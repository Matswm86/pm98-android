extends Control
class_name SquadScreen
## PM98 SQUAD MANAGEMENT (PLANTILLA) — the real game's CONTRACT view, rebuilt
## FRAME-BAKED 2026-07-13 against walkthrough run-1 frame 077_154612
## (docs/re/squad_screen_re.md). Doctrine = RivalScreen / LineupScreen:
##
##   * the shared SILVER header (band + manager/club plaque + crest + spiral
##     calendar sheet + green Preseason/Preparation bands) is painted live by
##     PMChrome.draw_match_header — the SAME header LINE-UP / VIEW RIVAL were
##     validated 0px against (the OLD blue procedural draw_header is gone);
##   * the SQUAD MANAGEMENT title glyphs are the frame's own bitmap, cut over
##     band.png (art/screens/squad/title_squad.png) so they blit seamlessly;
##   * the BODY chrome (art/screens/squad/chrome.png) is frame 077 VERBATIM —
##     blue-marble FONDO, white boxed table panel, the N° KEEPERS AV MO LOAN
##     WAGE YEARS column-header row (each code in its value colour), the
##     per-section scrollbar and the YOUTH TEAM + RETURN buttons — with only the
##     player-row grid cleared to panel white.
##
## SquadScreen draws ONLY the dynamic layer on top: the DEFENDERS / MIDFIELDERS /
## FORWARDS section bands and the player rows, each row a per-cell grid box
## (grey-128 border, grey-240 fill, 16px pitch — the frame's own structure) with
## the frame-sampled column colours and the real PROMAN fonts. N° | PLAYER | AV |
## MO | LOAN | WAGE | YEARS(term|left), grouped KEEPERS / DEFENDERS /
## MIDFIELDERS / FORWARDS (EQUIPOS demarcación), each section in REVERSE record
## order (squad_number_re.md). Driven live by the Career roster.
##
## The OLD invented chrome (dark-navy management_bg, blue title bar, the
## SQUAD-count box + club-kit right panel) is REMOVED — none of it is in the
## frame; the frame's right column is the scrollbar + the two buttons.
##
## INTERACTIVE: YOUTH TEAM opens the youth screen (emits youth_pressed) on the
## managed club; RETURN or a tap on empty space emits back_pressed; a player-row
## tap opens his PLAYER INFORMATION (emits player_pressed). While the FICHA card
## is up, set_dimmed routes the body + rows through the exact alert LUT
## (081-vs-082 pair); the live silver header stays bright — draw_match_header is
## not LUT-aware and PMChrome is out of edit scope (documented gap).

signal youth_pressed
signal back_pressed
signal player_pressed(player)

const W := 640
const H := 480
const BODY_Y0 := 62                      # header band height (draw_match_header)

# ---- frame-baked geometry (tools/re/specs/squad_chrome_samples.json) --------
const TITLE_XY := Vector2(186, 16)       # SQUAD MANAGEMENT glyph sprite anchor
const PANEL_Y0 := 74
const PANEL_Y1 := 466                     # white panel bottom (rows clip here)
const ROW0_Y := 92                        # first player-row band TOP border
const ROW_PITCH := 16
const ROW_X := 11                         # row band left (panel interior)
const ROW_W := 480                        # band width x11..491 (up to scrollbar)
const NAME_X := 52
const YOUTH_BTN := Rect2(521, 357, 115, 25)
const RETURN_BTN := Rect2(527, 436, 101, 29)

# cell x-spans (left, right) — frame-077 border scan (unchanged: already frame-true)
const CELL_NO := [16, 46]
const CELL_AV := [273, 298]
const CELL_MO := [298, 323]
const CELL_LOAN := [323, 359]
const CELL_WAGE := [359, 429]
const CELL_Y1 := [429, 454]
const CELL_Y2 := [454, 479]

