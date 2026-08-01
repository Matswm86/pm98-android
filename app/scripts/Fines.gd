extends RefCounted
class_name Fines
## THE FINES (MULTAS) — the board fines the club for a ground that is below the standard
## the competition it just played in demands.
##
## Read out of MANAGER.EXE, not invented: the levy is `FUN_0057a980` @0x57ab85..0x57ad6a
## (the club's POST-MATCH pass, called on BOTH clubs of a finished fixture by
## FUN_00448b60 @0x448dd8/0x448de3/0x448dea), and the card is `FUN_00549d40`, raised by the
## weekly hub run `FUN_00545fd0` @0x546164 the moment any of the five accumulator fields
## `club+0x27c/0x280/0x284/0x288/0x28c` is non-zero. Full record: docs/re/fines_re.md.
##
## Three competition arms, keyed on `DAT_0066b1dc` — the index of the competition the match
## belonged to (0 Premier, 1 First, 2 Second, 3 Third, 4 F.A. Cup, 5 Coca-Cola, 6 Charity
## Shield, 7 U.E.F.A. Cup, 8 Cup Winners' Cup, 9 European Cup, 10 European Supercup,
## 11 Intercontinental Cup; the mapping is each class ctor's own index argument in
## FUN_00441ea0, matched to the class code block that owns its `ACTLIGA\<TAG>%03u.CPT`
## template). Everything outside {0} ∪ {4} ∪ {7..11} falls straight through — the three
## lower divisions, the Coca-Cola Cup and the Charity Shield fine NOTHING, which is a
## RESULT of the `jb`/`ja` bounds at 0x57ac8e/0x57ac97, not an omission here.
##
## The engine holds money at 200 internal units per pound (FinanceModel.MONEY_PER_POUND),
## and each arm's debit (`FUN_00581240`, a float32 immediate) equals the value it banks in
## the accumulator exactly — 0x4A989680 = 5e6, 0x4B189680 = 1e7, 0x4A371B00 = 3e6,
## 0x4B64E1C0 = 1.5e7 — so both columns below are the same bytes read two ways.

## The five ground items a fine can be levied on, in the binary's own field order.
## `grade_cat`/`grade_key` index the port's GroundPreset vector the same way StadiumScreen
## does; `field` is the engine's own accumulator displacement, kept so the doc and the code
## cannot drift apart.
const ITEMS := [
	{"id": "floodlights", "field": 0x27c, "grade_cat": "facilities", "grade_key": 0,
		"icon": "icon_floodlights", "what": "the floodlights"},
	{"id": "changing_rooms", "field": 0x280, "grade_cat": "facilities", "grade_key": 2,
		"icon": "icon_changing_rooms", "what": "the changing rooms"},
	{"id": "score_board", "field": 0x284, "grade_cat": "facilities", "grade_key": 3,
		"icon": "icon_score_board", "what": "the score board"},
	{"id": "access", "field": 0x288, "grade_cat": "facilities", "grade_key": 4,
		"icon": "icon_access", "what": "the access"},
	{"id": "medical", "field": 0x28c, "grade_cat": "services", "grade_key": 0,
		"icon": "icon_medical", "what": "the medical equipment"},
]

## MANAGER.EXE's own message, @0x65E5AC / 0x65E51C / 0x65E490 / 0x65E408 / 0x65E378. The
## five differ only in the noun, so the port holds the shell once and `what` supplies the
## noun — the rendered string is character-for-character the binary's.
const MESSAGE := "You have been fined %s because you don´t have\n%s needed to play\nin this competition."

