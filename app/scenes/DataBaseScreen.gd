extends Control
class_name DataBaseScreen
## PM98 DATA BASE — the dbasewin.exe team/player browser SQUAD view, rebuilt from the
## reversed binary (NOT the invented green list it replaces). See docs/re/database_screen_re.md.
##
## Reversed 2026-06-29 from Dbasewin.exe:
##   * Background = RC_DBASE\FONDO DBASE.BMP, blitted at (0,0) (FUN_0042aba0 step 2).
##   * Four position columns built at literal widget rects (FUN_0042aba0, ebp+0x45f4 /
##     +0x4a0c / +0x4e24 / +0x523c), each titled GOALKEEPERS / DEFENDERS / MIDFIELDERS /
##     FORWARDS (str 0x493900..0x493930). Rects normalized via FUN_00404180(base, delta).
##   * Players binned into the 4 lists by their EQUIPOS demarcación category (0/1/2/3 =
##     GK/DF/MF/FW, FUN_0042c200) and sorted alphabetically by name (lstrcmp, FUN_0042c540).
##   * Each list rendered in LISTS mode (FUN_0042b540, this+0x2d4c == 0): Proman10, row
##     pitch 18px, first row y 21 within the column, name cell x=3 w=196; per row a MINIFOTO
##     thumbnail keyed by the player's photoId (FUN_0042c1c0 -> FUN_00445f10(id)) + the name.
##
## Native 640x480; scales to fit its parent (letterboxed). A row tap raises that player's
## FICHA (player_pressed); RETURN or a tap on empty space dismisses (back_pressed).

signal back_pressed
signal player_pressed(player)

const W := 640
const H := 480

# Column widget rects reversed from FUN_0042aba0, as Rect2(left, top, width, height).
# Each AddColumn call (vtable [edi+0xc0]) is preceded by FUN_004042b0(color, R,G,B) which
# writes a 4-byte COLORREF {R,G,B,0} — the per-position-group identity colour. Reversed by
# objdump at the four call sites (0x42af6d / 0x42afcd-style); the original colour-codes the
# four groups, it does NOT use one shared blue.
const COLS := [
	{"key": "GK", "title": "GOALKEEPERS", "rect": Rect2(6, 13, 208, 115),  "col": Color8(80, 110, 5)},    # ebp+0x45f4 (0x50,0x6e,0x05)
	{"key": "DF", "title": "DEFENDERS",   "rect": Rect2(6, 140, 209, 315), "col": Color8(212, 63, 0)},    # ebp+0x4a0c (0xd4,0x3f,0x00)
	{"key": "MF", "title": "MIDFIELDERS", "rect": Rect2(218, 140, 209, 315), "col": Color8(170, 0, 0)},   # ebp+0x4e24 (0xaa,0x00,0x00)
	{"key": "FW", "title": "FORWARDS",    "rect": Rect2(430, 140, 209, 277), "col": Color8(108, 21, 21)}, # ebp+0x523c (0x6c,0x15,0x15)
]
# Row metrics reversed from FUN_0042b540 (the two modes toggled by this+0x2d4c).
const HDR_H := 19      # title-text region height (informational); rows begin at FIRST_Y below it
# LISTS mode (Proman10): tight text rows, small thumbnail.
const FIRST_Y := 21    # local_270 (0x15): first row y within the column client
const PITCH := 18      # local_260 (0x12): Δy per row
const ROW_X := 3       # local_25c: item base x within the column
const ROW_W := 196     # local_268 (0xc4): item width
const ITEM_H := 16     # local_264 (0x10): item height (pitch 18 leaves a 2px gap)
# PHOTOS mode (Futuri18): taller rows, larger photo (RE doc session 3 table).
const FIRST_Y_PH := 25 # 0x19
const PITCH_PH := 40   # 0x28
const ROW_X_PH := 9    # 0x9: local_25c (PHOTOS)
const ROW_W_PH := 187  # 0xbb: local_268 (PHOTOS)
const ITEM_H_PH := 36  # 0x24: local_264 (PHOTOS)
# Fixed visible-row caps reversed from FUN_0042b540 (the row loop breaks at iVar8). The GK
# column caps at 4 rows (LISTS) / 2 (PHOTOS); the three outfield columns at 15 / 7. These are
# literal caps in the binary, NOT geometry — used both to cap rows and to gate the "more" badge.
const CAP_GK_LISTS := 4    # (-(mode!=0) & 0xfffffffe) + 4, mode==0
const CAP_GK_PHOTOS := 2   # ... mode!=0
const CAP_OUT_LISTS := 15  # (-(mode!=0) & 0xfffffff8) + 0xf, mode==0
const CAP_OUT_PHOTOS := 7  # ... mode!=0
# Per-column "more" scroll badge — reversed from FUN_0042b540 (items 0xdd..0xe0). Each is a
# fresh child of its column at relative base (0xa2,2)=(162,2), size delta (0x25,0x13)=(37,19),
# drawn by FUN_0042e590's 0xdd..0xe0 branch from cell this+0x742c[+0x54]: GK uses cell 0
# (MAS PORTEROS), the outfield columns use cell 2 (MAS JUGADORES). It appears only when the
# column's player count exceeds the visible cap (the binary adds the item under `if cap < count`).
const MORE_BADGE := Rect2(162, 2, 37, 19)
const RETURN_BTN := Rect2(516, 446, 118, 26)
# Tapping the title strip toggles LISTS <-> PHOTOS (the real game uses a bitmap button whose
# on-screen position is not yet reversed; this is a documented mobile stand-in, no invented art).
const TITLE_RECT := Rect2(224, 18, 372, 39)

