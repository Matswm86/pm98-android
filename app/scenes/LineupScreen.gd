extends Control
class_name LineupScreen
## PM98 LINE-UP (ALINEACION) at pixel parity (binding frame 155_162931 + witnesses
## 003/128/131/160; docs/re/lineup_screen_re.md). Static chrome = the REAL frame
## baked verbatim below the shared match-header barra
## (tools/re/build_lineup_chrome_from_frames.py, entry-flow doctrine): table panel,
## column-header band, TEAM RATING strip furniture, nude attr buttons, clean CAMPO,
## UNDO plate, scrollbar, TACTICS/RETURN. This screen draws ONLY the dynamic layer:
##  - squad rows from frame-cut templates per tint class (FUN_004fe2d0 slot bands:
##    gk/def/mid/fwd for the XI; uniform sub/res skins) + ProMan8 number/name,
##    STARJUGON star strip (halves=(AV+1) div 10, odd half = the dimmed star),
##    EURO8 fine-role SHORT name, red AV, CAMROL sprite, POS word;
##  - the UNAVAILABLE row (gold tint template: icon + count + unit boxes) in its two
##    forms -- INJURED (red cross, WEEKS) and SUSPENDED (two yellow cards, MATCHES);
##  - the SELECTED row's 2px black frame + the right-panel name band + attr
##    values (attrs PO/PA/RM/RG/EN/TI — frame-verified: Solskjaer 11/72/84/81/
##    66/79) with STARPARON stars;
##  - the TEAM RATING strip stars (walked per-cell patches; the strip fill is a
##    positional noise dither, so un-walked cells reuse the nearest patch) + value;
##  - the CAMPO mini-pitch composite: green DVERDE/AVERDE markers per formation
##    slot (mk = raw*148/318, *88/198 + (4,3)), the selected slot's coverage-ZONE
##    overlay (walked zones = frame patches; un-walked = majority dim LUT), and
##    the selected slot's WHITE (DBLANCO/ABLANCO) markers on top;
##  - SUBSTITUTES / RESERVES band strips (frame-cut, ball icon + label baked);
##  - the PARAMETERS numeric view (sep cols + per-column inks, witness 128);
##  - state plates: PARAM-active toggles + red arrow (128) / T-I-S vs UNDO.
##
## UNDO rule (walked evidence): TRAINING/INJURIES/STATISTICS show by default
## (003/128/131 — 131 has a SELECTED player and still shows them); UNDO replaces
## them iff the line-up has a PENDING CHANGE — an XI edit this visit (160) or an
## injured player still occupying an XI slot (155). UNDO reverts to the entry XI.
##
## XI editing (select-then-swap) is unchanged: tap selects, second tap swaps via
## Tactics.assign; the GK slot only accepts a keeper (lineup_screen_re.md).
## Native 640x480; scales to fit its parent.

signal back_pressed
signal tactics_pressed    # the TACTICS button -> Main opens the TACTICS board
signal xi_changed         # a player was swapped into/within the XI -> Main persists
signal training_pressed   # TRAINING  (T/I/S plate row 1) -> Main opens TrainingScreen
signal injuries_pressed   # INJURIES  (T/I/S plate row 2) -> Main opens InjuriesScreen
signal statistics_pressed # STATISTICS (T/I/S plate row 3) -> Main opens StatisticsScreen
signal player_info_pressed(player: Dictionary) # the [+] card box at a row's left -> Main opens the FICHA

const W := 640
const H := 480
const BODY_Y0 := 62

# ---- frame-baked geometry (lineup_chrome_samples.json) ----
const TABLE := Rect2(6, 67, 470, 399)     # hit-test extent (borders x7..464)
const XI_Y0 := 88                          # first XI fill top
const ROW_PITCH := 16
const ROW_X := 9                           # template left (card icon)
const ROW_W := 429
const PLUS_W := 15                         # the [+] card box (x9..24, frame 155) -> player FICHA
const BAND_SUB_H := 23
const BAND_RES_H := 22
const NUM_CELL := [33, 17]                 # GDI-centred shirt-number cell
const NAME_X := 67
const STAR_X0 := 172
const STAR_PITCH := 14
const ROLE_RIGHT := 349                    # fine-role right-aligns to the sep col
const AV_CELL := [351, 22]
const CAMROL_X := 374
const POS_CELL := [401, 34]
const NUM_SEPS := [173, 198, 223, 248, 273, 298, 323]
const NUM_CELLS := [[174, 24], [199, 24], [224, 24], [249, 24], [274, 24], [299, 24], [324, 25]]
const INJ_COUNT := [199, 24]               # count digits cell (yellow)
const INJ_WEEKS := [224, 74]               # WEEKS/DAYS label cell (black)
const INJ_FI := [299, 24]
const INJ_MO := [324, 25]
# right panel
const STRIP_STAR_X0 := 512
const STRIP_STAR_PITCH := 15
const STRIP_STAR_Y := 133
const STRIP_VAL_RIGHT := 613               # value right-align x (ProMan10)
const STRIP_VAL_Y := 137
const NAME_BAND := Rect2(478, 150, 152, 21)   # ProMan10 GDI-centred cell
const ATTR_ROWS_Y := [171, 196, 221]
const ATTR_COLS := [[479, 556], [557, 634]]
const ATTR_STAR_DY := 12
const ATTR_VAL_DY := 11
# walked star-strip signatures + anchors (Solskjaer 155): blit the verbatim
# frame strip when the halves count matches; plain glyphs otherwise (the
# glyph shadow is positional noise — documented approximation)
const ATTR_SIG := [1, 7, 8, 8, 6, 8]
const ATTR_XY := [[479, 183], [557, 183], [479, 208], [557, 208], [479, 233], [557, 233]]
const CAMPO_XY := Vector2i(478, 248)
const TIS_XY := Vector2i(474, 348)
const TOGGLE_PARAM := Rect2(477, 68, 157, 24)
const TOGGLE_RATING := Rect2(477, 92, 157, 24)
const ARROW_X := 464
# scrollbar (static in chrome at scroll 0; runtime redraw when scrolled)
const SCROLL_UP := Rect2(443, 388, 16, 16)
const SCROLL_DOWN := Rect2(443, 434, 16, 16)
const THUMB_STRIP_XY := Vector2i(439, 405)
const SCROLL_STEP := 3
const BTN_TACTICS := Rect2(481, 448, 75, 24)
const BTN_RETURN := Rect2(558, 448, 75, 24)
const UNDO_BTN := Rect2(478, 352, 155, 31)
const TIS_BTNS := [Rect2(478, 352, 155, 26), Rect2(478, 380, 155, 26), Rect2(478, 408, 155, 26)]

