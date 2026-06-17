$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$scenePath = Join-Path $projectRoot "scenes\MainVillage.tscn"
$scriptPath = Join-Path $projectRoot "scripts\main_village.gd"
$scene = Get-Content $scenePath -Raw
$script = Get-Content $scriptPath -Raw

$requiredSceneSnippets = @(
    'node name="EditableBottomNavigation"',
    'node name="NavButtons"',
    'node name="MapNavButton" type="TextureButton"',
    'node name="ExploreNavButton" type="TextureButton"',
    'node name="BuildingsNavButton" type="TextureButton"',
    'node name="QuestsNavButton" type="TextureButton"',
    'node name="SettingsNavButton" type="TextureButton"',
    'node name="QuestReadyBadge"',
    'res://assets/sprites/ui/nav_map.png',
    'res://assets/sprites/ui/nav_explore.png',
    'res://assets/sprites/ui/nav_buildings.png',
    'res://assets/sprites/ui/nav_quests.png',
    'res://assets/sprites/ui/nav_settings.png'
)

foreach ($snippet in $requiredSceneSnippets) {
    if ($scene -notlike "*$snippet*") {
        throw "Missing editable bottom navigation scene snippet: $snippet"
    }
}

$navButtonBlocks = [regex]::Matches($scene, '\[node name="(?:Map|Explore|Buildings|Quests|Settings)NavButton"[\s\S]*?(?=\n\[node |\z)')
if ($navButtonBlocks.Count -ne 5) {
    throw "Expected five editable bottom navigation button blocks."
}

$requiredScriptSnippets = @(
    'get_node_or_null("EditableBottomNavigation")',
    'func _wire_editable_bottom_bar',
    'func _wire_existing_nav_button',
    'NavButtons/%s',
    'QuestReadyBadge'
)

foreach ($snippet in $requiredScriptSnippets) {
    if ($script -notlike "*$snippet*") {
        throw "Missing editable bottom navigation script support: $snippet"
    }
}

$hoverFunction = [regex]::Match($script, 'func _set_texture_button_hover\([\s\S]*?(?=\nfunc |\z)')
if (!$hoverFunction.Success) {
    throw "Missing _set_texture_button_hover function."
}

if ($hoverFunction.Value -like "*button.scale*") {
    throw "Bottom navigation hover must not change button.scale because editor-authored nav sizing must stay stable."
}

$wireFunction = [regex]::Match($script, 'func _wire_existing_nav_button\([\s\S]*?(?=\nfunc |\z)')
if (!$wireFunction.Success) {
    throw "Missing _wire_existing_nav_button function."
}

if ($wireFunction.Value -like "*pivot_offset*") {
    throw "Scene-owned bottom navigation buttons should keep their editor pivot so runtime position matches the editor."
}

Write-Host "Editable bottom navigation verification passed."
