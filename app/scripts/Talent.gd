class_name Talent
extends RefCounted
## Real-talent injection (easter-egg lane, like the wonderkid): a season-keyed pool of
## REAL footballers who "come up" at their real club as a career rolls past 1997-98 --
## Owen-era kids at Liverpool in 1998-99, a certain Everton striker in 2002-03, and so
## on for twenty seasons. Data lives in data/talent_pool.json (loaded by TalentDB,
## curated offline by tools/talent_ingest.py from the owner's FM/CM database exports);
## no file = the feature is fully inert and the port behaves exactly as before.
##
## A pool entry is identity + a talent TIER; the 10-attr row is generated here at
## injection time in the same scheme as regen youth (Youth._make_attrs) so an injected
## player is indistinguishable in shape from any other player dict -- every screen and
## engine reads him unchanged. Ids are minted offline from TALENT_ID_BASE, a free band
## below the free-agent space, so they never collide with seniors/free/staff/youth.
##
## GameDB-free and static, like Youth/TransferMarket -> headless-testable
## (tests/test_talents.gd). Career owns the injection call sites.

const TALENT_ID_BASE := 600000    # ingest mints ids here (seniors ~8k, FREE 700000)

# Tier -> the CA a talent is headed for in his prime (age ~23, where Training.gd's
# improvement window closes). 1 = generational, 2 = world-class, 3 = elite,
# 4 = solid pro, 5 = squad player.
const TIER_PEAK := {1: 94, 2: 88, 3: 82, 4: 74, 5: 66}
const _PEAK_AGE := 23             # Training.PRIME_LO -- growth flatlines here
# Roughly what a season of Normal-intensity training adds to a young player
# (Training._RATE_YOUNG 0.11/wk over a ~40-week season).
const GROWTH_PER_SEASON := 4.5
const INTAKE_CA_MIN := 30
const INTAKE_CA_MAX := 80         # arrives at most first-team strong (wonderkid CA is 80)
const _POTENTIAL_MARGIN := 4      # ceiling sits a touch above the tier's prime CA

# Positional colour on top of the generic attr row, so an injected FW reads like a
# striker and an injected DF like a stopper (codes per Training._NAMES).
const _POS_BIAS := {
	"FW": ["TI", "RM", "VE"],
	"MF": ["PA", "RG", "TI"],
	"DF": ["EN", "AG", "RE"],
}
const _BIAS_LO := 4
const _BIAS_HI := 8
const _ATTR_CEIL := 85            # biased attrs may sit above Youth's 80, they're special


# ---- pool queries ----------------------------------------------------------

## JSON-null-safe int: pool entries store explicit nulls ("ca": null), and
## Dictionary.get returns the stored null, not the fallback -- int(null) errors.
static func _int(v: Variant, fallback: int) -> int:
	return fallback if v == null else int(v)


## The entry's target club id (-1 = none, e.g. a manager_youth-routed egg).
static func club_of(e: Dictionary) -> int:
	return _int(e.get("clubId"), -1)

## Entries debuting exactly in the season starting `start_year` (e.g. 1998 -> 1998-99)
## that haven't been injected yet (`used` = Career.talents_used, key -> season).
static func due(pool: Array, start_year: int, used: Dictionary) -> Array:
	return _due(pool, start_year, used, false)


## Entries due in ANY season up to `start_year` -- catch-up after a job change,
## an app update onto an in-flight save, or a missed window.
static func due_catchup(pool: Array, start_year: int, used: Dictionary) -> Array:
	return _due(pool, start_year, used, true)


static func _due(pool: Array, start_year: int, used: Dictionary, catchup: bool) -> Array:
	var out: Array = []
	for e in pool:
		if not (e is Dictionary):
			continue
		var dy := int((e as Dictionary).get("debutYear", 0))
		if dy <= 0 or used.has(key_of(e)):
			continue
		if (dy == start_year) if not catchup else (dy <= start_year):
			out.append(e)
	return out


static func key_of(e: Dictionary) -> String:
	return str(e.get("key", "%s|%d" % [str(e.get("legalName", e.get("name", "?"))), int(e.get("birthYear", 0))]))


## Age on the DB's basis = SEASON-START year - birthYear (Owen b.1979 is 18 in the
## 1997-98 DB, start_year 1997). Plain calendar-year subtraction, no +1 and no birthday
## adjustment — the witnessed rule the whole DB uses (owner FICHA frame 13: McClair
## b.1963 shows 34; makes the 19 Man Utd wage-tier witnesses exact). See extract_english.py.
static func age_in_season(e: Dictionary, start_year: int) -> int:
	return start_year - int(e.get("birthYear", start_year - 16))


# ---- player building -------------------------------------------------------

## Current ability on arrival: his tier's prime CA walked back a season's growth for
## every year he is short of the prime window, so Training.gd's ordinary young-player
## climb carries him to the tier's peak with no new development code.
static func intake_ca(e: Dictionary, age: int) -> int:
	if _int(e.get("ca"), 0) > 0:
		return clampi(_int(e.get("ca"), 0), INTAKE_CA_MIN, INTAKE_CA_MAX)
	var peak := int(TIER_PEAK.get(_int(e.get("tier"), 4), 74))
	var back := GROWTH_PER_SEASON * maxi(0, _PEAK_AGE - age)
	return clampi(int(round(peak - back)), INTAKE_CA_MIN, INTAKE_CA_MAX)


