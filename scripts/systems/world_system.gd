extends RefCounted
class_name WorldSystem

const GameData = preload("res://scripts/systems/game_data.gd")
const MapLayoutSystem = preload("res://scripts/systems/map_layout_system.gd")

const _VARSAYILAN_YOLLAR: Array = [
	{"tip": "ana", "from": "A", "to": "C"},
	{"tip": "ana", "from": "C", "to": "B"},
	{"tip": "ana", "from": "C", "to": "D"},
	{"tip": "normal", "from": "C", "to": "E"},
	{"tip": "normal", "from": "A", "to": "D"},
	{"tip": "gizli", "from": "D", "to": "E"},
]

var _root: Node2D = null
var _on_map_applied: Callable
var _on_map_visuals_extra: Callable

var aktif_harita_id = "trakya"
var harita_sinir = {"min_x": 20.0, "max_x": 980.0, "min_y": 80.0, "max_y": 440.0}
var nokta_konumlari = {}
var nokta_puan = {}
var nokta_altin = {}
var arazi_bolgeleri: Array = []
var orman_bolgeleri: Array = []
var bolge_etiketleri: Array = []
var gorsel_yollar: Array = []
var gorsel_patikalar: Array = []
var gorsel_lekeler: Array = []
var dere_yataklari: Array = []
var cevre_dekor: Array = []
var nokta_duzen: Dictionary = {}
var nokta_slotlari: Dictionary = {}
var _map_layout_kaynak: Dictionary = {}
var _sabit_nokta_konumlari: Dictionary = {}
var _sabit_nokta_puan: Dictionary = {}
var _sabit_nokta_altin: Dictionary = {}
var arazi_katmani: Node2D = null
var decor_katmani: Node2D = null
var kamera: Camera2D = null

func configure(root: Node2D) -> void:
	_root = root

func set_on_map_applied(callback: Callable) -> void:
	_on_map_applied = callback

func set_on_map_visuals_extra(callback: Callable) -> void:
	_on_map_visuals_extra = callback

func get_active_map_id() -> String:
	return aktif_harita_id

func get_map_bounds() -> Dictionary:
	return harita_sinir

func get_point_positions() -> Dictionary:
	return nokta_konumlari

func get_point_scores() -> Dictionary:
	return nokta_puan

func get_point_gold_values() -> Dictionary:
	return nokta_altin

func get_terrain_regions() -> Array:
	return arazi_bolgeleri

func get_forest_regions() -> Array:
	return orman_bolgeleri

func get_camera() -> Camera2D:
	return kamera

func get_arazi_katmani() -> Node2D:
	return arazi_katmani

func get_point_center(nokta: String) -> Vector2:
	return nokta_konumlari[nokta] + Vector2(40, 40)

func harita_uygula(map_id: String) -> void:
	var map_data = GameData.load_map(map_id)
	if map_data.is_empty():
		push_warning("Harita yuklenemedi: " + map_id)
		return
	aktif_harita_id = map_id
	_sabit_nokta_konumlari = map_data["nokta_konumlari"].duplicate()
	_sabit_nokta_puan = map_data["nokta_puan"].duplicate()
	_sabit_nokta_altin = map_data["nokta_altin"].duplicate()
	nokta_konumlari = _sabit_nokta_konumlari.duplicate()
	nokta_puan = _sabit_nokta_puan.duplicate()
	nokta_altin = _sabit_nokta_altin.duplicate()
	harita_sinir = map_data["sinir"].duplicate()
	arazi_bolgeleri = map_data.get("arazi_bolgeleri", []).duplicate(true)
	bolge_etiketleri = map_data.get("bolge_etiketleri", []).duplicate(true)
	gorsel_yollar = map_data.get("gorsel_yollar", []).duplicate(true)
	gorsel_patikalar = map_data.get("gorsel_patikalar", []).duplicate(true)
	gorsel_lekeler = map_data.get("gorsel_lekeler", []).duplicate(true)
	dere_yataklari = map_data.get("dere_yataklari", []).duplicate(true)
	cevre_dekor = map_data.get("cevre_dekor", []).duplicate(true)
	nokta_duzen = map_data.get("nokta_duzen", {}).duplicate()
	nokta_slotlari = map_data.get("nokta_slotlari", {}).duplicate()
	_map_layout_kaynak = map_data.duplicate(true)
	orman_bolgeleri = []
	for bolge in arazi_bolgeleri:
		if str(bolge.get("tip", "")) == "orman":
			orman_bolgeleri.append(bolge)
	harita_gorsellerini_guncelle()
	kamera_limitlerini_guncelle()
	if _on_map_applied.is_valid():
		_on_map_applied.call()

