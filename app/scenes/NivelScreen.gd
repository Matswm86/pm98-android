extends Control
class_name NivelScreen
## PM98 "SELECT LEVEL OF THE GAME" dialog (NIVELES), rebuilt from the ORIGINAL art at
## the coordinates reversed out of MANAGER.EXE (creation fn ~0x54a580, paint 0x54ac80)
## and verified against walkthrough frames 003/004/007. See docs/re/nivel_screen_re.md.
##
## Mounted as an overlay ABOVE the title screen (the original draws it over FONDO7 with
## a short zoom-in; frame 002 caught the dialog mid-zoom at ~0.8 scale). Tapping a
## level panel picks that game level; LOAD GAME opens the 8-row load modal (frames
## 005/006); CANCEL returns to the title.
##
## Native 640x480 design space; scales to fit (NEAREST).

signal level_chosen(level: String, players_age: bool)
signal load_game(slot: int)
signal cancel_pressed

const W := 640
const H := 480

# Dialog container: POS (93,32) SIZE 453x415 (id 1034). fondo.bmp = 453x383 at client
# (0,0); the strip below (client y 383..415) is painted, buttons sit on it.
const DLG := Rect2(93, 32, 453, 415)
const ART_H := 383

# Client rects (reversed; screen = client + DLG.position)
const R_ENT := Rect2(30, 55, 120, 105)      # TRAINER art  (Entrenador0/1)
const R_MAN := Rect2(279, 56, 149, 104)     # MANAGER art
const R_PRE := Rect2(28, 209, 132, 124)     # ACCOUNTANT art (Presidente0/1)
const R_TOT := Rect2(272, 206, 153, 128)    # TOTAL art
const R_CHK := Rect2(14, 364, 14, 14)       # "Players age ?" checkbox (ok.bmp tick)
const R_LOAD := Rect2(6, 385, 132, 25)      # LOAD GAME (+carga icon)
const R_CANCEL := Rect2(143, 385, 103, 25)
# Band caption rows measured off frame 003 (client y 32..53 / 184..205; split ~199/207)
const BAND1_Y := 32
const BAND2_Y := 184
const BAND_H := 21
const BAND_L := Rect2(2, 0, 197, 21)        # x-extent of the left band (y from BANDn_Y)
const BAND_R := Rect2(207, 0, 244, 21)

const C_NAVY := Color8(0, 0, 50)            # dialog interior base (frame sample)
const C_LOADTXT := Color8(123, 223, 82)     # LOAD GAME text (COLOR call 0x54a63e)
const C_CANCELTXT := Color8(255, 31, 0)     # CANCEL/DELETE red (family constant)
const ZOOM_TIME := 0.15                     # frame 002 = mid-zoom at ~0.8 scale

const LEVELS := [
	{"key": "trainer", "cap": "TRAINER", "rect": R_ENT, "art": "entrenador"},
	{"key": "manager", "cap": "MANAGER", "rect": R_MAN, "art": "manager"},
	{"key": "accountant", "cap": "ACCOUNTANT", "rect": R_PRE, "art": "presidente"},
	{"key": "total", "cap": "TOTAL", "rect": R_TOT, "art": "total"},
]
# Per-level bullet captions (strings verbatim from MANAGER.EXE .rdata)
const BULLETS := {
	"trainer": ["- Automatic finances", "- Automatic contract renewal"],
	"manager": ["- Automatic contract renewal"],
	"accountant": ["- Automatic tactics and squad"],
	"total": ["- Total control"],
}

var _fondo: Texture2D
var _ok: Texture2D
var _carga: Texture2D
var _art: Dictionary = {}      # "entrenador0" -> Texture2D …
var _f10: Font
var _f12: Font
var _f8: Font

var _players_age := false
var _press := ""               # held target key
var _zoom := 0.8               # opening zoom (0.8 -> 1.0, centre-anchored)
var _has_save := false
var _save_summary: Dictionary = {}   # {name, club} of the existing save (row 1 of modal)
var _modal := false            # LOAD GAME modal (frames 005/006) open

func _ready() -> void:
	_fondo = load("res://art/screens/nivel/fondo.png")
	_ok = load("res://art/screens/nivel/ok.png")
	_carga = load("res://art/icons/carga.png")
	for lv in LEVELS:
		for st in 2:
			var key: String = "%s%d" % [lv["art"], st]
			_art[key] = load("res://art/screens/nivel/%s.png" % key)
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	var tw := create_tween()
	tw.tween_method(_set_zoom, 0.8, 1.0, ZOOM_TIME)


func _set_zoom(v: float) -> void:
	_zoom = v
	queue_redraw()


## has_save + a one-line summary ({name, club}) for the load modal's first row.
func setup(has_save: bool, save_summary: Dictionary = {}) -> void:
	_has_save = has_save
	_save_summary = save_summary
	queue_redraw()


# ---- geometry --------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _abs(r: Rect2) -> Rect2:
	return Rect2(r.position + DLG.position, r.size)

