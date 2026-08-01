extends Control
class_name EuroGroupScreen
## RESULTS -> EURO. LEAGUE, the GROUP phase view, rebuilt frame-true.
##
## Replaces `Main._show_cup_group_placeholder`'s invented `CupScreen` card. Everything
## static is the original's own pixels (`art/screens/euroleague/chrome.png`, baked by
## `tools/re/build_euroleague_chrome_from_frames.py` from six live GROUP frames plus the
## same screen with an empty body); everything the career fills is redrawn here at the
## anchors solved with `tools/re/probe_text_anchor.py`.
##
## Geometry + inks: docs/re/euro_league_screen_re.md.

signal back_pressed
signal group_selected(index: int)
signal round_changed(delta: int)

const W := 640
const H := 480

const LETTERS := ["A", "B", "C", "D", "E", "F"]

# ---- the GROUP header band -------------------------------------------------------
const HDR_PLATE_XY := Vector2(100, 183)      # the per-letter `GROUP <letter>` plate
const HDR_KIT_XY := Vector2(75, 178)         # the group leader's NANOESC kit

# ---- the standings table ---------------------------------------------------------
const ROW_TOPS := [209, 224, 239, 254]
const CLUB_PEN_X := 100                      # calend12, LEFT-aligned
const FLAG_XY_DX := 183                      # MINIBAND flag, 14x10, right-aligned in the cell
const FLAG_DY := 2
# each number cell centred on x0 + x1 + 1 (the anchor form `_txt_field` takes)
const NUM_SUMS := [421, 459, 491, 523, 555, 587, 619]
const C_CLUB := Color8(60, 60, 100)
const C_NUM := Color8(180, 200, 220)

# ---- the two results rows --------------------------------------------------------
const RES_TOPS := [278, 300]
const RES_PEN_DY := -1                       # the pen top sits one row above the bar
const HOME_PEN_END := 177                    # right-aligned home name
const AWAY_PEN_X := 219                      # left-aligned away name
const BOX_SUMS := [378, 414]                 # score boxes x181..196 / x199..214
const KIT_X := [80, 301]
const KIT_TOPS := [274, 296]
## The outline-pass overlays (baked 2026-07-27, knockout-build method): the pass's
## result is POSITION-CONSTANT across every witnessed cell (six different clubs per
## well), so it is baked verbatim per well -- under = the ring outside the silhouette,
## over = the on-sprite positions the pass provably overrides club-independently.
const WELL_KEYS := [["res0_h", "res0_a"], ["res1_h", "res1_a"]]
const C_RES := Color8(80, 100, 120)
const C_GOAL := Color8(180, 200, 220)
const C_GOAL_MARK := Color8(255, 255, 0)

# ---- the ROUND paginator ---------------------------------------------------------
const ROUND_SUM := 829                       # plate x372..456
const ROUND_PEN_TOP := 124
const R_ROUND_PREV := Rect2(352, 118, 20, 22)
const R_ROUND_NEXT := Rect2(457, 118, 20, 22)
const R_RETURN := Rect2(504, 433, 116, 29)
const BTN_X := 358
const BTN_TOPS := [183, 207, 231, 255, 279, 303]
const BTN_SIZE := Vector2(89, 23)

const C_PRESS := Color(1, 1, 1, 0.2)

# the barra grammar, shared with ResultsScreen (same bake, same band)
const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 13), "hdr_status": Vector2(536, 10)}
# The shared `hdr_status` patch carries the band's DEFAULT right-hand emblem (a football).
# In season the original shows the division's own trophy there instead, and this screen's
# chrome carries it from the witness, so the patch is clipped short of that column.
const HDR_STATUS_W := 77

var _chrome: Texture2D
var _plates: Dictionary = {}       # letter -> the GROUP header plate
var _lit: Dictionary = {}          # letter -> the lit button face
var _well: Dictionary = {}         # "under_res0_h"/... the kit-well outline overlays
var _patches: Dictionary = {}
var _page_cal: Texture2D
var _page_p10: Texture2D
var _g_cal: Dictionary = {}
var _g_p10: Dictionary = {}
var _f8: Font
var _fcal: Font

var _header: Dictionary = {}
var _letter := "A"
var _round := 1
var _rounds := 6
var _rows: Array = []              # 4 x {name, flag, pts, p, w, d, l, gf, ga, club_id}
var _results: Array = []           # 2 x {home_id, home, away_id, away, hg, ag, played}
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/euroleague/chrome.png")
	for L in LETTERS:
		_plates[L] = _tex("res://art/screens/euroleague/hdr_group_%s.png" % L)
		_lit[L] = _tex("res://art/screens/euroleague/btn_lit_%s.png" % L)
	for row in WELL_KEYS:
		for k in row:
			_well["under_" + str(k)] = _tex("res://art/screens/euroleague/well_under_%s.png" % k)
			_well["over_" + str(k)] = _tex("res://art/screens/euroleague/well_over_%s.png" % k)
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


## `header` uses the draw_match_header manager-mode keys, as ResultsScreen does.
## `rows` is the group's ranked table, `results` that matchday's two fixtures.
func setup(header: Dictionary, letter: String, round_no: int, rounds: int,
		rows: Array, results: Array) -> void:
	_header = header
	_letter = letter if letter in LETTERS else "A"
	_round = clampi(round_no, 1, maxi(1, rounds))
	_rounds = maxi(1, rounds)
	_rows = rows
	_results = results
	queue_redraw()


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


