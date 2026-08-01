extends SceneTree
## "Free if relegated" — the clause finally DOES something (2026-08-01).
##
## The clause had been settled as offer-record `rec+0x10` (= `player+0x7c`) with a 0-px
## checkbox render, and carried as "what it does on relegation is still not found". It is
## found, and it has exactly ONE consumer in the whole image — rung 3 of the season-rollover
## release ladder in `FUN_0058AC90` @0x58ae5e:
##
##   0x58ae5e  mov eax,[esp+0x33c] / test / je   ; param_5: the club went DOWN a division
##   0x58ae69  mov eax,[esi+0x7c]  / test / je   ; the clause flag
##   0x58ae70  mov byte [esi+0x84],0             ; record YEARS := 0
##   0x58ae77  mov byte [esi+0x85],0             ; record LEFT  := 0
##   0x58ae7e..0x58aeb6                          ; post .data 0x662d80 -> 0x663254 to the news
##   0x58aebb  jmp the LEAVES tail               ; return 0 -> the head count drops
##
## The "only consumer" is a measurement, not an absence of evidence: an exhaustive
## displacement sweep (tools/re/dispscan.py's restarting sweep) finds nine `[reg+0x7c]`
## flag-test sites in the image — this one, four word-sized tests on an unrelated class and
## four C-runtime sites — and ZERO record-pointer-relative `[reg+0x10]` flag tests anywhere
## in 0x520000..0x5a0000, so a consumer reading the record through a pointer is excluded too.
##
## What this test pins, because each is a separate way to get it wrong:
##
##  1. relegated + clause  -> he LEAVES, with the binary's own line (typos included);
##  2. relegated, NO clause, matches-to-renew MET -> he STAYS (the clause is what releases
##     him, not the rollover generally);
##  3. the RUNG ORDER. In the binary the relegation rung (0x58ae5e) sits BEFORE the
##     matches-to-renew rung (0x58aebd), so a man who has met his renewal clause AND holds
##     the relegation clause still walks. The port used to test matches-to-renew first;
##  4. NOT relegated + clause -> he STAYS. The clause is inert in a season that ended above
##     the drop.
##
##   ~/godot462 --headless --path app --script res://tests/test_relegation_clause.gd

const CLAUSE_MAN := 900001      # relegation clause + matches-to-renew met
const RENEW_MAN := 900002       # matches-to-renew met, NO relegation clause
const PLAIN_MAN := 900003       # relegation clause, no renewal clause
const FILLER_BASE := 900100     # multi-year men that hold the 13-man floor clear


func _initialize() -> void:
	var ok := true
	ok = _run(true) and ok
	ok = _run(false) and ok
	print("test_relegation_clause: ", "ALL PASS" if ok else "FAILURES ABOVE")
	quit(0 if ok else 1)


