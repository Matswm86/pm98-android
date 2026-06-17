class_name Tactics
extends RefCounted
## Manager team selection + tactics for a career: the formation, the chosen XI,
## marking and the set-piece takers. Produces a ratings dict that MatchEngine
## consumes in place of the auto-best-XI, so who you pick and the shape you
## play actually move the scoreline.
##
## Grounded in MANAGER.EXE strings (scanned from the binary):
##   TEAM TACTICS / LINE-UP / SAVE TACTICS / LOAD TACTICS / PREDEF. TACTICS,
##   the four formations verbatim "5-3-2 4-4-2 4-3-3 3-5-2",
##   DEFENDING MARKING / MIDFIELDING MARKING / MAN-TO-MAN MARKINGS,
##   "Penalty taken by %s" / "Corner taken by %s" / "Free kick taken by %s",
##   and the rejection message "The initial line-up is not correct."
## The formation set, the marking/takers surface and that message are PM98's.
## The att/def role-weight model that turns an XI into ratings is OURS, calibrated
## to keep parity with MatchEngine.team_ratings so AI clubs (auto-best-XI) and the
## manager's chosen XI sit on one scale -- a balanced 4-4-2 of the best 10 ~ auto.
##
## GameDB-free (callers pass the club dict in) so it stays headless-testable.

# PM98's four formations (verbatim): outfield line counts [DEF, MID, FWD].
const FORMATIONS := {
	"5-3-2": [5, 3, 2],
	"4-4-2": [4, 4, 2],
	"4-3-3": [4, 3, 3],
	"3-5-2": [3, 5, 2],
}
const FORMATION_ORDER := ["5-3-2", "4-4-2", "4-3-3", "3-5-2"]
const DEFAULT_FORMATION := "4-4-2"

const MARKINGS := ["Zonal", "Man-to-man"]

const LINEUP_BAD := "The initial line-up is not correct."

# Role emphasis. Used as a WEIGHTED MEAN over the XI (weights need not sum to 1),
# so a more attacking shape leans on its forwards and a defensive shape on its
# back line -- the formation is an att/def trade-off rather than a free buff.
const _ROLE_ATK := {"DEF": 0.6, "MID": 1.0, "FWD": 1.5}
const _ROLE_DEF := {"DEF": 1.5, "MID": 1.0, "FWD": 0.5}

# Explicit shape multiplier [att, def] on top of role weighting, so the formation
# is a legible lever (not a fraction of a point). Centred on 4-4-2 = 1.0/1.0, which
# keeps the balanced best XI at parity with team_ratings. Ours, calibrated.
const _FORM_FACTOR := {
	"5-3-2": [0.95, 1.05],
	"4-4-2": [1.00, 1.00],
	"4-3-3": [1.06, 0.94],
	"3-5-2": [1.02, 0.98],
}

# Man-to-man tightens the back line at a small attacking cost (ours, calibrated).
const _MARK_MAN_DEF := 1.04
const _MARK_MAN_ATK := 0.98

# Per-player fallback scores when a chosen player has no decoded attr row.
const _NEUTRAL_SCORE := 50.0
const _NEUTRAL_GK := 52.0

var formation: String = DEFAULT_FORMATION
var xi: Array = []              # 11 player ids, slot order: [GK, DEF.., MID.., FWD..]
var marking: String = "Zonal"   # defending-line marking: "Zonal" | "Man-to-man"
var captain_id: int = -1
var pk_taker_id: int = -1        # penalty
var ck_taker_id: int = -1        # corner
var fk_taker_id: int = -1        # free kick


# ---- shape ---------------------------------------------------------------

## Slot roles for a formation, length 11: ["GK","DEF",...,"MID",...,"FWD",...].
static func slot_roles(form: String) -> Array:
	var lines: Array = FORMATIONS.get(form, FORMATIONS[DEFAULT_FORMATION])
	var roles: Array = ["GK"]
	for _i in int(lines[0]):
		roles.append("DEF")
	for _i in int(lines[1]):
		roles.append("MID")
	for _i in int(lines[2]):
		roles.append("FWD")
	return roles

func roles() -> Array:
	return slot_roles(formation)


# ---- construction --------------------------------------------------------

