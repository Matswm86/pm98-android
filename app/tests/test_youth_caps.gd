extends SceneTree
## The YOUTH SCOUT's SEARCH CAPABILITY mask — now the BINARY's own ladder, not a corpus fit.
##
## Three sessions filed this wrongly, twice for the same reason: the star bar was COUNTED BY
## EYE. s84 called it a rating ladder on one sample; s85 called it "per scout, not a ladder"
## because two scouts read as "2★" appeared to carry different masks; s86 measured the bar by
## GOLD AREA (`tools/re/probe_youth_cap_mask.py`) and found all three low scouts are 1.5★
## with the SAME pair — a ladder again, but with only its two ends witnessed and the rungs
## between 1.5 and 4.5 filed as "needs four more careers".
##
## s87 read them out of MANAGER.EXE instead. `YouthScreen.CAP_BY_QUALITY`'s header carries
## the disassembly; the shape is an eight-entry jump table at `0x53d520` on `q - 1`, where q
## is the scout's 1..10 quality byte (`Staff.quality_byte` = round(stars × 2)), with q ≥ 9
## disabling nothing and each arm falling through the ones below it.
##
## This test does two jobs. It pins the five WITNESSED scouts, which is what proves the
## table was read correctly:
##
## | scout | measured | YES values |
## |---|---|---|
## | J. Casson / C. Dewhurst / S. Munt | 1.5★ (q3) | HANDLING, TACKLING |
## | C. Stump | 4.5★ (q9) | all six |
## | P. Mitchell | 5.0★ (q10) | all six |
##
## And it pins the WHOLE ladder, including the rungs no frame shows, because those now come
## from the binary and a change to them is a claim about the binary.
##
## Run: godot4 --headless --path app --script res://tests/test_youth_caps.gd

const ALL_SIX := ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]

# The ladder as the jump table lays it out, q = 1..10.
const EXPECTED := {
	1: ["HANDLING"],
	2: ["HANDLING"],
	3: ["HANDLING", "TACKLING"],
	4: ["HANDLING", "TACKLING", "PASSING"],
	5: ["HANDLING", "TACKLING", "PASSING"],
	6: ["HANDLING", "TACKLING", "PASSING", "DRIBBLING"],
	7: ["HANDLING", "TACKLING", "PASSING", "DRIBBLING", "HEADING"],
	8: ["HANDLING", "TACKLING", "PASSING", "DRIBBLING", "HEADING"],
	9: ["HANDLING", "TACKLING", "PASSING", "DRIBBLING", "HEADING", "SHOOTING"],
	10: ["HANDLING", "TACKLING", "PASSING", "DRIBBLING", "HEADING", "SHOOTING"],
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var YS := load("res://scenes/YouthScreen.gd")

	# --- the five WITNESSED scouts, which is what the table has to reproduce -------------
	var low: Array = YS.available_caps(1.5)
	_ok(low.size() == 2 and low.has("HANDLING") and low.has("TACKLING"),
		"1.5★ (q3) -> HANDLING + TACKLING only (got %s)" % [low])
	for hi in [4.5, 5.0]:
		var caps: Array = YS.available_caps(hi)
		_ok(caps.size() == 6, "%.1f★ -> all six (got %s)" % [hi, caps])
		for c in ALL_SIX:
			_ok(caps.has(c), "%.1f★ includes %s" % [hi, c])

	# --- the WHOLE ladder, q = 1..10 -----------------------------------------------------
	for q in EXPECTED.keys():
		var want: Array = EXPECTED[q]
		var got: Array = YS.available_caps(float(q) / 2.0)
		_ok(got == want, "q=%d (%.1f★) -> %s (got %s)" % [q, float(q) / 2.0, want, got])

	# The ladder is MONOTONE — a better scout never loses a capability a worse one had.
	var prev: Array = []
	for q in range(1, 11):
		var got: Array = YS.available_caps(float(q) / 2.0)
		for c in prev:
			_ok(got.has(c), "q=%d keeps %s that q=%d had" % [q, c, q - 1])
		prev = got

	# "No scout" is the caller's own gate, but a negative rating must not match a rung.
	_ok((YS.available_caps(-1.0) as Array).is_empty(), "no scout -> []")
	_ok((YS.available_caps(0.0) as Array).is_empty(), "q=0 -> [] (the engine's no-scout arm)")

	# Half-star snapping: a rating carried as a float must not miss its rung.
	_ok((YS.available_caps(1.4999) as Array).size() == 2, "1.4999 snaps to q3")
	_ok((YS.available_caps(1.5001) as Array).size() == 2, "1.5001 snaps to q3")

	# And the table itself is the disassembly's, so a future edit has to change this test
	# and say which instruction it is changing.
	_ok(YS.CAPS_ENABLED_BY_QUALITY == [1, 1, 2, 3, 3, 4, 5, 5, 6, 6],
		"CAPS_ENABLED_BY_QUALITY is the 0x53d520 jump table (%s)"
			% [YS.CAPS_ENABLED_BY_QUALITY])
	_ok(YS.CAP_ORDER_BY_QUALITY == ["HANDLING", "TACKLING", "PASSING", "DRIBBLING", "HEADING",
			"SHOOTING"],
		"the disable order is the fall-through order of the arms (%s)"
			% [YS.CAP_ORDER_BY_QUALITY])

	print("YOUTH CAPS: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %s" % msg)
