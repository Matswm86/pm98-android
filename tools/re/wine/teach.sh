#!/bin/bash
# Teach one screen and give it a rule in a plan, in one step.
#   teach.sh PLAN NAME ROI FRAME CLICK_X CLICK_Y [SETTLE]
# ROI is X,Y,W,H. Extra teaching frames may follow SETTLE.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLAN="$1"; NAME="$2"; ROI="$3"; FRAME="$4"; CX="$5"; CY="$6"; SETTLE="${7:-1.5}"
shift 7 || shift 6
python3 "$HERE/autodrive.py" learn "$NAME" "$ROI" "$FRAME" "$@"
python3 - "$PLAN" "$NAME" "$CX" "$CY" "$SETTLE" <<'EOF'
import json, sys, pathlib
plan, name, cx, cy, settle = sys.argv[1:6]
p = pathlib.Path(plan)
d = json.loads(p.read_text())
d["rules"][name] = {"click": [int(cx), int(cy)], "settle": float(settle)}
p.write_text(json.dumps(d, indent=1) + "\n")
print(f"rule {name} -> click ({cx},{cy})")
EOF
