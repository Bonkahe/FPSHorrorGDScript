extends Node

class_name WeaponEffectsController

signal OnShotCameraImpulse (impulseDirection : Vector3, shotCameraImpulse : float);

@export_category("Shot Functionality")
@export var BarrelEnd: Node3D;
@export var BarrelRayCast: RayCast3D;
@export var MuzzleFlash: PackedScene;
@export var ImpactEffect: PackedScene;

@export var ImpactForce: float = 20;
@export var CameraShakePower: float = 0.3;

@export_category("Spread")
@export var SpreadNoise : FastNoiseLite;

@export var SpreadPanningSpeed : float = 10;
@export var SpreadAimingConeSize : float = 5;
@export var SpreadIdleConeSize : float = 20;

@export var SpreadBloomPerShot : float = 5;
@export var SpreadBloomDecay : float = 3;

@export_range(-1,1) var RecoilHorizontalBias: float = -0.15;
@export_range(0,1) var RecoilRotationBias: float = 0.85;

@export var RecoilSize : float = 15;
@export var RecoilPanningSpeed : float = 15;
@export var RecoilFade : float = 20;
@export var RecoilActualBlendSpeed : float = 10;

@export_category("Flashlight")
@export var FlashlightDelayDurationRange : Vector2 = Vector2(1.0, 2.0);
@export var FlashlightPointDurationRange : Vector2 = Vector2(2.0, 3.0);

@export var FlashlightPerPriorityLevelAdditive : float = 1.0;
@export var FlashlightViewRange : float = 25.0;
@export var FlashlightTargetMoveSpeed : float = 5.0;
@export var FlashlightBlendSpeed : float = 1.2;

@export_range(0,180) var FlashlightFieldOfViewClamp : float = 30.0;

@export_category("World Collision")
@export_flags_3d_physics var EnvironmentCollisionMask: int;
@export var EnvironmentStandoff : float = 0.15;

@export var TiltMaxVerticalOffset : float = 0.2;
@export var TiltMaxDistanceAiming : float = 0.4;
@export var TiltMaxDistanceIdle : float = 0.1;

@export var TiltBlendSpeed : float = 2.5;

@export_category("Node References")
@export var RightHandIKSolver: SkeletonIK3D;
@export var LeftHandIKSolver: SkeletonIK3D;

@export var CameraNode: Node3D;

@export var AimingIKContainer: Node3D;
@export var RightHandIdleIKContainer: Node3D;
@export var LeftHandIdleIKContainer: Node3D;

@export var RightHandIdleIKTarget: Node3D;
@export var RightHandAimingIKTarget: Node3D;
@export var LeftHandIdleIKTarget: Node3D;
@export var LeftHandAimingIKTarget: Node3D;

var HandOffsetPosition: Vector3;

var hasRoundAvailable: bool = false;
var IsAiming: bool = false;
var currentRoundCount: int;

var currentRecoilTarget: float;
var currentRecoilActual: float;
var currentRecoilTime: float;

var currentSpreadAdditive: float;
var currentSpreadTime: float;

var AimingTargetBasePosition: Vector3;
var RightHandIdleBasePosition: Vector3;
var LeftHandIdleBasePosition: Vector3;

var currentRightTiltWeight: float;
var lastRightTiltOffsetVector: Vector3;
var lastRightTiltLookAtVector: Vector3;

var currentLeftTargetTrackingWeight: float;
var lastLeftHandTargetPositionVector: Vector3;
var currentLeftTiltWeight: float;
var lastLeftTiltOffsetVector: Vector3;
var lastLeftTiltLookAtVector: Vector3;

var currentFlashlightTarget: FlashlightPoint;
var currentFlashlightTimer: float;

func _ready():
	AimingTargetBasePosition = AimingIKContainer.position;
	RightHandIdleBasePosition = RightHandIdleIKContainer.position;
	LeftHandIdleBasePosition = LeftHandIdleIKContainer.position;
	
	RightHandIKSolver.start();
	LeftHandIKSolver.start();
	
	Reload();

