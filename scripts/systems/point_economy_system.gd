extends RefCounted
class_name PointEconomySystem

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func priority_list() -> Array:
	var sirali: Array = []
	for nokta in ["C", "A", "B", "D", "E"]:
		if _host.nokta_konumlari.has(nokta):
			sirali.append(nokta)
	for nokta in _host.nokta_konumlari.keys():
		if not sirali.has(nokta):
			sirali.append(nokta)
	return sirali

func base_score(nokta: String) -> int:
	return 3 if nokta == "C" else 1

func base_gold(nokta: String) -> int:
	return 6 if nokta == "C" else 3

func unit_in_point_range(unit: Dictionary, nokta: String) -> bool:
	var etkiler = _host.birim_etkin_degerleri(unit)
	return unit["konum"].distance_to(_host.nokta_merkezi(nokta)) <= etkiler["menzil"]

func faction_count_at_point(nokta: String, taraf: String) -> int:
	var say = 0
	for b in _host.aktif_birimler:
		if b["hp"] <= 0 or b["taraf"] != taraf:
			continue
		if unit_in_point_range(b, nokta):
			say += 1
	return say

func tick_capture(delta: float) -> void:
	for nokta in _host.nokta_konumlari:
		var osmanli_sayisi = faction_count_at_point(nokta, "osmanli")
		var dogu_roma_sayisi = faction_count_at_point(nokta, "dogu_roma")
		var osmanli_bonus = 1.0 + float(_host.nokta_gelistirme[nokta]) * 0.08 if _host.nokta_sahipleri[nokta] == "osmanli" else 1.0
		var dogu_roma_bonus = 1.0 + float(_host.nokta_gelistirme[nokta]) * 0.08 if _host.nokta_sahipleri[nokta] == "dogu_roma" else 1.0

		if osmanli_sayisi > dogu_roma_sayisi:
			_host.nokta_capture[nokta] = min(100.0, _host.nokta_capture[nokta] + _host.capture_hizi * delta * osmanli_sayisi * osmanli_bonus)
		elif dogu_roma_sayisi > osmanli_sayisi:
			_host.nokta_capture[nokta] = max(0.0, _host.nokta_capture[nokta] - _host.capture_hizi * delta * dogu_roma_sayisi * dogu_roma_bonus)

		_update_capture_owner(nokta)

func _update_capture_owner(nokta: String) -> void:
	if _host.nokta_capture[nokta] >= 100.0:
		capture_point(nokta, "osmanli")
	elif _host.nokta_capture[nokta] <= 0.0:
		capture_point(nokta, "dogu_roma")
	else:
		capture_point(nokta, "tarafsiz")

func time_gold_amount() -> int:
	var dakika_bonus = int(_host.oyun_suresi / 60.0)
	return _host.sure_altin_taban + dakika_bonus

func generate_score() -> void:
	var sure_altin = time_gold_amount()
	_host.osmanli_altini += sure_altin
	_host.dogu_roma_altini += sure_altin

	for nokta in _host.nokta_sahipleri:
		if _host.nokta_sahipleri[nokta] == "osmanli":
			_host.osmanli_puani += _host.nokta_puan[nokta]
			_host.osmanli_altini += _host.nokta_altin[nokta]
			_host.osmanli_gelisim_altini += _host.nokta_altin[nokta]
		elif _host.nokta_sahipleri[nokta] == "dogu_roma":
			_host.dogu_roma_puani += _host.nokta_puan[nokta]
			_host.dogu_roma_altini += _host.nokta_altin[nokta]
			_host.dogu_roma_gelisim_altini += _host.nokta_altin[nokta]

	var osmanli_nokta = 0
	var dogu_roma_nokta = 0
	for nokta in _host.nokta_sahipleri:
		if _host.nokta_sahipleri[nokta] == "osmanli":
			osmanli_nokta += 1
		elif _host.nokta_sahipleri[nokta] == "dogu_roma":
			dogu_roma_nokta += 1

	if osmanli_nokta >= 3:
		_host.osmanli_puani += 1
		_host.osmanli_altini += 5
		_host.osmanli_gelisim_altini += 5
		if osmanli_nokta == _host.nokta_sahipleri.size():
			_host.osmanli_puani += 2
			_host.osmanli_altini += 10
			_host.osmanli_gelisim_altini += 10
	elif dogu_roma_nokta >= 3:
		_host.dogu_roma_puani += 1
		_host.dogu_roma_altini += 5
		_host.dogu_roma_gelisim_altini += 5
		if dogu_roma_nokta == _host.nokta_sahipleri.size():
			_host.dogu_roma_puani += 2
			_host.dogu_roma_altini += 10
			_host.dogu_roma_gelisim_altini += 10

	_host.ui_guncelle()

