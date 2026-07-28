class_name GroundPreset
extends RefCounted

## GROUND starting-grade presets — MANAGER.EXE `FUN_0057d780` @0x0057d780, read off the
## binary's own jump table (disassembled 2026-07-28, `objdump -d --start-address=0x57d780`).
##
## The ground ctor takes `club+0x50` (the club's COMPETITION INDEX, computed by
## `FUN_0057a180` — see `docs/re/stadium_screen_re.md` §"`club+0x50` — REVERSED") as arg3
## and writes the club's STARTING facility / service / car-park grades from it:
##
##     0057d799  xor al,al
##     0057d79b  cmp edx,3                 ; edx = club+0x50
##     0057d79e  mov [ecx+0x2a],al         ; HEATING   = 0 for EVERY index
##     0057d7a1  mov [ecx+0x3f],0x32
##     0057d7a5  mov [ecx+0x2f],al         ; CLUB SHOP = 0 for EVERY index
##     0057d7a8  ja  0057d830              ; index > 3 -> ret, NOTHING else written
##     0057d7ae  jmp [edx*4+0x57d834]      ; table: 57d7b5 / 57d7e1 / 57d80b / 57d80b
##
## so index 2 and index 3 SHARE one arm (both all-zero), and any index above 3 — every
## foreign club, which `FUN_0057a180` numbers 7..12 — gets no write at all and keeps the
## ctor's zeros. The four car-park quadrants are `ground+0x25..0x28`, the nine
## facility/service grades are `ground+0x29..0x31` in the GROUND ledger's own order.
##
## WITNESSED 2026-07-28 (`tools/re/refs/lowdiv-2026-07-28/`), which is what binds the
## index to the division — the last thing this file was waiting on:
##   * Manchester Utd. (Premier)      -> preset 0: FLOODLIGHTS 1.000.000 K.W. (2),
##     CHANGING ROOMS MEDIUM (1), SCORE BOARD VIDEO-WALL (2)   [captured 2026-07-23]
##   * Birmingham C   (First Div.)    -> preset 1: FLOODLIGHTS 500.000 K.W. (1),
##     CHANGING ROOMS BASIC (0), SCORE BOARD ELECTRONIC (1)
##   * Barnet         (Third Div.)    -> preset 2/3: FLOODLIGHTS NONE (0),
##     CHANGING ROOMS BASIC (0), SCORE BOARD MANUAL (0)
## Presets 2 and 3 are the same bytes in the binary, so Second vs Third is not
## observable — and does not need to be: both seed identically.

## `ground+0x29..0x31`, the nine grades in ledger order:
## FLOODLIGHTS, HEATING, CHANGING ROOMS, SCORE BOARD, ACCESS, MEDICAL, CLUB SHOP,
## CAFES, TOILETS.
const GRADES := {
	0: [2, 0, 1, 2, 1, 1, 0, 2, 2],   # 0057d7b5
	1: [1, 0, 0, 1, 0, 0, 0, 1, 1],   # 0057d7e1
	2: [0, 0, 0, 0, 0, 0, 0, 0, 0],   # 0057d80b
	3: [0, 0, 0, 0, 0, 0, 0, 0, 0],   # 0057d80b (shared arm)
}

## `ground+0x25..0x28`, the four car-park quadrants (NE NW SE SW).
const CAR_PARK := {
	0: [1, 1, 1, 1],
	1: [0, 0, 0, 0],
	2: [0, 0, 0, 0],
	3: [0, 0, 0, 0],
}

## `ground+0x3e` (0x32 for preset 0, 0x19 for 1/2/3; untouched above index 3).
const PITCH_3E := {0: 0x32, 1: 0x19, 2: 0x19, 3: 0x19}

## Above index 3 the ctor's zeros stand — the same nine zeros as presets 2/3.
const ZERO_GRADES := [0, 0, 0, 0, 0, 0, 0, 0, 0]

## `FUN_0057a180`'s scan order for the four English competitions (entries 0..3). Foreign
## clubs fall into its SECOND scan (entries 7..12) and so land above 3.
const LEAGUE_INDEX := {
	"eng_prem": 0,
	"eng_div1": 1,
	"eng_div2": 2,
	"eng_div3": 3,
}
const FOREIGN_INDEX := 7


## The club's `club+0x50`. `league_id` is game_db's `leagueId` (null / "" for the 384
## directory-only foreign clubs, which the binary numbers 7..12).
static func competition_index(league_id: String) -> int:
	return int(LEAGUE_INDEX.get(league_id, FOREIGN_INDEX))


## The nine starting grades for a competition index (ledger order, see GRADES).
static func grades(index: int) -> Array:
	return (GRADES[index] as Array).duplicate() if GRADES.has(index) else ZERO_GRADES.duplicate()