func noktalari_sabite_don() -> void:
	nokta_konumlari = _sabit_nokta_konumlari.duplicate()
	nokta_puan = _sabit_nokta_puan.duplicate()
	nokta_altin = _sabit_nokta_altin.duplicate()
	harita_gorsellerini_guncelle()

func mac_nokta_duzenini_uygula(seed_val: int = -1) -> void:
	if str(nokta_duzen.get("mod", "sabit")) != "aday":
		return
	if seed_val < 0:
		seed_val = randi()
	var sonuc = MapLayoutSystem.select_layout(_map_layout_kaynak, seed_val)
	nokta_konumlari = sonuc["positions"]
	nokta_puan = sonuc["puan"]
	nokta_altin = sonuc["altin"]
	harita_gorsellerini_guncelle()

func kamera_hazirla() -> void:
	if _root == null:
		return
	kamera = _root.get_node_or_null("Camera2D")
	if kamera == null:
		kamera = Camera2D.new()
		kamera.name = "Camera2D"
		_root.add_child(kamera)
	kamera.enabled = true
	kamera.position = Vector2(576, 324)
	kamera.zoom = Vector2(1, 1)

func kamera_limitlerini_guncelle() -> void:
	if kamera == null:
		return
	kamera.limit_left = int(harita_sinir["min_x"])
	kamera.limit_right = int(harita_sinir["max_x"])
	kamera.limit_top = int(harita_sinir["min_y"])
	kamera.limit_bottom = int(harita_sinir["max_y"])
	kamera_sinirla()

func kamera_sinirla() -> void:
	if kamera == null:
		return
	kamera.position.x = clamp(kamera.position.x, harita_sinir["min_x"], harita_sinir["max_x"])
	kamera.position.y = clamp(kamera.position.y, harita_sinir["min_y"], harita_sinir["max_y"])

func arazi_katmani_olustur() -> void:
	if _root == null:
		return
	if not is_instance_valid(arazi_katmani):
		arazi_katmani = Node2D.new()
		arazi_katmani.name = "AraziLayer"
		_root.add_child(arazi_katmani)
		_root.move_child(arazi_katmani, 0)
	decor_katmani_olustur()
	arazi_gorsellerini_guncelle()
	decor_gorsellerini_guncelle()

func decor_katmani_olustur() -> void:
	if _root == null or is_instance_valid(decor_katmani):
		return
	decor_katmani = Node2D.new()
	decor_katmani.name = "MapDecorLayer"
	decor_katmani.z_index = -1
	_root.add_child(decor_katmani)
	if is_instance_valid(arazi_katmani):
		var arazi_idx = arazi_katmani.get_index()
		_root.move_child(decor_katmani, arazi_idx + 1)

func build_control_points(capture_barlar: Dictionary) -> void:
	for nokta in nokta_konumlari:
		var pos = nokta_konumlari[nokta]

		var zemin = ColorRect.new()
		zemin.color = Color(0.34, 0.3, 0.22, 0.5)
		zemin.size = Vector2(132, 132)
		zemin.position = pos - Vector2(26, 26)
		zemin.name = "NoktaZemin_" + nokta
		zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zemin.z_index = -3
		_root.add_child(zemin)

		var tas_leke = ColorRect.new()
		tas_leke.color = Color(0.42, 0.38, 0.3, 0.35)
		tas_leke.size = Vector2(96, 96)
		tas_leke.position = pos - Vector2(8, 8)
		tas_leke.name = "NoktaTas_" + nokta
		tas_leke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tas_leke.z_index = -2
		_root.add_child(tas_leke)

		var halka = ColorRect.new()
		halka.color = Color(0.5, 0.44, 0.32, 0.45)
		halka.size = Vector2(104, 104)
		halka.position = pos - Vector2(12, 12)
		halka.name = "NoktaHalka_" + nokta
		halka.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halka.z_index = -1
		_root.add_child(halka)

		var cerceve = ColorRect.new()
		cerceve.color = Color(0.1, 0.1, 0.12, 0.65)
		cerceve.size = Vector2(84, 84)
		cerceve.position = pos - Vector2(2, 2)
		cerceve.name = "NoktaCerceve_" + nokta
		cerceve.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(cerceve)

		var kare = ColorRect.new()
		kare.color = Color(0.44, 0.4, 0.34, 0.94)
		kare.size = Vector2(80, 80)
		kare.position = pos
		kare.name = "Nokta_" + nokta
		_root.add_child(kare)

		var isim_l = Label.new()
		isim_l.name = "Label_Nokta_" + nokta
		isim_l.text = nokta
		isim_l.add_theme_font_size_override("font_size", 14)
		isim_l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		isim_l.position = pos + Vector2(30, 30)
		_root.add_child(isim_l)

		var bar_bg = ColorRect.new()
		bar_bg.name = "CaptureBg_" + nokta
		bar_bg.color = Color(0.15, 0.15, 0.18, 0.9)
		bar_bg.size = Vector2(80, 8)
		bar_bg.position = pos + Vector2(0, 85)
		_root.add_child(bar_bg)

		var bar = ColorRect.new()
		bar.color = Color(0.85, 0.72, 0.2, 1.0)
		bar.size = Vector2(40, 8)
		bar.position = pos + Vector2(0, 85)
		bar.name = "CaptureBar_" + nokta
		_root.add_child(bar)
		capture_barlar[nokta] = bar

		var puan_l = Label.new()
		puan_l.name = "Label_Puan_" + nokta
		puan_l.text = "+" + str(nokta_puan[nokta])
		puan_l.position = pos + Vector2(30, -20)
		_root.add_child(puan_l)

