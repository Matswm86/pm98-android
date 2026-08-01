extends Control
class_name KnockoutScreen
## RESULTS -> any cup at a KNOCKOUT phase, rebuilt frame-true.
##
## The original does not have "a knockout screen": it switches presentation with the size
## of the round and the column set with the competition (`docs/re/knockout_views_re.md`,
## five layouts witnessed 2026-07-26). This scene draws two of them:
##
##   * the LIST form -- the compact 15 px row table every round of nine ties or more
##     lands in, in both column sets:
##         European   1ST LEG   2ND LEG   AGGR.
##         domestic   RES.      REPLAY
##   * the BRACKET form -- any 4-tie round: four 80 px-pitch panels, a kit and a country
##     flag each side, the same column pair as plates over value boxes.
##   * the SEMIFINAL CARDS -- any 2-tie round: two cards, SEMIFINAL 1 (blue) and
##     SEMIFINAL 2 (green), each a 1ST LEG block (the home club's own ground, then the
##     two clubs with a score box) over a 2ND LEG block (sides swapped) over a FINALIST
##     plate. Witnessed for EURO. LEAGUE (two careers) and the Coca-Cola Cup; the other
##     competitions' cards bands are unwitnessed, so those fall back to the SORTEO.
##   * the FINAL -- a 1-tie round: the competition trophy, a RESULTS card (kits + flags,
##     STADIUM + the neutral ground, the two finalists with score cells) and the
##     laurelled WINNER band. The card + band chrome is byte-identical to the witnessed
##     CHARITY SHIELD screen's outside the content (0 px, 2026-07-27), so the redraw
##     grammar is CompResultScreen's. Witnessed for EURO. LEAGUE only.
##
## Everything static is the original's own pixels (`art/screens/knockout/`, baked by
## `tools/re/build_knockout_chrome_from_frames.py` from the witnessed frames); everything
## a career fills is redrawn here at the measured anchors.
##
## Geometry + inks: docs/re/knockout_views_re.md "Geometry banked 2026-07-26" for the
## list, "The bracket, re-measured 2026-07-26" for the bracket.

signal back_pressed
signal phase_changed(delta: int)
signal competition_selected(key: String)

const W := 640
const H := 480

# ---- the competition rail --------------------------------------------------------
const COMPS := ["facup", "cocacola", "charity", "euro", "cwc", "uefa", "supercup",
	"intercont"]
const RAIL_XY := Vector2(500, 110)
const CHIP_X := 506
const CHIP_W := 116
const CHIP_H := 29
const CHIP_TOP := {"facup": 118, "cocacola": 145, "charity": 172, "euro": 209,
	"cwc": 236, "uefa": 263, "supercup": 290, "intercont": 317}

# ---- the compact list panel ------------------------------------------------------
const PANEL_X0 := 6
const PANEL_X1 := 477
const HDR_XY := Vector2(6, 125)          # the baked panel top (border + title band)
const BODY_TOP := 154
const MAX_ROWS := 16                     # the panel's full height, beyond which it scrolls
## Below this the original switches to a different layout entirely -- the kit list at 5-8
## ties, the bracket at 4, two cards at 2, the trophy view at 1. Those are measured in
## docs/re/knockout_views_re.md but not built, so a caller checks this before raising the
## list.
const MIN_LIST_TIES := 9
const FULL_BODY_H := 255                 # witnessed at 16 rows (bottom border y408..410)
const SHORT_ROW_H := 15                  # witnessed at 15 rows (bottom border y378..380)
const BOTTOM_BORDER := 3

# Column cells, inclusive x spans. The gaps between them are the panel's own black rules.
const COLS_EURO := [[8, 158], [161, 309], [312, 365], [367, 420], [422, 475]]
const COLS_DOM := [[8, 185], [188, 363], [365, 418], [420, 473]]

# Row grounds, light row then dark row: the two name cells, the score cells, and the LAST
# score cell, which is a shade darker in both column sets.
const BG_NAME := [Color8(120, 140, 160), Color8(100, 120, 140)]
const BG_SCORE := [Color8(160, 160, 200), Color8(120, 120, 160)]
const BG_LAST := [Color8(140, 140, 180), Color8(100, 100, 140)]
# The manager's OWN tie replaces the alternating grounds outright, and takes a light ink
# instead of the dark one (witnessed on the F.A. Cup R3 draw, Peterborough v Bolton W).
const BG_MINE := [Color8(60, 80, 100), Color8(59, 85, 130), Color8(30, 52, 98)]
const C_MINE := Color8(140, 160, 180)
const C_BLACK := Color8(0, 0, 0)

# Text anchors, as offsets into the cell they live in (identical in both column sets).
const NAME_RIGHT_DX := -4                # home name: pen END at cell_x1 - 5
const NAME_LEFT_DX := 4                  # away name: pen at cell_x0 + 4
const NAME_TOP_DY := 2
const SCORE_A_END_DX := 21               # first number: pen END at cell_x0 + 20
const SCORE_DASH_DX := 24
const SCORE_B_DX := 31
const SCORE_TOP_DY := 2

const C_OUT := Color8(42, 63, 85)        # the eliminated club and its goals
const C_THROUGH := Color8(255, 223, 0)   # the club going through, and its goals

# ---- the KIT LIST (layout 2), measured 2026-07-28 --------------------------------
## The form the original switches to for a round of 5-8 ties: 22 px rows, a 17x20 ridi kit
## blitted each side of the two names, and the SAME column pair as the compact list. Three
## witnesses -- 09_comp_cwc (European, drawn), 01_uefa_1_8finals_leg1_played (European,
## leg 1 in) and 13_cocacola_r4_KITLIST_PLAYED (DOMESTIC, played, winners inked) -- two
## competitions, two careers, both column sets.
##
## Its panel is x6..493, three columns WIDER than the compact list's, because a round this
## small never scrolls: the scrollbar column is simply part of the panel here.
##
## Every witnessed round of this layout has EIGHT ties, and eight is also the only size the
## port's own cup structure can produce (every competition halves 16 -> 8 -> 4 -> 2 -> 1),
## so the 5-7 tie panel heights are neither witnessed nor reachable. The rows are drawn
## top-aligned from the compact list's own witnessed BODY_TOP and the panel tail follows
## the last row, which is exact at 8.
##
## The row grounds do NOT alternate here (all 24 witnessed rows carry the same five), and
## no witness shows the MANAGER's own tie in this layout, so it draws like any other --
## the port adds no highlight it has not seen (docs/re/knockout_views_re.md).
const KITLIST_MIN_TIES := 5
const KITLIST_MAX_TIES := 8
const KL_PANEL_X0 := 6
const KL_HDR_XY := Vector2(6, 125)
const KL_BODY_TOP := 154
const KL_ROW_H := 22
const KL_PITCH := 30
## Cells, inclusive x spans, in draw order: kit L, home, away, kit R, then the score cells.
const KL_COLS_EURO := [[15, 42], [44, 164], [167, 287], [289, 316], [319, 372],
	[374, 427], [429, 482]]
const KL_COLS_DOM := [[15, 42], [44, 192], [195, 342], [344, 371], [374, 427], [429, 482]]
## The 17x20 ridi kit's origin inside its 28x22 well -- the unique best offset on all 48
## witnessed cells. The well's outline pass is baked exactly like the bracket's.
const KL_SPR_DXY := Vector2(5, 1)
## Pen tops, solved off the frames: every name and every score digit sits at row_top + 6
## (the compact list's +2, moved down by the taller row). The cell-relative x anchors are
## the compact list's own, unchanged -- NAME_RIGHT_DX / NAME_LEFT_DX / SCORE_*_DX all
## reproduce exactly here.
const KL_TEXT_TOP_DY := 6

