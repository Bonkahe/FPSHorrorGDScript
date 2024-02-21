extends Control

@export var LaunchMenu : Control
@export var PauseMenu : Control
@export var DeathMenu : Control

@export var PlayerNode : Node3D
@export var LevelCamera : Camera3D
@export var TransitionMaterial : ShaderMaterial

@export var TransitionTime : float = 2.0

var IsPlaying : bool = false;

func _ready():
	get_tree().paused = true
	TransitionMaterial.set_shader_parameter("EffectStrength", 3.0)
	LaunchMenu.visible = true
	TweenOutTrans()
	PlayerNode.visible = false
	LevelCamera.current = true
	var playerHealthController : PlayerHealthController = PlayerNode.get_node("PlayerHealthController")
	if (playerHealthController != null):
		playerHealthController.connect("OnPlayerDeath", OnDeath.bind())
	

func _input(event):
	if (event.is_action_pressed("escape") and IsPlaying):
		TogglePauseMenu()

func ToggleFullScreen():
	if (DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func TogglePauseMenu():
	if (PauseMenu.visible):
		HidePauseMenu()
	else:
		ShowPauseMenu()

func OnDeath(CameraLocation : Vector3, CameraRotation : Vector3):
	get_tree().paused = true
	IsPlaying = false
	TweenInTrans(ShowDeathMenu.bind(CameraLocation, CameraRotation))

func ShowDeathMenu(CameraLocation : Vector3, CameraRotation : Vector3):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DeathMenu.visible = true
	LevelCamera.global_position = CameraLocation
	LevelCamera.global_rotation = CameraRotation
	LevelCamera.current = true
	PlayerNode.queue_free()
	TweenOutTrans()
	get_tree().paused = false

func ShowPauseMenu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	PauseMenu.visible = true
	get_tree().paused = true

func HidePauseMenu():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	PauseMenu.visible = false
	get_tree().paused = false

func BeginLaunch():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	LaunchMenu.visible = false
	TweenInTrans(FinishLaunch.bind())

func FinishLaunch():
	PlayerNode.visible = true
	LevelCamera.current = false
	TweenOutTrans()
	get_tree().paused = false
	IsPlaying = true

func RestartLevel():
	get_tree().reload_current_scene()

func ExitGame():
	TweenInTrans(get_tree().quit.bind())

func TweenOutTrans(CompletionCallable = null):
	var newTween : Tween = get_tree().create_tween()
	newTween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	newTween.tween_method(SetTransitionValue.bind(), 3.0, 0.0, TransitionTime)
	
	if (CompletionCallable != null and CompletionCallable is Callable):
		newTween.tween_callback(CompletionCallable)

func TweenInTrans(CompletionCallable = null):
	var newTween : Tween = get_tree().create_tween()
	newTween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	newTween.tween_method(SetTransitionValue.bind(), 0.0, 3.0, TransitionTime)
	if (CompletionCallable != null and CompletionCallable is Callable):
		newTween.tween_callback(CompletionCallable)

func SetTransitionValue(newValue : float):
	TransitionMaterial.set_shader_parameter("EffectStrength", newValue)
