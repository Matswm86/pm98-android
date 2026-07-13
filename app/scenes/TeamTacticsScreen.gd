extends Control
class_name TeamTacticsScreen
## PM98 TEAM TACTICS modal (ATTACK | DEFENCE) — the panel the board's TEAM TACTICS
## button (equipo.bmp, FUN_0056ea15) opens. docs/re/tactics_subscreens_re.md.
##
## SOURCE STATUS — HONEST GAP: this modal is UN-WALKED. It appears in NO
## walkthrough frame (run-1/2/3 all scanned; APP_VS_SPEC_AUDIT B6 lists PREDEFINED
## + MAN-TO-MAN but never a team-tactics/attack-defence modal) and FUN_0056ea15 is
## not disassembled. So it CANNOT be frame-baked and its ASSEMBLED WINDOW GEOMETRY
## is a documented reconstruction — NOT MEASURED for parity.
##
## What IS source-true (and used verbatim here):
##  - every CONTROL + LABEL: the exact contiguous string block in MANAGER.EXE at
##    0x25ff3c..0x260014 (ATTACK/DEFENCE; ATTACKING/SPECULATIVE/MIXED PLAY;
##    PASSING/LONG BALL; COUNTER ATTACK; TACKLING SOFT/MEDIUM/AGGRESSIVE; MARKING
##    ZONAL/MAN TO MAN; CLEARANCES SHORT/LONG; PRESSURISE FROM... OWN/MIDFIELD/
##    OPPONENT). This is why the control SET is authoritative even with no frame.
##  - every ART piece: decoded verbatim from the RECURSOS EQWIN* cluster
##    (tools/re/build_tactics_subs_chrome_from_frames.py): eqwin_attack/defence
##    headers, eqwin_ment{1,2,3} mentality tiles, eqwin_row_{tackle,marking,clear,
##    press} option strips (each carries its own baked checkboxes), eqwin_pass_
##    {short,long} slider ends, eqwin_step +/- button, eqwin_close X.
##  - each option strip's CHECKBOX centres (measured off the decoded art); the
##    selected option gets a tick painted into its baked box.
##
## What is RECONSTRUCTED (un-walked, flagged): the two-panel arrangement, the row
## stacking / y-positions, and the strip->control assignment (inferred from icon
## semantics: shoe=tackle, 1-vs-2 players=marking, pitch-zones=pressurise). The
## mentality tile order (Attacking/Speculative/Mixed) is likewise un-walked.
##
## Each control mutates the live career Tactics (Tactics.gd; its ratings() feed the
## match engine), emitting `changed` for Main to persist. The window closes on the
## EQWINX (the modal's only exit control — SAVE/LOAD TACTICS are BOARD buttons, not
## in this modal). Native 640x480; scales to fit (same transform as the board).

signal changed(tactics_dict: Dictionary)   # a lever moved; persist
signal done                                  # the X closed the modal

const W := 640
const H := 480
const STEP := 10   # slider increment (%), matches the retired TacticsScreen

# --- reconstructed window geometry (UN-WALKED; positions are not frame-verified)
const MODAL := Rect2(96, 118, 448, 240)
const TITLE := Rect2(96, 118, 448, 18)
const CLOSE := Rect2(528, 120, 12, 14)
const ATK_X := 110
const DEF_X := 324
const PANEL_W := 198
const HDR_Y := 144            # header strips top
const CONTENT_Y := 196        # first control row top

const C_DIM := Color(0, 0, 0, 0.45)
const C_TITLE_BAR := Color(0.16, 0.30, 0.60)
const C_PANEL := Color(1, 1, 1)
const C_LABEL := Color(0.10, 0.13, 0.22)
const C_TICK := Color(0.78, 0.12, 0.10)
const C_SLIDER := Color(0.40, 0.62, 0.20)
const C_SLIDER_LONG := Color(0.20, 0.38, 0.70)

# option order per control (values are the Tactics.gd strings)
const MENTALITY := ["Attacking", "Speculative", "Mixed"]   # un-walked tile order
const TACKLING := ["Soft", "Medium", "Aggressive"]
const MARKING := ["Zonal", "Man-to-man"]
const CLEARANCES := ["Short", "Long"]
const PRESSURISE := ["Own", "Midfield", "Opponent"]

