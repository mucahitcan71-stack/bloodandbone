extends RefCounted
class_name PropKatalog

const MODEL_KOK := "res://assets/proplar/doga/"
const MODEL_YAPI_KOK := "res://assets/proplar/yapilar/"

# Yeni prop: bu diziye tek satir ekle -> editor paleti + oyun otomatik.
const KATALOG: Array[Dictionary] = [
	# --- Agaclar (8.0) ---
	{"id": "common_1", "isim": "Agac 1", "model": MODEL_KOK + "CommonTree_1.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "common_2", "isim": "Agac 2", "model": MODEL_KOK + "CommonTree_2.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "common_3", "isim": "Agac 3", "model": MODEL_KOK + "CommonTree_3.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "common_4", "isim": "Agac 4", "model": MODEL_KOK + "CommonTree_4.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "common_5", "isim": "Agac 5", "model": MODEL_KOK + "CommonTree_5.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "pine_1", "isim": "Cam 1", "model": MODEL_KOK + "Pine_1.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "pine_2", "isim": "Cam 2", "model": MODEL_KOK + "Pine_2.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "pine_3", "isim": "Cam 3", "model": MODEL_KOK + "Pine_3.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "pine_4", "isim": "Cam 4", "model": MODEL_KOK + "Pine_4.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "pine_5", "isim": "Cam 5", "model": MODEL_KOK + "Pine_5.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "twisted_1", "isim": "Bukumlu 1", "model": MODEL_KOK + "TwistedTree_1.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "twisted_2", "isim": "Bukumlu 2", "model": MODEL_KOK + "TwistedTree_2.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "twisted_3", "isim": "Bukumlu 3", "model": MODEL_KOK + "TwistedTree_3.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "twisted_4", "isim": "Bukumlu 4", "model": MODEL_KOK + "TwistedTree_4.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "twisted_5", "isim": "Bukumlu 5", "model": MODEL_KOK + "TwistedTree_5.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "dead_1", "isim": "Olu Agac 1", "model": MODEL_KOK + "DeadTree_1.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "dead_2", "isim": "Olu Agac 2", "model": MODEL_KOK + "DeadTree_2.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "dead_3", "isim": "Olu Agac 3", "model": MODEL_KOK + "DeadTree_3.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "dead_4", "isim": "Olu Agac 4", "model": MODEL_KOK + "DeadTree_4.gltf", "olcek": 8.0, "kategori": "agac"},
	{"id": "dead_5", "isim": "Olu Agac 5", "model": MODEL_KOK + "DeadTree_5.gltf", "olcek": 8.0, "kategori": "agac"},
	# --- Taslar ---
	{"id": "rock_1", "isim": "Kaya 1", "model": MODEL_KOK + "Rock_Medium_1.gltf", "olcek": 6.0, "kategori": "tas"},
	{"id": "rock_2", "isim": "Kaya 2", "model": MODEL_KOK + "Rock_Medium_2.gltf", "olcek": 6.0, "kategori": "tas"},
	{"id": "rock_3", "isim": "Kaya 3", "model": MODEL_KOK + "Rock_Medium_3.gltf", "olcek": 6.0, "kategori": "tas"},
	{"id": "pebble_r1", "isim": "Cakil Yuvarlak 1", "model": MODEL_KOK + "Pebble_Round_1.gltf", "olcek": 3.0, "kategori": "tas"},
	{"id": "pebble_r2", "isim": "Cakil Yuvarlak 2", "model": MODEL_KOK + "Pebble_Round_2.gltf", "olcek": 3.0, "kategori": "tas"},
	{"id": "pebble_r3", "isim": "Cakil Yuvarlak 3", "model": MODEL_KOK + "Pebble_Round_3.gltf", "olcek": 3.0, "kategori": "tas"},
	{"id": "pebble_s1", "isim": "Cakil Kare 1", "model": MODEL_KOK + "Pebble_Square_1.gltf", "olcek": 3.0, "kategori": "tas"},
	{"id": "pebble_s2", "isim": "Cakil Kare 2", "model": MODEL_KOK + "Pebble_Square_2.gltf", "olcek": 3.0, "kategori": "tas"},
	{"id": "pebble_s3", "isim": "Cakil Kare 3", "model": MODEL_KOK + "Pebble_Square_3.gltf", "olcek": 3.0, "kategori": "tas"},
	# --- Bitki / ot tutami ---
	{"id": "bush", "isim": "Cali", "model": MODEL_KOK + "Bush_Common.gltf", "olcek": 5.0, "kategori": "bitki"},
	{"id": "fern_1", "isim": "Egrelti", "model": MODEL_KOK + "Fern_1.gltf", "olcek": 5.0, "kategori": "bitki"},
	{"id": "grass_tall", "isim": "Ot Yuksek", "model": MODEL_KOK + "Grass_Common_Tall.gltf", "olcek": 4.0, "kategori": "bitki"},
	{"id": "grass_wispy", "isim": "Ot Ince", "model": MODEL_KOK + "Grass_Wispy_Tall.gltf", "olcek": 4.0, "kategori": "bitki"},
	{"id": "clover_1", "isim": "Yonca", "model": MODEL_KOK + "Clover_1.gltf", "olcek": 4.0, "kategori": "bitki"},
	{"id": "plant_1", "isim": "Bitki 1", "model": MODEL_KOK + "Plant_1.gltf", "olcek": 4.0, "kategori": "bitki"},
	# --- Cicek / mantar ---
	{"id": "flower_3", "isim": "Cicek 3", "model": MODEL_KOK + "Flower_3_Group.gltf", "olcek": 4.0, "kategori": "cicek"},
	{"id": "flower_4", "isim": "Cicek 4", "model": MODEL_KOK + "Flower_4_Group.gltf", "olcek": 4.0, "kategori": "cicek"},
	{"id": "mushroom", "isim": "Mantar", "model": MODEL_KOK + "Mushroom_Common.gltf", "olcek": 4.0, "kategori": "cicek"},
	# --- Yapi (SecondAge) — gltf birimi kucuk; agac (8) referansindan buyuk gorunmeli ---
	{"id": "town_center", "isim": "Sehir Merkezi", "model": MODEL_YAPI_KOK + "TownCenter_SecondAge_Level2.gltf", "olcek": 30.0, "kategori": "yapi"},
	{"id": "wall", "isim": "Sur", "model": MODEL_YAPI_KOK + "Wall_SecondAge.gltf", "olcek": 30.0, "kategori": "yapi"},
	{"id": "wall_door", "isim": "Surlu Kapi", "model": MODEL_YAPI_KOK + "WallTowers_Door_SecondAge.gltf", "olcek": 30.0, "kategori": "yapi"},
	{"id": "watch_tower", "isim": "Gozetleme Kulesi", "model": MODEL_YAPI_KOK + "WatchTower_SecondAge_Level2.gltf", "olcek": 30.0, "kategori": "yapi"},
	{"id": "tower_house", "isim": "Kule Ev", "model": MODEL_YAPI_KOK + "TowerHouse_SecondAge.gltf", "olcek": 27.0, "kategori": "yapi"},
	{"id": "barracks", "isim": "Kisla", "model": MODEL_YAPI_KOK + "Barracks_SecondAge_Level2.gltf", "olcek": 27.0, "kategori": "yapi"},
	{"id": "archery", "isim": "Okcu Talimhanesi", "model": MODEL_YAPI_KOK + "Archery_SecondAge_Level2.gltf", "olcek": 27.0, "kategori": "yapi"},
	{"id": "house_1", "isim": "Ev 1", "model": MODEL_YAPI_KOK + "Houses_SecondAge_1_Level2.gltf", "olcek": 24.0, "kategori": "yapi"},
	{"id": "house_2", "isim": "Ev 2", "model": MODEL_YAPI_KOK + "Houses_SecondAge_2_Level2.gltf", "olcek": 24.0, "kategori": "yapi"},
	{"id": "house_3", "isim": "Ev 3", "model": MODEL_YAPI_KOK + "Houses_SecondAge_3_Level2.gltf", "olcek": 24.0, "kategori": "yapi"},
	{"id": "farm_wheat", "isim": "Bugday Tarlasi", "model": MODEL_YAPI_KOK + "Farm_SecondAge_Level2_Wheat.gltf", "olcek": 27.0, "kategori": "yapi"},
	# --- Dag ---
	{"id": "mountain", "isim": "Dag", "model": MODEL_YAPI_KOK + "Mountain_Single.gltf", "olcek": 45.0, "kategori": "dag"},
	{"id": "mountain_large", "isim": "Buyuk Dag", "model": MODEL_YAPI_KOK + "MountainLarge_Single.gltf", "olcek": 60.0, "kategori": "dag"},
	# --- Detay ---
	{"id": "barrel", "isim": "Varil", "model": MODEL_YAPI_KOK + "Barrel.gltf", "olcek": 14.0, "kategori": "detay"},
	{"id": "crate", "isim": "Sandik", "model": MODEL_YAPI_KOK + "Crate.gltf", "olcek": 14.0, "kategori": "detay"},
	{"id": "crate_stack", "isim": "Sandik Yigini", "model": MODEL_YAPI_KOK + "Crate_Stack2.gltf", "olcek": 14.0, "kategori": "detay"},
	{"id": "logs", "isim": "Kutukler", "model": MODEL_YAPI_KOK + "Logs.gltf", "olcek": 14.0, "kategori": "detay"},
]

