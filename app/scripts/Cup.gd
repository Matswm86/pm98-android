class_name Cup
extends RefCounted
## PM98's domestic knockouts, layered onto the league season. One chassis drives both:
##   * the F.A. Cup   -- single-leg ties, replays then penalties, labels Round 4 -> Round
##                       5 -> Qtr. Finals -> Semifinals -> Final (a 16-club field).
##   * the Coca-Cola (League) Cup -- TWO-LEGGED ties (the binary's "Round 1 - 1st"/"- 2nd"
##                       ... "Semifinals - 1st"/"- 2nd"), a SINGLE-leg Final, labels Round
##                       1 -> Round 2 -> Qtr Finals -> Semifinals -> Final.
## create() takes an `opts` dict to pick the competition's name, leg mode, label scheme,
## prize and schedule span; everything else is shared.
##
## FAITHFUL to the original (verified against MANAGER.EXE):
##   * Round labels are PM98's own (the .data label tables -- "Round 1".."Round 5",
##     "Qtr. Finals"/"Qtr Finals", "Semifinals", "Final", "Champion", "Finalist", plus the
##     two-legged "<round> - 1st"/"- 2nd" set; FACUP%03u.CPT / CCCUP%03u.CPT competition
##     files; img\premier\copas\{facup,cocacola}.bmp).
##   * OPEN DRAW: both cups re-draw the surviving clubs at random every round (NOT a fixed
##     seeded bracket). We do the same -- a fresh random pairing of survivors each round.
##   * Single-leg tie: a level result is REPLAYED at the reversed venue ("REPLAY" in the
##     binary); a level replay is settled on PENALTIES.
##   * Two-legged tie: home-and-away, advance on aggregate; a level aggregate is settled on
##     PENALTIES ("on penalties"/"AFTER PENALTIES" in the binary; extra time + away-goals
##     are abstracted into the penalty decider).
##
## ABSTRACTED (honest simplification, same spirit as the AI-clubs-get-no-injuries scope
## flag): the real cups span every division. Our career is a SINGLE division, so each cup
## is contested among that division's clubs only -- a faithful knockout, just a smaller,
## one-tier field (20 in the Premier League, 24 below). Both legs of a two-legged tie
## resolve on the one scheduled week (the real midweek-spaced legs are collapsed to a tie).
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

