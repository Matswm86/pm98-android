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
var _hub: MenuScreen = null             # persistent MENUPRINCIPAL hub while in a career
var _browse: BrowseScreen = null        # active PM98-chrome browse/select overlay (Track B)

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
		GameDB.database_loaded.connect(_boot, CONNECT_ONE_SHOT)
	else:
		_boot()
	# The devshot walk is the fallback capture; the targeted boot shots (BOOT/HUB/BROWSE)
	# drive their own capture from _boot, so they must not also trigger the walk (it would
	# race them on get_tree().quit()).
	if OS.has_environment("PM98_SHOT_DIR") and not OS.has_environment("PM98_BOOT_SHOT") \
			and not OS.has_environment("PM98_HUB_SHOT") and not OS.has_environment("PM98_BROWSE_SHOT"):
		_devshot()


## Build the base home view, then raise the original-art TITLE front door over it
## (skipped under the data-walk screenshot harness). Under PM98_BOOT_SHOT the title IS
## raised the normal way and the booted frame is captured — the faithful device repro.
func _boot() -> void:
	_show_home()
	if OS.has_environment("PM98_HUB_SHOT"):
		_hub_shot()
		return
	if OS.has_environment("PM98_BROWSE_SHOT"):
		_browse_shot()
		return
	var boot_shot := OS.has_environment("PM98_BOOT_SHOT")
	if boot_shot or not OS.has_environment("PM98_SHOT_DIR"):
		_show_title_screen()
	if boot_shot:
		_boot_shot()


## Capture the real booted frame (the title overlay exactly as _show_title_screen
## mounts it) through the live renderer, then quit. Run as the NORMAL app (no --script)
## so the main scene, stretch and viewport are the real ones the device uses.
func _boot_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	for _i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dir.path_join("boot.png"))
	# Diagnose: is the title mounted, sized, and are its textures actually loaded?
	var t: TitleScreen = null
	for c in get_children():
		if c is TitleScreen:
			t = c
	var diag := "no-title"
	if t != null:
		diag = "size=%s bg=%s bezel=%s" % [str(t.size), str(t._bg != null), str(t._bezel != null)]
	print("BOOT-SHOT err=%d %dx%d %s" % [err, img.get_width(), img.get_height(), diag])
	get_tree().quit()


