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
		_on_item(0)            # first competition -> its clubs
		await _settle()
		_on_item(0)            # first club -> squad
		await _settle()
		_save_shot(dir, "squad.png")
		_on_item(0)            # first player -> attributes
		await _settle()
		_save_shot(dir, "player.png")
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
	for lg in GameDB.leagues:
		rows.append("%s  (%d clubs)" % [lg["name"], (lg["clubIds"] as Array).size()])
		payload.append({"type": "league", "league": lg})
	var intl := GameDB.countries()
	if not intl.is_empty():
		rows.append("International  (%d countries)" % intl.size())
		payload.append({"type": "intl"})
	_set_view("PM98", "Select a competition", rows, payload, _activate_home)

func _activate_home(item: Dictionary) -> void:
	if item["type"] == "league":
		_push(_show_league.bind(item["league"]))
	else:
		_push(_show_intl)

func _show_league(league: Dictionary) -> void:
	var cl := GameDB.clubs_in_league(league["id"])
	cl.sort_custom(func(a, b): return a["name"] < b["name"])
	var rows: Array = []
	for c in cl:
		rows.append("%-22s %2d" % [c["name"], (c.get("players", []) as Array).size()])
	_set_view(league["name"], "%d clubs" % cl.size(), rows, cl, _show_squad_from)

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
	var rows: Array = []
	for p in players:
		var ca: int = int((p.get("attrs", {}) as Dictionary).get("CA", 0))
		var pos := "GK" if p.get("isGK") else "  "
		var age: Variant = p.get("age")
		rows.append("%-16s %s  CA %2d  %s" % [
			p["name"], pos, ca, ("age " + str(age)) if age != null else ""])
	var stadium: Variant = club.get("stadium")
	var sub: String = stadium if stadium is String else ""
	if club.get("capacity") != null:
		sub = "%s  (%s)" % [sub, _fmt_int(int(club["capacity"]))]
	_set_view(club["name"], sub, rows, players, _show_player_from)

func _show_player_from(player: Dictionary) -> void:
	_push(_show_player.bind(player))

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
		sub = "%s  -  b.%s%s" % [legal, str(by),
			("  GK" if player.get("isGK") else "")]
	_set_view(player["name"], sub, rows, [], func(_x): pass)


# ---- helpers -------------------------------------------------------------

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
