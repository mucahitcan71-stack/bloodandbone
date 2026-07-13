extends Node2D

const IsoProjection = preload("res://scripts/iso_projection.gd")
const PathSpline = preload("res://scripts/path_spline.gd")
const PropKatalog = preload("res://scripts/prop_katalog.gd")
const _YOL_SPLINE_ADIM := 10

const HARITA_SINIR := {"min_x": 0.0, "max_x": 15000.0, "min_y": 0.0, "max_y": 9000.0}
const KAMERA_HIZ := 900.0
const ZOOM_ADIM := 0.1
const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.5
const SECIM_YARICAP := 22.0
const YOL_SEG_ESIK := 50.0
const YOL_UZER_ESIK := 28.0
const PATIKA_NOKTA_ESIK := 30.0
const PROP_SILME_ESIK := 150.0
const PROP_SECIM_ESIK := 90.0
const PROP_OLCEK_MIN := 0.5
const PROP_OLCEK_MAX := 80.0
const FIRCA_YARICAP_MIN := 40.0
const FIRCA_YARICAP_MAX := 480.0
const FIRCA_YARICAP_BASLANGIC := 100.0
const FIRCA_MIN_MESAFE := 36.0
const FIRCA_SURUKLEME_ADIM := 20.0
const FIRCA_YOGUNLUK_MIN := 0.3
const FIRCA_YOGUNLUK_MAX := 3.0
const FIRCA_YOGUNLUK_BASLANGIC := 2.0
const FIRCA_SERPISTIRME_TABAN := 10
const CIKTI_DOSYA := "res://data/maps/editor_cikti.json"
const _ACILISTA_YUKLE := true
const ARAZI_KAPANIS_ESIK := 18.0
const ARAZI_TIPLERI := [
	{"id": "gizlenme", "isim": "Gizlenme (Orman)", "renk": Color(0.1, 0.4, 0.1, 0.35)},
]
const _ARAZI_TIP_RENK_ESKI := {
	"tepe": Color(0.5, 0.35, 0.2, 0.35),
	"vadi": Color(0.3, 0.5, 0.6, 0.35),
}
const YUK_GRID_W := 256
const YUK_FIRCA_YARICAP_MIN := 100.0
const YUK_FIRCA_YARICAP_MAX := 1500.0
const YUK_FIRCA_YARICAP_BAS := 400.0
const YUK_FIRCA_GUCU_MIN := 0.25
const YUK_FIRCA_GUCU_MAX := 4.0
const YUK_FIRCA_GUCU_BAS := 0.5
const YUK_FIRCA_SURUKLEME_ADIM := 28.0
const YUK_YUKSELT_ORAN := 8.0
const YUK_OVERLAY_ALPHA := 0.48

enum EditorMod { US, NOKTA, YOL, KIVIR, PROP, ARAZI, YUKSEKLIK }
enum PropAltMod { YERLESTIR, DUZENLE }
enum YukFirca { YUKSELT, ALCALT, YUMUSAT, DUZLE }

var mod: EditorMod = EditorMod.NOKTA
var noktalar: Array[Dictionary] = []
var yollar: Array[Dictionary] = []
var proplar: Array[Dictionary] = []
var arazi_bolgeleri: Array[Dictionary] = []
var _arazi_aktif_koseler: Array = []
var _secili_arazi_tip_idx := 0
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
var _sonraki_kavsak_index := 0
var _yol_cizim_olusturulan_kavsaklar: Array[String] = []
var _secili_yol_tipi := "ana"
var _secili_prop_id := ""
var _prop_alt_mod := PropAltMod.YERLESTIR
var _secili_prop_idx := -1
var _prop_duzenle_surukleme := false
var _firca_yaricap := FIRCA_YARICAP_BASLANGIC
var _firca_yogunluk := FIRCA_YOGUNLUK_BASLANGIC
var _prop_gizli := false
var _prop_sol_basili := false
var _son_firca_surukleme := Vector2.ZERO
var _prop_paleti: PanelContainer
var _prop_kategori_sekmeleri: HBoxContainer
var _prop_palet_icerik: VBoxContainer
var _prop_aktif_kategori := "agac"
var _prop_butonlar: Dictionary = {}
var _prop_kat_butonlar: Dictionary = {}
var _yuk_grid_w := YUK_GRID_W
var _yuk_grid_h := 1
var _yuk_veri: PackedFloat32Array = PackedFloat32Array()
var _yuk_firca: YukFirca = YukFirca.YUKSELT
var _yuk_firca_yaricap := YUK_FIRCA_YARICAP_BAS
var _yuk_firca_gucu := YUK_FIRCA_GUCU_BAS
var _yuk_sol_basili := false
var _yuk_duzle_hedef := 0.0
var _yuk_duzle_hazir := false
var _yuk_overlay_acik := true
var _yuk_overlay_dirty := true
var _yuk_overlay_img: Image = null
var _yuk_overlay_tex: ImageTexture = null
var _son_yuk_firca_surukleme := Vector2.ZERO


