extends SceneTree
## Headless test for T2 #10 — SCOUT + ASSISTANT MANAGER staff roles. Asserts the roles exist
## with wages + quality helpers, the scout's report surfaces affordable league targets (best
## first, none of your own), and the assistant auto-renews an expiring star at the rollover
## (who would otherwise leave on a free).
##   ~/godot462 --headless --path app --script res://tests/test_staff_roles.gd

const SEED := 7
const HI := 5


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true

	# Roles, wages, quality helpers.
	ok = _assert(Staff.SCOUT in Staff.ROLES and Staff.ASSISTANT in Staff.ROLES,
		"scout + assistant are hireable roles") and ok
	ok = _assert(Staff.wage_for(Staff.SCOUT, 3) > 0 and Staff.wage_for(Staff.ASSISTANT, 3) > 0,
		"both roles carry a wage") and ok
	var scout := {"id": 1, "role": Staff.SCOUT, "quality": 4, "wage": 0}
	var asst := {"id": 2, "role": Staff.ASSISTANT, "quality": HI, "wage": 0}
	ok = _assert(not Staff.has_scout([]) and Staff.has_scout([scout]) and Staff.scout_quality([scout]) == 4,
		"has_scout / scout_quality") and ok
	ok = _assert(Staff.has_assistant([asst]) and Staff.assistant_quality([asst]) == HI,
		"has_assistant / assistant_quality") and ok

	# Career fixtures.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	# SCOUT report: best affordable targets, most able first, none your own.
	var career := Career.create(prem[0], league, prem, leagues)
	ok = _assert(career.scout_targets().is_empty(), "no scout hired -> no report") and ok
	career.staff = [{"id": 1, "role": Staff.SCOUT, "quality": HI, "wage": 0}]
	career.cash = 50_000_000   # afford the dear targets
	var rep := career.scout_targets()
	ok = _assert(rep.size() == HI, "report holds `quality` targets (%d)" % rep.size()) and ok
	var sorted_ca := true
	var own := false
	var afford := true
	for i in rep.size():
		if i > 0 and int(rep[i]["ca"]) > int(rep[i - 1]["ca"]):
			sorted_ca = false
		if int(rep[i]["club_id"]) == career.club_id:
			own = true
		if int(rep[i]["fee"]) > career.cash:
			afford = false
	ok = _assert(sorted_ca and not own and afford,
		"report: most able first, affordable, none of your own") and ok

	# ASSISTANT auto-renews an expiring star (who otherwise leaves on a free).
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var star_id := _expire_a_star(career)
	career.staff = [{"id": 2, "role": Staff.ASSISTANT, "quality": HI, "wage": 0}]
	career.cash = 50_000_000
	career.advance_season(leagues, rng)
	ok = _assert(_in(career.rosters[career.club_id], star_id) and not _in(career.free_agents, star_id),
		"assistant re-signed the expiring star (kept, not freed)") and ok

	# Control: same setup, NO assistant -> the star leaves on a free.
	var ctrl := Career.create(prem[0], league, prem, leagues)
	var ctrl_id := _expire_a_star(ctrl)
	ctrl.staff = []
	ctrl.cash = 50_000_000
	ctrl.advance_season(leagues, RandomNumberGenerator.new())
	ok = _assert(not _in(ctrl.rosters[ctrl.club_id], ctrl_id),
		"with no assistant the expiring star leaves") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


## Force the squad's highest-CA outfielder to be expiring + not auto-renewed; return his id.
func _expire_a_star(career: Career) -> int:
	var best := {}
	for p in career.rosters[career.club_id]:
		if best.is_empty() or int(p.get("attrs", {}).get("CA", 0)) > int(best.get("attrs", {}).get("CA", 0)):
			best = p
	best["contract_years"] = 1
	best["auto_renew"] = false
	return int(best["id"])


func _in(pool: Array, pid: int) -> bool:
	for p in pool:
		if int(p.get("id", -1)) == pid:
			return true
	return false


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
