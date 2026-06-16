class_name Cup
extends RefCounted
## The F.A. Cup -- PM98's domestic knockout, layered onto the league season.
##
## FAITHFUL to the original (verified against MANAGER.EXE):
##   * Round labels are PM98's own: "Round 1".."Round 5", "Qtr. Finals",
##     "Semifinals", "Final" (the .data label table at 0x... -- see the strings
##     "Round 5","Qtr. Finals","Semifinals","Final","Champion","Finalist", plus
##     the FACUP%03u.CPT competition files + img\premier\copas\facup.bmp).
##   * OPEN DRAW: the F.A. Cup re-draws the surviving clubs at random every round
##     (it is NOT a fixed seeded bracket). We do the same -- a fresh random pairing
##     of survivors each round.
##   * Knockout: a level tie is REPLAYED at the reversed venue ("REPLAY" in the
##     binary); a level replay is settled on PENALTIES.
##
## ABSTRACTED (honest simplification, same spirit as the AI-clubs-get-no-injuries
## scope flag): the real F.A. Cup spans every division. Our career is a SINGLE
## division, so the cup is contested among that division's clubs only -- a faithful
## knockout, just a smaller, one-tier field (20 in the Premier League, 24 below).
## The round labels still land on the Premier-club progression (a 16-club field
## after round one runs Round 4 -> Round 5 -> Qtr. Finals -> Semifinals -> Final).
##
## Pure logic on a JSON-serializable Dictionary (the "bracket"), like SeasonSim's
## fixtures: it lives in the Career save and runs headless. The random DRAW happens
## lazily in play_round() (which has the rng), so create() stays deterministic and a
## save loaded without a cup can mint a default one safely.

const NAME := "F.A. Cup"

# Prize money credited to the manager's bank for progressing (gate receipts + prize
# fund). NOT a reversed PM98 prize table -- a modest, documented reward so a cup run
# matters financially. Per round survived, plus a trophy bonus for lifting the cup.
const ROUND_PRIZE := 200_000
const WINNER_BONUS := 1_500_000

# Round-label thresholds: the label for a round is chosen by how many clubs START it.
# Matches PM98 (a 16-club field => Round 5; 8 => Qtr. Finals; 4 => Semifinals; 2 => Final).
const _LABELS := [
	[2, "Final"], [4, "Semifinals"], [8, "Qtr. Finals"],
	[16, "Round 5"], [32, "Round 4"], [64, "Round 3"], [128, "Round 2"],
]


# ---- construction --------------------------------------------------------

## A fresh F.A. Cup over `club_ids`, with its rounds spread across a `total_weeks`
## league season. Deterministic: the random draw is deferred to play_round().
static func create(club_ids: Array, total_weeks: int) -> Dictionary:
	var ids: Array = []
	for v in club_ids:
		ids.append(int(v))
	return {
		"name": NAME,
		"survivors": ids,                  # clubs still in (full field at kickoff)
		"rounds": [],                      # played rounds, oldest first: {label, ties}
		"round_weeks": _schedule(total_weeks, _num_rounds(ids.size())),
		"champion_id": -1,
		"n0": ids.size(),                  # starting field size (for labels)
	}


## Largest power of two <= n (the field round one reduces to). 0 for n<1.
static func _floor_pow2(n: int) -> int:
	var p := 1
	while p * 2 <= n:
		p *= 2
	return p if n >= 1 else 0


## How many rounds the whole cup runs: one preliminary round to bring the field to a
## power of two (when it isn't already), then a clean halving down to one champion.
static func _num_rounds(n: int) -> int:
	if n <= 1:
		return 0
	var p := _floor_pow2(n)
	var halvings := 0
	var k := p
	while k > 1:
		k /= 2
		halvings += 1
	return halvings if n == p else halvings + 1


## League-week boundaries after which each cup round is played (midweek ties).
## Evenly spread across the season so the cup intensifies alongside the run-in.
static func _schedule(total_weeks: int, num_rounds: int) -> Array:
	var out: Array = []
	if num_rounds <= 0 or total_weeks <= 0:
		return out
	for k in range(num_rounds):
		var w := int(round(float(k + 1) * total_weeks / float(num_rounds + 1)))
		w = clampi(w, 1, total_weeks)
		if not out.is_empty() and w <= int(out[-1]):
			w = int(out[-1]) + 1            # keep strictly increasing
		out.append(w)
	return out


# ---- queries -------------------------------------------------------------

static func is_finished(b: Dictionary) -> bool:
	if int(b.get("champion_id", -1)) != -1:
		return true
	return _survivors(b).size() <= 1 and not (b.get("rounds", []) as Array).is_empty()

