class_name Youth
extends RefCounted
## The Youth Team, ported from MANAGER.EXE rather than invented (2026-07-25).
##
## The academy is DATA, not a generator. EQUIPOS.PKF ships `EQ969956.DBC` — engine club
## id **0x26e4**, the pool the game calls "Young players" (51 real records with names,
## birthplaces and ratings; app club id 1383). Everything the youth part does is one of
## four binary rules:
##
##  1. **The knock-down** — `FUN_005820f0` @0x582434: any record loaded under club 0x26e4
##     has ONE `rand(11)+0x23` (35..45) subtracted from all ten LIVE attribute bytes,
##     floored at 0. BASE is untouched. So a youngster's ceiling is his own shipped adult
##     rating, and the "hidden potential" this file used to roll was never needed.
##     (Applied at load in `GameDB._apply_loader_defaults`.)
##  2. **The scout's filter** — `FUN_00575d90` (youth-scout vtable 0x632fc8, slot 0):
##     the record must be in club 0x26e4, and **any one** selected capability's BASE byte
##     must be **> 0x4f**. The six criteria slots (+0x10..+0x24) are, in order,
##     BASE +0xae/+0xb1/+0xaf/+0xb2/+0xb0/+0xb3 = PO / RM / EN / RG / PA / TI =
##     HANDLING / DRIBBLING / TACKLING / HEADING / PASSING / SHOOTING.
##  3. **The search** — `FUN_00575e80` (vtable slot 1) walks club 0x26e4's player list,
##     keeps every match, and then throws all but **ONE, picked uniformly at random**
##     (`FUN_0058df90(n)`). The senior scout's `(quality+2)*5` shortlist cap is the OTHER
##     resolver (`FUN_00575750`) and does not apply here. Duration in weeks is set when
##     SEARCH is pressed, `FUN_0053e860` @0x53e967:
##         weeks = rand(6) + 0x37 - 5 * ((scout_quality_byte + 1) >> 1)
##  4. **The growth** — `FUN_00582760` case 0x20, ported in `Training.develop_youth_week`:
##     60% chance of +1 a week on every attribute, hard-stopped at BASE; when the core
##     four (VE/RE/AG/CA) all reach BASE the mode clears and the youth manager reports
##     "…is ready to be promoted to the first team squad."
##
## Signing is the shared offer path (`FUN_0058a360`), which is why the youth pseudo-club
## has its own two strings there: "%s has joined your Youth Team." on accept and
## "The youth player %s has rejected your offer." on refusal.
##
## The `_make_attrs` / `_gen_name` / `random_pos` block at the bottom is NOT the academy
## any more — it is the shared REGEN helper that `TransferMarket` (free agents) and
## `Talent` (the easter-egg lane) call, kept here so those callers keep working.

## The EQUIPOS club the youth pool ships under: `EQ969956.DBC`, engine id 0x26e4,
## remapped to 1383 by tools/extract_squads_exact.py. Mirrors GameDB.YOUTH_POOL_CLUB
## (an autoload cannot be read from a const initialiser).
const POOL_CLUB_ID := 1383

## `FUN_00575d90`: capability -> the BASE attribute byte it gates, and the threshold
## (`0x4f < byte`, so 80 and up). The labels are the YOUTH screen's own `cap_order`
## names; the attribute map is the one the TRAINING modes independently pin
## (docs/re/training_screen_re.md: HANDLING->PO, PASSING->PA, DRIBBLING->RM,
## HEADING->RG, TACKLING->EN, SHOOTING->TI).
const CAP_ATTR := {
	"HANDLING": "PO", "DRIBBLING": "RM", "TACKLING": "EN",
	"HEADING": "RG", "PASSING": "PA", "SHOOTING": "TI",
}
const CAP_THRESHOLD := 0x50       # `0x4f < base[attr]`

## `FUN_0053e860` @0x53e967: weeks = rand(6) + 0x37 - 5 * ((quality + 1) >> 1).
const SEARCH_BASE_WEEKS := 0x37
const SEARCH_SPAN := 6
const SEARCH_PER_STAR := 5
## OURS, and the only youth number that is: the owner's standing Android call
## (2026-07-24 owner report) is "it's ok to lower the amount of weeks it takes so we
## have 2 intakes per season". The original's own 30..60 weeks is one intake a season
## at best. Halving it is the whole deviation; set to 1 for the binary's own cadence.
const SEARCH_SPEEDUP := 2

# The age a youngster is released at if never promoted, and the soft cap on the setup.
const INTAKE_AGE_LO := 15
const INTAKE_AGE_HI := 17
const GRADUATE_AGE := 19          # over this and not promoted -> released from the setup
const SQUAD_CAP := 12             # the youth team won't grow past this

