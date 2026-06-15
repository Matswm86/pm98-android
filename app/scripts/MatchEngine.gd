class_name MatchEngine
extends RefCounted
## PM98 match engine (Phase 2: per-shot model, structurally derived from MANAGER.EXE).
##
## Turns two squads into a scoreline using the 10 decoded attributes.
##
## The original PM98 match result is an event-based positional simulation in
## MANAGER.EXE (.text ~0x58e000-0x5b4000): a per-tick driver (FUN_00598740)
## advances a 22-player ball-physics sim; a shot/tackle resolver (FUN_005aeda0)
## converts chances using player attributes + RNG rolls; a dispatcher
## (FUN_005966d0) emits GOAL=type7 / card / corner events onto a 16-byte event
## queue. Full RE map + verified addresses: docs/re/match_engine_re.md.
##
## FAITHFUL here (lifted from the binary, verified against bytes):
##   * PRNG = the Microsoft C LCG used throughout the sim (FUN_005ec250 @
##     0x5ec250): state = state*214013 + 2531011; roll = (state>>16) & 0x7FFF.
##     Probability gates in the binary are `(roll*N)>>15 < threshold`, a per-N
##     uniform compare. Pm98Rng below reproduces this exactly. (The *214013 is
##     strength-reduced to lea/shl/sub in the binary, which is why an earlier
##     byte-grep for 0x343FD found nothing and wrongly ruled out MSVC rand().)
##   * Scoring is per-SHOT Bernoulli resolution (not one scoreline draw): each
##     chance converts with a probability LINEAR in finishing skill, the shape
##     of FUN_005aeda0's outcome gates (e.g. permil threshold (skill+fwd*K)).
##
## ABSTRACTED (NOT a 1:1 port -- do not claim full fidelity):
##   * The positional ball physics that decides *how many* chances each side
##     gets. Chance VOLUME is modelled from the attack-vs-defence gap; the scale
##     and base conversion are calibrated to real-football aggregates (validated
##     in tests/test_engine.gd). The per-shot FORM is PM98's; the volume model
##     and the numeric constants are ours, tuned to the same output windows.
##
## Attribute codes (Spanish in the file) -> meaning:
##   VE pace · RE stamina · AG aggression · CA ability(quality) · RM heading/finishing
##   RG dribbling · PA passing · TI shooting · EN tackling · PO goalkeeping


## Microsoft C runtime LCG -- the exact PRNG in PM98's match sim (FUN_005ec250).
## Verified against MANAGER.EXE at 0x5ec250. GDScript ints are 64-bit so the
## multiply does not overflow before the 32-bit mask.
class Pm98Rng extends RefCounted:
	var state: int

	func _init(seed_: int) -> void:
		state = seed_ & 0xFFFFFFFF

	## One 15-bit draw in [0, 32767] -- identical to PM98's rand().
	func next() -> int:
		state = (state * 214013 + 2531011) & 0xFFFFFFFF
		return (state >> 16) & 0x7FFF

	## PM98's probability idiom `(rand()*1000)>>15 < permil`: true w.p. permil/1000.
	func chance_permil(permil: int) -> bool:
		return ((next() * 1000) >> 15) < permil


# --- tunables (set in tests/test_engine.gd against real-football targets) -----
# Per-shot model: chances ~ base + gap*slope, each converts at conv permil.
const BASE_SHOTS_HOME := 12.5   # chances for an evenly matched home side
const BASE_SHOTS_AWAY := 11.0   # chances for an evenly matched away side
const SHOT_SLOPE := 0.30        # extra chances per point of att-vs-defence gap
const SHOTS_MIN := 2            # floor on chances per side
const BASE_CONV_HOME := 118     # home conversion (permil) at zero gap
const BASE_CONV_AWAY := 102     # away conversion (permil) at zero gap
const CONV_SLOPE := 4.0         # conversion permil per point of gap
const CONV_LO := 25             # clamp: a hopeless chance still converts ~2.5%
const CONV_HI := 350            # clamp: even a sitter is not a certainty
const GK_WEIGHT := 0.35         # share of a side's defensive resistance from the keeper

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


## Public per-player attacking / defending scores (same weights team_ratings uses),
## so Tactics can rate a hand-picked XI on the identical scale.
static func atk_score(attrs: Dictionary) -> float:
	return _score(attrs, _ATK)

static func def_score(attrs: Dictionary) -> float:
	return _score(attrs, _DEF)


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


## Attack-vs-defence gap driving both chance volume and conversion for a side.
static func _gap(att_side: Dictionary, def_side: Dictionary) -> float:
	return float(att_side["att"]) - _resistance(def_side)


## Number of clear chances a side creates (PM98 abstracts these out of the
## positional sim; we model the count from the strength gap).
static func _chances(gap: float, base: float) -> int:
	return maxi(SHOTS_MIN, roundi(base + gap * SHOT_SLOPE))


## Per-shot conversion probability (permil) -- PM98's finishing gate is linear
## in skill; here the skill term is the att-vs-resistance gap off a venue base.
static func _conv_permil(gap: float, base: int) -> int:
	return clampi(roundi(base + gap * CONV_SLOPE), CONV_LO, CONV_HI)


## Resolve one side's goals: roll each chance through PM98's MSVC-LCG permil gate.
static func _resolve(prng: Pm98Rng, chances: int, conv: int) -> int:
	var goals := 0
	for _i in chances:
		if prng.chance_permil(conv):
			goals += 1
	return goals


## Simulate one match. `home`/`away` are team_ratings() dicts.
## Returns {home_goals, away_goals, shots_home, shots_away, conv_home, conv_away}.
static func simulate(rng: RandomNumberGenerator, home: Dictionary, away: Dictionary) -> Dictionary:
	# Seed PM98's LCG from the season RNG so a fixed test seed stays reproducible
	# while the per-shot rolls run on the authentic PM98 PRNG sequence.
	var prng := Pm98Rng.new(rng.randi())
	var gh := _gap(home, away)
	var ga := _gap(away, home)
	var sh := _chances(gh, BASE_SHOTS_HOME)
	var sa := _chances(ga, BASE_SHOTS_AWAY)
	var ch := _conv_permil(gh, BASE_CONV_HOME)
	var ca := _conv_permil(ga, BASE_CONV_AWAY)
	return {
		"home_goals": _resolve(prng, sh, ch),
		"away_goals": _resolve(prng, sa, ca),
		"shots_home": sh,
		"shots_away": sa,
		"conv_home": ch,
		"conv_away": ca,
	}
