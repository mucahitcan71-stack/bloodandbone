extends Node2D

# === OYUN DEĞİŞKENLERİ ===
var oyun_bitti = false
var oyun_suresi = 0.0
var max_sure = 1200.0

# === ZORLUK ===
var zorluk = "orta"
var zorluk_ayarlari = {
    "kolay": {"spawn": 20.0, "guc_carpan": 0.8, "savunma_carpan": 0.8},
    "orta":  {"spawn": 12.0, "guc_carpan": 1.0, "savunma_carpan": 1.0},
    "zor":   {"spawn": 7.0,  "guc_carpan": 1.3, "savunma_carpan": 1.3},
}

# === PUAN & ALTIN ===
var osmanli_puani = 0
var dogu_roma_puani = 0
var kazanma_puani = 200
var osmanli_altini = 30
var dogu_roma_altini = 30
var puan_timer = 0.0
var puan_interval = 15.0

# === HAZIRLIK ===
var hazirlik_suresi = 60.0
var kalan_sure = 60.0
var hazirlik_fazi = true

# === KONTROL NOKTALARI ===
var nokta_konumlari = {
    "A": Vector2(200, 300),
    "B": Vector2(500, 300),
    "C": Vector2(800, 300)
}
var nokta_sahipleri = {"A": "tarafsiz", "B": "tarafsiz", "C": "tarafsiz"}
var nokta_birimleri = {"A": [], "B": [], "C": []}

var nokta_capture = {"A": 50.0, "B": 50.0, "C": 50.0}
var capture_hizi = 3.0

var nokta_puan = {"A": 1, "B": 3, "C": 1}
var nokta_altin = {"A": 3, "B": 6, "C": 3}

# === BİRİM TİPLERİ ===
var osmanli_birim_tipleri = [
    {"isim": "Akinci", "hiz": 120.0, "renk": Color(1, 0.8, 0), "sembol": "🐎",
     "guc": 25, "savunma": 5, "hp": 40, "kontenjan": 1, "maliyet": 10, "asker_sayisi": 25, "menzil": 80.0},
    {"isim": "Yeniceeri", "hiz": 70.0, "renk": Color(0.8, 0.6, 0), "sembol": "⚔",
     "guc": 35, "savunma": 20, "hp": 100, "kontenjan": 3, "maliyet": 25, "asker_sayisi": 20, "menzil": 60.0},
    {"isim": "Topcu", "hiz": 40.0, "renk": Color(0.6, 0.4, 0), "sembol": "💣",
     "guc": 60, "savunma": 10, "hp": 70, "kontenjan": 10, "maliyet": 50, "asker_sayisi": 10, "menzil": 200.0},
]

var dogu_roma_birim_tipleri = [
    {"isim": "Kataphraktoi", "hiz": 80.0, "renk": Color(0.5, 0, 0.8), "sembol": "🛡",
     "guc": 20, "savunma": 20, "hp": 80, "kontenjan": 3, "maliyet": 25, "asker_sayisi": 12, "menzil": 70.0},
    {"isim": "Toksotai", "hiz": 60.0, "renk": Color(0.3, 0, 0.6), "sembol": "🏹",
     "guc": 15, "savunma": 5, "hp": 30, "kontenjan": 1, "maliyet": 10, "asker_sayisi": 20, "menzil": 180.0},
    {"isim": "Skoutatoi", "hiz": 35.0, "renk": Color(0.2, 0, 0.5), "sembol": "⚔",
     "guc": 18, "savunma": 15, "hp": 70, "kontenjan": 3, "maliyet": 20, "asker_sayisi": 18, "menzil": 50.0},
]

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

# === SEÇİM ===
var secili_nokta = ""
var secili_envanter_idx = -1
var secili_birim = null

# === UI ===
var hazirlik_paneli = []
var savas_paneli = []
var envanter_butonlari = []
var sayi_labellar = []
var capture_barlar = {}
var zorluk_butonlari = {}

func _ready() -> void:
    randomize()
    kontrol_noktalari_olustur()
    $CanvasLayer/Label_Osmanli.position = Vector2(20, 20)
    $CanvasLayer/Label_DoguRoma.position = Vector2(850, 20)
    $CanvasLayer/Label_Round.position = Vector2(450, 20)
    $CanvasLayer/Label_Sure.position = Vector2(450, 45)
    hazirlik_paneli_olustur()
    savas_paneli_olustur()
    hazirlik_baslat()

