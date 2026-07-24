class_name Career
extends RefCounted
## A persistent manager career: one club, played week-by-week through a league
## season, with an accumulating table, finances and a board objective. Saves to
## user://career.json. This is the spine the rest of the management layer hangs off.
##
## Kept free of the GameDB autoload (callers pass clubs/leagues in) so it stays
## unit-testable headless.

const SAVE_PATH := "user://career.json"
const MAX_STADIUM := 130000   # tier-11 capacity ceiling (matches StadiumScreen.MAX_CAPACITY)

var club_id: int = -1
var club_name: String = ""
var manager_name: String = ""     # entered on the SELECCION new-career screen
var manager_level: String = "manager"   # NIVEL dialog pick: trainer/manager/accountant/total
var match_options_shown: bool = false   # MATCH OPTIONS modal = career's FIRST match only (witnessed)
var players_age: bool = false     # NIVEL "Players age ?" checkbox
var preseason_rivals: Array = []  # PRESEASON friendly picks [{date, club_id, name, home}]
var friendlies_played: int = 0    # picks already simulated (index into preseason_rivals)
var friendly_results: Array = []  # played friendlies [{date, home_id, away_id, hg, ag}]
var league_id: String = ""
var league_name: String = ""
var season: String = "1997-98"
var year: int = 1                 # season number within this career
var week: int = 0                 # index of the NEXT round to play
var fixtures: Array = []          # Array[round]; round = Array[[home_id, away_id]]
var table: Dictionary = {}        # club_id:int -> stat row
# ---- the living pyramid (witnessed 2026-07-19, wine-captures-2026-07-19-lowerdiv/) ----
# The original simulates ALL FOUR English divisions every week: real per-fixture
# scores, per-player goal scorers, weekly table revisions with position arrows.
# `divisions` holds the OTHER tiers (the manager's own stays in fixtures/table):
#   tier:int -> {league_id, name, tier, ids:Array, names:{id->name}, fixtures,
#                table:{id->row}, played:int, scorers:Array, seed:{id->pos},
#                prev:{id->pos}}
# Witnessed round offset: divisions BELOW the manager's have already played
# round 1 by the manager's week-1 Saturday (w4 Premier career: Div1/2/3 all P=1
# at 9/8 pre-match; w5 Div-1 career: Premier+Div1 P=0, Div2/3 P=1; w6 Div-2
# career: Div3 P=1; w7 Div-3 career: Div2 P=0). Divisions at/above run in sync.
var divisions: Dictionary = {}
var seed_pos: Dictionary = {}     # manager division: club_id -> pre-season seed slot (witnessed
                                  # P=0 order = prior-season finish, relegated top/promoted bottom)
var table_prev: Dictionary = {}   # manager division: club_id -> position at the previous
                                  # table revision (the LEAGUE TABLES up/down arrows)
# Runtime-only (never persisted): static club dicts + rating/XI caches for the
# other divisions' weekly sim. Flat id-keyed (memberships move across seasons).
# Re-attached by Main after load (ensure_divisions).
var _div_clubs: Dictionary = {}   # club_id -> static club dict (ALL English clubs)
var _div_ratings: Dictionary = {} # club_id -> MatchEngine.team_ratings
var _div_xis: Dictionary = {}     # club_id -> MatchSim.xi_of
var results: Array = []           # manager's played results [{week,opp_id,home,hg,ag}]
var scorer_log: Array = []        # every league goal, all fixtures: {week,scorer,club,minute,h,a}
                                  # (own goals excluded; feeds GOAL SCORERS, witnessed 2026-07-18)
# ---- per-player SEASON statistics: the STATISTICS screen's persistent store ---------
# MANAGER.EXE keeps these at playerobj+0x24..+0x64 -- 17 dwords in the same field order
# as one 0x48-byte match record -- and the career-match runner ADDS each finished
# match's record into them (FUN_00448b60 @0x448f6b / @0x44907a). Ported as
# Pm98StatStore.fold_back(); the STATISTICS screen reads them back at @0x4b2233.
# Key = the GLOBAL game_db player id (NOT the participant slot -- see MatchSim.pid_map).
var season_stats: Dictionary = {}          # pid:int -> PackedInt32Array(17)
# club+0x274, the club's season MINUTES -- the TEAM TOTAL MIN cell (@0x4b221a). The
# runner bumps it per finished match (@0x449189). Live witness 2026-07-24: 630 -> 720
# across one Euro Cup tie, i.e. +90 and cup ties DO count.
var season_club_minutes: Dictionary = {}   # club_id:int -> int
# The TEAM TOTAL MP cell (the club-squad path's own count, @0x4b21ed). Same witness:
# it stayed 7 across that Euro tie while every player's MP went 7 -> 8, and 7 is exactly
# the 6 league rounds played plus the Charity Shield. So cup ties do NOT bump it.
var season_club_mp: Dictionary = {}        # club_id:int -> int
var cash: int = 0                 # running bank balance
var weekly_net: int = 0           # per-week finance delta (from FinanceModel)
# Season-to-date insurance ledger, £ (FINANCES lines, Insurance.gd / @0x57f3a6):
var ins_premiums: int = 0         # PLAYERS' INSURANCE  (week record +0x60)
var ins_hospitals: int = 0        # HOSPITALS, net of the group payouts (+0x64-+0x68-+0x6c)
var ins_wage_refund: int = 0      # insured-injured wages refunded (+0x54, cut from PLAYERS' WAGE)
var ins_group3_income: int = 0    # INSURANCE GROUP 3 income (+0x70)
var objective_pos: int = 17       # board wants: finish at least this high (1-based)
var objective_text: String = ""
var finished: bool = false        # season complete + objective resolved
var tactics: Dictionary = {}      # manager's Tactics.to_dict(): XI + shape + marking
var stadium_capacity: int = 0     # managed club's current ground capacity (0 = GameDB default)
# GROUND IMPROVEMENTS (frame 07): several works run at once -- a SEATS expansion, a CAR
# PARK level, a FACILITIES grade and a SERVICES grade can all be under construction in the
# same week. `works` is a LIST of {cat, key, label, cost, weeks_left, effect}; each ticks
# independently and applies its effect (capacity / car-park level / facility grade) on
# completion. car_park_levels = the 4 quadrants NE/NW/SE/SW (base level 1 each = 2,000
# spaces); ground_grades = completed FACILITIES/SERVICES upgrades "cat:key" -> grade.
var works: Array = []
var car_park_levels: Array = [1, 1, 1, 1]
var ground_grades: Dictionary = {}
var ticket_price: int = 0         # board-set match ticket price (0 = tier default)
var board_price: int = 0          # board-set advertising-board price (0 = tier default)
var boards_sold_season: bool = false  # GROUND MATCH DAY: sponsor-board season offer taken

# Live transfer state: the division's squads mutate as players move, and persist
# in the save -- the career, not GameDB, is the source of truth once you're managing.
var tier: int = 1                       # division tier (all clubs here share it)
var _leagues: Array = []                 # league metadata (tier lookups for external clubs)
var rosters: Dictionary = {}            # club_id:int -> Array[player dict] (live squads)
var club_names: Dictionary = {}         # club_id:int -> String
var transfer_listed: Dictionary = {}    # pid:int -> true (your players up for sale)
var sale_offers: Dictionary = {}        # pid:int -> Array[{buyer_id, buyer_name, offer, weekly_wage, years, week}]
var shortlist: Array = []               # pid:int targets you're tracking
var transfer_log: Array = []            # newest-first transfer news lines
var offers_left: int = OFFERS_PER_WEEK  # signings the board still allows this week
var news_log: Array = []                # newest-first club news {week,kind,text}
var training_intensity: String = Training.DEFAULT_INTENSITY   # Light/Normal/Intensive
var youth: Array = []                   # the youth team: scouted youngsters (Youth.gd)
var youth_seq: int = YOUTH_ID_BASE      # monotonic id minter for youth (above senior ids)
var youth_search: Dictionary = {}       # running scout search {skills:Array, weeks:int}; {} = idle
var scout_search: Dictionary = {}       # SENIOR scout search {criteria:Dictionary, due_week:int};
                                        # {} = idle (SCOUT screen, docs/re/scout_screen_re.md)
var scout_results: Array = []           # last finished search's rows (persist until a new search)
var pending_alerts: Array = []          # queued hub "PREMIER MANAGER 98" alert texts; Main
                                        # raises + clears them when the hub next shows (the
                                        # witnessed post-flow timing, scout_screen_re.md 78)
var external_signed: Dictionary = {}    # pid -> true: players bought off static (non-roster)
                                        # squads via the OFFERS browse (hidden from re-browse)
var pending_bids: Array = []            # outgoing transfer bids awaiting the selling club's
                                        # answer next week (the original's days-later response;
                                        # [{kind, pid, club_id, offer, weekly, years, clauses,
                                        #   bonus, week}]). Resolved in advance_week.
var staff: Array = []                   # hired backroom staff (Staff.gd)
var staff_pool: Array = []              # staff available to hire (refreshed each season)
var staff_seq: int = STAFF_ID_BASE      # monotonic id minter for staff candidates
var free_agents: Array = []             # out-of-contract players you can sign for £0 + a wage
var free_seq: int = FREE_ID_BASE        # monotonic id minter for generated free agents
var talents_used: Dictionary = {}       # real-talent ledger: pool key -> season injected (Talent.gd)
var fa_cup: Dictionary = {}             # the F.A. Cup bracket (Cup.gd); {} = not running
var league_cup: Dictionary = {}         # the Coca-Cola (League) Cup bracket; {} = not running

# Cross-season honours, captured at the end of each season (drive the next season's
# Charity Shield + European qualification). -1 / [] until a first season completes.
var last_champion_id: int = -1          # last season's league champions
var last_fa_winner_id: int = -1         # last season's F.A. Cup winners
var last_lc_winner_id: int = -1         # last season's League Cup winners (a UEFA berth)
var last_runners_up: Array = []         # last season's league places 2.. (EC 2nd berth + UEFA)
var charity_shield: Dictionary = {}     # the season-opener result; {} = not played.
                                        # While `charity_shield_pending` it holds only
                                        # {champ_id, fa_id, season} until the manager plays it.
var charity_shield_pending: bool = false  # the manager IS a shield contestant -> he PLAYS it
                                        # as his first fixture (Man Utd v Chelsea, witnessed
                                        # 2026-07-23), instead of the auto-resolved card
var season_opened: bool = false         # the week-0 curtain-raiser chain (shield card +
                                        # START OF SEASON screens) has run for this season
var euro_seeds: Dictionary = {}         # comp_key -> domestic seed club ids (the TEAMS IN
                                        # CHAMPIONSHIPS panels; set by mint_european_cups)

# European competitions (qualified into from last season's domestic finish). Each is a
# two-legged knockout (Cup.gd) over a field of this division's qualifier(s) + strong
# foreign clubs. euro = {comp_key -> bracket}; the foreign entrants' ratings + names are
# FROZEN here at draw time so the brackets resolve + save without GameDB.
var euro: Dictionary = {}               # {"european_cup"/"uefa_cup"/"cup_winners_cup" -> bracket}
var euro_ratings: Dictionary = {}       # foreign club id:int -> {att,def,gk}
var euro_names: Dictionary = {}         # foreign club id:int -> String

# Winners-of-winners finals (season-openers from LAST season's European winners). The
# European Cup winner + Cup Winners' Cup winner are captured at rollover, their ratings
# frozen so the finals resolve after euro_ratings is rebuilt.
var euro_winner_cup: int = -1           # last season's European Cup winner
var euro_winner_cwc: int = -1           # last season's Cup Winners' Cup winner
var euro_winner_ratings: Dictionary = {}  # winner/SA-champ id:int -> {att,def,gk}
var euro_winner_names: Dictionary = {}    # winner/SA-champ id:int -> String
var supercup: Dictionary = {}           # European Supercup result; {} = not played
var intercontinental: Dictionary = {}   # Intercontinental Cup result; {} = not played

# The manager's career ACROSS clubs (#14). Reputation tracks how you've done; the board can
# sack you for missing its objective; stronger clubs headhunt you when you overachieve; and
# every spell is recorded so a career spans several clubs (Manager.gd is the decision math).
var reputation: float = Manager.REP_START   # 0..100 standing in the game
var manager_history: Array = []         # past spells [{club, league, from_season, to_season, ...}]
var pending_offers: Array = []          # job offers currently on the table (built by Main from GameDB)
var sacked: bool = false                # set at season end when the board dismisses you
var sack_reason: String = ""            # "relegated" / "missed" (for the end-of-season message)
var headhunt_pending: bool = false      # a stronger club is courting you after a strong season
var spell_start_year: int = 1           # the career `year` you joined the current club
var comp_total: Dictionary = {}         # career-total per-competition record (MANAGER HISTORY
                                        # TOTAL view); past seasons/spells fold in at rollover
var _rep_year: int = 0                  # guard: the season `year` the board review was applied

# Coca-Cola Cup options: two-legged rounds, a single-leg final, sequential round labels
# (Round 1 -> Round 2 -> Qtr Finals -> Semifinals -> Final), a smaller purse than the F.A.
# Cup, and a schedule that finishes earlier in the season (so the two finals don't clash).
const LEAGUE_CUP_OPTS := {
	"name": "Coca-Cola Cup", "legs": 2, "two_legged_final": false,
	"label_scheme": "sequential", "qtr_label": "Qtr Finals",
	"prize_round": 120_000, "prize_winner": 900_000, "span_lo": 0.0, "span_hi": 0.7,
}

# Charity Shield (champions v F.A. Cup winners, the season's curtain-raiser). A modest,
# documented prize -- NOT a reversed PM98 figure (only the UEFA schedule is code-resident).
const CHARITY_PRIZE := 250_000

# The FIRST-season curtain-raiser is a fixed historical fixture: the 97-98 game opens on the
# real 96-97 honours, which the app never played, so it is seeded from the WITNESSED original
# CHARITY SHIELD CHAMPION card (screenshots/promanager-career-2026-07-16/11_charity_shield_
# champion.png, captured as a 3rd-division manager -> shown to EVERY manager, not just a
# participant): Manchester Utd. (96-97 league champions) lift it, Chelsea (96-97 F.A. Cup
# winners) are runners-up. Ids are the game's own EQUIPOS ids (Man Utd 40 / Chelsea 49); the
# seed no-ops if either is absent (a side-loaded non-97-98 database).
const S1_SHIELD_CHAMPION_ID := 40
const S1_SHIELD_RUNNERUP_ID := 49

# European competitions. Three two-legged knockouts seeded from last season's domestic
# finish; the field is filled to EURO_FIELD clubs with strong foreign sides from game_db.
const EURO_FIELD := 16                  # 16-club field. European Cup: 4 groups of 4 ->
                                        # top 2 -> QF/SF/Final. UEFA/CWC: R16 -> QF -> SF -> Final.
const UEFA_SPOTS := 2                   # league places below the champions that enter the UEFA Cup
const EURO_OPTS := {
	"european_cup": {"name": "European Cup", "emblem": "ligacamp"},
	"uefa_cup": {"name": "U.E.F.A. Cup", "emblem": "uefa"},
	"cup_winners_cup": {"name": "Cup Winners' Cup", "emblem": "recopa"},
}
# UEFA prize schedule -- the ONLY code-resident prize figures (reversed from MANAGER.EXE,
# docs/re/finance_constants.md). Per-match draw/win is collapsed to per-tie (legs are
# abstracted into one tie), so a tie won pays the "win" figure; milestones pay on reaching
# the round. EURO_WINNER (lifting it) is a documented bonus, not a reversed figure.
const EURO_ENTRY := 1_000_000           # "1 million from UEFA for competing"
const EURO_WIN := 510_000               # "510.000 for every match won"
const EURO_DRAW := 255_000              # "255.000 for every draw match" (the group phase)
const EURO_QF := 1_500_000              # "1.5 million ... qualification" (reach the last 8)
const EURO_SF := 1_625_000              # "1.625 million ... qualification" (reach the last 4)
const EURO_WINNER := 2_000_000
# Winners-of-winners one-off finals. Documented prizes (not reversed figures).
const SUPERCUP_PRIZE := 500_000         # European Supercup (Euro Cup winner v Cup Winners' winner)
const INTERCONTINENTAL_PRIZE := 750_000 # Intercontinental Cup (Euro Cup winner v S. American champion)

# Youth team: ids are minted from a base well above the senior id space (~8k players)
# so a promoted youngster never collides with a real player. Each career starts with a
# small academy intake; a fresh crop is scouted in at every season rollover.
const YOUTH_ID_BASE := 900000
const YOUTH_SEED_COUNT := 0             # a career starts with an EMPTY youth list (witnessed
                                        # orig/39, parity run 2026-07-16); the first rollover
                                        # scouts the first crop in
const YOUTH_INTAKE_LO := 1             # a season's fresh intake (scout's haul) ...
const YOUTH_INTAKE_HI := 3             # ... is this many youngsters
const YOUTH_SEARCH_WEEKS := 2          # a scout search reports back after this many weeks
const WONDERKID_MAX_YEAR := 3          # the guaranteed gem is scouted within a career's first 3 seasons

# Backroom staff: candidates are minted from their own id base; a new career starts with no
# staff hired but a pool to hire from (refreshed each season), and a soft cap on headcount.
const STAFF_ID_BASE := 800000
const STAFF_POOL_PER_ROLE := 3          # candidates available to hire per role at any time
const FREE_ID_BASE := 700000           # free-agent id space (below staff/youth, above seniors)
const FREE_POOL_SIZE := 8              # generated free agents available at any time
const FREE_POOL_CAP := 18              # pool ceiling once your released players are added in
const STAFF_MAX := 13                   # the 13 single-occupancy role slots (one member each)

# "The Directors will only let you make %u offer%s to sign a player per week."
const OFFERS_PER_WEEK := 3
# Transfer window shuts this many rounds before the season ends (deadline day).
const DEADLINE_TAIL := 6

# Living league (#12): rival clubs' squads injure/develop week to week like the manager's.
# Only a notable rival injury (this many matches or longer) is surfaced to the club news
# feed -- minor knocks drift the ratings quietly, as in the original game.
const AI_INJ_NEWS_WEEKS := 3


# ---- construction --------------------------------------------------------

## Start a fresh career managing `club` in its division. `league` is the league
## dict, `league_clubs` the full club dicts in that division, `leagues` all leagues.
## `pyramid` (optional): the full English-league context for the living pyramid —
## {"divisions": [{league_id, name, tier, clubs: Array[club dict]} x4],
##  "seeds": {league_id: Array[club_id]}}   (seeds = season_seed_1997.json,
## the witnessed pre-season table orders). Main builds it from GameDB
## (pyramid_context); headless tests may omit it (divisions stay empty and the
## career behaves exactly as before).
static func create(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array,
		pyramid: Dictionary = {}) -> Career:
	var c := Career.new()
	c.reputation = Manager.REP_START
	c._init_club(club, league, league_clubs, leagues, pyramid)
	return c


## Set this career up to manage `club` in its division: live rosters, fixtures, table,
## objective, finances, a fresh academy + staff pool + free-agent pool, and a clean slate
## of competitions. Shared by `create` (a brand-new career) and `take_job` (switching clubs
## mid-career) -- so the cross-career state (reputation, manager_history, the year counter)
## is set by the CALLER, never here. The managed club's spell is stamped as starting in the
## current `year`.
func _init_club(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array,
		pyramid: Dictionary = {}) -> void:
	club_id = int(club["id"])
	club_name = club.get("name", "?")
	league_id = str(league.get("id", ""))
	league_name = league.get("name", "League")
	_leagues = leagues                       # kept for external-club tier lookups (sign_external)
	tier = FinanceModel.tier_of(club, leagues)
	spell_start_year = year
	season = _season_label(year)
	# Fresh per-club slate (so switching clubs never carries the old club's data).
	week = 0
	finished = false
	sacked = false
	sack_reason = ""
	headhunt_pending = false
	pending_offers = []
	_rep_year = 0
	rosters = {}
	club_names = {}
	results = []
	news_log = []
	transfer_log = []
	transfer_listed = {}
	shortlist = []
	# The old division's rosters (and any talents injected into them) are gone; a clean
	# ledger lets inject_due_talents (Main, after take_job) re-deliver due talents here.
	talents_used = {}
	works = []
	car_park_levels = [1, 1, 1, 1]
	ground_grades = {}
	scout_search = {}
	scout_results = []
	pending_alerts = []
	external_signed = {}
	offers_left = OFFERS_PER_WEEK
	# Competitions reset: you arrive with no European qualification or honours at the new club.
	euro = {}
	euro_ratings = {}
	euro_names = {}
	last_champion_id = -1
	last_fa_winner_id = -1
	last_lc_winner_id = -1
	last_runners_up = []
	charity_shield = {}
	season_opened = false
	euro_seeds = {}
	euro_winner_cup = -1
	euro_winner_cwc = -1
	euro_winner_ratings = {}
	euro_winner_names = {}
	supercup = {}
	intercontinental = {}
	var ids: Array = []
	for lc in league_clubs:
		ids.append(int(lc["id"]))
		club_names[int(lc["id"])] = lc.get("name", "?")
		rosters[int(lc["id"])] = _seed_squad(lc)
	fixtures = SeasonSim.fixtures(ids)
	fa_cup = Cup.create(ids, fixtures.size())
	league_cup = Cup.create(ids, fixtures.size(), LEAGUE_CUP_OPTS)
	_init_table(league_clubs)
	_set_objective(club, league, league_clubs, leagues)
	var fin := FinanceModel.summary(club, tier)
	# weekly_net is the per-week finance delta WITHOUT the player wage bill -- player wages
	# are drawn live from the squad each week (so signings + renewal raises move the bill),
	# so we add the seed squad's wages back into the projected balance here. For an unchanged
	# squad the live deduction equals this added-back figure, i.e. identical to the old net.
	weekly_net = int(fin["weekly_balance"]) + int(fin["weekly_wages"])
	# STARTING CASH = the club's EQUIPOS budget u32 x 5000 — live-witnessed 2026-07-19
	# (Bolton 400 -> £2,000,000; A.Villa 1000 -> £5,000,000; Arsenal 1200 -> £6,000,000;
	# frames in screenshots/wine-captures-2026-07-19-economics/). Clubs without the
	# budget field (non-English records) keep the old projected-income fallback.
	var budget := int(club.get("budget", 0))
	if budget > 0:
		cash = budget * 5000
	else:
		cash = int(fin.get("total_income", 0)) / 4   # un-decoded fallback
	stadium_capacity = int(fin.get("capacity", 0))   # ground starts at the club's known size
	ticket_price = int(fin.get("ticket_price", 0))   # prices start at the division defaults
	board_price = int(fin.get("board_price", 0))
	tactics = Tactics.auto_pick(club, Tactics.DEFAULT_FORMATION).to_dict()
	# A fresh academy + staff pool + free-agent pool for the new club (none carry across).
	var yrng := RandomNumberGenerator.new()
	yrng.randomize()
	youth = Youth.intake(yrng, YOUTH_SEED_COUNT, youth_seq)
	youth_seq += YOUTH_SEED_COUNT
	staff = []
	staff_pool = Staff.generate_pool(yrng, staff_seq, STAFF_POOL_PER_ROLE)
	staff_seq += staff_pool.size()
	free_agents = TransferMarket.generate_free_agents(yrng, FREE_POOL_SIZE, free_seq)
	free_seq += FREE_POOL_SIZE
	# The living pyramid: witnessed seed order for the manager's own table + the
	# other three English divisions simulated alongside (see the divisions block
	# at the top of this file for the witness trail).
	seed_pos = {}
	table_prev = {}
	var seeds: Dictionary = pyramid.get("seeds", {})
	var my_seed: Array = seeds.get(league_id, [])
	for i in my_seed.size():
		seed_pos[int(my_seed[i])] = i + 1
	_build_divisions(pyramid, yrng)


