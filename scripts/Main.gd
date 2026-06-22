extends Node2D

const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const MetaSystem = preload("res://scripts/systems/meta_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const GameData = preload("res://scripts/systems/game_data.gd")
const WorldSystem = preload("res://scripts/systems/world_system.gd")
const FogSystem = preload("res://scripts/systems/fog_system.gd")
const UISystem = preload("res://scripts/systems/ui_system.gd")
const CommandSystem = preload("res://scripts/systems/command_system.gd")

var world_system: WorldSystem
var fog_system: FogSystem
var ui_system: UISystem
var command_system: CommandSystem

# === VERI (JSON'dan yuklenir) ===
var ustunluk_tablosu = {}
var osmanli_birim_tipleri: Array = []
var dogu_roma_birim_tipleri: Array = []
var kampanya_harita_idleri: Array = []
var kampanya_bolgeleri: Array = []
var aktif_harita_id = "trakya"
var harita_sinir = {"min_x": 20.0, "max_x": 980.0, "min_y": 80.0, "max_y": 440.0}

# === OYUN DEĞİŞKENLERİ ===
var oyun_bitti = false
var oyun_suresi = 0.0
var max_sure = 2100.0

# === ZORLUK ===
var zorluk = "orta"
var zorluk_ayarlari = {
	"kolay": {
		"spawn": 10.2,
		"guc_carpan": 1.13,
		"savunma_carpan": 1.1,
		"hp_carpan": 1.12,
		"kontenjan_hedef": 31,
		"oyuncu_altin": 29,
		"ai_altin": 44,
	},
	"orta": {
		"spawn": 8.0,
		"guc_carpan": 1.23,
		"savunma_carpan": 1.19,
		"hp_carpan": 1.21,
		"kontenjan_hedef": 32,
		"oyuncu_altin": 27,
		"ai_altin": 52,
	},
	"zor": {
		"spawn": 5.8,
		"guc_carpan": 1.34,
		"savunma_carpan": 1.28,
		"hp_carpan": 1.3,
		"kontenjan_hedef": 34,
		"oyuncu_altin": 24,
		"ai_altin": 62,
	},
}

# === PUAN & ALTIN ===
var osmanli_puani = 0
var dogu_roma_puani = 0
var kazanma_puani = 200
var osmanli_altini = 30
var dogu_roma_altini = 30
var osmanli_gelisim_altini = 0
var dogu_roma_gelisim_altini = 0
var puan_timer = 0.0
var puan_interval = 15.0
var sure_altin_taban = 4

# === HAZIRLIK ===
var hazirlik_suresi = 120.0
var kalan_sure = 120.0
var hazirlik_fazi = true

# === KONTROL NOKTALARI ===
var nokta_konumlari = {}
var nokta_sahipleri = {}

var nokta_capture = {}
var capture_hizi = 3.0

var nokta_puan = {}
var nokta_altin = {}

# === BİRİM TİPLERİ (data/units/*.json) ===

# === ENVANTER & KOMPOZİSYON ===
var max_kontenjan = 30
var mevcut_kontenjan = 30
var kompozisyon = [0, 0, 0]
var envanter = []

# === AKTİF BİRİMLER ===
var aktif_birimler = []

# === AI ===
var ai_spawn_timer = 0.0
var ai_spawn_suresi = 12.0
var ai_karar_araligi = {"kolay": 1.9, "orta": 1.25, "zor": 0.8}
var ai_takip_menzili = 430.0
var ai_kompozisyon = [0, 0, 0]
var ai_envanter: Array = []
var ai_hazirlik_timer = 0.0
var ai_hazirlik_araligi = 1.6
var ai_dalga_sayisi = 0

# === SEÇİM ===
var secili_nokta = ""
var secili_envanter_idx = -1
var secili_envanter_tip_anahtari = ""
var secili_envanter_gonder_adedi = 1
var secili_birim = null

# === UI ===
var hazirlik_paneli = []
var savas_paneli = []
var envanter_butonlari = []
var envanter_gruplari = {}
var envanter_adet_satiri: HBoxContainer = null
var envanter_adet_eksi_btn: Button = null
var envanter_adet_arti_btn: Button = null
var envanter_adet_label: Label = null
var sayi_labellar = []
var capture_barlar = {}
var zorluk_butonlari = {}
var tekrar_oyna_btn: Button = null
var kart_butonlari = []
var ekipman_butonlari = []
var secili_kart = {}
var ai_secili_kart = {}
var secili_ekipman = ""
var ai_secili_ekipman = ""
var hazirlik_aktif_tab = "genel"
var hazirlik_tab_gruplari = {"genel": [], "ordu": [], "taktik": []}
var hazirlik_tab_butonlari = {}
var mac_istatistik_kayit = {"galibiyet": 0, "maglubiyet": 0, "beraberlik": 0}
var detay_popup_timer: Timer = null
var detay_popup_panel: Panel = null
var detay_popup_label: Label = null
var secili_komut = "hareket"
var komut_menusu_panel: PanelContainer = null
var komut_menusu_hedef_birim = null
var pan_aktif = false
var kamera: Camera2D = null
var zoom_min = 0.3
var zoom_max = 1.5
var zoom_hizi = 0.1
var minimap_panel: PanelContainer = null
var minimap_kamera_rect: ColorRect = null
var minimap_birim_osmanli: ColorRect = null
var minimap_birim_dogu_roma: ColorRect = null
var minimap_nokta_isaretleri = {}
var minimap_fow_rect: TextureRect = null
var minimap_fow_gorseli: Image = null
var minimap_fow_doku: ImageTexture = null
var minimap_boyut = Vector2(220, 132)
var ui_root: Control = null
var ust_bilgi_paneli: HBoxContainer = null
var yan_hud_tetik: PanelContainer = null
var yan_hud_panel: PanelContainer = null
var yan_hud_icerik: VBoxContainer = null
var yan_hud_kaybol_timer: Timer = null
var hazirlik_panel_root: PanelContainer = null
var hazirlik_tabs_row: HBoxContainer = null
var hazirlik_tabs_content: VBoxContainer = null
var hazirlik_tab_container_map = {}
var savas_panel_root: PanelContainer = null
var savas_icerik_vbox: VBoxContainer = null
var envanter_grid: GridContainer = null
var mevcut_hiz_carpani = 1.0
var hiz_tek_btn: Button = null
var takviye_liste_satiri: HBoxContainer = null
var takviye_adet_satiri: HBoxContainer = null
var takviye_butonlari = []
var takviye_secili_idx = 0
var takviye_secili_adet = 1
var takviye_adet_label: Label = null
var takviye_toplu_btn: Button = null

# === SAVAS SISI / KESIF / PUSU ===
var gorus_hucre_boyutu = 40.0
var kesfedilen_alanlar = {}
var su_anki_gorus_alani = {}
var ai_su_anki_gorus_alani = {}
var gorus_hucre_katmani: Control = null
var gorus_hucreleri = {}
var kesfedilen_noktalar = {}
var nokta_son_bilgi = {}
var dusman_son_gorulen_konum = {}
var dusman_hayalet_ikonlari = {}
var hayalet_ikon_suresi = 4.0
var normal_birim_gorus_bonus = 30.0
var kontrol_noktasi_gorus_yaricapi = 100.0
var kesif_tespit_esigi = 135.0
var pusu_ilk_saldiri_carpani = 2.0
var birim_id_sayaci = 1
var orman_bolgeleri: Array = []
var arazi_bolgeleri: Array = []
var arazi_katmani: Node2D = null
var suvari_isimleri = {"Akinci": true, "Kataphraktoi": true}

# === FORMASYON / MORAL / GENERAL ===
var formasyonlar = {
	"hucum": {"guc": 1.2, "savunma": 0.85, "hiz": 1.05},
	"savunma": {"guc": 0.9, "savunma": 1.2, "hiz": 0.9},
	"dengeli": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0}
}
var taraf_formasyon = {"osmanli": "dengeli", "dogu_roma": "dengeli"}
var taraf_moral = {"osmanli": 100.0, "dogu_roma": 100.0}

# === YETENEK / ULT / HAVA ===
var ult_sarj = {"osmanli": 0.0, "dogu_roma": 0.0}
var ult_aktif_sure = {"osmanli": 0.0, "dogu_roma": 0.0}
var hava_durumu = "Acik"
var hava_durumu_efektleri = {
	"Acik": {"hiz": 1.0, "menzil": 1.0, "guc": 1.0},
	"Yagmur": {"hiz": 0.9, "menzil": 0.9, "guc": 0.95},
	"Sis": {"hiz": 0.95, "menzil": 0.78, "guc": 1.0},
	"Ruzgar": {"hiz": 1.05, "menzil": 1.08, "guc": 1.0},
}

# === KART / EKIPMAN / TERFI ===
var kart_havuzu = [
	{"id": "disiplin", "isim": "Demir Disiplin", "aciklama": "+10 moral", "moral": 10.0},
	{"id": "ikmal", "isim": "Hizli Ikmal", "aciklama": "+12 altin", "altin": 12},
	{"id": "talim", "isim": "Saha Talimi", "aciklama": "+8% guc", "guc": 1.08},
	{"id": "savunma_hatti", "isim": "Savunma Hatti", "aciklama": "+8% savunma", "savunma": 1.08},
	{"id": "hucum_plani", "isim": "Hucum Plani", "aciklama": "Formasyon: Hucum", "formasyon": "hucum"},
]
var kart_secenekleri = []
var ekipmanlar = {
	"celik": {"isim": "Keskin Celik", "guc": 1.12, "savunma": 1.0, "menzil": 1.0},
	"zirh": {"isim": "Zirh Kaplama", "guc": 1.0, "savunma": 1.12, "menzil": 1.0},
	"durbun": {"isim": "Saha Durbunu", "guc": 1.0, "savunma": 1.0, "menzil": 1.15}
}
var taraf_carpanlari = {
	"osmanli": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0},
	"dogu_roma": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0}
}
var terfi_verisi = {
	"osmanli": {},
	"dogu_roma": {}
}

# === NOKTA GELISTIRME / ISTATISTIK ===
var nokta_gelistirme = {}
var mac_istatistik = {
	"osmanli": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
	"dogu_roma": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
}

# === KAMPANYA ===
var kampanya_index = 0

func veri_yukle() -> void:
	osmanli_birim_tipleri = GameData.load_units("osmanli")
	dogu_roma_birim_tipleri = GameData.load_units("dogu_roma")
	ustunluk_tablosu = GameData.load_ustunluk()
	kampanya_harita_idleri = GameData.load_campaign_map_ids()
	kampanya_bolgeleri = GameData.campaign_region_names(kampanya_harita_idleri)
	kompozisyon_dizisi_sifirla()
	ai_kompozisyon_dizisi_sifirla()
	aktif_harita_id = str(kampanya_harita_idleri[0]) if kampanya_harita_idleri.size() > 0 else "trakya"
	harita_uygula(aktif_harita_id)

func kompozisyon_dizisi_sifirla() -> void:
	kompozisyon.clear()
	kompozisyon.resize(max(1, osmanli_birim_tipleri.size()))
	kompozisyon.fill(0)

func ai_kompozisyon_dizisi_sifirla() -> void:
	ai_kompozisyon.clear()
	ai_kompozisyon.resize(max(1, dogu_roma_birim_tipleri.size()))
	ai_kompozisyon.fill(0)

func _world_system_hazirla() -> void:
	world_system = WorldSystem.new()
	world_system.configure(self)
	world_system.set_on_map_applied(func():
		if is_instance_valid(gorus_hucre_katmani):
			savas_sisi_hucrelerini_sifirla()
	)
	world_system.set_on_map_visuals_extra(func():
		var positions = world_system.get_point_positions()
		for nokta in positions:
			if capture_barlar.has(nokta):
				var pos = positions[nokta]
				capture_barlar[nokta].position = pos + Vector2(0, 85)
				capture_barlar[nokta].size.x = 80.0 * (nokta_capture.get(nokta, 50.0) / 100.0)
	)

func _world_refs_sync() -> void:
	aktif_harita_id = world_system.get_active_map_id()
	harita_sinir = world_system.get_map_bounds()
	nokta_konumlari = world_system.get_point_positions()
	nokta_puan = world_system.get_point_scores()
	nokta_altin = world_system.get_point_gold_values()
	arazi_bolgeleri = world_system.get_terrain_regions()
	orman_bolgeleri = world_system.get_forest_regions()
	arazi_katmani = world_system.get_arazi_katmani()
	kamera = world_system.get_camera()

func _fog_system_hazirla() -> void:
	fog_system = FogSystem.new()
	fog_system.configure(self, world_system)
	_fog_refs_sync()

func _fog_refs_sync() -> void:
	gorus_hucre_boyutu = fog_system.get_cell_size()
	gorus_hucre_katmani = fog_system.get_fog_layer()
	gorus_hucreleri = fog_system.gorus_hucreleri
	kesfedilen_alanlar = fog_system.get_discovered_cells()
	su_anki_gorus_alani = fog_system.get_current_vision("osmanli")
	ai_su_anki_gorus_alani = fog_system.get_current_vision("dogu_roma")
	kesfedilen_noktalar = fog_system.get_discovered_points()
	kesif_tespit_esigi = fog_system.kesif_tespit_esigi
	kontrol_noktasi_gorus_yaricapi = fog_system.kontrol_noktasi_gorus_yaricapi
	normal_birim_gorus_bonus = fog_system.normal_birim_gorus_bonus
	hayalet_ikon_suresi = fog_system.hayalet_ikon_suresi
	dusman_son_gorulen_konum = fog_system.get_last_known_enemy_positions()

func _ui_system_hazirla() -> void:
	ui_system = UISystem.new()
	ui_system.configure(self)

func _ui_refs_sync() -> void:
	ui_root = ui_system.get_ui_root()
	ust_bilgi_paneli = ui_system.get_ust_bilgi_paneli()
	hazirlik_panel_root = ui_system.get_hazirlik_panel_root()
	hazirlik_tabs_row = ui_system.get_hazirlik_tabs_row()
	hazirlik_tabs_content = ui_system.get_hazirlik_tabs_content()
	savas_panel_root = ui_system.get_savas_panel_root()
	savas_icerik_vbox = ui_system.get_savas_icerik_vbox()
	yan_hud_tetik = ui_system.get_yan_hud_tetik()
	yan_hud_panel = ui_system.get_yan_hud_panel()
	yan_hud_icerik = ui_system.get_yan_hud_icerik()
	yan_hud_kaybol_timer = ui_system.get_yan_hud_kaybol_timer()
	detay_popup_panel = ui_system.get_detay_popup_panel()
	detay_popup_label = ui_system.get_detay_popup_label()
	detay_popup_timer = ui_system.get_detay_popup_timer()
	hazirlik_paneli = ui_system.get_hazirlik_paneli()
	hazirlik_aktif_tab = ui_system.get_hazirlik_aktif_tab()
	hazirlik_tab_gruplari = ui_system.get_hazirlik_tab_gruplari()
	hazirlik_tab_butonlari = ui_system.get_hazirlik_tab_butonlari()
	hazirlik_tab_container_map = ui_system.get_hazirlik_tab_container_map()
	savas_paneli = ui_system.get_savas_paneli()
	hiz_tek_btn = ui_system.get_hiz_tek_btn()

func _command_system_hazirla() -> void:
	command_system = CommandSystem.new()
	command_system.configure(self)
	command_system.bind_map_helpers(
		harita_sinirla,
		en_yakin_nokta_bul,
		nokta_merkezi,
		en_yakin_dost_nokta,
		birimin_arazisini_bul
	)

