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
##   PLAYERS FOUND  the two witnessed messages verbatim when the list is empty; the
##                  FILLED list is witnessed since 2026-08-01 by B9's own wine drive
##                  (tools/re/refs/b9-players-found-2026-08-01/) and blitted from that
##                  frame's own pixels — see the PF_* block below and
##                  tools/re/build_youth_found_list_from_frames.py. Gate: the
##                  `youth_b9found` pair in diff_youth_parity, 0 px.
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
signal caps_changed(selected: Dictionary)  # an LED toggled; Career persists the six flags
                                       # (the original's criteria object survives the screen)
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
var _star_half_purple: Texture2D     # cut from B9's 4.5* scout C. Stump (2026-08-01)
var _arrow: Texture2D                # the PARAMETERS-slot arrow sprite
var _arrow_rating: Texture2D         # the RATING-slot cut (11 of its 81 px re-dither)
var _found_list: Texture2D           # the PLAYERS FOUND list widget, cut from B9's capture
var _found_rowgrid: Texture2D        # its populated-row cell grid, for slots above the first
var _held: Dictionary = {}         # held-state ring sprites (frame-cut 048/088/089)

var _f8: Font
var _f10: Font
var _f_euro: Font        # euro8 — the PLAYERS FOUND money column's own face

var _youth: Array = []
var _scout: Dictionary = {}        # YOUTH TEAM SCOUT {name,stars,...}; {} = none
var _ymgr: Dictionary = {}         # YOUTH TEAM MANAGER; {} = none
var _searching := false            # a scout search is running (Career.youth_search)
var _selected: Dictionary = {}     # skill key -> true (LED lit)
var _mode := "parameters"          # "parameters" | "rating" (087 default)
## The arrow's own slot — a SEPARATE axis from `_mode` (see the draw, and youth_re.md C8):
## frame 047 has the RATING plaques with the arrow still on PARAMETERS.
var _arrow_row := "parameters"     # "parameters" | "rating"
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
var _alert_img: Texture2D          # zero-LED SEARCH refusal (PMAlert render); null = none

# PLAYERS FOUND, filled — WITNESSED UN-OCCLUDED 2026-08-01 by B9's own wine drive,
# `tools/re/refs/b9-players-found-2026-08-01/02_players_found_first.png`
# (TOTAL-level Bolton W career, Saturday 28 March 1998, the scout's first report:
# `Chapman  41  [ROL]  £5,000  19`). Its twin 14 months later differs by 494 px, every
# one of them in the header date plaque — the list rect is identical, so the widget is
# stable.
#
# The panel is a LIST: a header label row on white, six 12-px plates on a 16-px pitch,
# a 1-px grey cell grid around the POPULATED row, and a scrollbar at x609..624. All of
# it is cut verbatim into `found_list.png` / `found_rowgrid.png` by
# `tools/re/build_youth_found_list_from_frames.py`, so the port BLITS the chrome and
# draws only the five live cells over it.
#
# This supersedes the values read off refrun `p0759_UNKNOWN.png`, which has the
# contract-offer card on top of the panel — and the card DIMS what it covers, so its
# AV (132,26,26) / WAGE (100,0,0) / AGE (30,52,98) were the dimmed inks. The real ones
# are below, and each column's VALUE carries its own HEADER's ink.
const PF_LIST_XY := Vector2(333, 105)
const PF_ROW_Y0 := 120.0            # slot 0's plate top; its rules sit at y119 / y132
const PF_ROW_PITCH := 16
const PF_ROW_H := 12
const PF_ROW_X := 334.0
const PF_ROW_W := 271.0             # x334..x604
const PF_ROW_SLOTS := 6
const PF_NAME_X := 355.0            # the row's own pen; the header label's is x357
const PF_ROL_X := 484.0             # the 25x14 camrol icon, drawn over the row's rules
const PF_COL := {"AV": 471.0, "ROL": 496.0, "WAGE": 543.0, "AGE": 591.0}
const C_PF_ROW_SEL := Color8(255, 226, 128)
const C_PF_INK := Color8(0, 0, 0)
const C_PF_AV := Color8(212, 63, 0)
const C_PF_WAGE := Color8(150, 0, 0)
const C_PF_AGE := Color8(42, 95, 170)


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
	_star_half_purple = load("res://art/screens/youth/star_half_purple.png")
	_arrow = load("res://art/screens/youth/arrow.png")
	_arrow_rating = load("res://art/screens/youth/arrow_rating.png")
	_found_list = load("res://art/screens/youth/found_list.png")
	_found_rowgrid = load("res://art/screens/youth/found_rowgrid.png")
	for k in ["search_held", "rating_held", "return_held"]:
		_held[k] = load("res://art/screens/youth/%s.png" % k)
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f_euro = PMChrome.font("euro8")
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

