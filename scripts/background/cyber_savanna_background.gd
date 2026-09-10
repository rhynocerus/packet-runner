class_name CyberSavannaBackground
extends Node2D

# Packet Runner // Cyber-Savanna Background System v0.1
#
# Primera etapa:
# conserva la apariencia procedural existente, pero separada
# de la lógica principal del juego.

const BG := Color(0.027, 0.067, 0.122, 1.0)
const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)
const RED := Color(1.0, 0.259, 0.427, 1.0)
const PURPLE := Color(0.72, 0.42, 1.0, 1.0)

const GRID_SIZE := 64

# Aproximadamente 2.4 segundos entre estados visuales.
const LEVEL_TRANSITION_SPEED := 0.42

var elapsed := 0.0
var grid_offset := 0.0

var current_level: int = 1
var world_speed_scale: float = 1.0

# current_level controla la lógica.
# visual_level controla cómo se transforma el ecosistema.
var visual_level: float = 1.0
var target_visual_level: float = 1.0


func _ready() -> void:
	z_index = -100
	queue_redraw()


func _process(delta: float) -> void:
	if get_tree().paused:
		return

	elapsed += delta

	visual_level = move_toward(
		visual_level,
		target_visual_level,
		LEVEL_TRANSITION_SPEED * delta
	)

	grid_offset = fmod(
		elapsed * 24.0,
		float(GRID_SIZE)
	)

	queue_redraw()


func set_level(
	level: int,
	speed_scale: float = 1.0
) -> void:
	current_level = clampi(level, 1, 3)
	target_visual_level = float(current_level)
	world_speed_scale = maxf(speed_scale, 0.0)
	queue_redraw()


func _blend_level_float(
	level_1: float,
	level_2: float,
	level_3: float
) -> float:
	if visual_level <= 2.0:
		return lerpf(
			level_1,
			level_2,
			clampf(visual_level - 1.0, 0.0, 1.0)
		)

	return lerpf(
		level_2,
		level_3,
		clampf(visual_level - 2.0, 0.0, 1.0)
	)


func _blend_level_color(
	level_1: Color,
	level_2: Color,
	level_3: Color
) -> Color:
	if visual_level <= 2.0:
		return level_1.lerp(
			level_2,
			clampf(visual_level - 1.0, 0.0, 1.0)
		)

	return level_2.lerp(
		level_3,
		clampf(visual_level - 2.0, 0.0, 1.0)
	)


func _draw() -> void:
	var size := get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, size),
		BG
	)

	_draw_savanna_background(size)
	_draw_grid(size)
	_draw_network_ecosystem(size)
	_draw_level_atmosphere(size)


