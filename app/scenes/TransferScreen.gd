extends Control
class_name TransferScreen
## PM98 TRANSFER MARKET (FICHAR) screen, rebuilt FRAME-TRUE from the real walkthrough
## (screenshots/original-walkthrough-2026-07-02/097_164707.png — the screen reached
## hub -> TRANSFERS; frame 093 shows the "TRANSFER MARKET" hub region holding
## TRANSFERS/PLAYERS/STAFF), following the PreseasonScreen / FinanceScreen frame-bake
## precedent.
##
## The static chrome is the ORIGINAL frame's pixels, cut 1:1 by
## tools/re/build_transfer_chrome_from_frames.py into art/screens/transfer/chrome.png
## with ONLY the dynamic list body blanked. This scene draws that chrome at 640x480,
## redraws the live barra (PMChrome.draw_header) and the buyable rows on top — nothing
## about the panel, the AV/MO/CLUB FEE/WAGE/YEARS column headers, the scrollbar, the
## CURRENT OFFERS / SCOUT / OFFERS / RETURN nav buttons or the stadium background is
## hand-invented.
##
## Row (frame 097): [+] expand box | (nationality flag) | Name | gold stars |
## AV(red) | MO(blue) | CLUB FEE(red) | WAGE(dark-red) | YEARS|LEFT (two navy cells,
## yellow on the final year). The four BLUE position bands are SINGULAR:
## KEEPER / DEFENDER / MIDFIELDER / FORWARD, fixed [3,5,5,5] slots each (DAT_0065c020),
## dearest first; unfilled slots stay blank. The 18-row cap always fits the panel, so
## the frame's scrollbar is inert baked art (never actually scrolls).
##
## FRAME-TRUE: layout, labels, band names, colours, [+] box, nav chrome, background.
## EVERY VALUE CELL IS NOW SOURCE-BACKED (the four "honest gaps"/"approximations" this
## header used to list are closed, 2026-07-23):
##   AV       core4 >> 2                     FUN_00534570 (transfer_value_re.md §1)
##   stars    halves = (AV+1) div 10         star drawer FUN_004f79b0 (morale_re.md)
##   MO       displayed morale               FUN_00582db0 via Morale.display
##   CLUB FEE / WAGE  lookup table x5000     FUN_00576cd0 (transfer_value_re.md §10/§12)
##   YEARS|LEFT  the rolled contract term    FUN_00576cd0 rec+0x18/+0x19 (offer_record_re.md)
##   flag     player record byte +0x1a       flagCode (player_info_re.md)
## Remaining gap: the MO club term (FUN_0057b710) needs the SELLING club's gate receipts
## and wage bill, which the app only simulates for the manager's own club — so an AI
## club's row shows his stored base morale, never a fabricated number.
##
## Driven live by Career.market() (dearest first). Native 640x480; scales to fit parent.
##
## INTERACTIVE: a tap on a player row opens the make-offer card (`player_pressed`,
## Main -> MakeOfferScreen, the original's browse-list -> card route, run-3 100->101);
## CURRENT OFFERS opens the offers screen (`current_offers_pressed`,
## docs/re/ofertas_screen_re.md); RETURN dismisses (`back_pressed`). SCOUT opens the
## hire-gated search screen (`scout_pressed`, docs/re/scout_screen_re.md); OFFERS the
## map browse (`offers_pressed`, docs/re/offers_map_re.md).

signal back_pressed
signal current_offers_pressed
signal scout_pressed
signal offers_pressed
signal player_pressed(row: Dictionary)

const W := 640
const H := 480

# frame-sampled inks (app/art/screens/transfer/transfer_chrome.json)
const C_BAND := Color8(0, 0, 128)          # KEEPER/DEFENDER/... header (navy, frame C(50,81))
const C_AV := Color8(212, 63, 0)           # AV value (orange-red, frame dom-ink C(236,96))
const C_MO := Color8(75, 109, 172)         # MO value (blue) — used for the gap dash
const C_FEE := Color8(210, 0, 0)           # CLUB FEE (bright red, frame dom-ink)
const C_WAGE := Color8(150, 0, 0)          # WAGE (dark maroon, frame dom-ink C(367,95))
const C_YEARS := Color8(42, 63, 170)       # YEARS|LEFT cell digit (navy)
const C_YEARS_FINAL := Color8(255, 31, 0)     # LEFT digit on the final year (frame 097)
const C_LEFT_CHIP := Color8(255, 255, 170)    # its pale-yellow cell fill (frame 097)
const LEFT_CHIP_X := 446                      # chip x446..469, 12 rows from slot_y+2
const LEFT_CHIP_W := 24
const LEFT_CHIP_H := 12
const C_NAME := Color8(0, 0, 0)            # player name (black)
const C_ROW_SEP := Color8(176, 176, 176)   # thin row separator
const C_GAP := Color8(150, 150, 150)       # honest-gap dash colour

