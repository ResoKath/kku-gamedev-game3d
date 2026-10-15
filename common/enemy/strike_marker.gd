extends Node3D

var radius := 2.0
var damage := 18.0
var warning_time := 0.95
var color := Color(1.0, 0.15, 0.08)
var elapsed := 0.0
var disc: MeshInstance3D
var light: OmniLight3D

func _ready() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.035
	disc = MeshInstance3D.new()
	disc.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.38)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	disc.material_override = material
	add_child(disc)
	light = OmniLight3D.new()
	light.light_color = color
	light.omni_range = radius * 2.4
	light.light_energy = 0.7
	add_child(light)

func _process(delta: float) -> void:
	elapsed += delta
	var pulse := 0.75 + 0.25 * sin(elapsed * 18.0)
	disc.scale = Vector3(pulse, 1.0, pulse)
	if elapsed < warning_time:
		return
	var player = get_node("/root/Global").player
	if is_instance_valid(player) and player.is_alive:
		var gap: Vector3 = player.global_position - global_position
		gap.y = 0.0
		if gap.length() < radius:
			player.get_damage(damage, gap.normalized(), true)
	var flash := create_tween()
	flash.tween_property(light, "light_energy", 0.0, 0.2)
	flash.parallel().tween_property(disc, "scale", Vector3.ONE * 1.5, 0.2)
	flash.tween_callback(queue_free)
	set_process(false)
