extends RefCounted
class_name FogSystem

var _root: Node2D = null
var _world: WorldSystem = null

# Mantiksal hucre boyutu (gorunurluk sorgulari); gorsel ayri dusuk cozunurluklu doku
var gorus_hucre_boyutu = 120.0
var gorus_hucre_katmani: Node2D = null
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
var _minimap_dirty := true
# Gecici: tum haritayi gostermek icin true (sonra false yap)
var harita_sis_kapali := true
# --- TEMP PERF DIAG (F4 Fog / F12 Minimap) ---
var _PERF_DIAG_FOG_ACIK := true
var _PERF_DIAG_MINIMAP_ACIK := true
# --- /TEMP PERF DIAG ---

const _GIZLENME_AKTIF := true
const _TESPIT_MENZIL := 400.0
const _GIZLI_MODULATE := Color(1.0, 1.0, 1.0, 0.42)
const _OYUNCU_TARAF := "osmanli"

const FOG_GORUNUR = Color(0, 0, 0, 0.0)
const FOG_KAPALI = Color(0.06, 0.08, 0.11, 0.93)

const _FOG_TEX_TARGET_W := 128
const _VISION_INTERVAL := 0.15
const _FOG_SHADER_PATH := "res://assets/shaders/fog_of_war.gdshader"

var _fog_tex_w := 128
var _fog_tex_h := 96
var _fog_image: Image = null
var _fog_texture: ImageTexture = null
var _fog_poly: Polygon2D = null
var _fog_dirty := true
var _vision_accum := 0.0
var _map_min := Vector2.ZERO
var _map_size := Vector2(1, 1)
var _clear_grid: PackedByteArray = PackedByteArray()

func configure(root_node: Node2D, world_system: WorldSystem) -> void:
	_root = root_node
	_world = world_system

func get_perf_diag_status() -> Dictionary:
	return {
		"fog": _PERF_DIAG_FOG_ACIK,
		"minimap": _PERF_DIAG_MINIMAP_ACIK,
	}

func perf_diag_toggle(kind: String) -> Dictionary:
	match kind:
		"fog":
			_PERF_DIAG_FOG_ACIK = not _PERF_DIAG_FOG_ACIK
			_perf_diag_fog_uygula()
		"minimap":
			_PERF_DIAG_MINIMAP_ACIK = not _PERF_DIAG_MINIMAP_ACIK
		_:
			pass
	return get_perf_diag_status()

func _perf_diag_fog_uygula() -> void:
	if not is_instance_valid(gorus_hucre_katmani):
		return
	if _PERF_DIAG_FOG_ACIK:
		_vision_accum = _VISION_INTERVAL
		_fog_dirty = true
		_minimap_dirty = true
		if _root != null and not _root.hazirlik_fazi:
			tick_battle_fog(_VISION_INTERVAL)
		else:
			set_layer_visible(true)
			_upload_fog_texture()
	else:
		if is_instance_valid(gorus_hucre_katmani):
			gorus_hucre_katmani.visible = false

func get_fog_layer() -> Node:
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
	if not is_instance_valid(gorus_hucre_katmani):
		return
	if not _PERF_DIAG_FOG_ACIK:
		gorus_hucre_katmani.visible = false
		return
	gorus_hucre_katmani.visible = visible and not harita_sis_kapali

func reset_fog_on_map_change() -> void:
	if is_instance_valid(gorus_hucre_katmani):
		reset_fog_grid()

func unit_vision_radius(unit_type: Dictionary) -> float:
	if unit_type.has("gorus_yaricapi"):
		return float(unit_type["gorus_yaricapi"])
	return float(unit_type.get("menzil", 80.0)) + normal_birim_gorus_bonus

func update_point_visibility() -> void:
	if not _PERF_DIAG_FOG_ACIK:
		return
	if harita_sis_kapali:
		_tum_noktalari_goster()
		return
	for nokta in _root.nokta_konumlari:
		var kesfedildi = is_point_discovered(nokta)
		var isim_l = _root.map_gorsel_node("Label_Nokta_" + nokta) as Label
		var puan_l = _root.map_gorsel_node("Label_Puan_" + nokta)
		var bg = _root.map_gorsel_node("CaptureBg_" + nokta)
		var bar = _root.capture_barlar.get(nokta, null)
		if not kesfedildi:
			if isim_l: isim_l.visible = false
			if puan_l: puan_l.visible = false
			if bg: bg.visible = false
			if bar: bar.visible = false
			continue

		if isim_l:
			isim_l.visible = true
			isim_l.add_theme_color_override("font_color", _point_owner_color(_root.nokta_sahipleri[nokta]))
		if puan_l:
			puan_l.visible = true
			puan_l.modulate = Color(1, 1, 1, 1)
		_root.nokta_son_bilgi[nokta] = {
			"sahip": _root.nokta_sahipleri[nokta],
			"capture": _root.nokta_capture[nokta]
		}
		if bg: bg.visible = true
		if bar:
			bar.visible = true
			bar.size.x = 80.0 * (_root.nokta_capture[nokta] / 100.0)
			bar.color = Color(1, 0.8, 0)

