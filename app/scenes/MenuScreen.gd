extends Control
class_name MenuScreen
## PM98 MAIN MENU (MENUPRINCIPAL) screen — the in-career management hub.
##
## The static chrome (the 4 quadrants of colour-coded caption bars + the 12 picture
## icons + the INFORMATION / MANAGER / TRANSFER MARKET / FINANCES section labels + the
## marble background with the BARRA quadrant cross + the EXIT / SAVE GAME / NEWS /
## CONTINUE control bar + the central club CIRCLE frame and its slot boxes) is the REAL
## game's MENUPRINCIPAL, taken from the original 640x480 screen (data/pm98-refs/
## real-gallery/ma_6.png) into art/screens/menu_bg.png with only the club-specific data
## (header text + circle text + the two crests) cleared. The reversed coordinates that
## produced this layout are in docs/re/menu_screen_re.md (FUN_005469c0).
##
## This node blits that chrome, then draws the DYNAMIC layer on top: the shared PMChrome
## header (manager / club / date / league / week) and the central circle's live slots
## (league position, manager, managed club + crest, next opponent + crest, opponent
## manager / venue, CPU). Taps over an icon, its caption bar or a control button emit
## `action_selected(action)` (Main routes it). Native 640x480; scales to fit (NEAREST).

signal action_selected(action: String)
## Every queued alert box has been answered and the hub is live again.
signal alerts_cleared
## The EXIT confirm's Yes ("Do you want to leave the championship ?" — witnessed on
## hub EXIT 2026-07-27, wine-captures-2026-07-27-hubexit): leave to the title screen.
signal exit_confirmed

const W := 640
const H := 480

const C_TITLE := Color(0.96, 0.98, 1.0)
const C_DIM := Color(0.80, 0.86, 0.95)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.22)

# Reversed icon hit areas: action -> the icon PICTURE rect (pos, size) from the two
# FUN_00436fb0(x,y) points (docs/re/menu_screen_re.md). Non-overlapping; each sits on the
# visible icon in menu_bg.
const ICON_HITS := {
	"results": Rect2(7, 71, 86, 60),        # MARCA
	"table": Rect2(206, 93, 87, 72),        # CLASI
	"fixtures": Rect2(10, 147, 77, 66),     # CALEN
	"lineup": Rect2(535, 70, 93, 61),       # ALINE
	"tactics": Rect2(345, 101, 93, 63),     # TACTI
	"opponent": Rect2(536, 151, 85, 60),    # RIVAL
	"buy": Rect2(7, 327, 85, 76),           # FICHA  (caption "TRANSFERS")
	"sell": Rect2(184, 353, 101, 78),       # VENDE  (caption "PLAYERS")
	"staff": Rect2(6, 403, 72, 62),         # EMPLE
	"finance": Rect2(559, 328, 78, 80),     # CAJA
	"board": Rect2(361, 370, 86, 61),       # DECIS  (caption "BOARD ROOM")
	"stadium": Rect2(543, 415, 95, 61),     # ESTAD  (caption "GROUND")
}
# The colour caption bar beside each icon (measured off ma_6). Added to each icon's hit
# area so a tap on the visible label works too — bigger, unambiguous mobile targets.
const BAR_HITS := {
	"results": Rect2(95, 84, 132, 26),
	"table": Rect2(100, 127, 132, 26),
	"fixtures": Rect2(88, 171, 122, 26),
	"lineup": Rect2(418, 84, 122, 26),
	"tactics": Rect2(428, 127, 114, 26),
	"opponent": Rect2(408, 171, 132, 26),
	"buy": Rect2(50, 343, 132, 26),
	"sell": Rect2(85, 385, 114, 26),
	"staff": Rect2(20, 428, 165, 26),
	"finance": Rect2(446, 344, 114, 26),
	"board": Rect2(432, 387, 178, 26),
	"stadium": Rect2(350, 428, 132, 26),
}
# Control-bar buttons (measured off ma_6: y~246, h~38).
const CTRL_HITS := {
	"exit": Rect2(6, 246, 80, 38),
	"save": Rect2(90, 246, 114, 38),
	"news": Rect2(430, 246, 118, 38),
	"continue": Rect2(552, 246, 86, 38),
}

