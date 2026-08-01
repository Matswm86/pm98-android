extends Control
class_name ResultsScreen
## PM98 RESULTS screen (MENUPRINCIPAL "results" / MARCA) — the matches-on-date view
## with the competition rail. Static chrome = the REAL game's fresh frame
## (walkthrough 038_154452, the only RESULTS capture; 039-043 differ solely in the
## RETURN/Intercont hover animations): barra with the baked RESULTS title, PREMIER
## LEAGUE band + trophy, MATCHES ON band, 9 empty fixture-row plates, the date inset
## (cleared), the competition rail (F.A. Cup ... 3rd Play-Offs in their frame states)
## and the division chips + RETURN. See docs/re/results_screen_re.md and
## tools/re/build_results_chrome_from_frames.py.
##
## Dynamic layer redraws only deltas, all frame-derived:
##   header       band.png cuts + PMChrome HDR grammar (manager plates, calendar,
##                status) — same recomposition the header bake proved 0px
##   rows         RIDIESC kits + PROMAN10 names (pixel-exact vs frame: right edge
##                x=207 home / pen x=288 away, glyph top row_top+6, inks
##                (100,120,140) light / (120,140,160) washed rows)
##   date         PROMAN14 glyph cells cut from the frame date "9/8/1997"
##                ('023456' = fitted-fill synthesis, parity-phased)
##   title        only when the career league isn't the baked PREMIER LEAGUE:
##                white patch + PROMAN18 fitted-fill caps (documented approximation)
##   arrows       the two captured plate states + their mirrors for the un-walked
##                enabled-left / disabled-right states
##
## HONEST GAPS (see the RE doc): score digits (no frame shows a played result on
## this screen) render as PROMAN10 in the row ink; the rail/chips keep their baked
## frame-038 states and are not wired (career-driven states were never captured);
## AI fixtures have no persisted scores in Career, so their cells stay empty.
##
## Data: fixtures = Career.fixtures (Array[round]; round = Array[[home_id,away_id]]),
## results = Career.results (manager-only [{week,opp_id,home,hg,ag}]). Rounds with
## more than 9 fixtures split into date pages (round date + page days), mirroring the
## original's own within-matchday date split (matchday 1 = 9 games on 9/8/1997 with
## Man Utd's game on the next date — frame truth for the 9-row table).

signal back_pressed
## A competition rail chip was tapped -- the original's own door into the cup / Europe
## views (every knockout/Europe frame in the RE corpus was captured by clicking this
## rail). The caller routes it; chips for competitions the career is not in are simply
## ignored there, as the original's dimmed chips are.
signal competition_selected(key: String)

const W := 640
const H := 480

# The competition rail's chip hit rects -- x506..621, 29 px tall, the same measured
# geometry KnockoutScreen uses (docs/re/knockout_views_re.md). The play-off chips below
# them stay inert: the port has no play-off view (honest gap, results_screen_re.md).
const CHIP_X := 506
const CHIP_W := 116
const CHIP_H := 29
const CHIP_TOP := {"facup": 118, "cocacola": 145, "charity": 172, "euro": 209,
	"cwc": 236, "uefa": 263, "supercup": 290, "intercont": 317}

# The four DIVISION chips along the bottom edge. Measured off frame 038 by scanning for
# the plaques' solid-black border columns: they sit at x 14/134/254/374, each 112 wide,
# y 435..459. Tier order is the frame's own left-to-right reading (Premier League, First,
# Second, Third Division). The RE doc called these "chrome-only, not interactive" — that
# was true of the port, not of the original, whose RESULTS view switches division on them
# (Mats QA 2026-08-01: "Can't switch between different competitions").
const DIV_CHIPS := [[1, 14], [2, 134], [3, 254], [4, 374]]
const DIV_CHIP_Y := 435
const DIV_CHIP_W := 112
const DIV_CHIP_H := 25

