extends RefCounted
class_name UISystem

var _root: Node2D = null
var ui_root: Control = null
var ust_bilgi_paneli: HBoxContainer = null
var hazirlik_panel_root: PanelContainer = null
var hazirlik_tabs_row: HBoxContainer = null
var hazirlik_tabs_content: VBoxContainer = null
var savas_panel_root: PanelContainer = null
var savas_icerik_vbox: VBoxContainer = null
var yan_hud_tetik: PanelContainer = null
var yan_hud_panel: PanelContainer = null
var yan_hud_icerik: VBoxContainer = null
var yan_hud_kaybol_timer: Timer = null
var _hover_birim_detay: Dictionary = {}
var _detail_text_fn: Callable
var detay_popup_timer: Timer = null
var detay_popup_panel: Panel = null
var detay_popup_label: Label = null
var hazirlik_paneli: Array = []
var hazirlik_aktif_tab: String = "genel"
var hazirlik_tab_gruplari = {"genel": [], "ordu": [], "taktik": []}
var hazirlik_tab_butonlari = {}
var hazirlik_tab_container_map = {}

func configure(root_node: Node2D) -> void:
	_root = root_node

func get_node_by_name(node_name: String) -> Node:
	if _root == null or not _root.has_node("CanvasLayer"):
		return null
	return _root.get_node("CanvasLayer").find_child(node_name, true, false)

func get_ui_root() -> Control:
	return ui_root

func get_ust_bilgi_paneli() -> HBoxContainer:
	return ust_bilgi_paneli

func get_hazirlik_panel_root() -> PanelContainer:
	return hazirlik_panel_root

func get_hazirlik_tabs_row() -> HBoxContainer:
	return hazirlik_tabs_row

func get_hazirlik_tabs_content() -> VBoxContainer:
	return hazirlik_tabs_content

func get_savas_panel_root() -> PanelContainer:
	return savas_panel_root

func get_savas_icerik_vbox() -> VBoxContainer:
	return savas_icerik_vbox

func get_yan_hud_tetik() -> PanelContainer:
	return yan_hud_tetik

func get_yan_hud_panel() -> PanelContainer:
	return yan_hud_panel

func get_yan_hud_icerik() -> VBoxContainer:
	return yan_hud_icerik

func get_yan_hud_kaybol_timer() -> Timer:
	return yan_hud_kaybol_timer

