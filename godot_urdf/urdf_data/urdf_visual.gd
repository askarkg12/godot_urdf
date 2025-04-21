class_name URDFVisual extends Object
# All XYZ will be kept as is originally in URDF file
# Y and Z should be flipped when generating Nodes
enum Type {BOX, MESH, CYLINDER, SPHERE}

var origin_xyz: Vector3
var origin_rpy: Vector3
var type: Type
var size: Vector3
var radius: float
var length: float
var material_name: String
var material_color: Vector4
var material_texture_path: String
