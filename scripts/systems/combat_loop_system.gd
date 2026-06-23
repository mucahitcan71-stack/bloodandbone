extends RefCounted
class_name CombatLoopSystem

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func tick(delta: float) -> void:
	_process_attacks(delta)
	_apply_pending_damage()
	_process_movement_and_deaths(delta)
	_host.savas_sisi_guncelle()
	_host.nokta_gorunurluklerini_guncelle()
	_host.birim_gorunurluklerini_guncelle()

func _process_attacks(delta: float) -> void:
	for birim in _host.aktif_birimler:
		if birim["hp"] <= 0:
			continue
		if birim.get("pusu_modunda", false) or birim.get("geri_cekiliyor", false):
			continue

		birim["saldirim_timer"] += delta
		if birim["saldirim_timer"] < 1.0:
			continue
		birim["saldirim_timer"] = 0.0

		var dusman_listesi: Array = []
		var saldiran_efekt = _host.birim_etkin_degerleri(birim)
		for b in _host.aktif_birimler:
			if b["taraf"] != birim["taraf"] and b["hp"] > 0:
				if not _host.birim_gorunur_mu_tarafa(b, birim["taraf"]):
					continue
				if birim["konum"].distance_to(b["konum"]) <= saldiran_efekt["menzil"]:
					dusman_listesi.append(b)

		if dusman_listesi.is_empty():
			birim["savas_halinde"] = false
			continue

		birim["savas_halinde"] = true
		var hasar_per = max(1.0, float(saldiran_efekt["guc"]) / float(dusman_listesi.size()))
		for dusman in dusman_listesi:
			var dusman_efekt = _host.birim_etkin_degerleri(dusman)
			var carpan = _host.hasar_carpani_hesapla(birim["isim"], dusman["isim"])
			if not birim.get("pusu_ilk_saldiri_kullanildi", true):
				carpan *= float(birim.get("pusu_hasar_carpani", _host.pusu_ilk_saldiri_carpani))
				birim["pusu_ilk_saldiri_kullanildi"] = true
			var gercek_hasar = max(1.0, (hasar_per - float(dusman_efekt["savunma"])) * carpan)
			dusman["bekleyen_hasar"] += gercek_hasar
			birim["hasar_verilen"] += int(gercek_hasar)
			_host.ult_sarj[birim["taraf"]] = min(100.0, _host.ult_sarj[birim["taraf"]] + gercek_hasar * 0.08)
			_host.mac_istatistik[birim["taraf"]]["hasar"] += gercek_hasar

func _apply_pending_damage() -> void:
	for birim in _host.aktif_birimler:
		if birim["bekleyen_hasar"] > 0:
			birim["hp"] -= birim["bekleyen_hasar"]
			birim["bekleyen_hasar"] = 0.0

func _process_movement_and_deaths(delta: float) -> void:
	var silinecekler: Array = []
	for birim in _host.aktif_birimler:
		if birim["hp"] <= 0:
			if birim.get("is_general", false):
				_host.moral_degistir(birim["taraf"], -30.0)
			if birim == _host.secili_birim:
				_host.secili_birim = null
			var birim_id = int(birim.get("id", -1))
			if birim_id >= 0:
				_host.fog_system.remove_enemy_intel(birim_id)
			birim["node"].queue_free()
			silinecekler.append(birim)
			var taraf = birim["taraf"]
			var diger = "dogu_roma" if taraf == "osmanli" else "osmanli"
			_host.mac_istatistik[taraf]["kayip"] += 1
			_host.mac_istatistik[diger]["oldurme"] += 1
			continue

		var dusman_menzilde = false
		var hareket_efekt = _host.birim_etkin_degerleri(birim)
		var takip_id = int(birim.get("takip_edilen_dusman", -1))
		if takip_id >= 0:
			var takip = _host.birim_id_ile_bul(takip_id)
			if takip.is_empty():
				birim["takip_edilen_dusman"] = -1
			else:
				birim["hedef"] = takip["konum"]
				birim["hedef_nokta"] = _host.en_yakin_nokta_bul(takip["konum"])
		for b in _host.aktif_birimler:
			if b["taraf"] != birim["taraf"] and b["hp"] > 0:
				if not _host.birim_gorunur_mu_tarafa(b, birim["taraf"]):
					continue
				if birim["konum"].distance_to(b["konum"]) <= hareket_efekt["menzil"]:
					dusman_menzilde = true
					break

		var hedefe_varildi = birim["konum"].distance_to(birim["hedef"]) <= 8.0
		if birim.get("pusu_modunda", false):
			dusman_menzilde = false
			hedefe_varildi = true
		if birim.get("geri_cekiliyor", false):
			dusman_menzilde = false
		if not dusman_menzilde and not hedefe_varildi:
			var mesafe = birim["hedef"] - birim["konum"]
			var yon = mesafe.normalized()
			birim["konum"] += yon * hareket_efekt["hiz"] * delta
			var arazi_hareket = _host.birimin_arazisini_bul(birim["konum"])
			if bool(arazi_hareket.get("tek_sira", false)):
				var rect: Rect2 = arazi_hareket.get("rect", Rect2())
				var merkez = _host._dar_koridor_merkez(rect)
				if rect.size.x <= rect.size.y:
					birim["konum"].x = merkez.x
				else:
					birim["konum"].y = merkez.y
			birim["node"].position = birim["konum"]
			birim["pusu_arazi_gizli"] = false
		elif not birim.get("pusu_modunda", false):
			var orman_idx = _host._orman_bolge_index(birim["konum"])
			birim["pusu_arazi_gizli"] = orman_idx >= 0 and not dusman_menzilde and hedefe_varildi
		if birim.get("geri_cekiliyor", false) and hedefe_varildi:
			birim["geri_cekiliyor"] = false

		if is_instance_valid(birim["node"]):
			var hp_bar = birim["node"].get_node_or_null("HPBar")
			if hp_bar:
				hp_bar.size.x = 30.0 * (birim["hp"] / birim["max_hp"])
			var asker_l = birim["node"].get_node_or_null("AskerSayisi")
			if asker_l:
				var kalan = int(ceil(birim["hp"] / (birim["max_hp"] / birim["asker_sayisi"])))
				asker_l.text = str(max(0, kalan))

	for silinecek in silinecekler:
		_host.aktif_birimler.erase(silinecek)
