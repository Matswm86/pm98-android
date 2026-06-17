extends Control
class_name SquadScreen
## PM98 SQUAD MANAGEMENT (PLANTILLA) screen, rebuilt to match the real game's house style
## (the white table proven on LINE-UP / TRAINING ma_7/ma_8): the shared PMChrome plaque
## header + blue marble background over a white squad table — N. | PLAYER | AGE | EN SP ST
## AG GU FI MO | AV (+bar) | POS — grouped into the original's own KEEPERS / DEFENDERS /
## MIDFIELDERS / FORWARDS sections (the demarcación byte decoded out of EQUIPOS.PKF),
## sorted by ability. Right: the SQUAD count, the club kit and the YOUTH TEAM / RETURN
## buttons at their reversed positions.
##
## Driven live by the Career roster. Native 640x480; scales to fit its parent.
##
## INTERACTIVE: the YOUTH TEAM button opens the youth screen (emits `youth_pressed`) when
## youth is enabled (the managed club); the RETURN button or a tap on empty space emits
## `back_pressed` (the display-screen tap-to-dismiss).

signal youth_pressed
signal back_pressed

const W := 640
const H := 480

const C_STATBAND := Color(0.80, 0.90, 0.78)      # pale-green stat-cell band
const C_AVBAR := Color(0.46, 0.74, 0.32)
const C_AVBAR_BG := Color(0.62, 0.64, 0.58)
const C_GK_ROW := Color(0.98, 0.97, 0.80)
const C_BTN := Color(0.18, 0.44, 0.26)           # green YOUTH button
const C_BTN_HI := Color(0.34, 0.62, 0.40)
const C_DKBTN := Color(0.10, 0.16, 0.32)
const C_DKBTN_HI := Color(0.34, 0.46, 0.72)
const C_DKBTN_LO := Color(0.04, 0.08, 0.18)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_ROLE := {"GK": Color(0.20, 0.52, 0.30), "DF": Color(0.22, 0.36, 0.66),
	"MF": Color(0.46, 0.30, 0.62), "FW": Color(0.66, 0.24, 0.22), "OUT": Color(0.40, 0.42, 0.48)}

