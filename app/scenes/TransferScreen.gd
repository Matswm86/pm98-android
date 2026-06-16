extends Control
class_name TransferScreen
## PM98 TRANSFER MARKET (FICHAR) screen rebuilt from the ORIGINAL game art at the
## coordinates reversed out of MANAGER.EXE (FUN_00532a50). See
## docs/re/transfer_screen_re.md.
##
## Reversed: title "TRANSFER MARKET" at (150,16); the buyable-player list panel
## (8,72)..(498,435) with 16px rows; the original groups players into the 4 position
## bands KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS (the [3,5,5,5] camrol-role table) -
## we render the two we can derive faithfully (KEEPERS / OUTFIELD, dearest first),
## the role code not being decoded yet, exactly as the SQUAD screen does. The right-
## hand nav column (CURRENT OFFERS / SCOUT / OFFERS / RETURN) sits at x~512.
##
## Driven live by Career.market() (already sorted dearest first). Native 640x480;
## scales to fit its parent.

const W := 640
const H := 480

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_SECTION := Color(0.47, 0.55, 0.63)   # FUN_00437020(0x78,0x8c,0xa0) blue-grey band header
const C_NAME := Color(1.0, 1.0, 1.0)
const C_FEE := Color(0.98, 0.86, 0.45)       # gold fee figure
const C_KEY := Color(1.0, 0.87, 0.0)         # ★ first-XI marker
const C_SHORT := Color(0.95, 0.45, 0.55)     # ♥ shortlisted marker
const C_BTN := Color(0.16, 0.27, 0.47)
const C_BTN_HI := Color(0.27, 0.43, 0.65)
const C_RETURN := Color(0.81, 0.64, 0.65)    # peachy RETURN label (FUN_..(0xce,0xa2,0xa5))

# Reversed list region (8,72)..(498,435); top raised to 48 to seat the header row.
const PANEL := Rect2(8, 48, 490, 387)
const HDR_Y := 52
const ROW0_Y := 70
const ROW_H := 16
# The original's keeper band has 3 slots; cap ours so the (much larger cross-club)
# keeper pool can't starve the outfield band out of the visible panel.
const KEEP_CAP := 5

# Grid columns laid into the reversed panel (x 8..498). {code, x, align_right}.
const COLS := [
	["", 12, false], ["NAME", 26, false], ["AGE", 168, true], ["AB", 200, true],
	["CLUB FEE", 318, true], ["YR WAGE", 408, true], ["CLUB", 414, false],
]

# Right-hand nav column at the reversed x~512; button y's are the reversed values.
const NAV_X := 512
const NAV_W := 120
const BTN_H := 25
const BANK_BOX := Rect2(512, 48, 120, 44)
const BTN_CURRENT := Rect2(512, 286, 120, 25)
const BTN_SCOUT := Rect2(512, 323, 120, 25)
const BTN_OFFERS := Rect2(512, 360, 120, 25)
const BTN_RETURN := Rect2(512, 440, 120, 25)

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _rows: Array = []          # Career.market() rows
var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _cash: int = 0
var _window: String = ""
var _offers: int = 0


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Feed the buyable market (Career.market() rows) + chrome, then repaint.
func setup(market: Array, club: String, manager := "", season := "", cash := 0,
		window := "", offers := 0) -> void:
	_rows = market
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_window = window
	_offers = offers
	queue_redraw()


# ---- ordering ------------------------------------------------------------

## The market split into the bands we can derive faithfully (keepers / outfield),
## each kept dearest first (Career.market already sorts by fee). Returns
## [{section:String, players:Array}].
func _sections() -> Array:
	var gks: Array = []
	var outs: Array = []
	for r in _rows:
		if bool(r.get("isGK", false)):
			if gks.size() < KEEP_CAP:
				gks.append(r)
		else:
			outs.append(r)
	return [{"section": "KEEPERS", "players": gks},
		{"section": "OUTFIELD", "players": outs}]


# ---- helpers -------------------------------------------------------------

## £ with thousands separators, e.g. 21500000 -> "£21,500,000".
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


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(r: Rect2, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), lo, true)
	draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), lo, true)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 150, 13, "TRANSFER MARKET", C_TITLE, 15)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 500, 9, _club.substr(0, 18), C_TEXT, 13, true)
	if _season != "":
		_txt(_f12, 500, 26, _season, C_DIM, 13, true)

	# Column header row across the list panel.
	for c in COLS:
		var code: String = c[0]
		if code == "":
			continue
		var x: int = c[1]
		_txt(_f8, x, HDR_Y, code, C_HEAD, 11, bool(c[2]))

	_draw_list()
	_draw_nav()


