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
for a freshly loaded squad). The ROLE label uses the broad 4-entry role LUT
(`PTR_s_GOALKEEPER_00662d10` -> GOALKEEPER/DEFENDER/MIDFIELDER/FORWARD); the fine position
is shown by the CAMROL icon.

## Open
- The fine role-NAME text ("CENTRE FORWARD") source LUT is not yet located (the camrol icon
  carries the fine detail today).
- Nationality FLAG art (`DBDAT/BANDERAS.PKF`) not yet extracted — the name is shown as text.
- International (compact-record) clubs carry neither photoId nor these physicals yet.
