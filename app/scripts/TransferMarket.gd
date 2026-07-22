class_name TransferMarket
extends RefCounted
## Transfer market for a PM98 career: player valuation (CLUB FEE + YEARLY WAGE),
## the buyable market, offer evaluation, and AI-to-AI player movement so the league
## around you stays alive. Squad mutation + persistence live on Career; this class is
## the pure economic model (GameDB-free, headless-testable).
##
## Authentic PM98 surface (strings scanned from MANAGER.EXE this session):
##   TRANSFER MARKET / OFFERS / CURRENT OFFERS / SIGN PLAYER / SALE + LOAN PLAY. /
##   RENEW / LOAN PLAYER, CLUB FEE / YEARLY WAGE / MONTHLY WAGE / FREE TRANSFER /
##   ON LOAN / "Free if relegated", and the message templates
##   "You do not have enough money to make this offer.",
##   "The Directors will only let you make %u offer%s to sign a player per week.",
##   "%s%s has rejected your offer for %s.", "%s has rejected your offer for renewal.",
##   "You have signed %s, %s%s.", "%s has been signed by %s%s.",
##   "%s has renewed his contract.",
##   "%s has left your club as his contract has not been renewed",
##   "The transfer deadline is now %u week%s away."
##
## The fee + wage VALUES are the real PM98 model, reverse-engineered byte-exact from
## MANAGER.EXE (docs/re/transfer_value_re.md sec.10). They are a LOOKUP TABLE, not a
## curve: FUN_00576cd0 indexes 2x702 uint16 tables by
##   idx = stature*54 + abilityTier(AV)*6 + ageTier(age),   AV = (VE+RE+AG+CA)>>2
## fee = feeTable[idx]*5000, wage(yearly) = wageTable[idx]*5000. Each club's stature
## (band 0-12) is derived from its division + squad-strength thresholds (FUN_0057a180 +
## FUN_0057a340 + the per-division vtable+0x78), reproduced in stature_of(). Validated
## 13/13 witnesses byte-exact (tools/re/validate_value_model.py). Only the accept
## thresholds / key-player premium / AI-movement that LAYER on top stay ours (PM98's
## negotiation + AI-transfer logic is un-RE'd).

# Squad bounds (gameplay, ours). The only literal squad cap in the binary is the
# non-EU "maximum allowed" rule; total-squad limits live in the database, so these
# are sensible play limits that keep wages and selection coherent.
const SQUAD_MAX := 30          # can't sign beyond this
const SQUAD_MIN := 16          # can't sell below this (must field XI + cover)
const MIN_KEEPERS := 2         # never sell down to a single goalkeeper

# PM98 value table (RE'd FUN_00576cd0): fee = feeTable[idx]*MULT, wage = wageTable[idx]*MULT.
# MULT = 5000 (asm FILD word; FMUL 1e6 then display /200 = net x5000 = the £5,000 offer step).
const _VALUE_MULT := 5000
const _VALUE_TABLES_PATH := "res://data/value_tables.json"
static var _fee_table: PackedInt32Array = PackedInt32Array()
static var _wage_table: PackedInt32Array = PackedInt32Array()

const KEY_PREMIUM := 1.6       # a first-XI man isn't sold at book value...
const STAR_FORCE := 2.2        # ...but this multiple of value always prises him loose
const _MIN_FEE := 5000         # the table floor (£5k) is PM98's smallest fee/wage step

# New signings / renewals get a fresh multi-year deal.
const NEW_CONTRACT_YEARS := 3


# ---- valuation (RE'd PM98 lookup table, docs/re/transfer_value_re.md sec.10) ---------

static func _load_tables() -> void:
	if not _fee_table.is_empty():
		return
	var f := FileAccess.open(_VALUE_TABLES_PATH, FileAccess.READ)
	if f == null:
		push_error("TransferMarket: %s missing" % _VALUE_TABLES_PATH)
		return
	var j: Variant = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		for v in (j as Dictionary).get("fee_table", []):
			_fee_table.append(int(v))
		for v in (j as Dictionary).get("wage_table", []):
			_wage_table.append(int(v))


## A player's attribute row, or {} when undecoded (some fringe players store null).
static func _attrs(player: Dictionary) -> Dictionary:
	var a: Variant = player.get("attrs", {})
	return a if a is Dictionary else {}


