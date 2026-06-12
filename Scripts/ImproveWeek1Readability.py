import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

MATERIAL_COLORS = {
    "M_Etherwood_ForestGround_Dark": unreal.LinearColor(0.012, 0.085, 0.028, 1.0),
    "M_Etherwood_DirtPath": unreal.LinearColor(0.22, 0.12, 0.052, 1.0),
}

PATH_LABEL_PREFIX = "Etherwood Dirt Path "


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


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
    color_node = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionConstant4Vector, -360, 0)
    color_node.set_editor_property("constant", color)
    roughness_node = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionConstant, -360, 170)
    roughness_node.set_editor_property("r", 0.9)
    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def apply_material(actor, material):
    if not actor:
        return
    for mesh in actor.get_components_by_class(unreal.StaticMeshComponent):
        slots = max(mesh.get_num_materials(), 1)
        for slot_index in range(slots):
            mesh.set_material(slot_index, material)


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def spawn_path(label, start, end, material):
    midpoint = (start + end) * 0.5
    delta = end - start
    length = math.sqrt(delta.x * delta.x + delta.y * delta.y)
    yaw = math.degrees(math.atan2(delta.y, delta.x))
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, midpoint, unreal.Rotator(0.0, yaw, 0.0))
        actor.set_actor_label(label)

    actor.set_actor_location(unreal.Vector(midpoint.x, midpoint.y, -6.0), False, False)
    actor.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
    actor.set_actor_scale3d(unreal.Vector(length / 100.0, 0.34, 0.035))
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(load_asset("/Engine/BasicShapes/Cube.Cube"))
        mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)


def tune_light(label, intensity):
    actor = find_actor(label)
    if not actor:
        return
    component = actor.get_component_by_class(unreal.LightComponent)
    if component:
        component.set_editor_property("intensity", intensity)


def improve_text_labels():
    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if component:
            component.set_editor_property("text_render_color", unreal.Color(255, 222, 130, 255))
            component.set_editor_property("world_size", 42.0)


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = {name: ensure_material(name, color) for name, color in MATERIAL_COLORS.items()}
    ground_material = materials["M_Etherwood_ForestGround_Dark"]
    path_material = materials["M_Etherwood_DirtPath"]

    apply_material(find_actor("Etherwood Village Ground"), ground_material)
    apply_material(find_actor("Etherwood Background Meadow"), ground_material)

    fairy_house = find_actor("Fairy House")
    flower_grove = find_actor("Flower Grove")
    sacred_pond = find_actor("Sacred Koi Pond")
    if fairy_house and flower_grove:
        spawn_path("Etherwood Dirt Path Fairy To Flower", fairy_house.get_actor_location(), flower_grove.get_actor_location(), path_material)
    if fairy_house and sacred_pond:
        spawn_path("Etherwood Dirt Path Fairy To Pond", fairy_house.get_actor_location(), sacred_pond.get_actor_location(), path_material)
    if flower_grove and sacred_pond:
        spawn_path("Etherwood Dirt Path Flower To Pond", flower_grove.get_actor_location(), sacred_pond.get_actor_location(), path_material)

    tune_light("Etherwood Sun Light", 0.22)
    tune_light("Etherwood Directional Light", 0.18)
    tune_light("Etherwood Sky Light", 0.12)
    tune_light("Etherwood Fill Light", 65.0)
    tune_light("Etherwood Soft Fill Light", 45.0)

    improve_text_labels()

    level_subsystem.save_current_level()
    unreal.log("Week 1 readability pass applied.")


main()
