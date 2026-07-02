extends RefCounted
class_name WorldSystem

const GameData = preload("res://scripts/systems/game_data.gd")
const MapLayoutSystem = preload("res://scripts/systems/map_layout_system.gd")
const IsoProj = preload("res://scripts/iso_projection.gd")
const PathSpline = preload("res://scripts/path_spline.gd")
const _YOL_SPLINE_ADIM := 10

const _ISO_ARAZI_CIZIMI := true
const _ZEMIN_DOKU := "3d"  # "3d" | "cim" | "zengin" | "pixel"
const _PIXEL_CIMEN_ZEMIN := false
const _ESKI_SPRITE_ZEMIN := false
const _GIZLE_ARAZI_BOLGE_GORSEL := true
const _CIMEN_GRID_K := 64.0
const _CIMEN_GERCEK_YOL := "res://assets/zemin/cimen_gercek.jpg"
const _CIMEN_ZENGIN_YOLLARI := [
	"res://assets/zemin/cimen_zengin.png",
	"res://assets/zemin/cimen_zemin.png",
]
const _CIMEN_PIXEL_TILESET_YOL := "res://assets/zemin/cimen_tileset.tres"
const _CIMEN_KARO_TEX_PX := 64
const _CIM_DOKU_OLCEK := 0.5  # 1.0 = mevcut; kucuk = daha sik tekrar = daha kucuk cim
const _CIMEN_DIS_PAY := 640.0  # harita sinirinin disina cim (bos kose alanlari)
const _ZEMIN3D_COZUNURLUK := 0.5  # viewport render olcegi (1.0 = tam, dusuk = az VRAM)
const _ZEMIN3D_DOKU_TEKRAR := 256.0  # kac logical birimde bir doku tekrari
const _ZEMIN3D_DIS_PAY := 640.0  # 3d zeminde harita disi pay (viewport boyutunu sinirlar)
const _KAMERA_LIMIT_PAY := 1600.0  # zoom-out'ta kenarlarin gorunmesi icin limit payi
const _CIMEN_KARO_YOLLARI := [
	"res://assets/zemin/cimen_duz.png",
	"res://assets/placeholder_cimen_iso.png",
]
const _YOL_KALINLIK_OLCEK := 0.45  # kenar/yol/orta genisligi carpani

var _root: Node2D = null
var _on_map_applied: Callable
var _on_map_visuals_extra: Callable

var aktif_harita_id = "trakya"
var harita_sinir = {"min_x": 20.0, "max_x": 980.0, "min_y": 80.0, "max_y": 440.0}
var nokta_konumlari = {}
var kavsak_konumlari = {}
var nokta_puan = {}
var nokta_altin = {}
var arazi_bolgeleri: Array = []
var orman_bolgeleri: Array = []
var bolge_etiketleri: Array = []
var gorsel_yollar: Array = []
var gorsel_patikalar: Array = []
var gorsel_lekeler: Array = []
var dere_yataklari: Array = []
var nehir_hatlari: Array = []
var cevre_dekor: Array = []
var nokta_duzen: Dictionary = {}
var nokta_slotlari: Dictionary = {}
var us_idleri: Array = []
var us_taraf: Dictionary = {}
var _map_layout_kaynak: Dictionary = {}
var _sabit_nokta_konumlari: Dictionary = {}
var _sabit_nokta_puan: Dictionary = {}
var _sabit_nokta_altin: Dictionary = {}
var arazi_katmani: Node2D = null
var cimen_katmani: Node2D = null
var _cimen_tilemap: TileMapLayer = null
var _doku_tabanli_tileset_onbellek: Dictionary = {}
var _pixel_cimen_tileset_hazir: TileSet = null
var _zemin3d_viewport: SubViewport = null
var _zemin3d_sprite: Sprite2D = null
var decor_katmani: Node2D = null
var nesne_katmani: Node2D = null
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


func get_nesne_katmani() -> Node2D:
	nesne_katmani_olustur()
	return nesne_katmani


func find_map_node(node_name: String) -> Node:
	if _root == null:
		return null
	return _root.find_child(node_name, true, false)

func get_point_center(nokta: String) -> Vector2:
	return nokta_konumlari[nokta] + Vector2(40, 40)


func nokta_gorsel_kok_pos(nokta: String) -> Vector2:
	return _nokta_gorsel_anchor(nokta)


func birim_gorsel_konum(logical: Vector2) -> Vector2:
	if _ISO_ARAZI_CIZIMI:
		return _izo(logical) - Vector2(15.0, 15.0)
	return logical


func birim_y_sort_foot(logical: Vector2) -> Vector2:
	return birim_gorsel_konum(logical) + Vector2(15.0, 30.0)


func ekran_to_logical(ekran_pos: Vector2) -> Vector2:
	if _ISO_ARAZI_CIZIMI:
		return IsoProj.iso_to_logical(ekran_pos - _izo_cizim_offseti(harita_sinir))
	return ekran_pos


func logical_to_ekran(logical: Vector2) -> Vector2:
	return _izo(logical)


func izo_ekran_sinir(sinir: Dictionary) -> Dictionary:
	var min_x := float(sinir["min_x"])
	var max_x := float(sinir["max_x"])
	var min_y := float(sinir["min_y"])
	var max_y := float(sinir["max_y"])
	var koseler: Array[Vector2] = [
		Vector2(min_x, min_y),
		Vector2(max_x, min_y),
		Vector2(max_x, max_y),
		Vector2(min_x, max_y),
	]
	var off := _izo_cizim_offseti(sinir)
	var ilk: Vector2 = IsoProj.logical_to_iso(koseler[0]) + off
	var bx_min := ilk.x
	var bx_max := ilk.x
	var by_min := ilk.y
	var by_max := ilk.y
	for k in koseler:
		var p: Vector2 = IsoProj.logical_to_iso(k) + off
		bx_min = minf(bx_min, p.x)
		bx_max = maxf(bx_max, p.x)
		by_min = minf(by_min, p.y)
		by_max = maxf(by_max, p.y)
	return {"min_x": bx_min, "max_x": bx_max, "min_y": by_min, "max_y": by_max}


func birim_gorselini_uygula(birim: Dictionary) -> void:
	var konum: Vector2 = birim.get("konum", Vector2.ZERO)
	var kok = birim.get("kok_node")
	if is_instance_valid(kok):
		kok.position = birim_y_sort_foot(konum)
		return
	var gorsel: Vector2 = birim_gorsel_konum(konum)
	var node = birim.get("node")
	if is_instance_valid(node):
		node.position = gorsel
	var cerceve = birim.get("cerceve_node")
	if is_instance_valid(cerceve):
		cerceve.position = gorsel - Vector2(2.0, 2.0)


