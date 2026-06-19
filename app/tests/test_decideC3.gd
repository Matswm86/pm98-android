extends SceneTree
## Oracle-backed parity test for FUN_005a3400 slice C3 (set-piece switch, NON-TAKER cases 2/4/5),
## ported in Pm98Movement.decide_slice_c (_slice_c_case2_nontaker / _slice_c_case45_nontaker).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideC3.gd
##
## ORACLE = the REAL FUN_005a3400 under the Ghidra PCode emulator (cases 2/4/5, a NON-TAKER
## player), run to a clean RET (tools/re/run_decideC3_oracle.sh -> specs/decideC3_oracle.txt).
## This test mirrors each fixture's seeds, runs slice A -> B -> C, and asserts the banked outputs.

const BASE := 0x230000        # P0 base in the oracle's memory map
const U32 := 0xffffffff

# Fixture inputs (mirror run_decideC3_oracle.sh). on -> +0x2bc on-pitch ; tk -> taker team ;
# ys -> match+0x1824 (Yscale, case 2) ; pos -> player+0x2c8 (squad pos -> position table) ;
# d6 -> player+0x2d6 (pos-5/6 override gate) ; j19cc -> match+0x19cc (phase-5 guard) ;
# ep1/ep2 -> on-pitch slots +0x1f8/+0x204 ; b4 -> ball+0x4 facing vec ; b94 -> ball.y (+0x94).
# ball.pos far (0x500000) so clamp_min_sep is a no-op in every fixture.
const SLOTS_EP1 := [0x80000, 0x20000, 0x10000]
const SLOTS_EP2 := [0x40000, 0x50000, 0x60000]
const B4 := [0x70000, 0x30000, 0]
const FIX := {
	"c2_nontaker":     {"team": 0, "orient": 0, "phase": 2, "on": true,  "tk": 0, "ys": 0x40000, "b94": 0x10000},
	"c2_mirror":       {"team": 0, "orient": 1, "phase": 2, "on": true,  "tk": 0, "ys": 0x40000, "b94": -0x20000},
	"c4_same_override":{"team": 0, "orient": 0, "phase": 4, "on": true,  "tk": 0, "pos": 8, "b94": 0x10000},
	"c4_same_mirror":  {"team": 0, "orient": 1, "phase": 4, "on": true,  "tk": 0, "pos": 8, "b94": -0x10000},
	"c5_phase5_guard": {"team": 0, "orient": 0, "phase": 5, "on": true,  "tk": 0, "pos": 8, "j19cc": 0, "b94": 0x10000},
	"c5_phase5_on":    {"team": 0, "orient": 0, "phase": 5, "on": true,  "tk": 0, "pos": 8, "j19cc": 1, "b94": 0x10000},
	"c4_same_allzero": {"team": 0, "orient": 0, "phase": 4, "on": true,  "tk": 0, "pos": 0, "b94": 0x10000},
	"c4_same_pos5guard":{"team": 0, "orient": 0, "phase": 4, "on": true, "tk": 0, "pos": 5, "d6": 0, "b94": 0x10000},
	"c4_same_pos5d6":  {"team": 0, "orient": 0, "phase": 4, "on": true,  "tk": 0, "pos": 5, "d6": 1, "b94": 0x10000},
	"c4_same_off":     {"team": 0, "orient": 0, "phase": 4, "on": false, "tk": 0, "pos": 8, "b94": 0x10000},
	"c4_diff_off":     {"team": 0, "orient": 0, "phase": 4, "on": false, "tk": 1, "b94": 0x10000},
	"c4_diff_off_neg": {"team": 0, "orient": 1, "phase": 4, "on": false, "tk": 1, "b94": -0x10000},
	"c4_diff_on":      {"team": 0, "orient": 0, "phase": 4, "on": true,  "tk": 1, "b94": 0x10000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideC3 oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("decideC3_oracle.txt"), FileAccess.READ)
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
	var m := {
		0x1820: 0x100000, 0x19a0: int(fx["orient"]), 0x448: int(fx["phase"]),
		0x1824: int(fx.get("ys", 0)), 0x19cc: int(fx.get("j19cc", 0)),
		0x438: {0x2b8: int(fx["tk"])},
	}
	var ball := {0x4: int(B4[0]), 0x8: int(B4[1]), 0xc: int(B4[2]),
		0x90: 0x500000, 0x94: int(fx.get("b94", 0)), 0x98: 0}
	var p := {
		0x2b8: int(fx["team"]),
		0x2bc: (1 if fx["on"] else 0),
		0x2c8: int(fx.get("pos", 0)),
		0x2cc: -1,                                            # skip slice-B's +0xb0 table lookup
		0x2d6: int(fx.get("d6", 0)),
		0x18c: m,
		0x190: ball,
	}
	if fx["on"]:                                              # on-pitch: seed the two endpoint slots
		p[0x1f8] = int(SLOTS_EP1[0]); p[0x1fc] = int(SLOTS_EP1[1]); p[0x200] = int(SLOTS_EP1[2])
		p[0x204] = int(SLOTS_EP2[0]); p[0x208] = int(SLOTS_EP2[1]); p[0x20c] = int(SLOTS_EP2[2])

	Pm98Movement.decide_slice_a(p, m)
	Pm98Movement.decide_slice_b(p, m)
	Pm98Movement.decide_slice_c(p, m)

	for off in exp:
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got %d want %d" % [name, off, got, want])
