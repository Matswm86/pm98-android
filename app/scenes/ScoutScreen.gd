extends Control
class_name ScoutScreen
## PM98 SCOUT screen — frame-true from the live wine witness run (frames 43,
## 61-68, 73, 78, 81-82; docs/re/scout_screen_re.md). Static chrome = witness
## 61 (scout hired, idle) baked verbatim with ONLY the scout-strip ink cleared
## (from 43) and the barra text interiors blanked (transfer §C2 recipe) —
## tools/re/build_scout_chrome_from_frames.py. This scene draws ONLY state
## deltas: the live barra, the hired scout's strip (name/stars/wage), LED
## on-sprites, dropdown/spinner values, the armed SEARCH ring, and the PLAYERS
## FOUND panel (gate/searching texts are frame-cut sprites; result rows are
## drawn with the witnessed digit-centring grammar + frame-cut star glyphs).
##
## WITNESSED RULES (all frame-bound, see the RE doc):
##  * no scout hired -> the whole 43 body blits over (washed criteria + gate
##    text); only RETURN works.
##  * SEARCH with no LEFT-column toggle ON -> the "PREMIER MANAGER 98" alert
##    "You have to select some options to make the search." over the PMAlert
##    LUT dim (league checks alone do NOT count — witness 64/66).
##  * E.U. / NON E.U. / WITHOUT TEAM checks stay WASHED (baked) even with a
##    scout — enablement un-witnessed, kept inert.
##  * SEARCH arms Career.start_scout_search (async, ~2 week-advances); the
##    searching text persists on re-entry; the finished hub alert is Career
##    pending_alerts -> Main.
##  * results: AV = floor((VE+RE+AG+CA)/4) (witnessed 8/8), MO = live morale,
##    fee/wage = valuation model (real figures un-portable), YEARS pair with
##    the yellow final-year cell; non-EU-1997 mini flag (insurance rule).
##  * a row tap opens the make-offer card (witness 82) — `player_pressed`.
##
## CRITERIA VALUES: POSITION/ROLE/AGE/QUALITY/PRICE dropdown CONTENTS are now
## binary-exact — lifted from the MANAGER.EXE getter tables (POSITION 0x662d10,
## ROLE-short 0x662df8, AGE 0x661e08, QUALITY 0x661e20, PRICE 0x661e40). AGE and
## QUALITY are the SMALL fields (band strings <=5 chars fit) and PRICE the WIDE
## field, exactly as the game sizes them. The filled-value GLYPH STYLE is still
## un-witnessed for all but POSITION ("GOALKEEPER") — same centred grammar,
## face-level. The bottom 2-segment bar is baked furniture (behaviour
## un-witnessed, never animated). The original's result ORDER is un-RE'd.

##
## ---- ONE PANEL ON THIS SCREEN IS OURS, NOT THE GAME'S -----------------------
## `docs/SPEC_scout_attribute_search.md`, owner-approved 2026-07-25: a NAME box, six
## per-attribute "at least" thresholds, and a sort selector — none of which the original
## has. They live in an OVERLAY that is CLOSED by default and is opened by tapping the
## inert 2-segment bar along the bottom (x11..500, y438..463), so with the panel shut
## every witnessed state of this screen still renders at 0 differing pixels. That bar's
## real behaviour is un-witnessed and it is never animated in any captured frame; binding
## our toggle to it is OURS and moves the moment the original's own use for it is seen.
## The panel also carries the shortfall line for the engine's shortlist cap
## (Career.scout_cap) — the cap itself is the binary's, the line is ours.

signal back_pressed
signal search_started(criteria: Dictionary)
signal player_pressed(row: Dictionary)
## OURS (Mats, 2026-07-27): fired on every NAME keystroke — the INSTANT lookup.
## No mission is armed; Main answers with apply_instant_results().
signal name_search(name: String)

const W := 640
const H := 480

# ---- criteria widgets (scout_chrome.json geometry) -------------------------
const LED := {
	"pos": Vector2(114, 113), "age": Vector2(17, 158), "role": Vector2(114, 158),
	"quality": Vector2(17, 204), "price": Vector2(114, 204),
}
const LED_LEAGUE := {
	"eng_prem": Vector2(284, 140), "eng_div1": Vector2(367, 140),
	"eng_div2": Vector2(450, 140), "eng_div3": Vector2(533, 140),
}
# The three NON-DIVISION search regions, one 27px row apart under the division row
# (LED faces measured at y 171/198/225 on a live capture; cells at 167/194/221).
# These are how the original scouts ABROAD — there is no foreign-league checkbox.
const LED_REGION := {
	"eu": Vector2(284, 167), "non_eu": Vector2(284, 194), "no_team": Vector2(284, 221),
}
# Enablement is the hired SCOUT's star rating. Measured live 2026-07-24, one scout per
# career: 3.0 (K. Burrowes, the 2026-07-18 witness) -> all three washed; 3.5 (W. Crane)
# -> E.U. PLAYERS only; 4.0 (M. Kelso) -> E.U. + NON E.U.; 5.0 (J. Loxley) -> all three.
# One unlock per half-star from 3.5, so PLAYERS WITHOUT TEAM lands on 4.5 — the only
# step not sampled directly (bracketed: off at 4.0, on at 5.0).
const REGION_STARS := {"eu": 3.5, "non_eu": 4.0, "no_team": 4.5}
const LED_SIZE := Vector2(22, 13)
# toggle hit zones = LED + label row (generous tap targets, LED-anchored)
const DROP_POS := Rect2(131, 131, 125, 16)     # POSITION value field
const DROP_ROLE := Rect2(131, 176, 125, 16)    # ROLE value field (grammar-shared)
const SPIN_AGE := Rect2(35, 176, 50, 16)       # AGE small field
const SPIN_QUALITY := Rect2(35, 222, 50, 16)   # QUALITY small field
const SPIN_PRICE := Rect2(131, 222, 125, 16)   # PRICE field
const ARROWS := {
	"pos_l": Rect2(115, 131, 16, 16), "pos_r": Rect2(256, 131, 16, 16),
	"role_l": Rect2(115, 176, 16, 16), "role_r": Rect2(256, 176, 16, 16),
	"age_l": Rect2(19, 176, 16, 16), "age_r": Rect2(86, 176, 16, 16),
	"quality_l": Rect2(19, 222, 16, 16), "quality_r": Rect2(86, 222, 16, 16),
	"price_l": Rect2(115, 222, 16, 16), "price_r": Rect2(256, 222, 16, 16),
}
const BTN_SEARCH := Rect2(518, 211, 100, 26)
const BTN_RETURN := Rect2(517, 437, 110, 28)

