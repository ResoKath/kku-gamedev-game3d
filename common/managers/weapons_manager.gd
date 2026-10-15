extends Node3D

@onready var ray_cast_origin: Node3D = $RayCastOrigin
@onready var weapon_ray_cast: RayCast3D = $RayCastOrigin/WeaponRayCast
@onready var main_camera: Camera3D = %MainCamera

# Smooth follow settings
@export var follow_speed: float = 60.0 

# Weapon index for switching
# Pistol is index 1; the knife is index 0.
@export var weapons_array: Array[Node3D] = []
var current_weapon_index: int = 1
var current_weapon: Node3D

# Track aim mode state
var current_aim_mode: bool = false

# Weapon switch state
var is_switching: bool = false
var switch_tween: Tween
var motion_pivots: Array[Node3D] = []
var recoil_tween: Tween
var reload_tween: Tween

func _ready() -> void:
	# Start with a firearm so the first encounter is immediately playable.
	current_weapon_index = 1
	_build_motion_pivots()
	_setup_current_weapon()
	
	# Connect to input signals
	Global.fire_input.connect(_on_fire_input)
	Global.reload_input.connect(_on_reload_input)
	Global.weapon_switch_next.connect(switch_to_next_weapon)
	Global.weapon_switch_prev.connect(switch_to_previous_weapon)
	Global.aim_mode_changed.connect(_on_aim_mode_changed)

func _build_motion_pivots() -> void:
	for index in weapons_array.size():
		var weapon: Node3D = weapons_array[index]
		var pivot := Node3D.new()
		pivot.name = "MotionPivot"
		weapon.add_child(pivot)
		weapon.fps_arms_root.reparent(pivot, true)
		motion_pivots.append(pivot)
		weapon.fired.connect(_on_weapon_fired.bind(index))
		weapon.reload_started.connect(_on_weapon_reload_started.bind(index))
		weapon.reload_finished.connect(_on_weapon_reload_finished.bind(index))

func _setup_current_weapon() -> void:
	current_weapon = weapons_array[current_weapon_index]
	
	# Initialize all weapons
	for weapon in weapons_array:
		weapon.initialize(main_camera, weapon_ray_cast, ray_cast_origin)
		weapon.deactivate()
	
	# Activate current weapon (pistol) with current aim mode
	current_weapon.activate(current_aim_mode)

func _process(_delta: float) -> void:
	# Smoothly interpolate position and rotation to follow camera
	var target_transform = main_camera.global_transform
	
	# Lerp position
	global_position = global_position.lerp(target_transform.origin, follow_speed * _delta)
	
	# Slerp rotation (spherical linear interpolation for smooth rotation)
	var current_basis = global_transform.basis
	var target_basis = target_transform.basis
	global_transform.basis = current_basis.slerp(target_basis, follow_speed * _delta)
	
	# Continuous firing for automatic weapons (burst mode)
	# Pass false to indicate this is NOT the initial press
	if not is_switching and Input.is_action_pressed("fire") and current_weapon.burst_mode:
		current_weapon.try_fire(false)

func _on_fire_input() -> void:
	if not is_switching:
		current_weapon.try_fire(true)

func _on_reload_input() -> void:
	if is_switching or current_weapon.is_melee_weapon:
		return
	current_weapon.start_reload()

func _on_weapon_fired(index: int) -> void:
	if index != current_weapon_index:
		return
	var pivot: Node3D = motion_pivots[index]
	if recoil_tween:
		recoil_tween.kill()
	if current_weapon.is_melee_weapon:
		pivot.position = Vector3(-0.07, 0.0, -0.09)
		pivot.rotation_degrees = Vector3(-9.0, 0.0, -24.0)
		recoil_tween = create_tween().set_parallel(true)
		recoil_tween.set_trans(Tween.TRANS_CUBIC)
		recoil_tween.tween_property(pivot, "position", Vector3.ZERO, 0.24)
		recoil_tween.tween_property(pivot, "rotation_degrees", Vector3.ZERO, 0.24)
		return
	var kick := 8.0 if index == 1 else 4.5
	pivot.position = Vector3(0, 0.015, 0.065 if index == 1 else 0.045)
	pivot.rotation_degrees = Vector3(kick, randf_range(-1.0, 1.0), 0)
	recoil_tween = create_tween().set_parallel(true)
	recoil_tween.set_trans(Tween.TRANS_CUBIC)
	recoil_tween.set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(pivot, "position", Vector3.ZERO, 0.16)
	recoil_tween.tween_property(pivot, "rotation_degrees", Vector3.ZERO, 0.16)

