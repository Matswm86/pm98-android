extends Control
class_name CurrentOffersScreen
## PM98 CURRENT OFFERS (OFERTAS) screen — bids on your transfer-listed players.
## Reversed from MANAGER.EXE (docs/re/ofertas_screen_re.md): title "CURRENT OFFERS"
## @.data 0x65b700, white panel (31,78)-(606,438) [FUN_00523f70], 5 player bands at
## y=98 stepping 67 [FUN_00523ed0], each a 564x48 block [FUN_00524500]: the player's
## name/attribute strip (NAME | EN SP ST AG QU FI MO AV ROLE POS), the CLUB | CLUB
## OFFER | YEARLY WAGE | YEARS | CLAUSES labels row, one offer row of boxed cells and
## a footer strip; RETURN at (494,442)-(606,467). Cell spans + palette measured off
## the owner's capture `screenshots/transfer-offers-2026-07-02/current_offers.png`
## (capture→design offset dx=+2, dy=+12, anchored on the RE'd band y=98 / panel rects).
##
## Faithful gaps, never invented: MO (dynamic morale, unmodelled) renders "-" like
## SQUAD MANAGEMENT (APP_VS_SPEC_AUDIT B7); the CLAUSES cells render empty unless an
## offer row carries a `clauses` list (our TransferMarket doesn't model clauses — the
## four FUN_00524500 icons are baked and drawn only when present); the band-left kit
## figure comes from the un-RE'd band template (DAT_00666f70), so the club's extracted
## kit art stands in at the captured spot. The original band shows ONE offer row —
## Career keeps up to 5 bids per player, so the row shows the newest bid and a band
## tap hands the full list to the caller (`band_pressed`) for accept/refuse.
##
## Native 640x480; scales to fit its parent. INTERACTIVE: tap a populated band ->
## `band_pressed(player)`; RETURN or empty space -> `back_pressed`.

signal back_pressed
signal band_pressed(player)

const W := 640
const H := 480

# ---- geometry (design px; RE rects + capture border-scan) ------------------
const PANEL := Rect2(31, 78, 575, 360)           # outer border box (31,78)-(606,438)
const HDR_TXT_Y := 84                            # NAME / column-code header row
const NAME_HDR_X := 86                           # "NAME" + the player names' left edge
const BAND_X := 36                               # FUN_00524500 x=0x24
const BAND_Y0 := 98                              # FUN_00523ed0 y=0x62
const BAND_STEP := 67                            # ... stepping 0x43
const BAND_W := 564                              # header block 0x234 x 0x30
const BAND_H := 48
const BOX_X := 63                                # boxed rows start (kit gutter left of it)
const BOX_W := 537                               # 63..599 inclusive
const KIT_BOX := Rect2(38, 1, 22, 24)            # band-relative; capture (40,99)-(58,122)
# Attribute strip cells (8 value cells, then ROLE + POS), band row 1 (y+1..y+12).
const ATTR_X0 := 338
const ATTR_PITCH := 25
const ATTR_W := 24
const ROLE_CELL := [538, 23]                     # x, w
const POS_CELL := [562, 37]
const NAVY_W := 272                              # name area fill 64..335
# Offer row cells (fill x, w), band row 3 (y+27..y+38).
const CELL_CLUB := [67, 108]
const CELL_OFFER := [176, 115]
const CELL_WAGE := [292, 115]
const CELL_YEARS := [408, 36]
const CELL_SMALL1 := [445, 19]
const CELL_SMALL2 := [465, 29]
const CELL_CLAUSES := [495, 81]                  # 4 icon slots of ~20px
const CELL_SMALL3 := [577, 19]
const CLAUSE_KEYS := ["descenso", "partidos", "primasgol", "casacoche"]
const RETURN_BTN := Rect2(494, 442, 112, 25)     # CRect(0x1ee,0x1ba,0x25e,0x1d3)