# Central club CIRCLE (design space; boxes baked in menu_bg). The original
# stacks the HOME side on top and styles the PLAYER's half dark-with-white-ink,
# the CPU half pale-with-black-ink (witnessed: orig/73 + promanager 13 away =
# pale top; ma_6 home = dark top). menu_bg bakes the away arrangement; the
# hub/circle_home overlay (cut from ma_6) repaints the circle for home. The
# controller chips sit outermost ("CPU" / "PL n" = the entry-screen player
# slot, witnessed "PL 1" across Premier AND 3rd-Div careers), the ► pointer
# rides the player's manager bar. All anchors frame-measured off orig/73.
const CIRCLE_HOME_POS := Vector2(195, 168)
const ARROW_X := 238.0
const ARROW_Y_TOP := 196.0                 # beside the top manager bar (home)
const ARROW_Y_BOT := 302.0                 # beside the bottom manager bar (away)
const CHIP_CELL := [296, 49]               # chip text cell (x0, w)
const MGR_CELL := [250, 142]               # manager bar text cell
const CLUB_CX := 323                       # club band ink centre (both bands)
const CHIP_BASE_TOP := 185
const CHIP_BASE_BOT := 342
const MGR_BASE_TOP := 211
const MGR_BASE_BOT := 317
const CLUB_BASE_TOP := 240
const CLUB_BASE_BOT := 286
# Witnessed kit boxes: top x195-244 y200-264, bottom x395-444 y255-318. The
# original's free-floating 50x65 hub kit render is un-extracted (the panel
# bank bakes a white panel behind it, unusable over the circle); the kits
# sheet's figure content (bbox x1..45 y3..59 on the exact decode) draws 1:1
# centred on the witnessed box (flagged approximation, shield-card precedent).
const KIT_VIEW := Rect2(1, 3, 45, 57)      # the figure's content bbox
const KIT_TOP_POS := Vector2(197, 204)     # 45x57 centred in x195..244 y200..264
const KIT_BOT_POS := Vector2(397, 259)     # 45x57 centred in x395..444 y255..318
const C_INK_CPU := Color8(0, 0, 0)         # CPU half: black on the pale boxes
const C_INK_PLAYER := Color8(255, 255, 255)  # player half: white on the dark boxes

var _bg: Texture2D
var _bezel: Texture2D            # marble fill for the landscape letterbox margins
var _circle_home: Texture2D      # ma_6 circle overlay (player-home arrangement)
var _arrow_tex: Texture2D        # the player-side ► pointer (cut from orig/73)
var _f8: Font
var _f10: Font
var _f12: Font
var _f14: Font
var _fcal: Font                  # calend12: the circle manager-name face
var _kit_tex: Texture2D          # the managed club's kit, or null if no art for the id

var _club: String = ""
var _club_id: int = -1
var _league: String = ""        # league name (header right plaque)
var _manager_name: String = ""  # the real manager name (SELECCION); header left + circle
var _season: String = ""
var _cash: int = 0
var _position: String = ""      # "1st" / "2nd" ...
var _week: int = 0
var _opp_name: String = ""      # next-fixture opponent (circle)
var _opp_id: int = -1
var _opp_manager: String = ""   # next-fixture opponent manager (circle), if known
var _is_home: bool = true
var _opp_tex: Texture2D
var _press: String = ""        # action currently held down (for the highlight)

