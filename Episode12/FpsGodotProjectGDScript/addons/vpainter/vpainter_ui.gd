@tool
extends Control
class_name VPainter_UI

var vpainter : VPainter
#LOCAL COPY BUTTON
@export var local_copy_button_path:NodePath
var local_copy_button:Button

#COLOR PICKER:
@export var color_picker_dir:NodePath
var color_picker:ColorPickerButton

@export var background_picker_dir:NodePath
var background_picker:ColorPickerButton

@export var color_picker_dir_highlight:ColorRect
@export var background_picker_dir_highlight:ColorRect

#PEN PRESSURE:
@export var pen_pressure_settings_dir:NodePath
var pen_pressure_settings:VBoxContainer
@export var button_opacity_pressure_dir:NodePath
var button_opacity_pressure:CheckBox
@export var button_size_pressure_dir:NodePath
var button_size_pressure:CheckBox

#TOOLS:
@export var button_paint_dir:NodePath
var button_paint:Button

@export var button_sample_dir:NodePath
var button_sample:Button

@export var button_blur_dir:NodePath
var button_blur:Button

@export var button_displace_dir:NodePath
var button_displace:Button

@export var button_fill_dir:NodePath
var button_fill:Button

#BRUSH SLIDERS:
@export var brush_size_slider_dir:NodePath
var brush_size_slider:HSlider

@export var brush_opacity_slider_dir:NodePath
var brush_opacity_slider:HSlider

@export var brush_hardness_slider_dir:NodePath
var brush_hardness_slider:HSlider

@export var brush_spacing_slider_dir:NodePath
var brush_spacing_slider:HSlider

#BLENDING MODES:
@export var blend_modes_path:NodePath
var blend_modes:OptionButton

func _enter_tree():
	local_copy_button = get_node(local_copy_button_path) as Button
	local_copy_button.button_down.connect(_make_local_copy)
	
	color_picker = get_node(color_picker_dir) as ColorPickerButton
	color_picker.color_changed.connect(_set_paint_color)
	
	background_picker = get_node(background_picker_dir) as ColorPickerButton
	background_picker.color_changed.connect(_set_background_color)
	
	
	pen_pressure_settings = get_node(pen_pressure_settings_dir)
	
	button_opacity_pressure = get_node(button_opacity_pressure_dir) as CheckBox
	button_opacity_pressure.toggled.connect(_set_opacity_pressure)
	button_size_pressure = get_node(button_size_pressure_dir) as CheckBox
	button_size_pressure.toggled.connect(_set_size_pressure)
	
	button_paint = get_node(button_paint_dir) as Button
	button_paint.toggled.connect(_set_paint_tool)
	
	button_sample = get_node(button_sample_dir) as Button
	button_sample.toggled.connect(_set_sample_tool)
	
	button_blur = get_node(button_blur_dir) as Button
	button_blur.toggled.connect(_set_blur_tool)
	
	button_displace = get_node(button_displace_dir) as Button
	button_displace.toggled.connect(_set_displace_tool)
	
	button_fill = get_node(button_fill_dir)  as Button
	button_fill.toggled.connect(_set_fill_tool)

	brush_size_slider = get_node(brush_size_slider_dir) as HSlider
	brush_size_slider.value_changed.connect(_set_brush_size)
	brush_opacity_slider = get_node(brush_opacity_slider_dir) as HSlider
	brush_opacity_slider.value_changed.connect(_set_brush_opacity)
	brush_hardness_slider = get_node(brush_hardness_slider_dir) as HSlider
	brush_hardness_slider.value_changed.connect(_set_brush_hardness)
	brush_spacing_slider = get_node(brush_spacing_slider_dir) as HSlider
	brush_spacing_slider.value_changed.connect(_set_brush_spacing)
	
	blend_modes = get_node(blend_modes_path) as OptionButton
	blend_modes.item_selected.connect(_set_blend_mode)
	blend_modes.clear()
	blend_modes.add_item("MIX", 0)
	blend_modes.add_item("ADD", 1)
	blend_modes.add_item("SUBTRACT", 2)
	blend_modes.add_item("MULTIPLY", 3)
	blend_modes.add_item("DIVIDE", 4)

	button_paint.set_pressed(true)

