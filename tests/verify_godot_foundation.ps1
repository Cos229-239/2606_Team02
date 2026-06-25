$ProjectRoot = Split-Path -Parent $PSScriptRoot

$RequiredFiles = @(
  "project.godot",
  "scenes/MainMenu.tscn",
  "scenes/MainVillage.tscn",
  "ui/FlowerGrovePanel.tscn",
  "ui/SacredPondPanel.tscn",
  "ui/FairyHousePanel.tscn",
  "scripts/game_state.gd",
  "scripts/main_menu.gd",
  "scripts/main_village.gd",
  "scripts/flower_grove_panel.gd",
  "scripts/sacred_pond_panel.gd",
  "scripts/fairy_house_panel.gd"
)

foreach ($RelativePath in $RequiredFiles) {
  $FullPath = Join-Path $ProjectRoot $RelativePath
  if (-not (Test-Path $FullPath)) {
    throw "Missing required file: $RelativePath"
  }
}

$ProjectText = Get-Content (Join-Path $ProjectRoot "project.godot") -Raw
foreach ($Expected in @("MysticGrove_Godot", "MainMenu.tscn", "GameState")) {
  if ($ProjectText -notlike "*$Expected*") {
    throw "project.godot missing $Expected"
  }
}

$GameStateText = Get-Content (Join-Path $ProjectRoot "scripts/game_state.gd") -Raw
foreach ($Expected in @(
  "total_mana",
  "total_coins",
  "flower_grove_level",
  "flower_grove_stored_mana",
  "flower_grove_production_rate",
  "sacred_pond_water_purity",
  "sacred_pond_level",
  "grove_restoration",
  "fairy_house_level",
  "collect_flower_mana",
  "restore_sacred_pond",
  "save_game",
  "load_game"
)) {
  if ($GameStateText -notlike "*$Expected*") {
    throw "game_state.gd missing $Expected"
  }
}

$FlowerText = Get-Content (Join-Path $ProjectRoot "scripts/flower_grove_panel.gd") -Raw
foreach ($Expected in @("Collect Mana", "Upgrade Flower", "Unlock Plot", "Back")) {
  if ($FlowerText -notlike "*$Expected*") {
    throw "Flower Grove panel missing $Expected"
  }
}

$PondText = Get-Content (Join-Path $ProjectRoot "scripts/sacred_pond_panel.gd") -Raw
foreach ($Expected in @("Restore", "Decorate", "Back", "Water Purity", "Spirit Energy")) {
  if ($PondText -notlike "*$Expected*") {
    throw "Sacred Pond panel missing $Expected"
  }
}

$VillageText = Get-Content (Join-Path $ProjectRoot "scripts/main_village.gd") -Raw
foreach ($Expected in @("Flower Grove", "Sacred Koi Pond", "Fairy House", "Grove Restoration")) {
  if ($VillageText -notlike "*$Expected*") {
    throw "Main Village missing $Expected"
  }
}

Write-Output "MysticGrove_Godot foundation verification passed"