## A fresh cup over `club_ids`, with its rounds spread across a `total_weeks` league
## season. Deterministic: the random draw is deferred to play_round(). `opts` selects
## the competition (defaults = the F.A. Cup):
##   name             display name ("F.A. Cup" / "Coca-Cola Cup")
##   legs             ties per round before the final: 1 (FA Cup) or 2 (League Cup)
##   two_legged_final the final is also two legs (false for both English cups)
##   label_scheme     "facup" (by clubs remaining) or "sequential" (Round 1,2,... then QF/SF)
##   qtr_label        "Qtr. Finals" (FA Cup) or "Qtr Finals" (League Cup)
##   prize_round / prize_winner   bank credit per round survived / for lifting the cup
##   span_lo / span_hi            fraction of the season the rounds spread across [0,1]
static func create(club_ids: Array, total_weeks: int, opts: Dictionary = {}) -> Dictionary:
	var ids: Array = []
	for v in club_ids:
		ids.append(int(v))
	var span_lo := float(opts.get("span_lo", 0.0))
	var span_hi := float(opts.get("span_hi", 1.0))
	return {
		"name": str(opts.get("name", NAME)),
		"survivors": ids,                  # clubs still in (full field at kickoff)
		"rounds": [],                      # played rounds, oldest first: {label, ties}
		"round_weeks": _schedule(total_weeks, _num_rounds(ids.size()), span_lo, span_hi),
		"champion_id": -1,
		"n0": ids.size(),                  # starting field size (for labels)
		"legs": int(opts.get("legs", 1)),
		"two_legged_final": bool(opts.get("two_legged_final", false)),
		"label_scheme": str(opts.get("label_scheme", "facup")),
		"qtr_label": str(opts.get("qtr_label", "Qtr. Finals")),
		"prize_round": int(opts.get("prize_round", ROUND_PRIZE)),
		"prize_winner": int(opts.get("prize_winner", WINNER_BONUS)),
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


## League-week boundaries after which each cup round is played (midweek ties), spread
## across the [span_lo, span_hi] fraction of the season. The default span [0,1] spaces the
## rounds evenly to the run-in (the F.A. Cup); a tighter span (e.g. [0,0.7]) finishes a cup
## earlier (the League Cup, so the two finals don't coincide).
static func _schedule(total_weeks: int, num_rounds: int, span_lo := 0.0, span_hi := 1.0) -> Array:
	var out: Array = []
	if num_rounds <= 0 or total_weeks <= 0:
		return out
	var span := span_hi - span_lo
	for k in range(num_rounds):
		var frac := span_lo + float(k + 1) / float(num_rounds + 1) * span
		var w := int(round(frac * total_weeks))
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
	return _label_for(b, surv, (b.get("rounds", []) as Array).size() + 1)

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


## The PM98 label for a round starting with `count` clubs, under the F.A. Cup scheme
## (by clubs remaining). Kept as the default; _label_for dispatches per competition.
static func _round_label(count: int) -> String:
	for entry in _LABELS:
		if count <= int(entry[0]):
			return str(entry[1])
	return "Round 1"


## The label for a round of this bracket: the F.A. Cup uses the by-remaining table; the
## League Cup ("sequential") counts Round 1, Round 2, ... until the named end rounds, and
## uses its own "Qtr Finals" spelling. `round_no` is 1-based (rounds already played + 1).
static func _label_for(b: Dictionary, count: int, round_no: int) -> String:
	if str(b.get("label_scheme", "facup")) == "sequential":
		if count <= 2:
			return "Final"
		if count <= 4:
			return "Semifinals"
		if count <= 8:
			return str(b.get("qtr_label", "Qtr. Finals"))
		return "Round %d" % round_no
	return _round_label(count)


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
	var label := _label_for(b, start_count, (b.get("rounds", []) as Array).size() + 1)
	var out := {"label": label, "manager_tie": {}, "manager_out": false,
		"champion": false, "news": [], "prize": 0}
	if start_count <= 1:
		return out

	# How many legs this round's ties are played over: 1 (FA Cup, or a single-leg final),
	# else the competition's leg count (the League Cup's two-legged rounds).
	var legs := int(b.get("legs", 1))
	var two_final := bool(b.get("two_legged_final", false))
	var round_legs := 1 if (legs <= 1 or (start_count == 2 and not two_final)) else legs

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
		var tie := _play_tie(rng, h, a, ratings_fn, round_legs)
		ties.append(tie)
		next_survivors.append(int(tie["winner_id"]))
		i += 2

	b["rounds"] = (b.get("rounds", []) as Array) + [{"label": label, "ties": ties}]
	b["survivors"] = next_survivors

	# The manager's tie + news for this round.
	for tie in ties:
		if int(tie["home_id"]) == club_id or int(tie["away_id"]) == club_id:
			out["manager_tie"] = tie
			out["news"].append(_manager_news(b, tie, label, club_id, names_fn))
			if int(tie["winner_id"]) == club_id and not tie.get("bye", false):
				out["prize"] = int(b.get("prize_round", ROUND_PRIZE))
			elif int(tie["winner_id"]) != club_id:
				out["manager_out"] = true
			break

	# Champion?
	if next_survivors.size() == 1:
		b["champion_id"] = int(next_survivors[0])
		out["champion"] = (int(next_survivors[0]) == club_id)
		var champ_name := str(names_fn.call(int(next_survivors[0])))
		var cup_name := str(b.get("name", NAME))
		if out["champion"]:
			out["prize"] = int(out["prize"]) + int(b.get("prize_winner", WINNER_BONUS))
			out["news"].append({"kind": "cup",
				"text": "%s have WON the %s!" % [champ_name, cup_name]})
		else:
			out["news"].append({"kind": "cup",
				"text": "%s have won the %s." % [champ_name, cup_name]})
	return out


## Resolve one tie over `legs` legs. Single-leg (FA Cup, League Cup final): a draw is
## replayed at the reversed venue, a level replay goes to penalties. Two-leg (League Cup
## rounds): home-and-away, advance on aggregate, a level aggregate goes to penalties.
## Returns the tie dict; scores are from the FIRST-named (home-first-leg) side's view.
static func _play_tie(rng: RandomNumberGenerator, h: int, a: int, ratings_fn: Callable, legs := 1) -> Dictionary:
	var rh: Dictionary = ratings_fn.call(h)
	var ra: Dictionary = ratings_fn.call(a)
	if legs >= 2:
		return _play_two_leg_tie(rng, h, a, rh, ra)
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


## A two-legged tie (h hosts leg 1, a hosts leg 2): aggregate decides, level aggregate
## goes to penalties. Stores both leg scores (home-first-leg side's view) + the aggregate.
static func _play_two_leg_tie(rng: RandomNumberGenerator, h: int, a: int, rh: Dictionary, ra: Dictionary) -> Dictionary:
	var l1 := MatchEngine.simulate(rng, rh, ra)        # leg 1: h at home
	var l2 := MatchEngine.simulate(rng, ra, rh)        # leg 2: a at home
	var h_goals1 := int(l1["home_goals"])
	var a_goals1 := int(l1["away_goals"])
	var a_goals2 := int(l2["home_goals"])              # a is home in leg 2
	var h_goals2 := int(l2["away_goals"])              # h is away in leg 2
	var h_agg := h_goals1 + h_goals2
	var a_agg := a_goals1 + a_goals2
	var decided := "agg"
	var w: int
	if h_agg != a_agg:
		w = h if h_agg > a_agg else a
	else:
		w = _penalties(rng, h, a, rh, ra)
		decided = "pens"
	return {"home_id": h, "away_id": a, "two_legged": true,
		"leg1_hg": h_goals1, "leg1_ag": a_goals1,      # leg 1 (h home): h-a
		"leg2_hg": h_goals2, "leg2_ag": a_goals2,      # leg 2 (a home), still h-then-a
		"h_agg": h_agg, "a_agg": a_agg,
		"winner_id": w, "loser_id": (a if w == h else h), "decided": decided, "bye": false}


## A one-off neutral-venue match (the Charity Shield curtain-raiser; later the European
## Supercup / Intercontinental Cup). One match, no replay -- a level result goes straight
## to penalties. `h` is nominally the home/first-named side (e.g. the league champions).
## Returns a tie-shaped dict so the cup UI can render it like any other tie.
static func single_neutral_match(rng: RandomNumberGenerator, h: int, a: int, ratings_fn: Callable) -> Dictionary:
	var rh: Dictionary = ratings_fn.call(h)
	var ra: Dictionary = ratings_fn.call(a)
	var res := MatchEngine.simulate(rng, rh, ra)
	var hg := int(res["home_goals"])
	var ag := int(res["away_goals"])
	if hg != ag:
		var w := h if hg > ag else a
		return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
			"winner_id": w, "loser_id": (a if w == h else h), "decided": "", "bye": false}
	var wp := _penalties(rng, h, a, rh, ra)
	return {"home_id": h, "away_id": a, "hg": hg, "ag": ag,
		"winner_id": wp, "loser_id": (a if wp == h else h), "decided": "pens", "bye": false}


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


