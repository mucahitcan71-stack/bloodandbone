extends Node2D

class ClickMarker extends Node2D:
	const RADIUS := 10.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.2, 0.2, 0.9))
		draw_line(Vector2(-14, 0), Vector2(14, 0), Color.YELLOW, 2.0)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color.YELLOW, 2.0)


@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D

var _marker: ClickMarker
const GRID_HALF := 8


func _ready() -> void:
	_setup_marker()
	_setup_grid()
	camera.make_current()


func _setup_marker() -> void:
	_marker = ClickMarker.new()
	_marker.name = "ClickMarker"
	_marker.z_index = 10
	_marker.visible = false
	add_child(_marker)


func _setup_grid() -> void:
	if tile_layer.tile_set != null and not tile_layer.get_used_cells().is_empty():
		return

	var image := _make_iso_tile_image()
	var tex := ImageTexture.create_from_image(image)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(128, 64)
	atlas.create_tile(Vector2i(0, 0))

	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_size = Vector2i(128, 64)
	tileset.add_source(atlas, 0)
	tile_layer.tile_set = tileset

	for x in range(-GRID_HALF, GRID_HALF + 1):
		for y in range(-GRID_HALF, GRID_HALF + 1):
			tile_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	camera.position = tile_layer.map_to_local(Vector2i.ZERO)


func _make_iso_tile_image() -> Image:
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color(0.18, 0.55, 0.28)
	var edge := Color(0.12, 0.38, 0.2)
	for y in range(64):
		for x in range(128):
			var dx := absf(x - 64.0) / 64.0
			var dy := absf(y - 32.0) / 32.0
			var d := dx + dy
			if d <= 1.0:
				img.set_pixel(x, y, edge if d > 0.92 else fill)
	return img


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_left_click()


func _on_left_click() -> void:
	if tile_layer == null:
		return

	var local_pos := tile_layer.get_local_mouse_position()
	var map_coord := tile_layer.local_to_map(local_pos)
	var center_local := tile_layer.map_to_local(map_coord)
	var center_global := tile_layer.to_global(center_local)

	_marker.global_position = center_global
	_marker.visible = true
	_marker.queue_redraw()

	print(
		"Tiklanan karo: ", map_coord,
		" | fare local: ", local_pos,
		" | merkez: ", center_global
	)
