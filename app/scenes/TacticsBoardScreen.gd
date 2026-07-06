extends Control
class_name TacticsBoardScreen
## PM98 TACTICS board (TACTICAS) at pixel parity (binding frame 014_162413,
## docs/re/tacticas_screen_re.md). Distinct from the TEAM TACTICS modal
## (TacticsScreen.gd = the ATTACK|DEFENCE panel): this is the outer screen titled
## "TACTICS <club>" reached from LINE-UP's TACTICS button.
##
## Static chrome = the REAL frame baked verbatim below the shared barra
## (tools/re/build_tactics_chrome_from_frames.py, entry-flow doctrine): panel,
## column headers, skill grid, PREDEF/LOAD/SAVE, nav buttons, clean CAMPO pitch
## (the dedicated 278x167 tacticas CAMPO.BMP — NOT a stretch of the 152x92 one),
## and the RATING-active / PARAM.-inactive toggle as the frame shows. This screen
## draws ONLY the dynamic layer:
##  - the XI rows: a frame-cut row template per FORMATION-SLOT BAND (FUN_004fe2d0:
##    GK yellow; slot mk1.x<52 DEF green; mk2.x<211 MID lavender; else FWD salmon
##    — thresholds in formations.json's pre-scaled 258x154 space), then shirt No.
##    (ProMan8 navy), name (black), STARJUGON star strip, AV (red), camrol sprite,
##    fine-ROLE name + broad POS word;
##  - the pitch markers: DVERDE disc at mk1 + AVERDE movement arrow at mk2,
##    16x16 top-left at (187+mk.x, 310+mk.y) 1:1, ProMan8 black shirt digits
##    (frame 014 shows ONLY the horizontal AVERDE; fleul/fleur exist for
##    un-walked states);
##  - the "TACTICS <formation>" title text (white ProMan12);
##  - the flipped PARAM.-active state (reconstructed plates — un-walked).
##
## Stars: halves = (AV+1) div 10 (all 22 frame observations across 014+015);
## the odd half renders as STARJUGON-OFF (the dimmed star), NOT a clipped glyph.
## The AV value itself is an UN-RE'D in-engine derivation (no stored byte; see
## tacticas_screen_re.md "Honest gaps") — a player dict may carry a frame-true
## "av" override; otherwise the app's documented attrs-mean approximation shows.
## Native 640x480; scales to fit its parent (same transform as LINE-UP / RIVAL).

signal predef_pressed        # open the 10-formation picker (Main sets the formation)
signal formation_picked(form: String)  # a PREDEF thumbnail was chosen
signal load_pressed
signal save_pressed
signal team_tactics_pressed  # -> the TEAM TACTICS modal
signal view_rival_pressed    # -> VIEW RIVAL
signal lineup_pressed        # -> back to LINE-UP
signal return_pressed        # -> hub

const W := 640
const H := 480

# --- binary-exact widget rects (FUN_00568800) ---
const PREDEF_BTN := Rect2(7, 373, 156, 29)
const LOAD_BTN := Rect2(7, 407, 156, 29)
const SAVE_BTN := Rect2(7, 443, 156, 29)
const PARAM_BTN := Rect2(478, 286, 72, 23)
const RATING_BTN := Rect2(558, 286, 72, 23)
const TEAM_BTN := Rect2(478, 330, 152, 25)
const RIVAL_BTN := Rect2(478, 365, 152, 25)
const LINEUP_BTN := Rect2(478, 400, 152, 25)
const RETURN_BTN := Rect2(498, 440, 112, 25)
const PITCH_TITLE := Rect2(177, 275, 278, 30)

