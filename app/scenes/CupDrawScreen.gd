extends Control
class_name CupDrawScreen
## PM98 SORTEO — the cup DRAW screen, the original's own.
##
## This is the screen MANAGER.EXE raises when a knockout round is drawn: a bezelled
## left panel with the competition's name, its trophy beside the lottery drum, a yellow
## ROUND plate under them, the green MATCHES list filling one club at a time on the
## right, the 1ST LEG / 2ND LEG (or MATCH / REPLAY) plates bottom-left, and FINISH +
## CONTINUE. It replaces the invented `CupScreen` marble panels.
##
## Everything here is measured off three real frames — `74_after_wk4.png` and
## `75_scout_wk5.png` (Coca-Cola Cup ROUND 2, mid-draw and later) and
## `10_fa_cup_draw_round1.png` (F.A. Cup ROUND 1) — and the art is the game's own,
## named by MANAGER.EXE itself at 0x255670-0x255aa4 (`img\sorteo\frames\...`).
## Chrome: tools/re/build_cupdraw_chrome_from_frames.py. Art: tools/re/export_sorteo_art.py.
## Full derivation + the residual list: docs/re/cupdraw_screen_re.md.
##
## The picture layer reproduces the real frame at 100.0000% exact pixels: the window is
## cleared to black, the competition's 72x144 SORTEO strip goes at (31,76), the 188x144
## drum backdrop at (103,76), and one of the twelve 92x92 BOMBO frames at (136,76) drawn
## OPAQUE — its index-0 pixels land as black in the original, which is why a transparent
## blit left 168 stray pixels.
##
## THE MATCHES PANEL HAS TWO FORMS, and the switch is LIST LENGTH (REFRUN R8): a round
## of MORE than 16 ties draws one centred `Home - Away` line per tie over 23 scrollable
## rows; a round of 16 or fewer draws a 16-row GRID of four columns -- home kit, home
## club, away club, away kit -- with no scrollbar at all. Both forms are the original's,
## each with its own baked chrome. Witnessed on four frames of the reference run: the
## Coca-Cola Cup ROUND 3 and the F.A. Cup ROUND 4 (16 ties -> grid) against the F.A. Cup
## ROUND 3 and the Coca-Cola ROUND 2 (32 and 25 ties -> list).
##
## THE BOTTOM-LEFT PANEL IS A TIE-DETAIL CARD, and it is populated (R8): the two clubs'
## kits, each club's name over its manager's, and the two legs' grounds beside the
## MATCH / REPLAY (or 1ST LEG / 2ND LEG) plates. Every line's font and pen was solved
## against p0131 and p0747 at ZERO differing pixels, and the MANAGER'S OWN name comes out
## green (42,191,85) where another manager's is pale blue.
##
## THE DRAW IS A ONE-BY-ONE REVEAL, witnessed end to end (REFRUN, Coca-Cola ROUND 3,
## 2026-07-27 forensics): `p0125` empty grid, drum on BOMBO03 -> `p0126` ONE tie landed,
## drum on BOMBO08 -> `p0127` the HAND out of the drum — MANO7 byte-exact at (106,144) —
## holding the slip with the NEXT club's name ("Bradford City", tie 2's HOME side, not
## yet in the grid) -> `p0131` the full grid, drum parked on BOMBO00. So: the drum SPINS
## during the draw (every mid-draw frame is on a different BOMBO), each CLUB is revealed
## on the hand's slip and then lands in MATCHES (home first, then away), and a finished
## draw parks on BOMBO00 — which is why the 2026-07-25 film of an already-finished draw
## "did not animate": it was parked, not proof there is no animation.
## The slip name: calend12, pen centred on field-sum 380, pen top 152, inked through the
## slip's own tones — (192)->114 flat, (240)->144 flat, (220)-> a 144/128 checkerboard
## by (x+y) parity — all 265 name-ink pixels of p0127 reproduce exactly.
## OURS, flagged: the reveal CADENCE (rise/hold/gap timings), the MANO0..6 rising
## sequence's use and rate, extending the reveal to the LIST form (witnessed only on the
## grid), and tap-to-skip. BOLA0..3 stay exported and unused (no witnessed frame).
## The CONTINUE ball's lit/unlit rule is unknown, so the chrome keeps frame 74's phase.
## The white row the frames show is a MOUSE-HOVER highlight, which a touch app has no
## equivalent of -- it is bound to the tapped row instead, so the state is the
## original's own even though the trigger cannot be.

signal continue_pressed
signal finish_pressed
## A MATCHES row was tapped (grid form): its index in `ties`. The caller answers with
## `show_tie()` because only it knows the managers and the grounds.
signal tie_selected(row: int)

const W := 640
const H := 480

# ---- geometry (tools/re/specs/cupdraw_chrome_samples.json) ------------------
const PICTURE := Rect2(31, 76, 260, 144)
const STRIP_AT := Vector2(31, 76)
const FONDO_AT := Vector2(103, 76)
const BOMBO_AT := Vector2(136, 76)

# ---- the reveal (witnessed p0125 -> p0126 -> p0127 -> p0131) ----------------
const MANO_AT := Vector2(106, 144)   # MANO7 byte-exact on p0127
const SLIP_SUM := 380                # name pen centres here (calend12; solved, 0 px)
const SLIP_PEN_TOP := 152            # absolute pen top of the slip name
# The slip's three tones and the ink each one takes (all 265 name pixels of p0127):
# (192)->114, (240)->144, (220)-> 144 when (x+y) even, 128 when odd.
const SLIP_INK := {192: 114, 240: 144}
const SLIP_DITHER_EVEN := 144
const SLIP_DITHER_ODD := 128
# Cadence — OURS, flagged: no two witnessed stills are a known time apart, so these are
# chosen for readability, and any tap skips straight to the finished draw.
const REVEAL_RISE := 0.35            # MANO0..7 rising
const REVEAL_HOLD := 0.85            # MANO7 + the name held readable
const REVEAL_GAP := 0.15             # hand away before the next club

# Both witnessed titles centre on the same field: pen_x = (TITLE_SUM - advance) / 2 gives
# 96 for "Coca-Cola Cup" (adv 133) and 121 for "F.A. Cup" (adv 83), which is where the two
# frames put them to the pixel. TOP is one less than the ink row because the BMFont cells
# carry an empty first row.
const TITLE_SUM := 325
const TITLE_TOP := 39
const C_TITLE := Color8(255, 255, 255)

