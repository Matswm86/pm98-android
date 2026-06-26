extends SceneTree
## Oracle-backed parity test for the opponent-count leaf FUN_005b0b40
## (Pm98Action._count_teammates_closer), one of the engine_tick (FUN_005a4600) leaves.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b0b40.gd
##
## ORACLE = the PM98 binary's own FUN_005b0b40 under the Ghidra PCode emulator
## (tools/re/run_b0b40_oracle.sh; pure counter, no float-import so no _ftol/LUT injection),
## banked at specs/b0b40_oracle.txt as one `CALL 0 RET ... EAX=<count>` line per fixture.
## The fixture INPUTS are mirrored below (defaults + per-fixture overrides matching the runner);
## the EXPECTED output is the returned count EAX. arg = 0xfffe0000 (the engine_tick call site).

const ARG := 0xfffe0000

# Defaults mirror run_b0b40_oracle.sh's base spec.
#   self = abs(px + panchor) = 0x80000 ; threshold = arg + self = 0x60000.
#   q metric = abs(qx - qanchor): Q0 0x40000 (counted), Q1 0x40000 (counted, tests '-'),
#   Q2 0x80000 (NOT counted). base != 0 ; count 3.
const DEF := {
	"px": 0x40000, "panchor": 0x40000, "base": 1, "count": 3,
	"q0x": 0x50000, "q0anchor": 0x10000,
	"q1x": 0x10000, "q1anchor": 0x50000,
	"q2x": 0x80000, "q2anchor": 0,
}

# Per-fixture overrides (must match the runner's FIX poke deltas exactly).
const FIXTURES := {
	"count0": {"count": 0},
	"count2": {"count": 2},
	"mixed3": {},
	"boundary": {"count": 2, "q0x": 0x60000, "q0anchor": 0, "q1x": 0x5ffff, "q1anchor": 0},
	"null_base": {"base": 0, "count": 1},
	"negself": {"panchor": -0x40000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "b0b40 oracle file empty/unreadable (run tools/re/run_b0b40_oracle.sh)")
	else:
		for name in FIXTURES:
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


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("b0b40_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		if toks.size() < 5:
			continue
		var eax := 0
		var ret := ""
		for t in toks:
			if t == "RET" or t == "HALT":
				ret = t
			elif t.begins_with("EAX="):
				eax = t.substr(4).to_int()
		out[toks[1]] = {"ret": ret, "eax": eax}
	return out


func _merged(name: String) -> Dictionary:
	var o := DEF.duplicate()
	for k in FIXTURES[name]:
		o[k] = FIXTURES[name][k]
	return o


func _build_player(o: Dictionary) -> Dictionary:
	# The binary's {base, count} opponent descriptor maps to the team's roster Array (the
	# select_mark_target convention): the array length reproduces the count the binary walked,
	# and a null base (oracle `null_base`) -> empty array (the 0xc80000 sentinel never counts).
	var qs: Array = [
		{0x4: int(o.q0x), 0x3a4: int(o.q0anchor)},
		{0x4: int(o.q1x), 0x3a4: int(o.q1anchor)},
		{0x4: int(o.q2x), 0x3a4: int(o.q2anchor)},
	]
	var players: Array = [] if int(o.base) == 0 else qs.slice(0, int(o.count))
	return {0x4: int(o.px), 0x3a4: int(o.panchor), 0x188: {"players": players}}


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var p := _build_player(_merged(name))
	var got := Pm98Action._count_teammates_closer(p, ARG)
	var want := int(exp.eax)
	_ok(got == want, "%s: got %d want %d" % [name, got, want])
