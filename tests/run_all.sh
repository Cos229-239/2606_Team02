#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-}"

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

tests=(
  tests/abandoned_nook_onboarding_behavior.gd
  tests/arcane_forge_polish_behavior.gd
  tests/audio_system_behavior.gd
  tests/balance_and_save_behavior.gd
  tests/bottom_navigation_behavior.gd
  tests/building_quest_hooks_behavior.gd
  tests/building_systems_behavior.gd
  tests/fairy_worker_assignment_behavior.gd
  tests/flower_grove_merge_grid_behavior.gd
  tests/flower_grove_upgrade_behavior.gd
  tests/inventory_behavior.gd
  tests/main_menu_reset_confirmation_behavior.gd
  tests/main_village_tutorial_gate_behavior.gd
  tests/market_stall_polish_behavior.gd
  tests/pond_decoration_behavior.gd
  tests/pond_decorate_visual_behavior.gd
  tests/panel_interaction_polish_behavior.gd
  tests/potion_shop_behavior.gd
  tests/quest_panel_polish_behavior.gd
  tests/quest_system_behavior.gd
  tests/reset_save_onboarding_shows_tutorial_behavior.gd
  tests/reset_save_reopens_tutorial_behavior.gd
  tests/sacred_pond_panel_completion_behavior.gd
  tests/sacred_pond_level_rewards_behavior.gd
  tests/save_compatibility_behavior.gd
  tests/settings_panel_polish_behavior.gd
  tests/tutorial_layering_behavior.gd
  tests/building_panels_scene_load.gd
)

for test_script in "${tests[@]}"; do
  echo "==> $test_script"
  output_file="$(mktemp)"
  status=0
  "$GODOT_BIN" --headless --path "$PROJECT_ROOT" --script "$test_script" -- --no-save >"$output_file" 2>&1 || status=$?
  cat "$output_file"
  if [[ $status -ne 0 ]] || grep -Eq "SCRIPT ERROR|ERROR: Failed to load script|Parse Error|Compile Error|Assertion failed" "$output_file"; then
    rm -f "$output_file"
    echo "Test failed: $test_script" >&2
    exit 1
  fi
  rm -f "$output_file"
done

echo "All Godot behavior tests passed."
