extends SceneTree
## Headless test for the decoded MO/FITNESS/RATING model (docs/re/morale_re.md).
##   ~/godot462 --headless --path app --script res://tests/test_morale.gd
## Locks the constants RE'd or PCode-emulated out of MANAGER.EXE: the damped
## mutators (FUN_00584cc0/60), season init (FUN_005825c0), the RATING formula
## (FUN_00581e60) against the walkthrough frames, the post-match slot deltas
## (FUN_00582690), the emulated result-delta matrix (FUN_004179a0), the weekly
## league-position ceiling (FUN_00418030) and the new-signing jealousy
## (FUN_00588ae0). Pure over dicts — no GameDB.

func _initialize() -> void:
	quit(0 if _run() else 1)


var _ok := true

func _assert(cond: bool, label: String) -> void:
	print("  %s  %s" % ["ok " if cond else "[FAIL]", label])
	_ok = _ok and cond


func _run() -> bool:
	_mutators()
	_season_init()
	_rating_vs_frames()
	_post_match()
	_result_matrix()
	_ceiling()
	_jealousy()
	print("MORALE: %s" % ("ALL GREEN" if _ok else "FAILURES ABOVE"))
	return _ok


# Damped mutator: negatives soften when low, positives land full, clamp 40..99.
func _mutators() -> void:
	# Full hit at high morale (>=75): -10 lands full.
	var p := {"morale": 90}
	Morale.add(p, -10)
	_assert(p["morale"] == 80, "high-morale negative lands full (90-10=80)")
	# Three-quarters band (50..74): -8 -> -6.
	p = {"morale": 60}
	Morale.add(p, -8)
	_assert(p["morale"] == 54, "mid-morale negative x3/4 (60 + trunc(-24/4)=54)")
	# Halved band (<50): -8 -> -4.
	p = {"morale": 44}
	Morale.add(p, -8)
	_assert(p["morale"] == 40, "low-morale negative halved then floored (44-4=40)")
	# Positive always full; hard cap 99.
	p = {"morale": 95}
	Morale.add(p, 10)
	_assert(p["morale"] == 99, "positive caps at 99")
	# Floor 40.
	p = {"morale": 41}
	Morale.add(p, -20)
	_assert(p["morale"] == 40, "morale floors at 40")
	# Fitness shares the curve.
	p = {"fitness": 99}
	Morale.fitness_add(p, -8)
	_assert(p["fitness"] == 91, "fitness high negative lands full (99-8=91)")


# FUN_005825c0: morale 90 + rand(10) in [90,99]; fitness halfway toward 40.
func _season_init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var lo := 100
	var hi := 0
	for i in 200:
		var p := {"morale": 0, "fitness": 99}
		Morale.season_init(p, rng)
		lo = mini(lo, int(p["morale"]))
		hi = maxi(hi, int(p["morale"]))
		if i == 0:
			_assert(int(p["fitness"]) == 70, "fresh 99 fitness re-inits to 70 (frames 081/084)")
	_assert(lo >= 90 and hi <= 99 and hi >= 95, "season morale stays in [90,99] (got %d..%d)" % [lo, hi])


# FUN_00581e60 = (VE+RE+AG+CA+FITNESS+MORALE)/6, confirmed vs walkthrough frames.
func _rating_vs_frames() -> void:
	# Van der Gouw (game_db attrs) FI 70 MO 94 -> 80 (frame 081).
	var vdg := {"attrs": {"VE": 81, "RE": 79, "AG": 79, "CA": 80}, "fitness": 70, "morale": 94}
	_assert(Morale.av6(vdg) == 80, "RATING Van der Gouw = 80 (frame 081)")
	# Solskjaer FI 70 MO 90 -> 82 (frame 084).
	var ole := {"attrs": {"VE": 87, "RE": 83, "AG": 81, "CA": 84}, "fitness": 70, "morale": 90}
	_assert(Morale.av6(ole) == 82, "RATING Solskjaer = 82 (frame 084)")
	# Taylor FI 67 MO 81 -> 85 (make-offer frame 101).
	var tay := {"attrs": {"VE": 98, "RE": 95, "AG": 79, "CA": 92}, "fitness": 67, "morale": 81}
	_assert(Morale.av6(tay) == 85, "RATING Taylor = 85 (frame 101)")
	# Thornley FI 67 MO 85 -> 79 (team-offer frame 086).
	var tho := {"attrs": {"VE": 82, "RE": 81, "AG": 81, "CA": 80}, "fitness": 67, "morale": 85}
	_assert(Morale.av6(tho) == 79, "RATING Thornley = 79 (frame 086)")


