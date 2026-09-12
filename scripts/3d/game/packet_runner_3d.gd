extends Node3D

# Packet Runner 3D
# Packet Runner 3D v0.8.1 // Wide Lanes + Jump Pass
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
	"res://scenes/3d/rhino/rhino_oscar_3d.tscn"
)

const MUSIC_LEVEL1: AudioStream = preload(
	"res://assets/audio/music/packet-runner-level1.ogg"
)


const MUSIC_LEVEL2: AudioStream = preload(
	"res://assets/audio/music/packet-runner-level2.ogg"
)

const MUSIC_LEVEL3: AudioStream = preload(
	"res://assets/audio/music/packet-runner-level3.ogg"
)

const RHYNUS_SPLASH: Texture2D = preload(
	"res://assets/branding/rhynus/rhynus-splash-web.png"
)


const FONT_UI: Font = preload(
	"res://assets/fonts/UbuntuSans-Variable.ttf"
)

const FONT_UI_ITALIC: Font = preload(
	"res://assets/fonts/UbuntuSans-Italic-Variable.ttf"
)

const FONT_TELEMETRY: Font = preload(
	"res://assets/fonts/UbuntuSansMono-Variable.ttf"
)

const SFX_PACKET: AudioStream = preload(
	"res://assets/audio/sfx/packet-safe.wav"
)

const SFX_MALWARE: AudioStream = preload(
	"res://assets/audio/sfx/malware-hit.wav"
)

const SFX_GAME_OVER: AudioStream = preload(
	"res://assets/audio/sfx/game-over.wav"
)


const CYAN := Color(0.0, 0.90, 1.0, 1.0)
const GREEN := Color(0.19, 0.97, 0.64, 1.0)
const RED := Color(1.0, 0.26, 0.43, 1.0)
const YELLOW := Color(1.0, 0.82, 0.40, 1.0)

const BG := Color(0.015, 0.035, 0.060, 1.0)
const ROAD := Color(0.035, 0.075, 0.085, 1.0)
const SAVANNA := Color(0.11, 0.22, 0.13, 1.0)

const TRACK_SPEED := 9.2
const TRACK_WRAP := 44.0
const DECOR_SPEED := 2.7

const PLAYER_Z := 2.1
const LANE_CHANGE_SPEED := 7.0

const FORWARD_MOVE_SPEED := 5.8
const PLAYER_MIN_Z := -3.2
const PLAYER_MAX_Z := 3.2

const PLAYER_TURN_ANGLE := 8.0
const PLAYER_TURN_SPEED := 7.0

const JUMP_VELOCITY := 6.8
const JUMP_GRAVITY := 17.0
const JUMP_MALWARE_CLEARANCE := 0.62

const CAMERA_FOLLOW_SPEED := 2.6

const BOOST_DURATION := 5.0
const BOOST_MULTIPLIER := 1.55

const LEVEL_2_SCORE := 300
const LEVEL_3_SCORE := 700

const CINEMATIC_DURATION := 17.0

const SPAWN_INTERVAL := 0.78

const PACKET_SCORE := 10
const SHIELD_PICKUP := 20
const MALWARE_DAMAGE := 25

enum GameState {
	MENU,
	INTRO,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var game_state: int = GameState.MENU

var player: Node3D
var camera: Camera3D

var world_environment: Environment
var main_sun_light: DirectionalLight3D

var savanna_material: StandardMaterial3D
var road_material: StandardMaterial3D
var horizon_sun_material: StandardMaterial3D

var target_lane: int = 1
var forward_input: float = 0.0

var jump_velocity: float = 0.0
var is_jumping: bool = false

var lane_markers: Array[MeshInstance3D] = []
var decorations: Array[Node3D] = []
var ground_details: Array[Node3D] = []
var road_details: Array[Node3D] = []
var pickups: Array[Node3D] = []

var music_player: AudioStreamPlayer
var sfx_safe: AudioStreamPlayer
var sfx_malware: AudioStreamPlayer
var sfx_game_over: AudioStreamPlayer

var spawn_elapsed: float = 0.0
var status_elapsed: float = 0.0

var score: int = 0
var shield: int = 100

var current_level: int = 1
var boost_remaining: float = 0.0

var last_milestone_score: int = 0
var event_remaining: float = 0.0
var event_tween: Tween
var overlay_tween: Tween

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
var boost_label: Label
var event_label: Label

var brand_overlay: ColorRect

var cinematic_overlay: Control
var cinematic_title: Label
var cinematic_subtitle: Label
var cinematic_campaign: Label
var cinematic_skip_button: Button
var cinematic_demo_item: Node3D

var cinematic_elapsed: float = 0.0
var cinematic_phase: int = -1
var cinematic_text_tween: Tween

var scan_line: ColorRect

var animated_titles: Array[Label] = []
var animated_buttons: Array[Button] = []

var ui_motion_elapsed: float = 0.0
var scan_y: float = -8.0
var intro_scan_passes: int = 0

var pause_button: Button
var game_over_score: Label


func _ready() -> void:
	rng.randomize()

	_build_world()
	_build_player()
	_build_audio()
	_build_ui()

	_show_brand_splash()

	await get_tree().create_timer(
		2.8
	).timeout

	_start_cinematic_intro()


func _process(delta: float) -> void:
	_update_ui_motion(delta)

	if game_state == GameState.INTRO:
		if (
			Input.is_action_just_pressed(
				"ui_cancel"
			)
			or Input.is_action_just_pressed(
				"ui_accept"
			)
		):
			_finish_cinematic_intro()
			return

		_update_cinematic_intro(delta)
		return

	if Input.is_action_just_pressed("ui_cancel"):
		if (
			game_state == GameState.PLAYING
			or game_state == GameState.PAUSED
		):
			_toggle_pause()

	if game_state != GameState.PLAYING:
		return

	_update_boost(delta)
	_update_level_progression()

	_handle_player_input()
	_update_jump(delta)
	_update_player(delta)
	_update_camera(delta)

	_update_track(delta)
	_update_ground_details(delta)
	_update_road_details(delta)
	_update_decorations(delta)

	_update_pickups(delta)
	_update_spawning(delta)

	_update_status(delta)
	_update_event_feedback(delta)
	_update_level_visuals(delta)


# ============================================================
# GAME STATE
# ============================================================

func _start_game() -> void:
	score = 0
	shield = 100

	current_level = 1
	boost_remaining = 0.0
	last_milestone_score = 0

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

	if not music_player.playing:
		music_player.play()

	music_player.stream_paused = false

	_update_hud()


func _show_menu() -> void:
	game_state = GameState.MENU

	if is_instance_valid(
		cinematic_overlay
	):
		cinematic_overlay.hide()

	if is_instance_valid(brand_overlay):
		brand_overlay.hide()

	if is_instance_valid(music_player):
		music_player.stop()

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

	info_overlay.modulate.a = 0.0
	info_overlay.show()

	if is_instance_valid(overlay_tween):
		overlay_tween.kill()

	overlay_tween = create_tween()

