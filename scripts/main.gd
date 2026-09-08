extends Node2D

const PACKET_SCENE := preload("res://scenes/packet/network_packet.tscn")

const BG := Color(0.027, 0.067, 0.122, 1.0)
const PANEL := Color(0.063, 0.114, 0.196, 1.0)
const CYAN := Color(0.0, 0.898, 1.0, 1.0)
const GREEN := Color(0.192, 0.969, 0.643, 1.0)
const YELLOW := Color(1.0, 0.820, 0.400, 1.0)
const RED := Color(1.0, 0.259, 0.427, 1.0)
const PURPLE := Color(0.72, 0.42, 1.0, 1.0)

const GRID_SIZE := 64
const SPAWN_INTERVAL := 0.95

const LEVEL_2_SCORE := 100
const LEVEL_3_SCORE := 250

const MAX_ESCUDO := 100
const DANO_MALWARE := 15
const PUNTOS_SEGURO_NIVEL_1 := 10
const PUNTOS_SEGURO_NIVEL_2 := 15
const PUNTOS_SEGURO_NIVEL_3 := 20

const FIREWALL_RESTORE := 25
const BOOST_DURATION := 8.0

var elapsed := 0.0
var grid_offset := 0.0
var spawn_elapsed := 0.0

var puntos: int = 0
var escudo: int = MAX_ESCUDO
var game_over: bool = false
var game_started: bool = false

var current_level: int = 1
var world_speed_scale: float = 1.0

var score_multiplier: int = 1
var boost_time_left: float = 0.0

