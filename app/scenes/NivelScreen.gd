extends Control
class_name NivelScreen
## PM98 "SELECT LEVEL OF THE GAME" dialog (NIVELES). The static chrome is the REAL
## game's own settled frame (walkthrough 003, cropped to the dialog rect reversed out
## of MANAGER.EXE: creation fn ~0x54a580, id 1034, POS (93,32) SIZE 453x415) — see
## docs/re/nivel_screen_re.md and tools/re/build_entry_chrome_from_frames.py. The
## LOAD GAME modal chrome is frame 005's card (bbox via diff(005,003) = (140,102)
## 360x276, all TEN save rows empty = the resting state; the same card chassis
## as the SAVE GAME dialog, whose witness 51 pins rows y144 + 16k).
##
## Dynamic layer only: level-panel pressed states (the original *1.bmp art), the
## "Players age ?" tick (ok.bmp), button press tints, and the modal's row-1 text
## when a save exists. Tapping a level panel picks it; LOAD GAME opens the modal;
## CANCEL returns to the title. Native 640x480 design space; scales to fit (NEAREST).

signal level_chosen(level: String, players_age: bool)
signal load_game(slot: int)
signal cancel_pressed

const W := 640
const H := 480

# Dialog container: POS (93,32) SIZE 453x415 (id 1034; chrome.png == this crop).
const DLG := Rect2(93, 32, 453, 415)

# Client rects (reversed; screen = client + DLG.position)
const R_ENT := Rect2(30, 55, 120, 105)      # TRAINER art  (Entrenador0/1)
const R_MAN := Rect2(279, 56, 149, 104)     # MANAGER art
const R_PRE := Rect2(28, 209, 132, 124)     # ACCOUNTANT art (Presidente0/1)
const R_TOT := Rect2(272, 206, 153, 128)    # TOTAL art
const R_CHK := Rect2(14, 364, 14, 14)       # "Players age ?" checkbox (ok.bmp tick)
const R_LOAD := Rect2(6, 385, 132, 25)      # LOAD GAME (+carga icon)
const R_CANCEL := Rect2(143, 385, 103, 25)

const C_LOADTXT := Color8(123, 223, 82)     # LOAD GAME text (COLOR call 0x54a63e)
const C_CANCELTXT := Color8(255, 31, 0)     # CANCEL/DELETE red (family constant)
const ZOOM_TIME := 0.15                     # frame 002 = mid-zoom at ~0.8 scale

const LEVELS := [
	{"key": "trainer", "cap": "TRAINER", "rect": R_ENT, "art": "entrenador"},
	{"key": "manager", "cap": "MANAGER", "rect": R_MAN, "art": "manager"},
	{"key": "accountant", "cap": "ACCOUNTANT", "rect": R_PRE, "art": "presidente"},
	{"key": "total", "cap": "TOTAL", "rect": R_TOT, "art": "total"},
]
# Per-level bullet captions — strings verbatim from MANAGER.EXE .rdata. They are
# BAKED into chrome.png (original rasters); kept here as the RE record + for tests.
const BULLETS := {
	"trainer": ["- Automatic finances", "- Automatic contract renewal"],
	"manager": ["- Automatic contract renewal"],
	"accountant": ["- Automatic tactics and squad"],
	"total": ["- Total control"],
}

# LOAD GAME modal (frame 005; card bbox = diff(005,003)). Row/button rects are tap
# targets + dynamic-text anchors over the baked card.
const M_DLG := Rect2(140, 102, 360, 276)
const M_ROW0_Y := 143
const M_ROW_H := 16    # true card pitch (SAVE GAME witness 51: rows y144+16k)
const M_GAME_X := 148
const M_GAME_W := 205
const M_PLAYER_W := 132
const M_LOAD := Rect2(378, 303, 112, 25)
const M_CANCEL := Rect2(378, 343, 112, 25)

var _chrome: Texture2D
var _modal_tex: Texture2D
var _ok: Texture2D
var _art: Dictionary = {}      # "entrenador1" -> Texture2D (pressed states)
var _f10: Font

var _players_age := false
var _press := ""               # held target key
var _zoom := 0.8               # opening zoom (0.8 -> 1.0, centre-anchored)
var _has_save := false
var _save_summary: Dictionary = {}   # {name, club} of the existing save (row 1 of modal)
var _slots: Array = []               # 10 SAVE GAME slot metas ({} or {game, player})
var _modal := false            # LOAD GAME modal (frames 005/006) open

func _ready() -> void:
	_chrome = load("res://art/screens/nivel/chrome.png")
	_modal_tex = load("res://art/screens/nivel/load_modal.png")
	_ok = load("res://art/screens/nivel/ok.png")
	for lv in LEVELS:
		var key: String = "%s1" % lv["art"]
		_art[key] = load("res://art/screens/nivel/%s.png" % key)
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	var tw := create_tween()
	tw.tween_method(_set_zoom, 0.8, 1.0, ZOOM_TIME)


func _set_zoom(v: float) -> void:
	_zoom = v
	queue_redraw()