# ---- the scrollbar ---------------------------------------------------------------
const SCROLL_XY := Vector2(478, 125)
const SCROLL_TROUGH := [172, 394]        # its interior, in screen rows

# ---- the BRACKET layout (docs/re/knockout_views_re.md, re-measured 2026-07-26) -----
## Any 4-tie round. Four panels x20..477 at these tops (pitch 80); one baked 458x72
## strip per column set, repeated four times -- verify_bracket_split.py proves 20
## witnessed panels byte-identical outside the content the code below redraws.
const BRACKET_TIES := 4
const BRACKET_TOPS := [113, 193, 273, 353]
const BRACKET_PANEL_X := 20
## The 48x64 MINIESC kit sprite's origin each side, solved by matching the exact-decoded
## sprites against the euro QTR frame (best offset unique, second-best 3-5x worse). The
## original draws an outline/bevel ring OUTSIDE the silhouette in a second, un-reversed
## pass -- the sprite alone reproduces ~1470/1660 opaque px -- so the parity gate declares
## the two kit columns per panel, exactly as it declares the barra kit.
const BRACKET_KIT_L := Vector2(26, 8)    # + (0, T)
const BRACKET_KIT_R := Vector2(423, 8)
## The outline-pass overlays (baked 2026-07-27): the pass's ring turned out to be
## POSITION-CONSTANT across every witnessed cell (all MINIESC kits share one
## silhouette), so its result is baked verbatim per column -- kitwell_under_* draws
## under the sprite (the drop shadow + outer bevel), the icons additionally carry an
## OVER layer (positions the pass provably overrides on the sprite itself). See the
## baker's OVERLAYS block; the on-sprite bevel of the 48x64 kits is club-dependent
## and stays the declared bucket.
const BRACKET_WELL_L := Vector2(22, 2)   # + (0, T)
const BRACKET_WELL_R := Vector2(416, 2)
const BRACKET_FLAG_L := Vector2(83, 7)   # 30x20 dbcard flag, 0 px witnessed
const BRACKET_FLAG_R := Vector2(385, 7)
## Names are CENTRED, not edge-anchored: pen x = floor(cx - advance/2) with cx 178.5
## (home) / 319.5 (away) -- solved off all 15 witnessed names of the euro and F.A. Cup
## QTR frames (every one lands exactly). proman10, pen top T+12.
const BRACKET_NAME_CX2 := [357, 639]     # 2*cx, so the floor is integer arithmetic
const BRACKET_NAME_TOP_DY := 12
const BRACKET_NAME_INK := Color8(60, 80, 100)
## The WINNER's name plate, CLOSED 2026-07-28 against the first frame that ever showed a
## decided bracket tie (screenshots/wine-captures-2026-07-28-knockout-decided/
## 01_euro_qtr_finals_decided.png -> tools/re/refs/knockout-2026-07-26/
## 09_euroleague_qtrfinals_DECIDED_1998-04-11.png). The 07-26 build had only the LIST's
## rule to go on and inked the winner's name yellow on the plain plate; the original also
## REPAINTS his whole plate blue and puts a chevron at each end of it, pointing inwards.
## Measured on both witnessed sides of the frame (Borussia D. away, Manchester Utd. home):
##   plates      x114..247 (home) and x250..383 (away), rows T+7..T+26
##   fill        (42,95,170) over the strip's own (180,200,220)
##   chevrons    (166,202,240), 5 px wide, inset 1 px from each plate edge,
##               9 rows tall, apex row T+16, width = 5 - |dy| (a solid triangle)
const BRACKET_PLATE_X := [[114, 247], [250, 383]]
const BRACKET_PLATE_DY := 7
const BRACKET_PLATE_H := 20
const BRACKET_PLATE_WIN := Color8(42, 95, 170)
const BRACKET_CHEVRON := Color8(166, 202, 240)
const BRACKET_CHEVRON_W := 5
const BRACKET_CHEVRON_APEX_DY := 16
## A score centres on its value box: first number's pen END at cx-5, the dash's pen at
## cx-2, second number's pen at cx+5, pen top T+50 -- solved off the four witnessed
## leg-1 cells (box x83..175, cx 129: ink ends 122, dash 127..129, B starts 134).
## The dash is drawn at the .fnt's SECOND alpha level in every witnessed cell -- its six
## pixels are the 80 % blend of the ink over the box ground, not the full ink.
const BRACKET_SCORE_TOP_DY := 50
## The plain (not-through) score ink is PER BOX, not one colour: the two leg boxes print
## (180,200,220) on their (80,100,120) ground, and the navy AGGR box prints (180,180,220)
## on (20,0,90). Only witnessable once a frame carried a filled aggregate -- the
## 2026-07-28 decided-bracket witness -- so it was one constant until then.
const BRACKET_SCORE_INK := Color8(180, 200, 220)
const BRACKET_SCORE_INK_EURO := [Color8(180, 200, 220), Color8(180, 200, 220),
	Color8(180, 180, 220)]
const BRACKET_SCORE_INK_DOM := [Color8(180, 200, 220), Color8(180, 200, 220)]
## ...and the dash's second-alpha blend is per box too. The navy AGGR box carries NO
## blended pixel at all in the decided witness -- its dash is the full ink on all four
## ties, while both leg boxes keep the witnessed 80 % blend over their own ground.
const BRACKET_DASH_BLEND_EURO := [0.2, 0.2, 0.0]
const BRACKET_DASH_BLEND_DOM := [0.2, 0.2]
## Value-box centres per column set, in slot order (docs/re/knockout_views_re.md:
## euro boxes x83..175 / x193..283 / x310..414, domestic x135..227 / x271..361).
const BRACKET_BOX_CX_EURO := [129, 238, 362]
const BRACKET_BOX_CX_DOM := [181, 316]
## Each slot's box ground, for the dash's 80 % blend (euro slot 3 is the navy AGGR box,
## domestic slot 2 the darker REPLAY box).
const BRACKET_BOX_BG_EURO := [Color8(80, 100, 120), Color8(80, 100, 120), Color8(20, 0, 90)]
const BRACKET_BOX_BG_DOM := [Color8(80, 100, 120), Color8(60, 80, 100)]

# ---- the SEMIFINAL cards (docs/re/knockout_views_re.md, measured 2026-07-27) -------
## Two cards, one tie each. Chrome = the baked cards_body.png strip (one strip serves
## both column sets: the euro and cocacola cards frames are byte-identical below the band
## outside the content). Every pen below is solved off the three witnessed frames.
const CARDS_TIES := 2
const FINAL_TIES := 1
const CARDS_BODY_XY := Vector2(0, 120)
const CARDS_DX := [0, 258]               # every SF2 dynamic element = SF1 + 258
const CARDS_VENUE_PEN_X := 33            # leftmost venue ink, identical on all 3 frames
const CARDS_NAME_PEN_X := 34             # leftmost club ink, identical on all 3 frames
const CARDS_ICON_X := 13                 # the 17x20 ridi kit icon (matched at bar top)
const CARDS_LEG_TOPS := [190, 282]       # the two venue blocks' tops (black grounds)
const CARDS_BARS := [[209, 231], [301, 323]]   # club-bar tops per leg block
const CARDS_VENUE_PEN_DY := 4            # venue pen top = block top + 4 (ink rows +2)
const CARDS_TEXT_PEN_DY := 5             # names + digits: pen top = bar top + 5
## Score digits centre on their box: box x191..226 (SF1) / x449..484 (SF2), so the
## _txt_mid field sums are 418 / 934 -- the witnessed "1" lands at x464..468 and the
## "2" at x462..469 exactly.
const CARDS_BOX_FIELD := [418, 934]
const CARDS_NAME_INK := [Color8(42, 95, 170), Color8(80, 110, 5)]
const CARDS_VENUE_INK := [Color8(117, 147, 187), Color8(61, 191, 82)]
const CARDS_SCORE_INK := Color8(255, 255, 255)
## The FINALIST plates' white boxes (interior x20..216 / x281..477, y376..411). What a
## DECIDED semifinal fills them with was unwitnessed until 2026-07-28; both frames of that
## drive have them filled, and the grammar is the kit + the name, not a centred string.
const CARDS_FINALIST := [[20, 216], [281, 477]]
const CARDS_FINALIST_KIT := Vector2(2, 377)   # + plate_x0 on x; y is absolute
const CARDS_FINALIST_PEN_DX := 43
const CARDS_FINALIST_PEN_Y := 380

