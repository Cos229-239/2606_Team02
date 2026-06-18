$ErrorActionPreference = "Stop"

$scenePath = "ui\PondDecoratePanel.tscn"
if (!(Test-Path $scenePath)) {
    throw "Missing PondDecoratePanel scene."
}

$scene = Get-Content $scenePath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="PondBackground"',
    'name="TitlePlaque"',
    'name="TitleLabel"',
    'name="PondLayer"',
    'name="DecorationTray"',
    'name="DecorationRow"',
    'name="ActionRow"',
    'name="PlaceButton"',
    'name="RemoveButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Pond decorate scene is missing editable node marker: $node"
    }
}

for ($index = 0; $index -lt 6; $index++) {
    if ($scene -notlike "*name=`"Slot$index`"*") {
        throw "Pond decorate scene is missing editable slot Slot$index."
    }
}

for ($index = 0; $index -lt 4; $index++) {
    if ($scene -notlike "*name=`"DecorationCard$index`"*") {
        throw "Pond decorate scene is missing editable decoration card DecorationCard$index."
    }
}

Write-Host "Pond decorate editable scene verification passed."
