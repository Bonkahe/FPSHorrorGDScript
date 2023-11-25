@tool
extends EditorPlugin
class_name VPainter

var debug_show_collider:bool = false

var ui_sidebar : VPainter_UI
var ui_activate_button
var brush_cursor : Node3D

var movement_mode: bool;
var edit_mode: bool: 
	set = _set_edit_mode

var paint_color:Color
var alt_paint_color:Color

enum BlendModeEnum {MIX, ADD, SUBTRACT, MULTIPLY, DIVIDE}
var blend_mode : BlendModeEnum = BlendModeEnum.MIX

enum SculptModeEnum {STANDART, INFLATE, MOVE, SMOOTH}
var sculpt_mode : SculptModeEnum = SculptModeEnum.STANDART

var current_tool : String = "_paint_tool"


var invert_brush = false


var pressure_opacity:bool = false
var pressure_size:bool = false
var brush_pressure:float = 0.0
var process_drawing:bool = false

var brush_size:float = 1
var calculated_size:float = 1.0

var brush_opacity:float = 0.5
var calculated_opacity:float = 0.0

var brush_hardness:float = 0.5
var brush_spacing:float = 0.1

var current_mesh: MeshInstance3D
var editable_object:bool = false

var raycast_hit:bool = false
var hit_position
var hit_normal


func _handles(object: Object):
	return editable_object

func _forward_3d_gui_input(viewport_camera, event):
	if !edit_mode:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	_display_brush()
	_calculate_brush_pressure(event)
	_raycast(viewport_camera, event)
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT):
		if event.is_pressed():
			movement_mode = true
		else:
			movement_mode = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if (movement_mode):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	if raycast_hit:
		return _user_input(event) #the returned value blocks or unblocks the default input from godot
	else:
		return EditorPlugin.AFTER_GUI_INPUT_STOP

func _user_input(event) -> int:
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			process_drawing = true
			_process_drawing()
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		else:
			process_drawing = false
			_set_collision()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif event is InputEventKey and event.keycode == KEY_CTRL:
		if event.is_pressed():
			invert_brush = !invert_brush
			ui_sidebar._set_color_highlight(invert_brush)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _process_drawing():
	while process_drawing:
		call(current_tool)
		await get_tree().create_timer(brush_spacing).timeout

func _display_brush() -> void:
	if raycast_hit:
		brush_cursor.visible = true
		brush_cursor.global_position = hit_position
		brush_cursor.scale = Vector3.ONE * calculated_size
	else:
		brush_cursor.visible = false

func _calculate_brush_pressure(event) -> void:
	if event is InputEventMouseMotion:
		brush_pressure = event.pressure
		if pressure_size:
			calculated_size = (brush_size * brush_pressure)/2
		else:
			calculated_size = brush_size

		if pressure_opacity:
			calculated_opacity = brush_opacity * brush_pressure
		else:
			calculated_opacity = brush_opacity

func _raycast(camera:Camera3D, event:InputEvent) -> void:
	if event is InputEventMouse:
		#RAYCAST FROM CAMERA:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far

		var space_state =  get_viewport().world_3d.direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_origin + ray_dir * ray_distance
		query.exclude = []
		query.collision_mask = 524288
		query.collide_with_bodies = true
		query.collide_with_areas = false
		
		var hit = space_state.intersect_ray(query)
		#IF RAYCAST HITS A DRAWABLE SURFACE:
		if !hit:
			raycast_hit = false
			return
		if hit:
			raycast_hit = true
			hit_position = hit.position
			hit_normal = hit.normal

func _paint_tool() -> void:
		var data = MeshDataTool.new()
		data.create_from_surface(current_mesh.mesh, 0)

		for i in range(data.get_vertex_count()):
			var vertex := current_mesh.to_global(data.get_vertex(i))
			var vertex_distance:float = vertex.distance_to(hit_position)

			if vertex_distance < calculated_size/2:
				var linear_distance = 1 - (vertex_distance / (calculated_size/2))
				var calculated_hardness = linear_distance * brush_hardness

				match blend_mode:
					BlendModeEnum.MIX:
						data.set_vertex_color(i, data.get_vertex_color(i).lerp(alt_paint_color if invert_brush else paint_color, calculated_opacity * calculated_hardness))
					BlendModeEnum.ADD:
						data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) + alt_paint_color if invert_brush else paint_color, calculated_opacity * calculated_hardness))
					BlendModeEnum.SUBTRACT:
						data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) - alt_paint_color if invert_brush else paint_color, calculated_opacity * calculated_hardness))
					BlendModeEnum.MULTIPLY:
						data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) * alt_paint_color if invert_brush else paint_color, calculated_opacity * calculated_hardness))
					BlendModeEnum.DIVIDE:
						data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) / alt_paint_color if invert_brush else paint_color, calculated_opacity * calculated_hardness))
		
		var newMesh = ArrayMesh.new()
		data.commit_to_surface(newMesh)
		current_mesh.mesh = newMesh;

