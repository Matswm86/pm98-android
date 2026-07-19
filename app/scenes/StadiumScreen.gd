extends Control
class_name StadiumScreen
## PM98 GROUND (ESTADIO) overview, rebuilt frame-true from the ORIGINAL game.
##
## Binding frame: screenshots/original-walkthrough-2026-07-02/172_154930.png — the real
## MANAGER.EXE GROUND overview (default "WORK IN PROGRESS" state). The body chrome is baked
## 1:1 from that frame (tools/re/build_stadium_chrome_from_frames.py -> chrome.png): the LEFT
## "WORK IN PROGRESS" panel (SEATS / CAR PARK / FACILITIES / SERVICES sections with their
## TO BE PAID / WEEK columns + the fixed facility rows + TOTAL IMPROVEMENTS), the RIGHT green
## ground-name header + CAPACITY / CAR PARK / PITCH table over the pre-rendered ESTADIO<tier>
## scene, and the IMPROVE / WORKS / MATCH DAY / RETURN action grid. The shared BARRA header
## (PMChrome.draw_header) and marble background (PMChrome.draw_bg) render underneath, as on
## every other career screen.
##
## The PRIOR build was rejected as invented: it showed a "MATCH DAY" ticket-price stepper and
## a "SPONSOR BOARDS" price slider and a CAPACITY/CAR PARK/PITCH="NORMAL" readout that appear
## on NO GROUND-overview frame (ticket price / sponsor boards live on the separate GROUND
## MATCH DAY sub-screen, run-3 capture). All of it is gone.
##
## Only club-specific values are drawn over the baked chrome, from the real Career model:
##   - ground name (GameDB club.stadium) in the green header
##   - CAPACITY (Career.stadium_capacity)  -> "<n> seats"
##   - the ESTADIO<tier> picture (tier = clamp(capacity*11/130000, 0, 11), reversed
##     FUN_0051a6e0), drawn 1:1 at (299,148,320,240) over the baked Old-Trafford tile
## CAR PARK spaces and PITCH quality are NOT in game_db.json (only 15/476 clubs even carry a
## real capacity) -> honest gaps, left blank rather than fabricated (the prior cap/27 car-park
## and "NORMAL" pitch were invented). Native 640x480.

## RETURN -> dismiss (empty taps do not bounce to the hub).
signal back_pressed
## A SEATS offer card was ticked on the IMPROVEMENTS view -> Main runs Career.start_works.
## IMPROVE / WORKS now toggle the LEFT panel between the WORK IN PROGRESS ledger and the
## frame-true IMPROVEMENTS category picker IN-SCREEN (frame 173), so the prior Main-owned
## invented "GROUND WORKS" browse is gone.
signal improve_selected(added: int, cost: int, weeks: int)

const W := 640
const H := 480
const MAX_CAPACITY := 130000

# ---- IMPROVE view (binding frame 173_154935, "SEATS" category active) -------------------
# Category grid — only SEATS is witnessed with offers; CAR PARK / FACILITIES / SERVICES tab
# contents are un-RE'd (honest gap, inert). Rects measured off the frame black title bars.
const TAB_SEATS := Rect2(18, 113, 124, 18)
# The three SEATS offer cards (whole card is the PM98 hit target) + their tick boxes.
const CARDS := [Rect2(18, 233, 255, 55), Rect2(18, 293, 255, 55), Rect2(18, 353, 255, 55)]
const CHECKS := [Rect2(21, 240, 12, 12), Rect2(21, 300, 12, 12), Rect2(21, 360, 12, 12)]
# GBP price cells, blanked in the bake (seats + weeks stay baked — they are game constants,
# witnessed identical for Man Utd frame 173 and Bolton W parity/21). Left-aligned at x60.
const PRICE_ANCHORS := [Rect2(60, 253, 90, 13), Rect2(60, 313, 90, 13), Rect2(60, 373, 90, 13)]
# Fixed offers (witnessed-invariant across two clubs).
const OFFER_SEATS := [4000, 8000, 12000]
const OFFER_WEEKS := [20, 35, 50]
# Seat prices are TIERED by the club's board-objective label — DECODED from the
# live wine campaign 2026-07-19 (screenshots/wine-captures-2026-07-19-economics/):
# all four Premier tiers witnessed on real careers, base +£500k per tier, cards
# x1 / x1.75 / x2.5 with the engine's own float-truncation dirt kept verbatim:
#   Champion   4,250,000 / 7,437,500 / 10,624,999   (Arsenal s12 == ManU frame 173)
#   U.E.F.A.   3,750,000 / 6,562,499 /  9,375,000   (A.Villa s24)
#   Mid Table  3,250,000 / 5,687,500 /  8,124,999   (Wimbledon s28)
#   Avoid Rel. 2,750,000 / 4,812,499 /  6,875,000   (Bolton parity-run orig/21)
#   Promotion  2,250,000 / 3,937,500 /  5,624,999   (Manchester C w5_improve,
#     wine-captures-2026-07-19-lowerdiv/) — the ladder EXTENDS below Avoid
#     Relegation; the old "maps to the U.E.F.A. slot" inference is REFUTED.
const TIER_PRICES := {
	"Champion": [4250000, 7437500, 10624999],
	"U.E.F.A.": [3750000, 6562499, 9375000],
	"Promotion": [2250000, 3937500, 5624999],   # WITNESSED (Maine Road, Promotion board)
	"Mid Table": [3250000, 5687500, 8124999],
	"Avoid Relegation": [2750000, 4812499, 6875000],
}