func update_unit_visibility() -> void:
	if not _PERF_DIAG_FOG_ACIK:
		return
	guncelle_gizlenme_durumlari(_root.aktif_birimler)
	for birim in _root.aktif_birimler:
		_birim_gorunurluk_uygula(birim)
	update_enemy_intel(_root.aktif_birimler)

func guncelle_gizlenme_durumlari(units: Array) -> void:
	if not _GIZLENME_AKTIF:
		for birim in units:
			if birim.get("hp", 0) > 0:
				birim["pusu_arazi_gizli"] = false
		return
	for birim in units:
		if birim.get("hp", 0) <= 0:
			birim["pusu_arazi_gizli"] = false
			continue
		if birim.get("pusu_modunda", false):
			birim["pusu_arazi_gizli"] = false
			continue
		birim["pusu_arazi_gizli"] = _birim_arazi_gizli_mi(birim, units)

func _birim_arazi_gizli_mi(birim: Dictionary, units: Array) -> bool:
	var konum: Vector2 = birim.get("konum", Vector2.ZERO)
	if _root.has_method("yol_uzerinde_mi") and _root.yol_uzerinde_mi(konum):
		return false
	var gizlenme_icinde := _world != null and _world.gizlenme_bolgesinde_mi(konum)
	var duruyor := _birim_duruyor_mu(birim)
	if gizlenme_icinde and duruyor:
		return true
	return not _dusman_tespit_menzilinde(birim, units)

func _birim_duruyor_mu(birim: Dictionary) -> bool:
	if int(birim.get("takip_edilen_dusman", -1)) >= 0:
		return false
	if birim.get("geri_cekiliyor", false):
		return false
	if bool(birim.get("hareket_durdu", false)):
		return true
	var hedef: Vector2 = birim.get("hedef", birim.get("konum", Vector2.ZERO))
	return birim.get("konum", Vector2.ZERO).distance_to(hedef) <= 8.0

func _dusman_tespit_menzilinde(birim: Dictionary, units: Array) -> bool:
	var taraf := str(birim.get("taraf", ""))
	var konum: Vector2 = birim.get("konum", Vector2.ZERO)
	for b in units:
		if b.get("hp", 0) <= 0:
			continue
		if str(b.get("taraf", "")) == taraf:
			continue
		if konum.distance_to(b.get("konum", Vector2.ZERO)) <= _TESPIT_MENZIL:
			return true
	return false

func _birim_gorunurluk_uygula(birim: Dictionary) -> void:
	if birim.get("hp", 0) <= 0:
		return
	var kendi := str(birim.get("taraf", "")) == _OYUNCU_TARAF
	var gizli := bool(birim.get("pusu_modunda", false)) or bool(birim.get("pusu_arazi_gizli", false))
	var gorunur: bool
	if kendi:
		gorunur = true
	else:
		gorunur = is_unit_visible_to_player(birim, _root.aktif_birimler)
	var kok = birim.get("kok_node")
	var node = birim.get("node")
	var cerceve = birim.get("cerceve_node")
	if is_instance_valid(kok):
		kok.visible = gorunur
		kok.modulate = _GIZLI_MODULATE if (kendi and gizli and gorunur) else Color.WHITE
	if is_instance_valid(node):
		node.visible = gorunur
		if not is_instance_valid(kok):
			node.modulate = _GIZLI_MODULATE if (kendi and gizli and gorunur) else Color.WHITE
	if is_instance_valid(cerceve):
		cerceve.visible = false
	var asker3d = birim.get("asker3d")
	if is_instance_valid(asker3d):
		asker3d.visible = gorunur
	var halka3d = birim.get("halka3d")
	if is_instance_valid(halka3d):
		halka3d.visible = gorunur

func is_unit_visible_to_faction(target: Dictionary, observer_faction: String, units: Array) -> bool:
	if target.get("hp", 0) <= 0:
		return false
	if str(target.get("taraf", "")) == observer_faction:
		return true
	if target.get("pusu_modunda", false):
		return false
	if _GIZLENME_AKTIF and target.get("pusu_arazi_gizli", false):
		return false
	if harita_sis_kapali:
		return true
	return _goruste_mi(target["konum"], get_current_vision(observer_faction))

func is_unit_visible_to_player(unit: Dictionary, units: Array) -> bool:
	return is_unit_visible_to_faction(unit, _OYUNCU_TARAF, units)

