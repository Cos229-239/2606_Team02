$ErrorActionPreference = "Stop"

$scenePath = "ui\FlowerGrovePanel.tscn"
if (!(Test-Path $scenePath)) {
    throw "Missing FlowerGrovePanel scene."
}

$scene = Get-Content $scenePath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="FlowerGroveBackground"',
    'name="TitlePlaque"',
    'name="StoredManaPanel"',
    'name="ProductionPanel"',
    'name="GardenPreviewLayer"',
    'name="MergeGridPanel"',
    'name="MergeGrid"',
    'name="StatsPanelBackground"',
    'name="StatsLabel"',
    'name="FeedbackLabel"',
    'name="ActionBarBackground"',
    'name="ActionRow"',
    'name="CollectManaButton"',
    'name="UpgradeFlowerButton"',
    'name="UnlockPlotButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Flower Grove scene is missing editable node marker: $node"
    }
}

for ($index = 0; $index -lt 12; $index++) {
    if ($scene -notlike "*name=`"GridSlot$index`"*") {
        throw "Flower Grove scene is missing editable grid slot GridSlot$index."
    }
}

if ($scene -notlike '*flower_grove_background.png*') {
    throw "Flower Grove scene is missing the new Flower Grove background texture."
}

$requiredTextures = @(
    'flower_grove_title.png',
    'plot_tap_to_plant.png',
    'plot_locked.png',
    'button_collect_mana.png',
    'button_upgrade_grove.png',
    'button_unlock_plot.png',
    'button_back.png'
)

foreach ($texture in $requiredTextures) {
    if ($scene -notlike "*$texture*") {
        throw "Flower Grove scene is missing texture marker: $texture"
    }
}

Write-Host "Flower Grove editable scene verification passed."
