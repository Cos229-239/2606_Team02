# Etherwood Village Foundation Design

## Goal

Milestone 1 creates the Blueprint-first mobile foundation for Mystic Grove in Unreal Engine 5.7: a top-down village hub map, three clickable building locations, a smooth camera zoom loop, a back-to-village flow, and a visible mana counter.

## Scope

This milestone creates the core asset structure and the first playable village interaction loop. It includes:

- `MAP_EtherwoodVillage`
- `BP_BuildingInteractable`
- `BP_CameraManager`
- `BP_EconomyManager`
- `BP_FairyManager`
- `WBP_MainHUD`
- Flower Grove location
- Sacred Koi Pond location
- Fairy House location
- Clickable building interaction
- Camera zoom to selected building
- Back button return to the village camera
- Mana counter displayed in the HUD
- Mobile-focused input and rendering assumptions

Potion Shop, Ancient Tree, full fairy assignment, resource generation, coins, spirit energy, and Data Tables are reserved for later milestones unless needed as stubs.

## Folder Structure

All gameplay assets live under `Content`:

```text
Content/
  Blueprints/
    Buildings/
      BP_BuildingInteractable
    Core/
    Economy/
      BP_EconomyManager
    Fairies/
      BP_FairyManager
    Managers/
      BP_CameraManager
    UI/
      WBP_MainHUD
  Maps/
    MAP_EtherwoodVillage
  Art/
    Characters/
    Environment/
    Props/
  Audio/
  DataTables/
  Materials/
  Effects/
  Saves/
```

## Architecture

`MAP_EtherwoodVillage` is a simple top-down hub level. It contains one placed `BP_CameraManager`, one placed `BP_EconomyManager`, one placed `BP_FairyManager`, and three placed `BP_BuildingInteractable` actors representing Flower Grove, Sacred Koi Pond, and Fairy House.

`BP_BuildingInteractable` owns building identity and click/tap handling. Each instance inherits from a small native base class so the runtime click/touch loop works reliably while the placed building assets remain Blueprint-editable. Each instance exposes `BuildingID`, `DisplayName`, and `ZoomOffset`.

`BP_CameraManager` owns the village camera, current zoom target, interpolation settings, and return flow. It starts in village overview mode, smoothly moves to a selected building, exposes the focused building name to the HUD, and returns to the original camera transform when the back button is pressed.

`BP_EconomyManager` owns Milestone 1 currency state. It starts with `Mana = 0` and exposes `GetMana`, `AddMana`, and an `OnManaChanged` dispatcher so UI can update without polling.

`BP_FairyManager` is a placeholder manager for later worker assignment. In this milestone it exists in the level, initializes cleanly, and exposes no production behavior.

`WBP_MainHUD` remains the Blueprint UI placeholder for later visual polish. Milestone 1's playable HUD is drawn by `AMysticHud`: it displays the mana counter, shows the focused building panel, and provides a Back button that returns to the village camera.

## Mobile Optimization

Milestone 1 keeps the scene simple and scalable:

- Touch input is the primary interaction path.
- Building collision uses simple primitive shapes.
- Camera movement is interpolation-based, not physics-based.
- No starter content is required.
- Ray tracing remains disabled.
- UI is anchored for portrait and landscape mobile preview.
- The level uses placeholder meshes/materials only until final art arrives.

## Acceptance Criteria

- Opening the project in Unreal Engine 5.7 shows `MAP_EtherwoodVillage` under `Content/Maps`.
- The level contains Flower Grove, Sacred Koi Pond, and Fairy House placeholder locations.
- Tapping/clicking a building triggers a smooth camera zoom to that building.
- `WBP_MainHUD` displays a mana counter.
- The back button appears during building focus and returns the camera to village overview.
- The project remains Blueprint-first with no C++ gameplay module.
- The project remains configured for mobile/scalable rendering.