func birimin_arazisini_bul(konum: Vector2) -> Dictionary:
	for nokta in nokta_konumlari:
		if konum.distance_to(get_point_center(nokta)) <= 85.0:
			return {"tip": "duz_arazi"}
	for bolge in arazi_bolgeleri:
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.has_point(konum):
			return bolge
	return {"tip": "duz_arazi"}

func orman_bolge_index(pos: Vector2) -> int:
	for i in range(arazi_bolgeleri.size()):
		var bolge = arazi_bolgeleri[i]
		if str(bolge.get("tip", "")) != "orman":
			continue
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.has_point(pos):
			return i
	return -1

func harita_gorsellerini_guncelle() -> void:
	if _root == null:
		return
	decor_katmani_olustur()
	arazi_gorsellerini_guncelle()
	decor_gorsellerini_guncelle()
	for nokta in nokta_konumlari:
		var pos = nokta_konumlari[nokta]
		_nokta_gorsel_konumla(nokta, pos)
	if _on_map_visuals_extra.is_valid():
		_on_map_visuals_extra.call()

func _nokta_gorsel_konumla(nokta: String, pos: Vector2) -> void:
	if _root.has_node("NoktaZemin_" + nokta):
		_root.get_node("NoktaZemin_" + nokta).position = pos - Vector2(26, 26)
	if _root.has_node("NoktaTas_" + nokta):
		_root.get_node("NoktaTas_" + nokta).position = pos - Vector2(8, 8)
	if _root.has_node("NoktaHalka_" + nokta):
		_root.get_node("NoktaHalka_" + nokta).position = pos - Vector2(12, 12)
	if _root.has_node("NoktaCerceve_" + nokta):
		_root.get_node("NoktaCerceve_" + nokta).position = pos - Vector2(2, 2)
	if _root.has_node("Nokta_" + nokta):
		_root.get_node("Nokta_" + nokta).position = pos
	if _root.has_node("Label_Nokta_" + nokta):
		_root.get_node("Label_Nokta_" + nokta).position = pos + Vector2(30, 30)
	if _root.has_node("Label_Puan_" + nokta):
		_root.get_node("Label_Puan_" + nokta).position = pos + Vector2(30, -20)
		_root.get_node("Label_Puan_" + nokta).text = "+" + str(nokta_puan.get(nokta, 1))
	if _root.has_node("CaptureBg_" + nokta):
		_root.get_node("CaptureBg_" + nokta).position = pos + Vector2(0, 85)
	if _root.has_node("CaptureBar_" + nokta):
		_root.get_node("CaptureBar_" + nokta).position = pos + Vector2(0, 85)

func arazi_gorsellerini_guncelle() -> void:
	if not is_instance_valid(arazi_katmani):
		return
	for c in arazi_katmani.get_children():
		c.queue_free()
	var sinir = harita_sinir
	_taban_katmani_ekle(sinir)
	_arazi_leke_katmani_ekle(sinir)
	_gorsel_lekeler_ekle()
	for i in range(arazi_bolgeleri.size()):
		var bolge = arazi_bolgeleri[i]
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var tip = str(bolge.get("tip", "duz_arazi"))
		_arazi_bolge_ciz(bolge, rect, tip, i)

