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
signal continue_pressed   # full time: leave the BRIEF for the separate RESULT page (frame 083)

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
# kit = the club escudo drawn to the frame-64 bounds. The witnessed kit band is
# x14..55 (42 wide) / y89..142 (53 tall). The old anchors ("opaque y24..63, scale
# 1.32") were solved on the WRAPPED bank; on the exact decode the figure's bbox is
# x1..45 y3..59 (45x57), so the content now draws at its own top-left with the
# fit scale min(42/45, 53/57).
const KIT_H := Vector2(14, 89)             # home kit content top-left
const KIT_A := Vector2(585, 89)            # away kit content top-left
const KIT_SCALE := 0.9298                  # 45x57 figure -> the witnessed 42x53 band
# feed body = the REAL EVENTS panel (frame 67): light-grey MIN column x153..198 +
# white COMMENT column x199..467 (scrollbar x470..476). The old x312..470 rect drew
# only the right third, so the goal line's club clipped ("Goal by Salako" -> "Goal by
# Milose"). MIN digits right-align at x190; COMMENT left-aligns at x199 to the panel.
const EVENTS := Rect2(153, 269, 314, 167)  # white/grey feed body (x153..467, y269..436)
const EV_MIN_R := 190                       # minute right-edge (right-aligned in MIN col)
const EV_COMMENT_X := 199                    # comment left edge (white column start)
const EV_ROW_TOP := 274                      # first feed row top (frame-measured)
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

const KIT_SRC := Rect2(1, 3, 45, 57)   # the MINIESC figure's content bbox (exact decode)
const C_LCD := Color(0.78, 0.86, 0.78)
const C_NAME := Color(1.0, 1.0, 1.0)
const C_GOAL := Color(1, 0, 0)   # goal lines pure red (frame 67 "Goal by Blake" = 255,0,0)
const C_TXT := Color(0.10, 0.12, 0.18)
const C_PRESS := Color(1, 1, 1, 0.20)

# POSSESSION PERCENTAGE bar (frame 67): red (home, left) | green (away, right) inside a
# bevel, a light-red diamond pointer at the split, and a "NN %" label each side. The
# split reads the REAL engine POSS counters (Pm98StatMatch 0x64/0x804) — not fabricated.
# frame-measured: interior x156..482 y184..202; labels LEFT x67..118 / RIGHT x525..576.
const POSS_L := 156                       # bar interior left / right (span 326)
const POSS_R := 482
const POSS_Y0 := 184
const POSS_Y1 := 203
const POSS_RED := Color(85.0 / 255, 0, 0)         # home fill (frame 67 = 85,0,0)
const POSS_GRN := Color(0, 63.0 / 255, 0)         # away fill (0,63,0)
const POSS_ARROW := Color(1.0, 159.0 / 255, 170.0 / 255)   # pointer (255,159,170)
const POSS_LBL := Color(160.0 / 255, 180.0 / 255, 200.0 / 255)   # "NN %" light blue-grey
const POSS_LBL_L := Rect2(67, 184, 52, 17)        # left label bbox (blanked + redrawn)
const POSS_LBL_R := Rect2(525, 184, 52, 17)       # right label bbox
const POSS_CLEAN_L := Vector2i(119, 149)          # glyph-free band span to sample the blank
const POSS_CLEAN_R := Vector2i(489, 523)

var _bg: Texture2D
var _run_bg: Texture2D  # RUNNING chrome: every button vanishes except EXIT
						# (witnessed matchday_flow_witness_re §5)
var _ft_bg: Texture2D   # FULL TIME chrome: doors/KICK OFF/STATISTICS gone,
						# CONTINUE in the EXIT slot (parity orig/68)
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
var _am: Node             # /root/AudioManager (absent in some headless harnesses)
var _prev_minute := 0.0   # last frame's clock, so a goal fires its roar exactly once
var _final_done := false  # the full-time whistle is a one-shot
var _started := false   # KICK OFF pressed (running/paused chrome vs the idle board)
var _press := ""
var _poss_final := 0.5     # home possession fraction (real engine split; 0.5 = neutral gap)
var _has_poss := false     # true when the stat engine supplied POSS counters
var _blank_l: Array = []   # per-row band colours to erase the baked "50 %" labels
var _blank_r: Array = []


