extends SceneTree
## Oracle-backed parity test for the phase-based active-player selector (Stage 3 task 2,
## slice 5b): the two FUN_005b8f20 branches deferred from slice 5a --
##   * phase 2 -> Pm98Movement._select_phase2 (the static priority LUT &DAT_006392c8)
##   * phase 5/7 -> Pm98Movement._select_phase57 (the persistent set-piece queue)
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_selectactive5b.gd
##
## ORACLE = the PM98 binary's own FUN_005b8f20 under the Ghidra PCode emulator
## (tools/re/run_selectactive5b_oracle.sh; FUN_005bbf10 stubbed, a faithful memmove injected),
## banked at specs/selectactive5b_oracle.txt as one `CALL 0 RET ... mem[...]=...` line per
## fixture. The fixture INPUTS are mirrored below; EXPECTED = the chosen active (ctx+0x168),
## the queue count (ctx+0x20c) + its surviving buffer entries (ctx+0x208[0..count-1]), the
## +0x2ed flag, and every player's +0x5c / +0x8c. NOTE: the binary never erases the buffer
## past `count`, so the queue is compared only over buffer[0..count-1] (stale tail ignored).

const PLAYER_BASE := 0x230000
const STRIDE := 0x3bc

const ACTIVE_ADDR := 0x200168
const COUNT_ADDR := 0x20020c
const FLAG_ADDR := 0x2002ed
const FLAG5C_ADDR := {0x23005c: 0, 0x230418: 1, 0x2307d4: 2, 0x230b90: 3}   # +0x5c -> player idx
const FLAG8C_ADDR := {0x23008c: 0, 0x230448: 1, 0x230804: 2, 0x230bc0: 3}   # +0x8c -> player idx
const BUF_ADDR := [0x270000, 0x270004, 0x270008, 0x27000c]                  # queue buffer[0..3]

# Per-player fields are 4-element arrays [P0,P1,P2,P3]. Match/ctx scalars as named.
const DEF := {
	"phase": 0, "m19a0": 0, "m2ee": 0, "msub": 0, "active": -1, "force": 0,
	"queue": [],
	"onp": [1, 1, 1, 1], "p5c": [0, 0, 0, 0], "p8c": [0, 0, 0, 0],
	"p2c8": [0, 0, 0, 0], "p3a0": [0, 0, 0, 0], "p388": [0, 0, 0, 0],
}

