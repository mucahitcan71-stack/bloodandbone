extends RefCounted
class_name InputRouter

const CameraControllerScript = preload("res://scripts/camera/camera_controller.gd")

var _host: Node2D = null
var _sol_surukle_aktif := false
var _sol_surukle_tasinmis := false
var _sol_surukle_baslangic := Vector2.ZERO
const SOL_SURUKLE_ESIK := 10.0
const BIRIM_GORSEL_BOYUT := Vector2(30, 30)
const NOKTA_SECIM_YARICAP := 70.0

func configure(host: Node2D) -> void:
	_host = host

func handle_input(event: InputEvent) -> bool:
	if _host.oyun_bitti:
		return true
	if _handle_fps_overlay_toggle(event):
		return true
	if _handle_perf_diag_toggle(event):
		return true
	if _handle_path_debug_toggle(event):
		return true
	if handle_cancel_menu(event):
		return true
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			handle_secondary_click(mb.position)
			return true
	if handle_camera_input(event, _host.kamera, _host.camera_controller):
		return true
	if _handle_left_drag_pan(event, _host.kamera, _host.camera_controller):
		return true
	if event.is_action_pressed("cmd_primary_click"):
		_sol_surukle_aktif = true
		_sol_surukle_tasinmis = false
		if event is InputEventMouseButton:
			_sol_surukle_baslangic = (event as InputEventMouseButton).position
		return true
	if event.is_action_released("cmd_primary_click"):
		if _sol_surukle_aktif and not _sol_surukle_tasinmis:
			handle_primary_click(event)
		_sol_surukle_aktif = false
		_sol_surukle_tasinmis = false
		return true
	return false

func handle_secondary_click(event_position: Vector2) -> void:
	if _host.hazirlik_fazi:
		return
	_host.birim_detay_hover_bitir()
	_close_menus_outside_click(event_position)
	var dunya_pos = _host.get_global_mouse_position()
	var tiklama_sonucu = _find_clicked_unit(dunya_pos)
	var tiklanan_oyuncu = tiklama_sonucu.get("oyuncu", null)
	var tiklanan_dusman = tiklama_sonucu.get("dusman", null)
	if tiklanan_oyuncu != null:
		if _host.secili_birim != tiklanan_oyuncu:
			_host.komut_menusu_kapat()
			_host.komut_sec("hareket")
			_host.birim_tikla(tiklanan_oyuncu)
		_host.dusman_sag_tik_menu_kapat()
		_host.komut_menusu_ac(event_position, tiklanan_oyuncu)
		return
	if tiklanan_dusman != null and _host.secili_birim != null:
		_host.komut_menusu_kapat()
		_host.dusman_sag_tik_menu_ac(event_position, tiklanan_dusman)
		return
	_host.dusman_sag_tik_menu_kapat()
	if _host.secili_birim != null:
		_host.harita_sag_tik_menu_ac(event_position, dunya_pos)
		return
	_host.komut_menusu_kapat()

func handle_camera_input(
	event: InputEvent,
	camera: Camera2D,
	camera_controller: CameraControllerScript
) -> bool:
	if event.is_action_pressed("cmd_zoom_in"):
		camera_controller.apply_zoom(camera, false)
		return true
	if event.is_action_pressed("cmd_zoom_out"):
		camera_controller.apply_zoom(camera, true)
		return true
	return false

func _handle_left_drag_pan(
	event: InputEvent,
	camera: Camera2D,
	camera_controller: CameraControllerScript
) -> bool:
	if not _sol_surukle_aktif:
		return false
	if not (event is InputEventMouseMotion):
		return false
	var motion = event as InputEventMouseMotion
	if motion.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
		return false
	if not _sol_surukle_tasinmis and motion.position.distance_to(_sol_surukle_baslangic) >= SOL_SURUKLE_ESIK:
		_sol_surukle_tasinmis = true
	if not _sol_surukle_tasinmis:
		return false
	camera_controller.apply_drag_pan(camera, motion.relative, Callable(_host, "kamera_sinirla"))
	return true

func _handle_fps_overlay_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	var ek := event as InputEventKey
	if ek.keycode != KEY_F2:
		return false
	if ek.ctrl_pressed or ek.shift_pressed or ek.alt_pressed:
		return false
	_host.fps_overlay_toggle()
	return true

func _handle_perf_diag_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	var ek := event as InputEventKey
	var key := ek.keycode
	var kind := ""
	# F8 = Godot editor/debugger "Stop" (oyunu kapatır). F9 = breakpoint.
	# SSAO/Asker F10/F11. F1=Timing F3=Path F4=Fog F12=Minimap.
	# Ctrl+F3=VSync Ctrl+F6=Zemin Ctrl+F7=VP ALWAYS Ctrl+F8=Viewport ölçek (bare F8 yasak).
	if ek.ctrl_pressed:
		match key:
			KEY_F3:
				kind = "vsync"
			KEY_F6:
				kind = "zemin"
			KEY_F7:
				kind = "viewport"
			KEY_F8:
				kind = "viewport_olcek"
			_:
				return false
	elif ek.shift_pressed or ek.alt_pressed:
		return false
	else:
		match key:
			KEY_F1:
				kind = "timing"
			KEY_F4:
				kind = "fog"
			KEY_F6:
				kind = "prop"
			KEY_F7:
				kind = "golge"
			KEY_F10:
				kind = "ssao"
			KEY_F11:
				kind = "asker"
			KEY_F12:
				kind = "minimap"
			_:
				return false
	_host.perf_diag_toggle(kind)
	return true

