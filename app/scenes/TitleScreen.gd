extends Control
class_name TitleScreen
## PM98 TITLE / FRONT-DOOR screen rebuilt from the ORIGINAL game art.
##
## The front door is FUN_00545180 in MANAGER.EXE: it loads its full-screen background
## via FUN_004fa840 with screen id 0x4e3e -> FONDO index 7 ->
## `RECURSOS\PREMIER\SININFO\FONDO7.bmp` (640x480, the iconic PREMIER MANAGER 98 title),
## then walks a 44-byte-stride control table at DAT_00633588 placing four owner-drawn
## buttons (ids 20002/20021/20022 DATA BASE / MANAGER LEAGUE / PRO-MANAGER LEAGUE +
## 20026 SALIR). The three league/database buttons are already drawn into FONDO7 (the
## title art is a complete pre-rendered scene, like the ESTADIO tier scenes), so this
## node blits FONDO7 and turns taps over those three baked ellipses into actions; the
## EXIT control is drawn + hit at the salir rect the table places it (pos 552,431
## size 73x35). See docs/re/title_screen_re.md for the full reverse + provenance.
##
## INTERACTIVE: tapping a button emits `action_selected(action)`; the calling Main
## routes it (database browse / new career / quit). Native 640x480; self-scales to
## fit its parent with a marble bezel in the landscape letterbox margins.

signal action_selected(action: String)

const W := 640
const H := 480

const C_EXIT := Color(0.91, 0.94, 1.0)        # light text on the EXIT control
const C_EXIT_BG := Color(0.05, 0.10, 0.35, 0.78)  # navy pill behind EXIT (art has none)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.20)  # press feedback

# Hit areas in 640x480 design space. The three option buttons are the blue ellipses
# baked into FONDO7 (rects measured off the pre-rendered title art); EXIT is the
# reversed salir control rect from the FUN_00545180 layout table (pos 552,431 sz 73x35).
# Tuned to the real box-art title (art/screens/title/fondo7.png, from the 894x671
# Premier Manager 98 cover resized to 640x480): the three blue ovals sit on the left,
# the small circular SALIR glyph is baked bottom-right.
# EXACT reversed control-table rects (title_screen_re.md §52-54: ids drawn at pos.y − 0x14,
# size 332×45): base_datos (20,197,332,45) / liga_manager (20,255,332,45) / liga_promanager
# (20,314,332,45). Cross-checked against fondo7.png (blue ovals at y 202/261/320). SALIR glyph
# bottom-right at x 560..616 / y 410..458.
const HITS := {
	"database": Rect2(20, 197, 332, 45),        # DATA BASE        (id 20002)
	"career_league": Rect2(20, 255, 332, 45),   # MANAGER LEAGUE   (id 20021)
	"career_pro": Rect2(20, 314, 332, 45),      # PRO-MANAGER LEAGUE (id 20022)
	"exit": Rect2(558, 408, 64, 54),            # SALIR glyph      (id 20026)
}

var _bg: Texture2D
var _bezel: Texture2D            # marble fill for the landscape letterbox margins
var _f12: Font
var _press: String = ""          # action currently held down (for the highlight)


func _ready() -> void:
	_bg = load("res://art/screens/title/fondo7.png")
	_bezel = load("res://art/screens/fondo_marble.png")
	_f12 = load("res://art/fonts/proman12.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

## Map a parent-space point to the 640x480 design space.
func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

## The action whose hit rect contains a design-space point, or "".
func _hit(d: Vector2) -> String:
	for a in HITS:
		if (HITS[a] as Rect2).has_point(d):
			return a
	return ""


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		pos = mb.position
		pressed = mb.pressed
		tap = true
	elif e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		pos = st.position
		pressed = st.pressed
		tap = true
	if not tap:
		return
	if pressed:
		_press = _hit(_to_design(pos))
		queue_redraw()
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		queue_redraw()
		if a != "" and a == was:
			action_selected.emit(a)


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, r: Rect2, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := r.position.x + (r.size.x - w) * 0.5
	var py := r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)
	draw_string(f, Vector2(px, py), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	# Marble bezel behind the letterboxed 640x480 content (landscape margins).
	if _bezel != null:
		draw_texture_rect(_bezel, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))

	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)

	# The three league/database ovals and the SALIR glyph are baked into the title art;
	# this node only turns taps over them into actions. Show a press highlight on hold.
	if _press != "":
		draw_rect(HITS[_press], C_HILITE, true)
