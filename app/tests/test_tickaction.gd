extends SceneTree
## Oracle-backed parity test for FUN_005a50c0 (tick_action -- the per-player action / animation-phase
## advancer that FUN_005a4600 calls first) + FUN_005aac30 (setup_kick), ported in Pm98Action.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_tickaction.gd
##
## ORACLE = the REAL FUN_005a50c0 under the Ghidra PCode emulator, sub-calls real, run to a clean RET
## (tools/re/run_tickaction_oracle.sh -> specs/tickaction_oracle.txt). Covers the common path (timer
## lock / sub-wrap / forward advance + next-action / reverse / the 0x15 90deg turn) and all four 0x1d
## windup tiers (-0x50 latch, -100 lob, -0x78 release via real setup_kick, t==0 kick release).

const P0 := 0x230000
const U32 := 0xffffffff
# +0x34 and +0x66 are WORD fields -> compare modulo 16 bits.
const WORD_OFFS := {0x34: true, 0x66: true}

# Per-fixture INPUT player fields (mirror tools/re/run_tickaction_oracle.sh exactly). Anything absent is 0.
const FIX := {
	"timer_lock":    {"in": {0x40: 2,    0x48: 5,      0x30: 0, 0x2c: 7}},
	"sub_nz":        {"in": {0x40: 2,    0x48: 0,      0x30: 1, 0x2c: 7}},
	"fwd_nowrap":    {"in": {0x40: 2,    0x30: 3, 0x68: 5,      0x2c: 3}},
	"fwd_wrap_next": {"in": {0x40: 6,    0x30: 3, 0x68: 5,      0x2c: 11}},
	"reverse":       {"in": {0x40: 2,    0x30: 3, 0x68: -1,     0x2c: 0}},
	"act15":         {"in": {0x40: 0x15, 0x30: 3, 0x68: 5,      0x2c: 13, 0x34: 0x2000}},
	"w_tier1":       {"in": {0x40: 0x1d, 0x48: -0x50, 0x30: 1,  0x2c: 5}},
	"w_tier2":       {"in": {0x40: 0x1d, 0x48: -0x64, 0x30: 1,  0x2c: 5, 0x34: 0x1000,
		0x4: 0x40000, 0x8: 0x50000, 0xc: 0x60000}},
	"w_release":     {"in": {0x40: 0x1d, 0x48: -0x78, 0x34: 0x800,
		0x20: 0x100, 0x24: 0x200, 0x28: 0x300, 0x4: 0x40000, 0x8: 0x50000, 0xc: 0x60000},
		"skip_eax": true},   # -0x78 returns setup_kick's (void) garbage EAX; caller discards it
	"kick_release":  {"in": {0x40: 0x1d, 0x48: 0, 0x30: 1, 0x2c: 5, 0x34: 0x1500,
		0x4: 0x40000, 0x8: 0x50000, 0xc: 0x60000}},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "tickaction oracle file empty/unreadable (run tools/re/run_tickaction_oracle.sh)")
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


# Parse each "FIX <name> ... EAX=<v> ... mem[0xADDR:W]=val ..." row -> {"eax": v, "mem": {off: val}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("tickaction_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx_mem := RegEx.new()
	rx_mem.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	var rx_eax := RegEx.new()
	rx_eax.compile("EAX=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var mem := {}
		for mtch in rx_mem.search_all(line):
			mem[("0x" + mtch.get_string(1)).hex_to_int() - P0] = mtch.get_string(2).to_int()
		var eax_m := rx_eax.search(line)
		out[toks[1]] = {"eax": (eax_m.get_string(1).to_int() if eax_m else 0), "mem": mem}
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	# Build the player; link ball (ball+0x40 == player, so the player is the controller for setup_kick).
	var p := {}
	for off in fx["in"]:
		p[int(off)] = int(fx["in"][off])
	var ball := {0x40: p}
	p[0x190] = ball
	var m := {0x448: 0}   # match phase 0 -> the t==0 path takes no enqueue/RNG/sound branch
	p[0x18c] = m

	var ret: int = Pm98Action.tick_action(p, m)

	if not fx.get("skip_eax", false):
		_ok((ret & U32) == (int(exp["eax"]) & U32),
			"%s EAX: got 0x%x want 0x%x" % [name, ret & U32, int(exp["eax"]) & U32])
	var mem: Dictionary = exp["mem"]
	for off in mem:
		var mask := 0xffff if WORD_OFFS.has(off) else U32
		var got := int(p.get(off, 0)) & mask
		var want := int(mem[off]) & mask
		_ok(got == want, "%s +0x%x: got 0x%x want 0x%x" % [name, off, got, want])