# Regen-lane constants (free agents + the talent easter egg), NOT the academy.
const READY_CA := 58
const INTAKE_CA_LO := 30
const INTAKE_CA_HI := 46
const POTENTIAL_LO := 8
const POTENTIAL_HI := 42
const POTENTIAL_CAP := 88

# The hidden gem (easter egg): a guaranteed generational FW the academy scouts in within a
# career's first few seasons. Potential sits ABOVE the regen cap -- a one-in-a-generation
# talent, not an ordinary intake. Planted by Career._ensure_wonderkid().
const WONDERKID_NAME := "MATS MJÅTVEDT"
const WONDERKID_POTENTIAL := 99

const GK_CHANCE := 0.16           # roughly one in six intakes is a goalkeeper
# Outfield position split for generated players, weighted to the real squad balance
# decoded from EQUIPOS.PKF (DF 677 / MF 598 / FW 481 across the English pyramid).
const _DF_SHARE := 0.38
const _MF_SHARE := 0.33           # remainder (0.29) is FW

const ATTR_FLOOR := 20

# The trainable attribute codes (PO tracks separately for keepers, like Training).
const _OUTFIELD_CODES := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN"]

# Generated names come from the game's OWN tables (DBDAT/NOMBRES.30 + APELLIDO.30 via
# Staff.name_pools() -> res://data/name_pools.json) — the tables the original's staff-hire
# candidates were proven to draw from (docs/re/staff_re.md, 2026-07-18). "Forename Surname",
# the tables' own casing.
static func _gen_name(rng: RandomNumberGenerator) -> String:
	var p: Dictionary = Staff.name_pools()
	var fores: Array = p["forenames"]
	var surs: Array = p["surnames"]
	return "%s %s" % [fores[rng.randi() % fores.size()], surs[rng.randi() % surs.size()]]


# ---- REGEN LANE (free agents + the talent easter egg) --------------------
#
# NOT the academy. `TransferMarket.generate_free_agents` and `Talent` call these to mint
# a player who has no EQUIPOS record; the numbers below are OURS and always were. The
# real youth pool is `pool()` above and is entirely shipped data.

## Generate `count` fresh players with ids starting at `first_id` (the caller's monotonic
## id minter -- kept well above the senior id space so a mint never collides).
## `factor` (>= 1.0) nudges the quality of the crop. Never touches GameDB.
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
		"name": _gen_name(rng),
		"age": rng.randi_range(INTAKE_AGE_LO, INTAKE_AGE_HI),
		"isGK": is_gk,
		"pos": random_pos(rng, is_gk),
		"attrs": _make_attrs(rng, ca, is_gk),
		"potential": potential,
		"dev_progress": 0.0,
		"ready": false,
		"is_youth": true,
	}


