extends Node
class_name LimbPlacementController


@export var EnemyBody: RigidBody3D;
@export var LimbRaycast: RayCast3D;
@export var BodyLength: float = 1.5;
@export var BodyWidth: float = 2;
@export var TargetOffsetDown: float = 1.5;

@export var CurrentLimbs: Array[Limb];
@export var MinimumLimbStepDelay: float = 0.15;
@export var VelocityAccountingMultiplier: float = 0.5;

var CurrentLimbStepDelayTimer: float;
var CurrentLimbIndex: int;

var LastVelocity: Vector3 = Vector3.FORWARD;

func _ready():
	LimbRaycast.target_position = Vector3(0,0,-TargetOffsetDown);
	
	for limb in CurrentLimbs:
		limb.Controller = self;

func _physics_process(delta):
	CurrentLimbStepDelayTimer += delta;
	if CurrentLimbStepDelayTimer >= MinimumLimbStepDelay:
		CurrentLimbStepDelayTimer -= MinimumLimbStepDelay;
		CurrentLimbs[CurrentLimbIndex].InitializeStep();
		CurrentLimbIndex += 1;
		if (CurrentLimbIndex == CurrentLimbs.size()):
			CurrentLimbIndex = 0;

func GetTargetLimbPosition(targetLimb: LimbReference.LimbEnum):
	var targetPosition = EnemyBody.global_position;
	
	targetPosition += EnemyBody.linear_velocity * VelocityAccountingMultiplier;
	
	if EnemyBody.linear_velocity.length() > 0.5:
		LastVelocity = EnemyBody.linear_velocity.normalized();
	
	targetPosition += LastVelocity * (BodyLength / 2) * (-1 if targetLimb == LimbReference.LimbEnum.LeftFoot or targetLimb == LimbReference.LimbEnum.RightFoot else 1);
	
	LimbRaycast.global_position = targetPosition;
	
	targetPosition += LastVelocity.cross(Vector3.UP) * (BodyWidth / 2) * (-1 if targetLimb == LimbReference.LimbEnum.LeftHand or targetLimb == LimbReference.LimbEnum.LeftFoot else 1);
	
	targetPosition.y -= TargetOffsetDown;
	
	LimbRaycast.look_at(targetPosition, Vector3.BACK if abs((targetPosition - LimbRaycast.global_position).y) > 0.99 else Vector3.UP);
	LimbRaycast.force_raycast_update();
	
	var hitSurface = LimbRaycast.is_colliding();
	var hitNormal = Vector3.UP;
	if hitSurface:
		targetPosition = LimbRaycast.get_collision_point();
		hitNormal = LimbRaycast.get_collision_normal();
	
	return {"Position": targetPosition, "HitSurface": hitSurface, "HitNormal": hitNormal};
	
