extends SceneTree
## Oracle-backed parity test for the EXACT per-tick movement layer, first slice
## (Stage 3 task 2): FUN_005b8ce0 (nearest-player-to-ball selector), ported in
## Pm98Movement.select_nearest.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_movement.gd
##
## ORACLE = the PM98 binary's own FUN_005b8ce0 under the Ghidra PCode emulator
## (tools/re/run_movement_oracle.sh; faithful truncating _ftol injected, cos/atan
## LUT injected, exact-integer distances), banked at specs/movement_oracle.txt. The
## fixture INPUTS are embedded below (mirroring the runner's matrix); the EXPECTED
## outputs (active index + the three +0x5c flags + the velocity reset) are read from
## the banked file so there is no transcription.
##
## The oracle reports the active player by ABSOLUTE address; we map it to the index
## model Pm98Movement uses: 0 -> null(-1), else (addr - 0x230000) / 0x3bc.

const U32 := 0xffffffff
const P_BASE := 0x230000
const P_STRIDE := 0x3bc

# Fixture inputs (mirror run_movement_oracle.sh FIX). Each lists find_in_front, the
# three players' (x,y,z), and the few structural pokes. Positions are the exact-
# integer offsets from the runner.
const FIXTURES := {
	"near3":        {"fif": 0, "pos": [[0x50000,0,0],[0x20000,0,0],[0x80000,0,0]]},
	"near3_3d":     {"fif": 0, "pos": [[0x30000,0x40000,0],[0,0,0x20000],[0x80000,0,0]]},
	"cone_skip":    {"fif": 1, "pos": [[0x50000,0,0],[0,0x20000,0],[0x40000,0,0]]},
	"cone_keep":    {"fif": 1, "pos": [[0x50000,0,0],[0x20000,0,0],[0,0x80000,0]]},
	"owned1650":    {"fif": 0, "pos": [[0x50000,0,0],[0x20000,0,0],[0,0,0]], "ctrl": 0, "ctrl_team": 0},
	"owned165c":    {"fif": 0, "pos": [[0x50000,0,0],[0x20000,0,0],[0,0,0]], "other": 1, "other_team": 0},
	"lock_keep":    {"fif": 0, "pos": [[0x50000,0,0],[0x20000,0,0],[0,0,0]], "active": 0, "lock": 1},
	"velreset":     {"fif": 0, "pos": [[0x1300000,0,0],[0x20000,0,0],[0x1300000,0,0]], "team_flag": true, "vel": [0xAAAA,0xBBBB]},
	"none_inrange": {"fif": 0, "pos": [[0x1300000,0,0],[0x1300000,0,0],[0x1300000,0,0]]},
	"ineligible":   {"fif": 0, "pos": [[0x50000,0,0],[0x20000,0,0],[0,0,0]], "elig": [0,0,0]},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "movement oracle file empty/unreadable")
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


func _eq(name: String, field: String, got: int, want: int) -> void:
	_ok((got & U32) == (want & U32), "%s %s: got %d want %d" % [name, field, got & U32, want & U32])


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


# Map an oracle active-player ADDRESS to the Pm98Movement index model (0 -> null).
func _addr_to_idx(addr: int) -> int:
	if addr == 0:
		return -1
	return (addr - P_BASE) / P_STRIDE


func _load_oracle() -> Dictionary:
	# "M name | active | p0_5c | p1_5c | p2_5c | p1_v54 | p1_v58 | RET"
	var out := {}
	var f := FileAccess.open(_spec_path("movement_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var c := line.split("|")
		if c.size() < 8:
			continue
		var head := c[0].strip_edges().split(" ", false)
		if head.size() < 2 or head[0] != "M":
			continue
		out[head[1]] = {
			"active_idx": _addr_to_idx(c[1].strip_edges().to_int()),
			"p5c": [c[2].strip_edges().to_int(), c[3].strip_edges().to_int(), c[4].strip_edges().to_int()],
			"v54": c[5].strip_edges().to_int(),
			"v58": c[6].strip_edges().to_int(),
			"ret": c[7].strip_edges(),
		}
	return out


func _build_ctx(fx: Dictionary) -> Dictionary:
	var teaminfo := {0x2ee: (1 if fx.get("team_flag", false) else 0)}
	var m := {
		0x1614: 0, 0x1618: 0, 0x161c: 0, 0x1644: 0,
		0x1650: int(fx.get("ctrl", -1)), 0x1664: int(fx.get("ctrl_team", -1)),
		0x165c: int(fx.get("other", -1)),
		0x468: {0xfa0: 0},
	}
	var elig: Array = fx.get("elig", [1, 1, 1])
	var players: Array = []
	var pos: Array = fx["pos"]
	for i in 3:
		var p := {
			0x4: int(pos[i][0]), 0x8: int(pos[i][1]), 0xc: int(pos[i][2]),
			0x2bc: int(elig[i]), 0x5c: 0, 0x5d: 0, 0x54: 0, 0x58: 0,
			0x2b8: 0, 0x184: teaminfo, 0x18c: m,
		}
		players.append(p)
	# other_team: the controlling player's team via +0x2b8 (owned165c).
	if fx.has("other") and fx.has("other_team"):
		players[int(fx["other"])][0x2b8] = int(fx["other_team"])
	# lock_keep: the current active is locked.
	if fx.has("active"):
		players[int(fx["active"])][0x5d] = int(fx.get("lock", 0))
		players[int(fx["active"])][0x5c] = 1
	# velreset: preset the winner's (P1) velocity.
	if fx.has("vel"):
		players[1][0x54] = int(fx["vel"][0])
		players[1][0x58] = int(fx["vel"][1])
	return {
		"players": players, 0x8: 0, 0x138: m,
		0x168: int(fx["active"]) if fx.has("active") else -1,
	}


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var fx: Dictionary = FIXTURES[name]
	var ctx := _build_ctx(fx)
	Pm98Movement.select_nearest(ctx, int(fx["fif"]))
	_eq(name, "active_idx", int(ctx.get(0x168, -1)), exp.active_idx)
	var players: Array = ctx["players"]
	for i in 3:
		_eq(name, "p%d_5c" % i, int(players[i].get(0x5c, 0)), exp.p5c[i])
	# Velocity reset only meaningfully changes the winner; P1 is the reset target.
	_eq(name, "p1_v54", int(players[1].get(0x54, 0)), exp.v54)
	_eq(name, "p1_v58", int(players[1].get(0x58, 0)), exp.v58)