# --- frame-baked geometry (tactics_chrome_samples.json) ---
const BODY_Y0 := 62
const ROW_Y0 := 87
const ROW_PITCH := 16
const ROW_X := 8
const NUM_CX := 41                 # shirt-number centre ("1" paints 39..42, "21" 35..46)
const NAME_X := 67
const STAR_X0 := 172
const STAR_PITCH := 14
const AV_RIGHT := 370              # right-aligned advance edge (painted ends 368)
const CAMROL_X := 375
const ROLE_CX := 484               # fine-role text centre on the band (EURO8 face)
const POS_CX := 605                # broad POS word centre in the white box
const MARK_ORIGIN := Vector2i(187, 310)
const BAND_DEF_MAX_MK1X := 52      # FUN_004fe2d0 thresholds, pre-scaled space
const BAND_FWD_MIN_MK2X := 211

# --- frame-sampled inks ---
const C_NUM := Color8(0, 0, 128)
const C_NAME := Color8(0, 0, 0)
const C_AV := Color8(210, 0, 0)
const C_ROLE := Color8(60, 80, 100)
const C_POS := Color8(0, 0, 0)
const C_TITLE := Color8(255, 255, 255)
const C_TOGGLE_ON := Color8(255, 255, 0)     # active toggle label (frame RATING)
const C_TOGGLE_OFF := Color8(140, 140, 200)  # inactive label (frame PARAM.)

# --- fine-ROLE long names (0x662db0, indexed posFine-1; positions_re.md) ---
const FINE_ROLE_LONG := ["GOALKEEPER", "RIGHT BACK", "LEFT BACK", "SWEEPER",
	"INSIDE CENTRE LEFT", "INSIDE CENTRE RIGHT", "RIGHT MIDFIELDER", "INSIDE RIGHT",
	"CENTRE FORWARD", "CENTRAL MIDFIELDER", "LEFT MIDFIELDER", "RIGHT WINGER",
	"CENTRAL STRIKER", "LEFT WINGER", "DEFENSIVE MIDFIELDER", "RIGHT FORWARD",
	"LEFT FORWARD", "INSIDE LEFT"]
