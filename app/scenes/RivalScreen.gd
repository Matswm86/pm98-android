extends Control
class_name RivalScreen
## PM98 VIEW RIVAL (VERRIVAL) screen — frame-baked body (docs/re/rival_screen_re.md;
## build_rival_chrome_from_frames.py; binding frame 015_162415, witness 151_154848).
## Chrome = the real frame with every career pixel cleared; this scene draws the
## dynamic layer with the game's PROMAN fonts + RECURSOS art:
##  - the rival XI table: the LINE-UP RATING row grammar at +2px (shirt N. navy,
##    name black x69, STARJUGON strip x174+14j with halves=(AV+1) div 10, fine-role
##    LONG name right-aligned to x351, AV red, CAMROL sprite, POS word),
##  - the right panel: NANOESC kit (walked club = frame patch, shadow pass), club
##    name on the white plate, TEAM RATING star-cell patches + value, assistant
##    name + shadowed STARPARON stars, PARAMETERS/RATING toggle,
##  - the big pitch: BRIGHT rival markers (DVERDE disc at mk1 + AVERDE arrow at
##    mk2, WHITE ProMan8 shirt digits, discs first arrows on top) and the OWN
##    team's GHOST markers mirrored (242-x, 138-y) through the engine's noise
##    dither (walked own-state = verbatim patches; else majority-LUT approx).
##
## THE DEFINING RULE (sourced, FUN_005733d0): report depth scales with your
## ASSISTANT — bVar2==0 shows only the hire-an-Assistant message. The app keeps
## the two states its data renders faithfully: q==0 message / q>=1 full report.
##
## Frame-injection levers for the parity shot (same doctrine as the AV gap):
## per-player `av`, club `team_rating`, club `rival_markers` (the walked marker
## list, kept because the frame also pins the XI). Live rivals draw their OWN
## stored tactic from club_tactics.json (EQUIPOS.PKF slot table — the exact
## struct FUN_005733d0 reads off the rival club object; Barcelona's decode
## reproduces the walked frame-015 layout, see rival_screen_re.md); clubs
## missing from the data fall back to Tactics.auto_pick + formations.json.

signal back_pressed
signal tactics_pressed

const W := 640
const H := 480
const BODY_Y0 := 62

# ---- table (frame-measured; the LINE-UP row grammar shifted +2px) ---------
const ROW_Y0 := 102
const ROW_PITCH := 16
const ROW_X := 11
const NUM_CELL := [35, 17]
const NAME_X := 69
const STAR_X0 := 174
const STAR_PITCH := 14
const ROLE_RIGHT := 351
const AV_CELL := [353, 22]
const CAMROL_X := 376
const POS_CELL := [403, 34]
const C_NUM := Color8(0, 0, 128)
const C_NAME := Color8(0, 0, 0)
const C_ROLE := Color8(100, 120, 140)
const C_AV := Color8(210, 0, 0)
const C_POS := Color8(0, 0, 0)
# PARAMETERS (numeric) view is UN-WALKED on this screen: cells centred under the
# static header letters, lineup-128 inks + sep grammar (documented approximation)
const NUM_SEPS := [173, 198, 223, 248, 273, 299, 324]
const NUM_CELLS := [[174, 25], [199, 25], [224, 25], [249, 25], [274, 25], [301, 25], [325, 25]]
const NUM_INKS := [Color8(150, 0, 0), Color8(100, 100, 140), Color8(100, 100, 140),
	Color8(100, 100, 140), Color8(100, 100, 140), Color8(42, 95, 170), Color8(80, 110, 5)]
const NUM_KEYS := ["EN", "VE", "RE", "AG", "CA", "_fit", "_mo"]
const SEP_INK := Color8(128, 128, 128)

const FINE_ROLE := ["KEEPER", "RIGHT BACK", "LEFT BACK", "SWEEPER",
	"INS. CENT. LEFT", "INS. CENT. RIGHT", "RIGHT MID.", "INSIDE RIGHT",
	"CENTRE FORWARD", "CENTRAL MID.", "LEFT MID.", "RIGHT WINGER",
	"CENTRAL STRIKER", "LEFT WINGER", "DEF. MIDFIELDER", "RIGHT FORWARD",
	"LEFT FORWARD", "INSIDE LEFT"]
const POS_WORD := {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}

