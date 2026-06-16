import unreal


LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"


MATERIALS = {
    "M_FlowerPlot_LockedCover": unreal.LinearColor(0.05, 0.04, 0.055, 1.0),
    "M_FlowerPlot_ActiveGlow": unreal.LinearColor(0.36, 0.90, 0.58, 1.0),
    "M_FlowerGrove_LevelPulse": unreal.LinearColor(0.82, 0.42, 1.0, 1.0),
}


def find_actor(label):
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in subsystem.get_all_level_actors():
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
        material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(name, MATERIAL_FOLDER, unreal.Material, unreal.MaterialFactoryNew())

    material.set_editor_property("use_material_attributes", False)
    unreal.MaterialEditingLibrary.delete_all_material_expressions(material)

    color_node = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionConstant4Vector, -360, 0)
    color_node.set_editor_property("constant", color)
    roughness_node = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionConstant, -360, 170)
    roughness_node.set_editor_property("r", 0.5)
    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    if emissive:
        unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def set_hidden_in_game(actor, hidden):
    try:
        actor.set_actor_hidden_in_game(hidden)
    except Exception:
        actor.set_editor_property("actor_hidden_in_game", hidden)


def spawn_static(label, mesh_path, location, rotation, scale, material, hidden):
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


def main():
    unreal.EditorLoadingAndSavingUtils.load_map(LEVEL_PATH)
    locked = ensure_material("M_FlowerPlot_LockedCover", MATERIALS["M_FlowerPlot_LockedCover"], False)
    glow = ensure_material("M_FlowerPlot_ActiveGlow", MATERIALS["M_FlowerPlot_ActiveGlow"], True)
    pulse = ensure_material("M_FlowerGrove_LevelPulse", MATERIALS["M_FlowerGrove_LevelPulse"], True)

    spawn_static(
        "Flower Grove Locked Plot 04",
        "/Engine/BasicShapes/Cylinder.Cylinder",
        unreal.Vector(520.0, -110.0, 14.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.70, 0.70, 0.07),
        locked,
        False,
    )
    spawn_static(
        "Flower Grove Locked Plot 05",
        "/Engine/BasicShapes/Cylinder.Cylinder",
        unreal.Vector(610.0, -210.0, 14.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.70, 0.70, 0.07),
        locked,
        False,
    )
    spawn_static(
        "Flower Grove Active Plot Glow 04",
        "/Engine/BasicShapes/Sphere.Sphere",
        unreal.Vector(520.0, -110.0, 24.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.46, 0.46, 0.08),
        glow,
        True,
    )
    spawn_static(
        "Flower Grove Active Plot Glow 05",
        "/Engine/BasicShapes/Sphere.Sphere",
        unreal.Vector(610.0, -210.0, 24.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.46, 0.46, 0.08),
        glow,
        True,
    )
    spawn_static(
        "Flower Grove Level Up Pulse",
        "/Engine/BasicShapes/Cylinder.Cylinder",
        unreal.Vector(550.0, -160.0, 18.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(2.55, 2.0, 0.035),
        pulse,
        True,
    )

    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
    unreal.log("Flower Grove upgrade visual setup complete")


main()
