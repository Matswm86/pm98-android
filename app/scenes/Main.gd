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

# Spanish attribute codes -> the labels the original's own PLAYER INFORMATION card
# prints (Cole, frame p0056; see Training._NAMES for the full ten-code proof). RM and RG
# were swapped here too, and "Pace" / "Ability" / "Goalkeeping" are not the game's words.
const ATTR_LABELS := {
	"VE": "Speed", "RE": "Stamina", "AG": "Aggression", "CA": "Quality",
	"RM": "Dribbling", "RG": "Heading", "PA": "Passing",
	"TI": "Shooting", "EN": "Tackling", "PO": "Handling",
}
const ATTR_ORDER := ["CA", "VE", "RE", "AG", "RM", "RG", "PA", "TI", "EN", "PO"]

var _nav: Array[Callable] = []          # view stack; top is re-invoked on Back
var _payload: Array = []                # parallel data for the current list rows
var _on_activate: Callable
var _career: Career = null              # active managed career, null on the menu
var _hub: MenuScreen = null             # persistent MENUPRINCIPAL hub while in a career
var _browse: BrowseScreen = null        # active PM98-chrome browse/select overlay (Track B)
var _mgr_history: ManagerHistoryScreen = null   # active MANAGER HISTORY overlay (#14)
var _offers_screen: OffersSelectionScreen = null   # active OFFERS SELECTION overlay (#14)
var _seleccion: SeleccionScreen = null  # active new-career SELECCION overlay (faithful art)
var _database: DataBaseScreen = null    # active DATA BASE squad-view overlay (reversed dbasewin)
var _nivel: NivelScreen = null          # SELECT LEVEL OF THE GAME dialog (over the title)
var _preseason: PreseasonScreen = null  # "Preseason for <club>" screen
var _pending_level := "manager"         # NIVEL pick carried through the entry flow
var _pending_age := false               # "Players age ?" checkbox
var _club_tactics_db = null             # club_tactics.json clubs (lazy; roll CPU XI)
var _country_en_es: Dictionary = {}     # PAISES English name -> [Spanish DB names]

@onready var _title: Label = $Root/TopBar/Title
@onready var _subtitle: Label = $Root/TopBar/Subtitle
@onready var _back: Button = $Root/TopBar/Back
@onready var _list: ItemList = $Root/List
@onready var _footer: Label = $Root/Footer


func _ready() -> void:
	# Pixel-exact art: NEAREST like every other screen (the hub inherited Godot's
	# Linear default and blurred kits/crests -- owner #4). Project default now 0 too.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
			and not OS.has_environment("PM98_HUB_SHOT") and not OS.has_environment("PM98_BROWSE_SHOT") \
			and not OS.has_environment("PM98_MATCH_SHOT") and not OS.has_environment("PM98_NEWS_SHOT") \
			and not OS.has_environment("PM98_CUP_SHOT") \
			and not OS.has_environment("PM98_YOUTH_SHOT") and not OS.has_environment("PM98_STAFF_SHOT") \
			and not OS.has_environment("PM98_CONTRACT_SHOT") and not OS.has_environment("PM98_SCREENS_SHOT") \
			and not OS.has_environment("PM98_MANAGER_SHOT") and not OS.has_environment("PM98_FICHA_SHOT") \
			and not OS.has_environment("PM98_MATCHOPTS_SHOT") and not OS.has_environment("PM98_PLAYERACT_SHOT") \
			and not OS.has_environment("PM98_CUPDRAW_SHOT") \
			and not OS.has_environment("PM98_GROUNDACT_SHOT"):
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
	if OS.has_environment("PM98_MATCH_SHOT"):
		_match_shot()
		return
	if OS.has_environment("PM98_NEWS_SHOT"):
		_news_shot()
		return
	if OS.has_environment("PM98_CONTRACT_SHOT"):
		_contract_shot()
		return
	if OS.has_environment("PM98_CUP_SHOT"):
		_cup_shot()
		return
	if OS.has_environment("PM98_YOUTH_SHOT"):
		_youth_shot()
		return
	if OS.has_environment("PM98_STAFF_SHOT"):
		_staff_shot()
		return
	if OS.has_environment("PM98_SCREENS_SHOT"):
		_screens_shot()
		return
	if OS.has_environment("PM98_MANAGER_SHOT"):
		_manager_shot()
		return
	if OS.has_environment("PM98_FICHA_SHOT"):
		_ficha_shot()
		return
	if OS.has_environment("PM98_PLAYERACT_SHOT"):
		_playeract_shot()
		return
	if OS.has_environment("PM98_GROUNDACT_SHOT"):
		_groundact_shot()
		return
	if OS.has_environment("PM98_CUPDRAW_SHOT"):
		_cupdraw_shot()
		return
	if OS.has_environment("PM98_MATCHOPTS_SHOT"):
		_matchopts_shot()
		return
	if OS.has_environment("PM98_OPTIONS_SHOT"):
		_options_shot()
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
	_begin_career("Manager", lg, clubs[0])
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


