$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

function Assert-FileContains($relativePath, $needle) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path $path)) {
        throw "Missing required file: $relativePath"
    }
    $content = Get-Content -Raw -Path $path
    if (-not $content.Contains($needle)) {
        throw "$relativePath is missing: $needle"
    }
}

$panelScripts = @(
    "scripts\market_stall_panel.gd",
    "scripts\ancient_tree_panel.gd",
    "scripts\arcane_forge_panel.gd"
)

foreach ($script in $panelScripts) {
    if (-not (Test-Path (Join-Path $root $script))) {
        throw "Missing panel script: $script"
    }
}

Assert-FileContains "ui\MarketStallPanel.tscn" "market_stall_panel.gd"
Assert-FileContains "ui\AncientTreePanel.tscn" "ancient_tree_panel.gd"
Assert-FileContains "ui\ArcaneForgePanel.tscn" "arcane_forge_panel.gd"
Assert-FileContains "ui\MarketStallPanel.tscn" 'node name="MarketStallPanel" type="Control"'
Assert-FileContains "ui\AncientTreePanel.tscn" 'node name="AncientTreePanel" type="Control"'
Assert-FileContains "ui\ArcaneForgePanel.tscn" 'node name="ArcaneForgePanel" type="Control"'

Assert-FileContains "scripts\market_stall_panel.gd" "fulfill_market_order"
Assert-FileContains "scripts\market_stall_panel.gd" "extends Control"
Assert-FileContains "scripts\market_stall_panel.gd" "mana_bundle"
Assert-FileContains "scripts\market_stall_panel.gd" "potion_crate"
Assert-FileContains "scripts\market_stall_panel.gd" "spirit_contract"
Assert-FileContains "scripts\market_stall_panel.gd" "MarketplaceCanopy"
Assert-FileContains "scripts\market_stall_panel.gd" "OrderRibbon"
Assert-FileContains "scripts\market_stall_panel.gd" "ResourceShelf"

Assert-FileContains "scripts\ancient_tree_panel.gd" "restore_ancient_tree"
Assert-FileContains "scripts\ancient_tree_panel.gd" "extends Control"
Assert-FileContains "scripts\ancient_tree_panel.gd" "claim_ancient_tree_reward"
Assert-FileContains "scripts\ancient_tree_panel.gd" "Grove Restoration"
Assert-FileContains "scripts\ancient_tree_panel.gd" "TreeHalo"
Assert-FileContains "scripts\ancient_tree_panel.gd" "RewardVine"
Assert-FileContains "scripts\ancient_tree_panel.gd" "RootSigil"

Assert-FileContains "scripts\arcane_forge_panel.gd" "purchase_forge_upgrade"
Assert-FileContains "scripts\arcane_forge_panel.gd" "extends Control"
Assert-FileContains "scripts\arcane_forge_panel.gd" "flower_focus"
Assert-FileContains "scripts\arcane_forge_panel.gd" "potion_gilding"
Assert-FileContains "scripts\arcane_forge_panel.gd" "pond_resonance"
Assert-FileContains "scripts\arcane_forge_panel.gd" "ForgeAnvil"
Assert-FileContains "scripts\arcane_forge_panel.gd" "SparkColumn"
Assert-FileContains "scripts\arcane_forge_panel.gd" "UpgradeRune"

Assert-FileContains "scripts\game_state.gd" "signal market_stall_changed"
Assert-FileContains "scripts\game_state.gd" "signal ancient_tree_changed"
Assert-FileContains "scripts\game_state.gd" "signal arcane_forge_changed"
Assert-FileContains "scripts\game_state.gd" "QUEST_GOAL_MARKET_TRADE"
Assert-FileContains "scripts\game_state.gd" "QUEST_GOAL_RESTORE_TREE"
Assert-FileContains "scripts\game_state.gd" "QUEST_GOAL_FORGE_UPGRADE"

$buildingsPanel = Get-Content -Raw -Path (Join-Path $root "scripts\buildings_panel.gd")
foreach ($text in @(
    "Trade resources for Coins and reputation.",
    "Restore the grove heart and claim restoration rewards.",
    "Forge permanent upgrades for production, potions, and pond restoration."
)) {
    if (-not $buildingsPanel.Contains($text)) {
        throw "scripts\buildings_panel.gd is missing updated description: $text"
    }
}

Write-Host "Building system panels verification passed."
