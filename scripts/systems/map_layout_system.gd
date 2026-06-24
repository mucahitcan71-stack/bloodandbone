extends RefCounted
class_name MapLayoutSystem

const SLOT_SIRASI: Array = ["C", "D", "E"]

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

	var positions: Dictionary = {}
	var puan: Dictionary = {}
	var altin: Dictionary = {}
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

	for slot_id in SLOT_SIRASI:
		if not slotlar.has(slot_id):
			_sabit_slot_doldur(map_data, slot_id, positions, puan, altin)
			continue
		var slot = slotlar[slot_id] as Dictionary
		var adaylar = _aday_listesi(slot)
		_karistir(adaylar, rng)
		var secilen: Variant = null
		for aday in adaylar:
			var merkez = aday + Vector2(40, 40)
			if not _aday_uygun(merkez, positions, us_merkezleri, min_mesafe, us_uzaklik):
				continue
			if slot_id != "C" and positions.has("C"):
				var c_merkez = positions["C"] + Vector2(40, 40)
				if merkez.distance_to(c_merkez) < min_mesafe * 0.85:
					continue
			secilen = aday
			break
		if secilen == null and not adaylar.is_empty():
			secilen = adaylar[0]
		if secilen == null:
			_sabit_slot_doldur(map_data, slot_id, positions, puan, altin)
			continue
		positions[slot_id] = secilen
		puan[slot_id] = int(slot.get("puan", map_data.get("nokta_puan", {}).get(slot_id, 1)))
		altin[slot_id] = int(slot.get("altin", map_data.get("nokta_altin", {}).get(slot_id, 3)))

	for slot_id in map_data.get("nokta_konumlari", {}).keys():
		if positions.has(slot_id):
			continue
		_sabit_slot_doldur(map_data, str(slot_id), positions, puan, altin)

	return {"positions": positions, "puan": puan, "altin": altin}

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
		if typeof(aday) == TYPE_ARRAY and aday.size() >= 2:
			liste.append(Vector2(float(aday[0]), float(aday[1])))
	return liste

static func _aday_uygun(merkez: Vector2, secilen: Dictionary, us_merkezleri: Array, min_mesafe: float, us_uzaklik: float) -> bool:
	for us in us_merkezleri:
		if merkez.distance_to(us) < us_uzaklik:
			return false
	for slot_id in secilen:
		var diger = secilen[slot_id] + Vector2(40, 40)
		if merkez.distance_to(diger) < min_mesafe:
			return false
	return true

static func _karistir(liste: Array, rng: RandomNumberGenerator) -> void:
	for i in range(liste.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = liste[i]
		liste[i] = liste[j]
		liste[j] = tmp
