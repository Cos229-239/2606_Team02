import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
MATERIAL_FOLDER = "/Game/Materials"

MATERIAL_COLORS = {
    "M_Final_ForestGround": unreal.LinearColor(0.01, 0.095, 0.028, 1.0),
    "M_Final_ForestEdge": unreal.LinearColor(0.006, 0.055, 0.018, 1.0),
    "M_Final_DirtPath": unreal.LinearColor(0.20, 0.105, 0.035, 1.0),
    "M_Final_PondWater": unreal.LinearColor(0.0, 0.045, 0.22, 1.0),
    "M_Final_FlowerGroveBase": unreal.LinearColor(0.055, 0.025, 0.13, 1.0),
    "M_Final_CreamStone": unreal.LinearColor(0.34, 0.31, 0.23, 1.0),
    "M_Final_WarmWood": unreal.LinearColor(0.42, 0.24, 0.12, 1.0),
    "M_Final_FairyWallWarm": unreal.LinearColor(0.48, 0.38, 0.25, 1.0),
    "M_Final_MutedGlow": unreal.LinearColor(0.45, 0.34, 0.12, 1.0),
    "M_Final_MutedWhiteFlower": unreal.LinearColor(0.60, 0.56, 0.42, 1.0),
}

ACTOR_MATERIALS = {
    "Etherwood Village Ground": "M_Final_ForestGround",
    "Etherwood Background Meadow": "M_Final_ForestGround",
    "North Forest Edge": "M_Final_ForestEdge",
    "South Forest Edge": "M_Final_ForestEdge",
    "East Forest Edge": "M_Final_ForestEdge",
    "West Forest Edge": "M_Final_ForestEdge",
    "Etherwood Low Hill 1": "M_Final_ForestEdge",
    "Etherwood Low Hill 2": "M_Final_ForestEdge",
    "Etherwood Low Hill 3": "M_Final_ForestEdge",
    "Etherwood Low Hill 4": "M_Final_ForestEdge",
    "Etherwood Dirt Path Fairy To Flower": "M_Final_DirtPath",
    "Etherwood Dirt Path Fairy To Pond": "M_Final_DirtPath",
    "Etherwood Dirt Path Flower To Pond": "M_Final_DirtPath",
    "Sacred Koi Pond": "M_Final_PondWater",
    "Flower Grove": "M_Final_FlowerGroveBase",
    "Fairy House": "M_Final_FairyWallWarm",
}

PREFIX_MATERIALS = {
    "Fairy House Path Stone ": "M_Final_CreamStone",
    "Fairy Cottage Porch": "M_Final_WarmWood",
    "Flower Grove Path Stone ": "M_Final_DirtPath",
    "Flower Grove Plot ": "M_Final_DirtPath",
    "Sacred Pond Stone ": "M_Final_CreamStone",
    "Sacred Pond Waterfall ": "M_Final_PondWater",
    "Sacred Pond Lantern Glow ": "M_Final_MutedGlow",
    "Fairy House Light Orb ": "M_Final_MutedGlow",
    "Flower Grove Lantern Glow ": "M_Final_MutedGlow",
    "Flower Grove Mana Flower Glow ": "M_Final_MutedGlow",
    "Flower Grove Wildflower Edge ": "M_Final_MutedWhiteFlower",
}

LIGHT_SETTINGS = {
    "Etherwood Sun Light": (0.13, unreal.Color(255, 186, 126, 255)),
    "Etherwood Directional Light": (0.10, unreal.Color(255, 186, 126, 255)),
    "Etherwood Sky Light": (0.045, unreal.Color(105, 118, 126, 255)),
    "Etherwood Fill Light": (28.0, unreal.Color(255, 174, 112, 255)),
    "Etherwood Soft Fill Light": (20.0, unreal.Color(255, 174, 112, 255)),
}

