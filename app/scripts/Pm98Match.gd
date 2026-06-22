class_name Pm98Match
extends RefCounted
## EXACT port of MANAGER.EXE's MATCH-OBJECT CONSTRUCTOR FUN_00591180 -- the routine that
## `operator new(0x5fb8)` + FUN_00591180 runs (from the match-create wrapper FUN_00590fc0)
## to build the per-match simulation struct that the driver Pm98Driver.tick() advances.
## (docs/re/EXACT_PORT_PLAN.md Stage 3 task 2, item 3; map in docs/re/MATCH_TICK_DRIVER_MAP.md.)
##
## ====================== HONEST VALIDATION STATUS (read this) ======================
## This ports ONLY the CONSTRUCTOR (FUN_00591180), i.e. the match SKELETON: vtables, the
## four sub-entity sub-objects (2 keepers, referee, ball), the two team headers, the
## auxiliary sub-objects, and every zeroed/sentinel scalar field. It is a TRANSCRIPTION of
## the decompile (docs/re/sim/fn_00591180...) cross-checked against the objdump this-pointer
## offsets, in the same posture as Pm98Driver.gd -- NOT end-to-end-oracle-validated.
##
## CRITICAL: the constructor builds an EMPTY-ROSTER match. The two team headers leave
## team[0]=0 (player-array base = null) and team[1]=0 (player count = 0). The 22 players,
## their coordinates, the squad attributes, the goal dimensions (FUN_00593600) and the
## session sub-object at match+0x468 are NOT built here -- they are loaded by the POPULATE
## pass FUN_005923f0 (the next-session port, EXACT_PORT_PLAN item 3b). So build_match()
## alone does not yet drive a full match; it is the necessary first layer.
##
## LOAD-BEARING for the eventual seed-lockstep kill-test: FUN_005baca0 (this=match+0x2bac)
## draws the match RNG (FUN_005ec250) exactly 3*360 = 1080 times at construction time to
## fill a 360x3 noise table. build_match(rng) reproduces those draws against the live
## Pm98Rng. CAVEAT: whether these 1080 draws are part of the per-tick match seed stream
## depends on WHERE FUN_005923f0 (re)seeds the match RNG relative to the ctor -- unresolved
## until the populate is decoded. If FUN_005923f0 srand()s after construction, pass a
## throwaway rng here. This is flagged for the kill-test, not silently assumed.
##
## DATA MODEL (same offset->Variant Dictionary convention as Pm98Driver/Predicates/Dispatch):
##   * `m`            : the match struct -- flat int keys are byte offsets (m[0x17fc] etc).
##   * m["ball"]      : the ball sub-object at match+0x1610 (FUN_0058e050). ball+0x1d4 -> m.
##   * m["sim"]       : [team0, team1], the two team headers at match+0x46c / +0x78c. Each
##                      team header IS the movement context Pm98Movement reads: ctx[0x168]
##                      (active idx) == team[0x5a], ctx["players"] == the (empty) roster,
##                      ctx[0x8] == team index, ctx[0x138] == m. Players/idx/match-link are
##                      populated by FUN_005923f0; the ctor leaves players empty.
##   * m["keepers"]   : [keeper0, keeper1] at match+0xaac (idx 1) / +0xe74 (idx 2). Each
##                      keeper+0x18c -> m, keeper+0x190 -> ball, keeper+0x3bc -> index.
##   * m["referee"]   : the referee at match+0x123c (FUN_005a2640, vtable 0x6391f8).
##   * m["ring"]      : the global 1024-frame replay-ring counter DAT_006d31bc (0 at start).
##   Auxiliary sub-objects (the three 0x4c bbox holders, the 9x8 / 2x0x4c arrays, the
##   FUN_005d7240 / FUN_005f56a0 / 8x FUN_005f2ad0 anim+audio holders, and the FUN_005baca0
##   noise+param tables) are stored NESTED under their match byte-offset key, with their
##   exact ctor field writes, so the struct is faithful and addressable. None are read on
##   the headless scoreline path; they exist for fidelity and the future kill-test.
##
## VTABLE constants (0x6390e0 etc) are stored as raw .rdata VAs -- they are never read on
## the scoreline path; they are kept so the struct matches the binary byte-for-byte.

