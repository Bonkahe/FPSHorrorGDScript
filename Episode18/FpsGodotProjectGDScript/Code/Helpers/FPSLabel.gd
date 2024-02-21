extends Label


func _physics_process(delta):
	text = str(Engine.get_frames_per_second());
