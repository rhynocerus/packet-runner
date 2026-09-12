class_name RhinoOscar3D
extends Node3D

# Packet Runner // Rhino 1.0 Oscar Controller
# Conserva el GLB Blender y anima sus piezas por nombre.

const MODEL: PackedScene = preload(
	"res://assets/models/rhino/rhino3d-v1.0-oscar.glb"
)

const RUN_CYCLE_SPEED := 8.6

var model: Node3D

var body_root: Node3D
var head_pivot: Node3D

var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D

var elapsed := 0.0
var run_cycle := 0.0

var running := false
var hero_pose_active := false
var celebrate_remaining := 0.0

var base_pos := {}
var base_rot := {}


func _ready() -> void:
	model = MODEL.instantiate() as Node3D
	model.name = "OscarModel"
	add_child(model)

	body_root = _find_node("BodyRoot")

	if not is_instance_valid(body_root):
		body_root = model

	head_pivot = _find_node("HeadPivot")

	arm_l = _find_node("ArmL")
	arm_r = _find_node("ArmR")

	leg_l = _find_node("LegL")
	leg_r = _find_node("LegR")

	for node in [
		body_root,
		head_pivot,
		arm_l,
		arm_r,
		leg_l,
		leg_r,
	]:
		_remember(node)

	print("===== RHINO OSCAR CONTROLLER =====")
	print("BodyRoot : ", is_instance_valid(body_root))
	print("HeadPivot: ", is_instance_valid(head_pivot))
	print("ArmL     : ", is_instance_valid(arm_l))
	print("ArmR     : ", is_instance_valid(arm_r))
	print("LegL     : ", is_instance_valid(leg_l))
	print("LegR     : ", is_instance_valid(leg_r))


func _process(delta: float) -> void:
	elapsed += delta

	celebrate_remaining = maxf(
		0.0,
		celebrate_remaining - delta
	)

	if running:
		_process_running(delta)
	else:
		_process_idle()

	if hero_pose_active:
		_process_hero_pose(delta)


func _find_node(
	node_name: String
) -> Node3D:
	if not is_instance_valid(model):
		return null

	return model.find_child(
		node_name,
		true,
		false
	) as Node3D


func _remember(node: Node3D) -> void:
	if not is_instance_valid(node):
		return

	var id := node.get_instance_id()

	base_pos[id] = node.position
	base_rot[id] = node.rotation


func _base_position(
	node: Node3D
) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO

	return base_pos.get(
		node.get_instance_id(),
		node.position
	)


func _base_rotation(
	node: Node3D
) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO

	return base_rot.get(
		node.get_instance_id(),
		node.rotation
	)


func set_running(
	value: bool
) -> void:
	running = value

	if not running:
		run_cycle = 0.0


func set_hero_pose(
	value: bool
) -> void:
	hero_pose_active = value


func celebrate(
	duration: float = 1.2
) -> void:
	celebrate_remaining = maxf(
		celebrate_remaining,
		duration
	)


func _process_idle() -> void:
	var breath := sin(
		elapsed * 2.15
	)

	var sway := sin(
		elapsed * 1.10
	)

	if is_instance_valid(body_root):
		var p := _base_position(body_root)
		var r := _base_rotation(body_root)

		body_root.position = (
			p
			+ Vector3(
				0.0,
				breath * 0.018,
				0.0
			)
		)

		body_root.rotation = (
			r
			+ Vector3(
				0.0,
				0.0,
				deg_to_rad(
					sway * 0.65
				)
			)
		)

	if is_instance_valid(head_pivot):
		var r := _base_rotation(
			head_pivot
		)

		head_pivot.rotation = (
			r
			+ Vector3(
				deg_to_rad(
					sin(
						elapsed * 1.65
					) * 1.6
				),
				deg_to_rad(
					sin(
						elapsed * 0.85
					) * 2.8
				),
				0.0
			)
		)

	_idle_limb(
		arm_l,
		0.0,
		3.0
	)

	_idle_limb(
		arm_r,
		PI,
		3.0
	)

	_idle_limb(
		leg_l,
		PI,
		1.3
	)

	_idle_limb(
		leg_r,
		0.0,
		1.3
	)


