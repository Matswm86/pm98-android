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
			and not OS.has_environment("PM98_TRAIN_SHOT") and not OS.has_environment("PM98_CUP_SHOT") \
			and not OS.has_environment("PM98_YOUTH_SHOT") and not OS.has_environment("PM98_STAFF_SHOT") \
			and not OS.has_environment("PM98_CONTRACT_SHOT") and not OS.has_environment("PM98_SCREENS_SHOT") \
			and not OS.has_environment("PM98_MANAGER_SHOT") and not OS.has_environment("PM98_FICHA_SHOT") \
			and not OS.has_environment("PM98_MATCHOPTS_SHOT") and not OS.has_environment("PM98_PLAYERACT_SHOT"):
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
	if OS.has_environment("PM98_TRAIN_SHOT"):
		_train_shot()
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
	if OS.has_environment("PM98_MATCHOPTS_SHOT"):
		_matchopts_shot()
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


## Faithful real-render of the TRAINING screen (player development). Begins a career,
## sets intensity to Intensive, and captures the TRAINING browse (intensity row +
## the squad's development trend). Run as the NORMAL app under Xvfb+GL: PM98_TRAIN_SHOT=1.
func _train_shot() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if GameDB.leagues.is_empty():
		print("TRAIN-SHOT no leagues loaded")
		get_tree().quit()
		return
	var lg: Dictionary = GameDB.leagues[0]
	var clubs := GameDB.clubs_in_league(lg["id"])
	clubs.sort_custom(func(a, b): return a["name"] < b["name"])
	_begin_career("Manager", lg, clubs[0])
	_career.training_intensity = "Intensive"
	_show_career()               # raise the hub
	await _settle()
	_show_training()
	await _settle()
	_save_shot(dir, "training.png")
	print("TRAIN-SHOT done intensity=%s squad=%d" % [_career.training_intensity, _career.my_squad().size()])
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
	_show_renew(target)
	await _settle()
	_save_shot(dir, "contract.png")
	print("CONTRACT-SHOT done squad=%d wagebill/wk=%d demand/wk=%d club=%s" % [
		_career.my_squad().size(), _career.player_weekly_wage(),
		Contract.demanded_weekly(target, _career.tier), _career.club_name])
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
	for _i in 22:                # past several scheduled rounds of both cups
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()               # raise the hub
	await _settle()
	_show_cup_screen(_career.fa_cup, "F.A. CUP", "res://art/screens/cup/trophy.png")
	await _settle()
	_save_shot(dir, "cup.png")
	for c in get_children():
		if c is CupScreen:
			c.queue_free()
	await _settle()
	_show_cup_screen(_career.league_cup, "COCA-COLA CUP", "res://art/screens/cup/cocacola.png")
	await _settle()
	_save_shot(dir, "league_cup.png")
	var b: Dictionary = _career.fa_cup
	var lc: Dictionary = _career.league_cup
	# Finish the season and roll over so the Charity Shield (champions v F.A. Cup winners)
	# is contested, then capture it around the real CHARITY shield art.
	for c in get_children():
		if c is CupScreen:
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
		if c is CupScreen:
			c.queue_free()
	# First, partway in: the European Cup group stage in flight (a few matchdays played).
	for _g in 13:
		if _career.season_over():
			break
		_career.advance_week(rng)
	_show_career()
	await _settle()
	var ecg: Dictionary = _career.euro.get("european_cup", {})
	_show_cup_screen(ecg, "EUROPEAN CUP", _euro_emblem("european_cup"))
	await _settle()
	_save_shot(dir, "european_cup_group.png")
	for c in get_children():
		if c is CupScreen:
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
	_show_cup_screen(ec, str(ec.get("name", "EUROPEAN CUP")).to_upper(), _euro_emblem(show_key))
	await _settle()
	_save_shot(dir, "european_cup.png")
	# Finish this European season and roll over once more so the winners-of-winners finals
	# (European Supercup + Intercontinental Cup) are contested, then capture the Supercup.
	for c in get_children():
		if c is CupScreen:
			c.queue_free()
	while not _career.season_over():
		_career.advance_week(rng)
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion())
	_show_one_off_final(_career.supercup, "EUROPEAN SUPERCUP",
		"res://art/screens/cup/supercopa.png", "European Supercup",
		"European Cup winners v Cup Winners' Cup winners")
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

	# --- OWNER STEP 4: tap RENEW (mutates contract_years on accept, logs on reject) ---
	fi = _first_of(PlayerInfoScreen)
	if fi != null:
		var yrs_before := int(pl.get("contract_years", 0))
		var news_before := (_career.news_log as Array).size()
		var rn: Rect2 = PlayerInfoScreen.BTN["renew"]
		await _synth_tap(fi, rn.position + rn.size * 0.5)
		await _settle()
		_save_shot(dir, "pa_04_after_renew.png")
		var yrs_after := int(pl.get("contract_years", 0))
		var news_after := (_career.news_log as Array).size()
		print("PLAYERACT RENEW: contract_years %d -> %d, news %d -> %d  (%s)" % [
			yrs_before, yrs_after, news_before, news_after,
			"FIRED" if (yrs_before != yrs_after or news_before != news_after) else "DEAD"])

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
				or c is StadiumScreen or c is CupScreen or c is YouthScreen \
				or c is StaffScreen or c is BrowseScreen or c is TacticsScreen \
				or c is PlayerInfoScreen or c is RivalScreen or c is ManagerHistoryScreen \
				or c is TrainingScreen or c is InjuriesScreen or c is StatisticsScreen \
				or c is OffersSelectionScreen or c is ChampsScreen \
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
	scr.setup(club, manager, cash, youth_enabled, season, week, _career.tier if _career else 1)
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
	var tier := FinanceModel.tier_of(club, GameDB.leagues)
	var own: bool = _career != null and int(club.get("id", -1)) == _career.club_id
	scr.setup(player, club, tier, own)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	if not own:
		return
	var pid := int(player.get("id", -1))
	# RENEW: agree a new deal at his wage demand (his term resets); refresh the card in place.
	scr.renew_requested.connect(func(_p: Dictionary) -> void:
		AudioManager.ui_select()
		var res := _career.renew(pid)
		_career.save()
		scr.setup(player, club, tier, true)
		_toast(str(res.get("msg", ""))))
	# TRANSFER: place him on (or off) the transfer market -- "PLAYER PLACED ON TRANSFER MARKET".
	scr.transfer_requested.connect(func(_p: Dictionary) -> void:
		AudioManager.ui_select()
		_career.toggle_listed(pid)
		_career.save()
		var listed := _career.is_listed(pid)
		scr.setup(player, club, tier, true)
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
		# Re-attach the pyramid's static club records (never persisted); a
		# pre-pyramid save gains its lower divisions here (fast-forwarded).
		_career.ensure_divisions(_pyramid_context())
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
	_career.manager_name = manager_name
	# Entry-flow picks (NIVEL level + Players age ? + preseason friendlies). The
	# rivals play out via hub CONTINUE before league round 1 (Career.play_friendly).
	_career.manager_level = _pending_level
	_career.players_age = _pending_age
	var dates := ["1997-08-01", "1997-08-04", "1997-08-06", "1997-08-08"]
	var rivals_meta: Array = []
	for i in preseason_rivals.size():
		# null = a SKIPped slot (original SKIP consumes one date, audit §C2): that
		# August date simply has no friendly; later picks keep their own slot dates.
		if preseason_rivals[i] == null:
			continue
		var rc: Dictionary = preseason_rivals[i]
		rivals_meta.append({"date": dates[i] if i < 4 else "", "club_id": int(rc.get("id", -1)),
			"name": str(rc.get("name", "")), "home": bool(rc.get("home", false)),
			"venue_stadium": str(rc.get("venue_stadium", ""))})
	_career.preseason_rivals = rivals_meta
	# Season-1 honours: the original contests the Charity Shield + runs the
	# European competitions from career start, seeded with the REAL 1996-97
	# honours (witnessed TEAMS IN CHAMPIONSHIPS, orig/06). English careers only —
	# the honour clubs are resolved from GameDB by their game names.
	var rng2 := RandomNumberGenerator.new()
	rng2.randomize()
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_career.play_season_opener(rng)
	_career.save()
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
	else:
		move_child(_hub, get_child_count() - 1)
	_hub.visible = true
	# Shared-header state: during preseason the original's plaque bands read
	# "Preseason"/"Preparation" and the calendar sheet shows the pending
	# FRIENDLY's date (wine captures 2026-07-12); in season, league + Week N.
	var pf := c.pending_friendly()
	PMChrome.header_phase = "preseason" if not pf.is_empty() else ""
	PMChrome.header_date = PMChrome.date_from_iso(str(pf.get("date", ""))) \
		if not pf.is_empty() else {}
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
	var res := _career.advance_week(rng)   # ratings come from the live roster
	if res.is_empty():
		_career.save()   # bye / season end: no presentation, save immediately
		_show_career()   # refresh the hub in place
		_pop_pending_team_offers()
		return
	_show_match_result(res)

## The manager's match (B4): the running BRIEF + MATCH OPTIONS, whose RESULTS tap now surfaces
## the source-true FULL TIME read-out (MatchResultScreen; docs/re/match_flow_re.md). The BRIEF
## feed stays honest (kept). RETURN/CONTINUE refresh + raise the hub.
func _show_match_result(res: Dictionary) -> void:
	var home := GameDB.club(int(res["home_id"]))
	var away := GameDB.club(int(res["away_id"]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Narrate the EXACT stored scoreline so feed and table agree; the stat engine's own
	# scorers ride along in res["goals"] (empty -> narrate re-rolls by finishing weight).
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]), res.get("goals", []))
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
	if not bool(res.get("friendly", false)):
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
		"header": hdr, "stadium": _result_stadium(res),
	}
	# Back at the hub, any live bids on listed players raise their TEAM OFFER
	# cards — the original's post-match CONTINUE order (run-3 frames 085->086).
	var open_match := func() -> void:
		_open_match(home, away, int(res["hg"]), int(res["ag"]), m["lines"],
			"%s  -  back to the dugout" % verdict, func() -> void:
				_career.save()   # the deferred week autosave (EXIT-Yes never gets here)
				_show_career()
				_pop_pending_team_offers(), result_data, res.get("possession", []))
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
func _result_stadium(res: Dictionary) -> Dictionary:
	var home_id := int(res.get("home_id", -1))
	if home_id == _career.club_id:
		var fp := _career.finance_preview()
		return {"name": str(_mgr_club().get("stadium", "")),
			"capacity": int(fp.get("capacity", 0)), "attendance": int(fp.get("attendance", 0))}
	var club := GameDB.club(home_id)
	var sm := FinanceModel.summary(club, FinanceModel.tier_of(club, GameDB.leagues))
	return {"name": str(club.get("stadium", "")),
		"capacity": int(sm.get("capacity", 0)), "attendance": int(sm.get("attendance", 0))}

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
		data.get("header", {}), data.get("stadium", {}), half)
	var advance := func() -> void:
		rs.queue_free()
		if on_continue.is_valid():
			on_continue.call()
	# Both HALF TIME and FULL TIME advance on CONTINUE (witnessed §5: the HT read-out
	# carries a real CONTINUE button, not a tap-anywhere dismiss).
	rs.continue_pressed.connect(advance)

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
## the squad's training grid + the selected player's attribute panel over the baked
## resting chrome. RETURN reopens LINE-UP; TACTICS opens the TEAM TACTICS board.
func _show_training_screen() -> void:
	var scr: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), _career.staff, _match_header())
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

