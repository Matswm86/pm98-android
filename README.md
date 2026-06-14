# PM98

A classic-style **football management game for Android** — an English remake of
the late-90s manager classic: pick a club, sign players, set tactics, run the
season, climb the divisions.

> **Status: in development (pre-alpha).** First build is up: a browsable database
> of leagues, clubs and squads. The match engine and the rest of the management
> layer are next, see the roadmap below.

## Download

📦 **[Download the latest APK](https://github.com/Matswm86/pm98-android/releases/download/latest/pm98.apk)**
&nbsp;·&nbsp; [all releases](https://github.com/Matswm86/pm98-android/releases)

Sideload on your phone: open the link, tap the APK, allow "install from this
source" if prompted. This pre-alpha ships with sample data so it runs out of the
box.

## Screenshots

<p>
  <img src="screenshots/home.png" alt="Competitions" width="240"/>
  <img src="screenshots/squad.png" alt="Squad list" width="240"/>
  <img src="screenshots/player.png" alt="Player attributes" width="240"/>
</p>

## Features (planned)

- Full English league pyramid — Premier + Divisions 1, 2 and 3
- Hundreds of real-world clubs and squads
- Match engine, league tables, promotion/relegation and cups
- Transfers, scouting, youth development and contracts
- Stadium expansion, finances, training and morale
- Touch-friendly UI, fully offline, no ads

## Roadmap

1. **Data** — build the club/player database *(in progress)*
2. **Engine** — headless season simulation (match, league, transfers, finances)
3. **App** — Android UI on top of the engine → first APK
4. **Polish** — match presentation, audio, balancing

## Building from source

The game lives in `app/` (Godot 4 / GDScript) and the APK is built in CI — see
`.github/workflows/build-android.yml`. The `tools/` folder holds the Python
scripts that prepare the game's data. Both are work-in-progress.

## License

Code is released under the MIT License (see [`LICENSE`](LICENSE)). This is a
fan-made, non-commercial project and is not affiliated with or endorsed by any
real football club, league or rights holder.