func _ready() -> void:
	_kamera = $Camera2D
	_prop_paleti = $EditorUI/PropPaleti
	_prop_kategori_sekmeleri = $EditorUI/PropPaleti/RootVBox/KategoriScroll/KategoriSekmeler
	_prop_palet_icerik = $EditorUI/PropPaleti/RootVBox/Scroll/Icerik
	_secili_prop_id = PropKatalog.varsayilan_id()
	_prop_paleti_gorsel_kur()
	_prop_kategori_sekmeleri_kur()
	_prop_paletini_kur()
	_prop_paleti.visible = false
	_kamera.position = _harita_merkez_logical()
	_kamera.zoom = Vector2.ONE
	_yuk_grid_sifirla()
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
		var mm := event as InputEventMouseMotion
		if mod == EditorMod.YUKSEKLIK and _yuk_sol_basili:
			_yuk_firca_surukle(get_global_mouse_position())
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR and _prop_sol_basili and not _prop_ui_uzerinde_mi(get_global_mouse_position()):
			_prop_firca_surukle(get_global_mouse_position())
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE and _prop_duzenle_surukleme and _secili_prop_idx >= 0:
			_prop_duzenle_tasi(get_global_mouse_position())
			queue_redraw()
		if not _surukleme_ara.is_empty():
			_ara_nokta_surukle(get_global_mouse_position())
			queue_redraw()
		elif mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			queue_redraw()
		elif mod == EditorMod.ARAZI and not _arazi_aktif_koseler.is_empty():
			queue_redraw()
		elif mod == EditorMod.YUKSEKLIK:
			queue_redraw()
		if _orta_tik_surukleme:
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
	if _yuk_overlay_acik:
		_yuk_overlay_guncelle()
		if _yuk_overlay_tex != null:
			var uvs := PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)
			])
			var cols := PackedColorArray([
				Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1)
			])
			draw_polygon(koseler, cols, uvs, _yuk_overlay_tex)

	var font := ThemeDB.fallback_font
	var fs := ThemeDB.fallback_font_size
	_ciz_arazi_bolgeleri(off)

	for yol in yollar:
		var iso_pts := _yol_iso_polyline(yol, off)
		if iso_pts.size() >= 2:
			_ciz_editor_yol(iso_pts, str(yol.get("tip", "ana")))
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
		var renk: Color
		var yaricap: float
		match tip:
			"us":
				renk = Color(0.3, 0.55, 0.9, 0.95)
				yaricap = 8.0
			"kavsak":
				renk = Color(0.15, 0.82, 0.82, 0.98)
				yaricap = 5.5
			_:
				renk = Color(0.75, 0.75, 0.75, 0.95)
				yaricap = 8.0
		draw_circle(iso, yaricap, renk)
		var id := str(nokta.get("id", ""))
		if id == _secili_yol_kaynak_id:
			draw_arc(iso, 14.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.25, 0.95), 2.0)
		var etiket := "%s (%d, %d)" % [id, int(round(logical.x)), int(round(logical.y))]
		draw_string(font, iso + Vector2(10, -8), etiket, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1, 1, 1, 0.95))

	if not _prop_gizli:
		for pidx in _prop_sirali_indeksleri():
			_ciz_prop_isaret(proplar[pidx], pidx, off, font, fs)

	if mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR:
		var fare_iso := get_global_mouse_position()
		if not _prop_ui_uzerinde_mi(fare_iso):
			var fare_logical := IsoProjection.iso_to_logical(fare_iso - off)
			var firca_iso := IsoProjection.logical_to_iso(fare_logical) + off
			var firca_yaricap_iso := _firca_yaricap * 0.5
			draw_arc(firca_iso, firca_yaricap_iso, 0.0, TAU, 32, Color(0.2, 0.75, 0.35, 0.55), 1.5)

	if mod == EditorMod.YUKSEKLIK:
		# Fare altında lojik firca alanini (yaklasik iso yaricap) goster.
		var yfirca_iso := get_global_mouse_position()
		var yfirca_r := maxf(_yuk_firca_yaricap * 0.5, 8.0)
		draw_arc(yfirca_iso, yfirca_r, 0.0, TAU, 56, Color(0.05, 0.05, 0.02, 0.75), 3.2)
		draw_arc(yfirca_iso, yfirca_r, 0.0, TAU, 56, Color(0.98, 0.88, 0.28, 0.95), 2.0)

	if mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
		var bas_n := _nokta_id_ile_bul(_secili_yol_kaynak_id)
		if not bas_n.is_empty():
			var ctrl: Array = [bas_n["konum"]]
			for v in _yol_cizim_ara:
				if v is Vector2:
					ctrl.append(v)
					draw_circle(IsoProjection.logical_to_iso(v) + off, 4.0, Color(1.0, 0.65, 0.15, 0.85))
			var fare_logical := IsoProjection.iso_to_logical(get_global_mouse_position() - off)
			ctrl.append(fare_logical)
			var onizleme := _logical_to_iso_polyline(PathSpline.yumusat_catmull(ctrl, _YOL_SPLINE_ADIM), off)
			if onizleme.size() >= 2:
				_ciz_editor_yol(onizleme, _secili_yol_tipi)

	if mod == EditorMod.ARAZI:
		_ciz_arazi_aktif(off)

	var mod_yazi := "MOD: %s" % _mod_adi()
	if mod == EditorMod.YUKSEKLIK:
		mod_yazi = "MOD: YUKSEKLIK - firca: %s" % _yuk_firca_adi()
	elif mod == EditorMod.ARAZI:
		mod_yazi = "MOD: ARAZI - tip: %s" % _arazi_tip_isim(_secili_arazi_tip_idx)
	elif mod == EditorMod.PROP:
		if _prop_alt_mod == PropAltMod.DUZENLE:
			mod_yazi = "MOD: PROP - DUZENLE"
			if _secili_prop_idx >= 0 and _secili_prop_idx < proplar.size():
				var sp: Dictionary = proplar[_secili_prop_idx]
				mod_yazi = "MOD: PROP - DUZENLE | %s | olcek %.2f | rot %.0f" % [
					PropKatalog.isim(str(sp.get("id", ""))),
					float(sp.get("olcek", 8.0)),
					float(sp.get("rot", 0.0)),
				]
		else:
			mod_yazi = "MOD: PROP - YERLESTIR | %s (%s)" % [
				PropKatalog.isim(_secili_prop_id),
				PropKatalog.KATEGORI_SEKME.get(PropKatalog.kategori(_secili_prop_id), ""),
			]
	draw_string(font, Vector2(18, 26), mod_yazi, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs + 2, Color(1, 0.95, 0.7, 1))
	draw_string(font, Vector2(18, 48), "Kaydet: P | Yukle: L | Arazi: A | Yukseklik: H | Overlay: G", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.85, 0.9, 0.75, 1.0))
	draw_string(
		font,
		Vector2(18, 70),
		"YOL TIPI: %s (3=ana 4=patika 5=gizli)" % _yol_tip_etiketi(_secili_yol_tipi),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		fs,
		Color(0.95, 0.88, 0.55, 1.0)
	)
	var durum_y := 92.0
	if mod == EditorMod.YOL:
		draw_string(
			font,
			Vector2(18, 92),
			"Baslangic/bitis: nokta VEYA yol uzeri (kavsak) | Ara: serbest | Sag/Backspace geri | Esc iptal",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.9, 0.85, 0.65, 1.0)
		)
		durum_y = 114.0
	elif mod == EditorMod.KIVIR:
		draw_string(
			font,
			Vector2(18, 92),
			"Yola tikla=ara nokta, surukle=tasi, sag tik=sil",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.9, 0.85, 0.65, 1.0)
		)
		durum_y = 114.0
	elif mod == EditorMod.ARAZI:
		draw_string(
			font,
			Vector2(18, 92),
			"Sol tik=kose (sadece gizlenme) | Space/Enter/ilk koseye tik=kapat | Sag=geri | Esc=iptal",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.75, 0.95, 0.7, 1.0)
		)
		durum_y = 114.0
	elif mod == EditorMod.YUKSEKLIK:
		draw_string(
			font,
			Vector2(18, 92),
			"1 YUKSELT 2 ALCALT 3 YUMUSAT 4 DUZLE | Firca: %.0f ([/]) | Guc: x%.2f (,/.) | G overlay" % [
				_yuk_firca_yaricap, _yuk_firca_gucu
			],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.95, 0.9, 0.55, 1.0)
		)
		durum_y = 114.0
	elif mod == EditorMod.PROP:
		if _prop_alt_mod == PropAltMod.DUZENLE:
			draw_string(
				font,
				Vector2(18, 92),
				"Sol tik sec/surukle | +/- olcek | [/] rot | Del/sag sil | Esc birak | T yerlestir",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				fs,
				Color(0.85, 0.9, 0.75, 1.0)
			)
		else:
			draw_string(
				font,
				Vector2(18, 92),
				"Sol tik/surukle | sag sil | Firca: %.0f ([/]) | Yogunluk: x%.1f (,/.) | E duzenle | Shift+H gizle" % [_firca_yaricap, _firca_yogunluk],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				fs,
				Color(0.75, 0.95, 0.7, 1.0)
			)
		durum_y = 114.0
	elif _prop_gizli:
		draw_string(
			font,
			Vector2(18, 92),
			"Prop isaretleri GIZLI (Shift+H ile goster) | %d prop" % proplar.size(),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			fs,
			Color(0.75, 0.8, 0.7, 1.0)
		)
		durum_y = 114.0
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
	if mod == EditorMod.YUKSEKLIK and _tus_mu(ev, KEY_1):
		_yuk_firca = YukFirca.YUKSELT
		queue_redraw()
		return
	if mod == EditorMod.YUKSEKLIK and _tus_mu(ev, KEY_2):
		_yuk_firca = YukFirca.ALCALT
		queue_redraw()
		return
	if mod == EditorMod.YUKSEKLIK and _tus_mu(ev, KEY_3):
		_yuk_firca = YukFirca.YUMUSAT
		queue_redraw()
		return
	if mod == EditorMod.YUKSEKLIK and _tus_mu(ev, KEY_4):
		_yuk_firca = YukFirca.DUZLE
		queue_redraw()
		return
	if _tus_mu(ev, KEY_1):
		mod = EditorMod.US
		_prop_paleti_kapat()
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		queue_redraw()
	elif _tus_mu(ev, KEY_2):
		mod = EditorMod.NOKTA
		_prop_paleti_kapat()
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		queue_redraw()
	elif _tus_mu(ev, KEY_3):
			_secili_yol_tipi = "ana"
			queue_redraw()
	elif _tus_mu(ev, KEY_4):
			_secili_yol_tipi = "patika"
			queue_redraw()
	elif _tus_mu(ev, KEY_5):
			_secili_yol_tipi = "gizli"
			queue_redraw()
	elif _tus_mu(ev, KEY_6) and mod == EditorMod.ARAZI:
		_secili_arazi_tip_idx = 0
		queue_redraw()
	elif _tus_mu(ev, KEY_A) and not (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT)):
		# Not: A basili tutulursa WASD pan da sola kayar; kisa basis = arazi modu.
		mod = EditorMod.ARAZI
		_secili_arazi_tip_idx = 0
		_prop_paleti_kapat()
		_yol_cizim_iptal()
		_yuk_boya_bitir()
		_surukleme_ara = {}
		queue_redraw()
	elif _tus_mu(ev, KEY_Y):
		mod = EditorMod.YOL
		_prop_paleti_kapat()
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		queue_redraw()
	elif _tus_mu(ev, KEY_K):
		mod = EditorMod.KIVIR
		_prop_paleti_kapat()
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		_surukleme_ara = {}
		queue_redraw()
	elif _tus_mu(ev, KEY_T):
		mod = EditorMod.PROP
		_prop_alt_mod = PropAltMod.YERLESTIR
		_secili_prop_idx = -1
		_prop_duzenle_surukleme = false
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		_surukleme_ara = {}
		_prop_paleti_ac()
		queue_redraw()
	elif _tus_mu(ev, KEY_E):
		mod = EditorMod.PROP
		_prop_alt_mod = PropAltMod.DUZENLE
		_prop_sol_basili = false
		_prop_duzenle_surukleme = false
		_yol_cizim_iptal()
		_arazi_cizim_iptal()
		_yuk_boya_bitir()
		_surukleme_ara = {}
		_prop_paleti_kapat()
		queue_redraw()
	elif _tus_mu(ev, KEY_BRACKETLEFT):
		if mod == EditorMod.YUKSEKLIK:
			_yuk_firca_yaricap = clampf(_yuk_firca_yaricap - 80.0, YUK_FIRCA_YARICAP_MIN, YUK_FIRCA_YARICAP_MAX)
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE and _secili_prop_idx >= 0:
			_prop_rotasyon_ayarla(-8.0)
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR:
			_firca_yaricap = clampf(_firca_yaricap - 20.0, FIRCA_YARICAP_MIN, FIRCA_YARICAP_MAX)
			queue_redraw()
	elif _tus_mu(ev, KEY_BRACKETRIGHT):
		if mod == EditorMod.YUKSEKLIK:
			_yuk_firca_yaricap = clampf(_yuk_firca_yaricap + 80.0, YUK_FIRCA_YARICAP_MIN, YUK_FIRCA_YARICAP_MAX)
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE and _secili_prop_idx >= 0:
			_prop_rotasyon_ayarla(8.0)
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR:
			_firca_yaricap = clampf(_firca_yaricap + 20.0, FIRCA_YARICAP_MIN, FIRCA_YARICAP_MAX)
			queue_redraw()
	elif _tus_mu(ev, KEY_COMMA):
		if mod == EditorMod.YUKSEKLIK:
			_yuk_firca_gucu = clampf(_yuk_firca_gucu - 0.15, YUK_FIRCA_GUCU_MIN, YUK_FIRCA_GUCU_MAX)
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR:
			_firca_yogunluk = clampf(_firca_yogunluk - 0.15, FIRCA_YOGUNLUK_MIN, FIRCA_YOGUNLUK_MAX)
			queue_redraw()
	elif _tus_mu(ev, KEY_PERIOD):
		if mod == EditorMod.YUKSEKLIK:
			_yuk_firca_gucu = clampf(_yuk_firca_gucu + 0.15, YUK_FIRCA_GUCU_MIN, YUK_FIRCA_GUCU_MAX)
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR:
			_firca_yogunluk = clampf(_firca_yogunluk + 0.15, FIRCA_YOGUNLUK_MIN, FIRCA_YOGUNLUK_MAX)
			queue_redraw()
	elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE and _secili_prop_idx >= 0:
		if _tus_mu(ev, KEY_EQUAL) or _tus_mu(ev, KEY_PLUS) or _tus_mu(ev, KEY_KP_ADD):
			_prop_olcek_ayarla(1.1)
		elif _tus_mu(ev, KEY_MINUS) or _tus_mu(ev, KEY_KP_SUBTRACT):
			_prop_olcek_ayarla(0.9)
	elif _tus_mu(ev, KEY_G):
		_yuk_overlay_acik = not _yuk_overlay_acik
		_durum_mesaji = "Yukseklik overlay %s" % ("acik" if _yuk_overlay_acik else "kapali")
		_durum_sure = 1.5
		queue_redraw()
	elif _tus_mu(ev, KEY_H):
		if Input.is_key_pressed(KEY_SHIFT):
			_prop_gizli = not _prop_gizli
			_durum_mesaji = "Prop isaretleri %s" % ("gizlendi" if _prop_gizli else "gosteriliyor")
			_durum_sure = 1.8
			queue_redraw()
		else:
			mod = EditorMod.YUKSEKLIK
			_prop_paleti_kapat()
			_yol_cizim_iptal()
			_arazi_cizim_iptal()
			_surukleme_ara = {}
			_yuk_boya_bitir()
			queue_redraw()
	elif (_tus_mu(ev, KEY_SPACE) or _tus_mu(ev, KEY_ENTER) or _tus_mu(ev, KEY_KP_ENTER)) and mod == EditorMod.ARAZI:
		_arazi_poligonu_kapat()
	elif _tus_mu(ev, KEY_ESCAPE):
		if mod == EditorMod.ARAZI and not _arazi_aktif_koseler.is_empty():
			_arazi_cizim_iptal()
			_durum_mesaji = "Arazi cizimi iptal"
			_durum_sure = 1.5
			queue_redraw()
		elif mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE:
			_secili_prop_idx = -1
			_prop_duzenle_surukleme = false
			queue_redraw()
		elif mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			_yol_cizim_iptal()
			_durum_mesaji = "Yol cizimi iptal"
			_durum_sure = 1.5
			queue_redraw()
	elif _tus_mu(ev, KEY_BACKSPACE) and mod == EditorMod.ARAZI and not _arazi_aktif_koseler.is_empty():
		_arazi_kose_geri()
		queue_redraw()
	elif _tus_mu(ev, KEY_BACKSPACE) and mod == EditorMod.YOL and _secili_yol_kaynak_id != "":
			_yol_cizim_ara_son_geri()
			queue_redraw()
	elif _tus_mu(ev, KEY_Z):
		_geri_al()
	elif _tus_mu(ev, KEY_DELETE):
		if mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.DUZENLE and _secili_prop_idx >= 0:
			_prop_secili_sil()
	elif _tus_mu(ev, KEY_C):
		_tumunu_temizle()
	elif _tus_mu(ev, KEY_L):
		_yukle_editor_cikti(false)
		queue_redraw()


