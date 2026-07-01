extends SceneTree
## Oracle-backed parity test for FUN_005a4600 (engine_tick -- the per-player OPEN-PLAY ENGINE, player
## vtable +0xc), ported as Pm98Action.engine_tick. STEP-1 SKELETON: verifies the engine's own inline
## arithmetic + control flow (prologue flags, the 16-tick stamina block, tick_action integration, the
## possession counters, the switch inline arms, the power/interp blocks, and the movement-fn SELECTION).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_engine_tick.gd
##
## ORACLE = the REAL FUN_005a4600 under the Ghidra PCode emulator with the action handlers + resolver +
## shot-setup + teammate-count + 1 movement fn (FUN_005a65a0) + the 6 DEFERRED settle sub-leaves
## STUBBED, run to a clean RET (tools/re/run_engine_oracle.sh -> specs/engine_oracle.txt). Four movement
## fns now run REAL (un-stubbed): FUN_005a7260 (Pm98Movement.ball_touch_7260), FUN_005a8f20
## (Pm98Movement.steer_8f20), FUN_005a8680 (Pm98Movement.settle_8680, wired via _move_8680), and
## FUN_005a9490 (Pm98Movement.lean_9490 A+B+C, wired via _move_9490, un-stubbed s10) -- all
## verified transitively here (settle's slice is field-inert for the settle8680 fixture: branch-2 no-snap,
## p+0x5d=0, its 8f20 early-returns on the pre-set +0x2d7 guard). The other stubbed leaves are NO-OPS here
## too, so the skeleton's field writes still match bit-for-bit. `atexit` (FUN_00605ff0, the steer
## box-init's static-local registration, now reachable via 7260's goal-anchor) is dropped from the
## expected stub list (host artifact, not a game leaf).
##
## Each STUB line in the oracle records the leaf SELECTION + ORDER + arg0. We assert the ordered label
## list plus the two clean args -- B0B40's 0xfffe0000 and M65a0's iStack_38. (M8f20's arg is
## CONCAT22(stale-ECX-high, facing): the low 16 bits are facing, the high bits are uninstantiable
## garbage in the Dict model, so only its label is asserted.)

const P0 := 0x230000
const M0 := 0x260000
const B0 := 0x270000
const GS0 := 0x280000
const U32 := 0xffffffff
const WORD_OFFS := {0x34: true, 0x66: true}
# Stub labels whose arg0 is a clean, reproducible value worth asserting.
const ARG_CHECK := {"B0B40": true, "M65a0": true}

