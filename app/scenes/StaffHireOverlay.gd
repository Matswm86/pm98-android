extends Control
class_name StaffHireOverlay
## PM98 CLUB PERSONNEL hire overlay — the modal dialog that opens when a role card on the
## StaffScreen (EMPLE) is tapped. Frame-baked from the live walkthrough (docs/re/staff_re.md).
## TWO witnessed layouts:
##
## SINGLE-ROLE (frames 108/110/113/114/115/117/119): one CURRENT-<role> box + a
## "<ROLE>s AVAILABLE" pool with green SIGN buttons. Each of the 7 single-role categories
## (PHYSIOTHERAPIST / PSYCHOLOGIST / ASSISTANT_MANAGER / SCOUT / YOUTH_TEAM_MANAGER /
## YOUTH_TEAM_SCOUT / GROUNDSMAN) has its OWN baked plate art/screens/staff/overlay_<cat>.png
## with the correct baked CURRENT/AVAILABLE header wording (irregular in the original —
## "SCOUTS YOUTH TEAM AVAILABLE" — so baked, never generated) + its active-red rail button.
##
## TRAINERS (frame 100): the 6 skill coaches shown at once — a CURRENT TRAINING STAFF list
## (HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/SHOOTING) + a STAFF AVAILABLE pool filtered
## by a 2x3 skill picker. Plate art/screens/staff/overlay_trainers.png. The witnessed
## DRIBBLING blue-glow (selected filter) + HEADING focus-ring are neutralised in the bake;
## the live selected-skill highlight is an APPROXIMATION of the glow (only DRIBBLING-selected
## was ever witnessed, so a per-skill bake is impossible — docs/re/staff_re.md).
##
## The scene draws the baked plate + a dimming scrim, then redraws ONLY the live career data:
## the CURRENT holder(s) (name/half-stars/£wage) and up to three candidate rows from the pool.
## The right rail switches category; a green SIGN button signs a candidate; OK closes. Nothing
## here is invented.

signal category_selected(category: String)   # a right-rail category button tapped
signal sign_candidate(cand_id: int)           # a green SIGN button tapped
signal ok_pressed                             # OK / tap-outside -> close
signal skill_selected(skill: String)          # TRAINERS: a skill-picker button tapped

const W := 640
const H := 480

var _spec: Dictionary = {}
var _s: Dictionary = {}                 # the single-role layout spec
var _t: Dictionary = {}                 # the TRAINERS layout spec
var _mode := "single"                    # "single" | "trainers"
var _plate: Texture2D
var _cat := "PHYSIOTHERAPIST"
var _holder: Dictionary = {}            # single: {name, stars, wage} or {} when vacant
var _coaches: Dictionary = {}           # trainers: skill -> {name, stars, wage} (hired only)
var _skill := "HANDLING"                # trainers: selected skill filter
var _cands: Array = []                   # [{id, name, stars, wage}, ...] from the hire pool
var _press := ""

var _fname: Font
var _star_on := Color8(255, 210, 40)
var _c_black := Color8(0, 0, 0)
var _c_white := Color8(255, 255, 255)
var _c_green := Color8(127, 191, 85)


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
			_t = _spec.get("trainers", {})


func _ready() -> void:
	_ensure_loaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Show the overlay for `category`. For the 7 single-role categories pass the currently-hired
## `holder` ({} if vacant) and the `candidates` pool. For "TRAINERS" pass `coaches`
## (skill -> {name, stars, wage} for each hired coach), the `selected_skill`, and `candidates`
## = the pool for that skill. Untyped-safe.
func setup(category = "PHYSIOTHERAPIST", holder = {}, candidates = [],
		coaches = {}, selected_skill = "") -> void:
	_ensure_loaded()
	var c := str(category).to_upper()
	_cands = candidates if candidates is Array else []
	if c == "TRAINERS":
		_mode = "trainers"
		_cat = "TRAINERS"
		_coaches = coaches if coaches is Dictionary else {}
		var skills: Array = _t.get("skills", [])
		var sk := str(selected_skill).to_upper()
		_skill = sk if sk in skills else (str(skills[0]) if not skills.is_empty() else "HANDLING")
		var pth: String = str(_t.get("plate", ""))
		_plate = load("res://art/screens/staff/" + pth) if pth != "" else null
		queue_redraw()
		return
	_mode = "single"
	_cat = c if c in _s.get("cats", []) else "PHYSIOTHERAPIST"
	_holder = holder if holder is Dictionary else {}
	var plates: Dictionary = _s.get("plates", {})
	var path: String = str(plates.get(_cat, ""))
	_plate = load("res://" + "art/screens/staff/" + path) if path != "" else null
	queue_redraw()


# ---- geometry / input ----------------------------------------------------

func _cur_spec() -> Dictionary:
	return _t if _mode == "trainers" else _s

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _rail_rect(i: int) -> Rect2:
	var r: Dictionary = _cur_spec().get("rail", {})
	return Rect2(int(r.get("x", 452)), int(r.get("y0", 104)) + i * int(r.get("pitch", 30)),
		int(r.get("w", 123)), int(r.get("h", 22)))

func _skill_rect(i: int) -> Rect2:
	var b: Array = _t.get("picker", {}).get("rects", [])[i]
	return Rect2(b[0], b[1], b[2], b[3])

func _sign_rect(i: int) -> Rect2:
	var arr: Array = _cur_spec().get("avail" if _mode == "trainers" else "rows", {}).get("sign", [])
	var b: Array = arr[i]
	return Rect2(b[0], b[1], b[2], b[3])

func _hit(d: Vector2) -> String:
	var cats: Array = _cur_spec().get("cats", [])
	for i in cats.size():
		if _rail_rect(i).has_point(d):
			return "cat:" + str(cats[i])
	var ok: Array = _cur_spec().get("ok", [0, 0, 0, 0])
	if Rect2(ok[0], ok[1], ok[2], ok[3]).has_point(d):
		return "ok"
	if _mode == "trainers":
		var skills: Array = _t.get("skills", [])
		for i in mini(skills.size(), _t.get("picker", {}).get("rects", []).size()):
			if _skill_rect(i).has_point(d):
				return "skill:" + str(i)
		var asign: Array = _t.get("avail", {}).get("sign", [])
		for r in mini(asign.size(), _cands.size()):
			if _sign_rect(r).has_point(d):
				return "sign:" + str(r)
	else:
		var signs: Array = _s.get("rows", {}).get("sign", [])
		for r in mini(signs.size(), _cands.size()):
			if _sign_rect(r).has_point(d):
				return "sign:" + str(r)
	# a tap outside the dialog dismisses (matches the original modal)
	var dlg: Array = _cur_spec().get("dialog", [67, 63, 525, 352])
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
		category_selected.emit(c)
	elif was.begins_with("skill:"):
		var si := int(was.substr(6))
		var skills: Array = _t.get("skills", [])
		if si >= 0 and si < skills.size() and str(skills[si]) != _skill:
			skill_selected.emit(str(skills[si]))
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

## A 0..5 rating in 0.5 steps, left-aligned in a 5-slot zone ending at x_right, over
## background `bg`. The original draws ONLY the earned gold stars (+ a left-half for the
## .5) — NO grey placeholder stars (witnessed frames 100 + 113), so empty slots draw nothing.
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
			draw_rect(Rect2(cx, cy - r - 1, r + 2, 2 * r + 2), bg, true)   # erase right half

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45), true)   # dimming scrim
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _plate != null:
		var dlg: Array = _cur_spec().get("dialog", [67, 63, 525, 352])
		draw_texture(_plate, Vector2(dlg[0], dlg[1]))
	if _mode == "trainers":
		_draw_trainers()
	else:
		_draw_single()
	_draw_press()

func _draw_single() -> void:
	# CURRENT holder (name + half-stars + £wage), over the baked-empty box. Vacant -> nothing.
	if not _holder.is_empty():
		var h: Dictionary = _s.get("holder", {})
		_txt_left(float(h["name_x"]), float(h["name_y"]), str(_holder.get("name", "")), _c_black, 11)
		_stars(float(h["stars_right"]), float(h["stars_y"]), float(_holder.get("stars", 0.0)),
			_c_white)
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

func _draw_trainers() -> void:
	# CURRENT TRAINING STAFF: all 6 skill coaches (white name on the baked coloured bar,
	# gold half-stars, right-aligned black £wage on the white panel). Vacant -> nothing.
	var cur: Dictionary = _t.get("current", {})
	var tops: Array = cur.get("tops", [])
	var bcol: Array = cur.get("bar_col", [])
	var skills: Array = _t.get("skills", [])
	for i in mini(tops.size(), skills.size()):
		var sk := str(skills[i])
		if not _coaches.has(sk):
			continue
		var m: Dictionary = _coaches[sk]
		var top := int(tops[i])
		var bg := _c_white
		if i < bcol.size():
			bg = Color8(int(bcol[i][0]), int(bcol[i][1]), int(bcol[i][2]))
		_txt_left(float(cur["name_x"]), top - 2, str(m.get("name", "")), _c_white, 11)
		_stars(float(cur["stars_right"]), top - 1, float(m.get("stars", 0.0)), bg)
		_txt_right(float(cur["wage_right"]), top - 2, _money(int(m.get("wage", 0))), _c_black, 11)
	# STAFF AVAILABLE: up to 3 candidates for the selected skill (black name on green, gold
	# half-stars, right £wage on the grey panel). SIGN buttons are baked.
	var av: Dictionary = _t.get("avail", {})
	var atops: Array = av.get("tops", [])
	for r in mini(atops.size(), _cands.size()):
		var cand: Dictionary = _cands[r]
		var top := int(atops[r])
		_txt_left(float(av["name_x"]), top - 2, str(cand.get("name", "")), _c_black, 11)
		_stars(float(av["stars_right"]), top - 1, float(cand.get("stars", 0.0)), _c_green)
		_txt_right(float(av["wage_right"]), top - 2, _money(int(cand.get("wage", 0))), _c_black, 11)
	# Selected-skill highlight (APPROXIMATED glow: only DRIBBLING-selected was witnessed).
	var si := skills.find(_skill)
	if si >= 0 and si < _t.get("picker", {}).get("rects", []).size():
		var rr := _skill_rect(si)
		draw_rect(rr, Color(0.10, 0.0, 0.62, 0.45), true)
		draw_rect(rr, Color(0.45, 0.62, 1.0, 0.9), false)

func _draw_press() -> void:
	if _press.begins_with("cat:"):
		var cats: Array = _cur_spec().get("cats", [])
		var i := cats.find(_press.substr(4))
		if i >= 0:
			draw_rect(_rail_rect(i), Color(1, 1, 1, 0.20), true)
	elif _press.begins_with("skill:"):
		draw_rect(_skill_rect(int(_press.substr(6))), Color(1, 1, 1, 0.20), true)
	elif _press.begins_with("sign:"):
		draw_rect(_sign_rect(int(_press.substr(5))), Color(1, 1, 1, 0.25), true)
	elif _press == "ok":
		var ok: Array = _cur_spec().get("ok", [0, 0, 0, 0])
		draw_rect(Rect2(ok[0], ok[1], ok[2], ok[3]), Color(1, 1, 1, 0.20), true)
