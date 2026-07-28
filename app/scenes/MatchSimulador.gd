extends Control
class_name MatchSimulador
## PM98 WATCH — the 2D GRAFICO / SIMULADOR pitch (PC-Futbol-5.0 sprite simulator that
## Premier Manager 98 reskins). Reached from the reversed MATCH OPTIONS picker's WATCH
## button (docs/re/match_view_re.md, FUN_004e2630). This is build-plan step 3.
##
## REBUILT 2026-07-28 onto the original's own presentation. What changed and why it is now
## defensible (the previous side-on framing is gone — AUDIT A6/A7/A8 are addressed, not
## restated):
##
##   * **3/4 PERSPECTIVE CAMERA, not side-on.** `Pm98Camera` is the binary's own projection
##     (`FUN_005eec60`, focal length = viewport width from `SetCamera`'s `k = width*256*zoom`),
##     with its POSE fitted to a REAL WATCH capture of the running game
##     (`tools/re/refs/watch-2026-07-28/`, fit by `tools/re/fit_watch_camera.py`, vertical
##     residuals ~1e-12 px). The camera looks ACROSS the pitch — depth is world Y, the width
##     axis — which is what the capture shows and what the old side-on view got wrong.
##   * **The JUG bank is indexed the engine's way.** `JugRender` ports `FUN_005a5460`'s
##     `base[kind] + fpd[kind]*dir + phase` over all 74 kinds and 4211 frames, buckets
##     direction on the non-uniform thresholds `DAT_006653e0` (NOT a uniform-45 `atan2`),
##     applies the mode-gated mirror, and takes `kind` / `phase` / `facing` from the live
##     engine's own `player+0x40` / `+0x2c` / `+0x34`. The old `[3 phase x 8 dir]` bake — the
##     transpose of the real layout — and `_facing()` are both deleted.
##   * **The pitch background is not a gap.** `PCF5DAT.PKF` was believed to hold it; it does
##     not. Its ONLY reference in `MANAGER.EXE` (@0x4f82ed) opens it, seeks 0xecbf and reads
##     six bytes `D.G.C.` — a CD-presence check. The simulador's art is DATSIM's own
##     (`campina.raw` @0x59311f, `hierprem.raw` @0x59302c, `cielo1.bmp`, `red.bmp`, `jug.pgf`).
##     See `docs/re/pcf5dat_re.md`.
##   * **MOTION is the original's engine.** A live match runs the byte-exact positional sim
##     (`Pm98LiveMatch`); with no live match the view interpolates the same MatchCommentary
##     timeline the BRIEF view uses, through the same camera, so the two stay in lock-step.
##
## DECLARED (ours, and small): the camera POSE is a FIT, because the eye `camctrl+0x3c` and
## the orientation are not reversed (`Pm98Camera` documents exactly why); the pitch MARKING
## geometry is the laws of the game scaled to the session's own pitch dims, since PM98 stores
## only length and width; the stand/hoarding band above the far touchline is composed from
## DATSIM's own HIERPREM tiles at a measured height. Nothing here is drawn from imagination.
##
## Without a live match the view is a pure function of the match minute over the timeline;
## _process advances the clock, seek() drives the minute for tests / screenshots.

signal back_pressed                # EXIT — leave the match
signal brief_pressed               # BRIEF — drop back to the commentary view

const W := 640
const H := 480
const MIN_PER_SEC := 3.6           # match minutes per real second (matches MatchScreen)

# --- pitch, in METRES about the centre spot ---------------------------------
# Defaults are Old Trafford's, the figures `diag_watch_axes.gd` measured off the engine's own
# `match+0x1820` / `+0x1824`; a live match overrides them with its session's real dims.
const DEF_HALF_LEN := 58.0
const DEF_HALF_WID := 38.0
# Marking geometry — SOURCE-READ 2026-07-28, not declared any more. `FUN_0059a8c0` is the
# simulador's pitch builder and every figure below is one of its literal 16.16 operands
# (`docs/re/pitch_markings_re.md`). It builds them from `matchctx+0x1820` / `+0x1824` (the
# session's own half-length and half-width) and mirrors each end by negation.
#   0x92666 = 9.15   0x108000 = 16.5   0x1428f5 = 20.16   0x58000 = 5.5   0x928f5 = 9.16
#   0xb0000 = 11.0   0x10000 = 1.0     0x1999   = 0.1 (the line width, used for every line)
const CIRCLE_R := 9.15
const PEN_DEPTH := 16.5
const PEN_HALF_W := 20.16
const GOALAREA_DEPTH := 5.5
const GOALAREA_HALF_W := 9.16
const PEN_SPOT := 11.0
const CORNER_R := 1.0
## `0x1999` — the width of every painted line, and the amount the touchlines, goal lines and
## halfway line overrun the corners (`iVar6*2 + 0x3332`, i.e. length + 2 * 0.1).
const LINE_W := 0.1
## `0x2640` of a 0x10000 turn = 53.79 degrees. The D is the arc of the 9.15 m circle about the
## penalty spot between +/- this angle. The port used to DERIVE it as
## `acos((16.5 - 11) / 9.15)` = 53.06 degrees; the binary's own figure is 0.73 degrees wider,
## and the binary is the authority.
const D_HALF_ANGLE := TAU * 0x2640 / 65536.0
## `0x6664` x `0x3332` at `0xaccce` — the penalty and centre spots are 0.4 m x 0.2 m marks,
## not dots, and the penalty one is centred at 10.8 + 0.2 = 11.0 m from the goal line.
const SPOT_W := 0.4
const SPOT_H := 0.2
const GOAL_HALF_W := 3.66
const GOAL_H := 2.44
# Grass, sampled off the original capture (tools/re/refs/watch-2026-07-28/watch_02.png):
# base (41,71,35) with the mown bands running ALONG the depth axis, so their edges are
# constant-X lines — which is exactly how they read in the capture.
const GRASS_A := Color8(41, 71, 35)
const GRASS_B := Color8(38, 64, 34)
const GRASS_LIGHT := Color8(43, 85, 38)
const STRIPE_W := 8.0                        # metres per mown band
const LINE_COL := Color8(214, 218, 214)
# The hoarding + terrace band above the far touchline, in metres of real height.
const BOARD_H := 1.05
const STAND_H := 14.0
## Nothing nearer than this is drawn. The camera is 2 m past the near touchline, so the near
## half of the pitch genuinely runs behind the lens — the binary's own guard is the
## `(d & 0xffffff00) == 0 -> z = -1` clamp in FUN_005eec60.
const NEAR_PLANE := 3.0

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