## The INSURANCE screen (InsuranceScreen.gd; docs/re/insurance_screen_re.md):
## the squad with per-player INSURANCE POLICY groups (flat £200/£500/£1,000
## monthly). RETURN reopens INJURIES (witnessed 39 -> 40 back path).
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
## the squad roster over the baked table; per-player season stats are an honest gap (untracked).
func _show_statistics_screen() -> void:
	var scr: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_mgr_club(), _match_header())
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		_show_lineup_screen())

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

## The source-true TEAM TACTICS modal (ATTACK | DEFENCE, EQWIN* art + MANAGER.EXE label
## block; TeamTacticsScreen.gd, docs/re/tactics_subscreens_re.md) over a real LINE-UP
## backdrop. Each control mutates the career Tactics live (its ratings() feed the match
## engine), persisted on `changed`; the modal's ONLY exit is the EQWINX close (emits `done`,
## which frees both overlays) — there is no in-modal SAVE (SAVE/LOAD are BOARD buttons), so no
## save_requested connect. Supersedes the retired TacticsScreen.gd (which invented OK/SAVE/RETURN).
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
			not _career.youth_search.is_empty())
	refresh.call()
	scr.search_pressed.connect(func(skills: Array) -> void:
		_career.start_youth_search(skills)
		_career.save()
		refresh.call())
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
				_career.season, _career.week + 1, _career.tier)

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
const TICKET_LADDER := [8, 10, 12, 15, 18, 22, 28, 35]

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
	scr.setup(sm, _career.club_name, "", _career.season, _career.cash, _career.week + 1)
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
				_career.set_ticket_price(_cycle(TICKET_LADDER, int(pv["ticket"])))
			else:
				_career.set_board_price(_cycle(_board_ladder(), int(pv["board"])))
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
func _cycle(ladder: Array, current: int) -> int:
	for i in ladder.size():
		if int(ladder[i]) == current:
			return int(ladder[(i + 1) % ladder.size()])
	for v in ladder:
		if int(v) > current:
			return int(v)
	return int(ladder[0])

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
	if player.is_empty():
		_toast("That player is no longer available.")
		return
	var card: MakeOfferScreen = load("res://scenes/MakeOfferScreen.gd").new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)
	card.setup(player, {"id": from_club, "name": str(row.get("club_name", "?"))},
		int(row.get("fee", 0)), _career.cash)
	card.cancelled.connect(func() -> void:
		AudioManager.ui_select()
		card.queue_free())
	card.offer_made.connect(func(offer: int, yearly_wage: int, years: int, clauses: Array, bonus: int) -> void:
		AudioManager.ui_select()
		# The bid is only PLACED here — the club answers on the next week roll
		# (Career._resolve_pending_bids), as in the original's days-later response.
		var res := _career.place_bid_roster(pid, from_club, offer,
			maxi(1, yearly_wage / Contract.SEASON_WEEKS), years, clauses, bonus)
		_career.save()
		card.queue_free()
		_toast(str(res["msg"])))
	card.loan_requested.connect(func() -> void:
		AudioManager.ui_select()
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
		c.league_name, c.club_id)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.search_started.connect(func(criteria: Dictionary) -> void:
		AudioManager.ui_select()
		var foreign: Array = []
		for lid in criteria.get("leagues", []):
			if str(lid) != c.league_id:
				foreign.append_array(GameDB.clubs_in_league(str(lid)))
		c.start_scout_search(criteria, foreign)
		c.save())
	scr.player_pressed.connect(func(row: Dictionary) -> void:
		AudioManager.ui_select()
		_show_make_offer_card(row))

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
	var is_key := TransferMarket.is_key_player(club, pid)
	var fee := TransferMarket.asking_price(player, is_key, c.tier)
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

