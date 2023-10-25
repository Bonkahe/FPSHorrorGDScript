extends Node

class_name WeaponEffectsController

@export_category("Shot Functionality")
@export var BarrelEnd: Node3D;
@export var BarrelRayCast: RayCast3D;
@export var MuzzleFlash: PackedScene;
@export var ImpactEffect: PackedScene;

@export var ImpactForce: float = 20;

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

func _ready():
	AimingTargetBasePosition = AimingIKContainer.position;
	RightHandIdleBasePosition = RightHandIdleIKContainer.position;
	LeftHandIdleBasePosition = LeftHandIdleIKContainer.position;
	
	RightHandIKSolver.start();
	LeftHandIKSolver.start();
	
	Reload();

func _process(delta):
	currentRecoilTime = wrap(currentRecoilTime + (delta * RecoilPanningSpeed), 0, 1000000);
	currentSpreadTime = wrap(currentSpreadTime + (delta * SpreadPanningSpeed), 0, 1000000);
	
	currentSpreadAdditive = max(currentSpreadAdditive - (delta * SpreadBloomDecay), 0);
	currentRecoilTarget = max(currentRecoilTarget - (delta * RecoilFade), 0);
	
	currentRecoilActual = lerp(currentRecoilActual, currentRecoilTarget, delta * RecoilActualBlendSpeed);
	var recoil : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentRecoilTime) * 0.5 + 1, SpreadNoise.get_noise_1d(currentRecoilTime + 1000) - RecoilHorizontalBias, 0) * deg_to_rad(currentRecoilActual));
	
	if (IsAiming):
		var spread : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentSpreadTime), SpreadNoise.get_noise_1d(currentSpreadTime + 1000), 0) * deg_to_rad(SpreadAimingConeSize + currentSpreadAdditive));
		AimingIKContainer.rotation = recoil + spread;
		AimingIKContainer.global_position = CameraNode.to_global(AimingTargetBasePosition).lerp(CameraNode.global_position + (-AimingIKContainer.global_transform.basis.z).normalized() * AimingTargetBasePosition.length(), RecoilRotationBias);
	else:
		var spread : Vector3 = (Vector3(SpreadNoise.get_noise_1d(currentSpreadTime), SpreadNoise.get_noise_1d(currentSpreadTime + 1000), 0) * deg_to_rad(SpreadIdleConeSize + currentSpreadAdditive));
		RightHandIdleIKContainer.rotation = recoil + spread;
		RightHandIdleIKContainer.global_position = CameraNode.to_global(RightHandIdleBasePosition).lerp(CameraNode.to_global(Vector3(RightHandIdleBasePosition.x, RightHandIdleBasePosition.y, 0)) + (-RightHandIdleIKContainer.global_transform.basis.z).normalized() * RightHandIdleBasePosition.length(), RecoilRotationBias);

func Reload():
	currentRoundCount = 6;
	hasRoundAvailable = true;

func FireRevolver():
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

