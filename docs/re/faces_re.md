# Player faces (mugshots) — photoId decode + bank extraction

PM98 ships two photo banks of digitised player faces, both keyed by a global
**photoId** stored on each player's EQUIPOS record:

| bank | path | size | format |
|------|------|------|--------|
| profile | `DBDAT/BIGFOTO/EQ96<DDNN>.PKF` (one per club) | 124×182 | standard "BM" DIB, **junk** embedded palette |
| thumbnail | `DBDAT/MINIFOTO.PKF` (one flat archive, 690) | 32×32 | custom 26-byte stub header, raw bottom-up indices |

Both are coloured with the **shared 256-colour VGA palette** (`DAT.PKF+0x5ca`), the
same one every other PM98 bitmap uses. The big photos' own embedded palette is random
noise (verified by sight: garbage under embedded, a clean photo under VGA), so render
them with `force_vga`, opaque (full-frame photos — index 0 is a real colour, not
transparency). The minis defeat Pillow (the stub's width/height/bpp are garbage), so
they are hand-decoded: 1024 raw indices at offset 26, **bottom-up**, VGA palette.

The archive filename `J96NNNNN.BMP` encodes the season (`96`) and the 5-digit photoId
`NNNNN`. Exported id-named: `app/art/faces/<NNNNN>.png` + `mini/<NNNNN>.png`.

## photoId — where it lives on the player record

In the English extended record (`tools/extract_english.py`) each player's photoId is
the **u16 LE just before the player's name**, normally at `name_start − 3` (one pad byte
sits between the id and the `[u16 len]` name prefix). Equivalently it is the field that
trails the *previous* player's attribute block (`6c 6b` + 10 attrs + `01`), since the
records are laid out:

```
… attrs(k-1) 01 [photoId(k)] [u16 len][name(k)] … year(k) … bio(k) … 6c6b attrs(k) 01 [photoId(k+1)] …
```

The first decode attempt paired the photoId with the *attrs it physically follows*; that
is **off by one** (it put Schmeichel's photo on the backup keeper Van der Gouw, who is
listed first). The field belongs to the player whose **name it precedes**.

`name_start − 3` is right for most players, but some carry a **4-6 byte field block**
between the id and the name, so the id sits farther back (Phil Babb's real id 8443 is at
`name_start − 9`, with `06 04 00 23 00 03` then the name; a naive −3 read the tail `00 03`
= a phantom **768** that matched no photo). So the decoder **scans back from −3 in 2-byte
steps (to −15) and takes the first candidate that is a real photo in THIS club's BIGFOTO
archive** — pinning it to the actual face. The club's archive is found via the EQUIPOS
entry order (entry N's `EQ96<code>.DBC` names record N's `BIGFOTO/EQ96<code>.PKF`). No
archive hit → the −3 value if plausible, else None (photo-less → blank frame). This is
safe because the scan window is 12 bytes (the previous player's id is thousands of bytes
back) and only THIS club's ~15-20 ids are candidates.

## Cross-validation (how we know the join is right, not noise)

Verified **by looking** — the join's output rendered and eyeballed, not just counted:

- **Schmeichel = 3371** — the photo is unmistakably Peter Schmeichel in a red Denmark
  (DBU) training top. The off-by-one attempt mislabelled this as "Van der Gouw".
- **Flowers = 1851** — the England yellow Umbro keeper kit with the Three Lions; Tim
  Flowers was the only Blackburn keeper capped by England (not Filan/Fettis).
- **Seaman = 7931** — the iconic moustache. **Bergkamp / Wright** in the Arsenal JVC
  kit; **Beckham** in the young-England polo.
- **Coverage: 594 / 610 big photos (97%)** are claimed by exactly one player across the
  92 English clubs; every club's whole bank is consumed (Blackburn 15/15, Arsenal 21/21).
  The unclaimed handful are players the name heuristic dropped, not mapping errors.
- **~30%** of squad slots carry a photoId that resolves to a real bank entry; the rest
  are photo-less in the original (the game drew a blank frame — `FOTO_GENERAL.BMP` is an
  all-index-0 placeholder, exported as `_generic.png`).

## Pipeline

- `tools/re/export_faces.py` — exports both banks (indexed P-mode PNGs, lossless and
  ~2.4× smaller than RGB) + `_generic.png` + `app/data/face_index.json` manifest.
- `tools/extract_english.py` — adds `photoId` per player (`name_start − 3`; 0 /
  implausible → `null`). `tools/build_db.py` carries it into `game_db.json`.
- Runtime: `PMChrome.face(photoId)` / `PMChrome.mini_face(photoId)` (mirrors `kit()`),
  `null` when photo-less so callers draw a blank frame. Test: `tests/test_faces.gd`.

International/continental squads use the compact record format; their photoId offset is
not yet decoded (only English clubs carry `photoId` today, and BIGFOTO covers 72 clubs).
