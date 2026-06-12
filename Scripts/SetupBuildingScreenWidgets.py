import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
UI_PATH = "/Game/Blueprints/UI"

BUILDING_SCREENS = {
    "Flower Grove": {
        "widget": "WBP_FlowerGrove",
        "type": "FLOWER_GROVE",
    },
    "Sacred Koi Pond": {
        "widget": "WBP_SacredPond",
        "type": "SACRED_POND",
    },
    "Fairy House": {
        "widget": "WBP_FairyHouse",
        "type": "FAIRY_HOUSE",
    },
}


def ensure_directory(path):
    if not unreal.EditorAssetLibrary.does_directory_exist(path):
        unreal.EditorAssetLibrary.make_directory(path)


def get_building_screen_parent_class():
    parent = unreal.load_class(None, "/Script/MysticGrove.MysticBuildingScreenWidget")
    if not parent:
        raise RuntimeError("Could not load MysticBuildingScreenWidget parent class.")
    return parent


def create_widget_blueprint(asset_name, parent_class):
    asset_path = f"{UI_PATH}/{asset_name}"
    if unreal.EditorAssetLibrary.does_asset_exist(asset_path):
        return unreal.EditorAssetLibrary.load_asset(asset_path)

    factory = unreal.WidgetBlueprintFactory()
    try:
        factory.set_editor_property("parent_class", parent_class)
    except Exception:
        factory.set_editor_property("ParentClass", parent_class)

    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    widget = asset_tools.create_asset(asset_name, UI_PATH, None, factory)
    if not widget:
        raise RuntimeError(f"Could not create widget blueprint: {asset_path}")
    return widget


def get_widget_class(widget_blueprint):
    class_path = f"{widget_blueprint.get_path_name()}_C"
    widget_class = unreal.EditorAssetLibrary.load_blueprint_class(class_path)
    if not widget_class:
        raise RuntimeError(f"Could not load widget class: {class_path}")
    return widget_class


def enum_value(value_name):
    enum_type = getattr(unreal, "MysticBuildingType", None)
    if not enum_type:
        return None

    for name in dir(enum_type):
        if name.upper() == value_name:
            return getattr(enum_type, name)
    return None


def main():
    ensure_directory(UI_PATH)
    parent_class = get_building_screen_parent_class()

    widgets = {}
    for config in BUILDING_SCREENS.values():
        widget_blueprint = create_widget_blueprint(config["widget"], parent_class)
        unreal.EditorAssetLibrary.save_loaded_asset(widget_blueprint)
        widgets[config["widget"]] = get_widget_class(widget_blueprint)

    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    labels_to_actors = {actor.get_actor_label(): actor for actor in actors}

    assigned = []
    for label, config in BUILDING_SCREENS.items():
        actor = labels_to_actors.get(label)
        if not actor:
            raise RuntimeError(f"Missing placed building actor: {label}")

        actor.set_editor_property("building_name", unreal.Name(label.replace(" ", "")))
        actor.set_editor_property("display_name", unreal.Text(label))
        actor.set_editor_property("screen_widget_class", widgets[config["widget"]])

        building_type = enum_value(config["type"])
        if building_type is not None:
            actor.set_editor_property("building_type", building_type)

        if not actor.get_editor_property("zoom_target"):
            actor.set_editor_property("zoom_target", actor)

        assigned.append(f"{label} -> {config['widget']}")

    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).save_current_level()
    unreal.EditorAssetLibrary.save_directory(UI_PATH, only_if_is_dirty=False, recursive=True)
    unreal.log("Building screen widgets assigned: " + ", ".join(assigned))


main()