var puntos_label: Label
var escudo_label: Label
var level_label: Label
var legend_label: Label
var tool_status_label: Label
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
	current_level = 1
	world_speed_scale = 1.0
	score_multiplier = 1
	boost_time_left = 0.0
	_update_hud()
	_update_tool_status()

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

	level_label = Label.new()
	level_label.position = Vector2(610, 25)
	level_label.custom_minimum_size = Vector2(210, 30)
	level_label.add_theme_font_size_override("font_size", 16)
	add_child(level_label)

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

	legend_label = Label.new()
	legend_label.text = "● SEGURO +10     ◆ MALWARE -15 ESCUDO"
	legend_label.position = Vector2(835, 62)
	legend_label.add_theme_font_size_override("font_size", 13)
	legend_label.add_theme_color_override(
		"font_color",
		Color(0.78, 0.86, 0.92, 1.0)
	)
	add_child(legend_label)

	tool_status_label = Label.new()
	tool_status_label.position = Vector2(835, 84)
	tool_status_label.custom_minimum_size = Vector2(410, 20)
	tool_status_label.add_theme_font_size_override(
		"font_size",
		11
	)
	tool_status_label.add_theme_color_override(
		"font_color",
		CYAN
	)
	add_child(tool_status_label)

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
	get_tree().paused = true

	var viewport_size := get_viewport_rect().size

	start_layer = CanvasLayer.new()
	start_layer.name = "StartLayer"
	start_layer.layer = 30
	start_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(start_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	start_layer.add_child(root)

	# Fondo oscuro.
	var darkness := ColorRect.new()
	darkness.color = Color(0.004, 0.012, 0.025, 1.0)
	darkness.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(darkness)

	# --------------------------------------------------------
	# BRANDING RHYNUS COMPLETO
	# --------------------------------------------------------

	# --------------------------------------------------------
	# BRANDING RHYNUS COMO SPRITE2D
	#
	# La escala se calcula usando el tamaño REAL de la imagen.
	# Así nunca puede recortarse.
	# --------------------------------------------------------

	var target_logo_width := minf(
		viewport_size.x * 0.56,
		560.0
	)

	var target_logo_height := minf(
		viewport_size.y * 0.44,
		315.0
	)

	var logo := Sprite2D.new()

	logo.texture = load(
		"res://assets/branding/rhynus/rhynus-splash.png"
	) as Texture2D

	var texture_size := logo.texture.get_size()

	var logo_scale_factor := minf(
		target_logo_width / texture_size.x,
		target_logo_height / texture_size.y
	)

	var logo_target_scale := (
		Vector2.ONE * logo_scale_factor
	)

	var logo_center_y := (
		18.0
		+ target_logo_height * 0.5
	)

	logo.position = Vector2(
		viewport_size.x * 0.5,
		logo_center_y
	)

	logo.scale = (
		logo_target_scale * 1.035
	)

	logo.rotation = deg_to_rad(-0.20)
	logo.modulate.a = 0.0

	root.add_child(logo)

	# --------------------------------------------------------
	# PANEL DE JUEGO DEBAJO DEL BRANDING
	# --------------------------------------------------------

	var panel_width := minf(
		viewport_size.x - 90.0,
		620.0
	)

	var panel_height := 176.0

	var logo_bottom := (
		logo.position.y
		+ texture_size.y
		* logo_target_scale.y
		* 0.5
	)

	var desired_panel_y := (
		logo_bottom + 12.0
	)

	var panel_y := minf(
		desired_panel_y,
		viewport_size.y
		- panel_height
		- 18.0
	)

	var info_panel := Panel.new()

	info_panel.position = Vector2(
		(viewport_size.x - panel_width) * 0.5,
		panel_y
	)

	info_panel.size = Vector2(
		panel_width,
		panel_height
	)

	info_panel.modulate.a = 0.0
	root.add_child(info_panel)

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = Color(
		0.012,
		0.050,
		0.085,
		0.96
	)

	panel_style.border_color = Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.75
	)

	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2

	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18

	panel_style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.58
	)

	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0.0, 5.0)

	info_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	var presents := Label.new()
	presents.text = "PRESENTA"
	presents.position = Vector2(0.0, 9.0)
	presents.size = Vector2(panel_width, 18.0)
	presents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	presents.add_theme_font_size_override("font_size", 11)
	presents.add_theme_color_override("font_color", GREEN)
	presents.modulate.a = 0.0
	info_panel.add_child(presents)

	# Resplandor de título.
	var title_glow := Label.new()
	title_glow.text = "PACKET RUNNER"
	title_glow.position = Vector2(0.0, 25.0)
	title_glow.size = Vector2(panel_width, 40.0)
	title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_glow.add_theme_font_size_override(
		"font_size",
		29
	)

	title_glow.add_theme_color_override(
		"font_color",
		Color(CYAN.r, CYAN.g, CYAN.b, 0.30)
	)

	title_glow.add_theme_color_override(
		"font_outline_color",
		Color(CYAN.r, CYAN.g, CYAN.b, 0.24)
	)

	title_glow.add_theme_constant_override(
		"outline_size",
		10
	)

	title_glow.modulate.a = 0.0
	info_panel.add_child(title_glow)

	var game_title := Label.new()
	game_title.text = "PACKET RUNNER"
	game_title.position = Vector2(0.0, 25.0)
	game_title.size = Vector2(panel_width, 40.0)
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	game_title.add_theme_font_size_override(
		"font_size",
		29
	)

	game_title.add_theme_color_override(
		"font_color",
		CYAN
	)

	game_title.add_theme_color_override(
		"font_outline_color",
		Color(0, 0, 0, 1)
	)

	game_title.add_theme_constant_override(
		"outline_size",
		5
	)

	game_title.modulate.a = 0.0
	info_panel.add_child(game_title)

	var subtitle := Label.new()
	subtitle.text = (
		"DEFIENDE LA RED · COME BYTES SEGUROS · "
		+ "EVITA EL MALWARE"
	)

	subtitle.position = Vector2(0.0, 60.0)
	subtitle.size = Vector2(panel_width, 20.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle.add_theme_font_size_override(
		"font_size",
		11
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(0.90, 0.95, 1.0, 1.0)
	)

	subtitle.modulate.a = 0.0
	info_panel.add_child(subtitle)

	# --------------------------------------------------------
	# JUGAR
	# --------------------------------------------------------

	var play_button := Button.new()
	play_button.text = "JUGAR"

	play_button.size = Vector2(
		260.0,
		48.0
	)

	play_button.position = Vector2(
		(panel_width - 260.0) * 0.5,
		88.0
	)

	play_button.pivot_offset = (
		play_button.size * 0.5
	)

	play_button.add_theme_font_size_override(
		"font_size",
		19
	)

	play_button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	play_button.add_theme_color_override(
		"font_outline_color",
		Color(0, 0, 0, 1)
	)

	play_button.add_theme_constant_override(
		"outline_size",
		4
	)

	play_button.disabled = true
	play_button.modulate.a = 0.0
	play_button.pressed.connect(_start_game)

	_style_rhynus_button(
		play_button,
		CYAN
	)

	info_panel.add_child(play_button)

	var hint := Label.new()
	hint.text = "PC · MÓVIL · WEB"

	hint.position = Vector2(
		0.0,
		144.0
	)

	hint.size = Vector2(
		panel_width,
		18.0
	)

	hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hint.add_theme_font_size_override(
		"font_size",
		11
	)

	hint.add_theme_color_override(
		"font_color",
		Color(0.82, 0.91, 0.97, 1.0)
	)

	hint.modulate.a = 0.0
	info_panel.add_child(hint)

	# --------------------------------------------------------
	# BARRIDOS
	# --------------------------------------------------------

	var scan_cyan := ColorRect.new()

	scan_cyan.color = Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.52
	)

	scan_cyan.position = Vector2(
		-20.0,
		0.0
	)

	scan_cyan.size = Vector2(
		5.0,
		viewport_size.y
	)

	scan_cyan.modulate.a = 0.0
	scan_cyan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scan_cyan)

	var scan_green := ColorRect.new()

	scan_green.color = Color(
		GREEN.r,
		GREEN.g,
		GREEN.b,
		0.25
	)

	scan_green.position = Vector2(
		-55.0,
		0.0
	)

	scan_green.size = Vector2(
		3.0,
		viewport_size.y
	)

	scan_green.modulate.a = 0.0
	scan_green.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scan_green)

	# --------------------------------------------------------
	# ANIMACIÓN DE ENTRADA
	# --------------------------------------------------------

	var logo_tween := start_layer.create_tween()

	logo_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	logo_tween.set_parallel(true)

	logo_tween.tween_property(
		logo,
		"modulate:a",
		1.0,
		0.60
	)

	logo_tween.tween_property(
		logo,
		"scale",
		logo_target_scale,
		1.55
	).set_trans(
		Tween.TRANS_QUINT
	).set_ease(
		Tween.EASE_OUT
	)

	logo_tween.tween_property(
		logo,
		"rotation",
		0.0,
		1.25
	)

	var panel_tween := start_layer.create_tween()

	panel_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	panel_tween.tween_interval(0.62)

	panel_tween.tween_property(
		info_panel,
		"modulate:a",
		1.0,
		0.34
	)

	var text_tween := start_layer.create_tween()

	text_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	text_tween.tween_interval(0.82)

	text_tween.tween_property(
		presents,
		"modulate:a",
		1.0,
		0.20
	)

	text_tween.tween_property(
		game_title,
		"modulate:a",
		1.0,
		0.25
	)

	text_tween.parallel().tween_property(
		title_glow,
		"modulate:a",
		0.36,
		0.25
	)

	text_tween.parallel().tween_property(
		subtitle,
		"modulate:a",
		1.0,
		0.25
	)

	text_tween.tween_property(
		play_button,
		"modulate:a",
		1.0,
		0.25
	)

	text_tween.parallel().tween_property(
		hint,
		"modulate:a",
		1.0,
		0.25
	)

	text_tween.tween_callback(
		func():
			if is_instance_valid(play_button):
				play_button.disabled = false
	)

	text_tween.tween_callback(
		_start_rhynus_idle_animation.bind(
			logo,
			play_button,
			title_glow,
			logo_target_scale
		)
	)

	# --------------------------------------------------------
	# BARRIDO EN LOOP
	# --------------------------------------------------------

	var scan_loop := start_layer.create_tween()

	scan_loop.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	scan_loop.set_loops()

	scan_loop.tween_callback(
		func():
			scan_cyan.position.x = -20.0
			scan_green.position.x = -55.0
			scan_cyan.modulate.a = 0.0
			scan_green.modulate.a = 0.0
	)

	scan_loop.tween_interval(0.35)

	scan_loop.tween_property(
		scan_cyan,
		"modulate:a",
		0.68,
		0.10
	)

	scan_loop.parallel().tween_property(
		scan_green,
		"modulate:a",
		0.40,
		0.10
	)

	scan_loop.parallel().tween_property(
		scan_cyan,
		"position:x",
		viewport_size.x + 30.0,
		1.00
	)

	scan_loop.parallel().tween_property(
		scan_green,
		"position:x",
		viewport_size.x + 10.0,
		1.12
	)

	scan_loop.tween_property(
		scan_cyan,
		"modulate:a",
		0.0,
		0.16
	)

	scan_loop.parallel().tween_property(
		scan_green,
		"modulate:a",
		0.0,
		0.16
	)

	scan_loop.tween_interval(0.55)


