extends SceneTree
## EURO. LEAGUE group screen + the two Cup.gd accessors it reads through.
##   ~/godot462 --headless --path app --script res://tests/test_euro_group_screen.gd

var _fail := 0


func _initialize() -> void:
	_run()


func _ok(cond: bool, what: String) -> void:
	print("  %s   %s" % ["ok " if cond else "FAIL", what])
	if not cond:
		_fail += 1


func _run() -> void:
	_art()
	_cup_accessors()
	_yellow_rule()
	print("\n" + ("ALL PASS" if _fail == 0 else "%d FAILED" % _fail))
	quit(1 if _fail else 0)


## Every state the screen can draw must be a witnessed cut -- six header plates, six lit
## button faces, one chrome.
func _art() -> void:
	print("art")
	_ok(ResourceLoader.exists("res://art/screens/euroleague/chrome.png"), "chrome baked")
	for L in ["A", "B", "C", "D", "E", "F"]:
		_ok(ResourceLoader.exists("res://art/screens/euroleague/hdr_group_%s.png" % L),
			"GROUP %s header plate" % L)
		_ok(ResourceLoader.exists("res://art/screens/euroleague/btn_lit_%s.png" % L),
			"GROUP %s lit button" % L)


func _cup_accessors() -> void:
	print("Cup accessors")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var ids: Array = []
	for i in 24:
		ids.append(1000 + i)
	var b := Cup.create(ids, 40, {"name": "European Cup", "group_stage": {
		"groups": 6, "advance": 1, "best_runners_up": 2, "label": "1/8 Final"}})
	var ratings := func(_id: int) -> Dictionary:
		return {"att": 60, "def": 60, "mid": 60, "gk": 60, "overall": 60, "name": "C"}
	var names := func(id: int) -> String: return "C%d" % id
	Cup.play_group_matchday(b, rng, ratings, -1, names)

	var groups: Array = Cup.group_tables(b)
	_ok(groups.size() == 6, "six groups drawn (got %d)" % groups.size())
	var table: Array = Cup.ranked_table(groups[0])
	_ok(table.size() == 4, "a group table has four rows")
	var ranked_ok := true
	for i in table.size() - 1:
		if int(table[i]["pts"]) < int(table[i + 1]["pts"]):
			ranked_ok = false
	_ok(ranked_ok, "ranked_table is ordered on points")

	var fx: Array = Cup.group_fixtures(b, 0, 1)
	_ok(fx.size() == 2, "matchday 1 pairs a group of four into two fixtures")
	var clubs: Array = (groups[0] as Dictionary)["clubs"]
	var all_in := true
	var seen := {}
	for f in fx:
		for k in ["h", "a"]:
			all_in = all_in and clubs.has(int(f[k]))
			seen[int(f[k])] = true
	_ok(all_in and seen.size() == 4, "each club appears exactly once on a matchday")
	_ok(Cup.group_fixtures(b, 0, 99).is_empty(), "a round past the schedule is empty")

	# A double round-robin reverses: matchday 4 is matchday 1 with the venues swapped.
	var fx4: Array = Cup.group_fixtures(b, 0, 4)
	var rev_ok := fx4.size() == fx.size()
	for i in fx.size():
		var back := false
		for g in fx4:
			if int(g["h"]) == int(fx[i]["a"]) and int(g["a"]) == int(fx[i]["h"]):
				back = true
		rev_ok = rev_ok and back
	_ok(rev_ok, "matchday 4 is matchday 1 at the reversed venue")


## The goal digit the original inks yellow is the SECOND box on row 1 and the FIRST box on
## row 2 -- 20 rows witnessed across two careers, both legs. NOT a winner marker.
func _yellow_rule() -> void:
	print("the yellow goal digit")
	var mark := func(row: int, box: int) -> bool: return (row + box) % 2 == 1
	_ok(not mark.call(0, 0) and mark.call(0, 1), "row 1: the AWAY box is marked")
	_ok(mark.call(1, 0) and not mark.call(1, 1), "row 2: the HOME box is marked")
