extends RefCounted
class_name UnitDeploymentSystem

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func reset_composition() -> void:
	_host.kompozisyon.clear()
	_host.kompozisyon.resize(max(1, _host.osmanli_birim_tipleri.size()))
	_host.kompozisyon.fill(0)

func composition_total() -> int:
	var toplam = 0
	for sayi in _host.kompozisyon:
		toplam += sayi
	return toplam

func composition_add(idx: int) -> void:
	var tip = _host.osmanli_birim_tipleri[idx]
	if _host.mevcut_kontenjan < tip["kontenjan"]:
		return
	_host.mevcut_kontenjan -= tip["kontenjan"]
	_host.kompozisyon[idx] += 1
	_host.prep_controller.sayi_labellar[idx].text = str(_host.kompozisyon[idx])
	var kont_l = _host.ui_node("Label_Kontenjan")
	if kont_l != null:
		kont_l.text = "Kontenjan: " + str(_host.mevcut_kontenjan) + "/" + str(_host.max_kontenjan) + " | Ordu: " + str(composition_total())

func composition_remove(idx: int) -> void:
	if _host.kompozisyon[idx] <= 0:
		return
	var tip = _host.osmanli_birim_tipleri[idx]
	_host.mevcut_kontenjan += tip["kontenjan"]
	_host.kompozisyon[idx] -= 1
	_host.prep_controller.sayi_labellar[idx].text = str(_host.kompozisyon[idx])
	var kont_l2 = _host.ui_node("Label_Kontenjan")
	if kont_l2 != null:
		kont_l2.text = "Kontenjan: " + str(_host.mevcut_kontenjan) + "/" + str(_host.max_kontenjan) + " | Ordu: " + str(composition_total())

func get_selected_group_indices() -> Array:
	if _host.secili_envanter_tip_anahtari == "" or not _host.envanter_gruplari.has(_host.secili_envanter_tip_anahtari):
		return []
	return (_host.envanter_gruplari[_host.secili_envanter_tip_anahtari]["indeksler"] as Array).duplicate()

func _selected_type() -> Dictionary:
	if _host.secili_envanter_tip_anahtari == "" or not _host.envanter_gruplari.has(_host.secili_envanter_tip_anahtari):
		return {}
	return _host.envanter_gruplari[_host.secili_envanter_tip_anahtari]["tip"]

func update_selection_ui() -> void:
	var secili_indeksler = get_selected_group_indices()
	var secili_toplam = secili_indeksler.size()
	for btn in _host.envanter_butonlari:
		if not is_instance_valid(btn):
			continue
		var b_silik = bool(btn.get_meta("env_silik", false))
		if b_silik:
			btn.modulate = Color(1, 1, 1, 0.38)
			continue
		var b_anahtar = str(btn.get_meta("env_anahtar", ""))
		btn.modulate = Color(1.2, 1.17, 1.02, 1.0) if b_anahtar != "" and b_anahtar == _host.secili_envanter_tip_anahtari else Color(1, 1, 1, 1)
	if _host.envanter_adet_satiri != null:
		_host.envanter_adet_satiri.visible = false
	if secili_toplam <= 0:
		_host.secili_envanter_idx = -1
		_host.secili_envanter_tip_anahtari = ""
		_host.secili_envanter_gonder_adedi = 1
		return
	_host.secili_envanter_idx = int(secili_indeksler[0])
	_host.secili_envanter_gonder_adedi = clampi(_host.secili_envanter_gonder_adedi, 1, secili_toplam)
	if _host.envanter_adet_label != null:
		_host.envanter_adet_label.text = "x" + str(_host.secili_envanter_gonder_adedi)
	if _host.envanter_adet_eksi_btn != null:
		_host.envanter_adet_eksi_btn.disabled = _host.secili_envanter_gonder_adedi <= 1
	if _host.envanter_adet_arti_btn != null:
		_host.envanter_adet_arti_btn.disabled = _host.secili_envanter_gonder_adedi >= secili_toplam

