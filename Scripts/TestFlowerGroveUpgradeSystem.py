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


def call_upgrade(flower, mana):
    upgraded = flower.upgrade_flower_grove_with_mana(mana)
    remaining = flower.get_editor_property("last_upgrade_remaining_mana")
    message = str(flower.get_editor_property("last_upgrade_message"))
    return upgraded, remaining, message


def main():
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)

    flower = find_actor("Flower Grove")
    fairy_house = find_actor("Fairy House")
    if not flower:
        raise RuntimeError("Missing Flower Grove actor.")
    if not fairy_house:
        raise RuntimeError("Missing Fairy House actor.")

    required_flower_properties = [
        "flower_grove_level",
        "upgrade_cost",
        "base_mana_production_rate",
        "max_stored_mana",
        "stored_mana",
        "fairy_bonus_mana_production",
        "last_upgrade_remaining_mana",
        "last_upgrade_message",
    ]
    for property_name in required_flower_properties:
        try:
            flower.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 7 missing property {property_name}.") from exc

    flower.set_editor_property("stored_mana", 0.0)
    flower.set_editor_property("flower_grove_level", 1)
    flower.set_editor_property("upgrade_cost", 50)
    flower.set_editor_property("base_mana_production_rate", 5.0)
    flower.set_editor_property("mana_production_rate", 5.0)
    flower.set_editor_property("max_stored_mana", 100)

    fairy_house.set_editor_property("fairy_name", "Luna")
    fairy_house.set_editor_property("fairy_level", 1)
    fairy_house.set_editor_property("fairy_assigned_task", "Flower Grove")
    fairy_house.set_editor_property("fairy_work_bonus", 3.0)
    fairy_house.set_editor_property("fairy_is_assigned", True)
    flower.update_fairy_worker_bonus_from_house(fairy_house)

    upgraded, remaining_mana, message = call_upgrade(flower, 20)
    assert_equal(upgraded, False, "Upgrade should fail without enough mana.")
    assert_equal(remaining_mana, 20, "Failed upgrade should leave mana unchanged.")
    assert_equal(flower.get_editor_property("flower_grove_level"), 1, "Failed upgrade should leave level unchanged.")
    assert_close(flower.get_editor_property("base_mana_production_rate"), 5.0, "Failed upgrade should leave base production unchanged.")
    if "Not enough mana" not in message:
        raise RuntimeError(f"Expected not enough mana message, got: {message}")

    upgraded, remaining_mana, message = call_upgrade(flower, 100)
    assert_equal(upgraded, True, "Upgrade should succeed with enough mana.")
    assert_equal(remaining_mana, 50, "Upgrade should subtract the current 50 mana cost.")
    assert_equal(flower.get_editor_property("flower_grove_level"), 2, "Upgrade should increase Flower Grove level.")
    assert_close(flower.get_editor_property("base_mana_production_rate"), 7.0, "Upgrade should increase base production by 2.")
    assert_close(flower.get_editor_property("mana_production_rate"), 7.0, "Legacy production rate should stay in sync.")
    assert_equal(flower.get_editor_property("max_stored_mana"), 125, "Upgrade should increase max stored mana by 25.")
    assert_equal(flower.get_editor_property("upgrade_cost"), 100, "Upgrade cost should increase by 50.")
    assert_close(flower.get_total_mana_production_rate(), 10.0, "Total production should include upgraded base plus Luna bonus.")

    flower.set_editor_property("stored_mana", 0.0)
    flower.generate_mana_for_seconds(10.0)
    assert_close(flower.get_editor_property("stored_mana"), 100.0, "Stored mana should use the upgraded 10/sec total rate.")

    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)
    save_game.set_editor_property("flower_grove_level", flower.get_editor_property("flower_grove_level"))
    save_game.set_editor_property("flower_grove_upgrade_cost", flower.get_editor_property("upgrade_cost"))
    save_game.set_editor_property("flower_grove_base_mana_production_rate", flower.get_editor_property("base_mana_production_rate"))
    save_game.set_editor_property("flower_grove_max_stored_mana", flower.get_editor_property("max_stored_mana"))
    save_game.set_editor_property("flower_grove_stored_mana", flower.get_editor_property("stored_mana"))

    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("Could not save Flower Grove upgrade test data.")

    loaded = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded:
        raise RuntimeError("Could not load Flower Grove upgrade test data.")

    assert_equal(loaded.get_editor_property("flower_grove_level"), 2, "Saved Flower Grove level should load correctly.")
    assert_equal(loaded.get_editor_property("flower_grove_upgrade_cost"), 100, "Saved upgrade cost should load correctly.")
    assert_close(loaded.get_editor_property("flower_grove_base_mana_production_rate"), 7.0, "Saved base production should load correctly.")
    assert_equal(loaded.get_editor_property("flower_grove_max_stored_mana"), 125, "Saved max stored mana should load correctly.")
    assert_close(loaded.get_editor_property("flower_grove_stored_mana"), 100.0, "Saved stored mana should load correctly.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Milestone 7 Flower Grove upgrade verification passed")


main()