func _draw_list() -> void:
	var y := ROW0_Y
	var row := 0
	for sec in _sections():
		if (sec["players"] as Array).is_empty():
			continue
		if y + ROW_H > int(PANEL.end.y):
			break
		_txt(_f8, COLS[1][1], y + 2, str(sec["section"]), C_SECTION, 11)
		y += ROW_H
		for r in sec["players"]:
			if y + ROW_H > int(PANEL.end.y):
				_txt(_f8, COLS[1][1], y + 2, "...more (bid via the menu)", C_DIM, 11)
				return
			draw_rect(Rect2(int(PANEL.position.x), y, int(PANEL.size.x), ROW_H - 1),
				C_ROW_A if row % 2 == 0 else C_ROW_B, true)
			_row(r, y)
			y += ROW_H
			row += 1


func _row(r: Dictionary, y: int) -> void:
	var ty := y + 2
	# ★ first-XI / ♥ shortlist flag.
	if bool(r.get("key", false)):
		_txt(_f8, 12, ty, "*", C_KEY, 11)
	_txt(_f8, COLS[1][1], ty, str(r.get("name", "?")).substr(0, 16), C_NAME, 11)
	_txt(_f8, COLS[2][1], ty, str(int(r.get("age", 0))), C_TEXT, 11, true)
	_txt(_f8, COLS[3][1], ty, str(int(r.get("ca", 0))), C_TEXT, 11, true)
	_txt(_f8, COLS[4][1], ty, fmt_money(int(r.get("fee", 0))), C_FEE, 11, true)
	_txt(_f8, COLS[5][1], ty, fmt_money(int(r.get("wage", 0))), C_TEXT, 11, true)
	# CLUB column runs to the panel's right edge (x 414..498 = 84px); fit the club
	# name to it on whole-word boundaries so long names degrade cleanly
	# ("MANCHESTER UTD." -> "MANCHESTER", never a mid-word "MANCHESTER U").
	var club_w := float(int(PANEL.end.x) - COLS[6][1] - 1)
	_txt(_f8, COLS[6][1], ty, _fit_club(str(r.get("club_name", "")), club_w), C_DIM, 11)


## Fit a club name into `max_w` px of the CLUB column: keep whole words while they
## fit (drop the trailing tag, e.g. " UTD."), and only char-truncate a single
## over-long word as a last resort. No ellipsis - reads as a clean short name.
func _fit_club(s: String, max_w: float) -> String:
	if _f8 == null or s == "" or max_w <= 0.0:
		return s
	if _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= max_w:
		return s
	var toks := s.split(" ", false)
	while toks.size() > 1:
		toks.remove_at(toks.size() - 1)
		var cand := " ".join(toks)
		if _f8.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= max_w:
			return cand
	var out := s
	while out.length() > 1 and _f8.get_string_size(out, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x > max_w:
		out = out.substr(0, out.length() - 1)
	return out


## Right column: bank box + the reversed CURRENT OFFERS / SCOUT / OFFERS / RETURN
## nav buttons at their reversed y positions.
func _draw_nav() -> void:
	_cell(BANK_BOX, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(BANK_BOX.position.x) + 8, int(BANK_BOX.position.y) + 5, "BANK", C_HEAD, 11)
	_txt(_f12, int(BANK_BOX.end.x) - 8, int(BANK_BOX.position.y) + 22, fmt_money(_cash),
		C_FEE, 13, true)

	_nav_btn(BTN_CURRENT, "CURRENT OFFERS", C_HEAD, _f8)
	_nav_btn(BTN_SCOUT, "SCOUT", C_TEXT, _f10)
	_nav_btn(BTN_OFFERS, "OFFERS", C_TEXT, _f10)
	_nav_btn(BTN_RETURN, "RETURN", C_RETURN, _f10)

	# Bottom help band (reversed (8,440) ProMan8 line) - window status + bank.
	if _window != "":
		_txt(_f8, int(PANEL.position.x) + 4, int(PANEL.end.y) + 6,
			"Transfer window: %s   -   %d offers left this week" % [_window, _offers],
			C_DIM, 11)


func _nav_btn(r: Rect2, label: String, col: Color, f: Font) -> void:
	_cell(r, C_BTN, C_BTN_HI, C_CELL_LO)
	_txt(f, int(r.position.x) + 10, int(r.position.y) + 7, label, col, 11)
