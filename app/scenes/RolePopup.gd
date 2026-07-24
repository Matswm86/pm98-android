extends Control
class_name RolePopup
## PM98 TACTICS **ROLE** picker — the popup MANAGER.EXE raises when the POS-column
## arrow of an XI row is clicked (`FUN_0056a1d0` at 0x56a1d0; the pick is applied by
## `FUN_0056a560`, which writes `player[+0x18] = item_id - 0x58`).
##
## Chrome is the real game's own frame, baked with the text blanked
## (tools/re/build_role_popup_from_frame.py, entry-flow doctrine); this scene draws
## only the surname and the 18 role names in their per-player inks.
##
## The colour rule IS the "plausible roles" model, and it is binary-exact:
##   * `player[+0x1d]`      — his NATURAL role  -> GOLD  (the EXE pushes 0x0000dfff)
##   * `player[+0x1e..+22]` — five ALTERNATIVES -> WHITE (0x00ffffff)
##   * everything else keeps the default black ink.
## Both fields come straight out of EQUIPOS.PKF: `posFine` and `posAlts`
## (tools/re/equipos_parse.py `fineAlts`, docs/re/positions_re.md). The list itself is
## always all 18 roles — the original does not hide the ones he cannot play, it paints
## the ones he CAN. Witness: Bergsson (Bolton) shows RIGHT BACK gold and INSIDE CENTRE
## LEFT + INSIDE CENTRE RIGHT white, which is exactly his stored [2] + [5, 6].
##
## Signal: `role_picked(pid, pos_fine)` with `pos_fine` 1-based (the app's posFine
## space, = the engine byte + 1). Tapping outside the popup dismisses it.

signal role_picked(pid: int, pos_fine: int)
signal dismissed

const W := 640
const H := 480

const C_NATURAL := Color8(255, 223, 0)
const C_ALTERNATE := Color8(255, 255, 255)
const C_OTHER := Color8(0, 0, 0)

var _spec: Dictionary = {}
var _chrome: Texture2D
var _f8: Font
var _feuro: Font

var _pid := -1
var _name := ""
var _natural := 0          # 1-based posFine, 0 = unknown
var _alts: Array = []      # 1-based posFine values


func _ready() -> void:
	_chrome = load("res://art/screens/tactics/rolepopup_chrome.png")
	var f := FileAccess.open("res://art/screens/tactics/rolepopup.json", FileAccess.READ)
	if f != null:
		var j: Variant = JSON.parse_string(f.get_as_text())
		if j is Dictionary:
			_spec = j
	_f8 = PMChrome.font("8")
	_feuro = load("res://art/fonts/euro8.fnt") if ResourceLoader.exists("res://art/fonts/euro8.fnt") else _f8
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(player: Dictionary) -> void:
	_pid = int(player.get("id", -1))
	_name = PMChrome.title_case_name(str(player.get("name", "")))
	# `posNatural` is the engine's +0x1d, kept by Career.set_player_role the first time a
	# role is reassigned; before any reassignment it IS posFine.
	_natural = int(player.get("posNatural", player.get("posFine", 0)))
	_alts = []
	for a in player.get("posAlts", []):
		var v := int(a)
		if v >= 1 and v <= 18:
			_alts.append(v)
	queue_redraw()


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func popup_rect() -> Rect2:
	var r: Array = _spec.get("popup", [220, 87, 200, 277])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


## The 1-based posFine under a design point, or 0.
func role_at(d: Vector2) -> int:
	var r := popup_rect()
	var y0 := int(_spec.get("item_y0", 112))
	var pitch := int(_spec.get("item_pitch", 14))
	var ih := int(_spec.get("item_h", 12))
	for i in int(_spec.get("n_items", 18)):
		if Rect2(r.position.x, float(y0 + pitch * i), r.size.x, float(ih)).has_point(d):
			return i + 1
	return 0


## Ink for role index `i` (0-based) under the binary's own rule.
func ink_for(i: int) -> Color:
	if i + 1 == _natural:
		return C_NATURAL
	if _alts.has(i + 1):
		return C_ALTERNATE
	return C_OTHER


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	if PMChrome.is_emulated_pointer_dup(e):
		return
	if not e.pressed:
		return
	var d := _to_design(e.position)
	if not popup_rect().has_point(d):
		dismissed.emit()
		return
	var role := role_at(d)
	if role > 0:
		role_picked.emit(_pid, role)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	var r := popup_rect()
	if _chrome != null:
		draw_texture(_chrome, r.position)
	# surname, white, ink-centred on the bar (GDI floor centring)
	var cx := float(_spec.get("title_cx", 319))
	var tw := _f8.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	PMChrome.text(self, _f8, floorf(cx - tw * 0.5), float(int(_spec.get("title_ink_y", 96)) - 2),
		_name, C_ALTERNATE, 11)
	var y0 := int(_spec.get("item_y0", 112))
	var pitch := int(_spec.get("item_pitch", 14))
	var tx := float(_spec.get("item_text_x", 251))
	var dy := int(_spec.get("item_ink_dy", 2))
	for i in TacticsBoardScreen.FINE_ROLE_LONG.size():
		PMChrome.text(self, _feuro, tx, float(y0 + pitch * i + dy - 2),
			TacticsBoardScreen.FINE_ROLE_LONG[i], ink_for(i), 11)
