extends SceneTree
## Runtime wiring test for the goal/pitch collision-geometry builder -> ball physics.
## Proves Pm98CollBuilder.populate_posts(m) stores the post array the FUN_0058e2c0 collision loop
## (Pm98Movement._ball_collision / _post_narrow) reads, in the BYTE-OFFSET Dict form the loop
## expects, and that a ball fired at the goal line now (a) collides + bounces and (b) scores.
## Run: ~/godot462 --headless --path app --script res://tests/test_collposts.gd
##
## The goal dims mirror test_collbuilder.gd (the oracle-validated synthetic dims). With 0x1a1b=1
## the builder emits 62 posts: 30 crossbar 0x7ae1 + 8 net-post 0x8000 + 24 goal-line 0x9eb8.
## Crossbar/net posts sit at |x| <= 0x40000; goal-line posts at |x| ~ 0x90334 (planes -0x90334 /
## -0x8e334 on the left). A shot from x=-0x70334 moving -x therefore has a clean lane to the left
## goal line with no crossbar/net interception.

const U32 := 0xffffffff
const CB := 0x7ae1   # crossbar id
const NP := 0x8000   # net-post id
const GL := 0x9eb8   # goal-line id

# goal dims -- identical to test_collbuilder.gd / run_collbuilder_oracle.sh
const DIMS := {
	0x194c: 0x20000, 0x1950: 0x30000, 0x1954: 0x40000, 0x1958: 0x18000, 0x195c: 0x28000,
	0x1960: 0x12000, 0x1964: 0x1c000, 0x1968: 0x22000, 0x196c: 0x14000, 0x1970: 0x8000,
	0x1974: 0x10000, 0x1978: 0xc000, 0x197c: 0x6000, 0x1820: 0x90000, 0x1988: 0x0,
	0x1a4c: 0x5000, 0x1a1b: 0x1, 0x1a1c: 0x1, 0x27cc: 0x0,
}

var _fail := 0
var _pass := 0


func _init() -> void:
	_t_structure()
	_t_narrow_on_real_post()
	_t_ball_collision_e2e()
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


func _match() -> Dictionary:
	var m := {}
	for k in DIMS:
		m[k] = DIMS[k]
	# open play + a wide goal box around the left goal line; band/enqueue gates off
	m[0x448] = 0
	m[0x462] = 0
	m[0x1a38] = 0
	m[0x1828] = -0x100000; m[0x1834] = 0x100000     # box x
	m[0x182c] = -0x100000; m[0x1838] = 0x100000     # box y
	m[0x1830] = 0; m[0x183c] = 0x100000             # box z
	return m


# --- 1) populate_posts stores the post array in the byte-offset Dict form the loop reads ---------
func _t_structure() -> void:
	var m := _match()
	var n := Pm98CollBuilder.populate_posts(m)
	_ok(n == 62, "populate_posts returned 62 (got %d)" % n)
	_ok(int(m.get(0x17f8, 0)) == 62, "m[0x17f8] count == 62 (got %d)" % int(m.get(0x17f8, 0)))
	var posts: Array = m.get(0x17f4, [])
	_ok(posts.size() == 62, "m[0x17f4] has 62 posts (got %d)" % posts.size())

	# every post Dict must re-key the flat build() post exactly: byte offset == index * 4
	var flat_posts: Array = Pm98CollBuilder.build(m).get("posts", [])
	var rekey_ok := flat_posts.size() == posts.size()
	if rekey_ok:
		for i in flat_posts.size():
			var flat: Array = flat_posts[i]
			var d: Dictionary = posts[i]
			if d.size() != flat.size():
				rekey_ok = false
				break
			for j in flat.size():
				if (int(d.get(j * 4, 0)) & U32) != (int(flat[j]) & U32):
					rekey_ok = false
					break
			if not rekey_ok:
				break
	_ok(rekey_ok, "each post Dict re-keys flat build() post by byte=index*4")

	# id histogram at byte 0x54
	var hist := {}
	for d in posts:
		var pid := int(d.get(0x54, 0)) & U32
		hist[pid] = int(hist.get(pid, 0)) + 1
	_ok(int(hist.get(CB, 0)) == 30, "30 crossbar (0x7ae1) posts (got %d)" % int(hist.get(CB, 0)))
	_ok(int(hist.get(NP, 0)) == 8, "8 net-post (0x8000) posts (got %d)" % int(hist.get(NP, 0)))
	_ok(int(hist.get(GL, 0)) == 24, "24 goal-line (0x9eb8) posts (got %d)" % int(hist.get(GL, 0)))


