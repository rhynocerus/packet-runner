extends Node3D

# Packet Runner 3D
# Vertical Slice v0.1
#
# Primer prototipo jugable:
# - Cyber-Savanna procedural
# - Rhino Runner
# - Tres carriles
# - Paquetes
# - Escudos
# - Malware
# - HUD / Firewall
# - Menú / Información / Pausa

const RHINO_SCENE: PackedScene = preload(
	"res://scenes/3d/rhino/rhino_3d.tscn"
)

const CYAN := Color(0.0, 0.90, 1.0, 1.0)
const GREEN := Color(0.19, 0.97, 0.64, 1.0)
const RED := Color(1.0, 0.26, 0.43, 1.0)
const YELLOW := Color(1.0, 0.82, 0.40, 1.0)

const BG := Color(0.015, 0.035, 0.060, 1.0)
const ROAD := Color(0.035, 0.075, 0.085, 1.0)
const SAVANNA := Color(0.11, 0.22, 0.13, 1.0)

const TRACK_SPEED := 8.0
const TRACK_WRAP := 44.0
const DECOR_SPEED := 2.7

const PLAYER_Z := 2.1
const LANE_CHANGE_SPEED := 6.5

const SPAWN_INTERVAL := 1.05

const PACKET_SCORE := 10
const SHIELD_PICKUP := 20
const MALWARE_DAMAGE := 25

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var game_state: int = GameState.MENU

var player: Node3D
var target_lane: int = 1

var lane_markers: Array[MeshInstance3D] = []
var decorations: Array[Node3D] = []
var pickups: Array[Node3D] = []

var spawn_elapsed: float = 0.0
var status_elapsed: float = 0.0

var score: int = 0
var shield: int = 100

var rng := RandomNumberGenerator.new()

# UI
var ui_root: Control
var menu_overlay: ColorRect
var info_overlay: ColorRect
var game_over_overlay: ColorRect

var hud: VBoxContainer
var score_label: Label
var level_label: Label
var firewall_label: Label
var shield_label: Label
var shield_bar: ProgressBar

var pause_button: Button
var game_over_score: Label


func _ready() -> void:
	rng.randomize()

	_build_world()
	_build_player()
	_build_ui()

	_show_menu()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if (
			game_state == GameState.PLAYING
			or game_state == GameState.PAUSED
		):
			_toggle_pause()

	if game_state != GameState.PLAYING:
		return

	_handle_lane_input()
	_update_player(delta)
	_update_track(delta)
	_update_decorations(delta)
	_update_pickups(delta)
	_update_spawning(delta)
	_update_status(delta)


# ============================================================
# GAME STATE
# ============================================================

func _start_game() -> void:
	score = 0
	shield = 100
	target_lane = 1
	spawn_elapsed = 0.0

	_clear_pickups()

	player.position = Vector3(
		_lane_x(target_lane),
		0.0,
		PLAYER_Z
	)

	player.rotation = Vector3(
		0.0,
		PI,
		0.0
	)

	player.visible = true

	if player.has_method("set_running"):
		player.call("set_running", true)

	game_state = GameState.PLAYING

	menu_overlay.hide()
	info_overlay.hide()
	game_over_overlay.hide()

	hud.show()
	pause_button.show()
	pause_button.text = "PAUSA"

	_set_status(
		"FIREWALL: ESTABLE",
		0.0
	)

	_update_hud()


func _show_menu() -> void:
	game_state = GameState.MENU

	menu_overlay.show()
	info_overlay.hide()
	game_over_overlay.hide()

	hud.hide()
	pause_button.hide()

	player.visible = true

	if player.has_method("set_running"):
		player.call("set_running", false)


func _show_info() -> void:
	menu_overlay.hide()
	info_overlay.show()


func _hide_info() -> void:
	info_overlay.hide()
	menu_overlay.show()


func _toggle_pause() -> void:
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		pause_button.text = "CONTINUAR"

		if player.has_method("set_running"):
			player.call("set_running", false)

		firewall_label.text = "SISTEMA EN PAUSA"

	elif game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		pause_button.text = "PAUSA"

		if player.has_method("set_running"):
			player.call("set_running", true)

		_set_status(
			"FIREWALL: ESTABLE",
			0.0
		)


