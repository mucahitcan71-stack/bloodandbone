extends RefCounted
class_name UISystem
const HudStyle = preload("res://scripts/ui/hud_style.gd")
const UiLayoutBuilder = preload("res://scripts/ui/ui_layout_builder.gd")
const SideHud = preload("res://scripts/ui/side_hud.gd")
const UnitDetailPopup = preload("res://scripts/ui/unit_detail_popup.gd")

var _root: Node2D = null
var _layout: UiLayoutBuilder = UiLayoutBuilder.new()
var _side_hud: SideHud = SideHud.new()
var _detail_popup: UnitDetailPopup = UnitDetailPopup.new()

var hazirlik_paneli: Array = []
var hazirlik_aktif_tab: String = "genel"
var hazirlik_tab_gruplari = {"genel": [], "ordu": [], "taktik": []}
var hazirlik_tab_butonlari = {}
var hazirlik_tab_container_map = {}
var savas_paneli: Array = []
var hiz_tek_btn: Button = null
var savas_kaynak_satir: HBoxContainer = null
var _fps_label: Label = null
var _fps_legend: Label = null
var _timing_label: Label = null
var _fps_acik := true
var _PERF_DIAG_TIMING_ACIK := false
var _perf_diag_status := {
	"prop": true, "golge": true, "ssao": true, "asker": true,
	"fog": true, "minimap": true, "zemin": true, "viewport": true, "timing": false,
}
var _timing_us := {
	"fog": 0, "minimap": 0, "combat": 0, "ui": 0, "zemin3d": 0,
	"combat_hareket": 0, "combat_mesafe": 0, "combat_yol": 0, "combat_gorunurluk": 0,
}

func configure(root_node: Node2D) -> void:
	_root = root_node
	_layout.configure(root_node)
	_side_hud.configure(root_node)
	_detail_popup.configure(root_node)

func get_node_by_name(node_name: String) -> Node:
	if _root == null or not _root.has_node("CanvasLayer"):
		return null
	return _root.get_node("CanvasLayer").find_child(node_name, true, false)

# === Layout (delegated to UiLayoutBuilder) ===

func get_ui_root() -> Control:
	return _layout.get_ui_root()

func get_ust_bilgi_paneli() -> HBoxContainer:
	return _layout.get_ust_bilgi_paneli()

func get_hazirlik_panel_root() -> PanelContainer:
	return _layout.get_hazirlik_panel_root()

func get_hazirlik_tabs_row() -> HBoxContainer:
	return _layout.get_hazirlik_tabs_row()

func get_hazirlik_tabs_content() -> VBoxContainer:
	return _layout.get_hazirlik_tabs_content()

func get_savas_panel_root() -> PanelContainer:
	return _layout.get_savas_panel_root()

func get_savas_icerik_vbox() -> VBoxContainer:
	return _layout.get_savas_icerik_vbox()

func build_container_infrastructure() -> void:
	_layout.build_container_infrastructure()

func optimize_fonts(font_size: int, extra_roots: Array = []) -> void:
	_layout.optimize_fonts(font_size, extra_roots)

# === Side HUD (delegated to SideHud) ===

func get_yan_hud_tetik() -> PanelContainer:
	return _side_hud.get_yan_hud_tetik()

func get_yan_hud_panel() -> PanelContainer:
	return _side_hud.get_yan_hud_panel()

func get_yan_hud_icerik() -> VBoxContainer:
	return _side_hud.get_yan_hud_icerik()

func get_yan_hud_kaybol_timer() -> Timer:
	return _side_hud.get_yan_hud_kaybol_timer()

func build_side_hud() -> void:
	_side_hud.build(_layout.get_ui_root(), _layout.get_ust_bilgi_paneli())

# === Unit detail popup (delegated to UnitDetailPopup) ===

func set_unit_detail_text_provider(callback: Callable) -> void:
	_detail_popup.set_text_provider(callback)

func get_detay_popup_panel() -> Panel:
	return _detail_popup.get_panel()

func get_detay_popup_label() -> Label:
	return _detail_popup.get_label()

func get_detay_popup_timer() -> Timer:
	return _detail_popup.get_timer()

func build_unit_detail_popup() -> void:
	_detail_popup.build()