# Each override mirrors the matching FIX poke deltas in run_selectactive5b_oracle.sh exactly.
const FIXTURES := {
	# phase 2 (LUT priorities: code 9->20, 12->18, 14->16, 13->14, 16->12, 17->10, 18->6,
	#   15->5, 11->4, 10->3, 8->2, 7->1, others 0). compare is `<=` so a tie keeps the later.
	"p2_argmax": {"phase": 2, "p2c8": [0xa, 0x9, 0x8, 0xc]},
	"p2_tie_last": {"phase": 2, "p2c8": [0x9, 0xc, 0x9, 0x8]},
	"p2_offpitch": {"phase": 2, "onp": [0, 1, 1, 1], "p2c8": [0x9, 0xc, 0xa, 0x8]},
	"p2_allzero": {"phase": 2, "p2c8": [0, 1, 2, 3]},
	# phase 5/7 (set-piece queue)
	"p5_build_trunc": {"phase": 5, "m19a0": 0, "p3a0": [0x100, 0x400, 0x200, 0x300], "p8c": [1, 1, 1, 1]},
	"p7_build_trunc": {"phase": 7, "m19a0": 0, "p3a0": [0x100, 0x100, 0x100, 0x100], "p388": [0x10, 0x50, 0x30, 0x20]},
	"p5_offpitch": {"phase": 5, "m19a0": 0, "onp": [0, 1, 1, 1], "p3a0": [0x500, 0x100, 0x300, 0x200]},
	"p5_flag1": {"phase": 5, "m19a0": 4, "m2ee": 1, "msub": 2, "p3a0": [0x100, 0x400, 0x200, 0x300], "p8c": [0, 1, 1, 1]},
	"p5_build_nocycle": {"phase": 5, "m19a0": 4, "m2ee": 0, "p3a0": [0x100, 0x400, 0x200, 0x300]},
	"p5_pop_existing": {"phase": 5, "active": 1, "p5c": [0, 1, 0, 0], "queue": [2, 0, 3]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "selectactive5b oracle file empty/unreadable")
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


func _ptr2idx(val: int) -> int:
	if val == 0:
		return -1
	return (val - PLAYER_BASE) / STRIDE


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("selectactive5b_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		if toks.size() < 3:
			continue
		var ret := ""
		var reads := {}
		for t in toks:
			if t == "RET" or t == "HALT":
				ret = t
			elif t.begins_with("mem["):
				var inner := t.substr(4)
				var lb := inner.find("]")
				if lb < 0:
					continue
				var addr := inner.substr(0, lb).split(":")[0].hex_to_int()
				reads[addr] = inner.substr(lb + 2).to_int()
		out[toks[1]] = {"ret": ret, "reads": reads}
	return out


func _merged(name: String) -> Dictionary:
	var o := DEF.duplicate(true)
	for k in FIXTURES[name]:
		o[k] = FIXTURES[name][k]
	return o


func _build_ctx(o: Dictionary) -> Dictionary:
	var m := {
		0x448: int(o.phase), 0x438: -1, 0x19a0: int(o.m19a0),
		0x468: {0xfa0: int(o.msub)},
		0x1614: 0, 0x1618: 0, 0x161c: 0, 0x1644: 0,
		0x1650: -1, 0x165c: -1, 0x1664: 0,
	}
	var ti := {}
	var players: Array = []
	for i in 4:
		players.append({
			0x2bc: int(o.onp[i]), 0x5c: int(o.p5c[i]), 0x8c: int(o.p8c[i]),
			0x2c8: int(o.p2c8[i]), 0x3a0: int(o.p3a0[i]), 0x388: int(o.p388[i]),
			0x4: 0, 0x8: 0, 0xc: 0, 0x184: ti, 0x18c: m,
		})
	var ctx := {"players": players, 0x8: 0, 0x138: m, 0x168: int(o.active), 0x2ee: int(o.m2ee), "force_active": int(o.force)}
	if not (o.queue as Array).is_empty():
		ctx["queue"] = (o.queue as Array).duplicate()
	return ctx


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var ctx := _build_ctx(_merged(name))
	var ret := Pm98Movement.select_active(ctx)
	var players: Array = ctx["players"]
	var reads: Dictionary = exp.reads

	# active (== EAX == ctx+0x168)
	var want_active := _ptr2idx(int(reads[ACTIVE_ADDR]))
	_ok(ret == want_active, "%s active: got %d want %d (EAX=%d)" % [name, ret, want_active, int(reads[ACTIVE_ADDR])])
	_ok(int(ctx.get(0x168, -1)) == want_active, "%s ctx[0x168]: got %d want %d" % [name, int(ctx.get(0x168, -1)), want_active])

	# queue count (ctx+0x20c) + the surviving buffer entries (buffer[0..count-1])
	var want_count := int(reads[COUNT_ADDR])
	var queue: Array = ctx.get("queue", [])
	_ok(queue.size() == want_count, "%s queue count: got %d want %d" % [name, queue.size(), want_count])
	for k in min(want_count, BUF_ADDR.size()):
		var want_idx := _ptr2idx(int(reads[BUF_ADDR[k]]))
		var got_idx: int = int(queue[k]) if k < queue.size() else -99
		_ok(got_idx == want_idx, "%s queue[%d]: got %d want %d" % [name, k, got_idx, want_idx])

	# +0x2ed flag
	_ok(int(ctx.get(0x2ed, 0)) == int(reads[FLAG_ADDR]), "%s flag(0x2ed): got %d want %d" % [name, int(ctx.get(0x2ed, 0)), int(reads[FLAG_ADDR])])

	# +0x5c active flags
	for addr in FLAG5C_ADDR:
		var idx: int = FLAG5C_ADDR[addr]
		_ok(int(players[idx].get(0x5c, 0)) == int(reads[addr]), "%s P%d +0x5c: got %d want %d" % [name, idx, int(players[idx].get(0x5c, 0)), int(reads[addr])])

	# +0x8c bookkeeping field
	for addr in FLAG8C_ADDR:
		var idx: int = FLAG8C_ADDR[addr]
		_ok(int(players[idx].get(0x8c, 0)) == int(reads[addr]), "%s P%d +0x8c: got %d want %d" % [name, idx, int(players[idx].get(0x8c, 0)), int(reads[addr])])