const POS_WORD := {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

# PARAMETERS view column x (right-aligned) — the numeric view is UN-WALKED
# (no frame shows it on this screen); layout mirrors the header columns.
const COLS := [
	["EN", 178, "EN"], ["SP", 204, "VE"], ["ST", 230, "RE"], ["AG", 256, "AG"],
	["GU", 282, "CA"], ["FI", 308, "TI"], ["MO", 334, "RM"],
]

var _club: Dictionary = {}
var _tactics: Tactics = null
var _division := ""
var _season := "1997-98"
var _week := 0
var _header: Dictionary = {}   # match-header state (PMChrome.draw_match_header)
var _by_id: Dictionary = {}
var _rating_view := true   # frame default: RATING active
var _forms: Dictionary = {}   # name -> {gk_slot, slots:[{mk1,mk2}]}

var _f8: Font
var _f12: Font
var _feuro: Font                   # EURO8 — the ROLE-column face (frame-matched)
var _chrome: Texture2D
var _rows: Dictionary = {}          # band -> row template texture
var _star_on: Texture2D
var _star_off: Texture2D
var _disc: Texture2D
var _arrow: Texture2D
var _plate_on: Texture2D
var _plate_off: Texture2D
var _title_bar: Texture2D
var _disc_img: Image
var _arrow_img: Image
var _pm8_atlas: Image
var _digit_cells: Dictionary = {}   # "0".."9" -> {x,y,w,h,adv}
var _mark_cache: Dictionary = {}    # "d21"/"a21" -> ImageTexture
var _hits: Array = []      # [{r, kind}]
var _picker_open := false  # the PREDEF 10-formation overlay
var _scale := 1.0
var _origin := Vector2.ZERO

# PREDEF overlay geometry (FUN_0056f4c0): 451x250 body centred on 640x480; a 5x2
# thumbnail grid + CANCEL. Thumb k at rel ((k%5)*80+24, (k>4)*100+35).
const PICK_BODY := Rect2(94, 115, 451, 250)
const PICK_CANCEL := Rect2(94 + 170, 115 + 218, 110, 25)
const C_DKBTN := Color(0.08, 0.13, 0.26)
const C_DKBTN_HI := Color(0.28, 0.40, 0.66)
const C_BTN_LO := Color(0.06, 0.11, 0.22)
const C_BLUE := Color(0.20, 0.34, 0.62)
const C_BLUE_HI := Color(0.42, 0.56, 0.84)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_PITCH := Color(0.20, 0.47, 0.24)


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f12 = PMChrome.font("12")
	_feuro = load("res://art/fonts/euro8.fnt")
	_chrome = load("res://art/screens/tacticas/chrome.png")
	for band in ["gk", "def", "mid", "fwd"]:
		_rows[band] = load("res://art/screens/tacticas/row_%s.png" % band)
	_star_on = load("res://art/screens/tacticas/star_full.png")
	_star_off = load("res://art/screens/tacticas/star_off.png")
	_disc = load("res://art/icons/tacticas/dverde.png")
	_arrow = load("res://art/icons/tacticas/averde.png")
	_plate_on = load("res://art/screens/tacticas/plate_active.png")
	_plate_off = load("res://art/screens/tacticas/plate_inactive.png")
	_title_bar = load("res://art/screens/tacticas/title_bar.png")
	_disc_img = _disc.get_image()
	_disc_img.convert(Image.FORMAT_RGBA8)
	_arrow_img = _arrow.get_image()
	_arrow_img.convert(Image.FORMAT_RGBA8)
	# the BMFont atlas png is importer="skip" (the .fnt loader reads it raw)
	_pm8_atlas = Image.load_from_file("res://art/fonts/proman8.png")
	if _pm8_atlas != null:
		_pm8_atlas.convert(Image.FORMAT_RGBA8)
	_load_digit_cells()
	_load_formations()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


## ProMan8 digit cells from the BMFont file, for the marker-number composites.
func _load_digit_cells() -> void:
	var f := FileAccess.open("res://art/fonts/proman8.fnt", FileAccess.READ)
	if f == null:
		return
	while not f.eof_reached():
		var line := f.get_line()
		if not line.begins_with("char id="):
			continue
		var kv := {}
		for tok in line.split(" ", false):
			var eq := tok.find("=")
			if eq > 0:
				kv[tok.substr(0, eq)] = tok.substr(eq + 1)
		var cid := int(kv.get("id", "-1"))
		if cid >= 48 and cid <= 57:
			_digit_cells[char(cid)] = {"x": int(kv["x"]), "y": int(kv["y"]),
				"w": int(kv["width"]), "h": int(kv["height"]), "adv": int(kv["xadvance"])}


## The source-true 10-formation marker table (DAT_00660240 via export_formations.py;
## mk values PRE-SCALED into the 258x154 marker-layer space — drawn 1:1).
func _load_formations() -> void:
	var f := FileAccess.open("res://data/formations.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for rec in (d as Dictionary).get("formations", []):
			_forms[str(rec.get("name", ""))] = rec


func setup(club: Dictionary, tactics: Tactics, manager := "", division := "",
		season := "1997-98", week := 0, header := {}) -> void:
	_club = club
	_tactics = tactics
	_division = division
	_season = season
	_week = week
	_header = header
	if _header.is_empty():
		# manager-mode default (frame 058 layout): manager + own club, own kit.
		# Date derives from the week; the status pair is the only walked one.
		var d := PMChrome.date_parts(season, week)
		_header = {"mode": "manager", "top": manager,
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1)), "weekday": str(d["wd"]),
			"day": str(d["day"]), "month": str(d["mon"]), "year": str(d["year"])}
	_by_id.clear()
	for p in club.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	queue_redraw()


# ---- helpers -------------------------------------------------------------

