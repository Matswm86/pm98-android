extends Control
class_name PlayerInfoScreen
## PM98 PLAYER INFORMATION (FICHA) card — rebuilt 2026-07-03 to pixel parity
## against walkthrough run-1 frames 079/081 (Van der Gouw) + 084 (Solskjaer);
## docs/re/ficha_card_re.md. Static chrome = the REAL frame baked verbatim
## (tools/re/build_ficha_chrome_from_frames.py, entry-flow doctrine); this
## screen draws ONLY the state deltas: photo, name, identity fields, stat/skill
## values, the CONTRACT figures (CLUB FEE / YEARLY WAGE bars, YEARS|LEFT
## boxes), the CLAUSES column (checkbox + label + progress sub-line per state),
## and the pressed-button ring — with the PROMAN fonts at NATIVE .fnt sizes and
## the game's own art (MINIBAND mini SAD 0.0, camrol SAD 0.0, frame-cut 32x37
## FICHA kit patches / scaled NANOESC fallback).
##
## The card pops over its host screen, which palette-dims through the exact
## alert LUT (081-vs-082 pair). SquadScreen dims itself via set_dimmed (Main
## brackets the card's lifetime); for hosts without LUT-dim support yet the
## card keeps the old flat backdrop (`host_dims = false`, documented interim).
##
## WEIGHT/HEIGHT show METRIC (stored native units, standing user call
## 2026-06-26) where the original converted to imperial (still parity-excluded).
## The RATING box now renders the REAL formula (VE+RE+AG+CA+FITNESS+MORALE)/6
## (FUN_00581e60, docs/re/morale_re.md) in the value-cell font — 0px vs frames
## 081/084 (80 / 82). Still excluded: the animated info coin and the BIGFOTO
## block (downscale kernel un-RE'd, NEAREST fit).
##
## INTERACTIVE: the source button row RENEW / TRANSFER / SACK / OK
## (FUN_00526a60 card-local rects at card origin (76,58)). The three action
## buttons fire their request signals on the manager's OWN squad player
## (`actions_enabled`); a read-only opener (DATA BASE / opponent browse) covers
## them with card white — that browse-opened state is un-walked, the cover is
## the documented app behaviour, not frame truth. OK held shows the 2px red
## ring OUTSIDE the border, the frame-cut ok_pr (081/084; the same ring is
## extrapolated onto the identical-chrome siblings). OK or a tap on empty card
## space emits `back_pressed`.

signal back_pressed
signal renew_requested(player)
signal transfer_requested(player)
signal sack_requested(player)
## YOUTH card (`youth_actions`): the TRAINING / PROMOTE half of the source's own
## youth button row. SACK reuses `sack_requested`, CANCEL reuses `back_pressed`.
signal training_requested(player)
signal promote_requested(player)
## RENEW negotiation (TOTAL level): the OFFER form was submitted / cancelled.
signal offer_made(weekly, years, clauses)
signal renew_cancelled

const W := 640
const H := 480

const CARD_POS := Vector2(76, 58)

# ---- frame-measured geometry (ficha_chrome_samples.json) ----------------------
const COIN := Rect2(84, 65, 40, 40)             # animated info coin (excluded)
const PHOTO_RECT := Rect2(130, 68, 32, 32)      # borderless BIGFOTO block
const NAME_XY := Vector2(171, 78)
const POS_CX := 246.0
const POS_Y := 99.0
const AGE_CX := 171.0
const WGT_CX := 236.5
const HGT_CX := 301.5
const VAL_Y := 127.0
const NAT_FLAG := Vector2(141, 154)             # MINIBAND mini 14x10
const NAT_CX := 204.0
const KIND_CX := 304.0
const IDENT_Y := 154.0
const CAMROL_XY := Vector2(182, 169)            # 25x14, olive backing baked
const ROLE_CX := 279.0
const ROLE_Y := 171.0
const STATUS_CX := 200.5
const INSUR_CX := 307.5
const STATUS_Y := 201.0
const KIT_XY := Vector2(140, 211)               # 32x37 frame patch window
const CLUBNAME_XY := Vector2(162, 218)
const STAT_CX := 484.0                          # six cells, digits black
const STAT_Y0 := 104.0
const STAT_PITCH := 10
const RATING_C := Vector2(526, 132)
const SKILL_Y0 := 173
const SKILL_PITCH := 13
const STAR_X0 := 450
const STAR_PITCH := 14
const SKILL_VAL_CX := 535.0
# CONTRACT panel
const MONEY_CX := 252.0
const FEE_VAL_Y := 279.0
const WAGE_VAL_Y := 309.0
const YEARS_C := Vector2(207.5, 341)
const LEFT_C := Vector2(293.5, 341)
# CLAUSES column: 11x11 boxes at x351, labels ink-left x366; sub-lines at
# fixed frame rows (Matches played 081 / Goals 084)
const CB_X := 351
const CB_YS := [273, 287, 316, 345]             # Free / Matches / Scoring / House
const LABEL_X := 366.0
const SUB_MATCHES_Y := 298.0
const SUB_GOALS_Y := 327.0
# buttons (FUN_00526a60 rects + card origin): 3x 104x25 + the 52x25 OK
const BTN := {
	"renew": Rect2(161, 383, 104, 25),
	"transfer": Rect2(272, 383, 104, 25),
	"sack": Rect2(383, 383, 104, 25),
	"ok": Rect2(505, 383, 52, 25),
}
const OK_PR_XY := Vector2(503, 381)             # 081's held-OK ring cut