func decor_gorsellerini_guncelle() -> void:
	if not is_instance_valid(decor_katmani):
		return
	for c in decor_katmani.get_children():
		c.queue_free()
	_gorsel_yollar_ekle()
	_gorsel_patikalar_ekle()
	_dere_yataklari_ekle()
	_akarsu_ekle()
	_cevre_dekor_ekle()
	_bolge_etiketleri_ekle()

func _taban_katmani_ekle(sinir: Dictionary) -> void:
	var taban = ColorRect.new()
	taban.name = "AraziTaban"
	taban.position = Vector2(sinir["min_x"], sinir["min_y"])
	taban.size = Vector2(sinir["max_x"] - sinir["min_x"], sinir["max_y"] - sinir["min_y"])
	taban.color = Color(0.16, 0.21, 0.13, 1.0)
	taban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	taban.z_index = -2
	arazi_katmani.add_child(taban)

func _arazi_leke_katmani_ekle(sinir: Dictionary) -> void:
	var w = sinir["max_x"] - sinir["min_x"]
	var h = sinir["max_y"] - sinir["min_y"]
	var lekeler = [
		{"p": Vector2(sinir["min_x"] + w * 0.08, sinir["min_y"] + h * 0.12), "s": Vector2(w * 0.42, h * 0.38), "c": Color(0.22, 0.28, 0.17, 0.55)},
		{"p": Vector2(sinir["min_x"] + w * 0.48, sinir["min_y"] + h * 0.55), "s": Vector2(w * 0.36, h * 0.32), "c": Color(0.19, 0.24, 0.15, 0.45)},
		{"p": Vector2(sinir["min_x"] + w * 0.62, sinir["min_y"] + h * 0.08), "s": Vector2(w * 0.3, h * 0.28), "c": Color(0.24, 0.3, 0.18, 0.4)},
	]
	for i in range(lekeler.size()):
		var leke_data = lekeler[i]
		var leke = ColorRect.new()
		leke.name = "AraziLeke" + str(i)
		leke.position = leke_data["p"]
		leke.size = leke_data["s"]
		leke.color = leke_data["c"]
		leke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leke.z_index = -2
		arazi_katmani.add_child(leke)

func _gorsel_lekeler_ekle() -> void:
	for i in range(gorsel_lekeler.size()):
		var leke = gorsel_lekeler[i]
		var tip = str(leke.get("tip", ""))
		var rect = Rect2(
			Vector2(float(leke.get("x", 0.0)), float(leke.get("y", 0.0))),
			Vector2(float(leke.get("w", 120.0)), float(leke.get("h", 100.0)))
		)
		var alan = ColorRect.new()
		alan.position = rect.position
		alan.size = rect.size
		alan.color = _gorsel_leke_renk(tip)
		alan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alan.z_index = -2
		arazi_katmani.add_child(alan)
		if tip == "orman_kenar":
			var kenar = ColorRect.new()
			kenar.position = rect.position + Vector2(rect.size.x * 0.55, 6)
			kenar.size = Vector2(rect.size.x * 0.4, rect.size.y - 12)
			kenar.color = Color(0.06, 0.18, 0.09, 0.35)
			kenar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			kenar.z_index = -2
			arazi_katmani.add_child(kenar)

func _gorsel_leke_renk(tip: String) -> Color:
	match tip:
		"vadi_leke":
			return Color(0.26, 0.4, 0.22, 0.38)
		"ova":
			return Color(0.34, 0.4, 0.26, 0.42)
		"orman_kenar":
			return Color(0.12, 0.3, 0.14, 0.4)
		"pusuluk":
			return Color(0.07, 0.2, 0.1, 0.48)
	return Color(0.22, 0.28, 0.18, 0.3)

func _arazi_bolge_ciz(bolge: Dictionary, rect: Rect2, tip: String, bolge_idx: int) -> void:
	var alan = ColorRect.new()
	alan.position = rect.position
	alan.size = rect.size
	alan.color = _arazi_renk(tip)
	alan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alan.z_index = -1
	arazi_katmani.add_child(alan)
	match tip:
		"tepe":
			_tepe_gorsel_ekle(rect)
		"orman":
			_orman_gorsel_ekle(rect, bolge_idx)
		"vadi":
			_vadi_gorsel_ekle(rect)
		"dar_gecit", "kopru":
			_gecit_gorsel_ekle(rect, tip)
		"yol":
			pass

