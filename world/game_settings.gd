extends RefCounted

const PATH := "user://settings.cfg"
const DEFAULTS := {"master": 0.85, "ambience": 0.8, "music": 0.5, "effects": 0.85, "sensitivity": 0.003, "brightness": 1.0, "fullscreen": true}
var values: Dictionary = DEFAULTS.duplicate()

func load_settings(file_path: String = PATH) -> void:
	var config := ConfigFile.new()
	if config.load(file_path) != OK:
		return
	for key in DEFAULTS:
		var value = config.get_value("game", key, DEFAULTS[key])
		if typeof(value) == typeof(DEFAULTS[key]):
			values[key] = value
	for key in ["master", "ambience", "music", "effects"]:
		values[key] = clampf(values[key], 0.0, 1.0)
	values.sensitivity = clampf(values.sensitivity, 0.001, 0.01)
	values.brightness = clampf(values.brightness, 0.7, 1.7)

func save_settings(file_path: String = PATH) -> Error:
	var config := ConfigFile.new()
	for key in values:
		config.set_value("game", key, values[key])
	return config.save(file_path)

func setup_buses() -> void:
	for bus in ["Ambience", "Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.7
		reverb.wet = 0.12
		AudioServer.add_bus_effect(sfx, reverb)

func apply(game: Node) -> void:
	for pair in [["Master", "master"], ["Ambience", "ambience"], ["Music", "music"], ["SFX", "effects"]]:
		var index := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, values[pair[1]])))
		AudioServer.set_bus_mute(index, values[pair[1]] == 0.0)
	game.player.sensitivity = values.sensitivity
	var environment: Environment = game.get_node("WorldEnvironment").environment
	environment.tonemap_exposure = values.brightness
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