static func _survivors(b: Dictionary) -> Array:
	return b.get("survivors", [])

static func champion_id(b: Dictionary) -> int:
	return int(b.get("champion_id", -1))

## The label of the round that will be played next (or "" if the cup is over).
static func next_label(b: Dictionary) -> String:
	var surv := _survivors(b).size()
	if surv <= 1:
		return ""
	return _round_label(surv)

## True if club `cid` is still in the competition.
static func still_in(b: Dictionary, cid: int) -> bool:
	return _survivors(b).has(int(cid))

## How many league weeks remain before the next cup round (so the hub can hint it).
## -1 if there is no further round.
static func weeks_until_next(b: Dictionary, week: int) -> int:
	var ridx: int = (b.get("rounds", []) as Array).size()
	var rw: Array = b.get("round_weeks", [])
	if ridx >= rw.size():
		return -1
	return maxi(0, int(rw[ridx]) - week)


## The PM98 label for a round starting with `count` clubs.
static func _round_label(count: int) -> String:
	for entry in _LABELS:
		if count <= int(entry[0]):
			return str(entry[1])
	return "Round 1"


# ---- the draw + play -----------------------------------------------------

## Is a cup round due now? True when the cup is unfinished and the just-completed
## league `week` has reached the next scheduled round-week.
static func round_due(b: Dictionary, week: int) -> bool:
	if int(b.get("champion_id", -1)) != -1:
		return false
	if _survivors(b).size() <= 1:
		return false
	var ridx: int = (b.get("rounds", []) as Array).size()
	var rw: Array = b.get("round_weeks", [])
	if ridx >= rw.size():
		return false
	return week >= int(rw[ridx])


## Play the next round: draw the survivors at random, resolve every tie (replay then
## penalties on a level tie), advance the winners. Mutates `b`. `ratings_fn` is a
## Callable(id:int)->team_ratings dict; `names_fn` a Callable(id:int)->String.
## Returns {label, manager_tie, manager_out, champion, news:[{kind,text}], prize}.
static func play_round(b: Dictionary, rng: RandomNumberGenerator,
		ratings_fn: Callable, club_id: int, names_fn: Callable) -> Dictionary:
	var survivors: Array = (_survivors(b) as Array).duplicate()
	var start_count := survivors.size()
	var label := _round_label(start_count)
	var out := {"label": label, "manager_tie": {}, "manager_out": false,
		"champion": false, "news": [], "prize": 0}
	if start_count <= 1:
		return out

	# Open random draw of the survivors.
	_shuffle(survivors, rng)

	# Round one may need byes to bring an off-power-of-two field down to a power of
	# two; later rounds are a clean halving (survivors is always even by then). A field
	# already a power of two needs no byes -- it just halves.
	var byes := 0
	if (b.get("rounds", []) as Array).is_empty():
		var p := _floor_pow2(start_count)
		if p != start_count:
			byes = 2 * p - start_count        # clubs that sit the preliminary round out
	# Guard: an odd field with no planned byes (shouldn't happen) gives one bye.
	if (start_count - byes) % 2 == 1:
		byes += 1

	var ties: Array = []
	var next_survivors: Array = []
	var bye_clubs: Array = survivors.slice(0, byes)
	var players: Array = survivors.slice(byes)
	for cid in bye_clubs:
		ties.append({"home_id": int(cid), "away_id": -1, "hg": 0, "ag": 0,
			"winner_id": int(cid), "loser_id": -1, "decided": "bye", "bye": true})
		next_survivors.append(int(cid))
	var i := 0
	while i + 1 < players.size():
		var h := int(players[i])
		var a := int(players[i + 1])
		var tie := _play_tie(rng, h, a, ratings_fn)
		ties.append(tie)
		next_survivors.append(int(tie["winner_id"]))
		i += 2

	b["rounds"] = (b.get("rounds", []) as Array) + [{"label": label, "ties": ties}]
	b["survivors"] = next_survivors

	# The manager's tie + news for this round.
	for tie in ties:
		if int(tie["home_id"]) == club_id or int(tie["away_id"]) == club_id:
			out["manager_tie"] = tie
			var news := _manager_news(tie, label, club_id, names_fn)
			out["news"].append(news)
			if int(tie["winner_id"]) == club_id and not tie.get("bye", false):
				out["prize"] = ROUND_PRIZE
			elif int(tie["winner_id"]) != club_id:
				out["manager_out"] = true
			break

	# Champion?
	if next_survivors.size() == 1:
		b["champion_id"] = int(next_survivors[0])
		out["champion"] = (int(next_survivors[0]) == club_id)
		var champ_name := str(names_fn.call(int(next_survivors[0])))
		if out["champion"]:
			out["prize"] = int(out["prize"]) + WINNER_BONUS
			out["news"].append({"kind": "cup",
				"text": "%s have WON the %s!" % [champ_name, NAME]})
		else:
			out["news"].append({"kind": "cup",
				"text": "%s have won the %s." % [champ_name, NAME]})
	return out