const MATCH_SIZE := 0x5fb8   # operator new size from FUN_00590fc0 (sanity reference only)

# --- vtable VAs the ctor stamps (file delta 0x401200; see MATCH_TICK_DRIVER_MAP.md) ---
const VT_MATCH_FINAL := 0x6390e0       # *match (most-derived), set last (L104)
const VT_MATCH_BASE := 0x639888        # *match set by base ctor FUN_005c52b0, overwritten
const VT_MATCH_10C := 0x6390d8         # match+0x430 (param_1[0x10c]) final
const VT_MATCH_10C_TMP := 0x639218     # match+0x430 temp, overwritten by VT_MATCH_10C
const VT_KEEPER := 0x639208            # keeper base vtable (set by ctor after FUN_005a2640)
const VT_REFEREE := 0x6391f8           # referee base vtable
const VT_BALL := 0x639080              # ball vtable (FUN_0058e050)
const VT_SUB_A := 0x639224             # FUN_005a2640 progression
const VT_SUB_B := 0x639238
const VT_SUB_C := 0x639228             # FUN_005a2640 final (before caller overwrites)

const SENTINEL_LO := 0x70000000        # bbox "min" sentinel (huge +)
const SENTINEL_HI := 0x90000000        # bbox "max" sentinel (huge -, as unsigned dword)