# Top-edge dropdown bar (2026-07-12 live captures hub_dropdown_bar.png /
# dropdown_matchoptions_*.png / dropdown_options_panel.png): hovering/tapping
# the top edge slides down the PREMIER 98 bar; its MONITOR icon opens MATCH
# OPTIONS (emitted as the "match_options" action), the HEADPHONES icon opens
# the OPTIONS panel (OptionsPanel). The bar stays bright over the dimmed hub
# (witnessed in the options capture). Slide duration is an approximation (the
# capture poll can't time it); TRANSITIONS OFF makes it instant.
const DROP_H := 41.0
const R_DROP_MON := Rect2(534, 6, 33, 32)   # monitor icon (bar-local, frame-measured)
const R_DROP_HP := Rect2(592, 6, 30, 30)    # headphones icon (bar-local)
# ANDROID TOUCH ADAPTATION (owner-reported, 2026-07-24): on a phone the very top edge of
# the screen belongs to the system notification shade, so both the reveal tap AND the
# bar's own icons were being swallowed by it. The bar therefore RESTS this far below the
# top edge instead of flush against it, and the reveal band sits below the shade zone.
# At the worst-case 4:3 pillarbox on a 1080-tall phone the scale is 2.25, so design y36
# is ~81 real px and y48+6 (the monitor icon top) is ~121 px — clear of the 24dp inset.
# Nothing about the bar's own art or its icon geometry changes; only where it is parked.
const TOUCH_DROP_Y := 48.0
# Tapping this band reveals the bar (the original slides it down on top-edge hover; the
# top band carries no active hub controls, verified — all ICON/BAR hits are y>=70).
const R_DROP_TRIGGER := Rect2(0, 36, W, 32)
var _drop_tex: Texture2D
var _drop_open := false
var _drop_anim := 0.0            # 0 = hidden, 1 = fully down
var _drop_press := ""
var _drop_just_opened := false   # swallow the release that completes the opening tap
var _options: Control = null     # active OptionsPanel modal

# The modal "PREMIER MANAGER 98" alert box (PMAlert; docs/re/alert_box_re.md).
# While a message shows, the hub behind is palette-dimmed and input is modal.
var _alert_queue: PackedStringArray = []
var _alert_tex: ImageTexture       # finished box (normal OK state)
var _alert_tex_hot: ImageTexture   # finished box with the OK button held
var _alert_msg: String = ""        # the message currently on screen ("" = none)
var _alert_box: Rect2i             # design-space rect of the current box
var _alert_anim: float = 1.0       # grow-in progress 0..1 (case 5/6 zoom)
var _alert_ok_held := false
var _bg_dim: Texture2D             # menu_bg through the exact dim LUT

# The EXIT confirm — the SAME "Do you want to leave the championship ?" Yes/No box the
# in-match EXIT raises (LeaveConfirm.MSG), WITNESSED on hub EXIT 2026-07-27 over the
# palette-dimmed hub (screenshots/wine-captures-2026-07-27-hubexit: hub_exit_confirm
# shows the LUT dim, hub_exit_yes_title shows Yes -> the TITLE screen).
var _confirm_tex: ImageTexture = null
var _confirm_box: Rect2i
var _confirm_held := ""            # "yes" / "no" / ""


