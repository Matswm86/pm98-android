extends SceneTree
## Oracle-backed parity test for FUN_005a9490 ("the lean") SLICE C -- the post-scan shot/clear/
## ball-control tail, driven through the FULL wired entry lean_9490(p, true, rng) so the off-ball
## orchestrator (_lean9490_offball: gates -> aim -> grid -> scan(entry FAILS, p+0x54=0) -> Slice C)
## is exercised end-to-end against the REAL FUN_005a9490 run from its true entry.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_9490sliceC.gd
##
## ORACLE: tools/re/run_9490sliceC_oracle.sh -> specs/9490sliceC_oracle.txt (B9490c rows).

var _fail := 0
var _pass := 0

const SEED := 0x4d2

# name -> cfg (mirrors the run_9490sliceC_oracle.sh FIX pokes; p @0 facing 0 action 0 timer 5,
# scan-entry FAIL p+0x54=0, ball @(0x10000,0,0)). row/vec steer grid row 0 (or 2 for chase).
var _fix := {
	"clr_far":   {"vel": [0x10000, 0, 0], "row": 0, "vec": [0, 0, 0x18000],       "b4c": "", "b44": "", "b62": 0},
	"clr_close": {"vel": [0x10000, 0, 0], "row": 0, "vec": [0x1000, 0x1000, 0x10000], "b4c": "", "b44": "", "b62": 0},
	"clr_wide":  {"vel": [0x10000, 0, 0], "row": 0, "vec": [0x4000, 0x6000, 0x10000], "b4c": "", "b44": "", "b62": 0},
	"clr_out":   {"vel": [0x10000, 0, 0], "row": 0, "vec": [0x9000, 0, 0x10000],   "b4c": "", "b44": "", "b62": 0},
	"chase":     {"vel": [0x3000, 0, 0],  "row": 2, "vec": [0x4ccc, 0, 0x8000],    "b4c": "", "b44": "", "b62": 0},
	"ctl_low":   {"vel": [0x3000, 0, 0],  "row": 0, "vec": [0x4ccc, 0, 0x8000],    "b4c": "", "b44": "", "b62": 0},
	"ctl_high":  {"vel": [0x1000, 0, 0],  "row": 0, "vec": [0x4ccc, 0, 0x10000],   "b4c": "", "b44": "", "b62": 0},
	"own62":     {"vel": [0x3000, 0, 0],  "row": 0, "vec": [0x4ccc, 0, 0x8000],    "b4c": "p", "b44": "p", "b62": 1},
	"foreign62": {"vel": [0x3000, 0, 0],  "row": 0, "vec": [0x4ccc, 0, 0x8000],    "b4c": "q", "b44": "", "b62": 0},
}