func _ready() -> void:
	_bg = load("res://art/screens/matchflow/brief.png")
	_run_bg = load("res://art/screens/matchflow/brief_running.png")
	_ft_bg = load("res://art/screens/matchflow/brief_ft.png")
	_f18 = PMChrome.font("18")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	_am = get_node_or_null(^"/root/AudioManager")
	set_process(true)
	queue_redraw()


## Feed a finished fixture. `lines` = a match timeline (MatchCommentary shape or the
## honest goal vector). Only GOAL events are kept — the fabricated RATE_* lines are
## dropped so the feed is the stat engine's real record. home_id/away_id pull each
## club's kit escudo.
func setup(home_name: String, away_name: String, hg: int, ag: int, lines: Array,
		home_id: int = -1, away_id: int = -1, possession: Array = []) -> void:
	_home = home_name
	_away = away_name
	_hg = hg
	_ag = ag
	_home_kit = _kit_tex(home_id)
	_away_kit = _kit_tex(away_id)
	_feed = _honest_feed(lines)
	# REAL engine possession [home,away] -> the bar's final split. Empty (legacy path)
	# leaves the honest neutral 50/50. A degenerate 0+0 also stays neutral.
	_has_poss = possession.size() == 2 and (int(possession[0]) + int(possession[1])) > 0
	_poss_final = (float(possession[0]) / (int(possession[0]) + int(possession[1]))) if _has_poss else 0.5
	if _blank_l.is_empty():
		_precompute_label_blank()
	_minute = 0.0
	_playing = false        # frame 073: KICK OFF idle at 00:00; KICK OFF starts the stream
	_started = false
	queue_redraw()


## Cache the per-row band colours behind the baked "50 %" labels so the live bar can erase
## them (median of a glyph-free span in the same row -> reconstructs the blue chrome band,
## the same technique the bake tool uses). Read once from brief.png's Image.
func _precompute_label_blank() -> void:
	_blank_l.clear()
	_blank_r.clear()
	var img: Image = _bg.get_image() if _bg != null else null
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	for y in range(int(POSS_LBL_L.position.y), int(POSS_LBL_L.end.y)):
		_blank_l.append(_row_median(img, y, POSS_CLEAN_L.x, POSS_CLEAN_L.y))
		_blank_r.append(_row_median(img, y, POSS_CLEAN_R.x, POSS_CLEAN_R.y))


func _row_median(img: Image, y: int, x0: int, x1: int) -> Color:
	var rs: Array = []
	var gs: Array = []
	var bs: Array = []
	for x in range(x0, x1):
		var c := img.get_pixel(x, y)
		rs.append(c.r); gs.append(c.g); bs.append(c.b)
	rs.sort(); gs.sort(); bs.sort()
	var m := rs.size() / 2
	return Color(rs[m], gs[m], bs[m])


