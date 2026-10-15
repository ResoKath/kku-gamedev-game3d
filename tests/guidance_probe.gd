extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.director.stop()
	assert(game.story_label.text.contains("WASD"))
	game.player.global_position += Vector3(5, 0, 0)
	game.story_remaining = 0
	game._update_guidance(false)
	assert(game.story_label.text.contains("crew terminal"))
	game.story_remaining = 0
	game._update_guidance(true)
	assert(game.story_label.text.contains("Left click"))
	game.player.global_position = game._target_position() + Vector3(0, 0.2, 1)
	game._physics_process(0.01)
	assert(game.prompt_label.text.contains("Read log"))
	assert(not game.story_label.visible)
	game._on_activate()
	assert(game.objective_index == 1)
	assert(game.story_label.text.contains("reactor lockdown"))
	game._pause_game()
	game.controls_return = "pause"
	game._show_menu("controls")
	var escape := InputEventAction.new()
	escape.action = "exit"
	escape.pressed = true
	game._unhandled_input(escape)
	assert(game.phase == "paused" and paused)
	game._resume_game()
	assert(game.phase == "playing" and not paused)
	print("PASS: onboarding, contextual prompt priority, next objective, help return")
	game.queue_free()
	await process_frame
	quit()