# ---- frame-sampled inks ----
const C_NUM := Color8(0, 0, 128)
const C_NAME := Color8(0, 0, 0)
const C_ROLE := Color8(100, 120, 140)
const C_AV := Color8(210, 0, 0)
const C_POS := Color8(0, 0, 0)
const C_INJ_COUNT := Color8(255, 255, 0)
const C_INJ_LABEL := Color8(0, 0, 0)
const C_FI := Color8(0, 0, 128)
const C_MO := Color8(80, 110, 5)
const C_STRIP_VAL := Color8(160, 160, 200)
const C_ATTR_VAL := Color8(42, 95, 170)
const C_NAME_BAND := Color8(255, 255, 255)
const NUM_INKS := [Color8(150, 0, 0), Color8(100, 100, 140), Color8(100, 100, 140),
	Color8(100, 100, 140), Color8(100, 100, 140), Color8(42, 95, 170), Color8(80, 110, 5)]
const SEP_INK := {"xi": Color8(128, 128, 128), "sub": Color8(120, 120, 160),
	"res": Color8(100, 120, 140)}

# fine-position (1..18) -> the SHORT role name the LINE-UP rows print (the code-
# embedded switch at 0x567d35..; 14 of 18 frame-witnessed, index = the long table's)
const FINE_ROLE_SHORT := ["KEEPER", "RIGHT BACK", "LEFT BACK", "SWEEPER",
	"INS. CENT. LEFT", "INS. CENT. RIGHT", "RIGHT MID.", "INSIDE RIGHT",
	"CENTRE FORWARD", "CENTRAL MID.", "LEFT MID.", "RIGHT WINGER",
	"CENTRAL STRIKER", "LEFT WINGER", "DEF. MIDFIELDER", "RIGHT FORWARD",
	"LEFT FORWARD", "INSIDE LEFT"]
const POS_WORD := {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]
# PARAMETERS view value sources (form columns; FI/MO live via Morale)
const NUM_KEYS := ["EN", "VE", "RE", "AG", "CA", "_fit", "_mo"]
# attr-button skills: label -> attr key (frame-verified on Solskjaer 155)
const SKILL_KEYS := ["PO", "PA", "RM", "RG", "EN", "TI"]

var _club: Dictionary = {}
var _tactics: Tactics = null
var _division := ""
var _season := "1997-98"
var _week := 0
var _header: Dictionary = {}
var _by_id: Dictionary = {}
var _scroll := 0
var _press := ""
var _sel_pid := -1          # selected player id (-1 none)
var _rating_view := true    # RATING active (chrome default); false = PARAMETERS
var _entry_xi: Array = []   # XI snapshot at setup() — the UNDO baseline
var _forms: Dictionary = {}

var _f8: Font
var _f10: Font
var _f12: Font
var _feuro: Font
var _chrome: Texture2D
var _rows: Dictionary = {}
var _bands: Dictionary = {}
var _star_on: Texture2D
var _star_off: Texture2D
var _paron_on: Texture2D
var _paron_off: Texture2D
var _eq_full: Array = []
var _eq_half: Texture2D
var _eq_nude: Texture2D
var _attr_strips: Array = []
var _plate_tis: Texture2D
var _plate_param_on: Texture2D
var _plate_rating_off: Texture2D
var _arrow_at: Dictionary = {}
var _arrow_off: Dictionary = {}
var _campo_img: Image
var _mk_img: Dictionary = {}        # dverde/averde/dblanco/ablanco -> Image
var _zone_patch: Dictionary = {}    # "352_9" etc -> Image
var _zone_rects: Dictionary = {}
var _zone_lut: Dictionary = {}      # "r,g,b" -> [r,g,b]
var _up_limit: Texture2D
var _thumb_strip: Texture2D
var _track_strip: Texture2D
var _arrow_up_off: Texture2D
var _pitch_cache_key := ""
var _pitch_tex: Texture2D


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_feuro = load("res://art/fonts/euro8.fnt")
	_chrome = load("res://art/screens/lineup/chrome.png")
	for cls in ["gk", "def", "mid", "fwd", "inj", "ban", "sub", "res"]:
		_rows[cls] = load("res://art/screens/lineup/row_%s.png" % cls)
	_bands["sub"] = load("res://art/screens/lineup/band_subs.png")
	_bands["res"] = load("res://art/screens/lineup/band_res.png")
	_star_on = load("res://art/screens/tacticas/star_full.png")
	_star_off = load("res://art/screens/tacticas/star_off.png")
	_paron_on = load("res://art/screens/lineup/star_paron_on.png")
	_paron_off = load("res://art/screens/lineup/star_paron_off.png")
	for j in 4:
		_eq_full.append(load("res://art/screens/lineup/star_eq_full_%d.png" % j))
	_eq_half = load("res://art/screens/lineup/star_eq_half.png")
	_eq_nude = load("res://art/screens/lineup/star_eq_nude.png")
	_plate_tis = load("res://art/screens/lineup/plate_tis.png")
	for i in 6:
		_attr_strips.append(load("res://art/screens/lineup/attr_stars_%d.png" % i))
	_plate_param_on = load("res://art/screens/lineup/plate_param_on.png")
	_plate_rating_off = load("res://art/screens/lineup/plate_rating_off.png")
	_arrow_at["param"] = load("res://art/screens/lineup/arrow_at_param.png")
	_arrow_at["rating"] = load("res://art/screens/lineup/arrow_at_rating.png")
	_arrow_off["param"] = load("res://art/screens/lineup/arrow_off_param.png")
	_arrow_off["rating"] = load("res://art/screens/lineup/arrow_off_rating.png")
	_up_limit = load("res://art/screens/lineup/scroll_up_limit.png")
	_thumb_strip = load("res://art/screens/lineup/scroll_thumb_strip.png")
	_track_strip = load("res://art/screens/lineup/scroll_track_strip.png")
	_arrow_up_off = load("res://art/icons/lineup/arrow_up_off.png")
	_campo_img = _img("res://art/screens/lineup/campo.png")
	for nm in ["dverde", "averde", "dblanco", "ablanco"]:
		_mk_img[nm] = _img("res://art/icons/lineup/%s.png" % nm)
	for tag in ["352_9", "352_5", "442_6"]:
		_zone_patch[tag] = _img("res://art/screens/lineup/zone_%s.png" % tag)
	_load_samples()
	_load_formations()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func _img(path: String) -> Image:
	var t: Texture2D = load(path)
	if t == null:
		return null
	var im := t.get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im


