extends Control
class_name SquadScreen
## PM98 SQUAD MANAGEMENT (PLANTILLA) screen rebuilt from the ORIGINAL game art at the
## coordinates reversed out of MANAGER.EXE (FUN_00552110). See docs/re/squad_screen_re.md.
##
## Reversed: title "SQUAD MANAGEMENT" at (150,16) in ProMan14; the squad list panel
## spans (8,48)..(516,469); player rows are 16px tall; a "YOUTH TEAM" button sits
## bottom-right at (523,360)..(635,385) loading recursos\iconos\plantilla\juveniles.bmp.
## The grid's per-attribute columns reuse the same player-grid codes proven on the
## LINE-UP screen (N. PLAYER ... EN SP ST AG QU FI MO AV); the original groups the
## squad into sections, so we section it by the demarcación byte decoded out of
## EQUIPOS.PKF, with the original's own band labels (KEEPERS / DEFENDERS /
## MIDFIELDERS / FORWARDS from MANAGER.EXE), sorted by ability.
##
## Driven live by the Career roster. Native 640x480; scales to fit its parent.
##
## INTERACTIVE: the reversed YOUTH TEAM button opens the youth screen (emits
## `youth_pressed`) when youth is enabled (the managed club); the RETURN button or a tap
## on empty space emits `back_pressed` (the display-screen tap-to-dismiss). The GameDB
## browse mounts it with youth disabled, so any tap there just dismisses as before.

signal youth_pressed
signal back_pressed

const W := 640
const H := 480

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_SECTION := Color(1.0, 0.87, 0.0)   # FUN_00437020(0xff,0xdf,0) gold section text
const C_NAME := Color(1.0, 1.0, 1.0)
const C_BTN := Color(0.16, 0.43, 0.27)
const C_BTN_HI := Color(0.27, 0.59, 0.39)

# Player-grid columns (the codes proven on the line-up screen), laid into the
# reversed full-width squad panel (x 8..516). {code, x_left, attr_key}.
const COLS := [
	["N.", 12, "_num"], ["PLAYER", 38, "_name"], ["AGE", 168, "_age"],
	["EN", 198, "EN"], ["SP", 224, "VE"], ["ST", 250, "RE"], ["AG", 276, "AG"],
	["QU", 302, "CA"], ["FI", 328, "TI"], ["MO", 354, "RM"], ["AV", 386, "_avg"],
	["POS", 420, "_pos"],
]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

const PANEL := Rect2(8, 48, 508, 421)   # reversed (8,72,516,469) list region
const HDR_Y := 52
const ROW0_Y := 70
const ROW_H := 16
const YOUTH_BTN := Rect2(523, 360, 112, 25)   # reversed (0x20b,0x168)..(0x27b,0x181)
const RETURN_BTN := Rect2(523, 440, 112, 25)

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

const KIT_SRC := Rect2(0, 0, 31, 64)          # shirt half of the 48x64 MINIESC kit
const KIT_BOX := Rect2(539, 118, 80, 150)     # the club kit in the free right-strip gap

var _club: Dictionary = {}
var _manager: String = ""
var _cash: String = ""
var _youth_enabled := false      # the YOUTH TEAM button is live only for the managed club
var _press := ""                 # "youth" / "return" held down (for the highlight)
var _kit_tex: Texture2D          # the club's kit (escudo), or null if no art for the id


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, manager: String = "", cash: String = "", youth_enabled := false) -> void:
	_club = club
	_manager = manager
	_cash = cash
	_youth_enabled = youth_enabled
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

## The control under a design-space point: "youth" (only when enabled), "return", or "".
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
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		queue_redraw()
		# A tap on a live control fires it; any other tap dismisses (only if it didn't
		# start on a control), preserving the display-screen tap-to-dismiss feel.
		if a != "" and a == was:
			if a == "youth":
				youth_pressed.emit()
			else:
				back_pressed.emit()
		elif was == "":
			back_pressed.emit()


# ---- ordering ------------------------------------------------------------

## The squad split into the four decoded position sections (the demarcación byte
## reversed out of EQUIPOS.PKF: GK/DF/MF/FW), each sorted by ability. Records with no
## decoded position fall back to the GK flag (keepers) or an OUTFIELD catch-all.
## Returns [{section:String, players:Array}], empty sections dropped.
func _sections() -> Array:
	var bucket := {"GK": [], "DF": [], "MF": [], "FW": [], "OUT": []}
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		bucket[_pos_of(p)].append(p)
	var by_avg := func(a, b): return _avg_of(a) > _avg_of(b)
	var out: Array = []
	for key in ["GK", "DF", "MF", "FW", "OUT"]:
		if bucket[key].is_empty():
			continue
		bucket[key].sort_custom(by_avg)
		out.append({"section": SECTION_LABELS[key], "players": bucket[key]})
	return out


# The original's own section-header strings, lifted verbatim from MANAGER.EXE
# (KEEPERS / DEFENDERS / MIDFIELDERS / FORWARDS — the 4-entry band table at 0x634e28).
const SECTION_LABELS := {
	"GK": "KEEPERS", "DF": "DEFENDERS", "MF": "MIDFIELDERS",
	"FW": "FORWARDS", "OUT": "OUTFIELD",
}

## A player's section key: the decoded GK/DF/MF/FW, or a faithful fallback for records
## without a position byte (keeper by the GK flag, else the OUTFIELD catch-all).
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