func _draw_savanna_background(size: Vector2) -> void:
	var top := 110.0
	var horizon := size.y * 0.63

	var sky_colors: Array[Color] = [
		_blend_level_color(
			Color(0.055, 0.15, 0.22, 1.0),
			Color(0.08, 0.08, 0.16, 1.0),
			Color(0.010, 0.018, 0.060, 1.0)
		),
		_blend_level_color(
			Color(0.080, 0.22, 0.28, 1.0),
			Color(0.22, 0.10, 0.18, 1.0),
			Color(0.018, 0.035, 0.095, 1.0)
		),
		_blend_level_color(
			Color(0.160, 0.34, 0.33, 1.0),
			Color(0.52, 0.19, 0.12, 1.0),
			Color(0.025, 0.060, 0.120, 1.0)
		),
		_blend_level_color(
			Color(0.380, 0.45, 0.30, 1.0),
			Color(0.72, 0.36, 0.15, 1.0),
			Color(0.035, 0.080, 0.120, 1.0)
		)
	]

	var sun_color := _blend_level_color(
		Color(1.0, 0.78, 0.38, 0.86),
		Color(1.0, 0.40, 0.12, 0.90),
		Color(0.16, 0.50, 0.65, 0.25)
	)

	var far_color := _blend_level_color(
		Color(0.12, 0.24, 0.24, 1.0),
		Color(0.20, 0.10, 0.16, 1.0),
		Color(0.035, 0.075, 0.12, 1.0)
	)

	var mid_color := _blend_level_color(
		Color(0.14, 0.32, 0.24, 1.0),
		Color(0.28, 0.13, 0.13, 1.0),
		Color(0.035, 0.095, 0.11, 1.0)
	)

	var plain_color := _blend_level_color(
		Color(0.13, 0.29, 0.18, 1.0),
		Color(0.18, 0.13, 0.10, 1.0),
		Color(0.025, 0.075, 0.085, 1.0)
	)

	var band_height := (
		(horizon - top)
		/ float(sky_colors.size())
	)

	for i in range(sky_colors.size()):
		draw_rect(
			Rect2(
				0,
				top + band_height * i,
				size.x,
				band_height + 1.0
			),
			sky_colors[i]
		)

	# Sol / resplandor de horizonte
	var sun_position := Vector2(
		size.x * 0.78,
		top + 115.0
	)

	draw_circle(
		sun_position,
		54.0,
		Color(
			sun_color.r,
			sun_color.g,
			sun_color.b,
			sun_color.a * 0.12
		)
	)

	draw_circle(
		sun_position,
		43.0,
		sun_color
	)

	# Nubes muy lejanas
	_draw_parallax_clouds(
		size,
		top,
		horizon
	)

	# Montañas lejanas
	var far_offset := fmod(
		elapsed * 8.0 * world_speed_scale,
		300.0
	)

	for i in range(-1, 7):
		var x := float(i) * 300.0 - far_offset

		var mountain := PackedVector2Array([
			Vector2(x - 90.0, horizon),
			Vector2(x + 30.0, horizon - 145.0),
			Vector2(x + 105.0, horizon - 48.0),
			Vector2(x + 205.0, horizon)
		])

		draw_colored_polygon(
			mountain,
			far_color
		)

	# Segunda línea de montañas
	var far_offset_2 := fmod(
		elapsed * 12.0 * world_speed_scale,
		360.0
	)

	for i in range(-1, 6):
		var x := float(i) * 360.0 - far_offset_2

		var ridge := PackedVector2Array([
			Vector2(x - 80.0, horizon + 18.0),
			Vector2(x + 55.0, horizon - 82.0),
			Vector2(x + 145.0, horizon - 20.0),
			Vector2(x + 270.0, horizon + 18.0)
		])

		draw_colored_polygon(
			ridge,
			Color(
				mid_color.r,
				mid_color.g,
				mid_color.b,
				0.78
			)
		)

	# Colinas medias
	var mid_offset := fmod(
		elapsed * 19.0 * world_speed_scale,
		250.0
	)

	for i in range(-1, 8):
		var x := float(i) * 250.0 - mid_offset

		var hill := PackedVector2Array([
			Vector2(x - 55.0, horizon + 38.0),
			Vector2(x + 55.0, horizon - 52.0),
			Vector2(x + 150.0, horizon - 15.0),
			Vector2(x + 225.0, horizon + 38.0)
		])

		draw_colored_polygon(
			hill,
			mid_color
		)

	# Llanura
	draw_rect(
		Rect2(
			0,
			horizon,
			size.x,
			size.y - horizon
		),
		plain_color
	)

	# Línea lejana de vegetación
	var scrub_offset := fmod(
		elapsed * 23.0 * world_speed_scale,
		110.0
	)

	for i in range(
		-1,
		int(size.x / 110.0) + 2
	):
		var x := float(i) * 110.0 - scrub_offset
		var h := 8.0 + float(abs(i * 13) % 14)

		draw_circle(
			Vector2(
				x,
				horizon - h * 0.35
			),
			h,
			Color(0.06, 0.15, 0.10, 0.82)
		)


	# Arquitectura orgánico-tecnológica del horizonte
	_draw_horizon_architecture(
		size,
		horizon
	)

	# Acacias en plano medio
	var tree_offset := fmod(
		elapsed * 31.0 * world_speed_scale,
		320.0
	)

	for i in range(-1, 7):
		var tree_x := float(i) * 320.0 - tree_offset
		var tree_y := horizon + 20.0

		_draw_acacia(
			Vector2(tree_x, tree_y),
			0.72 + float(abs(i) % 2) * 0.13
		)

	# Polvo / partículas intermedias
	_draw_background_dust(
		size,
		horizon
	)

	# Hierba cercana
	var grass_offset := fmod(
		elapsed * 66.0 * world_speed_scale,
		52.0
	)

	for i in range(
		-1,
		int(size.x / 52.0) + 2
	):
		var x := float(i) * 52.0 - grass_offset
		var base_y := size.y - 7.0

		draw_line(
			Vector2(x, base_y),
			Vector2(x - 9.0, base_y - 30.0),
			Color(0.24, 0.42, 0.20, 0.88),
			3.0
		)

		draw_line(
			Vector2(x + 8.0, base_y),
			Vector2(x + 17.0, base_y - 23.0),
			Color(0.20, 0.36, 0.18, 0.82),
			2.0
		)

	# Sombras rápidas en primerísimo plano
	var ground_offset := fmod(
		elapsed * 105.0 * world_speed_scale,
		170.0
	)

	for i in range(-1, 10):
		var x := float(i) * 170.0 - ground_offset

		draw_line(
			Vector2(x, size.y - 18.0),
			Vector2(x + 75.0, size.y - 18.0),
			Color(0.01, 0.04, 0.035, 0.30),
			5.0
		)


func _draw_parallax_clouds(
	size: Vector2,
	top: float,
	horizon: float
) -> void:
	var cloud_offset := fmod(
		elapsed * 5.0 * world_speed_scale,
		390.0
	)

	var cloud_color := Color(
		0.60,
		0.72,
		0.72,
		0.12
	)

	if current_level == 2:
		cloud_color = Color(
			0.50,
			0.18,
			0.18,
			0.20
		)

	elif current_level == 3:
		cloud_color = Color(
			0.04,
			0.09,
			0.16,
			0.72
		)

	for i in range(-1, 6):
		var x := float(i) * 390.0 - cloud_offset
		var y := (
			top
			+ 54.0
			+ float(abs(i * 43) % 95)
		)

		var scale_factor := (
			0.78
			+ float(abs(i) % 3) * 0.12
		)

		draw_circle(
			Vector2(x, y),
			42.0 * scale_factor,
			cloud_color
		)

		draw_circle(
			Vector2(x + 40.0, y + 5.0),
			55.0 * scale_factor,
			cloud_color
		)

		draw_circle(
			Vector2(x + 88.0, y + 10.0),
			36.0 * scale_factor,
			cloud_color
		)

		draw_rect(
			Rect2(
				x - 38.0,
				y + 4.0,
				170.0,
				30.0
			),
			cloud_color
		)


