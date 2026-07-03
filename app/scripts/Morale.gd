class_name Morale
extends RefCounted
## MO (morale) + FITNESS — the dynamic-form model decoded from MANAGER.EXE
## (docs/re/morale_re.md). Every constant here is read or EMULATED out of the
## binary; nothing is tuned. Values live on the player dict:
##   p["morale"]  40..99   (struct +0xa6)
##   p["fitness"] 40..99   (struct +0xa7)
##
## Mutators FUN_00584cc0/FUN_00584c60 (damped negatives, clamp 40..99); season
## init FUN_005825c0 (90 + rand(10), fitness halfway toward 40); post-match slot
## deltas FUN_00582690; the result delta FUN_004179a0 PCode-emulated into the
## RESULT_DELTA_* tables (docs/re/inventory-evidence/morale_result_delta.json,
## 600/600 clean — including the original's own (4,4) away-loss +4 quirk);
## weekly league-position ceiling FUN_0057b400 + FUN_00418030; substitution
## nudge FUN_00582d80; new-signing jealousy FUN_00588ae0; displayed value
## FUN_00582db0 (base + render-time terms); RATING/AV FUN_00581e60 — confirmed
## against walkthrough frames 081/084 (VdG 80, Solskjaer 82).
##
## GameDB-free, pure functions over plain dicts -> headless-testable.

const FLOOR := 40                 # 0x28 — both bars clamp here
const CAP := 99                   # 0x63

