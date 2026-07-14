class_name Staff
extends RefCounted
## The backroom staff (EMPLE / CLUB PERSONNEL), rebuilt to the REAL game's 13 single-
## occupancy roles (witnessed frames 100 + 108-121, docs/re/staff_re.md). Each role holds
## exactly ONE member; you sign them from a per-role pool of candidates and pay their wages
## each week; sacking one costs a compensation (the contract pay-off).
##
## THE 13 ROLES (frame 121, transcribed pixel-by-pixel):
##   - 6 TRAINER skill slots: HANDLING / PASSING / DRIBBLING / HEADING / TACKLING / SHOOTING
##   - PHYSIOTHERAPIST / PSYCHOLOGIST / ASSISTANT_MANAGER / SCOUT / YOUTH_TEAM_MANAGER /
##     YOUTH_TEAM_SCOUT / GROUNDSMAN
## The TRAINERS category (frame 100) shows all 6 skill holders at once + a skill picker; the
## other 7 each open a single-role hire overlay (frames 108-119).
##
## Faithful SURFACE (strings scanned from MANAGER.EXE): STAFF / STAFF WAGES / STAFF AVAILABLE
## / CURRENT TRAINING STAFF / TRAINER(S) / TRAINING STAFF / PHYSIO. / PHYSIOTHERAPIST(S) /
## PSYCHOLOGIST / SCOUT(S) / YOUTH TEAM SCOUT / YOUTH (TEAM) MANAGER / ASSISTANT MANAGER /
## GROUNDSMAN, SIGN / SACK, WAGE, COMPENSATIONS OF CONTRACT, "Are you sure you want to sack
## him ?", "1 member of staff" / "%d members of staff", "you have to have hired trainers.",
## "you need to hire an Assistant."  The 13 role slots + half-star ratings + single-occupancy
## are the ORIGINAL's; PM98's staff EFFECTS + WAGES are data-driven (loaded from the save,
## un-RE'd), so the numeric model below is OURS -- only the surface is PM98's. Roles with a
## clean hook into the existing engine carry an effect (trainers -> development, physio ->
## injuries, youth manager -> academy, scout / assistant -> automation); PSYCHOLOGIST /
## YOUTH_TEAM_SCOUT / GROUNDSMAN are hireable but their engine effect is an HONEST GAP (no
## decoded source data), so they are no-ops -- never invent a number for them.
##
## GameDB-free, pure functions over plain dicts -> headless-testable (tests/test_staff.gd).

# ---- the 13 roles --------------------------------------------------------

const HANDLING := "HANDLING"
const PASSING := "PASSING"
const DRIBBLING := "DRIBBLING"
const HEADING := "HEADING"
const TACKLING := "TACKLING"
const SHOOTING := "SHOOTING"
const PHYSIOTHERAPIST := "PHYSIOTHERAPIST"
const PSYCHOLOGIST := "PSYCHOLOGIST"
const ASSISTANT_MANAGER := "ASSISTANT_MANAGER"
const SCOUT_ROLE := "SCOUT"
const YOUTH_TEAM_MANAGER := "YOUTH_TEAM_MANAGER"
const YOUTH_TEAM_SCOUT := "YOUTH_TEAM_SCOUT"
const GROUNDSMAN := "GROUNDSMAN"

# The six skill coaches, in frame-121 CLUB PERSONNEL order (left col then right col).
const TRAINER_SKILLS := [HANDLING, PASSING, DRIBBLING, HEADING, TACKLING, SHOOTING]

# All 13 role keys (the keys StaffScreen's personnel_chrome.json expects).
const ROLE_KEYS := [
	HANDLING, PASSING, DRIBBLING, HEADING, TACKLING, SHOOTING,
	PHYSIOTHERAPIST, PSYCHOLOGIST, ASSISTANT_MANAGER, SCOUT_ROLE,
	YOUTH_TEAM_MANAGER, YOUTH_TEAM_SCOUT, GROUNDSMAN,
]
const ROLES := ROLE_KEYS   # kept: old tests read Staff.ROLES

# --- back-compat aliases (external code + tests reference these names) ---
const PHYSIO := PHYSIOTHERAPIST
const SCOUT := SCOUT_ROLE
const ASSISTANT := ASSISTANT_MANAGER
const YOUTH_COACH := YOUTH_TEAM_MANAGER
const TRAINER := HANDLING   # legacy alias; trainers are now the six TRAINER_SKILLS

