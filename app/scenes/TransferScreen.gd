extends Control
class_name TransferScreen
## PM98 TRANSFER MARKET (FICHAR) screen, rebuilt to match the real game (ma_11): the
## shared PMChrome plaque header + blue marble background over the white buyable-player
## table — (crest) | NAME | ★ rating | AV | MO | AGE | CLUB FEE | WAGE | CLUB — grouped
## into the RED position bands KEEPERS / DEFENDERS / MIDFIELDERS / FORWARDS (the [3,5,5,5]
## camrol-role table). A selected-player detail strip runs along the bottom; the nav
## column (CURRENT OFFERS / SCOUT / OFFERS / RETURN) + BANK sit on the right.
##
## Driven live by Career.market() (dearest first). Native 640x480; scales to fit its parent.
##
## INTERACTIVE: the original ARROW scroll buttons page the buyable list when it overflows
## the panel (KEEPERS off the top, the last FORWARDS into view); any other tap emits
## `back_pressed` (the display-screen tap-to-dismiss).

signal back_pressed

const W := 640
const H := 480

const C_SECTION := Color(0.78, 0.16, 0.14)       # RED position-band header (ma_11)
const C_STATBAND := Color(0.86, 0.88, 0.92)
const C_FEE := Color(0.70, 0.18, 0.12)           # red club-fee figure
const C_WAGE := Color(0.16, 0.34, 0.20)          # green wage figure
const C_DKBTN := Color(0.10, 0.16, 0.32)
const C_DKBTN_HI := Color(0.34, 0.46, 0.72)
const C_DKBTN_LO := Color(0.04, 0.08, 0.18)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_STRIP := Color(0.90, 0.91, 0.86)

const TABLE := Rect2(6, 50, 498, 384)
const HDR_Y := 66
const ROW_X := 8
const ROW_W := 494
const ROW0_Y := 84
const ROW_H := 16
const NAME_X := 28
const STARS_X := 148
const AV_X := 226
const MO_X := 256
const AGE_X := 292
const FEE_X := 376
const WAGE_X := 452
const CLUB_X := 458

const BAND_CAPS := {"GK": 3, "DF": 5, "MF": 5, "FW": 5, "OUT": 5}
const BAND_ORDER := ["GK", "DF", "MF", "FW", "OUT"]
const BAND_LABELS := {
	"GK": "KEEPERS", "DF": "DEFENDERS", "MF": "MIDFIELDERS", "FW": "FORWARDS", "OUT": "OUTFIELD",
}

# Right-hand nav column.
const BANK_BOX := Rect2(510, 50, 124, 44)
const BTN_CURRENT := Rect2(510, 286, 124, 25)
const BTN_SCOUT := Rect2(510, 323, 124, 25)
const BTN_OFFERS := Rect2(510, 360, 124, 25)
const BTN_RETURN := Rect2(510, 440, 124, 25)
# Bottom selected-player detail strip.
const STRIP := Rect2(6, 440, 498, 26)
# Original ARROW scroll buttons (16x16 art), in the nav gutter centred on the list height;
# the hit rect is padded for touch and the 16px glyph is drawn centred inside it. Shown only
# while the list overflows the panel (the original registers them on the list widget).
const SCROLL_UP := Rect2(606, 150, 24, 22)
const SCROLL_DOWN := Rect2(606, 206, 24, 22)
const SCROLL_STEP := 3

var _f12: Font
var _f10: Font
var _f8: Font

var _rows: Array = []
var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _week: int = 0
var _cash: int = 0
var _window: String = ""
var _offers: int = 0
var _scroll: int = 0
var _press: String = ""


func _ready() -> void:
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(market: Array, club: String, manager := "", season := "", cash := 0,
		window := "", offers := 0, week := 0) -> void:
	_rows = market
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_window = window
	_offers = offers
	_week = week
	_scroll = 0
	queue_redraw()


# ---- scroll model + input -----------------------------------------------

## The list flattened to draw-items in render order — a {t:"hdr"} per band then its
## {t:"row"} players, each row carrying a continuous `idx` for the alternating stripe.
func _flat_items() -> Array:
	var items: Array = []
	var idx := 0
	for sec in _sections():
		items.append({"t": "hdr", "label": str(sec["section"])})
		for r in sec["players"]:
			items.append({"t": "row", "r": r, "idx": idx})
			idx += 1
	return items


## How many 16px rows fit between the first row and the panel's bottom.
func _visible_rows() -> int:
	return int((TABLE.end.y - ROW0_Y) / ROW_H)


func _max_scroll() -> int:
	return maxi(0, _flat_items().size() - _visible_rows())


func _clamp_scroll() -> void:
	_scroll = clampi(_scroll, 0, _max_scroll())


