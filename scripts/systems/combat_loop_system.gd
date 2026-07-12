extends RefCounted
class_name CombatLoopSystem

const Constants = preload("res://scripts/constants.gd")
const _YOL_DISI_HIZ_CARPAN := 0.5
const _PUSU_AKTIF := true
const _PUSU_HASAR_CARPAN := 1.5
const _PUSU_MORAL_CEZA := 12.0

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func tick(delta: float) -> void:
	_process_attacks(delta)
	_apply_pending_damage()
	_process_movement_and_deaths(delta)
	_host.fog_system.tick_battle_fog()

func _process_attacks(delta: float) -> void:
	var hazir: Array = []
	for birim in _host.aktif_birimler:
		if birim["hp"] <= 0:
			continue
		if birim.get("pusu_modunda", false) or birim.get("geri_cekiliyor", false):
			continue

		birim["saldirim_timer"] += delta
		if birim["saldirim_timer"] < 1.0:
			continue
		birim["saldirim_timer"] = 0.0

		var hedefler := _menzildeki_dusmanlar(birim)
		if hedefler.is_empty():
			birim["savas_halinde"] = false
			continue
		birim["savas_halinde"] = true
		hazir.append({"birim": birim, "hedefler": hedefler})

	# Ilk vurus: pusu saldirilari once, hasar hemen uygulanir; sonra normal
	var normal: Array = []
	for kayit in hazir:
		var birim: Dictionary = kayit["birim"]
		var hedefler: Array = kayit["hedefler"]
		var pusu_hedefler: Array = []
		var diger_hedefler: Array = []
		for dusman in hedefler:
			if dusman.get("hp", 0) <= 0:
				continue
			if _pusu_saldiri_mi(birim, dusman):
				pusu_hedefler.append(dusman)
			else:
				diger_hedefler.append(dusman)
		if not pusu_hedefler.is_empty():
			_saldiri_uygula(birim, pusu_hedefler, true)
			_apply_pending_damage()
		if not diger_hedefler.is_empty():
			normal.append({"birim": birim, "hedefler": diger_hedefler})

	for kayit in normal:
		var birim2: Dictionary = kayit["birim"]
		if birim2.get("hp", 0) <= 0:
			continue
		var canli: Array = []
		for d in kayit["hedefler"]:
			if d.get("hp", 0) > 0:
				canli.append(d)
		if not canli.is_empty():
			_saldiri_uygula(birim2, canli, false)

func _menzildeki_dusmanlar(birim: Dictionary) -> Array:
	var sonuc: Array = []
	var saldiran_efekt = _host.birim_etkin_degerleri(birim)
	for b in _host.aktif_birimler:
		if b["taraf"] == birim["taraf"] or b["hp"] <= 0:
			continue
		if not _host.birim_gorunur_mu_tarafa(b, birim["taraf"]):
			continue
		if birim["konum"].distance_to(b["konum"]) <= saldiran_efekt["menzil"]:
			sonuc.append(b)
	return sonuc

func _pusu_saldiri_mi(saldiran: Dictionary, hedef: Dictionary) -> bool:
	if not _PUSU_AKTIF:
		return false
	# Komut pususu tetik sonrasi rezerve ilk vurus
	if not saldiran.get("pusu_ilk_saldiri_kullanildi", true):
		return true
	# Arazi gizliligi: saldiran, hedefin tarafindan gorunmuyor
	return not _host.birim_gorunur_mu_tarafa(saldiran, str(hedef.get("taraf", "")))

func _saldiri_uygula(birim: Dictionary, dusman_listesi: Array, pusu: bool) -> void:
	if dusman_listesi.is_empty() or birim.get("hp", 0) <= 0:
		return
	var saldiran_efekt = _host.birim_etkin_degerleri(birim)
	var hasar_per = max(1.0, float(saldiran_efekt["guc"]) / float(dusman_listesi.size()))
	var pusu_kullanildi := false
	for dusman in dusman_listesi:
		if dusman.get("hp", 0) <= 0:
			continue
		var dusman_efekt = _host.birim_etkin_degerleri(dusman)
		var carpan = _host.hasar_carpani_hesapla(birim["isim"], dusman["isim"])
		var bu_pusu := pusu and _pusu_saldiri_mi(birim, dusman)
		if bu_pusu:
			carpan *= _PUSU_HASAR_CARPAN
			if not pusu_kullanildi:
				_host.moral_degistir(str(dusman.get("taraf", "")), -_PUSU_MORAL_CEZA)
			pusu_kullanildi = true
		var gercek_hasar = max(1.0, (hasar_per - float(dusman_efekt["savunma"])) * carpan)
		dusman["bekleyen_hasar"] += gercek_hasar
		birim["hasar_verilen"] += int(gercek_hasar)
		_host.ult_sarj[birim["taraf"]] = min(100.0, _host.ult_sarj[birim["taraf"]] + gercek_hasar * 0.08)
		_host.mac_istatistik[birim["taraf"]]["hasar"] += gercek_hasar
	if pusu_kullanildi:
		_pusu_ortaya_cik(birim)

func _pusu_ortaya_cik(birim: Dictionary) -> void:
	birim["pusu_modunda"] = false
	birim["pusu_arazi_gizli"] = false
	birim["pusu_ilk_saldiri_kullanildi"] = true
	if birim.get("taraf", "") == "osmanli":
		var savas_l = _host.ui_node("Label_SavasBilgi") if _host.has_method("ui_node") else null
		if savas_l != null:
			savas_l.text = "Pusu! Ilk vurus x%.1f, dusman morali dustu" % _PUSU_HASAR_CARPAN

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
			if _host.world_system != null:
				_host.world_system.zemin3d_birim_asker_sil(birim)
			if birim.has("kok_node") and is_instance_valid(birim["kok_node"]):
				birim["kok_node"].queue_free()
			elif is_instance_valid(birim.get("node")):
				if birim.has("cerceve_node") and is_instance_valid(birim["cerceve_node"]):
					birim["cerceve_node"].queue_free()
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
				birim["takip_timer"] = float(birim.get("takip_timer", 0.0)) + delta
				if birim["takip_timer"] >= 0.45:
					birim["takip_timer"] = 0.0
					var yol: PackedVector2Array = _host.birim_yol_bul(birim["konum"], takip["konum"])
					if yol.size() >= 2:
						birim["waypoints"] = yol
						birim["waypoint_idx"] = 1 if yol[0].distance_to(birim["konum"]) <= 14.0 else 0
						birim["hedef"] = yol[birim["waypoint_idx"]]
						birim["hareket_durdu"] = false
					else:
						birim["waypoints"] = PackedVector2Array()
						birim["waypoint_idx"] = 0
						birim["yol_baglanti"] = false
						birim["hedef"] = takip["konum"]
						birim["hareket_durdu"] = false
				birim["hedef_nokta"] = _host.en_yakin_nokta_bul(takip["konum"])
		for b in _host.aktif_birimler:
			if b["taraf"] != birim["taraf"] and b["hp"] > 0:
				if not _host.birim_gorunur_mu_tarafa(b, birim["taraf"]):
					continue
				if birim["konum"].distance_to(b["konum"]) <= hareket_efekt["menzil"]:
					dusman_menzilde = true
					break

		var hedef_pos: Vector2 = birim["hedef"]
		var to_hedef = hedef_pos - birim["konum"]
		var dist = to_hedef.length()
		var varis_esigi = Constants.BIRIM_HAREKET_VARIS_ESIGI
		if dist <= varis_esigi:
			_waypoint_siradaki(birim)
			hedef_pos = birim["hedef"]
			to_hedef = hedef_pos - birim["konum"]
			dist = to_hedef.length()
		var durak_band = Constants.BIRIM_HAREKET_DURAK_BANDI
		var chasing = takip_id >= 0
		if chasing:
			birim["hareket_durdu"] = false
		elif dist > varis_esigi + durak_band:
			birim["hareket_durdu"] = false
		var settled = bool(birim.get("hareket_durdu", false))
		var hedefe_varildi = settled or dist <= varis_esigi
		if not chasing and not settled and dist <= Constants.BIRIM_NOKTA_YAKIN_ESIGI:
			var hedef_nokta = str(birim.get("hedef_nokta", ""))
			if hedef_nokta != "" and _host.birim_nokta_menzilinde(birim, hedef_nokta) and _son_hedef_noktasi(birim, hedef_nokta):
				hedefe_varildi = true
		if birim.get("pusu_modunda", false):
			dusman_menzilde = false
			hedefe_varildi = true
		if birim.get("geri_cekiliyor", false):
			dusman_menzilde = false
		if not dusman_menzilde and not hedefe_varildi:
			var aktif_yol: PackedVector2Array = birim.get("waypoints", PackedVector2Array())
			var yol_hiz: float = 1.0
			if _host.yol_hiz_avantaji_mi(birim["konum"]):
				birim["yol_baglanti"] = false
			else:
				yol_hiz = _YOL_DISI_HIZ_CARPAN
			var step = hareket_efekt["hiz"] * yol_hiz * delta
			if dist > 0.001:
				var aday_konum = hedef_pos if step >= dist else birim["konum"] + (to_hedef / dist) * step
				if not _host.gecis_engelli_mi(aday_konum):
					birim["konum"] = aday_konum
			var arazi_hareket = _host.birimin_arazisini_bul(birim["konum"])
			if bool(arazi_hareket.get("tek_sira", false)):
				var snap_dist = birim["konum"].distance_to(hedef_pos)
				if snap_dist > varis_esigi * 2.0:
					var rect: Rect2 = arazi_hareket.get("rect", Rect2())
					var merkez = _host._dar_koridor_merkez(rect)
					if rect.size.x <= rect.size.y:
						birim["konum"].x = merkez.x
					else:
						birim["konum"].y = merkez.y
			birim["pusu_arazi_gizli"] = false
			dist = birim["konum"].distance_to(birim["hedef"])
			if dist <= varis_esigi:
				if not aktif_yol.is_empty() and _waypoint_siradaki(birim):
					hedefe_varildi = false
					birim["hareket_durdu"] = false
				else:
					hedefe_varildi = true
		if hedefe_varildi and not chasing and not birim.get("pusu_modunda", false) and not birim.get("savunma_modunda", false):
			birim["hedef"] = birim["konum"]
			birim["hareket_durdu"] = true
		if birim.get("geri_cekiliyor", false) and hedefe_varildi:
			birim["geri_cekiliyor"] = false

		_host.birim_gorselini_uygula(birim, delta)

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

func _waypoint_siradaki(birim: Dictionary) -> bool:
	var yol: PackedVector2Array = birim.get("waypoints", PackedVector2Array())
	if yol.is_empty():
		return false
	var idx := int(birim.get("waypoint_idx", 0))
	if idx >= yol.size() - 1:
		return false
	birim["waypoint_idx"] = idx + 1
	birim["hedef"] = yol[idx + 1]
	return true

func _son_hedef_noktasi(birim: Dictionary, nokta_id: String) -> bool:
	var yol: PackedVector2Array = birim.get("waypoints", PackedVector2Array())
	var son: Vector2 = yol[yol.size() - 1] if yol.size() > 0 else birim["hedef"]
	var merkez: Vector2 = _host.nokta_merkezi(nokta_id)
	var pay: float = _host.world_system.get_kale_yol_yaricapi() + 48.0
	return son.distance_to(merkez) <= pay
