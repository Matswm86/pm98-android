# THE FINES (MULTAS) — the card, the rule, and the eight "counterpart-less" screens

Status: **BUILT 2026-08-01 (s82).** Model `app/scripts/Fines.gd`, card `app/scenes/FinesScreen.gd`,
art `tools/re/build_fines_card_from_pkf.py` → `app/art/screens/fines/`, gate
`app/tests/test_fines.gd` (73 checks), render `app/tests/shot_fines.gd`.

Evidence: `MANAGER.EXE` (`FUN_0057a980`, `FUN_00549d40`, `FUN_00549fe0`, `FUN_00545fd0`,
`FUN_00448b60`, `FUN_00441ea0`) + `RECURSOS.PKF` folders MULTAS (17) and ESTADIO (10).
No frame of this card exists in the corpus — see §5 for what that means and what is declared.

---

## 1. What it is

The board fines the club when its GROUND is below the standard the competition it has just
played in demands. Five separate fines exist, one per facility, and the game states each in
its own sentence with its own icon:

> You have been fined £25,000 because you don´t have
> the floodlights needed to play
> in this competition.

The port had the FINES **expense line** in the finance screen since the ledger was reversed
(`FinanceModel.EXPENSE_LINES`) and nothing that ever wrote to it. This is the producer.

## 2. The levy — `FUN_0057a980` @0x57ab77..0x57ad6a

`FUN_0057a980` is the club's POST-MATCH pass. `FUN_00448b60` calls it on **both** clubs of a
finished fixture (@0x448dd8 / @0x448de3 / @0x448dea, picking the order off `club+0x5c`), so
the pass runs once per club per match — **home or away**.

```
57ab6c  mov eax,[esi+0x10]         ; this club's id
57ab6f  cmp edx,eax                ; vs the managed club (DAT_0066afd0+0x44)
57ab71  jne skip
57ab77  mov ecx,[esi+0x54]
57ab7a  mov eax,[esi+0x50]
57ab7d  cmp ecx,eax
57ab7f  jbe skip                   ; proceed only while club+0x54 > club+0x50
57ab85  mov eax,ds:0x66b1dc        ; the competition being processed
57ab8a  test eax,eax / jne ...     ; 0 -> PREMIER arm
57ac52  cmp eax,4  / jne ...       ; 4 -> F.A. CUP arm
57ac8b  cmp eax,7  / jb  skip
57ac94  cmp eax,0xb / ja skip      ; 7..11 -> the shared EUROPE arm
```

Each test inside an arm is the same shape: read the ground record `club+0x1e0`, compare one
grade byte, and on a shortfall push a **float32 immediate** to `FUN_00581240` (the debit),
call `FUN_00580b90(<bit>)` and store the same amount in the club's own accumulator.

| arm | grade byte | item | test | debit / banked | £ |
|---|---|---|---|---|---|
| PREMIER (idx 0) | `ground+0x29` | floodlights | `< 2` | `0x4A989680` / `0x4C4B40` | 25,000 |
| | `ground+0x2b` | changing rooms | `< 1` | 5,000,000 | 25,000 |
| | `ground+0x2c` | score board | `< 1` | 5,000,000 | 25,000 |
| | `ground+0x2d` | access | `< 1` | 10,000,000 | 50,000 |
| | `ground+0x2e` | medical equipment | `< 1` | 10,000,000 | 50,000 |
| F.A. CUP (idx 4) | `ground+0x29` | floodlights | `< 1` | `0x4A371B00` / `0x2DC6C0` | 15,000 |
| EUROPE (idx 7..11) | `ground+0x29` | floodlights | `< 2` | 10,000,000 | 50,000 |
| | `ground+0x2b` | changing rooms | `< 1` | 10,000,000 | 50,000 |
| | `ground+0x2c` | score board | `< 1` | 10,000,000 | 50,000 |
| | `ground+0x2d` | access | `< 1` | 15,000,000 | 75,000 |
| | `ground+0x2e` | medical equipment | `< 1` | 15,000,000 | 75,000 |

