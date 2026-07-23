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
## A CAR PARK quadrant / FACILITIES / SERVICES upgrade was ticked -> Main runs
## Career.begin_work(cat, key, label, cost, weeks, effect). Generalises the SEATS-only
## improve_selected to the three unblocked tabs (owner 2026-07-23).
signal works_requested(cat: String, key: int, label: String, cost: int, weeks: int, effect: Dictionary)

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

# ---- IMPROVE sub-tabs (owner frames 2026-07-23, native 640x480) -------------------------
# The IMPROVEMENTS picker has four category tabs; SEATS was the only one witnessed before.
# The owner's Man Utd capture unblocks CAR PARK / FACILITIES / SERVICES (frames 02/03/04,
# 09/10/12). Tab hit rects measured off those frames (SEATS keeps its own rect above).
const TAB_CARPARK := Rect2(148, 113, 124, 18)
const TAB_FACILITIES := Rect2(18, 138, 124, 18)
const TAB_SERVICES := Rect2(148, 138, 124, 18)
const TAB_TITLE_CX := 150.0                      # "CAR PARK" / "FACILITIES" / "EXTRAS" title
const TAB_TITLE_Y := 160.0
const C_TAB_SEL := Color8(210, 0, 0)             # active-tab red outline (frame 09)

# CAR PARK: 4 quadrants NE/NW/SE/SW, each level 1..4 (+500 spaces/level, base level 1 =
# 2,000 spaces). Baked chrome = carpark.png (quadrant art + labels + PER LEVEL panel); the
# 16 level boxes + works triangle are blanked there and redrawn here from Career state.
const QUAD_BOX_X := [[83, 97, 111, 125], [208, 222, 236, 250], [83, 97, 111, 125], [208, 222, 236, 250]]
const QUAD_BOX_Y := [202, 202, 299, 299]
const QUAD_CELL := [Rect2(22, 196, 118, 92), Rect2(147, 196, 118, 92),
	Rect2(22, 293, 118, 88), Rect2(147, 293, 118, 88)]
const QUAD_TRI := [Vector2(95, 229), Vector2(220, 229), Vector2(95, 326), Vector2(220, 326)]
const BOX_SZ := 11
const CAR_MAX := 4
const C_BOX_OWNED := Color8(59, 85, 130)         # filled = an owned level
const C_BOX_BUILD := Color8(210, 0, 0)           # red = the level under construction
# PER LEVEL price value cell (maroon "£2,975,000"). Kept baked for the witnessed club;
# covered (honest gap) + made inert for any club without a witnessed car-park price.
const CARPARK_PRICE_CELL := Rect2(136, 418, 88, 15)
const CARPARK_PER_LEVEL_SPACES := 500
const CARPARK_PER_LEVEL_WEEKS := 7

# FACILITIES / SERVICES: item bars over a detail panel. Only the ONE item per tab witnessed
# on the owner's Man Utd capture (CHANGING ROOMS £225k / MEDICAL EQUIPMENT £150k) is
# purchasable; every other item + grade is un-witnessed -> HONEST GAP (listed, but inert, no
# detail). Item lists are the game's own fixed labels (frames 03/04/10/12).
const FAC_ITEMS := ["FLOODLIGHTS", "UNDER-SOIL HEATING", "CHANGING ROOMS", "SCORE BOARD",
	"ACCESS TO THE STADIUM"]