func _load_samples() -> void:
	var f := FileAccess.open("res://data/lineup_chrome_samples.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_zone_lut = (d as Dictionary).get("zone_lut", {})
		var zp: Dictionary = (d as Dictionary).get("zone_patches", {})
		for k in zp:
			_zone_rects[k] = zp[k]


func _load_formations() -> void:
	var f := FileAccess.open("res://data/formations.json", FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for rec in (d as Dictionary).get("formations", []):
			_forms[str(rec.get("name", ""))] = rec


## Feed the manager's club + chosen tactics (+ season/week + match header), repaint.
func setup(club: Dictionary, tactics: Tactics, manager: String = "", division: String = "",
		season: String = "1997-98", week: int = 0, header := {}) -> void:
	_club = club
	_tactics = tactics
	_division = division
	_season = season
	_week = week
	_header = header
	if _header.is_empty():
		var d := PMChrome.date_parts(season, week)
		_header = {"mode": "manager", "top": manager,
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1)), "weekday": str(d["wd"]),
			"day": str(d["day"]), "month": str(d["mon"]), "year": str(d["year"])}
	_by_id.clear()
	for p in club.get("players", []):
		_by_id[int(p.get("id", -1))] = p
	_scroll = 0
	_sel_pid = -1
	_entry_xi = (_tactics.xi.duplicate() if _tactics != null else [])
	_pitch_cache_key = ""
	queue_redraw()


# ---- scroll model + flat item list ----------------------------------------

## The non-XI squad as ONE ordered pid list — SUBSTITUTES are its first
## Tactics.BENCH_SLOTS entries, RESERVES the rest, exactly the partition the original's
## squad object stores (bench/reserve COUNTS at team+0x1930 / team+0x1934). `Tactics
## .subs_order` persists it once the line-up is edited, so a SUBSTITUTES<->RESERVES swap
## sticks. Until then it derives: a club dict that pins "bench"/"reserves" pid arrays
## (the parity fixture does) keeps its walked order, otherwise the rest sorts by ability
## — both the previous behaviour bit-for-bit. Anyone signed since (or dropped from) the
## stored order is appended in roster order, so a new signing always reaches the screen.
func _subs_order() -> Array:
	var xi: Array = _tactics.xi if _tactics != null else []
	var rest: Array = []
	for p in _club.get("players", []):
		var pid := int(p.get("id", -1))
		if pid >= 0 and not xi.has(pid):
			rest.append(p)
	var out: Array = []
	var seen := {}
	var stored: Array = _tactics.subs_order if _tactics != null else []
	if stored.is_empty() and _club.has("bench") and _club.has("reserves"):
		stored = (_club["bench"] as Array) + (_club["reserves"] as Array)
	if stored.is_empty():
		rest.sort_custom(func(a, b): return _av_of(a) > _av_of(b))
		return rest
	for pid in stored:
		var i := int(pid)
		if xi.has(i) or seen.has(i) or not _by_id.has(i):
			continue
		seen[i] = true
		out.append(_by_id[i])
	for p in rest:                     # new signings / players pushed out of the XI
		if not seen.has(int(p.get("id", -1))):
			out.append(p)
	return out


## [bench, reserves] as player dicts, split off _subs_order().
func _tiers() -> Array:
	var order := _subs_order()
	return [order.slice(0, Tactics.BENCH_SLOTS), order.slice(Tactics.BENCH_SLOTS, order.size())]