func build_side_hud() -> void:
	if ui_root == null:
		return
	yan_hud_tetik = get_node_by_name("YanHudTetik") as PanelContainer
	if yan_hud_tetik == null:
		yan_hud_tetik = PanelContainer.new()
		yan_hud_tetik.name = "YanHudTetik"
		yan_hud_tetik.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		yan_hud_tetik.offset_left = -26
		yan_hud_tetik.offset_top = -80
		yan_hud_tetik.offset_right = -6
		yan_hud_tetik.offset_bottom = 80
		yan_hud_tetik.mouse_filter = Control.MOUSE_FILTER_STOP
		ui_root.add_child(yan_hud_tetik)
	for c in yan_hud_tetik.get_children():
		c.queue_free()
	var tetik_l = Label.new()
	tetik_l.text = "◀"
	tetik_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tetik_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tetik_l.set_anchors_preset(Control.PRESET_FULL_RECT)
	yan_hud_tetik.add_child(tetik_l)

	yan_hud_panel = get_node_by_name("YanHudPanel") as PanelContainer
	if yan_hud_panel == null:
		yan_hud_panel = PanelContainer.new()
		yan_hud_panel.name = "YanHudPanel"
		yan_hud_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		yan_hud_panel.offset_left = -270
		yan_hud_panel.offset_top = -96
		yan_hud_panel.offset_right = -30
		yan_hud_panel.offset_bottom = 96
		yan_hud_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		ui_root.add_child(yan_hud_panel)
	for c in yan_hud_panel.get_children():
		c.queue_free()
	var yan_margin = MarginContainer.new()
	yan_margin.add_theme_constant_override("margin_left", 10)
	yan_margin.add_theme_constant_override("margin_right", 10)
	yan_margin.add_theme_constant_override("margin_top", 8)
	yan_margin.add_theme_constant_override("margin_bottom", 8)
	yan_hud_panel.add_child(yan_margin)
	yan_hud_icerik = VBoxContainer.new()
	yan_hud_icerik.name = "YanHudIcerik"
	yan_margin.add_child(yan_hud_icerik)

	var os_l = get_node_by_name("Label_Osmanli")
	if os_l != null:
		os_l.reparent(yan_hud_icerik)
	var dr_l = get_node_by_name("Label_DoguRoma")
	if dr_l != null:
		dr_l.reparent(yan_hud_icerik)
	var round_l = get_node_by_name("Label_Round")
	if round_l != null:
		round_l.reparent(yan_hud_icerik)
	var sure_l = get_node_by_name("Label_Sure")
	if sure_l != null:
		sure_l.reparent(yan_hud_icerik)

	if ust_bilgi_paneli != null:
		ust_bilgi_paneli.visible = false

	if yan_hud_kaybol_timer == null:
		yan_hud_kaybol_timer = Timer.new()
		yan_hud_kaybol_timer.one_shot = true
		yan_hud_kaybol_timer.wait_time = 1.2
		yan_hud_kaybol_timer.timeout.connect(hide_side_hud)
		_root.add_child(yan_hud_kaybol_timer)

	if not yan_hud_tetik.mouse_entered.is_connected(show_side_hud):
		yan_hud_tetik.mouse_entered.connect(show_side_hud)
	if not yan_hud_tetik.mouse_exited.is_connected(schedule_side_hud_hide):
		yan_hud_tetik.mouse_exited.connect(schedule_side_hud_hide)
	if not yan_hud_panel.mouse_entered.is_connected(show_side_hud):
		yan_hud_panel.mouse_entered.connect(show_side_hud)
	if not yan_hud_panel.mouse_exited.is_connected(schedule_side_hud_hide):
		yan_hud_panel.mouse_exited.connect(schedule_side_hud_hide)

	yan_hud_panel.visible = false

func show_side_hud() -> void:
	if yan_hud_panel != null:
		yan_hud_panel.visible = true
	if yan_hud_kaybol_timer != null:
		yan_hud_kaybol_timer.stop()

func schedule_side_hud_hide() -> void:
	if yan_hud_kaybol_timer != null:
		yan_hud_kaybol_timer.start()

func hide_side_hud() -> void:
	if yan_hud_panel != null:
		yan_hud_panel.visible = false

func set_unit_detail_text_provider(callback: Callable) -> void:
	_detail_text_fn = callback

func get_detay_popup_panel() -> Panel:
	return detay_popup_panel

func get_detay_popup_label() -> Label:
	return detay_popup_label

func get_detay_popup_timer() -> Timer:
	return detay_popup_timer

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

func build_preparation_panel() -> void:
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
		tbtn.custom_minimum_size = Vector2(110, 32)
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
		parent = hazirlik_tabs_content
	parent.add_child(node)
	hazirlik_paneli.append(node)
	if hazirlik_tab_gruplari.has(tab):
		hazirlik_tab_gruplari[tab].append(node)

func register_preparation_widget(node: Control, tab: String = "") -> void:
	hazirlik_paneli.append(node)
	if tab != "" and hazirlik_tab_gruplari.has(tab):
		hazirlik_tab_gruplari[tab].append(node)

func add_preparation_footer(node: Control) -> void:
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