## One whole season, then the table is rewritten so the manager's club finishes either
## LAST (relegated) or FIRST (safe), and the rollover is run.
func _run(relegate: bool) -> bool:
	var db: Dictionary = JSON.parse_string(
		FileAccess.open("res://data/game_db.json", FileAccess.READ).get_as_text())
	var clubs: Array = db.get("clubs", [])
	var leagues: Array = db.get("leagues", [])
	var by_id := {}
	for c in clubs:
		by_id[int(c["id"])] = c
	var prem := []
	var league := {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in clubs:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	while not career.season_over():
		career.advance_week(rng, by_id)

	# --- the fixture squad -------------------------------------------------------------
	# All three are 25 (well under RETIRE_AGE_OUTFIELD, so rung 0 cannot claim them) and
	# all three are in their LAST contract year, so all three reach the release ladder.
	var roster: Array = career.rosters[career.club_id]
	# PAD FIRST, and the reason is a real flake this fixture used to carry: rung 2 of the
	# ladder is the binary's own 13-man floor (`0x58ae55`, `cmp ecx,0xd / jb keep`), and it
	# is counted DOWN as men leave. A season in which enough of the real squad expired or
	# retired could push the count under thirteen before PLAINMAN was reached, so he was
	# renewed by the floor instead of released by the clause and his line never appeared —
	# a genuine engine rung firing on an under-specified fixture, not an engine bug. The
	# padding men are on MULTI-year deals, so they never enter the ladder at all; they only
	# guarantee that the floor cannot be the thing under test.
	for i in 24:
		var filler := _man(FILLER_BASE + i, "FILLER%d" % i, false, false)
		filler["contract_years"] = 5
		filler["contract_term"] = 5
		roster.append(filler)
	roster.append(_man(CLAUSE_MAN, "CLAUSEMAN", true, true))
	roster.append(_man(RENEW_MAN, "RENEWMAN", false, true))
	roster.append(_man(PLAIN_MAN, "PLAINMAN", true, false))

	# --- force the finishing position -------------------------------------------------
	# `_manager_relegated()` reads the final table, which is exactly what the original's
	# caller reads to set param_5, so rewriting the table IS the fixture.
	var top := 0
	for id in career.table:
		top = maxi(top, int(career.table[id]["Pts"]))
	for id in career.table:
		if int(id) == career.club_id:
			career.table[id]["Pts"] = (-1 if relegate else top + 10)
			career.table[id]["GF"] = 0
			career.table[id]["GA"] = (999 if relegate else 0)
		elif relegate and int(career.table[id]["Pts"]) <= 0:
			career.table[id]["Pts"] = 1     # nobody else may tie the bottom place
	var pos := career.position()
	var total := career.standings().size()

	career.advance_season(leagues, rng)

	# --- verdicts ---------------------------------------------------------------------
	var left := {}
	for pid in [CLAUSE_MAN, RENEW_MAN, PLAIN_MAN]:
		left[pid] = not _in_roster(career, pid)
	var msg_clause := Retirement.RELEGATION_CLAUSE_MSG % "CLAUSEMAN"
	var msg_plain := Retirement.RELEGATION_CLAUSE_MSG % "PLAINMAN"
	var alerts: Array = career.pending_alerts

	var want_gone := relegate
	# PLAIN_MAN holds the relegation clause and nothing else, so in a SAFE season he simply
	# reaches the ordinary "contract not renewed" rung and may leave there — that is not this
	# test's business. What must hold for him either way is that he leaves under the CLAUSE
	# (with the clause's own line) exactly when the club went down, which the alert check
	# below asserts. CLAUSE_MAN is the rung-order witness: his renewal clause is MET, so the
	# only thing that can release him is the relegation rung sitting ahead of it.
	var checks := [
		["clause man leaves iff relegated (rung order beats matches-to-renew)",
			left[CLAUSE_MAN] == want_gone],
		["renewal-clause man WITHOUT the relegation clause always stays", not left[RENEW_MAN]],
		["the binary's own line is raised iff relegated",
			alerts.has(msg_clause) == want_gone and alerts.has(msg_plain) == want_gone],
	]
	var ok := true
	print("  -- %s: finished %d of %d --" % ["RELEGATED" if relegate else "SAFE", pos, total])
	for c in checks:
		var good: bool = c[1]
		ok = good and ok
		print("  %s  %s" % ["ok  " if good else "FAIL", c[0]])
	if want_gone and not alerts.has(msg_clause):
		print("      expected alert: %s" % msg_clause.replace("\n", "\\n"))
	return ok


## A 25-year-old in his last contract year. `clause` = the relegation clause (rec+0x10);
## `renewal` = the matches-to-renew clause with its target already MET, which is the rung
## the relegation rung has to beat.
func _man(pid: int, pname: String, clause: bool, renewal: bool) -> Dictionary:
	var p := {
		"id": pid, "name": pname, "legalName": "TEST %s" % pname, "pos": "MF",
		"age": 25, "contract_years": 1, "contract_term": 1, "wage": 1000,
		"attrs": {"VE": 60, "RE": 60, "AG": 60, "CA": 60, "EN": 60},
		"attrs_base": {"VE": 60, "RE": 60, "AG": 60, "CA": 60, "EN": 60},
		"clauses": [],
	}
	if clause:
		(p["clauses"] as Array).append(OfferRecord.CLAUSE_FREE_IF_RELEGATED)
	if renewal:
		(p["clauses"] as Array).append(OfferRecord.CLAUSE_MATCHES_TO_RENEW)
		p["clause_matches"] = OfferRecord.MATCHES_TO_RENEW
		p["clause_apps"] = OfferRecord.MATCHES_TO_RENEW
	return p


func _in_roster(career: Career, pid: int) -> bool:
	for p in career.rosters.get(career.club_id, []):
		if int(p.get("id", -1)) == pid:
			return true
	return false
