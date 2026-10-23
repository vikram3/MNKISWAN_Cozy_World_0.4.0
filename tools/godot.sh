#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${GODOT_BIN:-}" ]]; then
  if [[ -x /workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 ]]; then
    GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
  else
    GODOT_BIN=$(command -v godot || command -v godot4)
  fi
fi
# Cloud sandboxes have a read-only home; keep editor and game data in a writable root.
if [[ -d /workspace && -z "${XDG_DATA_HOME:-}" && ! -w "$HOME/.local/share" ]]; then
  export XDG_DATA_HOME=/workspace/.runtime/data
  export XDG_CONFIG_HOME=/workspace/.runtime/config
  export XDG_CACHE_HOME=/workspace/.runtime/cache
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
fi
if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  mkdir -p "$XDG_DATA_HOME"
fi
if [[ -d /workspace && -z "${XDG_CACHE_HOME:-}" ]]; then
  export XDG_CACHE_HOME=/workspace/.runtime/cache
  mkdir -p "$XDG_CACHE_HOME"
fi
if [[ "$($GODOT_BIN --version)" != 4.7.2.* ]]; then
  echo 'Godot 4.7.2 is required. Set GODOT_BIN to its executable.' >&2
  exit 1
fi
exec "$GODOT_BIN" --path . "$@"