## Hidden ceiling: explicit override, else a touch above the tier's prime CA. May sit
## above Youth.POTENTIAL_CAP (88) -- like the wonderkid, tier-1s are generational.
static func potential_of(e: Dictionary) -> int:
	if _int(e.get("potential"), 0) > 0:
		return _int(e.get("potential"), 0)
	return int(TIER_PEAK.get(_int(e.get("tier"), 4), 74)) + _POTENTIAL_MARGIN


## The 10-attr row: the regen builder around `ca` plus a positional lean.
static func make_attrs(rng: RandomNumberGenerator, ca: int, pos: String, is_gk: bool) -> Dictionary:
	var a := Youth._make_attrs(rng, ca, is_gk)
	if not is_gk and _POS_BIAS.has(pos):
		for code in _POS_BIAS[pos]:
			a[code] = clampi(int(a.get(code, ca)) + rng.randi_range(_BIAS_LO, _BIAS_HI),
				Youth.ATTR_FLOOR, _ATTR_CEIL)
	return a


## The intake's fine-position code. data/talent_pool.json ships posFine null on
## EVERY entry, and a stored null aborts every downstream `int(p.get("posFine", 0))`
## draw call (GDScript: get() returns the stored null, int(null) errors) — the
## "stars but no position or roles" rows Mats saw on season-2 talents. A talent
## therefore gets the representative central slot for his broad position — the
## same codes PMChrome._CAMROL_FALLBACK uses (positions_re.md): GK 1 / DF 4 /
## MF 10 / FW 9. [Mats QA 2026-07-26]
static func _fine_of(e: Dictionary, pos: String) -> int:
	var pf: Variant = e.get("posFine")
	if pf != null and int(pf) > 0:
		return int(pf)
	return int({"GK": 1, "DF": 4, "MF": 10, "FW": 9}.get(pos, 10))


## A full senior player dict, shaped exactly like a _seed_squad roster entry (identity
## from the DB schema + the live-roster stamps), ready to append to rosters[clubId].
## Keeps `potential` on the dict -- Training.train_week holds him there (his ceiling).
static func make_senior(e: Dictionary, rng: RandomNumberGenerator, start_year: int, band: int) -> Dictionary:
	var age := age_in_season(e, start_year)
	var is_gk := bool(e.get("isGK", false))
	var pos := str(e.get("pos", "MF"))
	var ca := intake_ca(e, age)
	var p := {
		"id": _int(e.get("id"), 0),
		"clubId": club_of(e),
		"name": str(e.get("name", "?")),
		"legalName": str(e.get("legalName", e.get("name", "?"))),
		"birthYear": int(e.get("birthYear", start_year - age + 1)),
		"age": age,
		"pos": pos,
		"posFine": _fine_of(e, pos),
		"posAlts": [],
		"isGK": is_gk,
		"media": null,
		"photoId": null,          # no J96 face-bank entry; screens draw no photo (frame truth)
		"squadNo": 0,             # 0 = no individuated number (never null — int(null) aborts)
		"nationality": str(e.get("nationality", "ENGLAND")),
		"flagCode": int(e.get("flagCode", 30)),
		"kind": str(e.get("kind", "NATIONAL")),
		# The pool carries no measurements; the loader's own defaults (GameDB
		# _apply_loader_defaults) so the FICHA card never prints blanks.
		"heightCm": int(e.get("heightCm") if e.get("heightCm") != null else 170 + rng.randi_range(0, 9)),
		"weightKg": int(e.get("weightKg") if e.get("weightKg") != null else 75 + rng.randi_range(0, 9)),
		"attrs": make_attrs(rng, ca, pos, is_gk),
		"potential": potential_of(e),
		# The _seed_squad live-roster stamps (Career.gd), so he is contract-complete.
		"contract_years": 3 if age <= 29 else (2 if age <= 32 else 1),
		"injured_weeks": 0,
		"suspended_weeks": 0,
		"yellows": 0,
		"dev_progress": 0.0,
		"auto_renew": false,
	}
	p["contract_term"] = p["contract_years"]
	Contract.stamp_wage(p, band)
	Morale.ensure(p, rng)
	return p