func tick_battle_fog(delta: float = _VISION_INTERVAL) -> void:
	if not _PERF_DIAG_FOG_ACIK:
		return
	_vision_accum += delta
	if _vision_accum >= _VISION_INTERVAL:
		_vision_accum = 0.0
		update_vision(_root.aktif_birimler, _root.nokta_sahipleri)
		update_point_visibility()
		update_unit_visibility()
	elif _fog_dirty:
		_upload_fog_texture()

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
	if not _PERF_DIAG_MINIMAP_ACIK:
		return
	var w := _fog_tex_w
	var h := _fog_tex_h
	if w <= 0 or h <= 0:
		return
	if _minimap_fow_gorseli == null or _minimap_fow_gorseli.get_width() != w or _minimap_fow_gorseli.get_height() != h:
		_minimap_fow_gorseli = Image.create(w, h, false, Image.FORMAT_RGBA8)
		_minimap_fow_doku = ImageTexture.create_from_image(_minimap_fow_gorseli)
		_minimap_dirty = true
	if not _minimap_dirty and _minimap_fow_doku != null:
		return
	if harita_sis_kapali:
		_minimap_fow_gorseli.fill(FOG_GORUNUR)
	else:
		for y in range(h):
			for x in range(w):
				var idx := y * w + x
				var clear := idx < _clear_grid.size() and _clear_grid[idx] != 0
				_minimap_fow_gorseli.set_pixel(x, y, FOG_GORUNUR if clear else FOG_KAPALI)
	if _minimap_fow_doku == null:
		_minimap_fow_doku = ImageTexture.create_from_image(_minimap_fow_gorseli)
	else:
		_minimap_fow_doku.update(_minimap_fow_gorseli)
	_minimap_dirty = false

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

func update_vision(units: Array, point_owners: Dictionary) -> void:
	if not _PERF_DIAG_FOG_ACIK:
		return
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
		_stamp_clear_cell(anahtar)

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

	if harita_sis_kapali:
		_clear_grid.fill(1)
	_fog_dirty = true
	_minimap_dirty = true
	_upload_fog_texture()

func create_fog_layer() -> void:
	if is_instance_valid(gorus_hucre_katmani):
		return
	gorus_hucre_katmani = Node2D.new()
	gorus_hucre_katmani.name = "FogLayer"
	gorus_hucre_katmani.z_index = 40
	_root.add_child(gorus_hucre_katmani)
	reset_fog_grid()

func reset_fog_grid() -> void:
	if not is_instance_valid(gorus_hucre_katmani):
		return
	kesfedilen_alanlar.clear()
	su_anki_gorus_alani.clear()
	ai_su_anki_gorus_alani.clear()
	_vision_accum = _VISION_INTERVAL
	_ensure_fog_resolution()
	_clear_grid.resize(_fog_tex_w * _fog_tex_h)
	_clear_grid.fill(0)
	_ensure_fog_draw_node()
	_fog_dirty = true
	_minimap_dirty = true
	_upload_fog_texture()
	set_layer_visible(false)

func _ensure_fog_resolution() -> void:
	var harita_sinir = _world.get_map_bounds()
	_map_min = Vector2(float(harita_sinir["min_x"]), float(harita_sinir["min_y"]))
	var map_max = Vector2(float(harita_sinir["max_x"]), float(harita_sinir["max_y"]))
	_map_size = map_max - _map_min
	if _map_size.x < 1.0:
		_map_size.x = 1.0
	if _map_size.y < 1.0:
		_map_size.y = 1.0
	_fog_tex_w = _FOG_TEX_TARGET_W
	_fog_tex_h = maxi(8, int(round(float(_FOG_TEX_TARGET_W) * _map_size.y / _map_size.x)))
	# Mantiksal hucre: doku cozunurlugune yakin tut (sorgu tutarliligi)
	gorus_hucre_boyutu = maxf(32.0, _map_size.x / float(_fog_tex_w))

func _ensure_fog_draw_node() -> void:
	if not is_instance_valid(gorus_hucre_katmani):
		return
	if _fog_image == null or _fog_image.get_width() != _fog_tex_w or _fog_image.get_height() != _fog_tex_h:
		_fog_image = Image.create(_fog_tex_w, _fog_tex_h, false, Image.FORMAT_RF)
		_fog_image.fill(Color(0, 0, 0, 1))
		_fog_texture = ImageTexture.create_from_image(_fog_image)
	elif _fog_texture == null:
		_fog_texture = ImageTexture.create_from_image(_fog_image)

	if not is_instance_valid(_fog_poly):
		_fog_poly = Polygon2D.new()
		_fog_poly.name = "FogOverlay"
		_fog_poly.z_index = 0
		_fog_poly.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var sh := load(_FOG_SHADER_PATH) as Shader
		if sh != null:
			var mat := ShaderMaterial.new()
			mat.shader = sh
			mat.set_shader_parameter("fog_color", FOG_KAPALI)
			_fog_poly.material = mat
		gorus_hucre_katmani.add_child(_fog_poly)

	_fog_poly.texture = _fog_texture
	if _fog_poly.material is ShaderMaterial:
		(_fog_poly.material as ShaderMaterial).set_shader_parameter("fog_tex", _fog_texture)

	var p00 := _world.logical_to_ekran(_map_min)
	var p10 := _world.logical_to_ekran(_map_min + Vector2(_map_size.x, 0.0))
	var p11 := _world.logical_to_ekran(_map_min + _map_size)
	var p01 := _world.logical_to_ekran(_map_min + Vector2(0.0, _map_size.y))
	_fog_poly.polygon = PackedVector2Array([p00, p10, p11, p01])
	var tw := float(_fog_tex_w)
	var th := float(_fog_tex_h)
	_fog_poly.uv = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(tw, 0.0),
		Vector2(tw, th),
		Vector2(0.0, th),
	])