## Build sensible default tactics for `club`: best keeper, then fill the shape by
## role (best defenders by defending, best forwards by attacking, best midfield by
## overall), with captain + set-piece takers derived from the chosen XI.
static func auto_pick(club: Dictionary, form: String = DEFAULT_FORMATION) -> Tactics:
	var t := Tactics.new()
	t.formation = form if FORMATIONS.has(form) else DEFAULT_FORMATION
	t._fill_xi(club)
	t._derive_roles(club)
	return t

## (Re)select the XI for the current formation from the club's squad.
func _fill_xi(club: Dictionary) -> void:
	var players: Array = club.get("players", [])
	var keepers: Array = []
	var outfield: Array = []   # [{id, atk, def, ovr}]
	for p in players:
		var pid := int(p.get("id", -1))
		if pid < 0:
			continue
		var attrs: Variant = p.get("attrs", {})
		var has_attrs: bool = (attrs is Dictionary) and not (attrs as Dictionary).is_empty()
		if p.get("isGK"):
			var po: float = float((attrs as Dictionary).get("PO", _NEUTRAL_GK)) if has_attrs else _NEUTRAL_GK
			keepers.append({"id": pid, "po": po})
		else:
			var atk := MatchEngine.atk_score(attrs) if has_attrs else _NEUTRAL_SCORE
			var dfn := MatchEngine.def_score(attrs) if has_attrs else _NEUTRAL_SCORE
			outfield.append({"id": pid, "atk": atk, "def": dfn, "ovr": 0.5 * atk + 0.5 * dfn,
				"pos": str(p.get("pos", ""))})

	keepers.sort_custom(func(a, b): return a["po"] > b["po"])
	var lines: Array = FORMATIONS[formation]
	var n_def := int(lines[0])
	var n_mid := int(lines[1])
	var n_fwd := int(lines[2])

	# Each line prefers its decoded demarcación (DF back, FW up front, MF in the middle),
	# ranked within the position by its trait, then spills into other outfielders if a
	# bucket is short. Defenders first, forwards next, midfield takes the remainder.
	var taken: Dictionary = {}
	var def_ids := _take(outfield, "def", n_def, taken, "DF")
	var fwd_ids := _take(outfield, "atk", n_fwd, taken, "FW")
	var mid_ids := _take(outfield, "ovr", n_mid, taken, "MF")

	xi.clear()
	xi.append(int(keepers[0]["id"]) if not keepers.is_empty() else -1)
	xi.append_array(def_ids)
	xi.append_array(mid_ids)
	xi.append_array(fwd_ids)

## Pick the top `n` ids of `pool` by `key`, skipping ids already in `taken`. When
## `want_pos` is given, players of that decoded position are preferred (sorted by `key`)
## and only when the bucket runs short do other outfielders fill in (also by `key`) -
## so a real defender is never benched for a forward with a fluke defending score.
func _take(pool: Array, key: String, n: int, taken: Dictionary, want_pos: String = "") -> Array:
	var avail: Array = pool.filter(func(r): return not taken.has(r["id"]))
	var by_key := func(a, b): return a[key] > b[key]
	var ordered: Array = avail
	if want_pos != "":
		var match_pos: Array = avail.filter(func(r): return str(r.get("pos", "")) == want_pos)
		var rest: Array = avail.filter(func(r): return str(r.get("pos", "")) != want_pos)
		match_pos.sort_custom(by_key)
		rest.sort_custom(by_key)
		ordered = match_pos + rest
	else:
		ordered.sort_custom(by_key)
	var ids: Array = []
	for i in mini(n, ordered.size()):
		ids.append(int(ordered[i]["id"]))
		taken[ordered[i]["id"]] = true
	return ids

## Captain + set-piece takers from the XI (captain = best ability, penalty/free
## kick = best shooting, corner = best passing). All chosen from players on the pitch.
func _derive_roles(club: Dictionary) -> void:
	var by_id := _players_by_id(club)
	captain_id = _best_in_xi(by_id, "CA")
	pk_taker_id = _best_in_xi(by_id, "TI")
	fk_taker_id = pk_taker_id
	ck_taker_id = _best_in_xi(by_id, "PA")

func _best_in_xi(by_id: Dictionary, code: String) -> int:
	var best_id := -1
	var best := -1.0
	for i in range(1, xi.size()):   # outfield only (skip the keeper)
		var p: Variant = by_id.get(int(xi[i]))
		if p == null:
			continue
		var attrs: Dictionary = (p as Dictionary).get("attrs", {})
		var v := float(attrs.get(code, 0))
		if v > best:
			best = v
			best_id = int(xi[i])
	return best_id


# ---- ratings (the MatchEngine feed) --------------------------------------