# ---- the OURS overlay (see the header note) --------------------------------
## The inert bottom bar, measured off the live frame p0023: body x11..500, y438..463.
const BTN_EXTRA := Rect2(11, 438, 490, 26)
## ---- the bottom bar is the ORIGINAL'S ROLLOVER READOUT (found 2026-07-26) -------------
## Two sessions recorded this bar as "inert furniture, behaviour un-witnessed". It is not:
## three frames in `screenshots/refrun-manutd-1997-98/novel/` show it in use, and they close
## it. `p0241` (Kluivert), `p0279` (Etxeberria) and `p0283` (Nesta) each carry
##   [the club's ridi kit] [the player's FULL name] [his club]
## for the ONE list row that is highlighted, and `p0245` — same results, no row highlighted —
## has all three empty. So it is a per-row rollover, not a persistent selection: in `p0245`
## the pointer has moved to SEARCH (the armed ring is up) and the readout has cleared, and in
## `p0242` / `p0281` a modal is up and it has cleared too. A click-selection would have
## survived both. Measured, all three frames agreeing to the pixel:
##   * kit      = `app/art/kits/ridi/<club_id>.png`, blitted at (17, 442) — matched 0 px on
##                all three (ridi/1020 Milan, ridi/1004 Athletic Club, ridi/1023 Lazio);
##   * name     = the full rendered name, CENTRED on segment A, ink pure black;
##   * club     = the club name, CENTRED on segment B, same ink;
##   * face     = proman8 at 11 px — the six witness strings size to within 1 px of the
##                measured ink widths, and no other font/size in the bank comes close;
##   * the highlighted row grows a **2 px BLACK frame**, x32..474, y (top-1)..(top+14),
##     replacing the grey 1 px border and eating one row of the white gap each side.
## Android has no pointer, so the rollover is bound to the PRESS: while a finger is held on a
## row that row frames and the bar reads out, and the release still opens the card. That is a
## port decision about an input the original did not have, not an invented pixel.
##
## The bar's two recessed segments, measured off the baked chrome: the grey (128,128,128)
## border runs x39..450 / y444..457, the interior is (220,220,220), and a single grey column
## at x286 splits it in two. So segment A is x40..285 and segment B x287..449, both y445..456.
const EXTRA_SEG_A := Rect2(40, 445, 246, 12)
const EXTRA_SEG_B := Rect2(287, 445, 163, 12)
const BAR_KIT_XY := Vector2(17, 442)
const BAR_TEXT_TY := 446           # pen top; puts the ink on the witnessed rows y448..454
## The two centres, SOLVED off the three witnesses rather than assumed from the segment
## widths: with the pen at `floor(cx - advance/2)` the six measured ink starts (112 / 83 / 109
## in A, 353 / 330 / 353 in B) bracket cx to exactly these two values. Rounding the half-pixel
## instead of flooring it puts "Athletic Club" 1 px right of the frame — the whole residual
## this pair closes.
const BAR_CX_A := 163.0
const BAR_CX_B := 368.0
## The door's own label. It is drawn ONLY while the original's readout is empty — the instant
## a row is pressed the readout takes the bar back — so the port never covers a pixel the
## original draws. That is the second and last site in this port that draws a pixel the
## original does not; `tools/re/diff_scout_bar_parity.py` bounds it exactly as
## `diff_options_parity.py` bounds the THREE UP FRONT row.
const EXTRA_LABEL := "EXTRA SEARCH FILTERS"
## ---- the panel itself: REBUILT IN ORIGINAL CHROME 2026-07-26 ---------------------------
## Mats on the first version: "NOT that AI slope image you used! REDO!" — it was drawn in an
## invented navy/yellow palette. Now every pixel of the panel is frame chrome:
## `ours_panel.png`, baked by tools/re/build_scout_ours_from_frames.py from the CLUB
## PERSONNEL trainers dialog (100_154657: the white plate, the flat (200,220,240) header
## fill, the six REAL HANDLING..SHOOTING button plates — the exact six labels the filters
## need — plus the label-free neutral plate for NAME / SORT BY / CLEAR / CLOSE) and the
## SCOUT screen's own pale-blue criteria fields + enabled arrows (61/67). The panel sits at
## the dialog's own witnessed screen origin (67,63). The scene draws only live text, in the
## screen's fonts and the donors' own inks. The consts below mirror the baker's layout
## + (67,63); change them together.
const OURS_PANEL := Rect2(67, 63, 458, 289)
const OURS_BAND := Rect2(91, 73, 410, 15)        # title fill (LBLUE, panel-wide)
const OURS_NAME_PLATE := Rect2(91, 103, 82, 26)
const OURS_NAME_FIELD := Rect2(183, 108, 220, 16)
const OURS_ROW_YS := [141, 175, 209]             # attr plate tops; spinners at +5
const OURS_COL_ARROW_L := [179, 395]             # per column (i % 2)
const OURS_COL_FIELD_X := [197, 413]
const OURS_COL_ARROW_R := [248, 464]
const OURS_FIELD_W := 49
const OURS_ARROW := Vector2(16, 16)
const OURS_SORT_PLATE := Rect2(91, 247, 82, 26)
const OURS_SORT_L := Vector2(179, 252)
const OURS_SORT_FIELD := Rect2(197, 252, 125, 16)
const OURS_SORT_R := Vector2(324, 252)
const OURS_CLEAR := Rect2(331, 309, 82, 26)
const OURS_CLOSE := Rect2(423, 309, 82, 26)
const OURS_NOTE_X := 91
const OURS_MSG_TY := 279                         # shortfall line
const OURS_NOTE_TY := 291                        # honesty note, line 1
const OURS_NOTE2_TY := 303                       # honesty note, line 2 (left of CLEAR)
const OURS_SORTS := [["name", "NAME"], ["av", "AV"], ["mo", "MO"], ["fee", "CLUB FEE"],
	["wage", "WAGE"], ["age", "AGE"]]
# Panel inks — every one sampled from the donor frames, none invented:
const C_OURS_TITLE := Color8(0, 0, 190)      # the dialog header-band's own text ink
const C_OURS_LBL := Color8(85, 223, 255)     # the skill plates' own label cyan
const C_OURS_NOTE := Color8(128, 128, 128)   # the screen's own border grey

const POSITIONS := ["GOALKEEPER", "DEFENDER", "MIDFIELDER", "FORWARD"]  # getter table PTR@0x662d10 (binary-exact)
const POS_KEYS := ["GK", "DF", "MF", "FW"]
# AGE / QUALITY / PRICE are BAND dropdowns in the original, NOT numeric spinners.
# Labels + order lifted binary-exact from the MANAGER.EXE scout getter tables
# (arrays of string pointers indexed by the dropdown position):
#   AGE     @0x661e08 (5 bands)
#   QUALITY @0x661e20 (7 bands, on the 0-99 ability/AV scale)
#   PRICE   @0x661e40 (10 bands, in K)
const AGE_BANDS := ["17-22", "23-26", "27-30", "31-33", "+33"]
const QUALITY_BANDS := ["50-65", "66-70", "71-75", "76-80", "81-85", "86-90", "+90"]
const PRICE_BANDS := ["10 - 75 K.", "80 - 125 K.", "130 - 250 K.", "250 - 500 K.",
	"500 - 1,500 K.", "1,500 - 3,000 K.", "3,000 - 5,000 K.", "5,000 - 7,500 K.",
	"7,500 - 10,000 K.", "+ 10,000 K."]

