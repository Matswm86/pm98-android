extends SceneTree
## Transcription parity test for Pm98Match.build_match (the match-object CONSTRUCTOR
## FUN_00591180 + its sub-ctors). Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_match_init.gd
##
## There is NO PCode-emu oracle here: FUN_00591180 is an integration constructor (it calls
## operator_new, the C runtime, and globals), not a pure leaf, so -- exactly like
## test_driver.gd for the driver shell -- this LOCKS what is decompile-exact and verifiable
## from the built Dict: the sentinel bboxes, the collider-list head, the positioning box,
## the sub-entity identities (keeper indices + vtables, the ball flags, the back-links to
## match/ball), the empty-roster team headers, the scalar field zeroes, the final vtables,
## and -- the load-bearing prize -- that the FUN_005baca0 noise table consumes EXACTLY
## 3*360 = 1080 match-RNG draws (a missed/extra ctor draw would desync the seed kill-test).

const U32 := 0xffffffff
const LO := 0x70000000
const HI := 0x90000000
const SEED := 0x12345678

var _fail := 0
var _pass := 0


func _init() -> void:
	var m := Pm98Match.build_match(MatchEngine.Pm98Rng.new(SEED))

	_check_vtables(m)
	_check_bboxes(m)
	_check_collider_and_scalars(m)
	_check_subentities(m)
	_check_teams(m)
	_check_aux(m)
	_check_noise_draws(m)
	_smoke_driver(m)

	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _eqx(got: int, want: int, msg: String) -> void:
	_ok((got & U32) == (want & U32), "%s: got 0x%x want 0x%x" % [msg, got & U32, want & U32])


# --- final + sub vtables (L104/L105 + caller stamps) ---
func _check_vtables(m: Dictionary) -> void:
	_eqx(int(m[0x0]), Pm98Match.VT_MATCH_FINAL, "match vtable +0x0")
	_eqx(int(m[0x430]), Pm98Match.VT_MATCH_10C, "match vtable +0x430")
	_eqx(int(m["keepers"][0][0x0]), Pm98Match.VT_KEEPER, "keeper0 vtable")
	_eqx(int(m["keepers"][1][0x0]), Pm98Match.VT_KEEPER, "keeper1 vtable")
	_eqx(int(m["referee"][0x0]), Pm98Match.VT_REFEREE, "referee vtable")
	_eqx(int(m["ball"][0x0]), Pm98Match.VT_BALL, "ball vtable")


# --- base bbox (FUN_005c52b0 @ match+0x3fc..) + positioning bbox (match+0x1828..) ---
func _check_bboxes(m: Dictionary) -> void:
	# base subobject bbox: LO LO HI HI LO LO HI HI at +0x3fc..+0x418, +0x3f4/+0x3f8 = 0.
	_eqx(int(m[0x3f4]), 0, "base +0x3f4")
	_eqx(int(m[0x3f8]), 0, "base +0x3f8")
	var base_pat := {0x3fc: LO, 0x400: LO, 0x404: HI, 0x408: HI, 0x40c: LO, 0x410: LO, 0x414: HI, 0x418: HI}
	for off in base_pat:
		_eqx(int(m[off]), base_pat[off], "base bbox +0x%x" % off)
	for off in [0x41c, 0x420, 0x424, 0x428, 0x42c]:
		_eqx(int(m[off]), 0, "base tail +0x%x" % off)
	_eqx(int(m[0xb4]), 1, "base +0xb4 = 1")
	# positioning bbox (read by restart_box_ok): LO LO LO HI HI HI at +0x1828..+0x183c.
	var pos_pat := {0x1828: LO, 0x182c: LO, 0x1830: LO, 0x1834: HI, 0x1838: HI, 0x183c: HI}
	for off in pos_pat:
		_eqx(int(m[off]), pos_pat[off], "pos bbox +0x%x" % off)


