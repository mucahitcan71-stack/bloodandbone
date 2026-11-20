extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const World = preload("res://scripts/systems/world_system.gd")
const Cache = preload("res://scripts/systems/fog_vision_cache.gd")

func _init() -> void:
    var map: Dictionary = GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Map not loaded")
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
        push_error("Unit types not loaded")
        quit(1)
        return

    for scenario in ["static", "moving"]:
        var cache = Cache.new()
        var baseline_total := 0
        var cached_total := 0
        var mismatches := 0
        var hits := 0
        var misses := 0

        for frame in range(6):
            var units: Array[Dictionary] = []
            for i in range(300):
                var pos := Vector2(
                    50.0 + float((i * 137) % 14900),
                    50.0 + float((i * 311) % 8900)
                )
                if scenario == "moving":
                    pos.x += float(frame) * 2.0
                var radius: float = fog.unit_vision_radius(types[i % types.size()])
                units.append({"id": i + 1, "position": pos, "radius": radius})

            var baseline: Dictionary = {}
            var start := Time.get_ticks_usec()
            for unit in units:
                fog._gorus_ekle(baseline, unit["position"], unit["radius"])
            baseline_total += Time.get_ticks_usec() - start

            var cached: Dictionary = {}
            start = Time.get_ticks_usec()
            for unit in units:
                var unit_id: int = unit["id"]
                var pos: Vector2 = unit["position"]
                var radius: float = unit["radius"]
                var cells: Dictionary
                if cache.has_valid(unit_id, pos, radius):
                    hits += 1
                    cells = cache.get_cells(unit_id, pos, radius)
                else:
                    misses += 1
                    cells = {}
                    fog._gorus_ekle(cells, pos, radius)
                    cache.store(unit_id, pos, radius, cells)
                for cell in cells:
                    cached[cell] = true
            cached_total += Time.get_ticks_usec() - start

            if baseline != cached:
                mismatches += 1
                print("MISMATCH: ", scenario, " frame ", frame)

        print("--- ", scenario, " ---")
        print("Baseline avg: %.3f ms" % (float(baseline_total) / 6000.0))
        print("Cached avg: %.3f ms" % (float(cached_total) / 6000.0))
        print("Cache hits: %d | misses: %d" % [hits, misses])
        print("Vision mismatches: ", mismatches)
        if mismatches > 0:
            quit(1)
            return

    print("FOW-013 cache benchmark completed")
    quit()
