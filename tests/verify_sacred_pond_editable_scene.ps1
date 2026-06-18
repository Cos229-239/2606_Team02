$ErrorActionPreference = "Stop"

$scenePath = "ui\SacredPondPanel.tscn"
if (!(Test-Path $scenePath)) {
    throw "Missing SacredPondPanel scene."
}

$scene = Get-Content $scenePath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="PondBackground"',
    'name="StatsPanelBackground"',
    'name="StatsLabel"',
    'name="FeedbackLabel"',
    'name="ActionBarBackground"',
    'name="ActionRow"',
    'name="RestoreButton"',
    'name="DecorateButton"',
    'name="UpgradesButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Sacred pond scene is missing editable node marker: $node"
    }
}

if ($scene -notlike '*sacred_pond_zoom.png*') {
    throw "Sacred pond scene is missing the pond zoom background texture."
}

Write-Host "Sacred pond editable scene verification passed."