func kontrol_noktalari_olustur() -> void:
    for nokta in nokta_konumlari:
        var kare = ColorRect.new()
        kare.color = Color.GRAY
        kare.size = Vector2(80, 80)
        kare.position = nokta_konumlari[nokta]
        kare.name = "Nokta_" + nokta
        add_child(kare)

        var isim_l = Label.new()
        isim_l.text = nokta
        isim_l.position = nokta_konumlari[nokta] + Vector2(30, 30)
        add_child(isim_l)

        var bar_bg = ColorRect.new()
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
        puan_l.text = "+" + str(nokta_puan[nokta])
        puan_l.position = nokta_konumlari[nokta] + Vector2(30, -20)
        add_child(puan_l)

func hazirlik_paneli_olustur() -> void:
    var zorluk_baslik = Label.new()
    zorluk_baslik.text = "ZORLUK SEC:"
    zorluk_baslik.position = Vector2(20, 460)
    $CanvasLayer.add_child(zorluk_baslik)
    hazirlik_paneli.append(zorluk_baslik)

    var zorluklar = [
        {"isim": "kolay", "text": "🟢 KOLAY"},
        {"isim": "orta",  "text": "🟡 ORTA"},
        {"isim": "zor",   "text": "🔴 ZOR"},
    ]

    var zx = 20
    for z in zorluklar:
        var btn = Button.new()
        btn.text = z["text"]
        btn.position = Vector2(zx, 480)
        btn.size = Vector2(100, 35)
        var z_isim = z["isim"]
        btn.pressed.connect(func(): zorluk_sec(z_isim))
        $CanvasLayer.add_child(btn)
        hazirlik_paneli.append(btn)
        zorluk_butonlari[z["isim"]] = btn
        zx += 110

    var secili_l = Label.new()
    secili_l.name = "Label_Zorluk"
    secili_l.position = Vector2(20, 520)
    secili_l.text = "Secili: ORTA"
    $CanvasLayer.add_child(secili_l)
    hazirlik_paneli.append(secili_l)

    var ayrac = Label.new()
    ayrac.text = "─────────────────────────────────"
    ayrac.position = Vector2(20, 538)
    $CanvasLayer.add_child(ayrac)
    hazirlik_paneli.append(ayrac)

    var baslik = Label.new()
    baslik.text = "ORDU KUR:"
    baslik.position = Vector2(150, 550)
    $CanvasLayer.add_child(baslik)
    hazirlik_paneli.append(baslik)

    var lk = Label.new()
    lk.name = "Label_Kontenjan"
    lk.position = Vector2(150, 568)
    lk.text = "Kontenjan: 30/30"
    $CanvasLayer.add_child(lk)
    hazirlik_paneli.append(lk)

    var x = 150
    for i in range(osmanli_birim_tipleri.size()):
        var tip = osmanli_birim_tipleri[i]

        var isim_l = Label.new()
        isim_l.text = tip["sembol"] + " " + tip["isim"] + " (" + str(tip["kontenjan"]) + "kt)"
        isim_l.position = Vector2(x, 585)
        $CanvasLayer.add_child(isim_l)
        hazirlik_paneli.append(isim_l)

        var btn_eksi = Button.new()
        btn_eksi.text = "-"
        btn_eksi.position = Vector2(x, 605)
        btn_eksi.size = Vector2(30, 30)
        var idx = i
        btn_eksi.pressed.connect(func(): kompozisyon_cikar(idx))
        $CanvasLayer.add_child(btn_eksi)
        hazirlik_paneli.append(btn_eksi)

        var sayi_l = Label.new()
        sayi_l.text = "0"
        sayi_l.position = Vector2(x + 35, 612)
        sayi_l.name = "Komp_" + str(i)
        $CanvasLayer.add_child(sayi_l)
        sayi_labellar.append(sayi_l)
        hazirlik_paneli.append(sayi_l)

        var btn_arti = Button.new()
        btn_arti.text = "+"
        btn_arti.position = Vector2(x + 55, 605)
        btn_arti.size = Vector2(30, 30)
        btn_arti.pressed.connect(func(): kompozisyon_ekle(idx))
        $CanvasLayer.add_child(btn_arti)
        hazirlik_paneli.append(btn_arti)

        x += 250

    var savas_btn = Button.new()
    savas_btn.name = "SavasBtn"
    savas_btn.text = "⚔ SAVASA BASLA"
    savas_btn.position = Vector2(900, 595)
    savas_btn.size = Vector2(180, 45)
    savas_btn.pressed.connect(func(): savas_baslat())
    $CanvasLayer.add_child(savas_btn)
    hazirlik_paneli.append(savas_btn)