# The 8 hire-overlay categories (right-hand rail, frame 113 top-to-bottom). TRAINERS expands
# to the six skill sub-trainers; the rest map 1:1 to a role.
const CATEGORIES := [
	"TRAINERS", PHYSIOTHERAPIST, PSYCHOLOGIST, ASSISTANT_MANAGER, SCOUT_ROLE,
	YOUTH_TEAM_MANAGER, YOUTH_TEAM_SCOUT, GROUNDSMAN,
]

# Human labels (the original's on-screen spelling), for headers like "CURRENT ASS. MANAGER".
const _LABEL := {
	HANDLING: "HANDLING", PASSING: "PASSING", DRIBBLING: "DRIBBLING",
	HEADING: "HEADING", TACKLING: "TACKLING", SHOOTING: "SHOOTING",
	PHYSIOTHERAPIST: "PHYSIOTHERAPIST", PSYCHOLOGIST: "PSYCHOLOGIST",
	ASSISTANT_MANAGER: "ASS. MANAGER", SCOUT_ROLE: "SCOUT",
	YOUTH_TEAM_MANAGER: "YOUTH MANAGER", YOUTH_TEAM_SCOUT: "YOUTH SCOUT",
	GROUNDSMAN: "GROUNDSMAN",
}

# Per-role tuning. wage = wage_base + round(stars * wage_step) (a seasonal wage; OURS).
# effect params (step/lo/hi) apply only to the four effect-bearing hooks; the rest are wage-
# only (HONEST GAP -- no engine effect, never invented).
const _DEF := {
	HANDLING: {"wage_base": 6000, "wage_step": 7000},
	PASSING: {"wage_base": 6000, "wage_step": 7000},
	DRIBBLING: {"wage_base": 6000, "wage_step": 7000},
	HEADING: {"wage_base": 6000, "wage_step": 7000},
	TACKLING: {"wage_base": 6000, "wage_step": 7000},
	SHOOTING: {"wage_base": 6000, "wage_step": 7000},
	PHYSIOTHERAPIST: {"wage_base": 8000, "wage_step": 8000, "blurb": "cuts injury risk"},
	PSYCHOLOGIST: {"wage_base": 4000, "wage_step": 3000, "blurb": "boosts morale (no engine effect yet)"},
	ASSISTANT_MANAGER: {"wage_base": 5000, "wage_step": 4000, "blurb": "auto-renews your stars"},
	SCOUT_ROLE: {"wage_base": 8000, "wage_step": 8000, "blurb": "finds transfer targets"},
	YOUTH_TEAM_MANAGER: {"wage_base": 6000, "wage_step": 4000, "blurb": "improves the academy"},
	YOUTH_TEAM_SCOUT: {"wage_base": 6000, "wage_step": 7000, "blurb": "scouts youngsters (no engine effect yet)"},
	GROUNDSMAN: {"wage_base": 1000, "wage_step": 800, "blurb": "keeps the pitch (no engine effect yet)"},
}

const QUALITY_LO := 1
const QUALITY_HI := 5
const STARS_LO := 1.0
const STARS_HI := 5.0
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


# ---- role helpers --------------------------------------------------------

static func is_trainer(role: String) -> bool:
	return role in TRAINER_SKILLS

## The category a role belongs to on the hire rail ("TRAINERS" for the six skills, else the
## role itself).
static func category_of(role: String) -> String:
	return "TRAINERS" if is_trainer(role) else role

static func label_for(role: String) -> String:
	return str(_LABEL.get(role, role))

## An "A. Name" style forename-initial + surname, matching the original's short staff names.
static func _short_name(rng: RandomNumberGenerator) -> String:
	var fore: String = _FORENAMES[rng.randi() % _FORENAMES.size()]
	var sur: String = _SURNAMES[rng.randi() % _SURNAMES.size()]
	return "%s. %s" % [fore.substr(0, 1), sur.capitalize()]


# ---- candidate generation ------------------------------------------------

## Half-star rating (1.0 .. 5.0 in 0.5 steps), the witnessed display granularity.
static func _rand_stars(rng: RandomNumberGenerator) -> float:
	return rng.randi_range(2, 10) * 0.5   # 1.0 .. 5.0 in half steps

## A hireable staff candidate for `role` with a random half-star rating + matching wage.
static func make_candidate(rng: RandomNumberGenerator, id: int, role: String) -> Dictionary:
	var stars := _rand_stars(rng)
	return {
		"id": id,
		"role": role,
		"name": _short_name(rng),
		"stars": stars,
		"quality": clampi(int(round(stars)), QUALITY_LO, QUALITY_HI),
		"wage": wage_for(role, stars),
	}


