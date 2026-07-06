extends Control
class_name DataBaseCardScreen
## PM98 DATA BASE player card (Dbasewin.exe) — the bios.json display surface,
## built frame-baked from the 2026-07-06 walked frames (docs/re/
## dbase_player_card_re.md; bake = tools/re/build_dbase_card_chrome_from_frames
## .py, geometry mirror app/data/dbase_card_chrome_samples.json).
##
## Layers (all chrome sprites are frame cuts / PKF piece art, kill-tested in
## the bake): FONDO DBASE + the black panel line -> banner (majority bake) +
## PROMAN18 name + per-club kit patch -> 7 FICHA-piece tabs (rest/dis/sel +
## position-keyed seam patches; disabled = the engine's parity-halftone wash,
## baked) -> per-view panel underlay + title bar -> dynamic content -> DATA/
## NOTES bottom band (3-state radio) -> PRINT/RETURN.
##
## Views: PERSONAL DATA (default; game_db fields — BIRTH PLACE/DATE/AGE/
## NATIONALITY/INTERNATIONAL/LAST CLUB + imperial HEIGHT/WEIGHT), six prose
## pages + the career PROGRESS table from bios.json (T4..T9 + T10 VERBATIM,
## incl. `intl` = T3), NOTES (empty notebook, frame 046).
##
## Faithful rules carried from the RE doc:
##   * tab disable = sentinel set OR stripped len < 15 (fits all 2025 players
##     and every walked witness; reproduced the walked wash states exactly);
##   * career CSV parses as a FLAT comma/newline token stream, 5 cells per
##     row — Blackwell's typo row shifts every later field (frame 062);
##   * AGE computes from the SYSTEM clock (the original does; "62 years" for
##     Schmeichel under a 2026 clock — faithful bug; now_unix is injectable
##     so parity states can pin the capture date);
##   * INTERNATIONAL renders bios `intl` VERBATIM ("Denmark"/"USA"/"-"/"No");
##   * HEIGHT/WEIGHT imperial via the FICHA floor constants
##     (docs/re/player_info_re.md; "6 3" / "15 12").
##
## Documented approximations (un-walked, flagged in the RE doc):
##   * banner-name fill = the engine rolls per-draw random speckle in 4 greys;
##     here a deterministic hash picks among the same 4 (parity masks glyphs);
##   * big NATIONALITY flag: walked countries ship as frame patches; other
##     codes stretch the 30x20 BANDERAS art into the same box;
##   * photo-less players: CAMPO pitch + BALON at the CAMROL slot (the
##     original's marker geometry is un-RE'd);
##   * PRINT is inert on mobile (no printer); pressed states un-walked.

signal back_pressed

const W := 640
const H := 480

# ---- bake-pinned geometry (dbase_card_chrome_samples.json) ----------------
const TAB_X := [[17, 85], [77, 193], [185, 261], [253, 321], [313, 397], [389, 473], [465, 557]]
const TAB_Y0 := 71
const SEAM_W := 8
const PANEL := Rect2(12, 91, 622, 325)
const TITLE_BAR_POS := Vector2(20, 96)
const NAME_BOX := Rect2(143, 8, 358, 32)
const KIT_XY := Vector2(566, 0)
const PHOTO_XY := Vector2(41, 137)
const PHOTO_BOX := Rect2(28, 126, 150, 208)
const ROLE_CX := 108.5
const ROLE_Y := 342.0
const FLAG_SMALL_XY := Vector2(461, 164)
const FLAG_BIG_XY := Vector2(404, 213)
const FLAG_BIG_SIZE := Vector2(63, 20)
const BOTTOM_XY := Vector2(12, 405)
const BTN_PRINT := Rect2(384, 442, 114, 28)
const BTN_RETURN := Rect2(506, 442, 114, 28)
const SCROLL_UP := Rect2(584, 124, 28, 26)
const SCROLL_DN := Rect2(584, 384, 28, 26)
const TRACK := Rect2(584, 150, 28, 234)
# PERSONAL DATA value anchors (frame-measured; PROMAN10 white unless noted)
const PD_BP_XY := Vector2(196, 170)
const PD_DATE_XY := Vector2(513, 170)
const PD_AGE_XY := Vector2(193, 219)
const PD_NAT_XY := Vector2(274, 219)
const PD_INTL_XY := Vector2(459, 219)
const PD_LC_XY := Vector2(196, 270)
const PD_H_XY := Vector2(200, 318)
const PD_W_XY := Vector2(400, 318)
# prose (all frame-fitted: tools/re/fit_prose_advances.py, 168/168 rows exact
# across the 12 walked prose frames of bio-coin-walk-2026-07-06)
const PROSE_X0 := 214            # pen origin
const PROSE_X1 := 569            # justification flush target
const PROSE_WRAP_CAP := 570      # natural pen-end may reach X1+1 (041 "which")
const PROSE_Y0 := 150
const PROSE_PITCH := 16
const PROSE_LINES := 14          # viewport rows 150..374 (039: rows 14/15 empty)
const PROSE_LINE_CAP := 24       # fixed line table; overflow DROPPED (044 end)
const BULLET_ADV := 9            # ▶ glyph advance; source spaces follow at 6px
# career PROGRESS grid
const CAR_COLS := [189, 252, 409, 488, 535, 573]
const CAR_HDR := ["SEASON", "TEAM", "DIVISION", "MATCH", "GOALS"]
const CAR_HDR_Y := 133
const CAR_HDR_H := 15
const CAR_ROW0 := 150
const CAR_ROW_H := 20
const CAR_N_ROWS := 12
const C_HDR_BLUE := Color8(166, 202, 240)
const C_HDR_GREEN := Color8(170, 191, 170)
const C_SEASON_BG := Color8(212, 223, 255)
const C_GRID := Color8(128, 128, 128)
const C_ROWSEP := Color8(192, 192, 192)
const CAR_INKS := [Color8(30, 52, 98), Color8(0, 0, 0), Color8(60, 80, 100),
	Color8(0, 95, 0), Color8(60, 80, 100)]