## The original-art CURRENT OFFERS (OFERTAS) screen: up to 5 transfer-listed players,
## each band showing his attribute strip + the newest bid (CLUB | CLUB OFFER | YEARLY
## WAGE | YEARS | CLAUSES), reversed from MANAGER.EXE + the owner's capture
## (docs/re/ofertas_screen_re.md; CurrentOffersScreen.gd). A band tap opens the REAL
## TEAM OFFER answer card (TeamOfferScreen, walkthrough run-3 frames 086-092);
## RETURN dismisses back to the transfer screen.
func _show_current_offers_screen() -> void:
	var scr: CurrentOffersScreen = load("res://scenes/CurrentOffersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var feed := func() -> void:
		var bands: Array = []
		for pid in _career.transfer_listed:
			var p := _career._find_in(_career.club_id, int(pid))
			if p.is_empty():
				continue
			bands.append({"player": p, "offers": _career.offers_for(int(pid))})
			if bands.size() == 5:
				break
		scr.setup(bands, "", _career.club_name, _career.league_name, _career.season,
			_career.week + 1, _career.club_id)
	feed.call()
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.band_pressed.connect(func(player: Dictionary) -> void:
		_show_team_offer(int(player.get("id", -1)), feed))

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
	var weekly := Contract.current_weekly(p, _career.tier)
	# CLUB FEE = the market value, YEARS = the full term, LEFT = years remaining
	# (our contract model's split of the original's YEARS|LEFT pair)
	scr.setup(p, GameDB.club(_career.club_id), offers,
		TransferMarket.value_of(p, _career.tier), Contract.yearly(weekly),
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
		int(sm.get("ticket_price", 0)), int(sm.get("board_price", 0)), _career.week + 1,
		_career.league_name, str(club.get("objective", "")))
	scr.improve_selected.connect(_on_stadium_improve)
	scr.back_pressed.connect(func() -> void: scr.queue_free())

## A SEATS offer card was ticked on the in-screen IMPROVEMENTS view: run the real Career
## expansion (start_works enforces cash + ceiling), persist, and re-mount the GROUND screen
## so it reflects the new WORK IN PROGRESS state.
func _on_stadium_improve(added: int, cost: int, weeks: int) -> void:
	if _career.start_works(added, cost, weeks):
		_career.save()
	_show_stadium_screen()

## The COMPETITIONS chooser on the hub CALEN/fixtures icon (the season-calendar slot): a
## PM98-chrome browse listing the two domestic cups, each routing to its CupScreen. The
## next-match readout stays on the RIVAL/opponent icon; a full fixture calendar is future.
func _show_competitions() -> void:
	# Build the list dynamically: the Charity Shield + European comps only appear once
	# qualified for (from the second season on), so route by an action tag, not an index.
	var rows: Array = []
	var acts: Array = []
	rows.append({"text": "SEASON FIXTURES", "value": "league calendar", "accent": Color(0.27, 1.0, 0.53)})
	acts.append("calendar")
	if not _career.charity_shield.is_empty():
		rows.append({"text": "CHARITY SHIELD", "value": _charity_status_word(), "accent": CupScreen.C_GOLD})
		acts.append("charity")
	rows.append({"text": "F.A. CUP", "value": _cup_status_word(_career.fa_cup), "accent": CupScreen.C_GOLD})
	acts.append("facup")
	rows.append({"text": "COCA-COLA CUP", "value": _cup_status_word(_career.league_cup), "accent": CupScreen.C_GOLD})
	acts.append("lcup")
	for key in ["european_cup", "uefa_cup", "cup_winners_cup"]:
		if _career.euro.has(key):
			var b: Dictionary = _career.euro[key]
			rows.append({"text": str(b.get("name", "Europe")).to_upper(),
				"value": _cup_status_word(b), "accent": CupScreen.C_GOLD})
			acts.append("euro:" + key)
	if not _career.supercup.is_empty():
		rows.append({"text": "EUROPEAN SUPERCUP", "value": _oneoff_status_word(_career.supercup),
			"accent": CupScreen.C_GOLD})
		acts.append("supercup")
	if not _career.intercontinental.is_empty():
		rows.append({"text": "INTERCONTINENTAL CUP", "value": _oneoff_status_word(_career.intercontinental),
			"accent": CupScreen.C_GOLD})
		acts.append("intercont")
	_mount_browse("%s  -  COMPETITIONS" % _career.club_name, "Cups, shield & Europe", rows,
		func(i: int) -> void:
			_dismiss_career_browse()
			_open_competition(acts[i]),
		func() -> void: _dismiss_career_browse())

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

## Route a COMPETITIONS chooser pick to its screen (each is a Cup.gd bracket on CupScreen,
## bar the single-match Charity Shield), around the competition's own trophy art.
func _open_competition(act: String) -> void:
	if act == "calendar":
		_show_calendar()
	elif act == "charity":
		_show_charity_shield()
	elif act == "facup":
		_show_cup_screen(_career.fa_cup, "F.A. CUP", "res://art/screens/cup/facup.png")
	elif act == "lcup":
		_show_cup_screen(_career.league_cup, "COCA-COLA CUP", "res://art/screens/cup/cocacola.png")
	elif act.begins_with("euro:"):
		var key := act.substr(5)
		var b: Dictionary = _career.euro.get(key, {})
		_show_cup_screen(b, str(b.get("name", "EUROPE")).to_upper(), _euro_emblem(key))
	elif act == "supercup":
		_show_one_off_final(_career.supercup, "EUROPEAN SUPERCUP",
			"res://art/screens/cup/supercopa.png", "European Supercup",
			"European Cup winners v Cup Winners' Cup winners")
	elif act == "intercont":
		_show_one_off_final(_career.intercontinental, "INTERCONTINENTAL CUP",
			"res://art/screens/cup/intercont.png", "Intercontinental Cup",
			"European Cup winners v the South American champions")

## The trophy art path for a European competition.
func _euro_emblem(key: String) -> String:
	match key:
		"european_cup":
			return "res://art/screens/cup/ligacamp.png"
		"uefa_cup":
			return "res://art/screens/cup/uefa.png"
		_:
			return "res://art/screens/cup/recopa.png"

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
	var out: Array = []
	for e in scored.slice(0, 48):
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
			var pos: int = _career.objective_pos if user \
				else int(Career.objective_for(cid, lid, clubs, GameDB.leagues)["pos"])
			var mgr := _career.manager_name if user else _mgr_of(cid)
			rows.append([str(cl["name"]), mgr, _objective_label(pos, total, tier), user])
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


## A one-word status of the Charity Shield for the competitions list.
func _charity_status_word() -> String:
	return _oneoff_status_word(_career.charity_shield)

## A one-word status of any single-match final (shield / supercup / intercontinental).
func _oneoff_status_word(res: Dictionary) -> String:
	if res.is_empty():
		return "not played"
	var w := int(res.get("winner_id", -1))
	if w == _career.club_id:
		return "WINNERS"
	return "won by %s" % _cup_name(w).substr(0, 14)

## The Charity Shield as a CupScreen overlay: the season's curtain-raiser (champions v
## F.A. Cup winners), a single neutral-venue match around the real CHARITY shield art.
func _show_charity_shield() -> void:
	_show_one_off_final(_career.charity_shield, "CHARITY SHIELD",
		"res://art/screens/cup/charity.png", "Charity Shield", "Champions v F.A. Cup winners")

## A single-match final (Charity Shield / European Supercup / Intercontinental Cup) as a
## CupScreen overlay: the manager's result if his club is in it, else who lifted it, around
## the competition's own trophy. `res` is a Cup.single_neutral_match dict (home_id/away_id/
## winner_id). Display-only, tap-to-dismiss.
func _show_one_off_final(res: Dictionary, title: String, emblem: String,
		round_label: String, sub: String) -> void:
	var scr: CupScreen = load("res://scenes/CupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var cid: int = _career.club_id
	var status := "NOT PLAYED"
	var status_col: Color = CupScreen.C_DIM
	var run_rows: Array = []
	var draw_rows: Array = []
	if not res.is_empty():
		var w := int(res.get("winner_id", -1))
		var home := int(res.get("home_id", -1))
		var away := int(res.get("away_id", -1))
		var pens: String = "  (pens)" if res.get("decided", "") == "pens" else ""
		var score := "%d-%d" % [int(res.get("hg", 0)), int(res.get("ag", 0))]
		draw_rows = [{"line": "%s  v  %s   %s%s" % [
			_cup_name(home), _cup_name(away), score, pens],
			"mine": cid == home or cid == away}]
		if w == cid:
			status = "WINNERS!"
			status_col = CupScreen.C_GOLD
		elif cid == home or cid == away:
			status = "RUNNERS-UP"
			status_col = CupScreen.C_LOSS
		else:
			status = "WON BY %s" % _cup_name(w).substr(0, 12).to_upper()
			status_col = CupScreen.C_TEXT
		if cid == home or cid == away:
			var opp := away if cid == home else home
			var won := w == cid
			run_rows = [{"round": round_label,
				"line": "%s %s  %s%s" % ["bt" if won else "lost to",
					_cup_name(opp).substr(0, 16), score, pens],
				"accent": CupScreen.C_WIN if won else CupScreen.C_LOSS}]
	scr.setup(_career.club_name, "", str(res.get("season", _career.season)), status, status_col,
		sub, run_rows, round_label, draw_rows, 0, title, emblem)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

## A one-word status of the manager's run in a cup, for the competitions list.
func _cup_status_word(b: Dictionary) -> String:
	if b.is_empty():
		return "not started"
	var champ := int(b.get("champion_id", -1))
	if champ == _career.club_id:
		return "WINNERS"
	if champ != -1:
		return "won by %s" % _cup_name(champ).substr(0, 14)
	return "still in" if Cup.still_in(b, _career.club_id) else "out"

## A cup screen as a full-screen overlay over the hub: the manager's run through the
## knockout + the latest round's draw, around the competition's authentic trophy art.
## Built from a Cup.gd bracket. Display-only; tap to dismiss.
func _show_cup_screen(b: Dictionary, title: String, emblem_path: String) -> void:
	var v := _cup_view(b)
	var scr: CupScreen = load("res://scenes/CupScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_career.club_name, "", _career.season, v["status"], v["status_col"],
		v["sub"], v["run_rows"], v["draw_label"], v["draw_rows"], v["draw_more"],
		title, emblem_path)
	scr.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			scr.queue_free())

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

## Build the CupScreen payload from a Cup.gd bracket: status, the manager's per-round run,
## and the latest round's draw (manager's tie first, the rest capped).
func _cup_view(b: Dictionary) -> Dictionary:
	var cid: int = _career.club_id
	var cup_nm: String = str(b.get("name", "Cup")) if not b.is_empty() else "Cup"
	var out := {"status": "NOT DRAWN", "status_col": CupScreen.C_DIM,
		"sub": "The %s has not started." % cup_nm, "run_rows": [],
		"draw_label": "", "draw_rows": [], "draw_more": 0}
	if b.is_empty():
		return out
	var rounds: Array = b.get("rounds", [])

	# Group phase (the European Cup before its knockout): show the group standings + the
	# manager's group results instead of a knockout draw.
	var groups: Array = Cup.group_tables(b)
	if not groups.is_empty() and rounds.is_empty():
		return _cup_group_view(b, groups, out)

	# The manager's tie in each played round -> a run row.
	var run_rows: Array = []
	for rnd in rounds:
		for tie in rnd.get("ties", []):
			if int(tie["home_id"]) != cid and int(tie.get("away_id", -1)) != cid:
				continue
			var label := str(rnd.get("label", ""))
			if tie.get("bye", false):
				run_rows.append({"round": label, "line": "bye", "accent": CupScreen.C_DIM})
				break
			var won := int(tie["winner_id"]) == cid
			var opp := int(tie["away_id"]) if int(tie["home_id"]) == cid else int(tie["home_id"])
			var line := "%s %s  %s" % ["bt" if won else "lost to", _cup_name(opp).substr(0, 16),
				_cup_score_for(tie, cid)]
			run_rows.append({"round": label, "line": line,
				"accent": CupScreen.C_WIN if won else CupScreen.C_LOSS})
			break
	out["run_rows"] = run_rows

	# Status line.
	var champ := int(b.get("champion_id", -1))
	# A competition the manager never entered (European comps he didn't qualify for): no
	# run, not a survivor. Domestic cups always include the whole division, so this never
	# fires there. Still show the trophy + the draw, just flagged as not qualified.
	if not Cup.still_in(b, cid) and run_rows.is_empty():
		out["status"] = "NOT QUALIFIED"
		out["status_col"] = CupScreen.C_DIM
		if champ != -1:
			out["sub"] = "%s won the %s." % [_cup_name(champ), cup_nm]
		else:
			out["sub"] = "You did not qualify. %d clubs remain." % (b.get("survivors", []) as Array).size()
	elif champ == cid:
		out["status"] = "WINNERS!"
		out["status_col"] = CupScreen.C_GOLD
		out["sub"] = "You have won the %s." % cup_nm
	elif champ != -1:
		out["status"] = "KNOCKED OUT"
		out["status_col"] = CupScreen.C_LOSS
		out["sub"] = "%s won the cup." % _cup_name(champ)
	else:
		var remain: int = (b.get("survivors", []) as Array).size()
		var k := Cup.weeks_until_next(b, _career.week)
		var nxt := Cup.next_label(b)
		var wk_txt := (", %s in %d wk%s" % [nxt, k, "" if k == 1 else "s"]) if k >= 0 and nxt != "" else ""
		if Cup.still_in(b, cid):
			out["status"] = "STILL IN"
			out["status_col"] = CupScreen.C_WIN
			out["sub"] = "%d clubs remain%s" % [remain, wk_txt]
		else:
			out["status"] = "KNOCKED OUT"
			out["status_col"] = CupScreen.C_LOSS
			out["sub"] = "%d clubs remain%s" % [remain, wk_txt]

	# The latest round's draw: manager's tie first, the rest capped to fit.
	if not rounds.is_empty():
		var last: Dictionary = rounds[-1]
		out["draw_label"] = str(last.get("label", ""))
		var ties: Array = (last.get("ties", []) as Array).duplicate()
		ties.sort_custom(func(x, y):
			var xm: bool = int(x["home_id"]) == cid or int(x.get("away_id", -1)) == cid
			var ym: bool = int(y["home_id"]) == cid or int(y.get("away_id", -1)) == cid
			return xm and not ym)
		var cap := 9
		var draw_rows: Array = []
		for tie in ties.slice(0, cap):
			var mine: bool = int(tie["home_id"]) == cid or int(tie.get("away_id", -1)) == cid
			draw_rows.append({"line": _cup_tie_line(tie), "mine": mine})
		out["draw_rows"] = draw_rows
		out["draw_more"] = maxi(0, ties.size() - cap)
	return out


## The CupScreen payload during the European Cup group phase: the manager's group table in
## THE DRAW panel, his matchday results in YOUR CUP RUN, and a group-position status.
func _cup_group_view(b: Dictionary, groups: Array, out: Dictionary) -> Dictionary:
	var cid: int = _career.club_id
	var cup_nm: String = str(b.get("name", "Cup"))
	var gs: Dictionary = b.get("group_stage", {})
	var advance := int(gs.get("advance", 2))
	# The manager's group (else group A, when browsing a comp he's not in).
	var my_gi := -1
	for gi in groups.size():
		for row in groups[gi].get("table", []):
			if int(row.get("id", -1)) == cid:
				my_gi = gi
	var gi: int = my_gi if my_gi >= 0 else 0
	var grp: Dictionary = groups[gi]
	var ranked: Array = Cup._sorted_table(grp.get("table", []))
	out["draw_label"] = "GROUP %s" % char(65 + gi)

	# Standings rows (top `advance` flagged by colour via the manager-gold "mine").
	var draw_rows: Array = []
	var pos_me := -1
	for i in ranked.size():
		var row: Dictionary = ranked[i]
		if int(row.get("id", -1)) == cid:
			pos_me = i + 1
		draw_rows.append({"line": "%d %s  P%d  %d-%d  %dpts" % [i + 1,
			_cup_name(int(row.get("id", -1))).substr(0, 13), int(row.get("p", 0)),
			int(row.get("gf", 0)), int(row.get("ga", 0)), int(row.get("pts", 0))],
			"mine": int(row.get("id", -1)) == cid})
	out["draw_rows"] = draw_rows

	# The manager's matchday results.
	var run_rows: Array = []
	if my_gi >= 0:
		var md := 0
		for md_results in grp.get("results", []):
			md += 1
			for m in md_results:
				if int(m["h"]) != cid and int(m["a"]) != cid:
					continue
				var home := int(m["h"]) == cid
				var mine_g := int(m["hg"]) if home else int(m["ag"])
				var their_g := int(m["ag"]) if home else int(m["hg"])
				var opp := int(m["a"]) if home else int(m["h"])
				var verb := "drew" if mine_g == their_g else ("bt" if mine_g > their_g else "lost to")
				var acc: Color = CupScreen.C_DIM if mine_g == their_g else \
					(CupScreen.C_WIN if mine_g > their_g else CupScreen.C_LOSS)
				run_rows.append({"round": "Matchday %d" % md,
					"line": "%s %s  %d-%d" % [verb, _cup_name(opp).substr(0, 14), mine_g, their_g], "accent": acc})
	out["run_rows"] = run_rows

	# Status: in / through / out of the group.
	var qualified := bool(gs.get("qualified", false))
	if my_gi < 0:
		out["status"] = "NOT QUALIFIED"
		out["status_col"] = CupScreen.C_DIM
		out["sub"] = "You are not in the %s." % cup_nm
	elif qualified and pos_me > 0 and pos_me <= advance:
		out["status"] = "QUALIFIED"
		out["status_col"] = CupScreen.C_GOLD
		out["sub"] = "Through to the knockout from Group %s." % char(65 + gi)
	elif qualified:
		out["status"] = "GROUP EXIT"
		out["status_col"] = CupScreen.C_LOSS
		out["sub"] = "Out at the group stage (Group %s)." % char(65 + gi)
	else:
		out["status"] = "GROUP STAGE"
		out["status_col"] = CupScreen.C_WIN if (pos_me > 0 and pos_me <= advance) else CupScreen.C_TEXT
		var k := Cup.weeks_until_next(b, _career.week)
		var nxt := Cup.next_label(b)
		var wk_txt := (", %s in %d wk%s" % [nxt, k, "" if k == 1 else "s"]) if k >= 0 and nxt != "" else ""
		out["sub"] = "Group %s: %d%s of %d%s" % [char(65 + gi), pos_me,
			_ord_suffix(pos_me), ranked.size(), wk_txt]
	return out


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
## leaves the career.
func _menu_action(action: String, scr: MenuScreen) -> void:
	AudioManager.ui_select()
	match action:
		"exit": _leave_career()
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

## The TRAINING screen on the hub's staff (EMPLE) icon. Tap the top row to cycle the
## training intensity (Light/Normal/Intensive -- the lever that trades faster player
## development against injury risk); the rest is the squad's development trend
## (improving / holding / declining by age + ability). Interim PM98-chrome BrowseScreen.
## NB: EMPLE is the original game's employees/staff slot; a full staff screen is deferred,
## training is the interim occupant of this icon (flagged in the handoff).
func _show_training() -> void:
	var c := _career
	var rows: Array = []
	var payload: Array = []
	rows.append({"text": "Training intensity:   %s" % c.training_intensity,
		"value": "tap to change", "accent": Color(1.0, 0.87, 0.0)})
	payload.append({"a": "cycle"})

	# Squad development, improving players first, then by ability.
	var squad: Array = c.my_squad().duplicate()
	var order := {"up": 0, "hold": 1, "down": 2}
	squad.sort_custom(func(a, b):
		var ta := Training.trend(a)
		var tb := Training.trend(b)
		if order[ta["dir"]] != order[tb["dir"]]:
			return order[ta["dir"]] < order[tb["dir"]]
		return int(ta["ability"]) > int(tb["ability"]))
	if squad.is_empty():
		rows.append({"text": "No players to develop yet.", "enabled": false})
		payload.append({"a": "noop"})
	for p in squad:
		var t := Training.trend(p)
		var word := "improving" if t["dir"] == "up" else ("declining" if t["dir"] == "down" else "at his peak")
		rows.append({
			"text": "%s  %-16s  CA %d" % [t["arrow"], str(t["name"]).substr(0, 16), int(t["ability"])],
			"value": word, "accent": t["colour"], "enabled": false,
		})
		payload.append({"a": "noop"})

	_mount_browse("%s  -  TRAINING" % c.club_name,
		"Intensive develops faster but risks more injuries", rows,
		func(i: int) -> void:
			if i < payload.size() and payload[i]["a"] == "cycle":
				_career.cycle_training()
				_career.save()
				_show_training(),
		func() -> void: _dismiss_career_browse())

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

func _show_transfers() -> void:
	var c := _career
	var rows: Array = []
	var payload: Array = []
	rows.append("VIEW TRANSFER MARKET   (the screen)"); payload.append({"t": "screen"})
	rows.append("TRANSFER MARKET"); payload.append({"t": "market"})
	rows.append("MY SQUAD   (sell / RENEW)"); payload.append({"t": "squad"})
	rows.append("FREE AGENTS   (%d)   -  sign for £0 + wages" % c.free_agents.size()); payload.append({"t": "free"})
	rows.append("LOAN MARKET   -  take a player for the season"); payload.append({"t": "loan"})
	if Staff.has_scout(c.staff):
		rows.append("SCOUT REPORT   (%d targets)" % c.scout_targets().size()); payload.append({"t": "scout"})
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
		"free": _push(_show_free_agents)
		"loan": _push(_show_loan_market)
		"scout": _push(_show_scout_report)
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
		var demand := Contract.demanded_weekly(p, _career.tier)
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
	var demand := Contract.demanded_weekly(player, _career.tier)
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
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
		var wage := Contract.current_weekly(p, _career.tier)
		var tag := "  EXPIRING" if Contract.is_expiring(p) else ""
		if p.get("on_loan"):
			tag = "  [ON LOAN]"
		elif _career.is_listed(pid):
			tag += "  [LISTED]"
		rows.append("%-15s %s CA%2d £%s/wk %dy%s" % [
			p.get("name", "?"), pos, ca, _fmt_int(wage), yrs, tag])
		payload.append(p)
	_set_view("MY SQUAD  (%d)" % squad.size(),
		"£%s/wk wage bill  -  tap a player to RENEW, list or sell" % _fmt_int(_career.player_weekly_wage()),
		rows, payload, func(p): _push(_show_player_deal.bind(p)))

func _show_player_deal(p: Dictionary) -> void:
	var pid := int(p["id"])
	var tier := _career.tier
	var weekly := Contract.current_weekly(p, tier)
	var auto: bool = bool(p.get("auto_renew", false))
	var rows: Array = []
	var payload: Array = []
	rows.append("RENEW contract  (negotiate wage)"); payload.append({"a": "renew"})
	rows.append("Auto-renew at expiry:  %s" % ("ON" if auto else "OFF")); payload.append({"a": "auto"})
	rows.append("Remove from transfer list" if _career.is_listed(pid) else "Place on transfer list")
	payload.append({"a": "list"})
	rows.append("Get an offer / sell now"); payload.append({"a": "sell"})
	var attrs: Dictionary = p.get("attrs", {})
	var expiring := "  -  EXPIRING" if Contract.is_expiring(p) else ""
	_set_view(p.get("name", "?"),
		"CA %d  -  CLUB FEE £%s  -  YEARLY WAGE £%s (£%s/mo)  -  contract %dy%s" % [
			int(attrs.get("CA", 0)), _fmt_int(TransferMarket.value_of(p, tier)),
			_fmt_int(Contract.yearly(weekly)), _fmt_int(Contract.monthly(weekly)),
			int(p.get("contract_years", 1)), expiring],
		rows, payload, func(it): _player_deal_action(p, it["a"]))

func _player_deal_action(p: Dictionary, a: String) -> void:
	var pid := int(p["id"])
	match a:
		"renew":
			_push(_show_renew.bind(p))
		"auto":
			_career.set_auto_renew(pid, not bool(p.get("auto_renew", false)))
			_career.save()
			_show_player_deal(p)            # refresh the ON/OFF label in place
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

## The RENEW negotiation: a player wants a wage to put pen to a new deal. You can hold his
## current terms (a lowball he may refuse), meet his demand, or better it to lock him in.
func _show_renew(p: Dictionary) -> void:
	var tier := _career.tier
	var weekly := Contract.current_weekly(p, tier)
	var demand := Contract.demanded_weekly(p, tier)
	var rows: Array = []
	var payload: Array = []
	for opt in Contract.renewal_options(p, tier):
		rows.append("%-30s £%s/wk  %dy" % [opt["label"], _fmt_int(int(opt["weekly"])), int(opt["years"])])
		payload.append(opt)
	_set_view("Renew %s" % p.get("name", "?"),
		"On £%s/wk now  -  he wants £%s/wk  -  pick an offer" % [_fmt_int(weekly), _fmt_int(demand)],
		rows, payload, func(opt): _renew_action(p, int(opt["weekly"])))

func _renew_action(p: Dictionary, offer_weekly: int) -> void:
	var res := _career.renew(int(p["id"]), offer_weekly)
	_career.save()
	_nav.pop_back()                      # drop the renew screen
	_push(_show_deal_result.bind(res["msg"]))

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


## The end-of-season board review (#14): the board passes its verdict, your reputation is
## updated, and the season either rolls on, ends in a sacking with job offers, or invites a
## move to a bigger club. The career history is always one tap away.
func _show_end_of_season() -> void:
	var rv := _career.board_review()
	var rows: Array = []
	var payload: Array = []
	rows.append("Final position: %d%s of %d" % [
		int(rv["finished_pos"]), _ord_suffix(int(rv["finished_pos"])), _career.standings().size()])
	payload.append({})
	rows.append("Board objective: %s" % _career.objective_text)
	payload.append({})
	rows.append("Reputation: %d  -  %s" % [int(rv["reputation"]), rv["rep_label"]])
	payload.append({})
	rows.append("")
	payload.append({})
	if bool(rv["sacked"]):
		var why := "relegation" if str(rv["reason"]) == "relegated" else "falling short of the board's target"
		rows.append("The board has SACKED you after %s." % why)
		payload.append({})
		_generate_offers(false)
		rows.append("▶  See which clubs want you (%d)" % _career.pending_offers.size())
		payload.append({"act": "offers"})
	elif bool(rv["headhunted"]):
		rows.append("Verdict: ACHIEVED  -  and bigger clubs have noticed.")
		payload.append({})
		_generate_offers(true)
		rows.append("▶  Stay at %s next season" % _career.club_name)
		payload.append({"act": "stay"})
		rows.append("▶  Hear out %d job offer%s" % [
			_career.pending_offers.size(), "" if _career.pending_offers.size() == 1 else "s"])
		payload.append({"act": "offers"})
	else:
		var verdict := "ACHIEVED - you keep your job" if bool(rv["objective_met"]) \
			else "MISSED - the board expects better"
		rows.append("Verdict: %s" % verdict)
		payload.append({})
		rows.append("▶  Start next season")
		payload.append({"act": "next"})
	rows.append("▶  Your managerial record")
	payload.append({"act": "record"})
	_set_view("End of %s" % _career.season, "%s" % _career.club_name, rows, payload,
		_activate_end_of_season)

func _activate_end_of_season(item: Dictionary) -> void:
	match str(item.get("act", "")):
		"next":
			_next_season()
		"stay":
			# Decline the suitors and sign up for another season at the current club.
			_career.pending_offers = []
			_career.headhunt_pending = false
			_next_season()
		"offers":
			_show_job_offers()
		"record":
			_show_manager_career()

func _next_season() -> void:
	# Carry the live squads, cash and tactics into the new season; contracts tick
	# down and unrenewed players leave on a free (handled in Career.advance_season).
	# TalentDB's pool rides along: real talents due in the new season arrive (empty
	# pool -- no talent_pool.json -- injects nothing and the rollover is vanilla).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion(), TalentDB.talents)
	_career.save()
	_enter_career()


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
