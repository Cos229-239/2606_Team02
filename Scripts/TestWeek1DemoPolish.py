import unreal


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected!r}, got {actual!r}.")


def assert_contains(text, expected, message):
    if expected not in str(text):
        raise RuntimeError(f"{message} Expected text containing {expected!r}, got {text!r}.")


def assert_property(obj, property_name, message):
    try:
        return obj.get_editor_property(property_name)
    except Exception as exc:
        raise RuntimeError(f"{message}: missing property {property_name}.") from exc


def main():
    try:
        hud_class = unreal.MysticHud
        controller_class = unreal.MysticGrovePlayerController
        screen_class = unreal.MysticBuildingScreenWidget
        start_screen_class = unreal.MysticStartScreenWidget
    except AttributeError as exc:
        raise RuntimeError("Milestone 10 needs Mystic C++ classes exposed to Python.") from exc

    hud_cdo = unreal.get_default_object(hud_class)
    controller_cdo = unreal.get_default_object(controller_class)
    screen_cdo = unreal.get_default_object(screen_class)
    start_screen_cdo = unreal.get_default_object(start_screen_class)

    assert_equal(assert_property(hud_cdo, "show_start_screen", "Start screen state"), True, "Start screen should be visible by default.")
    assert_contains(assert_property(hud_cdo, "demo_feedback_text", "Feedback popup state"), "", "Feedback text should default empty.")
    assert_equal(assert_property(hud_cdo, "demo_feedback_visible", "Feedback popup state"), False, "Feedback popup should default hidden.")
    assert_equal(hud_cdo.get_start_screen_button_action(unreal.Vector2D(640.0, 374.6)), 1, "Play button hitbox should work at its drawn center.")
    assert_equal(hud_cdo.get_start_screen_button_action(unreal.Vector2D(640.0, 450.6)), 2, "Reset Save button hitbox should work at its drawn center.")
    assert_equal(hud_cdo.get_start_screen_button_action(unreal.Vector2D(640.0, 526.6)), 3, "Quit button hitbox should work at its drawn center.")

    for method_name in [
        "get_start_screen_button_action",
        "set_start_screen_visible",
        "show_demo_feedback",
        "clear_demo_feedback",
    ]:
        if not hasattr(hud_cdo, method_name):
            raise RuntimeError(f"Milestone 10 missing HUD method {method_name}.")

    for method_name in [
        "play_from_start_screen",
        "quit_mystic_grove",
        "get_week1_demo_state_summary",
    ]:
        if not hasattr(controller_cdo, method_name):
            raise RuntimeError(f"Milestone 10 missing controller method {method_name}.")

    for property_name in ["on_play_requested", "on_reset_save_requested", "on_quit_requested"]:
        assert_property(start_screen_cdo, property_name, "Real start screen widget")

    assert_contains(controller_cdo.get_week1_demo_state_summary(), "Start Screen", "Demo summary should include start screen readiness.")
    assert_contains(controller_cdo.get_week1_demo_state_summary(), "Feedback Popups", "Demo summary should include feedback readiness.")
    assert_contains(controller_cdo.get_week1_demo_state_summary(), "Save Load", "Demo summary should include save/load readiness.")

    for property_name in [
        "button_click_sound",
        "collect_mana_sound",
        "restore_pond_sound",
        "upgrade_flower_sound",
        "back_button_sound",
    ]:
        if not assert_property(controller_cdo, property_name, "Placeholder sound setup"):
            raise RuntimeError(f"Milestone 10 should assign placeholder sound {property_name}.")

    first = str(assert_property(screen_cdo, "first_action_label", "Building button labels"))
    second = str(assert_property(screen_cdo, "second_action_label", "Building button labels"))
    third = str(assert_property(screen_cdo, "third_action_label", "Building button labels"))
    if first.strip() == "" or second.strip() == "":
        raise RuntimeError("Milestone 10 should not default to blank primary building buttons.")
    assert_equal(third.strip(), "", "Third action can be hidden when a building has only two primary actions.")

    unreal.log("Milestone 10 Week 1 demo polish verification passed")


main()
