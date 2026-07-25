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
## A per-team STATISTICS button: 0 = the LEFT (home) team, 1 = the RIGHT (away) team.
signal statistics_pressed(side: int)

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
# STADIUM panel value anchors, measured by diffing the two witnessed FULL TIME frames
# (Old Trafford 55,300/19,355/35%/£145,162/31%/£6,750 vs The Dell 15,200/12,160/80%/
# £91,200/86%/£18,750). The LABELS and the arrow chevrons are static chrome baked into
# result_ft.png and are NOT drawn here — the old bake row-medianed them away, which is
# the reported "stadium panel truncated and wrong".
const STAD_NAME := Vector2i(86, 358)        # ground name, left-aligned, black on white
const STAD_VAL_X := 109                     # CAPACITY value
const STAD_ATT_X := 128                     # ATTENDANCE value
const STAD_MONEY_X := 177                   # the two £ rows (the "£" belongs to the value)
const STAD_PCT_X := 236                     # the right sub-cell "NN %" on ATT / BOARDS
const STAD_Y := {                           # glyph tops (render-diffed to the frame)
	"cap": 377, "att": 394, "attmoney": 411, "boards": 428, "sponsor": 445,
}
# MAN OF THE MATCH: 32x32 mugshot cell + the name centred on the blue band.
const MOTM_PHOTO := Vector2i(312, 370)
const MOTM_NAME_CX := 464
const MOTM_NAME_Y := 381
const C_MOTM := Color8(180, 200, 220)       # the band's pale name ink (frame-sampled)
const CONTINUE := Rect2(479, 439, 112, 25)
# The per-team STATISTICS buttons on the board's button row. Measured off the two live
# frames (screenshots/wine-captures-2026-07-24-statistics-live/ 01 half time and 04 full
# time): the dark plates run x205..310 and x329..434, y308..332 in BOTH states. Half time
# additionally carries LINE-UP (x15..106) and TACTICS (x116..195) on the left — those are
# the manager's own mid-match doors and stay baked chrome (un-ported, see _on_input).
const STATS_BTN := [Rect2(205, 308, 106, 25), Rect2(329, 308, 106, 25)]
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
var _stadium: Dictionary = {}  # {name, capacity, attendance, gate, boards, boards_pct}
var _motm: Dictionary = {}     # {name, club, photo_id} — FUN_0044a370's pick, or {}
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
##   stadium = {name, capacity, attendance, gate, boards, boards_pct} for the fixture's
##             HOME ground, else {}
##   motm    = {name, club, photo_id} for FUN_0044a370's pick, else {} (no record)
##   half    = true for HALF TIME (hides MAN OF THE MATCH + CONTINUE), else FULL TIME
func setup(home_name: String, away_name: String, hg: int, ag: int, goals: Array,
		home_id: int, away_id: int, header: Dictionary = {}, stadium: Dictionary = {},
		half := false, motm: Dictionary = {}) -> void:
	_motm = motm
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
	# chrome -- it is NOT a tap-anywhere dismiss).
	#
	# EACH TEAM's STATISTICS button is live (owner report 2026-07-24: "in match results
	# screen the statistics button doesn't work on either team"). Witness frames 02/03
	# (half time) and 05/06 (full time) in wine-captures-2026-07-24-statistics-live/:
	# the button opens the STATISTICS table for THAT side's XI, showing the match record
	# (MP 1, MIN 45 or 90, RATING, MoM, G., SHOTS/PASSES/TAC. as x/y pairs, S., cards),
	# with RETURN back to this board. LINE-UP / TACTICS (half time, left) stay baked
	# chrome -- the manager's mid-match doors are still an un-ported gap.
	if e.pressed:
		_press = _hit(d)
	else:
		var rel := _hit(d)
		if rel != "" and rel == _press:
			if rel == "continue":
				continue_pressed.emit()
			elif rel.begins_with("stats:"):
				statistics_pressed.emit(int(rel.substr(6)))
		_press = ""
	queue_redraw()


## The live target at a design-space point ("" if none).
func _hit(d: Vector2) -> String:
	if CONTINUE.has_point(d):
		return "continue"          # live in BOTH states (witnessed 01 + 04)
	for i in STATS_BTN.size():
		if (STATS_BTN[i] as Rect2).has_point(d):
			return "stats:%d" % i
	return ""


