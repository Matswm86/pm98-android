extends Control
class_name PlayerInfoScreen
## PM98 PLAYER INFORMATION (FICHA) popup, rebuilt from the real game's player-info screen
## (screens/player_info_ref.jpg, the FUN_0052e0d0 renderer in MANAGER.EXE). The centred
## white-bordered card the magnifying-glass opens over the LINE-UP / SQUAD: the player's
## BIGFOTO mugshot + name header, the position word, the left identity column (AGE /
## WEIGHT / HEIGHT, NATIONALITY / KIND, ROLE + camrol, STATUS / INSURANCE, club kit), the
## right stat panel (SPEED..MORAL + RATING) with the star-skill strip (HANDLING..SHOOTING),
## and the CONTRACT panel (VALUE / YEARLY WAGE / YEARS LEFT). OK / a tap dismisses it.
##
## WEIGHT + HEIGHT are shown in METRIC (kg / cm) -- the native units PM98 stores them in
## (EQUIPOS Y+3 = kg, Y+2 = cm; the original UI converted to stone/feet via 6.35 kg/stone
## and 30.48 cm/foot, see FUN_0058dd70 / FUN_0058de00). Every field is real decoded data;
## the attr -> card-label mapping is the one confirmed against the Babb reference. Native
## 640x480; scales to fit its parent.
##
## INTERACTIVE: the OK button or a tap on empty space emits `back_pressed`.

signal back_pressed

const W := 640
const H := 480

# Card / panel chrome (read off the reference).
const C_CARD := Color(0.95, 0.96, 0.93)          # white card body
const C_CARD_HI := Color(1.0, 1.0, 1.0)
const C_CARD_LO := Color(0.52, 0.54, 0.56)
const C_AGE := Color(0.46, 0.56, 0.20)           # olive-green AGE box
const C_WEIGHT := Color(0.22, 0.40, 0.66)        # blue WEIGHT box
const C_HEIGHT := Color(0.52, 0.24, 0.26)        # maroon HEIGHT box
const C_IDENT := Color(0.30, 0.46, 0.70)         # NATIONALITY / KIND / STATUS bands
const C_IDENT_LO := Color(0.16, 0.28, 0.50)
const C_ROLEBOX := Color(0.18, 0.34, 0.30)       # dark teal ROLE band
const C_STATP := Color(0.30, 0.52, 0.78)         # blue stat panel
const C_STATCELL := Color(0.62, 0.78, 0.92)      # pale stat value cell
const C_RATING := Color(0.74, 0.82, 0.92)        # RATING value box
const C_SKILL := Color(0.05, 0.06, 0.10)         # black star-skill strip
const C_CONTRACT := Color(0.20, 0.30, 0.50)
const C_OK := Color(0.18, 0.44, 0.26)
const C_OK_HI := Color(0.34, 0.62, 0.40)
const C_LABEL := Color(0.92, 0.95, 1.0)
const C_VAL := Color(0.10, 0.13, 0.22)
const C_GOLD := Color(1.0, 0.86, 0.22)

const KIT_SRC := Rect2(0, 0, 31, 64)
const OK_BTN := Rect2(548, 446, 86, 26)

# attr code -> readable; the confirmed FICHA mapping (Babb reference).
const POS_WORD := {"GK": "GOALKEEPER", "DF": "DEFENDER", "MF": "MIDFIELDER", "FW": "FORWARD"}
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

var _f8: Font
var _f10: Font
var _f12: Font
var _f14: Font
var _f18: Font

var _p: Dictionary = {}
var _club: Dictionary = {}
var _tier: int = 1
var _press := ""


