extends RefCounted
class_name HudCommands

const HudStyle = preload("res://scripts/ui/hud_style.gd")

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
		return {"disabled": true, "selected": false, "modulate": Color(0.72, 0.72, 0.74, 0.55)}
	if komut_id in ["hareket", "saldir", "pusu"] and secili_komut == komut_id:
		return {"disabled": false, "selected": true, "modulate": Color(1.22, 1.16, 0.92, 1.0)}
	if komut_id == "ult" and ult_hazir:
		return {"disabled": false, "selected": false, "modulate": Color(1.18, 1.12, 0.78, 1.0)}
	return {"disabled": false, "selected": false, "modulate": Color(1, 1, 1, 1)}

static func apply_button_visuals(btn: Button, state: Dictionary) -> void:
	if btn == null:
		return
	var disabled = bool(state.get("disabled", false))
	var selected = bool(state.get("selected", false))
	if disabled:
		btn.add_theme_stylebox_override("normal", HudStyle.command_button_disabled())
		btn.add_theme_stylebox_override("hover", HudStyle.command_button_disabled())
		btn.add_theme_stylebox_override("pressed", HudStyle.command_button_disabled())
	elif selected:
		var s = HudStyle.command_button_pressed()
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_color = Color(0.92, 0.76, 0.28, 1.0)
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("hover", s)
		btn.add_theme_stylebox_override("pressed", s)
	else:
		btn.add_theme_stylebox_override("normal", HudStyle.command_button_normal())
		btn.add_theme_stylebox_override("hover", HudStyle.command_button_hover())
		btn.add_theme_stylebox_override("pressed", HudStyle.command_button_pressed())
	btn.add_theme_stylebox_override("disabled", HudStyle.command_button_disabled())

static func resolve_click_action(komut_id: String) -> String:
	if komut_id == "savun":
		return "savun"
	if komut_id == "geri_cekil":
		return "geri_cekil"
	if komut_id == "ult":
		return "ult"
	return "sec"
