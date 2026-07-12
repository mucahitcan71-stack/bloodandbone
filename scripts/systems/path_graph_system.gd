extends RefCounted
class_name PathGraphSystem

const PathSpline = preload("res://scripts/path_spline.gd")

# Ileride yol uzeri pusu noktalari: graf dugum tipi "pusu_noktasi" + yola_snap ayni kenar agi.
var PATH_DEBUG := false

const _YOL_SPLINE_ADIM := 10
const _MERGE_TOLERANS := 14.0
const _YOL_USTU_TOLERANS := 95.0
const _YOL_BILINCLI_TIK := 48.0
const _YOL_HIZ_TOLERANS := 36.0
const _YOL_TIKLAMA_TOLERANS := 220.0
const _YOLA_ULASIM_TOLERANS := 900.0
const _YAY_ADIM := 5

var _root: Node2D = null
var _world: WorldSystem = null
var _debug_katmani: Node2D = null

var _nodes: Array = []
var _edges: Array = []
var _adjacency: Array = []
var _edge_spatial: Dictionary = {}
const _SPATIAL_CELL := 256.0


func configure(root: Node2D, world: WorldSystem) -> void:
	_root = root
	_world = world


func rebuild() -> void:
	_nodes.clear()
	_edges.clear()
	_adjacency.clear()
	_edge_spatial.clear()
	if _world == null:
		_debug_temizle()
		return
	_graf_patikalardan_insaa()
	_graf_kavsaklardan_insaa()
	_graf_kale_kapi_yaylari_bagla()
	_adjacency_olustur()
	_spatial_olustur()
	if PATH_DEBUG:
		_debug_cizimi_guncelle()
	else:
		_debug_temizle()


func toggle_path_debug() -> bool:
	PATH_DEBUG = not PATH_DEBUG
	if PATH_DEBUG:
		_debug_cizimi_guncelle()
	else:
		_debug_temizle()
	return PATH_DEBUG


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _nodes.is_empty() or _adjacency.is_empty():
		return PackedVector2Array()
	var yakin_bit := _yola_en_yakin(to)
	if yakin_bit["mesafe"] > _YOL_TIKLAMA_TOLERANS:
		return PackedVector2Array()
	var bit: Vector2 = yakin_bit["pos"]
	var yakin_bas := _yola_en_yakin(from)
	if yakin_bas["mesafe"] > _YOLA_ULASIM_TOLERANS:
		return PackedVector2Array()
	var bas: Vector2 = yakin_bas["pos"]
	var baglanti := from.distance_to(bas) > _YOL_USTU_TOLERANS
	var start_nid := nearest_node_id(bas)
	var goal_nid := nearest_node_id(bit)
	if start_nid < 0 or goal_nid < 0:
		return PackedVector2Array()
	var v_start := _nodes.size()
	var v_goal := _nodes.size() + 1
	var start_link: float = bas.distance_to(_nodes[start_nid]["pos"])
	var goal_link: float = bit.distance_to(_nodes[goal_nid]["pos"])
	var adj := _adjacency_kopyala(v_goal + 1)
	_adj_kenar_ekle(adj, v_start, start_nid, start_link)
	_adj_kenar_ekle(adj, v_goal, goal_nid, goal_link)
	var node_path := _astar_sanal(adj, v_start, v_goal, bas, bit, v_start, v_goal, v_goal + 1)
	if node_path.is_empty():
		return PackedVector2Array()
	var yol := _sanal_yol_waypoints(bas, bit, node_path, v_start, v_goal)
	if not baglanti:
		return yol
	var tam := PackedVector2Array()
	tam.append(from)
	if from.distance_squared_to(bas) > 4.0:
		tam.append(bas)
	for i in range(yol.size()):
		var p: Vector2 = yol[i]
		if tam.size() > 0 and p.distance_squared_to(tam[tam.size() - 1]) <= 4.0:
			continue
		tam.append(p)
	return _waypoint_temizle(tam)


func plan_move(from: Vector2, to: Vector2, force_offroad: bool = false) -> PackedVector2Array:
	# Yol SADECE hedef yolun ustune tiklaninca. Aksi halde duz — yola asla sapma.
	if force_offroad:
		return _duz_yol(from, to)
	var hit_to := _yola_en_yakin(to)
	var hedef_yolda: bool = float(hit_to["mesafe"]) <= _YOL_BILINCLI_TIK
	if not hedef_yolda:
		return _duz_yol(from, to)
	var yol := find_path(from, to)
	if yol.size() >= 2:
		return yol
	yol = find_path(from, hit_to["pos"])
	if yol.size() >= 2:
		return yol
	return _duz_yol(from, hit_to["pos"])


