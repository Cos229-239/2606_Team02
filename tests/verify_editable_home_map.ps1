$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$scene = "scenes/MainVillage.tscn"
$script = "scripts/main_village.gd"

Assert-FileContains $scene 'node name="EditableHomeMap"'
Assert-FileContains $scene 'node name="BackgroundPreview"'
Assert-FileContains $scene 'restored_village_background.png'
Assert-FileContains $scene 'node name="AncientTreePlacement"'
Assert-FileContains $scene 'node name="SacredKoiPondPlacement"'
Assert-FileContains $scene 'node name="FlowerGrovePlacement"'
Assert-FileContains $scene 'node name="FairyHousePlacement"'
Assert-FileContains $scene 'node name="PotionShopPlacement"'
Assert-FileContains $scene 'node name="MarketStallPlacement"'
Assert-FileContains $scene 'node name="ArcaneForgePlacement"'
Assert-FileContains $scene 'arcane_forge_home.png'

Assert-FileContains $script 'func _get_placement_rect'
Assert-FileContains $script 'func _get_click_rect'
Assert-FileContains $script 'return Rect2(placement.position, placement.size)'
Assert-FileContains $script 'AncientTreePlacement'
Assert-FileContains $script 'SacredKoiPondPlacement'
Assert-FileContains $script 'FlowerGrovePlacement'
Assert-FileContains $script 'FairyHousePlacement'
Assert-FileContains $script 'PotionShopPlacement'
Assert-FileContains $script 'ArcaneForgePlacement'
Assert-FileContains $script 'Arcane Forge'

Write-Output "MysticGrove_Godot editable home map verification passed"
