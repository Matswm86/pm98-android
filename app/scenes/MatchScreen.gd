extends Control
class_name MatchScreen
## PM98 MATCH SCREEN — the real Premier Manager 98 "watch a match" view: a results /
## commentary screen, NOT a sprite pitch. Reproduced from the original (see the real
## screenshots + the reversed strings in docs/re/match_view_re.md): a digital clock +
## half indicator, the two clubs' shirts + score, a POSSESSION PERCENTAGE bar, the
## minute-by-minute EVENTS table (MIN | COMMENT), and REPLAY / CONTINUE / EXIT buttons,
## over the blue stadium background (RECURSOS FONDO9.BMP).
##
## The whole view is a PURE FUNCTION of the match minute over the MatchCommentary
## timeline (the per-shot model lifted from MANAGER.EXE; docs/re/match_engine_re.md):
## the EVENTS list is the timeline up to the clock, the score counts goals passed, the
## possession bar is the share of events per side. _process just advances the clock;
## seek()/the headless test drive the minute, so a screenshot at minute M is reproducible.
##
## The original's premium 3D "highlights" (Actua-engine .p3d models) are CD-only data not
## present in the game archive, so REPLAY is out of scope — this is the 2D + text mode.

signal back_pressed

const W := 640
const H := 480

const MIN_PER_SEC := 3.6      # match minutes per real second (~25s for a 90' match)
const VIS_ROWS := 12          # EVENTS rows visible in the panel

# layout (640x480 design space, matched to the original screenshot)
const CLOCK_BOX := Rect2(276, 6, 88, 34)
const HOME_SCORE_BOX := Rect2(252, 72, 44, 40)
const AWAY_SCORE_BOX := Rect2(344, 72, 44, 40)
const POSS_BAR := Rect2(150, 170, 340, 18)
const EVENTS_PANEL := Rect2(150, 224, 340, 208)
const REPLAY_BTN := Rect2(14, 449, 118, 26)
const CONT_BTN := Rect2(261, 449, 118, 26)
const EXIT_BTN := Rect2(508, 449, 118, 26)

const C_TITLE := Color(0.98, 0.99, 1.0)
const C_GOLD := Color(1.0, 0.86, 0.20)
const C_NAME := Color(1.0, 1.0, 1.0)
const C_LCD := Color(0.78, 0.86, 0.78)
const C_LCD_BG := Color(0.06, 0.10, 0.08, 0.92)
const C_PANEL := Color(0.86, 0.90, 0.96, 0.96)   # EVENTS table body
const C_PANEL_HDR := Color(0.12, 0.18, 0.34, 0.96)
const C_ROW_HI := Color(0.20, 0.34, 0.66)        # latest event row
const C_TXT := Color(0.10, 0.12, 0.18)
const C_POSS_H := Color(0.78, 0.12, 0.12)        # home possession (red)
const C_POSS_A := Color(0.16, 0.56, 0.20)        # away possession (green)
const C_BOX := Color(0.06, 0.12, 0.30, 0.92)
const C_BOX_BD := Color(0.46, 0.60, 0.92)
const C_BTN := Color(0.10, 0.16, 0.34, 0.92)
const C_BTN_HI := Color(0.30, 0.42, 0.72)
const C_BTN_LO := Color(0.03, 0.06, 0.16)

const KIT_SRC := Rect2(0, 0, 31, 64)   # shirt half of the 48x64 MINIESC escudo

var _bg: Texture2D
var _home_kit: Texture2D
var _away_kit: Texture2D
var _f18: Font
var _f14: Font
var _f12: Font
var _f10: Font

var _home := "HOME"
var _away := "AWAY"
var _hg := 0
var _ag := 0
var _home_id := -1
var _away_id := -1
var _lines: Array = []         # [{minute, side, text, goal?}]
var _poss_home := 50           # home possession % at full time (for the kick-off baseline)

var _minute := 0.0
var _prev_minute := 0.0        # for firing event SFX on the frame the clock crosses them
var _final_done := false
var _playing := true
var _press: int = -1           # which button is being pressed (0 replay/1 cont/2 exit)
# AudioManager autoload looked up by path (the bare global doesn't resolve under --script).
var _am: Node


func _ready() -> void:
	_bg = load("res://art/screens/match_bg.png")
	_f18 = load("res://art/fonts/proman18.fnt") if ResourceLoader.exists("res://art/fonts/proman18.fnt") else load("res://art/fonts/proman14.fnt")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	_am = get_node_or_null(^"/root/AudioManager")
	set_process(true)
	queue_redraw()


## Feed a finished fixture. lines = MatchCommentary timeline lines. home_id/away_id pull
## each club's shirt escudo (res://art/kits/<id>.png); pass -1 for none.
func setup(home_name: String, away_name: String, hg: int, ag: int, lines: Array,
		home_id: int = -1, away_id: int = -1) -> void:
	_home = home_name
	_away = away_name
	_hg = hg
	_ag = ag
	_lines = lines
	_home_id = home_id
	_away_id = away_id
	_home_kit = _kit_tex(home_id)
	_away_kit = _kit_tex(away_id)
	_poss_home = _possession_home()
	_minute = 0.0
	_prev_minute = 0.0
	_final_done = false
	_playing = true
	# Match audio: the menu theme yields to the crowd bed, kick-off whistle blows.
	if _am == null:
		_am = get_node_or_null(^"/root/AudioManager")
	if _am:
		_am.stop_music()
		_am.play_crowd()
		_am.sfx("whistle")
	queue_redraw()