	overlay_tween.tween_property(
		info_overlay,
		"modulate:a",
		1.0,
		0.28
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func _hide_info() -> void:
	info_overlay.hide()
	menu_overlay.show()


func _toggle_pause() -> void:
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		pause_button.text = "CONTINUAR"

		if is_instance_valid(music_player):
			music_player.stream_paused = true

		if player.has_method("set_running"):
			player.call("set_running", false)

		firewall_label.text = "SISTEMA EN PAUSA"

	elif game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		pause_button.text = "PAUSA"

		if is_instance_valid(music_player):
			music_player.stream_paused = false

		if player.has_method("set_running"):
			player.call("set_running", true)

		_set_status(
			"FIREWALL: ESTABLE",
			0.0
		)


func _game_over() -> void:
	game_state = GameState.GAME_OVER

	if is_instance_valid(music_player):
		music_player.stop()

	if is_instance_valid(sfx_game_over):
		sfx_game_over.play()

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
# AUDIO
# ============================================================

func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic3D"
	music_player.stream = MUSIC_LEVEL1
	music_player.volume_db = -7.0
	add_child(music_player)

	sfx_safe = AudioStreamPlayer.new()
	sfx_safe.name = "SfxSafe3D"
	sfx_safe.stream = SFX_PACKET
	sfx_safe.volume_db = -1.0
	add_child(sfx_safe)

	sfx_malware = AudioStreamPlayer.new()
	sfx_malware.name = "SfxMalware3D"
	sfx_malware.stream = SFX_MALWARE
	sfx_malware.volume_db = -1.0
	add_child(sfx_malware)

	sfx_game_over = AudioStreamPlayer.new()
	sfx_game_over.name = "SfxGameOver3D"
	sfx_game_over.stream = SFX_GAME_OVER
	sfx_game_over.volume_db = -1.0
	add_child(sfx_game_over)


func _play_safe_sfx(
	pitch: float = 1.0
) -> void:
	sfx_safe.pitch_scale = pitch
	sfx_safe.play()


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


func _handle_player_input() -> void:
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

	# Espacio / ui_accept.
	# En INTRO sigue funcionando como skip;
	# aquí sólo llegamos estando PLAYING.
	if (
		Input.is_action_just_pressed(
			"ui_accept"
		)
		and not is_jumping
	):
		is_jumping = true
		jump_velocity = JUMP_VELOCITY

		if player.has_method(
			"set_airborne"
		):
			player.call(
				"set_airborne",
				true
			)

		_show_event_feedback(
			"↑ SALTO",
			CYAN,
			0.45
		)

	forward_input = 0.0

	if (
		Input.is_key_pressed(KEY_W)
		or Input.is_action_pressed("ui_up")
	):
		forward_input -= 1.0

	if (
		Input.is_key_pressed(KEY_S)
		or Input.is_action_pressed("ui_down")
	):
		forward_input += 1.0


func _update_jump(delta: float) -> void:
	if not is_jumping:
		player.position.y = 0.0
		return

	jump_velocity -= (
		JUMP_GRAVITY
		* delta
	)

	player.position.y += (
		jump_velocity
		* delta
	)

	if player.position.y <= 0.0:
		player.position.y = 0.0
		jump_velocity = 0.0
		is_jumping = false

		if player.has_method(
			"set_airborne"
		):
			player.call(
				"set_airborne",
				false
			)


func _update_player(delta: float) -> void:
	var target_x: float = _lane_x(
		target_lane
	)

	var horizontal_error: float = (
		target_x
		- player.position.x
	)

	player.position.x = move_toward(
		player.position.x,
		target_x,
		LANE_CHANGE_SPEED * delta
	)

	player.position.z = clampf(
		player.position.z
		+ forward_input
		* FORWARD_MOVE_SPEED
		* _boost_multiplier()
		* delta,
		PLAYER_MIN_Z,
		PLAYER_MAX_Z
	)

	# Movimiento físico del nodo principal:
	# giro pequeño para conservar dirección de carrera.
	var turn_factor: float = clampf(
		horizontal_error / 2.8,
		-1.0,
		1.0
	)

	var desired_yaw: float = (
		PI
		- deg_to_rad(
			PLAYER_TURN_ANGLE
			* turn_factor
		)
	)

	player.rotation.y = lerp_angle(
		player.rotation.y,
		desired_yaw,
		minf(
			1.0,
			PLAYER_TURN_SPEED
			* delta
		)
	)

	# Giro VISUAL del modelo.
	# Mantiene casi todo el 3/4 durante el cambio
	# y sólo se endereza al acercarse al nuevo carril.
	var visual_steer: float = 0.0

	if absf(horizontal_error) > 0.08:
		visual_steer = (
			signf(horizontal_error)
			* clampf(
				absf(horizontal_error)
				/ 0.48,
				0.0,
				1.0
			)
		)

	if player.has_method(
		"set_steering"
	):
		player.call(
			"set_steering",
			visual_steer
		)


func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	var target_camera_y: float = 3.45
	var target_camera_z: float = 7.20
	var target_fov: float = 70.0
	var look_ahead: float = -4.5

	if boost_remaining > 0.0:
		# Durante el boost nos acercamos al Rino
		# y abrimos ligeramente el campo visual.
		target_camera_y = 3.00
		target_camera_z = 6.00
		target_fov = 75.0
		look_ahead = -6.0

	var blend: float = clampf(
		delta * 2.5,
		0.0,
		1.0
	)

	camera.position.x = lerpf(
		camera.position.x,
		player.position.x * 0.18,
		blend
	)

	camera.position.y = lerpf(
		camera.position.y,
		target_camera_y,
		blend
	)

	camera.position.z = lerpf(
		camera.position.z,
		target_camera_z,
		blend
	)

	camera.fov = lerpf(
		camera.fov,
		target_fov,
		blend
	)

	camera.look_at(
		Vector3(
			player.position.x * 0.12,
			1.15,
			player.position.z + look_ahead
		),
		Vector3.UP
	)


func _boost_multiplier() -> float:
	if boost_remaining > 0.0:
		return BOOST_MULTIPLIER

	return 1.0


func _level_speed_multiplier() -> float:
	match current_level:
		2:
			return 1.10

		3:
			return 1.22

	return 1.0


func _current_track_speed() -> float:
	return (
		TRACK_SPEED
		* _boost_multiplier()
		* _level_speed_multiplier()
	)


func _current_decor_speed() -> float:
	return (
		DECOR_SPEED
		* _boost_multiplier()
		* _level_speed_multiplier()
	)


func _current_spawn_interval() -> float:
	match current_level:
		2:
			return 0.70

		3:
			return 0.58

	return SPAWN_INTERVAL


func _lane_x(lane: int) -> float:
	match lane:
		0:
			return -2.8

		1:
			return 0.0

		2:
			return 2.8

	return 0.0


func _build_world() -> void:
	_build_environment()
	_build_ground()
	_build_ground_details()
	_build_road_details()
	_build_track()
	_build_edge_guides()
	_build_horizon()
	_build_decorations()


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()

	world_environment = Environment.new()

	world_environment.background_mode = (
		Environment.BG_COLOR
	)

	world_environment.background_color = BG

	world_environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	world_environment.ambient_light_color = Color(
		0.38,
		0.48,
		0.58,
		1.0
	)

	world_environment.ambient_light_energy = 1.25

	world_env.environment = world_environment
	add_child(world_env)

	main_sun_light = DirectionalLight3D.new()

	main_sun_light.rotation_degrees = Vector3(
		-48.0,
		25.0,
		0.0
	)

	main_sun_light.light_color = Color(
		1.0,
		0.84,
		0.62,
		1.0
	)

	main_sun_light.light_energy = 1.9
	main_sun_light.shadow_enabled = true

	add_child(main_sun_light)

	camera = Camera3D.new()

	camera.position = Vector3(
		0.0,
		3.45,
		7.2
	)

	camera.fov = 70.0

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

	savanna_material = _make_material(
		SAVANNA,
		Color.BLACK
	)

	savanna_mesh.material_override = (
		savanna_material
	)

	add_child(savanna_mesh)

	# Ruta central.
	var road_mesh := MeshInstance3D.new()
	var road_plane := PlaneMesh.new()

	road_plane.size = Vector2(
		9.6,
		80.0
	)

	road_mesh.mesh = road_plane

	road_mesh.position = Vector3(
		0.0,
		0.0,
		-18.0
	)

	road_material = _make_material(
		ROAD,
		Color.BLACK
	)

	road_mesh.material_override = (
		road_material
	)

	add_child(road_mesh)


func _build_ground_details() -> void:
	for i in range(58):
		var side: float = (
			-1.0
			if i % 2 == 0
			else 1.0
		)

		var x: float = (
			side
			* rng.randf_range(
				3.4,
				12.0
			)
		)

		var z: float = rng.randf_range(
			-52.0,
			6.0
		)

		var roll: float = rng.randf()

		var detail: Node3D

		if roll < 0.36:
			detail = _create_ground_patch(
				x,
				z
			)

		elif roll < 0.58:
			detail = _create_rock(
				x,
				z
			)

		elif roll < 0.80:
			detail = _create_data_grass(
				x,
				z
			)

		else:
			detail = _create_data_trace(
				x,
				z
			)

		ground_details.append(detail)


func _create_ground_patch(
	x: float,
	z: float
) -> Node3D:
	var root := Node3D.new()

	root.position = Vector3(
		x,
		0.006,
		z
	)

	add_child(root)

	var patch := MeshInstance3D.new()
	var mesh := CylinderMesh.new()

	mesh.top_radius = rng.randf_range(
		0.40,
		1.10
	)

	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.012
	mesh.radial_segments = rng.randi_range(
		5,
		8
	)

	patch.mesh = mesh

	patch.scale.z = rng.randf_range(
		0.45,
		1.15
	)

	patch.rotation.y = rng.randf_range(
		0.0,
		TAU
	)

	patch.material_override = _make_material(
		Color(
			rng.randf_range(0.09, 0.15),
			rng.randf_range(0.17, 0.25),
			rng.randf_range(0.08, 0.13),
			1.0
		),
		Color.BLACK
	)

	root.add_child(patch)

	return root


func _create_rock(
	x: float,
	z: float
) -> Node3D:
	var root := Node3D.new()

	root.position = Vector3(
		x,
		0.10,
		z
	)

	add_child(root)

	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()

	mesh.radius = 0.22
	mesh.height = 0.44
	mesh.radial_segments = 6
	mesh.rings = 3

	rock.mesh = mesh

	rock.scale = Vector3(
		rng.randf_range(0.7, 1.5),
		rng.randf_range(0.5, 1.1),
		rng.randf_range(0.7, 1.6)
	)

	rock.rotation = Vector3(
		rng.randf_range(-0.2, 0.2),
		rng.randf_range(0.0, TAU),
		rng.randf_range(-0.2, 0.2)
	)

	rock.material_override = _make_material(
		Color(
			0.12,
			0.14,
			0.13,
			1.0
		),
		Color.BLACK
	)

	root.add_child(rock)

	return root


func _create_data_grass(
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

	var grass_material := _make_material(
		Color(
			0.06,
			0.29,
			0.16,
			1.0
		),
		Color.BLACK
	)

	for blade_index in range(3):
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()

		mesh.size = Vector3(
			0.035,
			rng.randf_range(
				0.24,
				0.48
			),
			0.025
		)

		blade.mesh = mesh

		blade.position = Vector3(
			float(blade_index - 1) * 0.08,
			mesh.size.y * 0.5,
			0.0
		)

		blade.rotation_degrees.z = (
			float(blade_index - 1) * 13.0
		)

		blade.material_override = grass_material

		root.add_child(blade)

	# Una pequeña fibra de datos ocasional.
	if rng.randf() < 0.35:
		var fiber := MeshInstance3D.new()
		var fiber_mesh := BoxMesh.new()

		fiber_mesh.size = Vector3(
			0.018,
			0.32,
			0.018
		)

		fiber.mesh = fiber_mesh
		fiber.position.y = 0.16

		fiber.material_override = _make_material(
			CYAN,
			CYAN
		)

		root.add_child(fiber)

	return root


func _create_data_trace(
	x: float,
	z: float
) -> Node3D:
	var root := Node3D.new()

	root.position = Vector3(
		x,
		0.018,
		z
	)

	add_child(root)

	var energy := _make_material(
		Color(
			0.0,
			0.20,
			0.22,
			1.0
		),
		Color(
			0.0,
			0.32,
			0.36,
			1.0
		)
	)

	var segment_count := rng.randi_range(
		2,
		4
	)

	for i in range(segment_count):
		var line := MeshInstance3D.new()
		var mesh := BoxMesh.new()

		mesh.size = Vector3(
			rng.randf_range(
				0.18,
				0.55
			),
			0.014,
			0.025
		)

		line.mesh = mesh

		line.position = Vector3(
			float(i) * 0.26,
			0.0,
			float(i % 2) * 0.12
		)

		line.rotation.y = deg_to_rad(
			rng.randf_range(
				-18.0,
				18.0
			)
		)

		line.material_override = energy

		root.add_child(line)

	return root


func _update_ground_details(
	delta: float
) -> void:
	for item in ground_details:
		item.position.z += (
			_current_track_speed() * delta
		)

		if item.position.z > 8.0:
			item.position.z -= 60.0

			var side: float = (
				-1.0
				if item.position.x < 0.0
				else 1.0
			)

			item.position.x = (
				side
				* rng.randf_range(
					5.0,
					12.0
				)
			)


func _build_road_details() -> void:
	var panel_dark := _make_material(
		Color(
			0.025,
			0.050,
			0.060,
			1.0
		),
		Color.BLACK
	)

	var panel_data := _make_material(
		Color(
			0.02,
			0.12,
			0.14,
			1.0
		),
		Color(
			0.0,
			0.22,
			0.25,
			1.0
		)
	)

	for i in range(28):
		var root := Node3D.new()

		root.position = Vector3(
			rng.randf_range(
				-4.20,
				4.20
			),
			0.014,
			4.0
			- float(i) * 1.75
			+ rng.randf_range(
				-0.35,
				0.35
			)
		)

		add_child(root)

		var plate := MeshInstance3D.new()
		var mesh := BoxMesh.new()

		mesh.size = Vector3(
			rng.randf_range(
				0.35,
				1.15
			),
			0.016,
			rng.randf_range(
				0.18,
				0.60
			)
		)

		plate.mesh = mesh

		plate.rotation.y = rng.randf_range(
			-0.10,
			0.10
		)

		if rng.randf() < 0.22:
			plate.material_override = panel_data
		else:
			plate.material_override = panel_dark

		root.add_child(plate)

		road_details.append(root)


func _update_road_details(delta: float) -> void:
	for item in road_details:
		item.position.z += (
			_current_track_speed()
			* delta
		)

		if item.position.z > 7.0:
			item.position.z -= 50.0

			item.position.x = rng.randf_range(
				-4.20,
				4.20
			)

			item.rotation.y = rng.randf_range(
				-0.12,
				0.12
			)


func _build_track() -> void:
	var marker_material := _make_material(
		Color(0.0, 0.50, 0.58, 1.0),
		CYAN
	)

	for i in range(22):
		for divider_x in [-1.40, 1.40]:
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


func _build_edge_guides() -> void:
	var edge_material := _make_material(
		Color(0.015, 0.14, 0.16, 1.0),
		Color(0.0, 0.48, 0.54, 1.0)
	)

	for i in range(22):
		for side in [-4.65, 4.65]:
			var guide := MeshInstance3D.new()
			var box := BoxMesh.new()

			box.size = Vector3(
				0.075,
				0.055,
				0.42
			)

			guide.mesh = box
			guide.material_override = edge_material

			guide.position = Vector3(
				float(side),
				0.040,
				4.0 - float(i) * 2.0
			)

			add_child(guide)
			lane_markers.append(guide)


func _update_track(delta: float) -> void:
	for marker in lane_markers:
		marker.position.z += (
			_current_track_speed() * delta
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

	horizon_sun_material = _make_material(
		YELLOW,
		Color(
			1.0,
			0.55,
			0.12,
			1.0
		)
	)

	sun.material_override = (
		horizon_sun_material
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
	# Ya no repetimos secuencias fijas.
	# Cada lateral recibe una combinación distinta
	# de acacias, torres, balizas o espacio vacío.
	for i in range(14):
		var base_z: float = (
			-4.0
			- float(i) * 4.2
		)

		for side in [-1.0, 1.0]:
			var roll: float = rng.randf()

			# Dejar algunos huecos evita el efecto túnel.
			if roll > 0.88:
				continue

			var x: float = (
				float(side)
				* rng.randf_range(
					3.7,
					5.7
				)
			)

			var z: float = (
				base_z
				+ rng.randf_range(
					-1.2,
					1.2
				)
			)

			var item: Node3D

			if roll < 0.43:
				item = _create_acacia(
					x,
					z
				)

			elif roll < 0.72:
				item = _create_tower(
					x,
					z
				)

			else:
				item = _create_data_beacon(
					x,
					z
				)

			var uniform_scale: float = (
				rng.randf_range(
					0.82,
					1.20
				)
			)

			item.scale = Vector3.ONE * uniform_scale

			item.rotation.y = deg_to_rad(
				rng.randf_range(
					-12.0,
					12.0
				)
			)

			decorations.append(item)


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

	var bark := _make_material(
		Color(0.18, 0.13, 0.075, 1.0),
		Color.BLACK
	)

	var foliage := _make_material(
		Color(0.055, 0.23, 0.14, 1.0),
		Color.BLACK
	)

	var steel := _make_material(
		Color(0.055, 0.09, 0.11, 1.0),
		Color.BLACK
	)

	var energy := _make_material(
		Color(0.0, 0.38, 0.42, 1.0),
		CYAN
	)

	# Tronco principal.
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()

	trunk_mesh.top_radius = 0.10
	trunk_mesh.bottom_radius = 0.20
	trunk_mesh.height = 2.35
	trunk_mesh.radial_segments = 8

	trunk.mesh = trunk_mesh
	trunk.position.y = 1.175
	trunk.material_override = bark

	root.add_child(trunk)

	# Núcleo tecnológico incrustado.
	var spine := MeshInstance3D.new()
	var spine_mesh := BoxMesh.new()

	spine_mesh.size = Vector3(
		0.075,
		1.35,
		0.075
	)

	spine.mesh = spine_mesh

	spine.position = Vector3(
		0.0,
		1.25,
		0.16
	)

	spine.material_override = energy

	root.add_child(spine)

	# Collar de red.
	var collar := MeshInstance3D.new()
	var collar_mesh := CylinderMesh.new()

	collar_mesh.top_radius = 0.26
	collar_mesh.bottom_radius = 0.26
	collar_mesh.height = 0.07
	collar_mesh.radial_segments = 12

	collar.mesh = collar_mesh
	collar.position.y = 1.55
	collar.material_override = steel

	root.add_child(collar)

	var collar_core := MeshInstance3D.new()
	var collar_core_mesh := CylinderMesh.new()

	collar_core_mesh.top_radius = 0.19
	collar_core_mesh.bottom_radius = 0.19
	collar_core_mesh.height = 0.085
	collar_core_mesh.radial_segments = 12

	collar_core.mesh = collar_core_mesh
	collar_core.position.y = 1.555
	collar_core.material_override = energy

	root.add_child(collar_core)

	# Ramas biomecánicas.
	for side in [-1.0, 1.0]:
		var branch := MeshInstance3D.new()
		var branch_mesh := CylinderMesh.new()

		branch_mesh.top_radius = 0.055
		branch_mesh.bottom_radius = 0.09
		branch_mesh.height = 1.25
		branch_mesh.radial_segments = 7

		branch.mesh = branch_mesh

		branch.position = Vector3(
			float(side) * 0.38,
			2.0,
			0.0
		)

		branch.rotation_degrees.z = (
			float(side) * 56.0
		)

		branch.material_override = bark

		root.add_child(branch)

	# Copa principal en tres masas para leer mejor como acacia.
	for data in [
		[-0.72, 2.47, 1.28],
		[0.0, 2.60, 1.55],
		[0.72, 2.47, 1.28]
	]:
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()

		crown_mesh.radius = 0.65
		crown_mesh.height = 1.30
		crown_mesh.radial_segments = 12
		crown_mesh.rings = 6

		crown.mesh = crown_mesh

		crown.position = Vector3(
			float(data[0]),
			float(data[1]),
			0.0
		)

		crown.scale = Vector3(
			float(data[2]),
			0.28,
			0.70
		)

		crown.material_override = foliage

		root.add_child(crown)

	# Nodo de comunicaciones.
	var node_light := MeshInstance3D.new()
	var node_mesh := SphereMesh.new()

	node_mesh.radius = 0.12
	node_mesh.height = 0.24
	node_mesh.radial_segments = 10
	node_mesh.rings = 5

	node_light.mesh = node_mesh

	node_light.position = Vector3(
		0.0,
		2.12,
		0.32
	)

	node_light.material_override = energy

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

	var dark := _make_material(
		Color(0.035, 0.065, 0.085, 1.0),
		Color.BLACK
	)

	var steel := _make_material(
		Color(0.12, 0.18, 0.21, 1.0),
		Color.BLACK
	)

	var energy := _make_material(
		Color(0.0, 0.28, 0.34, 1.0),
		CYAN
	)

	# Base.
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()

	base_mesh.size = Vector3(
		0.90,
		0.22,
		0.90
	)

	base.mesh = base_mesh

	base.position.y = 0.11
	base.material_override = dark

	root.add_child(base)

	# Columna central.
	var column := MeshInstance3D.new()
	var column_mesh := BoxMesh.new()

	column_mesh.size = Vector3(
		0.52,
		2.85,
		0.52
	)

	column.mesh = column_mesh

	column.position.y = 1.53
	column.material_override = dark

	root.add_child(column)

	# Núcleo luminoso.
	var core := MeshInstance3D.new()
	var core_mesh := BoxMesh.new()

	core_mesh.size = Vector3(
		0.15,
		1.85,
		0.54
	)

	core.mesh = core_mesh

	core.position = Vector3(
		0.0,
		1.55,
		0.05
	)

	core.material_override = energy

	root.add_child(core)

	# Dos placas laterales.
	for side in [-1.0, 1.0]:
		var fin := MeshInstance3D.new()
		var fin_mesh := BoxMesh.new()

		fin_mesh.size = Vector3(
			0.18,
			1.55,
			0.34
		)

		fin.mesh = fin_mesh

		fin.position = Vector3(
			float(side) * 0.36,
			1.55,
			0.0
		)

		fin.rotation_degrees.z = (
			float(side) * 7.0
		)

		fin.material_override = steel

		root.add_child(fin)

	# Cabezal.
	var crown := MeshInstance3D.new()
	var crown_mesh := BoxMesh.new()

	crown_mesh.size = Vector3(
		1.15,
		0.18,
		0.62
	)

	crown.mesh = crown_mesh

	crown.position.y = 3.0
	crown.material_override = steel

	root.add_child(crown)

	# Antena.
	var antenna := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()

	antenna_mesh.top_radius = 0.025
	antenna_mesh.bottom_radius = 0.055
	antenna_mesh.height = 1.15
	antenna_mesh.radial_segments = 8

	antenna.mesh = antenna_mesh
	antenna.position.y = 3.65
	antenna.material_override = steel

	root.add_child(antenna)

	# Baliza superior.
	var beacon := MeshInstance3D.new()
	var beacon_mesh := SphereMesh.new()

	beacon_mesh.radius = 0.105
	beacon_mesh.height = 0.21

	beacon.mesh = beacon_mesh
	beacon.position.y = 4.20
	beacon.material_override = energy

	root.add_child(beacon)

	return root


# ============================================================
# BALIZAS DE DATOS
# ============================================================

func _create_data_beacon(
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

	var dark := _make_material(
		Color(0.02, 0.055, 0.070, 1.0),
		Color.BLACK
	)

	var energy := _make_material(
		Color(0.0, 0.42, 0.48, 1.0),
		CYAN
	)

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()

	stem_mesh.top_radius = 0.035
	stem_mesh.bottom_radius = 0.055
	stem_mesh.height = 1.05
	stem_mesh.radial_segments = 8

	stem.mesh = stem_mesh
	stem.position.y = 0.525
	stem.material_override = dark

	root.add_child(stem)

	var outer := MeshInstance3D.new()
	var outer_mesh := CylinderMesh.new()

	outer_mesh.top_radius = 0.30
	outer_mesh.bottom_radius = 0.30
	outer_mesh.height = 0.045
	outer_mesh.radial_segments = 16

	outer.mesh = outer_mesh
	outer.position.y = 1.10
	outer.material_override = energy

	root.add_child(outer)

	# Centro oscuro para simular anillo.
	var inner := MeshInstance3D.new()
	var inner_mesh := CylinderMesh.new()

	inner_mesh.top_radius = 0.19
	inner_mesh.bottom_radius = 0.19
	inner_mesh.height = 0.052
	inner_mesh.radial_segments = 16

	inner.mesh = inner_mesh
	inner.position.y = 1.105
	inner.material_override = dark

	root.add_child(inner)

	var pulse := MeshInstance3D.new()
	var pulse_mesh := SphereMesh.new()

	pulse_mesh.radius = 0.09
	pulse_mesh.height = 0.18

	pulse.mesh = pulse_mesh
	pulse.position.y = 1.14
	pulse.material_override = energy

	root.add_child(pulse)

	return root


func _update_decorations(delta: float) -> void:
	for item in decorations:
		item.position.z += (
			_current_decor_speed() * delta
		)

		if item.position.z > 8.0:
			item.position.z -= rng.randf_range(
				48.0,
				58.0
			)

			var side: float = (
				-1.0
				if item.position.x < 0.0
				else 1.0
			)

			item.position.x = (
				side
				* rng.randf_range(
					3.7,
					5.7
				)
			)

			var uniform_scale: float = (
				rng.randf_range(
					0.82,
					1.20
				)
			)

			item.scale = (
				Vector3.ONE
				* uniform_scale
			)

			item.rotation.y = deg_to_rad(
				rng.randf_range(
					-14.0,
					14.0
				)
			)


# ============================================================
# PICKUPS / MALWARE
# ============================================================

func _update_spawning(delta: float) -> void:
	spawn_elapsed += delta

	if spawn_elapsed < _current_spawn_interval():
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

	var malware_chance: float = 0.14

	match current_level:
		2:
			malware_chance = 0.20

		3:
			malware_chance = 0.26

	var shield_chance := 0.18
	var boost_chance := 0.10

	var packet_chance: float = (
		1.0
		- malware_chance
		- shield_chance
		- boost_chance
	)

	if roll < packet_chance:
		kind = "packet"

	elif roll < (
		packet_chance
		+ shield_chance
	):
		kind = "shield"

	elif roll < (
		packet_chance
		+ shield_chance
		+ boost_chance
	):
		kind = "boost"

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

	elif kind == "boost":
		var boost_mesh := CylinderMesh.new()

		boost_mesh.top_radius = 0.12
		boost_mesh.bottom_radius = 0.24
		boost_mesh.height = 0.68
		boost_mesh.radial_segments = 6

		mesh_resource = boost_mesh

		material = _make_material(
			Color(
				0.68,
				0.44,
				0.04,
				1.0
			),
			YELLOW
		)

		visual.rotation_degrees = Vector3(
			90.0,
			0.0,
			0.0
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
			_current_track_speed()
			* delta
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
			< 0.68
		)

		if close_z and close_x:
			var kind: String = str(
				item.get_meta(
					"kind",
					"packet"
				)
			)

			var malware_jumped: bool = (
				kind == "malware"
				and player.position.y
				>= JUMP_MALWARE_CLEARANCE
			)

			if malware_jumped:
				_show_event_feedback(
					"↑ MALWARE SALTADO",
					CYAN,
					0.70
				)

				_set_status(
					"EVASIÓN LIMPIA // MALWARE",
					0.9
				)

			else:
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

			_check_score_milestone()

			_play_safe_sfx(1.0)

			_show_event_feedback(
				"✓ PAQUETE SEGURO  +10",
				GREEN,
				0.85
			)

			_set_status(
				"PAQUETE SEGURO // +%d"
				% PACKET_SCORE,
				1.2
			)

		"shield":
			_play_safe_sfx(1.22)

			_show_event_feedback(
				"🛡 ESCUDO DE RED  +20",
				CYAN,
				1.35
			)

			shield = mini(
				100,
				shield + SHIELD_PICKUP
			)

			_set_status(
				"FIREWALL REFORZADO // +%d"
				% SHIELD_PICKUP,
				1.5
			)

		"boost":
			boost_remaining = BOOST_DURATION

			_play_safe_sfx(1.38)

			_show_event_feedback(
				"⚡ BOOST DE RED",
				YELLOW,
				1.30
			)

			_set_status(
				"⚡ BOOST DE RED // 5 SEG",
				1.8
			)

		"malware":
			sfx_malware.pitch_scale = 1.0
			sfx_malware.play()

			_show_event_feedback(
				"⚠ MALWARE  -25 ESCUDO",
				RED,
				1.45
			)

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


func _update_boost(delta: float) -> void:
	if boost_remaining <= 0.0:
		boost_remaining = 0.0
		return

	boost_remaining = maxf(
		0.0,
		boost_remaining - delta
	)

	_update_hud()


func _update_level_visuals(
	delta: float
) -> void:
	if (
		world_environment == null
		or savanna_material == null
		or road_material == null
		or horizon_sun_material == null
	):
		return

	var target_bg := Color(
		0.015,
		0.035,
		0.060,
		1.0
	)

	var target_ambient := Color(
		0.38,
		0.48,
		0.58,
		1.0
	)

	var target_savanna := Color(
		0.11,
		0.22,
		0.13,
		1.0
	)

	var target_road := Color(
		0.035,
		0.075,
		0.085,
		1.0
	)

	var target_sun := YELLOW

	var target_light := Color(
		1.0,
		0.84,
		0.62,
		1.0
	)

	var target_ambient_energy: float = 1.25
	var target_light_energy: float = 1.90

	match current_level:
		2:
			# Infection Front:
			# ocaso cálido, suelo enfermo,
			# tecnología bajo tensión.
			target_bg = Color(
				0.085,
				0.025,
				0.045,
				1.0
			)

			target_ambient = Color(
				0.52,
				0.25,
				0.18,
				1.0
			)

			target_savanna = Color(
				0.19,
				0.12,
				0.075,
				1.0
			)

			target_road = Color(
				0.085,
				0.045,
				0.052,
				1.0
			)

			target_sun = Color(
				1.0,
				0.36,
				0.10,
				1.0
			)

			target_light = Color(
				1.0,
				0.42,
				0.18,
				1.0
			)

			target_ambient_energy = 1.12
			target_light_energy = 2.10

		3:
			# Redline Savanna:
			# noche tecnológica / infección crítica.
			target_bg = Color(
				0.008,
				0.012,
				0.040,
				1.0
			)

			target_ambient = Color(
				0.19,
				0.24,
				0.38,
				1.0
			)

			target_savanna = Color(
				0.035,
				0.075,
				0.080,
				1.0
			)

			target_road = Color(
				0.030,
				0.045,
				0.070,
				1.0
			)

			target_sun = Color(
				0.14,
				0.44,
				0.62,
				1.0
			)

			target_light = Color(
				0.28,
				0.56,
				0.88,
				1.0
			)

			target_ambient_energy = 0.92
			target_light_energy = 1.30

	var blend: float = clampf(
		delta * 1.45,
		0.0,
		1.0
	)

	world_environment.background_color = (
		world_environment.background_color.lerp(
			target_bg,
			blend
		)
	)

	world_environment.ambient_light_color = (
		world_environment.ambient_light_color.lerp(
			target_ambient,
			blend
		)
	)

	world_environment.ambient_light_energy = lerpf(
		world_environment.ambient_light_energy,
		target_ambient_energy,
		blend
	)

	savanna_material.albedo_color = (
		savanna_material.albedo_color.lerp(
			target_savanna,
			blend
		)
	)

	road_material.albedo_color = (
		road_material.albedo_color.lerp(
			target_road,
			blend
		)
	)

	horizon_sun_material.albedo_color = (
		horizon_sun_material.albedo_color.lerp(
			target_sun,
			blend
		)
	)

	horizon_sun_material.emission = (
		horizon_sun_material.emission.lerp(
			target_sun,
			blend
		)
	)

	main_sun_light.light_color = (
		main_sun_light.light_color.lerp(
			target_light,
			blend
		)
	)

	main_sun_light.light_energy = lerpf(
		main_sun_light.light_energy,
		target_light_energy,
		blend
	)


func _update_level_progression() -> void:
	var target_level := 1

	if score >= LEVEL_3_SCORE:
		target_level = 3

	elif score >= LEVEL_2_SCORE:
		target_level = 2

	if target_level == current_level:
		return

	current_level = target_level

	if player.has_method("celebrate"):
		player.call(
			"celebrate",
			1.7
		)

	_apply_level_change()


func _check_score_milestone() -> void:
	var milestone: int = (
		floori(
			float(score)
			/ 100.0
		)
		* 100
	)

	if (
		milestone < 100
		or milestone <= last_milestone_score
	):
		return

	last_milestone_score = milestone

	if player.has_method("celebrate"):
		player.call(
			"celebrate",
			0.85
		)


func _apply_level_change() -> void:
	var next_music: AudioStream = MUSIC_LEVEL1

	match current_level:
		1:
			level_label.text = (
				"NIVEL 01 // SABANA CONECTADA"
			)

			level_label.add_theme_color_override(
				"font_color",
				GREEN
			)

			next_music = MUSIC_LEVEL1

		2:
			level_label.text = (
				"NIVEL 02 // FRENTE DE INFECCIÓN"
			)

			level_label.add_theme_color_override(
				"font_color",
				YELLOW
			)

			next_music = MUSIC_LEVEL2

			_set_status(
				"⚠ ACTIVIDAD HOSTIL EN AUMENTO",
				2.5
			)

		3:
			level_label.text = (
				"NIVEL 03 // REDLINE SAVANNA"
			)

			level_label.add_theme_color_override(
				"font_color",
				RED
			)

			next_music = MUSIC_LEVEL3

			_set_status(
				"⚠ RED EN ESTADO CRÍTICO",
				2.5
			)

	if (
		is_instance_valid(music_player)
		and music_player.stream != next_music
	):
		music_player.stream = next_music
		music_player.play()


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

	var ui_theme := Theme.new()
	ui_theme.default_font = FONT_UI
	ui_root.theme = ui_theme

	_build_brand_splash()
	_build_cinematic_overlay()
	_build_hud()
	_build_menu()
	_build_info()
	_build_game_over()
	_build_ui_motion_fx()


func _style_title(
	label: Label
) -> void:
	label.add_theme_font_override(
		"font",
		FONT_UI_ITALIC
	)

	label.add_theme_color_override(
		"font_outline_color",
		Color(
			CYAN.r,
			CYAN.g,
			CYAN.b,
			0.55
		)
	)

	label.add_theme_constant_override(
		"outline_size",
		2
	)

	animated_titles.append(label)


func _style_italic(
	label: Label
) -> void:
	label.add_theme_font_override(
		"font",
		FONT_UI_ITALIC
	)


func _style_telemetry(
	label: Label
) -> void:
	label.add_theme_font_override(
		"font",
		FONT_TELEMETRY
	)


func _style_button(
	button: Button
) -> void:
	button.add_theme_font_override(
		"font",
		FONT_UI
	)


func _build_ui_motion_fx() -> void:
	scan_line = ColorRect.new()

	scan_line.name = "CyberScanLine"

	scan_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	scan_line.set_anchors_preset(
		Control.PRESET_TOP_WIDE
	)

	scan_line.offset_top = 0.0
	scan_line.offset_bottom = 3.0

	scan_line.color = Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.12
	)

	ui_root.add_child(scan_line)

	scan_line.move_to_front()


func _update_ui_motion(
	delta: float
) -> void:
	ui_motion_elapsed += delta

	# --------------------------------------------------------
	# Respiración de títulos
	# --------------------------------------------------------

	var pulse: float = (
		0.5
		+ 0.5
		* sin(
			ui_motion_elapsed * 2.6
		)
	)

	for title in animated_titles:
		if not is_instance_valid(title):
			continue

		title.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.86
			+ pulse * 0.14
		)

		title.add_theme_color_override(
			"font_outline_color",
			Color(
				CYAN.r,
				CYAN.g,
				CYAN.b,
				0.22
				+ pulse * 0.58
			)
		)

		title.add_theme_constant_override(
			"outline_size",
			1
			+ int(
				round(
					pulse * 2.0
				)
			)
		)

	# --------------------------------------------------------
	# Botones respirando con desfase
	# --------------------------------------------------------

	for i in range(
		animated_buttons.size()
	):
		var button := animated_buttons[i]

		if not is_instance_valid(button):
			continue

		var button_pulse: float = (
			0.5
			+ 0.5
			* sin(
				ui_motion_elapsed * 2.1
				+ float(i) * 0.55
			)
		)

		button.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.88
			+ button_pulse * 0.12
		)

	# --------------------------------------------------------
	# Parpadeo tipo terminal
	# --------------------------------------------------------

	if is_instance_valid(
		firewall_label
	):
		var terminal_phase: float = fmod(
			ui_motion_elapsed,
			1.55
		)

		var terminal_alpha: float = 1.0

		if terminal_phase < 0.065:
			terminal_alpha = 0.54

		firewall_label.modulate.a = (
			terminal_alpha
		)

	# --------------------------------------------------------
	# Scan line
	# --------------------------------------------------------

	if not is_instance_valid(
		scan_line
	):
		return

	var scan_speed: float = 155.0

	var scan_alpha: float = (
		0.055
		+ pulse * 0.040
	)

	# Durante la intro hacemos tres barridos más visibles.
	if (
		is_instance_valid(
			brand_overlay
		)
		and brand_overlay.visible
		and intro_scan_passes > 0
	):
		scan_speed = 720.0
		scan_alpha = 0.25

	scan_y += (
		scan_speed * delta
	)

	var screen_height: float = (
		get_viewport().get_visible_rect().size.y
	)

	if scan_y > screen_height:
		scan_y = -8.0

		if (
			is_instance_valid(
				brand_overlay
			)
			and brand_overlay.visible
			and intro_scan_passes > 0
		):
			intro_scan_passes -= 1

	scan_line.position.y = scan_y

	var scan_color := CYAN

	match current_level:
		2:
			scan_color = YELLOW

		3:
			scan_color = RED

	scan_line.color = Color(
		scan_color.r,
		scan_color.g,
		scan_color.b,
		scan_alpha
	)


func _build_brand_splash() -> void:
	brand_overlay = ColorRect.new()

	brand_overlay.color = Color(
		0.005,
		0.015,
		0.025,
		1.0
	)

	brand_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ui_root.add_child(brand_overlay)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	brand_overlay.add_child(center)

	var box := VBoxContainer.new()

	box.custom_minimum_size = Vector2(
		600.0,
		360.0
	)

	box.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	center.add_child(box)

	var logo := TextureRect.new()

	logo.texture = RHYNUS_SPLASH

	logo.custom_minimum_size = Vector2(
		560.0,
		250.0
	)

	logo.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	box.add_child(logo)


	brand_overlay.hide()


func _show_brand_splash() -> void:
	intro_scan_passes = 3
	scan_y = -8.0

	menu_overlay.hide()
	info_overlay.hide()
	game_over_overlay.hide()

	hud.hide()
	pause_button.hide()

	if is_instance_valid(
		cinematic_overlay
	):
		cinematic_overlay.hide()

	brand_overlay.show()


# ============================================================
# CINEMATIC INTRO
# ============================================================

func _build_cinematic_overlay() -> void:
	cinematic_overlay = Control.new()

	cinematic_overlay.name = (
		"CinematicIntro"
	)

	cinematic_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ui_root.add_child(
		cinematic_overlay
	)

	# Letterbox superior.
	var top_bar := ColorRect.new()

	top_bar.color = Color(
		0.0,
		0.005,
		0.012,
		0.88
	)

	top_bar.set_anchors_preset(
		Control.PRESET_TOP_WIDE
	)

	top_bar.offset_bottom = 72.0

	cinematic_overlay.add_child(
		top_bar
	)

	# Letterbox inferior.
	var bottom_bar := ColorRect.new()

	bottom_bar.color = Color(
		0.0,
		0.005,
		0.012,
		0.88
	)

	bottom_bar.set_anchors_preset(
		Control.PRESET_BOTTOM_WIDE
	)

	bottom_bar.offset_top = -88.0

	cinematic_overlay.add_child(
		bottom_bar
	)

	# Título cinematográfico.
	cinematic_title = Label.new()

	_style_title(
		cinematic_title
	)

	cinematic_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	cinematic_title.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	cinematic_title.offset_left = -420.0
	cinematic_title.offset_top = 88.0
	cinematic_title.offset_right = 420.0
	cinematic_title.offset_bottom = 136.0

	cinematic_title.add_theme_font_size_override(
		"font_size",
		31
	)

	cinematic_title.add_theme_color_override(
		"font_color",
		CYAN
	)

	cinematic_overlay.add_child(
		cinematic_title
	)

	# Subtítulo.
	cinematic_subtitle = Label.new()

	_style_italic(
		cinematic_subtitle
	)

	cinematic_subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	cinematic_subtitle.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	cinematic_subtitle.offset_left = -440.0
	cinematic_subtitle.offset_top = 137.0
	cinematic_subtitle.offset_right = 440.0
	cinematic_subtitle.offset_bottom = 172.0

	cinematic_subtitle.add_theme_font_size_override(
		"font_size",
		17
	)

	cinematic_subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.93,
			0.96,
			1.0
		)
	)

