extends Control
class_name MatchScreen
## PM98 BRIEF-mode match — the real Premier Manager 98 running-match read-out
## (walkthrough frame 073_162649): a digital clock + half/state label, the two clubs'
## kits + score, a POSSESSION bar, the minute-stamped EVENTS feed, and the in-match
## LINE-UP / TACTICS / MAN-TO-MAN / STATISTICS controls + KICK OFF + EXIT.
##
## Static chrome is the REAL game's frame 073, baked to art/screens/matchflow/brief.png
## by tools/re/build_match_flow_chrome_from_frames.py with only the dynamic club names +
## the state label cleared. The screen redraws: the clock digit, the half/state label,
## the club kits + names + score, and the EVENTS feed.
##
## EVENT-STREAM HONESTY (docs/re/APP_VS_SPEC_AUDIT.md B3/B4b): the instant-result stat
## engine records ONLY goals (scorer + minute). So the feed shows Kick Off + the REAL
## goal lines and nothing else — the fabricated shots/fouls/cards/corners of the old
## MatchCommentary are DROPPED here (setup() keeps only goal-flagged lines). POSSESSION
## is not produced by the stat engine, so the bar stays the frame's neutral 50/50 (an
## honest gap, never eased toward invented data). Full fidelity needs the positional
## engine's event stream (match_flow_re.md "renderable-today vs gap").

signal back_pressed

const W := 640
const H := 480
const MIN_PER_SEC := 3.6      # match minutes per real second (~25s for a 90' match)

# frame-measured geometry (tools/re/specs/match_flow_chrome_samples.json "brief")
const CLOCK := Rect2(258, 30, 114, 70)     # LCD box (digit overpaint)
const STATE_Y := 68                        # half/state label top
const BAND_Y := Rect2(0, 99, 640, 37)      # black scoreline band
const NAME_H := Vector2(76, 256)           # home name zone (x span)
const NAME_A := Vector2(382, 586)          # away name zone (x span)
const BOX_L := Rect2(258, 100, 62, 32)     # left score box
const BOX_R := Rect2(322, 100, 58, 32)     # right score box
const KIT_H := Vector2(20, 84)             # home kit anchor (escudo top-left)
const KIT_A := Vector2(588, 84)            # away kit anchor
const EVENTS := Rect2(312, 268, 158, 164)  # white feed body
const EV_MIN_X := 316
const EV_COMMENT_X := 356
const EV_ROW_H := 15
const VIS_ROWS := 10

# in-match buttons (x,y,w,h) — LINE-UP/TACTICS/MAN-TO-MAN + two STATISTICS are chrome
# (they open sub-screens not built on this path); KICK OFF advances, EXIT leaves.
const BTN := {
	"lineup": Rect2(495, 227, 133, 33), "tactics": Rect2(495, 283, 133, 33),
	"mtm": Rect2(495, 339, 133, 33), "stats_r": Rect2(495, 393, 133, 30),
	"stats_l": Rect2(14, 393, 133, 30), "kick": Rect2(262, 442, 156, 30),
	"exit": Rect2(508, 442, 120, 30),
}

const KIT_SRC := Rect2(0, 0, 31, 64)   # shirt half of the 48x64 MINIESC escudo
const C_LCD := Color(0.78, 0.86, 0.78)
const C_NAME := Color(1.0, 1.0, 1.0)
const C_GOAL := Color(1.0, 0.60, 0.55)   # goal lines colour-coded (B4b "red/colour-coded")
const C_TXT := Color(0.10, 0.12, 0.18)
const C_PRESS := Color(1, 1, 1, 0.20)

var _bg: Texture2D
var _f18: Font
var _f14: Font
var _f12: Font
var _f10: Font
var _home := "HOME"
var _away := "AWAY"
var _hg := 0
var _ag := 0
var _home_kit: Texture2D
var _away_kit: Texture2D
var _feed: Array = []          # honest feed: [{minute, side, text, goal, kickoff}]
var _minute := 0.0
var _playing := true
var _press := ""


func _ready() -> void:
	_bg = load("res://art/screens/matchflow/brief.png")
	_f18 = PMChrome.font("18")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	set_process(true)
	queue_redraw()


