extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const World = preload("res://scripts/systems/world_system.gd")

func _init() -> void:
    var map: Dictionary = GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("FAIL: Map not loaded")
        quit(1)
        return
    var world = World.new()
    world.harita_sinir = map["sinir"].duplicate()
    world._yukseklik_haritasi_yukle(map["yukseklik_haritasi"])
    var fog = Fog.new()
    fog._world = world
    fog.gorus_hucre_boyutu = 120.0
    var types: Array = []
    types.append_array(GameData.load_units("osmanli"))
    types.append_array(GameData.load_units("dogu_roma"))
    if types.is_empty():
        push_error("FAIL: Unit types not loaded")
        quit(1)
        return
    print("Unit types: ", types.size())
    for layout in ["grouped", "spread"]:
        print("--- Layout: ", layout, " ---")
        for count in [10, 100, 300]:
            var total_usec := 0
            var cells := 0
            for frame in range(15):
                var visible: Dictionary = {}
                var start := Time.get_ticks_usec()
                for i in range(count):
                    var p: Vector2
                    if layout == "grouped":
                        p = Vector2(7500.0 + float(i % 15) * 8.0, 4500.0 + float(i / 15) * 8.0)
                    else:
                        p = Vector2(50.0 + float((i * 137) % 14900), 50.0 + float((i * 311) % 8900))
                    var radius: float = fog.unit_vision_radius(types[i % types.size()])
                    fog._gorus_ekle(visible, p, radius)
                total_usec += Time.get_ticks_usec() - start
                cells = visible.size()
            var avg_ms := float(total_usec) / 15000.0
            print("Soldiers: %d | Avg: %.3f ms | Cells: %d" % [count, avg_ms, cells])
    print("FOW-012 benchmark completed")
    quit()