## Displayed AV: frame-true "av" override wins (parity shots pin the frame's
## dynamic FI/MO); else the real rating (Morale.av6 = FUN_00581e60 — the table
## paint FUN_004f5260 draws this exact cell from it, morale_re.md) when the
## squad carries form, else the attrs-mean approximation.
func _av_of(p: Dictionary) -> int:
	if p.has("av"):
		return int(p["av"])
	if p.has("morale") or p.has("fitness"):
		return Morale.av6(p)
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


func _role_long(p: Dictionary) -> String:
	var pf := int(p.get("posFine", 0))
	if pf >= 1 and pf <= FINE_ROLE_LONG.size():
		return FINE_ROLE_LONG[pf - 1]
	return str(POS_WORD.get(str(p.get("pos", "")), "")) if p.get("pos") else "OUTFIELD"


func _pos_word(p: Dictionary) -> String:
	if bool(p.get("isGK", false)):
		return "GOAL"
	return str(POS_WORD.get(str(p.get("pos", "")), "OUT"))


## The shirt number PM98 prints: the decoded EQUIPOS squad number when the club's set
## is individuated (Man Utd in frame 014), else the XI slot ordinal (never invented).
func _shirt(p: Dictionary, slot: int) -> int:
	var no := int(p.get("squadNo", 0))
	return no if no > 0 else slot + 1


## Row tint band of an OUTFIELD formation slot (FUN_004fe2d0, decompiled 2026-07-03):
## slot mk1.x < 65 raw (52 pre-scaled) -> DEF; elif mk2.x < 0x104 raw (211) -> MID;
## else FWD. The tint tracks the SLOT a player occupies, not his POS (frame 014:
## Pallister DEF / Sheringham FOR both sit in MID slots -> lavender).
func _band_of_slot(slot_idx: int) -> String:
	var form: String = _tactics.formation if _tactics != null else "4-4-2"
	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary):
		return "mid"
	var slots: Array = (rec as Dictionary).get("slots", [])
	if slot_idx < 0 or slot_idx >= slots.size():
		return "mid"
	var s: Dictionary = slots[slot_idx]
	var mk1: Array = s.get("mk1", [0, 0])
	var mk2: Array = s.get("mk2", [0, 0])
	if int(mk1[0]) < BAND_DEF_MAX_MK1X:
		return "def"
	if int(mk2[0]) >= BAND_FWD_MIN_MK2X:
		return "fwd"
	return "mid"


func _hit(r: Rect2, kind: String) -> void:
	_hits.append({"r": r, "kind": kind})


## The game's GDI cell centring: px = cell_x0 + (cell_w - advance_w) div 2
## (integer floor — frame-fit across the N./AV/ROLE/POS cells of frame 014).
func _cell_centre(f: Font, s: String, x0: int, cw: int) -> float:
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
	return float(x0 + int(floorf((cw - w) / 2.0)))


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	_scale = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	PMChrome.draw_match_header(self, "tactics", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))

	_draw_rows()
	_draw_pitch_dynamic()
	_draw_toggle()
	_register_buttons()

	if _picker_open:
		_hits.clear()   # the overlay swallows all board hits while it is up
		_draw_picker()


