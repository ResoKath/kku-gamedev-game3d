extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.director.stop()
	game.horror.enabled = false
	game.player.global_position = game.sector.room_center(2, 3) + Vector3(0, 0.2, 0)
	for i in 4:
		await physics_frame
	var h = game.horror
	h.enabled = true
	h.fear = 90.0
	h._update_fear(1.0)
	assert(h.fear == 82.0, "Fear should decay away from living enemies")
	game.director._spawn_at(game.player.global_position + Vector3(0, 0.0, -4.8), true)
	var enemy = game.get_node("Enemies").get_child(0)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await physics_frame
	h.fear = 0.0
	h._update_fear(1.0)
	assert(h.fear > 10.0 and h.fear < 25.0)
	h._update_debuff(0.0)
	assert(not game.player.fear_debuff)
	h.fear = 99.0
	h._update_debuff(0.0)
	assert(not game.player.fear_debuff)
	h.fear = 100.0
	h._update_debuff(0.0)
	assert(game.player.fear_debuff and h.debuff_remaining == 8.0)
	Input.action_press("sprint")
	await physics_frame
	assert(is_equal_approx(game.player.speed, game.player.walk_speed), "Panic must force walking even while sprint is held")
	assert(not game.player.camera_pivot.is_sprinting, "Panic must cancel sprint FOV")
	h._process(0.5)
	assert(h.panic_shade > 0.0, "Panic should darken the screen")
	h._update_debuff(8.0)
	assert(not game.player.fear_debuff and h.debuff_remaining == 0.0)
	await physics_frame
	assert(is_equal_approx(game.player.speed, game.player.sprint_speed), "Sprint should recover after panic")
	Input.action_release("sprint")
	h._update_debuff(0.0)
	assert(not game.player.fear_debuff, "Debuff must not retrigger while fear stays full")
	h.fear = 60.0
	h._update_debuff(0.0)
	h.fear = 100.0
	h._update_debuff(0.0)
	assert(game.player.fear_debuff, "Debuff should rearm after recovery")
	h.stop()
	assert(not game.player.fear_debuff)
	h.enabled = true
	h.fear = 80.0
	enemy.is_alive = false
	h._update_fear(1.0)
	assert(h.fear == 72.0)
	var before: float = h.fear
	game._pause_game()
	h._process(10.0)
	assert(h.fear == before)
	game._resume_game()
	h._update_soundscape(1.0)
	assert(h.heartbeat.pitch_scale > 1.0)
	assert(game.get_node("HUD/Control").fear_bar.value >= 0)
	print("PASS: proximity fear, decay, 100% debuff, recovery, pause, audio response")
	game.queue_free()
	await process_frame
	quit()