## The guaranteed wonderkid: a 16-year-old striker with first-team ability already and a
## generational ceiling (potential above the regen cap). `ready` is true so the youth
## manager flags him for promotion straight away. Same dict shape as any youth/senior, so
## every screen (youth team, squad, line-up, value) reads him with no special-casing.
static func make_wonderkid(id: int) -> Dictionary:
	return {
		"id": id,
		"name": WONDERKID_NAME,
		"age": 16,
		"isGK": false,
		"pos": "FW",
		"attrs": {
			"VE": 84, "RE": 82, "AG": 86, "CA": 80, "RM": 88,
			"RG": 80, "PA": 85, "TI": 80, "EN": 84, "PO": 22,
		},
		"potential": WONDERKID_POTENTIAL,
		"dev_progress": 0.0,
		"ready": true,
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


# ---- the shipped pool + the scout (FUN_00575d90 / FUN_00575e80 / FUN_0053e860) ----

## The live youth pool out of a `clubs_by_id` map (GameDB's, or a test's): every player
## loaded under club 0x26e4, already knocked down by the loader. Returns the SAME dicts
## the map holds, so signing one and mutating him is what the engine does with its own
## record. Passed in rather than reached for, so this file stays headless-testable.
static func pool_of(clubs_by_id: Dictionary) -> Array:
	var c: Dictionary = clubs_by_id.get(POOL_CLUB_ID, {})
	var ps: Variant = c.get("players", [])
	return ps if ps is Array else []


## `FUN_005820f0` @0x582434 — the club-0x26e4 branch of the DBC player loader, which
## rolls ONE `rand(11) + 0x23` (35..45) and subtracts it from all TEN live attribute
## bytes (+0x9c..+0xa5), flooring at 0, leaving BASE (+0xaa..+0xb3) alone. `attrs_base`
## keeps the shipped block; `attrs` becomes the knocked-down live one. Idempotent — a
## record that already carries `attrs_base` has been through this.
const DEGRADE_LO := 0x23
const DEGRADE_SPAN := 0xb

static func degrade(p: Dictionary, rng: RandomNumberGenerator) -> void:
	var av: Variant = p.get("attrs")
	if not (av is Dictionary) or p.has("attrs_base"):
		return
	var d := DEGRADE_LO + rng.randi_range(0, DEGRADE_SPAN - 1)
	var live: Dictionary = av
	p["attrs_base"] = live.duplicate()
	for k in live:
		var v := int(live[k])
		live[k] = (v - d) if d < v else 0


## `FUN_00575d90`. `caps` is the set of capability names the six LEDs have lit. A record
## matches when ANY lit capability's BASE byte is > 0x4f — the predicate short-circuits
## on the first hit, so it is a plain OR, not a score.
static func scout_matches(p: Dictionary, caps: Array) -> bool:
	var base: Dictionary = Training.base_attrs(p)
	for cap in caps:
		var code := str(CAP_ATTR.get(str(cap), ""))
		if code != "" and int(base.get(code, 0)) >= CAP_THRESHOLD:
			return true
	return false


## `FUN_00575e80`. Filter `pool`, then keep exactly ONE at random. `exclude` is the ids
## already signed (the engine drops a signed youngster out of club 0x26e4, so he can
## never be found twice). Returns [] or a one-element Array — the PLAYERS FOUND panel.
static func scout_search(rng: RandomNumberGenerator, caps: Array, pool: Array,
		exclude: Array = []) -> Array:
	var hits: Array = []
	for p in pool:
		if int(p.get("id", -1)) in exclude:
			continue
		if scout_matches(p, caps):
			hits.append(p)
	if hits.is_empty():
		return []
	# A DEEP COPY, not the GameDB record itself: the engine re-parents its own record
	# because it reloads the database for every new game, but GameDB here is loaded once
	# per app launch and shared by every career. Handing out the live dict would leave a
	# signed youngster's clubId / ready / part-grown attrs stuck on the pool for the next
	# career. The copy is what `enrol` then stamps.
	return [(hits[rng.randi_range(0, hits.size() - 1)] as Dictionary).duplicate(true)]


## `FUN_0053e860` @0x53e967, divided by the owner's SEARCH_SPEEDUP.
## `quality` is the YOUTH TEAM SCOUT's raw 1..10 quality byte (Staff.quality_byte).
static func search_weeks(rng: RandomNumberGenerator, quality: int) -> int:
	var w := rng.randi_range(0, SEARCH_SPAN - 1) \
		+ SEARCH_BASE_WEEKS - SEARCH_PER_STAR * ((quality + 1) >> 1)
	return maxi(1, int(ceil(float(w) / float(SEARCH_SPEEDUP))))


## Stamp a pool record as a member of YOUR youth setup: the engine moves him out of club
## 0x26e4 and turns his training mode to 0x20, which is all "being in the academy" is.
static func enrol(p: Dictionary, club_id: int) -> Dictionary:
	p["clubId"] = club_id
	p["is_youth"] = true
	p["ready"] = false
	p["_from_youth_pool"] = 1   # so the scout never re-finds him after a promotion
	Training.base_attrs(p)      # make sure BASE exists before he starts climbing
	return p


# ---- weekly development --------------------------------------------------

## One week of `FUN_00582760`'s 0x20 YOUTH branch (ported in Training.develop_youth_week):
## 60% chance of +1 on every attribute, stopped dead at the player's own shipped BASE;
## when the core four reach BASE the youth manager reports him ready. `factor` is
## accepted for call-site compatibility and deliberately unused — the original's youth
## growth has no staff term.
static func develop_week(rng: RandomNumberGenerator, youth: Array, _factor := 1.0) -> Array:
	return Training.develop_youth_week(rng, youth)


# ---- queries (for the screen + Career) -----------------------------------

static func is_ready(p: Dictionary) -> bool:
	return bool(p.get("ready", false))


## Current ability (CA) for a youth -- his headline rating on the screen.
static func ability(p: Dictionary) -> int:
	var attrs: Variant = p.get("attrs", {})
	return int((attrs as Dictionary).get("CA", 0)) if attrs is Dictionary else 0


## His ceiling: the shipped BASE CA the loader knocked him down from. The regen lane
## (free agents, talents) still carries an explicit `potential`, so honour that first.
static func potential_of(p: Dictionary) -> int:
	if p.has("potential"):
		return int(p["potential"])
	return int(Training.base_attrs(p).get("CA", ability(p)))


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
