import math
import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def load_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if not asset:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def spawn_static(label, location, rotation, scale, material):
    actor = find_actor(label)
    if not actor:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.StaticMeshActor, location, rotation)
        actor.set_actor_label(label)

    cube = load_asset("/Engine/BasicShapes/Cube.Cube")
    actor.set_actor_location(location, False, False)
    actor.set_actor_rotation(rotation, False)
    actor.set_actor_scale3d(scale)

    mesh = actor.get_component_by_class(unreal.StaticMeshComponent)
    if mesh:
        mesh.set_static_mesh(cube)
        if isinstance(material, unreal.MaterialInterface):
            mesh.set_material(0, material)
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
    return actor


def spawn_or_get(label, actor_class, location, rotation):
    actor = find_actor(label)
    if actor:
        return actor
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(actor_class, location, rotation)
    actor.set_actor_label(label)
    return actor


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for old_label in [
        "North Forest Backdrop",
        "South Forest Backdrop",
        "East Forest Backdrop",
        "West Forest Backdrop",
        "Etherwood Distant Hill 1",
        "Etherwood Distant Hill 2",
        "Etherwood Distant Hill 3",
        "Etherwood Distant Hill 4",
        "Etherwood Distant Hill 5",
    ]:
        old_actor = find_actor(old_label)
        if old_actor:
            actor_subsystem.destroy_actor(old_actor)

    meadow_mat = load_asset("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")
    forest_mat = load_asset("/Engine/EngineMaterials/WorldGridMaterial.WorldGridMaterial")
    hill_mat = load_asset("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")

    spawn_static(
        "Etherwood Background Meadow",
        unreal.Vector(0.0, 0.0, -42.0),
        unreal.Rotator(0.0, 0.0, 0.0),
        unreal.Vector(54.0, 54.0, 0.035),
        meadow_mat,
    )

    forest_specs = [
        ("North Forest Edge", unreal.Vector(0.0, 3400.0, -48.0), unreal.Vector(68.0, 2.4, 0.025)),
        ("South Forest Edge", unreal.Vector(0.0, -3400.0, -48.0), unreal.Vector(68.0, 2.4, 0.025)),
        ("East Forest Edge", unreal.Vector(3400.0, 0.0, -48.0), unreal.Vector(2.4, 68.0, 0.025)),
        ("West Forest Edge", unreal.Vector(-3400.0, 0.0, -48.0), unreal.Vector(2.4, 68.0, 0.025)),
    ]
    for label, location, scale in forest_specs:
        spawn_static(label, location, unreal.Rotator(0.0, 0.0, 0.0), scale, forest_mat)

    for index, angle in enumerate([25, 110, 205, 300]):
        radians = math.radians(angle)
        location = unreal.Vector(math.cos(radians) * 2900.0, math.sin(radians) * 2900.0, -47.0)
        scale = unreal.Vector(9.5, 2.4, 0.06)
        rotation = unreal.Rotator(0.0, angle, 0.0)
        spawn_static(f"Etherwood Low Hill {index + 1}", location, rotation, scale, hill_mat)

    sky = spawn_or_get("Etherwood Sky Atmosphere", unreal.SkyAtmosphere, unreal.Vector(0.0, 0.0, 0.0), unreal.Rotator(0.0, 0.0, 0.0))
    sky.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))

    fog = spawn_or_get("Etherwood Soft World Fog", unreal.ExponentialHeightFog, unreal.Vector(0.0, 0.0, 120.0), unreal.Rotator(0.0, 0.0, 0.0))
    fog_component = fog.get_component_by_class(unreal.ExponentialHeightFogComponent)
    if fog_component:
        fog_component.set_editor_property("fog_density", 0.018)
        fog_component.set_editor_property("fog_height_falloff", 0.35)

    level_subsystem.save_current_level()
    unreal.log("Etherwood Village background landscape added without changing gameplay object placement.")


main()
