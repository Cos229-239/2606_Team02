$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

function Assert-FileExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Missing file $Path"
    }
}

$state = "scripts/game_state.gd"
$panel = "scripts/market_stall_panel.gd"
$scene = "ui/MarketStallPanel.tscn"
$assetRoot = "assets/sprites/market_stall"

Assert-FileContains $state "signal market_stall_changed"
Assert-FileContains $state "market_stall_level"
Assert-FileContains $state "func fulfill_market_trade"
Assert-FileContains $state "func upgrade_market_stall"
Assert-FileContains $state "func upgrade_market_storage"

Assert-FileContains $scene "MarketStallPanel"
Assert-FileContains $scene "market_stall_panel.gd"

Assert-FileExists "$assetRoot/market_stall_background.png"
Assert-FileExists "$assetRoot/market_stall_title.png"
Assert-FileExists "$assetRoot/market_order_row_panel.png"
Assert-FileExists "$assetRoot/market_order_board.png"
Assert-FileExists "$assetRoot/market_shopkeeper.png"
Assert-FileExists "$assetRoot/market_trade_card.png"
Assert-FileExists "$assetRoot/market_orders_card.png"
Assert-FileExists "$assetRoot/market_upgrades_card.png"
Assert-FileExists "$assetRoot/market_storage_card.png"
Assert-FileExists "$assetRoot/market_back_card.png"

Assert-FileContains $panel "market_stall_background.png"
Assert-FileContains $panel "market_shopkeeper.png"
Assert-FileContains $panel "Trade"
Assert-FileContains $panel "Orders"
Assert-FileContains $panel "Upgrades"
Assert-FileContains $panel "Storage"
Assert-FileContains $panel "Back"

Write-Output "MysticGrove_Godot Market Stall panel verification passed"
