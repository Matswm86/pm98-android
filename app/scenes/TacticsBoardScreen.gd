extends Control
class_name TacticsBoardScreen
## PM98 TACTICS board (TACTICAS), rebuilt to match the real game (frame 014_162413,
## docs/re/tacticas_screen_re.md). Distinct from the TEAM TACTICS modal
## (TacticsScreen.gd = the ATTACK|DEFENCE panel): this is the outer screen titled
## "TACTICS <club>" reached from LINE-UP's TACTICS button.
##
## It shows the XI (11 starters) with the full fine-ROLE name + broad POS columns,
## a skill-emphasis grid, the three PREDEF / LOAD / SAVE TACTICS buttons, and the big
## CAMPO pitch carrying the current formation's two-phase markers (green disc =
## defensive phase, movement arrow = attacking phase) placed by the real
## DAT_00660240 coordinate table (app/data/formations.json). PARAM. / RATING toggles
## the stat columns; TEAM TACTICS / VIEW RIVAL / LINE-UP / RETURN navigate. Native
## 640x480; scales to fit its parent (same transform as LINE-UP / RIVAL).
##
## Widget rects are binary-exact (FUN_00568800); the XI table geometry is measured
## from frame 014. The per-slot ROLE-reassignment arrow is drawn but read-only (the
## app has no role-override model — see tacticas_screen_re.md "Honest gaps").

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
const SKILL_GRID := Rect2(7, 275, 156, 91)
const PITCH_TITLE := Rect2(177, 275, 278, 30)
const PITCH := Rect2(177, 305, 278, 167)
# marker child layer inside the pitch (rel (10,5), size 258x154), from FUN_00568800.
const MARK_ORIGIN := Vector2(187, 310)
const MARK_W := 258.0
const MARK_H := 154.0