LIGHT_PREFIX_SETTINGS = {
    "Fairy House Light ": (18.0, 110.0, unreal.Color(255, 190, 110, 255)),
    "Flower Grove Lantern Light ": (16.0, 95.0, unreal.Color(255, 190, 110, 255)),
    "Flower Grove Mana Flower Light ": (20.0, 105.0, unreal.Color(110, 210, 185, 255)),
    "Sacred Pond Lantern Light ": (18.0, 105.0, unreal.Color(255, 188, 105, 255)),
}


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
    try:
        material.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    except Exception:
        pass
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
    roughness_node.set_editor_property("r", 0.95)

    unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_BASE_COLOR)
    try:
        unreal.MaterialEditingLibrary.connect_material_property(color_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    except Exception:
        pass
    unreal.MaterialEditingLibrary.connect_material_property(roughness_node, "", unreal.MaterialProperty.MP_ROUGHNESS)
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(path)
    return material


def apply_material(actor, material):
    if not actor:
        return False

    changed = False
    for mesh in actor.get_components_by_class(unreal.StaticMeshComponent):
        slots = max(mesh.get_num_materials(), 1)
        for slot_index in range(slots):
            mesh.set_material(slot_index, material)
        changed = True
    return changed


def tune_light(actor, intensity, color=None, radius=None):
    if not actor:
        return False

    component = actor.get_component_by_class(unreal.LightComponent)
    if not component:
        return False

    component.set_editor_property("intensity", intensity)
    if color:
        component.set_editor_property("light_color", color)
    point_component = actor.get_component_by_class(unreal.PointLightComponent)
    if point_component and radius is not None:
        point_component.set_editor_property("attenuation_radius", radius)
    return True


def tune_fog(actor):
    if not actor:
        return False

    component = actor.get_component_by_class(unreal.ExponentialHeightFogComponent)
    if not component:
        return False

    component.set_editor_property("fog_density", 0.0005)
    component.set_editor_property("fog_height_falloff", 0.10)

    # UE property names move around a bit, so only set the tint fields that exist.
    for property_name, color in [
        ("fog_inscattering_color", unreal.LinearColor(0.05, 0.075, 0.065, 1.0)),
        ("fog_in_scattering_color", unreal.LinearColor(0.05, 0.075, 0.065, 1.0)),
        ("directional_inscattering_color", unreal.LinearColor(0.42, 0.32, 0.22, 1.0)),
        ("directional_in_scattering_color", unreal.LinearColor(0.42, 0.32, 0.22, 1.0)),
    ]:
        try:
            component.set_editor_property(property_name, color)
        except Exception:
            pass
    return True


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    materials = {name: ensure_material(name, color) for name, color in MATERIAL_COLORS.items()}
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    label_to_actor = {actor.get_actor_label(): actor for actor in actors}

    changed_materials = []
    for label, material_name in ACTOR_MATERIALS.items():
        if apply_material(label_to_actor.get(label), materials[material_name]):
            changed_materials.append(label)

    for actor in actors:
        label = actor.get_actor_label()
        for prefix, material_name in PREFIX_MATERIALS.items():
            if label.startswith(prefix):
                if apply_material(actor, materials[material_name]):
                    changed_materials.append(label)
                break

    changed_lights = []
    for label, (intensity, color) in LIGHT_SETTINGS.items():
        if tune_light(label_to_actor.get(label), intensity, color):
            changed_lights.append(label)

    for actor in actors:
        label = actor.get_actor_label()
        for prefix, (intensity, radius, color) in LIGHT_PREFIX_SETTINGS.items():
            if label.startswith(prefix):
                if tune_light(actor, intensity, color, radius):
                    changed_lights.append(label)
                break

    tuned_fog = tune_fog(label_to_actor.get("Etherwood Soft World Fog"))

    level_subsystem.save_current_level()
    unreal.log("Reduced village washout materials: " + ", ".join(changed_materials))
    unreal.log("Reduced village washout lights: " + ", ".join(changed_lights))
    unreal.log("Reduced village washout fog: " + str(tuned_fog))


main()
