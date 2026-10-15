extends CharacterBody3D

static var next_crowd_vocal_ms := 0
static var next_crowd_attack_ms := 0
static var next_crowd_death_ms := 0
const BLOOD_TEXTURE := preload("res://assets/third_party/gore/blood_splat.png")

@export_group("node connections")
@export var character_root: Node3D
@export var collision_shape: CollisionShape3D
@export var animation_tree: AnimationTree
@export var damage_body:PhysicalBoneSimulator3D

@export_group("settings")
@export var move_speed: float = 1.0
@export var rotate_speed: float = 2.0
@export var max_health: float = 100.0
var current_health: float = 100.0
@export var show_health_bar:bool = true
@export var can_open_doors: bool = false

@export_group("attack")
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var vision_range: float = 10.0
@export var chase_time: float = 5.0
var is_chasing:bool = false

@export_group("sfx")
@export var spawn_sfx:AudioStreamPlayer3D
@export var idle_sfx:AudioStreamPlayer3D
@export var alert_sfx:AudioStreamPlayer3D
@export var hit_sfx:AudioStreamPlayer3D
@export var attack_sfx:AudioStreamPlayer3D
@export var death_sfx:AudioStreamPlayer3D

@export_group("vfx")
@export var spawn_vfx:Node3D
@export var attack_vfx:Node3D
@export var hit_vfx:Node3D
@export var death_vfx:Node3D





var state_machine:AnimationNodeStateMachinePlayback
var current_state
var previous_state

const GRAVITY = -20.0
var is_alive: bool = true
var player = null
var sector_map

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var debug_label: Label3D = $DebugLabel
@onready var chase_timer: Timer = $ChaseTimer
@onready var health_bar: MeshInstance3D = $HealthBar



func _ready() -> void:
	sector_map = get_tree().get_first_node_in_group("sector_map")
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	current_health = max_health
	health_bar.visible = show_health_bar
	
	# Make the health bar material unique for this instance
	if health_bar.get_surface_override_material_count() > 0:
		health_bar.set_surface_override_material(0, health_bar.get_active_material(0).duplicate())
	
	update_health_bar()
	
	if can_open_doors:
		add_to_group("door_access")
	debug_label.visible = Global.debug_mode
	state_machine = animation_tree.get("parameters/playback")
	animation_tree.set("parameters/walk/TimeScale/scale", clampf(move_speed / 3.5, 1.0, 2.0))
	for voice in [spawn_sfx, alert_sfx, attack_sfx, death_sfx]:
		if voice:
			voice.max_distance = 18.0
			voice.unit_size = 2.0
	if alert_sfx:
		alert_sfx.volume_db = -16.0
	if attack_sfx:
		attack_sfx.volume_db = -11.0
	if death_sfx:
		death_sfx.volume_db = -10.0
	if idle_sfx:
		idle_sfx.volume_db = -19.0
		idle_sfx.max_distance = 11.0
	if hit_sfx:
		hit_sfx.volume_db = -13.0
		hit_sfx.max_distance = 14.0
	
	var bone_array: Array = damage_body.get_children()
	for col_bone in bone_array:
		col_bone.update_damage.connect(get_damage)
		col_bone.collision_layer = 2
		col_bone.collision_mask = 2
	
	play_vfx(spawn_vfx)

var path_refresh := 0.0
var steering_target := Vector3.ZERO

func _physics_process(delta: float) -> void:
	path_refresh -= delta
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if player == null:
		player = Global.player
	
	if player == null or not is_alive:
		return

	# Determine current state
	if not is_alive:
		current_state = "dead"
	elif _player_in_attack_range():
		current_state = "attack"
	elif _chasing_player():
		current_state = "move"
	else:
		current_state = "idle"
	
	# Only update animation tree when state changes
	if current_state != previous_state:
		_change_state(current_state)
		previous_state = current_state
		
	match state_machine.get_current_node():
		"idle":
			velocity = Vector3.ZERO
		
		"walk":
			var next_nav_point: Vector3
			if sector_map:
				if path_refresh <= 0 or global_position.distance_to(steering_target) < 0.4:
					steering_target = sector_map.get_enemy_waypoint(global_position, player.global_position)
					path_refresh = 0.3
				next_nav_point = steering_target
			else:
				nav_agent.set_target_position(player.global_position)
				next_nav_point = nav_agent.get_next_path_position()
			var flat_direction := next_nav_point - global_position
			flat_direction.y = 0
			velocity.x = flat_direction.normalized().x * move_speed
			velocity.z = flat_direction.normalized().z * move_speed
			_look_at_target(next_nav_point, delta)
			
		
		
		"attack":
			velocity = Vector3.ZERO
			_look_at_target(player.global_position, delta)
			
		"dead":
			pass
	
	move_and_slide()