## The squad list flattened to draw-items in render order: XI rows, the
## SUBSTITUTES band + bench rows, the RESERVES band + reserve rows. Rows are
## 16px units; the bands are 23px/22px strips (frame-measured).
func _flat_items() -> Array:
	var items: Array = []
	var roles: Array = _tactics.roles() if _tactics != null else []
	var xi: Array = _tactics.xi if _tactics != null else []
	for i in xi.size():
		var rl: String = roles[i] if i < roles.size() else ""
		items.append({"t": "row", "pid": int(xi[i]), "slot": i, "role": rl, "h": ROW_PITCH})
	var tiers := _tiers()
	var bench: Array = tiers[0]
	var reserves: Array = tiers[1]
	items.append({"t": "band", "label": "sub", "h": BAND_SUB_H})
	for p in bench:
		items.append({"t": "row", "pid": int(p.get("id", -1)), "slot": -1,
			"tier": "sub", "h": ROW_PITCH})
	items.append({"t": "band", "label": "res", "h": BAND_RES_H})
	for p in reserves:
		items.append({"t": "row", "pid": int(p.get("id", -1)), "slot": -1,
			"tier": "res", "h": ROW_PITCH})
	return items


## Index of the first RESERVES row in _flat_items(): the XI rows, the SUBSTITUTES
## band, the bench rows and the RESERVES band all precede it and never scroll.
func _res_start() -> int:
	var n_xi: int = (_tactics.xi.size() if _tactics != null else 0)
	return n_xi + 1 + (_tiers()[0] as Array).size() + 1


## Items that fit between the first row top and the table bottom at a scroll. Only the
## RESERVES tail scrolls — witnessed on the real game 2026-07-24: six presses of the
## down arrow rolled the reserve list (a freshly signed player showed up at its foot)
## while the STARTING XI and SUBSTITUTES rows never moved. The app used to scroll the
## whole flat list, which pushed the XI off the top.
func _layout(scroll: int) -> Array:
	var items := _flat_items()
	var head := mini(_res_start(), items.size())
	var order: Array = []
	for i in head:
		order.append(i)
	for i in range(head + scroll, items.size()):
		order.append(i)
	var out: Array = []
	var y := XI_Y0 - 1
	for i in order:
		var h := int(items[i]["h"])
		if y + h > 465:
			break
		var it: Dictionary = items[i].duplicate()
		it["y"] = y
		it["i"] = i
		out.append(it)
		y += h
	return out


func _max_scroll() -> int:
	var items := _flat_items()
	var s := 0
	while s < items.size() and _layout(s).size() < items.size() - s:
		s += 1
	return s


func _clamp_scroll() -> void:
	_scroll = clampi(_scroll, 0, _max_scroll())


func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	if BTN_RETURN.has_point(d):
		return "return"
	if BTN_TACTICS.has_point(d):
		return "tactics"
	if TOGGLE_PARAM.has_point(d):
		return "param"
	if TOGGLE_RATING.has_point(d):
		return "rating"
	if _pending_change() and UNDO_BTN.has_point(d):
		return "undo"
	# T/I/S plate (default state — replaced by UNDO once a change is pending):
	# rows top->bottom = TRAINING / INJURIES / STATISTICS (lineup_screen_re.md).
	if not _pending_change():
		if TIS_BTNS[0].has_point(d):
			return "training"
		if TIS_BTNS[1].has_point(d):
			return "injuries"
		if TIS_BTNS[2].has_point(d):
			return "statistics"
	if _max_scroll() > 0:
		if SCROLL_UP.has_point(d):
			return "up"
		if SCROLL_DOWN.has_point(d):
			return "down"
	var fi := _row_at(d)
	if fi >= 0:
		# the [+] card box at the row's left opens the player's FICHA (frame 155); the rest
		# of the row keeps the select-then-swap XI edit.
		if d.x >= ROW_X and d.x < ROW_X + PLUS_W:
			return "plus:%d" % fi
		return "row:%d" % fi
	return ""


## The flat-list index of the player row under a design-space point, or -1.
func _row_at(d: Vector2) -> int:
	if d.x < ROW_X or d.x > ROW_X + ROW_W:
		return -1
	for it in _layout(_scroll):
		if it["t"] == "row" and d.y >= float(it["y"]) and d.y < float(it["y"]) + 16.0:
			return int(it["i"])
	return -1


func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		pos = (e as InputEventMouseButton).position
		pressed = (e as InputEventMouseButton).pressed
		tap = true
	elif e is InputEventScreenTouch:
		pos = (e as InputEventScreenTouch).position
		pressed = (e as InputEventScreenTouch).pressed
		tap = true
	if not tap:
		return
	if pressed:
		_press = _hit(_to_design(pos))
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		if a == was and a != "":
			match a:
				"return": back_pressed.emit()
				"tactics": tactics_pressed.emit()
				"training": training_pressed.emit()
				"injuries": injuries_pressed.emit()
				"statistics": statistics_pressed.emit()
				"param":
					_rating_view = false
					queue_redraw()
				"rating":
					_rating_view = true
					queue_redraw()
				"undo": _undo()
				"up", "down":
					_scroll += SCROLL_STEP if a == "down" else -SCROLL_STEP
					_clamp_scroll()
					queue_redraw()
				_:
					if a.begins_with("plus:"):
						_tap_plus(int(a.substr(5)))
					elif a.begins_with("row:"):
						_tap_row(int(a.substr(4)))


# ---- XI editing (select-then-swap) ---------------------------------------

## The [+] card box: open the tapped player's FICHA (PlayerInfoScreen) over the line-up.
func _tap_plus(i: int) -> void:
	var items := _flat_items()
	if i < 0 or i >= items.size() or items[i].get("t") != "row":
		return
	var p: Variant = _by_id.get(int(items[i]["pid"]))
	if p is Dictionary:
		player_info_pressed.emit(p)


func _tap_row(i: int) -> void:
	var items := _flat_items()
	if i < 0 or i >= items.size() or items[i].get("t") != "row":
		return
	var pid := int(items[i]["pid"])
	if _sel_pid < 0:
		_sel_pid = pid
	elif _sel_pid == pid:
		_sel_pid = -1
	else:
		_try_swap(_sel_pid, pid)
	_pitch_cache_key = ""
	queue_redraw()


