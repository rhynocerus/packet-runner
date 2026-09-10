extends Node3D

const RHINO_SCENE := preload(
	"res://scenes/3d/rhino/rhino_3d.tscn"
)

const TRACK_SPEED := 6.2
const TRACK_WRAP := 11.0

const INSPECT_YAW_SPEED := 1.65
const INSPECT_PITCH_SPEED := 0.85
const INSPECT_MAX_PITCH := 0.38

var inspect_pitch: float = 0.0

var rhino: Node3D
var lane_markers: Array[MeshInstance3D] = []


func _ready() -> void:
	_build_environment()
	_build_rhino()


func _process(delta: float) -> void:
	# La pista viene hacia nosotros mientras el Rino permanece
	# centrado. Es el mismo truco visual de muchos runners.
	for marker in lane_markers:
		marker.position.z += TRACK_SPEED * delta

		if marker.position.z > 5.0:
			marker.position.z -= TRACK_WRAP

	_process_inspection(delta)


func _process_inspection(delta: float) -> void:
	if not is_instance_valid(rhino):
		return

	# Flechas izquierda/derecha:
	# rotación completa alrededor del eje vertical.
	if Input.is_key_pressed(KEY_LEFT):
		rhino.rotation.y += INSPECT_YAW_SPEED * delta

	if Input.is_key_pressed(KEY_RIGHT):
		rhino.rotation.y -= INSPECT_YAW_SPEED * delta

	# Flechas arriba/abajo:
	# inclinación limitada para inspeccionar cabeza, espalda y botas.
	if Input.is_key_pressed(KEY_UP):
		inspect_pitch += INSPECT_PITCH_SPEED * delta

	if Input.is_key_pressed(KEY_DOWN):
		inspect_pitch -= INSPECT_PITCH_SPEED * delta

	inspect_pitch = clampf(
		inspect_pitch,
		-INSPECT_MAX_PITCH,
		INSPECT_MAX_PITCH
	)

	rhino.rotation.x = inspect_pitch


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(
		0.018,
		0.035,
		0.055,
		1.0
	)

	environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	environment.ambient_light_color = Color(
		0.42,
		0.52,
		0.62,
		1.0
	)

	environment.ambient_light_energy = 1.25

	env.environment = environment
	add_child(env)

	# ---------------------------------------------------------
	# SUELO
	# ---------------------------------------------------------

	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()

	plane.size = Vector2(14.0, 14.0)
	floor.mesh = plane

	var floor_mat := StandardMaterial3D.new()

	floor_mat.albedo_color = Color(
		0.035,
		0.075,
		0.085,
		1.0
	)

	floor_mat.roughness = 0.88
	floor.material_override = floor_mat

	add_child(floor)

	# ---------------------------------------------------------
	# CARRILES DE DATOS
	# ---------------------------------------------------------

	var marker_mat := StandardMaterial3D.new()

	marker_mat.albedo_color = Color(
		0.0,
		0.72,
		0.82,
		1.0
	)

	marker_mat.emission_enabled = true
	marker_mat.emission = Color(
		0.0,
		0.90,
		1.0,
		1.0
	)

	marker_mat.emission_energy_multiplier = 1.6

	for i in range(11):
		for side in [-0.72, 0.72]:
			var marker := MeshInstance3D.new()
			var box := BoxMesh.new()

			box.size = Vector3(
				0.055,
				0.018,
				0.62
			)

			marker.mesh = box
			marker.material_override = marker_mat

			marker.position = Vector3(
				side,
				0.018,
				-5.0 + float(i)
			)

			add_child(marker)
			lane_markers.append(marker)

	# ---------------------------------------------------------
	# LUCES
	# ---------------------------------------------------------

	var sun := DirectionalLight3D.new()

	sun.rotation_degrees = Vector3(
		-42.0,
		35.0,
		0.0
	)

	sun.light_energy = 2.0
	sun.shadow_enabled = true

	add_child(sun)

	var rim := OmniLight3D.new()

	rim.position = Vector3(
		-1.4,
		2.0,
		2.2
	)

	rim.light_color = Color(
		0.0,
		0.90,
		1.0,
		1.0
	)

	rim.light_energy = 2.8
	rim.omni_range = 6.0

	add_child(rim)

	# ---------------------------------------------------------
	# CÁMARA 3/4
	# ---------------------------------------------------------

	var camera := Camera3D.new()

	camera.position = Vector3(
		2.15,
		1.62,
		3.65
	)

	add_child(camera)

	camera.look_at(
		Vector3(0.0, 0.98, 0.0),
		Vector3.UP
	)

	camera.current = true


func _build_rhino() -> void:
	rhino = RHINO_SCENE.instantiate()

	rhino.name = "Rhino3D"
	rhino.position = Vector3.ZERO

	add_child(rhino)

	if rhino.has_method("set_running"):
		rhino.set_running(true)
