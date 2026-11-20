extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const World = preload("res://scripts/systems/world_system.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var map: Dictionary = GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Map missing")
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

    var source := Vector2(7835.294, 2352.941)
    var target := Vector2(8635.294, 2352.941)
    var target_cell := fog._hucre_anahtari(target)
    var units: Array = [{
        "id": 101,
        "hp": 100.0,
        "taraf": "osmanli",
        "konum": source,
        "gorus_yaricapi": 950.0
    }]

    fog.update_vision(units, {})
    var blocked: bool = not fog.su_anki_gorus_alani.has(target_cell)
    print("Hill blocks target: ", blocked)

    var flat_heights: Array = map["yukseklik_haritasi"]["veri"].duplicate()
    flat_heights.fill(0.0)
    var flat_map: Dictionary = map["yukseklik_haritasi"].duplicate()
    flat_map["veri"] = flat_heights
    world._yukseklik_haritasi_yukle(flat_map)

    fog.update_vision(units, {})
    var visible_after_change: bool = fog.su_anki_gorus_alani.has(target_cell)
    print("Visible after terrain change: ", visible_after_change)

    fog._vision_cache.clear()
    fog.update_vision(units, {})
    var visible_after_clear: bool = fog.su_anki_gorus_alani.has(target_cell)
    print("Visible after cache clear: ", visible_after_clear)

    if blocked and visible_after_clear:
        if visible_after_change:
            print("Terrain cache already updates correctly")
        else:
            print("CONFIRMED: Terrain change requires cache invalidation")
        quit()
    else:
        push_error("Unexpected terrain test result")
        quit(1)
