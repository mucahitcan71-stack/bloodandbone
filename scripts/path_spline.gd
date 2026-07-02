class_name PathSpline
extends RefCounted

static func yumusat_catmull(noktalar: Array, adim: int = 10) -> PackedVector2Array:
	var pts: Array = []
	for p in noktalar:
		if p is Vector2:
			pts.append(p)
	var n := pts.size()
	if n < 2:
		var out := PackedVector2Array()
		for p in pts:
			out.append(p)
		return out
	adim = maxi(adim, 2)
	var result := PackedVector2Array()
	for i in range(n - 1):
		var p0: Vector2 = pts[i - 1] if i > 0 else pts[0]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[i + 2] if i + 2 < n else pts[n - 1]
		var j_start := 1 if i > 0 else 0
		for j in range(j_start, adim + 1):
			var t := float(j) / float(adim)
			result.append(_catmull_rom(p0, p1, p2, p3, t))
	return result

static func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
