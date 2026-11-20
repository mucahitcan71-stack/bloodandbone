extends SceneTree

const World = preload("res://scripts/systems/world_system.gd")
const LOS = preload("res://scripts/systems/fog_line_of_sight.gd")

func _init() -> void:
    var map: Dictionary = GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Map not loaded")
        quit(1)
        return
    var world = World.new()
    world.harita_sinir = map["sinir"].duplicate()
    world._yukseklik_haritasi_yukle(map["yukseklik_haritasi"])
    var terrain := func(p: Vector2) -> float:
        return world.zemin_yuksekligi(p.x, p.y)
    var walls: Array[PackedVector2Array] = []
    var peak := Vector2(8235.294, 2352.941)
    var sources: Array[Vector2] = []
    var targets: Array[Vector2] = []

    for i in range(1000):
        var offset_y := float((i * 37) % 1001) - 500.0
        var left_distance := 150.0 + float((i * 53) % 651)
        var right_distance := 150.0 + float((i * 71) % 651)
        sources.append(peak + Vector2(-left_distance, offset_y))
        targets.append(peak + Vector2(right_distance if i % 2 == 0 else -right_distance, -offset_y * 0.7))

    var reference: Array[bool] = []
    var start := Time.get_ticks_usec()
    for i in range(sources.size()):
        reference.append(LOS.can_see(sources[i], targets[i], terrain, walls, 34.0, 34.0, 2.0))
    var baseline := float(Time.get_ticks_usec() - start) / 1000.0

    print("Step 2: %.3f ms" % baseline)
    print("Blocked: %d / %d" % [reference.count(false), reference.size()])

    for step in [4.0, 8.0, 16.0, 24.0]:
        var false_visible := 0
        var false_hidden := 0
        start = Time.get_ticks_usec()
        for i in range(sources.size()):
            var result := LOS.can_see(sources[i], targets[i], terrain, walls, 34.0, 34.0, step)
            if result and not reference[i]:
                false_visible += 1
                print("MISSED BLOCK | step=", step, " | source=", sources[i], " | target=", targets[i])
            elif not result and reference[i]:
                false_hidden += 1
        var elapsed := float(Time.get_ticks_usec() - start) / 1000.0
        print("Step %.0f: %.3f ms | False visible: %d | False hidden: %d" % [step, elapsed, false_visible, false_hidden])

    print("FOW-012 hill sampling completed")
    quit()
