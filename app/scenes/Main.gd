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
var _seleccion: SeleccionScreen = null  # active new-career SELECCION overlay (faithful art)
var _database: DataBaseScreen = null    # active DATA BASE squad-view overlay (reversed dbasewin)

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
			and not OS.has_environment("PM98_MANAGER_SHOT") and not OS.has_environment("PM98_FICHA_SHOT"):
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
		int(home.get("id", -1)), int(away.get("id", -1)))
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
	# T2 #5: the stadium WORKS sub-view, then the overview with an expansion in progress.
	_career.cash = 20_000_000
	_show_stadium_screen()
	_show_stadium_works()
	await _settle()
	_save_shot(dir, "stadium_works.png")
	_career.start_works(5000, 3_900_000, 13)
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
				or c is PlayerInfoScreen or c is RivalScreen:
			c.queue_free()
	_browse = null


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
	scr.setup(club, manager, cash, youth_enabled, season, week)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.youth_pressed.connect(_show_youth_screen)
	scr.player_pressed.connect(_open_player_info.bind(club))

## The DATA BASE squad view (the reversed dbasewin.exe browser) for a club dict: the four
## GOALKEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS columns over FONDO DBASE. A row raises that
## player's FICHA; RETURN or a tap on empty space dismisses. See DataBaseScreen.gd.
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
	_database.player_pressed.connect(_open_player_info.bind(club))

## PLAYER INFORMATION (FICHA) overlay for one squad player, raised over the SQUAD screen.
## tier (for value/wage) comes from the club's division; OK / a tap dismisses it. When the
## player is one of the MANAGER'S OWN squad, the source RENEW / TRANSFER / SACK buttons are
## live (PM98 opens these from SQUAD MANAGEMENT); for another club's player (DATA BASE /
## opponent browse) the card is read-only. The Career hooks mutate the live roster dict (same
## object the overlay holds), so a RENEW updates YEARS in place and a SACK removes the player.
func _open_player_info(player: Dictionary, club: Dictionary) -> void:
	var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
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
		tier: int, my_id: int) -> void:
	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(rows, title_left, season, week_label, tier, my_id)
	scr.back_pressed.connect(func() -> void:
		AudioManager.ui_select()
		scr.queue_free())
	scr.club_selected.connect(func(id: int) -> void:
		AudioManager.ui_select()
		var club := _club_with_roster(id) if _career != null and id == _career.club_id else GameDB.club(id)
		_open_database_squad(club))

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
func _open_match(home: Dictionary, away: Dictionary, hg: int, ag: int,
		lines: Array, _sub: String, on_back: Callable) -> void:
	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(str(home.get("name", "?")), str(away.get("name", "?")), hg, ag, lines,
		int(home.get("id", -1)), int(away.get("id", -1)))
	scr.back_pressed.connect(func() -> void:
		scr.queue_free()
		if on_back.is_valid():
			on_back.call())
	# The reversed MATCH OPTIONS view picker (WATCH/HIGHLIGHTS/BRIEF/RESULTS), source-exact
	# rects from FUN_004e2630 (docs/re/match_view_re.md). Overlays the running match: BRIEF
	# watches the commentary, RESULTS skips to full time; WATCH/HIGHLIGHTS show their source
	# status (2D simulador = next build step; 3D .p3d data absent).
	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	opt.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opt)
	opt.picked.connect(func(mode: String) -> void:
		match mode:
			"results":
				scr.seek(90.0)
			"watch":
				# WATCH -> the 2D GRAFICO simulador, fed the same timeline as BRIEF so the
				# two views stay in lock-step (clock/score/possession). BRIEF drops back to
				# the commentary screen underneath; EXIT leaves the match.
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
		opt.queue_free())


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
		# An in-progress career in its first seasons still gets the guaranteed gem on resume.
		var before: int = (_career.youth as Array).size()
		_career._ensure_wonderkid()
		if (_career.youth as Array).size() != before:
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
		"Full time", func() -> void: _show_match_pick(league, null))


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
	_seleccion.career_begun.connect(_begin_career)
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

