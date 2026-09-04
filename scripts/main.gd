extends Node2D

const PACKET_SCENE := preload("res://scenes/packet/network_packet.tscn")

const BG := Color(0.027, 0.067, 0.122, 1.0)
const PANEL := Color(0.063, 0.114, 0.196, 1.0)
const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)
const RED := Color(1.0, 0.259, 0.427, 1.0)

const GRID_SIZE := 64
const SPAWN_INTERVAL := 0.95

const MAX_ESCUDO := 100
const DANO_MALWARE := 15
const PUNTOS_SEGURO := 10

var elapsed := 0.0
var grid_offset := 0.0
var spawn_elapsed := 0.0

var puntos: int = 0
var escudo: int = MAX_ESCUDO

var puntos_label: Label
var escudo_label: Label

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()

	_create_interface()
	_reset_game_state()

	for i in range(5):
		_spawn_packet(float(i) * 190.0)


func _reset_game_state() -> void:
	puntos = 0
	escudo = MAX_ESCUDO
	_update_hud()

	print(
		"Estado inicial -> Puntos: ",
		puntos,
		" | Escudo: ",
		escudo
	)


func _create_interface() -> void:
	var title := Label.new()
	title.text = "PACKET RUNNER"
	title.position = Vector2(32, 18)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", CYAN)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "DEFIENDE LA RED  //  PROTOTIPO 0.2"
	subtitle.position = Vector2(35, 62)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override(
		"font_color",
		Color(0.75, 0.84, 0.92, 1.0)
	)
	add_child(subtitle)

	puntos_label = Label.new()
	puntos_label.position = Vector2(835, 23)
	puntos_label.custom_minimum_size = Vector2(190, 32)
	puntos_label.add_theme_font_size_override("font_size", 20)
	puntos_label.add_theme_color_override("font_color", GREEN)
	add_child(puntos_label)

	escudo_label = Label.new()
	escudo_label.position = Vector2(1030, 23)
	escudo_label.custom_minimum_size = Vector2(220, 32)
	escudo_label.add_theme_font_size_override("font_size", 20)
	add_child(escudo_label)

	var legend := Label.new()
	legend.text = "● SEGURO +10     ◆ MALWARE -15 ESCUDO"
	legend.position = Vector2(835, 62)
	legend.add_theme_font_size_override("font_size", 13)
	legend.add_theme_color_override(
		"font_color",
		Color(0.78, 0.86, 0.92, 1.0)
	)
	add_child(legend)

	var controls := Label.new()
	controls.text = "INTERCEPTA LOS SEGUROS  //  EVITA EL MALWARE  //  WASD + FLECHAS"
	controls.position = Vector2(32, 680)
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", GREEN)
	add_child(controls)


func _process(delta: float) -> void:
	elapsed += delta
	spawn_elapsed += delta

	grid_offset = fmod(
		elapsed * 24.0,
		float(GRID_SIZE)
	)

	if spawn_elapsed >= SPAWN_INTERVAL:
		spawn_elapsed -= SPAWN_INTERVAL
		_spawn_packet()

	queue_redraw()


func _spawn_packet(extra_x: float = 0.0) -> void:
	var packet := PACKET_SCENE.instantiate() as NetworkPacket
	var viewport_size := get_viewport_rect().size

	var type := NetworkPacket.PacketType.SAFE

	if rng.randf() < 0.28:
		type = NetworkPacket.PacketType.MALWARE

	var packet_speed := rng.randf_range(150.0, 260.0)

	packet.position = Vector2(
		viewport_size.x + 50.0 + extra_x,
		rng.randf_range(150.0, viewport_size.y - 60.0)
	)

	packet.configure(type, packet_speed)
	packet.collected.connect(_on_packet_collected)

	add_child(packet)


func _on_packet_collected(packet_type: int) -> void:
	if packet_type == NetworkPacket.PacketType.SAFE:
		puntos += PUNTOS_SEGURO

		if OS.is_debug_build():
			print("Paquete seguro -> Puntos: ", puntos)

	else:
		escudo = clampi(
			escudo - DANO_MALWARE,
			0,
			MAX_ESCUDO
		)

		if OS.is_debug_build():
			print("Malware -> Escudo: ", escudo)

	_update_hud()


func _update_hud() -> void:
	puntos_label.text = "PUNTOS  %05d" % puntos
	escudo_label.text = "ESCUDO  %d/%d" % [
		escudo,
		MAX_ESCUDO
	]

	if escudo > 60:
		escudo_label.add_theme_color_override(
			"font_color",
			CYAN
		)
	elif escudo > 40:
		escudo_label.add_theme_color_override(
			"font_color",
			YELLOW
		)
	else:
		escudo_label.add_theme_color_override(
			"font_color",
			RED
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
