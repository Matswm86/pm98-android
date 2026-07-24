extends Control
class_name TeamOfferScreen
## PM98 TEAM OFFER answer card — the modal the original pops over the MANAGER MENU
## when CPU clubs bid on a transfer-listed player (walkthrough run-3 frames
## 086-092 + 150-153). Static chrome = the REAL frame baked verbatim
## (tools/re/build_team_offer_chrome_from_frames.py, entry-flow doctrine); this
## screen draws ONLY the state deltas: the player-card fields, the CLUB OFFERS
## rows and the per-row REFUSE/ACCEPT toggle + OK, with the PROMAN fonts at
## NATIVE .fnt sizes and the game's own art (MINIBAND flags SAD 0.0, camrol
## sprite SAD 0.0, frame-cut FICHA kit patch for Man Utd / scaled NANOESC
## fallback for clubs no frame shows).
##
## Frame-truth interaction: each offer row carries ONE toggle chip, REFUSE by
## default (086/090/150/152); a tap flips it (088/092/151/153 = ACCEPT), the
## red inner outline is the held-down state (087/091), OK (089) commits every
## row's answer. The only exit is OK — the card is modal, exactly like the
## original. WEIGHT/HEIGHT show METRIC (the stored native units, standing user
## call 2026-06-26) where the original converted to imperial.
##
## Signals: `answered(decisions)` — Array[String] "accept"/"refuse", parallel to
## the offers passed to setup(). The caller applies them to the Career model.

signal answered(decisions: Array)

const W := 640
const H := 480

const MODAL_POS := Vector2(98, 5)

# offer list / chip geometry (all frame-measured; see team_offer_re.md)
const CHIP_X := 446
const CHIP_Y0 := 368
const ROW_PITCH := 14
const N_ROWS := 5
const OK_RECT := Rect2(446, 442, 91, 29)
const ROW0_TEXT_Y := 371.0
const FLAG_X := 134
const FLAG_Y0 := 371
const CLUB_TEXT_X := 156.0
const AMOUNT_RIGHT_X := 436.0

# player-card anchors (086-exact: y = the measured glyph-top row; centres from
# both 086 and 150 where two frames pin them, e.g. fee/wage centre x~227)
const NAME_XY := Vector2(147, 49)
const POS_CENTER_X := 221.5
const POS_Y := 70.0
const VAL_STRIP_Y := 98.0           # AGE/WEIGHT/HEIGHT value glyph top - 2
const AGE_CX := 147.5
const WGT_CX := 212.0
const HGT_CX := 287.0
const NAT_FLAG := Vector2(117, 125)  # 14x10 MINIBAND mini, borderless
const NAT_TEXT_C := Vector2(179.5, 125)
const KIND_TEXT_C := Vector2(280.5, 125)
const CAMROL_XY := Vector2(158, 140)
const ROLE_TEXT_C := Vector2(255, 142)
const STATUS_TEXT_C := Vector2(177, 172)
const INSUR_TEXT_C := Vector2(283.5, 172)
const KIT_XY := Vector2(112, 181)    # 24x33 frame patch / nano fallback box
const CLUBNAME_XY := Vector2(138, 189)
const STAT_CELL := Rect2(449, 75, 22, 9)   # +10 per row; digits centred x460
const STAT_PITCH := 10
const RATING_C := Vector2(502, 103)
const SKILL_Y0 := 144
const SKILL_PITCH := 13
const STAR_X0 := 426
const STAR_PITCH := 14
const SKILL_VAL_CX := 511.0          # values CENTRED here ('17' vs '70' pin it)
const FEE_TEXT_C := Vector2(228.0, 250)
const WAGE_TEXT_C := Vector2(228.0, 280)
const YEARS_C := Vector2(184.0, 312)
const LEFT_C := Vector2(270.0, 312)
const CLAUSE_XY := Vector2(327, 244)
const PHOTO_XY := Vector2(106, 39)   # 35x35 block, 33x33 interior