const SVC_ITEMS := ["MEDICAL EQUIPMENT", "CLUB SHOP", "CAFES", "TOILETS"]
const ITEM_BAR_X := 18
const ITEM_BAR_W := 254
const ITEM_BAR_H := 13
const ITEM_BAR_Y0 := 185
const ITEM_BAR_PITCH := 18
# Witnessed item per tab: index -> {grades, current grade, upgrade cost/weeks, ledger label,
# icon sprite, effect-cat}. current/grade indices are 0-based within `grades`.
const FAC_WITNESS := {
	2: {"grades": ["BASIC", "MEDIUM", "COMPLETE"], "current": 1, "cost": 225000, "weeks": 3,
		"ledger": "CHANG. ROOMS", "icon": "chgrooms"},
}
const SVC_WITNESS := {
	0: {"grades": ["BASIC", "COMPLETE", "I.C.U."], "current": 1, "cost": 150000, "weeks": 2,
		"ledger": "SICKROOM", "icon": "medical"},
}
const DETAIL_HDR := Rect2(15, 284, 258, 26)      # grey-blue header bar (frame y284..310)
const DETAIL_ICON := Vector2(17, 284)            # 34x26 svc_<icon>.png
const DETAIL_NAME_CX := 162.0
const DETAIL_NAME_Y := 290.0
const DETAIL_BODY := Rect2(15, 310, 258, 135)    # light-grey detail body
const DETAIL_PRICE_LBL_X := 30.0
const DETAIL_VAL_X := 130.0
const DETAIL_PRICE_Y := 319.0
const DETAIL_WEEKS_Y := 337.0
const GRADE_BOX_X := 40
const GRADE_Y0 := 354                            # BASIC row top (MEDIUM +18 = current highlight)
const GRADE_PITCH := 18
const GRADE_LABEL_X := 62.0
const C_ITEM_BAR := Color8(0, 0, 0)
const C_HDR_BG := Color8(96, 112, 128)           # detail header grey-blue
const C_BODY_BG := Color8(220, 220, 220)         # detail body light grey
const C_HILITE := Color8(56, 78, 128)            # current-grade highlight bar
const C_PRICE_RED := Color8(164, 32, 32)
const C_WEEKS_GREEN := Color8(40, 130, 40)
const C_GRADE_GREY := Color8(128, 128, 128)      # a lower/other grade box
const C_SEL_GOLD := Color8(210, 160, 40)         # selected item-bar outline (frame 10)

# WORK IN PROGRESS ledger rows (frame 07): each live work lands in its section row with a
# TO BE PAID (£) + WEEK; the SEATS / CAR PARK rows also show the built quantity. Row centres
# + column centres measured off frame 07 (native 640x480).
const LEDGER_VAL_X := 40.0                        # SEATS/CAR PARK value ("N seats"/"N spaces")
const LEDGER_PAID_CX := 192.0                     # TO BE PAID (£) column centre
const LEDGER_WEEK_CX := 263.0                     # WEEK column centre
const LEDGER_SEATS_Y := 146                       # SEATS value-row centre
const LEDGER_CARPARK_Y := 196                     # CAR PARK value-row centre
const LEDGER_FAC_Y0 := 244                        # FLOODLIGHTS row centre (rows +20 each)
const LEDGER_SVC_Y0 := 374                        # SICKROOM row centre
const LEDGER_ROW_PITCH := 20
const C_LED_SEATS := Color8(42, 63, 170)          # SEATS / CAR PARK ink (blue)
const C_LED_FAC := Color8(40, 110, 40)            # FACILITIES ink (green)
const C_LED_SVC := Color8(150, 30, 30)            # SERVICES ink (maroon)

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
const C_WHITE := Color8(255, 255, 255)
const C_BLACK := Color8(0, 0, 0)
const C_GROUND_TXT := Color8(255, 255, 255)
const C_VALUE_TXT := Color8(200, 220, 240)
const C_TOTAL_RED := Color8(170, 0, 0)
const C_SEATS_INK := Color8(40, 60, 130)         # SEATS section blue (matches its column heads)
const C_PRESS := Color(1, 1, 1, 0.18)
const C_PRICE := Color8(150, 0, 0)               # £ offer price ink (frame-sampled)
const C_XRED := Color8(210, 0, 0)                # ticked-box red X (frame 175)

var _chrome: Texture2D
var _improve: Texture2D
var _carpark: Texture2D
var _svc_icons := {}                             # "chgrooms"/"medical" -> Texture2D
var _obras: Texture2D                            # works triangle (shared)
var _scene: Texture2D
var _f12: Font
var _f10: Font
var _f8: Font
var _view := "works"                             # "works" (ledger) | "improve" (picker)
var _tab := "seats"                              # improve sub-tab: seats|carpark|facilities|services
var _sel := -1                                   # ticked SEATS offer card (-1 none)