func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


## Which scroll button (if any) a design-space point hits. Returns "" when the list does
## not overflow, so a tap there falls through to dismiss.
func _hit(d: Vector2) -> String:
	if BTN_RETURN.has_point(d):
		return "return"
	if _max_scroll() <= 0:
		return ""
	if SCROLL_UP.has_point(d):
		return "up"
	if SCROLL_DOWN.has_point(d):
		return "down"
	return ""


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
	if pressed:
		_press = _hit(_to_design(pos))
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		if a == was and a != "":
			# RETURN dismisses; a scroll-button tap pages the list. A tap on a player row or
			# empty space is a no-op (it no longer bounces back to the hub).
			if a == "return":
				back_pressed.emit()
			else:
				_scroll += SCROLL_STEP if a == "down" else -SCROLL_STEP
				_clamp_scroll()
				queue_redraw()


# ---- ordering ------------------------------------------------------------

func _sections() -> Array:
	var bands := {"GK": [], "DF": [], "MF": [], "FW": [], "OUT": []}
	for r in _rows:
		var key := _band_of(r)
		if bands[key].size() < int(BAND_CAPS[key]):
			bands[key].append(r)
	var out: Array = []
	for key in BAND_ORDER:
		if not bands[key].is_empty():
			out.append({"section": BAND_LABELS[key], "players": bands[key]})
	return out


func _band_of(r: Dictionary) -> String:
	var pos := str(r.get("pos", ""))
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if bool(r.get("isGK", false)) else "OUT"


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


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "TRANSFER MARKET", _manager, _club, "Premier", _season, _week)

	PMChrome.draw_table_panel(self, TABLE)
	_draw_col_header()
	_draw_list()
	_draw_scroll()
	_draw_strip()
	_draw_nav()


func _draw_col_header() -> void:
	PMChrome.draw_col_header(self, Rect2(TABLE.position.x + 2, HDR_Y, TABLE.size.x - 4, 16))
	_txt(_f10, NAME_X, HDR_Y + 2, "PLAYER", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, STARS_X, HDR_Y + 2, "RATING", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, AV_X, HDR_Y + 2, "AV", PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, MO_X, HDR_Y + 2, "MO", PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, AGE_X, HDR_Y + 2, "AGE", PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, FEE_X, HDR_Y + 2, "CLUB FEE", PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, WAGE_X, HDR_Y + 2, "WAGE", PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, CLUB_X, HDR_Y + 2, "CLUB", PMChrome.C_TBL_HDR_TXT, 11)


func _draw_list() -> void:
	var items := _flat_items()
	_clamp_scroll()
	var vis := _visible_rows()
	var y := ROW0_Y
	for i in range(_scroll, mini(items.size(), _scroll + vis)):
		var it: Dictionary = items[i]
		if it["t"] == "hdr":
			# RED position-band header on a light strip.
			draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1), PMChrome.C_ROW_DARK, true)
			_txt(_f10, NAME_X, y + 2, str(it["label"]), C_SECTION, 11)
		else:
			_row(it["r"], y, int(it["idx"]))
		y += ROW_H


## The original ARROW scroll buttons: up/down with on/off art for whether more list exists
## in that direction. Drawn only while the list overflows the panel.
func _draw_scroll() -> void:
	if _max_scroll() <= 0:
		return
	_draw_arrow(SCROLL_UP, "scroll_up_on" if _scroll > 0 else "scroll_up_off")
	_draw_arrow(SCROLL_DOWN, "scroll_down_on" if _scroll < _max_scroll() else "scroll_down_off")


func _draw_arrow(hit: Rect2, name: String) -> void:
	var g := Rect2(hit.position + (hit.size - Vector2(16, 16)) * 0.5, Vector2(16, 16))
	if not PMChrome.draw_icon(self, name, g):
		# Fallback so the control still reads when the PNG is absent: a drawn triangle.
		var up := name.begins_with("scroll_up")
		var col := PMChrome.C_GOLD if name.ends_with("_on") else PMChrome.C_STAR_OFF
		var c := g.get_center()
		var pts := PackedVector2Array([Vector2(c.x, c.y - 6), Vector2(c.x - 6, c.y + 5),
			Vector2(c.x + 6, c.y + 5)] if up else [Vector2(c.x, c.y + 6),
			Vector2(c.x - 6, c.y - 5), Vector2(c.x + 6, c.y - 5)])
		draw_colored_polygon(pts, col)