	cinematic_overlay.add_child(
		cinematic_subtitle
	)

	# Campaña / logro.
	cinematic_campaign = Label.new()

	_style_telemetry(
		cinematic_campaign
	)

	cinematic_campaign.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	cinematic_campaign.offset_left = 24.0
	cinematic_campaign.offset_top = -66.0
	cinematic_campaign.offset_right = 560.0
	cinematic_campaign.offset_bottom = -24.0

	cinematic_campaign.add_theme_font_size_override(
		"font_size",
		15
	)

	cinematic_campaign.add_theme_color_override(
		"font_color",
		GREEN
	)

	cinematic_overlay.add_child(
		cinematic_campaign
	)

	# Botón para saltar.
	cinematic_skip_button = _make_button(
		"SALTAR INTRO"
	)

	cinematic_skip_button.custom_minimum_size = Vector2(
		170.0,
		40.0
	)

	cinematic_skip_button.add_theme_font_size_override(
		"font_size",
		15
	)

	cinematic_skip_button.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	cinematic_skip_button.offset_left = -194.0
	cinematic_skip_button.offset_top = 16.0
	cinematic_skip_button.offset_right = -18.0
	cinematic_skip_button.offset_bottom = 58.0

	cinematic_skip_button.pressed.connect(
		_finish_cinematic_intro
	)