func _game_over() -> void:
	game_state = GameState.GAME_OVER

	if player.has_method("set_running"):
		player.call("set_running", false)

	game_over_score.text = (
		"PAQUETES ASEGURADOS // %05d"
		% score
	)

	game_over_overlay.show()
	pause_button.hide()

	firewall_label.text = (
		"⚠ FIREWALL COMPROMETIDO"
	)


# ============================================================
# PLAYER
# ============================================================

func _build_player() -> void:
	player = RHINO_SCENE.instantiate()
	player.name = "RhinoRunner3D"

	player.position = Vector3(
		0.0,
		0.0,
		PLAYER_Z
	)

	# Mira hacia el horizonte.
	player.rotation.y = PI

	add_child(player)


func _handle_lane_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		target_lane = clampi(
			target_lane - 1,
			0,
			2
		)

	if Input.is_action_just_pressed("ui_right"):
		target_lane = clampi(
			target_lane + 1,
			0,
			2
		)


func _update_player(delta: float) -> void:
	var target_x: float = _lane_x(target_lane)

	player.position.x = move_toward(
		player.position.x,
		target_x,
		LANE_CHANGE_SPEED * delta
	)


func _lane_x(lane: int) -> float:
	match lane:
		0:
			return -1.6
		1:
			return 0.0
		2:
			return 1.6

	return 0.0


# ============================================================
# WORLD
# ============================================================

func _build_world() -> void:
	_build_environment()
	_build_ground()
	_build_track()
	_build_horizon()
	_build_decorations()


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()

	var environment := Environment.new()

	environment.background_mode = (
		Environment.BG_COLOR
	)

	environment.background_color = BG

	environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	environment.ambient_light_color = Color(
		0.38,
		0.48,
		0.58,
		1.0
	)

	environment.ambient_light_energy = 1.25

	world_env.environment = environment
	add_child(world_env)

	var sun_light := DirectionalLight3D.new()

	sun_light.rotation_degrees = Vector3(
		-48.0,
		25.0,
		0.0
	)

	sun_light.light_energy = 1.9
	sun_light.shadow_enabled = true

	add_child(sun_light)

	var camera := Camera3D.new()

	camera.position = Vector3(
		0.0,
		3.45,
		7.2
	)

	add_child(camera)

	camera.look_at(
		Vector3(
			0.0,
			1.15,
			-2.0
		),
		Vector3.UP
	)

	camera.current = true


func _build_ground() -> void:
	# Sabana general.
	var savanna_mesh := MeshInstance3D.new()
	var savanna_plane := PlaneMesh.new()

	savanna_plane.size = Vector2(
		30.0,
		80.0
	)

	savanna_mesh.mesh = savanna_plane
	savanna_mesh.position = Vector3(
		0.0,
		-0.04,
		-18.0
	)

	savanna_mesh.material_override = (
		_make_material(
			SAVANNA,
			Color.BLACK
		)
	)

	add_child(savanna_mesh)

	# Ruta central.
	var road_mesh := MeshInstance3D.new()
	var road_plane := PlaneMesh.new()

	road_plane.size = Vector2(
		6.4,
		80.0
	)

	road_mesh.mesh = road_plane

	road_mesh.position = Vector3(
		0.0,
		0.0,
		-18.0
	)

	road_mesh.material_override = (
		_make_material(
			ROAD,
			Color.BLACK
		)
	)

	add_child(road_mesh)


func _build_track() -> void:
	var marker_material := _make_material(
		Color(0.0, 0.50, 0.58, 1.0),
		CYAN
	)

	for i in range(22):
		for divider_x in [-0.80, 0.80]:
			var marker := MeshInstance3D.new()
			var box := BoxMesh.new()

			box.size = Vector3(
				0.055,
				0.018,
				0.72
			)

			marker.mesh = box
			marker.material_override = marker_material

			marker.position = Vector3(
				float(divider_x),
				0.025,
				4.0 - float(i) * 2.0
			)

			add_child(marker)
			lane_markers.append(marker)


func _update_track(delta: float) -> void:
	for marker in lane_markers:
		marker.position.z += (
			TRACK_SPEED * delta
		)

		if marker.position.z > 5.0:
			marker.position.z -= TRACK_WRAP


