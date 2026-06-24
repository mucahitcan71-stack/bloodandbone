extends RefCounted
class_name HudActiveUnits

const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")

var _last_layout_signature: String = ""
var _on_unit_select: Callable = Callable()
var _on_reserve_select: Callable = Callable()
var _on_reserve_context: Callable = Callable()
var _on_add_unit: Callable = Callable()
var _on_add_unit_context: Callable = Callable()

const _ISIM_KISALTMA: Dictionary = {
	"Akıncı": "Akn",
	"Akinci": "Akn",
	"Yeniçeri": "Yen",
	"Yeniceri": "Yen",
	"Sipahi": "Sip",
	"Azap": "Azp",
	"Topçu": "Top",
	"Topcu": "Top",
	"Kapıkulu": "Kap",
	"Kapikulu": "Kap",
	"General": "Gen",
}

func ensure_shell(parent: VBoxContainer) -> HBoxContainer:
	var block = parent.get_node_or_null("SahadaStripBlock") as VBoxContainer
	if block != null:
		var baslik = block.get_node_or_null("Label_SahadaBaslik")
		if baslik != null:
			baslik.visible = false
		return block.get_node_or_null("SahadaScroll/SahadaKartSatir") as HBoxContainer
	block = VBoxContainer.new()
	block.name = "SahadaStripBlock"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(block)
	parent.move_child(block, 0)

	var scroll = ScrollContainer.new()
	scroll.name = "SahadaScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 52)
	block.add_child(scroll)

	var row = HBoxContainer.new()
	row.name = "SahadaKartSatir"
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 6)
	scroll.add_child(row)
	return row

func update(deps: Dictionary) -> void:
	var ui_node = deps.get("ui_node") as Callable
	if not ui_node.is_valid():
		return
	_on_unit_select = deps.get("on_unit_select", Callable()) as Callable
	_on_reserve_select = deps.get("on_reserve_select", Callable()) as Callable
	_on_reserve_context = deps.get("on_reserve_context", Callable()) as Callable
	_on_add_unit = deps.get("on_add_unit", Callable()) as Callable
	_on_add_unit_context = deps.get("on_add_unit_context", Callable()) as Callable
	if bool(deps.get("hazirlik_fazi", true)):
		_hide_strip(ui_node)
		_last_layout_signature = ""
		return

	var orta_vbox = _find_orta_vbox(ui_node)
	if orta_vbox == null:
		return
	var row = ensure_shell(orta_vbox)
	var block = orta_vbox.get_node_or_null("SahadaStripBlock") as VBoxContainer
	if block != null:
		block.visible = true

	var units = _filter_units(deps.get("aktif_birimler", []))
	var reserve_cards = _build_reserve_cards(
		deps.get("envanter", []),
		deps.get("osmanli_birim_tipleri", []),
		str(deps.get("secili_envanter_tip_anahtari", ""))
	)
	var selected_type_idx = _selected_type_idx(deps.get("osmanli_birim_tipleri", []), str(deps.get("secili_envanter_tip_anahtari", "")))
	var cards = _merge_cards(units, reserve_cards, selected_type_idx)
	var secili_id = _selected_unit_id(deps.get("secili_birim"))
	var strip_width = _strip_width(orta_vbox)
	var layout = HudInventory.active_card_layout(cards.size(), strip_width)
	var signature = _layout_signature(cards, layout)
	if signature != _last_layout_signature:
		row.add_theme_constant_override("separation", int(layout.get("gap", 6)))
		_rebuild_cards(row, cards, layout)
		_last_layout_signature = signature
	else:
		_refresh_card_content(row, cards, layout)
	_apply_selection_visuals(row, secili_id, int(deps.get("secili_envanter_idx", -1)))

func _hide_strip(ui_node: Callable) -> void:
	var orta_vbox = _find_orta_vbox(ui_node)
	if orta_vbox == null:
		return
	var block = orta_vbox.get_node_or_null("SahadaStripBlock")
	if block != null:
		block.visible = false

func _find_orta_vbox(ui_node: Callable) -> VBoxContainer:
	var orta_modul = ui_node.call("HudOrtaModul") as PanelContainer
	if orta_modul == null:
		return null
	var margin = orta_modul.get_child(0) as MarginContainer
	if margin == null:
		return null
	return margin.get_child(0) as VBoxContainer

