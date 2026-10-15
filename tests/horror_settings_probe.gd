extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.horror.enabled = false
	game.director.stop()
	for i in 4:
		await physics_frame
	assert(game.sector.navigation_ready)
	# Actual imported supports must stop both rays and a moving player capsule.
	var center: Vector3 = game.sector.room_center(2, 3)
	var support_hit := false
	for z in range(-7, 8):
		var start := center + Vector3(-8, 1.1, z)
		var finish := center + Vector3(8, 1.1, z)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 1, [game.player.get_rid()]))
		if not hit.is_empty() and absf(hit.position.x - center.x) < 7.5:
			var transform: Transform3D = game.player.global_transform
			transform.origin = start - Vector3(0, 1.1, 0)
			assert(game.player.test_move(transform, Vector3(16, 0, 0)))
			support_hit = true
			break
	assert(support_hit, "No solid internal support detected")
	# Spawns are valid, more numerous, and bounded.
	game.director.rng.seed = 17
	game.director.enabled = true
	for i in 12:
		game.director.time_until_spawn = 0
		game.director._physics_process(0.1)
	assert(game.director.living_count() > 6)
	for enemy in game.get_node("Enemies").get_children():
		assert(enemy.move_speed > game.player.walk_speed and enemy.move_speed < game.player.sprint_speed, "Zombie chase speed must sit between walk and sprint")
		assert(enemy.animation_tree.get("parameters/walk/TimeScale/scale") > 1.0, "Zombie walk animation must accelerate with chase speed")
	assert(game.director.living_count() <= 16)
	print("PASS population: ", game.director.living_count())
	game.director.stop()
	for enemy in game.get_node("Enemies").get_children():
		enemy.queue_free()
	await process_frame
	game.player.global_position = center + Vector3(0, 0.2, 0)
	game.player.camera_pivot.rotation = Vector3.ZERO
	game.player.camera_holder.rotation = Vector3.ZERO
	game.horror.enabled = true
	game.director._spawn_at(center + Vector3(0, 0.2, -4.8), true)
	game.horror.fear = 100.0
	game.horror._update_debuff(0.0)
	assert(game.player.fear_debuff)
	game.horror._update_debuff(8.1)
	assert(not game.player.fear_debuff)
	# Persistence uses an isolated file, never the user's saved preferences.
	var config = load("res://world/game_settings.gd").new()
	config.values.master = 0.35
	config.values.sensitivity = 0.0045
	assert(config.save_settings("user://settings_probe.cfg") == OK)
	var restored = load("res://world/game_settings.gd").new()
	restored.load_settings("user://settings_probe.cfg")
	assert(restored.values.master == 0.35 and restored.values.sensitivity == 0.0045)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings_probe.cfg"))
	game._pause_game()
	game.settings_return = "pause"
	game._show_menu("settings")
	assert(game.phase == "settings" and paused)
	var escape := InputEventAction.new()
	escape.action = "exit"
	escape.pressed = true
	game._unhandled_input(escape)
	assert(game.phase == "paused" and paused)
	game._resume_game()
	assert(game.get_node("HUD/Control").visible)
	print("PASS: support collision, navigation grid, fear debuff, settings persistence, pause return")
	game.queue_free()
	await process_frame
	quit()
