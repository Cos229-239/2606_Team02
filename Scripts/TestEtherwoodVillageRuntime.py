import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
REQUIRED_LABELS = {
    "Etherwood Village Ground",
    "Flower Grove",
    "Sacred Koi Pond",
    "Sacred Pond Focus Target",
    "Sacred Pond Stone 01",
    "Sacred Pond Lily 01",
    "Sacred Pond Koi 01",
    "Sacred Pond Lantern Post 01",
    "Sacred Pond Lantern Glow 01",
    "Sacred Pond Waterfall Stream",
    "Fairy House",
    "Fairy Cottage Purple Roof",
    "Fairy Cottage Window Front Left",
    "Fairy Cottage Porch",
    "Fairy House Path Stone 1",
    "Fairy House Fence Post 01",
    "Fairy House Mushroom Stem 01",
    "Fairy House Light Orb 01",
    "Flower Grove Label",
    "Sacred Koi Pond Label",
    "Fairy House Label",
    "BP_CameraManager_VillageOverview",
    "BP_EconomyManager",
    "BP_FairyManager",
    "Etherwood Sun Light",
    "Etherwood Sky Light",
    "Etherwood Soft Fill Light",
    "Etherwood Background Meadow",
    "North Forest Edge",
    "South Forest Edge",
    "East Forest Edge",
    "West Forest Edge",
    "Etherwood Low Hill 1",
    "Etherwood Low Hill 2",
    "Etherwood Low Hill 3",
    "Etherwood Low Hill 4",
    "Etherwood Sky Atmosphere",
    "Etherwood Soft World Fog",
    "Etherwood Sky Light",
    "Etherwood Fill Light",
    "PlayerStart",
}

EXPECTED_WIDGETS = {
    "Flower Grove": {
        "widget": "/Game/Blueprints/UI/WBP_FlowerGrove",
        "name": "FlowerGrove",
        "type": "FLOWER",
    },
    "Sacred Koi Pond": {
        "widget": "/Game/Blueprints/UI/WBP_SacredPond",
        "name": "SacredKoiPond",
        "type": "SACRED",
    },
    "Fairy House": {
        "widget": "/Game/Blueprints/UI/WBP_FairyHouse",
        "name": "FairyHouse",
        "type": "FAIRY",
    },
}


def main():
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    labels = {actor.get_actor_label() for actor in actors}
    missing = sorted(REQUIRED_LABELS - labels)
    if missing:
        raise RuntimeError("Missing Etherwood Village actors: " + ", ".join(missing))

    labels_to_actors = {actor.get_actor_label(): actor for actor in actors}
    for label, config in EXPECTED_WIDGETS.items():
        actor = labels_to_actors.get(label)
        building_name = str(actor.get_editor_property("building_name"))
        if config["name"] not in building_name:
            raise RuntimeError(f"{label} has wrong BuildingName: {building_name}")

        building_type = str(actor.get_editor_property("building_type")).upper()
        if config["type"] not in building_type:
            raise RuntimeError(f"{label} has wrong BuildingType: {building_type}")

        zoom_target = actor.get_editor_property("zoom_target")
        if not zoom_target:
            raise RuntimeError(f"{label} is missing ZoomTarget.")

        widget_class = actor.get_editor_property("screen_widget_class")
        if not widget_class:
            raise RuntimeError(f"{label} is missing ScreenWidgetClass.")

        class_path = widget_class.get_path_name()
        widget_path = config["widget"]
        if widget_path not in class_path:
            raise RuntimeError(f"{label} uses wrong widget class: {class_path}")

        widget_asset = unreal.EditorAssetLibrary.load_asset(widget_path)
        if not widget_asset:
            raise RuntimeError(f"Missing widget asset: {widget_path}")

    unreal.log("Etherwood Village runtime layout check passed.")


main()
