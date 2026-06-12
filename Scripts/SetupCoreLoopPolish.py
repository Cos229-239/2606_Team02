import unreal


LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"


MATERIALS = {
    "M_CoreLoop_RestorationFlower": unreal.LinearColor(0.72, 0.18, 0.88, 1.0),
    "M_CoreLoop_PondGlow": unreal.LinearColor(0.06, 0.42, 0.95, 1.0),
    "M_CoreLoop_FairyLight": unreal.LinearColor(1.0, 0.72, 0.20, 1.0),
    "M_CoreLoop_TreeGlow": unreal.LinearColor(0.20, 0.95, 0.66, 1.0),
}


def find_actor(label):
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in actor_subsystem.get_all_level_actors():
        if actor.get_actor_label() == label:
            return actor
    return None


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def ensure_material(name, color, emissive=False):
    if not unreal.EditorAssetLibrary.does_directory_exist(MATERIAL_FOLDER):
        unreal.EditorAssetLibrary.make_directory(MATERIAL_FOLDER)

    path = f"{MATERIAL_FOLDER}/{name}"
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        material = unreal.EditorAssetLibrary.load_asset(path)
    else:
        material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            name,
            MATERIAL_FOLDER,
            unreal.Material,
            unreal.MaterialFactoryNew(),
        )

    material.set_editor_property("use_material_attributes", False)
    unreal.MaterialEditingLibrary.delete_all_material_expressions(material)

    color_node = unreal.MaterialEditingLibrary.create_material_expression(
        material,
        unreal.MaterialExpressionConstant4Vector,
        -360,
        0,
    )
    color_node.set_editor_property("constant", color)

    roughness_node = unreal.MaterialEditingLibrary.create_material_expression(
        material,
        unreal.MaterialExpressionConstant,
        -360,
        170,
    )
    roughness_node.set_editor_property("r", 0.45)

    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    if emissive:
        unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def build_materials():
    return {
        name: ensure_material(name, color, True)
        for name, color in MATERIALS.items()
    }


def set_hidden_in_game(actor, hidden):
    try:
        actor.set_actor_hidden_in_game(hidden)
    except Exception:
        actor.set_editor_property("actor_hidden_in_game", hidden)


def spawn_static(label, mesh_path, location, rotation, scale, material, hidden=True):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, location, rotation)
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(rotation, False)
    actor.set_actor_scale3d(scale)
    set_hidden_in_game(actor, hidden)

    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(load_asset(mesh_path))
        mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
    return actor


def spawn_point_light(label, location, color, intensity, radius, hidden=True):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.PointLight, location, unreal.Rotator(0.0, 0.0, 0.0))
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    set_hidden_in_game(actor, hidden)

    light = actor.get_component_by_class(unreal.PointLightComponent)
    if light:
        light.set_editor_property("intensity", intensity)
        light.set_editor_property("attenuation_radius", radius)
        light.set_editor_property("light_color", color)
    return actor


def ensure_fairy_loop():
    actor = find_actor("Luna Fairy Movement Loop")
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.MysticFairyLoopActor,
            unreal.Vector(-420.0, -170.0, 95.0),
            unreal.Rotator(0.0, 0.0, 0.0),
        )
        actor.set_actor_label("Luna Fairy Movement Loop")

    actor.set_actor_location(unreal.Vector(-420.0, -170.0, 95.0), False, False)
    actor.set_actor_rotation(unreal.Rotator(0.0, 0.0, 0.0), False)
    actor.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
    actor.set_editor_property("fairy_house_label", "Fairy House")
    actor.set_editor_property("flower_grove_label", "Flower Grove")
    actor.set_editor_property("sacred_pond_label", "Sacred Koi Pond")
    actor.set_editor_property("move_speed", 110.0)
    set_hidden_in_game(actor, False)
    return actor


def main():
    unreal.EditorLoadingAndSavingUtils.load_map(LEVEL_PATH)
    materials = build_materials()

    # These are hidden in game until Sacred Pond purity reaches the matching threshold.
    spawn_static(
        "Core Loop Extra Flowers 25",
        "/Engine/BasicShapes/Sphere.Sphere",
        unreal.Vector(210.0, 230.0, 18.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.42, 0.42, 0.12),
        materials["M_CoreLoop_RestorationFlower"],
    )
    spawn_static(
        "Core Loop Pond Glow 50",
        "/Engine/BasicShapes/Cylinder.Cylinder",
        unreal.Vector(150.0, 185.0, 9.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(2.8, 2.0, 0.035),
        materials["M_CoreLoop_PondGlow"],
    )
    spawn_point_light(
        "Core Loop Fairy Lights 75",
        unreal.Vector(150.0, 180.0, 135.0),
        unreal.Color(255, 210, 110, 255),
        260.0,
        420.0,
    )
    spawn_point_light(
        "Core Loop Ancient Tree Glow 100",
        unreal.Vector(30.0, 390.0, 185.0),
        unreal.Color(110, 255, 190, 255),
        420.0,
        520.0,
    )
    ensure_fairy_loop()

    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
    unreal.log("Core loop polish map setup complete")


main()