func _try_swap(sel_pid: int, tgt_pid: int) -> void:
	if _tactics == null:
		return
	var xi: Array = _tactics.xi
	var sel_slot := xi.find(sel_pid)
	var tgt_slot := xi.find(tgt_pid)
	var slot := -1
	var mover := -1
	if tgt_slot >= 0:
		slot = tgt_slot
		mover = sel_pid
	elif sel_slot >= 0:
		slot = sel_slot
		mover = tgt_pid
	else:
		# NEITHER man is in the XI: a SUBSTITUTES <-> RESERVES exchange. The real game
		# does this (live-witnessed 2026-07-24: Fairclough selected in SUBSTITUTES,
		# Barlow tapped in RESERVES -> Barlow took the bench slot and Fairclough took
		# Barlow's reserve place). Before this the app just moved the selection, so a
		# substitute could never be swapped with a reserve.
		_swap_bench(sel_pid, tgt_pid)
		return
	if not _swap_legal(mover, slot):
		return
	_tactics.assign(slot, mover)
	_sel_pid = -1
	xi_changed.emit()


## Exchange two non-XI players' PLACES in the single SUBSTITUTES+RESERVES order — the
## positional swap the original performs (a substitute tapped against a reserve takes
## his row and vice versa). Materialises the derived order on the first edit.
func _swap_bench(a_pid: int, b_pid: int) -> void:
	var order: Array = []
	for p in _subs_order():
		order.append(int(p.get("id", -1)))
	var ai := order.find(a_pid)
	var bi := order.find(b_pid)
	if ai < 0 or bi < 0:
		_sel_pid = b_pid
		queue_redraw()
		return
	order[ai] = b_pid
	order[bi] = a_pid
	_tactics.subs_order = order
	_sel_pid = -1
	xi_changed.emit()


func _swap_legal(mover: int, slot: int) -> bool:
	if _tactics == null or slot < 0 or slot >= _tactics.xi.size():
		return false
	var rs: Array = _tactics.roles()
	if _is_keeper(mover) != (rs[slot] == "GK"):
		return false
	var mover_slot := _tactics.xi.find(mover)
	if mover_slot >= 0:
		var displaced := int(_tactics.xi[slot])
		if _is_keeper(displaced) != (rs[mover_slot] == "GK"):
			return false
	return true


func _is_keeper(pid: int) -> bool:
	var p: Variant = _by_id.get(pid)
	return p is Dictionary and bool((p as Dictionary).get("isGK", false))


## Whether the line-up carries a pending change: an XI edit since entry, or an
## injured player still in the XI (both walked UNDO states — 160 and 155).
func _pending_change() -> bool:
	if _tactics == null:
		return false
	if _tactics.xi != _entry_xi:
		return true
	for pid in _tactics.xi:
		var p: Variant = _by_id.get(int(pid))
		if p is Dictionary and _injury_weeks(p as Dictionary) > 0:
			return true
	return false


func _undo() -> void:
	if _tactics == null or _entry_xi.is_empty():
		return
	_tactics.xi = _entry_xi.duplicate()
	_sel_pid = -1
	_pitch_cache_key = ""
	xi_changed.emit()
	queue_redraw()


# ---- helpers ---------------------------------------------------------------

## Displayed AV: frame-true "av" override wins (parity shots pin the frame's
## dynamic FI/MO); else the real rating (Morale.av6 = FUN_00581e60 — the table
## paint FUN_004f5260 draws this exact cell from it, morale_re.md) when the
## squad carries form, else the attrs-mean approximation.
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


func _role_short(p: Dictionary) -> String:
	var pf := int(p.get("posFine", 0))
	if pf >= 1 and pf <= FINE_ROLE_SHORT.size():
		return FINE_ROLE_SHORT[pf - 1]
	return str(POS_WORD.get(str(p.get("pos", "")), "OUT"))


func _pos_word(p: Dictionary) -> String:
	if bool(p.get("isGK", false)):
		return "GOAL"
	return str(POS_WORD.get(str(p.get("pos", "")), "OUT"))


func _shirt(p: Dictionary, slot: int) -> int:
	var no := int(p.get("squadNo", 0))
	return no if no > 0 else slot + 1


## Row tint band of an XI slot (FUN_004fe2d0, same rule as the TACTICS board).
func _band_of_slot(slot_idx: int) -> String:
	var form: String = _tactics.formation if _tactics != null else "4-4-2"
	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary):
		return "mid"
	var slots: Array = (rec as Dictionary).get("slots", [])
	if slot_idx < 0 or slot_idx >= slots.size():
		return "mid"
	var s: Dictionary = slots[slot_idx]
	var mk1: Array = s.get("mk1", [0, 0])
	var mk2: Array = s.get("mk2", [0, 0])
	if int(mk1[0]) < 52:
		return "def"
	if int(mk2[0]) >= 211:
		return "fwd"
	return "mid"


## GDI cell centring: px = x0 + (cw - advance) div 2 (floor).
func _cell_centre(f: Font, s: String, x0: int, cw: int, sz := 11) -> float:
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	return float(x0 + int(floorf((cw - w) / 2.0)))