# text colours (frame-sampled, team_offer_chrome_samples.json)
const C_WHITE := Color8(255, 255, 255)
const C_BLACK := Color8(0, 0, 0)
const C_RATING := Color8(59, 85, 130)
const C_GOLD := Color8(255, 223, 0)
const C_WAGE := Color8(180, 200, 220)
const C_YEARS := Color8(200, 230, 60)
const C_LEFT := Color8(42, 191, 85)
const C_CLUBROW := Color8(30, 52, 98)
const C_AMOUNT := Color8(85, 0, 0)

const POS_WORD := {"GK": "GOALKEEPER", "DF": "DEFENDER", "MF": "MIDFIELDER", "FW": "FORWARD"}

var _chrome: Texture2D
var _btn := {}          # "refuse_on"/"accept_on"/"refuse_pr"/"accept_pr" -> Texture2D
var _ok_pr: Texture2D
var _clause_on: Texture2D
var _photo_block: Texture2D
var _star_full: Texture2D
var _star_half: Texture2D
var _f8: Font
var _f10: Font
var _f12: Font

var _p: Dictionary = {}
var _club: Dictionary = {}
var _offers: Array = []
var _fee := 0
var _yearly := 0
var _years := 0
var _left := 0
var _clauses: Array = []          # checked clause indices (only 0 has frame art)
var _kit: Texture2D = null        # screen-owned 24x33 frame kit cut (kit_<id>.png)
var _accept: Array = []           # per-offer bool, REFUSE (false) by default
var _press := ""                  # "row0".."row4" / "ok" while held


