extends Control
class_name TrainingScreen
## PM98 TRAINING sub-screen (LINE-UP -> TRAINING). Static chrome is the REAL
## game's resting frame baked verbatim below the shared barra
## (tools/re/build_lineup_subs_chrome_from_frames.py; binding frames run-2
## 004_162346 fresh / 005_162348 tags+TOTAL / 006_162350 Keane selected /
## 010_162401 Butt PASSING-focus). See docs/re/training_screen_re.md. The scene
## draws ONLY the dynamic layer over the baked furniture:
##  - the squad grid, grouped KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS: shirt
##    number (navy) + name (black) + a STARJUGON rating strip (halves=(AV+1)/10)
##    + the AV cell (red). AV = the app's rating (LineupScreen._av_of, mean of
##    the 8 outfield attrs) — the same number the accepted LINE-UP screen shows;
##  - the AVER. right panel for a tapped player: his decoded attributes mapped to
##    PM98's rows (SPEED=VE STAMINA=RE AGGRESSION=AG QUALITY=CA | HANDLING=PO
##    PASSING=PA DRIBBLING=RM HEADING=RG TACKLING=EN SHOOTING=TI, SPEC_BINDING
##    §3), each with its stars + AV value; the AVER header value;
##  - TOTAL TRAINABLE PLAYERS = squad size; grid TOTAL = 0 (rest).
##
##  - the four PER-SECTION SCROLLBARS. The original does NOT cap a section at its
##    visible slot count: each carries its own bar and one arrow click moves the list
##    by one row (witnessed live 2026-07-24, Bolton W with 9 defenders in 6 slots).
##    Both witnessed states render 0 px vs the original —
##    `tools/re/build_training_scroll_from_frames.py` + `shot_training_scroll.gd`.
##
## CLOSED 2026-07-25: the FI (fitness) grid column now shows the player's condition
## byte, and the four witnessed focus chips (HA/PA/TA/SH) are drawn as the frame's own
## art instead of a synthesised plate — their plate colours are an independent table and
## PASSING/TACKLING were being drawn in the wrong colour.
##
## HONEST GAPS (flagged, never invented — training_screen_re.md §Gaps): the DRIBBLING /
## HEADING / GENERAL / FITNESS chips (no capture has those coaches hired with a man
## assigned) and the right-panel "last" column. Native 640x480; scales to fit its parent.

signal back_pressed        # RETURN -> Main reopens LINE-UP
signal tactics_pressed     # TACTICS -> Main opens the TEAM TACTICS board
signal focus_toggled(pid: int, focus: String)   # a right-panel skill box was ticked
signal auto_pressed        # AUTO -> Career.auto_training_focus()

const W := 640
const H := 480
const BODY_Y0 := 62

# ---- frame-baked geometry (tools/re/specs/lineup_subs_samples.json + baker) --
const TITLE_XY := Vector2(250, 22)
# grid section row-bar tops (design y); bar fill x16..286 h13 (baker TR_SECT_TOPS)
const SECT := [
	{"key": "gk", "tops": [88, 104, 120], "pos": ["GK"]},   # 3rd slot measured live 2026-07-24
	{"key": "def", "tops": [151, 167, 183, 199, 215, 231], "pos": ["DF"]},
	{"key": "mid", "tops": [263, 279, 295, 311, 327, 343], "pos": ["MF"]},
	{"key": "fwd", "tops": [375, 391, 407, 423, 439], "pos": ["FW"]},
]
const BAR_X0 := 16
const BAR_W := 270            # fill x16..286
const BAR_H := 13
const NUM_CELL := [16, 21]    # GDI-centred shirt-number cell (frame: "1"/"17" -> centre 26)
const NAME_X := 53            # names align under the KEEPERS/DEFENDERS headers
const NAME_W := 108.0
const STAR_X0 := 163          # STARJUGON grid strip
const STAR_PITCH := 14
# FI (fitness) and AV cells, both GDI-centred. Measured on tn4 row y88 (Ward, FI 70 AV 64):
# the FI digits ink x240..254, the AV digits x265..279 — centres 247 and 272.
const FI_CELL := [236, 22]
const AV_CELL := [261, 22]    # frame: AV digits x265..279

