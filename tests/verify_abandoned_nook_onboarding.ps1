$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Test-Path $Path)) {
        throw "Missing file $Path"
    }
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

Assert-FileContains "scenes/AbandonedNook.tscn" "res://scripts/abandoned_nook.gd"
Assert-FileContains "scripts/abandoned_nook.gd" "Tap the dead flower to begin"
Assert-FileContains "scripts/abandoned_nook.gd" "Drag matching life together."
Assert-FileContains "scripts/abandoned_nook.gd" "Life returns to the grove."
Assert-FileContains "scripts/abandoned_nook.gd" "+10 Mana"
Assert-FileContains "scripts/abandoned_nook.gd" "complete_onboarding_merge"
Assert-FileContains "scripts/abandoned_nook.gd" "change_scene_to_file(MAIN_VILLAGE_PATH)"
Assert-FileContains "scripts/game_state.gd" "has_completed_onboarding"
Assert-FileContains "scripts/game_state.gd" "first_merge_complete"
Assert-FileContains "scripts/game_state.gd" "func complete_onboarding_merge"
Assert-FileContains "scripts/main_menu.gd" "res://scenes/AbandonedNook.tscn"

Write-Output "MysticGrove_Godot Abandoned Nook onboarding verification passed"