# ---- frame-measured geometry (docs/re/results_screen_re.md) -----------------
const ROW_Y0 := 154
const ROW_PITCH := 23
const N_ROWS := 9
const NAME_HOME_RIGHT := 207.0     # PROMAN10 pen END of the right-aligned home name
const NAME_AWAY_LEFT := 288.0      # PROMAN10 pen of the left-aligned away name
const NAME_TOP_DY := 6             # glyph line-box top within the row
const KIT_HOME_X := 21
const KIT_AWAY_X := 461
const SCORE_H_CX := 230.0          # score cell centres (cells x214..246 / x249..281)
const SCORE_A_CX := 265.0
const R_PREV := Rect2(308, 127, 27, 25)
const R_NEXT := Rect2(459, 127, 27, 25)
const R_RETURN := Rect2(504, 433, 116, 29)
const TITLE_BAKED := "PREMIER LEAGUE"

# frame-sampled row inks (light / washed rows alternate)
const C_INK := [Color8(100, 120, 140), Color8(120, 140, 160)]
const C_PRESS := Color(1, 1, 1, 0.2)

# header grammar (the shared barra bake, PMChrome HDR_* consts; patches cut from
# band.png by the build script and drawn at their source positions)
const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 13), "hdr_status": Vector2(536, 10)}

var _chrome: Texture2D
var _patches: Dictionary = {}
var _title_patch: Texture2D
var _title_caps: Texture2D
var _date_digits: Texture2D
var _arrow: Dictionary = {}        # left_on / left_off / right_on / right_off
var _spec: Dictionary = {}
var _f8: Font
var _f10: Font
var _fcal: Font

var _header: Dictionary = {}
var _league_name := ""
var _season := "1997-98"
var _fixtures: Array = []
var _results: Array = []
var _week := 0
var _club_id := -1
var _club_names: Dictionary = {}
var _scores: Dictionary = {}       # 1-based round -> Array of [home_id, away_id, hg, ag]
var _pages: Array = []             # [{round:int, day_off:int, pairs:Array}]
var _idx := 0
var _press := ""
var _tier := 1                     # the division currently shown by the four bottom chips
var _home_tier := 1                # the manager's own division (the chip the chrome bakes lit)
var _divisions: Dictionary = {}    # tier -> {name, fixtures, scores, names}