func _physics_process(delta):
	currentRecoilTime = wrap(currentRecoilTime + (delta * RecoilPanningSpeed), 0, 1000000);
	currentSpreadTime = wrap(currentSpreadTime + (delta * SpreadPanningSpeed), 0, 1000000);
	
	currentSpreadAdditive = max(currentSpreadAdditive - (delta * SpreadBloomDecay), 0);
	currentRecoilTarget = max(currentRecoilTarget - (delta * RecoilFade), 0);
	
	currentRecoilActual = lerp(currentRecoilActual, currentRecoilTarget, delta * RecoilActualBlendSpeed);
	var recoil : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentRecoilTime) * 0.5 + 1, SpreadNoise.get_noise_1d(currentRecoilTime + 1000) - RecoilHorizontalBias, 0) * deg_to_rad(currentRecoilActual));
	
	if (IsAiming):
		if (currentFlashlightTarget != null && currentFlashlightTarget.priority < FlashlightPoint.Priority.high):
			currentFlashlightTarget = null;
		
		var spread : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentSpreadTime), SpreadNoise.get_noise_1d(currentSpreadTime + 1000), 0) * deg_to_rad(SpreadAimingConeSize + currentSpreadAdditive));
		AimingIKContainer.rotation = recoil + spread;
		AimingIKContainer.global_position = CameraNode.to_global(AimingTargetBasePosition).lerp(CameraNode.global_position + (-AimingIKContainer.global_transform.basis.z).normalized() * AimingTargetBasePosition.length(), RecoilRotationBias);
		AimingIKContainer.global_position += HandOffsetPosition;
		
		AimingIKContainer.global_transform = AdjustToEnvironment(AimingIKContainer.global_transform, delta, true);
	else:
		var spread : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentSpreadTime), SpreadNoise.get_noise_1d(currentSpreadTime + 1000), 0) * deg_to_rad(SpreadIdleConeSize + currentSpreadAdditive));
		RightHandIdleIKContainer.rotation = recoil + spread;
		RightHandIdleIKContainer.global_position = CameraNode.to_global(RightHandIdleBasePosition).lerp(CameraNode.to_global(Vector3(RightHandIdleBasePosition.x, RightHandIdleBasePosition.y, 0)) + (-RightHandIdleIKContainer.global_transform.basis.z).normalized() * RightHandIdleBasePosition.length(), RecoilRotationBias);
		RightHandIdleIKContainer.global_position += HandOffsetPosition;
		
		RightHandIdleIKContainer.global_transform = AdjustToEnvironment(RightHandIdleIKContainer.global_transform, delta, true);
		
		UpdateFlashlightTarget(delta);
		
		if (currentFlashlightTarget != null):
			currentLeftTargetTrackingWeight = min(currentLeftTargetTrackingWeight + delta * FlashlightBlendSpeed, 1);
			lastLeftHandTargetPositionVector = lastLeftHandTargetPositionVector.lerp(CameraNode.to_local(currentFlashlightTarget.global_position), delta * FlashlightTargetMoveSpeed);
		else:
			currentLeftTargetTrackingWeight = max(currentLeftTargetTrackingWeight - delta * FlashlightBlendSpeed, 0);
		
		spread = Vector3(SpreadNoise.get_noise_1d(currentSpreadTime + 10), SpreadNoise.get_noise_1d(currentSpreadTime + 1010), 0) * deg_to_rad(SpreadIdleConeSize);
		
		if (currentLeftTargetTrackingWeight > 0):
			LeftHandIdleIKContainer.look_at(CameraNode.to_global(lastLeftHandTargetPositionVector));
			LeftHandIdleIKContainer.rotation += spread;
			
			LeftHandIdleIKContainer.rotation = spread.lerp(LeftHandIdleIKContainer.rotation, currentLeftTargetTrackingWeight);
		else:
			LeftHandIdleIKContainer.rotation = spread;
		
		LeftHandIdleIKContainer.global_position = CameraNode.to_global(LeftHandIdleBasePosition).lerp(CameraNode.to_global(Vector3(LeftHandIdleBasePosition.x, LeftHandIdleBasePosition.y, 0)) + (-LeftHandIdleIKContainer.global_transform.basis.z).normalized() * LeftHandIdleBasePosition.length(), RecoilRotationBias);
		LeftHandIdleIKContainer.global_position += HandOffsetPosition;
		
		LeftHandIdleIKContainer.global_transform = AdjustToEnvironment(LeftHandIdleIKContainer.global_transform, delta, false);