# ---- band layout (frame 097; the fixed [3,5,5,5] slot grid, always drawn) ----
const BAND_X := 50                          # band-header text ink-left
const BANDS := [
	{"key": "GK", "label": "KEEPER", "hdr_y": 72, "slot_y": [92, 108, 124]},
	{"key": "DF", "label": "DEFENDER", "hdr_y": 140, "slot_y": [156, 172, 188, 204, 220]},
	{"key": "MF", "label": "MIDFIELDER", "hdr_y": 236, "slot_y": [252, 268, 284, 300, 316]},
	{"key": "FW", "label": "FORWARD", "hdr_y": 332, "slot_y": [348, 364, 380, 396, 412]},
]
const BAND_CAPS := {"GK": 3, "DF": 5, "MF": 5, "FW": 5}   # DAT_0065c020 slot counts
const ROW_H := 13                           # row content height (16px pitch)
# Value-grid faces, re-measured against frame 097 row slot_y=156 (2026-07-23). The old
# "ProMan8 @8" was proman8 SCALED DOWN from its native 11, which mangled 8/9/comma
# glyphs into blobs. Two faces, each at its NATIVE size, reproduce the frame's ink
# widths exactly:
#   AV "79" ink x235..249 = 15px  -> proman8 @11 (advance 16)
#   MO "86" ink x260..274 = 15px  -> proman8 @11
#   FEE "£1,000,000" ink 293..336 = 44px -> calend8 @15 (advance 44, exact)
#   WAGE "£350,000"   ink 365..403 = 39px -> calend8 @15 (advance 39, exact)
#   YEARS "2" ink 430..433 = 4px          -> calend8 @15
# (calend8-as-the-money-face is the FinanceScreen ledger precedent.)
const AV_SZ := 11                           # proman8 native
const MONEY_SZ := 15                        # calend8 native
const VAL_DY := 3                           # AV/MO glyph y-top vs slot_y (frame rows 161..167)
const MONEY_DY := 1                         # calend8's taller line box, same ink rows

# ---- column anchors (design coords, measured off frame 097) ----------------
const PLUS_XY := Vector2(5, 91)             # plus.png blit origin at slot_y 92
const FLAG_X := 34                          # nationality flag left (if flagCode)
const NAME_X := 60
const STARS_X := 156                        # frame 097: runs at x156/170/184/198
const STAR_PITCH := 14
const STAR_DY := 3                          # glyph rows slot_y+3 .. slot_y+11
const STAR_SLOTS := 5
const AV_RIGHT := 251
const MO_CENTER := 268
const FEE_RIGHT := 338
const WAGE_RIGHT := 405
const YEARS1_CENTER := 433
const YEARS2_CENTER := 458
const ROW_LEFT := 8
const ROW_RIGHT := 494

# ---- nav button hit rects (baked art; the scene only hit-tests them) --------
const BTN_CURRENT := Rect2(496, 287, 128, 21)
const BTN_SCOUT := Rect2(496, 324, 128, 21)
const BTN_OFFERS := Rect2(496, 361, 128, 21)
const BTN_RETURN := Rect2(496, 441, 128, 21)

# ---- live barra anchors (frame 097 ink centers/baselines; the text interiors
# are blanked in the chrome bake so the LIVE career draws here — the stale
# "asdf"/Man Utd fix, audit §C2 stale-career bleed) -------------------------
const BARRA_MGR_CX := 52          # manager + club band text center
const BARRA_MGR_BASE := 26        # "asdf" glyph rows 19..25
const BARRA_CLUB_BASE := 44       # "Manchester Utd." glyph rows 37..43
const BARRA_CREST := Rect2(112, 14, 28, 33)   # kit box interior
const SHEET_CX := 483             # calendar sheet text center
const SHEET_WD_BASE := 24         # "Saturday" caps 17..23 + descender
const SHEET_DAY_BASE := 35        # "23" digits 28..34
const SHEET_MON_BASE := 44        # "August" caps 37..43 + descender
const SHEET_YR_BASE := 55         # "1997" digits 48..54
const C_SHEET_DAY := Color8(255, 0, 0)
const C_SHEET_YEAR := Color8(42, 95, 170)
const BAND_CX := 580              # right-plaque band text center
const BAND1_BASE := 26            # "Premier" glyph rows 18..25
const BAND2_BASE := 44            # "Week 3" glyph rows 36..43

var _chrome: Texture2D
var _plus: Texture2D
var _star_full: Texture2D
var _star_half: Texture2D
var _f12: Font
var _f10: Font
var _f8: Font
var _fcal: Font

