extends RefCounted
class_name MetaSystem

static func draw_cards(pool: Array, count: int = 3) -> Array:
	var copy = pool.duplicate(true)
	copy.shuffle()
	var out: Array = []
	for i in range(min(count, copy.size())):
		out.append(copy[i])
	return out

static func update_promotion_state(state: Dictionary, unit_name: String) -> Dictionary:
	if unit_name == "General":
		return state
	if not state.has(unit_name):
		state[unit_name] = {"kullanim": 0, "seviye": 0}
	state[unit_name]["kullanim"] += 1
	if state[unit_name]["kullanim"] >= 3 and state[unit_name]["seviye"] < 3:
		state[unit_name]["kullanim"] = 0
		state[unit_name]["seviye"] += 1
	return state

static func get_promotion_level(state: Dictionary, unit_name: String) -> int:
	if not state.has(unit_name):
		return 0
	return int(state[unit_name].get("seviye", 0))

static func choose_ai_army_type(unit_types: Array, remain_capacity: int, difficulty: String) -> int:
	var candidates: Array = []
	for i in range(unit_types.size()):
		if int(unit_types[i]["kontenjan"]) <= remain_capacity:
			candidates.append(i)
	if candidates.is_empty():
		return -1

	var base_weights = {
		"kolay": [0.22, 0.28, 0.5],
		"orta": [0.18, 0.24, 0.58],
		"zor": [0.1, 0.15, 0.75],
	}
	var w: Array = base_weights.get(difficulty, base_weights["orta"]).duplicate()
	while w.size() < unit_types.size():
		w.append(w[w.size() - 1])
	var total = 0.0
	for i in candidates:
		total += float(w[i])

	var roll = randf() * total
	var acc = 0.0
	for i in candidates:
		acc += float(w[i])
		if roll <= acc:
			return i
	return int(candidates[-1])

static func campaign_next_index(current: int, won: bool, region_count: int) -> int:
	if won:
		return min(current + 1, region_count - 1)
	return max(current - 1, 0)
