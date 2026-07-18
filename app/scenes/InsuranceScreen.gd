extends Control
class_name InsuranceScreen
## PM98 INSURANCE screen (INJURIES -> INSURANCE) + the INSURANCE POLICY modal.
## Frame-baked 2026-07-18 from the live wine witness run (captures 33-39 of
## screenshots/wine-captures-2026-07-18-goalscorers/;
## tools/re/build_insurance_chrome_from_frames.py; docs/re/insurance_screen_re.md).
##
## Chrome = capture 34 verbatim (33's PARAM. red ring is the engine's transient
## click-focus border -> NOT baked; PARAM.'s lit red face IS baked = the active
## parameters view). The scene draws only the dynamic layer:
##  - the squad in 4 FIXED position sections (KEEP y87 x3 slots, DEF y151 x5,
##    MID y247 x5, FOR y343 x4; witnessed: Bolton's 4 MFs leave the 5th MID slot
##    as plain panel -> row grids are per-player, not furniture). Order =
##    REVERSE record order per section (matches all 16 witnessed rows exactly;
##    the SquadScreen/EQUIPOS demarcacion rule);
##  - per row: N° (+ mini nationality flag for non-EU-1997 players -- witnessed
##    Icelanders yes / Danes+Finn+Irish no; the exact bit is un-RE'd so the
##    EU-1997 membership list is a PATTERN-DERIVED rule, documented), name,
##    EN SP ST AG QU FI MO AV (witness-bound sources — see ATTR_COLS), AGE, WAGE
##    (monthly = weekly x 52 / 12 -- app wages are the calibrated model, NOT
##    the original's decoded per-player wages; a charter-#10 parity gap);
##  - insured rows: green arrow + pale-green INSUR. cell with doc icon + group
##    digit (digit ink = the modal button's digit ink -- witnessed identical
##    for group 1, pattern-derived for 2/3) + grey COST cell with the monthly
##    price (witnessed "200");
##  - per-section scrollbar (x609..624): both dither textures are the witnessed
##    period-4 row patterns (reproduce ALL FOUR witnessed columns exactly);
##    slider h = floor(track_h*slots/total), off = floor(track_h*first/total)
##    (reproduces DEF 25px + FOR 20px). The ENABLED up arrow face is a vflip of
##    the enabled down face (both witnesses sit at first=0 -> pattern-derived).
##
## INSURANCE POLICY modal (witness 35/36/38): whole screen palette-dims through
## the PMAlert alert LUT (verified 9/9 sampled colour pairs); the modal is
## bright on top. GROUP prices are FLAT game constants (£200/£500/£1,000 --
## Ward £1,250 vs Frandsen £14,583 monthly wage see identical prices). Tapping
## a SELECT GROUP box previews it in the header card immediately (36: INSUR.
## GROUP 1 + £200 BEFORE OK); the 2px red pending border appears only on the
## tapped box (fresh-open shows NONE, 35/38). OK commits + closes; policy_
## selected(pid, group) -> Main -> Career.set_insurance (persists on the player
## dict like `wage`).
##
## HONEST GAPS (documented, never invented): RATING view un-walked -> the
## baked PARAM.-active state is the only view, both toggle buttons inert;
## premium CHARGING cadence + the injury payout flow are un-RE'd -> no money
## moves yet (the FinanceScreen PLAYERS' INSURANCE line stays a £0 gap);
## the header stays bright under the modal (draw_match_header is not
## LUT-aware -- the SquadScreen FICHA precedent). Native 640x480.

signal back_pressed                    # RETURN -> Main reopens INJURIES
signal policy_selected(pid: int, group: int)   # OK with a changed group

const W := 640
const H := 480
const BODY_Y0 := 62
const TITLE_XY := Vector2(239, 22)

