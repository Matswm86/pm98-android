extends Control
class_name RivalScreen
## PM98 VIEW RIVAL (VERRIVAL) screen -- the OPPONENT-scouting screen, rebuilt from the real
## game (FUN_005733d0; docs/re/rival_screen_re.md). Reached from the MANAGER MENU OPPONENT
## icon (and TACTICS -> VIEW RIVAL). Shows the next opponent's XI, team rating and formation.
##
## THE DEFINING RULE (sourced): the depth of the report scales with your ASSISTANT MANAGER.
## The original gates on `bVar2 = manager.staff_slot[8].ability` -- 0 = no assistant, then
## rising tiers add pitch markers, a second (defence-phase) marker set and per-player movement
## arrows. Those finer tiers need per-player two-phase tactic data PM98 does not decode for CPU
## clubs, so this port keeps the two states the app's data can render faithfully (no invented
## phases/arrow-directions): Staff.assistant_quality(career.staff) == 0 -> the "hire an
## Assistant" message only; >= 1 -> the full rival XI table + team rating + formation dots.
##
## Native 640x480, scales to fit its parent (same transform as LINE-UP). Display screen:
## RETURN dismisses, TACTICS opens the TEAM TACTICS modal; any other tap is a no-op.

signal back_pressed
signal tactics_pressed

const W := 640
const H := 480

# ---- source rects (FUN_005733d0, 640x480) --------------------------------
const R_PARAMETERS := Rect2(492, 85, 134, 21)
const R_RATING := Rect2(492, 109, 134, 21)
const R_CLUBNAME := Rect2(481, 155, 154, 18)
const R_RATINGSTRIP := Rect2(481, 173, 154, 32)
const R_COMPUTER := Rect2(482, 205, 152, 15)
const R_TACTICS := Rect2(508, 395, 112, 25)
const R_RETURN := Rect2(508, 440, 112, 25)
const R_ATTRGRID := Rect2(9, 297, 156, 91)
const R_ASSIST := Rect2(8, 398, 181, 69)
const R_CAMPO := Rect2(196, 300, 278, 167)
# marker layer: child of the campo at rel (10,5), interior 258x154, tac design space 318x198.
const MARK_ORIGIN := Vector2(206, 305)
const MARK_W := 258.0
const MARK_H := 154.0
const TAC_W := 318.0
const TAC_H := 198.0
const KIT_SRC := Rect2(0, 0, 31, 64)

