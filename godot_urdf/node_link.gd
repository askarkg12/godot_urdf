@tool
class_name URDF_Link_Node3D extends Node3D


enum JointType {REVOLUTE, FIXED}


@export var joint_type: JointType
@export var axis: Vector3 = Vector3(1,0,0)
var origin_rpy: Vector3 = Vector3(0,0,0)


@export var value: float = 0:
	set(_value):
		value = _value
		on_angle_change()


func on_angle_change():
	match joint_type:
		JointType.REVOLUTE:
			rotation = origin_rpy
			rotate_object_local(axis, value)
		_:
			pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