func _draw_rows() -> void:
	var xi: Array = _tactics.xi if _tactics != null else []
	var gk_slot := 10
	var rec: Variant = _forms.get(_tactics.formation if _tactics != null else "")
	if rec is Dictionary:
		gk_slot = int((rec as Dictionary).get("gk_slot", 10))
	for i in mini(xi.size(), 11):
		var p: Variant = _by_id.get(int(xi[i]))
		if p == null:
			continue
		var pl: Dictionary = p
		var y := ROW_Y0 + ROW_PITCH * i
		var band := "gk" if i == 0 else _band_of_slot(i - 1)
		if _rows.get(band) != null:
			draw_texture(_rows[band], Vector2(ROW_X, y))

		# shirt number (navy, GDI cell-centred: "1" paints 39..42, "2" 37..43,
		# "21" 35..46) + name
		PMChrome.text(self, _f8, _cell_centre(_f8, str(_shirt(pl, i)), 33, 17), y + 2,
			str(_shirt(pl, i)), C_NUM, 11)
		PMChrome.text(self, _f8, NAME_X, y + 2, PMChrome.title_case_name(str(pl.get("name", "?"))),
			C_NAME, 11, 0, 103.0)

		var av := _av_of(pl)
		if _rating_view:
			# STARJUGON strip: halves=(AV+1) div 10; odd half = the DIMMED star.
			var halves := (av + 1) / 10
			for j in halves / 2:
				draw_texture(_star_on, Vector2(STAR_X0 + STAR_PITCH * j, y + 2))
			if halves % 2 == 1 and _star_off != null:
				draw_texture(_star_off, Vector2(STAR_X0 + STAR_PITCH * (halves / 2), y + 2))
		else:
			# PARAMETERS view (UN-WALKED on this screen — documented approximation).
			var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
			for c in COLS:
				var v: Variant = attrs.get(c[2])
				PMChrome.text(self, _f8, c[1], y + 2, str(int(v)) if v != null else "-", C_NAME, 11, 2)

		PMChrome.text(self, _f8, _cell_centre(_f8, str(av), 351, 22), y + 2, str(av), C_AV, 11)

		# camrol role-pitch sprite on its black backing (border ring is alpha-0
		# in the export; the frame shows it black — same as the FICHA cards)
		draw_rect(Rect2(CAMROL_X, y, 25, 14), Color.BLACK, true)
		PMChrome.draw_role_icon(self, Rect2(CAMROL_X, y, 25, 14),
			int(pl.get("posFine", 0)), str(pl.get("pos", "")))

		# fine-ROLE long name (EURO8 grey-blue) + broad POS word (ProMan8 black),
		# GDI cell-centred — cells/faces frame-measured.
		var role_s := _role_long(pl)
		PMChrome.text(self, _feuro, _cell_centre(_feuro, role_s, 402, 166), y + 2, role_s, C_ROLE, 11)
		var pos_s := _pos_word(pl)
		PMChrome.text(self, _f8, _cell_centre(_f8, pos_s, 590, 30), y + 2, pos_s, C_POS, 11)


const BAKED_FORM := "3-5-2"   # the formation whose bar background the chrome bakes


## Markers + the formation-title text (the clean pitch itself is baked chrome).
func _draw_pitch_dynamic() -> void:
	var form: String = _tactics.formation if _tactics != null else "4-4-2"
	if form != BAKED_FORM and _title_bar != null:
		# other formations: the mirror-reconstructed clean bar (documented
		# approximation for the un-walked centre columns) under the new title
		draw_texture(_title_bar, PITCH_TITLE.position)
	PMChrome.text(self, _f12, PITCH_TITLE.position.x, 284, "TACTICS %s" % form,
		C_TITLE, 13, 1, PITCH_TITLE.size.x)

	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary) or _tactics == null:
		return
	var slots: Array = (rec as Dictionary).get("slots", [])
	var gk_slot := int((rec as Dictionary).get("gk_slot", 10))
	var xi: Array = _tactics.xi
	# arrows first, discs on top (they never overlap in the source frame, but the
	# disc is the primary marker)
	for pass_i in 2:
		for i in mini(xi.size(), 11):
			var slot_idx := gk_slot if i == 0 else (i - 1)
			if slot_idx < 0 or slot_idx >= slots.size():
				continue
			var s: Dictionary = slots[slot_idx]
			var num := _shirt(_by_id[int(xi[i])], i) if _by_id.has(int(xi[i])) else i + 1
			var mk1: Array = s.get("mk1", [0, 0])
			var mk2: Array = s.get("mk2", [0, 0])
			if pass_i == 0:
				if mk1 != mk2:
					_draw_marker(false, int(mk2[0]), int(mk2[1]), num)
			else:
				_draw_marker(true, int(mk1[0]), int(mk1[1]), num)


