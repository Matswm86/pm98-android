# web/ — pm98.mwmai.no

The public site for the project. Plain static files, no build step.

```
index.html        the page
style.css         PM98 chrome — palette taken off screens/hub.png + screens/title.png
app.js            the squad-book table browser
data/players.json 9,547 rated players, ranked on the three fields the instant
                  engine reads, priced from the executable's own fee/wage tables
data/value_tables.json   a copy of docs/re/value_tables.json, for reference
img/*.png         640x480 captures of the REAL 1998 PC GAME, copied from
                  ../screenshots/ (original-walkthrough + wine-captures).
                  ONLY original-game frames go here — never a capture of the
                  Android port, and never a mock-up.
```

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
  `index.html`, so the page is still right if the API call fails (unauthenticated,
  60 requests/hour per IP) or JavaScript is off.

Regression test for the first layer: bake a bogus filename into a copy of
`index.html`, serve it, and confirm the DOM's `#dlbtn` href comes back pointing
at the real newest APK.

Served by Caddy from `/var/www/pm98` under a `pm98.mwmai.no` vhost. The CSP is
strict — `script-src 'self'; style-src 'self'`, no `unsafe-inline` — so **do not
add inline `style="..."` attributes or inline `<script>`**, in the HTML or emitted
from `app.js`. Add a class to `style.css` instead. A violation shows up as an
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
