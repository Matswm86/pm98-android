extends Control
class_name PreseasonScreen
## PM98 PRESEASON screen ("Preseason for <club>"). The static chrome is the REAL
## game's fresh frame (walkthrough 013 == 016 pixel-exact): barra, EUROPE/S.AMERICA
## tabs, EUROPA map WITH its 47 runtime flags baked, empty country strip, ENGLAND
## kit panel, 4 calendar sheets (1/4/6/8 August 1997), 4 rival slots (slot 1
## active), SKIP / division filter (PREMIER selected) / washed DELETE / CONTINUE —
## all original pixels. See docs/re/pretemporada_screen_re.md and
## tools/re/build_entry_chrome_from_frames.py.
##
## Dynamic layer redraws only state deltas: the strip country name after a flag tap
## (frame 015 "HUNGARY"), the kit panel when country/division changes, rival slots
## once picks exist (state textures cut from the frame; the active badge moves),
## the division filter when re-selected (div_chip + red border + yellow label),
## the ENABLED DELETE (cut from frame 008's identical seleccion button — PM98
## washes disabled buttons toward the backdrop), tab swaps (S.AMERICA map is real
## art; its ACTIVE tab style is procedural — no walkthrough frame shows it), and
## press tints.
##
## 2026-07-12 (wine captures, screenshots/wine-captures-2026-07-12/): the
## S.AMERICA tab is now REAL pixels (tab strips + SUDAMERICA map with its 10
## runtime flags baked + SAD-matched markers — build_pretemp_states_from_frames.py),
## SKIP washes at 4/4 picks and CONTINUE goes hot (frame-cut states), the last
## picked club's name renders under the kit panel (ink 120,120,160 — frame
## pretemp_slot1), and each filled rival slot shows TWO lines: the club name and
## the VENUE STADIUM. Home/away is the engine's club-average compare, reversed
## from MANAGER.EXE FUN_004c7570 (docs/re/decompiled/fn_004c7570_FUN_004c7570.c):
## venue = own club iff AV(rival) < AV(own) else the rival, where AV =
## floor(sum(VE+RE+AG+CA over squad) / (4*n)) (FUN_0057a340). 7/7 live witnesses
## incl. the 1-pt edge (Bolton 71 @ Wimbledon 72 -> Selhurst Park) and the tie
## (Man Utd 81 vs Juventus 81 -> away). The old continent-tab hypothesis is DEAD
## (Bolton picking Sao Paulo -> Morumbi, away).
## (Foreign-club kit art extracted 2026-07-04 — all 476 NANOESC kits in
## app/art/kits/nano/, positional id->code map in tools/re/map_crests.py — so
## foreign country panels now render kits via the nano_kit fallback.)

signal preseason_done(rivals: Array)

const W := 640
const H := 480

const R_TITLE := Rect2(150, 16, 350, 27)
const R_TAB_EU := Rect2(3, 78, 21, 112)
const R_TAB_SA := Rect2(3, 190, 21, 112)
const R_MAP := Rect2(27, 80, 300, 220)
const R_STRIP := Rect2(7, 304, 322, 22)
const R_PANEL := Rect2(8, 336, 321, 130)
# NANOESC kits (24x32) blit 1:1, SAD-0.0-anchored vs frame 013: x 13+31i, y 368/405
const KIT_X0 := 13
const KIT_PITCH := 31
const KIT_Y := [368, 405]
const RIV_X := 377.0
const RIV_W := 228.0                           # slot body; number badge x 605..629
const BADGE_W := 24
const ROW_Y := [78.0, 136.0, 194.0, 252.0]
const R_SKIP := Rect2(503, 333, 112, 25)
const R_PREMIER := Rect2(383, 370, 112, 25)
const R_FIRST := Rect2(503, 370, 112, 25)
const R_SECOND := Rect2(383, 403, 112, 25)
const R_THIRD := Rect2(503, 403, 112, 25)
const R_DELETE := Rect2(383, 440, 112, 25)
const R_CONTINUE := Rect2(503, 440, 112, 25)