## The four starting car-park quadrant levels for a competition index.
static func car_park(index: int) -> Array:
	return (CAR_PARK[index] as Array).duplicate() if CAR_PARK.has(index) else [0, 0, 0, 0]


## Convenience: the nine starting grades straight from a game_db `leagueId`.
static func grades_for_league(league_id: String) -> Array:
	return grades(competition_index(league_id))


# ---------------------------------------------------------------------------------------
# The per-item TEMPLATE — the game's own strings, not per-club data.
#
# Each item's grade LABELS are fixed strings in MANAGER.EXE, identical for every club: the
# 2026-07-28 drive re-witnessed six of the nine on a First Division club (Birmingham C) and
# three on a Third Division club (Barnet) against the 2026-07-23 Man Utd capture, and every
# label set matched character for character. `cost_key` is the GroundCost / FUN_0057ddd0
# category; `ledger` is the WORK IN PROGRESS row label; `icon` is the detail-card sprite.
# The nine are in the ledger's own order, which is also `ground+0x29..0x31`.
const FACILITY_ITEMS := [
	{"item": "FLOODLIGHTS", "grades": ["NONE", "500.000 K.W.", "1.000.000 K.W.", "1.500.000 K.W."],
		"cost_key": "floodlights", "ledger": "FLOODLIGHTS", "icon": "floodlights"},
	{"item": "UNDER-SOIL HEATING", "grades": ["NO", "YES"],
		"cost_key": "under_soil_heating", "ledger": "HEATING", "icon": "heating"},
	{"item": "CHANGING ROOMS", "grades": ["BASIC", "MEDIUM", "COMPLETE"],
		"cost_key": "changing_rooms", "ledger": "CHANG. ROOMS", "icon": "chgrooms"},
	{"item": "SCORE BOARD", "grades": ["MANUAL", "ELECTRONIC", "VIDEO-WALL"],
		"cost_key": "score_board", "ledger": "SCORE BOARD", "icon": "scoreboard"},
	{"item": "ACCESS TO THE STADIUM", "grades": ["BASIC", "MEDIUM", "WIDE"],
		"cost_key": "access_to_the_stadium", "ledger": "ACCESS", "icon": "access"},
]
const SERVICE_ITEMS := [
	{"item": "MEDICAL EQUIPMENT", "grades": ["BASIC", "COMPLETE", "I.C.U."],
		"cost_key": "medical_equipment", "ledger": "SICKROOM", "icon": "medical"},
	{"item": "CLUB SHOP", "grades": ["NONE", "SMALL", "MEDIUM", "LARGE"],
		"cost_key": "club_shop", "ledger": "CLUB SHOPS", "icon": "clubshop"},
	{"item": "CAFES", "grades": ["SMALL", "MEDIUM", "LARGE", "VERY LARGE"],
		"cost_key": "cafes", "ledger": "CAFES", "icon": "cafes"},
	{"item": "TOILETS", "grades": ["10 W.C.", "20 W.C.", "40 W.C.", "80 W.C."],
		"cost_key": "toilets", "ledger": "TOILETS", "icon": "toilets"},
]

## Index into the nine-grade vector: FACILITIES occupy 0..4, SERVICES 5..8.
const SERVICE_GRADE_OFFSET := 5


## The full GROUND item table for ONE club, for `cat` in ("facilities" | "services").
##
## Every field is the original's own: the labels are MANAGER.EXE's fixed strings, `current`
## is `FUN_0057d780`'s preset for the club's competition index, and `cost` / `weeks` are
## `FUN_0057ddd0`'s own price for the NEXT grade at the club's stature band (`GroundCost`,
## which reproduces all 20 witnessed Man Utd prices and — new on 2026-07-28 — Barnet's three
## SEATS cards and Birmingham C's £200,000 / 4-week floodlight upgrade).
##
## `band` is the club's stature band (`Career.band_of`, the port's `club+0x58`). At the top
## grade the original shows £0 / 0 weeks, which is exactly what the witnesses print, so that
## is what an exhausted item returns.
static func items(cat: String, league_id: String, band: int) -> Array:
	var templates: Array = SERVICE_ITEMS if cat == "services" else FACILITY_ITEMS
	var grade_vec := grades_for_league(league_id)
	var base := SERVICE_GRADE_OFFSET if cat == "services" else 0
	var out: Array = []
	for i in templates.size():
		var t: Dictionary = templates[i]
		var labels: Array = t["grades"]
		var current: int = clampi(int(grade_vec[base + i]), 0, labels.size() - 1)
		var cost := 0
		var weeks := 0
		if current + 1 < labels.size():
			var q := GroundCost.quote(str(t["cost_key"]), band, current + 1)
			cost = int(q["gbp"])
			weeks = int(q["weeks"])
		out.append({
			"item": t["item"], "grades": labels.duplicate(), "current": current,
			"cost": cost, "weeks": weeks, "ledger": t["ledger"], "icon": t["icon"],
		})
	return out
