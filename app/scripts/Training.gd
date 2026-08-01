class_name Training
extends RefCounted
## Player development through training.
##
## `develop_week` is a byte-exact port of the engine's own weekly pass
## `FUN_00582760`, decoded 2026-07-24 — see the long comment above it for the
## disassembly, the two attribute blocks it reads and every constant. It replaced an
## invented age-based drift model whose prime-age rate needed 67 weeks per point,
## which is why the owner reported "training doesn't actually do anything".
##
## What survives from the old model, and why:
##   * `INTENSITIES` / `injury_multiplier` — the LIGHT/NORMAL/INTENSIVE lever still
##     feeds Availability's injury roll. It has no development effect (the engine's
##     pass has no intensity term).
##   * `trend()` — a TRAINING-screen readout only, not a prediction.
##
## GameDB-free, mutates only the dicts passed in -> headless-testable
## (tests/test_training.gd + tests/test_training_exact.gd). The engine runs this over
## EVERY club's squad each week; Career does the same.

const INTENSITIES := ["Light", "Normal", "Intensive"]
const DEFAULT_INTENSITY := "Normal"

# Per-intensity injury-risk multiplier (the lever's only surviving effect).
const _FACTOR := {"Light": 0.60, "Normal": 1.00, "Intensive": 1.55}
const _INJURY_MULT := {"Light": 0.75, "Normal": 1.00, "Intensive": 1.45}

# Age bands, kept for `trend()`'s TRAINING-screen arrows only. The engine's weekly
# pass has NO age term (see develop_week); these do not move a single attribute.
const PRIME_LO := 23
const PRIME_HI := 30

# The attribute labels the original's own PLAYER INFORMATION card prints, verified
# 2026-07-25 against Andrew Alexander COLE's live card (frame p0056) beside his
# game_db row: SPEED 87 / STAMINA 86 / AGGRESSION 84 / QUALITY 75 and HANDLING 13 /
# PASSING 70 / DRIBBLING 86 / HEADING 73 / TACKLING 65 / SHOOTING 88 against
# VE 87 RE 86 AG 84 CA 75 · PO 13 PA 70 RM 86 RG 73 EN 65 TI 88. Every value matches,
# so the card pins all ten codes. This dict previously had RM and RG SWAPPED and called
# VE "Pace" / CA "Ability" / PO "Goalkeeping" — none of which is a word the game uses.
const _NAMES := {
	"VE": "Speed", "RE": "Stamina", "AG": "Aggression", "CA": "Quality",
	"RM": "Dribbling", "RG": "Heading", "PA": "Passing", "TI": "Shooting",
	"EN": "Tackling", "PO": "Handling",
}


# ---- lookups -------------------------------------------------------------

static func intensity_factor(intensity: String) -> float:
	return float(_FACTOR.get(intensity, 1.0))

## Injury-risk multiplier for the intensity (fed to Availability.roll_match).
static func injury_multiplier(intensity: String) -> float:
	return float(_INJURY_MULT.get(intensity, 1.0))

static func attr_name(code: String) -> String:
	return str(_NAMES.get(code, code))


# ---- trend (for the training screen) -------------------------------------

## {dir:"up"|"down"|"hold", arrow:String, colour:Color, ability:int, name:String}
## for one player -- how the TRAINING screen shows him moving. Kept as a SCREEN
## affordance only: the engine's weekly pass (develop_week, below) has no age term,
## so this is a readout of who the manager would normally push, not a prediction.
static func trend(p: Dictionary) -> Dictionary:
	var age := int(p.get("age", 26))
	var attrs: Dictionary = p.get("attrs", {}) if p.get("attrs") is Dictionary else {}
	var ca := int(attrs.get("CA", 0))
	if age <= PRIME_LO:
		return {"dir": "up", "arrow": "^", "colour": Color(0.34, 0.86, 0.46),
			"ability": ca, "name": str(p.get("name", "?"))}
	if age > PRIME_HI:
		return {"dir": "down", "arrow": "v", "colour": Color(0.92, 0.36, 0.33),
			"ability": ca, "name": str(p.get("name", "?"))}
	return {"dir": "hold", "arrow": "-", "colour": Color(0.86, 0.90, 0.96),
		"ability": ca, "name": str(p.get("name", "?"))}


## Reset development carry-over (season rollover). The exact pass keeps no
## fractional carry, so this only clears the superseded field off old saves.
static func reset_progress(squad: Array) -> void:
	for p in squad:
		p["dev_progress"] = 0.0


