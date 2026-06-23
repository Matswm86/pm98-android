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
var league_id: String = ""
var league_name: String = ""
var season: String = "1997-98"
var year: int = 1                 # season number within this career
var week: int = 0                 # index of the NEXT round to play
var fixtures: Array = []          # Array[round]; round = Array[[home_id, away_id]]
var table: Dictionary = {}        # club_id:int -> stat row
var results: Array = []           # manager's played results [{week,opp_id,home,hg,ag}]
var cash: int = 0                 # running bank balance
var weekly_net: int = 0           # per-week finance delta (from FinanceModel)
var objective_pos: int = 17       # board wants: finish at least this high (1-based)
var objective_text: String = ""
var finished: bool = false        # season complete + objective resolved
var tactics: Dictionary = {}      # manager's Tactics.to_dict(): XI + shape + marking
var stadium_capacity: int = 0     # managed club's current ground capacity (0 = GameDB default)
var works: Dictionary = {}        # in-progress stadium expansion {added, weeks_left, cost}; {} = none
var ticket_price: int = 0         # board-set match ticket price (0 = tier default)
var board_price: int = 0          # board-set advertising-board price (0 = tier default)

# Live transfer state: the division's squads mutate as players move, and persist
# in the save -- the career, not GameDB, is the source of truth once you're managing.
var tier: int = 1                       # division tier (all clubs here share it)
var rosters: Dictionary = {}            # club_id:int -> Array[player dict] (live squads)
var club_names: Dictionary = {}         # club_id:int -> String
var transfer_listed: Dictionary = {}    # pid:int -> true (your players up for sale)
var shortlist: Array = []               # pid:int targets you're tracking
var transfer_log: Array = []            # newest-first transfer news lines
var offers_left: int = OFFERS_PER_WEEK  # signings the board still allows this week
var news_log: Array = []                # newest-first club news {week,kind,text}
var training_intensity: String = Training.DEFAULT_INTENSITY   # Light/Normal/Intensive
var youth: Array = []                   # the youth team: scouted youngsters (Youth.gd)
var youth_seq: int = YOUTH_ID_BASE      # monotonic id minter for youth (above senior ids)
var staff: Array = []                   # hired backroom staff (Staff.gd)
var staff_pool: Array = []              # staff available to hire (refreshed each season)
var staff_seq: int = STAFF_ID_BASE      # monotonic id minter for staff candidates
var free_agents: Array = []             # out-of-contract players you can sign for £0 + a wage
var free_seq: int = FREE_ID_BASE        # monotonic id minter for generated free agents
var fa_cup: Dictionary = {}             # the F.A. Cup bracket (Cup.gd); {} = not running
var league_cup: Dictionary = {}         # the Coca-Cola (League) Cup bracket; {} = not running

# Cross-season honours, captured at the end of each season (drive the next season's
# Charity Shield + European qualification). -1 / [] until a first season completes.
var last_champion_id: int = -1          # last season's league champions
var last_fa_winner_id: int = -1         # last season's F.A. Cup winners
var last_runners_up: Array = []         # last season's league places 2.. (for UEFA spots)
var charity_shield: Dictionary = {}     # the season-opener result; {} = not played

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
const YOUTH_SEED_COUNT := 5             # the academy crop a new career starts with
const YOUTH_INTAKE_LO := 1             # a season's fresh intake (scout's haul) ...
const YOUTH_INTAKE_HI := 3             # ... is this many youngsters

# Backroom staff: candidates are minted from their own id base; a new career starts with no
# staff hired but a pool to hire from (refreshed each season), and a soft cap on headcount.
const STAFF_ID_BASE := 800000
const STAFF_POOL_SIZE := 6              # candidates available to hire at any time
const FREE_ID_BASE := 700000           # free-agent id space (below staff/youth, above seniors)
const FREE_POOL_SIZE := 8              # generated free agents available at any time
const FREE_POOL_CAP := 18              # pool ceiling once your released players are added in
const STAFF_MAX := 8                    # the directors won't fund more staff than this

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
static func create(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array) -> Career:
	var c := Career.new()
	c.reputation = Manager.REP_START
	c._init_club(club, league, league_clubs, leagues)
	return c


