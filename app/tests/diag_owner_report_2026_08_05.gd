extends SceneTree
## THE OWNER'S 2026-08-05 REPORTS, reproduced on the REAL objects at HEAD before anything
## is changed. Four reports:
##   1. "youth training button has no function; the second youth player can only be sacked"
##   2. "three matches play on one CONTINUE with no hub between them"
##   3. "F.A. Cup shares a date with a league match; the league must finish before the
##      F.A. and European finals"
##   4. "RESULTS can only open the euro league; no other competition view opens"
##
##   ~/godot462 --headless --path app --script res://tests/diag_owner_report_2026_08_05.gd

const SEED := 4242

var _ok := true


func _initialize() -> void:
	quit(0 if _run() else 1)


func _db() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func _prem_career() -> Career:
	var db := _db()
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	var prem: Array = []
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	return Career.create(prem[0], league, prem, leagues)


## The REAL construction Main._begin_career runs: full pyramid + the 96-97 honours +
## the foreign euro pool, so the F.A. Cup runs its 8 rounds and euro brackets exist.
func _real_career() -> Career:
	var db := _db()
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	var by_name: Dictionary = {}
	var by_id: Dictionary = {}
	var divs: Array = []
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for lg in leagues:
		var ids: Array = []
		for c in db.get("clubs", []):
			if str(c.get("leagueId", "")) == str(lg["id"]):
				ids.append(c)
		divs.append({"league_id": str(lg["id"]), "name": str(lg["name"]),
			"tier": int(lg.get("tier", 0)), "clubs": ids})
	var prem: Array = (divs[0] as Dictionary)["clubs"]
	for c in db.get("clubs", []):
		by_name[str(c.get("name", ""))] = c
		by_id[int(c.get("id", -1))] = c
	var career := Career.create(prem[0], league, prem, leagues, {"divisions": divs, "seeds": {}})
	var ru: Array = []
	for n in ["Newcastle Utd", "Arsenal", "Liverpool", "Aston Villa"]:
		if by_name.has(n):
			ru.append(int(by_name[n]["id"]))
	var hon := {"champion_id": int(by_name["Manchester Utd."]["id"]),
		"fa_winner_id": int(by_name["Chelsea"]["id"]),
		"lc_winner_id": int(by_name.get("Leicester", {}).get("id", -1)),
		"runners_up": ru,
		"euro_cup_winner": by_name.get("Borussia D.", {}),
		"cwc_winner": by_name.get("F.C. Barcelona", {})}
	var sa := ["ARGENTINA", "BRAZIL", "URUGUAY", "CHILE", "COLOMBIA", "PERU",
		"BOLIVIA", "PARAGUAY", "ECUADOR", "VENEZUELA"]
	var scored: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") != null or str(c.get("country", "")) in sa \
				or (c.get("players", []) as Array).is_empty():
			continue
		var r := MatchEngine.team_ratings(c)
		scored.append({"c": c, "s": float(r["att"]) + float(r["def"]) + float(r["gk"])})
	scored.sort_custom(func(a, b): return a["s"] > b["s"])
	var pool: Array = []
	for e in scored.slice(0, 96):
		pool.append(e["c"])
	var rng := career.career_rng()
	career.open_first_season(hon, pool, by_name.get("Cruzeiro", {}), rng, [])
	return career


func _run() -> bool:
	print("=== 1. YOUTH: the card gates a player sees ===")
	_youth()
	print("\n=== 2/3. THE WEEK'S MATCH PILE-UP + THE FINALS CLASH ===")
	_calendar()
	print("\n=== 4. WHAT EACH RESULTS CHIP WOULD OPEN ===")
	_rail()
	print("\n%s" % ("ALL REPRODUCED / CONFIRMED" if _ok else "CHECK FAILURES ABOVE"))
	return _ok


func _ck(cond: bool, label: String) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	_ok = _ok and cond


func _mk_youth(id: int) -> Dictionary:
	return {"id": id, "name": "Kid %d" % id, "age": 17, "pos": "M", "posFine": 8,
		"attrs": {"VE": 10, "RE": 10, "AG": 10, "CA": 10},
		"attrs_base": {"VE": 15, "RE": 15, "AG": 15, "CA": 15},
		"in_training": false, "ready": false}


func _youth() -> void:
	var c := _prem_career()
	# Two freshly signed academy youngsters, a manager at each witnessed band.
	for stars in [1.0, 3.5, 5.0]:
		c.staff = [{"id": 9, "role": Staff.YOUTH_TEAM_MANAGER, "name": "M", "stars": stars,
			"wage": 1}]
		c.youth = [_mk_youth(1), _mk_youth(2)]
		var cap := Staff.youth_training_capacity(c.staff)
		var r1 := c.set_youth_training(1)
		var r2 := c.set_youth_training(2)
		var gate2 := Training.youth_in_training_count(c.youth) \
			< Staff.youth_training_capacity(c.staff)
		print("  %0.1f* manager: capacity %d | kid1 -> %s | kid2 -> %s | kid2 card TRAINING on=%s"
			% [stars, cap, r1.get("ok"), r2.get("ok"), gate2])
	# The witnessed counters: G. Keeping 3.5* reads "3 PLAYERS" (frame 047), M. Williamson
	# 5.0* reads "4 PLAYERS" (refrun R17) -- both are the CAPACITY, never the roster size.
	_ck(Staff.youth_training_capacity([{"role": Staff.YOUTH_TEAM_MANAGER, "stars": 3.5}]) == 3,
		"3.5* youth manager capacity = 3 (frame 047 '3 PLAYERS')")
	_ck(Staff.youth_training_capacity([{"role": Staff.YOUTH_TEAM_MANAGER, "stars": 5.0}]) == 4,
		"5.0* youth manager capacity = 4 (refrun R17 '4 PLAYERS')")
	# Card feedback: after a SUCCESSFUL training tap the tapped player's OWN card must
	# grey TRAINING (the action is spent) — the visible answer the owner was missing.
	c.staff = [{"id": 9, "role": Staff.YOUTH_TEAM_MANAGER, "name": "M", "stars": 5.0, "wage": 1}]
	c.youth = [_mk_youth(1), _mk_youth(2)]
	c.set_youth_training(1)
	var kid1_on: bool = not Training.youth_in_training(c.youth[0]) \
		and Training.youth_in_training_count(c.youth) \
		< Staff.youth_training_capacity(c.staff)
	var kid2_on: bool = not Training.youth_in_training(c.youth[1]) \
		and Training.youth_in_training_count(c.youth) \
		< Staff.youth_training_capacity(c.staff)
	_ck(not kid1_on, "kid1's card greys TRAINING the moment he is in training (feedback)")
	_ck(kid2_on, "kid2's card keeps TRAINING green below capacity")