const DATES := [{"d": 1}, {"d": 4}, {"d": 6}, {"d": 8}]   # 1/4/6/8 August 1997

# Frame-sampled colours (tools/re/specs/entry_chrome_samples.json)
const C_TITLE_BLUE := Color8(0, 0, 160)        # panel country title
const C_DIGIT_ON := Color8(255, 255, 255)
const C_DIGIT_OFF := Color8(220, 172, 121)
const C_SEL_BORDER := Color8(128, 0, 0)
const C_SEL_TEXT := Color8(255, 255, 0)
const C_UNSEL_TEXT := Color8(144, 144, 144)
const C_FILL_TEXT := Color8(20, 24, 60)
const C_PRESS := Color(1, 1, 1, 0.2)

var _chrome: Texture2D
var _map_sa: Texture2D
var _riv_badge: Dictionary = {}   # "on"/"off"
var _riv_head: Dictionary = {}
var _riv_bar: Dictionary = {}
var _div_chip: Texture2D
var _delete_on: Texture2D
var _skip_off: Texture2D          # 4/4 picks: SKIP washes (frame pretemp_slot4)
var _continue_hot: Texture2D      # 4/4 picks: CONTINUE goes hot (same frame)
var _tab_eu_off: Texture2D        # real tab strips, S.AMERICA active (2026-07-12 capture)
var _tab_sa_on: Texture2D
var _title_band: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font

var _club_name := ""
var _manager := ""
var _markers: Array = []          # {code,name,x,y} from the spec JSON (tap targets)
var _markers_sa: Array = []       # S.AMERICA map markers (SAD-matched, 2026-07-12)
var _tab := 0                     # 0=EUROPE 1=S.AMERICA
var _country := "ENGLAND"         # country shown in the kit panel
var _strip_country := ""          # black strip text; EMPTY until a flag is tapped (frame 013)
var _country_clubs: Array = []    # clubs listed in the panel
var _div := 0                     # England division filter index
var _rivals: Array = []           # picked rival clubs (Dictionary), in slot order
var _press := ""
var _leagues: Array = []
var _clubs_of: Callable           # league_id -> clubs
var _clubs_of_country: Callable   # PAISES English name -> clubs (Main bridges es->en)
var _managed_id := -1             # taken clubs (managed + picked rivals) render washed
var _own_club: Dictionary = {}    # managed club (venue + AV for the home/away compare)
var _own_av := 0                  # engine club average (FUN_0057a340) of the managed club
var _last_pick := ""              # last picked club name, under the kit panel (frame truth)
var _sel_flag: Dictionary = {}    # tapped map marker; its flag draws enlarged (frame 015)
var _sel_tab := 0                 # which map the selected marker belongs to
var _checker: Texture2D           # 2x2 white/transparent — the taken-club kit wash

# frame-sampled: last-pick label ink (pretemp_slot1, glyph rows y 450-457)
const C_LAST_PICK := Color8(120, 120, 160)