func AdjustToEnvironment(targetGlobalTransform : Transform3D, deltaTime : float, isRight : bool) -> Transform3D:
	var spaceState : PhysicsDirectSpaceState3D = RightHandAimingIKTarget.get_world_3d().direct_space_state;
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(CameraNode.global_position, targetGlobalTransform.origin, EnvironmentCollisionMask);
	
	var offset : Vector3 = -CameraNode.global_transform.basis.z * EnvironmentStandoff;
	query.to += offset;
	
	var result = spaceState.intersect_ray(query);
	
	var currentTiltWeight : float = currentRightTiltWeight if isRight else currentLeftTiltWeight;
	var lastTiltOffsetVector : Vector3 = lastRightTiltOffsetVector if isRight else lastLeftTiltOffsetVector;
	var lastTiltLookAtVector : Vector3 = lastRightTiltLookAtVector if isRight else lastLeftTiltLookAtVector;
	
	if (result):
		var hitpos : Vector3 = result.position;
		var hitnormal : Vector3 = result.normal;
		
		var tiltWeight : float = clamp(hitpos.distance_to(query.to) / (TiltMaxDistanceAiming if IsAiming else TiltMaxDistanceIdle), 0, 1);
		currentTiltWeight += (tiltWeight - currentTiltWeight) * deltaTime * TiltBlendSpeed;
		
		targetGlobalTransform.origin = hitpos - offset + (Vector3.UP * currentTiltWeight * TiltMaxVerticalOffset);
		lastTiltOffsetVector = CameraNode.to_local(targetGlobalTransform.origin);
		
		var newLookAtVector : Vector3 = (hitpos - (CameraNode.global_position - Vector3(0,1,0))).bounce(hitnormal).normalized() * EnvironmentStandoff;
		lastTiltLookAtVector = newLookAtVector;
		
		targetGlobalTransform = targetGlobalTransform.interpolate_with(
			targetGlobalTransform.looking_at(
				targetGlobalTransform.origin + newLookAtVector, CameraNode.global_transform.basis.z), 
				currentTiltWeight / 2)
		
	elif (currentTiltWeight > 0):
		currentTiltWeight = max(currentTiltWeight - deltaTime * TiltBlendSpeed, 0);
		
		targetGlobalTransform.origin = targetGlobalTransform.origin.lerp(CameraNode.to_global(lastTiltOffsetVector), currentTiltWeight);
		
		targetGlobalTransform = targetGlobalTransform.interpolate_with(
			targetGlobalTransform.looking_at(
				targetGlobalTransform.origin + lastTiltLookAtVector, CameraNode.global_transform.basis.z), 
				currentTiltWeight / 2)
	
	if (isRight):
		currentRightTiltWeight = currentTiltWeight;
		lastRightTiltOffsetVector = lastTiltOffsetVector;
		lastRightTiltLookAtVector = lastTiltLookAtVector;
	else:
		currentLeftTiltWeight = currentTiltWeight;
		lastLeftTiltOffsetVector = lastTiltOffsetVector;
		lastLeftTiltLookAtVector = lastTiltLookAtVector;
	
	return targetGlobalTransform