func _style_rhynus_button(
	button: Button,
	accent: Color
) -> void:
	var normal := StyleBoxFlat.new()

	normal.bg_color = Color(
		0.025,
		0.10,
		0.16,
		0.98
	)

	normal.border_color = accent

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.corner_radius_top_left = 13
	normal.corner_radius_top_right = 13
	normal.corner_radius_bottom_left = 13
	normal.corner_radius_bottom_right = 13

	normal.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.48
	)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0.0, 3.0)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(
		0.04,
		0.17,
		0.24,
		1.0
	)
	hover.border_color = GREEN

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(
		0.02,
		0.07,
		0.12,
		1.0
	)
	pressed.border_color = YELLOW

	button.add_theme_stylebox_override(
		"normal",
		normal
	)
	button.add_theme_stylebox_override(
		"hover",
		hover
	)
	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)
	button.add_theme_stylebox_override(
		"focus",
		hover
	)


func _start_rhynus_idle_animation(
	logo: Node2D,
	play_button: Button,
	title_glow: Label,
	base_scale: Vector2
) -> void:
	if not is_instance_valid(start_layer):
		return

	if not is_instance_valid(logo):
		return

	var logo_idle := start_layer.create_tween()
	logo_idle.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	logo_idle.set_loops()

	logo_idle.tween_property(
		logo,
		"scale",
		base_scale * 1.010,
		2.4
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	logo_idle.tween_property(
		logo,
		"scale",
		base_scale,
		2.4
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	var button_idle := start_layer.create_tween()
	button_idle.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	button_idle.set_loops()

	button_idle.tween_interval(0.55)

	button_idle.tween_property(
		play_button,
		"scale",
		Vector2(1.025, 1.025),
		0.35
	).set_trans(
		Tween.TRANS_SINE
	)

	button_idle.tween_property(
		play_button,
		"scale",
		Vector2.ONE,
		0.35
	).set_trans(
		Tween.TRANS_SINE
	)

	button_idle.tween_interval(0.75)

	var sparkle := start_layer.create_tween()
	sparkle.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	sparkle.set_loops()

	sparkle.tween_property(
		title_glow,
		"modulate:a",
		0.62,
		0.22
	)

	sparkle.tween_property(
		title_glow,
		"modulate:a",
		0.18,
		0.55
	)

	sparkle.tween_interval(0.95)


func _start_game() -> void:
	if is_instance_valid(start_layer):
		start_layer.queue_free()

	start_layer = null
	game_started = true
	pause_button.visible = true
	get_tree().paused = false

	var music := (
		get_node_or_null("BackgroundMusic")
		as AudioStreamPlayer
	)

	if music:
		if music.stream is AudioStreamOggVorbis:
			var ogg_stream := (
				music.stream
				as AudioStreamOggVorbis
			)
			ogg_stream.loop = true

		if not music.playing:
			music.play()


func _pause_game() -> void:
	if not game_started or game_over or get_tree().paused:
		return

	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 40
	pause_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_layer)

	var viewport_size := get_viewport_rect().size

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.015, 0.03, 0.80)
	shade.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.add_child(shade)

	var panel := Panel.new()
	panel.size = Vector2(430.0, 265.0)
	panel.position = (
		viewport_size - panel.size
	) * 0.5
	pause_layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(
		0.02,
		0.065,
		0.11,
		0.98
	)
	style.border_color = Color(
		CYAN.r,
		CYAN.g,
		CYAN.b,
		0.78
	)

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20

	style.shadow_color = Color(0, 0, 0, 0.60)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)

	panel.add_theme_stylebox_override(
		"panel",
		style
	)

	var brand := Label.new()
	brand.text = "RHYNUS // PACKET RUNNER"
	brand.position = Vector2(0.0, 20.0)
	brand.size = Vector2(430.0, 22.0)
	brand.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	brand.add_theme_font_size_override(
		"font_size",
		12
	)
	brand.add_theme_color_override(
		"font_color",
		GREEN
	)
	panel.add_child(brand)

	var title := Label.new()
	title.text = "PAUSA"
	title.position = Vector2(0.0, 49.0)
	title.size = Vector2(430.0, 42.0)
	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	title.add_theme_font_size_override(
		"font_size",
		32
	)
	title.add_theme_color_override(
		"font_color",
		CYAN
	)
	title.add_theme_color_override(
		"font_outline_color",
		Color(0, 0, 0, 1)
	)
	title.add_theme_constant_override(
		"outline_size",
		5
	)
	panel.add_child(title)

	var status := Label.new()
	status.text = (
		"LA RED QUEDA CONGELADA HASTA TU REGRESO"
	)
	status.position = Vector2(0.0, 92.0)
	status.size = Vector2(430.0, 22.0)
	status.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	status.add_theme_font_size_override(
		"font_size",
		11
	)
	status.add_theme_color_override(
		"font_color",
		Color(0.82, 0.90, 0.96, 1.0)
	)
	panel.add_child(status)

	var resume := Button.new()
	resume.text = "CONTINUAR"
	resume.size = Vector2(260.0, 48.0)
	resume.position = Vector2(85.0, 130.0)
	resume.add_theme_font_size_override(
		"font_size",
		18
	)
	_style_rhynus_button(resume, CYAN)
	resume.pressed.connect(_resume_game)
	panel.add_child(resume)

	var restart := Button.new()
	restart.text = "REINICIAR"
	restart.size = Vector2(260.0, 44.0)
	restart.position = Vector2(85.0, 191.0)
	restart.add_theme_font_size_override(
		"font_size",
		16
	)
	_style_rhynus_button(restart, GREEN)
	restart.pressed.connect(_restart_from_pause)
	panel.add_child(restart)

	get_tree().paused = true

	var intro := pause_layer.create_tween()
	intro.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	panel.scale = Vector2(0.96, 0.96)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0

	intro.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.18
	)

	intro.parallel().tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.22
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


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

	if boost_time_left > 0.0:
		boost_time_left = maxf(
			0.0,
			boost_time_left - delta
		)

		if boost_time_left <= 0.0:
			score_multiplier = 1

		_update_tool_status()

	grid_offset = fmod(
		elapsed * 24.0,
		float(GRID_SIZE)
	)

	var spawn_interval := _get_spawn_interval()

	if spawn_elapsed >= spawn_interval:
		spawn_elapsed -= spawn_interval
		_spawn_packet()

	queue_redraw()