var _cam := Pm98Camera.new()
## The original's own camera controller, built on the first LIVE frame (see `_drive_camera`).
## Null on the non-live timeline path, which keeps the fitted still pose.
var _cam_ctrl: Pm98CamCtrl = null
var _half_len := DEF_HALF_LEN
var _half_wid := DEF_HALF_WID

## The recolour state, built by `JugKit` from the clubs' own `P96A`/`P96B` ramps.
## `_kits[side]` = the team dictionary; `_squad[side][slot]` = {pattern, skin, hair} for the
## fielded player, empty on the timeline path where no XI exists.
var _pal := PackedColorArray()
var _kits: Array = [{}, {}]
var _squad: Array = [[], []]

var _ball: Texture2D
var _arrow: Texture2D
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
var _home_prev: Array = []
var _away_prev: Array = []
## Per-drawn-player {kind, phase} for the TIMELINE path only. A live match takes all three
## animation inputs off the engine's own player record instead — see `_draw_teams_live`.
var _anim: Array = []
var _anim_acc := 0.0

# ---- LIVE ENGINE (the M5 wire-in) -----------------------------------------
# When `set_live()` has been called this view stops interpolating a finished timeline and
# renders the POSITIONAL engine's own per-frame state: real player and ball coordinates,
# the binary's own clock, and goals as the engine raises them. See Pm98LiveMatch for why
# this is the engine the original uses for a WATCHED match and Pm98StatMatch is the one it
# uses for every other fixture.
var _live: Pm98LiveMatch = null
## Engine frames per second of wall clock. The original steps its match once per display
## frame; this is the port's equivalent rate, and one full match is ~18.5k frames.
const ENGINE_FPS := 60.0
## Never spend more than this many engine frames in one _process call — a slow device
## falls behind in match time rather than dropping the render loop.
const MAX_FRAMES_PER_TICK := 12
var _live_score := Vector2i.ZERO
var _live_feed: Array = []         # goal lines the engine raised, newest last


func _ready() -> void:
	# The engine-layout JUG bank is 8-bit PALETTE INDICES (`jug_index.bin`), exactly as the
	# original keeps it; `JugKit` builds the per-player 256-byte LUT and `JugRender.composite`
	# runs `FUN_005d34a0`'s remap. Nothing about a player is coloured at bake time any more.
	_pal = JugKit.palette(0)
	_ball = _tex("res://art/match/ball.png")
	_arrow = _tex("res://art/match/arrow.png")
	_crowd = _tex("res://art/match/crowd.png")
	_board = _tex("res://art/match/board_pm98.png")
	_net = _tex("res://art/match/goal_net.png")
	_f18 = _font("res://art/fonts/proman18.fnt", "res://art/fonts/proman14.fnt")
	_f12 = _font("res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt")
	_f10 = _font("res://art/fonts/proman10.fnt", "res://art/fonts/proman12.fnt")
	_home_prev.resize(11)
	_away_prev.resize(11)
	_anim.clear()
	for i in 22:
		# kind 3 is the fastest of the four gait tiers (mode 5, 14 phases, self-looping);
		# staggering the phase keeps 22 timeline-path players from marching in lock-step.
		_anim.append({"kind": 3, "phase": i % 14})
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
	_build_kits(home_id, away_id)
	# Keep the two teams visually distinct even when both escudos read similar.
	if _col_dist(_home_col, _away_col) < 0.30:
		_away_col = C_AWAY_DEF if _col_dist(_home_col, C_AWAY_DEF) > 0.30 else C_HOME_DEF
	_poss_home = _possession_home()
	_minute = 0.0
	_t = 0.0
	_playing = true
	queue_redraw()


## Jump the clock (tests / screenshots). Pure. Ignored on a live match — the engine owns
## the clock there and cannot be seeked, exactly as the original's watched match cannot.
func seek(minute: float) -> void:
	if _live != null:
		return
	_minute = clampf(minute, 0.0, 90.0)
	queue_redraw()