## Faithful real-render of the B1 career hub: begin a career in the first league with
## the first club through the REAL nav (_begin_career -> _enter_career -> _show_career),
## so the captured frame is the persistent MENUPRINCIPAL hub the device shows, then quit.
## Run as the NORMAL app under Xvfb+GL. Proves the hub mounts and renders (not the green
## list) the only way that counts here, with no display: PM98_HUB_SHOT=1.
func _hub_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("HUB-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career(lg, clubs[0])
	for _i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	# get_image() is null under the headless dummy renderer; guard so the diagnostic always
	# prints (real PNG is captured only under Xvfb+GL in screenshot.yml).
	var img := get_viewport().get_texture().get_image() if get_viewport().get_texture() != null else null
	var err := img.save_png(dir.path_join("hub.png")) if img != null else -1
	var w := img.get_width() if img != null else 0
	var h := img.get_height() if img != null else 0
	var mounted := _hub != null and is_instance_valid(_hub) and _hub.visible
	print("HUB-SHOT err=%d %dx%d hub_mounted=%s club=%s" % [err, w, h, str(mounted), _career.club_name])
	get_tree().quit()


## Faithful real-render of the Track-B browse flow: walk the REAL nav (database home ->
## new-career division + club pickers -> database league browse -> a watched match) and
## capture each frame, so the PNGs prove the PM98-chrome screens (not the green list) the
## device shows. Run as the NORMAL app under Xvfb+GL: PM98_BROWSE_SHOT=1.
func _browse_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("BROWSE-SHOT no leagues loaded")
		get_tree().quit()
		return
	await _settle()
	_save_shot(dir, "home.png")            # _boot already mounted the home/database browse
	_show_career_pick_league()
	await _settle()
	_save_shot(dir, "pick_league.png")
	var lg: Dictionary = GameDB.leagues[0]
	_show_career_pick_club(lg)
	await _settle()
	_save_shot(dir, "pick_club.png")
	_show_db_league(lg)
	await _settle()
	_save_shot(dir, "db_league.png")
	var cl := GameDB.clubs_in_league(lg["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	if cl.size() >= 2:
		_play_watch_match(cl[0], cl[1], lg)
		await _settle()
		_save_shot(dir, "match.png")
	print("BROWSE-SHOT done browse_mounted=%s" % str(_browse != null and is_instance_valid(_browse)))
	get_tree().quit()


# ---- dev screenshot harness (inert unless PM98_SHOT_DIR is set) -----------
# Boots the app, walks home -> squad -> player capturing each, then quits.
# Run under a real/virtual display: PM98_SHOT_DIR=... godot --rendering-driver opengl3 .

func _devshot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.loaded_path == "":
		await GameDB.database_loaded
	await _settle()
	# The TITLE front door (the boot overlay): mount it explicitly, capture a REAL
	# render of it, then free it so the rest of the walk sees the views beneath.
	var title: TitleScreen = load("res://scenes/TitleScreen.gd").new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title)
	await _settle()
	_save_shot(dir, "title.png")
	title.queue_free()
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
	var tex := get_viewport().get_texture()
	var img := tex.get_image() if tex != null else null
	var err := img.save_png(dir.path_join(fname)) if img != null else -1
	print("SHOT %s -> %s (err %d)" % [fname, dir, err])


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
	# Any green data-browser view hides the persistent MENUPRINCIPAL hub (it sits on top
	# of $Root); _show_career re-raises it. Lets the still-green sub-flows (tactics,
	# transfer text menus, match feed, end-of-season) show beneath the hub overlay.
	if _hub != null and is_instance_valid(_hub):
		_hub.visible = false
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


# ---- PM98-chrome browse / overlay plumbing (Track B) ---------------------
# The green data-browser is replaced by BrowseScreen overlays for the connective
# list/select flows (home / database browse / new-career pickers / match feed), and
# the existing reversed art screens (SQUAD, LEAGUE TABLES, FINANCES) for the leaves.

## Mount a fresh PM98-chrome browse list, freeing any previous one (a drill-down
## replaces its parent). `on_select` gets the tapped row index; `on_back` the RETURN tap.
func _mount_browse(title: String, subtitle: String, rows: Array,
		on_select: Callable, on_back: Callable, opts: Dictionary = {}) -> void:
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
	_browse = load("res://scenes/BrowseScreen.gd").new()
	_browse.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_browse)
	_browse.setup(title, subtitle, rows, opts)
	_browse.row_selected.connect(on_select)
	_browse.back_pressed.connect(on_back)

## Free every front-of-house overlay (browse + title) before the career hub takes over.
func _clear_front_overlays() -> void:
	for c in get_children():
		if c is BrowseScreen or c is TitleScreen:
			c.queue_free()
	_browse = null

## Add a full-rect art overlay that frees on any tap (the display-only screen pattern).
func _mount_tap_overlay(scr: Control) -> void:
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## Reversed SQUAD overlay for any club dict (career roster or a GameDB club).
func _open_squad(club: Dictionary, manager: String, cash: String) -> void:
	var scr: SquadScreen = load("res://scenes/SquadScreen.gd").new()
	scr.setup(club, manager, cash)
	_mount_tap_overlay(scr)

## Reversed LEAGUE TABLES overlay for any standings array (career or a SeasonSim table).
func _open_table(rows: Array, title_left: String, season: String, week_label: String,
		tier: int, my_id: int) -> void:
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.setup(rows, title_left, season, week_label, tier, my_id)
	_mount_tap_overlay(scr)

## Reversed FINANCES overlay for any club dict.
func _open_finance(club: Dictionary, club_name: String, season: String) -> void:
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	scr.setup(sm, club_name, "", season)
	_mount_tap_overlay(scr)

## PM98-chrome match read-out (B4): the scoreline in the BARRA, the commentary feed
## as non-selectable rows (goals gold, phase markers dim), RETURN runs `on_back`.
func _open_match(home: Dictionary, away: Dictionary, hg: int, ag: int,
		lines: Array, sub: String, on_back: Callable) -> void:
	var rows: Array = []
	for ln in lines:
		var side: int = ln["side"]
		if side == -1:
			rows.append({"text": "- - -  %s" % ln["text"], "enabled": false,
				"accent": Color(0.59, 0.69, 0.82)})
		else:
			var tag := "H" if side == 0 else "A"
			var g := false
			if ln.get("goal"):
				g = true
			rows.append({
				"text": "%2d'  [%s]  %s%s" % [ln["minute"], tag, ln["text"], "   GOAL!" if g else ""],
				"enabled": false,
				"accent": Color(1.0, 0.87, 0.0) if g else null,
			})
	var scr: BrowseScreen = load("res://scenes/BrowseScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup("%s  %d : %d  %s" % [home.get("name", "?"), hg, ag, away.get("name", "?")],
		sub, rows, {"back_label": "RETURN"})
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		if on_back.is_valid():
			on_back.call())


