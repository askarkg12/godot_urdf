class_name URDFParser extends XMLParser


func as_node3d(source_path:String) -> Node3D:
	var robot: URDFRobot = parse(source_path)
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
			visual_instance.position = visual.origin_xyz
			visual_instance.rotation = visual.origin_rpy
		
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
				printerr("Unimplemented joint type for node generation: ", joint.type)
	return root_node


func parse(source_path: String) -> URDFRobot:
	var document: XMLDocument = XML.parse_file(source_path)
	var root_xml_node = document.root
	
	var robot = URDFRobot.new()
	robot.name = root_xml_node.name
	
	for child_xml_node in root_xml_node.children:
		match child_xml_node.name:
			"link":
				robot.links.append(get_urdf_link(child_xml_node))
			"joint":
				robot.joints.append(get_urdf_joint(child_xml_node))
	return robot


func get_urdf_joint(xml_node: XMLNode) -> URDFJoint :
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
						-float(axis_split[1]),
				)
			"origin":
				var xyz_split = i.attributes["xyz"].split(" ")
				joint.origin_xyz = Vector3(
						float(xyz_split[0]),
						float(xyz_split[2]),
						-float(xyz_split[1])
				)
				var rpy_split = i.attributes["rpy"].split(" ")
				joint.origin_rpy = Vector3(
						float(rpy_split[0]),
						float(rpy_split[2]),
						-float(rpy_split[1])
				)
	return joint


func get_urdf_link(xml_node: XMLNode) -> URDFLink:
	var link: URDFLink = URDFLink.new()
	link.name = xml_node.attributes["name"]
	for link_properties in xml_node.children:
		match link_properties.name:
			"visual":
				link.visuals.append(get_link_visual(link_properties))
	return link


func get_link_visual(xml_node: XMLNode) -> URDFVisual:
	var visual = URDFVisual.new()
	for i in xml_node.children:
		match i.name:
			"origin":
				var xyz_split = i.attributes["xyz"].split(" ")
				visual.origin_xyz = Vector3(
						float(xyz_split[0]),
						float(xyz_split[2]),
						-float(xyz_split[1])
				)
				var rpy_split = i.attributes["rpy"].split(" ")
				visual.origin_rpy = Vector3(
						float(rpy_split[0]),
						float(rpy_split[2]),
						-float(rpy_split[1])
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
					_:
						printerr("Unsupported geometry for visual in link properties: ", i.children[0].name)
			"material":
				visual.material_name = i.attributes["name"]
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
						printerr("Unsupported material tag: ", i.children[0].name)
			_:
				printerr("Unsupported node for Visual link: ", i.name)
	return visual