# ---- the YOUTH card's own button row (FUN_005274d0, decompiled 2026-07-29) ----
#
# A YOUTH TEAM roster row opens this card through `FUN_0053ec40`, which calls
# `FUN_005274d0` where a senior row calls `FUN_00526a60`. Same FICHA chrome, same card
# origin, DIFFERENT buttons — and this row is the whole missing control surface: without
# it there is no way to put a youngster into training and no way to promote him.
#
# Rects are the source's own `FUN_00436fb0(w,h)` / `FUN_00436fb0(x,y)` pairs, card-local,
# lifted verbatim and shifted by CARD_POS (the same transform that reproduces the senior
# row exactly: RENEW's local (85,325) + (76,58) == the witnessed Rect2(161,383,104,25)):
#
#   TRAINING  size (0x54,0x19) = 84x25   pos (0x34,0x149)  = (52,329)   widget id 0xda
#   SACK      size (0x54,0x19) = 84x25   pos (0x8f,0x149)  = (143,329)  widget id 0x67
#   PROMOTE   size (0x72,0x19) = 114x25  pos (0xea,0x149)  = (234,329)  widget id 0xdc
#   CANCEL    size (0x6a,0x19) = 106x25  pos (0x172,0x149) = (370,329)  widget id 0x386
#
# Ink: the first three are drawn under `FUN_00437020(0xff,0xdf,0)` = gold (255,223,0);
# CANCEL under `FUN_00437020(0xff,0,0)` = red (255,0,0).
const BTN_YOUTH := {
	"training": Rect2(128, 387, 84, 25),
	"sack": Rect2(219, 387, 84, 25),
	"promote": Rect2(310, 387, 114, 25),
	"cancel": Rect2(446, 387, 106, 25),
}
## The four plates are the WITNESSED pixels, cut 1:1 out of p0771 by
## tools/re/build_youth_card_buttons_from_frames.py (entry-flow doctrine). `promote_on`
## and `training_off` are the two states no frame we hold shows and are declared
## reconstructions — see that script's header.
const YBTN_ART := {
	"training": ["training_off", "training_on"],
	"sack": ["sack_on", "sack_on"],
	"promote": ["promote_off", "promote_on"],
	"cancel": ["cancel_on", "cancel_on"],
}

# ---- RENEW negotiation OFFER panel (frame 25_renew, TOTAL level; renew_negotiation_re.md) ----
# The OFFER panel replaces the identity/stat zone in renew mode. Static chrome = the frame-cut
# renew_overlay.png (headers/bars/◄►arrows/OFFER label/CLAUSES labels+sliders/CANCEL+OFFER
# buttons, with the fee/wage/years value cells + clause boxes cleared to resting). The dynamic
# layer here draws the offered CLUB FEE / YEARLY WAGE / YEARS values + the CLAUSES checkboxes.
# Every rect frame-measured off 25_renew (native 640x480, +1px window border removed).
const RENEW_OVERLAY_XY := Vector2(92, 103)       # native draw pos (card-relative 16,45)
const OFF_MONEY_CX := 252.0
const OFF_FEE_Y := 125.0
const OFF_WAGE_Y := 156.0
const OFF_YEARS_C := Vector2(210, 187)
const C_YEARS_INK := Color8(80, 110, 5)          # olive digit on the green YEARS bar (frame)
# stepper hit-rects over the baked ◄/► arrows (wage row y159, years row y191)
const OFF_WAGE_DN := Rect2(150, 152, 30, 14)
const OFF_WAGE_UP := Rect2(323, 152, 20, 14)
const OFF_YEARS_DN := Rect2(148, 184, 30, 14)
const OFF_YEARS_UP := Rect2(238, 184, 26, 14)
# CANCEL / OFFER buttons (baked visuals; these are the hit-rects)
const OFF_CANCEL := Rect2(287, 206, 103, 32)
const OFF_OFFER := Rect2(404, 206, 143, 32)
# OFFER clause checkboxes: 11x11 at CB_X, panel y-tops (baked textures blitted per current clause)
const OFF_CB_YS := [108, 124, 157, 190]
# The wage/years stepper granularity is BINARY-EXACT since 2026-07-23 (OfferRecord /
# docs/re/offer_record_re.md): the YEARLY WAGE arrows move by the engine's own
# value-dependent step (£5,000 / £10,000 / £25,000 by band) with a £5,000 floor, and
# YEARS runs 1..5 mirroring LEFT. The old £100/week placeholder is gone.
const OFF_YEARS_MIN := OfferRecord.YEARS_MIN
const OFF_YEARS_MAX := OfferRecord.YEARS_MAX

