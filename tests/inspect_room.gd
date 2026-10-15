extends SceneTree
func _initialize() -> void:
	for path in ["res://assets/kenney/modular-space-kit/Models/GLB format/room-large.glb", "res://assets/kenney/modular-space-kit/Models/GLB format/room-large-variation.glb"]:
		var room = load(path).instantiate()
		root.add_child(room)
		print(path)
		for mesh in room.find_children("*", "MeshInstance3D", true, false):
			print(mesh.name, " ", mesh.transform, " bounds=", mesh.get_aabb())
		room.queue_free()
	quit()
