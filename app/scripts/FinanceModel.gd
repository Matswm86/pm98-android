class_name FinanceModel
extends RefCounted
## Club finance projection for PM98, structured on the real PCF5 finance ledger.
##
## The LEDGER STRUCTURE is lifted from MANAGER.EXE (docs/re/finance_constants.md):
## a per-club weekly record (0x20c bytes) accumulated over a 52-week season, with
## these exact income/expense line items, and the TICKET PRICE / PRICE OF BOARD /
## win+scoring bonus control screens. PM98 accumulates the real figures as the
## season is played; this app has no save-game yet, so the AMOUNTS here are a
## projection from each club's known data (division, stadium capacity, squad) —
## ours and calibrated to plausible 1997-98 English football figures, NOT ported
## (the original per-club balances live in the save/EQUIPOS data, not in code).

# Defaults by division tier (1=Premier ... 4=Division Three).
const _CAP := {1: 35000, 2: 20000, 3: 10000, 4: 5000}     # fallback stadium size
const _FILL := {1: 0.85, 2: 0.65, 3: 0.55, 4: 0.45}        # attendance fraction
const _TICKET := {1: 15, 2: 12, 3: 10, 4: 8}               # £ default ticket price
const _BOARD := {1: 1200, 2: 600, 3: 300, 4: 150}          # £ per advertising board
const _BOARDS := {1: 60, 2: 48, 3: 36, 4: 24}              # boards sold
const _TV := {1: 8_000_000, 2: 1_200_000, 3: 450_000, 4: 220_000}  # season TV money
const _SPONSOR := {1: 5_000_000, 2: 900_000, 3: 300_000, 4: 120_000}  # shirt/main sponsor
const _HOME_GAMES := {1: 19, 2: 23, 3: 23, 4: 23}          # league home games
const _WAGE_BASE := {1: 4000, 2: 1500, 3: 700, 4: 400}     # £/wk for a CA-55 player

const SEASON_WEEKS := 52   # PM98 finance loops 0x34 = 52 weeks


## Tier (1-4) for a club, resolved against a leagues array (e.g. GameDB.leagues).
## Leagueless / international clubs default to mid (tier 2). Kept free of the
## GameDB autoload so it stays unit-testable headless.
static func tier_of(club: Dictionary, leagues: Array) -> int:
	var lid: Variant = club.get("leagueId")
	if lid != null:
		for lg in leagues:
			if lg.get("id") == lid:
				return int(lg.get("tier", 2))
	return 2


static func _player_wage(attrs: Dictionary, base: int) -> int:
	# Weekly wage scales with Ability (CA); stars earn disproportionately more.
	var ca := float(attrs.get("CA", 45))
	var mult: float = pow(maxf(0.4, ca / 55.0), 1.6)
	return int(round(base * mult / 100.0)) * 100


## Full finance summary for one club at a given division tier (1-4). Returns a dict
## of season + weekly figures and the line-item breakdown, keyed by the authentic
## PM98 ledger labels. Use tier_of(club, leagues) to resolve the tier.
static func summary(club: Dictionary, tier: int) -> Dictionary:
	var cap_raw: Variant = club.get("capacity")
	var cap: int = int(cap_raw) if (cap_raw != null and int(cap_raw) > 0) else int(_CAP[tier])
	var attendance := int(round(cap * float(_FILL[tier])))
	var ticket: int = int(_TICKET[tier])
	var board_price: int = int(_BOARD[tier])
	var home_games: int = int(_HOME_GAMES[tier])

	# Income
	var gate := attendance * ticket * home_games          # TICKETS
	var boards := board_price * int(_BOARDS[tier])         # SPONSOR BOARDS SOLD
	var sponsor: int = int(_SPONSOR[tier])                 # SPONSORSHIP MONEY
	var tv: int = int(_TV[tier])                           # TELEVISION
	var income := gate + boards + sponsor + tv

	# Expenses
	var wbase: int = int(_WAGE_BASE[tier])
	var weekly_wages := 0
	for p in club.get("players", []):
		weekly_wages += _player_wage(p.get("attrs", {}), wbase)
	var wages := weekly_wages * SEASON_WEEKS               # STAFF WAGES
	var bonus := int(round(gate * 0.02))                   # BONUS (win/appearance pool)
	var expense := wages + bonus

	var balance := income - expense
	return {
		"tier": tier,
		"capacity": cap,
		"capacity_known": cap_raw != null and int(cap_raw) > 0,
		"attendance": attendance,
		"ticket_price": ticket,
		"board_price": board_price,
		"income_lines": [
			["TICKETS", gate],
			["SPONSOR BOARDS SOLD", boards],
			["SPONSORSHIP MONEY", sponsor],
			["TELEVISION", tv],
		],
		"expense_lines": [
			["STAFF WAGES", wages],
			["BONUS", bonus],
		],
		"total_income": income,
		"total_expense": expense,
		"season_balance": balance,
		"weekly_balance": int(round(balance / float(SEASON_WEEKS))),
		"weekly_wages": weekly_wages,
	}
