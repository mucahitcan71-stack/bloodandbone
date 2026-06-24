extends RefCounted
class_name HudSelectedUnitPanel

static func build(parent: VBoxContainer) -> void:
	var baslik = Label.new()
	baslik.text = "SECILI BIRLIK"
	baslik.name = "Label_SeciliBirlikBaslik"
	baslik.add_theme_font_size_override("font_size", 9)
	baslik.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	parent.add_child(baslik)

	var ad = Label.new()
	ad.name = "Label_SeciliBirlikAd"
	ad.text = "Birim secilmedi"
	ad.add_theme_font_size_override("font_size", 11)
	ad.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	parent.add_child(ad)

	var tip = Label.new()
	tip.name = "Label_SeciliBirlikTip"
	tip.text = "—"
	tip.add_theme_font_size_override("font_size", 8)
	tip.add_theme_color_override("font_color", Color(0.78, 0.8, 0.76))
	parent.add_child(tip)

	var hp_satir = HBoxContainer.new()
	hp_satir.name = "SeciliBirlikHpSatir"
	hp_satir.add_theme_constant_override("separation", 6)
	parent.add_child(hp_satir)

	var hp_track = Control.new()
	hp_track.name = "SeciliBirlikHpTrack"
	hp_track.custom_minimum_size = Vector2(0, 8)
	hp_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_satir.add_child(hp_track)

	var hp_bg = ColorRect.new()
	hp_bg.name = "SeciliBirlikHpBg"
	hp_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_bg.color = Color(0.12, 0.14, 0.16, 0.95)
	hp_track.add_child(hp_bg)

	var hp_fill = ColorRect.new()
	hp_fill.name = "SeciliBirlikHpFill"
	hp_fill.color = Color(0.72, 0.22, 0.18, 1.0)
	hp_track.add_child(hp_fill)

	var hp_text = Label.new()
	hp_text.name = "Label_SeciliBirlikHp"
	hp_text.text = "HP —"
	hp_text.custom_minimum_size = Vector2(52, 0)
	hp_text.add_theme_font_size_override("font_size", 8)
	hp_text.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	hp_satir.add_child(hp_text)

	var durum = Label.new()
	durum.name = "Label_SeciliBirlikDurum"
	durum.text = "Durum: —"
	durum.add_theme_font_size_override("font_size", 8)
	durum.add_theme_color_override("font_color", Color(0.82, 0.84, 0.8))
	parent.add_child(durum)

	var stat = Label.new()
	stat.name = "Label_SeciliBirlikStat"
	stat.text = "G —  S —  M —"
	stat.add_theme_font_size_override("font_size", 8)
	stat.add_theme_color_override("font_color", Color(0.74, 0.76, 0.72))
	parent.add_child(stat)

static func update(ui_node: Callable, unit, secili_komut: String, stats_fn: Callable) -> void:
	var ad = ui_node.call("Label_SeciliBirlikAd") as Label
	var tip_l = ui_node.call("Label_SeciliBirlikTip") as Label
	var hp_fill = ui_node.call("SeciliBirlikHpFill") as ColorRect
	var hp_track = ui_node.call("SeciliBirlikHpTrack") as Control
	var hp_text = ui_node.call("Label_SeciliBirlikHp") as Label
	var durum = ui_node.call("Label_SeciliBirlikDurum") as Label
	var stat = ui_node.call("Label_SeciliBirlikStat") as Label
	if ad == null:
		return

	if unit == null or unit.is_empty():
		ad.text = "Birim secilmedi"
		if tip_l != null:
			tip_l.text = "Haritadan bir birim sec"
		if hp_fill != null:
			hp_fill.size = Vector2.ZERO
		if hp_text != null:
			hp_text.text = "HP —"
		if durum != null:
			durum.text = "Durum: —"
		if stat != null:
			stat.text = "G —  S —  M —"
		return

	var max_hp = max(1, int(unit.get("hp", 1)))
	var cur_hp = max(0, int(unit.get("hp", 0)))
	var hp_oran = clampf(float(cur_hp) / float(max_hp), 0.0, 1.0)
	ad.text = str(unit.get("isim", "Birim"))
	if tip_l != null:
		tip_l.text = str(unit.get("taraf", "osmanli")).capitalize()
	if hp_track != null and hp_fill != null:
		var track_w = max(1.0, hp_track.size.x)
		hp_fill.size = Vector2(max(2.0, track_w * hp_oran), 8.0)
	if hp_text != null:
		hp_text.text = "HP %d/%d" % [cur_hp, max_hp]
	if durum != null:
		durum.text = "Durum: " + _durum_metni(unit, secili_komut)
	if stat != null and stats_fn.is_valid():
		var etk = stats_fn.call(unit)
		stat.text = "G %d  S %d  M %d" % [
			int(etk.get("guc", 0)),
			int(etk.get("savunma", 0)),
			int(etk.get("menzil", 0)),
		]

static func _durum_metni(unit: Dictionary, secili_komut: String) -> String:
	if unit.get("pusu_modunda", false):
		return "Pusuda"
	if unit.get("geri_cekiliyor", false):
		return "Geri cekiliyor"
	if unit.get("savunma_modunda", false):
		return "Savunuyor"
	if unit.get("savas_halinde", false):
		return "Savasiyor"
	if secili_komut != "":
		var adlar = {
			"hareket": "Hareket",
			"saldir": "Saldir",
			"pusu": "Pusu",
			"savun": "Savun",
			"geri_cekil": "Geri cekil",
		}
		return adlar.get(secili_komut, "Hazir")
	return "Hazir"
