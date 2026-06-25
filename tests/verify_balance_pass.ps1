$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$flower = "scripts/flower_grove_panel.gd"
$pond = "scripts/sacred_pond_panel.gd"
$potion = "scripts/potion_shop_panel.gd"
$quest = "scripts/quest_panel.gd"
$village = "scripts/main_village.gd"

Assert-FileContains $state "flower_grove_max_stored_mana = 100"
Assert-FileContains $state "flower_grove_base_mana_production_rate = 5.0"
Assert-FileContains $state "flower_grove_upgrade_cost = 25"
Assert-FileContains $state "return [50, 100, 200][unlock_index]"
Assert-FileContains $state "sacred_pond_water_purity = 15"
Assert-FileContains $state "sacred_pond_restore_cost = 25"
Assert-FileContains $state "sacred_pond_base_restore_amount = 5"
Assert-FileContains $state "ceil(float(sacred_pond_restore_cost) * 1.25)"
Assert-FileContains $state "potion_mana_cost = 25"
Assert-FileContains $state "potion_base_craft_time = 5"
Assert-FileContains $state "potion_sell_value = 50"
Assert-FileContains $state "potion_shop_upgrade_cost = 100"
Assert-FileContains $state "Quest Complete!"

Assert-FileContains $flower "Not enough mana."
Assert-FileContains $flower "All plots unlocked."
Assert-FileContains $pond "Not enough Mana"
Assert-FileContains $potion "Not enough Mana."
Assert-FileContains $potion "Not enough Coins."
Assert-FileContains $potion "No potions to sell."
Assert-FileContains $quest "Claim Reward"
Assert-FileContains $village "_close_panel"

Write-Output "MysticGrove_Godot balance pass verification passed"
