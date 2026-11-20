extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")

func _init() -> void:
    var fog = Fog.new()
    fog.gorus_hucre_boyutu = 120.0
    for count in [10, 50, 100, 300]:
        var start := Time.get_ticks_usec()
        var total_cells := 0
        for frame in range(30):
            var visible: Dictionary = {}
            for i in range(count):
                var position := Vector2(float((i * 149) % 15000), float((i * 317) % 9000))
                fog._gorus_ekle(visible, position, 110.0)
            total_cells += visible.size()
        var elapsed_ms := float(Time.get_ticks_usec() - start) / 1000.0
        print("Asker: ", count, " | Ortalama: ", snappedf(elapsed_ms / 30.0, 0.001), " ms | Hucre: ", total_cells / 30)
    quit()
