extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main_ship.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	print("PROBE map_rooms=", game.get_node("SectorMap").get_child_count())
	print("PROBE phase=", game.phase, " paused=", paused)
	game._start_game()
	game.get_node("ThreatDirector").stop()
	for i in 8:
		await physics_frame
	var player = game.get_node("Player")
	print("PROBE start=", player.global_position, " floor=", player.is_on_floor())
	Input.action_press("forward")
	for i in 240:
		await physics_frame
	Input.action_release("forward")
	print("PROBE walk_forward=", player.global_position, " floor=", player.is_on_floor())
	player.global_position = Vector3(100, 0.2, 0)
	player.velocity = Vector3.ZERO
	for i in 6:
		await physics_frame
	var director = game.get_node("ThreatDirector")
	director.rng.seed = 123
	var candidate: Vector3 = director._pick_hidden_spawn()
	print("PROBE hidden_candidate=", candidate, " distance=", candidate.distance_to(player.global_position))
	if candidate != Vector3.INF:
		director._spawn_at(candidate)
		for i in 1020:
			await physics_frame
			if i in [180, 360, 540, 720]:
				var e = game.get_node("Enemies").get_child(0)
				print("PROBE zombie_step=", i, " pos=", e.global_position, " waypoint=", game.get_node("SectorMap").get_enemy_waypoint(e.global_position, player.global_position), " wall=", e.is_on_wall())
		var enemy = game.get_node("Enemies").get_child(0)
		print("PROBE zombie=", enemy.global_position, " chase=", enemy.is_chasing, " player_health=", player.current_health)
		enemy.queue_free()
	game._pause_game()
	print("PROBE pause=", game.phase, " tree=", paused)
	game._resume_game()
	print("PROBE resume=", game.phase, " tree=", paused)
	var supply_cell := Vector2i(1, 1)
	player.global_position = game.get_node("SectorMap").room_center(supply_cell.x, supply_cell.y) + Vector3(4, 0.2, 4)
	player.current_health = 50
	for j in 2:
		await physics_frame
	game._on_activate()
	print("PROBE supply=", game.used_supplies.has(supply_cell), " health=", player.current_health)
	for i in 4:
		var target: Vector3 = game._target_position()
		player.global_position = target + Vector3(0, 0.2, 1)
		for j in 2:
			await physics_frame
		game._on_activate()
		print("PROBE objective=", game.objective_index, " phase=", game.phase)
	paused = false
	quit()
