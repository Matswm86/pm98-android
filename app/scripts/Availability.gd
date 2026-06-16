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
##   * injured_weeks   : matchdays still to sit out injured   (0 = fit)
##   * suspended_weeks : matchdays still to sit out banned     (0 = available)
##   * yellows         : bookings accrued toward the next ban
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
			var wk := _injury_weeks(rng)
			p["injured_weeks"] = maxi(int(p.get("injured_weeks", 0)), wk)
			news.append({"kind": "injury",
				"text": "%s picked up an injury -- out for %d %s." % [_nm(p), wk, _matches(wk)]})
			continue
		if rng.randf() < RED_CHANCE:
			var rwk := _red_weeks(rng)
			p["suspended_weeks"] = maxi(int(p.get("suspended_weeks", 0)), rwk)
			news.append({"kind": "suspension",
				"text": "%s was sent off -- banned for %d %s." % [_nm(p), rwk, _matches(rwk)]})
			continue
		if rng.randf() < YELLOW_CHANCE:
			var y := int(p.get("yellows", 0)) + 1
			if y >= YELLOWS_FOR_BAN:
				p["yellows"] = 0
				p["suspended_weeks"] = maxi(int(p.get("suspended_weeks", 0)), 1)
				news.append({"kind": "suspension",
					"text": "%s is suspended after %d bookings -- out next match." % [_nm(p), YELLOWS_FOR_BAN]})
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


# ---- helpers -------------------------------------------------------------

## Injury length in matches, weighted short (most knocks are a week or two).
static func _injury_weeks(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.45:
		return 1
	if r < 0.75:
		return 2
	if r < 0.90:
		return 3
	if r < 0.97:
		return 4
	return 5 + (1 if rng.randf() < 0.5 else 0)

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