## Faithful real-render of the MATCH OPTIONS dropdown dialog and ALL FOUR tabs, driven
## through the REAL wiring: begin a career -> mount the hub -> route the monitor-icon
## action (_menu_action "match_options" -> _show_match_options) -> then TAP the tab row
## and a couple of controls through MatchOptions' real gui handler, capturing each tab.
## Proves the settings dialog switches tabs + draws its live state in the real app scene
## tree (not just an isolated shot). Run as the NORMAL app under Xvfb+GL: PM98_MATCHOPTS_SHOT=1.
func _matchopts_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("MATCHOPTS-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	await _settle()
	# the monitor icon on the hub's top dropdown routes here (Main._menu_action):
	_menu_action("match_options", _hub)
	await _settle()
	var opt: MatchOptions = null
	for c in get_children():
		if c is MatchOptions:
			opt = c
	if opt == null:
		print("MATCHOPTS-SHOT dialog did not mount")
		get_tree().quit()
		return
	# [tab-row button centre, tab name, extra control taps to show live state]
	var tabs := [
		[Vector2(164, 321), "match", []],
		[Vector2(268, 321), "graphics", [Vector2(213, 200), Vector2(488, 237)]],  # SKY off, PITCH MIN
		[Vector2(373, 321), "cameras", [Vector2(145, 280)]],                       # AUTO
		[Vector2(476, 321), "sound", [Vector2(321, 291)]],                         # AMBIENT off
	]
	for t in tabs:
		_matchopts_tap(opt, t[0])                    # switch tab through the real handler
		for extra in (t[2] as Array):
			_matchopts_tap(opt, extra)
		await _settle()
		_save_shot(dir, "matchopts_%s.png" % t[1])
	print("MATCHOPTS-SHOT done tab=%d controls=%s" % [opt._tab, str(opt._s)])
	get_tree().quit()


## Faithful real-render of the audio OPTIONS panel through the REAL route (the hub
## dropdown's headphones icon -> _menu_action "options_audio" -> _show_audio_options),
## captured in BOTH states of the one row this port adds to it: THREE UP FRONT off, then
## on after a real tap on its ON box. The row is the port's single declared deviation
## from a 0-px modal (docs/re/hack_three_forwards.md), so it gets looked at, not assumed.
## Run as the NORMAL app under Xvfb+GL: PM98_OPTIONS_SHOT=1.
func _options_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("OPTIONS-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	await _settle()
	_menu_action("options_audio", _hub)
	await _settle()
	var op: OptionsPanel = null
	for c in get_children():
		if c is OptionsPanel:
			op = c
	if op == null:
		print("OPTIONS-SHOT panel did not mount")
		get_tree().quit()
		return
	var was: bool = AudioManager.cheat_three_up_front
	AudioManager.set_three_up_front(false)
	op.queue_redraw()
	await _settle()
	_save_shot(dir, "options_cheat_off.png")
	# tap the ON box through the panel's own gui handler, not by setting the flag
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = OptionsPanel.R_CHEAT_ON.get_center()
		e.pressed = pressed
		op._on_input(e)
	await _settle()
	_save_shot(dir, "options_cheat_on.png")
	print("OPTIONS-SHOT done cheat=%s engine=%s" % [
		str(AudioManager.cheat_three_up_front), str(Pm98StatMatch.cheat_three_up_front)])
	AudioManager.set_three_up_front(was, true)
	get_tree().quit()


## Inject a real press+release touch at a design-space point into the dialog's gui handler.
func _matchopts_tap(opt: MatchOptions, p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		opt._on_input(e)


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
	_show_career_select()
	await _settle()
	_save_shot(dir, "seleccion.png")
	var lg: Dictionary = GameDB.leagues[0]
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


## Faithful real-render of A1 — the 2D MATCH VIEW. Builds a real fixture timeline,
## mounts the live MatchScreen, and captures it at kick-off, a goal minute, and late on,
## so the PNGs prove the DATSIM sprite pitch renders in the engine (not just the PIL
## mirror — the grey-screen incident lesson). Run as the NORMAL app under Xvfb+GL:
## PM98_MATCH_SHOT=1.
func _match_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("MATCH-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var cl := GameDB.clubs_in_league(lg["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	if cl.size() < 2:
		print("MATCH-SHOT need two clubs")
		get_tree().quit()
		return
	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# the results / commentary screen shows each club's shirt escudo; any two clubs work.
	var home: Dictionary = cl[0]
	var away: Dictionary = cl[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242        # fixed seed -> reproducible capture
	var m := MatchCommentary.timeline(rng, home, away)
	scr.setup(str(home.get("name", "?")), str(away.get("name", "?")),
		int(m["home_goals"]), int(m["away_goals"]), m["lines"],
		int(home.get("id", -1)), int(away.get("id", -1)), m.get("possession", []))
	scr.set_process(false)   # freeze the clock so seek() controls the captured minute
	# pick a goal minute if any, else mid-match
	var goal_min := 35
	for ln in m["lines"]:
		if ln.get("goal") == true:
			goal_min = int(ln["minute"])
			break
	for shot in [["match_kickoff.png", 2.0], ["match_goal.png", float(goal_min)], ["match_late.png", 82.0]]:
		scr.seek(shot[1])
		await _settle()
		_save_shot(dir, shot[0])
	print("MATCH-SHOT done %s v %s %d:%d goal@%d" % [str(home.get("name", "?")),
		str(away.get("name", "?")), int(m["home_goals"]), int(m["away_goals"]), goal_min])
	get_tree().quit()


## Faithful real-render of the injuries/suspensions + NEWS feature. Begins a career,
## plays a few weeks so results + any knocks accrue, then guarantees one visible injury
## and one suspension so the SQUAD capture shows the INJ/SUS markers, and captures the
## CLUB NEWS browse. Proves the feature renders in-engine (the grey-screen lesson). Run
## as the NORMAL app under Xvfb+GL: PM98_NEWS_SHOT=1.
func _news_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("NEWS-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 909090            # fixed seed -> reproducible capture
	for _i in 6:
		if _career.season_over():
			break
		_career.advance_week(rng)
	# Guarantee a visible injury + suspension in the squad capture (random rolls may
	# not have hit in only a few weeks).
	var sq: Array = _career.my_squad()
	if sq.size() >= 2:
		sq[0]["injured_weeks"] = 3
		sq[1]["suspended_weeks"] = 1
		_career._news("injury", "%s injured in training -- out for 3 matches." % sq[0].get("name", "?"))
		_career._news("suspension", "%s suspended for the next match." % sq[1].get("name", "?"))
	_show_career()               # raise the hub
	await _settle()
	_open_squad(_mgr_club(), "", "£%s" % _fmt_int(_career.cash), false,
		_career.season, _career.week + 1)
	await _settle()
	_save_shot(dir, "squad_injuries.png")
	for c in get_children():
		if c is SquadScreen:
			c.queue_free()
	await _settle()
	_show_club_news()
	await _settle()
	_save_shot(dir, "news.png")
	print("NEWS-SHOT done news=%d club=%s" % [(_career.news_log as Array).size(), _career.club_name])
	get_tree().quit()


## Faithful real-render of the RENEW negotiation. Begins a career, finds a player on a
## final-year (EXPIRING) deal -- the seed squad's veterans start on one-year contracts -- and
## mounts his renewal screen over the hub so the capture shows his current wage, his demand
## and the hold/meet/better offers. Run as the NORMAL app under Xvfb+GL: PM98_CONTRACT_SHOT=1.
func _contract_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("CONTRACT-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	# Pick an expiring player; guarantee one for the capture if the squad has none.
	var target: Dictionary = {}
	for p in _career.my_squad():
		if Contract.is_expiring(p):
			target = p
			break
	if target.is_empty() and not _career.my_squad().is_empty():
		target = _career.my_squad()[0]
		target["contract_years"] = Contract.EXPIRING_YEARS
	_show_career()               # raise the hub
	await _settle()
	# Drive the REAL contract path (not the retired _show_renew stand-in): mount the
	# source FICHA (PlayerInfoScreen) for the target, then fire its RENEW signal so the
	# real _open_renew_negotiation overlay renders -- the surface the shot must capture.
	var club := _mgr_club()
	_open_player_info(target, club)
	await _settle()
	for c in get_children():
		if c is PlayerInfoScreen:
			(c as PlayerInfoScreen).renew_requested.emit(target)
			break
	await _settle()
	_save_shot(dir, "contract.png")
	print("CONTRACT-SHOT done squad=%d wagebill/wk=%d demand/wk=%d club=%s" % [
		_career.my_squad().size(), _career.player_weekly_wage(),
		Contract.demanded_weekly(target, _career.my_band()), _career.club_name])
	get_tree().quit()


## Faithful real-render of the YOUTH TEAM screen. Begins a career (seeds the academy),
## develops the youth a season's worth so a youngster reaches first-team grade, guarantees
## at least one READY prospect for the capture, then mounts the youth screen over the hub.
## Run as the NORMAL app under Xvfb+GL: PM98_YOUTH_SHOT=1.
func _youth_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("YOUTH-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	# Develop the academy a season's worth so the crop separates into ready / developing.
	var rng := RandomNumberGenerator.new()
	rng.seed = 717171
	for _w in 46:
		Youth.develop_week(rng, _career.youth)
	# Guarantee a visible READY prospect for the capture (random ceilings may not hit it).
	if _career.promotable_youth().is_empty() and not _career.youth.is_empty():
		var top: Dictionary = _career.youth[0]
		(top["attrs"] as Dictionary)["CA"] = Youth.READY_CA + 3
		top["ready"] = true
	_show_career()               # raise the hub beneath the overlay
	await _settle()
	_show_youth_screen()
	await _settle()
	_save_shot(dir, "youth.png")
	print("YOUTH-SHOT done youth=%d ready=%d club=%s" % [
		(_career.youth as Array).size(), _career.promotable_youth().size(), _career.club_name])
	get_tree().quit()


## Faithful real-render of the STAFF (EMPLE) screen. Begins a career (seeds the hire pool),
## hires a few staff so the CURRENT STAFF section + the wage/effect readouts are populated,
## then mounts the staff screen over the hub. Run as the NORMAL app under Xvfb+GL:
## PM98_STAFF_SHOT=1.
func _staff_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("STAFF-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	# Hire one of each role from the pool so the screen shows a real backroom team + effects.
	var seen: Dictionary = {}
	for cand in (_career.staff_pool as Array).duplicate():
		var role: String = str(cand.get("role", ""))
		if not seen.has(role):
			seen[role] = true
			_career.hire_staff(int(cand.get("id", -1)))
	_show_career()               # raise the hub beneath the overlay
	await _settle()
	_show_staff_screen()
	await _settle()
	_save_shot(dir, "staff.png")
	print("STAFF-SHOT done hired=%d pool=%d wage/wk=%d club=%s" % [
		(_career.staff as Array).size(), (_career.staff_pool as Array).size(),
		_career.staff_weekly_wage(), _career.club_name])
	get_tree().quit()


## Faithful real-render of the cup screens (F.A. Cup + Coca-Cola Cup). Begins a career
## and plays into the season so several rounds of both cups have been drawn and played,
## then captures each CUP screen (the manager's run + the latest draw, around the trophy
## art). Run as the NORMAL app under Xvfb+GL: PM98_CUP_SHOT=1.
func _cup_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("CUP-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	# Manage the strongest club in the division: most likely to win the league and so
	# play in the European Cup, giving the European capture a real manager's run.
	clubs.sort_custom(func(a, b):
		var ra := MatchEngine.team_ratings(a)
		var rb := MatchEngine.team_ratings(b)
		return (ra["att"] + ra["def"] + ra["gk"]) > (rb["att"] + rb["def"] + rb["gk"]))
	_begin_career("Manager", lg, clubs[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 717171            # fixed seed -> reproducible capture
	# First stop early, while the F.A. Cup is still a big round: that is the KNOCKOUT LIST
	# view (docs/re/knockout_views_re.md), the one the SORTEO card used to stand in for.
	for _e in 10:
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()
	await _settle()
	_show_cup_screen(_career.fa_cup, "fa_cup", "F.A. Cup")
	await _settle()
	_save_shot(dir, "cup_knockout_list.png")
	for c in get_children():
		if c is KnockoutScreen or c is CupDrawScreen:
			c.queue_free()
	await _settle()
	for _i in 12:                # past several scheduled rounds of both cups
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()               # raise the hub
	await _settle()
	_show_cup_screen(_career.fa_cup, "fa_cup", "F.A. Cup")
	await _settle()
	_save_shot(dir, "cup.png")
	for c in get_children():
		if c is CupDrawScreen:
			c.queue_free()
	await _settle()
	_show_cup_screen(_career.league_cup, "league_cup", "Coca-Cola Cup")
	await _settle()
	_save_shot(dir, "league_cup.png")
	var b: Dictionary = _career.fa_cup
	var lc: Dictionary = _career.league_cup
	# Finish the season and roll over so the Charity Shield (champions v F.A. Cup winners)
	# is contested, then capture it around the real CHARITY shield art.
	for c in get_children():
		if c is CupDrawScreen:
			c.queue_free()
	while not _career.season_over():
		_career.advance_week(rng)
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion())
	_show_charity_shield()
	await _settle()
	_save_shot(dir, "charity_shield.png")
	var cs: Dictionary = _career.charity_shield
	# Into the new season far enough for European rounds to have been drawn + played,
	# then capture the European Cup screen around its real trophy art.
	for c in get_children():
		if c is CupDrawScreen:
			c.queue_free()
	# First, partway in: the European Cup group stage in flight (a few matchdays played).
	for _g in 13:
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()
	await _settle()
	var ecg: Dictionary = _career.euro.get("european_cup", {})
	_show_cup_screen(ecg, "european_cup", "European Cup")
	await _settle()
	_save_shot(dir, "european_cup_group.png")
	for c in get_children():
		if c is CupDrawScreen:
			c.queue_free()
	# Then deeper, into the knockout rounds.
	for _j in 18:
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()
	await _settle()
	# Showcase the European competition the manager actually qualified for (a real run,
	# even if knocked out, reads better than a not-qualified comp). By qualification:
	# champions -> European Cup, runners-up -> UEFA Cup, F.A. Cup winners -> Cup Winners'.
	var show_key := "european_cup"
	var mid: int = _career.club_id
	if _career.last_champion_id == mid:
		show_key = "european_cup"
	elif _career.last_runners_up.slice(0, Career.UEFA_SPOTS).has(mid):
		show_key = "uefa_cup"
	elif _career._cwc_seed() == mid:
		show_key = "cup_winners_cup"
	var ec: Dictionary = _career.euro.get(show_key, {})
	_show_cup_screen(ec, show_key, str(ec.get("name", "European Cup")))
	await _settle()
	_save_shot(dir, "european_cup.png")
	# Finish this European season and roll over once more so the winners-of-winners finals
	# (European Supercup + Intercontinental Cup) are contested, then capture the Supercup.
	for c in get_children():
		if c is CupDrawScreen:
			c.queue_free()
	while not _career.season_over():
		_career.advance_week(rng)
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion())
	_show_euro_supercup()
	await _settle()
	_save_shot(dir, "european_supercup.png")
	print("CUP-SHOT done facup_rounds=%d champ=%d | lcup_rounds=%d champ=%d | charity winner=%d | euro_comps=%d show=%s ec_rounds=%d | supercup=%d intercont=%d club=%s" % [
		(b.get("rounds", []) as Array).size(), int(b.get("champion_id", -1)),
		(lc.get("rounds", []) as Array).size(), int(lc.get("champion_id", -1)),
		int(cs.get("winner_id", -1)), _career.euro.size(), show_key,
		(ec.get("rounds", []) as Array).size(),
		int(_career.supercup.get("winner_id", -1)), int(_career.intercontinental.get("winner_id", -1)),
		_career.club_name])
	get_tree().quit()


## Faithful real-render of the reconstructed art overlays (league table / line-up / squad
## / finances / transfer / board / stadium) as REAL in-engine captures, so the README no
## longer leans on the PIL preview mirrors for these. Begins a career, plays a few weeks
## for live data, then mounts each overlay over the hub and captures it. Run as the NORMAL
## app under Xvfb+GL: PM98_SCREENS_SHOT=1.
func _screens_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("SCREENS-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 313131            # fixed seed -> reproducible captures
	for _i in 8:                 # a few weeks so the table + finances have data
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()               # raise the hub beneath the overlays
	await _settle()
	var shots := [
		["_show_league_table_screen", "league_table.png"],
		["_show_lineup_screen", "lineup.png"],
		["_show_squad_screen", "squad.png"],
		["_show_finance_screen", "finance.png"],
		["_show_transfer_screen", "transfer.png"],
		["_show_directiva_screen", "directiva.png"],
		["_show_stadium_screen", "stadium.png"],
		["_show_tactics_screen", "tactics.png"],   # TEAM TACTICS modal over the line-up (ma_9)
		["_show_market", "transfer_buy.png"],      # reskinned _set_view flow (T1 #3)
		["_show_club_news", "club_news.png"],      # T2 #12: rival injuries surface here
		["_show_injuries_screen", "injuries.png"], # the PRICE/INSUR./COST economy live
		["_show_insurance_screen", "insurance.png"],
	]
	for s in shots:
		call(s[0])
		await _settle()
		_save_shot(dir, s[1])
		_free_overlays()
		await _settle()
	# T2 #5: the in-screen IMPROVEMENTS picker, then the overview with an expansion running.
	_career.cash = 20_000_000
	_show_stadium_screen()
	for c in get_children():
		if c is StadiumScreen:
			c.open_improve()
	await _settle()
	_save_shot(dir, "stadium_works.png")
	_career.start_works(8000, 7_437_500, 35)   # real Man Utd SEATS offer (frame 173)
	_free_overlays()
	_show_stadium_screen()
	await _settle()
	_save_shot(dir, "stadium_inprogress.png")
	_free_overlays()
	# T2 #6: the board PRICES control.
	_show_finance_control()
	await _settle()
	_save_shot(dir, "prices.png")
	_free_overlays()
	# T2 #9: the FREE AGENTS list.
	_show_free_agents()
	await _settle()
	_save_shot(dir, "free_agents.png")
	_free_overlays()
	# T2 #13: the SEASON FIXTURES calendar.
	_show_calendar()
	await _settle()
	_save_shot(dir, "calendar.png")
	_free_overlays()
	# T2 #8: the LOAN MARKET.
	_show_loan_market()
	await _settle()
	_save_shot(dir, "loan_market.png")
	_free_overlays()
	# T2 #10: the SCOUT REPORT (hire a scout first so the report is available).
	for cand in (_career.staff_pool as Array).duplicate():
		if str(cand.get("role", "")) == Staff.SCOUT:
			_career.hire_staff(int(cand.get("id", -1)))
			break
	_career.cash = 50_000_000
	_show_scout_report()
	await _settle()
	_save_shot(dir, "scout_report.png")
	_free_overlays()
	print("SCREENS-SHOT done club=%s week=%d" % [_career.club_name, _career.week])
	get_tree().quit()

## Faithful real-render of the PLAYER INFORMATION (FICHA) popup. Picks a real Premier
## player WITH a BIGFOTO mugshot (Schmeichel, photoId 3371) so the capture proves the
## extracted face renders on a real screen, mounts his FICHA over the squad, and captures
## it. Run as the NORMAL app under Xvfb+GL: PM98_FICHA_SHOT=1.
func _ficha_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	# Find the club + player carrying the canonical verified face (Schmeichel 3371),
	# else any Premier player with a photo + decoded physicals.
	var club: Dictionary = {}
	var player: Dictionary = {}
	for c in GameDB.clubs:
		if c.get("leagueId") != "eng_prem":
			continue
		for p in c.get("players", []):
			if int(p.get("photoId", 0)) == 3371:
				club = c
				player = p
			if player.is_empty() and p.get("photoId") != null and p.get("heightCm") != null:
				club = c
				player = p
		if int(player.get("photoId", 0)) == 3371:
			break
	if player.is_empty():
		print("FICHA-SHOT no photo player found")
		get_tree().quit()
		return
	_open_squad(club, "", "")
	await _settle()
	_open_player_info(player, club)
	await _settle()
	_save_shot(dir, "player_info.png")
	print("FICHA-SHOT done %s %s photoId=%s %scm %skg %s" % [str(player.get("name")),
		str(club.get("name")), str(player.get("photoId")), str(player.get("heightCm")),
		str(player.get("weightKg")), str(player.get("nationality"))])
	get_tree().quit()


## RUNTIME REPRO of the owner's "nothing happens" report (2026-07-22 handoff): begin a
## real career, then drive the EXACT hub->PLAYERS->player->RENEW/TRANSFER path with
## SYNTHESIZED TOUCH INPUT pushed through the live Viewport (real hit-testing + overlay
## ordering, not a wiring shortcut), capturing each step and printing the Career-side
## mutation. Also drives the BUY path (transfer desk -> make offer -> place bid ->
## week-roll resolve). Run under Xvfb+GL: PM98_PLAYERACT_SHOT=1.
## Drives the REAL GROUND flow end-to-end (owner 2026-07-23): open GROUND -> IMPROVE -> CAR
## PARK tab -> tick a quadrant -> the work starts, the screen re-mounts on the WORK IN
## PROGRESS ledger showing it. Proves Main._on_stadium_works wiring, not just the render.
## Render-diff baseline for the SORTEO (cup-draw) screen. Mounts CupDrawScreen with the
## EXACT state of the binding frame `74_after_wk4.png` — Coca-Cola Cup, ROUND 2, the first
## four ties of a 25-tie round with the fourth's away club still undrawn — so
## tools/re/diff_cupdraw_parity.py can diff it against the real MANAGER.EXE frame pixel for
## pixel. The drum frame is pinned to BOMBO08, which is the one that frame holds.
## Run under Xvfb+GL: PM98_CUPDRAW_SHOT=1.
func _cupdraw_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	var scr: CupDrawScreen = load("res://scenes/CupDrawScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup("league_cup", "Coca-Cola Cup", "ROUND 2", [
		{"home": "Preston NE", "away": "Stockport C"},
		{"home": "Tranmere Rov", "away": "Crystal Pal."},
		{"home": "Northampton T.", "away": "Barnsley"},
		{"home": "Coventry", "away": ""},
	], 25, ["1ST LEG", "2ND LEG"])
	scr.set_process(false)
	scr.pin_drum(8)
	await _settle()
	_save_shot(dir, "cupdraw_74.png")
	# ...and the F.A. Cup frame `10_fa_cup_draw_round1.png`: different competition strip,
	# title, round, leg plates and a 40-tie scrollbar. Drum frame BOMBO07 there.
	scr.setup("fa_cup", "F.A. Cup", "ROUND 1", [
		{"home": "Stevenage B.", "away": "Kettering T."},
		{"home": "Colwyn B.", "away": "Fulham"},
		{"home": "Hayes", "away": "Stalybridge C."},
		{"home": "Hereford U.", "away": ""},
	], 40, ["MATCH", "REPLAY"])
	scr.pin_drum(7)
	await _settle()
	_save_shot(dir, "cupdraw_10.png")
	# ...and the GRID form (REFRUN R8), against the reference run's own two frames.
	# p0133: Coca-Cola Cup ROUND 3, all sixteen ties, the manager's own tie on row 1.
	scr.setup("league_cup", "Coca-Cola Cup", "ROUND 3", _CUPDRAW_R3_TIES, 16,
		["MATCH", "REPLAY"], _CUPDRAW_OWN_ID, "MWM")
	scr.pin_drum(0)
	await _settle()
	_save_shot(dir, "cupdraw_133.png")
	# p0747: a U.E.F.A. Cup 1/16 FINAL with the tie-detail card filled in.
	scr.setup("uefa_cup", "U.E.F.A. CUP", "1/16 FINAL", _CUPDRAW_UEFA_TIES, 16,
		["1ST LEG", "2ND LEG"], _CUPDRAW_OWN_ID, "MWM")
	scr.show_tie({
		"home": {"club": "F.C. Barcelona", "club_id": -1, "manager": "Van Gaal",
			"stadium": "Camp Nou"},
		"away": {"club": "Karlsruher", "club_id": -1, "manager": "Winfried Schafer",
			"stadium": "Wildpark"},
	}, 5)
	scr.pin_drum(0)
	await _settle()
	_save_shot(dir, "cupdraw_747.png")
	print("CUPDRAW-SHOT done")
	get_tree().quit()


## The reference run's own two grid draws, verbatim off p0133 and p0747. `home_id` /
## `away_id` only have to identify the MANAGER's club for the own-tie plate, so the
## sentinel below is used for it and every other club is left unidentified.
const _CUPDRAW_OWN_ID := 424242
const _CUPDRAW_R3_TIES := [
	{"home": "Aston Villa", "away": "Carlisle U."},
	{"home": "Bradford City", "away": "Manchester Utd.", "away_id": _CUPDRAW_OWN_ID},
	{"home": "Bolton W", "away": "Arsenal"},
	{"home": "Sheffield W.", "away": "Chelsea"},
	{"home": "Newcastle Utd", "away": "Bury"},
	{"home": "Wimbledon", "away": "Tranmere Rov"},
	{"home": "Liverpool", "away": "Peterborough"},
	{"home": "Manchester C", "away": "WBA"},
	{"home": "Stockport C", "away": "Sheffield Utd"},
	{"home": "Leicester", "away": "Ipswich"},
	{"home": "Charlton Ath", "away": "Blackburn R."},
	{"home": "Middlesbrough", "away": "Nottingham F."},
	{"home": "Grimsby T", "away": "Coventry"},
	{"home": "Wycombe W.", "away": "Sunderland"},
	{"home": "Tottenham H", "away": "Barnsley"},
	{"home": "West Ham Utd", "away": "Plymouth Arg."},
]
const _CUPDRAW_UEFA_TIES := [
	{"home": "Spartak Moscú", "away": "Croatia Zag."},
	{"home": "Helsingborgs", "away": "Panathinaikos"},
	{"home": "Olympiakos", "away": "B. Leverkusen"},
	{"home": "Schalke 04", "away": "Chelsea"},
	{"home": "Sampdoria", "away": "Vejle BK"},
	{"home": "F.C. Barcelona", "away": "Karlsruher"},
	{"home": "G. Ekeren", "away": "Manchester Utd.", "away_id": _CUPDRAW_OWN_ID},
	{"home": "Varzim", "away": "Borussia M."},
	{"home": "Tottenham H", "away": "D.Bucarest"},
	{"home": "C. At. Madrid", "away": "Sturm Graz"},
	{"home": "Lyon", "away": "R. Valladolid"},
	{"home": "Sl.Bratislava", "away": "Valletta"},
	{"home": "Blackburn R.", "away": "PAOK"},
	{"home": "De Graafschap", "away": "Ferencvaros"},
	{"home": "Viking", "away": "C.Salzburgo"},
	{"home": "Marítimo", "away": "Primorje"},
]


func _groundact_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("GROUNDACT-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var club: Dictionary = GameDB.clubs_in_league(lg["id"])[0]
	for c in GameDB.clubs_in_league(lg["id"]):
		if str(c.get("name", "")).to_upper().find("MANCHESTER UTD") >= 0:
			club = c
			break
	_begin_career("Manager", lg, club)
	_career.cash = 40_000_000
	await _settle()
	_show_stadium_screen()
	await _settle()
	_save_shot(dir, "ga_00_ground.png")
	var st: StadiumScreen = _first_of(StadiumScreen)
	if st == null:
		print("GROUNDACT FAIL: GROUND screen did not open")
		get_tree().quit()
		return
	_tap_screen(st, StadiumScreen.BTN_IMPROVE.get_center())
	_tap_screen(st, StadiumScreen.TAB_CARPARK.get_center())
	await _settle()
	print("GROUNDACT after IMPROVE+CARPARK: view=%s tab=%s" % [st._view, st._tab])
	_save_shot(dir, "ga_01_carpark.png")
	# Render-diff baselines for every improve sub-tab (seats/facilities/services).
	_tap_screen(st, StadiumScreen.TAB_SEATS.get_center())
	await _settle()
	_save_shot(dir, "ga_01a_seats.png")
	_tap_screen(st, StadiumScreen.TAB_FACILITIES.get_center())
	await _settle()
	_save_shot(dir, "ga_01b_facilities.png")
	# Previously-inert items now live with real data: select FLOODLIGHTS (0) + SCORE BOARD (3).
	_tap_screen(st, Vector2(145, 191))
	await _settle()
	_save_shot(dir, "ga_01b1_floodlights.png")
	# Two-tap: first tap on the next grade (1.500.000 K.W., row y408) previews its price (£500k).
	_tap_screen(st, Vector2(145, 408))
	await _settle()
	_save_shot(dir, "ga_01b1p_floodlights_preview.png")
	_tap_screen(st, Vector2(145, 245))
	await _settle()
	_save_shot(dir, "ga_01b2_scoreboard.png")
	_tap_screen(st, StadiumScreen.TAB_SERVICES.get_center())
	await _settle()
	_save_shot(dir, "ga_01c_services.png")
	_tap_screen(st, Vector2(145, 209))
	await _settle()
	_save_shot(dir, "ga_01c1_clubshop.png")
	_tap_screen(st, StadiumScreen.TAB_CARPARK.get_center())
	await _settle()
	var before := _career.works.size()
	_tap_screen(st, (StadiumScreen.QUAD_CELL[0] as Rect2).get_center())
	await _settle()
	var after := _career.works.size()
	print("GROUNDACT carpark tick: works %d -> %d  (%s)" % [before, after,
		"FIRED" if after > before else "DEAD -- tap did nothing"])
	print("GROUNDACT works_total = £%d (expect 2,975,000)" % _career.works_total())
	_save_shot(dir, "ga_02_after_buy_ledger.png")
	# Re-open CAR PARK to render-diff the works triangle (obras) in the building quadrant.
	st = _first_of(StadiumScreen)
	if st != null:
		_tap_screen(st, StadiumScreen.BTN_IMPROVE.get_center())
		_tap_screen(st, StadiumScreen.TAB_CARPARK.get_center())
		await _settle()
		_save_shot(dir, "ga_02b_carpark_building.png")

	# MATCH DAY (owner frame 06): the button was inert; now it opens the ticket-price / sponsor
	# -board sub-view. Drive it end-to-end: open it, step both prices, take the board offer.
	# The carpark tick re-mounted the GROUND screen, so re-acquire the live instance.
	st = _first_of(StadiumScreen)
	if st == null:
		print("GROUNDACT FAIL: GROUND screen gone after carpark tick")
		get_tree().quit()
		return
	_tap_screen(st, StadiumScreen.BTN_MATCHDAY.get_center())
	await _settle()
	print("GROUNDACT MATCH DAY: view=%s (expect matchday)" % st._view)
	_save_shot(dir, "ga_03_matchday.png")
	var tk0 := _career.ticket_price
	_tap_screen(st, StadiumScreen.MD_TICKET_UP.get_center())
	await _settle()
	print("GROUNDACT ticket step: %s -> %s (%s)" % [tk0, _career.ticket_price,
		"FIRED" if _career.ticket_price != tk0 else "DEAD"])
	var bd0 := _career.board_price
	_tap_screen(st, StadiumScreen.MD_BOARD_UP.get_center())
	await _settle()
	print("GROUNDACT board step: %d -> %d (%s)" % [bd0, _career.board_price,
		"FIRED" if _career.board_price != bd0 else "DEAD"])
	var cash0 := _career.cash
	_tap_screen(st, StadiumScreen.MD_ACCEPT.get_center())
	await _settle()
	print("GROUNDACT board sale: cash +£%d, sold=%s (expect +1,120,000 / true)" % [
		_career.cash - cash0, _career.boards_sold_season])
	_save_shot(dir, "ga_04_matchday_sold.png")
	print("GROUNDACT-SHOT done")
	get_tree().quit()


## Press+release a screen's own _on_input at a design point (the hit-test path used by
## test_wiring_pass) -- used by _groundact_shot where viewport push_input routing is flaky.
func _tap_screen(scr: Control, d: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = d
		e.pressed = pressed
		scr._on_input(e)


func _playeract_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("PLAYERACT-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	var club: Dictionary = clubs[0]
	for c in clubs:
		if str(c.get("name", "")).to_upper().find("MANCHESTER UTD") >= 0:
			club = c
			break
	_begin_career("Manager", lg, club)      # under PM98_SHOT_DIR this mounts the hub
	await _settle()
	_save_shot(dir, "pa_00_hub.png")
	print("PLAYERACT career_id=%d club=%s squad=%d" % [
		_career.club_id, str(club.get("name", "")), (_career.my_squad() as Array).size()])

	# --- OWNER STEP 1: hub PLAYERS button (action "sell") -> SQUAD MANAGEMENT ---
	_menu_action("sell", _hub)
	await _settle()
	_save_shot(dir, "pa_01_squad.png")
	var squad: SquadScreen = _first_of(SquadScreen)
	if squad == null:
		print("PLAYERACT FAIL: SQUAD screen did not open from hub PLAYERS")
		get_tree().quit()
		return
	print("PLAYERACT squad rows=%d youth_enabled=%s" % [(squad._rows as Array).size(), squad._youth_enabled])
	if (squad._rows as Array).is_empty():
		print("PLAYERACT FAIL: no player rows drawn")
		get_tree().quit()
		return

	# --- OWNER STEP 2: tap the first player row -> PLAYER INFORMATION card ---
	var row0: Dictionary = squad._rows[0]
	var pl: Dictionary = row0["p"]
	var pid := int(pl.get("id", -1))
	var r: Rect2 = row0["r"]
	await _synth_tap(squad, r.position + r.size * 0.5)
	await _settle()
	_save_shot(dir, "pa_02_playerinfo.png")
	var fi: PlayerInfoScreen = _first_of(PlayerInfoScreen)
	if fi == null:
		print("PLAYERACT FAIL: player row tap did NOT open PLAYER INFORMATION (pid=%d)" % pid)
		get_tree().quit()
		return
	print("PLAYERACT player='%s' pid=%d actions_enabled=%s (own path expects true)" % [
		str(pl.get("name", "?")), pid, fi._actions])

	# --- OWNER STEP 3: tap TRANSFER (deterministic: pure toggle, no RNG) ---
	var listed_before := _career.is_listed(pid)
	var tr: Rect2 = PlayerInfoScreen.BTN["transfer"]
	await _synth_tap(fi, tr.position + tr.size * 0.5)
	await _settle()
	_save_shot(dir, "pa_03_after_transfer.png")
	var listed_after := _career.is_listed(pid)
	print("PLAYERACT TRANSFER: listed %s -> %s  (%s)" % [
		listed_before, listed_after,
		"FIRED" if listed_before != listed_after else "DEAD -- tap did nothing"])

	# --- OWNER STEP 4: RENEW is now a negotiation -- tap RENEW opens the pick-an-offer overlay,
	# then a row pick applies the deal (original behaviour: hold/meet/better, may be rejected). ---
	fi = _first_of(PlayerInfoScreen)
	if fi != null:
		var yrs_before := int(pl.get("contract_years", 0))
		var wage_before := int(pl.get("wage", 0))
		var rn: Rect2 = PlayerInfoScreen.BTN["renew"]
		await _synth_tap(fi, rn.position + rn.size * 0.5)
		await _settle()
		var nego: BrowseScreen = _first_of(BrowseScreen)
		_save_shot(dir, "pa_04a_renew_negotiation.png")
		print("PLAYERACT RENEW negotiation opened: %s" % ("YES" if nego != null else "NO -- overlay did not mount"))
		if nego != null:
			# pick row index 1 ("meet his demand"): PANEL y0=50, ROW_H=26 -> y in [76,102).
			await _synth_tap(nego, Vector2(250, 89))
			await _settle()
		fi = _first_of(PlayerInfoScreen)
		_save_shot(dir, "pa_04_after_renew.png")
		var yrs_after := int(pl.get("contract_years", 0))
		var wage_after := int(pl.get("wage", 0))
		print("PLAYERACT RENEW: contract_years %d -> %d, wage %d -> %d  (%s)" % [
			yrs_before, yrs_after, wage_before, wage_after,
			"FIRED" if (yrs_before != yrs_after or wage_before != wage_after) else "DEAD"])

	# --- OWNER STEP 5: BUY path -- transfer desk -> make-offer card -> OFFER -> week roll ---
	_free_overlays()
	await _settle()
	_show_transfer_screen()
	await _settle()
	_save_shot(dir, "pa_05_transfer_desk.png")
	var market: Array = _career.market()
	if market.is_empty():
		print("PLAYERACT BUY: market empty")
	else:
		_career.cash = 500_000_000    # isolate the SURFACING test from the cash gate
		_show_make_offer_card(market[0])
		await _settle()
		_save_shot(dir, "pa_06_make_offer.png")
		var card: MakeOfferScreen = _first_of(MakeOfferScreen)
		if card == null:
			print("PLAYERACT BUY: make-offer card did not open")
		else:
			var news_b := (_career.news_log as Array).size()
			var alerts_b := (_career.pending_alerts as Array).size()
			var pend_b := (_career.pending_bids as Array).size()
			var ob: Rect2 = MakeOfferScreen.BTN["offer"]
			await _synth_tap(card, ob.position + ob.size * 0.5)
			await _settle()
			print("PLAYERACT BUY placed: pending_bids %d->%d (toast only, no resolution yet)" % [
				pend_b, (_career.pending_bids as Array).size()])
			var rng := RandomNumberGenerator.new()
			rng.seed = 424242
			_career.advance_week(rng)    # the club answers -- the "days later" reply
			var news_a := (_career.news_log as Array).size()
			var alerts_a := (_career.pending_alerts as Array).size()
			print("PLAYERACT BUY resolved: news %d->%d  HUB-ALERTS %d->%d  %s" % [
				news_b, news_a, alerts_b, alerts_a,
				"(SURFACED as hub alert)" if alerts_a > alerts_b else "(NOT surfaced -> looks dead)"])
			for m in (_career.news_log as Array).slice(maxi(0, news_a - 2)):
				print("   news: %s" % (str(m.get("text", "")) if m is Dictionary else str(m)))
			# Re-render the hub: the queued bid answer must pop as the PREMIER MANAGER 98 box.
			_free_overlays()
			_mount_hub()
			await _settle()
			_save_shot(dir, "pa_06b_hub_bidreply.png")

	# --- OWNER STEP 6: STAFF hire path (screen renders + hire mutates the backroom) ---
	_free_overlays()
	await _settle()
	_show_staff_screen()
	await _settle()
	_save_shot(dir, "pa_07_staff.png")
	var staff_before := (_career.staff as Array).size()
	var pool := Staff.pool_for_role(_career.staff_pool, "PHYSIOTHERAPIST")
	if pool.is_empty():
		print("PLAYERACT STAFF: no PHYSIO candidates in pool")
	else:
		_open_staff_hire("PHYSIOTHERAPIST", func() -> void: pass, "PHYSIOTHERAPIST")
		await _settle()
		_save_shot(dir, "pa_08_staff_hire.png")
		_career.hire_staff(int(pool[0].get("id", -1)))
		_career.save()
		print("PLAYERACT STAFF hire: staff %d->%d  (%s)" % [staff_before, (_career.staff as Array).size(),
			"FIRED" if (_career.staff as Array).size() > staff_before else "DEAD"])
	# --- VERIFY: the transfer-listed MARKET tag now shows in the SQUAD list (Schmeichel listed @ pa_03) ---
	_free_overlays()
	await _settle()
	_show_squad_screen()
	await _settle()
	var sq: SquadScreen = _first_of(SquadScreen)
	print("PLAYERACT SQUAD listed-tag: Schmeichel listed=%s (expect true) -> MARKET tag rendered in pa_09" %
		(_career.is_listed(45) if sq != null else "no-screen"))
	_save_shot(dir, "pa_09_squad_listed.png")
	print("PLAYERACT-SHOT done")
	get_tree().quit()


## Push a real touch press+release through the Viewport at DESIGN-space point `d`
## on full-rect control `ctrl` (maps design 640x480 -> the control's scaled/letterboxed
## viewport pixels, the inverse of the screens' own _to_design). Exercises the live GUI
## hit-test + overlay z-order exactly as a finger would.
func _synth_tap(ctrl: Control, d: Vector2) -> void:
	# The control lives in the 640x480 canvas; push_input wants WINDOW pixels. Map
	# local/design -> canvas (get_global_transform_with_canvas) -> window
	# (viewport screen transform). A real finger arrives already in window space and
	# the viewport applies the same map, so this reproduces the true hit-test path.
	var canvas_pt: Vector2 = ctrl.get_global_transform_with_canvas() * d
	var pos: Vector2 = get_viewport().get_screen_transform() * canvas_pt
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = pos
	down.pressed = true
	get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = pos
	up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame


## First mounted child of a given screen type (dev-shot introspection helper).
func _first_of(t) -> Node:
	for c in get_children():
		if is_instance_of(c, t):
			return c
	return null


## Free any mounted art-overlay child (everything except the persistent hub), so the next
## capture starts clean. Used by _screens_shot between shots.
func _free_overlays() -> void:
	for c in get_children():
		if c == _hub:
			continue
		if c is LeagueTableScreen or c is LineupScreen or c is SquadScreen \
				or c is FinanceScreen or c is TransferScreen or c is DirectivaScreen \
				or c is StadiumScreen or c is CupDrawScreen or c is YouthScreen \
				or c is StaffScreen or c is BrowseScreen \
				or c is PlayerInfoScreen or c is RivalScreen or c is ManagerHistoryScreen \
				or c is TrainingScreen or c is InjuriesScreen or c is StatisticsScreen \
				or c is OffersSelectionScreen or c is ChampsScreen \
				or c is ManagersMonthScreen or c is PlayersMonthScreen \
				or c is CharityShieldScreen or c is SeasonStartScreen:
			c.queue_free()
	_browse = null
	_mgr_history = null
	_offers_screen = null


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
		AudioManager.ui_select()
		_nav.pop_back()
		_nav.back().call()

func _set_view(title: String, subtitle: String, rows: Array, payload: Array, on_activate: Callable) -> void:
	# T1 #3 reskin: the former green $Root ItemList is replaced by the PM98-chrome
	# BrowseScreen (marble FONDO + BARRA + PROMAN font), the same chrome the database
	# browse already uses. The _nav stack + payload/on_activate machinery is preserved, so
	# every _set_view caller (TEAM TACTICS + its sub-flows, the transfer market/bid/sell/
	# renew/shortlist flows, end-of-season) is reskinned with no change to its own logic.
	# The hub sits on top of $Root; hide it so the opaque BrowseScreen reads clean.
	if _hub != null and is_instance_valid(_hub):
		_hub.visible = false
	_payload = payload
	_on_activate = on_activate
	var show_back := _nav.size() > 1
	_mount_browse(title, subtitle, rows,
		func(i: int) -> void:
			if i >= 0 and i < _payload.size() and _on_activate.is_valid():
				_on_activate.call(_payload[i]),
		func() -> void:   # RETURN pops the nav stack (the old TopBar Back), no extra click SFX
			if _nav.size() > 1:
				_nav.pop_back()
				_nav.back().call(),
		{"show_back": show_back})

func _on_item(idx: int) -> void:
	if idx >= 0 and idx < _payload.size() and _on_activate.is_valid():
		AudioManager.ui_select()
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
	_browse.row_selected.connect(func(_i: int) -> void: AudioManager.ui_select())
	_browse.row_selected.connect(on_select)
	_browse.back_pressed.connect(func() -> void: AudioManager.ui_select())
	_browse.back_pressed.connect(on_back)
	AudioManager.play_music()   # the menu theme rides every front-end / management screen

## Free every front-of-house overlay (browse + title + seleccion) before the career hub.
func _clear_front_overlays() -> void:
	for c in get_children():
		if c is BrowseScreen or c is TitleScreen or c is SeleccionScreen or c is DataBaseScreen:
			c.queue_free()
	_browse = null
	_seleccion = null
	_database = null

## Add a full-rect art overlay that frees on any tap (the display-only screen pattern).
func _mount_tap_overlay(scr: Control) -> void:
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## Reversed SQUAD overlay for any club dict (career roster or a GameDB club). On the
## managed club (`youth_enabled`) the YOUTH TEAM button opens the academy; everywhere
## else the screen just tap-dismisses as before.
func _open_squad(club: Dictionary, manager: String, cash: String, youth_enabled := false,
		season := "1997-98", week := 0) -> void:
	var scr: SquadScreen = load("res://scenes/SquadScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# The transfer-listed tag ("MARKET", frame 15) only applies to the manager's OWN squad.
	var listed: Dictionary = _career.transfer_listed if _career and int(club.get("id", -1)) == _career.club_id else {}
	scr.setup(club, manager, cash, youth_enabled, season, week, _career.tier if _career else 1, listed)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.youth_pressed.connect(_show_youth_screen)
	scr.player_pressed.connect(func(p: Dictionary) -> void: _open_player_info(p, club, scr))

## The DATA BASE squad view (the reversed dbasewin.exe browser) for a club dict: the four
## GOALKEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS columns over FONDO DBASE. A row raises that
## player's DATA BASE card (the Dbasewin player view — bios pages + career PROGRESS,
## DataBaseCardScreen.gd; replaced the interim FICHA hop 2026-07-06); RETURN or a tap on
## empty space dismisses. See DataBaseScreen.gd.
func _open_database_squad(club: Dictionary) -> void:
	if _database != null and is_instance_valid(_database):
		_database.queue_free()
	_database = load("res://scenes/DataBaseScreen.gd").new()
	_database.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_database)
	_database.setup(club)
	_database.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		if _database != null and is_instance_valid(_database):
			_database.queue_free()
		_database = null)
	_database.player_pressed.connect(_open_dbase_card.bind(club))


## The DATA BASE player card (Dbasewin.exe; docs/re/dbase_player_card_re.md) —
## the bios.json display surface: PERSONAL DATA + 6 prose pages + career
## PROGRESS + NOTES over the frame-baked chrome. RETURN dismisses.
func _open_dbase_card(player: Dictionary, club: Dictionary) -> void:
	var scr: DataBaseCardScreen = load("res://scenes/DataBaseCardScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(player, club)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())

## PLAYER INFORMATION (FICHA) overlay for one squad player, raised over the SQUAD screen.
## tier (for value/wage) comes from the club's division; OK / a tap dismisses it. When the
## player is one of the MANAGER'S OWN squad, the source RENEW / TRANSFER / SACK buttons are
## live (PM98 opens these from SQUAD MANAGEMENT); for another club's player (DATA BASE /
## opponent browse) the card is read-only. The Career hooks mutate the live roster dict (same
## object the overlay holds), so a RENEW updates YEARS in place and a SACK removes the player.
func _open_player_info(player: Dictionary, club: Dictionary, host: Control = null) -> void:
	var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# The original palette-dims the whole host screen under the card (081-vs-082
	# walkthrough pair, exact alert LUT). SquadScreen dims itself; hosts without
	# LUT-dim support keep the card's flat backdrop (documented interim).
	var squad_host := host as SquadScreen
	if squad_host != null:
		squad_host.set_dimmed(true)
		scr.host_dims = true
		scr.tree_exiting.connect(func() -> void:
			if is_instance_valid(squad_host):
				squad_host.set_dimmed(false))
	# PlayerInfoScreen uses `tier` only for the CLUB FEE / wage stature lookup, so pass the
	# stature classification (english_tier_of: 1-4 English, 0 foreign) not the finance tier
	# (which would mislabel a foreign club as Division One).
	var tier := TransferMarket.english_tier_of(club, GameDB.leagues)
	var own: bool = _career != null and int(club.get("id", -1)) == _career.club_id
	var pid := int(player.get("id", -1))
	scr.setup(player, club, tier, own, own and _career.is_listed(pid))
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	if not own:
		return
	# RENEW: the original's negotiation -- the OFFER form (wage/years steppers) IN the card, he
	# can REJECT a lowball (renew_negotiation_re.md / contract_re.md). Enters the card's renew mode.
	scr.renew_requested.connect(func(_p: Dictionary) -> void:
		AudioManager.ui_select()
		_open_renew_negotiation(player, pid, club, tier, scr))
	# TRANSFER: place him on (or off) the transfer market -- "PLAYER PLACED ON TRANSFER MARKET".
	scr.transfer_requested.connect(func(_p: Dictionary) -> void:
		AudioManager.ui_select()
		_career.toggle_listed(pid)
		_career.save()
		var listed := _career.is_listed(pid)
		scr.setup(player, club, tier, true, listed)
		_refresh_squad_overlay()   # the SQUAD list behind the card now shows/hides the MARKET tag
		_toast("%s placed on the transfer market." % player.get("name", "?") if listed
			else "%s removed from the transfer list." % player.get("name", "?")))
	# SACK: terminate his contract (compensation paid); he leaves, so close the card + refresh.
	scr.sack_requested.connect(func(_p: Dictionary) -> void:
		AudioManager.ui_select()
		var res := _career.release(pid)
		_career.save()
		if bool(res.get("ok", false)):
			scr.queue_free()
			_refresh_squad_overlay()
		_toast(str(res.get("msg", ""))))

## The RENEW negotiation from the FICHA -- the SOURCE OFFER form witnessed live at TOTAL level
## (renew_negotiation_re.md, 2026-07-23): the card's identity zone becomes the OFFER panel with
## the YEARLY WAGE / YEARS steppers over the read-only CONTRACT panel. OFFER applies Career.renew
## (he may reject a lowball, contract_re.md) and stamps the offered term; CANCEL drops back to the
## plain card. Replaces the earlier invented full-screen browse list. Signals wired once per card.
func _open_renew_negotiation(player: Dictionary, pid: int, club: Dictionary, tier: int,
		scr: PlayerInfoScreen) -> void:
	var band := _career.my_band()
	var weekly := Contract.current_weekly(player, band)
	var demand := Contract.demanded_weekly(player, band)
	var years := maxi(int(player.get("contract_term", 0)), int(player.get("contract_years", 0)))
	if not scr.has_meta("renew_wired"):
		scr.set_meta("renew_wired", true)
		scr.offer_made.connect(func(offer_weekly: int, offer_years: int) -> void:
			AudioManager.ui_select()
			var res := _career.renew(pid, offer_weekly)
			if bool(res.get("ok", false)):
				# honour the offered contract length (Career.renew fixes term at NEW_TERM_YEARS)
				player["contract_term"] = offer_years
				player["contract_years"] = offer_years
			_career.save()
			scr.end_renew()
			scr.setup(player, club, tier, true, _career.is_listed(pid))
			_refresh_squad_overlay()   # SQUAD YEARS/WAGE update behind the card
			_toast(str(res.get("msg", ""))))
		scr.renew_cancelled.connect(func() -> void:
			AudioManager.ui_select()
			scr.end_renew())
	scr.begin_renew(weekly, demand, years)

## Reversed LEAGUE TABLES overlay for any standings array (career or a SeasonSim table).
## RETURN dismisses; tapping a club row raises that club's DATA BASE squad (the managed
## club shows its live roster). Was a display-only tap-to-dismiss overlay.
func _open_table(rows: Array, title_left: String, season: String, week_label: String,
		tier: int, my_id: int, manager: String = "") -> void:
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(rows, title_left, season, week_label, tier, my_id, manager)
	# The living pyramid behind the witnessed division tabs: each tab pulls that
	# division's REAL simulated table + previous-revision positions (movement
	# markers). Career overlays only — a season-sim table has no pyramid.
	if _career != null and my_id == _career.club_id:
		scr.set_pyramid(func(t: int) -> Dictionary:
			return {"rows": _career.standings_for(t), "prev": _career.prev_positions_for(t)},
			_career.prev_positions_for(_career.tier))
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.club_selected.connect(func(id: int) -> void:
		AudioManager.ui_select()
		var club := _club_with_roster(id) if _career != null and id == _career.club_id else GameDB.club(id)
		_open_database_squad(club))
	# GOAL SCORERS (witnessed 2026-07-18: LEAGUE TABLES button -> graph+list screen;
	# RETURN goes back to LEAGUE TABLES). Division-scoped: the button opens the
	# SELECTED division's chart (witnessed lt_goalscorers_third, 2026-07-19).
	# Career only — a simulated season table has no goal ledger (honest gap).
	scr.scorers_pressed.connect(func() -> void:
		if _career == null or my_id != _career.club_id:
			return
		AudioManager.ui_select()
		_show_goal_scorers_screen(scr.selected_tier()))

## Reversed FINANCES overlay for any club dict.
func _open_finance(club: Dictionary, club_name: String, season: String) -> void:
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	scr.setup(sm, club_name, "", season)
	_mount_tap_overlay(scr)

## A1 — the 2D MATCH VIEW: the faithful PM98 results/commentary screen (clock + half,
## both shirts + score, possession bar, minute-by-minute EVENTS table, REPLAY/CONTINUE/
## EXIT) animated to the engine's event timeline. NOT a sprite pitch — the original's
## top-down 3D highlights were Actua-engine CD-only data, out of scope (see MatchScreen.gd).
## RETURN runs `on_back`. (`sub` unused now that the scoreline + clock live in MatchScreen.)
## The presentation follows the stored MATCH OPTIONS view mode (BRIEF default): BRIEF runs the
## commentary read-out; RESULTS jumps to the FULL TIME read-out (career, `result_data` non-empty)
## or seeks the BRIEF to 90' (watched, `{}`); WATCH overlays the 2D simulador.
func _open_match(home: Dictionary, away: Dictionary, hg: int, ag: int,
		lines: Array, _sub: String, on_back: Callable, result_data: Dictionary = {},
		possession: Array = []) -> void:
	# The match presents in the view mode chosen in MATCH OPTIONS (persisted globally,
	# default BRIEF) — NOT a forced per-match picker. RESULTS on a career match jumps
	# straight to the source-true FULL TIME read-out (frame 083), no running BRIEF.
	var mode: String = AudioManager.match_view_mode
	if mode == "results" and not result_data.is_empty():
		# WITNESSED (§7): RESULTS mode stops at a HALF TIME read-out first, then
		# the FULL TIME read-out, then the hub — not a straight jump to full time.
		_open_result_readout(_halftime_data(result_data), func() -> void:
			_open_result_readout(result_data, on_back), true)
		return
	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(str(home.get("name", "?")), str(away.get("name", "?")), hg, ag, lines,
		int(home.get("id", -1)), int(away.get("id", -1)), possession)
	scr.back_pressed.connect(func() -> void:
		# Career match EXIT — WITNESSED (§6): the "Do you want to leave the
		# championship ?" confirm. No -> resume; Yes -> title screen, the
		# in-flight week NOT persisted (the save is deferred to the hub return).
		if not result_data.is_empty():
			_confirm_leave_match(scr)
			return
		scr.queue_free()   # watched (non-career) match: EXIT just leaves
		if on_back.is_valid():
			on_back.call())
	# Full time: the BRIEF hands off to the separate FULL TIME / RESULT page (frame 083),
	# then CONTINUE from there returns to the hub (frame 084). Career match only has the
	# read-out data; a watched match just leaves the running screen.
	scr.continue_pressed.connect(func() -> void:
		if not result_data.is_empty():
			_open_result_readout(result_data, func() -> void:
				scr.queue_free()
				if on_back.is_valid():
					on_back.call())
		else:
			scr.queue_free()
			if on_back.is_valid():
				on_back.call())
	# RESULTS on a watched (non-career) match: skip the play, jump the BRIEF to full time.
	if mode == "results":
		scr.seek(90.0)
		return
	# WATCH: overlay the 2D GRAFICO simulador, fed the same timeline so both views agree on
	# clock/score/possession. Its BRIEF button drops back to the commentary beneath; EXIT
	# leaves the match. (HIGHLIGHTS cannot be confirmed in MATCH OPTIONS -- 3D .p3d absent -- so
	# the stored mode is never "highlights"; BRIEF is the default running view.)
	if mode == "watch":
		var sim: MatchSimulador = load("res://scenes/MatchSimulador.gd").new()
		sim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(sim)
		sim.setup(str(home.get("name", "?")), str(away.get("name", "?")), hg, ag, lines,
			int(home.get("id", -1)), int(away.get("id", -1)))
		sim.brief_pressed.connect(func() -> void: sim.queue_free())
		sim.back_pressed.connect(func() -> void:
			sim.queue_free()
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
		"new": _show_career_select()
		"league": _show_db_league(item["league"])
		_: _show_db_intl()

func _continue_career() -> void:
	_career = Career.load_save()
	if _career != null:
		# GROUND heal for older saves: capacity 0 would collapse to `0 + added`
		# the moment a works completed (the pre-works default relied on a
		# display-side fallback only), and headroom did not exist before
		# 2026-07-27. Both are static per club in GameDB, so healing is exact.
		var gclub := GameDB.club(_career.club_id)
		if _career.stadium_capacity <= 0:
			_career.stadium_capacity = int(gclub.get("capacity", 0))
		if _career.stadium_headroom <= 0:
			_career.stadium_headroom = int(gclub.get("capacityHeadroom", 0))
		# Re-attach the pyramid's static club records (never persisted); a
		# pre-pyramid save gains its lower divisions here (fast-forwarded).
		_career.ensure_divisions(_pyramid_context())
		# ...and the shipped 0x26e4 youth pool, which is game data, not save data.
		_career.youth_pool = Youth.pool_of(GameDB.clubs_by_id)
		# ...and the shipped TRUE XIs, so European ties run on the byte-exact engine (S5).
		_career.euro_xis = _true_xi_index()
		# An in-progress career in its first seasons still gets the guaranteed gem on resume.
		var before: int = (_career.youth as Array).size()
		_career._ensure_wonderkid()
		# Real talents whose debut season has already passed arrive on resume too (an
		# app update onto an in-flight save, or a pool side-loaded mid-career).
		var caught_up: int = _career.inject_due_talents(TalentDB.talents)
		if (_career.youth as Array).size() != before or caught_up > 0:
			_career.save()
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
			_open_database_squad(item["club"])

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
		func(i: int) -> void: _open_database_squad(cl[i]),
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
		"Full time", func() -> void: _show_match_pick(league, null), {}, m.get("possession", []))


# ---- career mode ---------------------------------------------------------

## New-career SELECCION screen (the faithful original-art "ENTER YOUR NAME AND SELECT A
## TEAM"): one screen for manager-name entry + club selection across the divisions,
## replacing the old two-step Track-B division/club pickers. See SeleccionScreen.gd.
func _show_career_select() -> void:
	if _seleccion != null and is_instance_valid(_seleccion):
		_seleccion.queue_free()
	if _hub != null and is_instance_valid(_hub):
		_hub.visible = false
	for c in get_children():
		if c is BrowseScreen or c is TitleScreen:
			c.queue_free()
	_browse = null
	_seleccion = load("res://scenes/SeleccionScreen.gd").new()
	_seleccion.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_seleccion)
	_seleccion.setup(GameDB.leagues, Career.has_save(), GameDB.clubs_in_league)
	_seleccion.career_begun.connect(_show_preseason)
	_seleccion.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_dismiss_seleccion()
		_show_home())
	_seleccion.load_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_dismiss_seleccion()
		_continue_career())
	_seleccion.delete_pressed.connect(func() -> void:
		AudioManager.ui_select()
		Career.delete_save())
	AudioManager.play_music()

func _dismiss_seleccion() -> void:
	if _seleccion != null and is_instance_valid(_seleccion):
		_seleccion.queue_free()
	_seleccion = null


## SELECCION CONTINUE -> the "Preseason for <club>" screen (frames 012 -> 013).
## SKIP / CONTINUE there finalises the career with the entry-flow picks attached.
func _show_preseason(manager_name: String, league: Dictionary, club: Dictionary) -> void:
	AudioManager.ui_select()
	_dismiss_seleccion()
	if _preseason != null and is_instance_valid(_preseason):
		_preseason.queue_free()
	_preseason = load("res://scenes/PreseasonScreen.gd").new()
	_preseason.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preseason)
	_preseason.setup(PMChrome.title_case_name(str(club.get("name", ""))), manager_name,
		GameDB.leagues, GameDB.clubs_in_league, _clubs_of_country_en, int(club.get("id", -1)),
		club)
	_preseason.preseason_done.connect(func(rivals: Array) -> void:
		if _preseason != null and is_instance_valid(_preseason):
			_preseason.queue_free()
		_preseason = null
		_begin_career(manager_name, league, club, rivals))


## Clubs of a PAISES English country name (what the preseason map/strip shows).
## Since the 2026-07-06 exact rebuild game_db stores the PAISES name itself
## (EQUIPOS header country code) — direct lookup. The country_es_en.json bridge
## remains only as a fallback for an owner-side-loaded pre-rebuild user:// DB
## (whose tags were best-effort Spanish).
func _clubs_of_country_en(name_en: String) -> Array:
	var direct := GameDB.clubs_in_country(name_en)
	if not direct.is_empty():
		return direct
	if _country_en_es.is_empty():
		var f := FileAccess.open("res://data/country_es_en.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for es in parsed.get("map", {}):
					var en := str(parsed["map"][es].get("en", ""))
					if not _country_en_es.has(en):
						_country_en_es[en] = []
					_country_en_es[en].append(es)
	var out: Array = []
	for es2 in _country_en_es.get(name_en, []):
		out.append_array(GameDB.clubs_in_country(str(es2)))
	return out

## The full English-pyramid context for Career's living lower divisions:
## all four league memberships (static GameDB club dicts) plus the WITNESSED
## 1997-98 pre-season seed orders (data/season_seed_1997.json, live wine
## campaign 2026-07-19 — see docs/re/league_table_screen_re.md).
func _pyramid_context() -> Dictionary:
	var divs: Array = []
	for lg in GameDB.leagues:
		divs.append({"league_id": str(lg["id"]), "name": str(lg["name"]),
			"tier": int(lg.get("tier", 0)), "clubs": GameDB.clubs_in_league(str(lg["id"]))})
	var seeds: Dictionary = {}
	if FileAccess.file_exists("res://data/season_seed_1997.json"):
		var f := FileAccess.open("res://data/season_seed_1997.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				seeds = parsed.get("seeds", {})
	return {"divisions": divs, "seeds": seeds}


func _begin_career(manager_name: String, league: Dictionary, club: Dictionary,
		preseason_rivals: Array = []) -> void:
	AudioManager.ui_select()
	var league_clubs := GameDB.clubs_in_league(league["id"])
	_career = Career.create(club, league, league_clubs, GameDB.leagues, _pyramid_context())
	_career.youth_pool = Youth.pool_of(GameDB.clubs_by_id)   # the shipped 0x26e4 pool
	_career.euro_xis = _true_xi_index()   # shipped TRUE XIs -> euro ties on the stat engine (S5)
	_career.manager_name = manager_name
	# Entry-flow picks (NIVEL level + Players age ? + preseason friendlies). The
	# rivals play out via hub CONTINUE before league round 1 (Career.play_friendly).
	_career.manager_level = _pending_level
	_career.players_age = _pending_age
	_career.preseason_rivals = _preseason_meta(preseason_rivals, Career.preseason_dates(1997))
	# Season-1 honours: the original contests the Charity Shield + runs the
	# European competitions from career start, seeded with the REAL 1996-97
	# honours (witnessed TEAMS IN CHAMPIONSHIPS, orig/06). English careers only —
	# the honour clubs are resolved from GameDB by their game names.
	var rng2 := _career.career_rng()   # S3: the ONE persisted career stream
	var hon := _english_honours_96_97()
	if not hon.is_empty():
		_career.open_first_season(hon, _euro_pool(), _sa_champion_1997(), rng2,
			_honour_clubs(hon))
	_career.save()
	_dismiss_seleccion()
	# TEAMS IN CHAMPIONSHIPS opens the season chain (orig/06: preseason CONTINUE
	# -> this sheet -> hub); the shield card + START OF SEASON ride the week-0
	# hub entry once the preseason friendlies are done (_show_career). The shot
	# harnesses (PM98_*_SHOT capture rigs) drive _begin_career directly and skip
	# the chain -- they are not the real flow.
	if OS.has_environment("PM98_SHOT_DIR"):
		_enter_career()
	else:
		_show_champs_screen(func() -> void: _enter_career())

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
	# Foreign clubs (preseason friendly rivals) have no live career roster —
	# keep the GameDB squad rather than wiping it with an empty override.
	var live := _career.squad_of(id)
	if not live.is_empty():
		base["players"] = live
	# The managed club's ground can be expanded via stadium WORKS, so its live capacity
	# overrides the static GameDB figure (feeds finance gate income + the stadium tier).
	if id == _career.club_id and _career.stadium_capacity > 0:
		base["capacity"] = _career.stadium_capacity
	# Board-set prices (ticket / advertising board) likewise override the defaults so the
	# finance ledger reflects the manager's pricing.
	if id == _career.club_id:
		if _career.ticket_price > 0:
			base["ticket_price"] = _career.ticket_price
		if _career.board_price > 0:
			base["board_price"] = _career.board_price
	return base

## The management hub IS the original-art MENUPRINCIPAL (B1): a persistent overlay raised
## once on entering the career and re-shown whenever nav returns here, instead of the old
## green data-browser list. Mount-or-refresh: re-reads _career each call so the centre
## panel (club / cash / position) updates after a match or signing.
func _show_career() -> void:
	if _nav.is_empty():
		_nav.append(_show_home)
	# Free any browse overlay (a reskinned _set_view sub-flow / results / news) before the
	# hub takes over, so it doesn't linger behind the hub when we pop back here.
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
		_browse = null
	# Week-0 curtain-raiser chain (audit C1 #8/#9): once the preseason friendlies
	# are done (or none were picked), the original shows the CHARITY SHIELD
	# CHAMPION card then START OF SEASON before the week-1 hub (orig/70-73).
	if _career != null and not _career.season_opened and _career.week == 0 \
			and not _career.finished and _career.pending_friendly().is_empty() \
			and not OS.has_environment("PM98_SHOT_DIR"):
		_run_season_open_chain()
		return
	_mount_hub()


## Play the shield (season 1; rollovers already played it) and walk the witnessed
## card -> START OF SEASON -> hub sequence. season_opened is stamped first so
## re-entering _show_career can't loop the chain.
func _run_season_open_chain() -> void:
	_career.season_opened = true
	var rng := _career.career_rng()   # S3: the ONE persisted career stream
	_career.play_season_opener(rng)
	_career.save()
	# A CONTESTANT plays his shield as the first fixture: go straight to START OF SEASON,
	# then the hub raises it as the "Charity Final" match (played in _career_advance, the
	# CHARITY SHIELD CHAMPION card follows the full-time whistle). A non-participant sees the
	# already-decided card FIRST (wine-witnessed order: card -> START OF SEASON -> hub).
	if _career.charity_shield_pending:
		_show_season_start(func() -> void: _mount_hub())
		return
	var after_shield := func() -> void:
		_show_season_start(func() -> void: _mount_hub())
	var cs: Dictionary = _career.charity_shield
	if cs.is_empty():
		after_shield.call()
		return
	_show_shield_card(cs, after_shield)

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
		_hub.exit_confirmed.connect(_leave_career_to_title)
	else:
		move_child(_hub, get_child_count() - 1)
	_hub.visible = true
	# Shared-header state: during preseason the original's plaque bands read
	# "Preseason"/"Preparation" and the calendar sheet shows the pending
	# FRIENDLY's date (wine captures 2026-07-12); in season, league + Week N.
	var pf := c.pending_friendly()
	if not pf.is_empty():
		PMChrome.header_phase = "preseason"
		PMChrome.header_date = PMChrome.date_from_iso(str(pf.get("date", "")))
	elif not c.pending_charity_shield().is_empty():
		PMChrome.header_phase = "charity"   # the Charity Shield fixture plaque ("Charity"/"Final")
		PMChrome.header_date = {}
	else:
		PMChrome.header_phase = ""
		PMChrome.header_date = {}
	# Next-fixture opponent for the hub's central stack (pending friendly first).
	var fx := _next_fixture()
	var opp_name := ""
	var opp_id := -1
	var is_home := true
	var opp_mgr := ""
	if not fx.is_empty():
		is_home = int(fx[0]) == c.club_id
		opp_id = int(fx[1]) if is_home else int(fx[0])
		opp_name = str(GameDB.club(opp_id).get("name", ""))
		opp_mgr = str(GameDB.club(opp_id).get("manager", "") if GameDB.club(opp_id).get("manager") != null else "")
	_hub.setup(c.club_name, c.league_name, c.season, c.cash,
		"%d%s" % [c.position(), _ord_suffix(c.position())], c.club_id,
		c.week + 1, opp_name, opp_id, is_home, c.manager_name, opp_mgr)
	# Queued career alerts (the scout's "finished his search", ...) raise as the
	# witnessed hub "PREMIER MANAGER 98" boxes once the hub is up (witness 78,
	# docs/re/scout_screen_re.md).
	if not c.pending_alerts.is_empty():
		for msg in c.pending_alerts:
			_hub.alert(str(msg))
		c.pending_alerts = []
		c.save()
	AudioManager.play_music()   # resume the menu theme on return from a match

## The hub SAVE GAME 10-slot dialog (SaveGameDialog.gd;
## docs/re/savegame_dialog_re.md): over the LIVE undimmed hub (witness 51).
## SAVE writes the tapped slot with the typed GAME name (+ refreshes the
## autosave so Continue never lags a just-saved slot); CANCEL just closes.
func _show_save_dialog() -> void:
	var dlg: SaveGameDialog = load("res://scenes/SaveGameDialog.gd").new()
	dlg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dlg)
	dlg.setup(Career.slot_metas(), _career.manager_name)
	dlg.save_requested.connect(func(slot: int, save_name: String) -> void:
		_career.save_slot(slot, save_name)
		_career.save())
	dlg.closed.connect(func() -> void:
		dlg.queue_free())

## Leave the career to the ORIGINAL start screen (MENUPRINCIPAL EXIT-Yes, witnessed
## 2026-07-27: hub EXIT raises the leave-championship confirm over the LUT-dimmed hub
## and Yes lands on the TITLE screen — wine-captures-2026-07-27-hubexit). Saves first
## (unlike the in-match abandon, nothing here is mid-flight), frees the hub, clears
## the career, and mounts the title over the home browser exactly like boot does.
func _leave_career_to_title() -> void:
	if _career != null:
		_career.save()
	if _hub != null and is_instance_valid(_hub):
		_hub.queue_free()
	_hub = null
	_career = null
	_nav = [_show_home]
	_show_home()
	_show_title_screen()

func _career_advance() -> void:
	var rng := _career.career_rng()   # S3: the ONE persisted career stream
	# A pending preseason friendly plays FIRST (the walked August dates precede
	# round 1) through the same match flow as a league fixture — run-2 played
	# Man Utd v Sao Paulo in BRIEF mode. League table untouched (Career).
	# The autosave is DEFERRED to the hub return (_show_match_result's on_back):
	# witnessed §6 — EXIT-Yes abandons the in-flight week UNSAVED, so the disk
	# must still hold the pre-CONTINUE career while the match presents.
	var fr := _career.pending_friendly()
	if not fr.is_empty():
		var res_f := _career.play_friendly(rng, _club_with_roster(int(fr.get("club_id", -1))))
		if res_f.is_empty():
			_career.save()
			_show_career()
			return
		_show_match_result(res_f)
		return
	# The Charity Shield the manager contests is the curtain-raiser fixture (after any
	# friendlies, before league round 1): PLAY it through the same BRIEF/WATCH match flow,
	# then the CHARITY SHIELD CHAMPION card follows the whistle (witnessed 2026-07-23:
	# Man Utd v Chelsea, MATCH OPTIONS -> KICK OFF -> full time -> champion card).
	var sh := _career.pending_charity_shield()
	if not sh.is_empty():
		var res_s := _career.play_charity_shield_match(rng, _club_with_roster(int(sh["opp_id"])))
		if res_s.is_empty():
			_career.save()
			_show_career()
			return
		_show_match_result(res_s, func() -> void:
			_career.save()
			_show_shield_card(_career.charity_shield, func() -> void:
				_show_career()
				_pop_division_finals(func() -> void: _pop_cup_draw(func() -> void: _pop_month_awards(func() -> void: _pop_channel_tv(_pop_pending_team_offers))))))
		return
	var res := _career.advance_week(rng)   # ratings come from the live roster
	if res.is_empty():
		_career.save()   # bye / season end: no presentation, save immediately
		_show_career()   # refresh the hub in place
		_pop_division_finals(func() -> void: _pop_cup_draw(func() -> void: _pop_month_awards(func() -> void: _pop_channel_tv(_pop_pending_team_offers))))
		return
	_show_match_result(res)

## The manager's match (B4): the running BRIEF + MATCH OPTIONS, whose RESULTS tap now surfaces
## the source-true FULL TIME read-out (MatchResultScreen; docs/re/match_flow_re.md). The BRIEF
## feed stays honest (kept). RETURN/CONTINUE refresh + raise the hub.
func _show_match_result(res: Dictionary, on_finish: Callable = Callable()) -> void:
	# LIVE rosters, not the frozen GameDB squads: a player sold in week 3 must not turn
	# up on the week-4 BRIEF feed (owner report 2026-07-24). `_club_with_roster` is the
	# same view the pre-match LINE-UPS roll and every squad screen already use.
	var home := _club_with_roster(int(res["home_id"]))
	var away := _club_with_roster(int(res["away_id"]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Narrate the EXACT stored scoreline so feed and table agree; the stat engine's own
	# scorers ride along in res["goals"] (empty -> narrate re-rolls by finishing weight),
	# and res["xi_home"/"xi_away"] are the 22 that actually played — the only players the
	# feed may name.
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]),
		res.get("goals", []), res.get("xi_home", []), res.get("xi_away", []))
	var verdict := _result_word(int(res["hg"]), int(res["ag"]), bool(res["manager_home"]))
	# The RESULT read-out data: fixture-mode barra (the two clubs that JUST played — note the
	# date + phase chip are corrected for the played match below) + the real goal vector +
	# the STADIUM panel (ALWAYS the fixture HOME club's ground, charter #6d).
	var hdr := _match_header()
	hdr["mode"] = "fixture"
	hdr["home_id"] = int(res["home_id"])
	hdr["away_id"] = int(res["away_id"])
	hdr["top"] = PMChrome.title_case_name(str(home.get("name", "")))
	hdr["bottom"] = PMChrome.title_case_name(str(away.get("name", "")))
	# Header phase chip (charter #6e): the read-out barra's green plaque is NOT stuck
	# "Preseason"/"Preparation" in season. Friendlies keep that default (witnessed 1 Aug
	# Villa friendly); a LEAGUE match reads the division + the week just played
	# (witnessed 9 Aug Southampton away = "Premier"/"Week 1"). advance_week() has already
	# incremented `week` to the 1-based number of the round it just played, so the date
	# is that Saturday (date_parts week==played round), overriding _match_header's
	# next-week grammar for this played-match read-out.
	if bool(res.get("charity", false)):
		# The Charity Shield read-out reads "Charity"/"Final", not the friendly default.
		hdr["status_top"] = "Charity"
		hdr["status_bottom"] = "Final"
	elif not bool(res.get("friendly", false)):
		hdr["status_top"] = PMChrome._band_league(_career.league_name)
		hdr["status_bottom"] = "Week %d" % _career.week
		var pd := PMChrome.date_parts(_career.season, _career.week)
		hdr["weekday"] = str(pd["wd"])
		hdr["day"] = str(pd["day"])
		hdr["month"] = str(pd["mon"])
		hdr["year"] = str(pd["year"])
	var result_data := {
		"home": str(home.get("name", "?")), "away": str(away.get("name", "?")),
		"hg": int(res["hg"]), "ag": int(res["ag"]), "goals": res.get("goals", []),
		"home_id": int(res["home_id"]), "away_id": int(res["away_id"]),
		"header": hdr, "stadium": _result_stadium(res), "motm": _result_motm(res),
		# For the board's per-team STATISTICS buttons: the two XIs that played and the
		# fixture's own stat report (the records the binary copies out of
		# DAT_0066afd0+0x9c/+0xa4 rather than the season store).
		"xi_home": res.get("xi_home", []), "xi_away": res.get("xi_away", []),
		"report": res.get("report"), "report_ht": res.get("report_ht"),
	}
	# Back at the hub, any live bids on listed players raise their TEAM OFFER
	# cards — the original's post-match CONTINUE order (run-3 frames 085->086).
	# CONTINUE after full time: the default returns to the hub (deferred week autosave); a
	# caller can override it (the Charity Shield chains the CHARITY SHIELD CHAMPION card here).
	var finish := on_finish if on_finish.is_valid() else func() -> void:
		_career.save()   # the deferred week autosave (EXIT-Yes never gets here)
		_show_career()
		_pop_division_finals(func() -> void: _pop_cup_draw(func() -> void: _pop_month_awards(func() -> void: _pop_channel_tv(_pop_pending_team_offers))))
	var open_match := func() -> void:
		_open_match(home, away, int(res["hg"]), int(res["ag"]), m["lines"],
			"%s  -  back to the dugout" % verdict, finish, result_data, res.get("possession", []))
	# LINE-UPS ON (charter #5, frames 61-63): the XI-vs-XI photo roll precedes
	# the presentation in EVERY view mode — witnessed in RESULTS mode too (§4).
	if AudioManager.lineups_on:
		_show_lineup_roll(int(res["home_id"]), int(res["away_id"]), open_match)
	else:
		open_match.call()

## Mount the pre-match XI-vs-XI photo roll (LineupRollScreen) for a fixture; a tap
## on the complete state tears it down and continues into the match via `on_done`.
func _show_lineup_roll(home_id: int, away_id: int, on_done: Callable) -> void:
	var home := _club_with_roster(home_id)
	var away := _club_with_roster(away_id)
	var scr: LineupRollScreen = load("res://scenes/LineupRollScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(PMChrome.title_case_name(str(home.get("name", ""))),
		PMChrome.title_case_name(str(away.get("name", ""))),
		_roll_manager(home), _roll_manager(away), home_id, away_id,
		_roll_xi(home), _roll_xi(away))
	scr.done.connect(func() -> void:
		scr.queue_free()
		if on_done.is_valid():
			on_done.call())

## The manager name shown under a club on the roll header: the career's entered
## name for the managed club (witness "mwm"/"MWM" as typed), the GameDB manager
## for CPU clubs (witness "Gregory", "Van Gaal").
func _roll_manager(club: Dictionary) -> String:
	if _career != null and int(club.get("id", -1)) == _career.club_id:
		return _career.manager_name
	return str(club.get("manager", ""))

## A club's starting XI as roll rows [{num, name, photo_id}] in slot order (GK
## first): the manager's own Career tactics XI, or the CPU club's SHIPPED XI
## (club_tactics.json, the same rule VIEW RIVAL fields), else auto-pick. Shirt
## numbers are the EQUIPOS squadNo; clubs without one show slot 1..11 (witness:
## F.C. Barcelona ran 1..11 while Manchester Utd. wore real squad numbers).
func _roll_xi(club: Dictionary) -> Array:
	var ids: Array = []
	if _career != null and int(club.get("id", -1)) == _career.club_id:
		ids = _tactics().xi
	else:
		ids = _cpu_xi_ids(club)
	var by_id := {}
	for p in club.get("players", []):
		by_id[int(p.get("id", -1))] = p
	var out: Array = []
	for i in mini(11, ids.size()):
		var p: Dictionary = by_id.get(int(ids[i]), {})
		var num := int(p.get("squadNo", 0))
		out.append({"num": num if num > 0 else i + 1,
			"name": str(p.get("name", "")), "photo_id": p.get("photoId")})
	return out

## A CPU club's XI ids: the shipped .DBC slot XI when game_db-complete (the
## VIEW RIVAL rule, docs/re/rival_screen_re.md), else Tactics auto-pick.
func _cpu_xi_ids(club: Dictionary) -> Array:
	if _club_tactics_db == null:
		_club_tactics_db = {}
		var f := FileAccess.open("res://data/club_tactics.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_club_tactics_db = (d as Dictionary).get("clubs", {})
	var rec: Variant = _club_tactics_db.get(str(int(club.get("id", -1))))
	if rec is Dictionary:
		var xi: Array = (rec as Dictionary).get("xi", [])
		if xi.size() == 11:
			var have := {}
			for p in club.get("players", []):
				have[int(p.get("id", -1))] = true
			var ok := true
			for v in xi:
				if int(v) < 0 or not have.has(int(v)):
					ok = false
					break
			if ok:
				return xi
	return Tactics.auto_pick(club).xi

## The RESULT-mode read-out's STADIUM panel data: ALWAYS the fixture HOME club's ground,
## filled (witnessed at AWAY matches too -- Villa Park, The Dell; kills the old "honest
## blank away" rule, charter #6d). Ground NAME + CAPACITY are source-exact (EQUIPOS
## param_1[6]); ATTENDANCE + % are the FinanceModel projection (per-match runtime gate is
## not reproducible -- finance_constants.md -- so the money/sponsor rows stay an honest gap).
## Manager-home reuses the Career finance_preview (its own board-set prices + works-expanded
## capacity); an away fixture projects the home OPPONENT's gate from its tier + real capacity.
## All five rows are filled (the original fills them at home and away alike). The money
## rows come from the SAME FinanceModel ledger the FINANCES screen shows, reduced to one
## match: ATTENDANCE MONEY = the season TICKETS line / home games, SPONSOR BOARDS SOLD =
## boards sold as a % of the tier's board count, SPONSORSHIP MONEY = the board income for
## this match. The model is ours and documented as such (finance_constants.md: the
## original's per-match runtime gate lives in the save, not in code) — but the panel is no
## longer half-blank, which is what made it read as truncated.
func _result_stadium(res: Dictionary) -> Dictionary:
	var home_id := int(res.get("home_id", -1))
	var club := _mgr_club() if home_id == _career.club_id else GameDB.club(home_id)
	var sm: Dictionary
	if home_id == _career.club_id:
		sm = _career.finance_summary()
	else:
		sm = FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var home_games: int = maxi(1, int(sm.get("home_games", 19)))
	var gate := 0
	var boards := 0
	for line in sm.get("income_lines", []):
		if line[0] == "TICKETS":
			gate = int(line[1])
		elif line[0] == "SPONSOR BOARDS SOLD":
			boards = int(line[1])
	@warning_ignore("integer_division")
	return {"name": str(club.get("stadium", "")),
		"capacity": int(sm.get("capacity", 0)), "attendance": int(sm.get("attendance", 0)),
		"gate": gate / home_games, "boards": boards / home_games,
		"boards_pct": int(sm.get("boards_pct", 0))}


## MAN OF THE MATCH for the read-out: FUN_0044a370 picked a player id; resolve his name,
## his club and his mugshot. `{}` when the fixture produced no per-player record.
func _result_motm(res: Dictionary) -> Dictionary:
	var pid := int(res.get("motm_pid", 0))
	if pid <= 0:
		return {}
	for cid in [int(res.get("home_id", -1)), int(res.get("away_id", -1))]:
		var view := _club_with_roster(cid) if _career.rosters.has(cid) else GameDB.club(cid)
		for p in view.get("players", []):
			if int((p as Dictionary).get("id", -1)) == pid:
				return {"name": str((p as Dictionary).get("name", "")),
					"club": PMChrome.title_case_name(str(view.get("name", ""))),
					"photo_id": (p as Dictionary).get("photoId")}
	return {}

## Mount the source-true FULL TIME read-out (MatchResultScreen) over the running match, from a
## MATCH OPTIONS RESULTS tap. `data` carries the fixture + real goal vector + stadium; CONTINUE
## tears the whole match flow down and returns to the hub (via `on_continue`).
func _open_result_readout(data: Dictionary, on_continue: Callable, half := false) -> void:
	var rs: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	rs.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rs)
	rs.setup(str(data.get("home", "?")), str(data.get("away", "?")),
		int(data.get("hg", 0)), int(data.get("ag", 0)), data.get("goals", []),
		int(data.get("home_id", -1)), int(data.get("away_id", -1)),
		data.get("header", {}), data.get("stadium", {}), half, data.get("motm", {}))
	var advance := func() -> void:
		rs.queue_free()
		if on_continue.is_valid():
			on_continue.call()
	# Both HALF TIME and FULL TIME advance on CONTINUE (witnessed §5: the HT read-out
	# carries a real CONTINUE button, not a tap-anywhere dismiss).
	rs.continue_pressed.connect(advance)
	# Either team's STATISTICS button opens that side's MATCH table over the board
	# (witness frames 02/03 half time, 05/06 full time); RETURN drops back to it.
	rs.statistics_pressed.connect(func(side: int) -> void:
		AudioManager.ui_select()
		_show_match_statistics(data, side))

## The HALF TIME view of a result: the same fixture with only first-half goals
## and the score they produce (witnessed RESULTS-mode chain, §7).
func _halftime_data(data: Dictionary) -> Dictionary:
	var ht := data.duplicate()
	var goals: Array = []
	var hg := 0
	var ag := 0
	for g in data.get("goals", []):
		if int(g.get("minute", 0)) <= 45:
			goals.append(g)
			if int(g.get("side", 0)) == 0:
				hg += 1
			else:
				ag += 1
	ht["goals"] = goals
	ht["hg"] = hg
	ht["ag"] = ag
	# The HALF TIME board's STATISTICS buttons read the half-time snapshot, not the
	# finished match (MIN 45, and every column a prefix of the full-time sheet).
	ht["report"] = data.get("report_ht")
	return ht

## EXIT during a career match: the witnessed leave-championship confirm (§6).
## The match pauses under the box; No resumes it; Yes drops to the title
## screen with the in-flight week NOT persisted (save is deferred to the hub
## return, so the disk still holds the pre-CONTINUE career).
func _confirm_leave_match(scr: MatchScreen) -> void:
	scr.set_paused(true)
	var cf: LeaveConfirm = load("res://scenes/LeaveConfirm.gd").new()
	add_child(cf)
	cf.no_pressed.connect(func() -> void:
		cf.queue_free()
		scr.set_paused(false))
	cf.yes_pressed.connect(func() -> void:
		cf.queue_free()
		scr.queue_free()
		_abandon_career_to_title())

## Witnessed §6 "Yes": abandon the career to the TITLE SCREEN without saving —
## the in-flight week is lost; "Continue career" reloads the pre-week save.
func _abandon_career_to_title() -> void:
	if _hub != null and is_instance_valid(_hub):
		_hub.queue_free()
	_hub = null
	_career = null
	_nav = [_show_home]
	_show_home()
	_show_title_screen()

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
## beneath; either league mode raises the SELECT LEVEL OF THE GAME dialog over the
## title (frames 002-007; the pro/league split isn't modelled in this build, so both
## enter the same career-entry flow).
func _title_action(action: String, scr: TitleScreen) -> void:
	AudioManager.ui_select()
	match action:
		"exit":
			get_tree().quit()
		"database":
			scr.queue_free()        # reveal the home browse mounted beneath
			if _browse == null or not is_instance_valid(_browse):
				_show_home()
		_:
			_show_nivel_screen(scr)


## The NIVEL dialog (SELECT LEVEL OF THE GAME) as an overlay ABOVE the still-mounted
## title screen, exactly as the original draws it over FONDO7 (frames 002-007).
## See NivelScreen.gd / docs/re/nivel_screen_re.md.
func _show_nivel_screen(title_scr: TitleScreen) -> void:
	if _nivel != null and is_instance_valid(_nivel):
		_nivel.queue_free()
	_nivel = load("res://scenes/NivelScreen.gd").new()
	_nivel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_nivel)
	var summary: Dictionary = {}
	if Career.has_save():
		var saved := Career.load_save()
		if saved != null:
			summary = {"club": saved.club_name, "name": saved.manager_name}
	_nivel.setup(Career.has_save(), summary, Career.slot_metas())
	_nivel.level_chosen.connect(func(level: String, age: bool) -> void:
		_pending_level = level
		_pending_age = age
		_dismiss_nivel()
		if title_scr != null and is_instance_valid(title_scr):
			title_scr.queue_free()
		_show_career_select())
	_nivel.load_game.connect(func(slot: int) -> void:
		_dismiss_nivel()
		if title_scr != null and is_instance_valid(title_scr):
			title_scr.queue_free()
		# slot -1 = the legacy autosave row; 0-9 = a SAVE GAME dialog slot
		if slot >= 0:
			var c := Career.load_slot(slot)
			if c != null:
				c.save()        # the loaded slot becomes the live autosave
		_continue_career())
	_nivel.cancel_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_dismiss_nivel())   # title screen stays behind

func _dismiss_nivel() -> void:
	if _nivel != null and is_instance_valid(_nivel):
		_nivel.queue_free()
	_nivel = null

## The original-art LEAGUE TABLES screen over the hub, driven by the live career
## standings. Tap to dismiss. (See scenes/LeagueTableScreen.gd for asset provenance.)
func _show_league_table_screen() -> void:
	_open_table(_career.standings(), _career.club_name, _career.season,
		"Week %d" % mini(_career.week + 1, _career.total_weeks()),
		_career.tier, _career.club_id, _career.manager_name)

## GOAL SCORERS (LEAGUE TABLES sub-screen; docs/re/goalscorers_screen_re.md): the
## scorer chart + compare graph + per-player goal-log popup, fed by the scorer
## ledger of the given DIVISION (witnessed division-scoped, 2026-07-19: entering
## from a lower division's table shows THAT division's chart). Mounts OVER the
## league table; RETURN frees it so the table beneath re-raises.
func _show_goal_scorers_screen(for_tier: int = -1) -> void:
	var t: int = _career.tier if for_tier <= 0 else for_tier
	var scr: GoalScorersScreen = load("res://scenes/GoalScorersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_career.league_scorers_for(t), _career.scorer_goal_dict_for(t),
		_career.names_for(t),
		_career.week, _career.manager_name, _career.club_name, _career.tier,
		_career.season, "Week %d" % mini(_career.week + 1, _career.total_weeks()),
		_career.club_id)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())

## The original-art LINE-UP (ALINEACIÓN) screen as a full-screen overlay: the squad
## list + the CAMPO mini-pitch with the chosen XI in formation, at the coordinates
## reversed from MANAGER.EXE (docs/re/lineup_screen_re.md). Tap to dismiss.
func _show_lineup_screen() -> void:
	var scr: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var tac := _tactics()
	scr.setup(_mgr_club(), tac, _career.manager_name, _career.league_name, _career.season,
		_career.week + 1, _match_header())
	# RETURN dismisses; TACTICS opens the TEAM TACTICS modal. Tapping a player selects him;
	# tapping a second player swaps them into/within the XI (PM98's line-up edit), persisted
	# via Career. The ARROW buttons page the squad list.
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_board_screen())
	scr.xi_changed.connect(func() -> void:
		AudioManager.ui_select()
		_save_tactics(tac)
		_career.save())
	# The LINE-UP T/I/S plate opens the three sub-screens; each RETURN reopens LINE-UP.
	scr.training_pressed.connect(func() -> void:
		scr.queue_free()
		_show_training_screen())
	scr.injuries_pressed.connect(func() -> void:
		scr.queue_free()
		_show_injuries_screen())
	scr.statistics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_statistics_screen())
	# The [+] card box beside each player opens his FICHA over the line-up (not dismissing it).
	scr.player_info_pressed.connect(func(p: Dictionary) -> void:
		_open_player_info(p, _mgr_club(), scr))

## The LINE-UP TRAINING sub-screen (TrainingScreen.gd; docs/re/training_screen_re.md):
## the squad's training grid, the CURRENT TRAINING STAFF band (the hired skill coaches
## with their TP) and the selected player's attribute panel with its focus boxes.
## Ticking a box assigns him to that coach through Career.set_training_focus, which
## enforces the original's two caps; AUTO fills every coach to his TP. RETURN reopens
## LINE-UP; TACTICS opens the TEAM TACTICS board.
func _show_training_screen() -> void:
	var scr: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var feed := func() -> void:
		scr.setup(_mgr_club(), _career.staff, _match_header(), _career.training_focus)
	feed.call()
	scr.focus_toggled.connect(func(pid: int, focus: String) -> void:
		AudioManager.ui_select()
		var sel := scr._sel_pid
		var res := _career.set_training_focus(pid, focus)
		if str(res.get("msg", "")) != "":
			scr.alert(str(res["msg"]))       # "You can´t train any more players."
		_career.save()
		feed.call()
		scr._sel_pid = sel                   # setup() clears the selection; keep his panel up
		scr.queue_redraw())
	scr.auto_pressed.connect(func() -> void:
		AudioManager.ui_select()
		if Training.total_trainable(_career.staff) <= 0:
			scr.alert(Training.NO_TRAINER_MSG)
			return
		_career.auto_training_focus()
		_career.save()
		feed.call())
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_show_lineup_screen())
	scr.tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_board_screen())

## The LINE-UP INJURIES sub-screen (InjuriesScreen.gd; docs/re/injuries_screen_re.md):
## the manager squad's injured players by section + the physio band. RETURN reopens LINE-UP.
func _show_injuries_screen() -> void:
	var scr: InjuriesScreen = load("res://scenes/InjuriesScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), _career.staff, _match_header())
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_show_lineup_screen())
	scr.insurance_pressed.connect(func() -> void:
		scr.queue_free()
		_show_insurance_screen())
	# The PHYS. "+" button: send him to the physiotherapist (FUN_00543080 ->
	# FUN_00584db0). Refused silently when nobody is hired or the physio's slots are
	# full — the original's own behaviour, no message.
	scr.treat_pressed.connect(func(pid: int) -> void:
		var res := _career.treat_injury(pid)
		if not res:
			return
		AudioManager.ui_select()
		_career.save()
		scr.setup(_mgr_club(), _career.staff, _match_header()))

## The INSURANCE screen (InsuranceScreen.gd; docs/re/insurance_screen_re.md):
## the squad with per-player INSURANCE POLICY groups, priced by the binary's own
## FUN_0058c020 (Insurance.gd -- £200/£500/£1,000 is its floor, not a flat rate).
## RETURN reopens INJURIES (witnessed 39 -> 40 back path).
func _show_insurance_screen() -> void:
	var scr: InsuranceScreen = load("res://scenes/InsuranceScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), _career.tier, _match_header())
	scr.policy_selected.connect(func(pid: int, group: int) -> void:
		_career.set_insurance(pid, group)
		_career.save())
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_show_injuries_screen())

## The LINE-UP STATISTICS sub-screen (StatisticsScreen.gd; docs/re/statistics_screen_re.md):
## the squad roster over the baked table, with the REAL per-player season records out of
## the career's Pm98StatStore (the port of playerobj+0x24) and the club-counter TEAM TOTAL.
func _show_statistics_screen() -> void:
	var scr: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var club := _mgr_club()
	var rows := _career.season_stat_rows(club.get("players", []) as Array)
	scr.setup(club, _match_header(), rows,
		_career.season_stat_totals(rows, int(club.get("id", -1))))
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_show_lineup_screen())

## The MATCH statistics table for one side of a finished (or half-finished) fixture —
## the HALF TIME / FULL TIME board's per-team STATISTICS button (witness frames 02/03
## and 05/06, screenshots/wine-captures-2026-07-24-statistics-live/). Same screen the
## LINE-UP route uses, but fed the MATCH report instead of the season store: eleven rows,
## the XI that played, and the totals the report path computes (MP 1, MIN = the max, then
## a per-column sum). RETURN drops back to the board, which is still mounted underneath.
func _show_match_statistics(data: Dictionary, side: int) -> void:
	var xi: Array = data.get("xi_home" if side == 0 else "xi_away", [])
	var cid := int(data.get("home_id" if side == 0 else "away_id", -1))
	if xi.is_empty():
		# A legacy save or the ratings-fallback path carries no XI to render.
		_toast("No line-up was recorded for this match.")
		return
	var scr: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var club := {"id": cid, "name": str(data.get("home" if side == 0 else "away", "?")),
		"players": xi}
	var rows := Pm98StatStore.match_rows(data.get("report"), side, xi)
	# The board's own barra (both clubs + the fixture date), not the manager plaques —
	# the witnessed STATISTICS frames keep the match header they were opened from.
	scr.setup(club, data.get("header", {}), rows, Pm98StatStore.totals(rows))
	scr.back_pressed.connect(func() -> void: scr.queue_free())

## The original-art TACTICS board (TACTICAS) over the hub: the XI with fine-ROLE / POS
## columns, the skill grid, PREDEF / LOAD / SAVE TACTICS, and the CAMPO pitch carrying the
## formation's two-phase markers (docs/re/tacticas_screen_re.md; TacticsBoardScreen.gd).
## This is the screen the LINE-UP / OPPONENT TACTICS button and the hub TACTICS icon open
## Header state for the shared match-context barra (PMChrome.draw_match_header;
## frames 014/058): the week's league fixture when one exists — every walked
## TACTICS frame shows the fixture plaques — else the manager plaques.
## (Preseason friendly headers from preseason_rivals are un-wired yet: the
## friendly fixture list has no week join here; documented loose end.)
## [home_id, away_id] for the manager's NEXT match: a pending preseason friendly
## first (the walked August dates precede round 1 — run-2 headers show the
## friendly fixture on LINE-UP/TACTICS/VIEW RIVAL), else this week's league
## fixture, else [] (bye / season over).
func _next_fixture() -> Array:
	var fr := _career.pending_friendly()
	if not fr.is_empty():
		var rid := int(fr.get("club_id", -1))
		return [_career.club_id, rid] if bool(fr.get("home", false)) else [rid, _career.club_id]
	# The Charity Shield the manager contests is the next fixture (champions = home side).
	var sh := _career.pending_charity_shield()
	if not sh.is_empty():
		return [int(sh["champ_id"]), int(sh["fa_id"])]
	return _career.manager_fixture()

func _match_header() -> Dictionary:
	var d := PMChrome.date_parts(_career.season, _career.week + 1)
	var h := {"weekday": str(d["wd"]), "day": str(d["day"]),
		"month": str(d["mon"]), "year": str(d["year"])}
	var fx := _next_fixture()
	if fx.is_empty():
		h["mode"] = "manager"
		h["top"] = _career.manager_name
		h["bottom"] = PMChrome.title_case_name(_career.club_name)
		h["club_id"] = _career.club_id
	else:
		h["mode"] = "fixture"
		h["home_id"] = int(fx[0])
		h["away_id"] = int(fx[1])
		h["top"] = PMChrome.title_case_name(str(GameDB.club(int(fx[0])).get("name", "")))
		h["bottom"] = PMChrome.title_case_name(str(GameDB.club(int(fx[1])).get("name", "")))
	return h


## in the original; TEAM TACTICS on it opens the ATTACK|DEFENCE modal. PREDEF picks one of
## the ten source formations (real DAT_00660240 shape); LINE-UP / VIEW RIVAL / RETURN nav.
func _show_tactics_board_screen() -> void:
	for c in get_children():
		if c is TacticsBoardScreen:
			c.queue_free()
	var scr: TacticsBoardScreen = load("res://scenes/TacticsBoardScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var refresh := func() -> void:
		scr.setup(_mgr_club(), _tactics(), _career.manager_name, _career.league_name,
			_career.season, _career.week + 1, _match_header())
	refresh.call()
	# Apply a chosen formation to the live career tactics + persist + refresh the board.
	# Shared by the board's own `formation_picked` (the direct/test path) and the frame-true
	# PredefTacticsScreen overlay below.
	var apply_form := func(form: String) -> void:
		var t := _tactics()
		t.set_formation(form, _mgr_club())
		_save_tactics(t)
		_career.save()
		refresh.call()
	scr.formation_picked.connect(apply_form)
	# The POS-column FLECHA opens MANAGER.EXE's own ROLE picker: all 18 fine roles, the
	# player's NATURAL role in gold and his five ALTERNATIVES in white (RolePopup — the
	# EXE paints exactly those six, FUN_0056a1d0). Picking one writes his fine role, the
	# same field FUN_0056a560 sets. Witnessed live 2026-07-24 (Bergsson RIGHT BACK ->
	# INSIDE CENTRE LEFT: the ROLE cell and camrol change, POS does not).
	scr.role_pressed.connect(func(pid: int) -> void:
		AudioManager.ui_select()
		var p := _career._find_in(_career.club_id, pid)
		if p.is_empty():
			return
		var pop: RolePopup = load("res://scenes/RolePopup.gd").new()
		pop.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(pop)
		pop.setup(p)
		pop.dismissed.connect(func() -> void: pop.queue_free())
		pop.role_picked.connect(func(picked_pid: int, pos_fine: int) -> void:
			AudioManager.ui_select()
			pop.queue_free()
			if _career.set_player_role(picked_pid, pos_fine):
				_career.save()
				refresh.call()))
	# PREDEF opens the frame-true PredefTacticsScreen (10-formation picker, frame 140;
	# docs/re/tactics_subscreens_re.md) OVER the board, superseding the board's inline
	# disassembly-geometry picker: suppress that inline overlay (leave TacticsBoardScreen and
	# its 0px parity + regression test untouched) and mount the frame-baked modal instead.
	scr.predef_pressed.connect(func() -> void:
		scr._picker_open = false
		scr.queue_redraw()
		var pick: PredefTacticsScreen = load("res://scenes/PredefTacticsScreen.gd").new()
		pick.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(pick)
		pick.setup(_tactics().formation)
		pick.formation_picked.connect(func(form: String) -> void:
			apply_form.call(form)
			pick.queue_free())
		pick.cancelled.connect(func() -> void: pick.queue_free()))
	scr.save_pressed.connect(func() -> void:
		var t := _tactics()
		t.save_preset("%s %s" % [t.formation, t.marking])
		_toast("Tactics saved"))
	scr.load_pressed.connect(func() -> void:
		var presets := Tactics.list_presets()
		var user := presets.filter(func(p): return not bool(p.get("builtin", false)))
		if user.is_empty():
			_toast("No saved tactics")
			return
		var t := _tactics()
		t.apply_preset(user[-1], _mgr_club())
		_save_tactics(t)
		_career.save()
		_toast("Loaded %s" % str(user[-1].get("name", "tactics")))
		refresh.call())
	scr.team_tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_screen())
	scr.view_rival_pressed.connect(func() -> void:
		var fx := _next_fixture()
		if fx.is_empty():
			_toast("No match this week (bye)")
			return
		var home: bool = int(fx[0]) == _career.club_id
		var opp_id: int = int(fx[1]) if home else int(fx[0])
		scr.queue_free()
		_show_rival_screen(_club_with_roster(opp_id)))
	scr.lineup_pressed.connect(func() -> void:
		scr.queue_free()
		_show_lineup_screen())
	scr.return_pressed.connect(func() -> void: scr.queue_free())

## The frame-baked TEAM TACTICS modal (ATTACK | DEFENCE; TeamTacticsScreen.gd,
## docs/re/tactics_subscreens_re.md, witnessed by parity-run orig/25+26) over a real
## LINE-UP backdrop. Each control mutates the career Tactics live, persisted on
## `changed`; the exit is the modal's own baked OK plate (emits `done`, which frees
## both overlays) — the retired TacticsScreen.gd was RIGHT about OK; the close-X the
## interim modal carried was the invention (EQWINX is the tick). No in-modal SAVE
## (SAVE/LOAD are BOARD buttons), so no save_requested connect.
func _show_tactics_screen() -> void:
	var bg: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.setup(_mgr_club(), _tactics(), _career.manager_name, _career.league_name, _career.season,
		_career.week + 1, _match_header())
	var scr: TeamTacticsScreen = load("res://scenes/TeamTacticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_tactics())
	scr.changed.connect(func(d: Dictionary) -> void:
		_career.tactics = d
		_career.save())
	scr.done.connect(func() -> void:
		scr.queue_free()
		bg.queue_free())

## The original-art SQUAD MANAGEMENT (PLANTILLA) screen for the managed club. The YOUTH
## TEAM button opens the academy; a tap elsewhere dismisses to the hub.
## (docs/re/squad_screen_re.md; the database browse reuses _open_squad with youth off.)
func _show_squad_screen() -> void:
	_open_squad(_mgr_club(), "", "£%s" % _fmt_int(_career.cash), true,
		_career.season, _career.week + 1)

## The YOUTH TEAM screen (over the squad): the academy crop with their projected potential,
## the youth manager's READY flags, and PROMOTE (tap a ready youngster -> first team). The
## development model is ours (Youth.gd); the surface is PM98's. RETURN reveals the squad.
func _show_youth_screen() -> void:
	var scr: YouthScreen = load("res://scenes/YouthScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var refresh := func() -> void:
		scr.setup(_career.youth, _career.staff, _career.manager_name, _career.club_name,
			_career.season, _career.week + 1, _career.club_id,
			not _career.youth_search.is_empty(), _career.youth_caps, _career.youth_found)
	refresh.call()
	scr.search_pressed.connect(func(skills: Array) -> void:
		_career.start_youth_search(skills)
		_career.save()
		refresh.call())
	# The six LED flags live on the career (the original's criteria object survives
	# leaving the screen — youth_re.md §3), so a toggle persists immediately.
	scr.caps_changed.connect(func(sel: Dictionary) -> void:
		_career.youth_caps = sel
		_career.save())
	# PLAYERS FOUND row tap: offer the prospect a contract. He joins, or turns you down
	# ("The youth player %s has rejected your offer.") — the owner's "the players they
	# find are supposed to be clickable to offer a contract".
	scr.prospect_pressed.connect(func(pid: int) -> void:
		AudioManager.ui_select()
		var res := _career.sign_youth_prospect(int(pid))
		_career.save()
		refresh.call()
		_toast(str(res.get("msg", ""))))
	scr.promote_requested.connect(func(pid: int) -> void:
		_career.promote_youth(int(pid))
		_career.save()
		refresh.call()
		_refresh_squad_overlay())
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_refresh_squad_overlay())

## Re-feed the SQUAD overlay (if it's still mounted under the youth screen) the live roster,
## so a promotion shows up immediately when the youth screen closes.
func _refresh_squad_overlay() -> void:
	for c in get_children():
		if c is SquadScreen:
			(c as SquadScreen).setup(_mgr_club(), "", "£%s" % _fmt_int(_career.cash), true,
				_career.season, _career.week + 1, _career.tier, _career.transfer_listed)

## The STAFF (EMPLE) screen on the hub's staff icon: hire/sack the backroom team (a TRAINER
## speeds development, a PHYSIO cuts injuries, a YOUTH COACH improves the academy -- Staff.gd),
## with the wage bill + live effect. The TRAINING button opens the training screen (the trainer
## context); RETURN -> hub. Replaces the interim training-on-the-staff-icon (now nested under it).
func _show_staff_screen() -> void:
	var scr: StaffScreen = load("res://scenes/StaffScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	_staff_last_role = ""
	var refresh := func() -> void:
		scr.setup(_career.staff_personnel(), _career.manager_name, _career.club_name,
			_career.season, _career.week + 1, _career.club_id)
	refresh.call()
	# Tap a role card -> open the hire overlay for that role's category (frames 100 + 108-119).
	# A coach card (a TRAINER skill) opens the TRAINERS layout with THAT skill preselected.
	scr.role_selected.connect(func(role: String) -> void:
		_staff_last_role = role
		_open_staff_hire(Staff.category_of(role), refresh, role))
	# The CLUB PERSONNEL SIGN button opens the hire overlay (last-viewed role, else the first
	# single-role category); SACK sacks the last-viewed role's holder (model choice: sacking is
	# selection-driven and the last card tapped is the selection -- docs/re/staff_re.md).
	scr.sign_pressed.connect(func() -> void:
		var r: String = _staff_last_role if _staff_last_role != "" else "PHYSIOTHERAPIST"
		_open_staff_hire(Staff.category_of(r), refresh, r))
	scr.sack_pressed.connect(func() -> void:
		var m: Dictionary = Staff.member_in_role(_career.staff, _staff_last_role)
		if not m.is_empty():
			_career.sack_staff(int(m.get("id", -1)))
			_career.save()
			refresh.call())
	scr.back_pressed.connect(func() -> void:
		_close_staff_hire()
		scr.queue_free())


# ---- backroom-staff hire overlay (StaffHireOverlay) ----------------------

var _staff_overlay: StaffHireOverlay = null
var _staff_last_role := ""
var _staff_skill := "HANDLING"   # TRAINERS overlay: the skill whose AVAILABLE pool is shown

## Open (or re-open) the modal hire overlay for a `category`. TRAINERS opens its own 6-skill
## layout (frame 100): all six coaches at once + a skill picker that filters the AVAILABLE pool
## (`selected_skill` picks the initial skill; defaults to the last-tapped coach card). The other
## seven are single-role. `refresh` repaints the CLUB PERSONNEL screen underneath after a hire.
func _open_staff_hire(category: String, refresh: Callable, selected_skill: String = "") -> void:
	_close_staff_hire()
	var ov: StaffHireOverlay = load("res://scenes/StaffHireOverlay.gd").new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	_staff_overlay = ov
	if category == "TRAINERS":
		var sk := selected_skill
		if not Staff.is_trainer(sk):
			sk = _staff_last_role if Staff.is_trainer(_staff_last_role) else Staff.HANDLING
		_staff_skill = sk
		var repaint_tr := func() -> void:
			ov.setup("TRAINERS", {}, Staff.pool_for_role(_career.staff_pool, _staff_skill).slice(0, 3),
				_career.staff_personnel(), _staff_skill)
		repaint_tr.call()
		# skill picker -> re-filter AVAILABLE to that skill (CURRENT list is unchanged).
		ov.skill_selected.connect(func(skill: String) -> void:
			_staff_skill = skill
			_staff_last_role = skill
			repaint_tr.call())
		ov.category_selected.connect(func(cat: String) -> void:
			_staff_last_role = cat
			_open_staff_hire(cat, refresh))
		ov.sign_candidate.connect(func(cid: int) -> void:
			_career.hire_staff(int(cid))
			_career.save()
			refresh.call()
			repaint_tr.call())
		ov.ok_pressed.connect(func() -> void: _close_staff_hire())
		return
	var repaint := func() -> void:
		ov.setup(category, _career.staff_personnel().get(category, {}),
			Staff.pool_for_role(_career.staff_pool, category).slice(0, 3))
	repaint.call()
	ov.category_selected.connect(func(cat: String) -> void:
		_staff_last_role = cat
		_open_staff_hire(cat, refresh))
	ov.sign_candidate.connect(func(cid: int) -> void:
		_career.hire_staff(int(cid))
		_career.save()
		refresh.call()
		repaint.call())
	ov.ok_pressed.connect(func() -> void: _close_staff_hire())

func _close_staff_hire() -> void:
	if _staff_overlay != null and is_instance_valid(_staff_overlay):
		_staff_overlay.queue_free()
	_staff_overlay = null

## The original-art FINANCES ("INCOME + EXPENSES") screen for the managed club. Tap to
## dismiss. (docs/re/finance_screen_re.md, driven by FinanceModel.)
## Selectable match ticket prices (£); the board advertising-board ladder is tier-scaled.
# OURS: the original's own TICKET PRICE ladder is not reversed. Only the DEFAULT is
# witnessed -- £7.50 a head (FinanceModel.TICKET_DEFAULT) -- and it opens the ladder.
const TICKET_LADDER := [7.5, 10.0, 12.0, 15.0, 18.0, 22.0, 28.0, 35.0]

func _show_finance_screen() -> void:
	for c in get_children():
		if c is FinanceScreen:
			c.queue_free()
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
		_browse = null
	var club := _mgr_club()
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(sm, _career.club_name, "", _career.season, _career.cash, _career.week + 1,
		_career.insurance_ledger(), _career.week_books(), _career.live_week_book(),
		_career.cash_at_close(),
		{"supercup": not _career.supercup.is_empty(),
			"intercontinental": not _career.intercontinental.is_empty(),
			"euro_comp": _career.euro_income_comp()})
	scr.prices_pressed.connect(_show_finance_control)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	# Secret cash cheat: 5 taps on the live-cash box deposit £100M, then re-render with it.
	scr.cheat_cash.connect(func() -> void:
		_career.cash += 100_000_000
		_career._news("finance", "An anonymous benefactor deposits £100,000,000 into the club account.")
		_career.save()
		_show_finance_screen())

## The board PRICE controls (T2 #6): set the match TICKET PRICE and the advertising
## BOARD PRICE; the live preview shows how demand (attendance / boards sold) responds, so
## the manager can find the revenue-maximising price. PM98-chrome browse over the finances.
func _show_finance_control() -> void:
	var pv := _career.finance_preview()
	var gold := Color(0.98, 0.86, 0.45)
	var rows: Array = [
		{"text": "Match ticket price", "value": "£%d" % int(pv["ticket"]), "accent": gold},
		{"text": "Advertising board price", "value": "£%s" % Career._grp(int(pv["board"])), "accent": gold},
		{"text": "Projected attendance", "enabled": false,
			"value": "%s / %s" % [Career._grp(int(pv["attendance"])), Career._grp(int(pv["capacity"]))]},
		{"text": "Season gate + board income", "enabled": false,
			"value": "£%s" % Career._grp(int(pv["gate"]) + int(pv["boards"]))},
	]
	var payload: Array = [{"a": "ticket"}, {"a": "board"}, null, null]
	_mount_browse("%s  -  PRICES" % _career.club_name,
		"Tap a price to change it; demand responds", rows,
		func(i: int) -> void:
			var p: Variant = payload[i]
			if p == null:
				return
			if p["a"] == "ticket":
				_career.set_ticket_price(_cycle(TICKET_LADDER, float(pv["ticket"])))
			else:
				_career.set_board_price(int(_cycle(_board_ladder(), float(pv["board"]))))
			_career.save()
			_show_finance_control(),
		func() -> void: _show_finance_screen())

## Tier-scaled advertising-board price ladder (rounded to £50), around the division default.
func _board_ladder() -> Array:
	var def := int(FinanceModel.summary({}, _career.tier).get("board_price", 600))
	var out: Array = []
	for fct in [0.5, 0.75, 1.0, 1.5, 2.0, 3.0]:
		out.append(int(round(def * fct / 50.0)) * 50)
	return out

## Next rung up a price ladder (wraps); if `current` is off-ladder, the first rung above it.
func _cycle(ladder: Array, current: float) -> float:
	for i in ladder.size():
		if absf(float(ladder[i]) - current) < 0.005:
			return float(ladder[(i + 1) % ladder.size()])
	for v in ladder:
		if float(v) > current:
			return float(v)
	return float(ladder[0])

## Step a price ladder by one rung (GROUND MATCH DAY arrows: right = up, left = down). Clamps
## at the ends (no wrap) so the two arrows read as +/- on the same ladder the PRICES screen
## cycles. Off-ladder `current` snaps to the nearest rung in the step direction.
func _step_price(ladder: Array, current: float, up: bool) -> float:
	if ladder.is_empty():
		return current
	if up:
		for v in ladder:
			if float(v) > current:
				return float(v)
		return float(ladder[ladder.size() - 1])
	for i in range(ladder.size() - 1, -1, -1):
		if float(ladder[i]) < current:
			return float(ladder[i])
	return float(ladder[0])

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
	scr.setup(c.market(), c.club_name, c.manager_name, c.season, c.cash, win,
		c.offers_left, c.week + 1, c.league_name, c.club_id)
	# The screen owns its input now (the ARROW scroll buttons page the list); a non-scroll
	# tap emits back_pressed to dismiss the overlay. CURRENT OFFERS is the sourced FICHAR
	# hub route to the offers screen (docs/re/ofertas_screen_re.md FUN_00532a50).
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.current_offers_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_current_offers_screen())
	scr.scout_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_scout_screen())
	scr.offers_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_offers_screen())
	scr.player_pressed.connect(func(row: Dictionary) -> void:
		AudioManager.ui_select()
		_show_make_offer_card(row))