# =============================================================================
# build_match -- operator new(0x5fb8) + FUN_00591180. Returns the skeleton match Dict.
# `rng` is the live match-seed Pm98Rng (consumed 1080x by the FUN_005baca0 noise table).
# =============================================================================
static func build_match(rng: MatchEngine.Pm98Rng) -> Dictionary:
	var m: Dictionary = {}

	# --- L16/0x59119f: base-class subobject ctor FUN_005c52b0(this=match+0). Embedded at
	# match+0, so its fields are flat match keys. (Its own callee FUN_005bc430 is a further
	# aux sub-init not read headless; omitted.) ---
	_ctor_c52b0_base(m)

	# --- L17/0x5911bd: temp vtable at match+0x430, overwritten at L105. ---
	m[0x430] = VT_MATCH_10C_TMP
	m[0x464] = 0                                          # L19 param_1[0x119]

	# --- L20/0x5911d2: two team headers, FUN_00605ee0(match+0x46c, 0x320, 2, FUN_005b6360).
	# team0 @ +0x46c, team1 @ +0x78c. Exposed as m["sim"]; players empty (populate fills). ---
	var team0 := _ctor_team(m, 0)
	var team1 := _ctor_team(m, 1)
	m[0x46c] = team0
	m[0x78c] = team1
	m["sim"] = [team0, team1]

	# --- L22-34/0x5911d7..0x591248: the two keepers + the referee. FUN_005a2640(this, match),
	# then the caller stamps the base vtable + (for keepers) the team index at +0x3bc. ---
	var ball := _ctor_ball(m)                             # build ball first (keepers point at it)
	m[0x1610] = ball
	m["ball"] = ball

	var gk0 := _ctor_base_sub(m, ball)                    # match+0xaac
	gk0[0x0] = VT_KEEPER
	gk0[0x3bc] = 1                                         # keeper index 1
	gk0[0x2b8] = 0
	var gk1 := _ctor_base_sub(m, ball)                    # match+0xe74
	gk1[0x0] = VT_KEEPER
	gk1[0x3bc] = 2                                         # keeper index 2
	gk1[0x2b8] = 0
	m[0xaac] = gk0
	m[0xe74] = gk1
	m["keepers"] = [gk0, gk1]

	var ref := _ctor_base_sub(m, ball)                    # match+0x123c
	ref[0x0] = VT_REFEREE
	ref[0x2b8] = 0
	m[0x123c] = ref
	m["referee"] = ref

	# --- L37-39/0x591259: collider-list head + sentinel (match+0x17f4/+0x17f8/+0x17fc).
	# The binary +0x17f4 is the collider-list base POINTER (null at ctor); the GDScript
	# consumers (Pm98Movement._ball_collision) model that list as an Array, so the faithful
	# "null list" is an empty Array, and populate_posts(m) (STEP-1, Pm98CollBuilder) replaces
	# it with the real post array (+0x17f8 = count, scalar). ---
	m[0x17f4] = []
	m[0x17f8] = 0
	m[0x17fc] = _u(-1)                                    # 0xffffffff

	m[0x1809] = 0                                         # byte
	# --- L41-46: the positioning bbox match+0x1828..+0x183c (read by restart_box_ok). ---
	m[0x1828] = SENTINEL_LO
	m[0x182c] = SENTINEL_LO
	m[0x1830] = SENTINEL_LO
	m[0x1834] = SENTINEL_HI
	m[0x1838] = SENTINEL_HI
	m[0x183c] = SENTINEL_HI
	m[0x1840] = 0                                         # byte (param_1+0x610)
	m[0x1a1d] = 0                                         # byte

	# --- L49-58: event-queue / restart scalar field zeroes. The binary +0x1a24 is the event
	# queue's base pointer (null at ctor); Pm98Driver._dequeue models the queue as an Array,
	# so the faithful "empty queue" is an empty Array. +0x1a28.. stay scalar zeroes. ---
	m[0x1a24] = []
	for off in [0x1a28, 0x1a44, 0x1a48, 0x1a4c, 0x1a50, 0x1a54, 0x1a58, 0x1a5c, 0x1a60]:
		m[off] = 0
	m[0x2468] = 0                                         # L59 param_1[0x91a]
	m[0x246c] = 0                                         # L60 param_1[0x91b]

	# --- L62/0x591303: 9x 8-byte array @ match+0x2470 (elem ctor FUN_005917f0 -> {0,0}). ---
	var arr8: Array = []
	for i in range(9):
		arr8.append({0x0: 0, 0x4: 0})
	m[0x2470] = arr8

	# --- L64-68/0x591316..0x591341: three FUN_005c9210 bbox holders @ +0x24b8/+0x2504/+0x2550. ---
	m[0x24b8] = _ctor_c9210()
	m[0x2504] = _ctor_c9210()
	m[0x2550] = _ctor_c9210()

	# --- L70/0x591360: 2x 0x4c array @ match+0x259c (elem ctor FUN_005c9210). ---
	m[0x259c] = [_ctor_c9210(), _ctor_c9210()]

	# --- L72/0x591370: FUN_005d7240 @ match+0x2634. ---
	m[0x2634] = _ctor_d7240()

	# --- L73-80: scalar zeroes match+0x27c8..+0x27e8 (0x9f2..0x9fa, skipping 0x9f6=+0x27d8). ---
	for off in [0x27c8, 0x27cc, 0x27d0, 0x27d4, 0x27dc, 0x27e0, 0x27e4, 0x27e8]:
		m[off] = 0

	# --- L82/0x5913b0: FUN_005f56a0 @ match+0x27f0. ---
	m[0x27f0] = _ctor_f56a0()

	# --- L84-97/0x5913bb..0x59142b: eight FUN_005f2ad0 holders @ +0x2884 stride 0x64. ---
	var f2ad0_off := 0x2884
	for i in range(8):
		m[f2ad0_off] = _ctor_f2ad0()
		f2ad0_off += 0x64

	m[0x2ba4] = 0                                         # L98 param_1[0xae9]
	m[0x2ba8] = 0                                         # L99 param_1[0xaea]

	# --- L101/0x591447: FUN_005baca0 @ match+0x2bac -- the 1080-RNG-draw noise table. ---
	m[0x2bac] = _ctor_baca0(rng)

	m[0x5fb0] = 0                                         # L102 param_1[0x17ec]
	m[0x5fb4] = 0                                         # L103 param_1[0x17ed]

	# --- L104-105: final vtables. ---
	m[0x0] = VT_MATCH_FINAL
	m[0x430] = VT_MATCH_10C

	# --- L107-117: post-array registry DAT_00674650/4 is a GLOBAL bookkeeping side effect;
	# the per-match post geometry is built by Pm98CollBuilder.populate_posts(m) (STEP-1), so
	# it is not reproduced into the match Dict here. ---

	m[0x199c] = 0                                         # L118 param_1[0x667]
	m[0x458] = 0                                          # L119 param_1[0x116]
	m[0x5fac] = 0                                         # L120 byte (headless display gate)

	m["ring"] = 0                                         # DAT_006d31bc starts at 0
	return m


