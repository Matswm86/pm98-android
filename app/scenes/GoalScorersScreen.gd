extends Control
class_name GoalScorersScreen
## PM98 GOAL SCORERS screen (LEAGUE TABLES -> GOAL SCORERS), rebuilt FRAME-TRUE.
##
## BINDING SOURCES (docs/re/goalscorers_screen_re.md):
##  * EMPTY chrome: walkthrough 047_154510.png (== 048 == parity orig/12 at 0.00 diff).
##  * POPULATED semantics + inks: the 2026-07-18 live wine witness run
##    (screenshots/wine-captures-2026-07-18-goalscorers/): frames 18 (WEEKS 2 list),
##    21/22/23/24/26 (COMPARE arm -> row select -> slot fill -> graph mark),
##    27 (player goal-log popup), 84/87/88/89/90 (WEEKS 4 list, pager-arrow inertness,
##    slot reset on re-entry, Abou 3-goal mark).
##
## WITNESSED SEMANTICS ported 1:1:
##  * Pager band shows "WEEKS <rounds played>" in gold; EMPTY (no text) before round 1
##    (walkthrough 047 preseason state). The stepper arrows changed 0 px when clicked at
##    2 and 4 rounds played -> ported as baked, INERT chrome (documented unknown).
##  * List = top scorers, G. / PLAYER / TEAM, max 14 rows (witnessed grid), ranked by
##    goals desc; ties keep first-to-reach-that-count order (frames 18/87 orders are
##    consistent with this; not exhaustively provable - see RE doc).
##  * COMPARE button arms a slot (label swaps to the baked SELECT sprite; the white ring
##    seen in frame 21 is the standard click-focus border, not armed chrome). A row tap
##    WHILE ARMED fills the slot bar (club kit + surname), outlines the picked row and
##    plots that player on the graph IMMEDIATELY - the arm persists (frame 22: mark +
##    slot + border with the label still SELECT); tapping the button again disarms
##    (frame 23: label back to COMPARE, border gone, mark stays). An unarmed row tap
##    opens the per-player goal-log popup. Slots RESET when the screen is left
##    (witnessed: compares gone on re-entry at week 5).
##  * Graph mark geometry (pixel-calibrated): week w at cumulative total g draws a 2x2
##    dot at (67 + 5*(w-1), 309 - 5*g); consecutive plotted weeks connect (flat runs are
##    witnessed contiguous); weeks with total 0 draw NOTHING (Sheringham wk1 absent).
##    Mark colour = slot stripe colour: WHITE / RED (both witnessed) / BLUE 0,0,220
##    (slot-3 stripe; a blue compare was never armed in a witness - pattern-derived).
##  * Popup (frame 27): "First Middle SURNAME" title, WEEK | MATCH (home/away club) |
##    MIN. rows ("'88"-style minute, the original's tick glyph), "Data up to MATCH n"
##    strip, RETURN. 12 rows witnessed in the panel.
##
## Interactive: RETURN dismisses (popup first if open).

signal back_pressed

const W := 640
const H := 480

# ---- geometry (all measured off the binding frames; see the bake tool) ----
const ROW_Y0 := 123
const ROW_PITCH := 16
const ROW_H := 12
const N_ROWS := 14
const CELL_G := [319, 355]
const CELL_PLAYER := [356, 466]
const CELL_TEAM := [467, 606]
const PAGER_BAND := Rect2(330, 81, 214, 15)
const GRAPH_X0 := 67
const GRAPH_Y_BASE := 309
const GRAPH_STEP := 5
const SLOT_BARS := [Rect2(10, 377, 137, 25), Rect2(160, 377, 137, 25), Rect2(310, 377, 137, 25)]
const SLOT_KIT := [13, 384, 24, 17]      # x-off, y, w, h
const SLOT_NAME_X := 44
const COMPARE_BTNS := [Rect2(16, 420, 127, 26), Rect2(166, 420, 127, 26), Rect2(316, 420, 127, 26)]
const SELECT_LABEL_OFF := Vector2(28, 4)
const RETURN_BTN := Rect2(508, 420, 125, 26)
const LIST_HIT := Rect2(316, 121, 294, 16 * 14)   # row tap region (border bbox 317..607)