func tick_hold_stats(delta: float) -> void:
	var ult_hiz = {
		"kolay": {"oyuncu": 0.26, "ai": 0.48},
		"orta": {"oyuncu": 0.22, "ai": 0.52},
		"zor": {"oyuncu": 0.18, "ai": 0.56},
	}
	var hiz = ult_hiz.get(_host.zorluk, ult_hiz["orta"])
	var oyuncu_ult_hiz = float(hiz["oyuncu"])
	var ai_ult_hiz = float(hiz["ai"])
	for nokta in _host.nokta_sahipleri:
		if _host.nokta_sahipleri[nokta] == "osmanli":
			_host.mac_istatistik["osmanli"]["nokta_sure"] += delta
			_host.ult_sarj["osmanli"] = min(100.0, _host.ult_sarj["osmanli"] + delta * oyuncu_ult_hiz)
		elif _host.nokta_sahipleri[nokta] == "dogu_roma":
			_host.mac_istatistik["dogu_roma"]["nokta_sure"] += delta
			_host.ult_sarj["dogu_roma"] = min(100.0, _host.ult_sarj["dogu_roma"] + delta * ai_ult_hiz)

func upgrade_point(nokta: String) -> void:
	if _host.hazirlik_fazi or _host.oyun_bitti:
		return
	if _host.nokta_sahipleri[nokta] != "osmanli":
		return
	var seviye = _host.nokta_gelistirme[nokta]
	if seviye >= 3:
		return
	var maliyet = 20 + seviye * 15
	if _host.osmanli_gelisim_altini < maliyet:
		return
	_host.osmanli_gelisim_altini -= maliyet
	_host.mac_istatistik["osmanli"]["altin_harcama"] += maliyet
	_host.nokta_gelistirme[nokta] += 1
	_host.nokta_puan[nokta] = base_score(nokta) + _host.nokta_gelistirme[nokta]
	_host.nokta_altin[nokta] = base_gold(nokta) + _host.nokta_gelistirme[nokta]
	_host.ui_guncelle()

func reset_point_colors() -> void:
	for nokta in _host.nokta_konumlari:
		capture_point(nokta, "tarafsiz")
		_host.nokta_capture[nokta] = 50.0
		if _host.capture_barlar.has(nokta):
			_host.capture_barlar[nokta].size.x = 40.0

func update_point_color(nokta: String) -> void:
	var kare = _host.get_node("Nokta_" + nokta)
	if _host.nokta_sahipleri[nokta] == "osmanli":
		kare.color = Color.GOLD
	elif _host.nokta_sahipleri[nokta] == "dogu_roma":
		kare.color = Color.PURPLE
	else:
		kare.color = Color.GRAY

func capture_point(nokta: String, taraf: String) -> void:
	if _host.nokta_sahipleri[nokta] == taraf:
		return
	var onceki = _host.nokta_sahipleri[nokta]
	_host.nokta_sahipleri[nokta] = taraf
	if onceki == "osmanli":
		_host.moral_degistir("osmanli", -10.0)
	elif onceki == "dogu_roma":
		_host.moral_degistir("dogu_roma", -10.0)
	if taraf == "osmanli":
		_host.moral_degistir("osmanli", 10.0)
	elif taraf == "dogu_roma":
		_host.moral_degistir("dogu_roma", 10.0)
