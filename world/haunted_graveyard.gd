extends Node3D

const PACK := "res://assets/kenney/graveyard-kit/Models/GLB format/"
const HALF_WIDTH := 32.0
const Z_START := 10.0
const Z_END := -90.0

var rng := RandomNumberGenerator.new()
var flicker_lights: Array[OmniLight3D] = []
var elapsed := 0.0

func _ready() -> void:
	rng.seed = 666013
	_make_ground()
	_make_perimeter()
	_make_path()
	_make_graves()
	_make_landmarks()
	_make_lights()

func _process(delta: float) -> void:
	elapsed += delta
	for i in flicker_lights.size():
		var light := flicker_lights[i]
		light.light_energy = 1.0 + sin(elapsed * (7.0 + i * 0.7) + i * 1.8) * 0.18
		if sin(elapsed * 1.7 + i * 2.3) > 0.985:
			light.light_energy *= 0.24

func _model(name: String, at: Vector3, yaw := 0.0, size := 1.0) -> Node3D:
	var source: PackedScene = load(PACK + name + ".glb")
	var item: Node3D = source.instantiate()
	item.name = name
	item.position = at
	item.rotation.y = yaw
	item.scale = Vector3.ONE * size
	add_child(item)
	return item

func _box(at: Vector3, dimensions: Vector3, visible := false) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	if visible:
		var mesh := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = dimensions
		mesh.mesh = cube
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.075, 0.09, 0.085)
		material.roughness = 1.0
		mesh.material_override = material
		body.add_child(mesh)
	add_child(body)

func _make_ground() -> void:
	_box(Vector3(0, -0.55, -40), Vector3(64, 1, 100), true)
	# The winding walkway and all visible decoration use Kenney models.
	for z in range(8, -88, -4):
		_model("road", Vector3(rng.randf_range(-0.6, 0.6), 0.015, z), rng.randf_range(-0.05, 0.05), 1.6)

func _make_perimeter() -> void:
	_box(Vector3(-HALF_WIDTH, 2, -40), Vector3(1, 4, 100))
	_box(Vector3(HALF_WIDTH, 2, -40), Vector3(1, 4, 100))
	_box(Vector3(0, 2, Z_START), Vector3(64, 4, 1))
	_box(Vector3(0, 2, Z_END), Vector3(64, 4, 1))
	for z in range(8, -90, -3):
		_model("stone-wall-damaged" if posmod(z, 12) == 0 else "stone-wall", Vector3(-31.5, 0, z), PI / 2)
		_model("stone-wall-damaged" if posmod(z, 15) == 0 else "stone-wall", Vector3(31.5, 0, z), PI / 2)
	for x in range(-30, 32, 3):
		_model("stone-wall", Vector3(x, 0, 9.5))
		_model("stone-wall-damaged", Vector3(x, 0, -89.5))

func _make_path() -> void:
	for z in range(3, -86, -8):
		for side in [-1, 1]:
			var x: float = side * rng.randf_range(5.5, 7.5)
			_model("iron-fence-damaged" if rng.randf() < 0.28 else "iron-fence", Vector3(x, 0, z), PI / 2)
			if rng.randf() < 0.45:
				_model("debris", Vector3(side * rng.randf_range(8, 14), 0, z + 2), rng.randf() * TAU)

func _make_graves() -> void:
	var stones := ["gravestone-round", "gravestone-broken", "gravestone-cross", "gravestone-decorative", "gravestone-bevel", "grave"]
	for z in range(3, -87, -5):
		for x in [-27, -22, -17, -12, 12, 17, 22, 27]:
			if rng.randf() < 0.78:
				_model(stones[rng.randi_range(0, stones.size() - 1)], Vector3(x + rng.randf_range(-0.9, 0.9), 0, z + rng.randf_range(-1, 1)), rng.randf_range(-0.25, 0.25))
			if rng.randf() < 0.15:
				_model("cross-wood", Vector3(x + 1.6, 0, z), rng.randf_range(-0.4, 0.4))
	for z in [-6, -24, -48, -73]:
		for side in [-1, 1]:
			_model("pine-crooked", Vector3(side * 25, 0, z), rng.randf() * TAU, rng.randf_range(1.0, 1.35))
	for z in [-14, -38, -62, -81]:
		_model("rocks", Vector3(-19, 0, z), rng.randf() * TAU)
		_model("rocks-tall", Vector3(20, 0, z + 2), rng.randf() * TAU)

func _make_landmarks() -> void:
	_model("crypt-large", Vector3(-19, 0, -35), PI / 2, 1.4)
	_model("crypt-large-roof", Vector3(-19, 0, -35), PI / 2, 1.4)
	_model("crypt", Vector3(20, 0, -57), -PI / 2, 1.3)
	_model("altar-stone", Vector3(0, 0, -82), PI, 2.2)
	_model("coffin-old", Vector3(0, 0, -78), 0.3, 1.5)
	for x in [-7, 7]:
		_model("pillar-obelisk", Vector3(x, 0, -79), 0, 1.6)
		_model("fire-basket", Vector3(x, 0, -76))
	for z in [-20, -51, -70]:
		_model("coffin", Vector3(14 if z == -51 else -14, 0, z), rng.randf() * TAU)

func _make_lights() -> void:
	for z in [4, -13, -31, -50, -68, -82]:
		var x := -5.2 if z % 2 == 0 else 5.2
		_model("lightpost-single", Vector3(x, 0, z))
		var light := OmniLight3D.new()
		light.position = Vector3(x, 2.8, z)
		light.light_color = Color(1.0, 0.26, 0.08) if z < -66 else Color(0.37, 0.65, 0.82)
		light.light_energy = 1.0
		light.omni_range = 13.0
		light.shadow_enabled = true
		add_child(light)
		flicker_lights.append(light)
	for x in [-7.0, 7.0]:
		var flame := OmniLight3D.new()
		flame.position = Vector3(x, 1.8, -76)
		flame.light_color = Color(1.0, 0.13, 0.025)
		flame.light_energy = 1.8
		flame.omni_range = 10.0
		add_child(flame)