# --- XI table geometry (measured from frame 014) ---
const TABLE := Rect2(6, 48, 630, 220)
const HDR_Y := 52
const XI_Y0 := 66
const ROW_H := 18
const ROW_X := 8
const ROW_W := 624
const STAT_X0 := 158
const STAT_X1 := 348
const AV_X := 356
const ROLE_ICON_X := 414
const ROLE_BAND := Rect2(430, 0, 116, 0)   # x/w only; y/h per-row
const ROLE_ARROW_X := 550
const POS_BOX := Rect2(586, 0, 46, 0)       # x/w only
# The 7 attribute columns (right-aligned x), PARAMETERS view. GU (not QU) per header.
const COLS := [
	["EN", 178, "EN"], ["SP", 204, "VE"], ["ST", 230, "RE"], ["AG", 256, "AG"],
	["GU", 282, "CA"], ["FI", 308, "TI"], ["MO", 334, "RM"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

# --- fine-ROLE long names (0x662db0, indexed posFine-1; positions_re.md) ---
const FINE_ROLE_LONG := ["GOALKEEPER", "RIGHT BACK", "LEFT BACK", "SWEEPER",
	"INSIDE CENTRE LEFT", "INSIDE CENTRE RIGHT", "RIGHT MIDFIELDER", "INSIDE RIGHT",
	"CENTRE FORWARD", "CENTRAL MIDFIELDER", "LEFT MIDFIELDER", "RIGHT WINGER",
	"CENTRAL STRIKER", "LEFT WINGER", "DEFENSIVE MIDFIELDER", "RIGHT FORWARD",
	"LEFT FORWARD", "INSIDE LEFT"]
const POS_WORD := {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}

# --- palette (read off frame 014) ---
const C_GK_ROW := Color(0.98, 0.97, 0.80)
const C_STATBAND := Color(0.80, 0.90, 0.78)
const C_ROLEBAND := Color(0.44, 0.50, 0.60)
const C_ROLEBAND_HI := Color(0.62, 0.68, 0.78)
const C_ROLEBAND_LO := Color(0.24, 0.28, 0.38)
const C_ROLE_TXT := Color(0.86, 0.90, 0.98)
const C_DKBTN := Color(0.08, 0.13, 0.26)
const C_DKBTN_HI := Color(0.28, 0.40, 0.66)
const C_BTN_LO := Color(0.06, 0.11, 0.22)
const C_BLUE := Color(0.20, 0.34, 0.62)
const C_BLUE_HI := Color(0.42, 0.56, 0.84)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_PITCH := Color(0.20, 0.47, 0.24)

var _club: Dictionary = {}
var _tactics: Tactics = null
var _division := ""
var _season := "1997-98"
var _week := 0
var _by_id: Dictionary = {}
var _rating_view := true   # true = RATING (stars), false = PARAMETERS (numbers); frame default RATING
var _forms: Dictionary = {}   # name -> {gk_slot, slots:[{mk1,mk2}]}

var _f8: Font
var _f10: Font
var _f12: Font
var _campo: Texture2D
var _hits: Array = []      # [{r, kind, value}]
var _picker_open := false  # the PREDEF 10-formation overlay
var _scale := 1.0
var _origin := Vector2.ZERO

# PREDEF overlay geometry (FUN_0056f4c0): 451x250 body centred on 640x480; a 5x2
# thumbnail grid + CANCEL. Thumb k at rel ((k%5)*80+24, (k>4)*100+35).
const PICK_BODY := Rect2(94, 115, 451, 250)
const PICK_CANCEL := Rect2(94 + 170, 115 + 218, 110, 25)


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_campo = load("res://art/screens/campo.png")
	_load_formations()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


## The source-true 10-formation marker table (DAT_00660240 via export_formations.py).
func _load_formations() -> void:
	var f := FileAccess.open("res://data/formations.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for rec in (d as Dictionary).get("formations", []):
			_forms[str(rec.get("name", ""))] = rec


func setup(club: Dictionary, tactics: Tactics, _manager := "", division := "",
		season := "1997-98", week := 0) -> void:
	_club = club
	_tactics = tactics
	_division = division
	_season = season
	_week = week
	_by_id.clear()
	for p in club.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	queue_redraw()


# ---- helpers -------------------------------------------------------------

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


func _hit(r: Rect2, kind: String, value: Variant = null) -> void:
	_hits.append({"r": r, "kind": kind, "value": value})


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	_scale = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "TACTICS", "", str(_club.get("name", "")), _division,
		_season, _week, int(_club.get("id", -1)))

	_draw_table()
	_draw_skill_grid()
	_draw_left_buttons()
	_draw_pitch()
	_draw_right_buttons()

	if _picker_open:
		_hits.clear()   # the overlay swallows all board hits while it is up
		_draw_picker()


func _draw_table() -> void:
	PMChrome.draw_table_panel(self, TABLE)
	PMChrome.draw_col_header(self, Rect2(TABLE.position.x + 2, HDR_Y, TABLE.size.x - 4, 14))
	PMChrome.text(self, _f10, 14, HDR_Y + 1, "N.", PMChrome.C_TBL_HDR_TXT, 11)
	PMChrome.text(self, _f10, 48, HDR_Y + 1, "PLAYER", PMChrome.C_TBL_HDR_TXT, 11)
	for c in COLS:
		PMChrome.text(self, _f10, c[1], HDR_Y + 1, c[0], PMChrome.C_TBL_HDR_TXT, 11, 2)
	PMChrome.text(self, _f10, AV_X, HDR_Y + 1, "AV", PMChrome.C_TBL_HDR_TXT, 11, 2)
	PMChrome.text(self, _f10, ROLE_BAND.position.x, HDR_Y + 1, "ROLE", PMChrome.C_TBL_HDR_TXT, 11, 1, ROLE_BAND.size.x)
	PMChrome.text(self, _f10, POS_BOX.position.x, HDR_Y + 1, "POS", PMChrome.C_TBL_HDR_TXT, 11)

	var xi: Array = _tactics.xi if _tactics != null else []
	var y := XI_Y0
	for i in mini(xi.size(), 11):
		_draw_row(y, i, int(xi[i]))
		y += ROW_H


func _draw_row(y: int, slot: int, pid: int) -> void:
	var p: Variant = _by_id.get(pid)
	if p == null:
		return
	var pl: Dictionary = p
	var is_gk: bool = bool(pl.get("isGK", false))
	var bg: Color = C_GK_ROW if is_gk else (PMChrome.C_ROW_LIGHT if slot % 2 == 0 else PMChrome.C_ROW_DARK)
	draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1), bg, true)
	draw_rect(Rect2(ROW_X, y + ROW_H - 1, ROW_W, 1), PMChrome.C_ROW_SEP, true)
	draw_rect(Rect2(STAT_X0, y, STAT_X1 - STAT_X0, ROW_H - 1), C_STATBAND, true)

	var ty := y + 2
	PMChrome.draw_crest(self, int(_club.get("id", -1)), Rect2(10, y + 1, 13, ROW_H - 3))
	PMChrome.text(self, _f10, 44, ty, str(_shirt(pl, slot)), PMChrome.C_ROW_TXT, 11, 2)
	PMChrome.text(self, _f10, 48, ty, PMChrome.title_case_name(str(pl.get("name", "?"))), PMChrome.C_ROW_TXT, 11, 0, 104.0)

	if _rating_view:
		# RATING: a single 5-star overall rating in the EN-column band (frame 014).
		PMChrome.draw_stars(self, 172, y + 4, _avg_of(pl) / 20.0, 8, 5)
	else:
		# PARAMETERS: the seven numeric attributes.
		var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
		for c in COLS:
			var v: Variant = attrs.get(c[2])
			PMChrome.text(self, _f10, c[1], ty, str(int(v)) if v != null else "-", PMChrome.C_ROW_TXT, 11, 2)

	PMChrome.text(self, _f10, AV_X, ty, str(_avg_of(pl)), PMChrome.C_ROW_TXT, 11, 2)

	# ROLE: camrol pitch-position icon + the full fine-role name on a grey band.
	var band := Rect2(ROLE_BAND.position.x, y + 1, ROLE_BAND.size.x, ROW_H - 3)
	PMChrome.bevel(self, band, C_ROLEBAND, C_ROLEBAND_HI, C_ROLEBAND_LO)
	if not PMChrome.draw_role_icon(self, Rect2(ROLE_ICON_X, y + 1, 14, ROW_H - 3),
			int(pl.get("posFine", 0)), str(pl.get("pos", ""))):
		draw_rect(Rect2(ROLE_ICON_X, y + 3, 12, ROW_H - 6), C_PITCH, true)
	PMChrome.text(self, _f8, band.position.x, y + 3, _role_long(pl), C_ROLE_TXT, 10, 1, band.size.x)

	# POS: the left ◄ arrow (drawn faithfully; read-only) + the broad POS box.
	_draw_pos_arrow(Rect2(ROLE_ARROW_X, y + 4, 10, ROW_H - 8))
	var box := Rect2(POS_BOX.position.x, y + 2, POS_BOX.size.x, ROW_H - 4)
	PMChrome.bevel(self, box, Color.WHITE, Color.WHITE, PMChrome.C_TBL_LO)
	PMChrome.text(self, _f8, box.position.x, y + 3, _pos_word(pl), PMChrome.C_ROW_TXT, 10, 1, box.size.x)


