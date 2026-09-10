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

var elapsed := 0.0
var grid_offset := 0.0

var current_level: int = 1
var world_speed_scale: float = 1.0


func _ready() -> void:
	z_index = -100
	queue_redraw()


func _process(delta: float) -> void:
	if get_tree().paused:
		return

	elapsed += delta

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
	world_speed_scale = maxf(speed_scale, 0.0)
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, size),
		BG
	)

	_draw_savanna_background(size)
	_draw_level_atmosphere(size)
	_draw_grid(size)


func _draw_savanna_background(size: Vector2) -> void:
	var top := 110.0
	var horizon := size.y * 0.63

	var sky_colors := [
		Color(0.035, 0.10, 0.16, 1.0),
		Color(0.055, 0.16, 0.22, 1.0),
		Color(0.12, 0.25, 0.28, 1.0),
		Color(0.25, 0.34, 0.27, 1.0)
	]

	var sun_color := Color(1.0, 0.72, 0.30, 0.78)
	var far_color := Color(0.10, 0.20, 0.22, 1.0)
	var mid_color := Color(0.12, 0.27, 0.23, 1.0)
	var plain_color := Color(0.11, 0.23, 0.16, 1.0)

	if current_level == 2:
		sky_colors = [
			Color(0.08, 0.08, 0.16, 1.0),
			Color(0.22, 0.10, 0.18, 1.0),
			Color(0.52, 0.19, 0.12, 1.0),
			Color(0.72, 0.36, 0.15, 1.0)
		]

		sun_color = Color(1.0, 0.40, 0.12, 0.90)
		far_color = Color(0.20, 0.10, 0.16, 1.0)
		mid_color = Color(0.28, 0.13, 0.13, 1.0)
		plain_color = Color(0.18, 0.13, 0.10, 1.0)

	elif current_level == 3:
		sky_colors = [
			Color(0.010, 0.018, 0.060, 1.0),
			Color(0.018, 0.035, 0.095, 1.0),
			Color(0.025, 0.060, 0.120, 1.0),
			Color(0.035, 0.080, 0.120, 1.0)
		]

		sun_color = Color(0.16, 0.50, 0.65, 0.25)
		far_color = Color(0.035, 0.075, 0.12, 1.0)
		mid_color = Color(0.035, 0.095, 0.11, 1.0)
		plain_color = Color(0.025, 0.075, 0.085, 1.0)

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


func _draw_acacia(origin: Vector2, scale_factor: float) -> void:
	var trunk_color := Color(0.16, 0.16, 0.11, 0.95)
	var leaf_color := Color(0.10, 0.24, 0.14, 0.95)

	draw_line(
		origin,
		origin + Vector2(2.0, -72.0) * scale_factor,
		trunk_color,
		8.0 * scale_factor
	)

	draw_line(
		origin + Vector2(1.0, -47.0) * scale_factor,
		origin + Vector2(-25.0, -67.0) * scale_factor,
		trunk_color,
		4.0 * scale_factor
	)

	draw_line(
		origin + Vector2(1.0, -52.0) * scale_factor,
		origin + Vector2(29.0, -72.0) * scale_factor,
		trunk_color,
		4.0 * scale_factor
	)

	var crown_center := origin + Vector2(2.0, -79.0) * scale_factor

	draw_colored_polygon(
		_ellipse_background_points(
			crown_center,
			Vector2(54.0, 17.0) * scale_factor,
			24
		),
		leaf_color
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