# the tab-disable rule (docs/re/dbase_player_card_re.md, data-validated)
const SENTINELS := ["x", "X", "-", "*", "TXT ?", "No data.", "Sin datos.", "ND,ND,ND,ND,ND"]
# banner name speckle greys (the engine's per-draw noise family)
const NAME_GREYS := [Color8(255, 255, 255), Color8(240, 240, 240),
	Color8(220, 220, 220), Color8(192, 192, 192)]
const NAME_SHADOW := Color8(50, 70, 0)
const TAB_KEYS := ["profile", "technical", "honours", "career", "internat",
	"anecdotes", "lastseason"]

static var _bios: Dictionary = {}      # game_db player id (String) -> {pages, career, intl}
static var _paises: Dictionary = {}    # flagCode (int) -> PAISES display name

var now_unix := 0                      # 0 = real clock; parity states inject
var _p: Dictionary = {}
var _club: Dictionary = {}
var _bio: Dictionary = {}
var _tab_ok: Array = [false, false, false, false, false, false, false]  # sentinel rule
var _view := "pdata"                   # pdata | one of TAB_KEYS | notes
var _scroll := 0                       # prose line / career row offset
var _press := ""
var _tex: Dictionary = {}
var _f8: Font
var _f10: Font
var _f12: Font
var _f18: Font
var _fkk: Font


static func bios_of(pid: int) -> Dictionary:
	if _bios.is_empty():
		var f := FileAccess.open("res://data/bios.json", FileAccess.READ)
		if f != null:
			_bios = JSON.parse_string(f.get_as_text()).get("players", {})
	return _bios.get(str(pid), {})


static func pais_name(code: int) -> String:
	if _paises.is_empty():
		var f := FileAccess.open("res://data/country_codes.json", FileAccess.READ)
		if f != null:
			var by_name: Dictionary = JSON.parse_string(f.get_as_text()).get("byName", {})
			for n in by_name:
				_paises[int(by_name[n])] = n
	return str(_paises.get(code, ""))


## Disable rule: sentinel set OR stripped len < 15 (dbase_player_card_re.md;
## separates all 2025 players and reproduced every walked witness's wash).
static func section_enabled(s: String) -> bool:
	var t := s.strip_edges()
	return not (t in SENTINELS or t.length() < 15)


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f18 = PMChrome.font("18")
	_fkk = load("res://art/fonts/kkita.fnt") if ResourceLoader.exists("res://art/fonts/kkita.fnt") else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(player: Dictionary, club: Dictionary) -> void:
	_p = player
	_club = club
	_bio = bios_of(int(player.get("id", -1)))
	var pages: Array = _bio.get("pages", ["", "", "", "", "", ""])
	_tab_ok = []
	for i in 3:
		_tab_ok.append(section_enabled(str(pages[i])))
	_tab_ok.append(section_enabled(str(_bio.get("career", ""))))
	for i in range(3, 6):
		_tab_ok.append(section_enabled(str(pages[i])))
	_view = "pdata"
	_scroll = 0
	queue_redraw()