	cinematic_overlay.add_child(
		cinematic_skip_button
	)

	var hint := Label.new()

	_style_telemetry(
		hint
	)

	hint.text = (
		"ESC / ENTER // SALTAR INTRO"
	)

	hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hint.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)

	hint.offset_left = -260.0
	hint.offset_top = -58.0
	hint.offset_right = 260.0
	hint.offset_bottom = -24.0

	hint.add_theme_color_override(
		"font_color",
		Color(
			0.50,
			0.78,
			0.82,
			1.0
		)
	)

	cinematic_overlay.add_child(
		hint
	)

	cinematic_overlay.hide()


func _start_cinematic_intro() -> void:
	game_state = GameState.INTRO

	cinematic_elapsed = 0.0
	cinematic_phase = -1

	brand_overlay.hide()
	menu_overlay.hide()
	info_overlay.hide()
	game_over_overlay.hide()

	hud.hide()
	pause_button.hide()

	cinematic_overlay.show()

	player.visible = true

	player.position = Vector3(
		0.0,
		0.0,
		0.45
	)

	player.rotation = Vector3(
		0.0,
		PI,
		0.0
	)

	if player.has_method(
		"set_running"
	):
		player.call(
			"set_running",
			true
		)

	current_level = 1
	boost_remaining = 0.0

	camera.position = Vector3(
		4.2,
		4.20,
		-4.7
	)

	camera.fov = 58.0

	camera.look_at(
		player.position
		+ Vector3(
			0.0,
			1.55,
			0.0
		),
		Vector3.UP
	)

	if is_instance_valid(
		music_player
	):
		music_player.stream = (
			MUSIC_LEVEL1
		)

		music_player.volume_db = -9.0
		music_player.play()

	_set_cinematic_phase(0)