# Status legend — reversed from FUN_0042aba0 Loop A (objdump 0x42b16d..0x42b2d1). Three cells
# at y=460 (push 0x1cc), x from the stack array {0xa,0x5a,0xaa,0x118} read [esp+esi+0x74]
# (esi=0,4,8 -> 10/90/170). Each cell = a marker bitmap blitted at the cell origin (FUN_00458730)
# + a label drawn in Calend8 black (FUN_00456560 "Calend8" before the loop, FUN_004042d0(buf,0)).
# Markers + labels paired from the 7-bmp array (idx 0..2) and PTR_s_New_signing @0x493958.
const LEGEND_Y := 460   # 0x1cc
const LEGEND := [
	{"x": 10,  "icon": "dbase_new_signing", "label": "New signing"},            # nuevo fichaje.bmp
	{"x": 90,  "icon": "dbase_youth",       "label": "Youth player"},           # ascendido.bmp
	{"x": 170, "icon": "dbase_absence",     "label": "Absence from the team"},  # baja.bmp
]
const C_LEGEND_TXT := Color(0, 0, 0)   # FUN_004042d0(buf, 0) = black

# ROW rendering — reversed from the ROW-ITEM paint method FUN_0042e590 (vtable PTR_LAB_00486a38
# slot +0x10c; the row class OVERRIDES the content-paint virtual, proven by diffing the row vtable
# against the column vtable 0x485ed8 where the same slot holds FUN_00402130). Facts (session 10):
#   * NAME = record+0xc, drawn by FUN_00452b90 in the DC text colour (+0x1fc). FUN_0042e590 sets
#     +0x1fc = uStack_40 = 0 (BLACK) for a normal row, 0xbfd4 (gold) only for the SELECTED row.
#     There is NO per-name status tint (that was a mis-read); the name is plain black.
#   * LISTS mode draws NO photo — FUN_0042c1c0 (the photo loader) is gated on mode!=0, and the
#     LISTS branch of FUN_0042e590 blits no bitmap. The 32x32 MINIFOTO appears ONLY in PHOTOS mode.
#   * STATUS underline bar (FUN_00404490 -> FUN_0044ed40): a 1px x 196 bar at item (left,+15) in
#     the player STATUS colour (player+0x4c): 1=green 0x0a8264, 2=blue 0xbe0000, 3=red 0x0000ff;
#     status 0 (silver 0xc0c0c0) draws NOTHING (gated `if status != 0`).
#   * NO alternating row banding and NO separator lines exist in the binary — both were invented.
const C_NAME := Color(0, 0, 0)                   # +0x1fc = 0 -> black (normal row)
const C_NAME_SEL := Color8(212, 191, 0)          # 0xbfd4 -> gold (selected row; unused in static view)
# Status -> 1px underline colour. Index by player status byte; 0 = no bar. COLORREF 0x00BBGGRR.
const STATUS_BAR := [Color8(192, 192, 192), Color8(100, 130, 10), Color8(0, 0, 190), Color8(255, 0, 0)]
# COLUMN paint — reversed end-to-end from FUN_00402130 (column vtable 0x485ed8 slot +0x10c),
# session 11 (disasm of FUN_00454200 / FUN_0045b080 / the AddColumn call site in FUN_0042aba0):
#   * TITLE colour = field +0x5c = the per-group COLORREF (GK olive / DF orange / MF red / FW
#     dark-red). FUN_00454200 stores param_7 (the AddColumn colour) at +0x5c; +0x60 (bevel base)
#     is the inherited PARENT colour, not this. So the title is group-coloured, NOT white.
#   * TITLE inset = field +0x3fc = 6 (FUN_0045b080). Drawn by FUN_00452b90 at client
#     (iStack_48 + left + 3 + 6, iStack_44 + top + 3) = (+9, +3) normal (iStack_48/44 = 0).
#   * Recessed BLACK bevel border: FUN_0044f830 draws 3 concentric bottom+right L-shadows of the
#     inset-3 rect, shifted +i, alpha 192/128/64 (FUN_0043d2d0 = bottom + right 1px edges, colour
#     0 = black via FUN_004042d0); then FUN_00404e60 a 1px BLACK outline at the inset-3 rect.
#   * Interior is NOT filled — FUN_00404e60 draws 4 edges only, so the FONDO shows through.
#   * Corner highlight ornaments (FUN_00404880 hline / FUN_00404930 vline / FUN_00404b30 rect,
#     shaded from +0x60 via FUN_004042f0/FUN_00404390) are NOT drawn: +0x60 is inherited from the
#     screen window, set at the screen's creation OUTSIDE the column code, and is not yet reversed.
#     Drawing them would require guessing the base colour, so they are left for the next pass.
const C_BEVEL_DARK := Color(0, 0, 0)             # FUN_004042d0(...,0) = black: frames + outline
const C_TITLE := Color(1, 1, 1)   # club-name title — verified 0xffffff (FUN_004042d0)
const C_BTN := Color(0.13, 0.27, 0.56)
const C_BTN_HI := Color(0.42, 0.58, 0.86)
const C_BTN_LO := Color(0.05, 0.10, 0.26)
const C_GOLD := Color(1.0, 0.84, 0.22)

