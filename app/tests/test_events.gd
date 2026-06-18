extends SceneTree
## Oracle-backed parity test for the EXACT match-event-queue layer (Stage 3 task 2):
## FUN_00594470 (enqueue) + FUN_005909f0 (keeper_event), ported in Pm98Events.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_events.gd
##
## ORACLE = the PM98 binary's own queue functions under the Ghidra PCode emulator
## (tools/re/run_event_oracle.sh, realloc FUN_005bbf10 stubbed + buffer pre-set),
## banked at tools/re/specs/event_oracle.txt. The fixture INPUTS are embedded below
## (mirroring the runner's matrices); the EXPECTED outputs are read from the banked
## file so there is no transcription. A final composition check fires the now-
## available keeper_save -> keeper_event wire the previous session deferred.

const U32 := 0xffffffff

# enqueue fixtures (mirror run_event_oracle.sh ENQ_MATRIX). `player` present -> the
# event copies player+0x2b8/+0x2c0; phase drives the FUN_005943d0/b0 0x1a2c gate.
const ENQ_FIXTURES := {
	"basic":      {"code": 0x10, "player": true,  "flag": 0, "phase": 1, "px": 0x111, "py": 0x222, "freeze": 0},
	"noplayer":   {"code": 0x10, "player": false, "flag": 0, "phase": 1, "px": 0,     "py": 0,     "freeze": 0},
	"flag1":      {"code": 0x10, "player": true,  "flag": 1, "phase": 1, "px": 0x5,   "py": 0x6,   "freeze": 0},
	"phase4skip": {"code": 0x1,  "player": false, "flag": 1, "phase": 4, "px": 0,     "py": 0,     "freeze": 0},
	"phase4upd":  {"code": 0x2,  "player": false, "flag": 3, "phase": 4, "px": 0,     "py": 0,     "freeze": 0},
	"frozen":     {"code": 0x10, "player": true,  "flag": 0, "phase": 1, "px": 0x111, "py": 0x222, "freeze": 1},
}