func _spawn_packet(extra_x: float = 0.0) -> void:
	var packet := PACKET_SCENE.instantiate() as NetworkPacket
	var viewport_size := get_viewport_rect().size

	var type := NetworkPacket.PacketType.SAFE

	var roll := rng.randf()
	var malware_chance := _get_malware_chance()
	var firewall_chance := _get_firewall_chance()
	var boost_chance := _get_boost_chance()

	if roll < malware_chance:
		type = NetworkPacket.PacketType.MALWARE

	elif roll < (
		malware_chance
		+ firewall_chance
	):
		type = NetworkPacket.PacketType.FIREWALL

	elif roll < (
		malware_chance
		+ firewall_chance
		+ boost_chance
	):
		type = NetworkPacket.PacketType.BOOST

	var speed_range := _get_packet_speed_range()
	var packet_speed := rng.randf_range(
		speed_range.x,
		speed_range.y
	)

	if (
		type == NetworkPacket.PacketType.FIREWALL
		or type == NetworkPacket.PacketType.BOOST
	):
		packet_speed *= 0.86

	packet.position = Vector2(
		viewport_size.x + 50.0 + extra_x,
		rng.randf_range(150.0, viewport_size.y - 60.0)
	)

	packet.configure(type, packet_speed)
	packet.collected.connect(_on_packet_collected)

	add_child(packet)


