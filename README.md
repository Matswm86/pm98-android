# PM98

<img src="docs/img/pm98-pl-trophy.png?v=2" alt="Premier League trophy, rendered from the original PM98 game files" width="150" align="right"/>

An Android remake of **Premier Manager 98**, rebuilt from the original game's own
data. Take over a club, build your squad, run the season.

> **Early build, now playable.** Pick a club and play a career week-by-week with
> save/load, line-up and tactics, and a transfer market, alongside the original
> management screens rebuilt pixel-for-pixel from the game's own art.

<sub>The trophy above is decoded straight from the original game's archives by
`tools/re/pkf_image.py` (see the reverse-engineering notes in `docs/re/`). Original
game art © Dinamic Multimedia; shown here for this non-commercial fan remake.</sub>

## Download

📦 **[Download the latest APK](https://github.com/Matswm86/pm98-android/releases/download/latest/pm98.apk)**
&nbsp;·&nbsp; [all releases](https://github.com/Matswm86/pm98-android/releases)

Open the link on your phone, tap the APK, allow "install from this source" if
prompted. Reinstalling over an older build? Uninstall the old one first.

## What's in it now

- The full English pyramid: Premier League + Divisions One, Two and Three
  (92 clubs), as the original 1997-98 database has them.
- 384 more clubs from leagues across Europe and South America.
- ~8,000 players with their original ratings, keepers and squads as shipped.
- Browse League → Club → Squad → Player, with each player's attributes.
- Simulate a full season from any English division: every fixture played from the
  real squads, with a final table (form, goal difference, promotion/relegation).
- **Play a career:** take over a club and go week-by-week, with autosave/load,
  the league standings, fixtures and your board objective.
- **Team selection & tactics:** choose your XI on the pitch, pick a formation,
  marking and set-piece takers, all fed into the match engine.
- **Transfer market:** buy and sell players (valued from their real ratings),
  with AI clubs bidding back.
- **Injuries & suspensions:** your players pick up knocks and bookings as they
  play, sit out while they recover, and come back. An injured or suspended player
  can't be selected, so the XI reshuffles and the side is weaker until he returns.
  Five bookings earn a one-match ban; reds sit a player down on the spot.
- **Club news:** a live feed of injuries, suspensions, returns to fitness and the
  weekly result, newest first and colour-coded, on the original Main Menu's NEWS.
- **Training & player development:** your players improve or decline over a season
  by age (youngsters climb, veterans fade), and training **intensity** is the lever:
  harder training develops them faster but risks more injuries. Squads age a year
  each season, so a career has a real arc.
- **The domestic cups:** the **F.A. Cup** and the **Coca-Cola (League) Cup** both run
  alongside the league, with a fresh open draw each round (as the real cups do) and
  prize money for every round you survive plus a bonus for lifting one. The F.A. Cup is
  single-leg with replays then penalties (Round 4 → Round 5 → Qtr. Finals → Semifinals →
  Final); the League Cup is **two-legged** (home and away, settled on aggregate then
  penalties) with a single-leg final (Round 1 → Round 2 → Qtr Finals → Semifinals →
  Final). Track each run on its own original cup screen, around the game's own trophy art.
- **The Charity Shield:** each new season opens with the curtain-raiser between last
  season's **league champions** and **F.A. Cup winners** (the league runners-up step up if
  one club did the Double), a single neutral-venue match settled on penalties if level,
  around the game's own Charity Shield art.
- **European competitions:** finish high and you qualify for Europe the next season,
  the same way the original does: the **European Cup** (champions), the **U.E.F.A. Cup**
  (runners-up) and the **Cup Winners' Cup** (F.A. Cup winners). Each is a two-legged
  knockout (home and away, settled on aggregate then penalties) against a field of strong
  foreign clubs from the game's own database, with prize money on the reversed **UEFA
  schedule** (1M to compete, 510k a win, bonuses for reaching the last 8 and last 4), and
  its own original trophy. Watch every competition through to its final even when you're
  not in it.
- **The winners-of-winners finals:** each new season also opens the **European Supercup**
  (last season's European Cup winners v Cup Winners' Cup winners) and the **Intercontinental
  Cup** (European Cup winners v the South American champions), one-off matches around their
  own original trophies.
- **Watch a match:** a minute-by-minute commentary feed (goals, cards, saves,
  corners) using the original game's own English match text, with real scorers.
- **Club finances:** income and expenses over a 52-week season, structured on the
  original game's finance ledger (tickets, TV, sponsors, wages).
- **The original screens, rebuilt:** the Title / front-door menu, the Main Menu hub,
  League Tables, Line-Up, Squad, Finances, Transfer Market, the Board of Directors and
  the Stadium are reconstructed at the exact pixel coordinates reversed out of the
  game's executable, using its own icons, fonts and backgrounds (see `docs/re/`). The
  app opens on the real PREMIER MANAGER 98 title screen. Runs in landscape, scaled to
  fit any phone.

## Screenshots

The app on a phone-aspect screen, opening on the original PREMIER MANAGER 98 title,
captured from the running game (not a mock-up):

<p><img src="screenshots/boot_phone.png?v=2" alt="PM98 running on a phone — the title screen" width="640"/></p>

The Title and the original Main Menu as the live career hub (here managing ARSENAL),
captured from the actual Godot build:

<p>
  <img src="screenshots/title.png?v=2" alt="Title / front-door menu" width="320"/>
  <img src="screenshots/hub.png?v=2" alt="Main Menu as the live career hub" width="320"/>
</p>

The **2D match view** — the iconic DATSIM sprite match — with the original game's own
player sprites on a 3/4 broadcast pitch, driven by the reverse-engineered match engine
(real scoreline, minute-by-minute events). Captured from the running Godot build:

<p>
  <img src="screenshots/match.png?v=2" alt="2D match view — kick-off" width="420"/>
  <img src="screenshots/match_goals.png?v=2" alt="2D match view — late on, ARSENAL 2:4" width="420"/>
</p>

**Injuries, suspensions and the club news feed** — the squad screen flags who's out
(INJ/SUS, in red/orange), and the Main Menu's NEWS carries the week's injuries, bans,
returns and results, colour-coded and newest-first. Captured from the running build:

<p>
  <img src="screenshots/squad_injuries.png?v=2" alt="Squad screen with injured/suspended players flagged" width="420"/>
  <img src="screenshots/news.png?v=2" alt="Club news feed — injuries, suspensions, returns, results" width="420"/>
</p>

**Training & player development** — set the training intensity and watch your squad's
development trend (young players improving in green, veterans fading), on the Main Menu's
staff icon. Captured from the running build:

<p>
  <img src="screenshots/training.png?v=2" alt="Training screen — intensity lever and squad development trend" width="420"/>
</p>

**The domestic cups** — the F.A. Cup (single-leg, replays then penalties) and the
Coca-Cola Cup (two-legged, settled on aggregate), each on its own original cup screen with
the game's own trophy: the manager's run round-by-round, the latest draw, and the status.
Captured from the running build:

<p>
  <img src="screenshots/fa_cup.png?v=2" alt="F.A. Cup screen — the manager's run, the latest draw, and the trophy" width="420"/>
  <img src="screenshots/coca_cola_cup.png?v=2" alt="Coca-Cola Cup screen — two-legged aggregate scorelines and the trophy" width="420"/>
</p>

**The Charity Shield** — the season's curtain-raiser, last season's champions v F.A. Cup
winners around the game's own shield art. Captured from the running build:

<p>
  <img src="screenshots/charity_shield.png?v=2" alt="Charity Shield screen — champions v F.A. Cup winners, around the real shield art" width="420"/>
</p>

**European competitions** — qualify from last season's finish into the European Cup, the
U.E.F.A. Cup or the Cup Winners' Cup: two-legged knockouts against strong foreign clubs,
each around its own original trophy, with the reversed UEFA prize money. Captured from the
running build (the manager's Cup Winners' Cup run):

<p>
  <img src="screenshots/european_cup.png?v=2" alt="European competition screen — a two-legged knockout run against foreign clubs, around the real trophy" width="420"/>
</p>

The database and the new-career club picker, all in PM98 chrome (the green data-browser
is gone), captured from the running build:

<p>
  <img src="screenshots/home.png?v=2" alt="Database browse" width="240"/>
  <img src="screenshots/pick_club.png?v=2" alt="Pick a club" width="240"/>
  <img src="screenshots/league_table.png?v=2" alt="League table" width="240"/>
</p>

The rest of the rebuilt screens, reconstructed at the exact pixel coordinates reversed
out of the game's executable, from its own icons, fonts and backgrounds:

<p>
  <img src="screenshots/lineup.png?v=2" alt="Line-up and formation" width="240"/>
  <img src="screenshots/squad.png?v=2" alt="Squad management" width="240"/>
  <img src="screenshots/transfer.png?v=2" alt="Transfer market" width="240"/>
</p>
<p>
  <img src="screenshots/finance.png?v=2" alt="Club finances" width="240"/>
  <img src="screenshots/directiva.png?v=2" alt="Board of Directors" width="240"/>
  <img src="screenshots/stadium.png?v=2" alt="Stadium" width="240"/>
</p>

<sub>Every screenshot here is a real capture from the running Godot build (Xvfb + GL in CI) —
not a mock-up or a preview render. On a phone each screen runs in landscape with a marble
bezel in the side margins.</sub>

## Status

This is an early build, but the whole front end is now PREMIER MANAGER 98, not a green
placeholder UI: it opens on the original title screen, the career hub is the original
Main Menu, and the database browse, the new-career club/league pickers and the
2D match view all run in the game's own chrome (marble background, the BARRA bar, the
PROMAN font), routing into the reversed Squad, League Tables and Finances screens. A
couple of deep menus (team tactics, the transfer desk) are still a simpler functional UI.

## Coming next

European competitions, youth development, a full staff team and deeper player contracts
(injuries, suspensions, the club news feed, training/player development and BOTH domestic
cups — the F.A. Cup and the Coca-Cola Cup — are now in). The 2D
match view now renders the original game's own sprites on a 3/4 broadcast pitch (the
`.PGF` sprite format is fully cracked, see `docs/re/match_view_re.md`); next for it are
the original scrolling tile-camera and per-team kit recolours. Club crests and player
photos are decoded from the game files (the archive format is cracked, see
`docs/re/pkf_format.md`) and are being wired in. The season simulation uses the
original game's verified random-number generator and a per-shot model tuned to
realistic football results.

## Built with

Godot 4 (GDScript); the APK is built in GitHub Actions. The `tools/` folder holds
the Python that decodes the original game files into the database the app ships
with, and `docs/` documents the file formats.
