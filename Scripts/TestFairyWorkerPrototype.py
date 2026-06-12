import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
SAVE_BLUEPRINT_PATH = "/Game/Saves/SaveGame_MysticGrove"
SAVE_SLOT = "MysticGrove_SaveSlot"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def get_generated_class(blueprint_path):
    blueprint = unreal.EditorAssetLibrary.load_asset(blueprint_path)
    if not blueprint:
        raise RuntimeError(f"Missing Blueprint asset: {blueprint_path}")
    generated_class = blueprint.generated_class()
    if not generated_class:
        raise RuntimeError(f"Blueprint has no generated class: {blueprint_path}")
    return generated_class


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def assert_close(actual, expected, message):
    if abs(float(actual) - float(expected)) > 0.01:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def main():
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)

    flower_grove = find_actor("Flower Grove")
    fairy_house = find_actor("Fairy House")
    if not flower_grove:
        raise RuntimeError("Missing Flower Grove actor.")
    if not fairy_house:
        raise RuntimeError("Missing Fairy House actor.")

    required_actor_properties = [
        "fairy_name",
        "fairy_level",
        "fairy_assigned_task",
        "fairy_work_bonus",
        "fairy_is_assigned",
        "fairy_bonus_mana_production",
    ]
    for property_name in required_actor_properties:
        try:
            if property_name.startswith("fairy_bonus"):
                flower_grove.get_editor_property(property_name)
            else:
                fairy_house.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 5 missing property {property_name}.") from exc

    fairy_house.set_editor_property("fairy_name", "Luna")
    fairy_house.set_editor_property("fairy_level", 1)
    fairy_house.set_editor_property("fairy_assigned_task", "Flower Grove")
    fairy_house.set_editor_property("fairy_work_bonus", 3.0)
    fairy_house.set_editor_property("fairy_is_assigned", True)
    fairy_house.set_editor_property("fairy_workers_active", 1)

    flower_grove.set_editor_property("stored_mana", 0.0)
    flower_grove.set_editor_property("mana_production_rate", 5.0)
    flower_grove.update_fairy_worker_bonus_from_house(fairy_house)

    assert_equal(fairy_house.get_editor_property("fairy_name"), "Luna", "Starting fairy name is wrong.")
    assert_equal(fairy_house.get_editor_property("fairy_level"), 1, "Starting fairy level is wrong.")
    assert_equal(fairy_house.get_editor_property("fairy_assigned_task"), "Flower Grove", "Starting fairy task is wrong.")
    assert_close(fairy_house.get_editor_property("fairy_work_bonus"), 3.0, "Starting fairy bonus is wrong.")
    assert_equal(fairy_house.get_editor_property("fairy_is_assigned"), True, "Starting fairy assigned flag is wrong.")
    assert_close(flower_grove.get_total_mana_production_rate(), 8.0, "Flower Grove total production should include Luna bonus.")

    flower_grove.generate_mana_for_seconds(10.0)
    assert_close(flower_grove.get_editor_property("stored_mana"), 80.0, "Flower Grove should generate 80 mana in 10 seconds with Luna assigned.")

    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)
    save_game.set_editor_property("fairy_name", "Luna")
    save_game.set_editor_property("fairy_level", 1)
    save_game.set_editor_property("fairy_assigned_task", "Flower Grove")
    save_game.set_editor_property("fairy_work_bonus", 3.0)
    save_game.set_editor_property("fairy_is_assigned", True)
    save_game.set_editor_property("fairy_workers_active", 1)

    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("Could not save fairy worker data.")
    loaded_game = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded_game:
        raise RuntimeError("Could not load fairy worker data.")

    assert_equal(loaded_game.get_editor_property("fairy_name"), "Luna", "Saved fairy name did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_level"), 1, "Saved fairy level did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_assigned_task"), "Flower Grove", "Saved fairy task did not load.")
    assert_close(loaded_game.get_editor_property("fairy_work_bonus"), 3.0, "Saved fairy bonus did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_is_assigned"), True, "Saved fairy assigned flag did not load.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Milestone 5 fairy worker verification passed.")


main()