func build_fps_overlay() -> void:
	if _root == null or not _root.has_node("CanvasLayer"):
		return
	if is_instance_valid(_fps_label):
		return
	var layer: CanvasLayer = _root.get_node("CanvasLayer")
	var lbl := Label.new()
	lbl.name = "Label_Fps"
	lbl.visible = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lbl.position = Vector2(8, 8)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.98, 0.98, 0.75, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.text = _fps_overlay_metni()
	layer.add_child(lbl)
	_fps_label = lbl
	var legend := Label.new()
	legend.name = "Label_FpsLegend"
	legend.visible = true
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.set_anchors_preset(Control.PRESET_TOP_LEFT)
	legend.position = Vector2(8, 32)
	legend.add_theme_font_size_override("font_size", 14)
	legend.add_theme_color_override("font_color", Color(0.85, 0.9, 0.75, 0.95))
	legend.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	legend.add_theme_constant_override("outline_size", 2)
	legend.text = "F4:Fog  F12:Mini  Ctrl+F6:Zemin  Ctrl+F7:VP  F1:Timing | F6:Prop  F7:Golge  F10:SSAO  F11:Asker  F2:FPS"
	layer.add_child(legend)
	_fps_legend = legend
	var timing := Label.new()
	timing.name = "Label_PerfTiming"
	timing.visible = false
	timing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timing.set_anchors_preset(Control.PRESET_TOP_LEFT)
	timing.position = Vector2(8, 52)
	timing.add_theme_font_size_override("font_size", 15)
	timing.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0, 1.0))
	timing.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	timing.add_theme_constant_override("outline_size", 3)
	timing.text = _timing_overlay_metni()
	layer.add_child(timing)
	_timing_label = timing
	_fps_acik = true

func toggle_fps_overlay() -> void:
	_fps_acik = not _fps_acik
	if is_instance_valid(_fps_label):
		_fps_label.visible = _fps_acik
		if _fps_acik:
			_fps_label.text = _fps_overlay_metni()
	if is_instance_valid(_fps_legend):
		_fps_legend.visible = _fps_acik
	if is_instance_valid(_timing_label):
		_timing_label.visible = _fps_acik and _PERF_DIAG_TIMING_ACIK

func set_perf_diag_status(status: Dictionary) -> void:
	_perf_diag_status = status
	if _fps_acik and is_instance_valid(_fps_label):
		_fps_label.text = _fps_overlay_metni()

func is_perf_timing_acik() -> bool:
	return _PERF_DIAG_TIMING_ACIK

func toggle_perf_timing() -> bool:
	_PERF_DIAG_TIMING_ACIK = not _PERF_DIAG_TIMING_ACIK
	_perf_diag_status["timing"] = _PERF_DIAG_TIMING_ACIK
	if is_instance_valid(_timing_label):
		_timing_label.visible = _fps_acik and _PERF_DIAG_TIMING_ACIK
		if _PERF_DIAG_TIMING_ACIK:
			_timing_label.text = _timing_overlay_metni()
	return _PERF_DIAG_TIMING_ACIK

func perf_timing_frame_basla() -> void:
	if not _PERF_DIAG_TIMING_ACIK:
		return
	for k in _timing_us.keys():
		_timing_us[k] = 0

func perf_timing_basla() -> int:
	if not _PERF_DIAG_TIMING_ACIK:
		return -1
	return Time.get_ticks_usec()

func perf_timing_ekle(key: String, t0: int) -> void:
	if t0 < 0:
		return
	_timing_us[key] = int(_timing_us.get(key, 0)) + (Time.get_ticks_usec() - t0)

func perf_timing_us_ekle(key: String, us: int) -> void:
	if not _PERF_DIAG_TIMING_ACIK or us <= 0:
		return
	_timing_us[key] = int(_timing_us.get(key, 0)) + us

func perf_timing_combat_topla() -> void:
	if not _PERF_DIAG_TIMING_ACIK:
		return
	_timing_us["combat"] = (
		int(_timing_us.get("combat_hareket", 0))
		+ int(_timing_us.get("combat_mesafe", 0))
		+ int(_timing_us.get("combat_yol", 0))
	)