func _draw_pos_arrow(r: Rect2) -> void:
	if PMChrome.draw_icon(self, "tacticas/flecha", r):
		return
	var cy := r.get_center().y
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x, cy), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.end.y)]), Color(0.55, 0.10, 0.10))


func _draw_skill_grid() -> void:
	var labels := [["HANDLING", "PASSING"], ["DRIBBLING", "HEADING"], ["TACKLING", "SHOOTING"]]
	var cw := SKILL_GRID.size.x / 2.0
	var chh := SKILL_GRID.size.y / 3.0
	for r in 3:
		for cc in 2:
			var bx := SKILL_GRID.position.x + cc * cw
			var by := SKILL_GRID.position.y + r * chh
			PMChrome.bevel(self, Rect2(bx + 1, by + 1, cw - 2, chh - 2), C_BLUE, C_BLUE_HI, C_BTN_LO)
			PMChrome.text(self, _f8, bx, by + chh * 0.5 - 5, labels[r][cc], C_PANEL_TXT, 10, 1, cw)


func _draw_left_buttons() -> void:
	_icon_button(PREDEF_BTN, "PREDEF. TACTICS", "tacticas/predef", "predef")
	_icon_button(LOAD_BTN, "LOAD TACTICS", "carga", "load")
	_icon_button(SAVE_BTN, "SAVE TACTICS", "tacticas/grabar", "save")


func _draw_right_buttons() -> void:
	# PARAM. / RATING toggle (active one framed gold).
	_toggle_button(PARAM_BTN, "PARAM.", not _rating_view, "param")
	_toggle_button(RATING_BTN, "RATING", _rating_view, "rating")
	_icon_button(TEAM_BTN, "TEAM TACTICS", "tacticas/equipo", "team")
	_icon_button(RIVAL_BTN, "VIEW RIVAL", "tacticas/verrival", "rival")
	_icon_button(LINEUP_BTN, "LINE-UP", "tacticas/ali", "lineup")
	_plain_button(RETURN_BTN, "RETURN", C_GOLD, "return")


