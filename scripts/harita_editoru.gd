extends Node2D

const IsoProjection = preload("res://scripts/iso_projection.gd")

const HARITA_SINIR := {"min_x": 0.0, "max_x": 5000.0, "min_y": 0.0, "max_y": 3000.0}
const KAMERA_HIZ := 900.0
const ZOOM_ADIM := 0.1
const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.5
const SECIM_YARICAP := 22.0
const CIKTI_DOSYA := "res://data/maps/editor_cikti.json"

enum EditorMod { US, NOKTA, YOL }

var mod: EditorMod = EditorMod.NOKTA
var noktalar: Array[Dictionary] = []
var yollar: Array[Dictionary] = []
var _secili_yol_kaynak_id := ""
var _islem_gecmisi: Array[Dictionary] = []
var _kamera: Camera2D
var _orta_tik_surukleme := false
var _durum_mesaji := ""
var _durum_sure := 0.0


func _ready() -> void:
	_kamera = $Camera2D
	_kamera.position = _harita_merkez_logical()
	_kamera.zoom = Vector2.ONE
	queue_redraw()


func _process(delta: float) -> void:
	_durum_sure = maxf(0.0, _durum_sure - delta)
	var yon := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		yon.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		yon.y += 1.0
	if Input.is_key_pressed(KEY_A):
		yon.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		yon.x += 1.0
	if yon != Vector2.ZERO:
		_kamera.position += yon.normalized() * KAMERA_HIZ * delta * maxf(0.4, _kamera.zoom.x)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key_input(event as InputEventKey)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_left_click(get_global_mouse_position())
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_orta_tik_surukleme = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x - ZOOM_ADIM)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x + ZOOM_ADIM)
	elif event is InputEventMouseMotion and _orta_tik_surukleme:
		var mm := event as InputEventMouseMotion
		_kamera.position -= mm.relative * _kamera.zoom


func _draw() -> void:
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var koseler := PackedVector2Array([
		IsoProjection.logical_to_iso(Vector2(HARITA_SINIR.min_x, HARITA_SINIR.min_y)) + off,
		IsoProjection.logical_to_iso(Vector2(HARITA_SINIR.max_x, HARITA_SINIR.min_y)) + off,
		IsoProjection.logical_to_iso(Vector2(HARITA_SINIR.max_x, HARITA_SINIR.max_y)) + off,
		IsoProjection.logical_to_iso(Vector2(HARITA_SINIR.min_x, HARITA_SINIR.max_y)) + off,
	])
	draw_colored_polygon(koseler, Color(0.42, 0.62, 0.43, 1.0))

	var font := ThemeDB.fallback_font
	var fs := ThemeDB.fallback_font_size
	for yol in yollar:
		var a_id := str(yol.get("a", ""))
		var b_id := str(yol.get("b", ""))
		var a_nokta := _nokta_id_ile_bul(a_id)
		var b_nokta := _nokta_id_ile_bul(b_id)
		if a_nokta.is_empty() or b_nokta.is_empty():
			continue
		var a_pos := IsoProjection.logical_to_iso(a_nokta["konum"]) + off
		var b_pos := IsoProjection.logical_to_iso(b_nokta["konum"]) + off
		draw_line(a_pos, b_pos, Color(0.66, 0.52, 0.3, 0.92), 6.0, true)

	for nokta in noktalar:
		var logical: Vector2 = nokta["konum"]
		var iso := IsoProjection.logical_to_iso(logical) + off
		var tip := str(nokta.get("tip", "nokta"))
		var renk := Color(0.3, 0.55, 0.9, 0.95) if tip == "us" else Color(0.75, 0.75, 0.75, 0.95)
		draw_circle(iso, 8.0, renk)
		var id := str(nokta.get("id", ""))
		if id == _secili_yol_kaynak_id:
			draw_arc(iso, 14.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.25, 0.95), 2.0)
		var etiket := "%s (%d, %d)" % [id, int(round(logical.x)), int(round(logical.y))]
		draw_string(font, iso + Vector2(10, -8), etiket, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1, 1, 1, 0.95))

	var mod_yazi := "MOD: %s" % _mod_adi()
	draw_string(font, Vector2(18, 26), mod_yazi, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs + 2, Color(1, 0.95, 0.7, 1))
	if _durum_sure > 0.0 and _durum_mesaji != "":
		draw_string(font, Vector2(18, 48), _durum_mesaji, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.85, 1, 0.85, 1))


