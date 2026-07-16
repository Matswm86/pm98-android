extends Control
class_name OffersSelectionScreen
## PM98 OFFERS SELECTION screen — frame-baked from the live-witnessed original
## (screenshots/promanager-career-2026-07-16/03..07, MANAGER.EXE under wine; EXE
## strings 0x25e5bc OFFERS SELECTION / 0x25e724 "OFFERS FOR";
## docs/re/promanager_career_screens_re.md). This is the original counterpart of
## the invented "JOB OFFERS" browse (audit B5-1): the app mounts it for the
## post-sack / headhunt offer list. The original's mid-career use of this screen
## is UNPROVEN (post-sack surface unknown, RE doc) — witnessed chrome, flagged.
##
## Baked (art/screens/offers_selection/): title bar + plaque + ball, the 8-row
## slot table, the OFFERS FOR panel with its 10 empty rows, bottom bar with the
## washed disabled CONTINUE. The scene draws live, over blanked baked fields:
##   - the panel title "OFFERS FOR <name>" (proman12, advance-centred on x=320 —
##     the block re-centres with the name, witnessed frames 03 vs 05)
##   - slot row 1: number chip + arrow + manager name; after an offer is taken
##     also the TEAM / DIVISION / OBJECTIVE fills + texts (frame 07)
##   - the offer rows: baked red chips (the red darkens down the list), arrow
##     chips, proman8 texts centred per cell (frame 05)
##   - the active name-entry cell + OFFERS plate (frames 03/04/07 states; the
##     in-app single-career flow never shows them — parity/multi-slot only)
##   - the lit CONTINUE once an offer is accepted (frame 07)
##   - the club-detail popup (frame 06): whole screen through the witnessed
##     palette-dim LUT, popup bright on top with live club/division/values/kit.
##
## HONEST GAPS: the slot arrow chip's function is un-witnessed -> inert. Slot
## digits beyond '1' and entry rows beyond the witnessed two are un-witnessed ->
## not rendered (single-career app never needs them). Offer objectives beyond
## the fresh-manager band ("Avoid Relegation"/"Mid Table") are un-witnessed —
## the app shows its real board objective per club. The popup kit patch is
## witnessed only for Brighton & HA (kits/offers/107.png); other clubs fall
## back to the scaled NANOESC kit (documented, un-witnessed at this size).
## MEMBERS is witnessed only as "-". Native 640x480; scales to fit.

signal back_pressed             # RETURN -> dismiss (no job taken)
signal offer_accepted(index: int)    # an offer row was tapped (slot filled)
signal accept_confirmed(index: int)  # CONTINUE pressed with an accepted offer

const W := 640
const H := 480

const NAVY := Color8(30, 52, 98)
const C_TITLE_INK := Color8(166, 202, 240)   # panel title (witnessed)
const C_ENTRY_INK := Color8(220, 220, 220)   # typed name in the black cell
const C_MGR_FILL := Color8(120, 140, 160)    # filled slot: MANAGER + OBJECTIVE
const C_TEAM_FILL := Color8(127, 159, 85)    # filled slot: TEAM
const C_DIV_FILL := Color8(170, 159, 85)     # filled slot: DIVISION
const C_POP_CLUB_INK := Color8(255, 223, 0)
const C_POP_DIV_INK := Color8(102, 50, 12)
# The value texts and the label texts swap the row's two colours: each row's
# value ink = its label-cell fill (witnessed, one per row down the ramp).
const POP_VAL_INKS: Array[Color] = [
	Color8(200, 220, 240), Color8(180, 200, 220),
	Color8(160, 180, 200), Color8(140, 160, 180),
]

# Upper slot table (frame coords): 8 row bands, fill y = 86 + 15*r, height 14.
const UP_Y0 := 86
const PITCH := 15
const CELL_MGR := Vector2i(88, 204)
const CELL_TEAM := Vector2i(207, 341)
const CELL_DIV := Vector2i(344, 435)
const CELL_OBJ := Vector2i(438, 595)
const SLOT_CHIP_POS := Vector2(45, 86)
const SLOT_ARROW_POS := Vector2(70, 86)

# Lower OFFERS FOR panel: 10 rows, fill y = 265 + 15*r, height 14.
const LOW_Y0 := 265
const LOW_ROWS := 10
const LOW_CHIP_X := 104.0
const LOW_ARROW := Vector2i(129, 144)
const LOW_TEAM := Vector2i(147, 281)
const LOW_DIV := Vector2i(284, 375)
const LOW_OBJ := Vector2i(378, 535)
const TITLE_CENTER_X := 320.0     # "OFFERS FOR <name>" advance-centre (witnessed)
const TITLE_CAP_TOP := 232.0

