extends Node3D

const SAFE_SPAWN := Vector3(100, 0.2, 0)
const OBJECTIVE_CELLS := [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(6, 4), Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 4)]
const OBJECTIVES := [
	"Recover the crew log", "Secure the med bay", "Restart the reactor", "Seal the cargo hold",
	"Restore navigation", "Purge the maintenance deck", "Open the armory", "Silence the comms array",
	"Reach the command bridge", "Defeat the infected captain"
]
const TARGET_NAMES := ["CREW LOG", "MED BAY", "REACTOR", "CARGO HOLD", "NAVIGATION", "MAINTENANCE", "ARMORY", "COMMS", "BRIDGE", "CAPTAIN"]
const KILLS_REQUIRED := [4, 6, 7, 9, 10, 11, 13, 14, 16, 0]
const ACTION_HINTS := ["[F] Read the log", "[F] Secure med bay", "[F] Restart reactor", "[F] Seal cargo hold", "[F] Restore navigation", "[F] Purge maintenance", "[F] Open armory", "[F] Silence comms", "[F] Access bridge", "[F] Evacuate"]
const UI_FONT := preload("res://resources/fonts/BarlowCondensed-Regular.ttf")
const DISPLAY_FONT := preload("res://resources/fonts/BarlowCondensed-SemiBold.ttf")
const INK := Color("040a0e")
const PANEL := Color("08151c")
const CYAN := Color("d1d4ce")
const WHITE := Color("ecece4")
const MUTED := Color("969c98")
const AMBER := Color("e9ad5a")
const RED := Color("e7514a")

@onready var player = $Player
@onready var director = $ThreatDirector
@onready var sector = $SectorMap

var phase := "menu"
var objective_index := 0
var gate_open := false
var boss_entry_sealed := false
var mission_layer: CanvasLayer
var mission_label: Label
var prompt_label: Label
var story_label: Label
var menu_cover: ColorRect
var story_remaining := 0.0
var boss
var boss_label: Label
var ambient_player: AudioStreamPlayer
var combat_player: AudioStreamPlayer
var hints_seen: Dictionary = {}
var controls_return := "intro"
var settings = preload("res://world/game_settings.gd").new()
var settings_return := "intro"
var horror: Node3D