func _izo(logical: Vector2) -> Vector2:
	if _ISO_ARAZI_CIZIMI:
		return IsoProj.logical_to_iso(logical) + _izo_cizim_offseti(harita_sinir)
	return logical


func _izo_nokta_dizisi(points: PackedVector2Array) -> PackedVector2Array:
	if not _ISO_ARAZI_CIZIMI:
		return points
	var out := PackedVector2Array()
	for p in points:
		out.append(_izo(p))
	return out


func _nokta_gorsel_anchor(nokta: String) -> Vector2:
	if _ISO_ARAZI_CIZIMI:
		return _izo(get_point_center(nokta)) - Vector2(40.0, 40.0)
	return nokta_konumlari[nokta]


func _nokta_y_sort_foot(nokta: String) -> Vector2:
	if _ISO_ARAZI_CIZIMI:
		return _izo(get_point_center(nokta)) + Vector2(0.0, 40.0)
	return nokta_konumlari[nokta] + Vector2(40.0, 80.0)


func _decor_z(topdown_z: int) -> int:
	return topdown_z + 8 if _ISO_ARAZI_CIZIMI else topdown_z


func _nokta_gorsel_z(topdown_z: int) -> int:
	return topdown_z + 12 if _ISO_ARAZI_CIZIMI else topdown_z

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
	kavsak_konumlari = map_data.get("kavsaklar", {}).duplicate()
	nokta_puan = _sabit_nokta_puan.duplicate()
	nokta_altin = _sabit_nokta_altin.duplicate()
	harita_sinir = map_data["sinir"].duplicate()
	arazi_bolgeleri = map_data.get("arazi_bolgeleri", []).duplicate(true)
	bolge_etiketleri = map_data.get("bolge_etiketleri", []).duplicate(true)
	gorsel_yollar = map_data.get("gorsel_yollar", []).duplicate(true)
	gorsel_patikalar = map_data.get("gorsel_patikalar", []).duplicate(true)
	gorsel_lekeler = map_data.get("gorsel_lekeler", []).duplicate(true)
	dere_yataklari = map_data.get("dere_yataklari", []).duplicate(true)
	nehir_hatlari = map_data.get("nehir_hatlari", []).duplicate(true)
	cevre_dekor = map_data.get("cevre_dekor", []).duplicate(true)
	nokta_duzen = map_data.get("nokta_duzen", {}).duplicate()
	nokta_slotlari = map_data.get("nokta_slotlari", {}).duplicate()
	us_idleri = map_data.get("usler", []).duplicate()
	_map_layout_kaynak = map_data.duplicate(true)
	us_taraf_eslemesi_kur()
	orman_bolgeleri = []
	for bolge in arazi_bolgeleri:
		if str(bolge.get("tip", "")) == "orman":
			orman_bolgeleri.append(bolge)
	harita_gorsellerini_guncelle()
	kamera_limitlerini_guncelle()
	if _on_map_applied.is_valid():
		_on_map_applied.call()

func us_taraf_eslemesi_kur(ters_cevir: bool = false) -> void:
	us_taraf.clear()
	if us_idleri.is_empty():
		return
	var orta_y := (float(harita_sinir.get("min_y", 0.0)) + float(harita_sinir.get("max_y", 0.0))) * 0.5
	for uid in us_idleri:
		var us_id := str(uid)
		if not nokta_konumlari.has(us_id):
			continue
		var y := float(nokta_konumlari[us_id].y)
		var taraf := "osmanli" if y > orta_y else "dogu_roma"
		if ters_cevir:
			taraf = "dogu_roma" if taraf == "osmanli" else "osmanli"
		us_taraf[us_id] = taraf

func us_taraf_getir(taraf: String) -> String:
	for uid in us_idleri:
		var us_id := str(uid)
		if us_taraf.get(us_id, "") == taraf:
			return us_id
	return ""

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
	var s := _aktif_kamera_sinir()
	kamera.limit_left = int(s["min_x"] - _KAMERA_LIMIT_PAY)
	kamera.limit_right = int(s["max_x"] + _KAMERA_LIMIT_PAY)
	kamera.limit_top = int(s["min_y"] - _KAMERA_LIMIT_PAY)
	kamera.limit_bottom = int(s["max_y"] + _KAMERA_LIMIT_PAY)
	kamera_sinirla()

func kamera_sinirla() -> void:
	if kamera == null:
		return
	var s := _aktif_kamera_sinir()
	kamera.position.x = clamp(kamera.position.x, s["min_x"], s["max_x"])
	kamera.position.y = clamp(kamera.position.y, s["min_y"], s["max_y"])

func kamera_merkez_konum() -> Vector2:
	var s := _aktif_kamera_sinir()
	return Vector2((s["min_x"] + s["max_x"]) * 0.5, (s["min_y"] + s["max_y"]) * 0.5)

func _aktif_kamera_sinir() -> Dictionary:
	if _ISO_ARAZI_CIZIMI:
		return izo_ekran_sinir(harita_sinir)
	return harita_sinir

func arazi_katmani_olustur() -> void:
	if _root == null:
		return
	cimen_katmani_olustur()
	if not is_instance_valid(arazi_katmani):
		arazi_katmani = Node2D.new()
		arazi_katmani.name = "AraziLayer"
		arazi_katmani.position = Vector2.ZERO
		_root.add_child(arazi_katmani)
		_root.move_child(arazi_katmani, 0)
	decor_katmani_olustur()
	arazi_gorsellerini_guncelle()
	decor_gorsellerini_guncelle()

func cimen_katmani_olustur() -> void:
	if _root == null or is_instance_valid(cimen_katmani):
		return
	cimen_katmani = Node2D.new()
	cimen_katmani.name = "CimenLayer"
	cimen_katmani.position = Vector2.ZERO
	cimen_katmani.z_index = -20
	_root.add_child(cimen_katmani)
	_root.move_child(cimen_katmani, 0)

func decor_katmani_olustur() -> void:
	if _root == null or is_instance_valid(decor_katmani):
		return
	decor_katmani = Node2D.new()
	decor_katmani.name = "MapDecorLayer"
	decor_katmani.position = Vector2.ZERO
	decor_katmani.z_index = -1
	_root.add_child(decor_katmani)
	if is_instance_valid(arazi_katmani):
		var arazi_idx = arazi_katmani.get_index()
		_root.move_child(decor_katmani, arazi_idx + 1)
	nesne_katmani_olustur()