# Popup (frame 06).
const POPUP_POS := Vector2(148, 174)
const POP_CLUB := Vector2i(150, 334)      # header cell interiors (x0, x1)
const POP_DIV := Vector2i(337, 489)
const POP_HDR_CAP_TOP := 180.0
const POP_VAL_X := 340.0                  # value pen (cell 337 + witnessed pad 3)
const POP_VAL_Y0 := 199                   # first value row fill top (+17 per row)
const POP_ROW_PITCH := 17
const KIT_POS := Vector2(157, 205)
const KIT_SIZE := Vector2(47, 59)
const BTN_OK := Rect2(403, 272, 71, 28)

# Controls (frame-measured hit rects).
const BTN_RETURN := Rect2(25, 438, 115, 30)
const BTN_CONTINUE := Rect2(505, 438, 120, 30)
const CONTINUE_ON_POS := Vector2(508, 440)
const PLATE_X := 206.0

var _body: Texture2D
var _body_dim: Texture2D
var _plate_off: Texture2D
var _plate_on: Texture2D
var _plate_off_r1: Texture2D   # row-2 art (the plate dither is screen-anchored)
var _slot_chip1: Texture2D
var _arrow: Texture2D
var _offer_chips: Array[Texture2D] = []
var _continue_on: Texture2D
var _popup_tex: Texture2D
var _f8: Font
var _f10: Font
var _f12: Font
var _lut := {}                  # "r,g,b" -> Color (witnessed palette dim)
var _dim_cache := {}            # Texture2D -> ImageTexture

var _manager := ""
var _offers: Array = []         # [{team, division, objective, stadium, capacity,
								#   members, cash, club_id}]
var _accepted: Dictionary = {}  # {team, division, objective} once a row is taken
var _accepted_i := -1
var _popup_i := -1
var _kit_tex: Texture2D = null  # resolved on show_popup (draw-time loads render blank)
# Parity/multi-slot extras (the in-app single-career flow never sets these):
var entry_row := -1
var entry_text := ""


func _ready() -> void:
	var base := "res://art/screens/offers_selection"
	_body = _tex(base + "/body.png")
	_body_dim = _tex(base + "/body_dim.png")
	_plate_off = _tex(base + "/offers_plate_off.png")
	_plate_on = _tex(base + "/offers_plate_on.png")
	_plate_off_r1 = _tex(base + "/offers_plate_off_r1.png")
	_slot_chip1 = _tex(base + "/slot_chip1.png")
	_arrow = _tex(base + "/arrow_chip.png")
	for r in LOW_ROWS:
		_offer_chips.append(_tex(base + "/offer_chip_%02d.png" % (r + 1)))
	_continue_on = _tex(base + "/continue_on.png")
	_popup_tex = _tex(base + "/popup.png")
	var lf := FileAccess.get_file_as_string(base + "/dim_lut.json")
	if lf != "":
		var lut: Dictionary = JSON.parse_string(lf)
		for k in lut:
			var d: PackedStringArray = (lut[k] as String).split(",")
			_lut[k] = Color8(int(d[0]), int(d[1]), int(d[2]))
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


static func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## `manager` fills the slot row + the panel title; `offers` fills the OFFERS FOR
## rows (max 10 render — the original shows exactly 10 to a fresh manager);
## `accepted` (frame-07 state) fills the slot's TEAM/DIVISION/OBJECTIVE.
func setup(manager: String, offers: Array, accepted: Dictionary = {}) -> void:
	_manager = manager
	_offers = offers
	_accepted = accepted
	_accepted_i = -1
	_popup_i = -1
	entry_row = -1
	entry_text = ""
	queue_redraw()


func show_popup(i: int) -> void:
	if i >= 0 and i < _offers.size():
		_popup_i = i
		var cid := int((_offers[i] as Dictionary).get("club_id", -1))
		_kit_tex = _tex("res://art/kits/offers/%d.png" % cid)
		if _kit_tex == null:
			# un-witnessed at this size: scaled NANOESC fallback (dbcard convention)
			_kit_tex = PMChrome.nano_kit(cid)
		queue_redraw()


func close_popup() -> void:
	_popup_i = -1
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		return
	var p := _to_design(e.position)
	if _popup_i >= 0:
		if BTN_OK.has_point(p):
			close_popup()
		return
	if BTN_RETURN.has_point(p):
		back_pressed.emit()
		return
	if BTN_CONTINUE.has_point(p):
		if not _accepted.is_empty() and _accepted_i >= 0:
			accept_confirmed.emit(_accepted_i)
		return
	for i in mini(_offers.size(), LOW_ROWS):
		var ry := float(LOW_Y0 + i * PITCH)
		if Rect2(LOW_CHIP_X, ry, LOW_OBJ.y - LOW_CHIP_X + 1, 14).has_point(p):
			if p.x >= LOW_ARROW.x and p.x <= LOW_ARROW.y:
				show_popup(i)      # row arrow -> club-detail popup (frame 06)
			else:
				_accept(i)         # row tap accepts the offer (frame 07)
			return


