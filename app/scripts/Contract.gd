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

## The market weekly wage for a player at his club's stature BAND (0-12): the RE'd PM98
## wage table (weekly = yearly table wage / 52), so a signing's wage matches the finance
## ledger's STAFF WAGES line. Band comes from TransferMarket.stature_of(club squad, tier).
static func market_weekly(player: Dictionary, band: int) -> int:
	return FinanceModel.weekly_wage(player, band)


## A player's actual weekly wage: his stored `wage` (set when he joined or last renewed),
## or the market wage if none is stored (legacy saves / GameDB players).
static func current_weekly(player: Dictionary, band: int) -> int:
	var w: Variant = player.get("wage")
	return int(w) if w != null else market_weekly(player, band)


## Stamp a player's current wage onto his dict (his market wage at his club's band). Called
## when a player joins the club (seed / signing / youth promotion) so his wage persists and
## the live wage bill counts him.
static func stamp_wage(player: Dictionary, band: int) -> void:
	player["wage"] = market_weekly(player, band)


## Total weekly wage bill for a squad (deducted from cash each week).
static func squad_weekly_bill(squad: Array, band: int) -> int:
	var w := 0
	for p in squad:
		w += current_weekly(p, band)
	return w


static func yearly(weekly: int) -> int:
	return weekly * SEASON_WEEKS


## The player's EXACT yearly wage for display (FICHA YEARLY WAGE / SQUAD WAGE column /
## TEAM OFFER). PM98's native wage unit is the £5,000-step yearly table value; the app
## keeps an integer weekly figure for the finance ledger, but round(yearly/52)*52 corrupts
## the exact table value on screen (£1,000,000 -> £1,000,012, witnessed owner frame 15).
## So an un-renewed player (his stored weekly still equals the table's rounded weekly)
## shows the EXACT table yearly; once he has renegotiated his deal (stored weekly differs),
## his agreed weekly x52 is the truth. Legacy dicts with no stored wage use the table.
static func current_yearly(player: Dictionary, band: int) -> int:
	var w: Variant = player.get("wage")
	if w == null or int(w) == TransferMarket.weekly_wage(player, band):
		return TransferMarket.yearly_wage(player, band)
	return int(w) * SEASON_WEEKS

static func monthly(weekly: int) -> int:
	return int(round(weekly * SEASON_WEEKS / 12.0))


# ---- renewal negotiation -------------------------------------------------

## The weekly wage a player demands to renew: HIS CURRENT TERMS, floored at his market
## rate so a player on a below-table deal is not re-signed under it.
##
## CORRECTED 2026-08-01. This used to multiply his market wage by an invented "ambition"
## ladder — 1.40 at 21 and under, down to 0.98 past 31, plus a CA kicker — so almost
## every renewal opened with a demand 18-52% above what the man was already on, and the
## OFFER form (which opens at his CURRENT yearly wage, `PlayerInfoScreen.begin_renew`)
## was a rejection unless you stepped the wage up several times. Mats QA: "why is
## contract renewal so much harder? Players demand way too much."
##
## The ladder was never source-backed — this file's own header says the demand MODEL is
## ours — and the one witnessed renewal transaction contradicts it: at TOTAL level on the
## real game, "offering his exact current terms accepted silently"
## (`docs/re/renew_negotiation_re.md` §Mechanics witnessed, frame 28_offerresult). So the
## demand is his current terms. The soft-floor band below still lets a LOWBALL be
## refused, which is what the engine's own "%s has rejected your offer for renewal."
## string is for.
static func demanded_weekly(player: Dictionary, band: int) -> int:
	return maxi(current_weekly(player, band), market_weekly(player, band))


## The renewal offers the manager can table for a player (the RENEW screen rows). Monotonic
## by wage: hold his current terms (a lowball for anyone wanting a raise), meet his demand,
## or better it to lock him in. Each = {key, label, weekly, years}.
static func renewal_options(player: Dictionary, band: int) -> Array:
	var cur := current_weekly(player, band)
	var dem := demanded_weekly(player, band)
	return [
		{"key": "hold", "label": "Offer current terms", "weekly": cur, "years": NEW_TERM_YEARS},
		{"key": "meet", "label": "Meet his wage demand", "weekly": dem, "years": NEW_TERM_YEARS},
		{"key": "improve", "label": "Better his demand (secure him)",
			"weekly": _round100(float(dem) * IMPROVE_STEP), "years": NEW_TERM_YEARS},
	]


## Decide whether a player accepts a renewal at `offer_weekly`. Accept at/above his demand,
## a coin-weighted maybe just below it, a flat refusal under that. Returns {accepted, demanded}.
static func evaluate_renewal(player: Dictionary, offer_weekly: int, band: int, rng: RandomNumberGenerator) -> Dictionary:
	var dem := demanded_weekly(player, band)
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