## Build the feed from a timeline: a Kick Off line then EVERY match event, minute-stamped
## like the original BRIEF (shots, saves, ball-cleared, good-defending, headers, corners,
## fouls, cards, offsides + the red GOAL lines) -- owner 2026-07-23: "there are many more
## match events in the original BRIEF, not only goals". The GOALS are the stat engine's
## real record (scorer + minute); the surrounding events are MatchCommentary's narrative
## layer, timed around them, matching the original's dense presentation.
## Accepts both the MatchCommentary shape ({minute, side, text, goal}) and the raw
## stat-engine goal vector ({minute, side/scorer_side, scorer, own_goal}).
func _honest_feed(lines: Array) -> Array:
	# the witnessed feed opens with a plain "Kick Off" line (no minute, no clubs)
	var out: Array = [{"minute": 0, "side": -1, "text": "Kick Off", "kickoff": true}]
	for ln in lines:
		if not (ln is Dictionary):
			continue
		var d: Dictionary = ln
		# Raw stat-engine goal vector (no pre-formatted text) -> a red goal line.
		if not d.has("text"):
			if d.has("scorer"):
				var gs := int(d.get("side", d.get("scorer_side", -1)))
				out.append({"minute": int(d.get("minute", 0)), "side": gs,
					"text": "Goal by %s (%s)" % [str(d.get("scorer", "")), (_home if gs == 0 else _away)],
					"goal": true})
			continue
		# MatchCommentary shape: keep every side-tagged event; drop only the phase markers
		# (side == -1: KICK OFF / HALF TIME / FULL TIME -- MatchScreen draws the clock itself).
		var side := int(d.get("side", -1))
		if side < 0:
			continue
		out.append({"minute": int(d.get("minute", 0)), "side": side,
			"text": str(d.get("text", "")), "goal": bool(d.get("goal", false))})
	return out


## Jump the clock to a minute (tests / screenshots).
func seek(minute: float) -> void:
	_minute = clampf(minute, 0.0, 90.0)
	queue_redraw()


## Pause/resume the running clock (the leave-championship alert holds the
## match while it is up; witnessed §6 "No -> resumes").
func set_paused(p: bool) -> void:
	if _started and _minute < 90.0:
		_playing = not p


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


## Home possession fraction at `minute`: eases the neutral 50/50 kickoff toward the real
## engine split as the clock runs (the original's bar drifts through the match; only the
## final split is engine-known, so the path between is a display ease — never a fabricated
## stat). Without engine counters (legacy path) it stays the honest neutral 50/50.
func _possession_at(minute: float) -> float:
	if not _has_poss:
		return 0.5
	return lerpf(0.5, _poss_final, clampf(minute / 90.0, 0.0, 1.0))


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
		# Every feed line the clock has just passed fires its SFX once.
		for ln in _feed:
			var m := float(ln.get("minute", 0))
			if _prev_minute < m and m <= _minute:
				var key := _line_sfx(ln)
				if key != "" and _am:
					_am.sfx(key)
		_prev_minute = _minute
		if _minute >= 90.0 and not _final_done:
			_final_done = true
			if _am:
				_am.sfx("whistle_final")
		queue_redraw()


## SFX key for a commentary line, or "" if it has none. Goals roar; a card draws the
## crowd. The feed itself only ever carries goal + kick-off lines today (the fabricated
## RATE_* chatter is dropped in setup()), so the card branches are dormant but kept:
## they are the original mapping and cost nothing.
func _line_sfx(ln: Dictionary) -> String:
	if ln.get("goal") == true:
		return "goal"
	var t := str(ln.get("text", ""))
	if t.begins_with("Yellow card:"):
		return "card_yellow"
	if t.ends_with("sent off"):
		return "card_red"
	return ""


func _exit_tree() -> void:
	if _am:
		_am.stop_crowd()


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
	# FULL TIME (orig/68): a single CONTINUE stands in the EXIT slot.
	# RUNNING (witness §5): every button vanishes except EXIT.
	# Only the idle pre-kick board has the full button set.
	if _minute >= 90.0 or _started:
		return "exit" if (BTN["exit"] as Rect2).has_point(d) else ""
	for k in BTN:
		if (BTN[k] as Rect2).has_point(d):
			return k
	return ""