func _strip_width(orta_vbox: VBoxContainer) -> float:
	var w = orta_vbox.size.x
	if w > 0.0:
		return w - 8.0
	return 420.0

func _filter_units(aktif_birimler: Array) -> Array:
	var units: Array = []
	for birim in aktif_birimler:
		if birim.get("taraf", "") != "osmanli":
			continue
		if int(birim.get("hp", 0)) <= 0:
			continue
		units.append(birim)
	units.sort_custom(func(a, b) -> bool:
		return _strip_sort_key(a, -1) < _strip_sort_key(b, -1)
	)
	return units

func _layout_signature(cards: Array, layout: Dictionary) -> String:
	if cards.is_empty():
		return ""
	var parts: PackedStringArray = []
	for card in cards:
		var card_type = str(card.get("card_type", ""))
		if card_type == "action":
			parts.append("a")
		else:
			parts.append("s" + str(int(card.get("strip_slot", -1))) + card_type[0])
	return "%s#%d#%d" % [",".join(parts), cards.size(), int(layout.get("width", 0))]

func _selected_unit_id(secili_birim) -> int:
	if secili_birim == null:
		return -1
	if secili_birim is Dictionary:
		if secili_birim.is_empty():
			return -1
		if str(secili_birim.get("taraf", "")) != "osmanli":
			return -1
		if int(secili_birim.get("hp", 0)) <= 0:
			return -1
		return int(secili_birim.get("id", -1))
	return -1

func _apply_selection_visuals(row: HBoxContainer, secili_id: int, secili_reserve_idx: int) -> void:
	for child in row.get_children():
		if child is not Button:
			continue
		var btn = child as Button
		var card_type = str(btn.get_meta("card_type", ""))
		if card_type == "field":
			var unit_id = int(btn.get_meta("unit_id", -1))
			_apply_card_visual_state(btn, unit_id >= 0 and unit_id == secili_id, false)
		elif card_type == "reserve":
			var reserve_idx = int(btn.get_meta("reserve_index", -1))
			_apply_card_visual_state(btn, reserve_idx >= 0 and reserve_idx == secili_reserve_idx, true)
		elif card_type == "action":
			_apply_card_visual_state(btn, false, false)

func _apply_card_visual_state(btn: Button, selected: bool, reserve: bool) -> void:
	var compact = bool(btn.get_meta("card_compact", false))
	if selected:
		btn.add_theme_stylebox_override("normal", HudStyle.active_unit_card_selected())
		btn.add_theme_stylebox_override("hover", HudStyle.active_unit_card_selected())
		btn.modulate = HudInventory.selected_modulate()
	elif reserve:
		btn.add_theme_stylebox_override("normal", HudStyle.inventory_card_disabled())
		btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_disabled())
		btn.modulate = HudInventory.dimmed_modulate()
	elif compact:
		btn.add_theme_stylebox_override("normal", HudStyle.active_unit_card_compact_style())
		btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_hover())
		btn.modulate = Color(1, 1, 1, 1)
	else:
		btn.add_theme_stylebox_override("normal", HudStyle.active_unit_card_style())
		btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_hover())
		btn.modulate = Color(1, 1, 1, 1)
	btn.add_theme_stylebox_override("pressed", HudStyle.inventory_card_pressed())

func _type_labels(units: Array, compact: bool) -> Array:
	var counts: Dictionary = {}
	var labels: Array = []
	for birim in units:
		var isim = str(birim.get("isim", "Birim"))
		var sira = int(counts.get(isim, 0)) + 1
		counts[isim] = sira
		labels.append(_format_card_label(isim, sira, compact))
	return labels

func _format_card_label(isim: String, sira: int, compact: bool) -> String:
	var ad = str(_ISIM_KISALTMA.get(isim, isim)) if compact else isim
	return ad + " " + str(sira)

