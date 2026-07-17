extends Control
class_name MatchResultScreen
## PM98 RESULT-mode match — the real HALF TIME / FULL TIME read-out (live captures
## screenshots/wine-captures-2026-07-12/match_result_{fulltime,halftime_oldtrafford}.png):
## the shared match barra with the HALF/FULL TIME title, the kits + scoreline, the
## POSSESSION bar, the two teams' BOOKINGS | GOALS panels + TOTAL FOULS, the STADIUM
## panel and (full time) MAN OF THE MATCH + CONTINUE.
##
## Static chrome is the real frame, baked to art/screens/matchflow/result_{ft,ht}.png by
## tools/re/build_match_flow_chrome_from_frames.py with the club-specific data cleared.
## The screen redraws: the barra (PMChrome.draw_match_header — parity-locked, reused, NOT
## rebuilt) + the baked HALF/FULL TIME title sprite, the kits + names + score, the real
## GOAL rows, and the Career-known stadium CAPACITY / ATTENDANCE + ground name.
##
## EVENT-STREAM HONESTY (docs/re/APP_VS_SPEC_AUDIT.md B3/B4b): the instant-result stat
## engine records ONLY goals (scorer + minute). GOALS columns are the REAL vector; the
## BOOKINGS columns, TOTAL FOULS, the POSSESSION %, the attendance-money / sponsor lines
## and MAN OF THE MATCH are NOT produced -> they render the original chrome with an honest
## empty/absent state, never fabricated (match_flow_re.md "renderable-today vs gap").

signal continue_pressed

const W := 640
const H := 480

# frame-measured geometry (tools/re/specs/match_flow_chrome_samples.json "result")
const TITLE_XY := {"fulltime": Vector2(244, 13), "halftime": Vector2(242, 13)}
# Score boxes frame-measured off the witnessed FT read-outs (build_match_flow_chrome
# spec "result"): left x266..319, right x320..373, y78..113. The digit centres in the box.
const BOX_L := Rect2(266, 78, 53, 35)      # left score box
const BOX_R := Rect2(320, 78, 53, 35)      # right score box
const NAME_H_X := 40                       # home name left edge
const NAME_A_X := 604                      # away name right edge
const KIT_H := Vector2(6, 60)              # home kit anchor (escudo top-left)
const KIT_A := Vector2(590, 60)            # away kit anchor
const GCOL := {"home": Vector2(169, 289), "away": Vector2(482, 602)}   # GOALS cell columns
const ROW_Y0 := 172
const ROW_PITCH := 16
const N_ROWS := 7
const FOULS := [Rect2(123, 283, 34, 16), Rect2(436, 283, 34, 16)]   # value zones (overpaint)
const STAD_NAME_Y := 357
const STAD_ROWS := [380, 396, 412]          # CAPACITY / ATTENDANCE (money rows blank)
const STAD_LABEL_X := 22
const STAD_VALUE_X := 150
const CONTINUE := Rect2(479, 439, 112, 25)
const KIT_SRC := Rect2(0, 0, 31, 64)

const C_NAME := Color(0.98, 0.99, 1.0)
const C_SCORE := Color(1, 1, 1)
const C_CELL_TXT := Color(0.10, 0.16, 0.10)   # dark text on the green GOALS cells
const C_STAD_TXT := Color(0.90, 0.94, 1.0)    # white on the blue stadium rows
const C_STAD_NAME := Color(0, 0, 0)           # black on the white ground-name row (witnessed)
const C_FOULS_BG := Color8(117, 147, 187)     # TOTAL FOULS band
const C_PRESS := Color(1, 1, 1, 0.20)

var _bg: Texture2D
var _title: Texture2D
var _f18: Font
var _f10: Font
var _f8: Font
var _home := "HOME"
var _away := "AWAY"
var _hg := 0
var _ag := 0
var _home_kit: Texture2D
var _away_kit: Texture2D
var _goals_home: Array = []    # [{scorer, minute}]
var _goals_away: Array = []
var _header: Dictionary = {}
var _stadium: Dictionary = {}  # {name, capacity, attendance} (Career-known) or {}
var _half := false
var _press := ""


func _ready() -> void:
	_f18 = PMChrome.font("18")
	_f10 = PMChrome.font("10")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed a finished fixture.
