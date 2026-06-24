extends SceneTree
## Oracle-backed parity test for the KICKOFF-TAKER slice of FUN_005a65a0 (the movement dispatcher) and
## its kick-setup FUN_005aa4d0, ported in Pm98Movement.move_dispatch / kick_setup / pass_target_select.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_kicksetup.gd
##
## ORACLE = the REAL FUN_005a65a0 under the Ghidra PCode emulator on a kickoff-taker fixture
## (tools/re/run_kicksetup_oracle.sh -> specs/kicksetup_oracle.txt). The runner zeroes the struct
## windows P/M/C/T/TGT and pokes only the links below, with the LCG seed (DAT_006d3184) = 1. Row:
##   M <name> | action | v54 | c+0x4c | p+0x80 | RET
## c+0x4c is the absolute TGT address (0x270000) in the emulator; here we assert C[0x4c] IS the TGT
## Dict (identity). action / v54 / p+0x80 are read straight from the banked oracle (no transcription).
##
## The fixture PRESETS p+0xb4 (the pass target) non-null, so FUN_005aa680 is skipped -- the oracle does
## NOT cover the pass-target selector (that gets its own oracle). pass_target_select gets a light
## functional check below (nearest in-cone teammate), NOT an emulator oracle.

const U32 := 0xffffffff

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "kicksetup oracle empty/unreadable (run tools/re/run_kicksetup_oracle.sh)")
	else:
		for onp in [1, 0]:
			var name := "onpitch" if onp == 1 else "offpitch"
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run_dispatch(name, onp, orc[name])
	_check_pass_target()

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


# Parse the 2 data rows of specs/kicksetup_oracle.txt into {name: {action, v54, p80}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("kicksetup_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("M "):
			continue
		var cols := line.split("|")
		if cols.size() < 5:
			continue
		var name := cols[0].substr(1).strip_edges()
		out[name] = {
			"action": cols[1].strip_edges().to_int(),
			"v54": cols[2].strip_edges().to_int(),
			"p80": cols[4].strip_edges().to_int(),
		}
	return out


# Build the kickoff-taker fixture (mirrors run_kicksetup_oracle.sh) and drive move_dispatch.
func _run_dispatch(name: String, onpitch: int, exp: Dictionary) -> void:
	var P := {}
	var M := {}
	var C := {}
	var T := {}
	var TGT := {}
	P[0x184] = T
	P[0x18c] = M
	P[0x190] = C
	P[0x2bc] = onpitch
	P[0xb4] = TGT
	M[0x448] = 2
	M[0x438] = P
	C[0x40] = P

	var rng := MatchEngine.Pm98Rng.new(1)
	var handled: bool = Pm98Movement.move_dispatch(P, M, rng)

	_ok(handled, "%s: move_dispatch returned true (taker path handled)" % name)
	_ok((int(P.get(0x40, 0)) & U32) == (exp["action"] & U32),
		"%s action P+0x40: got %d want %d" % [name, int(P.get(0x40, 0)), exp["action"]])
	_ok(int(P.get(0x54, 0)) == exp["v54"],
		"%s v54 P+0x54: got %d want %d" % [name, int(P.get(0x54, 0)), exp["v54"]])
	_ok(int(P.get(0x80, 0)) == exp["p80"],
		"%s p+0x80: got %d want %d" % [name, int(P.get(0x80, 0)), exp["p80"]])
	# c+0x4c holds the chosen target -- the preset TGT Dict (oracle's 0x270000), by identity.
	_ok(C.get(0x4c, null) == TGT, "%s c+0x4c is the preset target" % name)
	# the taker path draws exactly twice (velocity + the discarded L244 roll): seed 1 -> 2 advances.
	var ref := MatchEngine.Pm98Rng.new(1)
	ref.next(); ref.next()
	_ok(rng.state == ref.state, "%s drew exactly 2 LCG rolls" % name)


# Light functional check (NOT an emulator oracle): with p+0xb4 unset, pass_target_select picks a
# teammate. Two teammates in the angle cone (matrix angle 0); the nearer-to-the-reach-point wins.
func _check_pass_target() -> void:
	var P := {0x4: 0, 0x8: 0, 0x34: 0, 0x2b8: 0, 0x2c4: 0}
	var M := {0x44c: 0}
	# q1 near the reach point (10.0 ahead along facing 0 -> +x), q2 far. Both in-cone (matrix ang 0).
	var q1 := {0x4: 0xa0000, 0x8: 0, 0x2b8: 0, 0x2c4: 1}
	var q2 := {0x4: 0x500000, 0x8: 0, 0x2b8: 0, 0x2c4: 2}
	# p holds the relationship-matrix angle for each teammate slot (0 -> inside the 0x18e4 cone).
	P[Pm98Movement._angle_off(1, 0)] = 0
	P[Pm98Movement._angle_off(2, 0)] = 0
	var T := {0: [P, q1, q2]}
	P[0x184] = T
	P[0x18c] = M
	var got := Pm98Movement.pass_target_select(P, M)
	_ok(got == q1, "pass_target_select picks the nearer in-cone teammate (got %s)" %
		("q1" if got == q1 else ("q2" if got == q2 else "none")))