func _command_refs_sync() -> void:
	secili_komut = command_system.get_selected_command()
	secili_birim = command_system.get_selected_unit()
	komut_menusu_hedef_birim = command_system.get_menu_target_unit()

func _command_state_push() -> void:
	command_system._sync_from_main(secili_komut, secili_birim, komut_menusu_hedef_birim)

func _command_status_line_uygula(result: Dictionary) -> void:
	var metin = str(result.get("status_line", ""))
	if metin == "":
		return
	var savas_bilgi = ui_node("Label_SavasBilgi")
	if savas_bilgi != null:
		savas_bilgi.text = metin

func harita_uygula(map_id: String) -> void:
	world_system.harita_uygula(map_id)
	_world_refs_sync()

func kamera_hazirla() -> void:
	world_system.kamera_hazirla()
	_world_refs_sync()

func kamera_limitlerini_guncelle() -> void:
	world_system.kamera_limitlerini_guncelle()

func kamera_sinirla() -> void:
	world_system.kamera_sinirla()

func arazi_katmani_olustur() -> void:
	world_system.arazi_katmani_olustur()
	_world_refs_sync()

func arazi_gorsellerini_guncelle() -> void:
	world_system.arazi_gorsellerini_guncelle()

func harita_gorsellerini_guncelle() -> void:
	world_system.harita_gorsellerini_guncelle()

func _hucre_anahtari(pos: Vector2) -> Vector2i:
	return fog_system._hucre_anahtari(pos)

func _hucre_merkezi(anahtar: Vector2i) -> Vector2:
	return fog_system._hucre_merkezi(anahtar)

func _goruste_mi(pos: Vector2, gorus_alani: Dictionary) -> bool:
	return fog_system._goruste_mi(pos, gorus_alani)

func _gorus_ekle(gorus_alani: Dictionary, merkez: Vector2, yaricap: float) -> void:
	fog_system._gorus_ekle(gorus_alani, merkez, yaricap)

func _birim_gorus_yaricapi(tip: Dictionary) -> float:
	if tip.has("gorus_yaricapi"):
		return float(tip["gorus_yaricapi"])
	return float(tip.get("menzil", 80.0)) + normal_birim_gorus_bonus

func savas_sisi_hucrelerini_sifirla() -> void:
	if not is_instance_valid(gorus_hucre_katmani):
		return
	fog_system.reset_fog_grid()
	_fog_refs_sync()

func savas_sisi_katmani_olustur() -> void:
	fog_system.create_fog_layer()
	_fog_refs_sync()

func _nokta_renk(taraf: String) -> Color:
	if taraf == "osmanli":
		return Color.GOLD
	if taraf == "dogu_roma":
		return Color.PURPLE
	return Color.GRAY

func birimin_arazisini_bul(konum: Vector2) -> Dictionary:
	return world_system.birimin_arazisini_bul(konum)

func _orman_bolge_index(pos: Vector2) -> int:
	return world_system.orman_bolge_index(pos)

func _kesif_birimi_mi(birim: Dictionary) -> bool:
	return fog_system.is_scout_unit(birim)

func _orman_gizlisi_tespit_edildi_mi(hedef: Dictionary, goren_taraf: String) -> bool:
	return fog_system.is_forest_stealth_broken(hedef, goren_taraf, aktif_birimler)

func birim_gorunur_mu_tarafa(hedef: Dictionary, goren_taraf: String) -> bool:
	return fog_system.is_unit_visible_to_faction(hedef, goren_taraf, aktif_birimler)

func pusu_tetik_kontrolu() -> void:
	for birim in aktif_birimler:
		if birim["hp"] <= 0 or not birim.get("pusu_modunda", false):
			continue
		var etkiler = birim_etkin_degerleri(birim)
		for dusman in aktif_birimler:
			if dusman["hp"] <= 0 or dusman["taraf"] == birim["taraf"]:
				continue
			if birim["konum"].distance_to(dusman["konum"]) <= etkiler["menzil"]:
				birim["pusu_modunda"] = false
				birim["pusu_ilk_saldiri_kullanildi"] = false
				var savas_l = ui_node("Label_SavasBilgi")
				if birim["taraf"] == "osmanli" and savas_l != null:
					savas_l.text = "Pusu tetiklendi! Ilk saldiri x2 bonuslu"
				break

func savas_sisi_guncelle() -> void:
	fog_system.update_vision(aktif_birimler, nokta_sahipleri)
	_fog_refs_sync()

func _hayalet_ikon_temizle(id: int) -> void:
	fog_system.clear_ghost_icon(id)

func _dusman_hayaletlerini_guncelle() -> void:
	fog_system.refresh_ghost_icons()
	_fog_refs_sync()

func birim_gorunurluklerini_guncelle() -> void:
	for birim in aktif_birimler:
		if not is_instance_valid(birim["node"]):
			continue
		birim["node"].visible = fog_system.is_unit_visible_to_player(birim, aktif_birimler)
	fog_system.update_enemy_intel(aktif_birimler)
	_fog_refs_sync()

func nokta_gorunurluklerini_guncelle() -> void:
	for nokta in nokta_konumlari:
		var kesfedildi = fog_system.is_point_discovered(nokta)
		var kare = get_node_or_null("Nokta_" + nokta)
		var isim_l = get_node_or_null("Label_Nokta_" + nokta)
		var puan_l = get_node_or_null("Label_Puan_" + nokta)
		var bg = get_node_or_null("CaptureBg_" + nokta)
		var bar = capture_barlar.get(nokta, null)
		if not kesfedildi:
			if kare: kare.visible = false
			if isim_l: isim_l.visible = false
			if puan_l: puan_l.visible = false
			if bg: bg.visible = false
			if bar: bar.visible = false
			continue

		if kare: kare.visible = true
		if isim_l: isim_l.visible = true
		if puan_l:
			puan_l.visible = true
			puan_l.modulate = Color(1, 1, 1, 1)
		nokta_son_bilgi[nokta] = {
			"sahip": nokta_sahipleri[nokta],
			"capture": nokta_capture[nokta]
		}
		if kare:
			kare.color = _nokta_renk(nokta_sahipleri[nokta])
			kare.modulate = Color(1, 1, 1, 1)
		if bg: bg.visible = true
		if bar:
			bar.visible = true
			bar.size.x = 80.0 * (nokta_capture[nokta] / 100.0)
			bar.color = Color(1, 0.8, 0)

func kampanya_haritasini_yukle() -> void:
	if kampanya_harita_idleri.is_empty():
		return
	kampanya_index = clampi(kampanya_index, 0, kampanya_harita_idleri.size() - 1)
	harita_uygula(str(kampanya_harita_idleri[kampanya_index]))

func _ready() -> void:
	randomize()
	_world_system_hazirla()
	_fog_system_hazirla()
	_ui_system_hazirla()
	_command_system_hazirla()
	kamera_hazirla()
	veri_yukle()
	kayit_yukle()
	kampanya_haritasini_yukle()
	arazi_katmani_olustur()
	kontrol_noktalari_olustur()
	savas_sisi_katmani_olustur()
	ui_container_altyapi_olustur()
	_yan_hud_hazirla()
	hazirlik_paneli_olustur()
	savas_paneli_olustur()
	komut_menusu_olustur()
	minimap_olustur()
	birim_detay_popup_olustur()
	tekrar_oyna_butonu_olustur()
	hazirlik_baslat()
	_command_refs_sync()
	ui_fontlarini_optimize_et()

func kayit_yukle() -> void:
	var data = SaveSystem.load_game()
	kampanya_index = int(data.get("kampanya_index", 0))
	if kampanya_harita_idleri.size() > 0:
		kampanya_index = clampi(kampanya_index, 0, kampanya_harita_idleri.size() - 1)
	zorluk = str(data.get("zorluk", "orta"))
	if not zorluk_ayarlari.has(zorluk):
		zorluk = "orta"
	var terfi = data.get("terfi_verisi", {})
	if typeof(terfi) == TYPE_DICTIONARY:
		terfi_verisi = terfi
	var ist = data.get("istatistik", {})
	if typeof(ist) == TYPE_DICTIONARY:
		mac_istatistik_kayit = ist

func kayit_kaydet() -> void:
	SaveSystem.save_game({
		"kampanya_index": kampanya_index,
		"zorluk": zorluk,
		"terfi_verisi": terfi_verisi,
		"istatistik": mac_istatistik_kayit,
	})

func ui_node(name: String) -> Node:
	return ui_system.get_node_by_name(name)

func ui_fontlarini_optimize_et() -> void:
	var extras: Array = []
	if yan_hud_tetik != null:
		extras.append(yan_hud_tetik)
	if yan_hud_panel != null:
		extras.append(yan_hud_panel)
	if komut_menusu_panel != null:
		extras.append(komut_menusu_panel)
	if minimap_panel != null:
		extras.append(minimap_panel)
	if detay_popup_panel != null:
		extras.append(detay_popup_panel)
	if tekrar_oyna_btn != null:
		extras.append(tekrar_oyna_btn)
	ui_system.optimize_fonts(10, extras)

func ui_container_altyapi_olustur() -> void:
	ui_system.build_container_infrastructure()
	_ui_refs_sync()

func _envanter_anahtari(tip: Dictionary) -> String:
	var id = str(tip.get("id", ""))
	if id != "":
		return id
	return str(tip.get("isim", "birim"))

func takviye_gorunurluk_guncelle(acik: bool) -> void:
	if takviye_liste_satiri != null:
		takviye_liste_satiri.visible = acik
	if takviye_adet_satiri != null:
		takviye_adet_satiri.visible = acik

func takviye_ui_guncelle() -> void:
	if takviye_butonlari.is_empty():
		return
	for i in range(takviye_butonlari.size()):
		var btn = takviye_butonlari[i]
		if is_instance_valid(btn):
			btn.modulate = Color(1.35, 1.35, 1.0) if i == takviye_secili_idx else Color(1, 1, 1)
	var tip = osmanli_birim_tipleri[takviye_secili_idx]
	var maliyet = int(tip["maliyet"])
	var alinabilir = int(osmanli_altini / max(1, maliyet))
	takviye_secili_adet = clampi(takviye_secili_adet, 1, max(1, alinabilir))
	if takviye_adet_label != null:
		takviye_adet_label.text = "x" + str(takviye_secili_adet)
	if takviye_toplu_btn != null:
		takviye_toplu_btn.text = "Toplu Ekle (" + str(takviye_secili_adet * maliyet) + "🪙)"

func takviye_birim_sec(idx: int) -> void:
	if idx < 0 or idx >= osmanli_birim_tipleri.size():
		return
	takviye_secili_idx = idx
	takviye_secili_adet = 1
	takviye_ui_guncelle()

func takviye_adet_degistir(delta: int) -> void:
	var tip = osmanli_birim_tipleri[takviye_secili_idx]
	var maliyet = int(tip["maliyet"])
	var alinabilir = max(1, int(osmanli_altini / max(1, maliyet)))
	takviye_secili_adet = clampi(takviye_secili_adet + delta, 1, alinabilir)
	takviye_ui_guncelle()

func takviye_toplu_ekle() -> void:
	var tip = osmanli_birim_tipleri[takviye_secili_idx]
	var maliyet = int(tip["maliyet"])
	var alinabilir = int(osmanli_altini / max(1, maliyet))
	var adet = min(takviye_secili_adet, alinabilir)
	if adet <= 0:
		var s0 = ui_node("Label_SavasBilgi")
		if s0 != null:
			s0.text = "Yeterli altin yok!"
		return
	osmanli_altini -= maliyet * adet
	mac_istatistik["osmanli"]["altin_harcama"] += maliyet * adet
	for i in range(adet):
		envanter.append(tip.duplicate())
	envanter_olustur()
	var s1 = ui_node("Label_SavasBilgi")
	if s1 != null:
		s1.text = str(adet) + " " + tip["isim"] + " envantere eklendi"
	ui_guncelle()

func _yan_hud_goster() -> void:
	ui_system.show_side_hud()

func _yan_hud_kaybol_zamanla() -> void:
	ui_system.schedule_side_hud_hide()

func _yan_hud_kaybet() -> void:
	ui_system.hide_side_hud()

func _yan_hud_hazirla() -> void:
	ui_system.build_side_hud()
	_ui_refs_sync()

func hazirlik_eleman_ekle(tab: String, node: Control) -> void:
	ui_system.add_preparation_element(tab, node)
	_ui_refs_sync()

func hazirlik_tab_degistir(tab: String) -> void:
	ui_system.switch_preparation_tab(tab)
	_ui_refs_sync()

func terfi_ozet_metni() -> String:
	return HudFormatter.promotion_summary(terfi_verisi.get("osmanli", {}))

func hazirlik_bilgi_guncelle() -> void:
	var kampanya_l = ui_node("Label_Kampanya")
	if kampanya_l != null:
		kampanya_l.text = "Bolge: " + kampanya_bolgeleri[kampanya_index]
	var terfi_l = ui_node("Label_Terfi")
	if terfi_l != null:
		terfi_l.text = terfi_ozet_metni()
	var kayit_l = ui_node("Label_Kayit")
	if kayit_l != null:
		kayit_l.text = HudFormatter.save_stats(mac_istatistik_kayit)
	var zorluk_l = ui_node("Label_Zorluk")
	if zorluk_l != null:
		var isimler = {"kolay": "KOLAY", "orta": "ORTA", "zor": "ZOR"}
		zorluk_l.text = "Zorluk: " + isimler.get(zorluk, "ORTA")

func kontrol_noktalari_olustur() -> void:
	for nokta in nokta_konumlari:
		var kare = ColorRect.new()
		kare.color = Color.GRAY
		kare.size = Vector2(80, 80)
		kare.position = nokta_konumlari[nokta]
		kare.name = "Nokta_" + nokta
		add_child(kare)

		var isim_l = Label.new()
		isim_l.name = "Label_Nokta_" + nokta
		isim_l.text = nokta
		isim_l.position = nokta_konumlari[nokta] + Vector2(30, 30)
		add_child(isim_l)

		var bar_bg = ColorRect.new()
		bar_bg.name = "CaptureBg_" + nokta
		bar_bg.color = Color(0.5, 0, 0.8)
		bar_bg.size = Vector2(80, 10)
		bar_bg.position = nokta_konumlari[nokta] + Vector2(0, 85)
		add_child(bar_bg)

		var bar = ColorRect.new()
		bar.color = Color(1, 0.8, 0)
		bar.size = Vector2(40, 10)
		bar.position = nokta_konumlari[nokta] + Vector2(0, 85)
		bar.name = "CaptureBar_" + nokta
		add_child(bar)
		capture_barlar[nokta] = bar

		var puan_l = Label.new()
		puan_l.name = "Label_Puan_" + nokta
		puan_l.text = "+" + str(nokta_puan[nokta])
		puan_l.position = nokta_konumlari[nokta] + Vector2(30, -20)
		add_child(puan_l)