## WHICH of the six SEARCH CAPABILITIES a youth scout of this rating can search on.
##
## Measured, not argued: `tools/re/probe_youth_cap_mask.py` reads the star bar by GOLD AREA
## (full glyph 13 px, half glyph 8) and the value cells by ink colour, over every youth-scout
## frame the repo holds. Three scouts previously read as "2 stars" are all **1.5**, and all
## three carry the same pair; the two high scouts (4.5 and 5.0) carry all six. So the mask
## follows the RATING -- the earlier "per scout" reading came from a star bar counted by eye.
##
## ONLY the witnessed rungs are here. An unwitnessed rating returns `[]`, which every caller
## reads as "no restriction known" and renders exactly as the port always has, so frame 047
## stays at 0 px. Filling 2.0 .. 4.0 needs careers at those ratings, and inventing them is
## precisely what this project does not do.
const CAP_BY_STARS := {
	1.5: ["HANDLING", "TACKLING"],
	4.5: ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"],
	5.0: ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"],
}

## The witnessed capability list for `stars`, or [] when that rating has never been seen
## (and for "no scout", which the caller gates on separately).
static func available_caps(stars: float) -> Array:
	if stars < 0.0:
		return []
	# The star bar draws in half-star steps, so snap before the lookup: a 1.5 stored as
	# 1.4999 must not silently fall through to "unrestricted".
	var key: float = round(stars * 2.0) / 2.0
	return (CAP_BY_STARS.get(key, []) as Array).duplicate()


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
	if _alert_img != null:
		return "alert_ok"     # any tap answers the alert's OK (single-button box)
	# the arrow's two slots are their own buttons (FUN_0053e760 / FUN_0053e7e0), left of
	# the plaques and tested BEFORE them so the narrow column is not swallowed
	var asp: Dictionary = _spec.get("arrow", {})
	var ax := float(asp.get("x", 475))
	var aw := float(asp.get("w", 11))
	var ah := float(asp.get("h", 18))
	for row in ["parameters", "rating"]:
		var ay := float(asp.get("y_rating" if row == "rating" else "y_parameters",
			290 if row == "rating" else 266))
		if Rect2(ax, ay, aw, ah).has_point(d):
			return "arrow:" + row
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
	if was == "alert_ok":
		_alert_img = null
		PMChrome.set_dim(false)
		queue_redraw()
	elif was == "btn:return":
		back_pressed.emit()
	elif was.begins_with("arrow:"):
		_arrow_row = was.substr(6)
		queue_redraw()
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
			if skills.is_empty():
				# A zero-LED search can never match (the predicate is an OR over the
				# lit flags) — refuse with the EXE's own alert (0x65d3c0, witnessed on
				# the senior SCOUT screen; the youth-side gate itself is un-witnessed).
				_alert_img = ImageTexture.create_from_image(
					PMAlert.render("You have to select some options to make the search."))
				PMChrome.set_dim(true)
				queue_redraw()
				return
			search_pressed.emit(skills)
	elif was.begins_with("led:"):
		# toggling is only live once a scout is hired (the 087 state has no
		# scout and its LEDs are the baked "disabled" art)
		if not _scout.is_empty():
			var k := was.substr(4)
			# An UNAVAILABLE capability's tap is REFUSED, not toggled -- witnessed on
			# `tools/re/refs/youth-caps-2026-08-01/b9_02_leds_armed.png`, where six taps on a
			# 1.5* scout's block left only HANDLING and TACKLING lit and the other four
			# unmoved. Silently, with no alert: nothing in that frame pair says the original
			# says anything, so the port says nothing either.
			var avail := available_caps(float(_scout.get("stars", 0.0)))
			if not avail.is_empty() and not avail.has(k):
				return
			_selected[k] = not bool(_selected.get(k, false))
			caps_changed.emit(_selected.duplicate())
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
			draw_texture(_tex(tex), Vector2(x0 + i * 11.0, y))
	if rating - full >= 0.5 and half_tex != null:
		draw_texture(_tex(half_tex), Vector2(x0 + full * 11.0, y))

