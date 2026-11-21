extends SceneTree

# Run with --path . --script res://scripts/fow_017_benchmark.gd.
# Add --headless for CPU-only runs, or --resolution 1280x720 for GPU comparison.

const SAMPLE_COUNT := 40
const UNIT_COUNT := 60

var fog := FogSystem.new()
var world := WorldSystem.new()
var field := Node2D.new()
var units: Array = []
var owners := {}

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := GameData.load_map("editor_cikti")
	if map.is_empty():
		push_error("Benchmark map missing")
		quit(1)
		return
	root.add_child(field)
	world.harita_sinir = map["sinir"]
	world._yukseklik_haritasi_yukle(map["yukseklik_haritasi"])
	fog.configure(field, world)
	fog.create_fog_layer()

	var types := GameData.load_units("osmanli")
	if types.is_empty():
		push_error("Benchmark unit types missing")
		quit(1)
		return
	var bounds := Rect2(fog._map_min, fog._map_size)
	world.nokta_konumlari["benchmark"] = bounds.get_center()
	owners["benchmark"] = "osmanli"
	for i in range(UNIT_COUNT):
		units.append({
			"id": i, "hp": 1, "taraf": "osmanli" if i % 2 == 0 else "dogu_roma",
			"konum": Vector2.ZERO, "gorus_yaricapi": fog.unit_vision_radius(types[i % types.size()]),
		})

	fog.measure_vision_update = true
	for layout in ["spread", "grouped"]:
		for moving in [false, true]:
			_sample_cpu(bounds, layout, moving)
	fog.measure_vision_update = false

	if not _check_visibility(bounds):
		quit(1)
		return
	if DisplayServer.get_name() != "headless":
		var ok := await _sample_gpu(bounds)
		if not ok:
			quit(1)
			return
		if not await _check_3d_projection():
			quit(1)
			return
	quit()


func _place_units(bounds: Rect2, layout: String, step: int) -> void:
	for i in range(units.size()):
		var fraction := Vector2(float((i * 137) % 997) / 997.0, float((i * 311) % 991) / 991.0)
		var spread := bounds.size * 0.75 if layout == "spread" else Vector2(520, 520)
		units[i]["konum"] = bounds.get_center() + (fraction - Vector2(0.5, 0.5)) * spread + Vector2(11, 7) * step


func _sample_cpu(bounds: Rect2, layout: String, moving: bool) -> void:
	fog.reset_fog_grid()
	var samples := [[], [], [], []]
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	var uploads := 0
	for sample in range(-6, SAMPLE_COUNT):
		_place_units(bounds, layout, sample if moving else 0)
		fog.update_vision(units, owners)
		if sample < 0:
			continue
		var times := fog.vision_update_usec
		for stage in range(samples.size()):
			samples[stage].append(times[stage])
		if fog.vision_update_uploaded_texture:
			uploads += 1
		for cells in [fog.get_current_vision("osmanli"), fog.get_current_vision("dogu_roma"), fog.get_discovered_cells()]:
			var keys: Array = cells.keys()
			keys.sort()
			digest.update(var_to_bytes(keys))
		digest.update(fog._clear_grid)
		digest.update(var_to_bytes(fog._fog_image.get_data()))
		var visible: Array[bool] = []
		for unit in units:
			var observer := "dogu_roma" if unit["taraf"] == "osmanli" else "osmanli"
			visible.append(fog.is_unit_visible_to_faction(unit, observer, units))
		digest.update(var_to_bytes(visible))
	print("CPU %s moving=%s n=%d uploads=%d median/p95 us vision=%s mask=%s texture_pack=%s texture_submit=%s sha256=%s" % [
		layout, moving, SAMPLE_COUNT, uploads, _stats(samples[0]), _stats(samples[1]),
		_stats(samples[2]), _stats(samples[3]), digest.finish().hex_encode(),
	])


func _check_visibility(bounds: Rect2) -> bool:
	fog.reset_fog_grid()
	var start := bounds.get_center()
	var finish := start + Vector2(600, 0) # Deliberate jump to isolate stale-mask behavior.
	var scout := {"id": 1000, "hp": 1, "taraf": "osmanli", "konum": start, "gorus_yaricapi": 150.0}
	var enemy := {"hp": 1, "taraf": "dogu_roma", "konum": start}
	fog.update_vision([scout], {})
	var seen := fog.is_unit_visible_to_player(enemy, [scout, enemy])
	scout["konum"] = finish
	var texel := fog._world_to_tex(finish)
	var index := texel.y * fog._fog_tex_w + texel.x
	var stale_mask := fog._clear_grid[index] == 0 and fog.is_unit_visible_to_player(scout, [scout])
	fog.update_vision([scout], {})
	var refreshed := fog._clear_grid[index] == 2
	var persistent := fog.is_world_pos_discovered(start)
	var hidden := not fog.is_unit_visible_to_player(enemy, [scout, enemy])
	print("CHECK seen=%s stale_mask_over_friendly=%s refreshed=%s persistent=%s enemy_hidden_on_explored=%s" % [
		seen, stale_mask, refreshed, persistent, hidden,
	])
	_check_normal_speed_transition(bounds)
	return seen and stale_mask and refreshed and persistent and hidden


