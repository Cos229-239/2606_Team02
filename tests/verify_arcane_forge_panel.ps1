$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

function Assert-FileExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Missing file $Path"
    }
}

$state = "scripts/game_state.gd"
$panel = "scripts/arcane_forge_panel.gd"
$scene = "ui/ArcaneForgePanel.tscn"
$assetRoot = "assets/sprites/arcane_forge"

Assert-FileContains $state "signal arcane_forge_changed"
Assert-FileContains $state "arcane_forge_level"
Assert-FileContains $state "func craft_forge_gear"
Assert-FileContains $state "func enhance_forge_gear"
Assert-FileContains $state "func upgrade_arcane_forge"

Assert-FileContains $scene "ArcaneForgePanel"
Assert-FileContains $scene "arcane_forge_panel.gd"

Assert-FileExists "$assetRoot/arcane_forge_background.png"
Assert-FileExists "$assetRoot/forge_craft_card.png"
Assert-FileExists "$assetRoot/forge_gear_card.png"
Assert-FileExists "$assetRoot/forge_upgrades_card.png"
Assert-FileExists "$assetRoot/forge_enhance_card.png"
Assert-FileExists "$assetRoot/forge_back_card.png"
Assert-FileExists "$assetRoot/forge_fairy_workbench.png"
Assert-FileExists "$assetRoot/forge_anvil_focus.png"

Assert-FileContains $panel "arcane_forge_background.png"
Assert-FileContains $panel "forge_fairy_workbench.png"
Assert-FileContains $panel "forge_anvil_focus.png"
Assert-FileContains $panel "Craft"
Assert-FileContains $panel "Gear"
Assert-FileContains $panel "Upgrades"
Assert-FileContains $panel "Enhance"
Assert-FileContains $panel "Back"

Write-Output "MysticGrove_Godot Arcane Forge panel verification passed"
