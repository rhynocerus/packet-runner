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
var game_over: bool = false

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
	get_tree().paused = false
	game_over = false
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
	controls.text = "PC: WASD + FLECHAS  //  MÓVIL: TOCA Y ARRASTRA"
	controls.position = Vector2(32, 680)
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", GREEN)
	add_child(controls)


func _process(delta: float) -> void:
	if game_over:
		return

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

	if escudo <= 0 and not game_over:
		_show_game_over()


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

func _show_game_over() -> void:
	game_over = true

	var music := get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if music:
		music.stop()

	var layer := CanvasLayer.new()
	layer.name = "GameOverLayer"
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(layer)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(480, 280)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", RED)
	content.add_child(title)

	var reason := Label.new()
	reason.text = "ESCUDO AGOTADO // LA RED HA CAÍDO"
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.add_theme_font_size_override("font_size", 18)
	reason.add_theme_color_override("font_color", CYAN)
	content.add_child(reason)

	var final_score := Label.new()
	final_score.text = "PUNTUACIÓN FINAL  %05d" % puntos
	final_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score.add_theme_font_size_override("font_size", 26)
	final_score.add_theme_color_override("font_color", GREEN)
	content.add_child(final_score)

	var retry := Button.new()
	retry.text = "REINTENTAR"
	retry.custom_minimum_size = Vector2(240, 56)
	retry.add_theme_font_size_override("font_size", 20)
	retry.pressed.connect(_retry_game)
	content.add_child(retry)

	get_tree().paused = true


func _retry_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


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