func _tus_mu(ev: InputEventKey, code: Key) -> bool:
	return ev.keycode == code or ev.physical_keycode == code


func _handle_left_click(mouse_dunya: Vector2) -> void:
	if mod == EditorMod.YUKSEKLIK:
		_yuk_sol_basili = true
		var ylogical := _mouse_to_logical(mouse_dunya)
		if not _harita_icinde_mi(ylogical):
			return
		if _yuk_firca == YukFirca.DUZLE:
			_yuk_duzle_hedef = _yuk_ornekle(ylogical.x, ylogical.y)
			_yuk_duzle_hazir = true
		_son_yuk_firca_surukleme = ylogical
		_yuk_firca_uygula(ylogical)
		queue_redraw()
		return
	if mod == EditorMod.PROP:
		if _prop_ui_uzerinde_mi(mouse_dunya):
			return
		if _prop_alt_mod == PropAltMod.DUZENLE:
			var idx := _prop_sec_idx(mouse_dunya)
			if idx >= 0:
				_secili_prop_idx = idx
				_prop_duzenle_surukleme = true
			else:
				_secili_prop_idx = -1
			queue_redraw()
			return
		_prop_sol_basili = true
		var logical := _mouse_to_logical(mouse_dunya)
		if not _harita_icinde_mi(logical):
			return
		_prop_ekle(logical, _secili_prop_id)
		_son_firca_surukleme = logical
		queue_redraw()
		return
	if mod == EditorMod.YOL:
		_yol_modu_tikla(mouse_dunya)
		return
	if mod == EditorMod.KIVIR:
		_kivir_modu_tikla(mouse_dunya)
		return
	if mod == EditorMod.ARAZI:
		_arazi_modu_tikla(mouse_dunya)
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
	for kid in _yol_cizim_olusturulan_kavsaklar:
		_nokta_sil_id(kid)
	_yol_cizim_olusturulan_kavsaklar.clear()
	_secili_yol_kaynak_id = ""
	_yol_cizim_ara.clear()


func _yol_cizim_ara_son_geri() -> void:
	if not _yol_cizim_ara.is_empty():
		_yol_cizim_ara.pop_back()


func _yol_modu_tikla(mouse_dunya: Vector2) -> void:
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var logical := IsoProjection.iso_to_logical(mouse_dunya - off)

	if _secili_yol_kaynak_id == "":
		var bas_uc := _yol_ucu_coz(mouse_dunya)
		if bas_uc.is_empty():
			_durum_mesaji = "Yol bir noktadan veya yoldan baslamali"
			_durum_sure = 2.0
			queue_redraw()
			return
		_secili_yol_kaynak_id = str(bas_uc.get("id", ""))
		if bas_uc.get("olusturuldu", false):
			_yol_cizim_olusturulan_kavsaklar.append(_secili_yol_kaynak_id)
		_yol_cizim_ara.clear()
		queue_redraw()
		return

	var bitis_uc := _yol_ucu_coz(mouse_dunya)
	if not bitis_uc.is_empty():
		var bitis_id := str(bitis_uc.get("id", ""))
		if bitis_id == _secili_yol_kaynak_id:
			return
		if _yol_var_mi(_secili_yol_kaynak_id, bitis_id):
			_durum_mesaji = "Bu yol zaten var"
			_durum_sure = 2.0
			queue_redraw()
			return
		if bitis_uc.get("olusturuldu", false):
			_yol_cizim_olusturulan_kavsaklar.append(bitis_id)
		var ara_kopya: Array = []
		for v in _yol_cizim_ara:
			if v is Vector2:
				ara_kopya.append(v)
		var yol := {"a": _secili_yol_kaynak_id, "b": bitis_id, "ara": ara_kopya, "tip": _secili_yol_tipi}
		yollar.append(yol)
		var kavsak_kayit: Array = []
		for kid in _yol_cizim_olusturulan_kavsaklar:
			kavsak_kayit.append(kid)
		_islem_gecmisi.append({
			"tip": "yol",
			"a": _secili_yol_kaynak_id,
			"b": bitis_id,
			"kavsaklar": kavsak_kayit,
		})
		_yol_cizim_olusturulan_kavsaklar.clear()
		_secili_yol_kaynak_id = ""
		_yol_cizim_ara.clear()
		queue_redraw()
		return

	_yol_cizim_ara.append(logical)
	queue_redraw()


