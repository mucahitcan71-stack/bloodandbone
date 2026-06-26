class_name IsoProjection
extends RefCounted

# 2:1 izometrik karo boyutu (Faz B'de gerçek karo boyutuna göre ayarlanacak)
# Şimdilik varsayılan değerler, A2'de netleşecek
const TILE_W: float = 128.0
const TILE_H: float = 64.0


# Mantıksal konum -> izometrik ekran konumu (çizim için)
# logical: oyun mantığının kullandığı düz koordinat (Vector2)
# döner: ekranda çizilecek izometrik konum (Vector2)
static func logical_to_iso(logical: Vector2) -> Vector2:
	# A2'de doldurulacak
	return logical  # şimdilik degisiklik yok (placeholder)


# İzometrik ekran konumu -> mantıksal konum (tıklama için)
# iso: ekrandaki izometrik konum (Vector2)
# döner: oyun mantığının kullanacağı düz konum (Vector2)
static func iso_to_logical(iso: Vector2) -> Vector2:
	# A2'de doldurulacak
	return iso  # şimdilik degisiklik yok (placeholder)
