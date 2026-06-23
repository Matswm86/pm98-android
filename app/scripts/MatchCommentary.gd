class_name MatchCommentary
extends RefCounted
## Minute-by-minute match commentary feed for PM98.
##
## The scoreline comes from MatchEngine.simulate() (the calibrated per-shot model,
## validated by tests/test_engine.gd) — this layer only TIMES and NARRATES events,
## it never changes the result. Goals are assigned to scorers + minutes; ancillary
## events (corners, fouls, cards, offsides, saves) are sprinkled at plausible rates.
##
## The commentary TEMPLATES below are lifted verbatim from MANAGER.EXE (the PCF5
## engine's English match-event strings, VAs cited) and map 1:1 to the verified
## event-type enum decoded in docs/re/match_engine_re.md (GOAL=7, own-goal=8,
## yellow=3, sent-off=4/5, pen=9/10, offside=0xb, corner=0xc/0xd, shots 0x10-0x17).
## What is OURS (and calibrated, not ported): the per-match event RATES and the
## minute distribution — PM98 derives those from its positional sim, which we abstract.

# Verbatim from MANAGER.EXE .rdata. "%s (%s)" = player name + club name.
const T_GOAL := "Goal by %s (%s)"                 # 0x65cf00
const T_OWN_GOAL := "Goal by %s (%s) (o.g.)"      # 0x65cee8
const T_YELLOW := "Yellow card: %s (%s)"          # 0x65cf38
const T_SENT_OFF := "%s (%s) sent off"            # 0x65cf24
const T_OFFSIDE := "%s (%s) offside"              # 0x65cea8
const T_FOUL := "Foul by %s (%s)"                 # 0x65cf68
const T_SAVED := "Shot saved by %s (%s)"          # 0x65ce54
const T_HEADER := "Header by %s (%s)"             # 0x65cdb8
const T_CORNER := "Corner taken by %s"            # 0x65ce84
const T_PEN_TAKEN := "Penalty taken by %s"        # 0x65ceb8
const T_PEN_CONCEDED := "Penalty conceded by %s (%s)"  # 0x65cecc
const T_FREE_KICK := "Free kick taken by %s"      # 0x65cf50
const T_POST := "Shot rebounded off the post"     # 0x65cd34 (leading spaces trimmed)
const T_CROSSBAR := "Shot hit crossbar"           # 0x65cd54
const P_KICK_OFF := "KICK OFF"                    # 0x65cc54
const P_HALF_TIME := "HALF TIME"                  # 0x6563b0
const P_FULL_TIME := "FULL TIME"                  # 0x656364

# Per-match ancillary event rates (ours, tuned to real-football aggregates).
const RATE_CORNERS := 10
const RATE_FOULS := 11
const RATE_YELLOWS := 3
const RATE_OFFSIDES := 4
const RATE_NEAR_MISSES := 3   # post / crossbar / save flavour lines


static func _outfield(club: Dictionary) -> Array:
	var out: Array = []
	for p in club.get("players", []):
		if not p.get("isGK"):
			out.append(p)
	if out.is_empty():
		out = club.get("players", [])
	return out


## Weighted random player: weight = sum of the given attr codes (+1 floor).
static func _pick(prng: MatchEngine.Pm98Rng, players: Array, codes: Array) -> Dictionary:
	if players.is_empty():
		return {"name": "?"}
	var weights: Array = []
	var total := 0
	for p in players:
		var av: Variant = p.get("attrs", {})       # some players have attrs == null
		var attrs: Dictionary = av if av is Dictionary else {}
		var w := 1
		for c in codes:
			w += int(attrs.get(c, 0))
		weights.append(w)
		total += w
	var roll := prng.next() % maxi(1, total)
	var acc := 0
	for i in players.size():
		acc += int(weights[i])
		if roll < acc:
			return players[i]
	return players[players.size() - 1]


static func _keeper(club: Dictionary) -> String:
	var best := ""
	var best_po := -1
	for p in club.get("players", []):
		if p.get("isGK"):
			var po := int(p.get("attrs", {}).get("PO", 0))
			if po > best_po:
				best_po = po
				best = p["name"]
	if best == "":
		var ps: Array = club.get("players", [])
		best = ps[0]["name"] if not ps.is_empty() else "the keeper"
	return best


static func _minute(prng: MatchEngine.Pm98Rng) -> int:
	return 1 + (prng.next() % 90)


## Build the full timed commentary for one fixture, computing the scoreline from
## the engine. home/away are full club dicts (with "players" and "name").
## Returns {home_goals, away_goals, lines:[{minute:int, side:int(-1 phase/0 home/1 away), text}]}.
static func timeline(rng: RandomNumberGenerator, home: Dictionary, away: Dictionary) -> Dictionary:
	var hr := MatchEngine.team_ratings(home)
	var ar := MatchEngine.team_ratings(away)
	var res := MatchSim.simulate(rng, hr, ar, MatchSim.xi_of(home), MatchSim.xi_of(away), \
			int(home.get("id", 0)), int(away.get("id", 0)))
	return narrate(rng, home, away, int(res["home_goals"]), int(res["away_goals"]), res.get("goals", []))


