extends Control
class_name LineupScreen
## PM98 LINE-UP (ALINEACIÓN) screen rebuilt from the ORIGINAL game art at the
## EXACT coordinates reversed out of MANAGER.EXE (FUN_004fc321 + FUN_004fe860).
## See docs/re/lineup_screen_re.md for the full reverse-engineering write-up.
##
## Left: the squad list with the game's own English column codes
##   N. PLAYER  EN SP ST AG QU FI MO AV  ROL POS
## at their reversed pixel x's; the starting XI rows (x21,w411,h16 from y17), then
## the SUBSTITUTES and RESERVES sections. Right: the real CAMPO mini-pitch with the
## 11 kit markers placed by the engine's own mapping
##   marker = pitch.origin + (tac_x*148/318, tac_y*88/198)
## driven live by the career's Tactics XI + formation and the real roster.
##
## Native canvas 640x480 (the original screen); scales to fit its parent.

const W := 640
const H := 480

# Palette-accurate chrome, matched to the league-table screen.
const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_SECTION := Color(0.50, 0.50, 0.50)
const C_GK := Color(0.16, 0.43, 0.27)
const C_NAME := Color(1.0, 1.0, 1.0)

# Reversed column left-x (MANAGER.EXE FUN_004fe860). Header row at y=5.
# {code, x_left, attr_key}. The attr_key is the DISPLAY mapping decoded attrs ->
# the game's English column codes: SP=VE(speed) ST=RE(stamina) AG=AG(agility)
# QU=CA(quality) are exact; EN/FI/MO are best-effort (the English attr-label table
# in the EXE is not reversed yet); AV is the computed mean; "" = derived/non-attr.
const COLS := [
	["N.", 25, "_num"], ["PLAYER", 63, "_name"],
	["EN", 166, "EN"], ["SP", 191, "VE"], ["ST", 216, "RE"], ["AG", 240, "AG"],
	["QU", 266, "CA"], ["FI", 293, "TI"], ["MO", 317, "RM"], ["AV", 342, "_avg"],
	["ROL", 364, "_rol"], ["POS", 394, "_pos"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

const ROW_X := 21
const ROW_W := 411
const ROW_H := 16
const XI_Y0 := 17          # first XI row top (i=0x15 -> y17, step 16)
const SUBS_HDR_Y := 204    # SUBSTITUTES header (FUN_004fe860)
const SUBS_Y0 := 220       # first substitute row (i=0xdc)
const MAX_SUBS := 5        # bench size shown before the RESERVES block

# Pitch panel (476,155,156,187); the CAMPO mini-pitch sits in its lower area.
const PITCH_PANEL := Rect2(476, 155, 156, 187)
const CAMPO_POS := Vector2(480, 250)   # 152x92 campo top-left
const MARK_ORIGIN := Vector2(482, 252) # interior top-left (2px campo border)
const MARK_W := 148.0                  # 0x94: tac_x * 148/318
const MARK_H := 88.0                   # 0x58: tac_y * 88/198
const TAC_W := 318.0                   # 0x13e design space
const TAC_H := 198.0                   # 0xc6

# Home-kit crop (left 31px of the 48x64 MINIESC kit), as the league table.
const KIT_SRC := Rect2(0, 0, 31, 64)

var _bg: Texture2D
var _bar: Texture2D
var _campo: Texture2D
var _f24: Font
var _f12: Font
var _f10: Font
var _f8: Font
var _kits: Dictionary = {}

var _club: Dictionary = {}
var _tactics: Tactics = null
var _manager: String = ""
var _division: String = ""
var _by_id: Dictionary = {}


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_campo = load("res://art/screens/campo.png")
	_f24 = load("res://art/fonts/proman24.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Feed the screen the manager's club + chosen tactics, then repaint.
func setup(club: Dictionary, tactics: Tactics, manager: String = "", division: String = "") -> void:
	_club = club
	_tactics = tactics
	_manager = manager
	_division = division
	_by_id.clear()
	for p in club.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	queue_redraw()


# ---- formation geometry --------------------------------------------------

## Tactical (x,y) in the 318x198 design space for each XI slot of a formation.
## Attacking left->right (GK by the left penalty box, forwards on the right),
## matching the CAMPO mini-pitch (box on the left). Lines spread evenly across y.
func _slot_positions() -> Array:
	if _tactics == null:
		return []
	var lines: Array = Tactics.FORMATIONS.get(_tactics.formation, Tactics.FORMATIONS["4-4-2"])
	var cols := {"GK": 20.0, "DEF": 90.0, "MID": 175.0, "FWD": 262.0}
	var out: Array = []
	out.append(Vector2(cols["GK"], TAC_H * 0.5))   # GK centred
	for role in ["DEF", "MID", "FWD"]:
		var n := 0
		match role:
			"DEF": n = int(lines[0])
			"MID": n = int(lines[1])
			"FWD": n = int(lines[2])
		for k in n:
			var y := TAC_H * (k + 0.5) / float(n)
			# pull the spread in from the touchlines a touch
			y = lerp(TAC_H * 0.16, TAC_H * 0.84, (k + 0.5) / float(n))
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


func _txt_c(f: Font, cx: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(x: int, y: int, w: int, h: int, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(Rect2(x, y, w, h), base, true)
	draw_rect(Rect2(x, y, w, 1), hi, true)
	draw_rect(Rect2(x, y, 1, h), hi, true)
	draw_rect(Rect2(x, y + h - 1, w, 1), lo, true)
	draw_rect(Rect2(x + w - 1, y, 1, h), lo, true)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt_c(_f24, 176, 14, "LINE-UP", C_TITLE, 26)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, str(_club.get("name", "")).substr(0, 18), C_TEXT, 13, true)
	_txt(_f12, 628, 26, _division, C_DIM, 13, true)

	_draw_columns()
	_draw_squad()
	_draw_pitch()


func _draw_columns() -> void:
	for c in COLS:
		var code: String = c[0]
		var x: int = c[1]
		if code == "PLAYER" or code == "N.":
			_txt(_f8, x, 56, code, C_HEAD, 11)
		else:
			_txt(_f8, x, 56, code, C_HEAD, 11)


## XI rows (from tactics.xi) + a SUBSTITUTES bench + RESERVES, at the reversed metrics.
func _draw_squad() -> void:
	var roles: Array = _tactics.roles() if _tactics != null else []
	var xi: Array = _tactics.xi if _tactics != null else []

	# Starting XI.
	for i in xi.size():
		var y := XI_Y0 + 14 + i * ROW_H
		_row(y, i % 2 == 0)
		_row_player(int(xi[i]), i + 1, roles[i] if i < roles.size() else "", y)

	# Bench + reserves: squad players not in the XI, by ability.
	var rest: Array = []
	for p in _club.get("players", []):
		var pid := int(p.get("id", -1))
		if pid >= 0 and not xi.has(pid):
			rest.append(p)
	rest.sort_custom(func(a, b): return _avg_of(a) > _avg_of(b))

	_txt(_f8, ROW_X, SUBS_HDR_Y, "SUBSTITUTES", C_SECTION, 11)
	var bench := rest.slice(0, MAX_SUBS)
	for j in bench.size():
		var y := SUBS_Y0 + 14 + j * ROW_H
		_row(y, j % 2 == 0)
		_row_player(int(bench[j].get("id", -1)), 12 + j, _pos_of(bench[j]), y)

	var res_hdr_y := SUBS_Y0 + 14 + bench.size() * ROW_H + 6
	_txt(_f8, ROW_X, res_hdr_y, "RESERVES", C_SECTION, 11)
	var res := rest.slice(MAX_SUBS, rest.size())
	var ry0 := res_hdr_y + 16
	var max_rows := int((H - 10 - ry0) / ROW_H)
	for j in mini(res.size(), max_rows):
		var y := ry0 + j * ROW_H
		_row(y, j % 2 == 0)
		_row_player(int(res[j].get("id", -1)), MAX_SUBS + 12 + j, _pos_of(res[j]), y)


func _row(y: int, alt: bool) -> void:
	draw_rect(Rect2(ROW_X, y, ROW_W, ROW_H - 1), C_ROW_A if alt else C_ROW_B, true)


func _row_player(pid: int, number: int, role: String, y: int) -> void:
	var p: Variant = _by_id.get(pid)
	if p == null:
		return
	var pl: Dictionary = p
	var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
	var ty := y + 2
	for c in COLS:
		var code: String = c[0]
		var x: int = c[1]
		var key: String = c[2]
		match key:
			"_num":
				_txt(_f8, x + 18, ty, str(number), C_TEXT, 11, true)
			"_name":
				_txt(_f8, x, ty, str(pl.get("name", "?")).substr(0, 14), C_NAME, 11)
			"_avg":
				_txt(_f8, x + 18, ty, str(_avg_of(pl)), C_TEXT, 11, true)
			"_rol":
				_txt(_f8, x, ty, role, C_DIM, 11)
			"_pos":
				_txt(_f8, x, ty, _pos_of(pl), C_DIM, 11)
			_:
				var v: Variant = attrs.get(key)
				var sv := str(int(v)) if v != null else "-"
				_txt(_f8, x + 18, ty, sv, C_TEXT, 11, true)


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


## CAMPO mini-pitch (right) with the 11 XI kit markers placed by the engine mapping.
func _draw_pitch() -> void:
	# Panel header strip: club + formation, above the pitch.
	_cell(int(PITCH_PANEL.position.x), 119, 156, 22, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt_c(_f10, int(PITCH_PANEL.position.x) + 78, 122,
		_tactics.formation if _tactics != null else "", C_TITLE, 11)

	if _campo != null:
		draw_texture_rect(_campo, Rect2(CAMPO_POS, _campo.get_size()), false)
	else:
		_cell(int(CAMPO_POS.x), int(CAMPO_POS.y), 152, 92, C_GK, C_CELL_HI, C_CELL_LO)

	if _tactics == null:
		return
	var pos := _slot_positions()
	var xi: Array = _tactics.xi
	var club_id := int(_club.get("id", -1))
	for i in mini(xi.size(), pos.size()):
		var c := _mark_center(pos[i])
		_draw_marker(club_id, i + 1, c)


## A formation marker: the home-kit sprite (as the engine blits it) + the shirt
## number. No surname here -- the original draws only the kit on the pitch; names
## live in the squad list. Kept small (the engine's markers are 10x10 on a 148x88 pitch).
func _draw_marker(club_id: int, number: int, center: Vector2) -> void:
	var box_w := 11.0
	var box_h := 14.0
	var tex := _kit(club_id)
	if tex != null:
		var sc: float = min(box_w / KIT_SRC.size.x, box_h / KIT_SRC.size.y)
		var w := KIT_SRC.size.x * sc
		var h := KIT_SRC.size.y * sc
		draw_texture_rect_region(tex, Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h), KIT_SRC)
	else:
		draw_rect(Rect2(center.x - 5, center.y - 6, 10, 12), C_TITLE, true)
	_txt_c(_f8, int(center.x), int(center.y + box_h * 0.5 - 1), str(number), C_NAME, 11)