func _build_reserve_cards(envanter: Array, tipler: Array, secili_type_key: String) -> Array:
	var cards: Array = []
	var tip_index: Dictionary = {}
	for i in range(tipler.size()):
		tip_index[_inventory_key(tipler[i])] = i
	var reserve_counts: Dictionary = {}
	for i in range(envanter.size()):
		var tip = envanter[i]
		var isim = str(tip.get("isim", "Yedek"))
		var sira = int(reserve_counts.get(isim, 0)) + 1
		reserve_counts[isim] = sira
		var key = _inventory_key(tip)
		cards.append({
			"card_type": "reserve",
			"display_name": _format_card_label(isim, sira, true),
			"unit_name": isim,
			"reserve_index": i,
			"strip_slot": _strip_sort_key(tip, i),
			"type_key": key,
			"type_idx": int(tip_index.get(key, -1)),
			"status_text": "Yedek",
		})
	return cards

func _merge_cards(units: Array, reserve_cards: Array, selected_type_idx: int) -> Array:
	var cards: Array = []
	var labels = _type_labels(units, false)
	for i in range(units.size()):
		var birim = units[i]
		cards.append({
			"card_type": "field",
			"display_name": str(labels[i]),
			"unit_name": str(birim.get("isim", "Birim")),
			"field_unit_id": int(birim.get("id", -1)),
			"strip_slot": _strip_sort_key(birim, -1),
			"unit": birim,
		})
	for reserve_card in reserve_cards:
		cards.append(reserve_card)
	cards.sort_custom(func(a, b) -> bool:
		return int(a.get("strip_slot", 999999)) < int(b.get("strip_slot", 999999))
	)
	if selected_type_idx >= 0:
		cards.append({
			"card_type": "action",
			"display_name": "+ Birim",
			"status_text": "Ekle",
			"type_idx": selected_type_idx,
		})
	return cards

func _selected_type_idx(tipler: Array, secili_type_key: String) -> int:
	if tipler.is_empty():
		return -1
	if secili_type_key == "":
		return 0
	for i in range(tipler.size()):
		if _inventory_key(tipler[i]) == secili_type_key:
			return i
	return 0

func _rebuild_cards(row: HBoxContainer, cards: Array, layout: Dictionary) -> void:
	for child in row.get_children():
		child.queue_free()
	if cards.is_empty():
		var bos = Label.new()
		bos.text = "—"
		bos.add_theme_font_size_override("font_size", 8)
		bos.add_theme_color_override("font_color", Color(0.62, 0.64, 0.6))
		row.add_child(bos)
		return

	var kart_genislik = float(layout.get("width", 52.0))
	var kart_yukseklik = float(layout.get("height", 36.0))
	for card in cards:
		row.add_child(_build_card(card, kart_genislik, kart_yukseklik, layout))

func _refresh_card_content(row: HBoxContainer, cards: Array, layout: Dictionary) -> void:
	var field_by_id: Dictionary = {}
	var reserve_by_idx: Dictionary = {}
	var action_card: Dictionary = {}
	for card in cards:
		var card_type = str(card.get("card_type", ""))
		if card_type == "field":
			field_by_id[int(card.get("field_unit_id", -1))] = card
		elif card_type == "reserve":
			reserve_by_idx[int(card.get("reserve_index", -1))] = card
		elif card_type == "action":
			action_card = card
	for child in row.get_children():
		if child is not Button:
			continue
		var btn = child as Button
		var card_type = str(btn.get_meta("card_type", ""))
		if card_type == "field":
			var unit_id = int(btn.get_meta("unit_id", -1))
			if field_by_id.has(unit_id):
				_update_card_live(btn, field_by_id[unit_id], layout)
		elif card_type == "reserve":
			var reserve_index = int(btn.get_meta("reserve_index", -1))
			if reserve_by_idx.has(reserve_index):
				_update_card_live(btn, reserve_by_idx[reserve_index], layout)
		elif card_type == "action" and not action_card.is_empty():
			_update_card_live(btn, action_card, layout)