func _tepe_gorsel_ekle(rect: Rect2) -> void:
	var isik = ColorRect.new()
	isik.position = rect.position + Vector2(rect.size.x * 0.06, rect.size.y * 0.05)
	isik.size = Vector2(rect.size.x * 0.52, rect.size.y * 0.42)
	isik.color = Color(0.56, 0.42, 0.26, 0.28)
	isik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isik.z_index = -1
	arazi_katmani.add_child(isik)
	var golge = ColorRect.new()
	golge.position = rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.52)
	golge.size = Vector2(rect.size.x * 0.78, rect.size.y * 0.42)
	golge.color = Color(0.1, 0.08, 0.05, 0.38)
	golge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	golge.z_index = -1
	arazi_katmani.add_child(golge)

func _orman_gorsel_ekle(rect: Rect2, bolge_idx: int) -> void:
	var kenar = ColorRect.new()
	kenar.position = rect.position + Vector2(6, 6)
	kenar.size = rect.size - Vector2(12, 12)
	kenar.color = Color(0.07, 0.22, 0.1, 0.35)
	kenar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kenar.z_index = -1
	arazi_katmani.add_child(kenar)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + str(bolge_idx) + str(int(rect.position.x)))
	var adet = clampi(int(rect.size.x * rect.size.y / 16000.0), 8, 20)
	for i in range(adet):
		var px = rect.position.x + rng.randf_range(14.0, max(16.0, rect.size.x - 14.0))
		var py = rect.position.y + rng.randf_range(14.0, max(16.0, rect.size.y - 14.0))
		var agac_golge = ColorRect.new()
		agac_golge.size = Vector2(12, 9)
		agac_golge.position = Vector2(px - 4.0, py - 6.0)
		agac_golge.color = Color(0.05, 0.18, 0.08, 0.75)
		agac_golge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		agac_golge.z_index = -1
		arazi_katmani.add_child(agac_golge)
		var govde = ColorRect.new()
		govde.size = Vector2(3, 6)
		govde.position = Vector2(px, py)
		govde.color = Color(0.2, 0.14, 0.09, 0.9)
		govde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		govde.z_index = -1
		arazi_katmani.add_child(govde)

func _vadi_gorsel_ekle(rect: Rect2) -> void:
	var cukur = ColorRect.new()
	cukur.position = rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.22)
	cukur.size = Vector2(rect.size.x * 0.6, rect.size.y * 0.56)
	cukur.color = Color(0.32, 0.48, 0.24, 0.32)
	cukur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cukur.z_index = -1
	arazi_katmani.add_child(cukur)

func _gecit_gorsel_ekle(rect: Rect2, tip: String) -> void:
	var cizgi = ColorRect.new()
	if rect.size.x > rect.size.y:
		cizgi.position = rect.position + Vector2(0, rect.size.y * 0.38)
		cizgi.size = Vector2(rect.size.x, max(8.0, rect.size.y * 0.24))
	else:
		cizgi.position = rect.position + Vector2(rect.size.x * 0.38, 0)
		cizgi.size = Vector2(max(8.0, rect.size.x * 0.24), rect.size.y)
	var renk = Color(0.36, 0.36, 0.38, 0.55) if tip == "dar_gecit" else Color(0.38, 0.4, 0.44, 0.5)
	cizgi.color = renk
	cizgi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cizgi.z_index = -1
	arazi_katmani.add_child(cizgi)

func _gorsel_yollar_ekle() -> void:
	var yollar = gorsel_yollar if not gorsel_yollar.is_empty() else _VARSAYILAN_YOLLAR
	for baglanti in yollar:
		if typeof(baglanti) != TYPE_DICTIONARY:
			continue
		var a_id = str(baglanti.get("from", ""))
		var b_id = str(baglanti.get("to", ""))
		if a_id == "" or b_id == "":
			continue
		if not nokta_konumlari.has(a_id) or not nokta_konumlari.has(b_id):
			continue
		var tip = str(baglanti.get("tip", "normal"))
		var bas = get_point_center(a_id)
		var bit = get_point_center(b_id)
		_yol_cizgisi_ekle(bas, bit, tip, hash(a_id + b_id + aktif_harita_id + tip))

func _gorsel_patikalar_ekle() -> void:
	for i in range(gorsel_patikalar.size()):
		var patika = gorsel_patikalar[i]
		var tip = str(patika.get("tip", "normal"))
		var pts = patika.get("points", []) as Array
		if pts.size() < 2:
			continue
		var packed = PackedVector2Array()
		for j in range(pts.size()):
			packed.append(pts[j] as Vector2)
		var genis = _patika_noktalari_genislet(packed, hash("patika" + aktif_harita_id + str(i)), float(_yol_stili(tip).get("wobble", 22.0)))
		_yol_cizgisi_noktalari_ekle(genis, tip)