# ---- sections (witnessed fixed geometry; insurance_chrome.json) -----------
const SECT := [
	{"key": "gk", "y0": 87, "slots": 3, "pos": ["GK"]},
	{"key": "def", "y0": 151, "slots": 5, "pos": ["DF"]},
	{"key": "mid", "y0": 247, "slots": 5, "pos": ["MF"]},
	{"key": "fwd", "y0": 343, "slots": 4, "pos": ["FW"]},
]
const ROW_PITCH := 16
const ROW_BOX_H := 14                  # strip: top border + 12 fill + bottom border
const STRIP_X := 7

# row text cells (witness-measured)
const FLAG_XY := [50, 2]               # mini flag x + y-off inside the row box
const NAME_X := 67
const NAME_W := 105.0
# Column value sources, WITNESS-BOUND (all 16 rows of capture 33/34): SP ST AG
# QU = attrs VE RE AG CA (exact match, e.g. Ward 64/64/54/39); FI = the LIVE
# fitness stat (morale_re.md +0xa7: fresh 99 halves toward 40 -> 70, witnessed
# Ward FI 70 / Todd 69); AV = Morale.av6 (Ward (64+64+54+39+70+90)/6 = 63 ==
# witness); MO = live morale; EN = ENERGIA, witnessed 99 on ALL rows = the
# between-matches rested state (live in-match energia is unmodeled; a stored
# `energy` field plugs in if one ever exists).
const ATTR_COLS := [                   # column centre CX, value key
	[186, "_en"], [211, "VE"], [236, "RE"], [261, "AG"], [286, "CA"],
	[311, "_fit"], [336, "_mo"], [362, "_avg"],
]
const AGE_CX := 393
const NUM_CX := 41.5
const WAGE_CELL := [412, 63]
const ARROW_X := 474                   # 29x14 arrow button sprite x (y = row top)
const DOC_CELL := [502, 33]            # insured display cell (fill 170,223,170)
const DOC_ICON_XY := [511, 2]          # doc_row.png x + y-off (baked json doc_row_xy)
const DIGIT_X := 524
const COST_CELL := [536, 66]           # insured cost cell (fill 192,192,192)

const R_ARROW := Rect2(474, 0, 29, 14)   # per-row hit zone (y filled per row)

# ---- scrollbar (witnessed column x609..624; see class doc) ----------------
const SCR_X := 609
const SCR_W := 16

# ---- bottom bar buttons (hitboxes; PARAM./RATING inert -- see class doc) --
const R_RETURN := Rect2(523, 432, 112, 27)

# ---- modal (witnessed geometry; insurance_chrome.json) --------------------
const MODAL_XY := Vector2(104, 86)
const M_NAME_BAND := [148, 121, 191]   # x, y, w   "Ward (age 27)"
const M_RIGHT_BAND := [341, 121, 164]  # UNINSURED / doc + INSUR. GROUP n
const M_VAL_Y := 150                   # £ value row (witness glyphs y150..160)
const M_DOC_XY := [345, 123]           # baked json doc_modal_xy
const M_BTNS := {0: Rect2(128, 361, 90, 22), 1: Rect2(230, 361, 32, 22),
	2: Rect2(270, 361, 32, 22), 3: Rect2(310, 361, 32, 22)}
const M_OK := Rect2(458, 357, 92, 30)
const SEL_BORDER := Color8(255, 31, 0)   # witnessed 2px pending border (36)

const PRICES := {1: 200, 2: 500, 3: 1000}  # flat £/month (witness 35 vs 38)

# EU members 1997 in game_db nationality spellings: NOT on this list -> the
# N° cell shows the mini nationality flag (the witnessed foreigner marker;
# pattern-derived rule, see class doc).
const EU_1997 := ["AUSTRIA", "BELGIUM", "DENMARK", "ENGLAND", "FINLAND",
	"FRANCE", "GERMANY", "GREECE", "HOLLAND", "ITALY", "LUXEMBOURG",
	"NORTH. IRELAND", "PORTUGAL", "REP. OF IRELAND", "SCOTLAND", "SPAIN",
	"SWEDEN", "WALES"]

