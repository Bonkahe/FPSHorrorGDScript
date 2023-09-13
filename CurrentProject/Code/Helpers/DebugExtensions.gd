extends Node
class_name DebugExtensions

static func DrawPoint(originNode:Node, pos:Vector3, duration:float, color:Color, size:float = 0.05):
	var mesh_instance = MeshInstance3D.new();
	var sphereMesh = SphereMesh.new();
	var material = StandardMaterial3D.new();
	
	mesh_instance.mesh = sphereMesh;
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
	mesh_instance.position = pos;
	
	sphereMesh.radius = size / 2;
	sphereMesh.height = size;
	sphereMesh.material = material;
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;
	material.albedo_color = color;
	
	originNode.get_tree().root.add_child(mesh_instance);
	if (duration != 0):
		await originNode.get_tree().create_timer(duration).timeout;
		mesh_instance.queue_free();

static func BuildDebugLine(originNode:Node, origin:Vector3, destination:Vector3, duration:float, color:Color):
	var mesh_instance = MeshInstance3D.new();
	var immediate_mesh = ImmediateMesh.new();
	var material = StandardMaterial3D.new();
	
	mesh_instance.mesh = immediate_mesh;
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material);
	immediate_mesh.surface_add_vertex(origin);
	immediate_mesh.surface_add_vertex(destination);
	immediate_mesh.surface_end();
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;
	material.albedo_color = color;
	
	originNode.get_tree().root.add_child(mesh_instance);
	if (duration != 0):
		await originNode.get_tree().create_timer(duration).timeout;
		mesh_instance.queue_free();