# Rival XI table (shares the LINE-UP metrics/skin; only the XI, no subs/reserves).
const TABLE := Rect2(6, 48, 470, 232)
const HDR_Y := 66
const ROW_X := 8
const ROW_W := 466
const ROW_H := 16
const XI_Y0 := 84
const STAT_X0 := 158
const STAT_X1 := 344
const AVBAR_X := 360
const ROL_X := 398
const POS_X := 430
const COLS := [
	["EN", 174, "EN"], ["SP", 200, "VE"], ["ST", 226, "RE"], ["AG", 252, "AG"],
	["GU", 278, "CA"], ["FI", 304, "TI"], ["MO", 330, "RM"], ["AV", 356, "_avg"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

const HIRE_MSG := "In order to find information about the rival team\n\nyou need to hire an Assistant."

const C_GK_ROW := Color(0.98, 0.97, 0.80)
const C_STATBAND := Color(0.80, 0.90, 0.78)
const C_AVBAR := Color(0.46, 0.74, 0.32)
const C_AVBAR_BG := Color(0.62, 0.64, 0.58)
const C_BTN := Color(0.20, 0.34, 0.62)
const C_BTN_HI := Color(0.42, 0.56, 0.84)
const C_BTN_LO := Color(0.08, 0.16, 0.34)
const C_DKBTN := Color(0.08, 0.13, 0.26)
const C_DKBTN_HI := Color(0.28, 0.40, 0.66)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_ROLE := {"GK": Color(0.20, 0.52, 0.30), "DEF": Color(0.22, 0.36, 0.66),
	"MID": Color(0.46, 0.30, 0.62), "FOR": Color(0.66, 0.24, 0.22)}

var _campo: Texture2D
var _f12: Font
var _f10: Font
var _f8: Font
var _kits: Dictionary = {}

var _rival: Dictionary = {}
var _own: Dictionary = {}
var _tactics: Tactics = null
var _assist_q: int = 0            # Staff.assistant_quality(career.staff), 0..5
var _assist_name: String = ""
var _division: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _by_id: Dictionary = {}
var _press: String = ""


func _ready() -> void:
	_campo = load("res://art/screens/campo.png")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the RIVAL club to scout, the manager's OWN club (for the chrome plaque), the assistant
## quality (0..5) + name that gate the report, and the calendar plaque data. The rival's XI +
## formation are auto-picked (the same selector MatchSim fields CPU sides with).
func setup(rival: Dictionary, own: Dictionary, assist_quality: int, assist_name: String = "",
		division: String = "", season: String = "1997-98", week: int = 0) -> void:
	_rival = rival
	_own = own
	_assist_q = maxi(0, assist_quality)
	_assist_name = assist_name
	_division = division
	_season = season
	_week = week
	_tactics = Tactics.auto_pick(rival) if not rival.is_empty() else null
	_by_id.clear()
	for p in rival.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	queue_redraw()


func has_report() -> bool:
	return _assist_q > 0


# ---- input ---------------------------------------------------------------

const BTN_TACTICS := R_TACTICS
const BTN_RETURN := R_RETURN

func _hit(d: Vector2) -> String:
	if BTN_RETURN.has_point(d):
		return "return"
	if BTN_TACTICS.has_point(d):
		return "tactics"
	return ""


func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


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


# ---- formation geometry (matches LINE-UP) --------------------------------

func _slot_positions() -> Array:
	if _tactics == null:
		return []
	var lines: Array = Tactics.FORMATIONS.get(_tactics.formation, Tactics.FORMATIONS["4-4-2"])
	var cols := {"GK": 20.0, "DEF": 90.0, "MID": 175.0, "FWD": 262.0}
	var out: Array = []
	out.append(Vector2(cols["GK"], TAC_H * 0.5))
	for role in ["DEF", "MID", "FWD"]:
		var n := 0
		match role:
			"DEF": n = int(lines[0])
			"MID": n = int(lines[1])
			"FWD": n = int(lines[2])
		for k in n:
			var y: float = lerpf(TAC_H * 0.16, TAC_H * 0.84, (k + 0.5) / float(n))
			out.append(Vector2(cols[role], y))
	return out


func _mark_center(tac: Vector2) -> Vector2:
	return MARK_ORIGIN + Vector2(tac.x * MARK_W / TAC_W, tac.y * MARK_H / TAC_H)


func _kit(id: int) -> Texture2D:
	if not _kits.has(id):
		var path := "res://art/kits/%d.png" % id
		_kits[id] = load(path) if ResourceLoader.exists(path) else null
	return _kits[id]


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _centre(f: Font, x: float, w: float, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x + (w - tw) * 0.5, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	# Chrome plaque shows the fixture vs-stack: rival club on top, own club below, rival crest.
	PMChrome.draw_header(self, "VIEW RIVAL", str(_rival.get("name", "")),
		str(_own.get("name", "")), _division, _season, _week, int(_rival.get("id", -1)))

	PMChrome.draw_table_panel(self, TABLE)
	if has_report():
		_draw_col_header()
		_draw_xi()
	else:
		_draw_hire_message()

	_draw_right_panel()
	_draw_attr_grid()
	_draw_assistant_panel()
	if has_report():
		_draw_pitch()


func _draw_hire_message() -> void:
	var box := Rect2(TABLE.position.x + 20, TABLE.position.y + 60, TABLE.size.x - 40, 80)
	var y := int(box.position.y)
	for line in HIRE_MSG.split("\n"):
		_centre(_f12, box.position.x, box.size.x, y, line, PMChrome.C_ROW_TXT, 13)
		y += 18


func _draw_col_header() -> void:
	PMChrome.draw_col_header(self, Rect2(TABLE.position.x + 2, HDR_Y, TABLE.size.x - 4, 16))
	_txt(_f10, 14, HDR_Y + 2, "N.", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, 48, HDR_Y + 2, "PLAYER", PMChrome.C_TBL_HDR_TXT, 11)
	for c in COLS:
		_txt(_f10, c[1], HDR_Y + 2, c[0], PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, ROL_X, HDR_Y + 2, "ROL", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, POS_X, HDR_Y + 2, "POS", PMChrome.C_TBL_HDR_TXT, 11)


## The 11 rival XI rows (no SUBSTITUTES / RESERVES -- VIEW RIVAL shows only the XI).
func _draw_xi() -> void:
	if _tactics == null:
		return
	var roles: Array = _tactics.roles()
	var y := XI_Y0
	for i in _tactics.xi.size():
		var rl: String = roles[i] if i < roles.size() else ""
		_row(y, i, int(_tactics.xi[i]), i + 1, rl)
		y += ROW_H


func _row(y: int, idx: int, pid: int, number: int, _role: String) -> void:
	var p: Variant = _by_id.get(pid)
	if p == null:
		return
	var pl: Dictionary = p
	var is_gk: bool = pl.get("isGK", false)
	var bg: Color = C_GK_ROW if is_gk else (PMChrome.C_ROW_LIGHT if idx % 2 == 0 else PMChrome.C_ROW_DARK)
	draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1), bg, true)
	draw_rect(Rect2(ROW_X, y + ROW_H - 1, ROW_W, 1), PMChrome.C_ROW_SEP, true)
	draw_rect(Rect2(STAT_X0, y, STAT_X1 - STAT_X0, ROW_H - 1), C_STATBAND, true)

	var ty := y + 2
	PMChrome.draw_crest(self, int(_rival.get("id", -1)), Rect2(10, y, 13, ROW_H - 1))
	_txt(_f10, 44, ty, str(number), PMChrome.C_ROW_TXT, 11, true)
	_txt(_f10, 48, ty, str(pl.get("name", "?")).substr(0, 13), PMChrome.C_ROW_TXT, 11)

	var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
	for c in COLS:
		var key: String = c[2]
		var x: int = c[1]
		var sv := ""
		if key == "_avg":
			sv = str(_avg_of(pl))
		else:
			var v: Variant = attrs.get(key)
			sv = str(int(v)) if v != null else "-"
		_txt(_f10, x, ty, sv, PMChrome.C_ROW_TXT, 11, true)
	var avg := _avg_of(pl)
	draw_rect(Rect2(AVBAR_X, y + 4, 30, 7), C_AVBAR_BG, true)
	draw_rect(Rect2(AVBAR_X, y + 4, 30.0 * clampf(avg / 99.0, 0.0, 1.0), 7), C_AVBAR, true)
	var pos := _pos_of(pl)
	var rol_cell := Rect2(ROL_X, y + 1, 24, ROW_H - 3)
	if not PMChrome.draw_role_icon(self, rol_cell, int(pl.get("posFine", 0)), str(pl.get("pos", ""))):
		draw_rect(Rect2(ROL_X, y + 2, 24, ROW_H - 5), C_ROLE.get(_role_group(pos), PMChrome.C_TBL_HDR), true)
	_txt(_f8, POS_X, ty, pos, PMChrome.C_ROW_TXT, 10)


func _role_group(pos: String) -> String:
	if pos == "GK":
		return "GK"
	if pos in ["DEF", "RB", "LB", "CB"]:
		return "DEF"
	if pos in ["FOR", "ST", "CF"]:
		return "FOR"
	return "MID"


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


func _pos_of(p: Dictionary) -> String:
	return "GK" if p.get("isGK") else "OUT"


# ---- right control column ------------------------------------------------

func _draw_right_panel() -> void:
	# PARAMETERS / RATING (source rects).
	PMChrome.bevel(self, R_PARAMETERS, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, R_PARAMETERS.position.x, R_PARAMETERS.size.x, int(R_PARAMETERS.position.y) + 3,
		"PARAMETERS", C_GOLD, 13)
	PMChrome.bevel(self, R_RATING, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, R_RATING.position.x, R_RATING.size.x, int(R_RATING.position.y) + 3,
		"RATING", C_PANEL_TXT, 13)

	# Rival club-name box.
	PMChrome.bevel(self, R_CLUBNAME, Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, R_CLUBNAME.position.x, R_CLUBNAME.size.x, int(R_CLUBNAME.position.y) + 2,
		str(_rival.get("name", "")), C_PANEL_TXT, 12)

	# Crest + TEAM RATING stars + rating number.
	PMChrome.bevel(self, R_RATINGSTRIP, Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_BTN_LO)
	PMChrome.draw_crest(self, int(_rival.get("id", -1)),
		Rect2(R_RATINGSTRIP.position.x + 4, R_RATINGSTRIP.position.y + 3, 18, 26))
	var avg := _team_rating()
	_txt(_f8, int(R_RATINGSTRIP.position.x) + 26, int(R_RATINGSTRIP.position.y) + 2,
		"TEAM RATING", C_PANEL_TXT, 10)
	if has_report():
		PMChrome.draw_stars(self, R_RATINGSTRIP.position.x + 26, R_RATINGSTRIP.position.y + 13,
			avg / 20.0, 11, 5)
		_txt(_f12, int(R_RATINGSTRIP.end.x) - 8, int(R_RATINGSTRIP.position.y) + 8,
			str(avg), Color.WHITE, 14, true)

	# COMPUTER / rival-manager box.
	PMChrome.bevel(self, R_COMPUTER, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	var mgr := str(_rival.get("manager", "")).strip_edges()
	_centre(_f10, R_COMPUTER.position.x, R_COMPUTER.size.x, int(R_COMPUTER.position.y) + 1,
		mgr if mgr != "" else "COMPUTER", C_PANEL_TXT, 11)

	# TACTICS / RETURN.
	PMChrome.bevel(self, R_TACTICS, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, R_TACTICS.position.x, R_TACTICS.size.x, int(R_TACTICS.position.y) + 5,
		"TACTICS", C_PANEL_TXT, 13)
	PMChrome.bevel(self, R_RETURN, C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, R_RETURN.position.x, R_RETURN.size.x, int(R_RETURN.position.y) + 5,
		"RETURN", C_GOLD, 13)


func _team_rating() -> int:
	if _tactics == null:
		return 0
	var sum := 0
	var n := 0
	for pid in _tactics.xi:
		var p: Variant = _by_id.get(int(pid))
		if p != null:
			sum += _avg_of(p)
			n += 1
	return int(round(float(sum) / n)) if n > 0 else 0


## The team-style attribute cells (HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/SHOOTING).
## Labels only, faithful to the original's cells (the per-team style numbers are data-driven
## in PM98 and not decoded for CPU clubs -- shown as labelled cells, never invented values).
func _draw_attr_grid() -> void:
	var labels := [["HANDLING", "PASSING"], ["DRIBBLING", "HEADING"], ["TACKLING", "SHOOTING"]]
	var cw := R_ATTRGRID.size.x / 2.0
	var ch := R_ATTRGRID.size.y / 3.0
	for r in 3:
		for cc in 2:
			var bx := R_ATTRGRID.position.x + cc * cw
			var by := R_ATTRGRID.position.y + r * ch
			PMChrome.bevel(self, Rect2(bx + 1, by + 1, cw - 2, ch - 2), C_BTN, C_BTN_HI, C_BTN_LO)
			_centre(_f8, bx, cw, int(by + ch / 2.0) - 5, labels[r][cc], C_PANEL_TXT, 10)


## The ASSISTANT panel (bottom-left): the hired assistant's name + quality stars, or an empty
## title when none is hired (in which case the report itself is the hire-Assistant message).
func _draw_assistant_panel() -> void:
	PMChrome.bevel(self, R_ASSIST, Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_BTN_LO)
	_txt(_f10, int(R_ASSIST.position.x) + 6, int(R_ASSIST.position.y) + 4, "ASSISTANT",
		C_GOLD, 11)
	if _assist_q > 0:
		_txt(_f10, int(R_ASSIST.position.x) + 6, int(R_ASSIST.position.y) + 24,
			_assist_name if _assist_name != "" else "Assistant", C_PANEL_TXT, 11)
		PMChrome.draw_stars(self, R_ASSIST.position.x + 6, R_ASSIST.position.y + 44,
			float(_assist_q), 11, 5)


## CAMPO pitch with the rival formation kit markers (the reveal core). The original overlays a
## second defence-phase marker set + per-player movement arrows at higher assistant tiers; that
## needs two-phase per-player tactic data PM98 does not decode for CPU clubs, so this draws the
## single nominal formation the app models (documented gap in rival_screen_re.md, not faked).
func _draw_pitch() -> void:
	if _campo != null:
		draw_texture_rect(_campo, R_CAMPO, false)
	else:
		draw_rect(R_CAMPO, Color(0.16, 0.43, 0.27), true)
	if _tactics == null:
		return
	var pos := _slot_positions()
	var rid := int(_rival.get("id", -1))
	for i in mini(_tactics.xi.size(), pos.size()):
		_draw_marker(rid, i + 1, _mark_center(pos[i]))


func _draw_marker(club_id: int, number: int, center: Vector2) -> void:
	var tex := _kit(club_id)
	if tex != null:
		var sc: float = min(11.0 / KIT_SRC.size.x, 14.0 / KIT_SRC.size.y)
		var w := KIT_SRC.size.x * sc
		var h := KIT_SRC.size.y * sc
		draw_texture_rect_region(tex, Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h), KIT_SRC)
	else:
		draw_rect(Rect2(center.x - 5, center.y - 6, 10, 12), Color.WHITE, true)
	# The per-dot number (sourced: sprintf("%u", marker) on the marker layer).
	_centre(_f8, center.x - 8, 16, int(center.y) - 5, str(number), C_GOLD, 10)
