extends RefCounted
class_name GameData

const UNITS_OSMANLI_PATH = "res://data/units/osmanli.json"
const UNITS_DOGU_ROMA_PATH = "res://data/units/dogu_roma.json"
const USTUNLUK_PATH = "res://data/combat/ustunluk.json"
const CAMPAIGN_PATH = "res://data/campaign.json"
const MAPS_DIR = "res://data/maps/"

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("JSON bulunamadi: " + path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("JSON dosyasi acilamadi: " + path + " (hata: " + str(FileAccess.get_open_error()) + ")")
		return null
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("JSON okunamadi: " + path)
		return null
	return json.data

static func _parse_color(raw) -> Color:
	if raw is Color:
		return raw
	if typeof(raw) == TYPE_ARRAY and raw.size() >= 3:
		return Color(float(raw[0]), float(raw[1]), float(raw[2]))
	return Color.WHITE

static func _parse_unit(entry: Dictionary) -> Dictionary:
	var menzil = float(entry.get("menzil", 80.0))
	return {
		"id": str(entry.get("id", entry.get("isim", ""))),
		"isim": str(entry.get("isim", "")),
		"hiz": float(entry.get("hiz", 50.0)),
		"renk": _parse_color(entry.get("renk", [1, 1, 1])),
		"sembol": str(entry.get("sembol", "?")),
		"guc": int(entry.get("guc", 10)),
		"savunma": int(entry.get("savunma", 5)),
		"hp": int(entry.get("hp", 50)),
		"kontenjan": int(entry.get("kontenjan", 1)),
		"maliyet": int(entry.get("maliyet", 10)),
		"asker_sayisi": int(entry.get("asker_sayisi", 10)),
		"menzil": menzil,
		"gorus_yaricapi": float(entry.get("gorus_yaricapi", menzil + 30.0)),
		"sprite": str(entry.get("sprite", "")),
	}

static func load_units(faction: String) -> Array:
	var path = UNITS_OSMANLI_PATH if faction == "osmanli" else UNITS_DOGU_ROMA_PATH
	var data = _read_json(path)
	if typeof(data) != TYPE_ARRAY:
		return []
	var units: Array = []
	for entry in data:
		if typeof(entry) == TYPE_DICTIONARY:
			units.append(_parse_unit(entry))
	return units

static func load_ustunluk() -> Dictionary:
	var data = _read_json(USTUNLUK_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data.duplicate(true)

static func load_campaign_map_ids() -> Array:
	var data = _read_json(CAMPAIGN_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return ["trakya"]
	var bolgeler = data.get("bolgeler", [])
	if typeof(bolgeler) != TYPE_ARRAY or bolgeler.is_empty():
		return ["trakya"]
	return bolgeler.duplicate()

static func load_map(map_id: String) -> Dictionary:
	var path = MAPS_DIR + map_id + ".json"
	var data = _read_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return parse_map(data)

static func parse_map(data: Dictionary) -> Dictionary:
	var nokta_konumlari: Dictionary = {}
	var raw_noktalar = data.get("noktalar", {})
	if typeof(raw_noktalar) == TYPE_DICTIONARY:
		for nokta in raw_noktalar:
			var pos = raw_noktalar[nokta]
			if typeof(pos) == TYPE_ARRAY and pos.size() >= 2:
				nokta_konumlari[nokta] = Vector2(float(pos[0]), float(pos[1]))

	var sinir = data.get("sinir", {})
	var bounds = {
		"min_x": float(sinir.get("min_x", 20.0)),
		"max_x": float(sinir.get("max_x", 980.0)),
		"min_y": float(sinir.get("min_y", 80.0)),
		"max_y": float(sinir.get("max_y", 440.0)),
	}

	var arazi_bolgeleri: Array = []
	var raw_araziler = data.get("araziler", [])
	if typeof(raw_araziler) == TYPE_ARRAY:
		for raw in raw_araziler:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var x = float(raw.get("x", 0.0))
			var y = float(raw.get("y", 0.0))
			var w = float(raw.get("w", 0.0))
			var h = float(raw.get("h", 0.0))
			arazi_bolgeleri.append({
				"tip": str(raw.get("tip", "duz_arazi")),
				"x": x,
				"y": y,
				"w": w,
				"h": h,
				"rect": Rect2(Vector2(x, y), Vector2(w, h)),
				"savunma_bonus": float(raw.get("savunma_bonus", 1.0)),
				"hiz_bonus": float(raw.get("hiz_bonus", 1.0)),
				"tek_sira": bool(raw.get("tek_sira", false)),
				"suvari_yavaslama": float(raw.get("suvari_yavaslama", 1.0)),
				"gizlenme": bool(raw.get("gizlenme", false)),
			})
	else:
		var raw_ormanlar = data.get("ormanlar", [])
		if typeof(raw_ormanlar) == TYPE_ARRAY:
			for raw in raw_ormanlar:
				if typeof(raw) != TYPE_DICTIONARY:
					continue
				var x = float(raw.get("x", 0.0))
				var y = float(raw.get("y", 0.0))
				var w = float(raw.get("w", 0.0))
				var h = float(raw.get("h", 0.0))
				arazi_bolgeleri.append({
					"tip": "orman",
					"x": x,
					"y": y,
					"w": w,
					"h": h,
					"rect": Rect2(Vector2(x, y), Vector2(w, h)),
					"savunma_bonus": 1.0,
					"hiz_bonus": 1.0,
					"tek_sira": false,
					"suvari_yavaslama": 1.0,
					"gizlenme": true,
				})

	var bolge_etiketleri: Array = []
	var raw_etiketler = data.get("bolge_etiketleri", [])
	if typeof(raw_etiketler) == TYPE_ARRAY:
		for raw in raw_etiketler:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			bolge_etiketleri.append({
				"metin": str(raw.get("metin", "")),
				"x": float(raw.get("x", 0.0)),
				"y": float(raw.get("y", 0.0)),
			})

	return {
		"id": str(data.get("id", "")),
		"isim": str(data.get("isim", data.get("id", "Harita"))),
		"nokta_konumlari": nokta_konumlari,
		"nokta_puan": data.get("nokta_puan", {"A": 1, "B": 1, "C": 3, "D": 1, "E": 1}).duplicate(),
		"nokta_altin": data.get("nokta_altin", {"A": 3, "B": 3, "C": 6, "D": 3, "E": 3}).duplicate(),
		"sinir": bounds,
		"arazi_bolgeleri": arazi_bolgeleri,
		"bolge_etiketleri": bolge_etiketleri,
		"arkaplan": str(data.get("arkaplan", "")),
	}

static func campaign_region_names(map_ids: Array) -> Array:
	var names: Array = []
	for map_id in map_ids:
		var map_data = load_map(str(map_id))
		if map_data.is_empty():
			names.append(str(map_id))
		else:
			names.append(str(map_data.get("isim", map_id)))
	return names
