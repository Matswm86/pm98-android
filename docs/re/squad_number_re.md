# Squad number (N°) + SQUAD MANAGEMENT row order — decoded from EQUIPOS.PKF

Decoded 2026-07-02 against walkthrough frame `077_154612` (the real SQUAD MANAGEMENT,
Man Utd, 19 visible name→N° pairs). Both decodes follow the project's established
cross-validation method (the same method that pinned the broad `d[Y-3]` and fine
`d[Y-12]` position bytes, `positions_re.md`).

## The squad-number byte

In the extended (English) player record the layout before each player's name block is

```
[photo-id u16 LE][squadNo u8][u16 len][short name][u16 len][full name]...
```

**`squadNo` = the byte immediately after the photo-id u16** (i.e. at
`first_name_field_start - 1` in the plain layout; at `photo_pos + 2` in general —
Babb-style records carry a small field block between the number and the name).

### Validation
- **Frame truth 19/19**: SCHMEICHEL 1, GARY NEVILLE 2, IRWIN 3, MAY 4, JOHNSEN 5,
  PALLISTER 6, BECKHAM 7, BUTT 8, COLE 9, SHERINGHAM 10, GIGGS 11, PHIL NEVILLE 12,
  MCCLAIR 13, JORDI CRUYFF 14, KEANE 16, VAN DER GOUW 17, SCHOLES 18, NEVLAND 19,
  SOLSKJAER 20 — every visible frame-077 row matches the decoded byte exactly.
- **Off-frame consistency**: BERG decodes 21 (his real 97-98 number, not visible in
  the frame); the youth players decode 27-30 (CURTIS 27, THORNLEY 28, CLEGG 29,
  CASPER 30); **no Man Utd player decodes 15 — and the frame shows no 15 either.**
- **Extended-block cross-check**: BABB (Liverpool) has his photo id at `ns-9` with a
  field block before the name; `d[photo_pos+2] = 0x06` = his real 6.

### Coverage is per-club, NOT universal
Fleet scan over the 92 English clubs (pipeline output after the fix below):
**18 clubs carry a fully individuated set** (all present, no dups — the Premier's
big clubs), **67 leave the whole squad at the `0x01` pad** (the byte exists but
was never data-entered; a squad of 1s is not a numbering), **7 are mixed**
(pad-dominated with a handful of real entries, e.g. Forest's BEASANT 20 among 1s;
Arsenal/West Ham/Fulham have one duplicated pair each in otherwise-real sets).

**Pad `0x01` is byte-identical to a real dorsal 1** (Schmeichel's). The only safe
consumer rule is per-club: display N° when the club's set is individuated
(unique, all present), else render `-`. **What the original engine displays for a
pad club is UNRESOLVED** — do not invent a renumbering; resolve it only from a
walkthrough frame of a pad club's squad or the loader/grid decompile.

### Extractor fix that fell out (Giggs)
`name_before` picked a junk alignment for GIGGS: his trailing bio bytes
pseudo-decode as a 10-char "full name", and `RYAN JOSEPH GIGGS + junk` (27 chars)
out-scored the real `GIGGS + RYAN JOSEPH GIGGS` (22) on text length. That mis-start
also parity-shifted the photo scan-back (photo at an even offset is never scanned),
so Giggs' photoId was the `-3` fallback `1542` and his squadNo read `18`.
Fix (`tools/extract_english.py`): a name alignment whose `h-3` u16 is a real photo
id in THIS club's BIGFOTO archive outranks any text-length pick. Giggs now:
display `GIGGS`, legalName `RYAN JOSEPH GIGGS`, photoId `3381` (archive-pinned),
squadNo `11`. Emitted as `squadNo` through `build_db.py` into `game_db.json`.

## Row order: each section is REVERSE record order

Frame 077's four sections list players in the **exact reverse of the EQUIPOS record
order** (skipping nothing):

| section | EQUIPOS order (filtered) | frame 077 shows |
|---|---|---|
| KEEPERS | VdG, Schmeichel | Schmeichel, VdG |
| DEFENDERS | ..., Johnsen, P.Nev, G.Nev, Irwin, Pallister, ..., May | May, Pallister, Irwin, G.Nev, P.Nev, Johnsen (visible 6) |
| MIDFIELDERS | Thornley, McClair, Butt, Keane, Giggs, Scholes(±), Beckham | Beckham, Scholes, Giggs, Keane, Butt, McClair |
| FORWARDS | Nevland, Sheringham, Solskjaer, J.Cruyff, Cole | Cole, J.Cruyff, Solskjaer, Sheringham, Nevland |

Consistent with the loader building the club's player linked list by **prepending**;
the screen row-fill (`FUN_00588580`) walks that list per section (`player+0x1c`).
Ported: `SquadScreen._sections()` reverses each roster bucket (no ability sort).
A later signing (appended to the app roster) correctly shows first.

## Not fabricated
- **MO (morale)**: dynamic save value, no model in the app yet → renders `-`
  (never the static RM attribute; APP_VS_SPEC_AUDIT B7).
- **N° for pad clubs**: renders `-` (see above).
