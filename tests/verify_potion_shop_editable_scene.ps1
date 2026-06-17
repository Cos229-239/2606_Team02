$ErrorActionPreference = "Stop"

$scenePath = "ui\PotionShopPanel.tscn"
if (!(Test-Path $scenePath)) {
    throw "Missing PotionShopPanel scene."
}

$scene = Get-Content $scenePath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="PotionShopBackground"',
    'name="StatsPanelBackground"',
    'name="StatsLabel"',
    'name="CraftProgressBar"',
    'name="FeedbackLabel"',
    'name="ActionBarBackground"',
    'name="ActionRow"',
    'name="BuyButton"',
    'name="CraftPotionButton"',
    'name="SellPotionButton"',
    'name="UpgradeShopButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Potion Shop scene is missing editable node marker: $node"
    }
}

if ($scene -notlike '*potion_shop_zoom.png*') {
    throw "Potion Shop scene is missing the zoom background texture."
}

Write-Host "Potion Shop editable scene verification passed."
