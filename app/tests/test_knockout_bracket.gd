extends SceneTree
## KNOCKOUT BRACKET — the 4-tie layout's measured geometry and the layout switch
## (docs/re/knockout_views_re.md "The bracket, re-measured 2026-07-26").
##
## The render itself is proven by tools/re/diff_knockout_parity.py (0 px outside the
## declared kit / rail / barra buckets, both column sets); this suite pins the numbers a
## refactor could silently move and the setup() rules the parity shots depend on.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_knockout_bracket.gd

var _fail := 0


func _initialize() -> void:
	var scr: KnockoutScreen = load("res://scenes/KnockoutScreen.gd").new()
	get_root().add_child(scr)

	# the panel pitch: four tops 80 apart from y113 -- the frames' own positions
	_a(KnockoutScreen.BRACKET_TOPS == [113, 193, 273, 353], "panel tops 113/193/273/353")
	_a(KnockoutScreen.BRACKET_TIES == 4, "the bracket is the 4-tie layout")

	# value-box centres: euro x83..175 / x193..283 / x310..414, dom x135..227 / x271..361
	# -- the domestic slots sit at their OWN x positions, not the European ones minus one
	_a(KnockoutScreen.BRACKET_BOX_CX_EURO == [129, 238, 362], "euro box centres")
	_a(KnockoutScreen.BRACKET_BOX_CX_DOM == [181, 316], "domestic box centres")

	# the name centring rule: pen = floor(cx - adv/2) with cx 178.5 / 319.5, solved off
	# all 15 witnessed names (every one lands exactly)
	_a(KnockoutScreen.BRACKET_NAME_CX2 == [357, 639], "name centring 2cx 357 / 639")

	# the layout switch: setup() accepts "bracket", clamps anything unknown to "list"
	scr.setup({}, "euro", "QTR FINALS", true, _ties(4), false, false, 0, "bracket")
	_a(scr._layout == "bracket", "setup() takes layout = bracket")
	_a(scr._band_key() == "euro_bracket", "band key follows the layout family")
	scr.setup({}, "facup", "ROUND 3", false, _ties(16), false, false, 0, "nonsense")
	_a(scr._layout == "list", "an unknown layout clamps to list")
	_a(scr._band_key() == "facup_list", "band key back on the list family")

	# every bracket band the baker cut exists, and the two panel strips are 458x72
	for comp in ["euro", "facup", "cocacola", "uefa", "cwc"]:
		_a(ResourceLoader.exists("res://art/screens/knockout/band_%s_bracket.png" % comp),
			"band_%s_bracket.png baked" % comp)
	for fam in ["euro", "dom"]:
		var tex: Texture2D = load("res://art/screens/knockout/bracket_panel_%s.png" % fam)
		_a(tex != null and tex.get_width() == 458 and tex.get_height() == 72,
			"bracket_panel_%s.png is 458x72" % fam)

	print("FAILED %d" % _fail if _fail > 0 else "ALL PASS")
	quit(1 if _fail > 0 else 0)


func _ties(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append({"home": "H%d" % i, "away": "A%d" % i, "winner": -1,
			"cells": [["", ""], ["", ""]]})
	return out


func _a(cond: bool, what: String) -> void:
	if cond:
		print("  ok  %s" % what)
	else:
		print("  FAIL %s" % what)
		_fail += 1
