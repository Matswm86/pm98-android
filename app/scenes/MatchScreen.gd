extends Control
class_name MatchScreen
## PM98 2D MATCH VIEW (the iconic DATSIM) — real DATSIM sprites driven by the
## reverse-engineered match engine.
##
## The match SCORELINE + minute-by-minute event stream come straight from
## MatchCommentary.timeline()/narrate() over MatchEngine (the per-shot model lifted
## from MANAGER.EXE; docs/re/match_engine_re.md). This scene is the VISUAL: a 3/4
## broadcast pitch with the real JUG.PGF player sprites + BALON ball + COFLECHA
## selection arrow (cracked + exported by tools/re/{pgf_decode,export_match_art}.py;
## format in docs/re/match_view_re.md), animated to the event timeline.
##
## The whole on-pitch LAYOUT is a PURE FUNCTION of the match minute: the ball
## interpolates an event-keyframe path, the 22 players hold a 4-4-2 shape that
## shifts with the ball, the carrier seeks it. That keeps the view deterministic
## (a screenshot / headless test at minute M is reproducible) while _process only
## advances the clock. HONEST SCOPE: this is a faithful broadcast reconstruction,
## not a 1:1 port of the original 3/4 tile-scroll camera (documented as the next
## refinement in docs/re/match_view_re.md, same approach as the STADIUM pre-render).

signal back_pressed

const W := 640
const H := 480

# --- pitch geometry (3/4 broadcast trapezoid: length L->R, width far/top->near/bottom)
const FAR_Y := 116.0          # far touchline (top of pitch)
const NEAR_Y := 470.0         # near touchline (bottom)
const FAR_HALF := 196.0       # half pitch-width at the far line
const NEAR_HALF := 300.0      # half pitch-width at the near line
const CENTER_X := 320.0
const FAR_SCALE := 0.62       # sprite scale at far line
const NEAR_SCALE := 1.18      # sprite scale at near line
const TEAM_SHIFT := 0.34      # how far the block slides with the ball along length
const SPRITE_W := 26          # player cell in the exported atlas
const SPRITE_H := 52
const DIRS := 8
const ANIM_ROWS := 3

# Direction column -> facing angle (deg, 0=right/east, +y down). Tuned to the JUG
# group-of-8 layout (col widths 20,16,12,12,12,16,20,20 => sides wide, front/back narrow).
const DIR_ANGLE := [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]

const KIT_SRC := Rect2(0, 0, 31, 64)   # shirt half of the 48x64 MINIESC kit (scoreboard escudos)

const C_SKY_TOP := Color(0.30, 0.52, 0.86)
const C_SKY_BOT := Color(0.46, 0.66, 0.92)
const C_GRASS_A := Color(0.18, 0.52, 0.20)
const C_GRASS_B := Color(0.16, 0.46, 0.18)
const C_LINE := Color(0.92, 0.96, 0.92, 0.85)
const C_TITLE := Color(0.98, 0.99, 1.0)
const C_DIM := Color(0.62, 0.72, 0.85)
const C_HOME := Color(1.0, 0.83, 0.30)
const C_GOLD := Color(1.0, 0.87, 0.0)
const C_BTN := Color(0.16, 0.43, 0.27)
const C_BTN_HI := Color(0.27, 0.59, 0.39)
const BACK_BTN := Rect2(523, 448, 112, 26)

const MIN_PER_SEC := 3.6      # match minutes per real second (~25s for a 90' match)

# Scroll camera (T1 #4): the original DATSIM is a horizontally-scrolling 3/4 view that
# follows the ball, not a fixed whole-pitch shot. The camera shows the length window
# _cam_l ± VIEW_HALF (both touchlines always visible), zoomed to fill the screen width,
# and pans _cam_l to track the ball - clamped so it never scrolls past either goal.
const VIEW_HALF := 0.34
var _cam_l := 0.5             # camera length-focus; a PURE function of the minute (see _cam_at)

var _bar: Texture2D
var _sky_tex: Texture2D
var _pbase: Texture2D       # true-colour skin/boots/detail
var _pkit: Texture2D        # kit-luma layer, tinted per club at draw time
var _ball: Texture2D
var _arrow: Texture2D
var _col_home := Color(0.85, 0.18, 0.18)   # fallback kits (overridden from the club crest/kit art)
var _col_away := Color(0.18, 0.30, 0.85)
var _home_id := -1
var _away_id := -1
var _home_kit: Texture2D       # each side's kit (escudo), flanking the scoreboard score
var _away_kit: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font

