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
var game_started: bool = false

var puntos_label: Label
var escudo_label: Label
var pause_button: Button
var start_layer: CanvasLayer
var pause_layer: CanvasLayer

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()

	_create_interface()
	_reset_game_state()

	for i in range(5):
		_spawn_packet(float(i) * 190.0)

	_show_start_screen()


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

	pause_button = Button.new()
	pause_button.text = "PAUSA"
	pause_button.position = Vector2(1145, 655)
	pause_button.custom_minimum_size = Vector2(105, 48)
	pause_button.add_theme_font_size_override("font_size", 16)
	pause_button.visible = false
	pause_button.pressed.connect(_pause_game)
	add_child(pause_button)


func _input(event: InputEvent) -> void:
	if not game_started or game_over:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
				if get_tree().paused:
					_resume_game()
				else:
					_pause_game()


func _show_start_screen() -> void:
	game_started = false
	pause_button.visible = false

	start_layer = CanvasLayer.new()
	start_layer.name = "StartLayer"
	start_layer.layer = 30
	start_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(start_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.03, 0.05, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_layer.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 330)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "PACKET RUNNER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", CYAN)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "DEFIENDE LA RED"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", GREEN)
	box.add_child(subtitle)

	var instructions := Label.new()
	instructions.text = "ATRAPA PAQUETES SEGUROS // EVITA EL MALWARE"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 16)
	box.add_child(instructions)

	var play_button := Button.new()
	play_button.text = "JUGAR"
	play_button.custom_minimum_size = Vector2(260, 64)
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.pressed.connect(_start_game)
	box.add_child(play_button)

	get_tree().paused = true


func _start_game() -> void:
	if is_instance_valid(start_layer):
		start_layer.queue_free()

	start_layer = null
	game_started = true
	pause_button.visible = true
	get_tree().paused = false

	var music := get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if music and not music.playing:
		music.play()


func _pause_game() -> void:
	if not game_started or game_over or get_tree().paused:
		return

	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 40
	pause_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(400, 260)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", CYAN)
	box.add_child(title)

	var resume := Button.new()
	resume.text = "CONTINUAR"
	resume.custom_minimum_size = Vector2(250, 58)
	resume.add_theme_font_size_override("font_size", 20)
	resume.pressed.connect(_resume_game)
	box.add_child(resume)

	var restart := Button.new()
	restart.text = "REINICIAR"
	restart.custom_minimum_size = Vector2(250, 58)
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(_restart_from_pause)
	box.add_child(restart)

	get_tree().paused = true


func _resume_game() -> void:
	if is_instance_valid(pause_layer):
		pause_layer.queue_free()

	pause_layer = null
	get_tree().paused = false


func _restart_from_pause() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if game_over or get_tree().paused or not game_started:
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

		var safe_sfx := get_node_or_null("SfxSafe") as AudioStreamPlayer
		if safe_sfx:
			safe_sfx.play()

		if OS.is_debug_build():
			print("Paquete seguro -> Puntos: ", puntos)

	else:
		var malware_sfx := get_node_or_null("SfxMalware") as AudioStreamPlayer
		if malware_sfx:
			malware_sfx.play()

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

	var game_over_sfx := get_node_or_null("SfxGameOver") as AudioStreamPlayer
	if game_over_sfx:
		game_over_sfx.play()

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

	_draw_savanna_background(size)
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


func _draw_savanna_background(size: Vector2) -> void:
	var top := 110.0
	var horizon := size.y * 0.63

	# Cielo en bandas suaves.
	var sky_colors := [
		Color(0.035, 0.10, 0.16, 1.0),
		Color(0.055, 0.16, 0.22, 1.0),
		Color(0.12, 0.25, 0.28, 1.0),
		Color(0.25, 0.34, 0.27, 1.0)
	]

	var band_height := (horizon - top) / float(sky_colors.size())

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

	# Sol lejano.
	draw_circle(
		Vector2(size.x * 0.78, top + 115.0),
		45.0,
		Color(1.0, 0.72, 0.30, 0.75)
	)

	# Montañas lejanas, desplazamiento muy lento.
	var far_offset := fmod(elapsed * 9.0, 280.0)

	for i in range(-1, 7):
		var x := float(i) * 280.0 - far_offset
		var mountain := PackedVector2Array([
			Vector2(x - 80.0, horizon),
			Vector2(x + 25.0, horizon - 125.0),
			Vector2(x + 110.0, horizon - 35.0),
			Vector2(x + 190.0, horizon)
		])

		draw_colored_polygon(
			mountain,
			Color(0.10, 0.20, 0.22, 1.0)
		)

	# Colinas medias.
	var mid_offset := fmod(elapsed * 18.0, 240.0)

	for i in range(-1, 8):
		var x := float(i) * 240.0 - mid_offset
		var hill := PackedVector2Array([
			Vector2(x - 50.0, horizon + 35.0),
			Vector2(x + 55.0, horizon - 48.0),
			Vector2(x + 145.0, horizon - 12.0),
			Vector2(x + 215.0, horizon + 35.0)
		])

		draw_colored_polygon(
			hill,
			Color(0.12, 0.27, 0.23, 1.0)
		)

	# Llanura.
	draw_rect(
		Rect2(
			0,
			horizon,
			size.x,
			size.y - horizon
		),
		Color(0.11, 0.23, 0.16, 1.0)
	)

	# Acacias en plano medio.
	var tree_offset := fmod(elapsed * 28.0, 310.0)

	for i in range(-1, 7):
		var tree_x := float(i) * 310.0 - tree_offset
		var tree_y := horizon + 18.0

		_draw_acacia(
			Vector2(tree_x, tree_y),
			0.75 + float(i % 2) * 0.12
		)

	# Hierba cercana, la capa más rápida.
	var grass_offset := fmod(elapsed * 58.0, 54.0)

	for i in range(-1, int(size.x / 54.0) + 2):
		var x := float(i) * 54.0 - grass_offset
		var base_y := size.y - 8.0

		draw_line(
			Vector2(x, base_y),
			Vector2(x - 8.0, base_y - 27.0),
			Color(0.24, 0.42, 0.20, 0.85),
			3.0
		)

		draw_line(
			Vector2(x + 7.0, base_y),
			Vector2(x + 15.0, base_y - 20.0),
			Color(0.20, 0.36, 0.18, 0.80),
			2.0
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