func _ready() -> void:
	_f8 = load("res://art/fonts/proman8.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f18 = load("res://art/fonts/proman18.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the player + his club (for kit/name) + league tier (for value/wage), repaint.
func setup(player: Dictionary, club: Dictionary, tier: int = 1) -> void:
	_p = player
	_club = club
	_tier = maxi(1, tier)
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(pt: Vector2) -> Vector2:
	var s := _scale()
	return (pt - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

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
	var on_ok := OK_BTN.has_point(_to_design(pos))
	if pressed:
		_press = "ok" if on_ok else ""
		queue_redraw()
	else:
		_press = ""
		queue_redraw()
		# OK button or a tap anywhere on the card dismisses (display-screen pattern).
		back_pressed.emit()


# ---- derived values ------------------------------------------------------

func _attrs() -> Dictionary:
	var a: Variant = _p.get("attrs", {})
	return a if a is Dictionary else {}

func _attr(key: String) -> int:
	var v: Variant = _attrs().get(key)
	return int(v) if v != null else 0

## Overall rating == the squad-screen AV (mean of the 8 outfield-relevant attrs).
func _rating() -> int:
	var a := _attrs()
	var sum := 0.0
	var n := 0
	for k in AVG_KEYS:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0

## FITNESS / MORAL are dynamic form, not static attrs (handoff). Use the live career
## fields when present, else a match-fit / settled default (a freshly loaded squad).
func _fitness() -> int:
	return clampi(int(_p.get("fitness", 99)), 0, 99)

func _moral() -> int:
	return clampi(int(_p.get("morale", _p.get("moral", 85))), 0, 99)


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, align := 0, box_w := 0.0) -> void:
	PMChrome.text(self, f, x, y_top, s, col, sz, align, box_w)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.10, 0.86), true)   # dim the screen behind
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# The white card.
	PMChrome.bevel(self, Rect2(2, 2, W - 4, H - 4), C_CARD, C_CARD_HI, C_CARD_LO, 2.0)

	_draw_header()
	_draw_left_column()
	_draw_stat_panel()
	_draw_skill_strip()
	_draw_contract()
	_draw_ok()


## Blue title bar: the BIGFOTO mugshot (left), then the name; the position word below.
func _draw_header() -> void:
	var bar := Rect2(8, 8, W - 16, 50)
	PMChrome.bevel(self, bar, PMChrome.C_BAR, PMChrome.C_BAR_HI, PMChrome.C_BAR_LO)

	# Mugshot frame + photo (blank frame when photo-less, faithful to the original).
	var frame := Rect2(12, 11, 38, 44)
	PMChrome.bevel(self, frame, Color(0.10, 0.16, 0.30), Color(0.30, 0.40, 0.60), Color(0.04, 0.08, 0.18))
	var face := PMChrome.face(_p.get("photoId"))
	if face != null:
		var tw := float(face.get_width())
		var th := float(face.get_height())
		var sc: float = min((frame.size.x - 4) / tw, (frame.size.y - 4) / th)
		var fw := tw * sc
		var fh := th * sc
		draw_texture_rect(face, Rect2(frame.position.x + (frame.size.x - fw) * 0.5,
			frame.position.y + (frame.size.y - fh) * 0.5, fw, fh), false)

	var name := str(_p.get("name", "?"))
	_txt(_f18, 60, 16, name.to_upper(), PMChrome.C_TITLE, 20, 0, W - 80)
	var word := str(POS_WORD.get(str(_p.get("pos", "")), ""))
	if word == "" and _p.get("isGK", false):
		word = "GOALKEEPER"
	_txt(_f12, 60, 40, word, Color(0.74, 0.84, 1.0), 13)


