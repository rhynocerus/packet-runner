class_name NetworkPacket
extends Area2D

signal collected(packet_type: int)

enum PacketType {
	SAFE,
	MALWARE,
	FIREWALL,
	BOOST
}

const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const RED := Color(1.0, 0.259, 0.427, 1.0)
const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)
const PURPLE := Color(0.72, 0.42, 1.0, 1.0)

var packet_type: PacketType = PacketType.SAFE
var speed := 180.0
var elapsed := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func configure(type: PacketType, packet_speed: float) -> void:
	packet_type = type
	speed = packet_speed
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	position.x -= speed * delta

	if packet_type == PacketType.MALWARE:
		rotation += delta * 1.4

	elif packet_type == PacketType.BOOST:
		rotation -= delta * 2.2

	if position.x < -60.0:
		queue_free()

	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collected.emit(packet_type)
		queue_free()


func _draw() -> void:
	var pulse := (sin(elapsed * 6.0) + 1.0) * 0.5

	if packet_type == PacketType.SAFE:
		draw_circle(
			Vector2.ZERO,
			18.0 + pulse * 3.0,
			Color(GREEN.r, GREEN.g, GREEN.b, 0.10)
		)

		draw_circle(
			Vector2.ZERO,
			8.0,
			GREEN
		)

		draw_circle(
			Vector2.ZERO,
			3.0,
			CYAN
		)

	elif packet_type == PacketType.MALWARE:
		draw_circle(
			Vector2.ZERO,
			20.0 + pulse * 4.0,
			Color(RED.r, RED.g, RED.b, 0.12)
		)

		var diamond := PackedVector2Array([
			Vector2(0, -12),
			Vector2(12, 0),
			Vector2(0, 12),
			Vector2(-12, 0)
		])

		draw_colored_polygon(
			diamond,
			RED
		)

		draw_line(
			Vector2(-5, -5),
			Vector2(5, 5),
			Color.WHITE,
			2.0
		)

		draw_line(
			Vector2(5, -5),
			Vector2(-5, 5),
			Color.WHITE,
			2.0
		)

	elif packet_type == PacketType.FIREWALL:
		draw_circle(
			Vector2.ZERO,
			22.0 + pulse * 3.0,
			Color(CYAN.r, CYAN.g, CYAN.b, 0.13)
		)

		var shield := PackedVector2Array([
			Vector2(0, -15),
			Vector2(13, -8),
			Vector2(11, 7),
			Vector2(0, 16),
			Vector2(-11, 7),
			Vector2(-13, -8)
		])

		draw_colored_polygon(
			shield,
			Color(0.03, 0.22, 0.32, 1.0)
		)

		var shield_outline := PackedVector2Array([
			Vector2(0, -15),
			Vector2(13, -8),
			Vector2(11, 7),
			Vector2(0, 16),
			Vector2(-11, 7),
			Vector2(-13, -8),
			Vector2(0, -15)
		])

		draw_polyline(
			shield_outline,
			CYAN,
			3.0
		)

		draw_line(
			Vector2(0, -9),
			Vector2(0, 9),
			Color.WHITE,
			2.0
		)

		draw_line(
			Vector2(-7, 0),
			Vector2(7, 0),
			Color.WHITE,
			2.0
		)

	elif packet_type == PacketType.BOOST:
		draw_circle(
			Vector2.ZERO,
			22.0 + pulse * 4.0,
			Color(YELLOW.r, YELLOW.g, YELLOW.b, 0.14)
		)

		var bolt := PackedVector2Array([
			Vector2(-4, -16),
			Vector2(8, -16),
			Vector2(2, -3),
			Vector2(11, -3),
			Vector2(-7, 17),
			Vector2(-2, 4),
			Vector2(-11, 4)
		])

		draw_colored_polygon(
			bolt,
			YELLOW
		)

		draw_circle(
			Vector2.ZERO,
			3.0,
			PURPLE
		)
