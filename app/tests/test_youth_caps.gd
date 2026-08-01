extends SceneTree
## The YOUTH SCOUT's SEARCH CAPABILITY mask, pinned to the frames that witness it.
##
## Two sessions filed this wrongly and the reason is the same both times: the star bar was
## COUNTED BY EYE. s84 called it a rating ladder on one sample; s85 called it "per scout,
## not a ladder" because two scouts read as "2 stars" appeared to carry different masks.
## `tools/re/probe_youth_cap_mask.py` measures instead -- the star bar by GOLD AREA (a full
## glyph is a 13-px diamond, a half glyph 8; run WIDTH cannot separate them, 4 columns
## against 5) and the value cells by ink colour:
##
## | scout | measured | YES values |
## |---|---|---|
## | J. Casson    | 1.5★ | HANDLING, TACKLING |
## | C. Dewhurst  | 1.5★ | HANDLING, TACKLING |
## | S. Munt      | 1.5★ | HANDLING, TACKLING |
## | C. Stump     | 4.5★ | all six |
## | P. Mitchell  | 5.0★ | all six |
##
## There are no two same-rating scouts with different masks. The mask follows the RATING,
## and `YouthScreen.CAP_BY_STARS` carries the two witnessed ends and nothing between them.
##
## Run: godot4 --headless --path app --script res://tests/test_youth_caps.gd

const ALL_SIX := ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]

var _fail := 0
var _pass := 0


func _init() -> void:
	var YS := load("res://scenes/YouthScreen.gd")

	# The witnessed rungs.
	var low: Array = YS.available_caps(1.5)
	_ok(low.size() == 2 and low.has("HANDLING") and low.has("TACKLING"),
		"1.5★ -> HANDLING + TACKLING only (got %s)" % [low])
	for hi in [4.5, 5.0]:
		var caps: Array = YS.available_caps(hi)
		_ok(caps.size() == 6, "%.1f★ -> all six (got %s)" % [hi, caps])
		for c in ALL_SIX:
			_ok(caps.has(c), "%.1f★ includes %s" % [hi, c])

	# The UNWITNESSED ratings return [], which every caller reads as "no restriction known"
	# -- the render the port has always had, and what keeps frame 047 at 0 px. This must NOT
	# quietly become an invented ladder.
	for mid in [2.0, 2.5, 3.0, 3.5, 4.0]:
		_ok((YS.available_caps(mid) as Array).is_empty(),
			"%.1f★ is unwitnessed and returns [] (no invented rung)" % mid)

	# "No scout" is the caller's own gate, but a negative rating must not match a rung.
	_ok((YS.available_caps(-1.0) as Array).is_empty(), "no scout -> []")

	# Half-star snapping: a rating carried as a float must not miss its rung.
	_ok((YS.available_caps(1.4999) as Array).size() == 2, "1.4999 snaps to the 1.5 rung")
	_ok((YS.available_caps(1.5001) as Array).size() == 2, "1.5001 snaps to the 1.5 rung")

	# And the table itself is only ever the witnessed keys, so a future edit that adds an
	# unwitnessed rung has to change this test and say why.
	var keys: Array = (YS.CAP_BY_STARS as Dictionary).keys()
	keys.sort()
	_ok(keys == [1.5, 4.5, 5.0], "CAP_BY_STARS holds exactly the witnessed ratings (%s)" % [keys])

	print("YOUTH CAPS: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %s" % msg)
