extends Control
class_name MatchSimulador
## PM98 WATCH — the 2D GRAFICO / SIMULADOR pitch (PC-Futbol-5.0 sprite simulator that
## Premier Manager 98 reskins). Reached from the reversed MATCH OPTIONS picker's WATCH
## button (docs/re/match_view_re.md, FUN_004e2630). This is build-plan step 3.
##
## SOURCE FIDELITY (honest, same convention as MatchScreen's vectorial pitch):
##   * Player / ball / arrow sprites are the REAL DATSIM.PKF art, decoded by
##     tools/re/pgf_decode.py and baked by tools/re/export_match_art.py into
##     app/art/match/{player_base,player_kit,ball,arrow}.png. JUG.PGF gives 8 compass
##     facings x 3 run frames per 26x52 cell; the kit layer is a luma sheet the view
##     tints per club at runtime (modulate x club colour) — exactly what the exporter
##     split it for. BALON.RAW -> ball.png, COFLECHA.PGF -> arrow.png (active marker).
##   * The pitch surface + markings are drawn vectorially. The original's exact
##     PCF5DAT 3/4 tile-scroll camera and its per-tick positional stream are NOT in the
##     reversed source we hold (PCF5DAT.PKF positional playback was not cracked), so
##     player/ball motion is INTERPOLATED from the same MatchCommentary event timeline
##     the BRIEF view uses. That keeps both views in lock-step: identical clock, score,
##     possession and events — only the presentation differs. This is the documented
##     faithful substitute, not invented match data.
##
## The whole view is a pure function of the match minute over that timeline; _process
## only advances the clock, seek() drives the minute for tests / screenshots.

signal back_pressed                # EXIT — leave the match
signal brief_pressed               # BRIEF — drop back to the commentary view

const W := 640
const H := 480
const MIN_PER_SEC := 3.6           # match minutes per real second (matches MatchScreen)

# Side-on stadium bands (640x480 design space). The pitch is the grass band; home attacks
# RIGHT, away attacks LEFT — the original PC-Futbol simulador's side camera. Every band is
# filled with REAL DATSIM art (sky CIELO1, crowd + board + grass HIERPREM); the band layout
# is the app's choice because PCF5DAT's exact tile-scroll camera was not reversed.
const SKY := Rect2(0, 0, 640, 64)
const CROWD := Rect2(0, 46, 640, 40)
const BOARD := Rect2(0, 86, 640, 22)
const PITCH := Rect2(20, 108, 600, 308)     # grass play area (ny=0 far, ny=1 near)
const GOAL_DEPTH := 0.30                     # goal mouth half-height as a fraction of depth

# Buttons (bottom bar)
const BRIEF_BTN := Rect2(14, 449, 150, 26)
const CONT_BTN := Rect2(245, 449, 150, 26)
const EXIT_BTN := Rect2(476, 449, 150, 26)

# Formation in side-on field coords: nx in [0,1] own-goal->far-goal, ny in [0,1] far->near.
# Home defends the LEFT (nx~0) and attacks RIGHT; away mirrors (nx -> 1-nx). GK,4 DEF,4 MID,2 FWD.
const HOME_FORM := [
	Vector2(0.05, 0.50),
	Vector2(0.18, 0.20), Vector2(0.20, 0.42), Vector2(0.20, 0.60), Vector2(0.18, 0.82),
	Vector2(0.37, 0.22), Vector2(0.39, 0.44), Vector2(0.39, 0.62), Vector2(0.37, 0.82),
	Vector2(0.50, 0.38), Vector2(0.50, 0.64),
]

const C_BG := Color(0.04, 0.06, 0.12)
const C_LCD := Color(0.82, 0.90, 0.82)
const C_LCD_BG := Color(0.05, 0.09, 0.07, 0.94)
const C_GOLD := Color(1.0, 0.86, 0.20)
const C_TITLE := Color(0.98, 0.99, 1.0)
const C_BTN := Color(0.10, 0.16, 0.34, 0.94)
const C_BTN_HI := Color(0.30, 0.42, 0.72)
const C_BTN_LO := Color(0.03, 0.06, 0.16)
const C_HOME_DEF := Color(0.86, 0.20, 0.20)    # fallback kit tints if no escudo colour
const C_AWAY_DEF := Color(0.24, 0.42, 0.86)

const CELL_W := 26
const CELL_H := 52
const SPR_SC := 0.62               # on-pitch sprite scale

