extends RefCounted
class_name FogSystem

var _root: Node2D = null
var _world: WorldSystem = null

var gorus_hucre_boyutu = 40.0
var gorus_hucreleri = {}
var gorus_hucre_katmani: Control = null
var kesfedilen_alanlar = {}
var su_anki_gorus_alani = {}
var ai_su_anki_gorus_alani = {}
var kesfedilen_noktalar = {}
var kesif_tespit_esigi = 135.0
var kontrol_noktasi_gorus_yaricapi = 100.0
var normal_birim_gorus_bonus = 30.0
var hayalet_ikon_suresi = 4.0
var dusman_son_gorulen_konum = {}
var dusman_hayalet_ikonlari = {}
var _minimap_fow_gorseli: Image = null
var _minimap_fow_doku: ImageTexture = null
# Gecici: tum haritayi gostermek icin true (sonra false yap)
var harita_sis_kapali := true

const FOG_GORUNUR = Color(0, 0, 0, 0.0)
const FOG_KAPALI = Color(0.06, 0.08, 0.11, 0.93)

func configure(root_node: Node2D, world_system: WorldSystem) -> void:
	_root = root_node
	_world = world_system

func get_fog_layer() -> Control:
	return gorus_hucre_katmani

func get_cell_size() -> float:
	return gorus_hucre_boyutu

func get_discovered_cells() -> Dictionary:
	return kesfedilen_alanlar

func get_current_vision(faction: String) -> Dictionary:
	if faction == "dogu_roma":
		return ai_su_anki_gorus_alani
	return su_anki_gorus_alani

func get_discovered_points() -> Dictionary:
	return kesfedilen_noktalar

func is_point_discovered(point_id: String) -> bool:
	if harita_sis_kapali:
		return true
	return kesfedilen_noktalar.get(point_id, false)

func is_world_pos_discovered(pos: Vector2, faction: String = "osmanli") -> bool:
	if harita_sis_kapali:
		return true
	var gorus = get_current_vision(faction)
	return _goruste_mi(pos, gorus) or kesfedilen_alanlar.get(_hucre_anahtari(pos), false)

func get_last_known_enemy_positions() -> Dictionary:
	return dusman_son_gorulen_konum

func update_enemy_intel(units: Array) -> void:
	var simdi = Time.get_unix_time_from_system()
	for birim in units:
		if not is_instance_valid(birim.get("node")):
			continue
		if birim["taraf"] == "osmanli":
			continue
		var gorunur = is_unit_visible_to_player(birim, units)
		var id = int(birim.get("id", -1))
		if gorunur:
			if id >= 0:
				dusman_son_gorulen_konum[id] = {
					"konum": birim["konum"],
					"zaman": simdi + hayalet_ikon_suresi
				}
		elif id >= 0 and not dusman_son_gorulen_konum.has(id):
			_clear_ghost_icon(id)
	_update_ghost_icons()

func remove_enemy_intel(unit_id: int) -> void:
	dusman_son_gorulen_konum.erase(unit_id)
	_clear_ghost_icon(unit_id)

func clear_ghost_icon(unit_id: int) -> void:
	_clear_ghost_icon(unit_id)

func reset_enemy_intel() -> void:
	dusman_son_gorulen_konum.clear()
	for hayalet in dusman_hayalet_ikonlari.values():
		if is_instance_valid(hayalet):
			hayalet.queue_free()
	dusman_hayalet_ikonlari.clear()

func reset_match_discovery(point_ids: Array) -> void:
	kesfedilen_noktalar.clear()
	for nokta in point_ids:
		kesfedilen_noktalar[nokta] = false

func set_layer_visible(visible: bool) -> void:
	if is_instance_valid(gorus_hucre_katmani):
		gorus_hucre_katmani.visible = visible and not harita_sis_kapali

func reset_fog_on_map_change() -> void:
	if is_instance_valid(gorus_hucre_katmani):
		reset_fog_grid()

func unit_vision_radius(unit_type: Dictionary) -> float:
	if unit_type.has("gorus_yaricapi"):
		return float(unit_type["gorus_yaricapi"])
	return float(unit_type.get("menzil", 80.0)) + normal_birim_gorus_bonus