## has_save + a one-line summary ({name, club}) for the load modal's legacy
## autosave row, plus the 10 SAVE GAME dialog slot metas ({} or {game, player};
## Career.slot_metas). Slot rows list user saves; the autosave summary shows on
## row 0 only while slot 0 is empty (compat with pre-slot saves).
func setup(has_save: bool, save_summary: Dictionary = {}, slots: Array = []) -> void:
	_has_save = has_save
	_save_summary = save_summary
	_slots = []
	for i in 10:
		_slots.append(slots[i] if i < slots.size() and slots[i] is Dictionary else {})
	queue_redraw()


func _any_loadable() -> bool:
	for k in 10:
		if _row_kind(k) != "":
			return true
	return false


## What the load modal's row k lists: "slot" k, the legacy "auto" save, or "".
func _row_kind(k: int) -> String:
	if not (_slots[k] as Dictionary).is_empty():
		return "slot"
	if k == 0 and _has_save:
		return "auto"
	return ""


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


func _target_at(d: Vector2) -> String:
	if _modal:
		if M_LOAD.has_point(d) and _any_loadable(): return "mload"
		if M_CANCEL.has_point(d): return "mcancel"
		for k in 10:
			if _row_kind(k) != "" and Rect2(M_GAME_X, M_ROW0_Y + M_ROW_H * k,
					M_GAME_W + M_PLAYER_W + 4, M_ROW_H).has_point(d):
				return "mrow:%d" % k
		return ""
	for lv in LEVELS:
		if _abs(lv["rect"]).has_point(d):
			return str(lv["key"])
	# checkbox: include its caption for a fatter tap target
	if Rect2(_abs(R_CHK).position, Vector2(120, 16)).has_point(d): return "chk"
	# frame truth 003/005: LOAD GAME is solid and opens the (empty) modal even with
	# no save — the walkthrough had none and the modal showed 8 empty rows
	if _abs(R_LOAD).has_point(d): return "load"
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
		"mload":
			for k in 10:
				if _row_kind(k) != "":
					load_game.emit(k if _row_kind(k) == "slot" else -1)
					break
		_ when was.begins_with("mrow:"):
			var k := int(was.split(":")[1])
			load_game.emit(k if _row_kind(k) == "slot" else -1)
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


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	# centre-anchored opening zoom (frame 002 = the 0.8 step)
	if _zoom < 1.0:
		var c := DLG.position + DLG.size * 0.5
		draw_set_transform(_origin(s) + c * s * (1.0 - _zoom), 0.0, Vector2(s * _zoom, s * _zoom))

	# the whole resting dialog is the real frame-003 pixels
	if _chrome != null:
		draw_texture_rect(_chrome, DLG, false)

	# pressed level panel -> the original *1.bmp hover/pressed art
	for lv in LEVELS:
		if _press == str(lv["key"]):
			var tex: Texture2D = _art["%s1" % lv["art"]]
			if tex != null:
				draw_texture_rect(tex, _abs(lv["rect"]), false)

	# Players age ? tick (ok.bmp; the empty box is baked)
	if _players_age and _ok != null:
		draw_texture_rect(_ok, _abs(R_CHK), false)

	if _press == "load":
		draw_rect(_abs(R_LOAD), Color(1, 1, 1, 0.18), true)
	if _press == "cancel":
		draw_rect(_abs(R_CANCEL), Color(1, 1, 1, 0.18), true)

	if _modal:
		_draw_modal()


## The LOAD GAME modal: baked frame-005 card (8 empty rows = resting). Dynamic:
## row-1 text when the engine save exists + press tints. The engine holds ONE save
## today -> rows 2-8 stay the baked empty bars (honest).
func _draw_modal() -> void:
	if _modal_tex != null:
		draw_texture_rect(_modal_tex, M_DLG, false)
	for k in 10:
		var kind := _row_kind(k)
		if kind == "":
			continue
		var y := M_ROW0_Y + M_ROW_H * k
		if kind == "slot":
			var m: Dictionary = _slots[k]
			_txt(_f10, M_GAME_X + 6, y + 1, str(m.get("game", "")), Color.WHITE, 10)
			_txt(_f10, M_GAME_X + M_GAME_W + 10, y + 1, str(m.get("player", "")), Color.WHITE, 10)
		else:
			_txt(_f10, M_GAME_X + 6, y + 1, str(_save_summary.get("club", "SAVED GAME")), Color.WHITE, 10)
			_txt(_f10, M_GAME_X + M_GAME_W + 10, y + 1, str(_save_summary.get("name", "")), Color.WHITE, 10)
		if _press == "mrow:%d" % k:
			draw_rect(Rect2(M_GAME_X, y, M_GAME_W + M_PLAYER_W + 4, M_ROW_H - 2), Color(1, 1, 1, 0.2), true)
	if _press == "mload":
		draw_rect(M_LOAD, Color(1, 1, 1, 0.18), true)
	if _press == "mcancel":
		draw_rect(M_CANCEL, Color(1, 1, 1, 0.18), true)