var _t: Tactics = null
var _spec: Dictionary = {}
var _f8: Font
var _f10: Font
var _f12: Font
var _art: Dictionary = {}
var _cbx: Dictionary = {}          # strip file -> [checkbox cx]
var _hits: Array = []              # [{r:Rect2, kind, value}]
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	for nm in ["eqwin_attack", "eqwin_defence", "eqwin_ment1", "eqwin_ment2", "eqwin_ment3",
			"eqwin_row_tackle", "eqwin_row_marking", "eqwin_row_clear", "eqwin_row_press",
			"eqwin_pass_short", "eqwin_pass_long", "eqwin_step", "eqwin_close"]:
		_art[nm] = load("res://art/screens/tactics/%s.png" % nm)
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
		var tt: Dictionary = (d as Dictionary).get("team_tactics", {})
		_cbx = tt.get("checkbox_cx", {})


func setup(tactics: Tactics) -> void:
	_t = tactics
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	_scale = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	draw_rect(Rect2(0, 0, W, H), C_DIM, true)                       # dim backdrop
	PMChrome.bevel(self, MODAL, PMChrome.C_PLAQUE, PMChrome.C_PLAQUE_HI, PMChrome.C_PLAQUE_LO, 2.0)
	PMChrome.bevel(self, TITLE, C_TITLE_BAR, C_TITLE_BAR.lightened(0.3), C_TITLE_BAR.darkened(0.4))
	PMChrome.text(self, _f12, TITLE.position.x, TITLE.position.y + 2, "TEAM TACTICS",
		PMChrome.C_TITLE, 13, 1, TITLE.size.x)
	if _art.get("eqwin_close") != null:
		draw_texture(_art["eqwin_close"], CLOSE.position + Vector2(1, 3))
	_hit(CLOSE, "close", null)

	if _t == null:
		return
	# white panels behind each half (the header/strip art assumes a white ground)
	draw_rect(Rect2(ATK_X - 2, HDR_Y - 2, PANEL_W + 4, 202), C_PANEL, true)
	draw_rect(Rect2(DEF_X - 2, HDR_Y - 2, PANEL_W + 4, 202), C_PANEL, true)
	if _art.get("eqwin_attack") != null:
		draw_texture(_art["eqwin_attack"], Vector2(ATK_X, HDR_Y))
	if _art.get("eqwin_defence") != null:
		draw_texture(_art["eqwin_defence"], Vector2(DEF_X, HDR_Y))
	_draw_attack()
	_draw_defence()


func _draw_attack() -> void:
	# mentality: three EQWINAZUL tiles, each a source-true option (icon + baked box)
	var y := CONTENT_Y
	var tiles := ["eqwin_ment1", "eqwin_ment2", "eqwin_ment3"]
	var mcx := int(_cbx.get("mentality_tile", 34))
	for i in MENTALITY.size():
		var tile: Texture2D = _art.get(tiles[i])
		var tx := ATK_X + 2
		if tile != null:
			draw_texture(tile, Vector2(tx, y))
		if _t.mentality == MENTALITY[i]:
			_tick(Vector2(tx + mcx, y + 9))
		PMChrome.text(self, _f10, tx + 50, y + 4, _mental_label(MENTALITY[i]), C_LABEL, 11)
		_hit(Rect2(tx, y, PANEL_W - 6, 18), "mentality", MENTALITY[i])
		y += 20

	# PASSING <-> LONG BALL slider (EQWINTOQUE / EQWINLARGO ends + a value bar)
	y += 6
	PMChrome.text(self, _f8, ATK_X + 2, y, "PASSING", C_SLIDER.darkened(0.2), 10)
	PMChrome.text(self, _f8, ATK_X + PANEL_W - 2, y, "LONG BALL", C_SLIDER_LONG, 10, 2)
	y += 11
	if _art.get("eqwin_pass_short") != null:
		draw_texture(_art["eqwin_pass_short"], Vector2(ATK_X + 2, y))
	if _art.get("eqwin_pass_long") != null:
		draw_texture(_art["eqwin_pass_long"], Vector2(ATK_X + PANEL_W - 43, y))
	var bar := Rect2(ATK_X + 48, y + 5, PANEL_W - 96, 12)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _t.passing_pct / 100.0, bar.size.y)), C_SLIDER, true)
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * _t.passing_pct / 100.0, 0),
		Vector2(bar.size.x * (1.0 - _t.passing_pct / 100.0), bar.size.y)), C_SLIDER_LONG, true)
	_stepper(Rect2(ATK_X + 46, y + 20, 18, 15), "-", "pass_dec")
	PMChrome.text(self, _f10, ATK_X + 2, y + 22, "%d%%" % _t.passing_pct, C_SLIDER.darkened(0.2), 11)
	PMChrome.text(self, _f10, ATK_X + PANEL_W - 2, y + 22, "%d%%" % _t.long_ball_pct(),
		C_SLIDER_LONG, 11, 2)
	_stepper(Rect2(ATK_X + PANEL_W - 64, y + 20, 18, 15), "+", "pass_inc")
	y += 40

	# COUNTER ATTACK slider (YES/NO %)
	PMChrome.text(self, _f10, ATK_X + 2, y, "COUNTER ATTACK", C_LABEL, 11)
	y += 13
	_stepper(Rect2(ATK_X + 46, y, 18, 15), "-", "cnt_dec")
	PMChrome.text(self, _f10, ATK_X + 2, y + 2, "YES %d%%" % _t.counter_pct, C_SLIDER.darkened(0.2), 11)
	PMChrome.text(self, _f10, ATK_X + PANEL_W - 2, y + 2, "%d%% NO" % (100 - _t.counter_pct),
		C_TICK.darkened(0.05), 11, 2)
	_stepper(Rect2(ATK_X + PANEL_W - 64, y, 18, 15), "+", "cnt_inc")


