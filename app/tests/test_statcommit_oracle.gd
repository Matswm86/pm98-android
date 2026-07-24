extends SceneTree
## Stat-COMMIT parity: Pm98StatStore.commit / fold_back / rating vs the REAL
## FUN_0044e440 driven through the Ghidra PCode emulator
## (tools/re/run_statcommit_oracle.sh -> tools/re/specs/statcommit_oracle.txt).
##
## Every EXPECTED value below is BANKED FROM THE EMULATOR, transcribed from that spec
## file. The five fixtures rebuild the harness's memory image exactly: participant
## +0xec..+0x12f seeded with the sentinel dword 0x10000*(s+1) + 0x100*(p+1) + 4k, so a
## record that reads back sentinel(K) at +K proves the commit is a straight field copy.
##
##   A_clean    11 + 11 ids, no events, no markers
##   B_partial  two home ids and one away id blanked -> 9 / 10 records
##   C_events   5 match events -> the scoreline counters incl. the own-goal side flip
##   D_markers  two assists + a shot on side0 p0, a shot on side1 p0 -> the 0xc vector
##   E_duppid   home id 3 used twice -> 10 records (find-by-id-else-append OVERWRITES)
##
## The fold-back (FUN_00448b60 @0x448f6b/@0x44907a) and the row-widget RATING
## (FUN_004afce0 @0x4b03f6) are asserted on top of the same banked records.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_statcommit_oracle.gd

const HOME_CLUB := 0x28
const AWAY_CLUB := 0x11
const HOME_IDS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const AWAY_IDS := [21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]

var _fail := 0
var _pass := 0


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-30s got=%s exp=%s" % [name, str(got), str(exp)])


## sentinel(side, player, dword) exactly as run_statcommit_oracle.sh's build_side emits.
func _sentinel(s: int, p: int, k: int) -> int:
	return 0x10000 * (s + 1) + 0x100 * (p + 1) + 4 * k


func _build(home_ids: Array, away_ids: Array) -> Pm98StatMatch.Mem:
	var mem := Pm98StatMatch.Mem.new()
	# match-struct header fields the commit copies into the report object
	mem.set_u16(Pm98StatMatch.POSS, 0x39)                                   # M+0x64  = 57
	mem.set_u16(Pm98StatMatch.SIDE_STRIDE + Pm98StatMatch.POSS, 0x27)       # M+0x804 = 39
	mem.set_u16(Pm98StatMatch.TEAMID, HOME_CLUB)
	mem.set_u16(Pm98StatMatch.TEAMID1, AWAY_CLUB)
	mem.set_s32(0x1c, 0x1111)
	mem.set_s32(0x20, 0x2222)
	mem.set_s32(0x24, 0x3333)
	mem.set_s32(0x28, 0x4444)
	mem.set_u8(0x2c, 0x55)
	mem.set_u8(0x30, 0x66)
	mem.set_u8(0x34, 0x77)
	mem.set_u8(0x38, 0x88)
	mem.set_s32(0x3c, 0x9999)
	mem.set_s32(0x40, 0xaaaa)
	for s in range(2):
		var ids: Array = home_ids if s == 0 else away_ids
		for p in range(11):
			var pb := Pm98StatMatch._player(s, p)
			mem.set_u16(pb + Pm98StatMatch.SEL, int(ids[p]))
			mem.set_u8(pb + 0xb8, 0xff if (s == 0 and p == 0) else (0x40 + s * 0x20 + p))
			for k in range(17):
				mem.set_s32(pb + 0xec + 4 * k, _sentinel(s, p, k))
	return mem


func _check_header(tag: String, rep: Pm98StatStore.Report) -> void:
	_ck(tag + ".hdr+0x18", rep.hdr.decode_u16(0x18), 57)
	_ck(tag + ".hdr+0x1a", rep.hdr.decode_u16(0x1a), 39)
	_ck(tag + ".hdr+0x30", rep.hdr.decode_s32(0x30), 0x4444)
	_ck(tag + ".hdr+0x34", rep.hdr.decode_u8(0x34), 85)
	_ck(tag + ".hdr+0x35", rep.hdr.decode_u8(0x35), 102)
	_ck(tag + ".hdr+0x36", rep.hdr.decode_u8(0x36), 119)
	_ck(tag + ".hdr+0x37", rep.hdr.decode_u8(0x37), 136)
	_ck(tag + ".hdr+0x40", rep.hdr.decode_s32(0x40), 0x1111)
	_ck(tag + ".hdr+0x48", rep.hdr.decode_s32(0x48), 0x2222)
	_ck(tag + ".hdr+0x50", rep.hdr.decode_s32(0x50), 0x3333)
	_ck(tag + ".hdr+0xb4", rep.hdr.decode_s32(0xb4), 0x9999)
	_ck(tag + ".hdr+0xb8", rep.hdr.decode_s32(0xb8), 0xaaaa)