func _ready() -> void:
	_chrome = load("res://art/screens/pretemp/chrome.png")
	_map_sa = load("res://art/screens/pretemp/sudamerica.png")
	_riv_badge["on"] = load("res://art/screens/pretemp/riv_badge_on.png")
	_riv_badge["off"] = load("res://art/screens/pretemp/riv_badge_off.png")
	_riv_head["on"] = load("res://art/screens/pretemp/riv_head_on.png")
	_riv_head["off"] = load("res://art/screens/pretemp/riv_head_off.png")
	_riv_bar["on"] = load("res://art/screens/pretemp/riv_bar_on.png")
	_riv_bar["off"] = load("res://art/screens/pretemp/riv_bar_off.png")
	_div_chip = load("res://art/screens/pretemp/div_chip.png")
	_delete_on = load("res://art/screens/pretemp/delete_on.png")
	_skip_off = load("res://art/screens/pretemp/skip_off.png")
	_continue_hot = load("res://art/screens/pretemp/continue_hot.png")
	_tab_eu_off = load("res://art/screens/pretemp/tab_eu_off.png")
	_tab_sa_on = load("res://art/screens/pretemp/tab_sa_on.png")
	if ResourceLoader.exists("res://art/screens/pretemp/sudamerica_flags.png"):
		_map_sa = load("res://art/screens/pretemp/sudamerica_flags.png")
	_title_band = load("res://art/screens/pretemp/title_band.png")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	var ci := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	ci.set_pixel(0, 0, Color.WHITE)
	ci.set_pixel(1, 1, Color.WHITE)
	_checker = ImageTexture.create_from_image(ci)
	var f := FileAccess.open("res://data/pretemp_flag_markers.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_markers = parsed.get("markers", [])
	var fsa := FileAccess.open("res://data/pretemp_flag_markers_sa.json", FileAccess.READ)
	if fsa != null:
		var parsed_sa: Variant = JSON.parse_string(fsa.get_as_text())
		if typeof(parsed_sa) == TYPE_DICTIONARY:
			_markers_sa = parsed_sa.get("markers", [])
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club_name: String, manager: String, leagues: Array, clubs_of: Callable,
		clubs_of_country: Callable, managed_club_id := -1, managed_club: Dictionary = {}) -> void:
	_club_name = club_name
	_manager = manager
	_leagues = leagues
	_clubs_of = clubs_of
	_clubs_of_country = clubs_of_country
	_managed_id = managed_club_id
	_own_club = managed_club
	_own_av = club_av(managed_club)
	_select_england()
	queue_redraw()


## The engine's club average — FUN_0057a340: floor(sum of the 4 GENERAL bytes
## (VE speed / RE stamina / AG aggression / CA quality) over the whole squad,
## divided by 4*players). Drives the friendly venue compare (FUN_004c7570).
static func club_av(club: Dictionary) -> int:
	var ps: Array = club.get("players", [])
	if ps.is_empty():
		return 0
	var s := 0
	for p in ps:
		var a: Dictionary = (p as Dictionary).get("attrs", {})
		s += int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0)) + int(a.get("CA", 0))
	@warning_ignore("integer_division")
	return s / (ps.size() * 4)


func _select_england() -> void:
	_country = "ENGLAND"
	_country_clubs = []
	if _div < _leagues.size() and _clubs_of.is_valid():
		_country_clubs = _clubs_of.call(str(_leagues[_div].get("id", "")))
		_country_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


# ---- geometry --------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _kit_cols() -> int:
	return 10 if _country_clubs.size() <= 20 else int(ceil(_country_clubs.size() / 2.0))

## The tap/selection cell (26x36 around the 24x32 kit, as seleccion's OVER cell).
## Column x = 13 + floor(c*95/3) — the original's integer pitch (SAD-anchored 013).
func _kit_rect(i: int) -> Rect2:
	var cols := _kit_cols()
	var c := i % cols
	var x: float = KIT_X0 - 1 + (c * 95) / 3 if cols == 10 \
		else KIT_X0 - 1 + c * (R_PANEL.size.x - 16.0) / cols
	return Rect2(x, KIT_Y[i / cols] - 2, 26, 36)

func _flag_at(d: Vector2) -> Dictionary:
	for m in (_markers if _tab == 0 else _markers_sa):
		if Rect2(float(m["x"]) - 1, float(m["y"]) - 1, 20, 15).has_point(d):
			return m
	return {}