# ---- PLAYERS FOUND list (scout_chrome.json row1 anchors) -------------------
const ROW_X0 := 33
const ROW_X1 := 473
const ROW_Y0 := 297          # first row top border
const ROW_PITCH := 16
const N_ROWS := 8
const PLUS_XY := Vector2(11, -1)      # plus.png offset vs row border y (icon body x11..33; x6..10 is the marble bevel, per-row texture)
const FLAG_XY := Vector2(36, 2)       # mini flag vs row border y (Filan witness)
const NAME_X := 53
const STARS_X := 159
const STAR_PITCH := 14
const CELL_AV_CX := 246.0
const CELL_MO_CX := 271.5
const CELL_FEE_CX := 318.5
const CELL_WAGE_CX := 388.5
const CELL_Y1_CX := 435.5
const CELL_Y2_CX := 460.5
const VERTS := [233, 258, 283, 353, 423, 448]  # in-row cell separators
const Y2_CELL := Rect2(449, 1, 24, 12)         # LEFT cell fill vs row border y
const HEADERS_XY := Vector2(50, 284)
const SEARCHING_XY := Vector2(120, 336)
const SB_X := 478                     # scroll column left
const SB_TRACK_Y0 := 313              # slider track top (below up arrow)
const SB_TRACK_Y1 := 407              # track bottom (= down arrow top)
const SB_DN_Y := 407

# ---- scout strip -----------------------------------------------------------
const STRIP_NAME_X := 64
const STRIP_NAME_TY := 91
const STRIP_STAR_X := 171
const STRIP_STAR_PITCH := 11
const STRIP_WAGE_CX := 270.0
const STRIP_WAGE_TY := 96

# ---- inks (bake samples; the TransferScreen family) ------------------------
const C_NAME := Color8(0, 0, 0)
const C_AV := Color8(212, 63, 0)
const C_MO := Color8(75, 109, 172)
const C_FEE := Color8(210, 0, 0)
const C_WAGE := Color8(150, 0, 0)
const C_YEARS := Color8(42, 63, 170)
const C_Y2_FILL := Color8(255, 255, 170)
const C_Y2_INK := Color8(255, 31, 0)
const C_ROW_BORDER := Color8(128, 128, 128)
const C_ROW_FILL := Color8(240, 240, 240)
const C_GAP := Color8(150, 150, 150)

# ---- live barra anchors (the transfer-screen barra, same frame family) -----
const BARRA_MGR_CX := 52
const BARRA_MGR_BASE := 26
const BARRA_CLUB_BASE := 44
const BARRA_CREST := Rect2(112, 14, 28, 33)
const SHEET_CX := 483
const SHEET_WD_BASE := 24
const SHEET_DAY_BASE := 35
const SHEET_MON_BASE := 44
const SHEET_YR_BASE := 55
const C_SHEET_DAY := Color8(255, 0, 0)
const C_SHEET_YEAR := Color8(42, 95, 170)
const BAND_CX := 580
const BAND1_BASE := 26
const BAND2_BASE := 44

var _chrome: Texture2D
var _noscout: Texture2D
var _led_on: Texture2D
var _armed: Texture2D
var _searching_tex: Texture2D
var _headers: Texture2D
var _plus: Texture2D
var _star_full: Texture2D
var _star_half: Texture2D
var _sb_up_off: Texture2D
var _sb_dn_on: Texture2D
var _sb_slider: Texture2D
var _arrow_l: Texture2D
var _arrow_r: Texture2D
var _ours_panel_tex: Texture2D   # the frame-baked OURS panel plate (ours_panel.png)
var _f8: Font
var _f10: Font
var _f12: Font

var _has_scout := false
var _scout_name := ""
var _scout_stars := 0.0
var _scout_wage := 0
var _searching := false
var _results: Array = []
var _first := 0                  # scroll offset into _results
var _tog := {"pos": false, "age": false, "role": false, "quality": false, "price": false}
var _leagues := {"eng_prem": false, "eng_div1": false, "eng_div2": false, "eng_div3": false}
var _regions := {"eu": false, "non_eu": false, "no_team": false}
var _pos_idx := 0
var _age_idx := 0                # index into AGE_BANDS
var _role := 1                   # posFine 1..18 (PlayerInfoScreen.FINE_ROLE)
var _quality_idx := 0            # index into QUALITY_BANDS
var _price_idx := 0              # index into PRICE_BANDS
var _armed_flash := false        # SEARCH ring, shown on the arming tap (witness 68)
# ---- OURS panel state ------------------------------------------------------
var _ours_open := false
var _name_edit: LineEdit
var _attr_idx := {}              # attr code -> index into Career.SCOUT_ATTR_STOPS, -1 = off
var _sort_i := -1                # index into OURS_SORTS, -1 = the scan order (the default)
var _sort_desc := true
var _found_total := 0            # pre-cap match count (Career.scout_found_total)
var _instant := false            # the shown rows came from the instant name lookup
var _alert_img: Texture2D        # options alert (PMAlert render); null = none
var _hover_row := -1             # the row under the finger (the original's rollover), -1 none
var _press := ""
var _row_flag_cache := {}

# barra
var _manager := ""
var _club := ""
var _season := ""
var _week := 0
var _league := ""
var _club_id := -1