## The REAL make-offer card (MakeOfferScreen; walkthrough run-3 101-118,
## docs/re/make_offer_re.md): the PLAYER INFORMATION card with the OFFER panel.
## Opens over the transfer screen from a player-row tap (the original's browse
## list -> card route). OFFER -> Career.sign_player with the card's terms
## (yearly wage -> weekly, years, checked clauses); LOAN PLAYER ->
## Career.sign_loan (their first XI is never loanable, the loan_market rule);
## CANCEL closes. The original submits silently and returns to the browse (119)
## — our accept/reject feedback rides the existing toast, not a modal.
func _show_make_offer_card(row: Dictionary) -> void:
	var pid := int(row.get("pid", -1))
	var from_club := int(row.get("club_id", -1))
	var player := _career._find_in(from_club, pid)
	# A SCOUT result can name a player at a club with no live roster — the scout
	# searches the whole world (E.U. / NON E.U.), and only the manager's own division
	# is simulated live. `_find_in` returns {} for those, which used to answer the tap
	# with "That player is no longer available" and nothing else: the owner's "scout
	# results are supposed to be clickable". Fall back to the static GameDB record and
	# route the bid the external way, exactly as the OFFERS browse already does.
	var live := not player.is_empty()
	if not live:
		for p in GameDB.club(from_club).get("players", []):
			if int((p as Dictionary).get("id", -1)) == pid:
				player = p
				break
	# PLAYERS WITHOUT TEAM rows carry club_id -1: they are the free-agent pool, signed
	# on wage terms alone (no club to bid to), so the card routes to sign_free_agent.
	var free := false
	if player.is_empty() and from_club == -1:
		for p in _career.free_agents:
			if int((p as Dictionary).get("id", -1)) == pid:
				player = p
				free = true
				break
	if player.is_empty():
		_toast("That player is no longer available.")
		return
	var card: MakeOfferScreen = load("res://scenes/MakeOfferScreen.gd").new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)
	# This route IS the "PLAYER PLACED ON TRANSFER MARKET" card, so the OFFER panel
	# opens on the seller's own asking terms — witness (wine, Bolton wk 4): Almeyda's
	# card opens CLUB OFFER = CLUB FEE £8,500,000, YEARLY WAGE £575,000, YEARS 1, with
	# the contract's clauses ticked. See MakeOfferScreen.setup.
	var seller := GameDB.club(from_club)
	var band := _career.band_of(from_club) if live \
		else TransferMarket.stature_of(seller.get("players", []),
			TransferMarket.english_tier_of(seller, GameDB.leagues))
	var ask := int(row.get("fee", 0))
	if ask <= 0 and not free:
		ask = TransferMarket.value_of(player, band)   # a scout row with no stamped fee
	if free:
		band = _career.my_band()                      # no seller: value his terms off us
	card.setup(player, {"id": from_club, "name": str(row.get("club_name", "?"))},
		ask, _career.cash, {
			"offer": ask,
			"yearly_wage": Contract.current_yearly(player, band),
			"years": int(player.get("contract_years", player.get("contract_term", 1))),
			"clauses": player.get("clauses", []),
		})
	card.cancelled.connect(func() -> void:
		AudioManager.ui_select()
		card.queue_free())
	card.offer_made.connect(func(offer: int, yearly_wage: int, years: int, clauses: Array, bonus: int) -> void:
		AudioManager.ui_select()
		# The bid is only PLACED here — the club answers on the next week roll
		# (Career._resolve_pending_bids), as in the original's days-later response.
		var weekly := maxi(1, yearly_wage / Contract.SEASON_WEEKS)
		var res: Dictionary
		if free:
			res = _career.sign_free_agent(pid, weekly)   # no club to bid to: wage terms only
		elif live:
			res = _career.place_bid_roster(pid, from_club, offer, weekly, years, clauses, bonus)
		else:
			res = _career.place_bid_external(player,
				{"id": from_club, "name": str(row.get("club_name", "?")),
					"players": GameDB.club(from_club).get("players", [])},
				offer, weekly, years, clauses, bonus)
		_career.save()
		card.queue_free()
		_toast(str(res["msg"])))
	card.loan_requested.connect(func() -> void:
		AudioManager.ui_select()
		if free:
			_toast("%s has no club to loan him from." % str(player.get("name", "He")))
			return
		if not live:
			# loans out of static (foreign / other-division) clubs are un-modeled
			_toast("%s will not loan out their players." % str(row.get("club_name", "They")))
			return
		if bool(row.get("key", false)):
			_toast("%s will not loan out a first-team player." % str(row.get("club_name", "They")))
			return
		var res := _career.sign_loan(pid, from_club)
		_career.save()
		if res["ok"]:
			card.queue_free()
		_toast(str(res["msg"])))

