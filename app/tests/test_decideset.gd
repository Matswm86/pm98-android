extends SceneTree
## Oracle-backed parity test for the per-player DECIDE state setters
## (FUN_005a5430 set-position-code / FUN_0058eca0 engage-target), ported in Pm98Movement.gd.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideset.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator
## (tools/re/run_decideset_oracle.sh -> tools/re/specs/decideset_oracle.txt). The runner
## EMBEDS each fixture's initial state; the EXPECTED outputs are read from the banked file
## (so there is no transcription). Pointer-valued fields (p40/p44/p48/m43c for 58eca0) come
## out of the oracle as ABSOLUTE addresses; this test maps them to the index model
## Pm98Movement uses (0 -> null(-1), else (addr - P_BASE) / P_STRIDE) before comparing.

const U32 := 0xffffffff
const P_BASE := 0x230000
const P_STRIDE := 0x3bc

# FUN_005a5430 fixtures: name -> input position code (mirrors the runner).
const POS_FIX := {
	"pos_keep0": 0, "pos_remap4": 4, "pos_remap19": 19,
	"pos_keep30": 30, "pos_remap29": 29, "pos_keep12": 12,
}

# FUN_0058eca0 fixtures: name -> {tgt = target index (-1 null), + initial-state overrides}.
# Defaults (matching run_decideset_oracle.sh ENG_BASE): p54=99, p4c=0x3333, p80=5,
# target+0x2b8(team)=7, target+0x54=0xAAAA, target+0x58=0xBBBB, m458=10, m460=1, m448=0, m43c=0.
const ENG_FIX := {
	"engage_new":      {"tgt": 1, "p40": -1},
	"engage_sameteam": {"tgt": 1, "p40": -1, "p54": 7},
	"engage_takereq":  {"tgt": 1, "p40": -1, "m43c": 1},
	"engage_phase":    {"tgt": 1, "p40": -1, "m448": 2},
	"engage_same":     {"tgt": 1, "p40": 1, "p44": 1, "p48": 1},
	"engage_null":     {"tgt": -1, "p40": 1, "p44": 1, "p48": 1},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideset oracle file empty/unreadable")
	else:
		for name in POS_FIX:
			_run_pos(name, orc.get(name, {}))
		for name in ENG_FIX:
			_run_eng(name, orc.get(name, {}))
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


func _eq(name: String, field: String, got: int, want: int) -> void:
	_ok((got & U32) == (want & U32), "%s %s: got %d want %d" % [name, field, got & U32, want & U32])


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _addr_to_idx(addr: int) -> int:
	if addr == 0:
		return -1
	return (addr - P_BASE) / P_STRIDE


# Parse "FIX <name> fn=<f> k=v k=v ..." rows into {name: {"fn":..., k:int,...}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideset_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		var name := toks[1]
		for i in range(2, toks.size()):
			var kv := toks[i].split("=")
			if kv.size() != 2:
				continue
			if kv[0] == "fn":
				row["fn"] = kv[1]
			else:
				row[kv[0]] = kv[1].to_int()
		out[name] = row
	return out


func _run_pos(name: String, exp: Dictionary) -> void:
	if exp.get("fn", "") != "5a5430":
		_ok(false, "%s: missing/!=5a5430 in oracle" % name)
		return
	var p := {0x2c: 0x1111, 0x30: 0x2222}
	Pm98Movement.set_position_code(p, int(POS_FIX[name]))
	_eq(name, "p40", int(p.get(0x40, 0)), int(exp["p40"]))
	_eq(name, "p2c", int(p.get(0x2c, 0)), int(exp["p2c"]))
	_eq(name, "p30", int(p.get(0x30, 0)), int(exp["p30"]))


func _run_eng(name: String, exp: Dictionary) -> void:
	if exp.get("fn", "") != "58eca0":
		_ok(false, "%s: missing/!=58eca0 in oracle" % name)
		return
	var fx: Dictionary = ENG_FIX[name]
	var m := {
		0x458: 10, 0x460: 1,
		0x448: int(fx.get("m448", 0)), 0x43c: int(fx.get("m43c", 0)),
	}
	var p := {
		0x40: int(fx.get("p40", -1)), 0x54: int(fx.get("p54", 99)),
		0x4c: 0x3333, 0x80: 5, 0x1d4: m,
	}
	if fx.has("p44"):
		p[0x44] = int(fx["p44"])
	if fx.has("p48"):
		p[0x48] = int(fx["p48"])
	var target := {0x2b8: 7, 0x54: 0xAAAA, 0x58: 0xBBBB}
	var players: Array = [p, target]                       # p = idx 0, target = idx 1

	Pm98Movement.set_engagement(p, int(fx["tgt"]), players)

	# Pointer fields: compare against the oracle address mapped to an index.
	_eq(name, "p40", int(p.get(0x40, -1)), _addr_to_idx(int(exp["p40"])))
	_eq(name, "p44", int(p.get(0x44, -1)), _addr_to_idx(int(exp["p44"])))
	_eq(name, "p48", int(p.get(0x48, -1)), _addr_to_idx(int(exp["p48"])))
	_eq(name, "m43c", int(m.get(0x43c, -1)), _addr_to_idx(int(exp["m43c"])))
	# Scalar fields.
	_eq(name, "p4c", int(p.get(0x4c, 0)), int(exp["p4c"]))
	_eq(name, "p54", int(p.get(0x54, 0)), int(exp["p54"]))
	_eq(name, "p80", int(p.get(0x80, 0)), int(exp["p80"]))
	_eq(name, "t54", int(target.get(0x54, 0)), int(exp["t54"]))
	_eq(name, "t58", int(target.get(0x58, 0)), int(exp["t58"]))
	_eq(name, "m458", int(m.get(0x458, 0)), int(exp["m458"]))
	_eq(name, "m460", int(m.get(0x460, 0)), int(exp["m460"]))
