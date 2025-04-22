class_name URDFXMLParser extends XMLParser

const STL_IMPORTER_PATH = "res://addons/stl_importer/import_plugin.gd"

func as_node3d(source_path: String, options: Dictionary) -> Node3D:
	var robot: URDFRobot = parse(source_path, options)
	var root_node = Node3D.new()
	root_node.name = robot.name
	for link in robot.links:
		var link_node3d = URDF_Link_Node3D.new()
		root_node.add_child(link_node3d)
		link_node3d.owner = root_node
		link_node3d.name = link.name
		
		for visual in link.visuals:
			var visual_instance = MeshInstance3D.new()
			link_node3d.add_child(visual_instance)
			visual_instance.owner = root_node
			
			var material = StandardMaterial3D.new()
			
			material.albedo_color = Color(
					visual.material_color.x,
					visual.material_color.y,
					visual.material_color.z,
					visual.material_color.w
			)
			visual_instance.position = visual.origin_xyz
			visual_instance.rotation = visual.origin_rpy
			
			match visual.type:
				URDFVisual.Type.BOX:
					var box_mesh = BoxMesh.new()
					box_mesh.size = abs(visual.size)
					box_mesh.material = material
					
					visual_instance.mesh = box_mesh
				URDFVisual.Type.CYLINDER:
					var cylinder_mesh = CylinderMesh.new()
					cylinder_mesh.height = abs(visual.length)
					cylinder_mesh.bottom_radius = abs(visual.radius)
					cylinder_mesh.top_radius = abs(visual.radius)
					cylinder_mesh.material = material
					visual_instance.mesh = cylinder_mesh
				URDFVisual.Type.SPHERE:
					var sphere_mesh = SphereMesh.new()
					sphere_mesh.radius = abs(visual.radius)
					sphere_mesh.height = abs(visual.radius * 2)
					visual_instance.mesh = sphere_mesh
				URDFVisual.Type.MESH:
					# Import STL mesh into import directory
					var source_dir = source_path.get_basename()
					var mesh_source_path = source_dir + "/" + visual.mesh_path.get_file()

					# Copy mesh from global path to project and trigger import
					var error = DirAccess.copy_absolute(visual.mesh_path, mesh_source_path)
					if error != OK:
						push_error("Failed to copy mesh: ", mesh_source_path)
						continue

					# Load the imported mesh
					var imported_mesh = load(mesh_source_path)

					visual_instance.scale = Vector3(0.001,0.001,0.001)
					visual_instance.rotate_x(-PI/2)
					visual_instance.mesh = imported_mesh
				_:
					push_warning("Unsupported visual type: ", visual.type)

		for collider in link.colliders:
			var character_body = CharacterBody3D.new()
			var collision_shape = CollisionShape3D.new()
			link_node3d.add_child(character_body)
			character_body.owner = root_node
			character_body.add_child(collision_shape)
			collision_shape.owner = root_node
			
			
			match collider.type:
				URDFCollider.Type.BOX:
					var box_shape = BoxShape3D.new()
					box_shape.size = abs(collider.size)
					collision_shape.shape = box_shape
				URDFCollider.Type.CYLINDER:
					var cylinder_shape = CylinderShape3D.new()
					cylinder_shape.height = abs(collider.length)
					cylinder_shape.radius = abs(collider.radius)
					collision_shape.shape = cylinder_shape
				URDFCollider.Type.SPHERE:
					var sphere_shape = SphereShape3D.new()
					sphere_shape.radius = abs(collider.radius)
					collision_shape.shape = sphere_shape
				_:
					push_warning("Unsupported collider type: ", collider.type)
			character_body.position = collider.origin_xyz
			character_body.rotation = collider.origin_rpy
			
		
	for joint in robot.joints:
		var child_node3d: URDF_Link_Node3D = root_node.find_child(joint.child)
		var parent_node3d: URDF_Link_Node3D = root_node.find_child(joint.parent)
		
		root_node.remove_child(child_node3d)
		parent_node3d.add_child(child_node3d)
		
		child_node3d.position = joint.origin_xyz
		child_node3d.rotation = joint.origin_rpy
		match joint.type:
			"revolute":
				child_node3d.joint_type = child_node3d.JointType.REVOLUTE
				child_node3d.axis = joint.axis_xyz.normalized()
			"fixed":
				child_node3d.joint_type = child_node3d.JointType.FIXED
			_:
				push_warning("Unimplemented joint type for node generation: ", joint.type)
	return root_node


func parse(source_path: String, options: Dictionary) -> URDFRobot:
	var document: XMLDocument = XML.parse_file(source_path)
	var root_xml_node = document.root
	
	var robot = URDFRobot.new()
	robot.name = root_xml_node.name
	
	for child_xml_node in root_xml_node.children:
		match child_xml_node.name:
			"link":
				robot.links.append(get_urdf_link(child_xml_node, options))
			"joint":
				robot.joints.append(get_urdf_joint(child_xml_node))
	return robot