func _calendar() -> void:
	var db := _db()
	var clubs := {}
	for cl in db.get("clubs", []):
		clubs[int(cl["id"])] = cl
	var c := _real_career()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	print("  league slots: %d (last league round plays week %d)"
		% [c.total_weeks(), c.total_weeks()])
	print("  F.A. Cup round weeks:   %s" % str(c.fa_cup.get("round_weeks", [])))
	print("  Coca-Cola round weeks:  %s" % str(c.league_cup.get("round_weeks", [])))
	for key in c.euro:
		print("  %-18s weeks: %s" % [key, str((c.euro[key] as Dictionary).get("round_weeks", []))])
	var fa_final := int((c.fa_cup.get("round_weeks", []) as Array).back())
	var ec_final := int((c.euro.get("european_cup", {}).get("round_weeks", []) as Array).back())
	var cc_final := int((c.league_cup.get("round_weeks", []) as Array).back())
	_ck(fa_final > c.total_weeks(), "F.A. FINAL (wk %d) plays AFTER the league (wk %d)"
		% [fa_final, c.total_weeks()])
	_ck(ec_final > c.total_weeks(), "European Cup FINAL (wk %d) plays AFTER the league"
		% ec_final)
	_ck(cc_final == 34, "Coca-Cola FINAL keeps its authored week 34 (got %d)" % cc_final)
	# Walk the season the way the HUB now presents it: one tie popped per CONTINUE, a
	# hub return between each — and count the hub returns a stacked week produces.
	var worst := 0
	var worst_wk := 0
	while not c.season_over():
		var res := c.advance_week(rng, clubs)
		var continues := 0 if res.is_empty() else 1
		while c.has_pending_matches():
			var tie := c.take_next_pending_match()
			continues += 1
			if tie.is_empty():
				break
		if continues > worst:
			worst = continues
			worst_wk = c.week
	print("  worst week now takes %d SEPARATE hub continues (week %d) — never one pile-up"
		% [worst, worst_wk])
	_ck(c.week >= c.total_weeks(), "the season ran out (week %d)" % c.week)
	# Every bracket must end DECIDED for the champion cards (the finals past the league
	# grid resolve on the tail week or in finish_outstanding_cups).
	c.finish_outstanding_cups(rng)
	for pair in [["fa_cup", c.fa_cup], ["league_cup", c.league_cup]]:
		_ck(int((pair[1] as Dictionary).get("champion_id", -1)) != -1,
			"%s decided by season end" % pair[0])
	for key in c.euro:
		_ck(int((c.euro[key] as Dictionary).get("champion_id", -1)) != -1,
			"%s decided by season end" % key)


func _rail() -> void:
	var db := _db()
	var clubs := {}
	for cl in db.get("clubs", []):
		clubs[int(cl["id"])] = cl
	var c := _real_career()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for _w in 25:
		if not c.season_over():
			c.advance_week(rng, clubs)
			c.take_pending_matches()
	print("  career at week %d" % c.week)
	# What Main._show_cup_screen would decide for each rail chip's bracket.
	var brackets := {"facup": c.fa_cup, "cocacola": c.league_cup,
		"euro": c.euro.get("european_cup", {}), "cwc": c.euro.get("cup_winners_cup", {}),
		"uefa": c.euro.get("uefa_cup", {})}
	for chip in brackets:
		var b: Dictionary = brackets[chip]
		var has_view: bool = not b.is_empty() and (
			not (b.get("rounds", []) as Array).is_empty()
			or not (b.get("pending_draw", {}) as Dictionary).is_empty()
			or not Cup.group_tables(b).is_empty())
		_ck(has_view, "%s chip has a real view at week %d" % [chip, c.week])
		var view := "?"
		if not has_view:
			view = "inert (nothing drawn yet — no blank SORTEO any more)"
		elif not Cup.group_tables(b).is_empty() and (b.get("rounds", []) as Array).is_empty():
			view = "EuroGroupScreen"
		else:
			var rounds: Array = b.get("rounds", [])
			var n: int = ((rounds[-1] as Dictionary).get("ties", []) as Array).size() \
				if rounds.size() > 0 else 0
			view = "knockout/list path (last round %d ties)" % n
		print("  %-9s -> %s" % [chip, view])
	print("  supercup empty=%s  intercontinental empty=%s  (chips inert while empty)"
		% [c.supercup.is_empty(), c.intercontinental.is_empty()])