## Design-space rect of a held target, for the press flash.
func _press_rect(name: String) -> Rect2:
	if name == "continue":
		return CONTINUE
	if name.begins_with("stats:"):
		return STATS_BTN[int(name.substr(6))]
	return Rect2()


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

	# STADIUM panel: the ground name + all five row values under the baked labels.
	_draw_stadium()
	# MAN OF THE MATCH (full time only) — the selector's pick, with his mugshot.
	if not _half:
		_draw_motm()

	if _press != "":
		var pr := _press_rect(_press)
		if pr.size.x > 0:
			draw_rect(pr, C_PRESS, true)


func _draw_goals(rows: Array, col: Vector2) -> void:
	for i in mini(rows.size(), N_ROWS):
		var y: int = ROW_Y0 + ROW_PITCH * i
		var r: Dictionary = rows[i]
		_txt(_f8, int(col.x) + 6, y, str(r.get("scorer", "")), C_CELL_TXT, 11, false, int(col.y) - 34)
		_txt(_f8, int(col.y) - 28, y, str(r.get("minute", 0)), C_CELL_TXT, 11)


## The five stadium rows. Only the VALUES are drawn — every label and chevron is the
## original frame's own pixels in result_ft.png. Row grammar read straight off the two
## witnessed boards: "15,200 spectators" / "12,160 spect." + "80 %" in the right cell /
## "£91,200" / "86 %" in the right cell / "£18,750".
func _draw_stadium() -> void:
	if _stadium.is_empty():
		return
	var gname := str(_stadium.get("name", ""))
	if gname != "":
		# The ground-name row is WHITE with BLACK ink (witnessed OT/Villa/Dell/Reebok);
		# the five rows below are white-on-colour.
		_txt(_f8, STAD_NAME.x, STAD_NAME.y, gname, C_STAD_NAME, 11, false, 285)
	var cap := int(_stadium.get("capacity", 0))
	var att := int(_stadium.get("attendance", 0))
	if cap > 0:
		_txt(_f8, STAD_VAL_X, STAD_Y["cap"], "%s spectators" % _grp(cap), C_STAD_TXT, 11)
	if att > 0:
		_txt(_f8, STAD_ATT_X, STAD_Y["att"], "%s spect." % _grp(att), C_STAD_TXT, 11)
		if cap > 0:
			_txt(_f8, STAD_PCT_X, STAD_Y["att"],
				"%d %%" % int(round(100.0 * att / cap)), C_STAD_TXT, 11)
	if _stadium.has("gate"):
		_txt(_f8, STAD_MONEY_X, STAD_Y["attmoney"],
			"£%s" % _grp(int(_stadium["gate"])), C_STAD_TXT, 11)
	if _stadium.has("boards_pct"):
		_txt(_f8, STAD_PCT_X, STAD_Y["boards"],
			"%d %%" % int(_stadium["boards_pct"]), C_STAD_TXT, 11)
	if _stadium.has("boards"):
		_txt(_f8, STAD_MONEY_X, STAD_Y["sponsor"],
			"£%s" % _grp(int(_stadium["boards"])), C_STAD_TXT, 11)


## MAN OF THE MATCH: the 32x32 mugshot in the panel's photo cell and
## "Name (Club)" centred on the blue band (both frame-measured). An unpicked match
## (no per-player record) leaves the band empty, exactly as the bake rests.
func _draw_motm() -> void:
	if _motm.is_empty():
		return
	var face := PMChrome.mini_face(_motm.get("photo_id"))
	if face != null:
		draw_texture_rect(face, Rect2(MOTM_PHOTO.x, MOTM_PHOTO.y, 32, 32), false)
	var nm := str(_motm.get("name", ""))
	if nm == "":
		return
	var club := str(_motm.get("club", ""))
	var line := "%s (%s)" % [PMChrome.title_case_name(nm), club] if club != "" \
		else PMChrome.title_case_name(nm)
	# The band's face is ProMan10, not the panel's ProMan8: the witnessed
	# "Holdsworth (Bolton W)" measures 159px of ink, and only proman10's advances
	# (154) come near it — proman8 gives 129, which is what the first pass drew.
	if _f10 == null:
		return
	var sz := 10                       # proman10's NATIVE size (no rescale)
	while _f10.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > 210.0 and sz > 8:
		sz -= 1
	var w := _f10.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(_f10, int(MOTM_NAME_CX - w * 0.5), MOTM_NAME_Y, line, C_MOTM, sz)


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