## THE M5 WIRE-IN. Hand this view a `Pm98LiveMatch` and it renders that engine instead of
## interpolating a finished timeline: every player and the ball are drawn at the engine's
## own coordinates, the clock is the binary's `(banked + clk) * 0x2d / scale`, and the
## score changes when the engine's event queue raises code 7 / 8.
func set_live(live: Pm98LiveMatch) -> void:
	_live = live
	_lines = []
	_live_feed = []
	_live_score = Vector2i.ZERO
	_minute = 0.0
	_playing = true
	_build_squad_kits()
	queue_redraw()


## The live match, or null when this view is running a finished timeline.
func live_match() -> Pm98LiveMatch:
	return _live


## `FUN_005b63e0`, once per side. The away side wears its CHANGE strip when its own class byte
## equals the home side's — the binary's `param_2 == 1 && matchctx+0x742 == team+0x2c6`, where
## `matchctx+0x742` is literally team 0's `+0x2d6` (`0x46c + 0x2d6 == 0x742`).
##
## The keeper strips follow the same function's re-roll rule; its draw comes from the DISPLAY
## LCG, whose stream this port does not reproduce, so the seed is the fixture's own club ids.
## That divergence is declared here and in `JugKit.keeper_kit`.
func _build_kits(home_id: int, away_id: int) -> void:
	_squad = [[], []]
	if not JugKit.load_tables():
		_kits = [{}, {}]
		return
	var home := JugKit.team_kit(home_id)
	var away := JugKit.team_kit(away_id, int(home.get("cls", -1)) if not home.is_empty() else -1)
	var hk := JugKit.keeper_kit(home_id, int(home.get("cls", -1)) if not home.is_empty() else -1)
	var hcls: Array = []
	if not home.is_empty():
		hcls.append(int(home["cls"]))
	if not hk.is_empty():
		hcls.append(int(hk["cls"]))
	var ak := JugKit.keeper_kit(away_id, int(away.get("cls", -1)) if not away.is_empty() else -1,
		hcls)
	if not home.is_empty():
		home["keeper"] = hk
	if not away.is_empty():
		away["keeper"] = ak
	_kits = [home, away]


## `FUN_005a2830`, once per fielded player: his own copy of the team's shirt pattern with his
## SHIRT NUMBER stamped into it, plus his skin and hair ramps. The three inputs are the lineup
## record's `+0x42` / `+0x2c` / `+0x30`, which are the .DBC's `+0xf8` / `+0x16` / `+0x17`
## carried through verbatim (`Pm98LineupFeeder`).
func _build_squad_kits() -> void:
	_squad = [[], []]
	if _live == null or _live.match_state.is_empty():
		return
	for side in 2:
		var team: Dictionary = (_live.match_state["sim"] as Array)[side]
		var lineup: Dictionary = team[0x9C] if team.get(0x9C) is Dictionary else {}
		var slots: Array = lineup.get("slots", [])
		var kit: Dictionary = _kits[side] if side < _kits.size() else {}
		var rows: Array = []
		for slot in slots.size():
			if not (slots[slot] is Dictionary):
				rows.append({"pattern": PackedByteArray(), "skin": PackedByteArray(),
					"hair": PackedByteArray()})
				continue
			var rec: Dictionary = slots[slot]
			var sh := JugKit.skin_hair(int(rec.get(0x2C, 0)), int(rec.get(0x30, 0)))
			var pat := PackedByteArray()
			if not kit.is_empty():
				pat = JugKit.stamp_number(kit["pattern"], int(rec.get(0x42, slot + 1)),
					int(kit["cls"]), int(kit["ink"]))
			rows.append({"pattern": pat, "skin": sh["skin"], "hair": sh["hair"]})
		_squad[side] = rows


# ---- data: identical pure functions to MatchScreen, so the views agree -----

func _score_at(minute: float) -> Vector2i:
	if _live != null:
		return _live_score
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
	# LIVE: the half comes off the engine's own +0x19a0 counter and full time off its
	# dispatch-10 flag, not off a minute threshold the clock might not land on.
	if _live != null:
		if _live.over:
			return "FULL TIME"
		return "SECOND HALF" if _live.half() == 1 else "FIRST HALF"
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
	# Sample the figure's content bbox (x1..45, y3..59 on the exact-decoded sheet —
	# the old "shirt half x0..23" window was a wrapped-bank artifact); pick the most
	# saturated, reasonably-bright pixel as the team colour.
	var best := fallback
	var best_sat := -1.0
	var w: int = mini(46, img.get_width())
	var h: int = mini(60, img.get_height())
	for y in range(3, h, 2):
		for x in range(1, w, 2):
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
	if _live != null:
		_step_live(delta)
	else:
		if _playing and _minute < 90.0:
			_minute = minf(90.0, _minute + delta * MIN_PER_SEC)
		_step_anim(delta)
	queue_redraw()


