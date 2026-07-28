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

## TICKET PRICE -- WITNESSED, not ours. The original's FULL TIME stadium panel prints
## CAPACITY / ATTENDANCE / ATTENDANCE MONEY together, so the price falls straight out of
## the division:
##   Old Trafford 55,300 cap, 21,014 in (38%) -> ATTENDANCE MONEY £157,605 = 21,014 x 7.50
##   Anfield      41,000 cap, 41,000 in (100%) -> ATTENDANCE MONEY £307,500 = 41,000 x 7.50
## (screenshots/refrun-manutd-1997-98/named/p0031_full_time.png and p0342_full_time.png,
## 1997-98 reference run). Two different clubs, both exactly £7.50 a head, so the opening
## TICKET PRICE is a game default rather than a per-club figure -- and the app's old
## £15/12/10/8 tier ladder was ours and roughly double it.
## Only the PREMIER is witnessed; the same default is carried down the pyramid because
## nothing witnessed says it changes, and inventing a lower-division ladder would be a
## guess. Revisit the moment a Division One+ FULL TIME panel is captured.
const TICKET_DEFAULT := 7.5
const _TICKET := {1: TICKET_DEFAULT, 2: TICKET_DEFAULT, 3: TICKET_DEFAULT, 4: TICKET_DEFAULT}
const _BOARD := {1: 1200, 2: 600, 3: 300, 4: 150}          # £ per advertising board
const _BOARDS := {1: 60, 2: 48, 3: 36, 4: 24}              # boards sold
const _TV := {1: 8_000_000, 2: 1_200_000, 3: 450_000, 4: 220_000}  # season TV money
const _SPONSOR := {1: 5_000_000, 2: 900_000, 3: 300_000, 4: 120_000}  # shirt/main sponsor
const _HOME_GAMES := {1: 19, 2: 23, 3: 23, 4: 23}          # league home games

const SEASON_WEEKS := 52   # PM98 finance loops 0x34 = 52 weeks

# Demand response to the board-set prices (T2 #6). LINEAR in the price-vs-default ratio so
# revenue (price x quantity) is a downward parabola with an interior maximum -- there's a
# revenue-maximising price to find, not "always charge the max". At the default price the
# multiplier is 1.0 (so the figures are unchanged for every club that never sets a price).
#   attendance_mult = 1.6 - 0.6 * (ticket/default)   -> gate peaks at ~1.33x the default
#   boards_mult     = 1.5 - 0.5 * (board/default)    -> board income peaks at ~1.5x the default
const _TICKET_SLOPE := 0.6
const _BOARD_SLOPE := 0.5


# ---- the per-week ledger (FINANCE -> INC. + EXP. -> PER WEEK) -------------
#
# WITNESSED end to end in the 1997-98 reference run (docs/re/REFRUN_manutd_1997-98.md
# R5/R6/R9), two frames of the very screen:
#   out/refrun-manutd-9798/play/p0045_UNKNOWN.png  week "CURRENT 4", 10-8-1997..16-8-1997
#   out/refrun-manutd-9798/play/p0509_UNKNOWN.png  week 29, 1-2-1998..7-2-1998, a HOME week
# Week 29 reads, exactly:
#   INCOME    TICKETS £364,980 · TELEVISION £90,000 · everything else £0  -> £454,980
#   EXPENSES  PLAYERS' WAGE £226,923 · PLAYERS' BONUS £5,000 ·
#             STAFF WAGES £7,019 · everything else £0                     -> £238,942
# and the following AWAY week (p0495's LAST WEEK tiles) reads income £0, expenses
# £233,942 = 226,923 + 7,019. So the original's week splits cleanly into
#   * a FLAT cost charged every week: PLAYERS' WAGE + STAFF WAGES
#   * income and bonus that exist ONLY on a HOME matchday
# and an away week is a pure loss. That is the structure this app now runs; the old
# model spread one whole-season balance flat across 52 weeks, which produced a
# constant POSITIVE weekly delta and made the original's running-at-a-loss failure
# mode unreachable.
#
# The LINE LABELS are the screen's own, in the screen's own top-to-bottom order.

const INCOME_LINES := ["TICKETS", "PUBLICITY", "TELEVISION", "EUROPEAN CUP INCOME",
	"SALE + LOAN PLAY.", "INSURANCE GROUP 3", "LOANS"]