func _ready() -> void:
	for node_name in ["Player", "InputManager", "Enemies", "ThreatDirector", "SectorMap"]:
		get_node(node_name).process_mode = Node.PROCESS_MODE_PAUSABLE
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.global_position = SAFE_SPAWN
	Global.enemies_killed = 0
	for entry in [[Bullets.AmmoType.PISTOL, 48], [Bullets.AmmoType.ASSAULT, 160], [Bullets.AmmoType.LMG, 50]]:
		Bullets.ammo_inventory[entry[0]]["current"] = entry[1]
	Global.player_dead.connect(_on_player_dead)
	Global.activate_pressed.connect(_on_activate)
	settings.load_settings()
	settings.setup_buses()
	_build_mission_ui()
	_build_audio()
	horror = Node3D.new()
	horror.set_script(preload("res://world/horror_director.gd"))
	horror.name = "HorrorDirector"
	add_child(horror)
	settings.apply(self)
	_show_menu("intro")
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if phase != "playing":
		return
	if player.global_position.y < -4.0:
		var safe_cell: Vector2i = OBJECTIVE_CELLS[objective_index]
		player.global_position = sector.room_center(safe_cell.x, safe_cell.y) + Vector3(0, 0.2, 0)
		player.velocity = Vector3.ZERO
	if gate_open and objective_index < 9 and sector.get_cell(player.global_position) == OBJECTIVE_CELLS[objective_index + 1]:
		_advance_stage()
	if objective_index == 9 and not boss_entry_sealed and player.global_position.distance_to(sector.gate_position(8)) > 6.0:
		sector.close_stage_gate(8)
		boss_entry_sealed = true
	var target: Vector3 = _target_position()
	var distance: float = player.global_position.distance_to(target)
	var camera: Camera3D = player.get_node("CameraPivot/CameraHolder/MainCamera")
	var forward := -camera.global_transform.basis.z
	var to_target: Vector3 = (target - player.global_position).normalized()
	var cross: float = forward.x * to_target.z - forward.z * to_target.x
	var arrow := "↑" if forward.dot(to_target) > 0.75 else ("→" if cross > 0 else "←")
	var kills_left := _kills_remaining()
	mission_label.text = "STAGE %02d/10  |  %s  %s  %dm  |  LEFT %d" % [objective_index + 1, TARGET_NAMES[objective_index], arrow, roundi(distance), kills_left]
	var boss_alive: bool = objective_index == 9 and is_instance_valid(boss) and boss.is_alive
	prompt_label.text = (("Door open. Walk through." if gate_open else ("Defeat the captain" if boss_alive else ("Purge %d more hostiles" % kills_left if kills_left > 0 else "[F] Open the next door"))) if distance < 4.5 else "")
	boss_label.visible = boss_alive
	if boss_alive:
		boss_label.text = "INFECTED CAPTAIN  |  %d / %d" % [ceili(boss.current_health), ceili(boss.max_health)]
	story_label.visible = prompt_label.text.is_empty()
	if story_remaining > 0:
		story_remaining -= delta
		if story_remaining <= 0:
			story_label.text = ""
	var danger := false
	for enemy in $Enemies.get_children():
		if enemy.get("is_alive") == true and enemy.global_position.distance_to(player.global_position) < 24:
			danger = true
			break
	_update_guidance(danger)
	var duck: float = horror.audio_duck_db
	ambient_player.volume_db = move_toward(ambient_player.volume_db, (-24.0 if danger else -16.0) - duck, delta * 16)
	combat_player.volume_db = move_toward(combat_player.volume_db, (-14.0 if danger else -50.0) - duck, delta * 20)

func _show_hint(value: String, duration: float = 6.0) -> void:
	story_label.text = value
	story_remaining = duration

func _update_guidance(danger: bool) -> void:
	if story_remaining > 0 or not prompt_label.text.is_empty():
		return
	var weapons = player.get_node("WeaponsManager")
	if danger and not hints_seen.has("combat"):
		hints_seen["combat"] = true
		_show_hint("Left click to fire. Keep moving with WASD.")
	elif weapons.current_weapon and weapons.current_weapon.reload_required and weapons.get_current_mag() == 0 and not hints_seen.has("reload"):
		hints_seen["reload"] = true
		_show_hint("Empty magazine — press R to reload, or scroll to switch weapons.")
	elif not hints_seen.has("route") and player.global_position.distance_to(SAFE_SPAWN) > 4.0:
		hints_seen["route"] = true
		_show_hint(OBJECTIVES[objective_index] + ". Follow the arrow.", 8.0)

func _target_position() -> Vector3:
	return sector.gate_position(objective_index)

func _kills_remaining() -> int:
	if objective_index == 9:
		return (1 if is_instance_valid(boss) and boss.is_alive else 0) + director.living_count() + director.remaining_to_spawn
	return director.remaining_count()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("exit") and phase in ["playing", "paused"]:
		get_viewport().set_input_as_handled()
		if phase == "playing":
			_pause_game()
		else:
			_resume_game()
	elif event.is_action_pressed("exit") and phase == "controls":
		get_viewport().set_input_as_handled()
		_show_menu(controls_return)
	elif event.is_action_pressed("exit") and phase == "settings":
		get_viewport().set_input_as_handled()
		_show_menu(settings_return)

