class_name Pm98StatStore
extends RefCounted
## PM98 per-player STAT COMMIT + season fold-back -- the faithful port of the two
## binary halves that turn a finished match into STATISTICS rows and season totals.
## RE map: docs/re/season_stats_re.md + docs/re/statistics_row_widget_re.md.
##
##   * FUN_0044e440  the period-transition commit  -> commit()
##                   (oracle: tools/re/run_statcommit_oracle.sh -> specs/statcommit_oracle.txt)
##   * FUN_00449990 / FUN_00449a70  find-by-id-else-append, then OVERWRITE
##   * FUN_00448b60 @0x448f6b / @0x44907a  the season fold-back -> fold_back()
##   * FUN_004afce0  the STATISTICS row-widget draw -> row_cells() / rating()
##
## TWO STORES, ONE 0x48-BYTE RECORD.
##   report    DAT_0066afd0+0x9c/+0xa0 (home) and +0xa4/+0xa8 (away), rebuilt per fixture
##   persistent playerobj+0x24 .. +0x64, a per-field RUNNING SEASON TOTAL
## The commit OVERWRITES the report record (it is not an accumulator) and then zeroes the
## participant's +0xec..+0x12f block, so a report record only ever holds the stats since
## the last commit. Season figures come from the fold-back, never from repeated commits.
##
## record + K  ==  participant + 0xec + K   for K = 0x00 .. 0x43
## record + 0x44 == participant + 0x88      (the global player id, u16)
## record + 0x46 is never written.


# --- record geometry --------------------------------------------------------
const REC_SIZE := 0x48        # one report record
const REC_BLOCK := 0x44       # the part copied verbatim from participant +0xec
const REC_DWORDS := 17        # 0x44 / 4 -- what the fold-back adds and the totals sum
const PART_BLOCK := 0xec      # participant offset the block starts at

# Record field offsets. Names are the STATISTICS column labels established by the row
# widget's draw method; +0x38 and +0x40 have no identified producer and stay unnamed.
const R_MP := 0x00            # appeared flag; the commit forces 1
const R_MIN := 0x04           # minutes played
const R_INVOLVE := 0x08       # FUN_00450510 involvement tally; never displayed
const R_MOM := 0x0c           # man of the match
const R_GOALS := 0x10
const R_SHOTS_ON := 0x14
const R_SHOTS_OFF := 0x18
const R_PASS_OK := 0x1c
const R_PASS_FAIL := 0x20
const R_TACK_OK := 0x24
const R_TACK_FAIL := 0x28
const R_SAVES := 0x2c
const R_YELLOW := 0x30
const R_RED := 0x34
const R_F38 := 0x38           # UNNAMED -- disqualifies from MoM when nonzero
const R_INJURY := 0x3c
const R_F40 := 0x40           # UNNAMED
const R_PID := 0x44           # u16 search key

# Report-object (DAT_0066afd0) byte offsets the commit writes.
const F_POSS0 := 0x18         # u16 <- M+0x64
const F_POSS1 := 0x1a         # u16 <- M+0x804
const F_HOME_CLUB := 0x38     # u16, set by the match ctor
const F_AWAY_CLUB := 0x3a     # u16
const F_GOALS_H := 0x3c       # u8 scoreline counters
const F_GOALS_A := 0x3d
const F_ET_H := 0x4c
const F_ET_A := 0x4d
const F_PEN_H := 0x54
const F_PEN_A := 0x55
const F_MOM_PID := 0xac       # u16, written by FUN_0044a370 (selector NOT ported)

# Marker vector (F+0x94/+0x98), stride 0xc: {kind, minute | teamid<<16, pid}
const MARK_STRIDE := 0xc
const MARK_ASSIST := 1
const MARK_SHOT := 2


