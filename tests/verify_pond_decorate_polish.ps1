$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot "scripts\pond_decorate_panel.gd"

$requiredAssets = @(
    "assets\sprites\ui\decorate_title_plaque.png",
    "assets\sprites\ui\decorate_back_button.png",
    "assets\sprites\ui\decorate_remove_button.png",
    "assets\sprites\ui\decorate_place_button.png",
    "assets\sprites\ui\decorate_card.png",
    "assets\sprites\ui\decorate_slot_marker.png",
    "assets\sprites\buildings\sacred_pond_home.png"
)

foreach ($asset in $requiredAssets) {
    $path = Join-Path $projectRoot $asset
    if (!(Test-Path $path)) {
        throw "Missing decorate polish asset: $asset"
    }
}

$script = Get-Content $scriptPath -Raw

$requiredText = @(
    "POND_TEXTURE := `"res://assets/sprites/buildings/sacred_pond_home.png`"",
    "SLOT_TEXTURE := `"res://assets/sprites/ui/decorate_slot_marker.png`"",
    "PLACE_BUTTON_TEXTURE := `"res://assets/sprites/ui/decorate_place_button.png`"",
    "REMOVE_BUTTON_TEXTURE := `"res://assets/sprites/ui/decorate_remove_button.png`"",
    "BACK_BUTTON_TEXTURE := `"res://assets/sprites/ui/decorate_back_button.png`"",
    "GameState.place_pond_decoration",
    "GameState.remove_pond_decoration",
    "back_to_sacred_pond_requested.emit()",
    "No empty decoration slots.",
    "Not enough Mana."
)

foreach ($needle in $requiredText) {
    if ($script -notlike "*$needle*") {
        throw "Decorate polish script missing expected text: $needle"
    }
}

$forbiddenText = @(
    "ColorRect.new()`${newline}`twater",
    'water.color = Color("#0f4d91")',
    'marker.color = Color("#2a2f38")',
    'OptionButton.new()'
)

foreach ($needle in $forbiddenText) {
    if ($script -like "*$needle*") {
        throw "Decorate polish script still contains debug UI marker: $needle"
    }
}

Write-Host "Pond decorate polish verification passed."