func _on_activate() -> void:
	if phase != "playing":
		return
	if player.global_position.distance_to(_target_position()) > 4.5 or gate_open:
		return
	if objective_index == 9 and is_instance_valid(boss) and boss.is_alive:
		_show_hint("Defeat the infected captain first.", 3.0)
		return
	if _kills_remaining() > 0:
		_show_hint("Clear %d more hostiles to unlock the door." % _kills_remaining(), 3.5)
		return
	sector.open_stage_gate(objective_index)
	gate_open = true
	if objective_index == 9:
		_finish_game()
		return
	_show_hint("Door unlocked. Walk into the next stage.", 5.0)

func _advance_stage() -> void:
	objective_index += 1
	gate_open = false
	_show_hint("Stage %d. %s." % [objective_index + 1, OBJECTIVES[objective_index]], 6.0)
	if objective_index == 9:
		director.stop()
		for enemy in $Enemies.get_children():
			enemy.queue_free()
		_spawn_boss()
		_spawn_warden()
		director.begin_boss_stage(sector.get_boss_cells())
		_show_hint("Move out of the red blast zones. Use cover against drones.", 7.0)
	else:
		director.begin_stage(objective_index, OBJECTIVE_CELLS[objective_index], KILLS_REQUIRED[objective_index])
		if objective_index in [3, 6, 8]:
			sector.blackout(3.5)
			_show_hint("Emergency lights failed. Watch for flanking robots.", 5.0)
	var health_before: float = player.current_health
	player.current_health = minf(100.0, health_before + 25.0)
	Global.player_health_changed.emit(player.current_health - health_before, player.current_health, 100.0, false)
	Bullets._add_ammo(Bullets.AmmoType.PISTOL, 30)
	Bullets._add_ammo(Bullets.AmmoType.ASSAULT, 90)
	Bullets._add_ammo(Bullets.AmmoType.LMG, 45)
	Global.bullets_changed.emit()

func _spawn_boss() -> void:
	boss = preload("res://enemies/undead.tscn").instantiate()
	boss.name = "InfectedCaptain"
	boss.position = sector.room_center(0, 6) + Vector3(4, 0.2, -4)
	boss.scale = Vector3.ONE * 1.25
	boss.max_health = 2400.0
	boss.attack_damage = 32.0
	boss.attack_range = 2.6
	boss.move_speed = player.sprint_speed * 0.75
	boss.vision_range = 160.0
	boss.chase_time = 120.0
	boss.show_health_bar = true
	$Enemies.add_child(boss)
	boss.is_chasing = true
	for mesh in boss.character_root.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = false
	var captain_model := preload("res://assets/third_party/sci_fi_essentials/Enemy_QuadShell.gltf").instantiate()
	captain_model.scale = Vector3.ONE * 1.45
	boss.character_root.add_child(captain_model)
	var captain_animation := captain_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if captain_animation and captain_animation.has_animation("Run"):
		captain_animation.play("Run")
	var glow := OmniLight3D.new()
	glow.name = "CaptainGlow"
	glow.position = Vector3(0, 2.1, 0)
	glow.light_color = RED
	glow.light_energy = 1.4
	glow.omni_range = 5.0
	boss.add_child(glow)
	var abilities := Node.new()
	abilities.set_script(preload("res://common/enemy/boss_abilities.gd"))
	boss.add_child(abilities)

func _spawn_warden() -> void:
	var warden = preload("res://enemies/undead.tscn").instantiate()
	warden.name = "InfectedWarden"
	warden.position = sector.room_center(1, 5) + Vector3(-2, 0.2, 3)
	warden.scale = Vector3.ONE * 1.12
	warden.max_health = 1100.0
	warden.attack_damage = 22.0
	warden.attack_range = 2.3
	warden.move_speed = player.walk_speed * 1.3
	warden.vision_range = 160.0
	warden.chase_time = 120.0
	warden.show_health_bar = true
	$Enemies.add_child(warden)
	warden.is_chasing = true
	for mesh in warden.character_root.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = false
	var warden_model := preload("res://assets/third_party/sci_fi_essentials/Enemy_Trilobite.gltf").instantiate()
	warden_model.scale = Vector3.ONE * 1.8
	warden.character_root.add_child(warden_model)
	var warden_animation := warden_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if warden_animation and warden_animation.has_animation("Run"):
		warden_animation.play("Run")
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.9, 0)
	glow.light_color = Color(1.0, 0.3, 0.05)
	glow.light_energy = 1.1
	glow.omni_range = 4.5
	warden.add_child(glow)
	var abilities := Node.new()
	abilities.set_script(preload("res://common/enemy/boss_abilities.gd"))
	warden.add_child(abilities)

