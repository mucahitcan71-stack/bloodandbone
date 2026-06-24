extends RefCounted
class_name HudActiveUnits

const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")

var _last_id_signature: String = ""
var _on_unit_select: Callable = Callable()

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
	scroll.custom_minimum_size = Vector2(0, 34)
	block.add_child(scroll)

	var row = HBoxContainer.new()
	row.name = "SahadaKartSatir"
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	return row

func update(deps: Dictionary) -> void:
	var ui_node = deps.get("ui_node") as Callable
	if not ui_node.is_valid():
		return
	_on_unit_select = deps.get("on_unit_select", Callable()) as Callable
	if bool(deps.get("hazirlik_fazi", true)):
		_hide_strip(ui_node)
		_last_id_signature = ""
		return

	var orta_vbox = _find_orta_vbox(ui_node)
	if orta_vbox == null:
		return
	var row = ensure_shell(orta_vbox)
	var block = orta_vbox.get_node_or_null("SahadaStripBlock") as VBoxContainer
	if block != null:
		block.visible = true

	var units = _filter_units(deps.get("aktif_birimler", []))
	var signature = _id_signature(units)
	if signature != _last_id_signature:
		_rebuild_cards(row, units, _strip_width(orta_vbox))
		_last_id_signature = signature
	else:
		_refresh_card_content(row, units)

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

func _type_labels(units: Array) -> Array:
	var counts: Dictionary = {}
	var labels: Array = []
	for birim in units:
		var isim = str(birim.get("isim", "Birim"))
		var sira = int(counts.get(isim, 0)) + 1
		counts[isim] = sira
		labels.append(isim + " " + str(sira))
	return labels

func _rebuild_cards(row: HBoxContainer, units: Array, strip_width: float) -> void:
	for child in row.get_children():
		child.queue_free()
	if units.is_empty():
		var bos = Label.new()
		bos.text = "—"
		bos.add_theme_font_size_override("font_size", 8)
		bos.add_theme_color_override("font_color", Color(0.62, 0.64, 0.6))
		row.add_child(bos)
		return

	var labels = _type_labels(units)
	var kart_genislik = HudInventory.calculate_active_card_width(units.size(), strip_width)
	for i in range(units.size()):
		var birim = units[i]
		var kart = _build_card(birim, str(labels[i]), kart_genislik)
		row.add_child(kart)

func _refresh_card_content(row: HBoxContainer, units: Array) -> void:
	var labels = _type_labels(units)
	var idx = 0
	for child in row.get_children():
		if not child.has_meta("unit_id"):
			continue
		if idx >= units.size():
			break
		_apply_card_content(child as Control, units[idx], str(labels[idx]))
		idx += 1

func _build_card(birim: Dictionary, baslik_metin: String, genislik: float) -> Button:
	var btn = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(genislik, 30)
	btn.focus_mode = Control.FOCUS_NONE
	var unit_id = int(birim.get("id", -1))
	btn.set_meta("unit_id", unit_id)
	btn.add_theme_stylebox_override("normal", HudStyle.active_unit_card_style())
	btn.add_theme_stylebox_override("hover", HudStyle.inventory_card_hover())
	btn.add_theme_stylebox_override("pressed", HudStyle.inventory_card_pressed())
	btn.pressed.connect(func(): _handle_card_click(unit_id))
	_apply_card_content(btn, birim, baslik_metin)
	return btn

func _handle_card_click(unit_id: int) -> void:
	if unit_id < 0 or not _on_unit_select.is_valid():
		return
	_on_unit_select.call(unit_id)

func _apply_card_content(kart: Control, birim: Dictionary, baslik_metin: String) -> void:
	for c in kart.get_children():
		c.queue_free()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kart.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var ad = Label.new()
	ad.name = "SahadaKartAd"
	ad.text = baslik_metin
	ad.add_theme_font_size_override("font_size", 8)
	ad.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76))
	ad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ad)

	var alt = HBoxContainer.new()
	alt.add_theme_constant_override("separation", 4)
	alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(alt)

	var hp = Label.new()
	hp.name = "SahadaKartHp"
	hp.text = _hp_metni(birim)
	hp.add_theme_font_size_override("font_size", 7)
	hp.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt.add_child(hp)

	var durum = Label.new()
	durum.name = "SahadaKartDurum"
	durum.text = _durum_kisa(birim)
	durum.add_theme_font_size_override("font_size", 7)
	durum.add_theme_color_override("font_color", Color(0.7, 0.74, 0.68))
	durum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt.add_child(durum)

func _hp_metni(birim: Dictionary) -> String:
	var max_hp = max(1, int(birim.get("max_hp", birim.get("hp", 1))))
	var cur_hp = max(0, int(birim.get("hp", 0)))
	return "HP %d/%d" % [cur_hp, max_hp]

static func _durum_kisa(birim: Dictionary) -> String:
	if birim.get("pusu_modunda", false):
		return "Pusu"
	if birim.get("geri_cekiliyor", false):
		return "Geri"
	if birim.get("savunma_modunda", false):
		return "Savun"
	if birim.get("savas_halinde", false):
		return "Savas"
	var konum = birim.get("konum", Vector2.ZERO)
	var hedef = birim.get("hedef", konum)
	if konum.distance_to(hedef) > 8.0:
		return "Hareket"
	return "Hazir"
