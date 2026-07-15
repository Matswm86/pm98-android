extends Control
class_name MatchOptions
## PM98 MATCH OPTIONS — the hub's dropdown settings dialog, rebuilt to the REAL modal
## with all four tabs live (MATCH / GRAPHICS / CAMERAS / SOUND).
##
## Every tab panel is the original's own frame, cut verbatim at the identical modal
## bbox from the live captures (screenshots/wine-captures-2026-07-12/
## dropdown_matchoptions_{match,graphics,cameras,sound}.png ->
## art/screens/matchflow/mo_modal{,_graphics,_cameras,_sound}.png, baked by
## tools/re/build_match_flow_chrome_from_frames.py). Switching a tab swaps the sprite,
## so the active-tab highlight (baked red per capture) is correct for free.
##
## Structure of the modal (frame-measured):
##   MATCH tab   -> the VIEW-MODE row WATCH/HIGHLIGHTS/BRIEF/RESULTS (the real, functional
##                  choice) over the preview. This row exists ONLY on the MATCH tab; the
##                  other tabs' panels fill that space.
##   GRAPHICS tab-> SKY/BOARDS/SHADOWS ON toggles + PITCH DETAIL (HIGH/MED/LOW/MIN) +
##                  STADIUM DETAIL (HIGH/MED/LOW).
##   CAMERAS tab -> STATIC CAMERAS diagram (display), AUTO/FREE camera buttons + the same
##                  PITCH/STADIUM DETAIL (shared graphics-quality settings).
##   SOUND tab   -> FX/AMBIENT/COMMENTS ON toggles.
##   All tabs    -> the tab row MATCH/GRAPHICS/CAMERAS/SOUND + CANCEL / OK.
##
## The view-mode row's rects are corroborated by the reversed controller FUN_004e2630
## (docs/re/match_view_re.md: 98x25 buttons @ y100, panel-local x 5/109/214/317). The
## per-tab GRAPHICS/CAMERAS/SOUND sub-control rects were NOT reversed by the RE, so they
## are frame-measured from the captures (the pixels are the source; see the spec
## tools/re/specs/match_flow_chrome_samples.json -> match_options.*_controls).
##
## HONESTY — the graphics / camera / sound controls are honest NO-OPs at runtime.
## Every one configures PM98's 3D/positional match engine or its match audio, and BOTH
## are absent from the source on hand (the 3D Actua `.p3d` model data is on neither the
## disc nor the .rar; no match audio is played by the built views). So the dialog tracks
## and PERSISTS each choice exactly like the original's MANAGER.INI, but there is no 3D
## view / match-audio for it to change. Nothing is fabricated. Only the view-mode choice
## (MATCH tab) has a live consumer (Main._open_match). The rich BRIEF feed + the 3D view
## are unblocked only by finishing the M5 positional-engine RE (docs/re/match_view_re.md).
##
## Settings-dialog semantics: a control tap SELECTS/TOGGLES locally (highlight). OK
## confirms + persists the whole block (emits confirmed(mode, settings)); CANCEL discards.

signal confirmed(mode: String, settings: Dictionary)   # OK: persist mode + control block
signal cancelled                                        # CANCEL / dismiss: no change

const W := 640
const H := 480

# Modal sprite anchor (cut offset; tools/re/specs/match_flow_chrome_samples.json).
const MODAL_XY := Vector2(98, 116)

# Tabs (index -> name). The MATCH tab carries the functional view-mode row.
const TABS := ["match", "graphics", "cameras", "sound"]

# --- frame-measured hit-rects (absolute 640x480 design space) --------------
# Shared four-column x-grid used by both the view-mode row and the tab row.
const COL_X := {"watch": 116, "highlights": 220, "brief": 325, "results": 428,
	"match": 116, "graphics": 220, "cameras": 325, "sound": 428}
const COL_W := 97
const VIEW_Y := Vector2(279, 297)   # view-mode row (MATCH tab only)
const TAB_Y := Vector2(312, 330)    # tab row (all tabs)
const BOT_Y := Vector2(342, 370)    # CANCEL / OK row (all tabs)
const CANCEL := Vector2(323, 102)   # x, w
const OK := Vector2(430, 102)

