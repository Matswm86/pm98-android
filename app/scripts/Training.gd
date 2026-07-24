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

## Develop every player in `squad` for one training week at `intensity`. `dev_factor` is an
## external multiplier on the IMPROVEMENT rate (the backroom TRAINER staff -- Staff.gd --
## defaults to 1.0); it never speeds a veteran's decline. Mutates attrs + dev_progress in
## place and returns {kind:"develop"|"decline", text} for the players who crossed this week.
static func train_week(rng: RandomNumberGenerator, squad: Array, intensity: String, dev_factor := 1.0) -> Array:
	var news: Array = []
	var factor := intensity_factor(intensity)
	var dev := maxf(0.1, dev_factor)
	for p in squad:
		var attrs: Variant = p.get("attrs", {})
		if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
			continue   # unrated fringe player: nothing to develop
		var age := int(p.get("age", 26))
		var base := _base_rate(age)
		# A dict carrying a hidden `potential` (injected real talents keep theirs; ordinary
		# seniors never have one -- Youth.graduate erases it) HOLDS at that ceiling while
		# he'd otherwise improve; veteran decline (negative base) still applies. Vanilla
		# players never carry the key, so their path is bit-identical.
		if base > 0.0 and p.has("potential") \
				and int((attrs as Dictionary).get("CA", 0)) >= int(p["potential"]):
			continue
		# Trainers speed development but don't hasten decline: dev_factor applies to a
		# positive (improving) rate only.
		var rate := base * factor * (dev if base > 0.0 else 1.0)
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


# ---- FOCUS training (the real TRAINING screen's mechanic) ------------------
# Live-witnessed on MANAGER.EXE 2026-07-24 (Bolton career, week 3):
#  * With NO trainers hired the whole screen is washed, TOTAL TRAINABLE PLAYERS = 0
#    and AUTO is inert ("For specific training\nyou have to have hired trainers.").
#  * Hiring HANDLING F. Bush 4.0* and SHOOTING G. Slattery 2.5* put their names on the
#    CURRENT TRAINING STAFF band with a TP column reading 4 and 2 — floor(stars) — and
#    TOTAL TRAINABLE PLAYERS became 6 = 4 + 2.
#  * AUTO tagged the three keepers HA and two forwards SH; the grid TOTAL read 5.
#  * Selecting a player and ticking a right-panel skill box assigns him: the box turns
#    gold, his grid row gains the 2-letter tag and TOTAL goes up by one.
#  * Ticking a skill whose coach is already at his TP is refused SILENTLY (a 5th
#    HANDLING pick did nothing); ticking with the GLOBAL total already at TOTAL
#    TRAINABLE raises the alert "You can´t train any more players." (MANAGER.EXE
#    0x2593f0).
# The per-skill attribute map is the screen's own row order (SPEC_BINDING §3).

# The eight focus rows of the AVER. panel, top to bottom.
const FOCUS_GENERAL := "GENERAL"
const FOCUS_FITNESS := "FITNESS"
const FOCUS_SKILLS := ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]
const FOCUS_ROWS := [FOCUS_GENERAL, FOCUS_FITNESS, "HANDLING", "PASSING", "DRIBBLING",
	"HEADING", "TACKLING", "SHOOTING"]

# Focus -> the decoded attribute it trains (the right panel's own rows).
const FOCUS_ATTR := {
	"HANDLING": "PO", "PASSING": "PA", "DRIBBLING": "RM",
	"HEADING": "RG", "TACKLING": "EN", "SHOOTING": "TI",
}
# GENERAL trains the four SPEED / STAMINA / AGGRESSION / QUALITY rows together.
const GENERAL_ATTRS := ["VE", "RE", "AG", "CA"]

# The grid tag chip: 2-letter code + the skill's own CURRENT TRAINING STAFF bar colour
# (witnessed: HANDLING tags are the orange 212,95,0 of its bar, SHOOTING the dark red
# 85,0,0 of its own). GENERAL / FITNESS tags are un-witnessed — same chip grammar.
const FOCUS_CODE := {
	"GENERAL": "GE", "FITNESS": "FI", "HANDLING": "HA", "PASSING": "PA",
	"DRIBBLING": "DR", "HEADING": "HE", "TACKLING": "TA", "SHOOTING": "SH",
}
const FOCUS_COLOUR := {
	"GENERAL": Color8(59, 85, 130), "FITNESS": Color8(42, 127, 85),
	"HANDLING": Color8(212, 95, 0), "PASSING": Color8(212, 63, 0),
	"DRIBBLING": Color8(210, 0, 0), "HEADING": Color8(170, 0, 0),
	"TACKLING": Color8(150, 0, 0), "SHOOTING": Color8(85, 0, 0),
}
# The alert the original raises when the global capacity is full (0x2593f0, verbatim
# including its acute accent), and the no-trainer gate text (0x2593b8).
const FULL_MSG := "You can´t train any more players."
const NO_TRAINER_MSG := "For specific training\nyou have to have hired trainers."

