extends RefCounted
class_name MapLayoutSystem

const SLOT_SIRASI: Array = ["C", "D", "E"]
const YAN_ROLLER: Array = ["yan", "flank"]
const MERKEZ_ROLLER: Array = ["merkez"]

static func select_layout(map_data: Dictionary, seed_val: int) -> Dictionary:
	var duzen = map_data.get("nokta_duzen", {}) as Dictionary
	if str(duzen.get("mod", "sabit")) != "aday":
		return _sabit_sonuc(map_data)

	var slotlar = map_data.get("nokta_slotlari", {}) as Dictionary
	if slotlar.is_empty():
		return _sabit_sonuc(map_data)

	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var min_mesafe = float(duzen.get("min_mesafe", 320.0))
	var us_uzaklik = float(duzen.get("us_uzaklik", 300.0))
	var max_yol_mesafe = float(duzen.get("max_yol_mesafe", 380.0))
	var harita_id = str(map_data.get("id", "harita"))

	var positions: Dictionary = {}
	var puan: Dictionary = {}
	var altin: Dictionary = {}
	var secilen_roller: Dictionary = {}
	var us_merkezleri: Array = []

	for slot_id in ["A", "B"]:
		if not slotlar.has(slot_id):
			continue
		var slot = slotlar[slot_id] as Dictionary
		if bool(slot.get("sabit", false)):
			var pos = _slot_pos(slot)
			if pos != null:
				positions[slot_id] = pos
				puan[slot_id] = int(slot.get("puan", map_data.get("nokta_puan", {}).get(slot_id, 1)))
				altin[slot_id] = int(slot.get("altin", map_data.get("nokta_altin", {}).get(slot_id, 3)))
				us_merkezleri.append(pos + Vector2(40, 40))

	if slotlar.has("C"):
		var c_pick = _slot_aday_sec(
			harita_id, "C", slotlar["C"] as Dictionary, map_data, positions, us_merkezleri,
			rng, min_mesafe, us_uzaklik, max_yol_mesafe,
			func(aday: Dictionary) -> bool: return MERKEZ_ROLLER.has(str(aday.get("rol", "")))
		)
		_slot_sonuc_uygula("C", c_pick, slotlar["C"] as Dictionary, map_data, positions, puan, altin, secilen_roller)

	var d_pick: Dictionary = {}
	if slotlar.has("D"):
		d_pick = _slot_aday_sec(
			harita_id, "D", slotlar["D"] as Dictionary, map_data, positions, us_merkezleri,
			rng, min_mesafe, us_uzaklik, max_yol_mesafe,
			Callable()
		)
		_slot_sonuc_uygula("D", d_pick, slotlar["D"] as Dictionary, map_data, positions, puan, altin, secilen_roller)

	if slotlar.has("E"):
		var e_filter = Callable()
		var d_rol = str(d_pick.get("rol", ""))
		if not YAN_ROLLER.has(d_rol):
			e_filter = func(aday: Dictionary) -> bool: return YAN_ROLLER.has(str(aday.get("rol", "")))
		var e_pick = _slot_aday_sec(
			harita_id, "E", slotlar["E"] as Dictionary, map_data, positions, us_merkezleri,
			rng, min_mesafe, us_uzaklik, max_yol_mesafe,
			e_filter
		)
		if e_pick.is_empty() and e_filter.is_valid():
			e_pick = _fallback_aday(harita_id, "E", _aday_listesi(slotlar["E"] as Dictionary), e_filter)
		_slot_sonuc_uygula("E", e_pick, slotlar["E"] as Dictionary, map_data, positions, puan, altin, secilen_roller)

	for slot_id in map_data.get("nokta_konumlari", {}).keys():
		if positions.has(slot_id):
			continue
		_sabit_slot_doldur(map_data, slot_id, positions, puan, altin)

	return {"positions": positions, "puan": puan, "altin": altin}

static func _slot_aday_sec(
	harita_id: String,
	slot_id: String,
	slot: Dictionary,
	map_data: Dictionary,
	positions: Dictionary,
	us_merkezleri: Array,
	rng: RandomNumberGenerator,
	min_mesafe: float,
	us_uzaklik: float,
	max_yol_mesafe: float,
	rol_filter: Callable
) -> Dictionary:
	var adaylar = _aday_listesi(slot)
	if adaylar.is_empty():
		return {}
	var sirali = adaylar.duplicate()
	_karistir(sirali, rng)
	for aday in sirali:
		if rol_filter.is_valid() and not rol_filter.call(aday):
			continue
		var pos = Vector2(float(aday.get("x", 0.0)), float(aday.get("y", 0.0)))
		var merkez = pos + Vector2(40, 40)
		if not _aday_uygun(merkez, slot_id, positions, us_merkezleri, min_mesafe, us_uzaklik):
			continue
		var gecici = positions.duplicate()
		gecici[slot_id] = pos
		if _nokta_yol_mesafesi(merkez, map_data, gecici, slot_id) > max_yol_mesafe:
			continue
		return aday

	var fallback = _fallback_aday(harita_id, slot_id, adaylar, rol_filter)
	if fallback.is_empty():
		push_warning("MapLayout: %s/%s icin aday bulunamadi, sabit konum kullanilacak" % [harita_id, slot_id])
	return fallback

static func _fallback_aday(harita_id: String, slot_id: String, adaylar: Array, rol_filter: Callable) -> Dictionary:
	if rol_filter.is_valid():
		for aday in adaylar:
			if rol_filter.call(aday):
				push_warning("MapLayout: %s/%s kural fallback -> %s" % [harita_id, slot_id, str(aday.get("id", "aday"))])
				return aday
	if not adaylar.is_empty():
		push_warning("MapLayout: %s/%s rol fallback atlandi -> %s" % [harita_id, slot_id, str(adaylar[0].get("id", "aday"))])
		return adaylar[0]
	return {}

static func _slot_sonuc_uygula(
	slot_id: String,
	aday: Dictionary,
	slot: Dictionary,
	map_data: Dictionary,
	positions: Dictionary,
	puan: Dictionary,
	altin: Dictionary,
	secilen_roller: Dictionary
) -> void:
	if aday.is_empty():
		_sabit_slot_doldur(map_data, slot_id, positions, puan, altin)
		return
	positions[slot_id] = Vector2(float(aday.get("x", 0.0)), float(aday.get("y", 0.0)))
	puan[slot_id] = int(slot.get("puan", map_data.get("nokta_puan", {}).get(slot_id, 1)))
	altin[slot_id] = int(slot.get("altin", map_data.get("nokta_altin", {}).get(slot_id, 3)))
	secilen_roller[slot_id] = str(aday.get("rol", ""))

static func _sabit_sonuc(map_data: Dictionary) -> Dictionary:
	return {
		"positions": (map_data.get("nokta_konumlari", {}) as Dictionary).duplicate(),
		"puan": (map_data.get("nokta_puan", {}) as Dictionary).duplicate(),
		"altin": (map_data.get("nokta_altin", {}) as Dictionary).duplicate(),
	}

static func _sabit_slot_doldur(map_data: Dictionary, slot_id: String, positions: Dictionary, puan: Dictionary, altin: Dictionary) -> void:
	var sabit = map_data.get("nokta_konumlari", {}) as Dictionary
	if sabit.has(slot_id):
		positions[slot_id] = sabit[slot_id]
		puan[slot_id] = int((map_data.get("nokta_puan", {}) as Dictionary).get(slot_id, 1))
		altin[slot_id] = int((map_data.get("nokta_altin", {}) as Dictionary).get(slot_id, 3))

static func _slot_pos(slot: Dictionary) -> Variant:
	if slot.has("x") and slot.has("y"):
		return Vector2(float(slot["x"]), float(slot["y"]))
	return null

static func _aday_listesi(slot: Dictionary) -> Array:
	var liste: Array = []
	var raw = slot.get("adaylar", [])
	if typeof(raw) != TYPE_ARRAY:
		return liste
	for aday in raw:
		if typeof(aday) != TYPE_DICTIONARY:
			continue
		liste.append(aday.duplicate())
	return liste

static func _aday_uygun(
	merkez: Vector2,
	slot_id: String,
	secilen: Dictionary,
	us_merkezleri: Array,
	min_mesafe: float,
	us_uzaklik: float
) -> bool:
	for us in us_merkezleri:
		if merkez.distance_to(us) < us_uzaklik:
			return false
	for diger_id in secilen:
		if diger_id == slot_id:
			continue
		var diger = secilen[diger_id] + Vector2(40, 40)
		if merkez.distance_to(diger) < min_mesafe:
			return false
	if secilen.has("C") and slot_id != "C":
		var c_merkez = secilen["C"] + Vector2(40, 40)
		if merkez.distance_to(c_merkez) < min_mesafe * 0.85:
			return false
	return true

static func _nokta_yol_mesafesi(merkez: Vector2, map_data: Dictionary, positions: Dictionary, slot_id: String) -> float:
	var min_d = INF
	for seg in _yol_segmentleri(map_data, positions, slot_id):
		min_d = minf(min_d, _nokta_segment_mesafesi(merkez, seg["a"], seg["b"]))
	min_d = minf(min_d, _nokta_segment_mesafesi(merkez, _ana_hat_bas(), _ana_hat_bit()))
	return min_d

static func _yol_segmentleri(map_data: Dictionary, positions: Dictionary, slot_id: String) -> Array:
	var segments: Array = []
	for yol in map_data.get("gorsel_yollar", []):
		if typeof(yol) != TYPE_DICTIONARY:
			continue
		var from_id = str(yol.get("from", ""))
		var to_id = str(yol.get("to", ""))
		if from_id == "" or to_id == "":
			continue
		if not positions.has(from_id) and from_id != slot_id:
			continue
		if not positions.has(to_id) and to_id != slot_id:
			continue
		segments.append({
			"a": _slot_merkez(positions, from_id),
			"b": _slot_merkez(positions, to_id),
		})
	return segments

static func _slot_merkez(positions: Dictionary, slot_id: String) -> Vector2:
	return positions[slot_id] + Vector2(40, 40)

static func _ana_hat_bas() -> Vector2:
	return Vector2(680, 1515)

static func _ana_hat_bit() -> Vector2:
	return Vector2(4380, 1515)

static func _nokta_segment_mesafesi(nokta: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var uzunluk_kare = ab.length_squared()
	if uzunluk_kare <= 0.001:
		return nokta.distance_to(a)
	var t = clampf((nokta - a).dot(ab) / uzunluk_kare, 0.0, 1.0)
	return nokta.distance_to(a + ab * t)

static func _karistir(liste: Array, rng: RandomNumberGenerator) -> void:
	for i in range(liste.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = liste[i]
		liste[i] = liste[j]
		liste[j] = tmp
