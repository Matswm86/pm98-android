class_name Youth
extends RefCounted
## The Youth Team (Track A engine depth): a scouted intake of young players who
## develop on their own track until the youth manager judges one ready to step up,
## at which point you PROMOTE him into the first-team squad.
##
## Faithful surface (strings scanned from MANAGER.EXE this session): YOUTH TEAM /
## YOUTH PLAYER / YOUTH SCOUT / YOUTH MANAGER / PROMOTE / PROMOTED, and the message
## templates "%s has joined your Youth Team.",
## "Your youth manager has informed you that %s is ready to be promoted to the first
## team squad.", "The youth player %s has rejected your offer.",
## "The youth team scout has finished his search." / "...hasn't found".
## The original gates intake behind a hired YOUTH SCOUT and faster growth behind a
## YOUTH MANAGER -- staff (EMPLE) is a separate deferred screen, so for now the club
## runs a baseline youth setup; the intake/develop rates are factor-scaled so a future
## staff system can raise them with no rework here.
##
## A youth player carries the SAME dict shape as a senior (id/name/age/isGK/attrs) plus
## a hidden `potential` (his CA ceiling), a `dev_progress` carry-over and a `ready` flag,
## so promotion is a straight move into rosters[club_id] with no attribute remapping and
## every existing screen (squad, line-up, training, transfer value) reads him unchanged.
##
## GameDB-free, mutates only the dicts passed in -> headless-testable
## (tests/test_youth.gd). Manager's club only, like injuries and training.

# Intake age band, the age a youngster ages out of the setup if never promoted, and the
# soft cap on how many can sit in the youth team at once.
const INTAKE_AGE_LO := 15
const INTAKE_AGE_HI := 17
const GRADUATE_AGE := 19          # over this and not promoted -> released from the setup
const SQUAD_CAP := 12             # the youth team won't grow past this

# A youth player's CA must reach this for the youth manager to flag him ready to step up.
# Low-potential intakes never get here and age out instead -- youth is a gamble.
const READY_CA := 58

# Current-ability band at intake, and the spread of hidden potential above it. A gem
# (high roll) tops out near first-team class; most settle as squad players or wash out.
const INTAKE_CA_LO := 30
const INTAKE_CA_HI := 46
const POTENTIAL_LO := 8           # potential = intake CA + [POTENTIAL_LO..POTENTIAL_HI]
const POTENTIAL_HI := 42
const POTENTIAL_CAP := 88         # no youth projects past this
const GK_CHANCE := 0.16           # roughly one in six intakes is a goalkeeper
# Outfield position split for generated players, weighted to the real squad balance
# decoded from EQUIPOS.PKF (DF 677 / MF 598 / FW 481 across the English pyramid).
const _DF_SHARE := 0.38
const _MF_SHARE := 0.33           # remainder (0.29) is FW

# Weekly development toward potential (youth climb fast -- roughly a point of ability every
# ~3 weeks, so a promising prospect reaches first-team grade in one to two seasons). Scaled
# by a staff factor that defaults to 1.0 until a YOUTH MANAGER exists to raise it.
const _DEV_RATE := 0.34
const ATTR_FLOOR := 20

# The trainable attribute codes (PO tracks separately for keepers, like Training).
const _OUTFIELD_CODES := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN"]

