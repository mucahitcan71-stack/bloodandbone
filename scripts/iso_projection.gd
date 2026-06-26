class_name IsoProjection
extends RefCounted

# Piksel uzayı 2:1 izometrik. Ölçek 1.0 = orijinal piksel ölçeği korunur.
# Y ekseni yarıya iner (2:1 izometrik), böylece aşırı büyüme olmaz.
const SCALE: float = 1.0


static func logical_to_iso(logical: Vector2) -> Vector2:
	var iso_x = (logical.x - logical.y) * 0.5 * SCALE
	var iso_y = (logical.x + logical.y) * 0.25 * SCALE
	return Vector2(iso_x, iso_y)


static func iso_to_logical(iso: Vector2) -> Vector2:
	var a = iso.x / (0.5 * SCALE)
	var b = iso.y / (0.25 * SCALE)
	var logical_x = (a + b) / 2.0
	var logical_y = (b - a) / 2.0
	return Vector2(logical_x, logical_y)
