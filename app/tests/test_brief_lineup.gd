extends SceneTree
## The owner's 2026-07-24 report: "Brief still is bugged. It doesn't update the text
## according to current line up, only default. So even after I sell Pallister and buy
## Nesta, in brief it's still Pallister that gets a yellow card."
##
## Two defects, both asserted here:
##   1. `Main._show_match_result` narrated from `GameDB.club()` — the frozen 1997
##      squad — so a SOLD player kept appearing. It now uses `_club_with_roster`.
##   2. `MatchCommentary.narrate` picked event players from the WHOLE squad. The
##      statistical engine is built from the two XIs and nothing else
##      (`Pm98StatMatch.build_mem(xi_h, xi_a, ...)`), so a reserve cannot shoot,
##      clear, foul or be booked. `Career` now hands the featured XIs to the feed.
##
##   ~/godot462 --headless --path app --script res://tests/test_brief_lineup.gd

const SEED := 20260724


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var ok := true

	# ---- 1. a sold player never reaches the feed ------------------------------
	# Sell a squad man to a rival, then play the round he would have played in.
	var squad: Array = career.my_squad()
	var victim: Dictionary = {}
	for p in squad:
		if not p.get("isGK"):
			victim = p
			break
	var buyer := -1
	for id in career.rosters:
		if int(id) != career.club_id:
			buyer = int(id)
			break
	var sold := str(victim.get("name", "?"))
	var sale := career.accept_sale(int(victim.get("id", -1)), buyer, 1_000_000)
	ok = _assert(bool(sale.get("ok", false)), "sold %s (%s)" % [sold, sale.get("msg", "")]) and ok

	var res := career.advance_week(rng)
	ok = _assert(not res.is_empty(), "the manager played a fixture") and ok
	ok = _assert(res.has("xi_home") and res.has("xi_away"),
		"the result carries both featured XIs") and ok

	# The feed is narrated exactly the way Main does it, off the LIVE rosters.
	var home := _club_view(career, int(res["home_id"]))
	var away := _club_view(career, int(res["away_id"]))
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]),
		res.get("goals", []), res.get("xi_home", []), res.get("xi_away", []))

	var named := _named(m["lines"])
	ok = _assert(not named.has(sold),
		"the sold player %s is NOT named in the feed" % sold) and ok

	# ---- 2. only the 22 that played may be named -----------------------------
	var on_pitch: Dictionary = {}
	for side in ["xi_home", "xi_away"]:
		for p in (res.get(side, []) as Array):
			if p is Dictionary:
				on_pitch[str((p as Dictionary).get("name", ""))] = true
	var strays: Array = []
	for nm in named:
		if not on_pitch.has(nm):
			strays.append(nm)
	ok = _assert(strays.is_empty(),
		"every named player was on the pitch (strays: %s)" % ", ".join(strays)) and ok
	ok = _assert(named.size() >= 8, "the feed named %d players" % named.size()) and ok

	# ---- 3. the save/keeper is the XI keeper, not the squad's best PO --------
	var gk_home := str((res["xi_home"] as Array)[0].get("name", ""))
	var gk_away := str((res["xi_away"] as Array)[0].get("name", ""))
	var saves_ok := true
	for ln in m["lines"]:
		var t := str((ln as Dictionary)["text"])
		if t.begins_with("Shot saved by "):
			var who := t.substr(14, t.find(" (") - 14)
			if who != gk_home and who != gk_away:
				saves_ok = false
	ok = _assert(saves_ok, "saves are credited to an XI keeper (%s / %s)" % [gk_home, gk_away]) and ok

	# ---- 4. the legacy no-XI path still works (watched non-career fixture) ---
	var legacy := MatchCommentary.narrate(rng, prem[2], prem[3], 1, 1, [])
	ok = _assert((legacy["lines"] as Array).size() > 10, "the no-XI fallback still narrates") and ok

	# ---- 5. the OLD behaviour is reproduced, so this test can actually fail ---
	# Narrate the same fixture the pre-fix way — frozen GameDB squads, no XIs — and
	# assert the sold man DOES come back. If this stops reproducing, the assertions
	# above have gone vacuous.
	var frozen_h: Dictionary = {}
	var frozen_a: Dictionary = {}
	for c in prem:
		if int(c.get("id", -1)) == int(res["home_id"]):
			frozen_h = c
		elif int(c.get("id", -1)) == int(res["away_id"]):
			frozen_a = c
	var reproduced := false
	for i in 40:                       # the old path re-rolled, so sample it
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = SEED + i
		var old := MatchCommentary.narrate(rng2, frozen_h, frozen_a,
			int(res["hg"]), int(res["ag"]), [])
		if _named(old["lines"]).has(sold):
			reproduced = true
			break
	ok = _assert(reproduced,
		"the pre-fix path still names the sold %s (the repro is live)" % sold) and ok

	print("test_brief_lineup: ", "PASS" if ok else "FAIL")
	return ok


## Career's live view of a club (the headless twin of Main._club_with_roster).
func _club_view(career: Career, id: int) -> Dictionary:
	return {"id": id, "name": career.club_names.get(id, "?"), "players": career.squad_of(id)}


## Every distinct player name the feed mentions ("... by NAME (Club)" / "NAME (Club) ...").
func _named(lines: Array) -> Array:
	var out: Dictionary = {}
	for ln in lines:
		var t := str((ln as Dictionary)["text"])
		var b := t.find(" (")
		if b < 0:
			continue
		var head := t.substr(0, b)
		for lead in ["Goal by ", "Yellow card: ", "Shot by ", "Ball cleared by ",
				"Good defending by ", "Header by ", "Foul by ", "Shot saved by ",
				"Penalty conceded by "]:
			if head.begins_with(lead):
				head = head.substr(lead.length())
				break
		if head.ends_with(" sent off"):
			head = head.substr(0, head.length() - 9)
		if head.ends_with(" offside"):
			head = head.substr(0, head.length() - 8)
		if head != "" and not head.contains(":") and not head.contains("  "):
			out[head] = true
	return out.keys()


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