var _rows: Array = []
var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _cash: int = 0            # kept for Main's setup call; the frame shows no BANK box
var _window: String = ""      # ditto (no "Window: OPEN" text on the real screen)
var _offers: int = 0          # ditto
var _week: int = 0
var _press: String = ""
var _league: String = ""
var _club_id: int = -1


func _ready() -> void:
	_chrome = load("res://art/screens/transfer/chrome.png")
	_plus = load("res://art/screens/transfer/plus.png")
	_star_full = load("res://art/screens/transfer/star_full.png")
	_star_half = load("res://art/screens/transfer/star_half.png")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	_fcal = load("res://art/fonts/calend8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(market: Array, club: String, manager := "", season := "", cash := 0,
		window := "", offers := 0, week := 0, league := "", club_id := -1) -> void:
	_rows = market
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_window = window
	_offers = offers
	_week = week
	_league = league
	_club_id = club_id
	queue_redraw()


# ---- ordering: the 4 bands, each capped [3,5,5,5], dearest first ----------

## [{section, key, players}] in band order; players are the first N buyable rows of
## that decoded position, N <= the band's slot cap (the input is already fee-sorted).
func _sections() -> Array:
	var bands := {"GK": [], "DF": [], "MF": [], "FW": []}
	for r in _rows:
		var key := _band_of(r)
		if key != "" and bands[key].size() < int(BAND_CAPS[key]):
			bands[key].append(r)
	var out: Array = []
	for b in BANDS:
		out.append({"section": b["label"], "key": b["key"], "players": bands[b["key"]]})
	return out


## The 4-way position band key. Uses the decoded broad `pos`; a keeper with no pos
## still lands in GK. An outfield row with no decoded position is skipped rather than
## fabricated into a band.
func _band_of(r: Dictionary) -> String:
	var pos := str(r.get("pos", ""))
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if bool(r.get("isGK", false)) else ""


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


## Which control a design-space point hits: {a:"return|current|scout|offers|row", row?}.
func _hit(d: Vector2) -> Dictionary:
	if BTN_RETURN.has_point(d):
		return {"a": "return"}
	if BTN_CURRENT.has_point(d):
		return {"a": "current"}
	if BTN_SCOUT.has_point(d):
		return {"a": "scout"}
	if BTN_OFFERS.has_point(d):
		return {"a": "offers"}
	var r := _row_at(d)
	if not r.is_empty():
		return {"a": "row", "row": r}
	return {"a": ""}


## The player row under a design-space point ({} if none).
func _row_at(d: Vector2) -> Dictionary:
	if d.x < ROW_LEFT or d.x > ROW_RIGHT:
		return {}
	var secs := _sections()
	for bi in BANDS.size():
		var players: Array = secs[bi]["players"]
		var slots: Array = BANDS[bi]["slot_y"]
		for pi in mini(players.size(), slots.size()):
			var sy := int(slots[pi])
			if d.y >= sy - 1 and d.y <= sy + ROW_H:
				return players[pi]
	return {}


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
	var hit := _hit(_to_design(pos))
	var a := str(hit.get("a", ""))
	if pressed:
		_press = a
		return
	var was := _press
	_press = ""
	if a == "" or a != was:
		return
	# RETURN dismisses; CURRENT OFFERS opens the offers screen; SCOUT / OFFERS open
	# their screens; a row tap opens the make-offer card.
	match a:
		"return":
			back_pressed.emit()
		"current":
			current_offers_pressed.emit()
		"scout":
			scout_pressed.emit()
		"offers":
			offers_pressed.emit()
		"row":
			player_pressed.emit(hit["row"])


# ---- helpers -------------------------------------------------------------

static func fmt_money(v: int) -> String:
	var neg := v < 0
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return "%s£%s" % ["-" if neg else "", out]