const ROUND_SUM := 320          # 113 for "ROUND 2" (adv 93), 116 for "ROUND 1" (adv 88)
const ROUND_TOP := 236
const C_ROUND := Color8(255, 223, 0)

const LEG_SUM := 116            # 30 / 27 / 33 / 30 for 1ST LEG / 2ND LEG / MATCH / REPLAY
const LEG_TOPS := [413, 440]
const C_LEG := Color8(255, 255, 0)

const LIST_Y0 := 51
const LIST_PITCH := 16
const LIST_ROWS := 23
const LIST_TEXT_TOP := 2          # pen top inside the row band (row 0 ink lands at y 54)
const HOME_RIGHT := 465           # home club's pen END x — right-aligned
const DASH_X := 467               # the fixed "-" the game paints with the home club
const AWAY_LEFT := 475            # away club's pen START x
const C_ROW_TXT := Color8(80, 100, 120)

# Scrollbar. Trough interior y 70..401 (331 rows); the thumb is proportional and its
# height solves BOTH witnesses exactly: round(331 * 23 / ties) is 305 for the 25-tie
# Coca-Cola round 2 and 190 for the 40-tie F.A. Cup round 1, which is what they measure.
const SCROLL_X := 606           # the trough box is 18px wide; 606 and 622-623 are the
const SCROLL_W := 18            # THUMB's own black edges, and show trough colour without it
const TROUGH_Y := 70
const TROUGH_H := 331
const C_TROUGH := Color8(180, 200, 220)
const C_THUMB_CAP := Color8(220, 220, 220)
const C_THUMB_EDGE := Color8(60, 80, 100)
const C_THUMB_A := [Color8(120, 140, 160), Color8(120, 140, 160), Color8(120, 140, 160),
	Color8(100, 120, 140), Color8(100, 120, 140), Color8(100, 120, 140),
	Color8(100, 120, 140), Color8(114, 114, 114), Color8(114, 114, 114),
	Color8(114, 114, 114), Color8(114, 114, 114), Color8(80, 100, 120)]
const C_THUMB_B := [Color8(120, 140, 160), Color8(120, 140, 160), Color8(100, 120, 140),
	Color8(120, 140, 160), Color8(100, 120, 140), Color8(100, 120, 140),
	Color8(114, 114, 114), Color8(100, 120, 140), Color8(114, 114, 114),
	Color8(114, 114, 114), Color8(80, 100, 120), Color8(114, 114, 114)]

const BTN_FINISH := Rect2(350, 440, 112, 24)
const BTN_CONTINUE := Rect2(492, 438, 118, 28)

# ---- the GRID form, <= 16 ties (REFRUN R8) ---------------------------------
const GRID_MAX := 16          # the switch: <= 16 ties -> grid, more -> the list above
const GRID_ROWS_N := 16       # the grid always paints sixteen bands, drawn or not
const GRID_Y0 := 51
const GRID_PITCH := 23
const GRID_ROW_H := 22
const GRID_KIT_L := [334, 355]
const GRID_HOME := [356, 476]
const GRID_AWAY := [479, 599]
const GRID_KIT_R := [601, 622]
const GRID_PEN_TOP := 6       # pen top inside the row band
## Bands alternate and the INK follows the band; the manager's own tie takes a dark plate
## with his club in bright yellow, and the tapped row goes white. All four states are the
## frames' own.
const C_GRID_BG := [Color8(200, 220, 240), Color8(160, 180, 200)]
const C_GRID_KIT_BG := [Color8(180, 200, 220), Color8(140, 160, 180)]
const C_GRID_INK := [Color8(100, 120, 140), Color8(60, 80, 100)]
const C_GRID_OWN_BG := Color8(60, 60, 100)
const C_GRID_OWN_KIT_BG := Color8(40, 40, 80)
const C_GRID_OWN_INK := Color8(100, 120, 140)   # the side that is NOT the manager's club
const C_GRID_OWN_INK_MINE := Color8(255, 255, 85)
const C_GRID_SEL_BG := Color8(255, 255, 255)
const C_GRID_SEL_INK := Color8(60, 80, 100)

# ---- the tie-detail card (the bottom-left panel) ---------------------------
const CARD_CLUB_SUM := 325
const CARD_CLUB_TOPS := [323, 361]
const CARD_MGR_SUM := 325
const CARD_MGR_TOPS := [335, 373]
const CARD_STADIUM_SUM := 398
const CARD_STADIUM_TOPS := [411, 438]
const C_CARD_CLUB := Color8(255, 223, 0)
const C_CARD_MGR := Color8(166, 202, 240)
const C_CARD_MGR_OWN := Color8(42, 191, 85)
const C_CARD_STADIUM := Color8(42, 191, 255)
## The original's own hi-res panel kit art is un-extracted, so the app's kit texture is
## scaled into the measured rect -- the same documented approximation CompResultScreen
## and CharityShieldScreen already carry.
const CARD_KIT_L := Rect2(33, 325, 77, 56)
const CARD_KIT_R := Rect2(236, 329, 51, 56)