func merkez_logical_iso_offseti(sinir: Dictionary) -> Vector2:
	var min_x := float(sinir["min_x"])
	var min_y := float(sinir["min_y"])
	var w := float(sinir["max_x"]) - min_x
	var h := float(sinir["max_y"]) - min_y
	var merkez_logical := Vector2(min_x + w * 0.5, min_y + h * 0.5)
	var merkez_iso := IsoProjection.logical_to_iso(merkez_logical)
	return merkez_logical - merkez_iso


func _harita_merkez_logical() -> Vector2:
	return Vector2(
		(HARITA_SINIR["min_x"] + HARITA_SINIR["max_x"]) * 0.5,
		(HARITA_SINIR["min_y"] + HARITA_SINIR["max_y"]) * 0.5
	)


func _zoom_ayarla(deger: float) -> void:
	var z := clampf(deger, ZOOM_MIN, ZOOM_MAX)
	_kamera.zoom = Vector2(z, z)


func _handle_key_input(ev: InputEventKey) -> void:
	if ev.ctrl_pressed and ev.keycode == KEY_S:
		_kaydet_editor_cikti()
		return
	match ev.keycode:
		KEY_1:
			mod = EditorMod.US
			_secili_yol_kaynak_id = ""
			queue_redraw()
		KEY_2:
			mod = EditorMod.NOKTA
			_secili_yol_kaynak_id = ""
			queue_redraw()
		KEY_Y:
			mod = EditorMod.YOL
			_secili_yol_kaynak_id = ""
			queue_redraw()
		KEY_S:
			_kaydet_editor_cikti()
		KEY_Z:
			_geri_al()
		KEY_C, KEY_DELETE:
			_tumunu_temizle()


func _handle_left_click(mouse_dunya: Vector2) -> void:
	if mod == EditorMod.YOL:
		_yol_modu_tikla(mouse_dunya)
		return
	var logical := IsoProjection.iso_to_logical(mouse_dunya - merkez_logical_iso_offseti(HARITA_SINIR))
	var yeni_id := _id_uret(noktalar.size())
	var tip := "us" if mod == EditorMod.US else "nokta"
	var kayit := {"tip": tip, "konum": logical, "id": yeni_id}
	noktalar.append(kayit)
	_islem_gecmisi.append({"tip": "nokta", "id": yeni_id})
	queue_redraw()


func _yol_modu_tikla(mouse_dunya: Vector2) -> void:
	var hedef_nokta := _ekrana_en_yakin_nokta(mouse_dunya)
	if hedef_nokta.is_empty():
		return
	var id := str(hedef_nokta.get("id", ""))
	if id == "":
		return
	if _secili_yol_kaynak_id == "":
		_secili_yol_kaynak_id = id
		queue_redraw()
		return
	if _secili_yol_kaynak_id == id:
		_secili_yol_kaynak_id = ""
		queue_redraw()
		return
	if _yol_var_mi(_secili_yol_kaynak_id, id):
		_secili_yol_kaynak_id = id
		queue_redraw()
		return
	var yol := {"a": _secili_yol_kaynak_id, "b": id}
	yollar.append(yol)
	_islem_gecmisi.append({"tip": "yol", "a": _secili_yol_kaynak_id, "b": id})
	_secili_yol_kaynak_id = ""
	queue_redraw()


func _ekrana_en_yakin_nokta(mouse_dunya: Vector2) -> Dictionary:
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var secim: Dictionary = {}
	var min_d := INF
	for nokta in noktalar:
		var iso := IsoProjection.logical_to_iso(nokta["konum"]) + off
		var d := iso.distance_to(mouse_dunya)
		if d < min_d:
			min_d = d
			secim = nokta
	if min_d <= SECIM_YARICAP:
		return secim
	return {}


