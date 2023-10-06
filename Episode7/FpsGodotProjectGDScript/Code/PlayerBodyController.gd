extends CharacterBody3D

@export var gunEffects: WeaponEffectsController;

@export var animationTree: AnimationTree;

@export var HandStateMachinePlaybackPath: String;
@export var IdleAnimationName: String;
@export var AimingAnimationName: String;

@export var IdleFireAnimationName: String;
@export var AimingFireAnimationName: String;

@export var ReloadAnimationName: String;

@export var CameraNode: Node3D;
@export var ArmsNode: Node3D;

@export var RotationSpeed: float;
@export var CameraActualRotationSpeed: float;
@export var ArmsActualRotationSpeed: float;
@export var VerticalRotationLimit: float = 80;



@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var handStateMachinePlayback: AnimationNodeStateMachinePlayback;
var targetRotation: Vector3;
var isAiming: bool;

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	handStateMachinePlayback = animationTree.get(HandStateMachinePlaybackPath) as AnimationNodeStateMachinePlayback;

func _input(event):
	if (event is InputEventMouseMotion):
		targetRotation.x = clamp((-1 * event.relative.y * RotationSpeed) + targetRotation.x, -VerticalRotationLimit, VerticalRotationLimit)
		targetRotation.y = wrap((-1 * event.relative.x * RotationSpeed) + targetRotation.y, 0, 360)
	
	if (event.is_action_pressed("escape")):
		ToggleMouseMode();
	
	if (event.is_action_pressed("Aim")):
		isAiming = true;
		handStateMachinePlayback.travel(AimingAnimationName);
	
	if (event.is_action_released("Aim")):
		isAiming = false;
		handStateMachinePlayback.travel(IdleAnimationName);
	
	if (event.is_action_pressed("Fire")):
		FireWeapon();
	
	if (event.is_action_pressed("Reload")):
		isAiming = false;
		handStateMachinePlayback.travel(ReloadAnimationName);

func FireWeapon():
	if (!gunEffects.hasRoundAvailable):
		isAiming = false;
		handStateMachinePlayback.travel(ReloadAnimationName);
		return;
	
	if (isAiming):
		handStateMachinePlayback.travel(AimingFireAnimationName);
	else:
		handStateMachinePlayback.travel(IdleFireAnimationName);

func ToggleMouseMode():
	if (Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("Move_left", "Move_right", "Move_up", "Move_down")
	var direction = (CameraNode.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	CameraNode.rotation.x = lerp_angle(CameraNode.rotation.x, deg_to_rad(targetRotation.x), CameraActualRotationSpeed * delta);
	CameraNode.rotation.y = lerp_angle(CameraNode.rotation.y, deg_to_rad(targetRotation.y), CameraActualRotationSpeed * delta);
	
	ArmsNode.rotation.x = lerp_angle(ArmsNode.rotation.x, deg_to_rad(targetRotation.x), ArmsActualRotationSpeed * delta);
	ArmsNode.rotation.y = lerp_angle(ArmsNode.rotation.y, deg_to_rad(targetRotation.y), ArmsActualRotationSpeed * delta);
	
	
	
	
	
	
	
	
	
	
