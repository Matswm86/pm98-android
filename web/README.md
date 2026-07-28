# web/ — pm98.mwmai.no

The public site for the project. Plain static files, no build step.

```
index.html        every screen, all of them in the one document
style.css         PM98 chrome — palette taken off screens/hub.png + screens/title.png
app.js            the screen router, the squad-book table browser, the APK lookup
fonts/*.woff2     Oswald + Barlow, latin subsets, self-hosted (see "Fonts")
data/players.json 9,547 rated players, ranked on the three fields the instant
                  engine reads, priced from the executable's own fee/wage tables
data/value_tables.json   a copy of docs/re/value_tables.json, for reference
img/*.png         640x480 captures of the REAL 1998 PC GAME, copied from
                  ../screenshots/ (original-walkthrough + wine-captures).
                  ONLY original-game frames go here — never a capture of the
                  Android port, and never a mock-up.
img/*.webp        the same frames upscaled, used as full-bleed backgrounds;
                  img/hi/ holds the 1280/1920/2560 ladder and the @4x master.
                  Only the four the page serves are committed; img/hi/ is 34 MB
                  and lives on the workstation.
```

### One repaired frame

`bg_menu` came off the upscaler with two hard-edged slabs of duplicated plate
texture smeared across the INFORMATION band, the EXIT/SAVE GAME rail and the
FINANCES band — corruption in the capture the upscale was fed, not something the
1998 game ever drew. `img/hub.png`, the clean 640x480 frame of the same screen,
is the authority. The repair pastes `hub.png` back over exactly those two
rectangles of `img/hi/bg_menu@4x.png`, Gaussian-feathered, then re-derives the
1280/1920/2560 ladder from the master:

```
rects (fractions of the frame) = (.292,.400,.348,.562) and (.652,.512,.712,.660)
feather = width * 0.004
```

If the ladder is ever regenerated from a fresh upscale, the slabs come back and
the repair has to be re-applied. Nothing else in `img/` is retouched.

## The shell

The site wears the game rather than describing it. Three layers:

* **the front door** — `img/start_screen.webp`, the real 1998 title screen, with
  its three ovals made live: MANAGER MENU, SQUAD BOOK, DOWNLOAD.
* **the hub** — `img/bg_menu.webp`, the real MANAGER MENU, with a button sitting
  on each of the game's own sixteen plates and the site's club plate filling the
  centre disc. The disc's box is the circle's bounding box measured off the art:
  centre 50%/54%, rx 16.4%, ry 22.2%.
* **the screens** — Start, Download, The game, Beat it, Money, Squad book,
  Sources, on the marble the game's dialogues sit on.

State is the URL hash, so every screen is still linkable and the back button
works: `#menu`, `#start`, `#build`, `#beat`, `#money`, `#book`, `#sources`,
`#download`. `#hack` still lands on the three-up-front card, as it did when the
site was one long page.

### The board, and why there is no phone fallback

**Do not re-add a stacked, CSS-drawn version of the front door or the hub for
small screens.** One existed for a day and was rejected on sight: a phone got
coloured `<div>`s where the game should be. The captured screen is the layout, at
every width. If a viewport cannot show the real art, it shows the real art
smaller — it never shows a reconstruction.

Both boards are `.board` inside `.board-slot` inside `.board-fit`. The board is
always 4:3 and always fitted to the viewport; everything inside it is sized in
`cqw` off a `container-type: inline-size`, so the geometry never drifts from the
percentages measured off the art. `--reserve` is whatever sits under the board on
that screen (78px on the front door for the legal line, 40px on the hub).

A **portrait phone turns the board sideways** rather than shrinking it to a strip:
`transform: rotate(90deg)` with the slot's width and height swapped. 4:3 across a
390px screen is 293px tall; rotated it is ~520px along its long edge, a third more
board in every direction. It is also already the right way up the moment the phone
is turned, whether or not rotation lock is on — and if the OS does rotate, the
`orientation: landscape` query drops the transform and the board simply fits.

The surround is the same screen, blurred and dimmed (`.splash-shade`,
`.menu-shade`), so the window is filled with the game and nothing invented.

## Fonts

Oswald and Barlow, self-hosted under `fonts/`, latin subsets only. They are NOT
loaded from fonts.googleapis.com: the vhost CSP is `style-src 'self'` and
`font-src 'self'`, so a Google Fonts `<link>` is blocked outright, and the page
otherwise makes no third-party request at all. Oswald ships as one variable file
(`font-weight: 200 700`); Barlow as one file per weight used.

To refresh them, fetch the css2 stylesheet with a browser user-agent, keep only
the `/* latin */` `@font-face` blocks, and download those woff2 URLs.

## Deploy

```bash
./web/deploy.sh            # resolve newest APK -> rewrite index.html -> rsync
./web/deploy.sh --local    # rewrite only, no rsync
```

CI uploads one `pm98-<commit>.apk` per build to the `latest` release, so a
hardcoded filename goes stale on every push. Two layers handle that:

* **At page load**, `app.js` asks the GitHub API for the newest `pm98-*.apk` on
  the `latest` release and repoints the button and the file line. This is what
  keeps the link correct between deploys — including for the build produced by
  the very commit that deployed the page. Needs `connect-src https://api.github.com`
  in the vhost CSP.
* **At deploy time**, `deploy.sh` bakes the then-newest filename into
  `index.html` — the download button, `#dlmeta`, the band's `latest build` line,
  and the hub's build plate (`#buildline-*`, `#builddate-*`) — so the page is
  still right if the API call fails (unauthenticated, 60 requests/hour per IP)
  or JavaScript is off.

Regression test for the first layer: bake a bogus filename into a copy of
`index.html`, serve it, and confirm the DOM's `#dlbtn` href comes back pointing
at the real newest APK.

Served by Caddy from `/var/www/pm98` under a `pm98.mwmai.no` vhost. The CSP is
strict — `script-src 'self'; style-src 'self'; font-src 'self'`, no
`unsafe-inline` — so **do not add inline `style="..."` attributes or inline
`<script>`**, in the HTML or emitted from `app.js`, and do not link a webfont
from a CDN. Add a class to `style.css` instead. A violation shows up as an
unstyled element on the live site only, never locally over `file://`.

## Content provenance

Every formula quoted on the page is from `docs/re/`:

| Page section | Source |
|---|---|
| The two engines, the six fields, chance/keeper arithmetic | `stat_match_engine_re.md` |
| The four view modes (WATCH/HIGHLIGHTS/BRIEF/RESULTS) | `match_view_re.md`, `match_flow_re.md` |
| Three-up-front cheat | `hack_three_forwards.md` |
| Fee/wage table, stature bands, age tiers | `transfer_value_re.md`, `value_tables.json` |
| Insurance premium/payout/hospital arithmetic | `insurance_economy_re.md` |
| Ground improvement costs | `stadium_screen_re.md` §"The cost function" |
| UEFA prize schedule, ledger structure | `finance_constants.md`, `finance_screen_re.md` |
| Sack schedule and thresholds | `sack_path_re.md` |
| Morale/fitness deltas, RATING formula | `morale_re.md` |
| Scout cap and search semantics | `scout_screen_re.md` |
| Youth academy | `youth_re.md` |
| Staff roles and which ones are no-ops | `staff_re.md` |

If one of those docs is corrected, the page must be corrected with it.
