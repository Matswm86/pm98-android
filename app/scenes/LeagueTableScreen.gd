extends Control
class_name LeagueTableScreen
## PM98 LEAGUE TABLES screen, rebuilt to match the real game (ma_10 /
## hires_league_table.jpg): the shared management chrome (PMChrome) — blue marble
## background, the three top plaques (manager+club / calendar / league+week) and a
## blue title bar — over a white-bordered table panel. Inside the panel: a "PREMIER
## LEAGUE" + Date-stepper strip, a cream column-header row, the dark-blue alternating
## standings rows with their crest + tan stat cells + brown POINTS cell, and the
## EURO CUP / UEFA / RELEGATION zone tags hung on the panel's left edge. Right: the
## LEADER card, the division tabs, GOAL SCORERS and RETURN.
##
## Driven by a live standings table (Career or SeasonSim), so what you see is the real
## engine result in the real game's skin. Native 640x480; scales to fit its parent.
##
## Interactive: RETURN dismisses, and a tap on a standings row raises that club's squad.
## (Was a display-only overlay that dismissed to the hub on ANY tap — the "nothing inside
## works, pressing anything goes back" bug.) The division tabs are drawn as the current-
## division indicator; cross-division switching needs the multi-division table model the
## Career layer doesn't yet keep, so tapping another tab is a no-op for now (it does NOT
## invent a table) — flagged for the season-loop pass.

signal back_pressed              # RETURN -> dismiss
signal club_selected(id: int)    # a standings row tap -> open that club's squad

const W := 640
const H := 480

# Table panel + rows.
const C_PANEL := Color(0.90, 0.91, 0.86)         # cream table panel
const C_PANEL_HI := Color(1.0, 1.0, 0.98)
const C_PANEL_LO := Color(0.46, 0.48, 0.50)
const C_PANEL_HDR := Color(0.74, 0.78, 0.84)     # column-header strip (light blue-grey)
const C_HDR_TXT := Color(0.14, 0.24, 0.46)
const C_SUBTITLE := Color(0.20, 0.32, 0.60)
const C_ROW_A := Color(0.17, 0.27, 0.50)
const C_ROW_B := Color(0.13, 0.21, 0.42)
const C_NAME := Color(0.96, 0.98, 1.0)
const C_CELL := Color(0.52, 0.45, 0.30)          # tan stat cell
const C_CELL_HI := Color(0.66, 0.58, 0.40)
const C_CELL_LO := Color(0.30, 0.25, 0.15)
const C_CELL_TXT := Color(0.98, 0.96, 0.88)
const C_PTS := Color(0.50, 0.20, 0.14)           # brown points cell
const C_PTS_HI := Color(0.70, 0.32, 0.22)
const C_PTS_TXT := Color(1.0, 0.92, 0.84)
const C_POS_EURO := Color(1.0, 0.88, 0.30)       # yellow position number in a euro slot
# Date stepper + zone-tag palette.
const C_STEP_BG := Color(0.10, 0.16, 0.32)
const C_STEP_HI := Color(0.34, 0.46, 0.72)
const C_DATE_LBL := Color(0.96, 0.78, 0.20)
const C_EUROTAG := Color(0.84, 0.74, 0.16)
const C_UEFATAG := Color(0.80, 0.74, 0.26)
const C_PROMOTAG := Color(0.22, 0.50, 0.26)
const C_RELEGTAG := Color(0.74, 0.46, 0.20)
const C_TAG_TXT := Color(0.12, 0.12, 0.10)
# Right-side panel.
const C_BTN := Color(0.10, 0.16, 0.32)
const C_BTN_HI := Color(0.34, 0.46, 0.72)
const C_BTN_LO := Color(0.04, 0.08, 0.18)
const C_SEL := Color(0.50, 0.20, 0.14)
const C_GOLD := Color(1.0, 0.86, 0.22)

const KIT_SRC := Rect2(0, 0, 31, 64)

# Panel + column geometry (640x480 design space).
const PANEL := Rect2(6, 50, 532, 426)
const HDR_Y := 92
const ROW_Y0 := 110
const ROW_H := 17
const C_POS_R := 96          # POS number right edge
const C_CREST_X := 100
const C_NAME_X := 120
const STAT_XS := [322, 350, 378, 406, 440, 474]   # P W D L GF GA right edges
const STAT_W := 22
const PTS_X := 510

var _f24: Font
var _f18: Font
var _f12: Font
var _f10: Font
var _f8: Font
var _kits: Dictionary = {}

var _rows: Array = []
var _title_left: String = ""
var _season: String = "1997-98"
var _week_label: String = ""
var _tier: int = 1
var _my_id: int = -1


