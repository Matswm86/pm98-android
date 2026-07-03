extends Control
class_name SeleccionScreen
## PM98 NEW-CAREER screen (SELECCION, "ENTER YOUR NAME AND SELECT A TEAM"). The
## static chrome is the REAL game's fresh frame (walkthrough 008, caret erased):
## barra + title + PLAYER bar with the PUN10/PUN20 arrow chips + 20 empty save
## slots (slot 1 active) + Premier kit panel + division plaques + bottom row —
## all original pixels. See docs/re/seleccion_screen_re.md and
## tools/re/build_entry_chrome_from_frames.py.
##
## The dynamic layer redraws ONLY what differs from that resting state: slot rows
## whose state changed (lock/advance/delete — frame 011 truth: filled = black
## badge/white digit/gold bars/navy text; active = red badge/gold digit/gold bars/
## white outline), the PLAYER number when it moves off 1, the kit panel + plaques
## when the division or pick changes (selection = the original OVER.BMP gold cell,
## frame 010), pressed arrows (PUN11/21), and the solid CONTINUE (frame 012) once
## a slot is filled — PM98 renders disabled buttons WASHED toward the backdrop.
##
## Original allows 20 hot-seat players; this engine holds ONE career save, so slot
## 1 is the live slot and the rest render as the empty chrome (honest gap).
## CONTINUE with name+club locks the slot (frame 011); CONTINUE with the active
## slot blank and at least one filled slot starts the game (frames 012 -> 013).

signal career_begun(manager_name: String, league: Dictionary, club: Dictionary)
signal back_pressed
signal load_pressed
signal delete_pressed

const W := 640
const H := 480

# Reversed rects (capstone) — bottom row + title; body geometry frame-measured (008).
const R_TITLE := Rect2(108, 12, 480, 27)
const R_RETURN := Rect2(25, 427, 112, 25)
const R_LOAD := Rect2(175, 427, 152, 25)
const R_DELETE := Rect2(348, 427, 112, 25)
const R_CONTINUE := Rect2(508, 427, 112, 25)

# PLAYER bar (frame 008): PUN arrow chips SAD-0.0 at (79,65)/(501,65) 34x29;
# number cell frame x 251..292, name field x 293..489.
const R_ARROW_L := Rect2(79, 65, 34, 29)
const R_ARROW_R := Rect2(501, 65, 34, 29)
const R_SLOTNO := Rect2(251, 67, 42, 25)
const R_NAME := Rect2(293, 67, 197, 25)       # LineEdit mounts here

# Save-slot grid (frame-scanned): row-1 fill y 107..118, pitch 16; badge fill
# x 23..43, name bar 45..148, club bar 150..307 (+312 for the right column).
const SLOT_Y0 := 107
const SLOT_PITCH := 16
const COL_DX := 312
const COL_X := [20, 332]                       # band left edge per column

# Kit panel, SAD-0.0-anchored vs frame 008: black border (150,276)-(490,406), gold
# rect x 158..480 / y 291..383. NANOESC kits (24x32) blit 1:1 at x 167+31i,
# y 308/345; the OVER.BMP selection cell (26x36) sits at kit pos +(-1,-2). Ball
# sprite at (237,272); title text x270, glyphs y 286..295, on the y291 line.
const R_PANEL := Rect2(150, 276, 340, 130)
const KIT_X0 := 167
const KIT_PITCH := 31
const KIT_Y := [308, 345]
const KIT_W := 24
const KIT_H := 32
const GOLD_RECT := Rect2(158, 291, 323, 93)    # x 158..480 (w=323), y 291..383 (h=93)
const BALL_POS := Vector2(237, 272)
const TITLE_X := 270.0
const LINE_Y := 291
const R_PLAQ := [Rect2(13, 291, 124, 20), Rect2(13, 329, 124, 20),
	Rect2(503, 291, 124, 20), Rect2(503, 329, 124, 20)]