## {att, def, gk, name} for `club` built from the chosen XI + shape + marking.
## Falls back to MatchEngine.team_ratings when the line-up is invalid, mirroring
## PM98 auto-filling an incorrect line-up.
func ratings(club: Dictionary) -> Dictionary:
	if validate(club) != "":
		return MatchEngine.team_ratings(club)
	var by_id := _players_by_id(club)
	var rs := roles()

	var gk := _NEUTRAL_GK
	var gkp: Variant = by_id.get(int(xi[0]))
	if gkp != null:
		gk = float((gkp as Dictionary).get("attrs", {}).get("PO", _NEUTRAL_GK))

	var att_num := 0.0
	var att_den := 0.0
	var def_num := 0.0
	var def_den := 0.0
	for i in range(1, 11):
		var role: String = rs[i]
		var p: Variant = by_id.get(int(xi[i]))
		var attrs: Dictionary = (p as Dictionary).get("attrs", {}) if p != null else {}
		var has: bool = not attrs.is_empty()
		var atk := MatchEngine.atk_score(attrs) if has else _NEUTRAL_SCORE
		var dfn := MatchEngine.def_score(attrs) if has else _NEUTRAL_SCORE
		var wa: float = _ROLE_ATK[role]
		var wd: float = _ROLE_DEF[role]
		att_num += atk * wa
		att_den += wa
		def_num += dfn * wd
		def_den += wd

	var att := att_num / att_den if att_den > 0.0 else _NEUTRAL_SCORE
	var dfn_team := def_num / def_den if def_den > 0.0 else _NEUTRAL_SCORE
	var ff: Array = _FORM_FACTOR.get(formation, [1.0, 1.0])
	att *= float(ff[0])
	dfn_team *= float(ff[1])
	if marking == "Man-to-man":
		dfn_team *= _MARK_MAN_DEF
		att *= _MARK_MAN_ATK
	return {"att": att, "def": dfn_team, "gk": gk, "name": club.get("name", "?")}


# ---- validation ----------------------------------------------------------

## "" when the line-up is correct, else PM98's "The initial line-up is not correct."
func validate(club: Dictionary) -> String:
	if not FORMATIONS.has(formation):
		return LINEUP_BAD
	if xi.size() != 11:
		return LINEUP_BAD
	var by_id := _players_by_id(club)
	var seen: Dictionary = {}
	var rs := roles()
	for i in xi.size():
		var pid := int(xi[i])
		if not by_id.has(pid) or seen.has(pid):
			return LINEUP_BAD
		seen[pid] = true
		var is_gk: bool = bool((by_id[pid] as Dictionary).get("isGK", false))
		if rs[i] == "GK" and not is_gk:
			return LINEUP_BAD
		if rs[i] != "GK" and is_gk:
			return LINEUP_BAD
	return ""


# ---- manual edits --------------------------------------------------------

## Put `pid` into slot `i`; if it is already elsewhere in the XI, swap the two.
func assign(slot: int, pid: int) -> void:
	if slot < 0 or slot >= xi.size():
		return
	var cur := int(xi[slot])
	var at := xi.find(pid)
	if at != -1:
		xi[at] = cur
	xi[slot] = pid

## Switch formation, refilling the XI for the new shape from `club`.
func set_formation(form: String, club: Dictionary) -> void:
	if not FORMATIONS.has(form):
		return
	formation = form
	_fill_xi(club)
	_derive_roles(club)

func cycle_marking() -> void:
	marking = MARKINGS[(MARKINGS.find(marking) + 1) % MARKINGS.size()]


# ---- helpers -------------------------------------------------------------

func _players_by_id(club: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for p in club.get("players", []):
		out[int(p.get("id", -1))] = p
	return out


# ---- persistence ---------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"formation": formation, "xi": xi.duplicate(), "marking": marking,
		"captain_id": captain_id, "pk_taker_id": pk_taker_id,
		"ck_taker_id": ck_taker_id, "fk_taker_id": fk_taker_id,
	}

static func from_dict(d: Dictionary) -> Tactics:
	var t := Tactics.new()
	t.formation = d.get("formation", DEFAULT_FORMATION)
	var raw: Array = d.get("xi", [])
	t.xi = []
	for v in raw:
		t.xi.append(int(v))
	t.marking = d.get("marking", "Zonal")
	t.captain_id = int(d.get("captain_id", -1))
	t.pk_taker_id = int(d.get("pk_taker_id", -1))
	t.ck_taker_id = int(d.get("ck_taker_id", -1))
	t.fk_taker_id = int(d.get("fk_taker_id", -1))
	return t