## Narrate a PREDETERMINED scoreline (used by career mode so the league table and
## the highlights feed always agree). Same output shape as timeline().
##
## `engine_goals` (from MatchSim.simulate's `goals`) names the players the stat engine
## actually picked + the minutes it scored at; when present the GOAL lines come straight
## from it instead of re-rolling here, so the feed and the scoreline agree on WHO scored.
## Empty (legacy fallback / no XI) -> the goals are re-rolled by finishing weight as before.
static func narrate(rng: RandomNumberGenerator, home: Dictionary, away: Dictionary, home_goals: int, away_goals: int, engine_goals: Array = []) -> Dictionary:
	var prng := MatchEngine.Pm98Rng.new(rng.randi())
	var hp := _outfield(home)
	var ap := _outfield(away)
	var hn: String = home.get("name", "Home")
	var an: String = away.get("name", "Away")
	var events: Array = []   # {minute, side, text}

	if not engine_goals.is_empty():
		# The stat engine already chose the scorers + minutes -- narrate THOSE.
		for g in engine_goals:
			var nm := str((g as Dictionary).get("scorer", "?"))
			var club := hn if int((g as Dictionary).get("scorer_side", 0)) == 0 else an
			var tmpl := T_OWN_GOAL if bool((g as Dictionary).get("own_goal", false)) else T_GOAL
			events.append({"minute": int((g as Dictionary).get("minute", 1)),
				"side": int((g as Dictionary).get("side", 0)), "text": tmpl % [nm, club], "goal": true})
	else:
		# Legacy / no-XI fallback: scorer weighted by finishing (RM heading + TI shooting + CA).
		for _g in home_goals:
			var s := _pick(prng, hp, ["RM", "TI", "CA"])
			events.append({"minute": _minute(prng), "side": 0, "text": T_GOAL % [s.get("name", "?"), hn], "goal": true})
		for _g in away_goals:
			var s := _pick(prng, ap, ["RM", "TI", "CA"])
			events.append({"minute": _minute(prng), "side": 1, "text": T_GOAL % [s.get("name", "?"), an], "goal": true})

	# Ancillary events: alternate-ish between sides via the roll.
	var both := [[0, hp, hn], [1, ap, an]]
	_sprinkle(prng, events, both, RATE_YELLOWS, func(side, p, nm): return T_YELLOW % [p.get("name", "?"), nm], ["AG", "EN"])
	_sprinkle(prng, events, both, RATE_FOULS, func(side, p, nm): return T_FOUL % [p.get("name", "?"), nm], ["AG"])
	_sprinkle(prng, events, both, RATE_OFFSIDES, func(side, p, nm): return T_OFFSIDE % [p.get("name", "?"), nm], ["VE"])
	_sprinkle(prng, events, both, RATE_CORNERS, func(side, p, nm): return T_CORNER % p.get("name", "?"), ["PA"])

	# Saves name the DEFENDING keeper (side flips to the goalkeeper's team).
	var keepers := [[0, _keeper(home), hn], [1, _keeper(away), an]]
	for _i in RATE_NEAR_MISSES:
		var k: Array = keepers[prng.next() % 2]
		events.append({"minute": _minute(prng), "side": k[0], "text": T_SAVED % [k[1], k[2]]})

	events.sort_custom(func(a, b): return a["minute"] < b["minute"])

	# Stitch in phase markers.
	var lines: Array = [{"minute": 0, "side": -1, "text": "%s  -  %s  v  %s" % [P_KICK_OFF, hn, an]}]
	var half_done := false
	for e in events:
		if not half_done and e["minute"] > 45:
			lines.append({"minute": 45, "side": -1, "text": P_HALF_TIME})
			half_done = true
		lines.append(e)
	if not half_done:
		lines.append({"minute": 45, "side": -1, "text": P_HALF_TIME})
	lines.append({"minute": 90, "side": -1,
		"text": "%s  -  %s %d : %d %s" % [P_FULL_TIME, hn, home_goals, away_goals, an]})

	return {"home_goals": home_goals, "away_goals": away_goals, "lines": lines}


static func _sprinkle(prng: MatchEngine.Pm98Rng, events: Array, both: Array, count: int, fmt: Callable, codes: Array) -> void:
	for _i in count:
		var side_idx := prng.next() % 2
		var entry: Array = both[side_idx]
		var p := _pick(prng, entry[1], codes)
		events.append({"minute": _minute(prng), "side": entry[0], "text": fmt.call(entry[0], p, entry[2])})