# right panel (selected player) — sub-rows (design y) + the decoded attr they map to
const PANEL_NUM := [356, 16]
const PANEL_NAME_X := 384
const AVER_VAL_RIGHT := 626   # AVER header value, right-aligned
const RP_STAR_X0 := 481
const RP_STAR_PITCH := 14
const RP_VAL_CELL := [597, 26]  # the AV column value cell
# (row_y, attr_key, on_strip): _fit rows are honest GAPS (skipped)
const RP_ROWS := [
	[130, "VE", false], [144, "RE", false], [158, "AG", false], [172, "CA", false],
	[186, "_fit", true], [200, "PO", true], [214, "PA", true], [228, "RM", true],
	[242, "RG", true], [256, "EN", true], [270, "TI", true],
]

const TTP_CELL := [606, 28]   # TOTAL TRAINABLE PLAYERS value (white on navy band)
const TTP_Y := 418
const TOTAL_CELL := [287, 24] # grid TOTAL value (black on green cell)
const TOTAL_Y := 456

# CURRENT TRAINING STAFF band (measured off a live capture 2026-07-24, tn1): six rows
# 16px apart, each = the baked skill label + a name bar and a TP cell.
const STAFF_ROW_Y0 := 319
const STAFF_ROW_PITCH := 16
const STAFF_ROW_H := 12
const STAFF_BAR := [439, 167]      # name-bar x, width (439..605)
const STAFF_NAME_X := 442
const STAFF_STAR_RIGHT := 604      # star strip right-aligns here
const STAFF_TP_CELL := [610, 22]   # TP digits cell (610..631)
const STAFF_TP_COL := Color8(200, 255, 160)
# Focus check boxes: one per AVER.-panel row, in the frame's own row order. The box sits
# left of the row label (x357..368 on the capture); a live box is gold.
const FOCUS_BOX_X := 357
const FOCUS_BOX_W := 12
const FOCUS_ROW_Y := [116, 186, 200, 214, 228, 242, 256, 270]   # GENERAL, FITNESS, then the 6 skills
const C_FOCUS_ON := Color8(255, 208, 0)
const C_FOCUS_BRD := Color8(0, 0, 0)
# Grid tag chip: right of the row bar (bar ends x286), 21x12 as the frame's tag cuts.
const TAG_X := 288
const TAG_W := 21
const TAG_H := 12

# ---- per-section scrollbars (frame-measured, see tools/re/build_training_scroll_from_frames.py)
# The original SCROLLS each section — it does NOT cap the squad. Witnessed live
# 2026-07-24 on a Bolton W career with 9 defenders in 6 slots: the DEFENDERS bar is
# enabled with the thumb parked at the top, and one DOWN click moves the list by ONE
# row (Todd out at the top, Whitlow in at the bottom). Before this the grid drew only
# `mini(bucket.size(), tops.size())` players, so anything past a section's slot count
# was silently dropped — and `Career` appends a new signing to the END of the squad,
# which is why the owner's new men "never appeared in TRAINING".
const SCROLL_X := 313
const SCROLL_W := 16
const SCROLL_BTN_H := 16   # 16 + 62 + 16 == the 94-row DEFENDERS band exactly
# section key -> [band_y, band_h]
const SCROLL_BAND := {"gk": [87, 46], "def": [150, 94], "mid": [262, 94], "fwd": [374, 78]}

const R_AUTO := Rect2(348, 444, 84, 30)
const R_TACTICS := Rect2(448, 444, 84, 30)
const R_RETURN := Rect2(548, 444, 84, 30)

# ---- frame-sampled inks (baker samples + this session's probes) ----
const C_NUM := Color8(0, 0, 128)      # grid_n
const C_NAME := Color8(0, 0, 0)
const C_AV := Color8(210, 0, 0)       # grid_av
const C_AV_SEL := Color8(255, 0, 0)   # grid_av_sel
const C_FI := Color8(42, 95, 170)     # tn4 FI digits on a resting row
const C_FI_SEL := Color8(92, 126, 174) # tn4 FI digits on the selected (black) row
const C_RP_VAL := Color8(59, 85, 130) # rp_av / AVER value
const C_TOTAL := Color8(0, 0, 0)
const C_TTP := Color8(255, 255, 255)
const C_WHITE := Color8(255, 255, 255)
const C_PRESS := Color(1, 1, 1, 0.20)
const C_SEL_ROW := Color(0, 0, 0, 1)  # frame 006: the selected grid row is a black bar

