import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

MATERIAL_COLORS = {
    "M_FairyHouse_Walls": unreal.LinearColor(0.42, 0.24, 0.13, 1.0),
    "M_FairyHouse_RoofPurple": unreal.LinearColor(0.30, 0.10, 0.52, 1.0),
    "M_FairyHouse_WindowGlow": unreal.LinearColor(1.0, 0.68, 0.22, 1.0),
    "M_FairyHouse_PorchWood": unreal.LinearColor(0.24, 0.12, 0.05, 1.0),
    "M_FairyHouse_PathStone": unreal.LinearColor(0.38, 0.35, 0.30, 1.0),
    "M_FairyHouse_Fence": unreal.LinearColor(0.30, 0.18, 0.08, 1.0),
    "M_FairyHouse_MushroomStem": unreal.LinearColor(0.88, 0.78, 0.58, 1.0),
    "M_FairyHouse_MushroomCap": unreal.LinearColor(0.62, 0.08, 0.18, 1.0),
    "M_FairyHouse_FlowersPink": unreal.LinearColor(0.95, 0.18, 0.55, 1.0),
    "M_FairyHouse_FlowersBlue": unreal.LinearColor(0.25, 0.42, 1.0, 1.0),
    "M_FairyHouse_FairyLight": unreal.LinearColor(1.0, 0.82, 0.28, 1.0),
}

OLD_LABEL_PREFIXES = [
    "Fairy Cottage ",
    "Fairy House Path ",
    "Fairy House Fence ",
    "Fairy House Mushroom ",
    "Fairy House Flower ",
    "Fairy House Light ",
]

FAIRY_HOUSE_FOCUS_LABEL = "Fairy House Focus Target"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def ensure_material(name, color):
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
    roughness_node.set_editor_property("r", 0.7)

    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def build_materials():
    return {name: ensure_material(name, color) for name, color in MATERIAL_COLORS.items()}


def destroy_old_visuals():
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in list(actor_subsystem.get_all_level_actors()):
        label = actor.get_actor_label()
        if any(label.startswith(prefix) for prefix in OLD_LABEL_PREFIXES):
            actor_subsystem.destroy_actor(actor)


def spawn_static(label, mesh_path, location, rotation, scale, material, collision=False):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, location, rotation)
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(rotation, False)
    actor.set_actor_scale3d(scale)

    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(load_asset(mesh_path))
        mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_ONLY if collision else unreal.CollisionEnabled.NO_COLLISION)
    return actor


def ensure_focus_target(label, location, rotation):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.Actor, location, rotation)
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(rotation, False)
    actor.set_is_temporarily_hidden_in_editor(True)
    return actor