# ---- named presets (SAVE / LOAD / PREDEF. TACTICS) -----------------------
# A preset stores only the reusable SHAPE (formation + marking), not the per-club
# XI -- exactly what PM98's predefined/saved tactics carry. Loading one re-fills
# the XI for the new club. Saved presets live as flat user://tactic_*.json files.

const _PRESET_PREFIX := "tactic_"

## The four formations as predefined zonal tactics, plus any user-saved presets.
static func list_presets() -> Array:
	var out: Array = []
	for form in FORMATION_ORDER:
		out.append({"name": form, "formation": form, "marking": "Zonal", "builtin": true})
	var dir := DirAccess.open("user://")
	if dir != null:
		for fn in dir.get_files():
			if not (fn.begins_with(_PRESET_PREFIX) and fn.ends_with(".json")):
				continue
			var f := FileAccess.open("user://" + fn, FileAccess.READ)
			if f == null:
				continue
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary and (d as Dictionary).has("formation"):
				var rec: Dictionary = d
				rec["builtin"] = false
				rec["path"] = "user://" + fn
				out.append(rec)
	return out

func save_preset(name: String) -> void:
	var slug := name.to_lower().replace(" ", "_").replace("/", "-")
	var f := FileAccess.open("user://%s%s.json" % [_PRESET_PREFIX, slug], FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"name": name, "formation": formation, "marking": marking}))

## Apply a preset's shape to `club`, refilling the XI for the new formation.
func apply_preset(preset: Dictionary, club: Dictionary) -> void:
	marking = preset.get("marking", "Zonal")
	set_formation(preset.get("formation", DEFAULT_FORMATION), club)


# ---- availability repair -------------------------------------------------
# When players are unavailable (injured/suspended/sold), `club` is passed in as a
# fit-only view. Any XI slot whose player is missing from that view is refilled
# with the best available player of that slot's role, keeping the manager's other
# picks intact. The result rates + validates against the same fit view, so losing
# one player reshuffles only his slot rather than auto-picking the whole side.

## A copy of these tactics with every vacated slot (player absent from `club`)
## refilled by the best available player of that role. Slots stay -1 if no fit
## player of the role remains (a depleted squad), which trips validate() ->
## team_ratings fallback in ratings(). Re-derives captain + set-piece takers.
func repaired(club: Dictionary) -> Tactics:
	var t := Tactics.from_dict(to_dict())
	var by_id := _players_by_id(club)
	var rs := t.roles()
	var used: Dictionary = {}
	for pid in t.xi:
		if by_id.has(int(pid)):
			used[int(pid)] = true

	# Replacement pools: fit players not already kept in the XI.
	var keepers: Array = []
	var outfield: Array = []
	for p in club.get("players", []):
		var pid := int(p.get("id", -1))
		if pid < 0 or used.has(pid):
			continue
		var attrs: Variant = p.get("attrs", {})
		var has: bool = (attrs is Dictionary) and not (attrs as Dictionary).is_empty()
		if p.get("isGK"):
			var po: float = float((attrs as Dictionary).get("PO", _NEUTRAL_GK)) if has else _NEUTRAL_GK
			keepers.append({"id": pid, "po": po})
		else:
			var atk := MatchEngine.atk_score(attrs) if has else _NEUTRAL_SCORE
			var dfn := MatchEngine.def_score(attrs) if has else _NEUTRAL_SCORE
			outfield.append({"id": pid, "atk": atk, "def": dfn, "ovr": 0.5 * atk + 0.5 * dfn})
	keepers.sort_custom(func(a, b): return a["po"] > b["po"])

	for i in t.xi.size():
		if by_id.has(int(t.xi[i])):
			continue   # this pick is still available
		var role: String = rs[i] if i < rs.size() else "MID"
		var repl := -1
		if role == "GK":
			if not keepers.is_empty():
				repl = int((keepers.pop_front() as Dictionary)["id"])
		else:
			var key := "def" if role == "DEF" else ("atk" if role == "FWD" else "ovr")
			outfield.sort_custom(func(a, b): return a[key] > b[key])
			if not outfield.is_empty():
				repl = int((outfield.pop_front() as Dictionary)["id"])
		t.xi[i] = repl
	t._derive_roles(club)
	return t
