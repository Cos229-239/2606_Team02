import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

MATERIAL_COLORS = {
    "M_SacredPond_Water": unreal.LinearColor(0.02, 0.20, 0.52, 1.0),
    "M_SacredPond_Waterfall": unreal.LinearColor(0.40, 0.82, 0.95, 1.0),
    "M_SacredPond_Stone": unreal.LinearColor(0.28, 0.27, 0.24, 1.0),
    "M_SacredPond_LilyPad": unreal.LinearColor(0.05, 0.38, 0.13, 1.0),
    "M_SacredPond_KoiOrange": unreal.LinearColor(0.95, 0.32, 0.05, 1.0),
    "M_SacredPond_KoiWhite": unreal.LinearColor(0.92, 0.88, 0.76, 1.0),
    "M_SacredPond_LanternWood": unreal.LinearColor(0.18, 0.08, 0.03, 1.0),
    "M_SacredPond_LanternGlow": unreal.LinearColor(1.0, 0.72, 0.20, 1.0),
}

OLD_LABEL_PREFIXES = [
    "Sacred Pond Stone ",
    "Sacred Pond Lily ",
    "Sacred Pond Koi ",
    "Sacred Pond Lantern ",
    "Sacred Pond Waterfall ",
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
    roughness_node.set_editor_property("r", 0.55)

    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def build_materials():
    return {name: ensure_material(name, color) for name, color in MATERIAL_COLORS.items()}


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


def apply_mesh(actor, mesh_path, material):
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if not mesh:
        raise RuntimeError("Sacred Koi Pond actor has no StaticMeshComponent.")

    mesh.set_static_mesh(load_asset(mesh_path))
    mesh.set_material(0, material)
    mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_ONLY)


def destroy_old_pond_visuals():
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in list(actor_subsystem.get_all_level_actors()):
        label = actor.get_actor_label()
        if any(label.startswith(prefix) for prefix in OLD_LABEL_PREFIXES):
            actor_subsystem.destroy_actor(actor)


