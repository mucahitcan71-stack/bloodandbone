extends RefCounted
class_name HudComposer

const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudCommands = preload("res://scripts/ui/hud_commands.gd")

func _apply_module_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", HudStyle.module_panel_style())

func _apply_right_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", HudStyle.right_panel_style())

func compose_battle_wireframe(deps: Dictionary) -> Dictionary:
	var ui_system = deps.get("ui_system")
	var ui_node = deps.get("ui_node") as Callable
	var envanter_grid = deps.get("envanter_grid")
	var envanter_scroll = deps.get("envanter_scroll")
	var on_command_pressed = deps.get("on_command_pressed") as Callable
	if ui_system == null or not ui_node.is_valid():
		return {}
	var savas_icerik = ui_node.call("SavasIcerik") as VBoxContainer
	var savas_bilgi = ui_node.call("Label_SavasBilgi") as Label
	var env_baslik = ui_node.call("Label_Envanter") as Label
	var ult_btn = ui_node.call("UltBtn") as Button
	if savas_icerik == null or savas_bilgi == null or envanter_grid == null or env_baslik == null:
		return {}

	var hud_main = VBoxContainer.new()
	hud_main.name = "SavasHudMain"
	hud_main.add_theme_constant_override("separation", 6)
	hud_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_system.add_battle_panel_element(hud_main)
	savas_icerik.move_child(hud_main, 0)

	savas_bilgi.reparent(hud_main)
	savas_bilgi.add_theme_font_size_override("font_size", 10)
	savas_bilgi.add_theme_color_override("font_color", Color(0.9, 0.9, 0.86))

	var alt_satir = HBoxContainer.new()
	alt_satir.name = "SavasHudAltSatir"
	alt_satir.add_theme_constant_override("separation", 6)
	alt_satir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_main.add_child(alt_satir)
	ui_system.register_battle_panel_widget(alt_satir)

	var sol_modul = PanelContainer.new()
	sol_modul.name = "HudSolModul"
	sol_modul.custom_minimum_size = Vector2(182, 96)
	_apply_module_style(sol_modul)
	alt_satir.add_child(sol_modul)
	ui_system.register_battle_panel_widget(sol_modul)
	var sol_margin = MarginContainer.new()
	sol_margin.add_theme_constant_override("margin_left", 6)
	sol_margin.add_theme_constant_override("margin_right", 6)
	sol_margin.add_theme_constant_override("margin_top", 6)
	sol_margin.add_theme_constant_override("margin_bottom", 6)
	sol_modul.add_child(sol_margin)
	var sol_vbox = VBoxContainer.new()
	sol_vbox.add_theme_constant_override("separation", 4)
	sol_margin.add_child(sol_vbox)
	env_baslik.reparent(sol_vbox)
	env_baslik.add_theme_font_size_override("font_size", 10)

	var orta_modul = PanelContainer.new()
	orta_modul.name = "HudOrtaModul"
	orta_modul.custom_minimum_size = Vector2(420, 96)
	orta_modul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_module_style(orta_modul)
	alt_satir.add_child(orta_modul)
	ui_system.register_battle_panel_widget(orta_modul)
	var orta_margin = MarginContainer.new()
	orta_margin.add_theme_constant_override("margin_left", 6)
	orta_margin.add_theme_constant_override("margin_right", 6)
	orta_margin.add_theme_constant_override("margin_top", 6)
	orta_margin.add_theme_constant_override("margin_bottom", 6)
	orta_modul.add_child(orta_margin)
	if envanter_scroll != null:
		envanter_scroll.reparent(orta_margin)
	else:
		envanter_grid.reparent(orta_margin)

	var sag_modul = PanelContainer.new()
	sag_modul.name = "HudSagModul"
	sag_modul.custom_minimum_size = Vector2(132, 96)
	_apply_module_style(sag_modul)
	alt_satir.add_child(sag_modul)
	ui_system.register_battle_panel_widget(sag_modul)
	var sag_margin = MarginContainer.new()
	sag_margin.add_theme_constant_override("margin_left", 6)
	sag_margin.add_theme_constant_override("margin_right", 6)
	sag_margin.add_theme_constant_override("margin_top", 6)
	sag_margin.add_theme_constant_override("margin_bottom", 6)
	sag_modul.add_child(sag_margin)
	var sag_vbox = VBoxContainer.new()
	sag_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sag_vbox.add_theme_constant_override("separation", 5)
	sag_margin.add_child(sag_vbox)
	var komut_baslik = Label.new()
	komut_baslik.text = "KOMUT"
	komut_baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	komut_baslik.add_theme_font_size_override("font_size", 9)
	komut_baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	sag_vbox.add_child(komut_baslik)
	var komut_grid = GridContainer.new()
	komut_grid.columns = 3
	komut_grid.add_theme_constant_override("h_separation", 3)
	komut_grid.add_theme_constant_override("v_separation", 3)
	sag_vbox.add_child(komut_grid)
	var komut_butonlari = {}
	for komut in HudCommands.button_definitions():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(28, 26)
		btn.text = str(komut["text"])
		var komut_id = str(komut["id"])
		if on_command_pressed.is_valid():
			btn.pressed.connect(func(): on_command_pressed.call(komut_id))
		komut_grid.add_child(btn)
		komut_butonlari[komut_id] = btn
	if ult_btn != null:
		ult_btn.visible = false
	return {"komut_butonlari": komut_butonlari}

