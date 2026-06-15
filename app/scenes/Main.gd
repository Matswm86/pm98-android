extends Control
## PM98 data browser (first milestone): League -> Club -> Squad -> Player.
## UI is built in code so it validates headless and has no fragile .tscn wiring.
## Match engine, save/load and the rest of the management layer land on top of this.

# Float-form Color(r,g,b) only — the Color("hex") string constructor renders
# transparent/black on the Android runtime (see godot-android reference, gotcha #9).
const BG := Color(0.047, 0.102, 0.071)     # #0c1a12 dark pitch green
const PANEL := Color(0.071, 0.141, 0.102)  # #12241a
const ACCENT := Color(0.224, 1.0, 0.533)   # #39ff88 phosphor green
const TEXT := Color(0.812, 0.910, 0.847)   # #cfe8d8
const DIM := Color(0.498, 0.682, 0.576)    # #7fae93

# Spanish attribute codes -> readable English labels (same semantics as the file).
const ATTR_LABELS := {
	"VE": "Pace", "RE": "Stamina", "AG": "Aggression", "CA": "Ability",
	"RM": "Heading/Finishing", "RG": "Dribbling", "PA": "Passing",
	"TI": "Shooting", "EN": "Tackling", "PO": "Goalkeeping",
}
const ATTR_ORDER := ["CA", "VE", "RE", "AG", "RM", "RG", "PA", "TI", "EN", "PO"]

var _nav: Array[Callable] = []          # view stack; top is re-invoked on Back
var _payload: Array = []                # parallel data for the current list rows
var _on_activate: Callable
var _career: Career = null              # active managed career, null on the menu

@onready var _title: Label = $Root/TopBar/Title
@onready var _subtitle: Label = $Root/TopBar/Subtitle
@onready var _back: Button = $Root/TopBar/Back
@onready var _list: ItemList = $Root/List
@onready var _footer: Label = $Root/Footer


func _ready() -> void:
	_style()
	_back.pressed.connect(_go_back)
	_list.item_activated.connect(_on_item)
	_list.item_selected.connect(_on_item)   # single tap activates on touch
	if GameDB.loaded_path == "":
		GameDB.database_loaded.connect(_show_home, CONNECT_ONE_SHOT)
	else:
		_show_home()
	if OS.has_environment("PM98_SHOT_DIR"):
		_devshot()


# ---- dev screenshot harness (inert unless PM98_SHOT_DIR is set) -----------
# Boots the app, walks home -> squad -> player capturing each, then quits.
# Run under a real/virtual display: PM98_SHOT_DIR=... godot --rendering-driver opengl3 .

func _devshot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.loaded_path == "":
		await GameDB.database_loaded
	await _settle()
	_save_shot(dir, "home.png")
	if not GameDB.leagues.is_empty() or not GameDB.countries().is_empty():
		_on_item(0)            # first competition (Premier League)
		await _settle()
		var idx := 0       # marquee club for the shot, fallback to first listed
		for i in _payload.size():
			var c: Variant = _payload[i]
			if c is Dictionary and c.get("name", "") == "MANCHESTER UTD.":
				idx = i
				break
		_on_item(idx)          # club -> squad
		await _settle()
		_save_shot(dir, "squad.png")
		_on_item(0)            # first player -> attributes
		await _settle()
		_save_shot(dir, "player.png")
		# match engine: simulate the first league and shoot the final table
		_show_home()
		await _settle()
		_on_item(0)            # first competition -> league view
		await _settle()
		_on_item(0)            # "Simulate season" row -> final table
		await _settle()
		_save_shot(dir, "table.png")
	print("DEVSHOT done")
	get_tree().quit()

func _settle() -> void:
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _save_shot(dir: String, fname: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dir.path_join(fname))
	print("DEVSHOT %s -> %s (err %d)" % [fname, dir, err])


func _style() -> void:
	var bg := get_node_or_null("BG")
	if bg == null:
		bg = ColorRect.new()
		bg.name = "BG"
		bg.color = BG
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		move_child(bg, 0)
	_title.add_theme_color_override("font_color", ACCENT)
	_subtitle.add_theme_color_override("font_color", DIM)
	_footer.add_theme_color_override("font_color", DIM)
	_list.add_theme_color_override("font_color", TEXT)
	_list.add_theme_color_override("font_selected_color", BG)
	_list.add_theme_color_override("font_hovered_color", ACCENT)


# ---- navigation ----------------------------------------------------------

func _push(view: Callable) -> void:
	_nav.append(view)
	view.call()

func _go_back() -> void:
	if _nav.size() > 1:
		_nav.pop_back()
		_nav.back().call()

func _set_view(title: String, subtitle: String, rows: Array, payload: Array, on_activate: Callable) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_list.clear()
	for r in rows:
		_list.add_item(str(r))
	_payload = payload
	_on_activate = on_activate
	_back.visible = _nav.size() > 1
	var src := "SAMPLE DATA" if GameDB.is_sample else GameDB.season() + " season"
	_footer.text = "PM98  -  %s  -  %d clubs / %d players" % [
		src, GameDB.clubs.size(), _total_players()]

func _on_item(idx: int) -> void:
	if idx >= 0 and idx < _payload.size() and _on_activate.is_valid():
		_on_activate.call(_payload[idx])