## Feed a finished fixture. `lines` = a match timeline (MatchCommentary shape or the
## honest goal vector). Only GOAL events are kept — the fabricated RATE_* lines are
## dropped so the feed is the stat engine's real record. home_id/away_id pull each
## club's kit escudo.
func setup(home_name: String, away_name: String, hg: int, ag: int, lines: Array,
		home_id: int = -1, away_id: int = -1) -> void:
	_home = home_name
	_away = away_name
	_hg = hg
	_ag = ag
	_home_kit = _kit_tex(home_id)
	_away_kit = _kit_tex(away_id)
	_feed = _honest_feed(lines)
	_minute = 0.0
	_playing = true
	queue_redraw()


## Build the honest feed from a timeline: a Kick Off line + one line per GOAL only.
## Accepts both the MatchCommentary shape ({minute, side, text, goal}) and the raw
## stat-engine goal vector ({minute, side/scorer_side, scorer, own_goal}).
func _honest_feed(lines: Array) -> Array:
	var out: Array = [{"minute": 0, "side": -1, "text": "KICK OFF  -  %s v %s" % [
		_home.to_upper(), _away.to_upper()], "kickoff": true}]
	for ln in lines:
		if not (ln is Dictionary):
			continue
		var d: Dictionary = ln
		var is_goal := bool(d.get("goal", false)) or d.has("scorer")
		if not is_goal:
			continue   # DROP shots/fouls/cards/corners (fabricated; not stat-engine truth)
		var side := int(d.get("side", d.get("scorer_side", -1)))
		var scorer := str(d.get("scorer", ""))
		if scorer == "":   # MatchCommentary shape: "Goal by <name>"
			scorer = str(d.get("text", "")).trim_prefix("Goal by ").strip_edges()
		var club := _home if side == 0 else _away
		out.append({"minute": int(d.get("minute", 0)), "side": side,
			"text": "Goal by %s (%s)" % [scorer, club], "goal": true})
	return out


## Jump the clock to a minute (tests / screenshots).
func seek(minute: float) -> void:
	_minute = clampf(minute, 0.0, 90.0)
	queue_redraw()


# ---- pure functions of the minute ----------------------------------------

func _score_at(minute: float) -> Vector2i:
	var h := 0
	var a := 0
	for ln in _feed:
		if ln.get("goal") == true and float(ln.get("minute", 0)) <= minute:
			if int(ln["side"]) == 0:
				h += 1
			else:
				a += 1
	return Vector2i(h, a)


func _events_upto(minute: float) -> Array:
	var out: Array = []
	for ln in _feed:
		if float(ln.get("minute", 0)) <= minute:
			out.append(ln)
	return out


func _half_label(minute: float) -> String:
	if minute >= 90.0:
		return "FULL TIME"
	if minute >= 46.0:
		return "SECOND HALF"
	if minute >= 45.0:
		return "HALF TIME"
	if minute <= 0.0:
		return "KICK OFF"
	return "FIRST HALF"


func _kit_tex(club_id: int) -> Texture2D:
	return PMChrome.kit(club_id) if club_id >= 0 else null


# ---- clock ---------------------------------------------------------------

func _process(delta: float) -> void:
	if _playing and _minute < 90.0:
		_minute = minf(90.0, _minute + delta * MIN_PER_SEC)
		queue_redraw()


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
	else:
		var rel := _hit(d)
		if rel != "" and rel == _press:
			_activate(rel)
		_press = ""
	queue_redraw()


func _hit(d: Vector2) -> String:
	for k in BTN:
		if (BTN[k] as Rect2).has_point(d):
			return k
	# tapping the feed body skips to full time (watch the whole match at once)
	if EVENTS.has_point(d):
		return "skip"
	return ""


