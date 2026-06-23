extends RefCounted
class_name InputRouter

const CameraControllerScript = preload("res://scripts/camera/camera_controller.gd")

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func handle_input(event: InputEvent) -> bool:
	if _host.oyun_bitti:
		return true
	if handle_cancel_menu(event):
		return true
	if handle_camera_input(event, _host.kamera, _host.camera_controller):
		return true
	if event.is_action_pressed("cmd_primary_click"):
		handle_primary_click(event)
		return true
	return false

func handle_camera_input(
	event: InputEvent,
	camera: Camera2D,
	camera_controller: CameraControllerScript
) -> bool:
	if event.is_action_pressed("cmd_zoom_in"):
		camera_controller.apply_zoom(camera, true)
		return true
	if event.is_action_pressed("cmd_zoom_out"):
		camera_controller.apply_zoom(camera, false)
		return true
	return false

func handle_cancel_menu(event: InputEvent) -> bool:
	if not event.is_action_pressed("cmd_cancel_menu"):
		return false
	if _host.komut_menusu_panel != null and _host.komut_menusu_panel.visible:
		_host.komut_menusu_kapat()
		return true
	if _host.takviye_sag_tik_menu != null and _host.takviye_sag_tik_menu.visible:
		_host.takviye_sag_tik_menu_kapat()
		return true
	_host.komut_menusu_kapat()
	return true

func handle_primary_click(event: InputEvent) -> void:
	if _handle_minimap_click(event.position):
		_host.birim_detay_hover_bitir()
		return

	_close_menus_outside_click(event.position)

	if _is_click_on_takviye_menu(event.position):
		return

	var savas_icerik = _host.ui_node("SavasIcerik") as Control
	if savas_icerik != null and savas_icerik.visible:
		if savas_icerik.get_global_rect().has_point(event.position):
			_host.birim_detay_hover_bitir()
			return

	_host.birim_detay_hover_bitir()
	var dunya_pos = _host.get_global_mouse_position()
	if not _host.hazirlik_fazi:
		var tiklama_sonucu = _find_clicked_unit(dunya_pos)
		_apply_unit_click_decision(
			tiklama_sonucu["oyuncu"],
			tiklama_sonucu["dusman"],
			dunya_pos,
			event.position
		)
		return

	for birim in _host.aktif_birimler:
		if birim["taraf"] == "osmanli" and birim["hp"] > 0:
			var birim_rect = Rect2(birim["konum"], Vector2(30, 30))
			if birim_rect.has_point(dunya_pos):
				_host.birim_tikla(birim)
				break

func _handle_minimap_click(event_position: Vector2) -> bool:
	return _host.minimap_controller.handle_click(
		event_position,
		_host.kamera,
		_host.harita_sinir,
		Callable(_host, "kamera_sinirla")
	)

func _close_menus_outside_click(event_position: Vector2) -> void:
	if _host.komut_menusu_panel != null and _host.komut_menusu_panel.visible:
		var menu_rect = Rect2(_host.komut_menusu_panel.position, _host.komut_menusu_panel.size)
		if not menu_rect.has_point(event_position):
			_host.komut_menusu_kapat()
	if _host.takviye_sag_tik_menu != null and _host.takviye_sag_tik_menu.visible:
		var menu_rect = Rect2(_host.takviye_sag_tik_menu.position, _host.takviye_sag_tik_menu.size)
		if not menu_rect.has_point(event_position):
			_host.takviye_sag_tik_menu_kapat()

func _is_click_on_takviye_menu(event_position: Vector2) -> bool:
	if _host.takviye_sag_tik_menu == null or not _host.takviye_sag_tik_menu.visible:
		return false
	var takviye_menu_rect = Rect2(_host.takviye_sag_tik_menu.position, _host.takviye_sag_tik_menu.size)
	return takviye_menu_rect.has_point(event_position)

func _try_empty_area_point_selection(dunya_pos: Vector2) -> bool:
	for nokta in _host.nokta_konumlari:
		if not _host.fog_system.is_point_discovered(nokta):
			continue
		if dunya_pos.distance_to(_host.nokta_merkezi(nokta)) <= 70.0:
			_host.nokta_sec(nokta)
			return true
	return false

func _find_clicked_unit(dunya_pos: Vector2) -> Dictionary:
	var tiklanan_oyuncu = null
	var tiklanan_dusman = null
	for birim in _host.aktif_birimler:
		if birim["hp"] <= 0:
			continue
		var birim_rect = Rect2(birim["konum"], Vector2(30, 30))
		if not birim_rect.has_point(dunya_pos):
			continue
		if birim["taraf"] == "osmanli":
			tiklanan_oyuncu = birim
		else:
			tiklanan_dusman = birim
		if tiklanan_oyuncu != null:
			break
	return {"oyuncu": tiklanan_oyuncu, "dusman": tiklanan_dusman}

func _apply_unit_click_decision(tiklanan_oyuncu, tiklanan_dusman, dunya_pos: Vector2, ekran_pos: Vector2) -> void:
	if tiklanan_oyuncu != null:
		if _host.secili_birim == tiklanan_oyuncu:
			_host.komut_menusu_ac(ekran_pos, tiklanan_oyuncu)
		else:
			_host.komut_menusu_kapat()
			_host.komut_sec("hareket")
			_host.birim_tikla(tiklanan_oyuncu)
		return

	if _host.secili_birim != null and _host.secili_komut == "saldir" and tiklanan_dusman != null:
		_host.birim_komut_saldir(_host.secili_birim, tiklanan_dusman["konum"], int(tiklanan_dusman.get("id", -1)))
		return

	if _host.secili_birim != null:
		_host.komut_menusu_kapat()
		if _host.secili_komut == "pusu":
			_host.birim_pusu_kur()
		elif _host.secili_komut == "saldir":
			_host.birim_komut_saldir(_host.secili_birim, dunya_pos)
		else:
			_host.birim_hareket_ettir(dunya_pos)
	elif _host.secili_envanter_tip_anahtari != "":
		_host.birim_haritadan_gonder(dunya_pos)
	else:
		_try_empty_area_point_selection(dunya_pos)
