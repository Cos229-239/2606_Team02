$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainVillage = Get-Content -Raw -Path (Join-Path $root "scripts\main_village.gd")
$buildingsPanel = Get-Content -Raw -Path (Join-Path $root "scripts\buildings_panel.gd")

$requiredFiles = @(
    "ui\AncientTreePanel.tscn",
    "ui\ArcaneForgePanel.tscn",
    "ui\MarketStallPanel.tscn",
    "scripts\simple_building_panel.gd"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path $path)) {
        throw "Missing required file: $file"
    }
}

$requiredMainVillageText = @(
    "AncientTreePanelScene",
    "ArcaneForgePanelScene",
    "MarketStallPanelScene",
    "_open_ancient_tree",
    "_open_arcane_forge",
    "_open_market_stall",
    "_add_placeholder_area_button(`"Ancient Tree`"",
    "_add_placeholder_area_button(`"Market Stall`"",
    "_show_panel(AncientTreePanelScene.instantiate())",
    "_show_panel(ArcaneForgePanelScene.instantiate())",
    "_show_panel(MarketStallPanelScene.instantiate())"
)

foreach ($text in $requiredMainVillageText) {
    if (-not $mainVillage.Contains($text)) {
        throw "main_village.gd is missing: $text"
    }
}

$requiredBuildingsText = @(
    "`"Ancient Tree`"",
    "`"Market Stall`"",
    "`"Arcane Forge`"",
    "Restoration landmark and grove story placeholder.",
    "Orders and trading placeholder.",
    "Craft gear, enhance it with crystals, and upgrade the forge."
)

foreach ($text in $requiredBuildingsText) {
    if (-not $buildingsPanel.Contains($text)) {
        throw "buildings_panel.gd is missing: $text"
    }
}

Write-Host "All visible home buildings have clickable screens wired."
