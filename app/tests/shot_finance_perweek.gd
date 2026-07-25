extends SceneTree
## Render the FINANCES / INC. + EXP. / PER WEEK view against the two real MANAGER.EXE
## frames it was baked from (REFRUN R5/R9, Manchester Utd. 1997-98):
##
##   p0495_finance_perweek_wk31.png  the LIVE week — label "CURRENT 31",
##                                   "From 15-2-1998 to 21-2-1998", every cell £0
##   p0509_finance_perweek_wk29.png  stepped back — label "29" (no CURRENT),
##                                   "From 1-2-1998 to 7-2-1998", the played HOME week
##
## The books fed here are the ORIGINAL's own numbers off those frames, so every value
## cell, both totals, the header label, the date span and the LAST WEEK / CURRENT WEEK
## tiles must land on the frame's own pixels.
##
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_finance_perweek.gd

# Week 29, the played HOME week, exactly as the frame prints it.
const WK29 := {
	"week": 29,
	"income": {"TICKETS": 364_980, "TELEVISION": 90_000},
	"expense": {"PLAYERS' WAGE": 226_923, "PLAYERS' BONUS": 5_000, "STAFF WAGES": 7_019},
}
# Week 30, the AWAY week: income £0, expenses the flat wage+staff charge. Read off
# p0495's own LAST WEEK tile.
const WK30 := {
	"week": 30,
	"income": {},
	"expense": {"PLAYERS' WAGE": 226_923, "STAFF WAGES": 7_019},
}
const CASH := 3_283_406
const LEAGUE_WEEK := 29        # -> finance week 31, the live one


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
		[_full(WK29), _full(WK30)])

	node.show_week(31)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/finance_perweek_31.png" % dir)

	node.show_week(29)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/finance_perweek_29.png" % dir)

	print("wrote %s/finance_perweek_{31,29}.png" % dir)
	quit(0)


## Expand a sparse literal into a full week record — every line the screen prints,
## missing ones at £0, which is how the original shows them.
func _full(rec: Dictionary) -> Dictionary:
	var out := FinanceModel.new_week_ledger(int(rec["week"]))
	for line in (rec["income"] as Dictionary):
		out["income"][line] = int(rec["income"][line])
	for line in (rec["expense"] as Dictionary):
		out["expense"][line] = int(rec["expense"][line])
	return out
