class_name Pm98LiveMatch
extends RefCounted
## THE M5 WIRE-IN: the instruction-exact POSITIONAL engine, playing a real career fixture
## frame by frame, with its per-tick player and ball coordinates exposed to a view.
##
## ## Which engine plays which match — read this before "wiring MatchSim to M5"
##
## Premier Manager 98 ships **two** match engines and picks between them inside ONE
## function, on the session play-state (`docs/re/stat_match_engine_re.md`; the branch is
## `FUN_0044ee70` L128 `if (local_1c[1000] != 5)`, i.e. `session+0xfa0 != 5`):
##
## | play-state | engine | who uses it |
## |---|---|---|
## | `!= 5` | the POSITIONAL sim — 22 players, ball physics, the `FUN_00598740` tick driver | a match the manager WATCHES |
## | `== 5` | the STATISTICAL instant-result sim — pure `rand()` + integer arithmetic | every match he does NOT watch |
##
## So the app's existing played path is **already the original's own engine**:
## `MatchSim.simulate` routes to `Pm98StatMatch`, the byte-exact port of that `PS == 5`
## branch, for every fixture. Replacing it with the positional engine would make the port
## LESS faithful, not more, and the old worry that the positional engine is "too slow for
## instant fixture results" is moot — the original never uses it for them either.
##
## What was genuinely missing is THIS: the engine the original runs when you watch. That is
## what this class provides, and `MatchSimulador` (the WATCH view) is its consumer.
##
## ## Fidelity status
##
## The engine underneath is byte-exact against live-silicon captures over clk 1..2836
## (1,072,592 words across nine banked captures, zero mismatches — `M5_S59_FRONTIER_2836.md`)
## and plays a full 90 minutes organically from real squads. Past clk 2836 it is unverified,
## and the deferred leaves listed in `M5_S59_FRONTIER_2836.md` §Open will surface at their
## first live set piece. That is stated, not hidden: a watched match is the exact engine as
## far as it has been proven and the same engine's own continuation after that.
##
## ## Coordinate space (measured, `diag_live_coords.gd`)
##
## Positions are 16.16 fixed point about the CENTRE spot. `match+0x1820` is half the pitch
## length and `match+0x1824` half its width (for Old Trafford, 116x76 m: 3801088 = 116<<16/2
## and 2490368 = 76<<16/2), so `nx`/`ny` below are those halves normalised to 0..1. Ball
## `+0xc` is height and reaches ~321000 (≈4.9 m) on a lofted ball.

## One outer frame = one `Pm98Outer.step`. A full match measured 18,458 of them.
const FULL_TIME_DISPATCH := 10
const FRAME_CAP := 40000

var match_state: Dictionary = {}
var rng: MatchEngine.Pm98Rng = null
var home_id := -1
var away_id := -1
## [{minute, team, slot}] in the order the engine raised them.
var goals: Array = []
var score := [0, 0]
var frames := 0
var over := false

## [home XI names, away XI names] — display only (the WATCH view prints the ball carrier's).
var names: Array = []
var _ball: Dictionary = {}
var _half_len := 1
var _half_wid := 1