func zorluk_sec(secilen: String) -> void:
    zorluk = secilen
    ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]
    var isimler = {"kolay": "KOLAY", "orta": "ORTA", "zor": "ZOR"}
    $CanvasLayer/Label_Zorluk.text = "Secili: " + isimler[zorluk]
    for z in zorluk_butonlari:
        zorluk_butonlari[z].modulate = Color(1.5, 1.5, 1.5) if z == zorluk else Color(1, 1, 1)

func savas_paneli_olustur() -> void:
    var ln = Label.new()
    ln.name = "Label_SeciliNokta"
    ln.position = Vector2(20, 460)
    ln.text = "Nokta: Yok"
    $CanvasLayer.add_child(ln)
    savas_paneli.append(ln)

    var lb = Label.new()
    lb.name = "Label_SeciliBirim"
    lb.position = Vector2(20, 480)
    lb.text = "Birim: Yok"
    $CanvasLayer.add_child(lb)
    savas_paneli.append(lb)

    var gonder = Button.new()
    gonder.name = "GonderBtn"
    gonder.text = "➤ GONDER"
    gonder.position = Vector2(20, 500)
    gonder.size = Vector2(120, 35)
    gonder.pressed.connect(func(): birimi_gonder())
    $CanvasLayer.add_child(gonder)
    savas_paneli.append(gonder)

    var altin_l = Label.new()
    altin_l.name = "Label_Altin"
    altin_l.position = Vector2(20, 545)
    altin_l.text = "🪙 Altin: 30"
    $CanvasLayer.add_child(altin_l)
    savas_paneli.append(altin_l)

    var secili_birim_l = Label.new()
    secili_birim_l.name = "Label_SeciliBirimHarita"
    secili_birim_l.position = Vector2(20, 565)
    secili_birim_l.text = ""
    $CanvasLayer.add_child(secili_birim_l)
    savas_paneli.append(secili_birim_l)

    var satin_baslik = Label.new()
    satin_baslik.text = "Takviye Cagir:"
    satin_baslik.position = Vector2(160, 455)
    $CanvasLayer.add_child(satin_baslik)
    savas_paneli.append(satin_baslik)

    var sx = 160
    for i in range(osmanli_birim_tipleri.size()):
        var tip = osmanli_birim_tipleri[i]
        var btn = Button.new()
        btn.text = tip["sembol"] + " " + tip["isim"] + "\n" + str(tip["maliyet"]) + "🪙"
        btn.position = Vector2(sx, 470)
        btn.size = Vector2(130, 50)
        var idx = i
        btn.pressed.connect(func(): birim_satin_al(idx))
        $CanvasLayer.add_child(btn)
        savas_paneli.append(btn)
        sx += 145

    var env_baslik = Label.new()
    env_baslik.name = "Label_Envanter"
    env_baslik.position = Vector2(160, 530)
    env_baslik.text = "Envanter:"
    $CanvasLayer.add_child(env_baslik)
    savas_paneli.append(env_baslik)

    for el in savas_paneli:
        if is_instance_valid(el):
            el.visible = false

func kompozisyon_ekle(idx: int) -> void:
    var tip = osmanli_birim_tipleri[idx]
    if mevcut_kontenjan < tip["kontenjan"]:
        return
    mevcut_kontenjan -= tip["kontenjan"]
    kompozisyon[idx] += 1
    sayi_labellar[idx].text = str(kompozisyon[idx])
    $CanvasLayer/Label_Kontenjan.text = "Kontenjan: " + str(mevcut_kontenjan) + "/" + str(max_kontenjan)

func kompozisyon_cikar(idx: int) -> void:
    if kompozisyon[idx] <= 0:
        return
    var tip = osmanli_birim_tipleri[idx]
    mevcut_kontenjan += tip["kontenjan"]
    kompozisyon[idx] -= 1
    sayi_labellar[idx].text = str(kompozisyon[idx])
    $CanvasLayer/Label_Kontenjan.text = "Kontenjan: " + str(mevcut_kontenjan) + "/" + str(max_kontenjan)