# A focused player's attribute moves this much faster than passive development.
const FOCUS_RATE := 0.22


## Training points for one skill = floor(that coach's stars); 0 with no coach hired.
static func skill_tp(staff: Array, skill: String) -> int:
	var m := Staff.member_in_role(staff, skill)
	return 0 if m.is_empty() else int(floor(float(m.get("stars", 0.0))))


## TOTAL TRAINABLE PLAYERS = the sum of every hired skill coach's TP (witnessed 4+2=6).
static func total_trainable(staff: Array) -> int:
	var n := 0
	for sk in FOCUS_SKILLS:
		n += skill_tp(staff, sk)
	return n


## How many players are already assigned to `skill` in the focus map.
static func skill_load(focus: Dictionary, skill: String) -> int:
	var n := 0
	for pid in focus:
		if str(focus[pid]) == skill:
			n += 1
	return n


## How well `p` suits `skill` for the AUTO fill: keepers own HANDLING, outfielders are
## ranked by the attribute the skill trains. A negative/zero score means "never AUTO him
## onto this coach" (witnessed: AUTO put the keepers on HANDLING and forwards on
## SHOOTING, never the reverse).
static func focus_fit(p: Dictionary, skill: String) -> float:
	var gk := bool(p.get("isGK", false))
	if skill == "HANDLING":
		return float(int((p.get("attrs", {}) as Dictionary).get("PO", 0))) if gk else 0.0
	if gk:
		return 0.0            # outfield skills never AUTO onto a keeper
	var key := str(FOCUS_ATTR.get(skill, ""))
	if key == "":
		return 0.0
	var v := float(int((p.get("attrs", {}) as Dictionary).get(key, 0)))
	# SHOOTING leans on forwards, TACKLING on defenders — the witnessed AUTO shape.
	var pos := str(p.get("pos", ""))
	if skill == "SHOOTING" and pos == "FW":
		v += 20.0
	elif skill == "TACKLING" and pos == "DF":
		v += 20.0
	elif skill == "PASSING" and pos == "MF":
		v += 20.0
	return v


## Apply one week of FOCUS training. Every assigned player pushes the attribute his
## coach teaches, at a rate scaled by that coach's stars; GENERAL spreads across the
## four SPEED/STAMINA/AGGRESSION/QUALITY rows and FITNESS restores condition. Returns
## the same {kind, text} news items train_week does, for the attributes that crossed.
static func train_focus_week(rng: RandomNumberGenerator, squad: Array,
		focus: Dictionary, staff: Array) -> Array:
	var news: Array = []
	if focus.is_empty():
		return news
	var by_id := {}
	for p in squad:
		by_id[int((p as Dictionary).get("id", -1))] = p
	for pid in focus:
		var p: Variant = by_id.get(int(pid))
		if not (p is Dictionary):
			continue
		var pd: Dictionary = p
		var attrs: Variant = pd.get("attrs", {})
		if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
			continue
		var skill := str(focus[pid])
		if skill == FOCUS_FITNESS:
			pd["fitness"] = mini(99, int(pd.get("fitness", 70)) + 2)
			continue
		var keys: Array = GENERAL_ATTRS if skill == FOCUS_GENERAL else [str(FOCUS_ATTR.get(skill, ""))]
		# A coach's stars scale his session; GENERAL has no coach, so it runs at 1.0.
		var stars := 1.0 if skill == FOCUS_GENERAL else maxf(0.5, float(skill_tp(staff, skill)) / 2.0)
		var gain := FOCUS_RATE * stars * (0.75 + rng.randf() * 0.5)
		var key := str(keys[rng.randi_range(0, keys.size() - 1)])
		if key == "":
			continue
		var prog := float(pd.get("focus_progress", 0.0)) + gain
		if prog < 1.0:
			pd["focus_progress"] = prog
			continue
		pd["focus_progress"] = prog - 1.0
		var a: Dictionary = attrs
		var cur := int(a.get(key, 0))
		if cur <= 0 or cur >= ATTR_CAP:
			continue
		a[key] = cur + 1
		news.append({"kind": "training",
			"text": "%s has improved his %s in training." % [pd.get("name", "?"), attr_name(key)]})
	return news
