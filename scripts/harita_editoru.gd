extends Node2D

const IsoProjection = preload("res://scripts/iso_projection.gd")

const HARITA_SINIR := {"min_x": 0.0, "max_x": 5000.0, "min_y": 0.0, "max_y": 3000.0}
const KAMERA_HIZ := 900.0
const ZOOM_ADIM := 0.1
const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.5
const SECIM_YARICAP := 22.0
const YOL_SEG_ESIK := 50.0
const PATIKA_NOKTA_ESIK := 30.0
const CIKTI_DOSYA := "res://data/maps/editor_cikti.json"
const _ACILISTA_YUKLE := true

enum EditorMod { US, NOKTA, YOL, KIVIR }

var mod: EditorMod = EditorMod.NOKTA
var noktalar: Array[Dictionary] = []
var yollar: Array[Dictionary] = []
var _secili_yol_kaynak_id := ""
var _yol_cizim_ara: Array = []
var _islem_gecmisi: Array[Dictionary] = []
var _kamera: Camera2D
var _orta_tik_surukleme := false
var _surukleme_ara: Dictionary = {}
var _surukleme_eski_konum := Vector2.ZERO
var _durum_mesaji := ""
var _durum_sure := 0.0
var _sonraki_nokta_index := 0


func _ready() -> void:
	_kamera = $Camera2D
	_kamera.position = _harita_merkez_logical()
	_kamera.zoom = Vector2.ONE
	if _ACILISTA_YUKLE:
		_yukle_editor_cikti(true)
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
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_left_click(get_global_mouse_position())
			else:
				_handle_left_release()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_right_click(get_global_mouse_position())
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_orta_tik_surukleme = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x - ZOOM_ADIM)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x + ZOOM_ADIM)
	elif event is InputEventMouseMotion:
		if not _surukleme_ara.is_empty():
			_ara_nokta_surukle(get_global_mouse_position())
			queue_redraw()
		elif mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			queue_redraw()
		elif _orta_tik_surukleme:
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
		var iso_pts := _yol_iso_polyline(yol, off)
		if iso_pts.size() >= 2:
			draw_polyline(iso_pts, Color(0.66, 0.52, 0.3, 0.92), 6.0, true)
		var ara_raw: Variant = yol.get("ara", [])
		if typeof(ara_raw) == TYPE_ARRAY:
			for v in ara_raw as Array:
				if v is Vector2:
					var iso_ara := IsoProjection.logical_to_iso(v) + off
					draw_circle(iso_ara, 5.0, Color(1.0, 0.65, 0.15, 0.95))

	if not _surukleme_ara.is_empty():
		var yi: int = _surukleme_ara["yol_idx"]
		var ai: int = _surukleme_ara["ara_idx"]
		var ara_arr: Array = yollar[yi]["ara"]
		var suruklenen: Vector2 = ara_arr[ai]
		var iso_suruk := IsoProjection.logical_to_iso(suruklenen) + off
		draw_circle(iso_suruk, 7.0, Color(1.0, 0.85, 0.2, 1.0))
		draw_string(
			font,
			iso_suruk + Vector2(10, -8),
			"(%d, %d)" % [int(round(suruklenen.x)), int(round(suruklenen.y))],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(1.0, 0.9, 0.5, 1.0)
		)

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

	if mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
		var bas_n := _nokta_id_ile_bul(_secili_yol_kaynak_id)
		if not bas_n.is_empty():
			var onizleme := PackedVector2Array()
			onizleme.append(IsoProjection.logical_to_iso(bas_n["konum"]) + off)
			for v in _yol_cizim_ara:
				if v is Vector2:
					onizleme.append(IsoProjection.logical_to_iso(v) + off)
					draw_circle(IsoProjection.logical_to_iso(v) + off, 4.0, Color(1.0, 0.65, 0.15, 0.85))
			if onizleme.size() >= 1:
				draw_polyline(onizleme, Color(0.8, 0.6, 0.35, 0.65), 5.0, true)
				var fare_logical := IsoProjection.iso_to_logical(get_global_mouse_position() - off)
				var fare_iso := IsoProjection.logical_to_iso(fare_logical) + off
				draw_line(onizleme[onizleme.size() - 1], fare_iso, Color(0.9, 0.7, 0.4, 0.45), 4.0, true)

	var mod_yazi := "MOD: %s" % _mod_adi()
	draw_string(font, Vector2(18, 26), mod_yazi, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs + 2, Color(1, 0.95, 0.7, 1))
	var durum_y := 70.0
	draw_string(font, Vector2(18, 48), "Kaydet: P | Yukle: L", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.85, 0.9, 0.75, 1.0))
	if mod == EditorMod.YOL:
		draw_string(
			font,
			Vector2(18, 70),
			"Noktadan basla -> serbest tikla -> bitis noktasi | Sag tik/Backspace geri | Esc iptal",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.9, 0.85, 0.65, 1.0)
		)
		durum_y = 92.0
	elif mod == EditorMod.KIVIR:
		draw_string(
			font,
			Vector2(18, 70),
			"Yola tikla=ara nokta, surukle=tasi, sag tik=sil",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.9, 0.85, 0.65, 1.0)
		)
		durum_y = 92.0
	if _durum_sure > 0.0 and _durum_mesaji != "":
		draw_string(font, Vector2(18, durum_y), _durum_mesaji, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.85, 1, 0.85, 1))


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
	if _tus_mu(ev, KEY_P):
		_kaydet_editor_cikti()
		return
	if _tus_mu(ev, KEY_1):
			mod = EditorMod.US
			_yol_cizim_iptal()
			queue_redraw()
	elif _tus_mu(ev, KEY_2):
			mod = EditorMod.NOKTA
			_yol_cizim_iptal()
			queue_redraw()
	elif _tus_mu(ev, KEY_Y):
			mod = EditorMod.YOL
			_yol_cizim_iptal()
			queue_redraw()
	elif _tus_mu(ev, KEY_K):
			mod = EditorMod.KIVIR
			_yol_cizim_iptal()
			_surukleme_ara = {}
			queue_redraw()
	elif _tus_mu(ev, KEY_ESCAPE) and mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			_yol_cizim_iptal()
			_durum_mesaji = "Yol cizimi iptal"
			_durum_sure = 1.5
			queue_redraw()
	elif _tus_mu(ev, KEY_BACKSPACE) and mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			_yol_cizim_ara_son_geri()
			queue_redraw()
	elif _tus_mu(ev, KEY_Z):
			_geri_al()
	elif _tus_mu(ev, KEY_C) or _tus_mu(ev, KEY_DELETE):
			_tumunu_temizle()
	elif _tus_mu(ev, KEY_L):
		_yukle_editor_cikti(false)
		queue_redraw()