# frame-sampled inks
const C_NO := Color8(0, 0, 128)
const C_SECTION := Color8(0, 0, 190)
const C_AV := Color8(212, 63, 0)
const C_MO := Color8(75, 109, 172)
const C_LOANC := Color8(100, 130, 10)
const C_WAGE := Color8(150, 0, 0)
const C_YEARS := Color8(42, 63, 170)
const C_EXPIRE_TXT := Color8(255, 31, 0)
const C_EXPIRE_BG := Color8(255, 255, 170)
const C_CELL_BG := Color8(240, 240, 240)
const C_CELL_BRD := Color8(128, 128, 128)
const C_PRESS := Color8(255, 0, 0)        # baked-button press ring
# Transfer-listed tag: gold bar + white "MARKET" in the name column (frame 15 McClair,
# gold RGB 212,159,0 measured; design x 162..218 mapped off the AV/N reference columns).
const C_MARKET_BG := Color8(212, 159, 0)
const MARKET_TAG_X := 162
const MARKET_TAG_W := 56

# Per-section slot bands, measured off frame 077 (grey-128 row borders scanned down
# x=20): the original does NOT compress rows to fit a deep squad — every section has a
# FIXED number of 16px slots and its OWN scrollbar, and the surplus scrolls. KEEPERS is
# baked into the column-header row so it has no label band of its own.
#   KEEPERS   3 slots @ 92/108/124
#   DEFENDERS 6 slots @ 156..236   (label band 140)
#   MIDFIELDERS 6 slots @ 268..348 (label band 252)
#   FORWARDS  5 slots @ 380..444   (label band 364)
const SECT_SLOTS := {
	"GK": {"top": 92, "rows": 3, "label": 0, "up": 92, "down": 122},
	"DF": {"top": 156, "rows": 6, "label": 140, "up": 156, "down": 234},
	"MF": {"top": 268, "rows": 6, "label": 252, "up": 268, "down": 346},
	"FW": {"top": 380, "rows": 5, "label": 364, "up": 380, "down": 442},
	"OUT": {"top": 380, "rows": 5, "label": 364, "up": 380, "down": 442},
}
# Scroll-arrow buttons: the yellow glyphs sit at x496..503 (frame scan); the baked
# button cell is 16px wide from x492. Section tops above give each pair's y.
const SB_X := 492
const SB_W := 17
const SB_H := 17

const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]
const SECTION_LABELS := {
	"GK": "KEEPERS", "DF": "DEFENDERS", "MF": "MIDFIELDERS",
	"FW": "FORWARDS", "OUT": "OUTFIELD",
}

var _sect_scroll: Dictionary = {}   # section key -> first visible player index
var _chrome: Texture2D
var _chrome_dim: Texture2D
var _title: Texture2D
var _title_dim: Texture2D
var _f12: Font
var _f10: Font
var _f8: Font

var _club: Dictionary = {}
var _manager: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _tier: int = 1
var _band: int = 3           # the club's PM98 stature band (RE'd wage/fee input)
var _nos_ok := false
var _youth_enabled := false
var _press := ""
var _down := false  # a press was seen; release without it is the emulated-mouse twin
var _drag := PMTouch.Drag.new()  # drag-to-scroll (input layer only)
var _drag_sect := ""             # the section band the drag pressed on
var _rows: Array = []
var _listed: Dictionary = {}              # pid:int -> true, the manager's transfer-listed players
var _header: Dictionary = {}
var _dimmed := false