# ---- FOCUS training (the real TRAINING screen's mechanic) ------------------
# Live-witnessed on MANAGER.EXE 2026-07-24 (Bolton career, week 3):
#  * With NO trainers hired the whole screen is washed, TOTAL TRAINABLE PLAYERS = 0
#    and AUTO is inert ("For specific training\nyou have to have hired trainers.").
#  * Hiring HANDLING F. Bush 4.0* and SHOOTING G. Slattery 2.5* put their names on the
#    CURRENT TRAINING STAFF band with a TP column reading 4 and 2 — floor(stars) — and
#    TOTAL TRAINABLE PLAYERS became 6 = 4 + 2.
#  * AUTO tagged the three keepers HA and two forwards SH; the grid TOTAL read 5.
#  * Selecting a player and ticking a right-panel skill box assigns him: the box turns
#    gold, his grid row gains the 2-letter tag and TOTAL goes up by one.
#  * Ticking a skill whose coach is already at his TP is refused SILENTLY (a 5th
#    HANDLING pick did nothing); ticking with the GLOBAL total already at TOTAL
#    TRAINABLE raises the alert "You can´t train any more players." (MANAGER.EXE
#    0x2593f0).
# The per-skill attribute map is the screen's own row order (SPEC_BINDING §3).

# The eight focus rows of the AVER. panel, top to bottom.
const FOCUS_GENERAL := "GENERAL"
const FOCUS_FITNESS := "FITNESS"
const FOCUS_SKILLS := ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]
const FOCUS_ROWS := [FOCUS_GENERAL, FOCUS_FITNESS, "HANDLING", "PASSING", "DRIBBLING",
	"HEADING", "TACKLING", "SHOOTING"]

# Focus -> the decoded attribute it trains (the right panel's own rows).
const FOCUS_ATTR := {
	"HANDLING": "PO", "PASSING": "PA", "DRIBBLING": "RM",
	"HEADING": "RG", "TACKLING": "EN", "SHOOTING": "TI",
}
# GENERAL is mode 1: it lifts all SIX trainable attributes, but only to base+5
# (FUN_00582760 case 1). It does NOT touch SPEED/STAMINA/AGGRESSION/QUALITY —
# those four are the untrainable core (see develop_week).

const FOCUS_CODE := {
	"GENERAL": "GE", "FITNESS": "FI", "HANDLING": "HA", "PASSING": "PA",
	"DRIBBLING": "DR", "HEADING": "HE", "TACKLING": "TA", "SHOOTING": "SH",
}
# CURRENT TRAINING STAFF bar fills, sampled off the real frames (the modal colour of
# x439..605 on each row): identical in 005_162348 (six coaches hired) and tn4 (two).
const FOCUS_COLOUR := {
	"GENERAL": Color8(59, 85, 130), "FITNESS": Color8(42, 127, 85),
	"HANDLING": Color8(212, 95, 0), "PASSING": Color8(212, 63, 0),
	"DRIBBLING": Color8(210, 0, 0), "HEADING": Color8(170, 0, 0),
	"TACKLING": Color8(150, 0, 0), "SHOOTING": Color8(85, 0, 0),
}
# The grid tag chip is a FLAT plate + the white 2-letter code, and its plate colour is
# its OWN table — NOT the staff bar's. Measured in 005_162348 at the chip cell x288..308:
#   HANDLING (212,95,0)   TACKLING (42,0,170)   PASSING (150,0,0)   SHOOTING (85,0,0)
# HANDLING and SHOOTING happen to match their bar; PASSING and TACKLING do not (the old
# code drew both from FOCUS_COLOUR and got them wrong). The four witnessed chips ship as
# frame cuts (app/art/screens/training/tag_*.png) and are drawn as art.
const TAG_ART := {"HANDLING": "ha", "PASSING": "pa", "TACKLING": "ta", "SHOOTING": "sh"}
# DRIBBLING / HEADING / GENERAL / FITNESS chips are UN-WITNESSED: no capture we hold has
# those coaches hired with a man assigned. They fall back to the witnessed chip grammar
# with the skill's own staff-bar colour — the least-invented choice available, since that
# IS the plate colour for two of the four witnessed chips. Flagged in
# docs/re/training_screen_re.md; hiring a DRIBBLING or HEADING coach in a live career and
# assigning a player is the capture that would settle it.
# The alert the original raises when the global capacity is full (0x2593f0, verbatim
# including its acute accent), and the no-trainer gate text (0x2593b8).
const FULL_MSG := "You can´t train any more players."
const NO_TRAINER_MSG := "For specific training\nyou have to have hired trainers."


