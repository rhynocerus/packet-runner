class_name RhinoPlayer
extends Node2D

const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)
const BG := Color(0.027, 0.067, 0.122, 1.0)

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
		75.0,
		viewport_size.x - 105.0
	)

	position.y = clampf(
		position.y,
		155.0,
		viewport_size.y - 80.0
	)


func _draw() -> void:
	var pulse := (sin(elapsed * 4.0) + 1.0) * 0.5

	draw_circle(
		Vector2.ZERO,
		54.0 + pulse * 4.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.055)
	)

	draw_circle(
		Vector2.ZERO,
		44.0,
		Color(CYAN.r, CYAN.g, CYAN.b, 0.09)
	)

	var body := PackedVector2Array([
		Vector2(-45, -25),
		Vector2(20, -31),
		Vector2(50, -10),
		Vector2(38, 24),
		Vector2(-35, 27),
		Vector2(-55, 7)
	])

	draw_colored_polygon(body, GREEN)

	var head := Vector2(45, -10)

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
		Vector2(-32, 20),
		Vector2(-37, 48),
		GREEN,
		10.0
	)

	draw_line(
		Vector2(15, 20),
		Vector2(10, 48),
		GREEN,
		10.0
	)

	draw_line(
		Vector2(-48, -8),
		Vector2(-69, -23),
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
		Vector2(-5, -3),
		5.0,
		CYAN
	)
