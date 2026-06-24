extends RefCounted
class_name UiLayoutBuilder
const HudStyle = preload("res://scripts/ui/hud_style.gd")

var _root: Node2D = null
var ui_root: Control = null
var ust_bilgi_paneli: HBoxContainer = null
var hazirlik_panel_root: PanelContainer = null
var hazirlik_tabs_row: HBoxContainer = null
var hazirlik_tabs_content: VBoxContainer = null
var savas_panel_root: PanelContainer = null
var savas_icerik_vbox: VBoxContainer = null
var ust_bilgi_bari: PanelContainer = null
var ust_bilgi_kaynak_label: Label = null
var hedefler_paneli: PanelContainer = null
var hedefler_label: Label = null

func configure(root_node: Node2D) -> void:
	_root = root_node

func _get_node_by_name(node_name: String) -> Node:
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

func get_ust_bilgi_kaynak_label() -> Label:
	return ust_bilgi_kaynak_label

func get_hedefler_paneli() -> PanelContainer:
	return hedefler_paneli

func build_container_infrastructure() -> void:
	ui_root = _get_node_by_name("UIRoot") as Control
	ust_bilgi_paneli = _get_node_by_name("UstBilgiPaneli") as HBoxContainer
	hazirlik_panel_root = _get_node_by_name("HazirlikPaneli") as PanelContainer
	hazirlik_tabs_row = _get_node_by_name("HazirlikTabsRow") as HBoxContainer
	hazirlik_tabs_content = _get_node_by_name("HazirlikTabsContent") as VBoxContainer
	savas_panel_root = _get_node_by_name("SavasPaneli") as PanelContainer
	savas_icerik_vbox = _get_node_by_name("SavasIcerik") as VBoxContainer
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
		_uygula_panel_stili(hazirlik_panel_root)
		_ensure_ust_bilgi_bari()
		_ensure_hedefler_paneli()
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

	var os_label = _get_node_by_name("Label_Osmanli")
	if os_label != null:
		os_label.reparent(left)
	var dr_label = _get_node_by_name("Label_DoguRoma")
	if dr_label != null:
		dr_label.reparent(right)
	var round_label = _get_node_by_name("Label_Round")
	if round_label != null:
		round_label.reparent(center)
	var sure_label = _get_node_by_name("Label_Sure")
	if sure_label != null:
		sure_label.reparent(center)

	hazirlik_panel_root = PanelContainer.new()
	hazirlik_panel_root.name = "HazirlikPaneli"
	hazirlik_panel_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hazirlik_panel_root.offset_left = 20
	hazirlik_panel_root.offset_top = -250
	hazirlik_panel_root.offset_right = -20
	hazirlik_panel_root.offset_bottom = -20
	_uygula_panel_stili(hazirlik_panel_root)
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
	_uygula_panel_stili(savas_panel_root)
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
	_ensure_ust_bilgi_bari()
	_ensure_hedefler_paneli()

