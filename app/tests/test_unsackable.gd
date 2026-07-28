extends SceneTree
## Headless gate for the UNSACKABLE cheat (docs/re/hack_unsackable.md).
##
## The EXE patch flips FUN_00545fd0's three "keep him" branches to unconditional jumps,
## which makes all three dismissal arms UNREACHABLE (proved on the real bytes by
## `tools/hack/verify_unsackable.py`). The port's mirror is one early return at the head
## of `Career.sack_message()` / `sack_message_reason()`, so this test asserts the same
## three things the CFG proof asserts, on the port's own side:
##
##   1. with the cheat OFF every one of the three conditions still raises MANAGER.EXE's
##      own message, in the binary's own order of precedence (the non-regression half);
##   2. with the cheat ON no condition raises anything -- singly, or all three at once;
##   3. the switch is wired end to end (AudioManager -> Career static -> settings.cfg)
##      and Main's hub gate, which is `if c.sack_message() != ""`, therefore never fires.
##
## Driven through the same real career the sacking gate uses, plus a full driven season
## with all three conditions forced every week, so this is not a unit test of one `if`.
##
##   ~/godot462 --headless --path app --script res://tests/test_unsackable.gd

const SEED := 20260728


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, what: String) -> bool:
	print("  %s  %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _fresh() -> Career:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return null
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var prem_lg: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			prem_lg = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.is_empty() or prem_lg.is_empty():
		push_error("expected the Premier division")
		return null
	var ef := FileAccess.open("res://data/club_economy.json", FileAccess.READ)
	if ef != null:
		var rows: Dictionary = (JSON.parse_string(ef.get_as_text()) as Dictionary).get("clubs", {})
		for c in prem:
			var row: Dictionary = rows.get(str(int(c["id"])), {})
			if row.has("objective"):
				c["objective"] = str(row["objective"])
	var pick: Dictionary = prem[0]
	for c in prem:
		if str(c.get("objective", "")) == "Champion":
			pick = c
			break
	return Career.create(pick, prem_lg, prem, leagues)


## Put a career into one of FUN_00545fd0's three dismissal states.
func _arm(c: Career, which: String) -> void:
	if which == "finance" or which == "all":
		c.loss_weeks = Career.LOSS_SACK_WEEKS
	if which == "results" or which == "all":
		c.board_sack_flag = 1
	if which == "squad" or which == "all":
		var keep: Array = (c.rosters.get(c.club_id, []) as Array)
		c.rosters[c.club_id] = keep.slice(0, Career.SACK_MIN_SQUAD - 1)


func _run() -> bool:
	var ok := true
	var was: bool = Career.cheat_unsackable

	# ---- 1. the cheat OFF is the stock binary --------------------------------
	Career.cheat_unsackable = false
	var expected := {
		"finance": [Career.SACK_MSG_FINANCE, "insolvent"],
		"results": [Career.SACK_MSG_RESULTS, "results"],
		"squad": [Career.SACK_MSG_SQUAD, "squad"],
	}
	for which in ["finance", "results", "squad"]:
		var c := _fresh()
		if c == null:
			return false
		ok = _assert(c.sack_message() == "", "cheat OFF: a fresh career is not sacked") and ok
		_arm(c, which)
		var pair: Array = expected[which]
		ok = _assert(c.sack_message() == pair[0],
			"cheat OFF: the %s condition still raises MANAGER.EXE's own message" % which) and ok
		ok = _assert(c.sack_message_reason() == pair[1],
			"cheat OFF: ...and its reason word `%s`" % pair[1]) and ok
	# ...and the binary's order of precedence is untouched by the new early return.
	var order := _fresh()
	_arm(order, "all")
	ok = _assert(order.sack_message() == Career.SACK_MSG_FINANCE,
		"cheat OFF: 0x546013 (finance) still outranks the other two") and ok

	# ---- 2. the cheat ON: no condition can dismiss ---------------------------
	Career.cheat_unsackable = true
	for which in ["finance", "results", "squad", "all"]:
		var c := _fresh()
		_arm(c, which)
		ok = _assert(c.sack_message() == "",
			"cheat ON: the %s condition raises nothing" % which) and ok
		ok = _assert(c.sack_message_reason() == "",
			"cheat ON: ...and reports no reason") and ok
		# Main's hub gate is literally `if c.sack_message() != ""`, so this IS the gate.
		ok = _assert(not c.sacked, "cheat ON: ...and the career is never marked sacked") and ok

	# ---- 3. a full driven season with every condition held every week --------
	# Not a unit test of one `if`: the board's review runs for real, the finances move,
	# and all three dismissal states are re-armed after every single week.
	var s := _fresh()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var weeks := 0
	var raised := 0
	while not s.season_over():
		s.advance_week(rng)
		_arm(s, "all")
		if s.sack_message() != "":
			raised += 1
		s.pending_alerts = []
		weeks += 1
	ok = _assert(weeks > 30, "the driven season ran (%d weeks)" % weeks) and ok
	ok = _assert(raised == 0,
		"cheat ON: not one week of a driven season raised a dismissal (%d)" % raised) and ok
	ok = _assert(not s.sacked, "cheat ON: ...and the career ends the season in the job") and ok

	# The same season with the cheat OFF must still be dismissable, or the test above
	# proves nothing about the cheat.
	Career.cheat_unsackable = false
	var t := _fresh()
	_arm(t, "all")
	ok = _assert(t.sack_message() != "",
		"control: the identical state DOES dismiss with the cheat off") and ok

	# ---- 4. the switch, end to end ------------------------------------------
	var am: Node = get_root().get_node_or_null("AudioManager")
	ok = _assert(am != null, "AudioManager autoload mounted") and ok
	if am != null:
		var orig: bool = am.cheat_unsackable
		am.set_unsackable(true)
		ok = _assert(am.cheat_unsackable and Career.cheat_unsackable,
			"set_unsackable(true) moves both the setting and Career's static") and ok
		var armed := _fresh()
		_arm(armed, "all")
		ok = _assert(armed.sack_message() == "",
			"...and a career built afterwards reads the armed static") and ok
		am.set_unsackable(false)
		ok = _assert(not am.cheat_unsackable and not Career.cheat_unsackable,
			"set_unsackable(false) disarms both") and ok
		ok = _assert(armed.sack_message() != "",
			"...and the SAME career is dismissable again (the static is live, not copied)") and ok
		am.set_unsackable(orig)

	Career.cheat_unsackable = was
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok
