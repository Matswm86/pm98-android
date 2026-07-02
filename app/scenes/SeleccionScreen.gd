extends Control
class_name SeleccionScreen
## PM98 NEW-CAREER screen (SELECCION, "ENTER YOUR NAME AND SELECT A TEAM"), rebuilt
## frame-true against walkthrough frames 008-012 (2026-07-02) at the rects reversed
## from MANAGER.EXE (FUN_0055d560). See docs/re/seleccion_screen_re.md.
##
## Real body (frames 008-012): PLAYER name bar with arrows top-centre, TWENTY numbered
## save slots in two columns of 10 (number badge + NAME + CLUB cells), a central white
## kit panel showing the selected division's TWENTY club kits (tap = pick club, name
## appears beneath), four division plaques flanking the panel, and the reversed
## RETURN / LOAD GAME / DELETE / CONTINUE bottom row.
##
## Original allows up to 20 hot-seat players; this engine holds ONE career save, so
## slot 1 is the live slot and the rest render as the empty chrome the frames show
## (honest gap, documented). CONTINUE with name+club locks the slot (frame 011);
## CONTINUE with the slot list non-empty and the active slot blank starts the game
## (frames 012 -> 013, the preseason screen).

signal career_begun(manager_name: String, league: Dictionary, club: Dictionary)
signal back_pressed
signal load_pressed
signal delete_pressed

const W := 640
const H := 480

# Reversed rects (capstone) — title/buttons; the body is frame-measured (008-012).
const R_TITLE := Rect2(108, 12, 480, 27)
const R_RETURN := Rect2(25, 427, 112, 25)
const R_LOAD := Rect2(175, 427, 152, 25)
const R_DELETE := Rect2(348, 427, 112, 25)
const R_CONTINUE := Rect2(508, 427, 112, 25)

# PLAYER bar (frame 008)
const R_ARROW_L := Rect2(83, 66, 28, 28)
const R_ARROW_R := Rect2(502, 66, 28, 28)
const R_PLAYER := Rect2(118, 64, 380, 31)     # the full dark bar
const R_PLAYER_CHIP := Rect2(127, 67, 118, 25)
const R_SLOTNO := Rect2(247, 67, 44, 25)
const R_NAME := Rect2(293, 67, 202, 25)       # LineEdit mounts here

# Save-slot grid (frame 008): 2 cols x 10 rows, pitch 16, bar 12
const SLOT_Y0 := 107
const SLOT_PITCH := 16
const SLOT_H := 13
const COL_X := [20, 332]                       # badge left edge per column
const BADGE_W := 24
const NAME_W := 104                            # badge_end..149
const CLUB_W := 158                            # 150..308

# Kit panel + plaques (frames 008/010)
const R_PANEL := Rect2(150, 276, 340, 130)
const KIT_Y := [297, 342]                      # two kit rows (y top)
const KIT_H := 40
const R_PLAQ := [Rect2(13, 291, 124, 20), Rect2(13, 329, 124, 20),
	Rect2(503, 291, 124, 20), Rect2(503, 329, 124, 20)]

const C_GOLD := Color(1.0, 0.875, 0.0)
const C_YELLOW := Color(1.0, 1.0, 0.0)
const C_RED := Color(1.0, 0.122, 0.0)
const C_LOADTXT := Color8(123, 223, 82)
const C_SLOT_BAR := Color8(150, 155, 200)      # empty slot bar (frame 008 lavender)
const C_SLOT_SEL := Color8(230, 190, 40)       # active slot gold
const C_PRESS := Color(1, 1, 1, 0.20)

var _bg: Texture2D
var _barra: Texture2D
var _carga: Texture2D
var _borra: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _name_edit: LineEdit

var _leagues: Array = []
var _li := 0                    # selected division (plaque index)
var _clubs: Array = []          # clubs of the selected division, sorted
var _sel := -1                  # selected club index in _clubs
var _slots: Array = []          # 20 x {name:String, club:Dictionary, league:Dictionary}
var _active := 0                # active save slot (0-based; PLAYER N = _active+1)
var _has_save := false
var _press := ""
var _clubs_of: Callable


func _ready() -> void:
	_bg = load("res://art/screens/seleccion_bg.png")
	_barra = load("res://art/screens/barra0.png")
	_carga = load("res://art/icons/carga.png")
	_borra = load("res://art/icons/borra.png")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for i in 20:
		_slots.append({})
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = ""
	_name_edit.max_length = 16
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_edit.add_theme_font_override("font", _f12)
	_name_edit.add_theme_font_size_override("font_size", 13)
	_name_edit.add_theme_color_override("font_color", Color.WHITE)
	# the original name field is the black strip of the PLAYER bar
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	for st in ["normal", "focus", "read_only"]:
		_name_edit.add_theme_stylebox_override(st, sb)
	add_child(_name_edit)
	resized.connect(_reposition_name)
	gui_input.connect(_on_input)
	_reposition_name()
	queue_redraw()


## leagues + clubs_of resolver + whether a save exists (LOAD/DELETE state).
func setup(leagues: Array, has_save: bool, clubs_of: Callable) -> void:
	_leagues = leagues
	_has_save = has_save
	_clubs_of = clubs_of
	_li = 0
	_sel = -1
	_load_clubs()
	queue_redraw()


func _load_clubs() -> void:
	_clubs = []
	if _li >= 0 and _li < _leagues.size() and _clubs_of.is_valid():
		_clubs = _clubs_of.call(str(_leagues[_li].get("id", "")))
		_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


# ---- geometry --------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _reposition_name() -> void:
	if _name_edit == null:
		return
	var s := _scale()
	_name_edit.position = _origin(s) + R_NAME.position * s
	_name_edit.size = R_NAME.size * s

func _kit_cols() -> int:
	return 10 if _clubs.size() <= 20 else int(ceil(_clubs.size() / 2.0))

func _kit_rect(i: int) -> Rect2:
	var cols := _kit_cols()
	var pitch := (R_PANEL.size.x - 24.0) / cols
	var col := i % cols
	var row := i / cols
	return Rect2(R_PANEL.position.x + 12 + col * pitch, KIT_Y[row], pitch, KIT_H)

func _kit_at(d: Vector2) -> int:
	for i in _clubs.size():
		if i >= _kit_cols() * 2:
			break
		if _kit_rect(i).has_point(d):
			return i
	return -1

func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d): return "return"
	if _has_save and R_LOAD.has_point(d): return "load"
	if _has_save and R_DELETE.has_point(d): return "delete"
	if R_CONTINUE.has_point(d): return "continue"
	if R_ARROW_L.has_point(d): return "prev"
	if R_ARROW_R.has_point(d): return "next"
	for i in R_PLAQ.size():
		if i < _leagues.size() and R_PLAQ[i].has_point(d):
			return "league:%d" % i
	var k := _kit_at(d)
	if k >= 0: return "kit:%d" % k
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
		"return":
			back_pressed.emit()
		"load":
			load_pressed.emit()
		"delete":
			_has_save = false
			delete_pressed.emit()
			queue_redraw()
		"prev":
			_active = (_active + 19) % 20
			queue_redraw()
		"next":
			_active = (_active + 1) % 20
			queue_redraw()
		"continue":
			_continue()
		_:
			if was.begins_with("league:"):
				_li = int(was.substr(7))
				_sel = -1
				_load_clubs()
				queue_redraw()
			elif was.begins_with("kit:"):
				_sel = int(was.substr(4))
				queue_redraw()


## Original CONTINUE semantics (frames 010->011->012): with a name+club it locks the
## active slot and advances to the next PLAYER; with the active slot blank and at
## least one filled slot it starts the game (player 1's career).
func _continue() -> void:
	var nm := _name_edit.text.strip_edges()
	if _sel >= 0 and _sel < _clubs.size() and nm != "":
		_slots[_active] = {"name": nm, "club": _clubs[_sel], "league": _leagues[_li]}
		_active = mini(_active + 1, 19)
		_sel = -1
		_name_edit.text = ""
		queue_redraw()
		return
	for s2 in _slots:
		if not s2.is_empty():
			career_begun.emit(str(s2["name"]), s2["league"], s2["club"])
			return


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


func _arrow(r: Rect2, left: bool, key: String) -> void:
	_chip(r, key)
	var c := r.get_center()
	var s := 7.0
	var pts := PackedVector2Array([c + Vector2(-s if left else s, 0),
		c + Vector2(s if left else -s, -s), c + Vector2(s if left else -s, s)])
	draw_colored_polygon(pts, C_GOLD)


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _barra != null:
		draw_texture_rect(_barra, Rect2(0, 0, W, _barra.get_height()), false)
	_txt(_f14, R_TITLE.position.x, R_TITLE.position.y, "ENTER YOUR NAME AND SELECT A TEAM",
		Color.WHITE, 15, R_TITLE.size.x, true)

	# PLAYER bar + arrows
	draw_rect(R_PLAYER, Color(0, 0, 0), true)
	draw_rect(R_PLAYER_CHIP, Color8(200, 110, 20), true)
	PMChrome.bevel(self, R_PLAYER_CHIP, Color8(200, 110, 20), Color8(245, 170, 70), Color8(90, 45, 5))
	_txt(_f12, R_PLAYER_CHIP.position.x, R_PLAYER_CHIP.position.y + 4, "PLAYER", C_GOLD,
		14, R_PLAYER_CHIP.size.x, true)
	draw_rect(R_SLOTNO, Color8(70, 10, 10), true)
	_txt(_f12, R_SLOTNO.position.x, R_SLOTNO.position.y + 4, str(_active + 1), C_GOLD,
		14, R_SLOTNO.size.x, true)
	_arrow(R_ARROW_L, false, "prev")   # frame 008: left chip points right, right chip left
	_arrow(R_ARROW_R, true, "next")

	# 20 numbered save slots (2 cols x 10)
	for i in 20:
		var col := i / 10
		var row := i % 10
		var x: int = COL_X[col]
		var y := SLOT_Y0 + row * SLOT_PITCH
		var active := i == _active
		var badge_c := Color8(170, 30, 30) if active else Color8(60, 60, 80)
		draw_rect(Rect2(x, y, BADGE_W, SLOT_H), badge_c, true)
		_txt(_f10, x, y, str(i + 1), Color.WHITE, 11, BADGE_W, true)
		var bar_c := C_SLOT_SEL if active else C_SLOT_BAR
		draw_rect(Rect2(x + BADGE_W + 1, y, NAME_W, SLOT_H), bar_c, true)
		draw_rect(Rect2(x + BADGE_W + NAME_W + 2, y, CLUB_W, SLOT_H), bar_c, true)
		if active:
			draw_rect(Rect2(x, y, BADGE_W + NAME_W + CLUB_W + 2, SLOT_H), Color.WHITE, false)
		var slot: Dictionary = _slots[i]
		if not slot.is_empty():
			var dark := Color8(20, 24, 60)
			_txt(_f10, x + BADGE_W + 6, y + 1, str(slot["name"]).to_upper(), dark, 11)
			_txt(_f10, x + BADGE_W + NAME_W + 8, y + 1,
				PMChrome.title_case_name(str(slot["club"].get("name", ""))), dark, 11)

	# central kit panel
	draw_rect(R_PANEL, Color(0.97, 0.97, 0.95), true)
	draw_rect(R_PANEL.grow(-6), Color8(190, 160, 60), false)
	var lname := str(_leagues[_li].get("name", "")) if _li < _leagues.size() else ""
	_txt(_f12, R_PANEL.position.x, R_PANEL.position.y + 8, lname, Color8(190, 150, 30),
		14, R_PANEL.size.x, true)
	for i in _clubs.size():
		if i >= _kit_cols() * 2:
			break
		var kr := _kit_rect(i)
		var tex := PMChrome.kit(int(_clubs[i].get("id", -1)))
		if tex != null:
			var kw := minf(kr.size.x - 4, 30.0)
			var dst := Rect2(kr.get_center() - Vector2(kw * 0.5, KIT_H * 0.5 - 2),
				Vector2(kw, KIT_H - 6))
			draw_texture_rect(tex, dst, false)
		if i == _sel:
			draw_rect(Rect2(kr.position, Vector2(kr.size.x - 2, kr.size.y)), C_SLOT_SEL, false)
		elif _press == "kit:%d" % i:
			draw_rect(kr, C_PRESS, true)
	if _sel >= 0 and _sel < _clubs.size():
		_txt(_f12, R_PANEL.position.x, R_PANEL.end.y - 22,
			PMChrome.title_case_name(str(_clubs[_sel].get("name", ""))),
			Color8(60, 80, 190), 13, R_PANEL.size.x, true)

	# division plaques (selected = red text, as frame 008)
	for i in R_PLAQ.size():
		if i >= _leagues.size():
			break
		var pr: Rect2 = R_PLAQ[i]
		_chip(pr, "league:%d" % i)
		var nm2 := str(_leagues[i].get("name", ""))
		_txt(_f10, pr.position.x, pr.position.y + 4, nm2,
			C_RED if i == _li else Color(0.88, 0.90, 0.96), 11, pr.size.x, true)

	# bottom buttons (reversed rects)
	_button(R_RETURN, "RETURN", C_YELLOW, true, "return", null)
	_button(R_LOAD, "LOAD GAME", C_LOADTXT, _has_save, "load", _carga)
	_button(R_DELETE, "DELETE", C_RED, _has_save, "delete", _borra)
	_button(R_CONTINUE, "CONTINUE", C_YELLOW, true, "continue", null)


func _button(r: Rect2, label: String, col: Color, enabled: bool, key: String, icon: Texture2D) -> void:
	_chip(r, key)
	var tx := r.position.x
	if icon != null:
		draw_texture_rect(icon, Rect2(r.position + Vector2(7, 3), icon.get_size()), false)
		tx += 30
	_txt(_f12, tx, r.position.y + 5, label, col if enabled else Color(col, 0.35), 13,
		r.size.x - (tx - r.position.x), true)
