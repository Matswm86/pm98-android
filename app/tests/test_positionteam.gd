extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice A (the per-team positioning pass, OPEN-PLAY
## path), ported in Pm98Movement.position_team.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_positionteam.gd
##
## ORACLE = the REAL FUN_005b73a0 under the Ghidra PCode emulator for a non-set-piece phase
## (tools/re/run_positionteam_oracle.sh -> specs/positionteam_oracle.txt): relmatrix (throttled
## skip) + reset ctx+0x2e0 = -1 + TAIL return; no player touched. This test mirrors that and asserts
## ctx+0x2e0 == -1 and the player position is unchanged.

const U32 := 0xffffffff
const FIX := {"phase0": 0, "phase1": 1, "phase6": 6}        # all non-set-piece -> open-play no-op path

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "positionteam oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, int(FIX[name]), orc[name])
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


# Parse "FIX <name> ... mem[0xADDR:W]=val ...": row -> {absolute_addr: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("positionteam_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, phase: int, exp: Dictionary) -> void:
	var player := {0x4: 0x12340000}
	var m := {0x448: phase, 0x19cc: 0, 0x45c: 0}
	var ctx := {0x0: 0, 0x4: 1, 0x8: 0, 0x138: m, 0x2e0: 0, "players": [player]}

	Pm98Movement.position_team(ctx)

	# ctx+0x2e0 (@0x2302e0) -> -1 ; player+0x4 (@0x240004) -> unchanged sentinel.
	_ok((int(ctx.get(0x2e0, 0)) & U32) == (int(exp[0x2302e0]) & U32),
		"%s ctx+0x2e0: got %d want %d" % [name, int(ctx.get(0x2e0, 0)) & U32, int(exp[0x2302e0]) & U32])
	_ok((int(player.get(0x4, 0)) & U32) == (int(exp[0x240004]) & U32),
		"%s player+0x4: got 0x%x want 0x%x" % [name, int(player.get(0x4, 0)) & U32, int(exp[0x240004]) & U32])
