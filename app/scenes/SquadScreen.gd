extends Control
class_name SquadScreen
## PM98 SQUAD MANAGEMENT (PLANTILLA) screen — the real game's CONTRACT view
## (walkthrough frame 077_154612): the shared PMChrome plaque header + blue marble
## background over a white table with boxed cells — N° | PLAYER | AV | MO | LOAN |
## WAGE | YEARS(term|left) — grouped into the original's own KEEPERS / DEFENDERS /
## MIDFIELDERS / FORWARDS sections (the demarcación byte decoded out of EQUIPOS.PKF),
## each section in REVERSE record order (the original loader prepends to its player
## list; frame 077 shows every section exactly file-reversed — squad_number_re.md).
## N° is the decoded per-player squad number (EQUIPOS byte after the photo-id u16);
## MO (morale, a dynamic save value) is NOT modelled yet and renders "-" — never
## fabricated (APP_VS_SPEC_AUDIT B7). Right: the SQUAD count, the club kit and the
## YOUTH TEAM / RETURN buttons at their reversed positions.
##
## Driven live by the Career roster. Native 640x480; scales to fit its parent.
##
## INTERACTIVE: the YOUTH TEAM button opens the youth screen (emits `youth_pressed`) when
## youth is enabled (the managed club); the RETURN button or a tap on empty space emits
## `back_pressed` (the display-screen tap-to-dismiss).

signal youth_pressed
signal back_pressed
signal player_pressed(player)

const W := 640
const H := 480

const C_BTN := Color(0.18, 0.44, 0.26)           # green YOUTH button
const C_BTN_HI := Color(0.34, 0.62, 0.40)
const C_DKBTN := Color(0.10, 0.16, 0.32)
const C_DKBTN_HI := Color(0.34, 0.46, 0.72)
const C_DKBTN_LO := Color(0.04, 0.08, 0.18)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_GOLD := Color(1.0, 0.86, 0.22)

# Contract-view cell colors, sampled from walkthrough frame 077_154612 (the column
# CODE in the header is drawn in its own value colour, like the original).
const C_NO := Color8(0, 0, 128)                  # N° squad number (navy)
const C_SECTION := Color8(0, 0, 190)             # KEEPERS/DEFENDERS/... labels (blue)
const C_AV := Color8(212, 63, 0)                 # AV (orange-red)
const C_MO := Color8(75, 109, 172)               # MO (steel blue)
const C_LOANC := Color8(100, 130, 10)            # LOAN YES/NO (olive)
const C_WAGE := Color8(150, 0, 0)                # WAGE (dark red)
const C_YEARS := Color8(42, 63, 170)             # YEARS pair (blue)
const C_EXPIRE_TXT := Color8(255, 31, 0)         # remaining year == 1: red text ...
const C_EXPIRE_BG := Color8(255, 255, 170)       # ... on a yellow cell
const C_CELL_BG := Color8(240, 240, 240)         # boxed cell / row fill
const C_CELL_BRD := Color8(128, 128, 128)        # cell border grey

# Contract-view cell x-spans (left, right), from the frame-077 border scan:
# AV 273-298 | MO 298-323 | LOAN 323-359 | WAGE 359-429 | YEARS 429-454 | 454-479.
const CELL_AV := [273, 298]
const CELL_MO := [298, 323]
const CELL_LOAN := [323, 359]
const CELL_WAGE := [359, 429]
const CELL_Y1 := [429, 454]
const CELL_Y2 := [454, 479]
const NO_X0 := 16                                # N° box left edge
const NO_X1 := 46                                # N° box right edge

const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

const TABLE := Rect2(6, 50, 510, 426)
const HDR_Y := 66
const ROW_X := 8
const ROW_W := 506
const ROW0_Y := 84
const ROW_H := 16
const NAME_X := 52
const KIT_SRC := Rect2(0, 0, 31, 64)
const KIT_BOX := Rect2(534, 150, 100, 130)
const YOUTH_BTN := Rect2(522, 360, 112, 25)
const RETURN_BTN := Rect2(522, 440, 112, 25)

var _f12: Font
var _f10: Font
var _f8: Font

var _club: Dictionary = {}
var _manager: String = ""
var _cash: String = ""
var _season: String = "1997-98"
var _week: int = 0
var _tier: int = 1
var _nos_ok := false   # club's stored squad numbers are individuated -> N° displayable
var _youth_enabled := false
var _press := ""
var _kit_tex: Texture2D
var _rows: Array = []   # [{r: Rect2 (design space), p: Dictionary}] for player-row taps


