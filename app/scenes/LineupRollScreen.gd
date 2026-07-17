extends Control
class_name LineupRollScreen
## PM98 PRE-MATCH XI-vs-XI PHOTO ROLL (LINE-UPS ON) — the original's pre-match
## presentation, semantics WITNESSED LIVE in the original (docs/re/
## matchday_flow_witness_re.md §4 + the 07-16 stills orig/61-63, walkthrough
## 053-055): ~0.9s of CLEAN fondo, then the 11 rows land at ~4.3s pitch —
## each row's photo pair GROWS IN PLACE (home face first, away ~1.5s later),
## the HOME surname slides in from the LEFT EDGE on its dark band, the AWAY
## surname slides from the RIGHT EDGE as a WHITE plate with black ink that
## inverts on landing, and the numbers land last (away number after the away
## name settles — orig/61). After row 11 the header caps it (kits + "Home ◄►
## Away" title band + the grey manager row), the board HOLDS ~8s and then
## AUTO-advances. A tap mid-roll snaps to the complete board; a tap on the
## complete board advances immediately. The roll plays in EVERY view mode
## (witnessed in RESULTS mode too); LINE-UPS OFF skips it (Main gates).
##
## Chrome (tools/re/build_prematch_roll_from_frames.py, all from witnessed
## frames): prematch_bg.png = the clean fondo (row-1 zone reconstructed by
## inverting the band-translucency LUT); prematch_full.png = the complete
## state whose band strips are blitted as rows land (the bands are the fondo
## behind the original's ordered-dither translucency — not opaque chrome);
## roll_sil.png = the black-bust photo placeholder. Photos are the native
## 32x32 MINIFOTO at x284/x324 inside a 1px black 74x34 pair frame.
##
## Sub-second choreography within a row is approximated from the 20fps video
## (the landmarks — face order, +1.5s away lag, slide directions, white
## plate, number order, 4.3s pitch, 0.9s fondo, auto-advance hold — are all
## witnessed; the exact easing is not frame-locked).
##
## Header kits: the original's free-floating hi-res kit render is un-extracted
## (same family as the hub circle kits, s12 flag) — the 48x64 kit escudo is
## scaled into the witnessed box as the approximation.

signal done

const W := 640
const H := 480

const ROWS := 11
const ROW0_Y := 84
const ROW_PITCH := 36
const BAND_H := 32
const CELL_HOME_X := 284
const CELL_AWAY_X := 324
const OUTLINE := Rect2(283, -1, 74, 34)   # black frame around the pair block

const NAME_RIGHT_H := 255    # home surname right edge (ink ends 254)
const NAME_LEFT_A := 386     # away surname left edge
const NUM_CX_H := 40.5       # number centre x
const NUM_CX_A := 597.5
const INK_TOP_OFF := 10      # text ink top relative to band top
const GLYPH_TOP := 1         # proman14 cap ink starts at row 1 of the cell
const BASE := 12             # proman14 baseline within the line box

const TITLE_Y := 13          # title strip top (strip y13..45)
const TITLE_H := 33
const TITLE_INK_Y := 23
const TITLE_RIGHT_H := 276
const TITLE_LEFT_A := 364
const MGR_INK_Y := 57
const MGR_RIGHT_H := 249
const MGR_LEFT_A := 390

const C_NAME := Color(1, 1, 1)
const C_NUM := Color8(85, 143, 255)      # pale blue (capture-dither midpoint)
const C_MGR := Color8(105, 137, 181)     # pale grey-blue manager ink

# witnessed clock (matchday_flow_witness_re §4)
const FONDO_TIME := 0.9      # clean background before row 1
const ROW_TIME := 4.3        # row pitch (faces land at FONDO_TIME + i*ROW_TIME)
const HOLD_TIME := 8.0       # complete-board hold before the auto-advance
# per-row choreography (local t from the row's face landing)
const T_HFACE := 0.5         # home face unfold length
const T_BAND := 0.5          # band + home-name slide start
const T_HNAME_END := 1.4
const T_AFACE := 1.5         # away face unfold start (+0.5 long)
const T_ANAME := 2.0         # away white-plate slide start
const T_ANAME_END := 2.9
const T_HNUM := 3.3
const T_ANUM := 3.6          # away number last (orig/61: settled name, no number)
const ROW_DONE := 3.8

var _bg: Texture2D
var _full: Texture2D
var _sil: Texture2D
var _f14: Font
var _home := ""
var _away := ""
var _home_mgr := ""
var _away_mgr := ""
var _home_kit: Texture2D
var _away_kit: Texture2D
var _home_xi: Array = []     # [{num, name, photo_id}] slot order, GK first
var _away_xi: Array = []
var _t := 0.0                # clock since mount
var _finished := false


func _ready() -> void:
	_bg = load("res://art/screens/matchflow/prematch_bg.png")
	_full = load("res://art/screens/matchflow/prematch_full.png")
	_sil = load("res://art/screens/matchflow/roll_sil.png")
	_f14 = PMChrome.font("14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	set_process(true)
	queue_redraw()


func setup(home_name: String, away_name: String, home_mgr: String, away_mgr: String,
		home_id: int, away_id: int, home_xi: Array, away_xi: Array) -> void:
	_home = home_name
	_away = away_name
	_home_mgr = home_mgr
	_away_mgr = away_mgr
	_home_kit = PMChrome.kit(home_id)
	_away_kit = PMChrome.kit(away_id)
	_home_xi = home_xi
	_away_xi = away_xi
	_t = 0.0
	_finished = false
	queue_redraw()


func row_start(i: int) -> float:
	return FONDO_TIME + ROW_TIME * i


## The board is complete (all rows + header) at this clock time.
func complete_time() -> float:
	return row_start(ROWS - 1) + ROW_DONE


func is_complete() -> bool:
	return _t >= complete_time()


## Snap the whole board in (a tap mid-roll); the hold clock restarts here.
func complete_now() -> void:
	_t = maxf(_t, complete_time())
	queue_redraw()


func _process(delta: float) -> void:
	if _finished:
		return
	_t += delta
	# the complete board AUTO-advances after the hold (witnessed zero-click)
	if _t >= complete_time() + HOLD_TIME:
		_finish()
		return
	queue_redraw()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		if is_complete():
			_finish()
		else:
			complete_now()


# ---- drawing --------------------------------------------------------------

func band_y(i: int) -> int:
	return ROW0_Y + ROW_PITCH * i


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.08), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _bg != null:
		draw_texture(_bg, Vector2.ZERO)
	for i in ROWS:
		var lt := _t - row_start(i)
		if lt >= 0.0:
			_draw_row(i, lt)
	if is_complete():
		_draw_header()


