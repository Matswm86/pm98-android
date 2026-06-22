extends SceneTree
## Transcription parity test for Pm98Match.kickoff_init (the match KICKOFF / phase-init
## FUN_00593600 -- the sim-relevant tail callee of the asset loader FUN_005923f0). Run:
##   ~/godot462 --headless --path app --script res://tests/test_kickoff_init.gd
##
## Like test_match_init / test_driver there is no PCode-emu oracle (FUN_00593600 reads the
## session sub-object + globals + calls non-leaf resets), so this LOCKS what is decompile-
## exact and verifiable from the mutated Dict: the session link, the goal geometry, the
## pitch box (incl. the min/max ordering), the free-kick spot tables, the orientation
## fields, the phase = 2 / armed-gate / match-over scalars, the per-team active-idx reset,
## and -- the load-bearing prize -- that kickoff on the EMPTY skeleton draws the match RNG
## EXACTLY 4 times (kickoff side + 3 commentary timers; a missed/extra draw desyncs the
## seed kill-test). The 4 drawn values are checked against an independent reference Pm98Rng.

const U32 := 0xffffffff
const SEED := 0x12345678

# synthetic session / play-state object (binary: match+0x468), byte-offset keyed.
const PITCH_LEN := 0x6000000      # session+0x4c -> xscale = /2
const PITCH_WID := 0x4000000      # session+0x50 -> yscale = /2
const ORIENT_FD8 := 1             # session+0xfd8 -> +0x1984 = 3 - this
const ORIENT_FDC := 0             # session+0xfdc -> +0x1988 = 2 - this
const PITCH_TYPE := 2             # session+0xff4 -> DAT_00664060[2] = 0x5460

var _fail := 0
var _pass := 0


func _init() -> void:
	var session := {
		0x4c: PITCH_LEN, 0x50: PITCH_WID,
		0xfd0: 1, 0xfd4: 0, 0xfd8: ORIENT_FD8, 0xfdc: ORIENT_FDC, 0xff4: PITCH_TYPE,
	}
	# build the skeleton with a throwaway rng (the 1080 ctor draws are a separate stream),
	# then kickoff with a fresh seeded rng so the 4 kickoff draws are countable in isolation.
	var m := Pm98Match.build_match(MatchEngine.Pm98Rng.new(0xDEADBEEF))

	var live := MatchEngine.Pm98Rng.new(SEED)
	Pm98Match.kickoff_init(m, session, live)

	_check_link_and_geometry(m, session)
	_check_pitch_box(m)
	_check_freekick_tables(m)
	_check_orientation(m)
	_check_phase_and_gate(m)
	_check_team_reset(m)
	_check_rng_draws(m, live)
	_smoke_tick(m)

	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _eqx(got: int, want: int, msg: String) -> void:
	_ok((got & U32) == (want & U32), "%s: got 0x%x want 0x%x" % [msg, got & U32, want & U32])


func _g(m: Dictionary, off: int) -> int:
	return int(m.get(off, 0))


func _check_link_and_geometry(m: Dictionary, session: Dictionary) -> void:
	_ok(m.get(0x468) == session, "session link match+0x468")
	var xscale := PITCH_LEN / 2
	var yscale := PITCH_WID / 2
	_eqx(_g(m, 0x1820), xscale, "goal-X scale +0x1820")
	_eqx(_g(m, 0x1824), yscale, "goal-Y scale +0x1824")
	_eqx(_g(m, 0x1a40), 0xc66b14, "const +0x1a40")
	_eqx(_g(m, 0x194c), 0x190000, "freekick base +0x194c")
	_eqx(_g(m, 0x181e), 0x2000, "short +0x181e")
	_eqx(_g(m, 0x1940), 0xcccc, "const +0x1940")
	_eqx(_g(m, 0x1804), 0x1e0000, "const +0x1804")
	_eqx(_g(m, 0x1818), 0xf0000, "const +0x1818")
	# pitch-type table DAT_00664060[idx]
	_eqx(_g(m, 0x19ac), 0x5460, "pitch-type +0x19ac (DAT_00664060[2])")


func _check_pitch_box(m: Dictionary) -> void:
	# positive scales -> no swap: [-x, -y, z_lo, x, y, z_hi].
	var xscale := PITCH_LEN / 2
	var yscale := PITCH_WID / 2
	_eqx(_g(m, 0x1828), (-xscale) & U32, "box x_lo +0x1828")
	_eqx(_g(m, 0x182c), (-yscale) & U32, "box y_lo +0x182c")
	_eqx(_g(m, 0x1830), 0xffff0000, "box z_lo +0x1830")
	_eqx(_g(m, 0x1834), xscale, "box x_hi +0x1834")
	_eqx(_g(m, 0x1838), yscale, "box y_hi +0x1838")
	_eqx(_g(m, 0x183c), 0x3e80000, "box z_hi +0x183c")
	# pitch box must REPLACE the ctor's huge sentinels (build_match set +0x1828 = 0x70000000).
	_ok(_g(m, 0x1828) != 0x70000000, "pitch box overwrote ctor sentinel +0x1828")


