class_name Retirement
## PM98 season-rollover RETIREMENT + AGEING INTAKE — BINARY-EXACT (docs/re/retirement_re.md).
##
## S8 ("no player ever retires; squads age without bound") is closed here. Nothing in this
## file is invented: every constant and every branch is read out of MANAGER.EXE.
##
## The original's rollover pass is `FUN_0057a730` (once per club, walking the club's player
## list at club+0x24 through the +0x100 link). Per player it re-values the record
## (`FUN_00576cd0`, ported in OfferRecord/Contract) and then calls **`FUN_0058ac90`**, which
## decides retire / release / keep:
##
##   0x58acb7  FUN_00584340(player) = years LEFT (player+0x85 + the attached record's
##             +0xc when that record's club == player+0x6c). **>= 1 -> return 1**, i.e.
##             a player under contract is never touched: retirement only ever fires on a
##             contract that has run out.
##   0x58acce  player+0x6c != player+0x14 (already moving clubs) -> keep.
##   0x58acd9  club id >= 0x26ae (9902 STARS and up, the pseudo clubs) -> keep.
##   0x58acf2  age  = FUN_00584b50(player)  (whole years, birth date vs the game date)
##   0x58acfb  need = FUN_0058b020(player) = 0x23 - 2*(player+0x1c != 0)
##             player+0x1c is the POSITION BAND (0 GK / 1 DF / 2 MF / 3 FW,
##             tools/re/equipos_parse.py) -> **35 for a keeper, 33 for everyone else**.
##   0x58ad02  age < need -> fall through to the release ladder, else RETIRE.
##
## RETIRE (0x58ad08..0x58ad5b):
##   * the club's news gets `"%s, has retired and has left your club."` (the .data slot at
##     0x662ce4 -> 0x663a58) when the club has a human manager (club+0x5c != 0xffff, the
##     same test that prints "COMPUTER" for an unmanaged club at 0x573b0a);
##   * `FUN_0058b030(player)` REBIRTHS the record — see `rebirth()` below;
##   * a fresh 0x1c contract record is generated for him (`FUN_00576cd0`) and attached at
##     player+0x88. At an unmanaged club it carries the SAME club id, so the reborn man
##     stays and the squad size is unchanged; at a MANAGED club the id is overwritten with
##     0x26de = the FREE PLAYERS pool and the value floats are zeroed (0x58ad9c), so the
##     retiree's replacement enters the free-agent market instead of your squad.
##
## RELEASE, when he is out of contract but too young to retire (0x58ae41..0x58af35):
##   * `DAT_0066b1f4 != 0` -> keep;
##   * **squad size < 0xd (13) -> keep** — the original NEVER lets a squad be released
##     below thirteen. This is the floor the port was missing, and the reason a career
##     squad melted from 22 men to six inside one season;
##   * relegated (caller's arg5) AND player+0x7c set -> he leaves under the relegation
##     release clause, message 0x662d80 "…due to the clause in his contract freeing him
##     if your were relegated";
##   * player+0x86 != 0 AND player+0x86 <= player+0x87 -> keep: the MATCHES-TO-RENEW
##     clause (rec+0x1a, OfferRecord.MATCHES_TO_RENEW) has been reached, so the deal
##     renews itself;
##   * managed club -> he leaves on a free;
##   * unmanaged club -> he only leaves when the squad is >= 20 (0x14) AND his own
##     (VE+RE+AG+CA)/4 is below the club average (FUN_0057a340) AND (squad >= 26 or he is
##     low-morale / low-form) AND player+0x74 >= DAT_00639038.
##
## The port applies the retirement branch and the 13-man floor for every club, and keeps
## its own (declared) auto-renew simplification for the unmanaged clubs' release ladder.

# FUN_0058b020 @0x58b020: `(-(player+0x1c != 0) & 0xfffffffe) + 0x23`.
const RETIRE_AGE_GK := 35
const RETIRE_AGE_OUTFIELD := 33

# FUN_0058ac90 @0x58ae55: `cmp ecx,0xd / jb keep` on the club's RUNNING player count.
const SQUAD_FLOOR := 13

# FUN_0058b030 @0x58b04f: `FUN_0058df90(3) + 0xa` years added to the birth year.
const REBIRTH_YEARS_MIN := 10
const REBIRTH_YEARS_SPAN := 3

# FUN_0058b030 @0x58b06d: the four LIVE attribute bytes restored from the BASE block
# (+0x9c<-+0xaa, +0x9d<-+0xab, +0x9e<-+0xac, +0xa4<-+0xb2). The live block is
# VE RE AG CA RM RG PA TI EN PO at +0x9c and the shipped base block repeats it at +0xaa
# (docs/re/club_tactics_re.md L99), so these are VE, RE, AG and EN — the four that age
# erodes. CA/RM/RG/PA/TI/PO are deliberately NOT restored.
const REBIRTH_RESTORED := ["VE", "RE", "AG", "EN"]

# The news line, verbatim from .data 0x663a58 (the `%s` is the player's display name).
const RETIRED_MSG := "%s, has retired and has left your club."

# The RELEGATION RELEASE CLAUSE line, verbatim from .data 0x662d80 -> 0x663254 — including
# the missing space in "himif" and the "if your were" typo, both of which are in the
# shipped binary. The `%s` is the player's display name (player+0x4, pushed at 0x58ae7e).
const RELEGATION_CLAUSE_MSG := "%s, has left your team due to\nthe clause in his contract freeing himif your were relegated."