func _dere_yataklari_ekle() -> void:
	for i in range(dere_yataklari.size()):
		var dere = dere_yataklari[i]
		var pts = dere.get("points", []) as Array
		if pts.size() < 2:
			continue
		var packed = PackedVector2Array()
		for pt in pts:
			packed.append(pt as Vector2)
		var kenar = Line2D.new()
		kenar.points = packed
		kenar.width = 10.0
		kenar.default_color = Color(0.22, 0.2, 0.16, 0.35)
		kenar.antialiased = true
		kenar.z_index = -2
		decor_katmani.add_child(kenar)
		var yatak = Line2D.new()
		yatak.points = packed
		yatak.width = 5.0
		yatak.default_color = Color(0.34, 0.3, 0.24, 0.45)
		yatak.antialiased = true
		yatak.z_index = -1
		decor_katmani.add_child(yatak)

func _patika_noktalari_genislet(points: PackedVector2Array, seed_val: int, wobble: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var out = PackedVector2Array()
	out.append(points[0])
	for i in range(points.size() - 1):
		var segment = _organik_yol_noktalari(points[i], points[i + 1], seed_val + i, wobble)
		for j in range(1, segment.size()):
			out.append(segment[j])
	return out

func _yol_cizgisi_ekle(baslangic: Vector2, bitis: Vector2, tip: String, seed_val: int) -> void:
	var stil = _yol_stili(tip)
	var noktalar = _organik_yol_noktalari(baslangic, bitis, seed_val, float(stil.get("wobble", 22.0)))
	_yol_cizgisi_noktalari_ekle(noktalar, tip)

func _yol_cizgisi_noktalari_ekle(noktalar: PackedVector2Array, tip: String) -> void:
	var stil = _yol_stili(tip)
	var kenar = Line2D.new()
	kenar.points = noktalar
	kenar.width = float(stil.get("kenar", 24.0))
	kenar.default_color = stil.get("kenar_c", Color(0.28, 0.22, 0.14, 0.55))
	kenar.antialiased = true
	kenar.z_index = -2
	decor_katmani.add_child(kenar)
	var yol = Line2D.new()
	yol.points = noktalar
	yol.width = float(stil.get("yol", 16.0))
	yol.default_color = stil.get("yol_c", Color(0.5, 0.42, 0.28, 0.82))
	yol.antialiased = true
	yol.z_index = -1
	decor_katmani.add_child(yol)
	var orta = Line2D.new()
	orta.points = noktalar
	orta.width = float(stil.get("orta", 5.0))
	orta.default_color = stil.get("orta_c", Color(0.62, 0.54, 0.36, 0.45))
	orta.antialiased = true
	orta.z_index = 0
	decor_katmani.add_child(orta)

func _yol_stili(tip: String) -> Dictionary:
	if tip == "ana":
		return {
			"kenar": 36.0, "yol": 26.0, "orta": 8.0, "wobble": 18.0,
			"kenar_c": Color(0.24, 0.19, 0.12, 0.58),
			"yol_c": Color(0.54, 0.46, 0.3, 0.88),
			"orta_c": Color(0.66, 0.58, 0.38, 0.5),
		}
	if tip == "gizli":
		return {
			"kenar": 14.0, "yol": 8.0, "orta": 2.0, "wobble": 34.0,
			"kenar_c": Color(0.12, 0.16, 0.1, 0.5),
			"yol_c": Color(0.28, 0.32, 0.22, 0.62),
			"orta_c": Color(0.36, 0.4, 0.28, 0.35),
		}
	return {
		"kenar": 24.0, "yol": 16.0, "orta": 5.0, "wobble": 24.0,
		"kenar_c": Color(0.26, 0.21, 0.14, 0.52),
		"yol_c": Color(0.46, 0.4, 0.28, 0.78),
		"orta_c": Color(0.56, 0.48, 0.34, 0.42),
	}

func _organik_yol_noktalari(baslangic: Vector2, bitis: Vector2, seed_val: int, wobble: float = 22.0) -> PackedVector2Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var adim = clampi(int(baslangic.distance_to(bitis) / 140.0), 6, 16)
	var pts = PackedVector2Array()
	pts.append(baslangic)
	var yon = bitis - baslangic
	var perp = Vector2(-yon.y, yon.x).normalized()
	for i in range(1, adim):
		var t = float(i) / float(adim)
		var p = baslangic.lerp(bitis, t)
		var dalga = sin(t * PI * 2.4 + float(seed_val % 7)) * wobble
		dalga += rng.randf_range(-wobble * 0.65, wobble * 0.65)
		p += perp * dalga
		pts.append(p)
	pts.append(bitis)
	return pts

func _akarsu_ekle() -> void:
	for bolge in arazi_bolgeleri:
		if str(bolge.get("tip", "")) != "vadi":
			continue
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.size.x <= 0:
			continue
		var pts = PackedVector2Array()
		var bas_x = rect.position.x + rect.size.x * 0.15
		var bit_x = rect.position.x + rect.size.x * 0.82
		var mid_y = rect.position.y + rect.size.y * 0.5
		pts.append(Vector2(bas_x, mid_y - rect.size.y * 0.18))
		pts.append(Vector2(bas_x + rect.size.x * 0.22, mid_y + rect.size.y * 0.08))
		pts.append(Vector2(bas_x + rect.size.x * 0.48, mid_y - rect.size.y * 0.06))
		pts.append(Vector2(bas_x + rect.size.x * 0.68, mid_y + rect.size.y * 0.12))
		pts.append(Vector2(bit_x, mid_y - rect.size.y * 0.04))
		var kenar = Line2D.new()
		kenar.points = pts
		kenar.width = 14.0
		kenar.default_color = Color(0.14, 0.22, 0.3, 0.45)
		kenar.antialiased = true
		decor_katmani.add_child(kenar)
		var su = Line2D.new()
		su.points = pts
		su.width = 8.0
		su.default_color = Color(0.22, 0.34, 0.42, 0.65)
		su.antialiased = true
		decor_katmani.add_child(su)
		return

func _cevre_dekor_ekle() -> void:
	for i in range(cevre_dekor.size()):
		var dekor = cevre_dekor[i]
		var tip = str(dekor.get("tip", ""))
		var rect = Rect2(
			Vector2(float(dekor.get("x", 0.0)), float(dekor.get("y", 0.0))),
			Vector2(float(dekor.get("w", 48.0)), float(dekor.get("h", 40.0)))
		)
		match tip:
			"kaya":
				_dekor_kaya(rect, i)
			"calik":
				_dekor_calik(rect, i)
			"harabe":
				_dekor_harabe(rect)
			"kamp":
				_dekor_kamp(rect)
			"tarla":
				_dekor_tarla(rect)
			"sirt":
				_dekor_sirt(rect)
			"agac_kume":
				_dekor_agac_kume(rect, int(dekor.get("adet", 5)), i)
			"kopru_dekor":
				_dekor_kopru(rect)

func _dekor_kaya(rect: Rect2, seed_i: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + "kaya" + str(seed_i))
	for j in range(4):
		var tas = ColorRect.new()
		var s = Vector2(rng.randf_range(16.0, 34.0), rng.randf_range(12.0, 24.0))
		tas.size = s
		tas.position = rect.position + Vector2(rng.randf_range(0.0, max(4.0, rect.size.x - s.x)), rng.randf_range(0.0, max(4.0, rect.size.y - s.y)))
		tas.color = Color(0.38, 0.35, 0.32, 0.72)
		tas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(tas)

func _dekor_calik(rect: Rect2, seed_i: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + "calik" + str(seed_i))
	for j in range(5):
		var cali = ColorRect.new()
		cali.size = Vector2(10, 8)
		cali.position = rect.position + Vector2(rng.randf_range(0.0, rect.size.x - 10.0), rng.randf_range(0.0, rect.size.y - 8.0))
		cali.color = Color(0.14, 0.26, 0.12, 0.7)
		cali.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(cali)

func _dekor_harabe(rect: Rect2) -> void:
	var duvar = ColorRect.new()
	duvar.position = rect.position
	duvar.size = Vector2(rect.size.x * 0.7, rect.size.y * 0.55)
	duvar.color = Color(0.42, 0.4, 0.38, 0.65)
	duvar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(duvar)
	var kiris = ColorRect.new()
	kiris.position = rect.position + Vector2(rect.size.x * 0.45, rect.size.y * 0.2)
	kiris.size = Vector2(rect.size.x * 0.35, 8)
	kiris.color = Color(0.36, 0.34, 0.32, 0.6)
	kiris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(kiris)

func _dekor_kamp(rect: Rect2) -> void:
	for i in range(2):
		var cadir = ColorRect.new()
		cadir.size = Vector2(22, 16)
		cadir.position = rect.position + Vector2(float(i) * 28.0 + 8.0, rect.size.y * 0.35)
		cadir.color = Color(0.52, 0.44, 0.3, 0.7)
		cadir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(cadir)
	var ates = ColorRect.new()
	ates.size = Vector2(8, 8)
	ates.position = rect.position + Vector2(rect.size.x * 0.55, rect.size.y * 0.55)
	ates.color = Color(0.7, 0.42, 0.18, 0.55)
	ates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ates)

