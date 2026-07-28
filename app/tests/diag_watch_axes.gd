extends SceneTree
## Which world axis is the pitch LENGTH, and where do the keepers, the goals and the JUG
## `kind` bytes actually sit? Measured off the byte-exact positional engine, not inferred —
## this is what the 3/4 WATCH camera (`MatchSimulador`) projects, so getting it from a guess
## would poison the whole view.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_watch_axes.gd

const HOME_ID := 40
const AWAY_ID := 42
const FRAMES := 900


func _init() -> void:
	var live := Pm98LiveMatch.create(HOME_ID, AWAY_ID, 1)
	var half := live.pitch_half()
	print("half-length (+0x1820) = %d (%.1f m)   half-width (+0x1824) = %d (%.1f m)" % [
		half.x, half.x / 65536.0, half.y, half.y / 65536.0])

	_report(live, "KICKOFF")
	live.advance(FRAMES)
	_report(live, "FRAME %d" % FRAMES)

	# Every distinct JUG kind the engine actually reaches over this run, with its bank row —
	# the view can only be honest about frames the engine really asks for.
	var kinds := {}
	for f in 40:
		live.advance(60)
		for p in live.player_positions():
			var k := int(p["kind"])
			kinds[k] = int(kinds.get(k, 0)) + 1
	var keys := kinds.keys()
	keys.sort()
	print("kinds seen: ", keys)
	for k in keys:
		var row := JugRender.kind_row(k)
		if row.is_empty():
			print("  kind %d -> NOT IN BANK (%d samples)" % [k, kinds[k]])
		else:
			print("  kind %2d  mode=%3d fpd=%2d base=%4d next=%2d   %d samples" % [
				k, int(row["mode"]), int(row["fpd"]), int(row["base"]), int(row["next"]), kinds[k]])
	print("bank kinds loaded: ", JugRender.kind_count())
	print("metres/px z = %.5f   metres/px x = %.5f" % [
		JugRender.metres_per_pixel_z(), JugRender.metres_per_pixel_x()])
	quit(0)


func _report(live: Pm98LiveMatch, tag: String) -> void:
	var rows: Array = live.player_positions()
	print("--- %s ---" % tag)
	var xs := []
	var ys := []
	for p in rows:
		xs.append(int(p["x"]))
		ys.append(int(p["y"]))
	print("  x [%d .. %d]  (%.1f .. %.1f m)" % [
		xs.min(), xs.max(), xs.min() / 65536.0, xs.max() / 65536.0])
	print("  y [%d .. %d]  (%.1f .. %.1f m)" % [
		ys.min(), ys.max(), ys.min() / 65536.0, ys.max() / 65536.0])
	# slot 0 of each side is the keeper in the port's lineup order: whichever axis separates
	# the two keepers is the axis the GOALS are on, i.e. the pitch LENGTH.
	for p in rows:
		if int(p["slot"]) == 0:
			print("  keeper side %d: x=%.1f m  y=%.1f m  facing=%#06x kind=%d phase=%d" % [
				int(p["side"]), int(p["x"]) / 65536.0, int(p["y"]) / 65536.0,
				int(p["facing"]), int(p["kind"]), int(p["phase"])])
	var b := live.ball_position()
	print("  ball nx=%.3f ny=%.3f h=%.2f m" % [b["nx"], b["ny"], b["height"]])
