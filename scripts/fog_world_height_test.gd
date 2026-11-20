extends SceneTree

const World = preload("res://scripts/systems/world_system.gd")
const LOS = preload("res://scripts/systems/fog_line_of_sight.gd")

var passed := 0
var failed := 0

func _init() -> void:
    var world = World.new()
    world.harita_sinir = {"min_x": 0.0, "max_x": 100.0, "min_y": 0.0, "max_y": 100.0}
    var heights: Array = []
    for y in range(5):
        for x in range(5):
            heights.append(12.0 if x == 2 else 0.0)
    world._yukseklik_haritasi_yukle({"genislik": 5, "yukseklik": 5, "veri": heights})
    var height_reader := func(p: Vector2) -> float:
        return world.zemin_yuksekligi(p.x, p.y)
    var walls: Array[PackedVector2Array] = []
    _check("WorldSystem heightmap reads hill", true, world.zemin_yuksekligi(50.0, 50.0) > 11.9)
    _check("Real heightmap blocks line of sight", false, LOS.can_see(Vector2(10, 50), Vector2(90, 50), height_reader, walls, 1.7, 1.7, 2.0))
    _check("High observer sees over hill", true, LOS.can_see(Vector2(10, 50), Vector2(90, 50), height_reader, walls, 40.0, 1.7, 2.0))
    heights.fill(0.0)
    world._yukseklik_haritasi_yukle({"genislik": 5, "yukseklik": 5, "veri": heights})
    _check("Flat WorldSystem terrain is visible", true, LOS.can_see(Vector2(10, 50), Vector2(90, 50), height_reader, walls))
    print("FOW-003: %d passed, %d failed" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(label: String, expected: bool, actual: bool) -> void:
    if expected == actual:
        passed += 1
        print("PASS: ", label)
    else:
        failed += 1
        push_error("FAIL: " + label)