# view-mode order + the reversed source rects (panel-local), kept for the record.
const MODES := ["watch", "highlights", "brief", "results"]
const SRC_RECTS := [Rect2(5, 100, 98, 25), Rect2(109, 100, 98, 25),
	Rect2(214, 100, 98, 25), Rect2(317, 100, 98, 25)]
const DEFAULT_SEL := 2   # BRIEF (the user's default play mode)

# Per-tab control rects (frame-measured; absolute design space). See class doc + spec.
const GFX_TOGGLES := {   # ON/OFF toggles (default ON)
	"gfx_sky": Rect2(191, 190, 44, 20), "gfx_boards": Rect2(191, 230, 44, 20),
	"gfx_shadows": Rect2(191, 270, 44, 20),
}
const PITCH := {         # PITCH DETAIL radio (default high)
	"high": Rect2(418, 193, 48, 23), "med": Rect2(464, 193, 48, 23),
	"low": Rect2(418, 226, 48, 23), "min": Rect2(464, 226, 48, 23),
}
const STADIUM := {       # STADIUM DETAIL radio (default high)
	"high": Rect2(398, 266, 46, 22), "med": Rect2(446, 266, 44, 22),
	"low": Rect2(492, 266, 40, 22),
}
const CAM := {           # camera-mode buttons (default static = neither)
	"auto": Rect2(122, 270, 46, 20), "free": Rect2(178, 270, 60, 20),
}
const SND_TOGGLES := {   # ON/OFF toggles (default ON)
	"snd_fx": Rect2(181, 281, 44, 20), "snd_ambient": Rect2(299, 281, 44, 20),
	"snd_comments": Rect2(427, 281, 44, 20),
}

# Default control block (mirrors the baked ON/HIGH/static resting state).
const DEFAULTS := {
	"gfx_sky": true, "gfx_boards": true, "gfx_shadows": true,
	"pitch_detail": "high", "stadium_detail": "high",
	"snd_fx": true, "snd_ambient": true, "snd_comments": true,
	"camera_mode": "static",
}

const C_DIM := Color(0.02, 0.03, 0.07, 0.55)
const C_PRESS := Color(1, 1, 1, 0.22)
const C_SEL := Color(1.0, 0.82, 0.20)          # amber selection border
const C_OFF_FILL := Color(0.05, 0.05, 0.08)    # painted over an ON plate when OFF
const C_OFF_TEXT := Color(0.85, 0.25, 0.22)    # the original's OFF is red
# Honest source-status note shown when HIGHLIGHTS (3D) is tapped.
const HL_NOTE := "HIGHLIGHTS: 3D engine. The Actua .p3d model data is absent from the PM98 disc and the .rar, so it cannot be ported."

var _tabtex: Array = []   # Texture2D per tab index
var _tab := 0             # active tab index
var _sel := DEFAULT_SEL   # view-mode index (MATCH tab)
var _s := {}              # live control block (seeded by setup)
var _press := ""
var _note := ""


func _ready() -> void:
	for name in TABS:
		var rel := "mo_modal.png" if name == "match" else "mo_modal_%s.png" % name
		_tabtex.append(load("res://art/screens/matchflow/%s" % rel))
	if _s.is_empty():
		_s = DEFAULTS.duplicate()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	queue_redraw()


## Open the dialog on the MATCH tab, showing the stored view mode + control block.
func setup(current_mode: String, settings: Dictionary = {}) -> void:
	var i := MODES.find(current_mode)
	_sel = i if i >= 0 else DEFAULT_SEL
	_s = DEFAULTS.duplicate()
	for k in settings:
		if _s.has(k):
			_s[k] = settings[k]
	_tab = 0
	_note = ""
	queue_redraw()


# ---- hit-testing ---------------------------------------------------------

## Rect for a shared-grid button at row y-span `yspan`.
func _col_rect(name: String, yspan: Vector2) -> Rect2:
	return Rect2(COL_X[name], yspan.x, COL_W, yspan.y - yspan.x)