func hazirlik_paneli_olustur() -> void:
	ui_system.build_preparation_panel()
	_ui_refs_sync()

	# --- GENEL ---
	var zorluk_baslik = Label.new()
	zorluk_baslik.text = "ZORLUK"
	hazirlik_eleman_ekle("genel", zorluk_baslik)

	var zorluklar = [
		{"isim": "kolay", "text": "KOLAY"},
		{"isim": "orta", "text": "ORTA"},
		{"isim": "zor", "text": "ZOR"},
	]
	var zorluk_row = HBoxContainer.new()
	hazirlik_eleman_ekle("genel", zorluk_row)
	for z in zorluklar:
		var btn = Button.new()
		btn.text = z["text"]
		btn.custom_minimum_size = Vector2(90, 32)
		var z_isim = z["isim"]
		btn.pressed.connect(func(): zorluk_sec(z_isim))
		zorluk_row.add_child(btn)
		ui_system.register_preparation_widget(btn, "genel")
		zorluk_butonlari[z["isim"]] = btn

	var secili_l = Label.new()
	secili_l.name = "Label_Zorluk"
	secili_l.text = "Zorluk: ORTA"
	hazirlik_eleman_ekle("genel", secili_l)

	var kampanya_l = Label.new()
	kampanya_l.name = "Label_Kampanya"
	kampanya_l.text = "Bolge: Trakya"
	hazirlik_eleman_ekle("genel", kampanya_l)

	var terfi_l = Label.new()
	terfi_l.name = "Label_Terfi"
	terfi_l.text = "Terfi: yok"
	hazirlik_eleman_ekle("genel", terfi_l)

	var kayit_l = Label.new()
	kayit_l.name = "Label_Kayit"
	kayit_l.text = "G:0 M:0"
	hazirlik_eleman_ekle("genel", kayit_l)

	var ai_baslik = Label.new()
	ai_baslik.text = "DUSMAN ORDUSU"
	hazirlik_eleman_ekle("genel", ai_baslik)

	var ai_ordu_l = Label.new()
	ai_ordu_l.name = "Label_AiOrdu"
	ai_ordu_l.text = "Kuruluyor..."
	hazirlik_eleman_ekle("genel", ai_ordu_l)

	# --- ORDU ---
	var baslik = Label.new()
	baslik.text = "ORDU KUR"
	hazirlik_eleman_ekle("ordu", baslik)

	var lk = Label.new()
	lk.name = "Label_Kontenjan"
	lk.text = "Kontenjan: 30/30"
	hazirlik_eleman_ekle("ordu", lk)

	var birim_grid = GridContainer.new()
	birim_grid.columns = 3
	hazirlik_eleman_ekle("ordu", birim_grid)
	for i in range(osmanli_birim_tipleri.size()):
		var tip = osmanli_birim_tipleri[i]
		var grup = VBoxContainer.new()
		birim_grid.add_child(grup)
		ui_system.register_preparation_widget(grup, "ordu")
		var isim_l = Label.new()
		isim_l.text = tip["sembol"] + " " + tip["isim"] + " (" + str(tip["kontenjan"]) + "kt, " + str(tip["maliyet"]) + "🪙)"
		grup.add_child(isim_l)
		var hover_tip = tip
		isim_l.mouse_entered.connect(func(): birim_detay_hover_basla(hover_tip))
		isim_l.mouse_exited.connect(func(): birim_detay_hover_bitir())
		var satir_h = HBoxContainer.new()
		grup.add_child(satir_h)
		var btn_eksi = Button.new()
		btn_eksi.text = "-"
		btn_eksi.custom_minimum_size = Vector2(36, 32)
		var idx = i
		btn_eksi.pressed.connect(func(): kompozisyon_cikar(idx))
		btn_eksi.mouse_entered.connect(func(): birim_detay_hover_basla(hover_tip))
		btn_eksi.mouse_exited.connect(func(): birim_detay_hover_bitir())
		satir_h.add_child(btn_eksi)

		var sayi_l = Label.new()
		sayi_l.text = "0"
		sayi_l.name = "Komp_" + str(i)
		sayi_labellar.append(sayi_l)
		satir_h.add_child(sayi_l)

		var btn_arti = Button.new()
		btn_arti.text = "+"
		btn_arti.custom_minimum_size = Vector2(36, 32)
		btn_arti.pressed.connect(func(): kompozisyon_ekle(idx))
		btn_arti.mouse_entered.connect(func(): birim_detay_hover_basla(hover_tip))
		btn_arti.mouse_exited.connect(func(): birim_detay_hover_bitir())
		satir_h.add_child(btn_arti)

	# --- TAKTIK ---
	var formasyon_l = Label.new()
	formasyon_l.name = "Label_Formasyon"
	formasyon_l.text = "Formasyon: Dengeli"
	hazirlik_eleman_ekle("taktik", formasyon_l)

	var formasyonlar_ui = [
		{"id": "hucum", "text": "Hucum"},
		{"id": "savunma", "text": "Savunma"},
		{"id": "dengeli", "text": "Dengeli"},
	]
	var form_row = HBoxContainer.new()
	hazirlik_eleman_ekle("taktik", form_row)
	for f in formasyonlar_ui:
		var fbtn = Button.new()
		fbtn.text = f["text"]
		fbtn.custom_minimum_size = Vector2(96, 32)
		var f_id = f["id"]
		fbtn.pressed.connect(func(): formasyon_sec(f_id))
		form_row.add_child(fbtn)
		ui_system.register_preparation_widget(fbtn, "taktik")

	var kart_l = Label.new()
	kart_l.name = "Label_Kart"
	kart_l.text = "Kart (3'ten 1):"
	hazirlik_eleman_ekle("taktik", kart_l)

	var ekipman_l = Label.new()
	ekipman_l.name = "Label_Ekipman"
	ekipman_l.text = "Ekipman:"
	hazirlik_eleman_ekle("taktik", ekipman_l)

	var savas_btn = Button.new()
	savas_btn.name = "SavasBtn"
	savas_btn.text = "SAVASA BASLA"
	savas_btn.custom_minimum_size = Vector2(200, 42)
	savas_btn.pressed.connect(func(): savas_baslat())
	ui_system.add_preparation_footer(savas_btn)
	_ui_refs_sync()

func zorluk_sec(secilen: String) -> void:
	zorluk = secilen
	ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]
	for z in zorluk_butonlari:
		zorluk_butonlari[z].modulate = Color(1.5, 1.5, 1.5) if z == zorluk else Color(1, 1, 1)
	ai_ordu_hazirlik_sifirla()
	hazirlik_bilgi_guncelle()

func komut_sec(komut: String) -> void:
	var result = command_system.set_command_mode(komut)
	secili_komut = command_system.get_selected_command()
	_command_status_line_uygula(result)

func komut_menusu_olustur() -> void:
	komut_menusu_panel = ui_node("Panel_KomutMenu") as PanelContainer
	if komut_menusu_panel == null:
		komut_menusu_panel = PanelContainer.new()
		komut_menusu_panel.name = "Panel_KomutMenu"
		komut_menusu_panel.custom_minimum_size = Vector2(170, 156)
		komut_menusu_panel.visible = false
		$CanvasLayer.add_child(komut_menusu_panel)
	for c in komut_menusu_panel.get_children():
		c.queue_free()

	var menu_margin = MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 8)
	menu_margin.add_theme_constant_override("margin_right", 8)
	menu_margin.add_theme_constant_override("margin_top", 8)
	menu_margin.add_theme_constant_override("margin_bottom", 8)
	komut_menusu_panel.add_child(menu_margin)
	var menu_vbox = VBoxContainer.new()
	menu_margin.add_child(menu_vbox)

	var satir = [
		{"id": "saldir", "text": "⚔ Saldir"},
		{"id": "geri_cekil", "text": "↩ Geri Cekil"},
		{"id": "pusu", "text": "🌲 Pusu Kur"},
		{"id": "savun", "text": "🛡 Nokta Savun"},
	]
	for i in range(satir.size()):
		var btn = Button.new()
		btn.text = satir[i]["text"]
		btn.custom_minimum_size = Vector2(154, 30)
		var cmd = satir[i]["id"]
		btn.pressed.connect(func(): komut_menusu_komut_sec(cmd))
		menu_vbox.add_child(btn)

func komut_menusu_ac(ekran_pos: Vector2, birim: Dictionary) -> void:
	if komut_menusu_panel == null:
		return
	komut_menusu_hedef_birim = birim
	var view = get_viewport_rect().size
	var pos = ekran_pos
	if pos.x + komut_menusu_panel.size.x > view.x:
		pos.x = view.x - komut_menusu_panel.size.x - 8
	if pos.y + komut_menusu_panel.size.y > view.y:
		pos.y = view.y - komut_menusu_panel.size.y - 8
	komut_menusu_panel.position = pos
	komut_menusu_panel.visible = true

func komut_menusu_kapat() -> void:
	if komut_menusu_panel != null:
		komut_menusu_panel.visible = false
	komut_menusu_hedef_birim = null

func komut_menusu_komut_sec(komut: String) -> void:
	if komut_menusu_hedef_birim == null:
		komut_menusu_kapat()
		return
	secili_birim = komut_menusu_hedef_birim
	if komut == "saldir":
		secili_birim["savunma_modunda"] = false
		secili_birim["geri_cekiliyor"] = false
		secili_birim["takip_edilen_dusman"] = -1
		komut_sec("saldir")
	elif komut == "geri_cekil":
		birim_geri_cekil_baslat(secili_birim)
	elif komut == "pusu":
		birim_pusu_kur()
	elif komut == "savun":
		birim_nokta_savun(secili_birim)
	komut_menusu_kapat()

func minimap_olustur() -> void:
	minimap_panel = ui_node("MinimapPanel") as PanelContainer
	if minimap_panel == null:
		minimap_panel = PanelContainer.new()
		minimap_panel.name = "MinimapPanel"
		minimap_panel.custom_minimum_size = minimap_boyut
		minimap_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		minimap_panel.offset_left = -minimap_boyut.x - 12
		minimap_panel.offset_top = -minimap_boyut.y - 12
		minimap_panel.offset_right = -12
		minimap_panel.offset_bottom = -12
		ui_root.add_child(minimap_panel)

	var minimap_margin = ui_node("MinimapMargin") as MarginContainer
	if minimap_margin == null:
		minimap_margin = MarginContainer.new()
		minimap_margin.name = "MinimapMargin"
		minimap_margin.add_theme_constant_override("margin_left", 6)
		minimap_margin.add_theme_constant_override("margin_right", 6)
		minimap_margin.add_theme_constant_override("margin_top", 6)
		minimap_margin.add_theme_constant_override("margin_bottom", 6)
		minimap_panel.add_child(minimap_margin)

	var minimap_surface = ui_node("MinimapSurface") as ColorRect
	if minimap_surface == null:
		minimap_surface = ColorRect.new()
		minimap_surface.name = "MinimapSurface"
		minimap_surface.custom_minimum_size = minimap_boyut - Vector2(12, 12)
		minimap_surface.color = Color(0.08, 0.08, 0.08, 0.78)
		minimap_margin.add_child(minimap_surface)

	minimap_fow_rect = ui_node("MinimapFow") as TextureRect
	if minimap_fow_rect == null:
		minimap_fow_rect = TextureRect.new()
		minimap_fow_rect.name = "MinimapFow"
		minimap_fow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		minimap_fow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_fow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		minimap_surface.add_child(minimap_fow_rect)
	minimap_fow_rect.show_behind_parent = false

	minimap_kamera_rect = ui_node("MinimapKameraRect") as ColorRect
	if minimap_kamera_rect == null:
		minimap_kamera_rect = ColorRect.new()
		minimap_kamera_rect.name = "MinimapKameraRect"
		minimap_kamera_rect.size = Vector2(30, 18)
		minimap_kamera_rect.color = Color(1, 1, 1, 0.45)
		minimap_surface.add_child(minimap_kamera_rect)

	minimap_birim_osmanli = ui_node("MinimapBirimOsmanli") as ColorRect
	if minimap_birim_osmanli == null:
		minimap_birim_osmanli = ColorRect.new()
		minimap_birim_osmanli.name = "MinimapBirimOsmanli"
		minimap_birim_osmanli.size = Vector2(5, 5)
		minimap_birim_osmanli.color = Color.GOLD
		minimap_surface.add_child(minimap_birim_osmanli)

	minimap_birim_dogu_roma = ui_node("MinimapBirimDoguRoma") as ColorRect
	if minimap_birim_dogu_roma == null:
		minimap_birim_dogu_roma = ColorRect.new()
		minimap_birim_dogu_roma.name = "MinimapBirimDoguRoma"
		minimap_birim_dogu_roma.size = Vector2(5, 5)
		minimap_birim_dogu_roma.color = Color.PURPLE
		minimap_surface.add_child(minimap_birim_dogu_roma)

	for nokta in nokta_konumlari:
		var isaret = ColorRect.new()
		isaret.size = Vector2(4, 4)
		isaret.color = Color(0.7, 0.7, 0.7, 0.9)
		minimap_surface.add_child(isaret)
		minimap_nokta_isaretleri[nokta] = isaret

func minimap_dunya_to_panel(pos: Vector2) -> Vector2:
	var surface = ui_node("MinimapSurface")
	var panel_size = surface.size if surface != null else minimap_boyut
	var w = harita_sinir["max_x"] - harita_sinir["min_x"]
	var h = harita_sinir["max_y"] - harita_sinir["min_y"]
	if w <= 0 or h <= 0:
		return Vector2.ZERO
	return Vector2(
		((pos.x - harita_sinir["min_x"]) / w) * panel_size.x,
		((pos.y - harita_sinir["min_y"]) / h) * panel_size.y
	)

func minimap_panel_to_dunya(pos: Vector2) -> Vector2:
	var surface = ui_node("MinimapSurface")
	var panel_size = surface.size if surface != null else minimap_boyut
	var w = harita_sinir["max_x"] - harita_sinir["min_x"]
	var h = harita_sinir["max_y"] - harita_sinir["min_y"]
	return Vector2(
		harita_sinir["min_x"] + (pos.x / panel_size.x) * w,
		harita_sinir["min_y"] + (pos.y / panel_size.y) * h
	)

func minimap_fow_guncelle() -> void:
	if minimap_fow_rect == null:
		return
	fog_system.update_minimap_fow()
	minimap_fow_gorseli = fog_system.get_minimap_fow_image()
	minimap_fow_doku = fog_system.get_minimap_fow_texture()
	if minimap_fow_doku != null:
		minimap_fow_rect.texture = minimap_fow_doku

func minimap_guncelle() -> void:
	if minimap_panel == null:
		return
	minimap_fow_guncelle()
	for nokta in minimap_nokta_isaretleri:
		var isaret = minimap_nokta_isaretleri[nokta]
		if not is_instance_valid(isaret):
			continue
		isaret.position = minimap_dunya_to_panel(nokta_merkezi(nokta)) - Vector2(2, 2)
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
	minimap_birim_osmanli.visible = os_adet > 0
	minimap_birim_dogu_roma.visible = dr_adet > 0
	if os_adet > 0:
		minimap_birim_osmanli.position = minimap_dunya_to_panel(os_top / float(os_adet)) - Vector2(2, 2)
	if dr_adet > 0:
		minimap_birim_dogu_roma.position = minimap_dunya_to_panel(dr_top / float(dr_adet)) - Vector2(2, 2)

	if kamera != null and minimap_kamera_rect != null:
		var ekran = get_viewport_rect().size / kamera.zoom.x
		var top_left = kamera.position - ekran * 0.5
		var bot_right = kamera.position + ekran * 0.5
		var mini_tl = minimap_dunya_to_panel(top_left)
		var mini_br = minimap_dunya_to_panel(bot_right)
		minimap_kamera_rect.position = mini_tl
		minimap_kamera_rect.size = (mini_br - mini_tl).abs()