# ---- views ---------------------------------------------------------------

## The database root (B3): the original-art browse hub. Continue / new career at the top,
## then every league + International. A BrowseScreen overlay; TITLE re-raises the front door.
func _show_home() -> void:
	if _nav.is_empty():
		_nav.append(_show_home)
	var rows: Array = []
	var payload: Array = []
	if Career.has_save():
		rows.append({"text": "Continue career", "accent": Color(0.27, 1.0, 0.53)})
		payload.append({"type": "continue"})
	rows.append({"text": "Start a new career", "accent": Color(0.27, 1.0, 0.53)})
	payload.append({"type": "new"})
	for lg in GameDB.leagues:
		rows.append({"text": lg["name"], "value": "%d clubs" % (lg["clubIds"] as Array).size()})
		payload.append({"type": "league", "league": lg})
	var intl := GameDB.countries()
	if not intl.is_empty():
		rows.append({"text": "International", "value": "%d nations" % intl.size()})
		payload.append({"type": "intl"})
	_mount_browse("PREMIER MANAGER 98", "Database  -  manage or browse", rows,
		func(i: int) -> void: _home_select(payload[i]),
		func() -> void: _show_title_screen(),
		{"back_label": "TITLE"})

func _home_select(item: Dictionary) -> void:
	match item["type"]:
		"continue": _continue_career()
		"new": _show_career_pick_league()
		"league": _show_db_league(item["league"])
		_: _show_db_intl()

func _continue_career() -> void:
	_career = Career.load_save()
	if _career != null:
		_enter_career()

## Database browse of one league (B3): simulate / watch options, then the clubs. Tap a
## club for its reversed SQUAD screen; simulate -> reversed LEAGUE TABLES; watch -> match.
func _show_db_league(league: Dictionary) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	var payload: Array = []
	rows.append({"text": "Simulate the season", "accent": Color(0.27, 1.0, 0.53)})
	payload.append({"act": "sim"})
	rows.append({"text": "Watch a match", "accent": Color(0.27, 1.0, 0.53)})
	payload.append({"act": "watch"})
	for c in cl:
		rows.append({"text": c["name"], "value": "%d" % (c.get("players", []) as Array).size()})
		payload.append({"act": "club", "club": c})
	_mount_browse(league["name"], "%d clubs  -  tap for the squad" % cl.size(), rows,
		func(i: int) -> void: _db_league_select(league, payload[i]),
		func() -> void: _show_home())

func _db_league_select(league: Dictionary, item: Dictionary) -> void:
	match item["act"]:
		"sim":
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var res := SeasonSim.simulate_season(rng, GameDB.clubs_in_league(league["id"]))
			_open_table(res["table"], league["name"], GameDB.season(), "Final",
				int(league.get("tier", 1)), -1)
		"watch":
			_show_match_pick(league, null)
		"club":
			_open_squad(item["club"], "", "")

