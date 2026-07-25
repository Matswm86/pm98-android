extends Control
class_name CharityShieldScreen
## PM98 CAMPEON card -- the shared champion-card layout every trophy is presented on
## (charter #4, audit C1 #9). Frame-baked from the witnessed originals
## (parity-run-2026-07-16/orig/70_after_ft.png == promanager 11, CAMPEON family).
##
## ONE LAYOUT, SIX WITNESSED TROPHIES. The reference run caught five competitions on
## this exact card at a 0.99-1.00 pixel-signature match, and a sixth came off the
## European drive (docs/re/REFRUN_manutd_1997-98.md R7/R11/R14/R15). The title plate,
## the trophy render and the backdrop are per-competition art, so each has its own
## baked chrome (tools/re/build_champion_cards_from_frames.py); everything else --
## panel, RUNNER-UP label, OK button, every text baseline -- is shared and verified
## byte-identical across all six before the bake transfers its blanking zones.
##
## NOT witnessed and therefore NOT drawn: PREMIER LEAGUE, EUROPEAN CUP and CUP
## WINNER'S CUP. `has_card()` returns false for those, and the caller skips the card
## rather than showing an invented one.
## Chrome = the real frame with ONLY the winner/runner-up kits + name lines
## restored to the card's own texture (build_seasonflow_chrome_from_frames.py).
## Live draw: winner club "(on penalties)" (light grey 220s), winner manager
## (white), runner-up club + manager (pale blue 166,202,240), both clubs' kits
## via PMChrome.draw_crest (the game's own kit art, scaled -- the original's
## hi-res card kits are un-extracted; documented approximation). OK emits done.

signal ok_pressed

const W := 640
const H := 480

const C_WINNER := Color8(220, 220, 220)
const C_WINNER_MGR := Color8(255, 255, 255)
const C_RUNNER := Color8(166, 202, 240)
const BTN_OK := Rect2(84, 338, 60, 26)
const KIT_WINNER := Rect2(68, 116, 62, 80)
const KIT_RUNNER := Rect2(68, 246, 62, 80)
const TXT_X := 147
const WINNER_BASE := 163
const WINNER_MGR_BASE := 178
const RUNNER_BASE := 286
const RUNNER_MGR_BASE := 303

## Competition key -> baked chrome. Keys match Career's own competition keys.
const CHROME := {
	"charity_shield": "res://art/screens/seasonflow/shield.png",
	"intercontinental": "res://art/screens/seasonflow/card_intercontinental.png",
	"coca_cola": "res://art/screens/seasonflow/card_coca_cola.png",
	"uefa_cup": "res://art/screens/seasonflow/card_uefa_cup.png",
	"fa_cup": "res://art/screens/seasonflow/card_fa_cup.png",
	"supercup": "res://art/screens/seasonflow/card_supercup.png",
}

## Is this competition's card art witnessed? False -> the caller must NOT raise a card.
static func has_card(comp: String) -> bool:
	return CHROME.has(comp)


var _chrome: Texture2D
var _f12: Font
var _f8: Font
var _comp := "charity_shield"
var _winner: Dictionary = {}   # {club, manager, club_id, pens: bool}
var _runner: Dictionary = {}
var _press := false


func _ready() -> void:
	_load_chrome()
	_f12 = PMChrome.font("12")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## winner/runner: {club, manager, club_id} plus, on the winner, either `pens: true`
## or the original's own result `qualifier` string (witnessed: " (on penalties)").
## `comp` picks the trophy; an unwitnessed key keeps the Charity Shield chrome, so
## callers must gate on has_card() first.
func setup(winner: Dictionary, runner: Dictionary, comp := "charity_shield") -> void:
	_winner = winner
	_runner = runner
	_comp = comp
	_load_chrome()
	queue_redraw()


func _load_chrome() -> void:
	var path := str(CHROME.get(_comp, CHROME["charity_shield"]))
	_chrome = load(path)


func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = BTN_OK.has_point(d)
		queue_redraw()
		return
	var was := _press
	_press = false
	queue_redraw()
	if was and BTN_OK.has_point(d):
		ok_pressed.emit()


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	if not _winner.is_empty():
		PMChrome.draw_crest(self, int(_winner.get("club_id", -1)), KIT_WINNER)
		# The card's name field is "%s%s" % [club, qualifier] -- witnessed as
		# `Lyon (on penalties)` on the U.E.F.A. CUP CHAMPION card (REFRUN R14).
		var line := PMChrome.title_case_name(str(_winner.get("club", "?")))
		var qual := str(_winner.get("qualifier", ""))
		if qual == "" and bool(_winner.get("pens", false)):
			qual = " (on penalties)"
		line += qual
		_txt(_f12, TXT_X, WINNER_BASE, line, C_WINNER, 13)
		_txt(_f8, TXT_X, WINNER_MGR_BASE, PMChrome.title_case_name(str(_winner.get("manager", ""))),
			C_WINNER_MGR, 11)
	if not _runner.is_empty():
		PMChrome.draw_crest(self, int(_runner.get("club_id", -1)), KIT_RUNNER)
		_txt(_f12, TXT_X, RUNNER_BASE, PMChrome.title_case_name(str(_runner.get("club", "?"))),
			C_RUNNER, 13)
		_txt(_f8, TXT_X, RUNNER_MGR_BASE, PMChrome.title_case_name(str(_runner.get("manager", ""))),
			C_RUNNER, 11)
	if _press:
		draw_rect(BTN_OK, Color(1, 1, 1, 0.2), true)


func _txt(f: Font, x: int, baseline: int, t: String, col: Color, sz: int) -> void:
	if f != null and t != "":
		draw_string(f, Vector2(x, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
