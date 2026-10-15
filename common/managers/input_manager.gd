extends Node

var mouse_mode_captured:bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	if not Global.in_vehicle:
		#FIRING
		if Input.is_action_just_pressed("fire"):
			Global.fire_input.emit()

		#RELOAD
		if Input.is_action_just_pressed("reload"):
			Global.reload_input.emit()

		#WEAPON SWITCHING
		if Input.is_action_just_pressed("weapon_change_next"):
			Global.weapon_switch_next.emit()

		if Input.is_action_just_pressed("weapon_change_prev"):
			Global.weapon_switch_prev.emit()

	#ACTIVATE
	if Input.is_action_just_pressed("activate"):
		Global.activate_pressed.emit()

