extends Control

const UI_FONT := preload("res://resources/fonts/BarlowCondensed-SemiBold.ttf")
const CYAN := Color("a9c8d4")
const WHITE := Color("ecece4")
const MUTED := Color("88a4a7")
const RED := Color("e7514a")

@onready var enemies_label: Label = $EnemiesLabel
@onready var bullets_label: Label = $BulletsLabel
@onready var health_bar: ProgressBar = $HealthBar

var weapons_manager = null
var health_number: Label
var weapon_label: Label
var reserve_label: Label
var fear_bar: ProgressBar
var fear_label: Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build_visuals()
	Global.bullets_changed.connect(_on_bullets_changed)
	Global.player_health_changed.connect(_on_player_health_changed)
	Global.enemy_count_changed.connect(_on_enemy_count_changed)
	
	# Get weapons manager from player
	if Global.player:
		weapons_manager = Global.player.get_node_or_null("WeaponsManager")
	
	# Initial display updates
	_on_bullets_changed()
	_on_enemy_count_changed(Global.enemies_killed)
	if Global.player:
		update_health_bar(Global.player.current_health, 100.0)

func _build_visuals() -> void:
	enemies_label.hide()
	weapon_label = _label("", 19, WHITE)
	weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	weapon_label.offset_left = -280
	weapon_label.offset_right = -70
	weapon_label.offset_top = -156
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_number = _label("100", 66, CYAN)
	health_number.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_number.offset_left = 105
	health_number.offset_top = -139
	var cross := _label("+", 42, CYAN)
	cross.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cross.offset_left = 66
	cross.offset_top = -120
	_set_label_style(bullets_label, 76, WHITE)
	bullets_label.offset_left = -265
	bullets_label.offset_top = -139
	bullets_label.offset_right = -130
	bullets_label.offset_bottom = -50
	bullets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reserve_label = _label("/ 60", 28, Color("acaaa0"))
	reserve_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	reserve_label.offset_left = -117
	reserve_label.offset_top = -93
	health_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_bar.offset_left = 70
	health_bar.offset_top = -53
	health_bar.offset_right = 280
	health_bar.offset_bottom = -46
	health_bar.custom_minimum_size = Vector2.ZERO
	health_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.5, 0.6, 0.62, 0.22)
	background.set_corner_radius_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.set_corner_radius_all(0)
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	# Break the health strip into readable segments, without a surrounding card.
	for index in range(1, 10):
		var gap := ColorRect.new()
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		gap.position = Vector2(70 + index * 21, -53)
		gap.size = Vector2(3, 7)
		gap.color = Color("151b1d")
		add_child(gap)
	fear_label = _label("FEAR  0%", 19, Color("a69c83"))
	fear_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fear_label.offset_left = 70
	fear_label.offset_top = -212
	fear_bar = ProgressBar.new()
	fear_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fear_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fear_bar.position = Vector2(70, -177)
	fear_bar.size = Vector2(210, 6)
	fear_bar.show_percentage = false
	var fear_background := StyleBoxFlat.new()
	fear_background.bg_color = Color(0.6, 0.5, 0.3, 0.2)
	var fear_fill := StyleBoxFlat.new()
	fear_fill.bg_color = Color("b9a274")
	fear_bar.add_theme_stylebox_override("background", fear_background)
	fear_bar.add_theme_stylebox_override("fill", fear_fill)
	add_child(fear_bar)
	var threshold := ColorRect.new()
	threshold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threshold.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	threshold.position = Vector2(278, -181)
	threshold.size = Vector2(2, 14)
	threshold.color = Color("e7514a")
	add_child(threshold)

func update_fear(value: float, threshold: float, debuffed: bool = false) -> void:
	fear_bar.value = value
	fear_label.text = "PANIC — DISORIENTED" if debuffed else "FEAR  %d%%" % roundi(value)
	var tint := RED if debuffed or value >= threshold else Color("b9a274")
	fear_label.add_theme_color_override("font_color", tint)
	var fill: StyleBoxFlat = fear_bar.get_theme_stylebox("fill")
	fill.bg_color = tint

func _label(value: String, size_px: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_label_style(label, size_px, tint)
	add_child(label)
	return label

func _set_label_style(label: Label, size_px: int, tint: Color) -> void:
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _on_bullets_changed() -> void:
	if not weapons_manager or not weapons_manager.current_weapon:
		bullets_label.text = "--"
		reserve_label.text = ""
		return
	
	var current_mag = weapons_manager.get_current_mag()
	var current_ammo = weapons_manager.get_current_ammo()
	
	if weapons_manager.current_weapon.reload_required:
		bullets_label.text = str(current_mag)
		reserve_label.text = "/ " + ("∞" if current_ammo == -1 else str(current_ammo))
	else:
		bullets_label.text = "∞" if current_ammo == -1 else str(current_ammo)
		reserve_label.text = ""
	weapon_label.text = str(weapons_manager.current_weapon.name).to_upper()


func _on_enemy_count_changed(count: int) -> void:
	enemies_label.text = "%02d" % count


func _on_player_health_changed(_health_change:float,current_health:float,max_health:float, _is_enemy_damage:bool) -> void:
	update_health_bar(current_health,max_health)
		

func update_health_bar(current_health,max_health) -> void:
	health_bar.value = current_health
	health_bar.max_value = max_health
	health_number.text = str(roundi(current_health))
	health_number.add_theme_color_override("font_color", RED if current_health <= 25.0 else CYAN)
	var fill: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	fill.bg_color = RED if current_health <= 25.0 else CYAN
