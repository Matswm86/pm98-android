extends Control
class_name CompResultScreen
## PM98 RESULTS -> <single-match competition>: the CHARITY SHIELD and the
## INTERCONTINENTAL CUP, on the ORIGINAL's own screen.
##
## MANAGER.EXE proves the two are one screen: `FUN_004717a0` (charity) and
## `FUN_0048daf0` (intercontinental) are 1107 bytes each and differ in exactly two
## operands -- the title string and the trophy bitmap. Every other differing byte is an
## `e8` rel32 whose delta is 0x1c350, the distance between the entry points. Confirmed
## live: both frames carry the same title plate, RESULT plate, match panel, STADIUM
## caption, two club rows with score cells, WINNER band and laurel.
##
## Static chrome = each competition's OWN frame baked verbatim
## (tools/re/build_compresult_chrome_from_frames.py; binding frames
## screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_charity.png and
## 09_comp_intercont.png). This scene draws ONLY the club-dependent layer:
##   * the two kits + the two country flags
##   * the STADIUM name
##   * the two club names and their two score cells
##   * the WINNER band's club name and the kit in the laurel
##
## It replaces `Main._show_one_off_final`'s invented CupScreen for these two.
##
## HONEST GAPS (flagged, never invented):
##   * the original's hi-res 48x60 panel kit bank is un-extracted, so the app's own kit
##     art is scaled into the measured rect -- the same documented approximation
##     CharityShieldScreen already carries;
##   * the EUROPEAN SUPERCUP is the same family but a DIFFERENT builder (0x4a1820, two
##     1ST LEG / 2ND LEG blocks) and its frame is captured but not yet built.

signal back_pressed

const W := 640
const H := 480

# --- frame-measured geometry (design px; see the baker's docstring for the probes) ---
const KIT_HOME := Rect2(146, 158, 48, 60)
const KIT_AWAY := Rect2(306, 158, 48, 60)
const FLAG_HOME := Rect2(199, 163, 30, 20)
const FLAG_AWAY := Rect2(270, 163, 30, 20)
# STADIUM name: the baked caption's ink spans x203..282 and both witnessed names centre
# on the same point -- Wembley x209..276, Tokyo x219..265 -> centre 243.
const STADIUM_CENTRE := 243
const STADIUM_Y := 240
const ROW_Y := [269, 300]        # home / away plate tops (borders y265..288, y296..319)
const NAME_X := 155              # both witnessed names start here, left-aligned
const NAME_W := 148.0
const SCORE_CELL := [306, 39]    # x306..344, digits centre 325 in both frames
const WINNER_X := 65             # 'Manchester Utd.' ink x65..219
const WINNER_Y := 382
const LAUREL_KIT := Rect2(408, 342, 32, 44)

const C_NAME := Color8(80, 100, 120)     # club-row ink
const C_SCORE := Color8(255, 255, 255)
const C_STADIUM := Color8(17, 90, 34)
const C_WINNER := Color8(42, 63, 170)
const C_PRESS := Color(1, 1, 1, 0.2)
const R_RETURN := Rect2(504, 433, 116, 29)   # same plate ResultsScreen uses

const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 6), "hdr_status": Vector2(524, 6)}