func envanter_olustur() -> void:
    for btn in envanter_butonlari:
        if is_instance_valid(btn):
            btn.queue_free()
    envanter_butonlari.clear()

    var x = 160
    for i in range(envanter.size()):
        var tip = envanter[i]
        var btn = Button.new()
        btn.text = tip["sembol"] + " " + tip["isim"]
        btn.position = Vector2(x, 548)
        btn.size = Vector2(110, 30)
        var idx = i
        btn.pressed.connect(func(): envanter_sec(idx))
        $CanvasLayer.add_child(btn)
        envanter_butonlari.append(btn)
        x += 120

func envanter_sec(idx: int) -> void:
    secili_envanter_idx = idx
    secili_birim = null
    var tip = envanter[idx]
    $CanvasLayer/Label_SeciliBirim.text = "Birim: " + tip["sembol"] + " " + tip["isim"]
    $CanvasLayer/Label_SeciliBirimHarita.text = ""

func nokta_sec(nokta: String) -> void:
    secili_nokta = nokta
    $CanvasLayer/Label_SeciliNokta.text = "Nokta: " + nokta
    nokta_vurgula()

func nokta_vurgula() -> void:
    for nokta in nokta_konumlari:
        var kare = get_node("Nokta_" + nokta)
        kare.modulate = Color(1.5, 1.5, 1.5) if nokta == secili_nokta else Color(1, 1, 1)

func hedef_konum_hesapla(nokta: String, taraf: String) -> Vector2:
    var taraf_birimleri = 0
    for b in nokta_birimleri[nokta]:
        if b["taraf"] == taraf:
            taraf_birimleri += 1

    var sutun = taraf_birimleri % 4
    var satir = taraf_birimleri / 4

    if taraf == "osmanli":
        return Vector2(
            nokta_konumlari[nokta].x - 30 + sutun * 35,
            nokta_konumlari[nokta].y + 90 + satir * 35
        )
    else:
        return Vector2(
            nokta_konumlari[nokta].x - 30 + sutun * 35,
            nokta_konumlari[nokta].y - 100 - satir * 35
        )

func birimi_gonder() -> void:
    if secili_nokta == "":
        print("Once nokta sec!")
        return
    if secili_envanter_idx < 0 or secili_envanter_idx >= envanter.size():
        print("Once birim sec!")
        return

    var tip = envanter[secili_envanter_idx]
    envanter.remove_at(secili_envanter_idx)
    secili_envanter_idx = -1
    $CanvasLayer/Label_SeciliBirim.text = "Birim: Yok"

    var hk = hedef_konum_hesapla(secili_nokta, "osmanli")
    birim_olustur(Vector2(nokta_konumlari[secili_nokta].x, 560), secili_nokta, "osmanli", tip, hk)
    envanter_olustur()

func birim_satin_al(idx: int) -> void:
    var tip = osmanli_birim_tipleri[idx]
    if osmanli_altini < tip["maliyet"]:
        print("Yeterli altin yok!")
        return
    osmanli_altini -= tip["maliyet"]
    envanter.append(tip.duplicate())
    envanter_olustur()
    $CanvasLayer/Label_Altin.text = "🪙 Altin: " + str(osmanli_altini)

func hazirlik_baslat() -> void:
    hazirlik_fazi = true
    kalan_sure = hazirlik_suresi
    mevcut_kontenjan = max_kontenjan
    kompozisyon = [0, 0, 0]
    envanter.clear()
    secili_nokta = ""
    secili_envanter_idx = -1
    secili_birim = null
    nokta_birimleri = {"A": [], "B": [], "C": []}
    nokta_capture = {"A": 50.0, "B": 50.0, "C": 50.0}
    osmanli_puani = 0
    dogu_roma_puani = 0
    osmanli_altini = 30
    dogu_roma_altini = 30
    oyun_suresi = 0.0
    puan_timer = 0.0
    oyun_bitti = false
    ai_spawn_timer = 0.0
    ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]

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
    $CanvasLayer/Label_Kontenjan.text = "Kontenjan: " + str(max_kontenjan) + "/" + str(max_kontenjan)

    for el in hazirlik_paneli:
        if is_instance_valid(el):
            el.visible = true
    for el in savas_paneli:
        if is_instance_valid(el):
            el.visible = false

    nokta_renkleri_sifirla()
    ui_guncelle()

