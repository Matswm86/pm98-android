extends Control
class_name MatchOptions
## PM98 MATCH OPTIONS — the in-match view-mode picker, rebuilt 1:1 from MANAGER.EXE.
##
## The original's `FUN_004e2630` lays out a 437-wide options dialog whose top row is a
## four-button view-mode toolbar. Every rect below is RECOVERED from the binary (point/rect
## helpers FUN_00436fb0 + FUN_00436fd0, rect = pos+size), NOT invented — see
## docs/re/match_view_re.md for the disassembly and addresses:
##
##   title  "MATCH OPTIONS"  rect (2,2)-(437,30)        @ 0x4e6be0 / str 0x657974
##   WATCH       pos (5,100)   size (98,25)  rect-build @ 0x4e2aad  str 0x655fd8
##   HIGHLIGHTS  pos (109,100) size (98,25)  rect-build @ 0x4e2b18  str 0x657968
##   BRIEF       pos (214,100) size (98,25)  rect-build @ 0x4e2b86  str 0x657960
##   RESULTS     pos (317,100) size (98,25)  rect-build @ 0x4e2bf4  str 0x65429c
##
## Routing (honest to what is buildable from the source on hand):
##   BRIEF    -> the built commentary MatchScreen.gd            (emits picked("brief"))
##   RESULTS  -> MatchScreen seeked to full time               (emits picked("results"))
##   WATCH    -> the 2D GRAFICO simulador MatchSimulador.gd     (emits picked("watch"))
##              real DATSIM sprites on a vectorial pitch, animated over the same
##              MatchCommentary timeline as BRIEF (built; docs/re/match_view_re.md step 3).
##   HIGHLIGHTS -> the 3D engine; its Actua `.p3d` model data is absent from the PM98 disc
##              AND the .rar, so it cannot be ported. Selecting it shows the honest note.
##
## The panel's INTERNAL geometry is source-exact; its on-screen position (centred in the
## 640x480 design space) is an app layout choice — the dialog's window position is set
## elsewhere in the EXE, not in FUN_004e2630.

signal picked(mode: String)        # "brief" | "results" (the two buildable views)

const W := 640
const H := 480

# Panel placement in the 640x480 design space (centred). Internal rects are source-exact.
const PANEL := Rect2(101, 160, 437, 158)

# Source-exact, panel-local rects.
const TITLE_RECT := Rect2(2, 2, 435, 28)
const BTN_RECTS := [
	Rect2(5, 100, 98, 25),     # 0 WATCH
	Rect2(109, 100, 98, 25),   # 1 HIGHLIGHTS
	Rect2(214, 100, 98, 25),   # 2 BRIEF
	Rect2(317, 100, 98, 25),   # 3 RESULTS
]
const BTN_LABELS := ["WATCH", "HIGHLIGHTS", "BRIEF", "RESULTS"]
const MODES := ["watch", "highlights", "brief", "results"]
# Honest, RE-grounded descriptions of what each mode IS (no invented game text).
const MODE_DESC := [
	"WATCH: 2D graphic simulador (real DATSIM sprites on the pitch), animated over the same match timeline as BRIEF.",
	"HIGHLIGHTS: 3D engine. The Actua .p3d model data is absent from the PM98 disc and the .rar, so it cannot be ported.",
	"BRIEF: minute-by-minute commentary: clock, half, score, possession and the events feed.",
	"RESULTS: skip straight to the full-time result.",
]
const DEFAULT_SEL := 2   # BRIEF

# colours: reuse MatchScreen's palette so the overlay matches the rest of the UI.
const C_DIM := Color(0.02, 0.03, 0.07, 0.62)
const C_PANEL := Color(0.10, 0.16, 0.34, 0.98)
const C_PANEL_BD := Color(0.46, 0.60, 0.92)
const C_TITLE_BG := Color(0.12, 0.18, 0.34, 1.0)
const C_TITLE := Color(0.98, 0.99, 1.0)
const C_GOLD := Color(1.0, 0.86, 0.20)
const C_DESC_BG := Color(0.06, 0.10, 0.22, 0.96)
const C_DESC_TXT := Color(0.82, 0.88, 0.98)
const C_BTN := Color(0.10, 0.16, 0.34, 1.0)
const C_BTN_SEL := Color(0.20, 0.34, 0.66)
const C_BTN_HI := Color(0.30, 0.42, 0.72)
const C_BTN_LO := Color(0.03, 0.06, 0.16)
const C_BTN_OFF := Color(0.62, 0.66, 0.74)    # text of the unbuildable view (HIGHLIGHTS / 3D)