func _on_player_dead() -> void:
	if phase != "playing":
		return
	phase = "dead"
	director.stop()
	horror.stop()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_menu("dead")

func _start_game() -> void:
	phase = "playing"
	$HUD/Control.show()
	menu_cover.visible = false
	mission_label.visible = true
	prompt_label.visible = true
	story_label.visible = true
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.get_node("WeaponsManager").switch_weapon(1)
	ambient_player.play()
	combat_player.play()
	director.begin_stage(0, OBJECTIVE_CELLS[0], KILLS_REQUIRED[0])
	horror.start()
	_show_hint("WASD to move. Move the mouse to look around.", 6.0)

func _pause_game() -> void:
	phase = "paused"
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_menu("pause")

func _resume_game() -> void:
	phase = "playing"
	$HUD/Control.show()
	mission_label.show()
	prompt_label.show()
	story_label.show()
	menu_cover.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _finish_game() -> void:
	phase = "won"
	director.stop()
	horror.stop()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_menu("won")

func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _build_audio() -> void:
	for node in find_children("*", "AudioStreamPlayer3D", true, false):
		node.bus = "SFX"
	for node in find_children("*", "AudioStreamPlayer", true, false):
		node.bus = "SFX"
	ambient_player = AudioStreamPlayer.new()
	ambient_player.stream = preload("res://audio/third_party/lost_in_a_bad_place.ogg").duplicate()
	ambient_player.stream.loop = true
	ambient_player.volume_db = -16.0
	ambient_player.bus = "Ambience"
	add_child(ambient_player)
	combat_player = AudioStreamPlayer.new()
	combat_player.stream = preload("res://audio/third_party/infestation_control_room.mp3").duplicate()
	combat_player.stream.loop = true
	combat_player.volume_db = -50.0
	combat_player.bus = "Music"
	add_child(combat_player)

func _build_mission_ui() -> void:
	mission_layer = CanvasLayer.new()
	mission_layer.layer = 10
	mission_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(mission_layer)
	mission_label = Label.new()
	mission_label.anchor_left = 0.28
	mission_label.anchor_right = 0.72
	mission_label.offset_top = 36
	mission_label.offset_bottom = 72
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_override("font", UI_FONT)
	mission_label.add_theme_font_size_override("font_size", 21)
	mission_label.add_theme_color_override("font_color", WHITE)
	mission_label.visible = false
	mission_layer.add_child(mission_label)
	boss_label = Label.new()
	boss_label.anchor_left = 0.25
	boss_label.anchor_right = 0.75
	boss_label.offset_top = 82
	boss_label.offset_bottom = 122
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_override("font", DISPLAY_FONT)
	boss_label.add_theme_font_size_override("font_size", 30)
	boss_label.add_theme_color_override("font_color", RED)
	boss_label.visible = false
	mission_layer.add_child(boss_label)
	prompt_label = Label.new()
	prompt_label.anchor_left = 0.3
	prompt_label.anchor_right = 0.7
	prompt_label.anchor_top = 0.73
	prompt_label.anchor_bottom = 0.81
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_override("font", UI_FONT)
	prompt_label.add_theme_font_size_override("font_size", 28)
	prompt_label.add_theme_color_override("font_color", AMBER)
	prompt_label.visible = false
	mission_layer.add_child(prompt_label)
	story_label = Label.new()
	story_label.anchor_left = 0.24
	story_label.anchor_right = 0.76
	story_label.anchor_top = 0.84
	story_label.anchor_bottom = 0.89
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.add_theme_font_override("font", UI_FONT)
	story_label.add_theme_font_size_override("font_size", 25)
	story_label.add_theme_color_override("font_color", CYAN)
	story_label.visible = false
	mission_layer.add_child(story_label)
	menu_cover = ColorRect.new()
	var veil := ShaderMaterial.new()
	var veil_shader := Shader.new()
	veil_shader.code = "shader_type canvas_item;\nvoid fragment(){float edge=1.0-smoothstep(0.1,0.95,UV.x);float grain=fract(sin(dot(UV,vec2(12.9898,78.233)))*43758.5453)*0.012;COLOR=vec4(vec3(0.008+grain),mix(0.18,0.94,edge));}"
	veil.shader = veil_shader
	menu_cover.material = veil
	menu_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	mission_layer.add_child(menu_cover)