def oval_point(center, radius_x, radius_y, degrees, z=0.0):
    radians = math.radians(degrees)
    return center + unreal.Vector(math.cos(radians) * radius_x, math.sin(radians) * radius_y, z)


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = build_materials()
    destroy_old_pond_visuals()

    pond = find_actor("Sacred Koi Pond")
    if not pond:
        raise RuntimeError("Missing Sacred Koi Pond actor.")

    center = pond.get_actor_location()
    center.z = 44.0

    # The clickable building actor becomes the water surface.
    pond.set_actor_location(center, False, False)
    pond.set_actor_rotation(unreal.Rotator(0.0, 0.0, 0.0), False)
    pond.set_actor_scale3d(unreal.Vector(4.4, 3.0, 1.0))
    focus_target = find_actor("Sacred Pond Focus Target")
    if not focus_target:
        focus_target = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.Actor,
            center + unreal.Vector(215.0, 430.0, 0.0),
            unreal.Rotator(0.0, 0.0, 0.0),
        )
        focus_target.set_actor_label("Sacred Pond Focus Target")
    focus_target.set_actor_location(center + unreal.Vector(215.0, 430.0, 0.0), False, False)
    focus_target.set_actor_rotation(unreal.Rotator(0.0, -90.0, 85.0), False)
    pond.set_editor_property("zoom_offset", unreal.Vector(0.0, -1.0, 620.0))
    pond.set_editor_property("zoom_target", focus_target)
    apply_mesh(pond, "/Engine/BasicShapes/Plane.Plane", materials["M_SacredPond_Water"])

    # Chunky stone ring around the water.
    for index, degrees in enumerate(range(0, 360, 24), start=1):
        location = oval_point(center, 250.0, 175.0, degrees, 8.0)
        scale = unreal.Vector(0.42, 0.32, 0.12)
        rotation = unreal.Rotator(0.0, degrees, 0.0)
        spawn_static(
            f"Sacred Pond Stone {index:02d}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            location,
            rotation,
            scale,
            materials["M_SacredPond_Stone"],
        )

    # Lily pads on top of the water.
    lily_specs = [
        ("01", -92.0, -42.0, 18.0),
        ("02", 74.0, 28.0, -18.0),
        ("03", 24.0, -86.0, 42.0),
    ]
    for suffix, x, y, yaw in lily_specs:
        spawn_static(
            f"Sacred Pond Lily {suffix}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            center + unreal.Vector(x, y, 12.0),
            unreal.Rotator(0.0, yaw, 0.0),
            unreal.Vector(0.34, 0.24, 0.025),
            materials["M_SacredPond_LilyPad"],
        )

    # Placeholder koi: simple orange/white fish markers.
    koi_specs = [
        ("01", -38.0, 28.0, 25.0, "M_SacredPond_KoiOrange"),
        ("02", 52.0, -34.0, -38.0, "M_SacredPond_KoiWhite"),
        ("03", 104.0, 46.0, 72.0, "M_SacredPond_KoiOrange"),
    ]
    for suffix, x, y, yaw, mat_key in koi_specs:
        spawn_static(
            f"Sacred Pond Koi {suffix}",
            "/Engine/BasicShapes/Cone.Cone",
            center + unreal.Vector(x, y, 18.0),
            unreal.Rotator(90.0, yaw, 0.0),
            unreal.Vector(0.20, 0.10, 0.08),
            materials[mat_key],
        )

    # Lantern posts with glow caps and point lights.
    lantern_specs = [
        ("01", -250.0, -190.0),
        ("02", 250.0, -190.0),
        ("03", -250.0, 190.0),
        ("04", 250.0, 190.0),
    ]
    for suffix, x, y in lantern_specs:
        base = center + unreal.Vector(x, y, 25.0)
        spawn_static(
            f"Sacred Pond Lantern Post {suffix}",
            "/Engine/BasicShapes/Cylinder.Cylinder",
            base,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.08, 0.08, 0.45),
            materials["M_SacredPond_LanternWood"],
        )
        spawn_static(
            f"Sacred Pond Lantern Glow {suffix}",
            "/Engine/BasicShapes/Sphere.Sphere",
            base + unreal.Vector(0.0, 0.0, 54.0),
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(0.16, 0.16, 0.16),
            materials["M_SacredPond_LanternGlow"],
        )
        light = find_actor(f"Sacred Pond Lantern Light {suffix}")
        if not light:
            light = unreal.EditorLevelLibrary.spawn_actor_from_class(
                unreal.PointLight,
                base + unreal.Vector(0.0, 0.0, 70.0),
                unreal.Rotator(0.0, 0.0, 0.0),
            )
            light.set_actor_label(f"Sacred Pond Lantern Light {suffix}")
        light_component = light.get_component_by_class(unreal.PointLightComponent)
        if light_component:
            light_component.set_editor_property("intensity", 90.0)
            light_component.set_editor_property("attenuation_radius", 210.0)
            light_component.set_editor_property("light_color", unreal.Color(255, 188, 84, 255))
            light_component.set_editor_property("cast_shadows", False)

    # Small waterfall feeding into the top of the pond.
    waterfall_origin = center + unreal.Vector(0.0, 232.0, 48.0)
    spawn_static(
        "Sacred Pond Waterfall Rock Back",
        "/Engine/BasicShapes/Cube.Cube",
        waterfall_origin + unreal.Vector(0.0, 34.0, 14.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(1.6, 0.32, 0.42),
        materials["M_SacredPond_Stone"],
    )
    spawn_static(
        "Sacred Pond Waterfall Stream",
        "/Engine/BasicShapes/Cube.Cube",
        waterfall_origin + unreal.Vector(0.0, 5.0, 30.0),
        unreal.Rotator(-25.0, 0.0, 0.0),
        unreal.Vector(0.75, 0.08, 0.42),
        materials["M_SacredPond_Waterfall"],
    )
    spawn_static(
        "Sacred Pond Waterfall Foam",
        "/Engine/BasicShapes/Cylinder.Cylinder",
        center + unreal.Vector(0.0, 150.0, 15.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(0.45, 0.20, 0.018),
        materials["M_SacredPond_Waterfall"],
    )

    level_subsystem.save_current_level()
    unreal.log("Sacred Pond visual prototype dressed with water, stones, lily pads, koi, lanterns, and waterfall.")


main()