func _total_players() -> int:
	var n := 0
	for c in GameDB.clubs:
		n += (c.get("players", []) as Array).size()
	return n


# ---- views ---------------------------------------------------------------

func _show_home() -> void:
	if _nav.is_empty():
		_nav.append(_show_home)
	var rows: Array = []
	var payload: Array = []
	if Career.has_save():
		rows.append("▶  Continue career")
		payload.append({"type": "career_continue"})
	rows.append("🎮  Start a new career")
	payload.append({"type": "career_new"})
	for lg in GameDB.leagues:
		rows.append("%s  (%d clubs)" % [lg["name"], (lg["clubIds"] as Array).size()])
		payload.append({"type": "league", "league": lg})
	var intl := GameDB.countries()
	if not intl.is_empty():
		rows.append("International  (%d countries)" % intl.size())
		payload.append({"type": "intl"})
	_set_view("PM98", "Manage a club, or browse the database", rows, payload, _activate_home)

func _activate_home(item: Dictionary) -> void:
	match item["type"]:
		"career_continue":
			_career = Career.load_save()
			if _career != null:
				_enter_career()
		"career_new":
			_push(_show_career_pick_league)
		"league":
			_push(_show_league.bind(item["league"]))
		_:
			_push(_show_intl)

func _show_league(league: Dictionary) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = ["▶  Simulate season", "▶  Watch a match"]
	var payload: Array = [{"_sim": league}, {"_match": league}]
	for c in cl:
		rows.append("%-22s %2d" % [c["name"], (c.get("players", []) as Array).size()])
		payload.append(c)
	_set_view(league["name"], "%d clubs  -  tap a club for its squad" % cl.size(),
		rows, payload, _activate_league_row)

func _activate_league_row(item: Dictionary) -> void:
	if item.has("_sim"):
		var lg: Dictionary = item["_sim"]
		var rng := RandomNumberGenerator.new()
		rng.randomize()   # a fresh season each time
		var res := SeasonSim.simulate_season(rng, GameDB.clubs_in_league(lg["id"]))
		_push(_show_table.bind(lg, res["table"]))
	elif item.has("_match"):
		_push(_show_match_pick.bind(item["_match"], null))
	else:
		_push(_show_squad.bind(item))


# ---- match commentary feed ----------------------------------------------

## Club picker for a match. `home` null = pick the home side, else pick away.
func _show_match_pick(league: Dictionary, home: Variant) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	var payload: Array = []
	for c in cl:
		if home != null and int(c["id"]) == int((home as Dictionary)["id"]):
			continue   # can't play yourself
		rows.append(c["name"])
		payload.append(c)
	if home == null:
		_set_view(league["name"], "Pick the HOME side", rows, payload,
			func(c): _push(_show_match_pick.bind(league, c)))
	else:
		_set_view((home as Dictionary)["name"] + "  v  ?", "Pick the AWAY side", rows, payload,
			func(c): _push(_show_match_feed.bind(home, c)))

