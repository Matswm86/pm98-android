#!/usr/bin/env bash
# Deploy web/ to pm98.mwmai.no, pointing the download at the newest APK.
#
# The release tag `latest` accumulates one `pm98-<commit>.apk` per CI build, so
# a hardcoded filename in index.html goes stale on every push. This resolves the
# newest asset from the GitHub API at deploy time and rewrites the three places
# index.html names it, then rsyncs.
#
#   ./web/deploy.sh            # resolve + rewrite + deploy
#   ./web/deploy.sh --local    # resolve + rewrite only, no rsync
set -euo pipefail

REPO=Matswm86/pm98-android
HOST=${PM98_WEB_HOST:-mats@204.168.244.173}
DEST=${PM98_WEB_DEST:-/var/www/pm98/}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$DIR/index.html"

echo "resolving newest APK on $REPO release 'latest' ..."
read -r NAME SIZE UPLOADED < <(
  gh api "repos/$REPO/releases/tags/latest" --jq '
    [.assets[] | select(.name | test("^pm98-.*\\.apk$"))]
    | sort_by(.updated_at) | reverse | .[0]
    | "\(.name) \(.size) \(.updated_at)"'
)
[ -n "${NAME:-}" ] || { echo "no pm98-*.apk asset found" >&2; exit 1; }

MB=$(awk -v b="$SIZE" 'BEGIN{printf "%.1f", b/1000000}')
DATE=$(date -u -d "$UPLOADED" +'%-d %b %Y')
COMMIT=${NAME#pm98-}; COMMIT=${COMMIT%.apk}
echo "  -> $NAME  ${MB} MB  uploaded $DATE"

python3 - "$HTML" "$NAME" "$MB" "$DATE" "$COMMIT" <<'PY'
import re, sys
html, name, mb, date, commit = sys.argv[1:6]
s = open(html, encoding='utf-8').read()
before = s
s = re.sub(r'pm98-[0-9a-f]{7,40}\.apk', name, s)
s = re.sub(r'&middot; [\d.]+&nbsp;MB &middot; build <code>[0-9a-f]{7,40}</code>',
           '&middot; %s&nbsp;MB &middot; build <code>%s</code>' % (mb, commit), s)
s = re.sub(r'<div>uploaded [^&]*&middot;', '<div>uploaded %s &middot;' % date, s)
s = re.sub(r'<span class="sub">latest build &middot;[^<]*</span>',
           '<span class="sub">latest build &middot; %s</span>' % date, s)
open(html, 'w', encoding='utf-8').write(s)
print('index.html: unchanged' if s == before else 'index.html: rewritten')
PY

[ "${1:-}" = "--local" ] && { echo "--local: not deploying"; exit 0; }

rsync -a --delete --exclude deploy.sh --exclude README.md "$DIR/" "$HOST:$DEST"
echo "deployed -> https://pm98.mwmai.no/"
curl -sS -o /dev/null -w "  live: HTTP %{http_code}, %{size_download} B\n" https://pm98.mwmai.no/
