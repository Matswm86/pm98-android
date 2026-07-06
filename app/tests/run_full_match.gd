extends SceneTree
## STEP-5a HARNESS (port-side half of the kill-test; NOT an oracle lock): drive the PORT
## end-to-end -- Pm98Match.build_match -> kickoff_init (synthetic but structurally-valid
## lineup + session injected at team[0x9c]) -> loop Pm98Driver.tick() to match-over. This is
## the FIRST integration of the whole shell with a populated 22-player roster + the live
## movement core; the prior test_driver.gd only locked pure-scalar tick behaviour.
##
## RESULT (2026-06-22): runs 22 players, N ticks, ZERO crashes, construction draws == 1084
## (1080 noise + 4 kickoff), EXACTLY per spec. BUT the match stays in PHASE 2 (kickoff) forever
## -- 0:0. The 2026-06-23 wine trace (([[handoff-pm98-vtable-offset-rootcause-2026-06-23]])) found
## the off-by-4 vtable error behind the old "vtable+0x10 / no caller" story: the per-tick driver's
## +0xc ADVANCE pass (FUN_005b8c20) really dispatches FUN_005a4600 = the OPEN-PLAY ENGINE
## (Pm98Action.engine_tick), which reaches the resolver + the set_phase tails. engine_tick is now
## wired into Pm98Driver._advance_team (test_driver_advance_engine.gd proves a 0x1d kicker advances
## phase 2->1 through it).
##
## SUPERSEDED NOTES (kept as the record):
## * The "{2: N} forever" result predates the 06-23 vtable fix; since then the run reaches
##   open play (phase 0 by tick ~31).
## * The "setup_shot/resolve_post_shot leaves are still call_resolve=false stubs" claim was
##   STALE: all 8 handler sites in Pm98Action._action_switch pass call_resolve=true (cascade
##   oracle-GREEN via test_engine_cascade.gd). PROVEN 2026-07-01 by diag_match_states.gd:
##   P8 enters action 0x4 at t12, setup_shot writes 13 ball landings t31-44, the kickoff
##   kick moves the ball at t31. Still 0-0 because the shot is a minimum-power touch
##   (synthetic attributes, touch/power=min) and after t44 the two remaining movement
##   NO-OPs (_move_9490 lean; _move_65a0's non-taker open-play slice) leave every player
##   static, so nobody ever reaches a shooting state again.
##
## NOW (2026-07-01): drives Pm98Outer.step (FUN_005983f0, the per-frame step ABOVE the
## driver) instead of raw Pm98Driver.tick -- the outer step arms +0x1a1e on segment end
## (restart -> kickoff placement -> clock banked +0x19a8 += +0x450) and ends the match on
## dispatch code 10 (Pm98Dispatch._case_phase: +0x19a0-keyed half/full-time ladder at
## +0x450 > +0x19ac). Exit criteria (plan M2): clock advances organically, halves change,
## the match ends at code 10 -- NOT at a tick cap.
##
## s10 (2026-07-01, lean 9490 WIRED): the run now HITS THE CAP again -- H1 plays fully
## (phase 0 x 7200, clock banked at HT) but H2 sticks in phase 2. ROOT-CAUSED by
## diag_h2_stall.gd: restart_handler's kickoff PLACEMENT callees (FUN_0044d0d0/FUN_0044d190)
## are modeled as no-ops, so the restart's decide pass engages the taker ~46 m from the
## placed ball and the lean's Slice-A runaway gate correctly RELEASES it. The pre-wire
## FT-at-16005 baseline rode on stale H1 possession (nothing cleared owner/+0x54 without
## the lean). Fix = port the placement fns (plan M3 first item), NOT a lean revert.
##
## REAL INPUT (2026-07-07, plan M3 NEXT 2): the synthetic 4-4-2/_session builders are
## REPLACED by Pm98LineupFeeder -- the FUN_0044d5f0 port that builds both team[0x9c]
## lineups + the session from the exported .DBC data (game_db.json + club_tactics.json:
## real squads, real tactic slots, real stadium pitch dims, season-init FI 70 / cap 99).
## Fixture = Manchester Utd. (app id 40, Old Trafford 116x76) vs Liverpool (42) -- an
## arbitrary-but-pinned eng_prem pair (the fixture generator is not ported; the pair
## avoids the posFine-18 role-table edge: role 18 would index team[0x7f/0x80] past the
## zeroed 0x24-entry block, which the BINARY also overruns -- 114 shipped XIs carry an
## 18; MU/LIV max is 17). Session/lineup provenance: docs/re/session_lineup_re.md.
##
## Honest scope: squads/tactics/pitch/attrs are now REAL; kickoff PLACEMENT is still
## no-op-modeled (FUN_0044d0d0/FUN_0044d190, plan M3) and fitness/morale are season-init
## constants, so this is still NOT bit-for-bit parity vs MANAGER.EXE -- the parity oracle
## (wine MANAGER.EXE or full PCode-emu) is plan M4. Goal harvesting reads the raw event
## queue per FRAME; in the live branch each frame is 1 tick so delay-2 events are always
## seen, but pause-branch multi-tick frames could consume events before harvesting --
## fine today (headless PS==1 never enters the pause branch), the M5 BRIEF tap hooks the
## dequeue fire point instead.
##
## RESULT (2026-07-07, seed 1, REAL squads): FULL TIME code 10 at frame 15212, minute 90,
## halves {0: 7966, 1: 7246}, phases {2: 92, 0: 14400, 8: 720}, dispatch {1: 719, 10: 1},
## score 0-0, kickoff draws 1084, final rng state 276518391 -- IDENTICAL across 2 runs
## (deterministic). 0-0 persists pending the M3 kickoff-taker decision port.
##
## Run: ~/godot462 --headless --path app --script res://tests/run_full_match.gd