const KATEGORI_SIRASI: Array[String] = ["agac", "tas", "bitki", "cicek", "yapi", "dag", "detay"]
const KATEGORI_BASLIK := {
	"agac": "Agaclar",
	"tas": "Taslar",
	"bitki": "Bitkiler / Ot",
	"cicek": "Cicek / Mantar",
	"yapi": "Yapilar (SecondAge)",
	"dag": "Daglar",
	"detay": "Detay",
}
const KATEGORI_SEKME := {
	"agac": "Agac",
	"tas": "Tas",
	"bitki": "Bitki",
	"cicek": "Cicek",
	"yapi": "Yapi",
	"dag": "Dag",
	"detay": "Detay",
}
const ID_ALIASES := {"agac_common_1": "common_1"}
const LEGACY_OLCEK_BAZ := 200.0


static func id_coz(pid: String) -> String:
	return ID_ALIASES.get(pid, pid)


static func kategori_normalize(kat: String) -> String:
	match kat:
		"kaya":
			return "tas"
		"cali":
			return "bitki"
		_:
			return kat


static func olcek_normalize(kayitli: float, katalog_baz: float) -> float:
	if kayitli > katalog_baz * 4.0:
		return kayitli * (katalog_baz / LEGACY_OLCEK_BAZ)
	return kayitli


static func bul_id(pid: String) -> Dictionary:
	var coz := id_coz(pid)
	for entry in KATALOG:
		if str(entry.get("id", "")) == coz:
			return entry
	return {}


static func varsayilan_id() -> String:
	if KATALOG.is_empty():
		return ""
	return str(KATALOG[0].get("id", ""))


static func isim(pid: String) -> String:
	var entry := bul_id(pid)
	if entry.is_empty():
		return pid
	return str(entry.get("isim", pid))


static func kategori(pid: String) -> String:
	var entry := bul_id(pid)
	if entry.is_empty():
		return ""
	return kategori_normalize(str(entry.get("kategori", "")))


static func katalog_kategori(kat: String) -> Array[Dictionary]:
	var hedef := kategori_normalize(kat)
	var sonuc: Array[Dictionary] = []
	for entry in KATALOG:
		if kategori_normalize(str(entry.get("kategori", ""))) == hedef:
			sonuc.append(entry)
	return sonuc
