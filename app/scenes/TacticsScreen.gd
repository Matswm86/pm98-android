extends Control
class_name TacticsScreen
## PM98 TEAM TACTICS modal (ma_9): the centred ATTACK | DEFENCE panel that opens over
## the dimmed LINE-UP table. Rebuilt to match the real game rather than the prior text
## menu — the ATTACK half is the mentality radio (Attacking / Speculative / Mixed),
## the PASSING<->LONG-BALL slider and the COUNTER ATTACK slider; the DEFENCE half is
## TACKLING (Soft/Medium/Aggressive), MARKING (Zonal/Man-to-man), CLEARANCES
## (Short/Long) and PRESSURISE FROM (Own/Midfield/Opponent). OK / SAVE TACTICS / RETURN
## along the bottom.
##
## Every control feeds the match engine for real: it mutates the career Tactics, whose
## ratings() turns each lever into a bounded att/def trade-off (see Tactics.gd). It draws
## the modal + a dim layer only; Main mounts a real LineupScreen behind it as the backdrop
## (so the table the modal sits over is the genuine line-up, not a redraw). Native 640x480.

const W := 640
const H := 480

# Modal geometry (design space).
const MODAL := Rect2(40, 148, 560, 274)
const TITLE_BAR := Rect2(40, 148, 560, 18)
const ATK := Rect2(52, 172, 256, 222)
const DEF := Rect2(320, 172, 268, 222)
const OK_BTN := Rect2(282, 400, 76, 18)
const SAVE_BTN := Rect2(16, 452, 150, 22)
const RET_BTN := Rect2(474, 452, 150, 22)

# Palette (read off ma_9).
const C_DIM := Color(0.04, 0.05, 0.09, 0.55)
const C_MODAL := Color(0.55, 0.60, 0.70)
const C_MODAL_HI := Color(0.78, 0.82, 0.90)
const C_MODAL_LO := Color(0.24, 0.28, 0.38)
const C_ATK_HDR := Color(0.18, 0.34, 0.66)        # blue ATTACK header
const C_DEF_HDR := Color(0.86, 0.46, 0.12)        # orange DEFENCE header
const C_BAND_ORANGE := Color(0.82, 0.42, 0.10)
const C_BAND_RED := Color(0.70, 0.12, 0.12)
const C_PASS := Color(0.40, 0.62, 0.20)           # green PASSING
const C_LONG := Color(0.20, 0.38, 0.70)           # blue LONG BALL
const C_YES := Color(0.34, 0.58, 0.18)            # green YES
const C_NO := Color(0.74, 0.16, 0.14)             # red NO
const C_CHK := Color(0.78, 0.14, 0.12)            # checked box red
const C_BOX := Color(0.96, 0.97, 0.99)            # empty box
const C_BTN := Color(0.20, 0.34, 0.62)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_TXT := Color(0.10, 0.13, 0.22)
const C_PANEL_TXT := Color(0.92, 0.95, 1.0)

const STEP := 10   # slider increment (%)

signal changed(tactics_dict: Dictionary)   # a lever moved; persist
signal save_requested(tactics_dict: Dictionary)
signal done                                  # OK or RETURN

var _t: Tactics = null
var _f8: Font
var _f10: Font
var _f12: Font
var _f14: Font
var _hits: Array = []          # [{r: Rect2, kind: String, value: Variant}] in design space
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f14 = PMChrome.font("14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Feed the career's live Tactics (mutated in place by the controls).
func setup(tactics: Tactics) -> void:
	_t = tactics
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _t_str(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, align := 0, box_w := 0.0) -> void:
	PMChrome.text(self, f, x, y_top, s, col, sz, align, box_w)


func _draw() -> void:
	_scale = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	_origin = Vector2((size.x - W * _scale) * 0.5, (size.y - H * _scale) * 0.5)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	_hits.clear()

	# Dim the line-up backdrop (drawn by the LineupScreen sibling beneath).
	draw_rect(Rect2(0, 0, W, H), C_DIM, true)

	# Modal frame + blue title bar.
	PMChrome.bevel(self, MODAL, C_MODAL, C_MODAL_HI, C_MODAL_LO, 2.0)
	PMChrome.bevel(self, TITLE_BAR, C_ATK_HDR, C_ATK_HDR.lightened(0.3), C_ATK_HDR.darkened(0.4))
	_t_str(_f14, TITLE_BAR.position.x, TITLE_BAR.position.y + 1, "TEAM TACTICS", PMChrome.C_TITLE, 14, 1, TITLE_BAR.size.x)

	if _t == null:
		return
	_draw_attack()
	_draw_defence()

	# OK (inside modal) + SAVE TACTICS / RETURN (on the chrome below).
	_button(OK_BTN, "OK", C_GOLD, "ok", null, 13, true)
	_button(SAVE_BTN, "SAVE TACTICS", C_PASS.lightened(0.4), "save", null, 12)
	_button(RET_BTN, "RETURN", C_GOLD, "return", null, 12)


func _draw_attack() -> void:
	PMChrome.bevel(self, ATK, C_BOX, Color.WHITE, PMChrome.C_TBL_LO, 1.0)
	# header
	var hdr := Rect2(ATK.position.x + 4, ATK.position.y + 4, ATK.size.x - 8, 22)
	PMChrome.bevel(self, hdr, C_ATK_HDR, C_ATK_HDR.lightened(0.3), C_ATK_HDR.darkened(0.4))
	_pitch_icon(Rect2(hdr.position.x + 3, hdr.position.y + 3, 22, 16))
	_t_str(_f14, hdr.position.x + 30, hdr.position.y + 3, "ATTACK", PMChrome.C_TITLE, 14)

	# mentality radio (screen order: Attacking / Speculative / Mixed)
	var labels := [["Attacking", "ATTACKING PLAY"], ["Speculative", "SPECULATIVE PLAY"],
		["Mixed", "MIXED PLAY"]]
	var y := ATK.position.y + 34
	for row in labels:
		var r := Rect2(ATK.position.x + 10, y, ATK.size.x - 20, 20)
		_arrow(Rect2(r.position.x, y + 4, 14, 12), C_ATK_HDR)
		_check(Rect2(r.position.x + 18, y + 4, 13, 13), _t.mentality == row[0])
		_t_str(_f10, r.position.x + 38, y + 4, row[1], C_TXT, 11)
		_hit(r, "mentality", row[0])
		y += 21

	# PASSING <-> LONG BALL slider
	y += 4
	var pb := Rect2(ATK.position.x + 10, y, ATK.size.x - 20, 14)
	draw_rect(Rect2(pb.position.x, pb.position.y, pb.size.x * 0.5, pb.size.y), C_PASS, true)
	draw_rect(Rect2(pb.get_center().x, pb.position.y, pb.size.x * 0.5, pb.size.y), C_LONG, true)
	_t_str(_f8, pb.position.x + 4, pb.position.y + 2, "PASSING", Color.WHITE, 10)
	_t_str(_f8, pb.end.x - 4, pb.position.y + 2, "LONG BALL", Color.WHITE, 10, 2)
	y += 16
	var srow := Rect2(ATK.position.x + 10, y, ATK.size.x - 20, 18)
	_t_str(_f12, srow.position.x + 2, srow.position.y + 2, "%d%%" % _t.passing_pct, C_PASS.darkened(0.2), 13)
	_stepper(Rect2(srow.get_center().x - 40, srow.position.y, 18, 16), "-", "pass_dec")
	_stepper(Rect2(srow.get_center().x + 22, srow.position.y, 18, 16), "+", "pass_inc")
	_t_str(_f12, srow.end.x - 2, srow.position.y + 2, "%d%%" % _t.long_ball_pct(), C_LONG.darkened(0.1), 13, 2)
	y += 22

	# COUNTER ATTACK slider
	var cb := Rect2(ATK.position.x + 10, y, ATK.size.x - 20, 14)
	PMChrome.bevel(self, cb, C_BTN, C_BTN.lightened(0.3), C_BTN.darkened(0.4))
	_t_str(_f10, cb.position.x, cb.position.y + 1, "COUNTER ATTACK", C_PANEL_TXT, 11, 1, cb.size.x)
	y += 16
	var crow := Rect2(ATK.position.x + 10, y, ATK.size.x - 20, 18)
	_t_str(_f12, crow.position.x + 2, crow.position.y + 2, "YES %d%%" % _t.counter_pct, C_YES.darkened(0.15), 13)
	_stepper(Rect2(crow.get_center().x - 40, crow.position.y, 18, 16), "-", "cnt_dec")
	_stepper(Rect2(crow.get_center().x + 22, crow.position.y, 18, 16), "+", "cnt_inc")
	_t_str(_f12, crow.end.x - 2, crow.position.y + 2, "%d%% NO" % (100 - _t.counter_pct), C_NO.darkened(0.05), 13, 2)


func _draw_defence() -> void:
	PMChrome.bevel(self, DEF, C_BOX, Color.WHITE, PMChrome.C_TBL_LO, 1.0)
	var hdr := Rect2(DEF.position.x + 4, DEF.position.y + 4, DEF.size.x - 8, 22)
	PMChrome.bevel(self, hdr, C_DEF_HDR, C_DEF_HDR.lightened(0.3), C_DEF_HDR.darkened(0.4))
	_pitch_icon(Rect2(hdr.position.x + 3, hdr.position.y + 3, 22, 16))
	_t_str(_f14, hdr.position.x + 30, hdr.position.y + 3, "DEFENCE", Color.WHITE, 14)

	var y := DEF.position.y + 30
	# TACKLING (3-way)
	y = _band(y, "TACKLING", C_BAND_ORANGE)
	y = _options(y, "tackling", _t.tackling,
		[["Soft", "SOFT"], ["Medium", "MEDIUM"], ["Aggressive", "AGGR"]])
	# MARKING (2-way)
	y = _band(y, "MARKING", C_BAND_RED)
	y = _options(y, "marking", _t.marking, [["Zonal", "ZONAL"], ["Man-to-man", "MAN TO MAN"]])
	# CLEARANCES (2-way)
	y = _band(y, "CLEARANCES", C_BAND_RED)
	y = _options(y, "clearances", _t.clearances, [["Short", "SHORT"], ["Long", "LONG"]])
	# PRESSURISE FROM (3-way)
	y = _band(y, "PRESSURISE FROM...", C_BAND_RED)
	y = _options(y, "pressurise", _t.pressurise,
		[["Own", "OWN"], ["Midfield", "MIDFIELD"], ["Opponent", "OPPONENT"]])


## A coloured section band; returns the y just below it.
func _band(y: float, label: String, col: Color) -> float:
	var r := Rect2(DEF.position.x + 8, y, DEF.size.x - 16, 13)
	PMChrome.bevel(self, r, col, col.lightened(0.3), col.darkened(0.4))
	_t_str(_f10, r.position.x, r.position.y + 1, label, Color.WHITE, 11, 1, r.size.x)
	return y + 14


## A radio row: N options spread across the DEFENCE width, each a checkbox + label,
## the selected one ticked. Returns the y below the row.
func _options(y: float, kind: String, current: String, opts: Array) -> float:
	var n := opts.size()
	var colw := (DEF.size.x - 16) / float(n)
	for i in n:
		var opt: Array = opts[i]
		var cx := DEF.position.x + 8 + i * colw
		var hit := Rect2(cx, y, colw, 22)
		_check(Rect2(cx + 4, y + 2, 13, 13), current == opt[0])
		_t_str(_f8, cx + 20, y + 3, opt[1], C_TXT, 10)
		_hit(hit, kind, opt[0])
	return y + 24


# ---- glyphs --------------------------------------------------------------

func _check(r: Rect2, on: bool) -> void:
	PMChrome.bevel(self, r, C_CHK if on else C_BOX, (C_CHK if on else C_BOX).lightened(0.3),
		(C_CHK if on else C_BOX).darkened(0.4))
	if on:
		var p := r.position
		var e := r.end
		draw_line(p + Vector2(3, 3), e - Vector2(3, 3), Color.WHITE, 2.0)
		draw_line(Vector2(e.x - 3, p.y + 3), Vector2(p.x + 3, e.y - 3), Color.WHITE, 2.0)


func _arrow(r: Rect2, col: Color) -> void:
	var cy := r.get_center().y
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x, cy - r.size.y * 0.5), Vector2(r.end.x, cy),
		Vector2(r.position.x, cy + r.size.y * 0.5)]), col)


func _pitch_icon(r: Rect2) -> void:
	draw_rect(r, Color(0.16, 0.43, 0.27), true)
	draw_rect(r, Color.WHITE, false, 1.0)
	draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Color.WHITE, 1.0)
	draw_arc(r.get_center(), r.size.y * 0.22, 0, TAU, 10, Color.WHITE, 1.0)


func _stepper(r: Rect2, glyph: String, kind: String) -> void:
	PMChrome.bevel(self, r, C_BTN, C_BTN.lightened(0.3), C_BTN.darkened(0.4))
	_t_str(_f12, r.position.x, r.position.y, glyph, C_GOLD, 13, 1, r.size.x)
	_hit(r, kind, null)


func _button(r: Rect2, label: String, col: Color, kind: String, value: Variant, sz := 12, framed := false) -> void:
	PMChrome.bevel(self, r, PMChrome.C_PLAQUE, PMChrome.C_PLAQUE_HI, PMChrome.C_PLAQUE_LO)
	if framed:
		draw_rect(Rect2(r.position - Vector2(2, 2), r.size + Vector2(4, 4)), C_NO, false, 2.0)
	_t_str(_f12, r.position.x, r.position.y + (r.size.y - sz) * 0.5, label, col, sz, 1, r.size.x)
	_hit(r, kind, value)


func _hit(r: Rect2, kind: String, value: Variant) -> void:
	_hits.append({"r": r, "kind": kind, "value": value})


# ---- input ---------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed or _t == null:
		return
	var local: Vector2 = event.position
	var dp := (local - _origin) / _scale   # to design space
	for h in _hits:
		if (h["r"] as Rect2).has_point(dp):
			_apply(str(h["kind"]), h["value"])
			return
	accept_event()


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
		"ok", "return":
			done.emit()
			return
		"save":
			save_requested.emit(_t.to_dict())
			return
	changed.emit(_t.to_dict())
	queue_redraw()
