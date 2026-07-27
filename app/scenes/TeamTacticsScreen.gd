extends Control
class_name TeamTacticsScreen
## PM98 TEAM TACTICS modal (ATTACK | DEFENCE) — the panel the board's TEAM TACTICS
## button (equipo.bmp, FUN_0056ea15) opens. docs/re/tactics_subscreens_re.md.
##
## FRAME-BAKED 2026-07-27. The modal IS walked: `screenshots/parity-run-2026-07-16/
## orig/25_team_tactics.png` is a fresh Bolton career (= the club's own .DBC lever
## defaults) and `26_mantoman.png` differs in EXACTLY 74 px — the two MARKING boxes,
## each equal to the 37-ink-px EQWINX sprite. So:
##   * chrome = `teamtactics_chrome.png` (the frame cut at (57,95) 526x303, the five
##     witnessed ticks erased, the four 41x21 value plates blanked to black), baked by
##     tools/re/build_tactics_subs_chrome_from_frames.py PART 3 with every invariant
##     asserted;
##   * EQWINX is the TICK — blitted into the selected box of each of the five radio
##     rows (13 boxes, positions byte-verified against both frames);
##   * the ONLY dynamic pixels are the 13 tick boxes + the four value digits — the
##     values render live in each plate's own census-verified ink;
##   * the real exit is the baked OK plate (x288..362 y365..392) — the old close-X
##     was invented (EQWINX misread as a window control) and is GONE;
##   * gate: tools/re/diff_teamtactics_parity.py vs BOTH frames.
## The value digits are a bold raster absent from the extracted .fnt bank (the scout
## MONEY precedent), so the gate declares the four plates as the app-font bucket.
## Stepper DIRECTION is un-witnessed; the flanking arrows (grey-left toward the
## PASSING/YES plate, coloured-right toward the LONG BALL/NO plate) support
## left = toward the left value — OURS-inferred, flagged.
## The backdrop dim is an approximation (the original palette-dims the whole frame:
## 144->100, 44->22 measured on 25 vs the undimmed board) — documented gap.
##
## Each control mutates the live career Tactics (Tactics.gd), emitting `changed` for
## Main to persist. OK emits `done`. Native 640x480; scales to fit.

signal changed(tactics_dict: Dictionary)   # a lever moved; persist
signal done                                  # OK closed the modal

const W := 640
const H := 480
## The original's slider step is un-witnessed; 5 is forced by the witnessed values
## themselves (Bolton 45/55 is unreachable in steps of 10 from any x0/x5 anchor pair
## other than 5s) — the old STEP=10 could never render the witnessed default.
const STEP := 5

const MODAL := Rect2(57, 95, 526, 303)
const OK_BTN := Rect2(288, 365, 75, 28)
const C_DIM := Color(0, 0, 0, 0.45)          # approximation, see header
const C_PRESS := Color(1, 1, 1, 0.2)

# option order = the modal's own row order, frame-confirmed (top to bottom /
# left to right); values are the Tactics.gd strings.
const MENTALITY := ["Attacking", "Speculative", "Mixed"]
const TACKLING := ["Soft", "Medium", "Aggressive"]
const MARKING := ["Zonal", "Man-to-man"]
const CLEARANCES := ["Short", "Long"]
const PRESSURISE := ["Own", "Midfield", "Opponent"]

