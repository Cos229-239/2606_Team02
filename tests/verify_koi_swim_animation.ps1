$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$village = "scripts/main_village.gd"
$pond = "scripts/sacred_pond_panel.gd"

Assert-FileContains $village "func _add_home_swimming_koi"
Assert-FileContains $village "koi_gold.png"
Assert-FileContains $village "koi_blue.png"
Assert-FileContains $village "koi_pink.png"
Assert-FileContains $village "_animate_koi_loop"

Assert-FileContains $pond "func _add_swimming_koi"
Assert-FileContains $pond "_animate_koi_loop"
Assert-FileContains $pond "set_loops"
Assert-FileContains $pond "tween_property"

Write-Output "MysticGrove_Godot koi swim animation verification passed"
