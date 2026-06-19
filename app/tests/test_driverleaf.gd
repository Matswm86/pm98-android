extends SceneTree
## Oracle-backed parity test for three FUN_00598740 driver leaves, ported in
## Pm98Movement.within_box (FUN_005a1820), set_phase (FUN_005942e0), vec3_copy (FUN_00590ac0).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_driverleaf.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator (EAX for within_box, memory for the
## others), tools/re/run_driverleaf_oracle.sh -> specs/driverleaf_oracle.txt.

const U32 := 0xffffffff
const L := [0x20000, 0x20000, 0x20000]
const FIX := {
	"a1820_within": {"k": "box", "p1": [0, 0, 0], "p2": [0x10000, 0x10000, 0x10000]},
	"a1820_negok":  {"k": "box", "p1": [0x10000, 0x10000, 0x10000], "p2": [0, 0, 0]},
	"a1820_xfail":  {"k": "box", "p1": [0, 0, 0], "p2": [0x20000, 0x10000, 0x10000]},
	"a1820_yfail":  {"k": "box", "p1": [0, 0, 0], "p2": [0x10000, 0x30000, 0x10000]},
	"a1820_zfail":  {"k": "box", "p1": [0, 0, 0], "p2": [0x10000, 0x10000, 0x30000]},
	"phase_set":    {"k": "phase", "init": 0, "phase": 6},
	"phase_one":    {"k": "phase", "init": 0, "phase": 1},
	"phase_locked": {"k": "phase", "init": 8, "phase": 6},
	"copy_vec":     {"k": "copy", "src": [0x12340000, 0x56780000, 0x9abc0000]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "driverleaf oracle file empty/unreadable")
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


# Parse "FIX <name> ... [EAX=v] [mem[0xADDR:W]=v ...]": row -> {"eax": v, "mem": {addr: v}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("driverleaf_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rxe := RegEx.new(); rxe.compile("EAX=(-?[0-9]+)")
	var rxm := RegEx.new(); rxm.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {"mem": {}}
		var e := rxe.search(line)
		if e != null:
			row["eax"] = e.get_string(1).to_int()
		for mtch in rxm.search_all(line):
			row["mem"][("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	match fx["k"]:
		"box":
			var got: int = 1 if Pm98Movement.within_box(fx["p1"], fx["p2"], L[0], L[1], L[2]) else 0
			_ok(got == int(exp.get("eax", -1)), "%s: got %d want %d" % [name, got, int(exp.get("eax", -1))])
		"phase":
			var m := {0x448: int(fx["init"]), 0x44c: 0x7777}
			Pm98Movement.set_phase(m, int(fx["phase"]))
			var em: Dictionary = exp["mem"]
			_ok((int(m[0x448]) & U32) == (int(em[0x210448]) & U32),
				"%s +0x448: got %d want %d" % [name, int(m[0x448]) & U32, int(em[0x210448]) & U32])
			_ok((int(m[0x44c]) & U32) == (int(em[0x21044c]) & U32),
				"%s +0x44c: got %d want %d" % [name, int(m[0x44c]) & U32, int(em[0x21044c]) & U32])
		"copy":
			var r: Array = Pm98Movement.vec3_copy(fx["src"])
			var em: Dictionary = exp["mem"]
			var addrs := [0x230000, 0x230004, 0x230008]
			for i in 3:
				_ok((int(r[i]) & U32) == (int(em[addrs[i]]) & U32),
					"%s [%d]: got 0x%x want 0x%x" % [name, i, int(r[i]) & U32, int(em[addrs[i]]) & U32])