# The ESTADIO<tier> scene box, pixel-measured off frame 172 (320x240 tile, drawn 1:1 over
# the baked Old-Trafford picture so any tier fully covers it — no bleed).
const SCENE_BOX := Rect2(299, 148, 320, 240)
# Dynamic-text anchors, measured off frame 172 (see docs/re/stadium_screen_re.md).
const R_GROUND := Rect2(299, 71, 320, 20)        # green header, ground name (centred)
const R_CAP_VAL := Rect2(412, 94, 200, 15)       # CAPACITY value cell (left-aligned)
const R_TOTAL := Rect2(150, 452, 126, 13)        # TOTAL IMPROVEMENTS money cell (right)
const R_SEATS_VAL := Rect2(150, 118, 128, 14)    # SEATS row value span (active-works line)

# Action-grid hit rects, reversed from FUN_0051a6e0 (the baked icons/labels are frame pixels).
const BTN_IMPROVE := Rect2(298, 407, 152, 25)
const BTN_WORKS := Rect2(484, 407, 132, 25)
const BTN_MATCHDAY := Rect2(298, 442, 152, 25)
const BTN_RETURN := Rect2(488, 442, 124, 25)

# Frame-sampled text colours.
const C_GROUND_TXT := Color8(255, 255, 255)
const C_VALUE_TXT := Color8(200, 220, 240)
const C_TOTAL_RED := Color8(170, 0, 0)
const C_SEATS_INK := Color8(40, 60, 130)         # SEATS section blue (matches its column heads)
const C_PRESS := Color(1, 1, 1, 0.18)
const C_PRICE := Color8(150, 0, 0)               # £ offer price ink (frame-sampled)
const C_XRED := Color8(210, 0, 0)                # ticked-box red X (frame 175)

var _chrome: Texture2D
var _improve: Texture2D
var _scene: Texture2D
var _f12: Font
var _f10: Font
var _view := "works"                             # "works" (ledger) | "improve" (picker)
var _sel := -1                                   # ticked offer card (-1 none)

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _ground: String = ""
var _league: String = ""
var _capacity: int = 0
var _tier: int = 0
var _week: int = 0
var _works: String = ""
var _objective: String = ""                      # board-objective label -> price tier
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/stadium/chrome.png")
	_improve = load("res://art/screens/stadium/improvements.png")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	_load_scene()
	queue_redraw()


static func tier_for(capacity: int) -> int:
	return clampi(capacity * 11 / MAX_CAPACITY, 0, 11)


func _load_scene() -> void:
	_tier = tier_for(_capacity)
	var p := "res://art/screens/stadium/estadio%d.png" % _tier
	_scene = load(p) if ResourceLoader.exists(p) else null


## Signature preserved for Main._show_stadium_screen (13 args). Only club / manager / season /
## ground / capacity / works / week / league are used now; seated / standing / parking / ticket
## / board are ignored — they fed the removed invented ticket-price + sponsor + split readouts.
func setup(club: String, manager: String, season: String, ground: String,
		capacity: int, _seated: int, _standing: int, _parking: int, works := "",
		_ticket := 0, _board := 0, week := 0, league := "", objective := "") -> void:
	_club = club
	_manager = manager
	_season = season
	_ground = ground
	_league = league
	_objective = objective
	_capacity = maxi(0, capacity)
	_week = week
	_works = works
	_view = "works"          # (re)mount always opens on the WORK IN PROGRESS ledger
	_sel = -1
	_load_scene()
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	# The 2x2 action grid (IMPROVE / WORKS / MATCH DAY / RETURN) is baked in BOTH views:
	# IMPROVE + WORKS toggle the left panel in-screen (frame-true); RETURN leaves; MATCH DAY
	# is inert (disabled/washed in the frame). In the IMPROVE view the offer cards + the SEATS
	# tab are also live. An empty-space tap is a no-op (it used to bounce to the hub).
	if BTN_IMPROVE.has_point(d):
		return "improve"
	if BTN_WORKS.has_point(d):
		return "works"
	if BTN_RETURN.has_point(d):
		return "return"
	if _view == "improve":
		for i in CARDS.size():
			if CARDS[i].has_point(d):
				return "card%d" % i
		if TAB_SEATS.has_point(d):
			return "tab_seats"      # already active; other tabs un-witnessed -> not hit
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
	else:
		var a := _hit(d)
		var was := _press
		_press = ""
		queue_redraw()
		if a == "" or a != was:
			return
		if a == "improve":
			_view = "improve"
			queue_redraw()
		elif a == "works":
			_view = "works"
			queue_redraw()
		elif a == "return":
			back_pressed.emit()
		elif a.begins_with("card"):
			_select_card(int(a.substr(4)))
		# "tab_seats" -> no-op (SEATS is the only witnessed category)