func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d):
		return "return"
	if R_ROUND_PREV.has_point(d):
		return "prev"
	if R_ROUND_NEXT.has_point(d):
		return "next"
	for i in BTN_TOPS.size():
		if Rect2(BTN_X, BTN_TOPS[i], BTN_SIZE.x, BTN_SIZE.y).has_point(d):
			return "group%d" % i
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
	elif t == "prev" and _round > 1:
		round_changed.emit(-1)
	elif t == "next" and _round < _rounds:
		round_changed.emit(1)
	elif t.begins_with("group"):
		group_selected.emit(int(t.substr(5)))


# ---- text ------------------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((glyphs.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


## Blit one string from a PM98 BMFont atlas at a PEN origin (`x`) and pen top (`y_top`).
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
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)
	_draw_header()
	_draw_group_header()
	_draw_table()
	_draw_results()
	_draw_round()
	var lit: Texture2D = _lit.get(_letter)
	var gi := LETTERS.find(_letter)
	if lit != null and gi >= 0:
		draw_texture(lit, Vector2(BTN_X, BTN_TOPS[gi]))
	if _press != "":
		var r := _press_rect()
		if r.size.x > 0.0:
			draw_rect(r, C_PRESS, true)


func _press_rect() -> Rect2:
	if _press == "return":
		return R_RETURN
	if _press == "prev":
		return R_ROUND_PREV
	if _press == "next":
		return R_ROUND_NEXT
	if _press.begins_with("group"):
		return Rect2(BTN_X, BTN_TOPS[int(_press.substr(5))], BTN_SIZE.x, BTN_SIZE.y)
	return Rect2()


## The shared barra: textless band patches + the header bake's text grammar, exactly as
## ResultsScreen draws it (this IS the RESULTS screen -- only the body differs).
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
	PMChrome.draw_manager_panel(self, cid)
	for line in PMChrome.HDR_CAL_LINES:
		_gdi_text(_f8, 11, str(_header.get(line["key"], "")), PMChrome.HDR_CAL_S,
			line["y"], line["ink"])
	_gdi_text(_fcal, 15, str(_header.get("status_top", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_TOP_Y, Color(0, 0, 0))
	_gdi_text(_fcal, 15, str(_header.get("status_bottom", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_BOT_Y, Color(1, 1, 1))


## `GROUP <letter>` is CENTRED on its black plate, so the whole string shifts by a pixel
## between letters -- the six plates are therefore cut verbatim, one per witnessed frame,
## instead of re-rendered. The leader's NANOESC kit sits beside it.
func _draw_group_header() -> void:
	var leader := -1 if _rows.is_empty() else int((_rows[0] as Dictionary).get("club_id", -1))
	var kt := PMChrome.nano_kit(leader)
	if kt != null:
		draw_texture(kt, HDR_KIT_XY)
	var plate: Texture2D = _plates.get(_letter)
	if plate != null:
		draw_texture(plate, HDR_PLATE_XY)


func _draw_table() -> void:
	for i in mini(_rows.size(), ROW_TOPS.size()):
		var row: Dictionary = _rows[i]
		var top: int = ROW_TOPS[i]
		_txt(_page_cal, _g_cal, CLUB_PEN_X, top, str(row.get("name", "")), C_CLUB)
		var fl := PMChrome.mini_flag(row.get("flag", -1))
		if fl != null:
			draw_texture(fl, Vector2(FLAG_XY_DX, top + FLAG_DY))
		var vals := [row.get("pts", 0), row.get("p", 0), row.get("w", 0), row.get("d", 0),
			row.get("l", 0), row.get("gf", 0), row.get("ga", 0)]
		for j in NUM_SUMS.size():
			_txt_mid(_page_cal, _g_cal, NUM_SUMS[j], top, str(int(vals[j])), C_NUM)


## The matchday's two fixtures. The goal digit inked yellow is NOT a winner marker: it is
## the second box on row 1 and the first box on row 2, every time, whoever won -- witnessed
## on 20 rows across two careers and both legs of a double round-robin
## (docs/re/euro_league_screen_re.md). Ported as the checkerboard it measures as; its
## meaning is unresolved and deliberately NOT invented.
func _draw_results() -> void:
	for i in mini(_results.size(), RES_TOPS.size()):
		var r: Dictionary = _results[i]
		var top: int = RES_TOPS[i]
		var pen_top: int = top + RES_PEN_DY
		for slot in 2:
			var wk := str((WELL_KEYS[i] as Array)[slot])
			if _well.get("under_" + wk) != null:
				draw_texture(_well["under_" + wk], Vector2(KIT_X[slot], KIT_TOPS[i]))
			var kt := PMChrome.ridi_kit(int(r.get("home_id" if slot == 0 else "away_id", -1)))
			if kt != null:
				draw_texture(kt, Vector2(KIT_X[slot], KIT_TOPS[i]))
			if _well.get("over_" + wk) != null:
				draw_texture(_well["over_" + wk], Vector2(KIT_X[slot], KIT_TOPS[i]))
		_txt_right(_page_cal, _g_cal, HOME_PEN_END, pen_top, str(r.get("home", "")), C_RES)
		_txt(_page_cal, _g_cal, AWAY_PEN_X, pen_top, str(r.get("away", "")), C_RES)
		if not bool(r.get("played", true)):
			continue
		var goals := [int(r.get("hg", 0)), int(r.get("ag", 0))]
		for b in 2:
			var col: Color = C_GOAL_MARK if (i + b) % 2 == 1 else C_GOAL
			_txt_mid(_page_cal, _g_cal, BOX_SUMS[b], pen_top, str(goals[b]), col)


func _draw_round() -> void:
	_txt_mid(_page_p10, _g_p10, ROUND_SUM, ROUND_PEN_TOP, "Round %d" % _round, Color(0, 0, 0))