# GROUND state fed from Career (set_improve_state). Empty defaults keep the SEATS-only
# callers + tests rendering unchanged.
var _car_levels: Array = [1, 1, 1, 1]
var _car_price: int = 0                          # 0 = un-witnessed club -> honest gap
var _works_list: Array = []                      # live works (in-progress markers + ledger)
var _grades: Dictionary = {}                     # ground_grades ("cat:key" -> grade)
var _total: int = 0                              # TOTAL IMPROVEMENTS
var _fac_sel: int = 2                            # selected FACILITIES item (default CHANG. ROOMS)
var _svc_sel: int = 0                            # selected SERVICES item (default MEDICAL)

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
	_carpark = load("res://art/screens/stadium/carpark.png")
	_obras = load("res://art/screens/stadium/obras.png")
	for k in ["chgrooms", "medical"]:
		var p := "res://art/screens/stadium/svc_%s.png" % k
		if ResourceLoader.exists(p):
			_svc_icons[k] = load(p)
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	_f8 = PMChrome.font("8")
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
	_tab = "seats"
	_sel = -1
	_load_scene()
	queue_redraw()


## Feed the live GROUND state used by the CAR PARK / FACILITIES / SERVICES tabs + the WORK
## IN PROGRESS ledger. Main derives it from Career (car_park_levels, works, ground_grades,
## the witnessed per-level car-park price, TOTAL IMPROVEMENTS). Optional -- SEATS-only
## callers / tests leave the defaults and render exactly as before.
func set_improve_state(car_levels: Array, car_price: int, works: Array, grades: Dictionary,
		total: int) -> void:
	_car_levels = car_levels if car_levels.size() == 4 else [1, 1, 1, 1]
	_car_price = maxi(0, car_price)
	_works_list = works
	_grades = grades
	_total = maxi(0, total)
	queue_redraw()


## In-progress work on one (cat,key), or {} if none — for the build markers + the ledger.
func _work_for(cat: String, key: int) -> Dictionary:
	for w in _works_list:
		if str(w.get("cat")) == cat and int(w.get("key", -1)) == key:
			return w
	return {}


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _item_rect(i: int) -> Rect2:
	return Rect2(ITEM_BAR_X, ITEM_BAR_Y0 + ITEM_BAR_PITCH * i, ITEM_BAR_W, ITEM_BAR_H)


func _grade_rect(g: int) -> Rect2:
	return Rect2(ITEM_BAR_X, GRADE_Y0 + GRADE_PITCH * g, ITEM_BAR_W, ITEM_BAR_H)


func _hit(d: Vector2) -> String:
	# The 2x2 action grid (IMPROVE / WORKS / MATCH DAY / RETURN) is baked in BOTH views:
	# IMPROVE + WORKS toggle the left panel in-screen (frame-true); RETURN leaves; MATCH DAY
	# is inert (disabled/washed in the frame). An empty-space tap is a no-op.
	if BTN_IMPROVE.has_point(d):
		return "improve"
	if BTN_WORKS.has_point(d):
		return "works"
	if BTN_RETURN.has_point(d):
		return "return"
	if _view != "improve":
		return ""
	# category tabs (live in every improve sub-view)
	if TAB_SEATS.has_point(d):
		return "tab:seats"
	if TAB_CARPARK.has_point(d):
		return "tab:carpark"
	if TAB_FACILITIES.has_point(d):
		return "tab:facilities"
	if TAB_SERVICES.has_point(d):
		return "tab:services"
	match _tab:
		"seats":
			for i in CARDS.size():
				if CARDS[i].has_point(d):
					return "card%d" % i
		"carpark":
			for q in QUAD_CELL.size():
				if (QUAD_CELL[q] as Rect2).has_point(d):
					return "quad%d" % q
		"facilities":
			for i in FAC_ITEMS.size():
				if _item_rect(i).has_point(d):
					return "fac%d" % i
			var wf: Dictionary = FAC_WITNESS.get(_fac_sel, {})
			if not wf.is_empty():
				var nxt: int = int(_grade_of("facility", _fac_sel, wf)) + 1
				if nxt < (wf["grades"] as Array).size() and _grade_rect(nxt).has_point(d):
					return "facbuy"
		"services":
			for i in SVC_ITEMS.size():
				if _item_rect(i).has_point(d):
					return "svc%d" % i
			var ws: Dictionary = SVC_WITNESS.get(_svc_sel, {})
			if not ws.is_empty():
				var nxt2: int = int(_grade_of("service", _svc_sel, ws)) + 1
				if nxt2 < (ws["grades"] as Array).size() and _grade_rect(nxt2).has_point(d):
					return "svcbuy"
	return ""