# FUN_00582690: played +3/+3; a star (QU>=81) hurts more when left out. The
# negative deltas pass through the DAMPED mutator (FUN_00584cc0), so at morale
# 60 (the 50..74 band, x3/4): -3 -> -2, -2 -> -1, -5 -> -3.
func _post_match() -> void:
	var star := {"attrs": {"CA": 85}, "morale": 60, "fitness": 60}
	Morale.post_match_slot(star, "played")
	_assert(int(star["morale"]) == 63 and int(star["fitness"]) == 63, "played: +3 morale +3 fitness (undamped)")
	var benched := {"attrs": {"CA": 85}, "morale": 60, "fitness": 60}
	Morale.post_match_slot(benched, "bench")
	_assert(int(benched["morale"]) == 58, "star benched: -3 raw -> -2 damped (58)")
	var reserve := {"attrs": {"CA": 70}, "morale": 60, "fitness": 60}
	Morale.post_match_slot(reserve, "bench")
	_assert(int(reserve["morale"]) == 59, "lesser benched: -2 raw -> -1 damped (59)")
	var out := {"attrs": {"CA": 85}, "morale": 60, "fitness": 60}
	Morale.post_match_slot(out, "out")
	_assert(int(out["morale"]) == 57, "star dropped from 16: -5 raw -> -3 damped (57)")


# FUN_004179a0 emulated matrix (docs/re/inventory-evidence/morale_result_delta.json).
func _result_matrix() -> void:
	# Same-division home: W +8, D -2, L -10.
	_assert(Morale.result_delta(true, 0, 0, "W") == 8, "home same-band win +8")
	_assert(Morale.result_delta(true, 0, 0, "D") == -2, "home same-band draw -2")
	_assert(Morale.result_delta(true, 0, 0, "L") == -10, "home same-band loss -10")
	# Same-division away: W +10, D +5, L -4.
	_assert(Morale.result_delta(false, 0, 0, "W") == 10, "away same-band win +10")
	_assert(Morale.result_delta(false, 0, 0, "D") == 5, "away same-band draw +5")
	_assert(Morale.result_delta(false, 0, 0, "L") == -4, "away same-band loss -4")
	# Minnow (band 3) winning away at a giant (band 0) +20; giant losing that at home -24.
	_assert(Morale.result_delta(false, 3, 0, "W") == 20, "band-3 away win at band-0 giant +20")
	_assert(Morale.result_delta(true, 0, 3, "L") == -24, "band-0 giant home loss to band-3 -24")


# FUN_00418030 division-0 ceiling; only after 11 games.
func _ceiling() -> void:
	_assert(Morale.weekly_ceiling(1, 20) == 99, "top-2 ceiling 99")
	_assert(Morale.weekly_ceiling(4, 20) == 70, "3rd-5th ceiling 70")
	_assert(Morale.weekly_ceiling(12, 20) == 30, "11th-15th ceiling 30")
	_assert(Morale.weekly_ceiling(18, 20) == 10, "16th+ ceiling 10")
	_assert(Morale.weekly_ceiling(18, 5) == 99, "no ceiling before 11 games")
	# Over ceiling+8 decays; at/under does not.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var p := {"morale": 90, "attrs": {"CA": 70}}
	Morale.weekly_decay(p, 50, rng)   # 90 > 50+8 -> decay
	_assert(int(p["morale"]) < 90, "morale over ceiling+8 decays")
	var q := {"morale": 55, "attrs": {"CA": 70}}
	Morale.weekly_decay(q, 50, rng)   # 55 <= 58 -> no decay
	_assert(int(q["morale"]) == 55, "morale within ceiling+8 holds")


# FUN_00588ae0: a signed star unsettles the same-position incumbent.
func _jealousy() -> void:
	var newcomer := {"attrs": {"VE": 90, "RE": 90, "AG": 90, "CA": 90}, "posFine": 9, "pos": "MF", "wage": 5000}
	# Comparable same-fine incumbent, out-earned by the newcomer -> -60.
	var inc := {"attrs": {"VE": 88, "RE": 88, "AG": 88, "CA": 88}, "posFine": 9, "pos": "MF", "wage": 2000}
	_assert(Morale.jealousy_delta(inc, newcomer) == -60, "same-fine out-earned incumbent -60")
	# Different position entirely -> no jealousy.
	var other := {"attrs": {"CA": 88}, "posFine": 1, "pos": "GK", "wage": 2000}
	_assert(Morale.jealousy_delta(other, newcomer) == 0, "off-position incumbent unaffected")