# keeper_event fixtures (mirror run_event_oracle.sh KEV_MATRIX). save_flag selects the
# stat counter; bits = match+0x462 band byte that gates the 0x15/0x16 enqueue.
const KEV_FIXTURES := {
	"save_b40":   {"save_flag": 0, "bits": 0x40, "phase": 1, "kx": 0x777, "ky": 0x888},
	"save_b20":   {"save_flag": 0, "bits": 0x20, "phase": 1, "kx": 0x777, "ky": 0x888},
	"save_nobit": {"save_flag": 0, "bits": 0x0,  "phase": 1, "kx": 0x777, "ky": 0x888},
	"conceded":   {"save_flag": 1, "bits": 0x40, "phase": 1, "kx": 0x777, "ky": 0x888},
	"save_b80":   {"save_flag": 0, "bits": 0x80, "phase": 1, "kx": 0x777, "ky": 0x888},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_event_oracle()
	var enq: Dictionary = orc.get("enq", {})
	var kev: Dictionary = orc.get("kev", {})
	if enq.is_empty() or kev.is_empty():
		_ok(false, "event oracle file empty/unreadable")
	for name in ENQ_FIXTURES:
		if not enq.has(name):
			_ok(false, "enq " + name + ": missing from oracle file")
			continue
		_run_enq_fixture(name, enq[name])
	for name in KEV_FIXTURES:
		if not kev.has(name):
			_ok(false, "kev " + name + ": missing from oracle file")
			continue
		_run_kev_fixture(name, kev[name])
	_run_integration(kev.get("save_b40", {}))
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


func _eq(name: String, field: String, got: int, want: int) -> void:
	_ok((got & U32) == (want & U32), "%s %s: got %d want %d" % [name, field, got & U32, want & U32])


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _load_event_oracle() -> Dictionary:
	# enqueue lines:      "E name | count | code | x | y | delay | a2c | a30 | RET?"
	# keeper_event lines: "K name | s80 | s7c | count | code | x | y | delay | a2c | a30 | RET?"
	var enq := {}
	var kev := {}
	var f := FileAccess.open(_spec_path("event_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var c := line.split("|")
		var head := c[0].strip_edges().split(" ", false)
		if head.size() < 2:
			continue
		var tag := head[0]
		var nm := head[1]
		if tag == "E" and c.size() >= 9:
			enq[nm] = {
				"count": c[1].strip_edges().to_int(), "code": c[2].strip_edges().to_int(),
				"x": c[3].strip_edges().to_int(), "y": c[4].strip_edges().to_int(),
				"delay": c[5].strip_edges().to_int(), "a2c": c[6].strip_edges().to_int(),
				"a30": c[7].strip_edges().to_int(),
			}
		elif tag == "K" and c.size() >= 11:
			kev[nm] = {
				"s80": c[1].strip_edges().to_int(), "s7c": c[2].strip_edges().to_int(),
				"count": c[3].strip_edges().to_int(), "code": c[4].strip_edges().to_int(),
				"x": c[5].strip_edges().to_int(), "y": c[6].strip_edges().to_int(),
				"delay": c[7].strip_edges().to_int(), "a2c": c[8].strip_edges().to_int(),
				"a30": c[9].strip_edges().to_int(),
			}
	return {"enq": enq, "kev": kev}


# Assert the queue tail + bookkeeping against the banked oracle. `exp.count` == 0 means
# the binary wrote nothing (frozen / no-enqueue); the GDScript queue must be empty too.
func _check_queue(name: String, m: Dictionary, exp: Dictionary) -> void:
	var q: Array = m.get(0x1a24, [])
	_eq(name, "count", int(m.get(0x1a28, 0)), exp.count)
	_eq(name, "a2c", int(m.get(0x1a2c, 0)), exp.a2c)
	_eq(name, "a30", int(m.get(0x1a30, 0)), exp.a30)
	if exp.count == 0:
		_ok(q.is_empty(), "%s: queue should be empty, has %d" % [name, q.size()])
		return
	if q.is_empty():
		_ok(false, "%s: queue empty but oracle has an event" % name)
		return
	var ev: Array = q.back()
	_eq(name, "ev.code", int(ev[0]), exp.code)
	_eq(name, "ev.x", int(ev[1]), exp.x)
	_eq(name, "ev.y", int(ev[2]), exp.y)
	_eq(name, "ev.delay", int(ev[3]), exp.delay)


func _run_enq_fixture(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = ENQ_FIXTURES[name]
	var m := {0x1a38: fx.freeze, 0x468: {0xfa0: fx.phase}}
	var player: Dictionary = {0x2b8: fx.px, 0x2c0: fx.py} if fx.player else {}
	Pm98Events.enqueue(m, fx.code, player, fx.flag)
	_check_queue("e_" + name, m, exp)


func _run_kev_fixture(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = KEV_FIXTURES[name]
	var stat := {}
	var keeper := {0x3b8: stat, 0x2b8: fx.kx, 0x2c0: fx.ky}
	var m := {0x462: fx.bits, 0x468: {0xfa0: fx.phase}}
	var b := {0x4c: 0, 0x50: keeper, 0x1d4: m}
	Pm98Events.keeper_event(b, fx.save_flag)
	_eq("k_" + name, "s80", int(stat.get(0x80, 0)), exp.s80)
	_eq("k_" + name, "s7c", int(stat.get(0x7c, 0)), exp.s7c)
	_check_queue("k_" + name, m, exp)


# Composition: the keeper_save -> keeper_event wire deferred last session. The "save"
# keeper fixture (oracle-locked save=true in test_predicates) feeds keeper_event with a
# 0x40 band; the result must match the save_b40 keeper_event oracle (code 0x16, stat++).
func _run_integration(exp_b40: Dictionary) -> void:
	if exp_b40.is_empty():
		_ok(false, "integration: save_b40 oracle missing")
		return
	# keeper_save on the locked "save" geometry -> save == true.
	var box := {0x1820: 0x100000, 0x1828: 0xF0000, 0x182c: -0x30000, 0x1830: 0x0,
			0x1834: 0x110000, 0x1838: 0x30000, 0x183c: 0x20000, 0x19a0: 0}
	var bs := {4: 0x140000, 8: -0x10000, 0xc: 0x10000, 0x4c: 0, 0x50: 1, 0x61: 1}
	var ks := {4: 0xC0000, 8: 0x10000, 0xc: 0, 0x34: 0, 0x2b8: 0, 0x3a4: 0}
	var res: Dictionary = Pm98Predicates.keeper_save(bs, box, ks)
	_ok(bool(res.save), "integration: keeper_save should fire save")
	# Now fire the deferred event (save_flag=0 as the binary's 58f307 push 0) with the
	# keeper present and a 0x40 band, mirroring the binary's 58f30b call before clear.
	var stat := {}
	var keeper := {0x3b8: stat, 0x2b8: 0x777, 0x2c0: 0x888}
	var m := {0x462: 0x40, 0x468: {0xfa0: 1}}
	var b := {0x4c: 0, 0x50: keeper, 0x1d4: m}
	Pm98Events.keeper_event(b, 0)
	_eq("integ", "s80", int(stat.get(0x80, 0)), exp_b40.s80)
	var q: Array = m.get(0x1a24, [])
	_ok(not q.is_empty(), "integration: keeper_event should enqueue")
	if not q.is_empty():
		_eq("integ", "ev.code", int(q.back()[0]), exp_b40.code)