func _draw_background_dust(
	size: Vector2,
	horizon: float
) -> void:
	var dust_speed := 34.0

	if current_level == 2:
		dust_speed = 52.0
	elif current_level == 3:
		dust_speed = 72.0

	var offset := fmod(
		elapsed
		* dust_speed
		* world_speed_scale,
		size.x + 180.0
	)

	var dust_color := Color(
		0.75,
		0.68,
		0.38,
		0.16
	)

	if current_level == 2:
		dust_color = Color(
			1.0,
			0.40,
			0.16,
			0.22
		)

	elif current_level == 3:
		dust_color = Color(
			CYAN.r,
			CYAN.g,
			CYAN.b,
			0.20
		)

	for i in range(12):
		var x := fmod(
			float(i) * 143.0
			- offset
			+ size.x
			+ 180.0,
			size.x + 180.0
		) - 90.0

		var y := (
			horizon
			+ 45.0
			+ float((i * 47) % 190)
		)

		var radius := (
			2.0
			+ float(i % 3)
		)

		draw_circle(
			Vector2(x, y),
			radius,
			dust_color
		)


func _draw_horizon_architecture(
	size: Vector2,
	horizon: float
) -> void:
	# ========================================================
	# CYBER-SAVANNA v0.4
	# Torres-acacia: infraestructura que creció con el paisaje.
	# ========================================================

	var spacing: float = 420.0

	var architecture_offset: float = fmod(
		elapsed * 12.0 * world_speed_scale,
		spacing
	)

	var tower_positions: Array[Vector2] = []
	var tower_colors: Array[Color] = []
	var tower_corruption: Array[bool] = []
	var tower_variants: Array[int] = []

	# Primero calculamos todas las torres.
	for i in range(-1, 5):
		var variant: int = absi(i) % 3

		var x: float = (
			float(i) * spacing
			- architecture_offset
			+ 115.0
		)

		var base_y: float = (
			horizon
			- 4.0
			+ float(variant) * 3.0
		)

		var corrupted: bool = false

		if current_level == 2:
			corrupted = absi(i) % 4 == 1
		elif current_level >= 3:
			corrupted = absi(i) % 2 == 1

		var energy_color: Color = CYAN

		if corrupted:
			energy_color = RED
		elif variant == 2:
			energy_color = GREEN

		tower_positions.append(
			Vector2(x, base_y)
		)

		tower_colors.append(
			energy_color
		)

		tower_corruption.append(
			corrupted
		)

		tower_variants.append(
			variant
		)

	# ========================================================
	# ENLACES ENTRE TORRES
	# Se dibujan antes para quedar detrás de la estructura.
	# ========================================================

	for index in range(tower_positions.size() - 1):
		var a: Vector2 = tower_positions[index]
		var b: Vector2 = tower_positions[index + 1]

		var link_y_a: Vector2 = (
			a
			+ Vector2(
				0.0,
				-82.0
				- float(tower_variants[index]) * 8.0
			)
		)

		var link_y_b: Vector2 = (
			b
			+ Vector2(
				0.0,
				-82.0
				- float(tower_variants[index + 1]) * 8.0
			)
		)

		var link_color: Color = CYAN

		if (
			tower_corruption[index]
			or tower_corruption[index + 1]
		):
			link_color = RED

		draw_line(
			link_y_a,
			link_y_b,
			Color(
				link_color.r,
				link_color.g,
				link_color.b,
				0.11
			),
			1.0
		)

		# Pulso viajando entre nodos.
		var data_t: float = fmod(
			elapsed * 0.20
			+ float(index) * 0.23,
			1.0
		)

		var data_position: Vector2 = (
			link_y_a.lerp(
				link_y_b,
				data_t
			)
		)

		draw_circle(
			data_position,
			4.5,
			Color(
				link_color.r,
				link_color.g,
				link_color.b,
				0.055
			)
		)

		draw_circle(
			data_position,
			1.4,
			Color(
				link_color.r,
				link_color.g,
				link_color.b,
				0.62
			)
		)

	# ========================================================
	# TORRES
	# ========================================================

	for index in range(tower_positions.size()):
		var base: Vector2 = tower_positions[index]
		var variant: int = tower_variants[index]

		var height: float = (
			88.0
			+ float(variant) * 9.0
		)

		_draw_horizon_tower(
			base,
			height,
			variant,
			tower_colors[index],
			tower_corruption[index]
		)