func _ready() -> void:
	_chrome = load("res://art/screens/teamoffer/chrome.png")
	for k in ["refuse_on", "accept_on", "refuse_pr", "accept_pr"]:
		_btn[k] = load("res://art/screens/teamoffer/btn_%s.png" % k)
	_ok_pr = load("res://art/screens/teamoffer/ok_pr.png")
	_clause_on = load("res://art/screens/teamoffer/clause_on.png")
	_photo_block = load("res://art/screens/teamoffer/photo_block.png")
	_star_full = load("res://art/screens/teamoffer/star_full.png")
	_star_half = load("res://art/screens/teamoffer/star_half.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the card. `offers` = Career.offers_for(pid) entries ({buyer_id,
## buyer_name, offer, ...}); fee/yearly/years/left are the CONTRACT panel's
## display values (the caller derives them from the model); `clauses` = checked
## clause indices (the Career model stores none today — live callers pass []).
func setup(player: Dictionary, club: Dictionary, offers: Array, fee: int, yearly: int,
		years: int, left: int, clauses: Array = []) -> void:
	_p = player
	_club = club
	var cid := int(club.get("id", -1))
	var kit_path := "res://art/screens/teamoffer/kit_%d.png" % cid
	_kit = load(kit_path) if cid >= 0 and ResourceLoader.exists(kit_path) else null
	_offers = offers.slice(0, N_ROWS)
	_fee = fee
	_yearly = yearly
	_years = years
	_left = left
	_clauses = clauses
	_accept = []
	for i in _offers.size():
		_accept.append(false)
	queue_redraw()


# ---- input -----------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _target_at(d: Vector2) -> String:
	if OK_RECT.has_point(d):
		return "ok"
	for i in _offers.size():
		# The hit rect is EXACTLY the row pitch (14). It used to be 17 tall, which made
		# rows overlap: `_target_at` returns the FIRST match, so a tap on offer #2's chip
		# flipped offer #1 and #2 could never be accepted (team_offer_re.md: rows are at
		# y370+14i, the solid chip paints y370..382 and its shadow y383..385, so the
		# clickable band is one 14-row period).
		if Rect2(CHIP_X, CHIP_Y0 + ROW_PITCH * i, 91, ROW_PITCH).has_point(d):
			return "row%d" % i
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	# A finger tap arrives TWICE (emulated mouse + real touch); the chip flips on press,
	# so without this it flipped to ACCEPT and back to REFUSE in the same tap and the
	# card looked dead on a device. See PMChrome.is_emulated_pointer_dup.
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		# frame truth 086->087: the chip flips ON PRESS and holds the red
		# outline while down (087 shows the NEW label outlined)
		if _press.begins_with("row"):
			var i := int(_press.substr(3))
			_accept[i] = not _accept[i]
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "ok" and _target_at(d) == "ok":
		var out: Array = []
		for acc in _accept:
			out.append("accept" if acc else "refuse")
		answered.emit(out)


# ---- drawing ---------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, align := 0, bw := 0.0) -> void:
	PMChrome.text(self, f, x, y_top, s, col, sz, align, bw)

func _ctxt(f: Font, cx: float, y_top: float, s: String, col: Color, sz: int) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(f, cx - w * 0.5, y_top, s, col, sz)

## Double-struck (drawn at x and x+1): the original's bold pass on the card's
## contract money (frame stroke width 2).
func _btxt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	_txt(f, x, y_top, s, col, sz)
	_txt(f, x + 1, y_top, s, col, sz)


## GDI-style emboldening for the name header: each glyph double-struck AND its
## advance widened by 1 (the frame's letters are spaced one px apart from the
## doubled strokes).
func _bold_spaced(f: Font, x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	var cx := x
	for i in s.length():
		var ch := s[i]
		_txt(f, cx, y_top, ch, col, sz)
		_txt(f, cx + 1, y_top, ch, col, sz)
		cx += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 1.0

func _bctxt(f: Font, cx: float, y_top: float, s: String, col: Color, sz: int) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 1.0
	_btxt(f, cx - w * 0.5, y_top, s, col, sz)


func _attr(key: String) -> int:
	var a: Variant = _p.get("attrs", {})
	return int((a as Dictionary).get(key, 0)) if a is Dictionary else 0

# The REAL rating (FUN_00581e60, docs/re/morale_re.md): (VE+RE+AG+CA+FITNESS
# +MORALE)/6, same fitness/moral fallbacks as the card's own value rows.
func _rating() -> int:
	if not (_p.get("attrs", {}) is Dictionary) or (_p.get("attrs", {}) as Dictionary).is_empty():
		return 0
	return (_attr("VE") + _attr("RE") + _attr("AG") + _attr("CA")
		+ clampi(int(_p.get("fitness", 99)), 0, 99)
		+ clampi(int(_p.get("morale", _p.get("moral", 85))), 0, 99)) / 6


func _draw() -> void:
	var s := _scale()
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, MODAL_POS)

	_draw_header()
	_draw_identity()
	_draw_stats()
	_draw_contract()
	_draw_offers()
	if _press == "ok" and _ok_pr != null:
		draw_texture(_ok_pr, OK_RECT.position)


func _draw_header() -> void:
	# BIGFOTO photo block, only when the face art exists (photo-less card = the
	# baked resting look, faithful to Thornley's 086)
	var face := PMChrome.face(_p.get("photoId"))
	if face != null and _photo_block != null:
		draw_texture(_photo_block, PHOTO_XY)
		var tw := float(face.get_width())
		var th := float(face.get_height())
		# 33x33 interior; the original downscales the 124x182 BIGFOTO with an
		# unknown kernel — NEAREST fit is the documented approximation
		var sc := minf(33.0 / tw, 33.0 / th)
		var fw := tw * sc
		var fh := th * sc
		draw_texture_rect(face, Rect2(PHOTO_XY.x + 1 + (33 - fw) * 0.5,
			PHOTO_XY.y + 1 + (33 - fh) * 0.5, fw, fh), false)
	# card name form: given names Title-case + surname UPPER (PMChrome.card_name,
	# frame truth 086/090/150/152 + the 081/084 compound/two-given forms)
	_txt(_f12, NAME_XY.x, NAME_XY.y, PMChrome.card_name(_p), C_WHITE, 13)
	var word := str(POS_WORD.get(str(_p.get("pos", "")), ""))
	if word == "" and _p.get("isGK", false):
		word = "GOALKEEPER"
	# the position word + stat digits use PROMAN10's natural weight (the same
	# face as the baked HANDLING..SHOOTING labels), not a bold pass
	_ctxt(_f10, POS_CENTER_X, POS_Y, word, C_BLACK, 10)


func _draw_identity() -> void:
	# AGE / WEIGHT / HEIGHT (metric — the stored native units, user call)
	_ctxt(_f8, AGE_CX, VAL_STRIP_Y, str(int(_p.get("age", 0))), C_WHITE, 11)
	var wkg: Variant = _p.get("weightKg")
	var hcm: Variant = _p.get("heightCm")
	_ctxt(_f8, WGT_CX, VAL_STRIP_Y, ("%d kg" % int(wkg)) if wkg != null else "-", C_WHITE, 11)
	_ctxt(_f8, HGT_CX, VAL_STRIP_Y, ("%d cm" % int(hcm)) if hcm != null else "-", C_WHITE, 11)
	# NATIONALITY: bordered MINIBAND mini + name; KIND
	var nat := str(_p.get("nationality", "ENGLAND")).to_upper()
	if nat == "":
		nat = "ENGLAND"
	_draw_mini_flag(_p.get("flagCode"), NAT_FLAG)
	_ctxt(_f8, NAT_TEXT_C.x, NAT_TEXT_C.y, nat, C_WHITE, 11)
	_ctxt(_f8, KIND_TEXT_C.x, KIND_TEXT_C.y, str(_p.get("kind", "NATIONAL")).to_upper(), C_WHITE, 11)
	# ROLE: the camrol sprite (SAD 0.0 == the frame icon; its black border/ring
	# pixels are alpha-0 in the export, and the frame shows them black — the
	# backing rect restores them)
	draw_rect(Rect2(CAMROL_XY, Vector2(25, 14)), C_BLACK, true)
	PMChrome.draw_role_icon(self, Rect2(CAMROL_XY, Vector2(25, 14)),
		int(_p.get("posFine", 0)), str(_p.get("pos", "")))
	var pf := int(_p.get("posFine", 0)) if _p.get("posFine") != null else 0
	var role: String
	if pf >= 1 and pf <= PlayerInfoScreen.FINE_ROLE.size():
		role = PlayerInfoScreen.FINE_ROLE[pf - 1]
	else:
		role = str(POS_WORD.get(str(_p.get("pos", "")), "OUTFIELD"))
	_ctxt(_f8, ROLE_TEXT_C.x, ROLE_TEXT_C.y, role, C_WHITE, 11)
	# STATUS / INSURANCE
	var st := Availability.status(_p)
	var st_s := str(st["state"]) if st["state"] == "FIT" else "%s %dw" % [st["state"], int(st["weeks"])]
	_ctxt(_f8, STATUS_TEXT_C.x, STATUS_TEXT_C.y, st_s, C_WHITE, 11)
	_ctxt(_f8, INSUR_TEXT_C.x, INSUR_TEXT_C.y, "NONE", C_WHITE, 11)
	# club kit (frame patch where one exists, scaled NANOESC otherwise) + name.
	# Screen-owned 24x33 cut (kit-bank split 2026-07-03): art/kits/ficha/ holds
	# the 32x37 CARD-slot patches (make-offer / ficha card); this card's smaller
	# slot keeps its own frame cut, cached at setup (draw-time load() blits
	# nothing on the first presented frames — the ficha rollout caught it).
	if _kit != null:
		draw_texture(_kit, KIT_XY)
	else:
		var nano := PMChrome.nano_kit(int(_club.get("id", -1)))
		if nano != null:
			draw_texture_rect(nano, Rect2(KIT_XY, Vector2(21, 21)), false)
	_txt(_f8, CLUBNAME_XY.x, CLUBNAME_XY.y,
		PMChrome.title_case_name(str(_club.get("name", ""))), C_BLACK, 11)


## The 14x10 mini sits directly on the band/row background — the frames show
## no border ring around either flag.
func _draw_mini_flag(code: Variant, at: Vector2) -> void:
	var flag := PMChrome.mini_flag(code)
	if flag != null:
		draw_texture(flag, at)


func _draw_stats() -> void:
	var rows := [_attr("VE"), _attr("RE"), _attr("AG"), _attr("CA"),
		clampi(int(_p.get("fitness", 99)), 0, 99),
		clampi(int(_p.get("morale", _p.get("moral", 85))), 0, 99)]
	for i in rows.size():
		_ctxt(_f8, STAT_CELL.position.x + STAT_CELL.size.x * 0.5,
			STAT_CELL.position.y + STAT_PITCH * i, str(rows[i]), C_BLACK, 11)
	# RATING in the same small value-cell font (see PlayerInfoScreen / morale_re.md).
	_ctxt(_f12, RATING_C.x, RATING_C.y, str(_rating()), C_RATING, 13)
	# skill strip: halves = (value+1) div 10 — corrected 2026-07-03 against the
	# make-offer card (101: 19->1 full, 79->4 full; 090's HEADING 79 shows 4 FULL
	# stars, killing the earlier div-10 reading). Fits all 18 observations.
	var skills := [_attr("PO"), _attr("PA"), _attr("RM"), _attr("RG"), _attr("EN"), _attr("TI")]
	for i in skills.size():
		var v: int = skills[i]
		var y := SKILL_Y0 + SKILL_PITCH * i
		var halves := (v + 1) / 10
		for j in halves / 2:
			draw_texture(_star_full, Vector2(STAR_X0 + STAR_PITCH * j, y + 1))
		if halves % 2 == 1:
			draw_texture(_star_half, Vector2(STAR_X0 + STAR_PITCH * (halves / 2), y + 1))
		_ctxt(_f8, SKILL_VAL_CX, y, str(v), C_BLACK, 11)


func _draw_contract() -> void:
	_ctxt(_f8, FEE_TEXT_C.x, FEE_TEXT_C.y, "£%s" % _money(_fee), C_GOLD, 11)
	_ctxt(_f8, WAGE_TEXT_C.x, WAGE_TEXT_C.y, "£%s" % _money(_yearly), C_WAGE, 11)
	_ctxt(_f8, YEARS_C.x, YEARS_C.y, str(_years), C_YEARS, 11)
	_ctxt(_f8, LEFT_C.x, LEFT_C.y, str(_left), C_LEFT, 11)
	# only clause 0 ("Free if relegated") has frame art; the Career model stores
	# no clauses yet, so live cards keep the all-washed resting bake
	if _clauses.has(0) and _clause_on != null:
		draw_texture(_clause_on, CLAUSE_XY)


func _draw_offers() -> void:
	for i in _offers.size():
		var o: Dictionary = _offers[i]
		var ry := ROW0_TEXT_Y + ROW_PITCH * i
		# buyer nation mini flag: our transfer market is the English league, so
		# ENGLAND (code 30) unless the offer carries a flag_code (foreign CPU
		# bidders are un-modelled today — the original's PSV bid, frame 152)
		_draw_mini_flag(int(o.get("flag_code", 30)), Vector2(FLAG_X, FLAG_Y0 + ROW_PITCH * i))
		_txt(_f8, CLUB_TEXT_X, ry,
			PMChrome.title_case_name(str(o.get("buyer_name", "?"))), C_CLUBROW, 11)
		_txt(_f8, AMOUNT_RIGHT_X, ry, "£%s" % _money(int(o.get("offer", 0))), C_AMOUNT, 11, 2)
		var key := ("accept" if _accept[i] else "refuse") + ("_pr" if _press == "row%d" % i else "_on")
		var tex: Texture2D = _btn[key]
		if tex != null:
			draw_texture(tex, Vector2(CHIP_X, CHIP_Y0 + ROW_PITCH * i))


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
