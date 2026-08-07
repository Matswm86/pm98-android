extends Control
class_name HonoursScreen
## HONOURS + CAREER RESUME — **OURS, not the original's**.
##
## `docs/SPEC_ours_additions.md` item 1, owner-approved 2026-07-25. The original tracks
## eight trophies and shows each one only in the moment it is won, then forgets; it raises
## no board-verdict screen at all (REFRUN R15). Nothing in MANAGER.EXE draws this screen,
## so nothing here is claimed to be frame-true and no parity harness covers it. What IS
## faithful is the DATA: every line comes from `Career.honours`, the ledger written at the
## season rollover from the same brackets the champion cards are built from, so a level
## final carries its own "(on penalties)" qualifier (REFRUN R14) instead of a bare score.
##
## It is reached by tapping the manager-name plaque on the witnessed MANAGER HISTORY
## screen — a zone that screen leaves inert — so MANAGER HISTORY itself still renders at
## 0 differing pixels. Same rule as the SCOUT screen's extra-filters panel: an addition
## may not cost a witnessed pixel.
##
## Two pages, toggled by the button at the bottom left:
##   HONOURS — one row per competition: the seasons won, then the seasons lost in the final
##   CAREER  — one row per season: club, division, final position, the board's objective
##             and whether it was met, the trophies lifted, and how the season ended

signal back_pressed

const W := 640
const H := 480

const BTN_RETURN := Rect2(508, 440, 100, 26)
const BTN_PAGE := Rect2(24, 440, 130, 26)

const TITLE_Y := 20
const HEAD_Y := 58
const ROW_Y0 := 78
const ROW_PITCH := 20
const ROWS_VISIBLE := 17
const COL_LABEL := 28
const COL_WON := 210
const COL_LOST := 420

# Career page columns.
const CR_SEASON := 28
const CR_CLUB := 100
const CR_DIV := 196
const CR_POS := 276
const CR_OBJ := 306
const CR_OBJ_W := 106.0        # the objective is a sentence; auto-fit it into its column
const CR_WON := 420
const CR_WON_W := 196.0

# The desktop family this screen borrows (the SCOUT extra panel's plate).
const C_BG := Color8(20, 24, 60)
const C_EDGE := Color8(160, 180, 200)
const C_TITLE := Color8(255, 210, 0)
const C_HEAD := Color8(140, 150, 175)
const C_TXT := Color8(230, 235, 245)
const C_WON_INK := Color8(255, 210, 0)
const C_LOST_INK := Color8(160, 170, 195)
const C_MET := Color8(42, 191, 85)
const C_MISSED := Color8(235, 80, 70)
const C_BAND := Color8(30, 36, 78)

var _board: Dictionary = {}      # Career.honours_board()
var _resume: Array = []          # Career.career_resume()
var _manager := ""
var _page := 0                   # 0 = HONOURS, 1 = CAREER
var _scroll := 0
var _f8: Font
var _f10: Font
var _f12: Font
var _drag := PMTouch.Drag.new()  # drag-to-scroll (input layer only)


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(manager: String, board: Dictionary, resume: Array) -> void:
	_manager = manager
	_board = board
	_resume = resume
	_page = 0
	_scroll = 0
	queue_redraw()


## The rows the HONOURS page shows: every competition that has ever been won or lost in a
## final. A competition the manager has never reached the final of is left out entirely —
## an empty row would say nothing.
func honour_rows() -> Array:
	var rows: Array = []
	for key in Career.HONOUR_COMPS:
		var slot: Dictionary = _board.get(key, {})
		var won: Array = slot.get("won", [])
		var lost: Array = slot.get("runner_up", [])
		if won.is_empty() and lost.is_empty():
			continue
		rows.append({"name": str(Career.HONOUR_NAMES.get(key, key)),
			"won": won, "lost": lost})
	return rows


func _rows() -> Array:
	return honour_rows() if _page == 0 else _resume


func _to_design(p: Vector2) -> Vector2:
	var s: float = minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if e is InputEventScreenDrag or e is InputEventMouseMotion:
		# PMTouch drag-to-scroll: whole rows at ROW_PITCH
		var rows := _drag.take_rows(_to_design(e.position).y, ROW_PITCH)
		if rows != 0:
			_scroll = clampi(_scroll + rows, 0, maxi(0, _rows().size() - ROWS_VISIBLE))
			queue_redraw()
		return
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var p := _to_design(e.position)
	if e.pressed:
		# arm only over the list rows, never on a button (PMTouch)
		_drag.press(p.y, p.y > ROW_Y0
			and not BTN_RETURN.has_point(p) and not BTN_PAGE.has_point(p))
		return
	if _drag.release():
		return    # the gesture scrolled (or dup release) — no tap dispatch
	if BTN_RETURN.has_point(p):
		back_pressed.emit()
	elif BTN_PAGE.has_point(p):
		_page = 1 - _page
		_scroll = 0
		queue_redraw()
	elif p.y > ROW_Y0:
		# a tap on the list scrolls a page at a time (top half up, bottom half down)
		var n := _rows().size()
		var step := -ROWS_VISIBLE if p.y < ROW_Y0 + ROWS_VISIBLE * ROW_PITCH * 0.5 else ROWS_VISIBLE
		_scroll = clampi(_scroll + step, 0, maxi(0, n - ROWS_VISIBLE))
		queue_redraw()


