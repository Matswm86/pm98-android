extends SceneTree
## Oracle-backed parity test for FUN_005a4560 (vtable+0xc, the ADVANCE pass) + its motion leaf
## FUN_005ed8e0, ported in Pm98Movement.advance / _advance_motion.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_advance.gd
##
## ORACLE = the REAL FUN_005a4560 under the Ghidra PCode emulator (replay record/playback; pure
## copies, no physics), run to a clean RET (tools/re/run_advance_oracle.sh -> specs/advance_oracle.txt).
## Validates the PLAYBACK restore (9-dword motion + 0x51-dword decide state) and the two NO-OP gates.

const P0 := 0x230000
const U32 := 0xffffffff
# A motion frame (offset within the 0x24-byte frame -> value) and a decide-state frame; mirror the oracle.
const MFRAME := {0x0: 0x11110000, 0x4: 0x22220000, 0x8: 0x33330000, 0xc: 0x44440000,
	0x10: 0x55550000, 0x14: 0x66660000, 0x18: 0x77770000, 0x1c: 0x78880000, 0x20: 0x1234}
const DFRAME := {0x0: 0xa0000001, 0x4: 0xa0000002, 0x140: 0xa0000051}
# Player sentinels for the NO-OP fixtures (distinct from any buffer value).
const SENT := {0x4: 0xdead0004, 0x8: 0xdead0008, 0xc: 0xdead000c, 0x20: 0xdead0020, 0x24: 0xdead0024,
	0x28: 0xdead0028, 0x2c: 0xdead002c, 0x30: 0xdead0030, 0x34: 0xdead0034, 0x40: 0xdead0040,
	0x44: 0xdead0044, 0x180: 0xdead0180}
const FIX := {
	"pb_f0":     {"ring": 0, "frame": 0, "pb": true,  "rec": false},
	"pb_f2":     {"ring": 0, "frame": 2, "pb": true,  "rec": false},
	"noop_ring": {"ring": 1, "frame": 0, "pb": true,  "rec": false, "sent": true},
	"noop_live": {"ring": 0, "frame": 0, "pb": false, "rec": false, "sent": true},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "advance oracle file empty/unreadable")
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


# Parse "FIX <name> ... mem[0xADDR:W]=val ...": row -> {offset_from_P0: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("advance_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int() - P0] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var frame := int(fx["frame"])
	var buf38 := {}
	for off in MFRAME:
		buf38[frame * 0x24 + int(off)] = int(MFRAME[off])
	var buf3b0 := {}
	for off in DFRAME:
		buf3b0[frame * 0x144 + int(off)] = int(DFRAME[off])
	var p := {0x38: buf38, 0x3b0: buf3b0}
	if fx.get("sent", false):
		for off in SENT:
			p[int(off)] = int(SENT[off])

	Pm98Movement.advance(p, int(fx["ring"]), bool(fx["pb"]), bool(fx["rec"]), frame)

	for off in exp:
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got 0x%x want 0x%x" % [name, off, got, want])
