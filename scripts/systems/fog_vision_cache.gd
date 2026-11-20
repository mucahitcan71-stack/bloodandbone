extends RefCounted
class_name FogVisionCache

var _entries: Dictionary = {}

func clear() -> void:
    _entries.clear()

func get_cells(unit_id: int, position: Vector2, radius: float) -> Dictionary:
    if not _entries.has(unit_id):
        return {}
    var entry: Dictionary = _entries[unit_id]
    if entry["position"] != position or entry["radius"] != radius:
        return {}
    return entry["cells"]

func has_valid(unit_id: int, position: Vector2, radius: float) -> bool:
    if not _entries.has(unit_id):
        return false
    var entry: Dictionary = _entries[unit_id]
    return entry["position"] == position and entry["radius"] == radius

func store(unit_id: int, position: Vector2, radius: float, cells: Dictionary) -> void:
    _entries[unit_id] = {
        "position": position,
        "radius": radius,
        "cells": cells.duplicate()
    }

func prune(active_ids: Dictionary) -> void:
    for unit_id in _entries.keys():
        if not active_ids.has(unit_id):
            _entries.erase(unit_id)

func entry_count() -> int:
    return _entries.size()