func _dekor_tarla(rect: Rect2) -> void:
	var taban = ColorRect.new()
	taban.position = rect.position
	taban.size = rect.size
	taban.color = Color(0.48, 0.42, 0.28, 0.45)
	taban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(taban)
	var satir_say = clampi(int(rect.size.y / 14.0), 3, 8)
	for i in range(satir_say):
		var satir = ColorRect.new()
		satir.position = rect.position + Vector2(4, float(i) * 14.0 + 4)
		satir.size = Vector2(rect.size.x - 8, 4)
		satir.color = Color(0.4, 0.36, 0.24, 0.35)
		satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(satir)

func _dekor_sirt(rect: Rect2) -> void:
	var isik = ColorRect.new()
	isik.position = rect.position + Vector2(6, 4)
	isik.size = Vector2(rect.size.x * 0.55, rect.size.y * 0.45)
	isik.color = Color(0.34, 0.38, 0.26, 0.35)
	isik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(isik)
	var golge = ColorRect.new()
	golge.position = rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.48)
	golge.size = Vector2(rect.size.x * 0.72, rect.size.y * 0.42)
	golge.color = Color(0.12, 0.14, 0.1, 0.32)
	golge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(golge)

func _dekor_agac_kume(rect: Rect2, adet: int, seed_i: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + "ak" + str(seed_i))
	for j in range(clampi(adet, 3, 10)):
		var px = rect.position.x + rng.randf_range(0.0, max(8.0, rect.size.x - 10.0))
		var py = rect.position.y + rng.randf_range(0.0, max(8.0, rect.size.y - 10.0))
		var canopy = ColorRect.new()
		canopy.size = Vector2(11, 8)
		canopy.position = Vector2(px, py - 5)
		canopy.color = Color(0.07, 0.24, 0.11, 0.8)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(canopy)
		var trunk = ColorRect.new()
		trunk.size = Vector2(3, 6)
		trunk.position = Vector2(px + 4, py)
		trunk.color = Color(0.2, 0.14, 0.09, 0.9)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(trunk)

