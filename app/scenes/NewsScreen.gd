extends Control
class_name NewsScreen
## PM98 "News extra" (NOTICIAS) — the newspaper overlay the hub NEWS control opens,
## frame-baked from the live walkthrough (docs/re/news_screen_re.md).
##
## Witnessed states (run1): 155_154857 = front page — "News extra" masthead, blue
## "Premier League : MARKET" subtitle + light-blue rule, EMPTY white body (preseason),
## WEEKS: LAST/ACTUAL toggle (ACTUAL black), bottom file-tabs MARKET(on)/INJURIES/
## BOOKINGS, right rotated division tabs Premier(on)/1st/2nd/3rd Div., grey [X].
## 158_154905 = 1st Div. clicked: masthead gone, subtitle at the page top, Premier
## tab off / 1st Div. on, [X] in its yellow over-art (EXE NOTICIAS: cerrarOver.bmp).
## 156_154859 = INJURIES tab over-state. The overlay footprint is exactly the page
## rect (145,27,350,425); the live hub stays visible (and interactive-dead) around it.
##
## The scene draws the baked page + live layers ONLY:
##  - division tabs (witnessed on/off arts; 2nd/3rd ON = builder colour-map splice),
##  - category tabs (witnessed MARKET-on baked; other states = builder splices),
##  - subtitle re-strike (proman10 — frame glyphs match its atlas bitmap-exactly;
##    format "%s : %s" + division names are MANAGER.EXE's own strings),
##  - the news list (UN-WITNESSED — both witnessed bodies are empty; rows render
##    real Career news only, calend8 face per the EXE's NOTICIAS string block;
##    flagged reconstruction in the doc),
##  - the WEEKS toggle selection swap (un-witnessed LAST-selected state — the
##    baked ACTUAL-selected art is witnessed; swap is a documented reconstruction).
## Nothing here is invented content: empty categories stay empty.

signal back_pressed

const W := 640
const H := 480

## kind -> bottom tab. The original files league news under MARKET / INJURIES /
## BOOKINGS; our Career kinds map: market moves = transfer/contract/staff,
## injuries = injury. Bookings are not modelled by Career -> honestly empty.
## Other kinds (result/cup/youth) belong to hub alerts, not the newspaper.
const CATEGORY_KINDS := {
	"MARKET": ["transfer", "contract", "staff"],
	"INJURIES": ["injury"],
	"BOOKINGS": [],
}

var _spec: Dictionary = {}
var _page_premier: Texture2D
var _page_division: Texture2D
var _x_over: Texture2D
var _tabs: Dictionary = {}          # sprite name -> Texture2D
var _f10: Font
var _f8c: Font

var _division := 0                   # 0=Premier .. 3=Third Division
var _category := "MARKET"
var _weeks_actual := true            # ACTUAL (this week) vs LAST (previous week)
var _feed: Array = []                # [{week, kind, text}] newest first (Career.news_log)
var _week_now := 0
var _club_division := 0              # the managed club's division index
var _press := ""