func _change_state(new_state: String) -> void:
	# Reset all conditions
	animation_tree.set("parameters/conditions/idle", false)
	animation_tree.set("parameters/conditions/move", false)
	animation_tree.set("parameters/conditions/attack", false)
	animation_tree.set("parameters/conditions/dead", false)
	
	# Set the new state condition and update debug label
	match new_state:
		"idle":
			animation_tree.set("parameters/conditions/idle", true)
			play_sfx(idle_sfx)
			debug_label.text = "IDLE"
		"move":
			animation_tree.set("parameters/conditions/move", true)
			play_sfx(alert_sfx)
			debug_label.text = "MOVE"
		"attack":
			play_sfx(attack_sfx)
			play_vfx(attack_vfx)
			animation_tree.set("parameters/conditions/attack", true)
			debug_label.text = "ATTACK"
		"dead":
			animation_tree.set("parameters/conditions/dead", true)
			debug_label.text = "DEAD"

func _look_at_target(target: Vector3, delta: float) -> void:
	var dir = target - global_position
	dir.y = 0
	dir = dir.normalized()

	var target_yaw = atan2(-dir.x, -dir.z)
	character_root.rotation.y = lerp_angle(
		character_root.rotation.y,
		target_yaw,
		rotate_speed * delta
	)


func _player_in_attack_range() -> bool:
	return global_position.distance_to(player.global_position) < attack_range



func _chasing_player() -> bool:
	if _player_in_vision_range():
		is_chasing = true
		chase_timer.start(chase_time)
	
	return is_chasing

func _player_in_vision_range() -> bool:
	return global_position.distance_to(player.global_position) < vision_range

func _on_chase_timer_timeout() -> void:
	is_chasing = false

func _deal_damage():
	if _player_in_attack_range():
		var direction = global_position.direction_to(player.global_position)
		player.get_damage(attack_damage,direction, true)


func get_damage(damage:float,_direction:Vector3) -> void:
	if not is_alive:
		return
	current_health -= damage
	update_health_bar()
	play_sfx(hit_sfx)
	play_vfx(hit_vfx)
	_spawn_blood_spray(_direction, current_health <= 0)
	
	if current_health <= 0:
		is_alive = false
		die()


func update_health_bar() -> void:
	var health_mat := health_bar.get_active_material(0)
	health_mat.uv1_offset.x = -((current_health/ max_health) - 1 ) / 2

func die():
	Global.enemy_killed.emit()
	
	play_vfx(death_vfx)
	play_sfx(death_sfx)
	
	character_root.visible = false
	collision_shape.disabled = true
	health_bar.visible = false
	debug_label.visible = false
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _spawn_blood_spray(direction: Vector3, lethal: bool) -> void:
	var world := get_parent()
	var spray_direction := direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	var count := 6 if lethal else 3
	for i in count:
		var drop := Sprite3D.new()
		drop.texture = BLOOD_TEXTURE
		drop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.pixel_size = 0.0028 if lethal else 0.0018
		drop.no_depth_test = false
		drop.shaded = false
		drop.modulate = Color(0.72, 0.04, 0.025, 0.95)
		world.add_child(drop)
		drop.global_position = global_position + Vector3.UP * randf_range(0.8, 1.5)
		var travel := spray_direction * randf_range(0.45, 1.2) + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.4), randf_range(-0.4, 0.4))
		var tween := drop.create_tween().set_parallel(true)
		tween.tween_property(drop, "global_position", drop.global_position + travel, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(drop.queue_free)
	if lethal:
		_spawn_blood_stain(world)

func _spawn_blood_stain(world: Node) -> void:
	var stains := get_tree().get_nodes_in_group("blood_stain")
	if stains.size() >= 40:
		stains[0].queue_free()
	var stain := Decal.new()
	stain.add_to_group("blood_stain")
	stain.texture_albedo = BLOOD_TEXTURE
	stain.size = Vector3(randf_range(1.5, 2.3), 0.8, randf_range(1.5, 2.3))
	stain.modulate = Color(0.58, 0.025, 0.015, 0.85)
	world.add_child(stain)
	stain.global_position = global_position + Vector3.UP * 0.2
	stain.rotation.y = randf_range(0.0, TAU)

func play_sfx(sfx:AudioStreamPlayer3D):
	if sfx:
		var now := Time.get_ticks_msec()
		if sfx == alert_sfx or sfx == idle_sfx or sfx == hit_sfx:
			if now < next_crowd_vocal_ms:
				return
			next_crowd_vocal_ms = now + 1100
		elif sfx == attack_sfx:
			if now < next_crowd_attack_ms:
				return
			next_crowd_attack_ms = now + 450
		elif sfx == death_sfx:
			if now < next_crowd_death_ms:
				return
			next_crowd_death_ms = now + 500
		sfx.play()

func play_vfx(vfx:Node3D):
	if vfx:
		if vfx.is_class("GPUParticles3D"):
			vfx.restart()
		elif vfx.has_method("activate"):
			vfx.activate()
