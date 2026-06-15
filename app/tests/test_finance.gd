extends SceneTree
## Headless smoke test for the club finance projection.
##   ~/godot462 --headless --path app --script res://tests/test_finance.gd
## Asserts the ledger is internally consistent (totals = sum of lines, balance =
## income-expense) and lands in plausible ranges for a top-flight club. Prints one.

func _initialize() -> void:
	quit(0 if _run() else 1)


var _leagues: Array = []
var _all: Array = []


func _load() -> void:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	_leagues = db.get("leagues", [])
	_all = db.get("clubs", [])


func _prem() -> Array:
	var out: Array = []
	for c in _all:
		if c.get("leagueId") == "eng_prem":
			out.append(c)
	return out


func _run() -> bool:
	_load()
	var clubs := _prem()
	if clubs.is_empty():
		push_error("no Premier clubs")
		return false
	var club: Dictionary = clubs[0]
	var f := FinanceModel.summary(club, FinanceModel.tier_of(club, _leagues))
	print("=== %s finances (tier %d) ===" % [club["name"], f["tier"]])
	for line in f["income_lines"]:
		print("  + %-22s £%d" % [line[0], line[1]])
	for line in f["expense_lines"]:
		print("  - %-22s £%d" % [line[0], line[1]])
	print("  TOTAL INCOME  £%d" % f["total_income"])
	print("  TOTAL EXPENSE £%d" % f["total_expense"])
	print("  BALANCE       £%d  (£%d/wk)" % [f["season_balance"], f["weekly_balance"]])

	var ok := true
	var sum_in := 0
	for line in f["income_lines"]:
		sum_in += int(line[1])
	var sum_ex := 0
	for line in f["expense_lines"]:
		sum_ex += int(line[1])
	ok = _assert(sum_in == int(f["total_income"]), "income lines sum to total") and ok
	ok = _assert(sum_ex == int(f["total_expense"]), "expense lines sum to total") and ok
	ok = _assert(int(f["season_balance"]) == int(f["total_income"]) - int(f["total_expense"]),
		"balance = income - expense") and ok
	ok = _assert(int(f["total_income"]) > 5_000_000 and int(f["total_income"]) < 60_000_000,
		"top-flight income in plausible 1997-98 range (£%d)" % f["total_income"]) and ok
	ok = _assert(int(f["weekly_wages"]) > 0, "wage bill computed from squad") and ok

	# Lower-tier club should earn materially less than a top-flight one.
	var f4: Dictionary = {}
	for c in _all:
		if FinanceModel.tier_of(c, _leagues) == 4:
			f4 = FinanceModel.summary(c, 4)
			break
	if not f4.is_empty():
		ok = _assert(int(f4["total_income"]) < int(f["total_income"]),
			"tier-4 income (£%d) < tier-1 (£%d)" % [f4["total_income"], f["total_income"]]) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
