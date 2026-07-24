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

signal back_pressed
signal search_started(criteria: Dictionary)
signal player_pressed(row: Dictionary)

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
var _alert_img: Texture2D        # options alert (PMAlert render); null = none
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
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## scout = the hired Staff SCOUT member ({} = none); searching/results = the
## Career async state. Barra args follow the TransferScreen setup shape.
func setup(scout: Dictionary, searching: bool, results: Array, club: String,
		manager := "", season := "", week := 0, league := "", club_id := -1) -> void:
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
	_club = club
	_manager = manager
	_season = season
	_week = week
	_league = league
	_club_id = club_id
	queue_redraw()


func criteria() -> Dictionary:
	var leagues: Array = []
	for lid in _leagues:
		if _leagues[lid]:
			leagues.append(lid)
	# age/quality/price are BAND indices; -1 = off (index 0 is a valid band, so 0 can't mean off)
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
	}


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
	if BTN_RETURN.has_point(d):
		return "return"
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
		return
	var was := _press
	_press = ""
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
		"scroll_up":
			_first = maxi(0, _first - 1)
			queue_redraw()
			return
		"scroll_dn":
			_first = clampi(_first + 1, 0, maxi(0, _results.size() - N_ROWS))
			queue_redraw()
			return
	if a.begins_with("tog:"):
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
		if i < _results.size():
			player_pressed.emit(_results[i])


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
		_alert_img = ImageTexture.create_from_image(
			PMAlert.render("You have to select some options to make the search."))
		PMChrome.set_dim(true)
		queue_redraw()
		return
	_armed_flash = true
	_searching = true
	_results = []
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
	_draw_alert()


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
	var shown := mini(N_ROWS, _results.size() - _first)
	for i in shown:
		_draw_row(_results[_first + i], ROW_Y0 + i * ROW_PITCH)
	if _results.size() > N_ROWS:
		_draw_scrollbar()


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
