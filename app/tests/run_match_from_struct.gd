extends SceneTree
## M5 KILL-TEST (plan docs/re/PLAN_byte_exact_match_engine.md §M5): drive the recovered
## Pm98* engine from the REAL MANAGER.EXE frame-0 memory dump and check it reproduces the
## captured match bit-for-bit at the scoreline/goal-timing level.
##
## Reference: ~/MWM-AI/data/pm98-m4-oracle/capture2/ (Aston Villa 5-2 Bolton W, WATCH
## preseason friendly at Villa Park, frame-0 seed 0xea0d2a8d). Built from the FULL 296-region
## dump by tools/re/wine/m4_struct_import.py -> frame0_struct_import.json (86 match scalars,
## 22 players w/ full dword images, session, 2 team headers, ball/keeper/ref bodies).
##
## WHAT THIS DOES (byte-load, NOT self-generation):
##  1. build_match(throwaway_rng) for the byte-exact SKELETON (vtables, sub-object ctors,
##     cross-ref wiring) -- the 1080 noise draws land on the throwaway rng, NOT the match seed
##     (the dump was captured AFTER the asset loader already consumed them; the frame-0 seed
##     0xea0d2a8d is the state ready for the first outer step).
##  2. OVERRIDE every leaf from the dump: match scalars, session, the 22 players (dword image +
##     native-width engine fields), and the two team headers (score, active idx, the
##     0x4f active / 0x5b role pointer tables resolved to the loaded player objects, the
##     0xbf..0xc7 squad header, the 0x2ec part-strength byte). Cross-refs (player 0x184 own /
##     0x188 opp / 0x18c match / 0x190 ball) are rebuilt as GDScript object refs.
##     team[0x9c] is left UNSET so the step-1 restart uses the loaded players in place rather
##     than rebuilding from a lineup source (the XI is already byte-identical; _build_player is
##     RNG-neutral, so skipping the in-place rebuild does not perturb the seed).
##     Ball/keeper/referee interiors are the build_match ctor objects (frame-0-equivalent: the
##     step-1 restart re-places them via ball_/keeper_restart_decide), so the emitted bodies are
##     not byte-substituted -- documented in m4_struct_import.read_body.
##  3. rng.state = 0xea0d2a8d, then loop Pm98Outer.step to dispatch code 10 (full time).
##     The real session play-state (0xfa0=4, WATCH) routes step through the pause/watch branch,
##     whose wait-frame loop breaks on each priority event (a goal sets +0x1a2c) -- so each step
##     returns AT a goal, letting the harness read that goal's clock (+0x450), banked (+0x19a8)
##     and half (+0x19a0) exactly as m4_poll.py logged them off /proc/<pid>/mem.
##  4. Goal detection = the running per-team score m+0x478 / m+0x798 (Pm98Driver L397 increments
##     these flat keys; they are never reset by the port so they ARE the scoreline).
##
## PASS iff scoreline 5-2 AND per-goal (minute, team) AND FT dispatch 10 reproduce.
## A divergence localises via the goal clk/seed columns (placement vs tick vs resolver).
##
## Run: ~/godot462 --headless --path app --script res://tests/run_match_from_struct.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const REF_JSON := REF_DIR + "/m5_reference_villa_bolton_5_2.json"
const FRAME0_SEED := 0xea0d2a8d
const STEP_CAP := 60000
const STRIDE := 0x3bc


func _init() -> void:
	var ok := _run()
	quit(0 if ok else 1)