## On-screen ability AV = (VE + RE + AG + CA) >> 2 (FUN_0057a5a0). Falls back to CA
## alone when the other three are undecoded, so fringe rows still value.
static func av_of(attrs: Dictionary) -> int:
	if attrs.has("VE") and attrs.has("RE") and attrs.has("AG") and attrs.has("CA"):
		return (int(attrs["VE"]) + int(attrs["RE"]) + int(attrs["AG"]) + int(attrs["CA"])) >> 2
	return int(attrs.get("CA", 45))


## FUN_00576cd0 ability tier from AV: AV>=95->0 ... >=60->7 else 8.
static func _ability_tier(av: int) -> int:
	if av >= 95: return 0
	if av >= 90: return 1
	if av >= 85: return 2
	if av >= 80: return 3
	if av >= 75: return 4
	if av >= 70: return 5
	if av >= 65: return 6
	if av >= 60: return 7
	return 8


## FUN_00576cd0 age tier: <20->0 (special: AV>=95 & band0 -> 1) <23->1 <26->2 <30->3 <33->4 else 5.
static func _age_tier(age: int, av: int, band: int) -> int:
	if age < 20:
		return 1 if (av >= 95 and band == 0) else 0
	if age < 23: return 1
	if age < 26: return 2
	if age < 30: return 3
	if age < 33: return 4
	return 5


## The word index into the fee/wage tables (FUN_00576cd0): stature*54 + abil*6 + age.
static func _table_index(band: int, av: int, age: int) -> int:
	return band * 54 + _ability_tier(av) * 6 + _age_tier(age, av, band)


## FUN_0057a340: a club's average AV = floor(Σ(VE+RE+AG+CA over squad) / (nPlayers*4)),
## integer division; rows with undecoded attrs are skipped. The squad-strength input to
## every league's stature threshold.
static func _squad_avg_av(players: Array) -> int:
	var total := 0
	var n := 0
	for p in players:
		var a := _attrs(p)
		if a.has("VE") and a.has("RE") and a.has("AG") and a.has("CA"):
			total += int(a["VE"]) + int(a["RE"]) + int(a["AG"]) + int(a["CA"])
			n += 1
	return (total / (n * 4)) if n > 0 else 0     # FUN_0057a340 integer division


## FUN_004457a0: the stature threshold EVERY non-English (foreign) league shares — maps a
## club's average AV to a band 0-9 (the English divisions use their own fns via stature_of).
## Reversed byte-exact from MANAGER.EXE (docs/re/transfer_value_re.md §13): all six foreign
## league vtables (DAT_0066b1ac..b1c0, the FUN_0057a180 second scan group) resolve their
## +0x78 slot to this one function; the English four resolve to distinct per-division fns.
static func _foreign_band(avg: int) -> int:
	if avg >= 80: return 0
	if avg >= 76: return 1
	if avg >= 72: return 2
	if avg >= 68: return 3
	if avg >= 64: return 4
	if avg >= 60: return 5
	if avg >= 56: return 6
	if avg >= 54: return 7
	if avg >= 52: return 8
	return 9


## The club's ENGLISH division tier (1-4) for stature dispatch, or 0 when the club is
## foreign / not in an English league. Only the four English leagues carry a tier in
## game_db; a leagueless/foreign club (leagueId null, or an id absent from `leagues`)
## returns 0, so stature_of routes it through the shared foreign threshold. Kept DISTINCT
## from FinanceModel.tier_of (which defaults foreign clubs to mid tier 2 for the FINANCE
## model) — the stature model must NOT treat a foreign club as English Division One.
static func english_tier_of(club: Dictionary, leagues: Array) -> int:
	var lid: Variant = club.get("leagueId")
	if lid == null:
		return 0
	for lg in leagues:
		if lg.get("id") == lid:
			return int(lg.get("tier", 0))
	return 0