## One fixture's report object: the two record arrays plus the header bytes the commit
## touches. Mirrors DAT_0066afd0 closely enough that the oracle can be asserted directly.
class Report extends RefCounted:
	var hdr: PackedByteArray            # F+0x00 .. +0xff
	var home: PackedByteArray           # record array, stride 0x48
	var home_count: int = 0
	var away: PackedByteArray
	var away_count: int = 0
	var markers: PackedByteArray        # 0xc stride
	var marker_count: int = 0
	## FUN_004497f0 (the display event-list rebuild) is NOT reversed. The binary calls it
	## once per match event with the mapped report code (type 0..4 -> 1..5); we record the
	## call order so the dispatch stays observable, exactly like the oracle's stub.
	var event_codes: PackedInt32Array
	## Condition write-back: pid -> byte, clamped to 0x63 (the binary stores it into
	## playerobj+0xa8; the port has no global player table so it is surfaced here).
	var condition: Dictionary

	func _init(home_club: int = 0, away_club: int = 0) -> void:
		hdr = PackedByteArray(); hdr.resize(0x100)
		home = PackedByteArray()
		away = PackedByteArray()
		markers = PackedByteArray()
		event_codes = PackedInt32Array()
		condition = {}
		hdr.encode_u16(F_HOME_CLUB, home_club & 0xFFFF)
		hdr.encode_u16(F_AWAY_CLUB, away_club & 0xFFFF)

	func _arr(side: int) -> PackedByteArray:
		return home if side == 0 else away

	func count(side: int) -> int:
		return home_count if side == 0 else away_count

	## Record `idx` of `side` as 17 signed dwords (rec+0x00 .. +0x40).
	func fields(side: int, idx: int) -> PackedInt32Array:
		var a := _arr(side)
		var base := idx * REC_SIZE
		var out := PackedInt32Array(); out.resize(REC_DWORDS)
		for k in range(REC_DWORDS):
			out[k] = a.decode_s32(base + k * 4)
		return out

	func field(side: int, idx: int, off: int) -> int:
		return _arr(side).decode_s32(idx * REC_SIZE + off)

	func pid(side: int, idx: int) -> int:
		return _arr(side).decode_u16(idx * REC_SIZE + R_PID)

	func marker(idx: int) -> Dictionary:
		var b := idx * MARK_STRIDE
		return {
			"kind": markers.decode_s32(b),
			"value": markers.decode_s32(b + 4),
			"pid": markers.decode_u16(b + 8),
		}


# --- FUN_00449990 / FUN_00449a70: find-by-id-else-append, then OVERWRITE -----
## `rec` is a REC_SIZE-byte record whose +0x44 holds the id. Returns the slot index.
## Verified by the oracle: a duplicate id yields 10 home records, not 11 (E_duppid), and
## a zero id is never offered here at all (B_partial -> 9 / 10).
static func _add_or_replace(rep: Report, side: int, rec: PackedByteArray) -> int:
	var arr: PackedByteArray = rep.home if side == 0 else rep.away
	var n: int = rep.home_count if side == 0 else rep.away_count
	var id := rec.decode_u16(R_PID)
	var slot := -1
	for i in range(n):
		if arr.decode_u16(i * REC_SIZE + R_PID) == id:
			slot = i
			break
	if slot < 0:
		slot = n
		n += 1
		arr.resize(n * REC_SIZE)
	for k in range(REC_SIZE):
		arr[slot * REC_SIZE + k] = rec[k]
	if side == 0:
		rep.home = arr
		rep.home_count = n
	else:
		rep.away = arr
		rep.away_count = n
	return slot


static func _append_marker(rep: Report, kind: int, value: int, pid: int) -> void:
	var b := rep.marker_count * MARK_STRIDE
	rep.markers.resize(b + MARK_STRIDE)
	rep.markers.encode_s32(b, kind)
	rep.markers.encode_s32(b + 4, value)
	rep.markers.encode_s32(b + 8, pid)      # +0x0a takes the high half of the dword store
	rep.marker_count += 1


static func _bump(hdr: PackedByteArray, off: int) -> void:
	hdr.encode_u8(off, (hdr.decode_u8(off) + 1) & 0xFF)