# Frame-sampled colours (tools/re/specs/entry_chrome_samples.json + frame 011)
const C_GOLD_BAR := Color8(212, 191, 0)        # active club bar
const C_GOLD_NAME := Color8(212, 159, 0)       # active name bar
const C_LAV_BAR := Color8(160, 160, 200)       # empty club bar
const C_NAME_BAR := Color8(140, 160, 180)      # empty name bar
const C_BADGE := Color8(128, 128, 128)
const C_BADGE_DIGIT := Color8(192, 192, 192)
const C_BADGE_ACT := Color8(85, 0, 0)
const C_BADGE_ACT_DIGIT := Color8(255, 223, 0)
# filled slot (frame 011): black badge/white digit, dark-slate name bar with pale
# lavender text, grey-lavender club bar with pale-blue text — both CENTRED
const C_FILL_NAME_BAR := Color8(40, 60, 80)
const C_FILL_CLUB_BAR := Color8(100, 100, 140)
const C_FILL_NAME_TXT := Color8(200, 200, 240)
const C_FILL_CLUB_TXT := Color8(170, 191, 255)
const C_RULE := Color8(212, 191, 85)           # panel gold frame/rule
const C_PANEL_TITLE := Color8(212, 191, 85)
const C_PLAQ_SEL := Color8(255, 255, 0)
const C_PLAQ_UNSEL := Color8(192, 192, 192)
const C_PRESS := Color(1, 1, 1, 0.20)

var _chrome: Texture2D
var _pun: Dictionary = {}      # "11"/"21" pressed arrow art
var _row1_degap: Texture2D     # frame-011 rows 104..121: slot 1 minus its outline
var _player_cell: Texture2D
var _panel_ball: Texture2D
var _kit_over: Texture2D
var _plaque_sel: Texture2D
var _plaque_unsel: Texture2D
var _continue_on: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font
var _checker: Texture2D    # 2x2 white/transparent — the taken-club kit wash (frame 011)
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
	_chrome = load("res://art/screens/seleccion/chrome.png")
	_pun["11"] = load("res://art/screens/seleccion/pun11.png")
	_pun["21"] = load("res://art/screens/seleccion/pun21.png")
	_row1_degap = load("res://art/screens/seleccion/row1_degap.png")
	_player_cell = load("res://art/screens/seleccion/player_cell.png")
	_panel_ball = load("res://art/screens/seleccion/panel_ball.png")
	_kit_over = load("res://art/screens/seleccion/kit_over.png")
	_plaque_sel = load("res://art/screens/seleccion/plaque_sel.png")
	_plaque_unsel = load("res://art/screens/seleccion/plaque_unsel.png")
	_continue_on = load("res://art/screens/seleccion/continue_on.png")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	_f8 = PMChrome.font("8")
	var ci := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	ci.set_pixel(0, 0, Color.WHITE)
	ci.set_pixel(1, 1, Color.WHITE)
	_checker = ImageTexture.create_from_image(ci)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for i in 20:
		_slots.append({})
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = ""
	_name_edit.max_length = 16
	# frame 010: the typed name renders centred in the black field
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
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

## The selection/tap cell (the OVER.BMP footprint, 26x36 at kit pos +(-1,-2)).
func _kit_rect(i: int) -> Rect2:
	var cols := _kit_cols()
	var pitch: float = KIT_PITCH if cols == 10 else (R_PANEL.size.x - 30.0) / cols
	var col := i % cols
	var row := i / cols
	return Rect2(KIT_X0 - 1 + col * pitch, KIT_Y[row] - 2, 26, 36)

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


func _any_filled() -> bool:
	for s2 in _slots:
		if not s2.is_empty():
			return true
	return false


