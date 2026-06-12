import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

MATERIAL_COLORS = {
    "M_Etherwood_Grass": unreal.LinearColor(0.006, 0.075, 0.024, 1.0),
    "M_Etherwood_FlowerGrove": unreal.LinearColor(0.08, 0.035, 0.18, 1.0),
    "M_Etherwood_Plaza": unreal.LinearColor(0.006, 0.075, 0.024, 1.0),
    "M_Etherwood_PondWater": unreal.LinearColor(0.0, 0.105, 0.34, 1.0),
    "M_Etherwood_Wood": unreal.LinearColor(0.22, 0.11, 0.035, 1.0),
    "M_Etherwood_ForestEdge": unreal.LinearColor(0.015, 0.08, 0.025, 1.0),
    "M_Etherwood_Hill": unreal.LinearColor(0.23, 0.20, 0.15, 1.0),
}

ACTOR_MATERIALS = {
    "Etherwood Village Ground": "M_Etherwood_Plaza",
    "Etherwood Background Meadow": "M_Etherwood_Grass",
    "North Forest Edge": "M_Etherwood_ForestEdge",
    "South Forest Edge": "M_Etherwood_ForestEdge",
    "East Forest Edge": "M_Etherwood_ForestEdge",
    "West Forest Edge": "M_Etherwood_ForestEdge",
    "Etherwood Low Hill 1": "M_Etherwood_Hill",
    "Etherwood Low Hill 2": "M_Etherwood_Hill",
    "Etherwood Low Hill 3": "M_Etherwood_Hill",
    "Etherwood Low Hill 4": "M_Etherwood_Hill",
    "Flower Grove": "M_Etherwood_FlowerGrove",
    "Sacred Koi Pond": "M_Etherwood_PondWater",
    "Fairy House": "M_Etherwood_Wood",
    "Potion Shop": "M_Etherwood_Wood",
    "Ancient Tree": "M_Etherwood_Wood",
}


def ensure_folder(path):
    if not unreal.EditorAssetLibrary.does_directory_exist(path):
        unreal.EditorAssetLibrary.make_directory(path)


def create_or_update_material(name, color):
    material_path = f"{MATERIAL_FOLDER}/{name}"
    if unreal.EditorAssetLibrary.does_asset_exist(material_path):
        material = unreal.EditorAssetLibrary.load_asset(material_path)
    else:
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        material = asset_tools.create_asset(name, MATERIAL_FOLDER, unreal.Material, unreal.MaterialFactoryNew())

    material.set_editor_property("use_material_attributes", False)

    unreal.MaterialEditingLibrary.delete_all_material_expressions(material)
    color_node = unreal.MaterialEditingLibrary.create_material_expression(
        material,
        unreal.MaterialExpressionConstant4Vector,
        -380,
        0,
    )
    color_node.set_editor_property("constant", color)

    roughness_node = unreal.MaterialEditingLibrary.create_material_expression(
        material,
        unreal.MaterialExpressionConstant,
        -380,
        180,
    )
    roughness_node.set_editor_property("r", 0.85)

    unreal.MaterialEditingLibrary.connect_material_property(
        color_node,
        "",
        unreal.MaterialProperty.MP_BASE_COLOR,
    )
    unreal.MaterialEditingLibrary.connect_material_property(
        roughness_node,
        "",
        unreal.MaterialProperty.MP_ROUGHNESS,
    )
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(material_path)
    return material


def build_materials():
    ensure_folder(MATERIAL_FOLDER)
    return {
        name: create_or_update_material(name, color)
        for name, color in MATERIAL_COLORS.items()
    }


def apply_material(actor, material):
    changed = False
    mesh_components = actor.get_components_by_class(unreal.StaticMeshComponent)
    for mesh in mesh_components:
        slots = max(mesh.get_num_materials(), 1)
        for slot_index in range(slots):
            mesh.set_material(slot_index, material)
        changed = True
    return changed


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = build_materials()
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    labels_to_actors = {actor.get_actor_label(): actor for actor in actors}

    applied = []
    missing = []
    for label, material_name in ACTOR_MATERIALS.items():
        actor = labels_to_actors.get(label)
        if not actor:
            missing.append(label)
            continue

        if apply_material(actor, materials[material_name]):
            applied.append(label)

    level_subsystem.save_current_level()
    unreal.log("Applied flat Etherwood material pass to: " + ", ".join(applied))
    if missing:
        unreal.log_warning("Material pass skipped missing optional actors: " + ", ".join(missing))


main()