func _yol_ucu_coz(mouse_dunya: Vector2) -> Dictionary:
	var hedef_nokta := _ekrana_en_yakin_nokta(mouse_dunya)
	if not hedef_nokta.is_empty():
		return {"id": str(hedef_nokta.get("id", "")), "olusturuldu": false}
	var yol_hit := _en_yakin_yol_uzeri(mouse_dunya)
	if yol_hit.is_empty():
		return {}
	var konum: Vector2 = yol_hit["konum"]
	var kid := _kavsak_olustur(konum)
	return {"id": kid, "olusturuldu": true}


func _kavsak_olustur(konum: Vector2) -> String:
	_sonraki_kavsak_index += 1
	var kid := "K%d" % _sonraki_kavsak_index
	noktalar.append({"tip": "kavsak", "konum": konum, "id": kid})
	return kid


func _nokta_sil_id(id: String) -> void:
	for i in range(noktalar.size() - 1, -1, -1):
		if str(noktalar[i].get("id", "")) == id:
			noktalar.remove_at(i)
			break


func _en_yakin_yol_uzeri(mouse_dunya: Vector2) -> Dictionary:
	var off := merkez_logical_iso_offseti(HARITA_SINIR)
	var min_d := INF
	var en_yakin_iso := Vector2.ZERO
	for yol in yollar:
		var iso_poly := _yol_iso_polyline(yol, off)
		if iso_poly.size() < 2:
			continue
		for i in range(iso_poly.size() - 1):
			var hit := _segment_en_yakin_nokta(mouse_dunya, iso_poly[i], iso_poly[i + 1])
			var d: float = hit["mesafe"]
			if d < min_d:
				min_d = d
				en_yakin_iso = hit["nokta"]
	if min_d > YOL_UZER_ESIK:
		return {}
	return {"konum": IsoProjection.iso_to_logical(en_yakin_iso - off)}


func _segment_en_yakin_nokta(p: Vector2, a: Vector2, b: Vector2) -> Dictionary:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return {"mesafe": p.distance_to(a), "nokta": a}
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var nokta := a + ab * t
	return {"mesafe": p.distance_to(nokta), "nokta": nokta}


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


