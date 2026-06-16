extends Control
class_name CupScreen
## PM98 cup screen (F.A. Cup or Coca-Cola Cup): the manager's run through a domestic
## knockout, with the latest round's draw. PM98 chrome (BARRA bar + marble FONDO + ProMan
## font) around the competition's authentic trophy art (img\premier\copas\{facup,cocacola}.bmp,
## cracked from IMG.PKF via the shared VGA palette -> app/art/screens/cup/{trophy,cocacola}.png).
##
## Data-driven via setup() so it stays GameDB-free and headless-testable; Main builds the
## rows + picks the title/emblem from a Cup.gd bracket (Career.fa_cup / Career.league_cup).
## Native 640x480, self-scales and marble-bezels into the landscape letterbox like the
## other graphical screens. Display-only, tap-to-dismiss.

const W := 640
const H := 480

const C_TITLE := Color(0.96, 0.97, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_PANEL := Color(0.13, 0.21, 0.38)
const C_PANEL_HI := Color(0.27, 0.43, 0.65)
const C_PANEL_LO := Color(0.07, 0.13, 0.26)
const C_GOLD := Color(0.98, 0.86, 0.45)        # the manager's own tie / a win
const C_WIN := Color(0.31, 0.93, 0.55)
const C_LOSS := Color(0.86, 0.47, 0.44)
const C_BTN := Color(0.18, 0.28, 0.47)

const RUN_PANEL := Rect2(176, 58, 450, 188)
const DRAW_PANEL := Rect2(176, 252, 450, 214)
const TROPHY_AT := Vector2(34, 70)
const TROPHY_H := 150                            # drawn trophy height (px, design space)
const LBL_RETURN := Rect2(36, 438, 110, 28)

var _bg: Texture2D
var _bar: Texture2D
var _trophy: Texture2D
var _title := "F.A. CUP"          # competition title in the BARRA
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _status: String = ""             # "STILL IN" / "KNOCKED OUT" / "WINNERS!" / ...
var _status_col: Color = C_TEXT
var _sub: String = ""                # e.g. "16 clubs remain  -  Round 5 in 3 wks"
var _run_rows: Array = []            # [{round:String, line:String, accent:Color}]
var _draw_label: String = ""
var _draw_rows: Array = []           # [{line:String, mine:bool}]
var _draw_more: int = 0              # ties not shown (overflow note)


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_trophy = load("res://art/screens/cup/trophy.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


## Feed the prepared cup view, then repaint. `title` is the BARRA heading and `emblem_path`
## the competition's trophy art (defaults to the F.A. Cup trophy).
func setup(club: String, manager: String, season: String, status: String,
		status_col: Color, sub: String, run_rows: Array, draw_label: String,
		draw_rows: Array, draw_more := 0, title := "F.A. CUP",
		emblem_path := "res://art/screens/cup/trophy.png") -> void:
	_club = club
	_manager = manager
	_season = season
	_status = status
	_status_col = status_col
	_sub = sub
	_run_rows = run_rows
	_draw_label = draw_label
	_draw_rows = draw_rows
	_draw_more = maxi(0, draw_more)
	_title = title
	var em: Texture2D = load(emblem_path)
	if em != null:
		_trophy = em
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false, cw := 0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if right:
		px = x - w
	elif cw > 0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _panel(r: Rect2, base := C_PANEL) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), C_PANEL_HI, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), C_PANEL_HI, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), C_PANEL_LO, true)
	draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), C_PANEL_LO, true)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Marble field + BARRA chrome.
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 285, 13, _title, C_TITLE, 15)
	_txt(_f10, 12, 9, "Manager", C_TEXT, 11)
	_txt(_f10, 12, 26, (_manager if _manager != "" else _club).substr(0, 18), C_DIM, 11)
	_txt(_f10, 628, 9, _club.substr(0, 18), C_TEXT, 11, true)
	if _season != "":
		_txt(_f10, 628, 26, _season, C_DIM, 11, true)

	# The trophy emblem + the manager's status beneath it.
	if _trophy != null:
		var th := _trophy.get_height()
		var scale := float(TROPHY_H) / float(th) if th > 0 else 1.0
		var tw := _trophy.get_width() * scale
		draw_texture_rect(_trophy, Rect2(TROPHY_AT.x + (130 - tw) * 0.5, TROPHY_AT.y, tw, TROPHY_H), false)
	if _status != "":
		_txt(_f12, 18, int(TROPHY_AT.y) + TROPHY_H + 8, _status, _status_col, 13, false, 130)
	if _sub != "":
		# Wrap the sub line over up to two centred lines under the status.
		for i in _wrap(_sub, 18).size():
			_txt(_f8, 18, int(TROPHY_AT.y) + TROPHY_H + 28 + i * 13, _wrap(_sub, 18)[i], C_DIM, 10, false, 130)

	# YOUR CUP RUN panel.
	_panel(RUN_PANEL)
	var rx := int(RUN_PANEL.position.x)
	var ry := int(RUN_PANEL.position.y)
	_txt(_f12, rx + 10, ry + 6, "YOUR CUP RUN", C_HEAD, 13)
	if _run_rows.is_empty():
		_txt(_f10, rx + 10, ry + 30, "Not entered yet.", C_DIM, 11)
	var y := ry + 28
	for row in _run_rows:
		var acc: Color = row.get("accent", C_TEXT)
		_txt(_f10, rx + 12, y, str(row.get("round", "")).substr(0, 14), C_DIM, 11)
		_txt(_f10, rx + 120, y, str(row.get("line", "")).substr(0, 40), acc, 11)
		y += 22

	# THE DRAW panel (latest round's ties, manager's tie in gold).
	_panel(DRAW_PANEL)
	var dx := int(DRAW_PANEL.position.x)
	var dy := int(DRAW_PANEL.position.y)
	var head := "THE DRAW" if _draw_label == "" else ("THE DRAW  -  %s" % _draw_label.to_upper())
	_txt(_f12, dx + 10, dy + 6, head, C_HEAD, 13)
	if _draw_rows.is_empty():
		_txt(_f10, dx + 10, dy + 30, "The draw has not been made.", C_DIM, 11)
	var dyy := dy + 28
	for row in _draw_rows:
		var mine: bool = bool(row.get("mine", false))
		_txt(_f8, dx + 14, dyy, str(row.get("line", "")).substr(0, 64), C_GOLD if mine else C_TEXT, 10)
		dyy += 16
	if _draw_more > 0:
		_txt(_f8, dx + 14, dyy, "... and %d more ties" % _draw_more, C_DIM, 10)

	# RETURN button (the whole screen is tap-to-dismiss; this is chrome).
	_panel(LBL_RETURN, C_BTN)
	_txt(_f10, int(LBL_RETURN.position.x), int(LBL_RETURN.position.y) + 6,
		"RETURN", C_TEXT, 11, false, int(LBL_RETURN.size.x))


## Greedy word-wrap of `s` to at most `width` chars per line (for the narrow sub area).
func _wrap(s: String, width: int) -> Array:
	var words := s.split(" ", false)
	var lines: Array = []
	var cur := ""
	for w in words:
		if cur == "":
			cur = w
		elif cur.length() + 1 + w.length() <= width:
			cur += " " + w
		else:
			lines.append(cur)
			cur = w
	if cur != "":
		lines.append(cur)
	return lines.slice(0, 2)
