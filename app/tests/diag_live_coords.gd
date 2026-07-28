extends SceneTree
## Coordinate-space probe for the M5 WIRE-IN: run the positional engine on real career data
## and report the observed range of the player (+0x4/+0x8) and ball (+0x4/+0x8/+0xc) fields
## against the session pitch dims (+0x4c/+0x50), so the view can map engine units -> pitch
## without guessing the fixed-point scale.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_live_coords.gd

const HOME_ID := 40
const AWAY_ID := 42
const FRAMES := 4000


func _init() -> void:
	var rng := MatchEngine.Pm98Rng.new(1)
	var data := Pm98LineupFeeder.load_data()
	var input := Pm98LineupFeeder.build(HOME_ID, AWAY_ID, data)
	var m := Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = (input["lineups"] as Array)[0]
	(m["sim"][1] as Dictionary)[0x9c] = (input["lineups"] as Array)[1]
	Pm98Match.kickoff_init(m, input["session"], rng)

	var sess: Dictionary = input["session"]
	print("pitch session +0x4c=%d (>>16 = %d)  +0x50=%d (>>16 = %d)" % [
		int(sess[0x4c]), int(sess[0x4c]) >> 16, int(sess[0x50]), int(sess[0x50]) >> 16])

	var lo := [1 << 62, 1 << 62, 1 << 62]
	var hi := [-(1 << 62), -(1 << 62), -(1 << 62)]
	var blo := [1 << 62, 1 << 62, 1 << 62]
	var bhi := [-(1 << 62), -(1 << 62), -(1 << 62)]
	var ball: Dictionary = Pm98Driver._ball(m)
	for t in FRAMES:
		Pm98Outer.step(m, rng)
		for ti in 2:
			for p in ((m["sim"][ti] as Dictionary).get("players", []) as Array):
				var v := [_si(p, 4), _si(p, 8), _si(p, 0xc)]
				for k in 3:
					lo[k] = mini(lo[k], v[k])
					hi[k] = maxi(hi[k], v[k])
		var b := [_si(ball, 4), _si(ball, 8), _si(ball, 0xc)]
		for k in 3:
			blo[k] = mini(blo[k], b[k])
			bhi[k] = maxi(bhi[k], b[k])
		if int(m.get(0x1a38, 0)) == 10:
			break

	print("players x [%d .. %d]  y [%d .. %d]  z [%d .. %d]" % [lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]])
	print("ball    x [%d .. %d]  y [%d .. %d]  z [%d .. %d]" % [blo[0], bhi[0], blo[1], bhi[1], blo[2], bhi[2]])
	print("goal x (+0x1820) = %d ; half-pitch words +0x1824=%d" % [
		_si(m, 0x1820), _si(m, 0x1824)])
	var sample: Array = (m["sim"][0] as Dictionary).get("players", [])
	if not sample.is_empty():
		var p0: Dictionary = sample[0]
		print("sample GK: x=%d y=%d z=%d  role+0x2c8=%d shirt+0x2b4=%d" % [
			_si(p0, 4), _si(p0, 8), _si(p0, 0xc), int(p0.get(0x2c8, -1)), int(p0.get(0x2b4, -1))])
	quit(0)


func _si(d: Dictionary, off: int) -> int:
	return Pm98Trig._i32(int(d.get(off, 0)))