func _on_packet_collected(packet_type: int) -> void:
	match packet_type:
		NetworkPacket.PacketType.SAFE:
			var base_points := _get_safe_points()

			var awarded := (
				base_points
				* score_multiplier
			)

			puntos += awarded

			var safe_sfx := (
				get_node_or_null("SfxSafe")
				as AudioStreamPlayer
			)

			if safe_sfx:
				safe_sfx.pitch_scale = (
					_get_safe_sfx_pitch()
				)
				safe_sfx.play()

			_show_pickup_feedback(
				"+%d" % awarded,
				_get_points_color()
			)

			if OS.is_debug_build():
				print(
					"Paquete seguro -> Puntos: ",
					puntos
				)

		NetworkPacket.PacketType.MALWARE:
			var malware_sfx := (
				get_node_or_null("SfxMalware")
				as AudioStreamPlayer
			)

			if malware_sfx:
				malware_sfx.pitch_scale = (
					_get_malware_sfx_pitch()
				)
				malware_sfx.play()

			escudo = clampi(
				escudo - DANO_MALWARE,
				0,
				MAX_ESCUDO
			)

			_show_pickup_feedback(
				"MALWARE -%d" % DANO_MALWARE,
				RED
			)

			if OS.is_debug_build():
				print(
					"Malware -> Escudo: ",
					escudo
				)

		NetworkPacket.PacketType.FIREWALL:
			var old_shield := escudo

			escudo = clampi(
				escudo + FIREWALL_RESTORE,
				0,
				MAX_ESCUDO
			)

			var restored := (
				escudo - old_shield
			)

			var firewall_sfx := (
				get_node_or_null("SfxSafe")
				as AudioStreamPlayer
			)

			if firewall_sfx:
				firewall_sfx.pitch_scale = 0.84
				firewall_sfx.play()

			if restored > 0:
				_show_pickup_feedback(
					"FIREWALL +%d" % restored,
					CYAN
				)
			else:
				_show_pickup_feedback(
					"FIREWALL LISTO",
					CYAN
				)

		NetworkPacket.PacketType.BOOST:
			score_multiplier = 2
			boost_time_left = BOOST_DURATION

			var boost_sfx := (
				get_node_or_null("SfxSafe")
				as AudioStreamPlayer
			)

			if boost_sfx:
				boost_sfx.pitch_scale = 1.32
				boost_sfx.play()

			_show_pickup_feedback(
				"BOOST x2  8s",
				YELLOW
			)

	_update_level()
	_update_hud()
	_update_tool_status()

	if escudo <= 0 and not game_over:
		_show_game_over()