func _logical_to_iso_polyline(logical_pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var iso_pts := PackedVector2Array()
	for p in logical_pts:
		iso_pts.append(IsoProjection.logical_to_iso(p) + off)
	return iso_pts


func _yol_iso_polyline(yol: Dictionary, off: Vector2) -> PackedVector2Array:
	var ctrl: Array = []
	for p in _yol_polyline_logical(yol):
		ctrl.append(p)
	return _logical_to_iso_polyline(PathSpline.yumusat_catmull(ctrl, _YOL_SPLINE_ADIM), off)


func _yol_tip_etiketi(tip: String) -> String:
	match tip:
		"patika":
			return "PATIKA"
		"gizli":
			return "GIZLI"
		_:
			return "ANA"


func _editor_yol_stili(tip: String) -> Dictionary:
	match tip:
		"patika":
			return {"width": 3.0, "color": Color(0.58, 0.48, 0.32, 0.88), "kesik": false}
		"gizli":
			return {"width": 2.5, "color": Color(0.45, 0.52, 0.38, 0.72), "kesik": true}
		_:
			return {"width": 6.0, "color": Color(0.66, 0.52, 0.3, 0.92), "kesik": false}


func _ciz_editor_yol(iso_pts: PackedVector2Array, tip: String) -> void:
	if iso_pts.size() < 2:
		return
	var stil := _editor_yol_stili(tip)
	if stil.kesik:
		_ciz_kesik_polyline(iso_pts, stil.color, stil.width)
	else:
		draw_polyline(iso_pts, stil.color, stil.width, true)


func _ciz_kesik_polyline(pts: PackedVector2Array, color: Color, width: float, dash := 12.0, gap := 8.0) -> void:
	for i in range(pts.size() - 1):
		_ciz_kesik_segment(pts[i], pts[i + 1], color, width, dash, gap)


func _ciz_kesik_segment(a: Vector2, b: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
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
			draw_line(a + yon * t, a + yon * t2, color, width, true)
		t = t2
		ciz = not ciz


func _editor_tip_to_oyun(tip: String) -> String:
	match tip:
		"patika":
			return "normal"
		"gizli":
			return "gizli"
		_:
			return "ana"


func _oyun_tip_to_editor(tip: String) -> String:
	match tip:
		"normal":
			return "patika"
		"gizli":
			return "gizli"
		_:
			return "ana"


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
	if mod == EditorMod.YUKSEKLIK:
		_yuk_boya_bitir()
		return
	if mod == EditorMod.PROP:
		if _prop_alt_mod == PropAltMod.DUZENLE:
			_prop_duzenle_surukleme = false
			return
		_prop_sol_basili = false
		return
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
	if mod == EditorMod.ARAZI:
		_arazi_kose_geri()
		queue_redraw()
		return
	if mod == EditorMod.PROP:
		if _prop_ui_uzerinde_mi(mouse_dunya):
			return
		if _prop_alt_mod == PropAltMod.DUZENLE:
			if _secili_prop_idx >= 0:
				_prop_secili_sil()
			return
		_prop_sil_yakin(mouse_dunya)
		return
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
	proplar.clear()
	arazi_bolgeleri.clear()
	_arazi_cizim_iptal()
	_islem_gecmisi.clear()
	_yol_cizim_iptal()
	_surukleme_ara = {}
	_sonraki_nokta_index = 0
	_sonraki_kavsak_index = 0
	_secili_prop_idx = -1
	_prop_duzenle_surukleme = false
	_yuk_grid_sifirla()
	_yuk_boya_bitir()


func _id_uret(index: int) -> String:
	if index < 26:
		return char(65 + index)
	var ana := int(index / 26) - 1
	var alt := index % 26
	return char(65 + ana) + char(65 + alt)


func _nokta_puan_degeri(id: String, nokta_tip: String = "") -> int:
	if nokta_tip == "kavsak":
		return 0
	return 3 if id == "C" else 1


func _nokta_altin_degeri(id: String, nokta_tip: String = "") -> int:
	if nokta_tip == "kavsak":
		return 0
	return 6 if id == "C" else 3


func _sonraki_kavsak_indexini_guncelle() -> void:
	var max_k := 0
	for nokta in noktalar:
		if str(nokta.get("tip", "")) != "kavsak":
			continue
		var id := str(nokta.get("id", ""))
		if id.begins_with("K") and id.length() > 1:
			var sayi_str := id.trim_prefix("K")
			if sayi_str.is_valid_int():
				var sayi := int(sayi_str)
				if sayi > max_k:
					max_k = sayi
	_sonraki_kavsak_index = max_k


func _kavsak_baska_yolda_kullaniliyor(kid: String) -> bool:
	for yol in yollar:
		if str(yol.get("a", "")) == kid or str(yol.get("b", "")) == kid:
			return true
	return false


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
	return {"a": a_id, "b": b_id, "ara": ara_list, "tip": _oyun_tip_to_editor(str(patika.get("tip", "ana")))}


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
	var json_usler: Array = []
	var json_kavsaklar: Dictionary = {}
	for nokta in noktalar:
		var id := str(nokta.get("id", ""))
		if id == "":
			continue
		var ntip := str(nokta.get("tip", "nokta"))
		var konum: Vector2 = nokta["konum"]
		if ntip == "kavsak":
			json_kavsaklar[id] = [int(round(konum.x)), int(round(konum.y))]
			continue
		json_noktalar[id] = [int(round(konum.x)), int(round(konum.y))]
		json_puan[id] = _nokta_puan_degeri(id, ntip)
		json_altin[id] = _nokta_altin_degeri(id, ntip)
		if ntip == "us":
			json_usler.append(id)

	var patikalar: Array = []
	for yol in yollar:
		var pts := _yol_patika_points(yol)
		if pts.size() < 2:
			continue
		patikalar.append({"tip": _editor_tip_to_oyun(str(yol.get("tip", "ana"))), "points": pts})

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
		"usler": json_usler,
		"kavsaklar": json_kavsaklar,
		"patikalar": patikalar,
		"araziler": [],
		"yollar": [],
		"nehir_hatlari": [],
		"gorsel_lekeler": [],
		"dere_yataklari": [],
		"cevre_dekor": [],
		"bolge_etiketleri": [],
		"proplar": _json_proplar_uret(),
		"arazi_bolgeleri": _json_arazi_bolgeleri_uret(),
		"yukseklik_haritasi": _json_yukseklik_uret(),
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
	var hucre := _yuk_grid_w * _yuk_grid_h
	print("Kaydedildi: editor_cikti.json (oyun formati) | yukseklik hucre=%d (~%.1f KB float ham)" % [
		hucre, hucre * 4.0 / 1024.0
	])
	_durum_mesaji = "Kaydedildi: editor_cikti.json | yuk %dx%d" % [_yuk_grid_w, _yuk_grid_h]
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
	var us_set: Dictionary = {}
	var kavsak_konumlar: Dictionary = {}
	var ham_usler: Variant = kayit.get("usler", [])
	if typeof(ham_usler) == TYPE_ARRAY:
		for uid in ham_usler as Array:
			us_set[str(uid)] = true
	var ham_kavsaklar: Variant = kayit.get("kavsaklar", {})
	if typeof(ham_kavsaklar) == TYPE_DICTIONARY:
		for kid_key in ham_kavsaklar:
			var kid_str := str(kid_key)
			var ham_k: Variant = ham_kavsaklar[kid_key]
			if typeof(ham_k) == TYPE_ARRAY and (ham_k as Array).size() >= 2:
				var karr: Array = ham_k
				kavsak_konumlar[kid_str] = Vector2(float(karr[0]), float(karr[1]))
	elif typeof(ham_kavsaklar) == TYPE_ARRAY:
		var ham_noktalar_eski: Variant = kayit.get("noktalar", {})
		if typeof(ham_noktalar_eski) == TYPE_DICTIONARY:
			for kid_v in ham_kavsaklar as Array:
				var kid_str := str(kid_v)
				if ham_noktalar_eski.has(kid_str):
					var ham: Variant = ham_noktalar_eski[kid_str]
					if typeof(ham) == TYPE_ARRAY and (ham as Array).size() >= 2:
						var arr: Array = ham
						kavsak_konumlar[kid_str] = Vector2(float(arr[0]), float(arr[1]))
	var ham_noktalar: Variant = kayit.get("noktalar", {})
	if typeof(ham_noktalar) == TYPE_DICTIONARY:
		var nokta_sozluk: Dictionary = ham_noktalar
		for id_key in nokta_sozluk:
			var id_str: String = str(id_key)
			if kavsak_konumlar.has(id_str):
				continue
			var ham: Variant = nokta_sozluk[id_key]
			if typeof(ham) == TYPE_ARRAY and (ham as Array).size() >= 2:
				var arr: Array = ham
				var x: float = float(arr[0])
				var y: float = float(arr[1])
				var tip: String = "us" if us_set.has(id_str) else "nokta"
				yeni_noktalar.append({"tip": tip, "konum": Vector2(x, y), "id": id_str})
	for kid in kavsak_konumlar:
		yeni_noktalar.append({"tip": "kavsak", "konum": kavsak_konumlar[kid], "id": kid})
	noktalar = yeni_noktalar
	_sonraki_nokta_indexini_guncelle()
	_sonraki_kavsak_indexini_guncelle()
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
				yeni_yollar.append({"a": a, "b": b, "ara": ara_list, "tip": str(yol.get("tip", "ana"))})
	yollar = yeni_yollar
	_proplar_yukle(kayit)
	_arazi_bolgeleri_yukle(kayit)
	_yukseklik_yukle(kayit)
	print("Yuklendi: %s (%d nokta, %d yol, %d prop, %d arazi, yuk %dx%d)" % [
		CIKTI_DOSYA, noktalar.size(), yollar.size(), proplar.size(), arazi_bolgeleri.size(),
		_yuk_grid_w, _yuk_grid_h
	])
	_durum_mesaji = "Yuklendi: %d nokta, %d yol, %d prop, %d arazi" % [
		noktalar.size(), yollar.size(), proplar.size(), arazi_bolgeleri.size()
	]
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
		var kavsaklar: Variant = son.get("kavsaklar", [])
		if typeof(kavsaklar) == TYPE_ARRAY:
			for kid_v in kavsaklar as Array:
				var kid := str(kid_v)
				if not _kavsak_baska_yolda_kullaniliyor(kid):
					_nokta_sil_id(kid)
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
	_yol_cizim_olusturulan_kavsaklar.clear()
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
		EditorMod.PROP:
			return "PROP"
		EditorMod.ARAZI:
			return "ARAZI"
		EditorMod.YUKSEKLIK:
			return "YUKSEKLIK"
	return "?"


func _arazi_tip_isim(idx: int) -> String:
	if idx < 0 or idx >= ARAZI_TIPLERI.size():
		return "?"
	return str(ARAZI_TIPLERI[idx].get("isim", "?"))


func _arazi_tip_renk(tip_id: String) -> Color:
	for t in ARAZI_TIPLERI:
		if str(t.get("id", "")) == tip_id:
			return t.get("renk", Color(0.3, 0.3, 0.3, 0.35))
	if _ARAZI_TIP_RENK_ESKI.has(tip_id):
		return _ARAZI_TIP_RENK_ESKI[tip_id]
	return Color(0.3, 0.3, 0.3, 0.35)


func _arazi_cizim_iptal() -> void:
	_arazi_aktif_koseler.clear()


func _arazi_kose_geri() -> void:
	if not _arazi_aktif_koseler.is_empty():
		_arazi_aktif_koseler.pop_back()


func _arazi_modu_tikla(mouse_dunya: Vector2) -> void:
	var logical := _mouse_to_logical(mouse_dunya)
	if not _harita_icinde_mi(logical):
		return
	if _arazi_aktif_koseler.size() >= 3:
		var ilk: Vector2 = _arazi_aktif_koseler[0]
		var ilk_iso := IsoProjection.logical_to_iso(ilk) + merkez_logical_iso_offseti(HARITA_SINIR)
		if mouse_dunya.distance_to(ilk_iso) <= ARAZI_KAPANIS_ESIK:
			_arazi_poligonu_kapat()
			return
	_arazi_aktif_koseler.append(logical)
	queue_redraw()


func _arazi_poligonu_kapat() -> void:
	if _arazi_aktif_koseler.size() < 3:
		_durum_mesaji = "Arazi icin en az 3 kose gerekli"
		_durum_sure = 1.8
		queue_redraw()
		return
	var tip_id := "gizlenme"
	var koseler: Array = []
	for k in _arazi_aktif_koseler:
		if k is Vector2:
			koseler.append(k)
	arazi_bolgeleri.append({"tip": tip_id, "koseler": koseler})
	_arazi_aktif_koseler.clear()
	_durum_mesaji = "Arazi eklendi: Gizlenme (%d)" % arazi_bolgeleri.size()
	_durum_sure = 1.8
	queue_redraw()


func _ciz_arazi_bolgeleri(off: Vector2) -> void:
	for bolge in arazi_bolgeleri:
		var tip_id := str(bolge.get("tip", "gizlenme"))
		var renk := _arazi_tip_renk(tip_id)
		var pts: Array = bolge.get("koseler", [])
		if pts.size() < 3:
			continue
		var iso := PackedVector2Array()
		for p in pts:
			if p is Vector2:
				iso.append(IsoProjection.logical_to_iso(p) + off)
		if iso.size() < 3:
			continue
		draw_colored_polygon(iso, renk)
		var sinir := Color(renk.r, renk.g, renk.b, minf(1.0, renk.a + 0.45))
		for i in range(iso.size()):
			draw_line(iso[i], iso[(i + 1) % iso.size()], sinir, 2.0, true)


func _ciz_arazi_aktif(off: Vector2) -> void:
	if _arazi_aktif_koseler.is_empty():
		return
	var renk := _arazi_tip_renk(str(ARAZI_TIPLERI[_secili_arazi_tip_idx].get("id", "gizlenme")))
	var sinir := Color(renk.r, renk.g, renk.b, 0.95)
	var iso_pts: Array = []
	for k in _arazi_aktif_koseler:
		if k is Vector2:
			var iso := IsoProjection.logical_to_iso(k) + off
			iso_pts.append(iso)
			draw_circle(iso, 5.0, sinir)
	for i in range(iso_pts.size() - 1):
		draw_line(iso_pts[i], iso_pts[i + 1], sinir, 1.8, true)
	var fare_iso := get_global_mouse_position()
	if not iso_pts.is_empty():
		draw_line(iso_pts[iso_pts.size() - 1], fare_iso, Color(sinir.r, sinir.g, sinir.b, 0.55), 1.4, true)
		if iso_pts.size() >= 3:
			draw_line(fare_iso, iso_pts[0], Color(1.0, 1.0, 0.4, 0.35), 1.2, true)
			draw_arc(iso_pts[0], ARAZI_KAPANIS_ESIK, 0.0, TAU, 20, Color(1.0, 1.0, 0.35, 0.55), 1.2)


func _prop_paletini_kur() -> void:
	if _prop_palet_icerik == null:
		return
	for c in _prop_palet_icerik.get_children():
		c.queue_free()
	_prop_butonlar.clear()
	var grup := PropKatalog.katalog_kategori(_prop_aktif_kategori)
	for entry in grup:
		var pid := str(entry.get("id", ""))
		if pid == "":
			continue
		var btn := Button.new()
		btn.name = "PropBtn_%s" % pid
		btn.text = str(entry.get("isim", pid))
		btn.toggle_mode = true
		btn.button_pressed = pid == _secili_prop_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", _prop_kategori_renk(_prop_aktif_kategori))
		btn.pressed.connect(_prop_palet_sec.bind(pid))
		_prop_palet_icerik.add_child(btn)
		_prop_butonlar[pid] = btn


func _prop_kategori_sekmeleri_kur() -> void:
	if _prop_kategori_sekmeleri == null:
		return
	for c in _prop_kategori_sekmeleri.get_children():
		c.queue_free()
	_prop_kat_butonlar.clear()
	for kat in PropKatalog.KATEGORI_SIRASI:
		var btn := Button.new()
		btn.name = "KatBtn_%s" % kat
		btn.text = str(PropKatalog.KATEGORI_SEKME.get(kat, kat))
		btn.toggle_mode = true
		btn.button_pressed = kat == _prop_aktif_kategori
		btn.custom_minimum_size = Vector2(46, 26)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.add_theme_color_override("font_color", _prop_kategori_renk(kat))
		btn.pressed.connect(_prop_kategori_sec.bind(kat))
		_prop_kategori_sekmeleri.add_child(btn)
		_prop_kat_butonlar[kat] = btn


func _prop_kategori_sec(kat: String) -> void:
	_prop_aktif_kategori = kat
	for k in _prop_kat_butonlar:
		_prop_kat_butonlar[k].button_pressed = k == kat
	_prop_paletini_kur()
	queue_redraw()


func _prop_kategori_sekmeleri_guncelle() -> void:
	for k in _prop_kat_butonlar:
		_prop_kat_butonlar[k].button_pressed = k == _prop_aktif_kategori


func _prop_kategori_renk(kat: String) -> Color:
	match PropKatalog.kategori_normalize(kat):
		"tas":
			return Color(0.55, 0.52, 0.48, 0.95)
		"bitki":
			return Color(0.45, 0.72, 0.28, 0.95)
		"cicek":
			return Color(0.82, 0.45, 0.62, 0.95)
		"yapi":
			return Color(0.72, 0.56, 0.34, 0.95)
		"dag":
			return Color(0.42, 0.5, 0.62, 0.95)
		"detay":
			return Color(0.78, 0.62, 0.32, 0.95)
		_:
			return Color(0.12, 0.58, 0.22, 0.95)


func _prop_palet_sec(pid: String) -> void:
	_secili_prop_id = pid
	for id in _prop_butonlar:
		_prop_butonlar[id].button_pressed = id == pid
	queue_redraw()


func _prop_paleti_ac() -> void:
	if is_instance_valid(_prop_paleti):
		var pk := PropKatalog.kategori(_secili_prop_id)
		if pk != "":
			_prop_aktif_kategori = pk
		_prop_kategori_sekmeleri_guncelle()
		_prop_paletini_kur()
		_prop_paleti.visible = true
		_prop_paleti.move_to_front()


func _prop_paleti_kapat() -> void:
	if is_instance_valid(_prop_paleti):
		_prop_paleti.visible = false


func _prop_paleti_gorsel_kur() -> void:
	if not is_instance_valid(_prop_paleti):
		return
	_prop_paleti.custom_minimum_size = Vector2(240, 420)
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0.12, 0.14, 0.11, 0.92)
	stil.border_color = Color(0.45, 0.55, 0.38, 0.9)
	stil.set_border_width_all(2)
	stil.set_corner_radius_all(4)
	stil.content_margin_left = 8
	stil.content_margin_right = 8
	stil.content_margin_top = 6
	stil.content_margin_bottom = 6
	_prop_paleti.add_theme_stylebox_override("panel", stil)


func _prop_ui_uzerinde_mi(mouse_dunya: Vector2) -> bool:
	if not is_instance_valid(_prop_paleti) or not _prop_paleti.visible:
		return false
	return _prop_paleti.get_global_rect().has_point(mouse_dunya)


func _mouse_to_logical(mouse_dunya: Vector2) -> Vector2:
	return IsoProjection.iso_to_logical(mouse_dunya - merkez_logical_iso_offseti(HARITA_SINIR))


func _harita_icinde_mi(logical: Vector2) -> bool:
	return (
		logical.x >= HARITA_SINIR["min_x"]
		and logical.x <= HARITA_SINIR["max_x"]
		and logical.y >= HARITA_SINIR["min_y"]
		and logical.y <= HARITA_SINIR["max_y"]
	)


func _prop_ekle(logical: Vector2, prop_id: String) -> void:
	if prop_id == "":
		return
	var kat := PropKatalog.bul_id(prop_id)
	if kat.is_empty():
		return
	var baz_olcek := float(kat.get("olcek", 8.0))
	proplar.append({
		"id": prop_id,
		"konum": logical,
		"olcek": baz_olcek * randf_range(0.85, 1.15),
		"rot": randf_range(0.0, 360.0),
	})


func _prop_yakin_var(logical: Vector2, mesafe: float) -> bool:
	for prop in proplar:
		var pk: Vector2 = prop["konum"]
		if pk.distance_to(logical) < mesafe:
			return true
	return false


func _firca_kategori_carpan() -> float:
	match PropKatalog.kategori_normalize(PropKatalog.kategori(_secili_prop_id)):
		"tas", "cicek", "detay":
			return 1.55
		"bitki":
			return 1.2
		"yapi", "dag":
			return 0.85
		_:
			return 1.0


func _firca_etkin_yogunluk() -> float:
	var y := clampf(_firca_yogunluk, FIRCA_YOGUNLUK_MIN, FIRCA_YOGUNLUK_MAX)
	return y * _firca_kategori_carpan()


func _firca_etkin_min_mesafe() -> float:
	var y := _firca_etkin_yogunluk()
	return maxf(8.0, FIRCA_MIN_MESAFE / y)


func _firca_etkin_serp_adim() -> float:
	var y := _firca_etkin_yogunluk()
	return maxf(5.0, FIRCA_SURUKLEME_ADIM / sqrt(y))


func _firca_etkin_deneme() -> int:
	return clampi(int(FIRCA_SERPISTIRME_TABAN * _firca_etkin_yogunluk()), 4, 28)


func _prop_sirali_indeksleri() -> Array:
	var indeksler: Array = []
	for i in range(proplar.size()):
		indeksler.append(i)
	indeksler.sort_custom(func(a: int, b: int) -> bool:
		var ya: Vector2 = proplar[a]["konum"]
		var yb: Vector2 = proplar[b]["konum"]
		if absf(ya.y - yb.y) > 0.01:
			return ya.y < yb.y
		return ya.x < yb.x
	)
	return indeksler


func _ciz_prop_isaret(prop: Dictionary, prop_idx: int, off: Vector2, font: Font, fs: int) -> void:
	var plogical: Vector2 = prop["konum"]
	var piso := IsoProjection.logical_to_iso(plogical) + off
	var pid := str(prop.get("id", ""))
	var pkat := PropKatalog.kategori(pid)
	var p_renk := _prop_kategori_renk(pkat)
	var duzenle_secili := (
		mod == EditorMod.PROP
		and _prop_alt_mod == PropAltMod.DUZENLE
		and prop_idx == _secili_prop_idx
	)
	var yerlestir_tipi := pid == _secili_prop_id and mod == EditorMod.PROP and _prop_alt_mod == PropAltMod.YERLESTIR
	var yaricap := 12.0 if duzenle_secili else (10.0 if yerlestir_tipi else 9.0)
	draw_circle(piso, yaricap, p_renk)
	draw_arc(piso, yaricap, 0.0, TAU, 20, Color(0.05, 0.05, 0.05, 0.85), 2.0)
	if duzenle_secili:
		draw_arc(piso, yaricap + 4.0, 0.0, TAU, 28, Color(1.0, 0.95, 0.2, 1.0), 3.0)
		draw_arc(piso, yaricap + 7.0, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.75), 1.5)
		var rot := deg_to_rad(float(prop.get("rot", 0.0)))
		var ok_uz := 18.0
		draw_line(piso, piso + Vector2(sin(rot), -cos(rot)) * ok_uz, Color(1.0, 0.95, 0.35, 0.95), 2.0)
	elif yerlestir_tipi:
		draw_arc(piso, yaricap + 3.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.35, 0.95), 2.0)
	var kisaltma := PropKatalog.isim(pid).substr(0, 3)
	draw_string(font, piso + Vector2(11, -7), kisaltma, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1, 1, 1, 0.92))