var _kind := "charity"
var _match: Dictionary = {}      # {home:{name,club_id,flag}, away:{...}, hg, ag, stadium, winner}
var _header: Dictionary = {}
var _chrome: Texture2D
var _patches: Dictionary = {}
var _f8: Font
var _f10: Font
var _f12: Font
var _f14: Font
var _fcal: Font
var _press := ""


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f14 = PMChrome.font("14")
	_fcal = PMChrome.font("calend12")
	for k in HDR_PATCH_XY:
		var p := "res://art/screens/results/%s.png" % k
		_patches[k] = load(p) if ResourceLoader.exists(p) else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `kind` is "charity" or "intercont" (it picks the baked chrome, i.e. the title plate
## and the trophy). `m` carries the tie; an unplayed tie leaves `hg`/`ag` absent and the
## score cells and WINNER band stay empty, as the original's own un-played state does.
func setup(kind: String, m: Dictionary, header: Dictionary = {}) -> void:
	_kind = kind
	_match = m
	_header = header
	var path := "res://art/screens/compresult/%s.png" % kind
	_chrome = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()


func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = "return" if R_RETURN.has_point(d) else ""
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "return" and R_RETURN.has_point(d):
		back_pressed.emit()


func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	_draw_header()
	_draw_panel()
	if _press == "return":
		draw_rect(R_RETURN, C_PRESS, true)


## The barra values: the textless band.png patches + the header bake's text grammar,
## byte-for-byte the recomposition ResultsScreen already proved.
func _draw_header() -> void:
	for k in HDR_PATCH_XY:
		if _patches[k] != null:
			draw_texture(_patches[k], HDR_PATCH_XY[k])
	_gdi(_f8, 11, str(_header.get("top", "")), PMChrome.HDR_NAME_TOP["S"],
		PMChrome.HDR_NAME_TOP["y"], Color(0, 0, 0))
	_gdi(_f8, 11, str(_header.get("bottom", "")), PMChrome.HDR_NAME_BOT["S"],
		PMChrome.HDR_NAME_BOT["y"], Color(1, 1, 1))
	var nk := PMChrome.nano_kit(int(_header.get("club_id", -1)))
	if nk != null:
		draw_texture(nk, PMChrome.HDR_MGR_NANO_XY)
	for line in PMChrome.HDR_CAL_LINES:
		_gdi(_f8, 11, str(_header.get(line["key"], "")), PMChrome.HDR_CAL_S,
			line["y"], line["ink"])
	_gdi(_fcal, 15, str(_header.get("status_top", "")), PMChrome.HDR_STAT_S,
		PMChrome.HDR_STAT_TOP_Y, Color(0, 0, 0))
	_gdi(_fcal, 15, str(_header.get("status_bottom", "")), PMChrome.HDR_STAT_S,
		PMChrome.HDR_STAT_BOT_Y, Color(1, 1, 1))


func _draw_panel() -> void:
	var home: Dictionary = _match.get("home", {})
	var away: Dictionary = _match.get("away", {})
	_draw_side(home, KIT_HOME, FLAG_HOME)
	_draw_side(away, KIT_AWAY, FLAG_AWAY)

	var ground := str(_match.get("stadium", ""))
	if ground != "":
		PMChrome.text(self, _f12, STADIUM_CENTRE - 100, STADIUM_Y, ground, C_STADIUM, 13, 1, 200.0)

	var played: bool = _match.has("hg") and _match.has("ag")
	for i in 2:
		var side: Dictionary = home if i == 0 else away
		PMChrome.text(self, _f10, NAME_X, ROW_Y[i], str(side.get("name", "")),
			C_NAME, 11, 0, NAME_W)
		if played:
			var goals := int(_match.get("hg" if i == 0 else "ag", 0))
			PMChrome.text(self, _f14, SCORE_CELL[0], ROW_Y[i] - 1, str(goals),
				C_SCORE, 15, 1, float(SCORE_CELL[1]))

	var win: Dictionary = _match.get("winner", {})
	if not win.is_empty():
		PMChrome.text(self, _f14, WINNER_X, WINNER_Y, str(win.get("name", "")),
			C_WINNER, 15, 0, 280.0)
		PMChrome.draw_crest(self, int(win.get("club_id", -1)), LAUREL_KIT)


## One side of the tie: the club's kit in the measured well and its country flag in the
## original's own black-bordered box.
func _draw_side(side: Dictionary, kit_r: Rect2, flag_r: Rect2) -> void:
	if side.is_empty():
		return
	PMChrome.draw_crest(self, int(side.get("club_id", -1)), kit_r)
	var flag := PMChrome.flag(side.get("flag", ""))
	if flag != null:
		draw_texture_rect(flag, flag_r, false)


func _gdi(f: Font, sz: int, s: String, span: int, y_top: int, ink: Color) -> void:
	if s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (span - w) / 2
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)