var _club: Dictionary = {}
var _staff: Array = []                # the hired backroom staff (the six skill coaches)
var _focus: Dictionary = {}           # pid:int -> Training focus row
var _header: Dictionary = {}
var _by_id: Dictionary = {}
var _buckets: Dictionary = {}         # section key -> Array[player]
var _sel_pid := -1
var _press := ""
var _drag := PMTouch.Drag.new()       # grid drag-to-scroll (input layer only)
var _drag_key := ""                   # the section band the drag armed over
var _alert_img: Texture2D             # modal PM98 box (refusals); null = none
var _alert_box := Rect2i()

var _f8: Font
var _f10: Font
var _chrome: Texture2D
var _title: Texture2D
var _star_on: Texture2D
var _star_off: Texture2D
var _star_sel_on: Texture2D
var _star_sel_off: Texture2D
var _rp_star_on: Texture2D
var _rp_star_off: Texture2D
var _rp_star_strip: Texture2D
var _sc_up: Texture2D
var _sc_dn: Texture2D
var _sc_track: Texture2D
var _sc_thumb_top: Texture2D
var _sc_thumb_mid: Texture2D
var _sc_thumb_bot: Texture2D
var _sc_up_off: Texture2D
var _sc_dn_off: Texture2D
var _sc_off: Dictionary = {}          # band height -> the original's resting bar
var _scroll: Dictionary = {}          # section key -> first visible index
var _tags: Dictionary = {}            # focus name -> the frame-cut chip (witnessed four)


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/training/chrome.png")
	_title = load("res://art/screens/training/title.png")
	_star_on = load("res://art/screens/training/star_on.png")
	_star_off = load("res://art/screens/training/star_off.png")
	_star_sel_on = load("res://art/screens/training/star_sel_on.png")
	_star_sel_off = load("res://art/screens/training/star_sel_off.png")
	_rp_star_on = load("res://art/screens/training/rp_star_on.png")
	_rp_star_off = load("res://art/screens/training/rp_star_off.png")
	_rp_star_strip = load("res://art/screens/training/rp_star_on_strip.png")
	_sc_up = load("res://art/screens/training/scroll_up_on.png")
	_sc_dn = load("res://art/screens/training/scroll_dn_on.png")
	_sc_track = load("res://art/screens/training/scroll_track_on.png")
	_sc_thumb_top = load("res://art/screens/training/scroll_thumb_top.png")
	_sc_thumb_mid = load("res://art/screens/training/scroll_thumb_mid.png")
	_sc_thumb_bot = load("res://art/screens/training/scroll_thumb_bot.png")
	_sc_up_off = load("res://art/screens/training/scroll_up_off.png")
	_sc_dn_off = load("res://art/screens/training/scroll_dn_off.png")
	for bh in [46, 94]:
		var p := "res://art/screens/training/scroll_off_%d.png" % bh
		if ResourceLoader.exists(p):
			_sc_off[bh] = load(p)
	for focus in Training.TAG_ART:
		var tp := "res://art/screens/training/tag_%s.png" % str(Training.TAG_ART[focus])
		if ResourceLoader.exists(tp):
			_tags[focus] = load(tp)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, staff: Array = [], header: Dictionary = {},
		focus: Dictionary = {}) -> void:
	_club = club
	_staff = staff
	_focus = focus
	_header = header
	if _header.is_empty():
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1))}
	_by_id.clear()
	_buckets = {"gk": [], "def": [], "mid": [], "fwd": []}
	for p in club.get("players", []):
		var pd: Dictionary = p
		_by_id[int(pd.get("id", -1))] = pd
		_buckets[_section_of(pd)].append(pd)
	_sel_pid = -1
	queue_redraw()


## Which grid section a player belongs to (GK by isGK/pos; DF/MF/FW by pos; an
## unclassified outfielder falls into MIDFIELDERS so no man is dropped silently).
func _section_of(p: Dictionary) -> String:
	if bool(p.get("isGK", false)) or str(p.get("pos", "")) == "GK":
		return "gk"
	match str(p.get("pos", "")):
		"DF": return "def"
		"FW": return "fwd"
		_: return "mid"


# ---- app rating (identical to LineupScreen._av_of) ------------------------
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

func _av_of(p: Dictionary) -> int:
	if p.has("av"):
		return int(p["av"])
	if p.has("morale") or p.has("fitness"):
		return Morale.av6(p)
	var attrs: Variant = p.get("attrs", {})
	if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
		return 0
	var a: Dictionary = attrs
	var sum := 0.0
	var n := 0
	for k in AVG_KEYS:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