func _target_at(d: Vector2) -> String:
	# SKIP washes out (disabled) once all 4 slots are picked (frame pretemp_slot4)
	if R_SKIP.has_point(d) and _rivals.size() < 4: return "skip"
	if R_CONTINUE.has_point(d): return "continue"
	if R_DELETE.has_point(d) and not _rivals.is_empty(): return "delete"
	if R_TAB_EU.has_point(d): return "tab:0"
	if R_TAB_SA.has_point(d): return "tab:1"
	if _country == "ENGLAND":
		var divs := [R_PREMIER, R_FIRST, R_SECOND, R_THIRD]
		for i in divs.size():
			if i < _leagues.size() and divs[i].has_point(d):
				return "div:%d" % i
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		if _kit_rect(i).has_point(d):
			return "kit:%d" % i
	if not _flag_at(d).is_empty():
		var m := _flag_at(d)
		return "flag:%s" % str(m["name"])
	return ""


# ---- input -----------------------------------------------------------------

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
	match was:
		"skip", "continue":
			preseason_done.emit(_rivals.duplicate())
		"delete":
			_rivals.pop_back()
			queue_redraw()
		"tab:0":
			_tab = 0
			queue_redraw()
		"tab:1":
			# frame truth (pretemp_samerica_tab_active): switching tabs keeps the
			# kit panel (ENGLAND stayed) — only the map + tab strips swap
			_tab = 1
			queue_redraw()
		_:
			if was.begins_with("div:"):
				_div = int(was.substr(4))
				_select_england()
				queue_redraw()
			elif was.begins_with("flag:"):
				# frame 015 truth: the strip names the tapped country, but the kit
				# panel only switches when that country HAS clubs (HUNGARY tapped ->
				# strip HUNGARY, panel still ENGLAND)
				var nm := was.substr(5)
				_strip_country = nm
				for m in (_markers if _tab == 0 else _markers_sa):
					if str(m["name"]) == nm:
						_sel_flag = m
						_sel_tab = _tab
				if nm == "ENGLAND":
					_country = nm
					_select_england()
				else:
					var cc: Array = _clubs_of_country.call(nm) if _clubs_of_country.is_valid() else []
					if not cc.is_empty():
						_country = nm
						cc.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
						_country_clubs = cc
				queue_redraw()
			elif was.begins_with("kit:"):
				var i := int(was.substr(4))
				if _rivals.size() < 4 and i < _country_clubs.size():
					# `home` = the MANAGER hosts. Engine rule (MANAGER.EXE
					# FUN_004c7570 + FUN_0057a340, docs/re/decompiled/): the
					# friendly is played at the STRONGER club's ground —
					# venue = own club iff AV(rival) < AV(own), ties away.
					# 7/7 live witnesses 2026-07-12 (pretemporada_screen_re.md).
					var pick: Dictionary = (_country_clubs[i] as Dictionary).duplicate()
					var home := club_av(pick) < _own_av
					pick["home"] = home
					pick["venue_stadium"] = str((_own_club if home else pick).get("stadium", ""))
					_rivals.append(pick)
					_last_pick = PMChrome.title_case_name(str(pick.get("name", "")))
					queue_redraw()


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, cw := 0.0, center := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)

	# title: the baked one is "Preseason for Manchester Utd."; for any other club,
	# blit the textless barra band (row-median-inpainted real pixels) + redraw
	if _club_name != "" and _club_name != "Manchester Utd." and _title_band != null:
		draw_texture_rect(_title_band, Rect2(110, 12, 450, 36), false)
		_txt(_f14, R_TITLE.position.x, R_TITLE.position.y, "Preseason for %s" % _club_name,
			Color.WHITE, 15, R_TITLE.size.x, true)

	# S.AMERICA tab active: real pixels (2026-07-12 capture) — the SUDAMERICA map
	# with its 10 runtime flags baked + the real tab strips
	if _tab == 1:
		if _map_sa != null:
			draw_texture_rect(_map_sa, R_MAP, false)
		if _tab_eu_off != null:
			draw_texture_rect(_tab_eu_off, R_TAB_EU, false)
		if _tab_sa_on != null:
			draw_texture_rect(_tab_sa_on, R_TAB_SA, false)

	# selected country -> its flag renders ENLARGED at the BANDERAS native 30x20
	# (frame 015: HUNGARY at marker-(8,4) with a 1px black border), persisting;
	# same behaviour witnessed on the SA map (capture pretemp_brazil_panel)
	if _sel_tab == _tab and not _sel_flag.is_empty():
		var fx := float(_sel_flag["x"]) - 8.0
		var fy := float(_sel_flag["y"]) - 4.0
		draw_rect(Rect2(fx - 1, fy - 1, 32, 22), Color(0, 0, 0), true)
		var ftex := PMChrome.flag(int(_sel_flag["code"]))
		if ftex != null:
			draw_texture(ftex, Vector2(fx, fy))
	# flag press feedback (flags themselves are baked)
	if _press.begins_with("flag:"):
		for m in (_markers if _tab == 0 else _markers_sa):
			if _press == "flag:%s" % str(m["name"]):
				draw_rect(Rect2(float(m["x"]) - 1, float(m["y"]) - 1, 20, 15), C_PRESS, true)

	# country strip: baked empty; name appears after a flag tap (frame 015)
	if _strip_country != "":
		_txt(_f12, R_STRIP.position.x, R_STRIP.position.y + 5, _strip_country, Color.WHITE, 13,
			R_STRIP.size.x, true)

	# kit panel: baked ENGLAND/Premier resting; repaint on any change
	if _country != "ENGLAND" or _div != 0:
		_draw_panel()
	elif _press.begins_with("kit:"):
		draw_rect(_kit_rect(int(_press.substr(4))), C_PRESS, true)

	# last picked club's name under the kit rows (frames pretemp_slot1/2/3: the
	# label persists across country/tab changes; ink 120,120,160, glyphs y 450-457)
	if _last_pick != "":
		_txt(_f10, R_PANEL.position.x, 447, _last_pick, C_LAST_PICK, 10, R_PANEL.size.x, true)

	# rival slots: baked fresh state; repaint once picks exist
	if not _rivals.is_empty():
		for i in 4:
			_draw_rival(i)

	# division filter: baked PREMIER-selected; repaint when re-selected (or a
	# country without divisions is showing -> washed look stays baked)
	if _div != 0 and _country == "ENGLAND":
		_draw_divisions()

	# DELETE: baked washed; solid (frame 008's identical seleccion chip, cut grown
	# +2px for the bevel shadow) when usable
	if not _rivals.is_empty() and _delete_on != null:
		draw_texture_rect(_delete_on, Rect2(381, 438, 116, 30), false)

	# 4/4 picks: SKIP washes out (disabled), CONTINUE goes hot (frame pretemp_slot4)
	if _rivals.size() == 4:
		if _skip_off != null:
			draw_texture_rect(_skip_off, Rect2(501, 331, 116, 30), false)
		if _continue_hot != null:
			draw_texture_rect(_continue_hot, Rect2(501, 438, 116, 30), false)

	for key_r in [["skip", R_SKIP], ["continue", R_CONTINUE], ["delete", R_DELETE],
			["tab:0", R_TAB_EU], ["tab:1", R_TAB_SA], ["div:0", R_PREMIER],
			["div:1", R_FIRST], ["div:2", R_SECOND], ["div:3", R_THIRD]]:
		if _press == str(key_r[0]):
			draw_rect(key_r[1], C_PRESS, true)