## Un-witnessed press feedback (PARAMETERS only): the 088/089-style white ring.
func _ring(r: Rect2, col: Color) -> void:
	var pad := float((_spec.get("ring", {}) as Dictionary).get("pad", 2))
	draw_rect(Rect2(r.position - Vector2(pad, pad), r.size + Vector2(pad * 2, pad * 2)),
		col, false, 2.0)

## Dim pass-throughs while the refusal alert is up (the SAME palette-LUT dim the
## walkthrough proves for a host screen under a modal — ScoutScreen's pattern).
func _tex(t: Texture2D) -> Texture2D:
	return PMAlert.dim_texture(t) if _alert_img != null and t != null else t

func _ci(col: Color) -> Color:
	return PMAlert.dim_color(col) if _alert_img != null else col


func _draw() -> void:
	var s := _scale()
	var o := _origin(s)
	draw_set_transform(o, 0.0, Vector2(s, s))
	draw_rect(Rect2(0, 0, W, H), Color.BLACK, true)
	if _body != null:
		draw_texture(_tex(_body), Vector2(0, _body_y))
	PMChrome.draw_header(self, "YOUTH TEAM", _manager, _club, _league, _season,
		_week, _club_id)

	var ink: Dictionary = _spec.get("ink", {})
	var c_name := _ci(_col(ink.get("name", [255, 255, 255])))
	var c_yes := _ci(_col(ink.get("yes", [210, 0, 0])))
	var c_no := _ci(_col(ink.get("no", [0, 0, 0])))
	var c_msg := _ci(_col(ink.get("msg", [0, 0, 0])))
	var c_count := _ci(_col(ink.get("count", [166, 202, 240])))

	var has_scout := not _scout.is_empty()

	# --- scout bar (empty purple bar is baked) ---
	if has_scout:
		var nx: Array = _spec.get("scout_name_xy", [141, 87])
		_txt_left(_f8, float(nx[0]), float(nx[1]), str(_scout.get("name", "")), c_name, 11)
		var st: Dictionary = _spec.get("scout_stars", {})
		_stars(_star_a_purple, _star_b_purple, _star_half_purple, float(st.get("x0", 248)),
			float(st.get("y", 85)), float(_scout.get("stars", 0.0)))

	# --- capability values: the witnessed NO (no scout) / YES (scout) pair,
	#     ink-centred per cell (frame: NO/YES share cx 117 left / 242 right) ---
	# ⚠ KNOWN-INCOMPLETE, and 2026-08-01 (s85) says WHY, which s84 could not.
	# The value is the capability's AVAILABILITY to this scout, and the LED under it has
	# THREE states, not two. Read off two frames side by side:
	#   * `screenshots/original-walkthrough-2026-07-02/047_164509.png` — P. Mitchell 5.0★:
	#     all six values YES, and the six LEDs are three DARK MAROON (HANDLING, TACKLING,
	#     HEADING) and three BRIGHT RED WITH A RING (DRIBBLING, PASSING, SHOOTING);
	#   * `tools/re/refs/youth-caps-2026-08-01/b9_01_youth_before.png` — J. Casson 2★, the
	#     first time the screen is opened and BEFORE any click: HANDLING and TACKLING YES,
	#     the other four NO, and exactly those two LEDs are dark maroon while the other four
	#     are the PINK HATCHED art. After six taps (`b9_02_leds_armed.png`) only HANDLING and
	#     TACKLING went bright-with-ring — the other four taps were REFUSED.
	# So: pink hatched = UNAVAILABLE, dark maroon = available and unselected, bright + ring =
	# selected. The value cell is YES iff the capability is available, which is why 047 reads
	# all six YES with only three lit, and why a value that tracked the LED (tried and
	# reverted here) fails 047 by 345 px.
	#
	# ⚠ s85 went on to call it "PER SCOUT, not a star ladder", on the reading that J. Casson
	# and C. Dewhurst were both 2★ with different masks. **That reading was wrong, and
	# 2026-08-01 (s86) measured it rather than read it.** `tools/re/probe_youth_cap_mask.py`
	# scores the star bar by GOLD AREA -- a full glyph is a 13-px diamond, a half glyph 8 --
	# because run WIDTH cannot tell 1.5 from 2.0 (4 columns against 5) and the eye cannot
	# either. Every youth-scout frame the repo holds:
	#
	#   | scout | measured | YES values |
	#   |---|---|---|
	#   | J. Casson    | **1.5★** | HANDLING, TACKLING |
	#   | C. Dewhurst  | **1.5★** | HANDLING, TACKLING |
	#   | S. Munt      | **1.5★** | HANDLING, TACKLING |
	#   | C. Stump     | 4.5★ | all six |
	#   | P. Mitchell  | 5.0★ | all six |
	#
	# So there are no two same-rating scouts with different masks: all three low scouts are
	# 1.5★ and carry the IDENTICAL pair. The mask is a function of the RATING after all, and
	# `CAP_BY_STARS` below is what is witnessed -- the two ends of the ladder and nothing
	# between them. A rating with no row falls back to all-available, which is what the port
	# already did everywhere and what keeps frame 047 at 0 px; the rungs between 1.5 and 4.5
	# are NOT invented here, and a career at 2.0 / 3.0 / 3.5 is the capture that fills them.
	var cap_rows: Array = _spec.get("cap_rows", [126, 139, 152])
	var value_cx: Dictionary = _spec.get("cap_value_cx", {"left": 117, "right": 242})
	var avail := available_caps(float(_scout.get("stars", 0.0)) if has_scout else -1.0)
	var order: Array = _spec.get("cap_order", [])
	# `cap_order` INTERLEAVES the two columns (`_led_rect`: even index = left, odd = right),
	# so row i of the left column is order[2*i] and of the right column order[2*i + 1].
	for side in ["left", "right"]:
		for i in cap_rows.size():
			var top: float = float(cap_rows[i])
			var idx := i * 2 + (0 if side == "left" else 1)
			var skill := str(order[idx]) if idx < order.size() else ""
			var yes := has_scout and (avail.is_empty() or avail.has(skill))
			_txt_center(_f8, float(value_cx.get(side, 117)), top + 1.0,
				"YES" if yes else "NO", c_yes if yes else c_no, 11)

	# --- LEDs: disabled art baked; available/lit sprites once a scout exists ---
	if has_scout:
		for skill in _spec.get("cap_order", []):
			var r := _led_rect(str(skill))
			var tex := _led_lit if bool(_selected.get(str(skill), false)) else _led_avail
			if tex != null:
				draw_texture(_tex(tex), r.position)
		if _search_on != null:
			draw_texture(_tex(_search_on), _btn_rect("search").position)

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
			draw_texture(_tex(_plaq_param_off), _btn_rect("parameters").position)
		if _plaq_rating_on != null:
			draw_texture(_tex(_plaq_rating_on), _btn_rect("rating").position)

	# --- the selection arrow MOVES between its two slots. `FUN_0053e760` invalidates
	#     (475,266)-(484,283) and sets DAT_00658a40 = 1; `FUN_0053e7e0` invalidates
	#     (475,290)-(484,307) and sets it to 0 — each repaints its OWN slot, which is only
	#     meaningful if the arrow moves. Witnessed live 2026-08-01: y17 has it at 266, y18
	#     at 290. It had been baked into youth_body.png at 266 and never moved.
	#
	#     It is NOT the plaque mode. Frame 047 carries the RATING plaque pair (0px against
	#     y18 over both plaque rects) while its arrow sits at the PARAMETERS slot — so the
	#     two are separate axes and the arrow has its own hit rects. What ELSE the arrow
	#     selects is un-RE'd; it defaults to PARAMETERS, which is what every witnessed
	#     frame shows. Hypothesis, flagged as such in youth_re.md C8.
	var asp: Dictionary = _spec.get("arrow", {})
	var rating_row := _arrow_row == "rating"
	var atex: Texture2D = _arrow_rating if rating_row else _arrow
	if atex != null:
		var ay := float(asp.get("y_rating", 290)) if rating_row \
			else float(asp.get("y_parameters", 266))
		draw_texture(_tex(atex), Vector2(float(asp.get("x", 475)), ay))

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

	# --- the zero-LED refusal alert, over everything (the EXE's own box) ---
	if _alert_img != null:
		var ar := PMAlert.box_rect("You have to select some options to make the search.")
		draw_texture(_alert_img, Vector2(ar.position))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Roster rows under the baked NAME/SP/ST/AG/QU/AV/ROL/WAGE/YEARS headers. The
