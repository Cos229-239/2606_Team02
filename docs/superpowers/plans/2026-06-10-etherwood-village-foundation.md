# Etherwood Village Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Milestone 1 for Mystic Grove: a Blueprint-first UE 5.7 mobile village foundation with `MAP_EtherwoodVillage`, core Blueprint assets, three building locations, a HUD asset, and repeatable verification.

**Architecture:** Use Unreal Python editor automation to create the Blueprint asset skeletons and level foundation. The interactive loop is powered by a small native runtime module underneath Blueprint assets, so `BP_BuildingInteractable` and `BP_CameraManager` remain editable in the Content Browser while click/touch input, smooth camera focus, HUD drawing, and Back behavior run reliably in game.

**Tech Stack:** Unreal Engine 5.7, Blueprint assets, small C++ runtime base classes, Unreal Python editor scripting, PowerShell verification.

---

## Files

- Create: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\CreateEtherwoodVillageMilestone1.py`
- Create: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\TestEtherwoodVillageMilestone1.ps1`
- Create assets under: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Content\...`
- Modify generated asset registry and saved level data through Unreal Editor automation.

## Task 1: Verification Script

**Files:**
- Create: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\TestEtherwoodVillageMilestone1.ps1`

- [ ] **Step 1: Create the failing verification script**

```powershell
$ProjectRoot = "C:\Users\whitt\Documents\Unreal Projects\MysticGrove"
$RequiredPaths = @(
  "Content\Blueprints\Buildings\BP_BuildingInteractable.uasset",
  "Content\Blueprints\Managers\BP_CameraManager.uasset",
  "Content\Blueprints\Economy\BP_EconomyManager.uasset",
  "Content\Blueprints\Fairies\BP_FairyManager.uasset",
  "Content\Blueprints\UI\WBP_MainHUD.uasset",
  "Content\Maps\MAP_EtherwoodVillage.umap",
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
```

- [ ] **Step 2: Run the verification to confirm it fails before implementation**

Run:

```powershell
& "C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\TestEtherwoodVillageMilestone1.ps1"
```

Expected: exit code `1`, with missing Blueprint/map asset paths listed.

## Task 2: Unreal Creation Script

**Files:**
- Create: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\CreateEtherwoodVillageMilestone1.py`

- [ ] **Step 1: Create the Unreal Python script**

```python
import math
import unreal

CONTENT_DIRS = [
    "/Game/Blueprints/Core",
    "/Game/Blueprints/Economy",
    "/Game/Blueprints/Fairies",
    "/Game/Blueprints/Buildings",
    "/Game/Blueprints/UI",
    "/Game/Blueprints/Managers",
    "/Game/Maps",
    "/Game/Art/Characters",
    "/Game/Art/Environment",
    "/Game/Art/Props",
    "/Game/Audio",
    "/Game/DataTables",
    "/Game/Materials",
    "/Game/Effects",
    "/Game/Saves",
]

BUILDINGS = [
    ("Flower Grove", "FlowerGrove", unreal.Vector(-450.0, -120.0, 60.0), unreal.Vector(1.8, 1.8, 0.35)),
    ("Sacred Koi Pond", "SacredKoiPond", unreal.Vector(0.0, 260.0, 60.0), unreal.Vector(2.2, 1.6, 0.25)),
    ("Fairy House", "FairyHouse", unreal.Vector(440.0, -80.0, 60.0), unreal.Vector(1.4, 1.4, 0.6)),
]

def ensure_directories():
    for directory in CONTENT_DIRS:
        unreal.EditorAssetLibrary.make_directory(directory)

def create_blueprint(asset_path, asset_name, parent_class):
    existing = unreal.EditorAssetLibrary.load_asset(f"{asset_path}/{asset_name}")
    if existing:
        return existing
    factory = unreal.BlueprintFactory()
    factory.set_editor_property("ParentClass", parent_class)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    return asset_tools.create_asset(asset_name, asset_path, unreal.Blueprint, factory)

def create_widget_blueprint(asset_path, asset_name):
    existing = unreal.EditorAssetLibrary.load_asset(f"{asset_path}/{asset_name}")
    if existing:
        return existing
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    factory = unreal.WidgetBlueprintFactory()
    return asset_tools.create_asset(asset_name, asset_path, None, factory)

def set_asset_notes(asset, notes):
    unreal.EditorAssetLibrary.set_metadata_tag(asset, "MysticGroveNotes", notes)
    unreal.EditorAssetLibrary.save_loaded_asset(asset)

