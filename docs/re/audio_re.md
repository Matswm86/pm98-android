# Audio — music + SFX (T1 #1, D7)

PM98 ships its audio in three places, all read by the PCF5 engine through `MIDAS11.DLL`
(the MIDAS Digital Audio System). All are owned/copyrighted, so the originals stay under
the gitignored `extracted/`; `tools/re/export_audio.py` converts them to committed Ogg
Vorbis under `app/audio/` (same model as the kit PNGs — CI only regenerates `.import`).

## Sources

### MUSICAS.PKF — 8 ScreamTracker-3 modules (`.S3M`)
A standard PKF container (see `pkf_format.md`). Members, all valid S3M (`SCRM` @ 0x2c):

| member | duration | role |
|--------|----------|------|
| DINAMIC0.S3M | 101 s | in-game theme 0 (used as the **menu theme**) |
| DINAMIC1..5.S3M | 53–129 s | further in-game themes (rotation, not shipped yet) |
| DINABASE / DINABAS2.S3M | 294 / 338 s | longer DB-editor themes (unused here) |

`MANAGER.EXE`'s string table references `musicas\dinamic0.s3m` .. `dinamic5.s3m` as the
in-game music; DINABASE/DINABAS2 are not referenced from MANAGER.EXE. DINAMIC0 is the
front-end/menu theme. Rendered to Ogg with ffmpeg's `libopenmpt` demuxer (`ffmpeg -i x.s3m`).

### SONIDOS/*.RAW — UI sounds
Headerless **unsigned-8-bit mono PCM @ 11025 Hz** (the trailing "8" = 8-bit):
`SELEC8.RAW` (0.56 s, the select/confirm click) and `PASA8.RAW` (navigate). Decoded with
`ffmpeg -f u8 -ar 11025 -ac 1`.

### SFX/AMBIENTE.PKF — match SFX (u8/11025 mono, Spanish names)
PKF container of headerless u8 PCM (silence = 0x80). Shipped subset:

| member | s | role | asset |
|--------|---|------|-------|
| SILBATO | 0.6 | whistle | sfx/whistle.ogg |
| SILBATOF | 2.2 | final whistle | sfx/whistle_final.ogg |
| GOL | 19.4 | goal roar | sfx/goal.ogg |
| AMARIL | 4.7 | yellow-card crowd | sfx/card_yellow.ogg |
| ROJAL | 7.3 | red-card crowd | sfx/card_red.ogg |
| FONDO | 15.2 | crowd ambience bed (looped) | sfx/crowd.ogg |
| ENTRADA | 0.4 | tackle | sfx/tackle.ogg |
| POSTE | 0.3 | woodwork | sfx/post.ogg |

(Not shipped: GOL1/GOLV alt roars, OE*/OELOOP* "oé" chants, BOCINA horns, EXCLAMA*,
PROTESTV, plus `SFX/COMENT.PKF` = 45 MB of Spanish match commentary.) The 11025 Hz rate is
verified by duration sanity: SILBATO at 11025 = 0.63 s (a 22050 reading would be 0.31 s,
too short for a whistle).

## Runtime (`app/scripts/AudioManager.gd`, autoloaded)
One looping MUSIC player (menu theme), one looping CROWD player (match bed), a 6-voice
round-robin pool for one-shots. `music_enabled` / `sfx_enabled` mirror MANAGER.INI's
MUSIC / SOUND ON-OFF switches (a future options screen can flip them). Ogg imports default
to loop=off, so the manager forces `AudioStreamOggVorbis.loop = true` on the looped streams.

Wiring (`Main.gd`): `play_music()` rides every front-end / management screen (idempotent —
no restart spam); `ui_select()` clicks on hub/title/browse taps and the Back button. The
match (`MatchScreen.gd`) stops the music, starts the crowd bed, blows the kick-off whistle,
fires the goal roar / yellow / red SFX as the clock crosses each commentary event, and the
final whistle at 90'. It reaches the autoload by `/root/AudioManager` node lookup, not the
bare global identifier (which does not resolve when the screen is loaded under a `--script`
headless test).

Test: `app/tests/test_audio.gd` (assets present, autoload + SFX table, loop forcing,
idempotent play_music, MatchScreen event→SFX map).