func _check_normal_speed_transition(bounds: Rect2) -> void:
	# Look for a newly revealed texel within one ordinary movement interval.
	var cells_before := {}
	var cells_after := {}
	var sampler := world.terrain_height_sampler()
	var stride: float = fog.gorus_hucre_boyutu * 0.5
	for y in range(1, int(bounds.size.y / stride), 3):
		for x in range(1, int(bounds.size.x / stride), 3):
			var start := bounds.position + Vector2(x, y) * stride
			cells_before.clear()
			fog._gorus_ekle(cells_before, start, 150.0, sampler)
			for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				var finish: Vector2 = start + direction * (78.0 * 0.14)
				var texel := fog._world_to_tex(finish)
				var pixel_center := bounds.position + (Vector2(texel) + Vector2(0.5, 0.5)) * bounds.size / Vector2(fog._fog_tex_w, fog._fog_tex_h)
				var key := fog._hucre_anahtari(pixel_center)
				if cells_before.has(key):
					continue
				cells_after.clear()
				fog._gorus_ekle(cells_after, finish, 150.0, sampler)
				if cells_after.has(key):
					print("NORMAL SPEED stale texel found start=%s finish=%s texel=%s" % [start, finish, texel])
					return
	print("NORMAL SPEED no stale texel found in sampled routes")


func _sample_gpu(bounds: Rect2) -> bool:
	_place_units(bounds, "grouped", 0)
	fog.reset_fog_grid()
	fog.update_vision(units, owners)
	for unit in units:
		var marker := ColorRect.new()
		marker.position = world.logical_to_ekran(unit["konum"])
		marker.size = Vector2(16, 24)
		field.add_child(marker)
	var camera := Camera2D.new()
	camera.name = "BenchmarkCamera"
	camera.position = world.logical_to_ekran(bounds.get_center())
	camera.zoom = Vector2(0.75, 0.75)
	field.add_child(camera)
	camera.make_current()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var viewport := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	for overlay in [false, true, true, false]:
		fog.set_layer_visible(overlay)
		var samples := []
		for frame in range(-35, 120):
			await RenderingServer.frame_post_draw
			if frame >= 0:
				samples.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport) * 1000.0)
		var stats := _stats(samples)
		print("GPU overlay=%s units=%d viewport=%s median/p95 us=%s" % [overlay, UNIT_COUNT, root.get_visible_rect().size, stats])
		if stats.x <= 0:
			push_error("GPU timestamps unavailable on this renderer")
			return false
	return true


func _check_3d_projection() -> bool:
	world.configure(field)
	world.kamera = field.get_node("BenchmarkCamera")
	world._zemin3d_ekle(world.harita_sinir)
	var viewport := world._zemin3d_viewport
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var friendly := _add_projection_probe(Color.GREEN)
	world._protect_friendly_mesh_from_fog(friendly)
	var enemy := _add_projection_probe(Color.RED)

	# Leave the mask unknown to exercise the case where movement leads the vision tick.
	fog.reset_fog_grid()
	var camera := world._zemin3d_kam3d
	var camera_target := Vector2(7458, 3996)
	world.kamera.position = world.logical_to_ekran(camera_target)
	var passed := true
	for zoom in [0.55, 0.75, 1.25]:
		world.kamera.zoom = Vector2.ONE * zoom
		world.kamera.force_update_scroll()
		world._zemin3d_bolge_guncelle(true)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await RenderingServer.frame_post_draw
		for offset in [Vector2(-165, -160), Vector2.ZERO, Vector2(168, 170)]:
			var pos: Vector2 = camera_target + offset
			var enemy_pos := pos + Vector2(100, -100)
			var height := world.zemin_yuksekligi(pos.x, pos.y)
			friendly.position = Vector3(pos.x, height + 26.0, pos.y)
			enemy.position = Vector3(enemy_pos.x, world.zemin_yuksekligi(enemy_pos.x, enemy_pos.y) + 26.0, enemy_pos.y)
			var friendly_pixel := Vector2i(camera.unproject_position(friendly.position))
			var enemy_pixel := Vector2i(camera.unproject_position(enemy.position))

			fog.set_layer_visible(false)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var clear := viewport.get_texture().get_image()
			fog.set_layer_visible(true)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var fogged := viewport.get_texture().get_image()

			var f0 := clear.get_pixelv(friendly_pixel)
			var f1 := fogged.get_pixelv(friendly_pixel)
			var e0 := clear.get_pixelv(enemy_pixel)
			var e1 := fogged.get_pixelv(enemy_pixel)
			var occluded: bool = offset == Vector2(168, 170)
			var friendly_ok := f0.g > 0.6 and f0.is_equal_approx(f1)
			if occluded:
				friendly_ok = f0.g < 0.6 and f1.g < 0.25
			var ok := friendly_ok and e0.r > 0.6 and e1.r < 0.35
			passed = passed and ok
			print("3D PROJECTION zoom=%.2f height=%.2f friendly=%s -> %s enemy=%s -> %s pass=%s" % [
				zoom, height, f0, f1, e0, e1, ok,
			])
	# A visible point on the hill must sample the same map cell after projection.
	friendly.material_overlay = null
	var h := world.zemin_yuksekligi(camera_target.x, camera_target.y)
	friendly.position = Vector3(camera_target.x, h + 26.0, camera_target.y)
	var pixel := Vector2i(camera.unproject_position(friendly.position))
	var scout := {"hp": 1, "taraf": "osmanli", "konum": camera_target, "gorus_yaricapi": 240.0}
	fog.update_vision([scout], {})
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var revealed := viewport.get_texture().get_image().get_pixelv(pixel)
	fog.update_vision([], {})
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var explored := viewport.get_texture().get_image().get_pixelv(pixel)
	var mapped_ok := revealed.g > 0.75 and revealed.is_equal_approx(explored)
	print("3D MASK correct_world_cell_and_persistent=%s" % mapped_ok)
	passed = passed and mapped_ok
	fog.reset_fog_grid()
	friendly.queue_free()
	enemy.queue_free()
	await process_frame
	var unit := {"id": 1000, "taraf": "osmanli", "konum": camera_target}
	world.zemin3d_birim_asker_ekle(unit)
	var model := unit.get("asker3d") as Node3D
	if model == null:
		push_error("Could not instantiate the battle soldier")
		return false

	for zoom in [0.55, 0.75, 1.25]:
		world.kamera.zoom = Vector2.ONE * zoom
		world.kamera.force_update_scroll()
		world._zemin3d_bolge_guncelle(true)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await RenderingServer.frame_post_draw
		for step in range(3):
			unit["konum"] = camera_target + Vector2(5 * step, -5 * step)
			world.zemin3d_birim_asker_guncelle(unit, 0.1)
			if not await _check_soldier_pixels(unit, viewport, camera):
				passed = false
	await _sample_terrain_fog_gpu(viewport)
	world.zemin3d_birim_asker_sil(unit)
	return passed