func _begin_career(manager_name: String, league: Dictionary, club: Dictionary) -> void:
	AudioManager.ui_select()
	var league_clubs := GameDB.clubs_in_league(league["id"])
	_career = Career.create(club, league, league_clubs, GameDB.leagues)
	_career.manager_name = manager_name
	_career.save()
	_dismiss_seleccion()
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
	# Next-fixture opponent for the hub's central stack.
	var fx := c.manager_fixture()
	var opp_name := ""
	var opp_id := -1
	var is_home := true
	if not fx.is_empty():
		is_home = int(fx[0]) == c.club_id
		opp_id = int(fx[1]) if is_home else int(fx[0])
		opp_name = str(GameDB.club(opp_id).get("name", ""))
	_hub.setup(c.club_name, c.league_name, c.season, c.cash,
		"%d%s" % [c.position(), _ord_suffix(c.position())], c.club_id,
		c.week + 1, opp_name, opp_id, is_home, c.manager_name)
	AudioManager.play_music()   # resume the menu theme on return from a match

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
	# Narrate the EXACT stored scoreline so feed and table agree; the stat engine's own
	# scorers ride along in res["goals"] (empty -> narrate re-rolls by finishing weight).
	var m := MatchCommentary.narrate(rng, home, away, int(res["hg"]), int(res["ag"]), res.get("goals", []))
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
	AudioManager.ui_select()
	match action:
		"exit":
			get_tree().quit()
		"database":
			scr.queue_free()        # reveal the home browse mounted beneath
			if _browse == null or not is_instance_valid(_browse):
				_show_home()
		_:
			scr.queue_free()
			_show_career_select()

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
	var tac := _tactics()
	scr.setup(_mgr_club(), tac, "", _career.league_name, _career.season, _career.week + 1)
	# RETURN dismisses; TACTICS opens the TEAM TACTICS modal. Tapping a player selects him;
	# tapping a second player swaps them into/within the XI (PM98's line-up edit), persisted
	# via Career. The ARROW buttons page the squad list.
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_screen())
	scr.xi_changed.connect(func() -> void:
		AudioManager.ui_select()
		_save_tactics(tac)
		_career.save())