func _ready() -> void:
	_chrome = load("res://art/screens/results/chrome.png")
	for k in HDR_PATCH_XY:
		_patches[k] = load("res://art/screens/results/%s.png" % k)
	_title_patch = load("res://art/screens/results/title_patch.png")
	_title_caps = load("res://art/screens/results/title_caps.png")
	_date_digits = load("res://art/screens/results/date_digits.png")
	for k in ["left_on", "left_off", "right_on", "right_off"]:
		_arrow[k] = load("res://art/screens/results/arrow_%s.png" % k)
	var f := FileAccess.open("res://data/results_chrome_samples.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spec = parsed
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_fcal = PMChrome.font("calend12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `header` uses the draw_match_header keys (manager mode): top, bottom, club_id,
## weekday/day/month/year, status_top, status_bottom. `fixtures`/`results`/`week`
## come straight off Career; `club_names` maps club_id -> display name.
func setup(header: Dictionary, league_name: String, season: String, fixtures: Array,
		results: Array, week: int, club_id: int, club_names: Dictionary,
		scores: Dictionary = {}, divisions: Dictionary = {}, tier := 1) -> void:
	_header = header
	_league_name = league_name
	_season = season
	_fixtures = fixtures
	_results = results
	_week = week
	_club_id = club_id
	_club_names = club_names
	_scores = scores
	# `divisions` = tier -> {name, fixtures, scores, names}: every division the career is
	# simulating, so the bottom chips can switch between them. The manager's own tier is
	# included by the caller. Empty = the pre-2026-08-01 single-division behaviour.
	_divisions = divisions
	_tier = tier
	_home_tier = tier
	_build_pages()
	queue_redraw()


## Repaint the table for another division. Keeps the page index on the same ROUND when
## that round exists in the new division's schedule (the lower divisions run more rounds).
func _show_tier(t: int) -> void:
	if t == _tier or not _divisions.has(t):
		return
	var want := int((_pages[_idx] as Dictionary).get("round", 0)) if _idx < _pages.size() else 0
	var dv: Dictionary = _divisions[t]
	_tier = t
	_league_name = str(dv.get("name", ""))
	_fixtures = dv.get("fixtures", [])
	_scores = dv.get("scores", {})
	_club_names = dv.get("names", {})
	_build_pages()
	for i in _pages.size():
		if int((_pages[i] as Dictionary)["round"]) == want:
			_idx = i
			break
	queue_redraw()


## Split every round into pages of <=9 rows (the table has exactly 9 plates — frame
## truth). Page p of a round renders on the round date + p days, as the original
## splits a matchday across consecutive dates.
func _build_pages() -> void:
	_pages = []
	for r in _fixtures.size():
		var round_pairs: Array = _fixtures[r]
		var p := 0
		while p * N_ROWS < round_pairs.size():
			_pages.append({"round": r, "day_off": p,
				"pairs": round_pairs.slice(p * N_ROWS, (p + 1) * N_ROWS)})
			p += 1
	# default view: the first page of the NEXT round (fresh career -> round 1,
	# matching frame 038); a finished season clamps to the last round.
	_idx = 0
	var want: int = mini(_week, maxi(_fixtures.size() - 1, 0))
	for i in _pages.size():
		if int(_pages[i]["round"]) == want:
			_idx = i
			break


## The persisted score for one fixture of round r (round keys are 1-based).
## Returns [] for a round that has not been played yet — an empty pair of cells,
## which is what the original shows for a future matchday.
##
## Until 2026-08-01 this answered ONLY for the manager's own fixture, because
## `Career.results` is a manager-only ledger — so eight of the nine plates on every
## page were blank forever (Mats QA: "the result screen doesn't really work").
## `Career.round_scores` / `divisions[t].scores` now carry every fixture in the
## division, and `_results` survives as the fallback for saves written before that.
func _score_for(r: int, home_id: int, away_id: int) -> Array:
	var row: Variant = _scores.get(r + 1, _scores.get(str(r + 1), []))
	if row is Array:
		for e in (row as Array):
			var ent: Array = e
			if ent.size() >= 4 and int(ent[0]) == home_id and int(ent[1]) == away_id:
				return [int(ent[2]), int(ent[3])]
	if home_id != _club_id and away_id != _club_id:
		return []
	for e2 in _results:
		if int(e2.get("week", -1)) == r + 1:
			return [int(e2.get("hg", 0)), int(e2.get("ag", 0))]
	return []


## d/m/yyyy for round r page day_off: season start (9 Aug of the season's first
## year, PMChrome.date_parts grammar) + r weeks + day_off days.
func _date_for(r: int, day_off: int) -> Dictionary:
	var start_year := 1997
	if _season.length() >= 4 and _season.substr(0, 4).is_valid_int():
		start_year = int(_season.substr(0, 4))
	var t0 := Time.get_unix_time_from_datetime_dict(
		{"year": start_year, "month": 8, "day": 9, "hour": 12, "minute": 0, "second": 0})
	var d := Time.get_datetime_dict_from_unix_time(int(t0) + (r * 7 + day_off) * 86400)
	return {"day": int(d["day"]), "month": int(d["month"]), "year": int(d["year"])}


# ---- geometry ----------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d):
		return "return"
	if R_PREV.has_point(d) and _idx > 0:
		return "prev"
	if R_NEXT.has_point(d) and _idx < _pages.size() - 1:
		return "next"
	for c in CHIP_TOP:
		if Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H).has_point(d):
			return "comp:%s" % c
	for dc in DIV_CHIPS:
		if _divisions.has(int(dc[0])) \
				and Rect2(int(dc[1]), DIV_CHIP_Y, DIV_CHIP_W, DIV_CHIP_H).has_point(d):
			return "div:%d" % int(dc[0])
	return ""


# ---- input ---------------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _target_at(d):
		return
	if was.begins_with("comp:"):
		competition_selected.emit(was.substr(5))
		return
	if was.begins_with("div:"):
		_show_tier(int(was.substr(4)))
		return
	match was:
		"return":
			back_pressed.emit()
		"prev":
			_idx = maxi(_idx - 1, 0)
			queue_redraw()
		"next":
			_idx = mini(_idx + 1, _pages.size() - 1)
			queue_redraw()


# ---- drawing ---------------------------------------------------------------------

## GDI-centred single-line text: px = (S - extent) div 2 (the header-bake rule).
func _gdi_text(f: Font, sz: int, s: String, span: int, y_top: int, ink: Color) -> void:
	if f == null or s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (span - w) / 2
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)
	_draw_header()
	_draw_title()
	var page: Dictionary = _pages[_idx] if _idx < _pages.size() else {}
	if not page.is_empty():
		_draw_rows(page)
		_draw_date(page)
	_draw_arrows()
	for key_r in [["prev", R_PREV], ["next", R_NEXT], ["return", R_RETURN]]:
		if _press == str(key_r[0]):
			draw_rect(key_r[1], C_PRESS, true)
	if _press.begins_with("comp:"):
		var c := _press.substr(5)
		if CHIP_TOP.has(c):
			draw_rect(Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H), C_PRESS, true)
	_draw_div_chips()


