extends SubViewport

@onready var camera: Camera3D = $Camera3D
@onready var main_camera: Camera3D = %MainCamera

func _ready() -> void:
	if not camera.environment:
		var env := Environment.new()
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.9, 0.95, 1.0, 1.0)
		env.ambient_light_energy = 1.0
		camera.environment = env

func _process(_delta: float) -> void:
	camera.global_transform = main_camera.global_transform