## The SCOUT screen (docs/re/scout_screen_re.md): hire-gated criteria panel +
## the async search. SEARCH arms Career.start_scout_search (any checked
## non-own division's static GameDB clubs are bridged in and freeze at arm
## time); the finished hub alert rides Career.pending_alerts. A result-row tap
## opens the make-offer card — scout rows carry the market-row shape
## (pid/club_id/club_name/fee/key), so the existing card route applies
## (witness 82).
func _show_scout_screen() -> void:
	var c := _career
	var scr: ScoutScreen = load("res://scenes/ScoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(Staff.member_in_role(c.staff, Staff.SCOUT_ROLE), c.scout_searching(),
		c.scout_results, c.club_name, c.manager_name, c.season, c.week + 1,
		c.league_name, c.club_id, c.scout_found_total)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.search_started.connect(func(criteria: Dictionary) -> void:
		AudioManager.ui_select()
		var foreign: Array = []
		var seen := {}
		for lid in criteria.get("leagues", []):
			if str(lid) != c.league_id:
				for cl in GameDB.clubs_in_league(str(lid)):
					seen[int((cl as Dictionary).get("id", -1))] = true
					foreign.append(cl)
		# E.U. PLAYERS / NON E.U. PLAYERS scout ABROAD — that is how the original sends a
		# scout out of England (there is no foreign-league checkbox). Binary-exact since
		# 2026-07-25: `FUN_005753e0` @0x575675 routes a player to the nationality gate ONLY
		# when his club's division index (club+0x50) is >= 4, so these two boxes never
		# reach an English club's players — those are the four division checkboxes' job
		# alone. Hence the FOREIGN filter below (a club with no English `leagueId`). The
		# shipped database carries 384 non-English clubs, so the pool is real data.
		var world: Array = []
		if bool(criteria.get("eu", false)) or bool(criteria.get("non_eu", false)):
			for cl in GameDB.clubs:
				var cd: Dictionary = cl
				var cid := int(cd.get("id", -1))
				if cid == c.club_id or seen.has(cid) or c.rosters.has(cid):
					continue      # own club + the live division are scanned separately
				var lid_v: Variant = cd.get("leagueId")   # null on all 384 foreign clubs
				if lid_v is String and str(lid_v) != "":
					continue      # an ENGLISH-league club: only its division box reaches it
				seen[cid] = true
				world.append(cd)
		c.start_scout_search(criteria, foreign, world)
		c.save())
	scr.player_pressed.connect(func(row: Dictionary) -> void:
		AudioManager.ui_select()
		_show_make_offer_card(row))
	# OURS (Mats, 2026-07-27): the INSTANT name lookup — every keystroke in the
	# panel's NAME box queries the whole decoded database at once; no mission, no
	# criteria, no wait. Career never reads GameDB, so the static world (every
	# club outside the live division) is bridged here once per mount.
	var statics: Array = []
	for cl in GameDB.clubs:
		var scd: Dictionary = cl
		var scid := int(scd.get("id", -1))
		if scid == c.club_id or c.rosters.has(scid):
			continue
		statics.append(scd)
	scr.name_search.connect(func(name_raw: String) -> void:
		if c.instant_name_search(name_raw, statics) >= 0:
			scr.apply_instant_results(c.scout_results, c.scout_found_total))