func _draw_defence() -> void:
	# four source-true option strips, each with its own baked checkboxes; the
	# selected option gets a tick. Strip->control mapping is icon-semantic (flagged).
	var rows := [
		["TACKLING", "eqwin_row_tackle", "tackling", TACKLING, _t.tackling],
		["MARKING", "eqwin_row_marking", "marking", MARKING, _t.marking],
		["CLEARANCES", "eqwin_row_clear", "clearances", CLEARANCES, _t.clearances],
		["PRESSURISE FROM...", "eqwin_row_press", "pressurise", PRESSURISE, _t.pressurise],
	]
	var y := CONTENT_Y
	for r in rows:
		var label: String = r[0]
		var strip_key: String = r[1]
		var kind: String = r[2]
		var opts: Array = r[3]
		var cur: String = r[4]
		PMChrome.text(self, _f10, DEF_X + 2, y, label, C_LABEL, 11)
		var sy := y + 12
		var strip: Texture2D = _art.get(strip_key)
		var sw := PANEL_W - 6
		if strip != null:
			sw = strip.get_width()
			draw_texture(strip, Vector2(DEF_X + 3, sy))
		var cxs: Array = _cbx.get(strip_key + ".png", [])
		var opt_w := sw / float(opts.size())
		for i in opts.size():
			if i < cxs.size() and cur == opts[i]:
				_tick(Vector2(DEF_X + 3 + int(cxs[i]), sy + (strip.get_height() if strip != null else 16) / 2))
			_hit(Rect2(DEF_X + 3 + i * opt_w, sy, opt_w, 18), kind, opts[i])
		y += 33


# ---- glyphs --------------------------------------------------------------

## A tick painted into a baked (white) checkbox: a small red-bevelled square + X.
func _tick(centre: Vector2) -> void:
	var r := Rect2(centre - Vector2(5, 5), Vector2(10, 10))
	draw_rect(r, C_TICK, true)
	draw_line(r.position + Vector2(2, 2), r.end - Vector2(2, 2), Color.WHITE, 1.5)
	draw_line(Vector2(r.end.x - 2, r.position.y + 2), Vector2(r.position.x + 2, r.end.y - 2),
		Color.WHITE, 1.5)


func _stepper(r: Rect2, glyph: String, kind: String) -> void:
	if _art.get("eqwin_step") != null:
		draw_texture(_art["eqwin_step"], r.position)
	else:
		PMChrome.bevel(self, r, PMChrome.C_PLAQUE, PMChrome.C_PLAQUE_HI, PMChrome.C_PLAQUE_LO)
	PMChrome.text(self, _f12, r.position.x, r.position.y - 1, glyph, PMChrome.C_TITLE, 13, 1, r.size.x)
	_hit(r, kind, null)


func _mental_label(v: String) -> String:
	# the binary carries "<X> PLAY"; show it as PM98 does
	return "%s Play" % v


func _hit(r: Rect2, kind: String, value: Variant) -> void:
	_hits.append({"r": r, "kind": kind, "value": value})


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var pressed := (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed)
	if not pressed or _t == null:
		return
	var d: Vector2 = (e.position - _origin) / _scale
	for h in _hits:
		if (h["r"] as Rect2).has_point(d):
			_apply(str(h["kind"]), h["value"])
			return


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
		"close":
			done.emit()
			return
	changed.emit(_t.to_dict())
	queue_redraw()