func _prop_firca_surukle(mouse_dunya: Vector2) -> void:
	var logical := _mouse_to_logical(mouse_dunya)
	if not _harita_icinde_mi(logical):
		return
	var serp_adim := _firca_etkin_serp_adim()
	if logical.distance_to(_son_firca_surukleme) < serp_adim:
		return
	_son_firca_surukleme = logical
	var min_mesafe := _firca_etkin_min_mesafe()
	for _i in range(_firca_etkin_deneme()):
		var ang := randf() * TAU
		var r := sqrt(randf()) * _firca_yaricap
		var pos := logical + Vector2(cos(ang), sin(ang)) * r
		if not _harita_icinde_mi(pos):
			continue
		if _prop_yakin_var(pos, min_mesafe):
			continue
		_prop_ekle(pos, _secili_prop_id)
	queue_redraw()


func _prop_sec_idx(mouse_dunya: Vector2) -> int:
	var logical := _mouse_to_logical(mouse_dunya)
	var en_iyi := -1
	var en_kisa := PROP_SECIM_ESIK
	var en_yuksek_y := -INF
	for i in range(proplar.size()):
		var pk: Vector2 = proplar[i]["konum"]
		var d := pk.distance_to(logical)
		if d > PROP_SECIM_ESIK:
			continue
		if d < en_kisa - 0.5 or (absf(d - en_kisa) <= 0.5 and pk.y > en_yuksek_y):
			en_kisa = d
			en_yuksek_y = pk.y
			en_iyi = i
	return en_iyi


