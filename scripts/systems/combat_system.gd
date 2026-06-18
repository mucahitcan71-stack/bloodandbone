extends RefCounted
class_name CombatSystem

static func change_moral(current: float, amount: float) -> float:
	return clamp(current + amount, 0.0, 130.0)

static func moral_multiplier(moral: float) -> float:
	return clamp(0.75 + (moral / 100.0) * 0.5, 0.7, 1.35)

static func formation_multiplier(formations: Dictionary, side_formations: Dictionary, side: String, stat: String) -> float:
	var formation_name = side_formations.get(side, "dengeli")
	var formation = formations.get(formation_name, formations.get("dengeli", {}))
	return float(formation.get(stat, 1.0))

static func effective_stats(
	unit: Dictionary,
	side_formations: Dictionary,
	formations: Dictionary,
	side_morale: Dictionary,
	side_modifiers: Dictionary,
	weather_effect: Dictionary,
	ult_active: Dictionary,
	general: Dictionary,
	promotion_level: int
) -> Dictionary:
	var side = unit["taraf"]
	var attack = float(unit["guc"])
	var defense = float(unit["savunma"])
	var speed = float(unit["hiz"])
	var range_px = float(unit["menzil"])

	attack *= formation_multiplier(formations, side_formations, side, "guc")
	defense *= formation_multiplier(formations, side_formations, side, "savunma")
	speed *= formation_multiplier(formations, side_formations, side, "hiz")

	var morale_mult = moral_multiplier(float(side_morale.get(side, 100.0)))
	attack *= morale_mult
	defense *= morale_mult

	var side_mults = side_modifiers.get(side, {"guc": 1.0, "savunma": 1.0, "hiz": 1.0, "menzil": 1.0})
	attack *= float(side_mults.get("guc", 1.0))
	defense *= float(side_mults.get("savunma", 1.0))
	speed *= float(side_mults.get("hiz", 1.0))
	range_px *= float(side_mults.get("menzil", 1.0))

	attack *= float(weather_effect.get("guc", 1.0))
	speed *= float(weather_effect.get("hiz", 1.0))
	range_px *= float(weather_effect.get("menzil", 1.0))

	var promotion_mult = 1.0 + float(promotion_level) * 0.08
	attack *= promotion_mult
	defense *= promotion_mult

	if float(ult_active.get(side, 0.0)) > 0.0:
		attack *= 1.25
		speed *= 1.08

	if not general.is_empty():
		if unit["konum"].distance_to(general["konum"]) <= float(general.get("aura_menzil", 0.0)):
			attack *= float(general.get("aura_guc", 1.0))
			defense *= float(general.get("aura_savunma", 1.0))

	return {"guc": attack, "savunma": defense, "hiz": speed, "menzil": range_px}
