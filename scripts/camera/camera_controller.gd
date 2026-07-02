extends RefCounted
class_name CameraController

var speed := 800.0
var edge_trigger_px := 35.0
var zoom_min := 0.15
var zoom_max := 1.5
var zoom_speed := 0.1

func apply_pan(camera: Camera2D, delta: float, mouse_pos: Vector2, viewport_size: Vector2, clamp_cb: Callable) -> void:
	if camera == null:
		return
	var direction = Vector2.ZERO
	if mouse_pos.x < edge_trigger_px:
		direction.x -= 1.0
	elif mouse_pos.x > viewport_size.x - edge_trigger_px:
		direction.x += 1.0
	if mouse_pos.y < edge_trigger_px:
		direction.y -= 1.0
	elif mouse_pos.y > viewport_size.y - edge_trigger_px:
		direction.y += 1.0
	if Input.is_action_pressed("cmd_camera_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("cmd_camera_down"):
		direction.y += 1.0
	if Input.is_action_pressed("cmd_camera_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("cmd_camera_right"):
		direction.x += 1.0
	if direction == Vector2.ZERO:
		return
	direction = direction.normalized()
	camera.position += direction * speed * delta
	if clamp_cb.is_valid():
		clamp_cb.call()

func apply_drag_pan(camera: Camera2D, relative: Vector2, clamp_cb: Callable) -> void:
	if camera == null:
		return
	camera.position -= relative / camera.zoom.x
	if clamp_cb.is_valid():
		clamp_cb.call()

func apply_zoom(camera: Camera2D, zoom_in: bool) -> void:
	if camera == null:
		return
	var delta = Vector2(zoom_speed, zoom_speed)
	if zoom_in:
		delta *= -1.0
	var yeni = camera.zoom + delta
	camera.zoom = Vector2(
		clamp(yeni.x, zoom_min, zoom_max),
		clamp(yeni.y, zoom_min, zoom_max)
	)
