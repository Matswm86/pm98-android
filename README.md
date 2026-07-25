# PM98

<img src="screens/title.png" alt="The Premier Manager 98 front-door menu — Data Base / Manager League / Pro-Manager League" width="320" align="right"/>

An Android remake of **Premier Manager 98**, rebuilt from the original game's own
data. Take over a club, build your squad, run the season.

> **Early build, now playable.** Pick a club and play a career week-by-week with
> save/load, line-up and tactics, and a transfer market, alongside the original
> management screens rebuilt pixel-for-pixel from the game's own art.

<sub>The menu above is a real capture from the running build: the original game's own front-door
art and fonts, rebuilt pixel-for-pixel from the game's own resources (see the reverse-engineering
notes in `docs/re/`). Original game art © Dinamic Multimedia; shown here for this non-commercial
fan remake.</sub>

## Download

📦 **[Download the latest APK](https://github.com/Matswm86/pm98-android/releases/download/latest/pm98-d3f8298.apk)** — one tap downloads `pm98-d3f8298.apk` (current build) straight to your phone.

> **This build (2026-07-25)** makes the whole youth team the original's, which is what you asked for. It turned out the academy was never a generator at all — the game **ships** its youth players, fifty-one of them, with real names, birthplaces and ratings, in a hidden club inside its own database. Everything the youth part does is a rule over that table, and all four rules are now taken straight from the game's code:
>
> - **Your youngsters are real people from the game's own database now**, not names we made up. The game hands each one to you thirty-five to forty-five points below himself, so **his ceiling is his own shipped rating** — the "hidden potential" we used to roll for him was never needed.
> - **The youth scout brings back exactly one player**, picked at random from those who clear eighty in any capability you lit. That is what the routine does; our shortlist of up to three was ours.
> - **How long he takes now depends on how good he is.** Fifty to fifty-five weeks at half a star, thirty to thirty-five at five — the game's own formula. We still halve it so a season carries two intakes, as you asked; that is the one number in the whole youth part that is not the game's.
> - **A youngster grows back up to his shipped rating and stops dead there**, a point roughly every other week, and the youth manager tells you he is ready the moment his core four arrive. No more youngsters who never budge, and no more youngsters who grow past themselves.
> - **The academy no longer empties itself every summer.** We used to age players out at nineteen and scout a free crop in — neither thing happens in the original, and the shipped youngsters are seventeen to nineteen, so they were being thrown away almost immediately.
>
> **Earlier build (2026-07-25)** — nine things you reported, each settled against the original:
>
> - **Training actually trains now.** We had an invented development model whose prime-age rate needed sixty-seven weeks to move a single point, so your best players never budged. The real routine is now ported straight from the game: put a man on a coach and **that skill climbs a full point every week** until he is eighteen to twenty-four clear of his shipped rating. GENERAL lifts all six trainable skills but only by five; SPEED, STAMINA, AGGRESSION and QUALITY are not trainable at all, exactly as in the original; and take a man off training and his gains bleed away a point a week.
> - **The BRIEF commentary follows your team sheet.** Sell Pallister and buy Nesta and it is Nesta on the pitch — the feed was reading the frozen 1997 squad, so sold players kept turning up. Only the twenty-two who actually played can be named now, and a save is credited to the keeper you picked.
> - **STATISTICS works on the results board — for both teams.** The button beside each side at half time and full time opens that team's eleven with the match record: minutes, rating, man of the match, goals, shots, passes, tackles, saves and cards. Half time shows the half-time figures, not the finished match.
> - **Most of the world is reachable in the transfer market again.** Fifty-six flagged countries on the OFFERS map did nothing when you tapped them; the rule that blocked them was ours, fitted to two frames that turned out to be a mouse hover. We clicked every flag on the real game — all fifty-seven switch, Macedonia's single club included — so the block is gone.
> - **Scout results are clickable.** Tapping a scouted player opens the offer card, including players abroad and free agents, instead of answering "no longer available".
> - **The youth scout brings you a shortlist.** His finds now appear in PLAYERS FOUND and you offer each one a contract — which he can turn down, as the original's own message says. The search is shortened so a season carries **two** intakes.
> - **Bidding starts at the asking price on every player**, not only the transfer-listed ones. Ronaldo opens at £16,000,000 instead of £5,000. (The original opens a cold approach at the floor; on a touch screen that is six hundred taps, so this one is a deliberate change.)
> - **The ground works tell you when they are done** — the original's own message box, one per job: capacity, car park, facilities, services.
> - **The match-options bar is reachable on a phone.** It used to sit under the notification shade; it now parks lower down, clear of the system gesture area.



> Filenames change every build (`pm98-<commit>.apk`) on purpose, so your phone/browser can never serve a stale cached APK. If a newer build has landed and the direct link above 404s, grab the newest `pm98-*.apk` asset from the **[latest release page](https://github.com/Matswm86/pm98-android/releases/tag/latest)**.

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
- **Injuries & suspensions, marked the way the original marks them:** a man who cannot
  play is drawn on the gold plate with the game's own three boxes — a **red cross and
  WEEKS** if he is hurt, **two yellow cards and MATCHES** if he is banned. Your players
  pick up knocks and bookings as they
  play, sit out while they recover, and come back. An injured or suspended player
  can't be selected, so the XI reshuffles and the side is weaker until he returns.
  Five bookings earn a one-match ban; reds sit a player down on the spot.
- **Club news:** a live feed of injuries, suspensions, returns to fitness and the
  weekly result, newest first and colour-coded, on the original Main Menu's NEWS.
- **Training & player development:** the original's own weekly routine, ported from the
  game. Hire the six skill coaches, put a player on one, and that skill climbs a point a
  week until he is well clear of the rating he shipped with; GENERAL lifts all six a
  little; FITNESS restores condition three times as fast. SPEED, STAMINA, AGGRESSION and
  QUALITY are not trainable — that is the original, not a shortcut — and a man taken off
  training loses his gains again a point a week. Training **intensity** is still the
  injury lever. Squads age a year each season, so a career has a real arc.
- **The youth team:** hire a youth scout and he goes looking. What he brings back is a
  **shortlist** on the YOUTH TEAM screen — tap a name to offer him a contract, which he
  can turn down. Signed youngsters develop toward a projected **potential**, and when the
  youth manager judges one ready you **promote** him into the first-team squad. Two
  intakes a season. Reached from the SQUAD screen's YOUTH TEAM button.
- **The backroom staff:** hire and sack all thirteen of the original's jobs — the six skill
  coaches (**HANDLING, PASSING, DRIBBLING, HEADING, TACKLING, SHOOTING**, who decide how
  many players you can put into training and on what), a **PHYSIOTHERAPIST** (cuts injury
  risk and treats the injured), a **SCOUT**, a **YOUTH TEAM SCOUT** and **MANAGER**, and
  the rest — each with a star rating and a wage. A fresh set of candidates turns up every
  week. The wage bill comes out of the bank every week, and the STAFF screen shows the live
  effect of your team. On the Main Menu's EMPLE (staff) icon.
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
- **European competitions, at the original's own size:** finish high and you qualify for
  Europe the next season, the same way the original does: the **European Cup** (champions),
  the **U.E.F.A. Cup** (runners-up) and the **Cup Winners' Cup** (F.A. Cup winners). The
  field sizes are the game's own, counted off its own RESULTS screens — European Cup **24
  clubs in six groups of four**, U.E.F.A. Cup **32** (`1/16 FINALS`), Cup Winners' **16**
  (`1/8 FINALS`). Out of the groups go the **six winners plus the two best runners-up**,
  which is not a guess: a career was driven to the quarter finals and the eight clubs drawn
  there are exactly those eight. Two-legged throughout (aggregate, away goals, extra time,
  penalties), against strong foreign clubs from the game's own database, with prize money on
  the reversed **UEFA schedule** (1M to compete, 510k a win, bonuses for the last 8 and last
  4). Watch every competition through to its final even when you're not in it.
- **The winners-of-winners finals:** each new season also opens the **European Supercup**
  and the **Intercontinental Cup**. The Supercup is **two-legged**, the Cup Winners' Cup
  holder at home first, on the original's own screen with a `1ST LEG MATCH` / `2ND LEG
  MATCH` block and a real ground each — Camp Nou then Westfalen in 1997-98, straight out of
  the game's own club data. The **Charity Shield** and the **Intercontinental Cup** open on
  the original game's own single-match competition screen — the same screen for both,
  because MANAGER.EXE builds them with the same 1107-byte function and swaps only the title
  and the trophy.
- **Watch a match:** the original's in-match **MATCH OPTIONS** view picker
  (WATCH / HIGHLIGHTS / BRIEF / RESULTS, at the exact button coordinates reversed
  from the executable). **BRIEF** is a minute-by-minute commentary feed (goals,
  cards, saves, corners) in the game's own English match text with real scorers;
  **WATCH** is the **2D graphic simulador** — a side-on stadium built from the
  game's own sprites (players, ball, the PREMIER MANAGER 98 / actua Sports boards,
  crowd, grass and sky), animated over the very same match timeline so the two
  views always agree on the scoreline. (HIGHLIGHTS' 3D engine is CD-only data
  absent from the archive.)
- **Club finances:** income and expenses over a 52-week season, structured on the
  original game's finance ledger (tickets, TV, sponsors, wages).
- **The original screens, rebuilt:** the Title / front-door menu, the Main Menu hub,
  League Tables, Line-Up, Squad, Finances, Transfer Market, the Board of Directors and
  the Stadium are reconstructed at the exact pixel coordinates reversed out of the
  game's executable, using its own icons, fonts and backgrounds (see `docs/re/`). The
  app opens on the real PREMIER MANAGER 98 title screen. Runs in landscape, scaled to
  fit any phone.

## Screenshots

The career hub (the original Main Menu, running a season) and the LINE-UP screen with the
squad, formation and pitch:

<p>
  <img src="screens/hub.png" alt="Career hub — the Main Menu running a season, with Results / League Tables / Fixtures / Line-up / Tactics / Opponent / Transfers / Finances" width="420"/>
  <img src="screens/lineup.png" alt="LINE-UP screen — the full squad with ratings, the chosen XI, the formation and the mini-pitch" width="420"/>
</p>

<sub>PREMIER MANAGER 98, the game this build rebuilds screen-for-screen from the original's
own icons, fonts and backgrounds (the reverse-engineering notes are in `docs/re/`). Original
game © Dinamic Multimedia / Gremlin; shown here for this non-commercial fan remake. On a phone
each screen runs in landscape with a marble bezel in the side margins.</sub>

## Status

This is an early build, but the whole front end is now PREMIER MANAGER 98, not a green
placeholder UI: it opens on the original title screen, the career hub is the original
Main Menu, and the database browse, the new-career club/league pickers and the
2D match view all run in the game's own chrome (marble background, the BARRA bar, the
PROMAN font), routing into the reversed Squad, League Tables and Finances screens. A
couple of deep menus (team tactics, the transfer desk) are still a simpler functional UI.

## Coming next

The stadium works/expansion sub-view and the full position model (injuries, suspensions,
the club news feed, training/player development, the youth team, the backroom staff,
player contracts and wages, European competitions and BOTH domestic cups — the F.A. Cup and
the Coca-Cola Cup — are now in). The 2D
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
