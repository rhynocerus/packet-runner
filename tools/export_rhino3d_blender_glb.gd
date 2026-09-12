extends SceneTree

const RHINO_SCENE := preload(
	"res://scenes/3d/rhino/rhino_3d.tscn"
)

const OUTPUT_DIR := "res://exports/rhino3d"
const OUTPUT_FILE := "res://exports/rhino3d/rhino3d-v0.9.1-blender.glb"


func _init() -> void:
	call_deferred("_export_rhino")


func _force_all_visible(node: Node) -> void:
	if node is Node3D:
		(node as Node3D).visible = true

	for child in node.get_children():
		_force_all_visible(child)


func _export_rhino() -> void:
	print("===== RHINO 3D -> GLB =====")

	var rhino := RHINO_SCENE.instantiate()
	root.add_child(rhino)

	# Dejamos que _ready() construya toda la geometría procedural.
	await process_frame

	if rhino.has_method("set_running"):
		rhino.set_running(false)

	# Blender 4.5 aún no importa KHR_node_visibility.
	# Para el archivo de modelado hacemos visibles
	# temporalmente todas las piezas.
	_force_all_visible(rhino)

	await process_frame

	var output_dir := ProjectSettings.globalize_path(
		OUTPUT_DIR
	)

	var mkdir_error := DirAccess.make_dir_recursive_absolute(
		output_dir
	)

	if mkdir_error != OK:
		push_error(
			"No pude crear directorio: %s"
			% error_string(mkdir_error)
		)
		quit(1)
		return

	var document := GLTFDocument.new()
	var state := GLTFState.new()

	var append_error := document.append_from_scene(
		rhino,
		state
	)

	if append_error != OK:
		push_error(
			"Error preparando GLB: %s"
			% error_string(append_error)
		)
		quit(1)
		return

	var output_path := ProjectSettings.globalize_path(
		OUTPUT_FILE
	)

	var write_error := document.write_to_filesystem(
		state,
		output_path
	)

	if write_error != OK:
		push_error(
			"Error escribiendo GLB: %s"
			% error_string(write_error)
		)
		quit(1)
		return

	print("✅ GLB creado:")
	print(output_path)

	quit(0)
