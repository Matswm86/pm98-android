extends Control
class_name MakeOfferScreen
## PM98 MAKE-OFFER card — the buy-side PLAYER INFORMATION card with the OFFER
## panel (walkthrough run-3 frames 101-118; docs/re/make_offer_re.md). Static
## chrome = the REAL frame baked verbatim (tools/re/build_make_offer_chrome_from_
## frames.py, entry-flow doctrine); this screen draws ONLY the state deltas: the
## identity fields, stat/skill values, the CLUB OFFER / YEARLY WAGE / YEARS
## stepper values, clause checkbox marks + the Scoring-bonus stepper, and the
## pressed-button ring, with the PROMAN fonts at NATIVE .fnt sizes and the
## game's own art (MINIBAND flag SAD 0.0, camrol sprite SAD 0.0, frame-cut FICHA
## kit patch for Blackpool / scaled NANOESC fallback).
##
## Frame-truth interaction: ◄► steppers move CLUB OFFER / YEARLY WAGE by the ENGINE's
## own value-dependent step (£5,000 below £50,000, £10,000 below £250,000, £25,000
## above — handlers 0x529a20..0x529da0, docs/re/offer_record_re.md), floor £5,000;
## YEARS 1..5 in 1s; CLUB FEE is the fixed asking price.
## Checkboxes toggle the four clauses; "Scoring bonus" is player-gated (active
## only for forwards — FUN_0052c66f draws it washed otherwise) and activates its
## stepper at £5,000 when checked (113). "Matches to renew" keeps its washed,
## valueless stepper even when checked — NO frame shows that state (honest gap).
## OFFER / CANCEL / LOAN PLAYER exit; the original submits silently (119).
##
## WEIGHT/HEIGHT show METRIC (stored native units, standing user call
## 2026-06-26) where the original converted to imperial (parity-excluded). The
## RATING box now renders the REAL formula (VE+RE+AG+CA+FITNESS+MORALE)/6
## (FUN_00581e60, docs/re/morale_re.md) — 0px vs frames 101/113 (Taylor 85).
##
## Signals: offer_made(offer, yearly_wage, years, clauses, bonus) / loan_requested /
## cancelled — `bonus` is the Scoring-bonus £ figure (0 unless that clause is
## checked; the FICHA card displays it as "Scoring bonus (£X)"). The caller
## applies the model action and frees the card — NOTE the wage bar is the
## YEARLY figure (Contract.yearly = weekly x 52), as labelled.

signal offer_made(offer: int, yearly_wage: int, years: int, clauses: Array, bonus: int)
signal loan_requested
signal cancelled

const W := 640
const H := 480

const CARD_POS := Vector2(76, 48)

# ---- frame-measured geometry (make_offer_chrome_samples.json) ----------------
const PHOTO_RECT := Rect2(130, 59, 32, 32)      # borderless BIGFOTO block
const NAME_XY := Vector2(171, 69)
const POS_CX := 245.5
const POS_Y := 90.0
const AGE_CX := 171.0
const WGT_CX := 236.5
const HGT_CX := 301.5
const VAL_Y := 118.0
const NAT_FLAG := Vector2(141, 145)             # MINIBAND mini 14x10
const NAT_CX := 204.0
const KIND_CX := 304.0
const IDENT_Y := 145.0
const CAMROL_XY := Vector2(182, 160)            # 25x14, olive backing baked
const ROLE_CX := 279.0
const ROLE_Y := 162.0
const STATUS_CX := 200.5
const INSUR_CX := 307.5                         # steel value area x264..351
const STATUS_Y := 192.0
const KIT_XY := Vector2(140, 202)               # 32x37 frame patch window
const CLUBNAME_XY := Vector2(162, 209)
const STAT_CX := 484.0                          # six cells y96+10i
const STAT_Y0 := 95.0
const STAT_PITCH := 10
const RATING_C := Vector2(526, 123)
const SKILL_Y0 := 164
const SKILL_PITCH := 13
const STAR_X0 := 450
const STAR_PITCH := 14
const SKILL_VAL_CX := 535.0
# OFFER panel
const MONEY_CX := 253.5
const OFFER_VAL_Y := 272.0
const FEE_VAL_Y := 307.0
const WAGE_VAL_Y := 337.0
const YEARS_C := Vector2(209, 369)
const SCORING_C := Vector2(446, 355)
const ARROWS := {
	"offer_dn": Rect2(164, 270, 15, 14), "offer_up": Rect2(327, 270, 15, 14),
	"wage_dn": Rect2(164, 335, 15, 14), "wage_up": Rect2(327, 335, 15, 14),
	"years_dn": Rect2(164, 367, 15, 14), "years_up": Rect2(238, 367, 15, 14),
	"bonus_dn": Rect2(372, 352, 14, 15), "bonus_up": Rect2(506, 352, 14, 15),
}
const CB_X := 351
const CB_YS := [290, 306, 339, 372]             # Free / Matches / Scoring / House
const CLAUSE_KEYS := ["free", "matches", "scoring", "house"]
const SCORING_WASHED_XY := Vector2(351, 339)
const BTN := {
	"cancel": Rect2(140, 396, 104, 29),
	"loan": Rect2(253, 396, 144, 29),
	"offer": Rect2(405, 396, 146, 29),
}
const OFFER_PR_XY := Vector2(403, 394)          # 118's ring cut (OFFER exact)