The float32 immediate and the banked integer are the same number (`0x4A989680` is
`5000000.0f`, `0x4B189680` is `1e7f`, `0x4A371B00` is `3e6f`, `0x4B64E1C0` is `1.5e7f`), and
the £ column is that number over `FinanceModel.MONEY_PER_POUND` = 200. Nothing here is tuned.

**The five grade bytes are the ones the port already decodes.** `ground+0x29..0x31` is
`GroundPreset`'s nine-item vector in the ledger's own order, so `+0x29` / `+0x2b` / `+0x2c` /
`+0x2d` are FLOODLIGHTS / CHANGING ROOMS / SCORE BOARD / ACCESS in FACILITIES and `+0x2e` is
MEDICAL EQUIPMENT, the first of SERVICES (`stadium_screen_re.md`).

**What is NOT fined is a result, not an omission.** Indices 1, 2, 3 (First / Second / Third
Division), 5 (Coca-Cola Cup) and 6 (Charity Shield) fall outside `{0} ∪ {4} ∪ {7..11}` and
reach the function's exit without touching a single accumulator.

### The competition index

`DAT_0066b1dc` is the index of the competition being processed. `FUN_00441ea0` builds the
14-entry table `DAT_0066b190[]` and passes each class ctor **its own index**; matching those
ctors to the class code block that owns the class's `%c:ACTLIGA\<TAG>%03u.CPT` template
gives the whole map:

| idx | ctor | class | idx | ctor | class |
|---|---|---|---|---|---|
| 0 | `FUN_0041c0c0` | PREMI | 6 | `FUN_00404af0` | CHARI |
| 1 | `FUN_00410210` | FIRST | 7 | `FUN_00457ac0` | CUEFA |
| 2 | `FUN_004250c0` | SECON | 8 | `FUN_0045dfb0` | RECOP |
| 3 | `FUN_0042e880` | THIRD | 9 | `FUN_00451b30` | CEURO |
| 4 | `FUN_00406d00` | FACUP | 10 | `FUN_004631a0` | SCEUR |
| 5 | `FUN_00401da0` | CCCUP | 11 | `FUN_00431b30` | INTER |

Two independent confirmations of the two cup rows: the FACUP ctor allocates **8** round
slots (`FUN_00605ee0(this+0x1d, 8, 8, ...)`) and the CCCUP ctor **7** — exactly the ladder
lengths `docs/REMAINING.md` §0aaaaaaaaaaaaa.8 had to pin the cup calendar against.

## 3. The card — `FUN_00549d40`, raised by the weekly hub run

`FUN_00545fd0` (the weekly hub `run()`, the same function that raises the three board
dismissals) tests the five accumulators before it draws the menu:

```
if (club+0x27c + club+0x280 + club+0x284 + club+0x288 + club+0x28c != 0)
    FUN_00549d40(hub, club)          @0x546164     <-- the FINES card
if (club+0x290 != 0)
    FUN_005724e0(hub, club+0x290)    @0x546226     <-- the channelTV card
```

so the fines card comes **before** the channelTV card, which is the order the port's
post-week chain now uses. `FUN_00549d40` draws each non-zero field in field order and clears
it, advancing its row cursor only on a drawn row.

Geometry, all `CRect(origin, size)` where `FUN_00436fb0(x, y)` is the point and
`FUN_00436fd0(origin, size)` the rect (the convention `ChannelTvScreen`'s witnessed plate
already confirms):

| thing | origin | size | site |
|---|---|---|---|
| panel | (111, 82) | 418 x 316 | @0x549e02 / @0x549e0d |
| MULTA sprite | panel + (12, 6) | 54 x 58 | the empty-string rect it fills |
| row icon | panel + (19, y) | 40 x 26 | @0x54a090 / @0x54a0a6 |
| row text | panel + (71, y − 8) | 345 x 42 | in `FUN_00549fe0` |
| OK caption | panel + (336, 284) | 74 x 25 | @0x549f03 / @0x549f0d |

