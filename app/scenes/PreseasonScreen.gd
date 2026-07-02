extends Control
class_name PreseasonScreen
## PM98 PRESEASON screen ("Preseason for <club>"), rebuilt from the ORIGINAL art at
## the rects reversed from MANAGER.EXE (~0x4c6400) and verified against walkthrough
## frames 013-016. See docs/re/pretemporada_screen_re.md.
##
## Europe map (recursos\iconos\ofertas\EUROPA.BMP) with the 47 country flags at the
## frame-measured marker positions (tools/re/specs/pretemp_flag_markers.json,
## identities matched against the game's own BANDERAS flag art). Tap a flag ->
## country name in the black strip + its clubs in the white kit panel; tap a kit ->
## fills the next RIVAL slot (4 preseason friendly dates: 1/4/6/8 August 1997).
## SKIP / CONTINUE proceed into the career; DELETE clears the last filled slot.
##
## Honest gaps (documented): foreign-club KIT art is not yet extracted, so only
## countries with kit art (England's 92 clubs) list clubs in the panel — a foreign
## country shows its name + an empty panel. The S. AMERICA tab shows the real
## SUDAMERICA map art but has no flag markers yet (no walkthrough frame of that tab
## exists to measure from). Friendly-match simulation lands with the match loop; the
## picked rivals are stored on the career save (preseason_rivals).

signal preseason_done(rivals: Array)

const W := 640
const H := 480

const R_TITLE := Rect2(150, 16, 350, 27)
const R_TAB_EU := Rect2(3, 78, 21, 112)
const R_TAB_SA := Rect2(3, 190, 21, 112)
const R_MAP := Rect2(27, 80, 300, 220)
const R_STRIP := Rect2(7, 304, 322, 22)
const R_PANEL := Rect2(8, 336, 321, 130)
const KIT_Y := [364, 412]                     # two kit rows inside the panel
const KIT_H := 44
const CAL_X := 325.0
const RIV_X := 377.0
const RIV_W := 228.0                           # slot body (badge at 605..629)
const ROW_Y := [78.0, 136.0, 194.0, 252.0]
const R_SKIP := Rect2(503, 333, 112, 25)
const R_PREMIER := Rect2(383, 370, 112, 25)
const R_FIRST := Rect2(503, 370, 112, 25)
const R_SECOND := Rect2(383, 403, 112, 25)
const R_THIRD := Rect2(503, 403, 112, 25)
const R_DELETE := Rect2(383, 440, 112, 25)
const R_CONTINUE := Rect2(503, 440, 112, 25)

const DATES := [{"d": 1}, {"d": 4}, {"d": 6}, {"d": 8}]   # 1/4/6/8 August 1997

const C_GOLD := Color(1.0, 0.875, 0.0)
const C_YELLOW := Color(1.0, 1.0, 0.0)
const C_RED := Color(1.0, 0.122, 0.0)
const C_PRESS := Color(1, 1, 1, 0.2)

var _bg: Texture2D
var _barra: Texture2D
var _map_eu: Texture2D
var _map_sa: Texture2D
var _hoja: Texture2D
var _borra: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _fcal: Font

var _club_name := ""
var _manager := ""
var _markers: Array = []          # {code,name,x,y} from the spec JSON
var _tab := 0                     # 0=EUROPE 1=S.AMERICA
var _country := "ENGLAND"         # selected country (PAISES English name)
var _country_clubs: Array = []    # clubs listed in the panel
var _div := 0                     # England division filter index
var _rivals: Array = []           # picked rival clubs (Dictionary), in slot order
var _press := ""
var _leagues: Array = []
var _clubs_of: Callable           # league_id -> clubs
var _clubs_of_country: Callable   # PAISES English name -> clubs (Main bridges es->en)


func _ready() -> void:
	_bg = load("res://art/screens/seleccion_bg.png")
	_barra = load("res://art/screens/barra0.png")
	_map_eu = load("res://art/screens/pretemp/europa.png")
	_map_sa = load("res://art/screens/pretemp/sudamerica.png")
	_hoja = load("res://art/screens/pretemp/hoja_calendario.png")
	_borra = load("res://art/icons/borra.png")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	_fcal = PMChrome.font("calend8")
	var f := FileAccess.open("res://data/pretemp_flag_markers.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_markers = parsed.get("markers", [])
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club_name: String, manager: String, leagues: Array, clubs_of: Callable,
		clubs_of_country: Callable) -> void:
	_club_name = club_name
	_manager = manager
	_leagues = leagues
	_clubs_of = clubs_of
	_clubs_of_country = clubs_of_country
	_select_england()
	queue_redraw()


func _select_england() -> void:
	_country = "ENGLAND"
	_country_clubs = []
	if _div < _leagues.size() and _clubs_of.is_valid():
		_country_clubs = _clubs_of.call(str(_leagues[_div].get("id", "")))
		_country_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


# ---- geometry --------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _kit_cols() -> int:
	return 10 if _country_clubs.size() <= 20 else int(ceil(_country_clubs.size() / 2.0))

func _kit_rect(i: int) -> Rect2:
	var cols := _kit_cols()
	var pitch := (R_PANEL.size.x - 20.0) / cols
	return Rect2(R_PANEL.position.x + 10 + (i % cols) * pitch, KIT_Y[i / cols], pitch, KIT_H)

func _flag_at(d: Vector2) -> Dictionary:
	if _tab != 0:
		return {}
	for m in _markers:
		if Rect2(float(m["x"]) - 1, float(m["y"]) - 1, 20, 15).has_point(d):
			return m
	return {}

func _target_at(d: Vector2) -> String:
	if R_SKIP.has_point(d): return "skip"
	if R_CONTINUE.has_point(d): return "continue"
	if R_DELETE.has_point(d) and not _rivals.is_empty(): return "delete"
	if R_TAB_EU.has_point(d): return "tab:0"
	if R_TAB_SA.has_point(d): return "tab:1"
	if _country == "ENGLAND":
		var divs := [R_PREMIER, R_FIRST, R_SECOND, R_THIRD]
		for i in divs.size():
			if i < _leagues.size() and divs[i].has_point(d):
				return "div:%d" % i
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		if _kit_rect(i).has_point(d):
			return "kit:%d" % i
	if not _flag_at(d).is_empty():
		var m := _flag_at(d)
		return "flag:%s" % str(m["name"])
	return ""


# ---- input -----------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _target_at(d):
		return
	match was:
		"skip", "continue":
			preseason_done.emit(_rivals.duplicate())
		"delete":
			_rivals.pop_back()
			queue_redraw()
		"tab:0":
			_tab = 0
			queue_redraw()
		"tab:1":
			_tab = 1
			_country = ""
			_country_clubs = []
			queue_redraw()
		_:
			if was.begins_with("div:"):
				_div = int(was.substr(4))
				_select_england()
				queue_redraw()
			elif was.begins_with("flag:"):
				var nm := was.substr(5)
				_country = nm
				if nm == "ENGLAND":
					_select_england()
				else:
					_country_clubs = _clubs_of_country.call(nm) if _clubs_of_country.is_valid() else []
					_country_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
				queue_redraw()
			elif was.begins_with("kit:"):
				var i := int(was.substr(4))
				if _rivals.size() < 4 and i < _country_clubs.size():
					_rivals.append(_country_clubs[i])
					queue_redraw()


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, cw := 0.0, center := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _chip(r: Rect2, key: String) -> void:
	draw_rect(r, Color8(8, 8, 14), true)
	PMChrome.bevel(self, r, Color8(8, 8, 14), Color(0.45, 0.45, 0.5), Color(0, 0, 0))
	if _press == key:
		draw_rect(r, C_PRESS, true)


func _button(r: Rect2, label: String, col: Color, enabled: bool, key: String, icon: Texture2D = null) -> void:
	_chip(r, key)
	var tx := r.position.x
	if icon != null:
		draw_texture_rect(icon, Rect2(r.position + Vector2(7, 3), icon.get_size()), false)
		tx += 28
	_txt(_f12, tx, r.position.y + 5, label, col if enabled else Color(col, 0.35), 13,
		r.size.x - (tx - r.position.x), true)


func _vtab(r: Rect2, label: String, key: String, active: bool) -> void:
	_chip(r, key)
	# vertical caption reading bottom-up (frame 013: red-orange EUROPE / S. AMERICA)
	var col := Color8(235, 120, 30) if active else Color(0.8, 0.82, 0.9)
	var s := _scale()
	var o := _origin(s)
	var wtxt := _f10.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var anchor := r.get_center() + Vector2(4.0, wtxt * 0.5)
	draw_set_transform(o + anchor * s, -PI / 2, Vector2(s, s))
	draw_string(_f10, Vector2.ZERO, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	draw_set_transform(o, 0.0, Vector2(s, s))


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _barra != null:
		draw_texture_rect(_barra, Rect2(0, 0, W, _barra.get_height()), false)
	_txt(_f14, R_TITLE.position.x, R_TITLE.position.y, "Preseason for %s" % _club_name,
		Color.WHITE, 15, R_TITLE.size.x, true)

	# map + tabs + flags
	draw_rect(R_MAP.grow(2), Color(0, 0, 0), true)
	var map := _map_eu if _tab == 0 else _map_sa
	if map != null:
		draw_texture_rect(map, R_MAP, false)
	_vtab(R_TAB_EU, "EUROPE", "tab:0", _tab == 0)
	_vtab(R_TAB_SA, "S. AMERICA", "tab:1", _tab == 1)
	if _tab == 0:
		for m in _markers:
			var fr := Rect2(float(m["x"]), float(m["y"]), 18, 13)
			draw_rect(fr.grow(1), Color(0, 0, 0), true)
			var tex := PMChrome.flag(int(m["code"]))
			if tex != null:
				draw_texture_rect(tex, fr, false)
			if _press == "flag:%s" % str(m["name"]):
				draw_rect(fr, C_PRESS, true)

	# country strip + kit panel
	draw_rect(R_STRIP, Color(0, 0, 0), true)
	draw_rect(R_STRIP, Color(1, 1, 1, 0.4), false)
	if _country != "":
		_txt(_f12, R_STRIP.position.x, R_STRIP.position.y + 3, _country, Color.WHITE, 14,
			R_STRIP.size.x, true)
	draw_rect(R_PANEL, Color(0.97, 0.97, 0.95), true)
	draw_rect(R_PANEL.grow(-4), Color8(190, 160, 60), false)
	if _country != "":
		_txt(_f12, R_PANEL.position.x, R_PANEL.position.y + 6, _country, Color8(40, 60, 190),
			13, R_PANEL.size.x, true)
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		var kr := _kit_rect(i)
		var tex2 := PMChrome.kit(int(_country_clubs[i].get("id", -1)))
		if tex2 != null:
			var kw := minf(kr.size.x - 4, 26.0)
			draw_texture_rect(tex2, Rect2(kr.get_center() - Vector2(kw * 0.5, (KIT_H - 6) * 0.5),
				Vector2(kw, KIT_H - 8)), false)
		if _press == "kit:%d" % i:
			draw_rect(kr, C_PRESS, true)

	# calendar sheets + rival slots
	for i in 4:
		var y: float = ROW_Y[i]
		if _hoja != null:
			draw_texture_rect(_hoja, Rect2(CAL_X, y + 1, 40, 47), false)
		_txt(_fcal if _fcal != null else _f12, CAL_X, y + 9, str(DATES[i]["d"]),
			Color8(200, 20, 20), 13, 40, true)
		_txt(_fcal if _fcal != null else _f10, CAL_X, y + 24, "August", Color8(30, 30, 40), 9, 40, true)
		_txt(_fcal if _fcal != null else _f10, CAL_X, y + 34, "1997", Color8(30, 30, 40), 9, 40, true)
		var active := i == _rivals.size()
		var filled := i < _rivals.size()
		var head := Color(1, 1, 1) if active or filled else Color(0.55, 0.58, 0.66, 0.85)
		draw_rect(Rect2(RIV_X, y, RIV_W, 15), head, true)
		_txt(_f10, RIV_X, y + 2, "RIVAL", Color8(70, 80, 120) if active or filled else Color8(90, 95, 110),
			11, RIV_W, true)
		for b in 2:
			var bar := Rect2(RIV_X, y + 17 + b * 16, RIV_W, 14)
			draw_rect(bar, Color8(190, 195, 225) if active or filled else Color8(120, 126, 150, 200), true)
		if filled:
			_txt(_f10, RIV_X + 8, y + 18, PMChrome.title_case_name(str(_rivals[i].get("name", ""))),
				Color8(20, 24, 60), 11)
		var badge := Rect2(RIV_X + RIV_W, y, 24, 49)
		draw_rect(badge, Color8(190, 30, 30) if active else Color8(150, 80, 70, 220), true)
		_txt(_f14, badge.position.x, y + 15, str(i + 1), Color(1, 1, 1, 1.0 if active else 0.75),
			16, badge.size.x, true)

	# right-hand buttons
	_button(R_SKIP, "SKIP", Color(0.92, 0.95, 1.0), true, "skip")
	if _country == "ENGLAND":
		var divs := [R_PREMIER, R_FIRST, R_SECOND, R_THIRD]
		var caps := ["PREMIER", "FIRST", "SECOND", "THIRD"]
		for i in divs.size():
			if i >= _leagues.size():
				break
			_button(divs[i], caps[i], C_YELLOW if i == _div else Color(0.9, 0.92, 0.98),
				true, "div:%d" % i)
	_button(R_DELETE, "DELETE", C_RED, not _rivals.is_empty(), "delete", _borra)
	_button(R_CONTINUE, "CONTINUE", C_YELLOW, true, "continue")