func _cell(x: int, y: int, w: int, h: int, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(Rect2(x, y, w, h), base, true)
	draw_rect(Rect2(x, y, w, 1), hi, true)
	draw_rect(Rect2(x, y, 1, h), hi, true)
	draw_rect(Rect2(x, y + h - 1, w, 1), lo, true)
	draw_rect(Rect2(x + w - 1, y, 1, h), lo, true)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 150, 13, "SQUAD MANAGEMENT", C_TITLE, 15)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, str(_club.get("name", "")).substr(0, 18), C_TEXT, 13, true)
	if _cash != "":
		_txt(_f12, 628, 26, _cash, C_DIM, 13, true)

	# Column header row.
	for c in COLS:
		var code: String = c[0]
		var x: int = c[1]
		if code == "PLAYER" or code == "N.":
			_txt(_f8, x, HDR_Y, code, C_HEAD, 11)
		else:
			_txt(_f8, x + 18, HDR_Y, code, C_HEAD, 11, true)

	_draw_list()
	_draw_side()


func _draw_list() -> void:
	var secs := _sections()
	# Keep the reversed 16px rows for ordinary squads; compress just enough to fit when
	# the four position sections + a deep squad would otherwise clip a whole group (the
	# old GK/outfield split only ever dropped the weakest fringe; four sections must not
	# hide the forwards). Never below 11px so the PROMAN8 row text stays legible.
	var n_players := 0
	for sec in secs:
		n_players += (sec["players"] as Array).size()
	var n_rows := n_players + secs.size()
	var avail := int(PANEL.position.y + PANEL.size.y) - ROW0_Y
	var row_h: int = ROW_H if n_rows == 0 else clampi(avail / n_rows, 11, ROW_H)

	var y := ROW0_Y
	var row := 0
	var number := 1
	for sec in secs:
		# Section header (gold), like the original's section split.
		_txt(_f8, COLS[1][1], y + 2, str(sec["section"]), C_SECTION, 11)
		y += row_h
		for p in sec["players"]:
			if y + row_h > int(PANEL.position.y + PANEL.size.y):
				return
			draw_rect(Rect2(int(PANEL.position.x), y, int(PANEL.size.x), row_h - 1),
				C_ROW_A if row % 2 == 0 else C_ROW_B, true)
			_row_player(p, number, y)
			y += row_h
			row += 1
			number += 1


func _row_player(p: Dictionary, number: int, y: int) -> void:
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	var ty := y + 2
	for c in COLS:
		var key: String = c[2]
		var x: int = c[1]
		match key:
			"_num":
				_txt(_f8, x + 16, ty, str(number), C_TEXT, 11, true)
			"_name":
				_txt(_f8, x, ty, str(p.get("name", "?")).substr(0, 16), C_NAME, 11)
			"_age":
				_txt(_f8, x + 18, ty, str(p.get("age", "")), C_TEXT, 11, true)
			"_avg":
				_txt(_f8, x + 18, ty, str(_avg_of(p)), C_TEXT, 11, true)
			"_pos":
				# Availability takes the POS cell when a player is out: INJ/SUS in its
				# status colour, else the GK/OUT we can derive faithfully from the data.
				var st := Availability.status(p)
				if st["state"] == "FIT":
					_txt(_f8, x, ty, _pos_of(p), C_DIM, 11)
				else:
					_txt(_f8, x, ty, "%s %dw" % [st["state"], int(st["weeks"])], st["colour"], 11)
			_:
				var v: Variant = attrs.get(key)
				_txt(_f8, x + 18, ty, str(int(v)) if v != null else "-", C_TEXT, 11, true)


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


## Right column: squad count, the reversed YOUTH TEAM button + a small info box.
func _draw_side() -> void:
	var n := 0
	for p in _club.get("players", []):
		if int(p.get("id", -1)) >= 0:
			n += 1
	_cell(523, 60, 112, 40, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, 529, 64, "SQUAD", C_HEAD, 11)
	_txt(_f12, 631, 78, "%d players" % n, C_TEXT, 13, true)

	# The club kit (escudo) in the free gap between the SQUAD cell and the YOUTH button.
	if _kit_tex != null:
		var sc: float = min(KIT_BOX.size.x / KIT_SRC.size.x, KIT_BOX.size.y / KIT_SRC.size.y)
		var kw := KIT_SRC.size.x * sc
		var kh := KIT_SRC.size.y * sc
		draw_texture_rect_region(_kit_tex,
			Rect2(KIT_BOX.position.x + (KIT_BOX.size.x - kw) * 0.5,
				KIT_BOX.position.y + (KIT_BOX.size.y - kh) * 0.5, kw, kh), KIT_SRC)

	# YOUTH TEAM: a live green button on the managed club (opens the academy), greyed on a
	# browsed club where there's no youth team to open.
	var yb := YOUTH_BTN
	var ybase := (C_BTN_HI if _press == "youth" else C_BTN) if _youth_enabled else C_CELL
	_cell(int(yb.position.x), int(yb.position.y), int(yb.size.x), int(yb.size.y),
		ybase, C_BTN_HI if _youth_enabled else C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(yb.position.x) + 10, int(yb.position.y) + 6, "YOUTH TEAM",
		Color(0.92, 1.0, 0.94) if _youth_enabled else C_DIM, 11)

	var rb := RETURN_BTN
	_cell(int(rb.position.x), int(rb.position.y), int(rb.size.x), int(rb.size.y),
		C_CELL_HI if _press == "return" else C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(rb.position.x) + 6, int(rb.position.y) + 6, "RETURN", C_TEXT, 11)