func _init() -> void:
	var o := {}
	var f := FileAccess.open(_spec_path("9490sliceC_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "Slice C oracle missing (run tools/re/run_9490sliceC_oracle.sh)")
	else:
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if not line.begins_with("B9490c "):
				continue
			var parts := line.split(" ", false)
			var kv := {}
			for tok in parts:
				var eq := tok.find("=")
				if eq > 0 and tok.begins_with("0x"):
					kv[tok.substr(0, eq)] = _s32(tok.substr(eq + 1).to_int())
			o[parts[1]] = kv
		for name in _fix:
			if not o.has(name):
				_ok(false, "C/%s missing from oracle" % name)
				continue
			_run_one(name, o[name])
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


func _run_one(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _fix[name]
	var m := {}
	var ball := {0x40: 0, 0x50: 0, 0x70: 0, 0x80: 0x1234, 4: 0x10000, 8: 0, 0xc: 0, 0x34: 0,
		0x20: int(cfg["vel"][0]), 0x24: int(cfg["vel"][1]), 0x28: int(cfg["vel"][2]),
		0x62: int(cfg["b62"]), 0x1d4: m}
	for s in range(0x17, 0x27):                                # 16 trajectory slots FAR (p @0)
		ball[0xc * s] = 0x400000
		ball[0xc * s + 4] = 0x400000
		ball[0xc * s + 8] = 0x400000
	var sgo := 0x17 + int(cfg["row"])
	ball[0xc * sgo] = int(cfg["vec"][0])
	ball[0xc * sgo + 4] = int(cfg["vec"][1])
	ball[0xc * sgo + 8] = int(cfg["vec"][2])
	var p := {
		0x34: 0, 4: 0, 8: 0, 0xc: 0, 0x40: 0, 0x2c: 5, 0x54: 0, 0x2bc: 1,
		0x2b8: 0, 0x3a4: 0, 0x18c: m, 0x190: ball,
	}
	var q := {0x2b8: 1}                                        # opposing soft-carrier (@0x260000)
	ball[0x4c] = p if cfg["b4c"] == "p" else (q if cfg["b4c"] == "q" else 0)
	ball[0x44] = p if cfg["b44"] == "p" else 0
	var rng = MatchEngine.Pm98Rng.new(SEED)
	var handled: bool = Pm98Movement.lean_9490(p, true, rng)
	_ok(handled, "C/%s: wired lean_9490 must return true" % name)
	_eq(name, "action", int(want["0x230040"]), int(p.get(0x40, 0)))
	_eq(name, "p2c",    int(want["0x23002c"]), int(p.get(0x2c, 0)))
	_eq(name, "p54",    int(want["0x230054"]), int(p.get(0x54, 0)))
	_eq(name, "velx",   int(want["0x280020"]), int(ball.get(0x20, 0)))
	_eq(name, "vely",   int(want["0x280024"]), int(ball.get(0x24, 0)))
	_eq(name, "velz",   int(want["0x280028"]), int(ball.get(0x28, 0)))
	_ref_eq(name, "ball40", int(want["0x280040"]), ball.get(0x40, 0), p)
	_ref_eq(name, "ball44", int(want["0x280044"]), ball.get(0x44, 0), p)
	_ref_eq(name, "ball48", int(want["0x280048"]), ball.get(0x48, 0), p)
	_eq(name, "ball54", int(want["0x280054"]), int(ball.get(0x54, 0)))
	_eq(name, "ball80", int(want["0x280080"]), int(ball.get(0x80, 0)))
	_eq(name, "anim68", int(want["0x280068"]), int(ball.get(0x68, 0)))
	_eq(name, "anim6c", int(want["0x28006c"]), int(ball.get(0x6c, 0)))
	_eq(name, "tgt9c",  int(want["0x28009c"]), int(ball.get(0x9c, 0)))
	_eq(name, "tgta0",  int(want["0x2800a0"]), int(ball.get(0xa0, 0)))
	_eq(name, "tgta4",  int(want["0x2800a4"]), int(ball.get(0xa4, 0)))
	_eq(name, "m458",   int(want["0x2a0458"]), int(m.get(0x458, 0)))
	_eq(name, "rng",    int(want["0x6d3184"]) & 0xffffffff, int(rng.state) & 0xffffffff)


## Pointer-valued oracle field: 0x230000 (p @0x230000 in the emu) -> the p Dictionary; 0 -> int 0.
## NEVER str() the got value -- the fixtures are CYCLIC (p -> ball -> p) and stringifying recurses.
func _ref_eq(name: String, field: String, want: int, got, p: Dictionary) -> void:
	var desc := "Dict" if got is Dictionary else str(got)
	if want == 0x230000:
		_ok(got is Dictionary and is_same(got, p), "C/%s %s: want p ref, got %s" % [name, field, desc])
	else:
		_ok(not (got is Dictionary) and (got is Dictionary or int(got) == want),
			"C/%s %s: got=%s want=%d (0x%x)" % [name, field, desc, want, want & 0xffffffff])


func _eq(name: String, field: String, want: int, got: int) -> void:
	_ok(got == want, "C/%s %s: got=%d (0x%x) want=%d (0x%x)" % [name, field, got, got & 0xffffffff, want, want & 0xffffffff])