func _prop_duzenle_tasi(mouse_dunya: Vector2) -> void:
	if _secili_prop_idx < 0 or _secili_prop_idx >= proplar.size():
		return
	var logical := _mouse_to_logical(mouse_dunya)
	if not _harita_icinde_mi(logical):
		return
	proplar[_secili_prop_idx]["konum"] = logical


func _prop_olcek_ayarla(carpan: float) -> void:
	if _secili_prop_idx < 0 or _secili_prop_idx >= proplar.size():
		return
	var yeni := clampf(float(proplar[_secili_prop_idx].get("olcek", 8.0)) * carpan, PROP_OLCEK_MIN, PROP_OLCEK_MAX)
	proplar[_secili_prop_idx]["olcek"] = snappedf(yeni, 0.01)
	queue_redraw()


func _prop_rotasyon_ayarla(delta_deg: float) -> void:
	if _secili_prop_idx < 0 or _secili_prop_idx >= proplar.size():
		return
	var rot := float(proplar[_secili_prop_idx].get("rot", 0.0)) + delta_deg
	while rot < 0.0:
		rot += 360.0
	while rot >= 360.0:
		rot -= 360.0
	proplar[_secili_prop_idx]["rot"] = snappedf(rot, 0.1)
	queue_redraw()


func _prop_secili_sil() -> void:
	if _secili_prop_idx < 0 or _secili_prop_idx >= proplar.size():
		return
	proplar.remove_at(_secili_prop_idx)
	_secili_prop_idx = -1
	_prop_duzenle_surukleme = false
	queue_redraw()


func _prop_sil_yakin(mouse_dunya: Vector2) -> void:
	var logical := _mouse_to_logical(mouse_dunya)
	var en_yakin := -1
	var en_kisa := PROP_SILME_ESIK
	for i in range(proplar.size()):
		var pk: Vector2 = proplar[i]["konum"]
		var d := pk.distance_to(logical)
		if d < en_kisa:
			en_kisa = d
			en_yakin = i
	if en_yakin >= 0:
		proplar.remove_at(en_yakin)
		queue_redraw()


func _json_proplar_uret() -> Array:
	var json_proplar: Array = []
	for prop in proplar:
		var konum: Vector2 = prop["konum"]
		json_proplar.append({
			"id": str(prop.get("id", "")),
			"x": int(round(konum.x)),
			"y": int(round(konum.y)),
			"olcek": snappedf(float(prop.get("olcek", 8.0)), 0.01),
			"rot": snappedf(float(prop.get("rot", 0.0)), 0.01),
		})
	return json_proplar


func _json_arazi_bolgeleri_uret() -> Array:
	var sonuc: Array = []
	for bolge in arazi_bolgeleri:
		if typeof(bolge) != TYPE_DICTIONARY:
			continue
		var tip_id := str(bolge.get("tip", "gizlenme"))
		var pts: Array = bolge.get("koseler", [])
		if pts.size() < 3:
			continue
		var koseler_json: Array = []
		for p in pts:
			if p is Vector2:
				koseler_json.append([int(round(p.x)), int(round(p.y))])
		if koseler_json.size() < 3:
			continue
		sonuc.append({"tip": tip_id, "koseler": koseler_json})
	return sonuc


func _arazi_bolgeleri_yukle(kayit: Dictionary) -> void:
	arazi_bolgeleri.clear()
	_arazi_cizim_iptal()
	var ham: Variant = kayit.get("arazi_bolgeleri", [])
	if typeof(ham) != TYPE_ARRAY:
		return
	for raw in ham as Array:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = raw
		var tip_id := str(d.get("tip", "gizlenme"))
		var ham_koseler: Variant = d.get("koseler", [])
		if typeof(ham_koseler) != TYPE_ARRAY:
			continue
		var koseler: Array = []
		for pt in ham_koseler as Array:
			if typeof(pt) == TYPE_ARRAY and (pt as Array).size() >= 2:
				var parr: Array = pt
				koseler.append(Vector2(float(parr[0]), float(parr[1])))
		if koseler.size() < 3:
			continue
		arazi_bolgeleri.append({"tip": tip_id, "koseler": koseler})


func _proplar_yukle(kayit: Dictionary) -> void:
	proplar.clear()
	var ham: Variant = kayit.get("proplar", [])
	if typeof(ham) != TYPE_ARRAY:
		return
	for raw in ham as Array:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = raw
		var pid := str(d.get("id", ""))
		if pid == "":
			continue
		var kat := PropKatalog.bul_id(pid)
		var baz := float(kat.get("olcek", 8.0)) if not kat.is_empty() else 8.0
		var ham_olcek := float(d.get("olcek", baz))
		proplar.append({
			"id": pid,
			"konum": Vector2(float(d.get("x", 0)), float(d.get("y", 0))),
			"olcek": PropKatalog.olcek_normalize(ham_olcek, baz),
			"rot": float(d.get("rot", 0.0)),
		})
	_secili_prop_idx = -1
	_prop_duzenle_surukleme = false


func _yuk_firca_adi() -> String:
	match _yuk_firca:
		YukFirca.YUKSELT:
			return "YUKSELT"
		YukFirca.ALCALT:
			return "ALCALT"
		YukFirca.YUMUSAT:
			return "YUMUSAT"
		YukFirca.DUZLE:
			return "DUZLE"
	return "?"


func _yuk_grid_boyut_hesapla() -> Vector2i:
	var map_w := maxf(HARITA_SINIR.max_x - HARITA_SINIR.min_x, 1.0)
	var map_h := maxf(HARITA_SINIR.max_y - HARITA_SINIR.min_y, 1.0)
	var tw := YUK_GRID_W
	var th := maxi(1, int(round(float(tw) * map_h / map_w)))
	return Vector2i(tw, th)