func formasyon_sec(formasyon: String) -> void:
	taraf_formasyon["osmanli"] = formasyon
	var adlar = {"hucum": "Hucum", "savunma": "Savunma", "dengeli": "Dengeli"}
	var l = ui_node("Label_Formasyon")
	if l != null:
		l.text = "Formasyon: " + adlar.get(formasyon, "Dengeli")

func birim_detay_popup_olustur() -> void:
	ui_system.set_unit_detail_text_provider(birim_detay_metni)
	ui_system.build_unit_detail_popup()
	_ui_refs_sync()

func _birim_detay_popup_konumla() -> void:
	ui_system.reposition_unit_detail_popup()

func _birim_detay_popup_goster(metin: String) -> void:
	ui_system.show_unit_detail_popup(metin)

func birim_detay_hover_basla(tip: Dictionary) -> void:
	ui_system.begin_unit_detail_hover(tip)

func birim_detay_hover_bitir() -> void:
	ui_system.end_unit_detail_hover()

func _liste_metni(arr: Array) -> String:
	if arr.is_empty():
		return "-"
	return ", ".join(arr)

func birim_detay_metni(tip: Dictionary) -> String:
	var isim = str(tip.get("isim", "Birim"))
	var guc = int(tip.get("guc", 0))
	var savunma = int(tip.get("savunma", 0))
	var hp = int(tip.get("hp", 0))
	var hiz = int(tip.get("hiz", 0))
	var menzil = int(tip.get("menzil", 0))
	var gorus = int(tip.get("gorus_yaricapi", menzil + normal_birim_gorus_bonus))
	var maliyet = int(tip.get("maliyet", 0))
	var kontenjan = int(tip.get("kontenjan", 0))
	var asker = int(tip.get("asker_sayisi", 0))
	var ustunluk = ustunluk_tablosu.get(isim, {})
	var guclu = _liste_metni(ustunluk.get("guclu", []))
	var zayif = _liste_metni(ustunluk.get("zayif", []))
	return "%s %s\nG:%d  S:%d  HP:%d\nHiz:%d  Menzil:%d  Gorus:%d\nMaliyet:%d  Kont:%d  Asker:%d\nGuclu: %s\nZayif: %s" % [
		str(tip.get("sembol", "•")),
		isim,
		guc,
		savunma,
		hp,
		hiz,
		menzil,
		gorus,
		maliyet,
		kontenjan,
		asker,
		guclu,
		zayif
	]

func birim_detay_goster(tip: Dictionary) -> void:
	_birim_detay_popup_goster(birim_detay_metni(tip))

