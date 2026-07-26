extends Control
class_name KnockoutScreen
## RESULTS -> any cup at a KNOCKOUT phase, rebuilt frame-true.
##
## The original does not have "a knockout screen": it switches presentation with the size
## of the round and the column set with the competition (`docs/re/knockout_views_re.md`,
## five layouts witnessed 2026-07-26). This scene is the LIST form -- the compact 15 px
## row table every round of nine ties or more lands in, in both column sets:
##
##     European   1ST LEG   2ND LEG   AGGR.
##     domestic   RES.      REPLAY
##
## Everything static is the original's own pixels (`art/screens/knockout/`, baked by
## `tools/re/build_knockout_chrome_from_frames.py` from the witnessed frames); everything
## a career fills is redrawn here at the measured anchors.
##
## Geometry + inks: docs/re/knockout_views_re.md "Geometry banked 2026-07-26".

signal back_pressed
signal phase_changed(delta: int)
signal competition_selected(key: String)

const W := 640
const H := 480

# ---- the competition rail --------------------------------------------------------
const COMPS := ["facup", "cocacola", "charity", "euro", "cwc", "uefa", "supercup",
	"intercont"]
const RAIL_XY := Vector2(500, 110)
const CHIP_X := 506
const CHIP_W := 116
const CHIP_H := 29
const CHIP_TOP := {"facup": 118, "cocacola": 145, "charity": 172, "euro": 209,
	"cwc": 236, "uefa": 263, "supercup": 290, "intercont": 317}

# ---- the compact list panel ------------------------------------------------------
const PANEL_X0 := 6
const PANEL_X1 := 477
const HDR_XY := Vector2(6, 125)          # the baked panel top (border + title band)
const BODY_TOP := 154
const MAX_ROWS := 16                     # the panel's full height, beyond which it scrolls
## Below this the original switches to a different layout entirely -- the kit list at 5-8
## ties, the bracket at 4, two cards at 2, the trophy view at 1. Those are measured in
## docs/re/knockout_views_re.md but not built, so a caller checks this before raising the
## list.
const MIN_LIST_TIES := 9
const FULL_BODY_H := 255                 # witnessed at 16 rows (bottom border y408..410)
const SHORT_ROW_H := 15                  # witnessed at 15 rows (bottom border y378..380)
const BOTTOM_BORDER := 3

# Column cells, inclusive x spans. The gaps between them are the panel's own black rules.
const COLS_EURO := [[8, 158], [161, 309], [312, 365], [367, 420], [422, 475]]
const COLS_DOM := [[8, 185], [188, 363], [365, 418], [420, 473]]

# Row grounds, light row then dark row: the two name cells, the score cells, and the LAST
# score cell, which is a shade darker in both column sets.
const BG_NAME := [Color8(120, 140, 160), Color8(100, 120, 140)]
const BG_SCORE := [Color8(160, 160, 200), Color8(120, 120, 160)]
const BG_LAST := [Color8(140, 140, 180), Color8(100, 100, 140)]
# The manager's OWN tie replaces the alternating grounds outright, and takes a light ink
# instead of the dark one (witnessed on the F.A. Cup R3 draw, Peterborough v Bolton W).
const BG_MINE := [Color8(60, 80, 100), Color8(59, 85, 130), Color8(30, 52, 98)]
const C_MINE := Color8(140, 160, 180)
const C_BLACK := Color8(0, 0, 0)

# Text anchors, as offsets into the cell they live in (identical in both column sets).
const NAME_RIGHT_DX := -4                # home name: pen END at cell_x1 - 5
const NAME_LEFT_DX := 4                  # away name: pen at cell_x0 + 4
const NAME_TOP_DY := 2
const SCORE_A_END_DX := 21               # first number: pen END at cell_x0 + 20
const SCORE_DASH_DX := 24
const SCORE_B_DX := 31
const SCORE_TOP_DY := 2

const C_OUT := Color8(42, 63, 85)        # the eliminated club and its goals
const C_THROUGH := Color8(255, 223, 0)   # the club going through, and its goals

