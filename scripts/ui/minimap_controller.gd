extends RefCounted
class_name MinimapController

var minimap_panel: PanelContainer = null
var minimap_surface: ColorRect = null
var minimap_kamera_rect: ColorRect = null
var minimap_birim_osmanli: ColorRect = null
var minimap_birim_dogu_roma: ColorRect = null
var minimap_nokta_isaretleri: Dictionary = {}
var minimap_fow_rect: TextureRect = null
var minimap_boyut := Vector2(206, 124)
const KAMERA_NOKTA_BOYUT := Vector2(6, 6)

func get_panel() -> PanelContainer:
	return minimap_panel

func build(ui_root: Control, yeni_boyut: Vector2, panel_style: StyleBoxFlat, surface_color: Color, nokta_konumlari: Dictionary) -> void:
	if ui_root == null:
		return
	minimap_boyut = yeni_boyut
	if minimap_panel == null:
		minimap_panel = ui_root.find_child("MinimapPanel", true, false) as PanelContainer
	if minimap_panel == null:
		minimap_panel = PanelContainer.new()
		minimap_panel.name = "MinimapPanel"
		ui_root.add_child(minimap_panel)
	minimap_panel.custom_minimum_size = minimap_boyut
	minimap_panel.add_theme_stylebox_override("panel", panel_style)
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -minimap_boyut.x - 26
	minimap_panel.offset_top = 62
	minimap_panel.offset_right = -26
	minimap_panel.offset_bottom = 62 + minimap_boyut.y

	var minimap_margin = minimap_panel.find_child("MinimapMargin", true, false) as MarginContainer
	if minimap_margin == null:
		minimap_margin = MarginContainer.new()
		minimap_margin.name = "MinimapMargin"
		minimap_margin.add_theme_constant_override("margin_left", 8)
		minimap_margin.add_theme_constant_override("margin_right", 8)
		minimap_margin.add_theme_constant_override("margin_top", 8)
		minimap_margin.add_theme_constant_override("margin_bottom", 8)
		minimap_panel.add_child(minimap_margin)

	minimap_surface = minimap_panel.find_child("MinimapSurface", true, false) as ColorRect
	if minimap_surface == null:
		minimap_surface = ColorRect.new()
		minimap_surface.name = "MinimapSurface"
		minimap_margin.add_child(minimap_surface)
	minimap_surface.custom_minimum_size = minimap_boyut - Vector2(16, 16)
	minimap_surface.color = surface_color

	minimap_fow_rect = minimap_surface.find_child("MinimapFow", true, false) as TextureRect
	if minimap_fow_rect == null:
		minimap_fow_rect = TextureRect.new()
		minimap_fow_rect.name = "MinimapFow"
		minimap_fow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		minimap_fow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_fow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		minimap_surface.add_child(minimap_fow_rect)
	minimap_fow_rect.show_behind_parent = false

	minimap_kamera_rect = minimap_surface.find_child("MinimapKameraRect", true, false) as ColorRect
	if minimap_kamera_rect == null:
		minimap_kamera_rect = ColorRect.new()
		minimap_kamera_rect.name = "MinimapKameraRect"
		minimap_kamera_rect.size = KAMERA_NOKTA_BOYUT
		minimap_kamera_rect.color = Color(1, 1, 1, 0.85)
		minimap_kamera_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_surface.add_child(minimap_kamera_rect)

	minimap_birim_osmanli = minimap_surface.find_child("MinimapBirimOsmanli", true, false) as ColorRect
	if minimap_birim_osmanli == null:
		minimap_birim_osmanli = ColorRect.new()
		minimap_birim_osmanli.name = "MinimapBirimOsmanli"
		minimap_birim_osmanli.size = Vector2(5, 5)
		minimap_birim_osmanli.color = Color.GOLD
		minimap_surface.add_child(minimap_birim_osmanli)

	minimap_birim_dogu_roma = minimap_surface.find_child("MinimapBirimDoguRoma", true, false) as ColorRect
	if minimap_birim_dogu_roma == null:
		minimap_birim_dogu_roma = ColorRect.new()
		minimap_birim_dogu_roma.name = "MinimapBirimDoguRoma"
		minimap_birim_dogu_roma.size = Vector2(5, 5)
		minimap_birim_dogu_roma.color = Color.PURPLE
		minimap_surface.add_child(minimap_birim_dogu_roma)

	for key in minimap_nokta_isaretleri.keys():
		if not nokta_konumlari.has(key):
			var eski = minimap_nokta_isaretleri[key]
			if is_instance_valid(eski):
				eski.queue_free()
			minimap_nokta_isaretleri.erase(key)
	for nokta in nokta_konumlari.keys():
		var isim = "MinimapNokta_" + str(nokta)
		var isaret = minimap_surface.find_child(isim, true, false) as ColorRect
		if isaret == null:
			isaret = ColorRect.new()
			isaret.name = isim
			isaret.size = Vector2(4, 4)
			isaret.color = Color(0.7, 0.7, 0.7, 0.9)
			minimap_surface.add_child(isaret)
		minimap_nokta_isaretleri[nokta] = isaret