func _row(r: Dictionary, y: int, idx: int) -> void:
	draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1),
		PMChrome.C_ROW_LIGHT if idx % 2 == 0 else PMChrome.C_ROW_DARK, true)
	draw_rect(Rect2(ROW_X, y + ROW_H - 1, ROW_W, 1), PMChrome.C_ROW_SEP, true)
	var ty := y + 2
	var ca := int(r.get("ca", 0))
	PMChrome.draw_crest(self, int(r.get("club_id", -1)), Rect2(10, y, 13, ROW_H - 1))
	_txt(_f10, NAME_X, ty, str(r.get("name", "?")).substr(0, 15), PMChrome.C_ROW_TXT, 11)
	PMChrome.draw_stars(self, STARS_X, y + 3, ca / 20.0, 9, 5)
	_txt(_f10, AV_X, ty, str(ca), PMChrome.C_ROW_TXT, 11, true)
	_txt(_f10, MO_X, ty, str(int(r.get("mo", 0))), PMChrome.C_ROW_TXT, 11, true)
	_txt(_f10, AGE_X, ty, str(int(r.get("age", 0))), PMChrome.C_ROW_TXT, 11, true)
	_txt(_f10, FEE_X, ty, fmt_money(int(r.get("fee", 0))), C_FEE, 11, true)
	_txt(_f10, WAGE_X, ty, fmt_money(int(r.get("wage", 0))), C_WAGE, 11, true)
	_txt(_f8, CLUB_X, ty, _fit_club(str(r.get("club_name", "")), float(int(TABLE.end.x) - CLUB_X - 2)),
		PMChrome.C_ROW_TXT, 10)


func _fit_club(s: String, max_w: float) -> String:
	if _f8 == null or s == "" or max_w <= 0.0:
		return s
	if _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x <= max_w:
		return s
	var toks := s.split(" ", false)
	while toks.size() > 1:
		toks.remove_at(toks.size() - 1)
		var cand := " ".join(toks)
		if _f8.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x <= max_w:
			return cand
	var out := s
	while out.length() > 1 and _f8.get_string_size(out, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > max_w:
		out = out.substr(0, out.length() - 1)
	return out


## Bottom strip: the dearest target's name + selling club (the real screen shows the
## selected row; this display overlay features the top target).
func _draw_strip() -> void:
	PMChrome.bevel(self, STRIP, C_STRIP, PMChrome.C_TBL_HI, PMChrome.C_TBL_LO, 2.0)
	if _rows.is_empty():
		return
	var r: Dictionary = _rows[0]
	_txt(_f12, int(STRIP.position.x) + 12, int(STRIP.position.y) + 6,
		str(r.get("name", "?")), PMChrome.C_ROW_TXT, 13)
	_txt(_f12, int(STRIP.end.x) - 12, int(STRIP.position.y) + 6,
		str(r.get("club_name", "")), PMChrome.C_TBL_HDR, 13, true)


## Right column: BANK box + CURRENT OFFERS / SCOUT / OFFERS / RETURN nav buttons.
func _draw_nav() -> void:
	PMChrome.bevel(self, BANK_BOX, Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(BANK_BOX.position.x) + 8, int(BANK_BOX.position.y) + 5, "BANK", C_PANEL_TXT, 11)
	_txt(_f12, int(BANK_BOX.end.x) - 8, int(BANK_BOX.position.y) + 24, fmt_money(_cash), C_GOLD, 13, true)

	_nav_btn(BTN_CURRENT, "CURRENT OFFERS", C_GOLD, _f10)
	_nav_btn(BTN_SCOUT, "SCOUT", C_PANEL_TXT, _f12, "scout")
	_nav_btn(BTN_OFFERS, "OFFERS", C_PANEL_TXT, _f12, "offers")
	_nav_btn(BTN_RETURN, "RETURN", C_GOLD, _f12)

	if _window != "":
		_txt(_f8, int(BANK_BOX.position.x) + 4, int(BANK_BOX.end.y) + 6,
			"Window: %s" % _window, PMChrome.C_STAR_OFF, 10)
		_txt(_f8, int(BANK_BOX.position.x) + 4, int(BANK_BOX.end.y) + 18,
			"%d offers left" % _offers, PMChrome.C_STAR_OFF, 10)


func _nav_btn(r: Rect2, label: String, col: Color, f: Font, glyph := "") -> void:
	PMChrome.bevel(self, r, C_DKBTN, C_DKBTN_HI, C_DKBTN_LO)
	# The original SECRETARIO magnifier / OFERTAS money-bag glyph sits to the left of the
	# label when baked; without it the label just keeps its original inset.
	var tx := int(r.position.x) + 10
	if glyph != "":
		var gr := Rect2(r.position.x + 5, r.position.y + 4, 17, 17)
		if PMChrome.draw_icon(self, glyph, gr):
			tx = int(gr.end.x) + 5
	_txt(f, tx, int(r.position.y) + 6, label, col, 12)
