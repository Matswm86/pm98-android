class_name Staff
extends RefCounted
## The backroom staff (EMPLE / employees), the Track-A lever that ties together the three
## systems already built: a TRAINER speeds player development, a PHYSIOTHERAPIST cuts injury
## risk, and a YOUTH COACH improves both the academy intake and how fast youth develop. You
## hire them from a pool of available staff and pay their wages each week; sacking one costs
## a compensation (the contract pay-off).
##
## Faithful surface (strings scanned from MANAGER.EXE this session): STAFF / STAFF WAGES /
## STAFF AVAILABLE / CURRENT TRAINING STAFF / TRAINER / TRAINERS / TRAINING STAFF /
## PHYSIO. / PHYSIOTHERAPIST(S) / SCOUT(S) / YOUTH TEAM SCOUT / YOUTH (TEAM) MANAGER /
## ASSISTANT MANAGER, HIRE (contratar.bmp) / SACK (despedir.bmp), YEARLY WAGE / MONTHLY
## WAGE, COMPENSATIONS OF CONTRACT, "Are you sure you want to sack him ?",
## "1 member of staff" / "%d members of staff", "you have to have hired trainers.",
## "you need to hire an Assistant.". PM98's staff EFFECTS + wages are data-driven (loaded
## from the save), so the model here is OURS; only the surface is PM98's. A general transfer
## SCOUT and the ASSISTANT MANAGER (automation) are deferred -- the three effect-bearing
## roles below are the ones with clean hooks into the existing engine.
##
## GameDB-free, pure functions over plain dicts -> headless-testable (tests/test_staff.gd).

# The roles we model, each with a clean mechanical hook into the engine.
const TRAINER := "Trainer"
const PHYSIO := "Physiotherapist"
const YOUTH_COACH := "Youth Coach"
# Automation roles (T2 #10): a SCOUT produces transfer suggestions, an ASSISTANT MANAGER
# protects your expiring stars by auto-renewing them at the rollover. They have no _factor
# (their effect is a hook, not a multiplier) -- see has_scout / scout_quality / etc.
const SCOUT := "Scout"
const ASSISTANT := "Assistant Manager"
const ROLES := [TRAINER, PHYSIO, YOUTH_COACH, SCOUT, ASSISTANT]

# Per-role tuning. effect = the per-quality-point step on that role's factor; the factor is
# clamped to [lo, hi]. wage = yearly_base + quality * wage_step (a seasonal wage).
const _DEF := {
	"Trainer": {"step": 0.05, "lo": 1.0, "hi": 1.5, "wage_base": 30000, "wage_step": 15000,
		"icon": "emple3", "blurb": "speeds player development"},
	"Physiotherapist": {"step": 0.05, "lo": 0.55, "hi": 1.0, "wage_base": 26000, "wage_step": 12000,
		"icon": "emple6", "blurb": "cuts injury risk"},
	"Youth Coach": {"step": 0.06, "lo": 1.0, "hi": 1.6, "wage_base": 28000, "wage_step": 14000,
		"icon": "emple7", "blurb": "improves the academy"},
	"Scout": {"step": 0.0, "lo": 1.0, "hi": 1.0, "wage_base": 24000, "wage_step": 11000,
		"icon": "emple1", "blurb": "finds transfer targets"},
	"Assistant Manager": {"step": 0.0, "lo": 1.0, "hi": 1.0, "wage_base": 40000, "wage_step": 20000,
		"icon": "emple2", "blurb": "auto-renews your stars"},
}

const QUALITY_LO := 1
const QUALITY_HI := 5
const SEASON_WEEKS := 52   # wages are yearly; weekly = / SEASON_WEEKS (matches FinanceModel)
const SACK_WEEKS := 8      # COMPENSATIONS OF CONTRACT: sacking pays this many weeks' wage

# Staff name pools (English-style), ours -- PM98 generates staff names the same way.
const _FORENAMES := [
	"BRIAN", "ROY", "TERRY", "DON", "ERIC", "GRAHAM", "PETER", "ALAN", "KEITH", "DEREK",
	"GORDON", "MALCOLM", "TREVOR", "BARRY", "RON", "GEOFF", "STAN", "NORMAN", "CLIVE", "LEN",
	"FRANK", "ARTHUR", "HOWARD", "VICTOR", "DENIS", "JOHN", "BOB", "JIM", "TED", "WALTER",
]
const _SURNAMES := [
	"ATKINSON", "ROBSON", "GREENWOOD", "VENABLES", "ARMFIELD", "SAUNDERS", "HOWE", "REVIE",
	"MERCER", "NICHOLSON", "SHANKLY", "PAISLEY", "CLOUGH", "TAYLOR", "WATERS", "BURKINSHAW",
	"SEXTON", "DOCHERTY", "ALLISON", "WADDINGTON", "MILNE", "CATTERICK", "STEIN", "BUSBY",
	"GRADI", "BASSETT", "BOND", "MACARI", "PLEAT", "BARTON", "HODGSON", "WILKINS",
]


# ---- candidate generation ------------------------------------------------

