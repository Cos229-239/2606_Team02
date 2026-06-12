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
    asset_full_path = f"{asset_path}/{asset_name}"
    if unreal.EditorAssetLibrary.does_asset_exist(asset_full_path):
        return unreal.EditorAssetLibrary.load_asset(asset_full_path)

    factory = unreal.BlueprintFactory()
    factory.set_editor_property("ParentClass", parent_class)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    return asset_tools.create_asset(asset_name, asset_path, unreal.Blueprint, factory)


def create_widget_blueprint(asset_path, asset_name):
    asset_full_path = f"{asset_path}/{asset_name}"
    if unreal.EditorAssetLibrary.does_asset_exist(asset_full_path):
        return unreal.EditorAssetLibrary.load_asset(asset_full_path)

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

    set_asset_notes(
        building_bp,
        "Milestone 1 clickable/tappable building actor. Add Blueprint variables: BuildingID, DisplayName, ZoomTargetOffset, InteractionRadius. OnClicked/Touch should call BP_CameraManager.FocusBuilding.",
    )
    set_asset_notes(
        camera_bp,
        "Milestone 1 village camera manager. Add Blueprint functions FocusBuilding(BuildingActor) and ReturnToVillage. Use Timeline or VInterpTo for smooth zoom.",
    )
    set_asset_notes(
        economy_bp,
        "Milestone 1 economy manager. Add Mana integer, GetMana, AddMana, and OnManaChanged dispatcher.",
    )
    set_asset_notes(
        fairy_bp,
        "Milestone 1 fairy manager foundation. Worker assignment starts in a future milestone.",
    )
    set_asset_notes(
        hud_bp,
        "Milestone 1 main HUD. Add Mana text counter and Back button. Back button calls BP_CameraManager.ReturnToVillage.",
    )

    return building_bp, camera_bp, economy_bp, fairy_bp


def get_generated_class(blueprint):
    class_path = f"{blueprint.get_path_name()}_C"
    return unreal.EditorAssetLibrary.load_blueprint_class(class_path)


def recreate_level(building_bp, camera_bp, economy_bp, fairy_bp):
    level_path = "/Game/Maps/MAP_EtherwoodVillage"
    if unreal.EditorAssetLibrary.does_asset_exist(level_path):
        unreal.EditorAssetLibrary.delete_asset(level_path)
    unreal.EditorLevelLibrary.new_level(level_path)

    cube = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube.Cube")
    building_class = get_generated_class(building_bp)
    camera_class = get_generated_class(camera_bp)
    economy_class = get_generated_class(economy_bp)
    fairy_class = get_generated_class(fairy_bp)

    for label, building_id, location, scale in BUILDINGS:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
            building_class, location, unreal.Rotator(0.0, 0.0, 0.0)
        )
        actor.set_actor_label(label)
        actor.set_actor_scale3d(scale)
        if hasattr(actor, "static_mesh_component"):
            actor.static_mesh_component.set_static_mesh(cube)
            actor.static_mesh_component.set_collision_profile_name("BlockAll")
        unreal.EditorAssetLibrary.set_metadata_tag(actor, "BuildingID", building_id)

    camera = unreal.EditorLevelLibrary.spawn_actor_from_class(
        camera_class, unreal.Vector(0.0, -900.0, 850.0), unreal.Rotator(-55.0, 0.0, 0.0)
    )
    camera.set_actor_label("BP_CameraManager_VillageOverview")

    economy = unreal.EditorLevelLibrary.spawn_actor_from_class(
        economy_class, unreal.Vector(-700.0, 500.0, 40.0), unreal.Rotator(0.0, 0.0, 0.0)
    )
    economy.set_actor_label("BP_EconomyManager")

    fairy = unreal.EditorLevelLibrary.spawn_actor_from_class(
        fairy_class, unreal.Vector(-560.0, 500.0, 40.0), unreal.Rotator(0.0, 0.0, 0.0)
    )
    fairy.set_actor_label("BP_FairyManager")

    unreal.EditorLevelLibrary.save_current_level()


def main():
    ensure_directories()
    building_bp, camera_bp, economy_bp, fairy_bp = create_assets()
    recreate_level(building_bp, camera_bp, economy_bp, fairy_bp)
    unreal.EditorAssetLibrary.save_directory("/Game", only_if_is_dirty=False, recursive=True)
    unreal.log("Mystic Grove Milestone 1 foundation created.")


main()