func _ready() -> void:
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, manager: String = "", cash: String = "", youth_enabled := false,
		season: String = "1997-98", week: int = 0, tier: int = 1) -> void:
	_club = club
	_manager = manager
	_cash = cash
	_youth_enabled = youth_enabled
	_season = season
	_week = week
	_tier = tier
	_nos_ok = _squad_numbers_individuated()
	var cid := int(club.get("id", -1))
	var path := "res://art/kits/%d.png" % cid
	_kit_tex = load(path) if cid >= 0 and ResourceLoader.exists(path) else null
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
	return ""

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
		queue_redraw()
	else:
		var d := _to_design(pos)
		var a := _hit(d)
		var was := _press
		_press = ""
		queue_redraw()
		if a != "" and a == was:
			if a == "youth":
				youth_pressed.emit()
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

## Sections in the original's display order: within each position group the rows run in
## REVERSE roster (EQUIPOS record) order — frame 077 shows every Man Utd section exactly
## file-reversed (the game's loader prepends onto its player list; FUN_00588580 then
## walks that list). A player signed later (appended to the roster) thus shows first.
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
## duplicates). Lower-division EQUIPOS records often leave the whole squad at the
## 0x01 pad -> N° isn't stored there and renders "-" (squad_number_re.md).
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


const SECTION_LABELS := {
	"GK": "KEEPERS", "DF": "DEFENDERS", "MF": "MIDFIELDERS",
	"FW": "FORWARDS", "OUT": "OUTFIELD",
}

func _pos_of(p: Dictionary) -> String:
	var pos := str(p.get("pos", ""))
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if p.get("isGK") else "OUT"


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	# Title is the screen's own string "SQUAD MANAGEMENT" @.data 0x65f098 (squad_screen_re.md).
	PMChrome.draw_header(self, "SQUAD MANAGEMENT", _manager, str(_club.get("name", "")),
		str(_club.get("leagueName", "")), _season, _week, int(_club.get("id", -1)))

	PMChrome.draw_table_panel(self, TABLE)
	var secs := _sections()
	_draw_col_header(str(secs[0]["section"]) if not secs.is_empty() else "")
	_draw_list()
	_draw_side()


## Top header row (frame 077): N° + the first section's label + the column codes,
## each code in its own value colour (AV red, MO blue, LOAN olive, WAGE dark red,
## YEARS blue) on the white panel.
func _draw_col_header(first_section: String) -> void:
	_txt(_f10, NO_X1 - 6, HDR_Y + 2, "N°", C_NO, 11, true)
	_txt(_f10, NAME_X, HDR_Y + 2, first_section, C_SECTION, 11)
	_cell_code("AV", CELL_AV, C_AV)
	_cell_code("MO", CELL_MO, C_MO)
	_cell_code("LOAN", CELL_LOAN, C_LOANC)
	_cell_code("WAGE", CELL_WAGE, C_WAGE)
	_txt(_f10, (CELL_Y1[0] + CELL_Y2[1]) / 2 + 16, HDR_Y + 2, "YEARS", C_YEARS, 11, true)


func _cell_code(code: String, span: Array, col: Color) -> void:
	var w := _f10.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x if _f10 else 0.0
	_txt(_f10, int((span[0] + span[1] - w) / 2.0), HDR_Y + 2, code, col, 11)


func _draw_list() -> void:
	_rows.clear()
	var secs := _sections()
	var n_players := 0
	for sec in secs:
		n_players += (sec["players"] as Array).size()
	var n_rows := n_players + secs.size()
	var avail := int(TABLE.end.y - 4) - ROW0_Y
	var row_h: int = ROW_H if n_rows == 0 else clampi(avail / n_rows, 11, ROW_H)

	var y := ROW0_Y
	var first := true
	for sec in secs:
		if not first:
			_section(y, str(sec["section"]), row_h)
			y += row_h
		first = false
		for p in sec["players"]:
			if y + row_h > int(TABLE.end.y - 4):
				return
			_row(y, p, str(sec["key"]), row_h)
			y += row_h


## Section band: the original draws just the blue group label on the white panel
## (the first group's label lives in the column-header row instead).
func _section(y: int, label: String, row_h: int) -> void:
	_txt(_f10, NAME_X, y + maxi(1, (row_h - 12) / 2), label, C_SECTION, 11)


## A boxed cell of the contract row: light-grey fill, grey border (frame 077 rows
## are individual 13px boxes at 16px pitch).
func _cell(x0: int, x1: int, y: int, row_h: int, bg: Color = C_CELL_BG) -> void:
	var r := Rect2(x0, y, x1 - x0, row_h - 3)
	draw_rect(r, bg, true)
	draw_rect(r, C_CELL_BRD, false, 1.0)


