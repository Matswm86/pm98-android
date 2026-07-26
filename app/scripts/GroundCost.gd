class_name GroundCost
extends RefCounted

## GROUND IMPROVEMENTS cost model — MANAGER.EXE `FUN_0057ddd0` @0x0057ddd0, byte-exact.
##
## The original computes every improvement price from one 15-way category table over a
## 9-way club-tier table (docs/re/stadium_screen_re.md "Cost function"). The tier byte is
## `ground+0x24`, and `FUN_0057ed09`/`FUN_0057d780` show it is copied straight from
## `club+0x58` — the club's STATURE band, the same 0-12 value the fee/wage tables use
## (TransferMarket.stature_of, docs/re/transfer_value_re.md).
##
##     price_f32 = tierTable[category][min(tier, 8) or default]     (x0.5 for SEATS)
##     gbp       = trunc( f32(weeks * 1e6 * price_f32) / 200 )
##
## The /200 is the game-wide money display convention already reversed for transfer fees.
## The f32 store is what produces the original's own off-by-one dirt (£10,624,999 for the
## Man Utd +12,000-seat card), so it is reproduced rather than rounded away.
##
## Table data: app/data/ground_cost_table.json, walked out of the real binary's jump tables
## by tools/re/extract_ground_prices.py (20/20 witnessed prices exact).

const TABLE_PATH := "res://data/ground_cost_table.json"

# Category ids as the original passes them to FUN_0057ddd0 (1-based).
const CAT_SEATS := "seats"
const CAT_CAR_PARK := ["car_park_ne", "car_park_nw", "car_park_se", "car_park_sw"]
# FACILITIES then SERVICES, in the GROUND ledger's own order.
const CAT_FACILITIES := [
	"floodlights", "under_soil_heating", "changing_rooms",
	"score_board", "access_to_the_stadium",
]
const CAT_SERVICES := ["medical_equipment", "club_shop", "cafes", "toilets"]

static var _table: Dictionary = {}


static func _load() -> Dictionary:
	if not _table.is_empty():
		return _table
	var f := FileAccess.open(TABLE_PATH, FileAccess.READ)
	if f == null:
		push_error("GroundCost: %s missing" % TABLE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary and (parsed as Dictionary).has("categories"):
		_table = parsed
	return _table


## The x87 epilogue verbatim: FILD weeks ; FMUL double 1e6 ; FMUL float price ; FSTP float,
## then the money display path's /200 and its truncation toward zero.
static func gbp(weeks: int, price: float) -> int:
	var raw := PackedFloat32Array([float(weeks) * 1000000.0 * price])
	return int(float(raw[0]) / 200.0)


## The f32 price coefficient for one (category, club tier, item index).
static func coefficient(category: String, tier: int, index: int) -> float:
	var t := _load()
	if t.is_empty():
		return 0.0
	var rec: Dictionary = (t["categories"] as Dictionary).get(category, {})
	if rec.is_empty():
		return 0.0
	if rec.has("price_flat"):
		return float(rec["price_flat"])
	if rec.has("price_by_index"):
		return float((rec["price_by_index"] as Dictionary).get(str(index), 0.0))
	var arms: Array = rec["price_by_tier"]
	# The switch covers tiers 0..8; a stature band above that lands on the arm's default.
	if tier >= 0 and tier < arms.size():
		return float(arms[tier])
	return float(rec["price_default"])


## Build weeks for one (category, item index). Categories with a fixed build time ignore
## the index; SEATS (three offer cards), CLUB SHOP and CAFES read it.
static func weeks(category: String, index: int) -> int:
	var t := _load()
	if t.is_empty():
		return 0
	var rec: Dictionary = (t["categories"] as Dictionary).get(category, {})
	if rec.is_empty():
		return 0
	if rec.has("weeks_by_index") and not (rec["weeks_by_index"] as Dictionary).is_empty():
		return int((rec["weeks_by_index"] as Dictionary).get(str(index), 0))
	return int(rec.get("weeks_flat", 0))


## The original's cost for one improvement: {"gbp": int, "weeks": int}.
static func quote(category: String, tier: int, index: int) -> Dictionary:
	var w := weeks(category, index)
	return {"gbp": gbp(w, coefficient(category, tier, index)), "weeks": w}


## The three SEATS offer-card prices (+4,000 / +8,000 / +12,000) for a club tier.
static func seat_prices(tier: int) -> Array:
	var out: Array = []
	for i in 3:
		out.append(quote(CAT_SEATS, tier, i)["gbp"])
	return out


## The CAR PARK per-level price (all four quadrants share one table).
static func car_park_price(tier: int) -> int:
	return quote(CAT_CAR_PARK[0], tier, 0)["gbp"]