# TRANSFER-LISTED state (owner frame 14, 2026-07-23): when the player is on the
# transfer market the card grows a "PLAYER PLACED ON TRANSFER MARKET" banner in the
# card-white strip between the CONTRACT/CLAUSES block and the RENEW/TRANSFER/SACK/OK
# row, and the TRANSFER button carries a persistent red outline. Both measured off the
# native 640x480 owner capture (frame text solid olive, no AA).
const LISTED_BANNER := "PLAYER PLACED ON TRANSFER MARKET"
const LISTED_BANNER_CX := 345.0                 # card-centred (frame 14)
const LISTED_BANNER_Y := 367.0                  # top of the olive glyph row (frame y368..374)
const C_LISTED := Color8(80, 110, 5)            # frame-sampled olive banner ink

const C_WHITE := Color8(255, 255, 255)
const C_BLACK := Color8(0, 0, 0)
const C_GOLD := Color8(255, 223, 0)
const C_WAGE := Color8(180, 200, 220)
const C_YEARS := Color8(200, 230, 60)
const C_LEFT := Color8(42, 191, 85)
const C_RATING := Color8(59, 85, 130)
const C_RING := Color8(255, 0, 0)
const C_FIELD := Color8(220, 220, 220)
const C_WASHED := Color8(144, 144, 144)
const C_CHECK := Color8(255, 31, 0)

const POS_WORD := {"GK": "GOALKEEPER", "DF": "DEFENDER", "MF": "MIDFIELDER", "FW": "FORWARD"}
# The FICHA ROLE band shows the FINE position name: the original renderer
# FUN_0052e0d0 indexes the SHORT fine-name table (MANAGER.EXE 0x662df8) by the
# in-memory fine byte player+0x18 = posFine-1. See docs/re/positions_re.md.
const FINE_ROLE := ["KEEPER", "RIGHT BACK", "LEFT BACK", "SWEEPER", "INS. CENT. LEFT",
	"INS. CENT. RIGHT", "RIGHT MID.", "INSIDE RIGHT", "CENTRE FORWARD", "CENTRAL MID.",
	"LEFT MID.", "RIGHT WINGER", "CENTRAL STRIKER", "LEFT WINGER", "DEF. MIDFIELDER",
	"RIGHT FORWARD", "LEFT FORWARD", "INSIDE LEFT"]
const AVG_KEYS := ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]

var _chrome: Texture2D
var _ok_pr: Texture2D
var _star_full: Texture2D
var _star_half: Texture2D
var _f8: Font
var _f10: Font
var _f12: Font

var _p: Dictionary = {}
var _club: Dictionary = {}
var _tier: int = 1
var _actions := false   # RENEW/TRANSFER/SACK live (manager's own squad player)
var _listed := false    # player is on the transfer market -> banner + red TRANSFER outline
# YOUTH card (FUN_005274d0): the TRAINING/SACK/PROMOTE/CANCEL row replaces the senior one.
var _youth := false
var _training_on := false   # FUN_0057cd30() > FUN_0057cd50(): a training slot is free
var _promote_on := false    # CORE4 live == BASE on all four (the source's own gate)
var _ybtn: Dictionary = {}  # youth button plates, by art name
var _press := ""
var _down := false  # a press was seen; release without it is the emulated-mouse twin
## The host screen LUT-dims itself while this card is up (SquadScreen); when it
## can't yet, the card draws the old flat backdrop instead (documented interim).
var host_dims := false
# Contract figures shown in the panel (computed from the model in setup; the
# parity harness pins the frame values directly).
var _fee := 0
var _yearly := 0
var _years := 0
var _left := 0