func tick_fps_overlay() -> void:
	if not _fps_acik or not is_instance_valid(_fps_label):
		return
	_fps_label.text = _fps_overlay_metni()
	if _PERF_DIAG_TIMING_ACIK and is_instance_valid(_timing_label):
		_timing_label.text = _timing_overlay_metni()

func _fps_overlay_metni() -> String:
	return "FPS: %d  |  Prop:%s Golge:%s SSAO:%s Asker:%s | Fog:%s Mini:%s Zem:%s VP:%s" % [
		Engine.get_frames_per_second(),
		_perf_diag_etiket("prop"),
		_perf_diag_etiket("golge"),
		_perf_diag_etiket("ssao"),
		_perf_diag_etiket("asker"),
		_perf_diag_etiket("fog"),
		_perf_diag_etiket("minimap"),
		_perf_diag_etiket("zemin"),
		_perf_diag_etiket("viewport"),
	]

func _timing_overlay_metni() -> String:
	return (
		"Fog: %.1fms | Minimap: %.1fms | Combat: %.1fms | UI: %.1fms | Zemin3d: %.1fms\n"
		+ "Hareket: %.1fms | Mesafe: %.1fms | Yol: %.1fms | Gorunurluk: %.1fms"
	) % [
		float(_timing_us.get("fog", 0)) / 1000.0,
		float(_timing_us.get("minimap", 0)) / 1000.0,
		float(_timing_us.get("combat", 0)) / 1000.0,
		float(_timing_us.get("ui", 0)) / 1000.0,
		float(_timing_us.get("zemin3d", 0)) / 1000.0,
		float(_timing_us.get("combat_hareket", 0)) / 1000.0,
		float(_timing_us.get("combat_mesafe", 0)) / 1000.0,
		float(_timing_us.get("combat_yol", 0)) / 1000.0,
		float(_timing_us.get("combat_gorunurluk", 0)) / 1000.0,
	]

func _perf_diag_etiket(k: String) -> String:
	return "ACIK" if bool(_perf_diag_status.get(k, true)) else "KAPALI"

func begin_unit_detail_hover(tip: Dictionary) -> void:
	_detail_popup.begin_hover(tip)

func end_unit_detail_hover() -> void:
	_detail_popup.end_hover()

func sync_unit_detail_hover_visibility() -> void:
	_detail_popup.sync_visibility()

func reposition_unit_detail_popup() -> void:
	_detail_popup.reposition()

# === Battle panel ===

func get_hazirlik_paneli() -> Array:
	return hazirlik_paneli

func get_hazirlik_aktif_tab() -> String:
	return hazirlik_aktif_tab

func get_hazirlik_tab_gruplari() -> Dictionary:
	return hazirlik_tab_gruplari

func get_hazirlik_tab_butonlari() -> Dictionary:
	return hazirlik_tab_butonlari

func get_hazirlik_tab_container_map() -> Dictionary:
	return hazirlik_tab_container_map

func get_savas_paneli() -> Array:
	return savas_paneli

func get_hiz_tek_btn() -> Button:
	return hiz_tek_btn

func clear_battle_panel() -> void:
	for el in savas_paneli:
		if is_instance_valid(el):
			el.queue_free()
	savas_paneli.clear()
	hiz_tek_btn = null

func add_battle_panel_element(node: Control) -> void:
	var savas_icerik_vbox = _layout.get_savas_icerik_vbox()
	if savas_icerik_vbox == null:
		return
	savas_icerik_vbox.add_child(node)
	savas_paneli.append(node)

func register_battle_panel_widget(node: Control) -> void:
	savas_paneli.append(node)

func build_battle_panel_skeleton(_ult_pressed: Callable) -> void:
	if _layout.get_savas_icerik_vbox() == null:
		return

	var bilgi = Label.new()
	bilgi.name = "Label_SavasBilgi"
	bilgi.text = "Envanter sec → haritaya tikla"
	add_battle_panel_element(bilgi)

	var ust_durum_satir = HBoxContainer.new()
	ust_durum_satir.name = "SavasKaynakSatir"
	add_battle_panel_element(ust_durum_satir)
	savas_kaynak_satir = ust_durum_satir
	savas_kaynak_satir.visible = false

	var altin_l = Label.new()
	altin_l.name = "Label_Altin"
	altin_l.text = "30🪙 | G0"
	ust_durum_satir.add_child(altin_l)
	register_battle_panel_widget(altin_l)

	var durum_l = Label.new()
	durum_l.name = "Label_Durum"
	durum_l.text = "M100 | Acik | U0%"
	ust_durum_satir.add_child(durum_l)
	register_battle_panel_widget(durum_l)

	# ULT komutu sagdaki komut modulu icindeki butonlardan yonetiliyor.