func _displace_tool() -> void:
		var data = MeshDataTool.new()
		data.create_from_surface(current_mesh.mesh, 0)

		for i in range(data.get_vertex_count()):
			var vertex := current_mesh.to_global(data.get_vertex(i))
			var vertex_distance:float = vertex.distance_to(hit_position)

			if vertex_distance < calculated_size/2:
				var linear_distance = 1 - (vertex_distance / (calculated_size/2))
				var calculated_hardness = linear_distance * brush_hardness

				if !invert_brush:
					data.set_vertex(i, data.get_vertex(i) + hit_normal * calculated_opacity * calculated_hardness)
				else:
					data.set_vertex(i, data.get_vertex(i) - hit_normal * calculated_opacity * calculated_hardness)

		var newMesh = ArrayMesh.new()
		data.commit_to_surface(newMesh)
		current_mesh.mesh = newMesh;

func _blur_tool() -> void:
	pass

func _fill_tool() -> void:
	var data = MeshDataTool.new()
	data.create_from_surface(current_mesh.mesh, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		
		match blend_mode:
			BlendModeEnum.MIX:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(alt_paint_color if invert_brush else paint_color, brush_opacity))
			BlendModeEnum.ADD:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) + alt_paint_color if invert_brush else paint_color, brush_opacity))
			BlendModeEnum.SUBTRACT:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) - alt_paint_color if invert_brush else paint_color, brush_opacity))
			BlendModeEnum.MULTIPLY:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) * alt_paint_color if invert_brush else paint_color, brush_opacity))
			BlendModeEnum.DIVIDE:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) / alt_paint_color if invert_brush else paint_color, brush_opacity))
				
		var newMesh = ArrayMesh.new()
		data.commit_to_surface(newMesh)
		current_mesh.mesh = newMesh;
	process_drawing = false

func _sample_tool() -> void:
	var data = MeshDataTool.new()
	data.create_from_surface(current_mesh.mesh, 0)
	
	var closest_distance:float = INF
	var closest_vertex_index:int

	for i in range(data.get_vertex_count()):
		var vertex = current_mesh.to_global(data.get_vertex(i))

		if vertex.distance_to(hit_position) < closest_distance:
			closest_distance = vertex.distance_to(hit_position)
			closest_vertex_index = i
	
	var picked_color = data.get_vertex_color(closest_vertex_index)
	paint_color = Color(picked_color.r, picked_color.g, picked_color.b, 1)
	if invert_brush:
		ui_sidebar._set_background_color(paint_color)
	else:
		ui_sidebar._set_paint_color(paint_color)
	
	
	var newMesh = ArrayMesh.new()
	data.commit_to_surface(newMesh)
	current_mesh.mesh = newMesh;

func _set_collision() -> void:
	var temp_collision:StaticBody3D = current_mesh.get_node_or_null(current_mesh.name + "_col")
	if (temp_collision == null):
		current_mesh.create_trimesh_collision()
		temp_collision = current_mesh.get_node(current_mesh.name + "_col")
		temp_collision.set_collision_layer(524288)
		temp_collision.set_collision_mask(524288)
	else:
		temp_collision.free()
		current_mesh.create_trimesh_collision()
		temp_collision = current_mesh.get_node(current_mesh.name + "_col")
		temp_collision.set_collision_layer(524288)
		temp_collision.set_collision_mask(524288)
	
	if !debug_show_collider:
		temp_collision.hide()

func _delete_collision() -> void:
	var temp_collision:StaticBody3D = current_mesh.get_node_or_null(current_mesh.name + "_col")
	if (temp_collision != null):
		temp_collision.free()

func _set_edit_mode(value) -> void:
	edit_mode = value
	if !current_mesh:
		return
		if (!current_mesh.mesh):
			return

	if edit_mode:
		_set_collision()
	else:
		ui_sidebar.hide()
		_delete_collision()

func _make_local_copy() -> void:
	current_mesh.mesh = current_mesh.mesh.duplicate(false)

func _selection_changed() -> void:
	ui_activate_button._set_ui_sidebar(false)

	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1 and selection[0] is MeshInstance3D:
		current_mesh = selection[0]
		if current_mesh.mesh == null:
			ui_activate_button._set_ui_sidebar(false)
			ui_activate_button._hide()
			editable_object = false
		else:
			ui_activate_button._show()
			editable_object = true
	else:
		editable_object = false
		ui_activate_button._set_ui_sidebar(false) #HIDE THE SIDEBAR
		ui_activate_button._hide()

func _enter_tree() -> void:
	#SETUP THE SIDEBAR:
	ui_sidebar = preload("res://addons/vpainter/vpainter_ui.tscn").instantiate() as VPainter_UI
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
	ui_sidebar.hide()
#	print("test1")
#	print(ui_sidebar)
	ui_sidebar.vpainter = self
	#SETUP THE EDITOR BUTTON:
	ui_activate_button = preload("res://addons/vpainter/vpainter_activate_button.tscn").instantiate() as VPainter_UI_ActivateButton
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
	ui_activate_button.hide()
	ui_activate_button.vpainter = self
	ui_activate_button.ui_sidebar = ui_sidebar
	#SELECTION SIGNAL:
	get_editor_interface().get_selection().selection_changed.connect(_selection_changed)
	#LOAD BRUSH:
	brush_cursor = preload("res://addons/vpainter/res/brush_cursor/BrushCursor.tscn").instantiate() as Node3D
	brush_cursor.visible = false
	add_child(brush_cursor)

func _exit_tree() -> void:
	#REMOVE THE SIDEBAR:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
	if ui_sidebar:
		ui_sidebar.free()
	#REMOVE THE EDITOR BUTTON:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
	if ui_activate_button:
		ui_activate_button.free()

