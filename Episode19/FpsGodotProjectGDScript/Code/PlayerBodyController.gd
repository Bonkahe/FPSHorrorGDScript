extends CharacterBody3D

class_name PlayerBodyController

@export_category("Node References")
@export var GunEffects: WeaponEffectsController;

@export var CameraNode: Node3D;
@export var CameraActual: Camera3D;
@export var ArmsNode: Node3D;

@export_category("Animations")
@export var animationTree: AnimationTree;

@export_group("Animation Names")
@export var HandStateMachinePlaybackPath: String;
@export var IdleAnimationName: String;
@export var AimingAnimationName: String;

@export var IdleFireAnimationName: String;
@export var AimingFireAnimationName: String;

@export var IdleReloadAnimationName: String;
@export var AimingReloadAnimationName: String;

@export_category("Camera Shake Variables")

@export var CameraShake_Noise : Noise;
@export var CameraShake_NoisePanningSpeed : float = 30;
@export var CameraShake_MaxPower : float = 0.15;
@export var CameraShake_BlendSpeed : float = 7;
@export var CameraShake_ReturnStrength : float = 5;
@export var CameraShake_NoiseStrength : float = 0.2;
@export var CameraShake_FallingBias : float = 1.0;
@export var CameraShake_FallingStrengthFalloff : float = 2.0;
@export var CameraShake_FallingMaxStrength : float = 1.0;
@export var CameraShake_JumpingStrength : float = 0.2;

@export_category("Walking Sway Variables")
@export var WalkingSway_StepsPerSecond : float = 5.0;
@export var WalkingSway_MaxSwayDistance : float = 0.05;
@export var WalkingSway_MaxSwayHandsHeight : float = -0.005;
@export var WalkingSway_MaxSwayCameraHeight : float = 0.01;
@export var WalkingSway_BlendSpeed : float = 5;
@export var WalkingSway_Bias : float = 0.5;

@export_category("Rotation Variables")
@export var VerticalRecoil: float = 2;
@export var RotationSpeed: float = 0.3;
@export var CameraActualRotationSpeed: float = 20;
@export var ArmsActualRotationSpeed: float = 12;
@export var VerticalRotationLimit: float = 80;

@export_category("Movement Variables")
@export var SPEED: float = 8.0;
@export var JUMP_VELOCITY: float = 4.5;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var handStateMachinePlayback: AnimationNodeStateMachinePlayback;
var targetRotation: Vector3;
var isAiming: bool;

var ArmsBasePosition : Vector3;
var walkingSway_CurrentValue : float;

var cameraShake_Position  : Vector3;
var timeSinceStarted : float;

var lastYVelocity : float;

func _ready():
	ArmsBasePosition = ArmsNode.position;
	
	handStateMachinePlayback = animationTree.get(HandStateMachinePlaybackPath) as AnimationNodeStateMachinePlayback;

func _input(event):
	
	if (event is InputEventMouseMotion):
		targetRotation.x = clamp((-1 * event.relative.y * RotationSpeed) + targetRotation.x, -VerticalRotationLimit, VerticalRotationLimit)
		targetRotation.y = wrap((-1 * event.relative.x * RotationSpeed) + targetRotation.y, 0, 360)
	
	
	if (event.is_action_pressed("Aim")):
		isAiming = true;
		handStateMachinePlayback.travel(AimingAnimationName);
	
	if (event.is_action_released("Aim")):
		isAiming = false;
		handStateMachinePlayback.travel(IdleAnimationName);
	
	if (event.is_action_pressed("Fire")):
		FireWeapon();
	
	if (event.is_action_pressed("Reload")):
		ReloadWeapon();

func FireWeapon():
	if (!GunEffects.hasRoundAvailable):		
		ReloadWeapon();
		return;
	
	if (isAiming):
		handStateMachinePlayback.travel(AimingFireAnimationName);
	else:
		handStateMachinePlayback.travel(IdleFireAnimationName);