`y` = 0x4e (78) for the first drawn row, +0x2c (44) per row after it: **78, 122, 166, 210,
254**. Title font `ProMan14` (@0x549e9b), row font `ProMan8`, OK ink `(255,223,0)`
(`FUN_00437020(0xff,0xdf,0)` @0x549ef6), row ink white (`FUN_00436270(0xffffff)`).

## 4. The art needs no bake

Every pixel this card draws is a whole entry in `RECURSOS.PKF`, blitted at a literal
coordinate — so unlike every other screen in this port it is exported 1:1 rather than cut
out of a frame. Names alone are ambiguous (RECURSOS holds seven `FONDO.BMP`s), so the
extractor keys on the type-2 record's third u32, which is the **folder id**:

| folder | entry | size | is |
|---|---|---|---|
| MULTAS (17) | `FONDO.BMP` | **418 x 316** | the panel — a floodlit night ground |
| MULTAS (17) | `MULTA.GIF` | **54 x 58** | the fine ticket, top-left |
| ESTADIO (10) | `EQUIPAM_0.BMP` | **40 x 26** | floodlights |
| ESTADIO (10) | `EQUIPAM_2.BMP` | 40 x 26 | changing rooms |
| ESTADIO (10) | `EQUIPAM_3.BMP` | 40 x 26 | score board |
| ESTADIO (10) | `EQUIPAM_4.BMP` | 40 x 26 | access |
| ESTADIO (10) | `EXTRAS_0.BMP` | 40 x 26 | medical equipment |

**The three bold sizes are the cross-check.** 418 x 316 is the panel CRect in
`FUN_00549d40`; 40 x 26 is the icon CRect in `FUN_00549fe0`; 54 x 58 is the empty-string
CRect the MULTA sprite is blitted into. The archive and the disassembly agree three times
without either being consulted for the other. `test_fines.gd` asserts all three.

## 5. Declared, because there is no witness frame

Five driven careers never raised this card, and now it is clear why: Man Utd's ground
(GroundPreset 0 = FLOODLIGHTS 2 / CHANGING ROOMS 1 / SCORE BOARD 2 / ACCESS 1 / MEDICAL 1)
clears **every** threshold in **every** arm. So:

* **The OK plate's HIT rect** is the binary's own text rect grown by 2 px, the same border
  `ChannelTvScreen`'s measured plate sits outside its own text rect. Declared, not measured.
* **The outer gate `club+0x54 > club+0x50` is NOT reversed.** `club+0x50` is the club's
  competition index (the byte `FUN_0057d780` reads for the ground preset); `club+0x54` is
  simply the next byte the record reader stores (`FUN_0057bfb0` @0x57c18d, four consecutive
  bytes into +0x4c/+0x50/+0x54/+0x58, and +0x58 is the stature band the port already models).
  The port applies each arm whenever the manager's club actually plays in that competition,
  which is the block's behaviour with that gate open. Stated here rather than guessed at.
* The row **line spacing** (11 px inside the 42 px text rect) is the port's own layout of the
  binary's three-line string inside the binary's own rect.

Everything else on this card is a literal.

---

## 6. The other seven "counterpart-less" screens — resolved from source

`APP_VS_SPEC_AUDIT.md` §B2 carried eight original screens as having no app counterpart:
**MULTAS, SECRETARIO, TV, HIGHLIGHTS, CREDITOS, SELECCIONPRO, SININFO** and the group-phase
half of **EMPAREJAMIENTOS**. That list was built from RECURSOS.PKF **folder names**, and six
of those folders are not screens at all — they are art groups belonging to screens this port
already ships. Each row below is the function that references the folder's own files.