func _taken_ids() -> Dictionary:
	var out := {}
	for s2 in _slots:
		if not (s2 as Dictionary).is_empty():
			out[int((s2["club"] as Dictionary).get("id", -1))] = true
	return out


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, cw := 0.0, center := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## Ceil-centred variant for single digits (frame-verified: the original's digit
## centring rounds right of centre).
func _txt_fc(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, cw: float) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var nudge := 1.0 if s == "1" else 0.0  # frame 011: '1' sits one px right of our centre
	draw_string(f, Vector2(x + ceilf((cw - w) * 0.5) + nudge, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)

	# pressed PLAYER-bar arrows -> the *1 art over the baked *0 chips
	if _press == "prev" and _pun["11"] != null:
		draw_texture_rect(_pun["11"], R_ARROW_L, false)
	if _press == "next" and _pun["21"] != null:
		draw_texture_rect(_pun["21"], R_ARROW_R, false)

	# PLAYER number: baked '1'; redraw only when the active slot moved (frame 011:
	# large blocky bright-gold digit with a dark-brown outline, centred in the cell)
	if _active != 0 and _player_cell != null:
		draw_texture_rect(_player_cell, Rect2(251, 67, 42, 25), false)
		for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
				Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_txt_fc(_f14, 253 + off.x, 72 + off.y, str(_active + 1), Color8(72, 30, 2), 15, 38)
		_txt_fc(_f14, 253, 72, str(_active + 1), Color8(255, 223, 0), 15, 38)

	# slot rows: redraw only rows whose state differs from the baked resting frame
	# (slot 1 active-empty, the rest empty-inactive)
	for i in 20:
		var filled: bool = not (_slots[i] as Dictionary).is_empty()
		var active := i == _active
		var resting := (i == 0 and active and not filled) or (i != 0 and not active and not filled)
		if not resting:
			_draw_slot(i, filled, active)

	# kit panel + plaques: baked while the resting Premier view is showing; any
	# taken club also forces a repaint (its kit renders WASHED, frame 011)
	if _li != 0 or _sel >= 0 or not _taken_ids().is_empty():
		_draw_panel()
	elif _press.begins_with("kit:"):
		draw_rect(_kit_rect(int(_press.substr(4))), C_PRESS, true)
	if _li != 0:
		_draw_plaques()

	# bottom row: baked; CONTINUE turns solid (frame 012) once a slot is filled
	# (the cut is grown +2px — the chip's bevel shadow extends past the widget rect)
	if _any_filled() and _continue_on != null:
		draw_texture_rect(_continue_on, Rect2(506, 425, 117, 30), false)
	for key_r in [["return", R_RETURN], ["load", R_LOAD], ["delete", R_DELETE],
			["continue", R_CONTINUE], ["league:0", R_PLAQ[0]], ["league:1", R_PLAQ[1]],
			["league:2", R_PLAQ[2]], ["league:3", R_PLAQ[3]]]:
		if _press == str(key_r[0]):
			draw_rect(key_r[1], C_PRESS, true)


## One slot row in a non-resting state. Geometry/colours frame-scanned (008/011):
## the black frames stay baked; only fills/digits/texts/outline are drawn. Digits +
## row texts use the tiny 7px raster ("8" font); filled texts are CENTRED, pale
## lavender/blue on dark bars. When slot 1 loses its baked active outline, the
## true background rows come from the frame-011 degap strip.
func _draw_slot(i: int, filled: bool, active: bool) -> void:
	var col := i / 10
	var row := i % 10
	var x: int = COL_X[col]
	var y := SLOT_Y0 + row * SLOT_PITCH
	if i == 0 and not active and _row1_degap != null:
		draw_texture(_row1_degap, Vector2(14, 104))
	var bx := x + 3        # badge fill x (23 at col 0)
	if active:
		draw_rect(Rect2(bx, y, 21, 12), C_BADGE_ACT, true)
		draw_rect(Rect2(x + 25, y, 104, 12), C_GOLD_NAME, true)
		draw_rect(Rect2(x + 130, y, 158, 12), C_GOLD_BAR, true)
	elif filled:
		draw_rect(Rect2(bx, y, 21, 12), Color(0, 0, 0), true)
		draw_rect(Rect2(x + 25, y, 104, 12), C_FILL_NAME_BAR, true)
		draw_rect(Rect2(x + 130, y, 158, 12), C_FILL_CLUB_BAR, true)
	else:
		draw_rect(Rect2(bx, y, 21, 12), C_BADGE, true)
		draw_rect(Rect2(x + 25, y, 104, 12), C_NAME_BAR, true)
		draw_rect(Rect2(x + 130, y, 158, 12), C_LAV_BAR, true)
	var dcol := C_BADGE_ACT_DIGIT if active else (Color.WHITE if filled else C_BADGE_DIGIT)
	_txt_fc(_f8, bx, y + 1, str(i + 1), dcol, 11, 21)
	if filled:
		var slot: Dictionary = _slots[i]
		_txt(_f8, x + 25, y + 1, str(slot["name"]).to_upper(), C_FILL_NAME_TXT, 11, 104, true)
		_txt(_f8, x + 130, y + 1, PMChrome.title_case_name(str(slot["club"].get("name", ""))),
			C_FILL_CLUB_TXT, 11, 158, true)
	if active:
		# white 2px outline INSIDE the bg gaps around the black frame (frame 011,
		# row 2: white rows y-3..y-2 and y+13..y+14, side cols x-3..x-2 / +2)
		draw_rect(Rect2(x, y - 3, 291, 2), Color.WHITE, true)
		draw_rect(Rect2(x, y + 13, 291, 2), Color.WHITE, true)
		draw_rect(Rect2(x, y - 1, 2, 14), Color.WHITE, true)
		draw_rect(Rect2(x + 289, y - 1, 2, 14), Color.WHITE, true)


## Full kit-panel repaint (division switched, kit picked, or a club taken): white
## interior, the gold frame rect, ball + division title interrupting the top line
## (frame 008 layout: line to x231, ball at 237, title from 270, line resumes 437),
## the division's NANOESC kits 1:1, OVER.BMP behind the picked one, its name under
## the bottom line in gold (frame 010). Taken clubs' kits render dither-washed
## toward the panel white (frame 011).
func _draw_panel() -> void:
	# interior white (the 2px black outer border rows 276..277 / 404..405 stay baked)
	draw_rect(Rect2(152, 278, 336, 126), Color.WHITE, true)
	# gold frame as 1px filled strips (pixel-snapped; x 158..480, y 291..383)
	draw_rect(Rect2(158, 291, 323, 1), C_RULE, true)
	draw_rect(Rect2(158, 383, 323, 1), C_RULE, true)
	draw_rect(Rect2(158, 291, 1, 93), C_RULE, true)
	draw_rect(Rect2(480, 291, 1, 93), C_RULE, true)
	var lname := PMChrome.title_case_name(str(_leagues[_li].get("name", ""))) if _li < _leagues.size() else ""
	# the top line's two segments are FIXED: x 158..231 and 406..480 (frame 008;
	# the white break under ball+title is static, not measured off the text)
	draw_rect(Rect2(232, LINE_Y, 174, 1), Color.WHITE, true)
	if _panel_ball != null:
		draw_texture(_panel_ball, BALL_POS)
	_txt(_f12, TITLE_X, 285, lname, C_PANEL_TITLE, 13)
	var taken := _taken_ids()
	for i in _clubs.size():
		if i >= _kit_cols() * 2:
			break
		var kr := _kit_rect(i)
		var cid := int(_clubs[i].get("id", -1))
		var selected := i == _sel
		if selected and _kit_over != null:
			draw_texture_rect(_kit_over, kr, false)
		elif _press == "kit:%d" % i:
			draw_rect(kr, C_PRESS, true)
		# frame-rendered patch (authentic shadow-on-white) when available; the
		# transparent nano art on the gold OVER cell (a white-baked shadow would
		# fringe) and for divisions without a frame render yet. Taken clubs use
		# the frame-proven WASHED render where one exists (Man Utd), else
		# nano + checker approximation.
		var washed: bool = taken.has(cid)
		if washed:
			var wp := PMChrome.panel_kit(cid, "washed")
			if wp != null:
				draw_texture(wp, kr.position + Vector2(1, 2))
			else:
				var nt := PMChrome.nano_kit(cid)
				if nt != null:
					draw_texture(nt, kr.position + Vector2(1, 2))
				if _checker != null:
					draw_texture_rect(_checker, kr, true)
		else:
			var patch := PMChrome.panel_kit(cid)
			if patch != null and not selected:
				draw_texture(patch, kr.position + Vector2(1, 2))
			else:
				var tex := PMChrome.nano_kit(cid)
				if tex != null:
					draw_texture(tex, kr.position + Vector2(1, 2))
	if _sel >= 0 and _sel < _clubs.size():
		_txt(_f12, R_PANEL.position.x, 388, PMChrome.title_case_name(str(_clubs[_sel].get("name", ""))),
			C_PANEL_TITLE, 13, R_PANEL.size.x, true)


## Plaque repaint (division switched): state interior textures cut from the frame
## + the label with the PROMAN raster (sel = yellow on red glow, frame 008).
func _draw_plaques() -> void:
	for i in R_PLAQ.size():
		if i >= _leagues.size():
			break
		var pr: Rect2 = R_PLAQ[i]
		var tex := _plaque_sel if i == _li else _plaque_unsel
		if tex != null:
			draw_texture_rect(tex, Rect2(pr.position + Vector2(3, 1), Vector2(122, 21)), false)
		_txt(_f10, pr.position.x, pr.position.y + 5,
			PMChrome.title_case_name(str(_leagues[i].get("name", ""))),
			C_PLAQ_SEL if i == _li else C_PLAQ_UNSEL, 10, pr.size.x, true)
