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

# Sacking is NOT decided here. MANAGER.EXE has no end-of-season dismissal at all: every
# sack it raises comes out of the WEEKLY hub run `FUN_00545fd0` and ends the career on the
# spot, and the results arm behind it is the board's own week-10/14/18/22/26/30/34 review
# (`FUN_0057a980` @0x57ad6a). Both live in Career (`sack_message`, `_board_results_review`,
# docs/re/sack_path_re.md); the invented SACK_GAP verdict this file used to hold is gone.
# REP_SACK above still applies, because a sack is still a dent in the manager's standing.

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
