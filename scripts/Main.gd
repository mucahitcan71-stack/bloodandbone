extends Node2D

const Constants = preload("res://scripts/constants.gd")
const GameTables = preload("res://scripts/game_tables.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const MetaSystem = preload("res://scripts/systems/meta_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const GameData = preload("res://scripts/systems/game_data.gd")
const WorldSystem = preload("res://scripts/systems/world_system.gd")
const FogSystem = preload("res://scripts/systems/fog_system.gd")
const UISystem = preload("res://scripts/systems/ui_system.gd")
const CommandSystem = preload("res://scripts/systems/command_system.gd")
const HudStyle = preload("res://scripts/ui/hud_style.gd")
const HudCommands = preload("res://scripts/ui/hud_commands.gd")
const HudInventory = preload("res://scripts/ui/hud_inventory.gd")
const MinimapController = preload("res://scripts/ui/minimap_controller.gd")
const HudComposer = preload("res://scripts/ui/hud_composer.gd")
const PreparationController = preload("res://scripts/ui/preparation_controller.gd")
const CameraController = preload("res://scripts/camera/camera_controller.gd")
const InputRouter = preload("res://scripts/input/input_router.gd")
const BattleFlowSystem = preload("res://scripts/systems/battle_flow_system.gd")
const CombatLoopSystem = preload("res://scripts/systems/combat_loop_system.gd")
const UnitDeploymentSystem = preload("res://scripts/systems/unit_deployment_system.gd")
const AiSystem = preload("res://scripts/systems/ai_system.gd")
const PointEconomySystem = preload("res://scripts/systems/point_economy_system.gd")
const ContextMenus = preload("res://scripts/ui/context_menus.gd")
const UnitStatsSystem = preload("res://scripts/systems/unit_stats_system.gd")

var world_system: WorldSystem
var fog_system: FogSystem
var ui_system: UISystem
var command_system: CommandSystem
var battle_flow: BattleFlowSystem = BattleFlowSystem.new()
var combat_loop: CombatLoopSystem = CombatLoopSystem.new()
var unit_deployment: UnitDeploymentSystem = UnitDeploymentSystem.new()
var ai_system: AiSystem = AiSystem.new()
var point_economy: PointEconomySystem = PointEconomySystem.new()
var prep_controller: PreparationController = PreparationController.new()
var context_menus: ContextMenus = ContextMenus.new()
var unit_stats: UnitStatsSystem = UnitStatsSystem.new()

# === VERI (JSON'dan yuklenir) ===
var ustunluk_tablosu = {}
var osmanli_birim_tipleri: Array = []
var dogu_roma_birim_tipleri: Array = []
var kampanya_harita_idleri: Array = []
var kampanya_bolgeleri: Array = []
var aktif_harita_id = "trakya"
var harita_sinir = Constants.VARSAYILAN_HARITA_SINIR.duplicate()

# === OYUN DEĞİŞKENLERİ ===
var oyun_bitti = false
var oyun_suresi = 0.0
var max_sure = 2100.0

# === ZORLUK ===
var zorluk = "orta"
var zorluk_ayarlari = GameTables.ZORLUK_AYARLARI

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
var savas_baslangic_kompozisyon: Array = []
var envanter = []

# === AKTİF BİRİMLER ===
var aktif_birimler = []

# === AI ===
var ai_spawn_timer = 0.0
var ai_spawn_suresi = 12.0
var ai_karar_araligi = GameTables.AI_KARAR_ARALIGI
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
var capture_barlar = {}
var tekrar_oyna_btn: Button = null
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
var takviye_sag_tik_menu: PanelContainer = null
var takviye_sag_tik_secili_idx = -1
var kamera: Camera2D = null
var camera_controller: CameraController = CameraController.new()
var input_router: InputRouter = InputRouter.new()
var hud_composer: HudComposer = HudComposer.new()
var minimap_controller: MinimapController = MinimapController.new()
var minimap_panel: PanelContainer = null
var minimap_boyut = Vector2(206, 137)
var ui_root: Control = null
var yan_hud_tetik: PanelContainer = null
var yan_hud_panel: PanelContainer = null
var yan_hud_icerik: VBoxContainer = null
var yan_hud_kaybol_timer: Timer = null
var hazirlik_panel_root: PanelContainer = null
var hazirlik_tabs_row: HBoxContainer = null
var hazirlik_tabs_content: VBoxContainer = null
var hazirlik_tab_container_map = {}
var savas_panel_root: PanelContainer = null
var envanter_scroll: ScrollContainer = null
var envanter_grid: GridContainer = null
var mevcut_hiz_carpani = 1.0
var hiz_tek_btn: Button = null
var panel_sag_log_hiz: PanelContainer = null
var label_sag_osmanli: Label = null
var label_sag_roma: Label = null
var hud_komut_butonlari = {}

# === SAVAS SISI / KESIF / PUSU ===
var nokta_son_bilgi = {}
var pusu_ilk_saldiri_carpani = 2.0
var birim_id_sayaci = 1
var orman_bolgeleri: Array = []
var arazi_bolgeleri: Array = []
var arazi_katmani: Node2D = null
var suvari_isimleri = {"Akinci": true, "Kataphraktoi": true}

# === FORMASYON / MORAL / GENERAL ===
var formasyonlar = GameTables.FORMASYONLAR
var taraf_formasyon = {"osmanli": "dengeli", "dogu_roma": "dengeli"}
var taraf_moral = {"osmanli": 100.0, "dogu_roma": 100.0}

# === YETENEK / ULT / HAVA ===
var ult_sarj = {"osmanli": 0.0, "dogu_roma": 0.0}
var ult_aktif_sure = {"osmanli": 0.0, "dogu_roma": 0.0}
var hava_durumu = "Acik"
var hava_durumu_efektleri = GameTables.HAVA_DURUMU_EFEKTLERI

# === KART / EKIPMAN / TERFI ===
var kart_havuzu = GameTables.KART_HAVUZU
var kart_secenekleri = []
var ekipmanlar = GameTables.EKIPMANLAR
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

# === EKONOMI / NOKTA SAHIPLIGI ERISIM SARMALAYICILARI ===
# Alt sistemler (ai_system, point_economy_system) bu state'i artik
# dogrudan field erisimi yerine bu fonksiyonlar uzerinden degistiriyor.

func nokta_sahibi_getir(nokta: String) -> String:
	return nokta_sahipleri.get(nokta, "tarafsiz")

func nokta_sahibi_belirle(nokta: String, taraf: String) -> void:
	nokta_sahipleri[nokta] = taraf

func nokta_capture_getir(nokta: String) -> float:
	return nokta_capture.get(nokta, 50.0)

func nokta_capture_belirle(nokta: String, deger: float) -> void:
	nokta_capture[nokta] = deger

func altin_ekle(taraf: String, miktar: int) -> void:
	if taraf == "osmanli":
		osmanli_altini += miktar
	else:
		dogu_roma_altini += miktar

func gelisim_altini_ekle(taraf: String, miktar: int) -> void:
	if taraf == "osmanli":
		osmanli_gelisim_altini += miktar
	else:
		dogu_roma_gelisim_altini += miktar

func gelisim_altini_harca(taraf: String, miktar: int) -> bool:
	var mevcut = osmanli_gelisim_altini if taraf == "osmanli" else dogu_roma_gelisim_altini
	if mevcut < miktar:
		return false
	gelisim_altini_ekle(taraf, -miktar)
	return true

func puan_ekle(taraf: String, miktar: int) -> void:
	if taraf == "osmanli":
		osmanli_puani += miktar
	else:
		dogu_roma_puani += miktar

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
	unit_deployment.reset_composition()

func ai_kompozisyon_dizisi_sifirla() -> void:
	ai_system.reset_composition()

func _world_system_hazirla() -> void:
	world_system = WorldSystem.new()
	world_system.configure(self)
	world_system.set_on_map_applied(func():
		fog_system.reset_fog_on_map_change()
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

func _ui_system_hazirla() -> void:
	ui_system = UISystem.new()
	ui_system.configure(self)

func _ui_refs_sync() -> void:
	ui_root = ui_system.get_ui_root()
	hazirlik_panel_root = ui_system.get_hazirlik_panel_root()
	hazirlik_tabs_row = ui_system.get_hazirlik_tabs_row()
	hazirlik_tabs_content = ui_system.get_hazirlik_tabs_content()
	savas_panel_root = ui_system.get_savas_panel_root()
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

func _battle_flow_hazirla() -> void:
	battle_flow.configure(self)

func _combat_loop_hazirla() -> void:
	combat_loop.configure(self)

func _unit_deployment_hazirla() -> void:
	unit_deployment.configure(self)

func _ai_system_hazirla() -> void:
	ai_system.configure(self)

func _point_economy_hazirla() -> void:
	point_economy.configure(self)

func _input_router_hazirla() -> void:
	input_router.configure(self)

func _prep_controller_hazirla() -> void:
	prep_controller.configure(self)

func _context_menus_hazirla() -> void:
	context_menus.configure(self)

func _unit_stats_hazirla() -> void:
	unit_stats.configure(self)

func _context_menus_refs_sync() -> void:
	komut_menusu_panel = context_menus.komut_menusu_panel
	komut_menusu_hedef_birim = context_menus.komut_menusu_hedef_birim
	takviye_sag_tik_menu = context_menus.takviye_sag_tik_menu
	takviye_sag_tik_secili_idx = context_menus.takviye_sag_tik_secili_idx

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

func _kamera_kaydirmayi_uygula(delta: float) -> void:
	camera_controller.apply_pan(
		kamera,
		delta,
		get_viewport().get_mouse_position(),
		get_viewport().get_visible_rect().size,
		Callable(self, "kamera_sinirla")
	)

func arazi_katmani_olustur() -> void:
	world_system.arazi_katmani_olustur()
	_world_refs_sync()

func arazi_gorsellerini_guncelle() -> void:
	world_system.arazi_gorsellerini_guncelle()

func harita_gorsellerini_guncelle() -> void:
	world_system.harita_gorsellerini_guncelle()

func savas_sisi_katmani_olustur() -> void:
	fog_system.create_fog_layer()

func birimin_arazisini_bul(konum: Vector2) -> Dictionary:
	return world_system.birimin_arazisini_bul(konum)

func _orman_bolge_index(pos: Vector2) -> int:
	return world_system.orman_bolge_index(pos)

func birim_gorunur_mu_tarafa(hedef: Dictionary, goren_taraf: String) -> bool:
	return fog_system.is_unit_visible_to_faction(hedef, goren_taraf, aktif_birimler)

func pusu_tetik_kontrolu() -> void:
	for birim in aktif_birimler:
		if birim.get("hp", 0) <= 0 or not birim.get("pusu_modunda", false):
			continue
		var etkiler = birim_etkin_degerleri(birim)
		for dusman in aktif_birimler:
			if dusman.get("hp", 0) <= 0 or dusman.get("taraf", "") == birim.get("taraf", ""):
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

func birim_gorunurluklerini_guncelle() -> void:
	fog_system.update_unit_visibility()

func nokta_gorunurluklerini_guncelle() -> void:
	fog_system.update_point_visibility()

func kampanya_haritasini_yukle() -> void:
	if kampanya_harita_idleri.is_empty():
		return
	kampanya_index = clampi(kampanya_index, 0, kampanya_harita_idleri.size() - 1)
	harita_uygula(str(kampanya_harita_idleri[kampanya_index]))

func _ready() -> void:
	randomize()
	var eski_rect = get_node_or_null("ColorRect") as ColorRect
	if eski_rect != null:
		eski_rect.visible = false
	_world_system_hazirla()
	_fog_system_hazirla()
	_ui_system_hazirla()
	_command_system_hazirla()
	_battle_flow_hazirla()
	_combat_loop_hazirla()
	_unit_deployment_hazirla()
	_ai_system_hazirla()
	_point_economy_hazirla()
	_input_router_hazirla()
	_prep_controller_hazirla()
	_context_menus_hazirla()
	_unit_stats_hazirla()
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
	takviye_sag_tik_menu_olustur()
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
	if takviye_sag_tik_menu != null:
		extras.append(takviye_sag_tik_menu)
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

func _yan_hud_hazirla() -> void:
	ui_system.build_side_hud()
	_ui_refs_sync()
	if yan_hud_tetik != null:
		yan_hud_tetik.visible = false
	if yan_hud_panel != null:
		yan_hud_panel.visible = false

func hazirlik_eleman_ekle(tab: String, node: Control) -> void:
	prep_controller._add_element(tab, node)

func hazirlik_tab_degistir(tab: String) -> void:
	prep_controller.switch_tab(tab)

func terfi_ozet_metni() -> String:
	return HudFormatter.promotion_summary(terfi_verisi.get("osmanli", {}))

func hazirlik_bilgi_guncelle() -> void:
	prep_controller.update_info()

func hazirlik_paneli_olustur() -> void:
	prep_controller.build_panel()

func zorluk_sec(secilen: String) -> void:
	prep_controller.select_difficulty(secilen)

func kart_secenekleri_hazirla() -> void:
	prep_controller.prepare_card_options()

func kart_sec(kart: Dictionary) -> void:
	prep_controller.select_card(kart)

func ekipman_secimleri_hazirla() -> void:
	prep_controller.prepare_equipment_options()

func ekipman_sec(anahtar: String) -> void:
	prep_controller.select_equipment(anahtar)

func kontrol_noktalari_olustur() -> void:
	world_system.build_control_points(capture_barlar)

func komut_sec(komut: String) -> void:
	var result = command_system.set_command_mode(komut)
	secili_komut = command_system.get_selected_command()
	_command_status_line_uygula(result)

func komut_menusu_olustur() -> void:
	context_menus.build_komut_menusu()
	_context_menus_refs_sync()

func komut_menusu_ac(ekran_pos: Vector2, birim: Dictionary) -> void:
	context_menus.ac_komut_menusu(ekran_pos, birim)
	_context_menus_refs_sync()

func komut_menusu_kapat() -> void:
	context_menus.kapat_komut_menusu()
	_context_menus_refs_sync()

func takviye_sag_tik_menu_olustur() -> void:
	context_menus.build_takviye_menu()
	_context_menus_refs_sync()

func takviye_sag_tik_menu_ac(idx: int, ekran_pos: Vector2) -> void:
	context_menus.ac_takviye_menu(idx, ekran_pos)
	_context_menus_refs_sync()

func takviye_sag_tik_menu_kapat() -> void:
	context_menus.kapat_takviye_menu()
	_context_menus_refs_sync()

func _takviye_sag_tik_menu_secildi() -> void:
	context_menus._on_takviye_secildi()
	_context_menus_refs_sync()

func _envanter_kart_gui_input(event: InputEvent, idx: int, silik: bool) -> void:
	context_menus.envanter_kart_gui_input(event, idx, silik)
	_context_menus_refs_sync()

func komut_menusu_komut_sec(komut: String) -> void:
	if komut_menusu_hedef_birim == null:
		komut_menusu_kapat()
		return
	command_system.select_unit(komut_menusu_hedef_birim)
	secili_birim = command_system.get_selected_unit()
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
	minimap_controller.build(
		ui_root,
		minimap_boyut,
		HudStyle.minimap_panel_style(),
		HudStyle.minimap_surface_color(),
		nokta_konumlari
	)
	minimap_panel = minimap_controller.get_panel()

func minimap_guncelle() -> void:
	minimap_controller.update(
		fog_system,
		nokta_konumlari,
		nokta_sahipleri,
		aktif_birimler,
		kamera,
		get_viewport_rect().size,
		harita_sinir
	)

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

func birim_detay_hover_basla(tip: Dictionary) -> void:
	ui_system.begin_unit_detail_hover(tip)

func birim_detay_hover_bitir() -> void:
	ui_system.end_unit_detail_hover()

func _birim_detay_hover_durumunu_guncelle() -> void:
	ui_system.sync_unit_detail_hover_visibility()

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
	var gorus = int(tip.get("gorus_yaricapi", menzil + fog_system.normal_birim_gorus_bonus))
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

func kart_uygula(taraf: String, kart: Dictionary) -> void:
	if kart.is_empty():
		return
	if kart.has("moral"):
		taraf_moral[taraf] = clamp(taraf_moral[taraf] + kart["moral"], 0.0, Constants.MORAL_MAX)
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
	var sirali = Constants.HIZ_SECENEKLERI
	var idx = 0
	for i in range(sirali.size()):
		if is_equal_approx(float(sirali[i]), mevcut_hiz_carpani):
			idx = i
			break
	var sonraki = float(sirali[(idx + 1) % sirali.size()])
	hiz_sec(sonraki)

func _savas_hud_wireframe_duzenle() -> void:
	var result = hud_composer.compose_battle_wireframe({
		"ui_system": ui_system,
		"ui_node": Callable(self, "ui_node"),
		"envanter_grid": envanter_grid,
		"envanter_scroll": envanter_scroll,
		"on_command_pressed": Callable(self, "_komut_paneli_buton_tiklandi"),
	})
	hud_komut_butonlari = result.get("komut_butonlari", {})
	_komut_paneli_guncelle()

func _savas_sag_bolum_duzenle() -> void:
	var result = hud_composer.compose_right_panel(ui_root, Callable(self, "ui_node"), kazanma_puani)
	panel_sag_log_hiz = result.get("panel_sag_log_hiz")
	label_sag_osmanli = result.get("label_sag_osmanli")
	label_sag_roma = result.get("label_sag_roma")

func _komut_paneli_buton_tiklandi(komut_id: String) -> void:
	var action = HudCommands.resolve_click_action(komut_id)
	if action == "savun":
		if secili_birim != null:
			birim_nokta_savun(secili_birim)
		return
	if action == "geri_cekil":
		if secili_birim != null:
			birim_geri_cekil_baslat(secili_birim)
		return
	if action == "ult":
		ult_kullan("osmanli")
		return
	komut_sec(komut_id)

func _komut_paneli_guncelle() -> void:
	if hud_komut_butonlari.is_empty():
		return
	var secili_var = secili_birim != null
	var ult_hazir = ult_sarj["osmanli"] >= Constants.ULT_TAM_SARJ
	hud_composer.update_command_buttons(hud_komut_butonlari, secili_var, secili_komut, ult_hazir)
	hud_composer.update_selected_unit_card({
		"ui_node": Callable(self, "ui_node"),
		"secili_birim": secili_birim,
		"secili_komut": secili_komut,
		"stats_fn": Callable(self, "birim_etkin_degerleri"),
	})

func savas_paneli_olustur() -> void:
	ui_system.clear_battle_panel()
	ui_system.build_battle_panel_skeleton(func(): ult_kullan("osmanli"))
	_ui_refs_sync()

	var env_baslik = Label.new()
	env_baslik.name = "Label_Envanter"
	env_baslik.text = "Envanter: (bos)"
	ui_system.add_battle_panel_element(env_baslik)

	envanter_scroll = ScrollContainer.new()
	envanter_scroll.name = "EnvanterScroll"
	envanter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	envanter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	envanter_scroll.custom_minimum_size = Vector2(0, 52)
	ui_system.add_battle_panel_element(envanter_scroll)
	envanter_scroll.mouse_exited.connect(birim_detay_hover_bitir)

	envanter_grid = GridContainer.new()
	envanter_grid.columns = max(1, osmanli_birim_tipleri.size())
	envanter_grid.add_theme_constant_override("h_separation", 7)
	envanter_grid.add_theme_constant_override("v_separation", 0)
	envanter_scroll.add_child(envanter_grid)

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
		unit_deployment.update_selection_ui()
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
		var max_adet = unit_deployment.get_selected_group_indices().size()
		secili_envanter_gonder_adedi = min(max_adet, secili_envanter_gonder_adedi + 1)
		unit_deployment.update_selection_ui()
	)
	envanter_adet_satiri.add_child(envanter_adet_arti_btn)
	ui_system.register_battle_panel_widget(envanter_adet_arti_btn)

	var gel_baslik = Label.new()
	gel_baslik.text = "Nokta +"
	var gel_satir = HBoxContainer.new()
	gel_satir.name = "NoktaPlusSatir"
	var sirali_noktalar = Constants.NOKTA_ID_SIRALI
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

	var nokta_plus_grup = VBoxContainer.new()
	nokta_plus_grup.name = "NoktaPlusGrup"
	nokta_plus_grup.add_child(gel_baslik)
	nokta_plus_grup.add_child(gel_satir)
	ui_system.add_battle_panel_element(nokta_plus_grup)
	nokta_plus_grup.visible = false

	ui_system.build_battle_panel_footer(func(): hiz_carpani_arttir())
	_savas_hud_wireframe_duzenle()
	_savas_sag_bolum_duzenle()
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
	return unit_deployment.composition_total()

func kompozisyon_ekle(idx: int) -> void:
	unit_deployment.composition_add(idx)

func kompozisyon_cikar(idx: int) -> void:
	unit_deployment.composition_remove(idx)

func _envanter_secili_grup_indeksleri() -> Array:
	return unit_deployment.get_selected_group_indices()

func _envanter_secim_ui_guncelle() -> void:
	unit_deployment.update_selection_ui()

func envanter_olustur() -> void:
	unit_deployment.rebuild_inventory()

func envanter_sec(anahtar: String) -> void:
	unit_deployment.select_inventory(anahtar)

func birimi_gonder() -> void:
	unit_deployment.send_from_point()

func birim_haritadan_gonder(hedef_pos: Vector2) -> void:
	unit_deployment.send_from_map(hedef_pos)

func birim_satin_al(idx: int) -> void:
	unit_deployment.purchase_unit(idx)

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
	return point_economy.priority_list()

func nokta_taban_puan(nokta: String) -> int:
	return point_economy.base_score(nokta)

func nokta_taban_altin(nokta: String) -> int:
	return point_economy.base_gold(nokta)

func birim_nokta_menzilinde(birim: Dictionary, nokta: String) -> bool:
	return point_economy.unit_in_point_range(birim, nokta)

func noktadaki_taraf_sayisi(nokta: String, taraf: String) -> int:
	return point_economy.faction_count_at_point(nokta, taraf)

func hazirlik_baslat() -> void:
	battle_flow.start_preparation()

func savas_baslat() -> void:
	battle_flow.start_battle()

func hava_sec() -> void:
	var olasi = ["Acik", "Yagmur", "Sis", "Ruzgar"]
	hava_durumu = olasi[randi() % olasi.size()]

func moral_degistir(taraf: String, miktar: float) -> void:
	taraf_moral[taraf] = CombatSystem.change_moral(taraf_moral[taraf], miktar)

func taraf_moral_carpani(taraf: String) -> float:
	return CombatSystem.moral_multiplier(taraf_moral[taraf])

func general_hayatta_mi(taraf: String) -> bool:
	for b in aktif_birimler:
		if b.get("taraf", "") == taraf and b.get("hp", 0) > 0 and b.get("is_general", false):
			return true
	return false

func general_getir(taraf: String) -> Dictionary:
	for b in aktif_birimler:
		if b.get("taraf", "") == taraf and b.get("hp", 0) > 0 and b.get("is_general", false):
			return b
	return {}

func general_olustur(taraf: String) -> void:
	unit_stats.general_olustur(taraf)

func taraf_formasyon_carpani(taraf: String, stat: String) -> float:
	return CombatSystem.formation_multiplier(formasyonlar, taraf_formasyon, taraf, stat)

func terfi_seviyesi_getir(taraf: String, isim: String) -> int:
	return MetaSystem.get_promotion_level(terfi_verisi.get(taraf, {}), isim)

func terfi_kullanimi_artir(taraf: String, isim: String) -> void:
	terfi_verisi[taraf] = MetaSystem.update_promotion_state(terfi_verisi[taraf], isim)

func ult_kullan(taraf: String) -> void:
	if ult_sarj[taraf] < Constants.ULT_TAM_SARJ or ult_aktif_sure[taraf] > 0.0:
		return
	ult_sarj[taraf] = 0.0
	ult_aktif_sure[taraf] = 10.0
	moral_degistir(taraf, 8.0)

func _dar_koridor_merkez(rect: Rect2) -> Vector2:
	return unit_stats.dar_koridor_merkez(rect)

func birim_etkin_degerleri(birim: Dictionary) -> Dictionary:
	return unit_stats.birim_etkin_degerleri(birim)

func birim_olustur(baslangic: Vector2, hedef_nokta: String, taraf: String, tip: Dictionary, hedef_konum: Vector2 = Vector2(-1, -1)) -> void:
	unit_deployment.create_unit(baslangic, hedef_nokta, taraf, tip, hedef_konum)

func hasar_carpani_hesapla(saldiran: String, hedef: String) -> float:
	return unit_stats.hasar_carpani_hesapla(saldiran, hedef)

func birim_tikla(birim: Dictionary) -> void:
	var result = command_system.select_unit(birim)
	if result.get("ignored", false):
		return
	_command_refs_sync()
	_command_status_line_uygula(result)
	birim_detay_hover_bitir()
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
		if int(birim.get("id", -1)) == id and birim.get("hp", 0) > 0:
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
		_birim_detay_hover_durumunu_guncelle()

	kalan_sure -= delta
	oyun_suresi += delta
	ui_guncelle()
	minimap_guncelle()

	if hazirlik_fazi:
		ai_system.tick_preparation(delta)
		if kalan_sure <= 0:
			if kompozisyon_toplami() > 0:
				savas_baslat()
			else:
				kalan_sure = 10.0
				var kont_l = ui_node("Label_Kontenjan")
				if kont_l != null:
					kont_l.text = "Ordu kurmadan savas baslamaz!"
		_kamera_kaydirmayi_uygula(delta)
		return

	if kalan_sure <= 0:
		oyun_bitir()
		return

	ult_aktif_sure["osmanli"] = max(0.0, ult_aktif_sure["osmanli"] - delta)
	ult_aktif_sure["dogu_roma"] = max(0.0, ult_aktif_sure["dogu_roma"] - delta)
	if ult_sarj["dogu_roma"] >= Constants.ULT_TAM_SARJ:
		ult_kullan("dogu_roma")

	ai_system.tick_spawn_waves(delta)

	puan_timer += delta
	if puan_timer >= puan_interval:
		puan_timer = 0.0
		point_economy.generate_score()
		ai_system.upgrade_point()

	point_economy.tick_capture(delta)
	savas_sisi_guncelle()
	ai_system.update_units(delta)
	point_economy.tick_hold_stats(delta)
	pusu_tetik_kontrolu()
	nokta_gorunurluklerini_guncelle()
	birim_gorunurluklerini_guncelle()

	combat_loop.tick(delta)

	_kamera_kaydirmayi_uygula(delta)

	if osmanli_puani >= kazanma_puani:
		oyun_bitir_kazanan("osmanli")
	elif dogu_roma_puani >= kazanma_puani:
		oyun_bitir_kazanan("dogu_roma")

func nokta_gelistir(nokta: String) -> void:
	point_economy.upgrade_point(nokta)

func ai_nokta_gelistir() -> void:
	ai_system.upgrade_point()

func ai_ordu_hazirlik_sifirla() -> void:
	ai_system.reset_preparation_army()

func ai_ordu_ui_guncelle() -> void:
	ai_system.update_army_ui()

func ai_ordu_birim_ekle() -> void:
	ai_system.add_army_unit()

func ai_savas_envanteri_hazirla() -> void:
	ai_system.prepare_battle_inventory()

func ai_birimleri_guncelle(delta: float) -> void:
	ai_system.update_units(delta)

func ai_birim_gonder() -> void:
	ai_system.send_unit()

func oyun_sonu_paneli_goster() -> void:
	battle_flow.show_game_over_panel()

func tekrar_oyna() -> void:
	battle_flow.restart_match()

func oyun_bitir_kazanan(kazanan: String) -> void:
	battle_flow.end_match_with_winner(kazanan)

func oyun_bitir() -> void:
	battle_flow.end_match_by_score()

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
	_komut_paneli_guncelle()
	if label_sag_osmanli != null:
		label_sag_osmanli.text = "Skor OSM " + str(osmanli_puani) + "/" + str(kazanma_puani) + " • ROM " + str(dogu_roma_puani) + "/" + str(kazanma_puani)
	if label_sag_roma != null:
		label_sag_roma.text = "Moral OSM " + str(int(taraf_moral["osmanli"])) + " • ROM " + str(int(taraf_moral["dogu_roma"]))

func nokta_renkleri_sifirla() -> void:
	point_economy.reset_point_colors()

func nokta_renk_guncelle(nokta: String) -> void:
	point_economy.update_point_color(nokta)

func nokta_al(nokta: String, taraf: String) -> void:
	point_economy.capture_point(nokta, taraf)

func _input(event) -> void:
	input_router.handle_input(event)
