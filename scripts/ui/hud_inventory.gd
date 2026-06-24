extends RefCounted
class_name HudInventory

static func calculate_card_width(kart_sayisi: int, alan: float, bosluk: float = 7.0) -> float:
	var safe_kart_sayisi = max(1, kart_sayisi)
	var toplam_bosluk = bosluk * float(safe_kart_sayisi - 1)
	return clampf((alan - toplam_bosluk) / float(safe_kart_sayisi), 56.0, 82.0)

static func card_height() -> float:
	return 46.0

static func card_separation() -> float:
	return 7.0

static func calculate_active_card_width(kart_sayisi: int, alan: float, bosluk: float = 5.0) -> float:
	return float(active_card_layout(kart_sayisi, alan, bosluk).get("width", 52.0))

static func active_card_layout(kart_sayisi: int, alan: float, bosluk: float = -1.0) -> Dictionary:
	var count = max(1, kart_sayisi)
	var gap = bosluk if bosluk >= 0.0 else active_card_separation(count)
	var compact = count > 5
	var ultra = count > 10
	var width: float
	if ultra:
		width = 46.0
	elif count <= 5:
		var toplam_bosluk = gap * float(count - 1)
		width = clampf((alan - toplam_bosluk) / float(count), 72.0, 90.0)
	elif count <= 10:
		var toplam_bosluk = gap * float(count - 1)
		width = clampf((alan - toplam_bosluk) / float(count), 52.0, 66.0)
	else:
		width = 46.0
	return {
		"width": width,
		"height": 34.0 if compact else 36.0,
		"gap": gap,
		"compact": compact,
		"ultra": ultra,
	}

static func active_card_separation(kart_sayisi: int) -> float:
	if kart_sayisi > 10:
		return 4.0
	if kart_sayisi > 5:
		return 5.0
	return 6.0

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