func ReloadWeapon():
	if (isAiming):
		handStateMachinePlayback.travel(AimingReloadAnimationName);
	else:
		handStateMachinePlayback.travel(IdleReloadAnimationName);
	
	isAiming = false;

func _physics_process(delta):
	timeSinceStarted += delta * CameraShake_NoisePanningSpeed;
	
	if (cameraShake_Position.length() > 0.0001):
		
		var noise : Vector3 = (Vector3(CameraShake_Noise.get_noise_1d(timeSinceStarted), CameraShake_Noise.get_noise_1d(timeSinceStarted + 1000), CameraShake_Noise.get_noise_1d(timeSinceStarted + 2000)) * CameraShake_NoiseStrength) * (cameraShake_Position.length() / CameraShake_MaxPower);
		CameraActual.position = CameraActual.position.lerp(
			cameraShake_Position + noise,
			float(delta) * CameraShake_BlendSpeed);
		cameraShake_Position = cameraShake_Position.lerp(Vector3.ZERO, delta * CameraShake_ReturnStrength);	
	else:
		CameraActual.position = Vector3.ZERO;
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		walkingSway_CurrentValue = max(walkingSway_CurrentValue - delta * WalkingSway_BlendSpeed, 0);
		lastYVelocity = velocity.y;
	else:
		if (lastYVelocity < -CameraShake_FallingBias):
			ImpulseCamera(Vector3.DOWN, smoothstep(CameraShake_FallingBias, CameraShake_FallingStrengthFalloff + CameraShake_FallingBias, abs(lastYVelocity)) * CameraShake_FallingMaxStrength);
		
		if (velocity.length() > WalkingSway_Bias):
			walkingSway_CurrentValue = min(walkingSway_CurrentValue + delta * WalkingSway_BlendSpeed, 1.0);
		else:
			walkingSway_CurrentValue = max(walkingSway_CurrentValue - delta * WalkingSway_BlendSpeed, 0);
	
	lastYVelocity = velocity.y;
	
	if (walkingSway_CurrentValue > 0):
		var stepSpeed: float = delta * WalkingSway_StepsPerSecond;
		var stepBounce: float = (EaseInOutSine(-1.0, 1.0, timeSinceStarted * stepSpeed * 2.0 + 0.2) * -1.0) * WalkingSway_MaxSwayHandsHeight;
		if(stepBounce == WalkingSway_MaxSwayHandsHeight):
			#sound effect for stepping.
			pass;
		
		cameraShake_Position.y += (EaseInOutSine(-1.0, 1.0, timeSinceStarted * stepSpeed * 2.0 + 0.2) * -1.0) * WalkingSway_MaxSwayCameraHeight * (0.2 if isAiming else 1.0);
		
		GunEffects.HandOffsetPosition = CameraNode.transform.basis * (Vector3(
			EaseInOutSine(-1.0, 1.0, timeSinceStarted * stepSpeed) * WalkingSway_MaxSwayDistance,
			stepBounce,
			0.0) * walkingSway_CurrentValue * (0.2 if isAiming else 1.0));
	else:
		GunEffects.HandOffsetPosition = Vector3.ZERO;
	
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		ImpulseCamera(Vector3.UP, CameraShake_JumpingStrength);

	var input_dir = Input.get_vector("Move_left", "Move_right", "Move_up", "Move_down")
	var direction = CameraNode.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	direction.y = 0
	direction = direction.normalized()
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
	

func ImpulseCameraWithRecoil(impulseVector: Vector3, impulsePower: float):
	targetRotation.x += VerticalRecoil;
	ImpulseCamera(impulseVector, impulsePower);

func ImpulseCamera(impulseVector: Vector3, impulsePower: float):
	cameraShake_Position += impulseVector * impulsePower;
	cameraShake_Position = cameraShake_Position.normalized() * min(cameraShake_Position.length(), CameraShake_MaxPower);
	
func EaseInOutSine(start: float, end: float, value: float) -> float:
	end -= start;
	return -end * 0.5 * (cos(PI * value) - 1.0) + start;