func compose_right_panel(ui_root: Control, ui_node: Callable, kazanma_puani: int) -> Dictionary:
	if ui_root == null or not ui_node.is_valid():
		return {}
	var panel_sag_savas_bilgi = ui_node.call("PanelSagSavasBilgi") as PanelContainer
	if panel_sag_savas_bilgi != null:
		panel_sag_savas_bilgi.queue_free()

	var panel_sag_log_hiz = ui_node.call("PanelSagLogHiz") as PanelContainer
	if panel_sag_log_hiz == null:
		panel_sag_log_hiz = PanelContainer.new()
		panel_sag_log_hiz.name = "PanelSagLogHiz"
		ui_root.add_child(panel_sag_log_hiz)
	panel_sag_log_hiz.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel_sag_log_hiz.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_sag_log_hiz.offset_left = -340
	panel_sag_log_hiz.offset_top = -224
	panel_sag_log_hiz.offset_right = -12
	panel_sag_log_hiz.offset_bottom = -8
	_apply_right_panel_style(panel_sag_log_hiz)
	for c in panel_sag_log_hiz.get_children():
		c.queue_free()
	var log_margin = MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 9)
	log_margin.add_theme_constant_override("margin_right", 9)
	log_margin.add_theme_constant_override("margin_top", 7)
	log_margin.add_theme_constant_override("margin_bottom", 7)
	panel_sag_log_hiz.add_child(log_margin)
	var log_vbox = VBoxContainer.new()
	log_vbox.add_theme_constant_override("separation", 4)
	log_margin.add_child(log_vbox)
	var savas_baslik = Label.new()
	savas_baslik.text = "SAVAS"
	savas_baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	savas_baslik.add_theme_font_size_override("font_size", 9)
	savas_baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	savas_baslik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_vbox.add_child(savas_baslik)
	log_vbox.add_child(HSeparator.new())
	var label_sag_osmanli = Label.new()
	label_sag_osmanli.text = "Skor OSM 0/0 • ROM 0/0"
	label_sag_osmanli.add_theme_font_size_override("font_size", 8)
	label_sag_osmanli.add_theme_color_override("font_color", Color(0.92, 0.78, 0.3))
	label_sag_osmanli.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_vbox.add_child(label_sag_osmanli)
	var label_sag_roma = Label.new()
	label_sag_roma.text = "Moral OSM 0 • ROM 0"
	label_sag_roma.add_theme_font_size_override("font_size", 8)
	label_sag_roma.add_theme_color_override("font_color", Color(0.78, 0.68, 0.95))
	label_sag_roma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_vbox.add_child(label_sag_roma)
	var puan_hedef = Label.new()
	puan_hedef.text = "Hedef Puan: " + str(kazanma_puani)
	puan_hedef.add_theme_font_size_override("font_size", 8)
	puan_hedef.add_theme_color_override("font_color", Color(0.82, 0.83, 0.8))
	puan_hedef.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_vbox.add_child(puan_hedef)
	var log_baslik = Label.new()
	log_baslik.text = "BILDIRIM"
	log_baslik.add_theme_font_size_override("font_size", 8)
	log_baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	log_baslik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_vbox.add_child(log_baslik)
	log_vbox.add_child(HSeparator.new())
	var savas_bilgi = ui_node.call("Label_SavasBilgi") as Label
	if savas_bilgi != null:
		savas_bilgi.reparent(log_vbox)
		savas_bilgi.add_theme_font_size_override("font_size", 8)
		savas_bilgi.add_theme_color_override("font_color", Color(0.87, 0.88, 0.84))
		savas_bilgi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hiz_satir = HBoxContainer.new()
	hiz_satir.alignment = BoxContainer.ALIGNMENT_END
	log_vbox.add_child(hiz_satir)
	var hiz_btn = ui_node.call("HizBtn") as Button
	if hiz_btn != null:
		hiz_btn.custom_minimum_size = Vector2(92, 26)
		hiz_btn.reparent(hiz_satir)
	panel_sag_log_hiz.visible = false
	return {
		"panel_sag_log_hiz": panel_sag_log_hiz,
		"label_sag_osmanli": label_sag_osmanli,
		"label_sag_roma": label_sag_roma,
	}