func _draw_horizon_tower(
	base: Vector2,
	height: float,
	variant: int,
	energy_color: Color,
	corrupted: bool
) -> void:
	var top := (
		base
		+ Vector2(0.0, -height)
	)

	var trunk_dark := Color(
		0.07,
		0.12,
		0.13,
		0.86
	)

	var steel := Color(
		0.24,
		0.34,
		0.38,
		0.58
	)

	var foliage := Color(
		0.055,
		0.16,
		0.12,
		0.72
	)

	if current_level == 2:
		foliage = Color(
			0.15,
			0.17,
			0.09,
			0.68
		)

	elif current_level >= 3:
		foliage = Color(
			0.10,
			0.08,
			0.13,
			0.74
		)

	# --------------------------------------------------------
	# RAÍCES / ANCLAJES
	# --------------------------------------------------------

	draw_line(
		base,
		base + Vector2(-30.0, 6.0),
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.10
		),
		1.2
	)

	draw_line(
		base,
		base + Vector2(31.0, 7.0),
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.10
		),
		1.2
	)

	# --------------------------------------------------------
	# COLUMNA ORGÁNICO-METÁLICA
	# --------------------------------------------------------

	draw_line(
		base,
		top,
		trunk_dark,
		7.0
	)

	draw_line(
		base + Vector2(1.5, -4.0),
		top,
		steel,
		2.0
	)

	draw_line(
		base + Vector2(-1.0, -8.0),
		top,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.25
		),
		1.0
	)

	# --------------------------------------------------------
	# BRAZOS DE ACACIA / ANTENAS
	# --------------------------------------------------------

	var branch_y: float = (
		top.y
		+ 27.0
		+ float(variant) * 2.0
	)

	var left_joint := Vector2(
		base.x,
		branch_y
	)

	var right_joint := Vector2(
		base.x + 1.0,
		branch_y + 5.0
	)

	var left_tip := Vector2(
		base.x - 34.0 - float(variant) * 4.0,
		branch_y - 14.0
	)

	var right_tip := Vector2(
		base.x + 38.0 + float(variant) * 3.0,
		branch_y - 11.0
	)

	draw_line(
		left_joint,
		left_tip,
		trunk_dark,
		4.0
	)

	draw_line(
		right_joint,
		right_tip,
		trunk_dark,
		4.0
	)

	draw_line(
		left_joint,
		left_tip,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.31
		),
		1.0
	)

	draw_line(
		right_joint,
		right_tip,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.31
		),
		1.0
	)

	# --------------------------------------------------------
	# COPA / MATRIZ DE ANTENA
	# --------------------------------------------------------

	draw_circle(
		top + Vector2(-24.0, 5.0),
		22.0,
		foliage
	)

	draw_circle(
		top + Vector2(0.0, 1.0),
		27.0,
		foliage
	)

	draw_circle(
		top + Vector2(25.0, 6.0),
		21.0,
		foliage
	)

	# Placa central, equivalente a una pieza del traje del Rino.
	var plate_center := (
		top
		+ Vector2(0.0, 6.0)
	)

	var plate := PackedVector2Array([
		plate_center + Vector2(-13.0, -5.0),
		plate_center + Vector2(-8.0, -10.0),
		plate_center + Vector2(9.0, -10.0),
		plate_center + Vector2(14.0, -4.0),
		plate_center + Vector2(10.0, 6.0),
		plate_center + Vector2(-9.0, 6.0)
	])

	draw_colored_polygon(
		plate,
		Color(
			0.10,
			0.17,
			0.20,
			0.88
		)
	)

	var plate_outline := PackedVector2Array([
		plate[0],
		plate[1],
		plate[2],
		plate[3],
		plate[4],
		plate[5],
		plate[0]
	])

	draw_polyline(
		plate_outline,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.48
		),
		1.0,
		true
	)

	# --------------------------------------------------------
	# NÚCLEO DE COMUNICACIONES
	# --------------------------------------------------------

	var pulse: float = (
		0.70
		+ sin(
			elapsed * 2.0
			+ float(variant)
		) * 0.18
	)

	draw_circle(
		plate_center,
		8.0 + pulse * 2.0,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.045
		)
	)

	draw_circle(
		plate_center,
		2.4,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.78
		)
	)

	# Nodos terminales.
	draw_circle(
		left_tip,
		1.7,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.62
		)
	)

	draw_circle(
		right_tip,
		1.7,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.62
		)
	)

	# --------------------------------------------------------
	# CORRUPCIÓN
	# --------------------------------------------------------

	if corrupted:
		var glitch: float = (
			sin(
				elapsed * 7.0
				+ base.x * 0.01
			)
			* 4.0
		)

		draw_line(
			top + Vector2(-18.0, glitch),
			top + Vector2(18.0, -glitch),
			Color(
				RED.r,
				RED.g,
				RED.b,
				0.34
			),
			1.3
		)

		draw_circle(
			plate_center + Vector2(glitch, 0.0),
			3.5,
			Color(
				RED.r,
				RED.g,
				RED.b,
				0.18
			)
		)