func yola_yaklasim_yolu(from: Vector2) -> PackedVector2Array:
	var hit := _yola_en_yakin(from)
	if hit["mesafe"] > _YOLA_ULASIM_TOLERANS or hit["mesafe"] <= _YOL_USTU_TOLERANS:
		return PackedVector2Array()
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	sonuc.append(hit["pos"])
	return sonuc


func _duz_yol(from: Vector2, to: Vector2) -> PackedVector2Array:
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	sonuc.append(to)
	return sonuc


func yol_uzerinde_mi(pos: Vector2) -> bool:
	return _yola_en_yakin(pos)["mesafe"] <= _YOL_USTU_TOLERANS


func yol_hiz_avantaji_mi(pos: Vector2) -> bool:
	# Tam hiz sadece gercekten yol merkezine yakin olunca (graf kenarinda "sayilma" yok).
	return float(_yola_en_yakin(pos)["mesafe"]) <= _YOL_HIZ_TOLERANS


func yola_ulasimda_mi(pos: Vector2) -> bool:
	return _yola_en_yakin(pos)["mesafe"] <= _YOLA_ULASIM_TOLERANS


func yola_snap(pos: Vector2) -> Dictionary:
	var hit := _yola_en_yakin(pos)
	return {
		"ok": hit["mesafe"] <= _YOL_USTU_TOLERANS,
		"pos": hit["pos"],
		"mesafe": hit["mesafe"],
	}


func _yola_en_yakin(pos: Vector2) -> Dictionary:
	if _edges.is_empty():
		return {"pos": pos, "mesafe": INF}
	if _edge_spatial.is_empty():
		return _yola_en_yakin_tam(pos)
	var ck := _spatial_key(pos)
	var en_kisa := INF
	var en_iyi := pos
	# 900px ulasim toleransina yetecek halka (~4 hucre)
	var max_ring := 4
	for ring in range(max_ring + 1):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if ring > 0 and maxi(absi(dx), absi(dy)) != ring:
					continue
				var liste = _edge_spatial.get(Vector2i(ck.x + dx, ck.y + dy), null)
				if liste == null:
					continue
				for ei in liste:
					var e: Dictionary = _edges[ei]
					var pa: Vector2 = _nodes[e["a"]]["pos"]
					var pb: Vector2 = _nodes[e["b"]]["pos"]
					var hit := _segment_en_yakin(pa, pb, pos)
					if hit["dist"] < en_kisa:
						en_kisa = hit["dist"]
						en_iyi = hit["pos"]
	if en_kisa < INF:
		return {"pos": en_iyi, "mesafe": en_kisa}
	return _yola_en_yakin_tam(pos)


func _yola_en_yakin_tam(pos: Vector2) -> Dictionary:
	var en_kisa := INF
	var en_iyi := pos
	for e in _edges:
		var pa: Vector2 = _nodes[e["a"]]["pos"]
		var pb: Vector2 = _nodes[e["b"]]["pos"]
		var hit := _segment_en_yakin(pa, pb, pos)
		if hit["dist"] < en_kisa:
			en_kisa = hit["dist"]
			en_iyi = hit["pos"]
	return {"pos": en_iyi, "mesafe": en_kisa}


func _spatial_key(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / _SPATIAL_CELL)), int(floor(pos.y / _SPATIAL_CELL)))


func _spatial_olustur() -> void:
	_edge_spatial.clear()
	for i in range(_edges.size()):
		var e: Dictionary = _edges[i]
		var pa: Vector2 = _nodes[e["a"]]["pos"]
		var pb: Vector2 = _nodes[e["b"]]["pos"]
		var min_c := _spatial_key(Vector2(minf(pa.x, pb.x), minf(pa.y, pb.y)))
		var max_c := _spatial_key(Vector2(maxf(pa.x, pb.x), maxf(pa.y, pb.y)))
		for x in range(min_c.x, max_c.x + 1):
			for y in range(min_c.y, max_c.y + 1):
				var k := Vector2i(x, y)
				if not _edge_spatial.has(k):
					_edge_spatial[k] = []
				_edge_spatial[k].append(i)


func _segment_en_yakin(a: Vector2, b: Vector2, p: Vector2) -> Dictionary:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.01:
		return {"pos": a, "dist": p.distance_to(a)}
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var nokta := a + ab * t
	return {"pos": nokta, "dist": p.distance_to(nokta)}


func path_to_control_point(from: Vector2, nokta_id: String) -> PackedVector2Array:
	var hedef: Vector2 = _world.get_point_center(nokta_id)
	var kapi: Variant = _en_yakin_kapi_konumu(nokta_id, from)
	if kapi != null:
		hedef = kapi
	return plan_move(from, hedef)


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


