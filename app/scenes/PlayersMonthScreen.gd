extends Control
class_name PlayersMonthScreen
## PM98 PLAYERS OF THE MONTH — the second monthly-award sheet, raised straight
## after MANAGERS OF THE MONTH (witnessed 2026-07-18; frame `77_after_motm.png`).
##
## Chrome = the real frame's panel with ONLY the caption band, the division
## sub-header and the 20 TEAM|PLAYER cells cleared
## (tools/re/build_awards_chrome_from_frames.py -> art/screens/awards/players.png).
## The four division tab faces are cut verbatim from the same frame; PREMIER is the
## witnessed SELECTED face and the other three are the witnessed UNSELECTED faces,
## so a tab swap redraws the selected one from PREMIER's own pixels with its own
## label kept — flagged in docs/re/awards_screens_re.md as the one un-witnessed cut.
##
## Rows: TEAM right-aligned in the light cell, PLAYER left-aligned in the navy
## cell, ten per column, the division's clubs in alphabetical order (the frame's
## own order: Arsenal, Aston Villa, Barnsley, ... down column 1 then column 2).

signal ok_pressed

const W := 640
const H := 480

const PANEL := Vector2i(24, 92)
const CAPTION_Y := Vector2i(94, 115)
const SUBHDR_Y := Vector2i(117, 137)
const ROW_Y0 := 153
const ROW_PITCH := 16
const ROW_H := 12
const ROWS := 10
const COLS := [                    # (team x0,x1, player x0,x1)
	[33, 180, 181, 311],
	[329, 476, 477, 607],
]
const TAB_Y := Vector2i(350, 373)
const TABS := [
	{"key": 1, "label": "premier", "x": Vector2i(33, 147)},
	{"key": 2, "label": "first", "x": Vector2i(152, 266)},
	{"key": 3, "label": "second", "x": Vector2i(271, 386)},
	{"key": 4, "label": "third", "x": Vector2i(391, 506)},
]
const OK_X := Vector2i(511, 606)

const C_TEAM := Color8(0, 0, 0)              # black on the light TEAM cell
const C_PLAYER := Color8(255, 255, 255)      # white on the navy PLAYER cell
const C_SUB := Color8(0, 0, 0)               # the sub-header's division name
const DIV_NAMES := {1: "PREMIER LEAGUE", 2: "FIRST DIVISION",
	3: "SECOND DIVISION", 4: "THIRD DIVISION"}

var _chrome: Texture2D
var _tabs: Dictionary = {}       # label -> Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _month := ""
var _by_tier: Dictionary = {}    # tier -> Array of {club, player}
var _tier := 1
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/awards/players.png")
	for k in ["premier", "first", "second", "third", "ok"]:
		var p := "res://art/screens/awards/tab_%s.png" % k
		_tabs[k] = load(p) if ResourceLoader.exists(p) else null
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## month: "AUGUST"; by_tier: {tier -> [{club, player}, ...]} (any length; the
## sheet shows the first 20 in the frame's two columns of ten).
func setup(month: String, by_tier: Dictionary, tier := 1) -> void:
	_month = month
	_by_tier = by_tier
	_tier = tier if by_tier.has(tier) else int(by_tier.keys()[0]) if not by_tier.is_empty() else 1
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _hit(d: Vector2) -> String:
	if d.y < TAB_Y.x or d.y > TAB_Y.y:
		return ""
	if d.x >= OK_X.x and d.x <= OK_X.y:
		return "ok"
	for t in TABS:
		var x: Vector2i = t["x"]
		if d.x >= x.x and d.x <= x.y:
			return "tab%d" % int(t["key"])
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	if was != "" and was == _hit(d):
		if was == "ok":
			ok_pressed.emit()
		else:
			var t := int(was.substr(3))
			if _by_tier.has(t):
				_tier = t
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2(PANEL))
	ManagersMonthScreen.draw_caption(self, "PLAYERS OF THE MONTH (%s)" % _month,
		CAPTION_Y.x, CAPTION_Y.y, PANEL.x + 2, 613, _f14)
	# the selected division's name, centred on the light-blue sub-header band
	var sub := str(DIV_NAMES.get(_tier, ""))
	if sub != "" and _f12 != null:
		var w := _f12.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_f12, Vector2(int(319 - w * 0.5), SUBHDR_Y.x + 3 + _f12.get_ascent(13)),
			sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_SUB)
	var rows: Array = _by_tier.get(_tier, [])
	for i in mini(rows.size(), ROWS * COLS.size()):
		@warning_ignore("integer_division")
		var col: int = i / ROWS
		var r: int = i % ROWS
		var y := ROW_Y0 + ROW_PITCH * r
		var c: Array = COLS[col]
		var row: Dictionary = rows[i]
		_txt_right(_f10, int(c[1]) - 4, y + 1,
			PMChrome.title_case_name(str(row.get("club", ""))), C_TEAM, int(c[1]) - int(c[0]) - 8)
		_txt(_f10, int(c[2]) + 4, y + 1,
			PMChrome.title_case_name(str(row.get("player", ""))), C_PLAYER,
			int(c[3]) - int(c[2]) - 8)
	# division tabs: the selected one wears PREMIER's witnessed selected face
	for t in TABS:
		var x: Vector2i = t["x"]
		var key: String = str(t["label"])
		var tex: Texture2D = _tabs.get(key)
		if int(t["key"]) == _tier and key != "premier" and _tabs.get("premier") != null:
			# selected face is only witnessed on PREMIER: draw its glow, then this
			# tab's own resting label over it (documented approximation).
			draw_texture_rect_region(_tabs["premier"],
				Rect2(x.x, TAB_Y.x, x.y - x.x, TAB_Y.y - TAB_Y.x),
				Rect2(0, 0, mini(114, x.y - x.x), TAB_Y.y - TAB_Y.x))
		elif tex != null:
			draw_texture(tex, Vector2(x.x, TAB_Y.x))
		if _press == "tab%d" % int(t["key"]):
			draw_rect(Rect2(x.x, TAB_Y.x, x.y - x.x, TAB_Y.y - TAB_Y.x), Color(1, 1, 1, 0.18), true)
	if _tabs.get("ok") != null:
		draw_texture(_tabs["ok"], Vector2(OK_X.x, TAB_Y.x))
	if _press == "ok":
		draw_rect(Rect2(OK_X.x, TAB_Y.x, OK_X.y - OK_X.x, TAB_Y.y - TAB_Y.x),
			Color(1, 1, 1, 0.2), true)


func _fit(f: Font, t: String, maxw: int) -> int:
	var sz := 11
	while f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > float(maxw) and sz > 7:
		sz -= 1
	return sz


func _txt(f: Font, x: int, y_top: int, t: String, col: Color, maxw: int) -> void:
	if f == null or t == "":
		return
	var sz := _fit(f, t, maxw)
	draw_string(f, Vector2(x, y_top + f.get_ascent(sz)), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _txt_right(f: Font, x_right: int, y_top: int, t: String, col: Color, maxw: int) -> void:
	if f == null or t == "":
		return
	var sz := _fit(f, t, maxw)
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x_right - w, y_top + f.get_ascent(sz)), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)
