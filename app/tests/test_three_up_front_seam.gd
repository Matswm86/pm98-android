extends SceneTree
## Headless SEAM test for THREE UP FRONT: the whole live chain a career match uses
## (game_db pos -> Tactics.auto_pick -> XI dicts -> Pm98StatMatch.build_mem ->
## _att_count), which test_three_up_front.gd bypasses by writing ROLE into Mem
## directly. Covers the three 2026-07-26 QA findings ("won't get me goals"):
##   1. a 4-3-3 auto-pick XI actually ARMS the cave (>= 3 ROLE==3 a side);
##   2. a 4-4-2 opponent does NOT (the buff is per side);
##   3. Tactics.repaired keeps the SHAPE — an injured striker is replaced by the
##      club's next striker, not by the best midfielder (which silently disarmed
##      the cheat);
##   4. flag ON vs OFF changes the 4-3-3 side's result on the same seed, and the
##      ON path yields the cave's 6 (3 chances a half, all converting).
##   ~/godot462 --headless --path app --script res://tests/test_three_up_front_seam.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, what: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _xi_dicts(club: Dictionary, t: Tactics) -> Array:
	var by_id: Dictionary = {}
	for p in club.get("players", []):
		by_id[int(p.get("id", -1))] = p
	var xi: Array = []
	for pid in t.xi:
		if by_id.has(int(pid)):
			xi.append(by_id[int(pid)])
	return xi


func _fw_count(xi: Array) -> int:
	var n := 0
	for p in xi:
		if str(p.get("pos", "")) == "FW":
			n += 1
	return n


func _run() -> bool:
	var ok := true
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var manu: Dictionary = {}
	var opp: Dictionary = {}
	for c in db.get("clubs", []):
		if str(c.get("name", "")).begins_with("Manchester Utd"):
			manu = c
		elif str(c.get("league", c.get("leagueId", ""))) != "" and opp.is_empty():
			pass
	# opponent: first Premier club that is not Man Utd and auto-picks 2 FW
	for c in db.get("clubs", []):
		if c == manu:
			continue
		var t0 := Tactics.auto_pick(c)
		var xi0 := _xi_dicts(c, t0)
		if xi0.size() == 11 and _fw_count(xi0) == 2:
			opp = c
			break
	if manu.is_empty() or opp.is_empty():
		push_error("fixture clubs not found")
		return false

	# 1+2: the live classification seam, via build_mem's own ROLE writes.
	var t433 := Tactics.auto_pick(manu, "4-3-3")
	var xi_h := _xi_dicts(manu, t433)
	var xi_a := _xi_dicts(opp, Tactics.auto_pick(opp))
	ok = _assert(xi_h.size() == 11 and xi_a.size() == 11, "both XIs field eleven") and ok
	ok = _assert(_fw_count(xi_h) >= 3, "4-3-3 auto-pick fields 3 natural forwards") and ok
	var mem := Pm98StatMatch.build_mem(xi_h, xi_a, 1, 2)
	ok = _assert(Pm98StatMatch._att_count(mem, 0) >= 3,
		"home side ARMS the cave through the live chain (>=3 ROLE==3)") and ok
	ok = _assert(Pm98StatMatch._att_count(mem, 1) < 3,
		"the 4-4-2 opponent does NOT arm it") and ok

	# 3: repaired() keeps the shape when a striker goes down (club has spare FWs).
	var spare_fw := 0
	for p in manu.get("players", []):
		if str(p.get("pos", "")) == "FW":
			spare_fw += 1
	if spare_fw >= 4:
		var hurt_id := -1
		for p in xi_h:
			if str(p.get("pos", "")) == "FW":
				hurt_id = int(p.get("id", -1))
				break
		var clubcopy := {"players": []}
		for p in manu.get("players", []):
			if int(p.get("id", -1)) != hurt_id:
				clubcopy["players"].append(p)
		var t2 := t433.repaired(clubcopy)
		var xi2 := _xi_dicts(clubcopy, t2)
		ok = _assert(_fw_count(xi2) >= 3,
			"repaired() replaces an injured striker with a STRIKER (shape kept)") and ok
	else:
		print("  [SKIP] club has <4 natural FWs; repaired-shape case not exercised")

	# 4: ON vs OFF on the same seed through MatchSim.simulate.
	var was := Pm98StatMatch.cheat_three_up_front
	var rh := {"att": 1.0, "def": 1.0}
	Pm98StatMatch.cheat_three_up_front = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260726
	var off := MatchSim.simulate(rng, rh, rh, xi_h, xi_a, 1, 2)
	Pm98StatMatch.cheat_three_up_front = true
	rng = RandomNumberGenerator.new()
	rng.seed = 20260726
	var on := MatchSim.simulate(rng, rh, rh, xi_h, xi_a, 1, 2)
	Pm98StatMatch.cheat_three_up_front = was
	ok = _assert(int(on.get("home_goals", -1)) == 6,
		"flag ON: the armed side scores the cave's 6 (got %d-%d)" % [
			int(on.get("home_goals", -1)), int(on.get("away_goals", -1))]) and ok
	ok = _assert(int(off.get("home_goals", -1)) != 6 or
		int(off.get("away_goals", -1)) != int(on.get("away_goals", -1)) or
		int(off.get("home_goals", -1)) != int(on.get("home_goals", -1)),
		"flag OFF differs on the same seed (got %d-%d)" % [
			int(off.get("home_goals", -1)), int(off.get("away_goals", -1))]) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok
