extends Control
class_name YouthScreen
## PM98 YOUTH TEAM screen — SQUAD MANAGEMENT's bottom-right YOUTH TEAM button.
## REBUILT FRAME-TRUE (2026-07-16) from the real MANAGER.EXE walkthrough, replacing
## the earlier landscape-list substitute (that layout was ours, not the game's).
##
## Binding frames (docs/re/youth_re.md):
##   087_154632 (run1)  fresh career, NO staff: empty scout/manager bars, SEARCH
##                      CAPABILITY all NO, six dark "disabled" LEDs, pale DISABLED
##                      SEARCH lettering, PLAYERS FOUND = "You need to hire a scout
##                      / to search youth players.", empty 11-row roster,
##                      PARAMETERS selected / RATING unselected.  088 = RATING held
##                      (white ring), 089 = RETURN held (white ring).
##   047_164509 (run3)  scout P. Mitchell (5 gold stars, purple bar), all YES,
##                      "available" LEDs with DRIBBLING/PASSING/SHOOTING toggled
##                      LIT, yellow ENABLED SEARCH, PLAYERS FOUND = "The scout is
##                      now searching for players / with selected capabilities.",
##                      manager G. Keeping (3.5 stars) + "3 PLAYERS", RATING
##                      selected.  048 = SEARCH held (RED ring).
##
## The static chrome is frame 087's own pixels below the barra, cut 1:1 by
## tools/re/build_youth_chrome_from_frames.py into art/screens/youth/youth_body.png
## (only the six YES/NO value cells and the PLAYERS FOUND interior are lifted out —
## they hold live values). PMChrome.draw_header draws the shared barra live.
##
## LIVE LAYERS (anchors frame-measured, youth_chrome.json):
##   scout bar      YOUTH TEAM SCOUT hire (Staff.YOUTH_TEAM_SCOUT): white name +
##                  gold star sprites cut from 047; empty bar baked (no hire).
##   capabilities   NO (black) with no scout / YES (red 210,0,0) with one — the
##                  witnessed pair; a per-skill YES/NO gradient is un-witnessed.
##   LEDs           disabled art baked; "available" + "lit" sprites cut from 047.
##                  Tapping an available LED row toggles that skill's selection.
##   SEARCH         disabled lettering baked; enabled sprite from 047; held = red
##                  ring (048). Emits search_pressed(skills) when armed.
##   PLAYERS FOUND  the two witnessed messages verbatim; the panel's filled list
##                  is un-witnessed and stays an honest gap (found youngsters land
##                  in the roster via Career news — docs/re/youth_re.md).
##   manager bar    YOUTH TEAM MANAGER hire + "N PLAYERS" count (light blue).
##                  Frame 047 shows "3 PLAYERS" over an EMPTY row list — which
##                  counter that is is unresolved; live data uses youth.size()
##                  and the parity oracle pins the witnessed text explicitly.
##   roster rows    11 grey rows (pitch 16). A FILLED row is un-witnessed: values
##                  render in the proman faces under the baked column headers
##                  (SP=VE ST=RE AG=AG QU=CA, AV, ROL=pos; WAGE/YEARS un-modelled,
##                  left empty), documented as reconstruction. Tapping a READY
##                  youngster emits promote_requested(pid) (interaction un-walked).
##   PARAMETERS /   two-state toggle: baked = PARAMETERS selected (087); RATING
##   RATING         mode overlays the 047-cut plaque pair. With the witnessed
##                  empty roster the two modes are row-identical.
##   skill tiles    the bottom-right HANDLING..SHOOTING tile grid is baked static;
##                  its behaviour is un-witnessed — taps are no-ops (honest gap).

signal search_pressed(skills: Array)   # SEARCH armed + tapped (skill keys, cap_order ids)
signal promote_requested(pid: int)     # tap a READY roster row (un-walked interaction)
signal prospect_pressed(pid: int)      # tap a PLAYERS FOUND row -> offer him a contract
signal back_pressed                    # RETURN

const W := 640
const H := 480

var _body: Texture2D
var _spec: Dictionary = {}
var _body_y := 58

var _led_avail: Texture2D
var _led_lit: Texture2D
var _search_on: Texture2D
var _plaq_param_off: Texture2D
var _plaq_rating_on: Texture2D
# the original alternates TWO star sprites along a row (cells 1/3/5 = A, 2/4 = B)
var _star_a_purple: Texture2D
var _star_b_purple: Texture2D
var _star_a_blue: Texture2D
var _star_b_blue: Texture2D
var _star_half_blue: Texture2D
var _held: Dictionary = {}         # held-state ring sprites (frame-cut 048/088/089)

var _f8: Font
var _f10: Font

var _youth: Array = []
var _scout: Dictionary = {}        # YOUTH TEAM SCOUT {name,stars,...}; {} = none
var _ymgr: Dictionary = {}         # YOUTH TEAM MANAGER; {} = none
var _searching := false            # a scout search is running (Career.youth_search)
var _selected: Dictionary = {}     # skill key -> true (LED lit)
var _mode := "parameters"          # "parameters" | "rating" (087 default)
var _manager := ""
var _club := ""
var _league := "Premier League"
var _season := "1997-98"
var _week := 1
var _club_id := -1
var _count_override := -1          # parity oracle only (frame 047's "3 PLAYERS")
var _press := ""
var _row_rects: Array = []
var _found: Array = []             # Career.youth_found — the PLAYERS FOUND shortlist
var _found_rects: Array = []

# PLAYERS FOUND filled list. The panel interior is frame-measured (`pf_interior`); the
# ROW grammar inside it is the app's, because the original's filled panel is not in any
# frame we hold. Kept deliberately plain — name + ability + a potential star count — and
# on the same 16px pitch as every other list in the game.
const PF_ROW_PITCH := 16
const PF_ROW_H := 13
const C_PF_ROW := Color8(222, 228, 240)
const C_PF_ROW_SEL := Color8(255, 226, 128)
const C_PF_INK := Color8(0, 0, 0)
const C_PF_STAR := Color8(196, 138, 0)


func _ready() -> void:
	_body = load("res://art/screens/youth/youth_body.png")
	_led_avail = load("res://art/screens/youth/led_avail.png")
	_led_lit = load("res://art/screens/youth/led_lit.png")
	_search_on = load("res://art/screens/youth/search_on.png")
	_plaq_param_off = load("res://art/screens/youth/plaq_param_off.png")
	_plaq_rating_on = load("res://art/screens/youth/plaq_rating_on.png")
	_star_a_purple = load("res://art/screens/youth/star_a_purple.png")
	_star_b_purple = load("res://art/screens/youth/star_b_purple.png")
	_star_a_blue = load("res://art/screens/youth/star_a_blue.png")
	_star_b_blue = load("res://art/screens/youth/star_b_blue.png")
	_star_half_blue = load("res://art/screens/youth/star_half_blue.png")
	for k in ["search_held", "rating_held", "return_held"]:
		_held[k] = load("res://art/screens/youth/%s.png" % k)
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	var f := FileAccess.open("res://art/screens/youth/youth_chrome.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spec = parsed
			_body_y = int(_spec.get("body_y", 58))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the live youth team + staff + header chrome, then repaint. Backwards
## tolerant with the pre-rebuild Main call shape (youth, manager, club, cash).
func setup(youth: Array, staff = null, manager = "", club = "", season = "",
		week = 0, club_id = -1, searching = false, selected = null, found = null) -> void:
	if found is Array:
		_found = (found as Array).duplicate()
	_youth = youth.duplicate()
	_youth.sort_custom(func(a, b):
		var ra := Youth.is_ready(a)
		var rb := Youth.is_ready(b)
		if ra != rb:
			return ra
		return Youth.ability(a) > Youth.ability(b))
	if staff is Array:
		_scout = Staff.member_in_role(staff, Staff.YOUTH_TEAM_SCOUT)
		_ymgr = Staff.member_in_role(staff, Staff.YOUTH_TEAM_MANAGER)
	if manager is String and manager != "":
		_manager = manager
	if club is String and club != "":
		_club = club
	if season is String and season != "":
		_season = season
	if typeof(week) == TYPE_INT and int(week) > 0:
		_week = int(week)
	if typeof(club_id) == TYPE_INT and int(club_id) >= 0:
		_club_id = int(club_id)
	_searching = bool(searching)
	if selected is Dictionary:
		_selected = (selected as Dictionary).duplicate()
	queue_redraw()


# ---- geometry / input ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _btn_rect(name: String) -> Rect2:
	var b: Dictionary = _spec.get("buttons", {})
	var r: Array = b.get(name, [0, 0, 0, 0])
	return Rect2(r[0], r[1], r[2], r[3])

## The six LED slots in cap_order: left col rows = HANDLING/DRIBBLING/TACKLING,
## right col = PASSING/HEADING/SHOOTING.
func _led_rect(skill: String) -> Rect2:
	var order: Array = _spec.get("cap_order", [])
	var i := order.find(skill)
	if i < 0:
		return Rect2()
	var cols: Dictionary = _spec.get("led_cols", {})
	var rows: Array = _spec.get("led_rows", [])
	var sz: Array = _spec.get("led_size", [25, 16])
	var x := float(cols.get("left", 24)) if i % 2 == 0 else float(cols.get("right", 149))
	@warning_ignore("integer_division")
	var y := float(rows[i / 2])
	return Rect2(x, y, float(sz[0]), float(sz[1]))

## Tap card for a skill toggle: the LED plus its blue label run to the right.
func _led_card(skill: String) -> Rect2:
	var r := _led_rect(skill)
	return Rect2(r.position.x, r.position.y - 1, 112.0, r.size.y + 2)

func _hit(d: Vector2) -> String:
	for bname in ["search", "parameters", "rating", "return"]:
		if _btn_rect(bname).has_point(d):
			return "btn:" + bname
	for skill in _spec.get("cap_order", []):
		if _led_card(str(skill)).has_point(d):
			return "led:" + str(skill)
	for fr in _found_rects:
		if (fr["rect"] as Rect2).has_point(d):
			return "found:%d" % int(fr["pid"])
	for rr in _row_rects:
		if (rr["rect"] as Rect2).has_point(d):
			return "row:%d" % int(rr["pid"])
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
	elif was == "btn:parameters":
		_mode = "parameters"
		queue_redraw()
	elif was == "btn:rating":
		_mode = "rating"
		queue_redraw()
	elif was == "btn:search":
		if not _scout.is_empty() and not _searching:
			var skills: Array = []
			for k in _selected:
				if _selected[k]:
					skills.append(k)
			search_pressed.emit(skills)
	elif was.begins_with("led:"):
		# toggling is only live once a scout is hired (the 087 state has no
		# scout and its LEDs are the baked "disabled" art)
		if not _scout.is_empty():
			var k := was.substr(4)
			_selected[k] = not bool(_selected.get(k, false))
			queue_redraw()
	elif was.begins_with("found:"):
		prospect_pressed.emit(int(was.substr(6)))
	elif was.begins_with("row:"):
		var pid := int(was.substr(4))
		for p in _youth:
			if int(p.get("id", -1)) == pid and Youth.is_ready(p):
				promote_requested.emit(pid)
				break


# ---- drawing -------------------------------------------------------------

func _txt_left(f: Font, x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	draw_string(f, Vector2(x, y_top + 7), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _txt_right(f: Font, x_right: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x_right - w, y_top + 7), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

## The INK span of `s` relative to the pen x in `face`: [ink_x0, ink_x1], from
## the per-char atlas metrics (staff-wage doctrine — the original aligns INK boxes).
func _ink_span(s: String, face := "proman8") -> Array:
	var fm: Dictionary = (_spec.get("font_metrics", {}) as Dictionary).get(face, {})
	if fm.is_empty() or s.length() == 0 or not fm.has(s[0]) or not fm.has(s[s.length() - 1]):
		return []
	var adv := 0
	for i in s.length() - 1:
		adv += int((fm.get(s[i], [8, 0, 7]) as Array)[0])
	return [float((fm[s[0]] as Array)[1]), float(adv + int((fm[s[s.length() - 1]] as Array)[2]))]

## Ink-centred text on cx; returns the pen x it drew at (for follow-up alignment).
## `asc` = baseline offset from the ink top (proman8@11 caps: 7; proman10@10: 8).
func _txt_center(f: Font, cx: float, y_top: float, s: String, col: Color, sz: int,
		face := "proman8", asc := 7) -> float:
	if f == null:
		return 0.0
	var pen := cx - f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x / 2.0
	var span := _ink_span(s, face)
	if span.size() == 2:
		pen = cx - (float(span[0]) + float(span[1])) / 2.0
	pen = floorf(pen)
	draw_string(f, Vector2(pen, y_top + asc), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	return pen

## Gold star row from the frame-cut sprites (pitch 11). The original alternates
## two sprite variants along the row (cells 1/3/5 = A, 2/4 = B — frame 047).
func _stars(tex_a: Texture2D, tex_b: Texture2D, half_tex: Texture2D,
		x0: float, y: float, rating: float) -> void:
	var full := int(floor(rating))
	for i in full:
		var tex := tex_a if i % 2 == 0 else tex_b
		if tex != null:
			draw_texture(tex, Vector2(x0 + i * 11.0, y))
	if rating - full >= 0.5 and half_tex != null:
		draw_texture(half_tex, Vector2(x0 + full * 11.0, y))

## Un-witnessed press feedback (PARAMETERS only): the 088/089-style white ring.
func _ring(r: Rect2, col: Color) -> void:
	var pad := float((_spec.get("ring", {}) as Dictionary).get("pad", 2))
	draw_rect(Rect2(r.position - Vector2(pad, pad), r.size + Vector2(pad * 2, pad * 2)),
		col, false, 2.0)

func _draw() -> void:
	var s := _scale()
	var o := _origin(s)
	draw_set_transform(o, 0.0, Vector2(s, s))
	draw_rect(Rect2(0, 0, W, H), Color.BLACK, true)
	if _body != null:
		draw_texture(_body, Vector2(0, _body_y))
	PMChrome.draw_header(self, "YOUTH TEAM", _manager, _club, _league, _season,
		_week, _club_id)

	var ink: Dictionary = _spec.get("ink", {})
	var c_name := _col(ink.get("name", [255, 255, 255]))
	var c_yes := _col(ink.get("yes", [210, 0, 0]))
	var c_no := _col(ink.get("no", [0, 0, 0]))
	var c_msg := _col(ink.get("msg", [0, 0, 0]))
	var c_count := _col(ink.get("count", [166, 202, 240]))

	var has_scout := not _scout.is_empty()

	# --- scout bar (empty purple bar is baked) ---
	if has_scout:
		var nx: Array = _spec.get("scout_name_xy", [141, 87])
		_txt_left(_f8, float(nx[0]), float(nx[1]), str(_scout.get("name", "")), c_name, 11)
		var st: Dictionary = _spec.get("scout_stars", {})
		_stars(_star_a_purple, _star_b_purple, null, float(st.get("x0", 248)),
			float(st.get("y", 85)), float(_scout.get("stars", 0.0)))

	# --- capability values: the witnessed NO (no scout) / YES (scout) pair,
	#     ink-centred per cell (frame: NO/YES share cx 117 left / 242 right) ---
	var cap_rows: Array = _spec.get("cap_rows", [126, 139, 152])
	var value_cx: Dictionary = _spec.get("cap_value_cx", {"left": 117, "right": 242})
	for side in ["left", "right"]:
		for top in cap_rows:
			_txt_center(_f8, float(value_cx.get(side, 117)), float(top) + 1.0,
				"YES" if has_scout else "NO", c_yes if has_scout else c_no, 11)

	# --- LEDs: disabled art baked; available/lit sprites once a scout exists ---
	if has_scout:
		for skill in _spec.get("cap_order", []):
			var r := _led_rect(str(skill))
			var tex := _led_lit if bool(_selected.get(str(skill), false)) else _led_avail
			if tex != null:
				draw_texture(tex, r.position)
		if _search_on != null:
			draw_texture(_search_on, _btn_rect("search").position)

	# --- PLAYERS FOUND: the shortlist if the scout brought one back, else the
	#     two witnessed messages verbatim ---
	_found_rects.clear()
	if has_scout and not _searching and not _found.is_empty():
		_draw_found()
	var msg: Array = []
	if not has_scout:
		msg = _spec.get("pf_msg_no_scout", [])
	elif _searching:
		msg = _spec.get("pf_msg_searching", [])
	if msg.size() >= 2:
		# Message face = proman10 @ native 10 (frame glyphs match its atlas).
		# Line 1 ink-centred on the panel cx; line 2 LEFT-aligned to line 1's ink
		# start (frame-decoded: 087 both lines start x392, 047 both x344).
		var an: Dictionary = _spec.get("pf_msg_anchor", {})
		var pen1 := _txt_center(_f10, float(an.get("cx", 476)),
			float(an.get("line1_top", 145)), str(msg[0]), c_msg, 10, "proman10", 8)
		var span1 := _ink_span(str(msg[0]), "proman10")
		var span2 := _ink_span(str(msg[1]), "proman10")
		var ink_start := pen1 + (float(span1[0]) if span1.size() == 2 else 0.0)
		var pen2 := ink_start - (float(span2[0]) if span2.size() == 2 else 0.0)
		draw_string(_f10, Vector2(floorf(pen2), float(an.get("line2_top", 165)) + 8),
			str(msg[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_msg)

	# --- manager bar + player count ---
	if not _ymgr.is_empty():
		var mx: Array = _spec.get("mgr_name_xy", [183, 248])
		_txt_left(_f8, float(mx[0]), float(mx[1]), str(_ymgr.get("name", "")), c_name, 11)
		var st2: Dictionary = _spec.get("mgr_stars", {})
		_stars(_star_a_blue, _star_b_blue, _star_half_blue, float(st2.get("x0", 290)),
			float(st2.get("y", 246)), float(_ymgr.get("stars", 0.0)))
		var n := _count_override if _count_override >= 0 else _youth.size()
		var cxy: Array = _spec.get("count_xy", [376, 248])
		_txt_left(_f8, float(cxy[0]), float(cxy[1]),
			"%d PLAYER%s" % [n, "" if n == 1 else "S"], c_count, 11)

	# --- roster rows (filled rendering = documented reconstruction) ---
	_draw_rows()

	# --- mode plaques: baked = PARAMETERS selected; RATING mode overlays 047 pair ---
	if _mode == "rating":
		if _plaq_param_off != null:
			draw_texture(_plaq_param_off, _btn_rect("parameters").position)
		if _plaq_rating_on != null:
			draw_texture(_plaq_rating_on, _btn_rect("rating").position)

	# --- held states: frame-cut ring sprites (048 red SEARCH / 088 RATING /
	#     089 RETURN); PARAMETERS press is un-witnessed -> white rect ring ---
	if _press.begins_with("btn:"):
		var bname := _press.substr(4)
		var boxes: Dictionary = (_spec.get("ring", {}) as Dictionary).get("boxes", {})
		var key := bname + "_held"
		if _held.has(key) and boxes.has(key):
			if bname != "search" or has_scout:
				var bx: Array = boxes[key]
				draw_texture(_held[key], Vector2(float(bx[0]), float(bx[1])))
		elif bname == "parameters":
			_ring(_btn_rect(bname), _col((_spec.get("ring", {}) as Dictionary)
				.get("white", [255, 255, 255])))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Roster rows under the baked NAME/SP/ST/AG/QU/AV/ROL/WAGE/YEARS headers. The
## PARAMETERS columns show the FICHA parameter codes (SP=VE speed, ST=RE stamina,
## AG=AG aggression, QU=CA quality), AV the ability average, ROL the demarcation;
## WAGE/YEARS stay empty (youth contracts are un-modelled). Filled rendering is
## an un-witnessed reconstruction — docs/re/youth_re.md.
func _draw_rows() -> void:
	_row_rects = []
	var rspec: Dictionary = _spec.get("rows", {})
	var y0 := int(rspec.get("y0", 303))
	var pitch := int(rspec.get("pitch", 16))
	var rh := int(rspec.get("h", 12))
	var nrows := int(rspec.get("count", 11))
	var tx := float(rspec.get("text_x", 64))
	var cols: Dictionary = rspec.get("col_cx", {})
	var c_txt := Color8(0, 0, 0)
	for i in mini(_youth.size(), nrows):
		var p: Dictionary = _youth[i]
		var y := float(y0 + i * pitch)
		var attrs: Dictionary = p.get("attrs", {})
		_txt_left(_f8, tx, y + 2.0, str(p.get("name", "")).to_upper(), c_txt, 11)
		if _mode == "parameters":
			_txt_center(_f8, float(cols.get("SP", 352)), y + 2.0,
				str(int(attrs.get("VE", 0))), c_txt, 11)
			_txt_center(_f8, float(cols.get("ST", 375)), y + 2.0,
				str(int(attrs.get("RE", 0))), c_txt, 11)
			_txt_center(_f8, float(cols.get("AG", 398)), y + 2.0,
				str(int(attrs.get("AG", 0))), c_txt, 11)
			_txt_center(_f8, float(cols.get("QU", 421)), y + 2.0,
				str(int(attrs.get("CA", 0))), c_txt, 11)
		_txt_center(_f8, float(cols.get("AV", 287)), y + 2.0, str(Youth.ability(p)), c_txt, 11)
		_txt_center(_f8, float(cols.get("ROL", 312)), y + 2.0, str(p.get("pos", "")), c_txt, 11)
		# WAGE / YEARS stay empty (youth contracts un-modelled); readiness is
		# reported by the youth-manager news line, no invented row badge.
		var r := Rect2(tx - 8.0, y, 390.0, float(rh))
		_row_rects.append({"pid": int(p.get("id", -1)), "rect": r})
		if _press == "row:%d" % int(p.get("id", -1)):
			draw_rect(r, Color(1, 1, 1, 0.25), true)


## The PLAYERS FOUND shortlist. Each row is a prospect the scout came back with; a tap
## offers him a contract (Career.sign_youth_prospect), which he can refuse — the loop
## the MANAGER.EXE strings describe ("The youth team scout has finished his search." ->
## "%s has joined your Youth Team." / "The youth player %s has rejected your offer.").
## The panel's FILLED look is un-witnessed, so this is plain app grammar inside the
## frame-measured interior, flagged as reconstruction in docs/re/youth_re.md.
func _draw_found() -> void:
	var iv: Array = _spec.get("pf_interior", [326, 102, 302, 117])
	var x := float(iv[0]) + 4.0
	var w := float(iv[2]) - 8.0
	var y := float(iv[1]) + 6.0
	var limit := int((float(iv[3]) - 10.0) / PF_ROW_PITCH)
	for i in mini(_found.size(), limit):
		var p: Dictionary = _found[i]
		var pid := int(p.get("id", -1))
		var r := Rect2(x, y, w, PF_ROW_H)
		var held := _press == "found:%d" % pid
		draw_rect(r, C_PF_ROW_SEL if held else C_PF_ROW, true)
		_txt_left(_f8, x + 4.0, y + 1.0, str(p.get("name", "")).to_upper(), C_PF_INK, 11)
		_txt_center(_f8, x + w - 74.0, y + 1.0, str(p.get("age", 0)), C_PF_INK, 11)
		_txt_center(_f8, x + w - 54.0, y + 1.0, str(Youth.ability(p)), C_PF_INK, 11)
		# potential as 1-5 pips (the YOUTH screen's own star language, drawn plain
		# because the panel has no witnessed star art of its own)
		var pips := clampi(int(round(Youth.potential_of(p) / 20.0)), 1, 5)
		for s in pips:
			draw_rect(Rect2(x + w - 38.0 + s * 6.0, y + 4.0, 4.0, 5.0), C_PF_STAR, true)
		_found_rects.append({"pid": pid, "rect": r})
		y += PF_ROW_PITCH


func _col(v: Variant) -> Color:
	var a: Array = v if v is Array else [255, 255, 255]
	return Color8(int(a[0]), int(a[1]), int(a[2]))