## Jump the clock to a minute (tests / screenshots). Pure: no SFX replay.
func seek(minute: float) -> void:
	_minute = clampf(minute, 0.0, 90.0)
	_prev_minute = _minute
	_final_done = _minute >= 90.0
	queue_redraw()


# ---- data (all pure functions of the minute) -----------------------------

## Score shown at a minute (goals already played).
func _score_at(minute: float) -> Vector2i:
	var h := 0
	var a := 0
	for ln in _lines:
		if ln.get("goal") == true and float(ln.get("minute", 0)) <= minute:
			if int(ln["side"]) == 0:
				h += 1
			else:
				a += 1
	return Vector2i(h, a)


## Full-match home possession %, from the share of side-attributed events (default 50).
func _possession_home() -> int:
	var h := 0
	var tot := 0
	for ln in _lines:
		var s := int(ln.get("side", -1))
		if s == 0 or s == 1:
			tot += 1
			if s == 0:
				h += 1
	if tot == 0:
		return 50
	return clampi(int(round(100.0 * h / tot)), 12, 88)


## Possession at a minute eases from 50/50 at kick-off toward the full-match split.
func _possession_at(minute: float) -> int:
	var t := clampf(minute / 90.0, 0.0, 1.0)
	return int(round(lerpf(50.0, float(_poss_home), t)))


## EVENTS rows to show at a minute: the timeline up to the clock (newest last).
func _events_upto(minute: float) -> Array:
	var out: Array = []
	for ln in _lines:
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
	return "FIRST HALF"


# ---- club shirt art ------------------------------------------------------

func _kit_tex(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	var path := "res://art/kits/%d.png" % club_id
	return load(path) if ResourceLoader.exists(path) else null


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


# ---- clock ---------------------------------------------------------------

func _process(delta: float) -> void:
	if _playing and _minute < 90.0:
		_minute = minf(90.0, _minute + delta * MIN_PER_SEC)
		for ln in _lines:
			var m := float(ln.get("minute", 0))
			if m > _prev_minute and m <= _minute:
				var key := _line_sfx(ln)
				if key != "" and _am:
					_am.sfx(key)
		_prev_minute = _minute
		if _minute >= 90.0 and not _final_done:
			if _am:
				_am.sfx("whistle_final")
			_final_done = true
		queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _btn_at(d)
	else:
		var rel := _btn_at(d)
		if rel != -1 and rel == _press:
			match rel:
				0:   # REPLAY: rerun the clock from kick-off (no 3D engine; this re-watches text)
					_minute = 0.0
					_prev_minute = 0.0
					_final_done = false
					_playing = true
				1, 2:   # CONTINUE / EXIT: leave the match
					back_pressed.emit()
		elif rel == -1 and _press == -1:
			# tap the body: skip to full time and pause on the result
			if _minute < 90.0:
				_minute = 90.0
				_prev_minute = 90.0
				if not _final_done and _am:
					_am.sfx("whistle_final")
				_final_done = true
		_press = -1
	queue_redraw()


func _btn_at(d: Vector2) -> int:
	if REPLAY_BTN.has_point(d):
		return 0
	if CONT_BTN.has_point(d):
		return 1
	if EXIT_BTN.has_point(d):
		return 2
	return -1


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	# marble-ish bezel behind the 640x480 content (landscape side margins)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.16, 0.40), true)
	# darken slightly so the white panels + text pop, like the original
	draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.06, 0.18, 0.28), true)

	_draw_clock()
	_draw_scoreline()
	_draw_possession()
	_draw_events()
	_draw_buttons()


func _draw_clock() -> void:
	draw_rect(CLOCK_BOX, C_LCD_BG, true)
	draw_rect(CLOCK_BOX, Color(0.5, 0.6, 0.7, 0.5), false, 1.0)
	var clock := "%02d:00" % int(_minute) if _minute < 90.0 else "90:00"
	_txt(_f18, int(CLOCK_BOX.position.x), int(CLOCK_BOX.position.y) + 6, clock, C_LCD, 18, false, int(CLOCK_BOX.size.x))
	_txt(_f12, 0, int(CLOCK_BOX.end.y) + 3, _half_label(_minute), C_GOLD, 12, false, W)