# =============================================================================
# Sub-object constructors (decompile-exact; byte-offset keys).
# =============================================================================

## FUN_005c52b0(this=match+0): the base subobject embedded at match offset 0. Writes the
## base bbox (match+0x3f4..+0x42c), the temp vtable at match+0, and match+0xb4 = 1.
static func _ctor_c52b0_base(m: Dictionary) -> void:
	m[0x3f4] = 0                                          # param_1[0xfd]
	m[0x3f8] = 0                                          # param_1[0xfe]
	m[0x3fc] = SENTINEL_LO                                # param_1[0xff]
	m[0x400] = SENTINEL_LO                                # param_1[0x100]
	m[0x404] = SENTINEL_HI                                # param_1[0x101]
	m[0x408] = SENTINEL_HI                                # param_1[0x102]
	m[0x40c] = SENTINEL_LO                                # param_1[0x103]
	m[0x410] = SENTINEL_LO                                # param_1[0x104]
	m[0x414] = SENTINEL_HI                                # param_1[0x105]
	m[0x418] = SENTINEL_HI                                # param_1[0x106]
	m[0x41c] = 0                                          # param_1[0x107]
	m[0x420] = 0                                          # (undefined2) param_1[0x108]
	m[0x424] = 0                                          # param_1[0x109]
	m[0x428] = 0                                          # param_1[0x10a]
	m[0x42c] = 0                                          # param_1[0x10b]
	m[0x0] = VT_MATCH_BASE                                # *param_1 (overwritten at L104)
	m[0xb4] = 1                                           # param_1[0x2d]


## FUN_005b6360(this=team header): zero-init + the +0x28 nested 2x0x4c vector (empty).
## Also carries the movement-context convenience keys Pm98Movement reads (players/team/match).
## `idx` (team index) and the match link are BEST-EFFORT here (binary sets them in the
## populate FUN_005923f0); the ctor itself only guarantees team[0x5a]=0 (== ctx[0x168]).
static func _ctor_team(m: Dictionary, idx: int) -> Dictionary:
	var t: Dictionary = {}
	t[0x0] = 0                                            # player-array base (null -> 0 players)
	t[0x4] = 0                                            # player count (param_1[1])
	t[0xc] = 0                                            # param_1[3]
	t[0x10] = 0                                           # param_1[4]
	t[0x14] = 0                                           # param_1[5]
	t[0x9c] = 0                                           # param_1[0x27]
	t[0x168] = 0                                          # param_1[0x5a] == ctx active-player idx
	t[0x208] = 0                                          # param_1[0x82]
	t[0x20c] = 0                                          # param_1[0x83]
	t[0xa0] = []                                          # +0x28 nested 2x0x4c vector, empty
	# movement-context view (Pm98Movement): populated for real by FUN_005923f0.
	t["players"] = []
	t[0x8] = idx                                          # ctx team index (best-effort)
	t[0x138] = m                                          # ctx -> match (best-effort)
	return t


