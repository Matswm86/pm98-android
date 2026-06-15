extends SceneTree
## Headless wiring test for the FINANCES ("INCOME + EXPENSES") screen: confirms the
## cracked ORIGINAL assets load, that a real FinanceModel.summary feeds the screen,
## the money formatter is correct, and the totals equal the summed line items.
##   ~/godot462 --headless --path app --script res://tests/test_finance_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Money formatter (static, pure).
	ok = _assert(FinanceScreen.fmt_money(21550750) == "£21,550,750", "fmt_money positive") and ok
	ok = _assert(FinanceScreen.fmt_money(0) == "£0", "fmt_money zero") and ok
	ok = _assert(FinanceScreen.fmt_money(-1234567) == "-£1,234,567", "fmt_money negative") and ok
	ok = _assert(FinanceScreen.fmt_money(999) == "£999", "fmt_money sub-thousand") and ok

	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Real club -> FinanceModel summary.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var club: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem" and (c.get("players", []) as Array).size() >= 14:
			club = c
			break
	ok = _assert(not club.is_empty(), "found a Premier club") and ok
	var sm := FinanceModel.summary(club, 1)
	ok = _assert((sm["income_lines"] as Array).size() == 4, "4 income lines") and ok
	ok = _assert((sm["expense_lines"] as Array).size() == 2, "2 expense lines") and ok

	# Totals equal the summed lines, balance = income - expense.
	var inc := 0
	for line in sm["income_lines"]:
		inc += int(line[1])
	var exp := 0
	for line in sm["expense_lines"]:
		exp += int(line[1])
	ok = _assert(inc == int(sm["total_income"]), "income total = sum of income lines") and ok
	ok = _assert(exp == int(sm["total_expense"]), "expense total = sum of expense lines") and ok
	ok = _assert(int(sm["season_balance"]) == inc - exp, "balance = income - expense") and ok

	# Instantiate + feed the screen.
	var screen: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f12 != null and screen._f10 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(screen._bg != null and screen._bar != null, "FONDO + BARRA loaded") and ok
	screen.setup(sm, club["name"], "A. FERGUSON", "1997-98")
	await process_frame
	ok = _assert((screen._sum["income_lines"] as Array).size() == 4, "screen received the summary") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
