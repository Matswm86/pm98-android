extends SceneTree
## Oracle-backed parity test for FUN_005a3400's else-replay branch (DAT_006d31c4 != 0),
## ported in Pm98Movement.decide_slice_replay.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decideReplay.gd
##
## ORACLE = the REAL FUN_005a3400 down the replay branch under the Ghidra PCode emulator, run to
## a clean RET (tools/re/run_decideReplay_oracle.sh -> specs/decideReplay_oracle.txt). This test
## mirrors each fixture's struct seeds, runs decide_slice_replay, and asserts the banked outputs:
## the 81-dword saved-state restore (+0x40/+0x44/+0x5c/+0xb0/+0x180), the team active-player ptr
## (team+0x168, mapped pointer->dict identity), the prior active's cleared +0x5c, and the taker
## stamp (match+0x45c).

const U32 := 0xffffffff
const P0 := 0x230000          # player address
const OLD := 0x280000         # prior active player address
# Saved-state buffer seeds (mirror run_decideReplay_oracle.sh): offset -> value.
const BUF := {0x0: 0x11110000, 0x4: 0x22220000, 0x70: 0x33330000, 0x140: 0x44440000}

# Fixtures (mirror the oracle). gate -> restored +0x5c (buf+0x1c) ; ts168 -> initial team+0x168
# ("old"/"none"/"self") ; old5c -> OLD+0x5c initial ; taker -> player IS the set-piece taker ;
# team -> player+0x2b8 (the +0x45c stamp value).
const FIX := {
	"active_taker_old":    {"team": 1, "gate": 1, "ts168": "old",  "old5c": 1, "taker": true},
	"active_nontaker_old": {"team": 0, "gate": 1, "ts168": "old",  "old5c": 1, "taker": false},
	"inactive":            {"team": 0, "gate": 0, "ts168": "old",  "old5c": 1, "taker": true},
	"active_noold":        {"team": 1, "gate": 1, "ts168": "none", "old5c": 0, "taker": true},
	"active_self":         {"team": 0, "gate": 1, "ts168": "self", "old5c": 0, "taker": false},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "decideReplay oracle file empty/unreadable")
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


# Parse "FIX <name> ... mem[0xADDR:W]=val ...": row -> {absolute_addr: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("decideReplay_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


# Map the final team+0x168 (a player ref) back to the oracle's absolute pointer.
func _ts168_addr(ts: Dictionary, p: Dictionary, old: Dictionary) -> int:
	var v: Variant = ts.get(0x168, null)
	if v == null:
		return 0
	if is_same(v, p):
		return P0
	if is_same(v, old):
		return OLD
	return -1


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x45c: 0x7777, 0x438: {}}                       # +0x45c sentinel; +0x438 set below
	var buf := {}
	for off in BUF:
		buf[off] = int(BUF[off])
	buf[0x1c] = int(fx["gate"])                               # restored +0x5c gate
	var old := {0x5c: int(fx["old5c"])}                       # prior active player @0x280000
	var ts := {}                                              # team struct (player+0x184)
	match fx["ts168"]:
		"old":  ts[0x168] = old
		"self": pass                                          # set to p after p exists (below)
	var p := {0x2b8: int(fx["team"]), 0x184: ts, 0x18c: m, 0x3b0: buf}
	if fx["ts168"] == "self":
		ts[0x168] = p
	m[0x438] = (p if fx["taker"] else {})                     # taker == this player, or a distinct dict

	Pm98Movement.decide_slice_replay(p, m)

	# Copy fields (+0x40/+0x44/+0x5c/+0xb0/+0x180) by absolute address.
	for addr in [P0 + 0x40, P0 + 0x44, P0 + 0x5c, P0 + 0xb0, P0 + 0x180]:
		if exp.has(addr):
			_ok((int(p.get(addr - P0, 0)) & U32) == (int(exp[addr]) & U32),
				"%s +0x%x: got %d want %d" % [name, addr - P0, int(p.get(addr - P0, 0)) & U32, int(exp[addr]) & U32])
	# team+0x168 active-player pointer (mapped).
	if exp.has(0x240168):
		var got168 := _ts168_addr(ts, p, old) & U32
		_ok(got168 == (int(exp[0x240168]) & U32),
			"%s team+0x168: got 0x%x want 0x%x" % [name, got168, int(exp[0x240168]) & U32])
	# prior active +0x5c (cleared or not).
	if exp.has(OLD + 0x5c):
		_ok((int(old.get(0x5c, 0)) & U32) == (int(exp[OLD + 0x5c]) & U32),
			"%s OLD+0x5c: got %d want %d" % [name, int(old.get(0x5c, 0)) & U32, int(exp[OLD + 0x5c]) & U32])
	# match+0x45c taker-team stamp.
	if exp.has(0x21045c):
		_ok((int(m.get(0x45c, 0)) & U32) == (int(exp[0x21045c]) & U32),
			"%s match+0x45c: got %d want %d" % [name, int(m.get(0x45c, 0)) & U32, int(exp[0x21045c]) & U32])