func savas_baslat() -> void:
    if oyun_bitti:
        return
    hazirlik_fazi = false
    kalan_sure = max_sure
    ai_spawn_suresi = zorluk_ayarlari[zorluk]["spawn"]

    for i in range(osmanli_birim_tipleri.size()):
        for j in range(kompozisyon[i]):
            envanter.append(osmanli_birim_tipleri[i].duplicate())

    for el in hazirlik_paneli:
        if is_instance_valid(el):
            el.visible = false
    for el in savas_paneli:
        if is_instance_valid(el):
            el.visible = true

    envanter_olustur()
    ui_guncelle()
    print("=== SAVAS BASLADI === Zorluk: " + zorluk)

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
    if taraf == "dogu_roma":
        guc = int(guc * zorluk_ayarlari[zorluk]["guc_carpan"])
        savunma = int(savunma * zorluk_ayarlari[zorluk]["savunma_carpan"])
        hp = hp * zorluk_ayarlari[zorluk]["guc_carpan"]

    var birim = {
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
        "noktada": false,
        "saldirim_timer": 0.0,
        "hasar_verilen": 0,
        "bekleyen_hasar": 0.0,
        "secili": false,
        "savas_halinde": false  # Noktada olmadan savaşıyor mu
    }
    aktif_birimler.append(birim)

func birim_tikla(birim: Dictionary) -> void:
    if birim["taraf"] != "osmanli":
        return

    if secili_birim != null and secili_birim != birim:
        secili_birim["secili"] = false
        if is_instance_valid(secili_birim["node"]):
            secili_birim["node"].modulate = Color(1, 1, 1)

    secili_birim = birim
    birim["secili"] = true
    birim["node"].modulate = Color(1.5, 1.5, 0.5)

    $CanvasLayer/Label_SeciliBirimHarita.text = "Secili: " + birim["isim"] + " (Menzil: " + str(int(birim["menzil"])) + "px)"
    secili_envanter_idx = -1
    $CanvasLayer/Label_SeciliBirim.text = "Birim: Yok"

func birim_hareket_ettir(hedef_pos: Vector2) -> void:
    if secili_birim == null:
        return

    if secili_birim["noktada"]:
        var eski_nokta = secili_birim["hedef_nokta"]
        nokta_birimleri[eski_nokta].erase(secili_birim)
        secili_birim["noktada"] = false
        secili_birim["savas_halinde"] = false
        capture_sahip_guncelle(eski_nokta)

    secili_birim["hedef"] = hedef_pos
    secili_birim["savas_halinde"] = false

    secili_birim["secili"] = false
    if is_instance_valid(secili_birim["node"]):
        secili_birim["node"].modulate = Color(1, 1, 1)
    secili_birim = null
    $CanvasLayer/Label_SeciliBirimHarita.text = ""

