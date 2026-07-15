extends Control
class_name MatchOptions
## PM98 MATCH OPTIONS — the in-match presentation picker, rebuilt to the REAL modal.
##
## The whole modal is the original's own frame, cut verbatim from the live capture
## screenshots/wine-captures-2026-07-12/dropdown_matchoptions_match.png (the MATCH
## tab). Every label is static chrome, so nothing is redrawn — the sprite
## `art/screens/matchflow/mo_modal.png` (baked by tools/re/build_match_flow_chrome_from_frames.py)
## carries the exact pixels: the "MATCH OPTIONS" title bar, the MATCH-tab preview,
## the WATCH / HIGHLIGHTS / BRIEF / RESULTS view-mode row, the MATCH / GRAPHICS /
## CAMERAS / SOUND tab row and LINE-UPS / ON / CANCEL / OK.
##
## The view-mode row's rects are corroborated by the reversed controller FUN_004e2630
## (docs/re/match_view_re.md: 98x25 buttons @ y100, panel-local x 5/109/214/317); the
## frame is the pixel source and the hit-rects below are frame-measured (absolute).
##
## This is the hub's MATCH OPTIONS settings dialog (opened from the top dropdown bar's
## monitor icon), NOT a per-match popup: you SELECT a view mode and switch between them,
## exactly like the original PC version. Tapping a mode only SELECTS it (highlight); OK
## confirms + persists the choice, CANCEL discards. The stored mode then drives how the
## next match presents (Main._open_match).
##
## View modes (honest to what the source on hand can build):
##   BRIEF    -> the built commentary MatchScreen
##   RESULTS  -> the instant FULL TIME read-out (no running match)
##   WATCH    -> the 2D GRAFICO simulador
##   HIGHLIGHTS -> the 3D engine; its Actua `.p3d` model data is absent from the PM98
##              disc AND the .rar, so it cannot be ported — it can be selected but warns.

signal confirmed(mode: String)   # OK on a buildable mode: persist + close
signal cancelled                 # CANCEL / dismiss: no change

const W := 640
const H := 480

# Modal sprite anchor (cut offset; tools/re/specs/match_flow_chrome_samples.json).
const MODAL_XY := Vector2(98, 116)

# Frame-measured hit-rects (absolute 640x480 design space). view_row y 279..297,
# bottom row y 342..370.
const VIEW_Y := Vector2(279, 297)
const BOT_Y := Vector2(342, 370)
const VIEW := {   # mode -> [x, w]
	"watch": Vector2(116, 97), "highlights": Vector2(220, 97),
	"brief": Vector2(325, 97), "results": Vector2(428, 97),
}
const CANCEL := Vector2(323, 102)
const OK := Vector2(430, 102)

# view-mode order + the reversed source rects (panel-local), kept for the record.
const MODES := ["watch", "highlights", "brief", "results"]
const SRC_RECTS := [Rect2(5, 100, 98, 25), Rect2(109, 100, 98, 25),
	Rect2(214, 100, 98, 25), Rect2(317, 100, 98, 25)]
const DEFAULT_SEL := 2   # BRIEF (the user's default play mode)

const C_DIM := Color(0.02, 0.03, 0.07, 0.55)
const C_PRESS := Color(1, 1, 1, 0.22)
const C_SEL := Color(1.0, 0.82, 0.20)   # amber selection border on the chosen view mode
# Honest source-status note shown when HIGHLIGHTS (3D) is tapped.
const HL_NOTE := "HIGHLIGHTS: 3D engine. The Actua .p3d model data is absent from the PM98 disc and the .rar, so it cannot be ported."

var _modal: Texture2D
var _sel := DEFAULT_SEL
var _press := ""
var _note := ""


func _ready() -> void:
	_modal = load("res://art/screens/matchflow/mo_modal.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	queue_redraw()


## Open the dialog showing the currently-stored view mode as selected.
func setup(current_mode: String) -> void:
	var i := MODES.find(current_mode)
	_sel = i if i >= 0 else DEFAULT_SEL
	_note = ""
	queue_redraw()


# ---- hit-testing ---------------------------------------------------------

## The rect for a named hit target in the 640x480 design space.
func _rect(name: String) -> Rect2:
	if VIEW.has(name):
		var v: Vector2 = VIEW[name]
		return Rect2(v.x, VIEW_Y.x, v.y, VIEW_Y.y - VIEW_Y.x)
	if name == "cancel":
		return Rect2(CANCEL.x, BOT_Y.x, CANCEL.y, BOT_Y.y - BOT_Y.x)
	if name == "ok":
		return Rect2(OK.x, BOT_Y.x, OK.y, BOT_Y.y - BOT_Y.x)
	return Rect2()


## Which target a design-space point hits ("" if none).
func _hit(d: Vector2) -> String:
	for k in ["watch", "highlights", "brief", "results", "cancel", "ok"]:
		if _rect(k).has_point(d):
			return k
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
			_activate(rel)
		_press = ""
	queue_redraw()


## Route a confirmed tap. A view-mode tap only SELECTS that mode (like the original
## radio row); OK confirms + persists the current selection, CANCEL discards. HIGHLIGHTS
## can be selected but OK warns (its 3D .p3d data is absent and cannot be ported).
func _activate(target: String) -> void:
	_note = ""
	match target:
		"watch", "highlights", "brief", "results":
			_sel = MODES.find(target)   # select only; do not proceed
			if target == "highlights":
				_note = HL_NOTE
		"ok":
			var m: String = MODES[_sel]
			if m == "highlights":
				_note = HL_NOTE          # 3D .p3d absent — can't confirm HIGHLIGHTS
			else:
				confirmed.emit(m)
		"cancel":
			cancelled.emit()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _modal != null:
		draw_texture(_modal, MODAL_XY)
	# selection indicator: a bright border around the currently-chosen view mode
	# (the baked frame shows RESULTS red; this shows the LIVE selection over any mode).
	var sr := _rect(MODES[_sel])
	if sr.size.x > 0:
		draw_rect(sr.grow(2.0), C_SEL, false, 2.0)
		draw_rect(sr, Color(C_SEL.r, C_SEL.g, C_SEL.b, 0.18), true)
	# press feedback on the held target
	if _press != "":
		draw_rect(_rect(_press), C_PRESS, true)
	# honest 3D-absent note (drawn over the preview area when HIGHLIGHTS is tapped)
	if _note != "":
		var f := PMChrome.font("10")
		draw_rect(Rect2(110, 150, 420, 60), Color(0.03, 0.05, 0.12, 0.92), true)
		draw_rect(Rect2(110, 150, 420, 60), Color(0.4, 0.5, 0.7), false, 1.0)
		_wrap(f, Vector2(118, 156), 404, _note, Color(0.85, 0.9, 1.0), 12)


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


# ---- letterbox scaling ---------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