##   goals   = the stat engine's real vector [{minute, side(0/1), scorer, own_goal}]
##   header  = PMChrome.draw_match_header dict (fixture mode: top/bottom/home_id/away_id)
##   stadium = {name, capacity, attendance} for the managed ground (Career-known), else {}
##   half    = true for HALF TIME (hides MAN OF THE MATCH + CONTINUE), else FULL TIME
func setup(home_name: String, away_name: String, hg: int, ag: int, goals: Array,
		home_id: int, away_id: int, header: Dictionary = {}, stadium: Dictionary = {},
		half := false) -> void:
	_home = home_name
	_away = away_name
	_hg = hg
	_ag = ag
	_home_kit = PMChrome.kit(home_id)
	_away_kit = PMChrome.kit(away_id)
	_half = half
	_header = header
	_stadium = stadium
	_goals_home.clear()
	_goals_away.clear()
	for g in goals:
		if not (g is Dictionary):
			continue
		var side := int((g as Dictionary).get("side", (g as Dictionary).get("scorer_side", -1)))
		var row := {"scorer": str((g as Dictionary).get("scorer", "")),
			"minute": int((g as Dictionary).get("minute", 0))}
		if side == 0:
			_goals_home.append(row)
		elif side == 1:
			_goals_away.append(row)
	var key := "halftime" if half else "fulltime"
	_bg = load("res://art/screens/matchflow/result_%s.png" % ("ht" if half else "ft"))
	var tp := "res://art/screens/matchflow/title_%s.png" % key
	_title = load(tp) if ResourceLoader.exists(tp) else null
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	# Both HALF TIME and FULL TIME advance on the CONTINUE button (witnessed §5: the
	# RESULTS-mode HT read-out carries a real CONTINUE + STATISTICS/TACTICS/LINE-UP
	# chrome -- it is NOT a tap-anywhere dismiss). The manager-side buttons are baked
	# chrome, inert for now (their sub-screens mid-match are an un-ported gap, like the
	# BRIEF doors); CONTINUE is the only live control.
	if e.pressed:
		_press = "continue" if CONTINUE.has_point(d) else ""
	else:
		if _press == "continue" and CONTINUE.has_point(d):
			continue_pressed.emit()
		_press = ""
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)

	# barra (reused PMChrome — parity-locked) + the baked HALF/FULL TIME title
	if not _header.is_empty():
		PMChrome.draw_match_header(self, "", _header)
	if _title != null:
		draw_texture(_title, TITLE_XY["halftime" if _half else "fulltime"])

	# kits + names + score on the scoreline band
	_draw_kit(_home_kit, KIT_H)
	_draw_kit(_away_kit, KIT_A)
	_name(_f18, NAME_H_X, 74, _home.to_upper(), false, 236)
	_name(_f18, NAME_A_X, 74, _away.to_upper(), true, 200)
	_score(BOX_L, _hg)
	_score(BOX_R, _ag)

	# GOALS columns = the REAL vector (BOOKINGS columns stay honestly empty)
	_draw_goals(_goals_home, GCOL["home"])
	_draw_goals(_goals_away, GCOL["away"])

	# TOTAL FOULS is a gap -> honest absent (cover the baked value)
	for r in FOULS:
		draw_rect(r, C_FOULS_BG, true)

	# STADIUM panel: the Career-known ground name + CAPACITY + ATTENDANCE (the money
	# / sponsor rows are a gap -> left blank in the bake).
	_draw_stadium()

	if _press != "":
		draw_rect(CONTINUE, C_PRESS, true)


func _draw_goals(rows: Array, col: Vector2) -> void:
	for i in mini(rows.size(), N_ROWS):
		var y: int = ROW_Y0 + ROW_PITCH * i
		var r: Dictionary = rows[i]
		_txt(_f8, int(col.x) + 6, y, str(r.get("scorer", "")), C_CELL_TXT, 11, false, int(col.y) - 34)
		_txt(_f8, int(col.y) - 28, y, str(r.get("minute", 0)), C_CELL_TXT, 11)


func _draw_stadium() -> void:
	if _stadium.is_empty():
		return
	var gname := str(_stadium.get("name", ""))
	if gname != "":
		# The ground-name row is WHITE with BLACK ink (witnessed OT/Villa/Dell/Reebok);
		# only the CAPACITY/ATTENDANCE rows below are white-on-blue.
		_txt(_f8, 80, STAD_NAME_Y, gname, C_STAD_NAME, 11, false, 288)
	var cap := int(_stadium.get("capacity", 0))
	var att := int(_stadium.get("attendance", 0))
	if cap > 0:
		_txt(_f8, STAD_LABEL_X, STAD_ROWS[0], "CAPACITY:", C_STAD_TXT, 11)
		_txt(_f8, STAD_VALUE_X, STAD_ROWS[0], "%s spectators" % _grp(cap), C_STAD_TXT, 11)
	if att > 0 and cap > 0:
		var pct := int(round(100.0 * att / cap))
		_txt(_f8, STAD_LABEL_X, STAD_ROWS[1], "ATTENDANCE:", C_STAD_TXT, 11)
		_txt(_f8, STAD_VALUE_X, STAD_ROWS[1], "%s   %d %%" % [_grp(att), pct], C_STAD_TXT, 11)


static func _grp(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


func _draw_kit(tex: Texture2D, at: Vector2) -> void:
	if tex == null:
		return
	var sc: float = min(42.0 / KIT_SRC.size.x, 50.0 / KIT_SRC.size.y)
	draw_texture_rect_region(tex, Rect2(at.x, at.y, KIT_SRC.size.x * sc, KIT_SRC.size.y * sc), KIT_SRC)


func _name(f: Font, x: int, y_top: int, t: String, right_align: bool, maxw: int) -> void:
	if f == null:
		return
	var sz := 20
	while f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw and sz > 8:
		sz -= 1
	var wd := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := (x - wd) if right_align else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, C_NAME)


func _score(box: Rect2, n: int) -> void:
	_txt(_f18, int(box.position.x), int(box.position.y) + 8, str(n), C_SCORE, 24, true, 0, int(box.size.x))


## Draw text. center centres in cw (from x). clamp_x auto-shrinks to fit [x..clamp_x].
func _txt(f: Font, x: int, y_top: int, t: String, col: Color, sz: int, center := false,
		clamp_x := 0, cw := 0) -> void:
	if f == null or t == "":
		return
	if clamp_x > 0:
		while f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > float(clamp_x - x) and sz > 7:
			sz -= 1
	var wd := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if center and cw > 0:
		px = x + (cw - wd) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- letterbox scaling ---------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
