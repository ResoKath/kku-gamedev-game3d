extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.director.stop()
	for stage in 4:
		game.player.global_position = game._target_position() + Vector3(0, 0.2, 1)
		game._on_activate()
		if stage == 0:
			assert(game.objective_index == 1)
			continue
		assert(game.objective_index == stage, "Walking alone advanced a locked objective")
		assert(game._kills_remaining() == game.KILLS_REQUIRED[stage])
		for i in game.KILLS_REQUIRED[stage]:
			root.get_node("Global").enemy_killed.emit()
		assert(game._kills_remaining() == 0)
		game._on_activate()
		if stage < 3:
			assert(game.objective_index == stage + 1)
		else:
			assert(game.phase == "won")
	print("PASS: each combat lockdown blocks pacifist completion and unlocks after kills")
	paused = false
	game.queue_free()
	await process_frame
	quit()