# --- FUN_0044e440: the stat commit ------------------------------------------
## Called by every period-transition handler (FUN_0044d0d0/d190/d250/d310/d3d0/d520) and
## by the driver's tail (@0x44f2b0). Copies each selected participant's +0xec..+0x12f
## block into the report, zeroes the participant block, rebuilds the scoreline counters
## from the event vector and clamps the condition byte.
##
## `pids` is a PORT BRIDGE, not a binary feature. MANAGER.EXE keys every record on
## participant `+0x88`, which is the **global** player id. `Pm98StatMatch._fill_participant`
## writes slot+1 there instead (game_db XIs carry no id, and `goal_events()` maps
## `shirt-1` back to the XI index), so with the default the two sides collide on ids
## 1..11 and a season store keyed on them would merge both teams. Callers that want real
## season stats must pass `pids[side * 11 + idx] = <global player id>`; selection is still
## gated on `+0x88 != 0` exactly as the binary gates it.
## A HALF-TIME snapshot of the running per-player totals into `rep`, WITHOUT the
## participant zeroing `commit` does. This is what the PRESENTED branch's half-time
## board reads: the live sheets show a half-time table whose every column is a PREFIX of
## the full-time one (Man Utd SHOTS 7/9 -> 10/13, MIN 45 -> 90, frames 02 and 06 of
## screenshots/wine-captures-2026-07-24-statistics-live/), which running totals produce
## and per-period records do not. Zeroing here would break `CADENCE_MATCH`'s single
## whole-match commit, so this deliberately leaves `+0xec..+0x12f` alone.
##
## The header/event half is skipped: the half-time board's own goal + booking columns are
## drawn from the match's event vector by the caller, not from these records.
static func snapshot(mem: Pm98StatMatch.Mem, rep: Report, pids := {}) -> void:
	for side in range(2):
		for idx in range(11):
			var pb := Pm98StatMatch._player(side, idx)
			var pid := mem.u16(pb + Pm98StatMatch.SEL)
			if pid == 0:
				continue
			pid = int(pids.get(side * 11 + idx, pid))
			mem.set_s32(pb + PART_BLOCK, 1)                # rec+0x00 forced to 1, as commit does
			var rec := PackedByteArray(); rec.resize(REC_SIZE)
			for k in range(REC_BLOCK):
				rec[k] = mem.u8(pb + PART_BLOCK + k)
			rec.encode_u16(R_PID, pid)
			_add_or_replace(rep, side, rec)


