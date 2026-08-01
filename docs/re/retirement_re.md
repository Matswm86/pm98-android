# Retirement, the ageing intake, and the squad-size floor

Status: **SOLVED + BUILT 2026-07-27.** Every number below is read out of
`extracted/Premier Manager 98/MANAGER.EXE` with Ghidra (`tools/re/ghidra_scripts/
DecompileAt.java`) and `objdump -d -M intel -b pei-i386`. Nothing here is fitted,
witnessed-by-frame or guessed. Port: `app/scripts/Retirement.gd` +
`Career.advance_season`; gate `app/tests/test_retirement.gd` (20 asserts, in CI).

This closes **S8** ("no player ever retires; squads age without bound and a multi-season
career ages into a dead end", `docs/re/AUDIT_season_playthrough_2026-07-25.md`), which had
been parked as *"blocked on reversing `FUN_005865b0` / `FUN_005c1df0` / `FUN_00443180`"*.

## 0. The three "blocking" functions were the wrong lead

They came from `seasonend_flow_re.md` §"un-chased leftovers" and were never retirement:

| function | what it actually is |
|---|---|
| `FUN_005865b0` | a list teardown: walks `[p+4]`, `count` entries, frees each non-null |
| `FUN_005c1df0` | `SetCursor(*FUN_005e4590(arg))` — a mouse-cursor setter |
| `FUN_00443180` | a 45 KB UI dispatcher, unrelated |

The real entry point is found from the STRING, not from the season-end call list.
`%s, has retired and has left your club.` lives at **VA 0x663A58** (file 0x262058, `.data`
delta 0x401A00). It is not referenced by code directly — it sits in an 11-entry message
POINTER table at **0x662CD0..0x662CF8**, slot **[5] = 0x662CE4**, and that slot is read
once, from **0x58AD34**, i.e. inside `FUN_0058AC90`.

> Method note for the next session: resolve file→VA per SECTION.
> `.text` +0x400C00, `.rdata` +0x401200, `.data` +0x401A00. Using the `.data` delta on a
> `.text` hit sends you 0x800 bytes into the wrong function (it cost this session one
> round trip — 0x58bb34 instead of 0x58ad34).

## 1. The rollover pass — `FUN_0057A730`

Once per club, at the season rollover, walking the club's player list
(`club+0x24`, linked through `player+0x100`), and only when the season year has moved
past 1997 (`if (0x7cd < DAT_0066b18c)` at 0x57a8xx — so nothing happens in the first
season):

1. if the player has no attached record (`player+0x88 == 0`), re-value him:
   `FUN_00576cd0(club id, club+0x58, (VE+RE+AG+CA)/4, age, posFine+1)` — already ported as
   `OfferRecord` + `Contract.stamp_wage` (`docs/re/offer_record_re.md`);
2. `FUN_0058AC90(managed, squadCount, clubAvgAbility, wasRelegated)` decides his future.
   The caller keeps a RUNNING head count and decrements it whenever the callee returns 0;
3. afterwards `FUN_0058a7f0` resolves the club's pending moves and offers.

`param_4` is `FUN_0057a340(club)` = the mean of `(VE+RE+AG+CA)` over the whole squad.
`param_5` is set 1 when the club's new division index is worse than its old one, i.e. the
club was **relegated**. `param_2` is `club+0x5c != 0xffff`: 0xffff is the "no human
manager" sentinel — the same test at 0x573B0A picks the literal string `COMPUTER` for the
manager's name when it holds.

## 2. `FUN_0058AC90` — retire / release / keep

```
0x58acb7  FUN_00584340(player) >= 1                -> return 1   (still under contract)
0x58acce  player+0x6c != player+0x14               -> return 1   (already moving club)
0x58acd9  player+0x14 >= 0x26ae                    -> KEEP       (pseudo clubs, 9902+)
0x58ace3  DAT_00658a44 != 0                        -> skip to the release ladder
0x58acf2  age  = FUN_00584b50(player)
0x58acfb  need = FUN_0058b020(player)
0x58ad02  age < need                               -> release ladder, else RETIRE
```

* **`FUN_00584340` = contract years LEFT** — `player+0x85` plus the attached record's
  `+0xc` when that record's club equals `player+0x6c`. So **retirement only ever fires on
  a contract that has run out**; a 36-year-old with a year to run simply plays on.
* **`FUN_00584B50` = age in whole years.** `FUN_004ECCF0` differences two date structs
  (`u16 year @0`, `u8 day @2`, `u8 month @3`) with the usual not-had-his-birthday-yet
  correction. The player's birth date is at `player+0xfc`.
* **`FUN_0058B020` = the retirement age**:
  `(-(player+0x1c != 0) & 0xfffffffe) + 0x23`, i.e. **35** when `player+0x1c` is zero and
  **33** otherwise. `player+0x1c` is the POSITION BAND — `0 GK / 1 DF / 2 MF / 3 FW`, the
  byte `tools/re/equipos_parse.py` reads at that offset out of every EQUIPOS record.
  **Keepers retire at 35, everyone else at 33.**

### RETIRE (0x58AD08..0x58AD9C)

1. select the club and post `"%s, has retired and has left your club."` with `player+0x4`
   (his display name) — only when the club has a human manager;
2. `FUN_0058B030(player)` — the **rebirth**, §3;
3. build a fresh 0x1c contract record through `FUN_00576cd0` and attach it at
   `player+0x88` (`FUN_0058a7b0`). Its club id is the argument at 0x58AD8B =
   `player+0x14`, **the same club** — so at an unmanaged club the reborn man simply stays
   and the squad size is unchanged. At a MANAGED club 0x58AD9C overwrites it with
   **0x26de** (the FREE PLAYERS pool — the same id `equipos_parse.py` records as the
   squad-slot "validity exemption") and zeroes the record's fee, so your retiree's
   replacement enters the free-agent market rather than your squad;
4. return 0, so the caller's head count drops.

### RELEASE (0x58AE41..0x58AF35), when he is out of contract but too young to retire

```
0x58ae41  DAT_0066b1f4 != 0                             -> KEEP
0x58ae55  cmp ecx,0xd / jb                               -> KEEP   (squad count < 13)
0x58ae5e  relegated AND player+0x7c != 0                 -> LEAVES (relegation clause)
0x58aebd  player+0x86 != 0 AND +0x86 <= +0x87            -> KEEP   (matches-to-renew met)
0x58aecf  managed club                                   -> LEAVES
0x58aeda  cmp ecx,0x14 / jb                              -> KEEP   (unmanaged: squad < 20)
0x58aee3  (VE+RE+AG+CA)/4 >= club average                -> KEEP
0x58af13  squad < 26 AND (player+0xa7 >= 0x32 OR +0x23 > 5) -> KEEP
0x58af27  player+0x74 < DAT_00639038                     -> KEEP, else LEAVES
```

**The 13-man floor is the headline.** The count tested is the running one, taken BEFORE
the man in hand is removed, so a 13-man squad gives up exactly one and every release after
that is refused — the resting point is twelve. This is the rule the port did not have, and
its absence is what melted a career squad from 22 men to six inside one season (measured
2026-07-27, `app/tests/diag_bare_roster_probe.gd`: club 38 fell to 6-10 men on 15 of 40
career seeds; with the floor, 0 of 20).

The relegation-clause message is 0x662D80 -> 0x663254, verbatim including its typo:
`"%s, has left your team due to\nthe clause in his contract freeing himif your were relegated."`

### KEEP (0x58AF37..0x58AFE6)

The engine copies his freshly re-valued offer record (`player+0x6c`) onto a new 0x20
object with `rec+0x19 = rec+0x18` (LEFT := the generated TERM) and attaches it. In other
words a kept player's deal simply runs on for another `OfferRecord.seed_years(age)` years
at the re-valued wage. That is what `Career._renew_expiring` does.

## 3. `FUN_0058B030` — the rebirth (the ageing intake)

The retiring record is not freed. It is **recycled into a new man**, which is exactly why
the original's world does not run out of players:

| address | effect |
|---|---|
| 0x58b03a | `FUN_0058a7d0` — drop the attached offer record |
| 0x58b041 | `FUN_00584650` — drain the player's list at +0x90 |
| 0x58b04a | `FUN_00588620(player, 0)` — clear the flag at +0x98 (re-index side effect) |
| 0x58b04f | `lea ecx,[esi+0xfc]` … `FUN_004eccd0(birthdate, out, rand(3) + 0xa)` — **the birth YEAR is advanced by 10, 11 or 12**, day and month untouched, so he comes back 10-12 years younger |
| 0x58b06d | `+0x9c <- +0xaa`, `+0x9d <- +0xab`, `+0x9e <- +0xac`, `+0xa4 <- +0xb2` |
| 0x58b0b3 | a new long name into `player+0x8` (`FUN_0058da60`) |
| 0x58b0d4 | a new display name into `player+0x4` (`FUN_0058db80`) |
| 0x58b127 | `if (id < 25000) { unindex; id = DAT_0066c154++; re-index }` — a fresh unique id |

The live attribute block is `VE RE AG CA RM RG PA TI EN PO` at `+0x9c` and the shipped
BASE block repeats it at `+0xaa` (`club_tactics_re.md` L99), so the four restored bytes
are **VE, RE, AG and EN** — the athletic four that age erodes. CA/RM/RG/PA/TI/PO are
deliberately left alone: the reborn player keeps the record's skills.

Both names come from ONE draw: `FUN_0058D8D0` re-rolls an index until it differs from the
previous one and returns pool entry `[i]`; `FUN_0058DB60` then re-reads **the same index**.
The pool object at `0x66C198` is the game's own name tables — `DBDAT/NOMBRES.30` (148
forenames) + `DBDAT/APELLIDO.30` (327 surnames), already exported to
`app/data/name_pools.json` and already proven to be where staff hires draw from
(`docs/re/staff_re.md`). **Residual, declared:** which of the two transforms
(`FUN_0058d890`/`FUN_0058d910` vs `FUN_0058db40`/`FUN_0058d9e0`) yields the short name and
which the long one is not reversed; the port takes the shipped records' own convention —
display name = surname, legal name = `FORENAME SURNAME`.