## A club's STATURE band 0-12 (FUN_0057a180 + FUN_0057a340 + per-league vtable+0x78).
## Band = the club's league mapped through a squad-strength threshold on its average AV.
## `tier` is the club's OWN English division 1-4 (see english_tier_of); any other value
## (0/foreign) uses the shared foreign threshold FUN_004457a0:
##   Prem(1):  avgAV>=80->0  76-79->1  72-75->2  <=71->3
##   Div1(2):  avgAV>=64->4  60-63->5  <=59->6
##   Div2(3):  avgAV>=54->7  52-53->8  <=51->9
##   Div3(4):  avgAV>=50->10 48-49->11 <=47->12
##   foreign:  avgAV>=80->0 76-79->1 72-75->2 68-71->3 64-67->4 60-63->5 56-59->6
##             54-55->7 52-53->8 <=51->9   (FUN_004457a0)
## Lower band = more prestigious club = far higher fees/wages at equal ability. This is
## the ONE per-club input the runtime reproduces; the tables + tiers + x5000 are fixed.
static func stature_of(players: Array, tier: int) -> int:
	var avg := _squad_avg_av(players)
	match tier:
		1:
			return 0 if avg >= 80 else 1 if avg >= 76 else 2 if avg >= 72 else 3
		2:
			return 4 if avg >= 64 else 5 if avg >= 60 else 6
		3:
			return 7 if avg >= 54 else 8 if avg >= 52 else 9
		4:
			return 10 if avg >= 50 else 11 if avg >= 48 else 12
		_:
			return _foreign_band(avg)


## Transfer value (CLUB FEE, £) for a player, given his SELLING CLUB's stature band 0-12.
## Byte-exact PM98 lookup: feeTable[stature*54 + abilTier(AV)*6 + ageTier(age)] * 5000.
static func value_of(player: Dictionary, band: int) -> int:
	_load_tables()
	if _fee_table.is_empty():
		return _MIN_FEE
	var idx := _table_index(band, av_of(_attrs(player)), int(player.get("age", 26)))
	return _fee_table[clampi(idx, 0, _fee_table.size() - 1)] * _VALUE_MULT


## Yearly wage (YEARLY WAGE, £) for a player at his club's stature band. Byte-exact PM98
## lookup: wageTable[idx] * 5000.
static func yearly_wage(player: Dictionary, band: int) -> int:
	_load_tables()
	if _wage_table.is_empty():
		return _MIN_FEE
	var idx := _table_index(band, av_of(_attrs(player)), int(player.get("age", 26)))
	return _wage_table[clampi(idx, 0, _wage_table.size() - 1)] * _VALUE_MULT


## Weekly wage (£/wk) for the finance ledger = yearly table wage / 52, rounded.
static func weekly_wage(player: Dictionary, band: int) -> int:
	return int(round(yearly_wage(player, band) / float(FinanceModel.SEASON_WEEKS)))


## Round a BID/offer amount to the £5,000 step, floored at the table minimum.
static func _round_fee(v: float) -> int:
	return maxi(_MIN_FEE, int(round(v / 5000.0)) * 5000)


# ---- squad helpers -------------------------------------------------------

