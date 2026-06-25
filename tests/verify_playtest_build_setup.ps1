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

Assert-FileContains "project.godot" 'run/main_scene="res://scenes/MainMenu.tscn"'
Assert-FileContains "scenes/MainMenu.tscn" "MainMenu"
Assert-FileContains "scripts/main_menu.gd" "Play"
Assert-FileContains "scripts/main_menu.gd" "Continue"
Assert-FileContains "scripts/main_menu.gd" "Reset Save"
Assert-FileContains "scripts/main_menu.gd" "Quit"
Assert-FileContains "scripts/main_menu.gd" "Build:"
Assert-FileContains "scripts/game_state.gd" "func save_exists"
Assert-FileContains "scripts/game_state.gd" "func reset_save"
Assert-FileContains "scripts/main_village.gd" "Build:"
Assert-FileContains "export_presets.cfg" 'name="Windows Desktop"'
Assert-FileContains "export_presets.cfg" 'platform="Windows Desktop"'
Assert-FileContains "export_presets.cfg" 'export_path="builds/windows_playtest/MysticGrove_Playtest_01.exe"'
Assert-FileContains "data/PLAYTEST_CHECKLIST.md" "Can open Flower Grove"
Assert-FileContains "data/PLAYTEST_CHECKLIST.md" "Quest rewards can be claimed"
Assert-FileContains "data/BUG_REPORT_TEMPLATE.md" "Steps to reproduce"
Assert-FileContains "data/BUG_REPORT_TEMPLATE.md" "Severity: Low / Medium / High / Game-breaking"
Assert-FileContains "data/PLAYTEST_INSTRUCTIONS.md" "How To Launch The Build"
Assert-FileContains "data/PLAYTEST_INSTRUCTIONS.md" "5-10 minutes"
Assert-FileContains "data/PLAYTEST_INSTRUCTIONS.md" "Features Not Included Yet"

Write-Output "MysticGrove_Godot playtest build setup verification passed"
