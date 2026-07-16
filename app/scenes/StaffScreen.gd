extends Control
class_name StaffScreen
## PM98 CLUB PERSONNEL (EMPLEADOS / staff) screen — the Main Menu's EMPLE icon.
## REBUILT FRAME-TRUE (2026-07-13) from the real MANAGER.EXE walkthrough, replacing
## the earlier strings-only substitute (audit APP_VS_SPEC_AUDIT.md B1: "strings-only,
## NO reversed layout" + an invented TRAINING browse).
##
## Binding frame: screenshots/original-walkthrough-2026-07-02/121_154736.png (run1
## 15:47:36; hire overlay witnessed in 113-120). The static chrome is the ORIGINAL
## frame's pixels below the barra, cut 1:1 by tools/re/build_staff_chrome_from_frames.py
## into art/screens/staff/personnel_body.png; this scene draws that at 640x480, the
## shared header live on top (PMChrome.draw_header, so club/manager/date track the
## career), and the 13 staff value cells over the baked cells from `personnel` data.
##
## Real layout (docs/re/staff_re.md): a TRAINING STAFF panel = 2 cols x 3 rows of skill
## trainers (HANDLING / PASSING / DRIBBLING / HEADING / TACKLING / SHOOTING), each a
## blue skill label over a colour name bar (name + gold half-stars) + a red WAGE /
## £amount; then seven role cards laid out MIRRORED left/right with the portrait on the
## OUTER edge — left col PHYSIOTHERAPIST / ASSISTANT MANAGER / YOUTH TEAM MANAGER /
## GROUNDSMAN, right col PSYCHOLOGIST / SCOUT / YOUTH TEAM SCOUT — plus SIGN / SACK /
## RETURN. Every label, portrait and button is baked frame pixels; nothing invented.
##
## VALUES: `personnel` maps each of the 13 role keys -> {name, stars(0..5, .5 steps),
## wage:int} for roles the MANAGER HAS HIRED. A PM98 career opens with NO staff
## (Career.staff == []) and the manager signs them from a pool; AI/rival clubs have no
## staff at all, so there is NO per-club staff DB (and none is needed). Every unfilled
## role is drawn VACANT (empty bar, no name/stars/£ — frame 115's empty state); the
## baked body is frame 121 (a fully-hired club), so its baked staff MUST be blanked per
## slot or it would show as staff the manager never hired. Only hired roles are painted.
##
## WIRING (Main.gd owns this; NOT edited here):
##   _show_staff_screen calls scr.setup(...) with the manager's hired staff (empty at
##   career start -> all slots vacant, which is correct). Connect: back_pressed ->
##   dismiss (works today); role_selected(role) -> the hire overlay (frames 110-120,
##   NOT yet built); sign_pressed / sack_pressed -> the selected-role hire/sack. The old
##   hire_requested / sack_requested / training_requested signals are RETAINED below so
##   the current Main.connect calls do not fault; never emitted (kills the invented
##   TRAINING browse). NOTE: the Career staff MODEL has only 5 roles (TRAINER/PHYSIO/
##   YOUTH_COACH/SCOUT/ASSISTANT) vs the real game's 13 — expanding it + building the
##   hire overlay is the remaining staff work (see docs/re/staff_re.md).

# --- new signals (frame-true interactions) ---
signal role_selected(role: String)     # tap a role/skill card -> open the hire overlay
signal sign_pressed                     # SIGN button
signal sack_pressed                     # SACK button
signal back_pressed                     # RETURN button -> Main dismisses

# --- RETAINED for Main compatibility (NOT emitted; see WIRING note) ---
signal hire_requested(cand_id: int)
signal sack_requested(member_id: int)
signal training_requested

const W := 640
const H := 480

var _body: Texture2D
var _spec: Dictionary = {}
var _slots: Dictionary = {}
var _buttons: Dictionary = {}
var _body_y := 58

var _fname: Font        # staff name (proman)
var _f8: Font           # wage amount (proman8 = the original's wage face, cap 8px)
var _star_on := Color8(255, 210, 40)
var _c_name := Color8(255, 255, 255)
var _c_wage := Color8(0, 0, 0)

var _personnel: Dictionary = {}     # role -> {name,stars,wage}; empty -> pristine baked ref
var _ref: Dictionary = {}           # witnessed reference (frame 121), from the chrome JSON
var _manager := ""
var _club := ""
var _league := "Premier League"
var _season := "1997-98"
var _week := 1
var _club_id := -1
var _press := ""


func _ready() -> void:
	_body = load("res://art/screens/staff/personnel_body.png")
	_fname = PMChrome.font("10")
	_f8 = PMChrome.font("8")
	var f := FileAccess.open("res://art/screens/staff/personnel_chrome.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spec = parsed
			_slots = _spec.get("slots", {})
			_buttons = _spec.get("buttons", {})
			_body_y = int(_spec.get("body_y", 58))
			_ref = _spec.get("ref_staff", {})
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed live staff + header chrome, then repaint. `personnel` is a Dictionary keyed by
## the 13 role ids; anything else (e.g. the pre-rebuild Main call's Array) is treated as
## "no live data" -> the pristine witnessed reference render. Untyped params so the old
## Main.setup call cannot fault (see WIRING note).
func setup(personnel = {}, manager = "", club = "", season = "", week = 0, club_id = -1) -> void:
	_personnel = personnel if personnel is Dictionary else {}
	if manager is String and manager != "":
		_manager = manager
	elif _manager == "":
		_manager = "MWM"                        # witnessed default (frame 121)
	if club is String and club != "":
		_club = club
	elif _club == "":
		_club = "Manchester Utd."               # witnessed default (frame 121)
	if season is String and season != "":
		_season = season
	if typeof(week) == TYPE_INT and int(week) > 0:
		_week = int(week)
	if typeof(club_id) == TYPE_INT:
		_club_id = int(club_id)
	queue_redraw()


# ---- geometry / input ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

## The tap card for a slot: the name bar grown to cover its name/stars + the WAGE block.
func _card_rect(slot: Dictionary) -> Rect2:
	var b: Array = slot.get("bar", [0, 0, 0, 0])
	var x := float(b[0]) - 6.0
	var w := float(b[2]) + 78.0
	if slot.get("mirror", false):
		x = float(b[0]) - 72.0
		w = float(b[2]) + 78.0
	return Rect2(x, float(b[1]) - 4.0, w, float(b[3]) + 8.0)

func _hit(d: Vector2) -> String:
	for name in _buttons:
		var r: Array = _buttons[name]
		if Rect2(r[0], r[1], r[2], r[3]).has_point(d):
			return "btn:" + str(name)
	for role in _slots:
		if _card_rect(_slots[role]).has_point(d):
			return "role:" + str(role)
	return ""

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var pressed := (e as InputEventMouseButton).pressed if e is InputEventMouseButton \
		else (e as InputEventScreenTouch).pressed
	var pos: Vector2 = (e as InputEventMouseButton).position if e is InputEventMouseButton \
		else (e as InputEventScreenTouch).position
	var d := _to_design(pos)
	if pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	if was == "btn:return":
		back_pressed.emit()
	elif was == "btn:sign":
		sign_pressed.emit()
	elif was == "btn:sack":
		sack_pressed.emit()
	elif was.begins_with("role:"):
		role_selected.emit(was.substr(5))


# ---- drawing -------------------------------------------------------------

func _money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + "£" + out

func _txt_left(x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if _fname == null:
		return
	draw_string(_fname, Vector2(x, y_top + _fname.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _txt_right(x_right: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if _fname == null:
		return
	var w := _fname.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(_fname, Vector2(x_right - w, y_top + _fname.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

## Wage amount: centred on cx with its glyph TOP at y_top (frame-measured), in the
## game face the original uses for every wage cell — proman8 at its native 11pt.
## The original centres the INK box, not the advance box (frame 121: £45,000 ink
## x241..291 centre 266.0 and £16,000 ink x242..289 centre 265.5 share one cx), so
## the pen x comes from the per-char ink insets baked in wage_font_metrics.
## Verified vs frame 121: row-profile identical (baseline = glyph top + 7).
func _txt_center(cx: float, y_top: float, s: String, col: Color) -> void:
	if _f8 == null:
		return
	var pen := cx - _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2.0
	var fm: Dictionary = _spec.get("wage_font_metrics", {})
	if not fm.is_empty() and s.length() > 0 and fm.has(s[0]) and fm.has(s[s.length() - 1]):
		var adv := 0
		for i in s.length() - 1:
			adv += int((fm.get(s[i], [8, 0, 7]) as Array)[0])
		var ink_x0 := float((fm[s[0]] as Array)[1])
		var ink_x1 := float(adv + int((fm[s[s.length() - 1]] as Array)[2]))
		pen = cx - (ink_x0 + ink_x1) / 2.0
	# half-pixel centres floor (frame 121: £16,000 pen 242 from cx−23.5 = 242.5)
	draw_string(_f8, Vector2(floorf(pen), y_top + 7), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

## A small filled 5-point star, top-left cell at (x,y), width ~w. `on` = gold else off.
func _star(cx: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.42
		pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
	draw_colored_polygon(pts, col)

## Draw a 0..5 rating in 0.5 steps, LEFT-anchored from first_cx stepping right. The
## original (frame 121_154736) draws ONLY the earned gold stars (+ a left-half for the .5) —
## NO grey placeholder stars — and unfilled slots stay bare. Measured off frame 121: step
## 11px, star centres left-anchored (first_cx = stars_right - 53.5 for skill-trainer bars,
## - 49.0 for role cards; the caller supplies first_cx).
func _stars(first_cx: float, y_top: float, rating: float, bar_col: Color) -> void:
	var step := 11.0
	var r := 4.0
	var full := int(floor(rating))
	var half := (rating - full) >= 0.5
	var cy := y_top + 6.0
	for i in full:
		_star(first_cx + i * step, cy, r, _star_on)
	if half:
		# gold star with the right half masked back to the bar colour
		var cx := first_cx + full * step
		_star(cx, cy, r, _star_on)
		draw_rect(Rect2(cx, cy - r - 1, r + 2, 2 * r + 2), bar_col, true)

## Repaint a slot's name-bar (erasing frame 121's baked name + stars) and blank the
## baked £amount cell. The red "WAGE" label stacked above the amount is baked static
## and kept. Left role cards (kind=role, not mirrored) have their baked name overhanging
## the measured `bar` to the LEFT by ~30px (portrait ends x49, name starts x50, but
## bar.x=80), so grow the left edge to cover it without clipping the portrait.
func _blank_bar(slot: Dictionary) -> Color:
	var b: Array = slot["bar"]
	var bar := Rect2(b[0], b[1], b[2], b[3])
	var bc: Array = slot.get("bar_color", [60, 60, 90])
	var bar_col := Color8(bc[0], bc[1], bc[2])
	var left_grow := 7
	if str(slot.get("kind", "")) == "role":
		# Mirrored role cards: the wage cell abuts the bar's LEFT edge (cell ends
		# x413, bar starts x415) — growing left would paint bar colour over the
		# cell's right columns (frame 121 keeps them white). Nothing is baked
		# there, so no grow is needed on that side.
		left_grow = 0 if bool(slot.get("mirror", false)) else 30
	# Right extension: +1 on non-mirrored bars — their wage cell starts one column
	# past the bar (role-L cell x218, bar ends x217; trainer-L cell x242, bar ends
	# x241) and frame 121 keeps that first cell column white. Mirrored bars keep +2
	# (nothing abuts their right edge but the baked portrait shadow).
	var right_grow := 2 if bool(slot.get("mirror", false)) else 1
	draw_rect(Rect2(bar.position.x - left_grow, bar.position.y - 1,
		bar.size.x + left_grow + right_grow, bar.size.y + 2), bar_col, true)
	var wc: Array = slot["wage_cell"]
	draw_rect(Rect2(wc[0], wc[1], wc[2], wc[3]), Color8(255, 255, 255), true)
	return bar_col

## A role with no one hired: blank the bar + £cell, drawing nothing (frame-115 vacant).
func _draw_vacant(role: String) -> void:
	var slot: Dictionary = _slots.get(role, {})
	if slot.is_empty():
		return
	_blank_bar(slot)

func _draw_slot(role: String, data: Dictionary) -> void:
	var slot: Dictionary = _slots.get(role, {})
	if slot.is_empty():
		return
	var bar_col := _blank_bar(slot)
	# name (white, left-inset in the bar)
	_txt_left(float(slot["name_x"]), float(slot["name_y"]) - 1,
		str(data.get("name", "")), _c_name, 11)
	# stars (gold half-steps), left-anchored: first centre = stars_right - offset (measured
	# off frame 121: 53.5 for skill-trainer bars, 49.0 for role cards)
	var star_off := 53.5 if str(slot.get("kind", "")) == "train" else 49.0
	_stars(float(slot["stars_right"]) - star_off, float(slot["stars_y"]),
		float(data.get("stars", 0.0)), bar_col)
	# wage £amount (black), CENTERED in its cell like the original (frame-121 bboxes:
	# role-L values share cx≈266 while their right edges differ — NOT right-aligned)
	_txt_center(float(slot["wage_cx"]), float(slot["wage_top"]),
		_money(int(data.get("wage", 0))), _c_wage)

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	if _body != null:
		draw_texture(_body, Vector2(0, _body_y))
	PMChrome.draw_header(self, "CLUB PERSONNEL", _manager, _club, _league, _season, _week, _club_id)

	# Live values over the baked cells. The baked body is frame 121 (a fully-hired club),
	# so EVERY unfilled role must be blanked to the vacant state (frame 115: empty bar, no
	# name/stars, no £amount) — otherwise frame 121's baked staff would show as staff the
	# manager never hired. A real career opens with NO staff (Career.staff == []) and the
	# manager signs them from the pool; only hired roles are drawn.
	for role in _slots:
		var d: Variant = _personnel.get(role, null)
		if d is Dictionary:
			_draw_slot(role, d)
		else:
			_draw_vacant(role)

	# button press feedback (buttons themselves are baked)
	if _press.begins_with("btn:"):
		var bn := _press.substr(4)
		if _buttons.has(bn):
			var r: Array = _buttons[bn]
			draw_rect(Rect2(r[0], r[1], r[2], r[3]), Color(1, 1, 1, 0.2), true)
	elif _press.begins_with("role:"):
		draw_rect(_card_rect(_slots.get(_press.substr(5), {})), Color(1, 1, 1, 0.15), true)


## The witnessed reference staff (frame 121), for the render-shot + tests. Source, not
## invented — see tools/re/build_staff_chrome_from_frames.py REF_STAFF.
func reference_staff() -> Dictionary:
	return _ref.duplicate(true)
