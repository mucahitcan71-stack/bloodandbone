extends SceneTree

const Cache = preload("res://scripts/systems/fog_vision_cache.gd")

func _init() -> void:
    var cache = Cache.new()
    var passed := 0
    var failed := 0
    var pos := Vector2(500.0, 800.0)
    var cells := {Vector2i(4, 6): true, Vector2i(5, 6): true}

    if not cache.has_valid(1, pos, 110.0):
        passed += 1
        print("PASS: Empty cache is invalid")
    else:
        failed += 1
        print("FAIL: Empty cache")

    cache.store(1, pos, 110.0, cells)
    if cache.has_valid(1, pos, 110.0) and cache.get_cells(1, pos, 110.0) == cells:
        passed += 1
        print("PASS: Stored visibility restored")
    else:
        failed += 1
        print("FAIL: Stored visibility")

    if not cache.has_valid(1, pos + Vector2(1, 0), 110.0):
        passed += 1
        print("PASS: Movement invalidates cache")
    else:
        failed += 1
        print("FAIL: Movement")

    if not cache.has_valid(1, pos, 120.0):
        passed += 1
        print("PASS: Radius change invalidates cache")
    else:
        failed += 1
        print("FAIL: Radius change")

    cache.store(2, pos, 110.0, cells)
    cache.prune({2: true})
    if cache.entry_count() == 1 and not cache.has_valid(1, pos, 110.0):
        passed += 1
        print("PASS: Removed unit pruned")
    else:
        failed += 1
        print("FAIL: Pruning")

    cache.clear()
    if cache.entry_count() == 0:
        passed += 1
        print("PASS: Map reset clears cache")
    else:
        failed += 1
        print("FAIL: Reset")

    print("FOW-013 CACHE TEST: %d passed, %d failed" % [passed, failed])
    quit(0 if failed == 0 else 1)