func _draw() -> void:
	var s: float = minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	draw_rect(Rect2(8, 8, W - 16, H - 16), C_BG, true)
	draw_rect(Rect2(8, 8, W - 16, H - 16), C_EDGE, false, 1.0)

	var title := "HONOURS" if _page == 0 else "CAREER"
	PMChrome.text(self, _f12, COL_LABEL, TITLE_Y, title, C_TITLE, 13)
	PMChrome.text(self, _f8, COL_LABEL, TITLE_Y + 20,
		"%s - kept by this port, not by the 1998 game." % _manager, C_HEAD, 9)

	if _page == 0:
		_draw_honours()
	else:
		_draw_career()

	_button(BTN_PAGE, "CAREER" if _page == 0 else "HONOURS")
	_button(BTN_RETURN, "RETURN")


func _draw_honours() -> void:
	PMChrome.text(self, _f8, COL_LABEL, HEAD_Y, "COMPETITION", C_HEAD, 9)
	PMChrome.text(self, _f8, COL_WON, HEAD_Y, "WON", C_HEAD, 9)
	PMChrome.text(self, _f8, COL_LOST, HEAD_Y, "RUNNERS-UP", C_HEAD, 9)
	var rows := honour_rows()
	if rows.is_empty():
		PMChrome.text(self, _f10, COL_LABEL, ROW_Y0,
			"No finals yet. Trophies appear here the season after you win them.",
			C_TXT, 11)
		return
	for i in mini(ROWS_VISIBLE, rows.size() - _scroll):
		var r: Dictionary = rows[_scroll + i]
		var y := ROW_Y0 + i * ROW_PITCH
		if i % 2 == 1:
			draw_rect(Rect2(16, y - 2, W - 32, ROW_PITCH), C_BAND, true)
		PMChrome.text(self, _f10, COL_LABEL, y, str(r["name"]), C_TXT, 11)
		PMChrome.text(self, _f8, COL_WON, y + 1, _seasons(r["won"]), C_WON_INK, 9, 0, 200.0)
		PMChrome.text(self, _f8, COL_LOST, y + 1, _seasons(r["lost"]), C_LOST_INK, 9, 0, 192.0)


func _draw_career() -> void:
	PMChrome.text(self, _f8, CR_SEASON, HEAD_Y, "SEASON", C_HEAD, 9)
	PMChrome.text(self, _f8, CR_CLUB, HEAD_Y, "CLUB", C_HEAD, 9)
	PMChrome.text(self, _f8, CR_DIV, HEAD_Y, "DIVISION", C_HEAD, 9)
	PMChrome.text(self, _f8, CR_POS, HEAD_Y, "POS.", C_HEAD, 9)
	PMChrome.text(self, _f8, CR_OBJ, HEAD_Y, "OBJECTIVE", C_HEAD, 9)
	PMChrome.text(self, _f8, CR_WON, HEAD_Y, "WON", C_HEAD, 9)
	if _resume.is_empty():
		PMChrome.text(self, _f10, CR_SEASON, ROW_Y0,
			"Your first season is still running - it lands here when it ends.", C_TXT, 11)
		return
	for i in mini(ROWS_VISIBLE, _resume.size() - _scroll):
		var r: Dictionary = _resume[_scroll + i]
		var y := ROW_Y0 + i * ROW_PITCH
		if i % 2 == 1:
			draw_rect(Rect2(16, y - 2, W - 32, ROW_PITCH), C_BAND, true)
		PMChrome.text(self, _f8, CR_SEASON, y + 1, str(r["season"]), C_TXT, 9)
		PMChrome.text(self, _f10, CR_CLUB, y, str(r["club"]), C_TXT, 11, 0, 92.0)
		PMChrome.text(self, _f8, CR_DIV, y + 1, str(r["league"]), C_HEAD, 9, 0, 76.0)
		PMChrome.text(self, _f8, CR_POS, y + 1, str(int(r["pos"])), C_TXT, 9)
		PMChrome.text(self, _f8, CR_OBJ, y + 1, str(r["objective"]),
			C_MET if bool(r["objective_met"]) else C_MISSED, 9, 0, CR_OBJ_W)
		var won: Array = r["won"]
		var txt := ", ".join(PackedStringArray(won)) if not won.is_empty() else "-"
		if str(r.get("ended", "")) != "":
			txt = "%s [%s]" % [txt, str(r["ended"])]
		PMChrome.text(self, _f8, CR_WON, y + 1, txt,
			C_WON_INK if not won.is_empty() else C_HEAD, 9, 0, CR_WON_W)


## "1997-98, 2001-02 (on penalties)" — the seasons, each carrying its own qualifier.
func _seasons(entries: Array) -> String:
	var parts: Array = []
	for e in entries:
		var d: Dictionary = e
		var s := str(d.get("season", ""))
		if str(d.get("detail", "")) != "":
			s = "%s (%s)" % [s, str(d["detail"])]
		parts.append(s)
	return ", ".join(PackedStringArray(parts)) if not parts.is_empty() else "-"


func _button(r: Rect2, label: String) -> void:
	draw_rect(r, Color8(40, 48, 96), true)
	draw_rect(r, C_EDGE, false, 1.0)
	if _f10 == null:
		return
	var w := _f10.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	PMChrome.text(self, _f10, r.position.x + (r.size.x - w) * 0.5, r.position.y + 6,
		label, C_TXT, 11)