func _process(delta: float) -> void:
    if oyun_bitti:
        return

    kalan_sure -= delta
    oyun_suresi += delta
    ui_guncelle()

    if hazirlik_fazi:
        if kalan_sure <= 0:
            savas_baslat()
        return

    if kalan_sure <= 0:
        oyun_bitir()
        return

    ai_spawn_timer += delta
    if ai_spawn_timer >= ai_spawn_suresi:
        ai_spawn_timer = 0.0
        ai_birim_gonder()

    puan_timer += delta
    if puan_timer >= puan_interval:
        puan_timer = 0.0
        puan_uret()

    capture_guncelle(delta)

    # === SALDIRI SİSTEMİ ===
    # Hem noktada hem de serbest alanda savaş
    for birim in aktif_birimler:
        if birim["hp"] <= 0:
            continue

        birim["saldirim_timer"] += delta
        if birim["saldirim_timer"] < 1.0:
            continue
        birim["saldirim_timer"] = 0.0

        var dusman_listesi = []

        if birim["noktada"]:
            # Noktadaki düşmanlarla savaş
            var nokta = birim["hedef_nokta"]
            for b in nokta_birimleri[nokta]:
                if b["taraf"] != birim["taraf"] and b["hp"] > 0:
                    dusman_listesi.append(b)
        else:
            # Menzildeki tüm düşmanlarla savaş
            for b in aktif_birimler:
                if b["taraf"] != birim["taraf"] and b["hp"] > 0:
                    if birim["konum"].distance_to(b["konum"]) <= birim["menzil"]:
                        dusman_listesi.append(b)

        if dusman_listesi.is_empty():
            birim["savas_halinde"] = false
            continue

        birim["savas_halinde"] = true
        var hasar_per = max(1.0, float(birim["guc"]) / float(dusman_listesi.size()))
        for dusman in dusman_listesi:
            var gercek_hasar = max(1.0, hasar_per - float(dusman["savunma"]))
            dusman["bekleyen_hasar"] += gercek_hasar
            birim["hasar_verilen"] += int(gercek_hasar)

    # Hasarları uygula
    for birim in aktif_birimler:
        if birim["bekleyen_hasar"] > 0:
            birim["hp"] -= birim["bekleyen_hasar"]
            birim["bekleyen_hasar"] = 0.0

    # Hareket ve temizlik
    var silinecekler = []
    for birim in aktif_birimler:
        if birim["hp"] <= 0:
            if birim["noktada"]:
                nokta_birimleri[birim["hedef_nokta"]].erase(birim)
                capture_sahip_guncelle(birim["hedef_nokta"])
            if birim == secili_birim:
                secili_birim = null
            birim["node"].queue_free()
            silinecekler.append(birim)
            continue

        # Savaş halindeyse dur, menzilinde düşman var
        var dusman_menzilde = false
        if not birim["noktada"]:
            for b in aktif_birimler:
                if b["taraf"] != birim["taraf"] and b["hp"] > 0:
                    if birim["konum"].distance_to(b["konum"]) <= birim["menzil"]:
                        dusman_menzilde = true
                        break

        if dusman_menzilde:
            # Dur ve savaş
            pass
        else:
            birim["savas_halinde"] = false
            var mesafe = birim["hedef"] - birim["konum"]
            if mesafe.length() > 5 and not birim["noktada"]:
                var yon = mesafe.normalized()
                birim["konum"] += yon * birim["hiz"] * delta
                birim["node"].position = birim["konum"]
            else:
                if not birim["noktada"]:
                    # En yakın noktayı kontrol et
                    var en_yakin_nokta = ""
                    var en_yakin_mesafe = 60.0
                    for nokta in nokta_konumlari:
                        var d = birim["konum"].distance_to(nokta_konumlari[nokta] + Vector2(40, 40))
                        if d < en_yakin_mesafe:
                            en_yakin_mesafe = d
                            en_yakin_nokta = nokta

                    if en_yakin_nokta != "":
                        birim["noktada"] = true
                        birim["hedef_nokta"] = en_yakin_nokta
                        nokta_birimleri[en_yakin_nokta].append(birim)
                        capture_sahip_guncelle(en_yakin_nokta)
                        print(birim["isim"] + " Nokta " + en_yakin_nokta + "'ye ulasti!")

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

    if osmanli_puani >= kazanma_puani:
        oyun_bitir_kazanan("osmanli")
    elif dogu_roma_puani >= kazanma_puani:
        oyun_bitir_kazanan("dogu_roma")

func capture_guncelle(delta: float) -> void:
    for nokta in nokta_konumlari:
        var osmanli_sayisi = 0
        var dogu_roma_sayisi = 0
        for b in nokta_birimleri[nokta]:
            if b["taraf"] == "osmanli":
                osmanli_sayisi += 1
            elif b["taraf"] == "dogu_roma":
                dogu_roma_sayisi += 1

        if osmanli_sayisi > dogu_roma_sayisi:
            nokta_capture[nokta] = min(100.0, nokta_capture[nokta] + capture_hizi * delta * osmanli_sayisi)
        elif dogu_roma_sayisi > osmanli_sayisi:
            nokta_capture[nokta] = max(0.0, nokta_capture[nokta] - capture_hizi * delta * dogu_roma_sayisi)

        if capture_barlar.has(nokta):
            capture_barlar[nokta].size.x = 80.0 * (nokta_capture[nokta] / 100.0)

        capture_sahip_guncelle(nokta)

func capture_sahip_guncelle(nokta: String) -> void:
    if nokta_capture[nokta] >= 100.0:
        nokta_al(nokta, "osmanli")
    elif nokta_capture[nokta] <= 0.0:
        nokta_al(nokta, "dogu_roma")
    else:
        nokta_al(nokta, "tarafsiz")

