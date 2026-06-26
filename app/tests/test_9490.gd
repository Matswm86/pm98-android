extends SceneTree
## Oracle-backed parity test for FUN_005a9490 SLICE A (the "lean", active-carrier branch):
## Pm98Movement.lean_9490 mutates the ball (and the player, for the fast a5430(0xb)) exactly like the
## REAL binary when p IS the ball's active carrier.
##
## Run headless from the project dir:
##   ~/godot462 --headless --audio-driver Dummy --path app --script res://tests/test_9490.gd
##
## ORACLE = the REAL FUN_005a9490 entered at 0x5a9490 (ECX = p), the mutated fields read back at the
## function RET: tools/re/run_9490sliceA_oracle.sh -> specs/9490sliceA_oracle.txt
##   (A9490 <name> | <abs-addr>=<unsigned LE> ...).
## We rebuild the identical p/ball Dicts (same pokes), run lean_9490, and assert every mutated field ==
## the oracle. Slice A draws 0 RNG. ball+0x40 (carrier ref) is checked specially (Dict ref, not an int).

var _fail := 0
var _pass := 0

# name -> fixture cfg (mirrors run_9490sliceA_oracle.sh FIX rows). Every fixture is the carrier
# (ball+0x40 == p). Unlisted offsets default to 0.  pos = p+0x4/8/c, facing = p+0x34, anim = p+0x68,
# onpitch = p+0x2bc, action = p+0x40 ; bpos = ball+0x4/8/c, bvel = ball+0x20/24/28.
var _fix := {
	"chase":     {"action": 0, "onpitch": 1, "bpos": [0x24ccc, 0, 0], "bvel": [0, 0, 0]},
	"anim":      {"action": 0, "onpitch": 1, "anim": 1, "bpos": [0xcccc, 0, 0], "bvel": [0, 0, 0]},
	"near":      {"action": 0, "onpitch": 1, "bpos": [0x6ccc, 0, 0], "bvel": [0, 0, 0]},
	"slowA":     {"action": 0, "onpitch": 1, "bpos": [0xcccc, 0, 0], "bvel": [0x1000, 0, 0]},
	"slowB":     {"action": 0, "onpitch": 1, "bpos": [0xcccc, 0x4000, 0], "bvel": [0x1000, 0, 0]},
	"slowC":     {"action": 0, "onpitch": 1, "bpos": [0xcccc, 0, 0x3000], "bvel": [0x1000, 0, 0]},
	"slowD":     {"action": 0, "onpitch": 1, "bpos": [0x10000, 0, 0], "bvel": [0x1000, 0, 0]},
	"slowE":     {"action": 0, "onpitch": 1, "bpos": [0xe000, 0x2000, 0x1000], "bvel": [0x1000, 0, 0]},
	"fast":      {"action": 0, "onpitch": 1, "bpos": [0xcccc, 0, 0], "bvel": [0x40000, 0, 0]},
	"fast_n2bc": {"action": 0, "onpitch": 0, "bpos": [0xcccc, 0, 0], "bvel": [0x40000, 0, 0]},
	"fastP":     {"action": 0, "onpitch": 1, "pos": [0x8000, 0x2000, 0x400],
		"bpos": [0x14ccc, 0x2000, 0x400], "bvel": [0x40000, 0, 0]},
	"fastR":     {"action": 0, "onpitch": 1, "facing": 0x4000, "bpos": [0, 0x10000, 0], "bvel": [0x40000, 0, 0]},
	"slowR":     {"action": 0, "onpitch": 1, "facing": 0x4000, "bpos": [0, 0x10000, 0], "bvel": [0x1000, 0, 0]},
}

# oracle abs-addr -> (object, field-off). p=0x230000 ball=0x280000. ball+0x40 handled separately.
var _addr := {
	"0x230040": ["p", 0x40], "0x23002c": ["p", 0x2c], "0x230030": ["p", 0x30],
	"0x280004": ["ball", 0x4], "0x280008": ["ball", 0x8], "0x28000c": ["ball", 0xc],
	"0x280020": ["ball", 0x20], "0x280024": ["ball", 0x24], "0x280028": ["ball", 0x28],
	"0x280068": ["ball", 0x68], "0x28006c": ["ball", 0x6c],
	"0x28009c": ["ball", 0x9c], "0x2800a0": ["ball", 0xa0], "0x2800a4": ["ball", 0xa4],
}