## The ids of a club's auto-best XI (first-team); used to tag "key" players who
## are dearer to buy and aren't the ones AI clubs let go.
static func best_xi_ids(club_view: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pid in Tactics.auto_pick(club_view).xi:
		out[int(pid)] = true
	return out


static func is_key_player(club_view: Dictionary, pid: int) -> bool:
	return best_xi_ids(club_view).has(int(pid))


static func _find(players: Array, pid: int) -> Dictionary:
	for p in players:
		if int(p.get("id", -1)) == pid:
			return p
	return {}


static func _count_keepers(players: Array) -> int:
	var n := 0
	for p in players:
		if p.get("isGK"):
			n += 1
	return n


# ---- the market ----------------------------------------------------------

## Every buyable player across the OTHER clubs in the division, dearest first.
## Each row: {pid, name, isGK, ca, age, club_id, club_name, fee, wage, key}.
## `rosters` maps club_id -> Array[player]; `names` maps club_id -> String.
static func market(rosters: Dictionary, names: Dictionary, tier: int, exclude_club_id: int) -> Array:
	var out: Array = []
	for cid in rosters:
		if int(cid) == exclude_club_id:
			continue
		var players: Array = rosters[cid]
		var band := stature_of(players, tier)   # the selling club's PM98 stature
		var view := {"id": cid, "name": names.get(cid, "?"), "players": players}
		var key_ids := best_xi_ids(view)
		for p in players:
			var pid := int(p.get("id", -1))
			var attrs := _attrs(p)
			out.append({
				"pid": pid, "name": p.get("name", "?"), "isGK": bool(p.get("isGK", false)),
				"pos": str(p.get("pos", "")),
				"ca": int(attrs.get("CA", 0)), "mo": int(attrs.get("RM", 0)),
				"age": int(p.get("age", 0)),
				"club_id": int(cid), "club_name": names.get(cid, "?"),
				"fee": value_of(p, band), "wage": yearly_wage(p, band),
				"key": key_ids.has(pid),
			})
	out.sort_custom(func(a, b): return a["fee"] > b["fee"])
	return out


## Loanable players: each other club's non-first-XI surplus (you loan their fringe, not
## their stars), best CA first. Same row shape as market(). A club at the squad floor won't
## loan anyone out. `fee` here is purely informational (loans are free + wages).
static func loan_market(rosters: Dictionary, names: Dictionary, tier: int, exclude_club_id: int) -> Array:
	var out: Array = []
	for cid in rosters:
		if int(cid) == exclude_club_id:
			continue
		var players: Array = rosters[cid]
		if players.size() <= SQUAD_MIN:
			continue
		var band := stature_of(players, tier)
		var view := {"id": cid, "name": names.get(cid, "?"), "players": players}
		var key_ids := best_xi_ids(view)
		for p in players:
			var pid := int(p.get("id", -1))
			if key_ids.has(pid):
				continue   # never their first XI
			var attrs := _attrs(p)
			out.append({
				"pid": pid, "name": p.get("name", "?"), "isGK": bool(p.get("isGK", false)),
				"pos": str(p.get("pos", "")),
				"ca": int(attrs.get("CA", 0)), "mo": int(attrs.get("RM", 0)),
				"age": int(p.get("age", 0)),
				"club_id": int(cid), "club_name": names.get(cid, "?"),
				"fee": 0, "wage": yearly_wage(p, band), "key": false,
			})
	out.sort_custom(func(a, b): return a["ca"] > b["ca"])
	return out


## The asking price a club wants for a player: book value, with a premium for a
## first-XI man.
static func asking_price(player: Dictionary, is_key: bool, band: int) -> int:
	var value := value_of(player, band)
	return int(round(value * (KEY_PREMIUM if is_key else 1.0)))


## Decide whether the selling club accepts `offer` for `player`.
## Returns {accepted, asking, value}. Surplus players sell at/above book; a key
## player needs the premium and, even then, the board is reluctant until the offer
## approaches STAR_FORCE x value (where it always sells).
static func evaluate_offer(player: Dictionary, offer: int, is_key: bool, band: int, rng: RandomNumberGenerator) -> Dictionary:
	var value := value_of(player, band)
	var asking := asking_price(player, is_key, band)
	var res := {"accepted": false, "asking": asking, "value": value}
	if offer >= int(round(value * STAR_FORCE)):
		res["accepted"] = true
		return res
	if offer < asking:
		return res
	if not is_key:
		res["accepted"] = true
		return res
	# Key player at/above premium but below the forced price: reluctant board.
	var t := inverse_lerp(float(asking), value * STAR_FORCE, float(offer))
	var p_accept: float = lerpf(0.4, 1.0, clampf(t, 0.0, 1.0))
	res["accepted"] = rng.randf() < p_accept
	return res


## The best offer an AI club will table for a transfer-listed player of the
## manager's. Returns {buyer_id, buyer_name, offer, value} or {} if no club has
## room/interest. Buyers prefer players who'd improve or stock their squad.
static func solicit_offer(player: Dictionary, rosters: Dictionary, names: Dictionary, tier: int, seller_id: int, rng: RandomNumberGenerator) -> Dictionary:
	var seller_band := stature_of(rosters.get(seller_id, []), tier)
	var value := value_of(player, seller_band)
	var best := {}
	var best_score := -1.0
	for cid in rosters:
		if int(cid) == seller_id:
			continue
		var players: Array = rosters[cid]
		if players.size() >= SQUAD_MAX:
			continue
		# Smaller squads are keener; richer (higher-rated) clubs bid more.
		var keenness := 1.0 + (SQUAD_MAX - players.size()) / float(SQUAD_MAX)
		var score := keenness * (0.5 + rng.randf())
		if score > best_score:
			best_score = score
			var bid := int(round(value * lerpf(0.8, 1.15, rng.randf())))
			best = {
				"buyer_id": int(cid), "buyer_name": names.get(cid, "?"),
				"offer": _round_fee(float(bid)), "value": value,
			}
	return best


# ---- AI-to-AI movement ---------------------------------------------------

# "one season" / "N seasons" — the witnessed spelled-out singular vs numeral plural
# ("Wilson signs for Barnsley for one season." / "... for 5 seasons ...").
static func seasons_phrase(n: int) -> String:
	return "one season" if n == 1 else "%d seasons" % n


# Thousands-grouped £ amount (e.g. 288000 -> "288,000"), GameDB/Career-free so
# TransferMarket stays a pure module.
static func money_str(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


## Run a round of background transfers among the AI clubs (not the manager's).
## Moves 0-2 surplus players between clubs and returns witnessed-format news lines
## ("<buyer> has signed <player> for <N> seasons for £<fee>." — live-witnessed
## 2026-07-19 NEWS EXTRA MARKET feed). Mutates `rosters` in place (removes from
## seller, appends to buyer with a fresh deal). The deal LENGTH varies 1-5 seasons
## (the original clearly varies it: "one season" / "5 seasons" both witnessed);
## the exact distribution is un-RE'd (flagged model detail).
static func ai_round(rng: RandomNumberGenerator, rosters: Dictionary, names: Dictionary, manager_id: int, tier: int) -> Array:
	var news: Array = []
	var ids: Array = []
	for cid in rosters:
		if int(cid) != manager_id:
			ids.append(int(cid))
	if ids.size() < 2:
		return news
	var moves := rng.randi_range(0, 2)
	for _i in moves:
		var seller_id := int(ids[rng.randi() % ids.size()])
		var seller: Array = rosters[seller_id]
		if seller.size() <= SQUAD_MIN:
			continue
		var buyer_id := int(ids[rng.randi() % ids.size()])
		var buyer: Array = rosters[buyer_id]
		if buyer_id == seller_id or buyer.size() >= SQUAD_MAX:
			continue
		# A surplus player: not in the seller's first XI.
		var key_ids := best_xi_ids({"id": seller_id, "name": names.get(seller_id, "?"), "players": seller})
		var surplus: Array = seller.filter(func(p): return not key_ids.has(int(p.get("id", -1))))
		if surplus.is_empty():
			continue
		var player: Dictionary = surplus[rng.randi() % surplus.size()]
		# A keeper move must leave the seller with cover.
		if player.get("isGK") and _count_keepers(seller) <= MIN_KEEPERS:
			continue
		seller.erase(player)
		player["clubId"] = buyer_id
		var deal := rng.randi_range(1, 5)   # 1-5 seasons (witnessed range; distribution un-RE'd)
		player["contract_years"] = deal
		player["contract_term"] = deal
		buyer.append(player)
		var fee := value_of(player, stature_of(buyer, tier))
		news.append("%s has signed %s for %s for £%s." % [
			names.get(buyer_id, "?"), player.get("name", "?"),
			seasons_phrase(deal), money_str(fee)])
	return news


# ---- free agents ---------------------------------------------------------

# A free agent is an out-of-contract journeyman: older than a youth intake, modest ability.
const FA_AGE_LO := 28
const FA_AGE_HI := 35
const FA_CA_LO := 42
const FA_CA_HI := 64
const FA_GK_CHANCE := 0.18

## Generate `count` free agents (released journeymen) with ids from `first_id`. Reuses the
## Youth name pools + attribute builder (GameDB-free) so a fresh pool reads like real players.
## Returns player dicts shaped like a senior (id/name/age/isGK/attrs) + free_agent/contract_years.
static func generate_free_agents(rng: RandomNumberGenerator, count: int, first_id: int) -> Array:
	var out: Array = []
	for i in maxi(0, count):
		var is_gk := rng.randf() < FA_GK_CHANCE
		var ca := rng.randi_range(FA_CA_LO, FA_CA_HI)
		out.append({
			"id": first_id + i,
			"name": Youth._gen_name(rng),
			"age": rng.randi_range(FA_AGE_LO, FA_AGE_HI),
			"isGK": is_gk,
			"pos": Youth.random_pos(rng, is_gk),
			"attrs": Youth._make_attrs(rng, ca, is_gk),
			"contract_years": 0,
			"free_agent": true,
		})
	return out