func _update_level() -> void:
	var new_level := 1

	if puntos >= LEVEL_3_SCORE:
		new_level = 3
	elif puntos >= LEVEL_2_SCORE:
		new_level = 2

	if new_level == current_level:
		return

	var previous_level := current_level
	current_level = new_level

	match current_level:
		1:
			world_speed_scale = 1.0
		2:
			world_speed_scale = 1.25
		3:
			world_speed_scale = 1.55

	_show_level_transition(
		previous_level,
		current_level
	)

	_switch_level_music(current_level)

	queue_redraw()


func _show_level_transition(
	previous_level: int,
	new_level: int
) -> void:
	var layer := CanvasLayer.new()
	layer.name = "LevelTransition"
	layer.layer = 25
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var viewport_size := get_viewport_rect().size

	var panel := Panel.new()
	panel.size = Vector2(560.0, 92.0)
	panel.position = Vector2(
		(viewport_size.x - 560.0) * 0.5,
		-110.0
	)
	panel.modulate.a = 0.0
	layer.add_child(panel)

	var accent := YELLOW

	if new_level == 3:
		accent = RED

	var style := StyleBoxFlat.new()
	style.bg_color = Color(
		0.015,
		0.055,
		0.095,
		0.96
	)
	style.border_color = accent

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16

	style.shadow_color = Color(0, 0, 0, 0.50)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 5)

	panel.add_theme_stylebox_override(
		"panel",
		style
	)

	var completed := Label.new()
	completed.text = (
		"NIVEL %d SUPERADO" % previous_level
	)
	completed.position = Vector2(0.0, 13.0)
	completed.size = Vector2(560.0, 22.0)
	completed.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	completed.add_theme_font_size_override(
		"font_size",
		12
	)
	completed.add_theme_color_override(
		"font_color",
		GREEN
	)
	panel.add_child(completed)

	var title := Label.new()

	if new_level == 2:
		title.text = "NIVEL 2  //  OCASO"
	else:
		title.text = "NIVEL 3  //  TORMENTA DIGITAL"

	title.position = Vector2(0.0, 36.0)
	title.size = Vector2(560.0, 35.0)
	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	title.add_theme_font_size_override(
		"font_size",
		24
	)
	title.add_theme_color_override(
		"font_color",
		accent
	)
	title.add_theme_color_override(
		"font_outline_color",
		Color(0, 0, 0, 1)
	)
	title.add_theme_constant_override(
		"outline_size",
		4
	)
	panel.add_child(title)

	var message := Label.new()

	if new_level == 2:
		message.text = "EL TRÁFICO DE RED AUMENTA"
	else:
		message.text = "MÁXIMA AMENAZA // MANTÉN EL ESCUDO"

	message.position = Vector2(0.0, 69.0)
	message.size = Vector2(560.0, 17.0)
	message.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	message.add_theme_font_size_override(
		"font_size",
		10
	)
	message.add_theme_color_override(
		"font_color",
		Color(0.88, 0.93, 0.98, 1.0)
	)
	panel.add_child(message)

	var tween := layer.create_tween()

	tween.tween_property(
		panel,
		"position:y",
		122.0,
		0.38
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.parallel().tween_property(
		panel,
		"modulate:a",
		1.0,
		0.22
	)

	tween.tween_interval(1.35)

	tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.30
	)

	tween.parallel().tween_property(
		panel,
		"position:y",
		96.0,
		0.30
	)

	tween.tween_callback(layer.queue_free)


