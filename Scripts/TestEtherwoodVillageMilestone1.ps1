$ProjectRoot = "C:\Users\whitt\Documents\Unreal Projects\MysticGrove"
$RequiredPaths = @(
  "Content\Blueprints\Buildings\BP_BuildingInteractable.uasset",
  "Content\Blueprints\Managers\BP_CameraManager.uasset",
  "Content\Blueprints\Economy\BP_EconomyManager.uasset",
  "Content\Blueprints\Fairies\BP_FairyManager.uasset",
  "Content\Blueprints\UI\WBP_MainHUD.uasset",
  "Content\Maps\MAP_EtherwoodVillage.umap",
  "Scripts\CreateEtherwoodVillageMilestone1.py",
  "Scripts\UpdateEtherwoodVillageInteraction.py",
  "Scripts\TestEtherwoodVillageMilestone1.ps1",
  "Scripts\TestEtherwoodVillageRuntime.py",
  "Source\MysticGrove\MysticGrove.Build.cs",
  "Source\MysticGrove\MysticGrove.cpp",
  "Source\MysticGrove\MysticGroveGameMode.h",
  "Source\MysticGrove\MysticGroveGameMode.cpp",
  "Source\MysticGrove\MysticGrovePlayerController.h",
  "Source\MysticGrove\MysticGrovePlayerController.cpp",
  "Source\MysticGrove\MysticBuildingInteractable.h",
  "Source\MysticGrove\MysticBuildingInteractable.cpp",
  "Source\MysticGrove\MysticCameraManager.h",
  "Source\MysticGrove\MysticCameraManager.cpp",
  "Source\MysticGrove\MysticHud.h",
  "Source\MysticGrove\MysticHud.cpp",
  "Content\Art\Characters",
  "Content\Art\Environment",
  "Content\Art\Props",
  "Content\Audio",
  "Content\DataTables",
  "Content\Materials",
  "Content\Effects",
  "Content\Saves"
)

$Missing = @()
foreach ($RelativePath in $RequiredPaths) {
  $FullPath = Join-Path $ProjectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $FullPath)) {
    $Missing += $RelativePath
  }
}

$EngineConfig = Get-Content -LiteralPath (Join-Path $ProjectRoot "Config\DefaultEngine.ini") -Raw
$ConfigChecks = @{
  "TargetedHardwareClass=Mobile" = $EngineConfig.Contains("TargetedHardwareClass=Mobile")
  "DefaultGraphicsPerformance=Scalable" = $EngineConfig.Contains("DefaultGraphicsPerformance=Scalable")
  "r.RayTracing=False" = $EngineConfig.Contains("r.RayTracing=False")
  "GameDefaultMap=/Game/Maps/MAP_EtherwoodVillage" = $EngineConfig.Contains("GameDefaultMap=/Game/Maps/MAP_EtherwoodVillage")
  "GlobalDefaultGameMode=/Script/MysticGrove.MysticGroveGameMode" = $EngineConfig.Contains("GlobalDefaultGameMode=/Script/MysticGrove.MysticGroveGameMode")
}

foreach ($Check in $ConfigChecks.GetEnumerator()) {
  if (-not $Check.Value) {
    $Missing += "Config missing $($Check.Key)"
  }
}

if ($Missing.Count -gt 0) {
  Write-Host "Milestone 1 verification failed. Missing:"
  $Missing | ForEach-Object { Write-Host " - $_" }
  exit 1
}

Write-Host "Milestone 1 verification passed."
exit 0
