extends Control
class_name PredefTacticsScreen
## PM98 PREDEF. TACTICS picker (the 10-formation overlay, FUN_0056f4c0) at pixel
## parity. Binding frame 140_154820 (picker open, resting); dynamic-selection
## witness 142_154825 (the "3-5-2" cell selected: a blue-grey bevel box with the
## name repainted WHITE). docs/re/tactics_subscreens_re.md.
##
## Static chrome = the REAL modal cut verbatim from frame 140
## (tools/re/build_tactics_subs_chrome_from_frames.py -> predef_chrome.png):
## the maroon "PREDEFINED TACTICS" title bar, the 5x2 grid of source-table
## thumbnails (3-4-3 3-5-2 4-3-3 4-4-2 5-3-2 / 5-4-1 4-2-4 5-2-3 4-5-1 3-3-3-1,
## == Tactics.FORMATION_ORDER) with their labels, and CANCEL. This screen draws
## ONLY the dynamic layer: a dim backdrop and the selection highlight over the
## CURRENT formation, plus the live hit-rects. It replaces the retired
## PMChrome-primitive picker that used to live inside TacticsBoardScreen.
##
## DIM: PM98 dims the board behind with a palette LUT (alert_box_re.md); that LUT
## is board-state-specific and cannot be applied to the live dynamic board inside
## _draw, so this uses an alpha dim — a documented approximation (identical to the
## retired inline picker's Color(0,0,0,0.5)). The MODAL itself is 100% frame-true.
##
## Native 640x480; scales to fit its parent (same transform as the board).

signal formation_picked(form: String)   # a thumbnail chosen
signal cancelled                         # CANCEL (or tap outside the modal)

const W := 640
const H := 480
const C_DIM := Color(0, 0, 0, 0.45)      # documented approximation of the palette dim

var _chrome: Texture2D
var _spec: Dictionary = {}
var _f12: Font
var _current := ""                       # the formation to mark selected
var _modal := Rect2()                    # chrome origin/size in design space
var _cells: Array = []                   # [{name, cell:Rect2, label:Rect2}]
var _cancel := Rect2()
var _sel_fill := Color(0.47, 0.47, 0.63)
var _hits: Array = []                     # [{r:Rect2, kind:String}]
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	_f12 = PMChrome.font("12")
	_chrome = load("res://art/screens/tactics/predef_chrome.png")
	_load_spec()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func _load_spec() -> void:
	var f := FileAccess.open("res://data/tactics_subs_chrome_samples.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return
	_spec = (d as Dictionary).get("predef", {})
	var mr: Array = _spec.get("modal_rect", [106, 158, 447, 249])
	_modal = Rect2(mr[0], mr[1], mr[2], mr[3])
	var o := _modal.position
	for c in _spec.get("cells", []):
		var cell: Array = c["cell"]
		var lab: Array = c["label"]
		_cells.append({
			"name": str(c["name"]),
			"cell": Rect2(o.x + cell[0], o.y + cell[1], cell[2], cell[3]),
			"label": Rect2(o.x + lab[0], o.y + lab[1], lab[2], lab[3]),
		})
	var cn: Array = _spec.get("cancel", [272 - mr[0], 378 - mr[1], 113, 24])
	_cancel = Rect2(o.x + cn[0], o.y + cn[1], cn[2], cn[3])
	var sf: Array = _spec.get("sel_fill", [120, 120, 160])
	_sel_fill = Color8(sf[0], sf[1], sf[2])


## `current` is the presently-applied formation (marked with the selection box).
func setup(current := "") -> void:
	_current = current
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	_scale = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	# 1) dim backdrop (documented approximation of PM98's palette dim).
	draw_rect(Rect2(0, 0, W, H), C_DIM, true)

	# 2) the frame-true modal.
	if _chrome != null:
		draw_texture(_chrome, _modal.position)

	# 3) dynamic selection layer + live hit-rects.
	for c in _cells:
		var nm: String = c["name"]
		if nm == _current:
			_draw_selection(c["label"], nm)
		_hit(c["cell"], "pick:%s" % nm)
	_hit(_cancel, "cancel")


## The selection box (frame 142): a blue-grey bevel over the label with the
## name repainted WHITE (dot-separated, matching the baked resting glyphs).
func _draw_selection(label: Rect2, name: String) -> void:
	PMChrome.bevel(self, label, _sel_fill, _sel_fill.lightened(0.25), _sel_fill.darkened(0.4))
	PMChrome.text(self, _f12, label.position.x, label.position.y + 1, _dotted(name),
		Color.WHITE, 12, 1, label.size.x)


func _dotted(name: String) -> String:
	return "·".join(name.split("-"))


func _hit(r: Rect2, kind: String) -> void:
	_hits.append({"r": r, "kind": kind})


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var pressed := (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed)
	if not pressed:
		return
	var d: Vector2 = (e.position - _origin) / _scale
	for h in _hits:
		if (h["r"] as Rect2).has_point(d):
			_activate(str(h["kind"]))
			return
	# a tap outside the modal cancels (matches the board's picker dismissal)
	if not _modal.has_point(d):
		cancelled.emit()


func _activate(kind: String) -> void:
	if kind == "cancel":
		cancelled.emit()
	elif kind.begins_with("pick:"):
		formation_picked.emit(kind.substr(5))