# ---- the SEMIFINAL form, a round of exactly TWO ties (s91 witness, s92 build) ----
## THE PANEL HAS A FOURTH FORM and it is the semifinal draw. The binary draws the
## `SEMIFINAL 1` / `SEMIFINAL 2` plates (0x653ecc / 0x653ec0, at 0x4dbee5 / 0x4dbf49,
## Proman12) when the round being drawn has exactly TWO ties (`[this+0x7798] == 2`).
## Witnessed on both leg variants from one patched-gate drive
## (`tools/re/refs/cupdraw-semifinals-2026-08-02/`): no MATCHES list, no grid — the
## stadium backdrop with a black label plate over each tie's own GRID-form row. The
## round plate reads `SEMIFINALS`; the two strings here are the TIE plates.
## Plates + backdrop + row bands are baked (`chrome_semis.png`,
## tools/re/build_semisdraw_chrome_from_frames.py); what is drawn is each landed club's
## name and its NANOESC kit. Every number is measured on both frames (they agree):
## plate ink field 359+595 in proman12, rows interior 33 px with the GRID form's own
## tones, names in proman10 on the same (S - adv) / 2 rule.
const SEMIS_ROWS_Y := [155, 307]      # tie row interior tops (33 rows tall each)
const SEMIS_ROW_H := 33
const SEMIS_KIT_L := [334, 359]       # cell interiors, inclusive x spans
const SEMIS_HOME := [361, 476]
const SEMIS_AWAY := [479, 594]
const SEMIS_KIT_R := [596, 621]
const SEMIS_PEN_TOP := 11             # name pen top inside the row interior (solved, 0 px)
## The row kit is the 24x32 NANOESC bank blitted at the cell interior's own origin
## (solved against all four witnessed kits), through the 0x20 EDGE + spread pass at
## THIS site's own parameters: thr 0x40 / cap 0x80 — the attested `(0x20, 0x40, 0x80)`
## triple of PMShadow's site survey. The sweep over every attested (thr, cap) pair
## lands this one at 0 px on all four witnessed kits; the group form's (0x20, 0x80)
## leaves 459.
const SEMIS_KIT_AT := Vector2i(0, 0)
const SEMIS_KIT_THR := 0x40
const SEMIS_KIT_CAP := 0x80

# ---- the GROUPS form, the European Cup's group phase (s88) -----------------
## THE PANEL HAS A THIRD FORM and it is the group draw. Witness (banked s87, driven under
## Wine from a Manchester Utd. career):
## `tools/re/refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png` --
## European Cup, round plate `1/8 FINAL`, the draw MID-REVEAL with GROUP A's four clubs
## landed and groups B..F still empty. Instead of MATCHES the right panel carries a white
## header plate reading GROUPS over six boxes in a 2x3 grid, each a green `GROUP <letter>`
## header over four `kit | club | flag` rows. The bottom-left tie card is entirely BLANK
## on this form, LEG PLATES INCLUDED, so this form draws neither.
##
## Every number below is measured off that frame by
## `tools/re/build_groupdraw_chrome_from_frame.py`, which also bakes `chrome_groups.png`.
## The bake is exact because five of the six boxes are empty and their row bands are
## pixel-identical to each other (0 px), so group C's band IS the empty widget and is what
## group A's populated band was cleared with. The word GROUP never changes and stays in the
## chrome, the same standing the green MATCHES header has; only the LETTER is drawn.
const GROUPS_SUM := 955           # proman12, BLACK on the plate's flat white
const GROUPS_TOP := 30
const C_GROUPS := Color8(0, 0, 0)
const GBOX_X := [326, 483]
const GBOX_Y := [55, 180, 305]
const GBOX_LETTER := Vector2i(119, 4)     # box-local pen of the group letter (proman12)
const C_GBOX_LETTER := Color8(255, 255, 255)
const GROW_Y0 := 20               # box-local y of row 0; four rows on a 25-px pitch
const GROW_PITCH := 25
const GROW_H := 24
const GROW_N := 4
const GKIT_AT := Vector2i(7, 2)   # box-local x, row-local y of the 17x20 RIDIESC kit
const GNAME_SUM := 177            # box-local: pen = box_x + (177 - advance) / 2
const GNAME_TOP := 1
## The MINIBAND flag, and a measurement this port does not explain away: the screen blits
## the sprite's rows 1..9 ONLY. At (box+80, row+13) the frame carries flat row background
## across all fourteen columns on every one of group A's four rows, while rows 1..9 sit at
## (box+80, row+14) and reproduce `art/flags/mini_%03d.png` to within the un-reversed 1-px
## edge pass. Drawn exactly as measured.
const GFLAG_AT := Vector2i(80, 14)
const GFLAG_SRC := Rect2(0, 1, 14, 9)
## The row ink alternates with the band, exactly as the GRID form's does.
const C_GROW_INK := [Color8(100, 120, 140), Color8(60, 80, 100)]

## The five competitions MANAGER.EXE loads a SORTEO strip for on THIS screen, plus the
## two more that ship one in IMG.PKF (charity / supercup) for the single-tie finals.
const STRIPS := {
	"fa_cup": "sorteo_facup",
	"league_cup": "sorteo_cocacola",
	"european_cup": "sorteo_european_cup",
	"uefa_cup": "sorteo_uefa",
	"cup_winners_cup": "sorteo_cup_winners",
	"charity_shield": "sorteo_charity",
	"supercup": "sorteo_supercup",
}

var _chrome: Texture2D
var _chrome_grid: Texture2D
var _chrome_groups: Texture2D
var _chrome_semis: Texture2D
var _fondo: Texture2D
var _bombo: Array[Texture2D] = []
var _strip: Texture2D
var _page10: Texture2D
var _page14: Texture2D
var _page12: Texture2D        # proman12 — the GROUPS plate and the box letters
var _page12c: Texture2D       # calend12 — the card's two manager lines
var _g10: Dictionary = {}
var _g14: Dictionary = {}
var _g12: Dictionary = {}
var _g12c: Dictionary = {}

var _title := ""                  # "Coca-Cola Cup" — the EXE's own spelling
var _round := ""                  # "ROUND 2" — the EXE's own uppercase label
var _legs: Array = ["MATCH", "REPLAY"]
var _ties: Array = []             # [{home: String, away: String}], away "" while undrawn
var _total := 0                   # ties in the round; drives the scrollbar
var _first := 0                   # first visible row
var _spin := 0.0                  # drum animation phase (seconds; reveal only)
var _pinned := -1                 # pin_drum's frame, or -1
var _press := ""
# The one-by-one reveal (see the docstring): a flattened list of the clubs in draw
# order; _reveal_step of them have LANDED in MATCHES, the one at _reveal_step is on
# the hand's slip. Inactive (-1 total) outside a reveal — the parked, finished state.
var _reveal_on := false
var _reveal_names: Array = []
var _reveal_step := 0
var _reveal_t := 0.0
var _mano: Array[Texture2D] = []
var _mano7_img: Image = null      # slip tones for the name ink LUT
var _slip_name := ""              # cache key for _slip_tex
var _slip_tex: Texture2D = null
var _font12c_img: Image = null
var _own_club_id := -1            # the manager's club — its tie takes the dark plate
var _own_manager := ""            # his name — it renders green on the card
var _sel := -1                    # the tapped row, whose tie fills the detail card
var _card: Dictionary = {}        # {home:{club,manager,stadium}, away:{...}} or {}
## The GROUPS form: [{letter, clubs: [{name, club_id, flag}]}] or [] for the other forms.
var _groups: Array = []