# ---- the scrollbar ---------------------------------------------------------------
const SCROLL_XY := Vector2(478, 125)
const SCROLL_TROUGH := [172, 394]        # its interior, in screen rows

# ---- the phase paginator ---------------------------------------------------------
const C_LABEL := Color8(100, 100, 140)
const LABEL_TOP_DY := 5                  # the label's pen top inside its plate
const PAGER_BTN := Vector2(23, 21)

const R_RETURN := Rect2(504, 433, 116, 29)
const C_PRESS := Color(1, 1, 1, 0.2)

# the shared barra grammar, as ResultsScreen and EuroGroupScreen draw it
const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 13), "hdr_status": Vector2(536, 10)}
const HDR_STATUS_W := 77

var _desktop: Texture2D
var _bands: Dictionary = {}              # "<comp>_<fam>" -> {tex, meta}
var _band_meta: Dictionary = {}
var _chips: Dictionary = {}
var _hdr: Dictionary = {}                # "euro"/"dom" -> the panel top strip
var _pager: Dictionary = {}
var _scroll_col: Texture2D
var _scroll_thumb: Texture2D
var _patches: Dictionary = {}
var _page_cal: Texture2D
var _page_p10: Texture2D
var _g_cal: Dictionary = {}
var _g_p10: Dictionary = {}
var _f8: Font
var _fcal: Font

var _header: Dictionary = {}
var _comp := "euro"
var _label := ""
var _euro_cols := true
var _ties: Array = []                    # [{home, away, winner, cells}]
var _offset := 0
var _has_prev := false
var _has_next := false
var _press := ""


func _ready() -> void:
	_desktop = _tex("res://art/screens/knockout/desktop.png")
	for c in COMPS:
		_chips[c] = _tex("res://art/screens/knockout/rail_%s.png" % c)
	for key in ["euro", "dom"]:
		_hdr[key] = _tex("res://art/screens/knockout/list_hdr_%s.png" % key)
	for key in ["left_on", "right_on", "left_off_p0", "left_off_p1", "right_off_p0",
			"right_off_p1"]:
		_pager[key] = _tex("res://art/screens/knockout/pager_%s.png" % key)
	_scroll_col = _tex("res://art/screens/knockout/scroll_col.png")
	_scroll_thumb = _tex("res://art/screens/knockout/scroll_thumb_tile.png")
	_band_meta = _load_json("res://art/screens/knockout/bands.json")
	for key in _band_meta:
		_bands[key] = _tex("res://art/screens/knockout/band_%s.png" % key)
	for k in HDR_PATCH_XY:
		_patches[k] = _tex("res://art/screens/results/%s.png" % k)
	_page_cal = PMFont.page_texture("calend12")
	_page_p10 = PMFont.page_texture("proman10")
	_g_cal = PMFont.chars("calend12")
	_g_p10 = PMFont.chars("proman10")
	_f8 = PMChrome.font("8")
	_fcal = PMChrome.font("calend12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


static func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func _load_json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}


## `ties` is the phase's ties in draw order, each
##     {home: String, away: String, winner: int (0 home / 1 away / -1 undecided),
##      cells: Array of [String, String] -- one per column, "" for an empty cell}
## `euro_cols` picks 1ST LEG / 2ND LEG / AGGR. over RES. / REPLAY.
func setup(header: Dictionary, comp: String, label: String, euro_cols: bool,
		ties: Array, has_prev: bool, has_next: bool, offset := 0) -> void:
	_header = header
	_comp = comp if comp in COMPS else "euro"
	_label = label
	_euro_cols = euro_cols
	_ties = ties
	_has_prev = has_prev
	_has_next = has_next
	_offset = clampi(offset, 0, maxi(0, ties.size() - MAX_ROWS))
	queue_redraw()


func cols() -> Array:
	return COLS_EURO if _euro_cols else COLS_DOM


func visible_rows() -> int:
	return mini(_ties.size(), MAX_ROWS)


## The panel's body height. Witnessed at 15 rows (225) and at 16 (255); between them the
## rows are 15 px and at the full height they are the 255/16 the original's own separator
## positions imply. A count above 16 scrolls at the full height.
func body_h() -> int:
	var n := visible_rows()
	return FULL_BODY_H if n >= MAX_ROWS else n * SHORT_ROW_H