func _ready() -> void:
	_bg = load("res://art/screens/menu_bg.png")
	_bg_dim = load("res://art/screens/alert/menu_bg_dim.png")
	_bezel = load("res://art/screens/fondo_marble.png")
	if ResourceLoader.exists("res://art/screens/hub/circle_home.png"):
		_circle_home = load("res://art/screens/hub/circle_home.png")
	if ResourceLoader.exists("res://art/screens/hub/arrow.png"):
		_arrow_tex = load("res://art/screens/hub/arrow.png")
	if ResourceLoader.exists("res://art/screens/dropdown/bar.png"):
		_drop_tex = load("res://art/screens/dropdown/bar.png")
	_f8 = load("res://art/fonts/proman8.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f14 = load("res://art/fonts/proman14.fnt")
	_fcal = PMChrome.font("calend12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the live career chrome (club / league / season / cash / position + the next-fixture
## opponent + week + the opponent manager for the circle's lower slot), repaint.
func setup(club: String, league := "", season := "", cash := 0, position := "", club_id := -1,
		week := 0, opp_name := "", opp_id := -1, is_home := true, manager_name := "",
		opp_manager := "") -> void:
	_club = club
	_league = league
	_manager_name = manager_name
	_season = season
	_cash = cash
	_position = position
	_week = week
	_opp_name = opp_name
	_opp_manager = opp_manager
	_is_home = is_home
	if club_id != _club_id:
		_club_id = club_id
		var path := "res://art/kits/%d.png" % club_id
		_kit_tex = load(path) if club_id >= 0 and ResourceLoader.exists(path) else null
	if opp_id != _opp_id:
		_opp_id = opp_id
		var op := "res://art/kits/%d.png" % opp_id
		_opp_tex = load(op) if opp_id >= 0 and ResourceLoader.exists(op) else null
	queue_redraw()


## Raise the original's modal "PREMIER MANAGER 98" alert box over the hub (frames
## 093/094/149) — signing / rejection / save feedback. Messages queue; answering
## OK pops the next one, which grows in again (the 094 replacement-alert zoom).
func alert(msg: String) -> void:
	if msg.strip_edges() == "":
		return
	_alert_queue.append(msg)
	if _alert_tex == null:
		_next_alert()


func alert_active() -> bool:
	return _alert_tex != null


## Raise the witnessed hub-EXIT confirm: the leave-championship Yes/No box over the
## LUT-dimmed hub. Yes emits exit_confirmed; No dismisses back to the live hub.
func confirm_exit() -> void:
	if _confirm_tex != null:
		return
	_confirm_tex = ImageTexture.create_from_image(
		PMAlert.render(LeaveConfirm.MSG, false, true))
	_confirm_box = PMAlert.box_rect(LeaveConfirm.MSG)
	_confirm_held = ""
	queue_redraw()


## True while ANY modal box (alert queue or the EXIT confirm) dims the hub.
func _modal_up() -> bool:
	return _alert_tex != null or _confirm_tex != null


func _next_alert() -> void:
	if _alert_queue.is_empty():
		var was_up := _alert_tex != null
		_alert_tex = null
		_alert_tex_hot = null
		_alert_msg = ""
		set_process(false)
		queue_redraw()
		if was_up:
			alerts_cleared.emit()
		return
	var msg := _alert_queue[0]
	_alert_queue.remove_at(0)
	_alert_msg = msg
	_alert_box = PMAlert.box_rect(msg)
	_alert_tex = ImageTexture.create_from_image(PMAlert.render(msg, false))
	_alert_tex_hot = ImageTexture.create_from_image(PMAlert.render(msg, true))
	_alert_ok_held = false
	# FUN_005c5fd0 case 5/6: the box grows from its centre in ~15 steps of >=16ms.
	_alert_anim = 0.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var busy := false
	# alert box grow-in (FUN_005c5fd0 case 5/6)
	if _alert_tex != null and _alert_anim < 1.0:
		_alert_anim = minf(_alert_anim + delta / 0.25, 1.0)
		busy = true
	# dropdown bar slide (instant when TRANSITIONS OFF, like the original)
	var target := 1.0 if _drop_open else 0.0
	var am := get_node_or_null("/root/AudioManager")
	if am != null and not am.transitions_enabled:
		_drop_anim = target
	elif not is_equal_approx(_drop_anim, target):
		var step := delta / 0.18
		_drop_anim = minf(_drop_anim + step, target) if target > _drop_anim \
			else maxf(_drop_anim - step, target)
		busy = true
	if busy:
		queue_redraw()
	else:
		set_process(false)


func _open_drop() -> void:
	_drop_open = true
	_drop_press = ""
	set_process(true)
	queue_redraw()

func _close_drop() -> void:
	_drop_open = false
	_drop_press = ""
	set_process(true)
	queue_redraw()

## Which dropdown target a design-space point hits when the bar is open:
## "mon" (MATCH OPTIONS) / "hp" (audio OPTIONS) / "bar" (dead bar area) / "" (outside).
func _drop_hit(d: Vector2) -> String:
	var b := d - Vector2(0, TOUCH_DROP_Y)   # bar-local (the bar parks at TOUCH_DROP_Y)
	if R_DROP_MON.has_point(b):
		return "mon"
	if R_DROP_HP.has_point(b):
		return "hp"
	if b.y >= 0.0 and b.y <= DROP_H:
		return "bar"
	return ""


## The OK button rect in design space (EXE anchor: bottom-right, w-6 / h-6).
func _alert_ok_rect() -> Rect2:
	return Rect2(_alert_box.position.x + _alert_box.size.x - 45,
		_alert_box.position.y + _alert_box.size.y - 22, 39, 16)


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

## Map a parent-space point to the 640x480 design space.
func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

## The action whose hit rect (control / icon picture / caption bar) contains a
## design-space point, or "".
func _hit(d: Vector2) -> String:
	for a in CTRL_HITS:
		if (CTRL_HITS[a] as Rect2).has_point(d):
			return a
	for a in ICON_HITS:
		if (ICON_HITS[a] as Rect2).has_point(d):
			return a
	for a in BAR_HITS:
		if (BAR_HITS[a] as Rect2).has_point(d):
			return a
	return ""


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		pos = mb.position
		pressed = mb.pressed
		tap = true
	elif e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		pos = st.position
		pressed = st.pressed
		tap = true
	if not tap:
		return
	if _confirm_tex != null:
		# Modal: only the Yes/No cells react (the witnessed leave-championship box).
		var dc := _to_design(pos)
		var hitc := ""
		if PMAlert.yes_rect(LeaveConfirm.MSG).has_point(dc):
			hitc = "yes"
		elif PMAlert.no_rect(LeaveConfirm.MSG).has_point(dc):
			hitc = "no"
		if pressed:
			_confirm_held = hitc
		else:
			if _confirm_held != "" and _confirm_held == hitc:
				var amc := get_node_or_null("/root/AudioManager")
				if amc != null:
					amc.ui_select()
				_confirm_tex = null
				if hitc == "yes":
					exit_confirmed.emit()
			_confirm_held = ""
		queue_redraw()
		return
	if _alert_tex != null:
		# Modal: only the alert's OK button reacts (the original DoModal loop).
		if _alert_anim < 1.0:
			return
		var over := _alert_ok_rect().has_point(_to_design(pos))
		if pressed:
			_alert_ok_held = over
		else:
			if _alert_ok_held and over:
				var am := get_node_or_null("/root/AudioManager")
				if am != null:
					am.ui_select()
				_next_alert()
			_alert_ok_held = false
		queue_redraw()
		return
	var dd := _to_design(pos)
	# --- top dropdown bar: monitor = MATCH OPTIONS, headphones = OPTIONS (audio) ---
	if _drop_open:
		if pressed:
			_drop_press = _drop_hit(dd)
		else:
			# The release that completes the opening tap must NOT immediately re-close.
			if _drop_just_opened:
				_drop_just_opened = false
				_drop_press = ""
				queue_redraw()
				return
			var dh := _drop_hit(dd)
			var dwas := _drop_press
			_drop_press = ""
			_close_drop()
			if dh == dwas and dh == "mon":
				action_selected.emit("match_options")
			elif dh == dwas and dh == "hp":
				action_selected.emit("options_audio")
		queue_redraw()
		return
	if pressed and R_DROP_TRIGGER.has_point(dd):
		_open_drop()
		_drop_just_opened = true
		return
	if pressed:
		_press = _hit(dd)
		queue_redraw()
	else:
		var a := _hit(dd)
		var was := _press
		_press = ""
		queue_redraw()
		if a != "" and a == was:
			action_selected.emit(a)


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, cw := 0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if cw > 0 and w > cw:           # shrink to fit the box rather than clip
		sz = maxi(7, int(floor(sz * cw / w)))
		w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x + (cw - w) * 0.5 if cw > 0 else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, _dc(col))


## Palette-dim a colour while a modal box is up (exact LUT; PMAlert).
func _dc(c: Color) -> Color:
	return PMAlert.dim_color(c) if _modal_up() else c


## Circle slot text: the original's cell centring (x0 + (cell_w - (adv-1)) / 2,
## integer — every witnessed orig/73 + ma_6 slot label fits it exactly).
func _cell_txt(f: Font, cell: Array, baseline: int, t: String, col: Color, sz: int) -> void:
	if f == null or t == "":
		return
	var w := int(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x) - 1
	var px: int = int(cell[0]) + int(maxi(int(cell[1]) - w, 0) * 0.5)
	draw_string(f, Vector2(px, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, PMChrome.dim_col(col))


## Club band text: the original's heavy flat face (un-extracted; approximated by
## double-struck proman12 — witnessed ink centres x323 on both bands, flagged).
func _club_txt(baseline: int, t: String, col: Color) -> void:
	if _f12 == null or t == "":
		return
	var w := int(_f12.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x) + 1
	var px: int = CLUB_CX - int(w * 0.5)
	var c := PMChrome.dim_col(col)
	draw_string(_f12, Vector2(px, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c)
	draw_string(_f12, Vector2(px + 1, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c)


## A side's kit: the kits-sheet front view 1:1 (see KIT_TOP_POS note).
func _kit(tex: Texture2D, pos: Vector2) -> void:
	if tex == null:
		return
	if _modal_up():
		tex = PMAlert.dim_texture(tex)
	draw_texture_rect_region(tex, Rect2(pos, KIT_VIEW.size), KIT_VIEW)


func _draw() -> void:
	# Marble bezel behind the letterboxed 640x480 content (landscape margins).
	if _bezel != null:
		draw_texture_rect(_bezel, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))

	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	var dimmed := _modal_up()

	# The real MENUPRINCIPAL chrome (bars + icons + section labels + circle frame + bg);
	# under the modal alert, the pre-baked exact palette-dim of the same frame.
	var bg := _bg_dim if dimmed and _bg_dim != null else _bg
	if bg != null:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)

	# Header: the hub chrome bakes the REAL title bar / identity block / calendar
	# sheet / plaque (orig/73) — only the live texts + kit draw over it.
	PMChrome.set_dim(dimmed)
	PMChrome.draw_ident_texts(self, _manager_name, _club, _club_id)
	PMChrome.draw_sheet_band_texts(self, _league, _season, _week)

	# Central club circle: HOME side top, player's half dark (see consts block).
	# menu_bg bakes the away arrangement; home blits the ma_6 overlay first.
	var have_opp := _opp_name != ""
	var player_top := have_opp and _is_home
	if player_top and _circle_home != null:
		var ct := PMAlert.dim_texture(_circle_home) if dimmed else _circle_home
		draw_texture(ct, CIRCLE_HOME_POS)
	var top_ink := C_INK_PLAYER if player_top else C_INK_CPU
	var bot_ink := C_INK_CPU if player_top else C_INK_PLAYER
	# db surnames render title-cased ("Ferguson"); the player's name as typed
	# (witnessed lowercase "mwm" on orig/73).
	var opp_mgr_disp := PMChrome.title_case_name(_opp_manager)
	var top_club := _club if player_top else _opp_name
	var top_mgr := _manager_name if player_top else opp_mgr_disp
	var top_kit := _kit_tex if player_top else _opp_tex
	var bot_club := _opp_name if player_top else _club
	var bot_mgr := opp_mgr_disp if player_top else _manager_name
	var bot_kit := _opp_tex if player_top else _kit_tex
	if have_opp:
		_cell_txt(_f8, CHIP_CELL, CHIP_BASE_TOP, "PL 1" if player_top else "CPU", top_ink, 11)
		_cell_txt(_fcal, MGR_CELL, MGR_BASE_TOP, top_mgr, top_ink, 15)
		_club_txt(CLUB_BASE_TOP, top_club, top_ink)
		_kit(top_kit, KIT_TOP_POS)
	_club_txt(CLUB_BASE_BOT, bot_club, bot_ink)
	_kit(bot_kit, KIT_BOT_POS)
	_cell_txt(_fcal, MGR_CELL, MGR_BASE_BOT, bot_mgr, bot_ink, 15)
	_cell_txt(_f8, CHIP_CELL, CHIP_BASE_BOT, "CPU" if player_top else "PL 1", bot_ink, 11)
	if _arrow_tex != null:
		var at := PMAlert.dim_texture(_arrow_tex) if dimmed else _arrow_tex
		draw_texture(at, Vector2(ARROW_X, ARROW_Y_TOP if player_top else ARROW_Y_BOT))
	PMChrome.set_dim(false)

	# Press highlight over the held icon / bar / button (never under the modal).
	if _press != "" and not dimmed:
		var r: Rect2 = ICON_HITS.get(_press, BAR_HITS.get(_press, CTRL_HITS.get(_press, Rect2())))
		if r.size != Vector2.ZERO:
			draw_rect(r, C_HILITE, true)

	if not dimmed:
		_draw_dropdown()

	if dimmed:
		_draw_alert()
		_draw_confirm()


## The top dropdown bar (hub_dropdown_bar.png): hidden by default, revealed by a tap on
## the top edge, and carrying the MONITOR icon (opens MATCH OPTIONS) + HEADPHONES icon
## (opens the audio OPTIONS panel). While open the hub behind is dimmed. When closed a
## faint edge hint marks the pull zone (the original reveals on top-edge hover).
func _draw_dropdown() -> void:
	if _drop_anim <= 0.001:
		# Closed: the pull hint marks the REVEAL BAND, not the screen edge, so the
		# thumb lands where the tap is actually read (see TOUCH_DROP_Y).
		draw_rect(Rect2(R_DROP_TRIGGER.position.x, R_DROP_TRIGGER.end.y - 3,
			R_DROP_TRIGGER.size.x, 3), Color(0.45, 0.55, 0.85, 0.30), true)
		return
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.07, 0.45 * _drop_anim), true)
	# The bar slides from behind the top edge down to its parked TOUCH_DROP_Y.
	var y := TOUCH_DROP_Y - (TOUCH_DROP_Y + DROP_H) * (1.0 - _drop_anim)
	if _drop_tex != null:
		draw_texture(_drop_tex, Vector2(0, y))
	else:
		draw_rect(Rect2(0, y, W, DROP_H), Color(0.05, 0.08, 0.22), true)
	if _drop_press == "mon":
		draw_rect(Rect2(R_DROP_MON.position + Vector2(0, y), R_DROP_MON.size), C_HILITE, true)
	elif _drop_press == "hp":
		draw_rect(Rect2(R_DROP_HP.position + Vector2(0, y), R_DROP_HP.size), C_HILITE, true)