func nesne_katmani_olustur() -> void:
	if _root == null or is_instance_valid(nesne_katmani):
		return
	nesne_katmani = Node2D.new()
	nesne_katmani.name = "NesneKatmani"
	nesne_katmani.position = Vector2.ZERO
	nesne_katmani.y_sort_enabled = true
	nesne_katmani.z_index = 10
	_root.add_child(nesne_katmani)
	if is_instance_valid(decor_katmani):
		_root.move_child(nesne_katmani, decor_katmani.get_index() + 1)
	elif is_instance_valid(arazi_katmani):
		_root.move_child(nesne_katmani, arazi_katmani.get_index() + 1)

func build_control_points(capture_barlar: Dictionary) -> void:
	nesne_katmani_olustur()
	for nokta in nokta_konumlari:
		if kavsak_konumlari.has(nokta):
			continue
		var anchor = _nokta_gorsel_anchor(nokta)
		var foot = _nokta_y_sort_foot(nokta)
		var rel = anchor - foot
		var parent: Node = nesne_katmani if _ISO_ARAZI_CIZIMI else _root

		var kok: Node2D = null
		if _ISO_ARAZI_CIZIMI:
			kok = Node2D.new()
			kok.name = "NoktaKok_" + nokta
			kok.position = foot
			nesne_katmani.add_child(kok)
			parent = kok

		var zemin = ColorRect.new()
		zemin.color = Color(0.34, 0.3, 0.22, 0.5)
		zemin.size = Vector2(132, 132)
		zemin.position = rel - Vector2(26, 26)
		zemin.name = "NoktaZemin_" + nokta
		zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zemin.z_index = _nokta_gorsel_z(-3) if not _ISO_ARAZI_CIZIMI else -3
		parent.add_child(zemin)

		var tas_leke = ColorRect.new()
		tas_leke.color = Color(0.42, 0.38, 0.3, 0.35)
		tas_leke.size = Vector2(96, 96)
		tas_leke.position = rel - Vector2(8, 8)
		tas_leke.name = "NoktaTas_" + nokta
		tas_leke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tas_leke.z_index = _nokta_gorsel_z(-2) if not _ISO_ARAZI_CIZIMI else -2
		parent.add_child(tas_leke)

		var halka = ColorRect.new()
		halka.color = Color(0.5, 0.44, 0.32, 0.45)
		halka.size = Vector2(104, 104)
		halka.position = rel - Vector2(12, 12)
		halka.name = "NoktaHalka_" + nokta
		halka.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halka.z_index = _nokta_gorsel_z(-1) if not _ISO_ARAZI_CIZIMI else -1
		parent.add_child(halka)

		var cerceve = ColorRect.new()
		cerceve.color = Color(0.1, 0.1, 0.12, 0.65)
		cerceve.size = Vector2(84, 84)
		cerceve.position = rel - Vector2(2, 2)
		cerceve.name = "NoktaCerceve_" + nokta
		cerceve.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cerceve.z_index = _nokta_gorsel_z(0) if not _ISO_ARAZI_CIZIMI else 0
		parent.add_child(cerceve)

		var kare = ColorRect.new()
		kare.color = Color(0.44, 0.4, 0.34, 0.94)
		kare.size = Vector2(80, 80)
		kare.position = rel
		kare.name = "Nokta_" + nokta
		kare.z_index = _nokta_gorsel_z(1) if not _ISO_ARAZI_CIZIMI else 1
		parent.add_child(kare)

		var isim_l = Label.new()
		isim_l.name = "Label_Nokta_" + nokta
		isim_l.text = nokta
		isim_l.add_theme_font_size_override("font_size", 14)
		isim_l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		isim_l.position = rel + Vector2(30, 30)
		isim_l.z_index = _nokta_gorsel_z(2) if not _ISO_ARAZI_CIZIMI else 2
		parent.add_child(isim_l)

		var bar_bg = ColorRect.new()
		bar_bg.name = "CaptureBg_" + nokta
		bar_bg.color = Color(0.15, 0.15, 0.18, 0.9)
		bar_bg.size = Vector2(80, 8)
		bar_bg.position = rel + Vector2(0, 85)
		bar_bg.z_index = _nokta_gorsel_z(2) if not _ISO_ARAZI_CIZIMI else 2
		parent.add_child(bar_bg)

		var bar = ColorRect.new()
		bar.color = Color(0.85, 0.72, 0.2, 1.0)
		bar.size = Vector2(40, 8)
		bar.position = rel + Vector2(0, 85)
		bar.name = "CaptureBar_" + nokta
		bar.z_index = _nokta_gorsel_z(3) if not _ISO_ARAZI_CIZIMI else 3
		parent.add_child(bar)
		capture_barlar[nokta] = bar

		if not us_idleri.has(nokta):
			var puan_l = Label.new()
			puan_l.name = "Label_Puan_" + nokta
			puan_l.text = "+" + str(nokta_puan[nokta])
			puan_l.position = rel + Vector2(30, -20)
			puan_l.z_index = _nokta_gorsel_z(2) if not _ISO_ARAZI_CIZIMI else 2
			parent.add_child(puan_l)

func birimin_arazisini_bul(konum: Vector2) -> Dictionary:
	for nokta in nokta_konumlari:
		if konum.distance_to(get_point_center(nokta)) <= 85.0:
			return {"tip": "duz_arazi"}
	for bolge in arazi_bolgeleri:
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.has_point(konum):
			return bolge
	return {"tip": "duz_arazi"}

func gecis_engelli_mi(konum: Vector2) -> bool:
	for nokta in nokta_konumlari:
		if konum.distance_to(get_point_center(nokta)) <= 85.0:
			return false
	var su_var = false
	var gecis_var = false
	for bolge in arazi_bolgeleri:
		var rect: Rect2 = bolge.get("rect", Rect2())
		if not rect.has_point(konum):
			continue
		var tip = str(bolge.get("tip", ""))
		if tip == "su":
			su_var = true
		elif tip == "kopru" or tip == "dar_gecit":
			gecis_var = true
	return su_var and not gecis_var

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

