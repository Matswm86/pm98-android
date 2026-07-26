extends RefCounted
class_name PMChrome
## Shared Premier Manager 98 management-screen chrome, drawn procedurally to match
## the real game (see ~/MWM-AI/data/pm98-refs/real-gallery/hires_league_table.jpg and
## ma_6/ma_7). Every management screen had three systemic divergences from the original
## (handoff 2026-06-17): a blurred stadium PHOTO background, NO top plaque row, and flat
## dark text instead of the game's panelled chrome. This module fixes all three in one
## place; screens opt in by calling these helpers from their own `_draw()` (passing
## `self` as the CanvasItem) so un-retrofitted screens are untouched until their turn.
##
## All coordinates are in the shared 640x480 design space the screens scale to fit.
## The header band is y 2..46; screen content starts at ~y 56.

const W := 640
const H := 480
const HEADER_H := 46

# --- palette read off the real screenshots --------------------------------
const C_BAR := Color(0.16, 0.31, 0.60)          # title bar body (blue)
const C_BAR_HI := Color(0.42, 0.58, 0.86)
const C_BAR_LO := Color(0.06, 0.13, 0.30)
const C_TITLE := Color(0.80, 0.90, 1.0)          # title text (pale blue)
const C_PLAQUE := Color(0.30, 0.42, 0.62)        # manager plaque (blue-grey)
const C_PLAQUE_HI := Color(0.56, 0.68, 0.88)
const C_PLAQUE_LO := Color(0.10, 0.18, 0.36)
const C_PLAQUE_TXT := Color(0.96, 0.98, 1.0)
const C_DATE_BG := Color(0.93, 0.95, 0.98)       # white date plaque
const C_DATE_HI := Color(1.0, 1.0, 1.0)
const C_DATE_LO := Color(0.55, 0.60, 0.70)
const C_DATE_TXT := Color(0.10, 0.16, 0.30)
const C_DATE_DAY := Color(0.74, 0.10, 0.10)      # the big red day number
const C_LEAGUE := Color(0.18, 0.44, 0.22)        # green league/week plaque
const C_LEAGUE_HI := Color(0.40, 0.66, 0.42)
const C_LEAGUE_LO := Color(0.06, 0.22, 0.10)
const C_LEAGUE_TXT := Color(0.96, 1.0, 0.92)
const C_GOLD := Color(1.0, 0.84, 0.22)
const C_GOLD_LO := Color(0.72, 0.54, 0.06)
const C_STAR_OFF := Color(0.42, 0.46, 0.54)

# White data-table chrome (LINE-UP / SQUAD / TRANSFER: handoff root cause 3 — the real
# game uses white/cream grids with a blue column header and dark-blue SUBSTITUTES /
# RESERVES section bands, not flat dark text on a photo).
const C_TBL := Color(0.93, 0.94, 0.90)           # white/cream table body
const C_TBL_HI := Color(1.0, 1.0, 0.99)
const C_TBL_LO := Color(0.50, 0.52, 0.54)
const C_TBL_HDR := Color(0.16, 0.28, 0.54)       # blue column-header strip
const C_TBL_HDR_TXT := Color(0.86, 0.92, 1.0)
const C_ROW_LIGHT := Color(0.95, 0.96, 0.92)     # alternating cream rows
const C_ROW_DARK := Color(0.86, 0.88, 0.82)
const C_ROW_TXT := Color(0.10, 0.13, 0.22)
const C_ROW_SEP := Color(0.64, 0.66, 0.62)       # thin row separator
const C_BAND := Color(0.14, 0.24, 0.48)          # SUBSTITUTES / RESERVES section band
const C_BAND_TXT := Color(0.88, 0.93, 1.0)

