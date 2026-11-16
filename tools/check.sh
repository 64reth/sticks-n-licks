#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${GODOT:-}" ]]; then
  if command -v godot >/dev/null; then GODOT=godot
  else GODOT=/Applications/Godot.app/Contents/MacOS/Godot; fi
fi
mkdir -p output
# Prevent generated captures and dependency trees from entering Godot's asset scan.
touch output/.gdignore .venv/.gdignore 2>/dev/null || true
"$GODOT" --headless --path . --log-file output/import.log --editor --import --quit >output/import.stdout 2>&1
if rg -n 'SCRIPT ERROR|Parse Error|Failed to load' output/import.stdout; then exit 1; fi
"$GODOT" --headless --path . --log-file output/rules.log --script tests/test_rules.gd >output/rules.stdout 2>&1
cat output/rules.stdout
"$GODOT" --headless --path . --log-file output/controls.log --script tests/test_controls.gd >output/controls.stdout 2>&1
cat output/controls.stdout
"$GODOT" --headless --path . --log-file output/media.log --script tests/test_media.gd >output/media.stdout 2>&1
cat output/media.stdout
"$GODOT" --headless --path . --log-file output/launch-range.log --script tests/test_launch_range.gd >output/launch-range.stdout 2>&1
cat output/launch-range.stdout
"$GODOT" --headless --path . --log-file output/idle-movement.log --script tests/test_idle_movement.gd >output/idle-movement.stdout 2>&1
cat output/idle-movement.stdout
"$GODOT" --headless --path . --log-file output/arcade-hud.log --script tests/test_arcade_hud.gd >output/arcade-hud.stdout 2>&1
cat output/arcade-hud.stdout
"$GODOT" --headless --path . --log-file output/smoke.log --quit-after 10 >output/smoke.stdout 2>&1
"$GODOT" --headless --path . --log-file output/demo.log --fixed-fps 60 --scene scenes/tests/demo.tscn --quit-after 3000 -- --verify-demo >output/demo.stdout 2>&1
cat output/demo.stdout
# Godot can return zero on script parse failures; scan the output as well.
if rg -n 'SCRIPT ERROR|Parse Error|Failed to load|Assertion failed' output/{import,rules,controls,media,launch-range,idle-movement,arcade-hud,smoke,demo}.stdout; then exit 1; fi
if ! rg -q '51 checks, 0 failures' output/rules.stdout; then exit 1; fi
if ! rg -q '46 checks, 0 failures' output/controls.stdout; then exit 1; fi
if ! rg -q '3300 checks, 0 failures' output/media.stdout; then exit 1; fi
if ! rg -q '884 checks, 0 failures' output/launch-range.stdout; then exit 1; fi
if ! rg -q '676 checks, 0 failures' output/idle-movement.stdout; then exit 1; fi
if ! rg -q '189 checks, 0 failures' output/arcade-hud.stdout; then exit 1; fi
if ! rg -q 'DEMO: rematch reset' output/demo.stdout; then exit 1; fi
if [[ -x .venv/bin/python ]]; then
  .venv/bin/python -m unittest discover -s tests -p 'test_*.py' -v
else
  echo 'Optional Python asset checks skipped: install tools/requirements.txt in .venv.'
fi

# Slow real-clock lifecycle regression: no phase, position or clock overrides.
"$GODOT" --headless --path . --log-file output/live-movement.log --script tests/test_live_movement.gd --max-fps 120 >output/live-movement.stdout 2>&1
cat output/live-movement.stdout
if rg -n 'SCRIPT ERROR|Parse Error|Failed to load|Assertion failed' output/live-movement.stdout; then exit 1; fi
if ! rg -q 'LIVE MOVEMENT: [0-9]+ checks, 0 failures' output/live-movement.stdout; then exit 1; fi
