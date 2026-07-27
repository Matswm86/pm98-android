extends SceneTree
## DRAW-THEN-PLAY — the original draws a knockout round in one week and plays it in a
## later one, and the port used to pair AND play in a single step (the DIVERGENCE flagged
## on Career.pending_cup_draws). Witnessed on a live Bolton W career 2026-07-26, twice and
## in two competitions:
##
##   F.A. Cup   R2 played Sun 14 Dec 1997 -> R3 drawn, shown UNPLAYED Sat 20 Dec ->
##              still unplayed Sun 28 Dec -> played Sat 10 Jan 1998
##   Coca-Cola  R4 played Mon 1 Dec 1997 -> Qtr Finals drawn, shown UNPLAYED Sun 7 Dec
##
## Frames: screenshots/wine-captures-2026-07-26-cup-draw-then-play/.
## So the rule is measured, not invented: the next round is drawn the moment the previous
## one resolves, and is played at its own scheduled week.
##
##   ~/godot4 --headless --path app --script res://tests/test_cup_draw_then_play.gd

const SEED := 424242
var _ok := true


func _initialize() -> void:
	quit(0 if _run() else 1)


func _a(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	_ok = _ok and cond
	return cond


func _ratings_fn() -> Callable:
	return func(id: int) -> Dictionary:
		var base := 45.0 + float(id % 20)
		return {"att": base, "def": base, "gk": base + 2.0, "name": "C%d" % id}


func _names_fn() -> Callable:
	return func(id: int) -> String: return "C%d" % id


func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = SEED
	return r


func _run() -> bool:
	var ids: Array = []
	for i in range(1, 17):
		ids.append(i)

	# --- a fresh bracket has nothing drawn, and playing pairs on the spot -------------
	var b := Cup.create(ids, 40)
	_a((b.get("pending_draw", {}) as Dictionary).is_empty(), "a fresh cup has no pending draw")
	var rng := _rng()
	var r1 := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
	_a((b["rounds"] as Array).size() == 1, "playing the first round records it")
	_a((b.get("pending_draw", {}) as Dictionary).is_empty(),
		"play_round consumes the draw it made for itself")

	# --- draw round 2 WITHOUT playing it ---------------------------------------------
	var drawn := Cup.draw_next_round(b, rng)
	_a(not drawn.is_empty(), "the next round draws")
	_a((b["rounds"] as Array).size() == 1,
		"a drawn round is NOT recorded as played (rounds still %d)" % (b["rounds"] as Array).size())
	_a(Cup.next_label(b) == str(drawn["label"]),
		"next_label names the drawn round ('%s')" % Cup.next_label(b))
	var players: Array = (drawn["players"] as Array).duplicate()
	_a(players.size() == 8, "round 2 pairs the 8 survivors (%d)" % players.size())

	# Drawing again must not re-pair: the shuffle draws are consumed once, and a second
	# SORTEO for the same round would show different ties than the first.
	var again := Cup.draw_next_round(b, rng)
	_a(str(again) == str(drawn), "drawing twice returns the SAME pairing")

	# --- and the eventual play uses exactly those pairings ---------------------------
	var r2 := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
	_a(str(r2["label"]) == str(drawn["label"]),
		"the played round carries the drawn round's label")
	_a((b.get("pending_draw", {}) as Dictionary).is_empty(), "the pending draw is cleared")
	var ties: Array = (b["rounds"] as Array)[1]["ties"]
	var played_pairs: Array = []
	for t in ties:
		played_pairs.append([int((t as Dictionary)["home_id"]), int((t as Dictionary)["away_id"])])
	var drawn_pairs: Array = []
	var i := 0
	while i + 1 < players.size():
		drawn_pairs.append([int(players[i]), int(players[i + 1])])
		i += 2
	_a(str(played_pairs) == str(drawn_pairs),
		"the ties played are the ties drawn (%s)" % str(played_pairs))

	# --- the SORTEO plates follow the DRAWN round, not the last played one ------------
	Cup.draw_next_round(b, rng)
	var pd: Dictionary = b["pending_draw"]
	_a(Cup.draw_round_plate(b) == str(pd["label"]).to_upper()
			or Cup.draw_round_plate(b) == "QTR FINALS",
		"draw_round_plate names the drawn round ('%s')" % Cup.draw_round_plate(b))
	_a(Cup.draw_leg_plates(b) == ["MATCH", "REPLAY"],
		"a single-leg round shows MATCH / REPLAY")

	# --- a two-legged competition's drawn round shows the leg plates ------------------
	var lc := Cup.create(ids, 40, {"legs": 2, "name": "Coca-Cola Cup"})
	var rng2 := _rng()
	Cup.play_round(lc, rng2, _ratings_fn(), -1, _names_fn())
	Cup.draw_next_round(lc, rng2)
	_a(Cup.draw_leg_plates(lc) == ["1ST LEG", "2ND LEG"],
		"a two-legged drawn round shows 1ST LEG / 2ND LEG")

	# --- the Coca-Cola SEMIFINALS are two-legged (witnessed 1998-01-10, the SEMIFINALS
	# --- card view: 1ST LEG / 2ND LEG blocks with both clubs' own venues) while the
	# --- earlier rounds keep single-leg + replay and the final is a single match ------
	var cc := Cup.create(ids, 40, {"legs": 1, "semi_legs": 2, "name": "Coca-Cola Cup"})
	var rng4 := _rng()
	Cup.play_round(cc, rng4, _ratings_fn(), -1, _names_fn())       # R1: 16 -> 8
	var d8 := Cup.draw_next_round(cc, rng4)                        # QTR draw: 8 clubs
	_a(int(d8["round_legs"]) == 1, "semi_legs leaves the QTR single-leg")
	Cup.play_round(cc, rng4, _ratings_fn(), -1, _names_fn())       # QTR: 8 -> 4
	var d4 := Cup.draw_next_round(cc, rng4)                        # SEMI draw: 4 clubs
	_a(int(d4["round_legs"]) == 2, "semi_legs=2 makes the SEMIFINALS two-legged")
	_a(Cup.draw_leg_plates(cc) == ["1ST LEG", "2ND LEG"],
		"the drawn semis show 1ST LEG / 2ND LEG")
	Cup.play_round(cc, rng4, _ratings_fn(), -1, _names_fn())       # SEMI: 4 -> 2
	var semis: Dictionary = (cc["rounds"] as Array)[-1]
	_a(bool(((semis["ties"] as Array)[0] as Dictionary).get("two_legged", false)),
		"the played semis record two-legged ties")
	var d2 := Cup.draw_next_round(cc, rng4)                        # FINAL draw: 2 clubs
	_a(int(d2["round_legs"]) == 1, "the final stays a single match")
	# No stored field (no group stage) -> no neutral-venue pool -> -1, honestly absent.
	_a(int(d2.get("venue_id", -2)) == -1, "a domestic final records no neutral venue")

	# --- the FINAL's neutral ground: drawn from the competition's own field, never a
	# --- finalist's (the witnessed 1998 final ran at Das Antas -- neither finalist's;
	# --- the selection rule is un-reversed and the pick is declared OURS) -------------
	var eu := Cup.create(ids, 40, {"legs": 2, "name": "Euro. League",
		"group_stage": {"n_groups": 4, "advance": 2, "label": "1/8 FINALS"}})
	var rng5 := _rng()
	while int(eu.get("champion_id", -1)) == -1:
		var step := Cup.play_next(eu, rng5, _ratings_fn(), -1, _names_fn())
		if step.is_empty():
			break
	var final_rd: Dictionary = (eu["rounds"] as Array)[-1]
	var fvid := int(final_rd.get("venue_id", -1))
	_a(fvid >= 0, "a group-stage competition's final records a neutral venue")
	var f_home := int(((final_rd["ties"] as Array)[0] as Dictionary)["home_id"])
	var f_away := int(((final_rd["ties"] as Array)[0] as Dictionary)["away_id"])
	_a(fvid != f_home and fvid != f_away, "the neutral venue is NEITHER finalist's")

	# --- a finished competition draws nothing ----------------------------------------
	var small := Cup.create([1, 2], 40)
	var rng3 := _rng()
	Cup.play_round(small, rng3, _ratings_fn(), -1, _names_fn())
	_a(int(small["champion_id"]) != -1, "the two-club cup has a champion")
	_a((Cup.draw_next_round(small, rng3) as Dictionary).is_empty(),
		"a finished cup draws nothing")

	# --- a career plays a whole season with the split in place ------------------------
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_a(false, "game_db.json present")
		return _ok
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	var crng := RandomNumberGenerator.new()
	crng.seed = SEED
	# The SORTEO the hub raises must describe a round that has NOT been played: every card
	# queued during the season is checked against the bracket's own played rounds.
	var cards := 0
	var stale := 0
	while not career.season_over():
		career.advance_week(crng)
		for card in career.pending_cup_draws:
			cards += 1
			# Match the card to ITS OWN competition by title -- both cups run a "Round 3",
			# so pooling their played labels turns every one of them into a false positive.
			var owner: Dictionary = {}
			for cup in [career.fa_cup, career.league_cup]:
				if str(cup.get("name", "")) == str(card.get("title", "")):
					owner = cup
			var played: Array = []
			for rd in (owner.get("rounds", []) as Array):
				played.append(Cup.draw_round_plate({"rounds": [rd]}))
			# a card naming a round already in `rounds` is the old pair-and-play ordering
			if played.has(str(card.get("round", ""))) and int(card.get("total", 0)) > 0:
				stale += 1
				print("     stale card: %s %s (played %s)" % [card.get("title"), card.get("round"), str(played)])
		career.pending_cup_draws.clear()
	_a(cards > 0, "the season raised cup draws (%d)" % cards)
	_a(stale == 0, "no SORTEO named a round that was already played (%d stale)" % stale)
	for cup in [career.fa_cup, career.league_cup]:
		if cup.is_empty():
			continue
		var cname := str(cup.get("name", "?"))
		_a(int(cup.get("champion_id", -1)) != -1, "%s found a champion" % cname)
		_a((cup.get("pending_draw", {}) as Dictionary).is_empty(),
			"%s leaves no dangling draw at season end" % cname)

	print("\n%s" % ("ALL PASS" if _ok else "FAILURES ABOVE"))
	return _ok
