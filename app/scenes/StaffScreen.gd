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
## wage:int}. When empty the screen shows the pristine baked frame, i.e. the WITNESSED
## reference staff (frame 121's real Man Utd backroom) — an explicit honest-gap
## placeholder until a per-club PM98 staff DB is extracted (see WIRING note below).
##
## WIRING (Main.gd owns this; NOT edited here):
##   _show_staff_screen should call
##     scr.setup(personnel, manager, club, season, week, club_id)
##   where `personnel` is the managed club's real backroom (13 role keys) once the
##   EMPLEADOS staff DB is reversed; until then pass {} for the witnessed reference.
##   Connect: back_pressed -> dismiss (works today); role_selected(role) -> the hire
##   overlay (frames 113-120, not yet built); sign_pressed / sack_pressed -> the
##   selected-role hire/sack. The old hire_requested / sack_requested / training_requested
##   signals are RETAINED below purely so the current unmodified Main.connect calls do
##   not fault; they are never emitted (this kills the invented TRAINING browse).

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

var _fname: Font        # staff name + wage amount (proman)
var _star_on := Color8(255, 210, 40)
var _star_off := Color8(70, 70, 84)
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

## A small filled 5-point star, top-left cell at (x,y), width ~w. `on` = gold else off.
func _star(cx: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.42
		pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
	draw_colored_polygon(pts, col)

## Draw a 0..5 rating in 0.5 steps, right-anchored ending at x_right, centred on y.
func _stars(x_right: float, y_top: float, rating: float, bar_col: Color) -> void:
	var step := 9.0
	var r := 4.0
	var full := int(floor(rating))
	var half := (rating - full) >= 0.5
	var cy := y_top + 6.0
	for i in 5:
		var cx := x_right - (5 - i) * step + step * 0.5
		if i < full:
			_star(cx, cy, r, _star_on)
		elif i == full and half:
			# gold star with the right half masked back to the bar colour
			_star(cx, cy, r, _star_on)
			draw_rect(Rect2(cx, cy - r - 1, r + 2, 2 * r + 2), bar_col, true)
		else:
			_star(cx, cy, r, _star_off)

func _draw_slot(role: String, data: Dictionary) -> void:
	var slot: Dictionary = _slots.get(role, {})
	if slot.is_empty():
		return
	var b: Array = slot["bar"]
	var bar := Rect2(b[0], b[1], b[2], b[3])
	var bc: Array = slot.get("bar_color", [60, 60, 90])
	var bar_col := Color8(bc[0], bc[1], bc[2])
	# repaint the bar (grown a few px to cover the baked name + stars so a different
	# club's staff can replace them) and blank the baked £amount cell (white row bg) —
	# the red "WAGE" label stacked above it is baked static and kept.
	draw_rect(Rect2(bar.position.x - 7, bar.position.y - 1, bar.size.x + 9, bar.size.y + 2), bar_col, true)
	var war := float(slot["wage_amount_right"])
	draw_rect(Rect2(war - 100, float(slot["wage_amount_y"]) - 2, 108, 13), Color8(255, 255, 255), true)
	# name (white, left-inset in the bar)
	_txt_left(float(slot["name_x"]), float(slot["name_y"]) - 1,
		str(data.get("name", "")), _c_name, 11)
	# stars (gold half-steps), right-inset in the bar
	_stars(float(slot["stars_right"]), float(slot["stars_y"]), float(data.get("stars", 0.0)), bar_col)
	# wage £amount (black), right-anchored; the red "WAGE" label is baked static
	_txt_right(float(slot["wage_amount_right"]), float(slot["wage_amount_y"]),
		_money(int(data.get("wage", 0))), _c_wage, 11)

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	if _body != null:
		draw_texture(_body, Vector2(0, _body_y))
	PMChrome.draw_header(self, "CLUB PERSONNEL", _manager, _club, _league, _season, _week, _club_id)

	# Live values over the baked cells. Empty _personnel -> pristine baked frame, i.e.
	# the witnessed reference staff (honest-gap placeholder; NOT redrawn/covered).
	if not _personnel.is_empty():
		for role in _slots:
			var d: Variant = _personnel.get(role, null)
			if d is Dictionary:
				_draw_slot(role, d)

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
