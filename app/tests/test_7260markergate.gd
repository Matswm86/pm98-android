extends SceneTree
## Oracle-backed parity test for FUN_005a7260 marker-grid ENTRY GATES (slice 2b-iii-a):
## Pm98Movement._marker_gate_proceed == the real binary's gate outcome at 0x5a7d9e (run the marker
## search at 0x5a7e23 vs skip to the tail at 0x5a8457).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260markergate.gd
##
## ORACLE = the REAL FUN_005a7260 entered mid-function at 0x5a7d9e (ESI=p, EBP=p+4), tracing
## GRID@0x5a7e23 vs TAIL@0x5a8457: tools/re/run_7260markergate_oracle.sh -> specs/7260markergate_oracle.txt
##   (MGATE <name> proceed=<0|1> ...). We rebuild the identical p/ball/gs/m Dicts and assert the
## GDScript proceed bool == the oracle's.

var _fail := 0
var _pass := 0


# name -> the p Dict it builds (mirrors run_7260markergate_oracle.sh FIX rows). p.pos = 0; ball @ p[0x190];
# gs @ p[0x184], m @ gs[0x138]. In possession when gs[8] == m[0x1664] (both default 0 -> in possession).
func _build(name: String) -> Dictionary:
	var m := {}                                              # m[0x1664] default 0
	var gs := {0x138: m}                                     # gs[8] default 0 -> in possession
	var ball := {}
	var p := {4: 0, 8: 0, 0xc: 0, 0x184: gs, 0x190: ball}
	match name:
		"near_loose":
			gs[8] = 1                                        # gs[8]=1 != m[0x1664]=0 -> NOT in possession
		"far_x":
			ball[4] = 0x230000                               # |Δx| = 0x230000 >= threshold
		"far_y_neg":
			ball[8] = -0x230000                              # abs = 0x230000 >= threshold
		"far_z":
			ball[0xc] = 0x230000
		"near_boundary":
			ball[4] = 0x22ffff                               # just inside; not in possession
			gs[8] = 1
		"poss_carrier":
			ball[0x40] = 0x999                               # in possession, carrier != 0 -> tail
		"poss_loose_match44":
			ball[0x44] = p                                   # in possession, loose, ball+0x44 == p -> GRID
		"poss_loose_nomatch44":
			ball[0x44] = 0x111                               # in possession, loose, ball+0x44 != p -> tail
	return p


func _init() -> void:
	var o := _load("7260markergate_oracle.txt")
	if o.is_empty():
		_ok(false, "marker-gate oracle empty (run tools/re/run_7260markergate_oracle.sh)")
	else:
		for name in o:
			var p := _build(name)
			var got: bool = Pm98Movement._marker_gate_proceed(p)
			var want: bool = o[name]
			_ok(got == want, "mgate/%s: proceed=%s want=%s" % [name, got, want])
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


# name -> bool (proceed), parsed from `MGATE <name> proceed=<0|1> ...`.
func _load(fname: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path(fname), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("MGATE "):
			continue
		var parts := line.split(" ", false)
		var name := parts[1]
		for tok in parts:
			if tok.begins_with("proceed="):
				out[name] = tok.substr(8).to_int() == 1
	return out