func rebuild_inventory() -> void:
	for btn in _host.envanter_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	_host.envanter_butonlari.clear()
	_host.envanter_gruplari.clear()

	if _host.envanter_grid == null:
		return
	if is_instance_valid(_host.envanter_scroll) and _host.envanter_scroll.get_parent() == null:
		return
	_host.envanter_grid.columns = max(1, _host.osmanli_birim_tipleri.size())
	for child in _host.envanter_grid.get_children():
		child.queue_free()
	var kart_genislik = _card_width()

	var sira: Array = []
	for i in range(_host.envanter.size()):
		var tip = _host.envanter[i]
		var anahtar = _inventory_key(tip)
		if not _host.envanter_gruplari.has(anahtar):
			_host.envanter_gruplari[anahtar] = {"tip": tip, "indeksler": []}
			sira.append(anahtar)
		(_host.envanter_gruplari[anahtar]["indeksler"] as Array).append(i)

	if _host.hazirlik_fazi:
		_host.secili_envanter_idx = -1
		_host.secili_envanter_tip_anahtari = ""
		_host.secili_envanter_gonder_adedi = 1
		update_selection_ui()
		var env_l = _host.ui_node("Label_Envanter")
		if env_l != null:
			env_l.text = "Envanter: (bos)"
		return

	for idx in range(_host.osmanli_birim_tipleri.size()):
		var tip = _host.osmanli_birim_tipleri[idx]
		var anahtar = _inventory_key(tip)
		var adet = 0
		if _host.envanter_gruplari.has(anahtar):
			adet = (_host.envanter_gruplari[anahtar]["indeksler"] as Array).size()
		var orduda = _host.savas_baslangic_kompozisyon.size() > idx and int(_host.savas_baslangic_kompozisyon[idx]) > 0
		var silik = HudInventory.is_dimmed(orduda, adet)

		var btn = Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(kart_genislik, 42)
		btn.set_meta("env_anahtar", anahtar)
		btn.set_meta("env_silik", silik)
		btn.gui_input.connect(_host._envanter_kart_gui_input.bind(idx, silik))
		var hover_tip = tip
		btn.mouse_entered.connect(func(): _host.birim_detay_hover_basla(hover_tip))
		btn.mouse_exited.connect(func(): _host.birim_detay_hover_bitir())
		if silik:
			btn.modulate = Color(1, 1, 1, 0.38)
		elif adet > 0:
			btn.pressed.connect(func(): select_inventory(anahtar))

		var kart = VBoxContainer.new()
		kart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kart.alignment = BoxContainer.ALIGNMENT_CENTER

		var isim_l = Label.new()
		isim_l.text = str(tip.get("isim", "Birim"))
		isim_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isim_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isim_l.add_theme_font_size_override("font_size", 9)

		var alt_satir = HBoxContainer.new()
		alt_satir.alignment = BoxContainer.ALIGNMENT_CENTER
		alt_satir.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sembol_l = Label.new()
		sembol_l.text = str(tip.get("sembol", "•"))
		sembol_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sembol_l.add_theme_font_size_override("font_size", 10)

		var adet_l = Label.new()
		adet_l.text = "x" + str(adet)
		adet_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		adet_l.add_theme_font_size_override("font_size", 9)

		alt_satir.add_child(sembol_l)
		alt_satir.add_child(adet_l)
		kart.add_child(isim_l)
		kart.add_child(alt_satir)
		btn.add_child(kart)
		_host.envanter_grid.add_child(btn)
		_host.envanter_butonlari.append(btn)

	var env_l2 = _host.ui_node("Label_Envanter")
	if env_l2 != null:
		env_l2.text = "Envanter: " + str(_host.envanter.size()) + " birim"

	if _host.secili_envanter_tip_anahtari != "" and _host.envanter_gruplari.has(_host.secili_envanter_tip_anahtari):
		if get_selected_group_indices().is_empty():
			_host.secili_envanter_tip_anahtari = ""
	elif _host.secili_envanter_tip_anahtari == "":
		for idx in range(_host.osmanli_birim_tipleri.size()):
			var tip_key = _inventory_key(_host.osmanli_birim_tipleri[idx])
			if _host.envanter_gruplari.has(tip_key) and _group_count(tip_key) > 0:
				_host.secili_envanter_tip_anahtari = tip_key
				break
	_host.secili_envanter_gonder_adedi = 1
	update_selection_ui()
	_host.ui_fontlarini_optimize_et()

func select_inventory(anahtar: String) -> void:
	if not _host.envanter_gruplari.has(anahtar):
		return
	_host.secili_envanter_tip_anahtari = anahtar
	_host.secili_envanter_gonder_adedi = 1
	update_selection_ui()
	_host.command_system.select_unit(null)
	_host.secili_birim = _host.command_system.get_selected_unit()
	var tip = _host.envanter_gruplari[anahtar]["tip"]
	_host.birim_detay_hover_bitir()
	var s = _host.ui_node("Label_SavasBilgi")
	if s != null:
		var adet = get_selected_group_indices().size()
		s.text = "Secili: " + tip["isim"] + " (x" + str(adet) + ") — + / - ile adet, haritaya tikla"

