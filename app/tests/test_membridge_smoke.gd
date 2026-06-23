extends SceneTree
## Smoke + invariant test for the Mem-from-clubs bridge (Pm98StatMatch.build_mem /
## simulate_fixture), the port of FUN_0044d5f0. Not an emulator oracle (the bridge
## reads game_db, which the binary never sees) -- it checks the verified attr map
## (STR=avg(VE,RE,AG,CA), GKSAVE=PO, PASS=PA), that real squads simulate without
## crashing, and that strength ordering behaves (a strong XI beats a weak one over
## many sims). RE map: docs/re/stat_match_engine_re.md.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_membridge_smoke.gd

var _fail := 0
var _pass := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", msg)


func _load_db() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	assert(f != null, "game_db.json missing")
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## A complete-ish XI: the highest-PO GK in slot 0, then 10 outfielders (DF/MF/FW) by
## a balanced overall. Returns up to 11 game_db player dicts, slot 0 = GK.
func _xi(club: Dictionary) -> Array:
	var players: Array = club.get("players", [])
	var gks: Array = []
	var out: Array = []
	for p in players:
		var a: Variant = p.get("attrs", {})
		if not (a is Dictionary) or (a as Dictionary).is_empty():
			continue
		if p.get("isGK"):
			gks.append(p)
		else:
			out.append(p)
	gks.sort_custom(func(x, y): return int(x["attrs"].get("PO", 0)) > int(y["attrs"].get("PO", 0)))
	out.sort_custom(func(x, y):
		var sx: int = int(x["attrs"].get("CA", 0)) + int(x["attrs"].get("VE", 0))
		var sy: int = int(y["attrs"].get("CA", 0)) + int(y["attrs"].get("VE", 0))
		return sx > sy)
	var xi: Array = []
	xi.append(gks[0] if gks.size() > 0 else (out[0] if out.size() > 0 else null))
	for i in range(10):
		xi.append(out[i] if i < out.size() else null)
	return xi


func _init() -> void:
	var db := _load_db()
	var clubs: Array = db.get("clubs", [])
	# pick two clubs with dense squads
	var dense: Array = []
	for c in clubs:
		var n := 0
		for p in c.get("players", []):
			if (p.get("attrs", {}) is Dictionary) and not (p["attrs"] as Dictionary).is_empty():
				n += 1
		if n >= 14:
			dense.append(c)
		if dense.size() >= 4:
			break
	_ok(dense.size() >= 2, "need >=2 dense clubs, got %d" % dense.size())
	if dense.size() < 2:
		_report(); return

	var home: Dictionary = dense[0]
	var away: Dictionary = dense[1]
	var xi_h := _xi(home)
	var xi_a := _xi(away)

	# --- attr-map invariant: a Mem's participant fields match the verified map -----
	var mem := Pm98StatMatch.build_mem(xi_h, xi_a, int(home["id"]), int(away["id"]))
	var gk: Dictionary = xi_h[0]
	var ga: Dictionary = gk["attrs"]
	var pb0 := Pm98StatMatch._player(0, 0)
	var exp_str: int = (int(ga.get("VE", 0)) + int(ga.get("RE", 0)) + int(ga.get("AG", 0)) \
			+ int(ga.get("CA", 0))) >> 2
	_ok(mem.u8(pb0 + Pm98StatMatch.STR) == exp_str, "GK STR=avg(VE,RE,AG,CA)")
	_ok(mem.u8(pb0 + Pm98StatMatch.GKSAVE) == mini(int(ga.get("PO", 0)) + 10, 99), "GK GKSAVE=PO+10")
	_ok(mem.u8(pb0 + Pm98StatMatch.PASS) == int(ga.get("PA", 0)), "GK PASS=PA")
	_ok(mem.s32(pb0 + Pm98StatMatch.ROLE) == 0, "GK ROLE=0")
	_ok(mem.u16(pb0 + Pm98StatMatch.SEL) == 1, "GK SEL=slot+1")
	# an outfielder (slot 1): GKSAVE has NO +10, PASS=PA, ROLE in {1,2,3}
	var o1: Dictionary = xi_h[1]
	var oa: Dictionary = o1["attrs"]
	var pb1 := Pm98StatMatch._player(0, 1)
	_ok(mem.u8(pb1 + Pm98StatMatch.GKSAVE) == int(oa.get("PO", 0)), "outfield GKSAVE=PO (no +10)")
	_ok(mem.u8(pb1 + Pm98StatMatch.PASS) == int(oa.get("PA", 0)), "outfield PASS=PA")
	_ok(mem.s32(pb1 + Pm98StatMatch.ROLE) in [1, 2, 3], "outfield ROLE in {1,2,3}")

	# --- runs without crashing, plausible scoreline over many seeds ---------------
	var max_goals := 0
	var total_goals := 0
	for seed in range(200):
		var r := Pm98StatMatch.simulate_fixture(0x1000 + seed * 0x3779, xi_h, xi_a, \
				int(home["id"]), int(away["id"]))
		var hg: int = r["home_goals"]
		var ag2: int = r["away_goals"]
		_ok(hg >= 0 and ag2 >= 0 and hg <= 20 and ag2 <= 20, "sane score %d-%d" % [hg, ag2])
		max_goals = maxi(max_goals, hg + ag2)
		total_goals += hg + ag2
	_ok(max_goals >= 1, "at least one goal scored across 200 sims")
	var avg := float(total_goals) / 200.0
	print("  info: avg goals/match = %.2f, max in a match = %d" % [avg, max_goals])

	# --- strength ordering: a maxed XI beats a floored XI over many sims ----------
	var strong: Array = []
	var weak: Array = []
	for i in range(11):
		strong.append({"pos": ("GK" if i == 0 else "FW"),
			"isGK": i == 0,
			"attrs": {"VE": 95, "RE": 95, "AG": 95, "CA": 95, "RM": 95, "RG": 95,
				"PA": 95, "TI": 95, "EN": 95, "PO": 95}})
		weak.append({"pos": ("GK" if i == 0 else "DF"),
			"isGK": i == 0,
			"attrs": {"VE": 20, "RE": 20, "AG": 20, "CA": 20, "RM": 20, "RG": 20,
				"PA": 20, "TI": 20, "EN": 20, "PO": 20}})
	var strong_wins := 0
	var weak_wins := 0
	for seed in range(300):
		var r := Pm98StatMatch.simulate_fixture(0x55 + seed * 0x9e37, strong, weak, 0x7, 0x13)
		if r["home_goals"] > r["away_goals"]:
			strong_wins += 1
		elif r["away_goals"] > r["home_goals"]:
			weak_wins += 1
	print("  info: strong %d wins vs weak %d wins (of 300)" % [strong_wins, weak_wins])
	_ok(strong_wins > weak_wins, "strong XI wins more than weak XI")

	_report()


func _report() -> void:
	print("test_membridge_smoke: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