# ---- right panel (FUN_005733d0 rects + frame-measured anchors) -------------
const TOGGLE_PARAM := Rect2(492, 85, 134, 21)
const TOGGLE_RATING := Rect2(492, 109, 134, 21)
const ARROW_X := 479
const CLUB_PLATE := Rect2(481, 155, 154, 18)
const CLUB_TEXT_Y := 159
const KIT_XY := Vector2(485, 174)
const STRIP_CELL_X0 := 516
const STRIP_CELL_PITCH := 15
const STRIP_CELL_Y := 186
const STRIP_VAL_RIGHT := 617
const STRIP_VAL_Y := 191
const C_STRIP_VAL := Color8(160, 160, 200)
const R_COMPUTER := Rect2(482, 205, 152, 15)
const R_TACTICS := Rect2(508, 395, 112, 25)
const R_RETURN := Rect2(508, 440, 112, 25)
const C_TOGGLE_ON := Color8(255, 255, 0)
const C_TOGGLE_OFF := Color8(160, 160, 200)

# ---- pitch (tacticas CAMPO 1:1; marker layer 258x154) ----------------------
const CAMPO_XY := Vector2(196, 300)
const MARK_XY := Vector2i(206, 305)
const MIRROR_X := 0xF2
const MIRROR_Y := 0x8A
const DIGIT_WIN_DISC := 16
const DIGIT_WIN_ARROW := 13
const GHOST_DIGIT_INK := Color8(127, 159, 85)  # dominant walked dim-digit tone (approx)

const HIRE_MSG := "In order to find information about the rival team\n\nyou need to hire an Assistant."

var _rival: Dictionary = {}
var _own: Dictionary = {}
var _own_tactics: Tactics = null
var _tactics: Tactics = null
var _assist_q: int = 0
var _assist_name: String = ""
var _human_manager: String = ""     # human player managing the RIVAL (club+0x5c), "" = COMPUTER
var _division: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _header: Dictionary = {}
var _by_id: Dictionary = {}
var _press := ""
var _rating_view := true
var _forms: Dictionary = {}
var _club_tactics: Dictionary = {}  # app club id (str) -> EQUIPOS.PKF own-tactic record
var _club_slots: Array = []         # rival's own slots, reordered [GK, DEF.., MID.., FWD..]
var _samples: Dictionary = {}

var _f8: Font
var _f10: Font
var _f12: Font
var _chrome: Texture2D
var _row_tex: Texture2D
var _star_on: Texture2D
var _star_off: Texture2D
var _plate_on_nude: Texture2D
var _plate_off_nude: Texture2D
var _arrow_at_param: Texture2D
var _arrow_off_rating: Texture2D
var _kit_patches: Dictionary = {}
var _nano_kits: Dictionary = {}
var _strip_full: Array = []
var _strip_nude: Texture2D
var _eq_on: Texture2D
var _eq_off: Texture2D
var _assist_stars4: Texture2D
var _paron_on: Texture2D
var _paron_off: Texture2D
var _campo_img: Image
var _disc_img: Image
var _arrow_img: Image
var _arrow_flip_img: Image
var _ghost_patch: Dictionary = {}   # "slot_phase" -> Image
var _ghost_lut: Dictionary = {}     # "r,g,b" -> [r,g,b]
var _digit_cells: Dictionary = {}
var _pm8_atlas: Image
var _pitch_cache_key := ""
var _pitch_tex: Texture2D


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_chrome = load("res://art/screens/rival/chrome.png")
	_row_tex = load("res://art/screens/rival/row.png")
	_star_on = load("res://art/screens/tacticas/star_full.png")
	_star_off = load("res://art/screens/tacticas/star_off.png")
	_plate_on_nude = load("res://art/screens/rival/plate_on_nude.png")
	_plate_off_nude = load("res://art/screens/rival/plate_off_nude.png")
	_arrow_at_param = load("res://art/screens/rival/arrow_at_param.png")
	_arrow_off_rating = load("res://art/screens/rival/arrow_off_rating.png")
	_kit_patches[1000] = load("res://art/screens/rival/kit_1000.png")
	for j in 4:
		_strip_full.append(load("res://art/screens/rival/strip_star_full_%d.png" % j))
	_strip_nude = load("res://art/screens/rival/strip_star_nude.png")
	_eq_on = load("res://art/screens/rival/star_eq_on.png")
	_eq_off = load("res://art/screens/rival/star_eq_off.png")
	_assist_stars4 = load("res://art/screens/rival/assist_stars_4.png")
	_paron_on = load("res://art/screens/lineup/star_paron_on.png")
	_paron_off = load("res://art/screens/lineup/star_paron_off.png")
	_campo_img = _img("res://art/screens/rival/campo.png")
	_disc_img = _img("res://art/icons/tacticas/dverde.png")
	_arrow_img = _img("res://art/icons/tacticas/averde.png")
	if _arrow_img != null:
		_arrow_flip_img = _arrow_img.duplicate()
		_arrow_flip_img.flip_x()
	_load_samples()
	_load_formations()
	_load_club_tactics()
	_load_digit_cells()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func _img(path: String) -> Image:
	var t: Texture2D = load(path)
	if t == null:
		return null
	var im := t.get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im