var _f18: Font
var _f12: Font
var _f10: Font
var _sel := DEFAULT_SEL
var _press := -1


func _ready() -> void:
	_f18 = _font("res://art/fonts/proman18.fnt", "res://art/fonts/proman14.fnt")
	_f12 = _font("res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt")
	_f10 = _font("res://art/fonts/proman10.fnt", "res://art/fonts/proman12.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	queue_redraw()


func _font(path: String, fallback: String) -> Font:
	return load(path) if ResourceLoader.exists(path) else load(fallback)


# ---- input ---------------------------------------------------------------

## Hit-test in panel-local space. Returns the button index or -1.
func _btn_at(d: Vector2) -> int:
	var local := d - PANEL.position
	for i in BTN_RECTS.size():
		if (BTN_RECTS[i] as Rect2).has_point(local):
			return i
	return -1


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _btn_at(d)
	else:
		var rel := _btn_at(d)
		if rel != -1 and rel == _press:
			_select(rel)
		_press = -1
	queue_redraw()


## Selecting a mode: BRIEF/RESULTS proceed; WATCH/HIGHLIGHTS just highlight + show the note.
func _select(i: int) -> void:
	_sel = i
	match MODES[i]:
		"brief": picked.emit("brief")
		"results": picked.emit("results")
		"watch": picked.emit("watch")
		_: pass   # highlights: 3D .p3d absent from source — note shown, no proceed


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	# panel
	draw_rect(PANEL, C_PANEL, true)
	draw_rect(PANEL, C_PANEL_BD, false, 2.0)

	# title bar (source rect, panel-local -> design)
	var tr := Rect2(PANEL.position + TITLE_RECT.position, TITLE_RECT.size)
	draw_rect(tr, C_TITLE_BG, true)
	draw_rect(tr, C_PANEL_BD, false, 1.0)
	_txt(_f18, int(tr.position.x), int(tr.position.y) + 5, "MATCH OPTIONS", C_TITLE, 18, int(tr.size.x))

	# description inset (the dialog's tab-content area above the toolbar)
	var dr := Rect2(PANEL.position.x + 5, PANEL.position.y + 36, 425, 58)
	draw_rect(dr, C_DESC_BG, true)
	draw_rect(dr, Color(0.3, 0.4, 0.6, 0.6), false, 1.0)
	_wrap(_f10, dr.position + Vector2(8, 6), 409, MODE_DESC[_sel], C_DESC_TXT, 12)

	# the four source-exact view buttons
	for i in BTN_RECTS.size():
		_button(i)


func _button(i: int) -> void:
	var r := Rect2(PANEL.position + (BTN_RECTS[i] as Rect2).position, (BTN_RECTS[i] as Rect2).size)
	var base: Color = C_BTN
	if _press == i:
		base = C_BTN_HI
	elif _sel == i:
		base = C_BTN_SEL
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), C_BTN_HI, true)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), C_BTN_LO, true)
	draw_rect(r, Color(0.5, 0.6, 0.8, 0.6), false, 1.0)
	# Only HIGHLIGHTS is unbuildable (3D .p3d absent) -> dimmed; WATCH/BRIEF/RESULTS active.
	var fg: Color = C_BTN_OFF if i == 1 else (C_GOLD if _sel == i else C_TITLE)
	_txt(_f12, int(r.position.x), int(r.position.y) + 6, BTN_LABELS[i], fg, 13, int(r.size.x))


func _txt(f: Font, x: int, y_top: int, t: String, col: Color, sz: int, cw := 0) -> void:
	if f == null:
		return
	var wd := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x) + (cw - wd) * 0.5 if cw > 0 else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## Word-wrap `t` inside `width` starting at `pos`, line height from the font.
func _wrap(f: Font, pos: Vector2, width: float, t: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var lh := f.get_height(sz) + 1
	var line := ""
	var y := pos.y
	for word in t.split(" "):
		var trial := word if line == "" else line + " " + word
		if f.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width and line != "":
			draw_string(f, Vector2(pos.x, y + f.get_ascent(sz)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			line = word
			y += lh
		else:
			line = trial
	if line != "":
		draw_string(f, Vector2(pos.x, y + f.get_ascent(sz)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- letterbox scaling (identical to MatchScreen) ------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
