extends SceneTree

const Fog = preload("res://scripts/systems/fog_system.gd")
const World = preload("res://scripts/systems/world_system.gd")

var passed := 0
var failed := 0

func _init() -> void:
	var world = World.new()
	world.harita_sinir = {"min_x": 0.0, "max_x": 100.0, "min_y": 0.0, "max_y": 100.0}
	var heights: Array = []
	for y in range(5):
		for x in range(5):
			heights.append(120.0 if x == 2 else 0.0)
	world._yukseklik_haritasi_yukle({"genislik": 5, "yukseklik": 5, "veri": heights})

	var fog = Fog.new()
	fog._world = world
	fog.gorus_hucre_boyutu = 20.0
	var target_key := Vector2i(4, 2)
	var visible: Dictionary = {}

	fog._gorus_ekle(visible, Vector2(10, 50), 100.0)
	_check("Hill blocks target in FogSystem", not visible.has(target_key))
	_check("Observer's own cell stays visible", visible.has(Vector2i(0, 2)))

	visible.clear()
	fog._gorus_ekle(visible, Vector2(50, 50), 100.0)
	_check("Observer on hill sees target", visible.has(target_key))

	heights.fill(0.0)
	world._yukseklik_haritasi_yukle({"genislik": 5, "yukseklik": 5, "veri": heights})
	visible.clear()
	fog._gorus_ekle(visible, Vector2(10, 50), 100.0)
	_check("Flat terrain reveals target", visible.has(target_key))

	print("--- FOW-010 performance: flat synthetic map ---")
	for count in [10, 100, 300]:
		var started := Time.get_ticks_usec()
		var last_cells := 0
		for frame in range(20):
			var grid: Dictionary = {}
			for i in range(count):
				var pos := Vector2(float((i * 37) % 100) + 0.5, float((i * 61) % 100) + 0.5)
				fog._gorus_ekle(grid, pos, 60.0)
			last_cells = grid.size()
		var elapsed := float(Time.get_ticks_usec() - started) / 20000.0
		print("Soldiers: %d | Avg: %.3f ms | Cells: %d" % [count, elapsed, last_cells])

	print("FOW-010 RESULTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)