var _bg: Texture2D
var _f10: Font
var _f12: Font
var _f18: Font
var _ffut: Font   # Futuri18 — PHOTOS-mode row font
var _fcal: Font   # Calend8 — legend caption font
var _photos := false
var _club: Dictionary = {}
var _press := ""
var _rows: Array = []   # [{r: Rect2 (design space), p: Dictionary}] for row taps


func _ready() -> void:
	_bg = load("res://art/screens/fondo_dbase.png") if ResourceLoader.exists("res://art/screens/fondo_dbase.png") else null
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f18 = PMChrome.font("18")
	_ffut = PMChrome.font("futuri18")
	_fcal = PMChrome.font("calend8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary) -> void:
	_club = club
	queue_redraw()


# ---- ordering ------------------------------------------------------------

## Bin the squad into the 4 EQUIPOS categories, alphabetical by name within each (the
## FUN_0042c200 -> FUN_0042c540 order). Unknown positions fall to midfield.
func _bucket(key: String) -> Array:
	var out: Array = []
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		if _cat_of(p) == key:
			out.append(p)
	out.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	return out


func _cat_of(p: Dictionary) -> String:
	var pos := str(p.get("pos", "")).to_upper()
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if p.get("isGK") else "MF"


## Fixed visible-row cap for a column in the current mode (FUN_0042b540 iVar8).
func _row_cap(key: String) -> int:
	if key == "GK":
		return CAP_GK_PHOTOS if _photos else CAP_GK_LISTS
	return CAP_OUT_PHOTOS if _photos else CAP_OUT_LISTS


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	if e is InputEventMouseButton:
		pos = (e as InputEventMouseButton).position
		pressed = (e as InputEventMouseButton).pressed
	elif e is InputEventScreenTouch:
		pos = (e as InputEventScreenTouch).position
		pressed = (e as InputEventScreenTouch).pressed
	else:
		return
	var d := _to_design(pos)
	if pressed:
		_press = "return" if RETURN_BTN.has_point(d) else ""
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if RETURN_BTN.has_point(d):
		if was == "return":
			back_pressed.emit()
		return
	for row in _rows:
		if (row["r"] as Rect2).has_point(d):
			player_pressed.emit(row["p"])
			return
	# Title strip toggles LISTS <-> PHOTOS (this+0x2d4c); stand-in for the real button.
	if TITLE_RECT.has_point(d):
		_photos = not _photos
		queue_redraw()
		return
	back_pressed.emit()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else x
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.08), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# FONDO DBASE.BMP at (0,0) — the real washed-blue football photo + grid.
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.36, 0.42, 0.56), true)

	# Header title: the club/competition name in Proman18, white, in the top strip to the
	# right of the GOALKEEPERS column. Widget this+0x5a6c, rect base (224,18) delta (372,39)
	# (FUN_0042aba0 0x42ae7e..0x42aea6), colour 0xffffff (FUN_004042d0). No "DATA BASE"
	# subtitle exists in the binary — that was invented; removed.
	var cap := str(_club.get("name", "")).to_upper()
	if cap != "":
		var tf: Font = _f18 if _f18 != null else _f12
		_txt(tf, 224, 18 + 10, cap, C_TITLE, 18)

	_rows.clear()
	for col in COLS:
		_draw_column(col)

	_draw_legend()
	_draw_return()