# FUN_004179a0 emulated: [homeBand][awayBand] -> [W, D, L] for that side's OWN
# result. Bands 0..3 = English divisions (the app's league = band 0); 4-6/7-9 =
# the continental groups the same matrix carries.
const RESULT_DELTA_HOME := [
	[[8, -2, -10], [4, -4, -12], [2, -6, -14], [1, -8, -24], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[9, 1, -5], [8, -2, -10], [4, -4, -12], [2, -6, -16], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[10, 2, -4], [9, 1, -5], [6, -1, -8], [4, -3, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[12, 5, -1], [10, 3, -3], [9, 1, -5], [8, -1, -8], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -1, -8], [6, -2, -10], [4, -5, -12], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [9, 1, -5], [8, 0, -8], [6, -3, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [10, 3, -3], [9, 1, -5], [8, -1, -8], [8, -2, -10], [8, -2, -10], [8, -2, -10]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [10, 3, -3], [9, 1, -5], [8, -1, -8]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [10, 3, -3], [9, 1, -5], [8, -1, -8]],
	[[8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [8, -2, -10], [10, 3, -3], [9, 1, -5], [8, -1, -8]],
]
const RESULT_DELTA_AWAY := [
	[[10, 5, -4], [12, 6, -2], [15, 8, -3], [20, 10, -1], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[8, 3, -5], [10, 5, -4], [12, 6, -4], [15, 8, -3], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[6, -1, -7], [8, 1, -6], [10, 5, -4], [12, 6, -2], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[4, -3, -10], [4, -5, -15], [8, 1, -6], [10, 5, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [10, 5, 4], [12, 6, -2], [15, 8, -3], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [8, 3, -5], [10, 5, -4], [12, 6, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [6, -1, -7], [8, -1, -6], [10, 5, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 8, -3], [15, 8, -3], [15, 8, -3]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [12, 6, -4], [12, 6, -4], [12, 6, -4]],
	[[15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [15, 0, -4], [10, 5, -4], [10, 5, -4], [10, 5, -4]],
]

# FUN_00418030 division-0 ceiling by league position (1-based). Applied only
# after 11 league games (FUN_0057d5a0 gate); the app's league is division 0.
# Divisions 1-3 in docs/re/morale_re.md; ported when lower leagues exist.
const CEILING_DIV0 := {3: 99, 6: 70, 11: 50, 16: 30}   # pos < key -> value, else 10
const CEILING_MIN_GAMES := 11
const CEILING_GRACE := 8          # decay only when morale > ceiling + 8


# ---- the two damped mutators (FUN_00584cc0 / FUN_00584c60) ----------------

## Struct byte +0xa6. Negative deltas soften when the man is already down:
## <50 -> x2/4 (half), 50..74 -> x3/4, >=75 -> full. C truncation toward zero.
static func add(p: Dictionary, delta: int) -> void:
	p["morale"] = _bar_add(int(p.get("morale", CAP)), delta)

## Struct byte +0xa7 — identical curve.
static func fitness_add(p: Dictionary, delta: int) -> void:
	p["fitness"] = _bar_add(int(p.get("fitness", CAP)), delta)

static func _bar_add(value: int, delta: int) -> int:
	if delta < 0:
		if value < 50:
			delta = delta * 2
		elif value <= 74:
			delta = delta * 3
		else:
			delta = delta * 4
		# x86 `sar 2` after the bias add = trunc-toward-zero division by 4
		delta = int(float(delta) / 4.0)
	return clampi(value + delta, FLOOR, CAP)


# ---- season init (FUN_005825c0) --------------------------------------------

## New season (and new career): morale re-rolls 90 + rand(10); fitness falls
## halfway toward 40 (a fresh 99 lands on 70 — the value frames 081/084 pin).
static func season_init(p: Dictionary, rng: RandomNumberGenerator) -> void:
	p["morale"] = 90 + rng.randi_range(0, 9)
	var fit := int(p.get("fitness", CAP))
	p["fitness"] = fit + int(float(FLOOR - fit) / 2.0)


# ---- displayed MO (FUN_00582db0) -------------------------------------------

## The number every screen shows: stored base + render-time terms, clamped.
## Ported terms: the club money/wage bonus (FUN_0057b710) when `ctx` carries
## finances (manager's club). The position-preference term is 0 while the
## preference list defaults to the man's own role, and the out-of-position -15
## needs the un-dumped formation-zone tables — docs/re/morale_re.md gaps.
static func display(p: Dictionary, ctx: Dictionary = {}) -> int:
	return clampi(int(p.get("morale", CAP)) + club_term(p, ctx), FLOOR, CAP)

## FUN_0057b710: big-gate bonus + fair-wage bonus, each capped small. Club
## struct evidence: +0x1fc is banked into the ledger and ZEROED right after each
## match (FUN_0057af10) -> gate receipts, not cash; +0x28 is the player count
## (the same post-match loop counts it down); +0x1f8/count is compared 4x/8x
## against the player's wage float -> the wage bill in the wage's own unit.
## ctx keys (all optional): gate_receipts, squad_size, total_yearly_wages,
## division. Player wage = p["wage"] (weekly), scaled to yearly here.
static func club_term(p: Dictionary, ctx: Dictionary) -> int:
	var n := int(ctx.get("squad_size", 0))
	if n <= 0:
		return 0
	var term := 0
	var gate := int(ctx.get("gate_receipts", 0))
	if gate > 999999:
		# per-division divisor: 5M / 4M / 3M / 2M / 1M (club+0x58 switch)
		var div_table := [5000000, 4000000, 3000000, 2000000]
		var band := int(ctx.get("division", 0))
		var divisor: int = div_table[band] if band < div_table.size() else 1000000
		term = mini(8, int(float(gate) / float(n) / float(divisor)) * 2)
	var bill := float(ctx.get("total_yearly_wages", 0.0))
	var wage_yearly := float(p.get("wage", 0)) * 52.0
	if bill > 999999.0 and wage_yearly > 0.0:
		# thresholds 4.0x / 8.0x the club average (consts 0x638da0/0x638da4)
		var avg := bill / float(n)
		if wage_yearly <= avg * 4.0:
			term += 8
		elif wage_yearly <= avg * 8.0:
			term += 4
	return term


# ---- RATING / AV (FUN_00581e60) --------------------------------------------

## (VE + RE + AG + CA + FITNESS + MO) / 6, integer division. THE original
## rating — frames 081/084 confirm 80 (Van der Gouw) / 82 (Solskjaer).
static func av6(p: Dictionary, ctx: Dictionary = {}) -> int:
	var a: Dictionary = p.get("attrs", {})
	if a.is_empty():
		return 0
	var s := int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0)) \
		+ int(a.get("CA", 0)) + int(p.get("fitness", CAP)) + display(p, ctx)
	return s / 6


# ---- post-match (FUN_00582690 + FUN_004179a0 via FUN_0057af10) --------------

## Slot deltas for one player after a matchday. state: "played" (slot < 0xc),
## "bench" (0xc..0x10), "out" (>= 0x11), "unavailable" (injured/banned — checked
## FIRST in the binary). Good men (QU >= 81) hurt more when left out.
static func post_match_slot(p: Dictionary, state: String) -> void:
	var qu := int((p.get("attrs", {}) as Dictionary).get("CA", 0))
	match state:
		"unavailable":
			fitness_add(p, -3)
			add(p, -4 if qu < 81 else -5)
		"played":
			fitness_add(p, 3)
			add(p, 3)
		"bench":
			fitness_add(p, -1)
			add(p, -2 if qu < 81 else -3)
		"out":
			fitness_add(p, -2)
			add(p, -4 if qu < 81 else -5)

## The team result delta — ONE value applied to every player of the club
## (FUN_0057af10's roster loop). result: "W"/"D"/"L" for THIS club.
static func result_delta(home: bool, my_band: int, opp_band: int, result: String) -> int:
	var idx: int = {"W": 0, "D": 1, "L": 2}.get(result, 1)
	var cell: Array = (RESULT_DELTA_HOME[my_band][opp_band] if home
		else RESULT_DELTA_AWAY[opp_band][my_band])
	return int(cell[idx])


# ---- weekly ceiling decay (FUN_0057b400 + FUN_00418030) ---------------------

## League position drags a high-morale squad down: over ceiling+8 -> -10-rand(3)
## per player per week. Only once 11 league games are played.
static func weekly_ceiling(position: int, games_played: int) -> int:
	if games_played < CEILING_MIN_GAMES:
		return CAP
	for limit in CEILING_DIV0:
		if position < int(limit):
			return int(CEILING_DIV0[limit])
	return 10

static func weekly_decay(p: Dictionary, ceiling: int, rng: RandomNumberGenerator) -> void:
	if int(p.get("morale", CAP)) > ceiling + CEILING_GRACE:
		add(p, -10 - rng.randi_range(0, 2))


# ---- substitution nudge (FUN_00582d80, both players of the swap) ------------

static func sub_nudge(p: Dictionary, now_on_pitch: bool) -> void:
	var qu := int((p.get("attrs", {}) as Dictionary).get("CA", 0))
	if now_on_pitch:
		add(p, 2 if qu < 81 else 1)
	else:
		add(p, -2 if qu < 81 else -4)


# ---- new-signing jealousy (FUN_00588ae0) ------------------------------------

## Applied to every OTHER player of the signing club. Same fine position or the
## same broad group as the newcomer costs morale; wage and quality overlap set
## the size (exact branch map in docs/re/morale_re.md). `loanee` = the incumbent
## is on loan AT the club (owning club != this club).
static func jealousy_delta(incumbent: Dictionary, newcomer: Dictionary, loanee: bool = false) -> int:
	var core4 := func(pl: Dictionary) -> int:
		var a: Dictionary = pl.get("attrs", {})
		return int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0)) + int(a.get("CA", 0))
	var new_r: int = core4.call(newcomer) / 4
	var inc_r: int = core4.call(incumbent) / 4
	var same_fine := int(incumbent.get("posFine", -1)) == int(newcomer.get("posFine", -2))
	var same_broad := str(incumbent.get("pos", "?")) == str(newcomer.get("pos", "!"))
	var out_earned := float(incumbent.get("wage", 0)) < float(newcomer.get("wage", 0))
	if not (same_fine or same_broad):
		return 0
	if inc_r + 2 >= new_r and new_r + 2 >= inc_r:
		# comparable quality — the direct threat
		if loanee:
			return -50 if same_fine else -40
		if same_fine:
			return -60 if out_earned else -40
		return -50 if out_earned else -30
	if inc_r < new_r + 3:
		# clear gap, incumbent not clearly better
		if loanee:
			return -35 if same_fine else -20
		if same_fine:
			return -60 if out_earned else -30
		return -20 if out_earned else 0
	# incumbent clearly better: the same-broad -35 shadows the fine -50 (binary
	# assigns sequentially; same fine implies same broad)
	return -35


# ---- career plumbing ---------------------------------------------------------

## Stamp the dynamic bars on a player who never had them (signings mid-career,
## youth promotions): the season-init roll, like everyone got at kickoff.
static func ensure(p: Dictionary, rng: RandomNumberGenerator) -> void:
	if not p.has("morale"):
		p["morale"] = 90 + rng.randi_range(0, 9)
	if not p.has("fitness"):
		p["fitness"] = 70
