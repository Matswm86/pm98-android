class_name Training
extends RefCounted
## Player development through training (Track A engine depth).
##
## Gives the week-to-week career a long arc: your players get better or worse over
## a season depending on their age and how hard you train them. Young players
## improve, players in their prime hold, veterans decline -- and training INTENSITY
## is the lever, trading faster development against a higher injury risk (the link
## back into Availability.gd from last session).
##
## Kept light on the save: a single float `dev_progress` accumulates on each player
## dict; when it crosses +/-1.0 one attribute changes by a point and a news line
## fires, then the fractional remainder carries over. So changes are occasional,
## visible and explained, not a noisy per-attribute drift. Attributes are the
## decoded 10 (VE RE AG CA RM RG PA TI EN PO), so a bump flows straight through to
## ratings, the squad AV column and transfer value with no extra plumbing.
##
## GameDB-free, mutates only the dicts passed in -> headless-testable
## (tests/test_training.gd). Manager's club only, like injuries.

const INTENSITIES := ["Light", "Normal", "Intensive"]
const DEFAULT_INTENSITY := "Normal"

# Per-intensity development-rate factor and injury-risk multiplier.
const _FACTOR := {"Light": 0.60, "Normal": 1.00, "Intensive": 1.55}
const _INJURY_MULT := {"Light": 0.75, "Normal": 1.00, "Intensive": 1.45}

# Base weekly progress by career stage (Normal intensity). Young players climb,
# the prime holds with a touch of rounding-out, veterans slide.
const _RATE_YOUNG := 0.11    # age <= PRIME_LO
const _RATE_PRIME := 0.015   # PRIME_LO < age <= PRIME_HI
const _RATE_VET := -0.085    # age > PRIME_HI
const PRIME_LO := 23
const PRIME_HI := 30

const ATTR_CAP := 96   # a developed attribute won't climb past this
const ATTR_FLOOR := 22 # a declining attribute won't drop below this

# The trainable attribute codes (no PO -- keeper rating develops on its own track).
const _OUTFIELD_CODES := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN"]
# Veterans lose their legs first: physical attributes decline ahead of the rest.
const _DECLINE_FIRST := ["VE", "RE", "AG"]

const _NAMES := {
	"VE": "Pace", "RE": "Stamina", "AG": "Aggression", "CA": "Ability",
	"RM": "Heading", "RG": "Dribbling", "PA": "Passing", "TI": "Shooting",
	"EN": "Tackling", "PO": "Goalkeeping",
}


# ---- lookups -------------------------------------------------------------

static func intensity_factor(intensity: String) -> float:
	return float(_FACTOR.get(intensity, 1.0))

## Injury-risk multiplier for the intensity (fed to Availability.roll_match).
static func injury_multiplier(intensity: String) -> float:
	return float(_INJURY_MULT.get(intensity, 1.0))

static func attr_name(code: String) -> String:
	return str(_NAMES.get(code, code))


# ---- weekly development --------------------------------------------------

## Develop every player in `squad` for one training week at `intensity`. Mutates
## attrs + dev_progress in place and returns news items
## {kind:"develop"|"decline", text} for the players who crossed a point this week.
static func train_week(rng: RandomNumberGenerator, squad: Array, intensity: String) -> Array:
	var news: Array = []
	var factor := intensity_factor(intensity)
	for p in squad:
		var attrs: Variant = p.get("attrs", {})
		if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
			continue   # unrated fringe player: nothing to develop
		var age := int(p.get("age", 26))
		var rate := _base_rate(age) * factor
		# A little noise so identically-aged players don't move in lockstep.
		rate += (rng.randf() - 0.5) * 0.04 * factor
		var prog := float(p.get("dev_progress", 0.0)) + rate
		if prog >= 1.0:
			prog -= 1.0
			var item := _improve(p, attrs)
			if not item.is_empty():
				news.append(item)
		elif prog <= -1.0:
			prog += 1.0
			var item := _decline(p, attrs)
			if not item.is_empty():
				news.append(item)
		p["dev_progress"] = prog
	return news


## Reset development carry-over (e.g. at season rollover, after ages tick).
static func reset_progress(squad: Array) -> void:
	for p in squad:
		p["dev_progress"] = 0.0


# ---- trend (for the training screen) -------------------------------------

## {dir:"up"|"down"|"hold", arrow:String, colour:Color, ability:int, name:String}
## for one player -- how training is moving him, by age.
static func trend(p: Dictionary) -> Dictionary:
	var age := int(p.get("age", 26))
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	var ca := int(attrs.get("CA", 0))
	if age <= PRIME_LO:
		return {"dir": "up", "arrow": "^", "colour": Color(0.34, 0.86, 0.46),
			"ability": ca, "name": str(p.get("name", "?"))}
	if age > PRIME_HI:
		return {"dir": "down", "arrow": "v", "colour": Color(0.92, 0.36, 0.33),
			"ability": ca, "name": str(p.get("name", "?"))}
	return {"dir": "hold", "arrow": "-", "colour": Color(0.86, 0.90, 0.96),
		"ability": ca, "name": str(p.get("name", "?"))}


# ---- internals -----------------------------------------------------------

static func _base_rate(age: int) -> float:
	if age <= PRIME_LO:
		return _RATE_YOUNG
	if age <= PRIME_HI:
		return _RATE_PRIME
	return _RATE_VET


## Raise one attribute: the lowest outfield code still below the cap (so the player
## rounds out his game), nudging CA up alongside it so ability tracks development.
static func _improve(p: Dictionary, attrs: Dictionary) -> Dictionary:
	var code := _lowest_below_cap(attrs)
	if code == "":
		return {}
	attrs[code] = mini(ATTR_CAP, int(attrs.get(code, 0)) + 1)
	# ability (CA) is the headline rating -> let it creep up with real development
	if code != "CA" and int(attrs.get("CA", 0)) < ATTR_CAP:
		attrs["CA"] = mini(ATTR_CAP, int(attrs.get("CA", 0)) + 1)
	return {"kind": "develop",
		"text": "%s has improved his %s." % [p.get("name", "?"), attr_name(code)]}


## Lower one attribute: a physical first (pace/stamina/aggression), else the
## highest outfield code, pulling CA down a touch so the decline shows in ability.
static func _decline(p: Dictionary, attrs: Dictionary) -> Dictionary:
	var code := ""
	for c in _DECLINE_FIRST:
		if int(attrs.get(c, 0)) > ATTR_FLOOR:
			code = c
			break
	if code == "":
		code = _highest_above_floor(attrs)
	if code == "":
		return {}
	attrs[code] = maxi(ATTR_FLOOR, int(attrs.get(code, 0)) - 1)
	if code != "CA" and int(attrs.get("CA", 0)) > ATTR_FLOOR:
		attrs["CA"] = maxi(ATTR_FLOOR, int(attrs.get("CA", 0)) - 1)
	return {"kind": "decline",
		"text": "%s is past his best -- %s is slipping." % [p.get("name", "?"), attr_name(code)]}


static func _lowest_below_cap(attrs: Dictionary) -> String:
	var best := ""
	var best_v := ATTR_CAP + 1
	for c in _OUTFIELD_CODES:
		var v := int(attrs.get(c, 0))
		if v < ATTR_CAP and v < best_v:
			best_v = v
			best = c
	return best


static func _highest_above_floor(attrs: Dictionary) -> String:
	var best := ""
	var best_v := ATTR_FLOOR - 1
	for c in _OUTFIELD_CODES:
		var v := int(attrs.get(c, 0))
		if v > ATTR_FLOOR and v > best_v:
			best_v = v
			best = c
	return best