func _load_samples() -> void:
	var f := FileAccess.open("res://data/rival_chrome_samples.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_samples = d
		_ghost_lut = _samples.get("ghost_lut", {})
		for b in _ghost_lut_boxes():
			var tag := "ghost_352_%d_%d" % [int(b["slot"]), int(b["phase"])]
			_ghost_patch[tag] = _img("res://art/screens/rival/%s.png" % tag)


func _ghost_lut_boxes() -> Array:
	return (_samples.get("ghosts_352", {}) as Dictionary).get("boxes", [])


func _load_formations() -> void:
	var f := FileAccess.open("res://data/formations.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for rec in (d as Dictionary).get("formations", []):
			_forms[str(rec.get("name", ""))] = rec


## Every club's OWN stored tactic, decoded from the EQUIPOS.PKF per-club .DBC
## records (tools/re/export_club_tactics.py; MANAGER.EXE FUN_00579c70 slot block —
## the same 11x0x20 slot struct VIEW RIVAL draws from the rival club object).
func _load_club_tactics() -> void:
	var f := FileAccess.open("res://data/club_tactics.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_club_tactics = (d as Dictionary).get("clubs", {})


## ProMan8 digit glyph cells (BMFont) for the marker-number composites.
## Via PMFont — neither the raw .fnt nor the source png is in an exported build.
func _load_digit_cells() -> void:
	var tbl := PMFont.chars("proman8")
	for cid in range(48, 58):
		if not tbl.has(cid):
			continue
		var g: Dictionary = tbl[cid]
		var r: Rect2i = g["rect"]
		_digit_cells[char(cid)] = {"x": r.position.x, "y": r.position.y,
			"w": r.size.x, "h": r.size.y, "adv": int(g["adv"])}
	_pm8_atlas = PMFont.page("proman8").duplicate()
	_pm8_atlas.convert(Image.FORMAT_RGBA8)


## Feed the RIVAL club, the manager's OWN club + tactics (the ghost overlay is YOUR
## planned shape mirrored onto the scouting pitch), the assistant gate + name, and
## the calendar/header data.
## `human_manager` is the name of the HUMAN PLAYER managing the rival club, "" when
## none — see `_draw_manager_box` for the binary's own rule. This engine holds one
## career save (SeleccionScreen's declared hot-seat gap), so it is always "" today.
func setup(rival: Dictionary, own: Dictionary, assist_quality: int, assist_name: String = "",
		division: String = "", season: String = "1997-98", week: int = 0, header := {},
		own_tactics: Tactics = null, human_manager: String = "") -> void:
	_human_manager = human_manager.strip_edges()
	_rival = rival
	_own = own
	_own_tactics = own_tactics
	_assist_q = maxi(0, assist_quality)
	_assist_name = assist_name
	_division = division
	_season = season
	_week = week
	_header = header
	if _header.is_empty():
		var d := PMChrome.date_parts(season, week)
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(own.get("name", ""))),
			"club_id": int(own.get("id", -1)), "weekday": str(d["wd"]),
			"day": str(d["day"]), "month": str(d["mon"]), "year": str(d["year"])}
	# The rival fields its OWN stored shape AND (when game_db-complete) its OWN
	# SHIPPED XI — the .DBC squad records' player+0x1b slot bytes (FUN_00579c70's
	# squad loop; XI slot s stands at tactic slot s-1, so the slots pair with the
	# XI in NATIVE .DBC order). Clubs whose xi has game_db holes (old-cipher squad
	# corruption, see export_club_tactics.py) keep the auto-pick + band-reorder.
	_club_slots = []
	_tactics = null
	var rec: Variant = _club_tactics.get(str(int(rival.get("id", -1))))
	var rec_slots: Array = (rec as Dictionary).get("slots", []) if rec is Dictionary else []
	if rec_slots.size() == 11:
		var d0 := 0
		var m0 := 0
		for i in range(1, rec_slots.size()):
			match _slot_band(rec_slots[i]):
				"DEF": d0 += 1
				"MID": m0 += 1
		var f0 := rec_slots.size() - 1 - d0 - m0
		var xi_ids := _shipped_xi(rec, rival)
		if not xi_ids.is_empty():
			_club_slots = rec_slots
			_tactics = Tactics.with_xi(rival, xi_ids, d0, m0, f0)
		else:
			_club_slots = _club_slot_order(int(rival.get("id", -1)))
			_tactics = Tactics.auto_pick_shape(rival, d0, m0, f0)
	elif not rival.is_empty():
		_tactics = Tactics.auto_pick(rival)
	_by_id.clear()
	for p in rival.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	_pitch_cache_key = ""
	queue_redraw()


func has_report() -> bool:
	return _assist_q > 0


# ---- input -----------------------------------------------------------------

func _hit(d: Vector2) -> String:
	if R_RETURN.has_point(d):
		return "return"
	if R_TACTICS.has_point(d):
		return "tactics"
	if TOGGLE_PARAM.has_point(d):
		return "param"
	if TOGGLE_RATING.has_point(d):
		return "rating"
	return ""


func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


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
			match a:
				"return": back_pressed.emit()
				"tactics": tactics_pressed.emit()
				"param":
					_rating_view = false
					queue_redraw()
				"rating":
					_rating_view = true
					queue_redraw()


# ---- helpers ----------------------------------------------------------------

func _cell_centre(f: Font, s: String, x0: int, cw: int, sz := 11) -> float:
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	return float(x0 + int(floorf((cw - w) / 2.0)))


## GHOST (own-team) digits only: the dim mirrored markers carry the player's
## REAL squad number (walked run-2 own-state: MU shirts 1,2,3,21,6,8,7,10,9,
## 11,20). Rival BRIGHT digits + the table N. column use the slot number 1..11
## instead (frame 015) — do not route them through here.
func _shirt(p: Dictionary, slot: int) -> int:
	var no_v: Variant = p.get("squadNo")
	var no := int(no_v) if (no_v is int or no_v is float) else 0
	return no if no > 0 else slot + 1


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
	for k in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0


func _role_name(p: Dictionary) -> String:
	var fine := int(p.get("posFine", 0))
	if fine >= 1 and fine <= FINE_ROLE.size():
		return FINE_ROLE[fine - 1]
	return str(p.get("pos", ""))


func _pos_word(p: Dictionary) -> String:
	return str(POS_WORD.get(str(p.get("pos", "")).to_upper(), str(p.get("pos", ""))))


## TEAM RATING = sum of the XI's AVs, SKIPPING injured/banned men
## (FUN_005836a0), over a FIXED /11 (FUN_004fe540: FUN_0057a3a0() / 0xb) —
## walked proof: frame 155 shows 77 = (936 - Beckham's 88) / 11, frame 015
## shows 87 = 959 / 11 (morale_re.md).
func _team_rating() -> int:
	if _rival.has("team_rating"):
		return int(_rival["team_rating"])
	if _tactics == null:
		return 0
	var sum := 0
	for pid in _tactics.xi:
		var p: Variant = _by_id.get(int(pid))
		if p != null and Availability.is_available(p):
			sum += _av_of(p)
	return sum / 11


# ---- drawing ------------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "viewrival", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))

	if has_report():
		_draw_rows()
		_draw_pitch()
	else:
		_draw_hire_message()
	_draw_right_panel()


func _draw_hire_message() -> void:
	var y := 170
	for line in HIRE_MSG.split("\n"):
		PMChrome.text(self, _f12, 11, y, line, Color8(0, 0, 0), 13, 1, 460.0)
		y += 18


func _draw_rows() -> void:
	if _tactics == null:
		return
	for i in mini(_tactics.xi.size(), 11):
		var y := ROW_Y0 + ROW_PITCH * i
		var p: Variant = _by_id.get(int(_tactics.xi[i]))
		if _row_tex != null:
			draw_texture(_row_tex, Vector2(ROW_X, y))
		if p == null:
			continue
		var pl: Dictionary = p
		# N. column = the row/slot number 1..11, NOT the stored squad number:
		# frame 015 reads Hesp=1..Rivaldo=11 while Barcelona's .DBC squadNos are
		# [13,22,3,4,5,12,7,21,9,10,11]. (Pre-rebuild data had no intl squadNo,
		# so the old _shirt fallback was accidentally frame-correct.)
		var num := str(i + 1)
		PMChrome.text(self, _f8, _cell_centre(_f8, num, NUM_CELL[0], NUM_CELL[1]), y + 2,
			num, C_NUM, 11)
		PMChrome.text(self, _f8, NAME_X, y + 2,
			PMChrome.title_case_name(str(pl.get("name", "?"))), C_NAME, 11, 0, 103.0)
		var av := _av_of(pl)
		if _rating_view:
			# STARJUGON strip: halves=(AV+1) div 10; odd half = the DIMMED star
			var halves := (av + 1) / 10
			for j in halves / 2:
				draw_texture(_star_on, Vector2(STAR_X0 + STAR_PITCH * j, y + 2))
			if halves % 2 == 1 and _star_off != null:
				draw_texture(_star_off, Vector2(STAR_X0 + STAR_PITCH * (halves / 2), y + 2))
			PMChrome.text(self, _f8, ROLE_RIGHT, y + 2, _role_name(pl), C_ROLE, 11, 2)
		else:
			for sx in NUM_SEPS:
				draw_rect(Rect2(sx, y + 1, 1, 12), SEP_INK, true)
			var has_form: bool = pl.has("morale") or pl.has("fitness")
			for ci in NUM_KEYS.size():
				var key: String = NUM_KEYS[ci]
				var sv := ""
				match key:
					"_fit":
						sv = str(clampi(int(pl.get("fitness", 99)), 0, 99)) if has_form else "-"
					"_mo":
						sv = str(Morale.display(pl)) if has_form else "-"
					_:
						var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
						var v: Variant = attrs.get(key)
						sv = str(int(v)) if v != null else "-"
				PMChrome.text(self, _f8, _cell_centre(_f8, sv, NUM_CELLS[ci][0], NUM_CELLS[ci][1]),
					y + 2, sv, NUM_INKS[ci], 11)
		PMChrome.text(self, _f8, _cell_centre(_f8, str(av), AV_CELL[0], AV_CELL[1]), y + 2,
			str(av), C_AV, 11)
		PMChrome.draw_role_icon(self, Rect2(CAMROL_X, y, 25, 14),
			int(pl.get("posFine", 0)), str(pl.get("pos", "")))
		var pos_s := _pos_word(pl)
		PMChrome.text(self, _f8, _cell_centre(_f8, pos_s, POS_CELL[0], POS_CELL[1]), y + 2,
			pos_s, C_POS, 11)


# ---- right panel ---------------------------------------------------------------

func _draw_right_panel() -> void:
	# toggle: chrome bakes RATING-active; the flip is UN-WALKED -> label-cleared
	# plates + redrawn labels + swapped arrow patches (tactics-board doctrine)
	if not _rating_view:
		if _plate_on_nude != null:
			draw_texture(_plate_on_nude, TOGGLE_PARAM.position)
		PMChrome.text(self, _f12, TOGGLE_PARAM.position.x, TOGGLE_PARAM.position.y + 5,
			"PARAMETERS", C_TOGGLE_ON, 13, 1, TOGGLE_PARAM.size.x)
		if _plate_off_nude != null:
			draw_texture(_plate_off_nude, TOGGLE_RATING.position)
		PMChrome.text(self, _f12, TOGGLE_RATING.position.x, TOGGLE_RATING.position.y + 5,
			"RATING", C_TOGGLE_OFF, 13, 1, TOGGLE_RATING.size.x)
		if _arrow_at_param != null:
			draw_texture(_arrow_at_param, Vector2(ARROW_X, TOGGLE_PARAM.position.y))
		if _arrow_off_rating != null:
			draw_texture(_arrow_off_rating, Vector2(ARROW_X, TOGGLE_RATING.position.y))

	# rival club name on the black plate (WHITE ink, GDI-centred)
	var nm := PMChrome.title_case_name(str(_rival.get("name", "")))
	PMChrome.text(self, _f10, _cell_centre(_f10, nm, int(CLUB_PLATE.position.x),
		int(CLUB_PLATE.size.x), 10), CLUB_TEXT_Y, nm, Color8(255, 255, 255), 10)

	# NANOESC kit: walked club = frame patch (engine shadow pass); else the
	# shadowless sprite (header-bake precedent, documented)
	var cid := int(_rival.get("id", -1))
	if _kit_patches.has(cid) and _kit_patches[cid] != null:
		draw_texture(_kit_patches[cid], KIT_XY)
	else:
		var kt := _nano_kit(cid)
		if kt != null:
			draw_texture_rect_region(kt, Rect2(KIT_XY.x, KIT_XY.y, 24, 31), Rect2(0, 0, 24, 31))

	# TEAM RATING stars + value (hidden without an assistant, sourced bVar2>=1)
	if has_report():
		var tr := _team_rating()
		var halves := (tr + 1) / 10
		for j in 5:
			var x := STRIP_CELL_X0 + STRIP_CELL_PITCH * j
			if j < halves / 2:
				if j < 4 and _strip_full[j] != null:
					draw_texture(_strip_full[j], Vector2(x, STRIP_CELL_Y))
				elif _eq_on != null:  # un-walked 5th full star: plain glyph
					draw_texture(_eq_on, Vector2(x + 1, STRIP_CELL_Y + 6))
			elif j == halves / 2 and halves % 2 == 1 and _eq_off != null:
				# un-walked odd half: dimmed glyph (walked ratings show none)
				draw_texture(_eq_off, Vector2(x + 1, STRIP_CELL_Y + 6))
		PMChrome.text(self, _f10, STRIP_VAL_RIGHT, STRIP_VAL_Y, str(tr), C_STRIP_VAL, 10, 2)

	# The COMPUTER band is baked. FUN_005733d0 @0x573b0a:
	#     iVar8 = club[0x5c]; puVar10 = PTR_s_COMPUTER_00662da8;
	#     if (iVar8 != 0xffff) puVar10 = DAT_0066c178 + iVar8 * 0x9c;
	# club+0x5c is the HUMAN-PLAYER slot index (0xffff = none) and DAT_0066c178 is
	# the human players' record table — so this box names a HUMAN opponent in a
	# hot-seat game and reads the literal COMPUTER otherwise. It is NOT the club's
	# EQUIPOS manager (that name belongs to the LINE-UP roll header and START OF
	# SEASON, where it is witnessed): drawing it here painted "Van Gaal" over
	# frame 015's COMPUTER, the 440 px `diff_entry_parity` failure.
	var mgr := _human_manager
	if mgr != "":
		draw_rect(Rect2(R_COMPUTER.position.x + 2, R_COMPUTER.position.y + 2,
			R_COMPUTER.size.x - 4, R_COMPUTER.size.y - 4), Color8(0, 0, 128), true)
		PMChrome.text(self, _f10, _cell_centre(_f10, mgr, int(R_COMPUTER.position.x),
			int(R_COMPUTER.size.x), 10), int(R_COMPUTER.position.y) + 3, mgr,
			Color8(160, 160, 200), 10)

	_draw_assistant()


func _draw_assistant() -> void:
	var a: Dictionary = _samples.get("assist", {})
	if a.is_empty():
		return
	if _assist_name != "":
		PMChrome.text(self, _f10, int(a["name_x"]), int(a["band"][1]) + 1,
			PMChrome.title_case_name(_assist_name), Color8(255, 255, 255), 10, 0, 100.0)
	var q := _assist_q
	if q == int(a.get("walked_count", 4)) and _assist_stars4 != null:
		# the walked 4-star strip verbatim (glyphs + noise-dither shadow)
		draw_texture(_assist_stars4, Vector2(int(a["stars4_xy"][0]), int(a["stars4_xy"][1])))
	else:
		# un-walked count: plain STARPARON glyphs (shadow approx, documented)
		for j in clampi(q, 0, 5):
			draw_texture(_paron_on, Vector2(int(a["star_x0"]) + 11 * j, int(a["star_y"])))


func _nano_kit(id: int) -> Texture2D:
	if not _nano_kits.has(id):
		var path := "res://art/kits/nano/%d.png" % id
		_nano_kits[id] = load(path) if ResourceLoader.exists(path) else null
	return _nano_kits[id]


# ---- pitch ------------------------------------------------------------------------

## The rival's marker list, in priority order:
##  1. the frame-injected walked layout (parity shots pin the frame),
##  2. the club's OWN stored tactic from EQUIPOS.PKF (club_tactics.json — the
##     slot table VIEW RIVAL reads off the rival club object, FUN_005733d0),
##  3. the stock formation through formations.json (clubs missing from the data).
func _rival_markers() -> Array:
	if _rival.has("rival_markers"):
		return _rival["rival_markers"]
	var out: Array = []
	if _tactics == null:
		return out
	if not _club_slots.is_empty():
		for i in mini(_tactics.xi.size(), _club_slots.size()):
			var s: Dictionary = _club_slots[i]
			# Rival BRIGHT digits = the slot number 1..11 (walked frame 015:
			# discs read 1..11 while Barcelona's stored squadNos don't).
			var num := i + 1
			out.append({"kind": "disc", "mk": s.get("mk1", [0, 0]), "num": num})
			out.append({"kind": "arrow", "mk": s.get("mk2", [0, 0]), "num": num})
		return out
	var rec: Variant = _forms.get(_tactics.formation)
	if rec == null:
		return out
	var slots: Array = (rec as Dictionary).get("slots", [])
	var gk := int((rec as Dictionary).get("gk_slot", 10))
	var order := [gk]
	for i in slots.size():
		if i != gk:
			order.append(i)
	for i in mini(_tactics.xi.size(), order.size()):
		var s: Dictionary = slots[order[i]]
		# Same frame-015 rule as the club-slots path: rival digits = slot 1..11.
		var num := i + 1
		out.append({"kind": "disc", "mk": s.get("mk1", [0, 0]), "num": num})
		out.append({"kind": "arrow", "mk": s.get("mk2", [0, 0]), "num": num})
	return out


## The club's SHIPPED XI as 11 game_db ids in slot order, or [] when any slot
## is unmatched in game_db (-1) or the id is missing from the squad dict.
func _shipped_xi(rec: Dictionary, rival: Dictionary) -> Array:
	var xi: Array = rec.get("xi", [])
	if xi.size() != 11:
		return []
	var have := {}
	for p in rival.get("players", []):
		have[int(p.get("id", -1))] = true
	var ids: Array = []
	for v in xi:
		var pid := int(v)
		if pid < 0 or not have.has(pid):
			return []
		ids.append(pid)
	return ids


## The band a slot belongs to, by the sourced row-tint rule (FUN_004fe2d0):
## mk1.x_raw < 0x41 -> DEF, elif mk2.x_raw < 0x104 -> MID, else FWD.
func _slot_band(slot: Dictionary) -> String:
	var raw: Array = slot.get("raw", [])
	if raw.size() < 8:
		return "MID"
	if int(raw[4]) < 0x41:
		return "DEF"
	if int(raw[6]) < 0x104:
		return "MID"
	return "FWD"


## The rival club's own tactic slots reordered [GK, DEF.., MID.., FWD..] so they
## pair with the auto-picked XI order. GK = slot 0 (holds in all 476 shipped
## records: mk1 == mk2 == the (0,68) park spot); outfield slots keep their .DBC
## order within each band. Empty when the club is not in club_tactics.json.
func _club_slot_order(club_id: int) -> Array:
	var rec: Variant = _club_tactics.get(str(club_id))
	if rec == null:
		return []
	var slots: Array = (rec as Dictionary).get("slots", [])
	if slots.size() != 11:
		return []
	var defs: Array = []
	var mids: Array = []
	var fwds: Array = []
	for i in range(1, slots.size()):
		match _slot_band(slots[i]):
			"DEF": defs.append(slots[i])
			"MID": mids.append(slots[i])
			_: fwds.append(slots[i])
	return [slots[0]] + defs + mids + fwds


## Own (ghost) slot list: [mk1, mk2, shirt] per XI slot, GK first.
func _own_ghosts() -> Array:
	var out: Array = []
	if _own_tactics == null:
		return out
	var rec: Variant = _forms.get(_own_tactics.formation)
	if rec == null:
		return out
	var slots: Array = (rec as Dictionary).get("slots", [])
	var gk := int((rec as Dictionary).get("gk_slot", 10))
	var order := [gk]
	for i in slots.size():
		if i != gk:
			order.append(i)
	var own_by_id := {}
	for p in _own.get("players", []):
		own_by_id[int(p.get("id", -1))] = p
	for i in mini(_own_tactics.xi.size(), order.size()):
		var s: Dictionary = slots[order[i]]
		var p: Variant = own_by_id.get(int(_own_tactics.xi[i]))
		var num := _shirt(p if p is Dictionary else {}, i)
		out.append([s.get("mk1", [0, 0]), s.get("mk2", [0, 0]), num])
	return out


func _pitch_key(markers: Array, ghosts: Array) -> String:
	return JSON.stringify([markers, ghosts])


func _draw_pitch() -> void:
	var markers := _rival_markers()
	var ghosts := _own_ghosts()
	if markers.is_empty() and ghosts.is_empty():
		return
	var key := _pitch_key(markers, ghosts)
	if key != _pitch_cache_key or _pitch_tex == null:
		_pitch_tex = _compose_pitch(markers, ghosts)
		_pitch_cache_key = key
	if _pitch_tex != null:
		draw_texture(_pitch_tex, CAMPO_XY)


## Compose campo + ghost pass + bright pass into one cached texture (278x167).
func _compose_pitch(markers: Array, ghosts: Array) -> Texture2D:
	if _campo_img == null:
		return null
	var img := _campo_img.duplicate() as Image
	var mx0: int = MARK_XY.x - int(CAMPO_XY.x)
	var my0: int = MARK_XY.y - int(CAMPO_XY.y)

	# ---- ghost pass (own team mirrored, dim) --------------------------------
	var walked: Dictionary = _samples.get("ghosts_352", {})
	var walked_nums: Array = []
	for n in walked.get("nums", []):
		walked_nums.append(int(n))
	var own_nums: Array = []
	for g in ghosts:
		own_nums.append(int(g[2]))
	var own_is_walked: bool = (
		_own_tactics != null and _own_tactics.formation == str(walked.get("formation", ""))
		and own_nums == walked_nums
	)
	var rival_is_walked: bool = _rival.has("rival_markers")
	if own_is_walked:
		for b in walked.get("boxes", []):
			var clean := bool(b.get("clean", false))
			if not (clean or rival_is_walked):
				continue
			var tag := "ghost_352_%d_%d" % [int(b["slot"]), int(b["phase"])]
			var patch: Image = _ghost_patch.get(tag)
			if patch != null:
				img.blit_rect(patch, Rect2i(0, 0, 16, 16),
					Vector2i(mx0 + int(b["mk"][0]), my0 + int(b["mk"][1])))
	# un-walked own states (or poisoned boxes vs a live rival): majority-LUT
	# dim composite — a documented approximation of the engine's noise dither
	for gi in ghosts.size():
		var g: Array = ghosts[gi]
		for phase in 2:
			if own_is_walked and _has_walked_box(walked, gi, phase + 1, rival_is_walked):
				continue
			var mk: Array = g[phase]
			var gx: int = MIRROR_X - int(mk[0])
			var gy: int = MIRROR_Y - int(mk[1])
			_blit_ghost_lut(img, mx0 + gx, my0 + gy, phase == 0, int(g[2]))

	# ---- bright pass (rival; discs first, arrows on top) --------------------
	for kind in ["disc", "arrow"]:
		for m in markers:
			if str(m["kind"]) != kind:
				continue
			var src: Image = _disc_img if kind == "disc" else _arrow_img
			if src == null:
				continue
			var mark := _marker_img(src, int(m["num"]), kind == "disc")
			_blend(img, mark, mx0 + int(m["mk"][0]), my0 + int(m["mk"][1]))
	return ImageTexture.create_from_image(img)


func _has_walked_box(walked: Dictionary, slot: int, phase: int, rival_is_walked: bool) -> bool:
	for b in walked.get("boxes", []):
		if int(b["slot"]) == slot and int(b["phase"]) == phase:
			return bool(b.get("clean", false)) or rival_is_walked
	return false


## Sprite blit honouring alpha.
func _blend(dst: Image, src: Image, x: int, y: int) -> void:
	for yy in src.get_height():
		for xx in src.get_width():
			var c := src.get_pixel(xx, yy)
			if c.a > 0.0 and x + xx >= 0 and x + xx < dst.get_width() \
					and y + yy >= 0 and y + yy < dst.get_height():
				dst.set_pixel(x + xx, y + yy, c)


## Marker sprite + WHITE ProMan8 shirt digits (window 16 disc / 13 arrow, glyph
## top at sprite row 2, GDI x=(win-adv)/2 — frame-verified on all 21 markers).
func _marker_img(src: Image, num: int, disc: bool) -> Image:
	var img := src.duplicate() as Image
	if _pm8_atlas == null or _digit_cells.is_empty():
		return img
	var s := str(num)
	var w := 0
	for ch in s:
		w += int((_digit_cells.get(ch, {}) as Dictionary).get("adv", 0))
	var win := DIGIT_WIN_DISC if disc else DIGIT_WIN_ARROW
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
						img.set_pixel(tx, ty, Color.WHITE)
		x += int(c["adv"])
	return img


## Ghost fallback: sprite (flipped arrow for phase 2) mapped through the
## majority dim LUT + dim digits (documented approximation of the noise pass).
func _blit_ghost_lut(dst: Image, x: int, y: int, disc: bool, num: int) -> void:
	var spr: Image = _disc_img if disc else _arrow_flip_img
	if spr == null:
		return
	var mark := _marker_img_ghost(spr, num, disc)
	for yy in mark.get_height():
		for xx in mark.get_width():
			if x + xx < 0 or x + xx >= dst.get_width() or y + yy < 0 or y + yy >= dst.get_height():
				continue
			var c := mark.get_pixel(xx, yy)
			if c.a <= 0.0:
				continue
			var k := "%d,%d,%d" % [int(c.r * 255.0 + 0.5), int(c.g * 255.0 + 0.5), int(c.b * 255.0 + 0.5)]
			if _ghost_lut.has(k):
				var v: Array = _ghost_lut[k]
				dst.set_pixel(x + xx, y + yy, Color8(int(v[0]), int(v[1]), int(v[2])))
			else:
				dst.set_pixel(x + xx, y + yy, c)


func _marker_img_ghost(src: Image, num: int, disc: bool) -> Image:
	var img := src.duplicate() as Image
	if _pm8_atlas == null or _digit_cells.is_empty():
		return img
	var s := str(num)
	var w := 0
	for ch in s:
		w += int((_digit_cells.get(ch, {}) as Dictionary).get("adv", 0))
	var win := DIGIT_WIN_DISC if disc else DIGIT_WIN_ARROW
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
						img.set_pixel(tx, ty, GHOST_DIGIT_INK)
		x += int(c["adv"])
	return img
