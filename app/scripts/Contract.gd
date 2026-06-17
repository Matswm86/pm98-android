class_name Contract
extends RefCounted
## Player contracts & wages: the renewal negotiation, the wage demand a player makes
## when you offer him a new deal, and the live weekly wage bill that signings and
## raises move. This is the depth behind the squad's RENEW button -- a renewal is now a
## negotiation a player can REJECT, not a one-tap reset.
##
## Faithful surface (strings scanned from MANAGER.EXE): RENEW / YEARLY WAGE / MONTHLY
## WAGE / FREE TRANSFER / COMPENSATIONS OF CONTRACT, and the messages
##   "%s has renewed his contract.",
##   "%s has rejected your offer for renewal.",
##   "%s has left your club as his contract has not been renewed".
## PM98's per-player wages are data-driven (loaded from the EQUIPOS/save data, not code,
## docs/re/finance_constants.md), so the wage + demand MODEL here is OURS -- calibrated to
## FinanceModel.weekly_wage so a signing's wage and the club's books agree. Only the screen
## labels and the message templates are PM98's.
##
## GameDB-free, pure functions over plain player dicts -> headless-testable
## (tests/test_contract.gd). A player's actual wage is stored on his dict (`wage`, weekly
## £) once stamped, so a renewal raise persists in the save and the wage bill reflects the
## live squad. Players with no stored wage (pre-contracts saves, GameDB clubs) fall back to
## the market wage, which is deterministic, so legacy data behaves identically.

const NEW_TERM_YEARS := 3        # a renewed deal runs this long (matches TransferMarket)
const EXPIRING_YEARS := 1        # final year of contract -> renewable, else leaves on a free
const SEASON_WEEKS := 52         # wages are weekly; YEARLY WAGE = weekly x this (matches FinanceModel)

# A player never accepts a pay CUT to re-sign, so his demand is floored at his current wage;
# above that he asks for a raise scaled by ambition (younger + better = pushier). The accept
# test is hard at/above the demand, probabilistic in a narrow band below it, a flat refusal
# under that band -- so a lowball renewal earns the authentic "rejected your offer for renewal".
const SOFT_FLOOR := 0.90         # offers in [SOFT_FLOOR*demand, demand) may still be accepted
const IMPROVE_STEP := 1.10       # the "better his demand" button pays this multiple of demand


# ---- attribute helper ----------------------------------------------------

## A player's attribute row, or {} when undecoded (some fringe players store null).
static func _attrs(player: Dictionary) -> Dictionary:
	var a: Variant = player.get("attrs", {})
	return a if a is Dictionary else {}


static func _round100(v: float) -> int:
	return int(round(v / 100.0)) * 100


# ---- wages ---------------------------------------------------------------

## The market weekly wage for a player at a division tier (1-4): the shared FinanceModel
## curve, so a signing's wage matches the finance ledger's STAFF WAGES line.
static func market_weekly(player: Dictionary, tier: int) -> int:
	return FinanceModel.weekly_wage(_attrs(player), tier)


## A player's actual weekly wage: his stored `wage` (set when he joined or last renewed),
## or the market wage if none is stored (legacy saves / GameDB players).
static func current_weekly(player: Dictionary, tier: int) -> int:
	var w: Variant = player.get("wage")
	return int(w) if w != null else market_weekly(player, tier)


## Stamp a player's current wage onto his dict (his market wage at this tier). Called when a
## player joins the club (seed / signing / youth promotion) so his wage persists and the
## live wage bill counts him.
static func stamp_wage(player: Dictionary, tier: int) -> void:
	player["wage"] = market_weekly(player, tier)


## Total weekly wage bill for a squad (deducted from cash each week).
static func squad_weekly_bill(squad: Array, tier: int) -> int:
	var w := 0
	for p in squad:
		w += current_weekly(p, tier)
	return w


static func yearly(weekly: int) -> int:
	return weekly * SEASON_WEEKS

static func monthly(weekly: int) -> int:
	return int(round(weekly * SEASON_WEEKS / 12.0))


# ---- renewal negotiation -------------------------------------------------

## How hard a player pushes on a new deal: young, improving players want a clear raise; a
## settled prime player a modest one; an aging veteran is content to re-sign near his rate.
## A stronger player (higher CA) pushes a little harder on top.
static func _ambition(player: Dictionary) -> float:
	var age := int(player.get("age", 26))
	var amb: float
	if age <= 21:
		amb = 1.40
	elif age <= 24:
		amb = 1.28
	elif age <= 28:
		amb = 1.18
	elif age <= 31:
		amb = 1.08
	else:
		amb = 0.98   # past it; happy to re-sign near current terms
	var ca := float(_attrs(player).get("CA", 50))
	return amb + clampf((ca - 50.0) / 200.0, -0.05, 0.12)


## The weekly wage a player demands to renew. Floored at his current wage (he never re-signs
## for a cut), otherwise his market wage scaled by ambition. Rounded to £100.
static func demanded_weekly(player: Dictionary, tier: int) -> int:
	var cur := current_weekly(player, tier)
	var asked := _round100(float(market_weekly(player, tier)) * _ambition(player))
	return maxi(cur, asked)


## The renewal offers the manager can table for a player (the RENEW screen rows). Monotonic
## by wage: hold his current terms (a lowball for anyone wanting a raise), meet his demand,
## or better it to lock him in. Each = {key, label, weekly, years}.
static func renewal_options(player: Dictionary, tier: int) -> Array:
	var cur := current_weekly(player, tier)
	var dem := demanded_weekly(player, tier)
	return [
		{"key": "hold", "label": "Offer current terms", "weekly": cur, "years": NEW_TERM_YEARS},
		{"key": "meet", "label": "Meet his wage demand", "weekly": dem, "years": NEW_TERM_YEARS},
		{"key": "improve", "label": "Better his demand (secure him)",
			"weekly": _round100(float(dem) * IMPROVE_STEP), "years": NEW_TERM_YEARS},
	]


## Decide whether a player accepts a renewal at `offer_weekly`. Accept at/above his demand,
## a coin-weighted maybe just below it, a flat refusal under that. Returns {accepted, demanded}.
static func evaluate_renewal(player: Dictionary, offer_weekly: int, tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var dem := demanded_weekly(player, tier)
	var res := {"accepted": false, "demanded": dem}
	if offer_weekly >= dem:
		res["accepted"] = true
	elif offer_weekly >= int(round(float(dem) * SOFT_FLOOR)):
		var t := inverse_lerp(float(dem) * SOFT_FLOOR, float(dem), float(offer_weekly))
		res["accepted"] = rng.randf() < clampf(t, 0.0, 1.0)
	return res


## True while a player is in the final year of his deal -- renewable now, or he leaves on a
## free at the next rollover if you don't tie him down (the FREE TRANSFER departure).
static func is_expiring(player: Dictionary) -> bool:
	return int(player.get("contract_years", 1)) <= EXPIRING_YEARS
