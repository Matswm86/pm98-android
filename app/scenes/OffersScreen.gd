extends Control
class_name OffersScreen
## PM98 OFFERS (map browse) screen — frame-true from run-3 frames 098/099/100/
## 119 + wine witnesses 44/45/46/47 (docs/re/offers_map_re.md). Static chrome =
## frame 098 baked verbatim (England + Premier selected + empty 14-row grid +
## AV/ROL headers + division buttons + RETURN) with the barra text interiors
## blanked and the managed-club kit cell restored solid —
## tools/re/build_offers_chrome_from_frames.py.
##
## The LEFT column (EUROPA map + 47 baked flags, EUROPE/S.AMERICA tabs, country
## strip, kit panel) is pixel-identical to the PRESEASON chrome (match 1.000);
## this scene mirrors PreseasonScreen's proven machinery: flag tap -> strip
## name + enlarged flag; kit panel switches ONLY for a browsable country;
## kit tap -> gold OVER cell + squad list + name label (strip clears, 46);
## division buttons filter the kit grid (England only — foreign countries blit
## the button-free backdrop, 45).
##
## RIGHT panel: club title (navy, CX 485), squad rows = the club's record order
## REVERSED (witnessed 28/28), display number = the .DBC slot byte (<=16
## as-is: XI 1-11 + bench 12-16; >=17 renumbered in record order — the
## witness-proven rule, club_tactics.json squadSlots), stars (frame-cut
## glyphs), AV = floor((VE+RE+AG+CA)/4) (28/28 exact), ROL = the game's own
## camrol{posFine} sprite 1:1 at x587 (100.0% pixel match). Row tap -> the
## make-offer card (witness 47 = MakeOfferScreen; Main routes the buy through
## sign_player for own-division clubs, sign_external otherwise).
##
## EVERY COUNTRY IS BROWSABLE — corrected 2026-07-25 against the real game. The old
## ">= 16 clubs" rule came from two frames (walkthrough 015 HUNGARY, 119 MACEDONIA)
## where the strip named a country but the kit panel stayed on England. Those frames
## are a HOVER readout, not a click: 016 (2 s later, no further input) shows the strip
## already cleared and the panel still England. A live sweep of the real MANAGER.EXE
## preseason map — all 47 European flags plus all 10 S.American ones, ENGLAND re-tapped
## between each — switched the panel EVERY time, MACEDONIA's one club included
## (screenshots/wine-captures-2026-07-25-offers-map-countries/). The gate is deleted;
## a country is browsable iff GameDB holds any club for it.
##
## MODEL RULES: the browse shows the static GameDB squads (the app's living league
## covers only the manager's division; buys route through the live roster where one
## exists). Star rating mapping un-RE'd (parity-excluded, FICHA precedent).
## First/Third Division SELECTED faces are synthesized (un-witnessed).

signal back_pressed
signal player_pressed(player: Dictionary, club: Dictionary)

const W := 640
const H := 480

# ---- left column (the preseason-shared geometry) ---------------------------
const R_TAB_EU := Rect2(3, 78, 21, 112)
const R_TAB_SA := Rect2(3, 190, 21, 112)
const R_MAP := Rect2(27, 80, 300, 220)
const R_STRIP := Rect2(7, 304, 322, 22)
const R_PANEL := Rect2(8, 336, 321, 130)
const KIT_X0 := 13
const KIT_PITCH := 31
const KIT_Y := [368, 405]
const PANEL_TITLE_TOP := 346    # pen TOP row of the panel's country title
const PANEL_TITLE_FIELD := 336  # GDI centring field sum (4 country witnesses, exact)
const LAST_PICK_TOP := 449      # pen TOP row of the picked club's name (witness 46)
const C_TITLE_BLUE := Color8(0, 0, 160)
const C_PRESS := Color(1, 1, 1, 0.2)
const C_LAST_PICK := Color8(120, 120, 160)