func _tus_mu(ev: InputEventKey, code: Key) -> bool:
	return ev.keycode == code or ev.physical_keycode == code


func _handle_left_click(mouse_dunya: Vector2) -> void:
	if mod == EditorMod.YOL:
		_yol_modu_tikla(mouse_dunya)
		return
	if mod == EditorMod.KIVIR:
		_kivir_modu_tikla(mouse_dunya)
		return
	var logical := IsoProjection.iso_to_logical(mouse_dunya - merkez_logical_iso_offseti(HARITA_SINIR))
	var yeni_id := _id_uret(_sonraki_nokta_index)
	_sonraki_nokta_index += 1
	var tip := "us" if mod == EditorMod.US else "nokta"
	var kayit := {"tip": tip, "konum": logical, "id": yeni_id}
	noktalar.append(kayit)
	_islem_gecmisi.append({"tip": "nokta", "id": yeni_id})
	queue_redraw()


func _yol_cizim_iptal() -> void:
	_secili_yol_kaynak_id = ""
	_yol_cizim_ara.clear()


func _yol_cizim_ara_son_geri() -> void:
	if not _yol_cizim_ara.is_empty():
		_yol_cizim_ara.pop_back()


func _yol_modu_tikla(mouse_dunya: Vector2) -> void:
	var hedef_nokta := _ekrana_en_yakin_nokta(mouse_dunya)
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var logical := IsoProjection.iso_to_logical(mouse_dunya - off)

	if _secili_yol_kaynak_id == "":
		if hedef_nokta.is_empty():
			_durum_mesaji = "Yol bir noktadan baslamali"
			_durum_sure = 2.0
			queue_redraw()
			return
		_secili_yol_kaynak_id = str(hedef_nokta.get("id", ""))
		_yol_cizim_ara.clear()
		queue_redraw()
		return

	if not hedef_nokta.is_empty():
		var bitis_id := str(hedef_nokta.get("id", ""))
		if bitis_id == _secili_yol_kaynak_id:
			return
		if _yol_var_mi(_secili_yol_kaynak_id, bitis_id):
			_durum_mesaji = "Bu yol zaten var"
			_durum_sure = 2.0
			queue_redraw()
			return
		var ara_kopya: Array = []
		for v in _yol_cizim_ara:
			if v is Vector2:
				ara_kopya.append(v)
		var yol := {"a": _secili_yol_kaynak_id, "b": bitis_id, "ara": ara_kopya}
		yollar.append(yol)
		_islem_gecmisi.append({"tip": "yol", "a": _secili_yol_kaynak_id, "b": bitis_id})
		_yol_cizim_iptal()
		queue_redraw()
		return

	_yol_cizim_ara.append(logical)
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


