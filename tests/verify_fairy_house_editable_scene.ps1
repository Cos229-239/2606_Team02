$ErrorActionPreference = "Stop"

$scenePath = "ui\FairyHousePanel.tscn"
if (!(Test-Path $scenePath)) {
    throw "Missing FairyHousePanel scene."
}

$scene = Get-Content $scenePath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="FairyHouseBackground"',
    'name="StatsPanelBackground"',
    'name="StatsLabel"',
    'name="WorkersTitle"',
    'name="FairyCardsScroll"',
    'name="FairyCardsContainer"',
    'name="FeedbackLabel"',
    'name="ActionBarBackground"',
    'name="ActionRow"',
    'name="UpgradeHouseButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Fairy House scene is missing editable node marker: $node"
    }
}

if ($scene -notlike '*fairy_house_zoom.png*') {
    throw "Fairy House scene is missing the zoom background texture."
}

Write-Host "Fairy House editable scene verification passed."