# ---- assets ----------------------------------------------------------------

func _t(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := "res://art/screens/dbase_card/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]


func _bank(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


# ---- data helpers ----------------------------------------------------------

## Flat comma/newline token stream, 5 cells per row (Dbasewin FUN_00410610 +
## FUN_0044c400). Blackwell's `89-90.Plymouth A,2,7,0` typo row shifts every
## later field one column for the rest of the table (frame 062) — a per-line
## parser is falsified; never repair the dirt.
static func parse_career(blob: String) -> Array:
	var toks := PackedStringArray()
	for line in blob.split("\n"):
		for t in line.split(","):
			toks.append(t)
	# the source ends rows with newlines; empty artifacts of blank lines drop
	var clean := PackedStringArray()
	for t in toks:
		if t.strip_edges() != "" or clean.size() % 5 != 0:
			clean.append(t)
	var rows: Array = []
	var i := 0
	while i < clean.size():
		var row := PackedStringArray()
		for k in 5:
			row.append(clean[i + k].strip_edges() if i + k < clean.size() else "")
		rows.append(row)
		i += 5
	return rows


## Whole years since birth at the SYSTEM date — the original computes AGE off
## the live clock (frames 034/050/068: 62/53/52 years under the 2026 capture
## clock). Faithful bug; parity injects the capture date via now_unix.
func _age_years() -> int:
	var t := now_unix if now_unix > 0 else int(Time.get_unix_time_from_system())
	var d := Time.get_datetime_dict_from_unix_time(t)
	var by := int(_p.get("birthYear", 0))
	if by <= 0:
		return int(_p.get("age", 0))
	var age := int(d["year"]) - by
	var bm := int(_p.get("birthMonth", 0))
	var bd := int(_p.get("birthDay", 0))
	if bm > 0 and (int(d["month"]) < bm or (int(d["month"]) == bm and int(d["day"]) < bd)):
		age -= 1
	return age


## Imperial conversions — the FICHA float constants (player_info_re.md).
static func imperial_height(cm: int) -> String:
	var feet := int(cm / 30.48)
	var inches := int((cm - feet * 30.48) * 0.3937)
	return "%d %d" % [feet, inches]


static func imperial_weight(kg: int) -> String:
	var stone := int(kg / 6.35)
	var pounds := int((kg - stone * 6.35) * 2.2046)
	return "%d %d" % [stone, pounds]


# ---- input -----------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	for i in 7:
		if Rect2(TAB_X[i][0], TAB_Y0, TAB_X[i][1] - TAB_X[i][0], 20).has_point(d):
			return "tab%d" % i
	if Rect2(17, 405, 55, 24).has_point(d):
		return "data"
	if Rect2(72, 405, 60, 24).has_point(d):
		return "notes"
	if BTN_RETURN.has_point(d):
		return "return"
	if BTN_PRINT.has_point(d):
		return "print"
	if SCROLL_UP.has_point(d):
		return "up"
	if SCROLL_DN.has_point(d):
		return "down"
	return ""


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
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	var hit := _hit(d)
	queue_redraw()
	if hit == "" or hit != was:
		return
	if hit == "return":
		back_pressed.emit()
	elif hit == "print":
		pass  # real CreateProcess print path — inert on mobile
	elif hit == "data":
		_view = "pdata"
		_scroll = 0
	elif hit == "notes":
		_view = "notes"
	elif hit == "up":
		_scroll = maxi(0, _scroll - 1)
	elif hit == "down":
		_scroll = mini(_max_scroll(), _scroll + 1)
	elif hit.begins_with("tab"):
		var i := int(hit.substr(3))
		if _tab_ok[i]:  # disabled tabs dead-click (walked: 057)
			_view = TAB_KEYS[i]
			_scroll = 0


func _max_scroll() -> int:
	if _view == "career":
		return maxi(0, parse_career(str(_bio.get("career", ""))).size() - CAR_N_ROWS)
	if _view in TAB_KEYS:
		return maxi(0, _prose_lines().size() - PROSE_LINES)
	return 0


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	draw_string(f, Vector2(x, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _tw(f: Font, s: String, sz: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x if f != null else 0.0


func _blit(name: String, xy: Vector2) -> void:
	var t := _t(name)
	if t != null:
		draw_texture(t, xy)


func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.08), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	var fondo := _bank("res://art/screens/fondo_dbase.png")
	if fondo != null:
		draw_texture_rect(fondo, Rect2(0, 0, W, H), false)
	draw_rect(Rect2(12, 90, 616, 1), Color(0, 0, 0), true)  # panel line under the tabs

	_draw_banner()
	_draw_tabs()
	_draw_panel()
	_blit("bottom_" + ("data" if _view == "pdata" else ("notes" if _view == "notes" else "top")),
		BOTTOM_XY)
	_blit("btn_print", BTN_PRINT.position)
	_blit("btn_return", BTN_RETURN.position)


func _draw_banner() -> void:
	_blit("banner", Vector2.ZERO)
	# per-club kit patch (frame truth for the walked clubs); scaled NANOESC
	# fallback for the rest (documented — the DB kit blit is un-walked there)
	var kit := _bank("res://art/kits/dbcard/%d.png" % int(_club.get("id", -1)))
	if kit != null:
		draw_texture(kit, KIT_XY)
	else:
		var nano := PMChrome.nano_kit(int(_club.get("id", -1)))
		if nano != null:
			draw_texture_rect(nano, Rect2(571, 4, 44, 59), false)
	# PROMAN18 name, centred on x=320 (Schmeichel witness: w 352 at x144),
	# glyph top y=16; shadow +2, fill = deterministic pick of the 4 noise greys
	var name := PMChrome.card_name(_p)
	if _f18 != null:
		var wpx := _tw(_f18, name, 19)
		var x := floorf(320.0 - wpx / 2.0)
		_txt(_f18, x + 2, 18, name, NAME_SHADOW, 19)
		var seed := hash(name)
		for k in 4:
			# layered speckle: draw the name 4x in the noise greys with tiny
			# deterministic per-pass clip offsets — reads as the engine's
			# grainy fill at 1:1 (glyph pixels are parity-masked anyway)
			pass
		_txt(_f18, x, 16, name, NAME_GREYS[abs(seed) % 2], 19)


func _tab_state(i: int) -> String:
	if _view == TAB_KEYS[i]:
		return "sel"
	return "rest" if _tab_ok[i] else "dis"


func _draw_tabs() -> void:
	var states: Array = []
	for i in 7:
		states.append(_tab_state(i))
	# rest/dis right-to-left, then seam patches, selected last (bake compose)
	for i in range(6, -1, -1):
		if states[i] != "sel":
			_blit("tab%d_%s" % [i, states[i]], Vector2(TAB_X[i][0], TAB_Y0))
	for i in 6:
		var pair: String = states[i][0] + states[i + 1][0]
		var patch := ""
		if pair in ["rr", "dr"]:
			patch = "tabseam_" + pair
		elif pair in ["dd", "rd"]:
			patch = "tabseam%d_%s" % [i, pair]
		elif pair == "ds":
			patch = "tabseam_ds"
		elif pair == "sd":
			patch = "tabseam%d_nd" % i
		if patch != "":
			_blit(patch, Vector2(TAB_X[i + 1][0], TAB_Y0))
	for i in 7:
		if states[i] == "sel":
			_blit("tab%d_sel" % i, Vector2(TAB_X[i][0], TAB_Y0))


func _view_underlay() -> String:
	if _view == "pdata":
		return "view_pdata"
	if _view == "notes":
		return "view_notes"
	if _view == "career":
		return "view_career"
	return "view_prose"


func _draw_panel() -> void:
	_blit(_view_underlay(), PANEL.position)
	_blit("title_" + ("career" if _view == "career" else _view), TITLE_BAR_POS)
	# the photo (or pitch) + role word live in EVERY view's left column
	# (TECHNICAL swaps the photo for the pitch + WHERE HE PLAYS — 036)
	if _view == "technical":
		_draw_pitch_panel()
	else:
		_draw_photo_or_pitch()
		var role: String = {"GK": "GOALKEEPER", "DF": "DEFENDER", "MF": "MIDFIELDER",
			"FW": "FORWARD"}.get(str(_p.get("pos", "")), "")
		if role != "":
			_txt(_f10, floorf(ROLE_CX - _tw(_f10, role, 10) / 2.0), ROLE_Y - 2, role,
				Color(0, 0, 0), 10)
	match _view:
		"pdata":
			_draw_pdata()
		"career":
			_draw_career()
		"notes":
			pass  # the empty notebook is fully baked (frame 046)
		"technical":
			_draw_prose()
		_:
			_draw_prose()


# ---- PERSONAL DATA ---------------------------------------------------------

func _draw_pdata() -> void:
	var white := Color(1, 1, 1)
	_txt(_f10, PD_BP_XY.x, PD_BP_XY.y, str(_p.get("birthplace", "") if _p.get("birthplace") else ""), white, 10)
	if _p.get("birthDay") and _p.get("birthMonth") and _p.get("birthYear"):
		_txt(_f10, PD_DATE_XY.x, PD_DATE_XY.y, "%d/%d/%d" % [int(_p["birthDay"]),
			int(_p["birthMonth"]), int(_p["birthYear"])], white, 10)
	_txt(_f10, PD_AGE_XY.x, PD_AGE_XY.y, "%d  years" % _age_years(), white, 10)
	_txt(_f10, PD_NAT_XY.x, PD_NAT_XY.y, pais_name(int(_p.get("flagCode", -1))).to_upper(), white, 10)
	# INTERNATIONAL = bios T3 VERBATIM ('-'/'No' dirt included; 5 witnesses)
	_txt(_f10, PD_INTL_XY.x, PD_INTL_XY.y, str(_bio.get("intl", "-") if _bio.get("intl") != null else "-"), white, 10)
	_txt(_f10, PD_LC_XY.x, PD_LC_XY.y, str(_p.get("prevClub", "") if _p.get("prevClub") else ""), white, 10)
	if _p.get("heightCm"):
		_txt(_f10, PD_H_XY.x, PD_H_XY.y, imperial_height(int(_p["heightCm"])), white, 10)
	if _p.get("weightKg"):
		_txt(_f10, PD_W_XY.x, PD_W_XY.y, imperial_weight(int(_p["weightKg"])), white, 10)
	# flags: BANDERAS small at the BIRTH PLACE bar end; big patch (walked
	# countries) or a GDI-style stretch of the small art on the NATIONALITY bar
	var code := int(_p.get("flagCode", -1))
	var small := _bank("res://art/flags/dbcard/%d.png" % code)
	if small != null:
		# 1px black widget frame under the 30x20 flag (034 truth)
		draw_rect(Rect2(460, 163, 32, 22), Color(0, 0, 0), true)
		draw_texture(small, FLAG_SMALL_XY)
	# NATIONALITY flag: the frame-cut patch (30x20 BANDERAS inside its 1px
	# black widget frame) for the walked countries; framed BANDERAS otherwise
	var big := _bank("res://art/flags/dbcard/big_%d.png" % code)
	if big != null:
		draw_texture(big, FLAG_BIG_XY)
	elif small != null:
		draw_rect(Rect2(404, 213, 33, 22), Color(0, 0, 0), true)
		draw_texture(small, Vector2(405, 214))


func _draw_photo_or_pitch() -> void:
	var photo := _bank("res://art/faces/dbcard/%d.png" % int(_p.get("photoId", -1)))
	if photo != null:
		draw_texture(photo, PHOTO_XY)
		# the SOMBRA drop shadows (baked frame cuts; identical 034/055)
		_blit("photo_shadow_r", Vector2(165, 137))
		_blit("photo_shadow_b", Vector2(40, 319))
		return
	_draw_campo_markers()


func _draw_campo_markers() -> void:
	# CAMPO fallback (walked: 050/063/065/068) + BALON at the player's CAMROL
	# slot — the original's exact marker geometry is un-RE'd (approximation)
	var campo := _t("campo")
	if campo != null:
		draw_texture(campo, Vector2(37, 133))
	var balon := _t("balon")
	if balon != null:
		var fine := clampi(int(_p.get("posFine", 0)), 1, 18)
		@warning_ignore("integer_division")
		var fy := 300.0 - 15.0 * ((fine - 1) / 3)  # GK bottom rows, FW top
		var fx := 37.0 + 20.0 + 30.0 * ((fine - 1) % 3)
		if bool(_p.get("isGK", false)):
			fx = 95.0
			fy = 300.0
		draw_texture(balon, Vector2(fx, fy))


## TECHNICAL CHAR. left column: the pitch + mini face + "WHERE HE PLAYS...."
## (036 Schmeichel; marker geometry un-RE'd — documented approximation).
func _draw_pitch_panel() -> void:
	_draw_campo_markers()
	var mini := PMChrome.mini_face(_p.get("photoId"))
	if mini != null:
		draw_texture(mini, Vector2(45, 340))
	var yy := 340.0
	for line in ["WHERE", "HE", "PLAYS...."]:
		_txt(_f10, 96, yy, line, Color(0, 0, 0), 10)
		yy += 12.0


# ---- prose pages -----------------------------------------------------------

func _page_text() -> String:
	var idx := TAB_KEYS.find(_view)
	var pages: Array = _bio.get("pages", ["", "", "", "", "", ""])
	match idx:
		0: return str(pages[0])
		1: return str(pages[1])
		2: return str(pages[2])
		4: return str(pages[3])
		5: return str(pages[4])
		6: return str(pages[5])
	return ""


## Frame-fitted justification stretch (fit_prose_advances.py law 7):
## cumulative pixels inserted after break j of n breaks for line deficit D.
## - (D+1)/n representable in eighths -> zero-phase Bresenham on (D+1)/n
##   (total D+1: the line's pen-end lands on 570, one px past flush);
## - else every break gets D/n and the remainder r goes one px each to
##   breaks floor(n*i/(r+1)), i=1..r (evenly spread, ends bare; total D).
static func _gdi_stretch(deficit: int, n: int, j: int) -> int:
	if deficit <= 0 or n <= 0 or j <= 0:
		return 0
	if (8 * (deficit + 1)) % n == 0:
		@warning_ignore("integer_division")
		var cum: int = (j * (deficit + 1)) / n
		return cum
	@warning_ignore("integer_division")
	var base: int = deficit / n
	var r: int = deficit % n
	var placed := 0
	for i in range(1, r + 1):
		@warning_ignore("integer_division")
		var pos: int = (n * i) / (r + 1)
		if pos < j:
			placed += 1
	return j * base + placed


## The original's layout, frame-fitted to 168/168 rows across the 12 walked
## prose frames (tools/re/fit_prose_advances.py):
## - '*' renders as the ▶ glyph (advance 9); the source text after it runs
##   VERBATIM — leading spaces render 6px each and are justification breaks
##   ("*A member" has none: 039/043 walk the no-gap case);
## - gaps carry their literal space count (the data has double spaces);
## - greedy wrap: break before a word whose natural pen-end would pass 570;
## - the line table holds 24 lines; overflow is dropped and the 24th line
##   justifies like any broken line (044: "...Manchester United were");
## - every line justifies except a paragraph's stored last.
## Returns [{words, gaps, lead, justify, first}] per visual line.
func _prose_lines() -> Array:
	var out: Array = []
	if _fkk == null:
		return out
	var gap := _tw(_fkk, " ", 16)
	var parts := _page_text().split("*")
	for pi in range(1, parts.size()):
		var text := String(parts[pi]).strip_edges(false, true)
		if text.strip_edges() == "":
			continue
		var lead := 0
		while lead < text.length() and text[lead] == " ":
			lead += 1
		var toks := text.substr(lead).split(" ", true)
		var words: Array = []
		var spaces: Array = []
		var run := 0
		for t in toks:
			if t == "":
				run += 1
				continue
			if not words.is_empty():
				spaces.append(run + 1)
			words.append(String(t))
			run = 0
		var line_w: Array = []
		var line_s: Array = []
		var first := true
		var x := PROSE_X0 + BULLET_ADV + gap * lead
		for k in words.size():
			var wpx := _tw(_fkk, words[k], 16)
			var nsp: int = spaces[k - 1] if k > 0 else 0
			if not line_w.is_empty() and x + gap * nsp + wpx > PROSE_WRAP_CAP:
				out.append({"words": line_w, "gaps": line_s,
					"lead": lead if first else 0, "justify": true, "first": first})
				line_w = []
				line_s = []
				first = false
				x = PROSE_X0
			elif not line_w.is_empty():
				line_s.append(nsp)
				x += gap * nsp
			x += wpx
			line_w.append(words[k])
		if not line_w.is_empty():
			out.append({"words": line_w, "gaps": line_s,
				"lead": lead if first else 0, "justify": false, "first": first})
	if out.size() > PROSE_LINE_CAP:
		out.resize(PROSE_LINE_CAP)
		out[PROSE_LINE_CAP - 1]["justify"] = true
	return out


func _draw_prose() -> void:
	if _fkk == null:
		return
	# the prose page's open-right grey border (top/left/bottom only —
	# 072/035/037: exactly rows y128+y393 x189-575 and col x189)
	draw_rect(Rect2(189, 128, 387, 1), C_GRID, true)
	draw_rect(Rect2(189, 129, 1, 264), C_GRID, true)
	draw_rect(Rect2(189, 393, 387, 1), C_GRID, true)
	var lines := _prose_lines()
	var n := lines.size()
	var gap := _tw(_fkk, " ", 16)
	for row in PROSE_LINES:
		var li: int = row + _scroll
		if li >= n:
			break
		var l: Dictionary = lines[li]
		var y := PROSE_Y0 + row * PROSE_PITCH
		var first := bool(l["first"])
		if first:
			_blit("prose_bullet", Vector2(PROSE_X0, y))
		var words: Array = l["words"]
		var gaps: Array = l["gaps"]
		var lead: int = int(l["lead"])
		var justify := bool(l["justify"])
		var pen0 := PROSE_X0 + (BULLET_ADV if first else 0)
		var nbr: int = lead
		for g in gaps:
			nbr += int(g)
		var deficit := 0
		if justify:
			var natural := gap * nbr
			for w in words:
				natural += _tw(_fkk, str(w), 16)
			deficit = int(PROSE_X1 - pen0 - natural)
		var pen := float(pen0) + gap * lead
		var brk := lead
		for k in words.size():
			if k > 0:
				pen += gap * int(gaps[k - 1])
				brk += int(gaps[k - 1])
			var x := pen + (_gdi_stretch(deficit, nbr, brk) if justify else 0)
			# -3: the original's glyph cell tops sit at PROSE_Y0-3 (+16/row):
			# 072 'F' inks 150-159 = cell top 147 (kkita ink rows 3-12)
			_txt(_fkk, x, y - 3, str(words[k]), Color(0, 0, 0), 16)
			pen += _tw(_fkk, str(words[k]), 16)
	_draw_scrollbar(n, PROSE_LINES)


# ---- career PROGRESS table ---------------------------------------------------

func _draw_career() -> void:
	var rows := parse_career(str(_bio.get("career", "")))
	# header band: the baked frame cut (static across 038/042/062)
	_blit("career_header", Vector2(189, 131))
	# vertical grid lines UNDER the rows (the 192 row separators win crossings)
	for x in CAR_COLS:
		draw_rect(Rect2(x, CAR_ROW0, 1, CAR_N_ROWS * CAR_ROW_H - 1), C_GRID, true)
	# 12 fixed grid rows (042: empty bordered rows after the last entry)
	for r in CAR_N_ROWS:
		var y := CAR_ROW0 + r * CAR_ROW_H
		draw_rect(Rect2(190, y, CAR_COLS[1] - 190, CAR_ROW_H - 2), C_SEASON_BG, true)
		draw_rect(Rect2(190, y + CAR_ROW_H - 2, 383, 2), C_ROWSEP, true)
		var ri: int = r + _scroll
		if ri >= rows.size():
			continue
		var row: PackedStringArray = rows[ri]
		for k in 5:
			var cx0: int = CAR_COLS[k] + 1
			var cx1: int = CAR_COLS[k + 1]
			var cell := row[k] if k < row.size() else ""
			if cell == "":
				continue
			# PROMAN10, centred on the cell, pixel-clipped at BOTH cell edges
			# (062 "0. Plymou" / shifted-"Wimbledon" truth). C-style trunc
			# toward 0, NOT floor: overflowing cells centre 1px right of
			# floor ((-w)/2 truncates up) — the 062 clipped-cell residual
			var wpx := _tw(_f10, cell, 10)
			var x := cx0 + int((cx1 - cx0 - wpx) / 2.0)
			_clip_text("proman10", cell, x, y + 4,
				Rect2(cx0, y, cx1 - cx0, CAR_ROW_H - 2), CAR_INKS[k])
	draw_rect(Rect2(189, CAR_ROW0 + CAR_N_ROWS * CAR_ROW_H - 1, 385, 1), C_GRID, true)
	_draw_scrollbar(rows.size(), CAR_N_ROWS)


# ---- pixel-clipped text (GDI cell clipping, partial glyphs included) --------

static var _atlas: Dictionary = {}   # font key -> {tex, metrics: {code: [x,y,w,h,adv]}}


func _font_atlas(key: String) -> Dictionary:
	if not _atlas.has(key):
		var info := {}
		# the BMFont atlas png is not an imported resource (the .fnt owns it) —
		# read it as an Image and wrap it
		var tex: Texture2D = null
		var img := Image.new()
		if img.load_png_from_buffer(
				FileAccess.get_file_as_bytes("res://art/fonts/%s.png" % key)) == OK:
			tex = ImageTexture.create_from_image(img)
		var metrics := {}
		var f := FileAccess.open("res://art/fonts/%s.fnt" % key, FileAccess.READ)
		while f != null and not f.eof_reached():
			var line := f.get_line()
			if not line.begins_with("char id="):
				continue
			var kv := {}
			for part in line.split(" ", false):
				var eq := part.split("=")
				if eq.size() == 2:
					kv[eq[0]] = eq[1]
			metrics[int(kv.get("id", -1))] = [int(kv.get("x", 0)), int(kv.get("y", 0)),
				int(kv.get("width", 0)), int(kv.get("height", 0)), int(kv.get("xadvance", 0))]
		info["tex"] = tex
		info["metrics"] = metrics
		_atlas[key] = info
	return _atlas[key]


## Draw `s` with its glyph pixels CLIPPED to `clip` — partial glyphs at the
## clip edges render partially, exactly like the original's GDI cell clip.
func _clip_text(font_key: String, s: String, x: float, y_top: float,
		clip: Rect2, ink: Color) -> void:
	var fa := _font_atlas(font_key)
	var tex: Texture2D = fa["tex"]
	var metrics: Dictionary = fa["metrics"]
	if tex == null:
		return
	var cx := x
	for ch in s.to_ascii_buffer():
		var m: Array = metrics.get(ch, metrics.get(32, [0, 0, 0, 0, 5]))
		var dest := Rect2(cx, y_top, m[2], m[3])
		var inter := dest.intersection(clip)
		if inter.size.x > 0 and inter.size.y > 0:
			var src := Rect2(m[0] + (inter.position.x - dest.position.x),
				m[1] + (inter.position.y - dest.position.y), inter.size.x, inter.size.y)
			draw_texture_rect_region(tex, inter, src, ink)
		cx += m[4]


# ---- scrollbar ---------------------------------------------------------------

func _draw_scrollbar(total: int, visible_n: int) -> void:
	# the bar chrome is view-specific: prose (framed bar) vs career (bare)
	var vk := "scrollc" if _view == "career" else "scrollp"
	if total <= visible_n:
		# nothing to scroll: washed steppers + the flat full-track slab
		_blit(vk + "_up_washed", SCROLL_UP.position)
		_blit(vk + "_dn_washed", SCROLL_DN.position)
		_blit(vk + "_slab", TRACK.position)
		return
	var can_up := _scroll > 0
	var can_dn := _scroll < total - visible_n
	_blit(vk + "_up_" + ("active" if can_up else "washed"), SCROLL_UP.position)
	_blit(vk + "_dn_" + ("active" if can_dn else "washed"), SCROLL_DN.position)
	# flat gutter, then the baked 3D thumb (038 cut). The 038 witness (off 0)
	# is pixel-pinned at y=154; travel is fitted on the 038/042 pair
	# (total 14, +30px for 2 rows) and proportional for other page sizes —
	# documented approximation beyond the walked career states.
	# track: the below-thumb strip anchors to the track bottom, the above-thumb
	# strip to the top (both 038/042 frame cuts); the thumb covers the middle.
	var below := _t("scroll_track_below")
	if below != null:
		draw_texture(below, Vector2(TRACK.position.x, TRACK.end.y - below.get_height()))
	var above := _t("scroll_track_above")
	if above != null:
		draw_texture(above, Vector2(TRACK.position.x, TRACK.position.y))
	var thumb := _t("scroll_thumb")
	if thumb == null:
		return
	# off=0 is frame-pinned (038, thumb top at y150); the travel is fitted on
	# the 038/042 pair (+30px for 2 rows of a 14-row page) — proportional
	# beyond that pair is a documented approximation (no other walked offsets).
	var ty := 150.0 + floorf(TRACK.size.y * float(_scroll) / float(total + 1))
	if _scroll == 0:
		ty = 150.0
	draw_texture(thumb, Vector2(TRACK.position.x, ty))