func _draw_network_ecosystem(size: Vector2) -> void:
	var horizon := size.y * 0.63

	var network_strength := _blend_level_float(
		0.58,
		0.72,
		0.88
	)

	var infection_strength := _blend_level_float(
		0.0,
		0.34,
		0.72
	)

	var pulse := (
		0.72
		+ sin(elapsed * 2.2) * 0.18
	)

	var network_color := Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.18 * network_strength
	)

	var node_color := Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.48 * network_strength
	)

	var danger_color := Color(
		RED.r,
		RED.g,
		RED.b,
		0.52 * infection_strength
	)

	# --------------------------------------------------------
	# BACKBONE DE RED SOBRE EL HORIZONTE
	# --------------------------------------------------------

	draw_line(
		Vector2(0.0, horizon - 11.0),
		Vector2(size.x, horizon - 11.0),
		network_color,
		1.5
	)

	# --------------------------------------------------------
	# NODOS / ACACIAS TECNOLÓGICAS LEJANAS
	# --------------------------------------------------------

	var node_offset := fmod(
		elapsed * 10.0 * world_speed_scale,
		245.0
	)

	for i in range(-1, 7):
		var x := float(i) * 245.0 - node_offset

		var y := (
			horizon
			- 29.0
			- sin(elapsed * 0.65 + float(i)) * 5.0
		)

		var corrupted: bool = (
			current_level >= 2
			and abs(i) % 3 == 1
		)

		var color := node_color

		if corrupted:
			color = danger_color

		# Tronco de datos
		draw_line(
			Vector2(x, horizon - 10.0),
			Vector2(x, y),
			color,
			1.5
		)

		# Ramas-circuito
		draw_line(
			Vector2(x, y + 8.0),
			Vector2(x - 21.0, y + 16.0),
			color,
			1.2
		)

		draw_line(
			Vector2(x, y + 8.0),
			Vector2(x + 24.0, y + 14.0),
			color,
			1.2
		)

		draw_circle(
			Vector2(x, y),
			6.0 + pulse * 1.4,
			Color(
				color.r,
				color.g,
				color.b,
				color.a * 0.30
			)
		)

		draw_circle(
			Vector2(x, y),
			2.4,
			Color(
				color.r,
				color.g,
				color.b,
				minf(color.a * 2.2, 0.95)
			)
		)

		draw_circle(
			Vector2(x - 21.0, y + 16.0),
			1.8,
			color
		)

		draw_circle(
			Vector2(x + 24.0, y + 14.0),
			1.8,
			color
		)

	# --------------------------------------------------------
	# RUTAS DE DATOS EN LA SABANA
	# Perspectiva desde el horizonte hacia el jugador.
	# --------------------------------------------------------

	for route in range(4):
		var base_x := (
			size.x
			* (0.16 + float(route) * 0.22)
		)

		var route_bias := float(route) - 1.5

		for segment in range(8):
			var y0 := (
				horizon
				+ 24.0
				+ float(segment) * 39.0
			)

			var y1 := y0 + 23.0

			var drift := sin(
				elapsed * 0.65
				+ float(segment) * 0.55
				+ float(route)
			) * 4.0

			var spread0 := (
				(y0 - horizon)
				* route_bias
				* 0.14
			)

			var spread1 := (
				(y1 - horizon)
				* route_bias
				* 0.14
			)

			var line_color := Color(
				CYAN.r,
				CYAN.g,
				CYAN.b,
				0.070 * network_strength
			)

			if (
				current_level >= 2
				and route == 2
				and segment % 3 == 1
			):
				line_color = Color(
					RED.r,
					RED.g,
					RED.b,
					0.080 * infection_strength
				)

			draw_line(
				Vector2(
					base_x + spread0 + drift,
					y0
				),
				Vector2(
					base_x + spread1 + drift,
					y1
				),
				line_color,
				1.4
			)

	# --------------------------------------------------------
	# PACKETS AMBIENTALES
	# Pequeñas luciérnagas digitales.
	# --------------------------------------------------------

	for i in range(8):
		var speed := (
			0.055
			+ float(i % 3) * 0.012
		)

		var progress := fmod(
			elapsed
			* speed
			* world_speed_scale
			+ float(i) * 0.137,
			1.0
		)

		var x := (
			size.x * 1.08
			- progress * size.x * 1.18
		)

		var y := (
			horizon
			- 48.0
			- float((i * 31) % 95)
			+ sin(elapsed * 1.1 + float(i)) * 4.0
		)

		var packet_color := Color(
			GREEN.r,
			GREEN.g,
			GREEN.b,
			0.42
		)

		if (
			current_level >= 2
			and i % 4 == 1
		):
			packet_color = Color(
				RED.r,
				RED.g,
				RED.b,
				0.40 * maxf(infection_strength, 0.25)
			)

		draw_line(
			Vector2(x + 5.0, y),
			Vector2(x + 18.0, y),
			Color(
				packet_color.r,
				packet_color.g,
				packet_color.b,
				packet_color.a * 0.30
			),
			1.2
		)

		draw_circle(
			Vector2(x, y),
			2.6,
			packet_color
		)