func _ready() -> void:
	_chrome = load("res://art/screens/scout/chrome.png")
	_noscout = load("res://art/screens/scout/noscout_patch.png")
	_led_on = load("res://art/screens/scout/led_on.png")
	_armed = load("res://art/screens/scout/search_armed.png")
	_searching_tex = load("res://art/screens/scout/searching_text.png")
	_headers = load("res://art/screens/scout/headers.png")
	_plus = load("res://art/screens/scout/plus.png")
	_star_full = load("res://art/screens/scout/star_full.png")
	_star_half = load("res://art/screens/scout/star_half.png")
	_sb_up_off = load("res://art/screens/scout/scroll_up_off.png")
	_sb_dn_on = load("res://art/screens/scout/scroll_dn_on.png")
	_sb_slider = load("res://art/screens/scout/scroll_slider.png")
	_arrow_l = load("res://art/screens/scout/arrow_l_on.png")
	_arrow_r = load("res://art/screens/scout/arrow_r_on.png")
	_ours_panel_tex = load("res://art/screens/scout/ours_panel.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for e in Career.SCOUT_ATTR_FILTERS:
		_attr_idx[str(e[0])] = -1
	_build_name_edit()
	resized.connect(_reposition_name)
	gui_input.connect(_on_input)
	queue_redraw()


## The OURS name box. A real LineEdit so Android raises its own keyboard (the
## SeleccionScreen / SaveGameDialog precedent); hidden unless the panel is open.
## It sits on the BAKED pale-blue field plate (SaveGameDialog's frame-cell
## precedent), so its own boxes are empty and its ink is the field's black.
func _build_name_edit() -> void:
	_name_edit = LineEdit.new()
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "part of a surname"
	_name_edit.visible = false
	_name_edit.add_theme_font_override("font", _f10)
	_name_edit.add_theme_font_size_override("font_size", 11)
	_name_edit.add_theme_color_override("font_color", C_NAME)
	_name_edit.add_theme_color_override("font_placeholder_color", C_OURS_NOTE)
	_name_edit.add_theme_color_override("caret_color", C_NAME)
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 4
	for st in ["normal", "focus", "read_only"]:
		_name_edit.add_theme_stylebox_override(st, sb)
	# OURS (Mats, 2026-07-27): every keystroke IS the search — an instant lookup
	# over the decoded database, no scout run, no other filter. Enter drops the
	# keyboard and the panel so the hits are fully visible.
	_name_edit.text_changed.connect(func(t: String) -> void:
		name_search.emit(t.strip_edges())
		queue_redraw())
	_name_edit.text_submitted.connect(func(_t: String) -> void:
		_activate("ours_close"))
	add_child(_name_edit)
	_reposition_name()


func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _reposition_name() -> void:
	if _name_edit == null:
		return
	var s := _scale()
	_name_edit.position = _origin(s) + OURS_NAME_FIELD.position * s
	_name_edit.size = OURS_NAME_FIELD.size * s
	_name_edit.add_theme_font_size_override("font_size", maxi(8, int(11 * s)))


## scout = the hired Staff SCOUT member ({} = none); searching/results = the
## Career async state. Barra args follow the TransferScreen setup shape.
func setup(scout: Dictionary, searching: bool, results: Array, club: String,
		manager := "", season := "", week := 0, league := "", club_id := -1,
		found_total := -1) -> void:
	_found_total = found_total if found_total >= 0 else results.size()
	_has_scout = not scout.is_empty()
	_scout_name = str(scout.get("name", ""))
	_scout_stars = float(scout.get("stars", 0.0))
	_scout_wage = int(scout.get("wage", 0))
	_searching = searching
	_results = results
	_first = 0
	for rk in _regions:                # a weaker scout drops the regions he can't reach
		if _regions[rk] and not region_enabled(rk):
			_regions[rk] = false
	_armed_flash = false
	_instant = false
	_club = club
	_manager = manager
	_season = season
	_week = week
	_league = league
	_club_id = club_id
	queue_redraw()


## Re-arm every criteria widget from a dict `criteria()` produced. The original keeps
## the panel exactly as you left it — the scout's report does not wipe the form (Mats
## QA 2026-08-01) — but a fresh ScoutScreen node is built on every entry, so the state
## has to be restored from the career. `{}` leaves the defaults alone; unknown keys are
## ignored, so an older save's smaller dict restores what it does carry.
func restore_criteria(c: Dictionary) -> void:
	if c.is_empty():
		return
	var pos := str(c.get("pos", ""))
	_tog["pos"] = pos != ""
	if _tog["pos"] and POS_KEYS.has(pos):
		_pos_idx = POS_KEYS.find(pos)
	var role := int(c.get("role", 0))
	_tog["role"] = role > 0
	if _tog["role"]:
		_role = role
	for pair in [["age", "age_band"], ["quality", "quality_band"], ["price", "price_band"]]:
		var band := int(c.get(str(pair[1]), -1))
		_tog[str(pair[0])] = band >= 0
		if band >= 0:
			match str(pair[0]):
				"age": _age_idx = band
				"quality": _quality_idx = band
				"price": _price_idx = band
	for lid in _leagues:
		_leagues[lid] = (c.get("leagues", []) as Array).has(lid)
	# A scout downgraded since the search can no longer reach every region; setup()
	# re-applies that filter after this call, so a stale box cannot survive it.
	_regions["eu"] = bool(c.get("eu", false))
	_regions["non_eu"] = bool(c.get("non_eu", false))
	_regions["no_team"] = bool(c.get("no_team", false))
	_attr_idx = {}
	var stops: Array = Career.SCOUT_ATTR_STOPS
	for code in c.get("attr_min", {}):
		var i := stops.find(int((c["attr_min"] as Dictionary)[code]))
		if i >= 0:
			_attr_idx[code] = i
	if _name_edit != null:
		_name_edit.text = str(c.get("name", ""))


func criteria() -> Dictionary:
	var leagues: Array = []
	for lid in _leagues:
		if _leagues[lid]:
			leagues.append(lid)
	# age/quality/price are BAND indices; -1 = off (index 0 is a valid band, so 0 can't mean off)
	# `name` + `attr_min` are OURS (empty / {} = the original's behaviour exactly).
	var attr_min := {}
	for code in _attr_idx:
		var i := int(_attr_idx[code])
		if i >= 0:
			attr_min[code] = int(Career.SCOUT_ATTR_STOPS[i])
	return {
		"pos": POS_KEYS[_pos_idx] if _tog["pos"] else "",
		"role": _role if _tog["role"] else 0,
		"age_band": _age_idx if _tog["age"] else -1,
		"quality_band": _quality_idx if _tog["quality"] else -1,
		"price_band": _price_idx if _tog["price"] else -1,
		"leagues": leagues,
		"eu": bool(_regions["eu"]),
		"non_eu": bool(_regions["non_eu"]),
		"no_team": bool(_regions["no_team"]),
		"name": _name_edit.text.strip_edges() if _name_edit != null else "",
		"attr_min": attr_min,
	}


## The rows in display order. OURS: with no sort picked this is the Career scan order,
## i.e. exactly what the screen showed before the sort selector existed.
func view_rows() -> Array:
	if _sort_i < 0 or _results.is_empty():
		return _results
	var key := str(OURS_SORTS[_sort_i][0])
	var rows: Array = _results.duplicate()
	var desc := _sort_desc
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av: Variant = a.get(key, 0)
		var bv: Variant = b.get(key, 0)
		if av is String or bv is String:
			var c := str(av).naturalcasecmp_to(str(bv))
			return c > 0 if desc else c < 0
		return float(av) > float(bv) if desc else float(av) < float(bv))
	return rows


## OURS: the instant name lookup landed — show it as a normal result set. A
## pending mission keeps ticking in Career and overwrites these rows when it
## lands; `_searching` is dropped locally so the rows are visible NOW.
func apply_instant_results(rows: Array, total: int) -> void:
	_results = rows
	_found_total = total
	_searching = false
	_instant = true
	_first = 0
	queue_redraw()


## Can the hired scout reach this region? (REGION_STARS, live-measured — see above.)
func region_enabled(key: String) -> bool:
	return _has_scout and _scout_stars >= float(REGION_STARS.get(key, 99.0))


# ---- input -----------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	if _alert_img != null:
		return "alert_ok"     # any tap answers the alert's OK (single-button box)
	if _ours_open:
		return _hit_ours(d)
	if BTN_RETURN.has_point(d):
		return "return"
	if BTN_EXTRA.has_point(d) and _has_scout:
		return "ours_open"
	if not _has_scout:
		return ""
	if BTN_SEARCH.has_point(d) and not _searching:
		return "search"
	for k in LED:
		if Rect2(LED[k] - Vector2(2, 2), LED_SIZE + Vector2(4, 4)).has_point(d):
			return "tog:" + k
	for lid in LED_LEAGUE:
		if Rect2(LED_LEAGUE[lid] - Vector2(2, 2), LED_SIZE + Vector2(4, 4)).has_point(d):
			return "league:" + lid
	for rk in LED_REGION:
		if Rect2(LED_REGION[rk] - Vector2(2, 2), LED_SIZE + Vector2(4, 4)).has_point(d):
			return ("region:" + rk) if region_enabled(rk) else ""
	for k in ARROWS:
		if ARROWS[k].has_point(d):
			return "arrow:" + k
	if not _results.is_empty() and not _searching:
		var r := _row_at(d)
		if r >= 0:
			return "row:%d" % r
		if d.x >= SB_X and d.x <= SB_X + 16:
			if d.y >= ROW_Y0 and d.y < SB_TRACK_Y0:
				return "scroll_up"
			if d.y >= SB_DN_Y and d.y <= SB_DN_Y + 16:
				return "scroll_dn"
	return ""