## Rect for a named hit target in the 640x480 design space ("" -> empty rect).
func _rect(name: String) -> Rect2:
	if VIEW.has(name):
		return _col_rect(name, VIEW_Y)
	if name == "cancel":
		return Rect2(CANCEL.x, BOT_Y.x, CANCEL.y, BOT_Y.y - BOT_Y.x)
	if name == "ok":
		return Rect2(OK.x, BOT_Y.x, OK.y, BOT_Y.y - BOT_Y.x)
	return Rect2()

# Legacy alias so existing tests keep hit-testing the view-mode buttons by name.
const VIEW := {"watch": 0, "highlights": 1, "brief": 2, "results": 3}


## Which target a design-space point hits ("" if none). Namespaced so the router knows
## what a hit means: tab:<name>, view:<mode>, gfx_*, pitch:<q>, stad:<q>, cam:<m>, snd_*.
func _hit(d: Vector2) -> String:
	# tab row + CANCEL/OK are live on every tab
	for name in TABS:
		if _col_rect(name, TAB_Y).has_point(d):
			return "tab:" + name
	if _rect("cancel").has_point(d):
		return "cancel"
	if _rect("ok").has_point(d):
		return "ok"
	# per-tab interactive controls
	match _tab:
		0:
			for m in MODES:
				if _col_rect(m, VIEW_Y).has_point(d):
					return m   # bare mode name = the view-mode row (test-compatible)
		1:
			for k in GFX_TOGGLES:
				if (GFX_TOGGLES[k] as Rect2).has_point(d):
					return k
			for q in PITCH:
				if (PITCH[q] as Rect2).has_point(d):
					return "pitch:" + q
			for q in STADIUM:
				if (STADIUM[q] as Rect2).has_point(d):
					return "stad:" + q
		2:
			for m in CAM:
				if (CAM[m] as Rect2).has_point(d):
					return "cam:" + m
			for q in PITCH:
				if (PITCH[q] as Rect2).has_point(d):
					return "pitch:" + q
			for q in STADIUM:
				if (STADIUM[q] as Rect2).has_point(d):
					return "stad:" + q
		3:
			for k in SND_TOGGLES:
				if (SND_TOGGLES[k] as Rect2).has_point(d):
					return k
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
	else:
		var rel := _hit(d)
		if rel != "" and rel == _press:
			_activate(rel)
		_press = ""
	queue_redraw()


## Route a confirmed tap. Tab taps switch tab. On the MATCH tab a mode tap SELECTS the
## view mode (radio). GRAPHICS/CAMERAS/SOUND control taps toggle/select their (persisted,
## honest no-op) settings. OK confirms + persists the whole block; CANCEL discards.
func _activate(target: String) -> void:
	_note = ""
	if target.begins_with("tab:"):
		_tab = TABS.find(target.substr(4))
		return
	if target.begins_with("pitch:"):
		_s["pitch_detail"] = target.substr(6)
		return
	if target.begins_with("stad:"):
		_s["stadium_detail"] = target.substr(5)
		return
	if target.begins_with("cam:"):
		var m := target.substr(4)
		# a second tap on the active camera button releases back to STATIC (the default)
		_s["camera_mode"] = "static" if _s.get("camera_mode") == m else m
		return
	if GFX_TOGGLES.has(target) or SND_TOGGLES.has(target):
		_s[target] = not bool(_s.get(target, true))
		return
	match target:
		"watch", "highlights", "brief", "results":
			_sel = MODES.find(target)   # select the view mode only
			if target == "highlights":
				_note = HL_NOTE
		"ok":
			var m: String = MODES[_sel]
			if m == "highlights":
				_note = HL_NOTE          # 3D .p3d absent — can't confirm HIGHLIGHTS
			else:
				confirmed.emit(m, _s.duplicate())
		"cancel":
			cancelled.emit()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	var tex: Texture2D = _tabtex[_tab] if _tab < _tabtex.size() else null
	if tex != null:
		draw_texture(tex, MODAL_XY)
	match _tab:
		0: _draw_match_tab()
		1: _draw_graphics_tab()
		2: _draw_cameras_tab()
		3: _draw_sound_tab()
	# press feedback on the held target
	if _press != "":
		var pr := _press_rect(_press)
		if pr.size.x > 0:
			draw_rect(pr, C_PRESS, true)
	# honest 3D-absent note (HIGHLIGHTS view mode)
	if _note != "":
		var f := PMChrome.font("10")
		draw_rect(Rect2(110, 150, 420, 60), Color(0.03, 0.05, 0.12, 0.92), true)
		draw_rect(Rect2(110, 150, 420, 60), Color(0.4, 0.5, 0.7), false, 1.0)
		_wrap(f, Vector2(118, 156), 404, _note, Color(0.85, 0.9, 1.0), 12)