# Regen name pools -- English-style forenames + surnames so a fresh intake reads like a
# crop of academy kids (PM98 generates regen youth names the same way; these are ours).
const _FORENAMES := [
	"DANNY", "LEE", "CRAIG", "JAMIE", "RYAN", "KEVIN", "SCOTT", "DEAN", "WAYNE", "GARY",
	"NEIL", "STUART", "MARK", "PAUL", "STEVE", "DAVID", "MICHAEL", "ANDY", "RICHARD",
	"CHRIS", "JASON", "DARREN", "SIMON", "NICK", "ADAM", "LUKE", "BEN", "JACK", "TOM",
	"JOE", "HARRY", "GEORGE", "ASHLEY", "CARL", "ROSS", "OWEN", "ROBBIE", "JORDAN",
]
const _SURNAMES := [
	"WALSH", "HUGHES", "BARNES", "CLARKE", "REID", "MURPHY", "FOSTER", "PRICE", "GRAY",
	"WALLACE", "HOLMES", "DUNNE", "BENNETT", "FLETCHER", "WARD", "PHILLIPS", "PARKER",
	"COLE", "DIXON", "CARROLL", "HARPER", "SHARP", "FENTON", "DOYLE", "KEANE", "RILEY",
	"NOLAN", "QUINN", "BYRNE", "MULLEN", "HASLAM", "WHELAN", "CONNOLLY", "BRADY", "REEVES",
	"SPENCER", "MOONEY", "GALLAGHER", "SUTTON", "HACKETT", "PALMER", "ROWLEY", "STOKES",
]


# ---- intake --------------------------------------------------------------

## Generate `count` fresh youth players with ids starting at `first_id` (the caller's
## monotonic youth-id minter -- kept well above the senior id space so a promoted youth
## never collides). `factor` (>= 1.0, a future YOUTH SCOUT lever) nudges the quality of
## the crop. Returns the Array of player dicts; never touches GameDB.
static func intake(rng: RandomNumberGenerator, count: int, first_id: int, factor := 1.0) -> Array:
	var out: Array = []
	for i in maxi(0, count):
		out.append(_make_player(rng, first_id + i, factor))
	return out


static func _make_player(rng: RandomNumberGenerator, id: int, factor: float) -> Dictionary:
	var is_gk := rng.randf() < GK_CHANCE
	var ca := rng.randi_range(INTAKE_CA_LO, INTAKE_CA_HI)
	# A better scout finds, on average, a higher ceiling.
	var pot_bonus := int(round(rng.randi_range(POTENTIAL_LO, POTENTIAL_HI) * clampf(factor, 0.8, 1.6)))
	var potential := mini(POTENTIAL_CAP, ca + pot_bonus)
	return {
		"id": id,
		"name": "%s %s" % [_FORENAMES[rng.randi() % _FORENAMES.size()],
			_SURNAMES[rng.randi() % _SURNAMES.size()]],
		"age": rng.randi_range(INTAKE_AGE_LO, INTAKE_AGE_HI),
		"isGK": is_gk,
		"pos": random_pos(rng, is_gk),
		"attrs": _make_attrs(rng, ca, is_gk),
		"potential": potential,
		"dev_progress": 0.0,
		"ready": false,
		"is_youth": true,
	}


## A generated player's GK/DF/MF/FW demarcación, so regen youth and free agents bucket
## into the same position sections (squad screen, tactics) as decoded senior players.
static func random_pos(rng: RandomNumberGenerator, is_gk: bool) -> String:
	if is_gk:
		return "GK"
	var r := rng.randf()
	if r < _DF_SHARE:
		return "DF"
	if r < _DF_SHARE + _MF_SHARE:
		return "MF"
	return "FW"


## A raw attribute row around current ability `ca`, with the keeper/outfield split the
## rest of the engine expects (a keeper's PO is his headline, his outfield codes are low).
static func _make_attrs(rng: RandomNumberGenerator, ca: int, is_gk: bool) -> Dictionary:
	var a: Dictionary = {}
	for c in _OUTFIELD_CODES:
		a[c] = clampi(ca + rng.randi_range(-8, 8), ATTR_FLOOR, 80)
	a["CA"] = ca
	if is_gk:
		a["PO"] = clampi(ca + rng.randi_range(0, 10), ATTR_FLOOR, 82)
		# A keeper's outfield ability is incidental; keep it modest.
		for c in ["RM", "RG", "PA", "TI", "EN"]:
			a[c] = clampi(int(a[c]) - 18, ATTR_FLOOR, 60)
	else:
		a["PO"] = rng.randi_range(ATTR_FLOOR, 35)
	return a