func _yol_var_mi(a: String, b: String) -> bool:
	for yol in yollar:
		var ya := str(yol.get("a", ""))
		var yb := str(yol.get("b", ""))
		if (ya == a and yb == b) or (ya == b and yb == a):
			return true
	return false


func _nokta_id_ile_bul(id: String) -> Dictionary:
	for nokta in noktalar:
		if str(nokta.get("id", "")) == id:
			return nokta
	return {}


func _id_uret(index: int) -> String:
	if index < 26:
		return char(65 + index)
	var ana := int(index / 26) - 1
	var alt := index % 26
	return char(65 + ana) + char(65 + alt)


func _kaydet_editor_cikti() -> void:
	var json_data := {
		"id": "editor_cikti",
		"isim": "Editor Haritasi",
		"sinir": {"min_x": 0, "max_x": 5000, "min_y": 0, "max_y": 3000},
		"noktalar": {},
		"usler": [],
		"yollar_basit": [],
	}
	for nokta in noktalar:
		var id := str(nokta.get("id", ""))
		var konum: Vector2 = nokta["konum"]
		json_data["noktalar"][id] = [int(round(konum.x)), int(round(konum.y))]
		if str(nokta.get("tip", "nokta")) == "us":
			json_data["usler"].append(id)
	for yol in yollar:
		json_data["yollar_basit"].append({"a": str(yol.get("a", "")), "b": str(yol.get("b", ""))})

	var hedef_yol := CIKTI_DOSYA
	var dosya := FileAccess.open(hedef_yol, FileAccess.WRITE)
	if dosya == null:
		_durum_mesaji = "res:// yazilamadi, user:// yaziliyor"
		_durum_sure = 2.0
		hedef_yol = "user://editor_cikti.json"
		dosya = FileAccess.open(hedef_yol, FileAccess.WRITE)
		if dosya == null:
			push_error("Kaydetme basarisiz: editor_cikti.json")
			_durum_mesaji = "Kaydetme basarisiz"
			_durum_sure = 2.0
			queue_redraw()
			return
	dosya.store_string(JSON.stringify(json_data, "\t"))
	dosya.close()
	print("Kaydedildi: %s" % hedef_yol)
	_durum_mesaji = "Kaydedildi: %s" % hedef_yol
	_durum_sure = 3.0
	queue_redraw()


func _geri_al() -> void:
	if _islem_gecmisi.is_empty():
		return
	var son = _islem_gecmisi.pop_back()
	var tip := str(son.get("tip", ""))
	if tip == "yol":
		var a := str(son.get("a", ""))
		var b := str(son.get("b", ""))
		for i in range(yollar.size() - 1, -1, -1):
			var y = yollar[i]
			var ya := str(y.get("a", ""))
			var yb := str(y.get("b", ""))
			if (ya == a and yb == b) or (ya == b and yb == a):
				yollar.remove_at(i)
				break
	elif tip == "nokta":
		var id := str(son.get("id", ""))
		for i in range(yollar.size() - 1, -1, -1):
			var y = yollar[i]
			if str(y.get("a", "")) == id or str(y.get("b", "")) == id:
				yollar.remove_at(i)
		for i in range(noktalar.size() - 1, -1, -1):
			if str(noktalar[i].get("id", "")) == id:
				noktalar.remove_at(i)
				break
	_secili_yol_kaynak_id = ""
	queue_redraw()


func _tumunu_temizle() -> void:
	noktalar.clear()
	yollar.clear()
	_islem_gecmisi.clear()
	_secili_yol_kaynak_id = ""
	_durum_mesaji = "Temizlendi"
	_durum_sure = 1.5
	queue_redraw()


func _mod_adi() -> String:
	match mod:
		EditorMod.US:
			return "US"
		EditorMod.NOKTA:
			return "NOKTA"
		EditorMod.YOL:
			return "YOL"
	return "?"
