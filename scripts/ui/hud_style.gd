extends RefCounted
class_name HudStyle

const _CORNER_RADIUS := 6
const _BORDER_WIDTH := 2

static func _panel_style(bg: Color, border: Color, shadow: Color, shadow_size: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(_BORDER_WIDTH)
	style.set_corner_radius_all(_CORNER_RADIUS)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style

static func module_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.065, 0.085, 0.11, 0.91),
		Color(0.58, 0.47, 0.28, 0.72),
		Color(0, 0, 0, 0.34),
		3
	)

static func right_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.065, 0.085, 0.11, 0.93),
		Color(0.58, 0.47, 0.28, 0.75),
		Color(0, 0, 0, 0.36),
		4
	)

static func top_bar_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.065, 0.085, 0.11, 0.92),
		Color(0.58, 0.47, 0.28, 0.75),
		Color(0, 0, 0, 0.38),
		3
	)

static func objectives_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.065, 0.085, 0.11, 0.92),
		Color(0.58, 0.47, 0.28, 0.75),
		Color(0, 0, 0, 0.35),
		3
	)

static func battle_root_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.065, 0.085, 0.11, 0.92),
		Color(0.58, 0.47, 0.28, 0.72),
		Color(0, 0, 0, 0.38),
		3
	)

static func battle_bottom_shell_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.07, 0.42)
	style.border_color = Color(0.48, 0.4, 0.24, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(_CORNER_RADIUS)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 2
	return style

static func minimap_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.06, 0.08, 0.1, 0.9),
		Color(0.52, 0.43, 0.26, 0.7),
		Color(0, 0, 0, 0.3),
		3
	)

static func minimap_surface_color() -> Color:
	return Color(0.18, 0.25, 0.16, 0.95)

static func command_button_normal() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.1, 0.13, 0.95)
	s.border_color = Color(0.52, 0.42, 0.26, 0.85)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s

static func command_button_hover() -> StyleBoxFlat:
	var s = command_button_normal()
	s.bg_color = Color(0.14, 0.12, 0.08, 0.98)
	s.border_color = Color(0.78, 0.62, 0.32, 0.95)
	return s

static func command_button_pressed() -> StyleBoxFlat:
	var s = command_button_hover()
	s.bg_color = Color(0.18, 0.14, 0.08, 1.0)
	return s

static func command_button_disabled() -> StyleBoxFlat:
	var s = command_button_normal()
	s.bg_color = Color(0.06, 0.07, 0.09, 0.7)
	s.border_color = Color(0.35, 0.32, 0.24, 0.45)
	return s

static func inventory_card_normal() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	s.border_color = Color(0.48, 0.4, 0.24, 0.75)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

static func inventory_card_hover() -> StyleBoxFlat:
	var s = inventory_card_normal()
	s.border_color = Color(0.72, 0.58, 0.3, 0.9)
	return s

static func inventory_card_pressed() -> StyleBoxFlat:
	var s = inventory_card_hover()
	s.bg_color = Color(0.12, 0.1, 0.07, 0.98)
	return s

static func inventory_card_disabled() -> StyleBoxFlat:
	var s = inventory_card_normal()
	s.bg_color = Color(0.05, 0.06, 0.08, 0.55)
	s.border_color = Color(0.32, 0.3, 0.24, 0.35)
	return s

static func inventory_card_selected() -> StyleBoxFlat:
	var s = inventory_card_hover()
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_color = Color(0.92, 0.76, 0.28, 1.0)
	return s

static func speed_button_style() -> StyleBoxFlat:
	var s = command_button_normal()
	s.content_margin_left = 8
	s.content_margin_right = 8
	return s

static func active_unit_card_style() -> StyleBoxFlat:
	var s = inventory_card_normal()
	s.bg_color = Color(0.06, 0.08, 0.11, 0.9)
	s.content_margin_left = 3
	s.content_margin_right = 3
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s

static func active_unit_card_selected() -> StyleBoxFlat:
	var s = active_unit_card_style()
	s.bg_color = Color(0.11, 0.09, 0.06, 0.96)
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_color = Color(0.9, 0.74, 0.26, 0.95)
	return s
