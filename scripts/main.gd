extends Node2D

const BG := Color(0.027, 0.067, 0.122, 1.0)
const PANEL := Color(0.063, 0.114, 0.196, 1.0)
const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const PURPLE := Color(0.545, 0.361, 0.965, 1.0)
const RED := Color(1.0, 0.259, 0.427, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)

const RHINO_SPEED := 330.0
const GRID_SIZE := 64

var rhino_position := Vector2(640, 400)
var elapsed := 0.0
var grid_offset := 0.0

var packet_positions: Array[Vector2] = []
var packet_speeds: Array[float] = []
var packet_colors: Array[Color] = []

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()

	var viewport_size := get_viewport_rect().size
	rhino_position = viewport_size * Vector2(0.5, 0.58)

	for i in range(14):
		packet_positions.append(
			Vector2(
				rng.randf_range(0.0, viewport_size.x),
				rng.randf_range(140.0, viewport_size.y - 20.0)
			)
		)

		packet_speeds.append(rng.randf_range(40.0, 115.0))

		var palette := [CYAN, GREEN, PURPLE, RED, YELLOW]
		packet_colors.append(palette[i % palette.size()])

	_create_interface()

	queue_redraw()


func _create_interface() -> void:
	var title := Label.new()
	title.text = "PACKET RUNNER"
	title.position = Vector2(32, 18)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", CYAN)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "DEFEND THE NETWORK  //  PROTOTYPE 0.1"
	subtitle.position = Vector2(35, 62)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override(
		"font_color",
		Color(0.75, 0.84, 0.92, 1.0)
	)
	add_child(subtitle)

	var controls := Label.new()
	controls.text = "MOVE  [ W A S D ]  or  [ ARROW KEYS ]"
	controls.position = Vector2(32, 680)
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", GREEN)
	add_child(controls)


func _process(delta: float) -> void:
	elapsed += delta
	grid_offset = fmod(elapsed * 24.0, float(GRID_SIZE))

	_move_rhino(delta)
	_move_packets(delta)

	queue_redraw()


func _move_rhino(delta: float) -> void:
	var movement := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0

	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0

	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0

	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0

	if movement.length_squared() > 0.0:
		movement = movement.normalized()
		rhino_position += movement * RHINO_SPEED * delta

	var viewport_size := get_viewport_rect().size

	rhino_position.x = clampf(
		rhino_position.x,
		75.0,
		viewport_size.x - 105.0
	)

	rhino_position.y = clampf(
		rhino_position.y,
		155.0,
		viewport_size.y - 80.0
	)


func _move_packets(delta: float) -> void:
	var viewport_size := get_viewport_rect().size

	for i in range(packet_positions.size()):
		packet_positions[i].x += packet_speeds[i] * delta

		if packet_positions[i].x > viewport_size.x + 30.0:
			packet_positions[i].x = -30.0
			packet_positions[i].y = rng.randf_range(
				140.0,
				viewport_size.y - 30.0
			)


func _draw() -> void:
	var size := get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, size),
		BG
	)

	_draw_grid(size)

	draw_rect(
		Rect2(0, 0, size.x, 110),
		Color(PANEL.r, PANEL.g, PANEL.b, 0.92)
	)

	draw_line(
		Vector2(0, 110),
		Vector2(size.x, 110),
		Color(CYAN.r, CYAN.g, CYAN.b, 0.45),
		2.0
	)

	_draw_packets()
	_draw_rhino(rhino_position)


func _draw_grid(size: Vector2) -> void:
	var grid_color := Color(CYAN.r, CYAN.g, CYAN.b, 0.06)

	for x in range(-GRID_SIZE, int(size.x) + GRID_SIZE, GRID_SIZE):
		var px := float(x) + grid_offset

		draw_line(
			Vector2(px, 110),
			Vector2(px, size.y),
			grid_color,
			1.0
		)

	for y in range(110, int(size.y) + GRID_SIZE, GRID_SIZE):
		draw_line(
			Vector2(0, float(y)),
			Vector2(size.x, float(y)),
			grid_color,
			1.0
		)


func _draw_packets() -> void:
	for i in range(packet_positions.size()):
		var pos := packet_positions[i]
		var color := packet_colors[i]

		draw_line(
			pos - Vector2(30, 0),
			pos,
			Color(color.r, color.g, color.b, 0.18),
			2.0
		)

		draw_circle(
			pos,
			11.0,
			Color(color.r, color.g, color.b, 0.08)
		)

		draw_circle(pos, 4.5, color)


func _draw_rhino(pos: Vector2) -> void:
	var pulse := (sin(elapsed * 4.0) + 1.0) * 0.5

	draw_circle(
		pos,
		54.0 + pulse * 4.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.055)
	)

	draw_circle(
		pos,
		44.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.09)
	)

	var body := PackedVector2Array([
		pos + Vector2(-45, -25),
		pos + Vector2(20, -31),
		pos + Vector2(50, -10),
		pos + Vector2(38, 24),
		pos + Vector2(-35, 27),
		pos + Vector2(-55, 7)
	])

	draw_colored_polygon(body, GREEN)

	var head := pos + Vector2(45, -10)

	draw_circle(
		head,
		27.0,
		Color(0.135, 0.780, 0.550, 1.0)
	)

	var horn := PackedVector2Array([
		head + Vector2(20, -15),
		head + Vector2(66, -27),
		head + Vector2(23, 2)
	])

	draw_colored_polygon(horn, YELLOW)

	var ear := PackedVector2Array([
		head + Vector2(-10, -20),
		head + Vector2(-2, -43),
		head + Vector2(7, -20)
	])

	draw_colored_polygon(ear, GREEN)

	draw_line(
		pos + Vector2(-32, 20),
		pos + Vector2(-37, 48),
		GREEN,
		10.0
	)

	draw_line(
		pos + Vector2(15, 20),
		pos + Vector2(10, 48),
		GREEN,
		10.0
	)

	draw_line(
		pos + Vector2(-48, -8),
		pos + Vector2(-69, -23),
		GREEN,
		5.0
	)

	draw_circle(
		head + Vector2(8, -7),
		5.0,
		BG
	)

	draw_circle(
		head + Vector2(10, -9),
		1.8,
		Color.WHITE
	)

	draw_circle(
		pos + Vector2(-5, -3),
		5.0,
		CYAN
	)
