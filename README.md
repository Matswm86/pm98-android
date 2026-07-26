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

📦 **[Download the latest APK](https://github.com/Matswm86/pm98-android/releases/download/latest/pm98-46655c7.apk)** — one tap downloads `pm98-46655c7.apk` (current build) straight to your phone.

> **This build (2026-07-26, latest)** is about two things the notes had given up on, and a cheat.
>
> - **The cup draw now happens before the ties are played, the way it does in the real game.** The app used to draw a round and play it in the same instant, so the drum-and-balls screen appeared telling you about matches that had already been decided. Fixing it needed knowing how far ahead the real game draws — which nobody had ever watched. So we watched it: a whole 1997-98 season was played through under Wine with the results screen photographed every couple of weeks. F.A. Cup second round played 14 December, third round drawn and sitting there unplayed on the 20th, still unplayed on the 28th, played on 10 January. The League Cup does the same thing. So there was nothing to guess: the next round is drawn the moment the last one finishes, and it is played on its own weekend. That is now how the app behaves.
> - **The European knockout screens are no longer a mystery.** The notes said this was "genuinely blocked" — the one photograph anyone had showed four ties with nothing played, so nobody knew where the scores went, what the aggregate looked like, or which club got highlighted. The same season-long recording caught **five different layouts**, four of which had never been seen: the plain list, the list with shirts, the four-panel bracket for the quarter-finals, a two-card semi-final view that names the actual stadiums, and the final itself with the trophy and an empty winner's ribbon. All of it is measured and written down. The screens are not built yet, but nothing about them is unknown any more.
> - **Three up front.** Field three forwards and the instant-result engine stops pretending: your chance count is floored and the opposing keeper stops saving. Off by default, switch it on in OPTIONS. It only touches instantly-played matches — watched matches are unaffected — and with it switched off the engine is bit-for-bit what it always was. This one came out of taking the real 1998 program apart to find out why no tactic on the TEAM TACTICS screen can change a scoreline: it turns out that screen is not read by the result engine at all, and a match is capped at three chances a side per half no matter what you do. So we patched the cap out, in the real program first, and then ported the patch.
> - **Two tests that lied.** One went red about one run in three for a reason that had nothing to do with what it was testing, and one printed two engine errors every run and still said everything passed. Both fixed.

> **The build before (2026-07-26, third)** is mostly about things costing the right amount and being the right colour.
>
> - **Improving your ground now costs what the real game charges — at every club, not just two.** Until now the app only knew the prices for the two clubs anyone had ever photographed. Every other club showed an empty price box and you simply could not build. The sum has now been read straight out of the original game's own program code. It charges by how big a club you are, using exactly the same standing that decides what your players are worth and what wages they want, and one formula covers all fifteen kinds of work, from a new stand to more toilets. Every single price anyone has ever photographed — twenty-four of them — comes back out of it exactly. That includes two where the 1998 game's own arithmetic is a pound out (£10,624,999 rather than £10,625,000). We kept the missing pound, because the real game charges it.
> - **The little country flags had the wrong colours.** The notes had this down as "a handful of dithered pixels", which sounded like something you could not fix. It was not dither. The flags were being coloured from the wrong colour table entirely — the game hands Windows its own set of 256 colours, and Windows quietly keeps twenty of them for itself. Using the right table, and letting Windows keep its twenty, all ninety-nine wrong pixels across six screenshots became zero. The shirt graphics are now the only thing on that screen that is still not exact.
> - **The text on the ground-improvement panel was too big, in the wrong place, and one label was the wrong colour.** Measured against four photographs of the real screen, which all agree, and put right. It is now about twice as close as it was. The exact typeface it uses is still not identified, and that is written down rather than glossed over.
> - **The match engine has been checked further into the match.** Two more recordings of the real 1998 game running under a debugger, taken this session on a screen of their own so nothing was disturbed. The remake's copy still matches it exactly: 319,335 numbers compared across eight recordings, none of them different. That takes the checked window from two minutes of football to a little over three. Still nothing you can see — the match you actually play is the simpler engine until the exact one has been checked over a full ninety minutes.
> - **One thing in the notes was simply wrong.** The to-do list still said saving your game was a placeholder message. It has been a proper ten-slot save screen since last week. Checked against the code before repeating it.

> **The build before (2026-07-26, second)** changes nothing you can see. It is about the match engine, and it is good news.
>
> - **The remake's copy of the 1998 match engine is running the original's match, move for move.** Every player's position, which way he is facing, how fast he is going, who is marking whom, where the ball is, where the ball is *going* to be, and the game's own random-number generator — all of it, on every single tick, identical to the real Premier Manager 98 running under an emulator with a debugger attached. Six separate recordings of the real game, taken over several weeks, agree: 223,175 numbers compared, not one of them different.
> - **The thing we thought was broken was never broken.** For two sessions the notes said the two engines disagreed about which way players were facing, and about a moment where the real game stops the ball and gives it to a defender. Both were wrong. The tool doing the comparison was reading the real game at a slightly different moment inside each tick — sometimes half way through a tick, sometimes at the end, depending on what happened that tick. Read at the same instant, the two engines agree exactly. The comparison tool has been rewritten so it can only read at one fixed point per tick, and it now refuses to run at all if that point is not reliable.
> - **Here is the honest limit.** The real game's match clock runs to 14,400 ticks per half. We have recordings of the first 830. That is two minutes of football. So: the engine is exact everywhere we can check, and completely unchecked after minute two. Getting further means sitting the real 1998 game in front of a debugger for hours — about ten seconds of real time per tick of match — which is the next job.
> - **The match you actually play is still the simpler engine.** The exact one is not wired in yet, and will not be until it has been checked over a whole match. Nothing about your saves or your seasons changes with this build.
>
> Also tidied: the project's own "what is left to do" list was five weeks out of date and listed four finished things as unfinished. It is rewritten and every claim in it was checked against the code first.

> **The build before (2026-07-26, first)** gives the European group stage its real screen.
>
> - **RESULTS → Euro. League no longer shows a made-up card.** Where the app used to put an invented summary panel, it now draws the original's own screen: the black `GROUP A` header with the leaders' kit beside it, the four-club table with its country flags and its `PTS P W D L GF GA` columns, that matchday's two results underneath with both clubs' kits, and the six `GROUP A`–`GROUP F` buttons down the right. Tap a group to switch, or step the `Round` arrows through the six matchdays — including the ones that have not been played yet, which the original draws as empty score boxes rather than hiding.
> - **Every pixel of it was checked back against the real game.** Six screenshots of six different groups, taken from a career played through to week 22 in the actual 1998 game, and the remake now matches all six exactly — every name, every number, every score, every button. The only differences left are the shirt graphics themselves, where the original does something to the outline we have not worked out yet, and a handful of stray dots in the little country flags.
> - **One thing we had been told about this screen was simply wrong.** A goal number in each result is printed in yellow, and the obvious reading — that it marks the winner — is not true. Paged through all six matchdays of a group, in two different careers, the yellow always sits in the same two places whoever won. It is copied exactly as the game prints it, and we say plainly in the notes that we do not yet know what it means. It is not a winner marker, and it is not invented into one.

> **The build before (2026-07-25, later)** is about your scout, and about remembering what you have won.
>
> - **Your scout has a limit, and it is the one the game gave him.** We read the search out of the original's own code this time instead of watching it from outside. It scans every player, then keeps only so many: a three-star scout brings back forty names, a five-star one sixty — and which ones he keeps is a straight lottery, not the best of them. A better scout finds you *more*, not better. That number matched a screenshot from a week ago exactly, right down to the size of the scrollbar, which is how we know it is right.
> - **Searching by ROLE now finds everyone who can play there.** A player carries six positions, not one, and the original checks all six. We were only checking his first, so a search for a sweeper missed every defender who *also* plays sweeper.
> - **E.U. PLAYERS and NON E.U. PLAYERS only reach abroad**, as they do in the original — the four division boxes are what reach English clubs. And the game's own list of E.U. countries turned out to be in the executable after all: eighteen of them, exactly the list we had guessed.
> - **New: search by name, and by any of the six skills.** Tap the grey bar along the bottom of the SCOUT screen. Type part of a surname, or ask for HANDLING 80+, SHOOTING 85+, any combination, and sort what comes back. This is ours, not the 1998 game's, and it says so on its own face — and when your scout has had to leave names behind, it tells you how many. *(Honestly: only passing, handling and overall quality actually change match results, so filtering on shooting finds you a better-looking player, not more goals.)*
> - **New: an honours board and a career résumé.** The original shows you a trophy the day you win it and then forgets it forever. Now every season you finish is written down — what you won, what you lost the final of, where you finished, what the board asked for and whether you did it — across every club you manage. Tap your own name on the MANAGER HISTORY screen.
>
> Also fixed: the game's own player card calls RM *dribbling* and RG *heading*; we had those two the wrong way round in the training code, and called speed "pace" and quality "ability", which are not words this game uses.

> **Before that (2026-07-25)** finishes the season the game plays back at you. Four screens the real Premier Manager 98 shows and this remake did not, each rebuilt from the game's own frames and checked back against them pixel by pixel.
>
> - **The cup draw actually happens now.** The draw screen — the trophy, the lottery drum, the round plate, the list of ties — has been in the app for a while with no way to reach it. It now comes up on its own, the way the original does, the moment a round is drawn, for both English cups and all three European ones. And it has the second layout the original has: a short round (sixteen ties or fewer) lays the draw out in a grid with both clubs' kits instead of one line per tie, and **your own tie is picked out on a dark plate with your club in yellow**, so you can find yourself at a glance. Tap a tie and the panel bottom-left fills in with both clubs, both managers and both grounds.
> - **FINANCES has its week-by-week view.** The tab was there; the page behind it was not. You get the real weekly books — seven income lines, eleven expense lines — with a stepper to walk back through the season and the game's own date stamp for each week. While you are on the live week it reads `CURRENT 31`, exactly as the original does, and drops the word once you step back.
> - **THE CHAMPIONSHIPS.** After the trophy cards, the season's eight finals on one sheet with their scorelines, the winner's name in black and the loser's in grey. Nothing is ever shared: a level final went to penalties.
> - **END OF SEASON.** The four-division overview — champion, runner-up, the U.E.F.A. places, who went up and who went down. This is the screen whose *name* our invented board-verdict sheet used to borrow.
> - **PLAYERS OF THE YEAR.** One player of the season per club, ninety-two of them, across four division tabs.
>
> Getting these right also caught three things we had wrong on screens that already shipped: the finance figures were in the wrong typeface throughout, the finance chrome was rubbing out two panel borders, and the U.E.F.A. Cup draw was showing the F.A. Cup's trophy.

> **Earlier this day (2026-07-25)** the season the game plays back at you. I played a whole 1997-98 campaign in the real Premier Manager 98 by hand, recording every screen, and then fixed what the recording caught us getting wrong. Most of it is money.
>
> - **You can go broke now, and that is the point.** The original charges your wage bill every single week and only pays you when you play at home — so an away Saturday is a straight loss and Manchester United's bank falls from £9.6m to £3.3m across a season. Ours added the same tidy profit every week, home or away, and finished sixteen million up. The club's books are now the game's own: seven income lines, eleven expense lines, week by week, and if you run at a loss the board starts counting the weeks out loud.
> - **A ticket costs £7.50.** The game prints capacity, attendance and gate money together on the full-time board, and both grounds I checked came out at exactly seven pounds fifty a head. We were charging fifteen.
> - **A TV station buys the rights to your home matches** and tells you so on its own card before kick-off — £90,000 for a league game, £187,500 for the Charity Shield, £375,000 in the European Cup. That fee is your TELEVISION line for the week. We were paying television money on away weeks and on weeks with no match at all.
> - **The FINANCES screen is real.** Actual weekly figures, an actual last week / this week, and the balance chart is now your own season instead of one number drawn flat.
> - **The cups are the whole country again.** All ninety-two clubs, with the Premier entering at Round 3 — which is how a Division One side can knock you out, or win the thing. Ties are one match with a replay, as the draw card says. There is no prize purse any more: a cup run pays you through the turnstiles, like everything else.
> - **The lower divisions play all forty-six of their matches** and run ahead of you on midweeks, instead of stopping short at thirty-eight and handing out promotions off an unfinished table.
> - **The end of the season is the game's own.** Final tables, then the trophy cards, then the year's top scorers and managers, then next pre-season. The board-verdict screen we used to show you does not exist in the original and is gone.
> - **The Intercontinental Cup is played in December and the European Supercup in March**, each on its own trophy card, instead of both being bolted onto the start of the season.
> - **Two transfer-deadline warnings**, two weeks and one week out, in the game's own words.
> - **Youth training is twice as fast**, to match the scouting — you asked for both halved.

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
- **The club's books, week by week:** the original's own FINANCES ledger — seven income
  lines and eleven expense lines, accrued as the season is played. Your wage bill is
  charged **every** week; the turnstiles and the TV money only come in when you play at
  **home**, so an away Saturday costs you. A TV station buys the rights to each home match
  and says so on its own card. Run at a loss and the board starts counting the weeks.
- **Both domestic cups over the whole country:** all 92 clubs, with the Premier entering at
  **Round 3**, one match per tie and a replay if it's level — so a Division Two side can
  knock you out, and can win it.
- **The season ends the way the original ends it:** the final table of every division, then
  the trophy cards, then the year's top scorers and managers, then next pre-season.
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
