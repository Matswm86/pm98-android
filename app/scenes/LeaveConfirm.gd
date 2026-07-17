extends Control
class_name LeaveConfirm
## The in-match "Do you want to leave the championship ?" confirm box —
## WITNESSED (docs/re/matchday_flow_witness_re.md §6): EXIT during a career
## match raises the standard PREMIER MANAGER 98 alert with Yes/No framework
## cells (brief_exit_leave_championship_alert.png). No -> the alert closes and
## the match resumes; Yes -> the title screen, the career abandoned UNSAVED.
## The box art is PMAlert's witnessed-parity render with the Yes/No cells cut
## from the witness frame (art/screens/alert/{yes,no}.png).

signal yes_pressed
signal no_pressed

const W := 640
const H := 480
const MSG := "Do you want to leave the championship ?"

var _tex: ImageTexture
var _box: Rect2i
var _yes: Rect2
var _no: Rect2
var _press := ""


func _ready() -> void:
	_tex = ImageTexture.create_from_image(PMAlert.render(MSG, false, true))
	_box = PMAlert.box_rect(MSG)
	_yes = PMAlert.yes_rect(MSG)
	_no = PMAlert.no_rect(MSG)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	queue_redraw()


func _hit(d: Vector2) -> String:
	if _yes.has_point(d):
		return "yes"
	if _no.has_point(d):
		return "no"
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
	else:
		var rel := _hit(d)
		if rel != "" and rel == _press:
			if rel == "yes":
				yes_pressed.emit()
			else:
				no_pressed.emit()
		_press = ""
	queue_redraw()


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _tex != null:
		draw_texture(_tex, Vector2(_box.position))
	if _press != "":
		draw_rect(_yes if _press == "yes" else _no, Color(1, 1, 1, 0.2), true)


# ---- letterbox scaling ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