## The player pid under a design point in the grid, or -1.
func _grid_pid_at(d: Vector2) -> int:
	for sect in SECT:
		var key := str(sect["key"])
		var bucket: Array = _buckets.get(key, [])
		var tops: Array = sect["tops"]
		var first := _first_of(key)
		for i in mini(bucket.size() - first, tops.size()):
			if Rect2(BAR_X0, float(tops[i]), BAR_W, BAR_H).has_point(d):
				return int((bucket[first + i] as Dictionary).get("id", -1))
	return -1


## "scroll:<key>:<-1|1>" when a live section arrow is under `d`, else "".
func _scroll_hit(d: Vector2) -> String:
	for sect in SECT:
		var key := str(sect["key"])
		var bucket: Array = _buckets.get(key, [])
		var slots := _slots_of(key)
		if bucket.size() <= slots:
			continue                      # disabled bar: the arrows are inert
		var band: Array = SCROLL_BAND[key]
		var by := int(band[0])
		var bh := int(band[1])
		var first := _first_of(key)
		# 16x16 steppers, PMTouch-grown: the bars stop at x286 against SCROLL_X
		# (313), and a band's two grown arrow rects stay >= 4 px apart.
		if first > 0 and PMTouch.near(Rect2(SCROLL_X, by, SCROLL_W, SCROLL_BTN_H), d):
			return "scroll:%s:-1" % key
		if first + slots < bucket.size() \
				and PMTouch.near(Rect2(SCROLL_X, by + bh - SCROLL_BTN_H, SCROLL_W, SCROLL_BTN_H), d):
			return "scroll:%s:1" % key
	return ""


func _hit(d: Vector2) -> String:
	if _alert_img != null:
		return "alert_ok"          # any tap answers the single-button box
	if R_AUTO.has_point(d):
		return "auto"
	if _sel_pid >= 0:
		for i in FOCUS_ROW_Y.size():
			if Rect2(FOCUS_BOX_X - 3, FOCUS_ROW_Y[i] - 2, FOCUS_BOX_W + 6, FOCUS_BOX_W + 4).has_point(d):
				return "focus:%d" % i
	if R_TACTICS.has_point(d):
		return "tactics"
	if R_RETURN.has_point(d):
		return "return"
	var sc := _scroll_hit(d)
	if sc != "":
		return sc
	var pid := _grid_pid_at(d)
	if pid >= 0:
		return "grid:%d" % pid
	return ""


# ---- input ----------------------------------------------------------------

## The section band a design point sits in (bar column only, so the scrollbar
## column at SCROLL_X is excluded), or "". The drag-to-scroll arm region.
func _sect_at(d: Vector2) -> String:
	if d.x < BAR_X0 or d.x >= BAR_X0 + BAR_W:
		return ""
	for sect in SECT:
		var tops: Array = sect["tops"]
		if d.y >= float(tops[0]) and d.y < float(tops[tops.size() - 1]) + BAR_H:
			return str(sect["key"])
	return ""


func _on_input(e: InputEvent) -> void:
	# PMTouch drag-to-scroll inside the pressed section's own bar band; the grid
	# bars sit on a 16 px pitch. Taps already dispatch on release.
	if e is InputEventScreenDrag or e is InputEventMouseMotion:
		var rows := _drag.take_rows(_to_design(e.position).y, 16.0)
		if _drag.moved and _press != "":
			_press = ""                  # a scroll is not a press
			queue_redraw()
		if rows != 0 and _drag_key != "":
			_scroll_by(_drag_key, rows)
		return
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	# a finger tap arrives twice (emulated mouse + real touch) — the grid select and
	# the focus boxes are toggles (PMChrome.is_emulated_pointer_dup)
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		# Arm over a section's player bars only — never on a stepper, the FOCUS
		# boxes or a button, and never under the alert box (PMTouch).
		_drag_key = _sect_at(d) if _alert_img == null and _scroll_hit(d) == "" else ""
		_drag.press(d.y, _drag_key != "")
		queue_redraw()
		return
	if _drag.release():
		_press = ""                      # the gesture scrolled (or a dup) — no tap
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	match was:
		"alert_ok":
			_alert_img = null
			PMChrome.set_dim(false)
			queue_redraw()
		"return":
			back_pressed.emit()
		"tactics":
			tactics_pressed.emit()
		"auto":
			auto_pressed.emit()
		_:
			if was.begins_with("focus:"):
				var fi := int(was.substr(6))
				if _sel_pid >= 0 and fi < Training.FOCUS_ROWS.size():
					focus_toggled.emit(_sel_pid, str(Training.FOCUS_ROWS[fi]))
				return
			if was.begins_with("scroll:"):
				var part := was.split(":")
				_scroll_by(str(part[1]), int(part[2]))
				return
			if was.begins_with("grid:"):
				var pid := int(was.substr(5))
				_sel_pid = -1 if _sel_pid == pid else pid
				queue_redraw()


