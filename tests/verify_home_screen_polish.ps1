$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainVillagePath = Join-Path $root "scripts\main_village.gd"
$settingsPath = Join-Path $root "scripts\settings_panel.gd"

$mainVillage = Get-Content -Raw -Path $mainVillagePath
$settings = Get-Content -Raw -Path $settingsPath

function Assert-Contains {
    param([string]$Text, [string]$Needle, [string]$Name)
    if (-not $Text.Contains($Needle)) {
        throw "$Name is missing: $Needle"
    }
}

function Assert-NotContains {
    param([string]$Text, [string]$Needle, [string]$Name)
    if ($Text.Contains($Needle)) {
        throw "$Name should not contain: $Needle"
    }
}

Assert-Contains $mainVillage "_make_resource_panel" "main_village.gd"
Assert-Contains $mainVillage "_make_restoration_panel" "main_village.gd"
Assert-Contains $mainVillage "_refresh_attention_indicators" "main_village.gd"
Assert-Contains $mainVillage "_add_attention_marker" "main_village.gd"
Assert-Contains $mainVillage "_add_tappable_glow" "main_village.gd"
Assert-Contains $mainVillage "_make_nav_button" "main_village.gd"
Assert-Contains $mainVillage "_add_tree_restoration_badge" "main_village.gd"
Assert-NotContains $mainVillage "_make_small_button(`"Save`"" "main_village.gd"
Assert-NotContains $mainVillage "_make_small_button(`"Load`"" "main_village.gd"

Assert-Contains $settings "Save Game" "settings_panel.gd"
Assert-Contains $settings "Load Game" "settings_panel.gd"
Assert-Contains $settings "Reset Save" "settings_panel.gd"

Write-Host "MysticGrove_Godot home screen polish verification passed"
