extends Node

var boss
var player
var cooldown := 2.3
var volley := 0

func _ready() -> void:
	boss = get_parent()
	player = get_node("/root/Global").player

func _physics_process(delta: float) -> void:
	if not boss.is_alive or not is_instance_valid(player) or not player.is_alive:
		return
	cooldown -= delta
	if cooldown > 0.0:
		return
	volley += 1
	var origin: Vector3 = player.global_position
	var lateral := Vector3(player.velocity.z, 0.0, -player.velocity.x).normalized()
	var lead: Vector3 = player.velocity * 0.45
	if volley % 3 == 0:
		for offset in [-4.0, 0.0, 4.0]:
			_mark(origin + lead + lateral * offset, 2.2, 22.0, 1.05)
		cooldown = 3.0
	else:
		_mark(origin + lead, 2.8, 25.0, 0.85)
		cooldown = 2.1
	if boss.global_position.distance_to(player.global_position) < 5.5:
		_mark(boss.global_position, 4.1, 18.0, 0.65)

func _mark(location: Vector3, radius: float, damage: float, delay: float) -> void:
	var marker := Node3D.new()
	marker.set_script(preload("res://common/enemy/strike_marker.gd"))
	marker.position = Vector3(location.x, 0.06, location.z)
	marker.radius = radius
	marker.damage = damage
	marker.warning_time = delay
	marker.color = Color(1.0, 0.12, 0.045) if boss.name == "InfectedCaptain" else Color(0.2, 0.6, 1.0)
	boss.get_parent().add_child(marker)