func _get_spawn_interval() -> float:
	match current_level:
		2:
			return 0.78

		3:
			var extra_score := maxf(
				float(puntos - LEVEL_3_SCORE),
				0.0
			)

			return maxf(
				0.48,
				0.64 - extra_score / 2500.0
			)

		_:
			return SPAWN_INTERVAL


func _get_malware_chance() -> float:
	match current_level:
		2:
			return 0.34

		3:
			var extra_score := maxf(
				float(puntos - LEVEL_3_SCORE),
				0.0
			)

			return minf(
				0.55,
				0.42 + extra_score / 5000.0
			)

		_:
			return 0.28


func _get_firewall_chance() -> float:
	match current_level:
		2:
			return 0.07
		3:
			return 0.08
		_:
			return 0.05


func _get_boost_chance() -> float:
	match current_level:
		2:
			return 0.05
		3:
			return 0.06
		_:
			return 0.0


func _get_packet_speed_range() -> Vector2:
	match current_level:
		2:
			return Vector2(210.0, 320.0)
		3:
			return Vector2(260.0, 390.0)
		_:
			return Vector2(150.0, 260.0)


func _get_safe_points() -> int:
	match current_level:
		2:
			return PUNTOS_SEGURO_NIVEL_2
		3:
			return PUNTOS_SEGURO_NIVEL_3
		_:
			return PUNTOS_SEGURO_NIVEL_1


func _get_points_color() -> Color:
	match current_level:
		2:
			return YELLOW
		3:
			return PURPLE
		_:
			return GREEN


func _update_tool_status() -> void:
	if not is_instance_valid(tool_status_label):
		return

	if boost_time_left > 0.0:
		tool_status_label.text = (
			"BOOST x2 ACTIVO  //  %ds"
			% int(ceil(boost_time_left))
		)

		tool_status_label.add_theme_color_override(
			"font_color",
			YELLOW
		)

	else:
		tool_status_label.text = (
			"TOOLS // FIREWALL +25   BOOST x2 8s"
		)

		tool_status_label.add_theme_color_override(
			"font_color",
			Color(
				CYAN.r,
				CYAN.g,
				CYAN.b,
				0.72
			)
		)


