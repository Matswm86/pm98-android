extends SceneTree
## Oracle-backed parity test for the OPEN-PLAY STEERING TRIO (FUN_005a89c0 -> 8bc0 -> 8f20),
## ported in Pm98Movement.steer_89c0 / steer_8bc0 / steer_8f20 / _steer_carrier_drag.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_steering.gd
##
## ORACLE = the REAL FUN_005a89c0 driven through the Ghidra PCode emulator (tools/re/
## run_steering_oracle.sh -> specs/steering_oracle.txt) across 6 fixtures. The runner zeroes
## the P / M / ctrl / gs / target windows and pokes only the links below; each row banks the
## post-call P (0x230000) and ctrl (0x240000) field dump as `<abs-addr>=<u32 LE>`. Here we
## rebuild the identical Dict fixture, call steer_89c0, and assert every banked field bit-exact
## (compared as unsigned 32-bit). speed_scale = 100 (the oracle's `arg 0x64`).

const P_BASE := 0x230000
const C_BASE := 0x240000

var _fail := 0
var _pass := 0

# name -> [phase, carrier, tx, ty, tz, p388, cx, cy, cz, m461]  (mirrors run_steering_oracle.sh)
var _fixtures := {
	"park":     [2, false, 0x80000, 0x10000, 0, 0x4000, 0, 0, 0, 0],
	"steer":    [0, false, 0x80000, 0x10000, 0, 0x4000, 0, 0, 0, 0],
	"carrier":  [0, true,  0x80000, 0x10000, 0, 0x4000, 0x34ccc, 0x40000, 0, 0],
	"arrived":  [0, false, 0, 0, 0, 0x4000, 0, 0, 0, 0],
	"flip":     [0, false, -0x18000, 0, 0, 0x4000, 0, 0, 0, 0],
	"retarget": [0, false, 0x500, 0x300, 0, 0x4000, 0x80000, 0x10000, 0, 0],
}


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "steering oracle empty/unreadable (run tools/re/run_steering_oracle.sh)")
	else:
		for name in _fixtures:
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


# Parse specs/steering_oracle.txt -> {name: {abs_addr: u32_val}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("steering_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var parts := line.split("|")
		if parts.size() < 2:
			continue
		var name := parts[0].substr(4).strip_edges()
		var fields := {}
		for tok in parts[1].split(" ", false):
			var kv := tok.split("=")
			if kv.size() == 2:
				fields[kv[0].hex_to_int()] = kv[1].to_int()   # addr is hex, value decimal
		out[name] = fields
	return out


# Build the fixture Dicts (mirrors emit_spec) and drive steer_89c0; assert each banked field.
func _run_fixture(name: String, exp: Dictionary) -> void:
	var spec: Array = _fixtures[name]
	var phase: int = spec[0]
	var carrier: bool = spec[1]
	var tgt := [spec[2], spec[3], spec[4]]
	var p388: int = spec[5]
	var cx: int = spec[6]
	var cy: int = spec[7]
	var cz: int = spec[8]
	var m461: int = spec[9]

	var P := {}
	var M := {}
	var C := {}
	var GS := {}
	var OTHER := {}
	P[0x184] = GS
	P[0x18c] = M
	P[0x190] = C
	P[0x70] = 15000
	P[0x3ac] = 65536
	P[0x3a8] = 0
	P[0x388] = p388
	M[0x448] = phase
	M[0x461] = m461
	M[0x1970] = 0x7f000000
	M[0x1978] = 0x7f000000
	C[0x40] = P if carrier else OTHER
	C[0x4] = cx
	C[0x8] = cy
	C[0xc] = cz

	Pm98Movement.steer_89c0(P, tgt, 100)

	for addr in exp:
		var want: int = int(exp[addr]) & 0xffffffff
		var off: int
		var got: int
		var tag: String
		if addr >= C_BASE:
			off = addr - C_BASE
			got = int(C.get(off, 0)) & 0xffffffff
			tag = "ctrl+0x%x" % off
		else:
			off = addr - P_BASE
			got = int(P.get(off, 0)) & 0xffffffff
			tag = "P+0x%x" % off
		_ok(got == want, "%s %s: got %d want %d" % [name, tag, got, want])
