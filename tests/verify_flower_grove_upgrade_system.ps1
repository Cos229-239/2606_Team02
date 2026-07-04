$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$panel = "scripts/flower_grove_panel.gd"

Assert-FileContains $state "flower_grove_upgrade_cost: int = 25"
Assert-FileContains $state "flower_grove_active_plots: int = 3"
Assert-FileContains $state "flower_grove_max_plots: int = 6"
Assert-FileContains $state "flower_grove_base_mana_production_rate: float = 5.0"
Assert-FileContains $state "flower_grove_fairy_bonus_production: float = 0.0"
Assert-FileContains $state "ceil(float(flower_grove_upgrade_cost) * 1.5)"
Assert-FileContains $state "func unlock_flower_plot() -> int:"
Assert-FileContains $state "func get_flower_unlock_cost() -> int:"
Assert-FileContains $state "func get_flower_base_production_rate() -> float:"
Assert-FileContains $state "func get_flower_fairy_bonus_production() -> float:"
Assert-FileContains $state '"flower_grove_upgrade_cost"'
Assert-FileContains $state '"flower_grove_active_plots"'
Assert-FileContains $state '"flower_grove_plot_unlock_states"'
Assert-FileContains $state '"flower_grove_fairy_bonus_production"'

Assert-FileContains $panel "Base Production: +%d/sec"
Assert-FileContains $panel "Fairy Bonus: +%d/sec"
Assert-FileContains $panel "Total Production: +%d/sec"
Assert-FileContains $panel "Active Plots: %d / %d"
Assert-FileContains $panel "Unlock Plot Cost: %s"
Assert-FileContains $panel "unlock_button.disabled"
Assert-FileContains $panel "New flower plot unlocked!"
Assert-FileContains $panel "All plots unlocked."
Assert-FileContains $panel "_rebuild_garden_preview"
Assert-FileContains $panel "_pulse_garden_preview"
Assert-FileContains $panel "GameState.unlock_flower_plot()"

Write-Output "MysticGrove_Godot Flower Grove upgrade system verification passed"