## FUN_0058e050(this=ball@match+0x1610, param_2=match): the ball sub-object.
static func _ctor_ball(m: Dictionary) -> Dictionary:
	var b: Dictionary = {}
	b[0x1c] = 0                                           # byte param_1+7
	b[0x20] = 0; b[0x24] = 0; b[0x28] = 0; b[0x2c] = 0    # param_1[8..0xb]
	b[0x30] = 0                                           # (undefined2) param_1[0xd]
	b[0x38] = 0; b[0x3c] = 0                              # param_1[0xe..0xf]
	b[0x40] = 0; b[0x44] = 0; b[0x48] = 0; b[0x4c] = 0    # param_1[0x10..0x13]
	b[0x68] = 0; b[0x6c] = 0; b[0x70] = 0                 # param_1[0x1a..0x1c]
	b[0x80] = 0                                           # param_1[0x20]
	b[0x63] = 0                                           # byte (int)param_1+0x63
	b[0x5c] = 0                                           # param_1[0x17]
	b[0x0] = VT_BALL                                      # *param_1
	b[0x54] = _u(-1)                                      # param_1[0x15]
	b[0x58] = _u(-2)                                      # param_1[0x16]
	b[0x60] = 1                                           # byte param_1+0x18
	b[0x61] = 1                                           # byte (int)param_1+0x61
	b[0x1d8] = 1                                          # byte param_1+0x76
	b[0x1d4] = m                                          # param_1[0x75] -> match
	return b


## FUN_005a2640(this=keeper/referee, param_2=match): the shared base sub-entity ctor.
## Vtable progresses 0x639224 -> 0x639238 -> 0x639228; the caller (FUN_00591180) then
## overwrites *obj with the concrete keeper/referee vtable. obj+0x18c -> match,
## obj+0x190 -> ball (match+0x1610). Sets the two sub-entity bboxes + defaults +0xea/+0xeb.
static func _ctor_base_sub(m: Dictionary, ball: Dictionary) -> Dictionary:
	var o: Dictionary = {}
	o[0x1c] = 0                                           # byte param_1+7
	o[0x0] = VT_SUB_C                                     # final ctor vtable (overwritten by caller)
	o[0x2c] = 0; o[0x30] = 0                              # param_1[0xb..0xc]
	o[0x34] = 0                                           # (undefined2) param_1[0xd]
	o[0x184] = 0; o[0x188] = 0                            # param_1[0x61..0x62]
	o[0x18c] = m                                          # param_1[99] -> match
	o[0x190] = ball                                       # param_1[100] -> ball (match+0x1610)
	# sub-entity bboxes (param_1[0x84..0x8d]).
	o[0x210] = SENTINEL_LO; o[0x214] = SENTINEL_LO; o[0x218] = SENTINEL_LO
	o[0x21c] = SENTINEL_HI; o[0x220] = SENTINEL_HI; o[0x224] = SENTINEL_HI
	o[0x228] = SENTINEL_LO; o[0x22c] = SENTINEL_LO
	o[0x230] = SENTINEL_HI; o[0x234] = SENTINEL_HI
	o[0x238] = 0                                          # byte param_1+0x8e
	o[0x3b0] = 0; o[0x3b4] = 0; o[0x3b8] = 0              # param_1[0xec..0xee]
	o[0x2c0] = 0                                          # param_1[0xb0]
	o[0x2cc] = 0                                          # param_1[0xb3]
	o[0x2c4] = 0                                          # param_1[0xb1]
	o[0x368] = 0                                          # byte (int)param_1+0x2da
	o[0x367] = 0                                          # byte (int)param_1+0x2d9
	o[0x363] = 0                                          # byte (int)param_1+0x2d5
	o[0x2d4] = 0                                          # byte param_1+0xb5
	o[0x5c] = 0                                           # byte param_1+0x17
	o[0x2c8] = 0                                          # param_1[0xb2]
	for i in range(0xde, 0xe9):                           # param_1[0xde..0xe8] = 0
		o[i * 4] = 0
	o[0x2d0] = 0                                          # param_1[0xb4]
	o[0x48] = 0                                           # param_1[0x12]
	o[0x3a8] = 0x999                                      # param_1[0xea]
	o[0x3ac] = 0x62f                                      # param_1[0xeb]
	o[0x74] = 0; o[0x70] = 0; o[0x78] = 0                 # param_1[0x1d/0x1c/0x1e]
	o[0x4c] = 0; o[0x50] = 0                              # param_1[0x13/0x14]
	o[0x88] = 0                                           # param_1[0x22]
	o[0x366] = 0                                          # byte (int)param_1+0x2d6
	o[0xb0] = 0                                           # param_1[0x2c]
	o[0x8c] = 0                                           # param_1[0x23]
	o[0x68] = 0; o[0x6c] = 0                              # param_1[0x1a/0x1b]
	o[0x20] = 0; o[0x24] = 0; o[0x28] = 0                 # param_1[8/9/10]
	o[0x40] = 0                                           # param_1[0x10]
	o[0x180] = 0                                          # param_1[0x60]
	o[0x17c] = 0                                          # param_1[0x5f]
	return o