# ---- weekly development --------------------------------------------------

## Develop every youth in `youth` for one week. Each climbs toward his hidden potential;
## when his CA first reaches READY_CA the youth manager flags him (a "youth" news item),
## a fully-developed youngster holds. `factor` is the staff/development lever (>= 1.0).
## Mutates attrs/dev_progress/ready in place; returns news {kind:"develop"|"youth", text}.
static func develop_week(rng: RandomNumberGenerator, youth: Array, factor := 1.0) -> Array:
	var news: Array = []
	for p in youth:
		var attrs: Variant = p.get("attrs", {})
		if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
			continue
		var ca := int((attrs as Dictionary).get("CA", 0))
		var potential := int(p.get("potential", ca))
		if ca >= potential:
			continue   # reached his ceiling -- holds until promoted or aged out
		var rate := _DEV_RATE * maxf(0.5, factor)
		rate += (rng.randf() - 0.5) * 0.05 * factor
		var prog := float(p.get("dev_progress", 0.0)) + maxf(0.0, rate)
		if prog >= 1.0:
			prog -= 1.0
			var item := _improve(p, attrs, potential)
			if not item.is_empty():
				news.append(item)
			# Crossing the readiness line is the headline the youth manager reports.
			if not bool(p.get("ready", false)) and int(attrs.get("CA", 0)) >= READY_CA:
				p["ready"] = true
				news.append({"kind": "youth",
					"text": "Your youth manager reports that %s is ready to be promoted to the first team squad."
						% p.get("name", "?")})
		p["dev_progress"] = prog
	return news


## Raise one attribute (the lowest outfield code still below the ceiling) and nudge CA up
## with it, so development flows to ability without overshooting potential.
static func _improve(p: Dictionary, attrs: Dictionary, potential: int) -> Dictionary:
	var ceil_attr := mini(POTENTIAL_CAP, potential + 6)   # individual attrs may sit a little above CA
	var code := _lowest_below(attrs, ceil_attr)
	if code == "":
		return {}
	attrs[code] = mini(ceil_attr, int(attrs.get(code, 0)) + 1)
	if code != "CA" and int(attrs.get("CA", 0)) < potential:
		attrs["CA"] = mini(potential, int(attrs.get("CA", 0)) + 1)
	return {"kind": "develop",
		"text": "Youth team: %s is coming along nicely." % p.get("name", "?")}


static func _lowest_below(attrs: Dictionary, ceiling: int) -> String:
	var best := ""
	var best_v := ceiling + 1
	for c in _OUTFIELD_CODES:
		var v := int(attrs.get(c, 0))
		if v < ceiling and v < best_v:
			best_v = v
			best = c
	return best


# ---- queries (for the screen + Career) -----------------------------------

static func is_ready(p: Dictionary) -> bool:
	return bool(p.get("ready", false))


## Current ability (CA) for a youth -- his headline rating on the screen.
static func ability(p: Dictionary) -> int:
	var attrs: Variant = p.get("attrs", {})
	return int((attrs as Dictionary).get("CA", 0)) if attrs is Dictionary else 0


static func potential_of(p: Dictionary) -> int:
	return int(p.get("potential", ability(p)))


## A 1-5 star projection of a youth's ceiling, for the screen.
static func potential_stars(p: Dictionary) -> int:
	var pot := potential_of(p)
	return clampi(1 + int(floor((pot - 40) / 12.0)), 1, 5)


## Strip the youth-only markers and stamp first-team fields, returning the player dict
## ready to drop into a senior roster (the caller sets clubId + contract). Mutates `p`.
static func graduate(p: Dictionary) -> Dictionary:
	p.erase("potential")
	p.erase("ready")
	p.erase("is_youth")
	p["dev_progress"] = 0.0
	p["injured_weeks"] = 0
	p["suspended_weeks"] = 0
	p["yellows"] = 0
	return p
