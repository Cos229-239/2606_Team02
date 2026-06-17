$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot "scripts\main_village.gd"
$script = Get-Content $scriptPath -Raw

$requiredAssets = @(
    "assets\sprites\ui\nav_map.png",
    "assets\sprites\ui\nav_explore.png",
    "assets\sprites\ui\nav_buildings.png",
    "assets\sprites\ui\nav_quests.png",
    "assets\sprites\ui\nav_settings.png"
)

foreach ($asset in $requiredAssets) {
    $fullPath = Join-Path $projectRoot $asset
    if (!(Test-Path $fullPath)) {
        throw "Missing bottom navigation sprite asset: $asset"
    }
}

$requiredSnippets = @(
    "const NAV_BUTTON_TEXTURES",
    "TextureButton.new()",
    "STRETCH_KEEP_ASPECT_CENTERED",
    "ignore_texture_size = true",
    "quests_badge",
    "_make_quest_badge()"
)

foreach ($snippet in $requiredSnippets) {
    if ($script -notlike "*$snippet*") {
        throw "Missing expected bottom navigation implementation snippet: $snippet"
    }
}

$oldTextButtonPatterns = @(
    '_make_nav_button("Map", "MAP"',
    '_make_nav_button("Explore", "EXP"',
    '_make_nav_button("Buildings", "BLD"',
    '_make_nav_button("Quests", "QST"',
    '_make_nav_button("Settings", "SET"'
)

foreach ($pattern in $oldTextButtonPatterns) {
    if ($script.Contains($pattern)) {
        throw "Temporary text-only bottom navigation label is still present: $pattern"
    }
}

Write-Host "Bottom navigation sprite button verification passed."