func _draw_match_tab() -> void:
	# amber selection border around the currently-chosen view mode.
	var sr := _col_rect(MODES[_sel], VIEW_Y)
	draw_rect(sr.grow(2.0), C_SEL, false, 2.0)
	draw_rect(sr, Color(C_SEL.r, C_SEL.g, C_SEL.b, 0.18), true)


func _draw_graphics_tab() -> void:
	for k in GFX_TOGGLES:
		_draw_toggle(GFX_TOGGLES[k], bool(_s.get(k, true)))
	_draw_radio(PITCH, str(_s.get("pitch_detail", "high")))
	_draw_radio(STADIUM, str(_s.get("stadium_detail", "high")))


func _draw_cameras_tab() -> void:
	var m := str(_s.get("camera_mode", "static"))
	if CAM.has(m):
		_draw_border(CAM[m])   # STATIC (default) draws no override — matches the baked look
	_draw_radio(PITCH, str(_s.get("pitch_detail", "high")))
	_draw_radio(STADIUM, str(_s.get("stadium_detail", "high")))


func _draw_sound_tab() -> void:
	for k in SND_TOGGLES:
		_draw_toggle(SND_TOGGLES[k], bool(_s.get(k, true)))


## An ON/OFF toggle: baked plate already reads ON, so only OFF needs an override —
## paint over the ON glyph and draw the original's red "OFF".
func _draw_toggle(r: Rect2, on: bool) -> void:
	if on:
		return
	var inner := r.grow(-4.0)
	draw_rect(inner, C_OFF_FILL, true)
	var f := PMChrome.font("10")
	if f != null:
		var sz := 10
		var w := f.get_string_size("OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var p := Vector2(inner.get_center().x - w * 0.5, inner.get_center().y - f.get_height(sz) * 0.5 + f.get_ascent(sz))
		draw_string(f, p, "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, sz, C_OFF_TEXT)


## Amber selection border around the chosen cell of a radio group.
func _draw_radio(group: Dictionary, sel: String) -> void:
	if group.has(sel):
		_draw_border(group[sel])


func _draw_border(r: Rect2) -> void:
	draw_rect(r.grow(1.0), C_SEL, false, 2.0)
	draw_rect(r, Color(C_SEL.r, C_SEL.g, C_SEL.b, 0.16), true)


## Design-space rect for a held target, for the press flash.
func _press_rect(name: String) -> Rect2:
	if name.begins_with("tab:"):
		return _col_rect(name.substr(4), TAB_Y)
	if name.begins_with("pitch:"):
		return PITCH.get(name.substr(6), Rect2())
	if name.begins_with("stad:"):
		return STADIUM.get(name.substr(5), Rect2())
	if name.begins_with("cam:"):
		return CAM.get(name.substr(4), Rect2())
	if GFX_TOGGLES.has(name):
		return GFX_TOGGLES[name]
	if SND_TOGGLES.has(name):
		return SND_TOGGLES[name]
	if VIEW.has(name):
		return _col_rect(name, VIEW_Y)
	return _rect(name)


func _wrap(f: Font, pos: Vector2, width: float, t: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var lh := f.get_height(sz) + 1
	var line := ""
	var y := pos.y
	for word in t.split(" "):
		var trial := word if line == "" else line + " " + word
		if f.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width and line != "":
			draw_string(f, Vector2(pos.x, y + f.get_ascent(sz)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			line = word
			y += lh
		else:
			line = trial
	if line != "":
		draw_string(f, Vector2(pos.x, y + f.get_ascent(sz)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- letterbox scaling ---------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s
