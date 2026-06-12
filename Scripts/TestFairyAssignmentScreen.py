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

    flower = find_actor("Flower Grove")
    pond = find_actor("Sacred Koi Pond")
    fairy_house = find_actor("Fairy House")
    if not flower or not pond or not fairy_house:
        raise RuntimeError("Missing one of Flower Grove, Sacred Koi Pond, or Fairy House actors.")

    for property_name in [
        "fairy_name",
        "fairy_level",
        "fairy_assigned_task",
        "fairy_work_bonus",
        "fairy_is_assigned",
        "fairy_workers_active",
    ]:
        try:
            fairy_house.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 8 missing fairy property {property_name}.") from exc

    for property_name in ["fairy_bonus_mana_production"]:
        try:
            flower.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 8 missing flower property {property_name}.") from exc

    for property_name in ["base_restore_purity_amount", "fairy_restore_purity_bonus"]:
        try:
            pond.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 8 missing pond property {property_name}.") from exc

    fairy_house.set_editor_property("fairy_name", "Luna")
    fairy_house.set_editor_property("fairy_level", 1)
    fairy_house.set_editor_property("fairy_work_bonus", 3.0)

    fairy_house.assign_luna_to_task("Flower Grove")
    flower.update_fairy_worker_bonus_from_house(fairy_house)
    pond.update_sacred_pond_fairy_bonus_from_house(fairy_house)
    assert_equal(fairy_house.get_editor_property("fairy_workers_active"), 1, "Flower Grove assignment should count Luna as active.")
    assert_equal(str(fairy_house.get_editor_property("fairy_assigned_task")), "Flower Grove", "Luna should be assigned to Flower Grove.")
    assert_close(flower.get_editor_property("fairy_bonus_mana_production"), 3.0, "Flower Grove should receive Luna's +3 bonus.")
    assert_close(flower.get_total_mana_production_rate(), flower.get_editor_property("base_mana_production_rate") + 3.0, "Flower total production should include Luna.")
    assert_equal(pond.get_editor_property("fairy_restore_purity_bonus"), 0, "Sacred Pond should not get a bonus when Luna is at Flower Grove.")

    fairy_house.assign_luna_to_task("Sacred Koi Pond")
    flower.update_fairy_worker_bonus_from_house(fairy_house)
    pond.update_sacred_pond_fairy_bonus_from_house(fairy_house)
    assert_equal(fairy_house.get_editor_property("fairy_workers_active"), 1, "Sacred Pond assignment should count Luna as active.")
    assert_equal(str(fairy_house.get_editor_property("fairy_assigned_task")), "Sacred Koi Pond", "Luna should be assigned to Sacred Koi Pond.")
    assert_close(flower.get_editor_property("fairy_bonus_mana_production"), 0.0, "Flower Grove should lose Luna's bonus when assigned to pond.")
    assert_equal(pond.get_editor_property("fairy_restore_purity_bonus"), 2, "Sacred Pond should get +2 purity restore bonus from Luna.")

    pond.set_editor_property("sacred_pond_water_purity", 15)
    pond.set_editor_property("spirit_energy", 0)
    pond.set_editor_property("restore_cost", 25)
    restored = pond.restore_sacred_pond_with_mana(25)
    assert_equal(restored, True, "Restore should succeed with enough mana.")
    assert_equal(pond.get_editor_property("sacred_pond_water_purity"), 22, "Sacred Pond restore should give +7 purity when Luna is assigned.")
    assert_equal(pond.get_editor_property("spirit_energy"), 10, "Spirit energy should still increase by 10.")

    fairy_house.assign_luna_to_task("Unassigned")
    flower.update_fairy_worker_bonus_from_house(fairy_house)
    pond.update_sacred_pond_fairy_bonus_from_house(fairy_house)
    assert_equal(fairy_house.get_editor_property("fairy_workers_active"), 0, "Unassigned Luna should make active workers 0.")
    assert_equal(fairy_house.get_editor_property("fairy_is_assigned"), False, "Unassigned Luna should mark IsAssigned false.")
    assert_equal(str(fairy_house.get_editor_property("fairy_assigned_task")), "Unassigned", "Luna should be unassigned.")
    assert_close(flower.get_editor_property("fairy_bonus_mana_production"), 0.0, "Unassigned Luna should not boost Flower Grove.")
    assert_equal(pond.get_editor_property("fairy_restore_purity_bonus"), 0, "Unassigned Luna should not boost Sacred Pond.")

    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)
    save_game.set_editor_property("fairy_name", fairy_house.get_editor_property("fairy_name"))
    save_game.set_editor_property("fairy_level", fairy_house.get_editor_property("fairy_level"))
    save_game.set_editor_property("fairy_assigned_task", fairy_house.get_editor_property("fairy_assigned_task"))
    save_game.set_editor_property("fairy_work_bonus", fairy_house.get_editor_property("fairy_work_bonus"))
    save_game.set_editor_property("fairy_is_assigned", fairy_house.get_editor_property("fairy_is_assigned"))
    save_game.set_editor_property("fairy_workers_active", fairy_house.get_editor_property("fairy_workers_active"))

    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("Could not save fairy assignment test data.")

    loaded = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded:
        raise RuntimeError("Could not load fairy assignment test data.")

    assert_equal(str(loaded.get_editor_property("fairy_assigned_task")), "Unassigned", "Saved Luna assignment should load correctly.")
    assert_equal(loaded.get_editor_property("fairy_is_assigned"), False, "Saved Luna IsAssigned should load correctly.")
    assert_equal(loaded.get_editor_property("fairy_workers_active"), 0, "Saved active worker count should load correctly.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Milestone 8 fairy assignment verification passed")


main()
