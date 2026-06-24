extends RefCounted
class_name PreparationController

var _host: Node2D = null
var sayi_labellar: Array = []
var zorluk_butonlari: Dictionary = {}
var kart_butonlari: Array = []
var ekipman_butonlari: Array = []

func configure(host: Node2D) -> void:
	_host = host

func build_panel() -> void:
	_host.ui_system.build_preparation_panel()
	_host._ui_refs_sync()
	sayi_labellar.clear()
	zorluk_butonlari.clear()

	var zorluk_baslik = Label.new()
	zorluk_baslik.text = "ZORLUK"
	_add_element("genel", zorluk_baslik)

	var zorluklar = [
		{"isim": "kolay", "text": "KOLAY"},
		{"isim": "orta", "text": "ORTA"},
		{"isim": "zor", "text": "ZOR"},
	]
	var zorluk_row = HBoxContainer.new()
	_add_element("genel", zorluk_row)
	for z in zorluklar:
		var btn = Button.new()
		btn.text = z["text"]
		btn.custom_minimum_size = Vector2(78, 26)
		btn.add_theme_font_size_override("font_size", 10)
		var z_isim = z["isim"]
		btn.pressed.connect(func(): select_difficulty(z_isim))
		zorluk_row.add_child(btn)
		_host.ui_system.register_preparation_widget(btn, "genel")
		zorluk_butonlari[z["isim"]] = btn

	var secili_l = Label.new()
	secili_l.name = "Label_Zorluk"
	secili_l.text = "Zorluk: ORTA"
	_add_element("genel", secili_l)

	var kampanya_l = Label.new()
	kampanya_l.name = "Label_Kampanya"
	kampanya_l.text = "Bolge: Trakya"
	_add_element("genel", kampanya_l)

	var terfi_l = Label.new()
	terfi_l.name = "Label_Terfi"
	terfi_l.text = "Terfi: yok"
	_add_element("genel", terfi_l)

	var kayit_l = Label.new()
	kayit_l.name = "Label_Kayit"
	kayit_l.text = "G:0 M:0"
	_add_element("genel", kayit_l)

	var ai_baslik = Label.new()
	ai_baslik.text = "DUSMAN ORDUSU"
	_add_element("genel", ai_baslik)

	var ai_ordu_l = Label.new()
	ai_ordu_l.name = "Label_AiOrdu"
	ai_ordu_l.text = "Kuruluyor..."
	_add_element("genel", ai_ordu_l)

	var baslik = Label.new()
	baslik.text = "ORDU KUR"
	_add_element("ordu", baslik)

	var lk = Label.new()
	lk.name = "Label_Kontenjan"
	lk.text = "Kontenjan: 30/30"
	_add_element("ordu", lk)

	var birim_grid = GridContainer.new()
	birim_grid.columns = 3
	_add_element("ordu", birim_grid)
	for i in range(_host.osmanli_birim_tipleri.size()):
		var tip = _host.osmanli_birim_tipleri[i]
		var grup = VBoxContainer.new()
		birim_grid.add_child(grup)
		_host.ui_system.register_preparation_widget(grup, "ordu")
		var isim_l = Label.new()
		isim_l.text = tip["sembol"] + " " + tip["isim"] + " (" + str(tip["kontenjan"]) + "kt, " + str(tip["maliyet"]) + "🪙)"
		grup.add_child(isim_l)
		var hover_tip = tip
		isim_l.mouse_entered.connect(func(): _host.birim_detay_hover_basla(hover_tip))
		isim_l.mouse_exited.connect(func(): _host.birim_detay_hover_bitir())
		var satir_h = HBoxContainer.new()
		grup.add_child(satir_h)
		var btn_eksi = Button.new()
		btn_eksi.text = "-"
		btn_eksi.custom_minimum_size = Vector2(30, 24)
		var idx = i
		btn_eksi.pressed.connect(func(): _host.kompozisyon_cikar(idx))
		btn_eksi.mouse_entered.connect(func(): _host.birim_detay_hover_basla(hover_tip))
		btn_eksi.mouse_exited.connect(func(): _host.birim_detay_hover_bitir())
		satir_h.add_child(btn_eksi)

		var sayi_l = Label.new()
		sayi_l.text = "0"
		sayi_l.name = "Komp_" + str(i)
		sayi_labellar.append(sayi_l)
		satir_h.add_child(sayi_l)

		var btn_arti = Button.new()
		btn_arti.text = "+"
		btn_arti.custom_minimum_size = Vector2(30, 24)
		btn_arti.pressed.connect(func(): _host.kompozisyon_ekle(idx))
		btn_arti.mouse_entered.connect(func(): _host.birim_detay_hover_basla(hover_tip))
		btn_arti.mouse_exited.connect(func(): _host.birim_detay_hover_bitir())
		satir_h.add_child(btn_arti)

	var formasyon_l = Label.new()
	formasyon_l.name = "Label_Formasyon"
	formasyon_l.text = "Formasyon: Dengeli"
	_add_element("taktik", formasyon_l)

	var formasyonlar_ui = [
		{"id": "hucum", "text": "Hucum"},
		{"id": "savunma", "text": "Savunma"},
		{"id": "dengeli", "text": "Dengeli"},
	]
	var form_row = HBoxContainer.new()
	_add_element("taktik", form_row)
	for f in formasyonlar_ui:
		var fbtn = Button.new()
		fbtn.text = f["text"]
		fbtn.custom_minimum_size = Vector2(84, 26)
		fbtn.add_theme_font_size_override("font_size", 10)
		var f_id = f["id"]
		fbtn.pressed.connect(func(): _host.formasyon_sec(f_id))
		form_row.add_child(fbtn)
		_host.ui_system.register_preparation_widget(fbtn, "taktik")

	var kart_l = Label.new()
	kart_l.name = "Label_Kart"
	kart_l.text = "Kart (3'ten 1):"
	_add_element("taktik", kart_l)

	var ekipman_l = Label.new()
	ekipman_l.name = "Label_Ekipman"
	ekipman_l.text = "Ekipman:"
	_add_element("taktik", ekipman_l)

	var savas_btn = Button.new()
	savas_btn.name = "SavasBtn"
	savas_btn.text = "SAVASA BASLA"
	savas_btn.custom_minimum_size = Vector2(170, 34)
	savas_btn.add_theme_font_size_override("font_size", 10)
	savas_btn.pressed.connect(func(): _host.savas_baslat())
	_host.ui_system.add_preparation_footer(savas_btn)
	_host._ui_refs_sync()