var _home := "HOME"
var _away := "AWAY"
var _hg := 0
var _ag := 0
var _lines: Array = []         # [{minute, side, text, goal?}]
var _keys: Array = []          # ball keyframes [{m, l, w, goal, side}]
var _slots: Array = []         # 22 formation slots [{side, l, w}]

var _minute := 0.0
var _prev_minute := 0.0     # for firing event SFX on the frame the clock crosses them
var _final_done := false
var _playing := true
var _press_back := false
# AudioManager autoload by node path (the bare global identifier doesn't resolve when this
# screen is loaded under a --script test, so we look it up; null-guarded everywhere).
var _am: Node


func _ready() -> void:
	_bar = load("res://art/screens/barra0.png")
	_pbase = load("res://art/match/player_base.png")
	_pkit = load("res://art/match/player_kit.png")
	_ball = load("res://art/match/ball.png")
	_arrow = load("res://art/match/arrow.png")
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


## Feed a finished fixture. lines = MatchCommentary timeline lines. home_id/away_id are
## club ids used to pull each side's REAL kit colour from its kit art (res://art/kits/<id>.png);
## pass -1 to keep the red/blue fallback.
func setup(home_name: String, away_name: String, hg: int, ag: int, lines: Array,
		home_id: int = -1, away_id: int = -1) -> void:
	_home = home_name
	_away = away_name
	_hg = hg
	_ag = ag
	_lines = lines
	_home_id = home_id
	_away_id = away_id
	_col_home = _kit_colour(home_id, true, _col_home)    # left half = home shirt
	_col_away = _kit_colour(away_id, false, _col_away)   # right half = away shirt
	_home_kit = _kit_tex(home_id)
	_away_kit = _kit_tex(away_id)
	# keep the two sides telling apart: if the kits are too close, contrast the away one
	if _col_dist(_col_home, _col_away) < 0.32:
		_col_away = Color(0.93, 0.93, 0.96) if _col_home.get_luminance() < 0.5 else Color(0.10, 0.12, 0.30)
	_build_keyframes()
	_build_formation()
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


## SFX for a commentary line, or "" if it has none. Goals roar; cards draw the crowd.
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


func _col_dist(a: Color, b: Color) -> float:
	return sqrt(pow(a.r - b.r, 2.0) + pow(a.g - b.g, 2.0) + pow(a.b - b.b, 2.0))