static func commit(mem: Pm98StatMatch.Mem, rep: Report, pids := {}) -> void:
	# 1. header copy (@0x44e470..0x44e52d)
	rep.hdr.encode_u16(F_POSS0, mem.u16(Pm98StatMatch.POSS))
	rep.hdr.encode_u16(F_POSS1, mem.u16(Pm98StatMatch.SIDE_STRIDE + Pm98StatMatch.POSS))
	rep.hdr.encode_s32(0x30, mem.s32(0x28))
	rep.hdr.encode_u8(0x34, mem.u8(0x2c))
	rep.hdr.encode_u8(0x35, mem.u8(0x30))
	rep.hdr.encode_u8(0x36, mem.u8(0x34))
	rep.hdr.encode_u8(0x37, mem.u8(0x38))
	rep.hdr.encode_s32(0x40, mem.s32(0x1c))
	rep.hdr.encode_s32(0x48, mem.s32(0x20))
	rep.hdr.encode_s32(0x50, mem.s32(0x24))
	rep.hdr.encode_s32(0xb4, mem.s32(0x3c))
	rep.hdr.encode_s32(0xb8, mem.s32(0x40))

	# FUN_00449960: drop the old display list and zero the six scoreline counters.
	rep.event_codes = PackedInt32Array()
	for off in [F_GOALS_H, F_GOALS_A, F_ET_H, F_ET_A, F_PEN_H, F_PEN_A]:
		rep.hdr.encode_u8(off, 0)

	# 2. event loop (@0x44e530..0x44e694). The payload's low u16 is the credited team id;
	# it is tested against F+0x38 and F+0x3a INDEPENDENTLY (not else-if). p4 != 0 is an
	# own goal and flips the side. Extra-time goals (types 2/3) bump the ET pair AND fall
	# through into the goal pair. Type 4 (penalties) has no p4 flip.
	var home_id := rep.hdr.decode_u16(F_HOME_CLUB)
	var away_id := rep.hdr.decode_u16(F_AWAY_CLUB)
	for e in mem.events:
		var t := int(e["type"])
		var team := int(e["payload"]) & 0xFFFF
		var own := int(e["p4"]) != 0
		if t == 2 or t == 3:
			if team == home_id:
				_bump(rep.hdr, F_ET_A if own else F_ET_H)
			if team == away_id:
				_bump(rep.hdr, F_ET_H if own else F_ET_A)
		if t >= 0 and t <= 3:
			if team == home_id:
				_bump(rep.hdr, F_GOALS_A if own else F_GOALS_H)
			if team == away_id:
				_bump(rep.hdr, F_GOALS_H if own else F_GOALS_A)
		elif t == 4:
			if team == home_id:
				_bump(rep.hdr, F_PEN_H)
			if team == away_id:
				_bump(rep.hdr, F_PEN_A)
		if t >= 0 and t <= 4:
			rep.event_codes.append(t + 1)   # table 0x44ea2c: type 0..4 -> report code 1..5

	# 3 + 4. per-player commit, both sides x 11 (@0x44e6b0..0x44e9b2), then the condition
	# write-back tail (@0x44e9b8..0x44ea0c).
	for side in range(2):
		var team_id := mem.u16(side * Pm98StatMatch.SIDE_STRIDE + Pm98StatMatch.TEAMID)
		for idx in range(11):
			var pb := Pm98StatMatch._player(side, idx)
			var pid := mem.u16(pb + Pm98StatMatch.SEL)
			if pid == 0:
				continue                                   # a zero id is skipped entirely
			pid = int(pids.get(side * 11 + idx, pid))
			mem.set_s32(pb + PART_BLOCK, 1)                # rec+0x00 forced to 1 (@0x44e770)
			var rec := PackedByteArray(); rec.resize(REC_SIZE)
			for k in range(REC_BLOCK):
				rec[k] = mem.u8(pb + PART_BLOCK + k)
			rec.encode_u16(R_PID, pid)                     # +0x46 stays 0 (never written)
			_add_or_replace(rep, side, rec)
			for k in range(REC_BLOCK):
				mem.set_u8(pb + PART_BLOCK + k, 0)         # zero +0xec..+0x12f
			# markers: assists from +0xd4/+0xd8 (minutes +0xe0/+0xe4), shot from +0xdc
			# (minute +0xe8). value = minute | teamid << 16.
			if mem.s32(pb + Pm98StatMatch.D4) != 0:
				_append_marker(rep, MARK_ASSIST,
					mem.s32(pb + Pm98StatMatch.E0) | (team_id << 16), pid)
			if mem.s32(pb + Pm98StatMatch.D8) != 0:
				_append_marker(rep, MARK_ASSIST,
					mem.s32(pb + Pm98StatMatch.E4) | (team_id << 16), pid)
			if mem.s32(pb + Pm98StatMatch.DC) != 0:
				_append_marker(rep, MARK_SHOT,
					mem.s32(pb + Pm98StatMatch.E8) | (team_id << 16), pid)
			rep.condition[pid] = mini(mem.u8(pb + 0xb8), 0x63)


# --- FUN_0044a370: the MAN OF THE MATCH selector ----------------------------
## The selector's score, recomputed per record from the same four success ratios the row
## widget's RATING uses (`@0x44a463..0x44a617`). It is RATING's inner term before the
## `4 + 6*x/100` wrapper, so the two are the same measure on different scales.
static func mom_score(f: PackedInt32Array) -> int:
	var a := _ratio(f[R_INVOLVE / 4], f[R_MIN / 4])
	var b := _ratio(f[R_SHOTS_ON / 4], f[R_SHOTS_OFF / 4])
	var c := _ratio(f[R_PASS_OK / 4], f[R_PASS_FAIL / 4])
	var d := _ratio(f[R_TACK_OK / 4], f[R_TACK_FAIL / 4])
	return ((a + b + c + d) >> 2) + 10 * mini(f[R_GOALS / 4], 10)


