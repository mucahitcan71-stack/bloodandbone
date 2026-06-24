extends RefCounted
class_name HudComposer

const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudCommands = preload("res://scripts/ui/hud_commands.gd")
const HudSelectedUnitPanel = preload("res://scripts/ui/hud_selected_unit.gd")
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")

const BOTTOM_MODULE_H := 108
const MODULE_GAP := 10

func _apply_module_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", HudStyle.module_panel_style())

func _apply_right_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", HudStyle.right_panel_style())

func _module_margin() -> MarginContainer:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	return margin

func compose_battle_wireframe(deps: Dictionary) -> Dictionary:
	var ui_system = deps.get("ui_system")
	var ui_node = deps.get("ui_node") as Callable
	var envanter_grid = deps.get("envanter_grid")
	var envanter_scroll = deps.get("envanter_scroll")
	var on_command_pressed = deps.get("on_command_pressed") as Callable
	if ui_system == null or not ui_node.is_valid():
		return {}
	var savas_icerik = ui_node.call("SavasIcerik") as VBoxContainer
	var env_baslik = ui_node.call("Label_Envanter") as Label
	var ult_btn = ui_node.call("UltBtn") as Button
	if savas_icerik == null or envanter_grid == null or env_baslik == null:
		return {}

	var savas_scroll = savas_icerik.get_parent() as ScrollContainer
	if savas_scroll != null:
		savas_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var hud_main = VBoxContainer.new()
	hud_main.name = "SavasHudMain"
	hud_main.add_theme_constant_override("separation", 0)
	hud_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_system.add_battle_panel_element(hud_main)
	savas_icerik.move_child(hud_main, 0)

	var alt_satir = HBoxContainer.new()
	alt_satir.name = "SavasHudAltSatir"
	alt_satir.add_theme_constant_override("separation", MODULE_GAP)
	alt_satir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alt_satir.custom_minimum_size = Vector2(0, BOTTOM_MODULE_H)
	hud_main.add_child(alt_satir)
	ui_system.register_battle_panel_widget(alt_satir)

	var sol_modul = PanelContainer.new()
	sol_modul.name = "HudSolModul"
	sol_modul.custom_minimum_size = Vector2(288, BOTTOM_MODULE_H)
	_apply_module_style(sol_modul)
	alt_satir.add_child(sol_modul)
	ui_system.register_battle_panel_widget(sol_modul)
	var sol_margin = _module_margin()
	sol_modul.add_child(sol_margin)
	var sol_vbox = VBoxContainer.new()
	sol_vbox.add_theme_constant_override("separation", 3)
	sol_margin.add_child(sol_vbox)
	HudSelectedUnitPanel.build(sol_vbox)

	var orta_modul = PanelContainer.new()
	orta_modul.name = "HudOrtaModul"
	orta_modul.custom_minimum_size = Vector2(520, BOTTOM_MODULE_H)
	orta_modul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_module_style(orta_modul)
	alt_satir.add_child(orta_modul)
	ui_system.register_battle_panel_widget(orta_modul)
	var orta_margin = _module_margin()
	orta_modul.add_child(orta_margin)
	var orta_vbox = VBoxContainer.new()
	orta_vbox.add_theme_constant_override("separation", 4)
	orta_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orta_margin.add_child(orta_vbox)
	env_baslik.reparent(orta_vbox)
	env_baslik.text = "BIRLIKLER"
	env_baslik.add_theme_font_size_override("font_size", 9)
	env_baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	if envanter_scroll != null:
		envanter_scroll.reparent(orta_vbox)
		envanter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		envanter_scroll.custom_minimum_size = Vector2(0, HudInventory.card_height() + 4)
	else:
		envanter_grid.reparent(orta_vbox)

	var sag_modul = PanelContainer.new()
	sag_modul.name = "HudSagModul"
	sag_modul.custom_minimum_size = Vector2(148, BOTTOM_MODULE_H)
	_apply_module_style(sag_modul)
	alt_satir.add_child(sag_modul)
	ui_system.register_battle_panel_widget(sag_modul)
	var sag_margin = _module_margin()
	sag_modul.add_child(sag_margin)
	var sag_vbox = VBoxContainer.new()
	sag_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sag_vbox.add_theme_constant_override("separation", 6)
	sag_margin.add_child(sag_vbox)
	var komut_baslik = Label.new()
	komut_baslik.text = "KOMUT"
	komut_baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	komut_baslik.add_theme_font_size_override("font_size", 9)
	komut_baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	sag_vbox.add_child(komut_baslik)
	var komut_grid = GridContainer.new()
	komut_grid.columns = 3
	komut_grid.add_theme_constant_override("h_separation", 7)
	komut_grid.add_theme_constant_override("v_separation", 7)
	sag_vbox.add_child(komut_grid)
	var komut_butonlari = {}
	for komut in HudCommands.button_definitions():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(34, 32)
		btn.text = str(komut["text"])
		btn.add_theme_font_size_override("font_size", 11)
		var komut_id = str(komut["id"])
		HudCommands.apply_button_visuals(btn, {"disabled": false, "selected": false})
		if on_command_pressed.is_valid():
			btn.pressed.connect(func(): on_command_pressed.call(komut_id))
		komut_grid.add_child(btn)
		komut_butonlari[komut_id] = btn
	if ult_btn != null:
		ult_btn.visible = false
	return {"komut_butonlari": komut_butonlari}