# ---- sampled inks (insurance_chrome.json samples) -------------------------
const C_NUM := Color8(0, 0, 128)
const C_NAME := Color8(0, 0, 0)
const ATTR_INKS := {"_en": Color8(150, 0, 0), "VE": Color8(100, 100, 140),
	"RE": Color8(100, 100, 140), "AG": Color8(100, 100, 140),
	"CA": Color8(100, 100, 140), "_fit": Color8(42, 95, 170),
	"_mo": Color8(80, 110, 5), "_avg": Color8(210, 0, 0)}
const C_AGE := Color8(128, 128, 128)
const C_WAGE := Color8(128, 128, 128)
const C_COST := Color8(170, 63, 85)
const DIGIT_INKS := {1: Color8(60, 90, 0), 2: Color8(0, 0, 128), 3: Color8(85, 0, 0)}
const C_DOC_FILL := Color8(170, 223, 170)
const C_COST_FILL := Color8(192, 192, 192)
const C_TRACK := Color8(120, 140, 160)
const C_M_NAME := Color8(30, 52, 98)
const C_M_RIGHT := Color8(59, 85, 130)
const C_M_VAL := Color8(0, 0, 0)
const C_PRESS := Color(1, 1, 1, 0.20)

var _club: Dictionary = {}
var _tier: int = 1
var _header: Dictionary = {}
var _sections: Array = []              # {key, y0, slots, players}
var _scroll := {}                      # key -> first visible index
var _press := ""
var _modal_pid := -1                   # >= 0 while the POLICY modal is up
var _modal_p: Dictionary = {}
var _pending := -1                     # tapped group this modal session (-1 = none)

var _f8: Font
var _f10: Font
var _chrome: Texture2D
var _title: Texture2D
var _strip: Texture2D
var _arrow_off: Texture2D
var _arrow_on: Texture2D
var _doc_row: Texture2D
var _doc_modal: Texture2D
var _modal_tex: Texture2D
var _scr_up_off: Texture2D
var _scr_dn_off: Texture2D
var _scr_dn_on: Texture2D
var _scr_up_on: Texture2D              # vflip(dn_on), pattern-derived
var _scr_slider: Texture2D             # 25px master (row-pattern source)
var _scr_pale: Texture2D               # 43px master (row-pattern source)
var _slider_cache := {}                # h -> ImageTexture
var _pale_cache := {}


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	var base := "res://art/screens/insurance"
	_chrome = load(base + "/chrome.png")
	_title = load(base + "/title.png")
	_strip = load(base + "/row_strip.png")
	_arrow_off = load(base + "/arrow_off.png")
	_arrow_on = load(base + "/arrow_on.png")
	_doc_row = load(base + "/doc_row.png")
	_doc_modal = load(base + "/doc_modal.png")
	_modal_tex = load(base + "/modal.png")
	_scr_up_off = load(base + "/scroll_up_off.png")
	_scr_dn_off = load(base + "/scroll_dn_off.png")
	_scr_dn_on = load(base + "/scroll_dn_on.png")
	_scr_slider = load(base + "/scroll_slider25.png")
	_scr_pale = load(base + "/scroll_pale.png")
	_scr_up_on = _vflip(_scr_dn_on)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, tier: int, header: Dictionary = {}) -> void:
	_club = club
	_tier = tier
	_header = header
	if _header.is_empty():
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1))}
	var bucket := {"gk": [], "def": [], "mid": [], "fwd": []}
	for p in club.get("players", []):
		var pd: Dictionary = p
		if int(pd.get("id", -1)) < 0:
			continue
		bucket[_section_of(pd)].append(pd)
	_sections = []
	for s in SECT:
		var rows: Array = bucket[str(s["key"])]
		rows.reverse()                 # REVERSE record order (witnessed, all 4 sections)
		_sections.append({"key": s["key"], "y0": s["y0"], "slots": s["slots"],
			"players": rows})
		_scroll[str(s["key"])] = 0
	queue_redraw()


