import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

AREA_LABELS = {
    "Fairy House Label": {
        "target": "Fairy House",
        "text": "Fairy House",
        "offset": unreal.Vector(-40.0, -18.0, 128.0),
    },
    "Sacred Koi Pond Label": {
        "target": "Sacred Koi Pond",
        "text": "Sacred Koi Pond",
        "offset": unreal.Vector(0.0, -10.0, 92.0),
    },
    "Flower Grove Label": {
        "target": "Flower Grove",
        "text": "Flower Grove",
        "offset": unreal.Vector(0.0, -28.0, 96.0),
    },
}

MATERIAL_COLORS = {
    "M_Etherwood_ForestGround_Dark": unreal.LinearColor(0.018, 0.16, 0.045, 1.0),
    "M_Etherwood_DirtPath": unreal.LinearColor(0.30, 0.17, 0.07, 1.0),
    "M_Etherwood_PondWater_Readable": unreal.LinearColor(0.0, 0.06, 0.36, 1.0),
    "M_Etherwood_FlowerPatch_Readable": unreal.LinearColor(0.07, 0.032, 0.16, 1.0),
    "M_Etherwood_WarmWood": unreal.LinearColor(0.42, 0.24, 0.12, 1.0),
    "M_Etherwood_LabelBacking": unreal.LinearColor(0.005, 0.007, 0.012, 1.0),
}

DUPLICATE_LABEL_HINTS = (
    "Fairy House Label Shadow",
    "Sacred Koi Pond Label Shadow",
    "Flower Grove Label Shadow",
)

FLOWER_LABELS = {
    "Flower Grove Bloom Label 01": {
        "target": "Flower Grove Plot 01",
        "text": "Blue Bloom Lv. 1  +1 Mana/sec",
        "offset": unreal.Vector(-22.0, -34.0, 34.0),
    },
    "Flower Grove Bloom Label 02": {
        "target": "Flower Grove Plot 02",
        "text": "Purple Bloom Lv. 1  +2 Mana/sec",
        "offset": unreal.Vector(24.0, -34.0, 34.0),
    },
    "Flower Grove Bloom Label 03": {
        "target": "Flower Grove Plot 03",
        "text": "Golden Bloom Lv. 1  +2 Mana/sec",
        "offset": unreal.Vector(0.0, -42.0, 34.0),
    },
}


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def set_text(component, label_text):
    try:
        component.set_text(unreal.Text(label_text))
    except Exception:
        component.set_editor_property("text", unreal.Text(label_text))


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


def set_actor_hidden(actor, hidden):
    if actor:
        actor.set_actor_hidden_in_game(hidden)
        actor.set_is_temporarily_hidden_in_editor(hidden)


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def spawn_or_update_path(label, start, end, material):
    midpoint = (start + end) * 0.5
    delta = end - start
    length = math.sqrt(delta.x * delta.x + delta.y * delta.y)
    yaw = math.degrees(math.atan2(delta.y, delta.x))
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, midpoint, unreal.Rotator(0.0, yaw, 0.0))
        actor.set_actor_label(label)

    actor.set_actor_location(unreal.Vector(midpoint.x, midpoint.y, -5.0), False, False)
    actor.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
    actor.set_actor_scale3d(unreal.Vector(length / 100.0, 0.44, 0.035))
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(load_asset("/Engine/BasicShapes/Cube.Cube"))
        mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)


def spawn_or_update_backing(label, location, rotation, scale, material):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, location, rotation)
        actor.set_actor_label(label)

    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(rotation, False)
    actor.set_actor_scale3d(scale)
    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(load_asset("/Engine/BasicShapes/Cube.Cube"))
        mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
    return actor


def tune_light(label, intensity, color=None):
    actor = find_actor(label)
    if not actor:
        return
    component = actor.get_component_by_class(unreal.LightComponent)
    if component:
        component.set_editor_property("intensity", intensity)
        if color:
            component.set_editor_property("light_color", color)


def destroy_duplicate_labels():
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    canonical = set(AREA_LABELS.keys())
    area_texts = {config["text"] for config in AREA_LABELS.values()}

    for actor in list(actor_subsystem.get_all_level_actors()):
        label = actor.get_actor_label()
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        text_value = str(component.get_editor_property("text")) if component else ""

        if label in canonical:
            continue

        is_duplicate_area_label = component and text_value in area_texts
        is_extra_flower_label = label.startswith("Flower Grove Bloom Label ") and label not in FLOWER_LABELS
        is_old_shadow = label.endswith(" Shadow") or label in DUPLICATE_LABEL_HINTS
        if is_duplicate_area_label or is_old_shadow or is_extra_flower_label:
            actor_subsystem.destroy_actor(actor)