func _icon_button(r: Rect2, label: String, icon: String, kind: String) -> void:
	PMChrome.bevel(self, r, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	var tx := r.position.x + 4.0
	if PMChrome.draw_icon(self, icon, Rect2(r.position.x + 4, r.position.y + (r.size.y - 16) * 0.5, 20, 16)):
		tx = r.position.x + 28.0
	PMChrome.text(self, _f12, tx, r.position.y + (r.size.y - 12) * 0.5, label, C_PANEL_TXT, 12, 0, r.end.x - tx - 4.0)
	_hit(r, kind)


func _toggle_button(r: Rect2, label: String, active: bool, kind: String) -> void:
	PMChrome.bevel(self, r, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	if active:
		draw_rect(r, C_GOLD, false, 2.0)
	PMChrome.text(self, _f12, r.position.x, r.position.y + (r.size.y - 12) * 0.5,
		label, C_GOLD if active else C_PANEL_TXT, 12, 1, r.size.x)
	_hit(r, kind)


func _plain_button(r: Rect2, label: String, col: Color, kind: String) -> void:
	PMChrome.bevel(self, r, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	PMChrome.text(self, _f12, r.position.x, r.position.y + (r.size.y - 12) * 0.5, label, col, 12, 1, r.size.x)
	_hit(r, kind)


# ---- pitch ---------------------------------------------------------------

func _draw_pitch() -> void:
	var form: String = _tactics.formation if _tactics != null else "4-4-2"
	# "TACTICS <formation>" title bar above the pitch.
	PMChrome.bevel(self, PITCH_TITLE, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	PMChrome.text(self, _f12, PITCH_TITLE.position.x, PITCH_TITLE.position.y + 8,
		"TACTICS %s" % form, C_GOLD, 13, 1, PITCH_TITLE.size.x)

	if _campo != null:
		draw_texture_rect(_campo, PITCH, false)
	else:
		draw_rect(PITCH, C_PITCH, true)
	PMChrome.bevel(self, PITCH, Color(0, 0, 0, 0), Color(0.9, 0.95, 0.9, 0.5), Color(0, 0, 0, 0.4))

	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary) or _tactics == null:
		return
	var slots: Array = (rec as Dictionary).get("slots", [])
	var gk_slot := int((rec as Dictionary).get("gk_slot", 10))
	var xi: Array = _tactics.xi
	# XI[0] is the goalkeeper (app convention); it maps to the formation's gk_slot,
	# and XI[1..10] map to the outfield slots in table order (0..9).
	for i in mini(xi.size(), 11):
		var slot_idx := gk_slot if i == 0 else (i - 1)
		if slot_idx < 0 or slot_idx >= slots.size():
			continue
		var s: Dictionary = slots[slot_idx]
		var num := _shirt(_by_id[int(xi[i])], i) if _by_id.has(int(xi[i])) else i + 1
		_draw_token(s.get("mk1", [0, 0]), s.get("mk2", [0, 0]), num)


func _mk(v: Array) -> Vector2:
	return MARK_ORIGIN + Vector2(float(v[0]) * MARK_W / 258.0, float(v[1]) * MARK_H / 154.0)


## One formation token: a green disc at the primary (defensive) marker with the shirt
## number, plus a movement arrow at the secondary (attacking) marker when it differs.
func _draw_token(mk1: Array, mk2: Array, number: int) -> void:
	var c1 := _mk(mk1)
	var c2 := _mk(mk2)
	# movement arrow (secondary), drawn first so the disc reads on top when they overlap.
	if c1.distance_to(c2) > 6.0:
		var dx := c2.x - c1.x
		var dy := c2.y - c1.y
		var icon := "tacticas/mk_arrow"
		if absf(dy) > 4.0:
			icon = ("tacticas/fle_u" if dy < 0 else "tacticas/fle_d") + ("r" if dx >= 0 else "l")
		if not PMChrome.draw_icon(self, icon, Rect2(c2.x - 5, c2.y - 5, 10, 10)):
			draw_circle(c2, 4.0, Color(0.10, 0.30, 0.12))
		PMChrome.text(self, _f8, c2.x - 6, c2.y - 5, str(number), Color(0.05, 0.15, 0.05), 9, 1, 12.0)
	# primary disc.
	if not PMChrome.draw_icon(self, "tacticas/mk_disc", Rect2(c1.x - 5, c1.y - 5, 10, 10)):
		draw_circle(c1, 5.0, Color(0.45, 0.80, 0.35))
	PMChrome.text(self, _f8, c1.x - 6, c1.y - 5, str(number), Color.WHITE, 9, 1, 12.0)


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
		PMChrome.text(self, _f10, cell.position.x, cell.end.y - 14, str(forms[k]),
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