func _on_weapon_reload_started(duration: float, index: int) -> void:
	if index != current_weapon_index:
		return
	if recoil_tween:
		recoil_tween.kill()
	if reload_tween:
		reload_tween.kill()
	var pivot: Node3D = motion_pivots[index]
	pivot.position = Vector3.ZERO
	pivot.rotation_degrees = Vector3.ZERO
	reload_tween = create_tween()
	reload_tween.set_trans(Tween.TRANS_SINE)
	reload_tween.set_ease(Tween.EASE_IN_OUT)
	reload_tween.tween_property(pivot, "position", Vector3(0.06, -0.11, 0.06), duration * 0.3)
	reload_tween.parallel().tween_property(pivot, "rotation_degrees", Vector3(-12, 0, -10), duration * 0.3)
	reload_tween.tween_interval(duration * 0.4)
	reload_tween.tween_property(pivot, "position", Vector3.ZERO, duration * 0.3)
	reload_tween.parallel().tween_property(pivot, "rotation_degrees", Vector3.ZERO, duration * 0.3)

func _on_weapon_reload_finished(index: int) -> void:
	if index != current_weapon_index:
		return
	var pivot: Node3D = motion_pivots[index]
	pivot.position = Vector3.ZERO
	pivot.rotation_degrees = Vector3.ZERO

func _on_aim_mode_changed(aim_mode: bool) -> void:
	# Update tracked aim mode
	current_aim_mode = aim_mode
	
	# The weapon will handle its own animation through its connected signal
	# No need to do anything else here as each weapon is connected to the global signal

# Weapon switching functions
func switch_to_next_weapon() -> void:
	if current_weapon.is_reloading:
		return
	var next_index = (current_weapon_index + 1) % weapons_array.size()
	switch_weapon(next_index)

func switch_to_previous_weapon() -> void:
	if current_weapon.is_reloading:
		return
	var prev_index = (current_weapon_index - 1 + weapons_array.size()) % weapons_array.size()
	switch_weapon(prev_index)

func switch_weapon(index: int) -> void:
	if index < 0 or index >= weapons_array.size():
		return
	if index == current_weapon_index and not is_switching:
		return
	
	# Kill any in-progress tween to prevent stale callbacks running
	if switch_tween:
		switch_tween.kill()
	if recoil_tween:
		recoil_tween.kill()
	if reload_tween:
		reload_tween.kill()
	for pivot in motion_pivots:
		pivot.position = Vector3.ZERO
		pivot.rotation_degrees = Vector3.ZERO
	
	# Deactivate ALL weapons immediately — prevents double-visibility on rapid scroll
	for weapon in weapons_array:
		weapon.deactivate()
	
	# Update the reference now so rapid calls always operate on the correct weapon
	current_weapon_index = index
	current_weapon = weapons_array[current_weapon_index]
	is_switching = true
	var pivot: Node3D = motion_pivots[index]
	pivot.position = Vector3(0, -0.22, 0.08)
	pivot.rotation_degrees = Vector3(-20, 0, 0)
	
	switch_tween = create_tween()
	switch_tween.set_ease(Tween.EASE_IN_OUT)
	switch_tween.set_trans(Tween.TRANS_SINE)
	
	switch_tween.tween_interval(0.12)
	switch_tween.tween_callback(func():
		current_weapon.activate(current_aim_mode)
		Global.bullets_changed.emit()
	)
	switch_tween.tween_property(pivot, "position", Vector3.ZERO, 0.28)
	switch_tween.parallel().tween_property(pivot, "rotation_degrees", Vector3.ZERO, 0.28)
	
	switch_tween.tween_callback(func():
		is_switching = false
	)

# Helper functions to get weapon state
func get_current_mag() -> int:
	return current_weapon.get_current_mag()

func get_current_ammo() -> int:
	return current_weapon.get_current_ammo()

func get_max_ammo() -> int:
	return current_weapon.get_max_ammo()