## The OFFERS map-browse screen (docs/re/offers_map_re.md): country flags ->
## kit grid -> squad list -> the make-offer card (witness 47 = MakeOfferScreen,
## run-3 100->101). Buys route through sign_player when the club has a LIVE
## roster (the manager's own division), else sign_external (static clubs —
## foreign / other divisions).
func _show_offers_screen() -> void:
	var c := _career
	var scr: OffersScreen = load("res://scenes/OffersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var own_div := 0
	for i in GameDB.leagues.size():
		if str(GameDB.leagues[i].get("id", "")) == c.league_id:
			own_div = i
	var hidden := {}
	for pid in c.external_signed:
		hidden[int(pid)] = true
	for p in c.my_squad():
		hidden[int(p.get("id", -1))] = true
	scr.setup(GameDB.leagues, GameDB.clubs_in_league, _clubs_of_country_en,
		own_div, c.club_id, hidden, c.club_name, c.manager_name, c.season,
		c.week + 1, c.league_name, c.club_id)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.player_pressed.connect(func(player: Dictionary, club: Dictionary) -> void:
		AudioManager.ui_select()
		_show_browse_offer_card(player, club, scr))

## The make-offer card over the OFFERS browse for a player on a club WITHOUT a
## live roster path decision: own-division clubs resolve through the live
## roster (sign_player — AI transfers may have moved the man, witnessed-safe
## "no longer available"), anything else through sign_external.
func _show_browse_offer_card(player: Dictionary, club: Dictionary, host: Control) -> void:
	var c := _career
	var cid := int(club.get("id", -1))
	var pid := int(player.get("id", -1))
	var band := c.band_of(cid) if c.rosters.has(cid) else TransferMarket.stature_of(club.get("players", []), TransferMarket.english_tier_of(club, GameDB.leagues))
	# CLUB FEE shown is the player's ORIGINAL book value (PM98 fee table), NOT an
	# added key-player markup — the original shows the exact table value.
	var fee := TransferMarket.value_of(player, band)
	var card: MakeOfferScreen = load("res://scenes/MakeOfferScreen.gd").new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)
	card.setup(player, {"id": cid, "name": str(club.get("name", "?"))}, fee, c.cash)
	card.cancelled.connect(func() -> void:
		AudioManager.ui_select()
		card.queue_free())
	card.offer_made.connect(func(offer: int, yearly_wage: int, years: int, clauses: Array, bonus: int) -> void:
		AudioManager.ui_select()
		# Placed, not completed — the answer arrives with the next week roll.
		var res: Dictionary
		if c.rosters.has(cid):
			res = c.place_bid_roster(pid, cid, offer,
				maxi(1, yearly_wage / Contract.SEASON_WEEKS), years, clauses, bonus)
		else:
			res = c.place_bid_external(player, club, offer,
				maxi(1, yearly_wage / Contract.SEASON_WEEKS), years, clauses, bonus)
		c.save()
		card.queue_free()
		if bool(res.get("ok", false)) and host != null and is_instance_valid(host):
			(host as OffersScreen).setup_refresh_hidden(pid)
		_toast(str(res["msg"])))
	card.loan_requested.connect(func() -> void:
		AudioManager.ui_select()
		if not c.rosters.has(cid):
			# loans out of static (foreign / other-division) clubs are un-modeled
			_toast("%s will not loan out their players." % str(club.get("name", "They")))
			return
		var res := c.sign_loan(pid, cid)
		c.save()
		if res["ok"]:
			card.queue_free()
		_toast(str(res["msg"])))

## The original-art CURRENT OFFERS (OFERTAS) screen. LIVE-WITNESSED 2026-07-24 on the
## real game (Bolton career, week 1): the screen lists **the offers YOU have out** —
## one band per outstanding outgoing bid, showing the TARGET player's name/attribute
## strip and a single row CLUB (the club you bid to) | CLUB OFFER | YEARLY WAGE |
## YEARS | CLAUSES. A bid for Barlow of Rochdale showed "Rochdale £15,000 £5,000 1";
## a player of ours placed on the transfer market the same session did NOT appear.
## (The pre-2026-07-24 app fed this screen the manager's own transfer-listed players —
## the model was inverted. Incoming bids on your listed players are answered on the
## TEAM OFFER card that pops during CONTINUE processing, run-3 frames 085->086.)
## RETURN dismisses back to the transfer screen; a band tap is inert (the original's
## band interaction on THIS screen is un-witnessed — do not invent one).
func _show_current_offers_screen() -> void:
	var scr: CurrentOffersScreen = load("res://scenes/CurrentOffersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var bands: Array = []
	for b in _career.pending_bids:
		var bid: Dictionary = b
		var p: Dictionary
		var seller := ""
		if str(bid.get("kind", "")) == "external":
			p = bid.get("player", {})
			seller = str((bid.get("club", {}) as Dictionary).get("name", "?"))
		else:
			p = _career._find_in(int(bid.get("club_id", -1)), int(bid.get("pid", -1)))
			seller = str(_career.club_names.get(int(bid.get("club_id", -1)), "?"))
		if p.is_empty():
			continue
		# The row renders OUR terms: the fee we bid, the yearly wage we offered
		# (the card's weekly -> yearly), the contract length and any checked clauses.
		var weekly := int(bid.get("weekly", -1))
		bands.append({"player": p, "offers": [{
			"buyer_name": seller,
			"offer": int(bid.get("offer", 0)),
			"weekly_wage": weekly if weekly > 0 else Contract.market_weekly(p, _career.my_band()),
			"years": maxi(1, int(bid.get("years", TransferMarket.NEW_CONTRACT_YEARS))),
			"clauses": bid.get("clauses", []),
		}]})
		if bands.size() == 5:
			break
	scr.setup(bands, "", _career.club_name, _career.league_name, _career.season,
		_career.week + 1, _career.club_id)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())