## One marker: the 16x16 sprite top-left at (187+mk.x, 310+mk.y) 1:1 with the
## shirt number composited in (see _marker_tex).
func _draw_marker(disc: bool, mkx: int, mky: int, num: int) -> void:
	var tex := _marker_tex(disc, num)
	if tex != null:
		draw_texture(tex, Vector2(MARK_ORIGIN.x + mkx, MARK_ORIGIN.y + mky))


## DVERDE/AVERDE with the shirt number blitted in, RECT-CLIPPED to the marker's
## digit window — frame truth: the digits paint anywhere inside a 16-px (disc) /
## 13-px (arrow) wide window, INCLUDING over the grass at the sprite's transparent
## corners (slot9 "20" bottom-left), but never beyond it (the arrow "20"/"0" lose
## their overhanging columns). ProMan8 digits, glyph-cell top at sprite row 2
## (paints y4..10); ink dark-green (17,90,34) on discs, black on arrows;
## x = (window - advance) / 2 truncated toward zero.
func _marker_tex(disc: bool, num: int) -> Texture2D:
	var key := "%s%d" % ["d" if disc else "a", num]
	if _mark_cache.has(key):
		return _mark_cache[key]
	var src := _disc_img if disc else _arrow_img
	if src == null or _pm8_atlas == null or _digit_cells.is_empty():
		return _disc if disc else _arrow
	var img := src.duplicate() as Image
	var s := str(num)
	var w := 0
	for ch in s:
		w += int((_digit_cells.get(ch, {}) as Dictionary).get("adv", 0))
	var ink := Color8(17, 90, 34) if disc else Color8(0, 0, 0)
	var win := 16 if disc else 13
	var x := int((win - w) / 2.0)
	for ch in s:
		var c: Dictionary = _digit_cells.get(ch, {})
		if c.is_empty():
			continue
		for gy in int(c["h"]):
			for gx in int(c["w"]):
				if _pm8_atlas.get_pixel(int(c["x"]) + gx, int(c["y"]) + gy).a > 0.0:
					var tx := x + gx
					var ty := 2 + gy
					if tx >= 0 and tx < win and ty < img.get_height():
						img.set_pixel(tx, ty, ink)
		x += int(c["adv"])
	var tex := ImageTexture.create_from_image(img)
	_mark_cache[key] = tex
	return tex


## The frame bakes RATING-active / PARAM.-inactive. When the user flips to the
## numeric view, overlay the reconstructed plates (UN-WALKED state — the plates
## are the frame's own buttons with the labels cleared; documented extrapolation).
func _draw_toggle() -> void:
	if _rating_view:
		return
	if _plate_on != null:
		draw_texture(_plate_on, PARAM_BTN.position)
	if _plate_off != null:
		draw_texture(_plate_off, RATING_BTN.position)
	PMChrome.text(self, _f12, PARAM_BTN.position.x, PARAM_BTN.position.y + 6, "PARAM.",
		C_TOGGLE_ON, 13, 1, PARAM_BTN.size.x)
	PMChrome.text(self, _f12, RATING_BTN.position.x, RATING_BTN.position.y + 6, "RATING",
		C_TOGGLE_OFF, 13, 1, RATING_BTN.size.x)


## All buttons are baked chrome; only their hit-rects are live.
func _register_buttons() -> void:
	_hit(PREDEF_BTN, "predef")
	_hit(LOAD_BTN, "load")
	_hit(SAVE_BTN, "save")
	_hit(PARAM_BTN, "param")
	_hit(RATING_BTN, "rating")
	_hit(TEAM_BTN, "team")
	_hit(RIVAL_BTN, "rival")
	_hit(LINEUP_BTN, "lineup")
	_hit(RETURN_BTN, "return")


# ---- PREDEF overlay ------------------------------------------------------

