$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainVillageScript = Get-Content -Raw -Path (Join-Path $projectRoot "scripts\main_village.gd")
$sacredPondScript = Get-Content -Raw -Path (Join-Path $projectRoot "scripts\sacred_pond_panel.gd")

$requiredAssets = @(
    "assets\sprites\ui\panel_back.png",
    "assets\sprites\ui\panel_restore.png",
    "assets\sprites\ui\panel_decorate.png"
)

foreach ($asset in $requiredAssets) {
    if (-not (Test-Path (Join-Path $projectRoot $asset))) {
        throw "Missing panel nav button asset: $asset"
    }
}

$requiredMainVillageSnippets = @(
    "func _set_home_nav_visible",
    "_set_home_nav_visible(false)",
    "_set_home_nav_visible(true)",
    "bottom_nav_layer.visible = is_visible"
)

foreach ($snippet in $requiredMainVillageSnippets) {
    if ($mainVillageScript -notlike "*$snippet*") {
        throw "Missing home-nav visibility support: $snippet"
    }
}

$requiredPondSnippets = @(
    "const PANEL_BUTTONS",
    "panel_back.png",
    "panel_restore.png",
    "panel_decorate.png",
    'buttons.add_child(_make_panel_nav_button("Restore", _on_restore_pressed))',
    'buttons.add_child(_make_panel_nav_button("Decorate", _on_decorate_pressed))',
    'buttons.add_child(_make_panel_nav_button("Back", _on_back_pressed))',
    "func _make_panel_nav_button",
    "TextureButton"
)

foreach ($snippet in $requiredPondSnippets) {
    if ($sacredPondScript -notlike "*$snippet*") {
        throw "Missing Sacred Pond panel button support: $snippet"
    }
}

Write-Host "Panel nav button verification passed."