## The REAL TEAM OFFER answer card for one listed player's bids (TeamOfferScreen;
## walkthrough run-3 frames 086-092 + 150-153): every offer row carries a
## REFUSE/ACCEPT toggle (REFUSE default), OK commits all answers at once. The
## card is modal — OK is the only exit, as in the original. Replaces the interim
## ACCEPT/REFUSE browse dialogs (2026-07-03).
func _show_team_offer(pid: int, refresh: Callable = Callable()) -> void:
	var p := _career._find_in(_career.club_id, pid)
	var offers := _career.offers_for(pid)
	if p.is_empty() or offers.is_empty():
		return
	var scr: TeamOfferScreen = load("res://scenes/TeamOfferScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# CLUB FEE = the market value, YEARS = the full term, LEFT = years remaining
	# (our contract model's split of the original's YEARS|LEFT pair). YEARLY WAGE uses the
	# exact table yearly (Contract.current_yearly), not round(weekly/52)*52.
	scr.setup(p, GameDB.club(_career.club_id), offers,
		TransferMarket.value_of(p, _career.my_band()),
		Contract.current_yearly(p, _career.my_band()),
		int(p.get("contract_term", p.get("contract_years", 0))),
		int(p.get("contract_years", 0)))
	scr.answered.connect(func(decisions: Array) -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_apply_offer_answers(pid, decisions)
		if refresh.is_valid():
			refresh.call())

## Apply a TEAM OFFER card's per-row answers through the Career guards. Accepts
## run first in row order — the first sale wins and every other bid on him lapses
## (accept_offer semantics); refused bids are dropped (the listing stays). The
## original surfaces only the SIGNING as a message — the hub "PREMIER MANAGER 98"
## alert box, EXE format "%s has been signed by %s%s." (frames 093/094) — so
## refusals stay quiet.
func _apply_offer_answers(pid: int, decisions: Array) -> void:
	var sold := false
	for i in decisions.size():
		if str(decisions[i]) == "accept" and not sold:
			var r := _career.accept_offer(pid, i)
			if bool(r.get("ok")) and _hub != null and is_instance_valid(_hub):
				# The EXE's own signing message (no fee), title-cased as rendered.
				_hub.alert("%s has been signed by %s." % [
					PMChrome.title_case_name(str(r.get("player_name", "?"))),
					PMChrome.title_case_name(str(r.get("buyer_name", "?")))])
			elif not bool(r.get("ok")):
				_toast(str(r.get("msg", "")))
			sold = bool(r.get("ok"))
	if not sold:
		for i in range(decisions.size() - 1, -1, -1):   # high->low keeps indices live
			if str(decisions[i]) == "refuse":
				_career.refuse_offer(pid, i)
	_career.save()

## Pop the TEAM OFFER card for every listed player holding live bids — the
## original raises these over the hub during CONTINUE processing (run-3 frames
## 085->086: FULL TIME -> TEAM OFFER cards -> signing messages). One card at a
## time; answering it (all rows default REFUSE, so OK always clears the player's
## bid list) chains to the next.
## The MONTHLY AWARDS pair, raised in the CONTINUE chain when a calendar month has
## just ended — witnessed order (2026-07-18, frames 76 -> 77 -> hub):
## MANAGERS OF THE MONTH -> its OK -> PLAYERS OF THE MONTH -> its OK -> on.
## `after` runs once both sheets are answered (or immediately when none is due).
func _pop_month_awards(after: Callable) -> void:
	if _career == null or (_career.month_awards as Dictionary).is_empty():
		if after.is_valid():
			after.call()
		return
	var aw: Dictionary = _career.month_awards
	_career.month_awards = {}          # answered once; never re-raised
	_career.save()
	var month := str(aw.get("month", ""))
	var mgr_rows: Dictionary = {}
	for t in (aw.get("managers", {}) as Dictionary):
		var r: Dictionary = (aw["managers"] as Dictionary)[t]
		mgr_rows[int(t)] = {"club_id": int(r.get("club_id", -1)), "club": str(r.get("club", "")),
			"manager": _mgr_of(int(r.get("club_id", -1)))}
	var ply_rows: Dictionary = {}
	for t in (aw.get("players", {}) as Dictionary):
		ply_rows[int(t)] = (aw["players"] as Dictionary)[t]
	var mgr: ManagersMonthScreen = load("res://scenes/ManagersMonthScreen.gd").new()
	mgr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(mgr)
	mgr.setup(month, mgr_rows)
	mgr.ok_pressed.connect(func() -> void:
		AudioManager.ui_select()
		mgr.queue_free()
		var ply: PlayersMonthScreen = load("res://scenes/PlayersMonthScreen.gd").new()
		ply.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(ply)
		ply.setup(month, ply_rows, _career.tier)
		ply.ok_pressed.connect(func() -> void:
			AudioManager.ui_select()
			ply.queue_free()
			if after.is_valid():
				after.call()))


func _pop_pending_team_offers() -> void:
	if _career == null:
		return
	for pid in _career.transfer_listed:
		if not _career.offers_for(int(pid)).is_empty():
			_show_team_offer(int(pid), _pop_pending_team_offers)
			return

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
	scr.setup(c.club_name, c.manager_name, c.season, c.cash, bp["directors"], bp["supporters"],
		bp["rating"], c.objective_text, bp["record"], bp["position"], c.week + 1, c.league_name)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
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
##
## The IMPROVE / WORKS toggle + the SEATS offer cards now live INSIDE StadiumScreen
## (frame-true, binding frame 173). The prior invented blue "GROUND WORKS" browse and its
## invented offer table (+2000/+5000/+10000 seats @ fabricated £/weeks) are removed — the
## real offers are the fixed +4,000/+8,000/+12,000 seats @ 20/35/50 weeks with witnessed
## per-club prices, carried in StadiumScreen.OFFER_*; Main just runs Career.start_works.

func _show_stadium_screen() -> void:
	# Free any prior stadium overlay / browse so re-entry (e.g. after starting works) is clean.
	for c in get_children():
		if c is StadiumScreen:
			c.queue_free()
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
		_browse = null
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
	scr.setup(_career.club_name, _career.manager_name, _career.season, ground,
		cap, seated, cap - seated, int(round(cap / 27.0)), _career.works_status(),
		float(sm.get("ticket_price", 0.0)), int(sm.get("board_price", 0)), _career.week + 1,
		_career.league_name, str(club.get("objective", "")), _career.stadium_headroom)
	# The live GROUND state for the CAR PARK / FACILITIES / SERVICES tabs + the WORK IN
	# PROGRESS ledger. Every improvement price now comes from the binary's own cost function
	# (GroundCost / FUN_0057ddd0) keyed by the club's STATURE band — the value the original
	# copies from club+0x58 into ground+0x24 — so all 476 clubs are priced, not just Man Utd.
	scr.set_improve_state(_career.car_park_levels, _carpark_price(club), _career.works_ledger(),
		_career.ground_grades, _career.works_total(), _career.my_band())
	# The per-club FACILITIES / SERVICES item tables mined from the real game
	# (app/data/ground_prices.json). A captured club (Man Utd) gets every item live with real
	# grades / prices / weeks; an un-captured club falls back to the sparse witness default.
	scr.set_ground_items(_ground_items(club, "facilities"), _ground_items(club, "services"))
	scr.improve_selected.connect(_on_stadium_improve)
	scr.works_requested.connect(_on_stadium_works)
	# GROUND MATCH DAY sub-view (owner frame 06): the TICKET PRICE / PRICE OF BOARD steppers
	# drive the SAME board prices as FINANCE -> PRICES; the sponsor-board season offer + ACCEPT
	# credit the witnessed lump sum. Refreshed in place (no re-mount) so stepping stays on screen.
	_refresh_matchday(scr, club)
	scr.matchday_ticket_step.connect(func(up: bool) -> void:
		var pv := _career.finance_preview()
		_career.set_ticket_price(_step_price(TICKET_LADDER, float(pv["ticket"]), up))
		_career.save()
		_refresh_matchday(scr, _mgr_club()))
	scr.matchday_board_step.connect(func(up: bool) -> void:
		var pv := _career.finance_preview()
		_career.set_board_price(int(_step_price(_board_ladder(), float(pv["board"]), up)))
		_career.save()
		_refresh_matchday(scr, _mgr_club()))
	scr.boards_sold.connect(func() -> void:
		if _career.sell_sponsor_boards(_board_sale_offer(_mgr_club())):
			_career.save()
		_refresh_matchday(scr, _mgr_club()))
	scr.back_pressed.connect(func() -> void: scr.queue_free())

## Feed the GROUND MATCH DAY sub-view from the live Career model: the board-set ticket / board
## prices (finance_preview, the authoritative displayed figures), the next home fixture, whether
## this club is the baked witness (Man Utd -> ticket ground/league + the £1,120,000 offer stay
## baked), and whether the season's boards are already sold.
func _refresh_matchday(scr: StadiumScreen, club: Dictionary) -> void:
	if not is_instance_valid(scr):
		return
	var pv := _career.finance_preview()
	var opp := _career.next_home_opponent()
	var away := PMChrome.title_case_name(str(GameDB.club(opp).get("name", ""))) if opp >= 0 else ""
	scr.set_matchday_state(float(pv["ticket"]), int(pv["board"]),
		PMChrome.title_case_name(_career.club_name), away,
		_board_sale_offer(club) > 0, _career.boards_sold_season)

## The witnessed GROUND MATCH DAY sponsor-board season-sale offer. Only Man Utd was captured
## (frame 06, £1,120,000); the offer is conditional per club in the original (finance_constants
## prices-screen +0x1e0 flag) and its value is data-driven, so every other club is an honest
## gap (0 -> the offer block is hidden, ACCEPT inert). Mirrors _carpark_price's witness rule.
func _board_sale_offer(club: Dictionary) -> int:
	return 1_120_000 if str(club.get("name", "")).to_lower().contains("manchester utd") else 0

## The witnessed CAR PARK per-level price. Only Man Utd was captured (frame 09, £2,975,000);
## the cost fn is un-RE'd so every other club is an honest gap (0). SEATS proved these prices
## ARE club-specific, so applying Man Utd's figure game-wide would be invention.
func _carpark_price(club: Dictionary) -> int:
	return 2_975_000 if str(club.get("name", "")).to_lower().contains("manchester utd") else 0

## The per-club FACILITIES / SERVICES item table (real data mined from the original game,
## app/data/ground_prices.json). Returns the club's ordered item array for `cat` in
## ("facilities" | "services"), or [] for a club not yet captured (honest gap, no invention).
var _ground_prices_cache: Dictionary = {}
func _ground_items(club: Dictionary, cat: String) -> Array:
	if _ground_prices_cache.is_empty():
		var f := FileAccess.open("res://data/ground_prices.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_ground_prices_cache = parsed
	var by_club: Dictionary = _ground_prices_cache.get(cat, {})
	return by_club.get(str(club.get("name", "")), [])

## A SEATS offer card was ticked on the in-screen IMPROVEMENTS view: run the real Career
## expansion (start_works enforces cash + ceiling), persist, and re-mount the GROUND screen
## so it reflects the new WORK IN PROGRESS state.
func _on_stadium_improve(added: int, cost: int, weeks: int) -> void:
	if _career.start_works(added, cost, weeks):
		_career.save()
	_show_stadium_screen()

## A CAR PARK quadrant / FACILITIES / SERVICES upgrade was ticked: run the real work
## (begin_work enforces cash + the no-duplicate guard), persist, and re-mount so the WORK IN
## PROGRESS ledger reflects it (frame 07).
func _on_stadium_works(cat: String, key: int, label: String, cost: int, weeks: int, effect: Dictionary) -> void:
	if _career.begin_work(cat, key, label, cost, weeks, effect):
		_career.save()
	_show_stadium_screen()

## The SEASON FIXTURES calendar (T2 #13): the manager's full league season, one row per
## round, with the result filled in once played (W green / D neutral / L red) and the next
## fixture flagged. PM98-chrome browse driven by Career.season_fixtures(). RETURN -> hub.
func _show_calendar() -> void:
	var rows: Array = []
	for e in _career.season_fixtures():
		var opp: String = str(GameDB.club(int(e["opp_id"])).get("name", "?")).substr(0, 18)
		var vs := "v " if bool(e["home"]) else "@ "
		var row: Dictionary = {"text": "Wk %2d   %s%s" % [int(e["week"]), vs, opp], "enabled": false}
		if bool(e["played"]):
			var wdl: String = str(e["wdl"])
			row["value"] = "%d-%d  %s" % [int(e["mine"]), int(e["theirs"]), wdl]
			row["accent"] = Color(0.27, 1.0, 0.53) if wdl == "W" else (
				Color(0.86, 0.90, 0.96) if wdl == "D" else Color(0.85, 0.45, 0.42))
		elif bool(e["is_next"]):
			row["value"] = "NEXT"
			row["accent"] = Color(0.98, 0.86, 0.45)
			row["text"] = "> " + str(row["text"])
		else:
			row["value"] = "-"
		rows.append(row)
	if rows.is_empty():
		rows.append({"text": "No league fixtures scheduled.", "enabled": false})
	_mount_browse("%s  -  SEASON FIXTURES" % _career.club_name,
		"%s  -  %d played" % [_career.season, _career.results.size()], rows,
		func(_i: int) -> void: pass,
		func() -> void: _dismiss_career_browse())

## Route a competition key to its screen (the Cup.gd brackets go to the SORTEO /
## knockout views via _show_cup_screen; the one-off finals to their own screens).
func _open_competition(act: String) -> void:
	if act == "calendar":
		_show_calendar()
	elif act == "charity":
		_show_charity_shield()
	elif act == "facup":
		_show_cup_screen(_career.fa_cup, "fa_cup", "F.A. Cup")
	elif act == "lcup":
		_show_cup_screen(_career.league_cup, "league_cup", "Coca-Cola Cup")
	elif act.begins_with("euro:"):
		var key := act.substr(5)
		var b: Dictionary = _career.euro.get(key, {})
		_show_cup_screen(b, key, str(b.get("name", "Europe")))
	elif act == "supercup":
		_show_euro_supercup()
	elif act == "intercont":
		_show_comp_result("intercont", _career.intercontinental, "Tokyo")


## A competition rail chip (RESULTS / knockout views) -> its competition view. The rail
## chip keys are the baked chrome's own order; a chip whose competition the career is not
## in does nothing, exactly as the original's dimmed chips do.
func _open_rail_competition(chip: String) -> void:
	match chip:
		"facup":
			if not _career.fa_cup.is_empty():
				_open_competition("facup")
		"cocacola":
			if not _career.league_cup.is_empty():
				_open_competition("lcup")
		"charity":
			if not _career.charity_shield.is_empty():
				_open_competition("charity")
		"euro":
			if _career.euro.has("european_cup"):
				_open_competition("euro:european_cup")
		"cwc":
			if _career.euro.has("cup_winners_cup"):
				_open_competition("euro:cup_winners_cup")
		"uefa":
			if _career.euro.has("uefa_cup"):
				_open_competition("euro:uefa_cup")
		"supercup":
			if not _career.supercup.is_empty():
				_open_competition("supercup")
		"intercont":
			if not _career.intercontinental.is_empty():
				_open_competition("intercont")

## The trophy art path for a European competition.
func _euro_emblem(key: String) -> String:
	match key:
		"european_cup":
			return "res://art/screens/cup/ligacamp.png"
		"uefa_cup":
			return "res://art/screens/cup/uefa.png"
		_:
			return "res://art/screens/cup/recopa.png"

## Ordered TRUE-XI index (club id -> 11 game_db player dicts, slot 0 GK): each club's own
## shipped XI (club_tactics.json `xi`, the tactic slots' stored player ids) resolved over
## its game_db attr squad. Only fully-resolvable XIs (all 11 ids present with attrs) are
## indexed — all 383 foreign clubs qualify (verified 2026-07-27), so European ties run on
## the byte-exact stat engine instead of the legacy fallback (S5). Game data, rebuilt per
## boot, never persisted; fed to Career like youth_pool. Cached after the first build.
var _true_xis: Dictionary = {}

func _true_xi_index() -> Dictionary:
	if not _true_xis.is_empty():
		return _true_xis
	var f := FileAccess.open("res://data/club_tactics.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var tacts: Dictionary = (parsed as Dictionary).get("clubs", {})
	for c in GameDB.clubs:
		var cid := int(c.get("id", -1))
		var t: Variant = tacts.get(str(cid))
		if not (t is Dictionary):
			continue
		var xi_ids: Variant = (t as Dictionary).get("xi")
		if not (xi_ids is Array) or (xi_ids as Array).size() != 11:
			continue
		var by_id: Dictionary = {}
		for p in c.get("players", []):
			by_id[int(p.get("id", -1))] = p
		var xi: Array = []
		for pid in xi_ids:
			var p: Variant = by_id.get(int(pid))
			if p is Dictionary and (p.get("attrs") is Dictionary) \
					and not (p.get("attrs") as Dictionary).is_empty():
				xi.append(p)
		if xi.size() == 11:
			_true_xis[cid] = xi
	return _true_xis


## Strong foreign clubs (outside the English pyramid) to fill the European fields. The
## international set in game_db has no leagueId; rate each and take the strongest, frozen
## into the Career at draw time. Passed to advance_season at each rollover.
func _euro_pool() -> Array:
	var scored: Array = []
	for c in GameDB.clubs:
		if c.get("leagueId") != null:
			continue                       # English/league clubs aren't the foreign pool
		if str(c.get("country", "")) in SA_COUNTRIES:
			continue                       # South American clubs play the Intercontinental, not Europe
		if (c.get("players", []) as Array).is_empty():
			continue
		var r := MatchEngine.team_ratings(c)
		scored.append({"c": c, "s": float(r["att"]) + float(r["def"]) + float(r["gk"])})
	scored.sort_custom(func(a, b): return a["s"] > b["s"])
	# Enough to fill all three of the original's fields: 24 + 32 + 16 = 72 places, less
	# the domestic seeds, plus headroom for clubs the career has already used.
	var out: Array = []
	for e in scored.slice(0, 96):
		out.append(e["c"])
	return out

## South American country tags in game_db (the game's own PAISES.30 English
## spellings since the 2026-07-06 exact rebuild), for the Intercontinental Cup.
const SA_COUNTRIES := ["ARGENTINA", "BRAZIL", "URUGUAY", "CHILE", "COLOMBIA", "PERU",
	"BOLIVIA", "PARAGUAY", "ECUADOR", "VENEZUELA"]

## The South American champion for the Intercontinental Cup: the strongest South American
## club in game_db (a documented stand-in -- we don't simulate the Copa Libertadores).
func _sa_champion() -> Dictionary:
	var best: Dictionary = {}
	var best_s := -1.0
	for c in GameDB.clubs:
		if not (str(c.get("country", "")) in SA_COUNTRIES):
			continue
		if (c.get("players", []) as Array).is_empty():
			continue
		var r := MatchEngine.team_ratings(c)
		var s := float(r["att"]) + float(r["def"]) + float(r["gk"])
		if s > best_s:
			best_s = s
			best = c
	return best

# ---- season-entry chain (charter #4: TEAMS IN CHAMPIONSHIPS + CHARITY SHIELD
# card + START OF SEASON, audit C1 #7/8/9) ----------------------------------

## The REAL 1996-97 English honours (they seed season 1 exactly as witnessed on
## TEAMS IN CHAMPIONSHIPS orig/06): champions Manchester Utd., F.A. Cup winners
## Chelsea, League Cup winners Leicester, runners-up order Newcastle / Arsenal /
## Liverpool / Aston Villa; European Cup winners Borussia D., Cup Winners' Cup
## winners F.C. Barcelona. Resolved from GameDB by the game's own club names;
## {} if the DB lacks them (sample DB fallback).
func _english_honours_96_97() -> Dictionary:
	var champ := _club_by_name("Manchester Utd.")
	var fa := _club_by_name("Chelsea")
	var lc := _club_by_name("Leicester")
	var ru: Array = []
	for n in ["Newcastle Utd", "Arsenal", "Liverpool", "Aston Villa"]:
		var c := _club_by_name(n)
		if not c.is_empty():
			ru.append(int(c["id"]))
	if champ.is_empty() or fa.is_empty() or ru.is_empty():
		return {}
	return {"champion_id": int(champ["id"]), "fa_winner_id": int(fa["id"]),
		"lc_winner_id": int(lc["id"]) if not lc.is_empty() else -1,
		"runners_up": ru,
		"euro_cup_winner": _club_by_name("Borussia D."),
		"cwc_winner": _club_by_name("F.C. Barcelona")}


## GameDB club dicts for the honours' domestic clubs (frozen-rating seeds for a
## lower-division career whose rosters don't hold them).
func _honour_clubs(hon: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = [int(hon.get("champion_id", -1)), int(hon.get("fa_winner_id", -1)),
		int(hon.get("lc_winner_id", -1))]
	for v in hon.get("runners_up", []):
		ids.append(int(v))
	for id in ids:
		if int(id) != -1:
			var c := GameDB.club(int(id))
			if not c.is_empty():
				out.append(c)
	return out


func _club_by_name(name: String) -> Dictionary:
	for c in GameDB.clubs:
		if str(c.get("name", "")) == name:
			return c
	return {}


## The real 1997 Copa Libertadores champions (Cruzeiro -- witnessed on the
## INTERCONTINENTAL CUP panel, orig/06); the strongest-SA stand-in otherwise.
func _sa_champion_1997() -> Dictionary:
	var c := _club_by_name("Cruzeiro")
	return c if not c.is_empty() else _sa_champion()


func _club_display_name(id: int) -> String:
	if _career != null:
		if _career.club_names.has(id):
			return str(_career.club_names[id])
		if _career.euro_names.has(id):
			return str(_career.euro_names[id])
	return str(GameDB.club(id).get("name", "?"))


## The club's manager for the season sheets: the career manager for the managed
## club, the source-true transcription table (GameDB.manager) otherwise, "" =
## honest blank (un-witnessed clubs).
func _mgr_of(id: int) -> String:
	if _career != null and id == _career.club_id:
		return _career.manager_name
	var m: Variant = GameDB.club(id).get("manager")
	return str(m) if m != null else ""


## Panel entries for the TEAMS IN CHAMPIONSHIPS sheet, from the live career.
func _champs_entries() -> Dictionary:
	var c := _career
	var out: Dictionary = {}
	for key in ["european_cup", "uefa_cup", "cup_winners_cup"]:
		var rows: Array = []
		for id in c.euro_seeds.get(key, []):
			rows.append([_club_display_name(int(id)), _mgr_of(int(id))])
		if key == "european_cup":
			rows.reverse()  # frame truth (orig/06): runners-up listed above the champions
		out[key] = rows
	# Charity Shield pairing (the _play_charity_shield berth rule: the Double ->
	# the league runners-up step up).
	var champ := c.last_champion_id
	var fa := c.last_fa_winner_id
	if fa == -1 or fa == champ:
		fa = int(c.last_runners_up[0]) if not c.last_runners_up.is_empty() else -1
	var sh: Array = []
	for id in [champ, fa]:
		if int(id) != -1:
			sh.append([_club_display_name(int(id)), _mgr_of(int(id))])
	out["charity_shield"] = sh
	var sc: Array = []
	for id in [c.euro_winner_cup, c.euro_winner_cwc]:
		if int(id) != -1:
			sc.append([str(c.euro_winner_names.get(int(id), _club_display_name(int(id)))),
				_mgr_of(int(id))])
	out["supercup"] = sc
	var ic_rows: Array = []
	if c.euro_winner_cup != -1:
		ic_rows.append([str(c.euro_winner_names.get(c.euro_winner_cup, "?")),
			_mgr_of(c.euro_winner_cup)])
		var ic: Dictionary = c.intercontinental
		if not ic.is_empty():
			var sa_id := int(ic["winner_id"])
			if sa_id == c.euro_winner_cup:
				sa_id = int(ic["loser_id"])
			ic_rows.append([str(c.euro_winner_names.get(sa_id, "?")), _mgr_of(sa_id)])
	out["intercontinental"] = ic_rows
	return out


func _show_champs_screen(on_done: Callable) -> void:
	var scr: ChampsScreen = load("res://scenes/ChampsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_champs_entries())
	scr.continue_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		on_done.call())


func _show_shield_card(cs: Dictionary, on_done: Callable) -> void:
	var w := int(cs.get("winner_id", -1))
	var l := int(cs.get("loser_id", -1))
	var card: CharityShieldScreen = load("res://scenes/CharityShieldScreen.gd").new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)
	card.setup(
		{"club": _club_display_name(w), "manager": _mgr_of(w), "club_id": w,
			"pens": str(cs.get("decided", "")) == "pens"},
		{"club": _club_display_name(l), "manager": _mgr_of(l), "club_id": l})
	card.ok_pressed.connect(func() -> void:
		AudioManager.ui_select()
		card.queue_free()
		on_done.call())


## The witnessed band labels for the four English divisions (orig/71 + pro/12).
const DIV_BAND_LABELS := {"Premier League": "PREMIER LEAGUE", "Division One": "1ST DIVISION",
	"Division Two": "2ND DIVISION", "Division Three": "3RD DIVISION"}


## The original's objective CATEGORIES (Champion / U.E.F.A. / Mid Table / Avoid
## Relegation / Promotion, witnessed orig/71 + pro/12) mapped from the app's own
## board rule (Career.objective_for) -- the original's assignment rule is
## un-RE'd, so the categories ride our positions (documented divergence).
func _objective_label(pos: int, total: int, tier: int) -> String:
	var releg := int(SeasonSim.ZONES.get(tier, {"releg": 3}).get("releg", 3))
	if pos >= total - releg - 1:
		return "Avoid Relegation"
	if tier == 1:
		if pos <= 4:
			return "Champion"
		if pos <= 7:
			return "U.E.F.A."
		return "Mid Table"
	if pos <= 3:
		return "Promotion"
	return "Mid Table"


func _season_divisions() -> Array:
	var out: Array = []
	for lg in GameDB.leagues:
		var lid := str(lg["id"])
		var clubs := GameDB.clubs_in_league(lid)
		clubs.sort_custom(func(a, b): return str(a["name"]) < str(b["name"]))
		var tier := FinanceModel.tier_of({"leagueId": lid}, GameDB.leagues)
		var total := clubs.size()
		var rows: Array = []
		for cl in clubs:
			var cid := int(cl["id"])
			var user: bool = _career != null and cid == _career.club_id \
				and lid == _career.league_id
			var mgr := _career.manager_name if user else _mgr_of(cid)
			# O1: the board objective is a CATEGORY the game ships per club, not a
			# position the app derives. club_economy.json carries the witnessed
			# START OF SEASON label for 92 of the 94 English records (merged onto the
			# club dict by GameDB._apply_club_economy), so use it whenever it exists and
			# keep the position-derived label only as the fallback for the rest.
			var label := str(cl.get("objective", ""))
			if label == "":
				var pos: int = _career.objective_pos if user \
					else int(Career.objective_for(cid, lid, clubs, GameDB.leagues)["pos"])
				label = _objective_label(pos, total, tier)
			rows.append([str(cl["name"]), mgr, label, user])
		out.append({"title": str(DIV_BAND_LABELS.get(str(lg["name"]), lg["name"])), "rows": rows})
	return out


func _show_season_start(on_done: Callable) -> void:
	var scr: SeasonStartScreen = load("res://scenes/SeasonStartScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var start_tab := 0
	for i in GameDB.leagues.size():
		if str(GameDB.leagues[i]["id"]) == _career.league_id:
			start_tab = i
	scr.setup(_season_divisions(), start_tab)
	scr.continue_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		on_done.call())


## The Charity Shield on the ORIGINAL's own screen (champions v F.A. Cup winners, a single
## match at Wembley — the ground the real frame prints).
func _show_charity_shield() -> void:
	_show_comp_result("charity", _career.charity_shield, "Wembley")


## RESULTS -> CHARITY SHIELD / INTERCONTINENTAL CUP on the original's own screen
## (CompResultScreen; MANAGER.EXE FUN_004717a0 == FUN_0048daf0 bar the title and the
## trophy). `ground` is the fixed venue the real frame prints for that competition —
## Wembley for the shield, Tokyo for the Intercontinental Cup.
func _show_comp_result(kind: String, res: Dictionary, ground: String) -> void:
	var scr: CompResultScreen = load("res://scenes/CompResultScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var m := {"stadium": ground}
	if not res.is_empty():
		var home := int(res.get("home_id", -1))
		var away := int(res.get("away_id", -1))
		var win := int(res.get("winner_id", -1))
		m["home"] = _comp_side(home)
		m["away"] = _comp_side(away)
		if res.has("hg") and res.has("ag"):
			m["hg"] = int(res["hg"])
			m["ag"] = int(res["ag"])
		if win != -1:
			m["winner"] = _comp_side(win)
	scr.setup(kind, m, _match_header())
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())


## RESULTS -> Euro. Superc. on the original's own screen. The Supercup is a TWO-LEGGED
## tie (FUN_004a1820 mounts the 1ST LEG / 2ND LEG panel widget FUN_0046a110, two match
## records 0xbc apart), so it does NOT go through _show_comp_result -- that screen is the
## single-match CHARITY / INTERCONT builder. docs/re/euro_supercup_screen_re.md.
func _show_euro_supercup() -> void:
	var res: Dictionary = _career.supercup
	var scr: EuroSupercupScreen = load("res://scenes/EuroSupercupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_supercup_view(res), _match_header())
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())


## The Supercup tie as EuroSupercupScreen wants it. `home_id` is the Cup Winners' Cup
## holder, who hosts the FIRST leg (witnessed 1997-98: leg 1 Camp Nou, leg 2 Westfalen);
## the second leg is the same pair reversed, and each leg's ground is the home club's own
## `stadium` string out of game_db.
func _supercup_view(res: Dictionary) -> Dictionary:
	if res.is_empty():
		return {"legs": []}
	var h := int(res.get("home_id", -1))
	var a := int(res.get("away_id", -1))
	var side_h := _comp_side(h)
	var side_a := _comp_side(a)
	var leg1 := {"stadium": _club_ground(h), "home": side_h, "away": side_a}
	var leg2 := {"stadium": _club_ground(a), "home": side_a, "away": side_h}
	if res.has("leg1_hg") and res.has("leg1_ag"):
		leg1["hg"] = int(res["leg1_hg"])
		leg1["ag"] = int(res["leg1_ag"])
		# The stored leg-2 pair is still home-first-leg-side first; on the screen the
		# second leg is drawn with the away club on top, so the two swap.
		leg2["hg"] = int(res.get("leg2_ag", 0))
		leg2["ag"] = int(res.get("leg2_hg", 0))
	var out := {"legs": [leg1, leg2]}
	var win := int(res.get("winner_id", -1))
	if win != -1 and res.has("leg1_hg"):
		out["winner"] = _comp_side(win)
	return out


## A club's own ground name out of game_db (the EQUIPOS string), "" if unknown.
func _club_ground(club_id: int) -> String:
	var rec: Dictionary = GameDB.club(club_id)
	return str(rec.get("stadium", "")) if not rec.is_empty() else ""


## One club as CompResultScreen wants it: the display name, the id its kit is drawn from
## and the PAISES index its country flag is drawn from.
func _comp_side(club_id: int) -> Dictionary:
	var rec: Dictionary = GameDB.club(club_id)
	var code: int = int(rec.get("countryCode", -1)) if not rec.is_empty() else -1
	return {"name": _cup_name(club_id), "club_id": club_id, "flag": code}

## The European GROUP phase, on the old placeholder chrome. The original's group screen is
## NOT witnessed in any capture we hold, so this stays a placeholder — flagged in
## docs/re/cupdraw_screen_re.md — rather than being drawn on the SORTEO screen, which is a
## knockout-draw screen. Every knockout round goes through `_show_cup_screen`.
## RESULTS -> EURO. LEAGUE, the group phase, on the original's own screen
## (docs/re/euro_league_screen_re.md). `gi` is the group index and `rnd` the 1-based
## matchday the ROUND paginator sits on; both are re-entered on every tap so the screen
## stays a pure view over Cup.gd's bracket.
func _show_euro_group_screen(b: Dictionary, gi := 0, rnd := 0) -> void:
	var groups: Array = Cup.group_tables(b)
	if groups.is_empty():
		return
	gi = clampi(gi, 0, groups.size() - 1)
	var grp: Dictionary = groups[gi]
	var played := int((b.get("group_stage", {}) as Dictionary).get("matchdays_played", 0))
	var n_md := int((b.get("group_stage", {}) as Dictionary).get("n_matchdays", 6))
	if rnd <= 0:
		rnd = maxi(1, played)
	rnd = clampi(rnd, 1, n_md)

	var rows: Array = []
	for row in Cup.ranked_table(grp):
		var cid := int(row.get("id", -1))
		rows.append({"name": _cup_name(cid), "club_id": cid,
			"flag": int(GameDB.club(cid).get("countryCode", -1)),
			"pts": row.get("pts", 0), "p": row.get("p", 0), "w": row.get("w", 0),
			"d": row.get("d", 0), "l": row.get("l", 0),
			"gf": row.get("gf", 0), "ga": row.get("ga", 0)})

	# The original draws the matchday's fixtures whether or not they are played: an
	# unplayed round keeps the kits, the bars and the empty score boxes (witnessed
	# 2026-07-26, 03_group_A_round5_unplayed.png).
	var results: Array = []
	var md_results: Array = grp.get("results", [])
	var fixtures: Array = Cup.group_fixtures(b, gi, rnd)
	for i in fixtures.size():
		var f: Dictionary = fixtures[i]
		var r := {"home_id": int(f["h"]), "home": _cup_name(int(f["h"])),
			"away_id": int(f["a"]), "away": _cup_name(int(f["a"])), "played": false,
			"hg": 0, "ag": 0}
		if rnd - 1 < md_results.size():
			var played_md: Array = md_results[rnd - 1]
			if i < played_md.size():
				var pr: Dictionary = played_md[i]
				r["home_id"] = int(pr["h"])
				r["home"] = _cup_name(int(pr["h"]))
				r["away_id"] = int(pr["a"])
				r["away"] = _cup_name(int(pr["a"]))
				r["hg"] = int(pr["hg"])
				r["ag"] = int(pr["ag"])
				r["played"] = true
		results.append(r)

	var scr: EuroGroupScreen = load("res://scenes/EuroGroupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_match_header(), EuroGroupScreen.LETTERS[gi], rnd, n_md, rows, results)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.group_selected.connect(func(idx: int) -> void:
		scr.queue_free()
		_show_euro_group_screen(b, idx, rnd))
	scr.round_changed.connect(func(delta: int) -> void:
		scr.queue_free()
		_show_euro_group_screen(b, gi, rnd + delta))


## The original's SORTEO screen as a full-screen overlay: the latest round's draw, on the
## real chrome, around the competition's own trophy strip and the lottery drum. `key` picks
## that strip (CupDrawScreen.STRIPS); `title` is the name as MANAGER.EXE spells it. Built
## from a Cup.gd bracket. CONTINUE (or FINISH) dismisses it.
func _show_cup_screen(b: Dictionary, key: String, title: String) -> void:
	# The European GROUP phase is not a knockout draw: it has its own screen now, rebuilt
	# from the original's frames (docs/re/euro_league_screen_re.md).
	if not Cup.group_tables(b).is_empty() and (b.get("rounds", []) as Array).is_empty():
		_show_euro_group_screen(b)
		return
	# A knockout phase the original has a built layout for has its own screen too
	# (docs/re/knockout_views_re.md): the LIST at nine ties or more, the BRACKET at
	# four, the SEMIFINAL cards at two and the FINAL at one -- the last two only for
	# competitions whose chrome is witnessed (cards: euro + cocacola; final: euro).
	# The kit list (5-8 ties) and the unwitnessed cards/final competitions still fall
	# through to the SORTEO card.
	if _knockout_phases(b).size() > 0 and KNOCKOUT_RAIL.has(key):
		var last: int = _knockout_phases(b).size() - 1
		var n: int = (_knockout_ties(b, last) as Array).size()
		var chip := str(KNOCKOUT_RAIL[key])
		if n >= KnockoutScreen.MIN_LIST_TIES or n == KnockoutScreen.BRACKET_TIES \
				or (n == KnockoutScreen.CARDS_TIES and KnockoutScreen.cards_available(chip)) \
				or (n == KnockoutScreen.FINAL_TIES and KnockoutScreen.final_available(chip)):
			_show_knockout_screen(b, key, last)
			return
	var scr: CupDrawScreen = load("res://scenes/CupDrawScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var v := _cup_draw_view(b)
	scr.setup(key, title, v["round"], v["ties"], int(v["total"]), v["legs"],
		_career.club_id, _career.manager_name)
	_wire_cup_draw_rows(scr, v["ties"], v["legs"])
	scr.continue_pressed.connect(func() -> void: scr.queue_free())
	scr.finish_pressed.connect(func() -> void: scr.queue_free())


## Cup.gd bracket key -> the competition rail chip the original lights for it.
const KNOCKOUT_RAIL := {
	"fa_cup": "facup", "league_cup": "cocacola", "european_cup": "euro",
	"cup_winners_cup": "cwc", "uefa_cup": "uefa",
}


## The phases the paginator walks: every round PLAYED, then the round that has been DRAWN
## but not yet played, if there is one. That is the original's own order -- the next round
## is drawn the moment the previous resolves (docs/re/knockout_views_re.md).
func _knockout_phases(b: Dictionary) -> Array:
	var out: Array = []
	for r in b.get("rounds", []):
		out.append(r)
	var pd: Dictionary = b.get("pending_draw", {})
	if not pd.is_empty():
		out.append({"label": str(pd.get("label", "")), "pending": pd})
	return out


## One phase's ties as KnockoutScreen rows. Byes are left out, as they are on the SORTEO:
## the original's cup fields are large enough that no witnessed draw has one, so their
## rendering is unknown and is not invented.
func _knockout_ties(b: Dictionary, phase: int) -> Array:
	var phases := _knockout_phases(b)
	if phase < 0 or phase >= phases.size():
		return []
	var ph: Dictionary = phases[phase]
	var mine: int = _career.club_id
	var out: Array = []
	if ph.has("pending"):
		var pd: Dictionary = ph["pending"]
		var players: Array = pd.get("players", [])
		var two := int(pd.get("round_legs", 1)) >= 2
		var i := 0
		while i + 1 < players.size():
			var h := int(players[i])
			var a := int(players[i + 1])
			out.append({"home": _cup_name(h), "away": _cup_name(a), "winner": -1,
				"mine": h == mine or a == mine,
				"home_id": h, "away_id": a,
				"home_flag": int(GameDB.club(h).get("countryCode", -1)),
				"away_flag": int(GameDB.club(a).get("countryCode", -1)),
				"home_ground": str(GameDB.club(h).get("stadium", "")),
				"away_ground": str(GameDB.club(a).get("stadium", "")),
				"two_legged": two,
				"cells": [["", ""], ["", ""], ["", ""]] if two else [["", ""], ["", ""]]})
			i += 2
		return out
	for tie in ph.get("ties", []):
		if tie.get("bye", false):
			continue
		var h := int(tie["home_id"])
		var a := int(tie.get("away_id", -1))
		var w := int(tie.get("winner_id", -1))
		var cells: Array = []
		if tie.get("two_legged", false):
			# The second leg is printed with the sides swapped -- its host first.
			cells = [[str(int(tie["leg1_hg"])), str(int(tie["leg1_ag"]))],
				[str(int(tie["leg2_ag"])), str(int(tie["leg2_hg"]))],
				[str(int(tie["h_agg"])), str(int(tie["a_agg"]))]]
		else:
			var replay: Array = ["", ""]
			if tie.has("replay_hg"):
				# The REPLAY column with ink in it is not witnessed -- the one played
				# frame in hand leaves it empty on every level tie. Printed here in the
				# same grammar as RES., and flagged as unwitnessed in the RE doc.
				replay = [str(int(tie["replay_ag"])), str(int(tie["replay_hg"]))]
			cells = [[str(int(tie["hg"])), str(int(tie["ag"]))], replay]
		out.append({"home": _cup_name(h), "away": _cup_name(a),
			"winner": (0 if w == h else (1 if w == a else -1)),
			"mine": h == mine or a == mine,
			"home_id": h, "away_id": a,
			"home_flag": int(GameDB.club(h).get("countryCode", -1)),
			"away_flag": int(GameDB.club(a).get("countryCode", -1)),
			"home_ground": str(GameDB.club(h).get("stadium", "")),
			"away_ground": str(GameDB.club(a).get("stadium", "")),
			"two_legged": bool(tie.get("two_legged", false)),
			"cells": cells})
	return out


## RESULTS -> a cup at a knockout phase, on the original's own list layout. Re-entered on
## every tap, so the screen stays a pure view over Cup.gd's bracket.
func _show_knockout_screen(b: Dictionary, key: String, phase: int) -> void:
	var phases := _knockout_phases(b)
	if phases.is_empty():
		return
	phase = clampi(phase, 0, phases.size() - 1)
	var ties := _knockout_ties(b, phase)
	var two_legged := (ties.size() > 0
		and ((ties[0] as Dictionary).get("cells", []) as Array).size() >= 3)
	var scr: KnockoutScreen = load("res://scenes/KnockoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# The original switches presentation with the size of the round, per phase: the
	# 4-tie bracket, the 2-tie SEMIFINAL cards, the 1-tie FINAL, else the list (the
	# 5-8-tie kit list and the unwitnessed cards/final competitions fall back to the
	# list form / SORTEO, docs/re/knockout_views_re.md).
	var chip := str(KNOCKOUT_RAIL.get(key, "euro"))
	var layout := "list"
	if ties.size() == KnockoutScreen.BRACKET_TIES:
		layout = "bracket"
	elif ties.size() == KnockoutScreen.CARDS_TIES and KnockoutScreen.cards_available(chip):
		layout = "cards"
	elif ties.size() == KnockoutScreen.FINAL_TIES and KnockoutScreen.final_available(chip):
		layout = "final"
		# The FINAL's neutral ground, recorded on the draw (Cup._pair_round).
		var ph: Dictionary = phases[phase]
		var vid := int((ph.get("pending", {}) as Dictionary).get("venue_id",
			ph.get("venue_id", -1)))
		if not ties.is_empty():
			ties[0]["venue"] = str(GameDB.club(vid).get("stadium", "")) if vid >= 0 else ""
	# The phase plate's case is witnessed per family: the list/bracket plates are
	# UPPERCASE everywhere, the cards/final plates keep the euro competitions' own
	# mixed case ("Semifinals" / "Final") and uppercase the domestic ones
	# ("SEMIFINALS", the Coca-Cola witness).
	var disp := str((phases[phase] as Dictionary).get("label", ""))
	if not (layout in ["cards", "final"]
			and key in ["european_cup", "cup_winners_cup", "uefa_cup"]):
		disp = disp.to_upper()
	scr.setup(_match_header(), chip, disp, two_legged, ties,
		phase > 0, phase < phases.size() - 1, 0, layout)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.phase_changed.connect(func(delta: int) -> void:
		scr.queue_free()
		_show_knockout_screen(b, key, phase + delta))
	scr.competition_selected.connect(func(chip: String) -> void:
		scr.queue_free()
		_open_rail_competition(chip))


## Answer the SORTEO's row taps with the original's own tie-detail card: each club's
## name over its manager's, and the two legs' GROUNDS beside the MATCH / REPLAY (or
## 1ST LEG / 2ND LEG) plates. The first plate names the FIRST-named club's ground and the
## second the other's, which is what both witnessed cards show (The Pulse Stadium then
## Old Trafford for Bradford City v Manchester Utd.; Camp Nou then Wildpark for
## F.C. Barcelona v Karlsruher).
func _wire_cup_draw_rows(scr: CupDrawScreen, ties: Array, _legs: Array) -> void:
	scr.tie_selected.connect(func(row: int) -> void:
		if row < 0 or row >= ties.size():
			return
		var tie: Dictionary = ties[row]
		scr.show_tie({
			"home": _cup_draw_side(int(tie.get("home_id", -1)), str(tie.get("home", ""))),
			"away": _cup_draw_side(int(tie.get("away_id", -1)), str(tie.get("away", ""))),
		}, row))


func _cup_draw_side(club_id: int, fallback: String) -> Dictionary:
	var club := GameDB.club(club_id)
	return {
		"club": _cup_name(club_id) if club_id >= 0 else fallback,
		"club_id": club_id,
		"manager": _mgr_of(club_id),
		"stadium": str(club.get("stadium", "")),
	}


## The unprompted SORTEO the original raises when a knockout round is drawn (REFRUN R4).
## R13 (witnessed): after the penultimate league round the original presents the
## finished divisions' FINAL tables — blank club plate, the division in the badge —
## before the last round is played (p0610/p0638). Queued by
## Career._queue_division_finals; presented here at the head of the post-week chain,
## one LeagueTableScreen per tier, lowest first.
func _pop_division_finals(after: Callable) -> void:
	if _career == null or (_career.pending_division_finals as Array).is_empty():
		if after.is_valid():
			after.call()
		return
	var t := int((_career.pending_division_finals as Array).pop_front())
	_career.save()
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# Blank manager plate — the original shows no manager in this mode (R13).
	scr.setup(_career.standings_for(t), _career.club_name, _career.season,
		"Week %d" % _career.week, t, _career.club_id, "")
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_pop_division_finals(after))


## Rides the same post-week card chain the channelTV card and the monthly awards do,
## because that is how the original raises it: over the hub, with no menu step. FINISH
## and CONTINUE both dismiss it. The card plays the one-by-one reveal (p0125->p0131:
## drum spinning, each club on the hand's slip, park on BOMBO00) — the 2026-07-25 film
## that "did not run a draw animation" had filmed an ALREADY-FINISHED draw, parked,
## which is exactly the post-reveal state.
func _pop_cup_draw(after: Callable) -> void:
	if _career == null or (_career.pending_cup_draws as Array).is_empty():
		if after.is_valid():
			after.call()
		return
	var d: Dictionary = (_career.pending_cup_draws as Array).pop_front()
	var scr: CupDrawScreen = load("res://scenes/CupDrawScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var ties: Array = d.get("ties", [])
	scr.setup(str(d.get("key", "fa_cup")), str(d.get("title", "")), str(d.get("round", "")),
		ties, int(d.get("total", ties.size())), d.get("legs", ["MATCH", "REPLAY"]),
		_career.club_id, _career.manager_name)
	scr.reveal()   # the live, unprompted card plays the draw; hub re-views stay parked
	_wire_cup_draw_rows(scr, ties, d.get("legs", []))
	var dismiss := func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_pop_cup_draw(after)        # the week can draw more than one competition
	scr.continue_pressed.connect(dismiss)
	scr.finish_pressed.connect(dismiss)


## The SORTEO payload for a Cup.gd bracket: the LATEST round's ties in draw order, its
## plate label and the bottom-left leg plates.
##
## The plate label is the EXE's own uppercase form (0x2523fc-0x252428: FINAL / QTR FINALS /
## ROUND 4..1). Cup.gd's own label is uppercased and normalised into that set; a label the
## block does not carry (Round 5, Semifinals) is uppercased as-is rather than invented into
## one of the SEMIFINAL 1 / SEMIFINAL 2 plates, whose selection rule is not reversed. The
## per-leg suffix Cup.gd appends ("- 1st") is dropped: the original carries the leg on the
## bottom-left plates, not the round plate.
##
## Byes are left out of the MATCHES list and out of the tie count — the original's cup
## fields are large enough that no witnessed draw has one, so their rendering is unknown.
func _cup_draw_view(b: Dictionary) -> Dictionary:
	var out := {"round": "", "ties": [], "total": 0, "legs": ["MATCH", "REPLAY"]}
	var rounds: Array = b.get("rounds", [])
	if rounds.is_empty():
		return out
	var last: Dictionary = rounds[-1]
	out["legs"] = Cup.draw_leg_plates(b)
	out["round"] = Cup.draw_round_plate(b)
	var ties: Array = []
	for tie in last.get("ties", []):
		if tie.get("bye", false):
			continue
		ties.append({"home": _cup_name(int(tie["home_id"])),
			"away": _cup_name(int(tie.get("away_id", -1))),
			"home_id": int(tie["home_id"]), "away_id": int(tie.get("away_id", -1))})
	out["ties"] = ties
	out["total"] = ties.size()
	return out

## A club name from the live division (falls back to GameDB / a placeholder).
func _cup_name(id: int) -> String:
	if _career.club_names.has(id):
		return str(_career.club_names[id])
	return str(GameDB.club(id).get("name", "?"))

## "WINNER bt LOSER  2-1 (replay)" / "WINNER bt LOSER  3-1 agg" / "CLUB  (bye)" for a
## Cup.gd tie, winner first.
func _cup_tie_line(tie: Dictionary) -> String:
	if tie.get("bye", false):
		return "%s  (bye)" % _cup_name(int(tie["home_id"]))
	var w := int(tie["winner_id"])
	var l := int(tie["loser_id"])
	var decided: String = str(tie.get("decided", ""))
	if tie.get("two_legged", false):
		var hi := maxi(int(tie["h_agg"]), int(tie["a_agg"]))
		var lo := mini(int(tie["h_agg"]), int(tie["a_agg"]))
		var t := " agg"
		match decided:
			"pens":
				t = " agg pens"
			"away_goals":
				t = " agg (a.g.)"
			"aet":
				t = " agg aet"
		return "%s bt %s  %d-%d%s" % [_cup_name(w), _cup_name(l), hi, lo, t]
	var a: int
	var b: int
	if decided == "replay" or decided == "pens":
		a = int(tie.get("replay_hg", tie["hg"]))
		b = int(tie.get("replay_ag", tie["ag"]))
	else:
		a = int(tie["hg"])
		b = int(tie["ag"])
	var hi := maxi(a, b)
	var lo := mini(a, b)
	var tag := " (replay)" if decided == "replay" else (" (pens)" if decided == "pens" else "")
	return "%s bt %s  %d-%d%s" % [_cup_name(w), _cup_name(l), hi, lo, tag]

## The manager's scoreline string for a tie (decisive leg / aggregate, his goals first).
func _cup_score_for(tie: Dictionary, cid: int) -> String:
	var decided: String = str(tie.get("decided", ""))
	if tie.get("two_legged", false):
		var mine_a := int(tie["h_agg"]) if int(tie["home_id"]) == cid else int(tie["a_agg"])
		var theirs_a := int(tie["a_agg"]) if int(tie["home_id"]) == cid else int(tie["h_agg"])
		return "%d-%d agg%s" % [mine_a, theirs_a, " pens" if decided == "pens" else ""]
	var hg: int
	var ag: int
	if decided == "replay" or decided == "pens":
		hg = int(tie.get("replay_hg", tie["hg"]))
		ag = int(tie.get("replay_ag", tie["ag"]))
	else:
		hg = int(tie["hg"])
		ag = int(tie["ag"])
	var mine := hg if int(tie["home_id"]) == cid else ag
	var theirs := ag if int(tie["home_id"]) == cid else hg
	var tag := " (r)" if decided == "replay" else (" pens" if decided == "pens" else "")
	return "%d-%d%s" % [mine, theirs, tag]

## Route a MENUPRINCIPAL icon/button tap from the persistent hub. The hub stays mounted:
## art overlays (table/line-up/finance/board/stadium/buy) mount ABOVE it and tap-dismiss
## back to it; still-green sub-flows (tactics/sell/results) are pushed and hide the hub
## via _set_view (re-shown on Back); hub feedback (save / bye / signings) raises the
## original's modal "PREMIER MANAGER 98" alert box on the hub (docs/re/alert_box_re.md);
## CONTINUE plays the week (or opens end-of-season when the campaign is over); EXIT
## raises the witnessed leave-championship confirm (Yes -> the TITLE screen).
func _menu_action(action: String, scr: MenuScreen) -> void:
	AudioManager.ui_select()
	match action:
		"exit": scr.confirm_exit()
		"save":
			_show_save_dialog()
		"news": _show_club_news()
		"staff": _show_staff_screen()
		"fixtures": _show_fixtures_screen()
		"opponent": _show_opponent(scr)
		"continue":
			if _career.season_over():
				_push(_show_end_of_season)
			elif _next_fixture().is_empty():
				_career_advance()          # bye week: no match -> no MATCH OPTIONS
			elif _xi_has_unavailable():
				# WITNESSED (matchday_flow_witness_re §3): the XI-validity gate
				# fires BEFORE the modal/launch — CONTINUE with a banned/injured
				# player in the saved XI raises the standard alert and the week
				# does NOT advance until the LINE-UP is fixed.
				scr.alert("The initial line-up is not correct. A player is either banned or injured.")
			elif not _career.match_options_shown:
				# WITNESSED (matchday_flow_witness_re §1): MATCH OPTIONS raises on
				# the career's FIRST match only, over the undimmed hub (frame 60).
				# Every later CONTINUE goes straight into the stored presentation.
				_show_matchday_options()
			else:
				_career_advance()
		"table": _show_league_table_screen()
		"lineup": _show_lineup_screen()
		"finance": _show_finance_screen()
		"board": _show_directiva_screen()
		"stadium": _show_stadium_screen()
		"buy": _show_transfer_screen()
		"tactics": _show_tactics_board_screen()
		# The hub PLAYERS button (VENDE icon, action "sell") opens the real SQUAD MANAGEMENT
		# (PLANTILLA) screen, as the original does -- your squad, where a player tap raises his
		# PLAYER INFORMATION (RENEW / TRANSFER / SACK; TRANSFER = list him for sale). Was the
		# invented `_show_transfers` BrowseScreen menu (APP_VS_SPEC_AUDIT B1 SUBSTITUTE / B2
		# orphaned SquadScreen).
		"sell": _show_squad_screen()
		"results": _show_results_screen()
		# Top dropdown bar: monitor icon -> MATCH OPTIONS (view-mode settings dialog),
		# headphones icon -> the audio OPTIONS panel (MANAGER.INI volumes/transitions).
		"match_options": _show_match_options(scr)
		"options_audio": _show_audio_options(scr)

## MATCH OPTIONS (hub dropdown monitor icon): the settings dialog where the view mode
## (WATCH/HIGHLIGHTS/BRIEF/RESULTS) is chosen and switched, like the original PC version.
## Opens showing the currently-stored mode; OK persists it (AudioManager), CANCEL discards.
## The stored mode then drives how the next match presents (_open_match).
func _show_match_options(_scr: MenuScreen) -> void:
	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	opt.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opt)
	opt.setup(AudioManager.match_view_mode, AudioManager.match_settings())
	opt.confirmed.connect(func(m: String, settings: Dictionary) -> void:
		AudioManager.set_match_view_mode(m)
		AudioManager.set_match_settings(settings)
		opt.queue_free())
	opt.cancelled.connect(func() -> void: opt.queue_free())

## Matchday MATCH OPTIONS (charter #5, frame 60; witnessed §1-2): raised by the
## hub CONTINUE on the career's FIRST match only. A view-mode tap (or OK)
## persists the choice and LAUNCHES the week immediately; CANCEL dismisses
## back to the hub without advancing (re-CONTINUE re-opens it).
func _show_matchday_options() -> void:
	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	opt.set_anchors_preset(Control.PRESET_FULL_RECT)
	opt.launch_on_select = true
	add_child(opt)
	opt.setup(AudioManager.match_view_mode, AudioManager.match_settings())
	opt.confirmed.connect(func(m: String, settings: Dictionary) -> void:
		AudioManager.set_match_view_mode(m)
		AudioManager.set_match_settings(settings)
		_career.match_options_shown = true
		opt.queue_free()
		_career_advance())
	opt.cancelled.connect(func() -> void: opt.queue_free())

## OPTIONS (hub dropdown headphones icon): the audio panel (MANAGER.INI music/SFX/
## transitions). Self-contained — it reads/writes AudioManager and dismisses on OK.
func _show_audio_options(_scr: MenuScreen) -> void:
	var op: OptionsPanel = load("res://scenes/OptionsPanel.gd").new()
	op.set_anchors_preset(Control.PRESET_FULL_RECT)
	# THREE UP FRONT arming readout (Mats QA 2026-07-27: the cheat's state was
	# invisible — nothing distinguished armed from disarmed). The natural-FW count
	# of the XI that would actually be fielded this week; >= 3 = the forwards
	# trigger is armed. Drawn in the cheat row's own declared band.
	if _career != null:
		var fw := 0
		for p in _career._mgr_featured_xi():
			if str((p as Dictionary).get("pos", "")) == "FW":
				fw += 1
		op.xi_fw = fw
	add_child(op)
	op.closed.connect(func() -> void: op.queue_free())

## OPPONENT: the real VIEW RIVAL (VERRIVAL) scouting screen for the manager's next opponent
## (docs/re/rival_screen_re.md; RivalScreen.gd) -- the opponent XI, team rating and formation,
## with the report DEPTH gated by the manager's ASSISTANT (none -> the "hire an Assistant"
## message). Replaces the WRONG-SCREEN DATA BASE browser (APP_VS_SPEC_AUDIT B1). A bye week
## has no opponent, so it just reports that.
func _show_opponent(scr: MenuScreen) -> void:
	var fx := _next_fixture()
	if fx.is_empty():
		scr.alert("No match this week (bye)")
		return
	var home: bool = int(fx[0]) == _career.club_id
	var opp_id: int = int(fx[1]) if home else int(fx[0])
	_show_rival_screen(_club_with_roster(opp_id))

## Mount the VIEW RIVAL screen over the hub for `rival` (a roster-loaded club). RETURN
## dismisses; TACTICS opens the manager's own TEAM TACTICS modal (as the original does).
func _show_rival_screen(rival: Dictionary) -> void:
	var scr: RivalScreen = load("res://scenes/RivalScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var q := Staff.assistant_quality(_career.staff)
	var ass := Staff.members_in_role(_career.staff, Staff.ASSISTANT)
	var ass_name: String = str(ass[0].get("name", "")) if not ass.is_empty() else ""
	scr.setup(rival, _mgr_club(), q, ass_name, _career.league_name, _career.season,
		_career.week + 1, _match_header(), _tactics())
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_board_screen())

## "vs Arsenal" / "at Chelsea" / "bye" for the manager's next match.
func _menu_next_match() -> String:
	var fx := _next_fixture()
	if fx.is_empty():
		return "No match this week (bye)"
	var home: bool = int(fx[0]) == _career.club_id
	var opp_id: int = int(fx[1]) if home else int(fx[0])
	var opp := GameDB.club(opp_id)
	return "Next: %s %s" % ["vs" if home else "at", opp.get("name", "?")]

## The MENUPRINCIPAL RESULTS view (MARCA) — the source-true matches-on-date screen
## (ResultsScreen.gd, walkthrough frame 038; docs/re/results_screen_re.md), driven by the
## real Career fixtures/results/week/club data. Mounts as an overlay over whatever raised it
## (the hub, or THE CALENDAR's RESULTS button), so RETURN (back_pressed) frees it and re-raises
## the prior screen beneath. Replaces the rejected BrowseScreen W/D/L list (APP_VS_SPEC_AUDIT B1).
func _show_results_screen() -> void:
	var scr: ResultsScreen = load("res://scenes/ResultsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_match_header(), _career.league_name, _career.season,
		_career.fixtures, _career.results, _career.week, _career.club_id, _career.club_names)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	# The rail is the original's own door into the cup / Europe views (audit 2026-07-26:
	# they shipped unreachable). A chip for a competition the career is not in is ignored,
	# as the original's dimmed chips are.
	scr.competition_selected.connect(func(chip: String) -> void:
		_open_rail_competition(chip))

## The MENUPRINCIPAL FIXTURES icon opens the source-true "THE CALENDAR" (EMPAREJAMIENTOS)
## screen (FixturesScreen.gd, walkthrough frame 051; docs/re/fixtures_screen_re.md), replacing
## the rejected BrowseScreen "COMPETITIONS"/"SEASON FIXTURES" SUBSTITUTE (APP_VS_SPEC_AUDIT B1).
## Mounts over the hub; RETURN frees it, RESULTS/LEAGUE TABLES open those screens over it (so
## their RETURN re-raises the calendar). Manager-mode barra (frame 051 shows the manager plaques).
func _show_fixtures_screen() -> void:
	var scr: FixturesScreen = load("res://scenes/FixturesScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var hdr := _match_header()
	hdr["mode"] = "manager"
	hdr["top"] = _career.manager_name
	hdr["bottom"] = PMChrome.title_case_name(_career.club_name)
	hdr["club_id"] = _career.club_id
	# TODAY = a pending preseason friendly's REAL witnessed date, else the current league round
	# (inferred date model — see _league_round_date / calendar gap in the RE doc).
	var today := {}
	var pf := _career.pending_friendly()
	if not pf.is_empty():
		today = _iso_ymd(str(pf.get("date", "")))
	if today.is_empty():
		today = _league_round_date(_career.week)
	scr.setup(hdr, _calendar_entries(), today)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.results_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_results_screen())
	scr.tables_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_league_table_screen())

## The dated fixture entries THE CALENDAR consumes, built from live Career state.
## SOURCE-DOCTRINE NOTE (docs/re/fixtures_screen_re.md gap #4): the real 1997-98 fixture
## SCHEDULE + per-round calendar DATES live in the engine container PCF5DAT.PKF, which is NOT
## enumerable (SOURCE_INVENTORY §5 GAP#1); the app's own schedule is SeasonSim-generated. So
## per-round DATES are NOT source-provable and are NOT invented into the Career model. Here:
##   - preseason friendlies carry their REAL witnessed August dates (1/4/6/8 AUG 1997, assigned
##     in _begin_career from the walkthrough) -> placed source-true on the AUG sheet;
##   - league rounds are placed WEEK-ORDERED by the same inferred weekly cadence the (already
##     shipped) RESULTS screen uses (season-start 9 AUG + round*7 days). The exact calendar-DAY
##     of each league round is the honest gap; the WEEK STRUCTURE (one round per week) is the
##     game's own cadence. Cups/Charity/Europe carry no derivable date yet -> omitted (gap).
func _calendar_entries() -> Array:
	var out: Array = []
	var cid := _career.club_id
	for pr in _career.preseason_rivals:
		var ymd := _iso_ymd(str((pr as Dictionary).get("date", "")))
		if ymd.is_empty():
			continue
		var rid := int((pr as Dictionary).get("club_id", -1))
		var at_home := bool((pr as Dictionary).get("home", false))
		out.append(_calendar_entry(ymd, "preseason", "Preseason", "Preparation",
			cid if at_home else rid, rid if at_home else cid))
	for e in _career.season_fixtures():
		var ymd := _league_round_date(int(e["round"]))
		var home := bool(e["home"])
		out.append(_calendar_entry(ymd, "league", _career.league_name, "Week %d" % int(e["week"]),
			cid if home else int(e["opp_id"]), int(e["opp_id"]) if home else cid))
	return out

## One calendar entry ({y,m,d, comp, comp_name, round, home_id, away_id, home, away, home_flag,
## away_flag}); names from the live club_names (GameDB fallback for foreign friendly rivals),
## flags from the club's real countryCode (BANDERAS id).
func _calendar_entry(ymd: Dictionary, comp: String, comp_name: String, round_lbl: String,
		home_id: int, away_id: int) -> Dictionary:
	return {"y": int(ymd["y"]), "m": int(ymd["m"]), "d": int(ymd["d"]),
		"comp": comp, "comp_name": comp_name, "round": round_lbl,
		"home_id": home_id, "away_id": away_id,
		"home": _club_display_name(home_id), "away": _club_display_name(away_id),
		"home_flag": int(GameDB.club(home_id).get("countryCode", -1)),
		"away_flag": int(GameDB.club(away_id).get("countryCode", -1))}

## The inferred calendar date of league round `r` (0-based): season-start 9 AUG of the season's
## first year + r weeks (mirrors ResultsScreen._date_for for cross-screen consistency). The
## exact day is the honest calendar gap (fixtures_screen_re.md); clamped to the season length.
func _league_round_date(r: int) -> Dictionary:
	var sy := 1997
	if _career.season.length() >= 4 and _career.season.substr(0, 4).is_valid_int():
		sy = int(_career.season.substr(0, 4))
	var rr := clampi(r, 0, maxi(_career.total_weeks() - 1, 0))
	var t0 := Time.get_unix_time_from_datetime_dict(
		{"year": sy, "month": 8, "day": 9, "hour": 12, "minute": 0, "second": 0})
	var dd := Time.get_datetime_dict_from_unix_time(int(t0) + rr * 7 * 86400)
	return {"y": int(dd["year"]), "m": int(dd["month"]), "d": int(dd["day"])}

## Parse an ISO "yyyy-mm-dd" into {y,m,d} ints; {} if malformed (empty date string).
func _iso_ymd(iso: String) -> Dictionary:
	var p := iso.split("-")
	if p.size() != 3:
		return {}
	return {"y": int(p[0]), "m": int(p[1]), "d": int(p[2])}

## The hub NEWS control opens the original "News extra" newspaper overlay
## (NOTICIAS; frame-baked from walkthrough 155-158 — docs/re/news_screen_re.md).
## The hub stays visible around the page; [X] / tap-outside dismisses.
var _news_overlay: NewsScreen = null

func _show_club_news() -> void:
	if _news_overlay != null and is_instance_valid(_news_overlay):
		_news_overlay.queue_free()
	var ov: NewsScreen = load("res://scenes/NewsScreen.gd").new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	_news_overlay = ov
	ov.setup(_career.news_log, _career.week, clampi(_career.tier - 1, 0, 3))
	ov.back_pressed.connect(func() -> void:
		if _news_overlay != null and is_instance_valid(_news_overlay):
			_news_overlay.queue_free()
		_news_overlay = null)

## Dismiss a browse overlay shown from the hub (results) and re-raise the hub beneath it.
func _dismiss_career_browse() -> void:
	if _browse != null and is_instance_valid(_browse):
		_browse.queue_free()
	_browse = null
	_show_career()

# ---- team selection + tactics (S6) ---------------------------------------
# Career Tactics accessors for the original-art surfaces (TACTICS board, TEAM
# TACTICS modal, LINE-UP screen), persisted on the career and fed into the
# match engine for the manager's own club. The interim text-menu tactics
# handlers were removed 2026-07-04 once the board covered them; see Tactics.gd
# for the binary-string provenance.

func _tactics() -> Tactics:
	if _career.tactics.is_empty():
		_career.tactics = Tactics.auto_pick(_mgr_club()).to_dict()
	return Tactics.from_dict(_career.tactics)

## True when the SAVED tactics XI fields a banned/injured player — the hub
## CONTINUE gate (witnessed §3). Auto-pick (empty tactics) selects fit players
## only; ids no longer on the roster are left to the existing repair paths.
func _xi_has_unavailable() -> bool:
	if _career.tactics.is_empty():
		return false
	var by_id := {}
	for p in _mgr_club().get("players", []):
		by_id[int(p.get("id", -1))] = p
	for pid in Tactics.from_dict(_career.tactics).xi:
		var pl: Dictionary = by_id.get(int(pid), {})
		if not pl.is_empty() and not Availability.is_available(pl):
			return true
	return false

func _save_tactics(t: Tactics) -> void:
	_career.tactics = t.to_dict()
	_career.save()


# ---- transfer market (S7) ------------------------------------------------
# TRANSFER MARKET / OFFERS / RENEW / SALE -- buy, sell, renew and track targets.
# Squads + cash mutate on the career and persist. PM98 screen surface; the
# valuation model is ours-calibrated (see TransferMarket.gd).

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

## The interim bid-amount submenu is retired: bidding goes through the REAL
## make-offer card (walkthrough run-3 101-118). This menu keeps only the
## card route + the shortlist toggle.
func _show_market_player(row: Dictionary) -> void:
	var key: bool = row["key"]
	var fee: int = int(row["fee"])
	var pid := int(row["pid"])
	var rows: Array = []
	var payload: Array = []
	rows.append("Make an offer"); payload.append({"card": true})
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
	_show_make_offer_card(row)

## FREE AGENTS (T2 #9): out-of-contract players you can sign for no fee, just a wage. Tap
## one to open the wage negotiation. Driven by Career.free_agents (released + generated).
func _show_free_agents() -> void:
	var rows: Array = []
	var payload: Array = []
	var pool: Array = _career.free_agents.duplicate()
	pool.sort_custom(func(a, b): return int(a.get("attrs", {}).get("CA", 0)) > int(b.get("attrs", {}).get("CA", 0)))
	for p in pool:
		var gk := "GK" if p.get("isGK") else "  "
		var ca := int(p.get("attrs", {}).get("CA", 0))
		var demand := Contract.demanded_weekly(p, _career.my_band())
		rows.append("%-16s %s CA%2d  age %d  asks £%s/wk" % [
			str(p.get("name", "?")).substr(0, 16), gk, ca, int(p.get("age", 0)), _fmt_int(demand)])
		payload.append(p)
	if rows.is_empty():
		rows.append("No free agents available right now.")
		payload.append(null)
	_set_view("FREE AGENTS", "Sign for £0 fee + an agreed wage  -  %d offers left" % _career.offers_left,
		rows, payload, func(p):
			if p != null:
				_push(_show_free_agent_deal.bind(p)))

func _show_free_agent_deal(player: Dictionary) -> void:
	var pid := int(player.get("id", -1))
	var demand := Contract.demanded_weekly(player, _career.my_band())
	var rows: Array = []
	var payload: Array = []
	rows.append("Offer his demand        £%s/wk" % _fmt_int(demand)); payload.append({"wage": demand})
	rows.append("Offer above demand      £%s/wk" % _fmt_int(_bid_round(int(demand * 1.15))))
	payload.append({"wage": _bid_round(int(demand * 1.15))})
	rows.append("Offer below (risky)     £%s/wk" % _fmt_int(_bid_round(int(demand * 0.85))))
	payload.append({"wage": _bid_round(int(demand * 0.85))})
	var ca := int(player.get("attrs", {}).get("CA", 0))
	_set_view("Sign %s" % player.get("name", "?"),
		"CA %d  -  age %d  -  free transfer, wage only  -  %d offers left" % [
			ca, int(player.get("age", 0)), _career.offers_left],
		rows, payload, func(it): _free_agent_action(pid, int(it["wage"])))

func _free_agent_action(pid: int, wage: int) -> void:
	var rng := _career.career_rng()   # S3: the ONE persisted career stream
	var res := _career.sign_free_agent(pid, wage, rng)
	_career.save()
	if res["ok"]:
		_nav.pop_back()                     # drop the offer screen
		_push(_show_deal_result.bind(res["msg"]))
	else:
		_toast(res["msg"])                  # stay; renegotiate (offers permitting)

## SCOUT REPORT (T2 #10): your scout's recommended transfer targets (best affordable, most
## able first, as many as his quality). Tap one to open the bid screen. Needs a SCOUT hired.
func _show_scout_report() -> void:
	var rows: Array = []
	var payload: Array = []
	for row in _career.scout_targets():
		var gk := "GK" if row["isGK"] else "  "
		var star := "♥" if _career.shortlist.has(int(row["pid"])) else " "
		rows.append("%s%-15s %s CA%2d £%-9s %s" % [
			star, row["name"], gk, int(row["ca"]), _fmt_int(int(row["fee"])), row["club_name"]])
		payload.append(row)
	if rows.is_empty():
		rows.append("Your scout has no affordable targets to recommend.")
		payload.append(null)
	_set_view("SCOUT REPORT", "Your scout's recommended targets  -  tap to bid",
		rows, payload, func(r):
			if r != null:
				_push(_show_market_player.bind(r)))

## LOAN MARKET (T2 #8): other clubs' fringe players you can take on loan for the season
## (no fee, you pay the wage, he returns to his parent at the rollover). Tap to confirm.
func _show_loan_market() -> void:
	var rows: Array = []
	var payload: Array = []
	var mkt := _career.loan_market()
	for row in mkt:
		var gk := "GK" if row["isGK"] else "  "
		rows.append("%-16s %s CA%2d  age %d  %s" % [
			str(row["name"]).substr(0, 16), gk, int(row["ca"]), int(row["age"]), row["club_name"]])
		payload.append(row)
	if rows.is_empty():
		rows.append("No clubs are willing to loan a player out right now.")
		payload.append(null)
	_set_view("LOAN MARKET", "Loan a player for the season  -  %d offers left" % _career.offers_left,
		rows, payload, func(r):
			if r != null:
				_push(_show_loan_deal.bind(r)))

func _show_loan_deal(row: Dictionary) -> void:
	var weekly := int(round(float(row["wage"]) / FinanceModel.SEASON_WEEKS))
	var rows: Array = ["Take him on loan for the season", "Cancel"]
	var payload: Array = [{"do": true}, {"do": false}]
	_set_view("Loan %s" % row["name"],
		"%s  -  CA %d  -  no fee, you pay ~£%s/wk  -  returns next season" % [
			row["club_name"], int(row["ca"]), _fmt_int(weekly)],
		rows, payload, func(it): _loan_action(row, bool(it["do"])))

func _loan_action(row: Dictionary, do_it: bool) -> void:
	if not do_it:
		_go_back()
		return
	var res := _career.sign_loan(int(row["pid"]), int(row["club_id"]))
	_career.save()
	if res["ok"]:
		_nav.pop_back()                      # drop the confirm screen
		_push(_show_deal_result.bind(res["msg"]))
	else:
		_toast(res["msg"])

func _show_deal_result(msg: String) -> void:
	_set_view("Transfer", msg, ["Back to transfers"], [{}], func(_x): _go_back())


## THE SEASON-END SEQUENCE (REFRUN R13/R15, witnessed end to end 2026-07-25).
##
## The original runs EIGHT steps between the last league match and the new preseason,
## every one of them raised UNPROMPTED:
##   1. the final table of each division, as it finishes  <- built (LeagueTableScreen)
##   2. a champion card per trophy, on the shared CAMPEON layout  <- built, for the six
##      competitions whose card art is witnessed
##   3. THE CHAMPIONSHIPS -- all eight finals with scorelines   <- built (0-px bake)
##   4. END OF SEASON -- champion / U.E.F.A. places / promoted / relegated  <- built (0-px)
##   5. GOAL SCORERS OF THE YEAR                                <- built (awards layout)
##   6. PLAYERS OF THE YEAR -- one per club, four tabs          <- built (0-px bake)
##   7. MANAGERS OF THE YEAR                                    <- built (awards layout)
##   8. Preseason for the new season
## All eight now run. Steps 3, 4 and 6 were baked 2026-07-25 off the reference run's own
## frames at tools/re/refs/season-end-2026-07-25/ and render-diff at ZERO differing
## pixels (tools/re/diff_seasonend_year_parity.py); see docs/re/season_end_sequence_re.md.
##
## AND THERE IS NO BOARD-VERDICT SCREEN IN IT. What used to live here -- an unconditional
## "Final position: Nth of 20 / Board objective / Reputation / Verdict" sheet -- was an
## invention, and it also took the name of the original's own END OF SEASON screen, which
## is the four-division promoted/relegated overview (step 4). It is gone. The board's
## decision still happens (Career.board_review), but it surfaces only when it has
## consequences -- a sacking or a job offer -- and then through the original's own modal
## alert box, not a screen of its own.
func _show_end_of_season() -> void:
	_career.queue_season_end_champion_cards()
	_season_end_step(0)


## Walk the witnessed sequence one step at a time; each screen's own dismiss control
## advances it. Steps the app cannot yet draw faithfully are skipped in place.
func _season_end_step(step: int) -> void:
	var next := func() -> void: _season_end_step(step + 1)
	match step:
		0:
			_season_end_final_tables(next)
		1:
			_season_end_champion_cards(next)
		2:
			_season_end_championships(next)
		3:
			_season_end_overview(next)
		4:
			_season_end_goal_scorers(next)
		5:
			_season_end_players(next)
		6:
			_season_end_managers(next)
		_:
			_season_end_board()


## Step 1: the final table of every division, raised unprompted with a BLANK manager
## plate and the division in the badge (REFRUN R13). Lower divisions finish first (R12),
## so they are presented first, the manager's own division last.
func _season_end_final_tables(after: Callable) -> void:
	var tiers: Array = []
	for t in [4, 3, 2, 1]:
		if t == _career.tier or _career.has_division(t):
			tiers.append(t)
	_season_end_next_table(tiers, 0, after)


func _season_end_next_table(tiers: Array, i: int, after: Callable) -> void:
	if i >= tiers.size():
		after.call()
		return
	var t := int(tiers[i])
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	# Blank manager plate: in this mode the original shows no manager (R13).
	scr.setup(_career.standings_for(t) if t != _career.tier else _career.standings(),
		_career.club_name, _career.season, "Week %d" % _career.total_weeks(),
		t, _career.club_id, "")
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_season_end_next_table(tiers, i + 1, after))


## Step 2: the champion cards, in the original's own order, one OK each.
func _season_end_champion_cards(after: Callable) -> void:
	if _career.pending_champion_cards.is_empty():
		after.call()
		return
	var card: Dictionary = (_career.pending_champion_cards as Array).pop_front()
	var comp := str(card.get("comp", ""))
	if not CharityShieldScreen.has_card(comp):
		# Card art never captured for this trophy -- skip it rather than borrow another's.
		_season_end_champion_cards(after)
		return
	_show_champion_card(card, func() -> void: _season_end_champion_cards(after))


## The channelTV broadcast-rights card over the hub (REFRUN R6). The original raises it
## UNPROMPTED, so it rides the same post-week card chain the monthly awards and the TEAM
## OFFER cards do rather than gating CONTINUE. Career queues it when the COMING fixture is
## at home and that competition's fee is witnessed. The fee is booked to the week's
## TELEVISION line when the match is actually played -- the card announces it, it does not
## pay it -- so answering OK just clears the queue and runs `after`.
func _pop_channel_tv(after: Callable) -> void:
	if _career == null or (_career.pending_channel_tv as Dictionary).is_empty():
		if after.is_valid():
			after.call()
		return
	var card: Dictionary = _career.pending_channel_tv
	_career.pending_channel_tv = {}
	var scr: ChannelTvScreen = load("res://scenes/ChannelTvScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(int(card.get("fee", 0)))
	scr.ok_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		if after.is_valid():
			after.call())


## One CAMPEON card over whatever is on screen. `card` is a Career pending_champion_cards
## entry; manager names are resolved here (Career has no manager database).
func _show_champion_card(card: Dictionary, after: Callable) -> void:
	var scr: CharityShieldScreen = load("res://scenes/CharityShieldScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var w: Dictionary = (card.get("winner", {}) as Dictionary).duplicate()
	var r: Dictionary = (card.get("runner", {}) as Dictionary).duplicate()
	w["manager"] = _mgr_of(int(w.get("club_id", -1)))
	r["manager"] = _mgr_of(int(r.get("club_id", -1)))
	scr.setup(w, r, str(card.get("comp", "charity_shield")))
	scr.ok_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		if after.is_valid():
			after.call())


## Step 3: THE CHAMPIONSHIPS -- the season's eight finals on one sheet, each card's
## trophy and title baked from the original's own frame. A competition that was never
## played leaves its card as the original leaves it rather than borrowing another's.
func _season_end_championships(after: Callable) -> void:
	var rows := _career.season_end_championships()
	var any := false
	for r in rows:
		if not (r as Dictionary).is_empty():
			any = true
			break
	if not any:
		after.call()
		return
	var scr: ChampionshipsScreen = load("res://scenes/ChampionshipsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(rows)
	scr.continue_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		after.call())


## Step 4: END OF SEASON -- the four-division promoted / relegated overview. This is the
## screen whose NAME the deleted board-verdict invention used to take.
func _season_end_overview(after: Callable) -> void:
	var by_tier := _career.season_end_overview()
	if by_tier.is_empty():
		after.call()
		return
	var scr: EndOfSeasonScreen = load("res://scenes/EndOfSeasonScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(by_tier)
	scr.continue_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		after.call())


## Step 6: PLAYERS OF THE YEAR -- one award per club, four division tabs (92 awards).
func _season_end_players(after: Callable) -> void:
	var by_tier := _career.players_of_year()
	if by_tier.is_empty():
		after.call()
		return
	var scr: PlayersYearScreen = load("res://scenes/PlayersYearScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(by_tier, _career.tier)
	scr.continue_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		after.call())


## Step 5: GOAL SCORERS OF THE YEAR, on the award sheets' shared four-panel layout
## (the year and month sheets are byte-identical chrome -- verified against
## tools/re/refs/season-end-2026-07-25/24_managers_of_the_year.png).
func _season_end_goal_scorers(after: Callable) -> void:
	var aw := _career.season_end_awards()
	var rows: Dictionary = {}
	for t in (aw.get("scorers", {}) as Dictionary):
		var r: Dictionary = (aw["scorers"] as Dictionary)[t]
		# The original prints "Fowler (19)" in the name cell and the club beside it.
		rows[int(t)] = {"club_id": int(r.get("club_id", -1)), "club": str(r.get("club", "")),
			"manager": "%s (%d)" % [str(r.get("player", "")), int(r.get("goals", 0))]}
	_show_year_award("GOAL SCORERS OF THE YEAR", rows, after)


## Step 7: MANAGERS OF THE YEAR, same layout, one per division.
func _season_end_managers(after: Callable) -> void:
	var aw := _career.season_end_awards()
	var rows: Dictionary = {}
	for t in (aw.get("managers", {}) as Dictionary):
		var r: Dictionary = (aw["managers"] as Dictionary)[t]
		rows[int(t)] = {"club_id": int(r.get("club_id", -1)), "club": str(r.get("club", "")),
			"manager": _mgr_of(int(r.get("club_id", -1)))}
	_show_year_award("MANAGERS OF THE YEAR", rows, after)


func _show_year_award(title: String, rows: Dictionary, after: Callable) -> void:
	if rows.is_empty():
		after.call()
		return
	var scr: ManagersMonthScreen = load("res://scenes/ManagersMonthScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup_titled(title, rows)
	scr.ok_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		after.call())


## The board's decision, AFTER the sequence. The original has no verdict screen, so this
## raises nothing at all in the ordinary case -- it goes straight to the new preseason.
## A sacking or a job offer still has to reach the manager somehow; both go through the
## original's own modal alert box on the hub, and the offer list is the app's own screen.
func _season_end_board() -> void:
	var rv := _career.board_review()
	if bool(rv["sacked"]):
		# The board's own words. All three are MANAGER.EXE's, verbatim off the message
		# table FUN_00545fd0 indexes (2026-07-27): 0x662d24 -> 0x663818 (financial),
		# 0x662d2c -> 0x663744 (results), 0x662d30 -> 0x663690 (squad too small). The
		# port's old invented one-liner is gone.
		var msg := "The Directors have held an urgent meeting,\nand have sacked you as manager of the club."
		match str(rv["reason"]):
			"insolvent":
				msg = ("The Directors have held an urgent meeting.\n"
					+ "They have decided to terminate your contract\n"
					+ "as manager due to the disastrous financial management\nof the club.")
			"squad":
				msg = ("The Directors have decided to terminate your contract\n"
					+ "due to bad management of your squad,\n"
					+ "which does not have the minimum number of players\n"
					+ "needed to play in any championship.")
		_generate_offers(false)
		_show_alert_then(msg, _show_job_offers)
		return
	if bool(rv["headhunted"]):
		_generate_offers(true)
		_show_job_offers()
		return
	_next_season()


## Raise one modal "PREMIER MANAGER 98" alert box over whatever is on screen, then run
## `after` when it is answered. The hub owns the box, so it is queued there.
func _show_alert_then(msg: String, after: Callable) -> void:
	_show_career()
	if _hub != null and is_instance_valid(_hub):
		_hub.alerts_cleared.connect(func() -> void: after.call(), CONNECT_ONE_SHOT)
		_hub.alert(msg)
	else:
		after.call()


func _next_season() -> void:
	# Carry the live squads, cash and tactics into the new season; contracts tick
	# down and unrenewed players leave on a free (handled in Career.advance_season).
	# TalentDB's pool rides along: real talents due in the new season arrive (empty
	# pool -- no talent_pool.json -- injects nothing and the rollover is vanilla).
	var rng := _career.career_rng()   # S3: the ONE persisted career stream
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion(), TalentDB.talents)
	_career.save()
	_show_preseason_rollover()


## Preseason picks per slot date. null = a SKIPped slot (original SKIP consumes one
## date, audit §C2): that date simply has no friendly; later picks keep their own
## slot dates.
func _preseason_meta(picks: Array, dates: Array) -> Array:
	var rivals_meta: Array = []
	for i in picks.size():
		if picks[i] == null:
			continue
		var rc: Dictionary = picks[i]
		rivals_meta.append({"date": dates[i] if i < 4 else "", "club_id": int(rc.get("id", -1)),
			"name": str(rc.get("name", "")), "home": bool(rc.get("home", false)),
			"venue_stadium": str(rc.get("venue_stadium", ""))})
	return rivals_meta


## The season-rollover preseason picker (WITNESSED: REFRUN R15 step 8, p0664 —
## "Preseason for Manchester Utd." opens 1998-99). Same PreseasonScreen as career
## entry; the picks land on the NEW season's own dates (Career.preseason_dates)
## and the flow then enters the career as before. [Mats QA 2026-07-26]
func _show_preseason_rollover() -> void:
	if _preseason != null and is_instance_valid(_preseason):
		_preseason.queue_free()
	var club: Dictionary = GameDB.clubs_by_id.get(_career.club_id, {})
	_preseason = load("res://scenes/PreseasonScreen.gd").new()
	_preseason.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preseason)
	_preseason.setup(PMChrome.title_case_name(_career.club_name), _career.manager_name,
		GameDB.leagues, GameDB.clubs_in_league, _clubs_of_country_en, _career.club_id, club)
	_preseason.preseason_done.connect(func(rivals: Array) -> void:
		if _preseason != null and is_instance_valid(_preseason):
			_preseason.queue_free()
		_preseason = null
		var start_year := 1997
		var parts := _career.season.split("-")
		if parts.size() >= 1 and str(parts[0]).is_valid_int():
			start_year = int(parts[0])
		_career.preseason_rivals = _preseason_meta(rivals, Career.preseason_dates(start_year))
		_career.save()
		_enter_career())