func _row(y: int, p: Dictionary, key: String, row_h: int) -> void:
	_rows.append({"r": Rect2(ROW_X, y, ROW_W, row_h - 1), "p": p})
	var ty: int = y + maxi(1, (row_h - 14) / 2)

	# N° | PLAYER | AV | MO | LOAN | WAGE | YEARS(term|left) boxed cells. A GameDB
	# browse club has no career contract fields -> YEARS renders "-" (no fake expiry).
	var has_contract := p.has("contract_years")
	var expiring := has_contract and int(p.get("contract_years", 1)) <= Contract.EXPIRING_YEARS
	_cell(NO_X0, NO_X1, y, row_h)
	_cell(NO_X1, CELL_AV[0], y, row_h)
	_cell(CELL_AV[0], CELL_AV[1], y, row_h)
	_cell(CELL_MO[0], CELL_MO[1], y, row_h)
	_cell(CELL_LOAN[0], CELL_LOAN[1], y, row_h)
	_cell(CELL_WAGE[0], CELL_WAGE[1], y, row_h)
	_cell(CELL_Y1[0], CELL_Y1[1], y, row_h)
	_cell(CELL_Y2[0], CELL_Y2[1], y, row_h, C_EXPIRE_BG if expiring else C_CELL_BG)

	# N°: the decoded EQUIPOS squad number; "-" when this club's numbers aren't
	# individuated in the source data (never invented).
	var no_txt := str(int(p.get("squadNo", 0))) if _nos_ok else "-"
	_txt(_f10, NO_X1 - 6, ty, no_txt, C_NO, 11, true)

	# Name: black, like the frame; an injured/suspended player keeps the status
	# suffix the DATA-BASE view surfaced (availability must stay visible here).
	var st := Availability.status(p)
	_txt(_f10, NAME_X, ty, str(p.get("name", "?")).substr(0, 24), Color.BLACK, 11)
	if st["state"] != "FIT":
		_txt(_f8, CELL_AV[0] - 52, ty, "%s %dw" % [st["state"], int(st["weeks"])], st["colour"], 10)

	_txt(_f10, CELL_AV[1] - 5, ty, str(_avg_of(p)), C_AV, 11, true)
	# MO (morale) is a dynamic save value the app doesn't model yet -> honest gap,
	# never the unrelated static RM attribute (APP_VS_SPEC_AUDIT B7).
	_txt(_f10, CELL_MO[1] - 5, ty, "-", C_MO, 11, true)
	_txt(_f10, CELL_LOAN[0] + 8, ty, "YES" if p.get("on_loan") else "NO", C_LOANC, 11)
	var wage_y := Contract.yearly(Contract.current_weekly(p, _tier))
	_txt(_f10, CELL_WAGE[1] - 6, ty, "£%s" % _money(wage_y), C_WAGE, 11, true)
	var left := int(p.get("contract_years", 0))
	var term: int = maxi(int(p.get("contract_term", 0)), left)
	_txt(_f10, CELL_Y1[1] - 8, ty, str(term) if has_contract else "-", C_YEARS, 11, true)
	_txt(_f10, CELL_Y2[1] - 8, ty, str(left) if has_contract else "-",
		C_EXPIRE_TXT if expiring else C_YEARS, 11, true)


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


## Right column: squad count, the club kit, the YOUTH TEAM + RETURN buttons.
func _draw_side() -> void:
	var px := 522.0
	var pw := 112.0
	var n := 0
	for p in _club.get("players", []):
		if int(p.get("id", -1)) >= 0:
			n += 1
	PMChrome.bevel(self, Rect2(px, 52, pw, 44), Color(0.10, 0.16, 0.34), C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(px) + 6, 56, "SQUAD", C_PANEL_TXT, 11)
	_txt(_f12, int(px + pw) - 8, 74, "%d players" % n, Color.WHITE, 13, true)

	if _kit_tex != null:
		var sc: float = min(KIT_BOX.size.x / KIT_SRC.size.x, KIT_BOX.size.y / KIT_SRC.size.y)
		var kw := KIT_SRC.size.x * sc
		var kh := KIT_SRC.size.y * sc
		draw_texture_rect_region(_kit_tex,
			Rect2(KIT_BOX.position.x + (KIT_BOX.size.x - kw) * 0.5,
				KIT_BOX.position.y + (KIT_BOX.size.y - kh) * 0.5, kw, kh), KIT_SRC)

	var yb := YOUTH_BTN
	var ybase := (C_BTN_HI if _press == "youth" else C_BTN) if _youth_enabled else C_DKBTN
	PMChrome.bevel(self, yb, ybase, C_BTN_HI if _youth_enabled else C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(yb.position.x) + 10, int(yb.position.y) + 7, "YOUTH TEAM",
		Color(0.92, 1.0, 0.94) if _youth_enabled else PMChrome.C_STAR_OFF, 11)

	var rb := RETURN_BTN
	PMChrome.bevel(self, rb, C_DKBTN_HI if _press == "return" else C_DKBTN, C_DKBTN_HI, C_DKBTN_LO)
	_txt(_f10, int(rb.position.x) + 30, int(rb.position.y) + 7, "RETURN", C_GOLD, 12)