func _ready() -> void:
	_chrome = load("res://art/screens/cupdraw/chrome.png")
	_chrome_grid = load("res://art/screens/cupdraw/chrome_grid.png")
	_chrome_groups = load("res://art/screens/cupdraw/chrome_groups.png")
	_chrome_semis = load("res://art/screens/cupdraw/chrome_semis.png")
	_fondo = load("res://art/screens/cupdraw/fondo.png")
	for i in 12:
		var t: Texture2D = load("res://art/screens/cupdraw/bombo%02d_opaque.png" % i)
		if t != null:
			_bombo.append(t)
	for i in 8:
		var m: Texture2D = load("res://art/screens/cupdraw/mano%d.png" % i)
		if m != null:
			_mano.append(m)
	if _mano.size() == 8:
		_mano7_img = _mano[7].get_image()
	_page10 = PMFont.page_texture("proman10")
	_page14 = PMFont.page_texture("proman14")
	_page12 = PMFont.page_texture("proman12")
	_page12c = PMFont.page_texture("calend12")
	_g10 = PMFont.chars("proman10")
	_g14 = PMFont.chars("proman14")
	_g12 = PMFont.chars("proman12")
	_g12c = PMFont.chars("calend12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	# Parked on BOMBO00 until reveal() runs — the witnessed finished-draw state
	# (p0131, p0133, p0747). The old always-spinning idle was the port's invention.
	set_process(false)
	queue_redraw()


## Feed one round's draw.
##   key    — a STRIPS key, picks the competition's own trophy strip
##   title  — the competition name as MANAGER.EXE spells it ("F.A. Cup", "Coca-Cola Cup")
##   rnd    — the round label in the EXE's uppercase plate form ("ROUND 2", "QTR FINALS")
##   ties   — [{home, away}] in draw order; a trailing away "" is a club still waiting
##   total  — ties in the full round (>= ties.size()); sizes the scrollbar
##   legs   — the two bottom-left plates: ["1ST LEG","2ND LEG"] two-legged, else
##            ["MATCH","REPLAY"]
func setup(key: String, title: String, rnd: String, ties: Array, total: int,
		legs: Array, own_club_id := -1, own_manager := "") -> void:
	_title = title
	_round = rnd
	_ties = ties
	_total = maxi(total, ties.size())
	_legs = legs
	_first = 0
	_own_club_id = own_club_id
	_own_manager = own_manager
	_sel = -1
	_card = {}
	_groups = []
	var stem: String = str(STRIPS.get(key, "sorteo_facup"))
	_strip = load("res://art/screens/cupdraw/%s.png" % stem)
	queue_redraw()


## Feed the European Cup's GROUP phase draw — the panel's third form.
##   groups — [{letter: "A", clubs: [{name, club_id, flag}]}], up to four clubs a box and
##            up to six boxes; a short list is a draw still in progress, which is exactly
##            what the binding frame shows (group A full, B..F empty).
## The leg plates and the tie-detail card stay blank on this form: the witness has them
## blank, so nothing is drawn there rather than something being invented for them.
func setup_groups(key: String, title: String, rnd: String, groups: Array) -> void:
	_title = title
	_round = rnd
	_ties = []
	_total = 0
	_legs = []
	_first = 0
	_own_club_id = -1
	_own_manager = ""
	_sel = -1
	_card = {}
	_groups = groups
	var stem: String = str(STRIPS.get(key, "sorteo_european_cup"))
	_strip = load("res://art/screens/cupdraw/%s.png" % stem)
	queue_redraw()


## True while the screen is showing the group-phase draw rather than a knockout round.
func is_groups() -> bool:
	return not _groups.is_empty()


## True when the round is a SEMIFINAL: exactly two ties, the binary's own plate guard
## (`[this+0x7798] == 2`). A FINAL (one tie) is NOT this form — the guard also requires
## it, and no final draw has been witnessed, so a 1-tie round keeps the grid.
func is_semis() -> bool:
	return _total == 2 and _groups.is_empty()


## True when the round is short enough for the original's GRID form. The switch is the
## FULL round's tie count, not how many have been drawn so far, because the grid's
## sixteen row bands are painted before any club lands in them (frames p0125 / p0445).
func is_grid() -> bool:
	return _total <= GRID_MAX


## Fill the bottom-left tie-detail card. Each side is {club, manager, stadium}; the leg
## plates name the two grounds, so `stadium` is that side's own ground. Pass {} to clear.
func show_tie(card: Dictionary, row := -1) -> void:
	_card = card
	_sel = row
	queue_redraw()


## Hold the drum on one of the twelve frames (render-diff harness / a still capture).
func pin_drum(i: int) -> void:
	set_process(false)
	_reveal_on = false
	_pinned = i % 12
	queue_redraw()


## Play the draw as the original does (see the docstring): drum spinning, each club
## revealed on the hand's slip and then landing in MATCHES, park on BOMBO00 when done.
## Call after setup(); without it the screen shows the finished, parked draw.
func reveal() -> void:
	_reveal_names = []
	for tie in _ties:
		if str((tie as Dictionary).get("home", "")) != "":
			_reveal_names.append(str(tie["home"]))
		if str((tie as Dictionary).get("away", "")) != "":
			_reveal_names.append(str(tie["away"]))
	if _reveal_names.is_empty():
		return
	_reveal_on = true
	_reveal_step = 0
	_reveal_t = 0.0
	_spin = 0.0
	_pinned = -1
	set_process(true)
	queue_redraw()


## End the reveal instantly — the full grid, drum parked (tap-to-skip; OURS).
func skip_reveal() -> void:
	if not _reveal_on:
		return
	_reveal_on = false
	_reveal_step = _reveal_names.size()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	# The drum turns DURING the draw only (p0125/p0126 sit on different BOMBO frames;
	# every finished frame is parked). The RATE is not witnessed — 12/s is ours, flagged;
	# frames 74 and 10 hold BOMBO08 and BOMBO07 at the same spot, so the twelve cycle.
	if not _reveal_on or _bombo.is_empty():
		set_process(false)
		return
	_spin += delta
	_reveal_t += delta
	if _reveal_t >= REVEAL_RISE + REVEAL_HOLD:
		_reveal_step += 1
		_reveal_t = -REVEAL_GAP
		if _reveal_step >= _reveal_names.size():
			_reveal_on = false
			set_process(false)
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	# During the reveal any tap completes the draw instantly (OURS, flagged) — the
	# buttons and the row cards come back once the grid is full.
	if _reveal_on:
		if not e.pressed:
			skip_reveal()
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = "finish" if BTN_FINISH.has_point(d) else \
			("continue" if BTN_CONTINUE.has_point(d) else "")
	else:
		if _press == "finish" and BTN_FINISH.has_point(d):
			finish_pressed.emit()
		elif _press == "continue" and BTN_CONTINUE.has_point(d):
			continue_pressed.emit()
		elif _press == "":
			var r := _row_at(d)
			if r >= 0:
				tie_selected.emit(r)
		_press = ""
	queue_redraw()


## The MATCHES row under a design-space point, or -1. Grid + semifinal forms only: the
## list form's rows have no witnessed selected state beyond the same hover highlight,
## and no card content was ever captured for one.
func _row_at(d: Vector2) -> int:
	if is_semis():
		for k in mini(2, _ties.size()):
			if Rect2(SEMIS_KIT_L[0], int(SEMIS_ROWS_Y[k]),
					SEMIS_KIT_R[1] - SEMIS_KIT_L[0] + 1, SEMIS_ROW_H).has_point(d):
				return k
		return -1
	if not is_grid() or d.x < GRID_KIT_L[0] or d.x >= GRID_KIT_R[1]:
		return -1
	var r := int(floor((d.y - GRID_Y0) / float(GRID_PITCH)))
	if r < 0 or r >= GRID_ROWS_N or d.y < GRID_Y0:
		return -1
	return r if r < _ties.size() else -1


# ---- text ----------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		w += int(g.get("adv", 0))
	return w


## Blit one string from a PM98 BMFont atlas. The pages are pure white masks, so the
## colour is a modulate; `x` is the PEN origin and `y_top` the pen's top row.
func _txt(page: Texture2D, glyphs: Dictionary, x: int, y_top: int, s: String,
		col: Color) -> void:
	if page == null:
		return
	var pen := x
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])


