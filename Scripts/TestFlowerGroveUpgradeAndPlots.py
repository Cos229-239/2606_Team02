import unreal


MAP_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected!r}, got {actual!r}.")


def assert_close(actual, expected, message, tolerance=0.01):
    if abs(float(actual) - float(expected)) > tolerance:
        raise RuntimeError(f"{message} Expected {expected!r}, got {actual!r}.")


def assert_contains(text, expected, message):
    if expected not in str(text):
        raise RuntimeError(f"{message} Expected text containing {expected!r}, got {text!r}.")


def find_flower_grove():
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in subsystem.get_all_level_actors():
        if actor.get_actor_label() == "Flower Grove":
            return actor
    raise RuntimeError("Could not find Flower Grove actor in map.")


def find_actor(label):
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in subsystem.get_all_level_actors():
        if actor.get_actor_label() == label:
            return actor
    return None


def get_prop(obj, prop):
    try:
        return obj.get_editor_property(prop)
    except Exception as exc:
        raise RuntimeError(f"Missing property {prop}.") from exc


def main():
    unreal.EditorLoadingAndSavingUtils.load_map(MAP_PATH)
    flower_grove = find_flower_grove()

    expected_properties = [
        "flower_grove_level",
        "stored_mana",
        "max_stored_mana",
        "base_mana_production_rate",
        "fairy_bonus_mana_production",
        "upgrade_cost",
        "active_plots",
        "max_plots",
        "last_plot_unlock_message",
    ]
    for prop in expected_properties:
        get_prop(flower_grove, prop)

    assert_equal(get_prop(flower_grove, "flower_grove_level"), 1, "Flower Grove should start at level 1.")
    assert_close(get_prop(flower_grove, "stored_mana"), 0.0, "Stored mana should start at 0.")
    assert_equal(get_prop(flower_grove, "max_stored_mana"), 100, "Max stored mana should start at 100.")
    assert_close(get_prop(flower_grove, "base_mana_production_rate"), 5.0, "Base production should start at 5.")
    assert_equal(get_prop(flower_grove, "upgrade_cost"), 25, "Upgrade cost should start at 25 mana.")
    assert_equal(get_prop(flower_grove, "active_plots"), 3, "Flower Grove should start with 3 active plots.")
    assert_equal(get_prop(flower_grove, "max_plots"), 5, "Flower Grove should support 5 plots.")
    assert_close(flower_grove.get_total_mana_production_rate(), 5.0 + get_prop(flower_grove, "fairy_bonus_mana_production"), "Total production should equal base plus fairy bonus.")

    assert_equal(flower_grove.upgrade_flower_grove_with_mana(24), False, "Upgrade should fail without enough mana.")
    assert_contains(get_prop(flower_grove, "last_upgrade_message"), "Not enough mana", "Missing not enough mana upgrade feedback.")

    assert_equal(flower_grove.upgrade_flower_grove_with_mana(25), True, "Upgrade should succeed at exact cost.")
    assert_equal(get_prop(flower_grove, "last_upgrade_remaining_mana"), 0, "Upgrade should spend the current cost.")
    assert_equal(get_prop(flower_grove, "flower_grove_level"), 2, "Upgrade should increase level.")
    assert_close(get_prop(flower_grove, "base_mana_production_rate"), 7.0, "Upgrade should add +2 base production.")
    assert_equal(get_prop(flower_grove, "max_stored_mana"), 125, "Max storage should increase by 25 on every second level.")
    assert_equal(get_prop(flower_grove, "upgrade_cost"), 38, "Upgrade cost should scale by 1.5x rounded up.")
    assert_contains(get_prop(flower_grove, "last_upgrade_message"), "Flower Grove upgraded", "Upgrade feedback is wrong.")

    assert_equal(flower_grove.get_next_plot_unlock_cost(), 50, "First locked plot should cost 50 mana.")
    assert_equal(flower_grove.unlock_next_flower_plot_with_mana(49), False, "Plot unlock should fail without enough mana.")
    assert_contains(get_prop(flower_grove, "last_plot_unlock_message"), "Not enough mana", "Missing not enough mana plot feedback.")

    assert_equal(flower_grove.unlock_next_flower_plot_with_mana(50), True, "First plot unlock should succeed at 50 mana.")
    assert_equal(get_prop(flower_grove, "active_plots"), 4, "First unlock should activate plot 4.")
    assert_close(get_prop(flower_grove, "base_mana_production_rate"), 9.0, "Plot unlock should add +2 base production.")
    assert_equal(get_prop(flower_grove, "last_plot_unlock_remaining_mana"), 0, "Plot unlock should spend mana.")
    assert_contains(get_prop(flower_grove, "last_plot_unlock_message"), "New flower plot unlocked", "Plot unlock feedback is wrong.")
    assert_equal(flower_grove.get_next_plot_unlock_cost(), 100, "Second locked plot should cost 100 mana.")

    assert_equal(flower_grove.unlock_next_flower_plot_with_mana(100), True, "Second plot unlock should succeed.")
    assert_equal(get_prop(flower_grove, "active_plots"), 5, "Second unlock should activate plot 5.")
    assert_equal(flower_grove.get_next_plot_unlock_cost(), 0, "No unlock cost should remain after all plots unlock.")
    assert_equal(flower_grove.unlock_next_flower_plot_with_mana(999), False, "Unlock should fail when all plots are active.")
    assert_contains(get_prop(flower_grove, "last_plot_unlock_message"), "All plots unlocked", "All-plots feedback is wrong.")

    for label in ["Flower Grove Locked Plot 04", "Flower Grove Locked Plot 05", "Flower Grove Level Up Pulse"]:
        if not find_actor(label):
            raise RuntimeError(f"Missing Flower Grove visual feedback actor: {label}")

    unreal.log("Flower Grove upgrade and plot unlock verification passed")


main()
