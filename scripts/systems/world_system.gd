extends RefCounted
class_name WorldSystem

const GameData = preload("res://scripts/systems/game_data.gd")

var _root: Node2D = null
var _on_map_applied: Callable
var _on_map_visuals_extra: Callable

var aktif_harita_id = "trakya"
var harita_sinir = {"min_x": 20.0, "max_x": 980.0, "min_y": 80.0, "max_y": 440.0}
var nokta_konumlari = {}
var nokta_puan = {}
var nokta_altin = {}
var arazi_bolgeleri: Array = []
var orman_bolgeleri: Array = []
var arazi_katmani: Node2D = null
var kamera: Camera2D = null

func configure(root: Node2D) -> void:
	_root = root

func set_on_map_applied(callback: Callable) -> void:
	_on_map_applied = callback

func set_on_map_visuals_extra(callback: Callable) -> void:
	_on_map_visuals_extra = callback

func get_active_map_id() -> String:
	return aktif_harita_id

func get_map_bounds() -> Dictionary:
	return harita_sinir

func get_point_positions() -> Dictionary:
	return nokta_konumlari

func get_point_scores() -> Dictionary:
	return nokta_puan

func get_point_gold_values() -> Dictionary:
	return nokta_altin

func get_terrain_regions() -> Array:
	return arazi_bolgeleri

func get_forest_regions() -> Array:
	return orman_bolgeleri

func get_camera() -> Camera2D:
	return kamera

func get_arazi_katmani() -> Node2D:
	return arazi_katmani

func get_point_center(nokta: String) -> Vector2:
	return nokta_konumlari[nokta] + Vector2(40, 40)

func harita_uygula(map_id: String) -> void:
	var map_data = GameData.load_map(map_id)
	if map_data.is_empty():
		push_warning("Harita yuklenemedi: " + map_id)
		return
	aktif_harita_id = map_id
	nokta_konumlari = map_data["nokta_konumlari"].duplicate()
	nokta_puan = map_data["nokta_puan"].duplicate()
	nokta_altin = map_data["nokta_altin"].duplicate()
	harita_sinir = map_data["sinir"].duplicate()
	arazi_bolgeleri = map_data.get("arazi_bolgeleri", []).duplicate(true)
	orman_bolgeleri = []
	for bolge in arazi_bolgeleri:
		if str(bolge.get("tip", "")) == "orman":
			orman_bolgeleri.append(bolge)
	harita_gorsellerini_guncelle()
	kamera_limitlerini_guncelle()
	if _on_map_applied.is_valid():
		_on_map_applied.call()

func kamera_hazirla() -> void:
	if _root == null:
		return
	kamera = _root.get_node_or_null("Camera2D")
	if kamera == null:
		kamera = Camera2D.new()
		kamera.name = "Camera2D"
		_root.add_child(kamera)
	kamera.enabled = true
	kamera.position = Vector2(576, 324)
	kamera.zoom = Vector2(1, 1)

func kamera_limitlerini_guncelle() -> void:
	if kamera == null:
		return
	kamera.limit_left = int(harita_sinir["min_x"])
	kamera.limit_right = int(harita_sinir["max_x"])
	kamera.limit_top = int(harita_sinir["min_y"])
	kamera.limit_bottom = int(harita_sinir["max_y"])
	kamera_sinirla()

func kamera_sinirla() -> void:
	if kamera == null:
		return
	kamera.position.x = clamp(kamera.position.x, harita_sinir["min_x"], harita_sinir["max_x"])
	kamera.position.y = clamp(kamera.position.y, harita_sinir["min_y"], harita_sinir["max_y"])

func arazi_katmani_olustur() -> void:
	if _root == null or is_instance_valid(arazi_katmani):
		return
	arazi_katmani = Node2D.new()
	arazi_katmani.name = "AraziLayer"
	_root.add_child(arazi_katmani)
	_root.move_child(arazi_katmani, 0)
	arazi_gorsellerini_guncelle()

func birimin_arazisini_bul(konum: Vector2) -> Dictionary:
	for nokta in nokta_konumlari:
		if konum.distance_to(get_point_center(nokta)) <= 85.0:
			return {"tip": "duz_arazi"}
	for bolge in arazi_bolgeleri:
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.has_point(konum):
			return bolge
	return {"tip": "duz_arazi"}

func orman_bolge_index(pos: Vector2) -> int:
	for i in range(arazi_bolgeleri.size()):
		var bolge = arazi_bolgeleri[i]
		if str(bolge.get("tip", "")) != "orman":
			continue
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.has_point(pos):
			return i
	return -1

func harita_gorsellerini_guncelle() -> void:
	if _root == null:
		return
	arazi_gorsellerini_guncelle()
	for nokta in nokta_konumlari:
		var pos = nokta_konumlari[nokta]
		if _root.has_node("Nokta_" + nokta):
			_root.get_node("Nokta_" + nokta).position = pos
		if _root.has_node("Label_Nokta_" + nokta):
			_root.get_node("Label_Nokta_" + nokta).position = pos + Vector2(30, 30)
		if _root.has_node("Label_Puan_" + nokta):
			_root.get_node("Label_Puan_" + nokta).position = pos + Vector2(30, -20)
			_root.get_node("Label_Puan_" + nokta).text = "+" + str(nokta_puan.get(nokta, 1))
		if _root.has_node("CaptureBg_" + nokta):
			_root.get_node("CaptureBg_" + nokta).position = pos + Vector2(0, 85)
	if _on_map_visuals_extra.is_valid():
		_on_map_visuals_extra.call()

func arazi_gorsellerini_guncelle() -> void:
	if not is_instance_valid(arazi_katmani):
		return
	for c in arazi_katmani.get_children():
		c.queue_free()
	var sinir = harita_sinir
	var taban = ColorRect.new()
	taban.name = "AraziTaban"
	taban.position = Vector2(sinir["min_x"], sinir["min_y"])
	taban.size = Vector2(sinir["max_x"] - sinir["min_x"], sinir["max_y"] - sinir["min_y"])
	taban.color = Color(0.2, 0.26, 0.16, 1.0)
	taban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	taban.z_index = -2
	arazi_katmani.add_child(taban)
	for bolge in arazi_bolgeleri:
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var alan = ColorRect.new()
		alan.position = rect.position
		alan.size = rect.size
		alan.color = _arazi_renk(str(bolge.get("tip", "duz_arazi")))
		alan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alan.z_index = -1
		arazi_katmani.add_child(alan)

func _arazi_renk(tip: String) -> Color:
	if tip == "tepe":
		return Color(0.48, 0.34, 0.2, 0.72)
	if tip == "orman":
		return Color(0.1, 0.32, 0.14, 0.78)
	if tip == "dar_gecit":
		return Color(0.28, 0.28, 0.3, 0.75)
	if tip == "vadi":
		return Color(0.38, 0.58, 0.28, 0.7)
	if tip == "yol":
		return Color(0.62, 0.54, 0.32, 0.75)
	if tip == "kopru":
		return Color(0.42, 0.42, 0.46, 0.78)
	return Color(0, 0, 0, 0)
