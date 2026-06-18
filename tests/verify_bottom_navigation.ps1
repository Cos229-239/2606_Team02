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

$village = "scripts/main_village.gd"

Assert-FileContains $village "ExplorePanelScene"
Assert-FileContains $village "BuildingsPanelScene"
Assert-FileContains $village "SettingsPanelScene"
Assert-FileContains $village "_open_map"
Assert-FileContains $village "_open_explore"
Assert-FileContains $village "_open_buildings"
Assert-FileContains $village "_open_settings"
Assert-FileContains $village "open_building_requested"
Assert-FileContains $village "bottom_nav_layer"
Assert-FileContains $village "bottom_nav_layer.layer = 30"
Assert-FileContains $village "panel_layer.layer = 10"
Assert-FileContains $village "open_nav_panel"
Assert-FileContains $village "close_all_panels"
Assert-FileContains $village 'open_nav_panel("Quests")'
Assert-FileContains $village 'open_nav_panel("Settings")'

Assert-FileContains "ui/ExplorePanel.tscn" "ExplorePanel"
Assert-FileContains "scripts/explore_panel.gd" "Forest Trail: Locked"
Assert-FileContains "scripts/explore_panel.gd" "Moonlit Clearing: Locked"
Assert-FileContains "scripts/explore_panel.gd" "Crystal Hollow: Locked"
Assert-FileContains "scripts/explore_panel.gd" "Exploration coming soon."

Assert-FileContains "ui/BuildingsPanel.tscn" "BuildingsPanel"
Assert-FileContains "scripts/buildings_panel.gd" "Flower Grove"
Assert-FileContains "scripts/buildings_panel.gd" "Sacred Koi Pond"
Assert-FileContains "scripts/buildings_panel.gd" "Fairy House"
Assert-FileContains "scripts/buildings_panel.gd" "Potion Shop"
Assert-FileContains "scripts/buildings_panel.gd" "Ancient Tree"
Assert-FileContains "scripts/buildings_panel.gd" "Market Stall"
Assert-FileContains "scripts/buildings_panel.gd" "Arcane Forge"
Assert-FileContains $village "_open_ancient_tree"
Assert-FileContains $village "_open_market_stall"
Assert-FileContains $village "_open_arcane_forge"

Assert-FileContains "ui/SettingsPanel.tscn" "SettingsPanel"
Assert-FileContains "scripts/settings_panel.gd" "Music Volume"
Assert-FileContains "scripts/settings_panel.gd" "SFX Volume"
Assert-FileContains "scripts/settings_panel.gd" "Tutorial On"
Assert-FileContains "scripts/settings_panel.gd" "Save Game"
Assert-FileContains "scripts/settings_panel.gd" "Load Game"
Assert-FileContains "scripts/settings_panel.gd" "Reset Save"
Assert-FileContains "scripts/settings_panel.gd" "Credits"
Assert-FileContains "scripts/settings_panel.gd" "ASSET_CREDITS.md"

Assert-FileContains "scripts/game_state.gd" "music_volume"
Assert-FileContains "scripts/game_state.gd" "sfx_volume"
Assert-FileContains "scripts/game_state.gd" '"music_volume"'
Assert-FileContains "scripts/game_state.gd" '"sfx_volume"'

Write-Output "MysticGrove_Godot bottom navigation verification passed"
