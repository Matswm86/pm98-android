# The channelTV fee — the PRODUCER, found, and the whole table read out of MANAGER.EXE

Status: **CLOSED 2026-07-28 (s78).** Every competition's fee is now a read constant, and
the two DOMESTIC cups are a **proved null result**, not a gap.

Evidence: `extracted/Premier Manager 98/MANAGER.EXE`, `tools/re/scan_alias_writes.py`,
`tools/re/dump_tv_fee_table.py`. Supersedes `finance_screen_re.md`
§"What is still not found".

## 1. Why the old search failed, and what replaced it

`finance_screen_re.md` recorded the field's whole lifetime (raised, read, cleared, booked,
saved) but not its PRODUCER, and concluded:

> There is no `mov [reg+0x290], <value>` anywhere in `.text` outside the three sites above
> … so the producer must reach the field through an aliased base pointer.

**That conclusion was wrong, and the scan that produced it was the thing at fault.** There
IS a `mov [reg+0x290], <imm32>` producer — twenty-four of them. The earlier scan was a
*linear* byte/disassembly sweep, and `MANAGER.EXE` has data interleaved in `.text`, so a
linear sweep desynchronises and silently walks past whole functions. Re-running the same
displacement search **per function entry** (start each decode at a call target, never at an
arbitrary byte) finds 80 `disp == 0x290` operands where the old sweep reported 40.

Two tools came out of this and both stay:

* `tools/re/scan_alias_writes.py` — the search the old note asked for: a forward,
  intra-procedural abstract interpretation that tracks `(root, offset)` per register and
  reports writes landing on `root + 0x290` through `lea` / `add` chains. It is the search
  that WOULD have been needed had the aliased-base theory been right. Run against `0x290`
  it finds **no real aliased producer** (its only three hits are inside a CRT string
  routine, a linear-sweep artefact) — so the aliased-base theory is not merely unproven,
  it is refuted.
* Decoding per function entry, which is now the house rule for any `.text` scan here.

## 2. The producer — one per competition class, and the fee is an immediate

`club+0x290` is written by the competition object that owns the fixture, at the moment the
fixture is scheduled. Every writer has the same two guards:

```
cmp dword ptr [club+0x5c], 0xffff    ; the club must be the HOT SEAT (a managed club)
je  skip                             ; an AI club is never paid a TV fee
mov dword ptr [club+0x290], <fee>
```

and the one-off finals write it for **both** clubs, since either may be the manager's.

### The LEAGUE — `FUN_00417240`, and the shared arm is real

`FUN_00417240` is the league's own televised-match selector. Its four callers are exactly
the four English division classes (`0x41108d` FIRST, `0x41cbd3` PREMI, `0x425a5d` SECON,
`0x42f0ad` THIRD), and the fee is a jump table on `DAT_0066b1dc`, the index of the
competition currently being processed:

```
0x417457  mov eax, [0x66b1dc]
0x41745c  cmp eax, 3
0x41745f  ja  0x41748c                  ; default arm
0x417461  jmp dword ptr [eax*4 + 0x417570]
```

Jump table at `0x417570` = `[0x417468, 0x417474, 0x417480, 0x417480]` — **indices 2 and 3
share one arm**, which is the shape `finance_screen_re.md` guessed from the driven careers
and can now be stated as read, not inferred.

| idx | arm | immediate | internal | £ |
|---|---|---|---|---|
| 0 Premier | `0x417468` | `0x112a880` | 18,000,000 | **90,000** |
| 1 First | `0x417474` | `0x895440` | 9,000,000 | **45,000** |
| 2 Second | `0x417480` | `0x6acfc0` | 7,000,000 | **35,000** |
| 3 Third | `0x417480` (same) | `0x6acfc0` | 7,000,000 | **35,000** |
| default | `0x41748c` | `0x989680` | 10,000,000 | 50,000 — **unreachable**, see below |

All four match the driven-career captures exactly (`tools/re/refs/lowdiv-2026-07-28/`).

The default arm is dead code for this build: the only four callers are the four leagues and
each runs with its own index 0..3. It is recorded because it is in the image, and it is NOT
ported — nothing in the game reaches it.

### The CUPS — one writer per class

The competition classes are identified by their own save-file templates
(`%c:ACTLIGA\<TAG>%03u.CPT`), which sit inside each class's code block:

| tag | competition | writer sites | immediate | internal | £ |
|---|---|---|---|---|---|
| `CEURO` | European Cup | `0x454cfd` `0x45514e` `0x45532b` `0x455340` | `0x47868c0` | 75,000,000 | **375,000** |
| `CUEFA` | U.E.F.A. Cup | `0x45c8e8` `0x45cabc` `0x45cc90` `0x45ce6c` `0x45d05d` `0x45d21b` `0x45d230` | `0x47868c0` | 75,000,000 | **375,000** |
| `RECOP` | Cup Winners' Cup | `0x461f77` `0x4621a4` `0x4623d1` `0x4625fe` `0x46293f` `0x462952` | `0x47868c0` | 75,000,000 | **375,000** |
| `SCEUR` | European Supercup | `0x463dc0` `0x463de6` `0x463ee4` `0x463f06` | `0x47868c0` | 75,000,000 | **375,000** |
| `CHARI` | Charity Shield | `0x405b18` `0x405b23` | `0x23c3460` | 37,500,000 | **187,500** |
| `INTER` | Intercontinental Cup | `0x43275d` `0x432768` | `0x23c3460` | 37,500,000 | **187,500** |
| `FACUP` | F.A. Cup | **none** | — | — | **0** |
| `CCCUP` | Coca-Cola Cup | **none** | — | — | **0** |

Money is the engine's own unit throughout: **200 internal = £1** (`transfer_value_re.md`
§10), so every internal figure above divides exactly. The two witnessed cards that the port
could not previously source both fall out of this table: `p0032_channel_tv.png` £187,500 is
the Charity Shield and `p0138_channel_tv.png` £375,000 is the European Cup.

## 3. ⭐ The F.A. Cup and the Coca-Cola Cup pay NOTHING — and that is a RESULT

Five driven careers went looking for a domestic-cup channelTV card and never saw one. They
never saw one because **the game never raises one**: neither the `FACUP` class block
(`0x406000..0x410000`, anchored by its template refs at `0x407353` / `0x408af1`) nor the
`CCCUP` block (`0x401000..0x405000`, refs at `0x402203` / `0x4034c1`) contains a single
write to `club+0x290`, by displacement or through any `lea`/`add` alias chain.

So the port's long-standing "cup ties pay £0 and say so" was **already correct**, and it
stops being a flagged gap: it is the original's own behaviour, read out of the image. A
sixth wine drive would have found nothing, and is not needed.

## 4. The selection — which home match gets televised

Read from `FUN_00417240` for the league. Ported figures only where they are unambiguous;
the parts that are recorded but NOT ported are named at the end.

```
0x41734c  cmp [club+0x5c], 0xffff     ; managed club only
0x417359  cmp [club+0x228], 0xa       ; at most TEN televised matches per club per season
0x417369  cmp di, [fixture+0x44]      ; the club must be the HOME side
; --- forced: the derby table ---
0x417374..0x4173e2                    ; club-id pairs 0x12e/0x12f/0x131/0x133, either way round
0x4173e4  mov edi, 1                  ; a derby is ALWAYS televised
; --- otherwise: a roll, and only after round 5 ---
0x4173f3  call [comp+0x150] ; cmp eax, 5 ; jle skip
0x417409  rand(); ebx = ((rand*10)>>15) - fixture[+0x6c] + 0x65
0x417430  rand(); televised = ((rand*ebx)>>15) < 10
0x417457  <the fee jump table above>
0x41749b  [comp+0x68] = 1             ; mark the fixture televised
```

`club+0x228` is the season's televised-match COUNT — the same field the weekly pass
increments at `0x57ab50` when it books the fee, with `club+0x22c` taking the week
(`0x57ab5b`). The ten-match ceiling is therefore enforced by the producer, not the consumer.

**Recorded, not ported:** the derby table's club ids (`0x12e`, `0x12f`, `0x131`, `0x133`)
are raw EQUIPOS ids and are not yet bound to club names here; `fixture+0x6c` (which biases
the roll) is not yet named; and `[comp+0x150]` returning "the round number" is the natural
reading of the `> 5` gate but is not separately witnessed. The port keeps its own witnessed
"every home fixture is televised" behaviour rather than half-implementing the roll. That is
a declared divergence, and it is the one thing on this page that is not source-exact.

## 5. What the port does with it

* `FinanceModel.TV_FEE_INTERNAL` — the raw engine-unit constants, keyed by competition.
* `FinanceModel.TV_FEE` — the same table in £, derived by `/ MONEY_PER_POUND` (200) at
  parse time, so the £ figures cannot drift from the immediates.
* `FinanceModel.tv_fee()` — the reader; `"fa_cup"` and `"coca_cola"` return 0 **because the
  binary writes nothing**, which the doc comment now states instead of "not measured".
* `Career._tv_key_for_cup()` maps the two domestic cups onto those proved-zero keys.
* Gate: `app/tests/test_channeltv_screen.gd` pins every row of the table, the ×200
  relation, the shared Second/Third arm and the two proved zeros.
