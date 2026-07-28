extends SceneTree
## Render MAN-TO-MAN MARKINGS in the three WITNESSED states for the render-diff
## (`tools/re/diff_mantoman_parity.py`):
##
##   bolton   -> screenshots/parity-run-2026-07-16/orig/66_mantoman_match.png
##               Bolton W. vs Aston Villa, nothing assigned
##   manutd   -> screenshots/original-walkthrough-2026-07-02/058_162622.png
##               Manchester Utd. vs F.C. Barcelona, nothing assigned
##   assigned -> screenshots/original-walkthrough-2026-07-02/063_162631.png
##               the same career after two commits: Pallister -> Rivaldo and
##               Cole -> Guardiola, with Pallister's row still selected
##
## Every player comes out of the SHIPPED game_db (GameDB), looked up by the exact
## name the frame prints, so nothing about the roster is typed in by hand — the
## only thing this harness asserts is WHICH ten the original fielded and in what
## order, which is what the frames show.
##
##   DISPLAY=:1 PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_mantoman.gd

const BOLTON := 59
const VILLA := 45
const UNITED := 40
const BARCA := 1000

# The ten outfielders each frame lists, in the frame's own row order.
const XI := {
	BOLTON: ["Bergsson", "Whitlow", "Fish", "Thompson", "Frandsen", "Phillips",
		"Johansen", "Blake", "Holdsworth", "Gunnlaugsson"],
	VILLA: ["Nelson", "Wright", "Southgate", "Ehiogu", "Staunton", "Draper",
		"Taylor", "Yorke", "Milosevic", "Collymore"],
	UNITED: ["Gary Neville", "Irwin", "Berg", "Pallister", "Butt", "Beckham",
		"Sheringham", "Cole", "Giggs", "Solskjaer"],
	BARCA: ["Reiziger", "Abelardo", "Guardiola", "F. Couto", "Sergi", "Figo",
		"Luis Enrique", "Anderson", "Giovanni", "Rivaldo"],
}

# The header band each frame carries (both are the same preseason state).
const HDR := {"mode": "manager", "top": "MWM", "weekday": "Friday", "day": 1,
	"month": "August", "year": 1997, "status_top": "Preseason",
	"status_bottom": "Preparation"}

var _db: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIPPED: needs a rendering driver, not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	var win := get_root()
	win.size = Vector2i(640, 480)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(640, 480)
	win.add_child(bg)

	_db = win.get_node_or_null("GameDB")
	if _db == null:
		_db = load("res://scripts/GameDB.gd").new()
		_db.name = "GameDB"
		win.add_child(_db)
		await process_frame
	for _i in 40:
		if not _db.clubs.is_empty():
			break
		await process_frame
	assert(not _db.clubs.is_empty(), "GameDB never loaded")

	var scr: ManToManScreen = load("res://scenes/ManToManScreen.gd").new()
	scr.size = Vector2(640, 480)
	win.add_child(scr)

	scr.setup(BOLTON, _xi_of(BOLTON), VILLA, "Aston Villa", _xi_of(VILLA), [],
		[79, 198], _hdr(BOLTON, "Bolton W"))
	await _shot(win, "%s/mantoman_bolton.png" % dir)

	scr.setup(UNITED, _xi_of(UNITED), BARCA, "F.C. Barcelona", _xi_of(BARCA), [],
		[79, 198], _hdr(UNITED, "Manchester Utd."))
	await _shot(win, "%s/mantoman_manutd.png" % dir)

	# frame 064: Pallister (row 3) marks Rivaldo (opp row 9 -> slot 11) and Cole
	# (row 7) marks Guardiola (opp row 2 -> slot 4); Pallister stays selected.
	var marks := [0, 0, 0, 11, 0, 0, 0, 4, 0, 0]
	scr.setup(UNITED, _xi_of(UNITED), BARCA, "F.C. Barcelona", _xi_of(BARCA), marks,
		[79, 198], _hdr(UNITED, "Manchester Utd."))
	scr._sel = 3
	scr.queue_redraw()
	await _shot(win, "%s/mantoman_assigned.png" % dir)

	print("MANTOMAN shots -> %s" % dir)
	quit(0)


func _hdr(club_id: int, club: String) -> Dictionary:
	var h := HDR.duplicate()
	h["club_id"] = club_id
	h["bottom"] = club
	return h


## The ten outfielders in the frame's order, as ManToManScreen.setup wants them
## (slot 0 = the goalkeeper, which this screen never lists).
func _xi_of(club_id: int) -> Array:
	var club: Dictionary = _db.club(club_id)
	assert(not club.is_empty(), "GameDB has no club %d" % club_id)
	var by_name := {}
	for p in club.get("players", []):
		by_name[str(p.get("name", ""))] = p
	var out: Array = [{}]
	for n in XI[club_id]:
		assert(by_name.has(n), "club %d has no player named %s" % [club_id, n])
		out.append(by_name[n])
	return out


func _shot(win: Window, path: String) -> void:
	for _i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	win.get_texture().get_image().save_png(path)
