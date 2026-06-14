class_name MatchEngine
extends RefCounted
## PM98 match engine (Phase 1, plausible v1).
##
## Turns two squads into a scoreline using the 10 decoded attributes.
##
## IMPORTANT: this is a *plausible* football model, NOT a port of the original
## PM98 match math. The original ratings/formulas live in DAT.PKF (the one
## genuinely LZ-packed region, not yet reverse-engineered). When that is cracked
## we tune toward it; until then this is a self-consistent model whose aggregate
## output (goals/game, home edge, points spread) is validated against real
## football ranges in tests/test_engine.gd. Do not claim it matches the original.
##
## Attribute codes (Spanish in the file) -> meaning:
##   VE pace · RE stamina · AG aggression · CA ability(quality) · RM heading/finishing
##   RG dribbling · PA passing · TI shooting · EN tackling · PO goalkeeping

# --- tunables (set in tests/test_engine.gd against real-football targets) -----
const BASE_HOME := 1.50   # expected home goals between evenly matched sides
const BASE_AWAY := 1.10   # expected away goals between evenly matched sides
const SCALE := 20.0       # attribute-gap -> goal-rate sensitivity (bigger = flatter)
const GK_WEIGHT := 0.35   # share of a side's defensive resistance from the keeper
const LAMBDA_CAP := 6.0   # safety clamp on expected goals

# Outfield attacking score weights (sum 1.0).
const _ATK := {"CA": 0.28, "RM": 0.18, "TI": 0.16, "RG": 0.16, "PA": 0.12, "VE": 0.10}
# Outfield defending score weights (sum 1.0).
const _DEF := {"EN": 0.34, "CA": 0.24, "AG": 0.18, "RE": 0.12, "VE": 0.12}

# League-average floor used when a club has too little rated data to field an XI
# (a handful of Div-3 fringe clubs have no decoded GK / sparse attr rows).
const _FLOOR_ATT := 50.0
const _FLOOR_DEF := 50.0
const _FLOOR_GK := 52.0


static func _score(attrs: Dictionary, weights: Dictionary) -> float:
	var s := 0.0
	for code in weights:
		s += float(attrs.get(code, 0)) * float(weights[code])
	return s


## Derive {att, def, gk, name} ratings for a club from its squad.
## Picks the strongest GK and the best 10 outfielders (by a balanced overall),
## then averages their attacking / defending scores. Robust to short or
## attr-sparse squads via league-average floors.
static func team_ratings(club: Dictionary) -> Dictionary:
	var players: Array = club.get("players", [])
	var outfield: Array = []   # [{atk, def, ovr}]
	var best_gk := -1.0
	for p in players:
		var attrs: Variant = p.get("attrs", {})
		if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
			continue   # no decoded attr row -> can't rate this player
		if p.get("isGK"):
			best_gk = max(best_gk, float(attrs.get("PO", 0)))
		else:
			var atk := _score(attrs, _ATK)
			var dfn := _score(attrs, _DEF)
			outfield.append({"atk": atk, "def": dfn, "ovr": 0.5 * atk + 0.5 * dfn})

	outfield.sort_custom(func(a, b): return a["ovr"] > b["ovr"])
	var xi: Array = outfield.slice(0, 10)   # best 10 outfielders

	var att := _FLOOR_ATT
	var dfn_team := _FLOOR_DEF
	if not xi.is_empty():
		var sa := 0.0
		var sd := 0.0
		for r in xi:
			sa += r["atk"]
			sd += r["def"]
		att = sa / xi.size()
		dfn_team = sd / xi.size()
		# thin XI (few rated outfielders) pulls toward the floor
		if xi.size() < 8:
			var w := xi.size() / 8.0
			att = att * w + _FLOOR_ATT * (1.0 - w)
			dfn_team = dfn_team * w + _FLOOR_DEF * (1.0 - w)

	var gk := best_gk if best_gk >= 0.0 else _FLOOR_GK
	return {"att": att, "def": dfn_team, "gk": gk, "name": club.get("name", "?")}


## Defensive resistance a side presents to the opponent: outfield defence + keeper.
static func _resistance(r: Dictionary) -> float:
	return (1.0 - GK_WEIGHT) * float(r["def"]) + GK_WEIGHT * float(r["gk"])


## Expected goals for a side with ratings `att_side` against `def_side`.
static func _expected(att_side: Dictionary, def_side: Dictionary, base: float) -> float:
	var gap: float = float(att_side["att"]) - _resistance(def_side)
	return clampf(base * exp(gap / SCALE), 0.05, LAMBDA_CAP)


## Knuth Poisson sampler (lambda is small here, so this is cheap).
static func _poisson(rng: RandomNumberGenerator, lam: float) -> int:
	if lam <= 0.0:
		return 0
	var l := exp(-lam)
	var k := 0
	var p := 1.0
	while p > l:
		k += 1
		p *= rng.randf()
	return k - 1


## Simulate one match. `home`/`away` are team_ratings() dicts.
## Returns {home_goals, away_goals, lambda_home, lambda_away}.
static func simulate(rng: RandomNumberGenerator, home: Dictionary, away: Dictionary) -> Dictionary:
	var lh := _expected(home, away, BASE_HOME)
	var la := _expected(away, home, BASE_AWAY)
	return {
		"home_goals": _poisson(rng, lh),
		"away_goals": _poisson(rng, la),
		"lambda_home": lh,
		"lambda_away": la,
	}
