class_name Career
extends RefCounted
## A persistent manager career: one club, played week-by-week through a league
## season, with an accumulating table, finances and a board objective. Saves to
## user://career.json. This is the spine the rest of the management layer hangs off.
##
## Kept free of the GameDB autoload (callers pass clubs/leagues in) so it stays
## unit-testable headless.

const SAVE_PATH := "user://career.json"

var club_id: int = -1
var club_name: String = ""
var league_id: String = ""
var league_name: String = ""
var season: String = "1997-98"
var year: int = 1                 # season number within this career
var week: int = 0                 # index of the NEXT round to play
var fixtures: Array = []          # Array[round]; round = Array[[home_id, away_id]]
var table: Dictionary = {}        # club_id:int -> stat row
var results: Array = []           # manager's played results [{week,opp_id,home,hg,ag}]
var cash: int = 0                 # running bank balance
var weekly_net: int = 0           # per-week finance delta (from FinanceModel)
var objective_pos: int = 17       # board wants: finish at least this high (1-based)
var objective_text: String = ""
var finished: bool = false        # season complete + objective resolved
var tactics: Dictionary = {}      # manager's Tactics.to_dict(): XI + shape + marking

# Live transfer state: the division's squads mutate as players move, and persist
# in the save -- the career, not GameDB, is the source of truth once you're managing.
var tier: int = 1                       # division tier (all clubs here share it)
var rosters: Dictionary = {}            # club_id:int -> Array[player dict] (live squads)
var club_names: Dictionary = {}         # club_id:int -> String
var transfer_listed: Dictionary = {}    # pid:int -> true (your players up for sale)
var shortlist: Array = []               # pid:int targets you're tracking
var transfer_log: Array = []            # newest-first transfer news lines
var offers_left: int = OFFERS_PER_WEEK  # signings the board still allows this week
var news_log: Array = []                # newest-first club news {week,kind,text}

# "The Directors will only let you make %u offer%s to sign a player per week."
const OFFERS_PER_WEEK := 3
# Transfer window shuts this many rounds before the season ends (deadline day).
const DEADLINE_TAIL := 6


# ---- construction --------------------------------------------------------

## Start a fresh career managing `club` in its division. `league` is the league
## dict, `league_clubs` the full club dicts in that division, `leagues` all leagues.
static func create(club: Dictionary, league: Dictionary, league_clubs: Array, leagues: Array) -> Career:
	var c := Career.new()
	c.club_id = int(club["id"])
	c.club_name = club.get("name", "?")
	c.league_id = str(league.get("id", ""))
	c.league_name = league.get("name", "League")
	c.tier = FinanceModel.tier_of(club, leagues)
	var ids: Array = []
	for lc in league_clubs:
		ids.append(int(lc["id"]))
		c.club_names[int(lc["id"])] = lc.get("name", "?")
		c.rosters[int(lc["id"])] = c._seed_squad(lc)
	c.fixtures = SeasonSim.fixtures(ids)
	c._init_table(league_clubs)
	c._set_objective(league, league_clubs, leagues)
	var fin := FinanceModel.summary(club, c.tier)
	c.weekly_net = int(fin["weekly_balance"])
	c.cash = int(fin.get("total_income", 0)) / 4   # opening balance ~ a quarter's income
	c.tactics = Tactics.auto_pick(club, Tactics.DEFAULT_FORMATION).to_dict()
	return c


## Deep-copy a club's squad into a live roster, stamping a contract length on each
## player (younger players are tied down longer). Never aliases GameDB's data.
func _seed_squad(club_dict: Dictionary) -> Array:
	var out: Array = []
	for p in club_dict.get("players", []):
		var dup: Dictionary = (p as Dictionary).duplicate(true)
		var age := int(dup.get("age", 26))
		dup["contract_years"] = 3 if age <= 29 else (2 if age <= 32 else 1)
		dup["injured_weeks"] = 0       # availability state (Availability.gd)
		dup["suspended_weeks"] = 0
		dup["yellows"] = 0
		out.append(dup)
	return out


func _init_table(league_clubs: Array) -> void:
	table.clear()
	for lc in league_clubs:
		var id := int(lc["id"])
		table[id] = {
			"id": id, "name": lc.get("name", "?"),
			"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "Pts": 0,
		}