func puan_uret() -> void:
    for nokta in nokta_sahipleri:
        if nokta_sahipleri[nokta] == "osmanli":
            osmanli_puani += nokta_puan[nokta]
            osmanli_altini += nokta_altin[nokta]
        elif nokta_sahipleri[nokta] == "dogu_roma":
            dogu_roma_puani += nokta_puan[nokta]
            dogu_roma_altini += nokta_altin[nokta]

    var osmanli_nokta = 0
    var dogu_roma_nokta = 0
    for nokta in nokta_sahipleri:
        if nokta_sahipleri[nokta] == "osmanli":
            osmanli_nokta += 1
        elif nokta_sahipleri[nokta] == "dogu_roma":
            dogu_roma_nokta += 1

    if osmanli_nokta == 3:
        osmanli_puani += 1
        osmanli_altini += 5
    elif dogu_roma_nokta == 3:
        dogu_roma_puani += 1
        dogu_roma_altini += 5

    $CanvasLayer/Label_Altin.text = "🪙 Altin: " + str(osmanli_altini)

func ai_birim_gonder() -> void:
    var hedef = ai_hedef_sec()
    var tip = dogu_roma_birim_tipleri[randi() % dogu_roma_birim_tipleri.size()]
    var hk = hedef_konum_hesapla(hedef, "dogu_roma")
    birim_olustur(Vector2(nokta_konumlari[hedef].x, 50), hedef, "dogu_roma", tip, hk)

func ai_hedef_sec() -> String:
    for nokta in ["B", "A", "C"]:
        if nokta_sahipleri[nokta] == "tarafsiz":
            return nokta

    var en_zayif = ""
    var en_az = 999
    for nokta in nokta_sahipleri:
        if nokta_sahipleri[nokta] == "osmanli":
            var say = 0
            for b in nokta_birimleri[nokta]:
                if b["taraf"] == "osmanli":
                    say += 1
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

    var noktalar = ["A", "B", "C"]
    return noktalar[randi() % noktalar.size()]

func oyun_bitir_kazanan(kazanan: String) -> void:
    oyun_bitti = true
    if kazanan == "osmanli":
        $CanvasLayer/Label_Round.text = "OSMANLI KAZANDI! 🎉"
    else:
        $CanvasLayer/Label_Round.text = "DOGU ROMA KAZANDI! 🎉"

func oyun_bitir() -> void:
    oyun_bitti = true
    if osmanli_puani > dogu_roma_puani:
        oyun_bitir_kazanan("osmanli")
    elif dogu_roma_puani > osmanli_puani:
        oyun_bitir_kazanan("dogu_roma")
    else:
        $CanvasLayer/Label_Round.text = "BERABERE!"

func ui_guncelle() -> void:
    $CanvasLayer/Label_Osmanli.text = "⚔ Osmanli: " + str(osmanli_puani) + "/" + str(kazanma_puani)
    $CanvasLayer/Label_DoguRoma.text = "Dogu Roma: " + str(dogu_roma_puani) + "/" + str(kazanma_puani) + " 🛡"
    if hazirlik_fazi:
        $CanvasLayer/Label_Round.text = "HAZIRLIK"
        $CanvasLayer/Label_Sure.text = "Kalan: " + str(int(kalan_sure)) + "s"
    else:
        $CanvasLayer/Label_Round.text = "SAVAS DEVAM EDIYOR"
        var dk = int(kalan_sure) / 60
        var sn = int(kalan_sure) % 60
        $CanvasLayer/Label_Sure.text = str(dk) + ":" + str(sn).pad_zeros(2)

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
    nokta_sahipleri[nokta] = taraf
    nokta_renk_guncelle(nokta)

func _input(event) -> void:
    if oyun_bitti:
        return
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if event.position.y > 450:
                return
            if not hazirlik_fazi:
                var birim_tiklandi = false
                for birim in aktif_birimler:
                    if birim["taraf"] == "osmanli" and birim["hp"] > 0:
                        var birim_rect = Rect2(birim["konum"], Vector2(30, 30))
                        if birim_rect.has_point(event.position):
                            birim_tikla(birim)
                            birim_tiklandi = true
                            break

                if not birim_tiklandi:
                    if secili_birim != null:
                        birim_hareket_ettir(event.position)
                    else:
                        if event.position.x > 160 and event.position.x < 290 and event.position.y > 280 and event.position.y < 400:
                            nokta_sec("A")
                        elif event.position.x > 460 and event.position.x < 590 and event.position.y > 280 and event.position.y < 400:
                            nokta_sec("B")
                        elif event.position.x > 760 and event.position.x < 890 and event.position.y > 280 and event.position.y < 400:
                            nokta_sec("C")