## A free-agent pool dict (TransferMarket.generate_free_agents shape) for a talent
## whose real club does not exist in the PM98 world (route "free_agent", clubId -1):
## he surfaces on the free-transfer market at his debut season, signable for no fee.
## Carries `potential` so Training.gd holds his ceiling after he is signed.
static func make_free_agent(e: Dictionary, rng: RandomNumberGenerator, start_year: int) -> Dictionary:
	var age := age_in_season(e, start_year)
	var is_gk := bool(e.get("isGK", false))
	var pos := str(e.get("pos", "MF"))
	var ca := intake_ca(e, age)
	return {
		"id": _int(e.get("id"), 0),
		"clubId": -1,
		"name": str(e.get("name", "?")),
		"legalName": str(e.get("legalName", e.get("name", "?"))),
		"birthYear": int(e.get("birthYear", start_year - age + 1)),
		"age": age,
		"pos": pos,
		"posFine": _fine_of(e, pos),
		"posAlts": [],
		"isGK": is_gk,
		"nationality": str(e.get("nationality", "ENGLAND")),
		"flagCode": int(e.get("flagCode", 30)),
		"kind": str(e.get("kind", "NATIONAL")),
		"attrs": make_attrs(rng, ca, pos, is_gk),
		"potential": potential_of(e),
		"contract_years": 0,
		"free_agent": true,
		"injured_weeks": 0,
		"suspended_weeks": 0,
		"yellows": 0,
		"dev_progress": 0.0,
	}


## A youth-team dict (Youth.gd shape) for a talent arriving through the manager's own
## academy -- he shows on the YOUTH TEAM screen and is promoted like any scouted kid.
static func make_youth(e: Dictionary, rng: RandomNumberGenerator, start_year: int) -> Dictionary:
	var age := age_in_season(e, start_year)
	var is_gk := bool(e.get("isGK", false))
	var pos := str(e.get("pos", "MF"))
	var ca := intake_ca(e, age)
	var row := make_attrs(rng, ca, pos, is_gk)
	return {
		"id": int(e.get("id", 0)),
		"name": str(e.get("name", "?")),
		"legalName": str(e.get("legalName", e.get("name", "?"))),
		"birthYear": int(e.get("birthYear", start_year - age + 1)),
		"age": maxi(Youth.INTAKE_AGE_LO, age),
		"isGK": is_gk,
		"pos": pos,
		"posFine": _fine_of(e, pos),
		"posAlts": [],
		"nationality": str(e.get("nationality", "ENGLAND")),
		"flagCode": int(e.get("flagCode", 30)),
		"kind": str(e.get("kind", "NATIONAL")),
		"attrs": row,
		"attrs_base": _base_at_ceiling(row, ca, potential_of(e)),
		"potential": potential_of(e),
		"dev_progress": 0.0,
		"ready": ca >= Youth.READY_CA,
		"is_youth": true,
	}


## WORLD HISTORY for the STATIC (foreign) clubs. 10,574 of the pool's club-routed
## talents target the 307 clubs outside the English pyramid — clubs that never enter
## Career.rosters, so the live-division lane (`Career._inject_talent`) skipped every
## one of them forever and Ronaldinho never turned up at Gremio. This lane rebuilds
## those arrivals DERIVED and IDEMPOTENT, like GameDB.stamp_season_ages: each call
## strips every previously synced arrival (the `talent_arrival` tag) and re-adds all
## entries due by `start_year`, so a new 1997 career sees none of a prior career's
## future and a re-sync never duplicates. Attrs draw from a per-entry seeded RNG, so
## the same talent is the same player in every career. English-club entries are left
## to the live lane (they inject into rosters, with news + the used-ledger); a bought
## talent stays bought — Career.external_signed hides his re-synced static row by pid.
## Returns the number of talents now standing at their static clubs.
static func sync_static_clubs(clubs_by_id: Dictionary, pool: Array, start_year: int) -> int:
	for cid in clubs_by_id:
		var players: Array = (clubs_by_id[cid] as Dictionary).get("players", [])
		for i in range(players.size() - 1, -1, -1):
			if bool((players[i] as Dictionary).get("talent_arrival", false)):
				players.remove_at(i)
	var n := 0
	for e in pool:
		if not (e is Dictionary):
			continue
		var entry: Dictionary = e
		if str(entry.get("route", "club")) != "club":
			continue
		var dy := _int(entry.get("debutYear"), 0)
		if dy <= 0 or dy > start_year:
			continue
		var club: Dictionary = clubs_by_id.get(club_of(entry), {})
		# Foreign = no leagueId; an EMPTY squad is the "Free players" container
		# (GameDB._is_placeholder), never a destination.
		if club.is_empty() or club.get("leagueId") != null:
			continue
		var squad: Array = club.get("players", [])
		if squad.is_empty():
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key_of(entry)) ^ 0x7A1E97
		var band := TransferMarket.stature_of(squad, 1)
		var p := make_senior(entry, rng, start_year, band)
		p["talent_arrival"] = true
		squad.append(p)
		n += 1
	return n


## The easter-egg lane's BASE block (B6 2026-07-27): the byte-exact academy growth
## (`Training.develop_youth_week`) climbs LIVE attrs toward `attrs_base` and stops dead,
## so a talent whose BASE equalled his intake attrs would never grow at all — his
## `potential` was unreachable. Seed BASE as the intake row lifted by (potential - ca),
## capped at 99, with BASE CA = potential exactly. OURS (the regen lane always was);
## pool youngsters keep their shipped BASE untouched.
static func _base_at_ceiling(attrs: Dictionary, ca: int, potential: int) -> Dictionary:
	var up := maxi(0, potential - ca)
	var base := attrs.duplicate()
	for k in base:
		base[k] = clampi(int(base[k]) + up, 0, 99)
	base["CA"] = clampi(potential, 0, 99)
	return base