func _draw_row(i: int, lt: float) -> void:
	var y := band_y(i)
	var hp: Dictionary = _home_xi[i] if i < _home_xi.size() else {}
	var ap: Dictionary = _away_xi[i] if i < _away_xi.size() else {}
	# band strip (the translucent dark band, from the complete bake) + pair frame
	if lt >= T_BAND and _full != null:
		var r := Rect2(0, y, W, BAND_H)
		draw_texture_rect_region(_full, r, r)
	draw_rect(Rect2(OUTLINE.position.x, y + OUTLINE.position.y,
		OUTLINE.size.x, OUTLINE.size.y), Color.BLACK, true)
	# faces grow in place: home first, away ~1.5s later (vertical unfold)
	_draw_face(hp, CELL_HOME_X, y, clampf(lt / T_HFACE, 0.0, 1.0))
	_draw_face(ap, CELL_AWAY_X, y, clampf((lt - T_AFACE) / T_HFACE, 0.0, 1.0))
	if _f14 == null:
		return
	var by := y + INK_TOP_OFF - GLYPH_TOP + BASE   # proman14 baseline
	# home surname slides in from the LEFT edge on the band
	if lt >= T_BAND:
		var hn := str(hp.get("name", ""))
		var hw := _f14.get_string_size(hn, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var hp01 := clampf((lt - T_BAND) / (T_HNAME_END - T_BAND), 0.0, 1.0)
		draw_string(_f14, Vector2(lerpf(-hw, NAME_RIGHT_H - hw, hp01), by), hn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_NAME)
	# away surname slides in from the RIGHT edge as a WHITE plate w/ black ink,
	# inverting to white-on-band ink when it lands
	if lt >= T_ANAME:
		var an := str(ap.get("name", ""))
		var aw := _f14.get_string_size(an, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var ap01 := clampf((lt - T_ANAME) / (T_ANAME_END - T_ANAME), 0.0, 1.0)
		var ax := lerpf(W, NAME_LEFT_A, ap01)
		if ap01 < 1.0:
			draw_rect(Rect2(ax - 4, by - BASE + GLYPH_TOP - 2, aw + 8, 15 + 3),
				Color(1, 1, 1), true)
			draw_string(_f14, Vector2(ax, by), an,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0, 0, 0))
		else:
			draw_string(_f14, Vector2(ax, by), an,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_NAME)
	# numbers land last (away after the away name settles)
	if lt >= T_HNUM:
		_draw_num(str(hp.get("num", "")), NUM_CX_H, by)
	if lt >= T_ANUM:
		_draw_num(str(ap.get("num", "")), NUM_CX_A, by)


func _draw_num(t: String, cx: float, baseline: int) -> void:
	if t == "" or _f14 == null:
		return
	var w := _f14.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(_f14, Vector2(roundf(cx - w * 0.5), baseline), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_NUM)


## A face cell mid-unfold: the middle `p` fraction of the 32x32 MINIFOTO
## (grows from the vertical centre outward). p=0 -> nothing, p=1 -> full.
func _draw_face(pl: Dictionary, x: int, y: int, p: float) -> void:
	if p <= 0.0:
		return
	var tex := PMChrome.mini_face(pl.get("photo_id"))
	if tex == null:
		tex = _sil
	if tex == null:
		return
	var h := maxf(2.0, roundf(32.0 * p))
	var off := (32.0 - h) * 0.5
	draw_texture_rect_region(tex, Rect2(x, y + off, 32, h), Rect2(0, off, 32, h))


func _draw_header() -> void:
	if _full != null:
		var r := Rect2(0, TITLE_Y, W, TITLE_H)
		draw_texture_rect_region(_full, r, r)
	if _f14 != null:
		var tby := TITLE_INK_Y - GLYPH_TOP + BASE
		var hw := _f14.get_string_size(_home, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(_f14, Vector2(TITLE_RIGHT_H - hw, tby), _home,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_NAME)
		draw_string(_f14, Vector2(TITLE_LEFT_A, tby), _away,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_NAME)
		var mby := MGR_INK_Y - GLYPH_TOP + BASE
		var mw := _f14.get_string_size(_home_mgr, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(_f14, Vector2(MGR_RIGHT_H - mw, mby), _home_mgr,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_MGR)
		draw_string(_f14, Vector2(MGR_LEFT_A, mby), _away_mgr,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_MGR)
	# corner kits: the escudo scaled into the witnessed ~62x66 box (the
	# original's hi-res kit render is un-extracted — flagged approximation)
	_draw_kit(_home_kit, 10)
	_draw_kit(_away_kit, 568)


func _draw_kit(tex: Texture2D, x: int) -> void:
	if tex != null:
		draw_texture_rect(tex, Rect2(x, 0, 62, 66), false)


# ---- letterbox scaling ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
