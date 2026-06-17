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
## The valuation MODEL itself (fee curve, age factor, accept thresholds, AI movement)
## is OURS, calibrated to plausible 1997-98 English fees. PM98's real per-player fees
## are NOT code constants -- finance is a data-driven per-club float ledger loaded from
## the club database at new-game (docs/re/finance_constants.md), so there is nothing to
## port here; only the screen labels and message text are PM98's.

# Squad bounds (gameplay, ours). The only literal squad cap in the binary is the
# non-EU "maximum allowed" rule; total-squad limits live in the database, so these
# are sensible play limits that keep wages and selection coherent.
const SQUAD_MAX := 30          # can't sign beyond this
const SQUAD_MIN := 16          # can't sell below this (must field XI + cover)
const MIN_KEEPERS := 2         # never sell down to a single goalkeeper

# Fee curve: convex in Ability (CA), shaped by age, scaled by division tier. The
# tier scale sets the fee of an average (CA 50) prime-age player in that division.
const _TIER_FEE := {1: 915000.0, 2: 320000.0, 3: 110000.0, 4: 45000.0}
const _CA_PIVOT := 50.0
const _CA_POW := 4.0
const KEY_PREMIUM := 1.6       # a first-XI man isn't sold at book value...
const STAR_FORCE := 2.2        # ...but this multiple of value always prises him loose
const _MIN_FEE := 25000        # nobody changes hands for less than this

# New signings / renewals get a fresh multi-year deal.
const NEW_CONTRACT_YEARS := 3


# ---- valuation -----------------------------------------------------------

## Age multiplier on fee: peak value at 24-28, a discount for the very young
## (no decoded potential attribute, so youth isn't a premium here) and a steep
## decline past 30.
static func _age_factor(age: int) -> float:
	if age <= 0:
		return 1.0
	if age <= 20:
		return 0.85
	if age <= 23:
		return 0.95
	if age <= 28:
		return 1.0
	if age <= 30:
		return 0.80
	if age <= 32:
		return 0.55
	return 0.35


static func _round_fee(v: float, tier: int) -> int:
	var step: int = 50000 if tier <= 2 else 5000
	var n := int(round(v / step)) * step
	return maxi(_MIN_FEE, n)


## A player's attribute row, or {} when undecoded (some fringe players store null).
static func _attrs(player: Dictionary) -> Dictionary:
	var a: Variant = player.get("attrs", {})
	return a if a is Dictionary else {}


## Transfer value (CLUB FEE, £) for a player at a division tier (1-4).
static func value_of(player: Dictionary, tier: int) -> int:
	var attrs := _attrs(player)
	var ca := float(attrs.get("CA", 45))
	var age := int(player.get("age", 26))
	var scale: float = float(_TIER_FEE.get(tier, _TIER_FEE[2]))
	var raw := scale * pow(ca / _CA_PIVOT, _CA_POW) * _age_factor(age)
	return _round_fee(raw, tier)


## Yearly wage (YEARLY WAGE, £) -- weekly wage from the shared FinanceModel curve x season.
static func wage_yearly(player: Dictionary, tier: int) -> int:
	return FinanceModel.weekly_wage(_attrs(player), tier) * FinanceModel.SEASON_WEEKS


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
		var view := {"id": cid, "name": names.get(cid, "?"), "players": players}
		var key_ids := best_xi_ids(view)
		for p in players:
			var pid := int(p.get("id", -1))
			var attrs := _attrs(p)
			out.append({
				"pid": pid, "name": p.get("name", "?"), "isGK": bool(p.get("isGK", false)),
				"ca": int(attrs.get("CA", 0)), "age": int(p.get("age", 0)),
				"club_id": int(cid), "club_name": names.get(cid, "?"),
				"fee": value_of(p, tier), "wage": wage_yearly(p, tier),
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
		var view := {"id": cid, "name": names.get(cid, "?"), "players": players}
		var key_ids := best_xi_ids(view)
		for p in players:
			var pid := int(p.get("id", -1))
			if key_ids.has(pid):
				continue   # never their first XI
			var attrs := _attrs(p)
			out.append({
				"pid": pid, "name": p.get("name", "?"), "isGK": bool(p.get("isGK", false)),
				"ca": int(attrs.get("CA", 0)), "age": int(p.get("age", 0)),
				"club_id": int(cid), "club_name": names.get(cid, "?"),
				"fee": 0, "wage": wage_yearly(p, tier), "key": false,
			})
	out.sort_custom(func(a, b): return a["ca"] > b["ca"])
	return out


## The asking price a club wants for a player: book value, with a premium for a
## first-XI man.
static func asking_price(player: Dictionary, is_key: bool, tier: int) -> int:
	var value := value_of(player, tier)
	return int(round(value * (KEY_PREMIUM if is_key else 1.0)))


## Decide whether the selling club accepts `offer` for `player`.
## Returns {accepted, asking, value}. Surplus players sell at/above book; a key
## player needs the premium and, even then, the board is reluctant until the offer
## approaches STAR_FORCE x value (where it always sells).
static func evaluate_offer(player: Dictionary, offer: int, is_key: bool, tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var value := value_of(player, tier)
	var asking := asking_price(player, is_key, tier)
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
	var value := value_of(player, tier)
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
				"offer": _round_fee(float(bid), tier), "value": value,
			}
	return best


# ---- AI-to-AI movement ---------------------------------------------------

## Run a round of background transfers among the AI clubs (not the manager's).
## Moves 0-2 surplus players between clubs and returns news lines. Mutates `rosters`
## in place (removes from seller, appends to buyer with refreshed contract).
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
		player["contract_years"] = NEW_CONTRACT_YEARS
		buyer.append(player)
		news.append("%s has been signed by %s." % [player.get("name", "?"), names.get(buyer_id, "?")])
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
			"name": "%s %s" % [Youth._FORENAMES[rng.randi() % Youth._FORENAMES.size()],
				Youth._SURNAMES[rng.randi() % Youth._SURNAMES.size()]],
			"age": rng.randi_range(FA_AGE_LO, FA_AGE_HI),
			"isGK": is_gk,
			"attrs": Youth._make_attrs(rng, ca, is_gk),
			"contract_years": 0,
			"free_agent": true,
		})
	return out
