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
			
			match visual.type:
				URDFVisual.Type.BOX:
					visual_instance.mesh = BoxMesh.new()
					visual_instance.mesh .size = abs(visual.size)
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
				child_node3d.axis = joint.axis_xyz.normalized()
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
					_:
						printerr("Unsupported geometry for visual in link properties")
	return visual
