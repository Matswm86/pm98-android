class_name Career
extends RefCounted
## A persistent manager career: one club, played week-by-week through a league
## season, with an accumulating table, finances and a board objective. Saves to
## user://career.json. This is the spine the rest of the management layer hangs off.
##
## Kept free of the GameDB autoload (callers pass clubs/leagues in) so it stays
## unit-testable headless.

const SAVE_PATH := "user://career.json"
# The ground's build ceiling, CLOSED 2026-07-28 from the binary (the 07-27 note "the addend
# register wants one more trace" is discharged). `FUN_0051c2e0` -- the GROUND IMPROVEMENTS
# card builder -- banks `[ground+4] + [ground+8]` (capacity + expansion HEADROOM, the same
# sum the tier picture divides) into its frame at @0x51c340, and then per SEATS card:
#     0x51c8d0  push edi / push 1 / call FUN_0057e3f0   ; seats = (card + 1) * 4000
#     0x51c8df  add eax, [esp+0x28]                     ; ... + capacity + headroom
#     0x51c8e1  cmp eax, 0x249f0                        ; 150,000
#     0x51c8e6  jb keep                                 ; else -> FUN_005bf8c0 = DISABLE
# So the ceiling is 150,000 on the SUM, tested per card at build time (the card greys out),
# and 130,000 was only ever the tier-11 picture threshold (`FUN_0051a6e0`). Frame slots
# pinned by three agreeing reads at the same site: [esp+0x14] = the ground object
# (@0x51c319, used as `[ebx+0x33]`), [esp+0x2c] = the ground+0x34 works byte (@0x51c32b),
# [esp+0x28] = the capacity sum (@0x51c340).
const MAX_STADIUM := 150000

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
# MAN-TO-MAN MARKINGS (docs/re/mantoman_screen_re.md). `man_marking` is the
# original's own `team+0x234` table: ten entries, one per OUTFIELD lineup slot
# (2..11), 0 = unmarked and 2..11 = the opponent lineup slot that player marks.
# `marking_lines` is [club+0x25c, club+0x260] in the binary's own units — the
# DEFENDING and MIDFIELDING marking lines, ctor defaults 79 and 198
# (session_lineup_re.md); the screen scales them by 148/318 to draw.
var man_marking: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var marking_lines: Array = [79, 198]
var stadium_capacity: int = 0     # managed club's current ground capacity (0 = GameDB default)
# The ground's expansion HEADROOM (EQUIPOS param_1[7], loader-quantised to 4000s;
# game_db `capacityHeadroom`). The GROUND picture's tier is the SUM capacity+headroom
# — FUN_0051a6e0 adds ground+4 + ground+8 before the /130000 magic division. Static:
# the English (category-1) SEATS cards never decrement it (FUN_0057da50 draws from
# headroom only for category 2). Non-zero for 91 shipped clubs (~30 English).
var stadium_headroom: int = 0
# GROUND IMPROVEMENTS (frame 07): several works run at once -- a SEATS expansion, a CAR
# PARK level, a FACILITIES grade and a SERVICES grade can all be under construction in the
# same week. `works` is a LIST of {cat, key, label, cost, weeks_left, effect}; each ticks
# independently and applies its effect (capacity / car-park level / facility grade) on
# completion. car_park_levels = the 4 quadrants NE/NW/SE/SW (base level 1 each = 2,000
# spaces); ground_grades = completed FACILITIES/SERVICES upgrades "cat:key" -> grade.
var works: Array = []
var car_park_levels: Array = [1, 1, 1, 1]
var ground_grades: Dictionary = {}
# Board-set match ticket price, in POUNDS AND PENCE -- the original's own default is
# £7.50 a head (FinanceModel.TICKET_DEFAULT, measured exactly off two FULL TIME stadium
# panels), so this cannot be a whole-pound integer without losing the witness.
var ticket_price: float = 0.0     # board-set match ticket price (0 = tier default)
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
var youth_found: Array = []             # finished search's prospects, awaiting a contract offer
                                        # (the PLAYERS FOUND panel; they are NOT in `youth` yet)
var youth_caps: Dictionary = {}         # the six LED capability flags (skill key -> bool). The
                                        # original keeps them on the criteria object (+0x10..+0x24,
                                        # youth_re.md §3), so they survive leaving the screen —
                                        # persisted here for the same reason.
var youth_pool: Array = []              # the shipped 0x26e4 pool the YOUTH SCOUT searches
                                        # (Youth.pool_of(GameDB.clubs_by_id); set by the
                                        # caller so this file never reaches for an autoload).
                                        # NOT persisted — it is game data, not save data.
var scout_search: Dictionary = {}       # SENIOR scout search {criteria:Dictionary, due_week:int};
                                        # {} = idle (SCOUT screen, docs/re/scout_screen_re.md)
var scout_results: Array = []           # last finished search's rows (persist until a new search)
var scout_found_total: int = 0          # how many the scan MATCHED before the engine's
                                        # (quality+2)*5 shortlist cap trimmed it (see
                                        # _scout_apply_cap); == scout_results.size() when
                                        # nothing was cut. Drives the OURS shortfall line.
var training_focus: Dictionary = {}      # pid:int -> focus row (Training.FOCUS_ROWS)
var pending_alerts: Array = []          # queued hub "PREMIER MANAGER 98" alert texts; Main
                                        # raises + clears them when the hub next shows (the
                                        # witnessed post-flow timing, scout_screen_re.md 78)
var career_rng_state: String = "":      # persisted state of the career RNG (S3: every former
                                        # per-call randomize() site draws from ONE stream).
                                        # A string because the 64-bit state does not survive a
                                        # JSON double round-trip. "" = not seeded yet.
                                        # Assigning a state RE-PINS a live stream too — create()
                                        # already draws from it (academy/staff pools), so the
                                        # acceptance machinery can pin a career after the fact.
	set(v):
		career_rng_state = v
		if _career_rng != null and v != "":
			_career_rng.state = v.to_int()
var _career_rng: RandomNumberGenerator = null
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

# ---- MONTHLY AWARDS (MANAGERS / PLAYERS OF THE MONTH) ----------------------
# The two sheets the original raises during the CONTINUE chain at the end of a
# calendar month (witnessed 2026-07-18, Bolton career: week-4 CONTINUE -> the cup
# draw -> MANAGERS OF THE MONTH (AUGUST) -> PLAYERS OF THE MONTH (AUGUST) -> hub;
# frames 76 / 77). `month_awards` holds the built sheets until the UI has shown
# them, then Main clears it.
var month_awards: Dictionary = {}       # {} or {month, managers{tier->..}, players{tier->..}}
var _month_mark: Dictionary = {}        # tier -> {club_id -> [Pts, GF, GA]} at month start
var _month_goal_mark: Dictionary = {}   # tier -> scorer-log length at month start

# European competitions (qualified into from last season's domestic finish). Each is a
# two-legged knockout (Cup.gd) over a field of this division's qualifier(s) + strong
# foreign clubs. euro = {comp_key -> bracket}; the foreign entrants' ratings + names are
# FROZEN here at draw time so the brackets resolve + save without GameDB.
var euro: Dictionary = {}               # {"european_cup"/"uefa_cup"/"cup_winners_cup" -> bracket}
var euro_ratings: Dictionary = {}       # foreign club id:int -> {att,def,gk}
var euro_xis: Dictionary = {}           # foreign club id:int -> ordered 11-dict XI (slot 0
                                        # GK) resolved from the club's shipped TRUE XI
                                        # (club_tactics.json) over its game_db attr squad.
                                        # NOT persisted — game data, not save data; fed by
                                        # Main (like youth_pool) so European ties run on
                                        # the byte-exact engine instead of the legacy
                                        # fallback (S5). {} on a stale feed -> the loud
                                        # [MATCHSIM_FALLBACK] path, exactly as before.
var euro_names: Dictionary = {}         # foreign club id:int -> String

# Winners-of-winners finals (season-openers from LAST season's European winners). The
# European Cup winner + Cup Winners' Cup winner are captured at rollover, their ratings
# frozen so the finals resolve after euro_ratings is rebuilt.
var euro_winner_cup: int = -1           # last season's European Cup winner
var euro_winner_cwc: int = -1           # last season's Cup Winners' Cup winner
# REFRUN R14: the U.E.F.A. Cup winner was thrown away by _capture_euro_honours, yet the
# original both raises a U.E.F.A. CUP CHAMPION card for it and lists it among the eight
# trophies on THE CHAMPIONSHIPS. Captured now like the other two.
var euro_winner_uefa: int = -1          # last season's U.E.F.A. Cup winner
var euro_winner_ratings: Dictionary = {}  # winner/SA-champ id:int -> {att,def,gk}
var euro_winner_names: Dictionary = {}    # winner/SA-champ id:int -> String
# The original's own per-week finance books (FINANCE -> INC. + EXP. -> PER WEEK), the
# structure REFRUN R5/R9 witnessed. `week_ledgers` holds one record per COMPLETED week,
# oldest first, capped at the finance year's 52; `_wk` is the week being accumulated.
# Every cash movement goes through _post_income / _post_expense so the books and the
# bank can never disagree.
var week_ledgers: Array = []
var _wk: Dictionary = {}
# Cash as the last completed week closed — a STORED figure, the way the original's LAST
# WEEK / CASH tile behaves (walkthrough 006/013: LAST £7,556,099 + CURRENT-week income
# £9,120,000 = £16,676,099, £1 off the live £16,676,098 — a derived figure could not
# disagree, so the original stores it). False until a week has closed or a save carries it.
var cash_close: int = 0
var _cash_close_ok := false
# Consecutive weeks the club's BANK BALANCE has been below zero (REFRUN R16, trigger
# corrected 2026-07-26 -- see _close_week_books). The original raises one hub alert a week
# while this is non-zero, incrementing, and CLEARS it the moment the balance is positive
# again -- witnessed at 1, 2 and 3 weeks, then cleared by a sale.
var loss_weeks: int = 0
# club+0x294 -- the board's RESULTS-REVIEW sack flag, set/cleared by the weekly update
# `FUN_0057a980` @0x57aeb2 and consumed by the hub run `FUN_00545fd0` @0x54603a in the
# SAME week (docs/re/sack_path_re.md; the week table is `_board_results_review`).
var board_sack_flag: int = 0
# The review weeks that have already posted a WARNING this season, so the same week is
# never re-reviewed if the hub is re-mounted (the original's review runs once per weekly
# update, not once per hub draw).
var board_reviewed: Array = []
# The two readings the sack arms compare against, banked at the WARNING week they review
# (see `_board_results_review`): {round_no: bool below} and {round_no: int position}.
var _below_at: Dictionary = {}
var _pos_at: Dictionary = {}
# The 1-April season-end/contract warning has fired this season (it fires once).
var contract_warned := false
# The channelTV card queued for the coming HOME match: {"fee": int, "comp": String}.
# {} when the next fixture is away, or the competition's fee is not witnessed.
var pending_channel_tv: Dictionary = {}
# R13 (witnessed): tiers whose FINAL tables the hub presents after the penultimate
# league round, BEFORE the last one is played — the divisions that have already
# finished (lower divisions run ahead, R12). Drained by Main's post-week chain.
var pending_division_finals: Array = []
## Knockout rounds whose draw the hub still has to raise, oldest first (REFRUN R4). The
## original raises the pixel-exact SORTEO screen UNPROMPTED when a round is drawn; the
## port had the screen at 0 differing pixels and NO live caller at all. Each entry is
## {key, title, round, ties, total, legs} -- exactly CupDrawScreen.setup's arguments.
##
## CLOSED 2026-07-26. The two steps are separate now: `Cup.draw_next_round` pairs the next
## round the moment the previous one resolves, and the round is played at its own scheduled
## week, so this card shows ties that have NOT been played -- as the original's does. The
## split is witnessed, not assumed: F.A. Cup R2 played 14 Dec 1997, R3 drawn and shown
## unplayed by 20 Dec, still unplayed 28 Dec, played 10 Jan 1998; Coca-Cola R4 played
## 1 Dec, Qtr Finals drawn and shown unplayed 7 Dec. See `Cup.draw_next_round`.
var pending_cup_draws: Array = []

var supercup: Dictionary = {}           # European Supercup result; {} = not played
var sa_champion_id: int = -1            # Libertadores holder, for the December Intercontinental
# Champion cards the hub has to raise UNPROMPTED, oldest first (REFRUN R7/R11/R14/R15).
# The original presents every trophy on the one shared CAMPEON layout -- five competitions
# matched the taught `champion_card` signature at 0.99-1.00 -- and raises the card itself
# without the manager asking for it: the Charity Shield at season start, the
# Intercontinental in December, the Supercup in March, and the rest in the season-end
# sequence. Each entry is
#   {"comp": key, "winner": {club, club_id, qualifier}, "runner": {club, club_id}}
# with the manager names resolved by the UI (Career has no manager database).
var pending_champion_cards: Array = []
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
# OURS (docs/SPEC_ours_additions.md item 1, approved 2026-07-25). The original tracks
# eight trophies and shows each one only in the moment it is won, then forgets: a
# ten-season save leaves no record of itself, and the game raises no board-verdict screen
# at all (REFRUN R15). This is one record per COMPLETED season, oldest first, written by
# _capture_season_honours at the rollover. It is a LEDGER, not a rule change: nothing in
# the model reads it, so a save without it plays identically.
var honours: Array = []

# THE DOMESTIC CUPS, on the original's own shape (REFRUN R1/R2/R8, witnessed 2026-07-25).
#
# Both cups are contested by the WHOLE 92-club league pyramid, and PREMIER clubs enter at
# ROUND 3. Witnessed on two separate draws: the Coca-Cola Cup ROUND 3 drew Man Utd away at
# Bradford City (Division One, manager Jewell, The Pulse Stadium), and the F.A. Cup ROUND 3
# panel is a scrollable list of ties between clubs from outside the Premier. Two lower-
# division clubs went deep in the same season -- Bradford City WON the F.A. Cup and
# Wycombe W. (Division Two) reached the Coca-Cola final. The app used to contest each cup
# among the manager's own 20-club division, so a lower-division club could not be drawn at
# all, and its "sequential" labels called the manager's first tie Round 1 when the original
# calls it Round 3.
#
# Ties are SINGLE-LEG WITH A REPLAY, not two legs: the Round 3 draw card carries MATCH /
# REPLAY buttons per tie (R2). Only Round 3 was witnessed; the binary also ships the
# "<round> - 1st" / "- 2nd" two-legged label set, so whether the real Round 1 and the
# semifinals are two-legged (as they were in real 1997-98) is UNRESOLVED and is not
# guessed at here -- every round replays.
const PREMIER_ENTRY_ROUND := 3

const FA_CUP_OPTS := {
	"name": "F.A. Cup", "legs": 1, "two_legged_final": false,
	"label_scheme": "sequential", "qtr_label": "Qtr. Finals",
	"prize_round": 0, "prize_winner": 0, "span_lo": 0.0, "span_hi": 1.0,
}
const LEAGUE_CUP_OPTS := {
	"name": "Coca-Cola Cup", "legs": 1, "two_legged_final": false,
	# The SEMIFINALS are two-legged in the original -- witnessed 1998-01-10: the
	# SEMIFINALS card view carries 1ST LEG / 2ND LEG blocks with both clubs' own
	# venues (docs/re/knockout_views_re.md). Earlier rounds keep single-leg + replay
	# (the R4 list frame), and the final is a single match.
	"semi_legs": 2,
	"label_scheme": "sequential", "qtr_label": "Qtr Finals",
	"prize_round": 0, "prize_winner": 0, "span_lo": 0.0, "span_hi": 0.7,
}

# Charity Shield (champions v F.A. Cup winners, the season's curtain-raiser). RETIRED to
# 0 on 2026-07-25 for the same reason as the domestic cup purses: it was ours, and the
# original's per-week ledger has no line it could post to. What the original DOES pay for
# the Shield is the £187,500 channelTV fee, which is now booked instead (REFRUN R6).
const CHARITY_PRIZE := 0

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
# The original's own field sizes, counted off its RESULTS screens
# (docs/re/euro_league_screen_re.md):
#   European Cup   24 clubs -> six groups of four -> six winners + the two best
#                  runners-up -> QTR FINALS / SEMIFINALS / FINAL
#   U.E.F.A. Cup   32 clubs -> straight knockout from `1/16 FINALS`
#   Cup Winners'   16 clubs -> straight knockout from `1/8 FINALS`
# (The two qualifying rounds the original plays AHEAD of the European Cup groups -- 15
# ties then 16 -- are not modelled: the app's field is derived from the domestic
# qualifiers plus rated foreign clubs and enters at the group phase.)
const EURO_FIELD := {"european_cup": 24, "uefa_cup": 32, "cup_winners_cup": 16}
# `label` is the original's own phase string for the whole group phase, copied
# verbatim (REFRUN R3): the hub badge read `Euro. Cup / 1/8 Final` on 1 Oct, 5 Nov and
# 26 Nov 1997 alike, and the EURO. LEAGUE screen heads the groups `1/8 FINALS`.
const EURO_GROUPS := {"groups": 6, "advance": 1, "best_runners_up": 2,
	"label": "1/8 Final"}
const UEFA_SPOTS := 2                   # league places below the champions that enter the UEFA Cup
# THE EUROPEAN CALENDAR HAS A BREAK, and Cup's even spread does not (owner-reported
# 2026-07-29: "European cup draws appear too soon. Getting quarter finals in first half of
# season"). He is right, and it is measurable: with 39 league weeks starting Sat 9 Aug 1997
# (the hub's own week-1 date) an even spread put the Cup Winners' Cup quarter-final at week
# ~16, mid-November, and the U.E.F.A. Cup's at week ~20.
#
# The witnesses (docs/re/knockout_views_re.md, from the reference run's own probe log):
#   * euro QTR FINALS **drawn, unplayed, January 1998** (`02_euroleague_qtrfinals_...`)
#   * euro QTR FINALS **1st legs played Sat 14 Mar 1998** (`03_...`)  -> week 32
#   * 1998-99: same, 1st legs Sat 13 Mar 1999, and the SEMIFINALS Sat 27 Mar -> +2 weeks
#   * the FINAL was still undecided at week 38 in BOTH seasons and is played inside the
#     season-end sequence
# and for the group phase the hub badge itself: 1 Oct (wk 9), 5 Nov (wk 14), 26 Nov 1997
# (wk 17) — so the six matchdays run roughly weeks 6..20.
#
# So the last three rounds are PINNED at those fractions and only the rounds before them
# are spread. 32/39 = 0.82 (QF), 34/39 = 0.87 (SF), and the final on the LAST week, which
# is what "still undecided at week 38 in both seasons" means. DECLARED OURS: the three
# fractions are fitted to the four dates above, not read out of MANAGER.EXE — the
# round-week table itself has never been located. What is witnessed is that the
# quarter-finals are a MARCH event, and that is what this restores.
const EURO_TAIL_FRACS := [0.82, 0.87, 1.0]       # quarter-final, semi-final, final
const EURO_HEAD_SPAN := [0.15, 0.54]             # weeks ~6..21 — the autumn rounds
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
# A career starts with an EMPTY youth list (witnessed orig/39, parity run 2026-07-16);
# the YOUTH TEAM SCOUT is the only way anyone joins it. The search DURATION and the
# one-prospect result are MANAGER.EXE's own (Youth.search_weeks / Youth.scout_search);
# the only youth number that is ours is Youth.SEARCH_SPEEDUP, the owner's 2026-07-24
# call to halve the wait so a season carries two intakes rather than one.
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
# The Premier calendar is 38 rounds over THIRTY-NINE weeks: one blank league Saturday
# in the run-in. Witness chain: the badge reads "Premier Week 32" on Sun 8 Mar 1998
# (REFRUN R10, p0524 — so NO round had been skipped by March), "Premier Week 37" as
# the NEXT fixture on Sat 18 Apr (R12, p0610), and the Third Division's finished P=46
# table dated 2/5/1998 appears BEFORE the Premier's last match (R12/R13, p0638) — so
# the final round falls on Sat 2 MAY = week 39, and exactly one Saturday in weeks
# 33..37 carries no Premier round. Week 35 (Sat 4 Apr 1998) is the unique real-1998
# calendar fit — the F.A. Cup semi-final weekend — and rounds 35-38 then land
# 11 / 18 / 25 Apr + 2 May, reproducing both badge witnesses. The old straight
# 38-in-38 calendar finished on 25 April. [Mats QA 2026-07-26: "Premier league was
# already done in april, too soon"]
const BLANK_LEAGUE_WEEK := 35
# Transfer window shuts before the season ends. WITNESSED (REFRUN R10): on Sunday
# 8 March 1998, Premier Week 32, the original raised "The transfer deadline is now
# 2 weeks away." -- so the deadline falls on week 34, i.e. total_weeks() - 5 of the
# 39-week calendar above (was "- 4" of the straight 38-week one: same witnessed date).
const DEADLINE_TAIL := 5
# The original raises exactly TWO warnings, at two weeks and one week out, and the window
# then shuts silently -- there is no deadline-day event (owner, 2026-07-25: not a concept
# in 1998). The two-week wording is the witnessed string; the one-week form is the same
# string pluralised the way PM98 pluralises OFFERS_PER_WEEK's own alert ("%u offer%s").
# REFRUN R16 witnessed the alert on p0685_alert_box.png / p0716_alert_box.png; the exact
# STRING is now read straight out of MANAGER.EXE instead (.data slot 0x662d20 -> 0x6638b4,
# raised by FUN_0057ee50 @0x57efff): "You have been running the club\nat a loss for %u
# week%c now.", where the %c is `(-(1 < n) & 0x53) + 0x20` = 's' for n > 1 and a SPACE for
# n == 1 (the original's own quirk -- "for 1 week  now." -- which the hand transcription in
# REFRUN_manutd_1997-98_FINDINGS.md R16 did not preserve; the frames are not in the repo).
# The same pass moves the manager's reputation: -5 on a loss week, +1 on a clear one,
# clamped to 0..1000 (FUN_0057ee50 @0x57ef3f / 0x57efbb).
const LOSS_ALERT_MSG := "You have been running the club\nat a loss for %d week%s now."
# MEASURED 2026-07-27, no longer ours: the sacking screen FUN_00545fd0 @0x546013 tests
# `cmp [club+0x224],3 / jbe`, so the board dismisses you the moment the counter passes 3,
# i.e. on the FOURTH consecutive week in the red -- exactly the value the port had guessed.
const LOSS_SACK_WEEKS := 4
# FUN_00545fd0 @0x546063: the third dismissal reason -- a squad under 0x10 men, "which does
# not have the minimum number of players needed to play in any championship" (0x662d30).
const SACK_MIN_SQUAD := 16