## The 10-formation picker (FUN_0056f4c0): a dimmed backdrop, the body panel, a
## 5x2 grid of formation thumbnails (mini-pitch icon + name), and CANCEL. Each cell
## emits `pick:<form>`; Main applies it. Formation order = the source table order.
func _draw_picker() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.5), true)
	PMChrome.bevel(self, PICK_BODY, Color(0.30, 0.42, 0.62), Color(0.52, 0.64, 0.84),
		Color(0.12, 0.20, 0.38), 2.0)
	var title := Rect2(PICK_BODY.position.x + 4, PICK_BODY.position.y + 4, PICK_BODY.size.x - 8, 20)
	PMChrome.bevel(self, title, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	PMChrome.text(self, _f12, title.position.x, title.position.y + 4, "PREDEF. TACTICS",
		C_GOLD, 13, 1, title.size.x)

	var forms: Array = Tactics.FORMATION_ORDER
	for k in forms.size():
		var cell := Rect2(PICK_BODY.position.x + (k % 5) * 80 + 24,
			PICK_BODY.position.y + (0 if k < 5 else 100) + 35,
			80.0, 75.0 + (16.0 if k < 5 else 0.0))
		PMChrome.bevel(self, cell, C_BLUE, C_BLUE_HI, C_BTN_LO)
		# a mini pitch preview using the real formation markers.
		var pv := Rect2(cell.position.x + 6, cell.position.y + 4, cell.size.x - 12, cell.size.y - 22)
		draw_rect(pv, C_PITCH, true)
		_draw_picker_preview(pv, str(forms[k]))
		PMChrome.text(self, PMChrome.font("10"), cell.position.x, cell.end.y - 14, str(forms[k]),
			C_PANEL_TXT, 11, 1, cell.size.x)
		_hit(cell, "pick:%s" % forms[k])

	PMChrome.bevel(self, PICK_CANCEL, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	PMChrome.text(self, _f12, PICK_CANCEL.position.x, PICK_CANCEL.position.y + 6,
		"CANCEL", C_GOLD, 13, 1, PICK_CANCEL.size.x)
	_hit(PICK_CANCEL, "pick_cancel")


## Dots at each formation's primary markers, scaled into the thumbnail cell.
func _draw_picker_preview(pv: Rect2, form: String) -> void:
	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary):
		return
	for s in (rec as Dictionary).get("slots", []):
		var mk: Array = s.get("mk1", [0, 0])
		var p := pv.position + Vector2(float(mk[0]) / 258.0 * pv.size.x, float(mk[1]) / 154.0 * pv.size.y)
		draw_circle(p, 2.0, Color(0.75, 0.95, 0.6))


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin) / _scale


func _on_input(e: InputEvent) -> void:
	var pressed := (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed)
	if not pressed:
		return
	var d := _to_design(e.position)
	for h in _hits:
		if (h["r"] as Rect2).has_point(d):
			_activate(str(h["kind"]))
			return


func _activate(kind: String) -> void:
	if kind.begins_with("pick:"):
		_picker_open = false
		formation_picked.emit(kind.substr(5))
		queue_redraw()
		return
	match kind:
		"param":
			_rating_view = false
			queue_redraw()
		"rating":
			_rating_view = true
			queue_redraw()
		"predef":
			_picker_open = true
			predef_pressed.emit()
			queue_redraw()
		"pick_cancel":
			_picker_open = false
			queue_redraw()
		"load": load_pressed.emit()
		"save": save_pressed.emit()
		"team": team_tactics_pressed.emit()
		"rival": view_rival_pressed.emit()
		"lineup": lineup_pressed.emit()
		"return": return_pressed.emit()


# ---- PREDEF picker (called by Main to swap formation) --------------------

## Public helper: the ten formation names in PREDEF grid order (source table order),
## for Main's picker overlay.
static func predef_formations() -> Array:
	return Tactics.FORMATION_ORDER.duplicate()