func _build_horizon() -> void:
	# Sol
	var sun := MeshInstance3D.new()
	var sun_mesh := SphereMesh.new()

	sun_mesh.radius = 2.2
	sun_mesh.height = 4.4

	sun.mesh = sun_mesh

	sun.position = Vector3(
		6.0,
		7.5,
		-30.0
	)

	sun.material_override = _make_material(
		YELLOW,
		Color(
			1.0,
			0.55,
			0.12,
			1.0
		)
	)

	add_child(sun)

	# Montañas low-poly.
	for i in range(7):
		var mountain := MeshInstance3D.new()
		var cone := CylinderMesh.new()

		cone.top_radius = 0.0
		cone.bottom_radius = (
			2.0 + float(i % 3) * 0.55
		)

		cone.height = (
			3.0 + float(i % 2)
		)

		cone.radial_segments = 4

		mountain.mesh = cone

		var x: float = (
			-9.0
			+ float(i) * 3.0
		)

		mountain.position = Vector3(
			x,
			cone.height * 0.5,
			-35.0
			- float(i % 2) * 3.0
		)

		mountain.material_override = (
			_make_material(
				Color(
					0.08,
					0.16,
					0.17,
					1.0
				),
				Color.BLACK
			)
		)

		add_child(mountain)


func _build_decorations() -> void:
	for i in range(8):
		var z: float = (
			-4.0
			- float(i) * 5.5
		)

		var left: Node3D

		if i % 2 == 0:
			left = _create_acacia(
				-4.6,
				z
			)
		else:
			left = _create_tower(
				-4.8,
				z
			)

		decorations.append(left)

		var right: Node3D

		if i % 2 == 0:
			right = _create_tower(
				4.8,
				z - 2.0
			)
		else:
			right = _create_acacia(
				4.6,
				z - 2.0
			)

		decorations.append(right)


func _create_acacia(
	x: float,
	z: float
) -> Node3D:
	var root := Node3D.new()

	root.position = Vector3(
		x,
		0.0,
		z
	)

	add_child(root)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()

	trunk_mesh.top_radius = 0.10
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = 2.2
	trunk_mesh.radial_segments = 8

	trunk.mesh = trunk_mesh

	trunk.position.y = 1.1

	trunk.material_override = (
		_make_material(
			Color(
				0.20,
				0.15,
				0.08,
				1.0
			),
			Color.BLACK
		)
	)

	root.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()

	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 12
	crown_mesh.rings = 6

	crown.mesh = crown_mesh

	crown.position.y = 2.35

	crown.scale = Vector3(
		1.65,
		0.32,
		0.72
	)

	crown.material_override = (
		_make_material(
			Color(
				0.08,
				0.26,
				0.17,
				1.0
			),
			Color.BLACK
		)
	)

	root.add_child(crown)

	var node_light := MeshInstance3D.new()
	var node_mesh := SphereMesh.new()

	node_mesh.radius = 0.11
	node_mesh.height = 0.22

	node_light.mesh = node_mesh

	node_light.position = Vector3(
		0.0,
		2.25,
		0.58
	)

	node_light.material_override = (
		_make_material(
			CYAN,
			CYAN
		)
	)

	root.add_child(node_light)

	return root


func _create_tower(
	x: float,
	z: float
) -> Node3D:
	var root := Node3D.new()

	root.position = Vector3(
		x,
		0.0,
		z
	)

	add_child(root)

	var column := MeshInstance3D.new()
	var column_mesh := BoxMesh.new()

	column_mesh.size = Vector3(
		0.48,
		2.8,
		0.48
	)

	column.mesh = column_mesh

	column.position.y = 1.4

	column.material_override = (
		_make_material(
			Color(
				0.055,
				0.09,
				0.12,
				1.0
			),
			Color.BLACK
		)
	)

	root.add_child(column)

	var core := MeshInstance3D.new()
	var core_mesh := BoxMesh.new()

	core_mesh.size = Vector3(
		0.17,
		1.7,
		0.52
	)

	core.mesh = core_mesh

	core.position = Vector3(
		0.0,
		1.45,
		0.06
	)

	core.material_override = (
		_make_material(
			Color(
				0.0,
				0.35,
				0.42,
				1.0
			),
			CYAN
		)
	)

	root.add_child(core)

	var antenna := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()

	antenna_mesh.top_radius = 0.03
	antenna_mesh.bottom_radius = 0.05
	antenna_mesh.height = 1.0

	antenna.mesh = antenna_mesh

	antenna.position.y = 3.3

	antenna.material_override = (
		_make_material(
			Color(
				0.2,
				0.3,
				0.34,
				1.0
			),
			Color.BLACK
		)
	)

	root.add_child(antenna)

	return root


