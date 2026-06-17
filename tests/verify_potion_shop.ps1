$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$village = "scripts/main_village.gd"
$panel = "scripts/potion_shop_panel.gd"
$scene = "ui/PotionShopPanel.tscn"

Assert-FileContains $state "signal potion_shop_changed"
Assert-FileContains $state "potion_shop_level"
Assert-FileContains $state "mana_potion_count"
Assert-FileContains $state "potion_crafting_active"
Assert-FileContains $state "func start_mana_potion_craft"
Assert-FileContains $state "func update_potion_crafting"
Assert-FileContains $state "func sell_mana_potion"
Assert-FileContains $state "func upgrade_potion_shop"
Assert-FileContains $state '"potion_shop_level"'
Assert-FileContains $state '"mana_potion_count"'
Assert-FileContains $state '"potion_crafting_active"'

Assert-FileContains $village "PotionShopPanelScene"
Assert-FileContains $village '"Potion Shop"'
Assert-FileContains $village "_open_potion_shop"

Assert-FileContains $scene "PotionShopPanel"
Assert-FileContains $scene "potion_shop_panel.gd"

Assert-FileContains $panel "Craft Potion"
Assert-FileContains $panel "Sell Potion"
Assert-FileContains $panel "Upgrade Shop"
Assert-FileContains $panel "Mana Potion crafted!"
Assert-FileContains $panel "Potion sold for 50 Coins!"
Assert-FileContains $panel "No potions to sell."
Assert-FileContains $panel "Not enough Mana."

Write-Output "MysticGrove_Godot Potion Shop verification passed"