## Kit-panel repaint (country or division changed): white interior, blue country
## title (frame 013 style), the clubs' kits.
func _draw_panel() -> void:
	draw_rect(Rect2(R_PANEL.position + Vector2(2, 2), R_PANEL.size - Vector2(4, 4)), Color.WHITE, true)
	if _country != "":
		_txt(_f12, R_PANEL.position.x, R_PANEL.position.y + 6, _country, C_TITLE_BLUE,
			13, R_PANEL.size.x, true)
	var taken := {_managed_id: true}
	for rv in _rivals:
		taken[int((rv as Dictionary).get("id", -1))] = true
	for i in _country_clubs.size():
		if i >= _kit_cols() * 2:
			break
		var kr := _kit_rect(i)
		var cid := int(_country_clubs[i].get("id", -1))
		var washed: bool = taken.has(cid)
		# frame-rendered patch (013 shadow phase); taken clubs use the frame-proven
		# washed render where one exists, else nano + checker approximation
		var tex2: Texture2D = null
		var need_checker := false
		if washed:
			tex2 = PMChrome.panel_kit(cid, "washed")
			if tex2 == null:
				tex2 = PMChrome.nano_kit(cid)
				need_checker = true
		else:
			tex2 = PMChrome.panel_kit(cid, "panel13")
			if tex2 == null:
				tex2 = PMChrome.nano_kit(cid)
		if tex2 != null:
			draw_texture(tex2, kr.position + Vector2(1, 2))
			if need_checker and _checker != null:
				draw_texture_rect(_checker, kr, true)
		if _press == "kit:%d" % i:
			draw_rect(kr, C_PRESS, true)


