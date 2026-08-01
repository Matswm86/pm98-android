extends SceneTree
## The barra's MANAGER-MODE panel is furniture + the club's OWN NANOESC kit, for EVERY
## club -- not Manchester Utd's whole captured panel for him and a bare kit for everyone
## else. That fallback was the single biggest parity bucket in the port (649 px per frame
## on the EURO GROUP and all fourteen KNOCKOUT cases); it is 14 px now.
##
## Guards the three things that can silently undo it:
##   1. `art/kits/header/panel.png` ships and is transparent exactly in the kit well;
##   2. the panel + Man Utd's own nano kit reproduces his captured panel at 0 px, which is
##      what proves the composition is the original's (`kits/header/40.png` is the frame cut);
##   3. every screen that draws this barra goes through `PMChrome.draw_manager_panel`, so a
##      fourth copy of the old club-40-only branch cannot creep back in.

const PANEL := "res://art/kits/header/panel.png"
const CUT := "res://art/kits/header/40.png"
const MAN_UTD := 40
const NANO_LOCAL := Vector2i(6, 7)   # HDR_MGR_NANO_XY - HDR_MGR_PATCH_XY

var _fail := 0


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  PASS  %s" % what)
	else:
		_fail += 1
		print("  FAIL  %s" % what)


func _init() -> void:
	print("test_manager_panel")
	_check(ResourceLoader.exists(PANEL), "%s ships" % PANEL)
	_check(ResourceLoader.exists(CUT), "%s (the witness cut) ships" % CUT)
	if _fail:
		quit(1)
		return

	var panel: Image = (load(PANEL) as Texture2D).get_image()
	var cut: Image = (load(CUT) as Texture2D).get_image()
	_check(panel.get_size() == cut.get_size(),
		"panel is the cut's size (%s)" % str(panel.get_size()))

	var nano: Texture2D = PMChrome.nano_kit(MAN_UTD)
	_check(nano != null, "Man Utd's nano kit loads")
	if nano == null:
		quit(1)
		return
	var ni: Image = nano.get_image()

	# The well is open exactly where BOTH witness careers' kits occlude the panel. Where
	# only Man Utd's kit covers, the second career (Bolton W) saw the furniture and the
	# baker put it back -- those pixels are opaque ON PURPOSE, and they are what a club
	# with a narrower silhouette than Man Utd's gets to stand on.
	var bolton: Texture2D = PMChrome.nano_kit(59)
	_check(bolton != null, "Bolton W's nano kit loads")
	if bolton == null:
		quit(1)
		return
	var bi: Image = bolton.get_image()
	var well_open := 0
	var recovered := 0
	var wrong := 0
	for y in ni.get_height():
		for x in ni.get_width():
			if ni.get_pixel(x, y).a <= 0.0:
				continue
			var px := x + NANO_LOCAL.x
			var py := y + NANO_LOCAL.y
			if px >= panel.get_width() or py >= panel.get_height():
				continue
			var both: bool = x < bi.get_width() and y < bi.get_height() \
				and bi.get_pixel(x, y).a > 0.0
			if panel.get_pixel(px, py).a <= 0.0:
				well_open += 1
				if not both:
					wrong += 1        # Bolton saw it; it should not have been punched out
			elif both:
				wrong += 1            # nothing witnessed it; it must not be painted
			else:
				recovered += 1
	_check(wrong == 0,
		"the well is open exactly where both careers occlude (%d wrong)" % wrong)
	_check(well_open > 300, "the well is the real kit shape (%d px)" % well_open)
	_check(recovered > 0,
		"%d px under Man Utd's kit were recovered from the second career" % recovered)

	# Composition: panel over the cut's own club must reproduce the cut exactly.
	var comp := Image.create(panel.get_width(), panel.get_height(), false, Image.FORMAT_RGBA8)
	comp.blend_rect(panel, Rect2i(Vector2i.ZERO, panel.get_size()), Vector2i.ZERO)
	comp.blend_rect(ni, Rect2i(Vector2i.ZERO, ni.get_size()), NANO_LOCAL)
	var diff := 0
	for y in comp.get_height():
		for x in comp.get_width():
			var c := comp.get_pixel(x, y)
			var w := cut.get_pixel(x, y)
			if c.a <= 0.0 and w.a <= 0.0:
				continue
			if c.a <= 0.0 or w.a <= 0.0:
				diff += 1
			elif c.r8 != w.r8 or c.g8 != w.g8 or c.b8 != w.b8:
				diff += 1
	_check(diff == 0, "panel + Man Utd nano == his captured panel (%d px differ)" % diff)

	# Nobody keeps a private copy of the old club-40-only branch.
	for path in ["res://scenes/ResultsScreen.gd", "res://scenes/KnockoutScreen.gd",
			"res://scenes/EuroGroupScreen.gd"]:
		var src := FileAccess.get_file_as_string(path)
		_check(src.find("kits/header/40.png") == -1,
			"%s does not hard-code the Man Utd cut" % path.get_file())
		_check(src.find("PMChrome.draw_manager_panel") != -1,
			"%s draws the shared manager panel" % path.get_file())

	if _fail:
		print("test_manager_panel: %d FAIL" % _fail)
		quit(1)
	else:
		print("test_manager_panel: ALL PASS")
		quit(0)