func _section_of(p: Dictionary) -> String:
	if bool(p.get("isGK", false)) or str(p.get("pos", "")) == "GK":
		return "gk"
	match str(p.get("pos", "")):
		"DF": return "def"
		"FW": return "fwd"
		_: return "mid"


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()


func _sect_end(s: Dictionary) -> int:
	return int(s["y0"]) + ROW_PITCH * int(s["slots"]) - 3   # last box bottom border


# ---- input ----------------------------------------------------------------

func _hit(d: Vector2) -> String:
	if _modal_pid >= 0:
		for g in M_BTNS:
			if (M_BTNS[g] as Rect2).has_point(d):
				return "grp:%d" % g
		if M_OK.has_point(d):
			return "ok"
		return ""
	for s in _sections:
		var key := str(s["key"])
		var y0 := int(s["y0"])
		var slots := int(s["slots"])
		var players: Array = s["players"]
		for i in mini(slots, players.size() - int(_scroll[key])):
			var top := y0 + ROW_PITCH * i
			if Rect2(ARROW_X, top, 29, ROW_BOX_H).has_point(d):
				return "row:%s:%d" % [key, i]
		if players.size() > slots:
			if Rect2(SCR_X, y0, SCR_W, 16).has_point(d):
				return "up:" + key
			if Rect2(SCR_X, _sect_end(s) - 14, SCR_W, 15).has_point(d):
				return "dn:" + key
	if R_RETURN.has_point(d):
		return "return"
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	var parts := was.split(":")
	match parts[0]:
		"return":
			back_pressed.emit()
		"up", "dn":
			var s := _sect(parts[1])
			var lim := maxi(0, (s["players"] as Array).size() - int(s["slots"]))
			_scroll[parts[1]] = clampi(int(_scroll[parts[1]]) + (1 if parts[0] == "dn" else -1), 0, lim)
		"row":
			var s2 := _sect(parts[1])
			var p: Dictionary = (s2["players"] as Array)[int(_scroll[parts[1]]) + int(parts[2])]
			_modal_pid = int(p.get("id", -1))
			_modal_p = p
			_pending = -1              # fresh-open: no pending border (witness 35/38)
		"grp":
			_pending = int(parts[1])
		"ok":
			var cur := int(_modal_p.get("insurance_group", 0))
			if _pending >= 0 and _pending != cur:
				policy_selected.emit(_modal_pid, _pending)
			_modal_pid = -1
			_modal_p = {}
			_pending = -1
	queue_redraw()


func _sect(key: String) -> Dictionary:
	for s in _sections:
		if str(s["key"]) == key:
			return s
	return {}


# ---- drawing --------------------------------------------------------------

## Texture pass-through: LUT-dimmed while the POLICY modal is up (witnessed:
## the whole frame palette-dims through the PMAlert alert LUT).
func _tex(t: Texture2D) -> Texture2D:
	return PMAlert.dim_texture(t) if _modal_pid >= 0 and t != null else t


func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	# Header stays bright (draw_match_header is not LUT-aware; documented gap).
	PMChrome.draw_match_header(self, "insurance", _header)
	if _title != null:
		draw_texture(_title, TITLE_XY)

	PMChrome.set_dim(_modal_pid >= 0)
	if _chrome != null:
		draw_texture(_tex(_chrome), Vector2(0, BODY_Y0))
	for sct in _sections:
		_draw_section(sct)
	if _press == "return":
		draw_rect(R_RETURN, C_PRESS, true)
	PMChrome.set_dim(false)

	if _modal_pid >= 0:
		_draw_modal()


func _draw_section(s: Dictionary) -> void:
	var key := str(s["key"])
	var y0 := int(s["y0"])
	var slots := int(s["slots"])
	var players: Array = s["players"]
	var first := int(_scroll[key])
	for i in mini(slots, players.size() - first):
		_draw_row(y0 + ROW_PITCH * i, players[first + i], key, i)
	_draw_scrollbar(s, first)


