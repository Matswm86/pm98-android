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
## 2026-06-26) where the original converted to imperial; the RATING box renders
## our squad-AV (the FICHA rating formula is un-RE'd) — both parity-excluded,
## as is the animated info coin and the BIGFOTO block (downscale kernel
## un-RE'd, NEAREST fit).
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
const RATING_C := Vector2(525, 131)
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
var _f14: Font

var _p: Dictionary = {}
var _club: Dictionary = {}
var _tier: int = 1
var _actions := false   # RENEW/TRANSFER/SACK live (manager's own squad player)
var _press := ""
## The host screen LUT-dims itself while this card is up (SquadScreen); when it
## can't yet, the card draws the old flat backdrop instead (documented interim).
var host_dims := false
# Contract figures shown in the panel (computed from the model in setup; the
# parity harness pins the frame values directly).
var _fee := 0
var _yearly := 0
var _years := 0
var _left := 0


func _ready() -> void:
	_chrome = load("res://art/screens/ficha/chrome.png")
	_ok_pr = load("res://art/screens/ficha/ok_pr.png")
	_star_full = load("res://art/screens/teamoffer/star_full.png")
	_star_half = load("res://art/screens/teamoffer/star_half.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f14 = PMChrome.font("14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the player + his club (kit/name) + league tier (fee/wage). The three
## action buttons show only for the manager's own squad player.
func setup(player: Dictionary, club: Dictionary, tier: int = 1, actions_enabled := false) -> void:
	_p = player
	_club = club
	_tier = maxi(1, tier)
	_actions = actions_enabled
	_fee = TransferMarket.value_of(player, _tier)
	_yearly = Contract.yearly(Contract.current_weekly(player, _tier))
	_left = int(player.get("contract_years", 0))
	_years = maxi(int(player.get("contract_term", 0)), _left)
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(pt: Vector2) -> Vector2:
	var s := _scale()
	return (pt - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
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
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was != "" and _hit(d) == was:
		match was:
			"renew": renew_requested.emit(_p)
			"transfer": transfer_requested.emit(_p)
			"sack": sack_requested.emit(_p)
			_: back_pressed.emit()
		return
	back_pressed.emit()


# ---- derived values --------------------------------------------------------

func _attrs() -> Dictionary:
	var a: Variant = _p.get("attrs", {})
	return a if a is Dictionary else {}

func _attr(key: String) -> int:
	var v: Variant = _attrs().get(key)
	return int(v) if v != null else 0

## Overall rating == the squad-AV (mean of the 8 outfield attrs). The FICHA's
## own formula is un-RE'd (frames show 80/82 where this gives 79/82) — the
## RATING box is parity-excluded until the FUN_0052e0d0 rating read is found.
func _rating() -> int:
	var a := _attrs()
	var sum := 0.0
	var n := 0
	for k in AVG_KEYS:
		if a.has(k):
			sum += float(a[k])
			n += 1
	return int(round(sum / n)) if n > 0 else 0

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
	_draw_identity()
	_draw_stats()
	_draw_contract()
	_draw_clauses()
	_draw_buttons()


func _draw_header() -> void:
	# borderless 32x32 BIGFOTO block left of the name bar, only when face art
	# exists (photo-less players show none — frame truth; kernel un-RE'd)
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
	# ROLE: camrol sprite (SAD 0.0; alpha-0 ring restored by the black backing)
	draw_rect(Rect2(CAMROL_XY, Vector2(25, 14)), C_BLACK, true)
	PMChrome.draw_role_icon(self, Rect2(CAMROL_XY, Vector2(25, 14)),
		int(_p.get("posFine", 0)), str(_p.get("pos", "")))
	var pf := int(_p.get("posFine", 0)) if _p.get("posFine") != null else 0
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
	_ctxt(_f14, RATING_C.x, RATING_C.y, str(_rating()), C_RATING, 15)
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
	if not _actions:
		for k in ["renew", "transfer", "sack"]:
			draw_rect(BTN[k] as Rect2, C_WHITE, true)
	if _press == "ok" and _ok_pr != null:
		draw_texture(_ok_pr, OK_PR_XY)
	elif _press != "" and _actions:
		draw_rect((BTN[_press] as Rect2).grow(2.0), C_RING, false, 2.0)


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
