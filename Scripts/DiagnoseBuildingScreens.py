import unreal
from pathlib import Path

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
BUILDINGS = ["Flower Grove", "Sacred Koi Pond", "Fairy House"]
REPORT_PATH = Path(r"C:\Users\whitt\Documents\Unreal Projects\MysticGrove\Saved\BuildingScreenDiagnostics.txt")


def main():
    lines = []
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    labels_to_actors = {actor.get_actor_label(): actor for actor in actors}

    camera = labels_to_actors.get("BP_CameraManager_VillageOverview")
    if camera:
        lines.append(f"DIAG Camera: class={camera.get_class().get_path_name()}")

    for label in BUILDINGS:
        actor = labels_to_actors.get(label)
        if not actor:
            unreal.log_error(f"DIAG {label}: missing actor")
            continue

        actor_class = actor.get_class().get_path_name()
        widget_class = actor.get_editor_property("screen_widget_class")
        widget_class_path = widget_class.get_path_name() if widget_class else "None"
        building_name = actor.get_editor_property("building_name")
        building_type = actor.get_editor_property("building_type")
        zoom_target = actor.get_editor_property("zoom_target")
        zoom_target_label = zoom_target.get_actor_label() if zoom_target else "None"

        lines.append(f"DIAG {label}: class={actor_class}")
        lines.append(f"DIAG {label}: building_name={building_name} building_type={building_type}")
        lines.append(f"DIAG {label}: zoom_target={zoom_target_label}")
        lines.append(f"DIAG {label}: screen_widget_class={widget_class_path}")

    for widget_path in [
        "/Game/Blueprints/UI/WBP_FlowerGrove",
        "/Game/Blueprints/UI/WBP_SacredPond",
        "/Game/Blueprints/UI/WBP_FairyHouse",
    ]:
        asset = unreal.EditorAssetLibrary.load_asset(widget_path)
        widget_class = unreal.EditorAssetLibrary.load_blueprint_class(f"{widget_path}.{widget_path.rsplit('/', 1)[-1]}_C")
        parent_class = widget_class.get_super_class().get_path_name() if widget_class else "None"
        lines.append(f"DIAG widget {widget_path}: asset={bool(asset)} class={widget_class.get_path_name() if widget_class else 'None'} parent={parent_class}")

    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")
    unreal.log(f"Wrote building screen diagnostics to {REPORT_PATH}")


main()
