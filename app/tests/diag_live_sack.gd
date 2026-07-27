extends SceneTree
## Drives the REAL Main through the POST-SACK exit: boot Main.tscn, attach a career, force
## the board's financial counter past its threshold, then take the exit the modal's OK takes.
## Asserts what this probe can actually see -- the dismissal is armed, the career lands on
## the TITLE screen, the autosave is gone so "Continue" cannot resume a dead career, and the
## career object is released. It does NOT exercise the hub mount (a bare `_show_career()` on
## a synthetically attached career does not raise the hub, so the modal itself is covered by
## `test_sacking.gd` + the render path, not here). A probe, not a test.
##   DISPLAY=:N godot4 --rendering-driver opengl3 --path app \
##     --script res://tests/diag_live_sack.gd
func _initialize() -> void:
	_run()

func _count(n: Node, t) -> int:
	var k := 0
	for c in n.get_children():
		if is_instance_of(c, t):
			k += 1
	return k

func _run() -> void:
	Career.delete_save()
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 6:
		await process_frame
	var gdb := get_root().get_node_or_null("GameDB")
	if gdb == null:
		print("  SKIPPED: no GameDB autoload in this run mode")
		quit(0)
		return
	var db: Array = gdb.clubs
	var prem: Array = []
	for c in db:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var lg := {}
	for l in (gdb.leagues as Array):
		if l.get("id") == "eng_prem":
			lg = l
	var career := Career.create(prem[0], lg, prem, gdb.leagues)
	main._career = career
	career.save()
	main._show_career()
	for _i in 4:
		await process_frame
	print("  hub up: %s" % (main._hub != null))
	career.loss_weeks = Career.LOSS_SACK_WEEKS
	main._show_career()
	for _i in 4:
		await process_frame
	var ok := career.sack_message() == Career.SACK_MSG_FINANCE
	print("  %s  the board's financial dismissal is armed" % ("PASS" if ok else "FAIL"))
	# Answer the box the way the player does.
	main._leave_career_sacked()
	for _i in 6:
		await process_frame
	var titled := _count(main, load("res://scenes/TitleScreen.gd")) >= 1
	print("  %s  the sacked career lands on the TITLE screen" % ("PASS" if titled else "FAIL"))
	print("  %s  the autosave is gone (Continue cannot resume a dead career)"
		% ("PASS" if not Career.has_save() else "FAIL"))
	print("  %s  the career object is released" % ("PASS" if main._career == null else "FAIL"))
	quit(0)
