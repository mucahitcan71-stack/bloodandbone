extends SceneTree

const IsoProj = preload("res://scripts/iso_projection.gd")
const TOLERANCE := 0.001

const ROUND_TRIP_VALUES: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(1, 1),
	Vector2(5, 3),
	Vector2(-2, 4),
	Vector2(10, 10),
	Vector2(7, -5),
]


func _init() -> void:
	var all_ok := true

	print("=== IsoProjection A3: ROUND-TRIP ===")
	for original in ROUND_TRIP_VALUES:
		var iso: Vector2 = IsoProj.logical_to_iso(original)
		var geri: Vector2 = IsoProj.iso_to_logical(iso)
		var fark := (geri - original).length()
		var gecti := fark < TOLERANCE
		all_ok = all_ok and gecti
		print(
			"logical:", original,
			" -> iso:", iso,
			" -> geri:", geri,
			" | fark:", fark,
			" | ", "GECTI" if gecti else "KALDI"
		)

	print("")
	print("=== IsoProjection A3: BILINEN DEGERLER ===")
	all_ok = _check_known(Vector2(0, 0), Vector2(0, 0), all_ok)
	all_ok = _check_known(Vector2(1, 0), Vector2(64, 32), all_ok)
	all_ok = _check_known(Vector2(0, 1), Vector2(-64, 32), all_ok)
	all_ok = _check_known(Vector2(1, 1), Vector2(0, 64), all_ok)

	print("")
	print("SONUC: ", "TUM TESTLER GECTI" if all_ok else "BASARISIZ")
	quit(0 if all_ok else 1)


func _check_known(logical: Vector2, expected: Vector2, all_ok: bool) -> bool:
	var actual: Vector2 = IsoProj.logical_to_iso(logical)
	var fark := (actual - expected).length()
	var gecti := fark < TOLERANCE
	print(
		"logical ", logical,
		" bekleniyor ", expected,
		", cikan: ", actual,
		" | fark: ", fark,
		" | ", "GECTI" if gecti else "KALDI"
	)
	return all_ok and gecti
