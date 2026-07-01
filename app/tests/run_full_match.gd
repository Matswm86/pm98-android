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
## Honest scope: INPUT is SYNTHETIC (attributes + no real kickoff placement), so this proves
## the port RUNS deterministically end-to-end, NOT bit-for-bit parity vs MANAGER.EXE. The
## parity oracle (wine MANAGER.EXE or full PCode-emu) is plan M4. Goal harvesting reads the
## raw event queue per FRAME; in the live branch each frame is 1 tick so delay-2 events are
## always seen, but pause-branch multi-tick frames could consume events before harvesting --
## fine today (headless PS==1 never enters the pause branch), the M5 BRIEF tap hooks the
## dequeue fire point instead.
##
## Run: ~/godot462 --headless --path app --script res://tests/run_full_match.gd

const FRAME_CAP := 40000


func _init() -> void:
	_run(1)
	quit(0)


## A structurally-valid player attribute record (byte-keyed, the FUN_005a2830 input). role
## (rec[0x44]) must be != 0 to be "present"; attributes mid-range so players are non-degenerate.
func _rec(role: int, shirt: int, px: int, py: int) -> Dictionary:
	return {
		0x4: shirt,                                          # shirt / id (u16)
		0x8: px, 0xc: py, 0x10: px, 0x14: py,                # start positions (16.16)
		0x18: px, 0x1c: py, 0x20: px, 0x24: py,
		0x28: 0, 0x2c: 11, 0x30: 11,
		0x34: 60, 0x35: 60, 0x36: 60, 0x37: 60, 0x38: 60,    # 0xde..0xe2 attrs
		0x3c: 60, 0x3d: 60, 0x3e: 60, 0x3f: 60, 0x40: 65, 0x41: 60,   # 0xe3..0xe8
		0x42: 40,                                            # fitness
		0x44: role,                                          # demarcacion / role (present gate)
		0x98: 0,
	}


## 11 records for one team: slot 0 = GK (role 1), outfield roles 2..11 in a rough 4-4-2,
## start positions spread on a +/- half-pitch in 16.16 so they are not all at the origin.
func _lineup(team: int) -> Dictionary:
	var slots: Array = []
	var sgn := 1 if team == 0 else -1                        # team0 attacks +x, team1 -x
	var rows := [          # [role, x_m, y_m]
		[1, -45, 0],
		[2, -30, -20], [3, -30, -7], [4, -30, 7], [5, -30, 20],
		[6, -5, -22], [7, -5, -7], [8, -5, 7], [9, -5, 22],
		[10, 15, -10], [11, 15, 10],
	]
	for i in range(11):
		var r: Array = rows[i]
		slots.append(_rec(int(r[0]), team * 100 + i + 1, int(r[1]) * sgn * 0x10000, int(r[2]) * 0x10000))
	return {"header": [0, 0, 0, 0, 0, 0, 0, 0, 0], "slots": slots}


## A structurally-valid session / play-state object (binary: match+0x468).
func _session() -> Dictionary:
	return {
		0x4c: 0x680000,    # pitch length 104.0 -> xscale 52.0
		0x50: 0x440000,    # pitch width  68.0  -> yscale 34.0
		0xfd0: 0, 0xfd4: 0, 0xfd8: 0, 0xfdc: 0,              # orientation
		0xff4: 0,          # pitch-type index -> +0x19ac = 0x1c20 (7200)
		0xfa0: 1,          # play-state (1 = in play, not 0/4)
		0xfe8: 0, 0xfec: 0, 0xff0: 0,                        # display drivers (headless)
		# Pm98Dispatch._case_phase (+0x19a0 rung = kickoff count: 0=H1, 1=H2, 2=ET1, 3=ET2;
		# dispatch-1 threshold = +0x19ac for rungs 0/1, /3 for rungs 2/3 = 45/45/15/15 min).
		# session+0x44/+0x48 = extra-time/aggregate (cup) flags: BOTH 0 -> the rung-1 gate
		# ends the match at 90' (code 10 + event 0x20 FULL TIME) = a league match. Setting
		# 0x44=1 was empirically shown (2026-07-01) to play 45+45+15+15 into rung 3.
		0x14: 0, 0x20: 0, 0x24: 0, 0x44: 0, 0x48: 0,
	}


func _run(seed_: int) -> void:
	var rng := MatchEngine.Pm98Rng.new(seed_)

	var m := Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = _lineup(0)           # inject BEFORE kickoff_init
	(m["sim"][1] as Dictionary)[0x9c] = _lineup(1)
	Pm98Match.kickoff_init(m, _session(), rng)

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
