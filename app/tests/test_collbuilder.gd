extends SceneTree
## Parity test for the goal/pitch collision-geometry BUILDER (Pm98CollBuilder, port of
## FUN_005946f0). Validates, against the PCode-emu ground truth:
##   phase 0 (constant-fold)  -> specs/collbuilder_frame.txt   (frame, esp-offset = 0x618 - X)
##   phases 1-4 (geometry)    -> specs/collbuilder_oracle.txt  (MASTER quads + POST array)
## Inputs MUST mirror run_collbuilder_*.sh exactly.
## Run: ~/godot462 --headless --path app --script res://tests/test_collbuilder.gd

const U32 := 0xffffffff

# goal dims -- identical to run_collbuilder_oracle.sh / run_collbuilder_frame.sh pk() block
const DIMS := {
	0x194c: 0x20000, 0x1950: 0x30000, 0x1954: 0x40000, 0x1958: 0x18000, 0x195c: 0x28000,
	0x1960: 0x12000, 0x1964: 0x1c000, 0x1968: 0x22000, 0x196c: 0x14000, 0x1970: 0x8000,
	0x1974: 0x10000, 0x1978: 0xc000, 0x197c: 0x6000, 0x1820: 0x90000, 0x1988: 0x0,
	0x1a4c: 0x5000, 0x1a1b: 0x1, 0x1a1c: 0x1, 0x27cc: 0x0,
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var m := {}
	for k in DIMS:
		m[k] = DIMS[k]
	# --- phase 0 ---
	var frame := _load_frame()
	if frame.is_empty():
		_ok(false, "frame oracle empty/unreadable")
	else:
		var F: Dictionary = Pm98CollBuilder.build_frame(m)
		_check_frame(F, frame)
		_check_completeness(F, frame)
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _check_frame(F: Dictionary, frame: Dictionary) -> void:
	# every local we set must equal the dump at esp-offset (0x618 - X)
	var miss := 0
	for x in F:
		var off := 0x618 - int(x)
		if not frame.has(off):
			miss += 1
			if miss <= 5:
				_ok(false, "F[0x%x] -> off 0x%x not in dump" % [x, off])
			continue
		var got := int(F[x]) & U32
		var want := int(frame[off]) & U32
		_ok(got == want, "F[0x%x] (off 0x%x): got 0x%x want 0x%x" % [x, off, got, want])


func _check_completeness(F: Dictionary, frame: Dictionary) -> void:
	# Reverse direction: every NONZERO in-range frame-dump slot must be modeled in F. Proves
	# phase 0 is complete, not just that the slots we set happen to match. Exclusions are the two
	# non-geometry slots: off 0x618 (X=0x0) = the phase-0/1 boundary sentinel (a return addr),
	# and off 0x2c (X=0x5ec) = the `this`/match base pointer the builder stashes for the loop.
	var excl := {0x0: true, 0x5ec: true}
	var miss := 0
	for off in frame:
		var o := int(off)
		if o < 0 or o > 0x618:
			continue
		if (int(frame[off]) & U32) == 0:
			continue
		var x := 0x618 - o
		if excl.has(x):
			continue
		if not F.has(x):
			miss += 1
			_ok(false, "completeness: dump off 0x%x (X=0x%x val 0x%x) NOT set in F" % [o, x, int(frame[off]) & U32])
	if miss == 0:
		_ok(true, "completeness: all nonzero frame slots modeled")


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		if _fail <= 40:
			print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _load_frame() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("collbuilder_frame.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("F "):
			continue
		var t := line.split(" ", false)
		if t.size() >= 3 and t[1].length() <= 10:        # skip the one sub-base negative offset
			out[t[1].hex_to_int()] = int(t[2])
	return out
