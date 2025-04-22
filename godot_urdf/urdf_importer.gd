@tool

class_name GodotURDFImporter extends EditorImportPlugin

func _get_importer_name() -> String:
	return "godot_urdf"
	
func _get_visible_name() -> String:
	return "Godot URDF"
	
func _get_recognized_extensions() -> PackedStringArray:
	return ["urdf"]

func _get_save_extension() -> String:
	return "tscn"
	
func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "package_folder",
			"default_value": "",
			"property_hint": PROPERTY_HINT_GLOBAL_DIR,
			"hint_string": ""
		},
	]
	
func _get_import_order() -> int:
	return 0
	
func _get_resource_type() -> String:
	return "PackedScene"
	
func _get_preset_count() -> int:
	return 1
	
func _get_preset_name(preset_index: int) -> String:
	return "Default preset"
	
func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true
	
func _get_priority() -> float:
	return 1.0

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var scene = PackedScene.new()
	var urdf_parser = URDFXMLParser.new()
	
	# Create a new directory for the imported scene
	# Get filename without extension
	var basename= source_file.get_basename()
	var source_dir_result = DirAccess.make_dir_recursive_absolute(basename)
	if source_dir_result != OK:
		push_error("Failed to create import directory: ", basename)
		return source_dir_result
		
	var root = urdf_parser.as_node3d(source_file, options)
	scene.pack(root)
	var saved_path = save_path + "." + _get_save_extension()
	# Save the packed scene to the target path
	var save_result = ResourceSaver.save(scene, saved_path)
	if save_result != OK:
		push_error("Failed to save imported .foo as a scene.")
		return ERR_CANT_CREATE
	return OK