func _kenar_ekle(a: int, b: int, maliyet: float = -1.0) -> void:
	if a == b:
		return
	for e in _edges:
		if (e["a"] == a and e["b"] == b) or (e["a"] == b and e["b"] == a):
			return
	var pa: Vector2 = _nodes[a]["pos"]
	var pb: Vector2 = _nodes[b]["pos"]
	var cost := maliyet if maliyet >= 0.0 else pa.distance_to(pb)
	_edges.append({"a": a, "b": b, "mesafe": cost})


func _graf_kale_kapi_yaylari_bagla() -> void:
	for nokta_id in _world.get_kontrol_nokta_ids():
		var kapilar: Array = []
		for n in _nodes:
			if n["tip"] == "kapi" and str(n["meta"].get("nokta_id", "")) == str(nokta_id):
				kapilar.append(n)
		if kapilar.size() < 2:
			continue
		var merkez: Vector2 = _world.get_kale_anchor(str(nokta_id))
		kapilar.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var aa: float = (a["pos"] - merkez).angle()
			var ab: float = (b["pos"] - merkez).angle()
			return aa < ab
		)
		for i in range(kapilar.size()):
			var ga: Dictionary = kapilar[i]
			var gb: Dictionary = kapilar[(i + 1) % kapilar.size()]
			_kapi_yay_kenarlari(int(ga["id"]), int(gb["id"]), merkez)


func _kapi_yay_kenarlari(a_id: int, b_id: int, merkez: Vector2) -> void:
	var pa: Vector2 = _nodes[a_id]["pos"]
	var pb: Vector2 = _nodes[b_id]["pos"]
	var ang_a: float = (pa - merkez).angle()
	var ang_b: float = (pb - merkez).angle()
	var d_ang: float = posmod(ang_b - ang_a + TAU, TAU)
	if d_ang < 0.05:
		return
	var yaricap: float = pa.distance_to(merkez)
	var prev := a_id
	for step in range(1, _YAY_ADIM):
		var t: float = float(step) / float(_YAY_ADIM)
		var ang: float = ang_a + d_ang * t
		var pos := merkez + Vector2(cos(ang), sin(ang)) * yaricap
		var nid := _node_ekle_veya_bul(pos, "patika", {"kale_yay": true})
		var seg_cost: float = _nodes[prev]["pos"].distance_to(pos)
		_kenar_ekle(prev, nid, seg_cost)
		prev = nid
	var son_cost: float = _nodes[prev]["pos"].distance_to(pb)
	_kenar_ekle(prev, b_id, son_cost)


func _adjacency_kopyala(boyut: int) -> Array:
	var adj: Array = []
	adj.resize(boyut)
	for i in range(boyut):
		adj[i] = []
	for i in range(_adjacency.size()):
		for nb in _adjacency[i]:
			adj[i].append(nb.duplicate())
	return adj


func _adj_kenar_ekle(adj: Array, a: int, b: int, cost: float) -> void:
	adj[a].append({"n": b, "c": cost})
	adj[b].append({"n": a, "c": cost})


func _astar_sanal(adj: Array, start: int, goal: int, from_pos: Vector2, to_pos: Vector2, v_start: int, v_goal: int, node_count: int) -> PackedInt32Array:
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _heuristic_sanal(start, goal, from_pos, to_pos, v_start, v_goal)}
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
		if current >= adj.size():
			continue
		for nb in adj[current]:
			var komsu: int = nb["n"]
			if komsu >= node_count:
				continue
			var tentative: float = g_score.get(current, INF) + float(nb["c"])
			if tentative < g_score.get(komsu, INF):
				came_from[komsu] = current
				g_score[komsu] = tentative
				f_score[komsu] = tentative + _heuristic_sanal(komsu, goal, from_pos, to_pos, v_start, v_goal)
				if not open_set.has(komsu):
					open_set.append(komsu)
	return PackedInt32Array()


func _heuristic_sanal(a: int, b: int, from_pos: Vector2, to_pos: Vector2, v_start: int, v_goal: int) -> float:
	return _sanal_node_pos(a, from_pos, to_pos, v_start, v_goal).distance_to(_sanal_node_pos(b, from_pos, to_pos, v_start, v_goal))


func _sanal_node_pos(nid: int, from_pos: Vector2, to_pos: Vector2, v_start: int, v_goal: int) -> Vector2:
	if nid == v_start:
		return from_pos
	if nid == v_goal:
		return to_pos
	return _nodes[nid]["pos"]


func _sanal_yol_waypoints(from: Vector2, to: Vector2, node_ids: PackedInt32Array, v_start: int, v_goal: int) -> PackedVector2Array:
	var sonuc := PackedVector2Array()
	sonuc.append(from)
	for i in range(node_ids.size()):
		var nid := int(node_ids[i])
		if nid == v_start or nid == v_goal:
			continue
		if nid < _nodes.size():
			sonuc.append(_nodes[nid]["pos"])
	sonuc.append(to)
	return _waypoint_temizle(sonuc)


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
