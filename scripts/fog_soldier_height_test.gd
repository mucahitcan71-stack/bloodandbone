extends SceneTree

func _init() -> void:
    call_deferred("_measure")

func _measure() -> void:
    var path := "res://assets/karakterler/Exports/glTF (Godot-Unreal)/Outfits/Male_Ranger.gltf"
    var scene := load(path) as PackedScene
    if scene == null:
        push_error("Asker modeli yuklenemedi")
        quit(1)
        return

    var soldier := scene.instantiate() as Node3D
    if soldier == null:
        push_error("Model Node3D degil")
        quit(1)
        return

    soldier.scale = Vector3.ONE * 20.0
    root.add_child(soldier)

    var min_y := INF
    var max_y := -INF
    var mesh_count := 0

    for child in soldier.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance := child as MeshInstance3D
        if mesh_instance.mesh == null:
            continue
        mesh_count += 1
        var bounds := mesh_instance.get_aabb()
        for corner in range(8):
            var world_point: Vector3 = mesh_instance.global_transform * bounds.get_endpoint(corner)
            min_y = minf(min_y, world_point.y)
            max_y = maxf(max_y, world_point.y)

    if mesh_count == 0:
        push_error("Modelde mesh bulunamadi")
        quit(1)
        return

    print("Mesh sayisi: ", mesh_count)
    print("En alt nokta: ", min_y)
    print("En ust nokta: ", max_y)
    print("Model yuksekligi: ", max_y - min_y)
    quit()