const FRAME_CAP := 40000
const HOME_ID := 40                                          # Manchester Utd. (eng_prem)
const AWAY_ID := 42                                          # Liverpool (eng_prem)


func _init() -> void:
	_run(1)
	quit(0)


func _run(seed_: int) -> void:
	var rng := MatchEngine.Pm98Rng.new(seed_)

	var data := Pm98LineupFeeder.load_data()
	var input := Pm98LineupFeeder.build(HOME_ID, AWAY_ID, data)
	print("real input: home=%s away=%s  pitch=%dx%d (16.16 %x/%x)" % [
		(data["clubs"][HOME_ID] as Dictionary)["name"],
		(data["clubs"][AWAY_ID] as Dictionary)["name"],
		int((input["session"] as Dictionary)[0x4c]) >> 16,
		int((input["session"] as Dictionary)[0x50]) >> 16,
		(input["session"] as Dictionary)[0x4c], (input["session"] as Dictionary)[0x50]])

	var m := Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = (input["lineups"] as Array)[0]  # inject BEFORE kickoff_init
	(m["sim"][1] as Dictionary)[0x9c] = (input["lineups"] as Array)[1]
	Pm98Match.kickoff_init(m, input["session"], rng)

	var built0: int = ((m["sim"][0] as Dictionary).get("players", []) as Array).size()
	var built1: int = ((m["sim"][1] as Dictionary).get("players", []) as Array).size()
	print("seed=%d  players built: team0=%d team1=%d" % [seed_, built0, built1])
	print("post build/kickoff: rng draws=%d  state=%d" % [_rng_draw_count(seed_, rng.state), rng.state])

	var goals := [0, 0]
	var disp := {}
	var phase_hist := {}
	var halves := {}
	var over_at := -1
	var t := 0
	while t < FRAME_CAP:
		var cont := Pm98Outer.step(m, rng)               # FUN_005983f0 (one frame)
		_harvest_goals(m, goals)
		var ph: int = Pm98Driver._g(m, 0x448)
		phase_hist[ph] = int(phase_hist.get(ph, 0)) + 1
		halves[Pm98Driver._g(m, 0x19a0)] = int(halves.get(Pm98Driver._g(m, 0x19a0), 0)) + 1
		var code: int = Pm98Driver._g(m, 0x1a38)
		if code != 0:
			disp[code] = int(disp.get(code, 0)) + 1
		t += 1
		if Pm98Driver._g(m, 0x1a38) == 10:               # full time (dispatch case-1 -> 10)
			over_at = t
			break
		if not cont and Pm98Driver._g(m, 0x1a19) != 0:
			break                                        # UI abort (never headless)

	var minute := 0
	if Pm98Driver._g(m, 0x19ac) != 0:
		minute = ((Pm98Driver._g(m, 0x19a8) + Pm98Driver._g(m, 0x450)) * 0x2d) / Pm98Driver._g(m, 0x19ac)
	print("frames run       = %d%s" % [t, "  (FULL TIME code 10)" if over_at > 0 else "  (HIT CAP)"])
	print("clock            = minute %d  (+0x450=%d banked +0x19a8=%d scale +0x19ac=%d)" % [
		minute, Pm98Driver._g(m, 0x450), Pm98Driver._g(m, 0x19a8), Pm98Driver._g(m, 0x19ac)])
	print("half counter     = %s  (+0x19a0 histogram)" % str(halves))
	print("final score      = team0 %d : %d team1" % [goals[0], goals[1]])
	print("phase histogram  = %s" % str(phase_hist))
	print("dispatch freezes = %s" % str(disp))
	print("queue length end = %d" % (m.get(0x1a24, []) as Array).size())
	print("final rng state  = %d" % rng.state)
	print("DONE")


## Count code-7 (goal) / 8 (own-goal) records in the match queue, attribute to the scoring
## team (record[1] == player+0x2b8 == team index), and mark consumed (negate) so each counts once.
func _harvest_goals(m: Dictionary, goals: Array) -> void:
	for ev in (m.get(0x1a24, []) as Array):
		var c := int(ev[0])
		if c == 7 or c == 8:
			var team := int(ev[1])
			if team == 0 or team == 1:
				goals[team] += 1
			ev[0] = -c


## How many next() calls move seed_'s fresh stream to `target_state` (<= 4000 search).
func _rng_draw_count(seed_: int, target_state: int) -> int:
	var ref := MatchEngine.Pm98Rng.new(seed_)
	for n in range(0, 4001):
		if ref.state == target_state:
			return n
		ref.next()
	return -1