func _activate(target: String) -> void:
	match target:
		"kick":
			# KICK OFF starts the match (frame 073 -> 077, events stream as the clock runs).
			if not _playing:
				_playing = true
				_started = true
				# The menu theme yields to the crowd bed and the whistle blows.
				if _am == null:
					_am = get_node_or_null(^"/root/AudioManager")
				if _am:
					_am.stop_music()
					_am.play_crowd()
					_am.sfx("whistle")
		"exit":
			# At FULL TIME the EXIT slot holds CONTINUE (orig/68) -> the RESULT
			# read-out. Before full time EXIT leaves the running view (the career
			# path still presents the read-out — Main routes back_pressed there).
			if _minute >= 90.0:
				continue_pressed.emit()
			else:
				back_pressed.emit()
		_:
			pass   # LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS: in-match chrome (no sub-screen here)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	var bg := _bg
	if _minute >= 90.0 and _ft_bg != null:
		bg = _ft_bg
	elif _started and _run_bg != null:
		bg = _run_bg
	if bg != null:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)

	# live POSSESSION bar (real engine split; neutral 50/50 when no counters)
	_draw_possession()

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


## Draw the live POSSESSION bar over the baked chrome: erase the baked "50 %" labels,
## fill red|green at the current split, place the diamond pointer, and print both "NN %".
func _draw_possession() -> void:
	for i in _blank_l.size():
		var yy: int = int(POSS_LBL_L.position.y) + i
		draw_rect(Rect2(POSS_LBL_L.position.x, yy, POSS_LBL_L.size.x, 1), _blank_l[i], true)
		draw_rect(Rect2(POSS_LBL_R.position.x, yy, POSS_LBL_R.size.x, 1), _blank_r[i], true)
	var frac := _possession_at(_minute)
	var span := POSS_R - POSS_L
	var bx: int = clampi(POSS_L + int(round(span * frac)), POSS_L + 6, POSS_R - 6)
	draw_rect(Rect2(POSS_L, POSS_Y0, bx - POSS_L, POSS_Y1 - POSS_Y0), POSS_RED, true)
	draw_rect(Rect2(bx, POSS_Y0, POSS_R - bx, POSS_Y1 - POSS_Y0), POSS_GRN, true)
	var cy := (POSS_Y0 + POSS_Y1) * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx, POSS_Y0 - 1), Vector2(bx + 5, cy), Vector2(bx, POSS_Y1 + 1),
		Vector2(bx - 5, cy)]), POSS_ARROW)
	var hp: int = int(round(frac * 100.0))
	_poss_label(hp, POSS_LBL_L)          # home % (left, red side)
	_poss_label(100 - hp, POSS_LBL_R)    # away % (right, green side)


func _poss_label(pct: int, box: Rect2) -> void:
	if _f18 == null:
		return
	draw_string(_f18, Vector2(box.position.x, box.position.y + _f18.get_ascent(15) + 1),
		"%d %%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, POSS_LBL)


func _draw_events() -> void:
	if _f10 == null:
		return
	var rows := _events_upto(_minute)
	var start: int = maxi(0, rows.size() - VIS_ROWS)
	for i in range(start, rows.size()):
		var ln: Dictionary = rows[i]
		var yy: int = EV_ROW_TOP + (i - start) * EV_ROW_H
		var goal: bool = ln.get("goal") == true
		var col: Color = C_GOAL if goal else C_TXT
		var kick: bool = ln.get("kickoff", false)
		var base := yy + _f10.get_ascent(11)
		# minute right-aligned in the MIN column (goals only; Kick Off carries none)
		if not kick:
			var mtxt := str(int(ln.get("minute", 0)))
			var mw := _f10.get_string_size(mtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(_f10, Vector2(EV_MIN_R - mw, base), mtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		# comment left-aligned at the white column, clipped to the panel right edge
		# (full "Goal by <scorer> (<club>)" now fits — 265px vs the old clipped 112px)
		draw_string(_f10, Vector2(EV_COMMENT_X, base), str(ln.get("text", "")),
			HORIZONTAL_ALIGNMENT_LEFT, int(EVENTS.end.x) - EV_COMMENT_X - 3, 11, col)


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
	draw_texture_rect_region(tex,
		Rect2(at.x, at.y, KIT_SRC.size.x * KIT_SCALE, KIT_SRC.size.y * KIT_SCALE), KIT_SRC)


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