func _draw_column(col: Dictionary) -> void:
	var r: Rect2 = col["rect"]
	# Recessed BLACK bevel border (FUN_00402130). FUN_0044f830: 3 fading-black bottom+right
	# L-shadows of the inset-3 rect shifted +i (alpha 192/128/64); then FUN_00404e60: a 1px black
	# outline at the inset-3 rect. Interior left transparent (edges only -> FONDO shows through).
	var lx := r.position.x
	var ty := r.position.y
	for i in 3:
		var a := (192.0 - 64.0 * i) / 256.0
		var li := lx + 3 + i
		var tii := ty + 3 + i
		var ri := lx + r.size.x - 3 + i
		var bi := ty + r.size.y - 3 + i
		draw_rect(Rect2(li, bi - 1, ri - li, 1), Color(0, 0, 0, a), true)   # bottom edge
		draw_rect(Rect2(ri - 1, tii, 1, bi - tii), Color(0, 0, 0, a), true) # right edge
	draw_rect(Rect2(lx + 3, ty + 3, r.size.x - 6, r.size.y - 6), C_BEVEL_DARK, false)

	# COLUMN title: per-group colour (+0x5c), inset (+9, +3) (+0x3fc = 6). FUN_00452b90.
	_txt(_f10, lx + 9, ty + 3, str(col["title"]), col["col"], 11)

	# Mode-selected item metrics (FUN_0042b540: LISTS vs PHOTOS, toggled by this+0x2d4c).
	var lists := not _photos
	var first_y := FIRST_Y if lists else FIRST_Y_PH
	var pitch := PITCH if lists else PITCH_PH
	var item_x := ROW_X if lists else ROW_X_PH
	var item_w := ROW_W if lists else ROW_W_PH
	var item_h := ITEM_H if lists else ITEM_H_PH
	var name_f: Font = _f10 if lists else (_ffut if _ffut != null else _f12)
	var name_sz := 11 if lists else 18

	var players := _bucket(str(col["key"]))
	# Cap = the binary's fixed per-column cap, clamped to what fits the column geometry.
	var cap := _row_cap(str(col["key"]))
	var max_rows: int = min(int(floor((r.size.y - first_y) / pitch)), cap)
	for i in players.size():
		if i >= max_rows:
			break
		var p: Dictionary = players[i]
		var ix := r.position.x + item_x
		var iy := r.position.y + first_y + i * pitch
		_rows.append({"r": Rect2(ix, iy, item_w, item_h), "p": p})
		if lists:
			# LISTS (Proman10): NAME ONLY, inset (+6,+2), black. No thumbnail (FUN_0042c1c0
			# is gated on mode!=0), no banding, no separator — all of which the binary omits.
			_txt(name_f, ix + 6, iy + 2, str(p.get("name", "?")).substr(0, 22), C_NAME, name_sz)
			# Status underline bar (FUN_00404490): 1px x 196 at (left,+15) when status 1/2/3.
			var st := int(p.get("status", 0))
			if st >= 1 and st <= 3:
				draw_rect(Rect2(ix, iy + 15, item_w, 1), STATUS_BAR[st], true)
		else:
			# PHOTOS (Futuri18): 32x32 MINIFOTO at the item's left, name at +40 / +10 (black).
			var face := PMChrome.mini_face(p.get("photoId"))
			if face != null:
				draw_texture_rect(face, Rect2(ix, iy, 32, 32), false)
			_txt(name_f, ix + 40, iy + 10, str(p.get("name", "?")).substr(0, 14), C_NAME, name_sz)

	# "More" scroll badge in the column header when the squad overflows the cap (FUN_0042b540
	# adds item 0xdd..0xe0 only under `if cap < count`). GK -> MAS PORTEROS, outfield -> MAS
	# JUGADORES; both are 37x19 and blit 1:1 at the reversed relative origin (162,2).
	if players.size() > cap:
		var bx := r.position.x + MORE_BADGE.position.x
		var by := r.position.y + MORE_BADGE.position.y
		var bn := "dbase_more_gk" if str(col["key"]) == "GK" else "dbase_more_players"
		var btex := PMChrome.icon(bn)
		if btex != null:
			th_blit(btex, bx, by)
		else:
			draw_rect(Rect2(bx, by, MORE_BADGE.size.x, MORE_BADGE.size.y), Color(0.04, 0.5, 0.2, 0.6), true)