func _check_freekick_tables(m: Dictionary) -> void:
	var x := PITCH_LEN / 2
	var y := PITCH_WID / 2
	_eqx(_g(m, 0x1950), (x + 0x230000) & U32, "+0x1950")
	_eqx(_g(m, 0x1954), (x + 0xf0000) & U32, "+0x1954")
	_eqx(_g(m, 0x195c), (x + 0x60000) & U32, "+0x195c")
	_eqx(_g(m, 0x1960), (y + 0x230000) & U32, "+0x1960")
	_eqx(_g(m, 0x196c), (y + 0x60000) & U32, "+0x196c")
	_eqx(_g(m, 0x1970), (x + 0xc0000) & U32, "+0x1970")
	_eqx(_g(m, 0x1974), (x + 0x40000) & U32, "+0x1974")
	_eqx(_g(m, 0x1978), (y + 0xc0000) & U32, "+0x1978")
	_eqx(_g(m, 0x197c), (y + 0x40000) & U32, "+0x197c")
	# +0x1814 = -(+0x1960)
	_eqx(_g(m, 0x1814), (-(y + 0x230000)) & U32, "+0x1814 = -(+0x1960)")


func _check_orientation(m: Dictionary) -> void:
	_eqx(_g(m, 0x1984), 3 - ORIENT_FD8, "+0x1984 = 3 - session+0xfd8")
	_eqx(_g(m, 0x1988), 2 - ORIENT_FDC, "+0x1988 = 2 - session+0xfdc")
	_eqx(_g(m, 0x1a1b), 1, "+0x1a1b = (session+0xfd0 != 0)")
	_eqx(_g(m, 0x1a1c), 0, "+0x1a1c = (session+0xfd4 != 0)")


func _check_phase_and_gate(m: Dictionary) -> void:
	_eqx(_g(m, 0x448), 2, "phase +0x448")
	_eqx(_g(m, 0x44c), 2, "phase +0x44c")
	_eqx(_g(m, 0x1a1e), 1, "armed skip-tick gate +0x1a1e")
	_eqx(_g(m, 0x180e), 1, "in-match flag +0x180e")
	_eqx(_g(m, 0x454), 0, "match-over counter +0x454 = 0 (NOT over)")
	_eqx(_g(m, 0x1a38), 0, "restart type +0x1a38 = 0")
	_eqx(_g(m, 0x1808), 1, "byte +0x1808")
	_eqx(_g(m, 0x1809), 1, "byte +0x1809")
	# headless display flags cleared
	_eqx(_g(m, 0x180a), 0, "display flag +0x180a")
	_eqx(_g(m, 0x180b), 0, "display flag +0x180b")
	_eqx(_g(m, 0x180c), 0, "display flag +0x180c")


func _check_team_reset(m: Dictionary) -> void:
	for ti in range(2):
		var team: Dictionary = m["sim"][ti]
		_eqx(int(team.get(0x168, -1)), 0, "team[%d] active idx +0x168 reset" % ti)
		_eqx(int(team.get(0xc, -1)), 0, "team[%d] +0xc reset" % ti)
		_eqx(int(team.get(0x10, -1)), 0, "team[%d] +0x10 reset" % ti)
		_eqx(int(team.get(0x14, -1)), 0, "team[%d] +0x14 reset" % ti)


func _check_rng_draws(m: Dictionary, live: MatchEngine.Pm98Rng) -> void:
	# Independent reference: the EXACT four FUN_005ec250 draws, in order.
	var ref := MatchEngine.Pm98Rng.new(SEED)
	var side := (ref.next() * 2) >> 15
	var t1 := (ref.next() * 900) >> 15
	var t2 := (ref.next() * 0xe10) >> 15
	var t3 := ((ref.next() * 0x960) >> 15) + 900
	_eqx(_g(m, 0x19c8), side, "kickoff side +0x19c8")
	_eqx(_g(m, 0x45c), side, "kickoff side mirror +0x45c")
	_eqx(_g(m, 0x19e4), t1, "commentary timer +0x19e4")
	_eqx(_g(m, 0x19e8), t2, "commentary timer +0x19e8")
	_eqx(_g(m, 0x19ec), t3, "commentary timer +0x19ec")
	# THE draw-count lock: kickoff advanced the live rng by EXACTLY 4 (== the reference).
	_ok(live.state == ref.state, "kickoff drew the match seed exactly 4x (state lockstep)")
	# kickoff side is a single bit; timers in their documented ranges.
	_ok(side == 0 or side == 1, "kickoff side in {0,1}")
	_ok(t1 >= 0 and t1 < 900, "timer1 in [0,900)")
	_ok(t2 >= 0 and t2 < 3600, "timer2 in [0,3600)")
	_ok(t3 >= 900 and t3 < 3300, "timer3 in [900,3300)")


## Integration smoke: a built + kicked-off skeleton is driver-tickable. With +0x1a1e armed
## the first tick runs restart_handler then returns continue (+0x454 == 0). No live players,
## so the movement core no-ops; this just asserts no crash + a valid 0/1 return.
func _smoke_tick(m: Dictionary) -> void:
	var r := MatchEngine.Pm98Rng.new(0x1111)
	var cont: int = Pm98Driver.tick(m, r)
	_ok(cont == 0 or cont == 1, "driver tick on kicked-off skeleton returns 0/1 (got %d)" % cont)
