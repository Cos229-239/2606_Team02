import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"
FLOWER_GROVE_FOCUS_LABEL = "Flower Grove Focus Target"

MATERIAL_COLORS = {
    "M_FlowerGrove_GardenSoil": unreal.LinearColor(0.18, 0.09, 0.04, 1.0),
    "M_FlowerGrove_PathStone": unreal.LinearColor(0.42, 0.37, 0.28, 1.0),
    "M_FlowerGrove_FenceWood": unreal.LinearColor(0.28, 0.15, 0.06, 1.0),
    "M_FlowerGrove_LanternGlow": unreal.LinearColor(1.0, 0.76, 0.22, 1.0),
    "M_FlowerGrove_BlueBloom": unreal.LinearColor(0.10, 0.44, 1.0, 1.0),
    "M_FlowerGrove_PurpleBloom": unreal.LinearColor(0.45, 0.12, 0.82, 1.0),
    "M_FlowerGrove_GoldenBloom": unreal.LinearColor(1.0, 0.66, 0.08, 1.0),
    "M_FlowerGrove_ManaGlow": unreal.LinearColor(0.25, 0.95, 0.78, 1.0),
    "M_FlowerGrove_MushroomStem": unreal.LinearColor(0.82, 0.72, 0.52, 1.0),
    "M_FlowerGrove_MushroomCap": unreal.LinearColor(0.72, 0.10, 0.28, 1.0),
    "M_FlowerGrove_WildflowerPink": unreal.LinearColor(0.95, 0.18, 0.55, 1.0),
    "M_FlowerGrove_WildflowerWhite": unreal.LinearColor(0.95, 0.92, 0.78, 1.0),
}

OLD_LABEL_PREFIXES = [
    "Flower Grove Garden ",
    "Flower Grove Plot ",
    "Flower Grove Fence ",
    "Flower Grove Lantern ",
    "Flower Grove Path ",
    "Flower Grove Mana Flower ",
    "Flower Grove Mushroom ",
    "Flower Grove Wildflower ",
    "Flower Grove Bloom Label ",
]


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
    roughness_node.set_editor_property("r", 0.65)

    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    if emissive:
        unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def build_materials():
    glow_names = {"M_FlowerGrove_LanternGlow", "M_FlowerGrove_ManaGlow"}
    return {name: ensure_material(name, color, name in glow_names) for name, color in MATERIAL_COLORS.items()}


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
    actor.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
    actor.set_is_temporarily_hidden_in_editor(True)
    return actor


def set_text_actor(label, location, text):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.TextRenderActor, location, unreal.Rotator(42.0, 0.0, 0.0))
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(unreal.Rotator(42.0, 0.0, 0.0), False)
    text_component = actor.get_component_by_class(unreal.TextRenderComponent)
    if text_component:
        text_component.set_editor_property("text", text)
        text_component.set_editor_property("world_size", 12.0)
        text_component.set_editor_property("text_render_color", unreal.Color(245, 236, 200, 255))
    return actor


def apply_main_garden_mesh(actor, material):
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if not mesh:
        raise RuntimeError("Flower Grove actor has no StaticMeshComponent.")

    mesh.set_static_mesh(load_asset("/Engine/BasicShapes/Cylinder.Cylinder"))
    mesh.set_material(0, material)
    mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_ONLY)


def add_point_light(label, location, color, intensity=95.0, radius=170.0):
    light = find_actor(label)
    if not light:
        light = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.PointLight, location, unreal.Rotator(0.0, 0.0, 0.0))
        light.set_actor_label(label)

    light.set_actor_location(location, False, False)
    light_component = light.get_component_by_class(unreal.PointLightComponent)
    if light_component:
        light_component.set_editor_property("intensity", intensity)
        light_component.set_editor_property("attenuation_radius", radius)
        light_component.set_editor_property("light_color", color)
        light_component.set_editor_property("cast_shadows", False)


