extends Control
class_name LineupScreen
## PM98 LINE-UP (ALINEACIÓN) screen, rebuilt to match the real game (ma_7): the shared
## management chrome (PMChrome header + blue marble background) over the white squad
## TABLE — N. | PLAYER | EN SP ST AG GU FI MO | AV (+bar) | ROL | POS — in the game's
## own English column codes, with STARTERS / SUBSTITUTES / RESERVES sections and the
## right control column (PARAMETERS / RATING, the TEAM RATING star strip, the attribute
## buttons, the CAMPO mini-pitch with the live XI markers, TRAINING / INJURIES /
## STATISTICS and TACTICS / RETURN).
##
## XI + formation come from the career's Tactics; markers are placed by the engine's own
## mapping (marker = pitch.origin + tac*scale). Native 640x480; scales to fit its parent.

const W := 640
const H := 480

const C_GK_ROW := Color(0.98, 0.97, 0.80)        # pale-yellow goalkeeper row
const C_STATBAND := Color(0.80, 0.90, 0.78)      # pale-green stat-cell band
const C_AVBAR := Color(0.46, 0.74, 0.32)
const C_AVBAR_BG := Color(0.62, 0.64, 0.58)
const C_BTN := Color(0.20, 0.34, 0.62)           # attribute buttons (blue)
const C_BTN_HI := Color(0.42, 0.56, 0.84)
const C_BTN_LO := Color(0.08, 0.16, 0.34)
const C_DKBTN := Color(0.08, 0.13, 0.26)         # dark navy buttons
const C_DKBTN_HI := Color(0.28, 0.40, 0.66)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
# Role tag colours (ROL / POS).
const C_ROLE := {"GK": Color(0.20, 0.52, 0.30), "DEF": Color(0.22, 0.36, 0.66),
	"MID": Color(0.46, 0.30, 0.62), "FOR": Color(0.66, 0.24, 0.22)}

# Table geometry (640x480). {code, x, attr_key}; x is the RIGHT edge for numeric cols,
# LEFT edge for text cols. GU (not QU) per the real header.
const COLS := [
	["EN", 174, "EN"], ["SP", 200, "VE"], ["ST", 226, "RE"], ["AG", 252, "AG"],
	["GU", 278, "CA"], ["FI", 304, "TI"], ["MO", 330, "RM"], ["AV", 356, "_avg"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]
const TABLE := Rect2(6, 50, 470, 426)
const HDR_Y := 66
const ROW_X := 8
const ROW_W := 466
const ROW_H := 16
const STAT_X0 := 158
const STAT_X1 := 344
const AVBAR_X := 360
const ROL_X := 398
const POS_X := 430
const XI_Y0 := 84

# Pitch panel (right column).
const PITCH_POS := Vector2(482, 250)
const CAMPO_W := 150.0
const CAMPO_H := 92.0
const MARK_ORIGIN := Vector2(484, 252)
const MARK_W := 146.0
const MARK_H := 88.0
const TAC_W := 318.0
const TAC_H := 198.0
const KIT_SRC := Rect2(0, 0, 31, 64)

var _campo: Texture2D
var _f12: Font
var _f10: Font
var _f8: Font
var _kits: Dictionary = {}

var _club: Dictionary = {}
var _tactics: Tactics = null
var _division: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _by_id: Dictionary = {}


func _ready() -> void:
	_campo = load("res://art/screens/campo.png")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Feed the manager's club + chosen tactics (+ season/week for the calendar plaque), repaint.
func setup(club: Dictionary, tactics: Tactics, manager: String = "", division: String = "",
		season: String = "1997-98", week: int = 0) -> void:
	_club = club
	_tactics = tactics
	_division = division
	_season = season
	_week = week
	_by_id.clear()
	for p in club.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	queue_redraw()


# ---- formation geometry --------------------------------------------------

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


# ---- kits ----------------------------------------------------------------

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


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "LINE-UP", "", str(_club.get("name", "")), _division,
		_season, _week, int(_club.get("id", -1)))

	PMChrome.draw_table_panel(self, TABLE)
	_draw_col_header()
	_draw_squad()
	_draw_right_panel()