# ---- the FINAL (docs/re/knockout_views_re.md, measured 2026-07-27) -----------------
## One tie. Chrome = final_body_<comp>.png (euro is the one witnessed final). The card +
## WINNER band chrome is byte-identical to the CHARITY SHIELD frame's outside the content
## rects, so every anchor below is CompResultScreen's witnessed grammar verbatim.
const FINAL_KIT_L := Rect2(146, 158, 48, 60)
const FINAL_KIT_R := Rect2(306, 158, 48, 60)
const FINAL_FLAG_L := Vector2(199, 163)  # 30x20 dbcard flag boxes
const FINAL_FLAG_R := Vector2(270, 163)
const FINAL_STADIUM_X := 143.0           # centred in a 200-wide box -> centre 243
const FINAL_STADIUM_Y := 240
const FINAL_ROW_Y := [269, 300]
## The finalists' names are NATIVE proman12 -- the witness 'R' is 11x9 with advance 12,
## proman12's own metrics exactly -- at pen (155, bar interior top + 4): ink row 1 of the
## glyph cell lands on the witnessed y272/y303.
const FINAL_NAME_PEN_X := 155
const FINAL_NAME_PEN_Y := [271, 302]
const FINAL_SCORE_CELL := [306.0, 39.0]
const FINAL_WINNER_XY := [65.0, 382.0]
const FINAL_LAUREL := Rect2(408, 342, 32, 44)
const FINAL_C_NAME := Color8(80, 100, 120)
const FINAL_C_STADIUM := Color8(17, 90, 34)
const FINAL_C_WINNER := Color8(42, 63, 170)

# ---- the DOMESTIC final (the Coca-Cola Cup), measured 2026-07-28 --------------------
## A different card from the euro one: MATCH RESULT over STADIUM, a second olive REPLAY
## RESULT header with an empty panel under it, and NO kit/flag row -- the two club bars
## carry a 17x20 `ridi` icon each, exactly as the CARDS layout's rows do. The WINNER band
## and the laurel below are the euro final's, unchanged (the two frames agree pixel for
## pixel outside the card and the trophy). Every anchor solved on
## `tools/re/refs/knockout-2026-07-28/14`.
const DOM_FINAL_STADIUM_X := 151.0        # centred in a 200-wide box -> centre 251
const DOM_FINAL_STADIUM_Y := 161
const DOM_FINAL_BAR_TOP := [178, 200]     # bar interiors y178..197 / y200..219
const DOM_FINAL_ICON_X := 145             # the 17x20 ridi kit, at the bar's own top
const DOM_FINAL_NAME_PEN_X := 167         # leftmost club ink on both bars
const DOM_FINAL_NAME_PEN_DY := 4          # ink row 1 lands on y183 / y205
const DOM_FINAL_SCORE_FIELD := 677            # box x321..356, so 2*cx for integer maths

# ---- the phase paginator ---------------------------------------------------------
const C_LABEL := Color8(100, 100, 140)
const LABEL_TOP_DY := 5                  # the label's pen top inside its plate
const PAGER_BTN := Vector2(23, 21)

const R_RETURN := Rect2(504, 433, 116, 29)
const C_PRESS := Color(1, 1, 1, 0.2)

# the shared barra grammar, as ResultsScreen and EuroGroupScreen draw it
const HDR_PATCH_XY := {"hdr_names": Vector2(2, 10), "hdr_kit": Vector2(106, 6),
	"hdr_cal": Vector2(448, 13), "hdr_status": Vector2(536, 10)}
const HDR_STATUS_W := 77

var _desktop: Texture2D
var _bands: Dictionary = {}              # "<comp>_<fam>" -> {tex, meta}
var _band_meta: Dictionary = {}
var _chips: Dictionary = {}
var _hdr: Dictionary = {}                # "euro"/"dom" -> the panel top strip
var _bracket: Dictionary = {}            # "euro"/"dom" -> the baked 458x72 panel strip
var _cards_body: Texture2D               # the two SEMIFINAL cards, content blanked
var _cards_body_single: Texture2D        # the SINGLE-LEG (F.A. Cup) shape of the same
var _final_body: Texture2D               # per competition, loaded in setup()
var _well: Dictionary = {}               # "under_L"/"over_L"/... the kit-well overlays
var _kl: Dictionary = {}                 # the KIT LIST strips + its own well overlays
var _icon_ol: Dictionary = {}            # "under_sf1"/"over_sf1"/... the icon overlays
var _flags: Dictionary = {}              # countryCode -> 30x20 dbcard flag
var _ridi: Dictionary = {}               # club id -> 17x20 ridi kit icon
var _pager: Dictionary = {}
var _scroll_col: Texture2D
var _scroll_thumb: Texture2D
var _patches: Dictionary = {}
var _page_cal: Texture2D
var _page_p10: Texture2D
var _page_p12: Texture2D
var _g_cal: Dictionary = {}
var _g_p10: Dictionary = {}
var _g_p12: Dictionary = {}
var _f8: Font
var _fcal: Font
var _f10g: Font
var _f12g: Font
var _f14g: Font

var _header: Dictionary = {}
var _comp := "euro"
var _label := ""
var _layout := "list"                    # "list" | "bracket"
var _euro_cols := true
var _ties: Array = []                    # [{home, away, winner, cells}]
var _offset := 0
var _has_prev := false
var _has_next := false
var _press := ""


func _ready() -> void:
	_desktop = _tex("res://art/screens/knockout/desktop.png")
	for c in COMPS:
		_chips[c] = _tex("res://art/screens/knockout/rail_%s.png" % c)
	for key in ["euro", "dom"]:
		_hdr[key] = _tex("res://art/screens/knockout/list_hdr_%s.png" % key)
		_bracket[key] = _tex("res://art/screens/knockout/bracket_panel_%s.png" % key)
		_kl["hdr_%s" % key] = _tex("res://art/screens/knockout/kitlist_hdr_%s.png" % key)
		_kl["row_%s" % key] = _tex("res://art/screens/knockout/kitlist_row_%s.png" % key)
		_kl["foot_%s" % key] = _tex("res://art/screens/knockout/kitlist_foot_%s.png" % key)
	for k in ["under_p0", "over_p0", "under_p1", "over_p1"]:
		_kl[k] = _tex("res://art/screens/knockout/kitwell_kl_%s.png" % k)
	_cards_body = _tex("res://art/screens/knockout/cards_body.png")
	_cards_body_single = _tex("res://art/screens/knockout/cards_body_single.png")
	for k in ["under_L", "over_L", "under_R", "over_R"]:
		_well[k] = _tex("res://art/screens/knockout/kitwell_%s.png" % k)
	for k in ["under_sf1", "over_sf1", "under_sf2", "over_sf2"]:
		_icon_ol[k] = _tex("res://art/screens/knockout/icon_%s.png" % k)
	for key in ["left_on", "right_on", "left_off_p0", "left_off_p1", "right_off_p0",
			"right_off_p1"]:
		_pager[key] = _tex("res://art/screens/knockout/pager_%s.png" % key)
	_scroll_col = _tex("res://art/screens/knockout/scroll_col.png")
	_scroll_thumb = _tex("res://art/screens/knockout/scroll_thumb_tile.png")
	_band_meta = _load_json("res://art/screens/knockout/bands.json")
	for key in _band_meta:
		_bands[key] = _tex("res://art/screens/knockout/band_%s.png" % key)
	for k in HDR_PATCH_XY:
		_patches[k] = _tex("res://art/screens/results/%s.png" % k)
	_page_cal = PMFont.page_texture("calend12")
	_page_p10 = PMFont.page_texture("proman10")
	_page_p12 = PMFont.page_texture("proman12")
	_g_cal = PMFont.chars("calend12")
	_g_p10 = PMFont.chars("proman10")
	_g_p12 = PMFont.chars("proman12")
	_f8 = PMChrome.font("8")
	_fcal = PMChrome.font("calend12")
	_f10g = PMChrome.font("10")
	_f12g = PMChrome.font("12")
	_f14g = PMChrome.font("14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


static func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func _load_json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}