# ==========================================================================
# THE REAL WEEKLY DEVELOPMENT PASS — a byte-exact port of FUN_00582760
# ==========================================================================
# Owner report 2026-07-24: "training doesn't actually do anything. The players'
# stats don't go up. They do in the original, so fix it so it's exact."
#
# It is now exact. `FUN_00582760` (MANAGER.EXE, 1240 bytes @0x582760) is the
# PER-PLAYER weekly pass; the weekly club turn `FUN_0057b400` — the same function
# that runs `FUN_0057f080`'s ground-works messages and the two scout "finished his
# search" lines — walks the club's squad list (club+0x24) and calls it once per
# player, for EVERY club. So an untrained player is not "developing slowly": the
# original does not move him at all.
#
# EVERY attribute is stored TWICE in the player record, decoded this session from
# the DBC loader `FUN_005820f0` @0x582185-0x582250, which writes each of the ten
# EQUIPOS bytes into both blocks:
#
#   LIVE   +0x9c VE  +0x9d RE  +0x9e AG  +0x9f CA  +0xa0 PO  +0xa1 EN
#          +0xa2 PA  +0xa3 RM  +0xa4 RG  +0xa5 TI
#   BASE   +0xaa VE  +0xab RE  +0xac AG  +0xad CA  +0xae PO  +0xaf EN
#          +0xb0 PA  +0xb1 RM  +0xb2 RG  +0xb3 TI
#
# (+0x9c..+0x9f being VE/RE/AG/CA is independently confirmed: `FUN_00534570`
# averages exactly those four bytes as `core4`, the known wage/AV input.)
# BASE is the shipped EQUIPOS rating and is never rewritten after load; LIVE is what
# training moves. `FUN_0058b030` restores VE/RE/AG/RG from BASE when the engine
# regenerates a player, which is what pins the direction of the pair.
#
# The pass, verbatim:
#
#   mode = player[+0xa9]                      ; 0 = not in training
#   if mode == 0:                             ; DECAY — gains bleed back to base
#       for a in [PO, EN, PA, RM, RG, TI]:
#           if base[a] < live[a]: live[a] -= 1
#   else:
#       roll = rand(7) + 0x12                 ; 18..24, the focused attribute's headroom
#       gain, cap[6] = 0, [0,0,0,0,0,0]
#       switch mode:
#         1 GENERAL   -> gain 1, cap[*] = 5
#         2 FITNESS   -> gain 0                       (condition only)
#         3 HANDLING  -> gain 1, cap[PO] = roll
#         4 PASSING   -> gain 1, cap[PA] = roll
#         5 DRIBBLING -> gain 1, cap[RM] = roll
#         6 HEADING   -> gain 1, cap[RG] = roll
#         7 TACKLING  -> gain 1, cap[EN] = roll
#         8 SHOOTING  -> gain 1, cap[TI] = roll
#         0x20 YOUTH  -> gain = 1 if rand(100) > 0x27 else 0     (60%)
#                        core4: live = min(live+gain, base); when all four reach
#                        base -> mode = 0 + "Your youth manager has informed you
#                        that %s is ready to be promoted to the first team squad."
#       if gain:
#           for a in the six:
#               n = live[a] + gain
#               if n <= base[a] + cap[a]: live[a] = 99 if n > 98 else n
#       condition(+0xa7) += 3 if mode == 2 else 1     (FUN_00584c60)
#
# Consequences that are the ORIGINAL's, not ours: a focused attribute climbs a
# FULL POINT EVERY WEEK until it is 18-24 clear of the shipped rating; GENERAL
# lifts all six but only by 5; the core four (SPEED/STAMINA/AGGRESSION/QUALITY)
# are NOT trainable at all — only the youth-growth mode moves them, and only back
# up to the player's own shipped adult rating; and taking a man off training bleeds
# his gains away at a point a week.
#
# NOT located yet, stated rather than invented: whether a separate season-rollover
# pass ages attributes. `FUN_005825c0` (season init) touches only morale +0xa6,
# condition +0xa8/+0xa7 and the counters — no attribute drift. The app's own
# age-based drift is therefore gone from the weekly pass.

