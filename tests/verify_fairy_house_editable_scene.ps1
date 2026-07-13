$ErrorActionPreference = "Stop"

$scenePath = "ui\FairyHousePanel.tscn"
$scriptPath = "scripts\fairy_house_panel.gd"
if (!(Test-Path $scenePath)) {
    throw "Missing FairyHousePanel scene."
}

$scene = Get-Content $scenePath -Raw
$script = Get-Content $scriptPath -Raw
$requiredNodes = @(
    'name="Root"',
    'name="FairyHouseBackground"',
    'name="StatsPanelBackground"',
    'name="StatsLabel"',
    'name="WorkersTitle"',
    'name="FairyCardsScroll"',
    'name="FairyCardsContainer"',
    'name="FeedbackLabel"',
    'name="ActionBarBackground"',
    'name="ActionRow"',
    'name="UpgradeHouseButton"',
    'name="BackButton"'
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*$node*") {
        throw "Fairy House scene is missing editable node marker: $node"
    }
}

if ($scene -notlike '*fairy_house_interior.png*') {
    throw "Fairy House scene is missing the updated interior background texture."
}

foreach ($texture in @(
    'title_plaque.png',
    'fairy_luna_gatherer.png',
    'fairy_pip_pond_keeper.png',
    'fairy_nim_sleeping.png',
    'button_workers.png',
    'button_tasks.png',
    'button_upgrades.png',
    'button_back.png'
)) {
    if ($scene -notlike "*$texture*") {
        throw "Fairy House scene is missing updated sprite texture: $texture"
    }
}

foreach ($previewCard in @(
    'EditorPreviewLunaCard',
    'EditorPreviewPipCard',
    'EditorPreviewNimCard'
)) {
    if ($scene -notlike "*name=`"$previewCard`" type=`"PanelContainer`" parent=`"Root/FairyCardsScroll/FairyCardsContainer`"*") {
        throw "Fairy House editor preview card is missing: $previewCard"
    }
}

foreach ($previewPart in @(
    'name="PortraitFrame"',
    'name="Portrait" type="Sprite2D"',
    'name="Details" type="Label"',
    'name="AssignmentPreviewButtons"'
)) {
    if ($scene -notlike "*$previewPart*") {
        throw "Fairy House editor preview cards are missing part: $previewPart"
    }
}

foreach ($button in @('WorkersButton', 'TasksButton', 'UpgradeHouseButton', 'BackButton')) {
    if ($scene -notlike "*name=`"$button`" type=`"Button`" parent=`"Root/ActionRow`"*") {
        throw "Fairy House nav control should be a fixed-size Button, not a texture-sized control: $button"
    }
    if ($scene -notlike "*name=`"Art`" type=`"Sprite2D`" parent=`"Root/ActionRow/$button`"*") {
        throw "Fairy House nav control is missing scaled sprite art child: $button"
    }
}

if ($scene -like '*type="TextureButton" parent="Root/ActionRow"*') {
    throw "Fairy House action row should not use TextureButton; source PNG dimensions can break layout."
}

foreach ($layoutNeedle in @(
    'offset_left = 72.0',
    'offset_right = 1008.0',
    'horizontal_scroll_mode = 0',
    'theme_override_constants/separation = 15'
)) {
    if ($scene -notlike "*$layoutNeedle*") {
        throw "Fairy House worker tray is missing expected fixed layout marker: $layoutNeedle"
    }
}

foreach ($scriptNeedle in @(
    'card.custom_minimum_size = Vector2(286, 338)',
    'func _make_card_panel_style() -> StyleBoxFlat:',
    'card.add_theme_stylebox_override("panel", _make_card_panel_style())',
    'content_row.custom_minimum_size = Vector2(258, 238)',
    'portrait.custom_minimum_size = Vector2(96, 220)',
    'details.custom_minimum_size = Vector2(148, 220)',
    'func _get_portrait_position',
    'func _get_portrait_scale',
    'Working:\n%s',
    'button.custom_minimum_size = Vector2(72, 38)'
)) {
    if ($script -notlike "*$scriptNeedle*") {
        throw "Fairy House card script is missing expected compact-card marker: $scriptNeedle"
    }
}

Write-Host "Fairy House editable scene verification passed."
