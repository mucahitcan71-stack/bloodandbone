extends RefCounted
class_name BattleFlowSystem

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func start_preparation() -> void:
	_host.hiz_carpani_sifirla()
	_host.kampanya_haritasini_yukle()
	_host.hazirlik_fazi = true
	_host.kalan_sure = _host.hazirlik_suresi
	_host.mevcut_kontenjan = _host.max_kontenjan
	_host.kompozisyon_dizisi_sifirla()
	_host.savas_baslangic_kompozisyon.clear()
	_host.envanter.clear()
	_host.secili_nokta = ""
	_host.secili_envanter_idx = -1
	_host.secili_envanter_tip_anahtari = ""
	_host.secili_envanter_gonder_adedi = 1
	_host.command_system.reset_for_preparation()
	_host.secili_birim = _host.command_system.get_selected_unit()
	_host.secili_komut = _host.command_system.get_selected_command()
	_host.komut_menusu_kapat()
	_host.nokta_gelistirme.clear()
	_host.nokta_capture.clear()
	_host.nokta_sahipleri.clear()
	_host.fog_system.reset_match_discovery(_host.nokta_konumlari.keys())
	_host.nokta_son_bilgi.clear()
	_host.fog_system.reset_enemy_intel()
	for nokta in _host.nokta_konumlari:
		_host.nokta_capture[nokta] = 50.0
		_host.nokta_sahipleri[nokta] = "tarafsiz"
		_host.nokta_gelistirme[nokta] = 0
		_host.nokta_son_bilgi[nokta] = {"sahip": "tarafsiz", "capture": 50.0}
	_host.osmanli_puani = 0
	_host.dogu_roma_puani = 0
	_host.osmanli_altini = _host.zorluk_ayarlari[_host.zorluk]["oyuncu_altin"]
	_host.dogu_roma_altini = _host.zorluk_ayarlari[_host.zorluk]["ai_altin"]
	_host.osmanli_gelisim_altini = 0
	_host.dogu_roma_gelisim_altini = 0
	_host.oyun_suresi = 0.0
	_host.puan_timer = 0.0
	_host.oyun_bitti = false
	_host.ai_spawn_timer = 0.0
	_host.ai_dalga_sayisi = 0
	_host.ai_spawn_suresi = _host.zorluk_ayarlari[_host.zorluk]["spawn"]
	_host.ai_envanter.clear()
	_host.ai_ordu_hazirlik_sifirla()
	_host.taraf_moral = {"osmanli": 100.0, "dogu_roma": 100.0}
	_host.taraf_formasyon = {"osmanli": "dengeli", "dogu_roma": "dengeli"}
	_host.ult_sarj = {"osmanli": 0.0, "dogu_roma": 0.0}
	_host.ult_aktif_sure = {"osmanli": 0.0, "dogu_roma": 0.0}
	_host.hava_durumu = "Acik"
	_host.mac_istatistik = {
		"osmanli": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
		"dogu_roma": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
	}
	_host.taraf_carpanlari = {
		"osmanli": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0},
		"dogu_roma": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0}
	}
	_host.secili_kart = {}
	_host.secili_ekipman = ""
	var lf = _host.ui_node("Label_Formasyon")
	if lf != null:
		lf.text = "Formasyon: Dengeli"
	var le = _host.ui_node("Label_Ekipman")
	if le != null:
		le.text = "Ekipman:"
	var lk = _host.ui_node("Label_Kart")
	if lk != null:
		lk.text = "Kart (3'ten 1):"
	var lm = _host.ui_node("Label_MacOzeti")
	if lm != null:
		lm.text = ""
	_host.hazirlik_bilgi_guncelle()
	_host.kart_secenekleri_hazirla()
	_host.ekipman_secimleri_hazirla()
	_host.ekipman_sec("celik")
	_host.ai_secili_kart = _host.kart_havuzu[randi() % _host.kart_havuzu.size()]
	var ai_ek_keys = ["celik", "zirh", "durbun"]
	_host.ai_secili_ekipman = ai_ek_keys[randi() % ai_ek_keys.size()]

	for birim in _host.aktif_birimler:
		if is_instance_valid(birim["node"]):
			birim["node"].queue_free()
	_host.aktif_birimler.clear()

	for btn in _host.envanter_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	_host.envanter_butonlari.clear()

	for i in range(_host.sayi_labellar.size()):
		_host.sayi_labellar[i].text = "0"
	var kont_l = _host.ui_node("Label_Kontenjan")
	if kont_l != null:
		kont_l.text = "Kontenjan: " + str(_host.max_kontenjan) + "/" + str(_host.max_kontenjan) + " | Ordu: 0"

	if is_instance_valid(_host.tekrar_oyna_btn):
		_host.tekrar_oyna_btn.visible = false

	_host._ui_refs_sync()
	for el in _host.hazirlik_paneli:
		if is_instance_valid(el):
			el.visible = true
	if _host.hazirlik_panel_root != null:
		_host.hazirlik_panel_root.visible = true
	_host.hazirlik_tab_degistir("genel")
	for z in _host.zorluk_butonlari:
		_host.zorluk_butonlari[z].modulate = Color(1.5, 1.5, 1.5) if z == _host.zorluk else Color(1, 1, 1)
	for el in _host.savas_paneli:
		if is_instance_valid(el):
			el.visible = false
	if _host.savas_panel_root != null:
		_host.savas_panel_root.visible = false
	if _host.panel_sag_log_hiz != null:
		_host.panel_sag_log_hiz.visible = false
	_host.komut_sec("hareket")
	if is_instance_valid(_host.fog_system.get_fog_layer()):
		_host.fog_system.set_layer_visible(false)
	_host.fog_system.reset_fog_grid()
	_host.fog_system.update_point_visibility()
	_host.nokta_renkleri_sifirla()
	if _host.kamera != null:
		_host.kamera.position = Vector2(
			(_host.harita_sinir["min_x"] + _host.harita_sinir["max_x"]) * 0.5,
			(_host.harita_sinir["min_y"] + _host.harita_sinir["max_y"]) * 0.5
		)
		_host.kamera.zoom = Vector2(0.7, 0.7)
		_host.kamera_sinirla()
	_host.ui_guncelle()

func start_battle() -> void:
	if _host.oyun_bitti:
		return
	if _host.kompozisyon_toplami() <= 0:
		_host.hazirlik_tab_degistir("ordu")
		var kont_l2 = _host.ui_node("Label_Kontenjan")
		if kont_l2 != null:
			kont_l2.text = "En az 1 birim sec!"
		return
	_host.hazirlik_fazi = false
	_host.kalan_sure = _host.max_sure
	_host.ai_spawn_suresi = _host.zorluk_ayarlari[_host.zorluk]["spawn"]
	_host.savas_baslangic_kompozisyon = _host.kompozisyon.duplicate()

	for i in range(_host.osmanli_birim_tipleri.size()):
		for j in range(_host.kompozisyon[i]):
			_host.envanter.append(_host.osmanli_birim_tipleri[i].duplicate())

	_host.ai_savas_envanteri_hazirla()
	if _host.secili_kart.is_empty():
		_host.kart_sec(_host.kart_secenekleri[0] if _host.kart_secenekleri.size() > 0 else {})
	if _host.secili_ekipman == "":
		_host.ekipman_sec("celik")
	_host.kart_uygula("osmanli", _host.secili_kart)
	_host.kart_uygula("dogu_roma", _host.ai_secili_kart)
	_host.ekipman_uygula("osmanli", _host.secili_ekipman)
	_host.ekipman_uygula("dogu_roma", _host.ai_secili_ekipman)
	_host.hava_sec()
	_host.general_olustur("osmanli")
	_host.general_olustur("dogu_roma")

	for el in _host.hazirlik_paneli:
		if is_instance_valid(el):
			el.visible = false
	if _host.hazirlik_panel_root != null:
		_host.hazirlik_panel_root.visible = false
	for el in _host.savas_paneli:
		if is_instance_valid(el):
			el.visible = true
	var nokta_plus = _host.ui_node("NoktaPlusGrup")
	if nokta_plus != null:
		nokta_plus.visible = false
	if _host.envanter_adet_satiri != null:
		_host.envanter_adet_satiri.visible = false
	var savas_kaynak = _host.ui_node("SavasKaynakSatir")
	if savas_kaynak != null:
		savas_kaynak.visible = false
	if _host.savas_panel_root != null:
		_host.savas_panel_root.visible = true
	if _host.panel_sag_log_hiz != null:
		_host.panel_sag_log_hiz.visible = true
	if is_instance_valid(_host.fog_system.get_fog_layer()):
		_host.fog_system.set_layer_visible(true)

	_host.envanter_olustur()
	_host.komut_sec("hareket")
	if _host.kamera != null and _host.nokta_konumlari.has("C"):
		_host.kamera.position = _host.nokta_merkezi("C")
		_host.kamera_sinirla()
	_host.fog_system.tick_battle_fog()
	_host.ui_guncelle()
	_host.ai_spawn_timer = _host.ai_spawn_suresi * 0.4
	print("=== SAVAS BASLADI === Zorluk: " + _host.zorluk)

func restart_match() -> void:
	start_preparation()

func end_match_by_score() -> void:
	if _host.osmanli_puani > _host.dogu_roma_puani:
		end_match_with_winner("osmanli")
	elif _host.dogu_roma_puani > _host.osmanli_puani:
		end_match_with_winner("dogu_roma")
	else:
		_host.hiz_carpani_sifirla()
		_host.oyun_bitti = true
		_host.ui_system.set_game_over_round("BERABERE!")
		_host.mac_istatistik_kayit["beraberlik"] = int(_host.mac_istatistik_kayit.get("beraberlik", 0)) + 1
		_host.kayit_kaydet()
		show_game_over_panel()

func end_match_with_winner(kazanan: String) -> void:
	_host.hiz_carpani_sifirla()
	_host.oyun_bitti = true
	if kazanan == "osmanli":
		_host.ui_system.set_game_over_round("OSMANLI KAZANDI!")
		_host.kampanya_index = MetaSystem.campaign_next_index(
			_host.kampanya_index, true, _host.kampanya_harita_idleri.size()
		)
		_host.mac_istatistik_kayit["galibiyet"] = int(_host.mac_istatistik_kayit.get("galibiyet", 0)) + 1
	else:
		_host.ui_system.set_game_over_round("DOGU ROMA KAZANDI!")
		_host.kampanya_index = MetaSystem.campaign_next_index(
			_host.kampanya_index, false, _host.kampanya_harita_idleri.size()
		)
		_host.mac_istatistik_kayit["maglubiyet"] = int(_host.mac_istatistik_kayit.get("maglubiyet", 0)) + 1
	_host.kayit_kaydet()
	show_game_over_panel()

func show_game_over_panel() -> void:
	_host.ui_system.show_game_over_panel(_host.mac_ozeti_metni())