## Left identity column: AGE / WEIGHT / HEIGHT, NATIONALITY / KIND, ROLE, STATUS /
## INSURANCE, the club kit + name. Metric weight/height.
func _draw_left_column() -> void:
	var x := 12.0
	var w := 300.0

	# Row 1: AGE | WEIGHT | HEIGHT (metric).
	var bw := (w - 8) / 3.0
	var age := str(int(_p.get("age", 0)))
	var hcm: Variant = _p.get("heightCm")
	var wkg: Variant = _p.get("weightKg")
	var h_s := ("%d cm" % int(hcm)) if hcm != null else "-"
	var w_s := ("%d kg" % int(wkg)) if wkg != null else "-"
	_stat_box(Rect2(x, 66, bw, 38), C_AGE, "AGE", age)
	_stat_box(Rect2(x + bw + 4, 66, bw, 38), C_WEIGHT, "WEIGHT", w_s)
	_stat_box(Rect2(x + 2 * (bw + 4), 66, bw, 38), C_HEIGHT, "HEIGHT", h_s)

	# Row 2: NATIONALITY | KIND.
	var hw := (w - 6) / 2.0
	var nat := str(_p.get("nationality", "")).capitalize() if _p.get("nationality") else "England"
	_band_box(Rect2(x, 110, hw, 34), "NATIONALITY", nat)
	_band_box(Rect2(x + hw + 6, 110, hw, 34), "KIND", str(_p.get("kind", "NATIONAL")))

	# Row 3: ROLE (camrol pitch icon + the role word).
	var role := Rect2(x, 150, w, 26)
	PMChrome.bevel(self, role, C_ROLEBOX, C_ROLEBOX.lightened(0.25), C_ROLEBOX.darkened(0.4))
	_txt(_f10, x + 6, 156, "ROLE", C_LABEL, 11)
	var icon_cell := Rect2(x + 52, 152, 30, 22)
	PMChrome.draw_role_icon(self, icon_cell, int(_p.get("posFine", 0)), str(_p.get("pos", "")))
	var word := str(POS_WORD.get(str(_p.get("pos", "")), "OUTFIELD"))
	_txt(_f12, x + 90, 155, word, Color(0.90, 0.96, 1.0), 13)

	# Row 4: STATUS | INSURANCE.
	var st := Availability.status(_p)
	var st_s := str(st["state"]) if st["state"] == "FIT" else "%s %dw" % [st["state"], int(st["weeks"])]
	_band_box(Rect2(x, 182, hw, 34), "STATUS", st_s)
	_band_box(Rect2(x + hw + 6, 182, hw, 34), "INSURANCE", "NONE")

	# Row 5: the club kit + name.
	var kit := PMChrome.kit(int(_club.get("id", -1)))
	if kit != null:
		var sc: float = min(40.0 / KIT_SRC.size.x, 48.0 / KIT_SRC.size.y)
		draw_texture_rect_region(kit, Rect2(x + 4, 224, KIT_SRC.size.x * sc, KIT_SRC.size.y * sc), KIT_SRC)
	_txt(_f12, x + 52, 240, str(_club.get("name", "")), C_VAL, 13, 0, w - 56)


## A small two-line box: coloured label band + a white value strip below.
func _stat_box(r: Rect2, col: Color, label: String, value: String) -> void:
	PMChrome.bevel(self, Rect2(r.position.x, r.position.y, r.size.x, 16), col, col.lightened(0.3), col.darkened(0.4))
	_txt(_f10, r.position.x, r.position.y + 2, label, C_LABEL, 11, 1, r.size.x)
	var vr := Rect2(r.position.x, r.position.y + 17, r.size.x, r.size.y - 17)
	PMChrome.bevel(self, vr, Color(0.88, 0.90, 0.86), C_CARD_HI, C_CARD_LO)
	_txt(_f12, vr.position.x, vr.position.y + 3, value, C_VAL, 13, 1, vr.size.x)


## A horizontal band: dark label strip + a pale value strip below it.
func _band_box(r: Rect2, label: String, value: String) -> void:
	PMChrome.bevel(self, Rect2(r.position.x, r.position.y, r.size.x, 15), C_IDENT, C_IDENT.lightened(0.25), C_IDENT_LO)
	_txt(_f10, r.position.x, r.position.y + 1, label, C_LABEL, 11, 1, r.size.x)
	var vr := Rect2(r.position.x, r.position.y + 16, r.size.x, r.size.y - 16)
	PMChrome.bevel(self, vr, Color(0.80, 0.86, 0.94), C_CARD_HI, C_CARD_LO)
	_txt(_f10, vr.position.x + 2, vr.position.y + 2, value, C_VAL, 11, 1, vr.size.x)


## Right stat panel: SPEED STAMINA AGGRESSION QUALITY FITNESS MORAL + the RATING box.
func _draw_stat_panel() -> void:
	var panel := Rect2(322, 64, 312, 118)
	PMChrome.bevel(self, panel, C_STATP, C_STATP.lightened(0.2), C_STATP.darkened(0.4), 2.0)
	var rows := [["SPEED", _attr("VE")], ["STAMINA", _attr("RE")], ["AGGRESSION", _attr("AG")],
		["QUALITY", _attr("CA")], ["FITNESS", _fitness()], ["MORAL", _moral()]]
	var y := 68.0
	for row in rows:
		# Label right-aligned so it ENDS just left of the value cell (align 2 = x is the
		# right edge); must sit inside the panel, not draw leftward into the left column.
		_txt(_f12, 520, y, str(row[0]), Color(0.04, 0.10, 0.22), 13, 2)
		var cell := Rect2(528, y - 1, 36, 16)
		PMChrome.bevel(self, cell, C_STATCELL, C_STATCELL.lightened(0.2), C_STATCELL.darkened(0.3))
		_txt(_f12, cell.position.x, cell.position.y + 2, str(row[1]), C_VAL, 13, 1, cell.size.x)
		y += 19.0
	# RATING box (right of the panel).
	_txt(_f10, 570, 70, "RATING", Color(0.04, 0.10, 0.22), 11, 1, 60)
	var rb := Rect2(576, 92, 50, 30)
	PMChrome.bevel(self, rb, C_RATING, C_RATING.lightened(0.2), C_RATING.darkened(0.3))
	_txt(_f18, rb.position.x, rb.position.y + 5, str(_rating()), C_VAL, 20, 1, rb.size.x)


