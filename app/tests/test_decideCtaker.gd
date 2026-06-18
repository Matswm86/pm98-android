extends SceneTree
## Oracle-backed parity test for FUN_005a3400 slice C2 (set-piece switch, TAKER paths),
## ported in Pm98Movement._decide_slice_c_taker.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideCtaker.gd
##
## ORACLE = the REAL FUN_005a3400 under the Ghidra PCode emulator, driven with the player AS THE
## TAKER (match+0x438 == player), run to a clean RET (tools/re/run_decideCtaker_oracle.sh ->
## specs/decideCtaker_oracle.txt). This test mirrors each fixture, runs slice A -> B -> C (with
## match+0x438 pointing at the same player dict so the taker branch fires), and asserts every
## banked output field bit-exact.

const BASE := 0x230000        # P0 base in the oracle's memory map
const U32 := 0xffffffff

# Fixture inputs (mirror run_decideCtaker.sh). All off-pitch (+0x2bc=0), +0x2cc=-1.
#   team/orient/phase ; sc -> player+0x5c (stamina) ; t2ee -> teaminfo(+0x184)+0x2ee (stamina) ;
#   bpos -> ball (player+0x190) position +0x90/+0x94/+0x98 ; s2c/s30 -> seed +0x2c/+0x30 (cleared
#   by set_position_code when the code remaps). phase0 struct (match+0x468)+0xfa0 = 0 -> true.
const FIX := {
	"c2_flagT": {"team": 0, "orient": 0, "phase": 2, "sc": 1, "t2ee": 1, "bpos": [0x200000, 0x80000, 0]},
	"c2_flagF": {"team": 0, "orient": 0, "phase": 2, "sc": 0, "t2ee": 1, "bpos": [0x200000, 0x80000, 0]},
	"c3_taker": {"team": 0, "orient": 0, "phase": 3, "sc": 1, "t2ee": 1, "bpos": [0x180000, 0x80000, 0], "s2c": 0x111, "s30": 0x222},
	"c4_taker": {"team": 0, "orient": 0, "phase": 4, "sc": 1, "t2ee": 1, "bpos": [0x200000, 0x80000, 0], "s2c": 0x333, "s30": 0x444},
	"c6_taker": {"team": 1, "orient": 0, "phase": 6, "sc": 1, "t2ee": 1, "bpos": [0x200000, 0x80000, 0x10000]},
	"c7_taker": {"team": 0, "orient": 1, "phase": 7, "sc": 1, "t2ee": 1, "bpos": [0x200000, 0x80000, 0]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideCtaker oracle file empty/unreadable")
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


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideCtaker_oracle.txt"), FileAccess.READ)
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
	var m := {0x1820: 0x100000, 0x19a0: int(fx["orient"]), 0x448: int(fx["phase"]), 0x468: {0xfa0: 0}}
	var bpos: Array = fx["bpos"]
	var ball := {0x40: 0, 0x90: int(bpos[0]), 0x94: int(bpos[1]), 0x98: int(bpos[2])}
	var teaminfo := {0x2ee: int(fx["t2ee"])}
	var p := {
		0x2b8: int(fx["team"]),
		0x2bc: 0,                                             # off-pitch (slice A needs no slots)
		0x2cc: -1,                                            # skip slice-B's +0xb0 lookup
		0x18c: m,
		0x190: ball,
		0x184: teaminfo,
		0x5c: int(fx["sc"]),
	}
	if fx.has("s2c"):
		p[0x2c] = int(fx["s2c"]); p[0x30] = int(fx["s30"])
	m[0x438] = p                                              # taker identity: match+0x438 == player

	Pm98Movement.decide_slice_a(p, m)
	Pm98Movement.decide_slice_b(p, m)
	Pm98Movement.decide_slice_c(p, m)

	for off in exp:
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got %d want %d" % [name, off, got, want])