## The y of the black rule UNDER row `i` (there is none under the last row).
func _sep_y(i: int) -> int:
	var n := visible_rows()
	@warning_ignore("integer_division")
	return BODY_TOP + ((i + 1) * body_h()) / n - 1


func _row_span(i: int) -> Vector2i:
	var n := visible_rows()
	var top := BODY_TOP if i == 0 else _sep_y(i - 1) + 1
	var bot := (_sep_y(i) - 1) if i < n - 1 else BODY_TOP + body_h() - 2
	return Vector2i(top, bot)


# ---- layout ----------------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / float(W), size.y / float(H))


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	if s <= 0.0:
		return Vector2(-1, -1)
	return (p - _origin(s)) / s


func _band_key() -> String:
	return "%s_list" % _comp


func _pager_rects() -> Array:
	var m: Dictionary = _band_meta.get(_band_key(), {})
	if m.is_empty():
		return []
	var l: Array = m.get("left", [0, 0])
	var r: Array = m.get("right", [0, 0])
	return [Rect2(int(l[0]), int(l[1]), PAGER_BTN.x, PAGER_BTN.y),
		Rect2(int(r[0]), int(r[1]), PAGER_BTN.x, PAGER_BTN.y)]


func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d):
		return "return"
	var pr := _pager_rects()
	if pr.size() == 2:
		if (pr[0] as Rect2).has_point(d) and _has_prev:
			return "prev"
		if (pr[1] as Rect2).has_point(d) and _has_next:
			return "next"
	for c in COMPS:
		if Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H).has_point(d):
			return "comp:%s" % c
	return ""


func _on_input(e: InputEvent) -> void:
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var pressed := (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed)
	var released := (e is InputEventMouseButton and not (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and not (e as InputEventScreenTouch).pressed)
	if not (pressed or released):
		return
	var pos: Vector2 = (e as InputEventMouse).position if e is InputEventMouse \
		else (e as InputEventScreenTouch).position
	var t := _target_at(_to_design(pos))
	if pressed:
		_press = t
		queue_redraw()
		return
	_press = ""
	queue_redraw()
	if t == "":
		return
	if t == "return":
		back_pressed.emit()
	elif t == "prev":
		phase_changed.emit(-1)
	elif t == "next":
		phase_changed.emit(1)
	elif t.begins_with("comp:"):
		competition_selected.emit(t.substr(5))


# ---- text ------------------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((glyphs.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


func _txt(page: Texture2D, glyphs: Dictionary, x: int, y_top: int, s: String,
		col: Color) -> void:
	if page == null:
		return
	var pen := x
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])


@warning_ignore("integer_division")
func _txt_mid(page: Texture2D, glyphs: Dictionary, field_sum: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, (field_sum - _advance(glyphs, s)) / 2, y_top, s, col)


func _txt_right(page: Texture2D, glyphs: Dictionary, pen_end: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, pen_end - _advance(glyphs, s), y_top, s, col)


func _gdi_text(f: Font, sz: int, s: String, span: int, y_top: int, ink: Color) -> void:
	if f == null or s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (span - w) / 2
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)


# ---- draw ------------------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _desktop != null:
		draw_texture_rect(_desktop, Rect2(0, 0, W, H), false)
	_draw_header()
	_draw_band()
	_draw_panel()
	var rail: Texture2D = _chips.get(_comp)
	if rail != null:
		draw_texture(rail, RAIL_XY)
	if _press != "":
		var r := _press_rect()
		if r.size.x > 0.0:
			draw_rect(r, C_PRESS, true)


func _press_rect() -> Rect2:
	if _press == "return":
		return R_RETURN
	var pr := _pager_rects()
	if _press == "prev" and pr.size() == 2:
		return pr[0]
	if _press == "next" and pr.size() == 2:
		return pr[1]
	if _press.begins_with("comp:"):
		var c := _press.substr(5)
		if CHIP_TOP.has(c):
			return Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H)
	return Rect2()


