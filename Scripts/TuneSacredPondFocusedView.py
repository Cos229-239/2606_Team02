import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    pond = find_actor("Sacred Koi Pond")
    if not pond:
        raise RuntimeError("Missing Sacred Koi Pond actor.")

    focus_target = find_actor("Sacred Pond Focus Target")
    if not focus_target:
        focus_target = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.Actor,
            pond.get_actor_location(),
            unreal.Rotator(0.0, 0.0, 0.0),
        )
        focus_target.set_actor_label("Sacred Pond Focus Target")

    focus_location = pond.get_actor_location() + unreal.Vector(215.0, 430.0, 0.0)
    focus_target.set_actor_location(focus_location, False, False)
    focus_target.set_actor_rotation(unreal.Rotator(0.0, -90.0, 85.0), False)

    pond.set_actor_scale3d(unreal.Vector(4.4, 3.0, 1.0))
    pond.set_editor_property("zoom_offset", unreal.Vector(0.0, -1.0, 620.0))
    pond.set_editor_property("zoom_target", focus_target)

    level_subsystem.save_current_level()
    unreal.log("Sacred Koi Pond focused view tuned for closer camera and larger prototype pond.")


main()
