class_name SeasonSim
extends RefCounted
## Simulates a full division season from club squads and builds the league table.
## Double round-robin (home + away), 3/1/0 points, GD then GF tiebreaks.
## Uses MatchEngine for each fixture. Pure logic: runs in-app and headless.

# Promotion / relegation zones per English tier (1997-98 structure; playoff
# spots folded into the auto-promotion count for a single final table).
const ZONES := {
	1: {"promo": 0, "releg": 3},   # Premier League
	2: {"promo": 3, "releg": 3},   # Division One
	3: {"promo": 3, "releg": 4},   # Division Two
	4: {"promo": 4, "releg": 0},   # Division Three (no Conference modeled)
}


## Single round-robin schedule via the circle method.
## Returns Array[round], round = Array[[home_id, away_id]].
static func _round_robin(team_ids: Array) -> Array:
	var ids: Array = team_ids.duplicate()
	if ids.size() % 2 == 1:
		ids.append(-1)   # bye marker for odd club counts
	var n := ids.size()
	var half := n / 2
	var arr := ids.duplicate()
	var rounds: Array = []
	for r in range(n - 1):
		var round: Array = []
		for i in range(half):
			var a: int = arr[i]
			var b: int = arr[n - 1 - i]
			if a != -1 and b != -1:
				if r % 2 == 0:
					round.append([a, b])
				else:
					round.append([b, a])   # alternate venue across rounds
		rounds.append(round)
		# rotate all but the first slot one step
		var rest: Array = arr.slice(1)
		rest.push_front(rest.pop_back())
		arr = [arr[0]] + rest
	return rounds


## Full double round-robin (second half = first half with venues reversed).
static func fixtures(team_ids: Array) -> Array:
	var first := _round_robin(team_ids)
	var out: Array = first.duplicate()
	for round in first:
		var rev: Array = []
		for m in round:
			rev.append([m[1], m[0]])
		out.append(rev)
	return out


static func _apply(s: Dictionary, gf: int, ga: int) -> void:
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


static func _cmp(a: Dictionary, b: Dictionary) -> bool:
	if a["Pts"] != b["Pts"]:
		return a["Pts"] > b["Pts"]
	var gda: int = a["GF"] - a["GA"]
	var gdb: int = b["GF"] - b["GA"]
	if gda != gdb:
		return gda > gdb
	if a["GF"] != b["GF"]:
		return a["GF"] > b["GF"]
	return a["name"] < b["name"]


## Simulate a whole season for a set of club dicts.
## Returns {table: Array[row], fixtures: int} where each row has
## {id,name,P,W,D,L,GF,GA,GD,Pts} sorted into final standings.
static func simulate_season(rng: RandomNumberGenerator, clubs: Array) -> Dictionary:
	var ratings: Dictionary = {}
	var xis: Dictionary = {}
	var table: Dictionary = {}
	var ids: Array = []
	for c in clubs:
		var id := int(c["id"])
		ids.append(id)
		ratings[id] = MatchEngine.team_ratings(c)
		xis[id] = MatchSim.xi_of(c)
		table[id] = {
			"id": id, "name": ratings[id]["name"],
			"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "GD": 0, "Pts": 0,
		}
	var games := 0
	var home_wins := 0
	var draws := 0
	var away_wins := 0
	var goals := 0
	for round in fixtures(ids):
		for m in round:
			var h: int = m[0]
			var a: int = m[1]
			var res := MatchSim.simulate(rng, ratings[h], ratings[a], xis[h], xis[a], h, a)
			var hg: int = res["home_goals"]
			var ag: int = res["away_goals"]
			_apply(table[h], hg, ag)
			_apply(table[a], ag, hg)
			games += 1
			goals += hg + ag
			if hg > ag:
				home_wins += 1
			elif hg == ag:
				draws += 1
			else:
				away_wins += 1
	var rows: Array = table.values()
	for r in rows:
		r["GD"] = r["GF"] - r["GA"]
	rows.sort_custom(_cmp)
	return {
		"table": rows, "fixtures": games, "goals": goals,
		"home_wins": home_wins, "draws": draws, "away_wins": away_wins,
	}


## Marker for a standings position given the division tier: "P" promotion,
## "R" relegation, "" mid-table.
static func zone_marker(tier: int, position: int, total: int) -> String:
	var z: Dictionary = ZONES.get(tier, {"promo": 0, "releg": 0})
	if position < int(z["promo"]):
		return "P"
	if position >= total - int(z["releg"]):
		return "R"
	return ""