def create_assets():
    building_bp = create_blueprint("/Game/Blueprints/Buildings", "BP_BuildingInteractable", unreal.StaticMeshActor)
    camera_bp = create_blueprint("/Game/Blueprints/Managers", "BP_CameraManager", unreal.CameraActor)
    economy_bp = create_blueprint("/Game/Blueprints/Economy", "BP_EconomyManager", unreal.Actor)
    fairy_bp = create_blueprint("/Game/Blueprints/Fairies", "BP_FairyManager", unreal.Actor)
    hud_bp = create_widget_blueprint("/Game/Blueprints/UI", "WBP_MainHUD")

    set_asset_notes(building_bp, "Milestone 1: clickable/tappable building actor. Exposed Blueprint variables to add in editor: BuildingID, DisplayName, ZoomTargetOffset, InteractionRadius. OnClicked/Touch should call BP_CameraManager.FocusBuilding.")
    set_asset_notes(camera_bp, "Milestone 1: village camera manager. Add Blueprint functions FocusBuilding(BuildingActor) and ReturnToVillage. Use timeline or VInterpTo for smooth zoom.")
    set_asset_notes(economy_bp, "Milestone 1: economy manager. Add Mana integer, GetMana, AddMana, and OnManaChanged dispatcher.")
    set_asset_notes(fairy_bp, "Milestone 1: fairy manager foundation. Full worker assignment starts in a future milestone.")
    set_asset_notes(hud_bp, "Milestone 1: main HUD. Add Mana text counter and Back button. Back button calls BP_CameraManager.ReturnToVillage.")

    return building_bp, camera_bp, economy_bp, fairy_bp

def get_generated_class(blueprint):
    generated_class_path = f"{blueprint.get_path_name()}_C"
    return unreal.EditorAssetLibrary.load_blueprint_class(generated_class_path)

def recreate_level(building_bp, camera_bp, economy_bp, fairy_bp):
    level_path = "/Game/Maps/MAP_EtherwoodVillage"
    unreal.EditorLevelLibrary.new_level(level_path)

    cube = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube.Cube")
    building_class = get_generated_class(building_bp)
    camera_class = get_generated_class(camera_bp)
    economy_class = get_generated_class(economy_bp)
    fairy_class = get_generated_class(fairy_bp)

    for label, building_id, location, scale in BUILDINGS:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(building_class, location, unreal.Rotator(0.0, 0.0, 0.0))
        actor.set_actor_label(label)
        actor.set_actor_scale3d(scale)
        if hasattr(actor, "static_mesh_component"):
            actor.static_mesh_component.set_static_mesh(cube)
            actor.static_mesh_component.set_collision_profile_name("BlockAll")
        unreal.EditorAssetLibrary.set_metadata_tag(actor, "BuildingID", building_id)

    camera = unreal.EditorLevelLibrary.spawn_actor_from_class(camera_class, unreal.Vector(0.0, -900.0, 850.0), unreal.Rotator(-55.0, 0.0, 0.0))
    camera.set_actor_label("BP_CameraManager_VillageOverview")

    economy = unreal.EditorLevelLibrary.spawn_actor_from_class(economy_class, unreal.Vector(-700.0, 500.0, 40.0), unreal.Rotator(0.0, 0.0, 0.0))
    economy.set_actor_label("BP_EconomyManager")

    fairy = unreal.EditorLevelLibrary.spawn_actor_from_class(fairy_class, unreal.Vector(-560.0, 500.0, 40.0), unreal.Rotator(0.0, 0.0, 0.0))
    fairy.set_actor_label("BP_FairyManager")

    unreal.EditorLevelLibrary.save_current_level()

def main():
    ensure_directories()
    building_bp, camera_bp, economy_bp, fairy_bp = create_assets()
    recreate_level(building_bp, camera_bp, economy_bp, fairy_bp)
    unreal.EditorAssetLibrary.save_directory("/Game", only_if_is_dirty=False, recursive=True)
    unreal.log("Mystic Grove Milestone 1 foundation created.")

main()
```

- [ ] **Step 2: Run Unreal automation**

Run:

```powershell
& "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "C:\Users\whitt\Documents\Unreal Projects\MysticGrove\MysticGrove.uproject" -run=pythonscript -script="C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\CreateEtherwoodVillageMilestone1.py" -unattended -nop4 -NullRHI -NoSound -NoSplash
```

Expected: exit code `0`, log contains `Mystic Grove Milestone 1 foundation created.`

## Task 3: Verify Milestone Assets

**Files:**
- Run: `C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\TestEtherwoodVillageMilestone1.ps1`

- [ ] **Step 1: Run verification again**

Run:

```powershell
& "C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Scripts\TestEtherwoodVillageMilestone1.ps1"
```

Expected: exit code `0`, output contains `Milestone 1 verification passed.`

- [ ] **Step 2: Run Unreal commandlet smoke test**

Run:

```powershell
& "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "C:\Users\whitt\Documents\Unreal Projects\MysticGrove\MysticGrove.uproject" -run=CompileAllBlueprints -unattended -nop4 -NullRHI -NoSound -NoSplash
```

Expected: exit code `0`, output contains `Success - 0 error(s), 0 warning(s)`.

## Task 4: Completion Notes

**Files:**
- Modify: final assistant response only.

- [ ] **Step 1: Report created assets**

Report the exact project path and created asset names:

```text
C:\Users\whitt\Documents\Unreal Projects\MysticGrove
Content/Maps/MAP_EtherwoodVillage
Content/Blueprints/Buildings/BP_BuildingInteractable
Content/Blueprints/Managers/BP_CameraManager
Content/Blueprints/Economy/BP_EconomyManager
Content/Blueprints/Fairies/BP_FairyManager
Content/Blueprints/UI/WBP_MainHUD
```

- [ ] **Step 2: Report interaction boundary honestly**

State that Milestone 1 now has a playable click/tap, zoom, building panel, and Back loop through the native runtime base classes. `WBP_MainHUD` still exists as a Blueprint placeholder for later UI polish, while the current playable HUD is drawn by `AMysticHud`.