func _update_cinematic_intro(
	delta: float
) -> void:
	cinematic_elapsed += delta

	# --------------------------------------------------------
	# ESCENARIO EN MOVIMIENTO
	# --------------------------------------------------------

	var world_factor: float = 0.74

	if cinematic_phase == 3:
		world_factor = 1.08

	_update_track(
		delta * world_factor
	)

	_update_ground_details(
		delta * world_factor
	)

	_update_road_details(
		delta * world_factor
	)

	_update_decorations(
		delta * world_factor
	)

	_update_level_visuals(delta)

	# --------------------------------------------------------
	# ATMOSFERA
	# Fondo oscuro pero nunca negro plano.
	# --------------------------------------------------------

	if world_environment != null:
		var atmosphere_pulse: float = (
			0.5
			+ 0.5
			* sin(
				cinematic_elapsed * 0.72
			)
		)

		var cinematic_bg := Color(
			0.015,
			0.055,
			0.075,
			1.0
		)

		match cinematic_phase:
			0, 1, 2:
				cinematic_bg = Color(
					0.012,
					0.060
					+ atmosphere_pulse * 0.018,
					0.082
					+ atmosphere_pulse * 0.020,
					1.0
				)

			3:
				cinematic_bg = Color(
					0.095,
					0.038,
					0.030,
					1.0
				)

			4:
				cinematic_bg = Color(
					0.045,
					0.010,
					0.032,
					1.0
				)

			5:
				cinematic_bg = Color(
					0.008,
					0.055,
					0.078,
					1.0
				)

		world_environment.background_color = (
			world_environment.background_color.lerp(
				cinematic_bg,
				clampf(
					delta * 2.4,
					0.0,
					1.0
				)
			)
		)

	# --------------------------------------------------------
	# RITMO DE AUDIO SIN NUEVO ASSET
	# Ligero pulso de mezcla sincronizado con pisadas.
	# --------------------------------------------------------

	if (
		is_instance_valid(music_player)
		and music_player.playing
	):
		var step_wave: float = absf(
			sin(
				cinematic_elapsed
				* 8.2
			)
		)

		var step_hit: float = pow(
			step_wave,
			7.0
		)

		if cinematic_phase < 5:
			music_player.volume_db = (
				-10.2
				+ step_hit * 2.4
			)

			music_player.pitch_scale = (
				1.0
				+ step_hit * 0.012
			)

		else:
			music_player.volume_db = lerpf(
				music_player.volume_db,
				-8.5,
				clampf(
					delta * 2.0,
					0.0,
					1.0
				)
			)

			music_player.pitch_scale = lerpf(
				music_player.pitch_scale,
				1.0,
				clampf(
					delta * 3.0,
					0.0,
					1.0
				)
			)

	# --------------------------------------------------------
	# RINO
	# --------------------------------------------------------

	player.position.x = (
		sin(
			cinematic_elapsed * 0.72
		)
		* 0.14
	)

	player.position.z = 0.45

	if cinematic_phase < 5:
		player.rotation.y = (
			PI
			+ sin(
				cinematic_elapsed * 0.58
			)
			* deg_to_rad(4.0)
		)

	# --------------------------------------------------------
	# OBJETO DE PREVIEW
	# --------------------------------------------------------

	if is_instance_valid(
		cinematic_demo_item
	):
		cinematic_demo_item.rotation.y += (
			delta * 2.4
		)

		cinematic_demo_item.position.y = (
			1.22
			+ sin(
				cinematic_elapsed * 3.0
			)
			* 0.10
		)

	# --------------------------------------------------------
	# FASE
	# --------------------------------------------------------

	var new_phase: int = 0

	if cinematic_elapsed >= 13.4:
		new_phase = 5

	elif cinematic_elapsed >= 10.3:
		new_phase = 4

	elif cinematic_elapsed >= 7.5:
		new_phase = 3

	elif cinematic_elapsed >= 5.0:
		new_phase = 2

	elif cinematic_elapsed >= 2.5:
		new_phase = 1

	if new_phase != cinematic_phase:
		_set_cinematic_phase(
			new_phase
		)

	# Progreso independiente dentro del plano.
	var phase_start: float = 0.0
	var phase_end: float = 2.5

	match cinematic_phase:
		0:
			phase_start = 0.0
			phase_end = 2.5

		1:
			phase_start = 2.5
			phase_end = 5.0

		2:
			phase_start = 5.0
			phase_end = 7.5

		3:
			phase_start = 7.5
			phase_end = 10.3

		4:
			phase_start = 10.3
			phase_end = 13.4

		5:
			phase_start = 13.4
			phase_end = CINEMATIC_DURATION

	var phase_t: float = clampf(
		(
			cinematic_elapsed
			- phase_start
		)
		/ maxf(
			0.001,
			phase_end
			- phase_start
		),
		0.0,
		1.0
	)

	# --------------------------------------------------------
	# CAMARA
	# --------------------------------------------------------

	var target_camera := Vector3(
		4.2,
		4.20,
		-4.7
	)

	var target_fov: float = 58.0

	match cinematic_phase:
		0:
			# Frontal 3/4 que se aproxima.
			target_camera = Vector3(
				lerpf(
					4.20,
					2.10,
					phase_t
				),
				lerpf(
					4.20,
					2.15,
					phase_t
				),
				lerpf(
					-4.70,
					-3.45,
					phase_t
				)
			)

			target_fov = lerpf(
				58.0,
				53.0,
				phase_t
			)

		1:
			# Barrido lateral alrededor del Rino.
			target_camera = Vector3(
				-4.9
				+ sin(
					phase_t * PI
				)
				* 1.10,
				2.12
				+ sin(
					phase_t * PI
				)
				* 0.28,
				lerpf(
					1.20,
					-1.20,
					phase_t
				)
			)

			target_fov = 61.0

		2:
			# Persecución trasera que cruza el eje.
			target_camera = Vector3(
				lerpf(
					2.60,
					-1.55,
					phase_t
				),
				lerpf(
					3.00,
					2.45,
					phase_t
				),
				lerpf(
					5.80,
					4.55,
					phase_t
				)
			)

			target_fov = lerpf(
				65.0,
				70.0,
				phase_t
			)

		3:
			# BOOST: cámara se lanza hacia él.
			target_camera = Vector3(
				lerpf(
					-1.80,
					0.20,
					phase_t
				),
				lerpf(
					1.85,
					1.48,
					phase_t
				),
				lerpf(
					4.35,
					2.85,
					phase_t
				)
			)

			target_fov = lerpf(
				74.0,
				82.0,
				phase_t
			)

		4:
			# Redline: media órbita frontal.
			target_camera = Vector3(
				lerpf(
					-4.10,
					4.20,
					phase_t
				),
				2.20
				+ sin(
					phase_t * PI
				)
				* 0.35,
				-4.25
				+ sin(
					phase_t * PI
				)
				* 0.70
			)

			target_fov = lerpf(
				62.0,
				56.0,
				phase_t
			)

		5:
			# Hero shot final:
			# dolly directo a rostro y pulgar.
			target_camera = Vector3(
				lerpf(
					0.75,
					0.28,
					phase_t
				),
				lerpf(
					2.30,
					1.93,
					phase_t
				),
				lerpf(
					-5.10,
					-2.85,
					phase_t
				)
			)

			target_fov = lerpf(
				55.0,
				46.0,
				phase_t
			)

	var camera_blend: float = clampf(
		delta * 3.0,
		0.0,
		1.0
	)

	camera.position = camera.position.lerp(
		target_camera,
		camera_blend
	)

	camera.fov = lerpf(
		camera.fov,
		target_fov,
		camera_blend
	)

	var look_height: float = 1.55

	if cinematic_phase == 5:
		look_height = 1.72

	camera.look_at(
		player.position
		+ Vector3(
			0.0,
			look_height,
			0.0
		),
		Vector3.UP
	)

	if cinematic_elapsed >= CINEMATIC_DURATION:
		_finish_cinematic_intro()