## TIMELINE path only: run `FUN_005a50c0`'s own phase advance for each drawn player, so even
## the no-live-match view animates through the real bank rather than a modulo of wall clock.
## A live match never comes here — its `phase` is the engine's own `player+0x2c`.
func _step_anim(delta: float) -> void:
	_anim_acc += delta * JugRender.ANIM_HZ
	var steps: int = mini(int(_anim_acc), 6)
	if steps <= 0:
		return
	_anim_acc -= float(steps)
	for i in _anim.size():
		var st: Dictionary = _anim[i] if _anim[i] is Dictionary else {"kind": 3, "phase": 0}
		for _s in steps:
			st = JugRender.advance(int(st["kind"]), int(st["phase"]))
		_anim[i] = st


## Advance the positional engine by the frames this display frame is worth, then read the
## clock and the score back off it. The cap keeps a slow device from stalling the render
## loop: it falls behind in match time instead, which is visible and honest.
func _step_live(delta: float) -> void:
	if not _playing or _live.over:
		_sync_live()
		return
	var want := int(round(delta * ENGINE_FPS))
	_live.advance(clampi(want, 1, MAX_FRAMES_PER_TICK))
	_sync_live()
	_drive_camera(delta)


## Run the ORIGINAL's own camera controller for this display frame and let it move the
## view. `Pm98CamCtrl` is the exact port of `FUN_005f5850` plus the display driver at
## 0x597906; `Pm98Camera.follow` applies its movement to the fitted pose (see the note in
## that file for why the motion is applied as a delta and the rotation is not applied at
## all). Anchored on the first live frame so the view starts exactly where the fit put it.
func _drive_camera(delta: float) -> void:
	var st := _live.camera_state()
	var dt := maxi(1, int(round(delta * 1000.0)))
	if _cam_ctrl == null:
		_cam_ctrl = Pm98CamCtrl.new()
		_cam_ctrl.settle(st)
		_cam.anchor_to(_cam_ctrl)
		return
	_cam_ctrl.drive(st, dt)
	_cam.follow(_cam_ctrl)


func _sync_live() -> void:
	_minute = float(_live.minute())
	_live_score = Vector2i(_live.score[0], _live.score[1])
	while _live_feed.size() < _live.goals.size():
		var g: Dictionary = _live.goals[_live_feed.size()]
		_live_feed.append({"minute": int(g["minute"]), "side": int(g["team"]), "goal": true})


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
				1:    # CONTINUE: run to full time and hold on the result. On a live match
					# that means actually PLAYING the rest of it on the engine — the
					# original's own "skip to the end" is the same spin (Pm98Outer's
					# skip-request branch), not a jump to a precomputed scoreline.
					if _live != null:
						_live.run_to_full_time()
						_sync_live()
					else:
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

## Normalised pitch coords (the timeline path's own space, nx along the length, ny across the
## width) -> WORLD metres about the centre spot, so both paths feed one camera.
func _world(nx: float, ny: float, z := 0.0) -> Vector3:
	return Vector3((clampf(nx, 0.0, 1.0) * 2.0 - 1.0) * _half_len,
		(clampf(ny, 0.0, 1.0) * 2.0 - 1.0) * _half_wid, z)