func _nokta_gorsel_konumla(nokta: String, _logical_pos: Vector2) -> void:
	var anchor := _nokta_gorsel_anchor(nokta)
	var foot := _nokta_y_sort_foot(nokta)
	var rel := anchor - foot
	if _ISO_ARAZI_CIZIMI:
		var kok = find_map_node("NoktaKok_" + nokta) as Node2D
		if kok:
			kok.position = foot
	var zemin = find_map_node("NoktaZemin_" + nokta) as ColorRect
	if zemin:
		zemin.position = rel - Vector2(26, 26)
		if not _ISO_ARAZI_CIZIMI:
			zemin.z_index = _nokta_gorsel_z(-3)
	var tas = find_map_node("NoktaTas_" + nokta) as ColorRect
	if tas:
		tas.position = rel - Vector2(8, 8)
		if not _ISO_ARAZI_CIZIMI:
			tas.z_index = _nokta_gorsel_z(-2)
	var halka = find_map_node("NoktaHalka_" + nokta) as ColorRect
	if halka:
		halka.position = rel - Vector2(12, 12)
		if not _ISO_ARAZI_CIZIMI:
			halka.z_index = _nokta_gorsel_z(-1)
	var cerceve = find_map_node("NoktaCerceve_" + nokta) as ColorRect
	if cerceve:
		cerceve.position = rel - Vector2(2, 2)
		if not _ISO_ARAZI_CIZIMI:
			cerceve.z_index = _nokta_gorsel_z(0)
	var kare = find_map_node("Nokta_" + nokta) as ColorRect
	if kare:
		kare.position = rel
		if not _ISO_ARAZI_CIZIMI:
			kare.z_index = _nokta_gorsel_z(1)
	var isim = find_map_node("Label_Nokta_" + nokta) as Label
	if isim:
		isim.position = rel + Vector2(30, 30)
		if not _ISO_ARAZI_CIZIMI:
			isim.z_index = _nokta_gorsel_z(2)
	var puan = find_map_node("Label_Puan_" + nokta) as Label
	if puan and not us_idleri.has(nokta):
		puan.position = rel + Vector2(30, -20)
		puan.text = "+" + str(nokta_puan.get(nokta, 1))
		if not _ISO_ARAZI_CIZIMI:
			puan.z_index = _nokta_gorsel_z(2)
	var bar_bg = find_map_node("CaptureBg_" + nokta) as ColorRect
	if bar_bg:
		bar_bg.position = rel + Vector2(0, 85)
		if not _ISO_ARAZI_CIZIMI:
			bar_bg.z_index = _nokta_gorsel_z(2)
	var bar = find_map_node("CaptureBar_" + nokta) as ColorRect
	if bar:
		bar.position = rel + Vector2(0, 85)
		if not _ISO_ARAZI_CIZIMI:
			bar.z_index = _nokta_gorsel_z(3)

func arazi_gorsellerini_guncelle() -> void:
	if not is_instance_valid(arazi_katmani):
		return
	for c in arazi_katmani.get_children():
		c.queue_free()
	var sinir = harita_sinir
	var iso_offset := _izo_cizim_offseti(sinir)
	# --- ESKI TOP-DOWN CIZIM (izometrige gecis - kapatildi) ---
	if not _ISO_ARAZI_CIZIMI:
		_taban_katmani_ekle(sinir)
		_arazi_leke_katmani_ekle(sinir)
		_gorsel_lekeler_ekle()
	# --- YENI IZOMETRIK CIZIM (aktif) ---
	if _ISO_ARAZI_CIZIMI:
		if _ZEMIN_DOKU == "3d":
			_zemin3d_ekle(sinir)
		else:
			_cimen_zemin_ekle(sinir)
	elif _PIXEL_CIMEN_ZEMIN:
		_cimen_zemin_ekle(sinir)
	if is_instance_valid(cimen_katmani) and not _ISO_ARAZI_CIZIMI and not _PIXEL_CIMEN_ZEMIN:
		for c in cimen_katmani.get_children():
			c.queue_free()
	for i in range(arazi_bolgeleri.size()):
		var bolge = arazi_bolgeleri[i]
		var rect: Rect2 = bolge.get("rect", Rect2())
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var tip = str(bolge.get("tip", "duz_arazi"))
		if not _ISO_ARAZI_CIZIMI:
			_arazi_bolge_ciz(bolge, rect, tip, i)
		if _ISO_ARAZI_CIZIMI and not _GIZLE_ARAZI_BOLGE_GORSEL:
			_arazi_bolgesini_izo_ciz(bolge, rect, tip, i, iso_offset)

func decor_gorsellerini_guncelle() -> void:
	if not is_instance_valid(decor_katmani):
		return
	for c in decor_katmani.get_children():
		c.queue_free()
	_gorsel_yollar_ekle()
	_gorsel_patikalar_ekle()
	_nehir_hatlari_ekle()
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


func _cimen_karo_yukle() -> Texture2D:
	for yol in _CIMEN_KARO_YOLLARI:
		if ResourceLoader.exists(yol):
			var tex := load(yol) as Texture2D
			if tex:
				return tex
	return null


func _zemin_doku_pixel_mi() -> bool:
	return _ZEMIN_DOKU == "pixel"


func _aktif_doku_yolu() -> String:
	match _ZEMIN_DOKU:
		"cim":
			return _CIMEN_GERCEK_YOL
		"zengin":
			return _zengin_doku_yolu_bul()
		"pixel", "3d":
			return ""
		_:
			push_warning("WorldSystem: bilinmeyen _ZEMIN_DOKU='%s', cim kullaniliyor." % _ZEMIN_DOKU)
			return _CIMEN_GERCEK_YOL


func _zengin_doku_yolu_bul() -> String:
	for yol in _CIMEN_ZENGIN_YOLLARI:
		if ResourceLoader.exists(yol):
			return yol
	push_warning("WorldSystem: zengin zemin dokusu yok (cimen_zengin.png / cimen_zemin.png).")
	return _CIMEN_ZENGIN_YOLLARI[0]


func _cimen_tilemap_olustur() -> void:
	if not is_instance_valid(cimen_katmani):
		return
	if is_instance_valid(_cimen_tilemap):
		return
	_cimen_tilemap = TileMapLayer.new()
	_cimen_tilemap.name = "CimenTileMap"
	var tileset := _cimen_tileset_al()
	if tileset == null:
		_cimen_tilemap.queue_free()
		_cimen_tilemap = null
		push_warning("WorldSystem: cimen tileset yuklenemedi, izo taban kullaniliyor.")
		return
	_cimen_tilemap.tile_set = tileset
	_cimen_tilemap.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST if _zemin_doku_pixel_mi()
		else CanvasItem.TEXTURE_FILTER_LINEAR
	)
	_cimen_tilemap.z_index = 0
	_cimen_tilemap.position = Vector2.ZERO
	cimen_katmani.add_child(_cimen_tilemap)


func _cimen_tileset_al() -> TileSet:
	if _zemin_doku_pixel_mi():
		return _pixel_cimen_tileset_al()
	return _doku_tabanli_tileset_al(_aktif_doku_yolu())


