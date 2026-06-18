extends RefCounted
class_name HudFormatter

static func battle_status(morale: float, weather: String, ult_percent: float) -> String:
	return "Moral %d | Hava %s | Ult %d%%" % [int(morale), weather, int(ult_percent)]

static func match_summary(osm: Dictionary, rom: Dictionary) -> String:
	return "OSM K/D: %d/%d | Hasar: %d\nROM K/D: %d/%d | Hasar: %d\nNokta Sure O/R: %ds / %ds" % [
		int(osm.get("oldurme", 0)),
		int(osm.get("kayip", 0)),
		int(osm.get("hasar", 0)),
		int(rom.get("oldurme", 0)),
		int(rom.get("kayip", 0)),
		int(rom.get("hasar", 0)),
		int(osm.get("nokta_sure", 0.0)),
		int(rom.get("nokta_sure", 0.0)),
	]

static func ai_army_label(parts: Array, used_capacity: int, target_capacity: int) -> String:
	var text = "Kuruluyor..."
	if parts.size() > 0:
		text = ", ".join(parts)
	return text + "\n(" + str(used_capacity) + "/" + str(target_capacity) + " kt)"

static func promotion_summary(osmanli_promotions: Dictionary) -> String:
	if osmanli_promotions.is_empty():
		return "Terfi: henuz yok"
	var parts: Array = []
	for unit_name in osmanli_promotions:
		var level = int(osmanli_promotions[unit_name].get("seviye", 0))
		if level > 0:
			parts.append(unit_name + " Lv" + str(level))
	if parts.is_empty():
		return "Terfi: kullan, seviye kazan"
	return "Terfi: " + ", ".join(parts)

static func save_stats(stats: Dictionary) -> String:
	return "G:%d M:%d B:%d" % [
		int(stats.get("galibiyet", 0)),
		int(stats.get("maglubiyet", 0)),
		int(stats.get("beraberlik", 0)),
	]
