extends RefCounted
class_name SideHud

var _root: Node2D = null
var yan_hud_tetik: PanelContainer = null
var yan_hud_panel: PanelContainer = null
var yan_hud_icerik: VBoxContainer = null
var yan_hud_kaybol_timer: Timer = null

func configure(root_node: Node2D) -> void:
	_root = root_node

func _get_node_by_name(node_name: String) -> Node:
	if _root == null or not _root.has_node("CanvasLayer"):
		return null
	return _root.get_node("CanvasLayer").find_child(node_name, true, false)

func get_yan_hud_tetik() -> PanelContainer:
	return yan_hud_tetik

func get_yan_hud_panel() -> PanelContainer:
	return yan_hud_panel

func get_yan_hud_icerik() -> VBoxContainer:
	return yan_hud_icerik

func get_yan_hud_kaybol_timer() -> Timer:
	return yan_hud_kaybol_timer

func build(ui_root: Control, ust_bilgi_paneli: HBoxContainer) -> void:
	if ui_root == null:
		return
	yan_hud_tetik = _get_node_by_name("YanHudTetik") as PanelContainer
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

	yan_hud_panel = _get_node_by_name("YanHudPanel") as PanelContainer
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

	var os_l = _get_node_by_name("Label_Osmanli")
	if os_l != null:
		os_l.reparent(yan_hud_icerik)
	var dr_l = _get_node_by_name("Label_DoguRoma")
	if dr_l != null:
		dr_l.reparent(yan_hud_icerik)
	var round_l = _get_node_by_name("Label_Round")
	if round_l != null:
		round_l.reparent(yan_hud_icerik)
	var sure_l = _get_node_by_name("Label_Sure")
	if sure_l != null:
		sure_l.reparent(yan_hud_icerik)

	if ust_bilgi_paneli != null:
		ust_bilgi_paneli.visible = false

	if yan_hud_kaybol_timer == null:
		yan_hud_kaybol_timer = Timer.new()
		yan_hud_kaybol_timer.one_shot = true
		yan_hud_kaybol_timer.wait_time = 1.2
		yan_hud_kaybol_timer.timeout.connect(hide)
		_root.add_child(yan_hud_kaybol_timer)

	if not yan_hud_tetik.mouse_entered.is_connected(show):
		yan_hud_tetik.mouse_entered.connect(show)
	if not yan_hud_tetik.mouse_exited.is_connected(schedule_hide):
		yan_hud_tetik.mouse_exited.connect(schedule_hide)
	if not yan_hud_panel.mouse_entered.is_connected(show):
		yan_hud_panel.mouse_entered.connect(show)
	if not yan_hud_panel.mouse_exited.is_connected(schedule_hide):
		yan_hud_panel.mouse_exited.connect(schedule_hide)

	yan_hud_panel.visible = false

func show() -> void:
	if yan_hud_panel != null:
		yan_hud_panel.visible = true
	if yan_hud_kaybol_timer != null:
		yan_hud_kaybol_timer.stop()

func schedule_hide() -> void:
	if yan_hud_kaybol_timer != null:
		yan_hud_kaybol_timer.start()

func hide() -> void:
	if yan_hud_panel != null:
		yan_hud_panel.visible = false
