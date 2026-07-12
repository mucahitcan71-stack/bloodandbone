extends RefCounted
class_name CommandSystem

const _NOKTA_HEDEF_ESIGI := 100.0

var _root: Node2D = null
var secili_komut: String = "hareket"
var secili_birim = null
var menu_hedef_birim = null
var _harita_sinirla: Callable
var _en_yakin_nokta_bul: Callable
var _nokta_merkezi: Callable
var _en_yakin_dost_nokta: Callable
var _birimin_arazisini_bul: Callable
var _path_find: Callable
var _path_to_control_point: Callable
var _kontrol_noktasi_mi: Callable
var _yol_uzerinde_mi: Callable

func configure(root_node: Node2D) -> void:
	_root = root_node

func bind_map_helpers(
	clamp_map_fn: Callable,
	nearest_point_fn: Callable,
	point_center_fn: Callable,
	nearest_friendly_point_fn: Callable,
	terrain_at_fn: Callable
) -> void:
	_harita_sinirla = clamp_map_fn
	_en_yakin_nokta_bul = nearest_point_fn
	_nokta_merkezi = point_center_fn
	_en_yakin_dost_nokta = nearest_friendly_point_fn
	_birimin_arazisini_bul = terrain_at_fn

func bind_path_helpers(
	find_path_fn: Callable,
	path_to_control_point_fn: Callable,
	is_control_point_fn: Callable,
	on_road_fn: Callable = Callable()
) -> void:
	_path_find = find_path_fn
	_path_to_control_point = path_to_control_point_fn
	_kontrol_noktasi_mi = is_control_point_fn
	_yol_uzerinde_mi = on_road_fn

func reset_for_preparation() -> void:
	secili_komut = "hareket"
	secili_birim = null
	menu_hedef_birim = null

func reset_for_battle_start() -> void:
	secili_komut = "hareket"
	secili_birim = null
	menu_hedef_birim = null

func get_selected_command() -> String:
	return secili_komut

func get_selected_unit():
	return secili_birim

func get_menu_target_unit():
	return menu_hedef_birim

func has_selection() -> bool:
	return secili_birim != null

func set_command_mode(komut: String) -> Dictionary:
	secili_komut = komut
	var result = {"status_line": ""}
	if secili_birim == null:
		return result
	var metin = "Secili: " + str(secili_birim.get("isim", "Birim"))
	if komut == "saldir":
		metin += " — hedefe tikla"
	elif komut == "hareket":
		metin += " — hareket icin tikla"
	else:
		metin += " — komut sec"
	result["status_line"] = metin
	return result

func select_unit(birim) -> Dictionary:
	if birim == null:
		if secili_birim != null:
			_deselect_unit_visual(secili_birim)
		secili_birim = null
		return {}
	if birim.get("taraf", "") != "osmanli":
		return {"ignored": true}
	if secili_birim != null and secili_birim != birim:
		_deselect_unit_visual(secili_birim)
	secili_birim = birim
	birim["secili"] = true
	_birim_secim_gorseli(birim, true)
	var metin = "Secili: " + str(birim.get("isim", "Birim"))
	metin += " — hedefe tikla" if secili_komut == "hareket" else " — pusu kurmak icin tikla"
	return {
		"status_line": metin,
		"deselect_inventory": true,
	}

func _deselect_unit_visual(birim) -> void:
	if birim == null:
		return
	birim["secili"] = false
	_birim_secim_gorseli(birim, false)

func _release_unit_after_command(birim: Dictionary) -> void:
	birim["secili"] = false
	_birim_secim_gorseli(birim, false)

func _birim_secim_gorseli(birim, secili: bool) -> void:
	# Eski sari secim karesi (cerceve) kapali — geri bildirim sadece zemin halkasi
	var cerceve = birim.get("cerceve_node") if birim is Dictionary else null
	if is_instance_valid(cerceve):
		cerceve.visible = false
	if birim is Dictionary and is_instance_valid(birim.get("node")):
		birim["node"].modulate = Color(1, 1, 1)
	if birim is Dictionary and _root != null:
		var ws = _root.get("world_system")
		if ws != null:
			ws.zemin3d_birim_halka_secili(birim, secili)

func execute_move(hedef_pos: Vector2, force_offroad: bool = false) -> Dictionary:
	if secili_birim == null:
		return {}
	var birim = secili_birim
	if _harita_sinirla.is_valid():
		hedef_pos = _harita_sinirla.call(hedef_pos)
	var nokta := ""
	var kapi_yolu := false
	# Kapı yolu sadece hedef GERCEKTEN yolda ve noktaya yakinsa (arazi tiklamasinda yola cekme).
	if not force_offroad and _en_yakin_nokta_bul.is_valid() and _nokta_merkezi.is_valid():
		var yakin := str(_en_yakin_nokta_bul.call(hedef_pos))
		var merkez: Vector2 = _nokta_merkezi.call(yakin)
		if hedef_pos.distance_to(merkez) <= _NOKTA_HEDEF_ESIGI \
				and _yol_uzerinde_mi.is_valid() and _yol_uzerinde_mi.call(hedef_pos):
			nokta = yakin
			kapi_yolu = _kontrol_noktasi_mi.is_valid() and _kontrol_noktasi_mi.call(nokta)
	_yol_ata(birim, hedef_pos, nokta, kapi_yolu, force_offroad)
	birim["hedef_nokta"] = nokta
	birim["savas_halinde"] = false
	birim["geri_cekiliyor"] = false
	birim["savunma_modunda"] = false
	birim["takip_edilen_dusman"] = -1
	birim["pusu_modunda"] = false
	birim["pusu_arazi_gizli"] = false
	birim["pusu_ilk_saldiri_kullanildi"] = false
	_release_unit_after_command(birim)
	secili_birim = null
	if force_offroad:
		return {"status_line": "Yoldan cikis — yol disi (yavas)"}
	var durum := "Birim hareket ettirildi"
	if _yol_uzerinde_mi.is_valid() and not _yol_uzerinde_mi.call(hedef_pos):
		durum += " (yol disi — yavas)"
	return {"status_line": durum}

