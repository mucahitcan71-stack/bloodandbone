extends RefCounted
class_name CommandSystem

var _root: Node2D = null
var secili_komut: String = "hareket"
var secili_birim = null
var menu_hedef_birim = null

func configure(root_node: Node2D) -> void:
	_root = root_node

func reset_for_preparation() -> void:
	secili_komut = "hareket"
	secili_birim = null
	menu_hedef_birim = null

func reset_for_battle_start() -> void:
	secili_komut = "hareket"
	secili_birim = null
	menu_hedef_birim = null

func get_selected_command() -> String:
	return secili_komut

func get_selected_unit():
	return secili_birim

func get_menu_target_unit():
	return menu_hedef_birim

func has_selection() -> bool:
	return secili_birim != null

func _sync_from_main(komut: String, birim, menu_hedef) -> void:
	secili_komut = komut
	secili_birim = birim
	menu_hedef_birim = menu_hedef