func _doku_tabanli_tileset_al(yol: String) -> TileSet:
	if yol == "":
		return null
	if _doku_tabanli_tileset_onbellek.has(yol):
		return _doku_tabanli_tileset_onbellek[yol]
	if not ResourceLoader.exists(yol):
		push_warning("WorldSystem: zemin dokusu bulunamadi: " + yol)
		return null
	var tex := load(yol) as Texture2D
	if tex == null:
		push_warning("WorldSystem: zemin dokusu yuklenemedi: " + yol)
		return null
	var region_px := _gercekci_cimen_region_boyutu(tex)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = region_px
	atlas.create_tile(Vector2i(0, 0))
	_cimen_atlas_flip_alternatifleri(atlas, Vector2i(0, 0))
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED
	tileset.tile_size = Vector2i(64, 32)
	tileset.add_source(atlas, 0)
	_doku_tabanli_tileset_onbellek[yol] = tileset
	return tileset


func _gercekci_cimen_region_boyutu(tex: Texture2D) -> Vector2i:
	var olcek := maxf(_CIM_DOKU_OLCEK, 0.05)
	var px := maxi(8, int(float(_CIMEN_KARO_TEX_PX) / olcek))
	var tex_max := int(minf(tex.get_width(), tex.get_height()))
	px = mini(px, tex_max)
	return Vector2i(px, px)


func _pixel_cimen_tileset_al() -> TileSet:
	if _pixel_cimen_tileset_hazir != null:
		return _pixel_cimen_tileset_hazir
	if not ResourceLoader.exists(_CIMEN_PIXEL_TILESET_YOL):
		push_warning("WorldSystem: pixel cimen tileset bulunamadi: " + _CIMEN_PIXEL_TILESET_YOL)
		return null
	var ham := load(_CIMEN_PIXEL_TILESET_YOL) as TileSet
	if ham == null:
		return null
	var tileset := ham.duplicate(true) as TileSet
	for i in range(tileset.get_source_count()):
		var src_id := tileset.get_source_id(i)
		var atlas := tileset.get_source(src_id) as TileSetAtlasSource
		if atlas != null:
			_cimen_atlas_flip_alternatifleri(atlas, Vector2i(0, 0))
	_pixel_cimen_tileset_hazir = tileset
	return tileset


func _cimen_atlas_flip_alternatifleri(atlas: TileSetAtlasSource, coords: Vector2i) -> void:
	if not atlas.has_tile(coords):
		atlas.create_tile(coords)
	for alt in range(4):
		if alt > 0 and not atlas.has_alternative_tile(coords, alt):
			atlas.create_alternative_tile(coords, alt)
		var td := atlas.get_tile_data(coords, alt)
		if td != null:
			td.flip_h = (alt & 1) != 0
			td.flip_v = (alt & 2) != 0


func _cimen_doseme_sinirleri_genislet(sinir: Dictionary) -> Dictionary:
	var min_x := float(sinir["min_x"])
	var max_x := float(sinir["max_x"])
	var min_y := float(sinir["min_y"])
	var max_y := float(sinir["max_y"])
	var w := max_x - min_x
	var h := max_y - min_y
	var pay := maxf(_CIMEN_DIS_PAY, maxf(w, h) * 0.5)
	return {
		"min_x": min_x - pay,
		"max_x": max_x + pay,
		"min_y": min_y - pay,
		"max_y": max_y + pay,
	}


func _cimen_hucre_araligi(doseme: Dictionary, off: Vector2) -> Dictionary:
	var koseler: Array[Vector2] = [
		Vector2(doseme["min_x"], doseme["min_y"]),
		Vector2(doseme["max_x"], doseme["min_y"]),
		Vector2(doseme["max_x"], doseme["max_y"]),
		Vector2(doseme["min_x"], doseme["max_y"]),
	]
	var hucre_min := Vector2i(2147483647, 2147483647)
	var hucre_max := Vector2i(-2147483648, -2147483648)
	for k in koseler:
		var hucre := _cimen_tilemap.local_to_map(IsoProj.logical_to_iso(k) + off)
		hucre_min.x = mini(hucre_min.x, hucre.x)
		hucre_min.y = mini(hucre_min.y, hucre.y)
		hucre_max.x = maxi(hucre_max.x, hucre.x)
		hucre_max.y = maxi(hucre_max.y, hucre.y)
	return {"min": hucre_min, "max": hucre_max}


func _cimen_zemin_ekle(sinir: Dictionary) -> void:
	cimen_katmani_olustur()
	if not is_instance_valid(cimen_katmani):
		return
	for c in cimen_katmani.get_children():
		c.queue_free()
	_cimen_tilemap = null
	_cimen_tilemap_olustur()
	if not is_instance_valid(_cimen_tilemap):
		_izo_taban_ekle(sinir)
		return
	var off := _izo_cizim_offseti(sinir)
	var doseme := _cimen_doseme_sinirleri_genislet(sinir)
	var min_x := float(doseme["min_x"])
	var max_x := float(doseme["max_x"])
	var min_y := float(doseme["min_y"])
	var max_y := float(doseme["max_y"])
	var k := _CIMEN_GRID_K
	var hedef0 := IsoProj.logical_to_iso(Vector2(float(sinir["min_x"]), float(sinir["min_y"]))) + off
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + "cimen_flip")
	var pixel := _zemin_doku_pixel_mi()
	var kaynak_sayisi := 1 if not pixel else mini(3, _cimen_tilemap.tile_set.get_source_count())
	_cimen_tilemap.clear()
	_cimen_tilemap.position = Vector2.ZERO
	var aralik := _cimen_hucre_araligi(doseme, off)
	var hucre_min: Vector2i = aralik["min"]
	var hucre_max: Vector2i = aralik["max"]
	for cx in range(hucre_min.x, hucre_max.x + 1):
		for cy in range(hucre_min.y, hucre_max.y + 1):
			var hucre := Vector2i(cx, cy)
			var kaynak := rng.randi_range(0, kaynak_sayisi - 1) if kaynak_sayisi > 1 else 0
			var alt := rng.randi_range(0, 3)
			_cimen_tilemap.set_cell(hucre, kaynak, Vector2i(0, 0), alt)
	var hedef_hucre := _cimen_tilemap.local_to_map(hedef0 - _cimen_tilemap.position)
	var simdiki0 := _cimen_tilemap.map_to_local(hedef_hucre)
	var parent_pos := Vector2.ZERO
	if is_instance_valid(_cimen_tilemap.get_parent()) and _cimen_tilemap.get_parent() is CanvasItem:
		parent_pos = (_cimen_tilemap.get_parent() as CanvasItem).position
	print("[TILE-HIZA] hedef0=", hedef0, " map_to_local(hedef_hucre)=", simdiki0, " hedef_hucre=", hedef_hucre, " tilemap.position=", _cimen_tilemap.position, " parent.position=", parent_pos)
	if _ESKI_SPRITE_ZEMIN and pixel:
		var cimen_tex := _cimen_karo_yukle()
		if cimen_tex == null:
			push_warning("WorldSystem: cimen karo bulunamadi, izo taban kullaniliyor.")
			_izo_taban_ekle(sinir)
			return
		var x := min_x
		var ilk_sprite: Sprite2D = null
		while x <= max_x:
			var y := min_y
			while y <= max_y:
				var s := Sprite2D.new()
				s.texture = cimen_tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.centered = true
				s.position = IsoProj.logical_to_iso(Vector2(x, y)) + off
				s.z_index = 0
				cimen_katmani.add_child(s)
				if ilk_sprite == null:
					ilk_sprite = s
				y += k
			x += k
		if is_instance_valid(ilk_sprite):
			print("[TILE-HIZA] eski_ilk_sprite=", ilk_sprite.global_position)