## `ties` is the phase's ties in draw order, each
##     {home: String, away: String, winner: int (0 home / 1 away / -1 undecided),
##      cells: Array of [String, String] -- one per column, "" for an empty cell}
## The BRACKET layout additionally reads per tie, when present:
##     home_id / away_id      club ids, for the 48x64 MINIESC kit blit
##     home_flag / away_flag  dbcard countryCodes, for the 30x20 flags
## The CARDS layout reads home_id/away_id (ridi icons), home_ground/away_ground (the
## clubs' own venues) and two_legged; the FINAL reads ids, flags and `venue` (the
## neutral ground).
## `euro_cols` picks 1ST LEG / 2ND LEG / AGGR. over RES. / REPLAY.
## `layout` is "list" (9+ ties), "bracket" (4), "cards" (2) or "final" (1) -- the
## original switches presentation with the size of the round, so the caller picks per
## phase (cards/final only where that competition's chrome is witnessed, see
## cards_available / final_available).
func setup(header: Dictionary, comp: String, label: String, euro_cols: bool,
		ties: Array, has_prev: bool, has_next: bool, offset := 0,
		layout := "list") -> void:
	_header = header
	_comp = comp if comp in COMPS else "euro"
	_label = label
	_layout = layout if layout in ["list", "kitlist", "bracket", "cards", "final"] else "list"
	if _layout == "final":
		_final_body = _tex("res://art/screens/knockout/final_body_%s.png" % _comp)
	_euro_cols = euro_cols
	_ties = ties
	_has_prev = has_prev
	_has_next = has_next
	_offset = clampi(offset, 0, maxi(0, ties.size() - MAX_ROWS))
	queue_redraw()


func cols() -> Array:
	return COLS_EURO if _euro_cols else COLS_DOM


func visible_rows() -> int:
	return mini(_ties.size(), MAX_ROWS)


## The panel's body height. Witnessed at 15 rows (225) and at 16 (255); between them the
## rows are 15 px and at the full height they are the 255/16 the original's own separator
## positions imply. A count above 16 scrolls at the full height.
func body_h() -> int:
	var n := visible_rows()
	return FULL_BODY_H if n >= MAX_ROWS else n * SHORT_ROW_H


## The y of the black rule UNDER row `i` (there is none under the last row).
func _sep_y(i: int) -> int:
	var n := visible_rows()
	@warning_ignore("integer_division")
	return BODY_TOP + ((i + 1) * body_h()) / n - 1


func _row_span(i: int) -> Vector2i:
	var n := visible_rows()
	var top := BODY_TOP if i == 0 else _sep_y(i - 1) + 1
	var bot := (_sep_y(i) - 1) if i < n - 1 else BODY_TOP + body_h() - 2
	return Vector2i(top, bot)


# ---- layout ----------------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / float(W), size.y / float(H))


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	if s <= 0.0:
		return Vector2(-1, -1)
	return (p - _origin(s)) / s


## The FINAL shares the cards family's band: the witnessed euro final band differs from
## the euro semis band in the 292 label pixels only (2026-07-27).
func _band_key() -> String:
	var fam := "cards" if _layout in ["cards", "final"] else _layout
	# The KIT LIST shares the LIST family's band: the U.E.F.A. and Cup Winner's kit-list
	# witnesses carry the same strip, plate and arrow positions as their list frames.
	if fam == "kitlist":
		fam = "list"
	return "%s_%s" % [_comp, fam]


## Whether this competition's SEMIFINAL-cards chrome is witnessed (euro + cocacola
## today). A 2-tie phase of any other competition falls back to the SORTEO card --
## an honest gap recorded in docs/re/knockout_views_re.md.
static func cards_available(comp: String) -> bool:
	return ResourceLoader.exists("res://art/screens/knockout/band_%s_cards.png" % comp)


## Whether this competition's FINAL body (its trophy + card) is witnessed. Two today: the
## euro one (2026-07-27) and the DOMESTIC one the Coca-Cola frame gave (2026-07-28), which
## is a different card entirely -- MATCH RESULT over STADIUM plus a REPLAY RESULT panel.
static func final_available(comp: String) -> bool:
	return cards_available(comp) and ResourceLoader.exists(
		"res://art/screens/knockout/final_body_%s.png" % comp)


func _pager_rects() -> Array:
	var m: Dictionary = _band_meta.get(_band_key(), {})
	if m.is_empty():
		return []
	var l: Array = m.get("left", [0, 0])
	var r: Array = m.get("right", [0, 0])
	return [Rect2(int(l[0]), int(l[1]), PAGER_BTN.x, PAGER_BTN.y),
		Rect2(int(r[0]), int(r[1]), PAGER_BTN.x, PAGER_BTN.y)]


func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d):
		return "return"
	var pr := _pager_rects()
	if pr.size() == 2:
		if (pr[0] as Rect2).has_point(d) and _has_prev:
			return "prev"
		if (pr[1] as Rect2).has_point(d) and _has_next:
			return "next"
	for c in COMPS:
		if Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H).has_point(d):
			return "comp:%s" % c
	return ""