# Per-fixture INPUTS -- mirror tools/re/run_engine_oracle.sh EXACTLY. Anything absent is 0.
#   p/m/b/gs = field dicts (int offset -> int32). refs link identity pointers:
#     m438      -> match+0x438 = the player (is-taker),
#     ball40    -> ball+0x40   = the player (is-controller),
#     playstate -> match+0x468 = a {0xfa0: 0} session (play-state 0).
const FIX := {
	"flag2d8":    {"p": {0x40: 2, 0x48: 5, 0x4: 5, 0x3a4: -5}},
	"stamina16":  {"p": {0x40: 0, 0x48: 5, 0x88: 0xf, 0x68: 0x100, 0x70: 10, 0x74: 100, 0x78: 20},
		"m": {0x19ac: 2700}},
	"case1f":     {"p": {0x40: 0x1f, 0x48: 3}, "b": {0x20: 5, 0x24: 6, 0x28: 7}},
	"settle8680": {"p": {0x40: 2, 0x48: 5, 0x5c: 1}, "m": {0x44c: 7}, "gs": {0x2ee: 1},
		"refs": ["m438", "ball40", "playstate"]},
	"move65a0":   {"p": {0x40: 2, 0x48: 5}, "m": {0x44c: 7}, "refs": ["m438"]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "engine oracle file empty/unreadable (run tools/re/run_engine_oracle.sh)")
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


# Parse specs/engine_oracle.txt into {name: {"mem": {region: {off: val}}, "stubs": [[label, arg0], ...]}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("engine_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx_mem := RegEx.new()
	rx_mem.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	var rx_stub := RegEx.new()
	rx_stub.compile("STUB (\\w+) #[0-9]+ .* arg0=(-?[0-9]+)")
	var cur := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			cur = line.substr(7).strip_edges()
			out[cur] = {"mem": {"p": {}, "b": {}, "m": {}, "gs": {}}, "stubs": []}
		elif cur == "":
			continue
		elif line.find(" STUB ") >= 0:
			var sm := rx_stub.search(line)
			# `atexit` (FUN_00605ff0) is the MSVC static-local registration the steer box-init fires the
			# first time it runs (now reachable because FUN_005a7260 is un-stubbed and its goal-anchor
			# steers). It is a host-runtime artifact, NOT a game leaf -- the GDScript port computes the box
			# inline and never records it -- so it is dropped from the expected selection list.
			if sm and sm.get_string(1) != "atexit":
				out[cur]["stubs"].append([sm.get_string(1), sm.get_string(2).to_int()])
		elif line.find(" RET ") >= 0 or line.find(" HALT ") >= 0:
			for mtch in rx_mem.search_all(line):
				var addr := ("0x" + mtch.get_string(1)).hex_to_int()
				var val := mtch.get_string(2).to_int()
				var region := _region_of(addr)   # [name, base] or []
				if not region.is_empty():
					out[cur]["mem"][region[0]][addr - int(region[1])] = val
	return out


# Map an absolute oracle address to [region-name, base] or [] if outside the known regions.
func _region_of(addr: int) -> Array:
	if addr >= P0 and addr < P0 + 0x4000:
		return ["p", P0]
	if addr >= B0 and addr < B0 + 0x4000:
		return ["b", B0]
	if addr >= M0 and addr < M0 + 0x4000:
		return ["m", M0]
	if addr >= GS0 and addr < GS0 + 0x4000:
		return ["gs", GS0]
	return []


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var p := {}
	var m := {}
	var ball := {}
	var gs := {}
	for off in fx.get("p", {}):
		p[int(off)] = int(fx["p"][off])
	for off in fx.get("m", {}):
		m[int(off)] = int(fx["m"][off])
	for off in fx.get("b", {}):
		ball[int(off)] = int(fx["b"][off])
	for off in fx.get("gs", {}):
		gs[int(off)] = int(fx["gs"][off])
	p[0x18c] = m
	p[0x190] = ball
	p[0x184] = gs
	var refs: Array = fx.get("refs", [])
	if refs.has("m438"):
		m[0x438] = p
	if refs.has("ball40"):
		ball[0x40] = p
	if refs.has("playstate"):
		m[0x468] = {0xfa0: 0}

	Pm98Action.engine_tick(p, m)

	# 1) field writes (player / ball / match / gs).
	var stores := {"p": p, "b": ball, "m": m, "gs": gs}
	for region in exp["mem"]:
		var d: Dictionary = stores[region]
		for off in exp["mem"][region]:
			var mask := 0xffff if (region == "p" and WORD_OFFS.has(off)) else U32
			var got := int(d.get(off, 0)) & mask
			var want := int(exp["mem"][region][off]) & mask
			_ok(got == want, "%s %s+0x%x: got 0x%x want 0x%x" % [name, region, off, got, want])

	# 2) leaf SELECTION + ORDER (+ the two clean args).
	var got_stubs: Array = Pm98Action.trace_calls
	var want_stubs: Array = exp["stubs"]
	_ok(got_stubs.size() == want_stubs.size(),
		"%s stub count: got %d %s want %d %s" % [name, got_stubs.size(), _labels(got_stubs),
			want_stubs.size(), _labels(want_stubs)])
	for i in mini(got_stubs.size(), want_stubs.size()):
		_ok(String(got_stubs[i][0]) == String(want_stubs[i][0]),
			"%s stub #%d label: got %s want %s" % [name, i, got_stubs[i][0], want_stubs[i][0]])
		if ARG_CHECK.has(String(want_stubs[i][0])):
			_ok((int(got_stubs[i][1]) & U32) == (int(want_stubs[i][1]) & U32),
				"%s stub #%d %s arg: got 0x%x want 0x%x" % [name, i, want_stubs[i][0],
					int(got_stubs[i][1]) & U32, int(want_stubs[i][1]) & U32])


func _labels(stubs: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for s in stubs:
		out.append(String(s[0]))
	return out