func _handle_path_debug_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	var ek := event as InputEventKey
	if ek.keycode != KEY_F3:
		return false
	# Ctrl+F3 = VSync; F3 yalnız = path debug
	if ek.ctrl_pressed or ek.shift_pressed or ek.alt_pressed:
		return false
	_host.path_debug_toggle()
	return true

func handle_cancel_menu(event: InputEvent) -> bool:
	if not event.is_action_pressed("cmd_cancel_menu"):
		return false
	if _host.komut_menusu_panel != null and _host.komut_menusu_panel.visible:
		_host.komut_menusu_kapat()
		return true
	if _host.takviye_sag_tik_menu != null and _host.takviye_sag_tik_menu.visible:
		_host.takviye_sag_tik_menu_kapat()
		return true
	if _host.dusman_sag_tik_menu != null and _host.dusman_sag_tik_menu.visible:
		_host.dusman_sag_tik_menu_kapat()
		return true
	if _host.harita_sag_tik_menu != null and _host.harita_sag_tik_menu.visible:
		_host.harita_sag_tik_menu_kapat()
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
			if _birim_gorseline_tiklandi(dunya_pos, birim["konum"]):
				_host.birim_tikla(birim)
				break

func _handle_minimap_click(event_position: Vector2) -> bool:
	return _host.minimap_controller.handle_click(
		event_position,
		_host.kamera,
		_host.harita_sinir,
		Callable(_host, "kamera_sinirla"),
		Callable(_host, "logical_to_ekran")
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
	if _host.dusman_sag_tik_menu != null and _host.dusman_sag_tik_menu.visible:
		var dusman_rect = Rect2(_host.dusman_sag_tik_menu.position, _host.dusman_sag_tik_menu.size)
		if not dusman_rect.has_point(event_position):
			_host.dusman_sag_tik_menu_kapat()
	if _host.harita_sag_tik_menu != null and _host.harita_sag_tik_menu.visible:
		var harita_rect = Rect2(_host.harita_sag_tik_menu.position, _host.harita_sag_tik_menu.size)
		if not harita_rect.has_point(event_position):
			_host.harita_sag_tik_menu_kapat()

func _is_click_on_takviye_menu(event_position: Vector2) -> bool:
	if _host.takviye_sag_tik_menu == null or not _host.takviye_sag_tik_menu.visible:
		return false
	var takviye_menu_rect = Rect2(_host.takviye_sag_tik_menu.position, _host.takviye_sag_tik_menu.size)
	return takviye_menu_rect.has_point(event_position)

func _try_empty_area_point_selection(dunya_pos: Vector2) -> bool:
	var logical_click: Vector2 = _host.ekran_to_logical(dunya_pos)
	var en_yakin := ""
	var en_kisa := INF
	for nokta in _host.nokta_konumlari:
		if not _host.fog_system.is_point_discovered(nokta):
			continue
		var d := logical_click.distance_to(_host.nokta_merkezi(nokta))
		if d <= NOKTA_SECIM_YARICAP and d < en_kisa:
			en_kisa = d
			en_yakin = nokta
	if en_yakin != "":
		_host.nokta_sec(en_yakin)
		return true
	return false

func _birim_gorseline_tiklandi(dunya_pos: Vector2, konum: Vector2) -> bool:
	var rect := Rect2(_host.birim_gorsel_konum(konum), BIRIM_GORSEL_BOYUT)
	return rect.has_point(dunya_pos)


func _find_clicked_unit(dunya_pos: Vector2) -> Dictionary:
	var tiklanan_oyuncu = null
	var tiklanan_dusman = null
	var en_onde_oyuncu_y := -INF
	var en_onde_dusman_y := -INF
	for birim in _host.aktif_birimler:
		if birim["hp"] <= 0:
			continue
		if not _birim_gorseline_tiklandi(dunya_pos, birim["konum"]):
			continue
		var on_y: float = _host.birim_y_sort_foot(birim["konum"]).y
		if birim["taraf"] == "osmanli":
			if on_y >= en_onde_oyuncu_y:
				en_onde_oyuncu_y = on_y
				tiklanan_oyuncu = birim
		else:
			if not _host.birim_gorunur_mu_tarafa(birim, "osmanli"):
				continue
			if on_y >= en_onde_dusman_y:
				en_onde_dusman_y = on_y
				tiklanan_dusman = birim
	return {"oyuncu": tiklanan_oyuncu, "dusman": tiklanan_dusman}

func _apply_unit_click_decision(tiklanan_oyuncu, tiklanan_dusman, dunya_pos: Vector2, ekran_pos: Vector2) -> void:
	_host.dusman_sag_tik_menu_kapat()
	_host.harita_sag_tik_menu_kapat()
	if tiklanan_oyuncu != null:
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
			_host.birim_hareket_ettir(_host.ekran_to_logical(dunya_pos))
	elif _host.secili_envanter_tip_anahtari != "":
		_host.birim_haritadan_gonder(dunya_pos)
	else:
		_try_empty_area_point_selection(dunya_pos)