## The club's kit art (res://art/kits/<id>.png), or null when no art exists for the id.
func _kit_tex(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	var path := "res://art/kits/%d.png" % club_id
	return load(path) if ResourceLoader.exists(path) else null


## Dominant saturated colour of a club kit (one half of res://art/kits/<id>.png), brightened
## for use as a modulate over the kit-luma layer. Returns `fallback` if no kit art / no
## saturated colour (e.g. an all-white kit keeps the light fallback so it reads as white).
func _kit_colour(club_id: int, home_half: bool, fallback: Color) -> Color:
	if club_id < 0:
		return fallback
	var path := "res://art/kits/%d.png" % club_id
	if not ResourceLoader.exists(path):
		return fallback
	var tex: Texture2D = load(path)
	var img := tex.get_image() if tex != null else null
	if img == null:
		return fallback
	var w := img.get_width()
	var h := img.get_height()
	var x0 := 0 if home_half else w / 2
	var x1 := w / 2 if home_half else w
	var buckets := {}        # quantized rgb -> [weight, r_sum, g_sum, b_sum]
	for y in range(int(h * 0.15), int(h * 0.75)):     # torso band
		for x in range(x0, x1):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var mx: float = max(c.r, max(c.g, c.b))
			var mn: float = min(c.r, min(c.g, c.b))
			if mx < 0.25 or (mx - mn) < 0.22:        # skip near-white/gray/black
				continue
			var key := Vector3i(int(c.r * 5), int(c.g * 5), int(c.b * 5))
			var b: Array = buckets.get(key, [0.0, 0.0, 0.0, 0.0])
			b[0] += 1.0
			b[1] += c.r
			b[2] += c.g
			b[3] += c.b
			buckets[key] = b
	if buckets.is_empty():
		return fallback
	var best: Array = [0.0, 0.0, 0.0, 0.0]
	for b in buckets.values():
		if b[0] > best[0]:
			best = b
	var col := Color(best[1] / best[0], best[2] / best[0], best[3] / best[0])
	# brighten so the modulate gives a vivid kit (the kit-luma layer supplies the shading)
	var hsv_v: float = max(col.r, max(col.g, col.b))
	if hsv_v > 0.0:
		col = Color(col.r / hsv_v, col.g / hsv_v, col.b / hsv_v).lerp(col, 0.35)
	return col


## Jump the clock (screenshot / test hook). Layout is a pure function of the minute.
func seek(minute: float) -> void:
	_minute = clampf(minute, 0.0, 90.0)
	queue_redraw()


# ---- timeline -> ball keyframes ------------------------------------------

func _build_keyframes() -> void:
	_keys = [{"m": 0.0, "l": 0.5, "w": 0.5, "goal": false, "side": -1}]
	for ln in _lines:
		var side: int = int(ln.get("side", -1))
		var mn := float(ln.get("minute", 0))
		if side == -1:
			_keys.append({"m": mn, "l": 0.5, "w": 0.5, "goal": false, "side": -1})
			continue
		var attacking_right := side == 0          # home attacks right (l=1)
		var is_goal: bool = ln.get("goal") == true
		var l: float
		var w := 0.5
		if is_goal:
			l = 0.95 if attacking_right else 0.05
		elif ln.get("text", "").begins_with("Corner"):
			l = 0.90 if attacking_right else 0.10
			w = 0.12 if (mn as int) % 2 == 0 else 0.88
		else:
			l = 0.70 if attacking_right else 0.30
			w = 0.36 + 0.28 * float((mn as int) % 2)
		_keys.append({"m": mn, "l": l, "w": w, "goal": is_goal, "side": side})
		if is_goal:    # after a goal, restart from the centre spot
			_keys.append({"m": mn + 1.0, "l": 0.5, "w": 0.5, "goal": false, "side": -1})
	_keys.sort_custom(func(a, b): return a["m"] < b["m"])


## Ball pitch-position at a minute (pure: interpolate the keyframe path).
func _ball_at(minute: float) -> Dictionary:
	if _keys.is_empty():
		return {"l": 0.5, "w": 0.5, "goal_in": false}
	var prev: Dictionary = _keys[0]
	for k in _keys:
		if k["m"] > minute:
			var span: float = maxf(0.001, k["m"] - prev["m"])
			var t: float = clampf((minute - prev["m"]) / span, 0.0, 1.0)
			# ease toward goals so the ball "drives" in
			var te: float = t * t * (3.0 - 2.0 * t)
			return {
				"l": lerpf(prev["l"], k["l"], te),
				"w": lerpf(prev["w"], k["w"], te),
				"goal_in": k["goal"] and t > 0.85,
			}
		prev = k
	return {"l": prev["l"], "w": prev["w"], "goal_in": false}


# ---- formation -----------------------------------------------------------

func _build_formation() -> void:
	_slots = []
	# 4-4-2 in pitch-space; home attacks right (l grows), away mirrored.
	var rows := [
		[0.06, [0.5]],                      # GK
		[0.24, [0.16, 0.38, 0.62, 0.84]],   # back four
		[0.44, [0.16, 0.38, 0.62, 0.84]],   # midfield four
		[0.64, [0.36, 0.64]],               # front two
	]
	for side in 2:
		for r in rows:
			var base_l: float = r[0]
			for w in r[1]:
				var l: float = base_l if side == 0 else 1.0 - base_l
				_slots.append({"side": side, "l": l, "w": w})


## Player screen layout at a minute (pure). Returns array of
## {side, x, y, scale, dir, anim, carrier} sorted far->near for painting.
func _players_at(minute: float, ball: Dictionary) -> Array:
	var out: Array = []
	_cam_l = _cam_at(ball)   # camera tracks the ball before any _project below
	# Whole block slides toward the ball's end of the pitch (both teams compact
	# around the play); the attack DIRECTION (dir_sign) only sets facing, not the slide.
	var ball_shift: float = (ball["l"] - 0.5) * TEAM_SHIFT
	# possession: side whose half the ball is driving into
	var poss := 0 if ball["l"] >= 0.5 else 1
	# carrier = the possessing side's slot nearest the ball
	var carrier_idx := -1
	var best := 9.0
	for i in _slots.size():
		var s: Dictionary = _slots[i]
		if int(s["side"]) != poss:
			continue
		var d: float = absf((s["l"] + ball_shift) - ball["l"]) + absf(s["w"] - ball["w"])
		if d < best:
			best = d
			carrier_idx = i
	for i in _slots.size():
		var s: Dictionary = _slots[i]
		var side := int(s["side"])
		var dir_sign := 1.0 if side == 0 else -1.0
		var l: float = s["l"] + ball_shift
		var w: float = s["w"]
		# liveliness wobble (pure in minute)
		var ph := float(i) * 1.7
		l += 0.012 * sin(minute * 0.8 + ph)
		w += 0.02 * sin(minute * 0.9 + ph * 1.3)
		var carrier := i == carrier_idx
		if carrier:
			l = lerpf(l, ball["l"] - 0.02 * dir_sign, 0.8)
			w = lerpf(w, ball["w"], 0.8)
		l = clampf(l, 0.02, 0.98)
		w = clampf(w, 0.04, 0.98)
		var p := _project(l, w)
		# facing: carrier toward goal, others toward ball
		var face_to: Dictionary
		if carrier:
			face_to = _project(0.98 if side == 0 else 0.02, 0.5)
		else:
			face_to = _project(ball["l"], ball["w"])
		var ang := rad_to_deg(atan2(face_to["y"] - p["y"], face_to["x"] - p["x"]))
		out.append({
			"side": side, "x": p["x"], "y": p["y"], "scale": p["s"],
			"dir": _dir_col(ang),
			"anim": (int(minute * 4.0) + i) % ANIM_ROWS if not carrier else (int(minute * 6.0) + i) % ANIM_ROWS,
			"carrier": carrier,
		})
	out.sort_custom(func(a, b): return a["y"] < b["y"])
	return out


func _project(l: float, w: float) -> Dictionary:
	var y: float = lerpf(FAR_Y, NEAR_Y, w)
	var half: float = lerpf(FAR_HALF, NEAR_HALF, w)
	# Length is windowed around the camera focus: l == _cam_l ± VIEW_HALF maps to the
	# trapezoid edges, so the visible window fills the screen and pans with _cam_l.
	var x: float = CENTER_X + (l - _cam_l) / VIEW_HALF * half
	var s: float = lerpf(FAR_SCALE, NEAR_SCALE, w)
	return {"x": x, "y": y, "s": s}


## Camera length-focus for a ball position: follows the ball, clamped so the view never
## pans past either goal (the goal line then sits at the screen edge). Pure in the minute,
## because _ball_at(minute) is — so seek()/tests stay reproducible.
func _cam_at(ball: Dictionary) -> float:
	return clampf(ball.get("l", 0.5), VIEW_HALF, 1.0 - VIEW_HALF)


func _dir_col(angle_deg: float) -> int:
	var best := 0
	var bd := 999.0
	for c in DIRS:
		var d: float = absf(_wrap180(angle_deg - DIR_ANGLE[c]))
		if d < bd:
			bd = d
			best = c
	return best


func _wrap180(a: float) -> float:
	while a > 180.0:
		a -= 360.0
	while a < -180.0:
		a += 360.0
	return a


# ---- live state ----------------------------------------------------------

func _process(delta: float) -> void:
	if _playing and _minute < 90.0:
		_minute = minf(90.0, _minute + delta * MIN_PER_SEC)
		# fire SFX for any event the clock just crossed (normal play only)
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


## Score shown at the current minute (count goals already played).
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


## Latest commentary line at/below the current minute.
func _ticker_at(minute: float) -> String:
	var txt := "KICK OFF"
	for ln in _lines:
		if float(ln.get("minute", 0)) <= minute:
			txt = str(ln.get("text", txt))
	return txt


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		var d := _to_design(e.position)
		if e.pressed:
			_press_back = BACK_BTN.has_point(d)
		else:
			if _press_back and BACK_BTN.has_point(d):
				back_pressed.emit()
			elif not BACK_BTN.has_point(d):
				# tap pitch: skip to full time, then pause on the result
				if _minute < 90.0:
					_minute = 90.0
					_prev_minute = 90.0   # don't replay skipped goals/cards in one frame
					if not _final_done:
						if _am:
							_am.sfx("whistle_final")
						_final_done = true
				_playing = not _playing
				queue_redraw()
			_press_back = false


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	# marble-ish bezel behind the 640x480 content (landscape side margins)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.10, 0.07), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	var ball := _ball_at(_minute)
	_cam_l = _cam_at(ball)   # set the camera before the pitch markings project through it
	_draw_pitch()
	if not _slots.is_empty():
		for p in _players_at(_minute, ball):
			_draw_player(p)
		_draw_ball(ball)
	_draw_scoreboard(ball)


func _draw_pitch() -> void:
	# sky band under the scoreboard
	draw_rect(Rect2(0, 28, W, FAR_Y - 28), C_SKY_TOP, true)
	# Base grass: the full pitch-width trapezoid, always filling the screen (its width edges
	# are camera-independent; only the length scrolls).
	draw_colored_polygon(PackedVector2Array([
		Vector2(CENTER_X - FAR_HALF, FAR_Y), Vector2(CENTER_X + FAR_HALF, FAR_Y),
		Vector2(CENTER_X + NEAR_HALF, NEAR_Y), Vector2(CENTER_X - NEAR_HALF, NEAR_Y)]), C_GRASS_B)
	# Mowing stripes ALONG the length, projected through the camera so they scroll with it
	# (the visible cue that the camera is panning to follow the ball).
	var stripes := 16
	for i in range(0, stripes, 2):
		var a0 := _project(float(i) / stripes, 0.0)
		var a1 := _project(float(i + 1) / stripes, 0.0)
		var b1 := _project(float(i + 1) / stripes, 1.0)
		var b0 := _project(float(i) / stripes, 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(a0["x"], a0["y"]), Vector2(a1["x"], a1["y"]),
			Vector2(b1["x"], b1["y"]), Vector2(b0["x"], b0["y"])]), C_GRASS_A)
	_draw_markings()