func build_unit_detail_popup() -> void:
	detay_popup_timer = Timer.new()
	detay_popup_timer.one_shot = true
	detay_popup_timer.wait_time = 0.5
	detay_popup_timer.timeout.connect(_on_unit_detail_hover_timeout)
	_root.add_child(detay_popup_timer)

	detay_popup_panel = Panel.new()
	detay_popup_panel.name = "Panel_BirimDetayPopup"
	detay_popup_panel.position = Vector2(20, 20)
	detay_popup_panel.size = Vector2(340, 128)
	detay_popup_panel.visible = false
	_root.get_node("CanvasLayer").add_child(detay_popup_panel)

	detay_popup_label = Label.new()
	detay_popup_label.position = Vector2(8, 8)
	detay_popup_label.size = Vector2(324, 112)
	detay_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detay_popup_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detay_popup_panel.add_child(detay_popup_label)

func begin_unit_detail_hover(tip: Dictionary) -> void:
	_hover_birim_detay = tip
	if detay_popup_timer != null:
		detay_popup_timer.stop()
		detay_popup_timer.start()

func end_unit_detail_hover() -> void:
	_hover_birim_detay = {}
	if detay_popup_timer != null:
		detay_popup_timer.stop()
	if detay_popup_panel != null:
		detay_popup_panel.visible = false

func show_unit_detail_popup(metin: String) -> void:
	if detay_popup_panel == null or detay_popup_label == null:
		return
	detay_popup_label.text = metin
	reposition_unit_detail_popup()
	detay_popup_panel.visible = true

func reposition_unit_detail_popup() -> void:
	if detay_popup_panel == null or _root == null:
		return
	var mouse = _root.get_viewport().get_mouse_position() + Vector2(16, 16)
	var view = _root.get_viewport_rect().size
	var panel_size = detay_popup_panel.size
	if mouse.x + panel_size.x > view.x:
		mouse.x = view.x - panel_size.x - 8
	if mouse.y + panel_size.y > view.y:
		mouse.y = view.y - panel_size.y - 8
	detay_popup_panel.position = mouse

func _on_unit_detail_hover_timeout() -> void:
	if _hover_birim_detay.is_empty():
		return
	if not _detail_text_fn.is_valid():
		return
	show_unit_detail_popup(_detail_text_fn.call(_hover_birim_detay))