func _draw_level_atmosphere(size: Vector2) -> void:
	if current_level == 1:
		# Bruma cálida muy ligera.
		var haze := (
			0.025
			+ sin(elapsed * 0.8) * 0.008
		)

		draw_rect(
			Rect2(
				0,
				size.y * 0.55,
				size.x,
				size.y * 0.16
			),
			Color(0.85, 0.70, 0.34, haze)
		)

		return

	if current_level == 2:
		# Ocaso más intenso
		draw_rect(
			Rect2(
				0,
				110,
				size.x,
				size.y - 110
			),
			Color(0.62, 0.13, 0.04, 0.10)
		)

		# Rocas rápidas
		var rock_offset := fmod(
			elapsed
			* 47.0
			* world_speed_scale,
			225.0
		)

		for i in range(-1, 8):
			var x := float(i) * 225.0 - rock_offset
			var y := size.y - 35.0

			var rock := PackedVector2Array([
				Vector2(x - 38.0, y),
				Vector2(x - 16.0, y - 32.0),
				Vector2(x + 18.0, y - 42.0),
				Vector2(x + 43.0, y)
			])

			draw_colored_polygon(
				rock,
				Color(0.27, 0.12, 0.10, 0.92)
			)

		# Partículas encendidas de ocaso
		var ember_offset := fmod(
			elapsed * 76.0,
			size.x + 120.0
		)

		for i in range(10):
			var x := fmod(
				float(i) * 151.0
				- ember_offset
				+ size.x
				+ 120.0,
				size.x + 120.0
			) - 60.0

			var y := (
				180.0
				+ float((i * 61) % 420)
			)

			draw_circle(
				Vector2(x, y),
				2.0 + float(i % 2),
				Color(1.0, 0.42, 0.10, 0.32)
			)

	elif current_level == 3:
		# Oscurecimiento de tormenta
		draw_rect(
			Rect2(
				0,
				110,
				size.x,
				size.y - 110
			),
			Color(0.005, 0.015, 0.075, 0.46)
		)

		# Banda nubosa rápida
		var storm_offset := fmod(
			elapsed * 28.0,
			310.0
		)

		for i in range(-1, 6):
			var x := float(i) * 310.0 - storm_offset

			draw_circle(
				Vector2(x, 155.0),
				78.0,
				Color(0.02, 0.045, 0.095, 0.78)
			)

			draw_circle(
				Vector2(x + 70.0, 165.0),
				92.0,
				Color(0.025, 0.055, 0.105, 0.72)
			)

		# Scanlines horizontales
		var scan_offset := fmod(
			elapsed
			* 78.0
			* world_speed_scale,
			46.0
		)

		for y in range(
			130,
			int(size.y) + 46,
			46
		):
			var py := float(y) + scan_offset

			draw_line(
				Vector2(0, py),
				Vector2(size.x, py),
				Color(
					CYAN.r,
					CYAN.g,
					CYAN.b,
					0.10
				),
				1.0
			)

		# Lluvia digital vertical
		var rain_offset := fmod(
			elapsed * 190.0,
			120.0
		)

		for i in range(
			0,
			int(size.x / 72.0) + 2
		):
			var x := float(i) * 72.0 + 18.0

			var y := fmod(
				float(i * 91)
				+ rain_offset,
				size.y - 100.0
			) + 110.0

			draw_line(
				Vector2(x, y),
				Vector2(x - 6.0, y + 44.0),
				Color(
					CYAN.r,
					CYAN.g,
					CYAN.b,
					0.18
				),
				2.0
			)

		# Trazas de datos rápidas
		var streak_offset := fmod(
			elapsed * 165.0,
			270.0
		)

		for i in range(-1, 7):
			var x := float(i) * 270.0 - streak_offset
			var y := (
				185.0
				+ float((i * 83) % 410)
			)

			draw_line(
				Vector2(x, y),
				Vector2(x + 105.0, y),
				Color(
					CYAN.r,
					CYAN.g,
					CYAN.b,
					0.24
				),
				2.0
			)

		# Relámpago principal
		var flash := sin(elapsed * 5.7)

		if flash > 0.925:
			var lightning := PackedVector2Array([
				Vector2(size.x * 0.73, 120),
				Vector2(size.x * 0.68, 220),
				Vector2(size.x * 0.72, 220),
				Vector2(size.x * 0.64, 360),
				Vector2(size.x * 0.68, 360),
				Vector2(size.x * 0.60, 500)
			])

			for i in range(
				lightning.size() - 1
			):
				draw_line(
					lightning[i],
					lightning[i + 1],
					Color(
						0.62,
						0.92,
						1.0,
						0.82
					),
					3.0
				)

			# Flash ambiental breve
			draw_rect(
				Rect2(
					0,
					110,
					size.x,
					size.y - 110
				),
				Color(0.45, 0.72, 1.0, 0.045)
			)


