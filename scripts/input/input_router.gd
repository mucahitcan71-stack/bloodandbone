extends RefCounted
class_name InputRouter

const CameraControllerScript = preload("res://scripts/camera/camera_controller.gd")

func handle_camera_input(
	event: InputEvent,
	camera: Camera2D,
	camera_controller: CameraControllerScript
) -> bool:
	if event.is_action_pressed("cmd_zoom_in"):
		camera_controller.apply_zoom(camera, true)
		return true
	if event.is_action_pressed("cmd_zoom_out"):
		camera_controller.apply_zoom(camera, false)
		return true
	return false
