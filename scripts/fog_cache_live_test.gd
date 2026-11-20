extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const World = preload("res://scripts/systems/world_system.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var map: Dictionary = GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Map could not be loaded")
        quit(1)
        return

    var world = World.new()
    world.harita_sinir = map["sinir"].duplicate()
    world._yukseklik_haritasi_yukle(map["yukseklik_haritasi"])

    var host := Node2D.new()
    root.add_child(host)

    var fog = Fog.new()
    fog.configure(host, world)
    fog.create_fog_layer()

    var pos := Vector2(5000.0, 4500.0)
    var moved := Vector2(7000.0, 4500.0)
    var unit := {
        "id": 101,
        "hp": 100.0,
        "taraf": "osmanli",
        "konum": pos,
        "gorus_yaricapi": 180.0
    }
    var units: Array = [unit]
    var owners: Dictionary = {}
    var passed := 0
    var failed := 0

    fog.update_vision(units, owners)
    if fog._vision_cache.entry_count() == 1 and not fog.su_anki_gorus_alani.is_empty():
        print("PASS: First vision calculated")
        passed += 1
    else:
        print("FAIL: First vision")
        failed += 1

    var first_vision: Dictionary = fog.su_anki_gorus_alani.duplicate()
    fog.update_vision(units, owners)
    if fog.su_anki_gorus_alani == first_vision and fog._vision_cache.entry_count() == 1:
        print("PASS: Stationary vision unchanged")
        passed += 1
    else:
        print("FAIL: Stationary vision")
        failed += 1

    unit["konum"] = moved
    fog.update_vision(units, owners)
    if not fog.su_anki_gorus_alani.has(fog._hucre_anahtari(pos)) and fog.su_anki_gorus_alani.has(fog._hucre_anahtari(moved)):
        print("PASS: Movement updates vision")
        passed += 1
    else:
        print("FAIL: Movement")
        failed += 1

    unit["taraf"] = "dogu_roma"
    fog.update_vision(units, owners)
    if fog.su_anki_gorus_alani.is_empty() and fog.ai_su_anki_gorus_alani.has(fog._hucre_anahtari(moved)):
        print("PASS: Faction change updates vision")
        passed += 1
    else:
        print("FAIL: Faction change")
        failed += 1

    unit["hp"] = 0.0
    fog.update_vision(units, owners)
    if fog._vision_cache.entry_count() == 0 and fog.ai_su_anki_gorus_alani.is_empty():
        print("PASS: Dead unit removed")
        passed += 1
    else:
        print("FAIL: Dead unit")
        failed += 1

    fog.reset_fog_grid()
    if fog._vision_cache.entry_count() == 0:
        print("PASS: Map reset clears cache")
        passed += 1
    else:
        print("FAIL: Map reset")
        failed += 1

    print("FOW-013 LIVE TEST: %d passed, %d failed" % [passed, failed])
    quit(0 if failed == 0 else 1)
