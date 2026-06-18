$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$mainVillage = "scripts/main_village.gd"

Assert-FileContains $mainVillage "_add_path_curve"
Assert-FileContains $mainVillage "_add_shadow_ellipse"
Assert-FileContains $mainVillage "_add_ellipse"
Assert-FileContains $mainVillage "_add_poly"
Assert-FileContains $mainVillage "Polygon2D"
Assert-FileContains $mainVillage "Line2D"
Assert-FileContains $mainVillage "StyleBoxEmpty"
Assert-FileContains $mainVillage "cottage_roof_warm.png"
Assert-FileContains $mainVillage "water_bucket.png"
Assert-FileContains $mainVillage "grass_flowers.png"
Assert-FileContains $mainVillage "fence_post.png"

Write-Output "MysticGrove_Godot fake 2.5D village verification passed"