## Database browse of the international clubs by nation (B3).
func _show_db_intl() -> void:
	var rows: Array = []
	var names: Array = []
	for ctry in GameDB.countries():
		rows.append({"text": str(ctry), "value": "%d" % GameDB.clubs_in_country(ctry).size()})
		names.append(ctry)
	_mount_browse("INTERNATIONAL", "%d nations" % names.size(), rows,
		func(i: int) -> void: _show_db_country(str(names[i])),
		func() -> void: _show_home())

func _show_db_country(country: String) -> void:
	var cl := GameDB.clubs_in_country(country)
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	for c in cl:
		rows.append({"text": c["name"], "value": "%d" % (c.get("players", []) as Array).size()})
	_mount_browse(country.to_upper(), "%d clubs  -  tap for the squad" % cl.size(), rows,
		func(i: int) -> void: _open_squad(cl[i], "", ""),
		func() -> void: _show_db_intl())


# ---- match commentary feed ----------------------------------------------

## Club picker for a watched (non-career) match. `home` null = pick home, else pick away.
func _show_match_pick(league: Dictionary, home: Variant) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	var clubs: Array = []
	for c in cl:
		if home != null and int(c["id"]) == int((home as Dictionary)["id"]):
			continue   # can't play yourself
		rows.append({"text": c["name"]})
		clubs.append(c)
	if home == null:
		_mount_browse(league["name"], "Pick the HOME side", rows,
			func(i: int) -> void: _show_match_pick(league, clubs[i]),
			func() -> void: _show_db_league(league))
	else:
		_mount_browse("%s  v  ?" % str((home as Dictionary).get("name", "?")), "Pick the AWAY side", rows,
			func(i: int) -> void: _play_watch_match(home, clubs[i], league),
			func() -> void: _show_match_pick(league, null))

func _play_watch_match(home: Dictionary, away: Dictionary, league: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var m := MatchCommentary.timeline(rng, home, away)
	_open_match(home, away, int(m["home_goals"]), int(m["away_goals"]), m["lines"],
		"Full time", func() -> void: _show_match_pick(league, null))


# ---- career mode ---------------------------------------------------------

## New-career division picker (B2): original-art select list. Back -> the database root.
func _show_career_pick_league() -> void:
	var rows: Array = []
	var leagues: Array = []
	for lg in GameDB.leagues:
		rows.append({"text": lg["name"], "value": "%d clubs" % (lg["clubIds"] as Array).size()})
		leagues.append(lg)
	_mount_browse("NEW CAREER", "Choose a division to manage in", rows,
		func(i: int) -> void: _show_career_pick_club(leagues[i]),
		func() -> void: _show_home())

## New-career club picker (B2): original-art select list. Back -> the division picker.
func _show_career_pick_club(league: Dictionary) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	for c in cl:
		rows.append({"text": c["name"], "value": "%d" % (c.get("players", []) as Array).size()})
	_mount_browse(str(league["name"]).to_upper(), "Choose the club to take over", rows,
		func(i: int) -> void: _begin_career(league, cl[i]),
		func() -> void: _show_career_pick_league())

func _begin_career(league: Dictionary, club: Dictionary) -> void:
	var league_clubs := GameDB.clubs_in_league(league["id"])
	_career = Career.create(club, league, league_clubs, GameDB.leagues)
	_career.save()
	_enter_career()

## Enter the career: drop the front-of-house browse/title overlays, reset nav so the hub
## sits one level under Home (Back from a green sub-flow -> hub), and raise the hub.
func _enter_career() -> void:
	_clear_front_overlays()
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

## The management hub IS the original-art MENUPRINCIPAL (B1): a persistent overlay raised
## once on entering the career and re-shown whenever nav returns here, instead of the old
## green data-browser list. Mount-or-refresh: re-reads _career each call so the centre
## panel (club / cash / position) updates after a match or signing.
func _show_career() -> void:
	if _nav.is_empty():
		_nav.append(_show_home)
	_mount_hub()

## Create the persistent MENUPRINCIPAL hub on first entry (wiring its taps to _menu_action
## once), or raise + refresh the existing one. Kept on top of $Root so the green sub-flows
## hide cleanly behind it (see _set_view) and art overlays mount above it.
func _mount_hub() -> void:
	var c := _career
	if _hub == null or not is_instance_valid(_hub):
		_hub = load("res://scenes/MenuScreen.gd").new()
		_hub.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_hub)
		_hub.action_selected.connect(_menu_action.bind(_hub))
	else:
		move_child(_hub, get_child_count() - 1)
	_hub.visible = true
	_hub.setup(c.club_name, c.league_name, c.season, c.cash,
		"%d%s" % [c.position(), _ord_suffix(c.position())])

