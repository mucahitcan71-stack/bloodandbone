extends RefCounted
class_name SaveSystem

const SAVE_PATH = "user://blood_and_bone_save.json"
const SAVE_VERSION = 1

static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"kampanya_index": 0,
		"zorluk": "orta",
		"terfi_verisi": {"osmanli": {}, "dogu_roma": {}},
		"istatistik": {"galibiyet": 0, "maglubiyet": 0, "beraberlik": 0},
	}

static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_data()

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_data()

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return default_data()

	return merge_defaults(json.data)

static func merge_defaults(data: Dictionary) -> Dictionary:
	var out = default_data()
	for key in out:
		if data.has(key):
			out[key] = data[key]
	return out

static func save_game(data: Dictionary) -> bool:
	var payload = merge_defaults(data)
	payload["version"] = SAVE_VERSION

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Kayit dosyasi yazilamadi: " + SAVE_PATH)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true
