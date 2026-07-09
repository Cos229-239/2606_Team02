#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-}"
MODE="${1:-launch}"

if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  elif [[ -x "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT_BIN="$HOME/Downloads/Godot.app/Contents/MacOS/Godot"
  else
    echo "Godot executable not found. Set GODOT_BIN=/path/to/Godot." >&2
    exit 127
  fi
fi

usage() {
  echo "Usage: $0 [launch|test|export-macos]"
}

case "$MODE" in
  test)
    "$PROJECT_ROOT/tests/run_all.sh"
    ;;
  launch)
    "$PROJECT_ROOT/tests/run_all.sh"
    "$GODOT_BIN" --path "$PROJECT_ROOT"
    ;;
  export-macos)
    "$PROJECT_ROOT/tests/run_all.sh"
    mkdir -p "$PROJECT_ROOT/builds/macos_playtest"
    "$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "macOS Playtest" "$PROJECT_ROOT/builds/macos_playtest/MysticGrove_Playtest_01.zip"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