## A fresh pool of candidates: `per_role` for every one of the 13 roles (ids from `first_id`),
## so each hire category always has something to sign.
static func generate_pool(rng: RandomNumberGenerator, first_id: int, per_role: int = 3) -> Array:
	var out: Array = []
	var n := 0
	for role in ROLE_KEYS:
		for _i in maxi(0, per_role):
			out.append(make_candidate(rng, first_id + n, role))
			n += 1
	return out


## Yearly wage for a role at a rating (accepts a 1-5 int quality or a 0.5-step star float).
static func wage_for(role: String, rating: float) -> int:
	var d: Dictionary = _DEF.get(role, _DEF[HANDLING])
	var stars := clampf(rating, STARS_LO, STARS_HI)
	return int(d["wage_base"]) + int(round(stars * float(d["wage_step"])))


# ---- rating access (members may carry `stars` float and/or `quality` int) --

static func _stars_of(m: Dictionary) -> float:
	if m.has("stars"):
		return float(m["stars"])
	return float(m.get("quality", 0))

static func _quality_of(m: Dictionary) -> int:
	if m.has("quality"):
		return int(m["quality"])
	return int(round(_stars_of(m)))

## The single member hired in `role` ({} if the slot is vacant).
static func member_in_role(staff: Array, role: String) -> Dictionary:
	for m in staff:
		if str(m.get("role", "")) == role:
			return m
	return {}

## Half-star rating of the holder in `role` (0.0 if vacant).
static func _role_stars(staff: Array, role: String) -> float:
	var m := member_in_role(staff, role)
	return _stars_of(m) if not m.is_empty() else 0.0


# ---- effect factors ------------------------------------------------------

## Development multiplier from the training staff (>= 1.0; feeds Training.train_week). Scales
## with how much of the six-skill coaching bench is filled and how good they are: a full bench
## of 5-star coaches gives the cap, a single coach a small slice.
static func training_factor(staff: Array) -> float:
	var total := 0.0
	for role in TRAINER_SKILLS:
		total += _role_stars(staff, role)
	return clampf(1.0 + 0.10 * (total / float(TRAINER_SKILLS.size())), 1.0, 1.5)

## Injury-risk multiplier from the physio (<= 1.0; multiplies the training injury mult). A
## 5-star physio pulls it to the floor; no physio leaves it at 1.0.
static func physio_factor(staff: Array) -> float:
	return clampf(1.0 - 0.09 * _role_stars(staff, PHYSIOTHERAPIST), 0.55, 1.0)

## Youth multiplier from the youth team manager (>= 1.0; feeds Youth.intake + develop_week).
static func youth_factor(staff: Array) -> float:
	return clampf(1.0 + 0.12 * _role_stars(staff, YOUTH_TEAM_MANAGER), 1.0, 1.6)


# ---- automation hooks (scout / assistant) --------------------------------

static func has_scout(staff: Array) -> bool:
	return not member_in_role(staff, SCOUT_ROLE).is_empty()

## How many transfer targets the scout surfaces (= his quality, 1-5; 0 with no scout).
static func scout_quality(staff: Array) -> int:
	var m := member_in_role(staff, SCOUT_ROLE)
	return _quality_of(m) if not m.is_empty() else 0

static func has_assistant(staff: Array) -> bool:
	return not member_in_role(staff, ASSISTANT_MANAGER).is_empty()

## The assistant's quality (1-5): the CA bar above which he auto-renews expiring players
## scales with it, so a better assistant protects more of your squad.
static func assistant_quality(staff: Array) -> int:
	var m := member_in_role(staff, ASSISTANT_MANAGER)
	return _quality_of(m) if not m.is_empty() else 0


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


# ---- queries (for the screen + overlay) ----------------------------------

static func members_in_role(staff: Array, role: String) -> Array:
	return staff.filter(func(m): return str(m.get("role", "")) == role)

## Candidates in the pool for `role`, most able first (the "<ROLE>s AVAILABLE" list order).
static func pool_for_role(pool: Array, role: String) -> Array:
	var out: Array = pool.filter(func(m): return str(m.get("role", "")) == role)
	out.sort_custom(func(a, b): return _stars_of(a) > _stars_of(b))
	return out

## The StaffScreen `personnel` dict: role -> {name, stars, wage} for every hired slot. Vacant
## slots are simply absent (the screen draws them empty).
static func personnel_dict(staff: Array) -> Dictionary:
	var out: Dictionary = {}
	for m in staff:
		var role := str(m.get("role", ""))
		if role in ROLE_KEYS:
			out[role] = {"name": str(m.get("name", "")), "stars": _stars_of(m),
				"wage": int(m.get("wage", 0))}
	return out

static func blurb_for(role: String) -> String:
	return str((_DEF.get(role, {}) as Dictionary).get("blurb", ""))
