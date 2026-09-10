class_name Rhino3D
extends Node3D

# Packet Runner // Rhino 3D Prototype v0.2
# Organic Cyber Armor

const RHINO_SKIN := Color(0.55, 0.58, 0.62, 1.0)
const RHINO_LIGHT := Color(0.68, 0.70, 0.73, 1.0)
const RHINO_DARK := Color(0.27, 0.30, 0.34, 1.0)

const ARMOR_DARK := Color(0.045, 0.085, 0.11, 1.0)
const ARMOR_MID := Color(0.16, 0.22, 0.27, 1.0)
const ARMOR_LIGHT := Color(0.34, 0.41, 0.47, 1.0)

const CYAN := Color(0.0, 0.90, 1.0, 1.0)
const CYAN_SOFT := Color(0.16, 0.78, 0.84, 1.0)
const EYE_GLOW := Color(0.55, 0.96, 1.0, 1.0)

const HORN := Color(0.94, 0.88, 0.72, 1.0)

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

	# Respiración / peso corporal.
	if is_instance_valid(body_root):
		body_root.position.y = (
			1.10
			+ sin(elapsed * 2.15) * 0.018
		)
		body_root.rotation.z = deg_to_rad(
			sin(elapsed * 1.10) * 0.55
		)

	if is_instance_valid(head_pivot):
		head_pivot.rotation.x = deg_to_rad(
			sin(elapsed * 1.65) * 1.4
		)
		head_pivot.rotation.y = deg_to_rad(
			sin(elapsed * 0.85) * 2.4
		)

	# Idle muy sutil. No queremos que parezca corriendo parado.
	_animate_limb(arm_l, 0.0, 2.5)
	_animate_limb(arm_r, PI, 2.5)
	_animate_limb(leg_l, PI, 1.2)
	_animate_limb(leg_r, 0.0, 1.2)


func _animate_limb(
	node: Node3D,
	phase: float,
	amount_deg: float
) -> void:
	if not is_instance_valid(node):
		return

	node.rotation.x = deg_to_rad(
		sin(elapsed * 1.8 + phase) * amount_deg
	)