## Status legend (FUN_0042aba0 Loop A): 3 cells at y=460, x=10/90/170. Each is the real 11x11
## marker badge (nuevo fichaje / ascendido / baja) blitted at the cell origin + its Calend8
## caption in black to the right. Drawn in both modes — the original sets it up once, mode-blind.
func _draw_legend() -> void:
	var lf: Font = _fcal if _fcal != null else _f10
	var sz := 8
	for cell in LEGEND:
		var x: float = cell["x"]
		var tex := PMChrome.icon(str(cell["icon"]))
		var tw := 11.0
		if tex != null:
			th_blit(tex, x, LEGEND_Y)
			tw = float(tex.get_width())
		else:
			# Art absent: a neutral placeholder square so layout still reads (no invented glyph).
			draw_rect(Rect2(x, LEGEND_Y, 11, 11), Color(0, 0, 0, 0.25), true)
		# Caption to the right of the marker, vertically centred against the 11px badge.
		var ty := LEGEND_Y + (11 - sz) * 0.5
		_txt(lf, x + tw + 3, ty, str(cell["label"]), C_LEGEND_TXT, sz)


func th_blit(tex: Texture2D, x: float, y: float) -> void:
	draw_texture_rect(tex, Rect2(x, y, tex.get_width(), tex.get_height()), false)


func _draw_return() -> void:
	var rb := RETURN_BTN
	PMChrome.bevel(self, rb, C_BTN_HI if _press == "return" else C_BTN, C_BTN_HI, C_BTN_LO)
	_txt(_f10, rb.position.x + 34, rb.position.y + 7, "RETURN", C_GOLD, 12)
