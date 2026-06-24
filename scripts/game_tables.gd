extends RefCounted

const Constants = preload("res://scripts/constants.gd")

const ZORLUK_AYARLARI = {
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

const AI_KARAR_ARALIGI = {"kolay": 1.9, "orta": 1.25, "zor": 0.8}

const FORMASYONLAR = {
	"hucum": {"guc": 1.2, "savunma": 0.85, "hiz": 1.05},
	"savunma": {"guc": 0.9, "savunma": 1.2, "hiz": 0.9},
	"dengeli": {"guc": 1.0, "savunma": 1.0, "hiz": 1.0}
}

const HAVA_DURUMU_EFEKTLERI = {
	"Acik": {"hiz": 1.0, "menzil": 1.0, "guc": 1.0},
	"Yagmur": {"hiz": 0.9, "menzil": 0.9, "guc": 0.95},
	"Sis": {"hiz": 0.95, "menzil": Constants.SIS_MENZIL_CARPAN, "guc": 1.0},
	"Ruzgar": {"hiz": 1.05, "menzil": 1.08, "guc": 1.0},
}

const KART_HAVUZU = [
	{"id": "disiplin", "isim": "Demir Disiplin", "aciklama": "+10 moral", "moral": 10.0},
	{"id": "ikmal", "isim": "Hizli Ikmal", "aciklama": "+12 altin", "altin": 12},
	{"id": "talim", "isim": "Saha Talimi", "aciklama": "+8% guc", "guc": Constants.TALIM_GUC_CARPAN},
	{"id": "savunma_hatti", "isim": "Savunma Hatti", "aciklama": "+8% savunma", "savunma": Constants.SAVUNMA_HATTI_CARPAN},
	{"id": "hucum_plani", "isim": "Hucum Plani", "aciklama": "Formasyon: Hucum", "formasyon": "hucum"},
]

const EKIPMANLAR = {
	"celik": {"isim": "Keskin Celik", "guc": 1.12, "savunma": 1.0, "menzil": 1.0},
	"zirh": {"isim": "Zirh Kaplama", "guc": 1.0, "savunma": 1.12, "menzil": 1.0},
	"durbun": {"isim": "Saha Durbunu", "guc": 1.0, "savunma": 1.0, "menzil": 1.15}
}