func _build_model() -> void:
	if get_node_or_null("BodyRoot"):
		return

	var skin := _make_material(
		RHINO_SKIN,
		0.04,
		0.88
	)

	var skin_light := _make_material(
		RHINO_LIGHT,
		0.03,
		0.86
	)

	var skin_dark := _make_material(
		RHINO_DARK,
		0.07,
		0.82
	)

	var armor_dark := _make_material(
		ARMOR_DARK,
		0.48,
		0.35
	)

	var armor_mid := _make_material(
		ARMOR_MID,
		0.42,
		0.38
	)

	var armor_light := _make_material(
		ARMOR_LIGHT,
		0.36,
		0.42
	)

	var glow := _make_material(
		CYAN_SOFT,
		0.25,
		0.20,
		CYAN
	)

	var eye := _make_material(
		Color(0.78, 0.94, 1.0, 1.0),
		0.05,
		0.16,
		EYE_GLOW
	)

	var horn := _make_material(
		HORN,
		0.01,
		0.92
	)

	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	body_root.position = Vector3(0.0, 1.10, 0.0)
	add_child(body_root)

	# =========================================================
	# CUERPO ORGÁNICO
	# =========================================================

	# Gran masa de hombros. Da al Rino peso y potencia.
	_add_part(
		body_root,
		"ShoulderMass",
		_sphere(),
		skin,
		Vector3(0.0, 0.22, 0.02),
		Vector3.ZERO,
		Vector3(0.72, 0.64, 0.63)
	)

	# Torso inferior ligeramente más estrecho.
	_add_part(
		body_root,
		"LowerTorso",
		_capsule(0.42, 0.98),
		skin_dark,
		Vector3(0.0, -0.12, -0.02),
		Vector3.ZERO,
		Vector3(1.03, 1.0, 0.94)
	)

	# Pecho superior para formar el cuello/joroba característica.
	_add_part(
		body_root,
		"UpperBackMass",
		_sphere(),
		skin_light,
		Vector3(0.0, 0.40, -0.10),
		Vector3.ZERO,
		Vector3(0.57, 0.43, 0.47)
	)

	# =========================================================
	# ARMADURA DEL TORSO
	# =========================================================

	_add_part(
		body_root,
		"ChestArmor",
		_sphere(),
		armor_dark,
		Vector3(0.0, 0.19, 0.43),
		Vector3.ZERO,
		Vector3(0.54, 0.42, 0.12)
	)

	_add_box(
		body_root,
		"ChestCore",
		Vector3(0.25, 0.27, 0.045),
		glow,
		Vector3(0.0, 0.18, 0.555)
	)

	# Dos líneas laterales dan lectura de "P / data lanes".
	_add_box(
		body_root,
		"ChestLaneL",
		Vector3(0.055, 0.30, 0.035),
		glow,
		Vector3(-0.18, 0.18, 0.545),
		Vector3(0.0, 0.0, -8.0)
	)

	_add_box(
		body_root,
		"ChestLaneR",
		Vector3(0.055, 0.24, 0.035),
		glow,
		Vector3(0.18, 0.15, 0.545),
		Vector3(0.0, 0.0, 8.0)
	)

	_add_part(
		body_root,
		"PelvisArmor",
		_sphere(),
		armor_mid,
		Vector3(0.0, -0.36, 0.16),
		Vector3.ZERO,
		Vector3(0.42, 0.22, 0.23)
	)

	# Mochila compacta, no una caja enorme.
	_add_part(
		body_root,
		"BackModule",
		_capsule(0.18, 0.48),
		armor_mid,
		Vector3(0.0, 0.13, -0.52),
		Vector3.ZERO,
		Vector3(1.0, 1.0, 0.72)
	)

	_add_box(
		body_root,
		"BackEnergy",
		Vector3(0.16, 0.26, 0.035),
		glow,
		Vector3(0.0, 0.14, -0.665)
	)

	# =========================================================
	# CUELLO
	# =========================================================

	_add_part(
		body_root,
		"Neck",
		_capsule(0.30, 0.67),
		skin,
		Vector3(0.0, 0.45, 0.32),
		Vector3(68.0, 0.0, 0.0),
		Vector3(1.15, 1.0, 1.10)
	)

	# =========================================================
	# CABEZA
	# =========================================================

	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.60, 0.61)
	body_root.add_child(head_pivot)

	_add_part(
		head_pivot,
		"Head",
		_sphere(),
		skin,
		Vector3(0.0, 0.04, 0.06),
		Vector3.ZERO,
		Vector3(0.43, 0.36, 0.50)
	)

	# Mejillas para romper la esfera perfecta.
	_add_part(
		head_pivot,
		"CheekL",
		_sphere(),
		skin_dark,
		Vector3(-0.20, -0.015, 0.08),
		Vector3.ZERO,
		Vector3(0.17, 0.20, 0.24)
	)

	_add_part(
		head_pivot,
		"CheekR",
		_sphere(),
		skin_dark,
		Vector3(0.20, -0.015, 0.08),
		Vector3.ZERO,
		Vector3(0.17, 0.20, 0.24)
	)

	# Hocico horizontal grande.
	_add_part(
		head_pivot,
		"Snout",
		_capsule(0.19, 0.70),
		skin_dark,
		Vector3(0.0, -0.08, 0.38),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.12, 1.0, 0.92)
	)

	# Punta del hocico más ancha.
	_add_part(
		head_pivot,
		"Muzzle",
		_sphere(),
		skin_light,
		Vector3(0.0, -0.10, 0.67),
		Vector3.ZERO,
		Vector3(0.30, 0.19, 0.24)
	)

	# Narinas.
	_add_part(
		head_pivot,
		"NostrilL",
		_sphere(),
		armor_dark,
		Vector3(-0.105, -0.10, 0.865),
		Vector3.ZERO,
		Vector3(0.036, 0.027, 0.018)
	)

	_add_part(
		head_pivot,
		"NostrilR",
		_sphere(),
		armor_dark,
		Vector3(0.105, -0.10, 0.865),
		Vector3.ZERO,
		Vector3(0.036, 0.027, 0.018)
	)

	# =========================================================
	# CUERNOS
	# =========================================================

	# El cuerno principal es deliberadamente grande.
	_add_part(
		head_pivot,
		"MainHorn",
		_cone(0.025, 0.115, 0.58),
		horn,
		Vector3(0.0, 0.14, 0.76),
		Vector3(67.0, 0.0, 0.0)
	)

	_add_part(
		head_pivot,
		"SecondHorn",
		_cone(0.02, 0.075, 0.30),
		horn,
		Vector3(0.0, 0.25, 0.49),
		Vector3(58.0, 0.0, 0.0)
	)

	# =========================================================
	# OJOS / CEJAS / OREJAS
	# =========================================================

	_add_part(
		head_pivot,
		"LeftEye",
		_sphere(),
		eye,
		Vector3(-0.155, 0.105, 0.425),
		Vector3.ZERO,
		Vector3(0.060, 0.045, 0.035)
	)

	_add_part(
		head_pivot,
		"RightEye",
		_sphere(),
		eye,
		Vector3(0.155, 0.105, 0.425),
		Vector3.ZERO,
		Vector3(0.060, 0.045, 0.035)
	)

	_add_box(
		head_pivot,
		"BrowL",
		Vector3(0.17, 0.065, 0.08),
		armor_dark,
		Vector3(-0.15, 0.19, 0.405),
		Vector3(0.0, 0.0, -9.0)
	)

	_add_box(
		head_pivot,
		"BrowR",
		Vector3(0.17, 0.065, 0.08),
		armor_dark,
		Vector3(0.15, 0.19, 0.405),
		Vector3(0.0, 0.0, 9.0)
	)

	_add_part(
		head_pivot,
		"EarL",
		_cone(0.025, 0.095, 0.25),
		skin_dark,
		Vector3(-0.24, 0.35, -0.02),
		Vector3(0.0, 0.0, -25.0)
	)

	_add_part(
		head_pivot,
		"EarR",
		_cone(0.025, 0.095, 0.25),
		skin_dark,
		Vector3(0.24, 0.35, -0.02),
		Vector3(0.0, 0.0, 25.0)
	)

	# Placa tecnológica facial pequeña.
	_add_box(
		head_pivot,
		"TempleGlowL",
		Vector3(0.07, 0.12, 0.04),
		glow,
		Vector3(-0.275, 0.10, 0.22)
	)

	_add_box(
		head_pivot,
		"TempleGlowR",
		Vector3(0.07, 0.12, 0.04),
		glow,
		Vector3(0.275, 0.10, 0.22)
	)

	# =========================================================
	# BRAZOS
	# =========================================================

	arm_l = _build_arm(
		"ArmL",
		Vector3(-0.54, 0.18, 0.05),
		-1.0,
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	arm_r = _build_arm(
		"ArmR",
		Vector3(0.54, 0.18, 0.05),
		1.0,
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	# =========================================================
	# PIERNAS
	# =========================================================

	leg_l = _build_leg(
		"LegL",
		Vector3(-0.245, -0.42, 0.02),
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	leg_r = _build_leg(
		"LegR",
		Vector3(0.245, -0.42, 0.02),
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	# =========================================================
	# COLA
	# =========================================================

	_add_part(
		body_root,
		"Tail",
		_capsule(0.055, 0.40),
		skin_dark,
		Vector3(0.0, -0.15, -0.61),
		Vector3(78.0, 0.0, 0.0),
		Vector3(0.80, 1.0, 0.80)
	)

	_add_part(
		body_root,
		"TailTip",
		_sphere(),
		skin_dark,
		Vector3(0.0, -0.35, -0.70),
		Vector3.ZERO,
		Vector3(0.075, 0.10, 0.075)
	)


func _build_arm(
	name: String,
	origin: Vector3,
	side: float,
	skin: Material,
	skin_dark: Material,
	armor: Material,
	armor_dark: Material,
	glow: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = origin
	body_root.add_child(pivot)

	_add_part(
		pivot,
		"Shoulder",
		_sphere(),
		skin,
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3(0.22, 0.24, 0.23)
	)

	_add_part(
		pivot,
		"ShoulderArmor",
		_sphere(),
		armor,
		Vector3(side * 0.055, 0.035, 0.035),
		Vector3.ZERO,
		Vector3(0.23, 0.15, 0.20)
	)

	_add_part(
		pivot,
		"UpperArm",
		_capsule(0.115, 0.46),
		skin_dark,
		Vector3(0.0, -0.27, 0.0)
	)

	_add_part(
		pivot,
		"Elbow",
		_sphere(),
		armor_dark,
		Vector3(0.0, -0.49, 0.015),
		Vector3.ZERO,
		Vector3(0.135, 0.135, 0.135)
	)

	_add_part(
		pivot,
		"ForeArm",
		_capsule(0.105, 0.42),
		armor,
		Vector3(0.0, -0.68, 0.025)
	)

	_add_part(
		pivot,
		"Hand",
		_sphere(),
		skin_dark,
		Vector3(0.0, -0.91, 0.07),
		Vector3.ZERO,
		Vector3(0.14, 0.12, 0.16)
	)

	_add_box(
		pivot,
		"WristGlow",
		Vector3(0.19, 0.055, 0.17),
		glow,
		Vector3(0.0, -0.80, 0.045)
	)

	return pivot


func _build_leg(
	name: String,
	origin: Vector3,
	skin: Material,
	skin_dark: Material,
	armor: Material,
	armor_dark: Material,
	glow: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = origin
	body_root.add_child(pivot)

	_add_part(
		pivot,
		"Thigh",
		_capsule(0.17, 0.54),
		skin,
		Vector3(0.0, -0.28, 0.0)
	)

	_add_part(
		pivot,
		"Knee",
		_sphere(),
		armor_dark,
		Vector3(0.0, -0.55, 0.04),
		Vector3.ZERO,
		Vector3(0.17, 0.15, 0.18)
	)

	_add_part(
		pivot,
		"Shin",
		_capsule(0.135, 0.47),
		skin_dark,
		Vector3(0.0, -0.77, 0.015)
	)

	_add_part(
		pivot,
		"ShinArmor",
		_capsule(0.105, 0.32),
		armor,
		Vector3(0.0, -0.76, 0.115),
		Vector3.ZERO,
		Vector3(1.0, 1.0, 0.55)
	)

	_add_box(
		pivot,
		"ShinGlow",
		Vector3(0.075, 0.19, 0.025),
		glow,
		Vector3(0.0, -0.76, 0.205)
	)

	# Pie ancho, redondeado y pesado.
	_add_part(
		pivot,
		"Foot",
		_sphere(),
		skin_dark,
		Vector3(0.0, -1.04, 0.10),
		Vector3.ZERO,
		Vector3(0.22, 0.13, 0.31)
	)

	_add_part(
		pivot,
		"BootArmor",
		_sphere(),
		armor_dark,
		Vector3(0.0, -1.03, 0.16),
		Vector3.ZERO,
		Vector3(0.21, 0.105, 0.27)
	)

	_add_box(
		pivot,
		"BootGlow",
		Vector3(0.19, 0.035, 0.12),
		glow,
		Vector3(0.0, -1.035, 0.38)
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

	if (
		emission.r > 0.0
		or emission.g > 0.0
		or emission.b > 0.0
	):
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.45

	return material


func _sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh


func _capsule(
	radius: float,
	height: float
) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 8
	return mesh


func _cone(
	top_radius: float,
	bottom_radius: float,
	height: float
) -> CylinderMesh:
	var mesh := CylinderMesh.new()

	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 2

	return mesh


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
		rotation_deg
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
