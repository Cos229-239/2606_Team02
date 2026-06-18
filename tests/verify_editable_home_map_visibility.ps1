$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$scenePath = Join-Path $projectRoot "scenes\MainVillage.tscn"
$scriptPath = Join-Path $projectRoot "scripts\main_village.gd"
$scene = Get-Content $scenePath -Raw
$script = Get-Content $scriptPath -Raw

$requiredNodes = @(
    "BackgroundPreview",
    "AncientTreePlacement",
    "SacredKoiPondPlacement",
    "PotionShopPlacement",
    "FlowerGrovePlacement",
    "FairyHousePlacement",
    "MarketStallPlacement",
    "ArcaneForgePlacement",
    "AncientTreeLabelPlacement",
    "SacredKoiPondLabelPlacement",
    "PotionShopLabelPlacement",
    "FlowerGroveLabelPlacement",
    "FairyHouseLabelPlacement",
    "MarketStallLabelPlacement",
    "ArcaneForgeLabelPlacement"
)

foreach ($node in $requiredNodes) {
    if ($scene -notlike "*name=`"$node`"*") {
        throw "Missing editable home map node: $node"
    }
}

$placements = @(
    "AncientTreePlacement",
    "SacredKoiPondPlacement",
    "PotionShopPlacement",
    "FlowerGrovePlacement",
    "FairyHousePlacement",
    "MarketStallPlacement",
    "ArcaneForgePlacement"
)
foreach ($placement in $placements) {
    $spriteHeader = "parent=`"EditableHomeMap/$placement`""
    if ($scene -notlike "*$spriteHeader*") {
        throw "Missing visible editor sprite under $placement"
    }
}

$requiredScriptSnippets = @(
    "_get_area_label_rect",
    "_get_label_placement_name",
    "_hide_editor_label_previews",
    "ends_with(`"LabelPlacement`")"
)

foreach ($snippet in $requiredScriptSnippets) {
    if ($script -notlike "*$snippet*") {
        throw "Missing editable label placement script support: $snippet"
    }
}

$placementLookup = @"
func _get_placement_rect(placement_name: String, fallback: Rect2) -> Rect2:
	var placement := get_node_or_null("EditableHomeMap/%s" % placement_name) as Control
	if placement == null:
		return fallback
	return Rect2(placement.position, placement.size)
"@

if (!$script.Contains($placementLookup)) {
    throw "Placement lookup should use the editable parent Control rectangle directly."
}

Write-Host "Editable home map visibility verification passed."
