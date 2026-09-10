class_name Rhino3D
extends Node3D

const RHINO_SKIN := Color(0.66, 0.68, 0.72, 1.0)
const RHINO_DARK := Color(0.34, 0.36, 0.41, 1.0)

const ARMOR_DARK := Color(0.08, 0.14, 0.18, 1.0)
const ARMOR_MID := Color(0.23, 0.29, 0.34, 1.0)
const ARMOR_LIGHT := Color(0.44, 0.50, 0.56, 1.0)

const CYAN_GLOW := Color(0.0, 0.90, 1.0, 1.0)
const CYAN_SOFT := Color(0.22, 0.92, 0.98, 1.0)
const EYE_GLOW := Color(0.72, 0.95, 1.0, 1.0)

var elapsed := 0.0

var body_root: Node3D
var head_pivot: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D

func _ready() -> void:
	_build_model()

func _process(delta: float) -> void:
	elapsed += delta

	if is_instance_valid(body_root):
		body_root.position.y = 0.92 + sin(elapsed * 3.0) * 0.04
		body_root.rotation.z = deg_to_rad(sin(elapsed * 1.5) * 1.2)

	if is_instance_valid(head_pivot):
		head_pivot.rotation.x = deg_to_rad(sin(elapsed * 2.0) * 2.0)
		head_pivot.rotation.y = deg_to_rad(sin(elapsed * 1.15) * 3.0)

	_animate_limb(arm_l, 0.0, 10.0)
	_animate_limb(arm_r, PI, 10.0)
	_animate_limb(leg_l, PI, 14.0)
	_animate_limb(leg_r, 0.0, 14.0)

func _animate_limb(node: Node3D, phase: float, amount_deg: float) -> void:
	if not is_instance_valid(node):
		return

	node.rotation.x = deg_to_rad(sin(elapsed * 4.2 + phase) * amount_deg)

func _build_model() -> void:
	if get_node_or_null("BodyRoot"):
		return

	var mat_skin := _make_material(RHINO_SKIN, 0.05, 0.82)
	var mat_skin_dark := _make_material(RHINO_DARK, 0.08, 0.82)
	var mat_armor_dark := _make_material(ARMOR_DARK, 0.35, 0.45)
	var mat_armor_mid := _make_material(ARMOR_MID, 0.42, 0.40)
	var mat_armor_light := _make_material(ARMOR_LIGHT, 0.40, 0.36)
	var mat_glow := _make_material(CYAN_SOFT, 0.20, 0.22, CYAN_GLOW)
	var mat_eye := _make_material(Color(0.88, 0.94, 1.0, 1.0), 0.05, 0.18, EYE_GLOW)
	var mat_horn := _make_material(Color(0.95, 0.91, 0.80, 1.0), 0.02, 0.88)

	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	body_root.position = Vector3(0.0, 0.92, 0.0)
	add_child(body_root)

	# =========================================================
	# TORSO
	# =========================================================
	_add_part(
		body_root,
		"Torso",
		SphereMesh.new(),
		mat_skin,
		Vector3(0.0, 0.20, 0.0),
		Vector3.ZERO,
		Vector3(0.82, 0.72, 0.98)
	)

	_add_box(
		body_root,
		"ChestArmor",
		Vector3(0.66, 0.62, 0.28),
		mat_armor_dark,
		Vector3(0.0, 0.18, 0.42)
	)

	_add_box(
		body_root,
		"ChestCore",
		Vector3(0.28, 0.30, 0.06),
		mat_glow,
		Vector3(0.0, 0.18, 0.58)
	)

	_add_box(
		body_root,
		"PelvisArmor",
		Vector3(0.52, 0.30, 0.26),
		mat_armor_mid,
		Vector3(0.0, -0.18, 0.18)
	)

	_add_box(
		body_root,
		"BackPack",
		Vector3(0.42, 0.48, 0.20),
		mat_armor_mid,
		Vector3(0.0, 0.12, -0.44)
	)

	# =========================================================
	# CABEZA
	# =========================================================
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.34, 0.58)
	body_root.add_child(head_pivot)

	_add_part(
		head_pivot,
		"Head",
		SphereMesh.new(),
		mat_skin,
		Vector3(0.0, 0.14, 0.0),
		Vector3.ZERO,
		Vector3(0.48, 0.40, 0.56)
	)

	_add_box(
		head_pivot,
		"Snout",
		Vector3(0.34, 0.20, 0.46),
		mat_skin_dark,
		Vector3(0.0, 0.02, 0.28)
	)

	_add_box(
		head_pivot,
		"FaceArmor",
		Vector3(0.30, 0.18, 0.18),
		mat_armor_dark,
		Vector3(0.0, 0.12, 0.46)
	)

	_add_part(
		head_pivot,
		"MainHorn",
		_cylinder(0.02, 0.10, 0.44),
		mat_horn,
		Vector3(0.0, 0.18, 0.60),
		Vector3(90.0, 0.0, 0.0),
		Vector3.ONE
	)

	_add_part(
		head_pivot,
		"SmallHorn",
		_cylinder(0.02, 0.06, 0.24),
		mat_horn,
		Vector3(0.0, 0.03, 0.53),
		Vector3(90.0, 0.0, 0.0),
		Vector3.ONE
	)

	_add_box(
		head_pivot,
		"LeftEar",
		Vector3(0.08, 0.16, 0.05),
		mat_skin_dark,
		Vector3(-0.18, 0.34, -0.05),
		Vector3(18.0, 0.0, -24.0)
	)

	_add_box(
		head_pivot,
		"RightEar",
		Vector3(0.08, 0.16, 0.05),
		mat_skin_dark,
		Vector3(0.18, 0.34, -0.05),
		Vector3(18.0, 0.0, 24.0)
	)

	_add_part(
		head_pivot,
		"LeftEye",
		SphereMesh.new(),
		mat_eye,
		Vector3(-0.12, 0.16, 0.34),
		Vector3.ZERO,
		Vector3(0.06, 0.06, 0.06)
	)

	_add_part(
		head_pivot,
		"RightEye",
		SphereMesh.new(),
		mat_eye,
		Vector3(0.12, 0.16, 0.34),
		Vector3.ZERO,
		Vector3(0.06, 0.06, 0.06)
	)

	# =========================================================
	# BRAZOS
	# =========================================================
	arm_l = _build_arm(
		"ArmL",
		Vector3(-0.46, 0.16, 0.12),
		1.0,
		mat_armor_light,
		mat_armor_dark,
		mat_glow
	)

	arm_r = _build_arm(
		"ArmR",
		Vector3(0.46, 0.16, 0.12),
		-1.0,
		mat_armor_light,
		mat_armor_dark,
		mat_glow
	)

	# =========================================================
	# PIERNAS
	# =========================================================
	leg_l = _build_leg(
		"LegL",
		Vector3(-0.22, -0.30, 0.08),
		mat_armor_light,
		mat_armor_dark,
		mat_glow
	)

	leg_r = _build_leg(
		"LegR",
		Vector3(0.22, -0.30, 0.08),
		mat_armor_light,
		mat_armor_dark,
		mat_glow
	)

	# =========================================================
	# COLA
	# =========================================================
	_add_part(
		body_root,
		"Tail",
		_cylinder(0.03, 0.05, 0.34),
		mat_skin_dark,
		Vector3(0.0, -0.02, -0.62),
		Vector3(86.0, 0.0, 0.0),
		Vector3.ONE
	)