func _idle_limb(
	node: Node3D,
	phase: float,
	degrees: float
) -> void:
	if not is_instance_valid(node):
		return

	var r := _base_rotation(node)

	r.x += deg_to_rad(
		sin(
			elapsed * 1.8
			+ phase
		) * degrees
	)

	node.rotation = r


func _process_running(
	delta: float
) -> void:
	run_cycle += (
		delta
		* RUN_CYCLE_SPEED
	)

	var stride := sin(
		run_cycle
	)

	var impact := absf(
		sin(
			run_cycle * 2.0
		)
	)

	if is_instance_valid(body_root):
		var p := _base_position(body_root)
		var r := _base_rotation(body_root)

		body_root.position = (
			p
			+ Vector3(
				0.0,
				impact * 0.060,
				0.0
			)
		)

		body_root.rotation = (
			r
			+ Vector3(
				deg_to_rad(
					8.0
					+ impact * 1.4
				),
				0.0,
				deg_to_rad(
					stride * 2.2
				)
			)
		)

	if is_instance_valid(head_pivot):
		var r := _base_rotation(
			head_pivot
		)

		r.x += deg_to_rad(
			-5.0
			+ sin(
				run_cycle * 2.0
				+ 0.4
			) * 2.4
		)

		r.y += deg_to_rad(
			sin(
				run_cycle * 0.5
			) * 0.9
		)

		head_pivot.rotation = r

	_run_limb(
		arm_l,
		stride * 36.0
	)

	_run_limb(
		arm_r,
		-stride * 36.0
	)

	_run_limb(
		leg_l,
		-stride * 31.0
	)

	_run_limb(
		leg_r,
		stride * 31.0
	)

	if celebrate_remaining > 0.0:
		_process_celebrate()


func _run_limb(
	node: Node3D,
	degrees: float
) -> void:
	if not is_instance_valid(node):
		return

	var r := _base_rotation(node)

	r.x += deg_to_rad(
		degrees
	)

	node.rotation = r


func _process_celebrate() -> void:
	var cheer := sin(
		elapsed * 13.0
	)

	if is_instance_valid(arm_l):
		var r := _base_rotation(
			arm_l
		)

		r.x += deg_to_rad(
			-18.0
			+ cheer * 12.0
		)

		r.z += deg_to_rad(
			-58.0
		)

		arm_l.rotation = r

	if is_instance_valid(arm_r):
		var r := _base_rotation(
			arm_r
		)

		r.x += deg_to_rad(
			-18.0
			- cheer * 12.0
		)

		r.z += deg_to_rad(
			58.0
		)

		arm_r.rotation = r


func _process_hero_pose(
	delta: float
) -> void:
	var blend := clampf(
		delta * 7.0,
		0.0,
		1.0
	)

	if is_instance_valid(head_pivot):
		var base := _base_rotation(
			head_pivot
		)

		head_pivot.rotation.x = lerp_angle(
			head_pivot.rotation.x,
			base.x + deg_to_rad(-7.0),
			blend
		)

		head_pivot.rotation.y = lerp_angle(
			head_pivot.rotation.y,
			base.y + deg_to_rad(-4.0),
			blend
		)

		head_pivot.rotation.z = lerp_angle(
			head_pivot.rotation.z,
			base.z + deg_to_rad(2.5),
			blend
		)

	if is_instance_valid(arm_l):
		var base := _base_rotation(
			arm_l
		)

		arm_l.rotation.x = lerp_angle(
			arm_l.rotation.x,
			base.x + deg_to_rad(-10.0),
			blend
		)

		arm_l.rotation.z = lerp_angle(
			arm_l.rotation.z,
			base.z + deg_to_rad(-22.0),
			blend
		)

	if is_instance_valid(arm_r):
		var base := _base_rotation(
			arm_r
		)

		arm_r.rotation.x = lerp_angle(
			arm_r.rotation.x,
			base.x + deg_to_rad(-30.0),
			blend
		)

		arm_r.rotation.y = lerp_angle(
			arm_r.rotation.y,
			base.y + deg_to_rad(-12.0),
			blend
		)

		arm_r.rotation.z = lerp_angle(
			arm_r.rotation.z,
			base.z + deg_to_rad(72.0),
			blend
		)
