extends Node
## Autoload singleton: loads the PM98 game database (leagues + clubs + players).
##
## Load order (first that exists wins):
##   res://data/game_db.json    - the full real database (1997-98 clubs/players),
##                                built by tools/build_db.py from the owned game files
##                                and committed so the app ships the real game.
##   user://game_db.json        - side-loaded by the owner onto the device.
##   res://data/sample_db.json  - tiny synthetic fallback so the app always runs.

signal database_loaded

var meta: Dictionary = {}
var leagues: Array = []
var clubs: Array = []
var clubs_by_id: Dictionary = {}
var loaded_path: String = ""
var is_sample: bool = false


func _ready() -> void:
	_load()


func _load() -> void:
	for path in ["res://data/game_db.json", "user://game_db.json", "res://data/sample_db.json"]:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("GameDB: %s is not a valid database object" % path)
			continue
		meta = parsed.get("meta", {})
		leagues = parsed.get("leagues", [])
		clubs = parsed.get("clubs", [])
		clubs_by_id.clear()
		for c in clubs:
			clubs_by_id[int(c["id"])] = c
		_apply_loader_defaults()
		_apply_real_managers()
		loaded_path = path
		is_sample = path.ends_with("sample_db.json")
		database_loaded.emit()
		return
	push_error("GameDB: no database file found on any search path")


## The engine's own load-time record defaults (FUN_005820f0; docs/re/SPEC_BINDING.md
## birthYear/age row, tools/re/equipos_parse.py header). The original never surfaces a
## blank age/height/weight — the loader substitutes at load, per record, with rand():
##   birth year outside 1901..1985 -> age 25 + rand(0..4)   (@0x58228a)
##   height byte < 150cm           -> 170 + rand(0..9) cm    (@0x5822e6)
##   weight byte < 20kg            -> 75 + rand(0..9) kg     (@0x5822e6)
## The extractor exports exactly those cases as JSON null (extract_squads_exact.py:138),
## so null here == "engine substitutes". Applied to the loaded records only — never
## baked into game_db.json (SPEC_BINDING: "never baked").
func _apply_loader_defaults() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for c in clubs:
		for p in c.get("players", []):
			if p.get("age") == null:
				p["age"] = 25 + rng.randi_range(0, 4)
			if p.get("heightCm") == null:
				p["heightCm"] = 170 + rng.randi_range(0, 9)
			if p.get("weightKg") == null:
				p["weightKg"] = 75 + rng.randi_range(0, 9)


## Fill the empty `manager` field from the source-true transcription table
## (data/real_managers_1997.json: witnessed START OF SEASON / TEAMS IN
## CHAMPIONSHIPS frames — English manager data is not in EQUIPOS.PKF). Clubs
## absent from the table keep null and render an honest blank.
func _apply_real_managers() -> void:
	if not FileAccess.file_exists("res://data/real_managers_1997.json"):
		return
	var f := FileAccess.open("res://data/real_managers_1997.json", FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var table: Dictionary = parsed.get("managers", {})
	for c in clubs:
		if c.get("manager") == null and table.has(str(c.get("name", ""))):
			c["manager"] = str(table[str(c.get("name", ""))])


func season() -> String:
	return meta.get("season", "?")


func clubs_in_league(league_id: String) -> Array:
	var out: Array = []
	for c in clubs:
		if c.get("leagueId") == league_id:
			out.append(c)
	return out


## EQUIPOS ships one squadless no-league container record ("Free players",
## EQ961382 — the engine's out-of-contract pool, country byte 22/SPAIN,
## stadium "Tokyo"). It is data, not a browsable club: the original never
## lists it on any country surface, so every country query skips empty
## no-league records here (the only such record in the 476).
func _is_placeholder(c: Dictionary) -> bool:
	return (c.get("players", []) as Array).is_empty()


func countries() -> Array:
	## Distinct countries among clubs with no league (the international set), sorted.
	var seen: Dictionary = {}
	for c in clubs:
		if c.get("leagueId") == null and not _is_placeholder(c):
			var ctry: Variant = c.get("country")
			if ctry != null:
				seen[ctry] = true
	var out: Array = seen.keys()
	out.sort()
	return out


func clubs_in_country(country: String) -> Array:
	var out: Array = []
	for c in clubs:
		if c.get("leagueId") == null and c.get("country") == country and not _is_placeholder(c):
			out.append(c)
	return out


func club(club_id: int) -> Dictionary:
	return clubs_by_id.get(club_id, {})