func switch_tab(tab: String) -> void:
	_host.ui_system.switch_preparation_tab(tab)
	_host._ui_refs_sync()

func update_info() -> void:
	var kampanya_l = _host.ui_node("Label_Kampanya")
	if kampanya_l != null:
		kampanya_l.text = "Bolge: " + _host.kampanya_bolgeleri[_host.kampanya_index]
	var terfi_l = _host.ui_node("Label_Terfi")
	if terfi_l != null:
		terfi_l.text = _host.terfi_ozet_metni()
	var kayit_l = _host.ui_node("Label_Kayit")
	if kayit_l != null:
		kayit_l.text = HudFormatter.save_stats(_host.mac_istatistik_kayit)
	var zorluk_l = _host.ui_node("Label_Zorluk")
	if zorluk_l != null:
		var isimler = {"kolay": "KOLAY", "orta": "ORTA", "zor": "ZOR"}
		zorluk_l.text = "Zorluk: " + isimler.get(_host.zorluk, "ORTA")

func select_difficulty(secilen: String) -> void:
	_host.zorluk = secilen
	_host.ai_spawn_suresi = _host.zorluk_ayarlari[_host.zorluk]["spawn"]
	highlight_difficulty()
	_host.ai_ordu_hazirlik_sifirla()
	update_info()

func highlight_difficulty() -> void:
	for z in zorluk_butonlari:
		zorluk_butonlari[z].modulate = Color(1.5, 1.5, 1.5) if z == _host.zorluk else Color(1, 1, 1)

func prepare_card_options() -> void:
	var eski_satir = _host.ui_node("KartSecimSatiri")
	if eski_satir != null:
		eski_satir.queue_free()
	for btn in kart_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	kart_butonlari.clear()
	_host.kart_secenekleri = MetaSystem.draw_cards(_host.kart_havuzu, 3)
	var satir = HBoxContainer.new()
	satir.name = "KartSecimSatiri"
	_add_element("taktik", satir)
	for i in range(_host.kart_secenekleri.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(186, 24)
		btn.add_theme_font_size_override("font_size", 10)
		btn.text = _host.kart_secenekleri[i]["isim"]
		var kart = _host.kart_secenekleri[i]
		btn.pressed.connect(func(): select_card(kart))
		satir.add_child(btn)
		_host.ui_system.register_preparation_widget(btn, "taktik")
		kart_butonlari.append(btn)
	_host._ui_refs_sync()

func select_card(kart: Dictionary) -> void:
	_host.secili_kart = kart
	for btn in kart_butonlari:
		if is_instance_valid(btn):
			btn.disabled = true
	var l = _host.ui_node("Label_Kart")
	if l != null:
		l.text = "Kart: " + kart["isim"] + " (" + kart["aciklama"] + ")"

func prepare_equipment_options() -> void:
	var eski_satir = _host.ui_node("EkipmanSecimSatiri")
	if eski_satir != null:
		eski_satir.queue_free()
	for btn in ekipman_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	ekipman_butonlari.clear()
	var sirali = ["celik", "zirh", "durbun"]
	var satir = HBoxContainer.new()
	satir.name = "EkipmanSecimSatiri"
	_add_element("taktik", satir)
	for i in range(sirali.size()):
		var anahtar = sirali[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(186, 24)
		btn.add_theme_font_size_override("font_size", 10)
		btn.text = _host.ekipmanlar[anahtar]["isim"]
		var e = anahtar
		btn.pressed.connect(func(): select_equipment(e))
		satir.add_child(btn)
		_host.ui_system.register_preparation_widget(btn, "taktik")
		ekipman_butonlari.append(btn)
	_host._ui_refs_sync()

func select_equipment(anahtar: String) -> void:
	_host.secili_ekipman = anahtar
	var l = _host.ui_node("Label_Ekipman")
	if l != null:
		l.text = "Ekipman: " + _host.ekipmanlar[anahtar]["isim"]
	for i in range(ekipman_butonlari.size()):
		var btn = ekipman_butonlari[i]
		if is_instance_valid(btn):
			btn.modulate = Color(1.4, 1.4, 0.8) if btn.text == _host.ekipmanlar[anahtar]["isim"] else Color(1, 1, 1)

func reset_composition_labels() -> void:
	for i in range(sayi_labellar.size()):
		sayi_labellar[i].text = "0"

func show_ui() -> void:
	_host._ui_refs_sync()
	for el in _host.ui_system.get_hazirlik_paneli():
		if is_instance_valid(el):
			el.visible = true
	var root = _host.ui_system.get_hazirlik_panel_root()
	if root != null:
		root.visible = true
	switch_tab("genel")
	highlight_difficulty()

func hide_ui() -> void:
	for el in _host.ui_system.get_hazirlik_paneli():
		if is_instance_valid(el):
			el.visible = false
	var root = _host.ui_system.get_hazirlik_panel_root()
	if root != null:
		root.visible = false

func _add_element(tab: String, node: Control) -> void:
	_host.ui_system.add_preparation_element(tab, node)
	_host._ui_refs_sync()