func _draw_acacia(
	origin: Vector2,
	scale_factor: float
) -> void:
	# ========================================================
	# PACKET RUNNER // BIOMECHANICAL ACACIA v0.3
	# Naturaleza y tecnología pertenecen al mismo organismo.
	# ========================================================

	var bark_dark := Color(0.10, 0.12, 0.10, 0.98)
	var bark_light := Color(0.19, 0.20, 0.14, 0.94)

	var steel_dark := Color(0.12, 0.18, 0.21, 0.98)
	var steel_light := Color(0.34, 0.43, 0.48, 0.88)

	var leaf_dark := Color(0.055, 0.17, 0.10, 0.97)
	var leaf_mid := Color(0.085, 0.25, 0.14, 0.94)
	var leaf_light := Color(0.12, 0.31, 0.17, 0.86)

	if current_level == 2:
		leaf_dark = Color(0.13, 0.16, 0.09, 0.97)
		leaf_mid = Color(0.22, 0.24, 0.10, 0.94)
		leaf_light = Color(0.31, 0.29, 0.11, 0.84)

	elif current_level >= 3:
		leaf_dark = Color(0.09, 0.08, 0.12, 0.98)
		leaf_mid = Color(0.14, 0.11, 0.16, 0.95)
		leaf_light = Color(0.20, 0.13, 0.18, 0.84)

	var trunk_top := (
		origin
		+ Vector2(2.0, -72.0) * scale_factor
	)

	var left_joint := (
		origin
		+ Vector2(1.0, -47.0) * scale_factor
	)

	var left_tip := (
		origin
		+ Vector2(-25.0, -67.0) * scale_factor
	)

	var right_joint := (
		origin
		+ Vector2(1.0, -52.0) * scale_factor
	)

	var right_tip := (
		origin
		+ Vector2(29.0, -72.0) * scale_factor
	)

	var crown_center := (
		origin
		+ Vector2(2.0, -79.0) * scale_factor
	)

	# --------------------------------------------------------
	# VARIACIÓN DEL ÁRBOL
	# Se basa en escala, no en posición horizontal, para que
	# la infección no cambie mientras la acacia se desplaza.
	# --------------------------------------------------------

	var tree_variant: int = (
		int(round(scale_factor * 100.0))
		% 2
	)

	var left_energy: Color = CYAN
	var right_energy: Color = GREEN
	var trunk_energy: Color = CYAN

	if current_level == 2:
		if tree_variant == 0:
			left_energy = RED
		else:
			right_energy = RED

	elif current_level >= 3:
		left_energy = RED
		right_energy = RED

		if tree_variant == 1:
			trunk_energy = RED

	# ========================================================
	# RAÍCES / DATA BUS
	# ========================================================

	var root_left := (
		origin
		+ Vector2(-30.0, 3.0) * scale_factor
	)

	var root_right := (
		origin
		+ Vector2(34.0, 4.0) * scale_factor
	)

	var root_mid_left := (
		origin
		+ Vector2(-15.0, -1.0) * scale_factor
	)

	var root_mid_right := (
		origin
		+ Vector2(17.0, 0.0) * scale_factor
	)

	draw_line(
		origin,
		root_left,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.13),
		maxf(1.0, 1.4 * scale_factor)
	)

	draw_line(
		origin,
		root_right,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.13),
		maxf(1.0, 1.4 * scale_factor)
	)

	draw_line(
		root_left,
		root_mid_left,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.08),
		maxf(1.0, 1.0 * scale_factor)
	)

	draw_line(
		root_right,
		root_mid_right,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.08),
		maxf(1.0, 1.0 * scale_factor)
	)

	draw_circle(
		root_left,
		maxf(1.2, 1.8 * scale_factor),
		Color(CYAN.r, CYAN.g, CYAN.b, 0.48)
	)

	draw_circle(
		root_right,
		maxf(1.2, 1.8 * scale_factor),
		Color(CYAN.r, CYAN.g, CYAN.b, 0.48)
	)

	# ========================================================
	# ESTRUCTURA ORGÁNICA
	# ========================================================

	# Tronco natural.
	draw_line(
		origin,
		trunk_top,
		bark_dark,
		8.5 * scale_factor
	)

	draw_line(
		origin + Vector2(-1.0, -2.0) * scale_factor,
		trunk_top,
		bark_light,
		3.0 * scale_factor
	)

	# Ramas naturales.
	draw_line(
		left_joint,
		left_tip,
		bark_dark,
		5.0 * scale_factor
	)

	draw_line(
		right_joint,
		right_tip,
		bark_dark,
		5.0 * scale_factor
	)

	# ========================================================
	# EXOESQUELETO RHYNUS
	# Tiras de acero embebidas dentro del árbol.
	# ========================================================

	draw_line(
		origin + Vector2(1.0, -7.0) * scale_factor,
		trunk_top,
		steel_dark,
		maxf(1.2, 2.5 * scale_factor)
	)

	draw_line(
		origin + Vector2(1.4, -9.0) * scale_factor,
		trunk_top,
		steel_light,
		maxf(0.8, 0.9 * scale_factor)
	)

	draw_line(
		left_joint,
		left_tip,
		Color(
			left_energy.r,
			left_energy.g,
			left_energy.b,
			0.52
		),
		maxf(0.9, 1.35 * scale_factor)
	)

	draw_line(
		right_joint,
		right_tip,
		Color(
			right_energy.r,
			right_energy.g,
			right_energy.b,
			0.52
		),
		maxf(0.9, 1.35 * scale_factor)
	)

	draw_line(
		origin + Vector2(1.0, -10.0) * scale_factor,
		trunk_top,
		Color(
			trunk_energy.r,
			trunk_energy.g,
			trunk_energy.b,
			0.24
		),
		maxf(0.8, 1.1 * scale_factor)
	)

	# ========================================================
	# COPA NATURAL MULTICAPA
	# Conserva claramente la silueta de acacia.
	# ========================================================

	draw_colored_polygon(
		_ellipse_background_points(
			crown_center
				+ Vector2(-23.0, 2.0) * scale_factor,
			Vector2(35.0, 14.0) * scale_factor,
			20
		),
		leaf_dark
	)

	draw_colored_polygon(
		_ellipse_background_points(
			crown_center
				+ Vector2(23.0, 1.0) * scale_factor,
			Vector2(36.0, 14.0) * scale_factor,
			20
		),
		leaf_dark
	)

	draw_colored_polygon(
		_ellipse_background_points(
			crown_center,
			Vector2(50.0, 16.0) * scale_factor,
			24
		),
		leaf_mid
	)

	draw_colored_polygon(
		_ellipse_background_points(
			crown_center
				+ Vector2(-5.0, -4.0) * scale_factor,
			Vector2(34.0, 8.0) * scale_factor,
			18
		),
		leaf_light
	)

	# Línea tecnológica bajo la copa.
	draw_line(
		crown_center + Vector2(-39.0, 8.0) * scale_factor,
		crown_center + Vector2(37.0, 8.0) * scale_factor,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.13),
		maxf(0.8, 1.1 * scale_factor)
	)

	# ========================================================
	# ARTICULACIONES
	# Mismo lenguaje de placas del traje del Rino.
	# ========================================================

	_draw_acacia_joint(
		left_joint,
		scale_factor,
		left_energy
	)

	_draw_acacia_joint(
		right_joint,
		scale_factor,
		right_energy
	)

	_draw_acacia_joint(
		trunk_top,
		scale_factor,
		trunk_energy
	)

	# Nodos terminales.
	var terminal_positions: Array[Vector2] = [
		left_tip,
		right_tip,
		crown_center
	]

	var terminal_colors: Array[Color] = [
		left_energy,
		right_energy,
		trunk_energy
	]

	for node_index in range(terminal_positions.size()):
		var node_position: Vector2 = terminal_positions[node_index]
		var node_color: Color = terminal_colors[node_index]

		draw_circle(
			node_position,
			maxf(2.5, 5.0 * scale_factor),
			Color(
				node_color.r,
				node_color.g,
				node_color.b,
				0.075
			)
		)

		draw_circle(
			node_position,
			maxf(1.0, 2.0 * scale_factor),
			Color(
				node_color.r,
				node_color.g,
				node_color.b,
				0.82
			)
		)

	# ========================================================
	# PULSOS DE DATOS
	# ========================================================

	var pulse_phase: float = (
		elapsed * 0.38
		+ scale_factor * 1.73
	)

	var trunk_t: float = fmod(
		pulse_phase,
		1.0
	)

	var left_t: float = fmod(
		pulse_phase + 0.34,
		1.0
	)

	var right_t: float = fmod(
		pulse_phase + 0.67,
		1.0
	)

	var trunk_pulse: Vector2 = origin.lerp(
		trunk_top,
		trunk_t
	)

	var left_pulse: Vector2 = left_joint.lerp(
		left_tip,
		left_t
	)

	var right_pulse: Vector2 = right_joint.lerp(
		right_tip,
		right_t
	)

	_draw_acacia_pulse(
		trunk_pulse,
		scale_factor,
		trunk_energy
	)

	_draw_acacia_pulse(
		left_pulse,
		scale_factor,
		left_energy
	)

	_draw_acacia_pulse(
		right_pulse,
		scale_factor,
		right_energy
	)

	# ========================================================
	# INFECCIÓN
	# Nivel 2: una rama empieza a fallar.
	# Nivel 3: la corrupción alcanza la propia copa.
	# ========================================================

	if current_level == 2:
		var infected_tip: Vector2 = right_tip

		if tree_variant == 0:
			infected_tip = left_tip

		draw_line(
			infected_tip
				+ Vector2(-7.0, -3.0) * scale_factor,
			infected_tip
				+ Vector2(8.0, 4.0) * scale_factor,
			Color(RED.r, RED.g, RED.b, 0.46),
			maxf(1.0, 1.3 * scale_factor)
		)

	elif current_level >= 3:
		var glitch_wave: float = (
			sin(elapsed * 5.0 + scale_factor * 4.0)
			* 3.0
			* scale_factor
		)

		draw_line(
			crown_center
				+ Vector2(-38.0, -5.0) * scale_factor,
			crown_center
				+ Vector2(-9.0, glitch_wave) * scale_factor,
			Color(RED.r, RED.g, RED.b, 0.44),
			maxf(1.0, 1.5 * scale_factor)
		)

		draw_line(
			crown_center
				+ Vector2(8.0, -2.0) * scale_factor,
			crown_center
				+ Vector2(41.0, 4.0) * scale_factor,
			Color(RED.r, RED.g, RED.b, 0.38),
			maxf(1.0, 1.5 * scale_factor)
		)

		draw_circle(
			crown_center
				+ Vector2(13.0, -2.0) * scale_factor,
			maxf(2.0, 4.5 * scale_factor),
			Color(RED.r, RED.g, RED.b, 0.16)
		)