func _draw_row(top: int, p: Dictionary, key: String, i: int) -> void:
	if _strip != null:
		draw_texture(_tex(_strip), Vector2(STRIP_X, top))
	var ty := top + 2
	var no: Variant = p.get("squadNo")
	_digits(NUM_CX, ty, str(int(no)) if no != null else "-", C_NUM)
	if not str(p.get("nationality", "")) in EU_1997:
		var fl := PMChrome.mini_flag(p.get("flagCode"))
		if fl != null:
			draw_texture(_tex(fl), Vector2(FLAG_XY[0], top + FLAG_XY[1]))
	PMChrome.text(self, _f8, NAME_X, ty, PMChrome.title_case_name(str(p.get("name", "?"))),
		C_NAME, 11, 0, NAME_W)
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	var has_form: bool = p.has("morale") or p.has("fitness")
	for col in ATTR_COLS:
		var k := str(col[1])
		var v := "-"
		match k:
			"_en":
				v = str(clampi(int(p.get("energy", 99)), 0, 99))
			"_fit":
				v = str(clampi(int(p.get("fitness", 99)), 0, 99)) if has_form else "-"
			"_mo":
				v = str(Morale.display(p)) if has_form else "-"
			"_avg":
				v = str(Morale.av6(p)) if has_form else str(_avg_of(p))
			_:
				if attrs.has(k):
					v = str(int(attrs[k]))
		_digits(int(col[0]), ty, v, ATTR_INKS[k])
	var age: Variant = p.get("age")
	_digits(AGE_CX, ty, str(int(age)) if age != null else "-", C_AGE)
	PMChrome.text(self, _f8, WAGE_CELL[0], ty, "£" + _money(_monthly_wage(p)),
		C_WAGE, 11, 1, float(WAGE_CELL[1]))

	var g := int(p.get("insurance_group", 0))
	if g >= 1:
		if _arrow_on != null:
			draw_texture(_tex(_arrow_on), Vector2(ARROW_X, top))
		draw_rect(Rect2(DOC_CELL[0], top + 1, DOC_CELL[1], 12), PMChrome.dim_col(C_DOC_FILL), true)
		if _doc_row != null:
			draw_texture(_tex(_doc_row), Vector2(DOC_ICON_XY[0], top + DOC_ICON_XY[1]))
		PMChrome.text(self, _f8, DIGIT_X, ty, str(g), DIGIT_INKS[g], 11, 0)
		draw_rect(Rect2(COST_CELL[0], top + 1, COST_CELL[1], 12), PMChrome.dim_col(C_COST_FILL), true)
		PMChrome.text(self, _f8, COST_CELL[0], ty, _money(PRICES[g]), C_COST, 11, 1,
			float(COST_CELL[1]))
	if _press == "row:%s:%d" % [key, i]:
		draw_rect(Rect2(ARROW_X, top, 29, ROW_BOX_H), C_PRESS, true)


## Centred digit run, the ORIGINAL's grammar: digits are monospaced at
## advance 8 except "1" at 5; the string centres on the column centre CX with
## px = floor(CX - tw/2). Fitted on ALL 26 witnessed cell landings (capture 34
## - "99"/"64"/"70"/"90"/"63"/"27" at even widths AND every "1"-carrying value
## "81"/"71"/"61"/"31"/"12"/"16"/"1"); a per-string get_string_size centring
## drifts 1px on "1"-carrying values because our .fnt advances differ.
func _digits(cx: float, ty: int, s: String, ink: Color) -> void:
	var tw := 0
	for ch in s:
		tw += 5 if ch == "1" else 8
	var px := int(floor(cx - tw / 2.0))
	for ch in s:
		PMChrome.text(self, _f8, px, ty, ch, ink, 11, 0)
		px += 5 if ch == "1" else 8