## Accept offer `i`: the slot row fills, the offers list empties and CONTINUE
## lights (the witnessed frame-05 -> frame-07 transition).
func _accept(i: int) -> void:
	_accepted = _offers[i]
	_accepted_i = i
	_offers = []
	offer_accepted.emit(i)
	queue_redraw()


# ---- drawing ---------------------------------------------------------------

## Witnessed palette dim while the popup modal is up (dim_lut.json, frames
## 05->06); colours outside the captured LUT fall back to PMAlert's fitted
## multiply (documented — nothing witnessed maps outside the LUT).
func _dc(c: Color) -> Color:
	if _popup_i < 0:
		return c
	var k := "%d,%d,%d" % [c.r8, c.g8, c.b8]
	if _lut.has(k):
		return _lut[k]
	return PMAlert.dim_color(c)


func _dt(tex: Texture2D) -> Texture2D:
	if _popup_i < 0 or tex == null:
		return tex
	if _dim_cache.has(tex):
		return _dim_cache[tex]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var k := "%d,%d,%d" % [c.r8, c.g8, c.b8]
				img.set_pixel(x, y, _lut[k] if _lut.has(k) else PMAlert.dim_color(c))
	var out := ImageTexture.create_from_image(img)
	_dim_cache[tex] = out
	return out


## proman8 at native 11pt, ink CAP TOP at y_top (baseline = top + 7; the
## MANAGER HISTORY / STAFF convention, re-verified on these frames).
func _t8(pen_x: float, y_top: float, s: String, col: Color) -> void:
	if _f8 == null or s == "":
		return
	draw_string(_f8, Vector2(floorf(pen_x), y_top + 7), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _dc(col))