func _draw_acacia_joint(
	center: Vector2,
	scale_factor: float,
	energy_color: Color
) -> void:
	var radius: float = maxf(
		3.0,
		5.0 * scale_factor
	)

	var plate := PackedVector2Array([
		center + Vector2(-radius, -radius * 0.45),
		center + Vector2(-radius * 0.35, -radius),
		center + Vector2(radius * 0.55, -radius),
		center + Vector2(radius, -radius * 0.25),
		center + Vector2(radius * 0.70, radius * 0.70),
		center + Vector2(-radius * 0.55, radius)
	])

	draw_colored_polygon(
		plate,
		Color(0.11, 0.17, 0.20, 0.96)
	)

	var outline := PackedVector2Array([
		plate[0],
		plate[1],
		plate[2],
		plate[3],
		plate[4],
		plate[5],
		plate[0]
	])

	draw_polyline(
		outline,
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.62
		),
		maxf(1.0, 1.1 * scale_factor),
		true
	)

	draw_circle(
		center,
		maxf(0.9, 1.5 * scale_factor),
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.92
		)
	)


func _draw_acacia_pulse(
	position: Vector2,
	scale_factor: float,
	energy_color: Color
) -> void:
	draw_circle(
		position,
		maxf(2.0, 4.2 * scale_factor),
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.075
		)
	)

	draw_circle(
		position,
		maxf(0.9, 1.55 * scale_factor),
		Color(
			energy_color.r,
			energy_color.g,
			energy_color.b,
			0.88
		)
	)


func _ellipse_background_points(
	center: Vector2,
	radius: Vector2,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)

		points.append(
			center + Vector2(
				cos(angle) * radius.x,
				sin(angle) * radius.y
			)
		)

	return points



func _draw_grid(size: Vector2) -> void:
	var grid_color := Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.06
	)

	for x in range(
		-GRID_SIZE,
		int(size.x) + GRID_SIZE,
		GRID_SIZE
	):
		var px := float(x) + grid_offset

		draw_line(
			Vector2(px, 110),
			Vector2(px, size.y),
			grid_color,
			1.0
		)

	for y in range(
		110,
		int(size.y) + GRID_SIZE,
		GRID_SIZE
	):
		draw_line(
			Vector2(0, float(y)),
			Vector2(size.x, float(y)),
			grid_color,
			1.0
		)
