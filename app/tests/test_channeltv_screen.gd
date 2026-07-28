extends SceneTree
## Headless test for the `channelTV` card (ChannelTvScreen).
##
## Written 2026-07-27 because `AUDIT_COMPLETE_2026-07-26.md` recorded it as the ONE
## screen in the app with zero test coverage. It pins what the RE doc proves and what
## the baker asserts (`docs/re/REFRUN_manutd_1997-98.md` R6,
## `tools/re/build_channeltv_card_from_frames.py`): the baked chrome exists, the panel
## and OK rect sit where the frame puts them, the fee line is the ONLY thing the scene
## draws over the bake, the OK button emits exactly once and only from inside its rect,
## and the fee text is the frame's own wording with the game's thousands separators.
##
##   ~/godot462 --headless --path app --script res://tests/test_channeltv_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	ok = _assert(ResourceLoader.exists("res://art/screens/channeltv/card.png"),
		"baked card art present") and ok
	# Geometry: on-canvas, and the OK rect is inside the panel the bake cut.
	ok = _assert(ChannelTvScreen.OK_RECT.end.x <= 640 and ChannelTvScreen.OK_RECT.end.y <= 480,
		"OK rect inside the 640x480 canvas") and ok
	ok = _assert(ChannelTvScreen.PANEL.x > 0 and ChannelTvScreen.PANEL.y > 0,
		"panel is offset from the screen origin (it is a card, not a full screen)") and ok
	ok = _assert(ChannelTvScreen.FEE_BASELINE > ChannelTvScreen.PANEL.y,
		"fee baseline sits inside the panel") and ok

	# The fee table is the reversed one, not a guess: the card's £90,000 league fee is the
	# same figure the week's TELEVISION ledger row carries (REFRUN R6, Man Utd week 29).
	ok = _assert(int(FinanceModel.TV_FEE["league"]) == 90_000, "league TV fee £90,000") and ok
	ok = _assert(int(FinanceModel.TV_FEE["charity_shield"]) == 187_500,
		"Charity Shield TV fee £187,500") and ok
	ok = _assert(int(FinanceModel.TV_FEE["european_cup"]) == 375_000,
		"European Cup TV fee £375,000") and ok
	ok = _assert(FinanceScreen.fmt_money(90_000) == "£90,000",
		"the fee renders as the frame's own '£90,000'") and ok

	# 2026-07-28: the league fee is PER DIVISION, and it is NOT a clean ratio -- which is
	# exactly why each rung was captured rather than interpolated. All four English
	# divisions are witnessed (tools/re/refs/lowdiv-2026-07-28/): Man Utd £90,000,
	# Birmingham C £45,000, Blackpool £35,000, Barnet £35,000. A division outside the
	# four pays 0 -- no card, no TELEVISION row -- rather than a guess.
	ok = _assert(FinanceModel.league_tv_fee("eng_prem") == 90_000,
		"Premier home-league TV fee £90,000") and ok
	ok = _assert(FinanceModel.league_tv_fee("eng_div1") == 45_000,
		"First Division home-league TV fee £45,000") and ok
	ok = _assert(FinanceModel.league_tv_fee("eng_div2") == 35_000,
		"Second Division home-league TV fee £35,000") and ok
	ok = _assert(FinanceModel.league_tv_fee("eng_div3") == 35_000,
		"Third Division home-league TV fee £35,000") and ok
	ok = _assert(FinanceModel.league_tv_fee("esp_liga") == 0,
		"an unmodelled competition stays an honest gap") and ok
	# The ladder is not proportional: halving from Premier to First, then a 10k step, then
	# Second and Third SHARING one figure. Pin the shape so a future "tidy-up" cannot
	# smooth it into a formula the game does not have.
	ok = _assert(FinanceModel.league_tv_fee("eng_div2") == FinanceModel.league_tv_fee("eng_div3"),
		"Second and Third share one fee (the shared-arm shape)") and ok
	ok = _assert(FinanceScreen.fmt_money(45_000) == "£45,000",
		"the First Division fee renders as the card's own '£45,000'") and ok

	# 2026-07-28 (s78): the PRODUCER is found and the whole table is READ out of
	# MANAGER.EXE -- docs/re/channeltv_fee_re.md, reproducible byte-for-byte with
	# `python tools/re/dump_tv_fee_table.py`. Every competition class writes club+0x290
	# itself as an imm32, in the engine's own unit (200 internal = £1). Pin the RAW
	# immediates as well as the pounds, so neither table can drift from the image.
	ok = _assert(FinanceModel.MONEY_PER_POUND == 200,
		"the engine's money unit is 200 internal per pound") and ok
	for key in FinanceModel.TV_FEE_INTERNAL:
		var raw := int(FinanceModel.TV_FEE_INTERNAL[key])
		ok = _assert(raw % FinanceModel.MONEY_PER_POUND == 0,
			"%s: the imm32 %d divides exactly by 200" % [key, raw]) and ok
		ok = _assert(raw / FinanceModel.MONEY_PER_POUND == FinanceModel.tv_fee(key),
			"%s: £%d is exactly the imm32 / 200" % [key, FinanceModel.tv_fee(key)]) and ok
	ok = _assert(FinanceModel.tv_fee_internal("league") == 18_000_000,
		"Premier arm imm32 0x112a880 @0x417468") and ok
	ok = _assert(FinanceModel.tv_fee_internal("charity_shield") == 37_500_000,
		"Charity Shield imm32 0x23c3460 @0x405b18") and ok
	ok = _assert(FinanceModel.tv_fee_internal("european_cup") == 75_000_000,
		"European Cup imm32 0x47868c0 @0x454cfd") and ok
	# The four European/one-off competitions the port had never sourced.
	ok = _assert(FinanceModel.tv_fee("uefa_cup") == 375_000,
		"U.E.F.A. Cup TV fee £375,000 (CUEFA class, @0x45c8e8)") and ok
	ok = _assert(FinanceModel.tv_fee("cup_winners_cup") == 375_000,
		"Cup Winners' Cup TV fee £375,000 (RECOP class, @0x461f77)") and ok
	ok = _assert(FinanceModel.tv_fee("supercup") == 375_000,
		"European Supercup TV fee £375,000 (SCEUR class, @0x463dc0)") and ok
	ok = _assert(FinanceModel.tv_fee("intercontinental") == 187_500,
		"Intercontinental Cup TV fee £187,500 (INTER class, @0x43275d)") and ok
	# ⭐ The two domestic cups pay NOTHING, and that is a RESULT: neither the FACUP nor the
	# CCCUP class block writes club+0x290 at all. Pinned so a later session cannot "fill
	# the gap" with an invented figure.
	ok = _assert(FinanceModel.tv_fee("fa_cup") == 0,
		"F.A. Cup pays £0 -- the FACUP class has NO club+0x290 writer") and ok
	ok = _assert(FinanceModel.tv_fee("coca_cola") == 0,
		"Coca-Cola Cup pays £0 -- the CCCUP class has NO club+0x290 writer") and ok
	ok = _assert(FinanceModel.TV_FEE.has("fa_cup") and FinanceModel.TV_FEE.has("coca_cola"),
		"both domestic cups are PRESENT in the table at 0, not absent from it") and ok
	# And they must still land in the DOMESTIC detail section, not the euro one.
	ok = _assert(Career._comp_bucket("fa_cup") == "domestic",
		"the F.A. Cup books into the domestic detail section") and ok
	ok = _assert(Career._comp_bucket("coca_cola") == "domestic",
		"the Coca-Cola Cup books into the domestic detail section") and ok
	ok = _assert(Career._comp_bucket("uefa_cup") == "euro",
		"the U.E.F.A. Cup books into the euro detail section") and ok
	ok = _assert(Career._comp_bucket("supercup") == "supercup",
		"the Supercup books into its own detail section") and ok

	var scr: ChannelTvScreen = ChannelTvScreen.new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	await process_frame
	ok = _assert(scr._chrome != null, "chrome texture loaded") and ok
	ok = _assert(scr._fee == 0, "no fee before setup — the scene draws nothing over the bake") and ok
	scr.setup(int(FinanceModel.TV_FEE["league"]))
	await process_frame
	ok = _assert(scr._fee == 90_000, "setup carries the fee in") and ok

	# OK emits once, and only from inside its rect.
	var fired := [0]
	scr.ok_pressed.connect(func() -> void: fired[0] += 1)
	_tap(scr, ChannelTvScreen.OK_RECT.get_center())
	await process_frame
	ok = _assert(fired[0] == 1, "OK inside the rect emits exactly once") and ok
	_tap(scr, Vector2(20, 20))
	await process_frame
	ok = _assert(fired[0] == 1, "a tap outside the rect does not emit") and ok
	# Press-then-release-elsewhere must not fire either (the shared press/commit rule).
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = ChannelTvScreen.OK_RECT.get_center()
	scr._on_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(20, 20)
	scr._on_input(up)
	await process_frame
	ok = _assert(fired[0] == 1, "press inside, release outside does not emit") and ok

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(scr: ChannelTvScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		scr._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
