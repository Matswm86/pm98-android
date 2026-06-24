extends SceneTree
## Verifies the ROOT-CAUSE FIX (live-confirmed via wine trace --
## [[handoff-pm98-vtable-offset-rootcause-2026-06-23]]): the per-tick driver ADVANCE pass
## `Pm98Driver._advance_team` (the FUN_005b8c20 / player vtable+0xc loop) now dispatches
## `Pm98Action.engine_tick` (FUN_005a4600, the per-player OPEN-PLAY ENGINE), NOT the replay
## no-op `Pm98Movement.advance` (FUN_005a4560) the off-by-4 vtable map wrongly attributed there.
##
## WHY THIS IS THE DECISIVE CHECK: the no-op advance can NEVER write the match phase. engine_tick
## CAN: a player in the 0x1d kick-release state (action +0x40 == 0x1d, windup timer +0x48 == 0)
## drives tick_action (FUN_005a50c0) into its kick-release tail, which calls set_phase(m, 1)
## UNCONDITIONALLY. So observing phase 2 -> 1 through _advance_team is positive proof the +0xc pass
## now runs the scoring engine. (Reaching open-play phase 0 additionally needs resolve_post_shot's
## set_phase(0) -- the handler cascade, Task #4b item 4 -- plus real kickoff placement so a taker
## enters 0x1d organically; that is the documented remaining gap, NOT this wiring.)
##
## Run: ~/godot462 --headless --path app --script res://tests/test_driver_advance_engine.gd

var _fail := 0
var _pass := 0


func _init() -> void:
	_t_kick_release_advances_phase()
	_t_walking_player_inert()
	_t_engine_tick_actually_ran()
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


## A minimal kickoff-phase match (+0x448 == 2) and one player. engine_tick reads everything else
## via _g (default 0) / _ref (default {}), so only the load-bearing fields are set.
func _match() -> Dictionary:
	return {0x448: 2, 0x44c: 0}


## A player in the 0x1d kick-release state: action 0x1d, windup timer +0x48 == 0 (t==0 path),
## on-pitch flag +0x2bc == 0. Refs link to the supplied match + empty ball/gs.
func _kicker(m: Dictionary) -> Dictionary:
	return {
		0x40: 0x1d, 0x48: 0, 0x2bc: 0, 0x34: 0,
		0x4: 0, 0x8: 0, 0xc: 0, 0x3a4: 0, 0x88: 0, 0x80: 0, 0x84: 0,
		0x18c: m, 0x190: {}, 0x184: {},
	}


## A walking player (action 2) with its action timer locked (+0x48 == 5): tick_action just counts
## the timer down; no phase write, no rng. The phase-inert baseline.
func _walker(m: Dictionary) -> Dictionary:
	return {
		0x40: 2, 0x48: 5, 0x2bc: 0, 0x34: 0,
		0x4: 0, 0x8: 0, 0xc: 0, 0x3a4: 0, 0x88: 0, 0x80: 0, 0x84: 0,
		0x18c: m, 0x190: {}, 0x184: {},
	}


## POSITIVE: a kicking player drives _advance_team -> engine_tick -> set_phase(1). 2 -> 1.
func _t_kick_release_advances_phase() -> void:
	var m := _match()
	var ctx := {"players": [_kicker(m)]}
	var rng := MatchEngine.Pm98Rng.new(1)
	_ok(Pm98Driver._g(m, 0x448) == 2, "precondition: phase starts at kickoff (2)")
	Pm98Driver._advance_team(ctx, m, rng)
	_ok(Pm98Driver._g(m, 0x448) == 1,
		"kick-release through _advance_team advances phase 2 -> 1 (got %d)" % Pm98Driver._g(m, 0x448))
	# the 0x1d kick-release bracket is net-zero headless -> no rng consumed.
	_ok(rng.state == MatchEngine.Pm98Rng.new(1).state, "kick-release draws no rng")


## NEGATIVE control: a walking player leaves the phase untouched (engine_tick is not a blanket
## phase-setter -- only the kicking path writes phase). Guards against a false positive.
func _t_walking_player_inert() -> void:
	var m := _match()
	var ctx := {"players": [_walker(m)]}
	var rng := MatchEngine.Pm98Rng.new(1)
	Pm98Driver._advance_team(ctx, m, rng)
	_ok(Pm98Driver._g(m, 0x448) == 2,
		"walking player leaves phase at 2 (got %d)" % Pm98Driver._g(m, 0x448))


## engine_tick must have actually RUN on the walker (not skipped): tick_action decrements the locked
## action timer +0x48 (5 -> 4) every tick. A no-op advance would leave +0x48 == 5.
func _t_engine_tick_actually_ran() -> void:
	var m := _match()
	var p := _walker(m)
	var ctx := {"players": [p]}
	Pm98Driver._advance_team(ctx, m, MatchEngine.Pm98Rng.new(1))
	_ok(Pm98Driver._g(p, 0x48) == 4,
		"engine_tick ran: locked action timer +0x48 counted 5 -> 4 (got %d)" % Pm98Driver._g(p, 0x48))


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: %s" % msg)