func update_selected_unit_card(deps: Dictionary) -> void:
	var ui_node = deps.get("ui_node") as Callable
	if not ui_node.is_valid():
		return
	HudSelectedUnitPanel.update(
		ui_node,
		deps.get("secili_birim"),
		str(deps.get("secili_komut", "")),
		deps.get("stats_fn") as Callable
	)

func update_command_buttons(buttons: Dictionary, secili_var: bool, secili_komut: String, ult_hazir: bool) -> void:
	for komut_id in buttons:
		var btn = buttons[komut_id] as Button
		if btn == null:
			continue
		var state = HudCommands.button_state(str(komut_id), secili_var, secili_komut, ult_hazir)
		btn.disabled = bool(state.get("disabled", false))
		btn.modulate = state.get("modulate", Color(1, 1, 1, 1))
		HudCommands.apply_button_visuals(btn, state)

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
	panel_sag_log_hiz.offset_left = -348
	panel_sag_log_hiz.offset_top = -372
	panel_sag_log_hiz.offset_right = -14
	panel_sag_log_hiz.offset_bottom = -236
	_apply_right_panel_style(panel_sag_log_hiz)
	for c in panel_sag_log_hiz.get_children():
		c.queue_free()
	var log_margin = MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 10)
	log_margin.add_theme_constant_override("margin_right", 10)
	log_margin.add_theme_constant_override("margin_top", 8)
	log_margin.add_theme_constant_override("margin_bottom", 8)
	panel_sag_log_hiz.add_child(log_margin)
	var log_vbox = VBoxContainer.new()
	log_vbox.add_theme_constant_override("separation", 5)
	log_margin.add_child(log_vbox)
	var savas_baslik = Label.new()
	savas_baslik.text = "SAVAS"
	savas_baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	savas_baslik.add_theme_font_size_override("font_size", 11)
	savas_baslik.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
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
		savas_bilgi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		savas_bilgi.add_theme_font_size_override("font_size", 8)
		savas_bilgi.add_theme_color_override("font_color", Color(0.87, 0.88, 0.84))
		savas_bilgi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hiz_satir = HBoxContainer.new()
	hiz_satir.alignment = BoxContainer.ALIGNMENT_END
	log_vbox.add_child(hiz_satir)
	var hiz_btn = ui_node.call("HizBtn") as Button
	if hiz_btn != null:
		hiz_btn.custom_minimum_size = Vector2(76, 22)
		hiz_btn.add_theme_font_size_override("font_size", 9)
		hiz_btn.add_theme_stylebox_override("normal", HudStyle.speed_button_style())
		hiz_btn.add_theme_stylebox_override("hover", HudStyle.command_button_hover())
		hiz_btn.add_theme_stylebox_override("pressed", HudStyle.command_button_pressed())
		hiz_btn.reparent(hiz_satir)
	panel_sag_log_hiz.visible = false
	return {
		"panel_sag_log_hiz": panel_sag_log_hiz,
		"label_sag_osmanli": label_sag_osmanli,
		"label_sag_roma": label_sag_roma,
	}