## GDI fake-BOLD (the frame double-strikes at x and x+1): the role text, AV,
## injured-row cells, numeric-view values and every right-panel value/name.
func _btxt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, align := 0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if align == 2:
		px = x - (w + 1.0)
	var yb := y_top + f.get_ascent(sz)
	draw_string(f, Vector2(px, yb), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_string(f, Vector2(px + 1.0, yb), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _bcell_centre(f: Font, s: String, x0: int, cw: int, sz := 11) -> float:
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x) + 1
	return float(x0 + int(floorf((cw - w) / 2.0)))


func _injury_weeks(p: Dictionary) -> int:
	return int(p.get("injured_weeks", 0))


## Matches still to sit out banned (Availability.gd's `suspended_weeks`).
func _ban_matches(p: Dictionary) -> int:
	return int(p.get("suspended_weeks", 0))


# ---- drawing ---------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "lineup", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))

	_draw_items()
	_draw_scrollbar()
	_draw_right_panel()


func _draw_items() -> void:
	_clamp_scroll()
	for it in _layout(_scroll):
		var y := int(it["y"])   # unit top = the row's top sep line
		if it["t"] == "band":
			var tex: Texture2D = _bands.get(str(it["label"]))
			if tex != null:
				draw_texture(tex, Vector2(ROW_X, y))
		else:
			_draw_row(y, it)


func _draw_row(y: int, it: Dictionary) -> void:
	var p: Variant = _by_id.get(int(it["pid"]))
	if p == null:
		return
	var pl: Dictionary = p
	var slot := int(it["slot"])
	var tier: String = str(it.get("tier", "xi"))
	var injured := _injury_weeks(pl) > 0
	var banned := not injured and _ban_matches(pl) > 0
	# The original draws an injury and a suspension on the SAME gold plate and the same
	# three cells; only the icon (red cross / two yellow cards) and the unit word
	# (WEEKS / MATCHES) differ — docs/re/lineup_screen_re.md, witnessed on the reference
	# season's `2 Gary Neville ... 2 MATCHES` row.
	var unavailable := injured or banned
	var cls: String
	if tier == "xi":
		cls = ("inj" if injured else "ban") if unavailable else ("gk" if slot == 0 else _band_of_slot(slot - 1))
	else:
		cls = ("inj" if injured else "ban") if unavailable else tier
	if _rows.get(cls) != null:
		draw_texture(_rows[cls], Vector2(ROW_X, y))
	var tint := _tint_of(cls)

	# number + name (ProMan8; navy / black)
	var num := str(_shirt(pl, slot if slot >= 0 else 11))
	PMChrome.text(self, _f8, _cell_centre(_f8, num, NUM_CELL[0], NUM_CELL[1]), y + 2, num, C_NUM, 11)
	PMChrome.text(self, _f8, NAME_X, y + 2,
		PMChrome.title_case_name(str(pl.get("name", "?"))), C_NAME, 11, 0, 103.0)

	var av := _av_of(pl)
	if unavailable:
		_draw_unavailable_cells(y, pl, injured)
	elif _rating_view:
		# STARJUGON strip: halves=(AV+1) div 10; odd half = the DIMMED star.
		var halves := (av + 1) / 10
		for j in halves / 2:
			draw_texture(_star_on, Vector2(STAR_X0 + STAR_PITCH * j, y + 2))
		if halves % 2 == 1 and _star_off != null:
			draw_texture(_star_off, Vector2(STAR_X0 + STAR_PITCH * (halves / 2), y + 2))
		# fine-role SHORT name, right-aligned to the x349 sep (ProMan8 grey-blue)
		PMChrome.text(self, _f8, ROLE_RIGHT, y + 2, _role_short(pl), C_ROLE, 11, 2)
	else:
		# PARAMETERS view (witness 128): sep cols + per-column values
		var sep: Color = SEP_INK.get(tier, SEP_INK["xi"])
		for sx in NUM_SEPS:
			draw_rect(Rect2(sx, y + 1, 1, 12), sep, true)
		var has_form := pl.has("morale") or pl.has("fitness")
		for ci in NUM_KEYS.size():
			var key: String = NUM_KEYS[ci]
			var sv := ""
			match key:
				"EN":
					# The EN column is the +0xa8 dynamic byte (fn_004f5260 draws
					# it here), NOT the stored EN attr — frame 128 shows 99 on
					# all 20 rows while stored EN varies. Init 99 (FUN_005825c0);
					# career semantics un-RE'd.
					sv = str(int(pl.get("en_cap", 99)))
				"_fit":
					sv = str(clampi(int(pl.get("fitness", 99)), 0, 99)) if has_form else "-"
				"_mo":
					sv = str(Morale.display(pl)) if has_form else "-"
				_:
					var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
					var v: Variant = attrs.get(key)
					sv = str(int(v)) if v != null else "-"
			PMChrome.text(self, _f8, _cell_centre(_f8, sv, NUM_CELLS[ci][0], NUM_CELLS[ci][1]),
				y + 2, sv, NUM_INKS[ci], 11)

	PMChrome.text(self, _f8, _cell_centre(_f8, str(av), AV_CELL[0], AV_CELL[1]), y + 2,
		str(av), C_AV, 11)
	PMChrome.draw_role_icon(self, Rect2(CAMROL_X, y, 25, 14),
		int(pl.get("posFine", 0)), str(pl.get("pos", "")))
	var pos_s := _pos_word(pl)
	PMChrome.text(self, _f8, _cell_centre(_f8, pos_s, POS_CELL[0], POS_CELL[1]), y + 2,
		pos_s, C_POS, 11)

	# the SELECTED row's 2px black frame (155 Solskjaer witness)
	if int(it["pid"]) == _sel_pid:
		draw_rect(Rect2(28, y - 1, 411, 2), Color.BLACK, true)
		draw_rect(Rect2(28, y + 13, 411, 2), Color.BLACK, true)
		draw_rect(Rect2(28, y - 1, 2, 16), Color.BLACK, true)
		draw_rect(Rect2(437, y - 1, 2, 16), Color.BLACK, true)


func _tint_of(cls: String) -> Color:
	match cls:
		"gk": return Color8(255, 255, 170)
		"def": return Color8(220, 250, 210)
		"mid": return Color8(204, 204, 255)
		"fwd": return Color8(255, 191, 170)
		"inj", "ban": return Color8(212, 191, 85)
		"sub": return Color8(212, 223, 255)
	return Color8(180, 200, 220)


## The unavailable row's dynamic digits. The icon + boxes are template furniture
## (row_inj / row_ban); the count and the unit label are drawn here — WEEKS for an
## injury, MATCHES for a suspension, singular when the count is 1.
func _draw_unavailable_cells(y: int, pl: Dictionary, injured: bool) -> void:
	var wks := _injury_weeks(pl) if injured else _ban_matches(pl)
	PMChrome.text(self, _f8, _cell_centre(_f8, str(wks), INJ_COUNT[0], INJ_COUNT[1]), y + 2,
		str(wks), C_INJ_COUNT, 11)
	var label := ("WEEKS" if wks != 1 else "WEEK") if injured else ("MATCHES" if wks != 1 else "MATCH")
	PMChrome.text(self, _f8, _cell_centre(_f8, label, INJ_WEEKS[0], INJ_WEEKS[1]), y + 2,
		label, C_INJ_LABEL, 11)
	var fi := str(clampi(int(pl.get("fitness", 99)), 0, 99))
	PMChrome.text(self, _f8, _cell_centre(_f8, fi, INJ_FI[0], INJ_FI[1]), y + 2, fi, C_FI, 11)
	var mo := str(Morale.display(pl))
	PMChrome.text(self, _f8, _cell_centre(_f8, mo, INJ_MO[0], INJ_MO[1]), y + 2, mo, C_MO, 11)
	# the injured row's 1px black frame is baked in the row_inj template


## The scrollbar is baked at scroll 0. When scrolled, restore the strip and
## redraw thumb + up arrow (reconstruction — every walked frame is at scroll 0).
func _draw_scrollbar() -> void:
	if _scroll <= 0:
		return
	if _track_strip != null:
		for ty in range(THUMB_STRIP_XY.y, 434, 11):
			draw_texture_rect(_track_strip, Rect2(THUMB_STRIP_XY.x, ty, 23,
				mini(11, 433 - ty)), false)
	if _arrow_up_off != null:
		draw_texture(_arrow_up_off, SCROLL_UP.position)
	var ms := _max_scroll()
	var t := float(_scroll) / float(ms) if ms > 0 else 0.0
	if _thumb_strip != null:
		draw_texture(_thumb_strip, Vector2(THUMB_STRIP_XY.x,
			THUMB_STRIP_XY.y + int(t * (433 - 16 - THUMB_STRIP_XY.y))))


# ---- right panel ------------------------------------------------------------

## TEAM RATING = sum of the XI's AVs, SKIPPING injured/banned men
## (FUN_005836a0), over a FIXED /11 (FUN_004fe540: FUN_0057a3a0() / 0xb) —
## walked proof: frame 155 shows 77 = (936 - Beckham's 88) / 11, frame 015
## shows 87 = 959 / 11 (morale_re.md).
func _team_rating() -> int:
	if _club.has("team_rating"):
		return int(_club["team_rating"])
	var xi: Array = _tactics.xi if _tactics != null else []
	if xi.is_empty():
		return 0
	var sum := 0
	for pid in xi:
		var p: Variant = _by_id.get(int(pid))
		if p != null and Availability.is_available(p):
			sum += _av_of(p)
	return sum / 11


func _draw_right_panel() -> void:
	# toggle plates: chrome bakes RATING-active (155); flip via 128's plates
	if not _rating_view:
		if _plate_param_on != null:
			draw_texture(_plate_param_on, TOGGLE_PARAM.position)
		if _plate_rating_off != null:
			draw_texture(_plate_rating_off, TOGGLE_RATING.position)
		if _arrow_at["param"] != null:
			draw_texture(_arrow_at["param"], Vector2(ARROW_X, TOGGLE_PARAM.position.y))
		if _arrow_off["rating"] != null:
			draw_texture(_arrow_off["rating"], Vector2(ARROW_X, TOGGLE_RATING.position.y))

	# TEAM RATING strip: walked per-cell star patches + the value (ProMan8)
	var tr := _team_rating()
	var halves := (tr + 1) / 10
	for j in 5:
		var x := STRIP_STAR_X0 + STRIP_STAR_PITCH * j
		if j < halves / 2:
			var tex: Texture2D = _eq_full[mini(j, 3)]
			draw_texture(tex, Vector2(x, STRIP_STAR_Y))
		elif j == halves / 2 and halves % 2 == 1:
			draw_texture(_eq_half, Vector2(x, STRIP_STAR_Y))
	PMChrome.text(self, _f10, STRIP_VAL_RIGHT, STRIP_VAL_Y, str(tr), C_STRIP_VAL, 10, 2)

	# name band + attr values for the selected player
	var sel: Variant = _by_id.get(_sel_pid)
	if sel is Dictionary:
		var pl: Dictionary = sel
		var nm := PMChrome.title_case_name(str(pl.get("name", "")))
		PMChrome.text(self, _f10, _cell_centre(_f10, nm, int(NAME_BAND.position.x),
			int(NAME_BAND.size.x), 10), 158, nm, C_NAME_BAND, 10)
		var attrs: Dictionary = pl.get("attrs", {}) if pl.get("attrs") is Dictionary else {}
		for i in 6:
			var v := int(attrs.get(SKILL_KEYS[i], 0))
			var col: Array = ATTR_COLS[i % 2]
			var by: int = ATTR_ROWS_Y[i / 2]
			var h2 := (v + 1) / 10
			if h2 == int(ATTR_SIG[i]) and i < _attr_strips.size() and _attr_strips[i] != null:
				# the walked strip verbatim (glyphs + the noise-dither shadow)
				draw_texture(_attr_strips[i], Vector2(ATTR_XY[i][0], ATTR_XY[i][1]))
			else:
				# un-walked count: plain glyphs (shadow approximation documented)
				for j in h2 / 2:
					draw_texture(_paron_on, Vector2(col[0] + 10 * j, by + ATTR_STAR_DY))
				if h2 % 2 == 1 and _paron_off != null:
					draw_texture(_paron_off, Vector2(col[0] + 10 * (h2 / 2), by + ATTR_STAR_DY))
			PMChrome.text(self, _f8, _cell_centre(_f8, str(v), col[0] + 47, 31),
				by + ATTR_VAL_DY, str(v), C_ATTR_VAL, 11)

	_draw_pitch()

	# UNDO is baked in chrome; the default state overlays the T/I/S plate
	if not _pending_change() and _plate_tis != null:
		draw_texture(_plate_tis, Vector2(TIS_XY.x, TIS_XY.y))


## CAMPO composite: greens per formation slot, the selected slot's coverage
## zone (walked patch or majority-LUT dim), the selected slot's whites on top.
func _draw_pitch() -> void:
	var form: String = _tactics.formation if _tactics != null else "4-4-2"
	var sel_slot := _sel_slot()
	var key := "%s:%d" % [form, sel_slot]
	if key != _pitch_cache_key or _pitch_tex == null:
		_pitch_tex = _compose_pitch(form, sel_slot)
		_pitch_cache_key = key
	if _pitch_tex != null:
		draw_texture(_pitch_tex, Vector2(CAMPO_XY))


## The selected player's XI slot in FORMATION space (gk row -> gk_slot), or -1.
func _sel_slot() -> int:
	if _sel_pid < 0 or _tactics == null:
		return -1
	var i := _tactics.xi.find(_sel_pid)
	if i < 0:
		return -1
	var rec: Variant = _forms.get(_tactics.formation)
	var gk := int((rec as Dictionary).get("gk_slot", 10)) if rec is Dictionary else 10
	return gk if i == 0 else i - 1


func _mkmap(x: int, y: int) -> Vector2i:
	return Vector2i(4 + x * 148 / 318, 3 + y * 88 / 198)


func _compose_pitch(form: String, sel_slot: int) -> Texture2D:
	if _campo_img == null:
		return null
	var img := _campo_img.duplicate() as Image
	var rec: Variant = _forms.get(form)
	if not (rec is Dictionary):
		return ImageTexture.create_from_image(img)
	var slots: Array = (rec as Dictionary).get("slots", [])
	# arrows first, discs on top (the engine order)
	for si in slots.size():
		if si == sel_slot:
			continue
		var raw: Array = (slots[si] as Dictionary).get("raw", [])
		if raw.size() < 8:
			continue
		var m1 := _mkmap(int(raw[4]), int(raw[5]))
		var m2 := _mkmap(int(raw[6]), int(raw[7]))
		if m2 != m1:
			_blit(img, _mk_img["averde"], m2)
	for si in slots.size():
		if si == sel_slot:
			continue
		var raw: Array = (slots[si] as Dictionary).get("raw", [])
		if raw.size() < 8:
			continue
		_blit(img, _mk_img["dverde"], _mkmap(int(raw[4]), int(raw[5])))
	if sel_slot >= 0 and sel_slot < slots.size():
		var raw: Array = (slots[sel_slot] as Dictionary).get("raw", [])
		if raw.size() >= 8:
			_apply_zone(img, form, sel_slot, raw)
			var m2 := _mkmap(int(raw[6]), int(raw[7]))
			var m1 := _mkmap(int(raw[4]), int(raw[5]))
			if m2 != m1:
				_blit(img, _mk_img["ablanco"], m2)
			_blit(img, _mk_img["dblanco"], m1)
	return ImageTexture.create_from_image(img)


func _blit(dst: Image, src: Image, at: Vector2i) -> void:
	if src == null:
		return
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), at)