## Set this career up to manage `club` in its division: live rosters, fixtures, table,
## objective, finances, a fresh academy + staff pool + free-agent pool, and a clean slate
## of competitions. Shared by `create` (a brand-new career) and `take_job` (switching clubs
## mid-career) -- so the cross-career state (reputation, manager_history, the year counter)
## is set by the CALLER, never here. The managed club's spell is stamped as starting in the
## current `year`.
func _init_club(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array) -> void:
	club_id = int(club["id"])
	club_name = club.get("name", "?")
	league_id = str(league.get("id", ""))
	league_name = league.get("name", "League")
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
	works = {}
	offers_left = OFFERS_PER_WEEK
	# Competitions reset: you arrive with no European qualification or honours at the new club.
	euro = {}
	euro_ratings = {}
	euro_names = {}
	last_champion_id = -1
	last_fa_winner_id = -1
	last_runners_up = []
	charity_shield = {}
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
	_set_objective(league, league_clubs, leagues)
	var fin := FinanceModel.summary(club, tier)
	# weekly_net is the per-week finance delta WITHOUT the player wage bill -- player wages
	# are drawn live from the squad each week (so signings + renewal raises move the bill),
	# so we add the seed squad's wages back into the projected balance here. For an unchanged
	# squad the live deduction equals this added-back figure, i.e. identical to the old net.
	weekly_net = int(fin["weekly_balance"]) + int(fin["weekly_wages"])
	cash = int(fin.get("total_income", 0)) / 4   # opening balance ~ a quarter's income
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
	staff_pool = Staff.generate_pool(yrng, staff_seq, STAFF_POOL_SIZE)
	staff_seq += STAFF_POOL_SIZE
	free_agents = TransferMarket.generate_free_agents(yrng, FREE_POOL_SIZE, free_seq)
	free_seq += FREE_POOL_SIZE


## Deep-copy a club's squad into a live roster, stamping a contract length on each
## player (younger players are tied down longer). Never aliases GameDB's data.
func _seed_squad(club_dict: Dictionary) -> Array:
	var out: Array = []
	for p in club_dict.get("players", []):
		var dup: Dictionary = (p as Dictionary).duplicate(true)
		var age := int(dup.get("age", 26))
		dup["contract_years"] = 3 if age <= 29 else (2 if age <= 32 else 1)
		dup["injured_weeks"] = 0       # availability state (Availability.gd)
		dup["suspended_weeks"] = 0
		dup["yellows"] = 0
		dup["dev_progress"] = 0.0      # development carry-over (Training.gd)
		Contract.stamp_wage(dup, tier)  # his contracted weekly wage (Contract.gd)
		dup["auto_renew"] = false      # opt-in: auto-renew an expiring deal at rollover
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