## Objective = finish at least as high as squad strength suggests (with leniency),
## phrased by where that lands in the division.
func _set_objective(league: Dictionary, league_clubs: Array, leagues: Array) -> void:
	var ranked: Array = []
	for lc in league_clubs:
		var r := MatchEngine.team_ratings(lc)
		ranked.append({"id": int(lc["id"]), "ovr": r["att"] + r["def"] + r["gk"]})
	ranked.sort_custom(func(a, b): return a["ovr"] > b["ovr"])
	var strength_rank := league_clubs.size()
	for i in ranked.size():
		if ranked[i]["id"] == club_id:
			strength_rank = i + 1
			break
	var total := league_clubs.size()
	objective_pos = clampi(strength_rank + 2, 1, total)
	var tier := FinanceModel.tier_of({"leagueId": league_id}, leagues)
	var zone: Dictionary = SeasonSim.ZONES.get(tier, {"releg": 3})
	var relegation: int = int(zone.get("releg", 3))
	if objective_pos >= total - relegation:
		objective_text = "Avoid relegation"
		objective_pos = total - int(relegation) - 1
	elif objective_pos <= 1:
		objective_text = "Win the league"
	elif objective_pos <= maxi(2, total / 5):
		objective_text = "Finish in the top %d" % objective_pos
	else:
		objective_text = "Finish %d or higher" % objective_pos


# ---- season loop ---------------------------------------------------------

func total_weeks() -> int:
	return fixtures.size()

func season_over() -> bool:
	return week >= fixtures.size()

## [home_id, away_id] for the manager's match this week, or [] on a bye.
func manager_fixture() -> Array:
	if season_over():
		return []
	for m in fixtures[week]:
		if int(m[0]) == club_id or int(m[1]) == club_id:
			return [int(m[0]), int(m[1])]
	return []

## Play the current round: simulate every fixture, update the table, accrue cash.
## `clubs_by_id` maps id -> full club dict (for ratings). Returns the manager's
## result {home_id, away_id, hg, ag, manager_home} or {} on a bye / season end.
func advance_week(rng: RandomNumberGenerator, clubs_override: Dictionary = {}) -> Dictionary:
	if season_over():
		return {}
	# Rival clubs trade in the background while the window is open.
	if transfers_open() and not rosters.is_empty():
		for line in TransferMarket.ai_round(rng, rosters, club_names, club_id, tier):
			_log(line)
	# The fit XI that actually featured this week (captured before the match so its
	# injury/card rolls land on the players who played, not this week's recoveries).
	var featured := _mgr_featured_xi()
	var ratings: Dictionary = {}
	var manager_res: Dictionary = {}
	for m in fixtures[week]:
		var h := int(m[0])
		var a := int(m[1])
		if not ratings.has(h):
			ratings[h] = _ratings_for(h, clubs_override)
		if not ratings.has(a):
			ratings[a] = _ratings_for(a, clubs_override)
		var res := MatchEngine.simulate(rng, ratings[h], ratings[a])
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		_apply(table[h], hg, ag)
		_apply(table[a], ag, hg)
		if h == club_id or a == club_id:
			manager_res = {"home_id": h, "away_id": a, "hg": hg, "ag": ag, "manager_home": h == club_id}
	cash += weekly_net
	week += 1
	offers_left = OFFERS_PER_WEEK   # the board's weekly signing allowance resets
	if not manager_res.is_empty():
		results.append({
			"week": week, "opp_id": manager_res["away_id"] if manager_res["manager_home"] else manager_res["home_id"],
			"home": manager_res["manager_home"], "hg": manager_res["hg"], "ag": manager_res["ag"],
		})
		_log_result(manager_res)
	# Injuries & suspensions: a matchday elapsed (recoveries tick), then this match's
	# knocks and bookings are rolled on the side that featured. Manager's club only.
	for n in Availability.tick_week(my_squad()):
		_news(n["kind"], n["text"])
	if not manager_res.is_empty():
		for n in Availability.roll_match(rng, featured):
			_news(n["kind"], n["text"])
	if season_over():
		finished = true
	return manager_res


## Ratings for a club: the manager's own club uses the chosen XI + shape; every
## other (AI) club uses the auto-best-XI. Reads the live roster (so signings move
## results); `clubs_override` is a fallback for clubs not in the roster (e.g. an
## old save built before rosters existed).
func _ratings_for(id: int, clubs_override: Dictionary = {}) -> Dictionary:
	if id == club_id and not tactics.is_empty():
		# Field only the available players: the chosen XI is repaired around any
		# injured/suspended player, so absences actually weaken the side.
		var fit := _fit_view(id)
		return Tactics.from_dict(tactics).repaired(fit).ratings(fit)
	var club: Dictionary = club_view(id) if rosters.has(id) else clubs_override.get(id, {})
	return MatchEngine.team_ratings(club)


# ---- availability --------------------------------------------------------