## Pick the Man of the Match: the highest-scoring record across the home array then the
## away array, writing its pid into the report header (`F+0xac`) and returning it.
## Returns 0 when no record survives the gates -- the binary zeroes `F+0xac` first
## (`@0x44a382`) and simply leaves it at 0, so nobody is stamped.
##
## Banked against the real function: `tools/re/run_moms_oracle.sh` ->
## `tools/re/specs/moms_oracle.txt`, asserted by `app/tests/test_mom_oracle.gd`.
## The oracle pins all four behaviours below, including that the FIRST record wins a tie
## both inside one array (E_tie_home) and across the two (F/G_tie_cross).
##
## GAP, deliberately not modelled: on an exact score tie the binary runs a second
## tie-break that walks the display event list (`F+0x64` entries via FUN_00449660,
## `@0x44a7f6..0x44a832`) and counts the entries naming each record, with the stubbed
## FUN_00448a00 result code steering the final choice (`@0x44a871..0x44a8b9`). Every
## oracle fixture runs with `F+0x64 == 0`, where that loop cannot iterate and the result
## code provably does not change the outcome (F and G differ only in it and both return
## pid 11). With a populated event list the outcome is UNKNOWN, so it is not guessed.
static func pick_mom(rep: Report) -> int:
	var best := -1
	var best_pid := 0
	for side in range(2):
		for i in range(rep.count(side)):
			var f := rep.fields(side, i)
			if f[R_F38 / 4] != 0:              # @0x44a40c
				continue
			if f[R_YELLOW / 4] >= 2:           # two yellows, @0x44a448
				continue
			if f[R_RED / 4] != 0:              # a red, @0x44a455
				continue
			var s := mom_score(f)
			if s > best:                       # `jbe` @0x44a617 -> the FIRST wins a tie
				best = s
				best_pid = rep.pid(side, i)
	rep.hdr.encode_u16(F_MOM_PID, best_pid)
	return best_pid


# --- FUN_00448b60 @0x448f6b / @0x44907a: the season fold-back ---------------
## Adds every report record into the persistent per-player store, field by field. The
## binary writes playerobj+0x24 + 4k; here `store` is a Dictionary pid ->
## PackedInt32Array(17) holding the same 17 dwords in the same order.
##
## `mom_pid` is DAT_0066afd0+0xac (FUN_0044a370's pick). Passing 0 stamps nobody. The
## binary re-stamps rec+0x0c = 1 inside this loop, so the report row the STATISTICS
## screen renders and the season total both see the MoM flag.
##
## The runner skips the whole fold-back when its first argument is 0 (@0x448f5d), which
## is why `commit()` and `fold_back()` are separate calls here too.
static func fold_back(rep: Report, store: Dictionary, mom_pid: int = -1) -> void:
	var mom := rep.hdr.decode_u16(F_MOM_PID) if mom_pid < 0 else (mom_pid & 0xFFFF)
	for side in range(2):
		var arr: PackedByteArray = rep.home if side == 0 else rep.away
		var n: int = rep.home_count if side == 0 else rep.away_count
		for i in range(n):
			var base := i * REC_SIZE
			var pid := arr.decode_u16(base + R_PID)
			if mom != 0 and pid == mom:
				arr.encode_s32(base + R_MOM, 1)
			var acc: PackedInt32Array = store.get(pid, PackedInt32Array())
			if acc.size() != REC_DWORDS:
				acc = PackedInt32Array(); acc.resize(REC_DWORDS)
			for k in range(REC_DWORDS):
				acc[k] += arr.decode_s32(base + k * 4)
			store[pid] = acc
		# Packed arrays are copy-on-write in GDScript, so the MoM stamp above lands on a
		# local copy until it is written back.
		if side == 0:
			rep.home = arr
		else:
			rep.away = arr


# --- FUN_004afce0: the STATISTICS row widget --------------------------------
## The draw method's percentage helper (`@0x4b0426` and friends): 100*n/(n+d), and 0 for
## an empty pair. Unsigned truncating division.
static func _ratio(n: int, d: int) -> int:
	var t := n + d
	return 0 if t == 0 else (100 * n) / t