## Resolve one tie: a draw is replayed at the reversed venue, a level replay goes to
## penalties. Returns the tie dict (decisive-leg score from the FIRST-named side's view).
static func _play_tie(rng: RandomNumberGenerator, h: int, a: int, ratings_fn: Callable) -> Dictionary:
	var rh: Dictionary = ratings_fn.call(h)
	var ra: Dictionary = ratings_fn.call(a)
	var res := MatchEngine.simulate(rng, rh, ra)
	var hg := int(res["home_goals"])
	var ag := int(res["away_goals"])
	if hg != ag:
		var w := h if hg > ag else a
		return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
			"winner_id": w, "loser_id": (a if w == h else h), "decided": "", "bye": false}
	# Replay at the reversed venue (a at home).
	var r2 := MatchEngine.simulate(rng, ra, rh)
	var ag2 := int(r2["home_goals"])
	var hg2 := int(r2["away_goals"])
	if ag2 != hg2:
		var w2 := a if ag2 > hg2 else h
		return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
			"replay_hg": hg2, "replay_ag": ag2,
			"winner_id": w2, "loser_id": (a if w2 == h else h), "decided": "replay", "bye": false}
	# Penalties: weighted by team overall.
	var w3 := _penalties(rng, h, a, rh, ra)
	return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
		"replay_hg": hg2, "replay_ag": ag2,
		"winner_id": w3, "loser_id": (a if w3 == h else h), "decided": "pens", "bye": false}


## Penalty shootout: a rating-weighted coin flip (stronger sides edge it, never a lock).
static func _penalties(rng: RandomNumberGenerator, h: int, a: int, rh: Dictionary, ra: Dictionary) -> int:
	var oh := float(rh.get("att", 50)) + float(rh.get("def", 50)) + float(rh.get("gk", 50))
	var oa := float(ra.get("att", 50)) + float(ra.get("def", 50)) + float(ra.get("gk", 50))
	var p_home := 0.5
	if oh + oa > 0.0:
		# Compress toward 50/50: shootouts are close to a coin flip.
		p_home = 0.5 + 0.5 * ((oh - oa) / (oh + oa))
	return h if rng.randf() < p_home else a


## In-place Fisher-Yates using the season rng (reproducible under a fixed seed).
static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## A club-news line for the manager's tie this round.
static func _manager_news(tie: Dictionary, label: String, club_id: int, names_fn: Callable) -> Dictionary:
	if tie.get("bye", false):
		return {"kind": "cup", "text": "%s %s: a bye into the next round." % [NAME, label]}
	var hid := int(tie["home_id"])
	var aid := int(tie["away_id"])
	var opp := aid if hid == club_id else hid
	var opp_name := str(names_fn.call(opp))
	# Score from the manager's perspective.
	var mine: int
	var theirs: int
	if tie["decided"] == "replay" or tie["decided"] == "pens":
		# Report the replay scoreline (the decisive leg).
		var rmine := int(tie.get("replay_hg", tie["hg"]))   # h's replay goals
		var rtheirs := int(tie.get("replay_ag", tie["ag"]))
		mine = rmine if hid == club_id else rtheirs
		theirs = rtheirs if hid == club_id else rmine
	else:
		mine = int(tie["hg"]) if hid == club_id else int(tie["ag"])
		theirs = int(tie["ag"]) if hid == club_id else int(tie["hg"])
	var won := int(tie["winner_id"]) == club_id
	var suffix := ""
	if tie["decided"] == "replay":
		suffix = " (after a replay)"
	elif tie["decided"] == "pens":
		suffix = " (on penalties)"
	var my_name := str(names_fn.call(club_id))
	if won:
		return {"kind": "cup", "text": "%s %s: %s beat %s %d-%d%s." % [
			NAME, label, my_name, opp_name, mine, theirs, suffix]}
	return {"kind": "cup", "text": "%s %s: %s knocked out by %s %d-%d%s." % [
		NAME, label, my_name, opp_name, theirs, mine, suffix]}