## One rival slot repaint (state textures cut from frame 013; digits + picked club
## names with the PROMAN rasters).
func _draw_rival(i: int) -> void:
	var y: float = ROW_Y[i]
	var active := i == _rivals.size()
	var filled := i < _rivals.size()
	var on := active or filled
	var head: Texture2D = _riv_head["on" if on else "off"]
	var bar: Texture2D = _riv_bar["on" if on else "off"]
	var badge: Texture2D = _riv_badge["on" if active or filled else "off"]
	if head != null:
		draw_texture_rect(head, Rect2(RIV_X, y, RIV_W, 15), false)
	for b in 2:
		if bar != null:
			draw_texture_rect(bar, Rect2(RIV_X, y + 17 + b * 16, RIV_W, 14), false)
	if badge != null:
		draw_texture_rect(badge, Rect2(RIV_X + RIV_W, y, BADGE_W, 49), false)
	_txt(_f14, RIV_X + RIV_W, y + 15, str(i + 1),
		C_DIGIT_ON if active or filled else C_DIGIT_OFF, 15, BADGE_W, true)
	if filled:
		# frame truth (pretemp_slot1..4): line 1 = the rival club, line 2 = the
		# VENUE STADIUM (own ground iff the rival's engine AV is lower — that is
		# how the original tells you home from away), both centred navy
		_txt(_f10, RIV_X, y + 18, PMChrome.title_case_name(str(_rivals[i].get("name", ""))),
			C_FILL_TEXT, 10, RIV_W, true)
		_txt(_f10, RIV_X, y + 34, str(_rivals[i].get("venue_stadium", "")),
			C_FILL_TEXT, 10, RIV_W, true)


## Division filter repaint (selection moved off PREMIER): clean chips + labels,
## red inner border + yellow label on the selected one (frame 013 style).
func _draw_divisions() -> void:
	var divs := [R_PREMIER, R_FIRST, R_SECOND, R_THIRD]
	var caps := ["PREMIER", "FIRST", "SECOND", "THIRD"]
	for i in divs.size():
		if i >= _leagues.size():
			break
		var r: Rect2 = divs[i]
		if _div_chip != null:
			draw_texture_rect(_div_chip, r, false)
		if i == _div:
			# frame-measured inset (9,3)-(102,21) relative to the button
			draw_rect(Rect2(r.position + Vector2(9, 3), Vector2(94, 19)), C_SEL_BORDER, false)
			draw_rect(Rect2(r.position + Vector2(10, 4), Vector2(92, 17)), C_SEL_BORDER, false)
		_txt(_f12, r.position.x, r.position.y + 5, caps[i],
			C_SEL_TEXT if i == _div else C_UNSEL_TEXT, 13, r.size.x, true)