func world_to_panel(pos: Vector2, harita_sinir: Dictionary) -> Vector2:
	var panel_size = minimap_surface.size if minimap_surface != null else minimap_boyut
	var w = harita_sinir["max_x"] - harita_sinir["min_x"]
	var h = harita_sinir["max_y"] - harita_sinir["min_y"]
	if w <= 0 or h <= 0:
		return Vector2.ZERO
	return Vector2(
		((pos.x - harita_sinir["min_x"]) / w) * panel_size.x,
		((pos.y - harita_sinir["min_y"]) / h) * panel_size.y
	)

func panel_to_world(pos: Vector2, harita_sinir: Dictionary) -> Vector2:
	var panel_size = minimap_surface.size if minimap_surface != null else minimap_boyut
	var w = harita_sinir["max_x"] - harita_sinir["min_x"]
	var h = harita_sinir["max_y"] - harita_sinir["min_y"]
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return Vector2(harita_sinir["min_x"], harita_sinir["min_y"])
	return Vector2(
		harita_sinir["min_x"] + (pos.x / panel_size.x) * w,
		harita_sinir["min_y"] + (pos.y / panel_size.y) * h
	)

func update(fog_system: Object, nokta_konumlari: Dictionary, nokta_sahipleri: Dictionary, aktif_birimler: Array, kamera: Camera2D, viewport_size: Vector2, harita_sinir: Dictionary, ekran_to_logical_fn: Callable = Callable(), logical_to_ekran_fn: Callable = Callable()) -> void:
	if minimap_panel == null:
		return
	if fog_system != null and minimap_fow_rect != null:
		fog_system.update_minimap_fow()
		var doku = fog_system.get_minimap_fow_texture()
		if doku != null:
			minimap_fow_rect.texture = doku
	var kesfedilen_noktalar = fog_system.get_discovered_points() if fog_system != null else {}
	for nokta in minimap_nokta_isaretleri:
		var isaret = minimap_nokta_isaretleri[nokta]
		if not is_instance_valid(isaret) or not nokta_konumlari.has(nokta):
			continue
		var merkez = nokta_konumlari[nokta] + Vector2(40, 40)
		isaret.position = world_to_panel(merkez, harita_sinir) - Vector2(2, 2)
		isaret.visible = kesfedilen_noktalar.get(nokta, false)
		if nokta_sahipleri.get(nokta, "tarafsiz") == "osmanli":
			isaret.color = Color.GOLD
		elif nokta_sahipleri.get(nokta, "tarafsiz") == "dogu_roma":
			isaret.color = Color.PURPLE
		else:
			isaret.color = Color(0.7, 0.7, 0.7, 0.9)

	var os_top = Vector2.ZERO
	var os_adet = 0
	var dr_top = Vector2.ZERO
	var dr_adet = 0
	for birim in aktif_birimler:
		if birim["hp"] <= 0:
			continue
		if birim["taraf"] == "osmanli":
			os_top += birim["konum"]
			os_adet += 1
		else:
			dr_top += birim["konum"]
			dr_adet += 1
	if minimap_birim_osmanli != null:
		minimap_birim_osmanli.visible = os_adet > 0
		if os_adet > 0:
			minimap_birim_osmanli.position = world_to_panel(os_top / float(os_adet), harita_sinir) - Vector2(2, 2)
	if minimap_birim_dogu_roma != null:
		minimap_birim_dogu_roma.visible = dr_adet > 0
		if dr_adet > 0:
			minimap_birim_dogu_roma.position = world_to_panel(dr_top / float(dr_adet), harita_sinir) - Vector2(2, 2)

	if kamera != null and minimap_kamera_rect != null:
		var merkez_logical: Vector2 = kamera.position
		if ekran_to_logical_fn.is_valid():
			merkez_logical = ekran_to_logical_fn.call(kamera.position)
		var mini_pos := world_to_panel(merkez_logical, harita_sinir)
		minimap_kamera_rect.position = mini_pos - KAMERA_NOKTA_BOYUT * 0.5
		minimap_kamera_rect.size = KAMERA_NOKTA_BOYUT
		minimap_kamera_rect.visible = true

func handle_click(event_position: Vector2, kamera: Camera2D, harita_sinir: Dictionary, camera_clamp: Callable, logical_to_ekran_fn: Callable = Callable()) -> bool:
	if minimap_panel == null:
		return false
	var hedef_rect = Rect2(
		minimap_surface.get_global_position() if minimap_surface != null else minimap_panel.get_global_position(),
		minimap_surface.size if minimap_surface != null else minimap_panel.size
	)
	if not hedef_rect.has_point(event_position):
		return false
	if kamera != null:
		var yerel = event_position - hedef_rect.position
		var mantiksal = panel_to_world(yerel, harita_sinir)
		if logical_to_ekran_fn.is_valid():
			kamera.position = logical_to_ekran_fn.call(mantiksal)
		else:
			kamera.position = mantiksal
		if camera_clamp.is_valid():
			camera_clamp.call()
	return true