## Deep-copy a club's squad into a live roster, stamping a contract length on each
## player (younger players are tied down longer). Never aliases GameDB's data.
func _seed_squad(club_dict: Dictionary) -> Array:
	# Morale/fitness kickoff = the EXE's season reset (FUN_005825c0): morale
	# 90 + rand(10); fitness lands on 70 (halfway from a fresh 99 toward 40 —
	# the exact value frames 081/084 pin for week 1). docs/re/morale_re.md.
	var form_rng := RandomNumberGenerator.new()
	form_rng.randomize()
	# The club's PM98 stature band (from its own squad strength) drives every seeded wage.
	var band := TransferMarket.stature_of(club_dict.get("players", []), tier)
	var out: Array = []
	for p in club_dict.get("players", []):
		var dup: Dictionary = (p as Dictionary).duplicate(true)
		if dup.get("age") == null:
			# FUN_005820f0 @0x58228a: out-of-range birth year -> age 25 + rand(0..4),
			# substituted at record load (GameDB does this for the shipped DB; this
			# guard covers rosters seeded from raw JSON, e.g. test harnesses).
			dup["age"] = 25 + form_rng.randi_range(0, 4)
		var age := int(dup.get("age", 26))
		# Contract term, BINARY-EXACT (FUN_00576cd0 @0x576d09/0x576e5c — the same call
		# that fills CLUB FEE/WAGE also rolls YEARS and stamps LEFT equal to it).
		# Replaces the app's old invented 3/2/1 age ladder. docs/re/offer_record_re.md.
		dup["contract_years"] = OfferRecord.seed_years(age, form_rng)
		dup["contract_term"] = dup["contract_years"]   # deal length (SQUAD MANAGEMENT YEARS col; contract_years = years LEFT)
		var seeded := OfferRecord.seed_clauses(OfferRecord.av_of(dup),
			int(dup.get("posFine", 0)), int(dup["contract_years"]))
		# The clause -> checkbox map was witnessed 2026-07-24 (offer_record_re.md §5.1),
		# so the seeded clauses now reach the CONTRACT panel under their real labels
		# instead of being generated and dropped.
		dup["clauses"] = (seeded["indices"] as Array).duplicate()
		if int(seeded["matches"]) > 0:
			dup["clause_matches"] = int(seeded["matches"])
		if int(seeded["bonus"]) > 0:
			dup["clause_bonus"] = int(seeded["bonus"])
		dup["injured_weeks"] = 0       # availability state (Availability.gd)
		dup["suspended_weeks"] = 0
		dup["yellows"] = 0
		dup["dev_progress"] = 0.0      # development carry-over (Training.gd)
		Contract.stamp_wage(dup, band)  # his contracted weekly wage (Contract.gd)
		dup["auto_renew"] = false      # opt-in: auto-renew an expiring deal at rollover
		dup["morale"] = 90 + form_rng.randi_range(0, 9)
		dup["fitness"] = 70
		out.append(dup)
	return out


func _init_table(league_clubs: Array) -> void:
	table.clear()
	for lc in league_clubs:
		var id := int(lc["id"])
		table[id] = {
			"id": id, "name": lc.get("name", "?"),
			"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "Pts": 0,
		}


## Board objective. English league clubs carry the game's OWN objective label
## (START OF SEASON, all four divisions live-witnessed 2026-07-19 — frames
## s29..s32 in screenshots/wine-captures-2026-07-19-economics/, exported into
## club_economy.json by tools/re/export_club_economy.py): Champion / U.E.F.A. /
## Promotion / Mid Table / Avoid Relegation. Clubs without a witnessed label
## (non-English) keep the strength-ranked fallback below.
func _set_objective(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array) -> void:
	var label := str(club.get("objective", ""))
	if label != "":
		objective_text = label
		objective_pos = _objective_pos_for(label, league_clubs.size())
		return
	var obj := objective_for(club_id, league_id, league_clubs, leagues)
	objective_pos = int(obj["pos"])
	objective_text = str(obj["text"])


## The finish position the app holds the board's label to (sack/bonus checks).
## The LABEL is source data; this int mapping is the app's mechanic.
func _objective_pos_for(label: String, total: int) -> int:
	match label:
		"Champion":
			return 1
		"Promotion":
			return 3        # automatic spots + playoff round
		"U.E.F.A.":
			return 6
		"Mid Table":
			return maxi(1, total / 2)
		_:                  # Avoid Relegation: stay above the drop zone
			var zone: Dictionary = SeasonSim.ZONES.get(tier, {"releg": 3})
			return maxi(1, total - int(zone.get("releg", 3)) - 1)


## The objective the board would set for `for_club_id` in its division — the
## exact _set_objective rule, callable without a career (the OFFERS SELECTION
## screen previews it per offered club).
static func objective_for(for_club_id: int, for_league_id: String,
		league_clubs: Array, leagues: Array) -> Dictionary:
	var ranked: Array = []
	for lc in league_clubs:
		var r := MatchEngine.team_ratings(lc)
		ranked.append({"id": int(lc["id"]), "ovr": r["att"] + r["def"] + r["gk"]})
	ranked.sort_custom(func(a, b): return a["ovr"] > b["ovr"])
	var strength_rank := league_clubs.size()
	for i in ranked.size():
		if ranked[i]["id"] == for_club_id:
			strength_rank = i + 1
			break
	var total := league_clubs.size()
	var pos := clampi(strength_rank + 2, 1, total)
	var tier := FinanceModel.tier_of({"leagueId": for_league_id}, leagues)
	var zone: Dictionary = SeasonSim.ZONES.get(tier, {"releg": 3})
	var relegation: int = int(zone.get("releg", 3))
	var text: String
	if pos >= total - relegation:
		text = "Avoid relegation"
		pos = total - int(relegation) - 1
	elif pos <= 1:
		text = "Win the league"
	elif pos <= maxi(2, total / 5):
		text = "Finish in the top %d" % pos
	else:
		text = "Finish %d or higher" % pos
	return {"pos": pos, "text": text}


# ---- season loop ---------------------------------------------------------

func total_weeks() -> int:
	return fixtures.size()

func season_over() -> bool:
	return week >= fixtures.size()

## [home_id, away_id] for the manager's match this week, or [] on a bye.
func manager_fixture() -> Array:
	if season_over():
		return []
	for m in fixtures[week]:
		if int(m[0]) == club_id or int(m[1]) == club_id:
			return [int(m[0]), int(m[1])]
	return []


## The next un-played PRESEASON friendly pick, or {} once the league has kicked
## off. Friendlies occupy the walked August dates (1/4/6/8) BEFORE round 1
## (run-2 header witnesses: Juventus Fri 1, Barcelona Mon 4, Sao Paulo Wed 6),
## so they gate on week == 0. Main gates hub CONTINUE on this; a direct
## advance_week() call skips any un-played friendlies (they expire with week 0).
func pending_friendly() -> Dictionary:
	if week != 0 or friendlies_played >= preseason_rivals.size():
		return {}
	return preseason_rivals[friendlies_played]


## Simulate the pending preseason friendly against `rival` (a roster-loaded club
## dict — the GameDB view for foreign sides). Same engine path as a league
## fixture: the faithful stat engine where both XIs are usable, the ratings
## fallback otherwise; the manager fields his real repaired XI. Home/away comes
## from the pick (engine club-average rule, FUN_004c7570 — see PreseasonScreen
## and docs/re/pretemporada_screen_re.md; the old continent-tab hypothesis is
## dead). NO league
## table / morale / clause / cash effects: the original's friendly side-effects
## are un-RE'd (no frame evidence); only the match itself is walked (run-2 BRIEF
## sheet09, Man Utd v Sao Paulo). Returns the advance_week manager_res shape so
## the same MatchScreen flow renders it, plus `friendly: true`.
func play_friendly(rng: RandomNumberGenerator, rival: Dictionary) -> Dictionary:
	var pick := pending_friendly()
	if pick.is_empty():
		return {}
	var rid := int(pick.get("club_id", -1))
	var at_home := bool(pick.get("home", false))
	var my_ratings := _ratings_for(club_id)
	var my_xi := _mgr_featured_xi()
	var rv_ratings := MatchEngine.team_ratings(rival)
	var rv_xi := MatchSim.xi_of(rival)
	var h := club_id if at_home else rid
	var a := rid if at_home else club_id
	var res := MatchSim.simulate(rng,
		my_ratings if at_home else rv_ratings,
		rv_ratings if at_home else my_ratings,
		my_xi if at_home else rv_xi,
		rv_xi if at_home else my_xi, h, a)
	friendlies_played += 1
	friendly_results.append({"date": str(pick.get("date", "")), "home_id": h,
		"away_id": a, "hg": int(res["home_goals"]), "ag": int(res["away_goals"])})
	return {"home_id": h, "away_id": a, "hg": int(res["home_goals"]),
		"ag": int(res["away_goals"]), "manager_home": at_home,
		"goals": res.get("goals", []), "possession": res.get("possession", []), "friendly": true}


## The manager's full league season for the CALENDAR view: one entry per round, in order,
## with the result filled in once played. Each = {round, week, opp_id, home, played, mine,
## theirs, wdl, is_next}. Result rounds are matched by the stored week (round index + 1).
func season_fixtures() -> Array:
	var by_week: Dictionary = {}
	for r in results:
		by_week[int(r["week"])] = r
	var out: Array = []
	for ri in fixtures.size():
		var opp := -1
		var home := false
		for m in fixtures[ri]:
			if int(m[0]) == club_id:
				opp = int(m[1]); home = true; break
			elif int(m[1]) == club_id:
				opp = int(m[0]); home = false; break
		if opp < 0:
			continue   # bye (not expected in a round-robin, but skip cleanly)
		var wk := ri + 1
		var e := {"round": ri, "week": wk, "opp_id": opp, "home": home,
			"played": false, "mine": 0, "theirs": 0, "wdl": "", "is_next": ri == week}
		if by_week.has(wk):
			var res: Dictionary = by_week[wk]
			e["played"] = true
			e["mine"] = int(res["hg"]) if bool(res["home"]) else int(res["ag"])
			e["theirs"] = int(res["ag"]) if bool(res["home"]) else int(res["hg"])
			e["wdl"] = "W" if e["mine"] > e["theirs"] else ("D" if e["mine"] == e["theirs"] else "L")
		out.append(e)
	return out

## Play the current round: simulate every fixture, update the table, accrue cash.
## `clubs_by_id` maps id -> full club dict (for ratings). Returns the manager's
## result {home_id, away_id, hg, ag, manager_home} or {} on a bye / season end.
func advance_week(rng: RandomNumberGenerator, clubs_override: Dictionary = {}) -> Dictionary:
	if season_over():
		return {}
	# Snapshot this revision's positions BEFORE the round lands — the LEAGUE
	# TABLES movement arrows compare against the previous revision (witnessed
	# lt_wk2_premier: red/white position triangles at week 2).
	table_prev = _positions_of(standings())
	# Rival clubs trade in the background while the window is open. Their signings
	# surface in the NEWS EXTRA newspaper MARKET feed (witnessed: "Everton has
	# signed Lilley for 5 seasons for £288,000.", 2026-07-19) AND the manager's
	# transfer-activity log.
	if transfers_open() and not rosters.is_empty():
		for line in TransferMarket.ai_round(rng, rosters, club_names, club_id, tier):
			_news("transfer", line)
			_log(line)
	# The fit XI that actually featured this week (captured before the match so its
	# injury/card rolls land on the players who played, not this week's recoveries).
	var featured := _mgr_featured_xi()
	# Each rival club's fit XI for this round, captured the same way (#12 living league).
	var ai_featured := _ai_featured_by_club()
	var ratings: Dictionary = {}
	var manager_res: Dictionary = {}
	# The fit XI each side actually fields (reused from the featured/living-league capture
	# above, so the stat engine rates the same players the injury/card rolls land on).
	var xi_of_id := func(id: int) -> Array:
		return featured if id == club_id else (ai_featured.get(id, []) as Array)
	var round_results: Array = []   # every fixture's score, for the morale pass below
	for m in fixtures[week]:
		var h := int(m[0])
		var a := int(m[1])
		if not ratings.has(h):
			ratings[h] = _ratings_for(h, clubs_override)
		if not ratings.has(a):
			ratings[a] = _ratings_for(a, clubs_override)
		# Per-player STATISTICS records are only accumulated for the manager's own
		# fixture: his club's squad is the only one the STATISTICS screen ever renders
		# (@0x4b2233 walks the managed club's squad), and running the store for all four
		# divisions' 380 rounds would cost a season sim for nothing on screen.
		var mine := h == club_id or a == club_id
		var res := MatchSim.simulate(rng, ratings[h], ratings[a], \
				xi_of_id.call(h), xi_of_id.call(a), h, a, 90, mine)
		if mine:
			fold_match_stats(res, h, a)
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		_apply(table[h], hg, ag)
		_apply(table[a], ag, hg)
		round_results.append({"h": h, "a": a, "hg": hg, "ag": ag})
		# GOAL SCORERS ledger: every league goal of every fixture, credited to the
		# player who took the shot; own goals are NOT chart-credited (the conceding-
		# side scorer would be wrong on a scorers chart — witness discussion in
		# docs/re/goalscorers_screen_re.md). week+1 = this round's 1-based number.
		for g in res.get("goals", []):
			var gd: Dictionary = g
			if bool(gd.get("own_goal", false)):
				continue
			scorer_log.append({"week": week + 1, "scorer": str(gd.get("scorer", "?")),
				"club": h if int(gd.get("scorer_side", 0)) == 0 else a,
				"minute": int(gd.get("minute", 0)), "h": h, "a": a})
		if h == club_id or a == club_id:
			manager_res = {"home_id": h, "away_id": a, "hg": hg, "ag": ag, "manager_home": h == club_id,
				"goals": res.get("goals", []),
					"possession": res.get("possession", [])}   # scorers + real engine possession for the feed (not persisted)
	# Morale & fitness live through the round (docs/re/morale_re.md): the slot
	# deltas + the result delta hit BOTH sides of every fixture, then the league
	# table caps a high-flying squad's morale once 11 rounds are in. A derived
	# RNG (seed folded with the week) keeps morale's own randomness reproducible
	# WITHOUT reordering the shared match/injury/training stream.
	var mrng := RandomNumberGenerator.new()
	mrng.seed = rng.seed ^ (int(week) * 0x9E3779B1)
	_round_morale(round_results, featured, ai_featured, mrng)
	# Contract-clause progress counters (the FICHA's "Matches played:" / "Goals:"
	# sub-lines): a featured man on a matches-to-renew deal logs an appearance;
	# a scoring-bonus man logs his non-own goals. Incremented on the LIVE roster
	# dicts (featured may hold fit-view copies). Our model's tracking — the
	# original's exact counter semantics are un-RE'd beyond the frame labels.
	if not manager_res.is_empty():
		var featured_ids := {}
		for p in featured:
			if p is Dictionary:
				featured_ids[int((p as Dictionary).get("id", -1))] = true
		var my_side := 0 if bool(manager_res["manager_home"]) else 1
		var scored := {}   # scorer name -> goals this match (my side, no own goals)
		for g in manager_res.get("goals", []):
			if int(g.get("scorer_side", -1)) == my_side and not bool(g.get("own_goal", false)):
				var nm := str(g.get("scorer", ""))
				scored[nm] = int(scored.get(nm, 0)) + 1
		for p in rosters.get(club_id, []):
			var pd: Dictionary = p
			if not featured_ids.has(int(pd.get("id", -1))):
				continue
			if pd.has("clause_apps"):
				pd["clause_apps"] = int(pd["clause_apps"]) + 1
			var nm2 := str(pd.get("name", ""))
			if pd.has("clause_goals") and scored.has(nm2):
				pd["clause_goals"] = int(pd["clause_goals"]) + int(scored[nm2])
	cash += weekly_net
	cash -= player_weekly_wage()        # the live squad wage bill (YEARLY WAGE / 52 per man)
	cash -= Staff.weekly_wage(staff)   # the backroom staff wage bill (STAFF WAGES)
	_tick_insurance()                  # premiums, hospital bills and policy payouts
	_resolve_pending_bids(rng)         # last week's outgoing bids get their answers
	_accumulate_offers(rng)            # incoming bids on the transfer-listed (CURRENT OFFERS)
	week += 1
	offers_left = OFFERS_PER_WEEK   # the board's weekly signing allowance resets
	_tick_works()                   # stadium expansion progresses a week
	if not manager_res.is_empty():
		results.append({
			"week": week, "opp_id": manager_res["away_id"] if manager_res["manager_home"] else manager_res["home_id"],
			"home": manager_res["manager_home"], "hg": manager_res["hg"], "ag": manager_res["ag"],
		})
		_log_result(manager_res)
	# Injuries & suspensions: a matchday elapsed (recoveries tick), then this match's
	# knocks and bookings are rolled on the side that featured. Manager's club only.
	# Training intensity scales the injury risk (harder training = more knocks).
	for n in Availability.tick_week(my_squad()):
		_news(n["kind"], n["text"])
	if not manager_res.is_empty():
		# A physiotherapist on the staff lowers the injury risk (physio_factor <= 1.0).
		var inj_mult := Training.injury_multiplier(training_intensity) * Staff.physio_factor(staff)
		for n in Availability.roll_match(rng, featured, inj_mult):
			_news(n["kind"], n["text"])
	# Player development for the training week just completed -- a TRAINER on the staff
	# speeds it up (training_factor >= 1.0).
	for n in Training.train_week(rng, my_squad(), training_intensity, Staff.training_factor(staff)):
		_news(n["kind"], n["text"])
	# The youth team develops on its own track (a YOUTH COACH speeds it); a youngster
	# crossing the readiness line is reported so you know to look at the YOUTH TEAM screen.
	for n in Youth.develop_week(rng, youth, Staff.youth_factor(staff)):
		_news(n["kind"], n["text"])
	# A running YOUTH TEAM SCOUT search ticks down and reports back (YOUTH TEAM screen).
	_tick_youth_search(rng)
	# A running SENIOR scout search completes on its due week (SCOUT screen).
	_tick_scout_search()
	# F.A. Cup: any midweek tie whose scheduled league week has arrived is played
	# now (open random draw, replays then penalties). The manager's own tie writes a
	# news line and a cup run pays prize money; the rest resolves in the background so
	# a champion still emerges even after the manager is knocked out.
	_play_due_cup_rounds(rng, clubs_override)
	# Rival squads live through the same week (#12): recoveries tick, this round's knocks
	# land on the XIs that featured, and development nudges their ratings. Kept quiet bar
	# notable rival injuries, which surface in the club news feed.
	_roll_ai_squads(rng, ai_featured)
	# The OTHER divisions play their round of the week (the witnessed living
	# pyramid). Placed last so the pre-existing draw order within a week is
	# untouched for reproducibility.
	_advance_other_divisions(rng)
	if season_over():
		finished = true
	return manager_res


## Play every due round of both cups (F.A. Cup + League Cup) whose scheduled week has
## been reached. The bracket dicts mutate in place, so this writes straight to the save.
func _play_due_cup_rounds(rng: RandomNumberGenerator, clubs_override: Dictionary) -> void:
	var ratings_fn := func(id: int) -> Dictionary: return _ratings_for(id, clubs_override)
	var xi_fn := func(id: int) -> Array: return _xi_for(id, clubs_override)
	var names_fn := func(id: int) -> String:
		if club_names.has(int(id)):
			return str(club_names[int(id)])
		return str(euro_names.get(int(id), "?"))
	for cup in [fa_cup, league_cup]:
		if cup.is_empty():
			continue
		while Cup.round_due(cup, week):
			var cr := Cup.play_round(cup, rng, ratings_fn, club_id, names_fn, xi_fn,
				_cup_report_sink())
			for n in cr["news"]:
				_news(n["kind"], n["text"])
			if int(cr["prize"]) > 0:
				cash += int(cr["prize"])
	# European competitions: same chassis, but prizes follow the reversed UEFA schedule
	# (per-tie, with QF/SF milestones) rather than the domestic per-round model.
	for key in euro:
		var eb: Dictionary = euro[key]
		if eb.is_empty():
			continue
		while Cup.round_due(eb, week):
			var in_before := Cup.still_in(eb, club_id)
			var er := Cup.play_next(eb, rng, ratings_fn, club_id, names_fn, xi_fn,
				_cup_report_sink())
			for n in er["news"]:
				_news(n["kind"], n["text"])
			if str(er.get("phase", "")) == "group":
				# Group phase pays per match on the reversed UEFA per-match schedule (the
				# figures the knockout collapses to per-tie), plus the last-8 bonus on
				# qualifying through the group.
				match str(er.get("manager_result", "")):
					"win":
						cash += EURO_WIN
					"draw":
						cash += EURO_DRAW
				if bool(er.get("manager_qualified", false)):
					cash += EURO_QF
			elif in_before:
				cash += _euro_prize(eb, er)


## The manager's UEFA prize for a European round just played (he was in it beforehand):
## the per-tie "win" figure plus the milestone bonus for reaching the last 8 / last 4, and
## a trophy bonus for lifting it. A lost tie (manager_out) or a bye pays nothing.
func _euro_prize(bracket: Dictionary, result: Dictionary) -> int:
	var prize := 0
	var won_tie: bool = not bool(result.get("manager_out", false)) \
		and not (result.get("manager_tie", {}) as Dictionary).get("bye", false) \
		and not (result.get("manager_tie", {}) as Dictionary).is_empty()
	if won_tie:
		prize += EURO_WIN
		match (bracket.get("survivors", []) as Array).size():
			8:
				prize += EURO_QF        # winning the round of 16 -> into the last 8
			4:
				prize += EURO_SF        # winning the quarter-final -> into the last 4
	if bool(result.get("champion", false)):
		prize += EURO_WINNER
	return prize


## Ratings for a club: the manager's own club uses the chosen XI + shape; every
## other (AI) club uses the auto-best-XI. Reads the live roster (so signings move
## results); `clubs_override` is a fallback for clubs not in the roster (e.g. an
## old save built before rosters existed).
func _ratings_for(id: int, clubs_override: Dictionary = {}) -> Dictionary:
	if id == club_id and not tactics.is_empty():
		# Field only the available players: the chosen XI is repaired around any
		# injured/suspended player, so absences actually weaken the side.
		var fit := _fit_view(id)
		return Tactics.from_dict(tactics).repaired(fit).ratings(fit)
	if not rosters.has(id) and euro_ratings.has(id):
		# A foreign European opponent: its frozen ratings (plus a name for the feed).
		var r: Dictionary = (euro_ratings[id] as Dictionary).duplicate()
		r["name"] = str(euro_names.get(id, "?"))
		return r
	if rosters.has(id):
		# A rival (AI) club: rate from its AVAILABLE players only, so a rival's injuries
		# and suspensions actually weaken it (the living-league drift, #12). A thin XI
		# pulls toward MatchEngine's rating floor, never below it.
		return MatchEngine.team_ratings(_fit_view(id))
	# An English club outside the live division: its static pyramid record.
	if _div_clubs.has(id):
		return _div_rating(id)
	# Legacy save with no live roster for this club: the static override (full squad).
	return MatchEngine.team_ratings(clubs_override.get(id, {}))