# ---- drawing --------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "training", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))
	if _title != null:
		draw_texture(_title, TITLE_XY)

	_draw_grid()
	if _sel_pid >= 0 and _by_id.has(_sel_pid):
		_draw_panel(_by_id[_sel_pid])
		_draw_focus_boxes()

	_draw_staff_band()
	# TOTAL TRAINABLE PLAYERS = the sum of the hired coaches' TP; the grid TOTAL is how
	# many players are currently assigned (witnessed 4+2 = 6 trainable, TOTAL 5 after AUTO).
	PMChrome.text(self, _f8, TTP_CELL[0], TTP_Y, str(Training.total_trainable(_staff)),
		C_TTP, 11, 1, float(TTP_CELL[1]))
	PMChrome.text(self, _f8, TOTAL_CELL[0], TOTAL_Y, str(_focus.size()),
		C_TOTAL, 11, 1, float(TOTAL_CELL[1]))

	for kr in [["auto", R_AUTO], ["tactics", R_TACTICS], ["return", R_RETURN]]:
		if _press == str(kr[0]):
			draw_rect(kr[1], C_PRESS, true)
	if _alert_img != null:
		draw_texture(_alert_img, _alert_box.position)


func _draw_grid() -> void:
	for sect in SECT:
		var key := str(sect["key"])
		var bucket: Array = _buckets.get(key, [])
		var tops: Array = sect["tops"]
		var first := _first_of(key)
		for i in mini(bucket.size() - first, tops.size()):
			_draw_row(int(tops[i]), bucket[first + i])
		_draw_scrollbar(key, bucket.size(), tops.size(), first)


# ---- per-section scrolling ------------------------------------------------

## First visible index of a section, clamped to its current overflow (a sale or a
## signing can shrink the list under the stored offset).
func _first_of(key: String) -> int:
	var bucket: Array = _buckets.get(key, [])
	var slots := _slots_of(key)
	return clampi(int(_scroll.get(key, 0)), 0, maxi(0, bucket.size() - slots))


func _slots_of(key: String) -> int:
	for s in SECT:
		if str(s["key"]) == key:
			return (s["tops"] as Array).size()
	return 0


## The original's own slider grammar (offers_map_re.md; verified 0 px against both
## witnessed DEFENDERS states): thumb height = floor(track * visible / total), thumb
## offset = floor(track * first / total). Arrows light only when they can move.
func _draw_scrollbar(key: String, total: int, visible: int, first: int) -> void:
	var band: Array = SCROLL_BAND[key]
	var by := int(band[0])
	var bh := int(band[1])
	if total <= visible:
		# Nothing to scroll. The baked chrome came from a career whose DEFENDERS section
		# DID scroll, so its plate shows a thumb here — repaint the original's own
		# RESTING bar where a frame witnesses that band height (h 46 KEEPERS, h 94
		# DEF/MID). FORWARDS (h 78) is enabled in every frame we hold, so its resting
		# bar is un-witnessed and the baked plate stands rather than a synthesised one.
		var rest: Texture2D = _sc_off.get(bh)
		if rest != null:
			draw_texture(rest, Vector2(SCROLL_X, by))
		return
	var track_y := by + 16
	var track_h := bh - 32
	if _sc_track != null:
		draw_texture_rect(_sc_track, Rect2(SCROLL_X, track_y, SCROLL_W, track_h), true)
	var th := (track_h * visible) / total
	var ty := track_y + (track_h * first) / total
	if _sc_thumb_top != null and th >= 6:
		draw_texture(_sc_thumb_top, Vector2(SCROLL_X, ty))
		var body := Rect2(SCROLL_X, ty + 3, SCROLL_W, th - 6)
		draw_texture_rect(_sc_thumb_mid, body, true)
		draw_texture(_sc_thumb_bot, Vector2(SCROLL_X, ty + th - 3))
	# Both buttons are always painted — lit when they can move, dim when they cannot —
	# so the baked plate's own arrow never shows through an enabled bar.
	var up: Texture2D = _sc_up if first > 0 else _sc_up_off
	var dn: Texture2D = _sc_dn if first + visible < total else _sc_dn_off
	if up != null:
		draw_texture(up, Vector2(SCROLL_X, by))
	if dn != null:
		draw_texture(dn, Vector2(SCROLL_X, by + bh - SCROLL_BTN_H))