## A club-news line for the manager's tie this round (cup name from the bracket).
static func _manager_news(b: Dictionary, tie: Dictionary, label: String, club_id: int, names_fn: Callable) -> Dictionary:
	var cup_name := str(b.get("name", NAME))
	if tie.get("bye", false):
		return {"kind": "cup", "text": "%s %s: a bye into the next round." % [cup_name, label]}
	var hid := int(tie["home_id"])
	var opp := int(tie["away_id"]) if hid == club_id else hid
	var opp_name := str(names_fn.call(opp))
	var won := int(tie["winner_id"]) == club_id
	var mine: int
	var theirs: int
	var suffix := ""
	if tie.get("two_legged", false):
		# Report the aggregate; penalties flagged when level on aggregate.
		var h_agg := int(tie["h_agg"])
		var a_agg := int(tie["a_agg"])
		mine = h_agg if hid == club_id else a_agg
		theirs = a_agg if hid == club_id else h_agg
		suffix = " on aggregate"
		if tie["decided"] == "pens":
			suffix = " on aggregate, on penalties"
	elif tie["decided"] == "replay" or tie["decided"] == "pens":
		# The decisive replay scoreline (h's view in replay_hg/ag).
		var rmine := int(tie.get("replay_hg", tie["hg"]))
		var rtheirs := int(tie.get("replay_ag", tie["ag"]))
		mine = rmine if hid == club_id else rtheirs
		theirs = rtheirs if hid == club_id else rmine
		suffix = " (after a replay)" if tie["decided"] == "replay" else " (on penalties)"
	else:
		mine = int(tie["hg"]) if hid == club_id else int(tie["ag"])
		theirs = int(tie["ag"]) if hid == club_id else int(tie["hg"])
	var my_name := str(names_fn.call(club_id))
	if won:
		return {"kind": "cup", "text": "%s %s: %s beat %s %d-%d%s." % [
			cup_name, label, my_name, opp_name, mine, theirs, suffix]}
	return {"kind": "cup", "text": "%s %s: %s knocked out by %s %d-%d%s." % [
		cup_name, label, my_name, opp_name, theirs, mine, suffix]}