func build_battle_panel_footer(speed_pressed: Callable) -> void:
	if _layout.get_savas_icerik_vbox() == null:
		return

	var hiz_satir = HBoxContainer.new()
	hiz_satir.alignment = BoxContainer.ALIGNMENT_END
	add_battle_panel_element(hiz_satir)

	hiz_tek_btn = Button.new()
	hiz_tek_btn.name = "HizBtn"
	hiz_tek_btn.custom_minimum_size = Vector2(120, 30)
	hiz_tek_btn.text = "Hiz: 1x"
	if speed_pressed.is_valid():
		hiz_tek_btn.pressed.connect(speed_pressed)
	hiz_satir.add_child(hiz_tek_btn)
	register_battle_panel_widget(hiz_tek_btn)

	var mac_ozet = Label.new()
	mac_ozet.name = "Label_MacOzeti"
	mac_ozet.text = ""
	add_battle_panel_element(mac_ozet)

func update_hud(snapshot: Dictionary) -> void:
	var os_l = get_node_by_name("Label_Osmanli") as Label
	if os_l != null:
		os_l.text = "⚔ Osmanli: " + str(snapshot.get("osmanli_puan", 0)) + "/" + str(snapshot.get("kazanma_puani", 0))
	var dr_l = get_node_by_name("Label_DoguRoma") as Label
	if dr_l != null:
		dr_l.text = "Dogu Roma: " + str(snapshot.get("dogu_roma_puan", 0)) + "/" + str(snapshot.get("kazanma_puani", 0)) + " 🛡 | 🪙" + str(snapshot.get("dogu_roma_altini", 0))
	var durum_l = get_node_by_name("Label_Durum") as Label
	var altin_l = get_node_by_name("Label_Altin") as Label
	var hazirlik = snapshot.get("hazirlik_fazi", true)
	var ust_bilgi_kaynak_label = _layout.get_ust_bilgi_kaynak_label()
	if not hazirlik:
		var altin_metin = str(snapshot.get("osmanli_altin", 0)) + "🪙 | G" + str(snapshot.get("gelisim_altin", 0))
		var durum_metin = "M" + str(int(snapshot.get("moral", 0))) + " | " + str(snapshot.get("hava", "")) + " | U" + str(int(snapshot.get("ult_yuzde", 0))) + "%"
		if altin_l != null:
			altin_l.text = altin_metin
		if durum_l != null:
			durum_l.text = durum_metin
		if ust_bilgi_kaynak_label != null:
			ust_bilgi_kaynak_label.text = altin_metin + " " + durum_metin
	var ust_bilgi_bari = get_node_by_name("UstBilgiBari") as PanelContainer
	if ust_bilgi_bari != null:
		ust_bilgi_bari.visible = not hazirlik
	var hedefler_paneli = _layout.get_hedefler_paneli()
	if hedefler_paneli == null:
		hedefler_paneli = get_node_by_name("HedeflerPaneli") as PanelContainer
	if hedefler_paneli != null:
		hedefler_paneli.visible = not hazirlik
	if savas_kaynak_satir == null:
		savas_kaynak_satir = get_node_by_name("SavasKaynakSatir") as HBoxContainer
	if savas_kaynak_satir != null:
		savas_kaynak_satir.visible = false
	if hazirlik:
		var round_l = get_node_by_name("Label_Round") as Label
		if round_l != null:
			round_l.text = "HAZIRLIK"
		var sure_l = get_node_by_name("Label_Sure") as Label
		if sure_l != null:
			sure_l.text = "Kalan: " + str(int(snapshot.get("kalan_sure", 0.0))) + "s"
	else:
		var round_l2 = get_node_by_name("Label_Round") as Label
		if round_l2 != null:
			round_l2.text = "SAVAS DEVAM EDIYOR"
		var kalan = float(snapshot.get("kalan_sure", 0.0))
		var dk = int(kalan) / 60
		var sn = int(kalan) % 60
		var sure_l2 = get_node_by_name("Label_Sure") as Label
		if sure_l2 != null:
			sure_l2.text = str(dk) + ":" + str(sn).pad_zeros(2)