func _update_decorations(delta: float) -> void:
	for item in decorations:
		item.position.z += (
			DECOR_SPEED * delta
		)

		if item.position.z > 8.0:
			item.position.z -= 48.0


# ============================================================
# PICKUPS / MALWARE
# ============================================================

func _update_spawning(delta: float) -> void:
	spawn_elapsed += delta

	if spawn_elapsed < SPAWN_INTERVAL:
		return

	spawn_elapsed = 0.0
	_spawn_pickup()


func _spawn_pickup() -> void:
	var item := Node3D.new()

	item.name = "NetworkObject"

	var lane_index: int = (
		rng.randi_range(
			0,
			2
		)
	)

	item.position = Vector3(
		_lane_x(lane_index),
		0.95,
		-34.0
	)

	var roll: float = rng.randf()
	var kind: String = "packet"

	if roll < 0.60:
		kind = "packet"

	elif roll < 0.80:
		kind = "shield"

	else:
		kind = "malware"

	item.set_meta(
		"kind",
		kind
	)

	_build_pickup_visual(
		item,
		kind
	)

	add_child(item)
	pickups.append(item)


func _build_pickup_visual(
	item: Node3D,
	kind: String
) -> void:
	var visual := MeshInstance3D.new()

	var mesh_resource: Mesh
	var material: StandardMaterial3D

	if kind == "packet":
		var sphere := SphereMesh.new()

		sphere.radius = 0.28
		sphere.height = 0.56
		sphere.radial_segments = 12
		sphere.rings = 6

		mesh_resource = sphere

		material = _make_material(
			GREEN,
			GREEN
		)

	elif kind == "shield":
		var shield_mesh := BoxMesh.new()

		shield_mesh.size = Vector3(
			0.48,
			0.48,
			0.20
		)

		mesh_resource = shield_mesh

		material = _make_material(
			Color(
				0.0,
				0.42,
				0.52,
				1.0
			),
			CYAN
		)

		visual.rotation_degrees = Vector3(
			0.0,
			45.0,
			45.0
		)

	else:
		var malware_mesh := SphereMesh.new()

		malware_mesh.radius = 0.31
		malware_mesh.height = 0.62
		malware_mesh.radial_segments = 10
		malware_mesh.rings = 5

		mesh_resource = malware_mesh

		material = _make_material(
			Color(
				0.40,
				0.02,
				0.08,
				1.0
			),
			RED
		)

	visual.mesh = mesh_resource
	visual.material_override = material

	item.add_child(visual)

	if kind == "malware":
		_add_malware_spikes(
			item,
			material
		)


func _add_malware_spikes(
	item: Node3D,
	material: Material
) -> void:
	for rotation_z in [0.0, 45.0, 90.0, 135.0]:
		var spike := MeshInstance3D.new()
		var box := BoxMesh.new()

		box.size = Vector3(
			0.07,
			0.74,
			0.07
		)

		spike.mesh = box
		spike.material_override = material

		spike.rotation_degrees.z = float(
			rotation_z
		)

		item.add_child(spike)


func _update_pickups(delta: float) -> void:
	for i in range(
		pickups.size() - 1,
		-1,
		-1
	):
		var item: Node3D = pickups[i]

		item.position.z += (
			TRACK_SPEED * delta
		)

		item.rotation.y += (
			delta * 1.6
		)

		var close_z: bool = (
			absf(
				item.position.z
				- player.position.z
			)
			< 0.70
		)

		var close_x: bool = (
			absf(
				item.position.x
				- player.position.x
			)
			< 0.65
		)

		if close_z and close_x:
			_collect_pickup(item)

			pickups.remove_at(i)
			item.queue_free()

			continue

		if item.position.z > 7.5:
			pickups.remove_at(i)
			item.queue_free()


func _collect_pickup(
	item: Node3D
) -> void:
	var kind: String = str(
		item.get_meta(
			"kind",
			"packet"
		)
	)

	match kind:
		"packet":
			score += PACKET_SCORE

			_set_status(
				"PAQUETE SEGURO // +%d"
				% PACKET_SCORE,
				1.2
			)

		"shield":
			shield = mini(
				100,
				shield + SHIELD_PICKUP
			)

			_set_status(
				"FIREWALL REFORZADO // +%d"
				% SHIELD_PICKUP,
				1.5
			)

		"malware":
			shield = maxi(
				0,
				shield - MALWARE_DAMAGE
			)

			_set_status(
				"⚠ INTRUSIÓN DETECTADA // -%d"
				% MALWARE_DAMAGE,
				1.6
			)

			if shield <= 0:
				_update_hud()
				_game_over()
				return

	_update_hud()


