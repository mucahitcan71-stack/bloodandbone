extends RefCounted
class_name AiSystem

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func reset_composition() -> void:
	_host.ai_kompozisyon.clear()
	_host.ai_kompozisyon.resize(max(1, _host.dogu_roma_birim_tipleri.size()))
	_host.ai_kompozisyon.fill(0)

func reset_preparation_army() -> void:
	reset_composition()
	_host.ai_hazirlik_timer = 0.0
	_host.taraf_formasyon["dogu_roma"] = "hucum"
	update_army_ui()

func tick_preparation(delta: float) -> void:
	_host.ai_hazirlik_timer += delta
	if _host.ai_hazirlik_timer >= _host.ai_hazirlik_araligi:
		_host.ai_hazirlik_timer = 0.0
		add_army_unit()

func tick_spawn_waves(delta: float) -> void:
	_host.ai_spawn_timer += delta
	if _host.ai_spawn_timer < _host.ai_spawn_suresi:
		return
	_host.ai_spawn_timer = 0.0
	_host.ai_dalga_sayisi += 1
	send_unit()
	if _host.zorluk == "kolay" and _host.ai_dalga_sayisi % 2 == 0:
		send_unit()
		if randf() < 0.3:
			send_unit()
	elif _host.zorluk == "orta" and _host.ai_dalga_sayisi % 2 == 0:
		send_unit()
		if randf() < 0.4:
			send_unit()
	elif _host.zorluk == "zor":
		send_unit()
		if _host.ai_dalga_sayisi % 2 == 0:
			send_unit()
		if randf() < 0.65:
			send_unit()

func composition_total_kt() -> int:
	var toplam = 0
	for i in range(_host.ai_kompozisyon.size()):
		toplam += _host.ai_kompozisyon[i] * _host.dogu_roma_birim_tipleri[i]["kontenjan"]
	return toplam

func composition_total() -> int:
	var toplam = 0
	for sayi in _host.ai_kompozisyon:
		toplam += sayi
	return toplam

func update_army_ui() -> void:
	var ai_l = _host.ui_node("Label_AiOrdu")
	if ai_l == null:
		return
	var hedef = _host.zorluk_ayarlari[_host.zorluk]["kontenjan_hedef"]
	var kt = composition_total_kt()
	var parcalar: Array = []
	for i in range(_host.dogu_roma_birim_tipleri.size()):
		if _host.ai_kompozisyon[i] > 0:
			var tip = _host.dogu_roma_birim_tipleri[i]
			parcalar.append(tip["sembol"] + " " + tip["isim"] + " x" + str(_host.ai_kompozisyon[i]))
	ai_l.text = HudFormatter.ai_army_label(parcalar, kt, hedef)

func choose_unit_type(remain_capacity: int) -> int:
	return MetaSystem.choose_ai_army_type(_host.dogu_roma_birim_tipleri, remain_capacity, _host.zorluk)

func add_army_unit() -> void:
	var hedef = _host.zorluk_ayarlari[_host.zorluk]["kontenjan_hedef"]
	var mevcut = composition_total_kt()
	if mevcut >= hedef:
		return
	var idx = choose_unit_type(hedef - mevcut)
	if idx < 0:
		return
	_host.ai_kompozisyon[idx] += 1
	update_army_ui()

func build_full_army() -> void:
	reset_composition()
	var hedef = _host.zorluk_ayarlari[_host.zorluk]["kontenjan_hedef"]
	while composition_total_kt() < hedef:
		var onceki = composition_total_kt()
		add_army_unit()
		if composition_total_kt() == onceki:
			break
	update_army_ui()

func prepare_battle_inventory() -> void:
	if composition_total() <= 0 or composition_total_kt() < _host.zorluk_ayarlari[_host.zorluk]["kontenjan_hedef"] * 0.5:
		build_full_army()
	_host.ai_envanter.clear()
	for i in range(_host.dogu_roma_birim_tipleri.size()):
		for j in range(_host.ai_kompozisyon[i]):
			_host.ai_envanter.append(_host.dogu_roma_birim_tipleri[i].duplicate())
	_host.ai_envanter.shuffle()
	print("=== AI ORDUSU === " + str(_host.ai_envanter.size()) + " birim hazir")

func upgrade_point() -> void:
	if _host.hazirlik_fazi or _host.oyun_bitti:
		return
	var secim = ""
	var secim_seviye = 999
	for nokta in _host.nokta_oncelik_listesi():
		if _host.nokta_sahipleri[nokta] != "dogu_roma":
			continue
		if _host.nokta_gelistirme[nokta] < secim_seviye and _host.nokta_gelistirme[nokta] < 3:
			secim = nokta
			secim_seviye = _host.nokta_gelistirme[nokta]
	if secim == "":
		return
	var maliyet = 20 + secim_seviye * 15
	if _host.dogu_roma_gelisim_altini < maliyet:
		return
	_host.dogu_roma_gelisim_altini -= maliyet
	_host.mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet
	_host.nokta_gelistirme[secim] += 1
	_host.nokta_puan[secim] = _host.nokta_taban_puan(secim) + _host.nokta_gelistirme[secim]
	_host.nokta_altin[secim] = _host.nokta_taban_altin(secim) + _host.nokta_gelistirme[secim]
	if _host.zorluk == "kolay" and randf() < 0.42 and _host.dogu_roma_gelisim_altini >= maliyet + 8 and _host.nokta_gelistirme[secim] < 3:
		_host.dogu_roma_gelisim_altini -= maliyet + 8
		_host.mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 8
		_host.nokta_gelistirme[secim] += 1
		_host.nokta_puan[secim] = _host.nokta_taban_puan(secim) + _host.nokta_gelistirme[secim]
		_host.nokta_altin[secim] = _host.nokta_taban_altin(secim) + _host.nokta_gelistirme[secim]
	if _host.zorluk == "orta" and randf() < 0.62 and _host.dogu_roma_gelisim_altini >= maliyet + 12 and _host.nokta_gelistirme[secim] < 3:
		_host.dogu_roma_gelisim_altini -= maliyet + 12
		_host.mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 12
		_host.nokta_gelistirme[secim] += 1
		_host.nokta_puan[secim] = _host.nokta_taban_puan(secim) + _host.nokta_gelistirme[secim]
		_host.nokta_altin[secim] = _host.nokta_taban_altin(secim) + _host.nokta_gelistirme[secim]
	if _host.zorluk == "zor" and randf() < 0.82 and _host.dogu_roma_gelisim_altini >= maliyet + 15 and _host.nokta_gelistirme[secim] < 3:
		_host.dogu_roma_gelisim_altini -= maliyet + 15
		_host.mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 15
		_host.nokta_gelistirme[secim] += 1
		_host.nokta_puan[secim] = _host.nokta_taban_puan(secim) + _host.nokta_gelistirme[secim]
		_host.nokta_altin[secim] = _host.nokta_taban_altin(secim) + _host.nokta_gelistirme[secim]

func pick_target_position(nokta: String) -> Vector2:
	var merkez = _host.nokta_merkezi(nokta)
	var aci = randf() * TAU
	var uzaklik = randf_range(25.0, 110.0)
	return _host.harita_sinirla(merkez + Vector2(cos(aci), sin(aci)) * uzaklik)

func find_nearest_enemy(unit: Dictionary) -> Dictionary:
	var en_yakin: Dictionary = {}
	var en_kisa = _host.ai_takip_menzili
	for b in _host.aktif_birimler:
		if b["taraf"] != "osmanli" or b["hp"] <= 0:
			continue
		if not _host.birim_gorunur_mu_tarafa(b, "dogu_roma"):
			continue
		var d = unit["konum"].distance_to(b["konum"])
		if d < en_kisa:
			en_kisa = d
			en_yakin = b
	return en_yakin

func has_enemy_in_range(unit: Dictionary) -> bool:
	var etkiler = _host.birim_etkin_degerleri(unit)
	for b in _host.aktif_birimler:
		if b["taraf"] != "osmanli" or b["hp"] <= 0:
			continue
		if not _host.birim_gorunur_mu_tarafa(b, "dogu_roma"):
			continue
		if unit["konum"].distance_to(b["konum"]) <= etkiler["menzil"]:
			return true
	return false

func compute_unit_target(unit: Dictionary) -> Vector2:
	var dusman = find_nearest_enemy(unit)
	if not dusman.is_empty():
		var mesafe = unit["konum"].distance_to(dusman["konum"])
		var etkiler = _host.birim_etkin_degerleri(unit)
		if mesafe <= etkiler["menzil"]:
			return unit["konum"]
		var yon = (dusman["konum"] - unit["konum"]).normalized()
		var adim = clamp(mesafe - etkiler["menzil"] * 0.6, 40.0, 180.0)
		return _host.harita_sinirla(unit["konum"] + yon * adim)

	var nokta = choose_target_point()
	return pick_target_position(nokta)

func update_units(delta: float) -> void:
	var karar_suresi = _host.ai_karar_araligi.get(_host.zorluk, 3.5)
	if _host.zorluk == "zor":
		karar_suresi *= 0.7
	for birim in _host.aktif_birimler:
		if birim["taraf"] != "dogu_roma" or birim["hp"] <= 0:
			continue
		if birim.get("pusu_modunda", false):
			continue

		if has_enemy_in_range(birim):
			continue

		var dusman = find_nearest_enemy(birim)
		if not dusman.is_empty():
			var mesafe = birim["konum"].distance_to(dusman["konum"])
			var ai_etki = _host.birim_etkin_degerleri(birim)
			if mesafe <= ai_etki["menzil"] * 1.5:
				birim["hedef"] = compute_unit_target(birim)
				birim["hedef_nokta"] = _host.en_yakin_nokta_bul(birim["hedef"])
				birim["ai_timer"] = 0.0
				continue

		birim["ai_timer"] += delta
		var hedefe_varildi = birim["konum"].distance_to(birim["hedef"]) <= 8.0
		var yeni_hedef_zamani = hedefe_varildi and birim["ai_timer"] >= karar_suresi
		var uzun_yuruyus = birim["ai_timer"] >= karar_suresi * 2.5

		if not yeni_hedef_zamani and not uzun_yuruyus:
			continue

		birim["ai_timer"] = 0.0
		birim["hedef"] = compute_unit_target(birim)
		birim["hedef_nokta"] = _host.en_yakin_nokta_bul(birim["hedef"])

func choose_purchasable_unit() -> Dictionary:
	var uygun: Array = []
	for tip in _host.dogu_roma_birim_tipleri:
		if _host.dogu_roma_altini >= tip["maliyet"]:
			uygun.append(tip)
	if uygun.is_empty():
		return {}
	uygun.sort_custom(func(a, b): return a["maliyet"] > b["maliyet"])
	if _host.zorluk == "zor":
		return uygun[0]
	if _host.zorluk == "orta":
		return uygun[randi() % mini(2, uygun.size())]
	return uygun[randi() % mini(3, uygun.size())]

func send_unit() -> void:
	var tip: Dictionary = {}
	var kaynak = "ordu"
	if _host.ai_envanter.size() > 0:
		tip = _host.ai_envanter.pop_back()
	else:
		tip = choose_purchasable_unit()
		if tip.is_empty():
			return
		_host.dogu_roma_altini -= tip["maliyet"]
		_host.mac_istatistik["dogu_roma"]["altin_harcama"] += int(tip["maliyet"])
		kaynak = "altin"

	var hedef_nokta = choose_target_point()
	var hedef_pos = pick_target_position(hedef_nokta)
	var baslangic = _host.harita_sinirla(Vector2(
		randf_range(_host.harita_sinir["min_x"] + 80.0, _host.harita_sinir["max_x"] - 80.0),
		randf_range(_host.harita_sinir["min_y"] + 40.0, _host.harita_sinir["min_y"] + 180.0)
	))
	_host.birim_olustur(baslangic, hedef_nokta, "dogu_roma", tip, hedef_pos)
	print("AI " + tip["isim"] + " (" + kaynak + ") -> " + hedef_nokta + " | kalan ordu: " + str(_host.ai_envanter.size()))

func choose_target_point() -> String:
	var oncelik = _host.nokta_oncelik_listesi()
	if _host.zorluk == "zor":
		if _host.nokta_sahipleri.get("C", "tarafsiz") != "dogu_roma":
			return "C"
		for nokta in oncelik:
			if _host.nokta_sahipleri[nokta] == "osmanli":
				return nokta
	elif _host.zorluk == "orta":
		if _host.nokta_sahipleri.get("C", "tarafsiz") == "osmanli" and randf() < 0.9:
			return "C"
		for nokta in oncelik:
			if _host.nokta_sahipleri[nokta] == "osmanli":
				return nokta
	elif _host.zorluk == "kolay":
		if _host.nokta_sahipleri.get("C", "tarafsiz") == "osmanli" and randf() < 0.82:
			return "C"
		for nokta in oncelik:
			if _host.nokta_sahipleri[nokta] == "osmanli":
				return nokta

	for nokta in oncelik:
		if _host.nokta_sahipleri[nokta] == "tarafsiz":
			return nokta

	var en_zayif = ""
	var en_az = 999
	for nokta in _host.nokta_sahipleri:
		if _host.nokta_sahipleri[nokta] == "osmanli":
			var say = _host.noktadaki_taraf_sayisi(nokta, "osmanli")
			if say < en_az:
				en_az = say
				en_zayif = nokta

	if en_zayif != "":
		return en_zayif

	var en_tehlikeli = ""
	var en_dusuk = 100.0
	for nokta in _host.nokta_capture:
		if _host.nokta_sahipleri[nokta] == "dogu_roma" and _host.nokta_capture[nokta] < en_dusuk:
			en_dusuk = _host.nokta_capture[nokta]
			en_tehlikeli = nokta

	if en_tehlikeli != "":
		return en_tehlikeli

	var noktalar = _host.nokta_oncelik_listesi()
	return noktalar[randi() % noktalar.size()]
