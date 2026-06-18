$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Assert-Contains($Path, $Text, $Message) {
  $Content = Get-Content (Join-Path $ProjectRoot $Path) -Raw
  if ($Content -notlike "*$Text*") {
    throw "$Message Missing: $Text in $Path"
  }
}

$ProjectText = Get-Content (Join-Path $ProjectRoot "project.godot") -Raw
foreach ($Expected in @(
  "window/size/viewport_width=1080",
  "window/size/viewport_height=1920",
  "window/handheld/orientation=1",
  'window/stretch/mode="canvas_items"',
  'window/stretch/aspect="expand"'
)) {
  if ($ProjectText -notlike "*$Expected*") {
    throw "Mobile portrait project setting missing: $Expected"
  }
}

foreach ($Expected in @(
  "Tutorial",
  "The grove has lost its magic",
  "Tap Flower Grove",
  "Collect Mana",
  "Upgrade Flower Grove",
  "Assign a Fairy",
  "Restore the Sacred Pond",
  "Craft and sell a potion",
  "Claim a quest reward",
  "_show_floating_text",
  "_build_tree",
  "mouse_entered",
  "mouse_exited",
  "custom_minimum_size = Vector2(220, 76)",
  "Grove Restoration"
)) {
  Assert-Contains "scripts/main_village.gd" $Expected "Main Village polish check failed."
}

foreach ($Expected in @(
  "_show_floating_text",
  "_flash_button",
  "+%d Mana",
  "Collect Mana",
  "Upgrade Flower",
  "Unlock Plot",
  "Back",
  "custom_minimum_size = Vector2(220, 76)"
)) {
  Assert-Contains "scripts/flower_grove_panel.gd" $Expected "Flower Grove polish check failed."
}

foreach ($Expected in @(
  "_show_floating_text",
  "_flash_panel",
  "Water Purity +%d%%",
  "Not enough Mana",
  "Restore",
  "Decorate",
  "Back",
  "custom_minimum_size = Vector2(220, 76)"
)) {
  Assert-Contains "scripts/sacred_pond_panel.gd" $Expected "Sacred Pond polish check failed."
}

foreach ($Expected in @(
  "Fairy House",
  "Residents: %d / %d",
  "Workers Active",
  "Fairy Workers",
  "Assign to Flower Grove",
  "Assign to Sacred Pond",
  "Unassign",
  "Upgrade House",
  "Back",
  "custom_minimum_size = Vector2(220, 76)"
)) {
  Assert-Contains "scripts/fairy_house_panel.gd" $Expected "Fairy House polish check failed."
}

foreach ($Expected in @(
  "has_seen_tutorial",
  "tutorial_step",
  "total_mana",
  "total_coins",
  "flower_grove_stored_mana",
  "flower_grove_level",
  "flower_grove_production_rate",
  "sacred_pond_water_purity",
  "sacred_pond_level",
  "grove_restoration",
  "fairy_house_level"
)) {
  Assert-Contains "scripts/game_state.gd" $Expected "Save/load polish check failed."
}

Write-Output "MysticGrove_Godot milestone 2 polish verification passed"