func _clear_pickups() -> void:
	for item in pickups:
		if is_instance_valid(item):
			item.queue_free()

	pickups.clear()


# ============================================================
# HUD / UI
# ============================================================

func _build_ui() -> void:
	var canvas := CanvasLayer.new()

	canvas.layer = 20
	add_child(canvas)

	ui_root = Control.new()

	ui_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	canvas.add_child(ui_root)

	_build_hud()
	_build_menu()
	_build_info()
	_build_game_over()


func _build_hud() -> void:
	hud = VBoxContainer.new()

	hud.position = Vector2(
		22.0,
		18.0
	)

	hud.custom_minimum_size = Vector2(
		390.0,
		150.0
	)

	ui_root.add_child(hud)

	var title := Label.new()

	title.text = "PACKET RUNNER 3D"

	title.add_theme_color_override(
		"font_color",
		CYAN
	)

	title.add_theme_font_size_override(
		"font_size",
		24
	)

	hud.add_child(title)

	level_label = Label.new()

	level_label.text = (
		"NIVEL 01 // SABANA CONECTADA"
	)

	level_label.add_theme_color_override(
		"font_color",
		GREEN
	)

	hud.add_child(level_label)

	score_label = Label.new()
	hud.add_child(score_label)

	shield_label = Label.new()
	hud.add_child(shield_label)

	shield_bar = ProgressBar.new()

	shield_bar.min_value = 0
	shield_bar.max_value = 100
	shield_bar.value = 100
	shield_bar.show_percentage = false

	shield_bar.custom_minimum_size = Vector2(
		360.0,
		18.0
	)

	var bar_bg := StyleBoxFlat.new()

	bar_bg.bg_color = Color(
		0.02,
		0.06,
		0.08,
		0.90
	)

	var bar_fill := StyleBoxFlat.new()

	bar_fill.bg_color = CYAN

	shield_bar.add_theme_stylebox_override(
		"background",
		bar_bg
	)

	shield_bar.add_theme_stylebox_override(
		"fill",
		bar_fill
	)

	hud.add_child(shield_bar)

	firewall_label = Label.new()

	firewall_label.text = (
		"FIREWALL: ESTABLE"
	)

	firewall_label.add_theme_color_override(
		"font_color",
		CYAN
	)

	hud.add_child(firewall_label)

	pause_button = _make_button(
		"PAUSA"
	)

	ui_root.add_child(pause_button)

	pause_button.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	pause_button.offset_left = -155.0
	pause_button.offset_top = 20.0
	pause_button.offset_right = -20.0
	pause_button.offset_bottom = 65.0

	pause_button.pressed.connect(
		_toggle_pause
	)


