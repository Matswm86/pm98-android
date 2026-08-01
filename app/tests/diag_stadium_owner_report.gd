extends SceneTree
## OWNER REPORT PROBE, 2026-08-01: "ticket income in MATCH RESULTS doesn't get increased
## after stadium expansion", and "the image of the stadium doesn't change as I expand".
##
## s81 asserted the WEEK LEDGER's banked TICKETS line. That is a DIFFERENT read from the one
## the owner is looking at: the FULL TIME read-out's stadium panel prints
## `Main._result_stadium()`, which is `Career.finance_summary()`'s TICKETS line divided by
## HOME GAMES. This drives the real Career and prints that exact figure, plus the tile the
## GROUND screen would pick, before and after a real expansion.
##
##   ~/godot4 --headless --path app --script res://tests/diag_stadium_owner_report.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	print("club=%s  capacity=%d  headroom=%d"
		% [str(prem[0].get("name", "")), career.stadium_capacity, career.stadium_headroom])

	var before := _panel(career)
	var added := 20000
	career.stadium_capacity += added
	var after := _panel(career)

	print("\nFULL TIME stadium panel -- what the owner reads after a home match:")
	print("  capacity   %8d -> %8d" % [before["capacity"], after["capacity"]])
	print("  attendance %8d -> %8d" % [before["attendance"], after["attendance"]])
	print("  gate  (£)  %8d -> %8d" % [before["gate"], after["gate"]])
	print("  GROUND tile   %5d -> %5d" % [before["tier"], after["tier"]])

	var ok := int(after["gate"]) > int(before["gate"])
	print("\n[%s] the FULL TIME gate figure after a %d-seat expansion"
		% ["PASS" if ok else "FAIL", added])
	@warning_ignore("integer_division")
	var band := 130000 / 11
	print("     one GROUND tile band = %d seats (tier_for = capacity*11/130000, the"
		% band)
	print("     binary's own magic division at FUN_0051a6e0 @0x51a73a); this expansion")
	print("     crossed %d band edge(s)" % (int(after["tier"]) - int(before["tier"])))

	# And the smallest expansion that DOES move the picture, from the same club.
	var base: int = before["capacity"]
	var step := 0
	while step < 60000:
		step += 500
		if StadiumScreen.tier_for(base + step + career.stadium_headroom) \
				> StadiumScreen.tier_for(base + career.stadium_headroom):
			break
	print("     from %d seats the picture first changes at +%d seats" % [base, step])
	return ok


func _panel(c: Career) -> Dictionary:
	var sm: Dictionary = c.finance_summary()
	var home_games: int = maxi(1, int(sm.get("home_games", 19)))
	var gate := 0
	for line in sm.get("income_lines", []):
		if line[0] == "TICKETS":
			gate = int(line[1])
	@warning_ignore("integer_division")
	return {"capacity": int(sm.get("capacity", 0)),
		"attendance": int(sm.get("attendance", 0)),
		"gate": gate / home_games,
		"tier": StadiumScreen.tier_for(int(sm.get("capacity", 0)) + c.stadium_headroom)}