func _init() -> void:
	var o := _load("9490sliceA_oracle.txt", "A9490")
	if o.is_empty():
		_ok(false, "9490 Slice A oracle empty (run tools/re/run_9490sliceA_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from 9490 Slice A oracle")
	_run_noncarrier()
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


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _s32(v: int) -> int:
	return v - 0x100000000 if v >= 0x80000000 else v


func _load(fname: String, tag: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path(fname), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with(tag + " "):
			continue
		var parts := line.split(" ", false)
		var name := parts[1]
		var row := {}
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				row[tok.substr(0, eq)] = _s32(tok.substr(eq + 1).to_int())
		out[name] = row
	return out


func _build(cfg: Dictionary) -> Array:
	var pos: Array = cfg.get("pos", [0, 0, 0])
	var bpos: Array = cfg.get("bpos", [0, 0, 0])
	var bvel: Array = cfg.get("bvel", [0, 0, 0])
	var ball := {
		0x4: int(bpos[0]), 0x8: int(bpos[1]), 0xc: int(bpos[2]),
		0x20: int(bvel[0]), 0x24: int(bvel[1]), 0x28: int(bvel[2])}
	var p := {
		0x40: int(cfg.get("action", 0)),
		0x4: int(pos[0]), 0x8: int(pos[1]), 0xc: int(pos[2]),
		0x34: int(cfg.get("facing", 0)), 0x68: int(cfg.get("anim", 0)),
		0x2bc: int(cfg.get("onpitch", 0)), 0x190: ball}
	ball[0x40] = p                                           # carrier == this player
	return [p, ball]


func _run(name: String, want: Dictionary) -> void:
	var pb := _build(_fix[name])
	var p: Dictionary = pb[0]
	var ball: Dictionary = pb[1]
	var handled: bool = Pm98Movement.lean_9490(p)
	_ok(handled, "%s: lean_9490 should return true (carrier handled)" % name)

	# ball+0x40 (carrier ref): oracle 0 == released; oracle 0x230000 (2293760) == still the carrier.
	var rel := int(want.get("0x280040", 2293760)) == 0
	if rel:
		_ok(int(ball.get(0x40, -1)) == 0, "%s ball+0x40: expected released (0)" % name)
	else:
		_ok(is_same(ball.get(0x40, null), p), "%s ball+0x40: expected still carrier" % name)

	var objs := {"p": p, "ball": ball}
	for addr in _addr:
		var spec: Array = _addr[addr]
		var obj: Dictionary = objs[spec[0]]
		var got := int(obj.get(spec[1], 0))                  # unset Dict field == zeroed emu memory
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "9490A/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])


# Non-carrier deferral (no oracle: this is the trivial early-return that hands off to Slice B/C). The
# REAL FUN_005a9490 takes the big off-ball branch here; lean_9490 must decline it and mutate nothing.
func _run_noncarrier() -> void:
	var other := {0x4: 1, 0x8: 2, 0xc: 3}
	var ball := {0x4: 0xcccc, 0x8: 0, 0xc: 0, 0x20: 0x1000, 0x40: other}
	var p := {0x40: 0, 0x4: 0, 0x8: 0, 0xc: 0, 0x34: 0, 0x68: 0, 0x2bc: 1, 0x190: ball}
	var snap := ball.duplicate(true)
	var handled: bool = Pm98Movement.lean_9490(p)
	_ok(not handled, "noncarrier: lean_9490 must return false (deferred to Slice B/C)")
	var unchanged := true
	for k in snap:
		if k == 0x40:
			continue
		if int(ball.get(k, 0)) != int(snap[k]):
			unchanged = false
	_ok(unchanged, "noncarrier: ball fields must be untouched")
	_ok(is_same(ball.get(0x40, null), other), "noncarrier: ball+0x40 must stay the other carrier")