## The coverage-zone overlay: a walked frame patch when this (formation,slot)
## was walked (155/156/131), else the majority dim LUT (the true dim is a
## positional noise dither — documented approximation for un-walked zones).
func _apply_zone(img: Image, form: String, sel_slot: int, raw: Array) -> void:
	var tag := ""
	if form == "3-5-2" and sel_slot == 9:
		tag = "352_9"
	elif form == "3-5-2" and sel_slot == 5:
		tag = "352_5"
	elif form == "4-4-2" and sel_slot == 6:
		tag = "442_6"
	if tag != "" and _zone_patch.get(tag) != null and _zone_rects.has(tag):
		var r: Array = _zone_rects[tag]
		var patch: Image = _zone_patch[tag]
		img.blit_rect(patch, Rect2i(0, 0, patch.get_width(), patch.get_height()),
			Vector2i(int(r[0]), int(r[1])))
		return
	var p0 := _mkmap(int(raw[0]), int(raw[1]))
	var p1 := _mkmap(int(raw[0]) + int(raw[2]), int(raw[1]) + int(raw[3]))
	for yy in range(p0.y, mini(p1.y, img.get_height())):
		for xx in range(p0.x, mini(p1.x, img.get_width())):
			var c := img.get_pixel(xx, yy)
			var k := "%d,%d,%d" % [int(c.r * 255.0 + 0.5), int(c.g * 255.0 + 0.5), int(c.b * 255.0 + 0.5)]
			if _zone_lut.has(k):
				var v: Array = _zone_lut[k]
				img.set_pixel(xx, yy, Color8(int(v[0]), int(v[1]), int(v[2])))
