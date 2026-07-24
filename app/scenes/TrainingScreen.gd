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
## HONEST GAPS (flagged, never invented — training_screen_re.md §Gaps): PM98's
## per-player FOCUS tags (HA/TA/PA/SH) and the AUTO assignment, the per-skill
## right-panel FOCUS row + "last" column, the per-skill CURRENT TRAINING STAFF
## coaches, the FI (fitness) grid column, and per-section scrolling are mechanics
## the app's training model (Training.gd = intensity + passive development) does
## not implement; their furniture stays at the resting look and no value is faked.
## AUTO is a documented no-op. Native 640x480; scales to fit its parent.

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

const R_AUTO := Rect2(348, 444, 84, 30)
const R_TACTICS := Rect2(448, 444, 84, 30)
const R_RETURN := Rect2(548, 444, 84, 30)

# ---- frame-sampled inks (baker samples + this session's probes) ----
const C_NUM := Color8(0, 0, 128)      # grid_n
const C_NAME := Color8(0, 0, 0)
const C_AV := Color8(210, 0, 0)       # grid_av
const C_AV_SEL := Color8(255, 0, 0)   # grid_av_sel
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
		var bucket: Array = _buckets.get(str(sect["key"]), [])
		var tops: Array = sect["tops"]
		for i in mini(bucket.size(), tops.size()):
			if Rect2(BAR_X0, float(tops[i]), BAR_W, BAR_H).has_point(d):
				return int((bucket[i] as Dictionary).get("id", -1))
	return -1


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
	var pid := _grid_pid_at(d)
	if pid >= 0:
		return "grid:%d" % pid
	return ""


# ---- input ----------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
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
		var bucket: Array = _buckets.get(str(sect["key"]), [])
		var tops: Array = sect["tops"]
		for i in mini(bucket.size(), tops.size()):
			_draw_row(int(tops[i]), bucket[i])


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
	return int(p.get("squadNo", 0))


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
func _draw_tag(y: int, pid: int) -> void:
	var f := str(_focus.get(pid, ""))
	if f == "":
		return
	draw_rect(Rect2(TAG_X, y, TAG_W, BAR_H), Color(Training.FOCUS_COLOUR[f]), true)
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