# popup (frame coords; popup.png is the POPUP_BOX crop blitted back at its origin)
const POPUP_POS := Vector2(104, 104)
const POP_ROW_Y0 := 150
const POP_ROW_PITCH := 16
const POP_ROW_H := 12
const POP_N_ROWS := 12
const POP_CELL_WEEK := [113, 159]
const POP_CELL_M1 := [160, 306]
const POP_CELL_M2 := [307, 453]
const POP_CELL_MIN := [455, 505]
const POP_TITLE_BAND := Rect2(150, 111, 355, 20)
const POP_STRIP := Rect2(115, 348, 260, 14)
const POP_RETURN := Rect2(455, 344, 78, 20)

# ---- palette (sampled off the witness frames; goalscorers_chrome.json) ----
const C_G_INK := Color8(30, 52, 98)
const C_PLAYER_INK := Color8(255, 255, 255)
const C_TEAM_INK := Color8(0, 0, 0)
const C_PAGER_INK := Color8(255, 223, 0)
const C_SEL_BORDER := Color8(85, 127, 255)
const C_SLOT_NAME_INK := Color8(0, 0, 0)
const MARK_COLORS := [Color8(255, 255, 255), Color8(255, 31, 0), Color8(0, 0, 220)]
const C_POP_WEEK_INK := Color8(255, 223, 0)
const C_POP_MATCH_INK := Color8(255, 255, 255)
const C_POP_MIN_INK := Color8(0, 0, 128)
const C_POP_TITLE_INK := Color8(255, 255, 255)
const C_POP_STRIP_INK := Color8(30, 52, 98)

var _chrome: Texture2D
var _select_label: Texture2D
var _popup_tex: Texture2D
var _f12: Font
var _f8: Font     # the thin list face (proman8 @11 matches the original rows; RE doc)

var _rows: Array = []           # [{name, club_id, goals, legal}] ranked, from Career
var _goal_log: Dictionary = {}  # "name|club_id" -> [{week, minute, h, a}]
var _club_names: Dictionary = {}
var _weeks_played: int = 0
var _manager: String = ""
var _club_name: String = ""
var _tier: int = 1
var _season: String = "1997-98"
var _week_label: String = ""
var _my_id: int = -1

var _armed: int = -1            # compare slot armed for SELECT (-1 = none)
var _armed_pick: int = -1       # row index picked during the current arm (border)
var _slots: Array = [null, null, null]   # each null or {name, club_id}
var _popup: Dictionary = {}     # {} or {legal, rows: [{week, h, a, minute}]}


func _ready() -> void:
	_chrome = load("res://art/screens/goalscorers/chrome.png")
	_select_label = load("res://art/screens/goalscorers/select_label.png")
	_popup_tex = load("res://art/screens/goalscorers/popup.png")
	_f12 = PMChrome.font("12")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(rows: Array, goal_log: Dictionary, club_names: Dictionary, weeks_played: int,
		manager: String, club_name: String, tier: int, season: String,
		week_label: String, my_id: int) -> void:
	_rows = rows
	_goal_log = goal_log
	_club_names = club_names
	_weeks_played = weeks_played
	_manager = manager
	_club_name = club_name
	_tier = tier
	_season = season
	_week_label = week_label
	_my_id = my_id
	# Witnessed: compare slots are EMPTY on every entry (week-5 re-entry lost the
	# week-3 selections) -> state lives and dies with the screen instance.
	_armed = -1
	_armed_pick = -1
	_slots = [null, null, null]
	_popup = {}
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
	if not _popup.is_empty():
		if POP_RETURN.has_point(d):
			_popup = {}
			queue_redraw()
		return               # popup is modal (witnessed: list under it inert)
	if RETURN_BTN.has_point(d):
		back_pressed.emit()
		return
	for i in COMPARE_BTNS.size():
		if (COMPARE_BTNS[i] as Rect2).has_point(d):
			# Second tap on the armed button DISARMS (witnessed 22->23: label back to
			# COMPARE, border gone, slot + mark stay). A different button re-arms there.
			if _armed == i:
				_armed = -1
			else:
				_armed = i
			_armed_pick = -1
			queue_redraw()
			return
	if LIST_HIT.has_point(d):
		var idx := int((d.y - float(ROW_Y0)) / ROW_PITCH)
		if idx >= 0 and idx < mini(_rows.size(), N_ROWS):
			_row_tapped(idx)
		return