func _set_cinematic_phase(
	phase: int
) -> void:
	cinematic_phase = phase

	if player.has_method(
		"set_hero_pose"
	):
		player.call(
			"set_hero_pose",
			phase == 5
		)

	if player.has_method(
		"set_running"
	):
		player.call(
			"set_running",
			phase != 5
		)

	var demo_kind := ""

	match phase:
		0:
			current_level = 1
			boost_remaining = 0.0

			cinematic_title.text = (
				"PACKET RUNNER 3D"
			)

			cinematic_subtitle.text = (
				"DEFENDER LA RED EMPIEZA "
				+ "POR LEER EL CAMINO"
			)

			cinematic_campaign.text = (
				"CAMPAÑA 01 / 03  //  "
				+ "SABANA CONECTADA"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				CYAN
			)

			_set_cinematic_music(
				MUSIC_LEVEL1
			)

		1:
			demo_kind = "packet"

			cinematic_title.text = (
				"PAQUETES SEGUROS"
			)

			cinematic_subtitle.text = (
				"CAPTURA DATOS LEGITIMOS  //  +10"
			)

			cinematic_campaign.text = (
				"LOGRO PREVIEW  //  FLUJO SEGURO"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				GREEN
			)

		2:
			demo_kind = "shield"

			cinematic_title.text = (
				"ESCUDO DE RED"
			)

			cinematic_subtitle.text = (
				"REFUERZA EL FIREWALL  //  +20"
			)

			cinematic_campaign.text = (
				"DEFENSA ACTIVA  //  "
				+ "PROTEGE EL NUCLEO"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				CYAN
			)

			if player.has_method(
				"celebrate"
			):
				player.call(
					"celebrate",
					0.85
				)

		3:
			current_level = 2
			boost_remaining = 999.0
			demo_kind = "boost"

			cinematic_title.text = (
				"BOOST DE RED"
			)

			cinematic_subtitle.text = (
				"MAS VELOCIDAD  //  "
				+ "MENOS TIEMPO PARA REACCIONAR"
			)

			cinematic_campaign.text = (
				"CAMPAÑA 02 / 03  //  "
				+ "FRENTE DE INFECCION"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				YELLOW
			)

			_set_cinematic_music(
				MUSIC_LEVEL2
			)

		4:
			current_level = 3
			boost_remaining = 0.0
			demo_kind = "malware"

			cinematic_title.text = (
				"REDLINE SAVANNA"
			)

			cinematic_subtitle.text = (
				"MALWARE ACTIVO  //  "
				+ "FIREWALL EN ESTADO CRITICO"
			)

			cinematic_campaign.text = (
				"CAMPAÑA 03 / 03  //  "
				+ "SOBREVIVE A LA RED"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				RED
			)

			_set_cinematic_music(
				MUSIC_LEVEL3
			)

			if player.has_method(
				"celebrate"
			):
				player.call(
					"celebrate",
					1.15
				)

		5:
			# Restauramos la sabana mientras hacemos
			# el plano heroico final.
			current_level = 1
			boost_remaining = 0.0

			cinematic_title.text = (
				"PACKET RUNNER 3D"
			)

			cinematic_subtitle.text = (
				"LISTO PARA CORRER  //  "
				+ "LA RED TE ESPERA"
			)

			cinematic_campaign.text = (
				"MISION LISTA  //  "
				+ "A RHYNUS PROJECT"
			)

			cinematic_title.add_theme_color_override(
				"font_color",
				CYAN
			)

			_set_cinematic_music(
				MUSIC_LEVEL1
			)

			if player.has_method(
				"celebrate"
			):
				player.call(
					"celebrate",
					2.0
				)

	_set_cinematic_demo(
		demo_kind
	)

	# Golpe visual al cambiar de capítulo.
	if is_instance_valid(
		cinematic_text_tween
	):
		cinematic_text_tween.kill()

	cinematic_subtitle.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	cinematic_campaign.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	cinematic_title.scale = Vector2(
		0.94,
		0.94
	)

	cinematic_text_tween = create_tween()

	cinematic_text_tween.set_parallel(
		true
	)

	cinematic_text_tween.tween_property(
		cinematic_subtitle,
		"modulate:a",
		1.0,
		0.24
	)

	cinematic_text_tween.tween_property(
		cinematic_campaign,
		"modulate:a",
		1.0,
		0.30
	)

	cinematic_text_tween.tween_property(
		cinematic_title,
		"scale",
		Vector2.ONE,
		0.28
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _set_cinematic_music(
	stream: AudioStream
) -> void:
	if not is_instance_valid(
		music_player
	):
		return

	if music_player.stream == stream:
		if not music_player.playing:
			music_player.play()

		return

	music_player.stream = stream
	music_player.play()


func _set_cinematic_demo(
	kind: String
) -> void:
	if is_instance_valid(
		cinematic_demo_item
	):
		cinematic_demo_item.queue_free()

		cinematic_demo_item = null

	if kind.is_empty():
		return

	cinematic_demo_item = Node3D.new()

	cinematic_demo_item.name = (
		"CinematicDemoItem"
	)

	cinematic_demo_item.position = Vector3(
		1.40,
		1.22,
		-1.20
	)

	cinematic_demo_item.scale = Vector3.ONE * 1.25

	_build_pickup_visual(
		cinematic_demo_item,
		kind
	)

	add_child(
		cinematic_demo_item
	)


func _finish_cinematic_intro() -> void:
	if game_state != GameState.INTRO:
		return

	if is_instance_valid(
		cinematic_demo_item
	):
		cinematic_demo_item.queue_free()

		cinematic_demo_item = null

	cinematic_overlay.hide()

	current_level = 1
	boost_remaining = 0.0

	# Restauración inmediata de la paleta.
	_update_level_visuals(
		10.0
	)

	player.position = Vector3(
		0.0,
		0.0,
		PLAYER_Z
	)

	player.rotation = Vector3(
		0.0,
		PI,
		0.0
	)

	camera.position = Vector3(
		0.0,
		3.45,
		7.20
	)

	camera.fov = 70.0

	camera.look_at(
		Vector3(
			0.0,
			1.15,
			-2.0
		),
		Vector3.UP
	)

	if player.has_method(
		"set_running"
	):
		player.call(
			"set_running",
			false
		)


	if player.has_method(
		"set_hero_pose"
	):
		player.call(
			"set_hero_pose",
			false
		)

	if is_instance_valid(
		music_player
	):
		music_player.stop()

		music_player.volume_db = -7.0
		music_player.pitch_scale = 1.0

	_show_menu()


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
	_style_title(title)

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
	_style_italic(level_label)

	level_label.text = (
		"NIVEL 01 // SABANA CONECTADA"
	)

	level_label.add_theme_color_override(
		"font_color",
		GREEN
	)

	hud.add_child(level_label)

	score_label = Label.new()
	_style_telemetry(score_label)
	hud.add_child(score_label)

	shield_label = Label.new()
	_style_telemetry(shield_label)
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

	boost_label = Label.new()
	_style_italic(boost_label)

	boost_label.add_theme_color_override(
		"font_color",
		YELLOW
	)

	hud.add_child(boost_label)

	event_label = Label.new()
	_style_italic(event_label)

	event_label.text = ""

	event_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	event_label.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	event_label.offset_left = -260.0
	event_label.offset_top = 82.0
	event_label.offset_right = 260.0
	event_label.offset_bottom = 128.0

	event_label.add_theme_font_size_override(
		"font_size",
		24
	)

	event_label.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.92
		)
	)

	event_label.add_theme_constant_override(
		"outline_size",
		4
	)

	event_label.hide()

	ui_root.add_child(event_label)

	firewall_label = Label.new()
	_style_italic(firewall_label)

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

	pause_button.custom_minimum_size = Vector2(
		118.0,
		44.0
	)

	pause_button.add_theme_font_size_override(
		"font_size",
		16
	)

	ui_root.add_child(pause_button)

	pause_button.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	pause_button.offset_left = -138.0
	pause_button.offset_top = 20.0
	pause_button.offset_right = -18.0
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
	_style_title(title)

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
	_style_italic(subtitle)

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
	_style_telemetry(footer)

	footer.text = (
		"IZQ / DER // CAMBIAR CARRIL   "
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
	_style_title(title)

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
		+ "AMARILLO // boost de red // velocidad temporal\n"
		+ "ROJO   // malware // -25 firewall\n\n"
		+ "IZQ / DER // cambia de carril.\n"
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
	_style_title(title)

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
	_style_telemetry(game_over_score)

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

	_style_button(button)
	animated_buttons.append(button)

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


func _show_event_feedback(
	text_value: String,
	color: Color,
	duration: float = 1.25
) -> void:
	event_label.text = text_value

	event_label.add_theme_color_override(
		"font_color",
		color
	)

	event_remaining = duration

	event_label.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	event_label.scale = Vector2(
		0.86,
		0.86
	)

	event_label.show()

	if is_instance_valid(event_tween):
		event_tween.kill()

	event_tween = create_tween()

	event_tween.set_parallel(true)

	# Golpe inicial de escala.
	event_tween.tween_property(
		event_label,
		"scale",
		Vector2.ONE,
		0.16
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	# Entrada luminosa.
	event_tween.tween_property(
		event_label,
		"modulate:a",
		1.0,
		0.10
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# Después hacemos dos flashes cortos.
	var flash := create_tween()

	flash.tween_interval(0.18)

	flash.tween_property(
		event_label,
		"modulate:a",
		0.42,
		0.07
	)

	flash.tween_property(
		event_label,
		"modulate:a",
		1.0,
		0.07
	)

	flash.tween_property(
		event_label,
		"modulate:a",
		0.50,
		0.07
	)

	flash.tween_property(
		event_label,
		"modulate:a",
		1.0,
		0.08
	)


func _update_event_feedback(
	delta: float
) -> void:
	if event_remaining <= 0.0:
		return

	event_remaining -= delta

	if event_remaining <= 0.0:
		event_remaining = 0.0

		var fade_out := create_tween()

		fade_out.tween_property(
			event_label,
			"modulate:a",
			0.0,
			0.18
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN
		)

		fade_out.tween_callback(
			event_label.hide
		)


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

	if boost_remaining > 0.0:
		boost_label.text = (
			"BOOST      %.1f s"
			% boost_remaining
		)
	else:
		boost_label.text = (
			"BOOST      DISPONIBLE EN RUTA"
		)


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