## Leave the career back to the database/home browser (MENUPRINCIPAL EXIT). Saves first,
## frees the hub, clears the active career.
func _leave_career() -> void:
	if _career != null:
		_career.save()
	if _hub != null and is_instance_valid(_hub):
		_hub.queue_free()
	_hub = null
	_career = null
	_nav = [_show_home]
	_show_home()

func _career_advance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res := _career.advance_week(rng)   # ratings come from the live roster
	_career.save()   # autosave each week
	if res.is_empty():
		_show_career()   # bye / season just ended; refresh the hub in place
		return
	_show_match_result(res)

## The manager's match as a PM98-chrome read-out (B4): RETURN refreshes + raises the hub.
func _show_match_result(res: Dictionary) -> void:
	var home := GameDB.club(int(res["home_id"]))
	var away := GameDB.club(int(res["away_id"]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Narrate the EXACT stored scoreline so feed and table agree.
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]))
	var verdict := _result_word(int(res["hg"]), int(res["ag"]), bool(res["manager_home"]))
	_open_match(home, away, int(res["hg"]), int(res["ag"]), m["lines"],
		"%s  -  back to the dugout" % verdict, func() -> void: _show_career())

## The original-art TITLE / FRONT-DOOR screen as a full-screen overlay raised at boot:
## the PREMIER MANAGER 98 title (FONDO7) with DATA BASE / MANAGER LEAGUE /
## PRO-MANAGER LEAGUE + EXIT at the coordinates reversed from MANAGER.EXE
## (FUN_00545180; docs/re/title_screen_re.md). Taps route the front-door choice.
func _show_title_screen() -> void:
	var scr: TitleScreen = load("res://scenes/TitleScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.action_selected.connect(_title_action.bind(scr))

## Route a front-door tap: EXIT quits; DATA BASE drops to the home/database browser
## beneath; either league mode starts a new career (the pro/league split isn't modelled
## in this build, so both enter the same new-career flow).
func _title_action(action: String, scr: TitleScreen) -> void:
	match action:
		"exit":
			get_tree().quit()
		"database":
			scr.queue_free()        # reveal the home browse mounted beneath
			if _browse == null or not is_instance_valid(_browse):
				_show_home()
		_:
			scr.queue_free()
			_show_career_pick_league()

## The original-art LEAGUE TABLES screen over the hub, driven by the live career
## standings. Tap to dismiss. (See scenes/LeagueTableScreen.gd for asset provenance.)
func _show_league_table_screen() -> void:
	_open_table(_career.standings(), _career.club_name, _career.season,
		"Week %d" % mini(_career.week + 1, _career.total_weeks()),
		_career.tier, _career.club_id)

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

## The original-art SQUAD MANAGEMENT (PLANTILLA) screen for the managed club. Tap to
## dismiss. (docs/re/squad_screen_re.md; the database browse reuses _open_squad too.)
func _show_squad_screen() -> void:
	_open_squad(_mgr_club(), "", "£%s" % _fmt_int(_career.cash))

## The original-art FINANCES ("INCOME + EXPENSES") screen for the managed club. Tap to
## dismiss. (docs/re/finance_screen_re.md, driven by FinanceModel.)
func _show_finance_screen() -> void:
	_open_finance(_mgr_club(), _career.club_name, _career.season)

## The original-art TRANSFER MARKET (FICHAR) screen as a full-screen overlay: the
## buyable players (dearest first) in the reversed list panel + the right-hand nav
## column, at the coordinates reversed from MANAGER.EXE (docs/re/transfer_screen_re.md).
## Display-only (bid via the text menu); tap to dismiss.
func _show_transfer_screen() -> void:
	var c := _career
	var win := "OPEN" if c.transfers_open() else "CLOSED"
	var scr: TransferScreen = load("res://scenes/TransferScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(c.market(), c.club_name, "", c.season, c.cash, win, c.offers_left)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## The original-art BOARD OF DIRECTORS (DIRECTIVA) screen as a full-screen overlay:
## the three confidence/rating meters + the board's objective + your record, at the
## coordinates reversed from MANAGER.EXE (docs/re/directiva_screen_re.md). The meter
## values are derived from real career state (position vs board objective + form) —
## the Career model has no stored confidence stat. Display-only; tap to dismiss.
func _show_directiva_screen() -> void:
	var c := _career
	var bp := _board_panel()
	var scr: DirectivaScreen = load("res://scenes/DirectivaScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(c.club_name, "", c.season, c.cash, bp["directors"], bp["supporters"],
		bp["rating"], c.objective_text, bp["record"], bp["position"])
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## Derive the board view from real career state: directors confidence tracks the
## league position against the board objective; supporters confidence blends recent
## form with standing; manager rating is the position percentile blended with form.
## All clamped 0..100 and damped toward 50 before ~8 games are played. Also returns
## the cumulative W-D-L record and ordinal position string.
func _board_panel() -> Dictionary:
	var standings := _career.standings()
	var total := maxi(1, standings.size())
	var pos := _career.position()
	var obj := _career.objective_pos
	var played: int = (_career.results as Array).size()

	var w := 0
	var d := 0
	var l := 0
	for r in _career.results:
		var mine: int = int(r["hg"]) if bool(r["home"]) else int(r["ag"])
		var theirs: int = int(r["ag"]) if bool(r["home"]) else int(r["hg"])
		if mine > theirs:
			w += 1
		elif mine == theirs:
			d += 1
		else:
			l += 1

	var n := mini(5, played)
	var form_pts := 0
	for i in range(played - n, played):
		var r: Dictionary = _career.results[i]
		var mine: int = int(r["hg"]) if bool(r["home"]) else int(r["ag"])
		var theirs: int = int(r["ag"]) if bool(r["home"]) else int(r["hg"])
		form_pts += 3 if mine > theirs else (1 if mine == theirs else 0)
	var form := (float(form_pts) / 15.0) if n > 0 else 0.5
	var pct := float(total - pos) / float(maxi(1, total - 1))

	var directors := 55.0 + float(obj - pos) * 6.0
	var supporters := 30.0 + form * 55.0 + pct * 15.0
	var rating := pct * 70.0 + form * 30.0
	var weight := clampf(float(played) / 8.0, 0.0, 1.0)
	directors = lerp(50.0, directors, weight)
	supporters = lerp(50.0, supporters, weight)
	rating = lerp(50.0, rating, weight)

	return {
		"directors": clampi(int(round(directors)), 0, 100),
		"supporters": clampi(int(round(supporters)), 0, 100),
		"rating": clampi(int(round(rating)), 0, 100),
		"record": "%d-%d-%d" % [w, d, l],
		"position": "%d%s" % [pos, _ord_suffix(pos)],
	}

## The original-art GROUND (ESTADIO) overview screen as a full-screen overlay: the
## pre-rendered stadium scene for the club's capacity tier + the reversed info panel
## and 2x2 IMPROVE/WORKS/MATCH DAY/RETURN grid, at the coordinates reversed from
## MANAGER.EXE (docs/re/stadium_screen_re.md). The tier is the reversed capacity
## formula (clamp(capacity*11/130000, 0, 11)) on the SAME capacity the finance screen
## uses. GameDB stores only total capacity, so the seated/standing/parking split is
## display-derived (flagged in the RE doc). Display-only; tap to dismiss.
func _show_stadium_screen() -> void:
	var club := _mgr_club()
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var cap: int = int(sm["capacity"])
	var ground_v: Variant = club.get("stadium")
	var ground: String = ground_v if ground_v is String else ""
	# Display split of the single stored total: ~62% seated, rest terraces, parking ~1/27.
	var seated := int(round(cap * 0.62))
	var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_career.club_name, "", _career.season, ground,
		cap, seated, cap - seated, int(round(cap / 27.0)))
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## Route a MENUPRINCIPAL icon/button tap from the persistent hub. The hub stays mounted:
## art overlays (table/line-up/finance/board/stadium/buy) mount ABOVE it and tap-dismiss
## back to it; still-green sub-flows (tactics/sell/results) are pushed and hide the hub
## via _set_view (re-shown on Back); info actions toast on the hub itself; CONTINUE plays
## the week (or opens end-of-season when the campaign is over); EXIT leaves the career.
func _menu_action(action: String, scr: MenuScreen) -> void:
	match action:
		"exit": _leave_career()
		"save":
			_career.save()
			scr.toast("Game saved")
		"news": scr.toast("No news this week")
		"staff": scr.toast("Staff management is not in this build yet")
		"opponent", "fixtures": scr.toast(_menu_next_match())
		"continue":
			if _career.season_over():
				_push(_show_end_of_season)
			else:
				_career_advance()
		"table": _show_league_table_screen()
		"lineup": _show_lineup_screen()
		"finance": _show_finance_screen()
		"board": _show_directiva_screen()
		"stadium": _show_stadium_screen()
		"buy": _show_transfer_screen()
		"tactics": _push(_show_tactics)
		"sell": _push(_show_transfers)
		"results": _show_results_screen()

## "vs Arsenal" / "at Chelsea" / "bye" for the manager's next match.
func _menu_next_match() -> String:
	var fx := _career.manager_fixture()
	if fx.is_empty():
		return "No match this week (bye)"
	var home: bool = int(fx[0]) == _career.club_id
	var opp_id: int = int(fx[1]) if home else int(fx[0])
	var opp := GameDB.club(opp_id)
	return "Next: %s %s" % ["vs" if home else "at", opp.get("name", "?")]

## The MENUPRINCIPAL RESULTS view (B-track): the manager's match history this season as
## a PM98-chrome browse over the hub (win green / draw white / loss red). RETURN -> hub.
func _show_results_screen() -> void:
	var rows: Array = []
	var res: Array = _career.results
	if res.is_empty():
		rows.append({"text": "No matches played yet", "enabled": false})
	for r in res:
		var opp: String = str(GameDB.club(int(r["opp_id"])).get("name", "?"))
		var mine: int = int(r["hg"]) if bool(r["home"]) else int(r["ag"])
		var theirs: int = int(r["ag"]) if bool(r["home"]) else int(r["hg"])
		var wdl := "W" if mine > theirs else ("D" if mine == theirs else "L")
		var acc := Color(0.27, 1.0, 0.53) if wdl == "W" else (
			Color(0.86, 0.90, 0.96) if wdl == "D" else Color(0.85, 0.45, 0.42))
		rows.append({
			"text": "Wk %2d   %s %s   %d - %d" % [
				int(r["week"]), "v" if bool(r["home"]) else "@", opp, mine, theirs],
			"value": wdl, "accent": acc, "enabled": false,
		})
	_mount_browse("%s  -  RESULTS" % _career.club_name, "Season %s" % _career.season, rows,
		func(_i: int) -> void: pass,
		func() -> void: _dismiss_career_browse())

## Dismiss a browse overlay shown from the hub (results) and re-raise the hub beneath it.
func _dismiss_career_browse() -> void:
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
	_browse = null
	_show_career()

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
	rows.append("VIEW TRANSFER MARKET   (the screen)"); payload.append({"t": "screen"})
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
		"screen": _show_transfer_screen()
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