# ---- the board's dismissal, WHERE the original raises it ------------------
# There is no separate "sacking screen" in MANAGER.EXE. The sack IS the modal that the
# weekly hub screen (factory id 900) raises BEFORE it draws itself: `FUN_00545fd0` tests
# three conditions in ONE order and, on any of them, calls
# `FUN_005e5050(hwnd, "PREMIER MANAGER 98", msg, 0x1001, 0, 0)`, detaches the manager
# (`FUN_0057a500(club, 0xffff)` -> club+0x5c = 0xffff) and returns WITHOUT building a next
# screen. `FUN_004f96c0` then sees the detached club, finds no other live manager record
# and throws `CGFXException(0x4e3e)`, which `FUN_004f8a00` catches and returns from --
# dropping a single-manager career back on the MAIN MENU. Decoded end to end in
# docs/re/sack_path_re.md (both sessions); the three test sites are:
#
#   0x546013  club+0x224 > 3    -> SACK_MSG_FINANCE  (.data slot 0x662d24 -> 0x663818)
#   0x54603a  club+0x294 != 0   -> SACK_MSG_RESULTS  (.data slot 0x662d2c -> 0x663744)
#   0x546063  club+0x28  < 0x10 -> SACK_MSG_SQUAD    (.data slot 0x662d30 -> 0x663690)
#
# All four strings below are MANAGER.EXE's own bytes, newlines included (read out of
# .data at the VAs above, 2026-07-28 -- VA = file offset + 0x401a00).
const SACK_MSG_FINANCE := ("The Directors have held an urgent meeting.\n"
	+ "They have decided to terminate your contract\n"
	+ "as manager due to the disastrous financial management\nof the club.")
const SACK_MSG_RESULTS := ("The Directors have held an urgent meeting,\n"
	+ "and have sacked you as manager of the club.")
const SACK_MSG_SQUAD := ("The Directors have decided to terminate your contract\n"
	+ "due to bad management of your squad,\n"
	+ "which does not have the minimum number of players\n"
	+ "needed to play in any championship.")
# 0x66379c, posted to the club's message list by `FUN_0057d2d0` at the three WARNING weeks.
const BOARD_WARN_MSG := ("The Directors inform you that they are very unhappy with the current\n"
	+ "situation of the team and they expect better results.")

# The board's results review, `FUN_0057a980` @0x57ad6a..0x57aec9, disassembled 2026-07-28.
# Keyed by the division ROUND number just played; `bands` is the club+0x58 expectation
# band the arm applies to ([] = every band), `warn` posts BOARD_WARN_MSG, and `since` is
# the earlier week the sack arm compares against:
#   week 10 -> warn (bands 0,1)                    | 18 -> warn (all)   | 30 -> warn (band 0)
#   week 14 -> sack if below at 10 AND not recovered by 14 (bands 0,1)
#   week 22 -> sack if below at 18 AND not recovered by 22 (all bands)
#   week 26 -> sack if below at 18 AND STILL below at 26 (all bands; no `recovered` call)
#   week 34 -> sack if below at 30 AND not recovered by 34 (band 0)
const BOARD_REVIEW := {
	10: {"warn": true, "bands": [0, 1]},
	14: {"warn": false, "bands": [0, 1], "since": 10, "recover": true},
	18: {"warn": true, "bands": []},
	22: {"warn": false, "bands": [], "since": 18, "recover": true},
	26: {"warn": false, "bands": [], "since": 18, "recover": false},
	30: {"warn": true, "bands": [0]},
	34: {"warn": false, "bands": [0], "since": 30, "recover": true},
}
# `FUN_0057d3a0(week)` -- "below the board's expectation" -- is a position threshold that
# depends on club+0x58 alone (0x57d3cc..0x57d582): Premier band 1 -> pos > 8, band 2 ->
# pos > 15, band >= 3 -> pos > 17, band 0 -> POINTS based (leader's points as of week-1
# >= own + 7); divisions 1/2/3 use the same three-step shape, first band -> pos > 6,
# second -> pos > 13, else -> pos > 15. So the band is a GLOBAL index: Premier 0..3,
# Div 1 4/5/6, Div 2 7/8/9, Div 3 10/11/12.
const BOARD_BAND_POS := {0: -1, 1: 8, 2: 15, 3: 17, 4: 6, 5: 13, 6: 15,
	7: 6, 8: 13, 9: 15, 10: 6, 11: 13, 12: 15}
# ...and the band the port hands it is DERIVED, not decoded: club+0x58's own loader site
# was not located, but the game's START OF SEASON objective LABEL (witnessed for all 92
# English clubs, club_economy.json) fits the band set 1:1 in every division -- four labels
# and four bands in the Premier, three and three in each lower division, in the same order
# of severity. Declared as inference in docs/re/sack_path_re.md §"The band the port uses".
const BOARD_BAND_OF_LABEL := {
	1: {"Champion": 0, "U.E.F.A.": 1, "Mid Table": 2, "Avoid Relegation": 3},
	2: {"Promotion": 4, "Mid Table": 5, "Avoid Relegation": 6},
	3: {"Promotion": 7, "Mid Table": 8, "Avoid Relegation": 9},
	4: {"Promotion": 10, "Mid Table": 11, "Avoid Relegation": 12},
}
# The points gap that trips a band-0 (Champion) club: `add edi,7` @0x57d44a.
const BOARD_TITLE_GAP := 7
const DEADLINE_WARN_WEEKS := [2, 1]
const DEADLINE_WARN_MSG := "The transfer deadline is now %d week%s away."
# The original's 1-April season-end warning pair, verbatim from MANAGER.EXE's message
# table (slots 0x662CDC / 0x662CE0, strings @0x663B20 / @0x663A80). FUN_005862E0
# raises exactly one of them when today == 1 April: the SHORT one when the automatic
# contract-renewal flag DAT_0066B1F4 is set (TRAINER + MANAGER levels), the FULL
# warning when it is not (ACCOUNTANT + TOTAL) — docs/re/sack_path_re.md §NIVEL.
# It sits in the same table, raised by the same function, as the transfer-deadline
# warning above; it had simply never been ported. [Mats QA 2026-07-26]
const SEASON_END_MSG := "The season is near to finishing."
const CONTRACT_WARN_MSG := "The season is near to finishing,\nsome of your players contracts\nmay need renewing. Players can leave\nyour club next year if their contracts\nare not renewed."

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
	youth_search = {}
	youth_found = []
	pending_alerts = []
	week_ledgers = []
	_wk = {}
	loss_weeks = 0
	_reset_board_review()
	pending_channel_tv = {}
	pending_division_finals = []
	pending_cup_draws = []
	pending_champion_cards = []
	sa_champion_id = -1
	training_focus = {}
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
	euro_winner_uefa = -1
	euro_winner_ratings = {}
	euro_winner_names = {}
	supercup = {}
	intercontinental = {}
	var ids: Array = []
	for lc in league_clubs:
		ids.append(int(lc["id"]))
		club_names[int(lc["id"])] = lc.get("name", "?")
		rosters[int(lc["id"])] = _seed_squad(lc)
	fixtures = _league_fixtures(ids)
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
	stadium_headroom = int(club.get("capacityHeadroom", 0))
	ticket_price = float(fin.get("ticket_price", 0.0))   # prices start at the division defaults
	board_price = int(fin.get("board_price", 0))
	# A fresh career starts on the club's OWN .DBC tactic levers (per-club, the
	# witnessed original behaviour — parity-run orig/25: fresh Bolton = 45/50/
	# MIXED/MEDIUM/ZONAL/SHORT/OWN, its exact stream bytes), not global defaults.
	var t0 := Tactics.auto_pick(club, Tactics.DEFAULT_FORMATION)
	t0.apply_club_levers(Tactics.club_levers(club_id))
	tactics = t0.to_dict()
	# A fresh academy + staff pool + free-agent pool for the new club (none carry across).
	var yrng := career_rng()   # S3: the ONE persisted career stream
	youth = []                    # witnessed empty (orig/39, parity run 2026-07-16)
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
	# The cups span the whole pyramid, so they are minted AFTER the other divisions exist.
	_mint_domestic_cups(ids)


## Deep-copy a club's squad into a live roster, stamping a contract length on each
## player (younger players are tied down longer). Never aliases GameDB's data.
func _seed_squad(club_dict: Dictionary) -> Array:
	# Morale/fitness kickoff = the EXE's season reset (FUN_005825c0): morale
	# 90 + rand(10); fitness lands on 70 (halfway from a fresh 99 toward 40 —
	# the exact value frames 081/084 pin for week 1). docs/re/morale_re.md.
	var form_rng := career_rng()   # S3: the ONE persisted career stream
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
			# player+0x87, the counter FUN_0058ac90 @0x58aec7 compares the target against.
			# Seeded here so a shipped record's clause can actually reach its target;
			# advance_week already ticks `clause_apps` for every featured man.
			dup["clause_apps"] = 0
		if int(seeded["bonus"]) > 0:
			dup["clause_bonus"] = int(seeded["bonus"])
		dup["injured_weeks"] = 0       # availability state (Availability.gd)
		dup["suspended_weeks"] = 0
		dup["yellows"] = 0
		dup["dev_progress"] = 0.0      # development carry-over (Training.gd)
		# The engine's BASE attribute block (+0xaa..+0xb3): the shipped EQUIPOS rating,
		# written once at load and never again. Training moves the LIVE block relative
		# to it, and taking a man off training bleeds him back down to it.
		var seed_attrs: Variant = dup.get("attrs", {})
		if seed_attrs is Dictionary:
			dup["attrs_base"] = (seed_attrs as Dictionary).duplicate()
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
	# No witnessed label — the season-2+ board, and any non-English club. The RANK is
	# still the app's own strength-ranked rule (the original's assignment rule is un-RE'd),
	# but the LABEL has to be one of the game's own five categories, because that is the
	# only kind of thing the original's board ever issues (START OF SEASON, all four
	# divisions witnessed 2026-07-19). Until 2026-07-29 the fallback shipped its own prose
	# instead — "Finish 13 or higher", "Avoid relegation" with a small r — which is audit
	# finding O1, and which also broke `expectation_band()`: no fallback string is a key of
	# BOARD_BAND_OF_LABEL, so from season two on every band lookup returned -1 and the board
	# review, the sack ladder and the improvement test all ran on the -1 arm.
	var obj := objective_for(club_id, league_id, league_clubs, leagues)
	objective_text = objective_label(int(obj["pos"]), league_clubs.size(), tier)
	objective_pos = _objective_pos_for(objective_text, league_clubs.size())


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


## The original's objective CATEGORIES (Champion / U.E.F.A. / Mid Table / Avoid Relegation
## / Promotion — witnessed on START OF SEASON for all four English divisions, 2026-07-19)
## mapped from a finish position. The original's own assignment rule is un-RE'd, so the
## CATEGORIES ride the app's positions; the vocabulary is the game's, the choice is ours.
## Lived in Main as `_objective_label` until 2026-07-29, where only the OFFERS SELECTION
## preview could reach it — `_set_objective`'s own fallback needs the same rule (audit O1).
static func objective_label(pos: int, total: int, for_tier: int) -> String:
	var releg := int(SeasonSim.ZONES.get(for_tier, {"releg": 3}).get("releg", 3))
	if pos >= total - releg - 1:
		return "Avoid Relegation"
	if for_tier == 1:
		if pos <= 4:
			return "Champion"
		if pos <= 7:
			return "U.E.F.A."
		return "Mid Table"
	if pos <= 3:
		return "Promotion"
	return "Mid Table"


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


## The manager-league fixture list: the double round-robin with the witnessed blank
## run-in Saturday inserted (see BLANK_LEAGUE_WEEK). Rounds 1..34 play on their own
## week; rounds 35..38 play weeks 36..39 (final round Sat 2 May). Only the 20-club
## 38-round shape is witnessed; other league sizes keep straight scheduling.
static func _league_fixtures(ids: Array) -> Array:
	var fx := SeasonSim.fixtures(ids)
	if fx.size() == 38:
		fx.insert(BLANK_LEAGUE_WEEK - 1, [])
	return fx

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


