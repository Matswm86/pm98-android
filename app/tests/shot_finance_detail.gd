extends SceneTree
## Render the FINANCES INCOME / EXPENSES detail views against the real MANAGER.EXE
## frames they were baked from (walkthrough finance tour, run 3, Manchester Utd. at
## finance week "CURRENT 4"):
##
##   006_164349.png  INCOME / PER WEEK   — the named `SALE Jordi Cruyff £9,120,000` row
##   008_164357.png  EXPENSES / PER WEEK — every cell £0, dynamic labels absent
##   012_164404.png  EXPENSES / PER SEASON — wages 676,442 / 50 bonuses 5,000 /
##                                           staff 1,211 / TOTAL 682,653
##
## The books fed here are the ORIGINAL's own numbers off those frames. The wk1..wk3
## split below is the harness's own (only the totals are witnessed: LAST WEEK
## income 738,750 / expenses 231,692, season wage 676,442, staff 1,211, bonus 5,000)
## — the drawn cells depend only on those witnessed sums.
##
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_finance_detail.gd

const WK1 := {
	"week": 1,
	"income": {},
	"expense": {"PLAYERS' WAGE": 225_281, "STAFF WAGES": 404, "PLAYERS' BONUS": 5_000},
	"detail": {"wage_gross": 225_281, "bonus_n": 50},
}
const WK2 := {
	"week": 2,
	"income": {},
	"expense": {"PLAYERS' WAGE": 219_873, "STAFF WAGES": 403},
	"detail": {"wage_gross": 219_873},
}
const WK3 := {
	"week": 3,
	"income": {"TICKETS": 461_250, "TELEVISION": 277_500},
	"expense": {"PLAYERS' WAGE": 231_288, "STAFF WAGES": 404},
	"detail": {"wage_gross": 231_288},
}
# The RUNNING week 4: the Cruyff sale, posted but not closed (CURRENT WEEK tile).
const WK4_LIVE := {
	"week": 4,
	"income": {"SALE + LOAN PLAY.": 9_120_000},
	"expense": {},
	"detail": {"sales": [["Jordi Cruyff", 9_120_000]]},
}
const CASH := 16_676_098
const CASH_CLOSE := 7_556_099   # the frame's own STORED close figure (£1 off derived)
const LEAGUE_WEEK := 2          # -> finance week 4, "From 10-8-1997 to 16-8-1997"


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var node: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)
	node.setup({}, "Manchester Utd.", "MWM", "1997-98", CASH, LEAGUE_WEEK, {},
		[_full(WK1), _full(WK2), _full(WK3)], _full(WK4_LIVE), CASH_CLOSE,
		{"supercup": false, "intercontinental": false})

	node.show_view(FinanceScreen.VIEW_INCOME, FinanceScreen.PERIOD_WEEK, 4)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/finance_income_week.png" % dir)

	node.show_view(FinanceScreen.VIEW_EXPENSES, FinanceScreen.PERIOD_WEEK, 4)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/finance_expenses_week.png" % dir)

	node.show_view(FinanceScreen.VIEW_EXPENSES, FinanceScreen.PERIOD_SEASON)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/finance_expenses_season.png" % dir)

	print("wrote %s/finance_{income_week,expenses_week,expenses_season}.png" % dir)
	quit(0)


## Expand a sparse literal into a full week record — every line the screen prints,
## missing ones at £0, which is how the original shows them.
func _full(rec: Dictionary) -> Dictionary:
	var out := FinanceModel.new_week_ledger(int(rec["week"]))
	for line in (rec["income"] as Dictionary):
		out["income"][line] = int(rec["income"][line])
	for line in (rec["expense"] as Dictionary):
		out["expense"][line] = int(rec["expense"][line])
	for k in (rec.get("detail", {}) as Dictionary):
		out["detail"][k] = rec["detail"][k]
	return out