func _draw_col_header() -> void:
	PMChrome.draw_col_header(self, Rect2(TABLE.position.x + 2, HDR_Y, TABLE.size.x - 4, 16))
	_txt(_f10, 14, HDR_Y + 2, "N.", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, 48, HDR_Y + 2, "PLAYER", PMChrome.C_TBL_HDR_TXT, 11)
	for c in COLS:
		_txt(_f10, c[1], HDR_Y + 2, c[0], PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, ROL_X, HDR_Y + 2, "ROL", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, POS_X, HDR_Y + 2, "POS", PMChrome.C_TBL_HDR_TXT, 11)


## XI rows + SUBSTITUTES + RESERVES at the real metrics, in the white table skin.
func _draw_squad() -> void:
	var roles: Array = _tactics.roles() if _tactics != null else []
	var xi: Array = _tactics.xi if _tactics != null else []
	var row := 0
	var y := XI_Y0

	for i in xi.size():
		var rl: String = roles[i] if i < roles.size() else ""
		_row(y, row, int(xi[i]), i + 1, rl)
		y += ROW_H
		row += 1

	# Bench + reserves: squad players not in the XI, by ability.
	var rest: Array = []
	for p in _club.get("players", []):
		var pid := int(p.get("id", -1))
		if pid >= 0 and not xi.has(pid):
			rest.append(p)
	rest.sort_custom(func(a, b): return _avg_of(a) > _avg_of(b))

	_section(y, "SUBSTITUTES"); y += 15
	var bench := rest.slice(0, 5)
	for j in bench.size():
		_row(y, row, int(bench[j].get("id", -1)), 12 + j, _pos_of(bench[j]))
		y += ROW_H
		row += 1

	_section(y, "RESERVES"); y += 15
	var res := rest.slice(5, rest.size())
	var max_rows := int((TABLE.end.y - 4 - y) / ROW_H)
	for j in mini(res.size(), max_rows):
		_row(y, row, int(res[j].get("id", -1)), 17 + j, _pos_of(res[j]))
		y += ROW_H
		row += 1


func _section(y: int, label: String) -> void:
	draw_rect(Rect2(ROW_X, y, ROW_W, 14), PMChrome.C_ROW_DARK, true)
	_centre(_f10, ROW_X, ROW_W, y + 1, label, PMChrome.C_TBL_HDR, 11)