func execute_retreat(birim: Dictionary) -> Dictionary:
	var nokta = "E"
	if _en_yakin_dost_nokta.is_valid():
		nokta = str(_en_yakin_dost_nokta.call(birim["konum"], "osmanli"))
	birim["geri_cekiliyor"] = true
	birim["savunma_modunda"] = false
	birim["pusu_modunda"] = false
	birim["pusu_arazi_gizli"] = false
	birim["takip_edilen_dusman"] = -1
	if _nokta_merkezi.is_valid():
		var hedef_pos: Vector2 = _nokta_merkezi.call(nokta)
		_yol_ata(birim, hedef_pos, nokta, true)
	birim["hedef_nokta"] = nokta
	_release_unit_after_command(birim)
	secili_birim = null
	secili_komut = "hareket"
	return {"status_line": "Birim geri cekiliyor → " + nokta}

func execute_defend_point(birim: Dictionary) -> Dictionary:
	var nokta = ""
	if _en_yakin_nokta_bul.is_valid():
		nokta = str(_en_yakin_nokta_bul.call(birim["konum"]))
	birim["savunma_modunda"] = true
	birim["geri_cekiliyor"] = false
	birim["takip_edilen_dusman"] = -1
	birim["pusu_modunda"] = false
	birim["pusu_arazi_gizli"] = false
	birim["hedef"] = birim["konum"]
	birim["waypoints"] = PackedVector2Array()
	birim["waypoint_idx"] = 0
	birim["hedef_nokta"] = nokta
	_release_unit_after_command(birim)
	secili_birim = null
	secili_komut = "hareket"
	return {"status_line": "Nokta savun modu aktif: " + nokta}

func execute_attack(birim: Dictionary, hedef_pos: Vector2, hedef_dusman_id: int = -1) -> Dictionary:
	birim["geri_cekiliyor"] = false
	birim["savunma_modunda"] = false
	birim["pusu_modunda"] = false
	birim["pusu_arazi_gizli"] = false
	if _harita_sinirla.is_valid():
		hedef_pos = _harita_sinirla.call(hedef_pos)
	_yol_ata(birim, hedef_pos)
	if _en_yakin_nokta_bul.is_valid():
		birim["hedef_nokta"] = _en_yakin_nokta_bul.call(hedef_pos)
	birim["takip_edilen_dusman"] = hedef_dusman_id
	_release_unit_after_command(birim)
	secili_birim = null
	secili_komut = "hareket"
	return {"status_line": "Saldiri emri verildi"}

func execute_ambush() -> Dictionary:
	if secili_birim == null:
		return {}
	var birim = secili_birim
	var arazi = {}
	if _birimin_arazisini_bul.is_valid():
		arazi = _birimin_arazisini_bul.call(birim["konum"])
	if str(arazi.get("tip", "duz_arazi")) != "orman":
		return {"status_line": "Pusu sadece ORMAN bolgesinde kurulabilir"}
	birim["hedef"] = birim["konum"]
	birim["waypoints"] = PackedVector2Array()
	birim["waypoint_idx"] = 0
	birim["pusu_modunda"] = true
	birim["pusu_arazi_gizli"] = false
	birim["pusu_ilk_saldiri_kullanildi"] = false
	birim["geri_cekiliyor"] = false
	birim["savunma_modunda"] = false
	birim["takip_edilen_dusman"] = -1
	birim["savas_halinde"] = false
	_release_unit_after_command(birim)
	secili_birim = null
	secili_komut = "hareket"
	return {"status_line": "Birim pusuya girdi (dusman menzile girince ilk vurus x2)"}

func _sync_from_main(komut: String, birim, menu_hedef) -> void:
	secili_komut = komut
	secili_birim = birim
	menu_hedef_birim = menu_hedef

func _yol_ata(birim: Dictionary, hedef_pos: Vector2, nokta_id: String = "", kapi_hedefi: bool = false, force_offroad: bool = false) -> bool:
	var from: Vector2 = birim["konum"]
	var yol: PackedVector2Array
	if force_offroad:
		yol = PackedVector2Array()
		yol.append(from)
		yol.append(hedef_pos)
	elif kapi_hedefi and nokta_id != "" and _path_to_control_point.is_valid():
		yol = _path_to_control_point.call(from, nokta_id)
	elif _path_find.is_valid():
		yol = _path_find.call(from, hedef_pos)
	else:
		yol = PackedVector2Array()
	if yol.size() < 2:
		yol = PackedVector2Array()
		yol.append(from)
		yol.append(hedef_pos)
	birim["waypoints"] = yol
	var idx := 0
	while idx < yol.size() - 1 and yol[idx].distance_to(from) <= 14.0:
		idx += 1
	birim["waypoint_idx"] = idx
	birim["hedef"] = yol[idx]
	birim["yol_baglanti"] = false
	birim["hareket_durdu"] = false
	return true
