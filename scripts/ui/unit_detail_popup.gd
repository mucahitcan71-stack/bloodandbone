extends RefCounted
class_name UnitDetailPopup

var _root: Node2D = null
var _hover_birim_detay: Dictionary = {}
var _detail_text_fn: Callable
var detay_popup_timer: Timer = null
var detay_popup_panel: Panel = null
var detay_popup_label: Label = null

func configure(root_node: Node2D) -> void:
	_root = root_node

func set_text_provider(callback: Callable) -> void:
	_detail_text_fn = callback

func get_panel() -> Panel:
	return detay_popup_panel

func get_label() -> Label:
	return detay_popup_label

func get_timer() -> Timer:
	return detay_popup_timer

func build() -> void:
	detay_popup_timer = Timer.new()
	detay_popup_timer.one_shot = true
	detay_popup_timer.wait_time = 0.5
	detay_popup_timer.timeout.connect(_on_hover_timeout)
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

func begin_hover(tip: Dictionary) -> void:
	_hover_birim_detay = tip
	if detay_popup_timer != null:
		detay_popup_timer.stop()
		detay_popup_timer.start()

func end_hover() -> void:
	_hover_birim_detay = {}
	if detay_popup_timer != null:
		detay_popup_timer.stop()
	if detay_popup_panel != null:
		detay_popup_panel.visible = false

func sync_visibility() -> void:
	if detay_popup_panel == null or not detay_popup_panel.visible:
		return
	if _hover_birim_detay.is_empty():
		detay_popup_panel.visible = false
		if detay_popup_timer != null:
			detay_popup_timer.stop()

func show_popup(metin: String) -> void:
	if detay_popup_panel == null or detay_popup_label == null:
		return
	detay_popup_label.text = metin
	reposition()
	detay_popup_panel.visible = true

func reposition() -> void:
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

func _on_hover_timeout() -> void:
	if _hover_birim_detay.is_empty():
		return
	if not _detail_text_fn.is_valid():
		return
	show_popup(_detail_text_fn.call(_hover_birim_detay))
