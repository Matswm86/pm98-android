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
## are the ORIGINAL's.
##
## CANDIDATE POOLS (real, 2026-07-18 — docs/re/staff_re.md "The real candidate pools"):
## the original's hire lists were witnessed across TWO careers (Man Utd run1 frames 095-120,
## Bolton wine 56-59): every role — each of the six trainer SKILLS included — has its OWN
## 3-candidate pool, a signed candidate is REMOVED and the rows shift up WITHIN the week,
## list order is generation order (NOT rating-sorted), and wages are
## PER-CANDIDATE (three 3.0-star trainers at £16k/£17k/£19k; 5.0-star trainers £47k one
## career, £52k the other). Names come from the game's OWN tables — all 43 witnessed
## candidate surnames are rows of DBDAT/APELLIDO.30 (incl. the escape-byte "O'brian"),
## exported with the forename table to res://data/name_pools.json. Candidate wages here
## are drawn from _WAGE_ANCHORS: the exact witnessed (stars -> wage) points per role,
## interpolated between anchors — the original's generator itself is un-RE'd, so anything
## BETWEEN witnessed points is fitted, never asserted. **The refill cadence is no longer
## un-witnessed: the whole list is REGENERATED EVERY WEEK** (witnessed live 2026-07-24
## across weeks 1/3/4 of one Bolton career — three new names and a new star spread each
## time, and identical on a same-week reopen). Career._refresh_staff_pool does it.
##
## PM98's staff EFFECTS are data-driven (loaded from the save, un-RE'd), so the effect
## numerics below are OURS -- only the surface + pool mechanics above are PM98's. Roles
## with a clean hook into the existing engine carry an effect (trainers -> development,
## physio -> injuries, youth manager -> academy, scout / assistant -> automation);
## PSYCHOLOGIST / YOUTH_TEAM_SCOUT / GROUNDSMAN are hireable but their engine effect is an
## HONEST GAP (no decoded source data), so they are no-ops -- never invent a number for them.
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

# Role blurbs for the effect hooks (the app's own UI hint text, not original strings).
const _DEF := {
	PHYSIOTHERAPIST: {"blurb": "cuts injury risk"},
	PSYCHOLOGIST: {"blurb": "boosts morale (no engine effect yet)"},
	ASSISTANT_MANAGER: {"blurb": "auto-renews your stars"},
	SCOUT_ROLE: {"blurb": "finds transfer targets"},
	YOUTH_TEAM_MANAGER: {"blurb": "talks prospects into signing"},
	YOUTH_TEAM_SCOUT: {"blurb": "searches for youth players; better = faster"},
	GROUNDSMAN: {"blurb": "keeps the pitch (no engine effect yet)"},
}

# WITNESSED wage anchors: every (stars -> yearly wage) pair read off the original's own
# hire lists (Man Utd run1 frames 095-121 + Bolton wine 56-59, docs/re/staff_re.md).
# [stars, lo, hi] — lo==hi where one value was witnessed, a band where several were
# (e.g. 3.0-star trainers £16k Mitchell / £17k Padmore / £19k Swann+Robinson). wage_for
# interpolates between a role's own anchors; the six trainer skills share one class (the
# same STAFF AVAILABLE list UI serves all six, and the two careers' trainer wages lie on
# one curve). Values between/beyond anchors are FITTED — the exe's generator is un-RE'd.
const _WAGE_ANCHORS := {
	"TRAINER": [
		[1.0, 3000, 4000], [1.5, 5000, 6000], [2.5, 12000, 13000], [3.0, 16000, 19000],
		[3.5, 21000, 21000], [4.0, 27000, 27000], [4.5, 33000, 41000], [5.0, 47000, 52000],
	],
	PHYSIOTHERAPIST: [[2.0, 9000, 9000], [3.0, 16000, 16000], [5.0, 45000, 45000]],
	PSYCHOLOGIST: [[2.0, 6000, 6000], [4.5, 15000, 15000]],
	ASSISTANT_MANAGER: [[2.0, 7000, 7000], [2.5, 9000, 9000], [4.0, 16000, 16000]],
	SCOUT_ROLE: [
		[1.0, 4000, 4000], [1.5, 6000, 6000], [2.0, 8000, 8000],
		[3.0, 20000, 20000], [4.5, 45000, 45000],
	],
	YOUTH_TEAM_MANAGER: [[2.5, 12000, 12000], [3.0, 20000, 20000], [3.5, 21000, 21000]],
	YOUTH_TEAM_SCOUT: [[1.5, 6000, 7000], [5.0, 36000, 36000]],
	GROUNDSMAN: [[1.0, 1000, 1000], [3.0, 2000, 2000], [4.5, 4000, 4000]],
}

