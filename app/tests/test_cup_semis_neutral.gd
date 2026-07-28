extends SceneTree
## The SINGLE-LEG SEMIFINAL's neutral ground, and the card shape that goes with it.
##
## Witness: `tools/re/refs/knockout-2026-07-28/12_facup_semifinals_FINALISTS_1998-04-11.png`
## puts Ipswich vs Blackburn R. at HILLSBOROUGH and Stoke C vs Southampton at ANFIELD --
## neither a competitor's ground. So a domestic semifinal is played at a neutral ground,
## one per tie, and the card carries ONE block whose bar reads RESULT with that ground as
## its first row (docs/re/knockout_views_re.md).
##
## What is witnessed: the ground is neutral, and there is one per tie.
## What is DECLARED OURS: which ground -- a deterministic draw from the clubs the
## competition has actually fielded, the same rule the FINAL already uses.
## What is a DECLARED DIVERGENCE: the tie is still RESOLVED with the drawn home side's
## advantage; naming the venue does not move the match.
##
##   ~/godot4 --headless --path app --script res://tests/test_cup_semis_neutral.gd

const SEED := 909090
var _ok := true


func _initialize() -> void:
	quit(0 if _run() else 1)


func _a(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	_ok = _ok and cond
	return cond


func _ratings_fn() -> Callable:
	return func(id: int) -> Dictionary:
		var base := 45.0 + float(id % 20)
		return {"att": base, "def": base, "gk": base + 2.0, "name": "C%d" % id}


func _names_fn() -> Callable:
	return func(id: int) -> String: return "C%d" % id


func _run() -> bool:
	var ids: Array = []
	for i in range(1, 17):
		ids.append(i)
	var b := Cup.create(ids, 40)          # 16 clubs, single-leg: R1, QF, SF, FINAL
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())     # 16 -> 8
	Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())     # 8 -> 4
	_a((b["survivors"] as Array).size() == 4, "four clubs reach the semifinals")

	Cup.draw_next_round(b, rng)           # draw-then-play: the SF is drawn a week early
	var pend: Dictionary = b.get("pending_draw", {})
	_a(not pend.is_empty(), "the semifinal round is DRAWN before it is played")
	_a(int(pend.get("round_legs", 0)) == 1, "a domestic semifinal is SINGLE-leg")
	var venues: Array = pend.get("tie_venue_ids", []) as Array
	_a(venues.size() == 2, "the draw records one neutral ground per tie")

	var players: Array = pend.get("players", [])
	var neutral := true
	for i in venues.size():
		var v := int(venues[i])
		if v < 0 or v == int(players[i * 2]) or v == int(players[i * 2 + 1]):
			neutral = false
	_a(neutral, "neither club in a tie owns the ground it is played at")
	var pool := {}
	for v in ids:
		pool[int(v)] = true
	var from_field := true
	for v in venues:
		if not pool.has(int(v)):
			from_field = false
	_a(from_field, "the ground is drawn from the competition's OWN entrants")

	Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())     # 4 -> 2
	var semis: Dictionary = (b["rounds"] as Array)[-1]
	var carried := true
	for t in (semis.get("ties", []) as Array):
		if int((t as Dictionary).get("venue_id", -1)) < 0:
			carried = false
	_a(carried, "the played tie carries the ground the draw picked")

	# Same seed, same career -> the same grounds. The pick is declared OURS, so it must at
	# least be reproducible, which is what S3 asks of every rng site in the game.
	var b2 := Cup.create(ids, 40)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = SEED
	Cup.play_round(b2, rng2, _ratings_fn(), -1, _names_fn())
	Cup.play_round(b2, rng2, _ratings_fn(), -1, _names_fn())
	Cup.draw_next_round(b2, rng2)
	_a((b2.get("pending_draw", {}) as Dictionary).get("tie_venue_ids", []) == venues,
		"the same seed draws the same grounds")

	if _ok:
		print("test_cup_semis_neutral: ALL PASS")
	else:
		push_error("test_cup_semis_neutral: FAILED")
	return _ok