func _exit_tree():
	pass

func _make_local_copy():
	vpainter._make_local_copy()

func _set_color_highlight(invert_brush):
	if invert_brush:
		color_picker_dir_highlight.color = Color.BLACK
		background_picker_dir_highlight.color = Color.WHITE
	else:
		color_picker_dir_highlight.color = Color.WHITE
		background_picker_dir_highlight.color = Color.BLACK

func _set_paint_color(value):
	color_picker.set_pick_color(value)
	vpainter.paint_color = value

func _set_background_color(value):
	background_picker.set_pick_color(value)
	vpainter.alt_paint_color = value


func _set_blend_mode(id):
	#MIX, ADD, SUBTRACT, MULTIPLY, DIVIDE
	match id:
		0: #MIX
			vpainter.blend_mode = vpainter.BlendModeEnum.MIX
		1: #ADD
			vpainter.blend_mode = vpainter.BlendModeEnum.ADD
		2: #SUBTRACT
			vpainter.blend_mode = vpainter.BlendModeEnum.SUBTRACT
		3: #MULTIPLY
			vpainter.blend_mode = vpainter.BlendModeEnum.MULTIPLY
		4: #DIVIDE
			vpainter.blend_mode = vpainter.BlendModeEnum.DIVIDE

func _input(event):	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_set_paint_tool(true)
		if event.keycode == KEY_2:
			_set_sample_tool(true)
		if event.keycode == KEY_3:
			_set_blur_tool(true)
		if event.keycode == KEY_4:
			_set_displace_tool(true)
		if event.keycode == KEY_5:
			_set_fill_tool(true)
		
		if event.keycode == KEY_BRACELEFT:
			_set_brush_size(brush_size_slider.value - 0.05)
		if event.keycode == KEY_BRACERIGHT:
			_set_brush_size(brush_size_slider.value + 0.05)
		
		if event.keycode == KEY_APOSTROPHE :
			_set_brush_opacity(brush_opacity_slider.value - 0.01)
		if event.keycode == KEY_BACKSLASH :
			_set_brush_opacity(brush_opacity_slider.value + 0.01)

func _set_opacity_pressure(value):
	vpainter.pressure_opacity = value

func _set_size_pressure(value):
	vpainter.pressure_size = value

func _set_paint_tool(value):
	if vpainter == null:
		print("testreturned")
		return;
	if value:
		vpainter.current_tool = "_paint_tool"
		pen_pressure_settings.visible = true
		blend_modes.visible = true

		button_paint.set_pressed(true)
		button_sample.set_pressed(false)
		button_blur.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_sample_tool(value):
	if vpainter == null:
		print("testreturned")
		return;
	if value:
		vpainter.current_tool = "_sample_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(true)
		button_blur.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_blur_tool(value):
	if vpainter == null:
		print("testreturned")
		return;
	if value:
		vpainter.current_tool = "_blur_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_blur.set_pressed(true)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_displace_tool(value):
	if vpainter == null:
		print("testreturned")
		return;
	if value:
		vpainter.current_tool = "_displace_tool"
		pen_pressure_settings.visible = true
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_blur.set_pressed(false)
		button_displace.set_pressed(true)
		button_fill.set_pressed(false)


func _set_fill_tool(value):
	if vpainter == null:
		print("testreturned")
		return;
	if value:
		vpainter.current_tool = "_fill_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = true

		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_blur.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(true)


func _set_brush_size(value):
	brush_size_slider.value = value
	vpainter.brush_size = value
	vpainter.brush_cursor.scale = Vector3.ONE * value

func _set_brush_opacity(value):
	brush_opacity_slider.value = value
	vpainter.brush_opacity = value

func _set_brush_hardness(value):
	brush_hardness_slider.value = value
	vpainter.brush_hardness = value

func _set_brush_spacing(value):
	brush_spacing_slider.value = value
	vpainter.brush_spacing = value