func _show_match_feed(home: Dictionary, away: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var m := MatchCommentary.timeline(rng, home, away)
	var rows: Array = []
	for ln in m["lines"]:
		var side: int = ln["side"]
		if side == -1:
			rows.append("------  %s" % ln["text"])           # phase marker
		else:
			var tag := "H" if side == 0 else "A"
			var goal := "  *GOAL*" if ln.get("goal") else ""
			rows.append("%2d' [%s] %s%s" % [ln["minute"], tag, ln["text"], goal])
	_set_view("%s %d : %d %s" % [home["name"], m["home_goals"], m["away_goals"], away["name"]],
		"Full time  -  H home / A away  -  Back to pick again",
		rows, [], func(_x): pass)


# ---- career mode ---------------------------------------------------------

func _show_career_pick_league() -> void:
	var rows: Array = []
	var payload: Array = []
	for lg in GameDB.leagues:
		rows.append("%s  (%d clubs)" % [lg["name"], (lg["clubIds"] as Array).size()])
		payload.append(lg)
	_set_view("New career", "Choose a division to manage in", rows, payload,
		func(lg): _push(_show_career_pick_club.bind(lg)))

func _show_career_pick_club(league: Dictionary) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	for c in cl:
		rows.append(c["name"])
	_set_view(league["name"], "Choose the club to take over", rows, cl,
		func(c): _begin_career(league, c))

func _begin_career(league: Dictionary, club: Dictionary) -> void:
	var league_clubs := GameDB.clubs_in_league(league["id"])
	_career = Career.create(club, league, league_clubs, GameDB.leagues)
	_career.save()
	_enter_career()

## Reset the nav so the hub sits one level under Home (Back from hub -> menu).
func _enter_career() -> void:
	_nav = [_show_home]
	_push(_show_career)

func _clubs_by_id(league_id: String) -> Dictionary:
	var out: Dictionary = {}
	for c in GameDB.clubs_in_league(league_id):
		out[int(c["id"])] = c
	return out

## The managed club as a live view: GameDB's static meta (stadium/capacity/league)
## with the career's LIVE roster swapped in, so tactics, squad and finance screens
## reflect signings + sales. Career.club_view is the headless equivalent.
func _mgr_club() -> Dictionary:
	return _club_with_roster(_career.club_id)

func _club_with_roster(id: int) -> Dictionary:
	var base: Dictionary = GameDB.club(id).duplicate()
	base["players"] = _career.squad_of(id)
	return base

## The management hub. Re-reads _career each time so it refreshes after a match.
func _show_career() -> void:
	var c := _career
	var rows: Array = []
	var payload: Array = []
	if c.season_over():
		rows.append("▶  End of season")
		payload.append({"act": "end"})
	else:
		var fx := c.manager_fixture()
		var opp_label := "bye"
		if not fx.is_empty():
			var home: bool = int(fx[0]) == c.club_id
			var opp_id: int = int(fx[1]) if home else int(fx[0])
			var opp: Dictionary = GameDB.club(opp_id)
			opp_label = "%s %s" % ["vs" if home else "at", opp.get("name", "?")]
		rows.append("▶  Play week %d  (%s)" % [c.week + 1, opp_label])
		payload.append({"act": "advance"})
	rows.append("League table")
	payload.append({"act": "table"})
	rows.append("Team & tactics")
	payload.append({"act": "tactics"})
	rows.append("Squad")
	payload.append({"act": "squad"})
	var win := "open, deadline in %dw" % c.deadline_weeks_left() if c.transfers_open() else "closed"
	rows.append("Transfers   (window %s)" % win)
	payload.append({"act": "transfers"})
	rows.append("Finances")
	payload.append({"act": "finance"})
	rows.append("Save game")
	payload.append({"act": "save"})
	var sub := "Week %d/%d  -  %d%s  -  £%s  -  obj: %s" % [
		mini(c.week + 1, c.total_weeks()), c.total_weeks(), c.position(),
		_ord_suffix(c.position()), _fmt_int(c.cash), c.objective_text]
	_set_view("%s  -  %s" % [c.club_name, c.season], sub, rows, payload, _activate_career)

func _activate_career(item: Dictionary) -> void:
	match item["act"]:
		"advance": _career_advance()
		"end": _push(_show_end_of_season)
		"table": _show_league_table_screen()
		"tactics": _push(_show_tactics)
		"squad": _show_squad_screen()
		"transfers": _push(_show_transfers)
		"finance": _show_finance_screen()
		"save":
			_career.save()
			_toast("Game saved")

func _career_advance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res := _career.advance_week(rng)   # ratings come from the live roster
	_career.save()   # autosave each week
	if res.is_empty():
		_show_career()   # bye / season just ended; refresh in place
		return
	_push(_show_match_result.bind(res))

func _show_match_result(res: Dictionary) -> void:
	var home_id: int = res["home_id"]
	var away_id: int = res["away_id"]
	var home := GameDB.club(home_id)
	var away := GameDB.club(away_id)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Narrate the EXACT stored scoreline so feed and table agree.
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]))
	var rows: Array = []
	for ln in m["lines"]:
		var side: int = ln["side"]
		if side == -1:
			rows.append("------  %s" % ln["text"])
		else:
			var tag := "H" if side == 0 else "A"
			var goal := "  *GOAL*" if ln.get("goal") else ""
			rows.append("%2d' [%s] %s%s" % [ln["minute"], tag, ln["text"], goal])
	var you_h: bool = res["manager_home"]
	var verdict := _result_word(int(res["hg"]), int(res["ag"]), you_h)
	_set_view("%s %d : %d %s" % [home["name"], res["hg"], res["ag"], away["name"]],
		"%s  -  Back to the dugout" % verdict, rows, [], func(_x): pass)

## The original-art LEAGUE TABLES screen as a full-screen overlay over the hub,
## driven by the live career standings. Tap to dismiss. (First screen of the
## graphics reskin; see scenes/LeagueTableScreen.gd for asset provenance.)
func _show_league_table_screen() -> void:
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_career.standings(), _career.club_name, _career.season,
		"Week %d" % mini(_career.week + 1, _career.total_weeks()),
		_career.tier, _career.club_id)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## The original-art LINE-UP (ALINEACIÓN) screen as a full-screen overlay: the squad
## list + the CAMPO mini-pitch with the chosen XI in formation, at the coordinates
## reversed from MANAGER.EXE (docs/re/lineup_screen_re.md). Tap to dismiss.
func _show_lineup_screen() -> void:
	var scr: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), _tactics(), "", _career.league_name)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## The original-art SQUAD MANAGEMENT (PLANTILLA) screen as a full-screen overlay:
## the roster grouped (goalkeepers / outfield) with the player-grid columns, at the
## coordinates reversed from MANAGER.EXE (docs/re/squad_screen_re.md). Tap to dismiss.
func _show_squad_screen() -> void:
	var scr: SquadScreen = load("res://scenes/SquadScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), "", "£%s" % _fmt_int(_career.cash))
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## The original-art FINANCES ("INCOME + EXPENSES") screen as a full-screen overlay:
## the income/expense ledger + totals at the coordinates reversed from MANAGER.EXE
## (docs/re/finance_screen_re.md), driven by FinanceModel. Tap to dismiss.
func _show_finance_screen() -> void:
	var club := _mgr_club()
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(sm, _career.club_name, "", _career.season)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

func _show_career_table() -> void:
	var rows: Array = []
	var standings := _career.standings()
	var n := standings.size()
	for pos in n:
		var r: Dictionary = standings[pos]
		var me := "*" if int(r["id"]) == _career.club_id else " "
		rows.append("%2d%s %-15s %2d-%2d-%2d %+3d %3d" % [
			pos + 1, me, r["name"], r["W"], r["D"], r["L"],
			int(r["GF"]) - int(r["GA"]), r["Pts"]])
	_set_view("%s  -  table" % _career.league_name,
		"Week %d/%d  -  * = you  -  W-D-L GD Pts" % [mini(_career.week + 1, n), _career.total_weeks()],
		rows, [], func(_x): pass)

# ---- team selection + tactics (S6) ---------------------------------------
# LINE-UP / formation / marking / set-piece takers, persisted on the career and
# fed into the match engine for the manager's own club. PM98 surface; see
# Tactics.gd for the binary-string provenance.

func _tactics() -> Tactics:
	if _career.tactics.is_empty():
		_career.tactics = Tactics.auto_pick(_mgr_club()).to_dict()
	return Tactics.from_dict(_career.tactics)

func _save_tactics(t: Tactics) -> void:
	_career.tactics = t.to_dict()
	_career.save()

func _slot_stat(role: String, attrs: Dictionary) -> String:
	if role == "GK":
		return "PO %d" % int(attrs.get("PO", 0))
	if role == "DEF":
		return "DEF %d" % roundi(MatchEngine.def_score(attrs))
	return "ATT %d" % roundi(MatchEngine.atk_score(attrs))

func _show_tactics() -> void:
	var club := _mgr_club()
	var t := _tactics()
	var r := t.ratings(club)
	var valid := t.validate(club) == ""
	var rows: Array = []
	var payload: Array = []
	rows.append("VIEW LINE-UP   (the pitch)"); payload.append({"a": "lineup_view"})
	rows.append("Formation:   %s" % t.formation); payload.append({"a": "formation"})
	rows.append("LINE-UP   (choose your XI)"); payload.append({"a": "lineup"})
	rows.append("Marking:   %s" % t.marking); payload.append({"a": "marking"})
	rows.append("Set-piece takers"); payload.append({"a": "takers"})
	rows.append("Auto-pick best XI"); payload.append({"a": "auto"})
	rows.append("SAVE TACTICS"); payload.append({"a": "save"})
	rows.append("LOAD TACTICS"); payload.append({"a": "load"})
	if not valid:
		rows.append("⚠  %s" % Tactics.LINEUP_BAD); payload.append({"a": "noop"})
	var sub := "ATT %d  -  DEF %d  -  GK %d   (%s)" % [
		roundi(r["att"]), roundi(r["def"]), roundi(r["gk"]),
		"line-up OK" if valid else "invalid: auto-filled"]
	_set_view("%s  -  TEAM TACTICS" % _career.club_name, sub, rows, payload, _activate_tactics)

func _activate_tactics(item: Dictionary) -> void:
	match item["a"]:
		"lineup_view": _show_lineup_screen()
		"formation": _push(_show_formation_pick)
		"lineup": _push(_show_lineup)
		"takers": _push(_show_takers)
		"load": _push(_show_load_tactics)
		"marking":
			var t := _tactics()
			t.cycle_marking()
			_save_tactics(t)
			_show_tactics()
		"auto":
			var t := Tactics.auto_pick(_mgr_club(), _tactics().formation)
			_save_tactics(t)
			_show_tactics()
		"save":
			var t := _tactics()
			t.save_preset("%s %s" % [t.formation, t.marking])
			_toast("Tactics saved")

func _show_formation_pick() -> void:
	var t := _tactics()
	var rows: Array = []
	var payload: Array = []
	for form in Tactics.FORMATION_ORDER:
		var lines: Array = Tactics.FORMATIONS[form]
		var mark := "   <- current" if form == t.formation else ""
		rows.append("%s   (%d def / %d mid / %d fwd)%s" % [form, lines[0], lines[1], lines[2], mark])
		payload.append(form)
	_set_view("Formation", "Pick a shape  -  the XI re-fills to fit", rows, payload, _activate_formation)

func _activate_formation(form: String) -> void:
	var t := _tactics()
	t.set_formation(form, _mgr_club())
	_save_tactics(t)
	_go_back()

func _show_lineup() -> void:
	var club := _mgr_club()
	var t := _tactics()
	var by_id := _squad_by_id(club)
	var rs := t.roles()
	var rows: Array = []
	var payload: Array = []
	for i in t.xi.size():
		var p: Variant = by_id.get(int(t.xi[i]))
		var nm: String = (p as Dictionary).get("name", "?") if p != null else "(empty)"
		var attrs: Dictionary = (p as Dictionary).get("attrs", {}) if p != null else {}
		var cap := "  (C)" if p != null and int(t.xi[i]) == t.captain_id else ""
		rows.append("%-4s %-15s %-7s%s" % [rs[i], nm, _slot_stat(rs[i], attrs), cap])
		payload.append({"slot": i})
	_set_view("%s  -  LINE-UP" % t.formation, "Tap a slot to change that player",
		rows, payload, func(it): _push(_show_pick_player.bind(int(it["slot"]))))

func _show_pick_player(slot: int) -> void:
	var club := _mgr_club()
	var t := _tactics()
	var role: String = t.roles()[slot]
	var want_gk := role == "GK"
	var in_xi: Dictionary = {}
	for id in t.xi:
		in_xi[int(id)] = true
	var cands: Array = []
	for p in club.get("players", []):
		if bool(p.get("isGK", false)) == want_gk:
			cands.append(p)
	cands.sort_custom(func(a, b): return _cand_key(role, a) > _cand_key(role, b))
	var rows: Array = []
	var payload: Array = []
	for p in cands:
		var attrs: Dictionary = p.get("attrs", {})
		var here := "  * in XI" if in_xi.has(int(p["id"])) else ""
		rows.append("%-15s %-7s%s" % [p.get("name", "?"), _slot_stat(role, attrs), here])
		payload.append(int(p["id"]))
	_set_view("Pick %s" % role, "Slot %d  -  tap a player" % (slot + 1),
		rows, payload, func(pid): _assign_slot(slot, int(pid)))

func _assign_slot(slot: int, pid: int) -> void:
	var t := _tactics()
	t.assign(slot, pid)
	_save_tactics(t)
	_go_back()

func _show_takers() -> void:
	var club := _mgr_club()
	var t := _tactics()
	var by_id := _squad_by_id(club)
	var defs := [
		["Captain", t.captain_id, "cap"], ["Penalty taker", t.pk_taker_id, "pk"],
		["Corner taker", t.ck_taker_id, "ck"], ["Free-kick taker", t.fk_taker_id, "fk"],
	]
	var rows: Array = []
	var payload: Array = []
	for rl in defs:
		var nm: String = (by_id.get(int(rl[1]), {}) as Dictionary).get("name", "(none)")
		rows.append("%-16s %s" % [rl[0], nm])
		payload.append({"role": rl[2]})
	_set_view("Set-piece takers", "Tap to choose from your XI", rows, payload,
		func(it): _push(_show_pick_taker.bind(it["role"])))

func _show_pick_taker(role_key: String) -> void:
	var club := _mgr_club()
	var t := _tactics()
	var by_id := _squad_by_id(club)
	var first := 0 if role_key == "cap" else 1   # takers are outfield; captain can be the GK
	var rows: Array = []
	var payload: Array = []
	for i in range(first, t.xi.size()):
		var p: Variant = by_id.get(int(t.xi[i]))
		if p == null:
			continue
		rows.append((p as Dictionary).get("name", "?"))
		payload.append(int(t.xi[i]))
	_set_view("Choose taker", "From your starting XI", rows, payload,
		func(pid): _assign_taker(role_key, int(pid)))

func _assign_taker(role_key: String, pid: int) -> void:
	var t := _tactics()
	match role_key:
		"cap": t.captain_id = pid
		"pk": t.pk_taker_id = pid
		"ck": t.ck_taker_id = pid
		"fk": t.fk_taker_id = pid
	_save_tactics(t)
	_go_back()

func _show_load_tactics() -> void:
	var rows: Array = []
	var payload: Array = []
	for pr in Tactics.list_presets():
		var tag := "[predef]" if pr.get("builtin") else "[saved]"
		rows.append("%-18s %-10s %s" % [pr.get("name", "?"), pr.get("marking", "Zonal"), tag])
		payload.append(pr)
	_set_view("LOAD TACTICS", "Apply a saved or predefined shape", rows, payload, _activate_load)

func _activate_load(preset: Dictionary) -> void:
	var t := _tactics()
	t.apply_preset(preset, _mgr_club())
	_save_tactics(t)
	_go_back()

func _cand_key(role: String, p: Dictionary) -> float:
	var attrs: Dictionary = p.get("attrs", {})
	if role == "GK":
		return float(attrs.get("PO", 0))
	if role == "DEF":
		return MatchEngine.def_score(attrs)
	return MatchEngine.atk_score(attrs)

func _squad_by_id(club: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for p in club.get("players", []):
		out[int(p.get("id", -1))] = p
	return out


# ---- transfer market (S7) ------------------------------------------------
# TRANSFER MARKET / OFFERS / RENEW / SALE -- buy, sell, renew and track targets.
# Squads + cash mutate on the career and persist. PM98 screen surface; the
# valuation model is ours-calibrated (see TransferMarket.gd).

func _show_transfers() -> void:
	var c := _career
	var rows: Array = []
	var payload: Array = []
	rows.append("TRANSFER MARKET"); payload.append({"t": "market"})
	rows.append("MY SQUAD   (sell / RENEW)"); payload.append({"t": "squad"})
	rows.append("Shortlist   (%d)" % c.shortlist.size()); payload.append({"t": "shortlist"})
	rows.append("Transfer news   (%d)" % c.transfer_log.size()); payload.append({"t": "news"})
	var win := ("OPEN, deadline in %d weeks" % c.deadline_weeks_left()) if c.transfers_open() else "CLOSED"
	_set_view("%s  -  TRANSFERS" % c.club_name,
		"Window %s  -  £%s bank  -  %d offers left this week" % [win, _fmt_int(c.cash), c.offers_left],
		rows, payload, func(it): _activate_transfers(it["t"]))

func _activate_transfers(which: String) -> void:
	match which:
		"market": _push(_show_market)
		"squad": _push(_show_transfer_squad)
		"shortlist": _push(_show_shortlist)
		"news": _push(_show_transfer_news)

func _bid_round(n: int) -> int:
	var step: int = 50000 if _career.tier <= 2 else 5000
	return int(round(float(n) / step)) * step

func _show_market() -> void:
	var rows: Array = []
	var payload: Array = []
	for row in _career.market():
		var gk := "GK" if row["isGK"] else "  "
		var key := " *" if row["key"] else "  "
		var star := "♥" if _career.shortlist.has(int(row["pid"])) else " "
		rows.append("%s%-15s %s CA%2d £%-9s %-13s%s" % [
			star, row["name"], gk, int(row["ca"]), _fmt_int(int(row["fee"])), row["club_name"], key])
		payload.append(row)
	_set_view("TRANSFER MARKET", "%d players  -  * = first XI (dearer)  -  tap to bid" % rows.size(),
		rows, payload, func(row): _push(_show_market_player.bind(row)))

func _show_market_player(row: Dictionary) -> void:
	var key: bool = row["key"]
	var fee: int = int(row["fee"])
	var pid := int(row["pid"])
	var asking := int(round(fee * (TransferMarket.KEY_PREMIUM if key else 1.0)))
	var rows: Array = []
	var payload: Array = []
	rows.append("Bid the asking price      £%s" % _fmt_int(asking)); payload.append({"bid": asking})
	rows.append("Bid above asking          £%s" % _fmt_int(_bid_round(int(asking * 1.25))))
	payload.append({"bid": _bid_round(int(asking * 1.25))})
	if key:
		rows.append("Club-record bid (sure)    £%s" % _fmt_int(_bid_round(int(fee * TransferMarket.STAR_FORCE))))
		payload.append({"bid": _bid_round(int(fee * TransferMarket.STAR_FORCE))})
	rows.append("%s shortlist" % ("Remove from" if _career.shortlist.has(pid) else "Add to"))
	payload.append({"short": pid})
	_set_view("Bid for %s" % row["name"],
		"%s  -  CLUB FEE £%s  -  YEARLY WAGE £%s%s" % [
			row["club_name"], _fmt_int(fee), _fmt_int(int(row["wage"])), "  (first XI)" if key else ""],
		rows, payload, func(it): _market_action(row, it))

func _market_action(row: Dictionary, it: Dictionary) -> void:
	if it.has("short"):
		_career.toggle_shortlist(int(it["short"]))
		_career.save()
		_show_market_player(row)
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res := _career.sign_player(int(row["pid"]), int(row["club_id"]), int(it["bid"]), rng)
	_career.save()
	if res["ok"]:
		_nav.pop_back()                      # drop the bid screen
		_push(_show_deal_result.bind(res["msg"]))
	else:
		_toast(res["msg"])                   # stay; try a higher bid (offers permitting)

func _show_transfer_squad() -> void:
	var squad: Array = _career.my_squad().duplicate()
	squad.sort_custom(func(a, b):
		var ak := 1 if a.get("isGK") else 0
		var bk := 1 if b.get("isGK") else 0
		if ak != bk:
			return ak > bk
		return int(a.get("attrs", {}).get("CA", 0)) > int(b.get("attrs", {}).get("CA", 0)))
	var rows: Array = []
	var payload: Array = []
	for p in squad:
		var pid := int(p["id"])
		var pos := "GK" if p.get("isGK") else "  "
		var ca := int((p.get("attrs", {}) as Dictionary).get("CA", 0))
		var yrs := int(p.get("contract_years", 1))
		var listed := "  [LISTED]" if _career.is_listed(pid) else ""
		rows.append("%-15s %s CA%2d  %dy%s" % [p.get("name", "?"), pos, ca, yrs, listed])
		payload.append(p)
	_set_view("MY SQUAD  (%d)" % squad.size(), "Tap a player to RENEW, list or sell",
		rows, payload, func(p): _push(_show_player_deal.bind(p)))

func _show_player_deal(p: Dictionary) -> void:
	var pid := int(p["id"])
	var rows: Array = []
	var payload: Array = []
	rows.append("RENEW contract"); payload.append({"a": "renew"})
	rows.append("Remove from transfer list" if _career.is_listed(pid) else "Place on transfer list")
	payload.append({"a": "list"})
	rows.append("Get an offer / sell now"); payload.append({"a": "sell"})
	var attrs: Dictionary = p.get("attrs", {})
	_set_view(p.get("name", "?"),
		"CA %d  -  CLUB FEE £%s  -  YEARLY WAGE £%s  -  contract %dy" % [
			int(attrs.get("CA", 0)), _fmt_int(TransferMarket.value_of(p, _career.tier)),
			_fmt_int(TransferMarket.wage_yearly(p, _career.tier)), int(p.get("contract_years", 1))],
		rows, payload, func(it): _player_deal_action(p, it["a"]))

func _player_deal_action(p: Dictionary, a: String) -> void:
	var pid := int(p["id"])
	match a:
		"renew":
			var res := _career.renew(pid)
			_career.save()
			_nav.pop_back()
			_push(_show_deal_result.bind(res["msg"]))
		"list":
			_career.toggle_listed(pid)
			_career.save()
			_show_player_deal(p)
		"sell":
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var offer := _career.solicit_sale(pid, rng)
			if offer.is_empty():
				_toast("No club has made an offer.")
			else:
				_push(_show_sale_offer.bind(pid, p.get("name", "?"), offer))

func _show_sale_offer(pid: int, pname: String, offer: Dictionary) -> void:
	var rows := ["ACCEPT  -  sell for £%s" % _fmt_int(int(offer["offer"])), "REFUSE"]
	var payload := [{"a": "accept"}, {"a": "refuse"}]
	_set_view("Offer for %s" % pname,
		"%s bid £%s  (you value him at £%s)" % [
			offer["buyer_name"], _fmt_int(int(offer["offer"])), _fmt_int(int(offer["value"]))],
		rows, payload, func(it): _sale_action(pid, offer, it["a"]))

func _sale_action(pid: int, offer: Dictionary, a: String) -> void:
	if a == "refuse":
		_go_back()
		return
	var res := _career.accept_sale(pid, int(offer["buyer_id"]), int(offer["offer"]))
	_career.save()
	_nav.pop_back()   # drop the offer screen
	_nav.pop_back()   # drop the player screen (he may be gone)
	_push(_show_deal_result.bind(res["msg"]))

func _show_shortlist() -> void:
	var by_pid: Dictionary = {}
	for row in _career.market():
		by_pid[int(row["pid"])] = row
	var rows: Array = []
	var payload: Array = []
	for pid in _career.shortlist:
		var row: Variant = by_pid.get(int(pid))
		if row == null:
			rows.append("(player %d no longer available -- tap to clear)" % int(pid))
			payload.append({"gone": int(pid)})
			continue
		rows.append("%-15s CA%2d  £%-9s %s" % [
			row["name"], int(row["ca"]), _fmt_int(int(row["fee"])), row["club_name"]])
		payload.append(row)
	if rows.is_empty():
		rows.append("(shortlist empty -- add targets from the market)")
		payload.append({})
	_set_view("Shortlist", "%d targets  -  tap to bid" % _career.shortlist.size(),
		rows, payload, _activate_shortlist)

func _activate_shortlist(it: Dictionary) -> void:
	if it.has("club_id"):
		_push(_show_market_player.bind(it))
	elif it.has("gone"):
		_career.toggle_shortlist(int(it["gone"]))
		_career.save()
		_show_shortlist()

func _show_transfer_news() -> void:
	var rows: Array = (_career.transfer_log as Array).duplicate()
	if rows.is_empty():
		rows = ["(no transfer activity yet)"]
	_set_view("Transfer news", "Latest first", rows, [], func(_x): pass)

func _show_deal_result(msg: String) -> void:
	_set_view("Transfer", msg, ["Back to transfers"], [{}], func(_x): _go_back())


func _show_end_of_season() -> void:
	var pos := _career.position()
	var met := _career.objective_met()
	var rows: Array = []
	rows.append("Final position: %d%s of %d" % [pos, _ord_suffix(pos), _career.standings().size()])
	rows.append("Board objective: %s" % _career.objective_text)
	rows.append("Verdict: %s" % ("ACHIEVED - you keep your job" if met else "MISSED - the board is unhappy"))
	rows.append("")
	rows.append("▶  Start next season" if met else "▶  Start next season (last chance)")
	var payload: Array = [{}, {}, {}, {}, {"act": "next"}]
	_set_view("End of %s" % _career.season, "%s" % _career.club_name, rows, payload,
		_activate_end_of_season)

func _activate_end_of_season(item: Dictionary) -> void:
	if item.get("act") == "next":
		_next_season()

func _next_season() -> void:
	# Carry the live squads, cash and tactics into the new season; contracts tick
	# down and unrenewed players leave on a free (handled in Career.advance_season).
	_career.advance_season(GameDB.leagues)
	_career.save()
	_enter_career()

func _show_table(league: Dictionary, table: Array) -> void:
	var tier: int = int(league.get("tier", 0))
	var rows: Array = []
	var payload: Array = []
	var n := table.size()
	for pos in n:
		var r: Dictionary = table[pos]
		var mark := SeasonSim.zone_marker(tier, pos, n)
		rows.append("%2d%s %-15s %2d-%2d-%2d %+3d %3d" % [
			pos + 1, (mark if mark != "" else " "), r["name"],
			r["W"], r["D"], r["L"], r["GD"], r["Pts"]])
		payload.append(GameDB.club(int(r["id"])))
	_set_view("%s  -  final table" % league["name"],
		"%s  -  W-D-L  GD  Pts   (P promo / R releg)" % GameDB.season(),
		rows, payload, _show_squad_from)

func _show_intl() -> void:
	var rows: Array = []
	var payload: Array = []
	for ctry in GameDB.countries():
		var n := GameDB.clubs_in_country(ctry).size()
		rows.append("%-20s %3d" % [ctry, n])
		payload.append(ctry)
	_set_view("International", "%d countries" % rows.size(), rows, payload,
		func(ctry): _push(_show_country.bind(ctry)))

func _show_country(country: String) -> void:
	var cl := GameDB.clubs_in_country(country)
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	for c in cl:
		rows.append("%-22s %2d" % [c["name"], (c.get("players", []) as Array).size()])
	_set_view(country, "%d clubs" % cl.size(), rows, cl, _show_squad_from)

func _show_squad_from(club: Dictionary) -> void:
	_push(_show_squad.bind(club))

func _show_squad(club: Dictionary) -> void:
	var players: Array = (club.get("players", []) as Array).duplicate()
	# keepers first, then by ability descending (the file already roughly does this)
	players.sort_custom(func(a, b):
		var ak: int = 1 if a.get("isGK") else 0
		var bk: int = 1 if b.get("isGK") else 0
		if ak != bk:
			return ak > bk
		return int(a.get("attrs", {}).get("CA", 0)) > int(b.get("attrs", {}).get("CA", 0)))
	var rows: Array = ["💷  Finances"]
	var payload: Array = [{"_fin": club}]
	for p in players:
		var ca: int = int((p.get("attrs", {}) as Dictionary).get("CA", 0))
		var pos := "GK" if p.get("isGK") else "  "
		var age: Variant = p.get("age")
		rows.append("%-16s %s  CA %2d  %s" % [
			p["name"], pos, ca, ("age " + str(int(age))) if age != null else ""])
		payload.append(p)
	var stadium: Variant = club.get("stadium")
	var sub: String = stadium if stadium is String else ""
	if club.get("capacity") != null:
		sub = "%s  (%s)" % [sub, _fmt_int(int(club["capacity"]))]
	_set_view(club["name"], sub, rows, payload, _activate_squad_row)

func _activate_squad_row(item: Dictionary) -> void:
	if item.has("_fin"):
		_push(_show_finance.bind(item["_fin"]))
	else:
		_push(_show_player.bind(item))


# ---- club finances (PCF5 ledger structure, projected figures) ------------

func _show_finance(club: Dictionary) -> void:
	var f := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var rows: Array = []
	rows.append("INCOME + EXPENSES   (%d-week season)" % FinanceModel.SEASON_WEEKS)
	rows.append("")
	for line in f["income_lines"]:
		rows.append("  %-22s £%s" % [line[0], _fmt_int(int(line[1]))])
	rows.append("  %-22s £%s" % ["TOTAL INCOME", _fmt_int(int(f["total_income"]))])
	rows.append("")
	for line in f["expense_lines"]:
		rows.append("  %-22s -£%s" % [line[0], _fmt_int(int(line[1]))])
	rows.append("")
	var bal: int = int(f["season_balance"])
	var sign := "+" if bal >= 0 else "-"
	rows.append("  %-22s %s£%s" % ["BALANCE", sign, _fmt_int(abs(bal))])
	rows.append("  %-22s %s£%s/wk" % ["WEEKLY BALANCE",
		"+" if int(f["weekly_balance"]) >= 0 else "-", _fmt_int(abs(int(f["weekly_balance"])))])
	rows.append("")
	rows.append("CONTROLS")
	rows.append("  %-22s £%d" % ["TICKET PRICE", int(f["ticket_price"])])
	rows.append("  %-22s £%s" % ["PRICE OF BOARD", _fmt_int(int(f["board_price"]))])
	var cap_note := "" if f["capacity_known"] else " (est.)"
	rows.append("  %-22s %s%s @ %d%% att." % ["STADIUM",
		_fmt_int(int(f["capacity"])), cap_note, int(round(100.0 * f["attendance"] / float(f["capacity"])))])
	var div_names := {1: "Premier League", 2: "Division One", 3: "Division Two", 4: "Division Three"}
	_set_view("%s  -  finances" % club["name"],
		"%s  -  projected from squad + stadium" % div_names.get(int(f["tier"]), "League"),
		rows, [], func(_x): pass)

func _show_player(player: Dictionary) -> void:
	var attrs: Dictionary = player.get("attrs", {})
	var rows: Array = []
	if attrs.is_empty():
		rows.append("(no attribute row in the file for this player)")
	else:
		for code in ATTR_ORDER:
			if attrs.has(code):
				rows.append("%-20s %3d" % [ATTR_LABELS.get(code, code), int(attrs[code])])
	var legal: String = player.get("legalName", player["name"])
	var sub := legal
	var by: Variant = player.get("birthYear")
	if by != null:
		sub = "%s  -  b.%s%s" % [legal, str(int(by)),
			("  GK" if player.get("isGK") else "")]
	_set_view(player["name"], sub, rows, [], func(_x): pass)


# ---- helpers -------------------------------------------------------------

## Brief footer feedback (no toast widget; we reuse the footer label).
func _toast(msg: String) -> void:
	_footer.text = msg

func _ord_suffix(n: int) -> String:
	if n % 100 in [11, 12, 13]:
		return "th"
	match n % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"

## Result word from the manager's perspective.
func _result_word(hg: int, ag: int, manager_home: bool) -> String:
	var mine := hg if manager_home else ag
	var theirs := ag if manager_home else hg
	if mine > theirs:
		return "WIN"
	if mine == theirs:
		return "DRAW"
	return "LOSS"

func _fmt_int(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out