func update_point_visibility() -> void:
	if harita_sis_kapali:
		_tum_noktalari_goster()
		return
	for nokta in _root.nokta_konumlari:
		var kesfedildi = is_point_discovered(nokta)
		var kare = _root.map_gorsel_node("Nokta_" + nokta)
		var isim_l = _root.map_gorsel_node("Label_Nokta_" + nokta)
		var puan_l = _root.map_gorsel_node("Label_Puan_" + nokta)
		var bg = _root.map_gorsel_node("CaptureBg_" + nokta)
		var bar = _root.capture_barlar.get(nokta, null)
		if not kesfedildi:
			if kare: kare.visible = false
			if isim_l: isim_l.visible = false
			if puan_l: puan_l.visible = false
			if bg: bg.visible = false
			if bar: bar.visible = false
			continue

		if kare: kare.visible = true
		if isim_l: isim_l.visible = true
		if puan_l:
			puan_l.visible = true
			puan_l.modulate = Color(1, 1, 1, 1)
		_root.nokta_son_bilgi[nokta] = {
			"sahip": _root.nokta_sahipleri[nokta],
			"capture": _root.nokta_capture[nokta]
		}
		if kare:
			kare.color = _point_owner_color(_root.nokta_sahipleri[nokta])
			kare.modulate = Color(1, 1, 1, 1)
		if bg: bg.visible = true
		if bar:
			bar.visible = true
			bar.size.x = 80.0 * (_root.nokta_capture[nokta] / 100.0)
			bar.color = Color(1, 0.8, 0)

func update_unit_visibility() -> void:
	if harita_sis_kapali:
		for birim in _root.aktif_birimler:
			if is_instance_valid(birim.get("node")):
				birim["node"].visible = true
		update_enemy_intel(_root.aktif_birimler)
		return
	for birim in _root.aktif_birimler:
		if not is_instance_valid(birim["node"]):
			continue
		birim["node"].visible = is_unit_visible_to_player(birim, _root.aktif_birimler)
	update_enemy_intel(_root.aktif_birimler)

func tick_battle_fog() -> void:
	update_vision(_root.aktif_birimler, _root.nokta_sahipleri)
	update_point_visibility()
	update_unit_visibility()

func _point_owner_color(taraf: String) -> Color:
	if taraf == "osmanli":
		return Color.GOLD
	if taraf == "dogu_roma":
		return Color.PURPLE
	return Color.GRAY

func refresh_ghost_icons() -> void:
	_update_ghost_icons()

func get_minimap_fow_image() -> Image:
	return _minimap_fow_gorseli

func get_minimap_fow_texture() -> ImageTexture:
	return _minimap_fow_doku

func update_minimap_fow() -> void:
	var harita_sinir = _world.get_map_bounds()
	var min_h = _hucre_anahtari(Vector2(harita_sinir["min_x"], harita_sinir["min_y"]))
	var max_h = _hucre_anahtari(Vector2(harita_sinir["max_x"], harita_sinir["max_y"]))
	var w = maxi(1, max_h.x - min_h.x + 1)
	var h = maxi(1, max_h.y - min_h.y + 1)
	if _minimap_fow_gorseli == null or _minimap_fow_gorseli.get_width() != w or _minimap_fow_gorseli.get_height() != h:
		_minimap_fow_gorseli = Image.create(w, h, false, Image.FORMAT_RGBA8)
		_minimap_fow_doku = ImageTexture.create_from_image(_minimap_fow_gorseli)
	for x in range(w):
		for y in range(h):
			var anahtar = Vector2i(min_h.x + x, min_h.y + y)
			var col = FOG_GORUNUR if harita_sis_kapali else FOG_KAPALI
			if not harita_sis_kapali:
				if su_anki_gorus_alani.get(anahtar, false):
					col = FOG_GORUNUR
				elif kesfedilen_alanlar.get(anahtar, false):
					col = FOG_GORUNUR
			_minimap_fow_gorseli.set_pixel(x, y, col)
	if _minimap_fow_doku == null:
		_minimap_fow_doku = ImageTexture.create_from_image(_minimap_fow_gorseli)
	else:
		_minimap_fow_doku.update(_minimap_fow_gorseli)

func is_scout_unit(unit: Dictionary) -> bool:
	return float(unit.get("gorus_yaricapi", 0.0)) >= kesif_tespit_esigi