## OURS panel hit map. A tap outside the panel closes it, so it can never trap the user.
## Geometry mirrors the ours_panel.png bake: 2 columns x 3 rows of attribute spinners
## (column = i % 2, row = i / 2), then the SORT row and the two plate buttons.
func _hit_ours(d: Vector2) -> String:
	if not OURS_PANEL.has_point(d):
		return "ours_close"
	if OURS_CLOSE.has_point(d):
		return "ours_close"
	if OURS_CLEAR.has_point(d):
		return "ours_clear"
	for i in Career.SCOUT_ATTR_FILTERS.size():
		@warning_ignore("integer_division")
		var y: float = OURS_ROW_YS[i / 2] + 5
		var c := i % 2
		if Rect2(OURS_COL_ARROW_L[c], y, OURS_ARROW.x, OURS_ARROW.y).has_point(d):
			return "ours_attr_l:%d" % i
		if Rect2(OURS_COL_ARROW_R[c], y, OURS_ARROW.x, OURS_ARROW.y).has_point(d):
			return "ours_attr_r:%d" % i
	if Rect2(OURS_SORT_L, OURS_ARROW).has_point(d):
		return "ours_sort_l"
	if Rect2(OURS_SORT_R, OURS_ARROW).has_point(d):
		return "ours_sort_r"
	if d.y >= OURS_SORT_FIELD.position.y - 2 and d.y < OURS_SORT_FIELD.position.y + 18 \
			and d.x > OURS_SORT_R.x + OURS_ARROW.x:
		return "ours_sort_dir"
	return "ours_none"


func _row_at(d: Vector2) -> int:
	if d.x < ROW_X0 or d.x > ROW_X1:
		return -1
	for i in mini(N_ROWS, _results.size() - _first):
		var top := ROW_Y0 + i * ROW_PITCH
		if d.y >= top and d.y <= top + 13:
			return _first + i
	return -1


func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		pos = (e as InputEventMouseButton).position
		pressed = (e as InputEventMouseButton).pressed
		tap = true
	elif e is InputEventScreenTouch:
		pos = (e as InputEventScreenTouch).position
		pressed = (e as InputEventScreenTouch).pressed
		tap = true
	if not tap:
		return
	var a := _hit(_to_design(pos))
	if pressed:
		_press = a
		# the rollover: held on a row = the original's pointer over that row
		_hover_row = int(a.substr(4)) if a.begins_with("row:") else -1
		if _hover_row >= 0:
			queue_redraw()
		return
	var was := _press
	_press = ""
	if _hover_row >= 0:
		_hover_row = -1
		queue_redraw()
	if a == "" or a != was:
		return
	_activate(a)


func _activate(a: String) -> void:
	match a:
		"alert_ok":
			_alert_img = null
			PMChrome.set_dim(false)
			queue_redraw()
			return
		"return":
			back_pressed.emit()
			return
		"search":
			_try_search()
			return
		"ours_open", "ours_close":
			_ours_open = a == "ours_open"
			if _name_edit != null:
				_name_edit.visible = _ours_open
				if _ours_open:
					_reposition_name()
					_name_edit.grab_focus()
				else:
					_name_edit.release_focus()
			queue_redraw()
			return
		"ours_none":
			return
		"ours_clear":
			for code in _attr_idx:
				_attr_idx[code] = -1
			if _name_edit != null:
				_name_edit.text = ""
			_sort_i = -1
			queue_redraw()
			return
		"ours_sort_l", "ours_sort_r":
			var dr := -1 if a.ends_with("_l") else 1
			_sort_i = wrapi(_sort_i + dr, -1, OURS_SORTS.size())
			queue_redraw()
			return
		"ours_sort_dir":
			_sort_desc = not _sort_desc
			queue_redraw()
			return
		"scroll_up":
			_first = maxi(0, _first - 1)
			queue_redraw()
			return
		"scroll_dn":
			_first = clampi(_first + 1, 0, maxi(0, _results.size() - N_ROWS))
			queue_redraw()
			return
	if a.begins_with("ours_attr_"):
		var dirn := -1 if a.begins_with("ours_attr_l") else 1
		var ai := int(a.split(":")[1])
		var code := str(Career.SCOUT_ATTR_FILTERS[ai][0])
		# -1 (off) sits below stop 0, so one step left off the bottom turns the filter off.
		_attr_idx[code] = wrapi(int(_attr_idx[code]) + dirn, -1, Career.SCOUT_ATTR_STOPS.size())
		queue_redraw()
	elif a.begins_with("tog:"):
		var k := a.substr(4)
		_tog[k] = not _tog[k]
		_armed_flash = false
		queue_redraw()
	elif a.begins_with("league:"):
		var lid := a.substr(7)
		_leagues[lid] = not _leagues[lid]
		_armed_flash = false
		queue_redraw()
	elif a.begins_with("region:"):
		var rk := a.substr(7)
		if region_enabled(rk):
			_regions[rk] = not _regions[rk]
			_armed_flash = false
			queue_redraw()
	elif a.begins_with("arrow:"):
		_spin(a.substr(6))
		queue_redraw()
	elif a.begins_with("row:"):
		var i := int(a.substr(4))
		var rows := view_rows()          # the tap indexes what is DRAWN, not the scan order
		if i < rows.size():
			player_pressed.emit(rows[i])


func _spin(k: String) -> void:
	var dirn := -1 if k.ends_with("_l") else 1
	match k.substr(0, k.length() - 2):
		"pos":
			if _tog["pos"]:
				_pos_idx = wrapi(_pos_idx + dirn, 0, POSITIONS.size())
		"role":
			if _tog["role"]:
				_role = wrapi(_role + dirn, 1, PlayerInfoScreen.FINE_ROLE.size() + 1)
		"age":
			if _tog["age"]:
				_age_idx = wrapi(_age_idx + dirn, 0, AGE_BANDS.size())
		"quality":
			if _tog["quality"]:
				_quality_idx = wrapi(_quality_idx + dirn, 0, QUALITY_BANDS.size())
		"price":
			if _tog["price"]:
				_price_idx = wrapi(_price_idx + dirn, 0, PRICE_BANDS.size())


