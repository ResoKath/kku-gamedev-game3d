extends Node3D

const AMBIENCE := preload("res://audio/third_party/ambient_horror.ogg")
const HEARTBEAT := preload("res://audio/third_party/heartbeat_slow.wav")
const BREATH := preload("res://audio/third_party/breathing/horrorbreathing/horrorbreathing.ogg")
const CREATURES := [preload("res://audio/third_party/creature_01.wav"), preload("res://audio/third_party/creature_02.wav"), preload("res://audio/third_party/creature_03.wav"), preload("res://audio/third_party/creature_04.wav"), preload("res://audio/third_party/creature_05.wav")]
const DEBUFF_THRESHOLD := 100.0
const DEBUFF_DURATION := 8.0

var game
var rng := RandomNumberGenerator.new()
var sound_timer := 8.0
var drone: AudioStreamPlayer
var positional: AudioStreamPlayer3D
var heartbeat: AudioStreamPlayer
var breath: AudioStreamPlayer3D
var enabled := false
var fear := 0.0
var nearest_distance := INF
var nearest_enemy: Node3D
var nearest_visible := false
var debuff_remaining := 0.0
var debuff_armed := true
var quiet_remaining := 0.0
var audio_duck_db := 0.0
var looming_progress := 0.0
var looming_start := Vector3.ZERO
var looming_side := 1.0
var fear_hint_shown := false
var panic_overlay: ColorRect
var panic_shade := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	game = get_parent()
	rng.randomize()
	drone = AudioStreamPlayer.new()
	drone.stream = AMBIENCE.duplicate()
	drone.stream.loop = true
	drone.bus = "Ambience"
	drone.volume_db = -18.0
	add_child(drone)
	positional = AudioStreamPlayer3D.new()
	positional.bus = "SFX"
	positional.max_distance = 32.0
	positional.unit_size = 7.0
	positional.volume_db = -13.0
	add_child(positional)
	heartbeat = AudioStreamPlayer.new()
	var heart_stream: AudioStreamWAV = HEARTBEAT.duplicate()
	heart_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	heart_stream.loop_begin = 0
	heart_stream.loop_end = roundi(heart_stream.get_length() * heart_stream.mix_rate)
	heartbeat.stream = heart_stream
	heartbeat.bus = "Ambience"
	heartbeat.volume_db = -60.0
	add_child(heartbeat)
	breath = AudioStreamPlayer3D.new()
	breath.stream = BREATH
	breath.bus = "Ambience"
	breath.unit_size = 2.0
	breath.max_distance = 10.0
	breath.volume_db = -22.0
	add_child(breath)
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "PanicDarkness"
	overlay_layer.layer = 0
	add_child(overlay_layer)
	panic_overlay = ColorRect.new()
	panic_overlay.name = "Vignette"
	panic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panic_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panic_shader := Shader.new()
	panic_shader.code = "shader_type canvas_item; uniform float intensity = 0.0; void fragment() { vec2 p = UV * 2.0 - 1.0; float edge = smoothstep(0.25, 1.15, length(p)); float pulse = 0.9 + 0.1 * sin(TIME * 5.0); COLOR = vec4(0.01, 0.015, 0.03, intensity * (0.22 + 0.6 * edge) * pulse); }"
	var shade_material := ShaderMaterial.new()
	shade_material.shader = panic_shader
	panic_overlay.material = shade_material
	overlay_layer.add_child(panic_overlay)

func start() -> void:
	enabled = true
	fear = 0.0
	debuff_remaining = 0.0
	debuff_armed = true
	game.player.fear_debuff = false
	panic_shade = 0.0
	panic_overlay.material.set_shader_parameter("intensity", 0.0)
	drone.play()
	heartbeat.play()

func _process(delta: float) -> void:
	if not enabled or game.phase != "playing":
		return
	_update_fear(delta)
	_update_debuff(delta)
	panic_shade = move_toward(panic_shade, 1.0 if game.player.fear_debuff else 0.0, delta * 2.0)
	panic_overlay.material.set_shader_parameter("intensity", panic_shade)
	_update_soundscape(delta)
	sound_timer -= delta
	if sound_timer <= 0:
		sound_timer = rng.randf_range(11.0, 22.0) if fear < 50 else rng.randf_range(7.0, 14.0)
		if rng.randf() < 0.25:
			quiet_remaining = rng.randf_range(2.5, 5.0)
		else:
			_start_looming_sound()

