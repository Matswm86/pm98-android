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
static var _bg: Texture2D = null


# ---- shared assets -------------------------------------------------------

static func font(name: String) -> Font:
	if _fonts.is_empty():
		for n in ["8", "10", "12", "14", "18", "24"]:
			var p := "res://art/fonts/proman%s.fnt" % n
			if ResourceLoader.exists(p):
				_fonts[n] = load(p)
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


# ---- low-level drawing helpers -------------------------------------------

## Draw a string. align: 0 left (x = left), 1 centre (in box_w starting at x), 2 right (x = right edge).
static func text(ci: CanvasItem, f: Font, x: float, y_top: float, s: String,
		col: Color, sz: int, align := 0, box_w := 0.0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if align == 1:
		px = x + (box_w - w) * 0.5
	elif align == 2:
		px = x - w
	ci.draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## A beveled rectangle: solid base, light top/left edge, dark bottom/right edge.
static func bevel(ci: CanvasItem, r: Rect2, base: Color, hi: Color, lo: Color, bw := 1.0) -> void:
	ci.draw_rect(r, base, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, bw), hi, true)
	ci.draw_rect(Rect2(r.position.x, r.position.y, bw, r.size.y), hi, true)
	ci.draw_rect(Rect2(r.position.x, r.end.y - bw, r.size.x, bw), lo, true)
	ci.draw_rect(Rect2(r.end.x - bw, r.position.y, bw, r.size.y), lo, true)


## Fill the 640x480 content area with the management background (caller has already set
## the design-space transform). Falls back to a flat navy if the texture is missing.
static func draw_bg(ci: CanvasItem) -> void:
	var t := bg()
	if t != null:
		ci.draw_texture_rect(t, Rect2(0, 0, W, H), false)
	else:
		ci.draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)


## The managed club's home kit (left crop) fitted into a box, aspect-preserved.
static func draw_crest(ci: CanvasItem, club_id: int, r: Rect2) -> void:
	var tex := kit(club_id)
	if tex == null:
		return
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


# ---- the shared header ---------------------------------------------------

## The top plaque row every real management screen shares: a full-width blue title bar
## with the screen name centred, the manager+club plaque (left), the white calendar
## plaque (centre-right) and the green league/week plaque + trophy (right).
## week_disp is the 1-based week (Week 17); pass <=0 to omit the date + week.
static func draw_header(ci: CanvasItem, title: String, manager: String, club: String,
		league: String, season: String, week_disp: int, club_id := -1) -> void:
	var f8 := font("8")
	var f10 := font("10")
	var f12 := font("12")
	var f18 := font("18")

	# Full-width title bar behind everything.
	bevel(ci, Rect2(4, 10, W - 8, 28), C_BAR, C_BAR_HI, C_BAR_LO)
	text(ci, f18, 156, 15, title.to_upper(), C_TITLE, 19, 1, 292)

	# Manager / club plaque (left), with the club crest at its right edge.
	var mp := Rect2(6, 4, 150, 38)
	bevel(ci, mp, C_PLAQUE, C_PLAQUE_HI, C_PLAQUE_LO)
	var tw := mp.size.x - 26   # leave room for the crest at the right edge
	if manager != "":
		text(ci, f12, mp.position.x, 7, manager.substr(0, 16), C_PLAQUE_TXT, 12, 1, tw)
		text(ci, f12, mp.position.x, 22, club.substr(0, 16), C_PLAQUE_TXT, 12, 1, tw)
	else:
		text(ci, f12, mp.position.x, 14, club.substr(0, 16), C_PLAQUE_TXT, 13, 1, tw)
	if club_id >= 0:
		draw_crest(ci, club_id, Rect2(mp.end.x - 24, 5, 20, 36))

	if week_disp > 0:
		# White calendar plaque (centre-right): weekday / big red day / month / year.
		var d := date_parts(season, week_disp)
		var dp := Rect2(446, 2, 88, 42)
		bevel(ci, dp, C_DATE_BG, C_DATE_HI, C_DATE_LO)
		text(ci, f8, dp.position.x, 4, str(d["wd"]), C_DATE_TXT, 9, 1, dp.size.x)
		text(ci, f12, dp.position.x, 13, str(d["day"]), C_DATE_DAY, 14, 1, dp.size.x)
		text(ci, f8, dp.position.x, 28, str(d["mon"]), C_DATE_TXT, 9, 1, dp.size.x)
		text(ci, f8, dp.position.x, 37, str(d["year"]), C_DATE_TXT, 9, 1, dp.size.x)

	# Green league / week plaque (right) with a small gold trophy.
	var lp := Rect2(538, 2, 96, 42)
	bevel(ci, lp, C_LEAGUE, C_LEAGUE_HI, C_LEAGUE_LO)
	text(ci, f10, lp.position.x + 4, 8, league.substr(0, 9), C_LEAGUE_TXT, 11)
	if week_disp > 0:
		text(ci, f10, lp.position.x + 4, 26, "Week %d" % week_disp, C_LEAGUE_TXT, 11)
	_trophy(ci, lp.end.x - 18, 10, 13)


## A tiny gold trophy glyph (bowl + handles + stem + base), top-left at (x,y), height ~h.
static func _trophy(ci: CanvasItem, x: float, y: float, h: float) -> void:
	var w := h * 0.7
	# bowl (tapered)
	var bowl := PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w * 0.72, y + h * 0.5), Vector2(x + w * 0.28, y + h * 0.5)])
	ci.draw_colored_polygon(bowl, C_GOLD)
	# handles
	ci.draw_arc(Vector2(x, y + h * 0.14), h * 0.2, -PI * 0.5, PI * 0.5, 6, C_GOLD_LO, 1.5)
	ci.draw_arc(Vector2(x + w, y + h * 0.14), h * 0.2, PI * 0.5, PI * 1.5, 6, C_GOLD_LO, 1.5)
	# stem + base
	ci.draw_rect(Rect2(x + w * 0.42, y + h * 0.5, w * 0.16, h * 0.28), C_GOLD, true)
	ci.draw_rect(Rect2(x + w * 0.18, y + h * 0.78, w * 0.64, h * 0.22), C_GOLD, true)
	ci.draw_rect(Rect2(x + w * 0.18, y + h * 0.78, w * 0.64, h * 0.22), C_GOLD_LO, false, 1.0)
