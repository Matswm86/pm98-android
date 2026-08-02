# PM98

<img src="screens/title.png" alt="The Premier Manager 98 front-door menu" width="320" align="right"/>

Premier Manager 98 on Android. I own the PC game, I took my own copy apart, and this is what
came out of it: the same screens, the same clubs, the same players, on a phone.

Hobby project. Nothing is sold, nothing is monetised, and no game data ships in here that did
not come off my own disc.

## Download

**[Get the APK](https://github.com/Matswm86/pm98-android/releases/download/latest/pm98-b65755f.apk)**
&nbsp;·&nbsp; [all builds](https://github.com/Matswm86/pm98-android/releases)
&nbsp;·&nbsp; [pm98.mwmai.no](https://pm98.mwmai.no)

Open the link on your phone, tap the file, allow "install from this source" when it asks. If you
are reinstalling over an older build, uninstall the old one first.

The filename carries the build id on purpose, so your phone can never serve you a stale cached
APK. If the link 404s a newer build has landed, so grab the newest `pm98-*.apk` off the releases
page.

## What it does

Pick a club, take over, run it week by week.

- All 92 English clubs, plus 384 more from Europe and South America, and around 8,000 players on
  their original ratings.
- Line-up and tactics: the XI on the pitch, the formation, marking, set-piece takers.
- Transfers, counter-offers, contracts and renewals, the scout, the youth academy, and all
  thirteen backroom jobs to hire and sack.
- The club's books week by week. Wages go out every week, the gate and the TV money only come in
  when you play at home, so an away Saturday costs you. Run at a loss long enough and the board
  starts counting.
- Both domestic cups across all 92 clubs, the Charity Shield, and Europe: European Cup, U.E.F.A.
  Cup, Cup Winners' Cup, the Supercup and the Intercontinental.
- Training, injuries, suspensions, and squads that age a year every season.
- Watch a match side on, read it minute by minute, or jump straight to full time.
- The season ends the way the original ends it. Final tables, the trophy cards, the year's top
  scorers and managers, then next pre-season.
- Ten save slots. Landscape, scaled to whatever phone you have.

## Screenshots

<p>
  <img src="screens/hub.png" alt="Career hub, the Main Menu running a season" width="420"/>
  <img src="screens/lineup.png" alt="LINE-UP screen with the squad, the XI, the formation and the mini-pitch" width="420"/>
</p>

<sub>Captured off the Android build. Shots of the original 1998 PC game, which is what these are
measured against, are on the [project page](https://pm98.mwmai.no).</sub>

## Status

The manager game is finished and it plays.

Anything with a number on it is read out of the 1998 game rather than invented: transfer fees and
wages, insurance, the injury bill, ground costs, the sack schedule, what a scout will and will
not find you. Screens are measured against photographs of the real game running and most of them
come out at zero differing pixels. Where a value genuinely is not known yet the screen is left
blank instead of filled with something that looks about right.

Your results come out of the 1998 game's own engine. Premier Manager 98 has two: a positional
one that runs the twenty-two players when you watch a match, and a statistical one that decides
every match you do not watch. The second one is copied exactly, and it is what plays your season.

The first one is the part still being built. It is written, and it tracks the real game move for
move as far as I have managed to check it, which is the first nine minutes of a half. Watching a
match runs it for real; the drawing over the top of it is an approximation. HIGHLIGHTS cannot be
built at all, the 3D models are not on the disc.

Full list with per-item status: [`docs/REMAINING.md`](docs/REMAINING.md).

## Cheats

Two, both off by default, both toggled on the hub's OPTIONS panel (tap the top edge for the
dropdown bar, then the headphones). Neither is a Premier Manager 98 setting: each is a patch
worked out against the real `MANAGER.EXE` and then ported, so with the switch off the game
behaves exactly as the original does.

**Unsackable.** The board can hold as many urgent meetings as it likes. Four straight weeks in
the red, a results review gone against you, a squad under sixteen men: those are the three things
that end a career in this game, and none of them will.

**Three up front.** Pick a shape with three up front (4-3-3, 3-4-3, 4-2-4, 5-2-3) and the match
engine stops pretending: your chance count is floored and the opposing keeper stops saving. Six
goals a game unless the dice give you more. A Mixed Play mentality arms it too, as does actually
fielding three natural forwards in any shape. The row says **ARMED** when the coming match will
get it and **IDLE** when the switch is on but nothing has triggered. Instant results only,
watched matches play normally.

## Built with

Godot 4, and the APK is built in GitHub Actions. `tools/` is the Python that decodes the
original's archives, fonts and database and diffs the app's screens against captured frames.
`docs/` is the write-up of how the original actually works, one file per screen. `web/` is the
project page.

## Legal

A non-commercial fan project for my own use. Not affiliated with, endorsed by or connected to
Gremlin Interactive, Dinamic Multimedia, or anyone else holding rights in Premier Manager.
Premier Manager 98 and all its art, data and trademarks belong to their owners, and the
screenshots here are the original game, shown for identification and commentary. The code in this
repo is MIT, see [LICENSE](LICENSE). Nothing here is for sale.
