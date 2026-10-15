extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.director.stop()
	game.player.global_position = game.sector.room_center(2, 3) + Vector3(0, 0.2, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game.player.camera_pivot.rotation = Vector3.ZERO
	game.player.camera_holder.rotation = Vector3.ZERO
	for i in 10:
		await process_frame
	game.director._spawn_at(game.player.global_position + Vector3(0, 0.2, -4.8), true)
	game.horror.fear = 100.0
	game.horror._update_debuff(0.0)
	for i in 3:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://artifacts/fear_meter.png")
	for i in 12:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var error := root.get_viewport().get_texture().get_image().save_png("res://artifacts/fear_debuff.png")
	print("CAPTURE debuff=", error, " enemies=", game.director.living_count())
	game.queue_free()
	await process_frame
	quit()