## Objective = finish at least as high as squad strength suggests (with leniency),
## phrased by where that lands in the division.
func _set_objective(league: Dictionary, league_clubs: Array, leagues: Array) -> void:
	var ranked: Array = []
	for lc in league_clubs:
		var r := MatchEngine.team_ratings(lc)
		ranked.append({"id": int(lc["id"]), "ovr": r["att"] + r["def"] + r["gk"]})
	ranked.sort_custom(func(a, b): return a["ovr"] > b["ovr"])
	var strength_rank := league_clubs.size()
	for i in ranked.size():
		if ranked[i]["id"] == club_id:
			strength_rank = i + 1
			break
	var total := league_clubs.size()
	objective_pos = clampi(strength_rank + 2, 1, total)
	var tier := FinanceModel.tier_of({"leagueId": league_id}, leagues)
	var zone: Dictionary = SeasonSim.ZONES.get(tier, {"releg": 3})
	var relegation: int = int(zone.get("releg", 3))
	if objective_pos >= total - relegation:
		objective_text = "Avoid relegation"
		objective_pos = total - int(relegation) - 1
	elif objective_pos <= 1:
		objective_text = "Win the league"
	elif objective_pos <= maxi(2, total / 5):
		objective_text = "Finish in the top %d" % objective_pos
	else:
		objective_text = "Finish %d or higher" % objective_pos


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
	# Rival clubs trade in the background while the window is open.
	if transfers_open() and not rosters.is_empty():
		for line in TransferMarket.ai_round(rng, rosters, club_names, club_id, tier):
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
	for m in fixtures[week]:
		var h := int(m[0])
		var a := int(m[1])
		if not ratings.has(h):
			ratings[h] = _ratings_for(h, clubs_override)
		if not ratings.has(a):
			ratings[a] = _ratings_for(a, clubs_override)
		var res := MatchSim.simulate(rng, ratings[h], ratings[a], \
				xi_of_id.call(h), xi_of_id.call(a), h, a)
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		_apply(table[h], hg, ag)
		_apply(table[a], ag, hg)
		if h == club_id or a == club_id:
			manager_res = {"home_id": h, "away_id": a, "hg": hg, "ag": ag, "manager_home": h == club_id}
	cash += weekly_net
	cash -= player_weekly_wage()        # the live squad wage bill (YEARLY WAGE / 52 per man)
	cash -= Staff.weekly_wage(staff)   # the backroom staff wage bill (STAFF WAGES)
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
	# F.A. Cup: any midweek tie whose scheduled league week has arrived is played
	# now (open random draw, replays then penalties). The manager's own tie writes a
	# news line and a cup run pays prize money; the rest resolves in the background so
	# a champion still emerges even after the manager is knocked out.
	_play_due_cup_rounds(rng, clubs_override)
	# Rival squads live through the same week (#12): recoveries tick, this round's knocks
	# land on the XIs that featured, and development nudges their ratings. Kept quiet bar
	# notable rival injuries, which surface in the club news feed.
	_roll_ai_squads(rng, ai_featured)
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
			var cr := Cup.play_round(cup, rng, ratings_fn, club_id, names_fn, xi_fn)
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
			var er := Cup.play_next(eb, rng, ratings_fn, club_id, names_fn, xi_fn)
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
	return out


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
	return xi


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
					_news("injury", "%s's %s is out injured for %d matches." % [
						club_names.get(int(cid), "?"), p.get("name", "?"), now])
		Training.train_week(rng, squad, Training.DEFAULT_INTENSITY)


# ---- live squad access ---------------------------------------------------

## A club dict view backed by the live roster: {id, name, players}. This is what
## tactics, ratings, the squad screen and finances read once you're managing.
func club_view(id: int) -> Dictionary:
	return {"id": id, "name": club_names.get(id, "?"), "players": rosters.get(id, [])}

func squad_of(id: int) -> Array:
	return rosters.get(id, [])


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


## Sorted standings (Pts, then GD, GF, name) as an Array of stat rows.
func standings() -> Array:
	var rows: Array = table.values()
	rows.sort_custom(func(a, b):
		if a["Pts"] != b["Pts"]:
			return a["Pts"] > b["Pts"]
		var gda: int = a["GF"] - a["GA"]
		var gdb: int = b["GF"] - b["GA"]
		if gda != gdb:
			return gda > gdb
		if a["GF"] != b["GF"]:
			return a["GF"] > b["GF"]
		return a["name"] < b["name"])
	return rows

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

## Record the current club as a finished spell in the manager's history. `reason` is how it
## ended ("sacked" / "resigned" / "left for X"). Captures the span + the final standing.
func record_spell(reason: String) -> void:
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
		reason: String = "") -> void:
	if reason == "":
		reason = "sacked" if sacked else ("left for %s" % str(club.get("name", "?")))
	record_spell(reason)
	year += 1
	_init_club(club, league, league_clubs, leagues)

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
	var room := Youth.SQUAD_CAP - youth.size()
	if room <= 0:
		return
	var want := mini(room, rng.randi_range(YOUTH_INTAKE_LO, YOUTH_INTAKE_HI))
	# A youth coach raises the quality of the intake (Youth.intake's scout factor).
	for p in Youth.intake(rng, want, youth_seq, Staff.youth_factor(staff)):
		youth.append(p)
		_news("youth", "%s has joined your Youth Team." % p.get("name", "?"))
	youth_seq += want


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
	Contract.stamp_wage(p, tier)   # a first-team wage now he's promoted
	p["auto_renew"] = false
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
	return Contract.squad_weekly_bill(my_squad(), tier)