func calculate_spawn_position(nokta: String, taraf: String) -> Vector2:
	var taraf_sayisi = 0
	for b in _host.aktif_birimler:
		if b["hp"] <= 0 or b["taraf"] != taraf:
			continue
		if b["hedef_nokta"] == nokta:
			taraf_sayisi += 1

	var sutun = taraf_sayisi % 5
	var satir = taraf_sayisi / 5

	if taraf == "osmanli":
		return Vector2(
			_host.nokta_konumlari[nokta].x - 60 + sutun * 35,
			_host.nokta_konumlari[nokta].y + 100 + satir * 35
		)
	return Vector2(
		_host.nokta_konumlari[nokta].x - 60 + sutun * 35,
		_host.nokta_konumlari[nokta].y - 120 - satir * 35
	)

func send_from_point() -> void:
	if _host.secili_nokta == "":
		print("Once nokta sec!")
		return
	var secili_indeksler = get_selected_group_indices()
	if secili_indeksler.is_empty():
		print("Once birim sec!")
		return

	var adet = min(_host.secili_envanter_gonder_adedi, secili_indeksler.size())
	var tip = _selected_type()
	secili_indeksler.sort()
	for i in range(adet):
		var sil_idx = int(secili_indeksler[secili_indeksler.size() - 1 - i])
		_host.envanter.remove_at(sil_idx)
	_clear_selection_after_send(adet)

	var hedef_pos = calculate_spawn_position(_host.secili_nokta, "osmanli")
	var oyuncu_spawn_y = _host.harita_sinir["max_y"] - 60.0
	for i in range(adet):
		var dagilim = Vector2(float((i % 3) - 1) * 24.0, float(i / 3) * 22.0)
		create_unit(
			Vector2(_host.nokta_konumlari[_host.secili_nokta].x + dagilim.x, oyuncu_spawn_y),
			_host.secili_nokta, "osmanli", tip, hedef_pos + dagilim
		)
	rebuild_inventory()

func send_from_map(hedef_pos: Vector2) -> void:
	var secili_indeksler = get_selected_group_indices()
	if secili_indeksler.is_empty():
		return

	hedef_pos = _host.harita_sinirla(hedef_pos)
	var adet = min(1, secili_indeksler.size())
	var tip = _selected_type()
	secili_indeksler.sort()
	for i in range(adet):
		var sil_idx = int(secili_indeksler[secili_indeksler.size() - 1 - i])
		_host.envanter.remove_at(sil_idx)
	_clear_selection_after_send(adet)

	var nokta = _host.en_yakin_nokta_bul(hedef_pos)
	var oyuncu_spawn_y = _host.harita_sinir["max_y"] - 60.0
	for i in range(adet):
		var dagilim = Vector2(float((i % 3) - 1) * 24.0, float(i / 3) * 22.0)
		create_unit(
			Vector2(hedef_pos.x + dagilim.x, oyuncu_spawn_y),
			nokta, "osmanli", tip, hedef_pos + dagilim
		)
	rebuild_inventory()

func purchase_unit(idx: int) -> void:
	var tip = _host.osmanli_birim_tipleri[idx]
	if _host.osmanli_altini < tip["maliyet"]:
		print("Yeterli altin yok!")
		return
	_host.osmanli_altini -= tip["maliyet"]
	_host.mac_istatistik["osmanli"]["altin_harcama"] += int(tip["maliyet"])
	_host.envanter.append(tip.duplicate())
	rebuild_inventory()
	_host.ui_guncelle()

func create_unit(baslangic: Vector2, hedef_nokta: String, taraf: String, tip: Dictionary, hedef_konum: Vector2 = Vector2(-1, -1)) -> void:
	var cerceve = ColorRect.new()
	cerceve.color = Color(0.05, 0.05, 0.08, 0.55) if taraf == "osmanli" else Color(0.15, 0.05, 0.25, 0.65)
	cerceve.size = Vector2(34, 34)
	cerceve.position = baslangic - Vector2(2, 2)
	cerceve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cerceve.z_index = 19
	_host.add_child(cerceve)

	var kare = ColorRect.new()
	kare.color = tip["renk"]
	kare.size = Vector2(30, 30)
	kare.position = baslangic
	kare.z_index = 20
	_host.add_child(kare)

	var sembol = Label.new()
	sembol.text = tip["sembol"]
	sembol.position = Vector2(5, 5)
	sembol.add_theme_font_size_override("font_size", 14)
	kare.add_child(sembol)

	var asker_l = Label.new()
	asker_l.name = "AskerSayisi"
	asker_l.text = str(tip["asker_sayisi"])
	asker_l.position = Vector2(0, -18)
	asker_l.add_theme_font_size_override("font_size", 10)
	asker_l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	kare.add_child(asker_l)

	var hp_bg = ColorRect.new()
	hp_bg.color = Color(0.15, 0.05, 0.05, 0.9)
	hp_bg.size = Vector2(30, 4)
	hp_bg.position = Vector2(0, -6)
	kare.add_child(hp_bg)

	var hp_bar = ColorRect.new()
	hp_bar.color = Color(0.25, 0.78, 0.32, 1.0)
	hp_bar.size = Vector2(30, 4)
	hp_bar.position = Vector2(0, -6)
	hp_bar.name = "HPBar"
	kare.add_child(hp_bar)

	var gidilecek = hedef_konum if hedef_konum != Vector2(-1, -1) else _host.nokta_konumlari[hedef_nokta] + Vector2(25, 25)

	var guc = tip["guc"]
	var savunma = tip["savunma"]
	var hp = float(tip["hp"] * tip["asker_sayisi"])
	var gorus_yaricapi = _host.fog_system.unit_vision_radius(tip)
	if taraf == "dogu_roma":
		guc = int(guc * _host.zorluk_ayarlari[_host.zorluk]["guc_carpan"])
		savunma = int(savunma * _host.zorluk_ayarlari[_host.zorluk]["savunma_carpan"])
		hp = hp * _host.zorluk_ayarlari[_host.zorluk]["hp_carpan"]

	var birim = {
		"id": _host.birim_id_sayaci,
		"node": kare,
		"konum": baslangic,
		"hedef": gidilecek,
		"hedef_nokta": hedef_nokta,
		"taraf": taraf,
		"hiz": tip["hiz"],
		"guc": guc,
		"savunma": savunma,
		"hp": hp,
		"max_hp": hp,
		"asker_sayisi": tip["asker_sayisi"],
		"isim": tip["isim"],
		"menzil": tip.get("menzil", 80.0),
		"saldirim_timer": 0.0,
		"hasar_verilen": 0,
		"bekleyen_hasar": 0.0,
		"gorus_yaricapi": gorus_yaricapi,
		"pusu_modunda": false,
		"pusu_arazi_gizli": false,
		"pusu_ilk_saldiri_kullanildi": false,
		"pusu_hasar_carpani": _host.pusu_ilk_saldiri_carpani,
		"geri_cekiliyor": false,
		"savunma_modunda": false,
		"takip_edilen_dusman": -1,
		"secili": false,
		"savas_halinde": false,
		"ai_timer": 0.0 if taraf == "dogu_roma" else -1.0,
		"is_general": tip.get("is_general", false),
		"aura_menzil": tip.get("aura_menzil", 0.0),
		"aura_guc": tip.get("aura_guc", 1.0),
		"aura_savunma": tip.get("aura_savunma", 1.0)
	}
	_host.birim_id_sayaci += 1
	_host.aktif_birimler.append(birim)
	_host.terfi_kullanimi_artir(taraf, tip["isim"])

func _inventory_key(tip: Dictionary) -> String:
	var id = str(tip.get("id", ""))
	if id != "":
		return id
	return str(tip.get("isim", "birim"))

func _card_width() -> float:
	var kart_sayisi = max(1, _host.osmanli_birim_tipleri.size())
	var alan = 420.0
	if is_instance_valid(_host.envanter_scroll) and _host.envanter_scroll.size.x > 0.0:
		alan = _host.envanter_scroll.size.x - 12.0
	elif is_instance_valid(_host.envanter_grid):
		var parent = _host.envanter_grid.get_parent()
		if parent is Control and (parent as Control).size.x > 0.0:
			alan = (parent as Control).size.x - 12.0
	return HudInventory.calculate_card_width(kart_sayisi, alan)

func _group_count(anahtar: String) -> int:
	if not _host.envanter_gruplari.has(anahtar):
		return 0
	return (_host.envanter_gruplari[anahtar]["indeksler"] as Array).size()

func _clear_selection_after_send(adet: int) -> void:
	_host.secili_envanter_idx = -1
	_host.secili_envanter_tip_anahtari = ""
	_host.secili_envanter_gonder_adedi = 1
	var s = _host.ui_node("Label_SavasBilgi")
	if s != null:
		s.text = str(adet) + " birim gonderildi"
