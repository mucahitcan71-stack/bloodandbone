# Blood and Bone — Cursor Geliştirme Kuralları

Bu proje Godot 4 ile geliştirilen bir RTS oyunudur.

Ana hedef:
Main.gd tekrar şişmesin, her yeni değişiklik ilgili sisteme/modüle eklensin.

## Ana oyun kimliği

Yeni eklenecek her sistem şu üç hedefe hizmet etmeli:

1. Keşif
2. Pusu
3. Harita hakimiyeti

Bu üçünden hiçbirini güçlendirmeyen özellik düşük önceliklidir.

## Genel çalışma kuralı

Büyük değişiklik yapma.

Her zaman:

1. Küçük adım
2. Test
3. Commit

Tek seferde birden fazla sistemi değiştirme.

HUD, Fog, Minimap, Input, Combat, AI gibi sistemleri aynı commit içinde birlikte değiştirme.

## Main.gd kuralı

Main.gd mümkün olduğunca ince orkestratör olarak kalmalı.

Main.gd içine yeni büyük oyun mantığı ekleme.

Main.gd sadece şunları yapmalı:

* Sistemleri configure etmek
* Faz geçişlerini orkestre etmek
* Tick sırasını yönetmek
* Gerekirse ince wrapper fonksiyonlar tutmak

Yeni özellik eklerken önce şu soruyu sor:

“Bu kod Main.gd’ye mi ait, yoksa mevcut sistemlerden birine mi ait?”

Main.gd’ye ait değilse ilgili sisteme ekle.

## Sistem sahiplikleri

WorldSystem:
Harita, dünya, terrain, kamera sınırları, kontrol noktası temel yerleşimi.

FogSystem:
Fog of War, görüş, keşif, görünürlük, son görülen düşman, hayalet ikonlar.

UISystem:
HUD, panel yaşam döngüsü, savaş/hazırlık arayüzü, görsel yansıma.

CommandSystem:
Birim komutları, seçili komut, saldırı, hareket, savunma, pusu, ileride attack move / stop / hold position.

InputRouter:
Sol tık, sağ tık, minimap tıklaması, komut menüsü tıklamaları, input routing.

CameraController:
WASD, ok tuşları, kenar scroll, zoom, kamera hareketi.

MinimapController:
Minimap widget, blipler, FoW texture, minimap görsel güncellemeleri.

CombatLoopSystem:
Saldırı döngüsü, hasar, ölüm, savaş içi combat tick.

BattleFlowSystem:
Hazırlık → savaş → oyun bitişi, tekrar oyna, game over akışı.

UnitDeploymentSystem:
Birim oluşturma, envanter, sahaya gönderme, takviye / yedek birlik mantığı.

AiSystem:
AI ordu hazırlığı, dalga spawn, hedef seçimi, AI birim davranışı.

PointEconomySystem:
Kontrol noktası ele geçirme, puan, altın üretimi, nokta geliştirmeleri.

PreparationController:
Hazırlık paneli, zorluk seçimi, ordu/kart/ekipman seçimi.

HUD yardımcı modülleri:
Sadece HUD görünümü, stil, metin formatlama, komut paneli, envanter paneli.

## Yeni özellik ekleme kuralı

Yeni özellik eklemeden önce:

1. Hangi sisteme ait olduğunu belirle.
2. Main.gd’ye yeni büyük blok ekleme.
3. Var olan sistemi genişlet.
4. Yoksa küçük yeni modül öner.
5. Davranışı değiştirmeden önce mevcut akışı analiz et.
6. Test listesini yaz.
7. Değişen dosyaları raporla.

## Input / Command kuralı

Input doğrudan oyun davranışı çalıştırmamalı.

Doğru akış:

InputRouter → CommandSystem → ilgili Action/System

Örnek:

Sağ tık boş arazi:
InputRouter tıkı algılar.
CommandSystem hareket emrini yorumlar.
Birim hareket fonksiyonu çalışır.

Tuşlar doğrudan saldırı/hareket yaptırmamalı.
Tuşlar sadece komut tetiklemeli.

İleride tuş yapılandırması değiştirilebilir olacağı için action-based input mantığı korunmalı.

## Sağ tık sistemi kuralı

Sağ tık akıllı emir sistemi faz faz yapılacak.

Aynı anda hepsini yapma.

Sıra:

1. Boş araziye sağ tık = hareket
2. Düşmana sağ tık = saldırı
3. Kontrol noktasına sağ tık = git / ele geçir
4. Dost birime sağ tık = destek / takip, ileride
5. Shift ile emir kuyruğu, çok daha sonra

## HUD kuralı

Komple HUD redesign yapma.

HUD değişiklikleri mikro adımlarla yapılmalı.

Örnek güvenli değişiklikler:

* Seçili komut göstergesi
* Tooltip
* Bildirim metni
* Buton görünürlüğü
* Seçili birim kartı okunurluğu

Minimap, Fog ve HUD aynı anda değiştirilmemeli.

## Fog / Minimap kuralı

FogSystem ve MinimapController hassas sistemlerdir.

Performans riski nedeniyle gereksiz dokunma.

Fog veya minimap değişirse mutlaka uzun savaş testi yapılmalı.

## Refactor kuralı

Büyük refactor yapma.

Mikro refactor yap.

Doğru örnek:

“Sadece bu fonksiyonu ilgili sisteme taşı.”

Yanlış örnek:

“Main.gd’yi komple temizle.”

Her refactor davranışı korumalı.
Refactor sonrası oyun aynı şekilde çalışmalı.

## Test kuralı

Her değişiklik sonrası manuel test listesi ver.

Minimum testler:

* Oyun açılıyor mu?
* Hazırlık ekranı çalışıyor mu?
* Birim satın alma çalışıyor mu?
* Birim sahaya gönderiliyor mu?
* Savaş başlıyor mu?
* Sol tık seçim çalışıyor mu?
* Komut menüsü açılıyor mu?
* Hareket çalışıyor mu?
* Saldırı çalışıyor mu?
* Kamera hareketi çalışıyor mu?
* Minimap çalışıyor mu?
* 2-3 dakika savaşta donma var mı?

## Raporlama kuralı

Her cevabın sonunda şunları yaz:

* Değişen dosyalar
* Neden bu dosyalara dokunuldu
* Main.gd’ye yeni yük eklendi mi?
* Hangi sistemlerin davranışı değişti?
* Test listesi
* Commit mesajı önerisi

## Yasaklar

Şunları yapma:

* Main.gd’ye büyük yeni sistem ekleme
* Birden fazla büyük sistemi aynı anda değiştirme
* HUD + Fog + Minimap’i aynı anda değiştirme
* Input + Command + UI’ı aynı anda büyük şekilde değiştirme
* Çalışan sistemi gereksiz yere baştan yazma
* Test etmeden yeni adıma geçme
* “Temizlik” adı altında davranış değiştirme

## Şu anki öncelik

Öncelik sırası:

1. Refactorlu son sürümü stabilize etmek
2. InputRouter / CommandSystem sınırını sağlamlaştırmak
3. Sağ tık boş arazi hareketini küçük adımla eklemek
4. Seçili komut göstergesi ve command feedback eklemek
5. Sağ tık düşman saldırısı
6. Sağ tık kontrol noktası ele geçirme
7. Yedek birlik / takviye havuzu sistemini sonra geliştirmek
8. HUD polish
9. Pusu sistemini derinleştirmek
10. Fog/minimap büyük değişikliklerini en sona bırakmak

Ana kural:
Kod çalışıyorsa önce koru, sonra küçük küçük iyileştir.