const EXPENSE_LINES := ["SIGN PLAYER", "CANCELLATION", "PLAYERS' WAGE", "PLAYERS' BONUS",
	"PLAYERS' INCENTIVE", "PLAYERS' INSURANCE", "HOSPITALS", "STAFF WAGES",
	"REFORM GROUND", "FINES", "LOANS AND INTEREST"]

## The finance year runs SUNDAY..SATURDAY and week 1 opens 20 July 1997 -- derived, not
## guessed, from the two captured frames: week 4 is stamped "From 10-8-1997 to 16-8-1997"
## and week 29 "From 1-2-1998 to 7-2-1998", which are exactly 25 weeks apart. The league
## calendar's week 1 is Saturday 9 August 1997 (PMChrome.date_parts), the last day of
## finance week 3 -- so finance week = league week + LEAGUE_WEEK_OFFSET. Cross-checked on
## the channelTV card: hub "Week 27", Saturday 7 February 1998, ledger week 29.
## TELEVISION, per competition -- the channelTV card's fee IS that week's TELEVISION
## line (proved on week 29: the card says £90,000 on Sat 7 Feb 1998, the ledger's
## TELEVISION line for that week is £90,000). The original sells the rights to each
## HOME match, unprompted, on a per-competition constant. Three measured, all Man Utd
## home fixtures (REFRUN R6):
##   Charity Shield  Sun  3 Aug 1997  £187,500   p0032_channel_tv.png
##   European Cup    Wed  1 Oct 1997  £375,000   p0138_channel_tv.png
##   Premier League  Sat 25 Oct 1997  £90,000    p0210_channel_tv.png
##   Premier League  Sat  7 Feb 1998  £90,000    p0474_channel_tv.png  (confirms constant)
## NOT measured: the Coca-Cola Cup, the F.A. Cup, the U.E.F.A. Cup and the Cup Winners'
## Cup. Those pay 0 here rather than a guessed figure -- the gap is visible in the ledger
## and in docs/re/finance_screen_re.md, and closes the moment one is captured.
##
## 2026-07-28: the LEAGUE fee is NOT one constant -- it is PER DIVISION, and the port had
## been paying every club the Premier figure. Three careers were driven from the title
## screen to settle it, and ALL FOUR English divisions are now witnessed (see
## `LEAGUE_TV_FEE`). `TV_FEE["league"]` keeps the Premier value it was measured on;
## `league_tv_fee()` is the division-aware reader every caller uses.
const TV_FEE := {
	"league": 90_000,
	"charity_shield": 187_500,
	"european_cup": 375_000,
}

## The witnessed home-league channelTV fee per English division, keyed by the game_db
## `leagueId`. All four captured, none interpolated:
##   Premier   GBP 90,000  Man Utd      p0210_channel_tv.png / p0474_channel_tv.png (x2)
##   First     GBP 45,000  Birmingham C seven cards, weeks 9-24
##   Second    GBP 35,000  Blackpool    week 8
##   Third     GBP 35,000  Barnet       week 7
## Frames: `tools/re/refs/lowdiv-2026-07-28/`. Note the ladder is NOT a clean ratio, which
## is why each rung was captured: 90k -> 45k is a halving but 45k -> 35k is not, and
## **Second and Third pay the SAME fee** -- the same shared-arm shape the ground-grade
## preset selector has, where `FUN_0057d780`'s jump table sends competition indices 2 and 3
## to one arm (`docs/re/stadium_screen_re.md`). Foreign clubs are not modelled here.
const LEAGUE_TV_FEE := {
	"eng_prem": 90_000,
	"eng_div1": 45_000,
	"eng_div2": 35_000,
	"eng_div3": 35_000,
}


## The home-league TV fee for a club's division. A division outside the witnessed four
## returns 0, which raises NO channelTV card and books NO television line -- an honest gap
## in the ledger rather than a fabricated figure, exactly as the un-measured cups behave.
static func league_tv_fee(league_id: String) -> int:
	return int(LEAGUE_TV_FEE.get(league_id, 0))

## The channelTV card's own wording, verbatim off the frame (two lines, then the fee).
const CHANNEL_TV_TEXT := "A TV station has bought the rights\nto broadcast the current match."
const CHANNEL_TV_FEE_TEXT := "For £%s"