func _build_arm(
	name: String,
	origin: Vector3,
	side: float,
	mat_main: Material,
	mat_dark: Material,
	mat_glow: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = origin
	body_root.add_child(pivot)

	_add_part(
		pivot,
		"Shoulder",
		SphereMesh.new(),
		mat_main,
		Vector3(0.0, 0.0, 0.0),
		Vector3.ZERO,
		Vector3(0.18, 0.18, 0.18)
	)

	_add_part(
		pivot,
		"UpperArm",
		_cylinder(0.10, 0.10, 0.40),
		mat_dark,
		Vector3(0.0, -0.22, 0.0),
		Vector3.ZERO,
		Vector3.ONE
	)

	_add_part(
		pivot,
		"ForeArm",
		_cylinder(0.09, 0.08, 0.34),
		mat_main,
		Vector3(0.0, -0.52, 0.02),
		Vector3.ZERO,
		Vector3.ONE
	)

	_add_part(
		pivot,
		"Hand",
		SphereMesh.new(),
		mat_dark,
		Vector3(0.0, -0.76, 0.08),
		Vector3.ZERO,
		Vector3(0.11, 0.11, 0.11)
	)

	_add_box(
		pivot,
		"WristBand",
		Vector3(0.18, 0.06, 0.18),
		mat_glow,
		Vector3(0.0, -0.66, 0.06)
	)

	_add_box(
		pivot,
		"ShoulderPlate",
		Vector3(0.26, 0.16, 0.24),
		mat_glow,
		Vector3(side * 0.04, 0.02, 0.12),
		Vector3(0.0, 0.0, side * 10.0)
	)

	return pivot

func _build_leg(
	name: String,
	origin: Vector3,
	mat_main: Material,
	mat_dark: Material,
	mat_glow: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = origin
	body_root.add_child(pivot)

	_add_part(
		pivot,
		"Thigh",
		_cylinder(0.13, 0.11, 0.34),
		mat_main,
		Vector3(0.0, -0.18, 0.0),
		Vector3.ZERO,
		Vector3.ONE
	)

	_add_part(
		pivot,
		"Shin",
		_cylinder(0.11, 0.09, 0.32),
		mat_dark,
		Vector3(0.0, -0.46, 0.02),
		Vector3.ZERO,
		Vector3.ONE
	)

	_add_box(
		pivot,
		"ShinPlate",
		Vector3(0.18, 0.22, 0.10),
		mat_glow,
		Vector3(0.0, -0.45, 0.15)
	)

	_add_box(
		pivot,
		"Boot",
		Vector3(0.26, 0.16, 0.42),
		mat_main,
		Vector3(0.0, -0.74, 0.10)
	)

	_add_box(
		pivot,
		"BootGlow",
		Vector3(0.20, 0.05, 0.18),
		mat_glow,
		Vector3(0.0, -0.77, 0.26)
	)

	return pivot

func _make_material(
	albedo: Color,
	metallic: float,
	roughness: float,
	emission: Color = Color(0.0, 0.0, 0.0, 1.0)
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness

	if emission.r > 0.0 or emission.g > 0.0 or emission.b > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.5

	return material

func _add_box(
	parent: Node3D,
	name: String,
	size: Vector3,
	material: Material,
	position: Vector3,
	rotation_deg: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size

	return _add_part(
		parent,
		name,
		box,
		material,
		position,
		rotation_deg,
		Vector3.ONE
	)

func _add_part(
	parent: Node3D,
	name: String,
	mesh: Mesh,
	material: Material,
	position: Vector3,
	rotation_deg: Vector3 = Vector3.ZERO,
	scale_vec: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = mesh
	part.material_override = material
	part.position = position
	part.rotation_degrees = rotation_deg
	part.scale = scale_vec
	parent.add_child(part)
	return part

func _cylinder(
	top_radius: float,
	bottom_radius: float,
	height: float
) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 2
	return mesh