const QUALITY_LO := 1
const QUALITY_HI := 5
const STARS_LO := 1.0
const STARS_HI := 5.0
const SEASON_WEEKS := 52   # wages are yearly; weekly = / SEASON_WEEKS (matches FinanceModel)
const SACK_WEEKS := 8      # COMPENSATIONS OF CONTRACT: sacking pays this many weeks' wage

# The ORIGINAL name tables (DBDAT/NOMBRES.30 + APELLIDO.30, XOR-0x61 DMLT records),
# exported verbatim by tools/re/export_staff_names.py. All 43 witnessed hire-list
# surnames (Padmore, Gelbier, Jumblat, Debnam, O'brian, Savage, ...) are rows here.
const _NAME_POOLS_PATH := "res://data/name_pools.json"
static var _name_pools: Dictionary = {}

static func name_pools() -> Dictionary:
	if _name_pools.is_empty():
		var f := FileAccess.open(_NAME_POOLS_PATH, FileAccess.READ)
		assert(f != null, "name_pools.json missing")
		var d: Variant = JSON.parse_string(f.get_as_text())
		assert(d is Dictionary and not (d as Dictionary).is_empty(), "name_pools.json bad")
		_name_pools = d
	return _name_pools


# ---- role helpers --------------------------------------------------------

static func is_trainer(role: String) -> bool:
	return role in TRAINER_SKILLS

## The category a role belongs to on the hire rail ("TRAINERS" for the six skills, else the
## role itself).
static func category_of(role: String) -> String:
	return "TRAINERS" if is_trainer(role) else role

static func label_for(role: String) -> String:
	return str(_LABEL.get(role, role))


# ---- the engine's raw quality byte ---------------------------------------
# A staff record's `+1` byte is a 1..10 quality the game shows as `q / 2` half-stars,
# and every per-role capability the engine derives (FUN_00578b80) is keyed off it, NOT
# off the displayed star count. Verified live 2026-07-24: a 4.5-star physio (q = 9)
# reports "5 PLAYERS" on the INJURIES band, which is exactly FUN_00578b80's case 6
# ladder (q<3 -> 1, <5 -> 2, <7 -> 3, <9 -> 4, else 5).

const QUALITY_BYTE_HI := 10

## The engine's raw 1..10 quality byte for a hired member (stars x 2).
static func quality_byte(member: Dictionary) -> int:
	if member.is_empty():
		return 0
	return clampi(int(round(float(member.get("stars", 0.0)) * 2.0)), 0, QUALITY_BYTE_HI)


## FUN_00578b80 case 6 — how many injured players a PHYSIOTHERAPIST can treat at once
## ("N PLAYERS" on the INJURIES band).
static func physio_capacity(member: Dictionary) -> int:
	var q := quality_byte(member)
	if q <= 0:
		return 0
	if q < 3:
		return 1
	if q < 5:
		return 2
	if q < 7:
		return 3
	if q < 9:
		return 4
	return 5

## An "A. Padmore" style forename-initial + surname — the witnessed hire-list format —
## drawn from the game's OWN name tables (name_pools.json). Surnames keep their table
## bytes exactly ("O'brian", "Mcgrath" — the original's own casing).
static func _short_name(rng: RandomNumberGenerator) -> String:
	var p := name_pools()
	var fores: Array = p["forenames"]
	var surs: Array = p["surnames"]
	var fore: String = fores[rng.randi() % fores.size()]
	var sur: String = surs[rng.randi() % surs.size()]
	return "%s. %s" % [fore.substr(0, 1), sur]


