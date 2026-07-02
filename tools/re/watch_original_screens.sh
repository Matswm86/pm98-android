#!/bin/bash
# Watch the PM98 Wine window and save a PNG every time the screen content changes.
OUT=/home/mats/MWM-AI/projects/pm98-android/screenshots/original-walkthrough-2026-07-02
mkdir -p "$OUT"
last=""
i=0
end=$((SECONDS + 7200))   # 2h cap
while [ $SECONDS -lt $end ]; do
  WIN=$(xdotool search --name "Wine desktop" 2>/dev/null | head -1)
  [ -z "$WIN" ] && { sleep 3; continue; }
  tmp="$OUT/.frame.png"
  DISPLAY=:1 ffmpeg -loglevel error -y -f x11grab -window_id "$WIN" -draw_mouse 0 \
    -i :1 -frames:v 1 "$tmp" 2>/dev/null \
    || { sleep 2; continue; }
  h=$(md5sum "$tmp" | cut -d' ' -f1)
  if [ -n "$h" ] && [ "$h" != "$last" ]; then
    i=$((i + 1))
    cp "$tmp" "$OUT/$(printf '%03d' "$i")_$(date +%H%M%S).png"
    last=$h
  fi
  sleep 1.5
done
