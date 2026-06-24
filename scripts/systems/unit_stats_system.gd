extends RefCounted
class_name UnitStatsSystem
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const Constants = preload("res://scripts/constants.gd")

var _host: Node2D = null

func configure(host: Node2D) -> void:
	_host = host

func general_olustur(taraf: String) -> void:
	var tip = {
		"isim": "General",
		"hiz": 36.0,
		"renk": Color(1, 0.9, 0.35) if taraf == "osmanli" else Color(0.75, 0.55, 1),
		"sembol": "⭐",
		"guc": 30,
		"savunma": 20,
		"hp": 120,
		"asker_sayisi": 1,
		"menzil": 100.0,
		"is_general": true,
		"aura_menzil": 190.0,
		"aura_guc": 1.1,
		"aura_savunma": 1.1
	}
	var harita_sinir = _host.harita_sinir
	var merkez_x = (harita_sinir["min_x"] + harita_sinir["max_x"]) * 0.5
	var baslangic = Vector2(merkez_x - 220.0, harita_sinir["max_y"] - 140.0) if taraf == "osmanli" else Vector2(merkez_x + 220.0, harita_sinir["min_y"] + 140.0)
	var hedef = baslangic + Vector2(60, -40) if taraf == "osmanli" else baslangic + Vector2(-60, 40)
	_host.birim_olustur(baslangic, _host.en_yakin_nokta_bul(hedef), taraf, tip, hedef)

func dar_koridor_merkez(rect: Rect2) -> Vector2:
	return rect.position + rect.size * 0.5

func _birim_suvari_mi(birim: Dictionary) -> bool:
	return _host.suvari_isimleri.has(str(birim.get("isim", "")))

func birim_etkin_degerleri(birim: Dictionary) -> Dictionary:
	var taraf = birim["taraf"]
	var general = _host.general_getir(taraf)
	var weather = _host.hava_durumu_efektleri.get(_host.hava_durumu, _host.hava_durumu_efektleri["Acik"])
	var level = _host.terfi_seviyesi_getir(taraf, birim["isim"])
	var etkiler = CombatSystem.effective_stats(
		birim,
		_host.taraf_formasyon,
		_host.formasyonlar,
		_host.taraf_moral,
		_host.taraf_carpanlari,
		weather,
		_host.ult_aktif_sure,
		general,
		level
	)
	var arazi = _host.birimin_arazisini_bul(birim["konum"])
	var tip = str(arazi.get("tip", "duz_arazi"))
	if tip in ["tepe", "kopru"]:
		var sav = float(arazi.get("savunma_bonus", 1.0))
		etkiler["savunma"] = max(1, int(round(float(etkiler["savunma"]) * sav)))
	if tip in ["vadi", "yol"]:
		var hiz_bonus = float(arazi.get("hiz_bonus", 1.0))
		etkiler["hiz"] = max(8.0, float(etkiler["hiz"]) * hiz_bonus)
	if tip == "dar_gecit" and _birim_suvari_mi(birim):
		var yavas = float(arazi.get("suvari_yavaslama", 0.5))
		etkiler["hiz"] = max(8.0, float(etkiler["hiz"]) * yavas)
	return etkiler

func hasar_carpani_hesapla(saldiran: String, hedef: String) -> float:
	var ustunluk_tablosu = _host.ustunluk_tablosu
	if not ustunluk_tablosu.has(saldiran):
		return 1.0
	if hedef in ustunluk_tablosu[saldiran]["guclu"]:
		return Constants.HASAR_CARPANI_GUCLU
	if hedef in ustunluk_tablosu[saldiran]["zayif"]:
		return Constants.HASAR_CARPANI_ZAYIF
	return 1.0