## 4. The board, while we were in there — `FUN_0057EE50` and `FUN_00545FD0`

`FUN_0057EE50` is the weekly at-a-loss pass. On a week in the red it increments
`club+0x224`, posts .data 0x662D20 -> 0x6638B4 —

```
You have been running the club
at a loss for %u week%c now.
```

— where the `%c` is `(-(1 < n) & 0x53) + 0x20`, i.e. `'s'` above one week and a **space**
at one ("for 1 week  now."), and moves the manager's reputation by **-5**. A week back in
the black clears the counter and gives **+1**. Both are clamped to 0..1000.

`FUN_00545FD0` is the sacking screen, and it picks its message in this order:

| test | message |
|---|---|
| `cmp [club+0x224],3 / jbe` — **more than 3 loss weeks** | 0x662D24 -> "…terminate your contract as manager due to the disastrous financial management of the club." |
| `club+0x294 != 0` | 0x662D2C -> "…and have sacked you as manager of the club." |
| `cmp [club+0x28],0x10 / jae` — **squad under 16** | 0x662D30 -> "…due to bad management of your squad, which does not have the minimum number of players needed to play in any championship." |

So `LOSS_SACK_WEEKS = 4` — which the port had already guessed and flagged as OURS — is now
**measured**, and the third dismissal reason (a squad under sixteen) is new. All three
strings now reach the player verbatim; the port's invented one-liner is gone.