def clean_area_labels(materials):
    destroy_duplicate_labels()
    label_rotation = unreal.Rotator(42.0, 0.0, 0.0)

    for label, config in AREA_LABELS.items():
        actor = find_actor(label)
        target = find_actor(config["target"])
        if not actor:
            raise RuntimeError(f"Missing existing label actor: {label}")
        if not target:
            raise RuntimeError(f"Missing label target: {config['target']}")

        location = target.get_actor_location() + config["offset"]
        actor.set_actor_location(location, False, False)
        actor.set_actor_rotation(label_rotation, False)
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if component:
            set_text(component, config["text"])
            component.set_editor_property("world_size", 27.0)
            component.set_editor_property("text_render_color", unreal.Color(255, 224, 130, 255))
            component.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        spawn_or_update_backing(
            label + " Backing",
            location + unreal.Vector(0.0, 2.0, -3.0),
            label_rotation,
            unreal.Vector(1.65, 0.08, 0.34),
            materials["M_Etherwood_LabelBacking"],
        )


def clean_flower_labels(materials):
    label_rotation = unreal.Rotator(42.0, 0.0, 0.0)

    for label, config in FLOWER_LABELS.items():
        actor = find_actor(label)
        target = find_actor(config["target"])
        if not actor:
            raise RuntimeError(f"Missing existing flower label actor: {label}")
        if not target:
            raise RuntimeError(f"Missing flower label target: {config['target']}")

        location = target.get_actor_location() + config["offset"]
        actor.set_actor_location(location, False, False)
        actor.set_actor_rotation(label_rotation, False)
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if component:
            set_text(component, config["text"])
            component.set_editor_property("world_size", 12.0)
            component.set_editor_property("text_render_color", unreal.Color(245, 236, 200, 255))
            component.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        spawn_or_update_backing(
            label + " Backing",
            location + unreal.Vector(0.0, 1.0, -2.0),
            label_rotation,
            unreal.Vector(1.42, 0.055, 0.18),
            materials["M_Etherwood_LabelBacking"],
        )


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = {name: ensure_material(name, color) for name, color in MATERIAL_COLORS.items()}
    apply_material(find_actor("Etherwood Village Ground"), materials["M_Etherwood_ForestGround_Dark"])
    apply_material(find_actor("Etherwood Background Meadow"), materials["M_Etherwood_ForestGround_Dark"])
    apply_material(find_actor("Sacred Koi Pond"), materials["M_Etherwood_PondWater_Readable"])
    apply_material(find_actor("Flower Grove"), materials["M_Etherwood_FlowerPatch_Readable"])
    apply_material(find_actor("Fairy House"), materials["M_Etherwood_WarmWood"])
    apply_material(find_actor("Flower Grove Plot 01"), materials["M_Etherwood_DirtPath"])
    apply_material(find_actor("Flower Grove Plot 02"), materials["M_Etherwood_DirtPath"])
    apply_material(find_actor("Flower Grove Plot 03"), materials["M_Etherwood_DirtPath"])

    fairy_house = find_actor("Fairy House")
    flower_grove = find_actor("Flower Grove")
    sacred_pond = find_actor("Sacred Koi Pond")
    if fairy_house and flower_grove:
        spawn_or_update_path("Etherwood Dirt Path Fairy To Flower", fairy_house.get_actor_location(), flower_grove.get_actor_location(), materials["M_Etherwood_DirtPath"])
    if fairy_house and sacred_pond:
        spawn_or_update_path("Etherwood Dirt Path Fairy To Pond", fairy_house.get_actor_location(), sacred_pond.get_actor_location(), materials["M_Etherwood_DirtPath"])
    if flower_grove and sacred_pond:
        spawn_or_update_path("Etherwood Dirt Path Flower To Pond", flower_grove.get_actor_location(), sacred_pond.get_actor_location(), materials["M_Etherwood_DirtPath"])

    tune_light("Etherwood Sun Light", 0.22, unreal.Color(255, 198, 138, 255))
    tune_light("Etherwood Directional Light", 0.18, unreal.Color(255, 198, 138, 255))
    tune_light("Etherwood Sky Light", 0.12, unreal.Color(150, 168, 185, 255))
    tune_light("Etherwood Fill Light", 65.0, unreal.Color(255, 185, 120, 255))
    tune_light("Etherwood Soft Fill Light", 45.0, unreal.Color(255, 185, 120, 255))

    clean_area_labels(materials)
    clean_flower_labels(materials)

    level_subsystem.save_current_level()
    unreal.log("Village overview labels, lighting, ground, and paths cleaned for readability.")


main()