# ---- palette (sampled off the capture) -------------------------------------
const C_NAVY_ROW := Color8(42, 95, 170)          # name/attr strip fill
const C_NAME_HDR := Color8(42, 63, 170)          # "NAME" header + CLUB OFFER cell fill
const C_LBL_FILL := Color8(160, 180, 200)        # labels row + footer strip
const C_LBL_TXT := Color8(30, 52, 98)            # labels + CLUB cell text
const C_CELL_LIGHT := Color8(200, 220, 240)      # CLUB / small / clause cells
const C_WAGE_FILL := Color8(75, 109, 172)
const C_YEARS_FILL := Color8(30, 52, 98)
const C_OFFER_TXT := Color8(166, 202, 240)       # £ on the CLUB OFFER cell
const C_WAGE_TXT := Color8(180, 200, 220)        # £ on the YEARLY WAGE cell
const C_EN := Color8(150, 0, 0)
const C_STAT := Color8(100, 100, 140)            # SP / ST / AG / QU
const C_FI := Color8(42, 95, 170)
const C_MO_HDR := Color8(80, 110, 5)
const C_MO_VAL := Color8(100, 130, 10)
const C_AV_HDR := Color8(212, 95, 0)
const C_AV_VAL := Color8(210, 0, 0)
const C_POS_HDR := Color8(128, 128, 128)
const C_ROLE_FILL := Color8(140, 170, 30)        # olive camrol cell
const C_DKBTN := Color(0.10, 0.16, 0.32)
const C_DKBTN_HI := Color(0.34, 0.46, 0.72)
const C_DKBTN_LO := Color(0.04, 0.08, 0.18)
const C_GOLD := Color(1.0, 0.86, 0.22)