## The bottom rail's four DIVISION chips. The chrome bake has the manager's own division
## permanently lit (frame 038 was captured in the Premier), and no frame was ever captured
## with another chip selected, so the SELECTED state for the other three is a port-side
## indicator, not a witness: a 1px white ring around the active chip. Declared, not
## invented as chrome — the underlying plaques are still the frame's own pixels.
func _draw_div_chips() -> void:
	if _divisions.size() <= 1:
		return
	for dc in DIV_CHIPS:
		var t := int(dc[0])
		if not _divisions.has(t):
			continue
		var r := Rect2(int(dc[1]), DIV_CHIP_Y, DIV_CHIP_W, DIV_CHIP_H)
		if _press == "div:%d" % t:
			draw_rect(r, C_PRESS, true)
		elif t == _tier and t != _home_tier:
			draw_rect(r, Color(1, 1, 1), false, 1.0)


## The barra values: textless band.png patches + the header bake's text grammar
## (PMChrome HDR consts). The baked RESULTS title sprite is outside every patch,
## so it stays original pixels.
func _draw_header() -> void:
	for k in HDR_PATCH_XY:
		if _patches[k] != null:
			draw_texture(_patches[k], HDR_PATCH_XY[k])
	_gdi_text(_f8, 11, str(_header.get("top", "")), PMChrome.HDR_NAME_TOP["S"],
		PMChrome.HDR_NAME_TOP["y"], Color(0, 0, 0))
	_gdi_text(_f8, 11, str(_header.get("bottom", "")), PMChrome.HDR_NAME_BOT["S"],
		PMChrome.HDR_NAME_BOT["y"], Color(1, 1, 1))
	var cid := int(_header.get("club_id", _club_id))
	PMChrome.draw_manager_panel(self, cid)
	for line in PMChrome.HDR_CAL_LINES:
		_gdi_text(_f8, 11, str(_header.get(line["key"], "")), PMChrome.HDR_CAL_S,
			line["y"], line["ink"])
	_gdi_text(_fcal, 15, str(_header.get("status_top", "Preseason")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_TOP_Y, Color(0, 0, 0))
	_gdi_text(_fcal, 15, str(_header.get("status_bottom", "Preparation")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_BOT_Y, Color(1, 1, 1))


## Competition band: baked PREMIER LEAGUE stays; any other league repaints the
## white patch and stamps the fitted-fill PROMAN18 caps (GDI span S=511 — the
## single-witness centring that reproduces the frame's x=143).
func _draw_title() -> void:
	var name := _league_name.to_upper()
	if name == TITLE_BAKED or name == "" or _title_patch == null or _spec.is_empty():
		return
	var t: Dictionary = _spec.get("title", {})
	var cells: Dictionary = t.get("cells", {})
	var patch_xy: Array = t.get("patch_xy", [104, 86])
	draw_texture(_title_patch, Vector2(patch_xy[0], patch_xy[1]))
	var adv := 0
	for c in name:
		adv += int((cells.get(c, cells.get(" ", {"adv": 6})) as Dictionary).get("adv", 6))
	@warning_ignore("integer_division")
	var pen := (int(t.get("S", 511)) - adv) / 2
	var y := float(t.get("y", 86))
	var h := float(t.get("h", 23))
	for c in name:
		var cell: Dictionary = cells.get(c, {})
		if cell.is_empty():
			pen += 6
			continue
		draw_texture_rect_region(_title_caps, Rect2(pen, y, cell["w"], h),
			Rect2(cell["x"], 0, cell["w"], h))
		pen += int(cell["adv"])


func _draw_rows(page: Dictionary) -> void:
	var pairs: Array = page["pairs"]
	var r := int(page["round"])
	for i in mini(pairs.size(), N_ROWS):
		var y := ROW_Y0 + ROW_PITCH * i
		var ink: Color = C_INK[i % 2]
		var h_id := int(pairs[i][0])
		var a_id := int(pairs[i][1])
		for pair in [[h_id, KIT_HOME_X], [a_id, KIT_AWAY_X]]:
			var kt := PMChrome.ridi_kit(int(pair[0]))
			if kt != null:
				draw_texture(kt, Vector2(pair[1], y + 1))
		var hn := str(_club_names.get(h_id, _club_names.get(str(h_id), "")))
		var an := str(_club_names.get(a_id, _club_names.get(str(a_id), "")))
		_row_text(hn, NAME_HOME_RIGHT, y, ink, true)
		_row_text(an, NAME_AWAY_LEFT, y, ink, false)
		var sc := _score_for(r, h_id, a_id)
		if sc.size() == 2:
			# APPROXIMATION (results_screen_re.md): no walkthrough frame shows a
			# played score on this screen — PROMAN10 centred in the frame's cells.
			_row_text(str(sc[0]), SCORE_H_CX, y, ink, false, true)
			_row_text(str(sc[1]), SCORE_A_CX, y, ink, false, true)


func _row_text(txt: String, x: float, row_y: float, ink: Color, right: bool,
		center := false) -> void:
	if _f10 == null or txt == "":
		return
	var w := _f10.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var px := x
	if right:
		px = x - w
	elif center:
		px = x - w * 0.5
	draw_string(_f10, Vector2(px, row_y + NAME_TOP_DY + _f10.get_ascent(10)), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)


## The MATCHES ON date, d/m/yyyy, centred on the inset (cx=396 reproduces the
## witness pen 352 for "9/8/1997"). Cells are parity-picked: the checkered fill is
## phase-locked to screen x parity (build script).
func _draw_date(page: Dictionary) -> void:
	if _date_digits == null or _spec.is_empty():
		return
	var dd := _date_for(int(page["round"]), int(page["day_off"]))
	var txt := "%d/%d/%d" % [dd["day"], dd["month"], dd["year"]]
	var spec_d: Dictionary = _spec["date"]
	var cells: Dictionary = spec_d["cells"]
	var adv := 0
	for c in txt:
		adv += int((cells[c] as Dictionary)["adv"])
	@warning_ignore("integer_division")
	var pen: int = int(spec_d.get("cx", 396)) - adv / 2
	var y := float(spec_d["y"])
	var h := float(spec_d["h"])
	for c in txt:
		var cell: Dictionary = cells[c]
		var v: Dictionary = cell["p%d" % (pen % 2)]
		draw_texture_rect_region(_date_digits, Rect2(pen, y, cell["w"], h),
			Rect2(v["x"], 0, cell["w"], h))
		pen += int(cell["adv"])


## Arrow plates: baked = left disabled / right enabled (frame 038). Overlays swap
## in the mirrored real cuts for the un-walked states.
func _draw_arrows() -> void:
	var can_prev := _idx > 0
	var can_next := _idx < _pages.size() - 1
	if can_prev and _arrow["left_on"] != null:
		draw_texture(_arrow["left_on"], R_PREV.position)
	if not can_next and _arrow["right_off"] != null:
		draw_texture(_arrow["right_off"], R_NEXT.position)