func _draw_markings() -> void:
	# touchlines + goal lines (the trapezoid border)
	var tl := _project(0.0, 0.0)
	var tr := _project(1.0, 0.0)
	var nl := _project(0.0, 1.0)
	var nr := _project(1.0, 1.0)
	var corners := [Vector2(tl["x"], tl["y"]), Vector2(tr["x"], tr["y"]),
		Vector2(nr["x"], nr["y"]), Vector2(nl["x"], nl["y"])]
	for i in 4:
		draw_line(corners[i], corners[(i + 1) % 4], C_LINE, 2.0)
	# halfway line + centre circle
	var c0 := _project(0.5, 0.0)
	var c1 := _project(0.5, 1.0)
	draw_line(Vector2(c0["x"], c0["y"]), Vector2(c1["x"], c1["y"]), C_LINE, 2.0)
	# centre-circle horizontal radius tracks the length zoom (vertical radius is width, unzoomed)
	_draw_ellipse(_project(0.5, 0.5), 54.0 * (0.5 / VIEW_HALF), 26.0, C_LINE)
	# penalty boxes + goals at each end
	for end in [0.0, 1.0]:
		var bl: float = 0.16 if end == 0.0 else 0.84
		var b0 := _project(minf(end, bl), 0.22)
		var b1 := _project(maxf(end, bl), 0.22)
		var b2 := _project(maxf(end, bl), 0.78)
		var b3 := _project(minf(end, bl), 0.78)
		var box := [Vector2(b0["x"], b0["y"]), Vector2(b1["x"], b1["y"]),
			Vector2(b2["x"], b2["y"]), Vector2(b3["x"], b3["y"])]
		for i in 4:
			draw_line(box[i], box[(i + 1) % 4], C_LINE, 1.5)
		_draw_goal(end)


