$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot "scripts\main_village.gd"
$script = Get-Content $scriptPath -Raw

$requiredScriptSnippets = @(
    "_disable_editor_map_input_blocking()",
    "func _disable_editor_map_input_blocking",
    "func _set_control_tree_mouse_filter_ignore",
    "Control.MOUSE_FILTER_IGNORE",
    'get_node_or_null("EditableHomeMap")',
    "var building_hit_layer: CanvasLayer",
    'building_hit_layer.name = "BuildingHitLayer"',
    "building_hit_layer.layer = 5",
    "building_hit_layer.add_child(hit_area)"
)

foreach ($snippet in $requiredScriptSnippets) {
    if ($script -notlike "*$snippet*") {
        throw "Missing home map input passthrough support: $snippet"
    }
}

$readyFunction = [regex]::Match($script, 'func _ready\([\s\S]*?(?=\nfunc |\z)')
if (!$readyFunction.Success) {
    throw "Missing _ready function."
}

if ($readyFunction.Value -notlike "*_hide_editor_label_previews()*_disable_editor_map_input_blocking()*_build_screen()*") {
    throw "_ready should disable editor map input before building runtime hit buttons."
}

$wireFunction = [regex]::Match($script, 'func _wire_existing_nav_button\([\s\S]*?(?=\nfunc |\z)')
if (!$wireFunction.Success) {
    throw "Missing _wire_existing_nav_button function."
}

if ($wireFunction.Value -like "*pivot_offset*") {
    throw "Scene-owned bottom navigation buttons should not have pivot_offset changed at runtime."
}

$hoverFunction = [regex]::Match($script, 'func _set_texture_button_hover\([\s\S]*?(?=\nfunc |\z)')
if (!$hoverFunction.Success) {
    throw "Missing _set_texture_button_hover function."
}

if ($hoverFunction.Value -like "*button.scale*") {
    throw "Hover feedback should not change bottom navigation scale."
}

Write-Host "Home map input passthrough verification passed."
