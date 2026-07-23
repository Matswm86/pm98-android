class_name Availability
extends RefCounted
## Injuries & suspensions for a managed career (Track A engine depth).
##
## A football-manager spine mechanic the build was missing: players pick up
## injuries and bookings while they play, sit out while they recover, and come
## back. Availability is the consequence layer that makes selection matter --
## an injured or suspended player can't be fielded, which forces the engine to
## reshuffle the XI and quietly weakens the side until he's back.
##
## State lives on the player dict (so it persists inside Career.rosters with no
## extra save plumbing):
##   * injured_weeks   : weeks still to sit out injured        (0 = fit)
##   * suspended_weeks : matchdays still to sit out banned     (0 = available)
##   * yellows         : bookings accrued toward the next ban
##   * injury_type     : index into INJURY_TYPES (the diagnosis), set when injured
## A player is AVAILABLE only when both counters are zero.
##
## Scope (an honest simplification, flagged here): injuries/cards are rolled for
## the MANAGER's club only -- the side the player actually selects and feels the
## loss of. AI clubs auto-field their best XI from the full squad, as before.
## Counters mean "matches missed", so injured_weeks = 2 sits out the next two.
##
## GameDB-free and side-effect-only on the dicts passed in, so it stays
## headless-testable (see tests/test_availability.gd).

# Five bookings earn a one-match ban (the long-standing PM-era rule), then the
# yellow tally resets. Reds ban immediately for 1-3 matches by severity.
const YELLOWS_FOR_BAN := 5

# The game's own injury diagnoses, in its native index order. Lifted verbatim from
# MANAGER.EXE (extracted/Premier Manager 98/MANAGER.EXE): the injury-name pointer
# array at VA 0x6622e8. The stored diagnosis is a byte at the injury record's +2
# field (accessor fn @ 0x584e50: index < 18 -> this table, else the "XXXX"
# sentinel). No invention -- these are the 18 strings the original prints in the
# INJURIES screen "TYPE OF INJURY" column and in its injury news lines.
const INJURY_TYPES := [
	"virus", "cold", "pulled muscle", "dead leg", "pulled hamstring",
	"sprained ankle", "dislocated wrist", "dislocated finger", "sprained wrist",
	"groin strain", "broken nose", "broken toe", "broken cheekbone",
	"dislocated shoulder", "fractured rib", "shin splints injury", "slipped disc",
	"broken leg",
]
# The game's is_serious(injury) predicate (MANAGER.EXE @ 0x584e20 returns 1 for
# type indices 11..17). Serious diagnoses are the "badly injured" news tier
# (templates @ 0x662bc0 / 0x662c04) and take the longer knocks; 0..10 are ordinary
# (templates @ 0x662afc / 0x662b24).
const SERIOUS_MIN := 11

# Match-injury diagnosis distribution -- MANAGER.EXE roll_B @0x585210, the exact
# rand(100) compare ladder (virus/cold are excluded here: those two are the
# WEEKLY-illness roll_A @0x5850b0, a separate mechanic the app doesn't model).
# Each row is [threshold_exclusive, type_index]: rand(0..99) picks the first row
# whose threshold it falls under; the 98/99 tail maps to slipped disc / broken leg
# (binary: cmp 0x63; sbb eax,eax; add eax,0x11). Verified to sum to 100%.
const MATCH_INJURY_CDF := [
	[0x19, 2], [0x23, 3], [0x2d, 4], [0x35, 5], [0x3d, 6], [0x45, 7],
	[0x4a, 8], [0x4b, 9], [0x50, 10], [0x55, 11], [0x57, 12], [0x5c, 13],
	[0x61, 14], [0x62, 15],
]

# Per featured player, per match (probabilities, not permil -- rolled with randf).
const INJ_CHANCE := 0.018      # ~0.2 injuries / match across an XI (~1 every 5)
const RED_CHANCE := 0.004      # ~1 sending-off a season for a side
const YELLOW_CHANCE := 0.055   # bookings trickle toward bans over a season