func _ready() -> void:
	_chrome = load("res://art/screens/squad/chrome.png")
	_title = load("res://art/screens/squad/title_squad.png")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, manager: String = "", _cash: String = "", youth_enabled := false,
		season: String = "1997-98", week: int = 0, tier: int = 1, listed: Dictionary = {}) -> void:
	_club = club
	_manager = manager
	_youth_enabled = youth_enabled
	_season = season
	_week = week
	_tier = tier
	_listed = listed
	_band = TransferMarket.stature_of(club.get("players", []), tier)
	_nos_ok = _squad_numbers_individuated()
	# Shared silver header (LineupScreen precedent): manager plaque top, club
	# bottom, the club crest + spiral calendar sheet from the season/week.
	var d := PMChrome.date_parts(season, week)
	_header = {
		"mode": "manager", "top": manager,
		"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
		"club_id": int(club.get("id", -1)), "weekday": str(d["wd"]),
		"day": str(d["day"]), "month": str(d["mon"]), "year": str(d["year"]),
	}
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
	if _youth_enabled and YOUTH_BTN.has_point(d):
		return "youth"
	if RETURN_BTN.has_point(d):
		return "return"
	# The 17px stepper cells take PMTouch's grown rect (input-side only): the closest
	# up/down pair sits 13px apart (GK 92+17..122), so HIT_SLOP=5 never overlaps.
	for key in SECT_SLOTS:
		var slot: Dictionary = SECT_SLOTS[key]
		if PMTouch.near(Rect2(SB_X, int(slot["up"]), SB_W, SB_H), d):
			return "up:%s" % key
		if PMTouch.near(Rect2(SB_X, int(slot["down"]), SB_W, SB_H), d):
			return "down:%s" % key
	return ""


## Scroll one section by `delta` rows, clamped to its surplus. The original gives every
## section its own scrollbar (frame 077 shows four; the DEFENDERS/MIDFIELDERS pairs are
## live because Man Utd overflows their 6 slots, the other two washed).
func _scroll_section(key: String, delta: int) -> void:
	var slot: Dictionary = SECT_SLOTS.get(key, SECT_SLOTS["OUT"])
	var n := 0
	for sec in _sections():
		if str(sec["key"]) == key:
			n = (sec["players"] as Array).size()
	var maxs: int = maxi(0, n - int(slot["rows"]))
	var cur: int = clampi(int(_sect_scroll.get(key, 0)) + delta, 0, maxs)
	if cur != int(_sect_scroll.get(key, 0)):
		_sect_scroll[key] = cur
		queue_redraw()

## Section slot band under a design-space y, or "" (label bands + panel gaps miss).
func _sect_at_y(y: float) -> String:
	for sec in _sections():
		var key := str(sec["key"])
		var slot: Dictionary = SECT_SLOTS.get(key, SECT_SLOTS["OUT"])
		if y >= int(slot["top"]) and y < int(slot["top"]) + int(slot["rows"]) * ROW_PITCH:
			return key
	return ""


func _on_input(e: InputEvent) -> void:
	if e is InputEventScreenDrag or e is InputEventMouseMotion:
		# PMTouch drag-to-scroll: whole rows at ROW_PITCH, in the pressed section
		var rows := _drag.take_rows(_to_design(e.position).y, ROW_PITCH)
		if rows != 0 and _drag_sect != "":
			_scroll_section(_drag_sect, rows)
		return
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
		_down = true
		var dp := _to_design(pos)
		_press = _hit(dp)
		# arm the drag only over the player-row bands, never on a button/stepper (PMTouch)
		_drag_sect = _sect_at_y(dp.y) \
			if _press == "" and dp.x >= ROW_X and dp.x < ROW_X + ROW_W else ""
		_drag.press(dp.y, _drag_sect != "")
		queue_redraw()
	else:
		if _drag.release():
			# the gesture scrolled (or dup release) — no tap dispatch
			_down = false
			_press = ""
			queue_redraw()
			return
		# One release per press: with emulate_mouse_from_touch (Android default) every
		# touch also arrives as an emulated mouse event; without this gate a row tap
		# fired twice (second release hit the empty-space back_pressed fall-through and
		# collapsed the overlay stack to the hub). Same pattern as DataBaseScreen._down.
		if not _down:
			return
		_down = false
		var d := _to_design(pos)
		var a := _hit(d)
		var was := _press
		_press = ""
		queue_redraw()
		if a != "" and a == was:
			if a == "youth":
				youth_pressed.emit()
			elif a.begins_with("up:"):
				_scroll_section(a.substr(3), -1)
			elif a.begins_with("down:"):
				_scroll_section(a.substr(5), 1)
			else:
				back_pressed.emit()
			return
		# A tap on a player row opens his PLAYER INFORMATION (FICHA), not a dismiss.
		for row in _rows:
			if (row["r"] as Rect2).has_point(d):
				player_pressed.emit(row["p"])
				return
		if was == "":
			back_pressed.emit()


