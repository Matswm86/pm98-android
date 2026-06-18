extends SceneTree
## Oracle-backed parity test for the EXACT ball-physics scoring predicates (Stage 3
## task 3): FUN_0058ede0 / FUN_0058f100 / FUN_0058fbe0, ported in Pm98Predicates.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_predicates.gd
##
## ORACLE = the PM98 binary's own predicates under the Ghidra PCode emulator
## (tools/re/run_predicate_oracle.sh), banked at tools/re/specs/predicate_oracle.txt:
## per fixture, the mutated match+0x462 band byte, ball y/z, ball velocity
## (vx/vy/vz), and the deflection/trajectory vector (+0x90/+0x94/+0x98), plus the
## return. The fixture INPUTS are embedded below (mirroring the runner's MATRIX); the
## EXPECTED outputs are read from the banked oracle file so there is no transcription.
## Each predicate mutates the ball/match offset->int dicts exactly as the binary does.

const U32 := 0xffffffff

# Fixture inputs (mirror tools/re/run_predicate_oracle.sh MATRIX). `kind` selects the
# predicate; `src` is the FUN_0058f100 trajectory source vector.
const FIXTURES := {
	"ede0_out":    {"kind": "ede0", "x": 0,         "y": 0,       "z": 0,       "vx": 0,      "vy": 0,      "vz": 0,        "line": 0x100000, "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0},
	"ede0_low":    {"kind": "ede0", "x": 0x108000,  "y": 0x1000,  "z": 0x1000,  "vx": 0,      "vy": 0,      "vz": 0,        "line": 0x100000, "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0},
	"ede0_zclamp": {"kind": "ede0", "x": 0x108000,  "y": 0x1000,  "z": 0x25000, "vx": 0x2000, "vy": 0,      "vz": 0x5000,   "line": 0x100000, "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0},
	"ede0_yclamp": {"kind": "ede0", "x": 0x108000,  "y": 0x38000, "z": 0x1000,  "vx": 0x2000, "vy": 0x4000, "vz": 0,        "line": 0x100000, "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0},
	"ede0_win1":   {"kind": "ede0", "x": -0x108000, "y": 0x1000,  "z": 0x22000, "vx": 0,      "vy": 0,      "vz": 0,        "line": 0x100000, "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0},
	"f100_copy":   {"kind": "f100", "x": 0,         "y": 0,       "z": 0,       "vx": 0,      "vy": 0,      "vz": 0,        "line": 0,        "post": 0,        "poss": 0, "side": 0, "f63": 1, "b462": 0, "src": [0x111, 0x222, 0x333]},
	"f100_noarm":  {"kind": "f100", "x": 0,         "y": 0,       "z": 0,       "vx": 0,      "vy": 0,      "vz": 0,        "line": 0,        "post": 0,        "poss": 0, "side": 0, "f63": 0, "b462": 0, "src": [0x111, 0x222, 0x333]},
	"fbe0_out":    {"kind": "fbe0", "x": 0,         "y": 0,       "z": 0,       "vx": 0,      "vy": 0,      "vz": 0,        "line": 0x100000, "post": 0x40000,  "poss": 0, "side": 1, "f63": 0, "b462": 0},
	"fbe0_zcol":   {"kind": "fbe0", "x": 0x180000,  "y": 0x10000, "z": 0x28000, "vx": 0x1000, "vy": 0x2000, "vz": -0x3000,  "line": 0x100000, "post": 0x40000,  "poss": 0, "side": 1, "f63": 0, "b462": 0},
	"fbe0_ycol":   {"kind": "fbe0", "x": 0x180000,  "y": 0x3a000, "z": 0x10000, "vx": 0x1000, "vy": 0x3000, "vz": 0x1000,   "line": 0x100000, "post": 0x40000,  "poss": 0, "side": 1, "f63": 0, "b462": 0},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var oracle := _load_oracle()
	if oracle.is_empty():
		_ok(false, "oracle file empty/unreadable")
	for name in FIXTURES:
		if not oracle.has(name):
			_ok(false, name + ": missing from oracle file")
			continue
		_run_fixture(name, oracle[name])
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


func _eq(name: String, field: String, got: int, want: int) -> void:
	_ok((got & U32) == (want & U32), "%s %s: got %d want %d" % [name, field, got & U32, want & U32])


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _load_oracle() -> Dictionary:
	# parse "name | ret | b462 | y | z | vx | vy | vz | ox | oy | oz | RET?"
	var out := {}
	var f := FileAccess.open(_spec_path("predicate_oracle.txt"), FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var c := line.split("|")
		if c.size() < 12:
			continue
		out[c[0].strip_edges()] = {
			"ret": c[1].strip_edges().to_int(), "b462": c[2].strip_edges().to_int(),
			"y": c[3].strip_edges().to_int(), "z": c[4].strip_edges().to_int(),
			"vx": c[5].strip_edges().to_int(), "vy": c[6].strip_edges().to_int(),
			"vz": c[7].strip_edges().to_int(), "ox": c[8].strip_edges().to_int(),
			"oy": c[9].strip_edges().to_int(), "oz": c[10].strip_edges().to_int(),
		}
	return out


func _run_fixture(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIXTURES[name]
	var b := {4: fx.x, 8: fx.y, 0xc: fx.z, 0x20: fx.vx, 0x24: fx.vy, 0x28: fx.vz,
			0x4c: 0, 0x50: 0, 0x54: fx.side, 0x63: fx.f63}
	var m := {0x462: fx.b462, 0x1820: fx.line, 0x1824: fx.post, 0x19a0: fx.poss, 0x448: 0, 0x180a: 0}
	var ret := -1
	match fx.kind:
		"ede0":
			ret = Pm98Predicates.goal_area(b, m)
		"f100":
			Pm98Predicates.traj_copy(b, m, fx.get("src", [0, 0, 0]))
		"fbe0":
			ret = Pm98Predicates.post_bar(b, m)
	# ret: meaningful for ede0/fbe0 (FUN_0058f100 is void -> skip).
	if fx.kind != "f100":
		_eq(name, "ret", ret, exp.ret)
	_eq(name, "b462", int(m.get(0x462, 0)) & 0xff, exp.b462)
	_eq(name, "y", int(b.get(8, 0)), exp.y)
	_eq(name, "z", int(b.get(0xc, 0)), exp.z)
	_eq(name, "vx", int(b.get(0x20, 0)), exp.vx)
	_eq(name, "vy", int(b.get(0x24, 0)), exp.vy)
	_eq(name, "vz", int(b.get(0x28, 0)), exp.vz)
	_eq(name, "ox", int(b.get(0x90, 0)), exp.ox)
	_eq(name, "oy", int(b.get(0x94, 0)), exp.oy)
	_eq(name, "oz", int(b.get(0x98, 0)), exp.oz)