## One arrow click scrolls by ONE row (witnessed: Todd out at the top, Whitlow in at
## the bottom, after a single DOWN click).
func _scroll_by(key: String, delta: int) -> void:
	var bucket: Array = _buckets.get(key, [])
	var slots := _slots_of(key)
	var maxf := maxi(0, bucket.size() - slots)
	_scroll[key] = clampi(_first_of(key) + delta, 0, maxf)
	queue_redraw()


func _draw_row(y: int, p: Dictionary) -> void:
	var pid := int(p.get("id", -1))
	var sel := pid == _sel_pid
	var av := _av_of(p)
	if sel:
		# frame 006: the selected grid row is a black bar with light text +
		# STARJUGON-selected stars.
		draw_rect(Rect2(BAR_X0, y, BAR_W, BAR_H), C_SEL_ROW, true)
	var num := str(_shirt(p))
	var nm := PMChrome.title_case_name(str(p.get("name", "?")))
	PMChrome.text(self, _f8, NUM_CELL[0], y + 1, num,
		C_WHITE if sel else C_NUM, 11, 1, float(NUM_CELL[1]))
	PMChrome.text(self, _f8, NAME_X, y + 1, nm, C_WHITE if sel else C_NAME, 11, 0, NAME_W)
	_draw_stars(STAR_X0, y, av,
		_star_sel_on if sel else _star_on, _star_sel_off if sel else _star_off, STAR_PITCH)
	# FI = the player's condition byte (struct +0xa7, Morale's `fitness` 40..99) — the
	# same value the LINE-UP grid's FI column shows. Was an empty cell until 2026-07-25.
	# 70 is Morale.ensure's own seed, and the value the original prints for every man of a
	# freshly created career (17_training.png, Bolton W week 1: FI 70 down the whole grid).
	PMChrome.text(self, _f8, FI_CELL[0], y + 1, str(int(p.get("fitness", 70))),
		C_FI_SEL if sel else C_FI, 11, 1, float(FI_CELL[1]))
	PMChrome.text(self, _f8, AV_CELL[0], y + 1, str(av),
		C_AV_SEL if sel else C_AV, 11, 1, float(AV_CELL[1]))
	_draw_tag(y, pid)
	if _press == "grid:%d" % pid and not sel:
		draw_rect(Rect2(BAR_X0, y, BAR_W, BAR_H), C_PRESS, true)


## STARJUGON half-star strip (halves=(AV+1) div 10; an odd half draws the dim star).
func _draw_stars(x0: int, y: int, av: int, on: Texture2D, off: Texture2D, pitch: int) -> void:
	var halves := (av + 1) / 10
	var j := 0
	while j < halves / 2:
		if on != null:
			draw_texture(on, Vector2(x0 + pitch * j, y))
		j += 1
	if halves % 2 == 1 and off != null:
		draw_texture(off, Vector2(x0 + pitch * (halves / 2), y))


## The AVER. right panel for the tapped player: header (number/name/AVER value)
## + each decoded attribute on its PM98 row (stars + AV value). FITNESS (_fit)
## is a GAP: the app tracks no per-player fitness, so that row stays blank.
func _draw_panel(p: Dictionary) -> void:
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	PMChrome.text(self, _f10, PANEL_NUM[0], 73, str(_shirt(p)), C_NAME, 12, 1, float(PANEL_NUM[1]))
	PMChrome.text(self, _f10, PANEL_NAME_X, 73,
		PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, 12, 0, 150.0)
	PMChrome.text(self, _f10, AVER_VAL_RIGHT, 73, str(_av_of(p)), C_RP_VAL, 12, 2)
	for row in RP_ROWS:
		var key: String = row[1]
		if key == "_fit" or not attrs.has(key):
			continue   # GAP or unrated: no faked value
		var v := int(attrs[key])
		var on_strip: bool = row[2]
		_draw_stars(RP_STAR_X0, int(row[0]), v,
			_rp_star_strip if on_strip else _rp_star_on, _rp_star_off, RP_STAR_PITCH)
		PMChrome.text(self, _f8, RP_VAL_CELL[0], int(row[0]), str(v),
			C_RP_VAL, 11, 1, float(RP_VAL_CELL[1]))