var _base: Texture2D
var _kit: Texture2D
var _ball: Texture2D
var _arrow: Texture2D
var _sky: Texture2D
var _grass: Texture2D
var _crowd: Texture2D
var _board: Texture2D
var _net: Texture2D
var _f18: Font
var _f12: Font
var _f10: Font

var _home := "HOME"
var _away := "AWAY"
var _lines: Array = []             # MatchCommentary timeline [{minute, side, text, goal?}]
var _home_col := C_HOME_DEF
var _away_col := C_AWAY_DEF
var _poss_home := 50

var _minute := 0.0
var _t := 0.0                      # free-running time for liveliness (not score-bearing)
var _playing := true
var _press := -1
# remembered facing per player so an idle sprite doesn't snap to frame 0
var _home_face := PackedInt32Array()
var _away_face := PackedInt32Array()
var _home_prev: Array = []
var _away_prev: Array = []


func _ready() -> void:
	_base = _tex("res://art/match/player_base.png")
	_kit = _tex("res://art/match/player_kit.png")
	_ball = _tex("res://art/match/ball.png")
	_arrow = _tex("res://art/match/arrow.png")
	_sky = _tex("res://art/match/sky.png")
	_grass = _tex("res://art/match/grass.png")
	_crowd = _tex("res://art/match/crowd.png")
	_board = _tex("res://art/match/board_pm98.png")
	_net = _tex("res://art/match/goal_net.png")
	_f18 = _font("res://art/fonts/proman18.fnt", "res://art/fonts/proman14.fnt")
	_f12 = _font("res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt")
	_f10 = _font("res://art/fonts/proman10.fnt", "res://art/fonts/proman12.fnt")
	_home_face.resize(11)
	_away_face.resize(11)
	_home_prev.resize(11)
	_away_prev.resize(11)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	set_process(true)
	queue_redraw()


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

func _font(path: String, fallback: String) -> Font:
	return load(path) if ResourceLoader.exists(path) else load(fallback)


## Feed a finished fixture: same args as MatchScreen.setup so both views share data.
func setup(home_name: String, away_name: String, _hg: int, _ag: int, lines: Array,
		home_id: int = -1, away_id: int = -1) -> void:
	_home = home_name
	_away = away_name
	_lines = lines
	_home_col = _club_colour(home_id, C_HOME_DEF)
	_away_col = _club_colour(away_id, C_AWAY_DEF)
	# Keep the two teams visually distinct even when both escudos read similar.
	if _col_dist(_home_col, _away_col) < 0.30:
		_away_col = C_AWAY_DEF if _col_dist(_home_col, C_AWAY_DEF) > 0.30 else C_HOME_DEF
	_poss_home = _possession_home()
	_minute = 0.0
	_t = 0.0
	_playing = true
	queue_redraw()


## Jump the clock (tests / screenshots). Pure.
func seek(minute: float) -> void:
	_minute = clampf(minute, 0.0, 90.0)
	queue_redraw()


# ---- data: identical pure functions to MatchScreen, so the views agree -----

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


func _possession_at(minute: float) -> int:
	var t := clampf(minute / 90.0, 0.0, 1.0)
	return int(round(lerpf(50.0, float(_poss_home), t)))


func _half_label(minute: float) -> String:
	if minute >= 90.0:
		return "FULL TIME"
	if minute >= 46.0:
		return "SECOND HALF"
	if minute >= 45.0:
		return "HALF TIME"
	return "FIRST HALF"


## Side in possession at this minute = the most recent side-attributed event <= minute.
## -1 (loose / kick-off) until the first event. Drives which way the ball flows.
func _attacking_side(minute: float) -> int:
	var side := -1
	for ln in _lines:
		var s := int(ln.get("side", -1))
		if s >= 0 and float(ln.get("minute", 0)) <= minute:
			side = s
		elif float(ln.get("minute", 0)) > minute:
			break
	return side


## Minutes-distance to the nearest goal event (for the shot-on-goal lunge + net flash).
func _goal_pulse(minute: float) -> Dictionary:
	var best := 99.0
	var side := -1
	for ln in _lines:
		if ln.get("goal") == true:
			var d: float = absf(float(ln.get("minute", 0)) - minute)
			if d < best:
				best = d
				side = int(ln["side"])
	return {"dist": best, "side": side}


# ---- club colour from the real escudo -------------------------------------