const LEAGUE_WEEK_OFFSET := 2
const FINANCE_WEEK1_YMD := [1997, 7, 20]

## The DETAIL sub-record behind the INCOME / EXPENSES detail views (walkthrough frames
## 006/008/011/012). It never feeds the totals — the canonical 18 lines above stay the
## single source of the sums — it only splits them the way the detail screens print them:
##   comp:   per-competition-section {TICKETS/SPONSORS/TELEVISION/POINTS} buckets
##           ("league" / "domestic" / "euro" / "charity" / "supercup" / "intercontinental")
##   sales:  [[player name, fee], ...] — the witnessed `SALE Jordi Cruyff  £9,120,000` row
##   wage_gross/wage_refund: the PLAYERS´ WAGE section's green + blue sub-rows
##           (canonical line = gross - refund = the section's TOTAL row)
##   hosp_gross/hosp_pay2/hosp_pay3: the HOSPITALS section's three sub-rows
##           (canonical line = gross - pay2 - pay3 = Hospital Total)
##   bonus_n: the `N bonuses` label count. NO mechanism sets it yet — the original's
##           per-player bonus model is not reversed (frame 012 says "50 bonuses" for
##           £5,000 by week 4; our flat £5,000/home-matchday cannot honestly count) —
##           so the label is drawn only when a count exists.
##   ground: per-category REFORM GROUND split, keyed by Career.begin_work's cat
##           ("seats"/"carpark"/"facility"/"service" -> SEATS/CAR PARK/FACILITIES/EXTRAS)
static func new_ledger_detail() -> Dictionary:
	return {"comp": {}, "sales": [], "wage_gross": 0, "wage_refund": 0,
		"hosp_gross": 0, "hosp_pay2": 0, "hosp_pay3": 0, "bonus_n": 0, "ground": {}}


## A record's detail sub-record, healed for a legacy save: absent -> synthesized from the
## canonical lines where the mapping is 1:1 (wage/hospital gross = the net line when no
## insurance movement is recorded; the per-competition split is unknowable and stays
## empty, reading £0 exactly as a fresh original save does).
static func ledger_detail(rec: Dictionary) -> Dictionary:
	if rec.has("detail"):
		return rec["detail"]
	var det := new_ledger_detail()
	var exp: Dictionary = rec.get("expense", {})
	det["wage_gross"] = maxi(0, int(exp.get("PLAYERS' WAGE", 0)))
	det["hosp_gross"] = maxi(0, int(exp.get("HOSPITALS", 0)))
	return det


## A zeroed week record: every line the screen prints, at £0. Income and expenses are
## kept apart because the screen does, and because the sign convention differs.
static func new_week_ledger(week: int = 0) -> Dictionary:
	var inc: Dictionary = {}
	for k in INCOME_LINES:
		inc[k] = 0
	var exp: Dictionary = {}
	for k in EXPENSE_LINES:
		exp[k] = 0
	return {"week": week, "income": inc, "expense": exp, "detail": new_ledger_detail()}


static func ledger_total(rec: Dictionary, side: String) -> int:
	var t := 0
	for k in (rec.get(side, {}) as Dictionary):
		t += int(rec[side][k])
	return t


## Income minus expenses for one week record (the BALANCE chart's bar).
static func ledger_balance(rec: Dictionary) -> int:
	return ledger_total(rec, "income") - ledger_total(rec, "expense")


## ATTENDANCE MONEY for one match: heads through the turnstile x TICKET PRICE, which is
## the original's exact rule (see TICKET_DEFAULT above). Rounded down, as a till is.
static func attendance_money(attendance: int, ticket: float) -> int:
	return int(floor(float(attendance) * ticket))


## The finance-year week number for a league week (1-based both sides).
static func finance_week(league_week: int) -> int:
	return maxi(1, league_week) + LEAGUE_WEEK_OFFSET


## "From D-M-YYYY to D-M-YYYY" for a finance week, the screen's own stamp format.
static func finance_week_span(fin_week: int, start_year: int = 1997) -> String:
	var y0: int = FINANCE_WEEK1_YMD[0]
	var t0 := Time.get_unix_time_from_datetime_dict({
		"year": start_year + (int(FINANCE_WEEK1_YMD[0]) - y0), "month": int(FINANCE_WEEK1_YMD[1]),
		"day": int(FINANCE_WEEK1_YMD[2]), "hour": 12, "minute": 0, "second": 0})
	var a := int(t0) + (maxi(fin_week, 1) - 1) * 7 * 86400
	var b := a + 6 * 86400
	return "From %s to %s" % [_ymd(a), _ymd(b)]


