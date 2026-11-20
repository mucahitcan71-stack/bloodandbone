extends RefCounted
class_name FogLineOfSight

## Independent sight-line prototype. Not integrated into the main FogSystem.
## All coordinates are logical map coordinates, not isometric screen positions.
## terrain_height must be a Callable(Vector2) returning map height in units
## consistent with eye_height and target_height.
## Each wall is a PackedVector2Array containing two endpoints.
## Walls are opaque and infinitely high in this initial experiment.

static func can_see(
	origin: Vector2,
	target: Vector2,
	terrain_height: Callable,
	wall_segments: Array[PackedVector2Array],
	eye_height: float = 1.7,
	target_height: float = 1.7,
	step_size: float = 8.0
) -> bool:
	if not terrain_height.is_valid() or step_size <= 0.0:
		return false

	var distance: float = origin.distance_to(target)
	if distance <= 0.001:
		return true

	# First exclude opaque wall segments in logical map space.
	for segment in wall_segments:
		if segment.size() != 2:
			continue
		if Geometry2D.segment_intersects_segment(origin, target, segment[0], segment[1]) != null:
			return false

	var start_z: float = float(terrain_height.call(origin)) + eye_height
	var end_z: float = float(terrain_height.call(target)) + target_height
	var count: int = maxi(2, int(ceil(distance / step_size)))
	for index in range(1, count):
		var t: float = float(index) / float(count)
		var point: Vector2 = origin.lerp(target, t)
		var ray_height: float = lerpf(start_z, end_z, t)
		if float(terrain_height.call(point)) > ray_height:
			return false

	return true