func _run() -> bool:
	var dump := _load_json(STRUCT_JSON)
	var ref := _load_json(REF_JSON)
	if dump.is_empty():
		push_error("could not load %s" % STRUCT_JSON)
		return false

	# ---- 1. skeleton (throwaway rng absorbs the 1080 ctor noise draws) --------------------
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)

	# ---- 2a. match scalars -----------------------------------------------------------------
	for k in (dump["match"] as Dictionary):
		m[_hx(k)] = int((dump["match"] as Dictionary)[k])

	# ---- 2b. session (byte-offset keyed; drop _va) -> m[0x468] ------------------------------
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va":
			continue
		session[_hx(k)] = int((dump["session"] as Dictionary)[k])
	# DIAGNOSTIC ONLY: PM98_FORCE_PS overrides the loaded play-state (+0xfa0). The faithful
	# byte-load keeps the dumped 4 (WATCH -> pause branch); forcing 1 routes the validated
	# LIVE branch to localize whether an early goal is engine-deep or pause-branch-specific.
	var force_ps := OS.get_environment("PM98_FORCE_PS")
	if force_ps != "":
		session[0xfa0] = force_ps.to_int()
		print("[DIAG] play-state +0xfa0 forced to %d" % session[0xfa0])
	m[0x468] = session

	# ---- 2c. the 22 players (dword image + native fields + rebuilt cross-refs) --------------
	var ball: Dictionary = m["ball"]
	var teams: Array = m["sim"]
	var built := [[], []]
	for ti in range(2):
		var own: Dictionary = teams[ti]
		var opp: Dictionary = teams[1 - ti]
		for src in ((dump["players"] as Array)[ti] as Array):
			var p := _load_player(src as Dictionary, own, opp, m, ball)
			(built[ti] as Array).append(p)

	# ---- 2d. team headers ------------------------------------------------------------------
	for ti in range(2):
		_load_team_header(teams[ti] as Dictionary, (dump["team_headers"] as Array)[ti] as Dictionary,
			built[ti] as Array, ti, m)

	# ---- 3. seed + drive -------------------------------------------------------------------
	var rng := MatchEngine.Pm98Rng.new(0)
	rng.state = FRAME0_SEED

	print("== M5 byte-load kill-test ==")
	print("loaded: %d+%d players  match_scalars=%d  seed=0x%08x  scale(+0x19ac)=%d  phase(+0x448)=%d  playstate(+0xfa0)=%d" % [
		(built[0] as Array).size(), (built[1] as Array).size(),
		(dump["match"] as Dictionary).size(), rng.state,
		_g(m, 0x19ac), _g(m, 0x448), int(session.get(0xfa0, -1))])

	var goals: Array = []
	var prev := [_g(m, 0x478), _g(m, 0x798)]
	var over_at := -1
	var t := 0
	while t < STEP_CAP:
		Pm98Outer.step(m, rng)
		t += 1
		var cur := [_g(m, 0x478), _g(m, 0x798)]
		for team in range(2):
			while cur[team] > (prev[team] as int):
				prev[team] = int(prev[team]) + 1
				var gd := _snap(m, rng, team)
				goals.append(gd)
				print("  GOAL step=%d  %d' %s  %d-%d  clk=%d banked=%d half=%d rng=%d" % [
					t, gd["minute"], gd["team_name"], cur[0], cur[1], gd["clk"], gd["banked"], gd["half"], gd["rng"]])
		if t % 2000 == 0:
			print("  ..step=%d  min=%d (clk=%d bank=%d half=%d ph=%d)  score=%d-%d  disp=%d" % [
				t, ((_g(m, 0x19a8) + _g(m, 0x450)) * 0x2d) / max(1, _g(m, 0x19ac)),
				_g(m, 0x450), _g(m, 0x19a8), _g(m, 0x19a0), _g(m, 0x448), cur[0], cur[1], _g(m, 0x1a38)])
		if _g(m, 0x1a38) == 10:
			over_at = t
			break

	# ---- 4. report + compare ---------------------------------------------------------------
	print("\nsteps run        = %d%s" % [t, "  (FULL TIME dispatch 10)" if over_at > 0 else "  (HIT CAP -- no full time)"])
	print("final score      = Villa(team0) %d : %d Bolton(team1)" % [_g(m, 0x478), _g(m, 0x798)])
	print("ft clk/banked    = +0x450=%d  +0x19a8=%d  half +0x19a0=%d  rng=%d" % [
		_g(m, 0x450), _g(m, 0x19a8), _g(m, 0x19a0), rng.state])
	print("\n  #  minute  team          clk   banked  half   rng.state")
	for i in range(goals.size()):
		var gd: Dictionary = goals[i]
		print("  %d   %3d'   %-11s  %5d  %5d    %d    %d" % [
			i + 1, gd["minute"], gd["team_name"], gd["clk"], gd["banked"], gd["half"], gd["rng"]])

	return _compare(goals, over_at, m, ref)


## Snapshot a goal at the instant Pm98Outer.step returned (score just incremented for `team`).
func _snap(m: Dictionary, rng: MatchEngine.Pm98Rng, team: int) -> Dictionary:
	var banked := _g(m, 0x19a8)
	var clk := _g(m, 0x450)
	var scale := _g(m, 0x19ac)
	var minute := ((banked + clk) * 0x2d) / scale if scale != 0 else 0
	return {
		"minute": minute, "clk": clk, "banked": banked, "half": _g(m, 0x19a0),
		"team": team, "team_name": "Aston Villa" if team == 0 else "Bolton W", "rng": rng.state,
	}