## Players in `id`'s squad who can be selected this week (injury/ban aside).
func available_squad(id: int = club_id) -> Array:
	return Availability.available_players(squad_of(id))

## A club view backed by only the fit players (what selection/ratings field).
func _fit_view(id: int) -> Dictionary:
	return {"id": id, "name": club_names.get(id, "?"), "players": available_squad(id)}

## The manager's fit XI for this week: the saved tactics repaired around absences,
## resolved back to the live roster player dicts (so injury/card rolls write through).
func _mgr_featured_xi() -> Array:
	var fit := _fit_view(club_id)
	var t: Tactics = Tactics.from_dict(tactics).repaired(fit) if not tactics.is_empty() \
		else Tactics.auto_pick(fit)
	var by_id: Dictionary = {}
	for p in fit["players"]:
		by_id[int(p.get("id", -1))] = p
	var out: Array = []
	for pid in t.xi:
		if by_id.has(int(pid)):
			out.append(by_id[int(pid)])
	return out


# ---- live squad access ---------------------------------------------------

## A club dict view backed by the live roster: {id, name, players}. This is what
## tactics, ratings, the squad screen and finances read once you're managing.
func club_view(id: int) -> Dictionary:
	return {"id": id, "name": club_names.get(id, "?"), "players": rosters.get(id, [])}

func squad_of(id: int) -> Array:
	return rosters.get(id, [])


func _apply(s: Dictionary, gf: int, ga: int) -> void:
	s["P"] += 1
	s["GF"] += gf
	s["GA"] += ga
	if gf > ga:
		s["W"] += 1
		s["Pts"] += 3
	elif gf == ga:
		s["D"] += 1
		s["Pts"] += 1
	else:
		s["L"] += 1


## Sorted standings (Pts, then GD, GF, name) as an Array of stat rows.
func standings() -> Array:
	var rows: Array = table.values()
	rows.sort_custom(func(a, b):
		if a["Pts"] != b["Pts"]:
			return a["Pts"] > b["Pts"]
		var gda: int = a["GF"] - a["GA"]
		var gdb: int = b["GF"] - b["GA"]
		if gda != gdb:
			return gda > gdb
		if a["GF"] != b["GF"]:
			return a["GF"] > b["GF"]
		return a["name"] < b["name"])
	return rows

## Manager's current league position (1-based).
func position() -> int:
	var rows := standings()
	for i in rows.size():
		if int(rows[i]["id"]) == club_id:
			return i + 1
	return rows.size()

func objective_met() -> bool:
	return position() <= objective_pos


# ---- transfer market -----------------------------------------------------

const _LOG_CAP := 40
const _NEWS_CAP := 50

func _log(line: String) -> void:
	transfer_log.push_front(line)
	if transfer_log.size() > _LOG_CAP:
		transfer_log.resize(_LOG_CAP)

## Push a club-news item (injuries/suspensions/returns + the matchday headline).
## Newest first, stamped with the week just played; capped.
func _news(kind: String, text: String) -> void:
	news_log.push_front({"week": week, "kind": kind, "text": text})
	if news_log.size() > _NEWS_CAP:
		news_log.resize(_NEWS_CAP)

## A "Matchday N: ARSENAL 2-1 CHELSEA -- a win" headline from the manager's result.
func _log_result(res: Dictionary) -> void:
	var hg := int(res["hg"])
	var ag := int(res["ag"])
	var home: bool = bool(res["manager_home"])
	var home_name: String = club_names.get(int(res["home_id"]), "?")
	var away_name: String = club_names.get(int(res["away_id"]), "?")
	var mine := hg if home else ag
	var theirs := ag if home else hg
	var verdict := "a win" if mine > theirs else ("a draw" if mine == theirs else "a defeat")
	_news("result", "Matchday %d: %s %d-%d %s -- %s." % [week, home_name, hg, ag, away_name, verdict])

## True while the transfer window is open (before deadline day).
func transfers_open() -> bool:
	return week < maxi(0, total_weeks() - DEADLINE_TAIL)

## Rounds until the deadline (0 once it has passed).
func deadline_weeks_left() -> int:
	return maxi(0, (total_weeks() - DEADLINE_TAIL) - week)

func my_squad() -> Array:
	return rosters.get(club_id, [])

## The buyable market: every other club's players, dearest first.
func market() -> Array:
	return TransferMarket.market(rosters, club_names, tier, club_id)

func _find_in(id: int, pid: int) -> Dictionary:
	for p in rosters.get(id, []):
		if int(p.get("id", -1)) == pid:
			return p
	return {}