# RENEW negotiation (TOTAL-level manual renewal) state.
var _renew := false
var _renew_overlay: Texture2D
var _check_on: Texture2D
var _check_off: Texture2D
var _offer_yearly := 0      # the offered YEARLY wage (the engine's own unit; stepped)
var _offer_years := 0       # the offered contract length (stepped)
var _offer_clauses: Array = []  # the offered clause row indices (toggled on the OFFER panel)
var _cur_weekly := 0        # his current weekly (offer floor)
var _demand_weekly := 0     # the wage he wants (for the caller's accept/reject)


func _ready() -> void:
	_chrome = load("res://art/screens/ficha/chrome.png")
	_ok_pr = load("res://art/screens/ficha/ok_pr.png")
	_renew_overlay = load("res://art/screens/ficha/renew_overlay.png")
	_check_on = load("res://art/screens/ficha/renew_check_on.png")
	_check_off = load("res://art/screens/ficha/renew_check_off.png")
	_star_full = load("res://art/screens/teamoffer/star_full.png")
	_star_half = load("res://art/screens/teamoffer/star_half.png")
	for k in YBTN_ART:
		for art in YBTN_ART[k]:
			if not _ybtn.has(art):
				_ybtn[art] = load("res://art/screens/youth_card/%s.png" % art)
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the player + his club (kit/name) + league tier (fee/wage). The three
## action buttons show only for the manager's own squad player.
func setup(player: Dictionary, club: Dictionary, tier: int = 1, actions_enabled := false,
		listed := false) -> void:
	_p = player
	_club = club
	_tier = maxi(1, tier)
	_actions = actions_enabled
	_listed = listed
	# The player's SELLING-club stature band drives the RE'd PM98 fee/wage (his club's
	# squad strength, not just its division). docs/re/transfer_value_re.md sec.10.
	var band := TransferMarket.stature_of(_club.get("players", []), _tier)
	_fee = TransferMarket.value_of(player, band)
	_yearly = Contract.current_yearly(player, band)
	_left = int(player.get("contract_years", 0))
	_years = maxi(int(player.get("contract_term", 0)), _left)
	queue_redraw()


## Open this card as the YOUTH PLAYER card (`FUN_005274d0`): the button row becomes
## TRAINING / SACK / PROMOTE / CANCEL. Both gates are the source's own:
##   TRAINING greys when `FUN_0057cd30() <= FUN_0057cd50()` — the YOUTH TEAM MANAGER's
##            capacity is already taken by youngsters carrying the 0x20 mode byte.
##   PROMOTE  greys unless all four CORE4 live bytes (+0x9c..+0x9f) equal their BASE
##            (+0xaa..+0xad), i.e. he has finished growing into his shipped rating.
func setup_youth(player: Dictionary, club: Dictionary, staff: Array, youth: Array,
		tier: int = 1) -> void:
	setup(player, club, tier, false, false)
	_youth = true
	_promote_on = Training.youth_fully_grown(player)
	# ...and a youngster ALREADY carrying the 0x20 mode greys it too: the button's only
	# action (put him IN) is spent, and greying is the card's visible answer to the tap —
	# the owner's 2026-08-05 "the training button doesn't seem to have a function" was a
	# SUCCESSFUL tap whose only feedback went to the footer the fullscreen card covers.
	_training_on = not Training.youth_in_training(player) \
		and Training.youth_in_training_count(youth) \
		< Staff.youth_training_capacity(staff)
	queue_redraw()


## Enter the RENEW OFFER negotiation (the source form witnessed at TOTAL level,
## renew_negotiation_re.md): the identity/stat zone becomes the OFFER panel. Seeds the offer at
## his current terms; the ◄/► steppers move the wage/years; OFFER/CANCEL emit the signals.
## The offer opens on `_yearly` — his EXACT table yearly wage (Contract.current_yearly),
## the same figure the CONTRACT panel below shows — because the engine's stepper works in
## the yearly unit, and re-deriving it from the rounded weekly would drift off the table.
func begin_renew(cur_weekly: int, demand_weekly: int, years: int) -> void:
	_renew = true
	_cur_weekly = cur_weekly
	_demand_weekly = demand_weekly
	_offer_yearly = maxi(OfferRecord.MONEY_MIN, _yearly if _yearly > 0 else Contract.yearly(cur_weekly))
	_offer_years = maxi(OFF_YEARS_MIN, years)
	# The OFFER panel's four clause boxes open on his CURRENT clauses and are then the
	# manager's to change — that is what a negotiation form is for. They used to be a
	# read-only mirror of the CONTRACT panel below (Mats QA 2026-08-01: "adding or
	# removing clauses doesn't work").
	_offer_clauses = []
	for c in _clauses():
		_offer_clauses.append(int(c))
	_press = ""
	queue_redraw()

