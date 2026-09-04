class_name RhinoPlayer
extends Area2D

const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)

const RHINO_BODY := Color(0.25, 0.43, 0.48, 1.0)
const RHINO_DARK := Color(0.10, 0.22, 0.27, 1.0)
const RHINO_LIGHT := Color(0.40, 0.62, 0.64, 1.0)

@export var speed := 330.0

var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	_move(delta)
	queue_redraw()


func _move(delta: float) -> void:
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
		position += movement * speed * delta

	var viewport_size := get_viewport_rect().size

	position.x = clampf(
		position.x,
		85.0,
		viewport_size.x - 100.0
	)

	position.y = clampf(
		position.y,
		165.0,
		viewport_size.y - 75.0
	)


func _ellipse_points(
	center: Vector2,
	radius: Vector2,
	segments: int = 40
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


func _draw() -> void:
	var pulse := (sin(elapsed * 4.0) + 1.0) * 0.5

	# Halo tecnológico
	draw_circle(
		Vector2.ZERO,
		67.0 + pulse * 3.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.045)
	)

	# Cuerpo ancho y pesado
	draw_colored_polygon(
		_ellipse_points(
			Vector2(-10, 0),
			Vector2(57, 34)
		),
		RHINO_BODY
	)

	# Lomo
	draw_arc(
		Vector2(-10, 1),
		58.0,
		3.55,
		5.75,
		24,
		RHINO_LIGHT,
		3.0
	)

	# Cuatro patas robustas
	_draw_leg(Vector2(-42, 21))
	_draw_leg(Vector2(-18, 25))
	_draw_leg(Vector2(16, 24))
	_draw_leg(Vector2(35, 20))

	# Cuello
	var neck := PackedVector2Array([
		Vector2(22, -20),
		Vector2(51, -17),
		Vector2(56, 17),
		Vector2(26, 23)
	])
	draw_colored_polygon(neck, RHINO_BODY)

	# Cabeza característica
	var head := PackedVector2Array([
		Vector2(34, -22),
		Vector2(56, -25),
		Vector2(73, -15),
		Vector2(82, -3),
		Vector2(78, 15),
		Vector2(61, 25),
		Vector2(38, 18),
		Vector2(27, 4)
	])
	draw_colored_polygon(head, RHINO_LIGHT)

	# Hocico ancho
	var snout := PackedVector2Array([
		Vector2(65, -6),
		Vector2(91, -2),
		Vector2(94, 11),
		Vector2(83, 20),
		Vector2(61, 17)
	])
	draw_colored_polygon(snout, RHINO_BODY)

	# Cuerno principal
	var horn_big := PackedVector2Array([
		Vector2(70, -13),
		Vector2(96, -43),
		Vector2(82, -7)
	])
	draw_colored_polygon(horn_big, YELLOW)

	# Segundo cuerno
	var horn_small := PackedVector2Array([
		Vector2(55, -20),
		Vector2(66, -36),
		Vector2(64, -15)
	])
	draw_colored_polygon(
		horn_small,
		Color(0.95, 0.72, 0.30, 1.0)
	)

	# Orejas
	var ear_back := PackedVector2Array([
		Vector2(34, -20),
		Vector2(28, -41),
		Vector2(43, -25)
	])
	draw_colored_polygon(ear_back, RHINO_BODY)

	var ear_front := PackedVector2Array([
		Vector2(47, -23),
		Vector2(48, -43),
		Vector2(58, -25)
	])
	draw_colored_polygon(ear_front, RHINO_LIGHT)

	# Ojo
	draw_circle(
		Vector2(61, -8),
		4.5,
		RHINO_DARK
	)

	draw_circle(
		Vector2(62.5, -9.5),
		1.5,
		Color.WHITE
	)

	# Nariz
	draw_circle(
		Vector2(85, 8),
		2.7,
		RHINO_DARK
	)

	# Cola corta
	draw_line(
		Vector2(-62, -2),
		Vector2(-76, 7),
		RHINO_BODY,
		5.0
	)

	draw_line(
		Vector2(-76, 7),
		Vector2(-80, 14),
		RHINO_DARK,
		4.0
	)

	# Detalles tecnológicos
	draw_line(
		Vector2(-34, -8),
		Vector2(5, -8),
		CYAN,
		2.0
	)

	draw_circle(
		Vector2(-14, -8),
		4.5,
		CYAN
	)

	draw_line(
		Vector2(-4, -8),
		Vector2(15, 5),
		GREEN,
		2.0
	)


func _draw_leg(base: Vector2) -> void:
	draw_line(
		base,
		base + Vector2(-2, 27),
		RHINO_BODY,
		13.0
	)

	draw_line(
		base + Vector2(-7, 28),
		base + Vector2(7, 28),
		RHINO_DARK,
		6.0
	)