func build_container_infrastructure() -> void:
	ui_root = get_node_by_name("UIRoot") as Control
	ust_bilgi_paneli = get_node_by_name("UstBilgiPaneli") as HBoxContainer
	hazirlik_panel_root = get_node_by_name("HazirlikPaneli") as PanelContainer
	hazirlik_tabs_row = get_node_by_name("HazirlikTabsRow") as HBoxContainer
	hazirlik_tabs_content = get_node_by_name("HazirlikTabsContent") as VBoxContainer
	savas_panel_root = get_node_by_name("SavasPaneli") as PanelContainer
	savas_icerik_vbox = get_node_by_name("SavasIcerik") as VBoxContainer
	if savas_icerik_vbox != null:
		var savas_parent = savas_icerik_vbox.get_parent()
		if savas_parent != null and not (savas_parent is ScrollContainer):
			savas_parent.remove_child(savas_icerik_vbox)
			var savas_scroll = ScrollContainer.new()
			savas_scroll.name = "SavasScroll"
			savas_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			savas_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			savas_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			savas_parent.add_child(savas_scroll)
			savas_scroll.add_child(savas_icerik_vbox)
	if ui_root != null and ust_bilgi_paneli != null and hazirlik_panel_root != null and hazirlik_tabs_row != null and hazirlik_tabs_content != null and savas_panel_root != null and savas_icerik_vbox != null:
		_savas_panel_alt_konumla()
		return

	ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.get_node("CanvasLayer").add_child(ui_root)

	ust_bilgi_paneli = HBoxContainer.new()
	ust_bilgi_paneli.name = "UstBilgiPaneli"
	ust_bilgi_paneli.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ust_bilgi_paneli.offset_left = 20
	ust_bilgi_paneli.offset_top = 10
	ust_bilgi_paneli.offset_right = -20
	ust_bilgi_paneli.offset_bottom = 66
	ui_root.add_child(ust_bilgi_paneli)

	var left = VBoxContainer.new()
	left.name = "UstBilgiLeft"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust_bilgi_paneli.add_child(left)
	var center = VBoxContainer.new()
	center.name = "UstBilgiCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	ust_bilgi_paneli.add_child(center)
	var right = VBoxContainer.new()
	right.name = "UstBilgiRight"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	ust_bilgi_paneli.add_child(right)

	var os_label = get_node_by_name("Label_Osmanli")
	if os_label != null:
		os_label.reparent(left)
	var dr_label = get_node_by_name("Label_DoguRoma")
	if dr_label != null:
		dr_label.reparent(right)
	var round_label = get_node_by_name("Label_Round")
	if round_label != null:
		round_label.reparent(center)
	var sure_label = get_node_by_name("Label_Sure")
	if sure_label != null:
		sure_label.reparent(center)

	hazirlik_panel_root = PanelContainer.new()
	hazirlik_panel_root.name = "HazirlikPaneli"
	hazirlik_panel_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hazirlik_panel_root.offset_left = 20
	hazirlik_panel_root.offset_top = -250
	hazirlik_panel_root.offset_right = -20
	hazirlik_panel_root.offset_bottom = -20
	ui_root.add_child(hazirlik_panel_root)

	var hazirlik_margin = MarginContainer.new()
	hazirlik_margin.name = "HazirlikMargin"
	hazirlik_margin.add_theme_constant_override("margin_left", 14)
	hazirlik_margin.add_theme_constant_override("margin_right", 14)
	hazirlik_margin.add_theme_constant_override("margin_top", 10)
	hazirlik_margin.add_theme_constant_override("margin_bottom", 10)
	hazirlik_panel_root.add_child(hazirlik_margin)

	var hazirlik_main = VBoxContainer.new()
	hazirlik_main.name = "HazirlikMain"
	hazirlik_margin.add_child(hazirlik_main)
	hazirlik_tabs_row = HBoxContainer.new()
	hazirlik_tabs_row.name = "HazirlikTabsRow"
	hazirlik_main.add_child(hazirlik_tabs_row)
	hazirlik_tabs_content = VBoxContainer.new()
	hazirlik_tabs_content.name = "HazirlikTabsContent"
	hazirlik_main.add_child(hazirlik_tabs_content)

	savas_panel_root = PanelContainer.new()
	savas_panel_root.name = "SavasPaneli"
	ui_root.add_child(savas_panel_root)
	_savas_panel_alt_konumla()

	var savas_margin = MarginContainer.new()
	savas_margin.name = "SavasMargin"
	savas_margin.add_theme_constant_override("margin_left", 14)
	savas_margin.add_theme_constant_override("margin_right", 14)
	savas_margin.add_theme_constant_override("margin_top", 10)
	savas_margin.add_theme_constant_override("margin_bottom", 10)
	savas_panel_root.add_child(savas_margin)
	var savas_scroll = ScrollContainer.new()
	savas_scroll.name = "SavasScroll"
	savas_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	savas_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	savas_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	savas_margin.add_child(savas_scroll)
	savas_icerik_vbox = VBoxContainer.new()
	savas_icerik_vbox.name = "SavasIcerik"
	savas_scroll.add_child(savas_icerik_vbox)

func optimize_fonts(font_size: int, extra_roots: Array = []) -> void:
	if ui_root != null:
		_apply_font_size(ui_root, font_size)
	for node in extra_roots:
		if is_instance_valid(node):
			_apply_font_size(node, font_size)

func _savas_panel_alt_konumla() -> void:
	if savas_panel_root == null:
		return
	savas_panel_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	savas_panel_root.offset_left = 12
	savas_panel_root.offset_top = -310
	savas_panel_root.offset_right = -12
	savas_panel_root.offset_bottom = -8

func _apply_font_size(node: Node, font_size: int) -> void:
	if node is Label:
		(node as Label).add_theme_font_size_override("font_size", font_size)
	elif node is Button:
		(node as Button).add_theme_font_size_override("font_size", font_size)
	for c in node.get_children():
		_apply_font_size(c, font_size)