func _row_tapped(idx: int) -> void:
	var r: Dictionary = _rows[idx]
	if _armed >= 0:
		# SELECT: fill the armed slot + plot immediately; the arm PERSISTS and the picked
		# row keeps a border until the button is tapped again (witnessed 22).
		_slots[_armed] = {"name": str(r.get("name", "")), "club_id": int(r.get("club_id", -1))}
		_armed_pick = idx
	else:
		# Unarmed tap = the per-player goal-log popup (witnessed 27).
		_popup = {
			"legal": str(r.get("legal", r.get("name", ""))),
			"rows": _log_of(str(r.get("name", "")), int(r.get("club_id", -1))),
		}
	queue_redraw()


func _log_of(name: String, club_id: int) -> Array:
	return _goal_log.get("%s|%d" % [name, club_id], [])


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	PMChrome.draw_header(self, "GOAL SCORERS", _manager, _club_name, _div_name(_tier),
		_season, _week_num(), _my_id)

	_draw_pager()
	_draw_list()
	_draw_slots()
	_draw_graph()
	if not _popup.is_empty():
		_draw_popup()


## "WEEKS n" (gold, centred in the dark-red band) once at least one round is played.
## The preseason band is blank in the binding frame -> no text at 0 rounds.
func _draw_pager() -> void:
	if _weeks_played <= 0:
		return
	PMChrome.text(self, _f12, PAGER_BAND.position.x, PAGER_BAND.position.y + 1,
		"WEEKS %d" % _weeks_played, C_PAGER_INK, 12, 1, PAGER_BAND.size.x)


func _draw_list() -> void:
	for i in mini(_rows.size(), N_ROWS):
		var r: Dictionary = _rows[i]
		var y := ROW_Y0 + i * ROW_PITCH
		PMChrome.text(self, _f8, CELL_G[0], y + 2, str(r.get("goals", 0)),
			C_G_INK, 11, 1, CELL_G[1] - CELL_G[0])
		PMChrome.text(self, _f8, CELL_PLAYER[0], y + 2, str(r.get("name", "?")),
			C_PLAYER_INK, 11, 1, CELL_PLAYER[1] - CELL_PLAYER[0])
		PMChrome.text(self, _f8, CELL_TEAM[0], y + 2, str(_club_names.get(int(r.get("club_id", -1)), "?")),
			C_TEAM_INK, 11, 1, CELL_TEAM[1] - CELL_TEAM[0])


## Armed state: swap the armed button's label to the baked SELECT sprite (21/24) and
## outline the row picked during this arm (frame 22 border, cleared on disarm).
func _draw_slots() -> void:
	if _armed >= 0 and _select_label != null:
		var b := COMPARE_BTNS[_armed] as Rect2
		draw_texture(_select_label, b.position + SELECT_LABEL_OFF)
	if _armed >= 0 and _armed_pick >= 0:
		var y := ROW_Y0 + _armed_pick * ROW_PITCH
		draw_rect(Rect2(317, y - 2, 291, ROW_H + 4), C_SEL_BORDER, false, 2.0)
	for i in _slots.size():
		if _slots[i] == null:
			continue
		var sd: Dictionary = _slots[i]
		var bar := SLOT_BARS[i] as Rect2
		PMChrome.draw_crest(self, int(sd.get("club_id", -1)),
			Rect2(bar.position.x + SLOT_KIT[0] - 10, SLOT_KIT[1], SLOT_KIT[2], SLOT_KIT[3]))
		PMChrome.text(self, _f8, bar.position.x + SLOT_NAME_X - 10, SLOT_KIT[1] + 2,
			str(sd.get("name", "")), C_SLOT_NAME_INK, 11, 0, bar.size.x - SLOT_NAME_X - 4)