## The witnessed validation (64/66): at least one LEFT-column criteria toggle
## must be ON — league checkboxes alone do not count.
func _try_search() -> void:
	var any_tog := false
	for k in _tog:
		if _tog[k]:
			any_tog = true
	# MANAGER.EXE 0x557a84: the search needs >= 1 LEFT-column criterion AND >= 1 of the
	# seven region boxes (four divisions + E.U. / NON E.U. / WITHOUT TEAM). Witnessed
	# 2026-07-18 for the "leagues alone" half (frames 64/66 refused a Premier-only tap).
	var any_region := false
	for lid in _leagues:
		if _leagues[lid]:
			any_region = true
	for rk in _regions:
		if _regions[rk]:
			any_region = true
	if not any_tog or not any_region:
		# OURS: with a NAME typed and nothing else, SEARCH is the instant lookup —
		# the hits are already on screen from typing; re-fire and skip the refusal
		# (the witnessed alert stays the answer for a truly empty tap).
		var nm := _name_edit.text.strip_edges() if _name_edit != null else ""
		if nm != "":
			name_search.emit(nm)
			queue_redraw()
			return
		_alert_img = ImageTexture.create_from_image(
			PMAlert.render("You have to select some options to make the search."))
		PMChrome.set_dim(true)
		queue_redraw()
		return
	_armed_flash = true
	_searching = true
	_results = []
	_instant = false
	queue_redraw()
	search_started.emit(criteria())


# ---- helpers ---------------------------------------------------------------

## The witnessed digit-centring grammar (insurance decode): monospace advance 8
## ("1" -> 5), px = floor(CX - tw/2).
func _digits(cx: float, ty: int, s: String, ink: Color) -> void:
	var tw := 0
	for ch in s:
		tw += 5 if ch == "1" else 8
	var px := int(floor(cx - tw / 2.0))
	for ch in s:
		PMChrome.text(self, _f8, px, ty, ch, ink, 11, 0)
		px += 5 if ch == "1" else 8