| folder | who loads it | verdict |
|---|---|---|
| **MULTAS** | `FUN_00549d40` ← hub run @0x546164 | a real screen — **BUILT this session** |
| **TV** | `FUN_005724e0` ← hub run @0x546226 | the channelTV card — **already built** (`ChannelTvScreen`, s78) |
| **EMPAREJAMIENTOS** | `FUN_0050e980` | **MAN-TO-MAN MARKINGS** (`mantoman_screen_re.md` names this exact function). "emparejamientos" is *markings*, not the cup draw; the cup draw is `CupDrawScreen`, a different screen from a different frame set. **Built, 0 px both careers (s78).** |
| **SININFO** | `FUN_00545180` | the **TITLE SCREEN**'s own art group (`title_screen_re.md` §"button bitmaps live in the SININFO PKF group"). **Built.** |
| **SECRETARIO** | `FUN_00554880` and `FUN_0053cce0` | the SEARCH button art (`botonon`/`botonoff`/`buscar.bmp`) of two search panels: `FUN_00554880` belongs to the **SCOUT** screen (`FUN_00555ea0`, strings `SCOUT` / `PLAYERS FOUND` / `INFOFUT\if5masec.htm`) and `FUN_0053cce0` to the **YOUTH** screen (`FUN_0053d710`, `INFOFUT\if5majuv.htm`). **Both built** — `ScoutScreen` (binary-exact criteria) and `YouthScreen` (five parity shots at 0 px, s80). |
| **SELECCIONPRO** | `FUN_00561569` | the **OFFERS SELECTION** screen's two arrows + info plate (string `OFFERS SELECTION`, `INFOFUT\if5proma.htm` / `if5profe.htm`). **Built** — `OffersSelectionScreen`, gated by `diff_offers_selection_parity.py`. |
| **CREDITOS** | **nobody** | 10 entries, all Spanish captions (`AGRADECIMIENTOS`, `DISENO_GRAFICO`, `PRODUCCION`, `PROGRAMACION`, `GRAFICOS`) — the PC Fútbol 5 credits roll. **Zero references in `MANAGER.EXE` and zero in `Dbasewin.exe`**, searched case-insensitively over the whole image. Dead inherited content: Premier Manager 98 has no credits screen, and building one would be inventing a screen the game does not have. |
| **HIGHLIGHTS** | `FUN_005381c0` family + `img\opciones\ico_highlights.bmp` | 5 entries, and they are the **viewer's buttons** (`KICKOFF.GIF`, `REPLAY.GIF`, `FLECHA.BMP`) — the content is 3D replay. Unchanged **hard DATA gap**: `SOURCE_INVENTORY.md` §1 verified 0 `.p3d` / `Modelos\` hits on both sources. |

So the honest count is: **one real screen was missing, and it is built.** Five were art
groups of screens already at 0 px, one is dead PC Fútbol 5 inheritance, one is a data gap
that no amount of work here can close.

## 7. The European entry alert — raised, and one figure corrected

`REFRUN_manutd_1997-98_FINDINGS.md` carried "the alert itself (`p0110`) is a screen the port
does not raise — it credits `EURO_ENTRY` silently". It raises them now, with the binary's own
strings. There are exactly **four** `"from UEFA"` strings in the image, and all four sit
inside the CEURO (European Cup) class block, bracketed by `'European Cup'` @0x6534d8 and
`'%c:ACTLIGA\CEURO%03u.CPT'` @0x6534f4:

| VA | string | port |
|---|---|---|
| 0x653518 | `£1 million ... for competing in this championship` | `EURO_ENTRY` |
| 0x6535c4 | `£1.5 million ... qualification\nto the quarter finals` | `EURO_QF` |
| 0x653630 | `£1.625 million ... qualification\nto the semifinals` | `EURO_SF` |
| 0x65369c | `£2 million ... qualification\nto the final` | **`EURO_FINAL`** |

**The correction:** the port paid the £2,000,000 as `EURO_WINNER`, on lifting the trophy —
the one rung in that ladder placed by inference rather than by its text. Its string says
*qualification to the final*, so it is now the milestone for winning the semifinal
(`survivors == 2`), and there is no reversed trophy-lift bonus at all.

**Declared:** the alerts are raised for the **European Cup only**, because that is the class
block the four strings live in. Whether the U.E.F.A. Cup and the Cup Winners' Cup raise an
equivalent is not established, and an invented one would be worse than the gap. The PRIZE
money for those two competitions is unchanged pending a proper per-function scan of the
CUEFA / RECOP blocks for the credit call — the same scan discipline `channeltv_fee_re.md`
had to adopt, and the reason its first answer was wrong.