## Graph marks per the pixel-calibrated witness geometry (module header).
func _draw_graph() -> void:
	for i in _slots.size():
		if _slots[i] == null:
			continue
		var sd: Dictionary = _slots[i]
		var log: Array = _log_of(str(sd.get("name", "")), int(sd.get("club_id", -1)))
		var per_week := {}
		for g in log:
			var wk := int((g as Dictionary).get("week", 0))
			per_week[wk] = int(per_week.get(wk, 0)) + 1
		var col := MARK_COLORS[i] as Color
		var total := 0
		var prev := Vector2.ZERO
		var have_prev := false
		for wk in range(1, _weeks_played + 1):
			total += int(per_week.get(wk, 0))
			if total <= 0:
				continue      # zero-total weeks draw nothing (witnessed: Sheringham wk1)
			var g_c: int = mini(total, 45)
			var w_c: int = mini(wk, 40)
			var p := Vector2(GRAPH_X0 + GRAPH_STEP * (w_c - 1), GRAPH_Y_BASE - GRAPH_STEP * g_c)
			if have_prev:
				# Connect consecutive plotted weeks. Flat runs are witnessed contiguous
				# (Heskey x67..73); a RISING connection's shape is unwitnessed - drawn as
				# a straight 2px segment (documented interpolation, RE doc).
				if int(prev.y) == int(p.y):
					draw_rect(Rect2(prev.x, p.y, p.x - prev.x + 2, 2), col, true)
				else:
					draw_line(Vector2(prev.x + 1, prev.y + 1), Vector2(p.x + 1, p.y + 1), col, 2.0)
			draw_rect(Rect2(p.x, p.y, 2, 2), col, true)
			prev = p
			have_prev = true


func _draw_popup() -> void:
	if _popup_tex != null:
		draw_texture(_popup_tex, POPUP_POS)
	PMChrome.text(self, _f12, POP_TITLE_BAND.position.x, POP_TITLE_BAND.position.y + 2,
		str(_popup.get("legal", "")), C_POP_TITLE_INK, 12, 1, POP_TITLE_BAND.size.x)
	var rows: Array = _popup.get("rows", [])
	for i in mini(rows.size(), POP_N_ROWS):
		var g: Dictionary = rows[i]
		var y := POP_ROW_Y0 + i * POP_ROW_PITCH
		PMChrome.text(self, _f8, POP_CELL_WEEK[0], y + 2, str(g.get("week", 0)),
			C_POP_WEEK_INK, 11, 1, POP_CELL_WEEK[1] - POP_CELL_WEEK[0])
		PMChrome.text(self, _f8, POP_CELL_M1[0], y + 2, str(_club_names.get(int(g.get("h", -1)), "?")),
			C_POP_MATCH_INK, 11, 1, POP_CELL_M1[1] - POP_CELL_M1[0])
		PMChrome.text(self, _f8, POP_CELL_M2[0], y + 2, str(_club_names.get(int(g.get("a", -1)), "?")),
			C_POP_MATCH_INK, 11, 1, POP_CELL_M2[1] - POP_CELL_M2[0])
		# The original's minute glyph is a leading tick ('88, frame 27); the proman
		# raster carries ASCII apostrophe only -> "'88" (RE doc, typography note).
		PMChrome.text(self, _f8, POP_CELL_MIN[0], y + 2, "'%d" % int(g.get("minute", 0)),
			C_POP_MIN_INK, 11, 1, POP_CELL_MIN[1] - POP_CELL_MIN[0])
	PMChrome.text(self, _f8, POP_STRIP.position.x + 53, POP_STRIP.position.y + 1,
		"Data up to MATCH %d" % _weeks_played, C_POP_STRIP_INK, 11, 0)


# ---- helpers -------------------------------------------------------------

func _week_num() -> int:
	var digits := ""
	for ch in _week_label:
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0


func _div_name(tier: int) -> String:
	return {1: "Premier", 2: "Division One", 3: "Division Two", 4: "Division Three"}.get(tier, "League")
