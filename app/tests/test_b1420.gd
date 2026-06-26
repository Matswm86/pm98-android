extends SceneTree
## Oracle-backed parity test for FUN_005b1420 (the settle off-ball formation gate):
## Pm98Movement.formation_gate_b1420 maintains the p+0x14c counter + selects the SAME leaf + returns the
## same byte (where the byte is real, i.e. the b0040 / freeze arms) as the REAL binary.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b1420.gd
##
## ORACLE = the REAL FUN_005b1420 entered at 0x5b1420 (ECX=P), with the 3 dispatch leaves STUBBED and
## FUN_005943b0 executed for real: tools/re/run_b1420_oracle.sh -> specs/b1420_oracle.txt. Each `## FIX
## <name>` block carries a STUB line (B0040/B1500/B1C80; absent under the set-piece freeze) and a RET
## line (EAX = return byte, mem[0x23014c] = the counter). We rebuild the identical P/M/BALL/GS/SUB Dicts
## and assert: the leaf SELECTION (b1420_trace), the p+0x14c counter, and -- where the binary's return is
## NOT a stub sentinel (the b0040 / freeze arms return the real 1) -- the return byte.

var _fail := 0
var _pass := 0

# name -> fixture builder cfg (mirrors run_b1420_oracle.sh FIX rows). Unlisted offsets default to 0.
var _fix := {
	"b0040":         {"anchor": true},
	"b1500_carrier": {"carrier": true, "c0": 5, "bteam": 7},
	"b1c80":         {},
	"b1c80_carrier": {"carrier": true, "c0": 9},
	"freeze":        {"gs2ee": 1, "lock": 1, "subphase": 0},
	"freeze_phase":  {"gs2ee": 1, "lock": 1, "subphase": 2},
	"freeze_nolock": {"gs2ee": 1, "lock": 0, "subphase": 0},
}


func _init() -> void:
	var o := _load("b1420_oracle.txt")
	if o.is_empty():
		_ok(false, "b1420 oracle empty (run tools/re/run_b1420_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from b1420 oracle")
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _s32(v: int) -> int:
	return v - 0x100000000 if v >= 0x80000000 else v


# Parse the oracle into name -> {leaf:String, counter:int, eax:int}. leaf "" = the freeze (no stub).
func _load(fname: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path(fname), FileAccess.READ)
	if f == null:
		return {}
	var cur := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			cur = line.substr(7).strip_edges()
			out[cur] = {"leaf": "", "counter": 0, "eax": 0}
		elif cur != "" and line.begins_with("CALL 0 STUB "):
			out[cur]["leaf"] = line.split(" ", false)[3]
		elif cur != "" and line.begins_with("CALL 0 RET "):
			for tok in line.split(" ", false):
				if tok.begins_with("EAX="):
					out[cur]["eax"] = int(tok.substr(4))
				elif tok.begins_with("mem[0x23014c:4]="):
					out[cur]["counter"] = _s32(int(tok.substr(tok.find("=") + 1)))
	return out


func _run(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _fix[name]
	var sub := {0xfa0: int(cfg.get("subphase", 0))}
	var m := {0x468: sub}
	var gs := {0x2ee: int(cfg.get("gs2ee", 0))}
	var ball := {0x54: int(cfg.get("bteam", 0))}
	var p := {
		0x18c: m, 0x190: ball, 0x184: gs,
		0x14c: int(cfg.get("c0", 0)), 0x2b8: 0, 0x5c: int(cfg.get("lock", 0))}
	if cfg.get("anchor", false):
		gs[0x204] = p                                        # GS+0x204 = P (formation-anchor slot)
	if cfg.get("carrier", false):
		ball[0x40] = p                                       # BALL+0x40 = P (P holds the ball)

	var ret := Pm98Movement.formation_gate_b1420(p, false)   # wire=false: leaf trace-only (no _move_b0040)

	# Leaf SELECTION: the oracle's STUB label (or "" under the freeze) vs b1420_trace.
	var got_leaf := ""
	if Pm98Movement.b1420_trace.size() > 0:
		got_leaf = String((Pm98Movement.b1420_trace[0] as Array)[0])
	_ok(got_leaf == String(want["leaf"]),
		"b1420/%s leaf: got '%s' want '%s'" % [name, got_leaf, String(want["leaf"])])

	# Counter p+0x14c.
	_ok(int(p.get(0x14c, 0)) == int(want["counter"]),
		"b1420/%s p+0x14c: got %d want %d" % [name, int(p.get(0x14c, 0)), int(want["counter"])])

	# Return byte -- only where the binary's value is REAL (b0040 / freeze return 1, not a stub sentinel).
	if String(want["leaf"]) == "B0040" or String(want["leaf"]) == "":
		_ok((ret & 0xff) == int(want["eax"]),
			"b1420/%s return: got %d want %d" % [name, ret & 0xff, int(want["eax"])])