func _show_menu(kind: String) -> void:
	$HUD/Control.hide()
	mission_label.hide()
	prompt_label.hide()
	story_label.hide()
	boss_label.hide()
	if kind == "controls":
		phase = "controls"
	elif kind == "intro":
		phase = "menu"
	elif kind == "pause":
		phase = "paused"
	elif kind == "settings":
		phase = "settings"
	menu_cover.visible = true
	for child in menu_cover.get_children():
		child.queue_free()
	if kind == "settings":
		_build_settings_menu()
		return
	if kind == "intro":
		_build_intro_menu()
		return
	var accent := RED if kind == "dead" else (AMBER if kind == "won" else CYAN)
	var title := "YOU DIED" if kind == "dead" else ("ESCAPED" if kind == "won" else ("HOW TO PLAY" if kind == "controls" else "PAUSED"))
	var body: String = "Try another route." if kind == "dead" else ("You made it out." if kind == "won" else ("WASD   Move       SHIFT   Sprint\nMOUSE   Look      LEFT CLICK   Fire\nR   Reload       WHEEL   Switch weapon\nF   Interact     ESC   Pause" if kind == "controls" else OBJECTIVES[objective_index]))
	var panel := _make_panel(Vector2(760, 700), true)
	var panel_style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	panel.add_theme_stylebox_override("panel", panel_style)
	var column := _make_column(panel, 24)
	_add_menu_label(column, title, 65 if kind != "won" else 54, WHITE)
	_add_menu_label(column, body, 28, MUTED)
	_add_spacer(column, 32)
	if kind == "pause":
		_add_menu_button(column, "RESUME", _resume_game, true)
		_add_menu_button(column, "SETTINGS", func(): settings_return = "pause"; _show_menu("settings"))
		_add_menu_button(column, "HOW TO PLAY", func(): controls_return = "pause"; _show_menu("controls"))
		_add_menu_button(column, "RESTART RUN", _restart_game)
		_add_menu_button(column, "EXIT GAME", get_tree().quit)
	elif kind == "controls":
		_add_menu_button(column, "BACK", func(): _show_menu(controls_return), true)
	else:
		_add_menu_label(column, "KILLS  %d" % Global.enemies_killed, 22, accent)
		_add_menu_button(column, "PLAY AGAIN", _restart_game, true)
		_add_menu_button(column, "EXIT GAME", get_tree().quit)

func _build_intro_menu() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(110, 190)
	column.size = Vector2(840, 700)
	column.add_theme_constant_override("separation", 6)
	menu_cover.add_child(column)
	_add_menu_label(column, "HELLGATE", 122, WHITE)
	_add_menu_label(column, "TEN STAGES  /  ONE CAPTAIN", 26, AMBER)
	_add_spacer(column, 82)
	_add_menu_button(column, "NEW GAME", _start_game, true)
	_add_menu_button(column, "SETTINGS", func(): settings_return = "intro"; _show_menu("settings"))
	_add_menu_button(column, "HOW TO PLAY", func(): controls_return = "intro"; _show_menu("controls"))
	_add_menu_button(column, "EXIT GAME", get_tree().quit)
	_add_spacer(column, 42)
	_add_menu_label(column, "ENTER  SELECT     /     ESC  BACK", 18, MUTED)

