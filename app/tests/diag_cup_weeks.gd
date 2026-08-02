extends SceneTree
## One-shot diagnostic: the domestic round weeks Cup.create schedules on the Premier
## calendar (39 slots, blank league week 35) with the 1997-98 pinned week tables.


func _initialize() -> void:
	var ids: Array = []
	for i in 72:
		ids.append(1000 + i)
	var top: Array = []
	for i in 20:
		top.append(2000 + i)
	var entry := {"round": Career.PREMIER_ENTRY_ROUND, "ids": top}
	var host := Career.new()
	# a 39-slot Premier calendar: 38 rounds + the blank week 35
	for i in 39:
		host.fixtures.append([])
	var fa: Dictionary = host._cup_opts_on_calendar(Career.FA_CUP_OPTS,
		Career.FA_CUP_WEEKS)
	fa["late_entry"] = entry
	var lc: Dictionary = host._cup_opts_on_calendar(Career.LEAGUE_CUP_OPTS,
		Career.LEAGUE_CUP_WEEKS)
	lc["late_entry"] = entry
	var facup := Cup.create(ids, 39, fa)
	var lccup := Cup.create(ids, 39, lc)
	print("FA Cup    : ", facup.get("round_weeks", []))
	print("Coca-Cola : ", lccup.get("round_weeks", []))
	quit(0)