func refresh_speed_button(multiplier: float) -> void:
	if hiz_tek_btn == null:
		return
	hiz_tek_btn.text = "Hiz: " + str(int(multiplier)) + "x"

func set_game_over_round(text: String) -> void:
	var round_l = get_node_by_name("Label_Round") as Label
	if round_l != null:
		round_l.text = text

func show_game_over_panel(summary_text: String) -> void:
	for el in savas_paneli:
		if is_instance_valid(el) and el.name != "Label_MacOzeti":
			el.visible = false
	var retry_btn = get_node_by_name("TekrarOynaBtn") as Button
	if retry_btn != null:
		retry_btn.visible = true
	var ozet_l = get_node_by_name("Label_MacOzeti") as Label
	if ozet_l != null:
		ozet_l.text = summary_text
		ozet_l.visible = true

# === Preparation panel ===

func build_preparation_panel() -> void:
	var hazirlik_tabs_row = _layout.get_hazirlik_tabs_row()
	var hazirlik_tabs_content = _layout.get_hazirlik_tabs_content()
	if hazirlik_tabs_row == null or hazirlik_tabs_content == null:
		return
	hazirlik_tab_butonlari.clear()
	hazirlik_tab_container_map.clear()
	hazirlik_tab_gruplari = {"genel": [], "ordu": [], "taktik": []}
	hazirlik_paneli.clear()
	var tablar = [
		{"id": "genel", "text": "Genel"},
		{"id": "ordu", "text": "Ordu"},
		{"id": "taktik", "text": "Taktik"},
	]
	var tab_content_holder = VBoxContainer.new()
	hazirlik_tabs_content.add_child(tab_content_holder)
	for t in tablar:
		var tbtn = Button.new()
		tbtn.text = t["text"]
		tbtn.custom_minimum_size = Vector2(92, 26)
		tbtn.add_theme_font_size_override("font_size", 10)
		var tab_id = t["id"]
		tbtn.pressed.connect(func(): switch_preparation_tab(tab_id))
		hazirlik_tabs_row.add_child(tbtn)
		hazirlik_paneli.append(tbtn)
		hazirlik_tab_butonlari[tab_id] = tbtn
		var tbox = VBoxContainer.new()
		tbox.visible = false
		tab_content_holder.add_child(tbox)
		hazirlik_tab_container_map[tab_id] = tbox
	switch_preparation_tab("genel")

func add_preparation_element(tab: String, node: Control) -> void:
	var parent = hazirlik_tab_container_map.get(tab, null)
	if parent == null:
		parent = _layout.get_hazirlik_tabs_content()
	parent.add_child(node)
	hazirlik_paneli.append(node)
	if hazirlik_tab_gruplari.has(tab):
		hazirlik_tab_gruplari[tab].append(node)

func register_preparation_widget(node: Control, tab: String = "") -> void:
	hazirlik_paneli.append(node)
	if tab != "" and hazirlik_tab_gruplari.has(tab):
		hazirlik_tab_gruplari[tab].append(node)

func add_preparation_footer(node: Control) -> void:
	var hazirlik_tabs_content = _layout.get_hazirlik_tabs_content()
	if hazirlik_tabs_content == null:
		return
	hazirlik_tabs_content.add_child(node)
	hazirlik_paneli.append(node)

func switch_preparation_tab(tab: String) -> void:
	if not hazirlik_tab_gruplari.has(tab):
		return
	end_unit_detail_hover()
	hazirlik_aktif_tab = tab
	for t in hazirlik_tab_container_map:
		var kutu = hazirlik_tab_container_map[t]
		if is_instance_valid(kutu):
			kutu.visible = t == tab
	for t in hazirlik_tab_gruplari:
		for el in hazirlik_tab_gruplari[t]:
			if is_instance_valid(el):
				el.visible = t == tab
	for t in hazirlik_tab_butonlari:
		var btn = hazirlik_tab_butonlari[t]
		if is_instance_valid(btn):
			btn.modulate = Color(1.4, 1.4, 1.0) if t == tab else Color(1, 1, 1)