func kart_secenekleri_hazirla() -> void:
	var eski_satir = ui_node("KartSecimSatiri")
	if eski_satir != null:
		eski_satir.queue_free()
	for btn in kart_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	kart_butonlari.clear()
	kart_secenekleri = MetaSystem.draw_cards(kart_havuzu, 3)
	var satir = HBoxContainer.new()
	satir.name = "KartSecimSatiri"
	hazirlik_eleman_ekle("taktik", satir)
	for i in range(kart_secenekleri.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(220, 30)
		btn.text = kart_secenekleri[i]["isim"]
		var kart = kart_secenekleri[i]
		btn.pressed.connect(func(): kart_sec(kart))
		satir.add_child(btn)
		ui_system.register_preparation_widget(btn, "taktik")
		kart_butonlari.append(btn)
	_ui_refs_sync()

func kart_sec(kart: Dictionary) -> void:
	secili_kart = kart
	for btn in kart_butonlari:
		if is_instance_valid(btn):
			btn.disabled = true
	var l = ui_node("Label_Kart")
	if l != null:
		l.text = "Kart: " + kart["isim"] + " (" + kart["aciklama"] + ")"

func ekipman_secimleri_hazirla() -> void:
	var eski_satir = ui_node("EkipmanSecimSatiri")
	if eski_satir != null:
		eski_satir.queue_free()
	for btn in ekipman_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	ekipman_butonlari.clear()
	var sirali = ["celik", "zirh", "durbun"]
	var satir = HBoxContainer.new()
	satir.name = "EkipmanSecimSatiri"
	hazirlik_eleman_ekle("taktik", satir)
	for i in range(sirali.size()):
		var anahtar = sirali[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(220, 28)
		btn.text = ekipmanlar[anahtar]["isim"]
		var e = anahtar
		btn.pressed.connect(func(): ekipman_sec(e))
		satir.add_child(btn)
		ui_system.register_preparation_widget(btn, "taktik")
		ekipman_butonlari.append(btn)
	_ui_refs_sync()

func ekipman_sec(anahtar: String) -> void:
	secili_ekipman = anahtar
	var l = ui_node("Label_Ekipman")
	if l != null:
		l.text = "Ekipman: " + ekipmanlar[anahtar]["isim"]
	for i in range(ekipman_butonlari.size()):
		var btn = ekipman_butonlari[i]
		if is_instance_valid(btn):
			btn.modulate = Color(1.4, 1.4, 0.8) if btn.text == ekipmanlar[anahtar]["isim"] else Color(1, 1, 1)

func kart_uygula(taraf: String, kart: Dictionary) -> void:
	if kart.is_empty():
		return
	if kart.has("moral"):
		taraf_moral[taraf] = clamp(taraf_moral[taraf] + kart["moral"], 0.0, 130.0)
	if kart.has("altin"):
		if taraf == "osmanli":
			osmanli_altini += int(kart["altin"])
		else:
			dogu_roma_altini += int(kart["altin"])
	if kart.has("guc"):
		taraf_carpanlari[taraf]["guc"] *= kart["guc"]
	if kart.has("savunma"):
		taraf_carpanlari[taraf]["savunma"] *= kart["savunma"]
	if kart.has("formasyon"):
		taraf_formasyon[taraf] = kart["formasyon"]

func ekipman_uygula(taraf: String, ekipman_key: String) -> void:
	if ekipman_key == "" or not ekipmanlar.has(ekipman_key):
		return
	var e = ekipmanlar[ekipman_key]
	taraf_carpanlari[taraf]["guc"] *= e["guc"]
	taraf_carpanlari[taraf]["savunma"] *= e["savunma"]
	taraf_carpanlari[taraf]["menzil"] *= e["menzil"]

func hiz_butonunu_guncelle() -> void:
	ui_system.refresh_speed_button(mevcut_hiz_carpani)

func hiz_carpani_sifirla() -> void:
	mevcut_hiz_carpani = 1.0
	Engine.time_scale = 1.0
	hiz_butonunu_guncelle()

func hiz_sec(carpan: float) -> void:
	if hazirlik_fazi or oyun_bitti:
		return
	mevcut_hiz_carpani = carpan
	Engine.time_scale = carpan
	hiz_butonunu_guncelle()

func hiz_carpani_arttir() -> void:
	if hazirlik_fazi or oyun_bitti:
		return
	var sirali = [1.0, 2.0, 4.0, 6.0, 8.0]
	var idx = 0
	for i in range(sirali.size()):
		if is_equal_approx(float(sirali[i]), mevcut_hiz_carpani):
			idx = i
			break
	var sonraki = float(sirali[(idx + 1) % sirali.size()])
	hiz_sec(sonraki)

func savas_paneli_olustur() -> void:
	ui_system.clear_battle_panel()
	ui_system.build_battle_panel_skeleton(func(): ult_kullan("osmanli"))
	_ui_refs_sync()

	var satin_baslik = Label.new()
	satin_baslik.text = "Takviye:"
	ui_system.add_battle_panel_element(satin_baslik)

	var satin_toggle_satir = HBoxContainer.new()
	ui_system.add_battle_panel_element(satin_toggle_satir)

	var satin_toggle_btn = Button.new()
	satin_toggle_btn.text = "Birim Ekle"
	satin_toggle_btn.custom_minimum_size = Vector2(120, 28)
	satin_toggle_btn.pressed.connect(func():
		var yeni = not (takviye_liste_satiri != null and takviye_liste_satiri.visible)
		takviye_gorunurluk_guncelle(yeni)
	)
	satin_toggle_satir.add_child(satin_toggle_btn)
	ui_system.register_battle_panel_widget(satin_toggle_btn)

	takviye_liste_satiri = HBoxContainer.new()
	takviye_liste_satiri.visible = false
	ui_system.add_battle_panel_element(takviye_liste_satiri)
	takviye_butonlari.clear()
	for i in range(osmanli_birim_tipleri.size()):
		var tip = osmanli_birim_tipleri[i]
		var btn = Button.new()
		btn.text = tip["sembol"] + " " + str(tip["maliyet"]) + "🪙"
		btn.custom_minimum_size = Vector2(78, 28)
		var idx = i
		btn.pressed.connect(func(): takviye_birim_sec(idx))
		var hover_tip = tip
		btn.mouse_entered.connect(func(): birim_detay_hover_basla(hover_tip))
		btn.mouse_exited.connect(func(): birim_detay_hover_bitir())
		takviye_liste_satiri.add_child(btn)
		takviye_butonlari.append(btn)
		ui_system.register_battle_panel_widget(btn)

	takviye_adet_satiri = HBoxContainer.new()
	takviye_adet_satiri.visible = false
	ui_system.add_battle_panel_element(takviye_adet_satiri)
	var satin_adet_baslik = Label.new()
	satin_adet_baslik.text = "Adet:"
	takviye_adet_satiri.add_child(satin_adet_baslik)
	ui_system.register_battle_panel_widget(satin_adet_baslik)
	var satin_eksi = Button.new()
	satin_eksi.text = "-"
	satin_eksi.custom_minimum_size = Vector2(26, 26)
	satin_eksi.pressed.connect(func(): takviye_adet_degistir(-1))
	takviye_adet_satiri.add_child(satin_eksi)
	ui_system.register_battle_panel_widget(satin_eksi)
	takviye_adet_label = Label.new()
	takviye_adet_label.text = "x1"
	takviye_adet_satiri.add_child(takviye_adet_label)
	ui_system.register_battle_panel_widget(takviye_adet_label)
	var satin_arti = Button.new()
	satin_arti.text = "+"
	satin_arti.custom_minimum_size = Vector2(26, 26)
	satin_arti.pressed.connect(func(): takviye_adet_degistir(1))
	takviye_adet_satiri.add_child(satin_arti)
	ui_system.register_battle_panel_widget(satin_arti)
	takviye_toplu_btn = Button.new()
	takviye_toplu_btn.text = "Toplu Ekle"
	takviye_toplu_btn.custom_minimum_size = Vector2(120, 26)
	takviye_toplu_btn.pressed.connect(func(): takviye_toplu_ekle())
	takviye_adet_satiri.add_child(takviye_toplu_btn)
	ui_system.register_battle_panel_widget(takviye_toplu_btn)
	takviye_ui_guncelle()

	var env_baslik = Label.new()
	env_baslik.name = "Label_Envanter"
	env_baslik.text = "Envanter: (bos)"
	ui_system.add_battle_panel_element(env_baslik)

	envanter_grid = GridContainer.new()
	envanter_grid.columns = 6
	ui_system.add_battle_panel_element(envanter_grid)

	envanter_adet_satiri = HBoxContainer.new()
	envanter_adet_satiri.visible = false
	ui_system.add_battle_panel_element(envanter_adet_satiri)

	var adet_baslik = Label.new()
	adet_baslik.text = "Gonder:"
	envanter_adet_satiri.add_child(adet_baslik)
	ui_system.register_battle_panel_widget(adet_baslik)

	envanter_adet_eksi_btn = Button.new()
	envanter_adet_eksi_btn.text = "-"
	envanter_adet_eksi_btn.custom_minimum_size = Vector2(28, 28)
	envanter_adet_eksi_btn.pressed.connect(func():
		secili_envanter_gonder_adedi = max(1, secili_envanter_gonder_adedi - 1)
		_envanter_secim_ui_guncelle()
	)
	envanter_adet_satiri.add_child(envanter_adet_eksi_btn)
	ui_system.register_battle_panel_widget(envanter_adet_eksi_btn)

	envanter_adet_label = Label.new()
	envanter_adet_label.text = "x1"
	envanter_adet_satiri.add_child(envanter_adet_label)
	ui_system.register_battle_panel_widget(envanter_adet_label)

	envanter_adet_arti_btn = Button.new()
	envanter_adet_arti_btn.text = "+"
	envanter_adet_arti_btn.custom_minimum_size = Vector2(28, 28)
	envanter_adet_arti_btn.pressed.connect(func():
		var max_adet = _envanter_secili_grup_indeksleri().size()
		secili_envanter_gonder_adedi = min(max_adet, secili_envanter_gonder_adedi + 1)
		_envanter_secim_ui_guncelle()
	)
	envanter_adet_satiri.add_child(envanter_adet_arti_btn)
	ui_system.register_battle_panel_widget(envanter_adet_arti_btn)

	var gel_baslik = Label.new()
	gel_baslik.text = "Nokta +"
	ui_system.add_battle_panel_element(gel_baslik)

	var gel_satir = HBoxContainer.new()
	ui_system.add_battle_panel_element(gel_satir)
	var sirali_noktalar = ["A", "B", "C", "D", "E"]
	for nokta in sirali_noktalar:
		if not nokta_konumlari.has(nokta):
			continue
		var gbtn = Button.new()
		gbtn.name = "Gel_" + nokta
		gbtn.text = nokta
		gbtn.custom_minimum_size = Vector2(44, 32)
		var n = nokta
		gbtn.pressed.connect(func(): nokta_gelistir(n))
		gel_satir.add_child(gbtn)
		ui_system.register_battle_panel_widget(gbtn)

	ui_system.build_battle_panel_footer(func(): hiz_carpani_arttir())
	_ui_refs_sync()
	hiz_butonunu_guncelle()

	for el in savas_paneli:
		if is_instance_valid(el):
			el.visible = false
	ui_fontlarini_optimize_et()

func tekrar_oyna_butonu_olustur() -> void:
	tekrar_oyna_btn = Button.new()
	tekrar_oyna_btn.name = "TekrarOynaBtn"
	tekrar_oyna_btn.text = "🔄 TEKRAR OYNA"
	tekrar_oyna_btn.position = Vector2(820, 600)
	tekrar_oyna_btn.size = Vector2(180, 45)
	tekrar_oyna_btn.visible = false
	tekrar_oyna_btn.pressed.connect(func(): tekrar_oyna())
	$CanvasLayer.add_child(tekrar_oyna_btn)

func kompozisyon_toplami() -> int:
	var toplam = 0
	for sayi in kompozisyon:
		toplam += sayi
	return toplam

func kompozisyon_ekle(idx: int) -> void:
	var tip = osmanli_birim_tipleri[idx]
	if mevcut_kontenjan < tip["kontenjan"]:
		return
	mevcut_kontenjan -= tip["kontenjan"]
	kompozisyon[idx] += 1
	sayi_labellar[idx].text = str(kompozisyon[idx])
	var kont_l = ui_node("Label_Kontenjan")
	if kont_l != null:
		kont_l.text = "Kontenjan: " + str(mevcut_kontenjan) + "/" + str(max_kontenjan) + " | Ordu: " + str(kompozisyon_toplami())

func kompozisyon_cikar(idx: int) -> void:
	if kompozisyon[idx] <= 0:
		return
	var tip = osmanli_birim_tipleri[idx]
	mevcut_kontenjan += tip["kontenjan"]
	kompozisyon[idx] -= 1
	sayi_labellar[idx].text = str(kompozisyon[idx])
	var kont_l2 = ui_node("Label_Kontenjan")
	if kont_l2 != null:
		kont_l2.text = "Kontenjan: " + str(mevcut_kontenjan) + "/" + str(max_kontenjan) + " | Ordu: " + str(kompozisyon_toplami())

func _envanter_secili_grup_indeksleri() -> Array:
	if secili_envanter_tip_anahtari == "" or not envanter_gruplari.has(secili_envanter_tip_anahtari):
		return []
	return (envanter_gruplari[secili_envanter_tip_anahtari]["indeksler"] as Array).duplicate()

func _envanter_secili_tip() -> Dictionary:
	if secili_envanter_tip_anahtari == "" or not envanter_gruplari.has(secili_envanter_tip_anahtari):
		return {}
	return envanter_gruplari[secili_envanter_tip_anahtari]["tip"]

func _envanter_secim_ui_guncelle() -> void:
	var secili_indeksler = _envanter_secili_grup_indeksleri()
	var secili_toplam = secili_indeksler.size()
	if envanter_adet_satiri != null:
		envanter_adet_satiri.visible = secili_toplam > 0
	if secili_toplam <= 0:
		secili_envanter_idx = -1
		secili_envanter_tip_anahtari = ""
		secili_envanter_gonder_adedi = 1
		return
	secili_envanter_idx = int(secili_indeksler[0])
	secili_envanter_gonder_adedi = clampi(secili_envanter_gonder_adedi, 1, secili_toplam)
	if envanter_adet_label != null:
		envanter_adet_label.text = "x" + str(secili_envanter_gonder_adedi)
	if envanter_adet_eksi_btn != null:
		envanter_adet_eksi_btn.disabled = secili_envanter_gonder_adedi <= 1
	if envanter_adet_arti_btn != null:
		envanter_adet_arti_btn.disabled = secili_envanter_gonder_adedi >= secili_toplam

func envanter_olustur() -> void:
	for btn in envanter_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	envanter_butonlari.clear()
	envanter_gruplari.clear()

	if envanter_grid == null:
		return
	for child in envanter_grid.get_children():
		child.queue_free()

	if envanter.is_empty():
		secili_envanter_idx = -1
		secili_envanter_tip_anahtari = ""
		secili_envanter_gonder_adedi = 1
		_envanter_secim_ui_guncelle()
		var env_l = ui_node("Label_Envanter")
		if env_l != null:
			env_l.text = "Envanter: (bos)"
		return

	var sira: Array = []
	for i in range(envanter.size()):
		var tip = envanter[i]
		var anahtar = _envanter_anahtari(tip)
		if not envanter_gruplari.has(anahtar):
			envanter_gruplari[anahtar] = {"tip": tip, "indeksler": []}
			sira.append(anahtar)
		(envanter_gruplari[anahtar]["indeksler"] as Array).append(i)

	for anahtar in sira:
		var grup = envanter_gruplari[anahtar]
		var tip = grup["tip"]
		var adet = (grup["indeksler"] as Array).size()
		var btn = Button.new()
		btn.text = str(tip.get("sembol", "•"))
		btn.custom_minimum_size = Vector2(72, 42)
		btn.clip_text = true
		btn.pressed.connect(func(): envanter_sec(anahtar))
		var hover_tip = tip
		btn.mouse_entered.connect(func(): birim_detay_hover_basla(hover_tip))
		btn.mouse_exited.connect(func(): birim_detay_hover_bitir())
		var adet_l = Label.new()
		adet_l.text = "x" + str(adet)
		adet_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		adet_l.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		adet_l.offset_left = -28
		adet_l.offset_top = 2
		adet_l.offset_right = -2
		adet_l.offset_bottom = 18
		btn.add_child(adet_l)
		envanter_grid.add_child(btn)
		envanter_butonlari.append(btn)

	var env_l2 = ui_node("Label_Envanter")
	if env_l2 != null:
		env_l2.text = "Envanter: " + str(envanter.size()) + " birim"

	if secili_envanter_tip_anahtari == "" or not envanter_gruplari.has(secili_envanter_tip_anahtari):
		secili_envanter_tip_anahtari = str(sira[0]) if not sira.is_empty() else ""
		secili_envanter_gonder_adedi = 1
	_envanter_secim_ui_guncelle()
	ui_fontlarini_optimize_et()

func envanter_sec(anahtar: String) -> void:
	if not envanter_gruplari.has(anahtar):
		return
	secili_envanter_tip_anahtari = anahtar
	secili_envanter_gonder_adedi = 1
	_envanter_secim_ui_guncelle()
	secili_birim = null
	var tip = envanter_gruplari[anahtar]["tip"]
	birim_detay_goster(tip)
	var s = ui_node("Label_SavasBilgi")
	if s != null:
		var adet = _envanter_secili_grup_indeksleri().size()
		s.text = "Secili: " + tip["isim"] + " (x" + str(adet) + ") — + / - ile adet, haritaya tikla"

func nokta_sec(nokta: String) -> void:
	secili_nokta = nokta
	nokta_vurgula()
	var s2 = ui_node("Label_SavasBilgi")
	if secili_envanter_tip_anahtari != "" and s2 != null:
		s2.text = "Nokta " + nokta + " secildi — haritaya tikla"

func nokta_vurgula() -> void:
	for nokta in nokta_konumlari:
		var kare = get_node("Nokta_" + nokta)
		kare.modulate = Color(1.5, 1.5, 1.5) if nokta == secili_nokta else Color(1, 1, 1)

func nokta_merkezi(nokta: String) -> Vector2:
	return nokta_konumlari[nokta] + Vector2(40, 40)

func harita_sinirla(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, harita_sinir["min_x"], harita_sinir["max_x"]),
		clamp(pos.y, harita_sinir["min_y"], harita_sinir["max_y"])
	)

func en_yakin_nokta_bul(pos: Vector2) -> String:
	var en_yakin = nokta_konumlari.keys()[0] if nokta_konumlari.size() > 0 else "A"
	var en_kisa = 999999.0
	for nokta in nokta_konumlari:
		var d = pos.distance_to(nokta_merkezi(nokta))
		if d < en_kisa:
			en_kisa = d
			en_yakin = nokta
	return en_yakin

func nokta_oncelik_listesi() -> Array:
	var sirali: Array = []
	for nokta in ["C", "A", "B", "D", "E"]:
		if nokta_konumlari.has(nokta):
			sirali.append(nokta)
	for nokta in nokta_konumlari.keys():
		if not sirali.has(nokta):
			sirali.append(nokta)
	return sirali

func nokta_taban_puan(nokta: String) -> int:
	return 3 if nokta == "C" else 1

func nokta_taban_altin(nokta: String) -> int:
	return 6 if nokta == "C" else 3

func birim_nokta_menzilinde(birim: Dictionary, nokta: String) -> bool:
	var etkiler = birim_etkin_degerleri(birim)
	return birim["konum"].distance_to(nokta_merkezi(nokta)) <= etkiler["menzil"]

func noktadaki_taraf_sayisi(nokta: String, taraf: String) -> int:
	var say = 0
	for b in aktif_birimler:
		if b["hp"] <= 0 or b["taraf"] != taraf:
			continue
		if birim_nokta_menzilinde(b, nokta):
			say += 1
	return say

func birim_konumu_hesapla(nokta: String, taraf: String) -> Vector2:
	var taraf_sayisi = 0
	for b in aktif_birimler:
		if b["hp"] <= 0 or b["taraf"] != taraf:
			continue
		if b["hedef_nokta"] == nokta:
			taraf_sayisi += 1

	var sutun = taraf_sayisi % 5
	var satir = taraf_sayisi / 5

	if taraf == "osmanli":
		# Osmanlı aşağıda
		return Vector2(
			nokta_konumlari[nokta].x - 60 + sutun * 35,
			nokta_konumlari[nokta].y + 100 + satir * 35
		)
	else:
		# Doğu Roma yukarıda
		return Vector2(
			nokta_konumlari[nokta].x - 60 + sutun * 35,
			nokta_konumlari[nokta].y - 120 - satir * 35
		)

func birimi_gonder() -> void:
	if secili_nokta == "":
		print("Once nokta sec!")
		return
	var secili_indeksler = _envanter_secili_grup_indeksleri()
	if secili_indeksler.is_empty():
		print("Once birim sec!")
		return

	var adet = min(secili_envanter_gonder_adedi, secili_indeksler.size())
	var tip = _envanter_secili_tip()
	secili_indeksler.sort()
	for i in range(adet):
		var sil_idx = int(secili_indeksler[secili_indeksler.size() - 1 - i])
		envanter.remove_at(sil_idx)
	secili_envanter_idx = -1
	secili_envanter_tip_anahtari = ""
	secili_envanter_gonder_adedi = 1
	var s3 = ui_node("Label_SavasBilgi")
	if s3 != null:
		s3.text = str(adet) + " birim gonderildi"

	var hedef_pos = birim_konumu_hesapla(secili_nokta, "osmanli")
	var oyuncu_spawn_y = harita_sinir["max_y"] - 60.0
	for i in range(adet):
		var dagilim = Vector2(float((i % 3) - 1) * 24.0, float(i / 3) * 22.0)
		birim_olustur(
			Vector2(nokta_konumlari[secili_nokta].x + dagilim.x, oyuncu_spawn_y),
			secili_nokta, "osmanli", tip, hedef_pos + dagilim
		)
	envanter_olustur()

func birim_haritadan_gonder(hedef_pos: Vector2) -> void:
	var secili_indeksler = _envanter_secili_grup_indeksleri()
	if secili_indeksler.is_empty():
		return

	hedef_pos = harita_sinirla(hedef_pos)
	var adet = min(secili_envanter_gonder_adedi, secili_indeksler.size())
	var tip = _envanter_secili_tip()
	secili_indeksler.sort()
	for i in range(adet):
		var sil_idx = int(secili_indeksler[secili_indeksler.size() - 1 - i])
		envanter.remove_at(sil_idx)
	secili_envanter_idx = -1
	secili_envanter_tip_anahtari = ""
	secili_envanter_gonder_adedi = 1
	var s4 = ui_node("Label_SavasBilgi")
	if s4 != null:
		s4.text = str(adet) + " birim gonderildi"

	var nokta = en_yakin_nokta_bul(hedef_pos)
	var oyuncu_spawn_y = harita_sinir["max_y"] - 60.0
	for i in range(adet):
		var dagilim = Vector2(float((i % 3) - 1) * 24.0, float(i / 3) * 22.0)
		birim_olustur(
			Vector2(hedef_pos.x + dagilim.x, oyuncu_spawn_y),
			nokta, "osmanli", tip, hedef_pos + dagilim
		)
	envanter_olustur()

func birim_satin_al(idx: int) -> void:
	var tip = osmanli_birim_tipleri[idx]
	if osmanli_altini < tip["maliyet"]:
		print("Yeterli altin yok!")
		return
	osmanli_altini -= tip["maliyet"]
	mac_istatistik["osmanli"]["altin_harcama"] += int(tip["maliyet"])
	envanter.append(tip.duplicate())
	envanter_olustur()
	ui_guncelle()

func hazirlik_baslat() -> void:
	hiz_carpani_sifirla()
	kampanya_haritasini_yukle()
	hazirlik_fazi = true
	kalan_sure = hazirlik_suresi
	mevcut_kontenjan = max_kontenjan
	kompozisyon_dizisi_sifirla()
	envanter.clear()
	secili_nokta = ""
	secili_envanter_idx = -1
	secili_envanter_tip_anahtari = ""
	secili_envanter_gonder_adedi = 1
	secili_birim = null
	secili_komut = "hareket"
	komut_menusu_kapat()
	nokta_gelistirme.clear()
	nokta_capture.clear()
	nokta_sahipleri.clear()
	kesfedilen_noktalar.clear()
	nokta_son_bilgi.clear()
	fog_system.reset_enemy_intel()
	_fog_refs_sync()
	for nokta in nokta_konumlari:
		nokta_capture[nokta] = 50.0
		nokta_sahipleri[nokta] = "tarafsiz"
		nokta_gelistirme[nokta] = 0
		kesfedilen_noktalar[nokta] = false
		nokta_son_bilgi[nokta] = {"sahip": "tarafsiz", "capture": 50.0}
	osmanli_puani = 0
	dogu_roma_puani = 0
	osmanli_altini = zorluk_ayarlari[zorluk]["oyuncu_altin"]
	dogu_roma_altini = zorluk_ayarlari[zorluk]["ai_altin"]
	osmanli_gelisim_altini = 0
	dogu_roma_gelisim_altini = 0
	oyun_suresi = 0.0
	puan_timer = 0.0
	oyun_bitti = false
	ai_spawn_timer = 0.0
	ai_dalga_sayisi = 0
	ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]
	ai_envanter.clear()
	ai_ordu_hazirlik_sifirla()
	taraf_moral = {"osmanli": 100.0, "dogu_roma": 100.0}
	taraf_formasyon = {"osmanli": "dengeli", "dogu_roma": "dengeli"}
	ult_sarj = {"osmanli": 0.0, "dogu_roma": 0.0}
	ult_aktif_sure = {"osmanli": 0.0, "dogu_roma": 0.0}
	hava_durumu = "Acik"
	mac_istatistik = {
		"osmanli": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
		"dogu_roma": {"oldurme": 0, "kayip": 0, "hasar": 0.0, "altin_harcama": 0, "nokta_sure": 0.0},
	}
	taraf_carpanlari = {
		"osmanli": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0},
		"dogu_roma": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0}
	}
	secili_kart = {}
	secili_ekipman = ""
	var lf = ui_node("Label_Formasyon")
	if lf != null:
		lf.text = "Formasyon: Dengeli"
	var le = ui_node("Label_Ekipman")
	if le != null:
		le.text = "Ekipman:"
	var lk = ui_node("Label_Kart")
	if lk != null:
		lk.text = "Kart (3'ten 1):"
	var lm = ui_node("Label_MacOzeti")
	if lm != null:
		lm.text = ""
	hazirlik_bilgi_guncelle()
	kart_secenekleri_hazirla()
	ekipman_secimleri_hazirla()
	ekipman_sec("celik")
	ai_secili_kart = kart_havuzu[randi() % kart_havuzu.size()]
	var ai_ek_keys = ["celik", "zirh", "durbun"]
	ai_secili_ekipman = ai_ek_keys[randi() % ai_ek_keys.size()]

	for birim in aktif_birimler:
		if is_instance_valid(birim["node"]):
			birim["node"].queue_free()
	aktif_birimler.clear()

	for btn in envanter_butonlari:
		if is_instance_valid(btn):
			btn.queue_free()
	envanter_butonlari.clear()

	for i in range(sayi_labellar.size()):
		sayi_labellar[i].text = "0"
	var kont_l = ui_node("Label_Kontenjan")
	if kont_l != null:
		kont_l.text = "Kontenjan: " + str(max_kontenjan) + "/" + str(max_kontenjan) + " | Ordu: 0"

	if is_instance_valid(tekrar_oyna_btn):
		tekrar_oyna_btn.visible = false

	_ui_refs_sync()
	for el in hazirlik_paneli:
		if is_instance_valid(el):
			el.visible = true
	if hazirlik_panel_root != null:
		hazirlik_panel_root.visible = true
	hazirlik_tab_degistir("genel")
	for z in zorluk_butonlari:
		zorluk_butonlari[z].modulate = Color(1.5, 1.5, 1.5) if z == zorluk else Color(1, 1, 1)
	for el in savas_paneli:
		if is_instance_valid(el):
			el.visible = false
	if savas_panel_root != null:
		savas_panel_root.visible = false
	komut_sec("hareket")
	if is_instance_valid(gorus_hucre_katmani):
		gorus_hucre_katmani.visible = false
	savas_sisi_hucrelerini_sifirla()
	nokta_gorunurluklerini_guncelle()
	nokta_renkleri_sifirla()
	if kamera != null:
		kamera.position = Vector2((harita_sinir["min_x"] + harita_sinir["max_x"]) * 0.5, (harita_sinir["min_y"] + harita_sinir["max_y"]) * 0.5)
		kamera.zoom = Vector2(0.7, 0.7)
		kamera_sinirla()
	ui_guncelle()