func _yuk_grid_sifirla() -> void:
	var dim := _yuk_grid_boyut_hesapla()
	_yuk_grid_w = dim.x
	_yuk_grid_h = dim.y
	_yuk_veri = PackedFloat32Array()
	_yuk_veri.resize(_yuk_grid_w * _yuk_grid_h)
	_yuk_veri.fill(0.0)
	_yuk_overlay_dirty = true


func _yuk_boya_bitir() -> void:
	_yuk_sol_basili = false
	_yuk_duzle_hazir = false


func _yuk_hucre_merkez(ix: int, iy: int) -> Vector2:
	var u := (float(ix) + 0.5) / float(_yuk_grid_w)
	var v := (float(iy) + 0.5) / float(_yuk_grid_h)
	return Vector2(
		lerpf(HARITA_SINIR.min_x, HARITA_SINIR.max_x, u),
		lerpf(HARITA_SINIR.min_y, HARITA_SINIR.max_y, v)
	)


func _yuk_idx(ix: int, iy: int) -> int:
	return iy * _yuk_grid_w + ix


func _yuk_hucre_oku(ix: int, iy: int) -> float:
	if ix < 0 or iy < 0 or ix >= _yuk_grid_w or iy >= _yuk_grid_h:
		return 0.0
	return _yuk_veri[_yuk_idx(ix, iy)]


func _yuk_ornekle(logical_x: float, logical_y: float) -> float:
	if _yuk_veri.is_empty() or _yuk_grid_w < 1 or _yuk_grid_h < 1:
		return 0.0
	var map_w := maxf(HARITA_SINIR.max_x - HARITA_SINIR.min_x, 1.0)
	var map_h := maxf(HARITA_SINIR.max_y - HARITA_SINIR.min_y, 1.0)
	var u := (logical_x - HARITA_SINIR.min_x) / map_w * float(_yuk_grid_w - 1)
	var v := (logical_y - HARITA_SINIR.min_y) / map_h * float(_yuk_grid_h - 1)
	var x0 := int(floor(u))
	var y0 := int(floor(v))
	var x1 := mini(x0 + 1, _yuk_grid_w - 1)
	var y1 := mini(y0 + 1, _yuk_grid_h - 1)
	x0 = clampi(x0, 0, _yuk_grid_w - 1)
	y0 = clampi(y0, 0, _yuk_grid_h - 1)
	var tx := u - float(x0)
	var ty := v - float(y0)
	var h00 := _yuk_hucre_oku(x0, y0)
	var h10 := _yuk_hucre_oku(x1, y0)
	var h01 := _yuk_hucre_oku(x0, y1)
	var h11 := _yuk_hucre_oku(x1, y1)
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), ty)


func _yuk_firca_agirlik(dist: float, yaricap: float) -> float:
	if yaricap <= 0.001:
		return 0.0
	var t := clampf(dist / yaricap, 0.0, 1.0)
	return 1.0 - smoothstep(0.0, 1.0, t)


func _yuk_firca_uygula(merkez: Vector2) -> void:
	if _yuk_veri.is_empty():
		_yuk_grid_sifirla()
	var map_w := maxf(HARITA_SINIR.max_x - HARITA_SINIR.min_x, 1.0)
	var map_h := maxf(HARITA_SINIR.max_y - HARITA_SINIR.min_y, 1.0)
	var cell_w := map_w / float(_yuk_grid_w)
	var cell_h := map_h / float(_yuk_grid_h)
	var r := _yuk_firca_yaricap
	var ix0 := clampi(int(floor((merkez.x - r - HARITA_SINIR.min_x) / cell_w)), 0, _yuk_grid_w - 1)
	var ix1 := clampi(int(ceil((merkez.x + r - HARITA_SINIR.min_x) / cell_w)), 0, _yuk_grid_w - 1)
	var iy0 := clampi(int(floor((merkez.y - r - HARITA_SINIR.min_y) / cell_h)), 0, _yuk_grid_h - 1)
	var iy1 := clampi(int(ceil((merkez.y + r - HARITA_SINIR.min_y) / cell_h)), 0, _yuk_grid_h - 1)
	var guc := _yuk_firca_gucu
	var yum_kaynak: PackedFloat32Array = PackedFloat32Array()
	if _yuk_firca == YukFirca.YUMUSAT:
		yum_kaynak = _yuk_veri.duplicate()
	for iy in range(iy0, iy1 + 1):
		for ix in range(ix0, ix1 + 1):
			var cell := _yuk_hucre_merkez(ix, iy)
			var dist := cell.distance_to(merkez)
			if dist > r:
				continue
			var w := _yuk_firca_agirlik(dist, r)
			if w <= 0.0001:
				continue
			var idx := _yuk_idx(ix, iy)
			var h := _yuk_veri[idx]
			match _yuk_firca:
				YukFirca.YUKSELT:
					h += YUK_YUKSELT_ORAN * guc * w
				YukFirca.ALCALT:
					h -= YUK_YUKSELT_ORAN * guc * w
				YukFirca.YUMUSAT:
					var ort := 0.0
					var adet := 0.0
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var nx := clampi(ix + dx, 0, _yuk_grid_w - 1)
							var ny := clampi(iy + dy, 0, _yuk_grid_h - 1)
							ort += yum_kaynak[ny * _yuk_grid_w + nx]
							adet += 1.0
					ort /= maxf(adet, 1.0)
					h = lerpf(h, ort, clampf(0.55 * guc * w, 0.0, 1.0))
				YukFirca.DUZLE:
					if _yuk_duzle_hazir:
						h = lerpf(h, _yuk_duzle_hedef, clampf(0.65 * guc * w, 0.0, 1.0))
			_yuk_veri[idx] = h
	_yuk_overlay_dirty = true


func _yuk_firca_surukle(mouse_dunya: Vector2) -> void:
	var logical := _mouse_to_logical(mouse_dunya)
	if not _harita_icinde_mi(logical):
		return
	if logical.distance_to(_son_yuk_firca_surukleme) < YUK_FIRCA_SURUKLEME_ADIM:
		return
	_son_yuk_firca_surukleme = logical
	_yuk_firca_uygula(logical)


func _yuk_overlay_guncelle() -> void:
	if not _yuk_overlay_dirty and _yuk_overlay_tex != null:
		return
	if _yuk_veri.is_empty():
		_yuk_grid_sifirla()
	if _yuk_overlay_img == null or _yuk_overlay_img.get_width() != _yuk_grid_w or _yuk_overlay_img.get_height() != _yuk_grid_h:
		_yuk_overlay_img = Image.create(_yuk_grid_w, _yuk_grid_h, false, Image.FORMAT_RGBA8)
	var vmin := 0.0
	var vmax := 0.0
	for i in range(_yuk_veri.size()):
		var hv := _yuk_veri[i]
		vmin = minf(vmin, hv)
		vmax = maxf(vmax, hv)
	var span := maxf(vmax - vmin, 40.0)
	for iy in range(_yuk_grid_h):
		for ix in range(_yuk_grid_w):
			var n := (_yuk_veri[_yuk_idx(ix, iy)] - vmin) / span
			n = clampf(n, 0.0, 1.0)
			_yuk_overlay_img.set_pixel(ix, iy, Color(n, n, n, YUK_OVERLAY_ALPHA))
	if _yuk_overlay_tex == null:
		_yuk_overlay_tex = ImageTexture.create_from_image(_yuk_overlay_img)
	else:
		_yuk_overlay_tex.update(_yuk_overlay_img)
	_yuk_overlay_dirty = false


func _json_yukseklik_uret() -> Dictionary:
	var veri: Array = []
	veri.resize(_yuk_veri.size())
	for i in range(_yuk_veri.size()):
		veri[i] = snappedf(_yuk_veri[i], 0.01)
	return {
		"genislik": _yuk_grid_w,
		"yukseklik": _yuk_grid_h,
		"veri": veri,
	}


func _yukseklik_yukle(kayit: Dictionary) -> void:
	_yuk_grid_sifirla()
	var ham: Variant = kayit.get("yukseklik_haritasi", null)
	if typeof(ham) != TYPE_DICTIONARY:
		return
	var d: Dictionary = ham
	var gw := int(d.get("genislik", _yuk_grid_w))
	var gh := int(d.get("yukseklik", _yuk_grid_h))
	var ham_veri: Variant = d.get("veri", [])
	if typeof(ham_veri) != TYPE_ARRAY or gw < 1 or gh < 1:
		return
	var arr: Array = ham_veri
	if arr.size() < gw * gh:
		return
	_yuk_grid_w = gw
	_yuk_grid_h = gh
	_yuk_veri = PackedFloat32Array()
	_yuk_veri.resize(gw * gh)
	for i in range(gw * gh):
		_yuk_veri[i] = float(arr[i])
	_yuk_overlay_dirty = true