# ---- manager career across clubs (#14) -----------------------------------

## Build the job offers on the table from GameDB: real clubs in the reputation strength band
## (every manageable club ranked weakest..strongest, sliced by the percentile window the
## Career's reputation commands), excluding the club you manage. A headhunt restricts the
## pool to clubs STRONGER than yours. Stored on the career so they persist + render. Stable
## across redraws (no-op once offers exist).
func _generate_offers(headhunt: bool) -> void:
	if not _career.pending_offers.is_empty():
		return
	var band := _career.offer_band()
	var ranked: Array = []
	for c in GameDB.clubs:
		if c.get("leagueId") == null:
			continue   # only league clubs are manageable (skip the international-only set)
		ranked.append({"club": c, "ovr": _club_strength(c)})
	if ranked.is_empty():
		return
	ranked.sort_custom(func(a, b): return float(a["ovr"]) < float(b["ovr"]))
	var n := ranked.size()
	var lo_i := clampi(int(floor(float(band["lo"]) * (n - 1))), 0, n - 1)
	var hi_i := clampi(int(ceil(float(band["hi"]) * (n - 1))), 0, n - 1)
	var cur := _current_strength()
	var pool: Array = []
	for i in range(lo_i, hi_i + 1):
		var club: Dictionary = ranked[i]["club"]
		if int(club["id"]) == _career.club_id:
			continue
		if headhunt and float(ranked[i]["ovr"]) <= cur:
			continue
		pool.append(club)
	if pool.is_empty():
		# Always leave at least something on the table: nearest clubs, current excluded.
		for entry in ranked:
			var club: Dictionary = entry["club"]
			if int(club["id"]) != _career.club_id:
				pool.append(club)
	pool.shuffle()
	var offers: Array = []
	for club in pool.slice(0, int(band["count"])):
		offers.append(_offer_from_club(club))
	_career.pending_offers = offers

