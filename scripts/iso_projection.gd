class_name IsoProjection
extends RefCounted

# 2:1 izometrik karo boyutu (Faz B'de gerçek karoya göre ayarlanacak)
const TILE_W: float = 128.0
const TILE_H: float = 64.0


# Mantıksal konum -> izometrik ekran konumu (çizim için)
# Mantıksal koordinat: grid birimi cinsinden düz konum.
# x-y farkı yatayı, x+y toplamı dikeyi belirler (klasik 2:1 iso).
static func logical_to_iso(logical: Vector2) -> Vector2:
	var iso_x = (logical.x - logical.y) * (TILE_W / 2.0)
	var iso_y = (logical.x + logical.y) * (TILE_H / 2.0)
	return Vector2(iso_x, iso_y)


# İzometrik ekran konumu -> mantıksal konum (tıklama için)
# logical_to_iso'nun cebirsel tersi; round-trip aynı değeri vermeli.
static func iso_to_logical(iso: Vector2) -> Vector2:
	var logical_x = (iso.x / (TILE_W / 2.0) + iso.y / (TILE_H / 2.0)) / 2.0
	var logical_y = (iso.y / (TILE_H / 2.0) - iso.x / (TILE_W / 2.0)) / 2.0
	return Vector2(logical_x, logical_y)
