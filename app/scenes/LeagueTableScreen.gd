extends Control
class_name LeagueTableScreen
## PM98 LEAGUE TABLES (CLASIFICACION) screen, rebuilt FRAME-TRUE from the real game.
##
## BINDING SOURCE: there is NO LEAGUE TABLES frame in the walkthrough (all 239 distinct
## management screens were scanned; the standings grid never appears). The binding source
## is therefore the genuine PC capture real-gallery/ma_10.png (Premier, Week 17), cross-
## checked vs hires_league_table.jpg. See docs/re/league_table_screen_re.md.
##
## The static chrome is ma_10's pixels cut 1:1 by tools/re/build_leaguetable_chrome_from_frames.py
## into art/screens/leaguetable/chrome.png with ONLY the dynamic layers blanked (the 20
## standings rows, the LEADER kit, the date-box digits). This scene blits that chrome at
## 640x480, OVERDRAWS the live barra with PMChrome.draw_header (the TransferScreen pattern,
## so manager/club/date/week track the real career), and redraws the standings rows, the
## leader kit and the date value from Career.standings(). Every colour below was SAMPLED
## off ma_10 (leaguetable_chrome.json) — nothing is hand-invented.
##
## Only Premier is witnessed. The baked chrome (PREMIER LEAGUE subtitle, Premier-selected
## tab, EURO CUP / U.E.F.A. / RELEGATION zone-tag column) is Premier-only; a non-Premier
## career renders Premier chrome (documented GAP). Cross-division tab switching has no
## backing table in the Career layer, so the tabs are a no-op indicator (never invent
## another division's table).
##
## Interactive: RETURN dismisses; a tap on a standings row raises that club's squad.

signal back_pressed              # RETURN -> dismiss
signal club_selected(id: int)    # a standings row tap -> open that club's squad
signal scorers_pressed           # GOAL SCORERS button -> the scorers graph+list screen

const W := 640
const H := 480

# ---- row grid + column anchors (measured off ma_10; leaguetable_chrome.json) ----
const ROW_Y0 := 114
const ROW_PITCH := 16
const ROW_H := 14                     # coloured band (2px white gap below, baked)
const POS_REGION := Rect2(73, 0, 26, ROW_H)   # POS number sub-region (x only; y set live)
const CREST_BOX := Rect2(99, 0, 20, ROW_H)
const NAME_X := 127
const NAME_REGION_X0 := 123
const NAME_REGION_X1 := 270
# stat cells: [left_x, width]; order P W D L GF GA
const STAT_CELLS := [[271, 23], [296, 23], [321, 23], [346, 23], [371, 34], [407, 34]]
const PTS_CELL := [443, 38]
const SEP_XS := [270, 295, 320, 345, 370, 406, 442, 482]
const LEADER_KIT_BOX := Rect2(553, 97, 51, 65)
const DATE_RIGHT := 447                # right edge for the DD/MM/YYYY value
const DATE_Y := 76
const RETURN_BTN := Rect2(525, 423, 99, 25)
const SCORERS_BTN := Rect2(525, 354, 99, 24)   # GOAL SCORERS (baked; league_table_screen_re.md)

# ---- palette sampled off ma_10 (leaguetable_chrome.json "samples") ----
# normal (non-managed) row
const C_POS_BG := Color8(180, 200, 220)
const C_POS_INK := Color8(0, 0, 128)
const C_NAME_BG := Color8(0, 0, 128)
const C_NAME_INK := Color8(255, 255, 255)
const C_SEP := Color8(0, 0, 0)
# per-column cell [bg, ink] for P W D L GF GA
const CELL_BG := [Color8(220, 220, 220), Color8(180, 200, 220), Color8(212, 223, 170),
	Color8(212, 191, 170), Color8(180, 200, 220), Color8(212, 191, 170)]
const CELL_INK := [Color8(128, 128, 128), Color8(100, 120, 140), Color8(127, 159, 85),
	Color8(170, 127, 85), Color8(100, 120, 140), Color8(170, 127, 85)]
const C_PTS_BG := Color8(72, 30, 2)
const C_PTS_INK := Color8(255, 223, 0)
# managed (my-club) row — the dark/saturated variant
const C_MINE_POS_BG := Color8(42, 63, 170)
const C_MINE_POS_INK := Color8(166, 202, 240)
const C_MINE_NAME_BG := Color8(0, 0, 0)
const MINE_CELL_BG := [Color8(80, 80, 80), Color8(80, 100, 120), Color8(80, 110, 5),
	Color8(85, 0, 0), Color8(80, 100, 120), Color8(170, 127, 85)]
const MINE_CELL_INK := [Color8(192, 192, 192), Color8(166, 202, 240), Color8(170, 223, 170),
	Color8(255, 31, 0), Color8(166, 202, 240), Color8(212, 191, 170)]
const C_MINE_PTS_BG := Color8(150, 0, 0)
const C_MINE_PTS_INK := Color8(255, 255, 255)
# date stepper
const C_DATE_INK := Color8(180, 210, 50)

var _chrome: Texture2D
var _f12: Font
var _f8: Font