func _draw_header() -> void:
	for k in HDR_PATCH_XY:
		var tex: Texture2D = _patches.get(k)
		if tex == null:
			continue
		if k == "hdr_status":
			draw_texture_rect_region(tex,
				Rect2(HDR_PATCH_XY[k], Vector2(HDR_STATUS_W, tex.get_height())),
				Rect2(0, 0, HDR_STATUS_W, tex.get_height()))
		else:
			draw_texture(tex, HDR_PATCH_XY[k])
	_gdi_text(_f8, 11, str(_header.get("top", "")), PMChrome.HDR_NAME_TOP["S"],
		PMChrome.HDR_NAME_TOP["y"], Color(0, 0, 0))
	_gdi_text(_f8, 11, str(_header.get("bottom", "")), PMChrome.HDR_NAME_BOT["S"],
		PMChrome.HDR_NAME_BOT["y"], Color(1, 1, 1))
	var cid := int(_header.get("club_id", -1))
	var patch: Texture2D = null
	if cid == 40 and ResourceLoader.exists("res://art/kits/header/40.png"):
		patch = load("res://art/kits/header/40.png")
	if patch != null:
		draw_texture(patch, PMChrome.HDR_MGR_PATCH_XY)
	else:
		var nk := PMChrome.nano_kit(cid)
		if nk != null:
			draw_texture(nk, PMChrome.HDR_MGR_NANO_XY)
	for line in PMChrome.HDR_CAL_LINES:
		_gdi_text(_f8, 11, str(_header.get(line["key"], "")), PMChrome.HDR_CAL_S,
			line["y"], line["ink"])
	_gdi_text(_fcal, 15, str(_header.get("status_top", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_TOP_Y, Color(0, 0, 0))
	_gdi_text(_fcal, 15, str(_header.get("status_bottom", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_BOT_Y, Color(1, 1, 1))


## The competition band: the trophy, the name plate and the paginator, cut whole from that
## competition's own frame (the band's PLACEMENT is not a rule this port can state -- see
## the baker's header), with only the phase label and the arrow faces redrawn.
func _draw_band() -> void:
	var key := _band_key()
	var tex: Texture2D = _bands.get(key)
	var m: Dictionary = _band_meta.get(key, {})
	if tex == null or m.is_empty():
		return
	var org: Array = m.get("origin", [0, 0])
	draw_texture(tex, Vector2(int(org[0]), int(org[1])))
	var plate: Array = m.get("plate", [0, 0, 0, 0])
	_txt_mid(_page_p10, _g_p10, int(plate[0]) + int(plate[2]) + 1,
		int(plate[1]) + LABEL_TOP_DY, _label, C_LABEL)
	var l: Array = m.get("left", [0, 0])
	var r: Array = m.get("right", [0, 0])
	# A disabled arrow's triangle is dithered against absolute screen parity, so the face
	# is chosen by (x + y) & 1 -- both phases are the original's own (see the baker).
	var lt: Texture2D = _pager.get("left_on" if _has_prev
		else "left_off_p%d" % ((int(l[0]) + int(l[1])) & 1))
	var rt: Texture2D = _pager.get("right_on" if _has_next
		else "right_off_p%d" % ((int(r[0]) + int(r[1])) & 1))
	if lt != null:
		draw_texture(lt, Vector2(int(l[0]), int(l[1])))
	if rt != null:
		draw_texture(rt, Vector2(int(r[0]), int(r[1])))


func _draw_panel() -> void:
	var hdr: Texture2D = _hdr.get("euro" if _euro_cols else "dom")
	if hdr != null:
		draw_texture(hdr, HDR_XY)
	var n := visible_rows()
	if n <= 0:
		return
	var cs := cols()
	var bh := body_h()
	var last_x: int = int((cs[cs.size() - 1] as Array)[1])

	# the panel's own rules: the two side borders, the column rules, the row rules and the
	# 3 px foot -- all black, all full-bleed across the panel.
	draw_rect(Rect2(PANEL_X0, BODY_TOP, PANEL_X1 - PANEL_X0 + 1, bh), C_BLACK, true)
	for i in n:
		var span := _row_span(i)
		var dark := i % 2
		var mine := bool((_ties[i + _offset] as Dictionary).get("mine", false))
		for j in cs.size():
			var c: Array = cs[j]
			var col: Color = BG_MINE[0] if mine else BG_NAME[dark]
			if j == cs.size() - 1:
				col = BG_MINE[2] if mine else BG_LAST[dark]
			elif j >= 2:
				col = BG_MINE[1] if mine else BG_SCORE[dark]
			draw_rect(Rect2(int(c[0]), span.x, int(c[1]) - int(c[0]) + 1,
				span.y - span.x + 1), col, true)
	# the foot: the last two of the three border rows sit BELOW the body rect above
	draw_rect(Rect2(PANEL_X0, BODY_TOP + bh - 1, PANEL_X1 - PANEL_X0 + 1, BOTTOM_BORDER),
		C_BLACK, true)
	if last_x < PANEL_X1:
		draw_rect(Rect2(last_x + 1, BODY_TOP, PANEL_X1 - last_x, bh), C_BLACK, true)

	for i in n:
		_draw_row(i, cs)
	_draw_scroll()


func _draw_row(i: int, cs: Array) -> void:
	var tie: Dictionary = _ties[i + _offset]
	var span := _row_span(i)
	var winner := int(tie.get("winner", -1))
	var plain: Color = C_MINE if bool(tie.get("mine", false)) else C_OUT
	var home_cell: Array = cs[0]
	var away_cell: Array = cs[1]
	_txt_right(_page_p10, _g_p10, int(home_cell[1]) + NAME_RIGHT_DX,
		span.x + NAME_TOP_DY, str(tie.get("home", "")),
		C_THROUGH if winner == 0 else plain)
	_txt(_page_p10, _g_p10, int(away_cell[0]) + NAME_LEFT_DX,
		span.x + NAME_TOP_DY, str(tie.get("away", "")),
		C_THROUGH if winner == 1 else plain)

	var cells: Array = tie.get("cells", [])
	for j in mini(cells.size(), cs.size() - 2):
		var pair: Array = cells[j]
		if pair.is_empty() or (str(pair[0]) == "" and str(pair[1]) == ""):
			continue
		var c: Array = cs[j + 2]
		var x0: int = int(c[0])
		var top: int = span.x + SCORE_TOP_DY
		# The club going through has ITS goals inked yellow in every cell. The second leg
		# is printed with the sides swapped (the leg-2 host first), so the marked position
		# is the other one there -- witnessed on 15 rows of 06_euroleague_round1_played.
		var mark := -1 if winner < 0 else (1 - winner if _is_second_leg(j) else winner)
		_txt_right(_page_p10, _g_p10, x0 + SCORE_A_END_DX, top, str(pair[0]),
			C_THROUGH if mark == 0 else plain)
		_txt(_page_p10, _g_p10, x0 + SCORE_DASH_DX, top, "-", plain)
		_txt(_page_p10, _g_p10, x0 + SCORE_B_DX, top, str(pair[1]),
			C_THROUGH if mark == 1 else plain)


func _is_second_leg(col_index: int) -> bool:
	return _euro_cols and col_index == 1


## The scrollbar only exists when the list is longer than the panel. Its arrows and trough
## are the original's own; the thumb is drawn proportional to the window -- the two frames
## in hand differ only in its LENGTH, so the tracking rule itself is an inference and is
## recorded as one in docs/re/knockout_views_re.md.
func _draw_scroll() -> void:
	if _ties.size() <= MAX_ROWS or _scroll_col == null:
		return
	draw_texture(_scroll_col, SCROLL_XY)
	if _scroll_thumb == null:
		return
	var trough := SCROLL_TROUGH[1] - SCROLL_TROUGH[0] + 1
	var len_px := maxi(8, int(round(float(MAX_ROWS) / float(_ties.size()) * trough)))
	var free := trough - len_px
	var max_off := maxi(1, _ties.size() - MAX_ROWS)
	var top: int = SCROLL_TROUGH[0] + int(round(float(_offset) / float(max_off) * free))
	for y in len_px:
		draw_texture(_scroll_thumb, Vector2(SCROLL_XY.x, top + y))
