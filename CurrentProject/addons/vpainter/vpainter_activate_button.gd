@tool
extends Control
class_name VPainter_UI_ActivateButton

var vpainter : VPainter
var ui_sidebar : VPainter_UI

@export var button_path:NodePath
var button:Button


func _enter_tree():
	button = get_node(button_path) as Button
	button.toggled.connect(_set_ui_sidebar)

func _exit_tree():
	pass

func _show():
	button.set_pressed(false)
	self.show()
	pass

func _hide():
	button.set_pressed(false)
	self.hide()
	ui_sidebar.hide()
	pass

func _set_ui_sidebar(value):
	if value:
		ui_sidebar.set_process_input(true)
		vpainter._set_edit_mode(true)
		ui_sidebar.show()
		vpainter.brush_cursor.visible = true
	else:
		ui_sidebar.set_process_input(false)
		ui_sidebar.hide()
		vpainter._set_edit_mode(false)
		vpainter.brush_cursor.visible = false