## Bid `offer` for player `pid` at `from_club_id`. Mutates squads + cash on success.
## Returns {ok: bool, msg: String}. Enforces the board caps (deadline, weekly offer
## allowance, squad size, cash) before the selling club even considers the bid.
func sign_player(pid: int, from_club_id: int, offer: int, rng: RandomNumberGenerator) -> Dictionary:
	if not transfers_open():
		return {"ok": false, "msg": "The transfer deadline has passed."}
	if offers_left <= 0:
		return {"ok": false, "msg": "The Directors will only let you make %d offers to sign a player per week." % OFFERS_PER_WEEK}
	if my_squad().size() >= TransferMarket.SQUAD_MAX:
		return {"ok": false, "msg": "Your squad is full (%d), the maximum allowed. You can not sign more." % TransferMarket.SQUAD_MAX}
	if offer > cash:
		return {"ok": false, "msg": "You do not have enough money to make this offer."}
	var player := _find_in(from_club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer available."}
	offers_left -= 1   # an offer counts whether or not it is accepted
	var is_key := TransferMarket.is_key_player(club_view(from_club_id), pid)
	var verdict := TransferMarket.evaluate_offer(player, offer, is_key, tier, rng)
	var seller_name: String = club_names.get(from_club_id, "?")
	if not verdict["accepted"]:
		return {"ok": false, "msg": "%s have rejected your offer for %s." % [seller_name, player.get("name", "?")]}
	rosters[from_club_id].erase(player)
	player["clubId"] = club_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	rosters[club_id].append(player)
	cash -= offer
	transfer_listed.erase(pid)
	shortlist.erase(pid)
	_log("You have signed %s from %s for £%s." % [player.get("name", "?"), seller_name, _money(offer)])
	return {"ok": true, "msg": "You have signed %s." % player.get("name", "?")}

func is_listed(pid: int) -> bool:
	return transfer_listed.has(pid)

func toggle_listed(pid: int) -> void:
	if transfer_listed.has(pid):
		transfer_listed.erase(pid)
	else:
		transfer_listed[pid] = true

## The best AI offer for one of your players (used by the SALE screen). {} if none.
func solicit_sale(pid: int, rng: RandomNumberGenerator) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {}
	return TransferMarket.solicit_offer(player, rosters, club_names, tier, club_id, rng)

## Accept an AI offer for your player. Mutates squads + cash. {ok, msg}. Guards the
## squad floor so you can't sell yourself unable to field a side.
func accept_sale(pid: int, buyer_id: int, offer: int) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is no longer here."}
	var squad := my_squad()
	if squad.size() <= TransferMarket.SQUAD_MIN:
		return {"ok": false, "msg": "Your squad is too small to sell (min %d)." % TransferMarket.SQUAD_MIN}
	if player.get("isGK") and TransferMarket._count_keepers(squad) <= TransferMarket.MIN_KEEPERS:
		return {"ok": false, "msg": "You must keep at least %d goalkeepers." % TransferMarket.MIN_KEEPERS}
	rosters[club_id].erase(player)
	player["clubId"] = buyer_id
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	if rosters.has(buyer_id):
		rosters[buyer_id].append(player)
	cash += offer
	transfer_listed.erase(pid)
	var buyer_name: String = club_names.get(buyer_id, "?")
	_log("%s has been signed by %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)])
	return {"ok": true, "msg": "Sold %s to %s for £%s." % [player.get("name", "?"), buyer_name, _money(offer)]}

## Renew a squad player's contract (RENEW), resetting his term. {ok, msg}.
func renew(pid: int) -> Dictionary:
	var player := _find_in(club_id, pid)
	if player.is_empty():
		return {"ok": false, "msg": "That player is not in your squad."}
	player["contract_years"] = TransferMarket.NEW_CONTRACT_YEARS
	_log("%s has renewed his contract." % player.get("name", "?"))
	return {"ok": true, "msg": "%s has renewed his contract." % player.get("name", "?")}

func toggle_shortlist(pid: int) -> void:
	if shortlist.has(pid):
		shortlist.erase(pid)
	else:
		shortlist.append(pid)

func _money(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


# ---- season rollover -----------------------------------------------------

## Roll the career into the next season, KEEPING the live rosters, cash and tactics.
## Contracts tick down; any of your players who hit zero and weren't renewed leave on
## a free. Fixtures, table and objective are rebuilt from the current squads.
func advance_season(leagues: Array) -> void:
	var leavers: Array = []
	for p in rosters.get(club_id, []):
		var yrs := int(p.get("contract_years", 1)) - 1
		p["contract_years"] = yrs
		if yrs <= 0:
			leavers.append(p)
	for p in leavers:
		rosters[club_id].erase(p)
		_log("%s has left your club as his contract was not renewed." % p.get("name", "?"))
	# AI contracts tick but auto-renew, so rival squads stay stable across years.
	for cid in rosters:
		if int(cid) == club_id:
			continue
		for p in rosters[cid]:
			p["contract_years"] = maxi(1, int(p.get("contract_years", 2)) - 1) + 1
	# Fresh season = clean slate: bans don't carry over and everyone reports fit.
	Availability.reset(rosters.get(club_id, []))

	year += 1
	season = _season_label(year)
	week = 0
	finished = false
	results.clear()
	transfer_listed.clear()
	offers_left = OFFERS_PER_WEEK
	_log("--- %s season ---" % season)

	var ids: Array = rosters.keys()
	var views: Array = []
	for id in ids:
		views.append(club_view(id))
	fixtures = SeasonSim.fixtures(ids)
	_init_table(views)
	var league := {"id": league_id, "name": league_name, "tier": tier}
	_set_objective(league, views, leagues)
	var fin := FinanceModel.summary(club_view(club_id), tier)
	weekly_net = int(fin["weekly_balance"])
	# Refit the XI to the (possibly changed) squad while keeping the shape.
	if not tactics.is_empty():
		var t := Tactics.from_dict(tactics)
		t.set_formation(t.formation, club_view(club_id))
		tactics = t.to_dict()

func _season_label(yr: int) -> String:
	var start := 1996 + yr   # year 1 -> 1997-98
	return "%d-%02d" % [start, (start + 1) % 100]


# ---- persistence ---------------------------------------------------------

func to_dict() -> Dictionary:
	# JSON keys must be strings; store int-keyed dicts with string keys.
	var tbl: Dictionary = {}
	for id in table:
		tbl[str(id)] = table[id]
	var ros: Dictionary = {}
	for id in rosters:
		ros[str(id)] = rosters[id]
	var nms: Dictionary = {}
	for id in club_names:
		nms[str(id)] = club_names[id]
	var listed: Dictionary = {}
	for pid in transfer_listed:
		listed[str(pid)] = true
	return {
		"club_id": club_id, "club_name": club_name, "league_id": league_id,
		"league_name": league_name, "season": season, "year": year, "week": week,
		"fixtures": fixtures, "table": tbl, "results": results, "cash": cash,
		"weekly_net": weekly_net, "objective_pos": objective_pos,
		"objective_text": objective_text, "finished": finished,
		"tactics": tactics, "tier": tier, "rosters": ros, "club_names": nms,
		"transfer_listed": listed, "shortlist": shortlist, "transfer_log": transfer_log,
		"offers_left": offers_left, "news_log": news_log,
	}

static func from_dict(d: Dictionary) -> Career:
	var c := Career.new()
	c.club_id = int(d.get("club_id", -1))
	c.club_name = d.get("club_name", "?")
	c.league_id = d.get("league_id", "")
	c.league_name = d.get("league_name", "League")
	c.season = d.get("season", "1997-98")
	c.year = int(d.get("year", 1))
	c.week = int(d.get("week", 0))
	c.fixtures = d.get("fixtures", [])
	c.results = d.get("results", [])
	c.cash = int(d.get("cash", 0))
	c.weekly_net = int(d.get("weekly_net", 0))
	c.objective_pos = int(d.get("objective_pos", 17))
	c.objective_text = d.get("objective_text", "")
	c.finished = bool(d.get("finished", false))
	c.tactics = d.get("tactics", {})
	c.tier = int(d.get("tier", 1))
	c.shortlist = []
	for v in d.get("shortlist", []):
		c.shortlist.append(int(v))
	c.transfer_log = d.get("transfer_log", [])
	c.offers_left = int(d.get("offers_left", OFFERS_PER_WEEK))
	c.news_log = d.get("news_log", [])
	c.table = {}
	for k in d.get("table", {}):
		c.table[int(k)] = d["table"][k]
	c.rosters = {}
	for k in d.get("rosters", {}):
		c.rosters[int(k)] = d["rosters"][k]
	c.club_names = {}
	for k in d.get("club_names", {}):
		c.club_names[int(k)] = d["club_names"][k]
	c.transfer_listed = {}
	for k in d.get("transfer_listed", {}):
		c.transfer_listed[int(k)] = true
	return c

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func save(path: String = SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))

static func load_save(path: String = SAVE_PATH) -> Career:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return null
	return from_dict(parsed)