func _check_soldier_pixels(unit: Dictionary, viewport: SubViewport, camera: Camera3D) -> bool:
	var model: Node3D = unit["asker3d"]
	var player := model.get_node_or_null("BirimAnimPlayer") as AnimationPlayer
	if player:
		player.advance(0.1)
		player.speed_scale = 0.0
	var ring: Node3D = unit["halka3d"]
	ring.visible = false

	fog.set_layer_visible(false)
	model.hide()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var background := viewport.get_texture().get_image()
	model.show()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var visible_soldier := viewport.get_texture().get_image()
	fog.set_layer_visible(true)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var fogged := viewport.get_texture().get_image()
	model.hide()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var fogged_background := viewport.get_texture().get_image()
	model.show()
	if player:
		player.speed_scale = 1.0

	var center := Vector2i(camera.unproject_position(model.position))
	var region := Rect2i(center - Vector2i(65, 84), Vector2i(130, 103)).intersection(
		Rect2i(Vector2i.ONE, viewport.size - Vector2i(2, 2)))
	var subject_pixels := 0
	var preserved_pixels := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var original := visible_soldier.get_pixel(x, y)
			var core := true
			for neighbor in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var pixel := Vector2i(x, y) + Vector2i(neighbor)
				if _pixel_difference(visible_soldier.get_pixelv(pixel), background.get_pixelv(pixel)) <= 0.15:
					core = false
			if core:
				subject_pixels += 1
				var rendered := fogged.get_pixel(x, y)
				var fog_color := fogged_background.get_pixel(x, y)
				# Glow around the soldier can change with the fogged background.
				if _pixel_difference(rendered, original) < _pixel_difference(rendered, fog_color):
					preserved_pixels += 1
	var passed := subject_pixels > 0 and preserved_pixels >= subject_pixels * 0.95
	print("BATTLE SOLDIER zoom=%.2f pos=%s protected=%d/%d pass=%s" % [
		world.kamera.zoom.x, unit["konum"], preserved_pixels, subject_pixels, passed,
	])
	return passed


func _sample_terrain_fog_gpu(viewport: SubViewport) -> void:
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for overlay in [false, true, true, false]:
		fog.set_layer_visible(overlay)
		var samples := []
		for frame in range(-20, 60):
			await RenderingServer.frame_post_draw
			if frame >= 0:
				samples.append(RenderingServer.viewport_get_measured_render_time_gpu(rid) * 1000.0)
		print("3D GPU overlay=%s viewport=%s median/p95 us=%s" % [overlay, viewport.size, _stats(samples)])
	RenderingServer.viewport_set_measure_render_time(rid, false)


func _pixel_difference(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


func _add_projection_probe(color: Color) -> MeshInstance3D:
	var probe := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(32, 50, 32)
	probe.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	probe.material_override = material
	world._zemin3d_kok.add_child(probe)
	return probe


func _stats(samples: Array) -> Vector2:
	samples.sort()
	return Vector2(samples[samples.size() / 2], samples[ceili(samples.size() * 0.95) - 1])
