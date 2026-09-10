class_name Rhino3D
extends Node3D

# Packet Runner // Rhino 3D Prototype v0.8
# Sculpted Cyber Rhino

const RHINO_SKIN := Color(0.43, 0.47, 0.52, 1.0)
const RHINO_LIGHT := Color(0.59, 0.62, 0.67, 1.0)
const RHINO_DARK := Color(0.23, 0.26, 0.30, 1.0)

const ARMOR_DARK := Color(0.025, 0.050, 0.075, 1.0)
const ARMOR_MID := Color(0.09, 0.14, 0.18, 1.0)
const ARMOR_LIGHT := Color(0.20, 0.27, 0.32, 1.0)

const CYAN := Color(0.0, 0.90, 1.0, 1.0)
const CYAN_SOFT := Color(0.08, 0.72, 0.80, 1.0)
const EYE_GLOW := Color(0.00, 0.62, 1.00, 1.0)

const HORN := Color(0.94, 0.88, 0.72, 1.0)

var elapsed := 0.0

var body_root: Node3D
var head_pivot: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D

var running: bool = false
var run_cycle: float = 0.0

const RUN_CYCLE_SPEED := 8.2


func _ready() -> void:
	_build_model()


func _process(delta: float) -> void:
	elapsed += delta

	if running:
		_process_running(delta)
	else:
		_process_idle()


func set_running(value: bool) -> void:
	running = value

	if not running:
		run_cycle = 0.0


func _process_idle() -> void:
	if is_instance_valid(body_root):
		body_root.position.y = (
			1.62
			+ sin(elapsed * 2.15) * 0.018
		)

		body_root.rotation.x = 0.0

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

	_animate_limb(arm_l, 0.0, 2.5)
	_animate_limb(arm_r, PI, 2.5)
	_animate_limb(leg_l, PI, 1.2)
	_animate_limb(leg_r, 0.0, 1.2)