# ---- ordering ------------------------------------------------------------

## Sections in display order; within each group REVERSE roster (EQUIPOS record)
## order — frame 077 lists every Man Utd section file-reversed (squad_number_re.md).
func _sections() -> Array:
	var bucket := {"GK": [], "DF": [], "MF": [], "FW": [], "OUT": []}
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		bucket[_pos_of(p)].append(p)
	var out: Array = []
	for key in ["GK", "DF", "MF", "FW", "OUT"]:
		if bucket[key].is_empty():
			continue
		bucket[key].reverse()
		out.append({"key": key, "section": SECTION_LABELS[key], "players": bucket[key]})
	return out


## True when the club's stored squad numbers are individuated (all present, no
## duplicates); else N° renders "-" (squad_number_re.md).
func _squad_numbers_individuated() -> bool:
	var seen := {}
	var n := 0
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		var v: Variant = p.get("squadNo")
		if v == null:
			return false
		seen[int(v)] = true
		n += 1
	return n > 0 and seen.size() == n


func _pos_of(p: Dictionary) -> String:
	var pos := str(p.get("pos", ""))
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if p.get("isGK") else "OUT"


# ---- drawing -------------------------------------------------------------

func set_dimmed(on: bool) -> void:
	if _dimmed != on:
		_dimmed = on
		queue_redraw()


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, PMChrome.dim_col(col))


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Live silver header + the frame-cut SQUAD MANAGEMENT title. draw_match_header
	# is not LUT-aware, so it stays bright under the FICHA dim (documented gap).
	PMChrome.set_dim(_dimmed)
	PMChrome.draw_match_header(self, "", _header)
	var title := _title
	if _dimmed:
		if _title_dim == null:
			_title_dim = PMAlert.dim_texture(_title)
		title = _title_dim
	if title != null:
		draw_texture(title, TITLE_XY)

	# Body chrome (marble + boxed panel + column headers + scrollbar + buttons).
	var body := _chrome
	if _dimmed:
		if _chrome_dim == null:
			_chrome_dim = PMAlert.dim_texture(_chrome)
		body = _chrome_dim
	if body != null:
		draw_texture(body, Vector2(0, BODY_Y0))

	_draw_list()
	_draw_press()
	PMChrome.set_dim(false)


func _draw_list() -> void:
	_rows.clear()
	for sec in _sections():
		var key := str(sec["key"])
		var slot: Dictionary = SECT_SLOTS.get(key, SECT_SLOTS["OUT"])
		var n: int = int(slot["rows"])
		var top: int = int(slot["top"])
		if int(slot["label"]) > 0:
			_section(int(slot["label"]), str(sec["section"]), ROW_PITCH)
		var players: Array = sec["players"]
		var sc: int = clampi(int(_sect_scroll.get(key, 0)), 0, maxi(0, players.size() - n))
		_sect_scroll[key] = sc
		for i in n:
			var idx := sc + i
			if idx >= players.size():
				break
			_row(top + i * ROW_PITCH, players[idx], key, ROW_PITCH)


## Section band: the blue group label on the white panel (frame 077).
func _section(y: int, label: String, row_h: int) -> void:
	_txt(_f10, NAME_X, y + maxi(2, (row_h - 12) / 2), label, C_SECTION, 11)


## A boxed row cell: grey-240 fill, grey-128 border (frame-077 per-cell boxes).
func _cell(x0: int, x1: int, y: int, row_h: int, bg: Color = C_CELL_BG) -> void:
	var r := Rect2(x0, y, x1 - x0, row_h - 2)
	draw_rect(r, PMChrome.dim_col(bg), true)
	draw_rect(r, PMChrome.dim_col(C_CELL_BRD), false, 1.0)