func _zemin3d_ekle(sinir: Dictionary) -> void:
	cimen_katmani_olustur()
	if not is_instance_valid(cimen_katmani):
		return
	for c in cimen_katmani.get_children():
		c.queue_free()
	_cimen_tilemap = null
	_zemin3d_viewport = null
	_zemin3d_sprite = null

	var min_x := float(sinir["min_x"])
	var max_x := float(sinir["max_x"])
	var min_y := float(sinir["min_y"])
	var max_y := float(sinir["max_y"])
	var pay := _ZEMIN3D_DIS_PAY
	var gw := (max_x - min_x) + pay * 2.0
	var gh := (max_y - min_y) + pay * 2.0
	var merkez := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)

	# Genisletilmis alanin iso bbox boyutu (2:1 izometri)
	var iso_w := (gw + gh) * 0.5
	var iso_h := (gw + gh) * 0.25

	var vp := SubViewport.new()
	vp.name = "Zemin3DViewport"
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(
		maxi(16, int(iso_w * _ZEMIN3D_COZUNURLUK)),
		maxi(16, int(iso_h * _ZEMIN3D_COZUNURLUK))
	)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	cimen_katmani.add_child(vp)

	var kok3d := Node3D.new()
	kok3d.name = "Zemin3DKok"
	vp.add_child(kok3d)

	var plane := PlaneMesh.new()
	plane.size = Vector2(gw, gh)
	var mi := MeshInstance3D.new()
	mi.name = "ZeminMesh"
	mi.mesh = plane
	mi.position = Vector3(merkez.x, 0.0, merkez.y)
	mi.material_override = _zemin3d_materyal(gw, gh)
	kok3d.add_child(mi)

	var isik := DirectionalLight3D.new()
	isik.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	isik.light_energy = 1.15
	isik.shadow_enabled = false
	kok3d.add_child(isik)

	# 2:1 izometriye kalibre ortografik kamera:
	# rotation (-30, 45, 0) + size = iso_h * sqrt(2) => logical_to_iso ile birebir
	var kam := Camera3D.new()
	kam.projection = Camera3D.PROJECTION_ORTHOGONAL
	kam.size = iso_h * sqrt(2.0)
	kam.rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	var geri := Vector3(sqrt(3.0) / (2.0 * sqrt(2.0)), 0.5, sqrt(3.0) / (2.0 * sqrt(2.0)))
	var mesafe := (gw + gh) * 0.31 + 200.0
	kam.position = Vector3(merkez.x, 0.0, merkez.y) + geri * mesafe
	kam.near = 1.0
	kam.far = mesafe * 2.0 + 400.0
	kok3d.add_child(kam)
	kam.current = true

	var off := _izo_cizim_offseti(sinir)
	var spr := Sprite2D.new()
	spr.name = "Zemin3DSprite"
	spr.texture = vp.get_texture()
	spr.centered = true
	spr.position = IsoProj.logical_to_iso(merkez) + off
	spr.scale = Vector2.ONE / _ZEMIN3D_COZUNURLUK
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = 0
	cimen_katmani.add_child(spr)
	_zemin3d_viewport = vp
	_zemin3d_sprite = spr


func _zemin3d_materyal(gw: float, gh: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var yol := _zengin_doku_yolu_bul()
	var tex: Texture2D = null
	if ResourceLoader.exists(yol):
		tex = load(yol) as Texture2D
	if tex != null:
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3(gw / _ZEMIN3D_DOKU_TEKRAR, gh / _ZEMIN3D_DOKU_TEKRAR, 1.0)
	else:
		mat.albedo_color = Color(0.16, 0.21, 0.13)
	return mat


func _izo_taban_ekle(sinir: Dictionary) -> void:
	var min_x := float(sinir["min_x"])
	var max_x := float(sinir["max_x"])
	var min_y := float(sinir["min_y"])
	var max_y := float(sinir["max_y"])
	var koseler_logical: Array[Vector2] = [
		Vector2(min_x, min_y),
		Vector2(max_x, min_y),
		Vector2(max_x, max_y),
		Vector2(min_x, max_y),
	]
	var off := _izo_cizim_offseti(sinir)
	var koseler_iso := PackedVector2Array()
	for k in koseler_logical:
		koseler_iso.append(IsoProj.logical_to_iso(k) + off)
	var taban := Polygon2D.new()
	taban.name = "AraziIsoTaban"
	taban.polygon = koseler_iso
	taban.color = Color(0.16, 0.21, 0.13, 1.0)
	taban.z_index = 0
	arazi_katmani.add_child(taban)


func _izo_cizim_offseti(sinir: Dictionary) -> Vector2:
	var min_x := float(sinir["min_x"])
	var min_y := float(sinir["min_y"])
	var w := float(sinir["max_x"]) - min_x
	var h := float(sinir["max_y"]) - min_y
	var merkez_logical := Vector2(min_x + w * 0.5, min_y + h * 0.5)
	var merkez_iso := IsoProj.logical_to_iso(merkez_logical)
	return merkez_logical - merkez_iso


func _arazi_tip_rengi(tip: String) -> Color:
	match tip:
		"orman":
			return Color(0.08, 0.28, 0.12, 0.65)
		"vadi":
			return Color(0.22, 0.42, 0.2, 0.6)
		"yol":
			return Color(0.55, 0.45, 0.28, 0.6)
		"su":
			return Color(0.2, 0.45, 0.72, 0.6)
		"tepe":
			return Color(0.42, 0.34, 0.26, 0.65)
		"dar_gecit":
			return Color(0.28, 0.28, 0.3, 0.65)
		"kopru":
			return Color(0.48, 0.38, 0.28, 0.65)
		_:
			return Color(0.35, 0.48, 0.28, 0.55)


func _arazi_bolge_izo_z_index(tip: String) -> int:
	match tip:
		"yol":
			return 2
		"vadi", "su":
			return 3
		"dar_gecit", "kopru":
			return 4
		"orman":
			return 5
		"tepe":
			return 6
		_:
			return 3


func _arazi_bolgesini_izo_ciz(bolge: Dictionary, rect: Rect2, tip: String, bolge_idx: int, iso_offset: Vector2) -> void:
	var koseler_logical: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]
	var koseler_iso := PackedVector2Array()
	for k in koseler_logical:
		koseler_iso.append(IsoProj.logical_to_iso(k))
	var poly := Polygon2D.new()
	poly.name = "AraziIso_" + tip + "_" + str(bolge_idx)
	poly.polygon = koseler_iso
	poly.position = iso_offset
	poly.color = _arazi_tip_rengi(tip)
	poly.z_index = _arazi_bolge_izo_z_index(tip)
	arazi_katmani.add_child(poly)

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
		"su":
			pass
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