## Hire a candidate from the pool into the backroom staff. Guards the headcount cap and the
## directors' affordability (you must be able to cover the new wage bill). Moves the member
## out of the pool. Returns {ok, msg}.
func hire_staff(cand_id: int) -> Dictionary:
	var idx := -1
	for i in staff_pool.size():
		if int(staff_pool[i].get("id", -2)) == cand_id:
			idx = i
			break
	if idx == -1:
		return {"ok": false, "msg": "That member of staff is no longer available."}
	if staff.size() >= STAFF_MAX:
		return {"ok": false, "msg": "The directors won't fund more than %d staff." % STAFF_MAX}
	var m: Dictionary = staff_pool[idx]
	# The board won't sanction a hire the club plainly can't pay for (a season's wage).
	if int(m.get("wage", 0)) > cash:
		return {"ok": false, "msg": "You can't afford %s's wages." % m.get("name", "?")}
	staff_pool.remove_at(idx)
	staff.append(m)
	_news("staff", "%s has joined the club as %s." % [m.get("name", "?"), m.get("role", "staff")])
	_log("Hired %s (%s)." % [m.get("name", "?"), m.get("role", "staff")])
	return {"ok": true, "msg": "%s hired as %s." % [m.get("name", "?"), m.get("role", "staff")]}

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
	_log("Sacked %s (%s); paid £%s compensation." % [m.get("name", "?"), m.get("role", "staff"), _money(comp)])
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
func sign_player(pid: int, from_club_id: int, offer: int, rng: RandomNumberGenerator) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed. You can not sign more." % TransferMarket.SQUAD_MAX}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var player := _find_in(from_club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	offers_left -= 1   # an offer counts whether or not it is accepted
	var is_key := TransferMarket.is_key_player(club_view(from_club_id), pid)
	var verdict := TransferMarket.evaluate_offer(player, offer, is_key, tier, rng)
	var seller_name: String = club_names.get(from_club_id, "?")
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s have rejected your offer for %s." % [seller_name, player.get("name", "?")]}
	rosters[from_club_id].erase(player)
	player["clubId"] = club_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	Contract.stamp_wage(player, tier)   # his wage joins your live bill
	player["auto_renew"] = false
	rosters[club_id].append(player)
	cash -= offer
	transfer_listed.erase(pid)
	shortlist.erase(pid)
	_log("You have signed %s from %s for £%s." % [player.get("name", "?"), seller_name, _money(offer)])
	return {"ok": true, "msg": "You have signed %s." % player.get("name", "?")}

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
		offer_weekly = Contract.demanded_weekly(player, tier)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	offers_left -= 1   # an offer counts whether or not it is accepted
	var pname: String = player.get("name", "?")
	var verdict := Contract.evaluate_renewal(player, offer_weekly, tier, rng)
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s has rejected your terms." % pname, "demanded": int(verdict["demanded"])}
	free_agents.erase(player)
	player.erase("free_agent")
	player["clubId"] = club_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	player["wage"] = offer_weekly
	player["auto_renew"] = false
	rosters[club_id].append(player)
	_log("You have signed free agent %s on £%s/wk." % [pname, _money(offer_weekly)])
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
	player["wage"] = Contract.market_weekly(player, tier)   # you pick up his wages
	player["clubId"] = club_id
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
	else:
		transfer_listed[pid] = true

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
	if rosters.has(buyer_id):
		rosters[buyer_id].append(player)
	cash += offer
	transfer_listed.erase(pid)
	var buyer_name: String = club_names.get(buyer_id, "?")
	_log("%s has been signed by %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)])
	return {"ok": true, "msg": "Sold %s to %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)]}

## Offer a squad player a renewal at `offer_weekly` £/wk (default = meet his demand). It is a
## NEGOTIATION: he accepts at/above his wage demand, may balk just below it, and refuses a
## lowball -- "%s has rejected your offer for renewal." On acceptance his term resets and his
## stored wage updates (so a raise flows into the live wage bill). {ok, msg, demanded}.
func renew(pid: int, offer_weekly: int = -1, rng: RandomNumberGenerator = null) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is not in your squad."}
	if offer_weekly < 0:
		offer_weekly = Contract.demanded_weekly(player, tier)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var verdict := Contract.evaluate_renewal(player, offer_weekly, tier, rng)
	var pname: String = player.get("name", "?")
	if not verdict["accepted"]:
		_log("%s has rejected your offer for renewal." % pname)
		return {"ok": false, "msg": "%s has rejected your offer for renewal." % pname,
			"demanded": int(verdict["demanded"])}
	player["contract_years"] = Contract.NEW_TERM_YEARS
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
		sa_champion: Dictionary = {}) -> void:
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
		var demand_wk := Contract.demanded_weekly(p, tier)
		var affordable := Contract.yearly(demand_wk) <= cash
		# An ASSISTANT MANAGER (T2 #10) re-signs an expiring player good enough to keep, so your
		# stars don't walk for free while you're not looking. His quality lowers the CA bar
		# (q5 keeps CA>=60, q1 keeps CA>=72); needs no auto_renew flag, only affordability.
		var aq := Staff.assistant_quality(staff)
		var ca := int(p.get("attrs", {}).get("CA", 0))
		var assistant_keeps := aq > 0 and ca >= 75 - aq * 3
		if (p.get("auto_renew") or assistant_keeps) and affordable:
			p["contract_years"] = Contract.NEW_TERM_YEARS
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
	# The youth team ages a year too: anyone over the graduation age who was never
	# promoted is released to make room, then the scout brings in a fresh crop.
	_roll_youth(rng)
	# A fresh batch of staff comes onto the market for the new season.
	staff_pool = Staff.generate_pool(rng, staff_seq, STAFF_POOL_SIZE)
	staff_seq += STAFF_POOL_SIZE

	year += 1
	season = _season_label(year)
	week = 0
	finished = false
	results.clear()
	transfer_listed.clear()
	offers_left = OFFERS_PER_WEEK
	_log("--- %s season ---" % season)

	var ids: Array = rosters.keys()
	var views: Array = []
	for id in ids:
		views.append(club_view(id))
	fixtures = SeasonSim.fixtures(ids)
	fa_cup = Cup.create(ids, fixtures.size())   # a fresh F.A. Cup each season
	league_cup = Cup.create(ids, fixtures.size(), LEAGUE_CUP_OPTS)
	_init_table(views)
	var league := {"id": league_id, "name": league_name, "tier": tier}
	_set_objective(league, views, leagues)
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
	var s := standings()
	if not s.is_empty():
		last_champion_id = int(s[0].get("id", -1))
		last_runners_up = []
		for i in range(1, s.size()):
			last_runners_up.append(int(s[i].get("id", -1)))
	last_fa_winner_id = Cup.champion_id(fa_cup)


## Play the Charity Shield (champions v F.A. Cup winners) as the season's curtain-raiser.
## If one club holds both honours (the Double), the league runners-up take the second
## berth -- PM98 fills the vacancy the same way. Stores the result, pays the manager a
## modest prize if his club lifts it, and writes a news line either way. No-ops in a
## first season (no prior honours to contest).
func _play_charity_shield(rng: RandomNumberGenerator) -> void:
	charity_shield = {}
	var champ := last_champion_id
	var fa := last_fa_winner_id
	if champ == -1:
		return
	if fa == -1 or fa == champ:
		# Double winners (or no F.A. Cup last year): the league runners-up step up.
		fa = int(last_runners_up[0]) if not last_runners_up.is_empty() else -1
	if fa == -1 or fa == champ:
		return
	var ratings_fn := func(id: int) -> Dictionary: return _ratings_for(id)
	var xi_fn := func(id: int) -> Array: return _xi_for(id)
	var tie := Cup.single_neutral_match(rng, champ, fa, ratings_fn, xi_fn)
	tie["champ_id"] = champ
	tie["fa_id"] = fa
	tie["season"] = season
	charity_shield = tie
	var w := int(tie["winner_id"])
	var l := int(tie["loser_id"])
	var wn := str(club_names.get(w, "?"))
	var ln := str(club_names.get(l, "?"))
	var pens := " (on penalties)" if tie.get("decided", "") == "pens" else ""
	if w == club_id:
		cash += CHARITY_PRIZE
		_news("cup", "%s have won the Charity Shield, beating %s%s." % [wn, ln, pens])
	else:
		_news("cup", "Charity Shield: %s beat %s%s." % [wn, ln, pens])


## Build this season's European competitions from last season's honours. `euro_pool` is
## an array of foreign club dicts ({id,name,players}) the caller draws from GameDB; their
## ratings + names are FROZEN here so the brackets resolve and save without GameDB. Each
## comp's field = the domestic qualifier(s) + a draw of foreign clubs (distinct across our
## three competitions). No-op until a first season has produced honours, or if the pool is
## too small to fill a field. Called from advance_season after the new fixtures are set.
func mint_european_cups(euro_pool: Array, rng: RandomNumberGenerator) -> void:
	euro = {}
	euro_ratings = {}
	euro_names = {}
	if last_champion_id == -1 or euro_pool.is_empty():
		return
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
	var seeds := {
		"european_cup": [last_champion_id],
		"uefa_cup": last_runners_up.slice(0, UEFA_SPOTS),
		"cup_winners_cup": [_cwc_seed()],
	}
	var cursor := 0
	for key in EURO_OPTS:
		var field: Array = []
		for s in seeds[key]:
			if int(s) != -1 and not field.has(int(s)):
				field.append(int(s))
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

## Begin a ground expansion: pay `cost` now, capacity rises by `added` after `weeks`.
## Refuses if works are already running, cash is short, or it would breach the ceiling.
func start_works(added: int, cost: int, weeks: int) -> bool:
	if not works.is_empty() or added <= 0 or cash < cost \
			or stadium_capacity + added > MAX_STADIUM:
		return false
	cash -= cost
	works = {"added": added, "weeks_left": maxi(1, weeks), "cost": cost}
	_news("stadium", "Ground works begun: +%s capacity, ~%d weeks (-£%s)." % [
		_grp(added), maxi(1, weeks), _grp(cost)])
	return true


## Tick an in-progress expansion one week; on completion raise the capacity and refresh
## the weekly finance projection so the bigger gate actually feeds the books.
func _tick_works() -> void:
	if works.is_empty():
		return
	works["weeks_left"] = int(works["weeks_left"]) - 1
	if int(works["weeks_left"]) <= 0:
		stadium_capacity = mini(MAX_STADIUM, stadium_capacity + int(works["added"]))
		_news("stadium", "Ground expansion complete: capacity now %s." % _grp(stadium_capacity))
		works = {}
		_recompute_weekly_net()


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


## A short human status for the WORKS in progress (or "" when none), e.g. "+5,000 in 12 wk".
func works_status() -> String:
	if works.is_empty():
		return ""
	return "+%s in %d wk" % [_grp(int(works["added"])), int(works["weeks_left"])]


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
	return {
		"club_id": club_id, "club_name": club_name, "league_id": league_id,
		"league_name": league_name, "season": season, "year": year, "week": week,
		"fixtures": fixtures, "table": tbl, "results": results, "cash": cash,
		"weekly_net": weekly_net, "objective_pos": objective_pos,
		"objective_text": objective_text, "finished": finished,
		"tactics": tactics, "tier": tier, "rosters": ros, "club_names": nms,
		"stadium_capacity": stadium_capacity, "works": works,
		"ticket_price": ticket_price, "board_price": board_price,
		"transfer_listed": listed, "shortlist": shortlist, "transfer_log": transfer_log,
		"offers_left": offers_left, "news_log": news_log,
		"training_intensity": training_intensity, "youth": youth,
		"youth_seq": youth_seq, "staff": staff, "staff_pool": staff_pool,
		"staff_seq": staff_seq, "free_agents": free_agents, "free_seq": free_seq,
		"fa_cup": fa_cup,
		"league_cup": league_cup,
		"last_champion_id": last_champion_id, "last_fa_winner_id": last_fa_winner_id,
		"last_runners_up": last_runners_up, "charity_shield": charity_shield,
		"euro": euro, "euro_ratings": _str_keyed(euro_ratings),
		"euro_names": _str_keyed(euro_names),
		"euro_winner_cup": euro_winner_cup, "euro_winner_cwc": euro_winner_cwc,
		"euro_winner_ratings": _str_keyed(euro_winner_ratings),
		"euro_winner_names": _str_keyed(euro_winner_names),
		"supercup": supercup, "intercontinental": intercontinental,
		"reputation": reputation, "manager_history": manager_history,
		"pending_offers": pending_offers, "sacked": sacked, "sack_reason": sack_reason,
		"headhunt_pending": headhunt_pending, "spell_start_year": spell_start_year,
		"rep_year": _rep_year,
		"wages_live": true,   # marker: weekly_net excludes player wages (drawn live). See from_dict.
	}


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
	c.league_id = d.get("league_id", "")
	c.league_name = d.get("league_name", "League")
	c.season = d.get("season", "1997-98")
	c.year = int(d.get("year", 1))
	c.week = int(d.get("week", 0))
	c.fixtures = d.get("fixtures", [])
	c.results = d.get("results", [])
	c.cash = int(d.get("cash", 0))
	c.weekly_net = int(d.get("weekly_net", 0))
	c.objective_pos = int(d.get("objective_pos", 17))
	c.objective_text = d.get("objective_text", "")
	c.finished = bool(d.get("finished", false))
	c.tactics = d.get("tactics", {})
	c.tier = int(d.get("tier", 1))
	# Pre-stadium-works saves load with capacity 0 (-> GameDB default via Main) + no works.
	c.stadium_capacity = int(d.get("stadium_capacity", 0))
	c.works = d.get("works", {})
	c.ticket_price = int(d.get("ticket_price", 0))
	c.board_price = int(d.get("board_price", 0))
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
	# Pre-staff saves load with no staff + an empty pool (effects default to 1.0); the
	# first rollover refreshes a pool to hire from.
	c.staff = d.get("staff", [])
	c.staff_pool = d.get("staff_pool", [])
	c.staff_seq = int(d.get("staff_seq", STAFF_ID_BASE))
	# Pre-free-agent saves load with an empty pool; the first rollover seeds a fresh batch.
	c.free_agents = d.get("free_agents", [])
	c.free_seq = int(d.get("free_seq", FREE_ID_BASE))
	# Saves from before the cups existed load with no bracket; they stay inert this
	# season (round_due is false on an empty dict) and are rebuilt at the next rollover.
	c.fa_cup = d.get("fa_cup", {})
	c.league_cup = d.get("league_cup", {})
	c.last_champion_id = int(d.get("last_champion_id", -1))
	c.last_fa_winner_id = int(d.get("last_fa_winner_id", -1))
	c.last_runners_up = []
	for v in d.get("last_runners_up", []):
		c.last_runners_up.append(int(v))
	c.charity_shield = d.get("charity_shield", {})
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
	# Pre-contracts saves baked the player wage bill INTO weekly_net; the live loop now draws
	# it separately, so add it back once on load to keep the old weekly burn unchanged. Legacy
	# players have no stored `wage` -> current_weekly falls back to the (identical) market wage.
	if not d.has("wages_live"):
		c.weekly_net += c.player_weekly_wage()
	return c

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func save(path: String = SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))

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