func _ensure_ust_bilgi_bari() -> void:
	if ui_root == null:
		return
	ust_bilgi_bari = _get_node_by_name("UstBilgiBari") as PanelContainer
	if ust_bilgi_bari == null:
		ust_bilgi_bari = PanelContainer.new()
		ust_bilgi_bari.name = "UstBilgiBari"
		ui_root.add_child(ust_bilgi_bari)
		ui_root.move_child(ust_bilgi_bari, 0)
	ust_bilgi_bari.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ust_bilgi_bari.offset_left = 19
	ust_bilgi_bari.offset_top = 14
	ust_bilgi_bari.offset_right = -19
	ust_bilgi_bari.offset_bottom = 50
	ust_bilgi_bari.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust_bilgi_bari.add_theme_stylebox_override("panel", HudStyle.top_bar_style())
	for c in ust_bilgi_bari.get_children():
		c.queue_free()
	var bar_margin = MarginContainer.new()
	bar_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_margin.add_theme_constant_override("margin_left", 14)
	bar_margin.add_theme_constant_override("margin_right", 14)
	bar_margin.add_theme_constant_override("margin_top", 6)
	bar_margin.add_theme_constant_override("margin_bottom", 6)
	ust_bilgi_bari.add_child(bar_margin)
	var bar_row = HBoxContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_margin.add_child(bar_row)
	var logo_vbox = VBoxContainer.new()
	logo_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_vbox.add_theme_constant_override("separation", 0)
	logo_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(logo_vbox)
	var logo_label = Label.new()
	logo_label.name = "Label_UstLogo"
	logo_label.text = "BLOOD & BONE"
	logo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_label.add_theme_font_size_override("font_size", 13)
	logo_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	logo_vbox.add_child(logo_label)
	var logo_alt_label = Label.new()
	logo_alt_label.name = "Label_UstLogoAlt"
	logo_alt_label.text = "TACTICAL STRATEGY"
	logo_alt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_alt_label.add_theme_font_size_override("font_size", 7)
	logo_alt_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.5))
	logo_vbox.add_child(logo_alt_label)
	ust_bilgi_kaynak_label = Label.new()
	ust_bilgi_kaynak_label.name = "Label_UstKaynak"
	ust_bilgi_kaynak_label.text = "30🪙 | G0 M100 | Acik | U0%"
	ust_bilgi_kaynak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ust_bilgi_kaynak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ust_bilgi_kaynak_label.add_theme_font_size_override("font_size", 10)
	ust_bilgi_kaynak_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	bar_row.add_child(ust_bilgi_kaynak_label)

func _ensure_hedefler_paneli() -> void:
	if ui_root == null:
		return
	hedefler_paneli = _get_node_by_name("HedeflerPaneli") as PanelContainer
	if hedefler_paneli == null:
		hedefler_paneli = PanelContainer.new()
		hedefler_paneli.name = "HedeflerPaneli"
		ui_root.add_child(hedefler_paneli)
	hedefler_paneli.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hedefler_paneli.offset_left = 16
	hedefler_paneli.offset_top = 62
	hedefler_paneli.offset_right = 258
	hedefler_paneli.offset_bottom = 182
	hedefler_paneli.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hedefler_paneli.add_theme_stylebox_override("panel", HudStyle.objectives_panel_style())
	for c in hedefler_paneli.get_children():
		c.queue_free()
	var hedef_margin = MarginContainer.new()
	hedef_margin.add_theme_constant_override("margin_left", 12)
	hedef_margin.add_theme_constant_override("margin_right", 12)
	hedef_margin.add_theme_constant_override("margin_top", 10)
	hedef_margin.add_theme_constant_override("margin_bottom", 10)
	hedefler_paneli.add_child(hedef_margin)
	var hedef_vbox = VBoxContainer.new()
	hedef_vbox.add_theme_constant_override("separation", 4)
	hedef_margin.add_child(hedef_vbox)
	var baslik = Label.new()
	baslik.text = "HEDEFLER"
	baslik.add_theme_font_size_override("font_size", 11)
	baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	hedef_vbox.add_child(baslik)
	hedefler_label = Label.new()
	hedefler_label.name = "Label_HedeflerIcerik"
	hedefler_label.text = "• Tum dusman birliklerini etkisiz hale getir\n• Gizli gecidi ele gecir\n• Ana karargahi koru"
	hedefler_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hedefler_label.add_theme_font_size_override("font_size", 9)
	hedefler_label.add_theme_color_override("font_color", Color(0.88, 0.89, 0.86))
	hedef_vbox.add_child(hedefler_label)

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
	savas_panel_root.offset_top = -156
	savas_panel_root.offset_right = -12
	savas_panel_root.offset_bottom = -8
	if savas_panel_root.get_theme_stylebox("panel") == null:
		_uygula_panel_stili(savas_panel_root)

func _uygula_panel_stili(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", HudStyle.battle_root_panel_style())

func _apply_font_size(node: Node, font_size: int) -> void:
	if node is Label:
		(node as Label).add_theme_font_size_override("font_size", font_size)
	elif node is Button:
		(node as Button).add_theme_font_size_override("font_size", font_size)
	for c in node.get_children():
		_apply_font_size(c, font_size)