# Stepper behaviour is BINARY-EXACT (OfferRecord / docs/re/offer_record_re.md): the
# step is chosen from the CURRENT value (£5,000 under £50,000, £10,000 under £250,000,
# £25,000 above) by the handlers at 0x529a20..0x529da0, and ◄ refuses to go below
# £5,000. The old "£5,000 base + accelerating hold ramp" was invented and is gone.
# Only the auto-repeat CADENCE below is app behaviour (the widget's repeat timer is
# not RE'd); the amount each repeat moves is the engine's.
const FLOOR := OfferRecord.MONEY_MIN
const YEARS_MIN := OfferRecord.YEARS_MIN
const YEARS_MAX := OfferRecord.YEARS_MAX
const HOLD_DELAY := 0.4
const HOLD_RATE := 12.0                          # repeats/s while held

const C_WHITE := Color8(255, 255, 255)
const C_BLACK := Color8(0, 0, 0)
const C_GOLD := Color8(255, 223, 0)
const C_WAGE := Color8(180, 200, 220)
const C_YEARS := Color8(200, 230, 60)
const C_RATING := Color8(59, 85, 130)
const C_RING := Color8(255, 0, 0)

const POS_WORD := {"GK": "GOALKEEPER", "DF": "DEFENDER", "MF": "MIDFIELDER", "FW": "FORWARD"}

var _chrome: Texture2D
var _check_on: Texture2D
var _spin_l_on: Texture2D
var _spin_r_on: Texture2D
var _offer_pr: Texture2D
var _scoring_washed: Texture2D
var _star_full: Texture2D
var _star_half: Texture2D
var _f8: Font
var _f10: Font
var _f12: Font

var _p: Dictionary = {}
var _club: Dictionary = {}
var _fee := 0
var _cash := 0
var _offer := FLOOR
var _wage_yearly := FLOOR
var _years := YEARS_MIN
var _bonus := FLOOR                 # scoring-bonus £ (shown while checked)
var _checked := {"free": false, "matches": false, "scoring": false, "house": false}
var _press := ""                    # arrow/button id while held
var _hold_t := 0.0
var _repeats := 0


