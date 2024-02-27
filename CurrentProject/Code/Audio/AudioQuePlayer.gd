extends Node


@export var AudioQuePlayerPrefab : PackedScene

@export var AudioQuePlayer3DPrefab : PackedScene

func PlayAudioQue(AudioClip : AudioStream, VolumeDb : float):
	var newAudioPlayer : AudioQue = AudioQuePlayerPrefab.instantiate() as AudioQue
	add_child(newAudioPlayer)
	
	newAudioPlayer.stream = AudioClip
	newAudioPlayer.volume_db = VolumeDb
	newAudioPlayer.PlayWithDelete()

func PlayAudioQue3D(AudioClip : AudioStream, Position : Vector3, VolumeDb : float):
	var newAudioPlayer : AudioQue3D = AudioQuePlayer3DPrefab.instantiate() as AudioQue3D
	add_child(newAudioPlayer)
	
	newAudioPlayer.global_position = Position
	newAudioPlayer.stream = AudioClip
	newAudioPlayer.volume_db = VolumeDb
	newAudioPlayer.PlayWithDelete()