## RGB euclidean distance (Color has no distance_to).
func _col_dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _club_colour(club_id: int, fallback: Color) -> Color:
	if club_id < 0:
		return fallback
	var path := "res://art/kits/%d.png" % club_id
	if not ResourceLoader.exists(path):
		return fallback
	var tex: Texture2D = load(path)
	if tex == null:
		return fallback
	var img := tex.get_image()
	if img == null:
		return fallback
	# Sample the shirt half (left 0..23 of the 48-wide escudo); pick the most saturated,
	# reasonably-bright pixel as the team colour.
	var best := fallback
	var best_sat := -1.0
	var w: int = mini(24, img.get_width())
	var h: int = img.get_height()
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var mx: float = maxf(c.r, maxf(c.g, c.b))
			var mn: float = minf(c.r, minf(c.g, c.b))
			var sat := mx - mn
			if mx > 0.22 and sat > best_sat:
				best_sat = sat
				best = Color(c.r, c.g, c.b)
	# Too washed-out (white/grey shirt) -> keep the legible fallback.
	return best if best_sat > 0.12 else fallback


# ---- clock -----------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	if _playing and _minute < 90.0:
		_minute = minf(90.0, _minute + delta * MIN_PER_SEC)
	queue_redraw()


# ---- input -----------------------------------------------------------------

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
				0: brief_pressed.emit()
				1:    # CONTINUE: run to full time and hold on the result
					_minute = 90.0
				2: back_pressed.emit()
		_press = -1
	queue_redraw()


func _btn_at(d: Vector2) -> int:
	if BRIEF_BTN.has_point(d):
		return 0
	if CONT_BTN.has_point(d):
		return 1
	if EXIT_BTN.has_point(d):
		return 2
	return -1


# ---- field <-> screen ------------------------------------------------------

func _field(nx: float, ny: float) -> Vector2:
	return Vector2(PITCH.position.x + clampf(nx, 0.0, 1.0) * PITCH.size.x,
		PITCH.position.y + clampf(ny, 0.0, 1.0) * PITCH.size.y)


## Ball position in SCREEN coords at the current minute (deterministic-ish flow).
func _ball_field() -> Vector2:
	var atk := _attacking_side(_minute)
	# home (0) attacks the RIGHT goal (nx~0.80), away (1) the LEFT (nx~0.20)
	var tx := 0.5
	if atk == 0:
		tx = 0.80
	elif atk == 1:
		tx = 0.20
	# weave up/down the channel; gentle, not score-bearing
	var nx := tx + sin(_t * 1.3) * 0.10
	var ny := 0.5 + sin(_t * 1.7 + _minute * 0.6) * 0.32
	# shot on goal: drive into the mouth as the clock meets a goal minute
	var gp := _goal_pulse(_minute)
	if gp["side"] != -1 and float(gp["dist"]) < 0.8:
		var k := 1.0 - float(gp["dist"]) / 0.8
		var goal_x := 0.96 if int(gp["side"]) == 0 else 0.04
		nx = lerpf(nx, goal_x, k)
		ny = lerpf(ny, 0.5, k)
	return _field(clampf(nx, 0.04, 0.96), clampf(ny, 0.04, 0.96))


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_BG, true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	_draw_pitch()
	var ball := _ball_field()
	_draw_teams(ball)
	_draw_ball(ball)
	_draw_hud()
	_draw_buttons()


## The side-on stadium, composed entirely from REAL DATSIM tiles (sky / crowd / board /
## grass) plus the real goal net. Only the band layout is the app's choice.
func _draw_pitch() -> void:
	if _sky != null:
		draw_texture_rect(_sky, SKY, false)
	else:
		draw_rect(SKY, Color(0.45, 0.62, 0.85), true)
	_tile(_crowd, CROWD)
	_tile(_board, BOARD)
	_tile(_grass, PITCH)
	# subtle far-touchline shade where the grass meets the boards
	draw_rect(Rect2(PITCH.position.x, PITCH.position.y, PITCH.size.x, 2), Color(0, 0, 0, 0.22), true)
	_draw_goals()


## Fill `r` by repeating `tex` from its top-left (clips the last row/column).
func _tile(tex: Texture2D, r: Rect2) -> void:
	if tex == null:
		draw_rect(r, Color(0.12, 0.40, 0.18), true)
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var y := r.position.y
	while y < r.end.y:
		var h: float = minf(th, r.end.y - y)
		var x := r.position.x
		while x < r.end.x:
			var w: float = minf(tw, r.end.x - x)
			draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(0, 0, w, h))
			x += tw
		y += th


