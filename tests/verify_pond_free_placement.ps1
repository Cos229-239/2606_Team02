$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param(
        [string]$Path,
        [string]$Needle
    )
    $content = Get-Content -Raw -Path $Path
    if ($content -notlike "*$Needle*") {
        throw "Missing expected pond free placement support in $Path`: $Needle"
    }
}

Assert-FileContains "scripts/game_state.gd" "POND_DECORATION_EDITOR_RECT"
Assert-FileContains "scripts/game_state.gd" "func place_pond_decoration_at"
Assert-FileContains "scripts/game_state.gd" "func move_pond_decoration"
Assert-FileContains "scripts/game_state.gd" "func get_pond_decoration_screen_position"
Assert-FileContains "scripts/game_state.gd" "func get_pond_decoration_normalized_position"
Assert-FileContains "scripts/game_state.gd" '"PositionX"'
Assert-FileContains "scripts/game_state.gd" '"PositionY"'

Assert-FileContains "scripts/pond_decorate_panel.gd" "_on_pond_layer_gui_input"
Assert-FileContains "scripts/pond_decorate_panel.gd" "_on_placed_decoration_gui_input"
Assert-FileContains "scripts/pond_decorate_panel.gd" "Tap the pond to place this decoration."
Assert-FileContains "scripts/pond_decorate_panel.gd" "GameState.move_pond_decoration"

Assert-FileContains "scripts/sacred_pond_panel.gd" "_build_decoration_preview_layer"
Assert-FileContains "scripts/sacred_pond_panel.gd" "_refresh_decoration_preview"
Assert-FileContains "scripts/sacred_pond_panel.gd" "GameState.get_pond_decoration_position"

Assert-FileContains "scripts/main_village.gd" "_pond_decoration_world_position"
Assert-FileContains "scripts/main_village.gd" "GameState.get_pond_decoration_screen_position"

Write-Output "MysticGrove_Godot pond free placement verification passed"