## FUN_005c9210(this=0x4c bbox holder): a 0x4c-byte axis-aligned-box sub-object.
static func _ctor_c9210() -> Dictionary:
	var o: Dictionary = {}
	o[0x0] = 0; o[0x4] = 0; o[0x8] = 0; o[0xc] = 0; o[0x10] = 0   # param_1[0..4]
	o[0x24] = _u(-1)                                      # param_1[9]
	o[0x2c] = SENTINEL_LO                                 # param_1[0xb]
	o[0x28] = SENTINEL_LO                                 # param_1[10]
	o[0x34] = SENTINEL_HI                                 # param_1[0xd]
	o[0x30] = SENTINEL_HI                                 # param_1[0xc]
	o[0x40] = 0; o[0x44] = 0                              # param_1[0x10/0x11]
	o[0x48] = 0                                           # byte param_1+0x12
	o[0x49] = 0; o[0x4a] = 0; o[0x4b] = 0                 # bytes
	return o


## FUN_005d7240(this=sub-object @match+0x2634): an anim/state holder (its callee FUN_005c9210
## inits an embedded bbox at offset 0; FUN_005ee9f0 is an aux call with no field write here).
static func _ctor_d7240() -> Dictionary:
	var o := _ctor_c9210()                                # embedded FUN_005c9210 at offset 0
	o[0x10c] = SENTINEL_LO; o[0x108] = SENTINEL_LO
	o[0x114] = SENTINEL_HI; o[0x110] = SENTINEL_HI
	o[0x120] = 0                                          # byte
	o[0x150] = 0; o[0x154] = 0; o[0x18c] = 0; o[400] = 0
	o[0x140] = 0; o[0x144] = 0
	for off in [0x148, 0x149, 0x14a, 0x14b, 0x14c]:       # bytes
		o[off] = 0
	o[0x100] = 0x10000
	o[0x104] = 0x1900000
	for off in [0x168, 0x16c, 0x170, 0x174, 0x178, 0x17c, 0x158, 0x15c, 0x160]:
		o[off] = 0
	o[0x180] = 0
	o[0x181] = 1                                          # byte
	o[0x182] = 0; o[0x183] = 0; o[0x184] = 0; o[0x185] = 0; o[0x188] = 0
	o[0x186] = 1                                          # byte
	o[0x187] = 0                                          # byte
	return o