def apply_main_house_mesh(actor, material):
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if not mesh:
        raise RuntimeError("Fairy House actor has no StaticMeshComponent.")

    mesh.set_static_mesh(load_asset("/Engine/BasicShapes/Cube.Cube"))
    mesh.set_material(0, material)
    mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_ONLY)


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = build_materials()
    destroy_old_visuals()

    house = find_actor("Fairy House")
    if not house:
        raise RuntimeError("Missing Fairy House actor.")

    center = house.get_actor_location()
    center.z = 72.0

    # Existing clickable building actor becomes the cottage body.
    house.set_actor_location(center, False, False)
    house.set_actor_rotation(unreal.Rotator(0.0, 0.0, 0.0), False)
    house.set_actor_scale3d(unreal.Vector(1.35, 1.1, 0.95))

    focus_location = unreal.Vector(300.0, -470.0, 390.0)
    focus_rotation = unreal.Rotator(0.0, -30.0, 50.0)
    zoom_offset = unreal.Vector(0.0, 0.0, 0.0)
    focus_target = ensure_focus_target(FAIRY_HOUSE_FOCUS_LABEL, focus_location, focus_rotation)
    house.set_editor_property("zoom_offset", zoom_offset)
    house.set_editor_property("zoom_target", focus_target)
    apply_main_house_mesh(house, materials["M_FairyHouse_Walls"])

    # Purple fantasy roof.
    spawn_static(
        "Fairy Cottage Purple Roof",
        "/Engine/BasicShapes/Cone.Cone",
        center + unreal.Vector(0.0, 0.0, 88.0),
        unreal.Rotator(0.0, 45.0, 0.0),
        unreal.Vector(1.55, 1.35, 0.75),
        materials["M_FairyHouse_RoofPurple"],
    )

    # Warm windows and door.
    window_positions = [
        ("Front Left", unreal.Vector(-38.0, -58.0, 22.0)),
        ("Front Right", unreal.Vector(38.0, -58.0, 22.0)),
        ("Side", unreal.Vector(-72.0, 0.0, 24.0)),
    ]
    for suffix, offset in window_positions:
        spawn_static(
            f"Fairy Cottage Window {suffix}",
            "/Engine/BasicShapes/Cube.Cube",
            center + offset,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.24, 0.04, 0.22),
            materials["M_FairyHouse_WindowGlow"],
        )
    spawn_static(
        "Fairy Cottage Front Door",
        "/Engine/BasicShapes/Cube.Cube",
        center + unreal.Vector(0.0, -60.0, -12.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.32, 0.05, 0.50),
        materials["M_FairyHouse_PorchWood"],
    )

    # Porch and path.
    spawn_static(
        "Fairy Cottage Porch",
        "/Engine/BasicShapes/Cube.Cube",
        center + unreal.Vector(0.0, -92.0, -44.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(1.0, 0.35, 0.10),
        materials["M_FairyHouse_PorchWood"],
    )

    for index in range(5):
        spawn_static(
            f"Fairy House Path Stone {index + 1}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            center + unreal.Vector(0.0, -145.0 - index * 52.0, -48.0),
            unreal.Rotator(0.0, index * 9.0, 0.0),
            unreal.Vector(0.42, 0.30, 0.035),
            materials["M_FairyHouse_PathStone"],
        )

    # Fence around the cottage.
    fence_points = [
        (-150.0, -150.0), (-75.0, -170.0), (75.0, -170.0), (150.0, -150.0),
        (-155.0, -55.0), (155.0, -55.0), (-150.0, 70.0), (-75.0, 105.0),
        (75.0, 105.0), (150.0, 70.0),
    ]
    for index, (x, y) in enumerate(fence_points, start=1):
        spawn_static(
            f"Fairy House Fence Post {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            center + unreal.Vector(x, y, -18.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.055, 0.055, 0.34),
            materials["M_FairyHouse_Fence"],
        )

    # Mushrooms, flowers, and fairy lights.
    decor_points = [
        (-118.0, -102.0), (118.0, -118.0), (-132.0, 40.0), (132.0, 30.0),
        (-58.0, 130.0), (62.0, 128.0),
    ]
    for index, (x, y) in enumerate(decor_points, start=1):
        mushroom_base = center + unreal.Vector(x, y, -38.0)
        spawn_static(
            f"Fairy House Mushroom Stem {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            mushroom_base,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.06, 0.06, 0.16),
            materials["M_FairyHouse_MushroomStem"],
        )
        spawn_static(
            f"Fairy House Mushroom Cap {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            mushroom_base + unreal.Vector(0.0, 0.0, 20.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.18, 0.18, 0.08),
            materials["M_FairyHouse_MushroomCap"],
        )

        flower_mat = materials["M_FairyHouse_FlowersPink"] if index % 2 else materials["M_FairyHouse_FlowersBlue"]
        spawn_static(
            f"Fairy House Flower Cluster {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            center + unreal.Vector(x * 0.86, y * 0.86, -38.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.12, 0.12, 0.08),
            flower_mat,
        )

    light_points = [(-120.0, -55.0), (-70.0, 90.0), (0.0, 132.0), (70.0, 90.0), (120.0, -55.0)]
    for index, (x, y) in enumerate(light_points, start=1):
        location = center + unreal.Vector(x, y, 42.0)
        spawn_static(
            f"Fairy House Light Orb {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            location,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.09, 0.09, 0.09),
            materials["M_FairyHouse_FairyLight"],
        )
        light = find_actor(f"Fairy House Light {index:02d}")
        if not light:
            light = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.PointLight, location, unreal.Rotator(0.0, 0.0, 0.0))
            light.set_actor_label(f"Fairy House Light {index:02d}")
        light.set_actor_location(location, False, False)
        light_component = light.get_component_by_class(unreal.PointLightComponent)
        if light_component:
            light_component.set_editor_property("intensity", 60.0)
            light_component.set_editor_property("attenuation_radius", 180.0)
            light_component.set_editor_property("light_color", unreal.Color(255, 210, 95, 255))
            light_component.set_editor_property("cast_shadows", False)

    level_subsystem.save_current_level()
    unreal.log("Fairy House visual prototype dressed as a cozy fantasy cottage.")


main()
