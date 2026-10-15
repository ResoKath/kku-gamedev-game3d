extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	for i in 8:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	_capture("menu")
	game._show_menu("settings")
	for i in 2:
		await process_frame
	_capture("settings")
	game._show_menu("controls")
	for i in 2:
		await process_frame
	_capture("controls")
	game._start_game()
	for i in 12:
		await process_frame
	_capture("hud")
	game._pause_game()
	for i in 2:
		await process_frame
	_capture("pause")
	game._resume_game()
	game._show_menu("dead")
	for i in 2:
		await process_frame
	_capture("death")
	paused = false
	quit()

func _capture(name: String) -> void:
	var path := "res://artifacts/ui_%s.png" % name
	print("CAPTURE ", name, " ", root.get_viewport().get_texture().get_image().save_png(path))