func is_forest_stealth_broken(target: Dictionary, observer_faction: String, units: Array) -> bool:
	var bolge_idx = _world.orman_bolge_index(target["konum"])
	if bolge_idx < 0:
		return true
	var tespit_mesafesi = maxf(30.0, gorus_hucre_boyutu * 0.7)
	for b in units:
		if b["hp"] <= 0 or b["taraf"] != observer_faction:
			continue
		if not is_scout_unit(b):
			continue
		if _world.orman_bolge_index(b["konum"]) == bolge_idx and b["konum"].distance_to(target["konum"]) <= tespit_mesafesi:
			return true
	return false

func is_unit_visible_to_faction(target: Dictionary, observer_faction: String, units: Array) -> bool:
	if harita_sis_kapali and observer_faction == "osmanli":
		return target["hp"] > 0
	if target["taraf"] == observer_faction:
		return true
	if target["hp"] <= 0:
		return false
	if target.get("pusu_modunda", false):
		return false
	if target.get("pusu_arazi_gizli", false) and not is_forest_stealth_broken(target, observer_faction, units):
		return false
	return _goruste_mi(target["konum"], get_current_vision(observer_faction))

func is_unit_visible_to_player(unit: Dictionary, units: Array) -> bool:
	return is_unit_visible_to_faction(unit, "osmanli", units)

func update_vision(units: Array, point_owners: Dictionary) -> void:
	su_anki_gorus_alani.clear()
	ai_su_anki_gorus_alani.clear()
	for birim in units:
		if birim["hp"] <= 0:
			continue
		_gorus_ekle(
			su_anki_gorus_alani if birim["taraf"] == "osmanli" else ai_su_anki_gorus_alani,
			birim["konum"],
			float(birim.get("gorus_yaricapi", 110.0))
		)

	for nokta in point_owners:
		var merkez = _world.get_point_center(nokta)
		if point_owners[nokta] == "osmanli":
			_gorus_ekle(su_anki_gorus_alani, merkez, kontrol_noktasi_gorus_yaricapi)
		elif point_owners[nokta] == "dogu_roma":
			_gorus_ekle(ai_su_anki_gorus_alani, merkez, kontrol_noktasi_gorus_yaricapi)

	for anahtar in su_anki_gorus_alani:
		kesfedilen_alanlar[anahtar] = true

	var nokta_konumlari = _world.get_point_positions()
	for nokta in nokta_konumlari:
		if kesfedilen_noktalar.get(nokta, false):
			continue
		var merkez = _world.get_point_center(nokta)
		for birim in units:
			if birim["hp"] <= 0:
				continue
			if birim["konum"].distance_to(merkez) <= kontrol_noktasi_gorus_yaricapi:
				kesfedilen_noktalar[nokta] = true
				break

	_apply_main_map_overlay()

func create_fog_layer() -> void:
	if is_instance_valid(gorus_hucre_katmani):
		return
	gorus_hucre_katmani = Control.new()
	gorus_hucre_katmani.name = "FogLayer"
	gorus_hucre_katmani.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gorus_hucre_katmani.z_index = 40
	_root.add_child(gorus_hucre_katmani)
	reset_fog_grid()

func reset_fog_grid() -> void:
	if not is_instance_valid(gorus_hucre_katmani):
		return
	kesfedilen_alanlar.clear()
	su_anki_gorus_alani.clear()
	ai_su_anki_gorus_alani.clear()
	gorus_hucreleri.clear()
	for c in gorus_hucre_katmani.get_children():
		c.queue_free()
	var harita_sinir = _world.get_map_bounds()
	var min_h = _hucre_anahtari(Vector2(harita_sinir["min_x"], harita_sinir["min_y"]))
	var max_h = _hucre_anahtari(Vector2(harita_sinir["max_x"], harita_sinir["max_y"]))
	for x in range(min_h.x, max_h.x + 1):
		for y in range(min_h.y, max_h.y + 1):
			var hucre = ColorRect.new()
			hucre.size = Vector2(gorus_hucre_boyutu, gorus_hucre_boyutu)
			hucre.position = Vector2(float(x) * gorus_hucre_boyutu, float(y) * gorus_hucre_boyutu)
			hucre.color = FOG_KAPALI
			hucre.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hucre.visible = true
			gorus_hucre_katmani.add_child(hucre)
			gorus_hucreleri[Vector2i(x, y)] = hucre

