extends SceneTree
## Oracle-backed parity test for FUN_005b0bb0 (the AI pass-target test), ported as
## Pm98Movement.mark_pass_receiver. Run:
##   ~/godot462 --headless --path app --script res://tests/test_passtest.gd
## ORACLE = the REAL FUN_005b0bb0 under the PCode emulator (tools/re/run_passtest_oracle.sh ->
## specs/passtest_oracle.txt). Each oracle row: PT <name> RET steps=N EAX=<ret> mem[0x26043c:4]=<recv>
## mem[0x260460:1]=<cooldown>. The return bool is EAX & 0xff; mem[0x43c]!=0 <=> receiver marked.
## Inputs are mirrored here from the shell fixtures (the oracle banks the OUTPUTS only).

var _fail := 0
var _pass := 0


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/passtest_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "passtest oracle unreadable (run tools/re/run_passtest_oracle.sh)")
	else:
		var rx := RegEx.new()
		rx.compile("^PT (\\S+) RET steps=\\d+ EAX=(-?\\d+) mem\\[0x26043c:4\\]=(-?\\d+) mem\\[0x260460:1\\]=(-?\\d+)")
		while not f.eof_reached():
			var m := rx.search(f.get_line().strip_edges())
			if m == null:
				continue
			_check(m.get_string(1), m.get_string(2).to_int(), m.get_string(3).to_int(), m.get_string(4).to_int())
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


## Build the fixture inputs for `name`, run the port, and compare to the oracle outputs.
func _check(name: String, eax: int, want_recv: int, want_cd: int) -> void:
	var fx := _fixture(name)
	if fx.is_empty():
		_ok(false, "%s: no fixture builder" % name)
		return
	var p: Dictionary = fx["p"]
	var m: Dictionary = p[0x18c]
	var got: bool = Pm98Movement.mark_pass_receiver(p, fx["tgt"], fx["angle"], fx["scale"], fx["dist"], fx["opp"])
	var want: bool = (eax & 0xff) != 0
	_ok(got == want, "%s ret: got %s want %s" % [name, got, want])
	if want:
		_ok(m.get(0x43c, null) == p, "%s receiver: match+0x43c should be the player" % name)
		_ok(int(m.get(0x460, -1)) == want_cd, "%s cooldown: got %d want %d" % [name, int(m.get(0x460, -1)), want_cd])
	else:
		_ok(not m.has(0x43c), "%s receiver: match+0x43c must stay unwritten on miss" % name)
		_ok(not m.has(0x460), "%s cooldown: match+0x460 must stay unwritten on miss" % name)


## Mirror of the shell-fixture pokes (run_passtest_oracle.sh). Returns {p, tgt, angle, scale, dist, opp}.
func _fixture(name: String) -> Dictionary:
	var ball := {}
	var match_d := {}
	var p := {0x18c: match_d, 0x190: ball}
	var tgt := [0, 0, 0]
	var angle := 0
	var scale := 0
	var dist := 0x7fffffff
	var opp: Array = []
	match name:
		"owner":
			p[0x4] = 0x200000
			ball[0x4c] = p                       # ball owned by this player -> immediate true
		"toomany":
			p[0x4] = 0x100000
			opp = [{0x4: 0, 0x3a4: 0}, {0x4: 0, 0x3a4: 0}]   # >= 2 goalside opponents
		"farself":
			p[0x4] = 0x200000
			dist = 0x100000                      # |px| = 0x200000 >= dist
		"facereject":
			p[0x68] = 0x800
			p[0x2b8] = 0
			p[0x34] = 0x6000
			match_d[0x1820] = 0x300000
			match_d[0x19a0] = 0
		"proxfail":
			scale = 0x80000
			tgt = [0x300000, 0, 0]               # too far -> AABB miss
		"proxtrue":
			p[0x4] = 0x100000
			scale = 0x80000
			tgt = [0x100000, 0, 0]               # tgt == player.pos -> perp 0 <= thr_base
		"proxfalse":
			p[0x4] = 0x100000
			scale = 0x80000
			tgt = [0x100000, 0x60000, 0]         # perp 0x60000 > thr_base 0x30000
		_:
			return {}
	return {"p": p, "tgt": tgt, "angle": angle, "scale": scale, "dist": dist, "opp": opp}


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
