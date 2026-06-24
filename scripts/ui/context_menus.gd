extends RefCounted
class_name ContextMenus
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")

var _host: Node2D = null

var komut_menusu_panel: PanelContainer = null
var komut_menusu_hedef_birim = null
var takviye_sag_tik_menu: PanelContainer = null
var takviye_sag_tik_secili_idx = -1
var birim_ekle_menu_panel: PanelContainer = null

func configure(host: Node2D) -> void:
	_host = host

func build_komut_menusu() -> void:
	komut_menusu_panel = _host.ui_node("Panel_KomutMenu") as PanelContainer
	if komut_menusu_panel == null:
		komut_menusu_panel = PanelContainer.new()
		komut_menusu_panel.name = "Panel_KomutMenu"
		komut_menusu_panel.custom_minimum_size = Vector2(170, 156)
		komut_menusu_panel.visible = false
		_host.get_node("CanvasLayer").add_child(komut_menusu_panel)
	for c in komut_menusu_panel.get_children():
		c.queue_free()

	var menu_margin = MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 8)
	menu_margin.add_theme_constant_override("margin_right", 8)
	menu_margin.add_theme_constant_override("margin_top", 8)
	menu_margin.add_theme_constant_override("margin_bottom", 8)
	komut_menusu_panel.add_child(menu_margin)
	var menu_vbox = VBoxContainer.new()
	menu_margin.add_child(menu_vbox)

	var satir = [
		{"id": "saldir", "text": "⚔ Saldir"},
		{"id": "geri_cekil", "text": "↩ Geri Cekil"},
		{"id": "pusu", "text": "🌲 Pusu Kur"},
		{"id": "savun", "text": "🛡 Nokta Savun"},
	]
	for i in range(satir.size()):
		var btn = Button.new()
		btn.text = satir[i]["text"]
		btn.custom_minimum_size = Vector2(154, 30)
		var cmd = satir[i]["id"]
		btn.pressed.connect(func(): _host.komut_menusu_komut_sec(cmd))
		menu_vbox.add_child(btn)

func ac_komut_menusu(ekran_pos: Vector2, birim: Dictionary) -> void:
	if komut_menusu_panel == null:
		return
	komut_menusu_hedef_birim = birim
	var view = _host.get_viewport_rect().size
	var pos = ekran_pos
	if pos.x + komut_menusu_panel.size.x > view.x:
		pos.x = view.x - komut_menusu_panel.size.x - 8
	if pos.y + komut_menusu_panel.size.y > view.y:
		pos.y = view.y - komut_menusu_panel.size.y - 8
	komut_menusu_panel.position = pos
	komut_menusu_panel.visible = true

func kapat_komut_menusu() -> void:
	if komut_menusu_panel != null:
		komut_menusu_panel.visible = false
	komut_menusu_hedef_birim = null

func build_takviye_menu() -> void:
	takviye_sag_tik_menu = _host.ui_node("Panel_TakviyeSagTik") as PanelContainer
	if takviye_sag_tik_menu == null:
		takviye_sag_tik_menu = PanelContainer.new()
		takviye_sag_tik_menu.name = "Panel_TakviyeSagTik"
		takviye_sag_tik_menu.custom_minimum_size = Vector2(190, 44)
		takviye_sag_tik_menu.visible = false
		_host.get_node("CanvasLayer").add_child(takviye_sag_tik_menu)
	for c in takviye_sag_tik_menu.get_children():
		c.queue_free()

	var menu_margin = MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 6)
	menu_margin.add_theme_constant_override("margin_right", 6)
	menu_margin.add_theme_constant_override("margin_top", 6)
	menu_margin.add_theme_constant_override("margin_bottom", 6)
	takviye_sag_tik_menu.add_child(menu_margin)

	var btn = Button.new()
	btn.name = "TakviyeSagTikBtn"
	btn.custom_minimum_size = Vector2(178, 32)
	btn.pressed.connect(func(): _host._takviye_sag_tik_menu_secildi())
	menu_margin.add_child(btn)