var _rows: Array = []
var _title_left: String = ""
var _manager: String = ""       # career manager name for the two-line barra plaque ("" = sim table)
var _season: String = "1997-98"
var _week_label: String = ""
var _tier: int = 1
var _my_id: int = -1


func _ready() -> void:
	_chrome = load("res://art/screens/leaguetable/chrome.png")
	_f12 = PMChrome.font("12")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(rows: Array, title_left: String, season: String, week_label: String,
		tier: int = 1, my_id: int = -1, manager: String = "") -> void:
	_rows = rows
	_title_left = title_left
	_season = season
	_week_label = week_label
	_tier = tier
	_my_id = my_id
	_manager = manager
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
	var d := _to_design(e.position)
	if RETURN_BTN.has_point(d):
		back_pressed.emit()
		return
	if SCORERS_BTN.has_point(d):
		scorers_pressed.emit()
		return
	for i in _rows.size():
		var rr := Rect2(73, ROW_Y0 + i * ROW_PITCH, 482 - 73, ROW_H)
		if rr.has_point(d):
			var id := int((_rows[i] as Dictionary).get("id", -1))
			if id >= 0:
				club_selected.emit(id)
			return


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Baked ma_10 chrome (light marble bg, panel, headers, tags, tabs, buttons).
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	# Live barra over the baked header (manager/club/date/week track the real career).
	PMChrome.draw_header(self, "LEAGUE TABLES", _manager, _title_left, _div_name(_tier),
		_season, _week_num(), _my_id)

	_draw_date()
	_draw_rows()
	_draw_leader_kit()


## Redraw the Date-stepper value from the live week (green DD/MM/YYYY over the navy box).
## NOTE the box value reads 2 days behind the header calendar sheet in ma_10 (27/11 vs
## Sat 29/11); that offset is un-RE'd, so this mirrors the calendar sheet's date (GAP).
func _draw_date() -> void:
	var d := PMChrome.date_parts(_season, _week_num())
	var ds := "%02d/%02d/%d" % [int(d["day"]), _MONTH_NUM.get(d["mon"], 1), int(d["year"])]
	PMChrome.text(self, _f12, DATE_RIGHT, DATE_Y, ds, C_DATE_INK, 12, 2)


func _draw_rows() -> void:
	for i in _rows.size():
		if i >= 20:
			break                     # only 20 baked Premier slots (see doc gap)
		var r: Dictionary = _rows[i]
		var y := ROW_Y0 + i * ROW_PITCH
		var mine := int(r.get("id", -1)) == _my_id and _my_id >= 0

		# Region 1: POS number + crest.
		draw_rect(Rect2(73, y, 122 - 73, ROW_H), C_MINE_POS_BG if mine else C_POS_BG, true)
		PMChrome.text(self, _f12, POS_REGION.position.x, y + 1, str(i + 1),
			C_MINE_POS_INK if mine else C_POS_INK, 12, 1, POS_REGION.size.x)
		PMChrome.draw_crest(self, int(r.get("id", -1)), Rect2(CREST_BOX.position.x, y, CREST_BOX.size.x, ROW_H))

		# Region 2: team name plate.
		draw_rect(Rect2(NAME_REGION_X0, y, NAME_REGION_X1 - NAME_REGION_X0, ROW_H),
			C_MINE_NAME_BG if mine else C_NAME_BG, true)
		PMChrome.text(self, _f12, NAME_X, y + 1, str(r.get("name", "?")),
			C_NAME_INK, 12, 0, NAME_REGION_X1 - NAME_X - 2)

		# Stat cells P W D L GF GA.
		var vals := [r.get("P", 0), r.get("W", 0), r.get("D", 0), r.get("L", 0),
			r.get("GF", 0), r.get("GA", 0)]
		for c in 6:
			var cx: int = STAT_CELLS[c][0]
			var cw: int = STAT_CELLS[c][1]
			draw_rect(Rect2(cx, y, cw, ROW_H), (MINE_CELL_BG[c] if mine else CELL_BG[c]) as Color, true)
			PMChrome.text(self, _f12, cx, y + 1, str(vals[c]),
				(MINE_CELL_INK[c] if mine else CELL_INK[c]) as Color, 12, 1, cw)

		# PTS cell.
		draw_rect(Rect2(PTS_CELL[0], y, PTS_CELL[1], ROW_H), C_MINE_PTS_BG if mine else C_PTS_BG, true)
		PMChrome.text(self, _f12, PTS_CELL[0], y + 1, str(r.get("Pts", 0)),
			C_MINE_PTS_INK if mine else C_PTS_INK, 12, 1, PTS_CELL[1])

		# Black 1px column separators (the frame's cell borders).
		for sx in SEP_XS:
			draw_rect(Rect2(sx, y, 1, ROW_H), C_SEP, true)


## The LEADER card kit = the current leader (standings[0]) fitted in the white card.
func _draw_leader_kit() -> void:
	if _rows.size() > 0:
		PMChrome.draw_crest(self, int((_rows[0] as Dictionary).get("id", -1)), LEADER_KIT_BOX)


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