func _row(y: int, p: Dictionary, _key: String, row_h: int) -> void:
	_rows.append({"r": Rect2(ROW_X, y, ROW_W, row_h - 1), "p": p})
	var ty: int = y + maxi(2, (row_h - 12) / 2)

	var has_contract := p.has("contract_years")
	var expiring := has_contract and int(p.get("contract_years", 1)) <= Contract.EXPIRING_YEARS
	_cell(CELL_NO[0], CELL_NO[1], y, row_h)
	_cell(CELL_NO[1], CELL_AV[0], y, row_h)              # NAME cell
	_cell(CELL_AV[0], CELL_AV[1], y, row_h)
	_cell(CELL_MO[0], CELL_MO[1], y, row_h)
	_cell(CELL_LOAN[0], CELL_LOAN[1], y, row_h)
	_cell(CELL_WAGE[0], CELL_WAGE[1], y, row_h)
	_cell(CELL_Y1[0], CELL_Y1[1], y, row_h)
	_cell(CELL_Y2[0], CELL_Y2[1], y, row_h, C_EXPIRE_BG if expiring else C_CELL_BG)

	# N°: decoded EQUIPOS squad number; "-" when this club's set isn't individuated.
	var no_txt := str(int(p.get("squadNo", 0))) if _nos_ok else "-"
	_txt(_f10, CELL_NO[1] - 8, ty, no_txt, C_NO, 11, true)

	# Name: black; injured/suspended keeps its status suffix (availability stays visible).
	var st := Availability.status(p)
	_txt(_f10, NAME_X, ty, str(p.get("name", "?")).substr(0, 24), Color.BLACK, 11)
	if st["state"] != "FIT":
		_txt(_f8, CELL_AV[0] - 52, ty, "%s %dw" % [st["state"], int(st["weeks"])], st["colour"], 10)
	# Transfer-listed: the original's gold "MARKET" tag in the name column (frame 15).
	if _listed.has(int(p.get("id", -1))):
		draw_rect(Rect2(MARKET_TAG_X, y, MARKET_TAG_W, row_h - 2), PMChrome.dim_col(C_MARKET_BG), true)
		var mw: float = _f10.get_string_size("MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_txt(_f10, int(MARKET_TAG_X + (MARKET_TAG_W - mw) / 2), ty, "MARKET", Color.WHITE, 10)

	# AV = real rating (FUN_00581e60) with form, else _avg_of for a bare GameDB club.
	var has_form := p.has("morale") or p.has("fitness")
	_txt(_f10, CELL_AV[1] - 5, ty, str(Morale.av6(p)) if has_form else str(_avg_of(p)),
		C_AV, 11, true)
	_txt(_f10, CELL_MO[1] - 5, ty, str(Morale.display(p)) if has_form else "-",
		C_MO, 11, true)
	_txt(_f10, CELL_LOAN[0] + 8, ty, "YES" if p.get("on_loan") else "NO", C_LOANC, 11)
	var wage_y := Contract.current_yearly(p, _band)
	_txt(_f10, CELL_WAGE[1] - 6, ty, "£%s" % _money(wage_y), C_WAGE, 11, true)
	var left := int(p.get("contract_years", 0))
	var term: int = maxi(int(p.get("contract_term", 0)), left)
	_txt(_f10, CELL_Y1[1] - 8, ty, str(term) if has_contract else "-", C_YEARS, 11, true)
	_txt(_f10, CELL_Y2[1] - 8, ty, str(left) if has_contract else "-",
		C_EXPIRE_TXT if expiring else C_YEARS, 11, true)


## Baked-button press feedback: a 2px ring on the held button (the buttons
## themselves are baked chrome; the ring is the app's tap affordance).
func _draw_press() -> void:
	if _press == "youth" and _youth_enabled:
		draw_rect(YOUTH_BTN.grow(1.0), PMChrome.dim_col(C_PRESS), false, 2.0)
	elif _press == "return":
		draw_rect(RETURN_BTN.grow(1.0), PMChrome.dim_col(C_PRESS), false, 2.0)


## Thousands-separated integer for the WAGE column ("£1,000,000", frame 077).
func _money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


func _avg_of(p: Dictionary) -> int:
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
