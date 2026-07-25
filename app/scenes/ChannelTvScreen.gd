extends Control
class_name ChannelTvScreen
## PM98 `channelTV` card -- the original sells the broadcast rights to each HOME match
## and raises this over MANAGER MENU, unprompted, BEFORE the match is played
## (docs/re/REFRUN_manutd_1997-98.md R6; witnessed Sun 3 Aug 1997, Wed 1 Oct 1997,
## Sat 25 Oct 1997 and Sat 7 Feb 1998, all Manchester Utd. home fixtures).
##
## Chrome = the real frame's panel, cut 1:1 with ONLY the fee line blanked
## (tools/re/build_channeltv_card_from_frames.py). The bake refuses to run unless the
## two captured cards are byte-identical everywhere except that line and the OK
## button, so the logo, the camera art and both body lines are the original's pixels
## and the fee is the one thing this scene draws.
##
## The fee IS that week's TELEVISION ledger line -- proved on Man Utd's week 29, where
## the card says £90,000 and the ledger's TELEVISION row for the same week reads
## £90,000. FinanceModel.TV_FEE holds the per-competition table.

signal ok_pressed

const W := 640
const H := 480

# From tools/re/build_channeltv_card_from_frames.py (art/screens/channeltv/channeltv.json).
const PANEL := Vector2i(96, 102)                  # the panel's top-left on screen
const OK_RECT := Rect2(463, 345, 78, 29)
# The fee line, screen-absolute: ink measured at y329..339, x265..373, centred on the
# card. Drawn white, the same ink as the two body lines above it.
const FEE_BASELINE := 339
const FEE_CENTRE_X := 320
const C_FEE := Color8(255, 255, 255)

var _chrome: Texture2D
var _f12: Font
var _fee := 0
var _press := false


func _ready() -> void:
	_chrome = load("res://art/screens/channeltv/card.png")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `fee` is the competition's channelTV fee in pounds (FinanceModel.TV_FEE).
func setup(fee: int) -> void:
	_fee = fee
	queue_redraw()


func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = OK_RECT.has_point(d)
		queue_redraw()
		return
	var was := _press
	_press = false
	queue_redraw()
	if was and OK_RECT.has_point(d):
		ok_pressed.emit()


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2(PANEL))
	if _f12 != null and _fee > 0:
		# "For £90,000" -- the frame's own wording and thousands separators.
		var txt := "For %s" % FinanceScreen.fmt_money(_fee)
		var w := _f12.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_f12, Vector2(FEE_CENTRE_X - w * 0.5, FEE_BASELINE), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_FEE)
	if _press:
		draw_rect(OK_RECT, Color(1, 1, 1, 0.2), true)
