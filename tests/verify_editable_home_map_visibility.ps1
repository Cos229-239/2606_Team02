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

function Get-ControlRect {
    param([string]$NodeName)

    $match = [regex]::Match($scene, "(?s)\[node name=`"$NodeName`"[\s\S]*?(?=\n\[node |\z)")
    if (!$match.Success) {
        throw "Could not find node block for $NodeName"
    }

    $block = $match.Value
    $left = [double]([regex]::Match($block, "offset_left = ([\-0-9.]+)").Groups[1].Value)
    $top = [double]([regex]::Match($block, "offset_top = ([\-0-9.]+)").Groups[1].Value)
    $right = [double]([regex]::Match($block, "offset_right = ([\-0-9.]+)").Groups[1].Value)
    $bottom = [double]([regex]::Match($block, "offset_bottom = ([\-0-9.]+)").Groups[1].Value)

    return [pscustomobject]@{
        Left = $left
        Top = $top
        Right = $right
        Bottom = $bottom
        Width = $right - $left
        Height = $bottom - $top
    }
}

function Get-ClickRect {
    param($Rect)

    $insetX = $Rect.Width * 0.12
    $insetY = $Rect.Height * 0.10
    return [pscustomobject]@{
        Left = $Rect.Left + $insetX
        Top = $Rect.Top + $insetY
        Right = $Rect.Right - $insetX
        Bottom = $Rect.Bottom - $insetY
    }
}

function Test-RectOverlap {
    param($A, $B)
    return ($A.Left -lt $B.Right -and $A.Right -gt $B.Left -and $A.Top -lt $B.Bottom -and $A.Bottom -gt $B.Top)
}

$marketClick = Get-ClickRect (Get-ControlRect "MarketStallPlacement")
$forgeClick = Get-ClickRect (Get-ControlRect "ArcaneForgePlacement")
if (Test-RectOverlap $marketClick $forgeClick) {
    throw "Market Stall and Arcane Forge click rectangles overlap; market taps can open the forge."
}

Write-Host "Editable home map visibility verification passed."
