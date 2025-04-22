@tool
extends EditorPlugin

var godot_urdf = GodotURDFImporter.new()

func _enter_tree() -> void:
	add_import_plugin(godot_urdf)
	

func _exit_tree() -> void:
	remove_import_plugin(godot_urdf)
