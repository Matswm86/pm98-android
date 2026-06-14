# PM98

A classic-style **football management game for Android** — an English remake of
the late-90s manager classic: pick a club, sign players, set tactics, run the
season, climb the divisions.

> **Status: in development (pre-alpha).** No playable build yet — see the roadmap
> below. The download link and screenshots appear here with the first release.

## Download

📦 **[Releases](https://github.com/Matswm86/pm98-android/releases)** — the Android
APK will be published here when the first playable build is ready. Sideload it on
your phone (enable "install from unknown sources").

*No release yet.*

## Screenshots

*Coming with the first build.*

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

The Android app lives in `app/` (Kotlin) and is built in CI — see
`.github/workflows/`. The `tools/` folder holds the Python scripts that prepare
the game's data. Both are work-in-progress.

## License

Code is released under the MIT License (see [`LICENSE`](LICENSE)). This is a
fan-made, non-commercial project and is not affiliated with or endorsed by any
real football club, league or rights holder.
