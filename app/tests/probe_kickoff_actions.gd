extends SceneTree

# Probe: confirm the port parks every player at its DECIDE action (keeper 0x1e / outfield 0)
# and never reassigns to a resolve-capable action -> phase stays 2. Root-cause confirmation.
# Lineup/session helpers copied verbatim from run_full_match.gd.

const Pm98Match := preload("res://scripts/Pm98Match.gd")
const Pm98Driver := preload("res://scripts/Pm98Driver.gd")
const Pm98CollBuilder := preload("res://scripts/Pm98CollBuilder.gd")
const MatchEngine := preload("res://scripts/MatchEngine.gd")

func _rec(role: int, shirt: int, px: int, py: int) -> Dictionary:
	return {
		0x4: shirt, 0x8: px, 0xc: py, 0x10: px, 0x14: py,
		0x18: px, 0x1c: py, 0x20: px, 0x24: py,
		0x28: 0, 0x2c: 11, 0x30: 11,
		0x34: 60, 0x35: 60, 0x36: 60, 0x37: 60, 0x38: 60,
		0x3c: 60, 0x3d: 60, 0x3e: 60, 0x3f: 60, 0x40: 65, 0x41: 60,
		0x42: 40, 0x44: role, 0x98: 0,
	}

func _lineup(team: int) -> Dictionary:
	var slots: Array = []
	var sgn := 1 if team == 0 else -1
	var rows := [
		[1, -45, 0],
		[2, -30, -20], [3, -30, -7], [4, -30, 7], [5, -30, 20],
		[6, -5, -22], [7, -5, -7], [8, -5, 7], [9, -5, 22],
		[10, 15, -10], [11, 15, 10],
	]
	for i in range(11):
		var r: Array = rows[i]
		slots.append(_rec(int(r[0]), team * 100 + i + 1, int(r[1]) * sgn * 0x10000, int(r[2]) * 0x10000))
	return {"header": [0, 0, 0, 0, 0, 0, 0, 0, 0], "slots": slots}

func _session() -> Dictionary:
	return {
		0x4c: 0x680000, 0x50: 0x440000,
		0xfd0: 0, 0xfd4: 0, 0xfd8: 0, 0xfdc: 0, 0xff4: 0,
		0xfa0: 1, 0xfe8: 0, 0xfec: 0, 0xff0: 0,
		0x14: 0, 0x20: 0, 0x24: 0, 0x44: 0, 0x48: 0,
	}

func _init() -> void:
	var rng := MatchEngine.Pm98Rng.new(1)
	var m: Dictionary = Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = _lineup(0)
	(m["sim"][1] as Dictionary)[0x9c] = _lineup(1)
	Pm98Match.kickoff_init(m, _session(), rng)

	# snapshot actions right after kickoff_init (tick 0) and after 1, 5, 30 ticks
	for checkpoint in [0, 1, 5, 30]:
		while _ticks_done < checkpoint:
			Pm98Driver.tick(m, rng)
			_ticks_done += 1
		_report(m, checkpoint)
	print("DONE")
	quit()

var _ticks_done := 0

func _report(m: Dictionary, t: int) -> void:
	var ph: int = Pm98Driver._g(m, 0x448)
	var seen := {}
	var act_by_team := [[], []]
	for s in range(2):
		for p in (m["sim"][s] as Dictionary).get("players", []):
			var a: int = Pm98Driver._g(p as Dictionary, 0x40)
			seen[a] = int(seen.get(a, 0)) + 1
			act_by_team[s].append(a)
	print("t=%-3d phase=%d  distinct_actions=%s  team0=%s" % [t, ph, str(seen), str(act_by_team[0])])