func _draw_goal(end: float) -> void:
	# simple white goal frame at the goal line, depth-scaled, slightly behind the line
	var post_top := _project(end, 0.40)
	var post_bot := _project(end, 0.60)
	var s: float = post_top["s"]
	var gh := 26.0 * s
	var lean := (1.0 if end == 0.0 else -1.0) * 8.0 * s
	var p_tl := Vector2(post_top["x"], post_top["y"] - gh)
	var p_bl := Vector2(post_top["x"], post_top["y"])
	var p_tr := Vector2(post_bot["x"], post_bot["y"] - gh)
	var p_br := Vector2(post_bot["x"], post_bot["y"])
	# net (faint) + posts + crossbar + back frame
	draw_colored_polygon(PackedVector2Array([
		p_tl, Vector2(p_tl.x + lean, p_tl.y - 3), Vector2(p_tr.x + lean, p_tr.y - 3), p_tr]),
		Color(1, 1, 1, 0.10))
	for nx in range(1, 5):
		var f := nx / 5.0
		draw_line(p_bl.lerp(p_br, f), p_bl.lerp(p_br, f) + Vector2(lean, -gh - 3), Color(1, 1, 1, 0.18), 1.0)
	draw_line(p_tl, p_bl, Color.WHITE, 2.0)
	draw_line(p_tr, p_br, Color.WHITE, 2.0)
	draw_line(p_tl, p_tr, Color.WHITE, 2.0)