## Every fixture banks the same home rec0 / rec1 / away rec0 provenance rows.
func _check_records(tag: String, rep: Pm98StatStore.Report) -> void:
	_ck(tag + ".rec0+0x00", rep.field(0, 0, 0x00), 1)          # forced MP flag
	for k in range(1, 17):
		_ck(tag + ".rec0+0x%02x" % (4 * k), rep.field(0, 0, 4 * k), _sentinel(0, 0, k))
	_ck(tag + ".rec0.pid", rep.pid(0, 0), 1)
	_ck(tag + ".rec0.pad", rep.home.decode_u16(0x46), 0)       # +0x46 never written
	_ck(tag + ".rec1+0x00", rep.field(0, 1, 0x00), 1)
	_ck(tag + ".rec1+0x10", rep.field(0, 1, 0x10), 0x10210)
	_ck(tag + ".rec1.pid", rep.pid(0, 1), 2)
	_ck(tag + ".away0+0x00", rep.field(1, 0, 0x00), 1)
	_ck(tag + ".away0+0x18", rep.field(1, 0, 0x18), 0x20118)
	_ck(tag + ".away0.pid", rep.pid(1, 0), 21)


func _check_reset_and_condition(tag: String, mem: Pm98StatMatch.Mem,
		rep: Pm98StatStore.Report) -> void:
	var p00 := Pm98StatMatch._player(0, 0)
	var p01 := Pm98StatMatch._player(0, 1)
	_ck(tag + ".reset+0xec", mem.s32(p00 + 0xec), 0)
	_ck(tag + ".reset+0x104", mem.s32(p00 + 0x104), 0)
	_ck(tag + ".reset+0x12c", mem.s32(p00 + 0x12c), 0)
	_ck(tag + ".reset.p1+0x124", mem.s32(p01 + 0x124), 0)
	_ck(tag + ".cond.id1", rep.condition.get(1, -1), 99)       # 0xff clamped to 0x63
	_ck(tag + ".cond.id2", rep.condition.get(2, -1), 65)
	_ck(tag + ".cond.id21", rep.condition.get(21, -1), 96)


func _check_scoreline(tag: String, rep: Pm98StatStore.Report, exp: Array) -> void:
	var offs := [0x3c, 0x3d, 0x4c, 0x4d, 0x54, 0x55]
	for i in range(6):
		_ck(tag + ".score+0x%02x" % offs[i], rep.hdr.decode_u8(offs[i]), exp[i])


func _fix(tag: String, home_ids: Array, away_ids: Array, events: Array,
		markers: Array, counts: Array, scoreline: Array) -> Pm98StatStore.Report:
	var mem := _build(home_ids, away_ids)
	mem.events = events
	for m in markers:
		var pb: int = Pm98StatMatch._player(int(m[0]), int(m[1]))
		mem.set_s32(pb + int(m[2]), 1)
		mem.set_s32(pb + int(m[3]), int(m[4]))
	var rep := Pm98StatStore.Report.new(HOME_CLUB, AWAY_CLUB)
	Pm98StatStore.commit(mem, rep)
	_ck(tag + ".home_count", rep.home_count, counts[0])
	_ck(tag + ".away_count", rep.away_count, counts[1])
	_ck(tag + ".marker_count", rep.marker_count, counts[2])
	_check_header(tag, rep)
	_check_records(tag, rep)
	_check_reset_and_condition(tag, mem, rep)
	_check_scoreline(tag, rep, scoreline)
	return rep