func _activate(target: String) -> void:
	match target:
		"kick":
			if _minute >= 90.0:
				back_pressed.emit()   # CONTINUE at full time
			else:
				_minute = 90.0        # skip to the final result
				_playing = false
		"exit":
			back_pressed.emit()
		"skip":
			_minute = 90.0
			_playing = false
		_:
			pass   # LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS: in-match chrome (no sub-screen here)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)

	# clock digit (over the baked LCD, which we blank first) + half/state label
	draw_rect(Rect2(266, 18, 100, 30), Color(0.10, 0.10, 0.11), true)
	var clock := "%02d:00" % int(_minute) if _minute < 90.0 else "90:00"
	_txt(_f18, 266, 20, clock, C_LCD, 20, true, 100)
	_txt(_f14, 0, STATE_Y, _half_label(_minute), C_NAME, 15, true, W)

	# kits + names + score on the black band (blank the baked score-box digits first)
	_draw_kit(_home_kit, KIT_H)
	_draw_kit(_away_kit, KIT_A)
	_name(int(NAME_H.x), _home.to_upper(), int(NAME_H.y) - int(NAME_H.x), false)
	_name(int(NAME_A.y), _away.to_upper(), int(NAME_A.y) - int(NAME_A.x), true)
	var sc := _score_at(_minute)
	draw_rect(Rect2(BOX_L.position.x + 3, 102, BOX_L.size.x - 6, 30), Color(0, 0, 0.5), true)
	draw_rect(Rect2(BOX_R.position.x + 3, 102, BOX_R.size.x - 6, 30), Color(0, 0, 0.5), true)
	_txt(_f18, int(BOX_L.position.x), 104, str(sc.x), C_NAME, 22, true, int(BOX_L.size.x))
	_txt(_f18, int(BOX_R.position.x), 104, str(sc.y), C_NAME, 22, true, int(BOX_R.size.x))

	_draw_events()

	if _press != "" and BTN.has(_press):
		draw_rect(BTN[_press], C_PRESS, true)


func _draw_events() -> void:
	if _f10 == null:
		return
	var rows := _events_upto(_minute)
	var start: int = maxi(0, rows.size() - VIS_ROWS)
	for i in range(start, rows.size()):
		var ln: Dictionary = rows[i]
		var yy: int = int(EVENTS.position.y) + 2 + (i - start) * EV_ROW_H
		var goal: bool = ln.get("goal") == true
		var col: Color = C_GOAL if goal else C_TXT
		var kick: bool = ln.get("kickoff", false)
		# minute in the MIN column (goals only); comment clipped to the panel width.
		if not kick:
			draw_string(_f10, Vector2(EV_MIN_X, yy + _f10.get_ascent(11)), str(int(ln.get("minute", 0))),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		var cx: int = EV_MIN_X if kick else EV_COMMENT_X
		draw_string(_f10, Vector2(cx, yy + _f10.get_ascent(11)), str(ln.get("text", "")),
			HORIZONTAL_ALIGNMENT_LEFT, int(EVENTS.end.x) - cx - 2, 11, col)


## Draw a club name on the black band, shrunk to fit `maxw`. right=right-align at x.
func _name(x: int, t: String, maxw: int, right: bool) -> void:
	if _f18 == null:
		return
	var sz := 20
	while _f18.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw and sz > 9:
		sz -= 1
	var wd := _f18.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := (x - wd) if right else float(x)
	draw_string(_f18, Vector2(px, 104 + _f18.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, C_NAME)


func _draw_kit(tex: Texture2D, at: Vector2) -> void:
	if tex == null:
		return
	var sc: float = min(40.0 / KIT_SRC.size.x, 48.0 / KIT_SRC.size.y)
	draw_texture_rect_region(tex, Rect2(at.x, at.y, KIT_SRC.size.x * sc, KIT_SRC.size.y * sc), KIT_SRC)


## Draw text. right=centre-in-cw. When `clamp_x` is given the label is auto-shrunk to
## fit; `right_align` right-aligns at x.
func _txt(f: Font, x: int, y_top: int, t: String, col: Color, sz: int, center := false,
		cw := 0, clamp_x := 0, right_align := false) -> void:
	if f == null or t == "":
		return
	var maxw := 0.0
	if clamp_x > 0:
		maxw = float(clamp_x - x)
	elif right_align:
		maxw = float(x - 8)
	if maxw > 0.0:
		while f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw and sz > 7:
			sz -= 1
	var wd := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if center and cw > 0:
		px = x + (cw - wd) * 0.5
	elif right_align:
		px = x - wd
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- letterbox scaling ---------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