# Player-grid columns laid into the white table. {code, x, attr_key}; x is the RIGHT edge
# for numeric columns, LEFT edge for text columns. GU (not QU) per the real header.
const COLS := [
	["AGE", 176, "_age"],
	["EN", 200, "EN"], ["SP", 224, "VE"], ["ST", 248, "RE"], ["AG", 272, "AG"],
	["GU", 296, "CA"], ["FI", 320, "TI"], ["MO", 344, "RM"], ["AV", 372, "_avg"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

const TABLE := Rect2(6, 50, 510, 426)
const HDR_Y := 66
const ROW_X := 8
const ROW_W := 506
const ROW0_Y := 84
const ROW_H := 16
const NAME_X := 48
const STAT_X0 := 184
const STAT_X1 := 356
const AVBAR_X := 378
const POS_X := 414
const KIT_SRC := Rect2(0, 0, 31, 64)
const KIT_BOX := Rect2(534, 150, 100, 130)
const YOUTH_BTN := Rect2(522, 360, 112, 25)
const RETURN_BTN := Rect2(522, 440, 112, 25)

var _f12: Font
var _f10: Font
var _f8: Font

var _club: Dictionary = {}
var _manager: String = ""
var _cash: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _youth_enabled := false
var _press := ""
var _kit_tex: Texture2D


func _ready() -> void:
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, manager: String = "", cash: String = "", youth_enabled := false,
		season: String = "1997-98", week: int = 0) -> void:
	_club = club
	_manager = manager
	_cash = cash
	_youth_enabled = youth_enabled
	_season = season
	_week = week
	var cid := int(club.get("id", -1))
	var path := "res://art/kits/%d.png" % cid
	_kit_tex = load(path) if cid >= 0 and ResourceLoader.exists(path) else null
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
	if _youth_enabled and YOUTH_BTN.has_point(d):
		return "youth"
	if RETURN_BTN.has_point(d):
		return "return"
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
		if a != "" and a == was:
			if a == "youth":
				youth_pressed.emit()
			else:
				back_pressed.emit()
		elif was == "":
			back_pressed.emit()


# ---- ordering ------------------------------------------------------------

func _sections() -> Array:
	var bucket := {"GK": [], "DF": [], "MF": [], "FW": [], "OUT": []}
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		bucket[_pos_of(p)].append(p)
	var by_avg := func(a, b): return _avg_of(a) > _avg_of(b)
	var out: Array = []
	for key in ["GK", "DF", "MF", "FW", "OUT"]:
		if bucket[key].is_empty():
			continue
		bucket[key].sort_custom(by_avg)
		out.append({"key": key, "section": SECTION_LABELS[key], "players": bucket[key]})
	return out


const SECTION_LABELS := {
	"GK": "KEEPERS", "DF": "DEFENDERS", "MF": "MIDFIELDERS",
	"FW": "FORWARDS", "OUT": "OUTFIELD",
}

func _pos_of(p: Dictionary) -> String:
	var pos := str(p.get("pos", ""))
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if p.get("isGK") else "OUT"


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
	PMChrome.draw_header(self, "SQUAD", _manager, str(_club.get("name", "")),
		str(_club.get("leagueName", "")), _season, _week, int(_club.get("id", -1)))

	PMChrome.draw_table_panel(self, TABLE)
	_draw_col_header()
	_draw_list()
	_draw_side()


func _draw_col_header() -> void:
	PMChrome.draw_col_header(self, Rect2(TABLE.position.x + 2, HDR_Y, TABLE.size.x - 4, 16))
	_txt(_f10, 14, HDR_Y + 2, "N.", PMChrome.C_TBL_HDR_TXT, 11)
	_txt(_f10, NAME_X, HDR_Y + 2, "PLAYER", PMChrome.C_TBL_HDR_TXT, 11)
	for c in COLS:
		_txt(_f10, c[1], HDR_Y + 2, c[0], PMChrome.C_TBL_HDR_TXT, 11, true)
	_txt(_f10, POS_X, HDR_Y + 2, "POS", PMChrome.C_TBL_HDR_TXT, 11)


func _draw_list() -> void:
	var secs := _sections()
	var n_players := 0
	for sec in secs:
		n_players += (sec["players"] as Array).size()
	var n_rows := n_players + secs.size()
	var avail := int(TABLE.end.y - 4) - ROW0_Y
	var row_h: int = ROW_H if n_rows == 0 else clampi(avail / n_rows, 11, ROW_H)

	var y := ROW0_Y
	var row := 0
	var number := 1
	for sec in secs:
		_section(y, str(sec["section"]), row_h)
		y += row_h
		for p in sec["players"]:
			if y + row_h > int(TABLE.end.y - 4):
				return
			_row(y, row, p, number, str(sec["key"]), row_h)
			y += row_h
			row += 1
			number += 1


func _section(y: int, label: String, row_h: int) -> void:
	draw_rect(Rect2(ROW_X, y, ROW_W, row_h - 1), PMChrome.C_ROW_DARK, true)
	_txt(_f10, NAME_X, y + maxi(1, (row_h - 12) / 2), label, PMChrome.C_TBL_HDR, 11)


func _row(y: int, idx: int, p: Dictionary, number: int, key: String, row_h: int) -> void:
	var is_gk := key == "GK"
	var bg: Color = C_GK_ROW if is_gk else (PMChrome.C_ROW_LIGHT if idx % 2 == 0 else PMChrome.C_ROW_DARK)
	draw_rect(Rect2(ROW_X, y, ROW_W, row_h - 1), bg, true)
	draw_rect(Rect2(ROW_X, y + row_h - 1, ROW_W, 1), PMChrome.C_ROW_SEP, true)
	draw_rect(Rect2(STAT_X0, y, STAT_X1 - STAT_X0, row_h - 1), C_STATBAND, true)

	var ty: int = y + maxi(1, (row_h - 12) / 2)
	PMChrome.draw_crest(self, int(_club.get("id", -1)), Rect2(10, y, 13, row_h - 1))
	_txt(_f10, 40, ty, str(number), PMChrome.C_ROW_TXT, 11, true)
	_txt(_f10, NAME_X, ty, str(p.get("name", "?")).substr(0, 13), PMChrome.C_ROW_TXT, 11)

	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	for c in COLS:
		var key2: String = c[2]
		var x: int = c[1]
		var sv := ""
		if key2 == "_age":
			sv = str(int(p.get("age", 0)))
		elif key2 == "_avg":
			sv = str(_avg_of(p))
		else:
			var v: Variant = attrs.get(key2)
			sv = str(int(v)) if v != null else "-"
		_txt(_f10, x, ty, sv, PMChrome.C_ROW_TXT, 11, true)

	var avg := _avg_of(p)
	draw_rect(Rect2(AVBAR_X, y + maxi(2, row_h / 2 - 3), 28, 6), C_AVBAR_BG, true)
	draw_rect(Rect2(AVBAR_X, y + maxi(2, row_h / 2 - 3), 28.0 * clampf(avg / 99.0, 0.0, 1.0), 6), C_AVBAR, true)

	# POS: a coloured role tag, or the injury/suspension status when out.
	var st := Availability.status(p)
	if st["state"] == "FIT":
		var rcol: Color = C_ROLE.get(key, PMChrome.C_TBL_HDR)
		draw_rect(Rect2(POS_X, y + 2, 22, row_h - 5), rcol, true)
		_txt(_f8, POS_X + 26, ty, key, PMChrome.C_ROW_TXT, 10)
	else:
		_txt(_f8, POS_X, ty, "%s %dw" % [st["state"], int(st["weeks"])], st["colour"], 10)


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


## Right column: squad count, the club kit, the YOUTH TEAM + RETURN buttons.
func _draw_side() -> void:
	var px := 522.0
	var pw := 112.0
	var n := 0
	for p in _club.get("players", []):
		if int(p.get("id", -1)) >= 0:
			n += 1
	PMChrome.bevel(self, Rect2(px, 52, pw, 44), Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(px) + 6, 56, "SQUAD", C_PANEL_TXT, 11)
	_txt(_f12, int(px + pw) - 8, 74, "%d players" % n, Color.WHITE, 13, true)

	if _kit_tex != null:
		var sc: float = min(KIT_BOX.size.x / KIT_SRC.size.x, KIT_BOX.size.y / KIT_SRC.size.y)
		var kw := KIT_SRC.size.x * sc
		var kh := KIT_SRC.size.y * sc
		draw_texture_rect_region(_kit_tex,
			Rect2(KIT_BOX.position.x + (KIT_BOX.size.x - kw) * 0.5,
				KIT_BOX.position.y + (KIT_BOX.size.y - kh) * 0.5, kw, kh), KIT_SRC)

	var yb := YOUTH_BTN
	var ybase := (C_BTN_HI if _press == "youth" else C_BTN) if _youth_enabled else C_DKBTN
	PMChrome.bevel(self, yb, ybase, C_BTN_HI if _youth_enabled else C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(yb.position.x) + 10, int(yb.position.y) + 7, "YOUTH TEAM",
		Color(0.92, 1.0, 0.94) if _youth_enabled else PMChrome.C_STAR_OFF, 11)

	var rb := RETURN_BTN
	PMChrome.bevel(self, rb, C_DKBTN_HI if _press == "return" else C_DKBTN, C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(rb.position.x) + 30, int(rb.position.y) + 7, "RETURN", C_GOLD, 12)
