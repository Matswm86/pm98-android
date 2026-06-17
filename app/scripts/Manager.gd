class_name Manager
extends RefCounted
## The manager's standing across clubs (#14): reputation, the board's keep/sack verdict at
## a season's end, and the quality of the job offers that follow. Pure decision math --
## GameDB-free and side-effect-free, so it stays headless-testable. Career holds the state
## (reputation, manager_history, pending_offers, sacked); Main resolves the abstract offer
## band into real clubs from GameDB.
##
## PM98 modelled the board sacking you for missing its objective and, once you were out of a
## job (or had earned a bigger one), other clubs coming in for you -- a manager career that
## spans several clubs. This reproduces that core: a sack/keep verdict, reputation that
## tracks how you did, and a reputation-scaled pool of clubs that will offer you their job.

# Reputation runs 0..100. A new career starts mid-table (50). It climbs by beating the
# board's objective and lifting trophies, and falls by missing it / being sacked.
const REP_START := 50.0
const REP_MIN := 0.0
const REP_MAX := 100.0

# Season reputation deltas.
const REP_PER_PLACE := 1.4     # per league place finished above (+) / below (-) the objective
const REP_TITLE := 12.0        # winning the league
const REP_CUP := 6.0           # winning a domestic cup
const REP_RELEGATED := -10.0   # the drop on top of the place gap when you go down
const REP_SACK := -8.0         # an extra dent for being sacked

# Sacking: the board's patience. You are sacked when you finish well below the objective,
# or are relegated when survival was not the brief. A first season at a club is judged more
# leniently (a new manager is given time).
const SACK_GAP := 6            # finishing this many places below the objective -> sacked
const SACK_GAP_YEAR1 := 9      # ... more slack in your first season at the club

# Headhunting: overachieve while safe and a stronger club may come calling.
const HEADHUNT_GAP := 4        # finishing this many places ABOVE objective can attract suitors
const HEADHUNT_REP := 55.0     # ... but only once your reputation is high enough to interest one


## Reputation earned by a finished season. `titles` = {league:bool, cup:bool}. Finishing
## above the objective is positive, below is negative; trophies and relegation adjust.
static func reputation_delta(finished_pos: int, objective_pos: int, total: int,
		releg_count: int, titles: Dictionary = {}) -> float:
	var d := float(objective_pos - finished_pos) * REP_PER_PLACE
	if bool(titles.get("league", false)):
		d += REP_TITLE
	if bool(titles.get("cup", false)):
		d += REP_CUP
	if finished_pos > total - releg_count:
		d += REP_RELEGATED
	return d


static func apply_delta(reputation: float, delta: float) -> float:
	return clampf(reputation + delta, REP_MIN, REP_MAX)


## The board's end-of-season verdict. Sacked when finishing far below the objective, or
## relegated when the brief was not survival. `seasons_at_club` = seasons you have had at
## this club (1 = your first). {sacked: bool, reason: String}.
static func sack_decision(finished_pos: int, objective_pos: int, total: int,
		releg_count: int, objective_is_survival: bool, seasons_at_club: int) -> Dictionary:
	if finished_pos > total - releg_count and not objective_is_survival:
		return {"sacked": true, "reason": "relegated"}
	var gap := finished_pos - objective_pos
	var bar := SACK_GAP_YEAR1 if seasons_at_club <= 1 else SACK_GAP
	if gap >= bar:
		return {"sacked": true, "reason": "missed"}
	return {"sacked": false, "reason": ""}


## Does a stronger club come headhunting after a strong, safe season? Only when you beat the
## objective comfortably and your reputation is high enough to interest a bigger club. The
## better the overachievement + reputation, the likelier the approach.
static func headhunted(finished_pos: int, objective_pos: int, reputation: float,
		rng: RandomNumberGenerator) -> bool:
	if reputation < HEADHUNT_REP:
		return false
	if objective_pos - finished_pos < HEADHUNT_GAP:
		return false
	var p := clampf(0.25 + (reputation - HEADHUNT_REP) / 100.0
		+ float(objective_pos - finished_pos) * 0.04, 0.0, 0.85)
	return rng.randf() < p


## How many job offers, and from what STRENGTH percentile band of clubs, your reputation
## commands. Percentiles run over every club ranked weakest(0.0)..strongest(1.0); Main maps
## the band to real clubs. A sacking dents what clubs will offer you. {count, lo, hi}.
static func offer_band(reputation: float, sacked: bool) -> Dictionary:
	var r := reputation
	if sacked:
		r = maxf(REP_MIN, r - 15.0)
	var centre := clampf(r / REP_MAX, 0.0, 1.0)
	return {
		"count": 3 if r >= 35.0 else 2,
		"lo": clampf(centre - 0.22, 0.0, 0.95),
		"hi": clampf(centre + 0.12, 0.05, 1.0),
	}


## A word for a reputation value, shown on the career screen.
static func reputation_label(reputation: float) -> String:
	if reputation >= 85.0:
		return "World class"
	if reputation >= 70.0:
		return "Highly rated"
	if reputation >= 50.0:
		return "Respected"
	if reputation >= 30.0:
		return "Unproven"
	return "Under pressure"
