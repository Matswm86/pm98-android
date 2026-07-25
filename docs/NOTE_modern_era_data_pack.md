# NOTE — a modern-era data pack (2026-27), scoping only (2026-07-25)

**Status: NOT a plan and NOT authorised.** Mats raised the idea, set its scope, and asked for a
note to pick up later. Nothing here is approved to build. Write the real plan from this.

## The idea

A **start-date / era choice at career creation**, so a career can begin in **August 2026** with
real modern squads instead of 1997-98. Data sourced from Football Manager once the FM community
has updated it, the same route already used for youth intakes in later seasons.

## Scope, as Mats set it

> "Prize money, economy and european competitions stay the way they are originally.
> Only database changes and dates basically."

So **out of scope**: the UEFA prize table, the channelTV fees, the wage/gate economy, the
European competition structure (Cup Winners' Cup and all), the Charity Shield, the
Intercontinental Cup. All stay exactly as the original has them.

**In scope**: the player/club database, the dates, and the strings that name things.

Facepacks from FM: **wanted eventually, explicitly not a priority.**

## The one consequence of that scope that must be designed for

Keeping the 1997 economy while importing 2026 squads means **the money columns in the imported
database have to be 1997-scaled too**, or the two halves fight each other. The original pays
£90,000 for a televised league home game and charges Manchester Utd. £233,942 a week in wages;
Andy Cole's club fee is £8.5M and his wage £575,000 a year. If FM's £150M valuations and
£300,000-a-week wages come across untouched, the transfer market and the running-at-a-loss
mechanic both break instantly.

So the conversion must map **fees and wages down onto the 1997 scale**, alongside the attribute
mapping. That is a data-pack concern, not an economy change, and it keeps Mats's scope intact.

## What is genuinely cheap

- **The pyramid is unchanged.** 2026-27 England is still 20 / 24 / 24 / 24, so the 38-round and
  46-round seasons, the promotion/relegation zones and the play-offs all work untouched.
- **Dates are a constant and a string.** `Career.gd:24` `season: String = "1997-98"`,
  `Career.gd:3246` `start_year := 1997`, and the calendar is anchored at Sat 9 Aug 1997 in
  `PMChrome.date_parts`. Real 2026-27 opens around 15 Aug 2026.
- **No real fixture list is needed.** Finding O2 of the reference run: the port already builds
  its calendar with `SeasonSim._round_robin` and dates it `season_start + round*7`, i.e. the
  pairings are invented. That is a fidelity gap for 1997-98 but a convenience here.
- **`game_db.json` is already a swappable artefact** carrying its own `meta.season`. An era pack
  is a second file plus a manifest, not a fork.
- **Division names are strings**: Division One / Two / Three -> Championship / League One /
  League Two.

## Known gaps to design for

| gap | where | note |
|---|---|---|
| **E.U. member list is hardcoded EU-15** | `Career.gd:2334` | needs EU-27, and post-Brexit the scout's E.U. / NON E.U. filter inverts for English clubs |
| **The youth pool is 51 shipped 1997 players** | club `0x26e4`, `Youth.gd` | a 2026 pack needs its own pool; the scout returns one at random from it |
| **The wonderkid easter egg is a named 1997-era planted player** | `Youth.WONDERKID_NAME` | decide whether it carries over |
| **Coarse position does not follow from fine role** | see `SPEC_scout_attribute_search.md` | roles 13/16/17 are held mostly by coarse-`MF` players; an importer must set both bytes, not derive one |
| **Attribute mapping is the real design work** | — | FM is ~35 attributes on 1-20; this game is 10 on 0-99: SPEED, STAMINA, AGGRESSION, QUALITY (their mean is the engine's strength and the on-screen `AV`), plus HANDLING, PASSING, DRIBBLING, HEADING, TACKLING, SHOOTING. Only the first four, PASSING and HANDLING affect results. The youth-intake precedent already does a version of this — reuse it. |

## Art, when it becomes a priority

Target formats, measured from the shipped assets:

- **faces** — three variants, all needed per player:
  - `app/art/faces/*.png` — **124 x 182**, palettised (`P`), 613 files
  - `app/art/faces/dbcard/*.png` — **124 x 182**, `RGB`, 612 files
  - `app/art/faces/mini/*.png` — **32 x 32**, palettised (`P`), 690 files
- **kits** — `app/art/kits/*.png`, **48 x 64**, RGBA
- flags: `app/art/flags/`

FM facepacks ship as PNGs keyed by FM player UID, so a converter needs: FM UID -> this game's
`photoId`, then resize to 124 x 182 and quantise to the game's palette. The join key is the
hard part, not the image work. Majors only, as Mats said.

## Faithfulness

This is a large deviation and must never mix with the vanilla career:
[[feedback_pm98_stay_true_to_original]]. Make the era a career-creation choice **stamped into
the save**, so a 1997-98 save can never load a 2026 database, and label the pack ours in code
the way `Youth.SEARCH_SPEEDUP` is labelled.
