class_name Career
extends RefCounted
## A persistent manager career: one club, played week-by-week through a league
## season, with an accumulating table, finances and a board objective. Saves to
## user://career.json. This is the spine the rest of the management layer hangs off.
##
## Kept free of the GameDB autoload (callers pass clubs/leagues in) so it stays
## unit-testable headless.

const SAVE_PATH := "user://career.json"

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


# ---- construction --------------------------------------------------------

## Start a fresh career managing `club` in its division. `league` is the league
## dict, `league_clubs` the full club dicts in that division, `leagues` all leagues.
static func create(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array) -> Career:
	var c := Career.new()
	c.club_id = int(club["id"])
	c.club_name = club.get("name", "?")
	c.league_id = str(league.get("id", ""))
	c.league_name = league.get("name", "League")
	var ids: Array = []
	for lc in league_clubs:
		ids.append(int(lc["id"]))
	c.fixtures = SeasonSim.fixtures(ids)
	c._init_table(league_clubs)
	c._set_objective(league, league_clubs, leagues)
	var fin := FinanceModel.summary(club, FinanceModel.tier_of(club, leagues))
	c.weekly_net = int(fin["weekly_balance"])
	c.cash = int(fin.get("total_income", 0)) / 4   # opening balance ~ a quarter's income
	c.tactics = Tactics.auto_pick(club, Tactics.DEFAULT_FORMATION).to_dict()
	return c


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

## Play the current round: simulate every fixture, update the table, accrue cash.
## `clubs_by_id` maps id -> full club dict (for ratings). Returns the manager's
## result {home_id, away_id, hg, ag, manager_home} or {} on a bye / season end.
func advance_week(rng: RandomNumberGenerator, clubs_by_id: Dictionary) -> Dictionary:
	if season_over():
		return {}
	var ratings: Dictionary = {}
	var manager_res: Dictionary = {}
	for m in fixtures[week]:
		var h := int(m[0])
		var a := int(m[1])
		if not ratings.has(h):
			ratings[h] = _ratings_for(h, clubs_by_id)
		if not ratings.has(a):
			ratings[a] = _ratings_for(a, clubs_by_id)
		var res := MatchEngine.simulate(rng, ratings[h], ratings[a])
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		_apply(table[h], hg, ag)
		_apply(table[a], ag, hg)
		if h == club_id or a == club_id:
			manager_res = {"home_id": h, "away_id": a, "hg": hg, "ag": ag, "manager_home": h == club_id}
	cash += weekly_net
	week += 1
	if not manager_res.is_empty():
		results.append({
			"week": week, "opp_id": manager_res["away_id"] if manager_res["manager_home"] else manager_res["home_id"],
			"home": manager_res["manager_home"], "hg": manager_res["hg"], "ag": manager_res["ag"],
		})
	if season_over():
		finished = true
	return manager_res


## Ratings for a club: the manager's own club uses the chosen XI + shape; every
## other (AI) club uses the auto-best-XI. This is the S6 hook -- who you pick and
## the formation you play now drive your own results.
func _ratings_for(id: int, clubs_by_id: Dictionary) -> Dictionary:
	var club: Dictionary = clubs_by_id.get(id, {})
	if id == club_id and not tactics.is_empty():
		return Tactics.from_dict(tactics).ratings(club)
	return MatchEngine.team_ratings(club)


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


# ---- persistence ---------------------------------------------------------

func to_dict() -> Dictionary:
	# JSON keys must be strings; store the table with string keys.
	var tbl: Dictionary = {}
	for id in table:
		tbl[str(id)] = table[id]
	return {
		"club_id": club_id, "club_name": club_name, "league_id": league_id,
		"league_name": league_name, "season": season, "year": year, "week": week,
		"fixtures": fixtures, "table": tbl, "results": results, "cash": cash,
		"weekly_net": weekly_net, "objective_pos": objective_pos,
		"objective_text": objective_text, "finished": finished,
		"tactics": tactics,
	}

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
	c.table = {}
	for k in d.get("table", {}):
		c.table[int(k)] = d["table"][k]
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
