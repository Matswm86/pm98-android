extends SceneTree
## Oracle-backed parity test for the per-player marking-target selector (Stage 3 task 2,
## slice 3): FUN_005b36f0 (Pm98Movement.select_mark_target), the leaf of the marker-
## assignment pass FUN_005b94f0.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_marktarget.gd
##
## ORACLE = the PM98 binary's own FUN_005b36f0 under the Ghidra PCode emulator
## (tools/re/run_marktarget_oracle.sh; pure selector, no float-import so no _ftol/LUT
## injection), banked at specs/marktarget_oracle.txt as one `CALL 0 RET ... EAX=<ptr>`
## line per fixture. The fixture INPUTS are mirrored below (defaults + per-fixture
## overrides matching the runner); the EXPECTED output is the returned pointer EAX,
## mapped to the opp-index model via (EAX - 0x240000) / 0x3bc (0 -> none = -1).

const Q_BASE := 0x240000
const Q_STRIDE := 0x3bc

# Defaults mirror run_marktarget_oracle.sh's base spec (the search_pick scenario).
const DEF := {
	"tgt": -1, "m310": 0, "td300": 0, "td2fc": 0, "scale": 0,
	"px": 0x40000, "panchor": 0x40000, "p1e0": 0,
	"bxmin": 0, "bymin": 0, "bzmin": 0, "bxmax": 0x1000000, "bymax": 0x1000000, "bzmax": 0x1000000,
	# +0x154 marker links use -1 = none (index 0 is a real player); "taken" = any index >=0.
	"q0x": 0x50000, "q0y": 0x50000, "q0z": 0, "q0anchor": 0, "q0taken": -1,
	"q1x": 0x30000, "q1y": 0x30000, "q1z": 0, "q1anchor": 0, "q1taken": -1,
	"pq0": 0x50000, "pq1": 0x90000, "q0p": 0x40000, "q0p1": 0x80000, "q1p": 0x70000, "q1p1": 0x30000,
}

# Per-fixture overrides (must match the runner's FIX poke deltas exactly).
const FIXTURES := {
	"keep_box": {"tgt": 0},
	"invalid_search": {"tgt": 1, "q1x": 0x2000000},
	"keep_alt": {"tgt": 0, "m310": 1, "td300": 0x100000, "td2fc": 0x80000},
	"search_pick": {},
	"recip_filter": {"q0p": 0x80000, "q0p1": 0x40000, "q1p": 0x30000, "q1p1": 0x70000},
	"taken_skip": {"q0taken": 0, "q1p": 0x30000, "q1p1": 0x70000},
	"penalty_box": {"pq0": 0x80000, "pq1": 0x60000, "q1x": 0x2000000, "q1p": 0x30000, "q1p1": 0x70000},
	"penalty_flip": {"pq0": 0x80000, "pq1": 0x60000, "q0z": 0x1000, "q1x": 0x2000000, "q1p": 0x30000, "q1p1": 0x70000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "marktarget oracle file empty/unreadable")
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


func _eax_to_opp(eax: int) -> int:
	if eax == 0:
		return -1
	return (eax - Q_BASE) / Q_STRIDE


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("marktarget_oracle.txt"), FileAccess.READ)
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


func _build_ctx(o: Dictionary) -> Dictionary:
	var d0 := Pm98Movement._dist_off(0, 0)   # 0xe4  (our slot 0 = P)
	var d1 := Pm98Movement._dist_off(1, 0)   # 0xe8  (our slot 1 = P1)
	var dq0 := Pm98Movement._dist_off(0, 1)  # 0x110 (opp slot 0 = Q0)
	var dq1 := Pm98Movement._dist_off(1, 1)  # 0x114 (opp slot 1 = Q1)
	var p := {
		0x4: int(o.px), 0x8: 0x40000, 0xc: 0, 0x3a4: int(o.panchor), 0x1e0: int(o.p1e0),
		0x2b8: 0, 0x2bc: 1, 0x2c4: 0, 0xb0: int(o.tgt),
		0x210: int(o.bxmin), 0x214: int(o.bymin), 0x218: int(o.bzmin),
		0x21c: int(o.bxmax), 0x220: int(o.bymax), 0x224: int(o.bzmax),
		dq0: int(o.pq0), dq1: int(o.pq1),
	}
	var p1 := {0x2b8: 0, 0x2bc: 1, 0x2c4: 1, 0x4: 0, 0x8: 0, 0xc: 0, 0x3a4: 0}
	var q0 := {
		0x4: int(o.q0x), 0x8: int(o.q0y), 0xc: int(o.q0z), 0x3a4: int(o.q0anchor),
		0x2b8: 1, 0x2bc: 1, 0x2c4: 0, 0x154: int(o.q0taken), d0: int(o.q0p), d1: int(o.q0p1),
	}
	var q1 := {
		0x4: int(o.q1x), 0x8: int(o.q1y), 0xc: int(o.q1z), 0x3a4: int(o.q1anchor),
		0x2b8: 1, 0x2bc: 1, 0x2c4: 1, 0x154: int(o.q1taken), d0: int(o.q1p), d1: int(o.q1p1),
	}
	var m := {0x78c: [q0, q1], 0x1820: int(o.scale)}
	var td := {0x2fc: int(o.td2fc), 0x300: int(o.td300), 0x310: int(o.m310)}
	return {"players": [p, p1], 0x8: 0, 0x138: m, "team_desc": td}


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var ctx := _build_ctx(_merged(name))
	var got := Pm98Movement.select_mark_target(ctx, 0)
	var want := _eax_to_opp(int(exp.eax))
	_ok(got == want, "%s: got opp %d want opp %d (EAX=%d)" % [name, got, want, int(exp.eax)])
