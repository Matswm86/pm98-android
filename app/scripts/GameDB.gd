extends Node
## Autoload singleton: loads the PM98 game database (leagues + clubs + players).
##
## Load order (first that exists wins):
##   res://data/game_db.json    - the full database, built by tools/build_db.py from
##                                the owned game files. Gitignored (copyright); present
##                                in personal/local builds, absent from the public CI APK.
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
		loaded_path = path
		is_sample = path.ends_with("sample_db.json")
		database_loaded.emit()
		return
	push_error("GameDB: no database file found on any search path")


func season() -> String:
	return meta.get("season", "?")


func clubs_in_league(league_id: String) -> Array:
	var out: Array = []
	for c in clubs:
		if c.get("leagueId") == league_id:
			out.append(c)
	return out


func countries() -> Array:
	## Distinct countries among clubs with no league (the international set), sorted.
	var seen: Dictionary = {}
	for c in clubs:
		if c.get("leagueId") == null:
			var ctry: Variant = c.get("country")
			if ctry != null:
				seen[ctry] = true
	var out: Array = seen.keys()
	out.sort()
	return out


func clubs_in_country(country: String) -> Array:
	var out: Array = []
	for c in clubs:
		if c.get("leagueId") == null and c.get("country") == country:
			out.append(c)
	return out


func club(club_id: int) -> Dictionary:
	return clubs_by_id.get(club_id, {})
