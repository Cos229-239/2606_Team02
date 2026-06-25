$ErrorActionPreference = "Stop"

function Assert-PathExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Missing required path: $Path"
    }
}

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$requiredDirs = @(
    "assets/sprites/environment",
    "assets/sprites/buildings",
    "assets/sprites/ui",
    "assets/sprites/characters",
    "assets/sprites/effects",
    "assets/audio/sfx",
    "assets/audio/music",
    "data"
)

foreach ($dir in $requiredDirs) {
    Assert-PathExists $dir
}

$requiredAssets = @(
    "assets/sprites/environment/tree_round.png",
    "assets/sprites/environment/path_straight.png",
    "assets/sprites/environment/grass_flowers.png",
    "assets/sprites/environment/mushroom_red.png",
    "assets/sprites/buildings/cottage_door.png",
    "assets/sprites/buildings/cottage_window.png",
    "assets/sprites/ui/panel_border_ornate.png",
    "assets/sprites/characters/fairy_placeholder.png",
    "assets/sprites/effects/glow_orb.png"
)

foreach ($asset in $requiredAssets) {
    Assert-PathExists $asset
}

Assert-FileContains "data/ASSET_CREDITS.md" "Kenney - Tiny Town"
Assert-FileContains "data/ASSET_CREDITS.md" "Kenney - Fantasy UI Borders"
Assert-FileContains "data/ASSET_CREDITS.md" "Creative Commons CC0"
Assert-FileContains "scripts/main_village.gd" "res://assets/sprites/environment/tree_round.png"
Assert-FileContains "scripts/flower_grove_panel.gd" "res://assets/sprites/environment/grass_flowers.png"
Assert-FileContains "scripts/sacred_pond_panel.gd" "res://assets/sprites/ui/panel_border_ornate.png"
Assert-FileContains "scripts/fairy_house_panel.gd" "res://assets/sprites/buildings/cottage_door.png"

Write-Output "MysticGrove_Godot milestone 3 asset verification passed"