func _show_pickup_feedback(
	message: String,
	color: Color
) -> void:
	var player := get_node_or_null(
		"RhinoPlayer"
	) as Node2D

	if not player:
		return

	var feedback := Label.new()

	feedback.text = message
	feedback.position = (
		player.position
		+ Vector2(28.0, -48.0)
	)

	feedback.z_index = 50

	feedback.add_theme_font_size_override(
		"font_size",
		18
	)

	feedback.add_theme_color_override(
		"font_color",
		color
	)

	feedback.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	feedback.add_theme_constant_override(
		"outline_size",
		4
	)

	feedback.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(feedback)

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		feedback,
		"position:y",
		feedback.position.y - 44.0,
		0.75
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		feedback,
		"modulate:a",
		0.0,
		0.75
	)

	tween.chain().tween_callback(
		feedback.queue_free
	)


func _get_safe_sfx_pitch() -> float:
	match current_level:
		2:
			return 1.08
		3:
			return 1.16
		_:
			return 1.0


func _get_malware_sfx_pitch() -> float:
	match current_level:
		2:
			return 0.94
		3:
			return 0.88
		_:
			return 1.0


func _get_music_path(level: int) -> String:
	match level:
		2:
			return (
				"res://assets/audio/music/"
				+ "packet-runner-level2.ogg"
			)

		3:
			return (
				"res://assets/audio/music/"
				+ "packet-runner-level3.ogg"
			)

		_:
			return (
				"res://assets/audio/music/"
				+ "packet-runner-level1.ogg"
			)


func _switch_level_music(level: int) -> void:
	if not game_started:
		return

	var music := (
		get_node_or_null("BackgroundMusic")
		as AudioStreamPlayer
	)

	if not music:
		return

	var path := _get_music_path(level)

	var next_stream := load(path) as AudioStream

	if not next_stream:
		push_warning(
			"No se pudo cargar música: "
			+ path
		)
		return

	if next_stream is AudioStreamOggVorbis:
		var ogg_stream := (
			next_stream
			as AudioStreamOggVorbis
		)
		ogg_stream.loop = true

	var target_volume := -3.0

	match level:
		2:
			target_volume = -2.5
		3:
			target_volume = -2.0

	var fade := create_tween()

	fade.tween_property(
		music,
		"volume_db",
		-24.0,
		0.30
	)

	fade.tween_callback(
		func():
			if not is_instance_valid(music):
				return

			music.stop()
			music.stream = next_stream
			music.play()
	)

	fade.tween_property(
		music,
		"volume_db",
		target_volume,
		0.50
	)


func _update_hud() -> void:
	var points_color := GREEN
	var shield_base_color := CYAN

	var legend_color := Color(
		0.78,
		0.86,
		0.92,
		1.0
	)

	if is_instance_valid(level_label):
		match current_level:
			1:
				level_label.text = (
					"NIVEL 1  //  SABANA"
				)

				level_label.add_theme_color_override(
					"font_color",
					GREEN
				)

				points_color = GREEN
				shield_base_color = CYAN

			2:
				level_label.text = (
					"NIVEL 2  //  OCASO"
				)

				level_label.add_theme_color_override(
					"font_color",
					YELLOW
				)

				points_color = YELLOW
				shield_base_color = GREEN

				legend_color = Color(
					1.0,
					0.78,
					0.40,
					1.0
				)

			3:
				level_label.text = (
					"NIVEL 3  //  TORMENTA"
				)

				level_label.add_theme_color_override(
					"font_color",
					RED
				)

				points_color = PURPLE
				shield_base_color = PURPLE

				legend_color = Color(
					0.72,
					0.62,
					1.0,
					1.0
				)

	puntos_label.text = (
		"PUNTOS  %05d" % puntos
	)

	puntos_label.add_theme_color_override(
		"font_color",
		points_color
	)

	escudo_label.text = (
		"ESCUDO  %d/%d"
		% [
			escudo,
			MAX_ESCUDO
		]
	)

	if escudo > 60:
		escudo_label.add_theme_color_override(
			"font_color",
			shield_base_color
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

	if is_instance_valid(legend_label):
		legend_label.text = (
			"● SEGURO +%d     "
			+ "◆ MALWARE -%d ESCUDO"
		) % [
			_get_safe_points(),
			DANO_MALWARE
		]

		legend_label.add_theme_color_override(
			"font_color",
			legend_color
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
	_draw_level_atmosphere(size)
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