func _shirt(p: Dictionary) -> int:
	return PMChrome.iget(p, "squadNo")


## CURRENT TRAINING STAFF: the six skill coaches with name, star strip and the TP
## column (= floor(stars)). Rows with no coach hired keep the baked resting bar.
func _draw_staff_band() -> void:
	for i in Training.FOCUS_SKILLS.size():
		var skill := str(Training.FOCUS_SKILLS[i])
		var m := Staff.member_in_role(_staff, skill)
		if m.is_empty():
			continue
		var y := STAFF_ROW_Y0 + i * STAFF_ROW_PITCH
		# The hired row's bar lights up in the skill's own colour (the baked resting bar
		# is the washed version of the same fill).
		draw_rect(Rect2(STAFF_BAR[0], y, STAFF_BAR[1], STAFF_ROW_H),
			Color(Training.FOCUS_COLOUR[skill]), true)
		PMChrome.text(self, _f8, STAFF_NAME_X, y, str(m.get("name", "")), C_WHITE, 11)
		var halves := int(round(float(m.get("stars", 0.0)) * 2.0))
		var full := halves / 2
		var half := halves % 2
		var n := full + half
		var x := STAFF_STAR_RIGHT - n * 11
		for k in full:
			if _star_on != null:
				draw_texture(_star_on, Vector2(x + k * 11, y + 1))
		if half == 1 and _star_off != null:
			draw_texture(_star_off, Vector2(x + full * 11, y + 1))
		PMChrome.text(self, _f8, STAFF_TP_CELL[0], y, str(Training.skill_tp(_staff, skill)),
			STAFF_TP_COL, 11, 1, float(STAFF_TP_CELL[1]))


## The AVER. panel's eight focus check boxes for the selected player: gold when live.
func _draw_focus_boxes() -> void:
	if _sel_pid < 0:
		return
	var live := str(_focus.get(_sel_pid, ""))
	for i in FOCUS_ROW_Y.size():
		var r := Rect2(FOCUS_BOX_X, FOCUS_ROW_Y[i], FOCUS_BOX_W, FOCUS_BOX_W)
		if str(Training.FOCUS_ROWS[i]) == live:
			draw_rect(r, C_FOCUS_ON, true)
			draw_rect(r, C_FOCUS_BRD, false, 1.0)


## The 2-letter focus tag at the right end of an assigned player's grid row.
##
## The four chips the original shows us (HA/PA/TA/SH, frame 005_162348) ship as frame
## cuts and are drawn as ART — their plate colours are their own table, not the staff
## band's, so the old FOCUS_COLOUR fill had PASSING and TACKLING wrong. DRIBBLING /
## HEADING / GENERAL / FITNESS are un-witnessed and fall back to the chip grammar with
## the skill's staff-bar colour (Training.TAG_ART comment).
func _draw_tag(y: int, pid: int) -> void:
	var f := str(_focus.get(pid, ""))
	if f == "":
		return
	var art: Texture2D = _tags.get(f)
	if art != null:
		draw_texture(art, Vector2(TAG_X, y))
		return
	draw_rect(Rect2(TAG_X, y, TAG_W, TAG_H), Color(Training.FOCUS_COLOUR[f]), true)
	PMChrome.text(self, _f8, TAG_X, y + 1, str(Training.FOCUS_CODE[f]), C_WHITE, 11, 1, float(TAG_W))


## Raise the modal "PREMIER MANAGER 98" box over the screen — the original's own
## refusal path (0x2593f0 "You can´t train any more players.", 0x2593b8 the no-trainer
## gate). Any tap answers its OK, like the SCOUT screen's options alert.
func alert(msg: String) -> void:
	if msg.strip_edges() == "":
		return
	_alert_img = ImageTexture.create_from_image(PMAlert.render(msg))
	_alert_box = PMAlert.box_rect(msg)
	PMChrome.set_dim(true)
	queue_redraw()
