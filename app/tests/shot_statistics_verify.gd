extends SceneTree
## Render-verify the LINE-UP -> STATISTICS season table against the ORIGINAL wine
## witness `screenshots/wine-captures-2026-07-24-cadence-season-store/
## 01_season_store_before_7matches.png` — real MANAGER.EXE, TOTAL-level Manchester Utd
## career, 7 matches into 1997-98, the SAME entry point this screen ports (the screen's
## club-squad source path, @0x4b2233).
##
## The witness's own numbers are injected into a Career's `season_stats` /
## `season_club_minutes` / `season_club_mp` exactly as read off the frame — the same
## doctrine as the InsuranceScreen `LIVE` block and the RivalScreen `av` levers. Nothing
## is simulated here: this measures whether the PORT RENDERS the original's table, which
## is a separate question from whether the engine produces those numbers.
##
## DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --path app --rendering-driver opengl3 \
##   -s tests/shot_statistics_verify.gd
func _initialize() -> void:
	_run()


# The witness squad, top to bottom, as the frame lists it: [squadNo, name]. The frame
# carries a live SCROLLBAR, so the squad is longer than the 19 slots it shows;
# "Schmeichel" is the one further member whose numbers the TEAM TOTAL still includes
# (below). He is appended last so the screen's own 19-slot clamp keeps him off-screen,
# exactly as the frame has him.
const SQUAD := [
	[7, "Beckham"], [18, "Scholes"], [4, "May"], [11, "Giggs"], [16, "Keane"],
	[9, "Cole"], [8, "Butt"], [13, "McClair"], [28, "Thornley"], [14, "Jordi Cruyff"],
	[20, "Solskjaer"], [10, "Sheringham"], [19, "Nevland"], [6, "Pallister"],
	[3, "Irwin"], [2, "Gary Neville"], [12, "Phil Neville"], [5, "Johnsen"],
	[21, "Berg"], [1, "Schmeichel"],
]

# Per player, read off the frame at 2.5x zoom: MP, MIN, RATING, MoM, G., SHOTS x/y,
# PASSES x/y, TAC. x/y, S., yellow, red, injury. A missing entry = an all-dashes row.
# The record stores (succeeded, FAILED) while the frame prints succeeded/attempted, so
# every pair below is converted with second = y - x.
#
# Schmeichel's row is NOT printed anywhere; it is the exact residual of the printed TEAM
# TOTAL minus the 19 printed rows (PASSES 319-310 = 9 of 592-537 = 55; TAC 146-146 = 0
# of 443-434 = 9; S. 61-0; yellow 4-3). A keeper's shape, and it is arithmetic off the
# frame rather than a number anyone chose.
const LIVE := {
	"Beckham":      [7, 630, 6, 0, 0, 9, 17, 61, 70, 23, 60, 0, 0, 0, 0],
	"Giggs":        [7, 630, 6, 0, 1, 9, 15, 33, 55, 18, 49, 0, 0, 0, 0],
	"Cole":         [7, 630, 7, 0, 2, 13, 21, 23, 50, 13, 37, 0, 0, 0, 0],
	"Butt":         [7, 630, 6, 0, 0, 10, 14, 41, 79, 18, 46, 0, 0, 0, 0],
	"Solskjaer":    [7, 585, 7, 1, 3, 11, 20, 19, 37, 10, 38, 0, 1, 0, 0],
	"Sheringham":   [7, 630, 8, 3, 3, 12, 20, 32, 47, 18, 42, 0, 0, 0, 0],
	"Pallister":    [7, 540, 7, 0, 1, 2, 2, 25, 52, 8, 35, 0, 2, 0, 0],
	"Irwin":        [7, 630, 6, 0, 0, 3, 3, 31, 57, 11, 45, 0, 0, 0, 0],
	"Gary Neville": [7, 630, 6, 0, 0, 3, 3, 19, 42, 13, 43, 0, 0, 0, 0],
	"Johnsen":      [6, 540, 6, 0, 0, 4, 4, 24, 46, 11, 36, 0, 0, 0, 0],
	"Berg":         [1, 90, 7, 0, 0, 0, 0, 2, 2, 3, 3, 0, 0, 0, 2],
	"Schmeichel":   [7, 630, 4, 0, 0, 0, 0, 9, 55, 0, 9, 61, 1, 0, 0],
}