func _build_menu() -> void:
	menu_overlay = ColorRect.new()

	menu_overlay.color = Color(
		0.01,
		0.025,
		0.04,
		0.91
	)

	menu_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ui_root.add_child(menu_overlay)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	menu_overlay.add_child(center)

	var box := VBoxContainer.new()

	box.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	box.custom_minimum_size = Vector2(
		520.0,
		320.0
	)

	center.add_child(box)

	var title := Label.new()

	title.text = "PACKET RUNNER 3D"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_color_override(
		"font_color",
		CYAN
	)

	title.add_theme_font_size_override(
		"font_size",
		38
	)

	box.add_child(title)

	var subtitle := Label.new()

	subtitle.text = (
		"A RHYNUS PROJECT // "
		+ "CYBER-SAVANNA PROTOTYPE"
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_color_override(
		"font_color",
		GREEN
	)

	box.add_child(subtitle)

	var spacer := Control.new()

	spacer.custom_minimum_size.y = 28.0
	box.add_child(spacer)

	var play := _make_button(
		"JUGAR"
	)

	play.pressed.connect(
		_start_game
	)

	box.add_child(play)

	var info := _make_button(
		"INFORMACIÓN"
	)

	info.pressed.connect(
		_show_info
	)

	box.add_child(info)

	var footer := Label.new()

	footer.text = (
		"← → CAMBIAR CARRIL   "
		+ "ESC PAUSA"
	)

	footer.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	footer.add_theme_color_override(
		"font_color",
		Color(
			0.55,
			0.68,
			0.72,
			1.0
		)
	)

	box.add_child(footer)


func _build_info() -> void:
	info_overlay = ColorRect.new()

	info_overlay.color = Color(
		0.01,
		0.025,
		0.04,
		0.96
	)

	info_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ui_root.add_child(info_overlay)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	info_overlay.add_child(center)

	var box := VBoxContainer.new()

	box.custom_minimum_size = Vector2(
		620.0,
		400.0
	)

	center.add_child(box)

	var title := Label.new()

	title.text = (
		"PROTOCOLO PACKET RUNNER"
	)

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_color_override(
		"font_color",
		CYAN
	)

	title.add_theme_font_size_override(
		"font_size",
		28
	)

	box.add_child(title)

	var info := Label.new()

	info.text = (
		"Defiende la Cyber-Savanna.\n\n"
		+ "VERDE  // paquete legítimo // +10 puntos\n"
		+ "CYAN   // escudo de red // +20 firewall\n"
		+ "ROJO   // malware // -25 firewall\n\n"
		+ "← → cambia de carril.\n"
		+ "ESC o PAUSA detiene el sistema.\n\n"
		+ "Objetivo experimental:\n"
		+ "proteger el flujo de datos "
		+ "sin perder el firewall."
	)

	info.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	info.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	box.add_child(info)

	var back := _make_button(
		"VOLVER"
	)

	back.pressed.connect(
		_hide_info
	)

	box.add_child(back)

	info_overlay.hide()


func _build_game_over() -> void:
	game_over_overlay = ColorRect.new()

	game_over_overlay.color = Color(
		0.05,
		0.005,
		0.015,
		0.91
	)

	game_over_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ui_root.add_child(game_over_overlay)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	game_over_overlay.add_child(center)

	var box := VBoxContainer.new()

	box.custom_minimum_size = Vector2(
		500.0,
		300.0
	)

	center.add_child(box)

	var title := Label.new()

	title.text = (
		"⚠ FIREWALL COMPROMETIDO"
	)

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_color_override(
		"font_color",
		RED
	)

	title.add_theme_font_size_override(
		"font_size",
		30
	)

	box.add_child(title)

	game_over_score = Label.new()

	game_over_score.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	box.add_child(game_over_score)

	var retry := _make_button(
		"REINTENTAR"
	)

	retry.pressed.connect(
		_start_game
	)

	box.add_child(retry)

	var menu := _make_button(
		"VOLVER AL MENÚ"
	)

	menu.pressed.connect(
		_show_menu
	)

	box.add_child(menu)

	game_over_overlay.hide()


func _make_button(
	text_value: String
) -> Button:
	var button := Button.new()

	button.text = text_value

	button.custom_minimum_size = Vector2(
		280.0,
		48.0
	)

	button.add_theme_color_override(
		"font_color",
		CYAN
	)

	button.add_theme_color_override(
		"font_hover_color",
		GREEN
	)

	button.add_theme_font_size_override(
		"font_size",
		20
	)

	var style := StyleBoxFlat.new()

	style.bg_color = Color(
		0.025,
		0.08,
		0.10,
		0.92
	)

	style.border_color = Color(
		0.0,
		0.55,
		0.62,
		1.0
	)

	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	button.add_theme_stylebox_override(
		"normal",
		style
	)

	return button


func _update_hud() -> void:
	score_label.text = (
		"PUNTOS     %05d"
		% score
	)

	shield_label.text = (
		"ESCUDO     %03d/100"
		% shield
	)

	shield_bar.value = shield


func _set_status(
	text_value: String,
	duration: float
) -> void:
	firewall_label.text = text_value
	status_elapsed = duration


func _update_status(delta: float) -> void:
	if status_elapsed <= 0.0:
		return

	status_elapsed -= delta

	if status_elapsed <= 0.0:
		firewall_label.text = (
			"FIREWALL: ESTABLE"
		)


# ============================================================
# MATERIAL
# ============================================================

func _make_material(
	albedo: Color,
	emission_color: Color
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = albedo
	material.roughness = 0.72
	material.metallic = 0.10

	if (
		emission_color.r > 0.0
		or emission_color.g > 0.0
		or emission_color.b > 0.0
	):
		material.emission_enabled = true
		material.emission = emission_color

		material.emission_energy_multiplier = 1.4

	return material
