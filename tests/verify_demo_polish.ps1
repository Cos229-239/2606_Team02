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

Assert-FileContains "scripts/main_menu.gd" "Restore the magic of the grove."
Assert-FileContains "scripts/main_menu.gd" "Build: Demo Build 01"
Assert-FileContains "scripts/main_village.gd" "Build: Demo Build 01"
Assert-FileContains "scripts/main_village.gd" "assign fairies to help"
Assert-FileContains "scripts/main_village.gd" "Craft and sell a potion"
Assert-FileContains "scripts/main_village.gd" "Claim a quest reward"
Assert-FileContains "data/DEMO_NOTES.md" "Core Loop"
Assert-FileContains "data/DEMO_NOTES.md" "Current Features"
Assert-FileContains "data/DEMO_NOTES.md" "Known Limitations"
Assert-FileContains "export_presets.cfg" 'name="Windows Demo"'
Assert-FileContains "export_presets.cfg" 'export_path="builds/windows_demo/MysticGrove_Demo_01.exe"'

Write-Output "MysticGrove_Godot demo polish verification passed"