func _row(y: int, idx: int, pid: int, number: int, role: String) -> void:
	var p: Variant = _by_id.get(pid)
	if p == null:
		return
	var pl: Dictionary = p
	var is_gk: bool = pl.get("isGK", false)
	# row background
	var bg: Color = C_GK_ROW if is_gk else (PMChrome.C_ROW_LIGHT if idx % 2 == 0 else PMChrome.C_ROW_DARK)
	draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1), bg, true)
	draw_rect(Rect2(ROW_X, y + ROW_H - 1, ROW_W, 1), PMChrome.C_ROW_SEP, true)
	# pale-green stat band
	draw_rect(Rect2(STAT_X0, y, STAT_X1 - STAT_X0, ROW_H - 1), C_STATBAND, true)

	var ty := y + 2
	PMChrome.draw_crest(self, int(_club.get("id", -1)), Rect2(10, y, 13, ROW_H - 1))
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
	# AV bar just right of the AV value
	var avg := _avg_of(pl)
	draw_rect(Rect2(AVBAR_X, y + 4, 30, 7), C_AVBAR_BG, true)
	draw_rect(Rect2(AVBAR_X, y + 4, 30.0 * clampf(avg / 99.0, 0.0, 1.0), 7), C_AVBAR, true)
	# ROL: the original CAMROL pitch-position icon (faithful), with the colour tag as
	# a fallback when the icon / fine code is unavailable. POS: the broad role text.
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
	var px := 480.0
	var pw := 154.0
	# PARAMETERS / RATING.
	PMChrome.bevel(self, Rect2(px, 50, pw, 18), C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, px, pw, 52, "PARAMETERS", C_GOLD, 13)
	PMChrome.bevel(self, Rect2(px, 70, pw, 18), C_DKBTN, C_DKBTN_HI, C_BTN_LO)
	_centre(_f12, px, pw, 72, "RATING", C_PANEL_TXT, 13)

	# TEAM RATING strip with stars.
	var avg := _team_rating()
	PMChrome.bevel(self, Rect2(px, 92, pw, 30), Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_BTN_LO)
	PMChrome.draw_crest(self, int(_club.get("id", -1)), Rect2(px + 4, 94, 18, 26))
	_txt(_f8, int(px) + 26, 95, "TEAM RATING", C_PANEL_TXT, 10)
	PMChrome.draw_stars(self, px + 26, 106, avg / 20.0, 11, 5)
	_txt(_f12, int(px + pw) - 8, 100, str(avg), Color.WHITE, 14, true)

	# Attribute buttons (2 cols x 3 rows).
	var labels := [["HANDLING", "PASSING"], ["DRIBBLING", "HEADING"], ["TACKLING", "SHOOTING"]]
	for r in 3:
		for cc in 2:
			var bx := px + cc * (pw / 2.0)
			var by := 126 + r * 20
			PMChrome.bevel(self, Rect2(bx + 1, by, pw / 2.0 - 2, 18), C_BTN, C_BTN_HI, C_BTN_LO)
			_centre(_f8, bx, pw / 2.0, by + 3, labels[r][cc], C_PANEL_TXT, 10)

	_draw_pitch()

	# TRAINING / INJURIES / STATISTICS.
	var rows := ["TRAINING", "INJURIES", "STATISTICS"]
	for i in 3:
		var by := 348 + i * 22
		PMChrome.bevel(self, Rect2(px, by, pw, 20), C_DKBTN, C_DKBTN_HI, C_BTN_LO)
		_txt(_f12, int(px + pw) - 8, by + 4, rows[i], C_PANEL_TXT, 12, true)

	# TACTICS / RETURN.
	for i in 2:
		var bx := px + i * (pw / 2.0)
		PMChrome.bevel(self, Rect2(bx + 1, 448, pw / 2.0 - 2, 24), C_DKBTN, C_DKBTN_HI, C_BTN_LO)
		_centre(_f12, bx, pw / 2.0, 453, "TACTICS" if i == 0 else "RETURN",
			C_GOLD if i == 1 else C_PANEL_TXT, 13)


func _centre(f: Font, x: float, w: float, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x + (w - tw) * 0.5, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _team_rating() -> int:
	var xi: Array = _tactics.xi if _tactics != null else []
	if xi.is_empty():
		return 0
	var sum := 0
	var n := 0
	for pid in xi:
		var p: Variant = _by_id.get(int(pid))
		if p != null:
			sum += _avg_of(p)
			n += 1
	return int(round(float(sum) / n)) if n > 0 else 0


## CAMPO mini-pitch with the 11 XI kit markers placed by the engine mapping.
func _draw_pitch() -> void:
	if _campo != null:
		draw_texture_rect(_campo, Rect2(PITCH_POS, Vector2(CAMPO_W, CAMPO_H)), false)
	else:
		draw_rect(Rect2(PITCH_POS, Vector2(CAMPO_W, CAMPO_H)), Color(0.16, 0.43, 0.27), true)
	if _tactics == null:
		return
	var pos := _slot_positions()
	var xi: Array = _tactics.xi
	var club_id := int(_club.get("id", -1))
	for i in mini(xi.size(), pos.size()):
		_draw_marker(club_id, i + 1, _mark_center(pos[i]))


func _draw_marker(club_id: int, number: int, center: Vector2) -> void:
	var tex := _kit(club_id)
	if tex != null:
		var sc: float = min(11.0 / KIT_SRC.size.x, 14.0 / KIT_SRC.size.y)
		var w := KIT_SRC.size.x * sc
		var h := KIT_SRC.size.y * sc
		draw_texture_rect_region(tex, Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h), KIT_SRC)
	else:
		draw_rect(Rect2(center.x - 5, center.y - 6, 10, 12), Color.WHITE, true)