func _draw_goals() -> void:
	var top := _field(0.0, 0.5 - GOAL_DEPTH).y
	var bot := _field(0.0, 0.5 + GOAL_DEPTH).y
	_goal_at(PITCH.position.x - 14.0, top, 14.0, bot - top, true)    # left goal
	_goal_at(PITCH.end.x, top, 14.0, bot - top, false)               # right goal


func _goal_at(x: float, y: float, w: float, h: float, left: bool) -> void:
	if _net != null:
		draw_texture_rect(_net, Rect2(x, y, w, h), false)
	else:
		draw_rect(Rect2(x, y, w, h), Color(0.8, 0.84, 0.88, 0.5), true)
	# white frame (crossbar + the upright on the goal-line side)
	draw_rect(Rect2(x, y - 1, w, 2), Color(0.96, 0.98, 1.0), true)
	draw_rect(Rect2(x, y + h - 1, w, 2), Color(0.96, 0.98, 1.0), true)
	var post_x: float = x + w - 2.0 if left else x
	draw_rect(Rect2(post_x, y - 1, 2, h + 2), Color(0.97, 0.99, 1.0), true)


func _draw_teams(ball: Vector2) -> void:
	var atk := _attacking_side(_minute)
	# nearest home + away outfielder to the ball gets the active arrow
	var near_home := _draw_side(0, HOME_FORM, _home_col, ball, atk == 0)
	var near_away := _draw_side(1, _mirror(HOME_FORM), _away_col, ball, atk == 1)
	if atk == 0 and near_home != Vector2.ZERO:
		_draw_arrow(near_home)
	elif atk == 1 and near_away != Vector2.ZERO:
		_draw_arrow(near_away)


## Mirror the home formation to the away half (ny -> 1-ny).
func _mirror(form: Array) -> Array:
	var out: Array = []
	for p in form:
		out.append(Vector2((p as Vector2).x, 1.0 - (p as Vector2).y))
	return out


## Draw one team; returns the screen pos of the outfielder nearest the ball (or ZERO).
func _draw_side(side: int, form: Array, col: Color, ball: Vector2, has_ball: bool) -> Vector2:
	var faces: PackedInt32Array = _home_face if side == 0 else _away_face
	var prev: Array = _home_prev if side == 0 else _away_prev
	var ball_n := Vector2((ball.x - PITCH.position.x) / PITCH.size.x,
		(ball.y - PITCH.position.y) / PITCH.size.y)
	# resolve every player's screen pos once, tracking the nearest outfielder to the ball
	var poss: Array = []
	var nearest_i := -1
	var nearest_d := 1e9
	for i in form.size():
		var base: Vector2 = form[i]
		var follow := 0.0 if i == 0 else 0.30          # GK holds its line
		var nx := base.x + (ball_n.x - 0.5) * (follow * 0.7) + sin(_t * 1.3 + i) * 0.012
		var ny := base.y + (ball_n.y - 0.5) * follow
		var pos := _field(nx, ny)
		poss.append(pos)
		if i != 0:
			var d := pos.distance_to(ball)
			if d < nearest_d:
				nearest_d = d
				nearest_i = i
	# the possessing team's nearest man steps onto the ball
	if has_ball and nearest_i >= 0:
		poss[nearest_i] = (poss[nearest_i] as Vector2).lerp(ball, 0.55)
	# resolve facing + remember it, then draw back-to-front (far players first)
	for i in poss.size():
		faces[i] = _facing(prev[i], poss[i])
		prev[i] = poss[i]
	var order := range(poss.size())
	order.sort_custom(func(a, b): return (poss[a] as Vector2).y < (poss[b] as Vector2).y)
	for i in order:
		_draw_player(poss[i], col, faces[i], _run_phase())
	return poss[nearest_i] if nearest_i >= 0 else Vector2.ZERO


func _run_phase() -> int:
	# run-cycle frame off the clock so legs animate while play flows
	return int(_t * 6.0) % 3


## 8-compass facing from movement vector (down = 0). Falls back to last facing if still.
func _facing(prev_pos, pos: Vector2) -> int:
	if not (prev_pos is Vector2):
		return 0
	var v: Vector2 = pos - (prev_pos as Vector2)
	if v.length() < 0.4:
		return 0
	var ang := atan2(v.x, v.y)            # 0 == +y (down)
	return int(round(ang / (PI / 4.0))) & 7


