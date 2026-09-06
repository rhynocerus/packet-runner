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

const TOUCH_DEADZONE := 20.0

var touch_active := false
var touch_index := -1
var touch_target := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch

		if touch_event.pressed and touch_index == -1:
			touch_active = true
			touch_index = touch_event.index
			touch_target = touch_event.position

		elif not touch_event.pressed and touch_event.index == touch_index:
			touch_active = false
			touch_index = -1

	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag

		if drag_event.index == touch_index:
			touch_target = drag_event.position


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

	# En pantallas táctiles, el rinoceronte sigue el dedo.
	if touch_active:
		var touch_delta := touch_target - position

		if touch_delta.length() > TOUCH_DEADZONE:
			movement = touch_delta.normalized()
		else:
			movement = Vector2.ZERO

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

	# Halo sutil
	draw_circle(
		Vector2(-6, 0),
		62.0 + pulse * 2.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.04)
	)

	# Sombra al suelo
	draw_colored_polygon(
		_ellipse_points(
			Vector2(-10, 34),
			Vector2(48, 10),
			28
		),
		Color(0.03, 0.08, 0.12, 0.45)
	)

	# Cuerpo principal
	draw_colored_polygon(
		_ellipse_points(
			Vector2(-14, 0),
			Vector2(54, 34),
			40
		),
		RHINO_BODY
	)

	# Masa del hombro / lomo superior
	var upper_body := PackedVector2Array([
		Vector2(-52, -10),
		Vector2(-26, -28),
		Vector2(10, -31),
		Vector2(36, -20),
		Vector2(28, -3),
		Vector2(-6, -7),
		Vector2(-38, -4)
	])
	draw_colored_polygon(upper_body, RHINO_LIGHT)

	# Vientre / sombreado inferior
	var belly := PackedVector2Array([
		Vector2(-48, 10),
		Vector2(-22, 17),
		Vector2(10, 18),
		Vector2(31, 13),
		Vector2(22, 27),
		Vector2(-34, 28),
		Vector2(-52, 18)
	])
	draw_colored_polygon(belly, Color(0.18, 0.33, 0.38, 1.0))

	# Cuello
	var neck := PackedVector2Array([
		Vector2(18, -18),
		Vector2(44, -16),
		Vector2(49, 14),
		Vector2(23, 19),
		Vector2(10, 4)
	])
	draw_colored_polygon(neck, RHINO_BODY)

	# Cabeza más limpia y algo estilizada
	var head := PackedVector2Array([
		Vector2(32, -20),
		Vector2(52, -24),
		Vector2(72, -16),
		Vector2(84, -2),
		Vector2(81, 14),
		Vector2(63, 24),
		Vector2(40, 20),
		Vector2(26, 6),
		Vector2(24, -7)
	])
	draw_colored_polygon(head, RHINO_LIGHT)

	# Hocico
	var snout := PackedVector2Array([
		Vector2(65, -4),
		Vector2(89, -1),
		Vector2(92, 10),
		Vector2(82, 18),
		Vector2(60, 16)
	])
	draw_colored_polygon(snout, RHINO_BODY)

	# Placa frontal / base del cuerno
	var forehead := PackedVector2Array([
		Vector2(50, -19),
		Vector2(66, -16),
		Vector2(70, -6),
		Vector2(54, -5)
	])
	draw_colored_polygon(forehead, RHINO_BODY)

	# Cuerno principal
	var horn_big := PackedVector2Array([
		Vector2(64, -13),
		Vector2(92, -41),
		Vector2(76, -6)
	])
	draw_colored_polygon(horn_big, YELLOW)

	# Cuerno secundario
	var horn_small := PackedVector2Array([
		Vector2(53, -18),
		Vector2(65, -32),
		Vector2(61, -13)
	])
	draw_colored_polygon(
		horn_small,
		Color(0.93, 0.72, 0.32, 1.0)
	)

	# Orejas
	var ear_back := PackedVector2Array([
		Vector2(33, -20),
		Vector2(28, -36),
		Vector2(41, -24)
	])
	draw_colored_polygon(ear_back, RHINO_DARK)

	var ear_front := PackedVector2Array([
		Vector2(45, -22),
		Vector2(48, -38),
		Vector2(57, -23)
	])
	draw_colored_polygon(ear_front, RHINO_BODY)

	# Ojo
	draw_circle(Vector2(61, -7), 4.0, RHINO_DARK)
	draw_circle(Vector2(62.3, -8.3), 1.3, Color.WHITE)

	# Narinas
	draw_circle(Vector2(84, 7), 2.2, RHINO_DARK)
	draw_circle(Vector2(78, 10), 1.7, RHINO_DARK)

	# Boca sutil
	draw_line(
		Vector2(73, 16),
		Vector2(84, 15),
		RHINO_DARK,
		2.0
	)

	# Cola corta discreta
	draw_line(
		Vector2(-63, 0),
		Vector2(-74, 8),
		RHINO_DARK,
		4.0
	)
	draw_line(
		Vector2(-74, 8),
		Vector2(-78, 14),
		RHINO_DARK,
		3.0
	)

	# Patas
	_draw_leg(Vector2(-42, 18), 26.0)
	_draw_leg(Vector2(-16, 22), 24.0)
	_draw_leg(Vector2(14, 22), 24.0)
	_draw_leg(Vector2(34, 18), 26.0)


func _draw_leg(base: Vector2, height: float = 24.0) -> void:
	# Parte principal de la pata
	draw_line(
		base,
		base + Vector2(0, height),
		RHINO_BODY,
		11.0
	)

	# Pie / pezuña
	_draw_foot(base + Vector2(0, height))


func _draw_foot(center: Vector2) -> void:
	draw_line(
		center + Vector2(-6, 1),
		center + Vector2(6, 1),
		RHINO_DARK,
		5.0
	)
