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
		_apply_club_economy()
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
## Merge per-club ECONOMY source data (club_economy.json, exported by
## tools/re/export_club_economy.py) into the club dicts: `budget` (EQUIPOS
## header u32 — starting cash = budget x 5000, live-witnessed 2026-07-19) and
## `objective` (the START OF SEASON board label, all four English divisions
## witnessed). Clubs absent from the file just miss the keys (fallback paths).
func _apply_club_economy() -> void:
	if not FileAccess.file_exists("res://data/club_economy.json"):
		return
	var f := FileAccess.open("res://data/club_economy.json", FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var rows: Dictionary = parsed.get("clubs", {})
	for id_str in rows:
		var c: Dictionary = clubs_by_id.get(int(id_str), {})
		if c.is_empty():
			continue
		var row: Dictionary = rows[id_str]
		c["budget"] = int(row.get("budget", 0))
		if row.has("objective"):
			c["objective"] = str(row["objective"])


func _apply_loader_defaults() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for c in clubs:
		# FUN_005820f0 @0x582434 also knocks every club-0x26e4 (youth pool) record down
		# at load — same function, same pass. Youth.degrade carries the disassembly.
		var is_youth_pool := int(c.get("id", -1)) == Youth.POOL_CLUB_ID
		for p in c.get("players", []):
			if p.get("age") == null:
				p["age"] = 25 + rng.randi_range(0, 4)
			if p.get("heightCm") == null:
				p["heightCm"] = 170 + rng.randi_range(0, 9)
			if p.get("weightKg") == null:
				p["weightKg"] = 75 + rng.randi_range(0, 9)
			if is_youth_pool:
				Youth.degrade(p, rng)


## Fallback only, since 2026-07-27: `manager` now ships DECODED for all 476 clubs.
## It is EQUIPOS' tag-2 side record — the record the parser had always walked and
## skipped as "un-identified" (docs/re/retirement_re.md is a different pass; the decode
## is in tools/re/equipos_parse.py parse_side_record). Cross-check against the 44-row
## transcription table below: 43 agree exactly; the one disagreement is Lincoln C.,
## transcribed "Westley" where EQUIPOS says "Beck" — and John Beck is the 1997-98 man,
## Westley his 1998 successor, so the source wins and the frame was a later one.
## This table therefore fills nothing any more; it stays as a fallback for records
## that ever come through with a null manager, and clubs absent from both render an
## honest blank.
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


## AGE-AT-READ, the binary's own basis: the original never STORES a player's age — it
## computes SEASON-START year − birthYear on every read, off the global season year
## (FUN_00584b50 `mov eax,0x7cd; sub eax,[player+0xfc]`; docs/re/offer_record_re.md:87,
## docs/re/transfer_value_re.md). The port bakes `age` into the record instead, and until
## 2026-08-26 nothing ever re-derived it, so every player outside the manager's live
## division — all 384 foreign clubs included — stayed frozen at his 1997 age forever
## (Aimar at River: 18 in season 2005). Main calls this on career create / load / season
## rollover; every read site keeps reading `age` and the whole world ages. Records whose
## birthYear the extractor nulled keep their loader-substituted age (the binary
## substitutes exactly those). Career rosters hold DEEP COPIES (+1 at rollover, the same
## arithmetic: shipped age == 1997 − birthYear for all 8,600 dated records), untouched.
func stamp_season_ages(start_year: int) -> void:
	for c in clubs:
		for p in c.get("players", []):
			var by: Variant = p.get("birthYear")
			if by != null:
				p["age"] = start_year - int(by)


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