# LOAD GAME modal rects (measured off frame 005; abs 640x480 space)
const M_DLG := Rect2(143, 97, 354, 278)
const M_TITLE := Rect2(143, 100, 354, 21)
const M_HDR_Y := 128
const M_ROW0_Y := 143
const M_ROW_H := 17
const M_ROWS := 8
const M_GAME_X := 148
const M_GAME_W := 205
const M_PLAYER_W := 132
const M_PREVIEW := Rect2(148, 305, 225, 62)
const M_LOAD := Rect2(378, 303, 112, 25)
const M_CANCEL := Rect2(378, 343, 112, 25)

func _target_at(d: Vector2) -> String:
	if _modal:
		if M_LOAD.has_point(d) and _has_save: return "mload"
		if M_CANCEL.has_point(d): return "mcancel"
		if _has_save and Rect2(M_GAME_X, M_ROW0_Y, M_GAME_W + M_PLAYER_W + 4, M_ROW_H).has_point(d):
			return "mrow0"
		return ""
	for lv in LEVELS:
		if _abs(lv["rect"]).has_point(d):
			return str(lv["key"])
	# checkbox: include its caption for a fatter tap target
	if Rect2(_abs(R_CHK).position, Vector2(120, 16)).has_point(d): return "chk"
	if _has_save and _abs(R_LOAD).has_point(d): return "load"
	if _abs(R_CANCEL).has_point(d): return "cancel"
	return ""


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
		"chk":
			_players_age = not _players_age
			queue_redraw()
		"load":
			_modal = true
			queue_redraw()
		"cancel":
			cancel_pressed.emit()
		"mcancel":
			_modal = false
			queue_redraw()
		"mload", "mrow0":
			if _has_save:
				load_game.emit(0)
		_:
			level_chosen.emit(was, _players_age)


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, cw := 0.0, center := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

## The mirrored silver caption band (bright edge outward, dark toward the divider).
func _band(r: Rect2, label: String, bright_left: bool) -> void:
	for i in int(r.size.x):
		var t := float(i) / maxf(1.0, r.size.x - 1)
		if not bright_left:
			t = 1.0 - t
		var v := lerpf(1.0, 0.08, t)
		draw_rect(Rect2(r.position + Vector2(i, 0), Vector2(1, r.size.y)),
			Color(v, v, v * 1.05), true)
	# caption text sits toward the bright end (frame 003)
	var f := _f10
	var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var tx := r.position.x + 14.0 if bright_left else r.end.x - w - 14.0
	_txt(f, tx, r.position.y + 5, label, Color(0.05, 0.05, 0.10), 11)


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	# centre-anchored opening zoom (frame 002 = the 0.8 step)
	if _zoom < 1.0:
		var c := DLG.position + DLG.size * 0.5
		draw_set_transform(_origin(s) + c * s * (1.0 - _zoom), 0.0, Vector2(s * _zoom, s * _zoom))

	var o := DLG.position
	# fondo art (453x383) + the painted bottom strip under it
	if _fondo != null:
		draw_texture_rect(_fondo, Rect2(o, Vector2(DLG.size.x, ART_H)), false)
	draw_rect(Rect2(o + Vector2(0, ART_H), Vector2(DLG.size.x, DLG.size.y - ART_H)), Color8(6, 6, 22), true)
	draw_rect(Rect2(o + Vector2(0, ART_H), Vector2(DLG.size.x, DLG.size.y - ART_H)), Color(1, 1, 1, 0.25), false)

	# title on the art's black strip
	_txt(_f10, o.x, o.y + 6, "SELECT LEVEL OF THE GAME", Color.WHITE, 12, DLG.size.x, true)

	# caption bands (drawn over the art's baked ones, which face the other way)
	_band(Rect2(o + Vector2(BAND_L.position.x, BAND1_Y), Vector2(BAND_L.size.x, BAND_H)), "TRAINER", true)
	_band(Rect2(o + Vector2(BAND_R.position.x, BAND1_Y), Vector2(BAND_R.size.x, BAND_H)), "MANAGER", false)
	_band(Rect2(o + Vector2(BAND_L.position.x, BAND2_Y), Vector2(BAND_L.size.x, BAND_H)), "ACCOUNTANT", true)
	_band(Rect2(o + Vector2(BAND_R.position.x, BAND2_Y), Vector2(BAND_R.size.x, BAND_H)), "TOTAL", false)

	# level art panels (…1.bmp = the pressed/hover state)
	for lv in LEVELS:
		var pressed := _press == str(lv["key"])
		var tex: Texture2D = _art["%s%d" % [lv["art"], 1 if pressed else 0]]
		if tex != null:
			draw_texture_rect(tex, _abs(lv["rect"]), false)

	# bullets (exact .rdata strings) just under each art
	var bx := [o.x + 35, o.x + 284]
	for i in LEVELS.size():
		var lv: Dictionary = LEVELS[i]
		var lines: Array = BULLETS[lv["key"]]
		var r: Rect2 = _abs(lv["rect"])
		var by := r.end.y + 4.0
		if lines.size() == 1:
			by += 11.0   # single bullets align with the second line (frame 003)
		for j in lines.size():
			_txt(_f8, bx[i % 2], by + j * 11, str(lines[j]), Color.WHITE, 9)

	# Players age ? checkbox + caption
	var chk := _abs(R_CHK)
	draw_rect(chk, Color(0.92, 0.94, 0.97), true)
	draw_rect(chk, Color(0.2, 0.2, 0.3), false)
	if _players_age and _ok != null:
		draw_texture_rect(_ok, chk, false)
	_txt(_f8, chk.end.x + 6, chk.position.y + 2, "Players age ?", Color.WHITE, 10)

	# footer buttons
	_button(_abs(R_LOAD), "LOAD GAME", C_LOADTXT, _has_save, "load", true)
	_button(_abs(R_CANCEL), "CANCEL", C_CANCELTXT, true, "cancel", false)

	if _modal:
		_draw_modal()


