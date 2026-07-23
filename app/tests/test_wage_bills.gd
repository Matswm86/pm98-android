extends SceneTree
## LEAGUE-WIDE wage validation. The prior handoff flagged "wages 2-8x too high for every club
## except Man Utd" against the SUPERSEDED f(core4)xclub_factor model. That is disproven here: the
## byte-exact PM98 wage table (TransferMarket.yearly_wage, stature-banded, RE'd 2026-07-22d/e)
## reproduces the live-witnessed WEEK-1 wage bills of three DIFFERENT-band Premier clubs to within
## the /52 weekly-rounding error. Witnesses = export_club_economy live captures, wage_formula_re.md
## §1: Bolton (band 3) 39,903/wk, Aston Villa (band 1) 129,326/wk, Arsenal (band 0) 232,692/wk.
##   ~/godot4 --headless --path app --script res://tests/test_wage_bills.gd

# Witnessed live week-1 wage bill (£/wk) -> max acceptable abs error (the squad-size worth of
# per-player /52 rounding; ~26 players * ~£0.5 avg rounding, generous ceiling £50).
const WITNESS := {"Arsenal": 232692, "Aston Villa": 129326, "Bolton": 39903}
const MAX_ABS_ERR := 50


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var clubs: Array = db.get("clubs", [])
	var ok := true
	var seen := 0
	for name in WITNESS:
		var club := _find_club(clubs, name)
		ok = _assert(not club.is_empty(), "found club '%s'" % name) and ok
		if club.is_empty():
			continue
		seen += 1
		var tier := FinanceModel.tier_of(club, leagues)
		var band := TransferMarket.stature_of(club.get("players", []), tier)
		var weekly := 0
		for p in club.get("players", []):
			weekly += TransferMarket.weekly_wage(p, band)
		var anchor: int = WITNESS[name]
		var err: int = absi(weekly - anchor)
		ok = _assert(err <= MAX_ABS_ERR,
			"%-12s band=%d weekly=£%d vs witnessed £%d (err £%d <= £%d)"
			% [name, band, weekly, anchor, err, MAX_ABS_ERR]) and ok
	ok = _assert(seen == WITNESS.size(), "all %d witness clubs present" % WITNESS.size()) and ok
	print("ALL PASS" if ok else "FAILURES ABOVE")
	return ok


func _find_club(clubs: Array, name: String) -> Dictionary:
	for c in clubs:
		if str(c.get("name", "")).findn(name) >= 0:
			return c
	return {}


func _assert(cond: bool, msg: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])
	return cond