## Reconstruct one player Dict: full dword image (aligned) overlaid with the native-width
## engine fields (adds the sub-dword byte/word keys the port reads), then the cross-refs.
func _load_player(src: Dictionary, own: Dictionary, opp: Dictionary,
		m: Dictionary, ball: Dictionary) -> Dictionary:
	var p := {}
	for k in (src["dwords"] as Dictionary):
		p[_hx(k)] = int((src["dwords"] as Dictionary)[k])
	for k in src:
		if k == "dwords" or k == "_va":
			continue
		p[_hx(k)] = int(src[k])
	p[0x184] = own                       # own team header
	p[0x188] = opp                       # opponent team header
	p[0x18c] = m                         # match
	p[0x190] = ball                      # ball (match+0x1610)
	return p


func _load_team_header(team: Dictionary, hdr: Dictionary, players: Array, ti: int, m: Dictionary) -> void:
	team[0x0] = players                  # *param_1 = player-array base
	team[0x4] = players.size()           # param_1[1] = count
	team["players"] = players            # ctx["players"] (movement roster view)
	team[0x8] = ti                       # ctx team index
	team[0x138] = m                      # ctx -> match
	team[0xc] = int(hdr["score_0xc"])    # team[0xc] score copy
	team[0x168] = int(hdr["active_idx_0x168"])
	# active table team[0x4f+slot] -> loaded player object (or 0):
	var act: Array = hdr["active_table"]
	for slot in range(act.size()):
		team[0x4f + slot] = players[int(act[slot])] if act[slot] is float or act[slot] is int else 0
	# role table team[0x5b+k] -> loaded player object (or 0):
	var rol: Array = hdr["role_table"]
	for k in range(rol.size()):
		team[0x5b + k] = players[int(rol[k])] if rol[k] is float or rol[k] is int else 0
	# squad header team[0xbf..0xc7]:
	var sh: Array = hdr["squad_header"]
	for k in range(sh.size()):
		team[0xbf + k] = int(sh[k])
	team[0x2e0] = int(hdr["0x2e0"])      # relationship-matrix throttle (word 0xb8)
	team[0x2ec] = int(hdr["0x2ec"])      # byte part-strength flag
	team[0x2ed] = int(hdr["0x2ed"])
	team[0x20c] = int(hdr["0x20c"])


func _compare(goals: Array, over_at: int, m: Dictionary, ref: Dictionary) -> bool:
	if ref.is_empty():
		print("\n(no reference JSON -- report only)")
		return over_at > 0
	var ref_goals: Array = ref["goals"]
	var res: Dictionary = ref["result"]
	var fails: Array = []

	var got := [_g(m, 0x478), _g(m, 0x798)]
	var want_final: String = res["final"]
	if got[0] != 5 or got[1] != 2:
		fails.append("scoreline %d-%d != 5-2 (%s)" % [got[0], got[1], want_final])
	if over_at <= 0:
		fails.append("no FULL TIME dispatch 10 reached")

	if goals.size() != ref_goals.size():
		fails.append("goal count %d != %d" % [goals.size(), ref_goals.size()])
	var n: int = min(goals.size(), ref_goals.size())
	for i in range(n):
		var g: Dictionary = goals[i]
		var r: Dictionary = ref_goals[i]
		var rteam := 0 if str(r["team"]).begins_with("Aston") else 1
		if int(g["team"]) != rteam or int(g["minute"]) != int(r["minute"]):
			fails.append("goal %d: got %d' team%d, want %d' team%d (%s)" % [
				i + 1, int(g["minute"]), int(g["team"]), int(r["minute"]), rteam, r["score"]])

	print("\n== VERDICT ==")
	if fails.is_empty():
		print("PASS -- scoreline 5-2, %d goals with matching (minute,team), FULL TIME dispatch 10." % goals.size())
		return true
	print("FAIL (%d):" % fails.size())
	for f in fails:
		print("  - %s" % f)
	# diagnostic: seed at goal 1 vs reference (localises first divergence)
	if goals.size() >= 1 and ref_goals.size() >= 1:
		print("  goal-1 rng.state got=%d  ref seed_at=%s" % [int((goals[0] as Dictionary)["rng"]), str((ref_goals[0] as Dictionary)["seed_at"])])
	return false


func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


func _hx(k) -> int:
	return (k as String).hex_to_int()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
