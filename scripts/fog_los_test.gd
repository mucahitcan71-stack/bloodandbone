extends SceneTree

const LOS = preload("res://scripts/systems/fog_line_of_sight.gd")

var passed: int = 0
var failed: int = 0

func _init() -> void:
	var start := Vector2(0.0, 0.0)
	var target := Vector2(100.0, 0.0)
	var empty_walls: Array[PackedVector2Array] = []
	var blocking_walls: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(50, -10), Vector2(50, 10)])
	]
	var distant_walls: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(50, 20), Vector2(50, 40)])
	]

	_check("flat ground is visible", true,
		LOS.can_see(start, target, Callable(self, "_flat"), empty_walls))
	_check("hill occludes target", false,
		LOS.can_see(start, target, Callable(self, "_hill"), empty_walls, 1.7, 1.7, 5.0))
	_check("wall occludes target", false,
		LOS.can_see(start, target, Callable(self, "_flat"), blocking_walls))
	_check("wall outside ray does not occlude", true,
		LOS.can_see(start, target, Callable(self, "_flat"), distant_walls))
	_check("high lookout sees over low hill", true,
		LOS.can_see(start, target, Callable(self, "_lookout_hill"), empty_walls, 1.7, 1.7, 5.0))
	_check("same origin and target", true,
		LOS.can_see(start, start, Callable(self, "_flat"), empty_walls))
	_check("invalid sampling interval rejected", false,
		LOS.can_see(start, target, Callable(self, "_flat"), empty_walls, 1.7, 1.7, 0.0))

	print("FOW-002 results: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _flat(_pos: Vector2) -> float:
	return 0.0

func _hill(pos: Vector2) -> float:
	return 8.0 if pos.x >= 40.0 and pos.x <= 60.0 else 0.0

func _lookout_hill(pos: Vector2) -> float:
	if pos.x <= 1.0:
		return 10.0
	return 5.0 if pos.x >= 40.0 and pos.x <= 60.0 else 0.0

func _check(label: String, expected: bool, actual: bool) -> void:
	if expected == actual:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: %s (expected %s, got %s)" % [label, str(expected), str(actual)])