func _button(r: Rect2, label: String, col: Color, enabled: bool, key: String, icon: bool) -> void:
	draw_rect(r, Color8(10, 10, 14), true)
	PMChrome.bevel(self, r, Color8(10, 10, 14), Color(0.45, 0.45, 0.5), Color(0, 0, 0))
	if _press == key:
		draw_rect(r, Color(1, 1, 1, 0.18), true)
	var tx := r.position.x
	if icon and _carga != null:
		draw_texture_rect(_carga, Rect2(r.position + Vector2(6, 3), _carga.get_size()), false)
		tx += 30
	if not enabled:
		col = Color(col, 0.35)
	_txt(_f12, tx, r.position.y + 5, label, col, 13, r.size.x - (tx - r.position.x), true)


## The LOAD GAME modal (frames 005/006): red title card, GAME|PLAYER columns, 8 save
## rows, preview strip, LOAD/CANCEL. The engine has ONE save today -> row 1 shows it,
## rows 2-8 draw as the empty blue bars the original shows for unused slots.
func _draw_modal() -> void:
	draw_rect(M_DLG.grow(6), Color8(12, 12, 24), true)
	draw_rect(M_DLG.grow(6), Color(1, 1, 1, 0.35), false)
	# red title bar with the striped end caps the Dinamic cards use
	draw_rect(M_TITLE, Color8(150, 10, 10), true)
	for i2 in 8:
		var wseg := 4
		draw_rect(Rect2(M_TITLE.position + Vector2(4 + i2 * 8, 3), Vector2(wseg, M_TITLE.size.y - 6)),
			Color8(90, 6, 6) if i2 % 2 == 0 else Color8(200, 30, 30), true)
		draw_rect(Rect2(Vector2(M_TITLE.end.x - 12 - i2 * 8, M_TITLE.position.y + 3), Vector2(wseg, M_TITLE.size.y - 6)),
			Color8(90, 6, 6) if i2 % 2 == 0 else Color8(200, 30, 30), true)
	_txt(_f12, M_TITLE.position.x, M_TITLE.position.y + 3, "LOAD GAME", Color.WHITE, 14, M_TITLE.size.x, true)
	_txt(_f10, M_GAME_X, M_HDR_Y, "GAME", Color8(60, 80, 255), 11, M_GAME_W, true)
	_txt(_f10, M_GAME_X + M_GAME_W + 4, M_HDR_Y, "PLAYER", Color8(60, 80, 255), 11, M_PLAYER_W, true)
	for i in M_ROWS:
		var y := M_ROW0_Y + i * M_ROW_H
		var filled := i == 0 and _has_save
		var cbar := Color8(24, 40, 140) if not filled else Color8(40, 60, 170)
		draw_rect(Rect2(M_GAME_X, y, M_GAME_W, M_ROW_H - 3), cbar, true)
		draw_rect(Rect2(M_GAME_X + M_GAME_W + 4, y, M_PLAYER_W, M_ROW_H - 3), Color8(90, 110, 200), true)
		if filled:
			if _press == "mrow0":
				draw_rect(Rect2(M_GAME_X, y, M_GAME_W + M_PLAYER_W + 4, M_ROW_H - 3), Color(1, 1, 1, 0.2), true)
			_txt(_f10, M_GAME_X + 6, y + 1, str(_save_summary.get("club", "SAVED GAME")), Color.WHITE, 11)
			_txt(_f10, M_GAME_X + M_GAME_W + 10, y + 1, str(_save_summary.get("name", "")), Color.WHITE, 11)
	# preview strip (three grey bars, as the empty preview shows in frame 005)
	for i in 3:
		draw_rect(Rect2(M_PREVIEW.position + Vector2(0, i * 21), Vector2(M_PREVIEW.size.x, 16)),
			Color(0.72, 0.76, 0.84), true)
	_button(M_LOAD, "LOAD", C_LOADTXT, _has_save, "mload", true)
	_button(M_CANCEL, "CANCEL", C_CANCELTXT, true, "mcancel", false)