func get_urdf_joint(xml_node: XMLNode) -> URDFJoint:
	var joint = URDFJoint.new()
	joint.name = xml_node.attributes["name"]
	joint.type = xml_node.attributes["type"]
	for i in xml_node.children:
		match i.name:
			"parent":
				joint.parent = i.attributes["link"]
			"child":
				joint.child = i.attributes["link"]
			"axis":
				var axis_split = i.attributes["xyz"].split(" ")
				joint.axis_xyz = Vector3(
						float(axis_split[0]),
						float(axis_split[2]),
						- float(axis_split[1]),
				)
			"origin":
				var xyz_split = i.attributes["xyz"].split(" ")
				joint.origin_xyz = Vector3(
						float(xyz_split[0]),
						float(xyz_split[2]),
						- float(xyz_split[1])
				)
				if "rpy" in i.attributes:
					var rpy_split = i.attributes["rpy"].split(" ")
					joint.origin_rpy = Vector3(
							float(rpy_split[0]),
							float(rpy_split[2]),
							- float(rpy_split[1])
					)
	return joint


func get_urdf_link(xml_node: XMLNode, options: Dictionary) -> URDFLink:
	var link: URDFLink = URDFLink.new()
	link.name = xml_node.attributes["name"]
	for link_properties in xml_node.children:
		match link_properties.name:
			"visual":
				link.visuals.append(get_link_visual(link_properties, options))
			"collision":
				link.colliders.append(get_link_collider(link_properties, options))
			_:
				push_warning("Unsupported node for Link properties: ", link_properties.name)
	return link

func get_link_collider(xml_node: XMLNode, options: Dictionary) -> URDFCollider:
	var collider = URDFCollider.new()
	for i in xml_node.children:
		match i.name:
			"origin":
				var xyz_split = i.attributes["xyz"].split(" ")
				collider.origin_xyz = Vector3(
						float(xyz_split[0]),
						float(xyz_split[2]),
						- float(xyz_split[1])
				)
				var rpy_split = i.attributes["rpy"].split(" ")
				collider.origin_rpy = Vector3(
						float(rpy_split[0]),
						float(rpy_split[2]),
						- float(rpy_split[1])
				)
			"geometry":
				match i.children[0].name:
					"box":
						collider.type = URDFCollider.Type.BOX
						var size_split = i.children[0].attributes["size"].split(" ")
						collider.size = Vector3(
								float(size_split[0]),
								float(size_split[2]),
								float(size_split[1])
						)
					"cylinder":
						collider.type = URDFCollider.Type.CYLINDER
						collider.length = float(i.children[0].attributes["length"])
						collider.radius = float(i.children[0].attributes["radius"])
					"sphere":
						collider.type = URDFCollider.Type.SPHERE
						collider.radius = float(i.children[0].attributes["radius"])
					"mesh":
						collider.type = URDFCollider.Type.MESH
						collider.mesh_path = i.children[0].attributes["filename"]

						# Check package folder parameter is set
						if options.has("package_folder") and not options["package_folder"].is_empty():
							collider.mesh_path = options["package_folder"] + "/" + remove_package_prefix(i.children[0].attributes["filename"])
						else:
							# Raise error
							push_error("Package folder parameter is not set")
					_:
						push_warning("Unsupported geometry for collider in link properties: ", i.children[0].name)
			_:
				push_warning("Invalid node for Collider in link properties: ", i.name)
	return collider

func get_link_visual(xml_node: XMLNode, options: Dictionary) -> URDFVisual:
	var visual = URDFVisual.new()
	for i in xml_node.children:
		match i.name:
			"origin":
				var xyz_split = i.attributes["xyz"].split(" ")
				visual.origin_xyz = Vector3(
						float(xyz_split[0]),
						float(xyz_split[2]),
						- float(xyz_split[1])
				)
				var rpy_split = i.attributes["rpy"].split(" ")
				visual.origin_rpy = Vector3(
						float(rpy_split[0]),
						float(rpy_split[2]),
						- float(rpy_split[1])
				)
			"geometry":
				match i.children[0].name:
					"box":
						visual.type = URDFVisual.Type.BOX
						var size_split = i.children[0].attributes["size"].split(" ")
						visual.size = Vector3(
								float(size_split[0]),
								float(size_split[2]),
								float(size_split[1])
						)
					"cylinder":
						visual.type = URDFVisual.Type.CYLINDER
						visual.length = float(i.children[0].attributes["length"])
						visual.radius = float(i.children[0].attributes["radius"])
					"sphere":
						visual.type = URDFVisual.Type.SPHERE
						visual.radius = float(i.children[0].attributes["radius"])
					"mesh":
						visual.type = URDFVisual.Type.MESH

						# Check package folder parameter is set
						if options.has("package_folder") and not options["package_folder"].is_empty():
							visual.mesh_path = options["package_folder"] + "/" + remove_package_prefix(i.children[0].attributes["filename"])
						else:
							push_error("Package folder parameter is not set")
					_:
						push_error("Unsupported geometry for visual in link properties: ", i.children[0].name)
			"material":
				visual.material_name = i.attributes["name"]
				if len(i.children):
					match i.children[0].name:
						"color":
							var color_split = i.children[0].attributes["rgba"].split(" ")
							visual.material_color = Vector4(
									float(color_split[0]),
									float(color_split[1]),
									float(color_split[2]),
									float(color_split[3])
							)
						_:
							push_error("Unsupported material tag: ", i.children[0].name)
			_:
				push_error("Unsupported node for Visual link: ", i.name)
	return visual

func remove_package_prefix(path: String) -> String:
	return path.replace("package://", "")