func _hucre_anahtari(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / gorus_hucre_boyutu)),
		int(floor(pos.y / gorus_hucre_boyutu))
	)

func _hucre_merkezi(anahtar: Vector2i) -> Vector2:
	return Vector2(
		(float(anahtar.x) + 0.5) * gorus_hucre_boyutu,
		(float(anahtar.y) + 0.5) * gorus_hucre_boyutu
	)

func _goruste_mi(pos: Vector2, gorus_alani: Dictionary) -> bool:
	return gorus_alani.get(_hucre_anahtari(pos), false)

func _gorus_ekle(gorus_alani: Dictionary, merkez: Vector2, yaricap: float) -> void:
	var min_h = _hucre_anahtari(merkez - Vector2(yaricap, yaricap))
	var max_h = _hucre_anahtari(merkez + Vector2(yaricap, yaricap))
	for x in range(min_h.x, max_h.x + 1):
		for y in range(min_h.y, max_h.y + 1):
			var anahtar = Vector2i(x, y)
			if _hucre_merkezi(anahtar).distance_to(merkez) <= yaricap:
				gorus_alani[anahtar] = true

func _apply_main_map_overlay() -> void:
	if harita_sis_kapali:
		for anahtar in gorus_hucreleri:
			var hucre = gorus_hucreleri[anahtar]
			if is_instance_valid(hucre):
				hucre.color = FOG_GORUNUR
		set_layer_visible(false)
		return
	for anahtar in gorus_hucreleri:
		var hucre = gorus_hucreleri[anahtar]
		if not is_instance_valid(hucre):
			continue
		if su_anki_gorus_alani.get(anahtar, false):
			hucre.color = FOG_GORUNUR
		elif kesfedilen_alanlar.get(anahtar, false):
			hucre.color = FOG_GORUNUR
		else:
			hucre.color = FOG_KAPALI

func _clear_ghost_icon(id: int) -> void:
	if dusman_hayalet_ikonlari.has(id):
		var n = dusman_hayalet_ikonlari[id]
		if is_instance_valid(n):
			n.queue_free()
		dusman_hayalet_ikonlari.erase(id)

func _update_ghost_icons() -> void:
	var simdi = Time.get_unix_time_from_system()
	for id in dusman_son_gorulen_konum.keys():
		var kayit = dusman_son_gorulen_konum[id]
		if float(kayit.get("zaman", 0.0)) < simdi:
			_clear_ghost_icon(id)
			dusman_son_gorulen_konum.erase(id)
			continue
		var ikon = dusman_hayalet_ikonlari.get(id, null)
		if not is_instance_valid(ikon):
			var l = Label.new()
			l.text = "?"
			l.modulate = Color(0.9, 0.9, 0.9, 0.6)
			l.position = Vector2(kayit["konum"]) + Vector2(8, -10)
			_root.add_child(l)
			dusman_hayalet_ikonlari[id] = l
		else:
			ikon.position = Vector2(kayit["konum"]) + Vector2(8, -10)

func _tum_noktalari_goster() -> void:
	for nokta in _root.nokta_konumlari:
		var kare = _root.map_gorsel_node("Nokta_" + nokta)
		var isim_l = _root.map_gorsel_node("Label_Nokta_" + nokta)
		var puan_l = _root.map_gorsel_node("Label_Puan_" + nokta)
		var bg = _root.map_gorsel_node("CaptureBg_" + nokta)
		var bar = _root.capture_barlar.get(nokta, null)
		if kare:
			kare.visible = true
			kare.color = _point_owner_color(_root.nokta_sahipleri[nokta])
			kare.modulate = Color(1, 1, 1, 1)
		if isim_l:
			isim_l.visible = true
		if puan_l:
			puan_l.visible = true
			puan_l.modulate = Color(1, 1, 1, 1)
		if bg:
			bg.visible = true
		if bar:
			bar.visible = true
			bar.size.x = 80.0 * (_root.nokta_capture[nokta] / 100.0)
			bar.color = Color(1, 0.8, 0)