func end_renew() -> void:
	_renew = false
	_press = ""
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(pt: Vector2) -> Vector2:
	var s := _scale()
	return (pt - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
	if _renew:
		if OFF_OFFER.has_point(d):
			return "offer"
		if OFF_CANCEL.has_point(d):
			return "cancel"
		# 14px-tall spin arrows take PMTouch's grown rect (input-side only); the four
		# rects sit >= 32px apart so HIT_SLOP=5 never overlaps a neighbour.
		if PMTouch.near(OFF_WAGE_UP, d):
			return "wage_up"
		if PMTouch.near(OFF_WAGE_DN, d):
			return "wage_dn"
		if PMTouch.near(OFF_YEARS_UP, d):
			return "years_up"
		if PMTouch.near(OFF_YEARS_DN, d):
			return "years_dn"
		# The four OFFER-panel clause boxes. Grown to 16px so an 11x11 box is a usable
		# touch target on a phone; they do not overlap anything else on the panel.
		for ci in 4:
			if Rect2(CB_X - 3, int(OFF_CB_YS[ci]) - 3, 17, 17).has_point(d):
				return "clause_%d" % ci
		if (BTN["ok"] as Rect2).has_point(d):
			return "ok"
		return ""
	if _youth:
		# The source's own greying (FUN_005bf8c0(0,1)) makes a disabled button inert, so a
		# greyed TRAINING / PROMOTE must not hit-test either.
		for k in ["training", "sack", "promote", "cancel"]:
			if not (BTN_YOUTH[k] as Rect2).has_point(d):
				continue
			if k == "training" and not _training_on:
				return ""
			if k == "promote" and not _promote_on:
				return ""
			return "y_" + k
		return ""
	if (BTN["ok"] as Rect2).has_point(d):
		return "ok"
	if _actions:
		for k in ["renew", "transfer", "sack"]:
			if (BTN[k] as Rect2).has_point(d):
				return k
	return ""

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if _renew:
		_renew_input(e, d)
		return
	if e.pressed:
		_down = true
		_press = _hit(d)
		queue_redraw()
		return
	# One release per press (emulate_mouse_from_touch double-fire guard): an orphan
	# release landing on this freshly-mounted card tripped the unconditional
	# back_pressed below and tore the overlay stack down to the hub.
	if not _down:
		return
	_down = false
	var was := _press
	_press = ""
	queue_redraw()
	if was != "" and _hit(d) == was:
		match was:
			"renew": renew_requested.emit(_p)
			"transfer": transfer_requested.emit(_p)
			"sack": sack_requested.emit(_p)
			"y_training": training_requested.emit(_p)
			"y_promote": promote_requested.emit(_p)
			"y_sack": sack_requested.emit(_p)
			_: back_pressed.emit()
		return
	# A youth card is only left through CANCEL — a tap on empty card space must not
	# dismiss it, or the four-button row is unreachable on a fat-fingered tap.
	if not _youth:
		back_pressed.emit()


## RENEW OFFER form input: the ◄/► steppers fire on PRESS (repeatable); OFFER/CANCEL/OK act on
## release. A tap on empty card space is inert here (unlike the plain card) so a stray tap can't
## silently abandon the negotiation.
func _renew_input(e: InputEvent, d: Vector2) -> void:
	var h := _hit(d)
	if e.pressed:
		_down = true
		_press = h
		match h:
			# Engine steps (OfferRecord): value-dependent amount, £5,000 floor. There is
			# no "never below his current wage" clamp in the original — you may lowball
			# and he rejects (Contract.evaluate_renewal / "has rejected your offer").
			"wage_up": _offer_yearly = OfferRecord.step_up(_offer_yearly)
			"wage_dn": _offer_yearly = OfferRecord.step_down(_offer_yearly)
			"years_up": _offer_years = OfferRecord.years_up(_offer_years)
			"years_dn": _offer_years = OfferRecord.years_down(_offer_years)
		if h.begins_with("clause_"):
			var ci := int(h.substr(7))
			if _offer_clauses.has(ci):
				_offer_clauses.erase(ci)
			else:
				_offer_clauses.append(ci)
		queue_redraw()
		return
	if not _down:
		return
	_down = false
	var was := _press
	_press = ""
	queue_redraw()
	if was != "" and _hit(d) == was:
		match was:
			# Career/Contract keep an integer weekly ledger figure; the offer itself is
			# the engine's yearly value, converted only at the boundary.
			"offer": offer_made.emit(int(round(float(_offer_yearly) / float(Contract.SEASON_WEEKS))),
					_offer_years, _offer_clauses.duplicate())
			"cancel": renew_cancelled.emit()
			"ok": back_pressed.emit()


# ---- derived values --------------------------------------------------------

func _attrs() -> Dictionary:
	var a: Variant = _p.get("attrs", {})
	return a if a is Dictionary else {}

func _attr(key: String) -> int:
	var v: Variant = _attrs().get(key)
	return int(v) if v != null else 0

## The REAL rating (FUN_00581e60, docs/re/morale_re.md): (VE+RE+AG+CA+FITNESS
## +MORALE)/6 — matches frames 081/084 exactly (VdG 80, Solskjaer 82), so the
## RATING box is parity-INCLUDED again. The card's own fitness/moral fallbacks
## keep pre-career dicts rendering like a freshly loaded squad.
func _rating() -> int:
	var a := _attrs()
	if a.is_empty():
		return 0
	return (_attr("VE") + _attr("RE") + _attr("AG") + _attr("CA")
		+ _fitness() + _moral()) / 6

## FITNESS / MORAL are dynamic form, not static attrs; live career fields when
## present, else the match-fit / settled defaults of a freshly loaded squad.
func _fitness() -> int:
	return clampi(int(_p.get("fitness", 99)), 0, 99)

func _moral() -> int:
	return clampi(int(_p.get("morale", _p.get("moral", 85))), 0, 99)

func _clauses() -> Array:
	var c: Variant = _p.get("clauses", [])
	return c if c is Array else []


# ---- drawing -----------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int) -> void:
	PMChrome.text(self, f, x, y_top, s, col, sz)

## A decoded field's upper-cased text, or "-" when the source record left it null/empty
## (undecoded foreign/reserve players). Never invents a value. Guards the FICHA against the
## Dictionary.get(k, default)-returns-null-when-present trap that rendered "<NULL>".
static func _decoded_or_dash(raw: Variant) -> String:
	return str(raw).to_upper() if raw != null and str(raw) != "" else "-"


func _ctxt(f: Font, cx: float, y_top: float, s: String, col: Color, sz: int) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(f, cx - w * 0.5, y_top, s, col, sz)


func _draw() -> void:
	var s := _scale()
	if not host_dims:
		# interim flat backdrop for hosts without LUT-dim support (DATA BASE);
		# the frame-true dim is the host's own palette remap (SquadScreen)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.10, 0.86), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, CARD_POS)

	_draw_header()
	if _renew:
		_draw_offer()
	else:
		_draw_identity()
		_draw_stats()
	_draw_contract()
	_draw_clauses()
	_draw_buttons()


func _draw_header() -> void:
	# Borderless 32x32 block left of the name bar, only when face art exists
	# (photo-less players show none — frame truth; kernel un-RE'd).
	#
	# It is the MINIFOTO thumbnail blitted 1:1, NOT the 124x182 BIGFOTO squashed into the
	# rect. Measured 2026-08-02 against the walkthrough's own FICHA frames (079/081/084,
	# rect (130,68) 32x32): the MINI bank matches at **0 px**, the downscaled BIG at 974.
	# The mistake was invisible until the face banks were re-baked against MANAGER.PAL,
	# because both banks were wrong in the same direction.
	var face := PMChrome.mini_face(_p.get("photoId"))
	if face != null:
		draw_texture(face, PHOTO_RECT.position)
	# single-struck PROMAN12 — the face's natural weight IS the frame's bold look
	_txt(_f12, NAME_XY.x, NAME_XY.y, PMChrome.card_name(_p), C_WHITE, 13)
	# The POSITION word sits in the identity zone the OFFER panel replaces -> hide it in renew mode.
	if _renew:
		return
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
	# NATIONALITY (MINIBAND mini, borderless) / KIND. Every player now carries a real
	# nationality: the engine's own per-player country code (EQUIPOS byte +0x1a -> PAISES.30 ->
	# BANDERAS flag; build_db flagCode == that code). The null-guard below is a safety net only
	# (draw NO flag + honest "-" rather than an invented country if a record ever lacks one),
	# matching the weight / height gap convention.
	var nat_raw: Variant = _p.get("nationality")
	if nat_raw != null and str(nat_raw) != "":
		var flag := PMChrome.mini_flag(_p.get("flagCode"))
		if flag != null:
			draw_texture(flag, NAT_FLAG)
		_ctxt(_f8, NAT_CX, IDENT_Y, str(nat_raw).to_upper(), C_WHITE, 11)
	else:
		_ctxt(_f8, NAT_CX, IDENT_Y, "-", C_WHITE, 11)
	_ctxt(_f8, KIND_CX, IDENT_Y, _decoded_or_dash(_p.get("kind")), C_WHITE, 11)
	# ROLE: camrol sprite (SAD 0.0; alpha-0 ring restored by the black backing)
	draw_rect(Rect2(CAMROL_XY, Vector2(25, 14)), C_BLACK, true)
	var pf := PMChrome.iget(_p, "posFine")
	PMChrome.draw_role_icon(self, Rect2(CAMROL_XY, Vector2(25, 14)),
		pf, str(_p.get("pos", "")))
	var role: String
	if pf >= 1 and pf <= FINE_ROLE.size():
		role = FINE_ROLE[pf - 1]
	else:
		role = str(POS_WORD.get(str(_p.get("pos", "")), "OUTFIELD"))
	_ctxt(_f8, ROLE_CX, ROLE_Y, role, C_WHITE, 11)
	# STATUS / INSURANCE
	var st := Availability.status(_p)
	var st_s := str(st["state"]) if st["state"] == "FIT" else "%s %dw" % [st["state"], int(st["weeks"])]
	_ctxt(_f8, STATUS_CX, STATUS_Y, st_s, C_WHITE, 11)
	_ctxt(_f8, INSUR_CX, STATUS_Y, "NONE", C_WHITE, 11)
	# club kit (32x37 frame patch where one exists) + title-cased name
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
	var rows := [_attr("VE"), _attr("RE"), _attr("AG"), _attr("CA"), _fitness(), _moral()]
	for i in rows.size():
		_ctxt(_f8, STAT_CX, STAT_Y0 + STAT_PITCH * i, str(rows[i]), C_BLACK, 11)
	# RATING = the real formula, drawn one size up from the value cells: frames
	# 081/084 measure the RATING digit at 8px tall vs the value cells' 6px, so
	# proman12 @13 (not the value-cell proman8) — 0px at RATING_C.
	_ctxt(_f12, RATING_C.x, RATING_C.y, str(_rating()), C_RATING, 13)
	# skill strip: halves = (value+1) div 10 — the rule fitting ALL star
	# observations to date (team-offer 086/090, make-offer 101, ficha 081/084)
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


## The RENEW OFFER panel: the baked overlay chrome + the dynamic offered figures
## (CLUB FEE / YEARLY WAGE / YEARS) and the CLAUSES checkboxes (his current clauses; the
## clause-negotiation economics are un-RE'd, so the boxes reflect, they don't re-negotiate).
func _draw_offer() -> void:
	if _renew_overlay != null:
		draw_texture(_renew_overlay, RENEW_OVERLAY_XY)
	_ctxt(_f8, OFF_MONEY_CX, OFF_FEE_Y, "£%s" % _money(_fee), C_GOLD, 11)
	_ctxt(_f8, OFF_MONEY_CX, OFF_WAGE_Y, "£%s" % _money(_offer_yearly), C_WAGE, 11)
	_ctxt(_f8, OFF_YEARS_C.x, OFF_YEARS_C.y, str(_offer_years), C_YEARS_INK, 11)
	# The OFFERED clause state, not his current one — these boxes are editable.
	for i in 4:
		var tex: Texture2D = _check_on if _offer_clauses.has(i) else _check_off
		if tex != null:
			draw_texture(tex, Vector2(CB_X, OFF_CB_YS[i]))
	# the bottom RENEW button stays ringed while the OFFER form is up (frame 25)
	draw_rect((BTN["renew"] as Rect2).grow(2.0), C_RING, false, 2.0)
	# press feedback on the OFFER / CANCEL buttons (red ring, card doctrine)
	if _press == "offer":
		draw_rect(OFF_OFFER.grow(1.0), C_RING, false, 2.0)
	elif _press == "cancel":
		draw_rect(OFF_CANCEL.grow(1.0), C_RING, false, 2.0)


func _draw_contract() -> void:
	_ctxt(_f8, MONEY_CX, FEE_VAL_Y, "£%s" % _money(_fee), C_GOLD, 11)
	_ctxt(_f8, MONEY_CX, WAGE_VAL_Y, "£%s" % _money(_yearly), C_WAGE, 11)
	_ctxt(_f8, YEARS_C.x, YEARS_C.y, str(_years) if _years > 0 else "-", C_YEARS, 11)
	_ctxt(_f8, LEFT_C.x, LEFT_C.y, str(_left) if _left > 0 else "-", C_LEFT, 11)


## The CLAUSES column. Frame truth (081/084): a checked clause = black 11x11
## box border, white 9x9 interior, solid 7x7 (255,31,0) core + BLACK label; a
## resting clause = grey-144 border, field-grey interior + grey label. Active
## labels carry their figure — "Matches to renew (20)", "Scoring bonus
## (£5,000)" — and a progress sub-line below ("Matches played: 0" / "Goals:
## 0"). Our model stores the clause indices at signing (`clauses`), the bonus
## figure (`clause_bonus`) and live counters (`clause_apps` / `clause_goals`,
## advanced by Career.advance_week); a matches-to-renew TARGET is not yet
## negotiable on the make-offer card (its stepper is washed/valueless,
## un-RE'd), so the count renders only when `clause_matches` exists.
func _draw_clauses() -> void:
	var on := _clauses()
	var labels := ["Free if relegated", "Matches to renew", "Scoring bonus", "House and car"]
	if on.has(1) and _p.get("clause_matches") != null:
		labels[1] = "Matches to renew (%d)" % int(_p.get("clause_matches"))
	if on.has(2) and _p.get("clause_bonus") != null:
		labels[2] = "Scoring bonus (£%s)" % _money(int(_p.get("clause_bonus")))
	for i in 4:
		var by := int(CB_YS[i])
		var checked: bool = on.has(i)
		if checked:
			draw_rect(Rect2(CB_X, by, 11, 11), C_BLACK, true)
			draw_rect(Rect2(CB_X + 1, by + 1, 9, 9), C_WHITE, true)
			draw_rect(Rect2(CB_X + 2, by + 2, 7, 7), C_CHECK, true)
		else:
			draw_rect(Rect2(CB_X, by, 11, 11), C_WASHED, true)
			draw_rect(Rect2(CB_X + 1, by + 1, 9, 9), C_FIELD, true)
		_txt(_f8, LABEL_X, float(by), labels[i], C_BLACK if checked else C_WASHED, 11)
	if on.has(1):
		_txt(_f8, LABEL_X, SUB_MATCHES_Y, "Matches played: %d" % int(_p.get("clause_apps", 0)),
			C_BLACK, 11)
	if on.has(2):
		_txt(_f8, LABEL_X, SUB_GOALS_Y, "Goals: %d" % int(_p.get("clause_goals", 0)),
			C_BLACK, 11)


## Buttons are baked chrome. Read-only cards cover the three action buttons
## with card white (the browse-opened FICHA is un-walked — documented app
## behaviour). Held OK = the frame-cut ring; the same ring is extrapolated
## onto RENEW / TRANSFER / SACK (identical widget chrome, make-offer doctrine).
func _draw_buttons() -> void:
	if _youth:
		_draw_youth_buttons()
		return
	if not _actions:
		for k in ["renew", "transfer", "sack"]:
			draw_rect(BTN[k] as Rect2, C_WHITE, true)
	# Transfer-listed: the "PLAYER PLACED ON TRANSFER MARKET" banner (frame 14) sits in the
	# card-white strip above the button row; the TRANSFER button keeps a red outline. Only a
	# manager's OWN squad player can be listed, so it never shows on a read-only browse card.
	elif _listed:
		_ctxt(_f10, LISTED_BANNER_CX, LISTED_BANNER_Y, LISTED_BANNER, C_LISTED, 10)
		draw_rect((BTN["transfer"] as Rect2).grow(2.0), C_RING, false, 2.0)
	if _press == "ok" and _ok_pr != null:
		draw_texture(_ok_pr, OK_PR_XY)
	elif _press != "" and _actions:
		draw_rect((BTN[_press] as Rect2).grow(2.0), C_RING, false, 2.0)


## The YOUTH card's own row (FUN_005274d0). The baked senior row underneath is covered
## with card white first — the two rows sit at different y (325 vs 329 card-local), so the
## senior plates would peek out from under the youth ones.
func _draw_youth_buttons() -> void:
	var cover := Rect2(BTN["renew"].position.x - 40.0, BTN["renew"].position.y - 2.0,
		(BTN["ok"].position.x + BTN["ok"].size.x) - BTN["renew"].position.x + 60.0, 29.0)
	draw_rect(cover, C_WHITE, true)
	for k in ["training", "sack", "promote", "cancel"]:
		var on := true
		if k == "training":
			on = _training_on
		elif k == "promote":
			on = _promote_on
		var art: String = (YBTN_ART[k] as Array)[1 if on else 0]
		var tex: Texture2D = _ybtn.get(art)
		if tex != null:
			draw_texture(tex, (BTN_YOUTH[k] as Rect2).position)
		if _press == "y_" + k:
			draw_rect((BTN_YOUTH[k] as Rect2).grow(2.0), C_RING, false, 2.0)


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
