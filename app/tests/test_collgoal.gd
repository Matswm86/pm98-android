extends SceneTree
## Logic test for the FUN_0058e2c0 collision-loop GOAL-SCORING DETECTION (0x58e756..0x58e8d2), ported in
## Pm98Movement._collision_goal_check. This is the load-bearing scoreline path: once FUN_005efac0 (the
## deferred per-post narrow phase) reports a 0x9eb8 goal-line hit, this decides whether it is a goal and
## fires Pm98Events.keeper_event (FUN_005909f0 stat bump) + Pm98Events.enqueue (FUN_00594470 commentary).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_collgoal.gd
##
## NOT oracle-backed end-to-end (the enclosing post loop needs FUN_005efac0 + the unported match-init
## post array to reach this in-emu). The gate sequence is transcribed bit-for-bit from the disasm and
## the two sub-calls it makes (keeper_event, enqueue) are themselves oracle-validated (Pm98Events). This
## test pins the gate logic: inward sign-cross + in-goal-box + open-play + post id 0x9eb8 -> a goal that
## bumps the keeper stat +0x7c, enqueues 0x1a (or 0x1b when |pos.y| >= 0x36b85), and clears ball +0x50.

var _fail := 0
var _pass := 0


func _init() -> void:
	_t_goal()
	_t_wide_goal()
	_t_same_sign()
	_t_out_of_box()
	_t_not_open_play()
	_t_crossbar()
	_t_other_post()
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


# A match with a goal box [-0x80000..0x80000]^2 x [0..0x80000], open play, no commentary band bits.
func _match() -> Dictionary:
	return {
		0x448: 0,                                         # phase 0 = open play
		0x462: 0,                                         # no band bits -> keeper_event won't extra-enqueue
		0x1a38: 0,                                        # enqueue gate
		0x1828: -0x80000, 0x1834: 0x80000,               # goal box x
		0x182c: -0x80000, 0x1838: 0x80000,               # goal box y
		0x1830: 0, 0x183c: 0x80000,                       # goal box z
	}


# A ball crossing the goal line inward (pos.x<0, vel.x>0 -> signs differ), inside the box, with a latched
# keeper at +0x50 whose stat struct is at keeper+0x3b8. by = pos.y.
func _ball(m: Dictionary, by: int) -> Dictionary:
	var stat := {0x7c: 0, 0x80: 0}
	var keeper := {0x3b8: stat}
	return {0x4: -0x10000, 0x8: by, 0xc: 0x1000, 0x20: 0x100, 0x4c: 0, 0x50: keeper, 0x1d4: m, 0x80: 0}


func _stat(ball: Dictionary) -> Dictionary:
	var k: Dictionary = ball[0x50] if ball[0x50] is Dictionary else {}
	return k.get(0x3b8, {})


func _t_goal() -> void:
	var m := _match()
	var ball := _ball(m, 0)
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x9eb8})
	_ok(int(stat[0x7c]) == 1, "goal: keeper stat +0x7c bumped to 1 (got %d)" % int(stat[0x7c]))
	_ok(ball[0x50] == 0, "goal: ball +0x50 cleared to 0")
	var q: Array = m.get(0x1a24, [])
	_ok(q.size() == 1 and int(q[0][0]) == 0x1a, "goal: enqueued one 0x1a event (got %s)" % str(q))


func _t_wide_goal() -> void:
	var m := _match()
	var ball := _ball(m, 0x40000)                         # |pos.y| 0x40000 >= 0x36b85 -> wide code 0x1b
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x9eb8})
	var q: Array = m.get(0x1a24, [])
	_ok(q.size() == 1 and int(q[0][0]) == 0x1b, "wide_goal: enqueued 0x1b (got %s)" % str(q))


func _t_same_sign() -> void:
	var m := _match()
	var ball := _ball(m, 0)
	ball[0x4] = 0x10000                                   # pos.x>0, vel.x>0 -> same sign -> no goal
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x9eb8})
	_ok(int(stat[0x7c]) == 0, "same_sign: no stat bump")
	_ok(ball[0x50] is Dictionary, "same_sign: ball +0x50 keeper intact")
	_ok(not m.has(0x1a24), "same_sign: no event enqueued")


func _t_out_of_box() -> void:
	var m := _match()
	var ball := _ball(m, 0)
	ball[0x8] = 0x90000                                   # pos.y outside the goal box
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x9eb8})
	_ok(int(stat[0x7c]) == 0, "out_of_box: no stat bump")
	_ok(ball[0x50] is Dictionary, "out_of_box: ball +0x50 intact")


func _t_not_open_play() -> void:
	var m := _match()
	m[0x448] = 1                                          # phase != 0 -> no goal
	var ball := _ball(m, 0)
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x9eb8})
	_ok(int(stat[0x7c]) == 0, "not_open_play: no stat bump")


func _t_crossbar() -> void:
	var m := _match()
	var ball := _ball(m, 0)
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x7ae1})   # crossbar id -> no scoring
	_ok(int(stat[0x7c]) == 0, "crossbar: no stat bump")
	_ok(ball[0x50] is Dictionary, "crossbar: ball +0x50 intact")


func _t_other_post() -> void:
	var m := _match()
	var ball := _ball(m, 0)
	var stat: Dictionary = _stat(ball)
	Pm98Movement._collision_goal_check(ball, m, {0x54: 0x1234})   # neither crossbar nor goal line
	_ok(int(stat[0x7c]) == 0, "other_post: no stat bump")