## Centre on a field given as the SUM of its two edges, which is how both witnessed
## title/round/leg strings land: pen = (sum - advance) / 2, floored.
@warning_ignore("integer_division")
func _txt_field(page: Texture2D, glyphs: Dictionary, field_sum: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, (field_sum - _advance(glyphs, s)) / 2, y_top, s, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	var groups := is_groups()
	var semis := is_semis()
	var grid := is_grid()
	var chrome: Texture2D = _chrome_groups if groups else (_chrome_semis if semis else
		(_chrome_grid if grid else _chrome))
	if chrome != null:
		draw_texture(chrome, Vector2.ZERO)

	_draw_picture()
	_txt_field(_page14, _g14, TITLE_SUM, TITLE_TOP, _title, C_TITLE)
	if not semis:
		# The semifinal chrome bakes its ROUND plate WITH the text: a 2-tie round always
		# reads SEMIFINALS, and the plate text carries a dithered drop shadow that plain
		# yellow ink cannot reproduce (37 px on the witness without it).
		_txt_field(_page14, _g14, ROUND_SUM, ROUND_TOP, _round, C_ROUND)
	for i in mini(_legs.size(), LEG_TOPS.size()):
		_txt_field(_page10, _g10, LEG_SUM, int(LEG_TOPS[i]), str(_legs[i]), C_LEG)
	if groups:
		_draw_groups()
	elif semis:
		_draw_semis()
	elif grid:
		_draw_grid()
	else:
		_draw_rows()
		_draw_scrollbar()
	_draw_card()
	if _press != "":
		draw_rect(BTN_FINISH if _press == "finish" else BTN_CONTINUE,
			Color(1, 1, 1, 0.18), true)


## The ties as the current reveal step shows them: clubs land one at a time, home
## before away (p0126/p0127) — a club not yet landed reads as un-drawn, which both
## panel forms already render (the away-empty partial states of frames 74/75).
func _masked_ties() -> Array:
	if not _reveal_on:
		return _ties
	var out: Array = []
	var n := _reveal_step
	for tie in _ties:
		var t: Dictionary = (tie as Dictionary).duplicate()
		if str(t.get("home", "")) != "":
			if n > 0:
				n -= 1
			else:
				t["home"] = ""
				t["home_id"] = -1
		if str(t.get("away", "")) != "":
			if n > 0:
				n -= 1
			else:
				t["away"] = ""
				t["away_id"] = -1
		out.append(t)
	return out


## The GROUPS form: the white GROUPS plate, then six boxes of four `kit | club | flag`
## rows. The boxes, their green headers and the word GROUP are the chrome's; what is drawn
## here is the per-box LETTER and, for each club that has landed, its RIDIESC kit, its name
## centred on the box's own field and its MINIBAND flag.
@warning_ignore("integer_division")
func _draw_groups() -> void:
	_txt_field(_page12, _g12, GROUPS_SUM, GROUPS_TOP, "GROUPS", C_GROUPS)
	for g in mini(_groups.size(), GBOX_X.size() * GBOX_Y.size()):
		var box: Dictionary = _groups[g]
		var bx: int = int(GBOX_X[g % GBOX_X.size()])
		var by: int = int(GBOX_Y[g / GBOX_X.size()])
		_txt(_page12, _g12, bx + GBOX_LETTER.x, by + GBOX_LETTER.y,
			str(box.get("letter", "")), C_GBOX_LETTER)
		var clubs: Array = box.get("clubs", [])
		for k in mini(clubs.size(), GROW_N):
			var club: Dictionary = clubs[k]
			var y := by + GROW_Y0 + GROW_PITCH * k
			_txt_field(_page10, _g10, bx * 2 + GNAME_SUM, y + GNAME_TOP,
				str(club.get("name", "")), C_GROW_INK[k & 1])
			var kit := PMChrome.ridi_kit(int(club.get("club_id", -1)))
			if kit != null:
				_group_kit(kit, Vector2i(bx + GKIT_AT.x, y + GKIT_AT.y),
					int(club.get("club_id", -1)))
			var flag := PMChrome.mini_flag(club.get("flag", -1))
			if flag != null:
				_group_flag(flag, Vector2i(bx + GFLAG_AT.x, y + GFLAG_AT.y),
					int(club.get("flag", -1)))


## The group draw's kit is not a plain blit. `0x5c0688` — the RIDIESC picture widget's own
## call into `FUN_005cbea0` — is a `flags = 0x20` site, so it runs the EDGE pass
## (`FUN_005d60a0`) and then the same IIR spread the 0x10 arm uses: a darkened rim INSIDE
## the silhouette and a dithered drop shadow down-and-right OUTSIDE it. The chrome under
## the cell is the empty row widget, which is exactly what `chrome_groups.png` carries.
##
## `tools/re/probe_groupdraw_edge_render.py` grades this against the real frame
## `manutd_s1_eurocup_groups_1_8_final.png`: all four of group A's kits land at **0 px**,
## against 345 for the plain blit this replaces.
const GKIT_THR := 0x20   # site 0x5c0688 pushes thr/cap as registers; see PMShadow's note
const GKIT_CAP := 0x80


func _group_kit(kit: Texture2D, at: Vector2i, club_id: int) -> void:
	if _chrome_groups == null:
		draw_texture(kit, Vector2(at))
		return
	var bg := _chrome_groups.get_image().get_region(
		Rect2i(at, Vector2i(kit.get_width(), kit.get_height())))
	var t := PMShadow.edge_texture("gkit%d@%d,%d" % [club_id, at.x, at.y],
		bg, kit.get_image(), at, GKIT_THR, GKIT_CAP)
	draw_texture(t if t != null else kit, Vector2(at))


## The MINIBAND flag beside the name goes through the same widget and the same pass. It is
## scored the same way and lands at **4 px over the four rows**, against 37 for the plain
## blit. The residual is the sprite's ROW 0, which this screen does not draw at all (the
## chrome builder records that measurement and does not explain it) — so the pass's top row
## is computed against a destination that is not on screen, and its bottom neighbours
## inherit that. Recorded rather than tuned away.
func _group_flag(flag: Texture2D, at: Vector2i, code: int) -> void:
	if _chrome_groups == null:
		draw_texture_rect_region(flag,
			Rect2(at.x, at.y, GFLAG_SRC.size.x, GFLAG_SRC.size.y), GFLAG_SRC)
		return
	var si := flag.get_image()
	var bg := Image.create(si.get_width(), si.get_height(), false, Image.FORMAT_RGBA8)
	var chrome := _chrome_groups.get_image()
	# The blit's own origin is one row ABOVE the drawn band, because the screen takes the
	# sprite from row 1 (GFLAG_SRC.position.y).
	var org := Vector2i(at.x, at.y - int(GFLAG_SRC.position.y))
	for yy in si.get_height():
		for xx in si.get_width():
			var cy: int = org.y + yy
			var cx: int = org.x + xx
			if cx < chrome.get_width() and cy >= 0 and cy < chrome.get_height():
				bg.set_pixel(xx, yy, chrome.get_pixel(cx, cy))
	var t := PMShadow.edge_texture("gflag%d@%d,%d" % [code, org.x, org.y],
		bg, si, org, GKIT_THR, GKIT_CAP)
	if t == null:
		draw_texture_rect_region(flag,
			Rect2(at.x, at.y, GFLAG_SRC.size.x, GFLAG_SRC.size.y), GFLAG_SRC)
		return
	draw_texture_rect_region(t, Rect2(at.x, at.y, GFLAG_SRC.size.x, GFLAG_SRC.size.y),
		GFLAG_SRC)


## The SEMIFINAL form: two GRID-form rows at the measured pitch, each under its baked
## `SEMIFINAL 1` / `SEMIFINAL 2` plate. What is drawn per landed club is its proman10
## name centred on the cell's own field and its NANOESC kit through the 0x20 edge pass;
## an un-landed side shows the cleared band, exactly as the grid's does. The own-tie
## dark plate and the tapped-row white are the GRID form's witnessed states, carried
## over to this form's rows — OURS, flagged: no semifinal frame shows either.
func _draw_semis() -> void:
	var ties := _masked_ties()
	for k in mini(2, ties.size()):
		var tie: Dictionary = ties[k]
		var home := str(tie.get("home", ""))
		var away := str(tie.get("away", ""))
		if home == "" and away == "":
			continue
		var y: int = int(SEMIS_ROWS_Y[k])
		var hid := int(tie.get("home_id", -1))
		var aid := int(tie.get("away_id", -1))
		var mine: bool = _own_club_id >= 0 and (hid == _own_club_id or aid == _own_club_id)
		var ink: Color = C_GRID_INK[1]
		if mine:
			_fill_semis_row(y, C_GRID_OWN_BG, C_GRID_OWN_KIT_BG)
			ink = C_GRID_OWN_INK
		elif k == _sel:
			_fill_semis_row(y, C_GRID_SEL_BG, C_GRID_SEL_BG)
			ink = C_GRID_SEL_INK
		var pen := y + SEMIS_PEN_TOP
		if home != "":
			_txt_field(_page10, _g10, SEMIS_HOME[0] + SEMIS_HOME[1], pen, home,
				C_GRID_OWN_INK_MINE if (mine and hid == _own_club_id) else ink)
			_semis_kit(SEMIS_KIT_L, y, hid)
		if away != "":
			_txt_field(_page10, _g10, SEMIS_AWAY[0] + SEMIS_AWAY[1], pen, away,
				C_GRID_OWN_INK_MINE if (mine and aid == _own_club_id) else ink)
			_semis_kit(SEMIS_KIT_R, y, aid)


## Repaint one semifinal band cell by cell, sparing the black separators (the chrome's).
func _fill_semis_row(y: int, bg: Color, kit_bg: Color) -> void:
	draw_rect(Rect2(SEMIS_KIT_L[0], y, SEMIS_KIT_L[1] - SEMIS_KIT_L[0] + 1, SEMIS_ROW_H),
		kit_bg, true)
	draw_rect(Rect2(SEMIS_HOME[0], y, SEMIS_HOME[1] - SEMIS_HOME[0] + 1, SEMIS_ROW_H),
		bg, true)
	draw_rect(Rect2(SEMIS_AWAY[0], y, SEMIS_AWAY[1] - SEMIS_AWAY[0] + 1, SEMIS_ROW_H),
		bg, true)
	draw_rect(Rect2(SEMIS_KIT_R[0], y, SEMIS_KIT_R[1] - SEMIS_KIT_R[0] + 1, SEMIS_ROW_H),
		kit_bg, true)


## The 24x32 NANOESC kit at the cell interior's origin, through the 0x20 edge pass at
## this site's own (thr 0x40, cap 0x80), against the baked chrome under it.
func _semis_kit(cell: Array, y: int, club_id: int) -> void:
	var kit := PMChrome.nano_kit(club_id)
	if kit == null:
		return
	var at := Vector2i(int(cell[0]) + SEMIS_KIT_AT.x, y + SEMIS_KIT_AT.y)
	if _chrome_semis == null:
		draw_texture(kit, Vector2(at))
		return
	var bg := _chrome_semis.get_image().get_region(
		Rect2i(at, Vector2i(kit.get_width(), kit.get_height())))
	var t := PMShadow.edge_texture("skit%d@%d,%d" % [club_id, at.x, at.y],
		bg, kit.get_image(), at, SEMIS_KIT_THR, SEMIS_KIT_CAP)
	draw_texture(t if t != null else kit, Vector2(at))


## The GRID form: sixteen four-column bands, home kit | home club | away club | away kit.
## A band whose tie is the MANAGER'S takes the dark plate and prints his club in bright
## yellow; the tapped band goes white. Both are the frames' own states.
func _draw_grid() -> void:
	var ties := _masked_ties()
	for k in GRID_ROWS_N:
		if k >= ties.size():
			break
		var tie: Dictionary = ties[k]
		var home := str(tie.get("home", ""))
		if home == "":
			continue
		var away := str(tie.get("away", ""))
		var y := GRID_Y0 + GRID_PITCH * k
		var band := k & 1
		var hid := int(tie.get("home_id", -1))
		var aid := int(tie.get("away_id", -1))
		var mine: bool = _own_club_id >= 0 and (hid == _own_club_id or aid == _own_club_id)
		var ink: Color = C_GRID_INK[band]
		if mine:
			_fill_row(y, C_GRID_OWN_BG, C_GRID_OWN_KIT_BG)
			ink = C_GRID_OWN_INK
		elif k == _sel:
			_fill_row(y, C_GRID_SEL_BG, C_GRID_SEL_BG)
			ink = C_GRID_SEL_INK
		var pen := y + GRID_PEN_TOP
		_txt_field(_page10, _g10, GRID_HOME[0] + GRID_HOME[1], pen, home,
			C_GRID_OWN_INK_MINE if (mine and hid == _own_club_id) else ink)
		if away != "":
			_txt_field(_page10, _g10, GRID_AWAY[0] + GRID_AWAY[1], pen, away,
				C_GRID_OWN_INK_MINE if (mine and aid == _own_club_id) else ink)
		_kit_cell(GRID_KIT_L, y, hid)
		if away != "":
			_kit_cell(GRID_KIT_R, y, aid)


## Repaint one grid band, cell by cell: the two name cells take `bg` and the two kit
## cells `kit_bg`. The black column separators between them are the chrome's and must
## survive, so nothing paints across x477-478 or the two cell borders.
func _fill_row(y: int, bg: Color, kit_bg: Color) -> void:
	draw_rect(Rect2(GRID_KIT_L[0], y, GRID_KIT_L[1] - GRID_KIT_L[0], GRID_ROW_H), kit_bg, true)
	draw_rect(Rect2(GRID_HOME[0], y, GRID_HOME[1] - GRID_HOME[0] + 1, GRID_ROW_H), bg, true)
	draw_rect(Rect2(GRID_AWAY[0], y, GRID_AWAY[1] - GRID_AWAY[0] + 1, GRID_ROW_H), bg, true)
	draw_rect(Rect2(GRID_KIT_R[0], y, GRID_KIT_R[1] - GRID_KIT_R[0], GRID_ROW_H), kit_bg, true)


func _kit_cell(cell: Array, y: int, club_id: int) -> void:
	var kit := PMChrome.kit(club_id)
	if kit == null:
		return
	draw_texture_rect_region(kit,
		Rect2(int(cell[0]) + 2, y + 1, int(cell[1]) - int(cell[0]) - 4, GRID_ROW_H - 2),
		Rect2(1, 3, 45, 57))


## The bottom-left tie-detail card. Empty until a row is tapped, which is the original's
## own resting state (every captured frame with no tie selected shows it blank).
func _draw_card() -> void:
	if _card.is_empty():
		return
	var sides: Array = [_card.get("home", {}), _card.get("away", {})]
	for i in sides.size():
		var side: Dictionary = sides[i]
		if side.is_empty():
			continue
		_txt_field(_page10, _g10, CARD_CLUB_SUM, int(CARD_CLUB_TOPS[i]),
			str(side.get("club", "")), C_CARD_CLUB)
		var mgr := str(side.get("manager", ""))
		if mgr != "":
			_txt_field(_page12c, _g12c, CARD_MGR_SUM, int(CARD_MGR_TOPS[i]), mgr,
				C_CARD_MGR_OWN if (_own_manager != "" and mgr == _own_manager) else C_CARD_MGR)
		_txt_field(_page10, _g10, CARD_STADIUM_SUM, int(CARD_STADIUM_TOPS[i]),
			str(side.get("stadium", "")), C_CARD_STADIUM)
		var kit := PMChrome.kit(int(side.get("club_id", -1)))
		if kit != null:
			draw_texture_rect_region(kit, CARD_KIT_L if i == 0 else CARD_KIT_R,
				Rect2(1, 3, 45, 57))


## Black window, competition strip, drum backdrop, drum frame (opaque), and — during a
## reveal — the hand with the slip over it. Exactly the original's layer order: p0127
## proves MANO7 blits over the drum at (106,144) with the club's name on the slip.
func _draw_picture() -> void:
	draw_rect(PICTURE, Color(0, 0, 0), true)
	if _strip != null:
		draw_texture(_strip, STRIP_AT)
	if _fondo != null:
		draw_texture(_fondo, FONDO_AT)
	if not _bombo.is_empty():
		var idx := 0                          # parked = BOMBO00 (p0131/p0133/p0747)
		if _pinned >= 0:
			idx = _pinned % _bombo.size()
		elif _reveal_on:
			idx = int(_spin * 12.0) % _bombo.size()
		draw_texture(_bombo[idx], BOMBO_AT)
	if _reveal_on and _reveal_t >= 0.0 and _reveal_step < _reveal_names.size() \
			and not _mano.is_empty():
		var mi := 7
		if _reveal_t < REVEAL_RISE:
			mi = clampi(int(_reveal_t / REVEAL_RISE * 8.0), 0, 7)
		draw_texture(_mano[mini(mi, _mano.size() - 1)], MANO_AT)
		if mi == 7:
			var tex := _slip_name_tex(str(_reveal_names[_reveal_step]))
			if tex != null:
				draw_texture(tex, MANO_AT)


## The name on the hand's slip, pre-rendered per club: calend12 centred on field-sum
## 380, inked THROUGH the slip's own tones — (192)->114, (240)->144, (220)-> the
## 144/128 checkerboard by (x+y) parity. Reproduces p0127's 265 name pixels exactly;
## pixels that would fall off the slip's paper are simply not inked.
func _slip_name_tex(club: String) -> Texture2D:
	if club == _slip_name and _slip_tex != null:
		return _slip_tex
	if _mano7_img == null or _page12c == null:
		return null
	if _font12c_img == null:
		_font12c_img = _page12c.get_image()
	var img := Image.create(_mano7_img.get_width(), _mano7_img.get_height(),
		false, Image.FORMAT_RGBA8)
	@warning_ignore("integer_division")
	var pen := (SLIP_SUM - _advance(_g12c, club)) / 2 - int(MANO_AT.x)
	var top := SLIP_PEN_TOP - int(MANO_AT.y)
	for i in club.length():
		var g: Dictionary = _g12c.get(club.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		for py in r.size.y:
			for px in r.size.x:
				if _font12c_img.get_pixel(r.position.x + px, r.position.y + py).a < 0.5:
					continue
				var sx := pen + off.x + px
				var sy := top + off.y + py
				if sx < 0 or sy < 0 or sx >= img.get_width() or sy >= img.get_height():
					continue
				var bg := _mano7_img.get_pixel(sx, sy)
				if bg.a < 0.5 or bg.r8 != bg.g8 or bg.g8 != bg.b8:
					continue                     # off the slip's paper: no ink
				var v := -1
				if bg.r8 == 220:
					v = SLIP_DITHER_EVEN if ((sx + sy) & 1) == 0 else SLIP_DITHER_ODD
				elif SLIP_INK.has(bg.r8):
					v = int(SLIP_INK[bg.r8])
				if v >= 0:
					img.set_pixel(sx, sy, Color8(v, v, v))
		pen += int(g["adv"])
	_slip_name = club
	_slip_tex = ImageTexture.create_from_image(img)
	return _slip_tex


## The MATCHES list. Home club right-aligned so its pen ENDS at 465, the fixed "-" at
## 466, away club's pen starting at 475 — all three measured identical on eight witnessed
## rows across the two careers. A tie whose away club has not been drawn yet shows the
## home club and the dash alone, which is what frames 74 and 75 both catch mid-draw.
func _draw_rows() -> void:
	var ties := _masked_ties()
	for k in LIST_ROWS:
		var i := _first + k
		if i >= ties.size():
			break
		var tie: Dictionary = ties[i]
		var home := str(tie.get("home", ""))
		var away := str(tie.get("away", ""))
		if home == "":
			continue
		var y := LIST_Y0 + LIST_PITCH * k + LIST_TEXT_TOP
		_txt(_page10, _g10, HOME_RIGHT - _advance(_g10, home), y, home, C_ROW_TXT)
		_txt(_page10, _g10, DASH_X, y, "-", C_ROW_TXT)
		if away != "":
			_txt(_page10, _g10, AWAY_LEFT, y, away, C_ROW_TXT)


## The proportional thumb, rebuilt from the frame's own rows: a white cap, a 2-row
## alternating body keyed on absolute y, a dark edge row and a 2px black foot.
func _draw_scrollbar() -> void:
	if _total <= LIST_ROWS:
		var h := TROUGH_H
		_thumb(TROUGH_Y, h)
		return
	var th := int(round(float(TROUGH_H) * float(LIST_ROWS) / float(_total)))
	var ty := TROUGH_Y + int(round(float(TROUGH_H) * float(_first) / float(_total)))
	_thumb(ty, maxi(th, 8))


func _thumb(y0: int, h: int) -> void:
	var x := SCROLL_X
	draw_rect(Rect2(x, y0, 1, h), Color(0, 0, 0), true)               # left black edge
	draw_rect(Rect2(x + 16, y0, 2, h), Color(0, 0, 0), true)          # right black edge
	draw_rect(Rect2(x + 1, y0, 15, 1), C_THUMB_CAP, true)             # top cap
	draw_rect(Rect2(x + 1, y0 + 1, 1, h - 3), C_THUMB_CAP, true)      # cap column
	draw_rect(Rect2(x + 2, y0 + 1, 13, 1), C_TROUGH, true)
	draw_rect(Rect2(x + 15, y0 + 1, 1, 1), C_THUMB_EDGE, true)
	for y in range(y0 + 2, y0 + h - 3):
		var band: Array = C_THUMB_A if (y & 1) == 0 else C_THUMB_B
		draw_rect(Rect2(x + 2, y, 1, 1), C_TROUGH, true)
		for i in band.size():
			draw_rect(Rect2(x + 3 + i, y, 1, 1), band[i], true)
		draw_rect(Rect2(x + 15, y, 1, 1), C_THUMB_EDGE, true)
	draw_rect(Rect2(x + 2, y0 + h - 3, 14, 1), C_THUMB_EDGE, true)
	draw_rect(Rect2(x + 1, y0 + h - 2, 15, 2), Color(0, 0, 0), true)