## The current grade of a witnessed FACILITIES/SERVICES item: the club's stored upgrade if
## any, else the witnessed default (Man Utd's captured level).
func _grade_of(cat: String, item: int, witness: Dictionary) -> int:
	return int(_grades.get("%s:%d" % [cat, item], int(witness.get("current", 0))))


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
		elif a.begins_with("tab:"):
			_tab = a.substr(4)
			_sel = -1
			queue_redraw()
		elif a.begins_with("card"):
			_select_card(int(a.substr(4)))
		elif a.begins_with("quad"):
			_buy_carpark(int(a.substr(4)))
		elif a.begins_with("fac") and a != "facbuy":
			_fac_sel = int(a.substr(3))
			queue_redraw()
		elif a.begins_with("svc") and a != "svcbuy":
			_svc_sel = int(a.substr(3))
			queue_redraw()
		elif a == "facbuy":
			_buy_grade("facility", _fac_sel, FAC_WITNESS.get(_fac_sel, {}))
		elif a == "svcbuy":
			_buy_grade("service", _svc_sel, SVC_WITNESS.get(_svc_sel, {}))


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


## Tick a CAR PARK quadrant -> start a +1-level work (+500 spaces). Un-witnessed club (no
## per-level price) or a maxed / already-building quadrant is a no-op (honest gap). Cash is
## enforced authoritatively by Career.begin_work.
func _buy_carpark(q: int) -> void:
	if _car_price <= 0 or q < 0 or q >= _car_levels.size():
		return
	if int(_car_levels[q]) >= CAR_MAX or not _work_for("carpark", q).is_empty():
		return
	works_requested.emit("carpark", q, "500 spaces", _car_price, CARPARK_PER_LEVEL_WEEKS,
		{"added": CARPARK_PER_LEVEL_SPACES})


## Tick the next grade of the witnessed FACILITIES/SERVICES item -> start its upgrade work.
## Un-witnessed item, a max-grade item, or one already building is a no-op (honest gap).
func _buy_grade(cat: String, item: int, witness: Dictionary) -> void:
	if witness.is_empty() or not _work_for(cat, item).is_empty():
		return
	var nxt: int = _grade_of(cat, item, witness) + 1
	if nxt >= (witness["grades"] as Array).size():
		return
	works_requested.emit(cat, item, str(witness["ledger"]), int(witness["cost"]),
		int(witness["weeks"]), {"grade": nxt})


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
		# Shared IMPROVEMENTS title + 4 category tabs (frame 173 bake). Each sub-tab then draws
		# its own body over the SEATS body baked into improvements.png.
		if _improve != null:
			draw_texture_rect(_improve, Rect2(0, 0, W, H), false)
		match _tab:
			"carpark": _draw_carpark()
			"facilities": _draw_item_tab("facility", FAC_ITEMS, FAC_WITNESS, _fac_sel)
			"services": _draw_item_tab("service", SVC_ITEMS, SVC_WITNESS, _svc_sel)
			_: _draw_seats_prices()
		_draw_tab_outline()
		# TOTAL IMPROVEMENTS shows the live works sum in the picker too (frames 09/10/12),
		# overriding the £0 baked into improvements.png.
		_cell(_f10, R_TOTAL, "£%s" % fmt_int(_total), C_TOTAL_RED, 11, "right")
	else:
		# WORK IN PROGRESS ledger (frame 07): several works can run at once, each a row with
		# its own TO BE PAID / WEEK, summed into TOTAL IMPROVEMENTS. Rows are drawn from the
		# live works list; TOTAL is their outstanding-cost sum.
		_draw_works_ledger()

	# Press feedback over the baked buttons / cards.
	if _press == "improve":
		draw_rect(BTN_IMPROVE, C_PRESS, true)
	elif _press == "works":
		draw_rect(BTN_WORKS, C_PRESS, true)
	elif _press == "return":
		draw_rect(BTN_RETURN, C_PRESS, true)
	elif _press.begins_with("card"):
		draw_rect(CARDS[int(_press.substr(4))], C_PRESS, true)


