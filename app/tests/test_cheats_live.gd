extends SceneTree
## LIVE end-to-end test for BOTH cheat triggers, through the REAL career flow —
## not the build_mem seam. Mats QA 2026-07-27: "THREE UP FRONT still does not
## fire in play despite the green seam test", so this drives the exact chain a
## real week uses: AudioManager switch -> Career.tactics (saved dict, from_dict
## round-trip) -> advance_week -> _mgr_featured_xi -> repaired -> _pad_xi ->
## MatchSim.simulate -> Pm98StatMatch. Armed = exactly 3 chances/half with no
## keeper gate = at least 6 manager goals in the week's fixture.
##   ~/godot462 --headless --path app --script res://tests/test_cheats_live.gd

const SEED := 20260727


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])
	var clubs_by_id: Dictionary = {}
	for c in all:
		clubs_by_id[int(c["id"])] = c
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in all:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var ok := true

	# ---- A. THREE UP FRONT through the real week (4-3-3 fielded) -----------
	var goals_a := _play_weeks(prem, league, leagues, clubs_by_id, true, "4-3-3", "Attacking")
	ok = _assert(goals_a["min"] >= 6,
		"cheat ON + 4-3-3: every week >= 6 manager goals (min %d over %d games)"
		% [goals_a["min"], goals_a["games"]]) and ok

	# ---- A2. the SHAPE trigger on a squad WITHOUT three natural forwards ---
	# The bug Mats reported twice: pick 4-3-3, see 4-3-3 on the board, turn the cheat
	# on, get stock scorelines — because the front line was filled by a midfielder and
	# the natural-role trigger never fired. Every Premier club is driven here on an
	# ATTACKING 4-3-3 (so MIXED PLAY cannot be what arms it) and every one must score
	# six. Any club whose 4-3-3 happens to hold 3 natural FW would pass on the old
	# trigger too, so the test is only meaningful because it sweeps all 20.
	var worst := 99
	var worst_club := ""
	for i in prem.size():
		var g := _play_weeks(prem, league, leagues, clubs_by_id, true, "4-3-3",
			"Attacking", i)
		if int(g["min"]) < worst:
			worst = int(g["min"])
			worst_club = str((prem[i] as Dictionary).get("name", "?"))
	ok = _assert(worst >= 6,
		"the SHAPE alone arms it at EVERY Premier club on an attacking 4-3-3 "
		+ "(worst %d, %s)" % [worst, worst_club]) and ok

	# ---- B. MIXED PLAY variant (4-4-2 = only 2 FW, forwards trigger off) ---
	var goals_b := _play_weeks(prem, league, leagues, clubs_by_id, true, "4-4-2", "Mixed")
	ok = _assert(goals_b["min"] >= 6,
		"cheat ON + MIXED PLAY on 4-4-2: every week >= 6 goals (min %d)"
		% goals_b["min"]) and ok

	# ---- C. cheat OFF control: same seed, stock scores -----------------------
	var goals_c := _play_weeks(prem, league, leagues, clubs_by_id, false, "4-4-2", "Mixed")
	ok = _assert(goals_c["max"] <= 3,
		"cheat OFF: stock cap holds (max %d <= 3 per match)" % goals_c["max"]) and ok

	# ---- D. no leakage: the mixed-play side is always reset ------------------
	ok = _assert(Pm98StatMatch.cheat_manager_side == -1,
		"cheat_manager_side reset after every simulate") and ok
	ok = _assert(MatchSim.fallback_count == 0,
		"no legacy fallback (got %d)" % MatchSim.fallback_count) and ok

	_am().set_three_up_front(false)
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


## The REAL switch: the AudioManager script (an autoload in the app; instantiated
## directly here because --script runs carry no autoloads). Its
## set_three_up_front is the exact method the OPTIONS row calls, and it mirrors
## into Pm98StatMatch — the chain under test.
var _am_inst: Node = null

func _am() -> Node:
	if _am_inst == null:
		_am_inst = (load("res://scripts/AudioManager.gd") as GDScript).new()
	return _am_inst


## Fresh career, the REAL switch (AudioManager), the REAL tactics persistence
## (to_dict -> career.tactics -> save-shape), three advanced weeks. Returns the
## manager's min/max goals over the played fixtures.
func _play_weeks(prem: Array, league: Dictionary, leagues: Array,
		clubs_by_id: Dictionary, cheat: bool, form: String, ment: String,
		club_idx := 0) -> Dictionary:
	_am().set_three_up_front(cheat)
	MatchSim.fallback_count = 0
	var career := Career.create(prem[club_idx], league, prem, leagues)
	var t := Tactics.from_dict(career.tactics)
	t.set_formation(form, career.club_view(career.club_id))
	t.set_mentality(ment)
	career.tactics = t.to_dict()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var lo := 99
	var hi := 0
	var games := 0
	for _wk in 3:
		var res := career.advance_week(rng, clubs_by_id)
		if res.is_empty():
			continue
		games += 1
		var mine: int = int(res.get("hg", 0)) if bool(res.get("manager_home", true)) \
			else int(res.get("ag", 0))
		lo = mini(lo, mine)
		hi = maxi(hi, mine)
	return {"min": lo, "max": hi, "games": games}


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