## The ordered fit XI (slot 0 = GK) for a club id, the parallel of `_ratings_for` that
## feeds the faithful statistical engine via MatchSim. Mirrors the same fit/repair logic
## so injuries weaken the side the same way. A foreign euro opponent (frozen ratings, no
## live players) returns [] -> MatchSim falls back to its ratings path.
func _xi_for(id: int, clubs_override: Dictionary = {}) -> Array:
	if id == club_id and not tactics.is_empty():
		return _mgr_featured_xi()
	if not rosters.has(id) and euro_ratings.has(id):
		return []
	if rosters.has(id):
		return _ai_featured_xi(id)
	if _div_clubs.has(id):
		return _div_xi(id)
	return MatchSim.xi_of(clubs_override.get(id, {}))


# ---- availability --------------------------------------------------------

## Players in `id`'s squad who can be selected this week (injury/ban aside).
func available_squad(id: int = club_id) -> Array:
	return Availability.available_players(squad_of(id))

## A club view backed by only the fit players (what selection/ratings field).
func _fit_view(id: int) -> Dictionary:
	return {"id": id, "name": club_names.get(id, "?"), "players": available_squad(id)}

## The manager's fit XI for this week: the saved tactics repaired around absences,
## resolved back to the live roster player dicts (so injury/card rolls write through).
func _mgr_featured_xi() -> Array:
	var fit := _fit_view(club_id)
	var t: Tactics = Tactics.from_dict(tactics).repaired(fit) if not tactics.is_empty() \
		else Tactics.auto_pick(fit)
	var by_id: Dictionary = {}
	for p in fit["players"]:
		by_id[int(p.get("id", -1))] = p
	var out: Array = []
	for pid in t.xi:
		if by_id.has(int(pid)):
			out.append(by_id[int(pid)])
	return _pad_xi(out, club_id)


# ---- living league (rival squads, #12) -----------------------------------

## Each rival club featuring in this round mapped to the fit XI it fields, captured
## before the match so this week's injury/card rolls land on the players who played.
## The manager's own club is rolled separately (its chosen tactics), so it is excluded.
func _ai_featured_by_club() -> Dictionary:
	var out: Dictionary = {}
	if season_over():
		return out
	for m in fixtures[week]:
		for id in [int(m[0]), int(m[1])]:
			if id != club_id and rosters.has(id) and not out.has(id):
				out[id] = _ai_featured_xi(id)
	return out


## A rival club's best available XI (its keeper + ten outfielders, by current ability),
## the players an AI side would field this week. Availability-filtered so an already-out
## player is never picked, and never injured twice.
func _ai_featured_xi(id: int) -> Array:
	var gks: Array = []
	var outfield: Array = []
	for p in available_squad(id):
		if p.get("isGK"):
			gks.append(p)
		else:
			outfield.append(p)
	gks.sort_custom(func(a, b): return _ai_ovr(a) > _ai_ovr(b))
	outfield.sort_custom(func(a, b): return _ai_ovr(a) > _ai_ovr(b))
	var xi: Array = []
	if not gks.is_empty():
		xi.append(gks[0])
	for i in mini(10, outfield.size()):
		xi.append(outfield[i])
	return _pad_xi(xi, id)


## Guarantee an 11-man, stat-engine-usable XI for a roster-backed club. When the fit
## pool cannot fill it (an injury/ban pile-up), the remaining slots are filled from the
## rest of the squad: fit players first, then unavailable ones, attr-carrying players
## ahead of attr-less records (one attr-less entry kicks the WHOLE fixture to the legacy
## fallback via MatchSim._usable), best ability first. Slot 0 stays a keeper whenever
## the squad has one. The club fields its best possible 11 rather than silently handing
## the fixture to the abstracted legacy engine (audit §B3 fallback close).
func _pad_xi(xi: Array, id: int) -> Array:
	if xi.size() >= 11:
		return xi
	var picked: Dictionary = {}
	for p in xi:
		picked[int(p.get("id", -1))] = true
	var fit_ids: Dictionary = {}
	for p in available_squad(id):
		fit_ids[int(p.get("id", -1))] = true
	var rest: Array = []
	for p in squad_of(id):
		if not picked.has(int(p.get("id", -1))):
			rest.append(p)
	rest.sort_custom(func(a, b):
		var fa := int(fit_ids.has(int(a.get("id", -1))))
		var fb := int(fit_ids.has(int(b.get("id", -1))))
		if fa != fb:
			return fa > fb
		var aa := int(not (a.get("attrs", {}) as Dictionary).is_empty())
		var ab := int(not (b.get("attrs", {}) as Dictionary).is_empty())
		if aa != ab:
			return aa > ab
		return _ai_ovr(a) > _ai_ovr(b))
	var out := xi.duplicate()
	for p in rest:
		if out.size() >= 11:
			break
		out.append(p)
	# Slot 0 is the keeper the stat engine rates as such: if the pad left no GK up
	# front but the squad has one, move the best GK to the front.
	if not out.is_empty() and not bool(out[0].get("isGK", false)):
		for i in range(1, out.size()):
			if bool(out[i].get("isGK", false)):
				var gk: Dictionary = out[i]
				out.remove_at(i)
				out.push_front(gk)
				break
	return out


## Selection proxy for a rival player: keepers by PO, outfielders by overall ability (CA).
func _ai_ovr(p: Dictionary) -> int:
	var attrs: Dictionary = p.get("attrs", {})
	if p.get("isGK"):
		return int(attrs.get("PO", 0))
	return int(attrs.get("CA", 0))


## Live one rival week for every AI club: recoveries tick, the featured XI takes this
## round's knocks/bookings, and the squad develops (Normal intensity). Rival news stays
## quiet apart from notable new injuries (>= AI_INJ_NEWS_WEEKS matches), which feed the
## club news so the living league is visible without flooding it.
func _roll_ai_squads(rng: RandomNumberGenerator, ai_featured: Dictionary) -> void:
	for cid in rosters:
		if int(cid) == club_id:
			continue
		var squad: Array = rosters[cid]
		Availability.tick_week(squad)   # recoveries (discarded -- rival feed stays quiet)
		if ai_featured.has(int(cid)):
			var feat: Array = ai_featured[int(cid)]
			var before: Dictionary = {}
			for p in feat:
				before[int(p.get("id", -1))] = int(p.get("injured_weeks", 0))
			Availability.roll_match(rng, feat)
			for p in feat:
				var now := int(p.get("injured_weeks", 0))
				if now >= AI_INJ_NEWS_WEEKS and now > int(before.get(int(p.get("id", -1)), 0)):
					var diag := Availability.injury_type_name(p)
					var with_diag := " with a %s" % diag if diag != "" else ""
					_news("injury", "%s's %s is out injured for %d weeks%s." % [
						club_names.get(int(cid), "?"), p.get("name", "?"), now, with_diag])
		Training.train_week(rng, squad, Training.DEFAULT_INTENSITY)


# ---- live squad access ---------------------------------------------------

## A club dict view backed by the live roster: {id, name, players}. This is what
## tactics, ratings, the squad screen and finances read once you're managing.
func club_view(id: int) -> Dictionary:
	return {"id": id, "name": club_names.get(id, "?"), "players": rosters.get(id, [])}

func squad_of(id: int) -> Array:
	return rosters.get(id, [])


## A club's PM98 STATURE band (0-12) from its live squad + the shared division tier. This
## is the one per-club input to every fee/wage lookup (RE'd TransferMarket.stature_of):
## a club's fees/wages depend on its OWN squad strength, not just its division.
func band_of(id: int) -> int:
	return TransferMarket.stature_of(rosters.get(id, []), tier)

## The manager's own club stature band.
func my_band() -> int:
	return band_of(club_id)


func _apply(s: Dictionary, gf: int, ga: int) -> void:
	s["P"] += 1
	s["GF"] += gf
	s["GA"] += ga
	if gf > ga:
		s["W"] += 1
		s["Pts"] += 3
	elif gf == ga:
		s["D"] += 1
		s["Pts"] += 1
	else:
		s["L"] += 1


# ---- morale & fitness (docs/re/morale_re.md) -------------------------------

## The round's morale/fitness pass: both sides of every simulated fixture take
## the slot deltas (FUN_00582690) + the club result delta (the emulated
## FUN_004179a0 matrix), then the league table caps high morale once 11 rounds
## are in (FUN_0057b400 + FUN_00418030). Cup ties don't move morale yet — gap
## listed in morale_re.md.
func _round_morale(round_results: Array, featured: Array, ai_featured: Dictionary,
		rng: RandomNumberGenerator) -> void:
	if rosters.is_empty():
		return
	for rr in round_results:
		var hg := int(rr["hg"])
		var ag := int(rr["ag"])
		var hres := "W" if hg > ag else ("D" if hg == ag else "L")
		var ares := "W" if ag > hg else ("D" if hg == ag else "L")
		var h := int(rr["h"])
		var a := int(rr["a"])
		_club_match_morale(h, true, hres, featured if h == club_id else ai_featured.get(h, []))
		_club_match_morale(a, false, ares, featured if a == club_id else ai_featured.get(a, []))
	# Weekly league-position ceiling: over ceiling+8 bleeds -10-rand(3) a week.
	var st := standings()
	for i in st.size():
		var id := int(st[i]["id"])
		if not rosters.has(id):
			continue
		var ceiling := Morale.weekly_ceiling(i + 1, int(st[i]["P"]))
		if ceiling >= Morale.CAP:
			continue
		for p in rosters[id]:
			Morale.weekly_decay(p, ceiling, rng)


## One club's post-match morale: XI men played (+3/+3), the 5 best fit
## non-featured men sat the bench (the AI 16 is rating-picked — the original
## drives its subs off the same FUN_00581e60 rating), the rest were out of the
## 16; the unavailable take the injured/banned hit. Then the result delta lands
## on EVERY man. One league -> both clubs are division band 0.
func _club_match_morale(id: int, home: bool, result: String, xi: Array) -> void:
	if not rosters.has(id):
		return   # frozen euro opponents have no live roster
	var xi_ids := {}
	for p in xi:
		if p is Dictionary:
			xi_ids[int((p as Dictionary).get("id", -1))] = true
	var rest: Array = []
	for p in rosters[id]:
		var pd: Dictionary = p
		if not xi_ids.has(int(pd.get("id", -1))) and Availability.status(pd)["state"] == "FIT":
			rest.append(pd)
	rest.sort_custom(func(x, y): return Morale.av6(x) > Morale.av6(y))
	var bench_ids := {}
	for i in mini(5, rest.size()):
		bench_ids[int((rest[i] as Dictionary).get("id", -1))] = true
	var delta := Morale.result_delta(home, 0, 0, result)
	for p in rosters[id]:
		var pd: Dictionary = p
		var pid := int(pd.get("id", -1))
		var state := "out"
		if Availability.status(pd)["state"] != "FIT":
			state = "unavailable"
		elif xi_ids.has(pid):
			state = "played"
		elif bench_ids.has(pid):
			state = "bench"
		Morale.post_match_slot(pd, state)
		Morale.add(pd, delta)


## A new man through the door unsettles the incumbents in his position
## (FUN_00588ae0): applied to the manager's roster on every signing.
func _signing_shock(newcomer: Dictionary) -> void:
	var new_id := int(newcomer.get("id", -1))
	for p in rosters.get(club_id, []):
		var pd: Dictionary = p
		if int(pd.get("id", -1)) == new_id:
			continue
		var d := Morale.jealousy_delta(pd, newcomer, bool(pd.get("on_loan", false)))
		if d != 0:
			Morale.add(pd, d)


## Sorted standings (Pts, then GD, GF, then the pre-season seed order) as stat rows.
## The seed tiebreak reproduces the WITNESSED week-0 table: at P=0 every club is
## equal, and the original lists them in last season's finishing order (relegated
## clubs top, promoted clubs bottom) — never alphabetically (2026-07-19 frames
## w5_lt_premier / w5_lt_default / w6_lt_second_seed / w7_lt_third_seed). Mid-season
## equal-record ties falling to seed order is our consistent extension (un-witnessed).
func standings() -> Array:
	return _sorted_rows(table.values(), seed_pos)


static func _sorted_rows(rows: Array, seed: Dictionary) -> Array:
	rows.sort_custom(func(a, b):
		if a["Pts"] != b["Pts"]:
			return a["Pts"] > b["Pts"]
		var gda: int = a["GF"] - a["GA"]
		var gdb: int = b["GF"] - b["GA"]
		if gda != gdb:
			return gda > gdb
		if a["GF"] != b["GF"]:
			return a["GF"] > b["GF"]
		var sa: int = int(seed.get(int(a["id"]), 9999))
		var sb: int = int(seed.get(int(b["id"]), 9999))
		if sa != sb:
			return sa < sb
		return a["name"] < b["name"])
	return rows


# ---- the living pyramid --------------------------------------------------

## Build the OTHER divisions' sim state from the pyramid context. Divisions
## BELOW the manager's play their round 1 immediately (witnessed head start).
func _build_divisions(pyramid: Dictionary, rng: RandomNumberGenerator) -> void:
	divisions = {}
	_div_clubs = {}
	_div_ratings = {}
	_div_xis = {}
	for dv in pyramid.get("divisions", []):
		var t := int(dv.get("tier", 0))
		if t <= 0:
			continue
		# Static dicts for ALL English clubs (incl. the manager's division: a club
		# dropping out of the live division needs its record for the pyramid sim).
		for c in dv.get("clubs", []):
			_div_clubs[int(c["id"])] = c
		if t == tier:
			continue
		var clubs: Array = dv.get("clubs", [])
		var ids: Array = []
		var names: Dictionary = {}
		var tbl: Dictionary = {}
		for c in clubs:
			var id := int(c["id"])
			ids.append(id)
			names[id] = c.get("name", "?")
			tbl[id] = {"id": id, "name": c.get("name", "?"),
				"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "Pts": 0}
		var seed: Dictionary = {}
		var order: Array = (pyramid.get("seeds", {}) as Dictionary).get(str(dv.get("league_id", "")), [])
		for i in order.size():
			seed[int(order[i])] = i + 1
		divisions[t] = {"league_id": str(dv.get("league_id", "")), "name": str(dv.get("name", "")),
			"tier": t, "ids": ids, "names": names, "fixtures": SeasonSim.fixtures(ids),
			"table": tbl, "played": 0, "scorers": [], "seed": seed, "prev": {}}
	for t in divisions:
		if int(t) > tier:
			_play_division_round(int(t), rng)


## Re-attach the runtime club dicts after a load (they are never persisted), and
## build any missing division state fresh. An old save gains zeroed lower-division
## tables which are then FAST-FORWARDED to the expected round count by simulating
## the missed rounds (same engine, not invented numbers) so the witnessed
## "below divisions run a round ahead" offset holds mid-career.
func ensure_divisions(pyramid: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if divisions.is_empty():
		_build_divisions(pyramid, rng)
	else:
		for dv in pyramid.get("divisions", []):
			for c in dv.get("clubs", []):
				_div_clubs[int(c["id"])] = c
	if seed_pos.is_empty():
		var order: Array = (pyramid.get("seeds", {}) as Dictionary).get(league_id, [])
		for i in order.size():
			seed_pos[int(order[i])] = i + 1
	for t in divisions:
		var target := week + (1 if int(t) > tier else 0)
		while int(divisions[t]["played"]) < mini(target, (divisions[t]["fixtures"] as Array).size()):
			var before := int(divisions[t]["played"])
			_play_division_round(int(t), rng)
			if int(divisions[t]["played"]) == before:
				break   # clubs not attached; stop rather than spin


func _div_rating(id: int) -> Dictionary:
	if not _div_ratings.has(id):
		var c: Dictionary = _div_clubs.get(id, {})
		if c.is_empty():
			return {}
		_div_ratings[id] = MatchEngine.team_ratings(c)
	return _div_ratings[id]


func _div_xi(id: int) -> Array:
	if not _div_xis.has(id):
		var c: Dictionary = _div_clubs.get(id, {})
		if c.is_empty():
			return []
		_div_xis[id] = MatchSim.xi_of(c)
	return _div_xis[id]


## Simulate one round of an OTHER division: real scores, table update, per-player
## goal-scorer ledger — the witnessed living pyramid (Div-1 P=1 with a full Div-3
## scorers chart at the manager's week 1).
func _play_division_round(t: int, rng: RandomNumberGenerator) -> void:
	var dv: Dictionary = divisions.get(t, {})
	if dv.is_empty():
		return
	var played := int(dv["played"])
	var fx: Array = dv["fixtures"]
	if played >= fx.size():
		return
	if not _div_clubs.has(int((dv["ids"] as Array)[0])):
		push_warning("Career: division tier %d has no attached clubs; round skipped" % t)
		return
	dv["prev"] = _positions_of(standings_for(t))
	var tbl: Dictionary = dv["table"]
	for m in fx[played]:
		var h := int(m[0])
		var a := int(m[1])
		var res := MatchSim.simulate(rng, _div_rating(h), _div_rating(a),
			_div_xi(h), _div_xi(a), h, a)
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		_apply(tbl[h], hg, ag)
		_apply(tbl[a], ag, hg)
		for g in res.get("goals", []):
			var gd: Dictionary = g
			if bool(gd.get("own_goal", false)):
				continue
			(dv["scorers"] as Array).append({"week": played + 1,
				"scorer": str(gd.get("scorer", "?")),
				"club": h if int(gd.get("scorer_side", 0)) == 0 else a,
				"minute": int(gd.get("minute", 0)), "h": h, "a": a})
	dv["played"] = played + 1


## Advance every OTHER division by one round (called once per manager week).
func _advance_other_divisions(rng: RandomNumberGenerator) -> void:
	for t in divisions:
		_play_division_round(int(t), rng)


# Witnessed zone structure per tier (the live tables' tag columns, 2026-07-19):
# Premier RELEGATION rows 18-20; Div 1 PROMOTION 1-2 / PLAY-OFFS 3-6 /
# RELEGATION 22-24; Div 2 PROMOTION 1-2 / PLAY-OFFS 3-6 / RELEGATION 21-24;
# Div 3 PROMOTION 1-3 / PLAY-OFFS 4-7, no relegation (no Conference modeled).
# `up` = automatic promotion spots; the playoff pool's winner also goes up.
const PYRAMID_ZONES := {
	1: {"up": 0, "playoff": 0, "down": 3},
	2: {"up": 2, "playoff": 4, "down": 3},
	3: {"up": 2, "playoff": 4, "down": 4},
	4: {"up": 3, "playoff": 4, "down": 0},
}


## Ratings for any English club: live view for the manager's division, static
## record otherwise (playoff sim + cross-tier needs).
func _any_rating(id: int) -> Dictionary:
	if rosters.has(id):
		return _ratings_for(id)
	return _div_rating(id)


## Winner of a 4-club promotion playoff: semis 1v4 / 2v3 (pool in finishing
## order) then a final, single matches; a drawn tie re-simulates (sudden-death
## replay, capped). The PLAY-OFFS pools are witnessed (tag columns); the
## bracket seeding + one-leg format is the real 1997-98 English rule, FLAGGED
## as a real-world-rule reconstruction (the in-game bracket is un-witnessed).
func _playoff_winner(pool: Array, rng: RandomNumberGenerator) -> int:
	if pool.size() < 4:
		return int(pool[0]) if pool.size() > 0 else -1
	var semi1 := _playoff_tie(int(pool[0]), int(pool[3]), rng)
	var semi2 := _playoff_tie(int(pool[1]), int(pool[2]), rng)
	return _playoff_tie(semi1, semi2, rng)


func _playoff_tie(h: int, a: int, rng: RandomNumberGenerator) -> int:
	for _i in 5:
		var res := MatchSim.simulate(rng, _any_rating(h), _any_rating(a),
			_div_xi(h) if not rosters.has(h) else _xi_for(h),
			_div_xi(a) if not rosters.has(a) else _xi_for(a), h, a)
		if int(res["home_goals"]) != int(res["away_goals"]):
			return h if int(res["home_goals"]) > int(res["away_goals"]) else a
	return h if rng.randf() < 0.5 else a


## End-of-season pyramid movement (promotions / relegations / playoffs) across
## all four English divisions, INCLUDING the manager's club. Mutates the
## membership state (rosters/club_names/tier/league_id/league_name, divisions,
## seed orders) and leaves fixtures/table/cup rebuilding to the advance_season
## code that follows. New seed orders follow the WITNESSED construction:
## relegated-from-above at top (in their finishing order), survivors by finish,
## promoted-from-below at the bottom (champions first, playoff winner last).
func _pyramid_rollover(rng: RandomNumberGenerator) -> void:
	if divisions.is_empty():
		return   # no pyramid context (headless careers) — legacy same-membership rollover
	# Guard: membership moves need the static club records for arriving clubs.
	if _div_clubs.is_empty():
		push_warning("Career: pyramid rollover skipped — no static club records attached")
		return
	var tiers: Array = [tier]
	for t in divisions:
		tiers.append(int(t))
	tiers.sort()
	# Final standings (ids in finishing order) per tier.
	var final: Dictionary = {}
	for t in tiers:
		var ids: Array = []
		for r in standings_for(int(t)):
			ids.append(int((r as Dictionary).get("id", -1)))
		final[int(t)] = ids
	# Division defs (league_id/name) per tier, for reassignment below.
	var defs: Dictionary = {tier: {"league_id": league_id, "name": league_name}}
	for t in divisions:
		defs[int(t)] = {"league_id": divisions[t]["league_id"], "name": divisions[t]["name"]}
	# Promoted (auto first, playoff winner last) and relegated per tier.
	var promoted: Dictionary = {}
	var relegated: Dictionary = {}
	for t in tiers:
		var z: Dictionary = PYRAMID_ZONES.get(int(t), {"up": 0, "playoff": 0, "down": 0})
		var order: Array = final[int(t)]
		var ups: Array = order.slice(0, int(z["up"]))
		if int(z["playoff"]) > 0 and int(t) > 1 and tiers.has(int(t) - 1):
			var pool: Array = order.slice(int(z["up"]), int(z["up"]) + int(z["playoff"]))
			var winner := _playoff_winner(pool, rng)
			if winner >= 0:
				ups.append(winner)
		promoted[int(t)] = ups if (int(t) > 1 and tiers.has(int(t) - 1)) else []
		relegated[int(t)] = order.slice(order.size() - int(z["down"])) \
			if (int(z["down"]) > 0 and tiers.has(int(t) + 1)) else []
	# New membership per tier, in seed order (the witnessed construction).
	var new_members: Dictionary = {}
	for t in tiers:
		var stay: Array = []
		for id in final[int(t)]:
			if not (promoted[int(t)] as Array).has(id) and not (relegated[int(t)] as Array).has(id):
				stay.append(id)
		var members: Array = []
		if tiers.has(int(t) - 1):
			members.append_array(relegated[int(t) - 1])
		members.append_array(stay)
		if tiers.has(int(t) + 1):
			members.append_array(promoted[int(t) + 1])
		new_members[int(t)] = members
	# The manager's club follows its finish (promotion or relegation moves the career).
	var new_tier := tier
	for t in tiers:
		if (new_members[int(t)] as Array).has(club_id):
			new_tier = int(t)
			break
	var all_names := func(id: int) -> String:
		if club_names.has(id):
			return str(club_names[id])
		return str((_div_clubs.get(id, {}) as Dictionary).get("name", "?"))
	# Rebuild the LIVE division (rosters + names) for the manager's new membership:
	# clubs already live keep their rosters; arriving clubs are seeded from their
	# static records (their live in-season state is a fresh-squad simplification).
	var new_rosters: Dictionary = {}
	var new_names: Dictionary = {}
	for id in new_members[new_tier]:
		new_names[int(id)] = all_names.call(int(id))
		if rosters.has(int(id)):
			new_rosters[int(id)] = rosters[int(id)]
		else:
			new_rosters[int(id)] = _seed_squad(_div_clubs.get(int(id), {"players": []}))
	rosters = new_rosters
	club_names = new_names
	tier = new_tier
	league_id = str((defs[new_tier] as Dictionary)["league_id"])
	league_name = str((defs[new_tier] as Dictionary)["name"])
	seed_pos = {}
	for i in (new_members[new_tier] as Array).size():
		seed_pos[int(new_members[new_tier][i])] = i + 1
	table_prev = {}
	# Rebuild the OTHER divisions' sim state on the new memberships.
	var new_divisions: Dictionary = {}
	for t in tiers:
		if int(t) == new_tier:
			continue
		var ids: Array = new_members[int(t)]
		var names: Dictionary = {}
		var tbl: Dictionary = {}
		var seed: Dictionary = {}
		for i in ids.size():
			var id := int(ids[i])
			names[id] = all_names.call(id)
			seed[id] = i + 1
			tbl[id] = {"id": id, "name": names[id],
				"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "Pts": 0}
		new_divisions[int(t)] = {"league_id": (defs[int(t)] as Dictionary)["league_id"],
			"name": (defs[int(t)] as Dictionary)["name"], "tier": int(t), "ids": ids,
			"names": names, "fixtures": SeasonSim.fixtures(ids), "table": tbl,
			"played": 0, "scorers": [], "seed": seed, "prev": {}}
	divisions = new_divisions
	_div_ratings = {}
	_div_xis = {}
	# The witnessed round offset re-applies: divisions below the (new) manager
	# tier open the season a round ahead (career-start rule; season 2+ is our
	# consistent extension, un-witnessed).
	for t in divisions:
		if int(t) > tier:
			_play_division_round(int(t), rng)


func _positions_of(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for i in rows.size():
		out[int((rows[i] as Dictionary).get("id", -1))] = i + 1
	return out


## Sorted standings for ANY English tier (the manager's own or a simulated one).
## Returns [] for a tier the career has no data for.
func standings_for(t: int) -> Array:
	if t == tier:
		return standings()
	var dv: Dictionary = divisions.get(t, {})
	if dv.is_empty():
		return []
	return _sorted_rows((dv["table"] as Dictionary).values(), dv["seed"])


## Previous-revision positions for a tier (the LEAGUE TABLES movement arrows);
## {} before any revision exists.
func prev_positions_for(t: int) -> Dictionary:
	if t == tier:
		return table_prev
	return (divisions.get(t, {}) as Dictionary).get("prev", {})


func has_division(t: int) -> bool:
	return t == tier or divisions.has(t)


## Club id -> name for a tier (the manager's own uses the live map).
func names_for(t: int) -> Dictionary:
	if t == tier:
		return club_names
	return (divisions.get(t, {}) as Dictionary).get("names", {})


## GOAL SCORERS chart for a tier — witnessed division-scoped (lt_goalscorers_third:
## the button on a lower division's table opens THAT division's chart).
func league_scorers_for(t: int) -> Array:
	if t == tier:
		return league_scorers()
	var dv: Dictionary = divisions.get(t, {})
	if dv.is_empty():
		return []
	return _scorer_rows(dv["scorers"], func(cid: int, nm: String) -> String:
		return _static_legal_name(cid, nm))


func scorer_goal_dict_for(t: int) -> Dictionary:
	if t == tier:
		return scorer_goal_dict()
	var dv: Dictionary = divisions.get(t, {})
	return _goal_dict_of(dv.get("scorers", []))


## Full legal name for a scorer on a STATIC division roster.
func _static_legal_name(cid: int, surname: String) -> String:
	var c: Dictionary = _div_clubs.get(cid, {})
	for p in c.get("players", []):
		if p is Dictionary and str((p as Dictionary).get("name", "")) == surname:
			return str((p as Dictionary).get("legalName", surname))
	return surname

## GOAL SCORERS ranking off the scorer_log ledger: goals desc, ties in first-to-reach-
## that-count order (frames 18/87 of the 2026-07-18 witness run are consistent with
## this; the original's exact tiebreak is not exhaustively provable — RE doc §list).
## Rows: [{name, club_id, goals, legal}]; the screen shows at most its 14 witnessed bars.
func league_scorers() -> Array:
	return _scorer_rows(scorer_log, func(cid: int, nm: String) -> String:
		return _legal_name(cid, nm))


## Shared chart builder over any scorer ledger (the manager's or a division's).
static func _scorer_rows(log: Array, legal_fn: Callable) -> Array:
	var agg: Dictionary = {}
	for i in log.size():
		var e: Dictionary = log[i]
		var key := "%s|%d" % [str(e.get("scorer", "?")), int(e.get("club", -1))]
		if not agg.has(key):
			agg[key] = {"name": str(e.get("scorer", "?")), "club_id": int(e.get("club", -1)),
				"goals": 0, "last": 0}
		agg[key]["goals"] = int(agg[key]["goals"]) + 1
		agg[key]["last"] = i
	var rows: Array = agg.values()
	rows.sort_custom(func(x, y):
		if int(x["goals"]) != int(y["goals"]):
			return int(x["goals"]) > int(y["goals"])
		return int(x["last"]) < int(y["last"]))
	for r in rows:
		r["legal"] = legal_fn.call(int(r["club_id"]), str(r["name"]))
	return rows


## Fold one finished fixture's per-player record into the season stores -- the port of
## the career-match runner's fold-back loops (FUN_00448b60 @0x448f6b / @0x44907a).
## `res` is a MatchSim.simulate() result; it carries a Pm98StatStore.Report under
## "report" whenever the caller asked for stats (and null on the legacy fallback, where
## no per-player records exist at all). `league` gates the TEAM TOTAL MP counter -- see
## `season_club_mp`.
##
## NOT called for pre-season friendlies: the same live witness that pins the two club
## counters also pins this. Beckham read MP 7 with 6 league rounds played plus the
## Charity Shield, so the career's friendlies had folded back nothing.
## The sink Cup calls for every match the manager's club plays in a cup tie. Cup fixtures
## bump the club MINUTES counter but NOT the TEAM TOTAL MP counter (`league = false`).
func _cup_report_sink() -> Callable:
	return func(res: Dictionary, h: int, a: int, bump_club := true) -> void:
		fold_match_stats(res, h, a, false, bump_club)


## `bump_club` is false for a two-legged tie's extra time: the port simulates ET on its
## own Mem, so its records fold in like any other, but it is the SAME fixture as leg 2 and
## must not bill the club counters a second time.
func fold_match_stats(res: Dictionary, home_id: int, away_id: int, league := true,
		bump_club := true) -> void:
	var rep = res.get("report")
	if rep == null:
		return
	Pm98StatStore.fold_back(rep, season_stats, Pm98StatStore.pick_mom(rep))
	if not bump_club:
		return
	for cid in [home_id, away_id]:
		# @0x449189 also has a `+= 120` branch, taken when F+0x58 != 0 AND F+0x48 != 0.
		# Neither field has an identified producer, so that branch is deliberately NOT
		# modelled rather than guessed; every fixture here takes the witnessed +90.
		season_club_minutes[cid] = int(season_club_minutes.get(cid, 0)) + 90
		if league:
			season_club_mp[cid] = int(season_club_mp.get(cid, 0)) + 1


## One STATISTICS row per squad player, in squad order: the 17 season dwords of
## `playerobj+0x24`, exactly the record the screen rebuilds at @0x4b2233. A player who
## has never featured yields an all-zero row, which the widget prints as the dashes the
## real game shows for an unused squad member.
func season_stat_rows(players: Array) -> Array:
	var out: Array = []
	for p in players:
		var pid := int((p as Dictionary).get("id", -1))
		var f: PackedInt32Array = season_stats.get(pid, PackedInt32Array())
		if f.size() != Pm98StatStore.REC_DWORDS:
			f = PackedInt32Array()
			f.resize(Pm98StatStore.REC_DWORDS)
		out.append(f)
	return out


## The TEAM TOTAL row for `cid`. The club-squad path does NOT column-sum the first two
## cells: MP comes from the club's own matches-played count and MIN from club+0x274
## (@0x4b21ed / @0x4b221a). Everything from +0x08 rightwards is a per-column sum.
func season_stat_totals(rows: Array, cid: int) -> PackedInt32Array:
	return Pm98StatStore.totals(rows, int(season_club_mp.get(cid, 0)),
		int(season_club_minutes.get(cid, 0)))


## Per-player goal entries for the goal-log popup, keyed "surname|club_id".
## Entry: {week, minute, h, a} (h/a = the fixture's club ids, popup MATCH columns).
func scorer_goal_dict() -> Dictionary:
	return _goal_dict_of(scorer_log)


static func _goal_dict_of(log: Array) -> Dictionary:
	var out: Dictionary = {}
	for e in log:
		var key := "%s|%d" % [str(e.get("scorer", "?")), int(e.get("club", -1))]
		if not out.has(key):
			out[key] = []
		(out[key] as Array).append({"week": int(e.get("week", 0)), "minute": int(e.get("minute", 0)),
			"h": int(e.get("h", -1)), "a": int(e.get("a", -1))})
	return out


## Full legal name ("Stuart Edward RIPLEY", popup title) for a rostered surname;
## falls back to the surname when the player left the roster (sold/retired).
func _legal_name(cid: int, surname: String) -> String:
	for p in rosters.get(cid, []):
		if p is Dictionary and str((p as Dictionary).get("name", "")) == surname:
			return str((p as Dictionary).get("legalName", surname))
	return surname


## Manager's current league position (1-based).
func position() -> int:
	var rows := standings()
	for i in rows.size():
		if int(rows[i]["id"]) == club_id:
			return i + 1
	return rows.size()

func objective_met() -> bool:
	return position() <= objective_pos


# ---- manager career across clubs (#14) -----------------------------------

## Seasons you have managed the current club (1 = your first).
func seasons_at_club() -> int:
	return year - spell_start_year + 1

## The relegation count for the current division (how many go down).
func _releg_count() -> int:
	return int(SeasonSim.ZONES.get(tier, {"releg": 3}).get("releg", 3))

## Did the manager lift a domestic cup this season (F.A. Cup or League Cup)?
func _won_domestic_cup() -> bool:
	return Cup.champion_id(fa_cup) == club_id or Cup.champion_id(league_cup) == club_id

## The board's end-of-season verdict, computed ONCE per season (idempotent on repeat calls
## within the same `year`): applies the season's reputation change, decides whether you are
## sacked, and whether a stronger club is headhunting you. Returns a display summary. The
## actual job offers are built by Main (which has GameDB) from `offer_band()`.
func board_review() -> Dictionary:
	var finished_pos := position()
	var total := standings().size()
	if _rep_year != year:
		var titles := {"league": finished_pos == 1, "cup": _won_domestic_cup()}
		reputation = Manager.apply_delta(reputation,
			Manager.reputation_delta(finished_pos, objective_pos, total, _releg_count(), titles))
		var survival := objective_text == "Avoid relegation"
		var sd := Manager.sack_decision(finished_pos, objective_pos, total,
			_releg_count(), survival, seasons_at_club())
		sacked = bool(sd["sacked"])
		sack_reason = str(sd["reason"])
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		headhunt_pending = not sacked and Manager.headhunted(finished_pos, objective_pos, reputation, rng)
		if sacked:
			reputation = Manager.apply_delta(reputation, Manager.REP_SACK)
		_rep_year = year
	return {
		"sacked": sacked, "reason": sack_reason, "headhunted": headhunt_pending,
		"finished_pos": finished_pos, "objective_pos": objective_pos,
		"objective_met": finished_pos <= objective_pos,
		"reputation": int(round(reputation)), "rep_label": Manager.reputation_label(reputation),
	}

## The strength-percentile band + count of clubs that will offer you their job, given your
## reputation and whether you were just sacked (Manager.offer_band). Main maps it to real
## clubs ranked by strength.
func offer_band() -> Dictionary:
	return Manager.offer_band(reputation, sacked)

# ---- per-competition record (MANAGER HISTORY screen) ----------------------
# The original's lower MANAGER HISTORY table: COMPETITION | PLA WIN DR LOS GF GA
# (witnessed 2026-07-16; docs/re/promanager_career_screens_re.md). Computed from
# the season's REAL stored results — league `results`, each cup bracket's manager
# ties (replays + both legs of two-legged rounds counted as their own matches, ET
# goals folded into leg 2), and the one-off finals dicts. Nothing is estimated.

const COMP_STATS := {"pla": 0, "win": 0, "dr": 0, "los": 0, "gf": 0, "ga": 0}

static func _comp_acc(row: Dictionary, mine: int, theirs: int) -> void:
	row["pla"] = int(row["pla"]) + 1
	row["gf"] = int(row["gf"]) + mine
	row["ga"] = int(row["ga"]) + theirs
	if mine > theirs:
		row["win"] = int(row["win"]) + 1
	elif mine == theirs:
		row["dr"] = int(row["dr"]) + 1
	else:
		row["los"] = int(row["los"]) + 1

## The manager's matches in one cup bracket. Byes play no match; a drawn single-leg
## tie's replay is a second match (a pens decision leaves the replay a draw); a
## two-legged tie is two matches, extra time counting inside leg 2's score.
func _cup_record(b: Dictionary) -> Dictionary:
	var row := COMP_STATS.duplicate()
	for rd in b.get("rounds", []):
		for tie in rd.get("ties", []):
			var t: Dictionary = tie
			if bool(t.get("bye", false)):
				continue
			var home := int(t.get("home_id", -1)) == club_id
			if not home and int(t.get("away_id", -1)) != club_id:
				continue
			if t.has("leg1_hg"):
				var l2h := int(t["leg2_hg"]) + int(t.get("et_hg", 0))
				var l2a := int(t["leg2_ag"]) + int(t.get("et_ag", 0))
				_comp_acc(row, int(t["leg1_hg"]) if home else int(t["leg1_ag"]),
					int(t["leg1_ag"]) if home else int(t["leg1_hg"]))
				_comp_acc(row, l2h if home else l2a, l2a if home else l2h)
			else:
				_comp_acc(row, int(t.get("hg", 0)) if home else int(t.get("ag", 0)),
					int(t.get("ag", 0)) if home else int(t.get("hg", 0)))
				if t.has("replay_hg"):
					_comp_acc(row, int(t["replay_hg"]) if home else int(t["replay_ag"]),
						int(t["replay_ag"]) if home else int(t["replay_hg"]))
	return row

## A one-off final (Charity Shield / Supercup / Intercontinental): one match if the
## manager's club was in it (a pens decision records as the draw it finished).
func _oneoff_record(tie: Dictionary) -> Dictionary:
	var row := COMP_STATS.duplicate()
	if tie.is_empty():
		return row
	var home := int(tie.get("home_id", -1)) == club_id
	if not home and int(tie.get("away_id", -1)) != club_id:
		return row
	_comp_acc(row, int(tie.get("hg", 0)) if home else int(tie.get("ag", 0)),
		int(tie.get("ag", 0)) if home else int(tie.get("hg", 0)))
	return row

## This season's record at the current club, keyed by the screen's fixed row order.
func competition_record() -> Dictionary:
	var lg := COMP_STATS.duplicate()
	for r in results:
		_comp_acc(lg, int(r["hg"]) if bool(r["home"]) else int(r["ag"]),
			int(r["ag"]) if bool(r["home"]) else int(r["hg"]))
	return {
		"league": lg,
		"fa_cup": _cup_record(fa_cup),
		"coca_cola": _cup_record(league_cup),
		"charity": _oneoff_record(charity_shield),
		"uefa": _cup_record(euro.get("uefa_cup", {})),
		"cup_winners": _cup_record(euro.get("cup_winners_cup", {})),
		"european_cup": _cup_record(euro.get("european_cup", {})),
		"supercup": _oneoff_record(supercup),
		"intercont": _oneoff_record(intercontinental),
	}

## Fold the (finished) season's record into the career total. Called once at each
## season boundary — advance_season (staying) or record_spell (leaving) — the two
## paths are mutually exclusive, so nothing double-counts.
func _fold_comp_total() -> void:
	var rec := competition_record()
	for k in rec:
		var tot: Dictionary = comp_total.get(k, COMP_STATS.duplicate())
		for s in rec[k]:
			tot[s] = int(tot.get(s, 0)) + int(rec[k][s])
		comp_total[k] = tot

## Career total INCLUDING the season in progress (the screen's TOTAL view).
func competition_total() -> Dictionary:
	var rec := competition_record()
	for k in rec:
		var tot: Dictionary = comp_total.get(k, {})
		for s in tot:
			rec[k][s] = int(rec[k][s]) + int(tot[s])
	return rec


## Record the current club as a finished spell in the manager's history. `reason` is how it
## ended ("sacked" / "resigned" / "left for X"). Captures the span + the final standing.
func record_spell(reason: String) -> void:
	_fold_comp_total()
	manager_history.append({
		"club_id": club_id, "club_name": club_name, "league_name": league_name,
		"from_season": _season_label(spell_start_year), "to_season": season,
		"seasons": seasons_at_club(), "final_pos": position(),
		"final_pos_str": "%d%s" % [position(), _ord_suffix(position())],
		"reason": reason,
	})

## Switch clubs mid-career: record the current spell, advance the career into the next
## season, and rebuild every per-club piece of state for the new club (`_init_club`). The
## manager carries only reputation + history + the career year counter across the move.
## `reason` is how the old spell ended. After this the new club's first season is ready.
func take_job(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array,
		reason: String = "", pyramid: Dictionary = {}) -> void:
	if reason == "":
		reason = "sacked" if sacked else ("left for %s" % str(club.get("name", "?")))
	record_spell(reason)
	year += 1
	_init_club(club, league, league_clubs, leagues, pyramid)

## A 1st/2nd/3rd/4th... suffix (local copy so Career stays Main-free).
func _ord_suffix(n: int) -> String:
	if n % 100 in [11, 12, 13]:
		return "th"
	match n % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"


# ---- transfer market -----------------------------------------------------

const _LOG_CAP := 40
const _NEWS_CAP := 50

func _log(line: String) -> void:
	transfer_log.push_front(line)
	if transfer_log.size() > _LOG_CAP:
		transfer_log.resize(_LOG_CAP)

## Push a club-news item (injuries/suspensions/returns + the matchday headline).
## Newest first, stamped with the week just played; capped.
func _news(kind: String, text: String) -> void:
	news_log.push_front({"week": week, "kind": kind, "text": text})
	if news_log.size() > _NEWS_CAP:
		news_log.resize(_NEWS_CAP)

## A "Matchday N: ARSENAL 2-1 CHELSEA -- a win" headline from the manager's result.
func _log_result(res: Dictionary) -> void:
	var hg := int(res["hg"])
	var ag := int(res["ag"])
	var home: bool = bool(res["manager_home"])
	var home_name: String = club_names.get(int(res["home_id"]), "?")
	var away_name: String = club_names.get(int(res["away_id"]), "?")
	var mine := hg if home else ag
	var theirs := ag if home else hg
	var verdict := "a win" if mine > theirs else ("a draw" if mine == theirs else "a defeat")
	_news("result", "Matchday %d: %s %d-%d %s -- %s." % [week, home_name, hg, ag, away_name, verdict])

## Cycle the training intensity Light -> Normal -> Intensive -> Light.
func cycle_training() -> void:
	var i := Training.INTENSITIES.find(training_intensity)
	training_intensity = Training.INTENSITIES[(i + 1) % Training.INTENSITIES.size()]


# ---- youth team ----------------------------------------------------------

## Start a YOUTH TEAM SCOUT search (YOUTH TEAM screen's SEARCH button, frame 047's
## "The scout is now searching..." state). Skill keys are the screen's cap_order ids.
## No-op without a hired scout or with a search already running. The loop itself is
## decoded from MANAGER.EXE strings (docs/re/youth_re.md): search -> "finished his
## search" / "...hasn't found"; the duration/yield numbers are our reconstruction.
func start_youth_search(skills: Array) -> void:
	if youth_search.is_empty() and not Staff.member_in_role(staff, Staff.YOUTH_TEAM_SCOUT).is_empty():
		youth_search = {"skills": skills.duplicate(), "weeks": YOUTH_SEARCH_WEEKS}
		_news("youth", "The scout is now searching for players with selected capabilities.")

## Weekly tick of a running scout search. On completion the scout either brings a
## youngster into the youth setup (room permitting; better scouts find more often)
## or reports back empty-handed — both with the original's news strings.
func _tick_youth_search(rng: RandomNumberGenerator) -> void:
	if youth_search.is_empty():
		return
	youth_search["weeks"] = int(youth_search.get("weeks", 1)) - 1
	if int(youth_search["weeks"]) > 0:
		return
	youth_search = {}
	var scout := Staff.member_in_role(staff, Staff.YOUTH_TEAM_SCOUT)
	var stars := float(scout.get("stars", 0.0))
	var room := Youth.SQUAD_CAP - youth.size()
	if room > 0 and rng.randf() < 0.25 + 0.11 * stars:
		for p in Youth.intake(rng, 1, youth_seq, Staff.youth_factor(staff)):
			youth.append(p)
			_news("youth", "The youth team scout has finished his search.")
			_news("youth", "%s has joined your Youth Team." % p.get("name", "?"))
		youth_seq += 1
	else:
		_news("youth", "The youth team scout has finished his search and hasn't found any players.")


# ---- the SENIOR scout search (SCOUT screen, docs/re/scout_screen_re.md) ----

## Witnessed duration with the ★★★ scout: armed week 3, still searching after
## one advance, finished-alert after the second (frames 68/73/78). Quality
## dependence is un-witnessed — flat 2 weeks, documented.
const SCOUT_SEARCH_WEEKS := 2

## AGE / QUALITY / PRICE scout criteria are BAND dropdowns (SCOUT screen), labels +
## order lifted binary-exact from the MANAGER.EXE getter tables 0x661e08 / 0x661e20 /
## 0x661e40 (see ScoutScreen). These are the numeric bounds behind each band index,
## inclusive. QUALITY matches the displayed AV column (0-99); PRICE bounds are in K.
const SCOUT_AGE_BANDS := [[17, 22], [23, 26], [27, 30], [31, 33], [34, 99]]
const SCOUT_QUALITY_BANDS := [[50, 65], [66, 70], [71, 75], [76, 80], [81, 85], [86, 90], [91, 99]]
const SCOUT_PRICE_BANDS_K := [[10, 75], [80, 125], [130, 250], [250, 500], [500, 1500],
	[1500, 3000], [3000, 5000], [5000, 7500], [7500, 10000], [10000, 999999]]

## Arm a search. criteria: {pos:String(""|GK/DF/MF/FW), role:int(0=off, posFine),
## age_band/quality_band/price_band:int(-1=off, else band index into the SCOUT_*_BANDS
## tables), leagues:Array[String] (league ids)}. The screen enforces the witnessed
## validation (>=1 criteria toggle ON) before calling this. `foreign_clubs` =
## GameDB club dicts of any checked NON-own division (Career never reads
## GameDB itself — Main bridges): those divisions are static, so their matches
## freeze into the search now; the own division scans LIVE rosters at the due
## week (morale/contracts move until then).
func start_scout_search(criteria: Dictionary, foreign_clubs: Array = []) -> void:
	var frozen: Array = []
	for club in foreign_clubs:
		var cd: Dictionary = club
		for p in cd.get("players", []):
			var row := _scout_row(p, int(cd.get("id", -1)), str(cd.get("name", "?")), cd, false)
			if _scout_match(row, p, criteria):
				frozen.append(row)
	scout_search = {"criteria": criteria.duplicate(true),
		"due_week": week + SCOUT_SEARCH_WEEKS, "frozen": frozen}

func scout_searching() -> bool:
	return not scout_search.is_empty()

func _tick_scout_search() -> void:
	if scout_search.is_empty():
		return
	if week < int(scout_search.get("due_week", 0)):
		return
	scout_results = _scout_scan_own(scout_search.get("criteria", {}))
	scout_results.append_array(scout_search.get("frozen", []))
	scout_search = {}
	# The witnessed hub alert (78) — raised by Main when the hub next shows.
	pending_alerts.append("The scout has finished his search.")
	_news("transfer", "The scout has finished his search.")

## Scan the manager's own division (live rosters, own club excluded) when it is
## among the checked leagues. The original's result order is un-RE'd
## (scout_screen_re.md) — this is the app's own scan order, documented.
func _scout_scan_own(criteria: Dictionary) -> Array:
	var out: Array = []
	if not criteria.get("leagues", []).has(league_id):
		return out
	for cid in rosters:
		if int(cid) == club_id:
			continue
		var cv := club_view(int(cid))
		for p in rosters[cid]:
			var row := _scout_row(p, int(cid), str(club_names.get(int(cid), "?")), cv, true)
			if _scout_match(row, p, criteria):
				out.append(row)
	return out

## One PLAYERS FOUND row. AV = floor((VE+RE+AG+CA)/4) — the witnessed formula
## (8/8 GK rows exact; = FUN_00534570 >> 2). Fee/wage are the RE'd PM98 lookup
## tables (FUN_00576cd0 x5000, docs/re/transfer_value_re.md §10/§12) keyed by the
## selling club's stature band — not an app valuation model.
func _scout_row(p: Dictionary, cid: int, cname: String, club_v: Dictionary, live: bool) -> Dictionary:
	var a: Dictionary = p.get("attrs", {})
	var av := int((int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0)) + int(a.get("CA", 0))) / 4.0)
	var is_key := TransferMarket.is_key_player(club_v, int(p.get("id", -1)))
	# The selling club's stature band. A live own-division row uses band_of (shared tier);
	# a FROZEN foreign / other-division row must rank the club within ITS OWN league off its
	# OWN squad (foreign clubs are not in `rosters`, so band_of would see an empty squad +
	# the manager's tier). english_tier_of returns 1-4 for an English club, 0 for a foreign
	# league (-> FUN_004457a0), so both cases value correctly.
	var band := band_of(cid) if live else TransferMarket.stature_of(
		club_v.get("players", []), TransferMarket.english_tier_of(club_v, _leagues))
	return {
		"pid": int(p.get("id", -1)),
		"club_id": cid,
		"club_name": cname,
		"name": str(p.get("name", "?")),
		"flagCode": p.get("flagCode"),
		"nationality": str(p.get("nationality", "")),
		"pos": str(p.get("pos", "")),
		"posFine": int(p.get("posFine", 0)),
		"age": int(p.get("age", 26)),
		"av": av,
		"ca": int(a.get("CA", 0)),
		"mo": int(p.get("morale")) if live and p.get("morale") != null else -1,
		"fee": TransferMarket.value_of(p, band),   # displayed CLUB FEE = book value (no markup)
		"wage": TransferMarket.yearly_wage(p, band),
		"years": int(p.get("contract_term", 0)) if live else 0,
		"left": int(p.get("contract_years", 0)) if live else 0,
		"key": is_key,
	}

func _scout_match(row: Dictionary, p: Dictionary, criteria: Dictionary) -> bool:
	var pos := str(criteria.get("pos", ""))
	if pos != "" and str(p.get("pos", "")) != pos:
		return false
	var role := int(criteria.get("role", 0))
	if role > 0 and int(p.get("posFine", 0)) != role:
		return false
	var age_band := int(criteria.get("age_band", -1))
	if age_band >= 0:
		var ab: Array = SCOUT_AGE_BANDS[age_band]
		if int(row["age"]) < int(ab[0]) or int(row["age"]) > int(ab[1]):
			return false
	var quality_band := int(criteria.get("quality_band", -1))
	if quality_band >= 0:
		var qb: Array = SCOUT_QUALITY_BANDS[quality_band]
		if int(row["av"]) < int(qb[0]) or int(row["av"]) > int(qb[1]):
			return false
	var price_band := int(criteria.get("price_band", -1))
	if price_band >= 0:
		var pb: Array = SCOUT_PRICE_BANDS_K[price_band]
		if int(row["fee"]) < int(pb[0]) * 1000 or int(row["fee"]) > int(pb[1]) * 1000:
			return false
	return true


## A season's youth turnover: every youngster ages a year; anyone over the graduation
## age who was never promoted is released to free a place; then the scout brings in a
## fresh crop (capped at the youth squad size). News lines either way.
func _roll_youth(rng: RandomNumberGenerator) -> void:
	var stayers: Array = []
	for p in youth:
		p["age"] = int(p.get("age", Youth.INTAKE_AGE_LO)) + 1
		p["dev_progress"] = 0.0
		if int(p.get("age", 0)) > Youth.GRADUATE_AGE:
			_news("youth", "%s has left the youth team without making the grade." % p.get("name", "?"))
		else:
			stayers.append(p)
	youth = stayers
	_ensure_wonderkid()           # season-rollover delivery of the gem (first 3 seasons; no-op after)
	var room := Youth.SQUAD_CAP - youth.size()
	if room <= 0:
		return
	var want := mini(room, rng.randi_range(YOUTH_INTAKE_LO, YOUTH_INTAKE_HI))
	# A youth coach raises the quality of the intake (Youth.intake's scout factor).
	for p in Youth.intake(rng, want, youth_seq, Staff.youth_factor(staff)):
		youth.append(p)
		_news("youth", "%s has joined your Youth Team." % p.get("name", "?"))
	youth_seq += want


## Plant the guaranteed generational FW (easter egg) if a career is still in its first
## seasons and he isn't already in the academy or the first team. Idempotent: the name scan
## means re-running it on load / at every rollover never duplicates him. Bypasses the youth
## squad cap on purpose -- he is a one-off, not part of the regular scouted crop.
func _ensure_wonderkid() -> void:
	if year > WONDERKID_MAX_YEAR or _has_wonderkid():
		return
	youth.append(Youth.make_wonderkid(youth_seq))
	youth_seq += 1
	_news("youth", "%s, a sensational young striker, has joined your Youth Team." % Youth.WONDERKID_NAME)


func _has_wonderkid() -> bool:
	for p in youth:
		if String(p.get("name", "")) == Youth.WONDERKID_NAME:
			return true
	for p in rosters.get(club_id, []):
		if String(p.get("name", "")) == Youth.WONDERKID_NAME:
			return true
	return false


# ---- real-talent injection (Talent.gd, easter-egg lane) --------------------

## Deliver the real talents scheduled for the season starting now (called from
## advance_season with TalentDB's pool; an empty pool -- no talent_pool.json --
## makes this a no-op and the port behaves exactly as before).
func _inject_real_talents(rng: RandomNumberGenerator, pool: Array) -> void:
	if pool.is_empty():
		return
	var start_year := 1996 + year
	for e in _by_tier(Talent.due(pool, start_year, talents_used)):
		_inject_talent(e, rng, start_year)


## Catch-up delivery: every pool entry due in any season up to now that hasn't been
## injected (job changes re-seed the division; app updates land on in-flight saves).
## Idempotent. Returns how many arrived so the caller knows whether to save.
func inject_due_talents(pool: Array, rng: RandomNumberGenerator = null) -> int:
	if pool.is_empty():
		return 0
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var start_year := 1996 + year
	var n := 0
	for e in _by_tier(Talent.due_catchup(pool, start_year, talents_used)):
		if _inject_talent(e, rng, start_year):
			n += 1
	return n


## Best prospects first, so when a season delivers more talents than there is room
## for (free-agent pool cap, full squads) the headroom goes to the biggest names.
static func _by_tier(due: Array) -> Array:
	due.sort_custom(func(a, b): return int(a.get("tier", 4)) < int(b.get("tier", 4)))
	return due


## Place one pool entry. Routing: the manager's own club receives a youth-age talent
## through the faithful academy loop ("%s has joined your Youth Team."); AI clubs get
## him straight into their live roster (their academies are off-screen). A talent whose
## club is outside the live division is SKIPPED and stays due -- he may arrive later
## via catch-up when the manager surfaces in his division. Returns true if placed.
func _inject_talent(e: Dictionary, rng: RandomNumberGenerator, start_year: int) -> bool:
	var key := Talent.key_of(e)
	if str(e.get("route", "club")) == "free_agent":
		return _inject_free_talent(e, rng, start_year)
	var cid := club_id if str(e.get("route", "club")) == "manager_youth" else Talent.club_of(e)
	if not rosters.has(cid):
		return false               # not in this division; NOT marked used (stays due)
	# Idempotence: if he's already in the world (double call, resume), just mark the ledger.
	var pid := int(e.get("id", 0))
	for p in youth:
		if int(p.get("id", -1)) == pid:
			talents_used[key] = season
			return false
	for p in rosters[cid]:
		if int(p.get("id", -1)) == pid:
			talents_used[key] = season
			return false
	var pname := str(e.get("name", "?"))
	if cid == club_id and Talent.age_in_season(e, start_year) <= Youth.GRADUATE_AGE:
		# Your club: he comes through YOUR academy, wonderkid-style (bypasses the youth
		# cap on purpose -- a scheduled one-off, not part of the scouted crop).
		youth.append(Talent.make_youth(e, rng, start_year))
		if int(e.get("tier", 4)) <= 1:
			_news("youth", "%s, a sensational young prospect, has joined your Youth Team." % pname)
		else:
			_news("youth", "%s has joined your Youth Team." % pname)
	else:
		# An AI club (or a rare over-age arrival at yours): straight into the roster,
		# fully contract-stamped. Full squads skip-and-retry at a later rollover.
		if rosters[cid].size() >= TransferMarket.SQUAD_MAX:
			return false           # NOT marked used; transfer churn usually frees room
		rosters[cid].append(Talent.make_senior(e, rng, start_year, band_of(cid)))
		# Only headline arrivals reach the news feed (living-league quietness).
		if int(e.get("tier", 4)) <= 2:
			_news("youth", "%s, a highly rated youngster, has come through the ranks at %s." % [
				pname, club_names.get(cid, "?")])
	talents_used[key] = season
	return true


## A talent whose real club is outside the PM98 world (route "free_agent") arrives on
## the free-transfer market instead. One shot: the pool resets every rollover, so if
## nobody signs him he moves on abroad like the real market would. A full pool defers
## him (stays due; tier-first ordering gives the headroom to the biggest names).
func _inject_free_talent(e: Dictionary, rng: RandomNumberGenerator, start_year: int) -> bool:
	var key := Talent.key_of(e)
	var pid := int(e.get("id", 0))
	for p in free_agents:
		if int(p.get("id", -1)) == pid:
			talents_used[key] = season   # already on the market (double call, resume)
			return false
	if free_agents.size() >= FREE_POOL_CAP:
		return false                     # market full; NOT marked used (stays due)
	free_agents.append(Talent.make_free_agent(e, rng, start_year))
	if int(e.get("tier", 4)) <= 2:
		_news("contract", "%s, a highly rated young player, is available on a free transfer." %
			str(e.get("name", "?")))
	talents_used[key] = season
	return true


## The youth players the manager can promote right now (the youth manager has flagged
## them ready). The screen badges these and offers PROMOTE.
func promotable_youth() -> Array:
	return youth.filter(func(p): return Youth.is_ready(p))


## Promote a youth player into the first-team squad. He must be flagged ready, there must
## be room under the squad cap, and -- faithful to PM98's "rejected your offer" -- a very
## raw prospect can balk. On success he moves out of `youth` into rosters[club_id] on a
## fresh contract. Returns {ok, msg}.
func promote_youth(pid: int) -> Dictionary:
	var idx := -1
	for i in youth.size():
		if int(youth[i].get("id", -2)) == pid:
			idx = i
			break
	if idx == -1:
		return {"ok": false, "msg": "That youngster is not in your youth team."}
	var p: Dictionary = youth[idx]
	if not Youth.is_ready(p):
		return {"ok": false, "msg": "%s is not ready for the first team yet." % p.get("name", "?")}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d); make room before promoting." % TransferMarket.SQUAD_MAX}
	youth.remove_at(idx)
	Youth.graduate(p)
	p["clubId"] = club_id
	p["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	p["contract_term"] = TransferMarket.NEW_CONTRACT_YEARS
	Contract.stamp_wage(p, my_band())   # a first-team wage now he's promoted
	p["auto_renew"] = false
	var form_rng := RandomNumberGenerator.new()
	form_rng.randomize()
	Morale.ensure(p, form_rng)   # fresh dynamic form, like the season kickoff roll
	rosters[club_id].append(p)
	_news("youth", "%s has been promoted to the first team squad." % p.get("name", "?"))
	_log("%s has been promoted from the youth team." % p.get("name", "?"))
	return {"ok": true, "msg": "%s has been promoted to the first team." % p.get("name", "?")}


# ---- backroom staff ------------------------------------------------------

## The weekly STAFF WAGES bill (sum of the hired staff's wages).
func staff_weekly_wage() -> int:
	return Staff.weekly_wage(staff)

## The live weekly PLAYER wage bill (sum of your squad's contracted wages). Drawn from cash
## each week, so a signing or a renewal raise lifts your outgoings (Contract.gd).
func player_weekly_wage() -> int:
	return Contract.squad_weekly_bill(my_squad(), my_band())


# ---- player insurance (INSURANCE screen) ---------------------------------

## The monthly policy price for one player, GROUP 1/2/3 — the binary's own
## FUN_0058c020 (Insurance.gd): monthly wage / {150,120,70}, floored up to
## £200/£500/£1,000. Both 2026-07-18 wine witnesses (Ward £1,250 vs Frandsen
## £14,583 monthly) sit under the clamp, which is why they saw identical prices.
func insurance_price(p: Dictionary, group: int) -> int:
	return Insurance.premium_monthly(group, Contract.current_weekly(p, my_band()) * 52 / 12)


## Set a squad player's INSURANCE POLICY group (0 = uninsured, 1-3). Stored on
## his dict (`insurance_group`) like `wage`, so it persists with the roster.
func set_insurance(pid: int, group: int) -> bool:
	if group < 0 or group > 3:
		return false
	for p in my_squad():
		var pd: Dictionary = p
		if int(pd.get("id", -1)) == pid:
			if group == 0:
				pd.erase("insurance_group")
			else:
				pd["insurance_group"] = group
			return true
	return false


## One week of the insurance economy (MANAGER.EXE finance loop @0x57f3a6, ported
## in Insurance.gd). Charges every policy's weekly premium, bills the hospital
## for every active injury, credits the group 2/3 reimbursements, refunds an
## insured injured man's wage, and books the GROUP 3 income line. Every one of
## those setters moves the club balance by the same signed amount in the original
## (they all tail-call FUN_00580cd0 -> club+0x1ec), so cash follows the ledger.
## The season-to-date totals feed the FINANCES screen's own lines.
func _tick_insurance() -> void:
	var band := my_band()
	var pass_ := Insurance.weekly_pass(my_squad(),
		func(p): return Contract.current_weekly(p, band),
		func(p): return Contract.current_yearly(p, band))
	var premiums := int(pass_["premiums"])
	var hospitals := float(pass_["hospitals"])
	var payouts := float(pass_["payout2"]) + float(pass_["payout3"])
	var wage_back := int(pass_["wage_back"])
	var group3 := float(pass_["group3"])
	if premiums == 0 and hospitals == 0.0 and wage_back == 0:
		return
	@warning_ignore("integer_division")
	var prem_gbp := premiums / Insurance.UNIT
	var hosp_gbp := int(hospitals / Insurance.UNIT)
	var pay_gbp := int(payouts / Insurance.UNIT)
	@warning_ignore("integer_division")
	var back_gbp := wage_back / Insurance.UNIT
	var g3_gbp := int(group3 / Insurance.UNIT)
	ins_premiums += prem_gbp
	ins_hospitals += hosp_gbp - pay_gbp
	ins_wage_refund += back_gbp
	ins_group3_income += g3_gbp
	cash += back_gbp + g3_gbp - prem_gbp - (hosp_gbp - pay_gbp)


## The season-to-date insurance figures the FINANCES screen posts to its own
## PLAYERS' INSURANCE / HOSPITALS / INSURANCE GROUP 3 lines (and the PLAYERS'
## WAGE netting). Keys match FinanceScreen's ledger lookup.
func insurance_ledger() -> Dictionary:
	return {"premiums": ins_premiums, "hospitals": ins_hospitals,
		"wage_refund": ins_wage_refund, "group3_income": ins_group3_income}


## Clear the season-to-date insurance ledger (new season / new career).
func _reset_insurance_ledger() -> void:
	ins_premiums = 0
	ins_hospitals = 0
	ins_wage_refund = 0
	ins_group3_income = 0

## Hire a candidate from the pool into the backroom staff. The 13 roles are SINGLE-OCCUPANCY
## (frames 100 + 108-121): signing into a role that already has a holder REPLACES him -- the
## outgoing member returns to the pool (a like-for-like swap, no compensation; a SACK is the
## paid exit). Guards the directors' affordability (you must cover the new season's wage).
## Moves the member out of the pool. Returns {ok, msg}.
func hire_staff(cand_id: int) -> Dictionary:
	var idx := -1
	for i in staff_pool.size():
		if int(staff_pool[i].get("id", -2)) == cand_id:
			idx = i
			break
	if idx == -1:
		return {"ok": false, "msg": "That member of staff is no longer available."}
	var m: Dictionary = staff_pool[idx]
	var role := str(m.get("role", ""))
	# The board won't sanction a hire the club plainly can't pay for (a season's wage).
	if int(m.get("wage", 0)) > cash:
		return {"ok": false, "msg": "You can't afford %s's wages." % m.get("name", "?")}
	staff_pool.remove_at(idx)
	# Single occupancy: the incumbent in this role (if any) goes back onto the market.
	var outgoing: Dictionary = Staff.member_in_role(staff, role)
	if not outgoing.is_empty():
		staff.erase(outgoing)
		staff_pool.append(outgoing)
	staff.append(m)
	_news("staff", "%s has joined the club as %s." % [m.get("name", "?"), Staff.label_for(role)])
	_log("Hired %s (%s)." % [m.get("name", "?"), role])
	return {"ok": true, "msg": "%s hired as %s." % [m.get("name", "?"), Staff.label_for(role)]}


## The StaffScreen `personnel` payload: each hired role -> {name, stars, wage}; vacant roles
## are absent (the screen draws them empty).
func staff_personnel() -> Dictionary:
	return Staff.personnel_dict(staff)

## Sack a hired staff member, paying the contract compensation (a few weeks' wage) from cash.
## He returns to the available pool. Returns {ok, msg}.
func sack_staff(member_id: int) -> Dictionary:
	var idx := -1
	for i in staff.size():
		if int(staff[i].get("id", -2)) == member_id:
			idx = i
			break
	if idx == -1:
		return {"ok": false, "msg": "That member of staff is not on your books."}
	var m: Dictionary = staff[idx]
	var comp := Staff.sack_cost(m)
	staff.remove_at(idx)
	cash -= comp
	staff_pool.append(m)
	_news("staff", "%s has been sacked (£%s compensation)." % [m.get("name", "?"), _money(comp)])
	_log("Sacked %s (%s); paid £%s compensation." % [m.get("name", "?"), Staff.label_for(str(m.get("role", ""))), _money(comp)])
	return {"ok": true, "msg": "%s sacked. £%s compensation paid." % [m.get("name", "?"), _money(comp)]}

## True while the transfer window is open (before deadline day).
func transfers_open() -> bool:
	return week < maxi(0, total_weeks() - DEADLINE_TAIL)

## Rounds until the deadline (0 once it has passed).
func deadline_weeks_left() -> int:
	return maxi(0, (total_weeks() - DEADLINE_TAIL) - week)

func my_squad() -> Array:
	return rosters.get(club_id, [])

## The buyable market: every other club's players, dearest first.
func market() -> Array:
	return TransferMarket.market(rosters, club_names, tier, club_id)

func _find_in(id: int, pid: int) -> Dictionary:
	for p in rosters.get(id, []):
		if int(p.get("id", -1)) == pid:
			return p
	return {}

## Bid `offer` for player `pid` at `from_club_id`. Mutates squads + cash on success.
## Returns {ok: bool, msg: String}. Enforces the board caps (deadline, weekly offer
## allowance, squad size, cash) before the selling club even considers the bid.
## The make-offer card's terms ride along: `weekly` > 0 replaces the stamped market
## wage, `years` > 0 the default contract length, `clauses` (checked clause indices
## 0..3) are stored on the player and shown on his FICHA CLAUSES panel, and `bonus`
## is the Scoring-bonus £ figure ("Scoring bonus (£X)"). A matches-to-renew /
## scoring-bonus deal also gets its live progress counter (`clause_apps` /
## `clause_goals`, advanced weekly — the FICHA's "Matches played:" / "Goals:"
## sub-lines). The acceptance verdict stays fee-based — the original's clause
## weighting is un-RE'd (docs/re/make_offer_re.md).
## ---- outgoing bids take days: place now, the club answers next week ----------
## The original never completes a buy at the OFFER click — the response arrives
## days later (news / the player joins then). place_bid_* runs the placement
## gates (window, board allowance, cash, availability), charges the weekly
## allowance, and queues the bid; _resolve_pending_bids (advance_week) evaluates
## it with the SAME sign_player/sign_external logic and posts the outcome as news.

func _has_pending_bid(pid: int) -> bool:
	for b in pending_bids:
		if int(b.get("pid", -1)) == pid:
			return true
	return false


func place_bid_roster(pid: int, from_club_id: int, offer: int,
		weekly: int = -1, years: int = -1, clauses: Array = [], bonus: int = 0) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var player := _find_in(from_club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	if _has_pending_bid(pid):
		return {"ok": false, "msg": "You have already made an offer for %s." % player.get("name", "?")}
	offers_left -= 1
	pending_bids.append({"kind": "roster", "pid": pid, "club_id": from_club_id,
		"offer": offer, "weekly": weekly, "years": years, "clauses": clauses.duplicate(),
		"bonus": bonus, "week": week})
	return {"ok": true, "msg": "Your offer of £%s for %s has been sent to %s." %
		[_money(offer), player.get("name", "?"), club_names.get(from_club_id, "?")]}


func place_bid_external(player: Dictionary, selling_club: Dictionary, offer: int,
		weekly: int = -1, years: int = -1, clauses: Array = [], bonus: int = 0) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var pid := int(player.get("id", -1))
	if external_signed.has(pid) or not _find_in(club_id, pid).is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	if _has_pending_bid(pid):
		return {"ok": false, "msg": "You have already made an offer for %s." % player.get("name", "?")}
	offers_left -= 1
	# The seller is static GameDB data; snapshot both so the pending bid resolves +
	# saves self-contained (the club dict feeds is_key_player at resolution).
	pending_bids.append({"kind": "external", "pid": pid,
		"player": player.duplicate(true), "club": selling_club.duplicate(true),
		"offer": offer, "weekly": weekly, "years": years, "clauses": clauses.duplicate(),
		"bonus": bonus, "week": week})
	return {"ok": true, "msg": "Your offer of £%s for %s has been sent to %s." %
		[_money(offer), player.get("name", "?"), selling_club.get("name", "?")]}


## Resolve last week's outgoing bids (called from advance_week). The evaluation
## happens NOW, through the same sign paths (count_offer=false — the allowance
## was charged at placement); accept and reject both land in the news log AND pop as
## a hub message box on the next hub view — the original's "days later" reply to a
## bid, so a BUY is not a silent no-op. The box reuses the witnessed PREMIER MANAGER
## 98 alert idiom (scout_screen_re.md witness 78); the exact original bid-response
## modal wording is un-RE'd, so the app's own authored outcome line is shown.
func _resolve_pending_bids(rng: RandomNumberGenerator) -> void:
	if pending_bids.is_empty():
		return
	var due: Array = pending_bids
	pending_bids = []
	for b in due:
		var res: Dictionary
		if str(b.get("kind", "")) == "external":
			res = sign_external(b.get("player", {}), b.get("club", {}), int(b.get("offer", 0)),
				rng, int(b.get("weekly", -1)), int(b.get("years", -1)),
				b.get("clauses", []), int(b.get("bonus", 0)), false)
		else:
			res = sign_player(int(b.get("pid", -1)), int(b.get("club_id", -1)),
				int(b.get("offer", 0)), rng, int(b.get("weekly", -1)), int(b.get("years", -1)),
				b.get("clauses", []), int(b.get("bonus", 0)), false)
		# The club's answer pops on the hub (the "days later" reply). Accepted deals
		# already write their own "You have signed ..." news line; a rejection (or a
		# collapsed deal — squad full / cash gone) also posts to the news log.
		var msg := str(res.get("msg", ""))
		if msg != "":
			pending_alerts.append(msg)
		if not bool(res.get("ok", false)):
			_log(msg)


func sign_player(pid: int, from_club_id: int, offer: int, rng: RandomNumberGenerator,
		weekly: int = -1, years: int = -1, clauses: Array = [], bonus: int = 0,
		count_offer: bool = true) -> Dictionary:
	# count_offer=false = resolving a bid placed earlier (place_bid already charged the
	# board allowance and the window was open at placement) — skip the placement gates.
	if count_offer and not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if count_offer and offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed. You can not sign more." % TransferMarket.SQUAD_MAX}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var player := _find_in(from_club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	if count_offer:
		offers_left -= 1   # an offer counts whether or not it is accepted
	var is_key := TransferMarket.is_key_player(club_view(from_club_id), pid)
	var verdict := TransferMarket.evaluate_offer(player, offer, is_key, band_of(from_club_id), rng)
	var seller_name: String = club_names.get(from_club_id, "?")
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s have rejected your offer for %s." % [seller_name, player.get("name", "?")]}
	rosters[from_club_id].erase(player)
	player["clubId"] = club_id
	var term := years if years > 0 else TransferMarket.NEW_CONTRACT_YEARS
	player["contract_years"] = term
	player["contract_term"] = term
	Contract.stamp_wage(player, my_band())   # his wage joins your live bill
	if weekly > 0:
		player["wage"] = weekly          # the card's negotiated YEARLY WAGE / 52
	if not clauses.is_empty():
		player["clauses"] = clauses.duplicate()
		if clauses.has(1):
			player["clause_apps"] = 0
		if clauses.has(2):
			player["clause_goals"] = 0
			if bonus > 0:
				player["clause_bonus"] = bonus
	player["auto_renew"] = false
	Morale.ensure(player, rng)
	_signing_shock(player)   # the incumbents in his position take it badly (FUN_00588ae0)
	rosters[club_id].append(player)
	cash -= offer
	transfer_listed.erase(pid)
	shortlist.erase(pid)
	_log("You have signed %s from %s for £%s." % [player.get("name", "?"), seller_name, _money(offer)])
	# NEWS EXTRA MARKET feed (witnessed "Wilson signs for Barnsley for one season.").
	_news("transfer", "%s signs for %s for %s." % [
		player.get("name", "?"), club_name, TransferMarket.seasons_phrase(term)])
	return {"ok": true, "msg": "You have signed %s." % player.get("name", "?")}

## Bid for a player OUTSIDE the live rosters — the OFFERS map browse (any
## non-own-division English club or a foreign club, docs/re/offers_map_re.md).
## `player` is the GameDB player dict, `selling_club` the GameDB club dict.
## Same board guards + TransferMarket evaluation as sign_player; on success a
## COPY joins the live squad through the _seed_squad stamping (the source club
## is static data — our foreign/other-division clubs don't mutate, the same
## documented scope as "AI clubs don't develop"). `external_signed` hides him
## from future browses of that static squad.
func sign_external(player: Dictionary, selling_club: Dictionary, offer: int,
		rng: RandomNumberGenerator, weekly: int = -1, years: int = -1,
		clauses: Array = [], bonus: int = 0, count_offer: bool = true) -> Dictionary:
	if count_offer and not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if count_offer and offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed. You can not sign more." % TransferMarket.SQUAD_MAX}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var pid := int(player.get("id", -1))
	if external_signed.has(pid) or not _find_in(club_id, pid).is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	if count_offer:
		offers_left -= 1   # an offer counts whether or not it is accepted
	var is_key := TransferMarket.is_key_player(selling_club, pid)
	var sell_band := TransferMarket.stature_of(selling_club.get("players", []), TransferMarket.english_tier_of(selling_club, _leagues))
	var verdict := TransferMarket.evaluate_offer(player, offer, is_key, sell_band, rng)
	var seller_name := str(selling_club.get("name", "?"))
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s have rejected your offer for %s." % [seller_name, player.get("name", "?")]}
	var joined: Dictionary = player.duplicate(true)
	joined["clubId"] = club_id
	var term := years if years > 0 else TransferMarket.NEW_CONTRACT_YEARS
	joined["contract_years"] = term
	joined["contract_term"] = term
	joined["injured_weeks"] = 0
	joined["suspended_weeks"] = 0
	joined["yellows"] = 0
	joined["dev_progress"] = 0.0
	joined["auto_renew"] = false
	Contract.stamp_wage(joined, my_band())
	if weekly > 0:
		joined["wage"] = weekly
	if not clauses.is_empty():
		joined["clauses"] = clauses.duplicate()
		if clauses.has(1):
			joined["clause_apps"] = 0
		if clauses.has(2):
			joined["clause_goals"] = 0
			if bonus > 0:
				joined["clause_bonus"] = bonus
	Morale.ensure(joined, rng)
	joined["fitness"] = 70
	_signing_shock(joined)
	rosters[club_id].append(joined)
	cash -= offer
	external_signed[pid] = true
	_log("You have signed %s from %s for £%s." % [joined.get("name", "?"), seller_name, _money(offer)])
	_news("transfer", "%s signs for %s for %s." % [
		joined.get("name", "?"), club_name, TransferMarket.seasons_phrase(term)])
	return {"ok": true, "msg": "You have signed %s." % joined.get("name", "?")}

## Sign a free agent for NO fee on `offer_weekly` £/wk (default = his demand). It is a wage
## NEGOTIATION (reuses Contract.evaluate_renewal): he accepts at/above his demand, may balk
## just below, refuses a lowball. On success he joins your live squad + wage bill. {ok, msg,
## demanded}. Same board guards as a transfer (window, weekly offers, squad max), minus cash
## (there is no fee). A free signing still spends one of the week's offers.
func sign_free_agent(pid: int, offer_weekly: int = -1, rng: RandomNumberGenerator = null) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed." % TransferMarket.SQUAD_MAX}
	var player: Dictionary = {}
	for p in free_agents:
		if int(p.get("id", -1)) == pid:
			player = p
			break
	if player.is_empty():
		return {"ok": false, "msg": "That free agent is no longer available."}
	if offer_weekly < 0:
		offer_weekly = Contract.demanded_weekly(player, my_band())
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	offers_left -= 1   # an offer counts whether or not it is accepted
	var pname: String = player.get("name", "?")
	var verdict := Contract.evaluate_renewal(player, offer_weekly, my_band(), rng)
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s has rejected your terms." % pname, "demanded": int(verdict["demanded"])}
	free_agents.erase(player)
	player.erase("free_agent")
	player["clubId"] = club_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	player["contract_term"] = TransferMarket.NEW_CONTRACT_YEARS
	player["wage"] = offer_weekly
	player["auto_renew"] = false
	Morale.ensure(player, rng)
	_signing_shock(player)
	rosters[club_id].append(player)
	_log("You have signed free agent %s on £%s/wk." % [pname, _money(offer_weekly)])
	_news("transfer", "%s signs for %s for %s." % [
		pname, club_name, TransferMarket.seasons_phrase(TransferMarket.NEW_CONTRACT_YEARS)])
	return {"ok": true, "msg": "You have signed %s on a free." % pname, "demanded": int(verdict["demanded"])}


## Players you can take on loan (other clubs' fringe), best first. {} -> none.
func loan_market() -> Array:
	return TransferMarket.loan_market(rosters, club_names, tier, club_id)


## A SCOUT's transfer report (T2 #10): the best affordable targets across the league, most
## able first, as many as the scout's quality. [] when you have no scout hired.
func scout_targets() -> Array:
	if not Staff.has_scout(staff):
		return []
	var affordable: Array = market().filter(func(r): return int(r["fee"]) <= cash)
	affordable.sort_custom(func(a, b): return int(a["ca"]) > int(b["ca"]))
	return affordable.slice(0, Staff.scout_quality(staff))


## Take player `pid` on loan from `from_club_id` for the season: no fee, you pay his wage,
## and he RETURNS to his parent club at the next rollover. Same board guards as a signing
## (window, weekly offers, squad max). {ok, msg}.
func sign_loan(pid: int, from_club_id: int) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed." % TransferMarket.SQUAD_MAX}
	var player := _find_in(from_club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer available to loan."}
	offers_left -= 1
	rosters[from_club_id].erase(player)
	var parent_name: String = club_names.get(from_club_id, "?")
	player["on_loan"] = true
	player["loan_from"] = from_club_id
	player["loan_from_name"] = parent_name
	player["wage"] = Contract.market_weekly(player, my_band())   # you pick up his wages
	player["clubId"] = club_id
	_signing_shock(player)   # a loan arrival unsettles the position just the same
	rosters[club_id].append(player)
	_log("You have taken %s on loan from %s for the season." % [player.get("name", "?"), parent_name])
	return {"ok": true, "msg": "You have signed %s on loan." % player.get("name", "?")}


## Loanees in the manager's squad return to their parent clubs (called at the rollover,
## before contracts tick, so a loanee is never mistaken for one of your expiring players).
func _return_loanees() -> void:
	var returning: Array = []
	for p in rosters.get(club_id, []):
		if p.get("on_loan"):
			returning.append(p)
	for p in returning:
		rosters[club_id].erase(p)
		var parent := int(p.get("loan_from", -1))
		var pname: String = str(p.get("loan_from_name", "his club"))
		p.erase("on_loan")
		p.erase("loan_from")
		p.erase("loan_from_name")
		if rosters.has(parent):
			rosters[parent].append(p)
		_news("contract", "%s has returned to %s at the end of his loan." % [p.get("name", "?"), pname])


func is_listed(pid: int) -> bool:
	return transfer_listed.has(pid)

func toggle_listed(pid: int) -> void:
	if transfer_listed.has(pid):
		transfer_listed.erase(pid)
		sale_offers.erase(pid)   # withdrawing the listing withdraws the bids
	else:
		transfer_listed[pid] = true


# ---- CURRENT OFFERS (bids on your transfer-listed players) ----------------
# The screen (FICHAR hub -> CURRENT OFFERS, FUN_00523dc4/FUN_00523ed0) shows up
# to 5 listed players, each with up to 5 offer rows CLUB | CLUB OFFER | YEARLY
# WAGE | YEARS | CLAUSES. The accumulation model here is OURS (calibrated to
# TransferMarket.solicit_offer); only the screen surface is PM98's.

const MAX_OFFERS_PER_PLAYER := 5     # the band has 5 offer rows
const OFFER_CHANCE_PER_WEEK := 0.45  # a listed player draws interest most weeks

## Roll this week's incoming bids on the transfer-listed players (advance_week).
## Also drops stale entries for players no longer in the squad.
func _accumulate_offers(rng: RandomNumberGenerator) -> void:
	for pid in sale_offers.keys():
		if not transfer_listed.has(pid) or _find_in(club_id, int(pid)).is_empty():
			sale_offers.erase(pid)
	if not transfers_open():
		return
	for pid in transfer_listed:
		var p := _find_in(club_id, int(pid))
		if p.is_empty():
			continue
		var lst: Array = sale_offers.get(int(pid), [])
		if lst.size() >= MAX_OFFERS_PER_PLAYER or rng.randf() > OFFER_CHANCE_PER_WEEK:
			continue
		var o := TransferMarket.solicit_offer(p, rosters, club_names, tier, club_id, rng)
		if o.is_empty():
			continue
		lst.append({
			"buyer_id": int(o["buyer_id"]), "buyer_name": str(o["buyer_name"]),
			"offer": int(o["offer"]),
			# The terms the buyer tables for the player (YEARLY WAGE / YEARS rows).
			"weekly_wage": Contract.market_weekly(p, band_of(int(o["buyer_id"]))),
			"years": 1 + rng.randi_range(0, 2), "week": week,
		})
		sale_offers[int(pid)] = lst
		_news("transfer", "%s have made an offer for %s." % [o["buyer_name"], p.get("name", "?")])

## The live offer list for one of your listed players (CURRENT OFFERS rows).
func offers_for(pid: int) -> Array:
	return sale_offers.get(pid, [])

## Accept offer #idx on player pid: the sale goes through accept_sale (same squad
## guards) and every other bid on him lapses. {ok, msg}.
func accept_offer(pid: int, idx: int) -> Dictionary:
	var lst: Array = sale_offers.get(pid, [])
	if idx < 0 or idx >= lst.size():
		return {"ok": false, "msg": "That offer is no longer on the table."}
	var o: Dictionary = lst[idx]
	var res := accept_sale(pid, int(o["buyer_id"]), int(o["offer"]))
	if res.get("ok"):
		sale_offers.erase(pid)
	return res

## Refuse offer #idx on player pid (the bid is withdrawn; the listing stays).
func refuse_offer(pid: int, idx: int) -> Dictionary:
	var lst: Array = sale_offers.get(pid, [])
	if idx < 0 or idx >= lst.size():
		return {"ok": false, "msg": "That offer is no longer on the table."}
	var o: Dictionary = lst[idx]
	lst.remove_at(idx)
	if lst.is_empty():
		sale_offers.erase(pid)
	else:
		sale_offers[pid] = lst
	var p := _find_in(club_id, pid)
	return {"ok": true, "msg": "Refused %s's offer for %s." % [o.get("buyer_name", "?"),
		p.get("name", "?")]}

## The best AI offer for one of your players (used by the SALE screen). {} if none.
func solicit_sale(pid: int, rng: RandomNumberGenerator) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {}
	return TransferMarket.solicit_offer(player, rosters, club_names, tier, club_id, rng)

## Accept an AI offer for your player. Mutates squads + cash. {ok, msg}. Guards the
## squad floor so you can't sell yourself unable to field a side.
func accept_sale(pid: int, buyer_id: int, offer: int) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer here."}
	if player.get("on_loan"):
		return {"ok": false, "msg": "%s is only on loan; you can't sell him." % player.get("name", "?")}
	var squad := my_squad()
	if squad.size() <= TransferMarket.SQUAD_MIN:
		return {"ok": false, "msg": "Your squad is too small to sell (min %d)." % TransferMarket.SQUAD_MIN}
	if player.get("isGK") and TransferMarket._count_keepers(squad) <= TransferMarket.MIN_KEEPERS:
		return {"ok": false, "msg": "You must keep at least %d goalkeepers." % TransferMarket.MIN_KEEPERS}
	rosters[club_id].erase(player)
	player["clubId"] = buyer_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	player["contract_term"] = TransferMarket.NEW_CONTRACT_YEARS
	if rosters.has(buyer_id):
		rosters[buyer_id].append(player)
	cash += offer
	transfer_listed.erase(pid)
	var buyer_name: String = club_names.get(buyer_id, "?")
	_log("%s has been signed by %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)])
	return {"ok": true, "msg": "Sold %s to %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)],
		# For the hub alert box (EXE string "%s has been signed by %s%s.", frame 093):
		# the view composes + cases these (names here are raw cipher-UPPERCASE).
		"player_name": str(player.get("name", "?")), "buyer_name": buyer_name}

## SACK a squad player (the PLAYER INFORMATION button): terminate his contract now. He leaves
## for free and joins the free-agent pool; you pay off the balance of his deal as compensation
## (COMPENSATIONS OF CONTRACT = the remaining contract years' wage). Same squad-floor guards as
## a sale (you can't sack yourself unable to field a side / below the keeper minimum), and a
## loaned-in player is returned, not sackable. {ok, msg, compensation}.
func release(pid: int) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is not in your squad."}
	if player.get("on_loan"):
		return {"ok": false, "msg": "%s is only on loan; you can't sack him." % player.get("name", "?")}
	var squad := my_squad()
	if squad.size() <= TransferMarket.SQUAD_MIN:
		return {"ok": false, "msg": "Your squad is too small to sack anyone (min %d)." % TransferMarket.SQUAD_MIN}
	if player.get("isGK") and TransferMarket._count_keepers(squad) <= TransferMarket.MIN_KEEPERS:
		return {"ok": false, "msg": "You must keep at least %d goalkeepers." % TransferMarket.MIN_KEEPERS}
	var weekly := Contract.current_weekly(player, my_band())
	var comp := weekly * Contract.SEASON_WEEKS * maxi(1, int(player.get("contract_years", 1)))
	var pname: String = player.get("name", "?")
	rosters[club_id].erase(player)
	transfer_listed.erase(pid)
	shortlist.erase(pid)
	player["clubId"] = -1                 # now a free agent (no club)
	player["auto_renew"] = false
	free_agents.append(player)
	cash -= comp
	_log("You have sacked %s; paid £%s compensation of contract." % [pname, _money(comp)])
	return {"ok": true, "msg": "Sacked %s. Paid £%s compensation." % [pname, _money(comp)],
		"compensation": comp}


## Offer a squad player a renewal at `offer_weekly` £/wk (default = meet his demand). It is a
## NEGOTIATION: he accepts at/above his wage demand, may balk just below it, and refuses a
## lowball -- "%s has rejected your offer for renewal." On acceptance his term resets and his
## stored wage updates (so a raise flows into the live wage bill). {ok, msg, demanded}.
func renew(pid: int, offer_weekly: int = -1, rng: RandomNumberGenerator = null) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is not in your squad."}
	if offer_weekly < 0:
		offer_weekly = Contract.demanded_weekly(player, my_band())
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var verdict := Contract.evaluate_renewal(player, offer_weekly, my_band(), rng)
	var pname: String = player.get("name", "?")
	if not verdict["accepted"]:
		_log("%s has rejected your offer for renewal." % pname)
		return {"ok": false, "msg": "%s has rejected your offer for renewal." % pname,
			"demanded": int(verdict["demanded"])}
	player["contract_years"] = Contract.NEW_TERM_YEARS
	player["contract_term"] = Contract.NEW_TERM_YEARS
	player["wage"] = offer_weekly
	_log("%s has renewed his contract." % pname)
	return {"ok": true, "msg": "%s has renewed his contract on £%s/wk." % [pname, _money(offer_weekly)],
		"demanded": int(verdict["demanded"])}

## Toggle a player's auto-renew flag. An expiring deal with auto-renew on is renewed at his
## demand at the next season rollover (if you can afford it), instead of him leaving on a free.
func set_auto_renew(pid: int, on: bool) -> void:
	var player := _find_in(club_id, pid)
	if not player.is_empty():
		player["auto_renew"] = on

func toggle_shortlist(pid: int) -> void:
	if shortlist.has(pid):
		shortlist.erase(pid)
	else:
		shortlist.append(pid)

func _money(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


# ---- season rollover -----------------------------------------------------

## Roll the career into the next season, KEEPING the live rosters, cash and tactics.
## Contracts tick down; any of your players who hit zero and weren't renewed leave on
## a free. Fixtures, table and objective are rebuilt from the current squads.
func advance_season(leagues: Array, rng: RandomNumberGenerator = null, euro_pool: Array = [],
		sa_champion: Dictionary = {}, talent_pool: Array = []) -> void:
	# Fold the finished season's per-competition record into the career total while
	# results/brackets still hold it (MANAGER HISTORY's TOTAL view).
	_fold_comp_total()
	# Capture this season's honours BEFORE the table + European brackets are rebuilt --
	# they seed next season's Charity Shield, European qualification, and the
	# Supercup/Intercontinental (which need this season's European winners + ratings).
	_capture_honours()
	_capture_euro_honours()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	_return_loanees()   # loanees go home before contracts tick (never counted as your leavers)
	var leavers: Array = []
	for p in rosters.get(club_id, []):
		var yrs := int(p.get("contract_years", 1)) - 1
		p["contract_years"] = yrs
		p["age"] = int(p.get("age", 26)) + 1   # your squad ages a year (drives training)
		if yrs > 0:
			continue
		# Contract up. An auto-renew player is re-signed at his demand if the club can fund the
		# deal (a season's wage); otherwise -- and for everyone without auto-renew -- he leaves
		# on a FREE TRANSFER. You tie a player down in advance via the RENEW screen.
		var demand_wk := Contract.demanded_weekly(p, my_band())
		var affordable := Contract.yearly(demand_wk) <= cash
		# An ASSISTANT MANAGER (T2 #10) re-signs an expiring player good enough to keep, so your
		# stars don't walk for free while you're not looking. His quality lowers the CA bar
		# (q5 keeps CA>=60, q1 keeps CA>=72); needs no auto_renew flag, only affordability.
		var aq := Staff.assistant_quality(staff)
		var ca := int(p.get("attrs", {}).get("CA", 0))
		var assistant_keeps := aq > 0 and ca >= 75 - aq * 3
		if (p.get("auto_renew") or assistant_keeps) and affordable:
			p["contract_years"] = Contract.NEW_TERM_YEARS
			p["contract_term"] = Contract.NEW_TERM_YEARS
			p["wage"] = demand_wk
			var how := "auto" if p.get("auto_renew") else "assistant"
			_news("staff" if how == "assistant" else "contract",
				"%s has renewed his contract (%s)." % [p.get("name", "?"), how])
			_log("%s has renewed his contract on £%s/wk (%s)." % [p.get("name", "?"), _money(demand_wk), how])
		else:
			leavers.append(p)
	# A fresh batch of free agents for the new season; the manager's own released players join
	# the pool (you can re-sign one for nothing but a wage), capped so it never grows forever.
	free_agents = TransferMarket.generate_free_agents(rng, FREE_POOL_SIZE, free_seq)
	free_seq += FREE_POOL_SIZE
	for p in leavers:
		rosters[club_id].erase(p)
		p["free_agent"] = true
		p["contract_years"] = 0
		p.erase("auto_renew")
		free_agents.append(p)
		_news("contract", "%s has left on a free (contract not renewed)." % p.get("name", "?"))
		_log("%s has left your club as his contract has not been renewed." % p.get("name", "?"))
	if free_agents.size() > FREE_POOL_CAP:
		free_agents = free_agents.slice(free_agents.size() - FREE_POOL_CAP)
	# AI contracts tick but auto-renew, so rival squads stay stable across years. Their
	# players age a year and the season resets like the manager's (#12 living league): bans
	# and injuries clear, the development carry-over zeroes, so the dev engine re-evaluates
	# each rival from his new age (young rivals keep climbing, veterans keep sliding).
	for cid in rosters:
		if int(cid) == club_id:
			continue
		for p in rosters[cid]:
			p["contract_years"] = maxi(1, int(p.get("contract_years", 2)) - 1) + 1
			p["age"] = int(p.get("age", 26)) + 1
		Availability.reset(rosters[cid])
		Training.reset_progress(rosters[cid])
	# Fresh season = clean slate: bans don't carry over, everyone reports fit, and the
	# development carry-over is zeroed (ages just ticked, so trends re-evaluate).
	Availability.reset(rosters.get(club_id, []))
	Training.reset_progress(rosters.get(club_id, []))
	# The EXE's roster reset (FUN_005825c0) re-rolls every squad's dynamic form:
	# morale 90 + rand(10), fitness halfway back toward 40 (docs/re/morale_re.md).
	# Own RNG (seed folded with the year) so the reset's randomness stays
	# reproducible without perturbing the shared rollover stream downstream.
	var srng := RandomNumberGenerator.new()
	srng.seed = rng.seed ^ (int(year) * 0x85EBCA77)
	for cid in rosters:
		for p in rosters[cid]:
			Morale.season_init(p, srng)
	# The youth team ages a year too: anyone over the graduation age who was never
	# promoted is released to make room, then the scout brings in a fresh crop.
	_roll_youth(rng)
	# A fresh batch of staff comes onto the market for the new season.
	staff_pool = Staff.generate_pool(rng, staff_seq, STAFF_POOL_PER_ROLE)
	staff_seq += staff_pool.size()

	year += 1
	season = _season_label(year)
	week = 0
	finished = false
	season_opened = false   # the week-0 chain (shield card + START OF SEASON) re-runs
	boards_sold_season = false   # a fresh sponsor-board season offer becomes available again
	_reset_insurance_ledger()    # the FINANCES insurance lines are season-to-date
	# The STATISTICS store is per SEASON (its header reads "STATISTICS FOR <club>." with
	# no year, and a fresh career's table is all dashes), so it clears with the results.
	season_stats.clear()
	season_club_minutes.clear()
	season_club_mp.clear()
	results.clear()
	# Preseason friendlies were a career-entry pick; season 2+ has no re-pick UI
	# (un-walked — the walkthrough started one career), so the slate just clears.
	preseason_rivals.clear()
	friendlies_played = 0
	friendly_results.clear()
	transfer_listed.clear()
	offers_left = OFFERS_PER_WEEK
	_log("--- %s season ---" % season)
	# Real talents scheduled for the season just started (easter-egg lane; empty pool =
	# the vanilla port). After the label flip so 1998-99's crop lands IN 1998-99, and
	# before the roster views below so fixtures/objective/finances see the new arrivals.
	_inject_real_talents(rng, talent_pool)

	# End-of-season pyramid movement (witnessed zone structure): promotions,
	# relegations and playoff winners reshuffle all four English divisions —
	# including the manager's club, whose career follows its finish. Mutates
	# rosters/club_names/tier/league_id/seed orders; the rebuild below then
	# operates on the NEW membership. No-op without pyramid context.
	_pyramid_rollover(rng)

	var ids: Array = rosters.keys()
	var views: Array = []
	for id in ids:
		views.append(club_view(id))
	fixtures = SeasonSim.fixtures(ids)
	fa_cup = Cup.create(ids, fixtures.size())   # a fresh F.A. Cup each season
	league_cup = Cup.create(ids, fixtures.size(), LEAGUE_CUP_OPTS)
	_init_table(views)
	var league := {"id": league_id, "name": league_name, "tier": tier}
	# Season 2+: the witnessed labels are the 1997-98 board table; later seasons'
	# boards are un-witnessed, so the strength-ranked fallback applies ({} club).
	_set_objective({}, league, views, leagues)
	var fin := FinanceModel.summary(club_view(club_id), tier)
	weekly_net = int(fin["weekly_balance"]) + int(fin["weekly_wages"])  # wage-free; wages drawn live
	# Refit the XI to the (possibly changed) squad while keeping the shape.
	if not tactics.is_empty():
		var t := Tactics.from_dict(tactics)
		t.set_formation(t.formation, club_view(club_id))
		tactics = t.to_dict()
	# The Charity Shield opens the new season: last season's champions v F.A. Cup winners.
	_play_charity_shield(rng)
	# European competitions for the new season, seeded from last season's honours.
	mint_european_cups(euro_pool, rng)
	# Winners-of-winners curtain-raisers from last season's European champions.
	_play_euro_supercups(sa_champion, rng)


## Record the just-finished season's league champion, runners-up order and F.A. Cup
## winner. Called at the top of advance_season, before the table is rebuilt.
func _capture_honours() -> void:
	# With the living pyramid, the LEAGUE honours (Charity Shield + European
	# berths) belong to the PREMIER table whichever division the manager is in;
	# without it (headless careers) the manager's division stands in as before.
	var s := standings_for(1) if has_division(1) else standings()
	if not s.is_empty():
		last_champion_id = int(s[0].get("id", -1))
		last_runners_up = []
		for i in range(1, s.size()):
			last_runners_up.append(int(s[i].get("id", -1)))
	last_fa_winner_id = Cup.champion_id(fa_cup)
	last_lc_winner_id = Cup.champion_id(league_cup)


## Play the Charity Shield (champions v F.A. Cup winners) as the season's curtain-raiser.
## If one club holds both honours (the Double), the league runners-up take the second
## berth -- PM98 fills the vacancy the same way. Stores the result, pays the manager a
## modest prize if his club lifts it, and writes a news line either way. No-ops in a
## first season (no prior honours to contest).
func _play_charity_shield(rng: RandomNumberGenerator) -> void:
	charity_shield = {}
	charity_shield_pending = false
	var champ := last_champion_id
	var fa := last_fa_winner_id
	if champ == -1:
		_seed_first_season_shield(rng)   # no played 96-97 season -> the fixed-participant opener
		return
	if fa == -1 or fa == champ:
		# Double winners (or no F.A. Cup last year): the league runners-up step up.
		fa = int(last_runners_up[0]) if not last_runners_up.is_empty() else -1
	if fa == -1 or fa == champ:
		return
	_stage_charity_shield(champ, fa, rng)


## First-season curtain-raiser. The app has no played 96-97 season, but its honours are
## fixed history: Man Utd (96-97 champions) v Chelsea (96-97 F.A. Cup winners). Staged the
## same way as every later shield (fixed participants).
func _seed_first_season_shield(rng: RandomNumberGenerator) -> void:
	_stage_charity_shield(S1_SHIELD_CHAMPION_ID, S1_SHIELD_RUNNERUP_ID, rng)


## Stage the Charity Shield between `champ` (champions, home/first-named) and `fa` (F.A. Cup
## winners). PM98 plays it as a REAL match -- witnessed live 2026-07-23 (winner AND decider
## vary between fresh careers). If the MANAGER is one of the two contestants he PLAYS it as
## his first fixture (`charity_shield_pending`; resolved by play_charity_shield_match); a
## non-participant sees it auto-resolved into the CHARITY SHIELD CHAMPION card, exactly like
## the wine original shows a Barnsley manager Man Utd v Chelsea already decided.
func _stage_charity_shield(champ: int, fa: int, rng: RandomNumberGenerator) -> void:
	if champ == -1 or fa == -1 or champ == fa:
		return
	if club_id == champ or club_id == fa:
		# The manager contests it himself -> play it (Main._career_advance).
		charity_shield = {"champ_id": champ, "fa_id": fa, "season": season}
		charity_shield_pending = true
		return
	# Non-participant: auto-resolve now (Cup.single_neutral_match) into the card + news.
	charity_shield_pending = false
	var ratings_fn := func(id: int) -> Dictionary: return _ratings_for(id)
	var xi_fn := func(id: int) -> Array: return _xi_for(id)
	var tie := Cup.single_neutral_match(rng, champ, fa, ratings_fn, xi_fn)
	tie["champ_id"] = champ
	tie["fa_id"] = fa
	tie["season"] = season
	charity_shield = tie
	var w := int(tie["winner_id"])
	var l := int(tie["loser_id"])
	var pens := " (on penalties)" if tie.get("decided", "") == "pens" else ""
	# club_names is the manager's own division; a lower-division manager still gets the card
	# (names resolve via GameDB in Main). Post news only when both clubs are in this table.
	if club_names.has(w) and club_names.has(l):
		_news("cup", "Charity Shield: %s beat %s%s." % [
			str(club_names[w]), str(club_names[l]), pens])


## The Charity Shield fixture the manager must PLAY (he is a contestant), or {} when there is
## none (already played, or he isn't in it). {champ_id, fa_id, opp_id, home} -- the champions
## are the home / first-named side (witnessed "Manchester Utd. v Chelsea").
func pending_charity_shield() -> Dictionary:
	if not charity_shield_pending:
		return {}
	var champ := int(charity_shield.get("champ_id", -1))
	var fa := int(charity_shield.get("fa_id", -1))
	if champ == -1 or fa == -1 or (club_id != champ and club_id != fa):
		return {}
	var at_home := club_id == champ
	return {"champ_id": champ, "fa_id": fa, "opp_id": (fa if at_home else champ), "home": at_home}


## Play the manager's Charity Shield against `opp_view` (the other contestant, roster-loaded).
## Same engine path as play_friendly (his real repaired XI); the champions are the home side.
## A level result is decided on penalties (Cup.shootout) like the auto path. Stores the final
## result into `charity_shield`, awards the prize if he lifts it, clears the pending flag, and
## returns the advance_week manager_res shape (+ friendly/charity flags) for the same
## MatchScreen presentation. Returns {} if there is no pending shield.
func play_charity_shield_match(rng: RandomNumberGenerator, opp_view: Dictionary) -> Dictionary:
	var p := pending_charity_shield()
	if p.is_empty():
		return {}
	var champ := int(p["champ_id"])
	var fa := int(p["fa_id"])
	var at_home := bool(p["home"])        # manager manages the champions -> home
	var my_ratings := _ratings_for(club_id)
	var my_xi := _mgr_featured_xi()
	var opp_ratings := MatchEngine.team_ratings(opp_view)
	var opp_xi := MatchSim.xi_of(opp_view)
	var h := champ                        # champions are always the first-named / home side
	var a := fa
	var res := MatchSim.simulate(rng,
		my_ratings if at_home else opp_ratings,
		opp_ratings if at_home else my_ratings,
		my_xi if at_home else opp_xi,
		opp_xi if at_home else my_xi, h, a, 90, true)
	# The Shield counts in both club counters: the live witness's TEAM TOTAL MP of 7 is
	# 6 league rounds + this fixture (see `season_club_mp`).
	fold_match_stats(res, h, a)
	var hg := int(res["home_goals"])
	var ag := int(res["away_goals"])
	var decided := ""
	var winner := h if hg > ag else a
	if hg == ag:
		var rh := my_ratings if at_home else opp_ratings
		var ra := opp_ratings if at_home else my_ratings
		winner = Cup.shootout(rng, h, a, rh, ra)
		decided = "pens"
	var loser := a if winner == h else h
	charity_shield = {"champ_id": champ, "fa_id": fa, "season": season,
		"home_id": h, "away_id": a, "hg": hg, "ag": ag,
		"winner_id": winner, "loser_id": loser, "decided": decided, "bye": false}
	charity_shield_pending = false
	var pens := " (on penalties)" if decided == "pens" else ""
	if winner == club_id:
		cash += CHARITY_PRIZE
		if club_names.has(winner) and club_names.has(loser):
			_news("cup", "%s have won the Charity Shield, beating %s%s." % [
				str(club_names[winner]), str(club_names[loser]), pens])
	elif club_names.has(winner) and club_names.has(loser):
		_news("cup", "Charity Shield: %s beat %s%s." % [
			str(club_names[winner]), str(club_names[loser]), pens])
	return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
		"manager_home": at_home, "goals": res.get("goals", []),
		"possession": res.get("possession", []), "friendly": true, "charity": true}


## Build this season's European competitions from last season's honours. `euro_pool` is
## an array of foreign club dicts ({id,name,players}) the caller draws from GameDB; their
## ratings + names are FROZEN here so the brackets resolve and save without GameDB. Each
## comp's field = the domestic qualifier(s) + a draw of foreign clubs (distinct across our
## three competitions). No-op until a first season has produced honours, or if the pool is
## too small to fill a field. Called from advance_season after the new fixtures are set.
func mint_european_cups(euro_pool: Array, rng: RandomNumberGenerator,
		domestic_clubs: Array = []) -> void:
	euro = {}
	euro_ratings = {}
	euro_names = {}
	euro_seeds = {}
	if last_champion_id == -1 or euro_pool.is_empty():
		return
	# Out-of-roster domestic seeds (a lower-division career: the honours belong to
	# clubs outside the managed division) resolve through the same frozen-ratings
	# path as the foreign entrants — the caller passes their GameDB club dicts.
	for club in domestic_clubs:
		var did := int(club.get("id", -1))
		if did != -1 and not rosters.has(did) and not euro_ratings.has(did):
			euro_ratings[did] = MatchEngine.team_ratings(club)
			euro_names[did] = str(club.get("name", "?"))
	var bag: Array = []
	for club in euro_pool:
		var id := int(club.get("id", -1))
		if id == -1 or rosters.has(id) or euro_ratings.has(id):
			continue                       # skip our own clubs + duplicates
		euro_ratings[id] = MatchEngine.team_ratings(club)
		euro_names[id] = str(club.get("name", "?"))
		bag.append(id)
	if bag.size() < EURO_FIELD - UEFA_SPOTS:
		return                             # not enough foreign clubs to fill even one field
	# Shuffle the foreign pool once, then deal distinct clubs to each competition.
	for i in range(bag.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: Variant = bag[i]
		bag[i] = bag[j]
		bag[j] = tmp
	# Domestic berths (the witnessed 1997-98 entry list, TEAMS IN CHAMPIONSHIPS
	# orig/06): European Cup = champions + first runners-up (the real 97-98 2-spot
	# format, Man Utd + Newcastle); U.E.F.A. Cup = next runners-up + the League Cup
	# winners (Arsenal, Liverpool, Leicester, Aston Villa); Cup Winners' Cup = the
	# F.A. Cup winners (Chelsea).
	var uefa: Array = []
	for cand in [_ru(1), _ru(2), last_lc_winner_id, _ru(3)]:
		var cid := int(cand)
		if cid != -1 and cid != last_champion_id and cid != _ru(0) and not uefa.has(cid):
			uefa.append(cid)
	var seeds := {
		"european_cup": [last_champion_id, _ru(0)],
		"uefa_cup": uefa.slice(0, 4),
		"cup_winners_cup": [_cwc_seed()],
	}
	var cursor := 0
	for key in EURO_OPTS:
		var field: Array = []
		for s in seeds[key]:
			if int(s) != -1 and not field.has(int(s)):
				field.append(int(s))
		euro_seeds[key] = field.duplicate()   # the domestic entrants (champs screen)
		var need := EURO_FIELD - field.size()
		if cursor + need > bag.size():
			break                          # foreign pool exhausted; remaining comps skipped
		field += bag.slice(cursor, cursor + need)
		cursor += need
		var opts := {"name": str(EURO_OPTS[key]["name"]), "legs": 2,
			"two_legged_final": false, "label_scheme": "sequential",
			"qtr_label": "Quarter Finals", "prize_round": 0, "prize_winner": 0}
		# Only the European Cup runs a group phase (the real 1997-98 format): the 16-club
		# field is drawn into 4 groups of 4, double round-robin, top 2 into the knockout.
		# The U.E.F.A. Cup and Cup Winners' Cup were straight knockouts that season.
		if key == "european_cup":
			opts["group_stage"] = {"groups": 4, "advance": 2}
		euro[key] = Cup.create(field, fixtures.size(), opts)
		if field.has(club_id):
			cash += EURO_ENTRY
			_news("cup", "Your club has entered the %s (1 million from UEFA for competing)."
				% str(EURO_OPTS[key]["name"]))


## The Cup Winners' Cup seed: last season's F.A. Cup winners, or the league runners-up if
## the F.A. Cup wasn't decided (defensive -- it always is in a full season).
func _cwc_seed() -> int:
	if last_fa_winner_id != -1:
		return last_fa_winner_id
	return int(last_runners_up[0]) if not last_runners_up.is_empty() else -1


## last_runners_up[i] or -1 (the qualification-list helper).
func _ru(i: int) -> int:
	return int(last_runners_up[i]) if i < last_runners_up.size() else -1


## Season-1 curtain-raiser state: seed the REAL 1996-97 honours (the original
## contests the Charity Shield + runs the European competitions from career
## start -- witnessed TEAMS IN CHAMPIONSHIPS orig/06) and mint the season's
## competitions from them. `honours` = {champion_id, fa_winner_id, lc_winner_id,
## runners_up: Array, euro_cup_winner: Dictionary club, cwc_winner: Dictionary
## club} -- ids resolved by the caller from GameDB (create() has no DB access).
## The shield itself plays via play_season_opener on the week-0 chain.
func open_first_season(honours: Dictionary, euro_pool: Array,
		sa_champion: Dictionary, rng: RandomNumberGenerator,
		domestic_clubs: Array = []) -> void:
	last_champion_id = int(honours.get("champion_id", -1))
	last_fa_winner_id = int(honours.get("fa_winner_id", -1))
	last_lc_winner_id = int(honours.get("lc_winner_id", -1))
	last_runners_up = []
	for v in honours.get("runners_up", []):
		last_runners_up.append(int(v))
	mint_european_cups(euro_pool, rng, domestic_clubs)
	# Last season's European winners (real 1996-97: Borussia D. lifted the European
	# Cup, F.C. Barcelona the Cup Winners' Cup) contest the Supercup +
	# Intercontinental curtain-raisers, exactly like a rollover season.
	var ecw: Dictionary = honours.get("euro_cup_winner", {})
	var cwcw: Dictionary = honours.get("cwc_winner", {})
	if not ecw.is_empty():
		euro_winner_cup = int(ecw.get("id", -1))
		euro_winner_ratings[euro_winner_cup] = MatchEngine.team_ratings(ecw)
		euro_winner_names[euro_winner_cup] = str(ecw.get("name", "?"))
	if not cwcw.is_empty():
		euro_winner_cwc = int(cwcw.get("id", -1))
		euro_winner_ratings[euro_winner_cwc] = MatchEngine.team_ratings(cwcw)
		euro_winner_names[euro_winner_cwc] = str(cwcw.get("name", "?"))
	_play_euro_supercups(sa_champion, rng)


## Play the Charity Shield on the week-0 curtain-raiser chain if it hasn't been
## contested yet this season (season 1: honours seeded by open_first_season;
## rollover seasons play it inside advance_season already, so this no-ops).
func play_season_opener(rng: RandomNumberGenerator) -> void:
	if charity_shield.is_empty():
		_play_charity_shield(rng)


## Capture last season's European Cup + Cup Winners' Cup winners and FREEZE their ratings
## before the brackets (and euro_ratings) are rebuilt, so the Supercup + Intercontinental
## can be contested at the start of the new season. Called at the top of advance_season,
## while the finished season's `euro` brackets + ratings are still live.
func _capture_euro_honours() -> void:
	euro_winner_cup = -1
	euro_winner_cwc = -1
	euro_winner_ratings = {}
	euro_winner_names = {}
	if euro.is_empty():
		return
	euro_winner_cup = Cup.champion_id(euro.get("european_cup", {}))
	euro_winner_cwc = Cup.champion_id(euro.get("cup_winners_cup", {}))
	for id in [euro_winner_cup, euro_winner_cwc]:
		if int(id) != -1:
			_freeze_winner(int(id))


## Freeze a club's current rating + name into the winners store (resolves via the live
## roster / euro_ratings BEFORE they are rebuilt).
func _freeze_winner(id: int) -> void:
	var r := _ratings_for(id)
	euro_winner_ratings[id] = {"att": r.get("att", 50), "def": r.get("def", 50), "gk": r.get("gk", 50)}
	euro_winner_names[id] = str(r.get("name", "?"))


## Play the winners-of-winners finals as the new season opens: the European Supercup
## (last season's European Cup winner v Cup Winners' Cup winner) and the Intercontinental
## Cup (European Cup winner v the South American champion -- `sa_champion`, a club dict the
## caller supplies from game_db; approximated by the strongest South American club). Both
## are single neutral matches (level -> penalties). No-op until a first European season has
## produced winners. Pays the manager a documented prize + a news line if his club is in.
func _play_euro_supercups(sa_champion: Dictionary, rng: RandomNumberGenerator) -> void:
	supercup = {}
	intercontinental = {}
	if euro_winner_cup == -1:
		return
	var r_fn := func(id: int) -> Dictionary:
		if euro_winner_ratings.has(int(id)):
			var r: Dictionary = (euro_winner_ratings[int(id)] as Dictionary).duplicate()
			r["name"] = str(euro_winner_names.get(int(id), "?"))
			return r
		return _ratings_for(int(id))
	# European Supercup: needs both winners, and distinct (else no fixture).
	if euro_winner_cwc != -1 and euro_winner_cwc != euro_winner_cup:
		var tie := Cup.single_neutral_match(rng, euro_winner_cup, euro_winner_cwc, r_fn)
		tie["season"] = season
		supercup = tie
		_record_supercup_news(tie, "European Supercup", SUPERCUP_PRIZE)
	# Intercontinental Cup: European Cup winner v the South American champion.
	if not sa_champion.is_empty():
		var sid := int(sa_champion.get("id", -1))
		if sid != -1 and sid != euro_winner_cup:
			euro_winner_ratings[sid] = MatchEngine.team_ratings(sa_champion)
			euro_winner_names[sid] = str(sa_champion.get("name", "?"))
			var t2 := Cup.single_neutral_match(rng, euro_winner_cup, sid, r_fn)
			t2["season"] = season
			intercontinental = t2
			_record_supercup_news(t2, "Intercontinental Cup", INTERCONTINENTAL_PRIZE)


## Bank the manager's prize (if his club lifted it) + a news line for a one-off final.
func _record_supercup_news(tie: Dictionary, comp: String, prize: int) -> void:
	var w := int(tie["winner_id"])
	var l := int(tie["loser_id"])
	var wn := str(euro_winner_names.get(w, club_names.get(w, "?")))
	var ln := str(euro_winner_names.get(l, club_names.get(l, "?")))
	var pens := " (on penalties)" if tie.get("decided", "") == "pens" else ""
	if w == club_id:
		cash += prize
		_news("cup", "%s have won the %s, beating %s%s." % [wn, comp, ln, pens])
	else:
		_news("cup", "%s: %s beat %s%s." % [comp, wn, ln, pens])


# ---- stadium expansion (WORKS) -------------------------------------------

## Begin one GROUND improvement: pay `cost` now, its effect lands after `weeks`. Refuses on
## short cash, an identical (cat,key) work already running, or a SEATS capacity-ceiling
## breach. cat: "seats" | "carpark" | "facility" | "service"; effect carries {added:int}
## (seats/carpark capacity delta) or {grade:int} (facilities/services target grade).
func begin_work(cat: String, key: int, label: String, cost: int, weeks: int,
		effect: Dictionary = {}) -> bool:
	if cost > cash:
		return false
	if cat == "seats" and stadium_capacity + _pending_seats() + int(effect.get("added", 0)) > MAX_STADIUM:
		return false
	for w in works:
		if str(w.get("cat")) == cat and int(w.get("key", -1)) == key:
			return false                 # that item is already under construction
	cash -= cost
	works.append({"cat": cat, "key": key, "label": label, "cost": cost,
		"weeks_left": maxi(1, weeks), "effect": effect})
	_news("stadium", "Ground works begun: %s (-£%s, ~%d wk)." % [label, _grp(cost), maxi(1, weeks)])
	return true


## SEATS committed but not yet built, so a second SEATS card can't overshoot the ceiling.
func _pending_seats() -> int:
	var s := 0
	for w in works:
		if str(w.get("cat")) == "seats":
			s += int((w.get("effect", {}) as Dictionary).get("added", 0))
	return s


## SEATS expansion (back-compat wrapper for Main + the SEATS offer card). One seat work at
## a time (key fixed at 0), matching the single WORK IN PROGRESS SEATS row (frame 07).
func start_works(added: int, cost: int, weeks: int) -> bool:
	if added <= 0:
		return false
	return begin_work("seats", 0, "%s seats" % _grp(added), cost, weeks, {"added": added})


## Tick every in-progress work one week; apply the effect of any that complete and refresh
## the weekly finance projection so a bigger gate feeds the books.
func _tick_works() -> void:
	if works.is_empty():
		return
	var done: Array = []
	for w in works:
		w["weeks_left"] = int(w["weeks_left"]) - 1
		if int(w["weeks_left"]) <= 0:
			_complete_work(w)
			done.append(w)
	for w in done:
		works.erase(w)
	if not done.is_empty():
		_recompute_weekly_net()


func _complete_work(w: Dictionary) -> void:
	var eff: Dictionary = w.get("effect", {})
	match str(w.get("cat")):
		"seats":
			stadium_capacity = mini(MAX_STADIUM, stadium_capacity + int(eff.get("added", 0)))
			_news("stadium", "Ground expansion complete: capacity now %s." % _grp(stadium_capacity))
		"carpark":
			var q := int(w.get("key", 0))
			if q >= 0 and q < car_park_levels.size():
				car_park_levels[q] = mini(CAR_PARK_MAX_LEVEL, int(car_park_levels[q]) + 1)
			_news("stadium", "Car park works complete: %s." % w.get("label", ""))
		_:  # facility / service
			ground_grades["%s:%d" % [str(w.get("cat")), int(w.get("key", 0))]] = int(eff.get("grade", 1))
			_news("stadium", "%s works complete." % w.get("label", ""))


# ---- GROUND improvement accessors (StadiumScreen + the WIP ledger) --------
const CAR_PARK_MAX_LEVEL := 4
const CAR_PARK_SPACES_PER_LEVEL := 500

## The live work on one (cat,key), or {} if none in progress.
func work_for(cat: String, key: int) -> Dictionary:
	for w in works:
		if str(w.get("cat")) == cat and int(w.get("key", -1)) == key:
			return w
	return {}

## The current car-park level of quadrant q (0..3), base 1.
func car_park_level(q: int) -> int:
	return int(car_park_levels[q]) if q >= 0 and q < car_park_levels.size() else 1

## Total car-park spaces = sum of the four quadrant levels x 500 (Man Utd base = 2,000).
func car_park_spaces() -> int:
	var t := 0
	for lv in car_park_levels:
		t += int(lv) * CAR_PARK_SPACES_PER_LEVEL
	return t

## The current grade of a FACILITIES/SERVICES item, or `def` if the club has not upgraded it.
func ground_grade(cat: String, key: int, def: int) -> int:
	return int(ground_grades.get("%s:%d" % [cat, key], def))

## The WORK IN PROGRESS ledger rows (frame 07): one entry per live work.
func works_ledger() -> Array:
	return works

## TOTAL IMPROVEMENTS = the sum of every live work's outstanding cost (frame 07).
func works_total() -> int:
	var t := 0
	for w in works:
		t += int(w.get("cost", 0))
	return t


## Re-derive weekly_net from the current capacity (gate income depends on it). weekly_net
## excludes player wages (drawn live), so it = weekly_balance + weekly_wages, as at create.
func _recompute_weekly_net() -> void:
	weekly_net = int(_fin_summary()["weekly_balance"]) + int(_fin_summary()["weekly_wages"])


## The managed club's finance summary at the current capacity + board-set prices. Single
## source of truth for the weekly_net recompute and the price-control preview.
func _fin_summary() -> Dictionary:
	return FinanceModel.summary({
		"capacity": stadium_capacity, "players": my_squad(),
		"ticket_price": ticket_price, "board_price": board_price}, tier)


## Set the board-controlled match ticket price and refresh the weekly finance projection.
func set_ticket_price(p: int) -> void:
	ticket_price = maxi(1, p)
	_recompute_weekly_net()


## Set the board-controlled advertising-board price and refresh the weekly projection.
func set_board_price(p: int) -> void:
	board_price = maxi(1, p)
	_recompute_weekly_net()


## The managed club's next unplayed HOME league opponent id, for the GROUND MATCH DAY ticket
## (the ticket sets the price of a home gate). -1 once no home fixture remains this season.
func next_home_opponent() -> int:
	for e in season_fixtures():
		if int(e["round"]) >= week and not bool(e["played"]) and bool(e["home"]):
			return int(e["opp_id"])
	return -1


## Take the sponsor-board season-sale offer (GROUND MATCH DAY ACCEPT): credit the witnessed
## lump sum once and mark the boards sold so the offer disappears for the rest of the season.
## `amount` is the witnessed per-club offer (Main owns it, honest gap for un-witnessed clubs).
func sell_sponsor_boards(amount: int) -> bool:
	if boards_sold_season or amount <= 0:
		return false
	cash += amount
	boards_sold_season = true
	_news("finance", "The club sells its sponsor boards for the season for £%s." % _grp(amount))
	return true


## Live finance preview (attendance / season gate / board income) at the current prices,
## for the price-control screen so the manager sees the trade-off before committing.
func finance_preview() -> Dictionary:
	var fin := _fin_summary()
	var gate := 0
	var boards := 0
	for line in fin.get("income_lines", []):
		if line[0] == "TICKETS":
			gate = int(line[1])
		elif line[0] == "SPONSOR BOARDS SOLD":
			boards = int(line[1])
	return {"attendance": int(fin["attendance"]), "capacity": int(fin["capacity"]),
		"gate": gate, "boards": boards, "ticket": int(fin["ticket_price"]),
		"board": int(fin["board_price"])}


## A short human status for the SEATS work in progress (or "" when none), e.g. "+5,000 in
## 12 wk" -- back-compat for the GROUND SEATS row / status string.
func works_status() -> String:
	var w := work_for("seats", 0)
	if w.is_empty():
		return ""
	return "+%s in %d wk" % [_grp(int((w.get("effect", {}) as Dictionary).get("added", 0))),
		int(w["weeks_left"])]


static func _grp(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


func _season_label(yr: int) -> String:
	var start := 1996 + yr   # year 1 -> 1997-98
	return "%d-%02d" % [start, (start + 1) % 100]


# ---- persistence ---------------------------------------------------------

func to_dict() -> Dictionary:
	# JSON keys must be strings; store int-keyed dicts with string keys.
	var tbl: Dictionary = {}
	for id in table:
		tbl[str(id)] = table[id]
	var ros: Dictionary = {}
	for id in rosters:
		ros[str(id)] = rosters[id]
	var nms: Dictionary = {}
	for id in club_names:
		nms[str(id)] = club_names[id]
	var listed: Dictionary = {}
	for pid in transfer_listed:
		listed[str(pid)] = true
	var offers: Dictionary = {}
	for pid in sale_offers:
		offers[str(pid)] = sale_offers[pid]
	return {
		"club_id": club_id, "club_name": club_name, "manager_name": manager_name,
		"manager_level": manager_level, "players_age": players_age,
		"match_options_shown": match_options_shown,
		"preseason_rivals": preseason_rivals,
		"friendlies_played": friendlies_played, "friendly_results": friendly_results,
		"league_id": league_id,
		"league_name": league_name, "season": season, "year": year, "week": week,
		"fixtures": fixtures, "table": tbl, "results": results, "cash": cash,
		"scorer_log": scorer_log,
		"weekly_net": weekly_net, "objective_pos": objective_pos,
		"ins_premiums": ins_premiums, "ins_hospitals": ins_hospitals,
		"ins_wage_refund": ins_wage_refund, "ins_group3_income": ins_group3_income,
		"objective_text": objective_text, "finished": finished,
		"tactics": tactics, "tier": tier, "rosters": ros, "club_names": nms,
		"stadium_capacity": stadium_capacity, "works": works,
		"car_park_levels": car_park_levels, "ground_grades": ground_grades,
		"ticket_price": ticket_price, "board_price": board_price,
		"boards_sold_season": boards_sold_season,
		"transfer_listed": listed, "sale_offers": offers,
		"shortlist": shortlist, "transfer_log": transfer_log,
		"offers_left": offers_left, "news_log": news_log,
		"training_intensity": training_intensity, "youth": youth,
		"youth_seq": youth_seq, "youth_search": youth_search,
		"scout_search": scout_search, "scout_results": scout_results,
		"pending_alerts": pending_alerts, "external_signed": _str_keyed(external_signed),
		"pending_bids": pending_bids,
		"staff": staff, "staff_pool": staff_pool,
		"staff_seq": staff_seq, "free_agents": free_agents, "free_seq": free_seq,
		"talents_used": talents_used,
		"fa_cup": fa_cup,
		"league_cup": league_cup,
		"last_champion_id": last_champion_id, "last_fa_winner_id": last_fa_winner_id,
		"last_lc_winner_id": last_lc_winner_id,
		"last_runners_up": last_runners_up, "charity_shield": charity_shield,
		"charity_shield_pending": charity_shield_pending,
		"season_opened": season_opened, "euro_seeds": euro_seeds,
		"euro": euro, "euro_ratings": _str_keyed(euro_ratings),
		"euro_names": _str_keyed(euro_names),
		"euro_winner_cup": euro_winner_cup, "euro_winner_cwc": euro_winner_cwc,
		"euro_winner_ratings": _str_keyed(euro_winner_ratings),
		"euro_winner_names": _str_keyed(euro_winner_names),
		"supercup": supercup, "intercontinental": intercontinental,
		"reputation": reputation, "manager_history": manager_history,
		"comp_total": comp_total,
		"pending_offers": pending_offers, "sacked": sacked, "sack_reason": sack_reason,
		"headhunt_pending": headhunt_pending, "spell_start_year": spell_start_year,
		"rep_year": _rep_year,
		"divisions": _divisions_to_dict(), "seed_pos": _str_keyed(seed_pos),
		"table_prev": _str_keyed(table_prev),
		# The season stat store. PackedInt32Array is not a JSON type, so each record goes
		# out as a plain 17-int Array; from_dict packs it back.
		"season_stats": _season_stats_to_dict(),
		"season_club_minutes": _str_keyed(season_club_minutes),
		"season_club_mp": _str_keyed(season_club_mp),
		"wages_live": true,   # marker: weekly_net excludes player wages (drawn live). See from_dict.
	}


## JSON-safe copy of the pyramid state (string keys throughout).
func _divisions_to_dict() -> Dictionary:
	var out: Dictionary = {}
	for t in divisions:
		var dv: Dictionary = divisions[t]
		out[str(t)] = {"league_id": dv["league_id"], "name": dv["name"], "tier": dv["tier"],
			"ids": dv["ids"], "names": _str_keyed(dv["names"]),
			"fixtures": dv["fixtures"], "table": _str_keyed(dv["table"]),
			"played": dv["played"], "scorers": dv["scorers"],
			"seed": _str_keyed(dv["seed"]), "prev": _str_keyed(dv["prev"])}
	return out


static func _int_keyed(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		out[int(k)] = d[k]
	return out


func _season_stats_to_dict() -> Dictionary:
	var out: Dictionary = {}
	for pid in season_stats:
		out[str(pid)] = Array(season_stats[pid] as PackedInt32Array)
	return out


## Pack the JSON form back. A pre-STATISTICS save simply has no key and loads with an
## empty store, which renders as the all-dashes zero state.
static func _season_stats_from_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pid in d:
		var f := PackedInt32Array()
		f.resize(Pm98StatStore.REC_DWORDS)
		var src: Array = d[pid]
		for k in mini(src.size(), Pm98StatStore.REC_DWORDS):
			f[k] = int(src[k])
		out[int(pid)] = f
	return out


## Re-key an int-keyed dict to string keys for JSON storage.
func _str_keyed(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		out[str(k)] = d[k]
	return out

static func from_dict(d: Dictionary) -> Career:
	var c := Career.new()
	c.club_id = int(d.get("club_id", -1))
	c.club_name = d.get("club_name", "?")
	c.manager_name = str(d.get("manager_name", ""))
	c.manager_level = str(d.get("manager_level", "manager"))
	c.match_options_shown = bool(d.get("match_options_shown", false))
	c.players_age = bool(d.get("players_age", false))
	c.preseason_rivals = d.get("preseason_rivals", [])
	c.friendlies_played = int(d.get("friendlies_played", 0))
	c.friendly_results = d.get("friendly_results", [])
	c.league_id = d.get("league_id", "")
	c.league_name = d.get("league_name", "League")
	c.season = d.get("season", "1997-98")
	c.year = int(d.get("year", 1))
	c.week = int(d.get("week", 0))
	c.fixtures = d.get("fixtures", [])
	c.results = d.get("results", [])
	c.scorer_log = d.get("scorer_log", [])   # pre-goalscorers saves load with an empty chart
	c.cash = int(d.get("cash", 0))
	c.weekly_net = int(d.get("weekly_net", 0))
	c.ins_premiums = int(d.get("ins_premiums", 0))
	c.ins_hospitals = int(d.get("ins_hospitals", 0))
	c.ins_wage_refund = int(d.get("ins_wage_refund", 0))
	c.ins_group3_income = int(d.get("ins_group3_income", 0))
	c.objective_pos = int(d.get("objective_pos", 17))
	c.objective_text = d.get("objective_text", "")
	c.finished = bool(d.get("finished", false))
	c.tactics = d.get("tactics", {})
	c.tier = int(d.get("tier", 1))
	# Pre-stadium-works saves load with capacity 0 (-> GameDB default via Main) + no works.
	c.stadium_capacity = int(d.get("stadium_capacity", 0))
	# `works` was a single {added,weeks_left,cost} dict before the multi-work ledger; migrate
	# a legacy in-progress SEATS expansion into the new list form.
	var raw_works: Variant = d.get("works", [])
	if raw_works is Array:
		c.works = raw_works
	elif raw_works is Dictionary and not (raw_works as Dictionary).is_empty():
		c.works = [{"cat": "seats", "key": 0, "label": "%s seats" % c._grp(int(raw_works.get("added", 0))),
			"cost": int(raw_works.get("cost", 0)), "weeks_left": int(raw_works.get("weeks_left", 1)),
			"effect": {"added": int(raw_works.get("added", 0))}}]
	else:
		c.works = []
	# JSON stores every number as a float; coerce the levels/grades back to ints so array/dict
	# equality (and the save round-trip test) holds and the values stay clean ints.
	c.car_park_levels = []
	for v in d.get("car_park_levels", [1, 1, 1, 1]):
		c.car_park_levels.append(int(v))
	if c.car_park_levels.size() != 4:
		c.car_park_levels = [1, 1, 1, 1]
	c.ground_grades = {}
	var gg: Dictionary = d.get("ground_grades", {})
	for k in gg:
		c.ground_grades[str(k)] = int(gg[k])
	c.ticket_price = int(d.get("ticket_price", 0))
	c.board_price = int(d.get("board_price", 0))
	c.boards_sold_season = bool(d.get("boards_sold_season", false))
	c.shortlist = []
	for v in d.get("shortlist", []):
		c.shortlist.append(int(v))
	c.transfer_log = d.get("transfer_log", [])
	c.offers_left = int(d.get("offers_left", OFFERS_PER_WEEK))
	c.news_log = d.get("news_log", [])
	c.training_intensity = d.get("training_intensity", Training.DEFAULT_INTENSITY)
	# Saves from before youth existed load with an empty academy (inert); the first
	# rollover scouts a crop in. youth_seq defaults above the senior id space.
	c.youth = d.get("youth", [])
	c.youth_seq = int(d.get("youth_seq", YOUTH_ID_BASE))
	c.youth_search = d.get("youth_search", {})
	# Pre-SCOUT-screen saves load idle with no results (inert until a search).
	c.scout_search = d.get("scout_search", {})
	c.scout_results = d.get("scout_results", [])
	c.pending_alerts = d.get("pending_alerts", [])
	for k in d.get("external_signed", {}):
		c.external_signed[int(k)] = true
	c.pending_bids = d.get("pending_bids", [])   # pre-delay saves load with none pending
	# Pre-staff saves load with no staff + an empty pool (effects default to 1.0); the
	# first rollover refreshes a pool to hire from.
	c.staff = d.get("staff", [])
	c.staff_pool = d.get("staff_pool", [])
	c.staff_seq = int(d.get("staff_seq", STAFF_ID_BASE))
	# Pre-free-agent saves load with an empty pool; the first rollover seeds a fresh batch.
	c.free_agents = d.get("free_agents", [])
	c.free_seq = int(d.get("free_seq", FREE_ID_BASE))
	# Pre-talent saves load with an empty ledger; Main's catch-up delivers anyone due.
	c.talents_used = d.get("talents_used", {})
	# Saves from before the cups existed load with no bracket; they stay inert this
	# season (round_due is false on an empty dict) and are rebuilt at the next rollover.
	c.fa_cup = d.get("fa_cup", {})
	c.league_cup = d.get("league_cup", {})
	c.last_champion_id = int(d.get("last_champion_id", -1))
	c.last_fa_winner_id = int(d.get("last_fa_winner_id", -1))
	c.last_lc_winner_id = int(d.get("last_lc_winner_id", -1))
	c.last_runners_up = []
	for v in d.get("last_runners_up", []):
		c.last_runners_up.append(int(v))
	c.charity_shield = d.get("charity_shield", {})
	c.charity_shield_pending = bool(d.get("charity_shield_pending", false))
	# Pre-chain saves load as already-opened so the curtain-raiser screens don't
	# fire mid-season on an in-flight career.
	c.season_opened = bool(d.get("season_opened", true))
	c.euro_seeds = d.get("euro_seeds", {})
	c.euro = d.get("euro", {})
	c.euro_ratings = {}
	for k in d.get("euro_ratings", {}):
		c.euro_ratings[int(k)] = d["euro_ratings"][k]
	c.euro_names = {}
	for k in d.get("euro_names", {}):
		c.euro_names[int(k)] = d["euro_names"][k]
	c.euro_winner_cup = int(d.get("euro_winner_cup", -1))
	c.euro_winner_cwc = int(d.get("euro_winner_cwc", -1))
	c.euro_winner_ratings = {}
	for k in d.get("euro_winner_ratings", {}):
		c.euro_winner_ratings[int(k)] = d["euro_winner_ratings"][k]
	c.euro_winner_names = {}
	for k in d.get("euro_winner_names", {}):
		c.euro_winner_names[int(k)] = d["euro_winner_names"][k]
	c.supercup = d.get("supercup", {})
	c.intercontinental = d.get("intercontinental", {})
	# Manager career (#14). Pre-#14 saves load with a fresh reputation + empty history +
	# spell starting in the save's own year, so an in-flight career carries on seamlessly.
	c.reputation = float(d.get("reputation", Manager.REP_START))
	c.manager_history = d.get("manager_history", [])
	c.comp_total = d.get("comp_total", {})
	c.pending_offers = d.get("pending_offers", [])
	c.sacked = bool(d.get("sacked", false))
	c.sack_reason = str(d.get("sack_reason", ""))
	c.headhunt_pending = bool(d.get("headhunt_pending", false))
	c.spell_start_year = int(d.get("spell_start_year", c.year))
	c._rep_year = int(d.get("rep_year", 0))
	c.table = {}
	for k in d.get("table", {}):
		c.table[int(k)] = d["table"][k]
	c.rosters = {}
	for k in d.get("rosters", {}):
		c.rosters[int(k)] = d["rosters"][k]
	c.club_names = {}
	for k in d.get("club_names", {}):
		c.club_names[int(k)] = d["club_names"][k]
	c.transfer_listed = {}
	for k in d.get("transfer_listed", {}):
		c.transfer_listed[int(k)] = true
	c.sale_offers = {}
	for k in d.get("sale_offers", {}):
		c.sale_offers[int(k)] = d["sale_offers"][k]
	# Pre-pyramid saves load with no divisions; Main's ensure_divisions builds and
	# fast-forwards them (see that function). Int keys restored throughout.
	c.divisions = {}
	for tk in d.get("divisions", {}):
		var dv: Dictionary = d["divisions"][tk]
		var ids: Array = []
		for v in dv.get("ids", []):
			ids.append(int(v))
		c.divisions[int(tk)] = {"league_id": str(dv.get("league_id", "")),
			"name": str(dv.get("name", "")), "tier": int(dv.get("tier", 0)), "ids": ids,
			"names": _int_keyed(dv.get("names", {})), "fixtures": dv.get("fixtures", []),
			"table": _int_keyed(dv.get("table", {})), "played": int(dv.get("played", 0)),
			"scorers": dv.get("scorers", []), "seed": _int_keyed(dv.get("seed", {})),
			"prev": _int_keyed(dv.get("prev", {}))}
	c.seed_pos = _int_keyed(d.get("seed_pos", {}))
	c.table_prev = _int_keyed(d.get("table_prev", {}))
	c.season_stats = _season_stats_from_dict(d.get("season_stats", {}))
	c.season_club_minutes = _int_keyed(d.get("season_club_minutes", {}))
	c.season_club_mp = _int_keyed(d.get("season_club_mp", {}))
	# Pre-contracts saves baked the player wage bill INTO weekly_net; the live loop now draws
	# it separately, so add it back once on load to keep the old weekly burn unchanged. Legacy
	# players have no stored `wage` -> current_weekly falls back to the (identical) market wage.
	if not d.has("wages_live"):
		c.weekly_net += c.player_weekly_wage()
	return c

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

## Remove the save file (the SELECCION screen's DELETE button). No-op if none exists.
static func delete_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func save(path: String = SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))


# ---- SAVE GAME slots (the 10-slot dialog; witnessed 2026-07-18) -----------
# user://career.json stays the app's autosave/Continue spine; the TEN dialog
# slots are explicit user saves (the original's GAME/PLAYER rows). A sidecar
# index keeps the dialog metadata cheap (self-heals by scanning slot files).

const SLOT_PATH := "user://career_slot_%d.json"     # slot 0-9
const SLOT_INDEX_PATH := "user://career_slots.json"

## Write this career to a dialog slot with the typed GAME name.
func save_slot(slot: int, save_name: String) -> void:
	if slot < 0 or slot > 9:
		return
	var d := to_dict()
	d["save_name"] = save_name
	var f := FileAccess.open(SLOT_PATH % slot, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
	var idx := _slot_index()
	idx[str(slot)] = {"game": save_name, "player": manager_name}
	var fi := FileAccess.open(SLOT_INDEX_PATH, FileAccess.WRITE)
	if fi != null:
		fi.store_string(JSON.stringify(idx))

static func load_slot(slot: int) -> Career:
	return load_save(SLOT_PATH % slot)

## Metadata for the 10 dialog rows: {} for an empty slot, else {game, player}.
static func slot_metas() -> Array:
	var idx := _slot_index()
	var out: Array = []
	for i in 10:
		var m: Variant = idx.get(str(i))
		out.append(m if m is Dictionary and FileAccess.file_exists(SLOT_PATH % i) else {})
	return out

## The sidecar index; rebuilt from the slot files when missing (compat).
static func _slot_index() -> Dictionary:
	if FileAccess.file_exists(SLOT_INDEX_PATH):
		var raw := FileAccess.get_file_as_string(SLOT_INDEX_PATH)
		if raw.strip_edges() != "":
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary:
				return parsed
	var idx: Dictionary = {}
	for i in 10:
		if not FileAccess.file_exists(SLOT_PATH % i):
			continue
		var d: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(SLOT_PATH % i))
		if d is Dictionary:
			idx[str(i)] = {"game": str(d.get("save_name", "")),
				"player": str(d.get("manager_name", ""))}
	return idx

static func load_save(path: String = SAVE_PATH) -> Career:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return null
	return from_dict(parsed)
