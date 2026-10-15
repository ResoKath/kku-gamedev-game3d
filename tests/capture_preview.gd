extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main_ship.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	for i in 8:
		await process_frame
	game._start_game()
	for i in 45:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var path := "res://artifacts/gameplay_preview.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	print("CAPTURE ", image.save_png(path), " ", ProjectSettings.globalize_path(path))
	quit()
