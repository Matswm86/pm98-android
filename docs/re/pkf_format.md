# PCF5 `.PKF` archive format — CRACKED (session 4)

Premier Manager 98 is built on Dinamic Multimedia's **PC Fútbol 5 (PCF5)** engine
(strings `PCF5DAT.PKF`, `PCF5_Loader_Event1/2` in `MANAGER.EXE`). All `.PKF` files
(`DAT`, `DATSIM`, `IMG`, `RECURSOS`, …) use one container format, reversed here from
the loader in `MANAGER.EXE` and verified by a from-scratch parser/extractor
(`tools/re/pkf_unpack.py`) that walks all four archives to a clean END and extracts
byte-exact, valid payloads (RIFF `PAL`, Windows `BMP`).

## The container is NOT compressed
Earlier notes flagged `DAT.PKF` (whole-file entropy 7.77) as "the one genuinely packed
file, decode pending". That was wrong: the **container applies no compression**. The high
entropy is just the payloads themselves being already-encoded (`.IND` index bitmaps, `.PAL`
palettes, `.BRT` brightness LUTs, `.PGF`/`.RAW`/`.BMP` sprites). Every entry is a plain
slice `buf[offset : offset+size]`. Verified: in `DAT.PKF` consecutive payloads are
contiguous (`offset[i] + size[i] == offset[i+1]`) except at directory-chunk boundaries.

## Directory = a stream of tag-tagged records
Decoded from `FUN_005e81c0` (`0x5e81c0`), the directory parser, + its byte helpers
`FUN_005f9a70` (sequential read), `FUN_005e6490` (read a 20-byte name then de-obfuscate),
`FUN_005e87b0` (read 8), `FUN_005f9ae0` (seek). Parsing starts at file offset 0.

Each record = one **tag byte**; `tag & 7` = type, `tag & 0x80` = a region/compressed
storage flag that does **not** change how many bytes the directory reader consumes (so the
parser is flag-independent). Bytes consumed *after* the tag:

| type | layout (after tag)                                   | meaning |
|------|------------------------------------------------------|---------|
| 1 | `name[20]` + `u32` + `u32`                              | folder / group header (e.g. `CALCIO`, `COPAS`) |
| 2 | `name[20]` + `u8` + `u16` + `u16` + **`u32 off`** + **`u32 size`** + `u32 flag` | FILE entry |
| 3 | `u32 off` + `u32 size`                                  | unnamed raw block (rare; not seen in the 4 main PKFs) |
| 4 | `u32 target`                                            | SEEK absolute to `target` (directory continues there) |
| 5 | —                                                      | END of directory |
| other | —                                                    | corrupt / wrong start (engine raises error `0xC`) |

Layout on disk is interleaved: `[dir chunk of type-2 records][payload data for them]
[type-4 seek to next chunk]…`. The type-4 seek hops the reader over each data region to
the next directory chunk — which is why payload contiguity breaks exactly once per chunk.

### Name obfuscation (`FUN_005e6500` @ `0x5e6500`)
The fixed 20-byte name field is XOR-obfuscated:

    name[i] ^= ((i - 0x21) * (i + 1)) & 0xFF        for i in 0..19

(`i` arithmetic is signed-char in the binary; masking to a byte reproduces it.) The first
record of every archive is a type-1 whose de-obfuscated name is the archive's own id
(`DAT`, `DATSIM`, `IMG`, `RECURSOS`). The 6-byte run `2a 43 f8 b4 1e f1` that prior notes
called a "format signature" is **not** a signature: it is simply XOR-ciphertext bytes of
the first record's obfuscated name field.

## Verified inventory (via `pkf_unpack.py`)
| archive | bytes | folders (t1) | files (t2) | seeks (t4) | sample contents |
|---|---|---|---|---|---|
| DAT.PKF      | 2,498,013 | 1  | 41   | 4  | `MENU.PAL` `MANAGER.IND` `GRADIENT.DAT` `*.BRT` (palettes, index + brightness LUTs) |
| DATSIM.PKF   | 5,898,299 | 2  | 1704 | 56 | `BALON.RAW` `*.PGF` match-view sprites + `PALETAS` |
| IMG.PKF      | 2,126,009 | 29 | 267  | 14 | UI screens `CALCIO` `COPAS` `CLASIFICACION` + `*.BMP` |
| RECURSOS.PKF | 7,715,581 | 36 | 392  | 19 | `ICONOS` `BARRA*.BMP` `BARRAMASK*.BMP` UI resources |

All payloads land within file bounds; both archives extract to valid standard formats
(MENU.PAL = RIFF `PAL`, FADERP.BMP = Windows `BMP`).

## Tooling
`tools/re/pkf_unpack.py`:
- `pkf_unpack.py` — parse + summarize every PKF (record counts, names, contiguity).
- `pkf_unpack.py --extract OUT [F.PKF …]` — extract entries to `OUT/<pkf>/<name>`.

Extracted assets are the publisher's copyrighted content and are **not** committed
(`extracted/` is gitignored). The Android clone reads the originals at runtime / build.

## Decompile dumps
Loader chain decompiles in `docs/re/pkf/`: catalog lookup `FUN_005eb4f0`, load orchestrator
`FUN_005e6950`, directory parser `FUN_005e81c0`, name de-obfuscator `FUN_005e6500`, read/seek
primitives `FUN_005f9a70`/`FUN_005f9ae0`. (`FUN_004f82ec` is the unrelated CD copy-protection
check that reads a `D.G.C.` marker — not part of the archive loader.)
