# Blood and Bone - devam notu

Son calisma: 7 Kasim 2026

## Mevcut durum
- Fog sistemi uc durumlu hale getirildi: bilinmeyen, kesfedilmis/gorus disi, aktif gorus.
- Minimap ayni durumlari kullaniyor. Degismeyen sis dokusu yeniden yuklenmiyor.
- Godot 4.6.3 headless davranis testleri gecti; gorsel sonuc kullanicinin hedefini karsilamiyor.
- Degisen kod: scripts/systems/fog_system.gd ve assets/shaders/fog_of_war.gdshader.
- Tepe/vadi gorus engellemesi ve duvar engellemesi HENUZ uygulanmadi.

## Kullanicinin asil hedefi
Oyun amatorce gorunuyor. Yeni mekaniklerden once gorsel kalite hedeflenmeli.
Kullanici oyunda cok az asset oldugunu, buldugu ucretsiz assetlerin kalitesinden memnun olmadigini belirtti.
Ucretli asset icin butce henuz belirlenmedi; satin alma yapilmadi.

## Sonraki oturum
1. Tutarlilik gosteren gorsel referanslar ve sanat yonu belirle.
2. Mevcut asset envanterini incele; eksikleri kale/cevre/asker/animasyon/UI olarak somutlastir.
3. Uyumlu asset paketlerini arastir; fiyat, lisans, Godot aktarimi ve olcek uyumunu karsilastir.
4. Kale ve cevresinden olusan kucuk bir bolgeyi ornek kaliteye getir.
5. Sis siniri (baklava seklindeki koyu alan), kucuk/koseli gorus lekeleri ve okunabilirligi duzelt.
6. Gelistirici yazilari ve yogun HUD icin oyuncu gorunumu hazirla.
7. Once/sonra gorsel kontrol yap; hedef tutmadan tum haritaya yayma.

## Referans arsivleri
Inceleme dosyalari gereksizler/ altinda; oyun kaynaklarina ve Git kaydina dahil edilmemeli.
- Witcher FogOfWar: kalici kesif, sikistirilmis grid, ikon filtreleme.
- Godot Open RTS: gorus ve birim gizleme ayrimi, son bilinen yapi gorseli.
- Godot Visibility Polygon: duvar segmentleri uzerinden 2B gorus poligonu.
- Unity Fog of War: raycast ile engel ve kenar cozumu.
- MangoFog: yukseklik gridinde gorus hatti, kesif/anlik gorus ayrimi, yumusak gecis.

## Git
Son dogrulanmis uzak kayit: b85b92e, izometrik-deneme dali.
Bu oturumun degisikliklerinin GitHub'a gonderildigi ayrica dogrulanmali.