func _yol_polyline_logical(yol: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var a_nokta := _nokta_id_ile_bul(str(yol.get("a", "")))
	var b_nokta := _nokta_id_ile_bul(str(yol.get("b", "")))
	if a_nokta.is_empty() or b_nokta.is_empty():
		return pts
	pts.append(a_nokta["konum"])
	var ara_raw: Variant = yol.get("ara", [])
	if typeof(ara_raw) == TYPE_ARRAY:
		for v in ara_raw as Array:
			if v is Vector2:
				pts.append(v)
	pts.append(b_nokta["konum"])
	return pts


func _yol_iso_polyline(yol: Dictionary, off: Vector2) -> PackedVector2Array:
	var logical_pts := _yol_polyline_logical(yol)
	var iso_pts := PackedVector2Array()
	for p in logical_pts:
		iso_pts.append(IsoProjection.logical_to_iso(p) + off)
	return iso_pts


func _nokta_segment_mesafe(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _en_yakin_yol_segmenti(logical: Vector2) -> Dictionary:
	var min_d := INF
	var sonuc: Dictionary = {}
	for yi in range(yollar.size()):
		var poly := _yol_polyline_logical(yollar[yi])
		if poly.size() < 2:
			continue
		for si in range(poly.size() - 1):
			var d := _nokta_segment_mesafe(logical, poly[si], poly[si + 1])
			if d < min_d:
				min_d = d
				sonuc = {"yol_idx": yi, "segment_idx": si}
	if min_d <= YOL_SEG_ESIK:
		return sonuc
	return {}


func _en_yakin_ara_nokta(mouse_dunya: Vector2) -> Dictionary:
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var min_d := INF
	var sonuc: Dictionary = {}
	for yi in range(yollar.size()):
		var ara_raw: Variant = yollar[yi].get("ara", [])
		if typeof(ara_raw) != TYPE_ARRAY:
			continue
		var ara_arr: Array = ara_raw
		for ai in range(ara_arr.size()):
			var v: Vector2 = ara_arr[ai]
			var iso := IsoProjection.logical_to_iso(v) + off
			var d := iso.distance_to(mouse_dunya)
			if d < min_d:
				min_d = d
				sonuc = {"yol_idx": yi, "ara_idx": ai}
	if min_d <= SECIM_YARICAP:
		return sonuc
	return {}


func _kivir_modu_tikla(mouse_dunya: Vector2) -> void:
	var ara_hit := _en_yakin_ara_nokta(mouse_dunya)
	if not ara_hit.is_empty():
		_surukleme_ara = ara_hit
		var ara_arr: Array = yollar[ara_hit["yol_idx"]]["ara"]
		_surukleme_eski_konum = ara_arr[ara_hit["ara_idx"]]
		return
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var logical := IsoProjection.iso_to_logical(mouse_dunya - off)
	var seg_hit := _en_yakin_yol_segmenti(logical)
	if seg_hit.is_empty():
		return
	var yol_idx: int = seg_hit["yol_idx"]
	var seg_idx: int = seg_hit["segment_idx"]
	var yol: Dictionary = yollar[yol_idx]
	if not yol.has("ara"):
		yol["ara"] = []
	var ara_arr: Array = yol["ara"]
	ara_arr.insert(seg_idx, logical)
	_islem_gecmisi.append({"tip": "ara_ekle", "yol_idx": yol_idx, "ara_idx": seg_idx, "konum": logical})
	queue_redraw()


func _handle_left_release() -> void:
	if _surukleme_ara.is_empty():
		return
	var yi: int = _surukleme_ara["yol_idx"]
	var ai: int = _surukleme_ara["ara_idx"]
	var yeni: Vector2 = yollar[yi]["ara"][ai]
	if yeni.distance_to(_surukleme_eski_konum) > 0.5:
		_islem_gecmisi.append({
			"tip": "ara_tasi",
			"yol_idx": yi,
			"ara_idx": ai,
			"eski_konum": _surukleme_eski_konum,
		})
	_surukleme_ara = {}
	queue_redraw()


func _handle_right_click(mouse_dunya: Vector2) -> void:
	if mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
		_yol_cizim_ara_son_geri()
		queue_redraw()
		return
	if mod != EditorMod.KIVIR:
		return
	var hit := _en_yakin_ara_nokta(mouse_dunya)
	if hit.is_empty():
		return
	var yi: int = hit["yol_idx"]
	var ai: int = hit["ara_idx"]
	var ara_arr: Array = yollar[yi]["ara"]
	var konum: Vector2 = ara_arr[ai]
	ara_arr.remove_at(ai)
	_islem_gecmisi.append({"tip": "ara_sil", "yol_idx": yi, "ara_idx": ai, "konum": konum})
	queue_redraw()


func _ara_nokta_surukle(mouse_dunya: Vector2) -> void:
	if _surukleme_ara.is_empty():
		return
	var yi: int = _surukleme_ara["yol_idx"]
	var ai: int = _surukleme_ara["ara_idx"]
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var logical := IsoProjection.iso_to_logical(mouse_dunya - off)
	var ara_arr: Array = yollar[yi]["ara"]
	ara_arr[ai] = logical


func _id_index_from_string(id: String) -> int:
	if id.is_empty():
		return -1
	if id.length() == 1:
		return id.unicode_at(0) - 65
	if id.length() == 2:
		var ana := id.unicode_at(0) - 65
		var alt := id.unicode_at(1) - 65
		return (ana + 1) * 26 + alt
	return -1


func _sonraki_nokta_indexini_guncelle() -> void:
	var max_idx := -1
	for nokta in noktalar:
		var idx := _id_index_from_string(str(nokta.get("id", "")))
		if idx > max_idx:
			max_idx = idx
	_sonraki_nokta_index = max_idx + 1


func _editor_durumunu_temizle() -> void:
	noktalar.clear()
	yollar.clear()
	_islem_gecmisi.clear()
	_yol_cizim_iptal()
	_surukleme_ara = {}
	_sonraki_nokta_index = 0


func _id_uret(index: int) -> String:
	if index < 26:
		return char(65 + index)
	var ana := int(index / 26) - 1
	var alt := index % 26
	return char(65 + ana) + char(65 + alt)


func _nokta_puan_degeri(id: String) -> int:
	return 3 if id == "C" else 1


func _nokta_altin_degeri(id: String) -> int:
	return 6 if id == "C" else 3


func _yol_patika_points(yol: Dictionary) -> Array:
	var a_nokta := _nokta_id_ile_bul(str(yol.get("a", "")))
	var b_nokta := _nokta_id_ile_bul(str(yol.get("b", "")))
	if a_nokta.is_empty() or b_nokta.is_empty():
		return []
	var pts: Array = []
	var a_konum: Vector2 = a_nokta["konum"]
	pts.append([int(round(a_konum.x)), int(round(a_konum.y))])
	var ara_raw: Variant = yol.get("ara", [])
	if typeof(ara_raw) == TYPE_ARRAY:
		for v in ara_raw as Array:
			if v is Vector2:
				pts.append([int(round(v.x)), int(round(v.y))])
	var b_konum: Vector2 = b_nokta["konum"]
	pts.append([int(round(b_konum.x)), int(round(b_konum.y))])
	return pts


func _nokta_konumdan_en_yakin_id(konum: Vector2, tolerans: float) -> String:
	var en_yakin := ""
	var min_d := INF
	for nokta in noktalar:
		var k: Vector2 = nokta["konum"]
		var d := k.distance_to(konum)
		if d < min_d:
			min_d = d
			en_yakin = str(nokta.get("id", ""))
	if min_d <= tolerans:
		return en_yakin
	return ""


func _nokta_id_konumdan_bul(konum: Vector2, tolerans: float = 1.5) -> String:
	return _nokta_konumdan_en_yakin_id(konum, tolerans)


func _patika_to_yol(patika: Dictionary) -> Dictionary:
	var ham_pts: Variant = patika.get("points", [])
	if typeof(ham_pts) != TYPE_ARRAY or (ham_pts as Array).size() < 2:
		return {}
	var points: Array = ham_pts
	var ilk: Array = points[0]
	var son: Array = points[points.size() - 1]
	if ilk.size() < 2 or son.size() < 2:
		return {}
	var a_id := _nokta_konumdan_en_yakin_id(Vector2(float(ilk[0]), float(ilk[1])), PATIKA_NOKTA_ESIK)
	var b_id := _nokta_konumdan_en_yakin_id(Vector2(float(son[0]), float(son[1])), PATIKA_NOKTA_ESIK)
	if a_id == "" or b_id == "" or a_id == b_id:
		return {}
	var ara_list: Array = []
	for i in range(1, points.size() - 1):
		var pt: Array = points[i]
		if pt.size() >= 2:
			ara_list.append(Vector2(float(pt[0]), float(pt[1])))
	return {"a": a_id, "b": b_id, "ara": ara_list}


func _kaydet_editor_cikti() -> void:
	var c_var := false
	for nokta in noktalar:
		if str(nokta.get("id", "")) == "C":
			c_var = true
			break
	if not c_var:
		_durum_mesaji = "HATA: Haritada 'C' noktasi yok. Oyun cokebilir. Bir noktayi C yapin."
		_durum_sure = 4.0
		queue_redraw()
		return

	var json_noktalar: Dictionary = {}
	var json_puan: Dictionary = {}
	var json_altin: Dictionary = {}
	for nokta in noktalar:
		var id := str(nokta.get("id", ""))
		if id == "":
			continue
		var konum: Vector2 = nokta["konum"]
		json_noktalar[id] = [int(round(konum.x)), int(round(konum.y))]
		json_puan[id] = _nokta_puan_degeri(id)
		json_altin[id] = _nokta_altin_degeri(id)

	var patikalar: Array = []
	for yol in yollar:
		var pts := _yol_patika_points(yol)
		if pts.size() < 2:
			continue
		patikalar.append({"tip": "ana", "points": pts})

	var json_data := {
		"id": "editor_cikti",
		"isim": "Editor Haritasi",
		"sinir": {
			"min_x": int(HARITA_SINIR["min_x"]),
			"max_x": int(HARITA_SINIR["max_x"]),
			"min_y": int(HARITA_SINIR["min_y"]),
			"max_y": int(HARITA_SINIR["max_y"]),
		},
		"noktalar": json_noktalar,
		"nokta_puan": json_puan,
		"nokta_altin": json_altin,
		"patikalar": patikalar,
		"araziler": [],
		"yollar": [],
		"nehir_hatlari": [],
		"gorsel_lekeler": [],
		"dere_yataklari": [],
		"cevre_dekor": [],
		"bolge_etiketleri": [],
	}

	var klasor := "res://data/maps"
	var klasor_abs := ProjectSettings.globalize_path(klasor)
	DirAccess.make_dir_recursive_absolute(klasor_abs)
	var hedef_yol := CIKTI_DOSYA
	var dosya := FileAccess.open(hedef_yol, FileAccess.WRITE)
	if dosya == null:
		var err := FileAccess.get_open_error()
		push_error("Kaydetme basarisiz: %s (err=%d)" % [hedef_yol, err])
		_durum_mesaji = "Kaydetme basarisiz (err=%d)" % err
		_durum_sure = 2.5
		queue_redraw()
		return
	dosya.store_string(JSON.stringify(json_data, "\t"))
	dosya.close()
	print("Kaydedildi: editor_cikti.json (oyun formati)")
	_durum_mesaji = "Kaydedildi: editor_cikti.json (oyun formati)"
	_durum_sure = 3.0
	queue_redraw()


func _yukle_editor_cikti(sessiz: bool = false) -> void:
	if not FileAccess.file_exists(CIKTI_DOSYA):
		if not sessiz:
			_durum_mesaji = "Yuklenecek harita yok"
			_durum_sure = 2.0
		return
	var dosya := FileAccess.open(CIKTI_DOSYA, FileAccess.READ)
	if dosya == null:
		if not sessiz:
			_durum_mesaji = "Kayit acilamadi"
			_durum_sure = 2.0
		return
	var metin := dosya.get_as_text()
	dosya.close()
	var json := JSON.new()
	var err := json.parse(metin)
	if err != OK:
		_durum_mesaji = "JSON parse hatasi"
		_durum_sure = 2.0
		return
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		_durum_mesaji = "Gecersiz kayit formati"
		_durum_sure = 2.0
		return
	var kayit: Dictionary = data
	_editor_durumunu_temizle()
	var yeni_noktalar: Array[Dictionary] = []
	var ham_noktalar: Variant = kayit.get("noktalar", {})
	if typeof(ham_noktalar) == TYPE_DICTIONARY:
		var nokta_sozluk: Dictionary = ham_noktalar
		for id_key in nokta_sozluk:
			var id_str: String = str(id_key)
			var ham: Variant = nokta_sozluk[id_key]
			if typeof(ham) == TYPE_ARRAY and (ham as Array).size() >= 2:
				var arr: Array = ham
				var x: float = float(arr[0])
				var y: float = float(arr[1])
				yeni_noktalar.append({"tip": "nokta", "konum": Vector2(x, y), "id": id_str})
	noktalar = yeni_noktalar
	_sonraki_nokta_indexini_guncelle()
	var yeni_yollar: Array[Dictionary] = []
	var ham_patikalar: Variant = kayit.get("patikalar", [])
	if typeof(ham_patikalar) == TYPE_ARRAY and (ham_patikalar as Array).size() > 0:
		for pi in range((ham_patikalar as Array).size()):
			var p = (ham_patikalar as Array)[pi]
			if typeof(p) != TYPE_DICTIONARY:
				continue
			var yol_dict := _patika_to_yol(p)
			if yol_dict.is_empty():
				print("patika eslestirilemedi (index %d)" % pi)
				continue
			var ya := str(yol_dict.get("a", ""))
			var yb := str(yol_dict.get("b", ""))
			if _yol_listesinde_var(yeni_yollar, ya, yb):
				continue
			yeni_yollar.append(yol_dict)
	else:
		var ham_yollar: Variant = kayit.get("yollar_basit", [])
		if typeof(ham_yollar) == TYPE_ARRAY:
			for y in ham_yollar as Array:
				if typeof(y) != TYPE_DICTIONARY:
					continue
				var yol: Dictionary = y
				var a := str(yol.get("a", ""))
				var b := str(yol.get("b", ""))
				if a == "" or b == "" or a == b:
					continue
				if _yol_listesinde_var(yeni_yollar, a, b):
					continue
				var ara_list: Array = []
				var ham_ara: Variant = yol.get("ara", [])
				if typeof(ham_ara) == TYPE_ARRAY:
					for pt in ham_ara as Array:
						if typeof(pt) == TYPE_ARRAY and (pt as Array).size() >= 2:
							var parr: Array = pt
							ara_list.append(Vector2(float(parr[0]), float(parr[1])))
				yeni_yollar.append({"a": a, "b": b, "ara": ara_list})
	yollar = yeni_yollar
	print("Yuklendi: %s (%d nokta, %d yol)" % [CIKTI_DOSYA, noktalar.size(), yollar.size()])
	_durum_mesaji = "Yuklendi: %d nokta, %d yol" % [noktalar.size(), yollar.size()]
	_durum_sure = 3.0
	queue_redraw()


func _yol_listesinde_var(liste: Array[Dictionary], a: String, b: String) -> bool:
	for yol in liste:
		var ya := str(yol.get("a", ""))
		var yb := str(yol.get("b", ""))
		if (ya == a and yb == b) or (ya == b and yb == a):
			return true
	return false


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
	elif tip == "ara_ekle":
		var yi: int = son["yol_idx"]
		var ai: int = son["ara_idx"]
		(yollar[yi]["ara"] as Array).remove_at(ai)
	elif tip == "ara_sil":
		var yi_s: int = son["yol_idx"]
		var ai_s: int = son["ara_idx"]
		var konum: Vector2 = son["konum"]
		(yollar[yi_s]["ara"] as Array).insert(ai_s, konum)
	elif tip == "ara_tasi":
		var yi_t: int = son["yol_idx"]
		var ai_t: int = son["ara_idx"]
		var eski: Vector2 = son["eski_konum"]
		(yollar[yi_t]["ara"] as Array)[ai_t] = eski
	_secili_yol_kaynak_id = ""
	_yol_cizim_ara.clear()
	_surukleme_ara = {}
	queue_redraw()


func _tumunu_temizle() -> void:
	_editor_durumunu_temizle()
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
		EditorMod.KIVIR:
			return "KIVIR"
	return "?"
