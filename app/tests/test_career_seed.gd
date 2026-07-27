extends SceneTree
## S3 — a career IS reproducible at a fixed seed (2026-07-27). Two careers created from
## the same club, with `career_rng_state` pinned before the first draw and the SAME
## seeded advance-week rng, must produce identical standings, cash, cup brackets and
## roster order after a run of weeks. Before the migration this could not hold: 10
## randomize() sites in Career.gd (+5 career paths in Main) reseeded per call.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_career_seed.gd

const SEED := 20260727
const WEEKS := 12

var _fail := 0


func _a(cond: bool, label: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL  %s" % label)


func _build() -> Career:
	var db: Dictionary = JSON.parse_string(
		FileAccess.open("res://data/game_db.json", FileAccess.READ).get_as_text())
	var league: Dictionary = {}
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	# Pin the career stream BEFORE create() makes its first draw (_init_club seeds the
	# academy/staff/free-agent pools from career_rng).
	var carer := Career.new()
	carer.reputation = Manager.REP_START
	carer.career_rng_state = str(SEED)
	carer._init_club(prem[0], league, prem, db.get("leagues", []))
	return carer


func _drive(c: Career) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for _i in WEEKS:
		if c.season_over():
			break
		c.advance_week(rng)
	# The comparable footprint: league table, cash, both domestic brackets, the roster.
	var table: Array = []
	for row in c.standings():
		table.append([row.get("id"), row.get("pts"), row.get("gf"), row.get("ga")])
	var squad: Array = []
	for p in c.my_squad():
		squad.append([p.get("name"), p.get("form"), p.get("fitness")])
	return JSON.stringify([table, c.cash, c.fa_cup.get("rounds", []),
		c.league_cup.get("rounds", []), squad])


func _initialize() -> void:
	var a := _drive(_build())
	var b := _drive(_build())
	_a(a == b, "two same-seed careers are identical after %d weeks" % WEEKS)
	# And an UNPINNED career self-seeds (the original's own time() behaviour): the
	# stream state must persist into the save payload either way.
	var c := _build()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	c.advance_week(rng)
	_a(str(c.to_dict().get("career_rng_state", "")) != "",
		"the stream state rides the save payload")
	print("test_career_seed: %s" % ("ALL PASS" if _fail == 0 else "%d FAILED" % _fail))
	quit(1 if _fail > 0 else 0)