# TEAM TOTAL, read off the same frame. MP and MIN are the club counters, not sums.
const TOTAL_MP := 7
const TOTAL_MIN := 630
const TOTAL_RATING := 12


## The RATING cell is COMPUTED from the record, and rec+0x08 (the involvement tally) is
## the only input the frame does not print. Solve for the rec+0x08 that reproduces the
## printed rating, exactly as tools/re/verify_statrow_rating.py inverts it — so the
## injected record is the frame's own arithmetic, not a hand-picked number.
func _solve_involve(f: PackedInt32Array, want: int) -> int:
	for inv in range(0, 4000):
		f[Pm98StatStore.R_INVOLVE / 4] = inv
		if Pm98StatStore.rating(f) == want:
			return inv
	return -1


func _record(v: Array) -> PackedInt32Array:
	var f := PackedInt32Array()
	f.resize(Pm98StatStore.REC_DWORDS)
	f[Pm98StatStore.R_MP / 4] = int(v[0])
	f[Pm98StatStore.R_MIN / 4] = int(v[1])
	f[Pm98StatStore.R_MOM / 4] = int(v[3])
	f[Pm98StatStore.R_GOALS / 4] = int(v[4])
	f[Pm98StatStore.R_SHOTS_ON / 4] = int(v[5])
	f[Pm98StatStore.R_SHOTS_OFF / 4] = int(v[6]) - int(v[5])
	f[Pm98StatStore.R_PASS_OK / 4] = int(v[7])
	f[Pm98StatStore.R_PASS_FAIL / 4] = int(v[8]) - int(v[7])
	f[Pm98StatStore.R_TACK_OK / 4] = int(v[9])
	f[Pm98StatStore.R_TACK_FAIL / 4] = int(v[10]) - int(v[9])
	f[Pm98StatStore.R_SAVES / 4] = int(v[11])
	f[Pm98StatStore.R_YELLOW / 4] = int(v[12])
	f[Pm98StatStore.R_RED / 4] = int(v[13])
	f[Pm98StatStore.R_INJURY / 4] = int(v[14])
	var inv := _solve_involve(f, int(v[2]))
	if inv < 0:
		push_error("no rec+0x08 reproduces RATING %d" % int(v[2]))
	f[Pm98StatStore.R_INVOLVE / 4] = maxi(inv, 0)
	return f


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var players: Array = []
	var rows: Array = []
	for i in SQUAD.size():
		var nm: String = SQUAD[i][1]
		players.append({"id": 1000 + i, "squadNo": int(SQUAD[i][0]), "name": nm})
		var f := PackedInt32Array()
		f.resize(Pm98StatStore.REC_DWORDS)
		if LIVE.has(nm):
			f = _record(LIVE[nm])
		rows.append(f)
	var totals := Pm98StatStore.totals(rows, TOTAL_MP, TOTAL_MIN)
	# rec+0x08 is the one input no cell ever prints, so each row's is solved from that
	# row's own printed RATING (the smallest that reproduces it). Those per-row values are
	# under-determined, so their SUM is not the totals row's real +0x08 either -- solve the
	# totals row from its own printed RATING the same way instead of summing.
	var ti := _solve_involve(totals, TOTAL_RATING)
	if ti < 0:
		push_error("no rec+0x08 reproduces the TEAM TOTAL RATING %d" % TOTAL_RATING)
	totals[Pm98StatStore.R_INVOLVE / 4] = maxi(ti, 0)
	print("totals: ", Pm98StatStore.row_cells(totals))

	var scr: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	scr.setup({"id": 40, "name": "Manchester Utd.", "players": players},
		{"mode": "match", "top": "Manchester Utd.", "bottom": "F.C. Barcelona",
			"club_id": 40}, rows, totals)
	for _i in 8:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_statistics_season.png" % dir)
	print("STATISTICS season shot -> %s/shot_statistics_season.png" % dir)
	quit(0)