## The four preseason friendly dates for a season starting in `start_year`, as
## "YYYY-MM-DD". WITNESSED twice and both reproduce exactly: 1997-98 = 1/4/6/8 Aug
## 1997 (pretemporada_screen_re.md) and 1998-99 = 31 Jul + 3/5/7 Aug 1998 (REFRUN
## R15 step 8, p0664). The rule both fit: F = the day before August's first
## Saturday; the friendlies fall on F, F+3, F+5, F+7 (Fri / Mon / Wed / Fri).
static func preseason_dates(start_year: int) -> Array:
	var aug1 := int(Time.get_unix_time_from_datetime_dict(
		{"year": start_year, "month": 8, "day": 1, "hour": 12, "minute": 0, "second": 0}))
	var wd := int(Time.get_datetime_dict_from_unix_time(aug1).get("weekday", 0))  # 0 = Sun
	var first_sat := aug1 + ((6 - wd) % 7) * 86400
	var out: Array = []
	for off in [-1, 2, 4, 6]:
		var d := Time.get_datetime_dict_from_unix_time(first_sat + off * 86400)
		out.append("%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)])
	return out


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
		rv_xi if at_home else my_xi, h, a, 90, true)
	# The MAN OF THE MATCH selector runs on the MATCH report, which every fixture has;
	# what the live witness pins about friendlies is that they fold NOTHING into the
	# season store (Beckham's MP 7 = 6 rounds + the Shield). So pick him, name him on
	# the read-out, and skip fold_back.
	var mom := Pm98StatStore.pick_mom(res["report"]) if res.get("report") != null else 0
	friendlies_played += 1
	# A bid placed before this CONTINUE is answered BY it — witnessed 2026-07-24 on the
	# real game (bid placed week 1, "You have signed Barlow of Rochdale." on the very next
	# CONTINUE). The preseason friendlies are CONTINUEs too, so they must answer as well;
	# otherwise a bid placed at the start of the season sits unanswered until round 1.
	_resolve_pending_bids(rng)
	friendly_results.append({"date": str(pick.get("date", "")), "home_id": h,
		"away_id": a, "hg": int(res["home_goals"]), "ag": int(res["away_goals"])})
	return {"home_id": h, "away_id": a, "hg": int(res["home_goals"]),
		"ag": int(res["away_goals"]), "manager_home": at_home, "motm_pid": mom,
		"xi_home": my_xi if at_home else rv_xi, "xi_away": rv_xi if at_home else my_xi,
		"report": res.get("report"), "report_ht": res.get("report_ht"),
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
	_mark_month_start()   # the first round of a calendar month snapshots every table
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
		var mom := 0
		if mine:
			mom = fold_match_stats(res, h, a)
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
				# FUN_0044a370's pick, named on the FULL TIME read-out's MAN OF THE MATCH band
				"motm_pid": mom,
				# The 22 players that actually took the field. The stat engine only ever
				# knew these (build_mem takes the two XIs), so the BRIEF feed must name
				# them and nobody else — the owner's "I sold Pallister and he still picks
				# up yellow cards" was the feed reading the frozen 1997 GameDB squad.
				"xi_home": xi_of_id.call(h), "xi_away": xi_of_id.call(a),
				"report": res.get("report"), "report_ht": res.get("report_ht"),
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
	# THE WEEK'S BOOKS (REFRUN R5/R9). The original charges PLAYERS' WAGE + STAFF WAGES
	# EVERY week and adds income only on a HOME matchday, so an away week is a pure loss
	# (witnessed: -£233,942 flat, and Man Utd's cash FELL £9.6M -> £3.3M across 1997-98).
	# The old model added one constant season-average `weekly_net` every week regardless,
	# which is the sign error R9 measured; weekly_net now survives only as the FINANCES
	# screen's season projection and as save-file compatibility.
	_post_expense("PLAYERS' WAGE", player_weekly_wage())
	_rec_detail()["wage_gross"] += player_weekly_wage()   # the section's green sub-row
	_post_expense("STAFF WAGES", Staff.weekly_wage(staff))
	_post_matchday_income(manager_res)
	_tick_insurance()                  # premiums, hospital bills and policy payouts
	_resolve_pending_bids(rng)         # last week's outgoing bids get their answers
	_accumulate_offers(rng)            # incoming bids on the transfer-listed (CURRENT OFFERS)
	_refresh_staff_pool(rng)           # a brand-new hire list every week (CLUB PERSONNEL)
	week += 1
	_close_month_if_due()           # end of a calendar month -> the two award sheets
	offers_left = OFFERS_PER_WEEK   # the board's weekly signing allowance resets
	_tick_works()                   # stadium expansion progresses a week
	_tick_transfer_deadline()       # the two-week / one-week deadline warnings (R10)
	_tick_contract_warning()        # the 1-April season-end / contract-renewal warning
	_tick_one_off_finals(rng)       # Intercontinental in December, Supercup in March (R7/R11)
	if week == total_weeks() - 1:
		_queue_division_finals()    # R13: the finished divisions' tables, before your last round
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
	# ...and the WEEKLY illness tick, which the original runs whether or not the club
	# played (`FUN_0057a980`; roll_A is the only path that can produce virus or cold).
	# It posts to the club's message list, so it rides pending_alerts like the original's.
	for n in Availability.roll_weekly_illness(rng, my_squad()):
		_news(n["kind"], n["text"])
		pending_alerts.append(str(n["text"]))
	if not manager_res.is_empty():
		# A physiotherapist on the staff lowers the injury risk (physio_factor <= 1.0).
		var inj_mult := Training.injury_multiplier(training_intensity) * Staff.physio_factor(staff)
		for n in Availability.roll_match(rng, featured, inj_mult):
			_news(n["kind"], n["text"])
	# The weekly development pass, byte-exact from FUN_00582760 (see Training.gd):
	# a player carrying a TRAINING-screen focus climbs that attribute a POINT A WEEK
	# until he is 18-24 clear of his shipped rating (GENERAL: all six, +5); a player
	# with no focus bleeds any gains back at a point a week. The original walks every
	# club's squad here, so the rivals get the same pass below (_roll_ai_squads).
	for n in Training.develop_week(rng, my_squad(), training_focus):
		_news(n["kind"], n["text"])
	# The youth team runs the same weekly pass on its 0x20 YOUTH mode: 60% of a point on
	# every attribute, hard-stopped at his own shipped rating, and the youth manager's
	# "ready to be promoted" line the moment the core four get there. That line is the
	# original's own hub report ("Your youth manager has informed you that..."), so it
	# rides pending_alerts like the scout's — not just the news feed.
	for n in Youth.develop_week(rng, youth):
		_news(n["kind"], n["text"])
		if str(n["text"]).begins_with("Your youth manager has informed you"):
			pending_alerts.append(str(n["text"]))
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
	# Close the week's books LAST, so every posting this week made -- wages, the matchday
	# take, insurance, cup ties, transfers -- is inside the record before the
	# running-at-a-loss counter reads it (REFRUN R5/R9/R16).
	_close_week_books()
	# The board's results review runs in the same weekly per-club update as the finance
	# step (`FUN_0057a980`, after the books, before the hub is mounted) and reads the
	# table the round just produced. `week` has already been advanced by the round, so the
	# round NUMBER just played is `week` (1-based).
	_board_results_review(week)
	# ...then queue the channelTV card for the fixture the manager is about to play, which
	# is how the original raises it: unprompted, on the hub, BEFORE the match (R6).
	_queue_channel_tv()
	if season_over():
		finished = true
	return manager_res


## Queue one knockout round's SORTEO for the hub (REFRUN R4). Reads the bracket's LATEST
## round -- the one just resolved -- and hands CupDrawScreen exactly the payload it takes.
## A group-phase step is not a draw and raises nothing; nor is a round of byes only.
func _queue_cup_draw(b: Dictionary) -> void:
	# The SORTEO is by definition the draw of a round about to be PLAYED, so it reads
	# `pending_draw` and nothing else. Reading the last PLAYED round instead (what this did
	# until 2026-07-26) meant the final's own card was raised after the final had been
	# decided. No pending draw -> the competition has nothing left to draw -> no card.
	var pd: Dictionary = b.get("pending_draw", {})
	if pd.is_empty():
		return
	# ...and only for a competition the manager's club is STILL IN. The card is a hub
	# INTERRUPT, so raising it for a cup you are out of (or never entered) stops the week
	# for a draw that cannot involve you — owner-reported 2026-07-29, on the European
	# quarter-finals of a career with no European place at all. DECLARED OURS: no frame
	# shows what the original does for a non-participant (the reference run's club was in
	# the European Cup and both domestic cups all season, so every draw it saw was its
	# own). The bracket itself is unchanged and every round stays readable on the
	# KNOCKOUT screen — only the unprompted card is gated.
	#
	# The test is the DRAWN ROUND's own player list, not `Cup.still_in`: the domestic cups
	# hold the Premier clubs out until Round 3 (`late_entry`), so a survivors test would
	# suppress the very draw the reference run witnesses being raised ("Sun 14 Dec 1997
	# F.A. Cup Round 2 played ... the SORTEO for Round 3 is raised unprompted", with Man
	# Utd entering AT Round 3).
	if not (pd.get("players", []) as Array).has(club_id):
		return
	var ties: Array = []
	# The byes are skipped: a bye has no opponent and the original lists no line for it.
	var players: Array = pd.get("players", [])
	var i := 0
	while i + 1 < players.size():
		var h := int(players[i])
		var a := int(players[i + 1])
		ties.append({"home": _any_club_name(h), "away": _any_club_name(a),
			"home_id": h, "away_id": a})
		i += 2
	if ties.is_empty():
		return
	var name := str(b.get("name", ""))
	pending_cup_draws.append({
		"key": Cup.draw_art_key(b),
		"title": name,
		"round": Cup.draw_round_plate(b),
		"ties": ties,
		"total": ties.size(),
		"legs": Cup.draw_leg_plates(b),
	})


## Play every due round of both cups (F.A. Cup + League Cup) whose scheduled week has
## been reached. The bracket dicts mutate in place, so this writes straight to the save.
func _play_due_cup_rounds(rng: RandomNumberGenerator, clubs_override: Dictionary) -> void:
	var ratings_fn := func(id: int) -> Dictionary: return _ratings_for(id, clubs_override)
	var xi_fn := func(id: int) -> Array: return _xi_for(id, clubs_override)
	var names_fn := func(id: int) -> String:
		return _any_club_name(int(id))
	for cup in [fa_cup, league_cup]:
		if cup.is_empty():
			continue
		while Cup.round_due(cup, week):
			# DRAW-THEN-PLAY (witnessed 2026-07-26, see Cup.draw_next_round): a round the
			# original drew in an earlier week is already sitting in `pending_draw` and is
			# consumed here; a competition's FIRST round has none, and pairs on the spot.
			var cr := Cup.play_round(cup, rng, ratings_fn, club_id, names_fn, xi_fn,
				_cup_report_sink())
			# ...and the NEXT round is drawn the moment this one resolves, which is what
			# puts the SORTEO a week or more ahead of the ties it shows.
			Cup.draw_next_round(cup, rng)
			_queue_cup_draw(cup)
			for n in cr["news"]:
				_news(n["kind"], n["text"])
			# NOTE: cr["prize"] is Cup's own documented-invention purse and is now ZERO
			# (Cup.ROUND_PRIZE / WINNER_BONUS, and LEAGUE_CUP_OPTS). The original's
			# per-week ledger has NO domestic-cup income line (REFRUN R5), and an away
			# week's income was measured at exactly £0 -- a cup run pays the club through
			# the turnstiles, not through a purse. Booked below, as a matchday.
			# A cup tie AT HOME is a matchday: turnstiles, channelTV and the players' bonus,
			# exactly as a league Saturday (REFRUN R6/R9). The TV fee for the two domestic
			# cups is NOT witnessed, so _post_home_match pays 0 for them.
			var ct: Dictionary = cr.get("manager_tie", {})
			if _tie_is_home(ct):
				_post_home_match(_tv_key_for_cup(str(cup.get("name", ""))))
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
			# Same draw-then-play order as the domestic cups. `draw_next_round` is a no-op
			# while the group phase is live, so the group matchdays raise no SORTEO.
			Cup.draw_next_round(eb, rng)
			_queue_cup_draw(eb)
			for n in er["news"]:
				_news(n["kind"], n["text"])
			if str(er.get("phase", "")) == "group":
				# Group phase pays per match on the reversed UEFA per-match schedule (the
				# figures the knockout collapses to per-tie), plus the last-8 bonus on
				# qualifying through the group.
				match str(er.get("manager_result", "")):
					"win":
						_post_euro_points(EURO_WIN)
					"draw":
						_post_euro_points(EURO_DRAW)
				if bool(er.get("manager_qualified", false)):
					_post_euro_points(EURO_QF)
			elif in_before:
				# EUROPEAN CUP INCOME is one of the screen's own income lines (REFRUN R5),
				# and the UEFA schedule behind these figures IS reversed from MANAGER.EXE.
				_post_euro_points(_euro_prize(eb, er))
			var et: Dictionary = er.get("manager_tie", {})
			if _tie_is_home(et):
				_post_home_match(str(key))


## Was the manager's club the HOME side of this tie? A two-legged tie hosts one leg each
## way, so it counts as a home matchday either way; a bye and an empty tie do not.
func _tie_is_home(tie: Dictionary) -> bool:
	if tie.is_empty() or bool(tie.get("bye", false)):
		return false
	if bool(tie.get("two_legged", false)):
		return int(tie.get("home_id", -1)) == club_id or int(tie.get("away_id", -1)) == club_id
	return int(tie.get("home_id", -1)) == club_id


## FinanceModel.TV_FEE key for a domestic cup by display name.
##
## 2026-07-28 (s78): both domestic cups pay £0, and it is now PROVED rather than unmeasured.
## Neither the F.A. Cup's nor the Coca-Cola Cup's competition class in MANAGER.EXE contains
## a single write to `club+0x290`, the channelTV fee field (`docs/re/channeltv_fee_re.md`),
## so the original raises no card and books no TELEVISION row for a domestic cup tie. The
## £0 is the game's own figure. Any other cup name falls through to a key with no entry,
## which is still 0.
const CUP_TV_KEY := {
	"F.A. Cup": "fa_cup",
	"Coca-Cola Cup": "coca_cola",
}

func _tv_key_for_cup(cup_name: String) -> String:
	return str(CUP_TV_KEY.get(cup_name, "cup:%s" % cup_name))


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
		var mt := Tactics.from_dict(tactics).repaired(fit)
		var r := mt.ratings(fit)
		# THREE UP FRONT triggers (manager side ONLY — hack_three_forwards.md
		# §MIXED PLAY / §THE SHAPE TRIGGER): read by MatchSim's stat branch, inert
		# with the cheat off. `front_three` is the CHOSEN SHAPE's forward-slot count,
		# not who happens to fill those slots — that is the whole point of it (a
		# 4-3-3 fielded by a squad with two natural forwards never armed the
		# natural-role trigger).
		r["mixed_play"] = mt.mentality == "Mixed"
		r["front_three"] = Tactics.forward_slots(mt.formation) >= 3
		return r
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
## so injuries weaken the side the same way. A foreign euro opponent fields its shipped
## TRUE XI (`euro_xis`, fed by Main from club_tactics.json + game_db — S5 2026-07-27);
## with no feed it returns [] -> the loud legacy fallback, as before.
func _xi_for(id: int, clubs_override: Dictionary = {}) -> Array:
	if id == club_id and not tactics.is_empty():
		return _mgr_featured_xi()
	if not rosters.has(id) and euro_ratings.has(id):
		return euro_xis.get(id, [])
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


## A rival club's fielded XI this week, availability-filtered. SHAPE-AWARE since
## 2026-07-26: the original's AI fields its stored club tactic (the EQUIPOS slot
## block — overwhelmingly a 4-4-2 family shape), not a scratch "best ten by
## ability" pick. The old shape-free pick here fielded 3+ NATURAL FORWARDS at 16
## of 20 Premier clubs, which armed the THREE UP FRONT cave for the OPPOSITION
## whenever the cheat was on (Pm98StatMatch counts ROLE==3 per side) while the
## manager's own default 4-4-2 never armed it — Mats: "won't get me goals".
## Position-aware auto_pick (GK + 4 DF + 4 MF + 2 FW, best of each line) restores
## the original's shape; _pad_xi still guarantees eleven.
func _ai_featured_xi(id: int) -> Array:
	var pool := available_squad(id)
	var t := Tactics.auto_pick({"players": pool})
	var by_id: Dictionary = {}
	for p in pool:
		by_id[int(p.get("id", -1))] = p
	var xi: Array = []
	for pid in t.xi:
		if by_id.has(int(pid)):
			xi.append(by_id[int(pid)])
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
		# The weekly illness tick is per CLUB in the original (`FUN_0057a980` runs down
		# the whole club list), so the rivals catch colds too; their lines stay quiet,
		# same as their recoveries, and the notable-injury feed below still surfaces the
		# long ones.
		Availability.roll_weekly_illness(rng, squad)
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
		# The original runs the SAME weekly pass over every club's squad (FUN_0057b400
		# walks club+0x24 and calls FUN_00582760 per player). An AI side carries no
		# TRAINING-screen focus, so the pass is pure decay for them — they hold at their
		# shipped ratings. That is the engine's behaviour, not a simplification.
		Training.develop_week(rng, squad)


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
	var rng := career_rng()   # S3: the ONE persisted career stream
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
		var head2 := 1 if int(t) > tier else 0
		var n_fx := int((divisions[t]["fixtures"] as Array).size())
		var target := head2 + _division_rounds_due(n_fx - head2)
		while int(divisions[t]["played"]) < mini(target, n_fx):
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


## Advance every OTHER division to where it should be by this manager week.
##
## WITNESSED (REFRUN R12): the lower divisions play ALL 46 of their rounds and run AHEAD
## of the Premier -- the First Division table dated 18/4/1998 (the manager's week 37) reads
## P = 44 for every club, and the Third Division reached P = 46 before the Premier's last
## match. The extra rounds are midweek fixtures. Playing exactly one lower round per manager
## week (what this did before) stalls a 46-round division at 38 and hands `_pyramid_rollover`
## a short table, so promotion and relegation were computed off an unfinished season.
##
## The catch-up rule spreads the surplus rounds evenly across the manager's season:
##     rounds_due(w) = w + floor((division_rounds - manager_weeks) * w / manager_weeks)
## At w = 37 of 38, a 46-round division is due 37 + floor(8*37/38) = 44 -- the First
## Division witness, exactly -- and the last manager week clears the remaining two. The
## PER-DIVISION midweek allocation (which is what puts the Third Division two weeks further
## on) is not witnessed, so every lower division shares the one schedule rather than getting
## an invented one of its own.
func _advance_other_divisions(rng: RandomNumberGenerator) -> void:
	for t in divisions:
		var dv: Dictionary = divisions.get(int(t), {})
		if dv.is_empty():
			continue
		# The witnessed one-round HEAD START of every division BELOW the manager's
		# (Career._build_divisions) rides on top of the catch-up schedule.
		var head := 1 if int(t) > tier else 0
		var due := head + _division_rounds_due(int((dv.get("fixtures", []) as Array).size()) - head)
		while int(dv.get("played", 0)) < due:
			var before := int(dv.get("played", 0))
			_play_division_round(int(t), rng)
			if int(dv.get("played", 0)) == before:
				break            # nothing left to play (or the division is detached)


## How many rounds a division of `n_rounds` should have played by the manager's current
## week. See _advance_other_divisions for the witness this reproduces. The denominator
## is the manager league's ROUND count (the blank run-in Saturday excluded), while
## `week` keeps counting calendar weeks INCLUDING the blank — that pairing reproduces
## both R12 witnesses on the 39-week calendar: First Division P=44 (+head 1) at the
## 18-Apr hub read (week 37), and P=46 complete at week 38, BEFORE the 2-May final
## round (p0638). A round-count of `total_weeks()` here delayed both by a week.
func _division_rounds_due(n_rounds: int) -> int:
	var mw := total_weeks() - _blank_rounds()
	if mw <= 0 or n_rounds <= 0:
		return 0
	if n_rounds <= mw:
		return mini(week, n_rounds)
	@warning_ignore("integer_division")
	var extra := ((n_rounds - mw) * week) / mw
	return mini(week + extra, n_rounds)


## Blank (empty) rounds in the manager league's fixture list (the run-in Saturday).
func _blank_rounds() -> int:
	var n := 0
	for r in fixtures:
		if (r as Array).is_empty():
			n += 1
	return n


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
## Returns FUN_0044a370's MAN OF THE MATCH pick (0 when no record survives its gates,
## which is also what the binary leaves in F+0xac) so the caller can name him on the
## FULL TIME read-out.
func fold_match_stats(res: Dictionary, home_id: int, away_id: int, league := true,
		bump_club := true) -> int:
	var rep = res.get("report")
	if rep == null:
		return 0
	var mom := Pm98StatStore.pick_mom(rep)
	Pm98StatStore.fold_back(rep, season_stats, mom)
	if not bump_club:
		return mom
	for cid in [home_id, away_id]:
		# @0x449189 also has a `+= 120` branch, taken when F+0x58 != 0 AND F+0x48 != 0.
		# Neither field has an identified producer, so that branch is deliberately NOT
		# modelled rather than guessed; every fixture here takes the witnessed +90.
		season_club_minutes[cid] = int(season_club_minutes.get(cid, 0)) + 90
		if league:
			season_club_mp[cid] = int(season_club_mp.get(cid, 0)) + 1
	return mom


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

## `FUN_0057a730` (the weekly reset the season loop runs at the top of every pass) zeroes
## club+0x294 before the review can re-set it, so the flag never survives into a new season.
func _reset_board_review() -> void:
	board_sack_flag = 0
	board_reviewed = []
	_below_at = {}
	_pos_at = {}


## club+0x58 -- the board's expectation band for this club, derived from the game's own
## START OF SEASON objective label (see BOARD_BAND_OF_LABEL). -1 when the club carries no
## witnessed label (every non-English club), which is exactly the `division > 3` arm of
## `FUN_0057d3a0`: no board review at all.
func expectation_band() -> int:
	var by_label: Dictionary = BOARD_BAND_OF_LABEL.get(tier, {})
	return int(by_label.get(objective_text, -1))


## `FUN_0057d3a0(week)`: is the club BELOW the board's expectation as of `round_no`?
## `round_no` is the division's 1-based round number; the original queries the table as of
## `round_no - 1`, which for the app is the standings after that many rounds have been
## played. Returns false for an unknown band (no review) and for round 0.
func below_expectation(round_no: int) -> bool:
	if round_no <= 0:
		return false
	var band := expectation_band()
	if band < 0:
		return false
	var rows := standings()
	var pos := 0
	for i in rows.size():
		if int(rows[i]["id"]) == club_id:
			pos = i + 1
			break
	if pos == 0:
		return false
	if band == 0:
		# The points arm: the leader's points against the club's own, +7 (0x57d44a).
		var leader := int(rows[0]["Pts"]) if not rows.is_empty() else 0
		var mine := 0
		for r in rows:
			if int(r["id"]) == club_id:
				mine = int(r["Pts"])
				break
		return leader >= mine + BOARD_TITLE_GAP
	return pos > int(BOARD_BAND_POS.get(band, 99))


## The board's weekly results review, `FUN_0057a980` @0x57ad6a. Runs once per league round
## the manager's own division plays, from round 10 on, and either posts the WARNING message
## or sets/clears club+0x294 (`board_sack_flag`) per BOARD_REVIEW. The original gates the
## whole block on the Promanager career flag `DAT_0066b1e4` (a Manager League career is
## never results-reviewed); this port routes both front-door choices through one career and
## so runs it always -- recorded in docs/re/sack_path_re.md, not silently.
func _board_results_review(round_no: int) -> void:
	var arm: Dictionary = BOARD_REVIEW.get(round_no, {})
	if arm.is_empty() or board_reviewed.has(round_no):
		return
	var band := expectation_band()
	if band < 0:
		return
	var bands: Array = arm["bands"]
	if not bands.is_empty() and not bands.has(band):
		return
	board_reviewed.append(round_no)
	if bool(arm["warn"]):
		# The original re-queries the league table AS OF the warning week when the sack
		# arm runs four weeks later (`vt[0x88](club, week-1)`); the port keeps no historic
		# tables, so it banks the same two readings here. Every `since` week in
		# BOARD_REVIEW is a warn week over the SAME band set, so the two agree.
		var below := below_expectation(round_no)
		_below_at[round_no] = below
		_pos_at[round_no] = position()
		if below:
			pending_alerts.append(BOARD_WARN_MSG)
		return
	# A sack arm: it fires ONLY when the club was already below at the warning week.
	var since := int(arm["since"])
	if not _below_at.has(since) or not bool(_below_at[since]):
		board_sack_flag = 0
		return
	# `recover` = the original calls FUN_0057d5b0(since, now) -- did the club IMPROVE its
	# standing between the two weeks? -- while week 26 simply re-tests "still below".
	var still_bad := below_expectation(round_no)
	if bool(arm["recover"]):
		still_bad = still_bad and not _recovered(since, round_no)
	board_sack_flag = 1 if still_bad else 0


## `FUN_0057d5b0(wkA, wkB)`: did the club's standing IMPROVE between the two review weeks?
## The port keeps the position it recorded at the warning week and compares (`setl`, the
## mirror of below_expectation's `setge`).
func _recovered(wk_a: int, wk_b: int) -> bool:
	if not _pos_at.has(wk_a):
		return false
	var then := int(_pos_at[wk_a])
	var now := position()
	if expectation_band() == 0:
		# Band 0 compares POINTS to the leader, not places.
		return not below_expectation(wk_b)
	return now < then


## UNSACKABLE -- the port of the MANAGER_HACK.EXE unsackable patch
## (docs/re/hack_unsackable.md). Not a PM98 setting: the original has no such option.
## The EXE patch flips FUN_00545fd0's three "keep him" branches to unconditional jumps,
## which makes all three dismissal arms unreachable; here the same three tests are the
## whole of `sack_message()`, so the port's equivalent is one early return at its head.
## Mirrored from `AudioManager.set_unsackable`, exactly as `Pm98StatMatch`'s two cheat
## statics are. OFF by default, and OFF leaves every arm exactly as it was.
static var cheat_unsackable := false

## `FUN_00545fd0`'s three dismissal tests, in the binary's own order. Returns the message
## the original would raise, or "" when the board keeps you. Consumed by Main at the hub
## mount -- the same place the original consumes it.
func sack_message() -> String:
	if cheat_unsackable:
		return ""
	if loss_weeks >= LOSS_SACK_WEEKS:
		return SACK_MSG_FINANCE
	if board_sack_flag != 0:
		return SACK_MSG_RESULTS
	if (rosters.get(club_id, []) as Array).size() < SACK_MIN_SQUAD:
		return SACK_MSG_SQUAD
	return ""


## The reason word behind `sack_message()`, for the career record and the tests.
func sack_message_reason() -> String:
	if cheat_unsackable:
		return ""
	if loss_weeks >= LOSS_SACK_WEEKS:
		return "insolvent"
	if board_sack_flag != 0:
		return "results"
	if (rosters.get(club_id, []) as Array).size() < SACK_MIN_SQUAD:
		return "squad"
	return ""


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
		# The board does NOT dismiss at a season's end: all three of MANAGER.EXE's
		# dismissals are raised by the WEEKLY hub run `FUN_00545fd0` and end the career on
		# the spot (`sack_message()` above, consumed by Main at the hub mount). What is
		# left for the season review is the reputation move and the headhunt -- the app's
		# own multi-club extension. `sacked` here only reports a sack that has ALREADY
		# happened, so a review run after one still reads true.
		var rng := career_rng()   # S3: the ONE persisted career stream
		headhunt_pending = not sacked and Manager.headhunted(finished_pos, objective_pos, reputation, rng)
		if sacked:
			reputation = Manager.apply_delta(reputation, Manager.REP_SACK)
		_rep_year = year
	return {
		"sacked": sacked, "reason": sack_reason, "headhunted": headhunt_pending,
		"finished_pos": finished_pos, "objective_pos": objective_pos,
		"objective_met": finished_pos <= objective_pos,
		"reputation": int(round(reputation)), "rep_label": Manager.reputation_label(reputation),
		"loss_weeks": loss_weeks,
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

## The career's own RNG stream (S3, COMPLETE 2026-07-27). One seeding roll at first use
## — the original also seeds from time() once — then the state is persisted across
## save/load, so a loaded career continues the SAME stream instead of re-randomizing
## per call site. Every former per-call randomize() in Career.gd and Main's career
## paths now draws from here, so pinning `career_rng_state` BEFORE the first draw plus
## seeding the advance-week rng pins a whole career (test_career_seed.gd). Presentation
## randomness (commentary narration, the DB-browser sandbox) deliberately stays local.
func career_rng() -> RandomNumberGenerator:
	if _career_rng == null:
		_career_rng = RandomNumberGenerator.new()
		if career_rng_state != "":
			_career_rng.state = career_rng_state.to_int()
		else:
			_career_rng.randomize()
	return _career_rng


## Start a YOUTH TEAM SCOUT search (YOUTH TEAM screen's SEARCH button, frame 047's
## "The scout is now searching..." state). Skill keys are the screen's cap_order ids.
## No-op without a hired scout, with a search already running, or with ZERO capabilities
## lit — a zero-LED search can never match (`FUN_00575d90` is an OR over the lit flags),
## so arming one is a guaranteed dead 15-28 weeks; the screen shows the EXE's own
## refusal alert (0x65d3c0) and this guard keeps headless callers honest too. The loop
## itself is decoded from MANAGER.EXE strings (docs/re/youth_re.md): search -> "finished
## his search" / "...hasn't found"; the duration is FUN_0053e860's own.
func start_youth_search(skills: Array) -> void:
	if skills.is_empty():
		return
	var scout := Staff.member_in_role(staff, Staff.YOUTH_TEAM_SCOUT)
	if youth_search.is_empty() and not scout.is_empty():
		# FUN_0053e860 @0x53e967: rand(6) + 0x37 - 5*((quality+1)>>1), over the owner's
		# SEARCH_SPEEDUP. A 5-star scout is fast, a half-star one takes most of a season.
		youth_search = {"skills": skills.duplicate(),
			"weeks": Youth.search_weeks(career_rng(), Staff.quality_byte(scout))}
		youth_found = []      # arming a new search clears the last one's shortlist
		_news("youth", "The scout is now searching for players with selected capabilities.")

## Weekly tick of a running scout search. On completion the scout comes back with a
## SHORTLIST — the PLAYERS FOUND panel — or empty-handed. A found youngster does NOT
## join by himself: you offer him a contract from the panel, and he can turn it down
## ("The youth player %s has rejected your offer.", MANAGER.EXE 0x663be8 — the string
## only makes sense if there is an offer step, which the app used to skip).
func _tick_youth_search(rng: RandomNumberGenerator) -> void:
	if youth_search.is_empty():
		return
	youth_search["weeks"] = int(youth_search.get("weeks", 1)) - 1
	if int(youth_search["weeks"]) > 0:
		return
	var skills: Array = youth_search.get("skills", [])
	youth_search = {}
	# FUN_00575e80: walk the shipped 0x26e4 pool, keep every record whose BASE clears
	# 0x4f on ANY lit capability, then throw all but ONE at random. `_youth_taken` is
	# the engine dropping a signed youngster out of the pool for good.
	youth_found = Youth.scout_search(rng, skills, youth_pool, _youth_taken())
	if not youth_found.is_empty():
		_news("youth", "The youth team scout has finished his search.")
		pending_alerts.append("The youth team scout has finished his search.")
	else:
		_news("youth", "The youth team scout has finished his search and hasn't found\na player with the required qualities.")
		pending_alerts.append("The youth team scout has finished his search and hasn't found\na player with the required qualities.")


## Ids already out of the shipped 0x26e4 pool — in your academy, or promoted into your
## squad. The engine re-parents a signed youngster, so the scout can never re-find him.
## Only POOL-scouted members count (`_from_youth_pool`): the easter-egg lane's ids
## (wonderkid, talents) live in a different id space and are not the pool's business.
func _youth_taken() -> Array:
	var out: Array = []
	for p in youth:
		if int(p.get("_from_youth_pool", 0)) == 1:
			out.append(int(p.get("id", -1)))
	for p in rosters.get(club_id, []):
		var pid := int(p.get("id", -1))
		if pid >= 0 and int(p.get("_from_youth_pool", 0)) == 1:
			out.append(pid)
	return out


## How many of the academy's members came through the faithful scout loop. The declared
## SQUAD_CAP applies to THIS number, so an easter-egg arrival (wonderkid, scheduled
## talent — both bypass the cap on entry by design) never blocks a scouted signing.
func _scouted_youth_count() -> int:
	var n := 0
	for p in youth:
		if int(p.get("_from_youth_pool", 0)) == 1:
			n += 1
	return n


## Offer a contract to one of the scout's finds (a PLAYERS FOUND row tap). He joins the
## youth setup, or refuses — the two outcomes the MANAGER.EXE strings describe. A raw
## prospect with a big ceiling is the likeliest to say no. {ok, msg}.
func sign_youth_prospect(pid: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var idx := -1
	for i in youth_found.size():
		if int((youth_found[i] as Dictionary).get("id", -2)) == pid:
			idx = i
			break
	if idx == -1:
		return {"ok": false, "msg": "That youngster is no longer available."}
	var p: Dictionary = youth_found[idx]
	var nm := str(p.get("name", "?"))
	if _scouted_youth_count() >= Youth.SQUAD_CAP:
		return {"ok": false, "msg": "Your Youth Team is full (%d)." % Youth.SQUAD_CAP}
	if rng == null:
		rng = career_rng()
	# Refusal chance rises with his potential and falls with the YOUTH MANAGER's pull.
	var pot := float(Youth.potential_of(p))
	var pull := Staff.youth_factor(staff)
	var refuse := clampf((pot - 55.0) / 120.0 / maxf(0.5, pull), 0.0, 0.45)
	if rng.randf() < refuse:
		youth_found.remove_at(idx)
		_news("youth", "The youth player %s has rejected your offer." % nm)
		return {"ok": false, "msg": "The youth player %s has rejected your offer." % nm}
	youth_found.remove_at(idx)
	youth.append(Youth.enrol(p, club_id))
	_news("youth", "%s has joined your Youth Team." % nm)
	_log("%s has joined your Youth Team." % nm)
	return {"ok": true, "msg": "%s has joined your Youth Team." % nm}


# ---- the SENIOR scout search (SCOUT screen, docs/re/scout_screen_re.md) ----

## Witnessed duration with the ★★★ scout: armed week 3, still searching after
## one advance, finished-alert after the second (frames 68/73/78). Quality
## dependence is un-witnessed — flat 2 weeks, documented.
const SCOUT_SEARCH_WEEKS := 2

## AGE / QUALITY / PRICE scout criteria are BAND dropdowns (SCOUT screen), labels +
## order lifted binary-exact from the MANAGER.EXE getter tables 0x661e08 / 0x661e20 /
## 0x661e40 (see ScoutScreen). These are the numeric bounds behind each band index,
## inclusive. QUALITY matches the displayed AV column (0-99); PRICE bounds are in K.
## All five band tables are now confirmed against the resolver itself, `FUN_005753e0`
## (the senior scout vtable 0x6354f8 slot 0), disassembled 2026-07-25:
##   AGE     @0x57544b — 17-22 / 23-26 / 27-30 / 31-33 / >33
##   QUALITY @0x57552e — the >>2 mean of the player's +0x9c..+0x9f bytes (= AV) against
##                       0x32-0x41 / 0x42-0x46 / 0x47-0x4b / 0x4c-0x50 / 0x51-0x55 /
##                       0x56-0x5a / >0x5a
##   PRICE   @0x5755c8 — value x 1e-06 (the double at 0x638200), i.e. units of 5 K,
##                       against 2-15 / 16-25 / 26-50 / 51-100 / 101-300 / 301-600 /
##                       601-1000 / 1001-1500 / 1501-2000 / >2000 = exactly the K bounds
##                       below. 0xff in any criterion byte = that filter is OFF.
const SCOUT_AGE_BANDS := [[17, 22], [23, 26], [27, 30], [31, 33], [34, 99]]
const SCOUT_QUALITY_BANDS := [[50, 65], [66, 70], [71, 75], [76, 80], [81, 85], [86, 90], [91, 99]]
const SCOUT_PRICE_BANDS_K := [[10, 75], [80, 125], [130, 250], [250, 500], [500, 1500],
	[1500, 3000], [3000, 5000], [5000, 7500], [7500, 10000], [10000, 999999]]

## The shortlist cap, `FUN_00575750` @0x5757e7: `(quality_byte + 2) * 5`, where the
## quality byte is the staff record's raw 1..10 half-star value (Staff.quality_byte =
## stars x 2), NOT the 1..5 displayed star count. A ★★★ scout is quality 6 and therefore
## caps at 40 — which is exactly the result count the 2026-07-18 witness frame 81 shows
## (its 18px slider is floor(94 x 8 / 40)), so the cap is confirmed by a live frame and
## not only by the disassembly.
##   1.0★ 20 · 1.5★ 25 · 2.0★ 30 · 2.5★ 35 · 3.0★ 40 · 3.5★ 45 · 4.0★ 50 · 4.5★ 55 · 5.0★ 60
static func scout_cap(quality_byte: int) -> int:
	return (maxi(0, quality_byte) + 2) * 5

## OURS, not the binary's — the six per-attribute "at least" filters the SCOUT screen's
## extra panel adds (docs/SPEC_scout_attribute_search.md, owner-approved 2026-07-25).
## They are exactly Training.TRAINABLE, so the searchable set equals the improvable set.
## The original has NO per-attribute criterion; labels are the PLAYER INFORMATION card's.
const SCOUT_ATTR_FILTERS := [["PO", "HANDLING"], ["PA", "PASSING"], ["RM", "DRIBBLING"],
	["RG", "HEADING"], ["EN", "TACKLING"], ["TI", "SHOOTING"]]
## 30..95 in steps of 5 (14 stops); index -1 = off. OURS.
const SCOUT_ATTR_STOPS := [30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95]

## Arm a search. criteria: {pos:String(""|GK/DF/MF/FW), role:int(0=off, posFine),
## age_band/quality_band/price_band:int(-1=off, else band index into the SCOUT_*_BANDS
## tables), leagues:Array[String] (league ids)}. The screen enforces the witnessed
## validation (>=1 criteria toggle ON) before calling this. `foreign_clubs` =
## GameDB club dicts of any checked NON-own division (Career never reads
## GameDB itself — Main bridges): those divisions are static, so their matches
## freeze into the search now; the own division scans LIVE rosters at the due
## week (morale/contracts move until then).
## `foreign_clubs` = the clubs of the CHECKED divisions (the caller already filtered
## them, so their players clear the region gate by construction). `world_clubs` = the
## worldwide pool the E.U. / NON E.U. checkboxes open up; those players must clear the
## nationality gate. Both freeze at arm time.
func start_scout_search(criteria: Dictionary, foreign_clubs: Array = [],
		world_clubs: Array = []) -> void:
	var frozen: Array = []
	for club in foreign_clubs:
		var cd: Dictionary = club
		for p in cd.get("players", []):
			var row := _scout_row(p, int(cd.get("id", -1)), str(cd.get("name", "?")), cd, false)
			if _scout_match(row, p, criteria):
				frozen.append(row)
	for club in world_clubs:
		var wd: Dictionary = club
		for p in wd.get("players", []):
			if not _region_ok(p, false, criteria):
				continue
			var wrow := _scout_row(p, int(wd.get("id", -1)), str(wd.get("name", "?")), wd, false)
			if _scout_match(wrow, p, criteria):
				frozen.append(wrow)
	# PLAYERS WITHOUT TEAM: the out-of-contract pool, shown with no club.
	if bool(criteria.get("no_team", false)):
		for p in free_agents:
			var frow := _scout_row(p, -1, "-", {}, false)
			frow["fee"] = 0                       # a free agent costs no fee
			if _scout_match(frow, p, criteria):
				frozen.append(frow)
	scout_search = {"criteria": criteria.duplicate(true),
		"due_week": week + SCOUT_SEARCH_WEEKS, "frozen": frozen}

func scout_searching() -> bool:
	return not scout_search.is_empty()

## OURS (Mats, 2026-07-27): the INSTANT name search. Typing in the SCOUT panel's
## NAME box is a LOOKUP over the decoded database, not a scouting mission — no
## scout is dispatched, no other criterion is needed, and the hits land as NORMAL
## scout results (the `_scout_row` shape, so the standard tap-through to the
## offer card applies unchanged). The weeks-long mission machinery above is
## untouched and still owns every attribute / band search; a mission in flight
## keeps ticking and overwrites these rows when it lands, exactly as it would
## overwrite an older mission's rows. No cap is applied — the scout's shortlist
## trim (`FUN_00575750`) belongs to missions; a lookup is bounded by
## INSTANT_NAME_ROWS instead, with the true count kept in `scout_found_total`.
## `static_clubs` = every GameDB club outside the live division (Career never
## reads GameDB — Main bridges, the `start_scout_search` precedent). Matches the
## folded surname OR the folded full rendered name, so "kluivert" and "patrick"
## both find him. Returns the match count, or -1 when the query folds to fewer
## than INSTANT_NAME_MIN characters (too broad to mean anything — results keep
## whatever they held).
const INSTANT_NAME_MIN := 2
const INSTANT_NAME_ROWS := 200

func instant_name_search(name_raw: String, static_clubs: Array = []) -> int:
	var want := fold_name(name_raw)
	if want.length() < INSTANT_NAME_MIN:
		return -1
	var rows: Array = []
	var total := 0
	for cid in rosters:                       # the live division first (own club excluded,
		if int(cid) == club_id:               # the mission scan's own rule)
			continue
		var cv := club_view(int(cid))
		for p in rosters[cid]:
			if _name_hit(p, want):
				total += 1
				if rows.size() < INSTANT_NAME_ROWS:
					rows.append(_scout_row(p, int(cid), str(club_names.get(int(cid), "?")), cv, true))
	for club in static_clubs:
		var cd: Dictionary = club
		for p in cd.get("players", []):
			if _name_hit(p, want):
				total += 1
				if rows.size() < INSTANT_NAME_ROWS:
					rows.append(_scout_row(p, int(cd.get("id", -1)), str(cd.get("name", "?")), cd, false))
	for p in free_agents:
		if _name_hit(p, want):
			total += 1
			if rows.size() < INSTANT_NAME_ROWS:
				var frow := _scout_row(p, -1, "-", {}, false)
				frow["fee"] = 0               # a free agent costs no fee
				rows.append(frow)
	scout_results = rows
	scout_found_total = total
	return total

## The lookup runs on every keystroke over ~9.5k names, so the folded keys are
## cached — `fold_name` walks the string char by char and would dominate a frame.
var _name_fold_cache := {}

func _name_hit(p: Dictionary, want: String) -> bool:
	if _fold_cached(str(p.get("name", ""))).contains(want):
		return true
	var legal := str(p.get("legalName", ""))
	return legal != "" and _fold_cached(legal).contains(want)

func _fold_cached(s: String) -> String:
	var v: Variant = _name_fold_cache.get(s)
	if v == null:
		v = fold_name(s)
		_name_fold_cache[s] = v
	return str(v)

func _tick_scout_search() -> void:
	if scout_search.is_empty():
		return
	if week < int(scout_search.get("due_week", 0)):
		return
	var found: Array = _scout_scan_own(scout_search.get("criteria", {}))
	found.append_array(scout_search.get("frozen", []))
	scout_found_total = found.size()
	scout_results = _scout_apply_cap(found)
	scout_search = {}
	# The witnessed hub alert (78) — raised by Main when the hub next shows.
	pending_alerts.append("The scout has finished his search.")
	_news("transfer", "The scout has finished his search.")

## The engine's own shortlist trim, `FUN_00575750` @0x5757e7-0x5758d4: if the match count
## exceeds `(quality_byte + 2) * 5` the resolver keeps that many by drawing UNIFORMLY AT
## RANDOM WITHOUT REPLACEMENT (`rand() * n >> 15` into the match array, retrying any slot
## it has already zeroed) and discards the rest. It is NOT "the best N" — a weak scout
## brings back fewer names, not worse ones, and the same criteria re-run give a different
## shortlist. That answers the "which 35?" question `docs/SPEC_ours_additions.md` left
## open: the binary picks at random, so nothing here is ours to choose.
## `scout_found_total` keeps the pre-trim count so the screen can say how many were cut.
func _scout_apply_cap(found: Array) -> Array:
	var scout := Staff.member_in_role(staff, Staff.SCOUT_ROLE)
	if scout.is_empty():
		return found      # no hired scout = no cap: the original's screen cannot arm a
		                  # search at all without one (witness 43), so a quality byte of 0
		                  # is a state the resolver never sees. Capping it at (0+2)*5 = 10
		                  # would be us inventing a rule for a case the game does not have.
	var cap := scout_cap(Staff.quality_byte(scout))
	if found.size() <= cap:
		return found
	var pool: Array = found.duplicate()
	var kept: Array = []
	var r := career_rng()   # S3: the ONE persisted career stream
	while kept.size() < cap and not pool.is_empty():
		kept.append(pool.pop_at(r.randi() % pool.size()))
	return kept

## Scan the manager's own division (live rosters, own club excluded) when it is
## among the checked leagues. The original's result order is un-RE'd
## (scout_screen_re.md) — this is the app's own scan order, documented.
func _scout_scan_own(criteria: Dictionary) -> Array:
	var out: Array = []
	var in_div: bool = criteria.get("leagues", []).has(league_id)
	# The four ENGLISH divisions are reached ONLY by their own checkboxes. E.U. / NON E.U.
	# do NOT open them: `FUN_005753e0` @0x575675 sends a player to the nationality gate only
	# when his club's division index (club+0x50) is >= 4, i.e. when the club is foreign.
	if not in_div:
		return out
	for cid in rosters:
		if int(cid) == club_id:
			continue
		var cv := club_view(int(cid))
		for p in rosters[cid]:
			if not _region_ok(p, in_div, criteria):
				continue
			var row := _scout_row(p, int(cid), str(club_names.get(int(cid), "?")), cv, true)
			if _scout_match(row, p, criteria):
				out.append(row)
	return out


# The game's OWN E.U. list, no longer a historical reconstruction. `FUN_0058d2f0` is a
# flat compare chain over the PAISES country code and returns 1 for exactly eighteen:
#   2 GERMANY · 5 AUSTRIA · 0x0c BELGIUM · 0x12 DENMARK · 0x13 SCOTLAND · 0x16 SPAIN ·
#   0x17 FINLAND · 0x18 FRANCE · 0x1a GREECE · 0x1b HOLLAND · 0x1e ENGLAND ·
#   0x1f REP. OF IRELAND · 0x20 NORTH. IRELAND · 0x24 ITALY · 0x26 LUXEMBOURG ·
#   0x2d WALES · 0x2f PORTUGAL · 0x35 SWEDEN
# (codes resolved through app/data/country_codes.json = DBDAT/PAISES.30). Disassembled
# 2026-07-25; the historical EU-15 + home-nations list this file used to carry turns out
# to be exactly that set, so the behaviour is unchanged and the provenance is now the
# binary. `EU_CODES` is the binary's own key — names are the PAISES spellings of it.
const EU_CODES := [2, 5, 12, 18, 19, 22, 23, 24, 26, 27, 30, 31, 32, 36, 38, 45, 47, 53]
const EU_NATIONS := {
	"ENGLAND": true, "SCOTLAND": true, "WALES": true, "NORTH. IRELAND": true,
	"REP. OF IRELAND": true, "FRANCE": true, "GERMANY": true, "ITALY": true,
	"SPAIN": true, "PORTUGAL": true, "HOLLAND": true, "BELGIUM": true,
	"LUXEMBOURG": true, "DENMARK": true, "SWEDEN": true, "FINLAND": true,
	"AUSTRIA": true, "GREECE": true,
}

static func nationality_is_eu(nat: String) -> bool:
	return EU_NATIONS.has(nat.strip_edges().to_upper())


## Does this player fall inside ANY of the search's checked REGIONS? Binary-exact since
## 2026-07-25 — the tail of `FUN_005753e0` (@0x575675) is a three-way, not an OR:
##   club id 0x26de (the no-club pseudo-club)  -> the PLAYERS WITHOUT TEAM toggle;
##   club division index (club+0x50) < 4       -> that ENGLISH division's own checkbox;
##   otherwise (a foreign club)                -> nationality: FUN_0058d2f0 picks the
##                                                E.U. PLAYERS or NON E.U. PLAYERS box.
## So E.U. / NON E.U. never reach an English club's players, and the division boxes never
## reach a foreign one. `in_div` is whether the player's club sits in a checked division.
func _region_ok(p: Dictionary, in_div: bool, criteria: Dictionary) -> bool:
	if in_div:
		return true
	var is_eu := nationality_is_eu(str(p.get("nationality", "")))
	if bool(criteria.get("eu", false)) and is_eu:
		return true
	if bool(criteria.get("non_eu", false)) and not is_eu:
		return true
	return false

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
		# the SCOUT rollover bar prints the full rendered name (p0241/p0279/p0283)
		"legalName": str(p.get("legalName", "")),
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
	# ROLE matches ANY of the player's SIX role slots, not just his primary one. The
	# resolver loops the six bytes at player +0x1d..+0x22 and accepts on the first hit
	# (`FUN_005753e0` @0x5754bc); +0x1d is `posFine` and +0x1e..+0x22 are the five
	# alternates the extractor exports as `posAlts` (tools/re/equipos_parse.py:159).
	var role := int(criteria.get("role", 0))
	if role > 0 and not _has_role(p, role):
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
	# ---- OURS from here down (docs/SPEC_scout_attribute_search.md) ----------------
	# The original has no name box and no per-attribute criterion. Both are additions,
	# approved 2026-07-25, and both are pure narrowing: with `name` empty and every
	# threshold off, this block cannot change a single result.
	var want := fold_name(str(criteria.get("name", "")))
	if want != "" and not fold_name(str(row.get("name", ""))).contains(want):
		return false
	var attr_min: Dictionary = criteria.get("attr_min", {})
	if not attr_min.is_empty():
		var a: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
		for code in attr_min:
			if int(a.get(code, 0)) < int(attr_min[code]):
				return false
	return true


## The 20 accented letters the shipped squads actually use, folded to ASCII. Counted over
## all 9,547 names in `game_db.json`: 635 carry one (a-acute 150, e-acute 134, i-acute 119,
## o-acute 64, o-umlaut 37, n-tilde 34 ...). Typing "cafu" has to find "Cafú".
const _FOLD := {
	"á": "a", "ä": "a", "è": "e", "é": "e", "ë": "e", "í": "i", "ï": "i", "ñ": "n",
	"ò": "o", "ó": "o", "ö": "o", "ú": "u", "ü": "u", "ç": "c", "ý": "y",
}

## Search key for a player name: lower-cased, accents folded, and every character that is
## not a letter or a digit dropped. OURS — the search box is ours, so its matching rule is
## too, and it is deliberately forgiving because the game's own name data is not tidy:
##   * TWO different apostrophes ship in the same database — "O'Neill" with an ASCII quote
##     (40 names) and "O´Connor" with an acute accent (15). Nobody can be expected to know
##     which a given Irishman got, so neither counts.
##   * 68 names carry double quotes around a nickname ('"Pancho" Guerrero'), 243 carry a
##     dot, 16 a hyphen.
## Dropping spaces too means "o neill", "oneill" and "O´Neill" are one key, and
## "pancho guerrero" finds '"Pancho" Guerrero'. It is a SUBSTRING test, not a fuzzy one:
## a misspelling ("guerro") still misses, by design — no invented near-matching.
static func fold_name(s: String) -> String:
	var out := ""
	for ch in s.to_lower():
		var c: String = _FOLD.get(ch, ch)
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
	return out


## Does the player hold `role` (a 1..18 posFine) in ANY of his six role slots?
func _has_role(p: Dictionary, role: int) -> bool:
	if int(p.get("posFine", 0)) == role:
		return true
	for alt in p.get("posAlts", []):
		if int(alt) == role:
			return true
	return false


## A season's youth turnover. The ONLY route into the academy is the YOUTH TEAM SCOUT
## and the only route out is PROMOTE — nothing in MANAGER.EXE adds or releases youth at
## the rollover, so neither does this (the old age-out + free crop were both ours, and
## the shipped 0x26e4 pool is 17-19 year olds who would have aged straight out of it).
## Everyone just gets a year older.
func _roll_youth(_rng: RandomNumberGenerator) -> void:
	for p in youth:
		p["age"] = int(p.get("age", Youth.INTAKE_AGE_LO)) + 1
	_ensure_wonderkid()           # season-rollover delivery of the gem (first 3 seasons; no-op after)


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
		rng = career_rng()   # S3: the ONE persisted career stream
	var start_year := 1996 + year
	var n := 0
	for e in _by_tier(Talent.due_catchup(pool, start_year, talents_used)):
		if _inject_talent(e, rng, start_year):
			n += 1
	return n


## A new arrival's dorsal. squad_number_re.md's per-club rule is witnessed: N°
## renders only when the club's WHOLE set is individuated (unique, all present),
## else the column is "-". A joiner arriving with no number (talent intake, youth
## promotion, any signing) would therefore flip an individuated club to dashes —
## so he takes the lowest free dorsal instead. On a pad club (no real, unique
## numbering) this changes nothing: the set stays non-individuated and renders
## "-" exactly as before. [Mats QA 2026-07-26: talents must look like the squad]
static func _assign_free_no(roster: Array, p: Dictionary) -> void:
	var v: Variant = p.get("squadNo")
	if v != null and int(v) > 0:
		return
	var used := {}
	for q in roster:
		var qv: Variant = q.get("squadNo")
		if qv != null and int(qv) > 0:
			used[int(qv)] = true
	p["squadNo"] = 0
	if used.is_empty():
		return                       # pad club: he pads too
	var n := 1
	while used.has(n):
		n += 1
	p["squadNo"] = n


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
		var senior := Talent.make_senior(e, rng, start_year, band_of(cid))
		_assign_free_no(rosters[cid], senior)
		rosters[cid].append(senior)
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
	var form_rng := career_rng()   # S3: the ONE persisted career stream
	Morale.ensure(p, form_rng)   # fresh dynamic form, like the season kickoff roll
	_assign_free_no(rosters[club_id], p)
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
	# Booked against the screen's own insurance lines rather than as one lump, so the
	# PER WEEK view reads the way the original's does.
	_post_income("INSURANCE GROUP 3", g3_gbp)
	_post_expense("PLAYERS' INSURANCE", prem_gbp)
	_post_expense("HOSPITALS", hosp_gbp - pay_gbp)
	# The insured-injured wage refund nets off PLAYERS' WAGE (+0x50 - +0x54 in the
	# binary's week record, docs/re/insurance_economy_re.md).
	_post_expense("PLAYERS' WAGE", -back_gbp)
	# The HOSPITALS section's three sub-rows (detail view, frame 012): gross bill,
	# group-2 payout, group-3 payout. pay3 is derived as pay - pay2 so the sub-rows
	# always sum EXACTLY to the canonical line, whatever the £-unit rounding did.
	var det := _rec_detail()
	det["wage_refund"] += back_gbp
	det["hosp_gross"] += hosp_gbp
	var pay2_gbp := int(float(pass_["payout2"]) / Insurance.UNIT)
	det["hosp_pay2"] += pay2_gbp
	det["hosp_pay3"] += pay_gbp - pay2_gbp


## The season-to-date insurance figures the FINANCES screen posts to its own
## PLAYERS' INSURANCE / HOSPITALS / INSURANCE GROUP 3 lines (and the PLAYERS'
## WAGE netting). Keys match FinanceScreen's ledger lookup.
func insurance_ledger() -> Dictionary:
	return {"premiums": ins_premiums, "hospitals": ins_hospitals,
		"wage_refund": ins_wage_refund, "group3_income": ins_group3_income}


# ---- the weekly books (REFRUN R5/R9/R16) ---------------------------------

## The week record currently accumulating (minted lazily so a loaded save is fine).
func _week_rec() -> Dictionary:
	if _wk.is_empty():
		_wk = FinanceModel.new_week_ledger(FinanceModel.finance_week(week + 1))
	return _wk

## The accumulating week's DETAIL sub-record (the INCOME / EXPENSES detail views' split
## of the canonical lines — see FinanceModel.new_ledger_detail).
func _rec_detail() -> Dictionary:
	var rec := _week_rec()
	if not rec.has("detail"):
		rec["detail"] = FinanceModel.new_ledger_detail()
	return rec["detail"]


## One competition-section cell of the detail record: bucket = the screen's own section
## ("league" / "domestic" / "euro" / "charity" / "supercup" / "intercontinental"),
## field = "TICKETS" / "SPONSORS" / "TELEVISION" / "POINTS".
func _detail_comp_add(bucket: String, field: String, amount: int) -> void:
	if amount == 0:
		return
	var comp: Dictionary = _rec_detail()["comp"]
	if not comp.has(bucket):
		comp[bucket] = {}
	comp[bucket][field] = int((comp[bucket] as Dictionary).get(field, 0)) + amount


## The detail section a _post_home_match competition key belongs to.
static func _comp_bucket(comp_key: String) -> String:
	if comp_key == "league":
		return "league"
	if comp_key == "charity_shield":
		return "charity"
	# The two domestic cups have their own proved-zero fee keys since s78; a `cup:` key is
	# still produced for any cup name outside those two.
	if comp_key in ["fa_cup", "coca_cola"] or comp_key.begins_with("cup:"):
		return "domestic"
	if comp_key == "supercup" or comp_key == "intercontinental":
		return comp_key
	return "euro"      # european_cup / uefa_cup / cup_winners_cup


## Prize / points money on the EUROPEAN CUP INCOME line. The detail views print that
## line as the euro section's POINTS row (frame 006), so every posting to it lands
## there — including the Charity Shield purse, which the summary already books on this
## line and which has no row of its own in the detail layout (its section carries only
## TICKETS / SPONSORS / TELEVISION), keeping the visible rows equal to the total.
func _post_euro_points(amount: int) -> void:
	_post_income("EUROPEAN CUP INCOME", amount)
	_detail_comp_add("euro", "POINTS", amount)


## Bank `amount` and book it against one of the screen's INCOME lines. Negative amounts
## are legal (a reversal) and simply reduce the line.
func _post_income(line: String, amount: int) -> void:
	if amount == 0:
		return
	var rec := _week_rec()
	rec["income"][line] = int(rec["income"].get(line, 0)) + amount
	cash += amount

## Pay `amount` and book it against one of the screen's EXPENSE lines. `amount` is the
## POSITIVE cost; cash falls by it.
func _post_expense(line: String, amount: int) -> void:
	if amount == 0:
		return
	var rec := _week_rec()
	rec["expense"][line] = int(rec["expense"].get(line, 0)) + amount
	cash -= amount

## Close the accumulating week: file it, run the running-at-a-loss counter, and start a
## fresh record. Called once per advance_week, after every posting for the week is in.
func _close_week_books() -> void:
	var rec := _week_rec()
	week_ledgers.append(rec)
	while week_ledgers.size() > FinanceModel.SEASON_WEEKS:
		week_ledgers.pop_front()
	_wk = {}
	cash_close = cash          # the LAST WEEK / CASH tile's stored figure
	_cash_close_ok = true
	# REFRUN R16, corrected 2026-07-26: the trigger is the BANK BALANCE below zero, not a
	# P&L-negative week. Three discriminating witnesses: (1) the whole 1997-98 refrun
	# season raised NO alert although every quiet away week closes wages-only negative;
	# (2) the alerts began W4 of 1998-99 after the summer spend and cleared on the Butt
	# sale (p0685/p0716_alert_box.png, wording the original's own); (3) the ledger-based
	# reading fired at week 1 of a career holding millions -- Mats, live report,
	# 2026-07-26 -- which the original does not do.
	if cash < 0:
		loss_weeks += 1
		# FUN_0057ee50: `%c` is 's' above one week and a SPACE at one, and the board's
		# patience drains at -5 reputation a week (+1 on every week back in the black).
		pending_alerts.append(LOSS_ALERT_MSG % [loss_weeks, " " if loss_weeks <= 1 else "s"])
		reputation = Manager.apply_delta(reputation, -5)
	else:
		if loss_weeks > 0:
			reputation = Manager.apply_delta(reputation, 1)
		loss_weeks = 0

## PLAYERS' BONUS on a home matchday. WITNESSED ONCE: £5,000 in Man Utd's week-29 ledger,
## the only home week captured line by line (REFRUN R9). The original's `Win bonus` string
## is a PER-PLAYER contract term (docs/re/finance_constants.md), so whether the £5,000 is a
## club-flat figure or that squad's bonuses summed is NOT settled -- and neither is whether
## it is conditional on the result. Flat per home matchday is the minimal reading of the
## one measurement; it is not a reversed constant.
const HOME_MATCH_BONUS := 5_000

## Book one HOME match: the turnstile take, the channelTV fee for that competition, and
## the players' bonus. This is the ONLY route by which money enters the club in a normal
## week -- an away week or a blank week books nothing (REFRUN R9).
##   comp_key indexes FinanceModel.TV_FEE; an unwitnessed competition pays 0 TV rather
##   than a guessed figure.
func _post_home_match(comp_key: String) -> void:
	var fin := _fin_summary()
	var gate := int(fin.get("match_gate", 0))
	# The LEAGUE fee is per-division (witnessed 2026-07-28: Premier GBP 90,000, First
	# Division GBP 45,000); every other competition keeps its own measured constant.
	var fee := FinanceModel.league_tv_fee(league_id) if comp_key == "league" \
		else FinanceModel.tv_fee(comp_key)
	_post_income("TICKETS", gate)
	_post_income("TELEVISION", fee)
	_post_expense("PLAYERS' BONUS", HOME_MATCH_BONUS)
	# The detail views split these by competition section (frame 006's own layout).
	var bucket := _comp_bucket(comp_key)
	_detail_comp_add(bucket, "TICKETS", gate)
	_detail_comp_add(bucket, "TELEVISION", fee)


## The league round's matchday income, if the manager's club was at home this week.
func _post_matchday_income(res: Dictionary) -> void:
	if res.is_empty() or not bool(res.get("manager_home", false)):
		return
	_post_home_match("league")


## Queue the channelTV card for the coming week's fixture, so the hub can raise it BEFORE
## the match the way the original does (an unprompted card over MANAGER MENU, witnessed
## Sat 7 Feb 1998 / Premier Week 27). Home fixtures only, and only for a competition whose
## fee is witnessed -- an unmeasured competition raises no card rather than a made-up one.
func _queue_channel_tv() -> void:
	pending_channel_tv = {}
	if week >= fixtures.size():
		return
	for m in fixtures[week]:
		if int(m[0]) == club_id:
			var fee := FinanceModel.league_tv_fee(league_id)
			if fee > 0:
				pending_channel_tv = {"fee": fee, "comp": "league"}
			return
		elif int(m[1]) == club_id:
			return


## Which European competition the club is IN this season, as the FINANCES summary's
## euro-income row names it: `"european_cup"` / `"cup_winners_cup"` / `"uefa_cup"`.
##
## The original's branch chain is `FUN_0050812e` @0x5081B0..0x50838F, and it is a
## THREE-arm ladder over two competition globals, not a two-way switch:
##
##     if ((*DAT_0066b1b4)->vt[0x48]() != 0)      -> `EUROPEAN CUP INCOME`  @0x659B0C
##     else if ((*DAT_0066b1b0)->vt[0x48]() != 0) -> `CUP WINNERS CUP INCOME` @0x659AF4
##     else                                       -> `U.E.F.A. CUP INCOME`  @0x659AE0
##
## so U.E.F.A. is the FALL-THROUGH, which is exactly why the parity run's non-European
## lower-club career (`orig/51_finance_season.png`) reads `U.E.F.A. CUP INCOME` while
## walkthrough frame 013 (Man Utd in the European Cup) reads `EUROPEAN CUP INCOME`.
## Membership is "entered this season" (`euro_seeds`, the domestic entrant list), so the
## row keeps naming the competition after a knockout — which is what an income row for
## the season has to do. Declared: the original's predicate is a virtual call this port
## cannot see through, so "entered" is the reading, not a decoded flag.
func euro_income_comp() -> String:
	for key in ["european_cup", "cup_winners_cup"]:
		if (euro_seeds.get(key, []) as Array).has(club_id):
			return key
	return "uefa_cup"


## The finished week records, oldest first (the PER WEEK stepper + the BALANCE chart).
func week_books() -> Array:
	return week_ledgers


## The RUNNING week's record — money already posted this week (a sale, works, a prize).
## The original's CURRENT WEEK tile and the stepper's live week read from it (walkthrough
## 004/006: the Cruyff sale shows under CURRENT WEEK before the week has closed). {} when
## nothing has been posted yet, exactly the state p0495 witnessed.
func live_week_book() -> Dictionary:
	return _wk


## Cash as it stood when the last completed week closed (the LAST WEEK / CASH tile).
## Falls back to deriving it off the live record for a save from before this was stored.
func cash_at_close() -> int:
	if _cash_close_ok:
		return cash_close
	return cash - FinanceModel.ledger_balance(_wk)

## One finished week record by its FINANCE week number, or {} if that week is not banked.
func week_book(fin_week: int) -> Dictionary:
	for rec in week_ledgers:
		if int((rec as Dictionary).get("week", -1)) == fin_week:
			return rec
	return {}


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


## Throw the whole hire market away and generate a fresh one — every role gets three
## NEW candidates with a new star spread.
##
## WITNESSED 2026-07-24 on the real game (Bolton W career, TOTAL level, PHYSIOTHERAPISTS
## list, nobody signed in between):
##   week 1  A. Burgess 2.5 £6,000 · R. Fields 2.0 £7,000 · N. Kelso 2.0 £5,000
##   week 3  F. Hallet  3.0 £18,000 · D. Todd 4.5 £35,000 · P. Horlicks 5.0 £47,000
##   week 4  G. Conner  1.0 £4,000  · E. Wragg 4.5 £42,000 · J. Preece 4.5 £42,000
## — three different men every time, and the star spread moves with them (which is why
## the owner's careers were stuck with 3-star coaches: the app generated the pool ONCE
## and only ever removed from it). Closing and reopening the screen inside the SAME week
## returns the identical list, so the roll happens on the week tick, not on open.
##
## Members already hired are untouched; a candidate the manager sacked back onto the
## market goes with the rest (the original keeps no such carry-over).
func _refresh_staff_pool(rng: RandomNumberGenerator) -> void:
	staff_pool = Staff.generate_pool(rng, staff_seq, STAFF_POOL_PER_ROLE)
	staff_seq += staff_pool.size()


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
	_post_expense("CANCELLATION", comp)
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

## The transfer-deadline countdown alerts. WITNESSED (REFRUN R10, frame p0524): the
## original raises a hub alert box two weeks out, and (owner) one week out, then shuts
## the window silently. Called once per week from advance_week, AFTER `week` has been
## incremented, so `deadline_weeks_left()` is the count the manager still has.
func _tick_transfer_deadline() -> void:
	var left := deadline_weeks_left()
	if not DEADLINE_WARN_WEEKS.has(left):
		return
	pending_alerts.append(DEADLINE_WARN_MSG % [left, "" if left == 1 else "s"])


## The 1-April warning (see SEASON_END_MSG / CONTRACT_WARN_MSG). The original tests
## today == 1 April inside its daily pass; this port is week-grained, so it fires on
## the week whose Sun..Sat span contains 1 April of the season's end year — the same
## week-resolution mapping every other dated tick uses. Date math is PMChrome's own
## anchor (week 1 == Sat 9 Aug of the start year, date_parts).
func _tick_contract_warning() -> void:
	if contract_warned or week < 1:
		return
	var start_year := 1997
	var parts := season.split("-")
	if parts.size() >= 1 and parts[0].is_valid_int():
		start_year = int(parts[0])
	var t0 := Time.get_unix_time_from_datetime_dict(
		{"year": start_year, "month": 8, "day": 9, "hour": 12, "minute": 0, "second": 0})
	var sat := int(t0) + (week - 1) * 7 * 86400
	var apr1 := int(Time.get_unix_time_from_datetime_dict(
		{"year": start_year + 1, "month": 4, "day": 1, "hour": 12, "minute": 0, "second": 0}))
	if apr1 <= sat - 7 * 86400 or apr1 > sat:
		return
	contract_warned = true
	var auto_renew := manager_level in ["trainer", "manager"]   # DAT_0066B1F4
	pending_alerts.append(SEASON_END_MSG if auto_renew else CONTRACT_WARN_MSG)


## R13 (witnessed): after the penultimate league round the original presents the
## FINAL tables of every division that has already completed its rounds — blank
## club plate, the division in the badge — BEFORE the last round is played (p0638:
## Third Division P=46, dated 2/5/1998, shown before the Premier's last match).
## Lowest tier first (they finish first, R12). Never the manager's own division.
func _queue_division_finals() -> void:
	pending_division_finals = []
	for t in [4, 3, 2, 1]:
		if int(t) == tier:
			continue
		var dv: Dictionary = divisions.get(int(t), {})
		if dv.is_empty():
			continue
		if int(dv.get("played", 0)) >= int((dv.get("fixtures", []) as Array).size()):
			pending_division_finals.append(int(t))

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
		# MANAGER.EXE 0x261ba0 "%s%s has rejected your offer for %s." (club, player).
		return {"ok": false, "msg": "%s has rejected your offer for %s." % [seller_name, player.get("name", "?")]}
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
	_assign_free_no(rosters[club_id], player)
	rosters[club_id].append(player)
	_post_expense("SIGN PLAYER", offer)
	transfer_listed.erase(pid)
	shortlist.erase(pid)
	_log("You have signed %s from %s for £%s." % [player.get("name", "?"), seller_name, _money(offer)])
	# NEWS EXTRA MARKET feed (witnessed "Wilson signs for Barnsley for one season.").
	_news("transfer", "%s signs for %s for %s." % [
		player.get("name", "?"), club_name, TransferMarket.seasons_phrase(term)])
	# MANAGER.EXE 0x261a9c "You have signed %s %s%s." — witnessed 2026-07-24 rendering
	# "You have signed Barlow of Rochdale." (surname, then "of " + the selling club).
	return {"ok": true, "msg": "You have signed %s of %s." % [player.get("name", "?"), seller_name]}

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
		# MANAGER.EXE 0x261ba0 "%s%s has rejected your offer for %s."
		return {"ok": false, "msg": "%s has rejected your offer for %s." % [seller_name, player.get("name", "?")]}
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
	_assign_free_no(rosters[club_id], joined)
	rosters[club_id].append(joined)
	_post_expense("SIGN PLAYER", offer)
	external_signed[pid] = true
	_log("You have signed %s from %s for £%s." % [joined.get("name", "?"), seller_name, _money(offer)])
	_news("transfer", "%s signs for %s for %s." % [
		joined.get("name", "?"), club_name, TransferMarket.seasons_phrase(term)])
	# MANAGER.EXE 0x261a9c "You have signed %s %s%s." (witnessed "... Barlow of Rochdale.")
	return {"ok": true, "msg": "You have signed %s of %s." % [joined.get("name", "?"), seller_name]}

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
		rng = career_rng()   # S3: the ONE persisted career stream
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
	_assign_free_no(rosters[club_id], player)
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


# ---- MONTHLY AWARDS -------------------------------------------------------
# The two sheets are the original's own screens (frames 76 / 77, baked verbatim by
# tools/re/build_awards_chrome_from_frames.py). What the binary picks them BY is not
# reversed, so the selection below is OURS and says so — the same standing as the
# finance ledger's amounts (docs/re/finance_constants.md) and Career.sale_offers:
#   MANAGER OF THE MONTH  = the division's best record OVER THE MONTH (points won,
#       then goal difference, then goals for), computed from a table snapshot taken
#       at the month's first round. Nothing is fabricated: it is this career's own
#       played results.
#   PLAYER OF THE MONTH   = each club's top LEAGUE scorer over the same window, from
#       the scorer log the GOAL SCORERS chart already keeps; ties break on the
#       earlier goal. A club that did not score in the month prints no name (the
#       original always names one, but inventing a name would be worse).
# The month boundary itself is not modelled — it is the real calendar the header
# already runs on (PMChrome.date_parts, anchored at Sat 9 Aug 1997).

## Calendar month number of the round `w` (1-based week), on the header's own clock.
func _month_of_week(w: int) -> int:
	var start_year := 1997
	if season.length() >= 4 and season.substr(0, 4).is_valid_int():
		start_year = int(season.substr(0, 4))
	var t0 := Time.get_unix_time_from_datetime_dict(
		{"year": start_year, "month": 8, "day": 9, "hour": 12, "minute": 0, "second": 0})
	var d := Time.get_datetime_dict_from_unix_time(int(t0) + (maxi(w, 1) - 1) * 7 * 86400)
	return int(d.get("month", 8))


const MONTH_NAMES := ["", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
	"JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]


## Snapshot every division's table + scorer log at the first round of a month.
func _mark_month_start() -> void:
	var m := _month_of_week(week + 1)
	if not _month_mark.is_empty() and int(_month_mark.get("month", -1)) == m:
		return
	_month_mark = {"month": m, "tables": {}}
	_month_goal_mark = {}
	var tables: Dictionary = _month_mark["tables"]
	tables[tier] = _snapshot_table(table)
	_month_goal_mark[tier] = scorer_log.size()
	for t in divisions:
		tables[int(t)] = _snapshot_table(divisions[t]["table"])
		_month_goal_mark[int(t)] = (divisions[t]["scorers"] as Array).size()


static func _snapshot_table(tbl: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id in tbl:
		var r: Dictionary = tbl[id]
		out[int(id)] = [int(r.get("Pts", 0)), int(r.get("GF", 0)), int(r.get("GA", 0))]
	return out


## After the round lands: if the NEXT round falls in a new calendar month, the month
## just ended -> build both award sheets into `month_awards` for the UI to raise.
func _close_month_if_due() -> void:
	if _month_mark.is_empty():
		return
	var closing := int(_month_mark["month"])
	if _month_of_week(week + 1) == closing and not season_over():
		return
	var tables: Dictionary = _month_mark["tables"]
	var managers: Dictionary = {}
	var players: Dictionary = {}
	for t in tables:
		var tt := int(t)
		var tbl: Dictionary = table if tt == tier else (divisions[tt]["table"] as Dictionary)
		var nms: Dictionary = club_names if tt == tier else (divisions[tt]["names"] as Dictionary)
		var best_id := -1
		var best: Array = [-1, -999, -999]
		for id in tbl:
			var was: Array = (tables[tt] as Dictionary).get(int(id), [0, 0, 0])
			var now: Dictionary = tbl[id]
			var d := [int(now.get("Pts", 0)) - int(was[0]),
				(int(now.get("GF", 0)) - int(was[1])) - (int(now.get("GA", 0)) - int(was[2])),
				int(now.get("GF", 0)) - int(was[1])]
			if d[0] > best[0] or (d[0] == best[0] and d[1] > best[1]) \
					or (d[0] == best[0] and d[1] == best[1] and d[2] > best[2]):
				best = d
				best_id = int(id)
		if best_id != -1:
			managers[tt] = {"club_id": best_id, "club": str(nms.get(best_id, "?"))}
		# per-club top scorer of the month
		var log: Array = scorer_log if tt == tier else (divisions[tt]["scorers"] as Array)
		var from := int(_month_goal_mark.get(tt, 0))
		var tally: Dictionary = {}        # club -> {scorer -> goals}
		for i in range(from, log.size()):
			var g: Dictionary = log[i]
			var cid := int(g.get("club", -1))
			var nm := str(g.get("scorer", ""))
			if cid == -1 or nm == "":
				continue
			if not tally.has(cid):
				tally[cid] = {}
			(tally[cid] as Dictionary)[nm] = int((tally[cid] as Dictionary).get(nm, 0)) + 1
		var rows: Array = []
		var ids: Array = []
		for id in tbl:
			ids.append(int(id))
		ids.sort_custom(func(x, y): return str(nms.get(x, "")) < str(nms.get(y, "")))
		for id in ids:
			var top := ""
			var topn := 0
			for nm in (tally.get(id, {}) as Dictionary):
				if int((tally[id] as Dictionary)[nm]) > topn:
					topn = int((tally[id] as Dictionary)[nm])
					top = nm
			rows.append({"club_id": id, "club": str(nms.get(id, "?")), "player": top})
		players[tt] = rows
	month_awards = {"month": MONTH_NAMES[closing], "managers": managers, "players": players}
	_month_mark = {}
	_month_goal_mark = {}


# ---- the season-end award sheets (REFRUN R15 steps 5 and 7) ---------------
#
# GOAL SCORERS OF THE YEAR is EXACT: the original prints one name per division with his
# goal count in brackets ("Fowler (19)"), and the app already keeps the per-division
# league scorer ledger the GOAL SCORERS chart is drawn from, so this is the real number.
#
# MANAGERS OF THE YEAR is NOT. The reference run settled what the rule is NOT -- it is
# not "award the division's champion": the Second Division went to Wycombe W., who were
# Coca-Cola Cup FINALISTS rather than champions, and the Third to Peterborough, 3rd and
# promoted; a concurrent Bolton career gave the Premier to Wenger (Arsenal) while
# Blackburn R. were champions. The binary's own rule is un-reversed. So the PICK below is
# OURS, flagged exactly as MANAGERS OF THE MONTH's month-form pick is: a domestic-cup
# FINALIST from the division takes it (the one thing the witness positively shows counts),
# otherwise the club that finished furthest ABOVE its pre-season seed, ties on points.
# The SCREEN is the original's.

## Top league scorer of the season for tier `t`: {player, goals, club_id, club}, or {}.
func _top_scorer_of_year(t: int) -> Dictionary:
	var log: Array = scorer_log if t == tier else ((divisions.get(t, {}) as Dictionary).get("scorers", []) as Array)
	var nms: Dictionary = club_names if t == tier else names_for(t)
	var tally: Dictionary = {}       # "name@club" -> {n, club}
	for g in log:
		var gd: Dictionary = g
		var nm := str(gd.get("scorer", ""))
		var cid := int(gd.get("club", -1))
		if nm == "" or cid == -1:
			continue
		var k := "%s@%d" % [nm, cid]
		if not tally.has(k):
			tally[k] = {"n": 0, "club": cid, "name": nm}
		tally[k]["n"] = int(tally[k]["n"]) + 1
	var best: Dictionary = {}
	for k in tally:
		var row: Dictionary = tally[k]
		if best.is_empty() or int(row["n"]) > int(best["n"]):
			best = row
	if best.is_empty():
		return {}
	return {"player": str(best["name"]), "goals": int(best["n"]),
		"club_id": int(best["club"]), "club": str(nms.get(int(best["club"]), "?"))}


## Clubs from tier `t` that reached a domestic cup FINAL this season (winner + runner-up).
func _cup_finalists_in(t: int) -> Array:
	var out: Array = []
	var ids: Array = _pyramid_ids_by_tier(table.keys()).get(t, [])
	for b in [fa_cup, league_cup]:
		var rounds: Array = b.get("rounds", [])
		if rounds.is_empty():
			continue
		for tie in (rounds[-1] as Dictionary).get("ties", []):
			for k in ["home_id", "away_id"]:
				var cid := int((tie as Dictionary).get(k, -1))
				if cid != -1 and ids.has(cid) and not out.has(cid):
					out.append(cid)
	return out


## MANAGER OF THE YEAR pick for tier `t`: {club_id, club}, or {}. See the block comment --
## the rule is ours, the screen is the original's.
func _manager_of_year(t: int) -> Dictionary:
	var rows: Array = standings() if t == tier else standings_for(t)
	if rows.is_empty():
		return {}
	var nms: Dictionary = club_names if t == tier else names_for(t)
	var finalists := _cup_finalists_in(t)
	for i in rows.size():
		if finalists.has(int(rows[i].get("id", -1))):
			var fid := int(rows[i]["id"])
			return {"club_id": fid, "club": str(nms.get(fid, "?"))}
	var seeds: Dictionary = seed_pos if t == tier else ((divisions.get(t, {}) as Dictionary).get("seed", {}) as Dictionary)
	var best_id := -1
	var best_gain := -9999
	var best_pts := -1
	for i in rows.size():
		var cid := int(rows[i].get("id", -1))
		var gain := int(seeds.get(cid, i + 1)) - (i + 1)
		var pts := int(rows[i].get("Pts", 0))
		if gain > best_gain or (gain == best_gain and pts > best_pts):
			best_gain = gain
			best_pts = pts
			best_id = cid
	if best_id == -1:
		return {}
	return {"club_id": best_id, "club": str(nms.get(best_id, "?"))}


## The two season-end award sheets' data, keyed by tier 1..4:
##   {"scorers": {t: {player, goals, club_id, club}}, "managers": {t: {club_id, club}}}
func season_end_awards() -> Dictionary:
	var scorers: Dictionary = {}
	var managers: Dictionary = {}
	for t in [1, 2, 3, 4]:
		if t != tier and not divisions.has(t):
			continue
		var sc := _top_scorer_of_year(t)
		if not sc.is_empty():
			scorers[t] = sc
		var mg := _manager_of_year(t)
		if not mg.is_empty():
			managers[t] = mg
	return {"scorers": scorers, "managers": managers}


# ---- THE CHAMPIONSHIPS (REFRUN R15 step 3) --------------------------------
#
# The original's sheet carries EIGHT finals in eight fixed slots, and the slot -> trophy
# binding is baked into the chrome (each card's title and trophy bitmap are the frame's
# own pixels). So this returns the eight in the frame's own order, and a competition
# that was never played returns {} and leaves its card's cells empty -- which is what
# the original itself shows for a first season with no European history.
#
# The four RIGHT-hand slots are the ones the chrome gives a second score cell to, and
# they are exactly the four PM98 can decide over two legs or a replay.
const CHAMPIONSHIP_SLOTS := ["charity_shield", "european_cup", "cup_winners_cup",
	"intercontinental", "fa_cup", "uefa_cup", "supercup", "coca_cola"]

## The eight finals for THE CHAMPIONSHIPS, in the sheet's own slot order. Each entry is
## {} (not played) or {home: {club, club_id, scores, won}, away: {...}} -- the tie's own
## two sides in the sheet's own row order, with `scores` holding one figure per score
## cell the slot has and `won` driving the winner's black ink.
func season_end_championships() -> Array:
	var out: Array = []
	for comp in CHAMPIONSHIP_SLOTS:
		out.append(_championship_row(comp))
	return out


func _championship_row(comp: String) -> Dictionary:
	var tie: Dictionary = {}
	match comp:
		"charity_shield":
			tie = charity_shield
		"intercontinental":
			tie = intercontinental
		"supercup":
			tie = supercup
		"fa_cup":
			tie = _final_tie_of(fa_cup)
		"coca_cola":
			tie = _final_tie_of(league_cup)
		_:
			tie = _final_tie_of(euro.get(comp, {}) as Dictionary)
	if tie.is_empty() or int(tie.get("winner_id", -1)) == -1:
		return {}
	var w := int(tie["winner_id"])
	var home := int(tie.get("home_id", -1))
	var away := int(tie.get("away_id", -1))
	var scores := _tie_scores(tie)
	# HOME first, AWAY second -- the sheet lists the tie's own two sides in that order,
	# NOT winner-then-loser. Witnessed on the frame's U.E.F.A. CUP (Inter 0 above
	# Arsenal 1) and COCA-COLA CUP (Southampton above Arsenal), where the winner is the
	# SECOND row and is marked only by its ink.
	return {
		"home": {"club": _any_club_name(home), "club_id": home,
			"scores": scores["home"], "won": w == home},
		"away": {"club": _any_club_name(away), "club_id": away,
			"scores": scores["away"], "won": w == away},
	}


## A tie's goals per score cell, home side and away side. A two-legged tie fills BOTH
## cells (leg 1 then leg 2, always home-club-first as the tie records them); a single
## match fills only the first, and its second cell stays empty -- which is exactly what
## the frame's F.A. CUP and U.E.F.A. CUP cards show.
func _tie_scores(tie: Dictionary) -> Dictionary:
	if bool(tie.get("two_legged", false)):
		return {"home": [int(tie.get("leg1_hg", 0)), int(tie.get("leg2_hg", 0))],
			"away": [int(tie.get("leg1_ag", 0)), int(tie.get("leg2_ag", 0))]}
	return {"home": [int(tie.get("hg", 0))], "away": [int(tie.get("ag", 0))]}


# ---- END OF SEASON (REFRUN R15 step 4) ------------------------------------
#
# The four-division promoted / relegated overview. The PLATE COUNTS are the chrome's own
# (Premier 4 middle + 3 relegated, First 3 + 3, Second 3 + 4, Third 4 + none) and they
# agree line for line with the app's existing PYRAMID_ZONES, so nothing here is a new
# rule: the middle column is that division's promotion zone (its automatic places plus
# the play-off berth) and the right column its relegation zone.
#
# The PREMIER's middle column is headed U.E.F.A. CUP rather than PROMOTED and carries
# four clubs. The frame shows them as the four finishing BELOW the champion and the
# runner-up -- which is the only reading its own data supports -- so that is what this
# returns, and the mapping of those four onto actual berths stays with `UEFA_SPOTS`,
# which is a separate, already-shipped rule.
func season_end_overview() -> Dictionary:
	var out: Dictionary = {}
	for t in [1, 2, 3, 4]:
		if t != tier and not divisions.has(t):
			continue
		var rows: Array = standings() if t == tier else standings_for(t)
		if rows.is_empty():
			continue
		var nms: Dictionary = club_names if t == tier else names_for(t)
		var name_of := func(i: int) -> Dictionary:
			if i < 0 or i >= rows.size():
				return {}
			var cid := int((rows[i] as Dictionary).get("id", -1))
			return {"club_id": cid, "club": str(nms.get(cid, "?"))}
		var z: Dictionary = PYRAMID_ZONES.get(t, {"up": 0, "playoff": 0, "down": 0})
		var mid: Array = []
		if t == 1:
			# the four below the champion and the runner-up
			for i in range(2, 6):
				var r: Dictionary = name_of.call(i)
				if not r.is_empty():
					mid.append(r)
		else:
			var ups := int(z["up"]) + (1 if int(z["playoff"]) > 0 else 0)
			for i in ups:
				var r2: Dictionary = name_of.call(i)
				if not r2.is_empty():
					mid.append(r2)
		var rel: Array = []
		for i in range(rows.size() - int(z["down"]), rows.size()):
			var r3: Dictionary = name_of.call(i)
			if not r3.is_empty():
				rel.append(r3)
		out[t] = {"champion": name_of.call(0), "runner_up": name_of.call(1),
			"mid": mid, "relegated": rel}
	return out


# ---- PLAYERS OF THE YEAR (REFRUN R15 step 6) ------------------------------

## One award per CLUB, per division, in the sheet's own alphabetical club order --
## the same shape PLAYERS OF THE MONTH uses, over the WHOLE season's scorer ledger
## instead of one month's. A club that never scored shows an empty PLAYER cell rather
## than a borrowed name.
func players_of_year() -> Dictionary:
	var out: Dictionary = {}
	for t in [1, 2, 3, 4]:
		if t != tier and not divisions.has(t):
			continue
		var tbl: Dictionary = table if t == tier else ((divisions[t] as Dictionary)["table"] as Dictionary)
		var nms: Dictionary = club_names if t == tier else names_for(t)
		var log: Array = scorer_log if t == tier else ((divisions[t] as Dictionary)["scorers"] as Array)
		var tally: Dictionary = {}        # club -> {scorer -> goals}
		for g in log:
			var gd: Dictionary = g
			var cid := int(gd.get("club", -1))
			var nm := str(gd.get("scorer", ""))
			if cid == -1 or nm == "":
				continue
			if not tally.has(cid):
				tally[cid] = {}
			(tally[cid] as Dictionary)[nm] = int((tally[cid] as Dictionary).get(nm, 0)) + 1
		var ids: Array = []
		for id in tbl:
			ids.append(int(id))
		ids.sort_custom(func(x, y): return str(nms.get(x, "")) < str(nms.get(y, "")))
		var rows: Array = []
		for id in ids:
			var top := ""
			var topn := 0
			for nm2 in (tally.get(id, {}) as Dictionary):
				if int((tally[id] as Dictionary)[nm2]) > topn:
					topn = int((tally[id] as Dictionary)[nm2])
					top = nm2
			rows.append({"club_id": id, "club": str(nms.get(id, "?")), "player": top})
		out[t] = rows
	return out


## Queue the season's champion cards, in the ORIGINAL's own order (REFRUN R15 step 2):
## U.E.F.A. Cup -> Premier League -> Cup Winner's Cup -> F.A. Cup -> European Cup. Only
## competitions whose CARD ART is witnessed get a card -- the Premier League, European Cup
## and Cup Winners' Cup frames were never captured, so those are skipped rather than drawn
## on a borrowed trophy (CharityShieldScreen.has_card is the gate, on the UI side).
func queue_season_end_champion_cards() -> void:
	for entry in [["uefa_cup", euro.get("uefa_cup", {})],
			["cup_winners_cup", euro.get("cup_winners_cup", {})],
			["fa_cup", fa_cup], ["european_cup", euro.get("european_cup", {})],
			["coca_cola", league_cup]]:
		var comp := str(entry[0])
		var b: Dictionary = entry[1]
		if b.is_empty():
			continue
		var w := Cup.champion_id(b)
		if w == -1:
			continue
		var final_tie := _final_tie_of(b)
		var l := -1
		if int(final_tie.get("winner_id", -2)) == w:
			l = int(final_tie.get("loser_id", -1))
		pending_champion_cards.append({
			"comp": comp,
			"winner": {"club": _any_club_name(w), "club_id": w,
				"qualifier": champion_qualifier(final_tie)},
			"runner": {"club": _any_club_name(l), "club_id": l},
		})


## The deciding tie of a finished bracket ({} if it never got that far).
func _final_tie_of(b: Dictionary) -> Dictionary:
	var rounds: Array = b.get("rounds", [])
	if rounds.is_empty():
		return {}
	var ties: Array = (rounds[-1] as Dictionary).get("ties", [])
	return ties[0] if not ties.is_empty() else {}


## Send an injured squad player to the physiotherapist (the INJURIES screen's PHYS.
## "+" button). Mirrors FUN_00543080: refuses silently when he is already treated,
## when no PHYSIOTHERAPIST is hired, or when the physio's "N PLAYERS" capacity is
## already used up. Returns true when the injury was actually shortened.
func treat_injury(pid: int) -> bool:
	var p := _find_in(club_id, pid)
	if p.is_empty():
		return false
	var members := Staff.members_in_role(staff, Staff.PHYSIO)
	if members.is_empty():
		return false
	var physio: Dictionary = members[0]
	return Availability.treat(p, my_squad(), Staff.quality_byte(physio),
		Staff.physio_capacity(physio))


# ---- TACTICS role assignment ---------------------------------------------
# The TACTICS ROLE picker (FUN_0056a1d0 -> FUN_0056a560) writes the chosen role into
# `player[+0x18]`, the fine-position byte — that is the CURRENT role, distinct from the
# NATURAL role at `+0x1d` (`posNatural` here) and the five alternatives at `+0x1e..+0x22`
# (`posAlts`). The original lets you pick any of the 18 and paints the ones he can
# actually play; it does not refuse the others (see docs/re/positions_re.md).

## Assign `pid` the fine role `pos_fine` (1-based, the app's posFine space). Keeps the
## NATURAL role on first write so the picker can still paint it gold afterwards.
## Returns true when the squad player was found and changed.
func set_player_role(pid: int, pos_fine: int) -> bool:
	if pos_fine < 1 or pos_fine > 18:
		return false
	var p := _find_in(club_id, pid)
	if p.is_empty():
		return false
	if not p.has("posNatural"):
		p["posNatural"] = int(p.get("posFine", pos_fine))
	if int(p.get("posFine", 0)) == pos_fine:
		return false
	p["posFine"] = pos_fine
	return true


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

# ---- TRAINING focus (the AVER. panel's skill boxes) -----------------------

## Assign `pid` to the `focus` row, or clear it (focus == ""). Enforces the two caps the
## original enforces (witnessed 2026-07-24): a skill can hold at most its coach's TP
## players (refused SILENTLY), and the squad total can never exceed TOTAL TRAINABLE
## PLAYERS (refused with the alert "You can´t train any more players.").
## Returns {ok: bool, msg: String} — msg != "" means raise it as the PM98 alert box.
func set_training_focus(pid: int, focus: String) -> Dictionary:
	if focus == "":
		training_focus.erase(pid)
		return {"ok": true, "msg": ""}
	if not Training.FOCUS_ROWS.has(focus):
		return {"ok": false, "msg": ""}
	if _find_in(club_id, pid).is_empty():
		return {"ok": false, "msg": ""}
	var was := str(training_focus.get(pid, ""))
	if was == focus:
		training_focus.erase(pid)          # ticking the live box again clears it
		return {"ok": true, "msg": ""}
	if Training.FOCUS_SKILLS.has(focus):
		var tp := Training.skill_tp(staff, focus)
		if tp <= 0:
			return {"ok": false, "msg": ""}   # no coach for that skill: inert
		if Training.skill_load(training_focus, focus) >= tp:
			return {"ok": false, "msg": ""}   # that coach is full -> silent refusal
	if was == "" and training_focus.size() >= Training.total_trainable(staff):
		return {"ok": false, "msg": Training.FULL_MSG}
	training_focus[pid] = focus
	return {"ok": true, "msg": ""}


## AUTO: fill every hired coach up to his TP from the squad, best-suited first — keepers
## to HANDLING, forwards to SHOOTING, and so on (witnessed: AUTO tagged the three
## keepers HA and two forwards SH, TOTAL 5 of a 6-point bench). Clears any prior focus.
func auto_training_focus() -> void:
	training_focus = {}
	var cap := Training.total_trainable(staff)
	if cap <= 0:
		return
	for skill in Training.FOCUS_SKILLS:
		var tp := Training.skill_tp(staff, skill)
		if tp <= 0:
			continue
		var pool := my_squad().duplicate()
		pool.sort_custom(func(a, b): return Training.focus_fit(a, skill) > Training.focus_fit(b, skill))
		var placed := 0
		for p in pool:
			if placed >= tp or training_focus.size() >= cap:
				break
			var pid := int(p.get("id", -1))
			if pid < 0 or training_focus.has(pid) or Training.focus_fit(p, skill) <= 0.0:
				continue
			training_focus[pid] = skill
			placed += 1


## Drop focus rows for players who have left the squad (sold, released, retired).
func _prune_training_focus() -> void:
	for pid in training_focus.keys():
		if _find_in(club_id, int(pid)).is_empty():
			training_focus.erase(pid)


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
	_post_income("SALE + LOAN PLAY.", offer)
	# The detail view's named TRANSFERS row: `SALE Jordi Cruyff  £9,120,000` (frame 006).
	(_rec_detail()["sales"] as Array).append([str(player.get("name", "?")), offer])
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
	_post_expense("CANCELLATION", comp)
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
		rng = career_rng()   # S3: the ONE persisted career stream
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
	_capture_season_honours()    # OURS: the ledger, written while the brackets still stand
	if rng == null:
		rng = career_rng()   # S3: the ONE persisted career stream
	_return_loanees()   # loanees go home before contracts tick (never counted as your leavers)
	var leavers: Array = []
	var retirees: Array = []
	# S8, BINARY-EXACT (Retirement.gd / docs/re/retirement_re.md): the original's rollover
	# pass FUN_0058ac90 walks the squad with a RUNNING head count (the caller's iStack_28,
	# decremented every time the callee returns 0) and refuses to release anyone once that
	# count is under thirteen. Retirement is checked first and has no such floor.
	var squad_n := (rosters.get(club_id, []) as Array).size()
	for p in rosters.get(club_id, []):
		var yrs := int(p.get("contract_years", 1)) - 1
		p["contract_years"] = yrs
		p["age"] = int(p.get("age", 26)) + 1   # your squad ages a year (drives training)
		if yrs > 0:
			continue
		# 0x58acf2: out of contract. RETIREMENT is decided before anything else.
		if Retirement.retires(p):
			retirees.append(p)
			squad_n -= 1
			continue
		# 0x58aebd: the MATCHES-TO-RENEW clause (rec+0x1a) renews the deal by itself once
		# he has played its target this season -- player+0x86 != 0 && +0x86 <= +0x87.
		var clause_n := int(p.get("clause_matches", 0))
		if clause_n > 0 and int(p.get("clause_apps", 0)) >= clause_n:
			_renew_expiring(p, rng, "clause")
			continue
		# 0x58ae55: `cmp ecx,0xd / jb keep` -- never released below thirteen men.
		if squad_n < Retirement.SQUAD_FLOOR:
			_renew_expiring(p, rng, "squad")
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
			squad_n -= 1
	# A fresh batch of free agents for the new season; the manager's own released players join
	# the pool (you can re-sign one for nothing but a wage), capped so it never grows forever.
	free_agents = TransferMarket.generate_free_agents(rng, FREE_POOL_SIZE, free_seq)
	free_seq += FREE_POOL_SIZE
	# RETIREMENT at YOUR club (0x58ad08): the news line is the binary's own string, the man
	# leaves, and his record is reborn into the FREE PLAYERS pool (club 0x26de) as a new,
	# 10-12-years-younger player -- the original's ageing intake, which is what keeps the
	# world's population from collapsing as the veterans go.
	for p in retirees:
		rosters[club_id].erase(p)
		var line := Retirement.RETIRED_MSG % p.get("name", "?")
		_news("contract", line)
		_log(line)
		pending_alerts.append(line)
		free_seq += 1
		Retirement.rebirth(p, rng, free_seq)
		p["free_agent"] = true
		p["contract_years"] = 0
		p["value"] = 0            # 0x58ad9c: the managed-club branch zeroes the record's fee
		Contract.stamp_wage(p, my_band())
		free_agents.append(p)
	for p in leavers:
		rosters[club_id].erase(p)
		p["free_agent"] = true
		p["contract_years"] = 0
		p.erase("auto_renew")
		free_agents.append(p)
		_news("contract", "%s has left on a free (contract not renewed)." % p.get("name", "?"))
		_log("%s has left your club as his contract has not been renewed." % p.get("name", "?"))
		# WITNESSED (REFRUN R15 step 8): the original raises these as per-player hub
		# alerts at the new season's start, in exactly this wording.
		pending_alerts.append(
			"%s has left your club as his contract has not been renewed." % p.get("name", "?"))
	if free_agents.size() > FREE_POOL_CAP:
		free_agents = free_agents.slice(free_agents.size() - FREE_POOL_CAP)
	# AI contracts tick but auto-renew, so rival squads stay stable across years. Their
	# players age a year and the season resets like the manager's (#12 living league): bans
	# and injuries clear, the development carry-over zeroes, so the dev engine re-evaluates
	# each rival from his new age (young rivals keep climbing, veterans keep sliding).
	# S8: a rival's veterans DO retire, on the same FUN_0058b020 ages as yours -- and at an
	# UNMANAGED club the reborn record keeps its own club id (FUN_00576cd0's arg2 at
	# 0x58ad8b is player+0x14), so the man is replaced in place and the squad never shrinks.
	# That in-place rebirth is the whole reason the original's rival squads do not age into
	# a dead end; the port's auto-renew above stays as the (declared) stand-in for the rest
	# of FUN_0058ac90's unmanaged-club release ladder.
	for cid in rosters:
		if int(cid) == club_id:
			continue
		var rival_band := TransferMarket.stature_of(rosters[cid], tier)
		for p in rosters[cid]:
			p["contract_years"] = maxi(1, int(p.get("contract_years", 2)) - 1) + 1
			p["age"] = int(p.get("age", 26)) + 1
			if Retirement.retires(p):
				free_seq += 1
				Retirement.rebirth(p, rng, free_seq)
				p["contract_years"] = OfferRecord.seed_years(int(p.get("age", 20)), rng)
				p["contract_term"] = int(p["contract_years"])
				Contract.stamp_wage(p, rival_band)
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
	# The finance year is 52 weeks (FinanceModel.SEASON_WEEKS): a new season opens fresh
	# books and a cleared running-at-a-loss counter.
	week_ledgers = []
	_wk = {}
	loss_weeks = 0
	_reset_board_review()
	pending_channel_tv = {}
	pending_cup_draws = []
	pending_champion_cards = []
	sa_champion_id = -1
	# The STATISTICS store is per SEASON (its header reads "STATISTICS FOR <club>." with
	# no year, and a fresh career's table is all dashes), so it clears with the results.
	season_stats.clear()
	season_club_minutes.clear()
	season_club_mp.clear()
	results.clear()
	# The friendly slate clears for the new season; Main re-raises the preseason
	# picker on rollover (WITNESSED: REFRUN R15 step 8, p0664 — "Preseason for
	# Manchester Utd." opens 1998-99 with friendlies 31 Jul / 3 / 5 / 7 Aug 1998).
	# The old "season 2+ has no re-pick UI (un-walked)" note here was refuted by
	# that capture. [Mats QA 2026-07-26: preseason was gone in season two]
	preseason_rivals.clear()
	friendlies_played = 0
	friendly_results.clear()
	contract_warned = false
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
	fixtures = _league_fixtures(ids)
	_mint_domestic_cups(ids)                    # fresh 92-club cups each season
	_init_table(views)
	var league := {"id": league_id, "name": league_name, "tier": tier}
	# Season 2+: the witnessed labels are the 1997-98 board table; later seasons'
	# boards are un-witnessed, so the strength-ranked fallback applies ({} club).
	_set_objective({}, league, views, leagues)
	# club_view() carries no capacity, so without this the season-2+ projection
	# silently fell back to the tier-default table and ignored every completed
	# ground expansion.
	var cv2 := club_view(club_id)
	if stadium_capacity > 0:
		cv2["capacity"] = stadium_capacity
	var fin := FinanceModel.summary(cv2, tier)
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
	_arm_one_off_finals(sa_champion)


## FUN_0058ac90's KEEP branch (0x58af37 -> 0x58aff6): the expiring man is NOT released.
## The engine copies his freshly re-valued offer record (player+0x6c, re-seeded earlier in
## the same pass by FUN_00576cd0) onto him with `rec+0x19 = rec+0x18`, i.e. LEFT = the
## generated TERM, so the deal simply runs on for `OfferRecord.seed_years(age)` more years
## at the re-valued wage. `why` only picks the news wording.
func _renew_expiring(p: Dictionary, rng: RandomNumberGenerator, why: String) -> void:
	var term := OfferRecord.seed_years(int(p.get("age", 26)), rng)
	p["contract_years"] = term
	p["contract_term"] = term
	Contract.stamp_wage(p, my_band())
	p["clause_apps"] = 0
	if why == "clause":
		# .data 0x662d7c: "…has played his %s match this season, because of this his
		# contract will be automatically renewed."
		_news("contract", "%s has renewed his contract (matches clause)." % p.get("name", "?"))
		_log("%s has renewed his contract on the matches-to-renew clause (%d matches)."
			% [p.get("name", "?"), int(p.get("clause_matches", 0))])
	else:
		_news("contract", "%s has renewed his contract." % p.get("name", "?"))
		_log("%s stays: the squad is at the engine's %d-man floor (FUN_0058ac90 @0x58ae55)."
			% [p.get("name", "?"), Retirement.SQUAD_FLOOR])


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


# ---- OURS: the honours ledger (SPEC_ours_additions item 1) -----------------

## The eight trophies the original's own season-end backdrop shows, plus the
## Intercontinental Cup, which is not on the backdrop but does raise its own champion
## card (REFRUN R7) and so earns a line. Order = the backdrop's.
const HONOUR_COMPS := ["league", "fa_cup", "league_cup", "charity",
	"european_cup", "uefa_cup", "cup_winners_cup", "supercup", "intercont"]
const HONOUR_NAMES := {
	"league": "League", "fa_cup": "F.A. Cup", "league_cup": "Coca-Cola Cup",
	"charity": "Charity Shield", "european_cup": "European Cup",
	"uefa_cup": "U.E.F.A. Cup", "cup_winners_cup": "Cup Winner's Cup",
	"supercup": "European Supercup", "intercont": "Intercontinental Cup",
}

## Append the season that has just finished to `honours`. Called from advance_season
## AFTER _capture_honours / _capture_euro_honours (which is where the brackets are still
## intact) and BEFORE anything is rebuilt. Idempotent per season: re-running it for a
## season already on the ledger overwrites that entry rather than duplicating it.
func _capture_season_honours() -> void:
	var rec := {
		"season": season, "year": year,
		"club_id": club_id, "club_name": club_name, "league_name": league_name,
		"tier": tier, "pos": position(), "squad_size": rosters.get(club_id, []).size(),
		"objective": objective_text, "objective_pos": objective_pos,
		"objective_met": objective_met(),
		"sacked": sacked, "sack_reason": sack_reason,
		"comps": {},
	}
	var comps: Dictionary = rec["comps"]
	# The LEAGUE is the manager's own division, not necessarily the Premier League.
	var table := standings()
	if not table.is_empty():
		comps["league"] = {
			"winner_id": int(table[0].get("id", -1)),
			"winner_name": str(table[0].get("name", club_names.get(int(table[0].get("id", -1)), "?"))),
			"loser_id": int(table[1].get("id", -1)) if table.size() > 1 else -1,
			"loser_name": str(table[1].get("name", "")) if table.size() > 1 else "",
			"detail": "",
		}
	for pair in [["fa_cup", fa_cup], ["league_cup", league_cup],
			["european_cup", euro.get("european_cup", {})],
			["uefa_cup", euro.get("uefa_cup", {})],
			["cup_winners_cup", euro.get("cup_winners_cup", {})]]:
		var f := _final_of(pair[1])
		if not f.is_empty():
			comps[str(pair[0])] = f
	for pair2 in [["charity", charity_shield], ["supercup", supercup],
			["intercont", intercontinental]]:
		var t: Dictionary = pair2[1]
		if not t.is_empty() and int(t.get("winner_id", -1)) != -1:
			comps[str(pair2[0])] = {
				"winner_id": int(t.get("winner_id", -1)),
				"winner_name": _club_label(int(t.get("winner_id", -1))),
				"loser_id": int(t.get("loser_id", -1)),
				"loser_name": _club_label(int(t.get("loser_id", -1))),
				"detail": "on penalties" if str(t.get("decided", "")) == "pens" else "",
			}
	for i in honours.size():
		if str((honours[i] as Dictionary).get("season", "")) == season \
				and int((honours[i] as Dictionary).get("club_id", -2)) == club_id:
			honours[i] = rec
			return
	honours.append(rec)


## The winner and runner-up of a finished bracket, with the "(on penalties)" qualifier the
## champion cards carry (REFRUN R14). {} while the cup is still running.
func _final_of(b: Dictionary) -> Dictionary:
	var champ := Cup.champion_id(b)
	if champ == -1:
		return {}
	var rounds: Array = b.get("rounds", [])
	for i in range(rounds.size() - 1, -1, -1):
		for tie in (rounds[i] as Dictionary).get("ties", []):
			var t: Dictionary = tie
			if int(t.get("winner_id", -1)) != champ:
				continue
			return {
				"winner_id": champ, "winner_name": _club_label(champ),
				"loser_id": int(t.get("loser_id", -1)),
				"loser_name": _club_label(int(t.get("loser_id", -1))),
				"detail": "on penalties" if str(t.get("decided", "")) == "pens" else "",
			}
	return {"winner_id": champ, "winner_name": _club_label(champ),
		"loser_id": -1, "loser_name": "", "detail": ""}


## A club's display name from whichever store holds it (own division, then the European
## name cache). "?" rather than a guess when neither does.
func _club_label(cid: int) -> String:
	if cid < 0:
		return ""
	if int(cid) == club_id:
		return club_name
	if club_names.has(cid):
		return str(club_names[cid])
	if euro_names.has(cid):
		return str(euro_names[cid])
	return "?"


## The manager's own honours, folded across every season on the ledger:
## {comp_key: {"won": [season, ...], "runner_up": [season, ...]}}. Screens read this.
func honours_board() -> Dictionary:
	var out := {}
	for e in honours:
		var rec: Dictionary = e
		var cid := int(rec.get("club_id", -1))
		var comps: Dictionary = rec.get("comps", {})
		for key in HONOUR_COMPS:
			var c: Dictionary = comps.get(key, {})
			if c.is_empty():
				continue
			var slot: Dictionary = out.get(key, {"won": [], "runner_up": []})
			if int(c.get("winner_id", -1)) == cid:
				(slot["won"] as Array).append({"season": str(rec.get("season", "")),
					"club": str(rec.get("club_name", "")), "detail": str(c.get("detail", ""))})
			elif int(c.get("loser_id", -1)) == cid:
				(slot["runner_up"] as Array).append({"season": str(rec.get("season", "")),
					"club": str(rec.get("club_name", "")), "detail": str(c.get("detail", ""))})
			out[key] = slot
	return out


## One row per season for the career resume: club, division, final position, the board's
## objective and whether it was met, the trophies lifted, and how the season ended.
func career_resume() -> Array:
	var rows: Array = []
	for e in honours:
		var rec: Dictionary = e
		var cid := int(rec.get("club_id", -1))
		var won: Array = []
		var comps: Dictionary = rec.get("comps", {})
		for key in HONOUR_COMPS:
			var c: Dictionary = comps.get(key, {})
			if not c.is_empty() and int(c.get("winner_id", -1)) == cid:
				won.append(str(HONOUR_NAMES.get(key, key)))
		var ended := ""
		if bool(rec.get("sacked", false)):
			ended = "sacked (%s)" % str(rec.get("sack_reason", ""))
		rows.append({
			"season": str(rec.get("season", "")),
			"club": str(rec.get("club_name", "")),
			"league": str(rec.get("league_name", "")),
			"pos": int(rec.get("pos", 0)),
			"objective": str(rec.get("objective", "")),
			"objective_met": bool(rec.get("objective_met", false)),
			"won": won,
			"ended": ended,
		})
	return rows


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
	var mom := fold_match_stats(res, h, a)
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
	_resolve_pending_bids(rng)   # the Shield is a CONTINUE too (see play_friendly)
	# The channelTV card fires for the Shield too, at £187,500 -- witnessed Sun 3 Aug 1997
	# (REFRUN R6, p0032_channel_tv.png) -- and the fee IS that week's TELEVISION line. It
	# is paid for BROADCASTING the match, so it lands whoever wins. No TICKETS: the Shield
	# is played at a neutral ground, and the original's gate for it was not captured.
	if h == club_id or a == club_id:
		_post_income("TELEVISION", FinanceModel.tv_fee("charity_shield"))
		_detail_comp_add("charity", "TELEVISION", FinanceModel.tv_fee("charity_shield"))
	var pens := " (on penalties)" if decided == "pens" else ""
	if winner == club_id:
		_post_euro_points(CHARITY_PRIZE)
		if club_names.has(winner) and club_names.has(loser):
			_news("cup", "%s have won the Charity Shield, beating %s%s." % [
				str(club_names[winner]), str(club_names[loser]), pens])
	elif club_names.has(winner) and club_names.has(loser):
		_news("cup", "Charity Shield: %s beat %s%s." % [
			str(club_names[winner]), str(club_names[loser]), pens])
	return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
		"manager_home": at_home, "goals": res.get("goals", []), "motm_pid": mom,
		"xi_home": my_xi if at_home else opp_xi, "xi_away": opp_xi if at_home else my_xi,
		"report": res.get("report"), "report_ht": res.get("report_ht"),
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
	if bag.size() < int(EURO_FIELD["cup_winners_cup"]) - UEFA_SPOTS:
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
		var need := int(EURO_FIELD[key]) - field.size()
		if cursor + need > bag.size():
			break                          # foreign pool exhausted; remaining comps skipped
		field += bag.slice(cursor, cursor + need)
		cursor += need
		var opts := {"name": str(EURO_OPTS[key]["name"]), "legs": 2,
			"two_legged_final": false, "label_scheme": "sequential",
			"qtr_label": "Quarter Finals", "prize_round": 0, "prize_winner": 0,
			# The European break — see EURO_TAIL_FRACS. Autumn rounds (or the six group
			# matchdays) inside EURO_HEAD_SPAN, then QF/SF/Final in March..May.
			"span_lo": EURO_HEAD_SPAN[0], "span_hi": EURO_HEAD_SPAN[1],
			"tail_fracs": EURO_TAIL_FRACS.duplicate()}
		# Only the European Cup runs a group phase: 24 clubs into six groups of four,
		# double round-robin (`Round 1`..`Round 6` under the original's `1/8 FINALS`
		# header), then the six winners plus the two best runners-up into the quarter
		# finals. The U.E.F.A. Cup and Cup Winners' Cup are straight knockouts.
		if key == "european_cup":
			opts["group_stage"] = EURO_GROUPS.duplicate()
		euro[key] = Cup.create(field, fixtures.size(), opts)
		if field.has(club_id):
			_post_euro_points(EURO_ENTRY)
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
	_arm_one_off_finals(sa_champion)


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
	euro_winner_uefa = -1
	euro_winner_ratings = {}
	euro_winner_names = {}
	if euro.is_empty():
		return
	euro_winner_cup = Cup.champion_id(euro.get("european_cup", {}))
	euro_winner_cwc = Cup.champion_id(euro.get("cup_winners_cup", {}))
	euro_winner_uefa = Cup.champion_id(euro.get("uefa_cup", {}))
	for id in [euro_winner_cup, euro_winner_cwc, euro_winner_uefa]:
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
## caller supplies from game_db; approximated by the strongest South American club).
##
## The Supercup is a TWO-LEGGED tie, the Cup Winners' Cup holder at home first -- the
## original's own screen shows `1ST LEG MATCH` at the CWC winner's ground and `2ND LEG
## MATCH` at the European Cup winner's (1997-98: Camp Nou then Westfalen, for Borussia D.
## v F.C. Barcelona), `docs/re/euro_supercup_screen_re.md`. The Intercontinental stays a
## single neutral match in Tokyo (level -> penalties), which is what its screen shows.
## No-op until a first European season has produced winners. Pays the manager a documented
## prize + a news line if his club is in.
func _arm_one_off_finals(sa_champion: Dictionary) -> void:
	supercup = {}
	intercontinental = {}
	sa_champion_id = -1
	if euro_winner_cup == -1 or sa_champion.is_empty():
		return
	var sid := int(sa_champion.get("id", -1))
	if sid == -1 or sid == euro_winner_cup:
		return
	# Freeze the Libertadores holder's rating + name the same way the European winners are
	# frozen, so the December fixture is playable long after the caller's club dict is gone.
	euro_winner_ratings[sid] = MatchEngine.team_ratings(sa_champion)
	euro_winner_names[sid] = str(sa_champion.get("name", "?"))
	sa_champion_id = sid


## Ratings resolver for the frozen winners-of-winners field.
func _winner_ratings_fn() -> Callable:
	return func(id: int) -> Dictionary:
		if euro_winner_ratings.has(int(id)):
			var r: Dictionary = (euro_winner_ratings[int(id)] as Dictionary).duplicate()
			r["name"] = str(euro_winner_names.get(int(id), "?"))
			return r
		return _ratings_for(int(id))


## The two winners-of-winners finals, each on the date the ORIGINAL plays it. Neither is a
## curtain-raiser -- REFRUN R7 and R11 both caught the port red-handed there:
##   * INTERCONTINENTAL CUP -- raised in the FIRST DECEMBER WEEK of 1997 (the real fixture
##     was 2 December 1997), as a champion card: Borussia D. (Scala) over Cruzeiro (Weber).
##   * EUROPEAN SUPERCUP -- raised in MARCH, the week of Sunday 8 March 1998, also as a
##     champion card, and over two legs: F.C. Barcelona 2|1 Borussia D. 0|3.
## Month is read off the app's own calendar (_month_of_week), so both land in the right
## month whatever the season's week count is. Called once per week from advance_week.
func _tick_one_off_finals(rng: RandomNumberGenerator) -> void:
	if euro_winner_cup == -1:
		return
	var mon := _month_of_week(week)
	var r_fn := _winner_ratings_fn()
	# December: the Intercontinental Cup, one neutral match in Tokyo (level -> penalties).
	if intercontinental.is_empty() and mon == 12 and sa_champion_id != -1:
		var t2 := Cup.single_neutral_match(rng, euro_winner_cup, sa_champion_id, r_fn)
		t2["season"] = season
		intercontinental = t2
		_post_one_off_tv(t2, "intercontinental")
		_record_supercup_news(t2, "Intercontinental Cup", INTERCONTINENTAL_PRIZE)
		_queue_champion_card("intercontinental", "INTERCONTINENTAL CUP", t2)
	# March: the European Supercup, two legs, the Cup Winners' Cup holder hosting the first.
	if supercup.is_empty() and mon == 3 and euro_winner_cwc != -1 and euro_winner_cwc != euro_winner_cup:
		var tie := Cup.two_leg_tie(rng, euro_winner_cwc, euro_winner_cup, r_fn)
		tie["season"] = season
		tie["euro_cup_id"] = euro_winner_cup     # first-named on TEAMS IN CHAMPIONSHIPS
		tie["cwc_id"] = euro_winner_cwc
		supercup = tie
		_post_one_off_tv(tie, "supercup")
		_record_supercup_news(tie, "European Supercup", SUPERCUP_PRIZE)
		_queue_champion_card("supercup", "EUROPEAN SUPERCUP", tie)


## The channelTV fee for a winners-of-winners final, booked exactly the way the Charity
## Shield's already is and for the same source-read reason: the `SCEUR` and `INTER`
## competition classes each write `club+0x290` for BOTH sides of the tie, gated only on
## `club+0x5c != 0xffff` (the managed club) -- `0x463dc0`/`0x463de6`/`0x463ee4`/`0x463f06`
## for the Supercup at £375,000 and `0x43275d`/`0x432768` for the Intercontinental at
## £187,500 (`docs/re/channeltv_fee_re.md`). TELEVISION only: no TICKETS, because the
## Intercontinental is played at a neutral ground and the Supercup's gate was never
## captured -- the same declared limit the Shield carries.
func _post_one_off_tv(tie: Dictionary, comp_key: String) -> void:
	var ids := [int(tie.get("home_id", -1)), int(tie.get("away_id", -1)),
		int(tie.get("winner_id", -1)), int(tie.get("loser_id", -1))]
	if not ids.has(club_id):
		return
	var fee := FinanceModel.tv_fee(comp_key)
	_post_income("TELEVISION", fee)
	_detail_comp_add(_comp_bucket(comp_key), "TELEVISION", fee)


## Queue one CAMPEON card for the hub. `comp` keys the card art; the winner's club name
## takes the original's own result QUALIFIER when the tie was not settled in normal time --
## witnessed as `Lyon (on penalties)` on the U.E.F.A. CUP CHAMPION card (REFRUN R14), so
## the card's name field is "%s%s" % [club, qualifier], not just the club.
func _queue_champion_card(comp: String, _title: String, tie: Dictionary) -> void:
	var w := int(tie.get("winner_id", -1))
	var l := int(tie.get("loser_id", -1))
	if w == -1:
		return
	pending_champion_cards.append({
		"comp": comp,
		"winner": {"club": _any_club_name(w), "club_id": w,
			"qualifier": champion_qualifier(tie)},
		"runner": {"club": _any_club_name(l), "club_id": l},
	})


## The original's result qualifier appended to a champion's club name. Penalties is the
## only one witnessed (`Lyon (on penalties)`); every other decider prints nothing.
static func champion_qualifier(tie: Dictionary) -> String:
	return " (on penalties)" if str(tie.get("decided", "")) == "pens" else ""


## All English club ids the domestic cups are contested over, keyed by tier: the manager's
## own live division plus every other division the pyramid holds.
func _pyramid_ids_by_tier(div_ids: Array) -> Dictionary:
	var by_tier: Dictionary = {tier: div_ids.duplicate()}
	for t in divisions:
		by_tier[int(t)] = ((divisions[int(t)] as Dictionary).get("ids", []) as Array).duplicate()
	return by_tier


## Mint this season's F.A. Cup + Coca-Cola Cup over the whole pyramid, with the Premier
## clubs held back to Round 3 (see PREMIER_ENTRY_ROUND). A career with no pyramid context
## (a legacy save, or a side-loaded single-division database) falls back to the manager's
## own division, which is what the app did everywhere before.
func _mint_domestic_cups(div_ids: Array) -> void:
	var by_tier := _pyramid_ids_by_tier(div_ids)
	var top: Array = by_tier.get(1, [])
	var rest: Array = []
	for t in by_tier:
		if int(t) == 1:
			continue
		for v in by_tier[t]:
			if not rest.has(int(v)):
				rest.append(int(v))
	if rest.is_empty() or top.is_empty():
		fa_cup = Cup.create(div_ids, fixtures.size(), FA_CUP_OPTS)
		league_cup = Cup.create(div_ids, fixtures.size(), LEAGUE_CUP_OPTS)
		return
	var entry := {"round": PREMIER_ENTRY_ROUND, "ids": top}
	var fa: Dictionary = FA_CUP_OPTS.duplicate(true)
	fa["late_entry"] = entry
	var lc: Dictionary = LEAGUE_CUP_OPTS.duplicate(true)
	lc["late_entry"] = entry
	fa_cup = Cup.create(rest, fixtures.size(), fa)
	league_cup = Cup.create(rest, fixtures.size(), lc)


## A club's display name from any of the stores this career keeps.
func _any_club_name(id: int) -> String:
	if club_names.has(int(id)):
		return str(club_names[int(id)])
	if euro_winner_names.has(int(id)):
		return str(euro_winner_names[int(id)])
	# A pyramid club from another division: the cups now span all 92 (REFRUN R1).
	for t in divisions:
		var nm: Dictionary = (divisions[int(t)] as Dictionary).get("names", {})
		if nm.has(int(id)):
			return str(nm[int(id)])
	if _div_clubs.has(int(id)):
		return str((_div_clubs[int(id)] as Dictionary).get("name", "?"))
	return str(euro_names.get(int(id), "?"))


## Bank the manager's prize (if his club lifted it) + a news line for a one-off final.
func _record_supercup_news(tie: Dictionary, comp: String, prize: int) -> void:
	var w := int(tie["winner_id"])
	var l := int(tie["loser_id"])
	var wn := str(euro_winner_names.get(w, club_names.get(w, "?")))
	var ln := str(euro_winner_names.get(l, club_names.get(l, "?")))
	var pens := " (on penalties)" if tie.get("decided", "") == "pens" else ""
	if w == club_id:
		# Ours, not the binary's -- but a winners-of-winners final is UEFA/FIFA money, so
		# it posts to the ledger's own EUROPEAN CUP INCOME line rather than out of thin air.
		_post_euro_points(prize)
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
	# The binary's own test: this card's seats + (capacity + headroom) >= 150,000 disables
	# the card, so the refusal is `>=` on the SUM, not `>` on the capacity alone.
	if cat == "seats" and stadium_capacity + stadium_headroom + _pending_seats() \
			+ int(effect.get("added", 0)) >= MAX_STADIUM:
		return false
	for w in works:
		if str(w.get("cat")) == cat and int(w.get("key", -1)) == key:
			return false                 # that item is already under construction
	_post_expense("REFORM GROUND", cost)
	# The detail view's GROUND IMPROVEMENTS split: cat maps 1:1 onto the frame's
	# SEATS / CAR PARK / FACILITIES / EXTRAS rows (frame 008/012, EXTRAS = services).
	var gnd: Dictionary = _rec_detail()["ground"]
	gnd[cat] = int(gnd.get(cat, 0)) + cost
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


# The original's own completion messages, verbatim from MANAGER.EXE's message-pointer
# table at 0x662cec..0x662cf8 (one entry per GROUND category, in this order). They are
# raised as the modal "PREMIER MANAGER 98" box on the hub, like every other queued
# career alert — the owner-reported "no text box when ground works are complete".
# Note the capacity line reads "OF your stadium", the other three "AT your stadium".
const WORKS_DONE_MSG := {
	"seats": "The works to increase the capacity\nof your stadium has finished.",     # 0x6639d8
	"carpark": "The works to improve the parking\nat your stadium has finished.",      # 0x663998
	"facility": "The works to improve the facilities\nat your stadium has finished.",  # 0x663954
	"service": "The works to extend the services\nat your stadium has finished.",      # 0x663914
}


func _complete_work(w: Dictionary) -> void:
	var eff: Dictionary = w.get("effect", {})
	var cat := str(w.get("cat"))
	match cat:
		"seats":
			stadium_capacity = mini(MAX_STADIUM - stadium_headroom, stadium_capacity + int(eff.get("added", 0)))
			_news("stadium", "Ground expansion complete: capacity now %s." % _grp(stadium_capacity))
		"carpark":
			var q := int(w.get("key", 0))
			if q >= 0 and q < car_park_levels.size():
				car_park_levels[q] = mini(CAR_PARK_MAX_LEVEL, int(car_park_levels[q]) + 1)
			_news("stadium", "Car park works complete: %s." % w.get("label", ""))
		_:  # facility / service
			ground_grades["%s:%d" % [cat, int(w.get("key", 0))]] = int(eff.get("grade", 1))
			_news("stadium", "%s works complete." % w.get("label", ""))
	if WORKS_DONE_MSG.has(cat):
		pending_alerts.append(str(WORKS_DONE_MSG[cat]))


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


## The managed club's full finance ledger (the FINANCES screen's own numbers) — public
## so the FULL TIME read-out can bill this match's gate and sponsor rows off it.
func finance_summary() -> Dictionary:
	return _fin_summary()


## Set the board-controlled match ticket price and refresh the weekly finance projection.
func set_ticket_price(p: float) -> void:
	ticket_price = maxf(0.5, p)
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
	_post_income("PUBLICITY", amount)
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
		"gate": gate, "boards": boards, "ticket": float(fin["ticket_price"]),
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
		"man_marking": man_marking, "marking_lines": marking_lines,
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
		"stadium_capacity": stadium_capacity, "stadium_headroom": stadium_headroom, "works": works,
		"car_park_levels": car_park_levels, "ground_grades": ground_grades,
		"ticket_price": ticket_price, "board_price": board_price,
		"boards_sold_season": boards_sold_season,
		"transfer_listed": listed, "sale_offers": offers,
		"shortlist": shortlist, "transfer_log": transfer_log,
		"offers_left": offers_left, "news_log": news_log,
		"training_intensity": training_intensity, "training_focus": _str_keyed(training_focus),
		"youth": youth,
		"youth_seq": youth_seq, "youth_search": youth_search, "youth_found": youth_found,
		"youth_caps": youth_caps,
		"career_rng_state": (str(_career_rng.state) if _career_rng != null else career_rng_state),
		"scout_search": scout_search, "scout_results": scout_results,
		"scout_found_total": scout_found_total,
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
		"month_awards": month_awards, "month_mark": _month_mark,
		"month_goal_mark": _str_keyed(_month_goal_mark),
		"euro": euro, "euro_ratings": _str_keyed(euro_ratings),
		"euro_names": _str_keyed(euro_names),
		"week_ledgers": week_ledgers, "loss_weeks": loss_weeks,
		"board_sack_flag": board_sack_flag, "board_reviewed": board_reviewed,
		"board_below_at": _str_keyed(_below_at), "board_pos_at": _str_keyed(_pos_at),
		"week_open": _wk, "cash_close": cash_close, "cash_close_ok": _cash_close_ok,
		"contract_warned": contract_warned,
		"pending_champion_cards": pending_champion_cards, "sa_champion_id": sa_champion_id,
		"pending_channel_tv": pending_channel_tv,
		"pending_division_finals": pending_division_finals,
		"euro_winner_cup": euro_winner_cup, "euro_winner_cwc": euro_winner_cwc,
		"euro_winner_uefa": euro_winner_uefa,
		"euro_winner_ratings": _str_keyed(euro_winner_ratings),
		"euro_winner_names": _str_keyed(euro_winner_names),
		"supercup": supercup, "intercontinental": intercontinental,
		"reputation": reputation, "manager_history": manager_history,
		"honours": honours,
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

## In-place repair of a player dict carrying STORED nulls: a JSON null survives
## get(k, fallback), so `int(p.get("posFine", 0))` aborts the whole enclosing draw
## call in a debug build. Talent.gd wrote such nulls until 2026-07-26; this heals
## every roster/free-agent/youth dict on load so an in-flight career recovers
## without a restart. Missing keys (regen youth / free-pool dicts) heal the same way.
static func _heal_nulls(p: Dictionary) -> void:
	if p.get("posFine") == null or int(p.get("posFine", 0)) <= 0:
		p["posFine"] = int({"GK": 1, "DF": 4, "MF": 10, "FW": 9}.get(str(p.get("pos", "MF")), 10))
	if p.get("squadNo") == null:
		p["squadNo"] = 0
	if p.get("posAlts") == null:
		p["posAlts"] = []
	if p.get("heightCm") == null:
		p["heightCm"] = 175
	if p.get("weightKg") == null:
		p["weightKg"] = 78


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
	c.man_marking = d.get("man_marking", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	c.marking_lines = d.get("marking_lines", [79, 198])
	c.tier = int(d.get("tier", 1))
	# Pre-stadium-works saves load with capacity 0 (-> GameDB default via Main) + no works.
	c.stadium_capacity = int(d.get("stadium_capacity", 0))
	# Pre-headroom saves load 0; Main heals both from GameDB on career load.
	c.stadium_headroom = int(d.get("stadium_headroom", 0))
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
	c.ticket_price = float(d.get("ticket_price", 0.0))
	c.board_price = int(d.get("board_price", 0))
	c.boards_sold_season = bool(d.get("boards_sold_season", false))
	c.shortlist = []
	for v in d.get("shortlist", []):
		c.shortlist.append(int(v))
	c.transfer_log = d.get("transfer_log", [])
	c.offers_left = int(d.get("offers_left", OFFERS_PER_WEEK))
	c.news_log = d.get("news_log", [])
	c.training_intensity = d.get("training_intensity", Training.DEFAULT_INTENSITY)
	c.training_focus = {}
	for k in d.get("training_focus", {}):
		c.training_focus[int(k)] = str(d["training_focus"][k])
	# Saves from before youth existed load with an empty academy (inert); the first
	# rollover scouts a crop in. youth_seq defaults above the senior id space.
	c.youth = d.get("youth", [])
	c.youth_seq = int(d.get("youth_seq", YOUTH_ID_BASE))
	c.youth_search = d.get("youth_search", {})
	c.youth_found = d.get("youth_found", [])
	c.youth_caps = d.get("youth_caps", {})
	c.career_rng_state = str(d.get("career_rng_state", ""))
	# Pre-SCOUT-screen saves load idle with no results (inert until a search).
	c.scout_search = d.get("scout_search", {})
	c.scout_results = d.get("scout_results", [])
	c.scout_found_total = int(d.get("scout_found_total", c.scout_results.size()))
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
	# MONTHLY AWARDS: the pending sheets + the running month's table snapshot. JSON
	# turns every key into a String, so the tier-keyed maps are re-integered here
	# (an old save simply starts the next month fresh).
	c.month_awards = d.get("month_awards", {})
	c._month_mark = {}
	var mm: Dictionary = d.get("month_mark", {})
	if mm.has("month") and mm.has("tables"):
		var tabs: Dictionary = {}
		for k in (mm["tables"] as Dictionary):
			var one: Dictionary = {}
			for cid in (mm["tables"][k] as Dictionary):
				one[int(cid)] = mm["tables"][k][cid]
			tabs[int(k)] = one
		c._month_mark = {"month": int(mm["month"]), "tables": tabs}
	c._month_goal_mark = {}
	for k in d.get("month_goal_mark", {}):
		c._month_goal_mark[int(k)] = int(d["month_goal_mark"][k])
	c.euro_seeds = d.get("euro_seeds", {})
	c.euro = d.get("euro", {})
	c.euro_ratings = {}
	for k in d.get("euro_ratings", {}):
		c.euro_ratings[int(k)] = d["euro_ratings"][k]
	c.euro_names = {}
	for k in d.get("euro_names", {}):
		c.euro_names[int(k)] = d["euro_names"][k]
	c.week_ledgers = d.get("week_ledgers", [])
	# The RUNNING week's record was not saved before 2026-07-27; a legacy save loses its
	# in-week postings from the books (the bank kept them), which the detail views show
	# as £0 exactly as a fresh original save would.
	c._wk = d.get("week_open", {})
	c.cash_close = int(d.get("cash_close", 0))
	c._cash_close_ok = bool(d.get("cash_close_ok", false))
	c.pending_champion_cards = d.get("pending_champion_cards", [])
	c.sa_champion_id = int(d.get("sa_champion_id", -1))
	c.loss_weeks = int(d.get("loss_weeks", 0))
	c.board_sack_flag = int(d.get("board_sack_flag", 0))
	c.board_reviewed = d.get("board_reviewed", [])
	c._below_at = _int_keyed(d.get("board_below_at", {}))
	c._pos_at = _int_keyed(d.get("board_pos_at", {}))
	c.contract_warned = bool(d.get("contract_warned", false))
	c.pending_channel_tv = d.get("pending_channel_tv", {})
	for t in d.get("pending_division_finals", []):
		c.pending_division_finals.append(int(t))
	c.euro_winner_cup = int(d.get("euro_winner_cup", -1))
	c.euro_winner_uefa = int(d.get("euro_winner_uefa", -1))
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
	c.honours = d.get("honours", [])
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
	# Heal a save written while Talent.gd emitted stored nulls (posFine/squadNo —
	# a stored null survives get(k, fallback) and aborts int(null) in every draw
	# path: the season-2 "stars but no position or roles" rows, Mats QA 2026-07-26).
	for k in c.rosters:
		for p in c.rosters[k]:
			_heal_nulls(p)
	for p in c.free_agents:
		_heal_nulls(p)
	for p in c.youth:
		_heal_nulls(p)
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