func _su_gorsel_ekle(rect: Rect2) -> void:
	var akinti = ColorRect.new()
	akinti.position = rect.position + Vector2(0, rect.size.y * 0.32)
	akinti.size = Vector2(rect.size.x, rect.size.y * 0.36)
	akinti.color = Color(0.36, 0.56, 0.66, 0.3)
	akinti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akinti.z_index = -1
	arazi_katmani.add_child(akinti)
	var kenar_ust = ColorRect.new()
	kenar_ust.position = rect.position
	kenar_ust.size = Vector2(rect.size.x, 6)
	kenar_ust.color = Color(0.5, 0.42, 0.3, 0.4)
	kenar_ust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kenar_ust.z_index = -1
	arazi_katmani.add_child(kenar_ust)
	var kenar_alt = ColorRect.new()
	kenar_alt.position = rect.position + Vector2(0, rect.size.y - 6)
	kenar_alt.size = Vector2(rect.size.x, 6)
	kenar_alt.color = Color(0.5, 0.42, 0.3, 0.4)
	kenar_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kenar_alt.z_index = -1
	arazi_katmani.add_child(kenar_alt)

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
	for baglanti in gorsel_yollar:
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
		packed = _izo_nokta_dizisi(packed)
		var kenar = Line2D.new()
		kenar.points = packed
		kenar.width = 10.0
		kenar.default_color = Color(0.22, 0.2, 0.16, 0.35)
		kenar.antialiased = true
		kenar.z_index = _decor_z(-2)
		decor_katmani.add_child(kenar)
		var yatak = Line2D.new()
		yatak.points = packed
		yatak.width = 5.0
		yatak.default_color = Color(0.34, 0.3, 0.24, 0.45)
		yatak.antialiased = true
		yatak.z_index = _decor_z(-1)
		decor_katmani.add_child(yatak)

func _nehir_hatlari_ekle() -> void:
	for i in range(nehir_hatlari.size()):
		var hat = nehir_hatlari[i]
		var pts = hat.get("points", []) as Array
		if pts.size() < 2:
			continue
		var packed = PackedVector2Array()
		for pt in pts:
			packed.append(pt as Vector2)
		packed = _izo_nokta_dizisi(packed)
		var genislik = float(hat.get("genislik", 72.0))
		var kenar = Line2D.new()
		kenar.points = packed
		kenar.width = genislik + 22.0
		kenar.default_color = Color(0.1, 0.18, 0.26, 0.55)
		kenar.antialiased = true
		kenar.z_index = _decor_z(-2)
		decor_katmani.add_child(kenar)
		var su = Line2D.new()
		su.points = packed
		su.width = genislik
		su.default_color = Color(0.18, 0.36, 0.48, 0.78)
		su.antialiased = true
		su.z_index = _decor_z(-1)
		decor_katmani.add_child(su)

