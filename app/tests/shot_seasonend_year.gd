extends SceneTree
## Render the three season-end screens against the real MANAGER.EXE frames they were baked
## from (REFRUN R15, Manchester Utd. 1997-98). Every value fed here is the ORIGINAL's own,
## read off those frames, so each shot must land on the frame's own pixels.
##
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_seasonend_year.gd

## THE CHAMPIONSHIPS, in the sheet's own slot order (left column then right).
## The four right-hand slots carry a second score; the frame shows the F.A. Cup and the
## U.E.F.A. Cup with only one, because neither needed a replay or a second leg.
const CHAMPIONSHIPS := [
	{"home": {"club": "Manchester Utd.", "club_id": -1, "scores": [1], "won": true},
	 "away": {"club": "Chelsea", "club_id": -1, "scores": [0], "won": false}},
	{"home": {"club": "Real Madrid C.F.", "club_id": -1, "scores": [2], "won": true},
	 "away": {"club": "Parma", "club_id": -1, "scores": [1], "won": false}},
	{"home": {"club": "AEK Atenas", "club_id": -1, "scores": [1], "won": true},
	 "away": {"club": "Sturm Graz", "club_id": -1, "scores": [0], "won": false}},
	{"home": {"club": "Borussia D.", "club_id": -1, "scores": [2], "won": true},
	 "away": {"club": "Cruzeiro", "club_id": -1, "scores": [0], "won": false}},
	{"home": {"club": "Newcastle Utd", "club_id": -1, "scores": [2], "won": true},
	 "away": {"club": "Barnsley", "club_id": -1, "scores": [1], "won": false}},
	{"home": {"club": "Inter", "club_id": -1, "scores": [0], "won": false},
	 "away": {"club": "Arsenal", "club_id": -1, "scores": [1], "won": true}},
	{"home": {"club": "F.C. Barcelona", "club_id": -1, "scores": [2, 3], "won": true},
	 "away": {"club": "Borussia D.", "club_id": -1, "scores": [0, 0], "won": false}},
	{"home": {"club": "Southampton", "club_id": -1, "scores": [2, 1], "won": false},
	 "away": {"club": "Arsenal", "club_id": -1, "scores": [2, 2], "won": true}},
]

## END OF SEASON, all four divisions exactly as the frame prints them.
const OVERVIEW := {
	1: {"champion": {"club": "Blackburn R.", "club_id": -1},
		"runner_up": {"club": "Arsenal", "club_id": -1},
		"mid": [{"club": "Liverpool"}, {"club": "Aston Villa"},
			{"club": "Manchester Utd."}, {"club": "Chelsea"}],
		"relegated": [{"club": "Southampton"}, {"club": "Sheffield W."},
			{"club": "Everton"}]},
	2: {"champion": {"club": "Birmingham C", "club_id": -1}, "runner_up": {},
		"mid": [{"club": "Birmingham C"}, {"club": "Bradford City"},
			{"club": "Manchester C"}],
		"relegated": [{"club": "Bury"}, {"club": "Reading"}, {"club": "Stockport C"}]},
	3: {"champion": {"club": "Southend Utd", "club_id": -1}, "runner_up": {},
		"mid": [{"club": "Southend Utd"}, {"club": "Grimsby T"}, {"club": "Preston NE"}],
		"relegated": [{"club": "Blackpool"}, {"club": "Bristol Rovers"},
			{"club": "Carlisle U."}, {"club": "Bristol City"}]},
	4: {"champion": {"club": "Notts C.", "club_id": -1}, "runner_up": {},
		"mid": [{"club": "Notts C."}, {"club": "Scunthorpe U."},
			{"club": "Swansea City"}, {"club": "Cambridge U."}],
		"relegated": []},
}

## PLAYERS OF THE YEAR, the frame's own PREMIER LEAGUE page: twenty clubs alphabetically
## down column 1 then column 2.
const PLAYERS := {
	1: [
		{"club": "Arsenal", "player": "Wright"},
		{"club": "Aston Villa", "player": "Yorke"},
		{"club": "Barnsley", "player": "Ward"},
		{"club": "Blackburn R.", "player": "Henchoz"},
		{"club": "Bolton W", "player": "Gunnlaugsson"},
		{"club": "Chelsea", "player": "Petrescu"},
		{"club": "Coventry", "player": "Williams"},
		{"club": "Crystal Pal.", "player": "Gordon"},
		{"club": "Derby County", "player": "Baiano"},
		{"club": "Everton", "player": "Ferguson"},
		{"club": "Leeds Utd", "player": "Hasselbaink"},
		{"club": "Leicester", "player": "Marshall"},
		{"club": "Liverpool", "player": "Fowler"},
		{"club": "Manchester Utd.", "player": "Solskjaer"},
		{"club": "Newcastle Utd", "player": "Barnes"},
		{"club": "Sheffield W.", "player": "Whittingham"},
		{"club": "Southampton", "player": "Palmer"},
		{"club": "Tottenham H", "player": "Ferdinand"},
		{"club": "West Ham Utd", "player": "Dicks"},
		{"club": "Wimbledon", "player": "Gayle"},
	],
}


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	await _shoot(load("res://scenes/ChampionshipsScreen.gd").new(),
		func(n: Variant) -> void: n.setup(CHAMPIONSHIPS), dir, "championships.png")
	await _shoot(load("res://scenes/EndOfSeasonScreen.gd").new(),
		func(n: Variant) -> void: n.setup(OVERVIEW), dir, "endofseason.png")
	await _shoot(load("res://scenes/PlayersYearScreen.gd").new(),
		func(n: Variant) -> void: n.setup(PLAYERS, 1), dir, "players_year.png")
	print("wrote %s/{championships,endofseason,players_year}.png" % dir)
	quit(0)


func _shoot(node: Control, feed: Callable, dir: String, name: String) -> void:
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)
	feed.call(node)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
	node.queue_free()
	await process_frame