const C_INJURY := Color(0.92, 0.36, 0.33)     # red    -- out injured
const C_SUSPENSION := Color(0.97, 0.66, 0.18) # orange -- banned
const C_RETURN := Color(0.34, 0.86, 0.46)     # green  -- back available


# ---- queries -------------------------------------------------------------

static func is_available(p: Dictionary) -> bool:
	return int(p.get("injured_weeks", 0)) <= 0 and int(p.get("suspended_weeks", 0)) <= 0

## The subset of `squad` who can be selected this week (same dict references, so
## downstream mutation still writes through to the roster).
static func available_players(squad: Array) -> Array:
	return squad.filter(func(p): return is_available(p))

## Short status badge for a roster row, "" when fit. "INJ 3w" / "SUS 1w".
static func status_label(p: Dictionary) -> String:
	var inj := int(p.get("injured_weeks", 0))
	if inj > 0:
		return "INJ %dw" % inj
	var sus := int(p.get("suspended_weeks", 0))
	if sus > 0:
		return "SUS %dw" % sus
	return ""

## {state: "FIT"|"INJ"|"SUS", weeks:int, colour:Color} for richer UI.
static func status(p: Dictionary) -> Dictionary:
	var inj := int(p.get("injured_weeks", 0))
	if inj > 0:
		return {"state": "INJ", "weeks": inj, "colour": C_INJURY}
	var sus := int(p.get("suspended_weeks", 0))
	if sus > 0:
		return {"state": "SUS", "weeks": sus, "colour": C_SUSPENSION}
	return {"state": "FIT", "weeks": 0, "colour": C_RETURN}


# ---- weekly tick ---------------------------------------------------------

## A matchday has passed: decrement every active injury/suspension by one. Returns
## news items {kind:"return", text} for each player who has just become available.
static func tick_week(squad: Array) -> Array:
	var news: Array = []
	for p in squad:
		var inj := int(p.get("injured_weeks", 0))
		if inj > 0:
			inj -= 1
			p["injured_weeks"] = inj
			if inj == 0:
				p.erase("injury_type")
				news.append({"kind": "return", "text": "%s is back to full fitness." % _nm(p)})
		var sus := int(p.get("suspended_weeks", 0))
		if sus > 0:
			sus -= 1
			p["suspended_weeks"] = sus
			if sus == 0:
				news.append({"kind": "return", "text": "%s has served his suspension." % _nm(p)})
	return news


# ---- match roll ----------------------------------------------------------

## Roll the consequences of one match for the players who featured (`featured` =
## the fit XI that played). Mutates their counters and returns news items
## {kind:"injury"|"suspension", text}. A player can pick up at most one of
## injury / red / yellow per match (checked in that order of severity).
## `injury_mult` scales the injury chance (training intensity feeds this in).
static func roll_match(rng: RandomNumberGenerator, featured: Array, injury_mult := 1.0) -> Array:
	var news: Array = []
	var inj_chance := INJ_CHANCE * injury_mult
	for p in featured:
		if rng.randf() < inj_chance:
			# The game rolls the diagnosis first, then its per-type duration
			# (MANAGER.EXE apply_match_injury @0x584c00 -> roll_B -> setter).
			var ti := _roll_match_injury_type(rng)
			var wk := _injury_weeks(rng, ti)
			p["injured_weeks"] = maxi(int(p.get("injured_weeks", 0)), wk)
			p["injury_type"] = ti
			news.append({"kind": "injury", "type": ti,
				"text": _injury_news(_nm(p), wk, ti)})
			continue
		if rng.randf() < RED_CHANCE:
			var rwk := _red_weeks(rng)
			p["suspended_weeks"] = maxi(int(p.get("suspended_weeks", 0)), rwk)
			news.append({"kind": "suspension",
				"text": "%s sent off -- banned %d %s." % [_nm(p), rwk, _matches(rwk)]})
			continue
		if rng.randf() < YELLOW_CHANCE:
			var y := int(p.get("yellows", 0)) + 1
			if y >= YELLOWS_FOR_BAN:
				p["yellows"] = 0
				p["suspended_weeks"] = maxi(int(p.get("suspended_weeks", 0)), 1)
				news.append({"kind": "suspension",
					"text": "%s suspended -- out next match." % _nm(p)})
			else:
				p["yellows"] = y
	return news