# `player+0xa9` mode codes, keyed by the TRAINING screen's own row names.
const FOCUS_MODE := {
	FOCUS_GENERAL: 1, FOCUS_FITNESS: 2, "HANDLING": 3, "PASSING": 4,
	"DRIBBLING": 5, "HEADING": 6, "TACKLING": 7, "SHOOTING": 8,
}
const MODE_YOUTH := 0x20
# The six trainable attributes in the engine's own +0xa0..+0xa5 order.
const TRAINABLE := ["PO", "EN", "PA", "RM", "RG", "TI"]
# The four that only youth growth can move (+0x9c..+0x9f).
const CORE4 := ["VE", "RE", "AG", "CA"]
const GENERAL_CAP := 5           # case 1's flat headroom over base
const ROLL_BASE := 0x12          # rand(7) + 0x12 -> 18..24
const ROLL_SPAN := 7
const ATTR_MAX := 99             # `if (0x62 < n) n = 99`
const ATTR_SNAP := 0x62
const COND_FLOOR := 40           # FUN_00584c60's clamps (Morale.gd agrees: +0xa7 40..99)
const COND_CAP := 99


## The player's BASE (shipped EQUIPOS) attribute block — the engine's +0xaa..+0xb3.
## Seeded on first use for any player dict that predates it (a legacy save, a test
## fixture, a GameDB record used directly): his current values ARE his base until
## something trains him, which is exactly what the loader writes.
static func base_attrs(p: Dictionary) -> Dictionary:
	var b: Variant = p.get("attrs_base")
	if b is Dictionary and not (b as Dictionary).is_empty():
		return b
	var attrs: Variant = p.get("attrs", {})
	var seed_b: Dictionary = (attrs as Dictionary).duplicate() if attrs is Dictionary else {}
	p["attrs_base"] = seed_b
	return seed_b


## One WEEK of `FUN_00582760` over a squad. `focus` maps pid -> a FOCUS_ROWS name
## (absent = not in training). Returns the same {kind, text} news items as before,
## for the attributes that actually moved. Mutates `attrs` and `fitness` in place.
static func develop_week(rng: RandomNumberGenerator, squad: Array, focus: Dictionary = {}) -> Array:
	var news: Array = []
	for p in squad:
		var pd: Dictionary = p
		var av: Variant = pd.get("attrs", {})
		if not (av is Dictionary) or (av as Dictionary).is_empty():
			continue                       # unrated fringe record: the engine skips it too
		var attrs: Dictionary = av
		var base := base_attrs(pd)
		var mode := int(FOCUS_MODE.get(str(focus.get(int(pd.get("id", -1)), "")), 0))
		if mode == 0:
			# DECAY: anything above the shipped rating bleeds back a point a week.
			for a in TRAINABLE:
				if int(base.get(a, 0)) < int(attrs.get(a, 0)):
					attrs[a] = int(attrs[a]) - 1
			continue
		var roll := ROLL_BASE + rng.randi_range(0, ROLL_SPAN - 1)
		var gain := 1
		var cap := {}
		for a in TRAINABLE:
			cap[a] = 0
		match mode:
			1:
				for a in TRAINABLE:
					cap[a] = GENERAL_CAP
			2:
				gain = 0                   # FITNESS is condition only
			_:
				var key := str(FOCUS_ATTR.get(str(focus.get(int(pd.get("id", -1)), "")), ""))
				if key != "":
					cap[key] = roll
		if gain > 0:
			for a in TRAINABLE:
				var n := int(attrs.get(a, 0)) + gain
				if n <= int(base.get(a, 0)) + int(cap[a]):
					attrs[a] = ATTR_MAX if n > ATTR_SNAP else n
					if int(cap[a]) > 0:
						news.append({"kind": "training",
							"text": "%s has improved his %s in training." % [
								pd.get("name", "?"), attr_name(a)]})
		# FUN_00584c60: +3 condition on FITNESS, +1 otherwise.
		pd["fitness"] = clampi(int(pd.get("fitness", COND_CAP)) + (3 if mode == 2 else 1),
			COND_FLOOR, COND_CAP)
	return news