# ---- right panel -----------------------------------------------------------
const LIST_TITLE_CX := 485.0
const LIST_TITLE_TY := 81
const ROW_X0 := 342
const ROW_X1 := 586
const ROW_Y0 := 105            # first row top border
const ROW_PITCH := 16
const N_ROWS := 14
const NUM_CX := 354.5
const NAME_X := 380
const STARS_X := 488
const STAR_PITCH := 13
const AV_CX := 575.0           # "48"/"80" ink x567.. -> digit-centring centre
const CAMROL_X := 587
const SB_X := 615
const SB_UP_Y := 105
const SB_TRACK_Y0 := 121
const SB_TRACK_Y1 := 311
const SB_DN_Y := 311
const C_NUM := Color8(0, 0, 128)
const C_NAME := Color8(0, 0, 0)
const C_AV := Color8(212, 63, 0)

# ---- division buttons + RETURN ---------------------------------------------
const BTN_X := 362
const BTN_W := 118
const BTN_TOPS := [345, 375, 405, 435]
const BTN_H := 28
const NO_BUTTONS_XY := Vector2(358, 340)
const BTN_RETURN := Rect2(517, 437, 110, 28)

# ---- live barra anchors (the transfer-family barra) ------------------------
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
var _map_sa: Texture2D
var _tab_eu_off: Texture2D
var _tab_sa_on: Texture2D
var _over: Texture2D
var _btn := {}                 # "prem_sel"/"prem_off"/... -> Texture2D
var _no_buttons: Texture2D
var _sb_up_off: Texture2D
var _sb_dn_on: Texture2D
var _sb_dn_off: Texture2D
var _sb_slider: Texture2D
var _row_strip: Texture2D
var _checker: Texture2D
var _f8: Font
var _f10: Font
var _f12: Font

var _markers: Array = []
var _markers_sa: Array = []
var _tactics: Dictionary = {}  # club_tactics.json clubs (display numbers)

var _tab := 0
var _country := "ENGLAND"
var _country_clubs: Array = []
var _div := 0
var _strip_country := ""
var _sel_flag: Dictionary = {}
var _sel_tab := 0
var _sel_club_i := -1
var _squad_club: Dictionary = {}
var _rows: Array = []          # display rows {player, num}
var _first := 0
var _last_pick := ""
var _press := ""

var _leagues: Array = []
var _clubs_of: Callable
var _clubs_of_country: Callable
var _managed_id := -1
var _hidden: Dictionary = {}   # pid -> true (my roster + external_signed)

# barra
var _manager := ""
var _club := ""
var _season := ""
var _week := 0
var _league := ""
var _club_id := -1


