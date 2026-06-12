import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"

KEEP_LABELS = {
    "Fairy House Label",
    "Sacred Koi Pond Label",
    "Flower Grove Label",
    "Flower Grove Bloom Label 01",
    "Flower Grove Bloom Label 02",
    "Flower Grove Bloom Label 03",
}


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in list(actor_subsystem.get_all_level_actors()):
        label = actor.get_actor_label()
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if not component:
            continue

        if label.endswith(" Shadow") or label.endswith(" Backing"):
            actor_subsystem.destroy_actor(actor)
            continue

        if label.startswith("Flower Grove Bloom Label ") and label not in KEEP_LABELS:
            actor_subsystem.destroy_actor(actor)
            continue

        if label in KEEP_LABELS:
            actor.set_actor_hidden_in_game(True)
            actor.set_is_temporarily_hidden_in_editor(True)
            component.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)

    level_subsystem.save_current_level()
    unreal.log("World TextRender labels hidden so HUD labels can handle readability.")


main()
