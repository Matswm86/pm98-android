# PM98

<img src="docs/img/pm98-pl-trophy.png" alt="Premier League trophy, rendered from the original PM98 game files" width="150" align="right"/>

An Android remake of **Premier Manager 98**, rebuilt from the original game's own
data. Take over a club, build your squad, run the season.

> **Early build.** Browse the complete original database, simulate a full season
> and read the final table, watch a match commentary feed, and view club finances.
> The career loop (save/load, transfers, tactics) is in progress.

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
- **Watch a match:** a minute-by-minute commentary feed (goals, cards, saves,
  corners) using the original game's own English match text, with real scorers.
- **Club finances:** income and expenses over a 52-week season, structured on the
  original game's finance ledger (tickets, TV, sponsors, wages).

## Screenshots

<p>
  <img src="screenshots/home.png" alt="Competitions" width="240"/>
  <img src="screenshots/squad.png" alt="Squad" width="240"/>
  <img src="screenshots/player.png" alt="Player ratings" width="240"/>
  <img src="screenshots/table.png" alt="Simulated league table" width="240"/>
</p>

## Coming next

A full career: pick a club and play week-by-week through the season with save/load,
then team selection and tactics, transfers and contracts, training, the cups and
Europe, injuries and suspensions, and board objectives. Club crests, player photos
and a 2D match view are decoded from the game files (the archive format is fully
cracked, see `docs/re/pkf_format.md`) and are being wired in. The season simulation
uses the original game's verified random-number generator and a per-shot model tuned
to realistic football results.

## Built with

Godot 4 (GDScript); the APK is built in GitHub Actions. The `tools/` folder holds
the Python that decodes the original game files into the database the app ships
with, and `docs/` documents the file formats.
