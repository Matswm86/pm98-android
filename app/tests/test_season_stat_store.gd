extends SceneTree
## Career <-> Pm98StatStore wiring: the fold-back, the two club counters, the row/total
## builders the STATISTICS screen consumes, JSON round-trip and the season reset.
##
## The RENDER side of this feature is verified separately and is the real acceptance
## bar: tools/re/diff_statistics_parity.py reports 0 differing pixels against
## screenshots/wine-captures-2026-07-24-cadence-season-store/01_season_store_before_7matches.png.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_season_stat_store.gd

var _fail := 0
var _pass := 0


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
		print("  [PASS] %s" % name)
	else:
		_fail += 1
		print("  [FAIL] %-44s got=%s exp=%s" % [name, str(got), str(exp)])


## A finished-fixture result the way MatchSim returns one, with `n` home records whose
## MIN is 90 and whose goals ascend, so the MoM pick is predictable.
func _res(pids: Array) -> Dictionary:
	var rep := Pm98StatStore.Report.new(40, 17)
	var arr := PackedByteArray()
	for i in pids.size():
		var r := PackedByteArray()
		r.resize(Pm98StatStore.REC_SIZE)
		r.encode_s32(Pm98StatStore.R_MP, 1)
		r.encode_s32(Pm98StatStore.R_MIN, 90)
		r.encode_s32(Pm98StatStore.R_GOALS, i)
		r.encode_s32(Pm98StatStore.R_PASS_OK, 5)
		r.encode_s32(Pm98StatStore.R_PASS_FAIL, 3)
		r.encode_u16(Pm98StatStore.R_PID, int(pids[i]))
		arr.append_array(r)
	rep.home = arr
	rep.home_count = pids.size()
	return {"report": rep}


func _initialize() -> void:
	print("== Career season stat store ==")
	var c := Career.new()
	c.club_id = 40

	# --- MatchSim.pid_map: the mandatory slot -> global id bridge -------------
	var xi_h: Array = []
	var xi_a: Array = []
	for i in 11:
		xi_h.append({"id": 100 + i})
		xi_a.append({"id": 200 + i})
	var pm := MatchSim.pid_map(xi_h, xi_a)
	_ck("pid_map.home_slot0", pm.get(0), 100)
	_ck("pid_map.away_slot0", pm.get(11), 200)
	_ck("pid_map.size", pm.size(), 22)
	# Without the bridge both sides would collide on slot+1; with it they cannot.
	var uniq: Dictionary = {}
	for v in pm.values():
		uniq[v] = true
	_ck("pid_map.ids_unique", uniq.size(), 22)
	# A slot with no decoded id is left out rather than given an invented one.
	_ck("pid_map.skips_idless", MatchSim.pid_map([{"id": 7}, {}], []).size(), 1)

	# --- fold_back + the two club counters -----------------------------------
	c.fold_match_stats(_res([501, 502, 503]), 40, 17)
	_ck("fold.min", (c.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 90)
	_ck("fold.mp", (c.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MP / 4], 1)
	_ck("fold.goals", (c.season_stats[503] as PackedInt32Array)[Pm98StatStore.R_GOALS / 4], 2)
	_ck("fold.mom_top_scorer",
		(c.season_stats[503] as PackedInt32Array)[Pm98StatStore.R_MOM / 4], 1)
	_ck("fold.mom_not_others",
		(c.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MOM / 4], 0)
	_ck("fold.club_minutes", c.season_club_minutes[40], 90)
	_ck("fold.club_minutes_opp", c.season_club_minutes[17], 90)
	_ck("fold.club_mp", c.season_club_mp[40], 1)

	# A second fixture ADDS (the witnessed 630 -> 720 shape), it does not overwrite.
	c.fold_match_stats(_res([501, 502, 503]), 40, 17)
	_ck("fold2.min", (c.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 180)
	_ck("fold2.club_minutes", c.season_club_minutes[40], 180)
	_ck("fold2.club_mp", c.season_club_mp[40], 2)

	# A cup tie bumps MINUTES but NOT the MP counter (the live witness: 630 -> 720 while
	# the TEAM TOTAL MP stayed 7).
	c.fold_match_stats(_res([501]), 40, 17, false)
	_ck("fold_cup.club_minutes", c.season_club_minutes[40], 270)
	_ck("fold_cup.club_mp_unchanged", c.season_club_mp[40], 2)

	# A two-legged tie's extra time folds its PLAYER records but must not bill the club
	# counters again -- it is the same fixture as leg 2.
	c.fold_match_stats(_res([501]), 40, 17, false, false)
	_ck("fold_et.min_still_grows",
		(c.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 360)
	_ck("fold_et.club_minutes_unchanged", c.season_club_minutes[40], 270)
	_ck("fold_et.club_mp_unchanged", c.season_club_mp[40], 2)

	# A legacy-fallback result carries no report and must be a no-op, not a crash.
	c.fold_match_stats({"report": null}, 40, 17)
	_ck("fold_null.noop", c.season_club_minutes[40], 270)

	# --- the screen's row + total builders ------------------------------------
	var players: Array = [{"id": 501}, {"id": 999}, {"id": 503}]
	var rows := c.season_stat_rows(players)
	_ck("rows.count", rows.size(), 3)
	_ck("rows.featured", (rows[0] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 360)
	_ck("rows.unused_is_zero", (rows[1] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 0)
	_ck("rows.unused_prints_dash", Pm98StatStore.row_cells(rows[1])["MP"], "-")
	var tot := c.season_stat_totals(rows, 40)
	# MP and MIN are the CLUB counters, not column sums (@0x4b21ed / @0x4b221a).
	_ck("totals.mp_is_club_counter", tot[Pm98StatStore.R_MP / 4], 2)
	_ck("totals.min_is_club_counter", tot[Pm98StatStore.R_MIN / 4], 270)
	# Everything from +0x08 rightwards IS a column sum: 501 folded 4 records at 5
	# completed passes and 503 folded 2, so the column reads 30.
	_ck("totals.passes_ok", tot[Pm98StatStore.R_PASS_OK / 4], 30)
	_ck("totals.goals", tot[Pm98StatStore.R_GOALS / 4], 4)

	# --- JSON round-trip -------------------------------------------------------
	var back := Career.from_dict(c.to_dict())
	_ck("json.stats_kept",
		(back.season_stats[501] as PackedInt32Array)[Pm98StatStore.R_MIN / 4], 360)
	_ck("json.record_is_packed", back.season_stats[501] is PackedInt32Array, true)
	_ck("json.record_len", (back.season_stats[501] as PackedInt32Array).size(),
		Pm98StatStore.REC_DWORDS)
	_ck("json.club_minutes_kept", back.season_club_minutes[40], 270)
	_ck("json.club_mp_kept", back.season_club_mp[40], 2)
	# A pre-STATISTICS save has no key at all and must load clean.
	_ck("json.legacy_save", Career.from_dict({}).season_stats.size(), 0)

	print("%d checks, %d failed" % [_pass + _fail, _fail])
	print("ALL PASS" if _fail == 0 else "FAILED")
	quit(1 if _fail > 0 else 0)