## Ball position in WORLD metres. On a LIVE match this is the engine's own ball, `+0xc` height
## included; otherwise it is the timeline-driven flow.
func _ball_world() -> Vector3:
	if _live != null:
		var b := _live.ball_position()
		return _world(float(b["nx"]), float(b["ny"]), clampf(float(b["height"]), 0.0, 20.0))
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
	return _world(clampf(nx, 0.04, 0.96), clampf(ny, 0.04, 0.96))


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	# LIVE: read the clock/score off the engine here rather than only in _process, so a
	# harness that drives the engine itself (PM98_LIVEWATCH_SHOT) still shows the real
	# minute and scoreline instead of a stale 0:0.
	if _live != null:
		_sync_live()
		# A harness that drives the engine itself turns _process off (PM98_LIVEWATCH_SHOT),
		# so the camera would never see a frame. Give it the nominal display frame here so
		# the captured shots show the camera where the driver really puts it.
		if not is_processing():
			_drive_camera(1.0 / 60.0)
		var half := _live.pitch_half()
		if half.x > 0 and half.y > 0:
			_half_len = Pm98Camera.fx(half.x)
			_half_wid = Pm98Camera.fx(half.y)
	draw_rect(Rect2(Vector2.ZERO, size), C_BG, true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	_draw_stands()
	_draw_pitch()
	var ball := _ball_world()
	_draw_teams(ball)
	_draw_ball(ball)
	_draw_hud()
	_draw_buttons()


## Everything beyond the FAR touchline: the advertising hoardings and the terrace above them,
## both from DATSIM's own HIERPREM atlas. They sit at a constant depth, so the camera gives
## their screen band directly — no invented horizon line.
func _draw_stands() -> void:
	var far := _cam.project(Vector3(0.0, _half_wid, 0.0)).y
	var board_top := _cam.project(Vector3(0.0, _half_wid, BOARD_H)).y
	var stand_top := _cam.project(Vector3(0.0, _half_wid, STAND_H)).y
	draw_rect(Rect2(0, 0, W, maxf(stand_top, 0.0)), Color8(20, 24, 30), true)
	_tile(_crowd, Rect2(0, stand_top, W, maxf(board_top - stand_top, 1.0)))
	_tile(_board, Rect2(0, board_top, W, maxf(far - board_top, 1.0)))


## The playing surface: mown bands running ALONG the depth axis (so their edges are
## constant-X lines, which is how they read in the original capture), then the markings, then
## the two goals. Every band and line is a projected WORLD quantity, so the perspective is the
## camera's rather than a hand-drawn trapezoid.
func _draw_pitch() -> void:
	var hl := _half_len
	var hw := _half_wid
	# grass out to a margin beyond the touchlines, as the original shows
	var m := 6.0
	var x := -hl - m
	var i := 0
	while x < hl + m:
		var x1: float = minf(x + STRIPE_W, hl + m)
		_ground_quad(x, x1, -hw - m, hw + m, GRASS_A if i % 2 == 0 else GRASS_B)
		x = x1
		i += 1
	# a light band where the mower turned, sampled from the capture
	_ground_quad(-hl - m, hl + m, hw - 2.0, hw + m, GRASS_LIGHT)

	# `FUN_0059a8c0`'s own two loops: the touchlines step y by 2*halfWid from -halfWid, and the
	# goal/halfway lines step x by halfLen from -halfLen (so x = -hl, 0, +hl — the halfway line
	# falls out of the same loop). Both overrun the corners by one line width at each end.
	for sy in [-1.0, 1.0]:
		_line([Vector3(-hl - LINE_W, sy * hw, 0), Vector3(hl + LINE_W, sy * hw, 0)])
	for sx in [-1.0, 0.0, 1.0]:
		_line([Vector3(sx * hl, -hw - LINE_W, 0), Vector3(sx * hl, hw + LINE_W, 0)])
	_arc(Vector2.ZERO, CIRCLE_R, 0.0, TAU, 48)
	_spot(Vector2.ZERO)
	for s in [-1.0, 1.0]:
		var sgn: float = s
		var gx: float = sgn * hl
		var px: float = sgn * (hl - PEN_DEPTH)
		var ax: float = sgn * (hl - GOALAREA_DEPTH)
		_line([Vector3(gx, -PEN_HALF_W, 0), Vector3(px, -PEN_HALF_W, 0),
			Vector3(px, PEN_HALF_W, 0), Vector3(gx, PEN_HALF_W, 0)])
		_line([Vector3(gx, -GOALAREA_HALF_W, 0), Vector3(ax, -GOALAREA_HALF_W, 0),
			Vector3(ax, GOALAREA_HALF_W, 0), Vector3(gx, GOALAREA_HALF_W, 0)])
		var spot := Vector2(sgn * (hl - PEN_SPOT), 0.0)
		_spot(spot)
		# the D — the arc of radius 9.15 about the penalty spot, spanning the binary's own
		# +/-0x2640 (`FUN_005d9640(&v, 0x92666, 0x1999, 0xffffd9c0, 0x2640)` and its mirror).
		var base := 0.0 if sgn < 0.0 else PI
		_arc(spot, CIRCLE_R, base - D_HALF_ANGLE, base + D_HALF_ANGLE, 20)
		for sy in [-1.0, 1.0]:
			_arc(Vector2(gx, sy * hw), CORNER_R, 0.0, TAU, 12)
		_draw_goal(sgn)


## A goal, drawn as real 3D geometry: two posts, the crossbar, and the net panel between
## them. RED.BMP (the game's own net mesh) fills the mouth.
func _draw_goal(sgn: float) -> void:
	var gx := sgn * _half_len
	var back := gx + sgn * 1.8
	var tl := _cam.project(Vector3(gx, -GOAL_HALF_W, GOAL_H))
	var tr := _cam.project(Vector3(gx, GOAL_HALF_W, GOAL_H))
	var bl := _cam.project(Vector3(gx, -GOAL_HALF_W, 0.0))
	var br := _cam.project(Vector3(gx, GOAL_HALF_W, 0.0))
	if _net != null:
		var r := Rect2(minf(tl.x, bl.x), minf(tl.y, tr.y),
			absf(tr.x - tl.x), maxf(bl.y, br.y) - minf(tl.y, tr.y))
		if r.size.x > 1.0 and r.size.y > 1.0:
			draw_texture_rect(_net, r, false, Color(1, 1, 1, 0.75))
	_line([Vector3(back, -GOAL_HALF_W, 0), Vector3(back, -GOAL_HALF_W, GOAL_H),
		Vector3(back, GOAL_HALF_W, GOAL_H), Vector3(back, GOAL_HALF_W, 0)], Color8(180, 186, 190))
	_line([Vector3(gx, -GOAL_HALF_W, 0), Vector3(gx, -GOAL_HALF_W, GOAL_H)], Color.WHITE, 2.0)
	_line([Vector3(gx, GOAL_HALF_W, 0), Vector3(gx, GOAL_HALF_W, GOAL_H)], Color.WHITE, 2.0)
	_line([Vector3(gx, -GOAL_HALF_W, GOAL_H), Vector3(gx, GOAL_HALF_W, GOAL_H)], Color.WHITE, 2.0)


## Fill a ground-plane rectangle (world metres) as its projected quad, clipped to the near
## plane. The camera sits 2 m PAST the near touchline, so most pitch geometry crosses it —
## dropping such geometry (the first cut of this did) silently loses the halfway line and half
## the mown bands.
func _ground_quad(x0: float, x1: float, y0: float, y1: float, col: Color) -> void:
	var ny: float = maxf(y0, _cam.eye.y + NEAR_PLANE)
	if y1 <= ny:
		return
	var pts := PackedVector2Array([
		_cam.project(Vector3(x0, y1, 0)), _cam.project(Vector3(x1, y1, 0)),
		_cam.project(Vector3(x1, ny, 0)), _cam.project(Vector3(x0, ny, 0))])
	draw_colored_polygon(pts, col)


## Project a world polyline and stroke it, clipping every segment at the near plane instead of
## discarding lines that cross it. Line width follows the nearest surviving point's scale, so
## a far touchline thins out the way the original's does.
func _line(pts: Array, col := LINE_COL, w := 0.0) -> void:
	var out := PackedVector2Array()
	var width := w
	var prev: Variant = null
	for p in pts:
		var v: Vector3 = p
		var inside := _cam.depth(v) > NEAR_PLANE
		if prev != null:
			var u: Vector3 = prev
			var u_in := _cam.depth(u) > NEAR_PLANE
			if u_in != inside:
				var clipped := _clip_near(u, v)
				if out.is_empty() and inside:
					out.append(_cam.project(clipped))
				elif not inside:
					out.append(_cam.project(clipped))
					_stroke(out, col, width, w)
					out = PackedVector2Array()
		if inside:
			out.append(_cam.project(v))
			if w == 0.0:
				width = maxf(width, _cam.scale_at(_cam.depth(v)) * 0.12)
		prev = v
	_stroke(out, col, width, w)


func _stroke(out: PackedVector2Array, col: Color, width: float, w: float) -> void:
	if out.size() >= 2:
		draw_polyline(out, col, clampf(width if w == 0.0 else w, 1.0, 4.0))


## The point where segment a->b crosses the near plane.
func _clip_near(a: Vector3, b: Vector3) -> Vector3:
	var da := _cam.depth(a)
	var db := _cam.depth(b)
	if is_equal_approx(da, db):
		return b
	return a.lerp(b, (NEAR_PLANE - da) / (db - da))


func _arc(centre: Vector2, r: float, from_a: float, to_a: float, steps: int) -> void:
	var pts: Array = []
	for i in steps + 1:
		var a := lerpf(from_a, to_a, float(i) / float(steps))
		pts.append(Vector3(centre.x + cos(a) * r, centre.y + sin(a) * r, 0.0))
	_line(pts)


## The centre and penalty marks. `FUN_0059a8c0` draws each as a `0x6664` x `0x3332`
## (0.4 m x 0.2 m) ground quad, not a dot, so that is what this draws.
func _spot(centre: Vector2) -> void:
	_ground_quad(centre.x - SPOT_W * 0.5, centre.x + SPOT_W * 0.5,
		centre.y - SPOT_H * 0.5, centre.y + SPOT_H * 0.5, LINE_COL)


## Fill `r` by repeating `tex` from its top-left (clips the last row/column).
func _tile(tex: Texture2D, r: Rect2) -> void:
	if r.size.y <= 0.0:
		return
	if tex == null:
		draw_rect(r, Color8(30, 34, 40), true)
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


func _draw_teams(ball: Vector3) -> void:
	if _live != null:
		_draw_teams_live()
		return
	var atk := _attacking_side(_minute)
	var near_home := _draw_side(0, HOME_FORM, _home_col, ball, atk == 0)
	var near_away := _draw_side(1, _mirror(HOME_FORM), _away_col, ball, atk == 1)
	if atk == 0 and near_home != Vector3.ZERO:
		_draw_arrow(near_home)
	elif atk == 1 and near_away != Vector3.ZERO:
		_draw_arrow(near_away)


## LIVE: draw all 22 players where the ENGINE puts them, with the sprite the ENGINE would
## pick. `x`/`y` are `player+0x4`/`+0x8`, `facing` is `+0x34`, `kind` is `+0x40` and `phase`
## is `+0x2c` — the exact four inputs `FUN_005a5460` reads. Nothing is interpolated, guessed
## or remembered here. The active arrow goes to the engine's designated carrier
## (`match+0x440`), the original's own notion of who is on the ball.
func _draw_teams_live() -> void:
	var drawn: Array = []
	var carrier := Vector3.ZERO
	for p in _live.player_positions():
		var side := int(p["side"])
		var w := Vector3(Pm98Camera.fx(int(p["x"])), Pm98Camera.fx(int(p["y"])),
			Pm98Camera.fx(int(p["z"])))
		drawn.append({"w": w, "col": _home_col if side == 0 else _away_col,
			"kind": int(p["kind"]), "facing": int(p["facing"]), "phase": int(p["phase"]),
			"side": side, "slot": int(p["slot"])})
		if bool(p["carrying"]):
			carrier = w
	# painter's order: farthest first, so a near player overlaps a far one
	drawn.sort_custom(func(a, b): return (a["w"] as Vector3).y > (b["w"] as Vector3).y)
	for d in drawn:
		_draw_player(d["w"], d["col"], int(d["kind"]), int(d["facing"]), int(d["phase"]),
			int(d["side"]), int(d["slot"]))
	if carrier != Vector3.ZERO:
		_draw_arrow(carrier)


## Mirror the home formation to the away half (ny -> 1-ny).
func _mirror(form: Array) -> Array:
	var out: Array = []
	for p in form:
		out.append(Vector2((p as Vector2).x, 1.0 - (p as Vector2).y))
	return out


## Draw one team on the TIMELINE path; returns the world pos of the outfielder nearest the
## ball (or ZERO). Facing here is the direction of travel converted to the engine's own 16-bit
## angle word and then bucketed by `JugRender` exactly as a live match's is — the picker is
## never bypassed, only its input is the app's on this path.
func _draw_side(side: int, form: Array, col: Color, ball: Vector3, has_ball: bool) -> Vector3:
	var prev: Array = _home_prev if side == 0 else _away_prev
	var slot0 := 0 if side == 0 else 11
	var ball_n := Vector2((ball.x / _half_len + 1.0) * 0.5, (ball.y / _half_wid + 1.0) * 0.5)
	var poss: Array = []
	var nearest_i := -1
	var nearest_d := 1e9
	for i in form.size():
		var base: Vector2 = form[i]
		var follow := 0.0 if i == 0 else 0.30
		var nx := base.x + (ball_n.x - 0.5) * (follow * 0.7) + sin(_t * 1.3 + i) * 0.012
		var ny := base.y + (ball_n.y - 0.5) * follow
		var w := _world(nx, ny)
		poss.append(w)
		if i != 0:
			var d := w.distance_to(ball)
			if d < nearest_d:
				nearest_d = d
				nearest_i = i
	if has_ball and nearest_i >= 0:
		poss[nearest_i] = (poss[nearest_i] as Vector3).lerp(ball, 0.55)
	var order := range(poss.size())
	order.sort_custom(func(a, b): return (poss[a] as Vector3).y > (poss[b] as Vector3).y)
	for i in order:
		var w: Vector3 = poss[i]
		var face := _travel_angle(prev[i], w)
		prev[i] = w
		var idx: int = slot0 + i
		var st: Dictionary = _anim[idx] if idx < _anim.size() and _anim[idx] is Dictionary \
			else {"kind": 3, "phase": 0}
		_draw_player(w, col, int(st["kind"]), face, int(st["phase"]), side, i)
	return poss[nearest_i] if nearest_i >= 0 else Vector3.ZERO


## Direction of travel as the engine's own 16-bit angle word (full circle = 65536), so the
## timeline path hands `JugRender` the same kind of input a live player's `+0x34` carries.
func _travel_angle(prev_pos, pos: Vector3) -> int:
	if not (prev_pos is Vector3):
		return 0
	var v: Vector3 = pos - (prev_pos as Vector3)
	if Vector2(v.x, v.y).length() < 0.02:
		return 0
	return int(round(atan2(v.y, v.x) / TAU * 65536.0)) & 0xffff


## One player as the engine draws him: the JUG frame `FUN_005a5460` would pick, sized from the
## frame's OWN anchor and the `0x1b333/0x30` world-height scale, standing on the ground at his
## world position, with the drop shadow the original casts.
func _draw_player(w: Vector3, col: Color, kind: int, facing: int, phase: int,
		side := -1, slot := -1) -> void:
	var d := _cam.depth(w)
	if d <= _cam.MIN_DEPTH:
		return
	var r: Dictionary = JugRender.resolve(kind, facing, phase)
	var px := _cam.scale_at(d)
	var mz := JugRender.metres_per_pixel_z()
	var mx := JugRender.metres_per_pixel_x()
	if r.is_empty() or mz <= 0.0:
		draw_circle(_cam.project(w), maxf(1.0, px * 0.25), col)
		return
	var src: Rect2 = r["rect"]
	var ax := float(int(r["ax"]))
	var ay := float(int(r["ay"]))
	# world extents of the billboard, from the frame header (jug_render_spec.md §"the draw")
	var z_top := ay * mz
	var z_bot := (ay - src.size.y) * mz
	var x_left := -ax * mx
	var x_right := (src.size.x - ax) * mx
	var top := _cam.project(Vector3(w.x, w.y, w.z + z_top))
	var bot := _cam.project(Vector3(w.x, w.y, w.z + z_bot))
	var dw := (x_right - x_left) * px
	var dst := Rect2(_cam.project(Vector3(w.x + x_left, w.y, w.z)).x, top.y, dw,
		maxf(bot.y - top.y, 1.0))
	# contact shadow on the deck, at the feet
	var foot := _cam.project(Vector3(w.x, w.y, 0.0))
	draw_circle(Vector2(foot.x, foot.y), maxf(1.0, dw * 0.36), Color(0, 0, 0, 0.30))
	if bool(r["flip"]):
		dst = Rect2(dst.position.x + dst.size.x, dst.position.y, -dst.size.x, dst.size.y)
	var tex := _player_sprite(int(r["frame"]), int(r["map"]), bool(r["flip"]), side, slot)
	if tex != null:
		draw_texture_rect_region(tex, dst, src, Color.WHITE)
	else:
		draw_circle(_cam.project(w), maxf(1.0, px * 0.25), col)


## `FUN_005a5460:519-556` then `FUN_005d34a0` — build this player's 256-byte LUT and remap the
## frame through it. Slot 0 is the goalkeeper, who wears the team's `palpor` strip and whose
## shirt pattern is NOT painted (the binary gates that pass on `actor+0x2d4 = (slot != 0)`).
## With no XI (the timeline path) the team LUT's own defaults stand: `P96A0000.DAT` already
## carries a skin ramp at 1..8 and a hair ramp at 0x15..0x18, so nothing is invented.
func _player_sprite(frame: int, map_id: int, flip: bool, side: int, slot: int) -> Texture2D:
	if _pal.size() < 256 or side < 0 or side >= _kits.size():
		return null
	var kit: Dictionary = _kits[side]
	if kit.is_empty():
		return null
	var keeper := slot == 0
	var team_lut: PackedByteArray = kit["lut"]
	if keeper:
		var kk: Dictionary = kit.get("keeper", {})
		if kk.is_empty():
			return null
		team_lut = kk["lut"]
	var pattern := PackedByteArray()
	var skin := PackedByteArray()
	var hair := PackedByteArray()
	var rows: Array = _squad[side] if side < _squad.size() else []
	if slot >= 0 and slot < rows.size():
		var row: Dictionary = rows[slot]
		pattern = row["pattern"]
		skin = row["skin"]
		hair = row["hair"]
	elif not keeper:
		pattern = kit["pattern"]
	var lut := JugKit.draw_lut(team_lut, pattern, skin, hair, map_id, flip, not keeper)
	return JugRender.composite(frame, lut, _pal)


func _draw_ball(ball: Vector3) -> void:
	var d := _cam.depth(ball)
	if d <= _cam.MIN_DEPTH:
		return
	var p := _cam.project(ball)
	var px := _cam.scale_at(d)
	var r: float = maxf(1.5, px * 0.11)                # a 22 cm ball
	var shadow := _cam.project(Vector3(ball.x, ball.y, 0.0))
	draw_circle(shadow, maxf(1.0, r * 0.9), Color(0, 0, 0, 0.28))
	if _ball != null:
		draw_texture_rect(_ball, Rect2(p.x - r, p.y - r, r * 2.0, r * 2.0), false)
	else:
		draw_circle(p, r, Color.WHITE)
	var gp := _goal_pulse(_minute)
	if gp["side"] != -1 and float(gp["dist"]) < 0.35:
		var a := (0.35 - float(gp["dist"])) / 0.35
		var gx: float = _half_len if int(gp["side"]) == 0 else -_half_len
		var tl := _cam.project(Vector3(gx, -GOAL_HALF_W, GOAL_H))
		var br := _cam.project(Vector3(gx, GOAL_HALF_W, 0.0))
		draw_rect(Rect2(tl, br - tl).abs(), Color(1.0, 0.95, 0.2, a * 0.55), true)


func _draw_arrow(w: Vector3) -> void:
	if _arrow == null:
		return
	var d := _cam.depth(w)
	if d <= _cam.MIN_DEPTH:
		return
	var px := _cam.scale_at(d)
	var head := _cam.project(Vector3(w.x, w.y, w.z + 2.1))
	var fw: int = maxi(1, int(_arrow.get_height()))
	var sc: float = maxf(0.25, px / 90.0)
	var dw := fw * sc
	var dh: float = _arrow.get_height() * sc
	draw_texture_rect_region(_arrow, Rect2(head.x - dw * 0.5, head.y - dh, dw, dh),
		Rect2(0, 0, fw, _arrow.get_height()))


## The original's WATCH overlay, from the capture (tools/re/refs/watch-2026-07-28/watch_02.png):
## ONE slim line top-left reading "<home> <hg> - <ag> <away>" in white over a dark plate, and
## the ball carrier's shirt number + name bottom-right. No score pill, no possession bars —
## those belong to the BRIEF view, which is a different screen.
func _draw_hud() -> void:
	var sc := _score_at(_minute)
	var line := "%s %d - %d %s" % [_home.substr(0, 18), sc.x, sc.y, _away.substr(0, 18)]
	var wd := 0.0
	if _f12 != null:
		wd = _f12.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_rect(Rect2(0, 0, wd + 12.0, 20), Color(0.05, 0.07, 0.12, 0.78), true)
	_txt(_f12, 5, 2, line, C_TITLE, 14)
	# clock + half, small, under the score line so a watched match still reads its own time
	_txt(_f10, 5, 21, "%02d:00  %s" % [int(_minute), _half_label(_minute)], C_LCD, 10)
	var who := _carrier_label()
	if who != "":
		_txt(_f12, W - 8, H - 46, who, C_TITLE, 14, true)


## The engine's designated carrier (`match+0x440`) as "<shirt> <surname>", the pairing the
## original prints bottom-right. Empty when nobody is on the ball or no live match is running.
func _carrier_label() -> String:
	if _live == null:
		return ""
	for p in _live.player_positions():
		if bool(p["carrying"]):
			var nm := _live.player_name(int(p["side"]), int(p["slot"]))
			return ("%d  %s" % [int(p["slot"]) + 1, nm]) if nm != "" else ""
	return ""


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
