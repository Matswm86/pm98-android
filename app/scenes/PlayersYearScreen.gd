extends Control
class_name PlayersYearScreen
## PM98 PLAYERS OF THE YEAR — step 6 of the original's season-end sequence (REFRUN R15),
## baked from `tools/re/refs/season-end-2026-07-25/23_players_of_the_year.png`.
##
## It is NOT the PLAYERS OF THE MONTH sheet. Its title lives in the top barra rather than
## in a caption band inside the panel, its panel is its own size, and its four division
## tabs are a 2x2 GRID over a CONTINUE button instead of a single row ending in OK. Only
## the row grid (ten rows, two TEAM|PLAYER column pairs) happens to share the month
## sheet's pitch — and even there the columns sit at their own x.
##
## One award per CLUB, in the division's own alphabetical club order — 92 awards across
## the four tabs, which is what the reference run counted. A club that never scored shows
## an EMPTY player cell rather than a borrowed name.
##
## Chrome = the frame with only the division sub-header and the 20 cells cleared; the
## barra, the panel, the TEAM / PLAYER headers, the tabs and CONTINUE are the original's
## own pixels. The four tab faces are cut verbatim, and PREMIER is the only SELECTED
## face the frame witnesses — selecting another tab therefore borrows PREMIER's glow and
## keeps that tab's own label, exactly the documented approximation PlayersMonthScreen
## already carries (docs/re/awards_screens_re.md).
##
## Chrome: tools/re/build_seasonend_year_chrome_from_frames.py
## Render-diff: tools/re/diff_seasonend_year_parity.py

signal continue_pressed

const W := 640
const H := 480

## Text, solved with tools/re/probe_text_anchor.py at ZERO differing pixels against the
## frame. The rows are MICRO8 -- a WINFONTS face the app did not ship until this screen
## needed it, and the same face the already-shipped PLAYERS OF THE MONTH sheet's rows are
## drawn in (its identical "Arsenal" bitmap proves it), so that sheet's scaled-proman10
## rows are wrong by the same measurement.
const ROW_Y0 := 127
const ROW_PITCH := 16
const ROWS := 10
## Per column: TEAM's pen ENDS here (right-aligned), PLAYER's pen STARTS here.
const COLS := [[180, 186], [476, 482]]
const ROW_PEN_DY := 1
const SUBHDR_PEN_TOP := 95
const SUBHDR_FIELD_SUM := 640          # the band's caption centres on the full width
const TABS := [
	{"tier": 1, "rect": Rect2(380, 345, 112, 25)},
	{"tier": 2, "rect": Rect2(502, 345, 112, 25)},
	{"tier": 3, "rect": Rect2(380, 379, 112, 25)},
	{"tier": 4, "rect": Rect2(502, 379, 112, 25)},
]
const BTN_CONTINUE := Rect2(502, 426, 112, 25)

const C_TEAM := Color8(0, 0, 0)
const C_PLAYER := Color8(255, 255, 255)
const C_SUB := Color8(255, 255, 255)
const DIV_NAMES := {1: "PREMIER LEAGUE", 2: "FIRST DIVISION",
	3: "SECOND DIVISION", 4: "THIRD DIVISION"}

var _chrome: Texture2D
var _tabs: Dictionary = {}
var _page: Texture2D          # micro8 — the row face
var _g: Dictionary = {}
var _page12: Texture2D        # proman12 — the division sub-header
var _g12: Dictionary = {}
var _by_tier: Dictionary = {}
var _tier := 1
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/seasonend/players_year.png")
	for t in [1, 2, 3, 4]:
		var p := "res://art/screens/seasonend/py_tab_%d.png" % t
		_tabs[t] = load(p) if ResourceLoader.exists(p) else null
	_page = PMFont.page_texture("micro8")
	_g = PMFont.chars("micro8")
	_page12 = PMFont.page_texture("proman12")
	_g12 = PMFont.chars("proman12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## by_tier: Career.players_of_year() — {tier: [{club, club_id, player}, ...]}
func setup(by_tier: Dictionary, tier := 1) -> void:
	_by_tier = by_tier
	_tier = tier if by_tier.has(tier) else (int(by_tier.keys()[0]) if not by_tier.is_empty() else 1)
	queue_redraw()


## Park the sheet on one division (render-diff harness / a test).
func show_tier(t: int) -> void:
	if _by_tier.has(t):
		_tier = t
		queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _hit(d: Vector2) -> String:
	if BTN_CONTINUE.has_point(d):
		return "continue"
	for t in TABS:
		if (t["rect"] as Rect2).has_point(d):
			return "tab%d" % int(t["tier"])
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var s := _scale()
	var d: Vector2 = (e.position - _origin(s)) / s
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	if was != "" and was == _hit(d):
		if was == "continue":
			continue_pressed.emit()
		else:
			show_tier(int(was.substr(3)))
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	# the selected division's name, centred on the black sub-header band
	var sub := str(DIV_NAMES.get(_tier, ""))
	if sub != "":
		@warning_ignore("integer_division")
		var pen := (SUBHDR_FIELD_SUM - _advance(_g12, sub)) / 2
		_blit(_page12, _g12, pen, SUBHDR_PEN_TOP, sub, C_SUB)
	var rows: Array = _by_tier.get(_tier, [])
	for i in mini(rows.size(), ROWS * COLS.size()):
		@warning_ignore("integer_division")
		var col: int = i / ROWS
		var r: int = i % ROWS
		var y := ROW_Y0 + ROW_PITCH * r + ROW_PEN_DY
		var c: Array = COLS[col]
		var row: Dictionary = rows[i]
		var club := PMChrome.title_case_name(str(row.get("club", "")))
		_blit(_page, _g, int(c[0]) - _advance(_g, club), y, club, C_TEAM)
		_blit(_page, _g, int(c[1]), y,
			PMChrome.title_case_name(str(row.get("player", ""))), C_PLAYER)
	# the selected tab wears PREMIER's witnessed lit face under its own resting label
	for t in TABS:
		var rect: Rect2 = t["rect"]
		var tier := int(t["tier"])
		var tex: Texture2D = _tabs.get(tier)
		if tier == _tier and tier != 1 and _tabs.get(1) != null:
			draw_texture(_tabs[1], rect.position)
		elif tex != null:
			draw_texture(tex, rect.position)
		if _press == "tab%d" % tier:
			draw_rect(rect, Color(1, 1, 1, 0.18), true)
	if _press == "continue":
		draw_rect(BTN_CONTINUE, Color(1, 1, 1, 0.2), true)


static func _advance(glyphs: Dictionary, t: String) -> int:
	var w := 0
	for i in t.length():
		w += int((glyphs.get(t.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


func _blit(page: Texture2D, glyphs: Dictionary, x: int, y_top: int, t: String,
		col: Color) -> void:
	if page == null:
		return
	var pen := x
	for i in t.length():
		var g: Dictionary = glyphs.get(t.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])
