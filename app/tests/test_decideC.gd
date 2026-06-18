extends SceneTree
## Oracle-backed parity test for FUN_005a3400 slice C1 (set-piece switch, NON-TAKER paths),
## ported in Pm98Movement.decide_slice_c.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideC.gd
##
## ORACLE = the REAL FUN_005a3400 under the Ghidra PCode emulator, driven with a set-piece
## phase (match+0x448) and a NON-TAKER player (match+0x438 -> a distinct taker struct), run to a
## clean RET (tools/re/run_decideC_oracle.sh -> specs/decideC_oracle.txt). This test mirrors
## each fixture's seeds, runs slice A -> B -> C, and asserts every banked output field bit-exact.

const BASE := 0x230000        # P0 base in the oracle's memory map
const U32 := 0xffffffff

# Fixture inputs (mirror run_decideC_oracle.sh).
#   team/orient/phase ; on -> +0x2bc on-pitch flag ; tk -> the taker's team (match+0x438+0x2b8) ;
#   ep1/ep2 -> on-pitch formation slots +0x1f8 / +0x204 (slice A copies them to the endpoints;
#   omitted for off-pitch, where slice A derives [gx,0,0]) ; b4 -> ball (player+0x190) +0x4 vec ;
#   b90 -> ball +0x90 (case 7 off-pitch wing-side sign).
const FIX := {
	"c3_same":    {"team": 0, "orient": 0, "phase": 3, "on": true,  "tk": 0,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [0x80000, 0x10000, 0]},
	"c3_diff":    {"team": 0, "orient": 0, "phase": 3, "on": true,  "tk": 1,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [-0x40000, 0x20000, 0]},
	"c6_same":    {"team": 0, "orient": 0, "phase": 6, "on": true,  "tk": 0,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [0x30000, -0x10000, 0]},
	"c6_negmid":  {"team": 0, "orient": 0, "phase": 6, "on": true,  "tk": 0,
		"ep1": [3, 7, -1], "ep2": [-8, -2, 0], "b4": [0x10000, 0x10000, 0]},
	"c6_diff":    {"team": 0, "orient": 0, "phase": 6, "on": true,  "tk": 1,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [0x80000, -0x10000, 0]},
	"c7_same":    {"team": 0, "orient": 0, "phase": 7, "on": true,  "tk": 0,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [0x70000, 0x30000, 0]},
	"c7_off_pos": {"team": 1, "orient": 0, "phase": 7, "on": false, "tk": 0, "b4": [0x40000, 0x20000, 0], "b90": 0x70000},
	"c7_off_neg": {"team": 1, "orient": 0, "phase": 7, "on": false, "tk": 0, "b4": [0x40000, 0x20000, 0], "b90": -0x10000},
	"c7_on_diff": {"team": 0, "orient": 0, "phase": 7, "on": true,  "tk": 1,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0x40000, 0x50000, 0x60000], "b4": [0x70000, 0x30000, 0]},
	"default":    {"team": 0, "orient": 0, "phase": 8, "on": true,  "tk": 0,
		"ep1": [0x10000, 0x20000, 0x30000], "ep2": [0, 0, 0], "b4": [0x70000, 0x30000, 0]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideC oracle file empty/unreadable")
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


# Parse "FIX <name> CALL 0 RET ... mem[0xADDR:W]=val ...": row -> {offset: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideC_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			var off := ("0x" + mtch.get_string(1)).hex_to_int() - BASE
			row[off] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	# match+0x438 -> a DISTINCT taker dict (never is_same as p), carrying only its team.
	var m := {0x1820: 0x100000, 0x19a0: int(fx["orient"]), 0x448: int(fx["phase"]), 0x438: {0x2b8: int(fx["tk"])}}
	var ball := {0x4: int(fx["b4"][0]), 0x8: int(fx["b4"][1]), 0xc: int(fx["b4"][2]), 0x90: int(fx.get("b90", 0))}
	var p := {
		0x2b8: int(fx["team"]),
		0x2bc: (1 if fx["on"] else 0),
		0x2cc: -1,                                            # skip slice-B's +0xb0 table lookup
		0x18c: m,
		0x190: ball,
	}
	if fx["on"]:                                              # on-pitch: seed the two endpoint slots
		p[0x1f8] = int(fx["ep1"][0]); p[0x1fc] = int(fx["ep1"][1]); p[0x200] = int(fx["ep1"][2])
		p[0x204] = int(fx["ep2"][0]); p[0x208] = int(fx["ep2"][1]); p[0x20c] = int(fx["ep2"][2])

	Pm98Movement.decide_slice_a(p, m)
	Pm98Movement.decide_slice_b(p, m)
	Pm98Movement.decide_slice_c(p, m)

	for off in exp:
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got %d want %d" % [name, off, got, want])