static func _ymd(t: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "%d-%d-%d" % [int(d["day"]), int(d["month"]), int(d["year"])]


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


## Public weekly wage (£/wk) for one player at his club's stature band (0-12). Single
## source of truth shared by the finance ledger (STAFF WAGES) and the transfer market:
## the RE'd PM98 wage table (TransferMarket.weekly_wage = yearly table wage / 52), so a
## signing's wage and the books agree. Band comes from TransferMarket.stature_of(squad, tier).
static func weekly_wage(player: Dictionary, band: int) -> int:
	return TransferMarket.weekly_wage(player, band)


## Full finance summary for one club at a given division tier (1-4). Returns a dict
## of season + weekly figures and the line-item breakdown, keyed by the authentic
## PM98 ledger labels. Use tier_of(club, leagues) to resolve the tier.
static func summary(club: Dictionary, tier: int) -> Dictionary:
	var cap_raw: Variant = club.get("capacity")
	var cap: int = int(cap_raw) if (cap_raw != null and int(cap_raw) > 0) else int(_CAP[tier])
	var home_games: int = int(_HOME_GAMES[tier])

	# Board-set prices (T2 #6): a manager-chosen ticket / advertising-board price overrides
	# the tier default, and demand responds. With no override (every non-managed club, and
	# legacy callers) the defaults reproduce the previous figures exactly.
	var def_ticket: float = float(_TICKET[tier])
	var def_board: int = int(_BOARD[tier])
	var ticket_raw: Variant = club.get("ticket_price")
	var ticket: float = float(ticket_raw) if (ticket_raw != null and float(ticket_raw) > 0.0) else def_ticket
	var board_raw: Variant = club.get("board_price")
	var board_price: int = int(board_raw) if (board_raw != null and int(board_raw) > 0) else def_board

	# Attendance thins as the ticket price rises above the default (and fills toward capacity
	# as it drops), bounded so it never exceeds the ground or collapses to nothing.
	var att_mult := clampf(1.6 - _TICKET_SLOPE * ticket / def_ticket, 0.25, 1.6)
	var attendance := mini(cap, int(round(cap * float(_FILL[tier]) * att_mult)))
	# Fewer boards sell as their price rises above the default.
	var boards_mult := clampf(1.5 - _BOARD_SLOPE * float(board_price) / float(def_board), 0.2, 1.5)
	var boards_sold := int(round(_BOARDS[tier] * boards_mult))

	# Income
	# ATTENDANCE MONEY, the original's own rule: attendance x TICKET PRICE, exact
	# (witnessed twice, above). The season line is that per-match figure x home games.
	var gate := attendance_money(attendance, ticket) * home_games   # TICKETS
	var boards := board_price * boards_sold                # SPONSOR BOARDS SOLD
	var sponsor: int = int(_SPONSOR[tier])                 # SPONSORSHIP MONEY
	var tv: int = int(_TV[tier])                           # TELEVISION
	var income := gate + boards + sponsor + tv

	# Expenses. STAFF WAGES = the squad's weekly wage bill. Each unstamped player's wage is
	# the RE'd PM98 table wage (weekly = yearly / 52) at THIS club's stature band, so the
	# books match the market card. Band = the club's own squad strength (TransferMarket).
	var band := TransferMarket.stature_of(club.get("players", []), tier)
	var weekly_wages := 0
	for p in club.get("players", []):
		# A player's actual contracted wage (set on signing / renewal) takes precedence
		# over the table estimate, so a renewal raise shows up in the books.
		var stored: Variant = p.get("wage")
		weekly_wages += int(stored) if stored != null else TransferMarket.weekly_wage(p, band)
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
		"match_gate": attendance_money(attendance, ticket),
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
		# per-match derivations the FULL TIME stadium panel needs
		"home_games": home_games,
		"boards_sold": boards_sold,
		"boards_pct": int(round(100.0 * boards_sold / float(_BOARDS[tier]))),
		"total_income": income,
		"total_expense": expense,
		"season_balance": balance,
		"weekly_balance": int(round(balance / float(SEASON_WEEKS))),
		"weekly_wages": weekly_wages,
	}