func _init() -> void:
	var zero := [0, 0, 0, 0, 0, 0]

	# --- A_clean: counts 11/11/0, no events -----------------------------------
	var a := _fix("A_clean", HOME_IDS, AWAY_IDS, [], [], [11, 11, 0], zero)
	_ck("A_clean.rec10+0x00", a.field(0, 10, 0x00), 1)
	_ck("A_clean.rec10.pid", a.pid(0, 10), 11)

	# --- B_partial: blanked ids are skipped entirely --------------------------
	var b := _fix("B_partial", [1, 2, 0, 0, 5, 6, 7, 8, 9, 10, 11],
		[21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 0], [], [], [9, 10, 0], zero)
	_ck("B_partial.slot10.absent", b.home_count <= 10, true)

	# --- C_events: scoreline counters incl. the own-goal side flip ------------
	# evt(type, minute, p4, team, shirt): home goal / home own-goal / away ET1 /
	# type-4 home / away ET2. Banked: +0x3c=1 +0x3d=3 +0x4c=0 +0x4d=2 +0x54=1 +0x55=0.
	var ev := [
		{"type": 0, "minute": 27, "p4": 0, "payload": (6 << 16) | HOME_CLUB},
		{"type": 1, "minute": 12, "p4": 1, "payload": (9 << 16) | HOME_CLUB},
		{"type": 2, "minute": 5, "p4": 0, "payload": (4 << 16) | AWAY_CLUB},
		{"type": 4, "minute": 33, "p4": 0, "payload": (2 << 16) | HOME_CLUB},
		{"type": 3, "minute": 8, "p4": 0, "payload": (7 << 16) | AWAY_CLUB},
	]
	var c := _fix("C_events", HOME_IDS, AWAY_IDS, ev, [], [11, 11, 0], [1, 3, 0, 2, 1, 0])
	_ck("C_events.codes", str(Array(c.event_codes)), str([1, 2, 3, 5, 4]))

	# --- D_markers: the 0xc-stride assist/shot vector -------------------------
	# side0 p0 assist@0xc (+0xd4/+0xe0), assist@0x1e (+0xd8/+0xe4), shot@0x2a (+0xdc/+0xe8);
	# side1 p0 shot@0x11. Banked: {1,0x28000c,1} {1,0x28001e,1} {2,0x28002a,1} {2,0x110011,21}.
	var mk := [
		[0, 0, Pm98StatMatch.D4, Pm98StatMatch.E0, 0xc],
		[0, 0, Pm98StatMatch.D8, Pm98StatMatch.E4, 0x1e],
		[0, 0, Pm98StatMatch.DC, Pm98StatMatch.E8, 0x2a],
		[1, 0, Pm98StatMatch.DC, Pm98StatMatch.E8, 0x11],
	]
	var d := _fix("D_markers", HOME_IDS, AWAY_IDS, [], mk, [11, 11, 4], zero)
	var exp_mk := [
		{"kind": 1, "value": 0x28000c, "pid": 1},
		{"kind": 1, "value": 0x28001e, "pid": 1},
		{"kind": 2, "value": 0x28002a, "pid": 1},
		{"kind": 2, "value": 0x110011, "pid": 21},
	]
	for i in range(4):
		var got: Dictionary = d.marker(i)
		_ck("D_markers.rec%d.kind" % i, got["kind"], exp_mk[i]["kind"])
		_ck("D_markers.rec%d.value" % i, got["value"], exp_mk[i]["value"])
		_ck("D_markers.rec%d.pid" % i, got["pid"], exp_mk[i]["pid"])

	# --- E_duppid: find-by-id-else-append OVERWRITES -> 10 home records --------
	var e := _fix("E_duppid", [1, 2, 3, 4, 5, 6, 7, 3, 9, 10, 11], AWAY_IDS,
		[], [], [10, 11, 0], zero)
	# the second id-3 participant (slot 7) overwrote the first (slot 2), so the record
	# keyed 3 must carry slot 7's sentinels, not slot 2's.
	var slot3 := -1
	for i in range(e.home_count):
		if e.pid(0, i) == 3:
			slot3 = i
	_ck("E_duppid.id3.slot", slot3, 2)
	_ck("E_duppid.id3+0x10", e.field(0, slot3, 0x10), _sentinel(0, 7, 4))

	# --- fold-back (FUN_00448b60): per-field ADD into playerobj+0x24 ----------
	var store := {}
	Pm98StatStore.fold_back(a, store, 0)
	_ck("fold.pid1.+0x24", store[1][0], 1)                     # MP
	_ck("fold.pid1.+0x28", store[1][1], _sentinel(0, 0, 1))    # MIN
	_ck("fold.pid1.+0x34", store[1][4], _sentinel(0, 0, 4))    # season goals
	_ck("fold.pid21.+0x3c", store[21][6], _sentinel(1, 0, 6))
	_ck("fold.keys", store.size(), 22)
	# a second identical match must DOUBLE every field -- the fold-back adds, the
	# commit overwrites.
	Pm98StatStore.fold_back(a, store, 0)
	_ck("fold.twice.pid1.+0x24", store[1][0], 2)
	_ck("fold.twice.pid1.+0x34", store[1][4], 2 * _sentinel(0, 0, 4))
	# MoM stamp lands on the report row as well as the season total
	var store2 := {}
	Pm98StatStore.fold_back(a, store2, 2)
	_ck("fold.mom.rec1+0x0c", a.field(0, 1, 0x0c), 1)
	_ck("fold.mom.pid2.+0x30", store2[2][3], 1)
	_ck("fold.mom.pid1.+0x30", store2[1][3], _sentinel(0, 0, 3))

	# --- row widget: RATING (FUN_004afce0) + cell formatting -----------------
	# Live half-time witness, Man Utd (screenshots/wine-captures-2026-07-24-statistics-live
	# frame 02), Giggs: MIN 45, SHOTS 1/1, PASSES 4/7, TAC. 0/2, G. 0 -> RATING 6.
	_ck("rating.giggs_h1", Pm98StatStore.rating(_rec(45, 0, 0, 0, 1, 0, 4, 3, 0, 2)), 6)
	# Schmeichel: MIN 45, SHOTS -/-, PASSES 2/5, TAC. -/- -> RATING 4.
	_ck("rating.schmeichel_h1", Pm98StatStore.rating(_rec(45, 0, 0, 0, 0, 0, 2, 3, 0, 0)), 4)
	# Solskjaer full-time, one goal: MIN 45, SHOTS 2/3, PASSES 1/4, TAC. 2/6 -> RATING 6.
	_ck("rating.solskjaer", Pm98StatStore.rating(_rec(45, 0, 0, 1, 2, 1, 1, 3, 2, 4)), 6)
	# MIN 0 prints a dash, not a number.
	var cells: Dictionary = Pm98StatStore.row_cells(_rec(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
	_ck("cells.zero.RATING", cells["RATING"], "-")
	_ck("cells.zero.SHOTS", cells["SHOTS"], "-/-")
	_ck("cells.zero.MP", cells["MP"], "1")                     # _rec() always sets the MP flag
	# an unplayed slot -- every field 0 -- prints dashes right across the row
	var empty: PackedInt32Array = PackedInt32Array(); empty.resize(17)
	var cells0: Dictionary = Pm98StatStore.row_cells(empty)
	_ck("cells.empty.MP", cells0["MP"], "-")
	_ck("cells.empty.MIN", cells0["MIN"], "-")
	_ck("cells.empty.TAC.", cells0["TAC."], "-/-")
	var cells2: Dictionary = Pm98StatStore.row_cells(_rec(45, 0, 0, 1, 2, 1, 1, 3, 2, 4))
	_ck("cells.SHOTS", cells2["SHOTS"], "2/3")     # first / (first + second)
	_ck("cells.PASSES", cells2["PASSES"], "1/4")
	_ck("cells.TAC.", cells2["TAC."], "2/6")
	_ck("cells.G.", cells2["G."], "1")

	# --- TEAM TOTAL row: MP constant 1, MIN = MAX, the rest column sums -------
	var rows := [
		_rec(90, 0, 0, 0, 1, 0, 2, 4, 1, 5),
		_rec(45, 0, 0, 1, 2, 1, 1, 3, 2, 4),
	]
	var tot: PackedInt32Array = Pm98StatStore.totals(rows)
	_ck("totals.MP", tot[0], 1)
	_ck("totals.MIN", tot[1], 90)                              # max, not 135
	_ck("totals.G.", tot[4], 1)
	_ck("totals.SHOTS_ON", tot[5], 3)
	_ck("totals.SHOTS_OFF", tot[6], 1)
	_ck("totals.cells.SHOTS", Pm98StatStore.row_cells(tot)["SHOTS"], "3/4")

	# --- simulate() with the transitions un-stubbed --------------------------
	# None of FUN_0044d0d0/d190/d250/d310/d520 consumes rand(), so wiring the commit in
	# must leave the draw stream bit-identical. Same seed, same XIs, with and without.
	var xi0 := _xi(70)
	var xi1 := _xi(60)
	var m1 := Pm98StatMatch.build_mem(xi0, xi1, HOME_CLUB, AWAY_CLUB)
	var r1 := Pm98StatMatch.Rng.new(0x1234)
	Pm98StatMatch.simulate(m1, r1)
	var m2 := Pm98StatMatch.build_mem(xi0, xi1, HOME_CLUB, AWAY_CLUB)
	var r2 := Pm98StatMatch.Rng.new(0x1234)
	var rep2 := Pm98StatStore.Report.new(HOME_CLUB, AWAY_CLUB)
	# build_mem writes slot+1 into +0x88 on BOTH sides, so a season store keyed on the
	# raw value would merge the two teams. Bridge to distinct ids (see commit()'s `pids`).
	var pids := {}
	for i in range(11):
		pids[i] = 101 + i
		pids[11 + i] = 201 + i
	Pm98StatMatch.simulate(m2, r2, false, false, rep2, pids)
	_ck("sim.draws_unchanged", r2.draws, r1.draws)
	_ck("sim.state_unchanged", r2.state, r1.state)
	_ck("sim.events_unchanged", m2.events.size(), m1.events.size())
	# two commits (H1 + H2) into the same report -> still 11 + 11 records, because the
	# helper is find-by-id-else-append and the second commit OVERWRITES the first.
	_ck("sim.home_count", rep2.home_count, 11)
	_ck("sim.away_count", rep2.away_count, 11)
	# The commit OVERWRITES and then zeroes the participant block, so after the H2 commit
	# the report record holds SECOND-HALF stats only (45 minutes, not 90). This is what
	# the emulator banked; see the "commit cadence" open item in docs/re/season_stats_re.md
	# -- the live full-time frames are cumulative, which the traced cadence does not yet
	# explain, so nothing here pretends otherwise.
	_ck("sim.rep.min_is_h2", rep2.field(0, 0, Pm98StatStore.R_MIN), 45)
	var season := {}
	Pm98StatStore.fold_back(rep2, season, 0)
	_ck("sim.season.pid101.mp", season[101][0], 1)
	_ck("sim.season.pid101.min", season[101][Pm98StatStore.R_MIN / 4], 45)
	_ck("sim.season.keys", season.size(), 22)     # no home/away id collision
	# the scoreline the commit rebuilt must equal the engine's own score()
	var sc: Dictionary = Pm98StatMatch.score(m2)
	_ck("sim.scoreline.home", rep2.hdr.decode_u8(Pm98StatStore.F_GOALS_H),
		int(sc.get(HOME_CLUB, 0)))
	_ck("sim.scoreline.away", rep2.hdr.decode_u8(Pm98StatStore.F_GOALS_A),
		int(sc.get(AWAY_CLUB, 0)))

	print("test_statcommit_oracle: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


## A synthetic XI in the shape Pm98StatMatch.build_mem expects.
func _xi(strength: int) -> Array:
	var out := []
	for i in range(11):
		out.append({
			"attrs": {"VE": strength, "RE": strength, "AG": strength, "CA": strength,
				"PO": strength, "PA": strength},
			"pos": "GK" if i == 0 else ("DF" if i < 5 else ("MF" if i < 9 else "FW")),
		})
	return out


## Build a 17-dword record from the fields the row widget actually reads.
func _rec(minutes: int, involve: int, mom: int, goals: int, shots_on: int,
		shots_off: int, pass_ok: int, pass_fail: int, tack_ok: int,
		tack_fail: int) -> PackedInt32Array:
	var f := PackedInt32Array(); f.resize(17)
	f[0] = 1
	f[Pm98StatStore.R_MIN / 4] = minutes
	f[Pm98StatStore.R_INVOLVE / 4] = involve
	f[Pm98StatStore.R_MOM / 4] = mom
	f[Pm98StatStore.R_GOALS / 4] = goals
	f[Pm98StatStore.R_SHOTS_ON / 4] = shots_on
	f[Pm98StatStore.R_SHOTS_OFF / 4] = shots_off
	f[Pm98StatStore.R_PASS_OK / 4] = pass_ok
	f[Pm98StatStore.R_PASS_FAIL / 4] = pass_fail
	f[Pm98StatStore.R_TACK_OK / 4] = tack_ok
	f[Pm98StatStore.R_TACK_FAIL / 4] = tack_fail
	return f