func _ensure_loaded() -> void:
	if not _spec.is_empty():
		return
	var f := FileAccess.open("res://art/screens/news/news_chrome.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spec = parsed
	_page_premier = load("res://art/screens/news/page_premier.png")
	_page_division = load("res://art/screens/news/page_division.png")
	_x_over = load("res://art/screens/news/x_over.png")
	for n in ["tab_premier_on", "tab_premier_off", "tab_first_on", "tab_first_off",
			"tab_second_on", "tab_second_off", "tab_third_on", "tab_third_off",
			"tab_market_off", "tab_injuries_on", "tab_injuries_over", "tab_bookings_on"]:
		_tabs[n] = load("res://art/screens/news/%s.png" % n)
	_f10 = PMChrome.font("10")
	_f8c = PMChrome.font("calend8") if PMChrome.font("calend8") != null else _f10


func _ready() -> void:
	_ensure_loaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `news_log` = Career.news_log (newest first), `week_now` = Career.week,
## `club_division` = the managed club's division index (0=Premier..3).
func setup(news_log = [], week_now = 0, club_division = 0) -> void:
	_ensure_loaded()
	_feed = news_log if news_log is Array else []
	_week_now = int(week_now)
	_club_division = clampi(int(club_division), 0, 3)
	queue_redraw()


## The rows the current tab state shows: real Career news only. The newspaper is
## league-wide in the original, but Career only records the manager's own club's
## events -> items appear under the club's own division tab, others stay empty
## (the witnessed state IS an empty page).
func visible_items() -> Array:
	if _division != _club_division:
		return []
	var kinds: Array = CATEGORY_KINDS.get(_category, [])
	var want_week := _week_now if _weeks_actual else _week_now - 1
	var out: Array = []
	for n in _feed:
		if not (n is Dictionary):
			continue
		if str(n.get("kind", "")) in kinds and int(n.get("week", -1)) == want_week:
			out.append(n)
	return out


func state() -> Dictionary:
	return {"division": _division, "category": _category, "weeks_actual": _weeks_actual}


# ---- geometry / input ----------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _rect(key: String, group := "") -> Rect2:
	var src: Dictionary = _spec.get(group, {}) if group != "" else _spec
	var b: Array = src.get(key, [0, 0, 0, 0])
	return Rect2(b[0], b[1], b[2], b[3])

const DIV_ORDER := ["premier", "first", "second", "third"]
const CAT_ORDER := ["market", "injuries", "bookings"]

func _hit(d: Vector2) -> String:
	if _rect("x_btn").has_point(d):
		return "x"
	for i in DIV_ORDER.size():
		if _rect(DIV_ORDER[i], "div_tabs").has_point(d):
			return "div:%d" % i
	for c in CAT_ORDER:
		if _rect(c, "cat_tabs").has_point(d):
			return "cat:" + c.to_upper()
	var wk: Dictionary = _spec.get("weeks", {})
	var last: Array = wk.get("last", [0, 0, 0, 0])
	var act: Array = wk.get("actual", [0, 0, 0, 0])
	if Rect2(last[0], last[1], last[2], last[3]).has_point(d):
		return "weeks:last"
	if Rect2(act[0], act[1], act[2], act[3]).has_point(d):
		return "weeks:actual"
	if not _rect("page").has_point(d):
		return "outside"
	return ""

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var pressed := (e as InputEventMouseButton).pressed if e is InputEventMouseButton \
		else (e as InputEventScreenTouch).pressed
	var pos: Vector2 = (e as InputEventMouseButton).position if e is InputEventMouseButton \
		else (e as InputEventScreenTouch).position
	var d := _to_design(pos)
	if pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	var am := get_node_or_null("/root/AudioManager")
	if am != null:
		am.ui_select()
	if was == "x" or was == "outside":
		back_pressed.emit()
	elif was.begins_with("div:"):
		_division = int(was.substr(4))
	elif was.begins_with("cat:"):
		_category = was.substr(4)
	elif was == "weeks:last":
		_weeks_actual = false
	elif was == "weeks:actual":
		_weeks_actual = true
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _ink_span(s: String, face: String) -> Array:
	var fm: Dictionary = (_spec.get("font_metrics", {}) as Dictionary).get(face, {})
	if fm.is_empty() or s.length() == 0 or not fm.has(s[0]) or not fm.has(s[s.length() - 1]):
		return []
	var adv := 0
	for i in s.length() - 1:
		adv += int((fm.get(s[i], [8, 0, 7]) as Array)[0])
	return [float((fm[s[0]] as Array)[1]), float(adv + int((fm[s[s.length() - 1]] as Array)[2]))]

## Ink-centred proman10 strike (asc 8 = baseline offset from the ink top).
func _txt_center(cx: float, y_top: float, s: String, col: Color) -> void:
	if _f10 == null:
		return
	var pen := cx - _f10.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x / 2.0
	var span := _ink_span(s, "proman10")
	if span.size() == 2:
		pen = cx - (float(span[0]) + float(span[1])) / 2.0
	draw_string(_f10, Vector2(floorf(pen), y_top + 8), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)


func _draw() -> void:
	_ensure_loaded()
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	var page := _rect("page")
	var on_premier := _division == 0
	var page_tex := _page_premier if on_premier else _page_division
	if page_tex != null:
		draw_texture(page_tex, page.position)

	var sub: Dictionary = _spec.get("subtitle", {})
	var divisions: Array = sub.get("divisions", [])
	var ink_arr: Array = sub.get("ink", [42, 63, 170])
	var c_sub := Color8(int(ink_arr[0]), int(ink_arr[1]), int(ink_arr[2]))

	# division tabs: the baked page carries the witnessed pair (premier page =
	# premier ON + rest OFF; division page = premier OFF + first ON). Overdraw
	# only what deviates from the baked base.
	if not on_premier:
		if _division != 1:
			_tab(DIV_ORDER[1], "tab_first_off")
			_tab(DIV_ORDER[_division], "tab_%s_on" % DIV_ORDER[_division])

	# category tabs: baked = MARKET on. Other categories overdraw the splices.
	if _category != "MARKET":
		_tab_cat("market", "tab_market_off")
		_tab_cat(_category.to_lower(), "tab_%s_on" % _category.to_lower())
	elif _press == "cat:INJURIES" and _tabs.get("tab_injuries_over") != null:
		_tab_cat("injuries", "tab_injuries_over")

	# subtitle: the baked pages carry the two witnessed subtitles; re-strike only
	# when the tab state deviates (blank the baked ink rows first — pure white
	# behind the text on both pages).
	var baked := (on_premier and _division == 0 and _category == "MARKET") \
		or (_division == 1 and _category == "MARKET")
	if not baked:
		var bb: Array = sub.get("premier_bbox" if on_premier else "division_bbox", [])
		if bb.size() == 4:
			draw_rect(Rect2(148, bb[1] - 2, 322, bb[3] - bb[1] + 5), Color.WHITE)
			var div_name := str(divisions[_division]) if _division < divisions.size() else "?"
			_txt_center(float(sub.get("cx", 308)), float(bb[1]), "%s : %s" % [div_name, _category], c_sub)

	# WEEKS toggle: ACTUAL-selected is the baked witnessed art; LAST-selected is
	# a documented reconstruction (plate palette swap, glyphs re-struck).
	if not _weeks_actual:
		var wk: Dictionary = _spec.get("weeks", {})
		var l: Array = wk.get("last", [199, 411, 42, 16])
		var a: Array = wk.get("actual", [241, 411, 43, 16])
		draw_rect(Rect2(l[0], l[1], l[2], l[3]), Color8(0, 0, 0))
		draw_rect(Rect2(a[0], a[1], a[2], a[3]), Color8(192, 192, 192))
		_txt_center(l[0] + l[2] / 2.0, l[1] + 4.0, "LAST", Color8(255, 255, 255))
		_txt_center(a[0] + a[2] / 2.0, a[1] + 4.0, "ACTUAL", Color8(0, 0, 0))

	# [X] over-art while pressed (EXE cerrarOver.bmp; witnessed frame 158)
	if _press == "x" and _x_over != null:
		draw_texture(_x_over, _rect("x_btn").position)

	# the news list (reconstruction — witnessed bodies are empty; real data only)
	var body: Dictionary = _spec.get("body", {})
	var items := visible_items()
	if not items.is_empty():
		var x := float(body.get("x", 152))
		var top := float(body.get("top_premier", 108) if on_premier else body.get("top_division", 58))
		var bottom := float(body.get("bottom", 402))
		var pitch := float(body.get("pitch", 13))
		var y := top
		for n in items:
			if y + pitch > bottom:
				break
			# calend8 draws at its native size 15 (FinanceScreen ledger precedent)
			draw_string(_f8c, Vector2(x, y + 11), str(n.get("text", "")),
				HORIZONTAL_ALIGNMENT_LEFT, int(body.get("right", 472) - x), 15, Color.BLACK)
			y += pitch
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _tab(key: String, sprite: String) -> void:
	var t: Texture2D = _tabs.get(sprite)
	if t != null:
		draw_texture(t, _rect(key, "div_tabs").position)

func _tab_cat(key: String, sprite: String) -> void:
	var t: Texture2D = _tabs.get(sprite)
	if t != null:
		draw_texture(t, _rect(key, "cat_tabs").position)