## Per-arm: the minimum grade each item must hold, and the fine in INTERNAL units when it
## does not. `null` = the arm does not test that item at all.
##   PREMIER      @0x57ab92..0x57ac4d
##   F.A. CUP     @0x57ac57..0x57ac86   (floodlights only)
##   EUROPE       @0x57ac9d..0x57ad64   (U.E.F.A. / C.W.C. / European Cup / Supercup /
##                                        Intercontinental — one shared arm)
const ARM_PREMIER := {
	"floodlights": {"min": 2, "internal": 5_000_000},
	"changing_rooms": {"min": 1, "internal": 5_000_000},
	"score_board": {"min": 1, "internal": 5_000_000},
	"access": {"min": 1, "internal": 10_000_000},
	"medical": {"min": 1, "internal": 10_000_000},
}
const ARM_FA_CUP := {
	"floodlights": {"min": 1, "internal": 3_000_000},
}
const ARM_EUROPE := {
	"floodlights": {"min": 2, "internal": 10_000_000},
	"changing_rooms": {"min": 1, "internal": 10_000_000},
	"score_board": {"min": 1, "internal": 10_000_000},
	"access": {"min": 1, "internal": 15_000_000},
	"medical": {"min": 1, "internal": 15_000_000},
}

## The five competitions that share the EUROPE arm (indices 7..11), in the port's own keys.
const EUROPE_KEYS := ["uefa_cup", "cup_winners_cup", "european_cup", "supercup",
	"intercontinental"]

## The port's competition keys against `DAT_0066b1dc`'s own index. The four league indices
## come from `GroundPreset.competition_index`, which is the same field (`club+0x50`) read
## for the ground preset, so the two tables cannot disagree.
const COMP_INDEX := {
	"fa_cup": 4,
	"coca_cola": 5,
	"charity_shield": 6,
	"uefa_cup": 7,
	"cup_winners_cup": 8,
	"european_cup": 9,
	"supercup": 10,
	"intercontinental": 11,
}

## The three arms against the competition index, exactly as the binary's compares read.
const ARM_OF_INDEX := {0: ARM_PREMIER, 4: ARM_FA_CUP, 7: ARM_EUROPE, 8: ARM_EUROPE,
	9: ARM_EUROPE, 10: ARM_EUROPE, 11: ARM_EUROPE}


## `DAT_0066b1dc` for a match: a league fixture takes the club's own competition index
## (0..3), everything else its entry in COMP_INDEX. -1 for a key the port does not map.
static func comp_index(comp_key: String, league_id: String) -> int:
	if comp_key == "league":
		return GroundPreset.competition_index(league_id)
	return int(COMP_INDEX.get(comp_key, -1))


## The requirement table for a match in `comp_key`, or {} when that competition fines
## nothing. Indices 1..3 (First / Second / Third), 5 (Coca-Cola) and 6 (Charity Shield)
## fall through the `jb 0x57ac8e` / `ja 0x57ac97` bounds and fine nothing at all.
static func arm_for(comp_key: String, league_id: String) -> Dictionary:
	return ARM_OF_INDEX.get(comp_index(comp_key, league_id), {})


## Every fine one match in `comp_key` levies, given the club's live ground grades.
## `grade_of` is a Callable(cat: String, key: int) -> int returning the club's CURRENT
## grade for that item (Career passes its own `ground_grade` over the GroundPreset seed).
##
## Returns a list of {"id", "field", "icon", "internal", "pounds", "message"} in the
## binary's own order. Empty when the ground clears the standard — which is the normal
## case for a Premier club on preset 0 (FLOODLIGHTS 2 / CHANGING ROOMS 1 / SCORE BOARD 2 /
## ACCESS 1 / MEDICAL 1 all pass), and why five driven careers never saw this card.
static func for_match(comp_key: String, league_id: String, grade_of: Callable) -> Array:
	var arm := arm_for(comp_key, league_id)
	if arm.is_empty():
		return []
	var out: Array = []
	for item in ITEMS:
		var req: Variant = arm.get(str(item["id"]))
		if req == null:
			continue
		var rule: Dictionary = req
		var grade := int(grade_of.call(str(item["grade_cat"]), int(item["grade_key"])))
		if grade >= int(rule["min"]):
			continue
		var pounds := int(rule["internal"]) / FinanceModel.MONEY_PER_POUND
		out.append({
			"id": item["id"],
			"field": item["field"],
			"icon": item["icon"],
			"internal": int(rule["internal"]),
			"pounds": pounds,
			"message": MESSAGE % [_money(pounds), item["what"]],
		})
	return out


## The game's own money format for the `%s` in the message: "£25,000".
static func _money(pounds: int) -> String:
	var s := str(absi(pounds))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return "£" + s + out