func _draw_ellipse(c: Dictionary, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(Vector2(c["x"] + cos(a) * rx, c["y"] + sin(a) * ry))
	for i in 32:
		draw_line(pts[i], pts[i + 1], col, 1.5)


func _draw_player(p: Dictionary) -> void:
	if _pbase == null or _pkit == null:
		return
	var sc: float = p["scale"]
	var dw := SPRITE_W * sc
	var dh := SPRITE_H * sc
	var src := Rect2(int(p["dir"]) * SPRITE_W, int(p["anim"]) * SPRITE_H, SPRITE_W, SPRITE_H)
	var dst := Rect2(p["x"] - dw * 0.5, p["y"] - dh, dw, dh)
	# soft contact shadow
	draw_colored_polygon(_ellipse_poly(Vector2(p["x"], p["y"]), 7 * sc, 3 * sc),
		Color(0, 0, 0, 0.28))
	# base (skin/boots/detail) then the kit-luma layer tinted to the club's real colour
	draw_texture_rect_region(_pbase, dst, src)
	draw_texture_rect_region(_pkit, dst, src, _col_home if p["side"] == 0 else _col_away)
	if p.get("carrier") and _arrow != null:
		var aw := 13.0 * sc
		var fi := (int(_minute * 8.0)) % 8
		draw_texture_rect_region(_arrow, Rect2(p["x"] - aw * 0.5, p["y"] - dh - aw - 2, aw, aw),
			Rect2(fi * 28, 0, 28, 25))


func _ellipse_poly(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw_ball(ball: Dictionary) -> void:
	if _ball == null:
		return
	var p := _project(ball["l"], ball["w"])
	var sc: float = p["s"]
	var bs := 11.0 * sc
	draw_colored_polygon(_ellipse_poly(Vector2(p["x"], p["y"] + 1), bs * 0.5, bs * 0.25),
		Color(0, 0, 0, 0.30))
	draw_texture_rect(_ball, Rect2(p["x"] - bs * 0.5, p["y"] - bs, bs, bs), false)
	if ball.get("goal_in"):
		_txt(_f14, int(p["x"]) - 26, int(p["y"]) - 60, "GOAL!", C_GOLD, 18)


## A small kit (shirt crop) at the BARRA top, aspect-fitted into a 22x32 box at x.
func _draw_kit(tex: Texture2D, x: float) -> void:
	if tex == null:
		return
	var s: float = min(22.0 / KIT_SRC.size.x, 32.0 / KIT_SRC.size.y)
	draw_texture_rect_region(tex,
		Rect2(x + (22.0 - KIT_SRC.size.x * s) * 0.5, 4, KIT_SRC.size.x * s, KIT_SRC.size.y * s), KIT_SRC)


func _draw_scoreboard(ball: Dictionary) -> void:
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)
	var sc := _score_at(_minute)
	var clock := "%2d'" % int(_minute) if _minute < 90.0 else "FT"
	_txt(_f14, 14, 6, _home.substr(0, 16), C_HOME, 15)
	_txt(_f14, W - 14, 6, _away.substr(0, 16), C_HOME, 15, true)
	# dark pill behind the score+clock so they stay legible over the BARRA ball/pitch emblem
	var pill := Rect2(CENTER_X - 44, 3, 88, 42)
	draw_rect(pill, Color(0.04, 0.07, 0.12, 0.82), true)
	draw_rect(Rect2(pill.position, Vector2(pill.size.x, 1)), Color(0.5, 0.6, 0.75, 0.6), true)
	# each club's kit (escudo) flanking the score pill
	_draw_kit(_home_kit, pill.position.x - 26)
	_draw_kit(_away_kit, pill.end.x + 4)
	var score := "%d : %d" % [sc.x, sc.y]
	_txt(_f14, 0, 6, score, C_TITLE, 18, false, W)
	_txt(_f10, 0, 30, clock, C_GOLD, 12, false, W)
	# commentary ticker just under the bar
	_txt(_f12, 0, int(_bar.get_height()) if _bar != null else 44, _ticker_at(_minute), C_DIM, 12, false, W)
	# RETURN
	_cell(BACK_BTN, C_BTN, C_BTN_HI, Color(0.05, 0.10, 0.07))
	_txt(_f12, int(BACK_BTN.position.x), int(BACK_BTN.position.y) + 6, "RETURN",
		Color(0.92, 1.0, 0.94), 13, false, int(BACK_BTN.size.x))


func _cell(r: Rect2, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), lo, true)


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
