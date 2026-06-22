class_name Pm98StatMatch
extends RefCounted
## PM98 STATISTICAL match engine -- the faithful port of the "instant result" /
## AI-vs-AI fixture simulator that MANAGER.EXE runs for every match the human does
## NOT watch positionally (career-match runner FUN_0044ee70, the PS==5 branch,
## lines 357-792). Unlike app/scripts/MatchEngine.gd (an ABSTRACTED per-shot model),
## every number here is lifted from the binary and validated against the real
## function through the Ghidra PCode emulator (tools/re/run_statresolve_oracle.sh ->
## app/tests/test_statresolve_oracle.gd). Full RE map: docs/re/stat_match_engine_re.md.
##
## This file currently ports the SCORING CORE -- the chance/goal resolver
## FUN_0044ece0 -- plus its position-weight table. The surrounding orchestration
## (FUN_0044ee70's per-segment chance-count rand loops + the FUN_00450510 player
## stats accumulator) is the next port stage; see the spec doc NEXT section.
##
## RNG: the statistical engine calls the msvcrt C-runtime rand() (state*214013 +
## 2531011; draw = (state>>16)&0x7FFF) -- the SAME LCG MatchEngine.Pm98Rng already
## reproduces. The probability idiom is `(rand()*N)>>15`, a uniform draw in [0,N)
## (rand() is non-negative so the binary's sign-bias correction is a no-op here).


## msvcrt rand() LCG. Identical algorithm to MatchEngine.Pm98Rng; kept local so the
## stat engine seeds/advances its own stream (the binary's rand() state is separate
## from the positional sim's internal FUN_005ec250 LCG).
class Rng extends RefCounted:
	var state: int

	func _init(seed_: int) -> void:
		state = seed_ & 0xFFFFFFFF

	## One msvcrt rand() draw in [0, 32767].
	func next() -> int:
		state = (state * 214013 + 2531011) & 0xFFFFFFFF
		return (state >> 16) & 0x7FFF

	## The binary's `(rand()*n)>>15` uniform draw in [0, n).
	func mod(n: int) -> int:
		return (next() * n) >> 15


## Position -> attacking-threat weight, DAT_006532ec @ VA 0x6532ec (.data foff
## 0x2518ec). 19 entries (index = participant position code +0xc8, range 0..18);
## the central-striker slots (9) carry the heaviest weight. Goalkeepers (slot 0/1)
## weigh 0, so they never win the scorer roulette even before the GK is excluded.
const POS_WEIGHT := [0, 0, 3, 3, 3, 7, 7, 12, 10, 35, 10, 12, 15, 18, 15, 3, 18, 18, 10]

## FUN_004510b0 adds this per-period minute offset, switching on the event type
## (== the segment index): h1=+0, h2=+45, ET1=+90, ET2=+105.
const MINUTE_OFFSET := [0, 0x2d, 0x5a, 0x69]


## Resolve one created chance for the attacking `side` (0 or 1) at `seg` (0..3) and
## `minute` (within-period). Faithful port of FUN_0044ece0.
##
## `match` = { teams: [team0, team1] }; each team = { id: int, participants: [P x11] };
## each participant P = { shirt:int(+0x88, 0 = not in XI), pos:int(+0xc8),
## save:int(+0xc0, only P[0]=keeper consulted), d4:int, d8:int, dc:int (event-slot
## markers, +0xd4/+0xd8/+0xdc) }.
##
## Returns the emitted event { type, minute, p4, payload } where payload =
## (scorerShirt<<16)|teamId, or null if the keeper saved the chance (no event).
static func resolve_chance(rng: Rng, match: Dictionary, side: int, seg: int, minute: int) -> Variant:
	var att: Dictionary = match["teams"][side]
	var defn: Dictionary = match["teams"][1 - side]
	var keeper: Dictionary = defn["participants"][0]

	# --- keeper-save gate ---------------------------------------------------
	# An in-XI keeper saves when rand()%130 < his save rating (+0xc0); a keeper
	# not in the XI (shirt 0) cannot save, so the chance always proceeds.
	if int(keeper.get("shirt", 0)) != 0:
		if rng.mod(130) < int(keeper.get("save", 0)):
			return null

	# --- scorer roulette ----------------------------------------------------
	var parts: Array = att["participants"]
	var total := 0
	for p in parts:                                  # all 11; GK weight is 0
		if int(p.get("shirt", 0)) != 0:
			total += POS_WEIGHT[int(p.get("pos", 0))]

	# Roll once per pass; first available player past the running threshold wins.
	# Players[1..10] only -- the keeper (slot 0) is skipped, so he never scores.
	var scorer: Dictionary = {}
	while scorer.is_empty():
		var roll := rng.mod(total) if total > 0 else 0
		var acc := 0
		for i in range(1, 11):
			var p: Dictionary = parts[i]
			if int(p.get("shirt", 0)) == 0:
				continue
			acc += POS_WEIGHT[int(p.get("pos", 0))]
			if roll < acc and _available(p):
				scorer = p
				break
		if total <= 0:
			break                                    # no eligible scorers; avoid infinite loop

	if scorer.is_empty():
		return null

	# --- emit the goal event (FUN_004510b0) ---------------------------------
	var payload := ((int(scorer["shirt"]) & 0xFFFF) << 16) | (int(att.get("id", 0)) & 0xFFFF)
	return {
		"type": seg,
		"minute": minute + MINUTE_OFFSET[seg],
		"p4": 0,
		"payload": payload,
	}


## A participant can be picked as scorer only if fewer than two of its two event
## slots (+0xd4/+0xd8) are set AND it has no pending shot marker (+0xdc).
static func _available(p: Dictionary) -> bool:
	var slots := int(int(p.get("d4", 0)) != 0) + int(int(p.get("d8", 0)) != 0)
	return slots < 2 and int(p.get("dc", 0)) == 0