func _rebuild_clear_grid() -> void:
	var n := _fog_tex_w * _fog_tex_h
	if _clear_grid.size() != n:
		_clear_grid.resize(n)
	_clear_grid.fill(0)
	if harita_sis_kapali:
		_clear_grid.fill(1)
		return
	var origin := _hucre_anahtari(_map_min)
	for anahtar in kesfedilen_alanlar:
		_stamp_clear_cell_at(anahtar, origin)

func _stamp_clear_cell(anahtar: Vector2i) -> void:
	_stamp_clear_cell_at(anahtar, _hucre_anahtari(_map_min))

func _stamp_clear_cell_at(anahtar: Vector2i, origin: Vector2i) -> void:
	var tx := anahtar.x - origin.x
	var ty := anahtar.y - origin.y
	if tx < 0 or ty < 0 or tx >= _fog_tex_w or ty >= _fog_tex_h:
		return
	var idx := ty * _fog_tex_w + tx
	if idx >= 0 and idx < _clear_grid.size():
		_clear_grid[idx] = 1

func _upload_fog_texture() -> void:
	if not _fog_dirty:
		return
	if not _PERF_DIAG_FOG_ACIK or harita_sis_kapali:
		if is_instance_valid(gorus_hucre_katmani):
			gorus_hucre_katmani.visible = false
		_fog_dirty = false
		return
	_ensure_fog_draw_node()
	if _fog_image == null:
		return
	# RF: her piksel 1 float
	var n := _fog_tex_w * _fog_tex_h
	var bytes := PackedByteArray()
	bytes.resize(n * 4)
	for i in range(n):
		var v := 1.0 if (i < _clear_grid.size() and _clear_grid[i] != 0) else 0.0
		bytes.encode_float(i * 4, v)
	_fog_image.set_data(_fog_tex_w, _fog_tex_h, false, Image.FORMAT_RF, bytes)
	if _fog_texture == null:
		_fog_texture = ImageTexture.create_from_image(_fog_image)
	else:
		_fog_texture.update(_fog_image)
	if is_instance_valid(_fog_poly):
		_fog_poly.texture = _fog_texture
		if _fog_poly.material is ShaderMaterial:
			(_fog_poly.material as ShaderMaterial).set_shader_parameter("fog_tex", _fog_texture)
	set_layer_visible(true)
	_fog_dirty = false

func _world_to_tex(pos: Vector2) -> Vector2i:
	var u := (pos.x - _map_min.x) / _map_size.x
	var v := (pos.y - _map_min.y) / _map_size.y
	return Vector2i(
		clampi(int(floor(u * float(_fog_tex_w))), 0, _fog_tex_w - 1),
		clampi(int(floor(v * float(_fog_tex_h))), 0, _fog_tex_h - 1)
	)

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
	var r2 := yaricap * yaricap
	for x in range(min_h.x, max_h.x + 1):
		for y in range(min_h.y, max_h.y + 1):
			var anahtar = Vector2i(x, y)
			if _hucre_merkezi(anahtar).distance_squared_to(merkez) <= r2:
				gorus_alani[anahtar] = true

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
		var isim_l = _root.map_gorsel_node("Label_Nokta_" + nokta) as Label
		var puan_l = _root.map_gorsel_node("Label_Puan_" + nokta)
		var bg = _root.map_gorsel_node("CaptureBg_" + nokta)
		var bar = _root.capture_barlar.get(nokta, null)
		if isim_l:
			isim_l.visible = true
			isim_l.add_theme_color_override("font_color", _point_owner_color(_root.nokta_sahipleri[nokta]))
		if puan_l:
			puan_l.visible = true
			puan_l.modulate = Color(1, 1, 1, 1)
		if bg:
			bg.visible = true
		if bar:
			bar.visible = true
			bar.size.x = 80.0 * (_root.nokta_capture[nokta] / 100.0)
			bar.color = Color(1, 0.8, 0)
