import unreal


BLUEPRINT_PARENTS = {
    "/Game/Blueprints/Buildings/BP_BuildingInteractable": "/Script/MysticGrove.MysticBuildingInteractable",
    "/Game/Blueprints/Managers/BP_CameraManager": "/Script/MysticGrove.MysticCameraManager",
}

BUILDINGS = [
    {
        "label": "Flower Grove",
        "id": "FlowerGrove",
        "display": "Flower Grove",
        "location": unreal.Vector(-450.0, -120.0, 70.0),
        "scale": unreal.Vector(1.8, 1.8, 0.45),
        "zoom_offset": unreal.Vector(0.0, -410.0, 340.0),
    },
    {
        "label": "Sacred Koi Pond",
        "id": "SacredKoiPond",
        "display": "Sacred Koi Pond",
        "location": unreal.Vector(0.0, 260.0, 55.0),
        "scale": unreal.Vector(2.3, 1.6, 0.28),
        "zoom_offset": unreal.Vector(0.0, -390.0, 320.0),
    },
    {
        "label": "Fairy House",
        "id": "FairyHouse",
        "display": "Fairy House",
        "location": unreal.Vector(440.0, -80.0, 85.0),
        "scale": unreal.Vector(1.25, 1.25, 0.85),
        "zoom_offset": unreal.Vector(0.0, -380.0, 330.0),
    },
]


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def reparent_blueprints():
    for blueprint_path, parent_path in BLUEPRINT_PARENTS.items():
        blueprint = load_asset(blueprint_path)
        parent_class = unreal.load_class(None, parent_path)
        if not parent_class:
            raise RuntimeError(f"Missing native class: {parent_path}")
        unreal.BlueprintEditorLibrary.reparent_blueprint(blueprint, parent_class)
        unreal.BlueprintEditorLibrary.compile_blueprint(blueprint)
        unreal.EditorAssetLibrary.save_loaded_asset(blueprint)


def set_if_possible(actor, name, value):
    try:
        actor.set_editor_property(name, value)
    except Exception as exc:
        unreal.log_warning(f"Could not set {actor.get_actor_label()}.{name}: {exc}")


def get_generated_class(path):
    blueprint = load_asset(path)
    unreal.BlueprintEditorLibrary.compile_blueprint(blueprint)
    generated_class = unreal.BlueprintEditorLibrary.generated_class(blueprint)
    if not generated_class:
        raise RuntimeError(f"Missing generated class for {path}")
    return generated_class


def spawn_static_mesh(label, location, scale):
    cube = load_asset("/Engine/BasicShapes/Cube.Cube")
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, location, unreal.Rotator(0.0, 0.0, 0.0))
    actor.set_actor_label(label)
    actor.set_actor_scale3d(scale)
    actor.static_mesh_component.set_static_mesh(cube)
    actor.static_mesh_component.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    actor.static_mesh_component.set_collision_response_to_all_channels(unreal.CollisionResponseType.ECR_BLOCK)
    return actor


def set_light_intensity(actor, intensity):
    component = actor.get_component_by_class(unreal.LightComponent)
    if component:
        component.set_editor_property("intensity", intensity)


def rebuild_level():
    level_path = "/Game/Maps/MAP_EtherwoodVillage"
    if unreal.EditorAssetLibrary.does_asset_exist(level_path):
        unreal.EditorAssetLibrary.delete_asset(level_path)

    unreal.EditorLevelLibrary.new_level(level_path)

    ground = spawn_static_mesh("Etherwood Village Ground", unreal.Vector(0.0, 0.0, -20.0), unreal.Vector(13.0, 13.0, 0.08))
    ground.static_mesh_component.set_collision_enabled(unreal.CollisionEnabled.QUERY_ONLY)

    building_class = get_generated_class("/Game/Blueprints/Buildings/BP_BuildingInteractable")
    camera_class = get_generated_class("/Game/Blueprints/Managers/BP_CameraManager")
    economy_class = get_generated_class("/Game/Blueprints/Economy/BP_EconomyManager")
    fairy_class = get_generated_class("/Game/Blueprints/Fairies/BP_FairyManager")

    cube = load_asset("/Engine/BasicShapes/Cube.Cube")
    for data in BUILDINGS:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(building_class, data["location"], unreal.Rotator(0.0, 0.0, 0.0))
        actor.set_actor_label(data["label"])
        actor.set_actor_scale3d(data["scale"])
        set_if_possible(actor, "BuildingID", data["id"])
        set_if_possible(actor, "DisplayName", data["display"])
        set_if_possible(actor, "ZoomOffset", data["zoom_offset"])
        mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
        if mesh:
            mesh.set_static_mesh(cube)
            mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
            mesh.set_collision_response_to_all_channels(unreal.CollisionResponseType.ECR_BLOCK)

    camera = unreal.EditorLevelLibrary.spawn_actor_from_class(
        camera_class,
        unreal.Vector(0.0, -980.0, 860.0),
        unreal.Rotator(-55.0, 0.0, 0.0),
    )
    camera.set_actor_label("BP_CameraManager_VillageOverview")

    economy = unreal.EditorLevelLibrary.spawn_actor_from_class(
        economy_class,
        unreal.Vector(-700.0, 500.0, 40.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    economy.set_actor_label("BP_EconomyManager")

    fairy = unreal.EditorLevelLibrary.spawn_actor_from_class(
        fairy_class,
        unreal.Vector(-560.0, 500.0, 40.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    fairy.set_actor_label("BP_FairyManager")

    light = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.DirectionalLight,
        unreal.Vector(-300.0, -300.0, 700.0),
        unreal.Rotator(-50.0, 35.0, 0.0),
    )
    light.set_actor_label("Etherwood Directional Light")
    set_light_intensity(light, 5.0)

    sky_light = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.SkyLight,
        unreal.Vector(0.0, 0.0, 500.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    sky_light.set_actor_label("Etherwood Sky Light")
    set_light_intensity(sky_light, 2.5)

    fill_light = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PointLight,
        unreal.Vector(0.0, -240.0, 420.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    fill_light.set_actor_label("Etherwood Fill Light")
    set_light_intensity(fill_light, 3500.0)

    player_start = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PlayerStart,
        unreal.Vector(0.0, -240.0, 40.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    player_start.set_actor_label("PlayerStart")

    unreal.EditorLevelLibrary.save_current_level()


def main():
    reparent_blueprints()
    rebuild_level()
    unreal.EditorAssetLibrary.save_directory("/Game", only_if_is_dirty=False, recursive=True)
    unreal.log("Mystic Grove Milestone 1 interaction loop updated.")


main()
