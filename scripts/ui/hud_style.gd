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

static func minimap_panel_style() -> StyleBoxFlat:
	return _panel_style(
		Color(0.06, 0.08, 0.1, 0.9),
		Color(0.52, 0.43, 0.26, 0.7),
		Color(0, 0, 0, 0.3),
		3
	)

static func minimap_surface_color() -> Color:
	return Color(0.18, 0.25, 0.16, 0.95)