func _process_running(delta: float) -> void:
	run_cycle += delta * RUN_CYCLE_SPEED

	var stride := sin(run_cycle)
	var impact: float = absf(sin(run_cycle * 2.0))

	if is_instance_valid(body_root):
		# Inclinación atlética hacia delante.
		body_root.rotation.x = deg_to_rad(
			8.0 + impact * 1.1
		)

		# Rebote vertical del peso.
		body_root.position.y = (
			1.62
			+ impact * 0.055
		)

		# Ligero balanceo de hombros.
		body_root.rotation.z = deg_to_rad(
			stride * 1.8
		)

	if is_instance_valid(head_pivot):
		# La cabeza absorbe el impacto en sentido contrario.
		head_pivot.rotation.x = deg_to_rad(
			-5.0
			+ sin(run_cycle * 2.0 + 0.4) * 2.2
		)

		head_pivot.rotation.y = deg_to_rad(
			sin(run_cycle * 0.5) * 0.7
		)

	if is_instance_valid(arm_l):
		arm_l.rotation.x = deg_to_rad(
			stride * 34.0
		)

	if is_instance_valid(arm_r):
		arm_r.rotation.x = deg_to_rad(
			-stride * 34.0
		)

	if is_instance_valid(leg_l):
		leg_l.rotation.x = deg_to_rad(
			-stride * 29.0
		)

	if is_instance_valid(leg_r):
		leg_r.rotation.x = deg_to_rad(
			stride * 29.0
		)


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

	var eye_white := _make_material(
		Color(0.97, 0.985, 1.0, 1.0),
		0.0,
		0.30
	)

	var eye := _make_material(
		Color(0.02, 0.48, 0.92, 1.0),
		0.04,
		0.16,
		EYE_GLOW
	)

	var eye_pupil := _make_material(
		Color(0.004, 0.008, 0.012, 1.0),
		0.0,
		0.38
	)

	var horn := _make_material(
		HORN,
		0.01,
		0.92
	)

	var ear_inner := _make_material(
		Color(0.70, 0.36, 0.40, 1.0),
		0.02,
		0.88
	)

	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	body_root.position = Vector3(0.0, 1.62, 0.0)
	add_child(body_root)

	# =========================================================
	# CUERPO ESCULPIDO
	# =========================================================

	# Línea continua de hombros.
	# La cápsula horizontal evita el efecto de "bolas pegadas".
	_add_part(
		body_root,
		"ShoulderLine",
		_capsule(0.32, 1.18),
		skin,
		Vector3(0.0, 0.24, 0.02),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 1.0, 0.96)
	)

	# Caja torácica vertical, compacta y pesada.
	_add_part(
		body_root,
		"RibCage",
		_capsule(0.41, 0.96),
		skin,
		Vector3(0.0, -0.02, -0.01),
		Vector3.ZERO,
		Vector3(1.04, 1.0, 0.88)
	)

	# Abdomen más estrecho para definir cintura.
	_add_part(
		body_root,
		"Abdomen",
		_capsule(0.31, 0.68),
		skin_dark,
		Vector3(0.0, -0.34, -0.02),
		Vector3.ZERO,
		Vector3(1.02, 1.0, 0.90)
	)

	# Joroba dorsal característica del rinoceronte.
	_add_part(
		body_root,
		"ShoulderHump",
		_capsule(0.25, 0.76),
		skin_light,
		Vector3(0.0, 0.43, -0.11),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 1.0, 0.91)
	)

	# =========================================================
	# ARMADURA DEL TORSO
	# =========================================================

	_add_part(
		body_root,
		"ChestArmor",
		_capsule(0.15, 0.72),
		armor_dark,
		Vector3(0.0, 0.18, 0.43),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 1.0, 0.62)
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


	# Marca Rhynus abstracta "R", deliberadamente pequeña.
	_add_box(
		body_root,
		"RhynusRStem",
		Vector3(0.035, 0.18, 0.020),
		glow,
		Vector3(-0.045, 0.18, 0.585)
	)

	_add_box(
		body_root,
		"RhynusRTop",
		Vector3(0.105, 0.030, 0.020),
		glow,
		Vector3(0.005, 0.255, 0.585)
	)

	_add_box(
		body_root,
		"RhynusRMid",
		Vector3(0.090, 0.030, 0.020),
		glow,
		Vector3(0.000, 0.19, 0.585)
	)

	_add_box(
		body_root,
		"RhynusRLeg",
		Vector3(0.030, 0.105, 0.020),
		glow,
		Vector3(0.035, 0.135, 0.585),
		Vector3(0.0, 0.0, -28.0)
	)

	_add_part(
		body_root,
		"PelvisArmor",
		_capsule(0.12, 0.55),
		armor_mid,
		Vector3(0.0, -0.39, 0.16),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 1.0, 0.72)
	)

	# =========================================================
	# MOCHILA RHYNUS / DATA CORE
	# =========================================================

	_add_part(
		body_root,
		"BackModule",
		_capsule(0.22, 0.58),
		armor_dark,
		Vector3(0.0, 0.16, -0.55),
		Vector3.ZERO,
		Vector3(1.12, 1.0, 0.78)
	)

	_add_part(
		body_root,
		"BackShell",
		_capsule(0.16, 0.43),
		armor_mid,
		Vector3(0.0, 0.18, -0.68),
		Vector3.ZERO,
		Vector3(1.0, 1.0, 0.70)
	)

	_add_box(
		body_root,
		"BackEnergy",
		Vector3(0.18, 0.30, 0.030),
		glow,
		Vector3(0.0, 0.18, -0.795)
	)

	_add_box(
		body_root,
		"BackRailL",
		Vector3(0.035, 0.36, 0.035),
		glow,
		Vector3(-0.16, 0.17, -0.69)
	)

	_add_box(
		body_root,
		"BackRailR",
		Vector3(0.035, 0.36, 0.035),
		glow,
		Vector3(0.16, 0.17, -0.69)
	)

	# Correas visibles desde tres cuartos.
	_add_part(
		body_root,
		"StrapL",
		_capsule(0.025, 0.58),
		armor_dark,
		Vector3(-0.30, 0.25, -0.22),
		Vector3(18.0, 0.0, -10.0)
	)

	_add_part(
		body_root,
		"StrapR",
		_capsule(0.025, 0.58),
		armor_dark,
		Vector3(0.30, 0.25, -0.22),
		Vector3(18.0, 0.0, 10.0)
	)

	# =========================================================
	# CORREAS FRONTALES DE LA MOCHILA
	# =========================================================

	_add_part(
		body_root,
		"FrontStrapL",
		_capsule(0.035, 0.58),
		armor_dark,
		Vector3(-0.29, 0.18, 0.34),
		Vector3(10.0, 0.0, -8.0),
		Vector3(1.0, 1.0, 0.70)
	)

	_add_part(
		body_root,
		"FrontStrapR",
		_capsule(0.035, 0.58),
		armor_dark,
		Vector3(0.29, 0.18, 0.34),
		Vector3(10.0, 0.0, 8.0),
		Vector3(1.0, 1.0, 0.70)
	)

	_add_part(
		body_root,
		"FrontStrapGlowL",
		_capsule(0.012, 0.22),
		glow,
		Vector3(-0.285, 0.20, 0.382),
		Vector3(10.0, 0.0, -8.0)
	)

	_add_part(
		body_root,
		"FrontStrapGlowR",
		_capsule(0.012, 0.22),
		glow,
		Vector3(0.285, 0.20, 0.382),
		Vector3(10.0, 0.0, 8.0)
	)

	_add_box(
		body_root,
		"StrapBuckleL",
		Vector3(0.09, 0.08, 0.045),
		armor_light,
		Vector3(-0.285, -0.015, 0.405)
	)

	_add_box(
		body_root,
		"StrapBuckleR",
		Vector3(0.09, 0.08, 0.045),
		armor_light,
		Vector3(0.285, -0.015, 0.405)
	)


	# =========================================================
	# CUELLO
	# =========================================================

	_add_part(
		body_root,
		"Neck",
		_capsule(0.34, 0.72),
		skin,
		Vector3(0.0, 0.46, 0.32),
		Vector3(70.0, 0.0, 0.0),
		Vector3(1.12, 1.0, 1.02)
	)

	# Masa inferior que fusiona cuello y pecho.
	_add_part(
		body_root,
		"NeckBase",
		_capsule(0.27, 0.60),
		skin_dark,
		Vector3(0.0, 0.31, 0.25),
		Vector3(63.0, 0.0, 0.0),
		Vector3(1.10, 1.0, 1.0)
	)

	# =========================================================
	# CABEZA
	# =========================================================

	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.59, 0.58)
	body_root.add_child(head_pivot)

	# =========================================================
	# CRÁNEO
	# =========================================================

	# Cráneo longitudinal en vez de esfera.
	_add_part(
		head_pivot,
		"Cranium",
		_capsule(0.27, 0.62),
		skin,
		Vector3(0.0, 0.06, 0.10),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.12, 1.0, 0.95)
	)

	# Frente ancha y baja.
	_add_part(
		head_pivot,
		"ForeheadMass",
		_capsule(0.15, 0.43),
		skin_light,
		Vector3(0.0, 0.17, 0.24),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 0.86, 0.90)
	)

	# =========================================================
	# MORRO DE RINOCERONTE
	# =========================================================

	# Puente nasal largo y fuerte.
	_add_part(
		head_pivot,
		"NasalBridge",
		_capsule(0.145, 0.58),
		skin,
		Vector3(0.0, 0.015, 0.45),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.05, 1.0, 0.88)
	)

	# Masa principal del hocico.
	_add_part(
		head_pivot,
		"MuzzleMain",
		_capsule(0.165, 0.47),
		skin_light,
		Vector3(0.0, -0.070, 0.70),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.12, 1.0, 0.84)
	)

	# Laterales del morro. Dan anchura sin crear una nariz circular.
	_add_part(
		head_pivot,
		"MuzzleSideL",
		_capsule(0.080, 0.27),
		skin,
		Vector3(-0.105, -0.075, 0.77),
		Vector3(90.0, 0.0, 0.0),
		Vector3(0.92, 1.0, 0.78)
	)

	_add_part(
		head_pivot,
		"MuzzleSideR",
		_capsule(0.080, 0.27),
		skin,
		Vector3(0.105, -0.075, 0.77),
		Vector3(90.0, 0.0, 0.0),
		Vector3(0.92, 1.0, 0.78)
	)

	# Punta nasal achatada y ancha.
	_add_part(
		head_pivot,
		"NasalTip",
		_sphere(),
		skin_dark,
		Vector3(0.0, -0.060, 0.89),
		Vector3.ZERO,
		Vector3(0.235, 0.105, 0.105)
	)

	# Narinas laterales, no frontales tipo cerdito.
	_add_part(
		head_pivot,
		"NostrilL",
		_sphere(),
		armor_dark,
		Vector3(-0.135, -0.072, 0.955),
		Vector3.ZERO,
		Vector3(0.033, 0.023, 0.016)
	)

	_add_part(
		head_pivot,
		"NostrilR",
		_sphere(),
		armor_dark,
		Vector3(0.135, -0.072, 0.955),
		Vector3.ZERO,
		Vector3(0.033, 0.023, 0.016)
	)

	# Mandíbula inferior separada.
	_add_part(
		head_pivot,
		"LowerJaw",
		_capsule(0.105, 0.39),
		skin_dark,
		Vector3(0.0, -0.185, 0.64),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.02, 1.0, 0.82)
	)

	# Labio inferior sutil.
	_add_part(
		head_pivot,
		"LowerLip",
		_capsule(0.042, 0.20),
		skin,
		Vector3(0.0, -0.176, 0.825),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 0.70, 0.70)
	)

	# Boca oscura muy fina.
	_add_box(
		head_pivot,
		"MouthLine",
		Vector3(0.22, 0.014, 0.045),
		armor_dark,
		Vector3(0.0, -0.153, 0.80)
	)


	# =========================================================
	# CUERNOS
	# =========================================================

	# Base integrada en el puente nasal.
	_add_part(
		head_pivot,
		"HornBase",
		_cone(0.075, 0.125, 0.18),
		horn,
		Vector3(0.0, 0.105, 0.72),
		Vector3(65.0, 0.0, 0.0)
	)

	_add_part(
		head_pivot,
		"MainHorn",
		_cone(0.018, 0.095, 0.43),
		horn,
		Vector3(0.0, 0.22, 0.83),
		Vector3(66.0, 0.0, 0.0)
	)

	_add_part(
		head_pivot,
		"SecondHorn",
		_cone(0.016, 0.062, 0.23),
		horn,
		Vector3(0.0, 0.265, 0.50),
		Vector3(57.0, 0.0, 0.0)
	)

	# =========================================================
	# OJOS PROMO
	# =========================================================

	# Esclerótica grande y clara.
	_add_part(
		head_pivot,
		"LeftEyeWhite",
		_sphere(),
		eye_white,
		Vector3(-0.175, 0.108, 0.388),
		Vector3.ZERO,
		Vector3(0.125, 0.110, 0.054)
	)

	_add_part(
		head_pivot,
		"RightEyeWhite",
		_sphere(),
		eye_white,
		Vector3(0.175, 0.108, 0.388),
		Vector3.ZERO,
		Vector3(0.125, 0.110, 0.054)
	)

	# Iris cyan.
	_add_part(
		head_pivot,
		"LeftIris",
		_sphere(),
		eye,
		Vector3(-0.175, 0.105, 0.433),
		Vector3.ZERO,
		Vector3(0.076, 0.082, 0.026)
	)

	_add_part(
		head_pivot,
		"RightIris",
		_sphere(),
		eye,
		Vector3(0.175, 0.105, 0.433),
		Vector3.ZERO,
		Vector3(0.076, 0.082, 0.026)
	)

	# Pupilas oscuras.
	_add_part(
		head_pivot,
		"LeftPupil",
		_sphere(),
		eye_pupil,
		Vector3(-0.175, 0.105, 0.456),
		Vector3.ZERO,
		Vector3(0.043, 0.055, 0.016)
	)

	_add_part(
		head_pivot,
		"RightPupil",
		_sphere(),
		eye_pupil,
		Vector3(0.175, 0.105, 0.456),
		Vector3.ZERO,
		Vector3(0.043, 0.055, 0.016)
	)

	# Reflejo luminoso que les da vida.
	_add_part(
		head_pivot,
		"LeftEyeHighlight",
		_sphere(),
		eye_white,
		Vector3(-0.194, 0.137, 0.468),
		Vector3.ZERO,
		Vector3(0.013, 0.016, 0.007)
	)

	_add_part(
		head_pivot,
		"RightEyeHighlight",
		_sphere(),
		eye_white,
		Vector3(0.156, 0.137, 0.468),
		Vector3.ZERO,
		Vector3(0.013, 0.016, 0.007)
	)

	# Cejas más curvas visualmente y menos Angry Birds.
	_add_part(
		head_pivot,
		"BrowL",
		_capsule(0.030, 0.17),
		armor_dark,
		Vector3(-0.17, 0.205, 0.375),
		Vector3(0.0, 0.0, 78.0)
	)

	_add_part(
		head_pivot,
		"BrowR",
		_capsule(0.030, 0.17),
		armor_dark,
		Vector3(0.17, 0.205, 0.375),
		Vector3(0.0, 0.0, 102.0)
	)


	# =========================================================
	# OREJAS
	# =========================================================

	_add_part(
		head_pivot,
		"EarL",
		_cone(0.018, 0.095, 0.25),
		skin_dark,
		Vector3(-0.245, 0.31, -0.01),
		Vector3(-14.0, 0.0, -27.0)
	)

	_add_part(
		head_pivot,
		"EarR",
		_cone(0.018, 0.095, 0.25),
		skin_dark,
		Vector3(0.245, 0.31, -0.01),
		Vector3(-14.0, 0.0, 27.0)
	)

	# Interior coloreado, pequeño guiño directo al diseño promocional.
	_add_part(
		head_pivot,
		"EarInnerL",
		_cone(0.012, 0.050, 0.16),
		ear_inner,
		Vector3(-0.238, 0.315, 0.035),
		Vector3(-14.0, 0.0, -27.0)
	)

	_add_part(
		head_pivot,
		"EarInnerR",
		_cone(0.012, 0.050, 0.16),
		ear_inner,
		Vector3(0.238, 0.315, 0.035),
		Vector3(-14.0, 0.0, 27.0)
	)


	# =========================================================
	# DETALLES CYBER
	# =========================================================

	_add_part(
		head_pivot,
		"TempleGlowL",
		_capsule(0.025, 0.12),
		glow,
		Vector3(-0.255, 0.095, 0.18)
	)

	_add_part(
		head_pivot,
		"TempleGlowR",
		_capsule(0.025, 0.12),
		glow,
		Vector3(0.255, 0.095, 0.18)
	)

	_add_part(
		head_pivot,
		"ForeheadCore",
		_capsule(0.025, 0.11),
		glow,
		Vector3(0.0, 0.185, 0.355),
		Vector3(0.0, 0.0, 90.0)
	)

	# =========================================================
	# BRAZOS
	# =========================================================

	arm_l = _build_arm(
		"ArmL",
		Vector3(-0.56, 0.18, 0.04),
		-1.0,
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	arm_r = _build_arm(
		"ArmR",
		Vector3(0.56, 0.18, 0.04),
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
		Vector3(-0.26, -0.43, 0.02),
		skin,
		skin_dark,
		armor_light,
		armor_dark,
		glow
	)

	leg_r = _build_leg(
		"LegR",
		Vector3(0.26, -0.43, 0.02),
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

	# Hombro horizontal, integrado al torso.
	_add_part(
		pivot,
		"Shoulder",
		_capsule(0.14, 0.36),
		skin,
		Vector3(side * 0.035, 0.0, 0.0),
		Vector3(0.0, 0.0, 90.0)
	)

	_add_part(
		pivot,
		"ShoulderArmor",
		_capsule(0.105, 0.31),
		armor,
		Vector3(side * 0.085, 0.025, 0.045),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 1.0, 0.72)
	)

	_add_part(
		pivot,
		"ShoulderGlow",
		_capsule(0.028, 0.16),
		glow,
		Vector3(side * 0.10, 0.025, 0.135),
		Vector3(0.0, 0.0, 90.0)
	)

	_add_part(
		pivot,
		"UpperArm",
		_capsule(0.12, 0.48),
		skin_dark,
		Vector3(0.0, -0.27, 0.0),
		Vector3(2.0 * side, 0.0, 0.0)
	)

	# El codo queda pequeño y encajado.
	_add_part(
		pivot,
		"Elbow",
		_capsule(0.075, 0.19),
		armor_dark,
		Vector3(0.0, -0.49, 0.018),
		Vector3(0.0, 0.0, 90.0)
	)

	_add_part(
		pivot,
		"ForeArm",
		_capsule(0.105, 0.43),
		armor,
		Vector3(0.0, -0.69, 0.035),
		Vector3(-3.0, 0.0, 0.0)
	)

	# Protector externo inspirado en las promos.
	_add_part(
		pivot,
		"ForearmShield",
		_capsule(0.080, 0.31),
		armor_dark,
		Vector3(side * 0.015, -0.68, 0.135),
		Vector3(-4.0, 0.0, 0.0),
		Vector3(1.15, 1.0, 0.52)
	)

	_add_part(
		pivot,
		"ForearmShieldCore",
		_capsule(0.035, 0.20),
		glow,
		Vector3(side * 0.018, -0.68, 0.205),
		Vector3(-4.0, 0.0, 0.0),
		Vector3(1.0, 1.0, 0.40)
	)

	# Mano alargada, no esfera.
	_add_part(
		pivot,
		"Hand",
		_capsule(0.085, 0.23),
		skin_dark,
		Vector3(0.0, -0.92, 0.075),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.05, 1.0, 0.88)
	)

	_add_box(
		pivot,
		"WristGlow",
		Vector3(0.17, 0.045, 0.14),
		glow,
		Vector3(0.0, -0.80, 0.055)
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

	# Muslo muy sólido.
	_add_part(
		pivot,
		"Thigh",
		_capsule(0.18, 0.57),
		skin,
		Vector3(0.0, -0.29, 0.0),
		Vector3(-3.0, 0.0, 0.0),
		Vector3(1.05, 1.0, 0.96)
	)

	# Rodilla transversal, menos "rótula de bola".
	_add_part(
		pivot,
		"Knee",
		_capsule(0.10, 0.26),
		armor_dark,
		Vector3(0.0, -0.57, 0.035),
		Vector3(0.0, 0.0, 90.0)
	)

	_add_part(
		pivot,
		"LowerLeg",
		_capsule(0.135, 0.49),
		skin_dark,
		Vector3(0.0, -0.79, 0.035),
		Vector3(3.5, 0.0, 0.0)
	)

	# Placa tibial siguiendo la pierna.
	_add_part(
		pivot,
		"ShinArmor",
		_capsule(0.085, 0.30),
		armor,
		Vector3(0.0, -0.77, 0.145),
		Vector3(3.5, 0.0, 0.0),
		Vector3(1.0, 1.0, 0.55)
	)

	_add_box(
		pivot,
		"ShinGlow",
		Vector3(0.060, 0.17, 0.022),
		glow,
		Vector3(0.0, -0.77, 0.215)
	)

	# Tobillo compacto.
	_add_part(
		pivot,
		"Ankle",
		_capsule(0.085, 0.23),
		skin_dark,
		Vector3(0.0, -0.995, 0.065)
	)

	# Pie longitudinal.
	_add_part(
		pivot,
		"Foot",
		_capsule(0.115, 0.41),
		skin_dark,
		Vector3(0.0, -1.07, 0.18),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.08, 1.0, 0.92)
	)

	# Pequeña protección superior.
	_add_part(
		pivot,
		"FootArmor",
		_capsule(0.075, 0.29),
		armor_dark,
		Vector3(0.0, -1.035, 0.20),
		Vector3(90.0, 0.0, 0.0),
		Vector3(1.08, 1.0, 0.75)
	)

	_add_box(
		pivot,
		"BootGlow",
		Vector3(0.16, 0.028, 0.10),
		glow,
		Vector3(0.0, -1.025, 0.39)
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