func _build_card(card: Dictionary, genislik: float, yukseklik: float, layout: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(genislik, yukseklik)
	btn.focus_mode = Control.FOCUS_NONE
	var card_type = str(card.get("card_type", ""))
	btn.set_meta("card_type", card_type)
	if card_type == "field":
		btn.set_meta("unit_id", int(card.get("field_unit_id", -1)))
	elif card_type == "reserve":
		btn.set_meta("reserve_index", int(card.get("reserve_index", -1)))
		btn.set_meta("type_key", str(card.get("type_key", "")))
		btn.set_meta("type_idx", int(card.get("type_idx", -1)))
	elif card_type == "action":
		btn.set_meta("type_idx", int(card.get("type_idx", -1)))
	btn.set_meta("card_compact", bool(layout.get("compact", false)))
	btn.set_meta("card_ultra", bool(layout.get("ultra", false)))
	var normal_style = HudStyle.inventory_card_disabled() if card_type == "reserve" else (HudStyle.active_unit_card_style() if not bool(layout.get("compact", false)) else HudStyle.active_unit_card_compact_style())
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_disabled() if card_type == "reserve" else HudStyle.inventory_card_hover())
	btn.add_theme_stylebox_override("pressed", HudStyle.inventory_card_pressed())
	if card_type == "field":
		var unit_id = int(card.get("field_unit_id", -1))
		btn.pressed.connect(func(): _handle_field_click(unit_id))
	elif card_type == "reserve":
		var reserve_index = int(card.get("reserve_index", -1))
		var type_idx = int(card.get("type_idx", -1))
		btn.pressed.connect(func(): _handle_reserve_click(reserve_index))
		btn.gui_input.connect(func(event: InputEvent): _handle_reserve_input(event, type_idx))
	else:
		var type_idx = int(card.get("type_idx", -1))
		btn.pressed.connect(func(): _handle_add_unit_click(type_idx))
		btn.gui_input.connect(func(event: InputEvent): _handle_add_unit_input(event, type_idx))
	_ensure_card_structure(btn, layout)
	_update_card_live(btn, card, layout)
	return btn

func _ensure_card_structure(btn: Button, layout: Dictionary = {}) -> void:
	if btn.get_node_or_null("SahadaKartMargin") != null:
		return
	var compact = bool(layout.get("compact", false))
	var pad = 3 if compact else 4
	var margin = MarginContainer.new()
	margin.name = "SahadaKartMargin"
	margin.add_theme_constant_override("margin_left", pad)
	margin.add_theme_constant_override("margin_right", pad)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "SahadaKartVBox"
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var ad = Label.new()
	ad.name = "SahadaKartAd"
	ad.clip_text = true
	ad.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ad.add_theme_font_size_override("font_size", 7 if compact else 8)
	ad.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76))
	ad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ad)

	var hp_satir = HBoxContainer.new()
	hp_satir.name = "SahadaHpSatir"
	hp_satir.add_theme_constant_override("separation", 3)
	hp_satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_satir)

	var hp_track = Control.new()
	hp_track.name = "SahadaHpTrack"
	hp_track.custom_minimum_size = Vector2(0, 3 if compact else 4)
	hp_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_satir.add_child(hp_track)

	var hp_bg = ColorRect.new()
	hp_bg.name = "SahadaHpBg"
	hp_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_bg.color = HudStyle.active_unit_hp_bg_color()
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_track.add_child(hp_bg)

	var hp_fill = ColorRect.new()
	hp_fill.name = "SahadaHpFill"
	hp_fill.color = HudStyle.active_unit_hp_fill_color(1.0)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_track.add_child(hp_fill)

	var hp = Label.new()
	hp.name = "SahadaKartHp"
	hp.custom_minimum_size = Vector2(26 if compact else 40, 0)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp.add_theme_font_size_override("font_size", 5 if compact else 6)
	hp.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_satir.add_child(hp)

	var durum = Label.new()
	durum.name = "SahadaKartDurum"
	durum.clip_text = true
	durum.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	durum.add_theme_font_size_override("font_size", 6 if compact else 7)
	durum.add_theme_color_override("font_color", Color(0.7, 0.74, 0.68))
	durum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(durum)