## FUN_005f56a0(this=sub-object @match+0x27f0): a 3D-extent holder. Defaults 0xfc180000
## (min, ~ -8.0e? as raw float) and 0x3e80000 / 0x10000 fixed-point ones.
static func _ctor_f56a0() -> Dictionary:
	var o: Dictionary = {}
	o[0x14] = 0xfc180000; o[0x10] = 0xfc180000; o[0xc] = 0xfc180000   # param_1[5/4/3]
	o[0x20] = 0x3e80000; o[0x1c] = 0x3e80000; o[0x18] = 0x3e80000     # param_1[8/7/6]
	o[0x38] = 0x3e80000; o[0x34] = 0x3e80000; o[0x30] = 0x3e80000     # param_1[0xe/0xd/0xc]
	o[0x2c] = 0xfc180000; o[0x28] = 0xfc180000; o[0x24] = 0xfc180000  # param_1[0xb/0xa/9]
	for i in range(0xf, 0x1e):                            # param_1[0xf..0x1d] = 0
		o[i * 4] = 0
	o[0x92] = 1                                           # byte (int)param_1+0x92
	o[0x7c] = 0; o[0x78] = 0                              # param_1[0x1f/0x1e]
	o[0x88] = 0x10000; o[0x84] = 0x10000; o[0x80] = 0x10000   # param_1[0x22/0x21/0x20]
	o[0x90] = 0                                           # (undefined2) param_1[0x24]
	o[0x8e] = 0                                           # (undefined2) (int)param_1+0x8e
	o[0x8c] = 0                                           # (undefined2) param_1[0x23]
	o[0x4] = 0                                            # param_1[1]
	o[0x0] = 0                                            # *param_1
	return o


## FUN_005f2ad0(this=anim/audio holder @match+0x2884 stride 0x64): scale-default holder.
static func _ctor_f2ad0() -> Dictionary:
	var o: Dictionary = {}
	o[0x0] = 0; o[0x4] = 0; o[0x8] = 0; o[0xc] = 0        # param_1[0..3]
	o[0x50] = 0                                           # (undefined2) param_1[0x14]
	o[0x40] = 0                                           # param_1[0x10]
	o[0x4e] = 0                                           # (undefined2) (int)param_1+0x4e
	o[0x4c] = 0                                           # (undefined2) param_1[0x13]
	o[0x44] = 0                                           # param_1[0x11]
	o[0x48] = 0                                           # param_1[0x12]
	o[0x5c] = 0x10000; o[0x58] = 0x10000; o[0x54] = 0x10000   # param_1[0x17/0x16/0x15]
	o[0x60] = 1                                           # byte param_1+0x18
	return o


## FUN_005baca0(this=noise table @match+0x2bac): draws the match RNG 3*360=1080 times to
## fill a 360x3 noise table (each = roll*32, the `(roll*0x1000)>>7` idiom; MSVC rand is in
## [0,0x7fff] so the >>0x1f sign term is always 0), then fills a 240x8 record table with
## float-default constants (no RNG). LOAD-BEARING: the 1080 draws advance the seed.
static func _ctor_baca0(rng: MatchEngine.Pm98Rng) -> Dictionary:
	var noise: Array = []                                 # 360 rows of 3 ints
	for _row in range(0x168):                             # 360
		var a := rng.next()
		var b := rng.next()
		var c := rng.next()
		noise.append([_scale7(a), _scale7(b), _scale7(c)])
	# 240 records of the float-default pattern (param_1+0x52a..+0x52f per record, stride 8).
	var spin: Array = []
	for _rec in range(0xf0):                              # 240
		spin.append([0x3f000000, 0x3f800000, _u(-0x40000001), 0, 0x3f7e0000, 0x3f7e0000])
	return {"noise": noise, "spin": spin, "draws": 0x168 * 3}


# =============================================================================
# helpers
# =============================================================================

## The `(int)(roll*0x1000 + (roll*0x1000 >> 0x1f & 0x7f)) >> 7` scale from FUN_005baca0. For
## the MSVC rand() output roll in [0, 0x7fff], roll*0x1000 >= 0 so the arithmetic-shift bias
## term is 0: the result is (roll*0x1000) >> 7 == roll*32.
static func _scale7(roll: int) -> int:
	var p := roll * 0x1000
	return (p + ((p >> 31) & 0x7f)) >> 7


## Reinterpret a signed int as its unsigned 32-bit dword (the binary stores raw dwords).
static func _u(v: int) -> int:
	return v & 0xFFFFFFFF