func _dekor_kopru(rect: Rect2) -> void:
	var ayak1 = ColorRect.new()
	ayak1.position = rect.position
	ayak1.size = Vector2(10, rect.size.y)
	ayak1.color = Color(0.36, 0.34, 0.32, 0.75)
	ayak1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ayak1)
	var ayak2 = ColorRect.new()
	ayak2.position = rect.position + Vector2(rect.size.x - 10.0, 0)
	ayak2.size = Vector2(10, rect.size.y)
	ayak2.color = Color(0.36, 0.34, 0.32, 0.75)
	ayak2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ayak2)
	var tabla = ColorRect.new()
	tabla.position = rect.position + Vector2(0, rect.size.y * 0.35)
	tabla.size = Vector2(rect.size.x, max(8.0, rect.size.y * 0.22))
	tabla.color = Color(0.44, 0.38, 0.3, 0.8)
	tabla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(tabla)

func _bolge_etiketleri_ekle() -> void:
	for etiket in bolge_etiketleri:
		var metin = str(etiket.get("metin", ""))
		if metin == "":
			continue
		var golge = Label.new()
		golge.text = metin
		golge.position = Vector2(float(etiket.get("x", 0.0)) + 1.0, float(etiket.get("y", 0.0)) + 1.0)
		golge.add_theme_font_size_override("font_size", 11)
		golge.add_theme_color_override("font_color", Color(0.05, 0.06, 0.05, 0.55))
		golge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(golge)
		var label = Label.new()
		label.text = metin
		label.position = Vector2(float(etiket.get("x", 0.0)), float(etiket.get("y", 0.0)))
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.7, 0.72))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(label)

func _arazi_renk(tip: String) -> Color:
	if tip == "tepe":
		return Color(0.44, 0.31, 0.19, 0.78)
	if tip == "orman":
		return Color(0.09, 0.28, 0.12, 0.82)
	if tip == "dar_gecit":
		return Color(0.24, 0.24, 0.26, 0.78)
	if tip == "vadi":
		return Color(0.3, 0.46, 0.22, 0.72)
	if tip == "yol":
		return Color(0.48, 0.4, 0.26, 0.38)
	if tip == "kopru":
		return Color(0.36, 0.36, 0.4, 0.8)
	return Color(0, 0, 0, 0)