var _t: Tactics = null
var _chrome: Texture2D
var _tick: Texture2D
var _spec: Dictionary = {}         # samples JSON "team_tactics_modal"
var _f10: Font
var _hits: Array = []              # [{r:Rect2, kind, value}]
var _ok_held := false
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/tactics/teamtactics_chrome.png")
	_tick = load("res://art/screens/tactics/eqwin_close.png")   # EQWINX = the tick
	_load_spec()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func _load_spec() -> void:
	var f := FileAccess.open("res://data/tactics_subs_chrome_samples.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_spec = (d as Dictionary).get("team_tactics_modal", {})


func setup(tactics: Tactics) -> void:
	_t = tactics
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	_scale = minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	draw_rect(Rect2(0, 0, W, H), C_DIM, true)
	if _chrome != null:
		draw_texture(_chrome, MODAL.position)
	if _t == null:
		return

	# the 13 radio boxes: EQWINX into the selected one, hits on all of them
	var tk: Dictionary = _spec.get("tick_xy", {})
	for lever_opts in [["mentality", MENTALITY, _t.mentality],
			["tackling", TACKLING, _t.tackling],
			["marking", MARKING, _t.marking],
			["clearances", CLEARANCES, _t.clearances],
			["pressurise", PRESSURISE, _t.pressurise]]:
		var kind: String = lever_opts[0]
		var opts: Array = lever_opts[1]
		var cur: String = lever_opts[2]
		var sites: Dictionary = tk.get(kind, {})
		for opt in opts:
			var xy: Array = sites.get(opt, [])
			if xy.size() != 2:
				continue
			var p := Vector2(int(xy[0]), int(xy[1]))
			if cur == opt and _tick != null:
				draw_texture(_tick, p)
			# tap target: the 14x11 plate padded to a finger-sized rect
			_hit(Rect2(p.x - 8, p.y - 8, 25, 23), kind, opt)

	# the four value plates: live digits + % in each plate's own sampled ink
	var plates: Dictionary = _spec.get("value_plates", {})
	var inks: Dictionary = _spec.get("value_inks", {})
	var vals := {"passing": _t.passing_pct, "long_ball": _t.long_ball_pct(),
		"counter_yes": _t.counter_pct, "counter_no": 100 - _t.counter_pct}
	for key in vals:
		var pr: Array = plates.get(key, [])
		var ik: Array = inks.get(key, [])
		if pr.size() != 4 or ik.size() != 3:
			continue
		var col := Color8(int(ik[0]), int(ik[1]), int(ik[2]))
		var s := "%d%%" % int(vals[key])
		var tw := _f10.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		# centred, clamped INSIDE the plate: the gate bounds every value pixel
		# to the 41x21 plate rect
		var px := clampf(floorf(int(pr[0]) + (int(pr[2]) - tw) * 0.5),
			int(pr[0]) + 1, int(pr[0]) + int(pr[2]) - 1 - tw)
		PMChrome.text(self, _f10, px, int(pr[1]) + 6, s, col, 11)

	# the steppers (baked art; direction OURS-inferred from the flanking arrows)
	var st: Dictionary = _spec.get("steppers", {})
	for pair in [["pass_left", "pass_inc"], ["pass_right", "pass_dec"],
			["counter_left", "cnt_inc"], ["counter_right", "cnt_dec"]]:
		var r: Array = st.get(pair[0], [])
		if r.size() == 4:
			_hit(Rect2(int(r[0]) - 3, int(r[1]) - 3, int(r[2]) + 6, int(r[3]) + 6),
				pair[1], null)

	# OK — the modal's real (baked) exit
	if _ok_held:
		draw_rect(OK_BTN, C_PRESS, true)
	_hit(OK_BTN, "ok", null)


func _hit(r: Rect2, kind: String, value: Variant) -> void:
	_hits.append({"r": r, "kind": kind, "value": value})


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var is_tap := e is InputEventMouseButton or e is InputEventScreenTouch
	if not is_tap or _t == null:
		return
	var pressed: bool = (e as InputEvent).get("pressed")
	var d: Vector2 = (e.get("position") - _origin) / _scale
	if pressed:
		_ok_held = OK_BTN.has_point(d)
		if _ok_held:
			queue_redraw()
		return
	var was_ok := _ok_held
	_ok_held = false
	if OK_BTN.has_point(d) and was_ok:
		done.emit()
		return
	for h in _hits:
		if (h["r"] as Rect2).has_point(d):
			_apply(str(h["kind"]), h["value"])
			return
	queue_redraw()


func _apply(kind: String, value: Variant) -> void:
	match kind:
		"mentality": _t.set_mentality(str(value))
		"tackling": _t.set_tackling(str(value))
		"marking": _t.set_marking(str(value))
		"clearances": _t.set_clearances(str(value))
		"pressurise": _t.set_pressurise(str(value))
		"pass_inc": _t.step_passing(STEP)
		"pass_dec": _t.step_passing(-STEP)
		"cnt_inc": _t.step_counter(STEP)
		"cnt_dec": _t.step_counter(-STEP)
	changed.emit(_t.to_dict())
	queue_redraw()
