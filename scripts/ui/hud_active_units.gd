extends RefCounted
class_name HudActiveUnits

const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")

var _last_layout_signature: String = ""
var _on_unit_select: Callable = Callable()

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
		var row = block.get_node_or_null("SahadaScroll/SahadaKartSatir") as HBoxContainer
		return row
	block = VBoxContainer.new()
	block.name = "SahadaStripBlock"
	block.add_theme_constant_override("separation", 2)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)
	parent.move_child(block, 0)

	var baslik = Label.new()
	baslik.name = "Label_SahadaBaslik"
	baslik.text = "SAHADA"
	baslik.add_theme_font_size_override("font_size", 8)
	baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	block.add_child(baslik)

	var scroll = ScrollContainer.new()
	scroll.name = "SahadaScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 36)
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
	var secili_id = _selected_unit_id(deps.get("secili_birim"))
	var strip_width = _strip_width(orta_vbox)
	var layout = HudInventory.active_card_layout(units.size(), strip_width)
	var signature = _layout_signature(units, layout)
	if signature != _last_layout_signature:
		row.add_theme_constant_override("separation", int(layout.get("gap", 6)))
		_rebuild_cards(row, units, layout)
		_last_layout_signature = signature
	else:
		_refresh_card_content(row, units, layout)
	_apply_selection_visuals(row, secili_id)

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
		var na = str(a.get("isim", ""))
		var nb = str(b.get("isim", ""))
		if na != nb:
			return na < nb
		return int(a.get("id", 0)) < int(b.get("id", 0))
	)
	return units

func _id_signature(units: Array) -> String:
	if units.is_empty():
		return ""
	var parts: PackedStringArray = []
	for birim in units:
		parts.append(str(int(birim.get("id", -1))))
	return ",".join(parts)

func _layout_signature(units: Array, layout: Dictionary) -> String:
	return "%s#%d#%d" % [_id_signature(units), units.size(), int(layout.get("width", 0))]

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

func _apply_selection_visuals(row: HBoxContainer, secili_id: int) -> void:
	for child in row.get_children():
		if not child.has_meta("unit_id"):
			continue
		var btn = child as Button
		if btn == null:
			continue
		var unit_id = int(child.get_meta("unit_id", -1))
		_apply_card_visual_state(btn, unit_id >= 0 and unit_id == secili_id)

func _apply_card_visual_state(btn: Button, selected: bool) -> void:
	var compact = bool(btn.get_meta("card_compact", false))
	if selected:
		btn.add_theme_stylebox_override("normal", HudStyle.active_unit_card_selected())
		btn.add_theme_stylebox_override("hover", HudStyle.active_unit_card_selected())
		btn.modulate = HudInventory.selected_modulate()
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

func _rebuild_cards(row: HBoxContainer, units: Array, layout: Dictionary) -> void:
	for child in row.get_children():
		child.queue_free()
	if units.is_empty():
		var bos = Label.new()
		bos.text = "—"
		bos.add_theme_font_size_override("font_size", 8)
		bos.add_theme_color_override("font_color", Color(0.62, 0.64, 0.6))
		row.add_child(bos)
		return

	var compact = bool(layout.get("compact", false))
	var labels = _type_labels(units, compact)
	var kart_genislik = float(layout.get("width", 52.0))
	var kart_yukseklik = float(layout.get("height", 36.0))
	for i in range(units.size()):
		var birim = units[i]
		var kart = _build_card(birim, str(labels[i]), kart_genislik, kart_yukseklik, layout)
		row.add_child(kart)

func _refresh_card_content(row: HBoxContainer, units: Array, layout: Dictionary) -> void:
	var compact = bool(layout.get("compact", false))
	var labels = _type_labels(units, compact)
	var label_by_id: Dictionary = {}
	for i in range(units.size()):
		label_by_id[int(units[i].get("id", -1))] = str(labels[i])
	var unit_by_id: Dictionary = {}
	for birim in units:
		unit_by_id[int(birim.get("id", -1))] = birim
	for child in row.get_children():
		if not child.has_meta("unit_id"):
			continue
		var unit_id = int(child.get_meta("unit_id", -1))
		if not unit_by_id.has(unit_id):
			continue
		_update_card_live(child as Button, unit_by_id[unit_id], str(label_by_id.get(unit_id, "Birim")), layout)

func _build_card(birim: Dictionary, baslik_metin: String, genislik: float, yukseklik: float, layout: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(genislik, yukseklik)
	btn.focus_mode = Control.FOCUS_NONE
	var unit_id = int(birim.get("id", -1))
	btn.set_meta("unit_id", unit_id)
	btn.set_meta("card_compact", bool(layout.get("compact", false)))
	btn.set_meta("card_ultra", bool(layout.get("ultra", false)))
	var normal_style = HudStyle.active_unit_card_style() if not bool(layout.get("compact", false)) else HudStyle.active_unit_card_compact_style()
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_hover())
	btn.add_theme_stylebox_override("pressed", HudStyle.inventory_card_pressed())
	btn.pressed.connect(func(): _handle_card_click(unit_id))
	_ensure_card_structure(btn, layout)
	_update_card_live(btn, birim, baslik_metin, layout)
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

func _update_card_live(btn: Button, birim: Dictionary, baslik_metin: String, layout: Dictionary = {}) -> void:
	if btn.get_node_or_null("SahadaKartMargin") == null:
		_ensure_card_structure(btn, layout)
	var compact = bool(layout.get("compact", btn.get_meta("card_compact", false)))
	var ultra = bool(layout.get("ultra", btn.get_meta("card_ultra", false)))
	var ad = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaKartAd") as Label
	var hp_fill = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaHpTrack/SahadaHpFill") as ColorRect
	var hp_track = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaHpTrack") as Control
	var hp = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaHpSatir/SahadaKartHp") as Label
	var durum = btn.get_node("SahadaKartMargin/SahadaKartVBox/SahadaKartDurum") as Label
	if ad == null:
		return

	ad.text = baslik_metin
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

func _handle_card_click(unit_id: int) -> void:
	if unit_id < 0 or not _on_unit_select.is_valid():
		return
	_on_unit_select.call(unit_id)

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