## 5. What the port does, and what it does not

Built:

* retirement at 35 (GK) / 33 (outfield), on contract expiry only, for EVERY club;
* the rebirth, with the exact 10-12-year rollback and the exact four restored attributes;
* your retiree lands in the free-agent pool, a rival's is reborn in place (so the rival
  population is conserved — measured at 441 unchanged over five seasons);
* the 13-man release floor, and the matches-to-renew clause finally firing;
* the sacking threshold + the squad-under-16 dismissal + the three verbatim messages.

Declared divergences, unchanged by this pass:

* the unmanaged-club release ladder (0x58AEDA..0x58AF35) is still the port's auto-renew
  simplification; only its retirement half is faithful. `player+0xa7`, `+0x23` and the
  float at `+0x74` are un-identified, and `DAT_00639038` is an unread float constant.
* ~~the relegation release clause (`player+0x7c`) is not wired~~ — **WIRED 2026-08-01,
  see §6 below.**
* `DAT_0066b1f4` and `DAT_00658a44` (the two globals that switch the whole pass off) are
  un-identified; the port behaves as if both are zero, which is the in-game path.
* the original raises the sacking SCREEN mid-season; the port still dismisses at the
  season review it already has.
* the trailing newline on the at-a-loss string is dropped — `PMAlert` sizes its box at
  `72 + 10*lines`, and no frame of that alert survives in the repo to settle whether the
  original draws the empty line.

## 6. The relegation release clause — "Free if relegated", CLOSED 2026-08-01

`Evidence:` `app/tests/test_relegation_clause.gd`, `app/scripts/Retirement.gd`,
`app/scripts/Career.gd`, `extracted/Premier Manager 98/MANAGER.EXE` @0x58ae5e.

The clause had been settled on the ART side since 2026-07-24 — offer record `rec+0x10`
(= `player+0x7c`), the first of the four PLAYER INFORMATION checkboxes, rendering at 0 px —
and carried ever since as "what it DOES on relegation is still not found". The earlier
search followed the OFFER-COMMIT path (`FUN_005889c0`) and found no consumer there, which
is true and is why the item stayed open: **the consumer is not on the commit path at all,
it is on the SEASON ROLLOVER.**

### 6.1 The one consumer, and why "one" is a measurement

`FUN_0058AC90` @0x58ae5e — rung 3 of the release ladder in §2:

```
0x58ae5e  mov eax,[esp+0x33c]      ; param_5: the club's new division index is worse
0x58ae65  test eax,eax / je        ; not relegated -> fall to the matches-to-renew rung
0x58ae69  mov eax,[esi+0x7c]       ; player+0x7c = rec+0x10 = "Free if relegated"
0x58ae6c  test eax,eax / je        ; no clause -> fall to the matches-to-renew rung
0x58ae70  mov byte [esi+0x84],0    ; record YEARS := 0
0x58ae77  mov byte [esi+0x85],0    ; record LEFT  := 0
0x58ae7e  mov ecx,[esi+4]          ; his display name
0x58ae81  mov edx,[0x662d80]       ; -> 0x663254, the format string
0x58ae8e  call [0x6233cc]          ; sprintf into a stack buffer
0x58ae99  mov cx,word [esi+0x14]   ; his club id
0x58aea3  call 0x585ee0            ; club lookup
0x58aeaa  call 0x5793d0            ; the club's news sink
0x58aeb6  call 0x57d2d0            ; post it
0x58aebb  jmp 0x58af3b             ; the LEAVES tail: return 0, head count drops
```

`FUN_0057d2d0` @0x57d2ee returns immediately unless `club+0x5c != 0xffff`, so the line is
raised only at a club with a human manager — the same sentinel the RETIRE arm uses, and
the caller needs no gate of its own.

**"The only consumer" is measured, not inferred from one function's absence.** A restarting
linear sweep of the whole `.text` (`tools/re/dispscan.py`'s `sweep_text`, which does not
truncate at the first data byte) finds **nine** `[reg+0x7c]` flag-test sites in the image:
this one, four word-sized `cmp word ptr [ecx+0x7c],0` on an unrelated class (0x410350,
0x41c1be, 0x425200, 0x42e9a0) and four C-runtime sites in 0x5e/0x5f. Everything else that
touches displacement `0x7c` in the screen code is the widget-rect quadruple
`+0x78/+0x7c/+0x80/+0x84`, which is a different struct. And because the record is also
reachable through a POINTER (`lea ecx,[esi+0x6c]`, where the clause is `rec+0x10`), the
same sweep was run on displacement `0x10` over 0x520000..0x5a0000: 23 flag-test sites, and
every one is a list-node/pointer test or a club-id compare against the 0x26ae/0x26de/0x26e4
sentinels. **No consumer reads the clause through a record pointer either.**

### 6.2 What it does, exactly

For a player at a club that has just gone DOWN a division, who has reached the release
ladder at all — i.e. his contract has RUN OUT (0x58acb7 returns 1 for anyone with a year
left), he is not already moving club, his club id is below 0x26ae, `DAT_0066b1f4` is 0 and
the squad still holds at least `SQUAD_FLOOR` men — the clause zeroes his record's YEARS and
LEFT, raises the binary's own line, and he LEAVES with a fresh offer record
(`FUN_0058A0C0` on the LEAVES tail), i.e. into the free-agent market.

So it is **not** an instant release on the day of relegation. It is a rung in the
CONTRACT-EXPIRY ladder that guarantees the release once the season turns over — and it sits
**before** the matches-to-renew rung (0x58aebd), so a man who has met his renewal clause and
also holds this one still walks.

The line is verbatim from `.data` 0x662d80 -> 0x663254, including the missing space in
"himif" and the "if your were" typo:

```
%s, has left your team due to
the clause in his contract freeing himif your were relegated.
```

### 6.3 The port

`Retirement.RELEGATION_CLAUSE_MSG` + `Retirement.released_by_relegation_clause`;
`Career._manager_relegated()` is `param_5` for the manager's own club, read from the FINAL
TABLE before `_pyramid_rollover` moves anybody (the last `PYRAMID_ZONES[tier].down` places,
and only where there is a tier below to fall into — the same test the rollover then acts on).

**One ordering defect closed on the way in.** The port's ladder tested matches-to-renew
BEFORE the 13-man floor; the binary tests the floor first (0x58ae55) and the renewal clause
last (0x58aebd). While both rungs KEPT the player the swap was harmless, but it stops being
harmless the moment a rung between them RELEASES — which is exactly rung 3. The port now
runs the binary's order.

Gate `app/tests/test_relegation_clause.gd` (in the CI list) drives two whole seasons and
pins four things: the clause man leaves iff the club went down; a man with the renewal
clause and no relegation clause always stays; the binary's own line is raised iff relegated;
and the rung order, by giving the clause man a MET renewal clause — which under the port's
old order would have kept him.

**Still declared:** the clause is wired for the MANAGER'S club only. The rival-club ladder
(0x58AEDA..0x58AF35) remains the port's auto-renew simplification, as recorded above, so a
relegated AI club does not shed its clause-holders. That is the same declared scope as the
rest of the unmanaged ladder, not a new gap.
