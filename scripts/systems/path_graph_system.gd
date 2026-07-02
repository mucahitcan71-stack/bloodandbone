extends RefCounted
class_name PathGraphSystem

const PathSpline = preload("res://scripts/path_spline.gd")

# Faz 0 test: graf dugum/kenarlarini goster. Yayin oncesi false yap.
const PATH_DEBUG := true

const _YOL_SPLINE_ADIM := 10
const _MERGE_TOLERANS := 14.0

var _root: Node2D = null
var _world: WorldSystem = null
var _debug_katmani: Node2D = null

var _nodes: Array = []
var _edges: Array = []


func configure(root: Node2D, world: WorldSystem) -> void:
	_root = root
	_world = world


func rebuild() -> void:
	_nodes.clear()
	_edges.clear()
	if _world == null:
		_debug_temizle()
		return
	_graf_patikalardan_insaa()
	_graf_kavsaklardan_insaa()
	_graf_kale_kapilarina_bagla()
	if PATH_DEBUG:
		_debug_cizimi_guncelle()
	else:
		_debug_temizle()


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	# Faz 0–1: düz fallback — Faz 2'de A* buraya gelecek
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	sonuc.append(to)
	return sonuc


func path_to_control_point(from: Vector2, nokta_id: String) -> PackedVector2Array:
	var hedef := _en_yakin_kapi_konumu(nokta_id, from)
	if hedef == null:
		hedef = _world.get_point_center(nokta_id)
	return find_path(from, hedef)


func nearest_node_id(pos: Vector2) -> int:
	var en_yakin := -1
	var en_kisa := INF
	for i in range(_nodes.size()):
		var d := pos.distance_to(_nodes[i]["pos"])
		if d < en_kisa:
			en_kisa = d
			en_yakin = i
	return en_yakin


func get_node_count() -> int:
	return _nodes.size()


func get_edge_count() -> int:
	return _edges.size()


func _graf_patikalardan_insaa() -> void:
	for patika in _world.get_gorsel_patikalar():
		if typeof(patika) != TYPE_DICTIONARY:
			continue
		var pts: Array = patika.get("points", [])
		if pts.size() < 2:
			continue
		var kontrol: Array = []
		for raw in pts:
			if typeof(raw) == TYPE_VECTOR2:
				kontrol.append(raw)
		var yumusak := PathSpline.yumusat_catmull(kontrol, _YOL_SPLINE_ADIM)
		_polyline_graf_ekle(yumusak)


func _polyline_graf_ekle(pts: PackedVector2Array) -> void:
	if pts.size() < 2:
		return
	var onceki_id := -1
	for i in range(pts.size()):
		var nid := _patika_dugum_id(pts, i)
		if onceki_id >= 0:
			_kenar_ekle(onceki_id, nid)
		onceki_id = nid


func _patika_dugum_id(pts: PackedVector2Array, idx: int) -> int:
	var son := pts.size() - 1
	if idx == 0 or idx == son:
		var komsu_idx := 1 if idx == 0 else son - 1
		var nokta_id := _world.kontrol_nokta_yakin(pts[idx])
		if nokta_id != "":
			var kapi := _world.kale_kapi_konumu(nokta_id, pts[komsu_idx])
			return _node_ekle_veya_bul(kapi, "kapi", {"nokta_id": nokta_id})
	return _node_ekle_veya_bul(pts[idx], "patika")


func _graf_kale_kapilarina_bagla() -> void:
	for nokta_id in _world.get_kontrol_nokta_ids():
		var kapi_ids: Array = []
		for n in _nodes:
			if n["tip"] == "kapi" and str(n["meta"].get("nokta_id", "")) == str(nokta_id):
				kapi_ids.append(n["id"])
		if kapi_ids.size() < 2:
			continue
		for i in range(kapi_ids.size()):
			for j in range(i + 1, kapi_ids.size()):
				var a: int = kapi_ids[i]
				var b: int = kapi_ids[j]
				var pa: Vector2 = _nodes[a]["pos"]
				var pb: Vector2 = _nodes[b]["pos"]
				var merkez := _world.get_point_center(str(nokta_id))
				if pa.distance_to(merkez) > _world.get_kale_yol_yaricapi() * 1.35:
					continue
				if pb.distance_to(merkez) > _world.get_kale_yol_yaricapi() * 1.35:
					continue
				_kenar_ekle(a, b)


func _en_yakin_kapi_konumu(nokta_id: String, from: Vector2):
	var en_kisa := INF
	var sonuc = null
	for n in _nodes:
		if n["tip"] != "kapi":
			continue
		if str(n["meta"].get("nokta_id", "")) != str(nokta_id):
			continue
		var d := from.distance_to(n["pos"])
		if d < en_kisa:
			en_kisa = d
			sonuc = n["pos"]
	return sonuc


func _graf_kavsaklardan_insaa() -> void:
	for kid in _world.get_kavsak_konumlari():
		var pos: Vector2 = _world.get_kavsak_konumlari()[kid]
		_node_ekle_veya_bul(pos, "kavsak", {"kavsak_id": str(kid)})


func _node_ekle_veya_bul(pos: Vector2, tip: String, meta: Dictionary = {}) -> int:
	for i in range(_nodes.size()):
		if _nodes[i]["pos"].distance_to(pos) <= _MERGE_TOLERANS:
			return i
	var nid := _nodes.size()
	_nodes.append({"id": nid, "pos": pos, "tip": tip, "meta": meta})
	return nid


func _kenar_ekle(a: int, b: int) -> void:
	if a == b:
		return
	for e in _edges:
		if (e["a"] == a and e["b"] == b) or (e["a"] == b and e["b"] == a):
			return
	var pa: Vector2 = _nodes[a]["pos"]
	var pb: Vector2 = _nodes[b]["pos"]
	_edges.append({"a": a, "b": b, "mesafe": pa.distance_to(pb)})


func _debug_cizimi_guncelle() -> void:
	_debug_temizle()
	if _root == null or _world == null:
		return
	_debug_katmani = Node2D.new()
	_debug_katmani.name = "PathGraphDebug"
	_debug_katmani.z_index = 48
	_root.add_child(_debug_katmani)
	for e in _edges:
		var a: int = e["a"]
		var b: int = e["b"]
		var line := Line2D.new()
		line.points = PackedVector2Array([
			_world.logical_to_ekran(_nodes[a]["pos"]),
			_world.logical_to_ekran(_nodes[b]["pos"]),
		])
		line.width = 2.5
		line.default_color = Color(0.15, 0.75, 1.0, 0.5)
		line.antialiased = true
		_debug_katmani.add_child(line)
	for n in _nodes:
		var tip := str(n["tip"])
		var renk := Color(1.0, 0.88, 0.2, 0.85)
		if tip == "kavsak":
			renk = Color(0.2, 1.0, 0.95, 0.9)
		elif tip == "kapi":
			renk = Color(0.35, 1.0, 0.45, 0.95)
		var iso := _world.logical_to_ekran(n["pos"])
		var dot := ColorRect.new()
		dot.size = Vector2(7, 7)
		dot.position = iso - dot.size * 0.5
		dot.color = renk
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_debug_katmani.add_child(dot)


func _debug_temizle() -> void:
	if is_instance_valid(_debug_katmani):
		_debug_katmani.queue_free()
	_debug_katmani = null
