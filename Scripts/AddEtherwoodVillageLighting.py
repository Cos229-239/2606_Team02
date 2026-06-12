import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def spawn_or_get(label, actor_class, location, rotation):
    actor = find_actor(label)
    if actor:
        return actor

    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(actor_class, location, rotation)
    actor.set_actor_label(label)
    return actor


def set_if_available(component, property_name, value):
    if not component:
        return
    try:
        component.set_editor_property(property_name, value)
    except Exception:
        unreal.log_warning(f"Skipping unsupported light property: {property_name}")


def tune_wide_fill_light(actor, intensity):
    fill_component = actor.get_component_by_class(unreal.PointLightComponent)
    if not fill_component:
        return

    set_if_available(fill_component, "intensity", intensity)
    set_if_available(fill_component, "attenuation_radius", 6500.0)
    set_if_available(fill_component, "light_color", unreal.Color(210, 235, 205, 255))
    set_if_available(fill_component, "cast_shadows", False)
    set_if_available(fill_component, "use_inverse_squared_falloff", False)
    set_if_available(fill_component, "light_falloff_exponent", 0.35)


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    old_directional = find_actor("Etherwood Directional Light")
    if old_directional:
        unreal.get_editor_subsystem(unreal.EditorActorSubsystem).destroy_actor(old_directional)

    sun = spawn_or_get(
        "Etherwood Sun Light",
        unreal.DirectionalLight,
        unreal.Vector(-420.0, -540.0, 760.0),
        unreal.Rotator(-48.0, 34.0, 0.0),
    )
    sun_component = sun.get_component_by_class(unreal.DirectionalLightComponent)
    if sun_component:
        sun_component.set_editor_property("intensity", 2.2)
        sun_component.set_editor_property("light_color", unreal.Color(255, 238, 205, 255))
        sun_component.set_editor_property("cast_shadows", True)
        sun_component.set_editor_property("forward_shading_priority", 1)

    skylight = spawn_or_get(
        "Etherwood Sky Light",
        unreal.SkyLight,
        unreal.Vector(0.0, 0.0, 420.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    sky_component = skylight.get_component_by_class(unreal.SkyLightComponent)
    if sky_component:
        sky_component.set_editor_property("intensity", 1.45)
        sky_component.set_editor_property("lower_hemisphere_color", unreal.LinearColor(0.10, 0.16, 0.12, 1.0))

    fill = spawn_or_get(
        "Etherwood Soft Fill Light",
        unreal.PointLight,
        unreal.Vector(0.0, -180.0, 520.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    tune_wide_fill_light(fill, 120.0)

    old_fill = spawn_or_get(
        "Etherwood Fill Light",
        unreal.PointLight,
        unreal.Vector(0.0, -240.0, 520.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    tune_wide_fill_light(old_fill, 80.0)

    level_subsystem.save_current_level()
    unreal.log("Etherwood Village world lighting updated without changing camera transforms.")


main()
