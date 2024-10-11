class_name URDFVisual extends Object
# All XYZ will be kept as is originally in URDF file
# Y and Z should be flipped when generating Nodes
enum Type {BOX, MESH}

var origin_xyz: Vector3
var origin_rpy: Vector3
var type: Type
var size: Vector3