# The 0x20 YOUTH branch of the same switch, disassembled at 0x582813-0x5828c2:
#
#   case 0x20:
#     gain = (rand(100) > 0x27)                    ; 60%
#     if gain:
#       for a in CORE4 (live +0x9c..+0x9f / base +0xaa..+0xad):
#           n = live[a] + gain
#           if n <= base[a]: live[a] = 99 if n > 99 else n     ; i.e. min(live+gain, base)
#       if live[VE]==base[VE] and live[RE]==base[RE]
#          and live[AG]==base[AG] and live[CA]==base[CA]:
#           mode = 0
#           "Your youth manager has informed you that %s is ready to be
#            promoted to the first team squad."       (0x6634e1, via 0x662d58)
#   ; then the SHARED six-attribute block runs with cap[*] = 0, so the other six
#   ; also climb one a week and stop dead at BASE; condition +1 (FUN_00584c60).
#
# So a youth's ceiling is not a hidden number we roll: it is his own shipped
# EQUIPOS rating, which the DBC loader already knocked 35..45 off (see Youth.gd).
const YOUTH_GAIN_GATE := 0x27    # rand(100) > 0x27 -> gain 1

## OURS, and the only youth-TRAINING number that is (the twin of Youth.SEARCH_SPEEDUP,
## which is likewise ours). Owner decision 2026-07-25, recorded in
## docs/re/REFRUN_manutd_1997-98.md R17: "half the length of both scouting and training
## of youth players. Assume they take the same time." Scouting was already halved; this
## is training's half. The lever CANNOT be YOUTH_GAIN_GATE -- dropping it to 0 only takes
## the 60% firing rate to 100%, a 1.67x speedup, not 2x. The exact 2x is +2 per firing.
## Set to 1 for the binary's own cadence.
const YOUTH_GROWTH_SPEEDUP := 2

## The player+0xa9 training-mode byte the 0x20 YOUTH branch is keyed off. A youngster
## only reaches `case 0x20` while his mode byte HOLDS 0x20, and the ONLY thing that
## writes it is the TRAINING button on his own card (`0x527820`:
## `mov byte [player+0xa9], 0x20`). Promotion clears it back to 0 (`FUN_00588d10`).
## So an unassigned youngster does not develop at all — he sits at the rating the DBC
## loader knocked him down to until you put him in training. Carried on the port's
## player dicts as the boolean `in_training`.
const YOUTH_MODE := 0x20

## Is this youngster in the academy's training programme (mode byte == 0x20)?
static func youth_in_training(p: Dictionary) -> bool:
	return bool(p.get("in_training", false))

## The PROMOTE gate, `FUN_005274d0` @0x5275ba: the button is greyed unless all FOUR live
## CORE4 bytes (+0x9c..+0x9f) equal their BASE twins (+0xaa..+0xad) — the same equality
## the 0x20 growth branch tests before it reports him ready. So "ready" and "promotable"
## are one condition in the engine, read off the attributes rather than a stored flag.
static func youth_fully_grown(p: Dictionary) -> bool:
	var av: Variant = p.get("attrs", {})
	if not (av is Dictionary) or (av as Dictionary).is_empty():
		return false
	var attrs: Dictionary = av
	var base := base_attrs(p)
	for a in CORE4:
		if int(attrs.get(a, 0)) != int(base.get(a, 0)):
			return false
	return true


## `FUN_0057cd50` — how many of a club's youth carry the 0x20 mode byte right now. The
## engine walks the club's youth list (`club+0x3c`, next at `player+0x100`) and counts
## `player+0xa9 == 0x20`; the TRAINING button is greyed once this reaches the YOUTH TEAM
## MANAGER's `FUN_00578b80` capacity (Staff.youth_training_capacity).
static func youth_in_training_count(youth: Array) -> int:
	var n := 0
	for p in youth:
		if youth_in_training(p):
			n += 1
	return n


