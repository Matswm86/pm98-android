extends SceneTree
## MANAGER HISTORY screen (frame-true rebuild, 2026-07-16) — headless asserts for
## the geometry, the TOTAL/scroll/RETURN logic, and the Career per-competition
## record math it renders. The pixel gate lives in
## tools/re/diff_managerhistory_parity.py (witnessed states vs frames 15/16).

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# --- baked art present ---
	for n in ["body", "total_on"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/managerhistory/%s.png" % n),
			"art exists: %s" % n) and ok

	# --- screen logic ---
	var scr: ManagerHistoryScreen = load("res://scenes/ManagerHistoryScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)

	# Witnessed single-spell state (frame 15).
	var spell := {"team": "Brighton & HA", "division": "3rd Div.", "pos": "23rd",
		"obj": "YES", "directors": "5", "public": "5"}
	var zeros: Dictionary = {}
	for k in ManagerHistoryScreen.COMP_KEYS:
		zeros[k] = {"pla": 0, "win": 0, "dr": 0, "los": 0, "gf": 0, "ga": 0}
	scr.setup("mwm", [spell], zeros)
	ok = _assert(scr._manager == "mwm", "manager set") and ok
	ok = _assert(scr._spells.size() == 1, "one spell row") and ok
	ok = _assert(not scr._total_on, "TOTAL starts OFF (witnessed frame 15)") and ok
	ok = _assert(scr._total_rows == zeros, "empty totals fall back to season rows") and ok

	# TOTAL toggles on tap inside its plate, back off on a second tap.
	scr._on_input(_tap(560, 328))
	ok = _assert(scr._total_on, "TOTAL tap toggles ON") and ok
	scr._on_input(_tap(560, 328))
	ok = _assert(not scr._total_on, "TOTAL tap toggles OFF") and ok

	# RETURN emits back_pressed.
	var backs := [0]
	scr.back_pressed.connect(func() -> void: backs[0] += 1)
	scr._on_input(_tap(558, 452))
	ok = _assert(backs[0] == 1, "RETURN emits back_pressed") and ok

	# Scroll clamps: 13 visible rows, no scroll with one spell.
	scr._on_input(_tap(462, 283))   # down arrow
	ok = _assert(scr._scroll == 0, "no scroll with 1 spell") and ok
	var many: Array = []
	for i in range(15):
		many.append({"team": "Club %d" % i, "division": "3rd Div.", "pos": "1st",
			"obj": "", "directors": "", "public": ""})
	scr.setup("mwm", many, zeros)
	scr._on_input(_tap(462, 283))
	ok = _assert(scr._scroll == 1, "down arrow scrolls") and ok
	scr._on_input(_tap(462, 283))
	scr._on_input(_tap(462, 283))
	ok = _assert(scr._scroll == 2, "scroll clamps at spells-13") and ok
	scr._on_input(_tap(462, 103))   # up arrow
	ok = _assert(scr._scroll == 1, "up arrow scrolls back") and ok

	# --- Career.competition_record math (real data, no estimates) ---
	var c := Career.new()
	c.club_id = 1
	# League: W 2-1 home, D 0-0 away, L 1-3 home.
	c.results = [
		{"week": 1, "opp_id": 2, "home": true, "hg": 2, "ag": 1},
		{"week": 2, "opp_id": 3, "home": false, "hg": 0, "ag": 0},
		{"week": 3, "opp_id": 4, "home": true, "hg": 1, "ag": 3},
	]
	# FA Cup: a bye, a drawn tie won on replay, plus another club's tie (ignored).
	c.fa_cup = {"rounds": [{"label": "R1", "ties": [
		{"home_id": 1, "away_id": -1, "hg": 0, "ag": 0, "winner_id": 1, "loser_id": -1,
			"decided": "bye", "bye": true},
	]}, {"label": "R2", "ties": [
		{"home_id": 5, "away_id": 1, "hg": 1, "ag": 1, "replay_hg": 0, "replay_ag": 2,
			"winner_id": 1, "loser_id": 5, "decided": "replay", "bye": false},
		{"home_id": 2, "away_id": 3, "hg": 4, "ag": 0, "winner_id": 2, "loser_id": 3,
			"decided": "", "bye": false},
	]}]}
	# Europe: a two-legged tie, manager is the away (a) side of the pairing:
	# leg1 at 9's ground 0-1 (win), leg2 at home 2-2 + the manager's ET goal -> 3-2 win.
	c.euro = {"uefa_cup": {"rounds": [{"label": "R1", "ties": [
		{"home_id": 9, "away_id": 1, "leg1_hg": 0, "leg1_ag": 1, "leg2_hg": 2, "leg2_ag": 2,
			"et_hg": 0, "et_ag": 1, "hg": 2, "ag": 3, "winner_id": 1, "loser_id": 9,
			"decided": "aet", "bye": false},
	]}]}}
	# Charity Shield: the manager's club lost it 0-1.
	c.charity_shield = {"home_id": 1, "away_id": 2, "hg": 0, "ag": 1,
		"winner_id": 2, "loser_id": 1, "decided": ""}
	var rec := c.competition_record()
	var lg: Dictionary = rec["league"]
	ok = _assert(int(lg["pla"]) == 3 and int(lg["win"]) == 1 and int(lg["dr"]) == 1
		and int(lg["los"]) == 1 and int(lg["gf"]) == 3 and int(lg["ga"]) == 4,
		"league row 3/1/1/1 gf3 ga4, got %s" % str(lg)) and ok
	var fa: Dictionary = rec["fa_cup"]
	ok = _assert(int(fa["pla"]) == 2 and int(fa["win"]) == 1 and int(fa["dr"]) == 1
		and int(fa["gf"]) == 3 and int(fa["ga"]) == 1,
		"fa cup: bye skipped, draw + replay win, got %s" % str(fa)) and ok
	var ue: Dictionary = rec["uefa"]
	ok = _assert(int(ue["pla"]) == 2 and int(ue["win"]) == 2 and int(ue["dr"]) == 0
		and int(ue["gf"]) == 4 and int(ue["ga"]) == 2,
		"uefa: both legs from the away perspective, ET folded into leg 2, got %s" % str(ue)) and ok
	var ch: Dictionary = rec["charity"]
	ok = _assert(int(ch["pla"]) == 1 and int(ch["los"]) == 1 and int(ch["ga"]) == 1,
		"charity: one lost final, got %s" % str(ch)) and ok
	ok = _assert(int((rec["coca_cola"] as Dictionary)["pla"]) == 0, "empty cup all-zero") and ok

	# Totals: folding at the season boundary + TOTAL view = folded + current.
	c._fold_comp_total()
	var t := c.competition_total()   # current season still holds the same results
	ok = _assert(int((t["league"] as Dictionary)["pla"]) == 6,
		"total = folded season + running season") and ok
	# Round-trip: comp_total survives save/load.
	var d := c.to_dict()
	var c2 := Career.from_dict(d)
	ok = _assert(int(((c2.comp_total.get("league", {})) as Dictionary).get("pla", 0)) == 3,
		"comp_total round-trips") and ok

	print("MANAGER-HISTORY-SCREEN TESTS %s" % ("ALL PASS" if ok else "FAILURES"))
	quit(0 if ok else 1)


func _tap(x: float, y: float) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.pressed = true
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = Vector2(x, y)
	return e


func _assert(cond: bool, what: String) -> bool:
	print("%s  %s" % ["PASS" if cond else "FAIL", what])
	return cond