## The original-art TEAM TACTICS modal (ma_9) over a real LINE-UP backdrop: the ATTACK |
## DEFENCE control panel. Each control mutates the career Tactics live (its ratings() feed
## the match engine), persisted on `changed`; SAVE writes a named preset; OK / RETURN close
## both overlays. (scenes/TacticsScreen.gd; the lever att/def model lives in Tactics.gd.)
func _show_tactics_screen() -> void:
	var bg: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.setup(_mgr_club(), _tactics(), "", _career.league_name, _career.season, _career.week + 1)
	var scr: TacticsScreen = load("res://scenes/TacticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	scr.setup(_tactics())
	scr.changed.connect(func(d: Dictionary) -> void:
		_career.tactics = d
		_career.save())
	scr.save_requested.connect(func(d: Dictionary) -> void:
		var t := Tactics.from_dict(d)
		t.save_preset("%s %s" % [t.formation, t.marking])
		_toast("Tactics saved"))
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
	scr.setup(_career.youth, "", _career.club_name, "£%s" % _fmt_int(_career.cash))
	scr.promote_requested.connect(func(pid: int) -> void:
		_career.promote_youth(int(pid))
		_career.save()
		scr.setup(_career.youth, "", _career.club_name, "£%s" % _fmt_int(_career.cash))
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
				_career.season, _career.week + 1)

## The STAFF (EMPLE) screen on the hub's staff icon: hire/sack the backroom team (a TRAINER
## speeds development, a PHYSIO cuts injuries, a YOUTH COACH improves the academy -- Staff.gd),
## with the wage bill + live effect. The TRAINING button opens the training screen (the trainer
## context); RETURN -> hub. Replaces the interim training-on-the-staff-icon (now nested under it).
func _show_staff_screen() -> void:
	var scr: StaffScreen = load("res://scenes/StaffScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	var refresh := func() -> void:
		scr.setup(_career.staff, _career.staff_pool, "", _career.club_name, "£%s" % _fmt_int(_career.cash))
	refresh.call()
	scr.hire_requested.connect(func(cid: int) -> void:
		_career.hire_staff(int(cid)); _career.save(); refresh.call())
	scr.sack_requested.connect(func(mid: int) -> void:
		_career.sack_staff(int(mid)); _career.save(); refresh.call())
	# TRAINING opens the training browse, which dismisses back to the hub; free the staff
	# overlay first so the hub doesn't re-raise over an orphaned staff screen.
	scr.training_requested.connect(func() -> void:
		scr.queue_free()
		_show_training())
	scr.back_pressed.connect(func() -> void: scr.queue_free())

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
	scr.setup(c.market(), c.club_name, "", c.season, c.cash, win, c.offers_left, c.week + 1)
	# The screen owns its input now (the ARROW scroll buttons page the list); a non-scroll
	# tap emits back_pressed to dismiss the overlay.
	scr.back_pressed.connect(func() -> void: scr.queue_free())

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
## Stadium expansion options (added capacity, £ cost, weeks to build). ~£780/seat.
const STADIUM_WORKS := [
	{"added": 2000, "cost": 1_600_000, "weeks": 6},
	{"added": 5000, "cost": 3_900_000, "weeks": 13},
	{"added": 10000, "cost": 7_500_000, "weeks": 24},
]

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
	scr.setup(_career.club_name, "", _career.season, ground,
		cap, seated, cap - seated, int(round(cap / 27.0)), _career.works_status(),
		int(sm.get("ticket_price", 0)), int(sm.get("board_price", 0)), _career.week + 1,
		_career.league_name)
	scr.works_pressed.connect(_show_stadium_works)
	scr.back_pressed.connect(func() -> void: scr.queue_free())

## The WORKS sub-view: pick a ground expansion (spend cash now, capacity rises after the
## build weeks). PM98-chrome browse over the stadium overview. Reverses FUN_0051bd80's
## intent (a real spending lever) without its facility-counter sub-layout.
func _show_stadium_works() -> void:
	var rows: Array = []
	var payload: Array = []
	if not _career.works.is_empty():
		rows.append({"text": "Works already in progress: %s remaining" % _career.works_status(),
			"enabled": false, "accent": Color(0.98, 0.86, 0.45)})
		payload.append(null)
	else:
		for opt in STADIUM_WORKS:
			var affordable: bool = _career.cash >= int(opt["cost"])
			var room: bool = _career.stadium_capacity + int(opt["added"]) <= Career.MAX_STADIUM
			rows.append({
				"text": "Expand +%s   (~%d weeks)" % [Career._grp(int(opt["added"])), int(opt["weeks"])],
				"value": "£%s" % Career._grp(int(opt["cost"])),
				"enabled": affordable and room,
				"accent": null if (affordable and room) else Color(0.6, 0.55, 0.42),
			})
			payload.append(opt)
		if _career.stadium_capacity >= Career.MAX_STADIUM:
			rows = [{"text": "The ground is already at maximum capacity.", "enabled": false}]
			payload = [null]
	_mount_browse("%s  -  GROUND WORKS" % _career.club_name,
		"Spend now, capacity rises when the build completes", rows,
		func(i: int) -> void:
			var opt: Variant = payload[i]
			if opt != null and _career.start_works(int(opt["added"]), int(opt["cost"]), int(opt["weeks"])):
				_career.save()
				_show_stadium_screen(),
		func() -> void: _show_stadium_screen())

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

## South American country tags in game_db (Spanish), for the Intercontinental Cup.
const SA_COUNTRIES := ["Argentina", "Brasil", "Uruguay", "Chile", "Colombia", "Perú",
	"Bolivia", "Paraguay", "Ecuador", "Venezuela"]

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
## via _set_view (re-shown on Back); info actions toast on the hub itself; CONTINUE plays
## the week (or opens end-of-season when the campaign is over); EXIT leaves the career.
func _menu_action(action: String, scr: MenuScreen) -> void:
	AudioManager.ui_select()
	match action:
		"exit": _leave_career()
		"save":
			_career.save()
			scr.toast("Game saved")
		"news": _show_club_news()
		"staff": _show_staff_screen()
		"fixtures": _show_competitions()
		"opponent": _show_opponent(scr)
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
		# The hub PLAYERS button (VENDE icon, action "sell") opens the real SQUAD MANAGEMENT
		# (PLANTILLA) screen, as the original does -- your squad, where a player tap raises his
		# PLAYER INFORMATION (RENEW / TRANSFER / SACK; TRANSFER = list him for sale). Was the
		# invented `_show_transfers` BrowseScreen menu (APP_VS_SPEC_AUDIT B1 SUBSTITUTE / B2
		# orphaned SquadScreen).
		"sell": _show_squad_screen()
		"results": _show_results_screen()

## OPPONENT: the real VIEW RIVAL (VERRIVAL) scouting screen for the manager's next opponent
## (docs/re/rival_screen_re.md; RivalScreen.gd) -- the opponent XI, team rating and formation,
## with the report DEPTH gated by the manager's ASSISTANT (none -> the "hire an Assistant"
## message). Replaces the WRONG-SCREEN DATA BASE browser (APP_VS_SPEC_AUDIT B1). A bye week
## has no opponent, so it just reports that.
func _show_opponent(scr: MenuScreen) -> void:
	var fx := _career.manager_fixture()
	if fx.is_empty():
		scr.toast("No match this week (bye)")
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
		_career.week + 1)
	scr.back_pressed.connect(func() -> void: scr.queue_free())
	scr.tactics_pressed.connect(func() -> void:
		scr.queue_free()
		_show_tactics_screen())

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

## The MENUPRINCIPAL NEWS view: the club's news feed (injuries, suspensions, returns
## and the weekly result headline) as a PM98-chrome browse over the hub, newest first,
## colour-coded by kind. Driven by Career.news_log. RETURN -> hub.
func _show_club_news() -> void:
	var rows: Array = []
	var feed: Array = _career.news_log
	if feed.is_empty():
		rows.append({"text": "No club news yet -- play a week.", "enabled": false})
	for n in feed:
		var kind: String = str(n.get("kind", "")) if n is Dictionary else ""
		var text: String = str(n.get("text", n)) if n is Dictionary else str(n)
		var wk: int = int(n.get("week", 0)) if n is Dictionary else 0
		rows.append({
			"text": ("Wk %2d  %s" % [wk, text]) if wk > 0 else text,
			"accent": _news_colour(kind), "enabled": false,
		})
	_mount_browse("%s  -  CLUB NEWS" % _career.club_name, "Latest first", rows,
		func(_i: int) -> void: pass,
		func() -> void: _dismiss_career_browse())

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

## Row accent for a news item by kind: injury red, suspension orange, return green,
## result/other a neutral light.
func _news_colour(kind: String) -> Color:
	match kind:
		"injury": return Availability.C_INJURY
		"suspension": return Availability.C_SUSPENSION
		"return": return Availability.C_RETURN
		"develop": return Color(0.45, 0.82, 0.98)   # blue -- a player improved
		"decline": return Color(0.78, 0.62, 0.42)   # bronze -- a player slipped
		"cup": return Color(0.98, 0.86, 0.45)       # gold -- an F.A. Cup result
		"youth": return Color(0.55, 0.85, 0.55)     # green -- youth academy news
		"staff": return Color(0.70, 0.78, 0.95)     # steel -- backroom staff news
		"contract": return Color(0.95, 0.80, 0.55)  # amber -- contract / wage news
		_: return Color(0.86, 0.90, 0.96)

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
	rows.append("TEAM TACTICS   (attack / defence)"); payload.append({"a": "modal"})
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
		"modal": _show_tactics_screen()
		"takers": _push(_show_takers)
		"load": _push(_show_load_tactics)
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_career.advance_season(GameDB.leagues, rng, _euro_pool(), _sa_champion())
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

## The JOB OFFERS list (#14): the clubs that want you. Selecting one takes the job and
## starts your first season there. PM98-chrome browse.
func _show_job_offers() -> void:
	var offers: Array = _career.pending_offers
	var rows: Array = []
	var payload: Array = []
	if offers.is_empty():
		rows.append({"text": "No clubs have come in for you.", "enabled": false})
		payload.append(null)
	for o in offers:
		rows.append({"text": str(o["club_name"]), "value": str(o["league_name"])})
		payload.append(o)
	var subtitle := "Choose your next club" if _career.sacked else "A new challenge, if you want it"
	_mount_browse("JOB OFFERS", subtitle, rows,
		func(i: int) -> void:
			if i < payload.size() and payload[i] != null:
				_accept_job(payload[i]),
		func() -> void: _dismiss_career_browse())

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
	_career.take_job(club, league, league_clubs, GameDB.leagues, reason)
	_career.save()
	_enter_career()

## YOUR CAREER (#14): reputation + the current club + every past spell, most recent first.
## The MANAGER INFO the board screen points at, here as a PM98-chrome browse.
func _show_manager_career() -> void:
	var rows: Array = []
	rows.append({"text": "Reputation:  %d  -  %s" % [
		int(round(_career.reputation)), Manager.reputation_label(_career.reputation)],
		"accent": Color(1.0, 0.87, 0.0), "enabled": false})
	rows.append({"text": "%s  (%s)" % [_career.club_name, _career.league_name],
		"value": "now, season %d" % _career.seasons_at_club(),
		"accent": Color(0.55, 0.85, 1.0), "enabled": false})
	for i in range(_career.manager_history.size() - 1, -1, -1):
		var h: Dictionary = _career.manager_history[i]
		var span := str(h.get("from_season", "?"))
		if str(h.get("to_season", "")) != span:
			span = "%s to %s" % [span, str(h.get("to_season", ""))]
		rows.append({
			"text": "%s  (%s)" % [str(h.get("club_name", "?")), str(h.get("league_name", ""))],
			"value": "%s, %s" % [span, _spell_reason(h)],
			"accent": _spell_colour(h), "enabled": false})
	if _career.manager_history.is_empty():
		rows.append({"text": "Your first job  -  make your name here.", "enabled": false})
	var clubs_managed := _career.manager_history.size() + 1
	_mount_browse("YOUR CAREER", "%d club%s managed" % [
		clubs_managed, "" if clubs_managed == 1 else "s"], rows,
		func(_i: int) -> void: pass,
		func() -> void: _dismiss_career_browse())

## A short tag for how a spell ended ("sacked" / "resigned" / "left ...").
func _spell_reason(h: Dictionary) -> String:
	var r := str(h.get("reason", ""))
	if r == "sacked" or r == "relegated":
		return "%s, sacked" % str(h.get("final_pos_str", "?"))
	return "%s, %s" % [str(h.get("final_pos_str", "?")), r]

func _spell_colour(h: Dictionary) -> Color:
	var r := str(h.get("reason", ""))
	if r == "sacked" or r == "relegated":
		return Color(0.92, 0.40, 0.36)   # a sacking reads red
	return Color(0.80, 0.82, 0.88)

## Real-render of the manager-career flow (#14): take a weak club, miss the board's target,
## be sacked, render the JOB OFFERS list, take a job, render YOUR CAREER. PM98_MANAGER_SHOT.
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
