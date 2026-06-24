extends RefCounted
class_name HudInventory

static func calculate_card_width(kart_sayisi: int, alan: float, bosluk: float = 7.0) -> float:
	var safe_kart_sayisi = max(1, kart_sayisi)
	var toplam_bosluk = bosluk * float(safe_kart_sayisi - 1)
	return clampf((alan - toplam_bosluk) / float(safe_kart_sayisi), 58.0, 88.0)

static func card_height() -> float:
	return 48.0

static func card_separation() -> float:
	return 7.0

static func dimmed_modulate() -> Color:
	return Color(1, 1, 1, 0.36)

static func selected_modulate() -> Color:
	return Color(1.18, 1.12, 0.9, 1.0)

static func is_dimmed(orduda: bool, adet: int) -> bool:
	return not orduda and adet <= 0

static func should_show_context_menu(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT

static func should_block_left_click(event: InputEvent, silik: bool) -> bool:
	return silik and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