func _ready() -> void:
	_chrome = load("res://art/screens/offers/chrome.png")
	_map_sa = load("res://art/screens/pretemp/sudamerica.png")
	if ResourceLoader.exists("res://art/screens/pretemp/sudamerica_flags.png"):
		_map_sa = load("res://art/screens/pretemp/sudamerica_flags.png")
	_tab_eu_off = load("res://art/screens/pretemp/tab_eu_off.png")
	_tab_sa_on = load("res://art/screens/pretemp/tab_sa_on.png")
	_over = load("res://art/screens/pretemp/over.png")
	for k in ["prem_sel", "prem_off", "first_sel", "first_off", "second_sel",
			"second_off", "third_sel", "third_off"]:
		var p := "res://art/screens/offers/btn_%s.png" % k
		if ResourceLoader.exists(p):
			_btn[k] = load(p)
	_no_buttons = load("res://art/screens/offers/no_buttons_bg.png")
	_sb_up_off = load("res://art/screens/offers/scroll_up_off.png")
	_sb_dn_on = load("res://art/screens/offers/scroll_dn_on.png")
	_sb_dn_off = load("res://art/screens/offers/scroll_dn_off.png")
	_sb_slider = load("res://art/screens/offers/scroll_slider.png")
	_row_strip = load("res://art/screens/offers/row_strip.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	var ci := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	ci.set_pixel(0, 0, Color.WHITE)
	ci.set_pixel(1, 1, Color.WHITE)
	_checker = ImageTexture.create_from_image(ci)
	var f := FileAccess.open("res://data/pretemp_flag_markers.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_markers = parsed.get("markers", [])
	var fsa := FileAccess.open("res://data/pretemp_flag_markers_sa.json", FileAccess.READ)
	if fsa != null:
		var parsed_sa: Variant = JSON.parse_string(fsa.get_as_text())
		if typeof(parsed_sa) == TYPE_DICTIONARY:
			_markers_sa = parsed_sa.get("markers", [])
	var ft := FileAccess.open("res://data/club_tactics.json", FileAccess.READ)
	if ft != null:
		var parsed_t: Variant = JSON.parse_string(ft.get_as_text())
		if typeof(parsed_t) == TYPE_DICTIONARY:
			_tactics = parsed_t.get("clubs", {})
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## leagues/clubs_of/clubs_of_country follow the PreseasonScreen bridge shape.
## `own_div` = the manager's England division index (the fresh-open selection;
## witnessed only for Premier managers — model rule). `hidden` = pids already
## in the manager's squad or bought via sign_external (filtered from rows).
func setup(leagues: Array, clubs_of: Callable, clubs_of_country: Callable,
		own_div: int, managed_id: int, hidden: Dictionary, club: String,
		manager := "", season := "", week := 0, league := "", club_id := -1) -> void:
	_leagues = leagues
	_clubs_of = clubs_of
	_clubs_of_country = clubs_of_country
	_managed_id = managed_id
	_hidden = hidden
	_div = clampi(own_div, 0, 3)
	_club = club
	_manager = manager
	_season = season
	_week = week
	_league = league
	_club_id = club_id
	_select_england()
	queue_redraw()


## A successful buy hides the player from the browse (the rows rebuild keeps
## the ORIGINAL numbering — computed before the drop).
func setup_refresh_hidden(pid: int) -> void:
	_hidden[pid] = true
	if not _squad_club.is_empty():
		_rows = _build_rows(_squad_club)
		_first = clampi(_first, 0, maxi(0, _rows.size() - N_ROWS))
	queue_redraw()


func _select_england() -> void:
	_country = "ENGLAND"
	_country_clubs = []
	if _div < _leagues.size() and _clubs_of.is_valid():
		_country_clubs = _clubs_of.call(str(_leagues[_div].get("id", "")))
		# ENGLAND sorts, and that is not a stylistic choice: witness 44 (the resting
		# Premier panel) is 0 px only with this sort, and removing it costs 899 px.
		# FOREIGN countries do NOT sort -- witness 45's Spain grid is the archive's own
		# record order (Barcelona = EQ96001.DBC first). The two are genuinely different
		# in the original; see `_act`'s country branch and offers_map_re.md.
		_country_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


# ---- geometry --------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()

## ALWAYS the fixed 2x10 grid: witness 45 shows Spain's 21-club list on 10
## columns (20 kits shown; ink starts 13/45/77/109/139/171/203/235/267/299 =
## the (c*95)/3 integer pitch exactly). Overflow clubs are unreachable here —
## the original's own clipping.
func _kit_cols() -> int:
	return 10

func _kit_rect(i: int) -> Rect2:
	var c := i % 10
	@warning_ignore("integer_division")
	var x: float = KIT_X0 - 1 + (c * 95) / 3
	@warning_ignore("integer_division")
	return Rect2(x, KIT_Y[i / 10] - 2, 26, 36)

func _flag_at(d: Vector2) -> Dictionary:
	for m in (_markers if _tab == 0 else _markers_sa):
		if Rect2(float(m["x"]) - 1, float(m["y"]) - 1, 20, 15).has_point(d):
			return m
	return {}


# ---- the display-number rule (offers_map_re.md, witnessed 28/28) -----------

## Row list for a club: record order REVERSED; number = slot byte <= 16 as-is,
## else 17.. renumbered in record order. Hidden pids (my squad / already
## bought) drop out; the numbering is computed BEFORE the drop so the visible
## numbers stay the original's.
func _build_rows(club: Dictionary) -> Array:
	var players: Array = club.get("players", [])
	var slots: Array = []
	var tc: Dictionary = _tactics.get(str(int(club.get("id", -1))), {})
	for s in tc.get("squadSlots", []):
		slots.append(int(s))
	var nums: Array = []
	var nxt := 17
	for i in players.size():
		var s := int(slots[i]) if i < slots.size() else 99
		if s <= 16:
			nums.append(s)
		else:
			nums.append(nxt)
			nxt += 1
	var out: Array = []
	for i in range(players.size() - 1, -1, -1):
		var p: Dictionary = players[i]
		if _hidden.has(int(p.get("id", -1))):
			continue
		out.append({"player": p, "num": nums[i] if i < nums.size() else 0})
	return out


# ---- input -----------------------------------------------------------------

func _target_at(d: Vector2) -> String:
	if BTN_RETURN.has_point(d):
		return "return"
	if R_TAB_EU.has_point(d):
		return "tab:0"
	if R_TAB_SA.has_point(d):
		return "tab:1"
	if _country == "ENGLAND":
		for i in 4:
			if i < _leagues.size() and Rect2(BTN_X, BTN_TOPS[i], BTN_W, BTN_H).has_point(d):
				return "div:%d" % i
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		if _kit_rect(i).has_point(d):
			return "kit:%d" % i
	if not _flag_at(d).is_empty():
		return "flag:%s" % str(_flag_at(d)["name"])
	if not _rows.is_empty():
		var r := _row_at(d)
		if r >= 0:
			return "row:%d" % r
		if d.x >= SB_X and d.x <= SB_X + 16:
			if d.y >= SB_UP_Y and d.y < SB_TRACK_Y0:
				return "scroll_up"
			if d.y >= SB_DN_Y and d.y <= SB_DN_Y + 16:
				return "scroll_dn"
	return ""


func _row_at(d: Vector2) -> int:
	if d.x < ROW_X0 or d.x > ROW_X1:
		return -1
	for i in mini(N_ROWS, _rows.size() - _first):
		var top := ROW_Y0 + i * ROW_PITCH
		if d.y >= top and d.y <= top + 13:
			return _first + i
	return -1


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _target_at(d):
		return
	_route_target(was)


## Act on a confirmed tap target ("flag:NAME" / "kit:N" / "row:N" / "div:N" / ...).
## Split out of _on_input so the headless tests can drive the same routing.
func _route_target(was: String) -> void:
	match was:
		"return":
			back_pressed.emit()
			return
		"tab:0":
			_tab = 0
			queue_redraw()
			return
		"tab:1":
			_tab = 1
			queue_redraw()
			return
		"scroll_up":
			_first = maxi(0, _first - 1)
			queue_redraw()
			return
		"scroll_dn":
			_first = clampi(_first + 1, 0, maxi(0, _rows.size() - N_ROWS))
			queue_redraw()
			return
	if was.begins_with("div:"):
		_div = int(was.substr(4))
		_select_england()
		queue_redraw()
	elif was.begins_with("flag:"):
		var nm := was.substr(5)
		# Strip name + enlarged flag, and the kit panel switches to that country's
		# clubs. EVERY country switches — there is NO minimum-club gate (live sweep
		# 2026-07-25, all 47 European + 10 S.American flags clicked on a real
		# MANAGER.EXE preseason map; MACEDONIA's single club loads exactly like
		# SPAIN's twenty). See the class doc for how the old ">= 16" rule arose.
		_strip_country = nm
		for m in (_markers if _tab == 0 else _markers_sa):
			if str(m["name"]) == nm:
				_sel_flag = m
				_sel_tab = _tab
		if nm == "ENGLAND":
			_select_england()
		else:
			var cc: Array = _clubs_of_country.call(nm) if _clubs_of_country.is_valid() else []
			if not cc.is_empty():
				_country = nm
				# NO SORT. The grid is the ARCHIVE's own record order, which is what
				# `clubs_in_country` already hands back (EQUIPOS entry order ==
				# EQ96NNNN.DBC order == the app's club ids). Witness 45's Spain panel
				# reads Barcelona, Deportivo, Zaragoza, Real Madrid, Athletic, ...
				# = idx 0,1,2,3,4 — while an alphabetical sort put Athletic first, which
				# is where the panel's whole-grid permutation came from.
				_country_clubs = cc
				_sel_club_i = -1
		queue_redraw()
	elif was.begins_with("kit:"):
		var i := int(was.substr(4))
		if i < _country_clubs.size():
			_sel_club_i = i
			_squad_club = _country_clubs[i]
			_rows = _build_rows(_squad_club)
			_first = 0
			_last_pick = PMChrome.title_case_name(str(_squad_club.get("name", "")))
			# the strip clears + the enlarged flag reverts on a club tap (46)
			_strip_country = ""
			_sel_flag = {}
			queue_redraw()
	elif was.begins_with("row:"):
		var r := int(was.substr(4))
		if r < _rows.size():
			player_pressed.emit(_rows[r]["player"], _squad_club)


# ---- helpers ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int,
		cw := 0.0, center := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## The witnessed digit-centring grammar (advance 8, "1" -> 5, px = floor(CX -
## tw/2)) — AV "69" lands ink x238 exactly; the shirt numbers centre on CX 354.
func _digits(cx: float, ty: int, s: String, ink: Color) -> void:
	var tw := 0
	for ch in s:
		tw += 5 if ch == "1" else 8
	var px := int(floor(cx - tw / 2.0))
	for ch in s:
		PMChrome.text(self, _f8, px, ty, ch, ink, 11, 0)
		px += 5 if ch == "1" else 8


var _star_full: Texture2D
var _star_half: Texture2D

func _stars(x: float, y: float, rating: float) -> void:
	if _star_full == null:
		_star_full = load("res://art/screens/scout/star_full.png")
		_star_half = load("res://art/screens/scout/star_half.png")
	var full := int(rating)
	var half := rating - full >= 0.5
	for i in full:
		if _star_full != null:
			draw_texture(_star_full, Vector2(x - 1.0 + i * STAR_PITCH, y))
	if half and _star_half != null:
		# the witnessed half-star spacing (scout 81 rows 1/5): pitch 13 here
		draw_texture(_star_half, Vector2(x - 1.0 + full * STAR_PITCH, y))


func _txt_base_center(f: Font, cx: int, baseline: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, baseline), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	_draw_barra()

	# S.AMERICA tab active: the real SA map + tab strips (preseason art)
	if _tab == 1:
		if _map_sa != null:
			draw_texture_rect(_map_sa, R_MAP, false)
		if _tab_eu_off != null:
			draw_texture_rect(_tab_eu_off, R_TAB_EU, false)
		if _tab_sa_on != null:
			draw_texture_rect(_tab_sa_on, R_TAB_SA, false)

	# enlarged selected flag (frame 015 grammar; reverts on club tap — 45/46).
	# Witness-cut whole plaque (border+flag) for codes a frame shows (Spain 45)
	if _sel_tab == _tab and not _sel_flag.is_empty():
		var fx := float(_sel_flag["x"]) - 8.0
		var fy := float(_sel_flag["y"]) - 4.0
		var big := _big_flag(int(_sel_flag["code"]))
		if big != null:
			draw_texture(big, Vector2(fx - 1, fy - 1))
		else:
			draw_rect(Rect2(fx - 1, fy - 1, 32, 22), Color(0, 0, 0), true)
			var ftex := PMChrome.flag(int(_sel_flag["code"]))
			if ftex != null:
				draw_texture(ftex, Vector2(fx, fy))
	if _press.begins_with("flag:"):
		for m in (_markers if _tab == 0 else _markers_sa):
			if _press == "flag:%s" % str(m["name"]):
				draw_rect(Rect2(float(m["x"]) - 1, float(m["y"]) - 1, 20, 15), C_PRESS, true)

	# country strip: baked empty; names the last-tapped flag (45/119)
	if _strip_country != "":
		_txt(_f12, R_STRIP.position.x, R_STRIP.position.y + 5, _strip_country,
			Color.WHITE, 13, R_STRIP.size.x, true)

	_draw_kit_panel()

	if _last_pick != "":
		# Same grammar as the panel title, two rows lower: proman10, GDI-centred on
		# field sum 336, pen top 449 -- probe_text_anchor on witness 46 returns
		# pen_x 117 / advance 102 for "F.C. Barcelona", i.e. 2*117 + 102 = 336 exactly.
		# The pen top had been 447.
		var padv := _f10.get_string_size(_last_pick, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_txt(_f10, floor((PANEL_TITLE_FIELD - padv) * 0.5), LAST_PICK_TOP,
			_last_pick, C_LAST_PICK, 10)

	_draw_buttons()
	_draw_list()

	for key_r in [["return", BTN_RETURN], ["tab:0", R_TAB_EU], ["tab:1", R_TAB_SA]]:
		if _press == str(key_r[0]):
			draw_rect(key_r[1], C_PRESS, true)


## Kit panel: baked ENGLAND/Premier resting; repaint on any change. The gold
## OVER cell marks the selected club (46); the managed club's kit washes
## (checker / frame-proven patch — 44-vs-098 witness pair).
func _draw_kit_panel() -> void:
	var dirty := _country != "ENGLAND" or _div != 0 or _sel_club_i >= 0
	if dirty:
		draw_rect(Rect2(R_PANEL.position + Vector2(2, 2), R_PANEL.size - Vector2(4, 4)),
			Color.WHITE, true)
		if _country != "":
			# Solved off FOUR country witnesses with `tools/re/probe_text_anchor.py`
			# (identical-bitmap match, so this is read not chosen): the panel title is
			# **proman10 @10**, pen top **346**, GDI-centred on FIELD SUM 336 --
			# pen_x = floor((336 - advance) / 2). SPAIN adv 43 -> 146, MACEDONIA 85 ->
			# 125, HUNGARY 69 -> 133, SWEDEN 60 -> 138, all four exact. It had been
			# proman12 @13 centred on the panel rect, landing 4 px left and 4 px high.
			var tadv := _f10.get_string_size(_country, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			_txt(_f10, floor((PANEL_TITLE_FIELD - tadv) * 0.5), PANEL_TITLE_TOP,
				_country, C_TITLE_BLUE, 10)
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		var kr := _kit_rect(i)
		var cid := int(_country_clubs[i].get("id", -1))
		var washed := cid == _managed_id
		if dirty:
			var tex2: Texture2D = null
			var need_checker := false
			if washed:
				tex2 = PMChrome.panel_kit(cid, "washed")
				if tex2 == null:
					tex2 = PMChrome.nano_kit(cid)
					need_checker = true
			else:
				tex2 = PMChrome.panel_kit(cid, "panel13")
				if tex2 == null:
					tex2 = PMChrome.nano_kit(cid)
			if tex2 != null:
				draw_texture(tex2, kr.position + Vector2(1, 2))
				if need_checker and _checker != null:
					draw_texture_rect(_checker, kr, true)
		elif washed:
			# resting chrome bakes every kit SOLID — wash the live managed club
			var wtex := PMChrome.panel_kit(cid, "washed")
			if wtex != null:
				draw_texture(wtex, kr.position + Vector2(1, 2))
			elif _checker != null:
				draw_texture_rect(_checker, kr, true)
		if i == _sel_club_i and _over != null:
			draw_texture(_over, kr.position)
		if _press == "kit:%d" % i:
			draw_rect(kr, C_PRESS, true)


## Division buttons: England = per-state faces blitted over the baked set
## (Premier-selected baked); a foreign country blits the button-free backdrop
## (45). First/Third selected faces are synthesized (documented).
func _draw_buttons() -> void:
	if _country != "ENGLAND":
		if _no_buttons != null:
			draw_texture(_no_buttons, NO_BUTTONS_XY)
		return
	var keys := ["prem", "first", "second", "third"]
	for i in 4:
		var st := "%s_%s" % [keys[i], "sel" if _div == i else "off"]
		var t: Texture2D = _btn.get(st)
		if t != null:
			draw_texture(t, Vector2(BTN_X, BTN_TOPS[i]))
		if _press == "div:%d" % i:
			draw_rect(Rect2(BTN_X, BTN_TOPS[i], BTN_W, BTN_H), C_PRESS, true)


func _draw_list() -> void:
	if _sel_club_i < 0 or _rows.is_empty():
		return
	var tstr := PMChrome.title_case_name(str(_squad_club.get("name", "")))
	var tw := _f12.get_string_size(tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(_f12, Vector2(LIST_TITLE_CX + 0.5 - tw * 0.5,
		LIST_TITLE_TY + 1 + _f12.get_ascent(13)), tstr,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_TITLE_BLUE)
	var shown := mini(N_ROWS, _rows.size() - _first)
	for i in shown:
		_draw_row(_rows[_first + i], _first + i, ROW_Y0 + i * ROW_PITCH)
	_draw_scrollbar()


func _draw_row(r: Dictionary, idx: int, top: int) -> void:
	var p: Dictionary = r["player"]
	# populated-row furniture (witness row strip: the x562 name/AV separator +
	# the camrol cell frame the empty grid lacks)
	if _row_strip != null:
		draw_texture(_row_strip, Vector2(ROW_X0, top))
	var ty := top + 2
	_digits(NUM_CX, ty, str(int(r["num"])), C_NUM)
	PMChrome.text(self, _f12, NAME_X, top + 2,
		PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, 11)
	var a: Dictionary = p.get("attrs", {})
	var av := int((int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0))
		+ int(a.get("CA", 0))) / 4.0)
	_stars(STARS_X, top + 1, clampf(int(a.get("CA", 0)) / 20.0, 0.0, 5.0))
	_digits(AV_CX, ty, str(av), C_AV)
	var pf := int(p.get("posFine", 0))
	if pf >= 1 and pf <= 18:
		var cam: Texture2D = _camrol(pf)
		if cam != null:
			draw_texture(cam, Vector2(CAMROL_X, top))
	# NON-NATIONAL foreigner flag in the number cell (witness 46: exactly the
	# four Barcelona NON-NATIONALs carry the 20x14 flag at (360, row top)).
	# Witness-cut sprites for the seen codes; MINIBAND scaled for the rest
	# (documented approximation).
	if str(p.get("kind", "")) == "NON-NATIONAL":
		var code: Variant = p.get("flagCode")
		if code != null:
			var fl := _mid_flag(int(code))
			if fl != null:
				draw_texture(fl, Vector2(360, top))
			else:
				var mf := PMChrome.mini_flag(code)
				if mf != null:
					draw_texture_rect(mf, Rect2(360, top, 20, 14), false)
	if _press == "row:%d" % idx:
		# the witnessed pressed-row black ring (100 Brabin: y216..231 rows,
		# side columns x341..342 + x611..612 — spans the camrol cell too)
		draw_rect(Rect2(341, top - 1, 272, 2), Color.BLACK, true)
		draw_rect(Rect2(341, top + 13, 272, 2), Color.BLACK, true)
		draw_rect(Rect2(341, top - 1, 2, 16), Color.BLACK, true)
		draw_rect(Rect2(611, top - 1, 2, 16), Color.BLACK, true)


var _camrol_cache := {}
var _mid_flag_cache := {}
var _big_flag_cache := {}

func _big_flag(code: int) -> Texture2D:
	if not _big_flag_cache.has(code):
		var fp := "res://art/screens/offers/flag_big/%d.png" % code
		_big_flag_cache[code] = load(fp) if ResourceLoader.exists(fp) else null
	return _big_flag_cache[code]

## Witness-cut number-cell flag for a code ({} fallback -> null). Cached — a
## texture loaded inside _draw with no held reference frees before the frame
## flushes and renders WHITE.
func _mid_flag(code: int) -> Texture2D:
	if not _mid_flag_cache.has(code):
		var fp := "res://art/screens/offers/flag_mid/%d.png" % code
		_mid_flag_cache[code] = load(fp) if ResourceLoader.exists(fp) else null
	return _mid_flag_cache[code]

## Witnessed list-cell camrols first (cut from the browse frames — the icons
## bank's fine-7/13 dots differ from this list's rendering); icons bank as the
## fallback for un-witnessed fines.
func _camrol(pf: int) -> Texture2D:
	if not _camrol_cache.has(pf):
		var wp := "res://art/screens/offers/camrol/%02d.png" % pf
		if ResourceLoader.exists(wp):
			_camrol_cache[pf] = load(wp)
		else:
			_camrol_cache[pf] = load("res://art/icons/camrol/camrol%02d.png" % pf)
	return _camrol_cache[pf]


func _draw_scrollbar() -> void:
	var total := _rows.size()
	if total <= N_ROWS:
		return
	if _first > 0 and _sb_dn_on != null:
		# enabled-up un-witnessed (both witnesses at top) -> vflip, documented
		draw_texture_rect(_sb_dn_on, Rect2(SB_X, SB_UP_Y + 16, 16, -16), false)
	elif _sb_up_off != null:
		draw_texture(_sb_up_off, Vector2(SB_X, SB_UP_Y))
	var track := SB_TRACK_Y1 - SB_TRACK_Y0
	var h := maxi(6, int(floor(track * float(N_ROWS) / total)))
	var off := int(floor(track * float(_first) / total))
	if off > 0:
		draw_rect(Rect2(SB_X, SB_TRACK_Y0, 16, off), Color8(120, 140, 160), true)
	if _sb_slider != null:
		# the game STAMPS one noise texture from the slider's top (46-vs-100
		# shared rows identical) -> crop the witnessed sprite to h-3 and close
		# it with the sprite's OWN bottom cap (shadow row + 2px black border)
		var sh := float(_sb_slider.get_height())
		var srch := minf(h - 3.0, sh - 3.0)
		draw_texture_rect_region(_sb_slider, Rect2(SB_X, SB_TRACK_Y0 + off, 16, srch),
			Rect2(0, 0, 16, srch))
		draw_texture_rect_region(_sb_slider,
			Rect2(SB_X, SB_TRACK_Y0 + off + h - 3, 16, 3), Rect2(0, sh - 3, 16, 3))
	draw_rect(Rect2(SB_X, SB_TRACK_Y0 + off + h, 16, maxi(0, track - off - h)),
		Color8(120, 140, 160), true)
	if _first + N_ROWS < total and _sb_dn_on != null:
		draw_texture(_sb_dn_on, Vector2(SB_X, SB_DN_Y))
	elif _sb_dn_off != null:
		draw_texture(_sb_dn_off, Vector2(SB_X, SB_DN_Y))


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
