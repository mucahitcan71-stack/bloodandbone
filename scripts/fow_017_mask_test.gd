extends SceneTree

# Run with --headless --path . --script res://scripts/fow_017_mask_test.gd.
# Keep the original full projection as a reference for the incremental mask.
class ReferenceFog extends FogSystem:
	func _rebuild_clear_grid() -> void:
		var next_grid := PackedByteArray()
		next_grid.resize(_fog_tex_w * _fog_tex_h)
		for y in range(_fog_tex_h):
			for x in range(_fog_tex_w):
				var pos := _map_min + Vector2(
					(float(x) + 0.5) / float(_fog_tex_w) * _map_size.x,
					(float(y) + 0.5) / float(_fog_tex_h) * _map_size.y)
				var cell := _hucre_anahtari(pos)
				if harita_sis_kapali or get_current_vision("osmanli").get(cell, false):
					next_grid[y * _fog_tex_w + x] = 2
				elif get_discovered_cells().get(cell, false):
					next_grid[y * _fog_tex_w + x] = 1
		if next_grid == _clear_grid:
			return
		_clear_grid = next_grid
		for i in range(next_grid.size()):
			_fog_texture_bytes.encode_float(i * 4, next_grid[i] * 0.5)
		_fog_dirty = true
		_minimap_dirty = true


var world := WorldSystem.new()
var fog := FogSystem.new()
var reference := ReferenceFog.new()
var checks := 0

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for system in [fog, reference]:
		var field := Node2D.new()
		root.add_child(field)
		system.configure(field, world)
		system.create_fog_layer()
		system.measure_vision_update = true

	for map_id in ["editor_cikti", "trakya", "levant", "balkanlar", "anadolu"]:
		var map := GameData.load_map(map_id)
		if map.is_empty():
			push_error("Missing fixture map %s" % map_id)
			quit(1)
			return
		if not _check_map(map_id, map["sinir"], map.get("yukseklik_haritasi")):
			quit(1)
			return

	# Offset a small map so several texels map to each logical cell.
	if not _check_map("shifted small map", {"min_x": -23.5, "max_x": 56.25, "min_y": 13.25, "max_y": 68.9}, null):
		quit(1)
		return
	print("MASK EQUIVALENCE: %d updates passed" % checks)
	quit()


func _check_map(label: String, bounds: Dictionary, terrain: Variant) -> bool:
	world.harita_sinir = bounds
	world._yukseklik_haritasi_yukle(terrain)
	for system in [fog, reference]:
		system.reset_fog_on_map_change()
	var region := Rect2(fog._map_min, fog._map_size)
	world.nokta_konumlari = {"C": region.get_center()}
	var units := []
	var radius := minf(region.size.x, region.size.y) * 0.04
	for i in range(16):
		units.append({
			"id": i, "hp": 1, "taraf": "osmanli" if i % 2 == 0 else "dogu_roma",
			"konum": region.get_center(), "gorus_yaricapi": clampf(radius, 38.0, 180.0),
		})

	var owners := {"C": "osmanli"}
	for step in range(12):
		for i in range(units.size()):
			var fraction := Vector2(float((i * 137) % 997), float((i * 311) % 991)) / 1000.0
			units[i]["konum"] = region.position + (fraction * 0.8 + Vector2(0.1, 0.1)) * region.size
			units[i]["konum"] += Vector2(0.004, 0.003) * region.size * step
		if step == 6:
			owners["C"] = "dogu_roma"
			units[0]["hp"] = 0
		if not _compare(units, owners, "%s moving %d" % [label, step]):
			return false

	if not _compare(units, owners, label + " stationary") or fog.vision_update_uploaded_texture:
		push_error("Unexpected stationary texture upload on %s" % label)
		return false

	# Moving all units outside the map still affects logical vision.
	for unit in units:
		unit["konum"] += region.size * 5.0
	if not _compare(units, {}, label + " leaving the map"):
		return false
	for unit in units:
		unit["konum"] += region.size * 2.0
	if not _compare(units, {}, label + " outside the map") or fog.vision_update_uploaded_texture:
		push_error("Unexpected off-map texture upload on %s" % label)
		return false

	for system in [fog, reference]:
		system.harita_sis_kapali = true
	if not _compare(units, {}, label + " reveal all"):
		return false
	for system in [fog, reference]:
		system.harita_sis_kapali = false
	if not _compare(units, {}, label + " restore fog"):
		return false

	if terrain is Dictionary:
		var source := region.get_center()
		if label == "editor_cikti":
			source = Vector2(7835.294, 2352.941)
			units[1]["konum"] = Vector2(8635.294, 2352.941)
		units[2]["konum"] = source
		units[2]["gorus_yaricapi"] = 950.0
		if not _compare(units, {}, label + " before terrain revision"):
			return false
		var hill_blocks := not fog.is_unit_visible_to_player(units[1], units)
		var heights: PackedFloat32Array = terrain["veri"].duplicate()
		heights.fill(0.0)
		var flat: Dictionary = terrain.duplicate()
		flat["veri"] = heights
		world._yukseklik_haritasi_yukle(flat)
		if not _compare(units, {}, label + " after terrain revision"):
			return false
		if label == "editor_cikti" and (not hill_blocks or not fog.is_unit_visible_to_player(units[1], units)):
			push_error("Hill should block visibility until the terrain is flattened")
			return false
	print("PASS %s pixels=%s" % [label, fog._fog_image.get_size()])
	return true


func _compare(units: Array, owners: Dictionary, label: String) -> bool:
	for system in [fog, reference]:
		system.update_vision(units, owners)
		system.update_minimap_fow()
	var equal := (
		fog.get_current_vision("osmanli") == reference.get_current_vision("osmanli")
		and fog.get_current_vision("dogu_roma") == reference.get_current_vision("dogu_roma")
		and fog.get_discovered_cells() == reference.get_discovered_cells()
		and fog.get_discovered_points() == reference.get_discovered_points()
		and fog._clear_grid == reference._clear_grid
		and fog._fog_image.get_data() == reference._fog_image.get_data()
		and fog.get_minimap_fow_image().get_data() == reference.get_minimap_fow_image().get_data()
	)
	for unit in units:
		var observer := "dogu_roma" if unit["taraf"] == "osmanli" else "osmanli"
		equal = equal and (fog.is_unit_visible_to_faction(unit, observer, units)
			== reference.is_unit_visible_to_faction(unit, observer, units))
	if not equal:
		push_error("Mask or visibility differs from reference: %s" % label)
		return false
	checks += 1
	return true