# --- collider-list head + the explicit scalar zeroes/sentinels ---
func _check_collider_and_scalars(m: Dictionary) -> void:
	# +0x17f4 (collider list) + +0x1a24 (event queue) are null pointers in the binary, modeled
	# as empty Arrays for the GDScript consumers (ball-collision / dequeue).
	_ok(m[0x17f4] is Array and (m[0x17f4] as Array).is_empty(), "collider list +0x17f4 empty")
	_eqx(int(m[0x17f8]), 0, "collider head +0x17f8")
	_eqx(int(m[0x17fc]), U32, "collider sentinel +0x17fc = -1")
	_ok(m[0x1a24] is Array and (m[0x1a24] as Array).is_empty(), "event queue +0x1a24 empty")
	for off in [0x464, 0x199c, 0x458, 0x5fac, 0x1a1d, 0x1840, 0x1809, 0x2468, 0x246c, 0x2ba4, 0x2ba8, 0x5fb0, 0x5fb4]:
		_eqx(int(m[off]), 0, "scalar zero +0x%x" % off)
	for off in [0x1a28, 0x1a44, 0x1a48, 0x1a4c, 0x1a50, 0x1a54, 0x1a58, 0x1a5c, 0x1a60]:
		_eqx(int(m[off]), 0, "event-queue zero +0x%x" % off)
	for off in [0x27c8, 0x27cc, 0x27d0, 0x27d4, 0x27dc, 0x27e0, 0x27e4, 0x27e8]:
		_eqx(int(m[off]), 0, "scalar zero +0x%x" % off)
	# +0x27d8 (param_1[0x9f6]) is deliberately NOT written by the ctor.
	_ok(not m.has(0x27d8), "+0x27d8 left unwritten (param_1[0x9f6] skipped)")
	_eqx(int(m["ring"]), 0, "ring counter")


# --- keepers (idx 1/2, back-links), referee, ball flags ---
func _check_subentities(m: Dictionary) -> void:
	var gk0: Dictionary = m["keepers"][0]
	var gk1: Dictionary = m["keepers"][1]
	_eqx(int(gk0[0x3bc]), 1, "keeper0 index")
	_eqx(int(gk1[0x3bc]), 2, "keeper1 index")
	_eqx(int(gk0[0x2b8]), 0, "keeper0 +0x2b8")
	_ok(gk0[0x18c] == m, "keeper0 +0x18c -> match")
	_ok(gk0[0x190] == m["ball"], "keeper0 +0x190 -> ball")
	_eqx(int(gk0[0x3a8]), 0x999, "keeper0 +0x3a8 default")
	_eqx(int(gk0[0x3ac]), 0x62f, "keeper0 +0x3ac default")
	# referee back-links + that it is the match+0x123c object.
	_ok(m["referee"][0x18c] == m, "referee +0x18c -> match")
	_ok(m[0x123c] == m["referee"], "referee aliased at match+0x123c")
	_ok(m[0xaac] == gk0 and m[0xe74] == gk1, "keepers aliased at +0xaac/+0xe74")
	# ball (FUN_0058e050).
	var b: Dictionary = m["ball"]
	_eqx(int(b[0x54]), U32, "ball +0x54 = -1")
	_eqx(int(b[0x58]), _u(-2), "ball +0x58 = -2")
	_eqx(int(b[0x60]), 1, "ball +0x60 flag")
	_eqx(int(b[0x61]), 1, "ball +0x61 flag")
	_eqx(int(b[0x1d8]), 1, "ball +0x1d8 flag")
	_ok(b[0x1d4] == m, "ball +0x1d4 -> match")
	_ok(m[0x1610] == b, "ball aliased at match+0x1610")


# --- the two team headers = empty-roster movement contexts ---
func _check_teams(m: Dictionary) -> void:
	var sim: Array = m["sim"]
	_ok(sim.size() == 2, "sim has 2 team contexts")
	_ok(m[0x46c] == sim[0] and m[0x78c] == sim[1], "teams aliased at +0x46c/+0x78c")
	for k in range(2):
		var t: Dictionary = sim[k]
		_eqx(int(t[0x0]), 0, "team%d player-base = null" % k)
		_eqx(int(t[0x4]), 0, "team%d count = 0" % k)
		_eqx(int(t[0x168]), 0, "team%d +0x168 (active idx)" % k)
		_eqx(int(t[0x208]), 0, "team%d +0x208" % k)
		_ok((t["players"] as Array).is_empty(), "team%d roster empty" % k)
		_eqx(int(t[0x8]), k, "team%d ctx team index" % k)
		_ok(t[0x138] == m, "team%d ctx -> match" % k)