## Star-skill strip: HANDLING (bar) / PASSING / DRIBBLING / HEADING / TACKLING / SHOOTING.
func _draw_skill_strip() -> void:
	var strip := Rect2(322, 188, 312, 144)
	PMChrome.bevel(self, strip, C_SKILL, Color(0.20, 0.22, 0.28), Color(0.0, 0.0, 0.0))
	# label, attr key, as-bar?
	var rows := [["HANDLING", "PO", true], ["PASSING", "PA", false], ["DRIBBLING", "RM", false],
		["HEADING", "RG", false], ["TACKLING", "EN", false], ["SHOOTING", "TI", false]]
	var y := 194.0
	for row in rows:
		var val := _attr(str(row[1]))
		# Right-aligned label ending just left of the stars/bar (inside the strip).
		_txt(_f12, 476, y, str(row[0]), Color(0.92, 0.94, 1.0), 13, 2)
		if row[2]:
			# HANDLING as a filled bar (keepers full, outfielders near-empty), like the original.
			var bar := Rect2(484, y + 1, 110, 12)
			draw_rect(bar, Color(0.12, 0.13, 0.18), true)
			draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x * clampf(val / 99.0, 0.0, 1.0), bar.size.y),
				Color(0.86, 0.66, 0.20), true)
		else:
			PMChrome.draw_stars(self, 484, y, val / 20.0, 12, 5)
		_txt(_f12, 600, y, str(val), C_GOLD, 13, 2, 30)
		y += 23.0


## CONTRACT panel: market VALUE, YEARLY WAGE, YEARS LEFT (real helpers).
func _draw_contract() -> void:
	var panel := Rect2(12, 338, 524, 100)
	PMChrome.bevel(self, panel, C_CONTRACT, C_CONTRACT.lightened(0.25), C_CONTRACT.darkened(0.4), 2.0)
	_txt(_f12, panel.position.x + 8, panel.position.y + 6, "CONTRACT", C_GOLD, 13)
	var value := TransferMarket.value_of(_p, _tier)
	var weekly := Contract.current_weekly(_p, _tier)
	var yearly := Contract.yearly(weekly)
	var years := int(_p.get("contract_years", 0))
	var cols := [["VALUE", "£%s" % _money(value)], ["YEARLY WAGE", "£%s" % _money(yearly)],
		["YEARS LEFT", str(years) if years > 0 else "-"]]
	var cw := (panel.size.x - 16) / 3.0
	for i in 3:
		var cx := panel.position.x + 8 + i * cw
		_txt(_f10, cx, panel.position.y + 32, str(cols[i][0]), C_LABEL, 11, 1, cw - 8)
		var vb := Rect2(cx, panel.position.y + 48, cw - 8, 26)
		PMChrome.bevel(self, vb, Color(0.74, 0.16, 0.16) if i == 0 else Color(0.16, 0.30, 0.56),
			Color(0.9, 0.5, 0.5) if i == 0 else Color(0.4, 0.54, 0.8), Color(0.3, 0.04, 0.04))
		_txt(_f14, vb.position.x, vb.position.y + 4, str(cols[i][1]), Color(1.0, 0.92, 0.6), 15, 1, vb.size.x)


func _draw_ok() -> void:
	PMChrome.bevel(self, OK_BTN, C_OK_HI if _press == "ok" else C_OK, C_OK_HI, C_OK.darkened(0.4))
	_txt(_f14, OK_BTN.position.x, OK_BTN.position.y + 5, "OK", C_GOLD, 15, 1, OK_BTN.size.x)


## Thousands-separated integer (no locale dependency).
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