func UpdateFlashlightTarget(deltaTime : float):
	if (currentFlashlightTarget != null && !IsInFlashlightFieldOfView(currentFlashlightTarget.global_position)):
		currentFlashlightTarget = null;
		currentFlashlightTimer = 0;
	
	currentFlashlightTimer -= deltaTime;
	
	if (currentFlashlightTimer > 0):
		return;
	else:
		var flashlightTargets : Array[FlashlightPoint];
		
		for target in get_tree().get_nodes_in_group("FlashlightPoints"):
			var convertedTarget = target as FlashlightPoint;
			if (convertedTarget && 
				(!convertedTarget.HasBeenTargeted || convertedTarget.priority == FlashlightPoint.Priority.high) &&
				convertedTarget.global_position.distance_to(CameraNode.global_position) < FlashlightViewRange &&
				IsInFlashlightFieldOfView(convertedTarget.global_position)):
					flashlightTargets.append(convertedTarget);
					
		
		var rng  = RandomNumberGenerator.new();
		rng.randomize();
		
		
		if (flashlightTargets.size() > 0):
			flashlightTargets.sort_custom(SortFlashlightTargets);
			
			if (flashlightTargets[0].priority == FlashlightPoint.Priority.high):
				currentFlashlightTarget = flashlightTargets[0];
			else:
				currentFlashlightTarget = flashlightTargets[rng.randi_range(0, flashlightTargets.size() - 1)];
			
			currentFlashlightTarget.HasBeenTargeted = true;
			currentFlashlightTimer = rng.randf_range(FlashlightPointDurationRange.x, FlashlightPointDurationRange.y) + (FlashlightPerPriorityLevelAdditive * currentFlashlightTarget.priority);
		else:
			currentFlashlightTarget = null;
			currentFlashlightTimer = rng.randf_range(FlashlightDelayDurationRange.x, FlashlightDelayDurationRange.y);

func Reload():
	currentRoundCount = 6;
	hasRoundAvailable = true;

func FireRevolver():
	OnShotCameraImpulse.emit(BarrelRayCast.global_transform.basis.z, CameraShakePower);
	
	currentRecoilTarget += RecoilSize;
	currentSpreadAdditive += SpreadBloomPerShot;
	
	var newMuzzleFlash = MuzzleFlash.instantiate() as Node3D;
	BarrelEnd.add_child(newMuzzleFlash);
	newMuzzleFlash.global_position = BarrelEnd.global_position;
	newMuzzleFlash.global_rotation = BarrelEnd.global_rotation;
	
	currentRoundCount -= 1;
	hasRoundAvailable = currentRoundCount > 0;
	
	if (BarrelRayCast.is_colliding()):
		var hitLocation = BarrelRayCast.get_collision_point();
		var damageableEffect = ImpactEffect;
		var impactedTarget = BarrelRayCast.get_collider() as Node3D;
		
		if (impactedTarget is RigidBody3D):
			impactedTarget.apply_impulse(-BarrelRayCast.global_transform.basis.z * ImpactForce, hitLocation - impactedTarget.global_position);
		
		if (impactedTarget.has_node("Damageable")):
			var damageable = impactedTarget.get_node("Damageable") as DamageableObject;
			if (damageable.ImpactEffect != null):
				damageableEffect = damageable.ImpactEffect;
			damageable.HitObject(hitLocation, -BarrelRayCast.global_transform.basis.z * ImpactForce);
		
		var newImpactEffect = damageableEffect.instantiate() as Node3D;
		add_child(newImpactEffect);
		newImpactEffect.global_position = hitLocation;
		
		var lookAtPoint = BarrelRayCast.get_collision_normal();
		
		if (lookAtPoint != Vector3.ZERO):
			newImpactEffect.look_at(newImpactEffect.global_position + lookAtPoint, Vector3.BACK if abs(lookAtPoint.y) > 0.99 else Vector3.UP);

func SetAimMode():
	LeftHandIKSolver.target_node = LeftHandAimingIKTarget.get_path();
	RightHandIKSolver.target_node = RightHandAimingIKTarget.get_path();
	IsAiming = true;

func SetIdleMode():
	LeftHandIKSolver.target_node = LeftHandIdleIKTarget.get_path();
	RightHandIKSolver.target_node = RightHandIdleIKTarget.get_path();
	IsAiming = false;

func IsInFlashlightFieldOfView(position : Vector3) -> bool:
	return ((-CameraNode.global_transform.basis.z.dot((position - CameraNode.global_transform.origin).normalized()) * -1 + 1) / 2) * 180 < FlashlightFieldOfViewClamp;

func SortFlashlightTargets(a : FlashlightPoint, b : FlashlightPoint):
	return a.priority > b.priority;