## Build a live match for two game_db club ids. `lever_overrides` / `marking_overrides` /
## `line_overrides` are `Pm98LineupFeeder.build`'s live-career hooks — the manager's own
## TEAM TACTICS levers and MAN-TO-MAN table reach the engine through them, exactly as the
## original's career layer feeds its own club's stored bytes.
static func create(home: int, away: int, seed_: int, lever_overrides: Dictionary = {},
		marking_overrides: Dictionary = {}, line_overrides: Dictionary = {}) -> Pm98LiveMatch:
	var live := Pm98LiveMatch.new()
	live.home_id = home
	live.away_id = away
	live.rng = MatchEngine.Pm98Rng.new(seed_)
	var data := Pm98LineupFeeder.load_data()
	var input := Pm98LineupFeeder.build(home, away, data, lever_overrides,
		marking_overrides, line_overrides)
	var m := Pm98Match.build_match(live.rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = (input["lineups"] as Array)[0]
	(m["sim"][1] as Dictionary)[0x9c] = (input["lineups"] as Array)[1]
	Pm98Match.kickoff_init(m, input["session"], live.rng)
	live.match_state = m
	live.names = input.get("names", [])
	live._ball = Pm98Driver._ball(m)
	live._half_len = maxi(1, absi(Pm98Trig._i32(int(m.get(0x1820, 1)))))
	live._half_wid = maxi(1, absi(Pm98Trig._i32(int(m.get(0x1824, 1)))))
	return live


## Step the engine `n` outer frames (each is one `FUN_005983f0`), harvesting goals as they
## are raised. Returns the number actually stepped — short of `n` once full time lands.
func advance(n: int) -> int:
	if over:
		return 0
	var done := 0
	while done < n and not over:
		Pm98Outer.step(match_state, rng)
		frames += 1
		done += 1
		_harvest()
		if int(match_state.get(0x1a38, 0)) == FULL_TIME_DISPATCH or frames >= FRAME_CAP:
			over = true
	return done


## Run straight to full time. Used by the non-interactive path (a watched match the player
## abandons, and the headless gate) — ~18.5k frames for a 90-minute match.
func run_to_full_time() -> void:
	while not over:
		advance(2000)


## Match minute, the binary's own formula: `(banked + clk) * 0x2d / scale`.
func minute() -> int:
	var scale := int(match_state.get(0x19ac, 0))
	if scale == 0:
		return 0
	return (int(match_state.get(0x19a8, 0)) + int(match_state.get(0x450, 0))) * 0x2d / scale


## 0 = first half, 1 = second (match+0x19a0; 4 is the penalty mode).
func half() -> int:
	return int(match_state.get(0x19a0, 0))


## Every player as {side, slot, nx, ny, x, y, z, facing, kind, phase, carrying}.
## `nx`/`ny` are the 0..1 normalisation the old side-on view used; `x`/`y`/`z` are the RAW
## 16.16 world fields (`player+4/+8/+0xc`) the 3/4 WATCH camera projects, and `facing` /
## `kind` / `phase` are the engine's own `player+0x34` / `+0x40` / `+0x2c` — the three inputs
## `FUN_005a5460` uses to pick a JUG frame (`JugRender`). `carrying` marks the engine's own
## designated ball carrier (`match+0x440`).
func player_positions() -> Array:
	var out: Array = []
	var carrier: Variant = match_state.get(0x440, null)
	for side in 2:
		var team: Dictionary = (match_state["sim"] as Array)[side]
		var roster: Array = team.get("players", [])
		for slot in roster.size():
			var p: Dictionary = roster[slot]
			var wx := Pm98Trig._i32(int(p.get(4, 0)))
			var wy := Pm98Trig._i32(int(p.get(8, 0)))
			out.append({
				"side": side, "slot": slot,
				"nx": _nx(wx), "ny": _ny(wy),
				"x": wx, "y": wy, "z": Pm98Trig._i32(int(p.get(0xc, 0))),
				"facing": int(p.get(0x34, 0)) & 0xffff,
				"kind": int(p.get(0x40, 0)),
				"phase": int(p.get(0x2c, 0)),
				"carrying": carrier is Dictionary and (carrier as Dictionary) == p,
			})
	return out


## The fielded player's name for a side/slot, or "" when the feeder gave none.
func player_name(side: int, slot: int) -> String:
	if side < 0 or side >= names.size():
		return ""
	var xi: Array = names[side]
	return str(xi[slot]) if slot >= 0 and slot < xi.size() else ""


## Half the pitch LENGTH and half its WIDTH in 16.16 (`match+0x1820` / `+0x1824`) — Old
## Trafford's 116x76 m reads 3801088 / 2490368. The WATCH camera needs the raw figures, not
## the normalisation, because it projects world metres.
func pitch_half() -> Vector2i:
	return Vector2i(_half_len, _half_wid)


## The ball as {nx, ny, height} — `height` in metres off the +0xc fixed-point field.
func ball_position() -> Dictionary:
	return {
		"nx": _nx(Pm98Trig._i32(int(_ball.get(4, 0)))),
		"ny": _ny(Pm98Trig._i32(int(_ball.get(8, 0)))),
		"height": Pm98Trig._i32(int(_ball.get(0xc, 0))) / 65536.0,
	}


## Codes 7 (goal) and 8 (own goal) off the match event queue (match+0x1a24), attributed to
## the record's own team index and marked consumed by negating the code — the same harvest
## `run_full_match.gd` uses, run per frame so a queue flush cannot swallow one.
func _harvest() -> void:
	for ev in (match_state.get(0x1a24, []) as Array):
		var code := int(ev[0])
		if code != 7 and code != 8:
			continue
		var team := int(ev[1])
		if team != 0 and team != 1:
			ev[0] = -code
			continue
		score[team] += 1
		goals.append({"minute": minute(), "team": team, "slot": int(ev[2]), "own_goal": code == 8})
		ev[0] = -code


func _nx(x: int) -> float:
	return clampf((float(x) + _half_len) / (2.0 * _half_len), 0.0, 1.0)


func _ny(y: int) -> float:
	return clampf((float(y) + _half_wid) / (2.0 * _half_wid), 0.0, 1.0)