# ---- candidate generation ------------------------------------------------

## Half-star rating (1.0 .. 5.0 in 0.5 steps), the witnessed display granularity — the
## engine's raw 1..10 quality byte read as `q / 2` (Staff.quality_byte). The
## DISTRIBUTION is FITTED (uniform is consistent with the 57 witnessed candidates,
## range 1.0-5.0); the original's generator is un-RE'd. What IS witnessed is the range
## and that a fresh weekly pool routinely offers 4.5-5.0 star staff — see
## Career._refresh_staff_pool.
static func _rand_stars(rng: RandomNumberGenerator) -> float:
	return rng.randi_range(2, 10) * 0.5   # 1.0 .. 5.0 in half steps

## A hireable staff candidate for `role` with a half-star rating + a wage drawn from the
## witnessed anchor curve (per-candidate, like the original's — see _WAGE_ANCHORS).
static func make_candidate(rng: RandomNumberGenerator, id: int, role: String) -> Dictionary:
	var stars := _rand_stars(rng)
	return {
		"id": id,
		"role": role,
		"name": _short_name(rng),
		"stars": stars,
		"quality": clampi(int(round(stars)), QUALITY_LO, QUALITY_HI),
		"wage": wage_for(role, stars, rng),
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


## Yearly wage for a role at a rating (accepts a 1-5 int quality or a 0.5-step star float),
## from the WITNESSED anchor curve: exact at witnessed points, piecewise-linear between
## them, end-slope beyond. Where several wages were witnessed at one rating the anchor is
## a band — `rng` picks within it (per-candidate wages, as witnessed); without `rng` the
## band midpoint is returned. Snapped to £1,000 (every witnessed wage is a round £1,000).
static func wage_for(role: String, rating: float, rng: RandomNumberGenerator = null) -> int:
	var anchors: Array = _WAGE_ANCHORS["TRAINER"] if is_trainer(role) \
		else _WAGE_ANCHORS.get(role, _WAGE_ANCHORS["TRAINER"])
	var stars := clampf(rating, STARS_LO, STARS_HI)
	var lo := 0.0
	var hi := 0.0
	var first: Array = anchors[0]
	var last: Array = anchors[anchors.size() - 1]
	if stars <= float(first[0]) or anchors.size() == 1:
		# Below the first witnessed point: scale down along the ray from the origin.
		var t := stars / float(first[0])
		lo = float(first[1]) * t
		hi = float(first[2]) * t
	elif stars >= float(last[0]):
		# Above the last witnessed point: continue the last segment's slope.
		var prev: Array = anchors[anchors.size() - 2]
		var span := float(last[0]) - float(prev[0])
		var t2 := (stars - float(last[0])) / span
		lo = float(last[1]) + (float(last[1]) - float(prev[1])) * t2
		hi = float(last[2]) + (float(last[2]) - float(prev[2])) * t2
	else:
		for i in range(anchors.size() - 1):
			var a: Array = anchors[i]
			var b: Array = anchors[i + 1]
			if stars >= float(a[0]) and stars <= float(b[0]):
				var t3 := (stars - float(a[0])) / (float(b[0]) - float(a[0]))
				lo = lerpf(float(a[1]), float(b[1]), t3)
				hi = lerpf(float(a[2]), float(b[2]), t3)
				break
	var w := (lo + hi) / 2.0 if rng == null else rng.randf_range(lo, hi)
	return maxi(1000, int(round(w / 1000.0)) * 1000)


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

## Candidates in the pool for `role`, in generation order — the witnessed "<ROLE>s
## AVAILABLE" lists are NOT rating-sorted (run1 HANDLING: 1.5 / 3.0 / 1.0 stars,
## YOUTH MANAGERS: 3.5 / 2.5 / 3.0), and after a signing the remaining rows keep
## their order and shift up.
static func pool_for_role(pool: Array, role: String) -> Array:
	return pool.filter(func(m): return str(m.get("role", "")) == role)

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
