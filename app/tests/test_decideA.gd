extends SceneTree
## Oracle-backed parity test for FUN_005a3400 slice A (prologue + bbox), ported in
## Pm98Movement.decide_slice_a.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideA.gd
##
## ORACLE = the REAL FUN_005a3400 down the replay path under the Ghidra PCode emulator
## (tools/re/run_decideA_oracle.sh -> tools/re/specs/decideA_oracle.txt). The runner EMBEDS
## each fixture's inputs; the EXPECTED slice-A outputs (13 fields) are read from the banked
## file. All 13 fields are coordinates / scalars (no pointers), compared raw masked to u32.

const U32 := 0xffffffff

# Shared on-pitch formation slots (mirror the runner's ONPITCH_VECS), stored signed.
const VECS := {
	0x1f8: 0x60000, 0x1fc: -196608, 0x200: 0x10000,        # +0x1f8 slot  (0xFFFD0000 = -196608)
	0x204: -131072, 0x208: 0x40000, 0x20c: 0,              # +0x204 slot  (0xFFFE0000 = -131072)
	0x228: 0x50000, 0x22c: 0x20000,                        # +0x228 slot (2D)
	0x230: -65536, 0x234: 0x70000,                         # +0x230 slot (2D, 0xFFFF0000 = -65536)
}

# Fixture inputs (mirror run_decideA_oracle.sh): name -> {onpitch, team, x1820, orient}.
const FIX := {
	"off_u9_0":      {"on": false, "team": 0, "x1820": 0x100000, "orient": 0},
	"off_u9_1":      {"on": false, "team": 0, "x1820": 0x100000, "orient": 1},
	"off_team1":     {"on": false, "team": 1, "x1820": 0xC0000,  "orient": 1},
	"on_noflip":     {"on": true,  "team": 0, "x1820": 0x100000, "orient": 0},
	"on_flip":       {"on": true,  "team": 0, "x1820": 0x100000, "orient": 1},
	"on_flip_team1": {"on": true,  "team": 1, "x1820": 0xC0000,  "orient": 0},
}

# Oracle row key -> player offset (the 13 slice-A outputs).
const FIELDS := {
	"a3a4": 0x3a4,
	"e0": 0x1e0, "e4": 0x1e4, "e8": 0x1e8,
	"ec": 0x1ec, "f0": 0x1f0, "f4": 0x1f4,
	"b10": 0x210, "b14": 0x214, "b18": 0x218,
	"b1c": 0x21c, "b20": 0x220, "b24": 0x224,
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideA oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, orc[name])
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


# Parse "FIX <name> k=v k=v ..." rows.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideA_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for i in range(2, toks.size()):
			var kv := toks[i].split("=")
			if kv.size() == 2:
				row[kv[0]] = kv[1].to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x1820: int(fx["x1820"]), 0x19a0: int(fx["orient"])}
	var p := {0x2b8: int(fx["team"]), 0x2bc: (1 if fx["on"] else 0), 0x18c: m}
	if fx["on"]:
		for off in VECS:
			p[off] = int(VECS[off])

	Pm98Movement.decide_slice_a(p, m)

	for key in FIELDS:
		var off: int = FIELDS[key]
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[key]) & U32
		_ok(got == want, "%s %s(+0x%x): got %d want %d" % [name, key, off, got, want])
