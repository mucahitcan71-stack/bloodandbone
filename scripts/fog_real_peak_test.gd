extends SceneTree

func _init() -> void:
    var map := GameData.load_map("editor_cikti")
    if map.is_empty():
        push_error("Harita yuklenemedi")
        quit(1)
        return
    var h: Dictionary = map.get("yukseklik_haritasi", {})
    var values: Array = h.get("veri", [])
    var width := int(h.get("genislik", 0))
    var height := int(h.get("yukseklik", 0))
    if width <= 1 or height <= 1 or values.size() != width * height:
        push_error("Heightmap boyutlari gecersiz")
        quit(1)
        return
    var max_index := 0
    for i in range(values.size()):
        if float(values[i]) > float(values[max_index]):
            max_index = i
    var bounds: Dictionary = map["sinir"]
    var x := int(max_index % width)
    var y := int(max_index / width)
    var px := lerpf(float(bounds["min_x"]), float(bounds["max_x"]), float(x) / float(width - 1))
    var py := lerpf(float(bounds["min_y"]), float(bounds["max_y"]), float(y) / float(height - 1))
    print("Harita: editor_cikti")
    print("En yuksek tepe: ", values[max_index])
    print("Grid noktasi: ", Vector2i(x, y))
    print("Mantiksal konum: ", Vector2(px, py))
    print("Harita sinirlari: ", bounds)
    quit()
