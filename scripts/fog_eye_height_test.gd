extends SceneTree

const World = preload("res://scripts/systems/world_system.gd")
const LOS = preload("res://scripts/systems/fog_line_of_sight.gd")

func _init() -> void:
    var map := GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Harita okunamadi")
        quit(1)
        return
    var world = World.new()
    world.harita_sinir = map["sinir"].duplicate()
    world._yukseklik_haritasi_yukle(map["yukseklik_haritasi"])
    var peak := Vector2(8235.294, 2352.941)
    var left := peak + Vector2(-400, 0)
    var right := peak + Vector2(400, 0)
    var height_reader := func(p: Vector2) -> float:
        return world.zemin_yuksekligi(p.x, p.y)
    var walls: Array[PackedVector2Array] = []
    print("Sol yukseklik: ", height_reader.call(left))
    print("Tepe yukseklik: ", height_reader.call(peak))
    print("Sag yukseklik: ", height_reader.call(right))
    print("Normal gorus: ", LOS.can_see(left, right, height_reader, walls, 34.0, 34.0, 5.0))
    print("Yuksek gozlemci gorusu: ", LOS.can_see(left, right, height_reader, walls, 800.0, 1.7, 5.0))
    print("FOW-004 gercek harita gorus hesabi tamamlandi")
    quit()
