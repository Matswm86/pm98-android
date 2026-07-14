extends Control
class_name StaffHireOverlay
## PM98 CLUB PERSONNEL hire overlay — the modal dialog that opens when a role card on the
## StaffScreen (EMPLE) is tapped. Frame-baked from the live walkthrough (docs/re/staff_re.md);
## binding frames 108/110/113/114/115/117/119 (single-role) + 100 (TRAINERS, phase 2).
##
## Each single-role category (PHYSIOTHERAPIST / PSYCHOLOGIST / ASSISTANT_MANAGER / SCOUT /
## YOUTH_TEAM_MANAGER / YOUTH_TEAM_SCOUT / GROUNDSMAN) has its OWN baked plate
## art/screens/staff/overlay_<cat>.png: the ORIGINAL frame's pixels with the correct baked
## CURRENT/AVAILABLE header wording (irregular in the original — "SCOUTS YOUTH TEAM AVAILABLE"
## — so baked, never generated) + its active-red rail button, and the career-dynamic zones
## (current holder, candidate rows, £amounts) blanked. This scene draws that plate + the shared
## dimming scrim, then redraws ONLY the live data: the CURRENT holder (name/half-stars/£wage)
## and up to three candidate rows from the hire pool. The right rail switches category; a green
## SIGN button signs that candidate; OK closes. Nothing here is invented.

signal category_selected(category: String)   # a right-rail category button tapped
signal sign_candidate(cand_id: int)           # a green SIGN button tapped
signal ok_pressed                             # OK / tap-outside -> close
signal skill_selected(skill: String)          # TRAINERS layout (phase 2; unused for now)

const W := 640
const H := 480

var _spec: Dictionary = {}
var _s: Dictionary = {}                 # the "single" layout spec
var _plate: Texture2D
var _cat := "PHYSIOTHERAPIST"
var _holder: Dictionary = {}            # {name, stars, wage} or {} when the slot is vacant
var _cands: Array = []                   # [{id, name, stars, wage}, ...] from the hire pool
var _press := ""

var _fname: Font
var _star_on := Color8(255, 210, 40)
var _star_off := Color8(70, 70, 84)
var _c_black := Color8(0, 0, 0)


func _ensure_loaded() -> void:
	if not _s.is_empty():
		return
	_fname = PMChrome.font("10")
	var f := FileAccess.open("res://art/screens/staff/overlay_chrome.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spec = parsed
			_s = _spec.get("single", {})


func _ready() -> void:
	_ensure_loaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Show the overlay for `category`, with the currently-hired holder ({} if vacant) and the
## pool of hireable candidates for that role. Untyped-safe.
func setup(category = "PHYSIOTHERAPIST", holder = {}, candidates = []) -> void:
	_ensure_loaded()
	var c := str(category).to_upper()
	_cat = c if c in _s.get("cats", []) else "PHYSIOTHERAPIST"
	_holder = holder if holder is Dictionary else {}
	_cands = candidates if candidates is Array else []
	var plates: Dictionary = _s.get("plates", {})
	var path: String = str(plates.get(_cat, ""))
	_plate = load("res://" + "art/screens/staff/" + path) if path != "" else null
	queue_redraw()


# ---- geometry / input ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _rail_rect(i: int) -> Rect2:
	var r: Dictionary = _s.get("rail", {})
	return Rect2(int(r.get("x", 452)), int(r.get("y0", 104)) + i * int(r.get("pitch", 30)),
		int(r.get("w", 123)), int(r.get("h", 22)))

func _hit(d: Vector2) -> String:
	var cats: Array = _s.get("cats", [])
	for i in cats.size():
		if _rail_rect(i).has_point(d):
			return "cat:" + str(cats[i])
	var ok: Array = _s.get("ok", [0, 0, 0, 0])
	if Rect2(ok[0], ok[1], ok[2], ok[3]).has_point(d):
		return "ok"
	var signs: Array = _s.get("rows", {}).get("sign", [])
	for r in mini(signs.size(), _cands.size()):
		var b: Array = signs[r]
		if Rect2(b[0], b[1], b[2], b[3]).has_point(d):
			return "sign:" + str(r)
	# a tap outside the dialog dismisses (matches the original modal)
	var dlg: Array = _s.get("dialog", [67, 63, 525, 352])
	if not Rect2(dlg[0], dlg[1], dlg[2], dlg[3]).has_point(d):
		return "outside"
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
	if was == "ok" or was == "outside":
		ok_pressed.emit()
	elif was.begins_with("cat:"):
		var c := was.substr(4)
		if c == _cat:
			return
		if c == "TRAINERS":
			return   # TRAINERS layout is phase 2; ignore until built
		category_selected.emit(c)
	elif was.begins_with("sign:"):
		var idx := int(was.substr(5))
		if idx >= 0 and idx < _cands.size():
			sign_candidate.emit(int(_cands[idx].get("id", -1)))


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

func _txt_center(cx: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if _fname == null:
		return
	var w := _fname.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(_fname, Vector2(cx - w * 0.5, y_top + _fname.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _star(cx: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.42
		pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
	draw_colored_polygon(pts, col)

## A 0..5 rating in 0.5 steps, right-anchored ending at x_right, over background `bg`.
func _stars(x_right: float, y_top: float, rating: float, bg: Color) -> void:
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
			_star(cx, cy, r, _star_on)
			draw_rect(Rect2(cx, cy - r - 1, r + 2, 2 * r + 2), bg, true)
		else:
			_star(cx, cy, r, _star_off)

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45), true)   # dimming scrim
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _plate != null:
		var dlg: Array = _s.get("dialog", [67, 63, 525, 352])
		draw_texture(_plate, Vector2(dlg[0], dlg[1]))

	# CURRENT holder (name + half-stars + £wage), over the baked-empty box. Vacant -> nothing.
	if not _holder.is_empty():
		var h: Dictionary = _s.get("holder", {})
		_txt_left(float(h["name_x"]), float(h["name_y"]), str(_holder.get("name", "")), _c_black, 11)
		_stars(float(h["stars_right"]), float(h["stars_y"]), float(_holder.get("stars", 0.0)),
			Color8(255, 255, 255))
		_txt_center(float(h["wage_center"]), float(h["wage_y"]),
			_money(int(_holder.get("wage", 0))), _c_black, 11)

	# Candidate rows (up to 3): name (black on grey) + half-stars + right £wage. SIGN is baked.
	var rows: Dictionary = _s.get("rows", {})
	var grey := Color8(220, 220, 220)
	for r in mini(3, _cands.size()):
		var cand: Dictionary = _cands[r]
		var ry := int(rows["name_y"]) + r * int(rows["pitch"])
		_txt_left(float(rows["name_x"]), ry, str(cand.get("name", "")), _c_black, 11)
		_stars(float(rows["stars_right"]), ry, float(cand.get("stars", 0.0)), grey)
		_txt_right(float(rows["wage_right"]), ry, _money(int(cand.get("wage", 0))), _c_black, 11)

	# press feedback
	if _press.begins_with("cat:"):
		var cats: Array = _s.get("cats", [])
		var i := cats.find(_press.substr(4))
		if i >= 0:
			draw_rect(_rail_rect(i), Color(1, 1, 1, 0.20), true)
	elif _press.begins_with("sign:"):
		var b: Array = _s.get("rows", {}).get("sign", [])[int(_press.substr(5))]
		draw_rect(Rect2(b[0], b[1], b[2], b[3]), Color(1, 1, 1, 0.25), true)
	elif _press == "ok":
		var ok: Array = _s.get("ok", [0, 0, 0, 0])
		draw_rect(Rect2(ok[0], ok[1], ok[2], ok[3]), Color(1, 1, 1, 0.20), true)
