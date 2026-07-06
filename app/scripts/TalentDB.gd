extends Node
## Autoload singleton: loads the real-talent pool (the season-keyed easter-egg roster
## curated by tools/talent_ingest.py). Mirrors GameDB's search order:
##   res://data/talent_pool.json  - the committed pool
##   user://talent_pool.json      - side-loaded onto the device (also: delete to disable)
## Absent or invalid on every path = the feature is OFF and the port is untouched --
## `talents` stays empty, Career's injection loop no-ops, saves carry an empty ledger.

var talents: Array = []
var active: bool = false
var loaded_path: String = ""


func _ready() -> void:
	_load()


func _load() -> void:
	for path in ["res://data/talent_pool.json", "user://talent_pool.json"]:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("TalentDB: %s is not a valid talent pool object" % path)
			continue
		var pool: Variant = (parsed as Dictionary).get("talents", [])
		if not (pool is Array):
			push_warning("TalentDB: %s carries no talents array" % path)
			continue
		talents = []
		for e in (pool as Array):
			if e is Dictionary and int((e as Dictionary).get("debutYear", 0)) > 0 \
					and int((e as Dictionary).get("id", 0)) >= Talent.TALENT_ID_BASE:
				talents.append(e)
		loaded_path = path
		active = not talents.is_empty()
		return
	# No pool anywhere: silently inert (this is the vanilla-port path, not an error).
	talents = []
	active = false