func savas_baslat() -> void:
	if oyun_bitti:
		return
	if kompozisyon_toplami() <= 0:
		hazirlik_tab_degistir("ordu")
		var kont_l2 = ui_node("Label_Kontenjan")
		if kont_l2 != null:
			kont_l2.text = "En az 1 birim sec!"
		return
	hazirlik_fazi = false
	kalan_sure = max_sure
	ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]

	for i in range(osmanli_birim_tipleri.size()):
		for j in range(kompozisyon[i]):
			envanter.append(osmanli_birim_tipleri[i].duplicate())

	ai_savas_envanteri_hazirla()
	if secili_kart.is_empty():
		kart_sec(kart_secenekleri[0] if kart_secenekleri.size() > 0 else {})
	if secili_ekipman == "":
		ekipman_sec("celik")
	kart_uygula("osmanli", secili_kart)
	kart_uygula("dogu_roma", ai_secili_kart)
	ekipman_uygula("osmanli", secili_ekipman)
	ekipman_uygula("dogu_roma", ai_secili_ekipman)
	hava_sec()
	general_olustur("osmanli")
	general_olustur("dogu_roma")

	for el in hazirlik_paneli:
		if is_instance_valid(el):
			el.visible = false
	if hazirlik_panel_root != null:
		hazirlik_panel_root.visible = false
	for el in savas_paneli:
		if is_instance_valid(el):
			el.visible = true
	if savas_panel_root != null:
		savas_panel_root.visible = true
	if is_instance_valid(gorus_hucre_katmani):
		gorus_hucre_katmani.visible = true

	envanter_olustur()
	komut_sec("hareket")
	if kamera != null and nokta_konumlari.has("C"):
		kamera.position = nokta_merkezi("C")
		kamera_sinirla()
	savas_sisi_guncelle()
	nokta_gorunurluklerini_guncelle()
	birim_gorunurluklerini_guncelle()
	ui_guncelle()
	ai_spawn_timer = ai_spawn_suresi * 0.4
	print("=== SAVAS BASLADI === Zorluk: " + zorluk)

func hava_sec() -> void:
	var olasi = ["Acik", "Yagmur", "Sis", "Ruzgar"]
	hava_durumu = olasi[randi() % olasi.size()]

func moral_degistir(taraf: String, miktar: float) -> void:
	taraf_moral[taraf] = CombatSystem.change_moral(taraf_moral[taraf], miktar)

func taraf_moral_carpani(taraf: String) -> float:
	return CombatSystem.moral_multiplier(taraf_moral[taraf])

func general_hayatta_mi(taraf: String) -> bool:
	for b in aktif_birimler:
		if b["taraf"] == taraf and b["hp"] > 0 and b.get("is_general", false):
			return true
	return false

func general_getir(taraf: String) -> Dictionary:
	for b in aktif_birimler:
		if b["taraf"] == taraf and b["hp"] > 0 and b.get("is_general", false):
			return b
	return {}

func general_olustur(taraf: String) -> void:
	var tip = {
		"isim": "General",
		"hiz": 36.0,
		"renk": Color(1, 0.9, 0.35) if taraf == "osmanli" else Color(0.75, 0.55, 1),
		"sembol": "⭐",
		"guc": 30,
		"savunma": 20,
		"hp": 120,
		"asker_sayisi": 1,
		"menzil": 100.0,
		"is_general": true,
		"aura_menzil": 190.0,
		"aura_guc": 1.1,
		"aura_savunma": 1.1
	}
	var merkez_x = (harita_sinir["min_x"] + harita_sinir["max_x"]) * 0.5
	var baslangic = Vector2(merkez_x - 220.0, harita_sinir["max_y"] - 140.0) if taraf == "osmanli" else Vector2(merkez_x + 220.0, harita_sinir["min_y"] + 140.0)
	var hedef = baslangic + Vector2(60, -40) if taraf == "osmanli" else baslangic + Vector2(-60, 40)
	birim_olustur(baslangic, en_yakin_nokta_bul(hedef), taraf, tip, hedef)

func taraf_formasyon_carpani(taraf: String, stat: String) -> float:
	return CombatSystem.formation_multiplier(formasyonlar, taraf_formasyon, taraf, stat)

func terfi_seviyesi_getir(taraf: String, isim: String) -> int:
	return MetaSystem.get_promotion_level(terfi_verisi.get(taraf, {}), isim)

func terfi_kullanimi_artir(taraf: String, isim: String) -> void:
	terfi_verisi[taraf] = MetaSystem.update_promotion_state(terfi_verisi[taraf], isim)

func ult_kullan(taraf: String) -> void:
	if ult_sarj[taraf] < 100.0 or ult_aktif_sure[taraf] > 0.0:
		return
	ult_sarj[taraf] = 0.0
	ult_aktif_sure[taraf] = 10.0
	moral_degistir(taraf, 8.0)

func _dar_koridor_merkez(rect: Rect2) -> Vector2:
	return rect.position + rect.size * 0.5

func _birim_suvari_mi(birim: Dictionary) -> bool:
	return suvari_isimleri.has(str(birim.get("isim", "")))

func birim_etkin_degerleri(birim: Dictionary) -> Dictionary:
	var taraf = birim["taraf"]
	var general = general_getir(taraf)
	var weather = hava_durumu_efektleri.get(hava_durumu, hava_durumu_efektleri["Acik"])
	var level = terfi_seviyesi_getir(taraf, birim["isim"])
	var etkiler = CombatSystem.effective_stats(
		birim,
		taraf_formasyon,
		formasyonlar,
		taraf_moral,
		taraf_carpanlari,
		weather,
		ult_aktif_sure,
		general,
		level
	)
	var arazi = birimin_arazisini_bul(birim["konum"])
	var tip = str(arazi.get("tip", "duz_arazi"))
	if tip in ["tepe", "kopru"]:
		var sav = float(arazi.get("savunma_bonus", 1.0))
		etkiler["savunma"] = max(1, int(round(float(etkiler["savunma"]) * sav)))
	if tip in ["vadi", "yol"]:
		var hiz_bonus = float(arazi.get("hiz_bonus", 1.0))
		etkiler["hiz"] = max(8.0, float(etkiler["hiz"]) * hiz_bonus)
	if tip == "dar_gecit" and _birim_suvari_mi(birim):
		var yavas = float(arazi.get("suvari_yavaslama", 0.5))
		etkiler["hiz"] = max(8.0, float(etkiler["hiz"]) * yavas)
	return etkiler

func birim_olustur(baslangic: Vector2, hedef_nokta: String, taraf: String, tip: Dictionary, hedef_konum: Vector2 = Vector2(-1, -1)) -> void:
	var kare = ColorRect.new()
	kare.color = tip["renk"]
	kare.size = Vector2(30, 30)
	kare.position = baslangic
	add_child(kare)

	var sembol = Label.new()
	sembol.text = tip["sembol"]
	sembol.position = Vector2(5, 5)
	kare.add_child(sembol)

	var asker_l = Label.new()
	asker_l.name = "AskerSayisi"
	asker_l.text = str(tip["asker_sayisi"])
	asker_l.position = Vector2(0, -18)
	kare.add_child(asker_l)

	var hp_bg = ColorRect.new()
	hp_bg.color = Color.RED
	hp_bg.size = Vector2(30, 4)
	hp_bg.position = Vector2(0, -6)
	kare.add_child(hp_bg)

	var hp_bar = ColorRect.new()
	hp_bar.color = Color.GREEN
	hp_bar.size = Vector2(30, 4)
	hp_bar.position = Vector2(0, -6)
	hp_bar.name = "HPBar"
	kare.add_child(hp_bar)

	var gidilecek = hedef_konum if hedef_konum != Vector2(-1, -1) else nokta_konumlari[hedef_nokta] + Vector2(25, 25)

	var guc = tip["guc"]
	var savunma = tip["savunma"]
	var hp = float(tip["hp"] * tip["asker_sayisi"])
	var gorus_yaricapi = _birim_gorus_yaricapi(tip)
	if taraf == "dogu_roma":
		guc = int(guc * zorluk_ayarlari[zorluk]["guc_carpan"])
		savunma = int(savunma * zorluk_ayarlari[zorluk]["savunma_carpan"])
		hp = hp * zorluk_ayarlari[zorluk]["hp_carpan"]

	var birim = {
		"id": birim_id_sayaci,
		"node": kare,
		"konum": baslangic,
		"hedef": gidilecek,
		"hedef_nokta": hedef_nokta,
		"taraf": taraf,
		"hiz": tip["hiz"],
		"guc": guc,
		"savunma": savunma,
		"hp": hp,
		"max_hp": hp,
		"asker_sayisi": tip["asker_sayisi"],
		"isim": tip["isim"],
		"menzil": tip.get("menzil", 80.0),
		"saldirim_timer": 0.0,
		"hasar_verilen": 0,
		"bekleyen_hasar": 0.0,
		"gorus_yaricapi": gorus_yaricapi,
		"pusu_modunda": false,
		"pusu_arazi_gizli": false,
		"pusu_ilk_saldiri_kullanildi": false,
		"pusu_hasar_carpani": pusu_ilk_saldiri_carpani,
		"geri_cekiliyor": false,
		"savunma_modunda": false,
		"takip_edilen_dusman": -1,
		"secili": false,
		"savas_halinde": false,
		"ai_timer": 0.0 if taraf == "dogu_roma" else -1.0,
		"is_general": tip.get("is_general", false),
		"aura_menzil": tip.get("aura_menzil", 0.0),
		"aura_guc": tip.get("aura_guc", 1.0),
		"aura_savunma": tip.get("aura_savunma", 1.0)
	}
	birim_id_sayaci += 1
	aktif_birimler.append(birim)
	terfi_kullanimi_artir(taraf, tip["isim"])

func hasar_carpani_hesapla(saldiran: String, hedef: String) -> float:
	if not ustunluk_tablosu.has(saldiran):
		return 1.0
	if hedef in ustunluk_tablosu[saldiran]["guclu"]:
		return 1.5
	if hedef in ustunluk_tablosu[saldiran]["zayif"]:
		return 0.6
	return 1.0

func birim_tikla(birim: Dictionary) -> void:
	var result = command_system.select_unit(birim)
	if result.get("ignored", false):
		return
	_command_refs_sync()
	_command_status_line_uygula(result)
	birim_detay_goster(birim)
	if result.get("deselect_inventory", false):
		secili_envanter_idx = -1
		secili_envanter_tip_anahtari = ""
		secili_envanter_gonder_adedi = 1
		_envanter_secim_ui_guncelle()

func birim_hareket_ettir(hedef_pos: Vector2) -> void:
	var result = command_system.execute_move(hedef_pos)
	_command_refs_sync()
	_command_status_line_uygula(result)

func birim_id_ile_bul(id: int) -> Dictionary:
	for birim in aktif_birimler:
		if int(birim.get("id", -1)) == id and birim["hp"] > 0:
			return birim
	return {}

func en_yakin_dost_nokta(pos: Vector2, taraf: String) -> String:
	var secim = ""
	var en_kisa = INF
	for nokta in nokta_sahipleri:
		if nokta_sahipleri[nokta] != taraf:
			continue
		var d = pos.distance_to(nokta_merkezi(nokta))
		if d < en_kisa:
			en_kisa = d
			secim = nokta
	if secim != "":
		return secim
	var fallback = "E" if taraf == "osmanli" and nokta_konumlari.has("E") else ("D" if nokta_konumlari.has("D") else en_yakin_nokta_bul(pos))
	return fallback

func birim_komut_saldir(birim: Dictionary, hedef_pos: Vector2, hedef_dusman_id: int = -1) -> void:
	var result = command_system.execute_attack(birim, hedef_pos, hedef_dusman_id)
	_command_refs_sync()
	_command_status_line_uygula(result)

func birim_geri_cekil_baslat(birim: Dictionary) -> void:
	var result = command_system.execute_retreat(birim)
	_command_refs_sync()
	_command_status_line_uygula(result)

func birim_nokta_savun(birim: Dictionary) -> void:
	var result = command_system.execute_defend_point(birim)
	_command_refs_sync()
	_command_status_line_uygula(result)

func birim_pusu_kur() -> void:
	_command_state_push()
	var result = command_system.execute_ambush()
	_command_refs_sync()
	_command_status_line_uygula(result)