func _patika_noktalari_genislet(points: PackedVector2Array, _seed_val: int, _wobble: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var kontrol: Array = []
	for p in points:
		kontrol.append(p)
	return PathSpline.yumusat_catmull(kontrol, _YOL_SPLINE_ADIM)

func _yol_cizgisi_ekle(baslangic: Vector2, bitis: Vector2, tip: String, seed_val: int) -> void:
	var stil = _yol_stili(tip)
	var noktalar = _organik_yol_noktalari(baslangic, bitis, seed_val, float(stil.get("wobble", 22.0)))
	_yol_cizgisi_noktalari_ekle(noktalar, tip)

func _yol_cizgisi_noktalari_ekle(noktalar: PackedVector2Array, tip: String) -> void:
	var cizim_noktalari := _izo_nokta_dizisi(noktalar)
	var stil = _yol_stili(tip)
	if bool(stil.get("kesik", false)):
		_yol_kesik_hat_ekle(cizim_noktalari, stil)
		return
	var kenar = Line2D.new()
	kenar.points = cizim_noktalari
	kenar.width = float(stil.get("kenar", 24.0)) * _YOL_KALINLIK_OLCEK
	kenar.default_color = stil.get("kenar_c", Color(0.28, 0.22, 0.14, 0.55))
	kenar.antialiased = true
	kenar.z_index = _decor_z(-2)
	decor_katmani.add_child(kenar)
	var yol = Line2D.new()
	yol.points = cizim_noktalari
	yol.width = float(stil.get("yol", 16.0)) * _YOL_KALINLIK_OLCEK
	yol.default_color = stil.get("yol_c", Color(0.5, 0.42, 0.28, 0.82))
	yol.antialiased = true
	yol.z_index = _decor_z(-1)
	decor_katmani.add_child(yol)
	var orta = Line2D.new()
	orta.points = cizim_noktalari
	orta.width = float(stil.get("orta", 5.0)) * _YOL_KALINLIK_OLCEK
	orta.default_color = stil.get("orta_c", Color(0.62, 0.54, 0.36, 0.45))
	orta.antialiased = true
	orta.z_index = _decor_z(0)
	decor_katmani.add_child(orta)

func _yol_kesik_hat_ekle(pts: PackedVector2Array, stil: Dictionary) -> void:
	if pts.size() < 2:
		return
	var dash := 12.0
	var gap := 8.0
	var w := float(stil.get("yol", 5.0)) * _YOL_KALINLIK_OLCEK
	var renk: Color = stil.get("yol_c", Color(0.4, 0.45, 0.32, 0.55))
	for i in range(pts.size() - 1):
		_kesik_segment_line2d(pts[i], pts[i + 1], w, renk, dash, gap)

func _kesik_segment_line2d(a: Vector2, b: Vector2, width: float, color: Color, dash: float, gap: float) -> void:
	var delta := b - a
	var uzunluk := delta.length()
	if uzunluk < 0.01:
		return
	var yon := delta / uzunluk
	var t := 0.0
	var ciz := true
	while t < uzunluk:
		var parca := dash if ciz else gap
		var t2 := minf(t + parca, uzunluk)
		if ciz:
			var line := Line2D.new()
			line.points = PackedVector2Array([a + yon * t, a + yon * t2])
			line.width = width
			line.default_color = color
			line.antialiased = true
			line.z_index = _decor_z(-1)
			decor_katmani.add_child(line)
		t = t2
		ciz = not ciz

func _yol_stili(tip: String) -> Dictionary:
	if tip == "ana":
		return {
			"kenar": 36.0, "yol": 26.0, "orta": 8.0, "wobble": 18.0, "kesik": false,
			"kenar_c": Color(0.24, 0.19, 0.12, 0.58),
			"yol_c": Color(0.54, 0.46, 0.3, 0.88),
			"orta_c": Color(0.66, 0.58, 0.38, 0.5),
		}
	if tip == "gizli":
		return {
			"kenar": 0.0, "yol": 5.0, "orta": 0.0, "wobble": 34.0, "kesik": true,
			"kenar_c": Color(0.12, 0.16, 0.1, 0.5),
			"yol_c": Color(0.38, 0.44, 0.3, 0.58),
			"orta_c": Color(0.36, 0.4, 0.28, 0.35),
		}
	if tip == "normal":
		return {
			"kenar": 12.0, "yol": 8.0, "orta": 2.0, "wobble": 24.0, "kesik": false,
			"kenar_c": Color(0.22, 0.18, 0.12, 0.48),
			"yol_c": Color(0.42, 0.36, 0.26, 0.72),
			"orta_c": Color(0.5, 0.44, 0.32, 0.35),
		}
	return {
		"kenar": 24.0, "yol": 16.0, "orta": 5.0, "wobble": 24.0, "kesik": false,
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
		pts = _izo_nokta_dizisi(pts)
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
		tas.position = _izo(rect.position + Vector2(rng.randf_range(0.0, max(4.0, rect.size.x - s.x)), rng.randf_range(0.0, max(4.0, rect.size.y - s.y))))
		tas.color = Color(0.38, 0.35, 0.32, 0.72)
		tas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(tas)

func _dekor_calik(rect: Rect2, seed_i: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(aktif_harita_id + "calik" + str(seed_i))
	for j in range(5):
		var cali = ColorRect.new()
		cali.size = Vector2(10, 8)
		cali.position = _izo(rect.position + Vector2(rng.randf_range(0.0, rect.size.x - 10.0), rng.randf_range(0.0, rect.size.y - 8.0)))
		cali.color = Color(0.14, 0.26, 0.12, 0.7)
		cali.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(cali)

func _dekor_harabe(rect: Rect2) -> void:
	var duvar = ColorRect.new()
	duvar.position = _izo(rect.position)
	duvar.size = Vector2(rect.size.x * 0.7, rect.size.y * 0.55)
	duvar.color = Color(0.42, 0.4, 0.38, 0.65)
	duvar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(duvar)
	var kiris = ColorRect.new()
	kiris.position = _izo(rect.position + Vector2(rect.size.x * 0.45, rect.size.y * 0.2))
	kiris.size = Vector2(rect.size.x * 0.35, 8)
	kiris.color = Color(0.36, 0.34, 0.32, 0.6)
	kiris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(kiris)

func _dekor_kamp(rect: Rect2) -> void:
	for i in range(2):
		var cadir = ColorRect.new()
		cadir.size = Vector2(22, 16)
		cadir.position = _izo(rect.position + Vector2(float(i) * 28.0 + 8.0, rect.size.y * 0.35))
		cadir.color = Color(0.52, 0.44, 0.3, 0.7)
		cadir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(cadir)
	var ates = ColorRect.new()
	ates.size = Vector2(8, 8)
	ates.position = _izo(rect.position + Vector2(rect.size.x * 0.55, rect.size.y * 0.55))
	ates.color = Color(0.7, 0.42, 0.18, 0.55)
	ates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ates)

func _dekor_tarla(rect: Rect2) -> void:
	var taban = ColorRect.new()
	taban.position = _izo(rect.position)
	taban.size = rect.size
	taban.color = Color(0.48, 0.42, 0.28, 0.45)
	taban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(taban)
	var satir_say = clampi(int(rect.size.y / 14.0), 3, 8)
	for i in range(satir_say):
		var satir = ColorRect.new()
		satir.position = _izo(rect.position + Vector2(4, float(i) * 14.0 + 4))
		satir.size = Vector2(rect.size.x - 8, 4)
		satir.color = Color(0.4, 0.36, 0.24, 0.35)
		satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(satir)

func _dekor_sirt(rect: Rect2) -> void:
	var isik = ColorRect.new()
	isik.position = _izo(rect.position + Vector2(6, 4))
	isik.size = Vector2(rect.size.x * 0.55, rect.size.y * 0.45)
	isik.color = Color(0.34, 0.38, 0.26, 0.35)
	isik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(isik)
	var golge = ColorRect.new()
	golge.position = _izo(rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.48))
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
		canopy.position = _izo(Vector2(px, py - 5))
		canopy.color = Color(0.07, 0.24, 0.11, 0.8)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(canopy)
		var trunk = ColorRect.new()
		trunk.size = Vector2(3, 6)
		trunk.position = _izo(Vector2(px + 4, py))
		trunk.color = Color(0.2, 0.14, 0.09, 0.9)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(trunk)

func _dekor_kopru(rect: Rect2) -> void:
	var ayak1 = ColorRect.new()
	ayak1.position = _izo(rect.position)
	ayak1.size = Vector2(10, rect.size.y)
	ayak1.color = Color(0.36, 0.34, 0.32, 0.75)
	ayak1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ayak1)
	var ayak2 = ColorRect.new()
	ayak2.position = _izo(rect.position + Vector2(rect.size.x - 10.0, 0))
	ayak2.size = Vector2(10, rect.size.y)
	ayak2.color = Color(0.36, 0.34, 0.32, 0.75)
	ayak2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_katmani.add_child(ayak2)
	var tabla = ColorRect.new()
	tabla.position = _izo(rect.position + Vector2(0, rect.size.y * 0.35))
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
		var etiket_pos := _izo(Vector2(float(etiket.get("x", 0.0)), float(etiket.get("y", 0.0))))
		golge.position = etiket_pos + Vector2(1.0, 1.0)
		golge.add_theme_font_size_override("font_size", 11)
		golge.add_theme_color_override("font_color", Color(0.05, 0.06, 0.05, 0.55))
		golge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_katmani.add_child(golge)
		var label = Label.new()
		label.text = metin
		label.position = etiket_pos
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
	if tip == "su":
		return Color(0.0, 0.0, 0.0, 0.0)
	return Color(0, 0, 0, 0)