## Open the in-screen IMPROVEMENTS picker (as if IMPROVE were pressed) — for tests/shots.
func open_improve() -> void:
	_view = "improve"
	queue_redraw()


## Tick a SEATS offer card and ask Main to start the works. Only clubs with a WITNESSED
## price can purchase (un-RE'd price = honest gap, no purchase). The ceiling is pre-checked
## here; cash affordability is enforced authoritatively by Career.start_works.
## The club's seat-offer prices: the witnessed board-objective tier. No label
## (a club outside the witnessed English set) -> honest gap (blank, inert).
func _prices() -> Array:
	return TIER_PRICES.get(_objective, [])


func _select_card(i: int) -> void:
	var prices: Array = _prices()
	if prices.is_empty() or i < 0 or i >= OFFER_SEATS.size():
		return
	if _capacity + int(OFFER_SEATS[i]) > MAX_CAPACITY:
		return
	_sel = i
	queue_redraw()
	improve_selected.emit(int(OFFER_SEATS[i]), int(prices[i]), int(OFFER_WEEKS[i]))


# ---- helpers -------------------------------------------------------------

static func fmt_int(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


## Draw `s` in rect `r`, vertically centred; align left (default), right, or centre.
func _cell(f: Font, r: Rect2, s: String, col: Color, sz: int, align := "left") -> void:
	if f == null or s == "":
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := r.position.x
	if align == "right":
		px = r.end.x - w
	elif align == "centre":
		px = r.position.x + (r.size.x - w) * 0.5
	var py := r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)
	draw_string(f, Vector2(px, py), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Shared chrome (same as every career screen), then the frame-baked body over it.
	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "GROUND", _manager, _club, _league, _season, _week, -1)
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)

	# ESTADIO<tier> scene, 1:1 over the baked (Old Trafford) tile.
	if _scene != null:
		draw_texture_rect(_scene, SCENE_BOX, false)

	# Green header: the ground name (GameDB club.stadium; club as a fallback). RIGHT panel is
	# shared by both views (not covered by the IMPROVE overlay), so it draws unconditionally.
	_cell(_f12, R_GROUND, _ground if _ground != "" else _club, C_GROUND_TXT, 13, "centre")

	# CAPACITY value (real Career). CAR PARK / PITCH stay blank — uncaptured, honest gaps.
	_cell(_f10, R_CAP_VAL, "%s seats" % fmt_int(_capacity), C_VALUE_TXT, 11)

	if _view == "improve":
		# IMPROVEMENTS overlay (frame 173) covers the WORK IN PROGRESS left panel; redraw the
		# club's witnessed £ prices into the blanked cells (seats + weeks stay baked). An
		# un-witnessed club leaves the cells blank (honest gap — the price formula is un-RE'd).
		if _improve != null:
			draw_texture_rect(_improve, Rect2(0, 0, W, H), false)
		var prices: Array = _prices()
		for i in PRICE_ANCHORS.size():
			if not prices.is_empty():
				_cell(_f10, PRICE_ANCHORS[i], "£%s" % fmt_int(int(prices[i])), C_PRICE, 11)
			if _sel == i:
				_draw_check(CHECKS[i])
	else:
		# WORK IN PROGRESS ledger: TOTAL IMPROVEMENTS £0 default. An in-progress expansion has
		# no £ amount threaded here (Main passes a status string) -> the SEATS row shows the
		# status; the money total stays honest at £0 (see WIRING note in stadium_screen_re.md).
		_cell(_f10, R_TOTAL, "£0", C_TOTAL_RED, 11, "right")
		if _works != "":
			_cell(_f10, R_SEATS_VAL, _works, C_SEATS_INK, 9, "centre")

	# Press feedback over the baked buttons / cards.
	if _press == "improve":
		draw_rect(BTN_IMPROVE, C_PRESS, true)
	elif _press == "works":
		draw_rect(BTN_WORKS, C_PRESS, true)
	elif _press == "return":
		draw_rect(BTN_RETURN, C_PRESS, true)
	elif _press.begins_with("card"):
		draw_rect(CARDS[int(_press.substr(4))], C_PRESS, true)


## Draw the ticked-box red X (frame 175) inside checkbox rect `r`.
func _draw_check(r: Rect2) -> void:
	draw_line(r.position, r.end, C_XRED, 2.0)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), C_XRED, 2.0)