## WORK IN PROGRESS ledger (frame 07): each live work drawn into its section row, TOTAL =
## the outstanding-cost sum. Row labels/columns are baked in chrome.png; this fills the
## dynamic value / TO BE PAID / WEEK cells + the works triangle.
func _draw_works_ledger() -> void:
	for w in _works_list:
		var cat := str(w.get("cat"))
		var y := _ledger_row_y(cat, int(w.get("key", 0)))
		if y < 0:
			continue
		var col := C_LED_SEATS
		if cat == "facility":
			col = C_LED_FAC
		elif cat == "service":
			col = C_LED_SVC
		if _obras != null:
			draw_texture_rect(_obras, Rect2(18, y - 8, 16, 15), false)
		if cat == "seats" or cat == "carpark":
			_cell(_f10, Rect2(LEDGER_VAL_X, y - 8, 140, 16), str(w.get("label", "")), col, 11)
		_cell(_f10, Rect2(LEDGER_PAID_CX - 70, y - 8, 140, 16),
			"£%s" % fmt_int(int(w.get("cost", 0))), col, 11, "centre")
		_cell(_f10, Rect2(LEDGER_WEEK_CX - 35, y - 8, 70, 16),
			str(int(w.get("weeks_left", 0))), col, 11, "centre")
	_cell(_f10, R_TOTAL, "£%s" % fmt_int(_total), C_TOTAL_RED, 11, "right")


func _ledger_row_y(cat: String, key: int) -> int:
	match cat:
		"seats": return LEDGER_SEATS_Y
		"carpark": return LEDGER_CARPARK_Y
		"facility": return LEDGER_FAC_Y0 + LEDGER_ROW_PITCH * key
		"service": return LEDGER_SVC_Y0 + LEDGER_ROW_PITCH * key
	return -1


## SEATS offer prices + tick (unchanged behaviour, extracted for the sub-tab dispatch).
func _draw_seats_prices() -> void:
	var prices: Array = _prices()
	for i in PRICE_ANCHORS.size():
		if not prices.is_empty():
			_cell(_f10, PRICE_ANCHORS[i], "£%s" % fmt_int(int(prices[i])), C_PRICE, 11)
		if _sel == i:
			_draw_check(CHECKS[i])


## Red outline on the active category tab (frame 09 shows the picked tab ringed red).
func _draw_tab_outline() -> void:
	var r: Rect2 = TAB_SEATS
	match _tab:
		"carpark": r = TAB_CARPARK
		"facilities": r = TAB_FACILITIES
		"services": r = TAB_SERVICES
	draw_rect(r.grow(1.0), C_TAB_SEL, false, 2.0)


# ---- CAR PARK tab (frames 02/09) -----------------------------------------

func _fill_box(bx: int, by: int, col: Color) -> void:
	draw_rect(Rect2(bx + 1, by + 1, BOX_SZ - 2, BOX_SZ - 2), col, true)


func _draw_carpark() -> void:
	# baked quadrant art + labels + PER LEVEL panel (level boxes + triangle blanked in the bake)
	if _carpark != null:
		draw_texture_rect(_carpark, Rect2(0, 0, W, H), false)
	for q in QUAD_BOX_X.size():
		var lvl := clampi(int(_car_levels[q]), 0, CAR_MAX)
		var building := -1
		if not _work_for("carpark", q).is_empty():
			building = lvl                       # the level being built = box index `lvl`
		for b in 4:
			var bx: int = QUAD_BOX_X[q][b]
			var by: int = QUAD_BOX_Y[q]
			if b < lvl:
				_fill_box(bx, by, C_BOX_OWNED)
			elif b == building:
				_fill_box(bx, by, C_BOX_BUILD)
		if building >= 0 and _obras != null:
			draw_texture_rect(_obras, Rect2(QUAD_TRI[q], Vector2(22, 21)), false)
	# PER LEVEL price: baked £2,975,000 stays for the witnessed club; blank it (honest gap)
	# for any club whose per-level car-park price is un-witnessed (the cost fn is un-RE'd).
	if _car_price <= 0:
		draw_rect(CARPARK_PRICE_CELL, C_WHITE, true)