func _draw_scoreline() -> void:
	var sc := _score_at(_minute)
	# shirts flanking the centre
	_draw_shirt(_home_kit, 40, 70)
	_draw_shirt(_away_kit, W - 40 - 40, 70)
	# names
	_txt(_f14, 92, 82, _home.substr(0, 16), C_NAME, 16)
	_txt(_f14, W - 92, 82, _away.substr(0, 16), C_NAME, 16, true)
	# score boxes
	for box in [HOME_SCORE_BOX, AWAY_SCORE_BOX]:
		draw_rect(box, C_BOX, true)
		draw_rect(box, C_BOX_BD, false, 2.0)
	_txt(_f18, int(HOME_SCORE_BOX.position.x), int(HOME_SCORE_BOX.position.y) + 9, str(sc.x), C_TITLE, 20, false, int(HOME_SCORE_BOX.size.x))
	_txt(_f18, int(AWAY_SCORE_BOX.position.x), int(AWAY_SCORE_BOX.position.y) + 9, str(sc.y), C_TITLE, 20, false, int(AWAY_SCORE_BOX.size.x))


func _draw_shirt(tex: Texture2D, x: float, y: float) -> void:
	if tex == null:
		draw_rect(Rect2(x + 6, y, 28, 40), Color(0.7, 0.7, 0.75, 0.8), true)
		return
	var sc: float = min(40.0 / KIT_SRC.size.x, 44.0 / KIT_SRC.size.y)
	draw_texture_rect_region(tex, Rect2(x + (40.0 - KIT_SRC.size.x * sc) * 0.5, y, KIT_SRC.size.x * sc, KIT_SRC.size.y * sc), KIT_SRC)


func _draw_possession() -> void:
	_txt(_f12, 0, 150, "POSSESSION PERCENTAGE", C_TITLE, 12, false, W)
	var ph := _possession_at(_minute)
	var split: float = POSS_BAR.size.x * ph / 100.0
	draw_rect(Rect2(POSS_BAR.position, Vector2(split, POSS_BAR.size.y)), C_POSS_H, true)
	draw_rect(Rect2(POSS_BAR.position.x + split, POSS_BAR.position.y, POSS_BAR.size.x - split, POSS_BAR.size.y), C_POSS_A, true)
	draw_rect(POSS_BAR, Color(0.85, 0.9, 0.95, 0.6), false, 1.0)
	_txt(_f12, int(POSS_BAR.position.x) - 52, int(POSS_BAR.position.y) + 2, "%d%%" % ph, C_TITLE, 13, true)
	_txt(_f12, int(POSS_BAR.end.x) + 8, int(POSS_BAR.position.y) + 2, "%d%%" % (100 - ph), C_TITLE, 13)


func _draw_events() -> void:
	# "EVENTS" title (centered above the table, like the original)
	_txt(_f14, 0, int(EVENTS_PANEL.position.y) - 34, "EVENTS", C_TITLE, 14, false, W)
	# header
	var hdr := Rect2(EVENTS_PANEL.position.x, EVENTS_PANEL.position.y - 16, EVENTS_PANEL.size.x, 16)
	draw_rect(hdr, C_PANEL_HDR, true)
	_txt(_f10, int(hdr.position.x) + 6, int(hdr.position.y) + 3, "MIN", C_TITLE, 11)
	_txt(_f10, int(hdr.position.x) + 44, int(hdr.position.y) + 3, "COMMENT", C_TITLE, 11)
	# body
	draw_rect(EVENTS_PANEL, C_PANEL, true)
	draw_rect(EVENTS_PANEL, Color(0.3, 0.4, 0.6, 0.7), false, 1.0)
	var rows := _events_upto(_minute)
	var start: int = maxi(0, rows.size() - VIS_ROWS)
	var rh := EVENTS_PANEL.size.y / VIS_ROWS
	for i in range(start, rows.size()):
		var ln: Dictionary = rows[i]
		var yy: float = EVENTS_PANEL.position.y + (i - start) * rh
		var latest := i == rows.size() - 1
		if latest:
			draw_rect(Rect2(EVENTS_PANEL.position.x, yy, EVENTS_PANEL.size.x, rh), C_ROW_HI, true)
		var col: Color = C_TITLE if latest else C_TXT
		var side := int(ln.get("side", -1))
		var mins := "" if side < 0 else "%d" % int(ln.get("minute", 0))
		if mins != "":
			_txt(_f10, int(EVENTS_PANEL.position.x) + 8, int(yy) + 2, mins, col, 11)
		_txt(_f10, int(EVENTS_PANEL.position.x) + 44, int(yy) + 2, str(ln.get("text", "")).substr(0, 44), col, 11)


func _draw_buttons() -> void:
	_button(REPLAY_BTN, 0, "REPLAY", Color(1.0, 0.5, 0.5))
	_button(CONT_BTN, 1, "CONTINUE", Color(0.85, 1.0, 0.9))
	_button(EXIT_BTN, 2, "EXIT", C_GOLD)


func _button(r: Rect2, idx: int, label: String, fg: Color) -> void:
	var base: Color = C_BTN_HI if _press == idx else C_BTN
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), C_BTN_HI, true)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), C_BTN_LO, true)
	draw_rect(r, Color(0.5, 0.6, 0.8, 0.5), false, 1.0)
	_txt(_f12, int(r.position.x), int(r.position.y) + 6, label, fg, 13, false, int(r.size.x))


func _txt(f: Font, x: int, y_top: int, t: String, col: Color, sz: int, right := false, cw := 0) -> void:
	if f == null:
		return
	var wd := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if right:
		px = x - wd
	elif cw > 0:
		px = x + (cw - wd) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