func _ready() -> void:
	_f24 = load("res://art/fonts/proman24.fnt")
	_f18 = load("res://art/fonts/proman18.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


# ---- input ---------------------------------------------------------------
# RETURN dismisses; a tap on a standings row raises that club. The drawn RETURN rect is
# the one _leader_panel paints (px=544, pw=90).
const RETURN_BTN := Rect2(544, 446, 90, 26)

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		return
	var d := _to_design(e.position)
	if RETURN_BTN.has_point(d):
		back_pressed.emit()
		return
	for i in _rows.size():
		var rr := Rect2(PANEL.position.x + 2, ROW_Y0 + i * ROW_H, PANEL.size.x - 4, ROW_H - 1)
		if rr.has_point(d):
			var id := int((_rows[i] as Dictionary).get("id", -1))
			if id >= 0:
				club_selected.emit(id)
			return


func setup(rows: Array, title_left: String, season: String, week_label: String,
		tier: int = 1, my_id: int = -1) -> void:
	_rows = rows
	_title_left = title_left
	_season = season
	_week_label = week_label
	_tier = tier
	_my_id = my_id
	queue_redraw()


# ---- kits ----------------------------------------------------------------

func _kit(id: int) -> Texture2D:
	if not _kits.has(id):
		var path := "res://art/kits/%d.png" % id
		_kits[id] = load(path) if ResourceLoader.exists(path) else null
	return _kits[id]


func _draw_kit(id: int, x: float, y: float, box_w: float, box_h: float) -> void:
	var tex := _kit(id)
	if tex == null:
		return
	var s: float = min(box_w / KIT_SRC.size.x, box_h / KIT_SRC.size.y)
	var w := KIT_SRC.size.x * s
	var h := KIT_SRC.size.y * s
	draw_texture_rect_region(tex, Rect2(x + (box_w - w) * 0.5, y + (box_h - h) * 0.5, w, h), KIT_SRC)


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
	PMChrome.draw_header(self, "LEAGUE TABLES", "", _title_left, _div_name(_tier),
		_season, _week_num(), _my_id)

	# White-bordered table panel.
	PMChrome.bevel(self, PANEL, C_PANEL, C_PANEL_HI, C_PANEL_LO, 2.0)
	_draw_panel_strip()
	_draw_col_header()
	_draw_rows()
	_leader_panel()


## The strip inside the panel top: division name (left) + a Date stepper (right).
func _draw_panel_strip() -> void:
	_txt(_f18, 16, 54, _div_name(_tier).to_upper() + " LEAGUE", C_SUBTITLE, 18)
	# Date stepper: "Date" label + [<] [DD/MM/YYYY] [>]
	var d := PMChrome.date_parts(_season, _week_num())
	_txt(_f12, 318, 58, "Date", C_DATE_LBL, 13)
	PMChrome.bevel(self, Rect2(356, 54, 16, 16), C_STEP_BG, C_STEP_HI, C_BTN_LO)
	_txt(_f12, 360, 56, "<", Color.WHITE, 13)
	var datebox := Rect2(374, 54, 132, 16)
	PMChrome.bevel(self, datebox, C_STEP_BG, C_STEP_HI, C_BTN_LO)
	var ds := "%02d/%02d/%d" % [int(d["day"]), _MONTH_NUM.get(d["mon"], 1), int(d["year"])]
	_txt(_f12, 382, 56, ds, Color(0.86, 0.92, 1.0), 13)
	PMChrome.bevel(self, Rect2(508, 54, 16, 16), C_STEP_BG, C_STEP_HI, C_BTN_LO)
	_txt(_f12, 512, 56, ">", Color.WHITE, 13)


func _draw_col_header() -> void:
	var hr := Rect2(PANEL.position.x + 2, HDR_Y, PANEL.size.x - 4, 16)
	PMChrome.bevel(self, hr, C_PANEL_HDR, C_PANEL_HI, C_PANEL_LO)
	_txt(_f12, 60, HDR_Y + 2, "POS", C_HDR_TXT, 12)
	_txt(_f12, C_NAME_X, HDR_Y + 2, "TEAM", C_HDR_TXT, 12)
	var heads := ["P", "W", "D", "L", "GF", "GA"]
	for c in 6:
		_txt(_f12, STAT_XS[c], HDR_Y + 2, heads[c], C_HDR_TXT, 12, true)
	_txt(_f12, PTS_X + 22, HDR_Y + 2, "PTS", C_HDR_TXT, 12, true)


func _draw_rows() -> void:
	var n := _rows.size()
	var releg := int(SeasonSim.ZONES.get(_tier, {"releg": 3}).get("releg", 3))
	var promo := int(SeasonSim.ZONES.get(_tier, {"promo": 0}).get("promo", 0))
	for i in n:
		var r: Dictionary = _rows[i]
		var y := ROW_Y0 + i * ROW_H
		draw_rect(Rect2(PANEL.position.x + 2, y, PANEL.size.x - 4, ROW_H - 1),
			C_ROW_A if i % 2 == 0 else C_ROW_B, true)
		_zone_tag(i, n, promo, releg, y)
		if int(r.get("id", -1)) == _my_id:
			draw_rect(Rect2(PANEL.position.x + 2, y, PANEL.size.x - 4, ROW_H - 1),
				Color(1, 1, 1, 0.10), true)
		var euro := _tier == 1 and i < 5
		_txt(_f12, C_POS_R, y + 2, str(i + 1), C_POS_EURO if euro else C_NAME, 13, true)
		_draw_kit(int(r.get("id", -1)), C_CREST_X, y, 16, ROW_H - 1)
		_txt(_f12, C_NAME_X, y + 2, str(r.get("name", "?")).substr(0, 18), C_NAME, 13)
		var vals := [r.get("P", 0), r.get("W", 0), r.get("D", 0), r.get("L", 0),
			r.get("GF", 0), r.get("GA", 0)]
		for c in 6:
			var x: int = STAT_XS[c]
			PMChrome.bevel(self, Rect2(x - STAT_W + 2, y + 1, STAT_W, ROW_H - 3),
				C_CELL, C_CELL_HI, C_CELL_LO)
			_txt(_f12, x - 2, y + 2, str(vals[c]), C_CELL_TXT, 13, true)
		PMChrome.bevel(self, Rect2(PTS_X, y + 1, 26, ROW_H - 3), C_PTS, C_PTS_HI, C_CELL_LO)
		_txt(_f12, PTS_X + 22, y + 2, str(r.get("Pts", 0)), C_PTS_TXT, 13, true)


## Zone tag hung on the panel's left edge (EURO CUP / UEFA / PROMOTION / RELEGATION).
func _zone_tag(i: int, n: int, promo: int, releg: int, y: int) -> void:
	var label := ""
	var bg := C_EUROTAG
	if _tier == 1 and i < 2:
		label = "EURO CUP"
	elif _tier == 1 and i < 5:
		label = "U.E.F.A."; bg = C_UEFATAG
	elif _tier > 1 and i < promo:
		label = "PROMOTION"; bg = C_PROMOTAG
	elif i >= n - releg:
		label = "RELEGATION"; bg = C_RELEGTAG
	if label == "":
		return
	var tag := Rect2(2, y + 1, 56, ROW_H - 3)
	PMChrome.bevel(self, tag, bg, bg.lightened(0.25), bg.darkened(0.4))
	var col := Color.WHITE if bg == C_PROMOTAG else C_TAG_TXT
	_txt(_f8, 5, y + 3, label, col, 9)


# Right-side LEADER panel: leader's kit + name, division tabs, GOAL SCORERS, RETURN.
func _leader_panel() -> void:
	var px := 544
	var pw := 90
	# LEADER card.
	PMChrome.bevel(self, Rect2(px, 50, pw, 150), C_PANEL, C_PANEL_HI, C_PANEL_LO, 2.0)
	_txt(_f12, px + 6, 54, "LEADER", C_SUBTITLE, 12)
	if _rows.size() > 0:
		var lead: Dictionary = _rows[0]
		_draw_kit(int(lead.get("id", -1)), px + 21, 70, 48, 70)
		_txt(_f8, px + 5, 180, str(lead.get("name", "?")).substr(0, 16), C_HDR_TXT, 10)

	var tabs := ["Premier", "First", "Second", "Third"]
	for t in 4:
		var ty := 214 + t * 28
		var sel := (t + 1) == _tier
		PMChrome.bevel(self, Rect2(px, ty, pw, 24), C_SEL if sel else C_BTN,
			C_PTS_HI if sel else C_BTN_HI, C_BTN_LO)
		_txt(_f12, px + 8, ty + 5, tabs[t], C_PTS_TXT if sel else Color(0.82, 0.88, 1.0), 13)

	PMChrome.bevel(self, Rect2(px, 414, pw, 24), C_BTN, C_BTN_HI, C_BTN_LO)
	_txt(_f8, px + 4, 421, "GOAL SCORERS", Color(0.82, 0.88, 1.0), 10)
	PMChrome.bevel(self, Rect2(px, 446, pw, 26), C_SEL, C_PTS_HI, C_CELL_LO)
	_txt(_f12, px + 14, 451, "RETURN", C_GOLD, 14)


# ---- helpers -------------------------------------------------------------

const _MONTH_NUM := {"January": 1, "February": 2, "March": 3, "April": 4, "May": 5,
	"June": 6, "July": 7, "August": 8, "September": 9, "October": 10,
	"November": 11, "December": 12}


## Parse the 1-based week number out of "Week 17" / "Final"; 0 when unknown.
func _week_num() -> int:
	var digits := ""
	for ch in _week_label:
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0


func _div_name(tier: int) -> String:
	return {1: "Premier", 2: "Division One", 3: "Division Two", 4: "Division Three"}.get(tier, "League")
