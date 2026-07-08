$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Test-Path $Path)) {
        throw "Missing file $Path"
    }
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$pond = "scripts/sacred_pond_panel.gd"
$decorate = "scripts/pond_decorate_panel.gd"
$village = "scripts/main_village.gd"

Assert-FileContains "ui/PondDecoratePanel.tscn" "PondDecoratePanel"
Assert-FileContains $decorate "Decorate Sacred Pond"
Assert-FileContains $decorate "Moon Lantern"
Assert-FileContains $decorate "Spirit Stone"
Assert-FileContains $decorate "Bloom Lilypad"
Assert-FileContains $decorate "Sacred Bridge"
Assert-FileContains $state "Crystal Lotus"
Assert-FileContains $state "Stone Koi Statue"
Assert-FileContains $state "Crystal Pillar"
Assert-FileContains $state "Moonstone Steps"
Assert-FileContains $state "Fern Spring"
Assert-FileContains $state "Flame Basin"
Assert-FileContains $state "Reed Cluster"
Assert-FileContains $state "Willow Arch"
Assert-FileContains $decorate "Pond Beauty"
Assert-FileContains $decorate "Decoration placed!"
Assert-FileContains $decorate "No empty decoration slots."
Assert-FileContains $decorate "Not enough Mana."

Assert-FileContains $state "pond_beauty"
Assert-FileContains $state "pond_decorations"
Assert-FileContains $state "pond_decoration_slots"
Assert-FileContains $state "func place_pond_decoration"
Assert-FileContains $state "func remove_pond_decoration"
Assert-FileContains $state "func get_pond_decoration_restore_bonus"
Assert-FileContains $state "floor(float(pond_beauty) / 10.0)"
Assert-FileContains $state '"pond_beauty"'
Assert-FileContains $state '"pond_decorations"'
Assert-FileContains $state '"pond_decoration_slots"'

Assert-FileContains $pond "Pond Beauty"
Assert-FileContains $pond "Decoration Bonus"
Assert-FileContains $pond "decorate_requested"

Assert-FileContains $village "PondDecoratePanelScene"
Assert-FileContains $village "_open_pond_decorate"
Assert-FileContains $village "back_to_sacred_pond_requested"
Assert-FileContains $village "pond_decoration_visual_layer"

Write-Output "MysticGrove_Godot Pond Decoration verification passed"