func build_birim_ekle_menu() -> void:
	birim_ekle_menu_panel = _host.ui_node("Panel_BirimEkleMenu") as PanelContainer
	if birim_ekle_menu_panel == null:
		birim_ekle_menu_panel = PanelContainer.new()
		birim_ekle_menu_panel.name = "Panel_BirimEkleMenu"
		birim_ekle_menu_panel.visible = false
		birim_ekle_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_host.get_node("CanvasLayer").add_child(birim_ekle_menu_panel)
	for c in birim_ekle_menu_panel.get_children():
		c.queue_free()

	var tip_sayisi = _host.osmanli_birim_tipleri.size()
	var icerik_yukseklik = tip_sayisi * 34 + max(0, tip_sayisi - 1) * 4
	var panel_yukseklik = icerik_yukseklik + 12
	birim_ekle_menu_panel.custom_minimum_size = Vector2(200, panel_yukseklik)

	var menu_margin = MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 6)
	menu_margin.add_theme_constant_override("margin_right", 6)
	menu_margin.add_theme_constant_override("margin_top", 6)
	menu_margin.add_theme_constant_override("margin_bottom", 6)
	menu_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	birim_ekle_menu_panel.add_child(menu_margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_margin.add_child(vbox)
	for i in range(_host.osmanli_birim_tipleri.size()):
		var tip = _host.osmanli_birim_tipleri[i]
		var btn = Button.new()
		btn.text = "%s %s (%d🪙)" % [str(tip.get("sembol", "•")), str(tip.get("isim", "Birim")), int(tip.get("maliyet", 0))]
		btn.custom_minimum_size = Vector2(176, 30)
		btn.disabled = _host.osmanli_altini < int(tip.get("maliyet", 0))
		var idx = i
		btn.pressed.connect(func():
			kapat_birim_ekle_menu()
			_host.birim_satin_al(idx)
		)
		vbox.add_child(btn)

func ac_birim_ekle_menu(ekran_pos: Vector2) -> void:
	if birim_ekle_menu_panel == null:
		build_birim_ekle_menu()
	else:
		build_birim_ekle_menu()
	kapat_komut_menusu()
	kapat_takviye_menu()
	var view = _host.get_viewport_rect().size
	var pos = ekran_pos
	if pos == Vector2.ZERO:
		pos = _host.get_viewport().get_mouse_position()
	if pos.x + birim_ekle_menu_panel.size.x > view.x:
		pos.x = view.x - birim_ekle_menu_panel.size.x - 8
	if pos.y + birim_ekle_menu_panel.size.y > view.y:
		pos.y = view.y - birim_ekle_menu_panel.size.y - 8
	birim_ekle_menu_panel.position = pos
	birim_ekle_menu_panel.visible = true

func kapat_birim_ekle_menu() -> void:
	if birim_ekle_menu_panel != null:
		birim_ekle_menu_panel.visible = false

func ac_takviye_menu(idx: int, ekran_pos: Vector2) -> void:
	if takviye_sag_tik_menu == null or idx < 0 or idx >= _host.osmanli_birim_tipleri.size():
		return
	kapat_komut_menusu()
	takviye_sag_tik_secili_idx = idx
	var tip = _host.osmanli_birim_tipleri[idx]
	var menu_btn = takviye_sag_tik_menu.find_child("TakviyeSagTikBtn", true, false) as Button
	if menu_btn != null:
		menu_btn.text = str(tip["sembol"]) + " Birim Ekle (" + str(tip["maliyet"]) + "🪙)"
		menu_btn.disabled = _host.osmanli_altini < int(tip["maliyet"])
	var view = _host.get_viewport_rect().size
	var pos = ekran_pos
	if pos.x + takviye_sag_tik_menu.size.x > view.x:
		pos.x = view.x - takviye_sag_tik_menu.size.x - 8
	if pos.y + takviye_sag_tik_menu.size.y > view.y:
		pos.y = view.y - takviye_sag_tik_menu.size.y - 8
	takviye_sag_tik_menu.position = pos
	takviye_sag_tik_menu.visible = true

func kapat_takviye_menu() -> void:
	if takviye_sag_tik_menu != null:
		takviye_sag_tik_menu.visible = false
	takviye_sag_tik_secili_idx = -1

func _on_takviye_secildi() -> void:
	if takviye_sag_tik_secili_idx < 0:
		kapat_takviye_menu()
		return
	var idx = takviye_sag_tik_secili_idx
	kapat_takviye_menu()
	_host.birim_satin_al(idx)

func envanter_kart_gui_input(event: InputEvent, idx: int, silik: bool) -> void:
	if HudInventory.should_show_context_menu(event):
		ac_takviye_menu(idx, event.global_position)
		_host.get_viewport().set_input_as_handled()
	elif HudInventory.should_block_left_click(event, silik):
		_host.get_viewport().set_input_as_handled()
