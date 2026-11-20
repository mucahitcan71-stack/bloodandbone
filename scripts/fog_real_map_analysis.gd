extends SceneTree

func _init() -> void:
    var path := "res://data/maps/editor_cikti.json"
    var raw := FileAccess.get_file_as_string(path)
    var json = JSON.parse_string(raw)
    if not json is Dictionary:
        push_error("Harita JSON okunamadi")
        quit(1)
        return
    var heightmap: Dictionary = json.get("yukseklik_haritasi", {})
    var values: Array = heightmap.get("veri", [])
    if values.is_empty():
        push_error("Yukseklik verisi bos")
        quit(1)
        return
    var smallest := INF
    var largest := -INF
    var nonzero := 0
    for value in values:
        var height := float(value)
        smallest = minf(smallest, height)
        largest = maxf(largest, height)
        if not is_zero_approx(height):
            nonzero += 1
    print("Grid: ", heightmap.get("genislik"), " x ", heightmap.get("yukseklik"))
    print("Hucre sayisi: ", values.size())
    print("Minimum: ", smallest)
    print("Maksimum: ", largest)
    print("Sifirdan farkli: ", nonzero)
    quit()
