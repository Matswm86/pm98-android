extends SceneTree
## Oracle-backed parity test for the phase-based active-player selector (Stage 3 task 2,
## slice 5a): FUN_005b8f20 (Pm98Movement.select_active) -- the gate + phase 6/4/else
## branches. Phase 2 (LUT) and phase 5/7 (set-piece queue) are deferred to slice 5b.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_selectactive.gd
##
## ORACLE = the PM98 binary's own FUN_005b8f20 under the Ghidra PCode emulator
## (tools/re/run_selectactive_oracle.sh; faithful _ftol injected, no LUT since the only
## float path is select_nearest with find_in_front=0), banked at
## specs/selectactive_oracle.txt as one `CALL 0 RET ... mem[...]=...` line per fixture. The
## fixture INPUTS are mirrored below; EXPECTED = the chosen active player (ctx+0x168, mapped
## (ptr-0x230000)/0x3bc, 0 -> -1) and every player's +0x5c flag.

const PLAYER_BASE := 0x230000
const STRIDE := 0x3bc

# +0x5c readback address per player index.
const FLAG_ADDR := {0x23005c: 0, 0x230418: 1, 0x2307d4: 2, 0x230b90: 3}
const ACTIVE_ADDR := 0x200168

# Defaults mirror run_selectactive_oracle.sh's base spec (phase 0 -> else/select_nearest,
# no forced override, no prior active, all 4 players on-pitch at the origin).
const DEF := {
	"force": 0, "phase": 0, "forced": -1, "active": -1,
	"p0onp": 1, "p1onp": 1, "p2onp": 1, "p3onp": 1,
	"p0_5c": 0, "p1_5c": 0, "p2_5c": 0, "p3_5c": 0,
	"p0x": 0, "p1x": 0, "p2x": 0, "p3x": 0,
	"p0_39c": 0, "p1_39c": 0, "p2_39c": 0, "p3_39c": 0,
	"p0_394": 0, "p1_394": 0, "p2_394": 0, "p3_394": 0,
}

# Per-fixture overrides (must match the runner's FIX poke deltas exactly).
const FIXTURES := {
	"forced": {"force": 1, "active": 0, "p0_5c": 1, "forced": 1},
	"phase6": {"phase": 6, "active": 1, "p1_5c": 1},
	"phase4": {"phase": 4, "p0_39c": 0x40, "p1_39c": 0x30, "p2_39c": 0x20, "p3_39c": 0x10, "p2_394": 0x50, "p3_394": 0x30},
	"else_nearest": {"phase": 0, "p0x": 0x50000, "p1x": 0x20000, "p2x": 0x80000, "p3x": 0x90000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "selectactive oracle file empty/unreadable")
	else:
		for name in FIXTURES:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run_fixture(name, orc[name])
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


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _ptr2idx(val: int) -> int:
	if val == 0:
		return -1
	return (val - PLAYER_BASE) / STRIDE


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("selectactive_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		if toks.size() < 3:
			continue
		var ret := ""
		var reads := {}
		for t in toks:
			if t == "RET" or t == "HALT":
				ret = t
			elif t.begins_with("mem["):
				var inner := t.substr(4)
				var lb := inner.find("]")
				if lb < 0:
					continue
				var addr := inner.substr(0, lb).split(":")[0].hex_to_int()
				reads[addr] = inner.substr(lb + 2).to_int()
		out[toks[1]] = {"ret": ret, "reads": reads}
	return out


func _merged(name: String) -> Dictionary:
	var o := DEF.duplicate()
	for k in FIXTURES[name]:
		o[k] = FIXTURES[name][k]
	return o


func _build_ctx(o: Dictionary) -> Dictionary:
	var m := {
		0x448: int(o.phase), 0x438: int(o.forced),
		0x1614: 0, 0x1618: 0, 0x161c: 0, 0x1644: 0,
		0x1650: -1, 0x165c: -1, 0x1664: 0, 0x468: {0xfa0: 0},
	}
	var ti := {}   # teaminfo (+0x2ee unset -> 0, so select_nearest never resets velocity)
	var p0 := {0x2bc: int(o.p0onp), 0x5c: int(o.p0_5c), 0x4: int(o.p0x), 0x8: 0, 0xc: 0, 0x39c: int(o.p0_39c), 0x394: int(o.p0_394), 0x184: ti, 0x18c: m}
	var p1 := {0x2bc: int(o.p1onp), 0x5c: int(o.p1_5c), 0x4: int(o.p1x), 0x8: 0, 0xc: 0, 0x39c: int(o.p1_39c), 0x394: int(o.p1_394), 0x184: ti, 0x18c: m}
	var p2 := {0x2bc: int(o.p2onp), 0x5c: int(o.p2_5c), 0x4: int(o.p2x), 0x8: 0, 0xc: 0, 0x39c: int(o.p2_39c), 0x394: int(o.p2_394), 0x184: ti, 0x18c: m}
	var p3 := {0x2bc: int(o.p3onp), 0x5c: int(o.p3_5c), 0x4: int(o.p3x), 0x8: 0, 0xc: 0, 0x39c: int(o.p3_39c), 0x394: int(o.p3_394), 0x184: ti, 0x18c: m}
	return {"players": [p0, p1, p2, p3], 0x8: 0, 0x138: m, "force_active": int(o.force), 0x168: int(o.active)}


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var ctx := _build_ctx(_merged(name))
	var ret := Pm98Movement.select_active(ctx)
	var players: Array = ctx["players"]
	var reads: Dictionary = exp.reads
	# active (return value == ctx+0x168)
	if reads.has(ACTIVE_ADDR):
		var want_active := _ptr2idx(int(reads[ACTIVE_ADDR]))
		_ok(ret == want_active, "%s active: got %d want %d (EAX=%d)" % [name, ret, want_active, int(reads[ACTIVE_ADDR])])
		_ok(int(ctx.get(0x168, -1)) == want_active, "%s ctx[0x168]: got %d want %d" % [name, int(ctx.get(0x168, -1)), want_active])
	# +0x5c flags
	for addr in FLAG_ADDR:
		if not reads.has(addr):
			_ok(false, "%s: flag addr 0x%x missing from oracle row" % [name, addr])
			continue
		var idx: int = FLAG_ADDR[addr]
		var got := int(players[idx].get(0x5c, 0))
		var want := int(reads[addr])
		_ok(got == want, "%s P%d +0x5c: got %d want %d" % [name, idx, got, want])