func _ready() -> void:
	_chrome = load("res://art/screens/makeoffer/chrome.png")
	_check_on = load("res://art/screens/makeoffer/check_on.png")
	_spin_l_on = load("res://art/screens/makeoffer/spin_l_on.png")
	_spin_r_on = load("res://art/screens/makeoffer/spin_r_on.png")
	_offer_pr = load("res://art/screens/makeoffer/offer_pr.png")
	_scoring_washed = load("res://art/screens/makeoffer/scoring_washed.png")
	_star_full = load("res://art/screens/teamoffer/star_full.png")
	_star_half = load("res://art/screens/teamoffer/star_half.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	set_process(false)
	queue_redraw()


## Feed the card. `fee` = the asking price shown in the CLUB FEE bar; `cash` =
## the manager's funds (the offer stepper's ceiling — cap hypothesis per
## make_offer_re.md, the frames show 3,200,000 against a 3,000,000 fee).
##
## `seed` picks WHICH of the original's two opening states this card shows — both are
## witnessed, and which one you get depends on how the player was reached:
##
## * **Cold approach** (the OFFERS map browse — a player nobody has listed), `seed`
##   empty: the panel opens at the FLOOR, £5,000 / £5,000 / 1 year, no clause ticked.
##   Witness `101_164714.png` (Scott Taylor, CLUB FEE £3,000,000, CLUB OFFER £5,000).
## * **A player already PLACED ON TRANSFER MARKET** (the TRANSFERS list), `seed` given:
##   the OFFER panel opens pre-filled with the seller's own asking terms — CLUB OFFER
##   = CLUB FEE, YEARLY WAGE = his contract wage, YEARS = his contract years, and the
##   contract's clauses already ticked. Witness (wine, Bolton career week 4,
##   `35_make_offer.png`): Almeyda, CLUB FEE £8,500,000 and the card opens at CLUB
##   OFFER **£8,500,000**, YEARLY WAGE £575,000, YEARS 1, "Free if relegated" ticked.
##   The 2026-07-24 owner report ("a 14M bid takes hundreds of taps") was this state
##   being seeded at the floor instead.
##
## ANDROID DEVIATION (owner decision, 2026-07-24): the COLD-APPROACH opening CLUB OFFER
## is seeded at the CLUB FEE too, not at the £5,000 floor the original opens on. The
## original's floor is still what frame `101_164714.png` shows and it is not in dispute —
## but the stepper moves in £5,000/£10,000/£25,000 notches (value-dependent), so bidding
## the fee for a £16,000,000 player costs ~640 taps on a touch screen. Every route now
## opens at the asking price and the steppers walk DOWN from there. Pass an explicit
## `offer` in `seed` to override; the floor is still the stepper's hard minimum.
##
## `seed` keys: `offer`, `yearly_wage`, `years`, `clauses` (Array of clause indices).
func setup(player: Dictionary, selling_club: Dictionary, fee: int, cash: int,
		seed: Dictionary = {}) -> void:
	_p = player
	_club = selling_club
	_fee = fee
	_cash = cash
	_offer = maxi(FLOOR, int(seed.get("offer", maxi(FLOOR, fee))))
	_wage_yearly = maxi(FLOOR, int(seed.get("yearly_wage", FLOOR)))
	_years = clampi(int(seed.get("years", YEARS_MIN)), YEARS_MIN, YEARS_MAX)
	_bonus = FLOOR
	var pre: Array = seed.get("clauses", [])
	for i in CLAUSE_KEYS.size():
		_checked[CLAUSE_KEYS[i]] = pre.has(i)
	# the scoring-bonus stepper only exists while its clause is live (frame 113)
	if bool(_checked.get("scoring", false)):
		if not _scoring_enabled():
			_checked["scoring"] = false
	queue_redraw()


## Scoring bonus is player-gated: active for forwards, washed otherwise
## (Taylor FW active / McKinlay MF washed; the exact source predicate — bit 7 of
## [screen+0x4728] — is un-RE'd beyond that observation).
func _scoring_enabled() -> bool:
	return str(_p.get("pos", "")) == "FW"


func checked_clauses() -> Array:
	var out: Array = []
	for i in CLAUSE_KEYS.size():
		if _checked[CLAUSE_KEYS[i]]:
			out.append(i)
	return out


# ---- input -------------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _target_at(d: Vector2) -> String:
	for k in BTN:
		if (BTN[k] as Rect2).has_point(d):
			return k
	for k in ARROWS:
		if (ARROWS[k] as Rect2).grow(2.0).has_point(d):
			return k
	for i in CB_YS.size():
		# the checkbox + its label strip are one tap target
		if Rect2(CB_X, int(CB_YS[i]) - 1, 120, 13).has_point(d):
			return "cb_" + CLAUSE_KEYS[i]
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	# One finger tap arrives twice (emulated mouse + real touch): the clause boxes are
	# toggles and the ◄► steppers move per press, so both were wrong on a device.
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		_hold_t = 0.0
		_repeats = 0
		if _press.ends_with("_up") or _press.ends_with("_dn"):
			_step(_press)
			set_process(true)
		queue_redraw()
		return
	var was := _press
	_press = ""
	set_process(false)
	queue_redraw()
	if was == "" or _target_at(d) != was:
		return
	match was:
		"cancel":
			cancelled.emit()
		"loan":
			loan_requested.emit()
		"offer":
			offer_made.emit(_offer, _wage_yearly, _years, checked_clauses(),
				_bonus if _checked["scoring"] else 0)
		_:
			if was.begins_with("cb_"):
				_toggle(was.substr(3))


func _toggle(key: String) -> void:
	if key == "scoring" and not _scoring_enabled():
		return
	_checked[key] = not _checked[key]
	if key == "scoring":
		_bonus = FLOOR
	queue_redraw()


## Hold-to-repeat. Each repeat applies exactly one engine step (the amount is the
## RE'd value-dependent ladder in OfferRecord); only the repeat cadence is ours.
func _process(delta: float) -> void:
	if not (_press.ends_with("_up") or _press.ends_with("_dn")):
		set_process(false)
		return
	_hold_t += delta
	if _hold_t < HOLD_DELAY:
		return
	var due := int((_hold_t - HOLD_DELAY) * HOLD_RATE)
	while _repeats < due:
		_repeats += 1
		_step(_press)
	queue_redraw()


func _step(id: String) -> void:
	var up := id.ends_with("_up")
	match id.get_slice("_", 0):
		"offer":
			# ceiling = available funds (cap hypothesis, make_offer_re.md)
			_offer = OfferRecord.step_up(_offer, _cash) if up else OfferRecord.step_down(_offer)
		"wage":
			_wage_yearly = OfferRecord.step_up(_wage_yearly) if up else OfferRecord.step_down(_wage_yearly)
		"years":
			_years = OfferRecord.years_up(_years) if up else OfferRecord.years_down(_years)
			if not OfferRecord.matches_clause_allowed(_years):
				# binary rule (0x529e67/0x529fb7): a term over 1 year zeroes the
				# matches-to-renew target and greys its clause box.
				_checked["matches"] = false
		"bonus":
			if _checked["scoring"]:
				_bonus = OfferRecord.step_up(_bonus) if up else OfferRecord.step_down(_bonus)
	queue_redraw()


# ---- drawing -------------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, align := 0, bw := 0.0) -> void:
	PMChrome.text(self, f, x, y_top, s, col, sz, align, bw)

func _ctxt(f: Font, cx: float, y_top: float, s: String, col: Color, sz: int) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(f, cx - w * 0.5, y_top, s, col, sz)




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
		draw_texture(_chrome, CARD_POS)

	_draw_header()
	_draw_identity()
	_draw_stats()
	_draw_offer_panel()
	_draw_clauses()
	_draw_pressed()


func _draw_header() -> void:
	# borderless 32x32 BIGFOTO block over the name bar's left end, only when the
	# face art exists (Taylor: photoId with no art in the bank -> none, baked look)
	var face := PMChrome.face(_p.get("photoId"))
	if face != null:
		draw_texture_rect(face, PHOTO_RECT, false)
	# single-struck PROMAN12 — the face's natural weight IS the frame's bold look
	_txt(_f12, NAME_XY.x, NAME_XY.y, PMChrome.card_name(_p), C_WHITE, 13)
	var word := str(POS_WORD.get(str(_p.get("pos", "")), ""))
	if word == "" and _p.get("isGK", false):
		word = "GOALKEEPER"
	_ctxt(_f10, POS_CX, POS_Y, word, C_BLACK, 10)


func _draw_identity() -> void:
	# AGE / WEIGHT / HEIGHT (metric — stored native units, user call; the
	# original showed imperial, cells parity-excluded)
	_ctxt(_f8, AGE_CX, VAL_Y, str(int(_p.get("age", 0))), C_WHITE, 11)
	var wkg: Variant = _p.get("weightKg")
	var hcm: Variant = _p.get("heightCm")
	_ctxt(_f8, WGT_CX, VAL_Y, ("%d kg" % int(wkg)) if wkg != null else "-", C_WHITE, 11)
	_ctxt(_f8, HGT_CX, VAL_Y, ("%d cm" % int(hcm)) if hcm != null else "-", C_WHITE, 11)
	# NATIONALITY (MINIBAND mini, borderless) / KIND
	var nat := str(_p.get("nationality", "ENGLAND")).to_upper()
	if nat == "":
		nat = "ENGLAND"
	var flag := PMChrome.mini_flag(_p.get("flagCode"))
	if flag != null:
		draw_texture(flag, NAT_FLAG)
	_ctxt(_f8, NAT_CX, IDENT_Y, nat, C_WHITE, 11)
	_ctxt(_f8, KIND_CX, IDENT_Y, str(_p.get("kind", "NATIONAL")).to_upper(), C_WHITE, 11)
	# ROLE: camrol sprite (SAD 0.0; its border/ring pixels are alpha-0 in the
	# export and the frame shows them black — the backing rect restores them,
	# same as the TEAM OFFER card)
	draw_rect(Rect2(CAMROL_XY, Vector2(25, 14)), C_BLACK, true)
	PMChrome.draw_role_icon(self, Rect2(CAMROL_XY, Vector2(25, 14)),
		int(_p.get("posFine", 0)), str(_p.get("pos", "")))
	var pf := int(_p.get("posFine", 0)) if _p.get("posFine") != null else 0
	var role: String
	if pf >= 1 and pf <= PlayerInfoScreen.FINE_ROLE.size():
		role = PlayerInfoScreen.FINE_ROLE[pf - 1]
	else:
		role = str(POS_WORD.get(str(_p.get("pos", "")), "OUTFIELD"))
	_ctxt(_f8, ROLE_CX, ROLE_Y, role, C_WHITE, 11)
	# STATUS / INSURANCE
	var st := Availability.status(_p)
	var st_s := str(st["state"]) if st["state"] == "FIT" else "%s %dw" % [st["state"], int(st["weeks"])]
	_ctxt(_f8, STATUS_CX, STATUS_Y, st_s, C_WHITE, 11)
	_ctxt(_f8, INSUR_CX, STATUS_Y, "NONE", C_WHITE, 11)
	# selling club kit (frame patch where one exists) + title-cased name
	var kit := PMChrome.ficha_kit(int(_club.get("id", -1)))
	if kit != null:
		draw_texture(kit, KIT_XY)
	else:
		var nano := PMChrome.nano_kit(int(_club.get("id", -1)))
		if nano != null:
			draw_texture_rect(nano, Rect2(KIT_XY + Vector2(1, 4), Vector2(30, 30)), false)
	_txt(_f8, CLUBNAME_XY.x, CLUBNAME_XY.y,
		PMChrome.title_case_name(str(_club.get("name", ""))), C_BLACK, 11)


func _draw_stats() -> void:
	var rows := [_attr("VE"), _attr("RE"), _attr("AG"), _attr("CA"),
		clampi(int(_p.get("fitness", 99)), 0, 99),
		clampi(int(_p.get("morale", _p.get("moral", 85))), 0, 99)]
	for i in rows.size():
		_ctxt(_f8, STAT_CX, STAT_Y0 + STAT_PITCH * i, str(rows[i]), C_BLACK, 11)
	# RATING in the same small value-cell font (see PlayerInfoScreen / morale_re.md).
	_ctxt(_f12, RATING_C.x, RATING_C.y, str(_rating()), C_RATING, 13)
	# skill strip: halves = (value+1) div 10 — the rule fitting ALL 18 star
	# observations across 101 + TEAM OFFER 086/090 (see make_offer_re.md)
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


func _draw_offer_panel() -> void:
	_ctxt(_f8, MONEY_CX, OFFER_VAL_Y, "£%s" % _money(_offer), C_GOLD, 11)
	_ctxt(_f8, MONEY_CX, FEE_VAL_Y, "£%s" % _money(_fee), C_GOLD, 11)
	_ctxt(_f8, MONEY_CX, WAGE_VAL_Y, "£%s" % _money(_wage_yearly), C_WAGE, 11)
	_ctxt(_f8, YEARS_C.x, YEARS_C.y, str(_years), C_YEARS, 11)


func _draw_clauses() -> void:
	if not _scoring_enabled():
		# the washed "Scoring bonus" strip (McKinlay cut) over the baked active label
		if _scoring_washed != null:
			draw_texture(_scoring_washed, SCORING_WASHED_XY)
	elif _checked["scoring"]:
		# active stepper: black-triangle arrows + the £ value (frame 113)
		if _spin_l_on != null:
			draw_texture(_spin_l_on, (ARROWS["bonus_dn"] as Rect2).position)
		if _spin_r_on != null:
			draw_texture(_spin_r_on, (ARROWS["bonus_up"] as Rect2).position)
		_ctxt(_f8, SCORING_C.x, SCORING_C.y, "£%s" % _money(_bonus), C_BLACK, 11)
	for i in CLAUSE_KEYS.size():
		if _checked[CLAUSE_KEYS[i]] and _check_on != null:
			draw_texture(_check_on, Vector2(CB_X + 1, int(CB_YS[i]) + 1))


func _draw_pressed() -> void:
	if _press == "offer" and _offer_pr != null:
		draw_texture(_offer_pr, OFFER_PR_XY)
	elif _press == "cancel" or _press == "loan":
		# only OFFER's pressed state exists in the frames; the same 2px red ring
		# outside the button border is applied to its identical-chrome siblings
		# (documented extrapolation, make_offer_re.md)
		var r: Rect2 = (BTN[_press] as Rect2).grow(2.0)
		draw_rect(r, C_RING, false, 2.0)


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