func _on_input(e: InputEvent) -> void:
	if PMChrome.is_emulated_pointer_dup(e):
		return
	var pressed := (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed)
	var released := (e is InputEventMouseButton and not (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and not (e as InputEventScreenTouch).pressed)
	if not (pressed or released):
		return
	var pos: Vector2 = (e as InputEventMouse).position if e is InputEventMouse \
		else (e as InputEventScreenTouch).position
	var t := _target_at(_to_design(pos))
	if pressed:
		_press = t
		queue_redraw()
		return
	_press = ""
	queue_redraw()
	if t == "":
		return
	if t == "return":
		back_pressed.emit()
	elif t == "prev":
		phase_changed.emit(-1)
	elif t == "next":
		phase_changed.emit(1)
	elif t.begins_with("comp:"):
		competition_selected.emit(t.substr(5))


# ---- text ------------------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((glyphs.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


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


@warning_ignore("integer_division")
func _txt_mid(page: Texture2D, glyphs: Dictionary, field_sum: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, (field_sum - _advance(glyphs, s)) / 2, y_top, s, col)


func _txt_right(page: Texture2D, glyphs: Dictionary, pen_end: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, pen_end - _advance(glyphs, s), y_top, s, col)


func _gdi_text(f: Font, sz: int, s: String, span: int, y_top: int, ink: Color) -> void:
	if f == null or s == "":
		return
	var w := int(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	@warning_ignore("integer_division")
	var px := (span - w) / 2
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)


# ---- draw ------------------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _desktop != null:
		draw_texture_rect(_desktop, Rect2(0, 0, W, H), false)
	_draw_header()
	_draw_band()
	match _layout:
		"kitlist":
			_draw_kitlist()
		"bracket":
			_draw_bracket()
		"cards":
			_draw_cards()
		"final":
			_draw_final()
		_:
			_draw_panel()
	var rail: Texture2D = _chips.get(_comp)
	if rail != null:
		draw_texture(rail, RAIL_XY)
	if _press != "":
		var r := _press_rect()
		if r.size.x > 0.0:
			draw_rect(r, C_PRESS, true)


func _press_rect() -> Rect2:
	if _press == "return":
		return R_RETURN
	var pr := _pager_rects()
	if _press == "prev" and pr.size() == 2:
		return pr[0]
	if _press == "next" and pr.size() == 2:
		return pr[1]
	if _press.begins_with("comp:"):
		var c := _press.substr(5)
		if CHIP_TOP.has(c):
			return Rect2(CHIP_X, CHIP_TOP[c], CHIP_W, CHIP_H)
	return Rect2()


func _draw_header() -> void:
	for k in HDR_PATCH_XY:
		var tex: Texture2D = _patches.get(k)
		if tex == null:
			continue
		if k == "hdr_status":
			draw_texture_rect_region(tex,
				Rect2(HDR_PATCH_XY[k], Vector2(HDR_STATUS_W, tex.get_height())),
				Rect2(0, 0, HDR_STATUS_W, tex.get_height()))
		else:
			draw_texture(tex, HDR_PATCH_XY[k])
	_gdi_text(_f8, 11, str(_header.get("top", "")), PMChrome.HDR_NAME_TOP["S"],
		PMChrome.HDR_NAME_TOP["y"], Color(0, 0, 0))
	_gdi_text(_f8, 11, str(_header.get("bottom", "")), PMChrome.HDR_NAME_BOT["S"],
		PMChrome.HDR_NAME_BOT["y"], Color(1, 1, 1))
	var cid := int(_header.get("club_id", -1))
	PMChrome.draw_manager_panel(self, cid)
	for line in PMChrome.HDR_CAL_LINES:
		_gdi_text(_f8, 11, str(_header.get(line["key"], "")), PMChrome.HDR_CAL_S,
			line["y"], line["ink"])
	_gdi_text(_fcal, 15, str(_header.get("status_top", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_TOP_Y, Color(0, 0, 0))
	_gdi_text(_fcal, 15, str(_header.get("status_bottom", "")),
		PMChrome.HDR_STAT_S, PMChrome.HDR_STAT_BOT_Y, Color(1, 1, 1))


## The competition band: the trophy, the name plate and the paginator, cut whole from that
## competition's own frame (the band's PLACEMENT is not a rule this port can state -- see
## the baker's header), with only the phase label and the arrow faces redrawn.
func _draw_band() -> void:
	var key := _band_key()
	var tex: Texture2D = _bands.get(key)
	var m: Dictionary = _band_meta.get(key, {})
	if tex == null or m.is_empty():
		return
	var org: Array = m.get("origin", [0, 0])
	draw_texture(tex, Vector2(int(org[0]), int(org[1])))
	var plate: Array = m.get("plate", [0, 0, 0, 0])
	_txt_mid(_page_p10, _g_p10, int(plate[0]) + int(plate[2]) + 1,
		int(plate[1]) + LABEL_TOP_DY, _label, C_LABEL)
	var l: Array = m.get("left", [0, 0])
	var r: Array = m.get("right", [0, 0])
	# A disabled arrow's triangle is dithered against absolute screen parity, so the face
	# is chosen by (x + y) & 1 -- both phases are the original's own (see the baker).
	var lt: Texture2D = _pager.get("left_on" if _has_prev
		else "left_off_p%d" % ((int(l[0]) + int(l[1])) & 1))
	var rt: Texture2D = _pager.get("right_on" if _has_next
		else "right_off_p%d" % ((int(r[0]) + int(r[1])) & 1))
	if lt != null:
		draw_texture(lt, Vector2(int(l[0]), int(l[1])))
	if rt != null:
		draw_texture(rt, Vector2(int(r[0]), int(r[1])))


func _draw_panel() -> void:
	var hdr: Texture2D = _hdr.get("euro" if _euro_cols else "dom")
	if hdr != null:
		draw_texture(hdr, HDR_XY)
	var n := visible_rows()
	if n <= 0:
		return
	var cs := cols()
	var bh := body_h()
	var last_x: int = int((cs[cs.size() - 1] as Array)[1])

	# the panel's own rules: the two side borders, the column rules, the row rules and the
	# 3 px foot -- all black, all full-bleed across the panel.
	draw_rect(Rect2(PANEL_X0, BODY_TOP, PANEL_X1 - PANEL_X0 + 1, bh), C_BLACK, true)
	for i in n:
		var span := _row_span(i)
		var dark := i % 2
		var mine := bool((_ties[i + _offset] as Dictionary).get("mine", false))
		for j in cs.size():
			var c: Array = cs[j]
			var col: Color = BG_MINE[0] if mine else BG_NAME[dark]
			if j == cs.size() - 1:
				col = BG_MINE[2] if mine else BG_LAST[dark]
			elif j >= 2:
				col = BG_MINE[1] if mine else BG_SCORE[dark]
			draw_rect(Rect2(int(c[0]), span.x, int(c[1]) - int(c[0]) + 1,
				span.y - span.x + 1), col, true)
	# the foot: the last two of the three border rows sit BELOW the body rect above
	draw_rect(Rect2(PANEL_X0, BODY_TOP + bh - 1, PANEL_X1 - PANEL_X0 + 1, BOTTOM_BORDER),
		C_BLACK, true)
	if last_x < PANEL_X1:
		draw_rect(Rect2(last_x + 1, BODY_TOP, PANEL_X1 - last_x, bh), C_BLACK, true)

	for i in n:
		_draw_row(i, cs)
	_draw_scroll()


func _draw_row(i: int, cs: Array) -> void:
	var tie: Dictionary = _ties[i + _offset]
	var span := _row_span(i)
	var winner := int(tie.get("winner", -1))
	var plain: Color = C_MINE if bool(tie.get("mine", false)) else C_OUT
	var home_cell: Array = cs[0]
	var away_cell: Array = cs[1]
	_txt_right(_page_p10, _g_p10, int(home_cell[1]) + NAME_RIGHT_DX,
		span.x + NAME_TOP_DY, str(tie.get("home", "")),
		C_THROUGH if winner == 0 else plain)
	_txt(_page_p10, _g_p10, int(away_cell[0]) + NAME_LEFT_DX,
		span.x + NAME_TOP_DY, str(tie.get("away", "")),
		C_THROUGH if winner == 1 else plain)

	var cells: Array = tie.get("cells", [])
	for j in mini(cells.size(), cs.size() - 2):
		var pair: Array = cells[j]
		if pair.is_empty() or (str(pair[0]) == "" and str(pair[1]) == ""):
			continue
		var c: Array = cs[j + 2]
		var x0: int = int(c[0])
		var top: int = span.x + SCORE_TOP_DY
		# The club going through has ITS goals inked yellow in every cell. The second leg
		# is printed with the sides swapped (the leg-2 host first), so the marked position
		# is the other one there -- witnessed on 15 rows of 06_euroleague_round1_played.
		var mark := -1 if winner < 0 else (1 - winner if _is_second_leg(j) else winner)
		_txt_right(_page_p10, _g_p10, x0 + SCORE_A_END_DX, top, str(pair[0]),
			C_THROUGH if mark == 0 else plain)
		_txt(_page_p10, _g_p10, x0 + SCORE_DASH_DX, top, "-", plain)
		_txt(_page_p10, _g_p10, x0 + SCORE_B_DX, top, str(pair[1]),
			C_THROUGH if mark == 1 else plain)


func _is_second_leg(col_index: int) -> bool:
	return _euro_cols and col_index == 1


# ---- the kit list ------------------------------------------------------------------

## Layout 2: a round of 5-8 ties. Chrome = three baked strips (panel top, one 30-row row
## unit repeated per tie, the tail), all cut from the witnessed frames with their content
## rects blanked; everything a career fills is redrawn at the measured anchors. The score
## grammar is the compact list's, unchanged, and re-verified here on the DOMESTIC witness:
## the club going through takes the yellow ink and so does its own goal digit.
func _draw_kitlist() -> void:
	var key := "euro" if _euro_cols else "dom"
	var hdr: Texture2D = _kl.get("hdr_%s" % key)
	if hdr != null:
		draw_texture(hdr, KL_HDR_XY)
	var n := mini(_ties.size(), KITLIST_MAX_TIES)
	if n <= 0:
		return
	var row: Texture2D = _kl.get("row_%s" % key)
	var cs: Array = KL_COLS_EURO if _euro_cols else KL_COLS_DOM
	for i in n:
		var t := KL_BODY_TOP + KL_PITCH * i
		if row != null:
			draw_texture(row, Vector2(KL_PANEL_X0, t))
	var foot: Texture2D = _kl.get("foot_%s" % key)
	if foot != null:
		draw_texture(foot, Vector2(KL_PANEL_X0, KL_BODY_TOP + KL_ROW_H + KL_PITCH * (n - 1)))
	for i in n:
		_draw_kitlist_row(i, cs)


func _draw_kitlist_row(i: int, cs: Array) -> void:
	var tie: Dictionary = _ties[i]
	var t := KL_BODY_TOP + KL_PITCH * i
	var top := t + KL_TEXT_TOP_DY
	var winner := int(tie.get("winner", -1))
	for side in 2:
		var well: Array = cs[0] if side == 0 else cs[3]
		var wx := int(well[0])
		# The outline pass is DITHERED against absolute screen parity, exactly like the
		# paginator's disabled arrow: the left well (x15) and the EUROPEAN right well
		# (x289) are both odd and agree pixel for pixel across all three witnesses, while
		# the DOMESTIC right well (x344, even) disagrees at 222 of the well's 616
		# positions. So both phases are baked from real frames and picked here.
		var par := (wx + t) & 1
		var ul: Texture2D = _kl.get("under_p%d" % par)
		if ul != null:
			draw_texture(ul, Vector2(wx, t))
		var kit := _ridi_kit(int(tie.get("home_id" if side == 0 else "away_id", -1)))
		if kit != null:
			draw_texture(kit, Vector2(wx + KL_SPR_DXY.x, t + KL_SPR_DXY.y))
		var ol: Texture2D = _kl.get("over_p%d" % par)
		if ol != null:
			draw_texture(ol, Vector2(wx, t))
	var home_cell: Array = cs[1]
	var away_cell: Array = cs[2]
	_txt_right(_page_p10, _g_p10, int(home_cell[1]) + NAME_RIGHT_DX, top,
		str(tie.get("home", "")), C_THROUGH if winner == 0 else C_OUT)
	_txt(_page_p10, _g_p10, int(away_cell[0]) + NAME_LEFT_DX, top,
		str(tie.get("away", "")), C_THROUGH if winner == 1 else C_OUT)
	var cells: Array = tie.get("cells", [])
	for j in mini(cells.size(), cs.size() - 4):
		var pair: Array = cells[j]
		if pair.is_empty() or (str(pair[0]) == "" and str(pair[1]) == ""):
			continue
		var x0: int = int((cs[j + 4] as Array)[0])
		var mark := -1 if winner < 0 else (1 - winner if _is_second_leg(j) else winner)
		_txt_right(_page_p10, _g_p10, x0 + SCORE_A_END_DX, top, str(pair[0]),
			C_THROUGH if mark == 0 else C_OUT)
		_txt(_page_p10, _g_p10, x0 + SCORE_DASH_DX, top, "-", C_OUT)
		_txt(_page_p10, _g_p10, x0 + SCORE_B_DX, top, str(pair[1]),
			C_THROUGH if mark == 1 else C_OUT)


## The scrollbar only exists when the list is longer than the panel. Its arrows and trough
## are the original's own; the thumb is drawn proportional to the window -- the two frames
## in hand differ only in its LENGTH, so the tracking rule itself is an inference and is
## recorded as one in docs/re/knockout_views_re.md.
func _draw_scroll() -> void:
	if _ties.size() <= MAX_ROWS or _scroll_col == null:
		return
	draw_texture(_scroll_col, SCROLL_XY)
	if _scroll_thumb == null:
		return
	var trough := SCROLL_TROUGH[1] - SCROLL_TROUGH[0] + 1
	var len_px := maxi(8, int(round(float(MAX_ROWS) / float(_ties.size()) * trough)))
	var free := trough - len_px
	var max_off := maxi(1, _ties.size() - MAX_ROWS)
	var top: int = SCROLL_TROUGH[0] + int(round(float(_offset) / float(max_off) * free))
	for y in len_px:
		draw_texture(_scroll_thumb, Vector2(SCROLL_XY.x, top + y))


# ---- the bracket -----------------------------------------------------------------

func _flag(code: int) -> Texture2D:
	if code < 0:
		return null
	if not _flags.has(code):
		var p := "res://art/flags/dbcard/%d.png" % code
		_flags[code] = load(p) if ResourceLoader.exists(p) else null
	return _flags[code]


## Four 80 px-pitch panels; the strip is the original's own chrome (content blanked by
## the baker), everything a career fills is redrawn at the measured anchors. What a
## DECIDED tie draws here is unwitnessed -- no captured bracket has one -- so the
## advancing-club highlight applies the LIST layout's witnessed rule (the club going
## through and its own goals in yellow) to this layout's own base inks, and says so.
func _draw_bracket() -> void:
	var strip: Texture2D = _bracket.get("euro" if _euro_cols else "dom")
	var cxs: Array = BRACKET_BOX_CX_EURO if _euro_cols else BRACKET_BOX_CX_DOM
	var bgs: Array = BRACKET_BOX_BG_EURO if _euro_cols else BRACKET_BOX_BG_DOM
	var inks: Array = BRACKET_SCORE_INK_EURO if _euro_cols else BRACKET_SCORE_INK_DOM
	var blends: Array = BRACKET_DASH_BLEND_EURO if _euro_cols else BRACKET_DASH_BLEND_DOM
	for i in mini(_ties.size(), BRACKET_TIES):
		var t := int(BRACKET_TOPS[i])
		if strip != null:
			draw_texture(strip, Vector2(BRACKET_PANEL_X, t))
		var tie: Dictionary = _ties[i]
		if _well.get("under_L") != null:
			draw_texture(_well["under_L"], Vector2(BRACKET_WELL_L.x, t + BRACKET_WELL_L.y))
		if _well.get("under_R") != null:
			draw_texture(_well["under_R"], Vector2(BRACKET_WELL_R.x, t + BRACKET_WELL_R.y))
		var kl := PMChrome.kit(int(tie.get("home_id", -1)))
		if kl != null:
			draw_texture(kl, Vector2(BRACKET_KIT_L.x, t + BRACKET_KIT_L.y))
		var kr := PMChrome.kit(int(tie.get("away_id", -1)))
		if kr != null:
			draw_texture(kr, Vector2(BRACKET_KIT_R.x, t + BRACKET_KIT_R.y))
		if _well.get("over_L") != null:
			draw_texture(_well["over_L"], Vector2(BRACKET_WELL_L.x, t + BRACKET_WELL_L.y))
		if _well.get("over_R") != null:
			draw_texture(_well["over_R"], Vector2(BRACKET_WELL_R.x, t + BRACKET_WELL_R.y))
		var fl := _flag(int(tie.get("home_flag", -1)))
		if fl != null:
			draw_texture(fl, Vector2(BRACKET_FLAG_L.x, t + BRACKET_FLAG_L.y))
		var fr := _flag(int(tie.get("away_flag", -1)))
		if fr != null:
			draw_texture(fr, Vector2(BRACKET_FLAG_R.x, t + BRACKET_FLAG_R.y))
		var winner := int(tie.get("winner", -1))
		# The winner's plate is repainted BEFORE his name goes on it.
		if winner >= 0:
			_draw_winner_plate(t, winner)
		for side in 2:
			var s := str(tie.get("home" if side == 0 else "away", ""))
			@warning_ignore("integer_division")
			var pen: int = (int(BRACKET_NAME_CX2[side]) - _advance(_g_p10, s)) / 2
			_txt(_page_p10, _g_p10, pen, t + BRACKET_NAME_TOP_DY, s,
				C_THROUGH if winner == side else BRACKET_NAME_INK)
		var cells: Array = tie.get("cells", [])
		for j in mini(cells.size(), cxs.size()):
			var pair: Array = cells[j]
			if pair.is_empty() or (str(pair[0]) == "" and str(pair[1]) == ""):
				continue
			var cx := int(cxs[j])
			var top := t + BRACKET_SCORE_TOP_DY
			var mark := -1 if winner < 0 else (1 - winner if _is_second_leg(j) else winner)
			var plain_ink: Color = inks[j] if j < inks.size() else BRACKET_SCORE_INK
			_txt_right(_page_p10, _g_p10, cx - 5, top, str(pair[0]),
				C_THROUGH if mark == 0 else plain_ink)
			# the dash's six pixels are the .fnt's second alpha level -- the 80 % blend
			# of the ink over that slot's own box ground, witnessed on all four leg-1
			# cells (and applied to the unwitnessed slots by the same rule).
			_txt(_page_p10, _g_p10, cx - 2, top, "-",
				plain_ink.lerp(bgs[j], float(blends[j]) if j < blends.size() else 0.2))
			_txt(_page_p10, _g_p10, cx + 5, top, str(pair[1]),
				C_THROUGH if mark == 1 else plain_ink)


## Repaint one bracket tie's winning name plate and stamp its two inward chevrons
## (BRACKET_PLATE_* above). `t` is the panel top, `side` 0 = home / 1 = away.
func _draw_winner_plate(t: int, side: int) -> void:
	var span: Array = BRACKET_PLATE_X[side]
	var x0 := int(span[0])
	var x1 := int(span[1])
	draw_rect(Rect2(x0, t + BRACKET_PLATE_DY, x1 - x0 + 1, BRACKET_PLATE_H),
		BRACKET_PLATE_WIN, true)
	var apex := t + BRACKET_CHEVRON_APEX_DY
	for dy in range(-(BRACKET_CHEVRON_W - 1), BRACKET_CHEVRON_W):
		var w := BRACKET_CHEVRON_W - absi(dy)
		if w <= 0:
			continue
		# left edge: the triangle grows rightwards to its apex; right edge mirrors it.
		draw_rect(Rect2(x0 + 1, apex + dy, w, 1), BRACKET_CHEVRON, true)
		draw_rect(Rect2(x1 - w, apex + dy, w, 1), BRACKET_CHEVRON, true)


# ---- the semifinal cards -----------------------------------------------------------

func _ridi_kit(club_id: int) -> Texture2D:
	if club_id < 0:
		return null
	if not _ridi.has(club_id):
		var p := "res://art/kits/ridi/%d.png" % club_id
		_ridi[club_id] = load(p) if ResourceLoader.exists(p) else null
	return _ridi[club_id]


## Two cards, one tie each (docs/re/knockout_views_re.md "The semifinal cards, as
## built"). The chrome is the baked strip; the port redraws each leg block's venue (the
## HOST club's own ground -- the 2ND LEG swaps sides, its host first, as all three
## witnessed frames show), the ridi kit icon + club name + score digit per row, and the
## FINALIST plate once the tie is decided. UNWITNESSED and declared: the advancing-club
## highlight (the LIST layout's yellow rule applied here) and the FINALIST fill.
func _draw_cards() -> void:
	# The phase's SHAPE picks the strip: a two-legged phase carries the 1ST LEG / 2ND LEG
	# pair, a single-leg one (the F.A. Cup semifinals, witnessed 2026-07-28) carries ONE
	# block whose bar reads RESULT and simply ends after it. Both ties in a phase are the
	# same shape, so tie 0 decides.
	var phase_two := true
	if not _ties.is_empty():
		var t0: Dictionary = _ties[0]
		phase_two = bool(t0.get("two_legged", (t0.get("cells", []) as Array).size() >= 3))
	var body := _cards_body if phase_two or _cards_body_single == null else _cards_body_single
	if body != null:
		draw_texture(body, CARDS_BODY_XY)
	for i in mini(_ties.size(), CARDS_TIES):
		var dx := int(CARDS_DX[i])
		var tie: Dictionary = _ties[i]
		var winner := int(tie.get("winner", -1))
		var cells: Array = tie.get("cells", [])
		var two := bool(tie.get("two_legged", cells.size() >= 3))
		for leg in 2:
			# The single-leg strip has NO second block to draw a replay into: the one
			# witnessed F.A. Cup semifinal frame ends the panel after the RESULT block.
			# A replayed domestic semifinal in this layout is still unwitnessed, so the
			# port shows the original tie rather than inventing a second block.
			if leg == 1 and not phase_two:
				break
			var host := "away" if leg == 1 else "home"
			var guest := "home" if leg == 1 else "away"
			var pair: Array = cells[leg] if cells.size() > leg else ["", ""]
			var played := pair.size() >= 2 and (str(pair[0]) != "" or str(pair[1]) != "")
			# The 2ND LEG block of a SINGLE-leg tie holds the REPLAY when one was
			# played, in the same swapped grammar -- and stays empty otherwise. The
			# F.A. Cup model's replay in this layout is unwitnessed; declared.
			if leg == 1 and not two and not played:
				continue
			_txt(_page_p10, _g_p10, CARDS_VENUE_PEN_X + dx,
				int(CARDS_LEG_TOPS[leg]) + CARDS_VENUE_PEN_DY,
				str(tie.get(host + "_ground", "")), CARDS_VENUE_INK[i])
			for r in 2:
				var side := host if r == 0 else guest
				var side_i := 0 if side == "home" else 1
				var bar_top := int((CARDS_BARS[leg] as Array)[r])
				var ol := "sf%d" % (i + 1)
				if _icon_ol.get("under_" + ol) != null:
					draw_texture(_icon_ol["under_" + ol],
						Vector2(CARDS_ICON_X + dx, bar_top))
				var kt := _ridi_kit(int(tie.get(side + "_id", -1)))
				if kt != null:
					draw_texture(kt, Vector2(CARDS_ICON_X + dx, bar_top))
				if _icon_ol.get("over_" + ol) != null:
					draw_texture(_icon_ol["over_" + ol],
						Vector2(CARDS_ICON_X + dx, bar_top))
				# A DECIDED tie inks NOTHING yellow in this layout -- the two
				# 2026-07-28 witnesses (F.A. Cup and Coca-Cola semifinals, both
				# played out) print every club name and every goal digit in the
				# card's own ink. The list layout's yellow rule does not reach
				# here, and the port's earlier `C_THROUGH` was an inference from
				# that sibling layout; the frames refute it.
				_txt(_page_p10, _g_p10, CARDS_NAME_PEN_X + dx,
					bar_top + CARDS_TEXT_PEN_DY, str(tie.get(side, "")),
					CARDS_NAME_INK[i])
				var g := str(pair[r]) if pair.size() > r else ""
				if g != "":
					_txt_mid(_page_p10, _g_p10, int(CARDS_BOX_FIELD[i]),
						bar_top + CARDS_TEXT_PEN_DY, g, CARDS_SCORE_INK)
		if winner >= 0:
			_draw_finalist(i, str(tie.get("home_id" if winner == 0 else "away_id", "-1")),
				str(tie.get("home" if winner == 0 else "away", "")))


## The FINALIST plate, FILLED -- witnessed 2026-07-28 on two frames (the F.A. Cup and the
## Coca-Cola semifinals, both played out), which is what closed the port's declared-OURS
## guess (a GDI string centred in the plate, in the WINNER band's ink). The original puts
## the club's 24x32 NANO kit at the plate's left and prints his name proman10 beside it,
## LEFT-aligned, in THAT CARD's own name ink -- the same blue/green the club rows use.
## Pens solved off all four witnessed plates: name (plate_x0 + 43, 380), kit (plate_x0 + 2,
## 377). The kit keeps the un-reversed outline pass every other kit blit here carries
## (~80 px of 419 opaque), so the parity gate declares the two sprite wells.
func _draw_finalist(card: int, club_id: String, club: String) -> void:
	var fx: Array = CARDS_FINALIST[card]
	var x0 := int(fx[0])
	var kit := PMChrome.nano_kit(int(club_id))
	if kit != null:
		draw_texture(kit, Vector2(x0 + CARDS_FINALIST_KIT.x, CARDS_FINALIST_KIT.y))
	_txt(_page_p10, _g_p10, x0 + CARDS_FINALIST_PEN_DX, CARDS_FINALIST_PEN_Y, club,
		CARDS_NAME_INK[card])


# ---- the final ----------------------------------------------------------------------

## The one-tie view: trophy + RESULTS card + WINNER band. Every anchor is
## CompResultScreen's witnessed grammar -- the card and band chrome are byte-identical
## to the CHARITY SHIELD frame's outside the content rects (0 px, 2026-07-27). The kit
## wells keep that screen's documented approximation: the original's hi-res panel kit
## bank is un-extracted, so the app's own kit art is aspect-fitted into the measured
## rects and the parity gate declares the two wells.
func _draw_final() -> void:
	if _final_body != null:
		draw_texture(_final_body, CARDS_BODY_XY)
	if _ties.is_empty():
		return
	if _comp != "euro":
		_draw_final_domestic(_ties[0])
		return
	var tie: Dictionary = _ties[0]
	PMChrome.draw_crest(self, int(tie.get("home_id", -1)), FINAL_KIT_L)
	PMChrome.draw_crest(self, int(tie.get("away_id", -1)), FINAL_KIT_R)
	var fl := _flag(int(tie.get("home_flag", -1)))
	if fl != null:
		draw_texture(fl, FINAL_FLAG_L)
	var fr := _flag(int(tie.get("away_flag", -1)))
	if fr != null:
		draw_texture(fr, FINAL_FLAG_R)
	var venue := str(tie.get("venue", ""))
	if venue != "":
		PMChrome.text(self, _f12g, FINAL_STADIUM_X, FINAL_STADIUM_Y, venue,
			FINAL_C_STADIUM, 13, 1, 200.0)
	var cells: Array = tie.get("cells", [])
	var pair: Array = cells[0] if cells.size() > 0 else ["", ""]
	for r in 2:
		_txt(_page_p12, _g_p12, FINAL_NAME_PEN_X, int(FINAL_NAME_PEN_Y[r]),
			str(tie.get("home" if r == 0 else "away", "")), FINAL_C_NAME)
		# The played state's score digits (and the WINNER band below) keep
		# CompResultScreen's grammar: the witnessed CHARITY digits and winner name match
		# no extracted font bank (the winner ink is two-tone), so that screen's declared
		# approximation carries over until the face is reversed.
		var g := str(pair[r]) if pair.size() > r else ""
		if g != "":
			PMChrome.text(self, _f14g, FINAL_SCORE_CELL[0], FINAL_ROW_Y[r] - 1, g,
				Color(1, 1, 1), 15, 1, FINAL_SCORE_CELL[1])
	var winner := int(tie.get("winner", -1))
	if winner >= 0:
		_draw_final_winner(tie, winner)


## The WINNER band + laurel, shared by both final bodies: the two witnessed frames are
## pixel-identical there outside the name row and the wreath's middle.
func _draw_final_winner(tie: Dictionary, winner: int) -> void:
	var side := "home" if winner == 0 else "away"
	# The 2026-07-28 Coca-Cola witness is the FIRST frame with this band FILLED, and it
	# settles the pen exactly (ink x65..134, y383..395, so the pen is FINAL_WINNER_XY) but
	# NOT the face: the champion's name is 13 ink rows tall where proman12 gives 9, and no
	# extracted bank matches it (proman12 costs 608 px here, the GDI approximation 530).
	# So CompResultScreen's declared approximation stays and the row is a named bucket in
	# diff_knockout_parity until the face is reversed -- measured, not shrugged at.
	PMChrome.text(self, _f14g, FINAL_WINNER_XY[0], FINAL_WINNER_XY[1],
		str(tie.get(side, "")), FINAL_C_WINNER, 15, 0, 280.0)
	PMChrome.draw_crest(self, int(tie.get(side + "_id", -1)), FINAL_LAUREL)


## The DOMESTIC final's card (`tools/re/refs/knockout-2026-07-28/14`): MATCH RESULT over
## STADIUM, two club bars each carrying a 17x20 ridi icon, and an empty REPLAY RESULT panel
## that the port leaves empty -- a replayed domestic FINAL is not witnessed and is not
## invented. The WINNER band and the laurel are the shared ones.
func _draw_final_domestic(tie: Dictionary) -> void:
	var venue := str(tie.get("venue", ""))
	if venue != "":
		PMChrome.text(self, _f12g, DOM_FINAL_STADIUM_X, DOM_FINAL_STADIUM_Y, venue,
			FINAL_C_STADIUM, 13, 1, 200.0)
	var cells: Array = tie.get("cells", [])
	var pair: Array = cells[0] if cells.size() > 0 else ["", ""]
	for r in 2:
		var top := int(DOM_FINAL_BAR_TOP[r])
		var kt := _ridi_kit(int(tie.get("home_id" if r == 0 else "away_id", -1)))
		if kt != null:
			draw_texture(kt, Vector2(DOM_FINAL_ICON_X, top))
		_txt(_page_p12, _g_p12, DOM_FINAL_NAME_PEN_X, top + DOM_FINAL_NAME_PEN_DY,
			str(tie.get("home" if r == 0 else "away", "")), FINAL_C_NAME)
		var g := str(pair[r]) if pair.size() > r else ""
		if g != "":
			# Unlike the euro final -- whose only witness is UNPLAYED, so its digits stay
			# on CompResultScreen's declared GDI approximation -- this card has a PLAYED
			# witness, and its digits are the same proman12 bank the club names are.
			_txt_mid(_page_p12, _g_p12, DOM_FINAL_SCORE_FIELD,
				top + DOM_FINAL_NAME_PEN_DY, g, Color(1, 1, 1))
	var winner := int(tie.get("winner", -1))
	if winner >= 0:
		_draw_final_winner(tie, winner)
