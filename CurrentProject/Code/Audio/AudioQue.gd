extends AudioStreamPlayer
class_name AudioQue


func PlayWithDelete():
	play()
	await get_tree().create_timer(stream.get_length(), true, false, true).timeout
	queue_free()
