extends Control
class_name SaveGameDialog
## PM98 SAVE GAME dialog (hub SAVE GAME button). Frame-baked 2026-07-18 from
## the live wine witnesses 51/52/53/55 of
## screenshots/wine-captures-2026-07-18-goalscorers/
## (tools/re/build_savegame_chrome_from_frames.py; docs/re/savegame_dialog_re.md).
##
## The card (140,102)-(499,377) mounts over the LIVE, UNDIMMED hub (witness 51
## vs 50: the only out-of-card diffs are the hub's own animated stadium and the
## captions the card covers). TEN save slots (GAME | PLAYER), not eight.
##
## Witnessed flow: tap a slot -> the WHOLE row (both cells) turns BLACK (52);
## typed text renders as white thin glyphs CENTRED in the GAME cell (53, "wk3"
## y147..153 = the proman8@11 face); SAVE commits; CANCEL closes (55). The
## wine original could not save ("The game can´t be saved." disk-space path),
## so the SUCCESS visual + populated-slot rendering are unwitnessed: the app
## closes on save and renders stored slots as white centred text per cell (the
## typed-name grammar) -- pattern-derived, documented.
##
## Typing = a real LineEdit over the armed GAME cell (the SeleccionScreen
## career-entry pattern: black stylebox, centred white text, so the mobile
## keyboard works); caret transparent (witness 52/53 shows none).

signal save_requested(slot: int, name: String)   # SAVE with a slot armed
signal closed                                     # CANCEL (or after save)

const W := 640
const H := 480
const CARD_XY := Vector2(140, 102)

const ROW0_Y := 144
const ROW_PITCH := 16
const ROW_FILL_H := 12
const N_SLOTS := 10
const GAME_CELL := [148, 350]      # x0, x1 exclusive
const PLAYER_CELL := [351, 489]

const R_SAVE := Rect2(377, 306, 113, 25)
const R_CANCEL := Rect2(377, 346, 113, 25)

const C_ARMED := Color8(0, 0, 0)             # armed GAME cell (witness 52)
const C_ARMED_PLAYER := Color8(59, 85, 130)  # armed PLAYER cell: darkened steel
const C_TEXT := Color8(255, 255, 255)
const C_PRESS := Color(1, 1, 1, 0.20)

var _slots: Array = []             # N_SLOTS entries: {} or {game, player}
var _player_name := ""             # manager name stamped into the PLAYER cell
var _armed := -1
var _press := ""

var _f8: Font
var _dialog: Texture2D
var _edit: LineEdit


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_dialog = load("res://art/screens/savegame/dialog.png")
	if _slots.is_empty():
		for i in N_SLOTS:
			_slots.append({})
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_edit = LineEdit.new()
	_edit.max_length = 24
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.add_theme_font_override("font", _f8)
	_edit.add_theme_font_size_override("font_size", 11)
	_edit.add_theme_color_override("font_color", C_TEXT)
	_edit.add_theme_color_override("caret_color", Color(0, 0, 0, 0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	for st in ["normal", "focus", "read_only"]:
		_edit.add_theme_stylebox_override(st, sb)
	_edit.visible = false
	add_child(_edit)
	resized.connect(_reposition_edit)
	gui_input.connect(_on_input)
	queue_redraw()


## slots: N_SLOTS metadata entries ({} = empty, else {game, player});
## player_name: the manager name written beside a newly saved game.
func setup(slots: Array, player_name: String) -> void:
	_slots = []
	for i in N_SLOTS:
		_slots.append(slots[i] if i < slots.size() and slots[i] is Dictionary else {})
	_player_name = player_name
	_armed = -1
	if _edit != null:      # setup may land before _ready under a script host
		_edit.visible = false
	queue_redraw()


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()


func _row_rect(i: int) -> Rect2:
	return Rect2(GAME_CELL[0], ROW0_Y + ROW_PITCH * i,
		PLAYER_CELL[1] - GAME_CELL[0], ROW_FILL_H)


func _reposition_edit() -> void:
	if not _edit.visible:
		return
	var s := _scale()
	var o := _origin(s)
	# +1px: lands the glyphs on the witnessed rows (53: "wk3" y147..153)
	var r := Rect2(GAME_CELL[0], ROW0_Y + ROW_PITCH * _armed + 1,
		GAME_CELL[1] - GAME_CELL[0], ROW_FILL_H - 1)
	_edit.position = o + r.position * s
	_edit.size = r.size * s


# ---- input ----------------------------------------------------------------

func _hit(d: Vector2) -> String:
	for i in N_SLOTS:
		if _row_rect(i).has_point(d):
			return "slot:%d" % i
	if R_SAVE.has_point(d):
		return "save"
	if R_CANCEL.has_point(d):
		return "cancel"
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	var parts := was.split(":")
	match parts[0]:
		"slot":
			_armed = int(parts[1])
			_edit.text = str(_slots[_armed].get("game", ""))
			_edit.visible = true
			_reposition_edit()
			_edit.grab_focus()
		"save":
			if _armed >= 0:
				save_requested.emit(_armed, _edit.text.strip_edges())
				closed.emit()
		"cancel":
			closed.emit()
	queue_redraw()


# ---- drawing --------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _dialog != null:
		draw_texture(_dialog, CARD_XY)
	for i in N_SLOTS:
		var top := ROW0_Y + ROW_PITCH * i
		if i == _armed:
			# witnessed 52: GAME cell black (the LineEdit also paints it),
			# PLAYER cell darkened steel
			draw_rect(Rect2(GAME_CELL[0], top, GAME_CELL[1] - GAME_CELL[0],
				ROW_FILL_H), C_ARMED, true)
			draw_rect(Rect2(PLAYER_CELL[0], top, PLAYER_CELL[1] - PLAYER_CELL[0],
				ROW_FILL_H), C_ARMED_PLAYER, true)
			continue
		var meta: Dictionary = _slots[i]
		if meta.is_empty():
			continue
		PMChrome.text(self, _f8, GAME_CELL[0], top + 3, str(meta.get("game", "")),
			C_TEXT, 11, 1, float(GAME_CELL[1] - GAME_CELL[0]))
		PMChrome.text(self, _f8, PLAYER_CELL[0], top + 3, str(meta.get("player", "")),
			C_TEXT, 11, 1, float(PLAYER_CELL[1] - PLAYER_CELL[0]))
	for kr in [["save", R_SAVE], ["cancel", R_CANCEL]]:
		if _press == str(kr[0]):
			draw_rect(kr[1], C_PRESS, true)
