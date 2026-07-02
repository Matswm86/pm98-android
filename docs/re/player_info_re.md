# PLAYER INFORMATION (FICHA) decode — EQUIPOS.PKF + MANAGER.EXE

The centred white card the magnifying-glass opens over the LINE-UP / SQUAD (reference:
`screens/player_info_ref.jpg`). Renderer = `FUN_0052e0d0` (label layout) reading the player
struct at `*(screen+0x54)`. Reversed 2026-06-26 with Ghidra (`tools/re/ghidra_scripts/
DecompileAt.java` against `~/ghidra-projects/pm98`) + capstone. Ported to
`app/scenes/PlayerInfoScreen.gd`.

## Physical stats — stored METRIC, two bytes after the birth-year anchor

The EXTENDED English record (see `extract_english.py`) carries, right after the u16
birth-year anchor `Y`:

| offset | field        | unit | example (Schmeichel) |
|--------|--------------|------|----------------------|
| `Y`    | birth year   | u16  | 1963                 |
| `Y+2`  | **height**   | cm   | 193                  |
| `Y+3`  | **weight**   | kg   | 101                  |

`Y+2` is the byte an earlier pass mislabelled a "flag >=0x80" — an adult height in cm is
always >=150 (`0x96`), so it doubled as the anchor filter. Validated across 1950 players:
mean 180.9 cm / 75.2 kg, and exact real heights for Giggs 180, Owen 173, Schmeichel/Seaman
193, Beckham 183.

### Why imperial pairs were never found in the file
The FICHA shows weight as `stone pounds` and height as `feet inches`, but PM98 stores
**metric** and converts at render time (`FUN_0058dd70` weight, `FUN_0058de00` height):

```
stone  = floor(kg / 6.35)            # 6.35029 kg per stone   (const 0x639048 = 1/6.35)
pounds = floor((kg - stone*6.35) * 2.2046)        # 0x639050=6.35, 0x639058=14/6.35
feet   = floor(cm / 30.48)           # 30.48 cm per foot      (const 0x639060 = 1/30.48)
inches = floor((cm - feet*30.48) * 0.3937)        # 0x639068=30.48, 0x639070=1/2.54
```

Confirmed against the Bakayoko reference: 75 kg -> "11 11", 178 cm -> "5 10". In memory the
management player struct holds height at `player+0xf9` (cm) and weight at `player+0xfa`
(kg); the FICHA reads `[ebp+0xf9]`/`[ebp+0xfa]` at `0x52e906`/`0x52e881`.

**We show metric directly** (`193 cm` / `101 kg`) — the native stored unit — rather than the
original's imperial conversion (user call 2026-06-26).

## Nationality — explicit string for foreigners, ENGLAND default

The record stores three length-prefixed cipher strings after the physicals: birthplace,
previous club, **nationality**. English players OMIT the nationality field (it defaults to
the league nation), so the decode reads the 3rd string and accepts it only when it is a
known country (`COUNTRIES` whitelist in `extract_english.py`); otherwise -> `ENGLAND`. The
home nations (WALES / SCOTLAND / EIRE / NORTHERN IRELAND) ARE tagged. Verified: Schmeichel
DENMARK, Berg NORWAY, Van der Gouw HOLLAND. `kind` (the FICHA NATIONAL / NON-NATIONAL flag)
derives from nationality: English/British -> NATIONAL, else NON-NATIONAL.

## Card-label -> attribute mapping (confirmed vs the Babb reference)

`SPEED=VE STAMINA=RE AGGRESSION=AG QUALITY=CA` · `HANDLING=PO PASSING=PA DRIBBLING=RM
HEADING=RG TACKLING=EN SHOOTING=TI` · `RATING` = the squad-AV (mean of the 8 outfield
attrs) · `FITNESS / MORAL` = dynamic form (not static attrs; defaulted match-fit/settled
for a freshly loaded squad).

The **header subtitle** (under the name) uses the broad 4-entry role LUT
(`PTR_s_GOALKEEPER_00662d10` -> GOALKEEPER/DEFENDER/MIDFIELDER/FORWARD). The **ROLE band**,
however, shows the FINE position name: the renderer at `0x52ea9e` reads the in-memory fine
byte `player+0x18` and indexes the **SHORT fine-name table at `0x662df8`** (`mov dl,[ebp+0x18]`
/ `mov edx,[edx*4 + 0x662df8]`). The reference confirms it -- Bakayoko's subtitle is "FORWARD"
(broad) while his ROLE band reads "CENTRE FORWARD" (fine). See positions_re.md for the full
18-entry table and the posFine mapping. (An earlier pass mislabelled the ROLE band as using
the broad LUT -- corrected 2026-06-26.)

## Open
- International (compact-record) clubs carry neither photoId nor these physicals yet.
  **Verified 2026-06-26 why (not a TODO, a data-availability finding):** the compact
  Spanish/continental EQUIPOS record is `[u16 year][flag][media][10 attrs u8][01]` — it has
  **no physical bytes at all** (height/weight live only in the EXTENDED English layout at
  `Y+2/Y+3`), and **no per-player nationality byte**. Empirically (Barcelona dump): the `flag`
  byte at `Y+2` ranges `0xa9..0xc2` and tracks the player's rating, not a country (it gates
  the `media` byte's presence, `>=0xa0`); `media` (`Y+3`, 56-99, Spanish for "average") is a
  rating field, **not** a face key (J96 photoIds run in the thousands, so a 56-99 byte cannot
  index the 1302-face bank). So `flagCode` for every compact player is just the
  `flag_for(None)`=`ENGLAND_CODE` fallback in `build_db.py` (cosmetically wrong: shows the
  English flag for foreign clubs). The original game DOES display foreign nationalities, so
  they must be stored in a **separate** DBDAT structure (candidate join: `PAISES.30` country
  list + a parallel per-player nationality index, or `NOMBRES.30`/`APELLIDO.30` name
  dictionaries) — a NEW RE track, not recoverable from the per-player EQUIPOS bytes.

## Done
- The fine role-NAME LUT IS located (2026-06-26): SHORT table `0x662df8` / LONG `0x662db0`,
  18 entries indexed by `posFine-1`. The FICHA ROLE band now renders the fine name
  (`FINE_ROLE` in `PlayerInfoScreen.gd`); verified vs the Bakayoko reference. See positions_re.md.
- Nationality FLAG art (`DBDAT/BANDERAS.PKF`) extracted (2026-06-26): the real waving flag
  now blits left of the country name on the FICHA. See `tools/re/export_flags.py`.
- **Action button row (2026-07-02).** When opened from SQUAD MANAGEMENT for your OWN player,
  the card carries **RENEW / TRANSFER / SACK / OK** (builder `FUN_00526a60`; decompile in
  `docs/re/playerinfo/`). Card-local rects (push-tracked disasm): RENEW `(85,325) 104x25`,
  TRANSFER `(196,325) 104x25`, SACK `(307,325) 104x25`, OK `(429,325) 52x25` — three equal
  action buttons + a narrow OK. Wired to `Career.renew` / `toggle_listed` / `release`
  (PlayerInfoScreen emits `renew_/transfer_/sack_requested`; Main runs the action on the live
  roster dict). Read-only (buttons hidden) for another club's player. Frame `081_154619`.
  GAP: the CLAUSES panel + YEARS|LEFT split + the TRANSFER->TEAM OFFER accept/refuse screen
  (run-3) are not yet on the card — see APP_VS_SPEC_AUDIT B7.
