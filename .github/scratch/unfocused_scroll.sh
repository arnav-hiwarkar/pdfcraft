#!/usr/bin/env bash
set -uo pipefail
set -x
out=shots
mkdir -p "$out"
openbox & sleep 2
xterm -geometry 80x40+700+0 -title OTHERAPP & sleep 2
"$APP" sample.pdf > app.log 2>&1 &
app_pid=$!
app_win=""
for _ in $(seq 60); do
  app_win=$(xdotool search --onlyvisible --pid "$app_pid" 2>/dev/null | head -1 || true)
  [ -n "$app_win" ] && break
  sleep 1
done
[ -n "$app_win" ] || { echo "app window never appeared"; cat app.log; exit 1; }
other_win=$(xdotool search --onlyvisible --class xterm 2>/dev/null | head -1)
xwininfo -root -tree | grep -E '"' || true
[ -n "$other_win" ] || { echo "xterm window missing"; exit 1; }
xdotool windowsize "$app_win" 700 900 windowmove "$app_win" 0 0
xdotool windowsize "$other_win" 700 900 windowmove "$other_win" 700 0
sleep 6

shoot() { import -window root -crop 700x900+0+0 "$out/$1.png"; }
diffpx() { compare -metric AE "$out/$1.png" "$out/$2.png" null: 2>&1 || true; }
scroll_down() { xdotool click --repeat 6 --delay 80 5; sleep 3; }

xdotool windowactivate --sync "$other_win"; sleep 1
xdotool mousemove 350 450; sleep 2
echo "active window before unfocused scroll: $(xdotool getactivewindow getwindowname)"
shoot unfocused_before
scroll_down
shoot unfocused_after
echo "active window after unfocused scroll: $(xdotool getactivewindow getwindowname)"
u=$(diffpx unfocused_before unfocused_after)

xdotool windowactivate --sync "$app_win"; sleep 2
xdotool mousemove 350 450; sleep 1
echo "active window before focused scroll: $(xdotool getactivewindow getwindowname)"
shoot focused_before
scroll_down
shoot focused_after
f=$(diffpx focused_before focused_after)

{
  echo "### Real app (release build) on Linux X11, openbox click-to-focus"
  echo "- PdfCraft NOT focused, pointer over it, 6 wheel notches: **$u** pixels changed"
  echo "- PdfCraft focused, same scroll: **$f** pixels changed"
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
