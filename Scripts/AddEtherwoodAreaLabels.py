import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"

LABELS = {
    "Flower Grove Label": {
        "target": "Flower Grove",
        "text": "Flower Grove",
        "color": unreal.Color(255, 150, 210, 255),
    },
    "Sacred Koi Pond Label": {
        "target": "Sacred Koi Pond",
        "text": "Sacred Koi Pond",
        "color": unreal.Color(120, 210, 255, 255),
    },
    "Fairy House Label": {
        "target": "Fairy House",
        "text": "Fairy House",
        "color": unreal.Color(160, 255, 170, 255),
    },
}


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def set_text(component, label_text):
    try:
        component.set_text(unreal.Text(label_text))
    except Exception:
        component.set_editor_property("text", unreal.Text(label_text))


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    for label, config in LABELS.items():
        target = find_actor(config["target"])
        if not target:
            raise RuntimeError(f"Missing label target: {config['target']}")

        actor = find_actor(label)
        if not actor:
            actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
                unreal.TextRenderActor,
                target.get_actor_location() + unreal.Vector(0.0, 0.0, 210.0),
                unreal.Rotator(58.0, 0.0, 0.0),
            )
            actor.set_actor_label(label)

        actor.set_actor_location(target.get_actor_location() + unreal.Vector(0.0, 0.0, 210.0), False, False)
        actor.set_actor_rotation(unreal.Rotator(58.0, 0.0, 0.0), False)
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if component:
            set_text(component, config["text"])
            component.set_editor_property("world_size", 82.0)
            component.set_editor_property("text_render_color", config["color"])
            component.set_editor_property("horizontal_alignment", unreal.HorizTextAligment.EHTA_CENTER)
            component.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)

    level_subsystem.save_current_level()
    unreal.log("Etherwood area labels added for Flower Grove, Sacred Koi Pond, and Fairy House.")


main()
