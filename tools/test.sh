#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./tools/godot.sh --headless --editor --import --quit
export XDG_DATA_HOME="$(mktemp -d /tmp/mnkiswan-tests.XXXXXX)"
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
for suite in parse_all playtest flight_switch ui_flow village_life daily_life; do
  test_log="$XDG_DATA_HOME/$suite.log"
  if ! timeout 180 ./tools/godot.sh --headless --fixed-fps 60 "res://tests/$suite.tscn" > "$test_log" 2>&1; then
    cat "$test_log"
    exit 1
  fi
  cat "$test_log"
  # Godot can return success after a script error. Such a run is never a passing test.
  if rg -q 'SCRIPT ERROR|^ERROR:' "$test_log"; then
    exit 1
  fi
done