func _sample_threat() -> void:
	nearest_distance = INF
	nearest_enemy = null
	nearest_visible = false
	for enemy in game.get_node("Enemies").get_children():
		if enemy.get("is_alive") != true:
			continue
		var distance: float = enemy.global_position.distance_to(game.player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	if is_instance_valid(nearest_enemy) and nearest_distance < 16.0:
		var ray := PhysicsRayQueryParameters3D.create(game.player.camera.global_position, nearest_enemy.global_position + Vector3(0, 1.2, 0), 1, [game.player.get_rid(), nearest_enemy.get_rid()])
		nearest_visible = get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _update_fear(delta: float) -> void:
	_sample_threat()
	if nearest_distance < 14.0:
		var rate := lerpf(2.0, 22.0, 1.0 - clampf(nearest_distance / 14.0, 0.0, 1.0))
		if not nearest_visible:
			rate *= 0.25
		fear = minf(100.0 if nearest_visible else 65.0, fear + rate * delta) if fear < 65.0 or nearest_visible else move_toward(fear, 65.0, 3.0 * delta)
	else:
		fear = move_toward(fear, 0.0, 8.0 * delta)
	if fear >= 35 and fear < DEBUFF_THRESHOLD and not fear_hint_shown:
		fear_hint_shown = true
		game._show_hint("Fear rising — back away from the monster.", 4.0)

func _update_debuff(delta: float) -> void:
	if debuff_remaining > 0.0:
		debuff_remaining = maxf(0.0, debuff_remaining - delta)
		if debuff_remaining == 0.0:
			game.player.fear_debuff = false
	elif fear < 70.0:
		debuff_armed = true
	if debuff_armed and fear >= DEBUFF_THRESHOLD and debuff_remaining == 0.0:
		debuff_armed = false
		debuff_remaining = DEBUFF_DURATION
		game.player.fear_debuff = true
		game._show_hint("PANIC — you cannot sprint. Break away.", 4.0)
	game.get_node("HUD/Control").update_fear(fear, DEBUFF_THRESHOLD, debuff_remaining > 0.0)

func _start_looming_sound() -> void:
	var angle := rng.randf_range(-PI, PI)
	looming_start = game.player.global_position + Vector3(cos(angle) * 12.0, 1.5, sin(angle) * 12.0)
	looming_progress = 0.001
	looming_side = -1.0 if rng.randf() < 0.5 else 1.0
	positional.global_position = looming_start
	positional.stream = CREATURES[rng.randi_range(0, CREATURES.size() - 1)]
	positional.pitch_scale = rng.randf_range(0.62, 0.88)
	positional.volume_db = -22.0
	positional.play()
	if fear >= 45 and not breath.playing:
		breath.pitch_scale = rng.randf_range(0.8, 1.0)
		breath.global_position = game.player.camera.global_position + game.player.camera.global_basis.x * looming_side * 1.2 + game.player.camera.global_basis.z
		breath.play()

func _update_soundscape(delta: float) -> void:
	quiet_remaining = maxf(0.0, quiet_remaining - delta)
	var duck_target := 8.0 if debuff_remaining > 0.0 else (12.0 if quiet_remaining > 0.0 else 0.0)
	audio_duck_db = move_toward(audio_duck_db, duck_target, delta * 24.0)
	drone.volume_db = move_toward(drone.volume_db, lerpf(-29.0, -17.0, fear / 100.0) - audio_duck_db, delta * 8.0)
	heartbeat.volume_db = move_toward(heartbeat.volume_db, lerpf(-40.0, -12.0, fear / 100.0) if fear >= 15 else -60.0, delta * 12.0)
	heartbeat.pitch_scale = lerpf(0.9, 1.7, fear / 100.0)
	if looming_progress > 0 and positional.playing:
		looming_progress = minf(1.0, looming_progress + delta / 4.0)
		var end: Vector3 = game.player.camera.global_position + game.player.camera.global_basis.x * looming_side * 2.0 + game.player.camera.global_basis.z * 2.0
		positional.global_position = looming_start.lerp(end, looming_progress * fear / 100.0)
		positional.volume_db = lerpf(-22.0, -13.0, looming_progress * fear / 100.0)
	else:
		looming_progress = 0.0

func stop() -> void:
	enabled = false
	debuff_remaining = 0.0
	game.player.fear_debuff = false
	panic_shade = 0.0
	panic_overlay.material.set_shader_parameter("intensity", 0.0)
	audio_duck_db = 0.0
	drone.stop()
	positional.stop()
	heartbeat.stop()
	breath.stop()
