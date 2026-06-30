extends Node2D

const IsoProjection = preload("res://scripts/iso_projection.gd")

const HARITA_SINIR := {"min_x": 0.0, "max_x": 5000.0, "min_y": 0.0, "max_y": 3000.0}
const KAMERA_HIZ := 900.0
const ZOOM_ADIM := 0.1
const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.5

var noktalar: Array[Vector2] = []
var _kamera: Camera2D
var _orta_tik_surukleme := false


func _ready() -> void:
	_kamera = $Camera2D
	_kamera.position = _harita_merkez_logical()
	_kamera.zoom = Vector2.ONE
	queue_redraw()


func _process(delta: float) -> void:
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
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var mouse_dunya := get_global_mouse_position()
			var logical := IsoProjection.iso_to_logical(mouse_dunya - merkez_logical_iso_offseti(HARITA_SINIR))
			noktalar.append(logical)
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_orta_tik_surukleme = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x - ZOOM_ADIM)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_ayarla(_kamera.zoom.x + ZOOM_ADIM)
	elif event is InputEventMouseMotion and _orta_tik_surukleme:
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
	for logical in noktalar:
		var iso := IsoProjection.logical_to_iso(logical) + off
		draw_circle(iso, 6.0, Color(1.0, 0.2, 0.2, 0.95))
		var etiket := "(%d, %d)" % [int(round(logical.x)), int(round(logical.y))]
		draw_string(font, iso + Vector2(10, -8), etiket, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1, 1, 1, 0.95))


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
