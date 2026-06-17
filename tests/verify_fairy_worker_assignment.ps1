$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$fairyPanel = "scripts/fairy_house_panel.gd"
$flowerPanel = "scripts/flower_grove_panel.gd"
$pondPanel = "scripts/sacred_pond_panel.gd"

Assert-FileContains $state "var fairies: Array[Dictionary]"
Assert-FileContains $state '"FairyName": "Luna"'
Assert-FileContains $state '"FairyName": "Pip"'
Assert-FileContains $state '"FairyName": "Nim"'
Assert-FileContains $state '"FairyLevel"'
Assert-FileContains $state '"FairyRole"'
Assert-FileContains $state '"AssignedArea"'
Assert-FileContains $state '"WorkBonus"'
Assert-FileContains $state '"IsUnlocked"'
Assert-FileContains $state "func assign_fairy_to_area"
Assert-FileContains $state "func recalculate_fairy_bonuses"
Assert-FileContains $state "sacred_pond_fairy_restore_bonus"
Assert-FileContains $state "func get_sacred_pond_total_restore_amount"
Assert-FileContains $state '"fairies"'

Assert-FileContains $fairyPanel "Fairy Workers"
Assert-FileContains $fairyPanel "Assign to Flower Grove"
Assert-FileContains $fairyPanel "Assign to Sacred Pond"
Assert-FileContains $fairyPanel "Unassign"
Assert-FileContains $fairyPanel "GameState.assign_fairy_to_area"

Assert-FileContains $flowerPanel "Fairy Bonus: +%d/sec"
Assert-FileContains $flowerPanel "Total Production: +%d/sec"

Assert-FileContains $pondPanel "Base Restore Amount"
Assert-FileContains $pondPanel "Fairy Restore Bonus"
Assert-FileContains $pondPanel "Total Restore Amount"

Write-Output "MysticGrove_Godot fairy worker assignment static verification passed"