## Advance-centred proman8 on a cell interior (floored — witnessed on every
## filled cell of frames 05/07).
func _t8_center(cell: Vector2i, y_top: float, s: String, col: Color) -> void:
	if _f8 == null or s == "":
		return
	var w := _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var span := float(cell.y - cell.x + 1)
	_t8(cell.x + floorf((span - w) / 2.0), y_top, s, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	var body := _body_dim if (_popup_i >= 0 and _body_dim != null) else _body
	if body != null:
		draw_texture(body, Vector2.ZERO)

	_draw_slot_row()
	_draw_entry()
	_draw_offer_rows()
	_draw_title()
	if not _accepted.is_empty() and _continue_on != null:
		draw_texture(_dt(_continue_on), CONTINUE_ON_POS)
	if _popup_i >= 0:
		_draw_popup()


## Slot row 1 (the app's single career): chip + arrow + manager name on the
## slate fill (frame 05); TEAM/DIVISION/OBJECTIVE fill once accepted (frame 07).
func _draw_slot_row() -> void:
	if _manager == "" and _accepted.is_empty():
		return
	var yt := float(UP_Y0 + 4)                    # ink top = fill top + 4
	if _slot_chip1 != null:
		draw_texture(_dt(_slot_chip1), SLOT_CHIP_POS)
	if _arrow != null:
		draw_texture(_dt(_arrow), SLOT_ARROW_POS)  # function un-witnessed: inert
	draw_rect(Rect2(CELL_MGR.x, UP_Y0, CELL_MGR.y - CELL_MGR.x + 1, 14), _dc(C_MGR_FILL), true)
	_t8_center(CELL_MGR, yt, _manager, Color.WHITE)
	if _accepted.is_empty():
		return
	draw_rect(Rect2(CELL_TEAM.x, UP_Y0, CELL_TEAM.y - CELL_TEAM.x + 1, 14), _dc(C_TEAM_FILL), true)
	draw_rect(Rect2(CELL_DIV.x, UP_Y0, CELL_DIV.y - CELL_DIV.x + 1, 14), _dc(C_DIV_FILL), true)
	draw_rect(Rect2(CELL_OBJ.x, UP_Y0, CELL_OBJ.y - CELL_OBJ.x + 1, 14), _dc(C_MGR_FILL), true)
	_t8_center(CELL_TEAM, yt, str(_accepted.get("team", "")), Color.WHITE)
	_t8_center(CELL_DIV, yt, str(_accepted.get("division", "")), Color.WHITE)
	_t8_center(CELL_OBJ, yt, str(_accepted.get("objective", "")), Color.WHITE)


## The active name-entry cell + OFFERS plate (witnessed rows 1 and 2 only; the
## in-app flow never mounts one — parity and a future multi-slot mode). The cell
## swallows the row separators: 2px above on row 1, 1px above below row 1.
func _draw_entry() -> void:
	if entry_row < 0 or entry_row > 1:
		return
	var ft := UP_Y0 + entry_row * PITCH           # row fill top
	var top := ft - 2 if entry_row == 0 else ft - 1
	draw_rect(Rect2(CELL_MGR.x, top, CELL_MGR.y - CELL_MGR.x + 1, ft + 15 - top),
		_dc(Color.BLACK), true)
	# Plate art per row (the dither is screen-anchored, witnessed rows 1+2); the
	# name-typed plate is witnessed on row 1 only — an entry with text never
	# occurs on row 2 in-app or in the witness.
	var plate := _plate_off_r1 if entry_row == 1 \
		else (_plate_on if entry_text != "" else _plate_off)
	if plate != null:
		draw_texture(_dt(plate), Vector2(PLATE_X, ft - 1))
	_t8_center(CELL_MGR, ft + 4, entry_text, C_ENTRY_INK)


func _draw_offer_rows() -> void:
	for i in mini(_offers.size(), LOW_ROWS):
		var o: Dictionary = _offers[i]
		var ft := float(LOW_Y0 + i * PITCH)
		if i < _offer_chips.size() and _offer_chips[i] != null:
			draw_texture(_dt(_offer_chips[i]), Vector2(LOW_CHIP_X, ft))
		if _arrow != null:
			draw_texture(_dt(_arrow), Vector2(LOW_ARROW.x, ft))
		var yt := ft + 4
		_t8_center(LOW_TEAM, yt, str(o.get("team", "")), Color.BLACK)
		_t8_center(LOW_DIV, yt, str(o.get("division", "")), Color.BLACK)
		_t8_center(LOW_OBJ, yt, str(o.get("objective", "")), Color.BLACK)


## Panel title "OFFERS FOR <name>" — ONE proman12 string with the format's
## space always present (frame 03: "OFFERS FOR " pen 263; frame 05:
## "OFFERS FOR mwm" pen 243 — both = floor(320 - advance/2)). The name is the
## ACTIVE slot's manager: while an entry row is up it is still empty (frames
## 03/04 pre-OFFERS, frame 07 post-accept).
func _draw_title() -> void:
	if _f12 == null:
		return
	var nm := "" if entry_row >= 0 else _manager
	var s := "OFFERS FOR %s" % nm
	var w := _f12.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(_f12, Vector2(floorf(TITLE_CENTER_X - w / 2.0), TITLE_CAP_TOP + 9), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, _dc(C_TITLE_INK))


## proman10 centred on a header cell (native 10pt; cap top 180, baseline +8 —
## parity-calibrated vs frame 06).
func _t10_center(cell: Vector2i, y_top: float, s: String, col: Color) -> void:
	if _f10 == null or s == "":
		return
	var w := _f10.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var span := float(cell.y - cell.x + 1)
	draw_string(_f10, Vector2(float(cell.x) + floorf((span - w) / 2.0), y_top + 8), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)


## The club-detail popup (frame 06): baked box bright over the dimmed screen,
## live club/division headers, kit patch and the four value texts.
func _draw_popup() -> void:
	if _popup_tex == null or _popup_i >= _offers.size():
		return
	draw_texture(_popup_tex, POPUP_POS)
	var o: Dictionary = _offers[_popup_i]
	_t10_center(POP_CLUB, POP_HDR_CAP_TOP, str(o.get("team", "")), C_POP_CLUB_INK)
	_t10_center(POP_DIV, POP_HDR_CAP_TOP, str(o.get("division_full", o.get("division", ""))),
		C_POP_DIV_INK)
	if _kit_tex != null:
		if _kit_tex.get_size() == KIT_SIZE:
			draw_texture(_kit_tex, KIT_POS)      # witnessed patch, 1:1
		else:
			draw_texture_rect(_kit_tex, Rect2(KIT_POS, KIT_SIZE), false)
	var vals := [str(o.get("stadium", "-")), str(o.get("capacity", "-")),
		str(o.get("members", "-")), str(o.get("cash", "-"))]
	for r in 4:
		var yt := float(POP_VAL_Y0 + r * POP_ROW_PITCH + 4)
		if _f8 != null and str(vals[r]) != "":
			draw_string(_f8, Vector2(POP_VAL_X, yt + 7), str(vals[r]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, POP_VAL_INKS[r])