## A hireable staff candidate for `role` with a random quality + the matching wage.
static func make_candidate(rng: RandomNumberGenerator, id: int, role: String) -> Dictionary:
	var quality := rng.randi_range(QUALITY_LO, QUALITY_HI)
	return {
		"id": id,
		"role": role,
		"name": "%s %s" % [_FORENAMES[rng.randi() % _FORENAMES.size()],
			_SURNAMES[rng.randi() % _SURNAMES.size()]],
		"quality": quality,
		"wage": wage_for(role, quality),
	}


## A fresh pool of `count` available staff (ids from `first_id`), spread across the roles so
## there is always something to hire in each.
static func generate_pool(rng: RandomNumberGenerator, first_id: int, count: int) -> Array:
	var out: Array = []
	for i in maxi(0, count):
		var role: String = ROLES[i % ROLES.size()]
		out.append(make_candidate(rng, first_id + i, role))
	return out


## Yearly wage for a role at a quality (1-5).
static func wage_for(role: String, quality: int) -> int:
	var d: Dictionary = _DEF.get(role, _DEF[TRAINER])
	return int(d["wage_base"]) + clampi(quality, QUALITY_LO, QUALITY_HI) * int(d["wage_step"])


# ---- effect factors ------------------------------------------------------

## Sum of the quality of every hired member in `role`.
static func _quality_in(staff: Array, role: String) -> int:
	var q := 0
	for m in staff:
		if str(m.get("role", "")) == role:
			q += int(m.get("quality", 0))
	return q


## Generic factor for a role: lo/hi-clamped 1.0 +/- step * total_quality. For the physio the
## def's step pulls DOWNWARD (lo < 1.0) so more/better physios mean fewer injuries.
static func _factor(staff: Array, role: String) -> float:
	var d: Dictionary = _DEF[role]
	var q := _quality_in(staff, role)
	var raw := 1.0 + (1.0 if float(d["lo"]) >= 1.0 else -1.0) * float(d["step"]) * q
	return clampf(raw, float(d["lo"]), float(d["hi"]))


## Development multiplier from the training staff (>= 1.0; feeds Training.train_week).
static func training_factor(staff: Array) -> float:
	return _factor(staff, TRAINER)

## Injury-risk multiplier from the physios (<= 1.0; multiplies the training injury mult).
static func physio_factor(staff: Array) -> float:
	return _factor(staff, PHYSIO)

## Youth multiplier from the youth coach (>= 1.0; feeds Youth.intake + Youth.develop_week).
static func youth_factor(staff: Array) -> float:
	return _factor(staff, YOUTH_COACH)


# ---- automation hooks (scout / assistant) --------------------------------

## Highest quality among hired members of `role` (0 if none).
static func _best_quality(staff: Array, role: String) -> int:
	var q := 0
	for m in staff:
		if str(m.get("role", "")) == role:
			q = maxi(q, int(m.get("quality", 0)))
	return q

static func has_scout(staff: Array) -> bool:
	return _best_quality(staff, SCOUT) > 0

## How many transfer targets the scout will surface (= his quality, 1-5).
static func scout_quality(staff: Array) -> int:
	return _best_quality(staff, SCOUT)

static func has_assistant(staff: Array) -> bool:
	return _best_quality(staff, ASSISTANT) > 0

## The assistant's quality (1-5): the CA bar above which he auto-renews an expiring player
## scales with it, so a better assistant protects more of your squad.
static func assistant_quality(staff: Array) -> int:
	return _best_quality(staff, ASSISTANT)


# ---- wages ---------------------------------------------------------------

## Total YEARLY staff wage bill.
static func yearly_wage(staff: Array) -> int:
	var w := 0
	for m in staff:
		w += int(m.get("wage", 0))
	return w

## Weekly staff wage bill (deducted from cash each week).
static func weekly_wage(staff: Array) -> int:
	return int(round(yearly_wage(staff) / float(SEASON_WEEKS)))

## The COMPENSATIONS OF CONTRACT pay-off for sacking a member (a few weeks' wage).
static func sack_cost(member: Dictionary) -> int:
	return int(round(int(member.get("wage", 0)) / float(SEASON_WEEKS) * SACK_WEEKS))


# ---- queries (for the screen) --------------------------------------------

static func members_in_role(staff: Array, role: String) -> Array:
	return staff.filter(func(m): return str(m.get("role", "")) == role)

static func icon_for(role: String) -> String:
	return str((_DEF.get(role, _DEF[TRAINER]) as Dictionary).get("icon", "emple3"))

static func blurb_for(role: String) -> String:
	return str((_DEF.get(role, _DEF[TRAINER]) as Dictionary).get("blurb", ""))

## A short "+12% dev" / "-18% injuries" / "+15% youth" effect label for a role at a factor.
static func effect_label(role: String, factor: float) -> String:
	var pct := int(round((factor - 1.0) * 100.0))
	match role:
		PHYSIO:
			return "%d%% injuries" % pct   # pct is negative (factor < 1)
		YOUTH_COACH:
			return "+%d%% youth" % pct
		_:
			return "+%d%% dev" % pct
