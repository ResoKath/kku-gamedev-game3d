extends Node3D

const WALK_THROUGH_DEBRIS := [
	"rubble_", "steelpiece", "cinderblocks", "brokenchunks", "brokenslabs"
]

func _ready() -> void:
	# The downloaded demo includes its own exploration camera and environment.
	# This project keeps its existing FPS player and dark world environment.
	var demo_camera := get_node_or_null("Hangar/FreeLookCamera")
	if demo_camera:
		demo_camera.queue_free()
	var demo_environment := get_node_or_null("Hangar/WorldEnvironment")
	if demo_environment:
		demo_environment.queue_free()
	# These low scattered props are visual detail. Their original mesh collision
	# trapped the FPS controller, even though the pieces are ankle height.
	for body in find_children("*", "StaticBody3D", true, false):
		var parent_name := body.get_parent().name.to_lower()
		for debris_name in WALK_THROUGH_DEBRIS:
			if parent_name.begins_with(debris_name):
				body.collision_layer = 0
				body.collision_mask = 0
				break