func _build_settings_menu() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(110, 80)
	column.size = Vector2(780, 840)
	column.add_theme_constant_override("separation", 14)
	menu_cover.add_child(column)
	_add_menu_label(column, "SETTINGS", 65, WHITE)
	_add_menu_label(column, "Changes apply and save automatically.", 21, MUTED)
	for entry in [["master", "MASTER VOLUME", 0.0, 1.0, 0.05], ["ambience", "AMBIENCE", 0.0, 1.0, 0.05], ["music", "COMBAT MUSIC", 0.0, 1.0, 0.05], ["effects", "SOUND EFFECTS", 0.0, 1.0, 0.05], ["sensitivity", "MOUSE SENSITIVITY", 0.001, 0.01, 0.0005], ["brightness", "BRIGHTNESS", 0.7, 1.7, 0.05]]:
		_add_setting_slider(column, entry)
	for entry in [["fullscreen", "FULLSCREEN"]]:
		var toggle := CheckButton.new()
		toggle.text = entry[1]
		toggle.button_pressed = settings.values[entry[0]]
		toggle.add_theme_font_override("font", DISPLAY_FONT)
		toggle.add_theme_font_size_override("font_size", 26)
		toggle.custom_minimum_size.y = 48
		column.add_child(toggle)
		toggle.toggled.connect(func(value: bool): _change_setting(entry[0], value))
	_add_menu_button(column, "BACK", func(): _show_menu(settings_return), true)

func _add_setting_slider(column: VBoxContainer, entry: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	var caption := Label.new()
	caption.text = entry[1]
	caption.custom_minimum_size.x = 255
	caption.add_theme_font_override("font", DISPLAY_FONT)
	caption.add_theme_font_size_override("font_size", 25)
	row.add_child(caption)
	var slider := HSlider.new()
	slider.name = entry[0]
	slider.custom_minimum_size = Vector2(320, 42)
	slider.min_value = entry[2]
	slider.max_value = entry[3]
	slider.step = entry[4]
	slider.value = settings.values[entry[0]]
	row.add_child(slider)
	var number := Label.new()
	number.custom_minimum_size.x = 65
	number.add_theme_font_override("font", UI_FONT)
	number.add_theme_font_size_override("font_size", 25)
	number.text = _setting_value_text(entry[0], slider.value)
	row.add_child(number)
	slider.value_changed.connect(func(value: float):
		number.text = _setting_value_text(entry[0], value)
		_change_setting(entry[0], value))

func _setting_value_text(key: String, value: float) -> String:
	return "%.1f" % (value * 1000.0) if key == "sensitivity" else "%d%%" % roundi(value * 100.0)

func _change_setting(key: String, value: Variant) -> void:
	settings.values[key] = value
	settings.apply(self)
	var error: Error = settings.save_settings()
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))

func _make_panel(min_size: Vector2, centered: bool, parent: Control = menu_cover) -> PanelContainer:
	var target: Control = parent
	if centered:
		var center := MarginContainer.new()
		center.position = Vector2(110, 150)
		menu_cover.add_child(center)
		target = center
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	target.add_child(panel)
	return panel

func _make_column(panel: PanelContainer, separation: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	panel.add_child(column)
	return column

func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)

func _add_menu_label(parent: VBoxContainer, value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UI_FONT)
	if font_size >= 50:
		label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _add_menu_button(parent: VBoxContainer, title: String, action: Callable, primary: bool = false) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(520, 62)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(14)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = WHITE
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = AMBER
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(action)
	parent.add_child(button)
	button.mouse_entered.connect(button.grab_focus)
	if primary:
		button.call_deferred("grab_focus")