func _txt_center(f: Font, cx: float, ty: float, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	PMChrome.text(self, f, cx - w * 0.5, ty, s, col, sz, 0)


func _txt_base_center(f: Font, cx: int, baseline: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, baseline), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## Star glyph blits. The sprites carry a 1px lead margin from the frame cut
## (full cut at x158 for ink x159; half at x200 for ink x201) — blitting at
## STARS_X-1 + pitch lands the ink on the witnessed columns exactly.
func _stars(x: float, y: float, rating: float) -> void:
	var full := int(rating)
	var half := rating - full >= 0.5
	for i in full:
		if _star_full != null:
			draw_texture(_star_full, Vector2(x - 1.0 + i * STAR_PITCH, y))
	if half and _star_half != null:
		# witnessed on 3.5 (81 row 1, half ink x201 = the 14 pitch)
		draw_texture(_star_half, Vector2(x - 1.0 + full * STAR_PITCH, y))


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	var s: float = minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _chrome != null:
		draw_texture(_tex(_chrome), Vector2.ZERO)
	_draw_barra()

	if not _has_scout:
		# the witnessed 43 body: washed criteria + strip + gate text, verbatim
		if _noscout != null:
			draw_texture(_tex(_noscout), Vector2(0, 62))
		_draw_alert()
		return

	_draw_strip()
	for k in LED:
		if _tog[k] and _led_on != null:
			draw_texture(_tex(_led_on), LED[k])
	for lid in LED_LEAGUE:
		if _leagues[lid] and _led_on != null:
			draw_texture(_tex(_led_on), LED_LEAGUE[lid])
	for rk in LED_REGION:
		if _regions[rk] and _led_on != null:
			draw_texture(_tex(_led_on), LED_REGION[rk])
	for tk in ["pos", "role", "age", "quality", "price"]:
		if _tog[tk] and _arrow_l != null:
			draw_texture(_arrow_l, ARROWS[tk + "_l"].position)
			draw_texture(_arrow_r, ARROWS[tk + "_r"].position)
	if _tog["pos"]:
		_txt_center(_f10, DROP_POS.position.x + DROP_POS.size.x * 0.5,
			DROP_POS.position.y + 3, POSITIONS[_pos_idx], PMChrome.dim_col(C_NAME), 11)
	if _tog["role"]:
		var role_name := str(PlayerInfoScreen.FINE_ROLE[_role - 1]).to_upper()
		_txt_center(_f10, DROP_ROLE.position.x + DROP_ROLE.size.x * 0.5,
			DROP_ROLE.position.y + 3, role_name, PMChrome.dim_col(C_NAME), 10)
	if _tog["age"]:
		_txt_center(_f10, SPIN_AGE.position.x + SPIN_AGE.size.x * 0.5,
			SPIN_AGE.position.y + 3, AGE_BANDS[_age_idx], PMChrome.dim_col(C_NAME), 11)
	if _tog["quality"]:
		_txt_center(_f10, SPIN_QUALITY.position.x + SPIN_QUALITY.size.x * 0.5,
			SPIN_QUALITY.position.y + 3, QUALITY_BANDS[_quality_idx], PMChrome.dim_col(C_NAME), 11)
	if _tog["price"]:
		_txt_center(_f10, SPIN_PRICE.position.x + SPIN_PRICE.size.x * 0.5,
			SPIN_PRICE.position.y + 3, PRICE_BANDS[_price_idx], PMChrome.dim_col(C_NAME), 10)
	if _armed_flash and _armed != null:
		draw_texture(_tex(_armed), Vector2(516, 209))

	if _searching and _searching_tex != null:
		draw_texture(_tex(_searching_tex), SEARCHING_XY)
	elif not _results.is_empty():
		_draw_results()
	_draw_bar()
	if _ours_open:
		_draw_ours()
	_draw_alert()


## The bottom bar. The original's rollover readout when a row is held, and otherwise the door
## to the OURS panel — see the BAR_* note at the top of this file for the evidence and the
## exact measurements.
func _draw_bar() -> void:
	var row := rollover_row()
	if not row.is_empty():
		var cid := int(row.get("club_id", -1))
		var kit := PMChrome.ridi_kit(cid) if cid >= 0 else null
		if kit != null:
			draw_texture(_tex(kit), BAR_KIT_XY)
		_bar_text(BAR_CX_A, PMChrome.card_name(row))
		_bar_text(BAR_CX_B, str(row.get("club_name", "")))
		return
	# ---- OURS: the door label, only in the state the original leaves blank --------------
	# Before this the bar was blank grey with no label of any kind, so the search additions
	# were unreachable in practice — Mats: "I don't see the new search objects" (approved
	# 2026-07-26). Face and ink are the readout's own: proman8 at 11 px in black, on the
	# bar's own (220,220,220) interior. No new font, no new colour, nothing outside the two
	# segments.
	if not _has_scout:
		return
	_bar_text(BAR_CX_A, EXTRA_LABEL)
	var n := extra_filters_active()
	var state := "CLOSE" if _ours_open else ("TAP HERE" if n == 0 else "%d ACTIVE" % n)
	_bar_text(BAR_CX_B, state, C_NAME if n > 0 or _ours_open else C_ROW_BORDER)


## One bar segment's text, in the original's own grammar: proman8 at 11 px, pen top 446, pen x
## FLOORED off the segment centre (see BAR_CX_A / BAR_CX_B). `col` defaults to the readout's
## own black; the only other value it ever takes is the bar's OWN border grey (128,128,128),
## for the door's unset state — neither is a new colour on this screen.
func _bar_text(cx: float, s: String, col := C_NAME) -> void:
	if s.strip_edges().is_empty() or _f8 == null:
		return
	if _alert_img != null:
		col = PMAlert.dim_color(col)
	var w := _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	PMChrome.text(self, _f8, floorf(cx - w * 0.5), BAR_TEXT_TY, s, col, 11)


## The row the bar reads out: the one under the finger. `{}` = none, which is every state the
## original leaves the bar empty in (no results, a modal up, the pointer elsewhere).
func rollover_row() -> Dictionary:
	if _alert_img != null or _ours_open or _searching or _hover_row < 0:
		return {}
	var rows := view_rows()
	if _hover_row >= rows.size():
		return {}
	return rows[_hover_row]


## How many of the OURS filters are set — the number segment B reports, so a filter that is
## silently narrowing the results can never be invisible ([[feedback_no_silent_failures]]).
func extra_filters_active() -> int:
	var n := 0
	if _name_edit != null and not _name_edit.text.strip_edges().is_empty():
		n += 1
	for k in _attr_idx:
		if int(_attr_idx[k]) >= 0:
			n += 1
	if _sort_i >= 0:
		n += 1
	return n


## Chrome/sprites under the options alert swap to their LUT-dimmed copies
## (the witnessed whole-frame palette dim; InsuranceScreen precedent).
func _tex(t: Texture2D) -> Texture2D:
	return PMAlert.dim_texture(t) if _alert_img != null and t != null else t


func _draw_alert() -> void:
	if _alert_img == null:
		return
	var r := PMAlert.box_rect("You have to select some options to make the search.")
	draw_texture(_alert_img, Vector2(r.position))


var _strip_star: Texture2D
var _strip_stars3: Texture2D

func _draw_strip() -> void:
	if _scout_name != "":
		PMChrome.text(self, _f8, STRIP_NAME_X, STRIP_NAME_TY + 3,
			PMChrome.title_case_name(_scout_name), Color.WHITE, 11)
	if _strip_star == null:
		_strip_star = load("res://art/screens/scout/strip_star.png")
		_strip_stars3 = load("res://art/screens/scout/strip_stars3.png")
	var full := int(_scout_stars)
	if _scout_stars == 3.0 and _strip_stars3 != null:
		# the witnessed 3-star zone verbatim (incl drop shadows)
		draw_texture(_strip_stars3, Vector2(168, 90))
	elif _strip_star != null:
		for i in full:
			draw_texture(_strip_star, Vector2(170 + i * STRIP_STAR_PITCH, 92))
		if _scout_stars - full >= 0.5 and _star_half != null:
			draw_texture(_star_half, Vector2(170 + full * STRIP_STAR_PITCH, 92))
	if _scout_wage > 0:
		_txt_center(_f8, STRIP_WAGE_CX, STRIP_WAGE_TY,
			TransferScreen.fmt_money(_scout_wage), Color.WHITE, 11)


func _draw_results() -> void:
	if _headers != null:
		draw_texture(_tex(_headers), HEADERS_XY)
	var rows := view_rows()
	var shown := mini(N_ROWS, rows.size() - _first)
	for i in shown:
		_draw_row(rows[_first + i], ROW_Y0 + i * ROW_PITCH)
	if rows.size() > N_ROWS:
		_draw_scrollbar()
	# the rollover frame, measured on p0279 vs p0283 (the same list, a different row held):
	# 2 px black over x32..474, y (top-1)..(top+14) — it replaces the grey 1 px border and
	# takes one row of the white gap above and below.
	if _hover_row >= _first and _hover_row < _first + shown:
		var top := ROW_Y0 + (_hover_row - _first) * ROW_PITCH
		var col := PMAlert.dim_color(C_NAME) if _alert_img != null else C_NAME
		var w := ROW_X1 - ROW_X0 + 3          # x32..474 inclusive
		draw_rect(Rect2(ROW_X0 - 1, top - 1, w, 2), col, true)
		draw_rect(Rect2(ROW_X0 - 1, top + 13, w, 2), col, true)
		draw_rect(Rect2(ROW_X0 - 1, top + 1, 2, 12), col, true)
		draw_rect(Rect2(ROW_X1, top + 1, 2, 12), col, true)


# ---- the OURS panel --------------------------------------------------------

## The panel is the frame-baked plate; this draws ONLY live text over it, in the
## screen's own fonts and the donor chrome's own inks (see the OURS consts note).
func _draw_ours() -> void:
	if _ours_panel_tex != null:
		draw_texture(_ours_panel_tex, OURS_PANEL.position)
	_txt_center(_f10, OURS_BAND.position.x + OURS_BAND.size.x * 0.5,
		OURS_BAND.position.y + 2, "EXTRA SEARCH FILTERS", C_OURS_TITLE, 11)
	_plate_label(OURS_NAME_PLATE, "NAME")
	for i in Career.SCOUT_ATTR_FILTERS.size():
		var idx := int(_attr_idx[str(Career.SCOUT_ATTR_FILTERS[i][0])])
		@warning_ignore("integer_division")
		var fy: float = OURS_ROW_YS[i / 2] + 5
		var c := i % 2
		_txt_center(_f8, OURS_COL_FIELD_X[c] + OURS_FIELD_W * 0.5, fy + 3,
			("MIN %d" % int(Career.SCOUT_ATTR_STOPS[idx])) if idx >= 0 else "ANY",
			C_NAME if idx >= 0 else C_OURS_NOTE, 11)
	_plate_label(OURS_SORT_PLATE, "SORT BY")
	var sort_txt := "SCOUT'S ORDER" if _sort_i < 0 else str(OURS_SORTS[_sort_i][1])
	_txt_center(_f8, OURS_SORT_FIELD.position.x + OURS_SORT_FIELD.size.x * 0.5,
		OURS_SORT_FIELD.position.y + 3, sort_txt, C_NAME if _sort_i >= 0 else C_OURS_NOTE, 11)
	if _sort_i >= 0:
		PMChrome.text(self, _f8, OURS_SORT_R.x + OURS_ARROW.x + 10,
			OURS_SORT_FIELD.position.y + 3, "HIGH-LOW" if _sort_desc else "LOW-HIGH", C_NAME, 11)
	_plate_label(OURS_CLEAR, "CLEAR")
	_plate_label(OURS_CLOSE, "CLOSE")
	# The shortlist shortfall. The CAP is the engine's ((quality+2)*5, FUN_00575750) and it
	# discards at random; saying so out loud is ours, because a silent trim would read as
	# "that is all there was" ([[feedback_no_silent_failures]]).
	var msg := ""
	if _searching:
		msg = "The scout is still out."
	elif _results.is_empty():
		msg = "No search has come back yet."
	elif _instant and _found_total > _results.size():
		msg = "%d of %d shown - type more of the name." % [_results.size(), _found_total]
	elif _found_total > _results.size():
		msg = "%d of %d shown - your scout could only bring back %d." % [
			_results.size(), _found_total, _results.size()]
	else:
		msg = "%d found, all shown." % _results.size()
	PMChrome.text(self, _f8, OURS_NOTE_X, OURS_MSG_TY, msg, C_NAME, 9)
	PMChrome.text(self, _f8, OURS_NOTE_X, OURS_NOTE_TY,
		"MIN = at least. Not in the original game - added on request.", C_OURS_NOTE, 9)
	PMChrome.text(self, _f8, OURS_NOTE_X, OURS_NOTE2_TY,
		"Scout cap: (stars x 2 + 2) x 5 names.", C_OURS_NOTE, 9)


## A label on one of the baked neutral button plates, in the plates' own cyan.
func _plate_label(r: Rect2, s: String) -> void:
	_txt_center(_f8, r.position.x + r.size.x * 0.5, r.position.y + 8, s, C_OURS_LBL, 11)


func _draw_row(r: Dictionary, top: int) -> void:
	# box: 1px borders + fill + the witnessed cell verticals
	draw_rect(Rect2(ROW_X0, top, ROW_X1 - ROW_X0 + 1, 1), C_ROW_BORDER, true)
	draw_rect(Rect2(ROW_X0, top + 13, ROW_X1 - ROW_X0 + 1, 1), C_ROW_BORDER, true)
	draw_rect(Rect2(ROW_X0, top + 1, 1, 12), C_ROW_BORDER, true)
	draw_rect(Rect2(ROW_X1, top + 1, 1, 12), C_ROW_BORDER, true)
	draw_rect(Rect2(ROW_X0 + 1, top + 1, ROW_X1 - ROW_X0 - 1, 12), C_ROW_FILL, true)
	for vx in VERTS:
		draw_rect(Rect2(vx, top + 1, 1, 12), C_ROW_BORDER, true)
	if _plus != null:
		draw_texture(_tex(_plus), Vector2(PLUS_XY.x, top + PLUS_XY.y))
	# non-EU-1997 flag (the insurance-witnessed rule; Filan witnessed here at
	# (35, top+1), 22x12 — witness-cut sprite per code, MINIBAND scaled fallback)
	if not str(r.get("nationality", "")) in InsuranceScreen.EU_1997:
		var code: Variant = r.get("flagCode")
		if code != null:
			var fl := _row_flag(int(code))
			if fl != null:
				draw_texture(_tex(fl), Vector2(35, top + 1))
			else:
				var mf := PMChrome.mini_flag(code)
				if mf != null:
					draw_texture_rect(_tex(mf), Rect2(36, top + 2, 20, 10), false)
	var ty := top + 2
	PMChrome.text(self, _f12, NAME_X, top + 2,
		PMChrome.title_case_name(str(r.get("name", "?"))), C_NAME, 11)
	_stars(STARS_X, top + 1.0, clampf(int(r.get("ca", 0)) / 20.0, 0.0, 5.0))
	_digits(CELL_AV_CX, ty, str(int(r.get("av", 0))), C_AV)
	var mo := int(r.get("mo", -1))
	if mo >= 0:
		_digits(CELL_MO_CX, ty, str(mo), C_MO)
	else:
		_digits(CELL_MO_CX, ty, "-", C_GAP)
	_txt_center(_f8, CELL_FEE_CX, ty, TransferScreen.fmt_money(int(r.get("fee", 0))), C_FEE, 9)
	_txt_center(_f8, CELL_WAGE_CX, ty, TransferScreen.fmt_money(int(r.get("wage", 0))), C_WAGE, 9)
	var years := int(r.get("years", 0))
	var left := int(r.get("left", 0))
	if left == 1:
		draw_rect(Rect2(Y2_CELL.position.x, top + Y2_CELL.position.y,
			Y2_CELL.size.x, Y2_CELL.size.y), C_Y2_FILL, true)
	_digits(CELL_Y1_CX, ty, str(years) if years > 0 else "-", C_YEARS if years > 0 else C_GAP)
	_digits(CELL_Y2_CX, ty, str(left) if left > 0 else "-",
		(C_Y2_INK if left == 1 else C_YEARS) if left > 0 else C_GAP)


## Witness-cut row flag ({} fallback -> null); cached — an unheld texture
## loaded inside _draw frees before the frame flushes and renders white.
func _row_flag(code: int) -> Texture2D:
	if not _row_flag_cache.has(code):
		var fp := "res://art/screens/scout/flag_%d.png" % code
		_row_flag_cache[code] = load(fp) if ResourceLoader.exists(fp) else null
	return _row_flag_cache[code]


## The insurance slider formula (h = floor(track*visible/total), off =
## floor(track*first/total)) — reproduces the witnessed 18px slider (81:
## 8 visible of the ~40 Premier GKs).
func _draw_scrollbar() -> void:
	if _first > 0 and _sb_dn_on != null:
		# enabled-up is un-witnessed (81 sits at the top) -> vflip of the
		# enabled down arrow, pattern-derived (insurance precedent)
		draw_texture_rect(_sb_dn_on, Rect2(SB_X, ROW_Y0 + 16, 16, -16), false)
	elif _sb_up_off != null:
		draw_texture(_sb_up_off, Vector2(SB_X, ROW_Y0))
	var track := SB_TRACK_Y1 - SB_TRACK_Y0
	var total := _results.size()
	var h := maxi(4, int(floor(track * float(N_ROWS) / total)))
	var off := int(floor(track * float(_first) / total))
	if off > 0:
		draw_rect(Rect2(SB_X, SB_TRACK_Y0, 16, off), Color8(120, 140, 160), true)
	if _sb_slider != null:
		draw_texture_rect(_sb_slider, Rect2(SB_X, SB_TRACK_Y0 + off, 16, h), false)
	draw_rect(Rect2(SB_X, SB_TRACK_Y0 + off + h, 16,
		maxi(0, track - off - h)), Color8(120, 140, 160), true)
	if _first + N_ROWS < total and _sb_dn_on != null:
		draw_texture(_sb_dn_on, Vector2(SB_X, SB_DN_Y))


func _draw_barra() -> void:
	var f8 := PMChrome.font("8")
	var f10 := PMChrome.font("10")
	var f12 := PMChrome.font("12")
	if _manager != "":
		_txt_base_center(f12, BARRA_MGR_CX, BARRA_MGR_BASE, _manager, Color.BLACK, 12)
	_txt_base_center(f12, BARRA_MGR_CX, BARRA_CLUB_BASE, _club, Color.WHITE, 12)
	if _club_id >= 0:
		PMChrome.draw_crest(self, _club_id, BARRA_CREST)
	if _week > 0:
		var d := PMChrome.header_date if not PMChrome.header_date.is_empty() \
			else PMChrome.date_parts(_season, _week)
		_txt_base_center(f8, SHEET_CX, SHEET_WD_BASE, str(d["wd"]), Color.BLACK, 9)
		_txt_base_center(f12, SHEET_CX, SHEET_DAY_BASE, str(d["day"]), C_SHEET_DAY, 14)
		_txt_base_center(f8, SHEET_CX, SHEET_MON_BASE, str(d["mon"]), Color.BLACK, 9)
		_txt_base_center(f8, SHEET_CX, SHEET_YR_BASE, str(d["year"]), C_SHEET_YEAR, 9)
	var top_txt := "Preseason" if PMChrome.header_phase == "preseason" \
		else PMChrome._band_league(_league)
	_txt_base_center(f10, BAND_CX, BAND1_BASE, top_txt, Color.BLACK, 11)
	var bot_txt := ""
	if PMChrome.header_phase == "preseason":
		bot_txt = "Preparation"
	elif _week > 0:
		bot_txt = "Week %d" % _week
	if bot_txt != "":
		_txt_base_center(f12, BAND_CX, BAND2_BASE, bot_txt, Color.WHITE, 11)
