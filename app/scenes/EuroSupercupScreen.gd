extends Control
class_name EuroSupercupScreen
## PM98 RESULTS -> Euro. Superc.: the EUROPEAN SUPERCUP on the ORIGINAL's own screen.
##
## Its builder is `FUN_004a1820` (1133 bytes) — NOT the single-match CHARITY / INTERCONT
## screen. It mounts the shared two-leg panel widget `FUN_0046a110` at (137, 124), whose
## two headers read `1ST LEG MATCH` / `2ND LEG MATCH` (the same widget prints `MATCH
## RESULT` / `REPLAY RESULT` when it draws an F.A. Cup replay). Two match records live at
## `screen+0x347c` and `screen+0x3480`, 0xbc apart: the Supercup is home-and-away, not the
## neutral one-off the app used to render on the invented CupScreen.
##
## Static chrome = the original's own frame baked verbatim
## (tools/re/build_supercup_chrome_from_frames.py; binding frame
## screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_supercup.png). This
## scene draws ONLY the club-dependent layer:
##   * the two venue names
##   * the four mini kits and four club names
##   * the four score cells
##   * the WINNER band's club name and the kit in the laurel, once the tie is played
##
## Every rect below is a literal in FUN_0046a110 offset by the panel origin (137, 124) —
## the table in `docs/re/euro_supercup_screen_re.md` pairs each one with its call site.
##
## HONEST GAPS (flagged, never invented):
##   * the original's mini-kit bank for this panel is un-extracted, so the app's own kit
##     art is scaled into the measured well — the same documented approximation
##     CompResultScreen and CharityShieldScreen already carry;
##   * no PLAYED Supercup has been captured, so the score cells, the WINNER fill and any
##     aggregate presentation follow the shared grammar of the other cup screens rather
##     than a witnessed frame.

signal back_pressed

const W := 640
const H := 480

# --- panel geometry (design px) -------------------------------------------------------
const PANEL_X := 137
const PANEL_W := 227                  # FUN_0046a110's own 0xe3 text box
const LEG_ROW_Y := [[178, 200], [290, 312]]   # club-plate tops, leg 1 then leg 2
const VENUE_Y := [161, 274]           # venue-name line (the STADIUM caption stays baked)
const NAME_X := 167                   # both witnessed names start here, left-aligned
const NAME_TOP := 4                   # ink cap band sits +5 from the plate top
const NAME_W := 148.0
const KIT_WELL := Rect2(145, 0, 16, 20)       # y filled per row
const SCORE_X := 321
const SCORE_W := 36.0

const C_NAME := Color8(80, 100, 120)          # club-row ink (same plate as CompResult)
const C_SCORE := Color8(255, 255, 255)
const C_VENUE := Color8(17, 90, 34)           # the frame's venue green
const C_WINNER := Color8(42, 63, 170)
const C_PRESS := Color(1, 1, 1, 0.2)

# The WINNER band + laurel are the shared strip below the panel: pixel-identical to the
# CHARITY / INTERCONT frames over y346..420 (verified by diffing the two captures).
const WINNER_X := 65
const WINNER_Y := 382
const LAUREL_KIT := Rect2(408, 342, 32, 44)
const R_RETURN := Rect2(504, 433, 116, 29)

const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 6), "hdr_status": Vector2(524, 6)}

var _tie: Dictionary = {}        # {legs:[{stadium,home{name,club_id},away{...},hg,ag}], winner:{}}
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


## `t` carries the tie. An un-played leg leaves `hg`/`ag` absent and its score cells stay
## empty, which is exactly the state the binding frame captures.
func setup(t: Dictionary, header: Dictionary = {}) -> void:
	_tie = t
	_header = header
	var path := "res://art/screens/compresult/supercup.png"
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
	_draw_legs()
	_draw_winner()
	if _press == "return":
		draw_rect(R_RETURN, C_PRESS, true)


## The barra values: the textless band.png patches + the header bake's text grammar, the
## same recomposition ResultsScreen and CompResultScreen already use.
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


func _draw_legs() -> void:
	var legs: Array = _tie.get("legs", [])
	for li in 2:
		if li >= legs.size():
			continue
		var leg: Dictionary = legs[li]
		var ground := str(leg.get("stadium", ""))
		if ground != "":
			PMChrome.text(self, _f12, PANEL_X, VENUE_Y[li], ground, C_VENUE, 13, 1,
				float(PANEL_W))
		var played: bool = leg.has("hg") and leg.has("ag")
		for i in 2:
			var side: Dictionary = leg.get("home" if i == 0 else "away", {})
			if side.is_empty():
				continue
			var y: int = LEG_ROW_Y[li][i]
			var well := KIT_WELL
			well.position.y = y
			_draw_mini_kit(int(side.get("club_id", -1)), well)
			PMChrome.text(self, _f10, NAME_X, y + NAME_TOP, str(side.get("name", "")),
				C_NAME, 11, 0, NAME_W)
			if played:
				var goals := int(leg.get("hg" if i == 0 else "ag", 0))
				PMChrome.text(self, _f14, SCORE_X, y - 1, str(goals), C_SCORE, 15, 1,
					SCORE_W)


## The row's mini kit. The original's own NANOESC 24x32 kit is the closest art we hold to
## the panel's 16x20 sprite; the hi-res panel bank is un-extracted (the documented gap
## CompResultScreen carries too).
func _draw_mini_kit(club_id: int, r: Rect2) -> void:
	var tex := PMChrome.nano_kit(club_id)
	if tex == null:
		PMChrome.draw_crest(self, club_id, r)
		return
	var sc: float = minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
	var w := tex.get_width() * sc
	var h := tex.get_height() * sc
	draw_texture_rect(tex, Rect2(r.position.x + (r.size.x - w) * 0.5,
		r.position.y + (r.size.y - h) * 0.5, w, h), false)


func _draw_winner() -> void:
	var win: Dictionary = _tie.get("winner", {})
	if win.is_empty():
		return
	PMChrome.text(self, _f14, WINNER_X, WINNER_Y, str(win.get("name", "")),
		C_WINNER, 15, 0, 280.0)
	PMChrome.draw_crest(self, int(win.get("club_id", -1)), LAUREL_KIT)


func _gdi(f: Font, sz: int, s: String, span: int, y_top: int, ink: Color) -> void:
	if s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (span - w) / 2
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)
