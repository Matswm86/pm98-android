extends SceneTree
## Oracle-backed parity test for FUN_005a3400 slice B (field reset + facing + position),
## ported in Pm98Movement.decide_slice_b.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideB.gd
##
## ORACLE = the REAL FUN_005a3400 real-compute head under the Ghidra PCode emulator, run to a
## clean switch-default RET (tools/re/run_decideB_oracle.sh -> specs/decideB_oracle.txt). The
## runner EMBEDS each fixture's inputs + pre-seeds; this test mirrors them, calls
## decide_slice_b, and asserts every banked output field (parsed by absolute address) bit-exact.

const BASE := 0x230000        # P0 base in the oracle's memory map
const U32 := 0xffffffff

# Fixture inputs (mirror run_decideB_oracle.sh).
#   team / orient -> facing ; on -> +0x2bc on-pitch flag (drives pos 0 vs 0x1e) ;
#   idx -> +0x2cc slot ; tbl -> the +0x188 team struct's +0x13c table {idx -> value} ;
#   seed -> player fields pre-set before the call (proves +0x61 is never cleared, +0x2c/+0x30
#   are never written).
const FIX := {
	"home_on_v":    {"team": 0, "orient": 0, "on": true,  "idx": 3,  "tbl": {3: 0x50000}, "seed": {}},
	"away_on_zero": {"team": 0, "orient": 1, "on": true,  "idx": 0,  "tbl": {0: 0},        "seed": {0x61: 7}},
	"off_pitch":    {"team": 1, "orient": 1, "on": false, "idx": 5,  "tbl": {5: 0x123},    "seed": {0x2c: 0x111, 0x30: 0x222}},
	"neg_idx":      {"team": 1, "orient": 0, "on": true,  "idx": -1, "tbl": {},            "seed": {0x61: 3}},
	"away_t1_big":  {"team": 1, "orient": 0, "on": true,  "idx": 2,  "tbl": {2: 0x7fff0000}, "seed": {}},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideB oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, orc[name])
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


# Parse "FIX <name> CALL 0 RET ... mem[0xADDR:W]=val ...": row -> {offset: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideB_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			var off := ("0x" + mtch.get_string(1)).hex_to_int() - BASE
			row[off] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x1820: 0x100000, 0x19a0: int(fx["orient"])}
	# The +0x188 team/formation struct: its +0x13c int32 table, keyed at +0x13c + idx*4.
	var tinfo := {}
	for k in fx["tbl"]:
		tinfo[0x13c + int(k) * 4] = int(fx["tbl"][k])
	var p := {
		0x2b8: int(fx["team"]),
		0x2bc: (1 if fx["on"] else 0),
		0x2cc: int(fx["idx"]),
		0x18c: m,
		0x188: tinfo,
	}
	for off in fx["seed"]:
		p[int(off)] = int(fx["seed"][off])

	Pm98Movement.decide_slice_b(p, m)

	for off in exp:
		var got := int(p.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got %d want %d" % [name, off, got, want])
