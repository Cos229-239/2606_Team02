import unreal

SAVE_FOLDER = "/Game/Saves"
SAVE_BLUEPRINT_PATH = f"{SAVE_FOLDER}/SaveGame_MysticGrove"


def main():
    if not unreal.EditorAssetLibrary.does_directory_exist(SAVE_FOLDER):
        unreal.EditorAssetLibrary.make_directory(SAVE_FOLDER)

    if unreal.EditorAssetLibrary.does_asset_exist(SAVE_BLUEPRINT_PATH):
        unreal.log("SaveGame_MysticGrove already exists.")
        return

    parent_class = unreal.MysticGroveSaveGame.static_class()
    factory = unreal.BlueprintFactory()
    factory.set_editor_property("parent_class", parent_class)

    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    blueprint = asset_tools.create_asset("SaveGame_MysticGrove", SAVE_FOLDER, None, factory)
    if not blueprint:
        raise RuntimeError("Could not create SaveGame_MysticGrove Blueprint.")

    unreal.EditorAssetLibrary.save_asset(SAVE_BLUEPRINT_PATH)
    unreal.log("SaveGame_MysticGrove Blueprint created.")


main()