func _draw_player(pos: Vector2, col: Color, face: int, row: int) -> void:
	face = clampi(face, 0, 7)
	row = clampi(row, 0, 2)
	var src := Rect2(face * CELL_W, row * CELL_H, CELL_W, CELL_H)
	# mild perspective: nearer (lower on screen) players are a touch larger
	var depth := clampf((pos.y - PITCH.position.y) / PITCH.size.y, 0.0, 1.0)
	var dsc := SPR_SC * lerpf(0.82, 1.10, depth)
	var dw := CELL_W * dsc
	var dh := CELL_H * dsc
	var dst := Rect2(pos.x - dw * 0.5, pos.y - dh, dw, dh)   # feet at pos
	# soft contact shadow
	draw_circle(Vector2(pos.x, pos.y - 1), dw * 0.34, Color(0, 0, 0, 0.28))
	if _kit != null:
		draw_texture_rect_region(_kit, dst, src, col)        # tint kit to club colour
	if _base != null:
		draw_texture_rect_region(_base, dst, src, Color.WHITE)
	if _base == null and _kit == null:
		draw_rect(dst, col, true)


func _draw_ball(ball: Vector2) -> void:
	var sc := 0.42
	if _ball != null:
		var bw: float = _ball.get_width() * sc
		var bh: float = _ball.get_height() * sc
		draw_circle(Vector2(ball.x, ball.y + 1), bw * 0.5, Color(0, 0, 0, 0.30))
		draw_texture_rect(_ball, Rect2(ball.x - bw * 0.5, ball.y - bh * 0.5, bw, bh), false)
	else:
		draw_circle(ball, 4, Color.WHITE)
	# net flash at the scoring end on a goal minute (home -> right goal, away -> left)
	var gp := _goal_pulse(_minute)
	if gp["side"] != -1 and float(gp["dist"]) < 0.35:
		var a := (0.35 - float(gp["dist"])) / 0.35
		var top := _field(0.0, 0.5 - GOAL_DEPTH).y
		var bot := _field(0.0, 0.5 + GOAL_DEPTH).y
		var gx: float = PITCH.end.x if int(gp["side"]) == 0 else PITCH.position.x - 14.0
		draw_rect(Rect2(gx, top, 14.0, bot - top), Color(1.0, 0.95, 0.2, a * 0.7), true)


func _draw_arrow(pos: Vector2) -> void:
	if _arrow == null:
		return
	# COFLECHA.PGF is a horizontal strip of frames; use the first, bobbing above the head.
	var fw: int = maxi(1, int(_arrow.get_height()))   # square-ish frames
	var sc := 0.6
	var bob := sin(_t * 6.0) * 1.5
	var dw := fw * sc
	var dh: float = _arrow.get_height() * sc
	var src := Rect2(0, 0, fw, _arrow.get_height())
	draw_texture_rect_region(_arrow, Rect2(pos.x - dw * 0.5, pos.y - CELL_H * SPR_SC - dh + bob, dw, dh), src)


func _draw_hud() -> void:
	var sc := _score_at(_minute)
	# top score/clock strip
	draw_rect(Rect2(0, 0, W, 54), Color(0.05, 0.08, 0.18, 0.92), true)
	_txt(_f12, 40, 10, _home.substr(0, 18), C_TITLE, 14)
	_txt(_f12, W - 40, 10, _away.substr(0, 18), C_TITLE, 14, true)
	# clock pill
	var cb := Rect2(W * 0.5 - 44, 6, 88, 24)
	draw_rect(cb, C_LCD_BG, true)
	draw_rect(cb, Color(0.5, 0.6, 0.7, 0.5), false, 1.0)
	var clock := "%02d:00" % int(_minute) if _minute < 90.0 else "90:00"
	_txt(_f18, int(cb.position.x), int(cb.position.y) + 4, clock, C_LCD, 18, false, int(cb.size.x))
	# score
	_txt(_f18, 0, 30, "%d : %d" % [sc.x, sc.y], C_GOLD, 20, false, W)
	_txt(_f10, 0, 40, _half_label(_minute), C_TITLE, 10, false, W)
	# possession ticks under the bar
	var ph := _possession_at(_minute)
	_txt(_f10, 40, 40, "%d%%" % ph, C_TITLE, 10)
	_txt(_f10, W - 40, 40, "%d%%" % (100 - ph), C_TITLE, 10, true)


func _draw_buttons() -> void:
	_button(BRIEF_BTN, 0, "BRIEF", Color(0.85, 1.0, 0.9))
	_button(CONT_BTN, 1, "CONTINUE", C_TITLE)
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