## The modal alert box + its +5,+5 drop shadow. The finished box texture grows in
## from its centre (FUN_005c5fd0 case 5/6). The shadow is an approximation: the
## original remaps the palette per-INDEX in that band, which two RGB frames cannot
## disambiguate (docs/re/alert_box_re.md "Drop shadow") — a 45% black overlay
## matches the observed attenuation; the parity ROI excludes the band.
func _draw_alert() -> void:
	var b := Rect2(_alert_box)
	if _alert_anim >= 1.0:
		draw_rect(Rect2(b.position.x + b.size.x, b.position.y + 5, 5, b.size.y), Color(0, 0, 0, 0.45), true)
		draw_rect(Rect2(b.position.x + 5, b.position.y + b.size.y, b.size.x, 5), Color(0, 0, 0, 0.45), true)
	var tex := _alert_tex_hot if _alert_ok_held else _alert_tex
	if tex == null:
		return
	# ~15 growth steps of the original zoom; each frame draws the box scaled about
	# its centre (the engine StretchBlts the finished dialog the same way).
	var t := clampf(_alert_anim, 0.05, 1.0)
	var c := b.get_center()
	draw_texture_rect(tex, Rect2(c - b.size * t * 0.5, b.size * t), false)


## The EXIT confirm box (witnessed 2026-07-27): the leave-championship Yes/No dialog
## with the alert framework's drop shadow; the held cell gets LeaveConfirm's 20%
## white press feedback.
func _draw_confirm() -> void:
	if _confirm_tex == null:
		return
	var b := Rect2(_confirm_box)
	draw_rect(Rect2(b.position.x + b.size.x, b.position.y + 5, 5, b.size.y), Color(0, 0, 0, 0.45), true)
	draw_rect(Rect2(b.position.x + 5, b.position.y + b.size.y, b.size.x, 5), Color(0, 0, 0, 0.45), true)
	draw_texture(_confirm_tex, Vector2(b.position))
	if _confirm_held != "":
		var r := PMAlert.yes_rect(LeaveConfirm.MSG) if _confirm_held == "yes" \
			else PMAlert.no_rect(LeaveConfirm.MSG)
		draw_rect(r, Color(1, 1, 1, 0.2), true)
