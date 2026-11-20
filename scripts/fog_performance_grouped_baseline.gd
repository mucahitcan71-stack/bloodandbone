extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const LOS = preload("res://scripts/systems/fog_line_of_sight.gd")

func _init() -> void:
    var fog = Fog.new()
    fog.gorus_hucre_boyutu = 120.0
    var walls: Array[PackedVector2Array] = []
    var terrain := Callable(self, "_flat")

    for count in [10, 50, 100, 300]:
        var old_total := 0
        var new_total := 0
        var visible_old := 0
        var visible_new := 0

        for frame in range(30):
            var old_grid: Dictionary = {}
            var start := Time.get_ticks_usec()
            for i in range(count):
                var p := Vector2(7500.0 + float(i % 10) * 8.0, 4500.0 + float(i / 10) * 8.0)
                fog._gorus_ekle(old_grid, p, 110.0)
            old_total += Time.get_ticks_usec() - start
            visible_old += old_grid.size()

            var new_grid: Dictionary = {}
            start = Time.get_ticks_usec()
            for i in range(count):
                var p := Vector2(7500.0 + float(i % 10) * 8.0, 4500.0 + float(i / 10) * 8.0)
                var min_h: Vector2i = fog._hucre_anahtari(p - Vector2(110, 110))
                var max_h: Vector2i = fog._hucre_anahtari(p + Vector2(110, 110))
                for x in range(min_h.x, max_h.x + 1):
                    for y in range(min_h.y, max_h.y + 1):
                        var key := Vector2i(x, y)
                        var cell: Vector2 = fog._hucre_merkezi(key)
                        if cell.distance_squared_to(p) <= 110.0 * 110.0:
                            if LOS.can_see(p, cell, terrain, walls, 1.7, 1.7, 8.0):
                                new_grid[key] = true
            new_total += Time.get_ticks_usec() - start
            visible_new += new_grid.size()

        print("Asker: ", count)
        print("  Eski: ", snappedf(float(old_total) / 30000.0, 0.001), " ms")
        print("  Yeni: ", snappedf(float(new_total) / 30000.0, 0.001), " ms")
        print("  Hucre eski/yeni: ", visible_old / 30, " / ", visible_new / 30)
    quit()

func _flat(_pos: Vector2) -> float:
    return 0.0
