extends Control
class_name FinesScreen
## THE FINES (MULTAS) card — `FUN_00549d40`, raised over MANAGER MENU by the weekly hub run
## `FUN_00545fd0` @0x546164 whenever any of the club's five fine accumulators is non-zero.
##
## Unlike every other screen in this port, this one needs NO frame bake: each thing it draws
## is a whole entry in RECURSOS.PKF, and MANAGER.EXE blits it at a literal coordinate. The
## art is exported 1:1 by `tools/re/build_fines_card_from_pkf.py` and the geometry below is
## `art/screens/fines/fines.json`, which that script writes from the disassembly.
##
## The two independent size agreements are the check that the right entries were picked:
## MULTAS\FONDO.BMP is 418x316 and the binary's panel CRect is 418x316; ESTADIO\EQUIPAM_*
## are 40x26 and the binary's per-row icon CRect is 40x26. Neither number was chosen here.
##
## DECLARED, because no capture of this card exists in the corpus (the reference careers
## never triggered it — Man Utd's preset-0 ground clears every standard): the OK plate's
## HIT rect is the binary's own text rect grown by the 2 px border every other modal in this
## port measures, exactly as ChannelTvScreen's witnessed plate sits 2 px outside its text
## rect. Everything else is a literal.

signal ok_pressed

const W := 640
const H := 480

const PANEL := Vector2i(111, 82)        # FUN_00436fb0(0x6f,0x52)   @0x549e0d
const PANEL_SIZE := Vector2i(418, 316)  # FUN_00436fb0(0x1a2,0x13c) @0x549e02
const MULTA_AT := Vector2i(12, 6)       # the empty-string CRect the sprite fills, 54x58
const ROW_Y := [78, 122, 166, 210, 254] # 0x4e, then +0x2c a row
const ICON_X := 19                      # FUN_00436fb0(0x13, y)     @0x54a0a6
const ICON_SIZE := Vector2i(40, 26)     # FUN_00436fb0(0x28,0x1a)   @0x54a090
const TEXT_X := 71                      # FUN_00436fb0(0x47, y-8)
const TEXT_W := 345                     # FUN_00436fb0(0x159,0x2a)
const TEXT_DY := -8
const OK_TEXT := Vector2i(336, 284)     # FUN_00436fb0(0x150,0x11c) @0x549f0d
const OK_SIZE := Vector2i(74, 25)       # FUN_00436fb0(0x4a,0x19)   @0x549f03
const OK_BORDER := 2

const C_OK := Color8(255, 223, 0)       # FUN_00437020(0xff,0xdf,0) @0x549ef6
const C_ROW := Color8(255, 255, 255)    # FUN_00436270(0xffffff)    in FUN_00549fe0
const ICONS := ["icon_floodlights", "icon_changing_rooms", "icon_score_board",
	"icon_access", "icon_medical"]

var _panel: Texture2D
var _multa: Texture2D
var _icon: Dictionary = {}
var _f8: Font
var _f14: Font
var _rows: Array = []
var _press := false


func _ready() -> void:
	_panel = load("res://art/screens/fines/panel.png")
	_multa = load("res://art/screens/fines/multa.png")
	for n in ICONS:
		var p := "res://art/screens/fines/%s.png" % n
		if ResourceLoader.exists(p):
			_icon[n] = load(p)
	_f8 = PMChrome.font("8")
	_f14 = PMChrome.font("14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `rows` is what `Career.take_fines()` drained: up to five {"icon", "message"} entries in
## the binary's own field order. The original draws only the fields that are non-zero and
## closes the panel up around them (`iVar6` advances only on a drawn row), which is what
## the ROW_Y ladder does here.
func setup(rows: Array) -> void:
	_rows = rows
	queue_redraw()


func ok_rect() -> Rect2:
	return Rect2(
		PANEL.x + OK_TEXT.x - OK_BORDER, PANEL.y + OK_TEXT.y - OK_BORDER,
		OK_SIZE.x + OK_BORDER * 2, OK_SIZE.y + OK_BORDER * 2)


func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = ok_rect().has_point(d)
		queue_redraw()
		return
	var was := _press
	_press = false
	queue_redraw()
	if was and ok_rect().has_point(d):
		ok_pressed.emit()


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0,
		Vector2(s, s))
	if _panel != null:
		draw_texture(_panel, Vector2(PANEL))
	if _multa != null:
		draw_texture(_multa, Vector2(PANEL + MULTA_AT))
	for i in range(mini(_rows.size(), ROW_Y.size())):
		var row: Dictionary = _rows[i]
		var y: int = PANEL.y + int(ROW_Y[i])
		var tex: Texture2D = _icon.get(str(row.get("icon", "")), null)
		if tex != null:
			draw_texture_rect(tex,
				Rect2(PANEL.x + ICON_X, y, ICON_SIZE.x, ICON_SIZE.y), false)
		if _f8 != null:
			var line_y := y + TEXT_DY + 9
			for line in str(row.get("message", "")).split("\n"):
				draw_string(_f8, Vector2(PANEL.x + TEXT_X, line_y), line,
					HORIZONTAL_ALIGNMENT_LEFT, TEXT_W, 9, C_ROW)
				line_y += 11
	if _f14 != null:
		var ok_w := _f14.get_string_size("OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(_f14,
			Vector2(PANEL.x + OK_TEXT.x + (OK_SIZE.x - ok_w) * 0.5,
				PANEL.y + OK_TEXT.y + 18),
			"OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_OK)
	if _press:
		draw_rect(ok_rect(), Color(1, 1, 1, 0.2), true)
