# PM98

An Android remake of **Premier Manager 98**, rebuilt from the original game's own
data. Take over a club, build your squad, run the season.

> **Early build.** Browse the complete original database, then simulate a full
> season and read the final table. The rest of the management layer (transfers,
> finances, save/load) is in progress.

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

## Screenshots

<p>
  <img src="screenshots/home.png" alt="Competitions" width="240"/>
  <img src="screenshots/squad.png" alt="Squad" width="240"/>
  <img src="screenshots/player.png" alt="Player ratings" width="240"/>
  <img src="screenshots/table.png" alt="Simulated league table" width="240"/>
</p>

## Coming next

Match-day detail, transfers, finances and save/load. Club crests, player photos
and the original music are decoded from the game files and are being wired in.
The season simulation is an honest first model tuned to realistic football
results; it will be refined toward the original game's own match math as more of
the game data is decoded.

## Built with

Godot 4 (GDScript); the APK is built in GitHub Actions. The `tools/` folder holds
the Python that decodes the original game files into the database the app ships
with, and `docs/` documents the file formats.
