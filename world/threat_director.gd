extends Node3D

signal threat_changed(active_count: int)

const UNDEAD: PackedScene = preload("res://enemies/undead.tscn")
const ROBOT_ENEMY = preload("res://common/enemy/robot_enemy.gd")
const MAX_ATTEMPTS := 36

@export var enabled := false
@export var stage := 0

var time_until_spawn := 9.0
var remaining_to_spawn := 0
var stage_cell := Vector2i(3, 3)
var boss_mode := false
var boss_cells: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()
var map
var player
var camera: Camera3D
var enemy_container: Node3D

func _ready() -> void:
	rng.randomize()
	map = get_parent().get_node("SectorMap")
	player = get_parent().get_node("Player")
	camera = player.get_node("CameraPivot/CameraHolder/MainCamera")
	enemy_container = get_parent().get_node("Enemies")

func begin_stage(stage_number: int, cell: Vector2i, enemy_count: int) -> void:
	boss_mode = false
	stage = stage_number
	stage_cell = cell
	remaining_to_spawn = enemy_count
	enabled = true
	time_until_spawn = 0.5

func begin_boss_stage(cells: Array) -> void:
	boss_mode = true
	boss_cells.clear()
	for cell in cells:
		boss_cells.append(cell)
	stage = 9
	remaining_to_spawn = 3
	enabled = true
	time_until_spawn = 0.7

func stop() -> void:
	enabled = false
	remaining_to_spawn = 0

func remaining_count() -> int:
	return remaining_to_spawn + living_count()

func living_count() -> int:
	var count := 0
	for enemy in enemy_container.get_children():
		if enemy.name != "InfectedCaptain" and enemy.get("is_alive") == true:
			count += 1
	return count

func _physics_process(delta: float) -> void:
	if not enabled or not player.is_alive:
		return
	time_until_spawn -= delta
	if time_until_spawn > 0:
		return
	if boss_mode:
		var captain: Node = enemy_container.get_node_or_null("InfectedCaptain")
		if captain == null or captain.get("is_alive") != true:
			stop()
			return
		var guard_limit := 6
		if living_count() < guard_limit:
			var guard_position := _pick_hidden_spawn()
			if guard_position != Vector3.INF:
				_spawn_at(guard_position)
				remaining_to_spawn = maxi(0, remaining_to_spawn - 1)
		time_until_spawn = 0.8 if remaining_to_spawn > 0 else 5.5
		threat_changed.emit(living_count())
		return
	time_until_spawn = maxf(0.55, 1.35 - stage * 0.06)
	if remaining_to_spawn <= 0:
		return
	var alive := living_count()
	if alive >= mini(4 + floori(stage / 2.0), 9):
		return
	var candidate := _pick_hidden_spawn()
	if candidate != Vector3.INF:
		_spawn_at(candidate)
		remaining_to_spawn -= 1
	threat_changed.emit(living_count())

func _pick_hidden_spawn() -> Vector3:
	for attempt in MAX_ATTEMPTS:
		var cell: Vector2i = boss_cells[rng.randi_range(0, boss_cells.size() - 1)] if boss_mode else stage_cell
		var offset := 7.0 if boss_mode else 6.0
		var candidate: Vector3 = map.room_center(cell.x, cell.y) + Vector3(rng.randf_range(-offset, offset), 0.2, rng.randf_range(-offset, offset))
		var distance := candidate.distance_to(player.global_position)
		if distance < 4:
			continue
		if not is_spawn_clear(candidate):
			continue
		return candidate
	return Vector3.INF

func is_spawn_clear(candidate: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = candidate + Vector3(0, 1.0, 0)
	query.collision_mask = 1
	if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	for enemy in enemy_container.get_children():
		if enemy.get("is_alive") == true and enemy.global_position.distance_to(candidate) < 1.5:
			return false
	return true

func spawn_ambush() -> bool:
	return false

func _spawn_at(candidate: Vector3, ambush: bool = false) -> void:
	var roll := rng.randf()
	if boss_mode or (stage >= 2 and roll < minf(0.78, 0.22 + stage * 0.075)):
		var robot = CharacterBody3D.new()
		robot.set_script(ROBOT_ENEMY)
		if boss_mode:
			robot.kind = ROBOT_ENEMY.Kind.DRONE if roll < 0.5 else ROBOT_ENEMY.Kind.TRILOBITE
		else:
			robot.kind = ROBOT_ENEMY.Kind.DRONE if roll < 0.3 else (ROBOT_ENEMY.Kind.QUADSHELL if roll < 0.62 else ROBOT_ENEMY.Kind.TRILOBITE)
		robot.position = candidate
		robot.max_health = 65.0 + stage * 17.0 if robot.kind == ROBOT_ENEMY.Kind.DRONE else 110.0 + stage * 25.0
		robot.move_speed = 4.2 + stage * 0.12 if robot.kind == ROBOT_ENEMY.Kind.DRONE else (5.8 + stage * 0.16 if robot.kind == ROBOT_ENEMY.Kind.TRILOBITE else 3.5 + stage * 0.1)
		robot.attack_damage = 10.0 + stage * 1.7
		enemy_container.add_child(robot)
		return
	var enemy = UNDEAD.instantiate()
	enemy.position = candidate
	enemy.move_speed = player.walk_speed + (player.sprint_speed - player.walk_speed) * 0.3
	enemy.max_health = 90.0 + stage * 15.0
	enemy.attack_damage = 8.0 + stage * 1.5
	if boss_mode:
		enemy.max_health = 250.0
		enemy.attack_damage = 18.0
		enemy.move_speed = player.walk_speed * 1.2
	enemy.vision_range = 75.0
	enemy.chase_time = 20.0
	enemy.show_health_bar = false
	enemy_container.add_child(enemy)
	for sound in enemy.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	enemy.is_chasing = true
	if ambush:
		# Ambushers are already standing when the lamp returns, not slowly getting up.
		enemy.state_machine.start("walk")
		enemy._change_state("move")
		enemy.previous_state = "move"
		enemy.animation_tree.advance(0.05)
		var direction: Vector3 = player.global_position - candidate
		enemy.character_root.rotation.y = atan2(-direction.x, -direction.z)
