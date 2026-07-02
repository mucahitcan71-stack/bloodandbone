extends RefCounted
class_name PathGraphSystem

const PathSpline = preload("res://scripts/path_spline.gd")

# Faz 0 test: graf dugum/kenarlarini goster. Yayin oncesi false yap.
const PATH_DEBUG := true

const _YOL_SPLINE_ADIM := 10
const _MERGE_TOLERANS := 14.0
const _SNAP_TOLERANS := 120.0

var _root: Node2D = null
var _world: WorldSystem = null
var _debug_katmani: Node2D = null

var _nodes: Array = []
var _edges: Array = []
var _adjacency: Array = []


func configure(root: Node2D, world: WorldSystem) -> void:
	_root = root
	_world = world


func rebuild() -> void:
	_nodes.clear()
	_edges.clear()
	_adjacency.clear()
	if _world == null:
		_debug_temizle()
		return
	_graf_patikalardan_insaa()
	_graf_kavsaklardan_insaa()
	_adjacency_olustur()
	if PATH_DEBUG:
		_debug_cizimi_guncelle()
	else:
		_debug_temizle()


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _nodes.is_empty() or _adjacency.is_empty():
		return _duz_yol(from, to)
	var start_nid := nearest_node_id(from)
	var goal_nid := nearest_node_id(to)
	if start_nid < 0 or goal_nid < 0:
		return _duz_yol(from, to)
	if from.distance_to(_nodes[start_nid]["pos"]) > _SNAP_TOLERANS:
		return _duz_yol(from, to)
	if to.distance_to(_nodes[goal_nid]["pos"]) > _SNAP_TOLERANS:
		return _duz_yol(from, to)
	if start_nid == goal_nid:
		return _duz_yol(from, to)
	var node_path := _astar(start_nid, goal_nid)
	if node_path.is_empty():
		return _duz_yol(from, to)
	return _node_yolundan_waypoints(from, to, node_path)


func path_to_control_point(from: Vector2, nokta_id: String) -> PackedVector2Array:
	var hedef: Vector2 = _world.get_point_center(nokta_id)
	var kapi: Variant = _en_yakin_kapi_konumu(nokta_id, from)
	if kapi != null:
		hedef = kapi
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
		for parca in _world.polyline_kale_kes(yumusak):
			var segment: PackedVector2Array = parca
			if segment.size() >= 2:
				_polyline_graf_ekle(segment)


func _polyline_graf_ekle(pts: PackedVector2Array) -> void:
	if pts.size() < 2:
		return
	var onceki_id := -1
	for i in range(pts.size()):
		var nid := _patika_dugum_id(pts, i)
		if nid < 0:
			onceki_id = -1
			continue
		if onceki_id >= 0:
			_kenar_ekle(onceki_id, nid)
		onceki_id = nid


func _patika_dugum_id(pts: PackedVector2Array, idx: int) -> int:
	var son := pts.size() - 1
	if idx == 0 or idx == son:
		var komsu_idx := 1 if idx == 0 else son - 1
		var nokta_id := _world.kontrol_nokta_yakin(pts[idx])
		if nokta_id == "":
			nokta_id = _world.kontrol_nokta_kale_bolgesinde(pts[idx])
		if nokta_id != "":
			var kapi := _world.kale_kapi_konumu(nokta_id, pts[komsu_idx])
			return _node_ekle_veya_bul(kapi, "kapi", {"nokta_id": nokta_id})
	if _world.kontrol_nokta_kale_bolgesinde(pts[idx]) != "":
		return -1
	return _node_ekle_veya_bul(pts[idx], "patika")


func _en_yakin_kapi_konumu(nokta_id: String, from: Vector2) -> Variant:
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


func _adjacency_olustur() -> void:
	_adjacency.clear()
	_adjacency.resize(_nodes.size())
	for i in range(_nodes.size()):
		_adjacency[i] = []
	for e in _edges:
		var a: int = e["a"]
		var b: int = e["b"]
		var cost: float = e["mesafe"]
		_adjacency[a].append({"n": b, "c": cost})
		_adjacency[b].append({"n": a, "c": cost})


func _duz_yol(from: Vector2, to: Vector2) -> PackedVector2Array:
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	sonuc.append(to)
	return sonuc


func _astar(start: int, goal: int) -> PackedInt32Array:
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}
	var came_from: Dictionary = {}
	var open_set: Array = [start]
	while not open_set.is_empty():
		var best_idx := 0
		var current: int = open_set[0]
		var best_f: float = f_score.get(current, INF)
		for i in range(1, open_set.size()):
			var nid: int = open_set[i]
			var f: float = f_score.get(nid, INF)
			if f < best_f:
				best_f = f
				current = nid
				best_idx = i
		open_set.remove_at(best_idx)
		if current == goal:
			return _reconstruct_path(came_from, current)
		for nb in _adjacency[current]:
			var komsu: int = nb["n"]
			var tentative: float = g_score.get(current, INF) + float(nb["c"])
			if tentative < g_score.get(komsu, INF):
				came_from[komsu] = current
				g_score[komsu] = tentative
				f_score[komsu] = tentative + _heuristic(komsu, goal)
				if not open_set.has(komsu):
					open_set.append(komsu)
	return PackedInt32Array()


func _heuristic(a: int, b: int) -> float:
	return _nodes[a]["pos"].distance_to(_nodes[b]["pos"])


func _reconstruct_path(came_from: Dictionary, current: int) -> PackedInt32Array:
	var yol: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		yol.push_front(current)
	var sonuc := PackedInt32Array()
	for nid in yol:
		sonuc.append(int(nid))
	return sonuc


func _node_yolundan_waypoints(from: Vector2, to: Vector2, node_ids: PackedInt32Array) -> PackedVector2Array:
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	for i in range(node_ids.size()):
		sonuc.append(_nodes[node_ids[i]]["pos"])
	sonuc.append(to)
	return _waypoint_temizle(sonuc)


func _waypoint_temizle(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var sonuc := PackedVector2Array()
	sonuc.append(pts[0])
	for i in range(1, pts.size()):
		if pts[i].distance_squared_to(sonuc[sonuc.size() - 1]) > 4.0:
			sonuc.append(pts[i])
	return sonuc


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
