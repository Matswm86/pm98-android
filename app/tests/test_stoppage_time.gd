extends SceneTree
## STOPPAGE TIME -- the period-end rung of FUN_00598740, pinned.
##
## The M5 record listed "stoppage time" as unrun. It is not unmodelled: the whole rule is
## the second half of `Pm98Driver._buildup_branch`, and it is a straight transcription of
## `docs/re/sim/fn_00598740_FUN_00598740.c` L595-606:
##
## ```
##   iVar19 = *(int *)(param_1 + 0x19a0);                 // the phase / period index
##   if (3 < iVar19) goto default;                        // penalties: no period end here
##   iVar12 = *(int *)(param_1 + 0x19ac);                 // the period length in ticks
##   iVar10 = iVar12;
##   if (1 < iVar19) { iVar10 = iVar12 / 3; }             // extra time is a THIRD as long
##   iVar10 = *(int *)(param_1 + 0x450) - iVar10;         // elapsed past the whistle
##   if ((iVar10 < 0) ||
##      (( |*(int *)(param_1 + 0x1614)| >= *(int *)(param_1 + 0x1820) - 0x1e0000
##         && (iVar10 <= iVar12 / 9))))  goto default;    // <-- STOPPAGE TIME
##   ... FUN_005966d0(1)                                  // end the period
## ```
##
## So the period does NOT end on the whistle. It ends at the first evaluation after the
## whistle at which EITHER the ball has left the 0x1e0000 (30 m) band in front of a goal
## OR `half/9` ticks have run out -- five minutes at the shipped 45-minute period
## (14400 / 9 = 1600 ticks, 1600 * 0x2d / 14400 = 5'). That is stoppage time, with the
## original's own two rules: it is granted only for an attack near a goal, and it is
## capped.
##
## The one DECLARED substitution: the binary reads the ball ANCHOR `matchctx+0x1614`, a
## display field this port does not carry (`Pm98LiveMatch` §2 declares the same
## substitution for the camera), so the port reads the ball object's own x. Named here
## rather than hidden, and it is the field that anchor tracks.
##
## Run: godot4 --headless --path app --script res://tests/test_stoppage_time.gd

const HALF := 0x3840          # PITCH_TYPE_TABLE[1] -- the shipped 45-minute period
const HALF_LEN := 3801088     # Old Trafford's +0x1820 (116 m / 2 in 16.16)
const BAND := 0x1e0000        # 30 m, the attacking band the whistle is held for

var _fail := 0
var _pass := 0


func _init() -> void:
	# --- the four rungs, one fixture each -----------------------------------------
	# 1. before the whistle: no period end, wherever the ball is.
	_case("clk below the period length -> play on", HALF - 1, 0, _ball_x_midfield(), false)
	_case("clk below the period length, ball at goal -> play on",
		HALF - 1, 0, _ball_x_in_band(), false)

	# 2. ON the whistle with the ball in MIDFIELD -> the period ends at once.
	_case("whistle, ball in midfield -> period ends", HALF, 0, _ball_x_midfield(), true)

	# 3. ON the whistle with the ball INSIDE the 30 m band -> stoppage time, play on.
	_case("whistle, ball in the 30 m band -> stoppage time", HALF, 0, _ball_x_in_band(), false)
	_case("whistle, ball in the 30 m band at the OTHER end -> stoppage time",
		HALF, 0, -_ball_x_in_band(), false)

	# 4. the CAP: half/9 = 1600 ticks = five minutes, and not one tick more.
	_case("stoppage at the cap, ball still attacking -> play on",
		HALF + HALF / 9, 0, _ball_x_in_band(), false)
	_case("one tick past the cap -> period ends even mid-attack",
		HALF + HALF / 9 + 1, 0, _ball_x_in_band(), true)

	# --- the EXTRA-TIME period is a THIRD as long, and keeps the SAME cap ----------
	# iVar10 = iVar12 / 3 fires for phase 2 and 3; the cap divisor stays iVar12 / 9, so
	# extra time's grace is the same 1600 ticks against a 4800-tick period.
	_case("extra time: whistle at half/3, midfield -> period ends",
		HALF / 3, 2, _ball_x_midfield(), true)
	_case("extra time: whistle at half/3, in band -> stoppage time",
		HALF / 3, 2, _ball_x_in_band(), false)
	_case("extra time: cap is still half/9 past its own whistle",
		HALF / 3 + HALF / 9 + 1, 3, _ball_x_in_band(), true)

	# --- phase > 3 is PENALTIES: this rung never fires there -----------------------
	_case("penalties (phase 4) -> the period-end rung is skipped",
		HALF * 4, 4, _ball_x_midfield(), false)

	# --- the numbers themselves, so a future change to the table is caught ---------
	_eq(HALF / 9, 1600, "the stoppage cap in ticks")
	_eq((HALF / 9) * 0x2d / HALF, 5, "the stoppage cap in MINUTES")
	_eq(Pm98Match.PITCH_TYPE_TABLE[1], HALF, "the shipped period length")

	print("STOPPAGE TIME: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


## A ball x safely outside the 30 m band (the centre spot).
func _ball_x_midfield() -> int:
	return 0


## A ball x inside the band: |x| >= half_len - 0x1e0000.
func _ball_x_in_band() -> int:
	return HALF_LEN - BAND + 1


## Build a minimal match, run the buildup branch once, and report whether the period
## ended (the branch's only observable: it dispatches outcome 1, which `_case_phase`
## resolves and `dispatch` writes to +0x1a38 while stamping +0x19d4).
func _ended(clk: int, phase: int, ball_x: int) -> bool:
	var team: Dictionary = {0x44: 0, 0x48: 0}    # no aggregate, no extra time armed
	var ball: Dictionary = {4: ball_x, 8: 0, 0xc: 0}
	var m: Dictionary = {
		0x19a0: phase, 0x19ac: HALF, 0x450: clk, 0x1820: HALF_LEN,
		0x19c8: 0, 0x468: team, 0x1a38: 0, 0x19d4: 0, 0x454: 0,
		0x1a24: [], "ball": ball,
	}
	Pm98Driver._buildup_branch(m, MatchEngine.Pm98Rng.new(1), ball)
	return int(m.get(0x19d4, 0)) != 0


func _case(label: String, clk: int, phase: int, ball_x: int, want_end: bool) -> void:
	var got := _ended(clk, phase, ball_x)
	_ok(got == want_end, "%s (clk=%d phase=%d ball_x=%d -> ended=%s, want %s)" % [
		label, clk, phase, ball_x, got, want_end])


func _eq(got: int, want: int, label: String) -> void:
	_ok(got == want, "%s: %d (want %d)" % [label, got, want])


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %s" % msg)