# Column codes over the 8 attribute cells: [code, header colour, attrs key or ""].
# Key mapping as the other strips (EN tackling / VE speed / RE strength / AG / CA /
# TI finishing); MO is the unmodelled dynamic morale -> "-"; AV = the computed average.
const ATTR_COLS := [
	["EN", C_EN, "EN"], ["SP", C_STAT, "VE"], ["ST", C_STAT, "RE"], ["AG", C_STAT, "AG"],
	["QU", C_STAT, "CA"], ["FI", C_FI, "TI"], ["MO", C_MO_HDR, ""], ["AV", C_AV_HDR, "_avg"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

var _f12: Font
var _f10: Font
var _f8: Font

var _bands: Array = []       # up to 5 of {player: Dictionary, offers: Array}
var _manager: String = ""
var _club: String = ""
var _league: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _club_id: int = -1
var _press := ""


func _ready() -> void:
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## bands: the manager's transfer-listed players with their live bid lists, in listing
## order, capped to the screen's 5 slots ([{player, offers}]; offers may be empty).
func setup(bands: Array, manager: String, club: String, league: String,
		season: String = "1997-98", week: int = 0, club_id: int = -1) -> void:
	_bands = bands.slice(0, 5)
	_manager = manager
	_club = club
	_league = league
	_season = season
	_week = week
	_club_id = club_id
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
	if RETURN_BTN.has_point(d):
		return "return"
	for i in _bands.size():
		if Rect2(BAND_X, BAND_Y0 + i * BAND_STEP, BAND_W, BAND_H).has_point(d):
			return "band%d" % i
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
		queue_redraw()
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		queue_redraw()
		if a == "" or a != was:
			if was == "" and a == "":
				back_pressed.emit()
			return
		if a == "return":
			back_pressed.emit()
		else:
			var band: Dictionary = _bands[int(a.substr(4))]
			band_pressed.emit(band["player"])


# ---- helpers ---------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _ctxt(f: Font, x0: int, w: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(f, x0 + int((w - tw) / 2.0), y_top, s, col, sz)


func _avg_of(p: Dictionary) -> int:
	var attrs: Variant = p.get("attrs", {})
	if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
		return 0
	var a: Dictionary = attrs
	var sum := 0.0
	var n := 0
	for k in AVG_KEYS:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0


## The POS cell label (capture: DEF / FOR), the broad role group.
func _pos_label(p: Dictionary) -> String:
	var pos := str(p.get("pos", ""))
	if pos == "GK" or bool(p.get("isGK", false)):
		return "GK"
	return {"DF": "DEF", "MF": "MID", "FW": "FOR"}.get(pos, "")


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	var s: float = _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	# Title string "CURRENT OFFERS" @.data 0x65b700 (ofertas_screen_re.md).
	PMChrome.draw_header(self, "CURRENT OFFERS", _manager, _club, _league,
		_season, _week, _club_id)

	# The white panel (FUN_00523f70): black outer border, white inner fill.
	draw_rect(PANEL, Color.BLACK, true)
	draw_rect(Rect2(PANEL.position + Vector2(2, 2), PANEL.size - Vector2(4, 4)), Color.WHITE, true)

	_draw_col_header()
	for i in 5:
		var band: Dictionary = _bands[i] if i < _bands.size() else {}
		_draw_band(BAND_Y0 + i * BAND_STEP, band)
	_draw_return()


## Panel-top column header: NAME (navy) + the per-column codes in their own colours
## over the attribute cells, then ROLE (black) and POS (grey).
func _draw_col_header() -> void:
	_txt(_f10, NAME_HDR_X, HDR_TXT_Y, "NAME", C_NAME_HDR, 11)
	for i in ATTR_COLS.size():
		var col: Array = ATTR_COLS[i]
		_ctxt(_f10, ATTR_X0 + i * ATTR_PITCH, ATTR_W, HDR_TXT_Y, str(col[0]), col[1], 11)
	# The long ROLE / POS codes take the small face so they stay inside their cells.
	_ctxt(_f8, ROLE_CELL[0], ROLE_CELL[1], HDR_TXT_Y + 1, "ROLE", Color.BLACK, 10)
	_ctxt(_f8, POS_CELL[0], POS_CELL[1], HDR_TXT_Y + 1, "POS", C_POS_HDR, 10)


## One 564x48 band block: kit gutter | boxed rows (name/attr strip, labels row, the
## offer row, footer strip). An empty slot draws the full chrome with no content —
## exactly the capture's bands 3-5.
func _draw_band(y0: int, band: Dictionary) -> void:
	var p: Dictionary = band.get("player", {})
	var offers: Array = band.get("offers", [])

	# Boxed block: black base, fills inset so the 1px borders show through.
	draw_rect(Rect2(BOX_X, y0, BOX_W, BAND_H), Color.BLACK, true)
	draw_rect(Rect2(64, y0 + 1, NAVY_W, 12), C_NAVY_ROW, true)
	for i in 8:
		draw_rect(Rect2(ATTR_X0 + i * ATTR_PITCH, y0 + 1, ATTR_W, 12), Color.WHITE, true)
	# The olive camrol cell only exists under a player; an empty slot's cell is a
	# bare white box like the rest of the strip (capture bands 3-5).
	draw_rect(Rect2(ROLE_CELL[0], y0 + 1, ROLE_CELL[1], 12),
		C_ROLE_FILL if not p.is_empty() else Color.WHITE, true)
	draw_rect(Rect2(POS_CELL[0], y0 + 1, POS_CELL[1], 12), Color.WHITE, true)
	draw_rect(Rect2(64, y0 + 14, 535, 12), C_LBL_FILL, true)
	draw_rect(Rect2(64, y0 + 27, 535, 12), C_LBL_FILL, true)
	for c in [[CELL_CLUB, C_CELL_LIGHT], [CELL_OFFER, C_NAME_HDR], [CELL_WAGE, C_WAGE_FILL],
			[CELL_YEARS, C_YEARS_FILL], [CELL_SMALL1, C_CELL_LIGHT], [CELL_SMALL2, C_CELL_LIGHT],
			[CELL_CLAUSES, C_CELL_LIGHT], [CELL_SMALL3, C_CELL_LIGHT]]:
		var span: Array = c[0]
		draw_rect(Rect2(span[0] - 1, y0 + 26, span[1] + 2, 14), Color.BLACK, true)
		draw_rect(Rect2(span[0], y0 + 27, span[1], 12), c[1], true)
	draw_rect(Rect2(64, y0 + 40, 535, 7), C_LBL_FILL, true)

	# Labels row (ProMan8, dark navy), centred over their cells.
	var ly := y0 + 15
	_ctxt(_f8, CELL_CLUB[0], CELL_CLUB[1], ly, "CLUB", C_LBL_TXT, 10)
	_ctxt(_f8, CELL_OFFER[0], CELL_OFFER[1], ly, "CLUB OFFER", C_LBL_TXT, 10)
	_ctxt(_f8, CELL_WAGE[0], CELL_WAGE[1], ly, "YEARLY WAGE", C_LBL_TXT, 10)
	_ctxt(_f8, CELL_YEARS[0], CELL_YEARS[1], ly, "YEARS", C_LBL_TXT, 10)
	_ctxt(_f8, CELL_SMALL1[0], CELL_SMALL3[0] + CELL_SMALL3[1] - CELL_SMALL1[0], ly,
		"CLAUSES", C_LBL_TXT, 10)

	if p.is_empty():
		return

	# Kit figure in the gutter (the un-RE'd band template's spot; extracted kit art).
	var kit := PMChrome.kit(_club_id)
	if kit != null:
		var box := Rect2(KIT_BOX.position + Vector2(0, y0), KIT_BOX.size)
		var sc: float = minf(box.size.x / PMChrome.KIT_SRC.size.x,
			box.size.y / PMChrome.KIT_SRC.size.y)
		var kw := PMChrome.KIT_SRC.size.x * sc
		var kh := PMChrome.KIT_SRC.size.y * sc
		draw_texture_rect_region(kit, Rect2(box.position.x + (box.size.x - kw) * 0.5,
			box.position.y + (box.size.y - kh) * 0.5, kw, kh), PMChrome.KIT_SRC)

	# Name/attribute strip. Names render title-cased like the original screens
	# (the EQUIPOS cipher is single-case; capture "Southgate", frame 077 "Van der Gouw").
	var ty := y0 + 2
	_txt(_f10, NAME_HDR_X, ty, PMChrome.title_case_name(str(p.get("name", "?"))), Color.WHITE, 11)
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	for i in ATTR_COLS.size():
		var col: Array = ATTR_COLS[i]
		var key := str(col[2])
		var v := "-"
		var vcol: Color = col[1]
		if key == "_avg":
			v = str(_avg_of(p))
			vcol = C_AV_VAL
		elif key == "":
			vcol = C_MO_VAL      # MO: unmodelled dynamic morale -> honest "-"
		elif attrs.has(key):
			v = str(int(attrs[key]))
		_ctxt(_f10, ATTR_X0 + i * ATTR_PITCH, ATTR_W, ty, v, vcol, 11)
	# Camrol role icon on the olive cell (bare cell if the art is absent).
	PMChrome.draw_role_icon(self, Rect2(ROLE_CELL[0] + 1, y0 + 2, ROLE_CELL[1] - 2, 10),
		int(p.get("posFine", 0)), str(p.get("pos", "")))
	_ctxt(_f10, POS_CELL[0], POS_CELL[1], ty, _pos_label(p), Color.BLACK, 11)

	# The offer row: the newest bid (Career keeps up to 5; the band shows one, the
	# band tap opens the full list). Empty cells stay as drawn when no bid yet.
	if offers.is_empty():
		return
	var o: Dictionary = offers.back()
	var oy := y0 + 28
	_ctxt(_f10, CELL_CLUB[0], CELL_CLUB[1], oy,
		PMChrome.title_case_name(str(o.get("buyer_name", "?"))), C_LBL_TXT, 11)
	_ctxt(_f10, CELL_OFFER[0], CELL_OFFER[1], oy,
		TransferScreen.fmt_money(int(o.get("offer", 0))), C_OFFER_TXT, 11)
	_ctxt(_f10, CELL_WAGE[0], CELL_WAGE[1], oy,
		TransferScreen.fmt_money(Contract.yearly(int(o.get("weekly_wage", 0)))), C_WAGE_TXT, 11)
	_ctxt(_f10, CELL_YEARS[0], CELL_YEARS[1], oy, str(int(o.get("years", 0))), Color.WHITE, 11)
	var clauses: Array = o.get("clauses", []) if o.get("clauses") is Array else []
	for i in CLAUSE_KEYS.size():
		if CLAUSE_KEYS[i] in clauses:
			PMChrome.draw_icon(self, "clause_%s" % CLAUSE_KEYS[i],
				Rect2(CELL_CLAUSES[0] + i * 20, y0 + 27, 20, 12))


func _draw_return() -> void:
	var r := RETURN_BTN
	PMChrome.bevel(self, r, C_DKBTN_HI if _press == "return" else C_DKBTN, C_DKBTN_HI, C_DKBTN_LO)
	var tx := int(r.position.x) + 30
	# The OFERTAS money-bag glyph sits left of the label, as captured.
	if PMChrome.draw_icon(self, "offers", Rect2(r.position.x + 6, r.position.y + 3, 19, 19)):
		tx = int(r.position.x) + 32
	_txt(_f12, tx, int(r.position.y) + 7, "RETURN", C_GOLD, 12)
