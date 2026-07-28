# PCF5DAT.PKF — what it actually is (it is NOT the pitch background)

Status: **CLOSED 2026-07-28. The "hard gap" was a misidentification.** `PCF5DAT.PKF` is not
the simulador's tile-scroll pitch and holds nothing the WATCH view needs. `MANAGER.EXE` opens
it exactly once, to check that the CD is in the drive.

Evidence: `tools/re/enum_pcf5dat.py` (container probe), the disassembly below, and a byte read
of the file itself. Source: `~/backup/Div/premier manager 98.iso`.

## The claim this replaces

`REMAINING.md` §P0-2 and `handoff-pm98-m5-wirein-lowdiv-drive-2026-07-28` §1b both carried:

> **the PITCH background** — ⛔ **HARD GAP — `PCF5DAT.PKF`, the 3/4 tile-scroll camera, is not
> reversed.** This is the only genuinely unsolved piece

That was never verified against the binary. It is wrong.

## What the binary does with it

The string `PCF5DAT.PKF` lives at VA `0x658a60` and has **exactly one** xref in the whole
image, the operand at `0x4f82ed` inside the function at `0x4f82e0`:

```
0x4f82ec  push 0x658a60                 ; "PCF5DAT.PKF"
0x4f82f8  call 0x5ec200                 ; -> build the CD path
0x4f8308  call [0x6233cc]               ; wsprintf into the local buffer
0x4f831b  call [0x6233f8]               ; _lopen(path, 0x8000)
0x4f8329  je   0x4f83a6                 ; open failed -> the not-present arm
0x4f833d  call [0x6233f4]               ; _llseek(handle, 0xecbf, 1)
0x4f834f  call [0x6233fc]               ; _lread(handle, buf, 6)
0x4f835c  cmp  al, 0x44                 ; 'D'
0x4f8360  cmp  cl, 0x2e                 ; '.'
0x4f836a  cmp  byte [esp+0x12], 0x47    ; 'G'
0x4f8371  cmp  byte [esp+0x13], 0x2e    ; '.'
0x4f8377  cmp  byte [esp+0x14], 0x43    ; 'C'
0x4f837e  cmp  byte [esp+0x15], 0x2e    ; '.'
```

Six bytes at one fixed offset, compared against the literal `D.G.C.`. And the file really
does carry it:

```
>>> open('PCF5DAT.PKF','rb').read(0x11000)[0xecbf:0xecc5]
b'D.G.C.'
```

So `PCF5DAT.PKF` is a **CD-presence check**: a 314,854,588-byte PC Fútbol 5 data pack that
ships on the CD, is never read for content, and only has to exist with the right signature at
offset `0xecbf`. `enum_pcf5dat.py` independently reports it does not follow the PM98 PKF
directory grammar at all — 39.4 M candidate tag bytes, 37,072 with an in-bounds payload
triple, 30 with a printable name, and not one directory-like chain. Both facts agree: the
game never walks it.

## Where the simulador's art really comes from

All of it is in `DATSIM.PKF`, which is already extracted and already in use. The loader
`FUN_005923f0` builds each filename at a known site:

| file | site | what it is |
|---|---|---|
| `DatSim\campina.raw` | `0x59311f` | the out-of-stadium scenery LOD chain (trees, buildings, walls) |
| `DatSim\hierprem.raw` | `0x59302c` | the PM98-skinned stadium atlas: terrace, stairs, and the `PREMIER MANAGER 98` / `actua SPORTS` / `Gremlin` hoardings |
| `DatSim\hierba.raw`, `hierarg`, `hiebarsa`, `hiercal`, `hiercale`, `hieprees` | `0x592cbf`, `0x593069`, `0x593061`, `0x593043`, `0x59304a`, `0x593033` | the other competitions' stadium atlases |
| `DatSim\jug.pgf` | `0x59340a` | the 4211-frame player bank |
| `DatSim\balon.raw` | `0x5930ce` | the ball |
| `DatSim\cielo1.bmp` | `0x59a67c` | the sky backdrop |
| `DatSim\red.bmp`, `redhw.bmp` | `0x5ba012`, `0x593526` | the goal net |
| `DatSim\NumCam.bmp` | `0x592d37` | camera-number digits |
| `datsim\jugcam.ind` | `0x592a63` | the index table whose record layout is still a GAP |
| `Modelos\balon.p3d` | `0x592775` | the 3D HIGHLIGHTS path, whose `.p3d` models are absent |

## What was actually unreversed (and now is, or is declared)

The pitch never was the blocker. The two real unknowns are the camera's **eye**
(`camctrl+0x3c`, zeroed by its ctor `FUN_005f56a0` @`0x5f56d2`, with no other writer in
`0x5d7000..0x5f9000`) and its **orientation**. The projection itself is fully reversed
(`FUN_005eec60` plus `SetCamera`'s `k = width*256*zoom`, i.e. focal length = viewport width in
pixels), so the pose is solved by fitting that projection to a real WATCH capture —
`tools/re/fit_watch_camera.py`, frames in `tools/re/refs/watch-2026-07-28/`. See
`app/scripts/Pm98Camera.gd`.

Evidence: `tools/re/enum_pcf5dat.py`, `tools/re/fit_watch_camera.py`,
`tools/re/refs/watch-2026-07-28/`, `app/scripts/Pm98Camera.gd`, `app/tests/test_jug_render.gd`
