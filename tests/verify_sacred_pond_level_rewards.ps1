$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$pondPanel = "scripts/sacred_pond_panel.gd"
$village = "scripts/main_village.gd"

Assert-FileContains $state "active_pond_bonus"
Assert-FileContains $state "unlocked_pond_rewards"
Assert-FileContains $state "func update_sacred_pond_level_and_rewards"
Assert-FileContains $state "Blooming Waters"
Assert-FileContains $state "Moonlit Reflection"
Assert-FileContains $state "Fairy Blessing"
Assert-FileContains $state "Sun Koi Guardian"
Assert-FileContains $state "ceil(float(sacred_pond_restore_cost) * 1.25)"
Assert-FileContains $state "func get_active_pond_bonus_text"
Assert-FileContains $state "func get_next_pond_reward_text"
Assert-FileContains $state '"active_pond_bonus"'
Assert-FileContains $state '"unlocked_pond_rewards"'

Assert-FileContains $pondPanel "Active Pond Bonus"
Assert-FileContains $pondPanel "Next Reward"
Assert-FileContains $pondPanel "Total Restore Amount"

Assert-FileContains $village "restoration_visual_layer"
Assert-FileContains $village "_refresh_restoration_visuals"
Assert-FileContains $village "Extra pond flowers"
Assert-FileContains $village "Pond glow"
Assert-FileContains $village "Fairy lights"
Assert-FileContains $village "Sun Koi Guardian"

Write-Output "MysticGrove_Godot Sacred Pond level rewards verification passed"