func _draw_scrollbar(s: Dictionary, first: int) -> void:
	var y0 := int(s["y0"])
	var yend := _sect_end(s)
	var slots := int(s["slots"])
	var total: int = (s["players"] as Array).size()
	if total <= slots:
		# noscroll: dotted arrows + the pale dither track (witnessed KEEP + MID)
		if _scr_up_off != null:
			draw_texture(_tex(_scr_up_off), Vector2(SCR_X, y0))
		_pale(Rect2(SCR_X, y0 + 17, SCR_W, yend - y0 - 34))
		if _scr_dn_off != null:
			draw_texture(_tex(_scr_dn_off), Vector2(SCR_X, yend - 17))
		return
	# scrollable: 16px arrows + black track borders + slider (witnessed DEF/FOR)
	var can_up := first > 0
	var can_dn := first + slots < total
	var up := _scr_up_on if can_up else _crop16(_scr_up_off)
	if up != null:
		draw_texture(_tex(up), Vector2(SCR_X, y0))
	# track spans y0+16 .. yend-16 (46px DEF / 30px FOR); the slider carries its
	# own borders; the single black row at yend-15 fronts the enabled down arrow
	var track_y := y0 + 16
	var track_h := (yend - 15) - track_y
	draw_rect(Rect2(SCR_X, track_y, SCR_W, track_h), PMChrome.dim_col(C_TRACK), true)
	@warning_ignore("integer_division")
	var sl_h := track_h * slots / total
	@warning_ignore("integer_division")
	var sl_y := track_y + track_h * first / total
	_slider(Rect2(SCR_X, sl_y, SCR_W, sl_h))
	draw_rect(Rect2(SCR_X, yend - 15, SCR_W, 1), PMChrome.dim_col(Color8(0, 0, 0)), true)
	var dn := _scr_dn_on if can_dn else _crop_last15(_scr_dn_off)
	if dn != null:
		draw_texture(_tex(dn), Vector2(SCR_X, yend - 14))
	for a in [["up", y0], ["dn", yend - 14]]:
		if _press == str(a[0]) + ":" + str(s["key"]):
			draw_rect(Rect2(SCR_X, int(a[1]), SCR_W, 16), C_PRESS, true)