## Overall strength of a club dict (att + def + gk), the ranking key for offers.
func _club_strength(club: Dictionary) -> float:
	var r := MatchEngine.team_ratings(club)
	return float(r["att"]) + float(r["def"]) + float(r["gk"])

## Overall strength of the club you currently manage (from its live roster).
func _current_strength() -> float:
	return _club_strength(_mgr_club())

## A serialisable offer {club_id, club_name, league_id, league_name} from a GameDB club.
func _offer_from_club(club: Dictionary) -> Dictionary:
	var lg := _league_by_id(str(club.get("leagueId", "")))
	return {
		"club_id": int(club["id"]), "club_name": str(club.get("name", "?")),
		"league_id": str(club.get("leagueId", "")), "league_name": str(lg.get("name", "League")),
	}

func _league_by_id(id: String) -> Dictionary:
	for lg in GameDB.leagues:
		if str(lg.get("id", "")) == id:
			return lg
	return {}

## The clubs that want you (#14) — the original OFFERS SELECTION screen's
## "OFFERS FOR <name>" panel (live-witnessed 2026-07-16, frames 03-07;
## docs/re/promanager_career_screens_re.md). Replaces the invented JOB OFFERS
## browse (audit B5-1). The original fires this at the Promanager career start;
## its post-sack surface is UNKNOWN — witnessed chrome, mid-career use flagged.
## Row tap accepts (slot fills, CONTINUE lights, frame 07); CONTINUE takes the
## job; the row arrow opens the witnessed club-detail popup; RETURN declines.
func _show_job_offers() -> void:
	if _offers_screen != null and is_instance_valid(_offers_screen):
		_offers_screen.queue_free()
	var scr: OffersSelectionScreen = load("res://scenes/OffersSelectionScreen.gd").new()
	_offers_screen = scr
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var rows: Array = []
	for o in _career.pending_offers:
		rows.append(_offer_row(o))
	scr.setup(_career.manager_name, rows)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_offers_screen = null)
	scr.accept_confirmed.connect(func(i: int) -> void:
		AudioManager.ui_select()
		if i >= 0 and i < _career.pending_offers.size():
			var offer: Dictionary = _career.pending_offers[i]
			scr.queue_free()
			_offers_screen = null
			_accept_job(offer))

## One OFFERS FOR row + club-detail popup payload from a pending offer. All
## values are the app's real career data in the witnessed chrome: the objective
## is what the board will actually set (Career.objective_for), INTIAL CASH is
## the exact opening balance take_job grants (a quarter's income), CAPACITY the
## finance model's ground size. MEMBERS is witnessed only as "-" -> stays "-".
func _offer_row(o: Dictionary) -> Dictionary:
	var club := GameDB.club(int(o["club_id"]))
	var lid := str(o["league_id"])
	var league_clubs := GameDB.clubs_in_league(lid)
	var obj := Career.objective_for(int(o["club_id"]), lid, league_clubs, GameDB.leagues)
	var tier := FinanceModel.tier_of({"leagueId": lid}, GameDB.leagues)
	var fin := FinanceModel.summary(club, tier)
	var cap := int(fin.get("capacity", 0))
	var stadium := str(club.get("stadium", ""))
	return {
		"team": str(o["club_name"]), "division": _div_short(str(o["league_name"])),
		"division_full": str(o["league_name"]), "objective": str(obj["text"]),
		"club_id": int(o["club_id"]),
		"stadium": stadium if stadium != "" and stadium != "<null>" else "-",
		"capacity": "%s seats" % Career._grp(cap) if cap > 0 else "-",
		"members": "-",
		"cash": "£%s" % Career._grp(int(fin.get("total_income", 0)) / 4),
	}

## Take an offered job: rebuild the career around the new club (Career.take_job records the
## old spell + carries reputation/history), save, and enter the new career.
func _accept_job(offer: Dictionary) -> void:
	var lid := str(offer["league_id"])
	var league := _league_by_id(lid)
	var club := GameDB.club(int(offer["club_id"]))
	if club.is_empty() or league.is_empty():
		_toast("That club is no longer available.")
		return
	var league_clubs := GameDB.clubs_in_league(lid)
	var reason := "sacked" if _career.sacked else ("left %s" % _career.club_name)
	_career.take_job(club, league, league_clubs, GameDB.leagues, reason, _pyramid_context())
	# The new division was re-seeded from the 1997 GameDB: catch up any real talents
	# whose debut has already passed (they land at their clubs here, today's ages).
	_career.inject_due_talents(TalentDB.talents)
	_career.save()
	_enter_career()

## MANAGER HISTORY (#14): the original screen behind the board's MANAGER INFO button
## (live-witnessed 2026-07-16; docs/re/promanager_career_screens_re.md) — one spell row
## per club (TEAM/DIVISION/POS./OBJ./DIRECTORS/PUBLIC) + the per-competition record
## table with the TOTAL toggle. Replaces the invented "YOUR CAREER" browse (B5-1).
## Board confidence was never stored for past spells, so their DIRECTORS/PUBLIC cells
## stay honestly empty; only the current club carries the live board values.
func _show_manager_career() -> void:
	if _mgr_history != null and is_instance_valid(_mgr_history):
		_mgr_history.queue_free()
	var scr: ManagerHistoryScreen = load("res://scenes/ManagerHistoryScreen.gd").new()
	_mgr_history = scr
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var spells: Array = []
	for h in _career.manager_history:
		spells.append({"team": str(h.get("club_name", "?")),
			"division": _div_short(str(h.get("league_name", ""))),
			"pos": str(h.get("final_pos_str", "")),
			"obj": "", "directors": "", "public": ""})
	var bp := _board_panel()
	spells.append({"team": _career.club_name, "division": _div_short(_career.league_name),
		"pos": "%d%s" % [_career.position(), _ord_suffix(_career.position())],
		"obj": "YES" if _career.objective_met() else "NO",
		"directors": str(clampi(int(round(int(bp["directors"]) / 10.0)), 0, 10)),
		"public": str(clampi(int(round(int(bp["supporters"]) / 10.0)), 0, 10))})
	scr.setup(_career.manager_name, spells, _career.competition_record(),
		_career.competition_total())
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free()
		_mgr_history = null)
	scr.honours_pressed.connect(func() -> void:
		AudioManager.ui_select()
		_show_honours())

## HONOURS + CAREER RESUME — OURS (docs/SPEC_ours_additions.md item 1). Raised off the
## MANAGER HISTORY plaque, which the original leaves inert, so that screen keeps its 0-px
## parity. Reads only Career.honours, the ledger written at each season rollover.
func _show_honours() -> void:
	var scr: HonoursScreen = load("res://scenes/HonoursScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_career.manager_name, _career.honours_board(), _career.career_resume())
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())

## The witnessed division short-forms ("3rd Div." in OFFERS SELECTION / MANAGER
## HISTORY; "Premier" on the news side-tabs). Foreign league names pass through.
func _div_short(league_name: String) -> String:
	match league_name:
		"Premier League": return "Premier"
		"Division One": return "1st Div."
		"Division Two": return "2nd Div."
		"Division Three": return "3rd Div."
	return league_name

## Real-render of the manager-career flow (#14): take a weak club, miss the board's target,
## be sacked, render the JOB OFFERS list, take a job, render MANAGER HISTORY. PM98_MANAGER_SHOT.
func _manager_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("MANAGER-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return _club_strength(a) < _club_strength(b))
	_begin_career("Manager", lg, clubs[0])   # the weakest top-flight club -> likely to miss the target
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	while not _career.season_over():
		_career.advance_week(rng)
	var rv := _career.board_review()
	if not bool(rv["sacked"]):
		# Force the sacking branch for a deterministic capture if the minnows overachieved.
		_career.sacked = true
		_career.sack_reason = "missed"
		_career.pending_offers = []
	_show_career()
	await _settle()
	_generate_offers(false)
	_show_job_offers()
	await _settle()
	_save_shot(dir, "job_offers.png")
	var offer_count := _career.pending_offers.size()
	_free_overlays()
	if not _career.pending_offers.is_empty():
		_accept_job(_career.pending_offers[0])
		await _settle()
	_show_manager_career()
	await _settle()
	_save_shot(dir, "manager_career.png")
	print("MANAGER-SHOT done sacked=%s reason=%s offers=%d history=%d now=%s" % [
		str(rv["sacked"]), str(rv["reason"]), offer_count,
		_career.manager_history.size(), _career.club_name])
	get_tree().quit()

# ---- helpers -------------------------------------------------------------

## Brief footer feedback on the green sub-flow screens (the footer label).
## Hub-visible feedback goes through MenuScreen.alert (the real message box)
## instead — see _menu_action / _apply_offer_answers.
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