func _process(delta: float) -> void:
	if oyun_bitti:
		return

	_command_state_push()

	if detay_popup_panel != null and detay_popup_panel.visible:
		_birim_detay_popup_konumla()

	kalan_sure -= delta
	oyun_suresi += delta
	ui_guncelle()
	minimap_guncelle()

	if hazirlik_fazi:
		ai_hazirlik_timer += delta
		if ai_hazirlik_timer >= ai_hazirlik_araligi:
			ai_hazirlik_timer = 0.0
			ai_ordu_birim_ekle()
		if kalan_sure <= 0:
			if kompozisyon_toplami() > 0:
				savas_baslat()
			else:
				kalan_sure = 10.0
				var kont_l = ui_node("Label_Kontenjan")
				if kont_l != null:
					kont_l.text = "Ordu kurmadan savas baslamaz!"
		return

	if kalan_sure <= 0:
		oyun_bitir()
		return

	ult_aktif_sure["osmanli"] = max(0.0, ult_aktif_sure["osmanli"] - delta)
	ult_aktif_sure["dogu_roma"] = max(0.0, ult_aktif_sure["dogu_roma"] - delta)
	if ult_sarj["dogu_roma"] >= 100.0:
		ult_kullan("dogu_roma")

	ai_spawn_timer += delta
	if ai_spawn_timer >= ai_spawn_suresi:
		ai_spawn_timer = 0.0
		ai_dalga_sayisi += 1
		ai_birim_gonder()
		if zorluk == "kolay" and ai_dalga_sayisi % 2 == 0:
			ai_birim_gonder()
			if randf() < 0.3:
				ai_birim_gonder()
		elif zorluk == "orta" and ai_dalga_sayisi % 2 == 0:
			ai_birim_gonder()
			if randf() < 0.4:
				ai_birim_gonder()
		elif zorluk == "zor":
			ai_birim_gonder()
			if ai_dalga_sayisi % 2 == 0:
				ai_birim_gonder()
			if randf() < 0.65:
				ai_birim_gonder()

	puan_timer += delta
	if puan_timer >= puan_interval:
		puan_timer = 0.0
		puan_uret()
		ai_nokta_gelistir()

	capture_guncelle(delta)
	savas_sisi_guncelle()
	ai_birimleri_guncelle(delta)
	istatistik_nokta_sure_guncelle(delta)
	pusu_tetik_kontrolu()
	savas_sisi_guncelle()
	nokta_gorunurluklerini_guncelle()
	birim_gorunurluklerini_guncelle()

	# === SALDIRI SİSTEMİ ===
	for birim in aktif_birimler:
		if birim["hp"] <= 0:
			continue
		if birim.get("pusu_modunda", false) or birim.get("geri_cekiliyor", false):
			continue

		birim["saldirim_timer"] += delta
		if birim["saldirim_timer"] < 1.0:
			continue
		birim["saldirim_timer"] = 0.0

		var dusman_listesi = []

		var saldiran_efekt = birim_etkin_degerleri(birim)
		for b in aktif_birimler:
			if b["taraf"] != birim["taraf"] and b["hp"] > 0:
				if not birim_gorunur_mu_tarafa(b, birim["taraf"]):
					continue
				if birim["konum"].distance_to(b["konum"]) <= saldiran_efekt["menzil"]:
					dusman_listesi.append(b)

		if dusman_listesi.is_empty():
			birim["savas_halinde"] = false
			continue

		birim["savas_halinde"] = true
		var hasar_per = max(1.0, float(saldiran_efekt["guc"]) / float(dusman_listesi.size()))
		for dusman in dusman_listesi:
			var dusman_efekt = birim_etkin_degerleri(dusman)
			var carpan = hasar_carpani_hesapla(birim["isim"], dusman["isim"])
			if not birim.get("pusu_ilk_saldiri_kullanildi", true):
				carpan *= float(birim.get("pusu_hasar_carpani", pusu_ilk_saldiri_carpani))
				birim["pusu_ilk_saldiri_kullanildi"] = true
			var gercek_hasar = max(1.0, (hasar_per - float(dusman_efekt["savunma"])) * carpan)
			dusman["bekleyen_hasar"] += gercek_hasar
			birim["hasar_verilen"] += int(gercek_hasar)
			ult_sarj[birim["taraf"]] = min(100.0, ult_sarj[birim["taraf"]] + gercek_hasar * 0.08)
			mac_istatistik[birim["taraf"]]["hasar"] += gercek_hasar

	# Hasarları uygula
	for birim in aktif_birimler:
		if birim["bekleyen_hasar"] > 0:
			birim["hp"] -= birim["bekleyen_hasar"]
			birim["bekleyen_hasar"] = 0.0

	# Hareket ve temizlik
	var silinecekler = []
	for birim in aktif_birimler:
		if birim["hp"] <= 0:
			if birim.get("is_general", false):
				moral_degistir(birim["taraf"], -30.0)
			if birim == secili_birim:
				secili_birim = null
			var birim_id = int(birim.get("id", -1))
			if birim_id >= 0:
				fog_system.remove_enemy_intel(birim_id)
			birim["node"].queue_free()
			silinecekler.append(birim)
			var taraf = birim["taraf"]
			var diger = "dogu_roma" if taraf == "osmanli" else "osmanli"
			mac_istatistik[taraf]["kayip"] += 1
			mac_istatistik[diger]["oldurme"] += 1
			continue

		var dusman_menzilde = false
		var hareket_efekt = birim_etkin_degerleri(birim)
		var takip_id = int(birim.get("takip_edilen_dusman", -1))
		if takip_id >= 0:
			var takip = birim_id_ile_bul(takip_id)
			if takip.is_empty():
				birim["takip_edilen_dusman"] = -1
			else:
				birim["hedef"] = takip["konum"]
				birim["hedef_nokta"] = en_yakin_nokta_bul(takip["konum"])
		for b in aktif_birimler:
			if b["taraf"] != birim["taraf"] and b["hp"] > 0:
				if not birim_gorunur_mu_tarafa(b, birim["taraf"]):
					continue
				if birim["konum"].distance_to(b["konum"]) <= hareket_efekt["menzil"]:
					dusman_menzilde = true
					break

		var hedefe_varildi = birim["konum"].distance_to(birim["hedef"]) <= 8.0
		if birim.get("pusu_modunda", false):
			dusman_menzilde = false
			hedefe_varildi = true
		if birim.get("geri_cekiliyor", false):
			dusman_menzilde = false
		if not dusman_menzilde and not hedefe_varildi:
			var mesafe = birim["hedef"] - birim["konum"]
			var yon = mesafe.normalized()
			birim["konum"] += yon * hareket_efekt["hiz"] * delta
			var arazi_hareket = birimin_arazisini_bul(birim["konum"])
			if bool(arazi_hareket.get("tek_sira", false)):
				var rect: Rect2 = arazi_hareket.get("rect", Rect2())
				var merkez = _dar_koridor_merkez(rect)
				if rect.size.x <= rect.size.y:
					birim["konum"].x = merkez.x
				else:
					birim["konum"].y = merkez.y
			birim["node"].position = birim["konum"]
			birim["pusu_arazi_gizli"] = false
		elif not birim.get("pusu_modunda", false):
			var orman_idx = _orman_bolge_index(birim["konum"])
			birim["pusu_arazi_gizli"] = orman_idx >= 0 and not dusman_menzilde and hedefe_varildi
		if birim.get("geri_cekiliyor", false) and hedefe_varildi:
			birim["geri_cekiliyor"] = false

		if is_instance_valid(birim["node"]):
			var hp_bar = birim["node"].get_node_or_null("HPBar")
			if hp_bar:
				hp_bar.size.x = 30.0 * (birim["hp"] / birim["max_hp"])
			var asker_l = birim["node"].get_node_or_null("AskerSayisi")
			if asker_l:
				var kalan = int(ceil(birim["hp"] / (birim["max_hp"] / birim["asker_sayisi"])))
				asker_l.text = str(max(0, kalan))

	for silinecek in silinecekler:
		aktif_birimler.erase(silinecek)

	savas_sisi_guncelle()
	nokta_gorunurluklerini_guncelle()
	birim_gorunurluklerini_guncelle()

	if osmanli_puani >= kazanma_puani:
		oyun_bitir_kazanan("osmanli")
	elif dogu_roma_puani >= kazanma_puani:
		oyun_bitir_kazanan("dogu_roma")

func capture_guncelle(delta: float) -> void:
	for nokta in nokta_konumlari:
		var osmanli_sayisi = noktadaki_taraf_sayisi(nokta, "osmanli")
		var dogu_roma_sayisi = noktadaki_taraf_sayisi(nokta, "dogu_roma")
		var osmanli_bonus = 1.0 + float(nokta_gelistirme[nokta]) * 0.08 if nokta_sahipleri[nokta] == "osmanli" else 1.0
		var dogu_roma_bonus = 1.0 + float(nokta_gelistirme[nokta]) * 0.08 if nokta_sahipleri[nokta] == "dogu_roma" else 1.0

		if osmanli_sayisi > dogu_roma_sayisi:
			nokta_capture[nokta] = min(100.0, nokta_capture[nokta] + capture_hizi * delta * osmanli_sayisi * osmanli_bonus)
		elif dogu_roma_sayisi > osmanli_sayisi:
			nokta_capture[nokta] = max(0.0, nokta_capture[nokta] - capture_hizi * delta * dogu_roma_sayisi * dogu_roma_bonus)

		capture_sahip_guncelle(nokta)

func capture_sahip_guncelle(nokta: String) -> void:
	if nokta_capture[nokta] >= 100.0:
		nokta_al(nokta, "osmanli")
	elif nokta_capture[nokta] <= 0.0:
		nokta_al(nokta, "dogu_roma")
	else:
		nokta_al(nokta, "tarafsiz")

func sure_altin_miktari() -> int:
	var dakika_bonus = int(oyun_suresi / 60.0)
	return sure_altin_taban + dakika_bonus

func puan_uret() -> void:
	var sure_altin = sure_altin_miktari()
	osmanli_altini += sure_altin
	dogu_roma_altini += sure_altin

	for nokta in nokta_sahipleri:
		if nokta_sahipleri[nokta] == "osmanli":
			osmanli_puani += nokta_puan[nokta]
			osmanli_altini += nokta_altin[nokta]
			osmanli_gelisim_altini += nokta_altin[nokta]
		elif nokta_sahipleri[nokta] == "dogu_roma":
			dogu_roma_puani += nokta_puan[nokta]
			dogu_roma_altini += nokta_altin[nokta]
			dogu_roma_gelisim_altini += nokta_altin[nokta]

	var osmanli_nokta = 0
	var dogu_roma_nokta = 0
	for nokta in nokta_sahipleri:
		if nokta_sahipleri[nokta] == "osmanli":
			osmanli_nokta += 1
		elif nokta_sahipleri[nokta] == "dogu_roma":
			dogu_roma_nokta += 1

	if osmanli_nokta >= 3:
		osmanli_puani += 1
		osmanli_altini += 5
		osmanli_gelisim_altini += 5
		if osmanli_nokta == nokta_sahipleri.size():
			osmanli_puani += 2
			osmanli_altini += 10
			osmanli_gelisim_altini += 10
	elif dogu_roma_nokta >= 3:
		dogu_roma_puani += 1
		dogu_roma_altini += 5
		dogu_roma_gelisim_altini += 5
		if dogu_roma_nokta == nokta_sahipleri.size():
			dogu_roma_puani += 2
			dogu_roma_altini += 10
			dogu_roma_gelisim_altini += 10

	ui_guncelle()

func istatistik_nokta_sure_guncelle(delta: float) -> void:
	var ult_hiz = {
		"kolay": {"oyuncu": 0.26, "ai": 0.48},
		"orta": {"oyuncu": 0.22, "ai": 0.52},
		"zor": {"oyuncu": 0.18, "ai": 0.56},
	}
	var hiz = ult_hiz.get(zorluk, ult_hiz["orta"])
	var oyuncu_ult_hiz = float(hiz["oyuncu"])
	var ai_ult_hiz = float(hiz["ai"])
	for nokta in nokta_sahipleri:
		if nokta_sahipleri[nokta] == "osmanli":
			mac_istatistik["osmanli"]["nokta_sure"] += delta
			ult_sarj["osmanli"] = min(100.0, ult_sarj["osmanli"] + delta * oyuncu_ult_hiz)
		elif nokta_sahipleri[nokta] == "dogu_roma":
			mac_istatistik["dogu_roma"]["nokta_sure"] += delta
			ult_sarj["dogu_roma"] = min(100.0, ult_sarj["dogu_roma"] + delta * ai_ult_hiz)

func nokta_gelistir(nokta: String) -> void:
	if hazirlik_fazi or oyun_bitti:
		return
	if nokta_sahipleri[nokta] != "osmanli":
		return
	var seviye = nokta_gelistirme[nokta]
	if seviye >= 3:
		return
	var maliyet = 20 + seviye * 15
	if osmanli_gelisim_altini < maliyet:
		return
	osmanli_gelisim_altini -= maliyet
	mac_istatistik["osmanli"]["altin_harcama"] += maliyet
	nokta_gelistirme[nokta] += 1
	nokta_puan[nokta] = nokta_taban_puan(nokta) + nokta_gelistirme[nokta]
	nokta_altin[nokta] = nokta_taban_altin(nokta) + nokta_gelistirme[nokta]
	ui_guncelle()

func ai_nokta_gelistir() -> void:
	if hazirlik_fazi or oyun_bitti:
		return
	var secim = ""
	var secim_seviye = 999
	for nokta in nokta_oncelik_listesi():
		if nokta_sahipleri[nokta] != "dogu_roma":
			continue
		if nokta_gelistirme[nokta] < secim_seviye and nokta_gelistirme[nokta] < 3:
			secim = nokta
			secim_seviye = nokta_gelistirme[nokta]
	if secim == "":
		return
	var maliyet = 20 + secim_seviye * 15
	if dogu_roma_gelisim_altini < maliyet:
		return
	dogu_roma_gelisim_altini -= maliyet
	mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet
	nokta_gelistirme[secim] += 1
	nokta_puan[secim] = nokta_taban_puan(secim) + nokta_gelistirme[secim]
	nokta_altin[secim] = nokta_taban_altin(secim) + nokta_gelistirme[secim]
	if zorluk == "kolay" and randf() < 0.42 and dogu_roma_gelisim_altini >= maliyet + 8 and nokta_gelistirme[secim] < 3:
		dogu_roma_gelisim_altini -= maliyet + 8
		mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 8
		nokta_gelistirme[secim] += 1
		nokta_puan[secim] = nokta_taban_puan(secim) + nokta_gelistirme[secim]
		nokta_altin[secim] = nokta_taban_altin(secim) + nokta_gelistirme[secim]
	if zorluk == "orta" and randf() < 0.62 and dogu_roma_gelisim_altini >= maliyet + 12 and nokta_gelistirme[secim] < 3:
		dogu_roma_gelisim_altini -= maliyet + 12
		mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 12
		nokta_gelistirme[secim] += 1
		nokta_puan[secim] = nokta_taban_puan(secim) + nokta_gelistirme[secim]
		nokta_altin[secim] = nokta_taban_altin(secim) + nokta_gelistirme[secim]
	if zorluk == "zor" and randf() < 0.82 and dogu_roma_gelisim_altini >= maliyet + 15 and nokta_gelistirme[secim] < 3:
		dogu_roma_gelisim_altini -= maliyet + 15
		mac_istatistik["dogu_roma"]["altin_harcama"] += maliyet + 15
		nokta_gelistirme[secim] += 1
		nokta_puan[secim] = nokta_taban_puan(secim) + nokta_gelistirme[secim]
		nokta_altin[secim] = nokta_taban_altin(secim) + nokta_gelistirme[secim]

func ai_kompozisyon_toplami_kt() -> int:
	var toplam = 0
	for i in range(ai_kompozisyon.size()):
		toplam += ai_kompozisyon[i] * dogu_roma_birim_tipleri[i]["kontenjan"]
	return toplam

func ai_ordu_hazirlik_sifirla() -> void:
	ai_kompozisyon_dizisi_sifirla()
	ai_hazirlik_timer = 0.0
	taraf_formasyon["dogu_roma"] = "hucum"
	ai_ordu_ui_guncelle()

func ai_ordu_ui_guncelle() -> void:
	var ai_l = ui_node("Label_AiOrdu")
	if ai_l == null:
		return
	var hedef = zorluk_ayarlari[zorluk]["kontenjan_hedef"]
	var kt = ai_kompozisyon_toplami_kt()
	var parcalar: Array = []
	for i in range(dogu_roma_birim_tipleri.size()):
		if ai_kompozisyon[i] > 0:
			var tip = dogu_roma_birim_tipleri[i]
			parcalar.append(tip["sembol"] + " " + tip["isim"] + " x" + str(ai_kompozisyon[i]))
	ai_l.text = HudFormatter.ai_army_label(parcalar, kt, hedef)

func ai_birim_tipi_sec(kalan_kontenjan: int) -> int:
	return MetaSystem.choose_ai_army_type(dogu_roma_birim_tipleri, kalan_kontenjan, zorluk)

func ai_ordu_birim_ekle() -> void:
	var hedef = zorluk_ayarlari[zorluk]["kontenjan_hedef"]
	var mevcut = ai_kompozisyon_toplami_kt()
	if mevcut >= hedef:
		return
	var idx = ai_birim_tipi_sec(hedef - mevcut)
	if idx < 0:
		return
	ai_kompozisyon[idx] += 1
	ai_ordu_ui_guncelle()

func ai_ordu_kur_tam() -> void:
	ai_kompozisyon_dizisi_sifirla()
	var hedef = zorluk_ayarlari[zorluk]["kontenjan_hedef"]
	while ai_kompozisyon_toplami_kt() < hedef:
		var onceki = ai_kompozisyon_toplami_kt()
		ai_ordu_birim_ekle()
		if ai_kompozisyon_toplami_kt() == onceki:
			break
	ai_ordu_ui_guncelle()

func ai_kompozisyon_toplami() -> int:
	var toplam = 0
	for sayi in ai_kompozisyon:
		toplam += sayi
	return toplam

