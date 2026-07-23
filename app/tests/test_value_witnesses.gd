extends SceneTree
## FEE + WAGE table validation, league-wide, at the CODE level. Mirrors tools/re/
## validate_value_model.py (which proves the RE'd FUN_00576cd0 tables reproduce the witnesses)
## but runs against the APP's shipped res://data/value_tables.json and TransferMarket's own
## ability-tier map, so a drift between the RE'd tables and what the game actually loads is
## caught here. Each witness is (on-screen AV, CLUB FEE £, YEARLY WAGE £) from
## transfer_value_re.md §2/§10; the age tier is unknown for the transfer-market rows, so — as in
## the source validator — we require SOME (band 0-12, ageTier 0-5) to reproduce fee AND wage
## jointly. That spans stature bands 0..7 (elite Berger/Scholes → Div-2 Taylor), closing the
## "fee/wage across the whole league" gap the 07-23 handoff left open, with no invented data.
##   ~/godot4 --headless --path app --script res://tests/test_value_witnesses.gd

const MULT := 5000
const BANDS := 13
const AGE_TIERS := 6
# (name, AV, fee, wage) — transfer_value_re.md §10 validation set (Spiteri's AV is 65 by core4,
# §10 note: his on-screen "78" was a mis-read, so use 65).
const W := [
	["Wilson", 59, 5000, 5000], ["Martindale", 54, 25000, 10000], ["Rickers", 53, 50000, 5000],
	["Carragher", 57, 75000, 5000], ["Van Blerk", 68, 90000, 25000], ["Kadijevic", 73, 150000, 30000],
	["Spiteri", 65, 150000, 25000], ["Gojkovic", 71, 850000, 35000], ["Villarroya", 74, 500000, 90000],
	["Roberts", 78, 1500000, 125000], ["Marcelle", 78, 650000, 175000], ["Scholes", 81, 8500000, 575000],
	["Berger", 88, 11000000, 1000000],
]


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/value_tables.json", FileAccess.READ)
	var j: Dictionary = JSON.parse_string(f.get_as_text())
	var fee_t: Array = j.get("fee_table", [])
	var wage_t: Array = j.get("wage_table", [])
	var ok := true
	ok = _assert(fee_t.size() == BANDS * 9 * AGE_TIERS and wage_t.size() == fee_t.size(),
		"tables are 13 bands x 9 abil x 6 age = %d words (got fee %d / wage %d)"
		% [BANDS * 9 * AGE_TIERS, fee_t.size(), wage_t.size()]) and ok

	for w in W:
		var name: String = w[0]
		var av: int = w[1]
		var fee: int = w[2]
		var wage: int = w[3]
		var abil := TransferMarket._ability_tier(av)     # the LIVE app's AV->tier map
		var bands: Array = []
		for band in BANDS:
			for at in AGE_TIERS:
				var i := band * 54 + abil * 6 + at
				if int(fee_t[i]) * MULT == fee and int(wage_t[i]) * MULT == wage:
					if not bands.has(band):
						bands.append(band)
		ok = _assert(not bands.is_empty(),
			"%-11s AV%3d -> fee £%d + wage £%d reproduced by app tables at bands %s"
			% [name, av, fee, wage, str(bands)]) and ok

	print("ALL PASS" if ok else "FAILURES ABOVE")
	return ok


func _assert(cond: bool, msg: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])
	return cond