## The slider block at any height: rows 0-2 + period-4 face [A,B,C,B] + rows
## 22-24 of the witnessed 25px sprite (this reconstruction reproduces BOTH
## witnessed sliders -- DEF 25px and FOR 20px -- pixel-exact).
func _slider(r: Rect2) -> void:
	var h := int(r.size.y)
	if _scr_slider == null or h < 7:
		return
	if not _slider_cache.has(h):
		var src := _scr_slider.get_image()
		src.convert(Image.FORMAT_RGBA8)
		var img := Image.create(SCR_W, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var sy: int
			if y < 3:
				sy = y
			elif y >= h - 3:
				sy = 22 + (y - (h - 3))
			else:
				sy = 3 + ((y - 3) % 4)
			img.blit_rect(src, Rect2i(0, sy, SCR_W, 1), Vector2i(0, y))
		_slider_cache[h] = ImageTexture.create_from_image(img)
	draw_texture(_tex(_slider_cache[h]), r.position)


## The pale no-scroll track at any height: rows 0-1 + period-4 face + last row
## of the witnessed 43px sprite (reproduces KEEP 11px and MID 43px exactly).
func _pale(r: Rect2) -> void:
	var h := int(r.size.y)
	if _scr_pale == null or h < 4:
		return
	if not _pale_cache.has(h):
		var src := _scr_pale.get_image()
		src.convert(Image.FORMAT_RGBA8)
		var img := Image.create(SCR_W, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var sy: int
			if y < 2:
				sy = y
			elif y == h - 1:
				sy = 42
			else:
				sy = 2 + ((y - 2) % 4)
			img.blit_rect(src, Rect2i(0, sy, SCR_W, 1), Vector2i(0, y))
		_pale_cache[h] = ImageTexture.create_from_image(img)
	draw_texture(_tex(_pale_cache[h]), r.position)


func _crop16(t: Texture2D) -> Texture2D:
	return _crop_rows(t, 0, 16, "_c16")

func _crop_last15(t: Texture2D) -> Texture2D:
	if t == null:
		return null
	return _crop_rows(t, int(t.get_size().y) - 15, 15, "_c15")

var _crop_cache := {}
func _crop_rows(t: Texture2D, y0: int, h: int, key: String) -> Texture2D:
	if t == null:
		return null
	var k := key + str(y0)
	if not _crop_cache.has(k):
		var img := t.get_image().get_region(Rect2i(0, y0, SCR_W, h))
		_crop_cache[k] = ImageTexture.create_from_image(img)
	return _crop_cache[k]

func _vflip(t: Texture2D) -> Texture2D:
	if t == null:
		return null
	var img := t.get_image()
	img.flip_y()
	return ImageTexture.create_from_image(img)


# ---- the INSURANCE POLICY modal -------------------------------------------

func _draw_modal() -> void:
	if _modal_tex != null:
		draw_texture(_modal_tex, MODAL_XY)
	var p := _modal_p
	var nm := "%s (age %s)" % [PMChrome.title_case_name(str(p.get("name", "?"))),
		str(int(p.get("age"))) if p.get("age") != null else "-"]
	PMChrome.text(self, _f8, M_NAME_BAND[0], M_NAME_BAND[1] + 2, nm, C_M_NAME,
		12, 1, float(M_NAME_BAND[2]))
	var g := _pending if _pending >= 0 else int(p.get("insurance_group", 0))
	if g >= 1:
		if _doc_modal != null:
			draw_texture(_doc_modal, Vector2(M_DOC_XY[0], M_DOC_XY[1]))
		PMChrome.text(self, _f8, M_RIGHT_BAND[0], M_RIGHT_BAND[1] + 2,
			"INSUR.  GROUP  %d" % g, C_M_RIGHT, 12, 1, float(M_RIGHT_BAND[2]))
	else:
		PMChrome.text(self, _f8, M_RIGHT_BAND[0], M_RIGHT_BAND[1] + 2,
			"UNINSURED", C_M_RIGHT, 12, 1, float(M_RIGHT_BAND[2]))
	PMChrome.text(self, _f8, M_NAME_BAND[0], M_VAL_Y, "£" + _money(_monthly_wage(p)),
		C_M_VAL, 12, 1, float(M_NAME_BAND[2]))
	PMChrome.text(self, _f8, M_RIGHT_BAND[0], M_VAL_Y,
		"£" + _money(PRICES[g] if g >= 1 else 0), C_M_VAL, 12, 1, float(M_RIGHT_BAND[2]))
	if _pending >= 0:
		# 2px filled red frame OUTSIDE the box (witness 36: x228..263 y359..384
		# around the 32x22 "1" box) — filled bars, stroke rects blur the corners
		var b: Rect2 = M_BTNS[_pending]
		var o := Rect2(b.position - Vector2(2, 2), b.size + Vector2(4, 4))
		draw_rect(Rect2(o.position, Vector2(o.size.x, 2)), SEL_BORDER, true)
		draw_rect(Rect2(o.position + Vector2(0, o.size.y - 2), Vector2(o.size.x, 2)), SEL_BORDER, true)
		draw_rect(Rect2(o.position, Vector2(2, o.size.y)), SEL_BORDER, true)
		draw_rect(Rect2(o.position + Vector2(o.size.x - 2, 0), Vector2(2, o.size.y)), SEL_BORDER, true)
	if _press == "ok":
		draw_rect(M_OK, C_PRESS, true)


# ---- values ---------------------------------------------------------------

## Monthly wage display: the app's weekly contract wage x 52 / 12 (matches the
## original's yearly/12 grammar; the per-player VALUES are the calibrated app
## wage model, not the original's decoded wages -- charter #10 parity gap).
func _monthly_wage(p: Dictionary) -> int:
	@warning_ignore("integer_division")
	return Contract.current_weekly(p, _tier) * 52 / 12


func _avg_of(p: Dictionary) -> int:
	var attrs: Variant = p.get("attrs", {})
	if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
		return 0
	var a: Dictionary = attrs
	var sum := 0.0
	var n := 0
	for k in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0


func _money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out