# --- auxiliary sub-objects present at their byte offsets ---
func _check_aux(m: Dictionary) -> void:
	_ok((m[0x2470] as Array).size() == 9, "9x8 array @ +0x2470")
	for off in [0x24b8, 0x2504, 0x2550, 0x2634, 0x27f0]:
		_ok(m[off] is Dictionary, "aux sub-object @ +0x%x" % off)
	_ok((m[0x259c] as Array).size() == 2, "2x0x4c array @ +0x259c")
	# the 0x4c bbox holder default: +0x24=-1, +0x2c/+0x28=LO, +0x34/+0x30=HI.
	var c: Dictionary = m[0x24b8]
	_eqx(int(c[0x24]), U32, "c9210 +0x24 = -1")
	_eqx(int(c[0x2c]), LO, "c9210 +0x2c = LO")
	_eqx(int(c[0x34]), HI, "c9210 +0x34 = HI")
	# eight FUN_005f2ad0 holders @ +0x2884 stride 0x64.
	var off2 := 0x2884
	for i in range(8):
		_ok(m[off2] is Dictionary and int(m[off2][0x54]) == 0x10000, "f2ad0[%d] @ +0x%x" % [i, off2])
		off2 += 0x64


# --- LOAD-BEARING: FUN_005baca0 consumes EXACTLY 1080 match-RNG draws ---
func _check_noise_draws(m: Dictionary) -> void:
	# reference rng drawn 1080 times must land on the same state as the build's rng.
	var ref := MatchEngine.Pm98Rng.new(SEED)
	var r0 := ref.next(); var r1 := ref.next(); var r2 := ref.next()
	for _i in range(0x168 * 3 - 3):
		ref.next()
	var build_rng := MatchEngine.Pm98Rng.new(SEED)
	var _m2 := Pm98Match.build_match(build_rng)
	_ok(build_rng.state == ref.state, "ctor consumed exactly 1080 RNG draws (state match)")
	var nt: Dictionary = m[0x2bac]
	_eqx(int(nt["draws"]), 1080, "noise draw count = 1080")
	var noise: Array = nt["noise"]
	_ok(noise.size() == 0x168, "noise table has 360 rows")
	# first row = scale7 of the first three rolls from SEED.
	_eqx(int(noise[0][0]), Pm98Match._scale7(r0), "noise[0][0] = roll0*32")
	_eqx(int(noise[0][1]), Pm98Match._scale7(r1), "noise[0][1] = roll1*32")
	_eqx(int(noise[0][2]), Pm98Match._scale7(r2), "noise[0][2] = roll2*32")
	var spin: Array = nt["spin"]
	_ok(spin.size() == 0xf0, "spin table has 240 records")
	_eqx(int(spin[0][0]), 0x3f000000, "spin[0][0] = 0.5f")
	_eqx(int(spin[0][1]), 0x3f800000, "spin[0][1] = 1.0f")
	_eqx(int(spin[0][2]), _u(-0x40000001), "spin[0][2] raw")
	_eqx(int(spin[0][4]), 0x3f7e0000, "spin[0][4]")


# --- integration smoke ---
# The skeleton DOES expose m["sim"]/["ball"]/["keepers"] (the ctor's job). But the per-team
# movement passes (assign_markers etc) read the opponent descriptor at match+0x46c/+0x78c as a
# players ARRAY -- a shortcut the Pm98Movement port took against its own fixtures -- whereas the
# binary-faithful ctor stores the 800-byte team HEADER there (players live at header[0]). Until
# that model is reconciled (edit Pm98Movement + re-run run_assignmarker_oracle.sh) AND the
# populate FUN_005923f0 loads the 22 players, the movement core cannot run on the skeleton. So
# the smoke proves the driver's control flow + match-over + (Array-fixed) dequeue on the skeleton
# via the driver's DESIGNED no-op path (m["sim"] absent), and asserts the full structure exists.
func _smoke_driver(m: Dictionary) -> void:
	_ok((m["sim"] as Array).size() == 2, "skeleton exposes 2 sim contexts")
	_ok(m["ball"] is Dictionary and not (m["ball"] as Dictionary).is_empty(), "skeleton exposes ball")
	_ok((m["keepers"] as Array).size() == 2, "skeleton exposes 2 keepers")
	# Drive one tick with the movement core in its designed no-op state (sim absent).
	var shell := m.duplicate()
	shell.erase("sim")
	var rng := MatchEngine.Pm98Rng.new(0xABCDEF)
	var r: int = Pm98Driver.tick(shell, rng)
	_ok(r == Pm98Driver.ENGINE_CONTINUE, "driver tick on skeleton returns CONTINUE (got %d)" % r)


func _u(v: int) -> int:
	return v & U32