func _txt_left(f: Font, x: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	draw_string(f, Vector2(x, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _txt_right(f: Font, x_right: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x_right - w, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _txt_center(f: Font, cx: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## Centered on cx with the BASELINE given directly (the barra anchors are
## baseline-measured off the frame's own ink rows, not band tops).
func _txt_base_center(f: Font, cx: int, baseline: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, baseline), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	# The barra FRAME (plaque bevels, spiral sheet, band plaque, trophy) is BAKED from
	# frame 097; its career-specific TEXT interiors are blanked by the bake tool and
	# redrawn here from the live career (the audit §C2 stale-career fix — the chrome
	# used to carry the walkthrough's "asdf"/Man Utd/23 Aug/Week 3 on every career).
	_draw_barra()
	_draw_list()


## The live barra text at the frame-measured anchors: manager/club plaque (+ kit
## crest), the calendar sheet's date and the league/week plaque bands. Fonts/sizes
## follow PMChrome.draw_header (the hub's proven combos); positions are baselines
## measured off the baked frame's own ink, so the text sits where the original put it.
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


func _draw_list() -> void:
	var secs := _sections()
	for bi in BANDS.size():
		var b: Dictionary = BANDS[bi]
		# Band header (always drawn — the fixed [3,5,5,5] grid shows every band).
		_txt_left(_f12, BAND_X, int(b["hdr_y"]) - 4, str(b["label"]), C_BAND, 12)
		var players: Array = secs[bi]["players"]
		var slots: Array = b["slot_y"]
		for pi in mini(players.size(), slots.size()):
			_draw_row(players[pi], int(slots[pi]))


func _draw_row(r: Dictionary, y: int) -> void:
	# thin top + bottom separators (the frame's row-grid lines)
	draw_rect(Rect2(ROW_LEFT, y - 1, ROW_RIGHT - ROW_LEFT, 1), C_ROW_SEP, true)
	draw_rect(Rect2(ROW_LEFT, y + ROW_H, ROW_RIGHT - ROW_LEFT, 1), C_ROW_SEP, true)
	# [+] expand box (baked-cut sprite)
	if _plus != null:
		draw_texture(_plus, Vector2(PLUS_XY.x, y - 1))
	# nationality flag — honest gap unless the row carries a flagCode
	var fc: Variant = r.get("flagCode", null)
	if fc != null:
		var ft := PMChrome.mini_flag(fc)
		if ft != null:
			draw_texture(ft, Vector2(FLAG_X, y + 1))
	# name (title-cased to the game's rendered form)
	_txt_left(_f12, NAME_X, y + 1, PMChrome.title_case_name(str(r.get("name", "?"))), C_NAME, 12)
	# AV = core4>>2 (FUN_00534570, transfer_value_re.md §1) — the number in the AV cell
	# and the value the star strip beside it grades.
	var av := int(r.get("av", 0))
	_draw_star_strip(y, av)
	_txt_right(_f8, AV_RIGHT, y + VAL_DY, str(av), C_AV, AV_SZ)
	# MO = the displayed morale (FUN_00582db0 via Morale.display)
	var mo := int(r.get("mo", -1))
	if mo >= 0:
		_txt_center(_f8, MO_CENTER, y + VAL_DY, str(mo), C_MO, AV_SZ)
	else:
		_txt_center(_f8, MO_CENTER, y + VAL_DY, "-", C_GAP, AV_SZ)
	# CLUB FEE / WAGE = the RE'd PM98 lookup tables keyed by the selling club's stature
	_txt_right(_fcal, FEE_RIGHT, y + MONEY_DY, fmt_money(int(r.get("fee", 0))), C_FEE, MONEY_SZ)
	_txt_right(_fcal, WAGE_RIGHT, y + MONEY_DY, fmt_money(int(r.get("wage", 0))), C_WAGE, MONEY_SZ)
	# YEARS | LEFT — the deal FUN_00576cd0 rolled for him (rec+0x18 / rec+0x19)
	_draw_term_cell(YEARS1_CENTER, y, int(r.get("years", 0)), false)
	_draw_term_cell(YEARS2_CENTER, y, int(r.get("left", 0)), int(r.get("left", 0)) == 1)


## The gold star strip, RE'd rule + frame-cut art: `halves = (AV+1) div 10` (star drawer
## FUN_004f79b0, docs/re/morale_re.md), `halves/2` full stars and one half stub when a
## half is left over. Frame 097 draws NO dim placeholder for the unlit slots — a 3-star
## row simply stops — so neither do we (the old CA/20 + 5-slot grey strip is gone).
func _draw_star_strip(y: int, av: int) -> void:
	var halves := (maxi(av, 0) + 1) / 10
	var full := mini(halves / 2, STAR_SLOTS)
	for j in full:
		if _star_full != null:
			draw_texture(_star_full, Vector2(STARS_X + STAR_PITCH * j, y + STAR_DY))
	if halves % 2 == 1 and full < STAR_SLOTS and _star_half != null:
		draw_texture(_star_half, Vector2(STARS_X + STAR_PITCH * full, y + STAR_DY))


## One YEARS / LEFT digit cell. On the FINAL contract year frame 097 fills the LEFT cell
## with a pale-yellow chip (255,255,170) x446..469 y slot+2..slot+13 and switches the
## digit to red (255,31,0) — measured off the frame, not styled.
func _draw_term_cell(cx: int, y: int, v: int, final_year: bool) -> void:
	if final_year:
		draw_rect(Rect2(LEFT_CHIP_X, y + 2, LEFT_CHIP_W, LEFT_CHIP_H), C_LEFT_CHIP, true)
	if v <= 0:
		_txt_center(_fcal, cx, y + MONEY_DY, "-", C_GAP, MONEY_SZ)
		return
	_txt_center(_fcal, cx, y + MONEY_DY, str(v),
		C_YEARS_FINAL if final_year else C_YEARS, MONEY_SZ)