## One WEEK of the 0x20 YOUTH branch over a youth list. Returns {kind, text} news for
## each youngster the youth manager reports ready. Mutates attrs/fitness/`ready`.
## Only youngsters currently ASSIGNED to training (mode 0x20) develop — see YOUTH_MODE.
static func develop_youth_week(rng: RandomNumberGenerator, youth: Array) -> Array:
	var news: Array = []
	for p in youth:
		var pd: Dictionary = p
		var av: Variant = pd.get("attrs", {})
		if not (av is Dictionary) or (av as Dictionary).is_empty():
			continue
		var attrs: Dictionary = av
		var base := base_attrs(pd)
		if youth_in_training(pd) and not bool(pd.get("ready", false)):
			# YOUTH_GROWTH_SPEEDUP is ours; at 1 this is the binary's own +1.
			var gain := YOUTH_GROWTH_SPEEDUP if rng.randi_range(0, 99) > YOUTH_GAIN_GATE else 0
			if gain > 0:
				for a in CORE4:
					# The binary's clamp is `skip the step if it would overshoot BASE`,
					# which is identical to mini() at gain 1 but STALLS one point short
					# on an odd remaining gap at gain 2 -- and the CORE4 equality test
					# below would then never fire, so the youth never reports ready.
					# mini() is the faithful generalisation: never exceed BASE.
					var n := mini(int(attrs.get(a, 0)) + gain, int(base.get(a, 0)))
					if n > int(attrs.get(a, 0)):
						attrs[a] = ATTR_MAX if n > ATTR_MAX else n
				var done := true
				for a in CORE4:
					if int(attrs.get(a, 0)) != int(base.get(a, 0)):
						done = false
						break
				if done:
					pd["ready"] = true
					news.append({"kind": "youth",
						# EXACT EXE string, MANAGER.EXE @0x261ab8 — it carries an explicit
						# `\n` after "that". The port had flattened it to one line, and a
						# one-line box measures ~700px wide: it centres on (317,237), so
						# the OK button anchored at (w-6,h-6) landed OFF the 640x480
						# surface and the modal could never be dismissed (Mats QA
						# 2026-08-01: "goes outside of the screen so I cant press ok").
						"text": "Your youth manager has informed you that\n%s is ready to be promoted to the first team squad."
							% pd.get("name", "?")})
				# The shared block, cap[*] = 0. Same mini() clamp as CORE4 above.
				for a in TRAINABLE:
					var m := mini(int(attrs.get(a, 0)) + gain, int(base.get(a, 0)))
					if m > int(attrs.get(a, 0)):
						attrs[a] = ATTR_MAX if m > ATTR_SNAP else m
		pd["fitness"] = clampi(int(pd.get("fitness", COND_CAP)) + 1, COND_FLOOR, COND_CAP)
	return news


## Training points for one skill = that coach's `FUN_00578b80` capacity (cases 0-5:
## q<3 -> 1, 3-4 -> 2, 5-6 -> 3, 7-8 -> 4, 9-10 -> 5); 0 with no coach hired. This used
## to be `floor(stars)`, which agrees with the table on whole stars (the 4+2=6 witness
## can't tell them apart) but is one short on every HALF star — a 3.5-star coach is
## quality byte 7, which the engine's ladder puts in the 4 band, not 3.
static func skill_tp(staff: Array, skill: String) -> int:
	return Staff.capacity_of(Staff.member_in_role(staff, skill))


## TOTAL TRAINABLE PLAYERS = the sum of every hired skill coach's TP (witnessed 4+2=6).
static func total_trainable(staff: Array) -> int:
	var n := 0
	for sk in FOCUS_SKILLS:
		n += skill_tp(staff, sk)
	return n


## How many players are already assigned to `skill` in the focus map.
static func skill_load(focus: Dictionary, skill: String) -> int:
	var n := 0
	for pid in focus:
		if str(focus[pid]) == skill:
			n += 1
	return n


## How well `p` suits `skill` for the AUTO fill: keepers own HANDLING, outfielders are
## ranked by the attribute the skill trains. A negative/zero score means "never AUTO him
## onto this coach" (witnessed: AUTO put the keepers on HANDLING and forwards on
## SHOOTING, never the reverse).
static func focus_fit(p: Dictionary, skill: String) -> float:
	var gk := bool(p.get("isGK", false))
	if skill == "HANDLING":
		return float(int((p.get("attrs", {}) as Dictionary).get("PO", 0))) if gk else 0.0
	if gk:
		return 0.0            # outfield skills never AUTO onto a keeper
	var key := str(FOCUS_ATTR.get(skill, ""))
	if key == "":
		return 0.0
	var v := float(int((p.get("attrs", {}) as Dictionary).get(key, 0)))
	# SHOOTING leans on forwards, TACKLING on defenders — the witnessed AUTO shape.
	var pos := str(p.get("pos", ""))
	if skill == "SHOOTING" and pos == "FW":
		v += 20.0
	elif skill == "TACKLING" and pos == "DF":
		v += 20.0
	elif skill == "PASSING" and pos == "MF":
		v += 20.0
	return v
