$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$shader = "assets/shaders/background_glow_pulse.gdshader"
$scene = "scenes/MainVillage.tscn"
$script = "scripts/main_village.gd"

if (-not (Test-Path $shader)) {
    throw "Missing $shader"
}

Assert-FileContains $shader "shader_type canvas_item"
Assert-FileContains $shader "pulse_speed"
Assert-FileContains $shader "pulse_strength"
Assert-FileContains $shader "wind_strength"
Assert-FileContains $shader "wind_speed"
Assert-FileContains $shader "foliage_mask"
Assert-FileContains $shader "sin(TIME"
Assert-FileContains $shader "blue_mask"
Assert-FileContains $shader "blue_lift"

Assert-FileContains $scene "BackgroundGlowPulse"
Assert-FileContains $scene "BuildingGlowPulse"
Assert-FileContains $scene "background_glow_pulse.gdshader"
Assert-FileContains $scene "material = SubResource"
Assert-FileContains $scene "shader_parameter/wind_strength = 0.006"
$buildingWindUses = (Select-String -Path $scene -Pattern 'shader_parameter/wind_strength = 0.0').Count
if ($buildingWindUses -lt 1) {
    throw "Expected building glow material with wind disabled"
}
$materialUses = (Select-String -Path $scene -Pattern 'ShaderMaterial_BackgroundGlowPulse').Count
if ($materialUses -lt 2) {
    throw "Expected background glow material resource and use, found $materialUses uses"
}

Assert-FileContains $script "BACKGROUND_GLOW_SHADER_PATH"
Assert-FileContains $script "_make_background_glow_material"
Assert-FileContains $script "background.material"

Write-Output "MysticGrove_Godot background glow animation verification passed"