## Reset every availability counter (start-of-season clean slate: bans don't
## carry, fresh fitness). Mutates the squad in place.
static func reset(squad: Array) -> void:
	for p in squad:
		p["injured_weeks"] = 0
		p["suspended_weeks"] = 0
		p["yellows"] = 0
		p.erase("injury_type")


# ---- helpers -------------------------------------------------------------

## The diagnosis string for a player, "" when fit / untyped (legacy state).
static func injury_type_name(p: Dictionary) -> String:
	if int(p.get("injured_weeks", 0)) <= 0 or not p.has("injury_type"):
		return ""
	var ti := int(p["injury_type"])
	return INJURY_TYPES[ti] if ti >= 0 and ti < INJURY_TYPES.size() else ""

## Roll a match-injury diagnosis, MANAGER.EXE roll_B @0x585210: rand(0..99) mapped
## through the exact compare ladder (MATCH_INJURY_CDF). No invention -- this is the
## game's own per-type probability table (virus/cold excluded from match injuries).
static func _roll_match_injury_type(rng: RandomNumberGenerator) -> int:
	var r := rng.randi_range(0, 99)
	for row in MATCH_INJURY_CDF:
		if r < int(row[0]):
			return int(row[1])
	return 16 if r < 0x63 else 17

## Injury news line, using MANAGER.EXE's exact wording: serious diagnoses get the
## "is badly injured" tier (0x662bc0 / 0x662c04), ordinary ones the "will be out"
## tier (0x662afc / 0x662b24). Unit is weeks (the game's, not "matches").
static func _injury_news(nm: String, wk: int, ti: int) -> String:
	var t: String = INJURY_TYPES[ti]
	if ti >= SERIOUS_MIN:
		if wk == 1:
			return "%s is badly injured: he will be out for the next week with a %s." % [nm, t]
		return "%s is badly injured: he will be out for %d weeks with a %s." % [nm, wk, t]
	if wk == 1:
		return "%s will be out for one week with a %s." % [nm, t]
	return "%s will be out for the next %d weeks with a %s." % [nm, wk, t]


## Injury length in weeks for diagnosis `ti` -- MANAGER.EXE injury setter @0x584e70.
## The game rolls four weighted coins (75/50/25/12%) then feeds them to a per-type
## duration jump table (@0x585048); each `match` arm is that type's exact formula,
## transcribed byte-for-byte (see docs/re/injury_model_re.md). All four coins are
## rolled every time, as in the binary, so the RNG draw count matches.
static func _injury_weeks(rng: RandomNumberGenerator, ti: int) -> int:
	var a := 1 if rng.randi_range(0, 99) < 75 else 0
	var b := 1 if rng.randi_range(0, 99) < 50 else 0
	var c := 1 if rng.randi_range(0, 99) < 25 else 0
	var d := 1 if rng.randi_range(0, 99) < 12 else 0
	match ti:
		3: return 1                        # dead leg
		9: return 2                        # groin strain
		0, 1, 2, 8: return b + 1           # virus/cold/pulled muscle/sprained wrist
		4, 7, 10: return b + 2             # hamstring/dislocated finger/broken nose
		5: return b + 3                    # sprained ankle
		6: return d + c + b + 5            # dislocated wrist
		11: return c + b + 3               # broken toe
		12: return (c + b + 9) * 2         # broken cheekbone
		13: return c + b + 6               # dislocated shoulder
		14: return (c + b) * 2 + d + 5     # fractured rib
		15: return (c + b) * 2 + d + 25    # shin splints injury
		16: return (d + c + a + b + 10) * 2  # slipped disc
		17: return (c + b + 20) * 2 + d    # broken leg
	return b + 1

## Ban length for a red: mostly 1, occasionally 2-3 (violent conduct).
static func _red_weeks(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.70:
		return 1
	if r < 0.90:
		return 2
	return 3

static func _matches(n: int) -> String:
	return "match" if n == 1 else "matches"

static func _nm(p: Dictionary) -> String:
	return str(p.get("name", "A player"))