# ---- FACILITIES / SERVICES tabs (frames 03/04/10/12) ----------------------

func _draw_item_tab(cat: String, items: Array, witness_map: Dictionary, sel: int) -> void:
	# wipe the SEATS body baked into improvements.png, then draw this tab's list + detail
	draw_rect(Rect2(16, 158, 262, 288), C_WHITE, true)
	var title := "EXTRAS" if cat == "service" else "FACILITIES"
	_cell(_f12, Rect2(50, TAB_TITLE_Y, 200, 16), title, C_BLACK, 13, "centre")
	for i in items.size():
		var r := _item_rect(i)
		draw_rect(r, C_ITEM_BAR, true)
		_cell(_f10, r, str(items[i]), C_WHITE, 11, "centre")
	if sel >= 0 and sel < items.size():
		draw_rect(_item_rect(sel).grow(1.0), C_SEL_GOLD, false, 2.0)
	var w: Dictionary = witness_map.get(sel, {})
	if not w.is_empty():
		_draw_item_detail(cat, sel, items, w)


func _draw_item_detail(cat: String, item: int, items: Array, w: Dictionary) -> void:
	draw_rect(DETAIL_HDR, C_HDR_BG, true)
	var icon: Texture2D = _svc_icons.get(str(w.get("icon")))
	if icon != null:
		draw_texture(icon, DETAIL_ICON)
	_cell(_f12, Rect2(DETAIL_NAME_CX - 130, DETAIL_NAME_Y, 260, 16), str(items[item]), C_WHITE, 12, "centre")
	draw_rect(DETAIL_BODY, C_BODY_BG, true)
	var grades: Array = w["grades"]
	var cur: int = _grade_of(cat, item, w)
	var building := not _work_for(cat, item).is_empty()
	# PRICE / WEEKS of the next upgrade (blank once max grade is reached)
	if cur + 1 < grades.size():
		_txt10(DETAIL_PRICE_LBL_X, DETAIL_PRICE_Y, "PRICE:", C_PRICE_RED)
		_txt10(DETAIL_VAL_X, DETAIL_PRICE_Y, "£%s" % fmt_int(int(w["cost"])), C_PRICE_RED)
		_txt10(DETAIL_PRICE_LBL_X, DETAIL_WEEKS_Y, "WEEKS:", C_BLACK)
		_txt10(DETAIL_VAL_X, DETAIL_WEEKS_Y, "%d weeks" % int(w["weeks"]), C_WEEKS_GREEN)
	for g in grades.size():
		var y := GRADE_Y0 + GRADE_PITCH * g
		var boxr := Rect2(GRADE_BOX_X, y + 1, 12, 12)
		if g == cur:
			draw_rect(Rect2(56, y - 1, 216, 15), C_HILITE, true)   # current-grade highlight bar
			_fill_grade_box(boxr, C_BLACK)
		elif building and g == cur + 1:
			_fill_grade_box(boxr, C_BOX_BUILD)
			if _obras != null:
				draw_texture_rect(_obras, Rect2(18, y, 18, 14), false)
		else:
			_fill_grade_box(boxr, C_GRADE_GREY)
		_txt10(GRADE_LABEL_X, float(y), str(grades[g]), C_WHITE if g == cur else C_BLACK)


func _fill_grade_box(r: Rect2, fill: Color) -> void:
	draw_rect(r, C_BLACK, true)
	draw_rect(Rect2(r.position + Vector2.ONE, r.size - Vector2(2, 2)), fill, true)


## Left-aligned proman10 text at a glyph-top y (small helper for the detail panel labels).
func _txt10(x: float, y_top: float, s: String, col: Color) -> void:
	draw_string(_f10, Vector2(x, y_top + _f10.get_ascent(11)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


## Draw the ticked-box red X (frame 175) inside checkbox rect `r`.
func _draw_check(r: Rect2) -> void:
	draw_line(r.position, r.end, C_XRED, 2.0)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), C_XRED, 2.0)