func _update_card_live(btn: Button, card: Dictionary, layout: Dictionary = {}) -> void:
	if btn.get_node_or_null("SahadaKartMargin") == null:
		_ensure_card_structure(btn, layout)
	var compact = bool(layout.get("compact", btn.get_meta("card_compact", false)))
	var ultra = bool(layout.get("ultra", btn.get_meta("card_ultra", false)))
	var card_type = str(card.get("card_type", ""))
	var ad = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaKartAd") as Label
	var hp_fill = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaHpTrack/SahadaHpFill") as ColorRect
	var hp_track = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaHpTrack") as Control
	var hp = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaKartHp") as Label
	var durum = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaKartDurum") as Label
	if ad == null:
		return

	ad.text = str(card.get("display_name", "Birim"))
	if card_type == "action":
		if hp != null:
			hp.text = ""
		if hp_fill != null:
			hp_fill.color = HudStyle.active_unit_hp_bg_color()
			hp_fill.size = Vector2(0, 3.0 if compact else 4.0)
		if durum != null:
			durum.text = str(card.get("status_text", "Ekle"))
		return
	if card_type == "reserve":
		if hp != null:
			hp.text = ""
		if hp_fill != null:
			hp_fill.color = HudStyle.active_unit_hp_bg_color()
			hp_fill.size = Vector2(0, 3.0 if compact else 4.0)
		if durum != null:
			durum.text = str(card.get("status_text", "Yedek"))
		return

	var birim = card.get("unit", {})
	var max_hp = max(1.0, float(birim.get("max_hp", birim.get("hp", 1))))
	var cur_hp = max(0.0, float(birim.get("hp", 0)))
	var hp_oran = clampf(cur_hp / max_hp, 0.0, 1.0)
	if hp != null:
		if compact and max_hp > 99.0:
			hp.text = str(int(round(hp_oran * 100.0))) + "%"
		else:
			hp.text = "%d/%d" % [int(cur_hp), int(max_hp)]
	if hp_fill != null:
		hp_fill.color = HudStyle.active_unit_hp_fill_color(hp_oran)
	if hp_track != null and hp_fill != null:
		var track_w = max(6.0, hp_track.size.x)
		var bar_h = 3.0 if compact else 4.0
		hp_fill.size = Vector2(max(1.0, track_w * hp_oran), bar_h)
	if durum != null:
		durum.text = _durum_kisa(birim, ultra)

func _handle_field_click(unit_id: int) -> void:
	if unit_id < 0 or not _on_unit_select.is_valid():
		return
	_on_unit_select.call(unit_id)

func _handle_reserve_click(reserve_index: int) -> void:
	if reserve_index < 0 or not _on_reserve_select.is_valid():
		return
	_on_reserve_select.call(reserve_index)

func _handle_reserve_input(event: InputEvent, type_idx: int) -> void:
	if type_idx < 0 or not _on_reserve_context.is_valid():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_on_reserve_context.call(type_idx, event.global_position)

func _handle_add_unit_click(type_idx: int) -> void:
	if type_idx < 0 or not _on_add_unit.is_valid():
		return
	_on_add_unit.call(type_idx)

func _handle_add_unit_input(event: InputEvent, type_idx: int) -> void:
	if type_idx < 0 or not _on_add_unit_context.is_valid():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_on_add_unit_context.call(type_idx, event.global_position)

func _inventory_key(tip: Dictionary) -> String:
	var id = str(tip.get("id", ""))
	if id != "":
		return id
	return str(tip.get("isim", "birim"))

static func _strip_sort_key(entity: Dictionary, reserve_index: int) -> int:
	var slot = int(entity.get("strip_slot", -1))
	if slot >= 0:
		return slot
	if reserve_index >= 0:
		return 100000 + reserve_index
	return 200000 + int(entity.get("id", 0))

static func _durum_kisa(birim: Dictionary, ultra: bool = false) -> String:
	var metin := ""
	if birim.get("pusu_modunda", false):
		metin = "Pusu"
	elif birim.get("savunma_modunda", false):
		metin = "Savunma"
	elif birim.get("savas_halinde", false):
		metin = "Savas"
	elif int(birim.get("takip_edilen_dusman", -1)) >= 0:
		metin = "Savas"
	elif birim.get("geri_cekiliyor", false):
		metin = "Hareket"
	else:
		var konum = birim.get("konum", Vector2.ZERO)
		var hedef = birim.get("hedef", konum)
		if konum is Vector2 and hedef is Vector2 and konum.distance_to(hedef) > 8.0:
			metin = "Hareket"
		else:
			metin = "Hazir"
	if ultra:
		match metin:
			"Savunma":
				return "Sav"
			"Hareket":
				return "Hrt"
			"Hazir":
				return "Haz"
	return metin
