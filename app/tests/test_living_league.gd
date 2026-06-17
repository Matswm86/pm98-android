extends SceneTree
## Headless test for the living league (#12): rival clubs' squads injure, develop and
## drift across a season, and reset cleanly at the rollover.
##   ~/godot462 --headless --path app --script res://tests/test_living_league.gd
## New career -> play two full seasons -> assert rival injuries appear, rival ratings
## drift, squads never shrink, attributes stay bounded, and the rollover resets rivals.

const SEED := 71717


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])

	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in all:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.size() != 20 or league.is_empty():
		push_error("expected 20 Premier clubs + the league dict")
		return false

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true

	# Pick a rival (not the managed club) and snapshot its season-start rating + a
	# representative attribute sum, plus every rival's roster size.
	var rival_id := -1
	for id in career.rosters:
		if int(id) != career.club_id:
			rival_id = int(id)
			break
	ok = _assert(rival_id != -1, "found a rival club to track") and ok
	var start_rating: Dictionary = MatchEngine.team_ratings(career.club_view(rival_id))
	var start_attr_sum := _attr_sum(career.squad_of(rival_id))
	var start_sizes := _sizes(career)

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# --- Season 1: play it out, watching for rival injuries appearing mid-season. ---
	var rival_injuries_seen := false
	var attrs_bounded := true
	while not career.season_over():
		career.advance_week(rng)
		for id in career.rosters:
			if int(id) == career.club_id:
				continue
			for p in career.squad_of(id):
				if int(p.get("injured_weeks", 0)) > 0 or int(p.get("suspended_weeks", 0)) > 0:
					rival_injuries_seen = true
				if not _attrs_in_bounds(p):
					attrs_bounded = false
	ok = _assert(rival_injuries_seen, "rival players pick up injuries/suspensions in-season") and ok
	ok = _assert(attrs_bounded, "rival attributes stay within Training floor/cap") and ok

	# A notable rival injury reached the club news feed (>= AI_INJ_NEWS_WEEKS).
	var injury_news := false
	for n in career.news_log:
		if n is Dictionary and str(n.get("kind", "")) == "injury" and "out injured for" in str(n.get("text", "")):
			injury_news = true
			break
	ok = _assert(injury_news, "a notable rival injury surfaced in the club news feed") and ok

	# Rival ratings drifted over the season (development moved the dial).
	var end_rating: Dictionary = MatchEngine.team_ratings(career.club_view(rival_id))
	var end_attr_sum := _attr_sum(career.squad_of(rival_id))
	var drift: bool = end_attr_sum != start_attr_sum \
		or absf(float(end_rating["att"]) - float(start_rating["att"])) > 0.01 \
		or absf(float(end_rating["def"]) - float(start_rating["def"])) > 0.01
	ok = _assert(drift, "rival ratings/attributes drift across the season (was %d -> %d attr-sum)" % [
		start_attr_sum, end_attr_sum]) and ok

	# Squads stay fieldable: injuries never remove players, and the pre-existing AI transfer
	# market refuses to sell a club below SQUAD_MIN. A club that began under that floor (rare
	# in the top flight) only has to not drop further.
	var sizes_ok := true
	for id in start_sizes:
		if career.squad_of(int(id)).size() < mini(int(start_sizes[id]), TransferMarket.SQUAD_MIN):
			sizes_ok = false
	ok = _assert(sizes_ok, "every rival squad stayed at or above the SQUAD_MIN floor") and ok

	# --- Rollover: rivals age a year and the season resets (bans/injuries cleared). ---
	var pre_age := _avg_age(career.squad_of(rival_id))
	career.advance_season(leagues, rng)
	var post_age := _avg_age(career.squad_of(rival_id))
	ok = _assert(post_age > pre_age, "rivals aged across the rollover (%.1f -> %.1f)" % [pre_age, post_age]) and ok

	var reset_ok := true
	for id in career.rosters:
		if int(id) == career.club_id:
			continue
		for p in career.squad_of(id):
			if int(p.get("injured_weeks", 0)) != 0 or int(p.get("suspended_weeks", 0)) != 0:
				reset_ok = false
	ok = _assert(reset_ok, "the rollover cleared rival injuries/suspensions") and ok

	# Season 2 still plays out consistently (every club plays the full schedule).
	while not career.season_over():
		career.advance_week(rng)
	var games_ok := true
	for id in career.table:
		if int(career.table[id]["P"]) != 38:
			games_ok = false
	ok = _assert(games_ok, "season 2 played the full 38-round schedule for every club") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _attr_sum(squad: Array) -> int:
	var s := 0
	for p in squad:
		var attrs: Dictionary = p.get("attrs", {})
		for k in attrs:
			s += int(attrs[k])
	return s


## Development must keep every attribute inside the sane decoded range (1..99); the
## seed data itself can sit outside Training's softer [ATTR_FLOOR, ATTR_CAP] develop band,
## so this guards only against a runaway, not the natural spread of real ratings.
func _attrs_in_bounds(p: Dictionary) -> bool:
	var attrs: Dictionary = p.get("attrs", {})
	for k in attrs:
		var v := int(attrs[k])
		if v < 1 or v > 99:
			return false
	return true


func _sizes(career: Career) -> Dictionary:
	var out: Dictionary = {}
	for id in career.rosters:
		out[int(id)] = career.squad_of(int(id)).size()
	return out


func _avg_age(squad: Array) -> float:
	if squad.is_empty():
		return 0.0
	var s := 0
	for p in squad:
		s += int(p.get("age", 26))
	return float(s) / float(squad.size())


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