# Date synthesis. PM98 is week-based; the real header shows a full calendar date.
# Anchor: season week 1 == Saturday 9 Aug 1997 (verified: +16 weeks == Saturday
# 29 November 1997, exactly the real "Week 17" screenshot).
const _WD := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const _MON := ["", "January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]

# Home-kit crop (left 31px of the 48x64 MINIESC kit), as the other screens use.
const KIT_SRC := Rect2(0, 0, 31, 64)

static var _fonts: Dictionary = {}
static var _kits: Dictionary = {}
static var _nano_kits: Dictionary = {}
static var _panel_kits: Dictionary = {}
static var _faces: Dictionary = {}
static var _mini_faces: Dictionary = {}
static var _bg: Texture2D = null
static var _bg_dim: Texture2D = null
static var _camrol: Dictionary = {}
static var _icons: Dictionary = {}
static var _flags: Dictionary = {}
static var _mini_flags: Dictionary = {}
static var _ficha_kits: Dictionary = {}

# Fallback fine-position code per broad role, for records whose posFine is absent / out
# of range. Picks a representative central CAMROL slot: GK=1, central DF=4, central
# MF=10, central striker=9 (see docs/re/positions_re.md fine-code -> dot-x mapping).
const _CAMROL_FALLBACK := {"GK": 1, "DF": 4, "DEF": 4, "MF": 10, "MID": 10,
	"FW": 9, "FOR": 9}


# ---- pointer input -------------------------------------------------------

## True when `e` is the EMULATED mouse event Godot synthesises from a real finger tap,
## and the screen already handles `InputEventScreenTouch` itself.
##
## Measured on Godot 4.6.2 (`tests/test_pointer_dup.gd`): with the project default
## `input_devices/pointing/emulate_mouse_from_touch = true`, ONE finger press delivers
## TWO events to the same `gui_input`:
##     InputEventMouseButton pressed=true device=-1   (DEVICE_ID_EMULATION)
##     InputEventScreenTouch pressed=true device=0
## Handlers that only navigate are idempotent under that, so it stayed invisible; a
## handler that TOGGLES flips twice and lands back where it started. That is the
## 2026-07-24 owner bug "cannot change REFUSE to ACCEPT" — `TeamOfferScreen` flips the
## chip on press, so on a device it flipped to ACCEPT and straight back to REFUSE. The
## mouse-only headless `test_sell_loop` could never reproduce it (it sends one event).
##
## Every screen that handles BOTH event kinds must drop one of the pair. We drop the
## emulated mouse event (device == DEVICE_ID_EMULATION), keeping the real touch on a
## device and the real mouse on desktop.
static func is_emulated_pointer_dup(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.device == InputEvent.DEVICE_ID_EMULATION


# ---- shared assets -------------------------------------------------------

static func font(name: String) -> Font:
	if _fonts.is_empty():
		for n in ["8", "10", "12", "14", "18", "24"]:
			var p := "res://art/fonts/proman%s.fnt" % n
			if ResourceLoader.exists(p):
				_fonts[n] = load(p)
		# Futuri18 (DATA BASE PHOTOS-mode face) — a different family, keyed by full name.
		if ResourceLoader.exists("res://art/fonts/futuri18.fnt"):
			_fonts["futuri18"] = load("res://art/fonts/futuri18.fnt")
		# Calend8 (DATA BASE legend caption face) — also keyed by full name.
		if ResourceLoader.exists("res://art/fonts/calend8.fnt"):
			_fonts["calend8"] = load("res://art/fonts/calend8.fnt")
		# Calend12 (the 'Result' face) — the match-header status-plaque face.
		if ResourceLoader.exists("res://art/fonts/calend12.fnt"):
			_fonts["calend12"] = load("res://art/fonts/calend12.fnt")
	return _fonts.get(name)


## The management background texture (dark-blue marble), replacing the old stadium photo.
static func bg() -> Texture2D:
	if _bg == null and ResourceLoader.exists("res://art/screens/management_bg.png"):
		_bg = load("res://art/screens/management_bg.png")
	return _bg


static func kit(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	if not _kits.has(club_id):
		var p := "res://art/kits/%d.png" % club_id
		_kits[club_id] = load(p) if ResourceLoader.exists(p) else null
	return _kits[club_id]


## The club's NANOESC full kit (24x32 shirt+shorts, idx0 transparent) — the art the
## original SELECCION / PRESEASON panels blit (SAD-0.0-anchored vs frames 008/013).
static func nano_kit(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	if not _nano_kits.has(club_id):
		var p := "res://art/kits/nano/%d.png" % club_id
		_nano_kits[club_id] = load(p) if ResourceLoader.exists(p) else null
	return _nano_kits[club_id]


## The 24x32 FRAME-RENDERED panel kit (authentic soft shadow on the white panel —
## the original's kit-blit shadow pass is not a plain palette blit and its dither
## phase is screen-specific, so patches are baked per screen: `panel` from frame
## 008 for SELECCION, `panel13` from frame 013 for PRESEASON). Premier clubs only;
## callers fall back to nano_kit() for divisions no frame shows yet.
static func panel_kit(club_id: int, bank := "panel") -> Texture2D:
	if club_id < 0:
		return null
	var key := "%s/%d" % [bank, club_id]
	if not _panel_kits.has(key):
		var p := "res://art/kits/%s/%d.png" % [bank, club_id]
		_panel_kits[key] = load(p) if ResourceLoader.exists(p) else null
	return _panel_kits[key]


## The player's 124x182 profile photo (the original BIGFOTO mugshot), keyed by the
## EQUIPOS photoId on the player record (English squads). null when the player has no
## photoId or no bank entry -- the original drew a blank frame, so callers should too.
## Decode + the photoId->player join is documented in docs/re/faces_re.md.
static func face(photo_id) -> Texture2D:
	if photo_id == null or int(photo_id) <= 0:
		return null
	var id := int(photo_id)
	if not _faces.has(id):
		var p := "res://art/faces/%d.png" % id
		_faces[id] = load(p) if ResourceLoader.exists(p) else null
	return _faces[id]


## The player's 32x32 squad-list thumbnail (the original MINIFOTO), same photoId key.
static func mini_face(photo_id) -> Texture2D:
	if photo_id == null or int(photo_id) <= 0:
		return null
	var id := int(photo_id)
	if not _mini_faces.has(id):
		var p := "res://art/faces/mini/%d.png" % id
		_mini_faces[id] = load(p) if ResourceLoader.exists(p) else null
	return _mini_faces[id]


## The original CAMROL position icon (25x14 top-down pitch + role dot) for a fine
## position code 1..18 (the EQUIPOS demarcación, docs/re/positions_re.md). Cached.
static func camrol(pos_fine: int) -> Texture2D:
	var n: int = clampi(pos_fine, 1, 18)
	if not _camrol.has(n):
		var p := "res://art/icons/camrol/camrol%02d.png" % n
		_camrol[n] = load(p) if ResourceLoader.exists(p) else null
	return _camrol[n]


## The player's nationality FLAG (the 30x20 BANDERAS waving flag) for a country code
## (the EQUIPOS/PAISES index on the player's `flagCode`, baked by tools/re/export_flags.py).
## Cached; null when the code has no flag so callers keep their text-only fallback.
static func flag(code) -> Texture2D:
	if code == null or int(code) < 0:
		return null
	var n := int(code)
	if not _flags.has(n):
		var p := "res://art/flags/flag_%03d.png" % n
		_flags[n] = load(p) if ResourceLoader.exists(p) else null
	return _flags[n]


## A flat management-UI glyph baked by tools/re/export_icons.py (the FLECHA / ARROW /
## SECRETARIO / OFERTAS sprites), e.g. "fin_up", "scroll_down_on", "scout". Cached;
## returns null if the PNG is missing so callers keep their text fallback.
static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		var p := "res://art/icons/%s.png" % name
		_icons[name] = load(p) if ResourceLoader.exists(p) else null
	return _icons[name]


## The 14x10 MINIBAND mini flag for a country code (same PAISES index as flag();
## baked by tools/re/export_flags.py). This is the flag the TEAM OFFER card blits
## on its NATIONALITY band and club-offer rows (SAD 0.0 vs run-3 frame 086).
static func mini_flag(code) -> Texture2D:
	if code == null or int(code) < 0:
		return null
	var n := int(code)
	if not _mini_flags.has(n):
		var p := "res://art/flags/mini_%03d.png" % n
		_mini_flags[n] = load(p) if ResourceLoader.exists(p) else null
	return _mini_flags[n]


## The 21x21 FRAME-RENDERED player-card kit patch (the FICHA/TEAM OFFER kit blit
## composes a soft shadow that is not a plain palette blit — panel-kit precedent).
## Only clubs a walkthrough frame shows carry a patch (Man Utd today); callers
## fall back to scaled nano_kit() art for the rest.
static func ficha_kit(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	if not _ficha_kits.has(club_id):
		var p := "res://art/kits/ficha/%d.png" % club_id
		_ficha_kits[club_id] = load(p) if ResourceLoader.exists(p) else null
	return _ficha_kits[club_id]


## Draw a flat icon fitted (aspect-preserved) and centred in a cell. Returns true if a
## texture was drawn, so the caller can fall back to a drawn glyph when art is absent.
static func draw_icon(ci: CanvasItem, name: String, r: Rect2) -> bool:
	var tex := icon(name)
	if tex == null:
		return false
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var s: float = minf(r.size.x / tw, r.size.y / th)
	var w := tw * s
	var h := th * s
	ci.draw_texture_rect(tex, Rect2(r.position.x + (r.size.x - w) * 0.5,
		r.position.y + (r.size.y - h) * 0.5, w, h), false)
	return true


## Draw a player's CAMROL role icon centred in a cell. Uses posFine when present,
## else falls back to a representative slot for the broad position. Returns true if
## an icon was drawn (caller can paint a colour-tag fallback otherwise).
static func draw_role_icon(ci: CanvasItem, r: Rect2, pos_fine: int, broad_pos := "") -> bool:
	var fine := pos_fine
	if fine < 1 or fine > 18:
		fine = int(_CAMROL_FALLBACK.get(broad_pos.to_upper(), 0))
	if fine < 1:
		return false
	var tex := camrol(fine)
	if tex == null:
		return false
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var s: float = minf(r.size.x / tw, r.size.y / th)
	var w := tw * s
	var h := th * s
	ci.draw_texture_rect(tex, Rect2(r.position.x + (r.size.x - w) * 0.5,
		r.position.y + (r.size.y - h) * 0.5, w, h), false)
	return true


# ---- low-level drawing helpers -------------------------------------------

# Modal-dim mode (the hub behind the PMAlert box): while on, every colour and
# kit texture these helpers emit is passed through the exact palette-dim LUT
# (PMAlert.dim_color / dim_texture). MenuScreen brackets its draw_header call
# with set_dim; nothing else ever turns it on.
static var _dim_on := false

static func set_dim(on: bool) -> void:
	_dim_on = on

static func _dc(col: Color) -> Color:
	return PMAlert.dim_color(col) if _dim_on else col

## Public LUT-dim accessor for screens that draw raw rects while a modal dims
## them (SquadScreen under the FICHA card — the 081-vs-082 walkthrough pair
## proves the whole host screen palette-dims through the SAME alert LUT).
static func dim_col(col: Color) -> Color:
	return _dc(col)


## Draw a string. align: 0 left (x = left), 1 centre (in box_w starting at x), 2 right (x = right edge).
static func text(ci: CanvasItem, f: Font, x: float, y_top: float, s: String,
		col: Color, sz: int, align := 0, box_w := 0.0) -> void:
	if f == null:
		return
	col = _dc(col)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	# Auto-fit: when a box width is given and the string overflows it, shrink the font
	# so the WHOLE label stays inside its box. Replaces the old fixed-width clipping that
	# chopped long titles / league names ("Premier League" -> "Premier L") on every screen.
	if box_w > 0.0 and w > box_w:
		sz = maxi(6, int(floor(sz * box_w / w)))
		w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if align == 1:
		px = x + (box_w - w) * 0.5
	elif align == 2:
		px = x - w
	ci.draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## PM98's rendered name casing. Since the 2026-07-06 exact-cipher rebuild
## (XOR 0x61, tools/re/equipos_parse.py) game_db stores the TRUE mixed-case
## strings the original renders ("Van der Gouw" frame 077, "F.C. Barcelona"
## frame 015) — those pass through UNCHANGED. The title-case reconstruction
## below remains for single-case input only: talent-pool / youth / sample_db
## names still arrive UPPERCASE (the old approximate cipher was 5-bit
## single-case; the shim reproduces the frame-verified casing for them).
const _NAME_PARTICLES := ["der", "de", "la", "le", "di", "da", "van", "von", "den", "dos"]

static func title_case_name(s: String) -> String:
	if s != s.to_upper():
		return s  # already mixed case == the exact stored form; never re-case
	var words := s.split(" ", false)
	var out := PackedStringArray()
	for i in words.size():
		var w := str(words[i]).to_lower()
		if i > 0 and w in _NAME_PARTICLES:
			out.append(w)
		elif w.begins_with("mc") and w.length() > 2:
			# The real screens keep the inner capital ("McClair", alert frame 093).
			out.append("Mc" + w.substr(2).capitalize())
		elif w.replace(".", "").length() <= w.count("."):
			# dotted abbreviation ("F.C.", "F.") — stays uppercase ("F.C.
			# Barcelona" on the VIEW RIVAL club plate, frame 015).
			out.append(str(words[i]).to_upper())
		else:
			out.append(w.capitalize())
	return " ".join(out)


## The card-header name form on the FICHA-family cards (TEAM OFFER / MAKE-OFFER /
## PLAYER INFORMATION): given names Title-case + the SURNAME upper, where the
## surname is the record's display `name` field — it can be multi-word.
## Frame truth: "Ben THORNLEY" (086), "Scott TAYLOR" (101), "William (Billy)
## McKINLAY" (owner capture), "Raimond VAN DER GOUW" (081, compound surname),
## "Ole Gunnar SOLSKJAER" (084, two given names). Mc prefix keeps its inner
## capital. Splitting on the last word alone breaks the 081/084 forms — the
## surname suffix rule replaced it 2026-07-03.
static func card_name(p: Dictionary) -> String:
	var legal := str(p.get("legalName", "")).strip_edges()
	if legal == "":
		return str(p.get("name", "?"))
	# A MIXED-CASE legalName is already the string the original renders — the exact-cipher
	# rebuild stores the game's own casing, surname uppercased in place. Print it verbatim.
	# Witnessed five times: "Alessandro DEL PIERO" and "Iván DE LA PEÑA López" on the ficha
	# (refrun p0242 / p0282), "Patrick KLUIVERT", "Joseba ETXEBERRIA Lizardi" and
	# "Alessandro NESTA" in the SCOUT rollover bar (p0241 / p0279 / p0283). The
	# reconstruction below cannot produce the middle-surname forms at all — it uppercases the
	# LAST word, so it printed "Iván De La Peña LÓPEZ" — and 1,272 of the 9,547 shipped names
	# have a surname that is not the trailing run. 9,446 names are mixed-case and take this
	# path; the 97 all-uppercase ones (talent pool, youth, sample_db) still need the rebuild.
	if legal != legal.to_upper() and legal != legal.to_lower():
		return legal
	var surname := str(p.get("name", "")).strip_edges().to_upper()
	var given := ""
	if surname != "" and legal.to_upper().ends_with(surname):
		given = legal.substr(0, legal.length() - surname.length()).strip_edges()
	else:
		var ws := legal.split(" ", false)
		surname = str(ws[ws.size() - 1])
		ws.remove_at(ws.size() - 1)
		given = " ".join(ws)
	if surname.begins_with("MC") and surname.length() > 2:
		surname = "Mc" + surname.substr(2)
	var out := PackedStringArray()
	for w in given.split(" ", false):
		out.append(str(w).to_lower().capitalize())
	if out.is_empty():
		return surname
	return " ".join(out) + " " + surname


## A beveled rectangle: solid base, light top/left edge, dark bottom/right edge.
static func bevel(ci: CanvasItem, r: Rect2, base: Color, hi: Color, lo: Color, bw := 1.0) -> void:
	base = _dc(base)
	hi = _dc(hi)
	lo = _dc(lo)
	ci.draw_rect(r, base, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, bw), hi, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, bw, r.size.y), hi, true)
	ci.draw_rect(Rect2(r.position.x, r.end.y - bw, r.size.x, bw), lo, true)
	ci.draw_rect(Rect2(r.end.x - bw, r.position.y, bw, r.size.y), lo, true)


## Fill the 640x480 content area with the management background (caller has already set
## the design-space transform). Falls back to a flat navy if the texture is missing.
## Under a modal dim (set_dim), the pre-baked exact palette-dim of the same texture is
## used (management_bg_dim.png, baked by tools/re/build_ficha_chrome_from_frames.py —
## the MenuScreen menu_bg_dim precedent), avoiding a per-pixel runtime pass.
static func draw_bg(ci: CanvasItem) -> void:
	var t := bg()
	if _dim_on:
		if _bg_dim == null and ResourceLoader.exists("res://art/screens/ficha/management_bg_dim.png"):
			_bg_dim = load("res://art/screens/ficha/management_bg_dim.png")
		if _bg_dim != null:
			t = _bg_dim
		elif t != null:
			t = PMAlert.dim_texture(t)
	if t != null:
		ci.draw_texture_rect(t, Rect2(0, 0, W, H), false)
	else:
		ci.draw_rect(Rect2(0, 0, W, H), _dc(Color(0.10, 0.18, 0.40)), true)


## The managed club's home kit (left crop) fitted into a box, aspect-preserved.
static func draw_crest(ci: CanvasItem, club_id: int, r: Rect2) -> void:
	var tex := kit(club_id)
	if tex == null:
		return
	if _dim_on:
		tex = PMAlert.dim_texture(tex)
	var sc: float = min(r.size.x / KIT_SRC.size.x, r.size.y / KIT_SRC.size.y)
	var w := KIT_SRC.size.x * sc
	var h := KIT_SRC.size.y * sc
	ci.draw_texture_rect_region(tex,
		Rect2(r.position.x + (r.size.x - w) * 0.5, r.position.y + (r.size.y - h) * 0.5, w, h),
		KIT_SRC)


# ---- white data-table chrome (LINE-UP / SQUAD / TRANSFER) ----------------

## A white/cream table panel with a beveled white border.
static func draw_table_panel(ci: CanvasItem, r: Rect2) -> void:
	bevel(ci, r, C_TBL, C_TBL_HI, C_TBL_LO, 2.0)


## A blue column-header strip; the caller draws the column labels in C_TBL_HDR_TXT.
static func draw_col_header(ci: CanvasItem, r: Rect2) -> void:
	bevel(ci, r, C_TBL_HDR, C_TBL_HDR.lightened(0.2), C_TBL_HDR.darkened(0.4))


## An alternating cream table row with a thin bottom separator; highlight tints it.
static func draw_row(ci: CanvasItem, r: Rect2, idx: int, highlight := false) -> void:
	ci.draw_rect(r, C_ROW_LIGHT if idx % 2 == 0 else C_ROW_DARK, true)
	if highlight:
		ci.draw_rect(r, Color(0.20, 0.42, 0.86, 0.22), true)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), C_ROW_SEP, true)


## A dark-blue section band (SUBSTITUTES / RESERVES) with a centred label.
static func draw_band(ci: CanvasItem, r: Rect2, label: String) -> void:
	bevel(ci, r, C_BAND, C_BAND.lightened(0.25), C_BAND.darkened(0.4))
	text(ci, font("12"), r.position.x, r.position.y + (r.size.y - 13) * 0.5, label,
		C_BAND_TXT, 12, 1, r.size.x)


# ---- star rating (replaces the leaked CA64/CA96 integers, handoff root cause 4) ----

## Draw `rating` filled gold stars out of `count`, the rest grey, left-to-right from x.
static func draw_stars(ci: CanvasItem, x: float, y: float, rating: float, sz: float, count := 5) -> void:
	var filled := int(round(clampf(rating, 0.0, float(count))))
	for i in count:
		_star(ci, x + i * (sz + 1.0) + sz * 0.5, y + sz * 0.5, sz * 0.5,
			C_GOLD if i < filled else C_STAR_OFF)


static func _star(ci: CanvasItem, cx: float, cy: float, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var ang := -PI / 2.0 + k * PI / 5.0
		var rr := rad if k % 2 == 0 else rad * 0.42
		pts.append(Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr))
	ci.draw_colored_polygon(pts, col)


# ---- date --------------------------------------------------------------

## {wd, day, mon, year} for the displayed (1-based) week of a "YYYY-YY" season.
static func date_parts(season: String, week_disp: int) -> Dictionary:
	var start_year := 1997
	if season.length() >= 4 and season.substr(0, 4).is_valid_int():
		start_year = int(season.substr(0, 4))
	var t0 := Time.get_unix_time_from_datetime_dict(
		{"year": start_year, "month": 8, "day": 9, "hour": 12, "minute": 0, "second": 0})
	var t := int(t0) + (maxi(week_disp, 1) - 1) * 7 * 86400
	var d := Time.get_datetime_dict_from_unix_time(t)
	return {"wd": _WD[int(d.get("weekday", 6))], "day": int(d.get("day", 9)),
		"mon": _MON[int(d.get("month", 8))], "year": int(d.get("year", start_year))}


# ---- the frame-baked MATCH-CONTEXT header (barra band y0..61) -------------
# Baked by tools/re/build_match_header_from_frames.py; every anchor below is
# the fitted, XOR=0-asserted value from app/art/screens/header/header_samples
# .json (binding frame 014_162413 + 5 witness frames, recomposed pixel-exact).
# Text centring is the GDI rule px = (S - extent) / 2 (floor); extents come
# from the exported WINFONTS BMFonts (advance == glyph width, no kerning).

const HDR_NAME_TOP := {"S": 107, "y": 17}    # PROMAN8 black on (180,200,220)
const HDR_NAME_BOT := {"S": 108, "y": 35}    # PROMAN8 white on (80,100,120)
const HDR_CAL_S := 968                        # PROMAN8; weekday/day/month/year
const HDR_CAL_LINES := [
	{"key": "weekday", "y": 15, "ink": Color(0, 0, 0)},
	{"key": "day", "y": 26, "ink": Color(1, 0, 0)},
	{"key": "month", "y": 35, "ink": Color(0, 0, 0)},
	{"key": "year", "y": 46, "ink": Color8(42, 95, 170)},
]
const HDR_STAT_S := 1163                      # Result face (calend12 export)
const HDR_STAT_TOP_Y := 14                    # black on (127,159,85)
const HDR_STAT_BOT_Y := 32                    # white on (85,95,0)
const HDR_KIT_HOME := Vector2(116, 10)        # RIDIESC 17x20, 1:1, no shadow
const HDR_KIT_AWAY := Vector2(116, 30)
const HDR_MGR_PATCH_XY := Vector2(108, 8)     # 058 manager-mode panel patch
const HDR_MGR_NANO_XY := Vector2(114, 15)     # nano fallback for un-walked clubs

static var _hdr_band: Texture2D = null
static var _hdr_titles: Dictionary = {}
static var _hdr_ridi: Dictionary = {}
static var _hdr_mgr_patch: Texture2D = null

# title sprite anchors (cut offsets recorded by the bake)
const _HDR_TITLE_XY := {"tactics": Vector2(254, 22), "viewrival": Vector2(240, 22),
	"lineup": Vector2(254, 22), "mtm": Vector2(173, 22)}


static func ridi_kit(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	if not _hdr_ridi.has(club_id):
		var p := "res://art/kits/ridi/%d.png" % club_id
		_hdr_ridi[club_id] = load(p) if ResourceLoader.exists(p) else null
	return _hdr_ridi[club_id]


static func _hdr_title(key: String) -> Texture2D:
	if not _hdr_titles.has(key):
		var p := "res://art/screens/header/title_%s.png" % key
		_hdr_titles[key] = load(p) if ResourceLoader.exists(p) else null
	return _hdr_titles[key]


## GDI-centred single-line text: px = (S - extent) div 2, glyph canvas top at y.
static func _hdr_text(ci: CanvasItem, f: Font, sz: int, s: String, S: int,
		y: int, ink: Color) -> void:
	if f == null or s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (S - w) / 2
	ci.draw_string(f, Vector2(px, y + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)


## The match-context header: baked band + club/manager plaques, kit panel,
## calendar and status texts, and the baked title sprite. `h` keys:
##   mode "fixture"|"manager", top, bottom, home_id, away_id (fixture),
##   club_id (manager), weekday, day, month, year, status_top, status_bottom.
## Un-walked gaps (documented in the bake): manager-mode kits for clubs other
## than Man Utd fall back to the shadowless NANOESC blit; in-season status
## strings are un-walked (only Preseason/Preparation appear in the frames).
static func draw_match_header(ci: CanvasItem, title_key: String, h: Dictionary) -> void:
	if _hdr_band == null and ResourceLoader.exists("res://art/screens/header/band.png"):
		_hdr_band = load("res://art/screens/header/band.png")
	if _hdr_band != null:
		ci.draw_texture(_hdr_band, Vector2.ZERO)
	var f8 := font("8")
	var fres := font("calend12")
	_hdr_text(ci, f8, 11, str(h.get("top", "")), HDR_NAME_TOP["S"],
		HDR_NAME_TOP["y"], Color(0, 0, 0))
	_hdr_text(ci, f8, 11, str(h.get("bottom", "")), HDR_NAME_BOT["S"],
		HDR_NAME_BOT["y"], Color(1, 1, 1))
	if str(h.get("mode", "fixture")) == "manager":
		if _hdr_mgr_patch == null and int(h.get("club_id", -1)) == 40 \
				and ResourceLoader.exists("res://art/kits/header/40.png"):
			_hdr_mgr_patch = load("res://art/kits/header/40.png")
		if int(h.get("club_id", -1)) == 40 and _hdr_mgr_patch != null:
			ci.draw_texture(_hdr_mgr_patch, HDR_MGR_PATCH_XY)
		else:
			var nk := nano_kit(int(h.get("club_id", -1)))
			if nk != null:
				ci.draw_texture(nk, HDR_MGR_NANO_XY)
	else:
		for pair in [[int(h.get("home_id", -1)), HDR_KIT_HOME],
				[int(h.get("away_id", -1)), HDR_KIT_AWAY]]:
			var kt := ridi_kit(pair[0])
			if kt != null:
				ci.draw_texture(kt, pair[1])
	for line in HDR_CAL_LINES:
		_hdr_text(ci, f8, 11, str(h.get(line["key"], "")), HDR_CAL_S,
			line["y"], line["ink"])
	_hdr_text(ci, fres, 15, str(h.get("status_top", "Preseason")), HDR_STAT_S,
		HDR_STAT_TOP_Y, Color(0, 0, 0))
	_hdr_text(ci, fres, 15, str(h.get("status_bottom", "Preparation")), HDR_STAT_S,
		HDR_STAT_BOT_Y, Color(1, 1, 1))
	var tt := _hdr_title(title_key)
	if tt != null:
		ci.draw_texture(tt, _HDR_TITLE_XY.get(title_key, Vector2.ZERO))


# ---- the shared header ---------------------------------------------------

# Frame-baked top-right chrome (tools/re/build_header_topright_from_frames.py;
# binding frame 016_162419 + the 2026-07-12 week-1 capture
# hub_week1_inseason_bands.png): the spiral-bound white CALENDAR SHEET and the
# lavender plaque holding two green bands + the football. Replaces the old
# procedural grey bevels (the reported "grey bar over the calendar" defect).
static var _hdr_sheet: Texture2D = null
static var _hdr_plaque: Texture2D = null
static var _hdr_ident: Texture2D = null
## Career phase for the plaque bands: "" = in season (league / Week N — witnessed
## "Premier"/"Week 1"), "preseason" = the witnessed "Preseason"/"Preparation".
static var header_phase := ""
## Optional date override for the calendar sheet (date_from_iso shape) — the
## original shows the pending FRIENDLY's date during preseason, not the week date.
static var header_date: Dictionary = {}

# Frame-sampled inks (app/data/header_chrome_samples.json)
const C_SHEET_INK := Color8(0, 0, 0)
const C_SHEET_DAY := Color8(255, 0, 0)
const C_SHEET_YEAR := Color8(42, 95, 170)
const C_BAND1_INK := Color8(0, 0, 0)
const C_BAND2_INK := Color8(255, 255, 255)


## "1997-08-01" -> the date_parts dict shape (for the preseason friendly dates).
static func date_from_iso(iso: String) -> Dictionary:
	var p := iso.split("-")
	if p.size() != 3:
		return {}
	var t := Time.get_unix_time_from_datetime_dict({"year": int(p[0]), "month": int(p[1]),
		"day": int(p[2]), "hour": 12, "minute": 0, "second": 0})
	var d := Time.get_datetime_dict_from_unix_time(int(t))
	return {"wd": _WD[int(d.get("weekday", 6))], "day": int(d.get("day", 1)),
		"mon": _MON[int(d.get("month", 8))], "year": int(d.get("year", 1997))}


## The top plaque row every real management screen shares: a full-width blue title bar
## with the screen name centred, the manager+club plaque (left), the spiral calendar
## sheet (centre-right) and the banded lavender plaque + football (right).
## week_disp is the 1-based week (Week 17); pass <=0 to omit the date + week.
static func draw_header(ci: CanvasItem, title: String, manager: String, club: String,
		league: String, season: String, week_disp: int, club_id := -1) -> void:
	var f12 := font("12")
	var f18 := font("18")

	# Full-width title bar behind everything.
	bevel(ci, Rect2(4, 10, W - 8, 28), C_BAR, C_BAR_HI, C_BAR_LO)
	text(ci, f18, 156, 15, title.to_upper(), C_TITLE, 19, 1, 292)

	# Manager / club identity block (left): the real chrome cut from the hub
	# frame (orig/73, tools/re/build_hub_chrome_from_frames.py) — pale name bar
	# (dark ink) over the dark club bar (white ink), kit in the white box.
	# Witnessed ink centres: name x54, club x58 (both proman10).
	if _hdr_ident == null and ResourceLoader.exists("res://art/screens/hub/ident_block.png"):
		_hdr_ident = load("res://art/screens/hub/ident_block.png")
	if _hdr_ident != null:
		ci.draw_texture(_hdr_ident, Vector2(0, 4))
		draw_ident_texts(ci, manager, club, club_id)
	else:
		var mp := Rect2(6, 4, 150, 38)
		bevel(ci, mp, C_PLAQUE, C_PLAQUE_HI, C_PLAQUE_LO)
		var tw := mp.size.x - 26   # leave room for the crest at the right edge
		if manager != "":
			text(ci, f12, mp.position.x, 7, manager, C_PLAQUE_TXT, 12, 1, tw)
			text(ci, f12, mp.position.x, 22, club, C_PLAQUE_TXT, 12, 1, tw)
		else:
			text(ci, f12, mp.position.x, 14, club, C_PLAQUE_TXT, 13, 1, tw)
		if club_id >= 0:
			draw_crest(ci, club_id, Rect2(mp.end.x - 24, 5, 20, 36))

	if _hdr_sheet == null and ResourceLoader.exists("res://art/screens/header/cal_sheet.png"):
		_hdr_sheet = load("res://art/screens/header/cal_sheet.png")
	if _hdr_plaque == null and ResourceLoader.exists("res://art/screens/header/plaque_right.png"):
		_hdr_plaque = load("res://art/screens/header/plaque_right.png")

	if week_disp > 0 and _hdr_sheet != null:
		# Real spiral calendar sheet (frame 016_162419); the sheet overlaps the
		# barra like the original — no plaque box behind it.
		ci.draw_texture(_hdr_sheet, Vector2(445, 6))
	if _hdr_plaque != null:
		# The banded lavender plaque + football (frame 016_162419).
		ci.draw_texture(_hdr_plaque, Vector2(529, 4))
	draw_sheet_band_texts(ci, league, season, week_disp)


## The live header TEXTS alone — calendar-sheet date stack + plaque band labels.
## Chrome-baked screens (the hub) call this directly over their real baked
## sheet/plaque; draw_header lays the sprites first for everything else.
## All metrics frame-measured off orig/73: date stack cx 483 (proman8, weekday
## baseline 24 / red day 35 / month 44 / blue year 55), band labels cx 577
## (proman10, "Premier" black baseline 26, "Week 1" white baseline 44). During
## preseason the date is the pending friendly's (header_date), as witnessed.
static func draw_sheet_band_texts(ci: CanvasItem, league: String, season: String,
		week_disp: int) -> void:
	var f8 := font("8")
	if week_disp > 0:
		var d := header_date if not header_date.is_empty() else date_parts(season, week_disp)
		_ctr_txt(ci, f8, 483, 24, str(d["wd"]), C_SHEET_INK, 11)
		_ctr_txt(ci, f8, 483, 35, str(d["day"]), C_SHEET_DAY, 11)
		_ctr_txt(ci, f8, 483, 44, str(d["mon"]), C_SHEET_INK, 11)
		_ctr_txt(ci, f8, 483, 55, str(d["year"]), C_SHEET_YEAR, 11)
	var top_txt := _band_league(league)
	if header_phase == "preseason":
		top_txt = "Preseason"
	elif header_phase == "charity":
		top_txt = "Charity"       # the Charity Shield fixture plaque (witnessed "Charity"/"Final")
	var bot_txt := ""
	if header_phase == "preseason":
		bot_txt = "Preparation"
	elif header_phase == "charity":
		bot_txt = "Final"
	elif week_disp > 0:
		bot_txt = "Week %d" % week_disp
	_band_txt(ci, 26, top_txt, C_BAND1_INK)
	if bot_txt != "":
		_band_txt(ci, 44, bot_txt, C_BAND2_INK)


## Band labels use the calend12 "Result" face (mask-matched 0px against
## orig/73 "Premier"), centred on x580.
static func _band_txt(ci: CanvasItem, baseline: int, t: String, col: Color) -> void:
	var f := font("calend12")
	if f == null or t == "":
		return
	var w := int(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x)
	ci.draw_string(f, Vector2(580 - int((w - 2) * 0.5), baseline), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, _dc(col))


## The identity block's live texts + kit (the block chrome itself is baked on
## the hub, blitted by draw_header everywhere else). Name bar dark ink cx 54,
## club bar white cx 58, kit in the white box (all frame-measured, proman10).
static func draw_ident_texts(ci: CanvasItem, manager: String, club: String, club_id: int) -> void:
	# proman8, both bars centred on x53 (mask-matched 0px vs orig/73).
	var f8 := font("8")
	if manager != "":
		_ctr_txt(ci, f8, 53, 26, manager, C_BAND1_INK, 11)
	_ctr_txt(ci, f8, 53, 44, club, C_BAND2_INK, 11)
	if club_id >= 0:
		# The original's box-filling kit render is un-extracted; the 24x32
		# frame-rendered panel kit centred in the box comes closest (flagged;
		# kits-sheet stretch as the non-Premier fallback).
		var pk := panel_kit(club_id)
		if pk != null:
			ci.draw_texture(pk, Vector2(114, 15))
		else:
			var tex := kit(club_id)
			if tex != null:
				ci.draw_texture_rect_region(tex, Rect2(114, 15, 32, 32), Rect2(0, 0, 31, 64))


## Witnessed centring (px = cx - int((adv-1)/2); orig/73 "mwm" -> x38,
## "Bolton W" -> x28, "Saturday" -> x457, "Premier" -> x549).
static func _ctr_txt(ci: CanvasItem, f: Font, cx: int, baseline: int, t: String,
		col: Color, sz: int) -> void:
	if f == null or t == "":
		return
	var w := int(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x) - 1
	ci.draw_string(f, Vector2(cx - int(w * 0.5), baseline), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, _dc(col))


## The band's short division name: "Premier" witnessed on the week-1 hub; the
## lower divisions follow the game's own division labels (PREMIER/FIRST/SECOND/
## THIRD, witnessed on the preseason picker buttons). Foreign names pass through.
static func _band_league(league: String) -> String:
	match league:
		"Premier League": return "Premier"
		"Division One": return "First"
		"Division Two": return "Second"
		"Division Three": return "Third"
	return league


## A tiny gold trophy glyph (bowl + handles + stem + base), top-left at (x,y), height ~h.
static func _trophy(ci: CanvasItem, x: float, y: float, h: float) -> void:
	var gold := _dc(C_GOLD)
	var gold_lo := _dc(C_GOLD_LO)
	var w := h * 0.7
	# bowl (tapered)
	var bowl := PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w * 0.72, y + h * 0.5), Vector2(x + w * 0.28, y + h * 0.5)])
	ci.draw_colored_polygon(bowl, gold)
	# handles
	ci.draw_arc(Vector2(x, y + h * 0.14), h * 0.2, -PI * 0.5, PI * 0.5, 6, gold_lo, 1.5)
	ci.draw_arc(Vector2(x + w, y + h * 0.14), h * 0.2, PI * 0.5, PI * 1.5, 6, gold_lo, 1.5)
	# stem + base
	ci.draw_rect(Rect2(x + w * 0.42, y + h * 0.5, w * 0.16, h * 0.28), gold, true)
	ci.draw_rect(Rect2(x + w * 0.18, y + h * 0.78, w * 0.64, h * 0.22), gold, true)
	ci.draw_rect(Rect2(x + w * 0.18, y + h * 0.78, w * 0.64, h * 0.22), gold_lo, false, 1.0)
