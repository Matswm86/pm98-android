extends SceneTree
## Step-4 BUILD ORACLE parity: Pm98Match._build_player vs the REAL FUN_005a2830 driven
## through the Ghidra PCode emulator (tools/re/run_playerbuild_oracle.sh ->
## tools/re/specs/playerbuild_oracle.txt). Unlike test_player_build.gd (hand-computed),
## every expected number below is BANKED FROM THE EMULATOR, and the 0xe1 column was
## produced by the binary's own x87 fld/fild/fmul -> _ftol path -- so this finally pins
## the recovered 0xe1 field (disasm 0x5a2e36 + gcc-x87 cross-check) against the live
## function, not just a derivation. Run:
##   ~/godot462 --headless --path app --script res://tests/test_player_build_oracle.gd
##
## The emulator drives FUN_005a2830 with display/sprite calls stubbed; it reads the
## source record R, the team header TH (selector TH+0x31c, part-strength TH+0x2ec), and
## the match (mode +0x19a0, clock +0x19ac, +0x1a5c). _build_player takes those same
## inputs as (m, ti, slot, arr_idx, rec) + team[0xc7]/team[0x2ec], so the fixtures below
## reconstruct each emulator run exactly.
##
## CAVEAT -- 0xe1 (+0x384), the ftol field: Ghidra's PCode emulator models the x87 stack
## as 64-bit doubles, so the fmul `byte * 0.6` (a 55-bit-mantissa product, e.g. b37=10 ->
## 5404319552844595*10/2^53 = 2.9999..978 in the true 80-bit register) ROUNDS UP to the
## nearest double (3.0) BEFORE ftol, then truncates to the WRONG value (the raw emulator
## banked 3/6/153 for b37 5/10/255). Real x87 keeps the 64-bit extended mantissa exactly,
## so the product stays < the integer and ftol(trunc) gives 2/5/152. The 0xe1 expectations
## below therefore use the REAL-x87 values (== gcc long-double oracle /tmp/e1_oracle.c ==
## the exact-integer port `(b37*mantissa)>>53`), NOT the emulator's mis-rounded column.
## All 25 integer fields ARE emulator-validated (PCode emulates integer ops exactly).

const U32 := 0xffffffff
var _fail := 0
var _pass := 0

# Field byte-keys in the oracle's readback order (see playerbuild_oracle.txt header).
const KEYS := [0x2c0, 0x2c4, 0x2c8, 0x2d0, 0x2dc,                 # b0 b1 b2 b4 b7
	0x378, 0x37c, 0x380, 0x384, 0x388, 0x38c, 0x390, 0x394, 0x398, 0x39c, 0x3a0, 0x3a8, 0x3ac,  # de..eb
	0x70, 0x74, 0x78,                                             # 1c 1d 1e
	0x36c, 0x370, 0x2da,                                          # db dc 2da
	0x1f8, 0x228]                                                 # start pos 0x7e 0x8a

# BASE_REC from run_playerbuild_oracle.sh (byte-keyed source record).
func _base_rec() -> Dictionary:
	return {0x4: 0x270f, 0x8: 0x11112222, 0x18: 0x33334444, 0x2c: 2, 0x30: 1,
		0x34: 50, 0x35: 40, 0x36: 90, 0x37: 10, 0x38: 64, 0x3c: 60, 0x3d: 70,
		0x3e: 80, 0x3f: 75, 0x40: 85, 0x41: 58, 0x42: 45, 0x44: 3, 0x98: 1}


func _init() -> void:
	# {name, team, slot, arr_idx, c7, part, mode, clock, rec_overrides, expected[26]}
	var fixtures := [
		["outfield_s2", 0, 5, 0, 2, 1, 0, 0, {},
			[9999, 0, 3, 45, 0, 50, 77, 90, 10, 86, 86, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["gk_s2", 0, 0, 0, 2, 1, 0, 0, {},
			[9999, 0, 1, 45, 256, 50, 92, 90, 10, 86, 86, 70, 100, 75, 94, 84, 4423, 2850, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		# 0xe1: real-x87 trunc (emulator banked 3/6/153, mis-rounded -- see CAVEAT).
		["sel0_06", 0, 5, 0, 0, 1, 0, 0, {0x37: 5},
			[9999, 0, 3, 45, 0, 50, 77, 90, 2, 86, 86, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["sel1_08", 0, 5, 0, 1, 1, 0, 0, {0x37: 5},
			[9999, 0, 3, 45, 0, 50, 77, 90, 4, 86, 86, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["sel0_trap10", 0, 5, 0, 0, 1, 0, 0, {0x37: 10},
			[9999, 0, 3, 45, 0, 50, 77, 90, 5, 86, 86, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["sel0_255", 0, 5, 0, 0, 1, 0, 0, {0x37: 255},
			[9999, 0, 3, 45, 0, 50, 77, 90, 152, 86, 86, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["mode4", 0, 5, 0, 2, 1, 4, 0, {},
			[9999, 0, 3, 45, 0, 50, 77, 90, 10, 86, 80, 70, 80, 75, 94, 84, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["clock18k", 0, 5, 0, 2, 1, 0, 18000, {},
			[9999, 0, 3, 45, 0, 50, 58, 90, 10, 75, 86, 70, 80, 75, 89, 71, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		["partstr", 0, 5, 0, 2, 0, 0, 0, {},
			[9999, 0, 3, 45, 0, 50, 77, 90, 10, 81, 81, 70, 76, 75, 89, 79, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
		# team1: emulator left team-1 header selector + part flag uninit (0), arr_idx from
		# (P - TH1[0]=0)/0x3bc; reconstruct with c7=0, part=0, arr_idx=2399.
		["team1", 1, 5, 2399, 0, 0, 0, 0, {},
			[9999, 2399, 3, 45, 512, 50, 77, 90, 5, 81, 81, 70, 76, 75, 89, 79, 3440, 2216, 7000, 7000, 90, 0, 1, 1, 286335522, 858997828]],
	]
	for fx in fixtures:
		_run_fixture(fx)
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _run_fixture(fx: Array) -> void:
	var name: String = fx[0]
	var ti: int = fx[1]
	var slot: int = fx[2]
	var arr_idx: int = fx[3]
	var c7: int = fx[4]
	var part: int = fx[5]
	var mode: int = fx[6]
	var clock: int = fx[7]
	var rec: Dictionary = _base_rec()
	for k in (fx[8] as Dictionary):
		rec[k] = fx[8][k]
	var expected: Array = fx[9]

	# minimal match: _build_player reads only m["sim"][ti], m["sim"][1-ti], 0x19a0/0x19ac/0x1a5c.
	var team := {0xc7: c7, 0x2ec: part}
	var sim := [{}, {}]
	sim[ti] = team
	var m := {"sim": sim, 0x19a0: mode, 0x19ac: clock, 0x1a5c: 0}

	var p: Dictionary = Pm98Match._build_player(m, ti, slot, arr_idx, rec)
	for i in range(KEYS.size()):
		_eqx(int(p.get(KEYS[i], 0)), int(expected[i]),
			"%s [+0x%x]" % [name, KEYS[i]])


func _eqx(got: int, want: int, msg: String) -> void:
	if (got & U32) == (want & U32):
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] %s: got %d want %d" % [msg, got & U32, want & U32])