## RATING is NOT stored anywhere -- the widget recomputes it from the record on every
## paint (`@0x4b03f6..0x4b04cb`), and FUN_0044a370 recomputes the same score to pick the
## Man of the Match. Range 4..16. Note the first ratio's numerator is rec+0x08 and its
## denominator partner is rec+0x04 (the minutes), which is the reverse of the other three.
static func rating(f: PackedInt32Array) -> int:
	var a := _ratio(f[R_INVOLVE / 4], f[R_MIN / 4])
	var b := _ratio(f[R_SHOTS_ON / 4], f[R_SHOTS_OFF / 4])
	var c := _ratio(f[R_PASS_OK / 4], f[R_PASS_FAIL / 4])
	var d := _ratio(f[R_TACK_OK / 4], f[R_TACK_FAIL / 4])
	var m := (a + b + c + d) >> 2
	return 4 + (6 * (m + 10 * mini(f[R_GOALS / 4], 10))) / 100


## The twelve numeric cells of one STATISTICS row, already formatted the way the widget
## prints them: a single cell is "-" when the value is 0, an x/y pair is "-/-" when both
## fields are 0 and otherwise "first/(first+second)". RATING prints "-" until MIN > 0.
## `extended` mirrors widget+0x438 != 0, which gates the MoM and injury cells.
static func row_cells(f: PackedInt32Array, extended := true) -> Dictionary:
	return {
		"MP": _cell(f[R_MP / 4]),
		"MIN": _cell(f[R_MIN / 4]),
		"RATING": str(rating(f)) if f[R_MIN / 4] > 0 else "-",
		"MoM": (_cell(f[R_MOM / 4]) if extended else "-"),
		"G.": _cell(f[R_GOALS / 4]),
		"SHOTS": _pair(f[R_SHOTS_ON / 4], f[R_SHOTS_OFF / 4]),
		"PASSES": _pair(f[R_PASS_OK / 4], f[R_PASS_FAIL / 4]),
		"TAC.": _pair(f[R_TACK_OK / 4], f[R_TACK_FAIL / 4]),
		"S.": _cell(f[R_SAVES / 4]),
		"yellow": _cell(f[R_YELLOW / 4]),
		"red": _cell(f[R_RED / 4]),
		"injury": (_cell(f[R_INJURY / 4]) if extended else "-"),
	}


static func _cell(v: int) -> String:
	return "-" if v == 0 else str(v)


static func _pair(n: int, d: int) -> String:
	return "-/-" if n + d == 0 else "%d/%d" % [n, n + d]


## One side's MATCH records, ordered to match `xi` — what the HALF TIME / FULL TIME
## board's per-team STATISTICS button shows. `@0x4b1fd3` / `@0x4b20f5` is the binary's
## own path: it `rep movsd`-copies the records straight out of the report array
## (`DAT_0066afd0+0xa4` / `+0x9c`) rather than rebuilding them from the persistent store,
## so these are the stats SINCE THE LAST COMMIT — this match, not the season.
##
## Records are keyed on the global player id (`rec+0x44`), which `MatchSim.pid_map`
## supplies to `commit`. A player with no record yields an all-zero row, which the widget
## prints as the original's dashes.
static func match_rows(rep, side: int, xi: Array) -> Array:
	var by_pid: Dictionary = {}
	if rep != null:
		for i in rep.count(side):
			by_pid[rep.pid(side, i)] = rep.fields(side, i)
	var out: Array = []
	for p in xi:
		var f := PackedInt32Array()
		f.resize(REC_DWORDS)
		if p is Dictionary:
			var pid := int((p as Dictionary).get("id", -1))
			if by_pid.has(pid):
				f = by_pid[pid]
		out.append(f)
	return out


## The TEAM TOTAL row (`@0x4b2322..0x4b246c`). `+0x00` and `+0x04` are NOT column sums:
## the report-array path writes a constant 1 and the MAX of rec+0x04, everything from
## `+0x08` to `+0x40` is a per-column sum. (Rendering from the persistent store instead
## substitutes a vtable total and `club+0x274`; pass those in as `mp` / `minutes`.)
static func totals(rows: Array, mp := 1, minutes := -1) -> PackedInt32Array:
	var out := PackedInt32Array(); out.resize(REC_DWORDS)
	var max_min := 0
	for r in rows:
		var f: PackedInt32Array = r
		max_min = maxi(max_min, f[R_MIN / 4])
		for k in range(2, REC_DWORDS):
			out[k] += f[k]
	out[R_MP / 4] = mp
	out[R_MIN / 4] = max_min if minutes < 0 else minutes
	return out