# --- 2) a real goal-line post Dict + a fired ball -> _post_narrow reports a hit + reflect --------
func _t_narrow_on_real_post() -> void:
	var m := _match()
	Pm98CollBuilder.populate_posts(m)
	var posts: Array = m.get(0x17f4, [])
	# pick the left INNER goal-line plane (x == -0x8e334, the +x-facing face the ball meets first)
	var target := {}
	for d in posts:
		if int(d.get(0x54, 0)) == GL and Pm98Movement._si(d, 0x0) == -0x8e334:
			target = d
			break
	if target.is_empty():
		_ok(false, "narrow: no left-inner goal-line post (x==-0x8e334) found")
		return
	var ball := {0x4: -0x70334, 0x8: 0, 0xc: 0x27d70, 0x20: -0x40000, 0x24: 0, 0x28: 0}
	var hit := Pm98Movement._post_narrow(ball, target)
	_ok(hit, "narrow: ball fired at real goal-line post reports a hit")
	if hit:
		_ok(Pm98Movement._si(ball, 0x20) > 0, "narrow: vel.x reflected to +x (got 0x%x)" % (Pm98Movement._si(ball, 0x20) & U32))


# --- 3) full _ball_collision pass: posts wired -> collision counter bumps + goal enqueued --------
# NOTE: firing dead-centre at the thin (0x2000) goal-line slab makes the faithful restart-on-hit
# loop (0x58e73e, i=0) ricochet between the slab's two opposing faces (inner +x-normal POST 50,
# outer -x-normal POST 38), so the counter and the goal-enqueue can fire more than once in a single
# call (observed: 4 bounces, 2 goals). That is faithful to the binary's collision loop; in a live
# match the DRIVER (FUN_00598740, step 2) flips the match phase on a goal -> the open-play gate in
# _collision_goal_check blocks the re-score on the next pass. Hence the >= 1 assertions here; the
# single-hit reflect DIRECTION is pinned exactly in _t_narrow_on_real_post above.
func _t_ball_collision_e2e() -> void:
	var m := _match()
	Pm98CollBuilder.populate_posts(m)
	var keeper := {0x3b8: {0x7c: 0, 0x80: 0}}
	var ball := {
		0x4: -0x70334, 0x8: 0, 0xc: 0x27d70,            # pos inside, lane to the left goal line
		0x20: -0x40000, 0x24: 0, 0x28: 0,               # vel toward -x goal
		0x4c: 0, 0x50: keeper, 0x1d4: m, 0x80: 0,
	}
	Pm98Movement._ball_collision(ball)
	_ok(int(ball.get(0x80, 0)) >= 1, "e2e: collision counter +0x80 bumped (got %d)" % int(ball.get(0x80, 0)))
	_ok(Pm98Movement._si(ball, 0x20) != -0x40000, "e2e: vel.x changed by the reflect (got 0x%x)" % (Pm98Movement._si(ball, 0x20) & U32))
	var q: Array = m.get(0x1a24, [])
	_ok(q.size() >= 1 and int(q[0][0]) == 0x1a, "e2e: goal event 0x1a enqueued (got %s)" % str(q))
	var stat: Dictionary = keeper.get(0x3b8, {})
	_ok(int(stat.get(0x7c, 0)) >= 1, "e2e: keeper goal-conceded stat +0x7c bumped (got %d)" % int(stat.get(0x7c, 0)))