## FUN_0058ac90 @0x58ae5e — rung 3 of the release ladder, and the ONLY consumer of the
## "Free if relegated" clause in the whole image (proved 2026-08-01 by an exhaustive
## displacement scan: the nine `[reg+0x7c]` flag-test sites are this one plus four
## word-sized tests on an unrelated class and four C-runtime sites, and there is no
## record-pointer-relative `[reg+0x10]` flag test anywhere in 0x520000..0x5a0000).
##
##   0x58ae5e  mov eax,[esp+0x33c]      ; param_5 = the club went DOWN a division
##   0x58ae65  test eax,eax / je        ; not relegated -> next rung
##   0x58ae69  mov eax,[esi+0x7c]       ; player+0x7c = rec+0x10 = "Free if relegated"
##   0x58ae6c  test eax,eax / je        ; clause absent -> next rung
##   0x58ae70  mov byte [esi+0x84],0    ; record YEARS  := 0
##   0x58ae77  mov byte [esi+0x85],0    ; record LEFT   := 0
##   0x58ae7e..0x58aeb6                 ; sprintf 0x663254 and post it to the club's news
##                                      ; (FUN_0057d2d0 @0x57d2ee returns early unless
##                                      ;  club+0x5c != 0xffff, i.e. a human manager)
##   0x58aebb  jmp the LEAVES tail      ; returns 0, so the caller's head count drops and
##                                      ; FUN_0058a0c0 gives him a fresh offer record
##
## Note the GATES it inherits from the rungs above it: the man's contract must already have
## RUN OUT (0x58acb7 returns 1 for anyone with a year left), he must not already be moving
## club, and the squad must still hold >= SQUAD_FLOOR men (0x58ae55). So the clause is not
## an instant release on the day of relegation — it is a rung in the CONTRACT-EXPIRY ladder
## that guarantees the release once the season turns over, and it sits BEFORE the
## matches-to-renew rung (0x58aebd), so it beats a clause that would otherwise renew him.
static func released_by_relegation_clause(player: Dictionary, relegated: bool) -> bool:
	if not relegated:
		return false
	var clauses: Variant = player.get("clauses")
	if clauses is Array:
		return (clauses as Array).has(OfferRecord.CLAUSE_FREE_IF_RELEGATED)
	return false


## FUN_0058b020: the age at which THIS player retires.
static func retire_age(player: Dictionary) -> int:
	return RETIRE_AGE_GK if _is_gk(player) else RETIRE_AGE_OUTFIELD


## FUN_0058ac90 @0x58ad02, for a player whose contract has just run out.
static func retires(player: Dictionary) -> bool:
	return int(player.get("age", 0)) >= retire_age(player)


## FUN_0058b030: the retiring record is reborn as a NEW man in the same body — the engine
## reuses the record rather than freeing it, which is what keeps the world's player count
## constant. Mutates `player` in place and returns it.
##
##   * birth year += rand(0..2) + 10  (so he is 10..12 years younger; the day/month keep)
##   * VE/RE/AG/EN restored from the shipped base block
##   * a fresh name: the engine draws ONE entry from its name pool (FUN_0058d8d0, which
##     re-rolls while the index equals the previous one) and derives both the display name
##     (+0x4) and the long name (+0x8) from that single pick. The pool is the game's own
##     DBDAT/NOMBRES.30 + APELLIDO.30 (app/data/name_pools.json via Staff.name_pools(),
##     the tables staff hires were proven to draw from — docs/re/staff_re.md).
##   * a new player id from the caller's minter (FUN_0058b030 @0x58b127 assigns
##     `DAT_0066c154++` to any record whose id is below 25000 and re-indexes it)
##   * the attached offer record is dropped (FUN_0058a7d0) and re-generated
static func rebirth(player: Dictionary, rng: RandomNumberGenerator, new_id: int) -> Dictionary:
	var back := REBIRTH_YEARS_MIN + rng.randi_range(0, REBIRTH_YEARS_SPAN - 1)
	player["age"] = maxi(1, int(player.get("age", 0)) - back)
	if player.get("birthYear") != null:
		player["birthYear"] = int(player["birthYear"]) + back
	var live: Variant = player.get("attrs")
	var base: Variant = player.get("attrs_base")
	if live is Dictionary and base is Dictionary:
		for code in REBIRTH_RESTORED:
			if (base as Dictionary).has(code):
				(live as Dictionary)[code] = int((base as Dictionary)[code])
	var pools: Dictionary = Staff.name_pools()
	var fores: Array = pools.get("forenames", [])
	var surs: Array = pools.get("surnames", [])
	if not fores.is_empty() and not surs.is_empty():
		var fore := str(fores[rng.randi() % fores.size()])
		var sur := str(surs[rng.randi() % surs.size()])
		player["name"] = sur
		player["legalName"] = "%s %s" % [fore, sur.to_upper()]
	player["id"] = new_id
	# The record is a different man now: his career state is not his.
	player["squadNo"] = 0
	player["injured_weeks"] = 0
	player["suspended_weeks"] = 0
	player["yellows"] = 0
	player["dev_progress"] = 0.0
	player["reborn"] = true          # audit flag: this record was recycled by the engine
	player.erase("clause_apps")
	player.erase("clause_goals")
	player.erase("auto_renew")
	return player


## `true` when the position band is the keeper band (player+0x1c == 0).
static func _is_gk(player: Dictionary) -> bool:
	if player.get("isGK") != null:
		return bool(player["isGK"])
	return str(player.get("pos", "")) == "GK"