def main():
    unreal.EditorLevelLibrary.load_level(LEVEL_PATH)

    materials = build_materials()
    destroy_old_visuals()

    grove = find_actor("Flower Grove")
    if not grove:
        raise RuntimeError("Missing Flower Grove actor.")

    center = grove.get_actor_location()
    center.z = 52.0

    grove.set_actor_location(center, False, False)
    grove.set_actor_rotation(unreal.Rotator(0.0, 0.0, 0.0), False)
    grove.set_actor_scale3d(unreal.Vector(1.95, 1.95, 0.08))
    apply_main_garden_mesh(grove, materials["M_FlowerGrove_GardenSoil"])

    focus_target = ensure_focus_target(
        FLOWER_GROVE_FOCUS_LABEL,
        center + unreal.Vector(0.0, -440.0, 340.0),
        unreal.Rotator(0.0, -38.0, 0.0),
    )
    grove.set_editor_property("zoom_target", focus_target)
    grove.set_editor_property("zoom_offset", unreal.Vector(0.0, 0.0, 0.0))

    for index in range(9):
        angle = math.radians(index * 40.0)
        location = center + unreal.Vector(math.cos(angle) * 155.0, math.sin(angle) * 155.0, 6.0)
        spawn_static(
            f"Flower Grove Fence Post {index + 1:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            location,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.055, 0.055, 0.40),
            materials["M_FlowerGrove_FenceWood"],
        )

    plot_data = [
        ("Blue Bloom", "M_FlowerGrove_BlueBloom", unreal.Vector(-78.0, 28.0, 14.0), "+1 Mana/sec"),
        ("Purple Bloom", "M_FlowerGrove_PurpleBloom", unreal.Vector(70.0, 24.0, 14.0), "+2 Mana/sec"),
        ("Golden Bloom", "M_FlowerGrove_GoldenBloom", unreal.Vector(0.0, -88.0, 14.0), "+2 Mana/sec"),
    ]
    for index, (name, material_name, offset, mana_text) in enumerate(plot_data, start=1):
        plot_center = center + offset
        spawn_static(
            f"Flower Grove Plot {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            plot_center + unreal.Vector(0.0, 0.0, -7.0),
            unreal.Rotator(0.0, index * 18.0, 0.0),
            unreal.Vector(0.52, 0.38, 0.045),
            materials["M_FlowerGrove_PathStone"],
        )
        for petal in range(6):
            angle = math.radians(petal * 60.0)
            petal_location = plot_center + unreal.Vector(math.cos(angle) * 19.0, math.sin(angle) * 19.0, 16.0)
            spawn_static(
                f"Flower Grove Mana Flower {index:02d}-{petal + 1:02d}",
                "/Engine/BasicShapes/Sphere.Sphere",
                petal_location,
                unreal.Rotator(0.0, 0.0, 0.0),
                unreal.Vector(0.11, 0.11, 0.08),
                materials[material_name],
            )
        spawn_static(
            f"Flower Grove Mana Flower Glow {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            plot_center + unreal.Vector(0.0, 0.0, 32.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.13, 0.13, 0.13),
            materials["M_FlowerGrove_ManaGlow"],
        )
        add_point_light(
            f"Flower Grove Mana Flower Light {index:02d}",
            plot_center + unreal.Vector(0.0, 0.0, 54.0),
            unreal.Color(100, 255, 210, 255),
        )
        set_text_actor(
            f"Flower Grove Bloom Label {index:02d}",
            plot_center + unreal.Vector(0.0, 0.0, 76.0),
            f"{name} Lv. 1  {mana_text}",
        )

    for index in range(5):
        spawn_static(
            f"Flower Grove Path Stone {index + 1:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            center + unreal.Vector(0.0, -150.0 - index * 44.0, 0.0),
            unreal.Rotator(0.0, index * 11.0, 0.0),
            unreal.Vector(0.34, 0.24, 0.035),
            materials["M_FlowerGrove_PathStone"],
        )

    lantern_points = [(-138.0, -72.0), (138.0, -72.0), (-92.0, 130.0), (92.0, 130.0)]
    for index, (x, y) in enumerate(lantern_points, start=1):
        post_location = center + unreal.Vector(x, y, 18.0)
        spawn_static(
            f"Flower Grove Lantern Post {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            post_location,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.045, 0.045, 0.42),
            materials["M_FlowerGrove_FenceWood"],
        )
        glow_location = post_location + unreal.Vector(0.0, 0.0, 45.0)
        spawn_static(
            f"Flower Grove Lantern Glow {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            glow_location,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.10, 0.10, 0.10),
            materials["M_FlowerGrove_LanternGlow"],
        )
        add_point_light(f"Flower Grove Lantern Light {index:02d}", glow_location, unreal.Color(255, 205, 105, 255), 75.0, 150.0)

    decor_points = [(-164.0, 10.0), (164.0, 16.0), (-122.0, -132.0), (122.0, -132.0), (-34.0, 164.0), (42.0, 166.0)]
    for index, (x, y) in enumerate(decor_points, start=1):
        base = center + unreal.Vector(x, y, 6.0)
        spawn_static(
            f"Flower Grove Mushroom Stem {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            base,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.045, 0.045, 0.14),
            materials["M_FlowerGrove_MushroomStem"],
        )
        spawn_static(
            f"Flower Grove Mushroom Cap {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            base + unreal.Vector(0.0, 0.0, 17.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.14, 0.14, 0.065),
            materials["M_FlowerGrove_MushroomCap"],
        )
        wildflower_mat = materials["M_FlowerGrove_WildflowerPink"] if index % 2 else materials["M_FlowerGrove_WildflowerWhite"]
        spawn_static(
            f"Flower Grove Wildflower Edge {index:02d}",
            "/Engine/BasicShapes/Sphere.Sphere",
            base + unreal.Vector(x * -0.08, y * -0.08, 8.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.08, 0.08, 0.06),
            wildflower_mat,
        )

    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).save_current_level()
    unreal.log("Flower Grove visual prototype dressed as a magical flower garden.")


main()
