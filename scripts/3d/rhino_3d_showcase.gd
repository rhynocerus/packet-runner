extends Node3D

const RHINO_SCENE := preload("res://scenes/3d/rhino/rhino_3d.tscn")

var rhino: Node3D

func _ready() -> void:
	_build_environment()
	_build_rhino()

func _process(delta: float) -> void:
	if is_instance_valid(rhino):
		rhino.rotation.y += delta * 0.55

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.03, 0.05, 0.08, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.70, 1.0)
	environment.ambient_light_energy = 1.2
	env.environment = environment
	add_child(env)

	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14.0, 14.0)
	floor.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.06, 0.10, 0.12, 1.0)
	floor_mat.roughness = 0.92
	floor.material_override = floor_mat
	add_child(floor)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sun.light_energy = 2.1
	sun.shadow_enabled = true
	add_child(sun)

	var rim := OmniLight3D.new()
	rim.position = Vector3(0.0, 2.0, 2.0)
	rim.light_color = Color(0.0, 0.90, 1.0, 1.0)
	rim.light_energy = 2.5
	add_child(rim)

	var camera := Camera3D.new()
	camera.current = true
	camera.position = Vector3(0.0, 1.6, 4.8)
	camera.rotation_degrees = Vector3(-10.0, 0.0, 0.0)
	add_child(camera)

func _build_rhino() -> void:
	rhino = RHINO_SCENE.instantiate()
	rhino.name = "Rhino3D"
	rhino.position = Vector3(0.0, 0.0, 0.0)
	add_child(rhino)
