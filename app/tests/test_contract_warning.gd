extends SceneTree
## Headless test for the 1-April season-end / contract-renewal warning
## (MANAGER.EXE FUN_005862E0, message table slots 0x662CDC / 0x662CE0).
##   ~/godot462 --headless --path app --script res://tests/test_contract_warning.gd
## Week-grained trigger: fires once, on the week whose Sun..Sat span contains
## 1 April of the end year; the NIVEL auto-renew flag picks the message.


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, what: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _run() -> bool:
	var ok := true

	# 1997-98: week-1 Saturday = 9 Aug 1997, so 1 April 1998 falls in week 35's span.
	var c := Career.new()
	c.season = "1997-98"
	c.manager_level = "total"          # DAT_0066B1F4 = 0 -> the FULL warning
	c.week = 34
	c._tick_contract_warning()
	ok = _assert(c.pending_alerts.is_empty() and not c.contract_warned,
		"week 34 (Sat 28 Mar) does not fire") and ok
	c.week = 35
	c._tick_contract_warning()
	ok = _assert(c.pending_alerts.size() == 1 and c.contract_warned,
		"week 35 (span 29 Mar..4 Apr) fires once") and ok
	ok = _assert(str(c.pending_alerts[0]) == Career.CONTRACT_WARN_MSG,
		"ACCOUNTANT/TOTAL level gets the full contract warning (flag 0)") and ok
	c._tick_contract_warning()
	ok = _assert(c.pending_alerts.size() == 1, "it never fires twice a season") and ok

	# TRAINER/MANAGER levels auto-renew (flag 1) -> the short message.
	var c2 := Career.new()
	c2.season = "1997-98"
	c2.manager_level = "manager"
	c2.week = 35
	c2._tick_contract_warning()
	ok = _assert(c2.pending_alerts.size() == 1
		and str(c2.pending_alerts[0]) == Career.SEASON_END_MSG,
		"TRAINER/MANAGER level gets the short message (flag 1)") and ok

	# A later season keeps the rule on its own calendar (1 April 1999).
	var c3 := Career.new()
	c3.season = "1998-99"
	c3.manager_level = "total"
	c3.week = 34
	c3._tick_contract_warning()
	var fired_34 := c3.pending_alerts.size()
	c3.week = 35
	c3._tick_contract_warning()
	ok = _assert(fired_34 + c3.pending_alerts.size() >= 1,
		"1998-99 fires on its own late-March/early-April week") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok
