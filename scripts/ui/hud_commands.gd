extends RefCounted
class_name HudCommands

static func button_definitions() -> Array:
	return [
		{"id": "hareket", "text": "↔"},
		{"id": "saldir", "text": "⚔"},
		{"id": "pusu", "text": "🌲"},
		{"id": "savun", "text": "🛡"},
		{"id": "geri_cekil", "text": "↩"},
		{"id": "ult", "text": "★"},
	]

static func button_state(komut_id: String, secili_var: bool, secili_komut: String, ult_hazir: bool) -> Dictionary:
	var secim_gerektirir = komut_id in ["saldir", "pusu", "savun", "geri_cekil"]
	var disabled = secim_gerektirir and not secili_var
	if disabled:
		return {"disabled": true, "modulate": Color(0.7, 0.7, 0.72, 0.65)}
	if komut_id in ["hareket", "saldir", "pusu"] and secili_komut == komut_id:
		return {"disabled": false, "modulate": Color(1.22, 1.16, 0.92, 1.0)}
	if komut_id == "ult" and ult_hazir:
		return {"disabled": false, "modulate": Color(1.18, 1.12, 0.78, 1.0)}
	return {"disabled": false, "modulate": Color(1, 1, 1, 1)}

static func resolve_click_action(komut_id: String) -> String:
	if komut_id == "savun":
		return "savun"
	if komut_id == "geri_cekil":
		return "geri_cekil"
	if komut_id == "ult":
		return "ult"
	return "sec"