## PARAMETERS columns show the FICHA parameter codes (SP=VE speed, ST=RE stamina,
## AG=AG aggression, QU=CA quality), AV the ability average, ROL the CAMROL fine-
## position icon (the original's own compact ROL grammar, 100%-pixel-witnessed on
## the OFFERS list; the youth row itself is un-witnessed — B9's capture settles it);
## WAGE/YEARS stay empty (youth contracts are un-modelled) except the declared OURS
## "PROMOTE" cue on a READY row — the EXE's own word (its PROMOTE/PROMOTED strings),
## marking the tap that promotes him. Filled rendering is an un-witnessed
## reconstruction — docs/re/youth_re.md.
func _draw_rows() -> void:
	_row_rects = []
	var rspec: Dictionary = _spec.get("rows", {})
	var y0 := int(rspec.get("y0", 303))
	var pitch := int(rspec.get("pitch", 16))
	var rh := int(rspec.get("h", 12))
	var nrows := int(rspec.get("count", 11))
	var tx := float(rspec.get("text_x", 64))
	var cols: Dictionary = rspec.get("col_cx", {})
	var c_txt := _ci(Color8(0, 0, 0))
	# The row's INKS, measured off the first witness of a FILLED roster row --
	# `tools/re/refs/youth-roster-2026-08-01/b9_roster_signed_1998-10-03.png`, a signed
	# prospect (`Burgess 20 19 20 21 20 [ROL] £5,000 3 3`). The row was black throughout in
	# this port and it is not: the five parameter cells are the AV column's ORANGE, the money
	# is the WAGE header's dark red and the two trailing figures are the YEARS header's blue.
	# Same family as the PLAYERS FOUND panel s84 measured, with one difference worth stating
	# plainly rather than smoothing over: SP / ST / AG / QU do NOT carry their own headers'
	# slate (100,100,140) -- all five parameter values carry AV's (212,63,0).
	var c_param := _ci(Color8(212, 63, 0))
	var c_wage := _ci(Color8(150, 0, 0))
	var c_years := _ci(Color8(42, 63, 170))
	for i in mini(_youth.size(), nrows):
		var p: Dictionary = _youth[i]
		var y := float(y0 + i * pitch)
		var attrs: Dictionary = p.get("attrs", {})
		# NOT upper-cased -- the witness reads "Burgess", the same correction s84 had to make
		# to the PLAYERS FOUND panel's name column.
		_txt_left(_f8, tx, y + 2.0, str(p.get("name", "")), c_txt, 11)
		if _mode == "parameters":
			_txt_center(_f8, float(cols.get("SP", 187)), y + 2.0,
				str(int(attrs.get("VE", 0))), c_param, 11)
			_txt_center(_f8, float(cols.get("ST", 211)), y + 2.0,
				str(int(attrs.get("RE", 0))), c_param, 11)
			_txt_center(_f8, float(cols.get("AG", 237)), y + 2.0,
				str(int(attrs.get("AG", 0))), c_param, 11)
			_txt_center(_f8, float(cols.get("QU", 262)), y + 2.0,
				str(int(attrs.get("CA", 0))), c_param, 11)
		_txt_center(_f8, float(cols.get("AV", 287)), y + 2.0, str(Youth.ability(p)), c_param, 11)
		var pf := PMChrome.iget(p, "posFine")
		if pf >= 1 and pf <= 18:
			var rol := PMChrome.camrol(pf)
			if rol != null:
				draw_texture(_tex(rol),
					Vector2(floorf(float(cols.get("ROL", 312)) - 12.0), y - 1.0))
			else:
				_txt_center(_f8, float(cols.get("ROL", 312)), y + 2.0, str(p.get("pos", "")), c_txt, 11)
		else:
			_txt_center(_f8, float(cols.get("ROL", 312)), y + 2.0, str(p.get("pos", "")), c_txt, 11)
		# WAGE / YEARS are REAL (witnessed 2026-08-01, refrun p0771: a youth player's card
		# carries CLUB FEE £75,000 / YEARLY WAGE £15,000 / YEARS 4 / LEFT 4). The old
		# "youth contracts are un-modelled" note was wrong and the columns are no longer
		# blank. The invented in-row "PROMOTE" cue (B4) is GONE: promotion lives on the
		# youth player's card, where the source puts it.
		var wage := int(p.get("contract_wage", 0))
		if wage > 0:
			_txt_center(_f8, float(cols.get("WAGE", 358)), y + 2.0, _money(wage), c_wage, 11)
		# TWO figures under the single YEARS header, not one. Measured on the witness: blue
		# ink at cx 406 and cx 432, while the header's own ink spans x396..441 — one label
		# over two cells, which is why a single centred column landed between them. The pair
		# is the youth card's own YEARS / LEFT (refrun p0771: YEARS 4 / LEFT 4).
		# DECLARED: the witness row has 3 and 3, so it cannot say WHICH cell is which; the
		# port puts YEARS left and LEFT right, following the card's own order.
		var yrs := int(p.get("contract_years", 0))
		if yrs > 0:
			_txt_center(_f8, float(cols.get("YEARS", 406)), y + 2.0, str(yrs), c_years, 11)
			var left := int(p.get("contract_left", yrs))
			_txt_center(_f8, float(cols.get("LEFT", 432)), y + 2.0, str(left), c_years, 11)
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
	# The whole widget — header labels, the six plates, slot 0's cell grid, the scrollbar —
	# is the frame's own pixels. Only the five live cells are drawn here.
	if _found_list != null:
		draw_texture(_tex(_found_list), PF_LIST_XY)
	var y := PF_ROW_Y0
	for i in mini(_found.size(), PF_ROW_SLOTS):
		var p: Dictionary = _found[i]
		var pid := int(p.get("id", -1))
		var r := Rect2(PF_ROW_X, y, PF_ROW_W, float(PF_ROW_H))
		# Slot 0's grid is baked into found_list.png. Whether the grid belongs to the SLOT
		# or to a POPULATED row cannot be told apart from one prospect, so the port stamps
		# it per populated row — which reproduces the witness exactly. Declared in youth_re.
		if i > 0 and _found_rowgrid != null:
			draw_texture(_tex(_found_rowgrid), Vector2(PF_LIST_XY.x, y - 1.0))
		if _press == "found:%d" % pid:
			draw_rect(r, _ci(C_PF_ROW_SEL), true)
		_txt_left(_f8, PF_NAME_X, y + 3.0, str(p.get("name", "")), _ci(C_PF_INK), 11)
		# AV = floor((VE+RE+AG+CA)/4), the same average every other list in the game uses
		# (scout_screen_re.md, verified 28/28 on the OFFERS squad list).
		_txt_center(_f8, PF_COL["AV"], y + 3.0, str(_av(p)), _ci(C_PF_AV), 11)
		var pf := PMChrome.iget(p, "posFine")
		var rol := PMChrome.camrol(pf) if pf >= 1 and pf <= 18 else null
		if rol != null:
			draw_texture(_tex(rol), Vector2(PF_ROL_X, y - 1.0))
		else:
			_txt_center(_f8, PF_COL["ROL"], y + 3.0, str(p.get("pos", "")), _ci(C_PF_INK), 11)
		# The money column is the EURO8 face at 11, not the bold list face the other four
		# cells use. Identified by SHAPE, not by width, and reproducibly:
		#   app/tests/shot_face_probe.gd + tools/re/probe_text_face.py
		# render "£5,000" in all eight extracted faces at 8/10/11/12 and XOR each against
		# the witness cell's own ink mask (y122..131, x526..558, 94 px). euro8@11 is the
		# ONLY pair that scores 0; the other 31 do not even share its bounding box.
		var wage := int(p.get("contract_wage", 0))
		if wage > 0:
			_txt_center(_f_euro, PF_COL["WAGE"], y + 2.0, _money(wage), _ci(C_PF_WAGE), 11,
				"euro8", 8)
		_txt_center(_f8, PF_COL["AGE"], y + 3.0, str(int(p.get("age", 0))), _ci(C_PF_AGE), 11)
		_found_rects.append({"pid": pid, "rect": r})
		y += PF_ROW_PITCH


## AV = floor((VE+RE+AG+CA)/4) — the game's own squad-list average.
func _av(p: Dictionary) -> int:
	var a: Dictionary = p.get("attrs", {})
	var s := 0
	for k in ["VE", "RE", "AG", "CA"]:
		s += int(a.get(k, 0))
	@warning_ignore("integer_division")
	return s / 4


## "£15,000" — the card's own money grammar (witnessed refrun p0771).
func _money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return "£" + out


func _col(v: Variant) -> Color:
	var a: Array = v if v is Array else [255, 255, 255]
	return Color8(int(a[0]), int(a[1]), int(a[2]))