func ai_savas_envanteri_hazirla() -> void:
	if ai_kompozisyon_toplami() <= 0 or ai_kompozisyon_toplami_kt() < zorluk_ayarlari[zorluk]["kontenjan_hedef"] * 0.5:
		ai_ordu_kur_tam()
	ai_envanter.clear()
	for i in range(dogu_roma_birim_tipleri.size()):
		for j in range(ai_kompozisyon[i]):
			ai_envanter.append(dogu_roma_birim_tipleri[i].duplicate())
	ai_envanter.shuffle()
	print("=== AI ORDUSU === " + str(ai_envanter.size()) + " birim hazir")

func ai_hedef_konum_sec(nokta: String) -> Vector2:
	var merkez = nokta_merkezi(nokta)
	var aci = randf() * TAU
	var uzaklik = randf_range(25.0, 110.0)
	return harita_sinirla(merkez + Vector2(cos(aci), sin(aci)) * uzaklik)

func ai_yakin_dusman_bul(birim: Dictionary) -> Dictionary:
	var en_yakin: Dictionary = {}
	var en_kisa = ai_takip_menzili
	for b in aktif_birimler:
		if b["taraf"] != "osmanli" or b["hp"] <= 0:
			continue
		if not birim_gorunur_mu_tarafa(b, "dogu_roma"):
			continue
		var d = birim["konum"].distance_to(b["konum"])
		if d < en_kisa:
			en_kisa = d
			en_yakin = b
	return en_yakin

func ai_birim_menzilde_dusman_var(birim: Dictionary) -> bool:
	var etkiler = birim_etkin_degerleri(birim)
	for b in aktif_birimler:
		if b["taraf"] != "osmanli" or b["hp"] <= 0:
			continue
		if not birim_gorunur_mu_tarafa(b, "dogu_roma"):
			continue
		if birim["konum"].distance_to(b["konum"]) <= etkiler["menzil"]:
			return true
	return false

func ai_birim_hedefi_hesapla(birim: Dictionary) -> Vector2:
	var dusman = ai_yakin_dusman_bul(birim)
	if not dusman.is_empty():
		var mesafe = birim["konum"].distance_to(dusman["konum"])
		var etkiler = birim_etkin_degerleri(birim)
		if mesafe <= etkiler["menzil"]:
			return birim["konum"]
		var yon = (dusman["konum"] - birim["konum"]).normalized()
		var adim = clamp(mesafe - etkiler["menzil"] * 0.6, 40.0, 180.0)
		return harita_sinirla(birim["konum"] + yon * adim)

	var nokta = ai_hedef_sec()
	return ai_hedef_konum_sec(nokta)

func ai_birimleri_guncelle(delta: float) -> void:
	var karar_suresi = ai_karar_araligi.get(zorluk, 3.5)
	if zorluk == "zor":
		karar_suresi *= 0.7
	for birim in aktif_birimler:
		if birim["taraf"] != "dogu_roma" or birim["hp"] <= 0:
			continue
		if birim.get("pusu_modunda", false):
			continue

		if ai_birim_menzilde_dusman_var(birim):
			continue

		var dusman = ai_yakin_dusman_bul(birim)
		if not dusman.is_empty():
			var mesafe = birim["konum"].distance_to(dusman["konum"])
			var ai_etki = birim_etkin_degerleri(birim)
			if mesafe <= ai_etki["menzil"] * 1.5:
				birim["hedef"] = ai_birim_hedefi_hesapla(birim)
				birim["hedef_nokta"] = en_yakin_nokta_bul(birim["hedef"])
				birim["ai_timer"] = 0.0
				continue

		birim["ai_timer"] += delta
		var hedefe_varildi = birim["konum"].distance_to(birim["hedef"]) <= 8.0
		var yeni_hedef_zamani = hedefe_varildi and birim["ai_timer"] >= karar_suresi
		var uzun_yuruyus = birim["ai_timer"] >= karar_suresi * 2.5

		if not yeni_hedef_zamani and not uzun_yuruyus:
			continue

		birim["ai_timer"] = 0.0
		birim["hedef"] = ai_birim_hedefi_hesapla(birim)
		birim["hedef_nokta"] = en_yakin_nokta_bul(birim["hedef"])

func ai_birim_sec() -> Dictionary:
	var uygun: Array = []
	for tip in dogu_roma_birim_tipleri:
		if dogu_roma_altini >= tip["maliyet"]:
			uygun.append(tip)
	if uygun.is_empty():
		return {}
	uygun.sort_custom(func(a, b): return a["maliyet"] > b["maliyet"])
	if zorluk == "zor":
		return uygun[0]
	if zorluk == "orta":
		return uygun[randi() % mini(2, uygun.size())]
	return uygun[randi() % mini(3, uygun.size())]

func ai_birim_gonder() -> void:
	var tip: Dictionary = {}
	var kaynak = "ordu"
	if ai_envanter.size() > 0:
		tip = ai_envanter.pop_back()
	else:
		tip = ai_birim_sec()
		if tip.is_empty():
			return
		dogu_roma_altini -= tip["maliyet"]
		mac_istatistik["dogu_roma"]["altin_harcama"] += int(tip["maliyet"])
		kaynak = "altin"

	var hedef_nokta = ai_hedef_sec()
	var hedef_pos = ai_hedef_konum_sec(hedef_nokta)
	var baslangic = harita_sinirla(Vector2(
		randf_range(harita_sinir["min_x"] + 80.0, harita_sinir["max_x"] - 80.0),
		randf_range(harita_sinir["min_y"] + 40.0, harita_sinir["min_y"] + 180.0)
	))
	birim_olustur(baslangic, hedef_nokta, "dogu_roma", tip, hedef_pos)
	print("AI " + tip["isim"] + " (" + kaynak + ") -> " + hedef_nokta + " | kalan ordu: " + str(ai_envanter.size()))

func ai_hedef_sec() -> String:
	var oncelik = nokta_oncelik_listesi()
	if zorluk == "zor":
		if nokta_sahipleri.get("C", "tarafsiz") != "dogu_roma":
			return "C"
		for nokta in oncelik:
			if nokta_sahipleri[nokta] == "osmanli":
				return nokta
	elif zorluk == "orta":
		if nokta_sahipleri.get("C", "tarafsiz") == "osmanli" and randf() < 0.9:
			return "C"
		for nokta in oncelik:
			if nokta_sahipleri[nokta] == "osmanli":
				return nokta
	elif zorluk == "kolay":
		if nokta_sahipleri.get("C", "tarafsiz") == "osmanli" and randf() < 0.82:
			return "C"
		for nokta in oncelik:
			if nokta_sahipleri[nokta] == "osmanli":
				return nokta

	for nokta in oncelik:
		if nokta_sahipleri[nokta] == "tarafsiz":
			return nokta

	var en_zayif = ""
	var en_az = 999
	for nokta in nokta_sahipleri:
		if nokta_sahipleri[nokta] == "osmanli":
			var say = noktadaki_taraf_sayisi(nokta, "osmanli")
			if say < en_az:
				en_az = say
				en_zayif = nokta

	if en_zayif != "":
		return en_zayif

	var en_tehlikeli = ""
	var en_dusuk = 100.0
	for nokta in nokta_capture:
		if nokta_sahipleri[nokta] == "dogu_roma" and nokta_capture[nokta] < en_dusuk:
			en_dusuk = nokta_capture[nokta]
			en_tehlikeli = nokta

	if en_tehlikeli != "":
		return en_tehlikeli

	var noktalar = nokta_oncelik_listesi()
	return noktalar[randi() % noktalar.size()]

func oyun_sonu_paneli_goster() -> void:
	ui_system.show_game_over_panel(mac_ozeti_metni())

func tekrar_oyna() -> void:
	hazirlik_baslat()

func oyun_bitir_kazanan(kazanan: String) -> void:
	hiz_carpani_sifirla()
	oyun_bitti = true
	if kazanan == "osmanli":
		ui_system.set_game_over_round("OSMANLI KAZANDI!")
		kampanya_index = MetaSystem.campaign_next_index(kampanya_index, true, kampanya_harita_idleri.size())
		mac_istatistik_kayit["galibiyet"] = int(mac_istatistik_kayit.get("galibiyet", 0)) + 1
	else:
		ui_system.set_game_over_round("DOGU ROMA KAZANDI!")
		kampanya_index = MetaSystem.campaign_next_index(kampanya_index, false, kampanya_harita_idleri.size())
		mac_istatistik_kayit["maglubiyet"] = int(mac_istatistik_kayit.get("maglubiyet", 0)) + 1
	kayit_kaydet()
	oyun_sonu_paneli_goster()

func oyun_bitir() -> void:
	if osmanli_puani > dogu_roma_puani:
		oyun_bitir_kazanan("osmanli")
	elif dogu_roma_puani > osmanli_puani:
		oyun_bitir_kazanan("dogu_roma")
	else:
		hiz_carpani_sifirla()
		oyun_bitti = true
		ui_system.set_game_over_round("BERABERE!")
		mac_istatistik_kayit["beraberlik"] = int(mac_istatistik_kayit.get("beraberlik", 0)) + 1
		kayit_kaydet()
		oyun_sonu_paneli_goster()

func mac_ozeti_metni() -> String:
	var ozet = HudFormatter.match_summary(mac_istatistik["osmanli"], mac_istatistik["dogu_roma"])
	return ozet + "\nBolge: " + kampanya_bolgeleri[kampanya_index] + " | " + HudFormatter.save_stats(mac_istatistik_kayit)

func _hud_snapshot_olustur() -> Dictionary:
	return {
		"hazirlik_fazi": hazirlik_fazi,
		"osmanli_puan": osmanli_puani,
		"dogu_roma_puan": dogu_roma_puani,
		"kazanma_puani": kazanma_puani,
		"kalan_sure": kalan_sure,
		"osmanli_altin": osmanli_altini,
		"gelisim_altin": osmanli_gelisim_altini,
		"dogu_roma_altini": dogu_roma_altini,
		"moral": int(taraf_moral["osmanli"]),
		"hava": hava_durumu,
		"ult_yuzde": int(ult_sarj["osmanli"]),
	}

func ui_guncelle() -> void:
	ui_system.update_hud(_hud_snapshot_olustur())
	takviye_ui_guncelle()

func nokta_renkleri_sifirla() -> void:
	for nokta in nokta_konumlari:
		nokta_al(nokta, "tarafsiz")
		nokta_capture[nokta] = 50.0
		if capture_barlar.has(nokta):
			capture_barlar[nokta].size.x = 40.0

func nokta_renk_guncelle(nokta: String) -> void:
	var kare = get_node("Nokta_" + nokta)
	if nokta_sahipleri[nokta] == "osmanli":
		kare.color = Color.GOLD
	elif nokta_sahipleri[nokta] == "dogu_roma":
		kare.color = Color.PURPLE
	else:
		kare.color = Color.GRAY

func nokta_al(nokta: String, taraf: String) -> void:
	if nokta_sahipleri[nokta] == taraf:
		return
	var onceki = nokta_sahipleri[nokta]
	nokta_sahipleri[nokta] = taraf
	if onceki == "osmanli":
		moral_degistir("osmanli", -10.0)
	elif onceki == "dogu_roma":
		moral_degistir("dogu_roma", -10.0)
	if taraf == "osmanli":
		moral_degistir("osmanli", 10.0)
	elif taraf == "dogu_roma":
		moral_degistir("dogu_roma", 10.0)

func _minimap_tiklamasini_isle(event_position: Vector2) -> bool:
	if minimap_panel != null:
		var surface = ui_node("MinimapSurface")
		var hedef_rect = Rect2(
			surface.get_global_position() if surface != null else minimap_panel.get_global_position(),
			surface.size if surface != null else minimap_panel.size
		)
		if hedef_rect.has_point(event_position):
			if kamera != null:
				var yerel = event_position - hedef_rect.position
				kamera.position = minimap_panel_to_dunya(yerel)
				kamera_sinirla()
			return true
	return false

func _input(event) -> void:
	if oyun_bitti:
		return

	if event.is_action_pressed("cmd_cancel_menu"):
		komut_menusu_kapat()
		return

	if event.is_action_pressed("cmd_camera_pan"):
		pan_aktif = true
		return
	if event.is_action_released("cmd_camera_pan"):
		pan_aktif = false
		return
	if event is InputEventMouseMotion and pan_aktif:
		if kamera != null:
			kamera.position -= event.relative / kamera.zoom.x
			kamera_sinirla()
		return

	if event.is_action_pressed("cmd_zoom_in"):
		if kamera != null:
			var yeni = kamera.zoom - Vector2(zoom_hizi, zoom_hizi)
			kamera.zoom = Vector2(
				clamp(yeni.x, zoom_min, zoom_max),
				clamp(yeni.y, zoom_min, zoom_max)
			)
		return
	if event.is_action_pressed("cmd_zoom_out"):
		if kamera != null:
			var yeni = kamera.zoom + Vector2(zoom_hizi, zoom_hizi)
			kamera.zoom = Vector2(
				clamp(yeni.x, zoom_min, zoom_max),
				clamp(yeni.y, zoom_min, zoom_max)
			)
		return

	if event.is_action_pressed("cmd_primary_click"):
			if _minimap_tiklamasini_isle(event.position):
				return

			if komut_menusu_panel != null and komut_menusu_panel.visible:
				var menu_rect = Rect2(komut_menusu_panel.position, komut_menusu_panel.size)
				if not menu_rect.has_point(event.position):
					komut_menusu_kapat()

			if event.position.y > 450:
				return

			var dunya_pos = get_global_mouse_position()
			if not hazirlik_fazi:
				var tiklanan_oyuncu = null
				var tiklanan_dusman = null
				for birim in aktif_birimler:
					if birim["hp"] <= 0:
						continue
					var birim_rect = Rect2(birim["konum"], Vector2(30, 30))
					if not birim_rect.has_point(dunya_pos):
						continue
					if birim["taraf"] == "osmanli":
						tiklanan_oyuncu = birim
					else:
						tiklanan_dusman = birim
					if tiklanan_oyuncu != null:
						break

				if tiklanan_oyuncu != null:
					if secili_birim == tiklanan_oyuncu:
						komut_menusu_ac(event.position, tiklanan_oyuncu)
					else:
						komut_menusu_kapat()
						komut_sec("hareket")
						birim_tikla(tiklanan_oyuncu)
					return

				if secili_birim != null and secili_komut == "saldir" and tiklanan_dusman != null:
					birim_komut_saldir(secili_birim, tiklanan_dusman["konum"], int(tiklanan_dusman.get("id", -1)))
					return

				if secili_birim != null:
					komut_menusu_kapat()
					if secili_komut == "pusu":
						birim_pusu_kur()
					elif secili_komut == "saldir":
						birim_komut_saldir(secili_birim, dunya_pos)
					else:
						birim_hareket_ettir(dunya_pos)
				elif secili_envanter_tip_anahtari != "":
					birim_haritadan_gonder(dunya_pos)
				else:
					for nokta in nokta_konumlari:
						if not kesfedilen_noktalar.get(nokta, false):
							continue
						if dunya_pos.distance_to(nokta_merkezi(nokta)) <= 70.0:
							nokta_sec(nokta)
							break
				return

			if hazirlik_fazi:
				var birim_tiklandi = false
				for birim in aktif_birimler:
					if birim["taraf"] == "osmanli" and birim["hp"] > 0:
						var birim_rect = Rect2(birim["konum"], Vector2(30, 30))
						if birim_rect.has_point(dunya_pos):
							birim_tikla(birim)
							birim_tiklandi = true
							break
