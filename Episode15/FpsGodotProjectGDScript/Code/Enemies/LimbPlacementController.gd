extends Node
class_name LimbPlacementController

@export var Skeleton: Skeleton3D
@export var ChestBone: PhysicalBone3D
@export var HeadIKSolver: SkeletonIK3D

@export var ChestTargetPoint: Node3D
@export var ChestTargetContainer: Node3D
@export var HeadTargetContainer: Node3D

@export var JumpVelocity: float = 1.5
@export var StepBouncePower: float = 1.5
@export var TorsoBounceVisualStrength: float = 1.5
@export var TorsoLerpSpeed: float = 1.5
@export var TorsoRotationLerpSpeed: float = 1.5
@export var HeadRotationLerpSpeed: float = 3

@export var EnemyAIController: EnemyAIController
@export var EnemyBody: BasicEnemyNavigationAgent
@export var LimbRaycast: RayCast3D
@export var BodyLength: float = 1.5

@export var ShoulderBodyWidth: float = 2
@export var BottomBodyWidth: float = 2

@export var TargetOffsetDown: float = 1.5

@export var CurrentLimbs: Array[Limb]
@export var MinimumLimbStepDelay: float = 0.15
@export var VelocityAccountingMultiplier: float = 0.5

var CurrentLimbStepDelayTimer: float;
var CurrentLimbIndex: int;

var LastVelocity: Vector3 = Vector3.FORWARD;

var CurrentTorsoOffset: Vector3 = Vector3.ZERO;
var ChestBoneID: int;

func _ready():
	var rng = RandomNumberGenerator.new();
	rng.randomize()
	
	CurrentLimbStepDelayTimer = rng.randf_range(0, MinimumLimbStepDelay);
	CurrentLimbIndex = rng.randf_range(0, CurrentLimbs.size() - 1);
	
	ChestBoneID = ChestBone.get_bone_id();
	HeadIKSolver.start();
	
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
	
	var countval = 0;
	for limb in CurrentLimbs:
		if (limb.CurrentlyTraveling):
			countval += 1;
	
	CurrentTorsoOffset = Vector3.DOWN * countval * TorsoBounceVisualStrength;
	
	UpdateBodyPositions(delta)
	UpdateHeadPosition(delta)

func KickOffVelocity(desiredDirection: Vector3, targetPoint: Vector3):
	var currentVelocity: float = JumpVelocity;
	if (EnemyBody.linear_velocity.dot(EnemyBody.DesiredVelocity) < 0):
		currentVelocity *= EnemyBody.DesiredVelocity.length() * VelocityAccountingMultiplier;
	
	EnemyBody.apply_impulse(desiredDirection * currentVelocity + (ChestTargetContainer.global_transform.basis.y * StepBouncePower) - EnemyBody.linear_velocity, EnemyBody.to_local(targetPoint));

func UpdateBodyPositions(delta: float):
	ChestTargetContainer.global_position.x = EnemyBody.global_position.x;
	ChestTargetContainer.global_position.z = EnemyBody.global_position.z;
	ChestTargetContainer.global_position.y = lerp(
		ChestTargetContainer.global_position.y, 
		(EnemyBody.global_position + (ChestTargetContainer.global_transform.basis.y * CurrentTorsoOffset)).y, 
		delta * TorsoLerpSpeed);
	
	var targetRotation = ChestTargetContainer.global_transform.looking_at(
		ChestTargetContainer.global_position + LastVelocity, 
		Vector3.BACK if abs(LastVelocity.y) > 0.99 else Vector3.UP).basis.get_euler();
	
	ChestTargetContainer.global_rotation.x = lerp_angle(ChestTargetContainer.global_rotation.x, targetRotation.x, delta * TorsoRotationLerpSpeed);
	ChestTargetContainer.global_rotation.y = lerp_angle(ChestTargetContainer.global_rotation.y, targetRotation.y, delta * TorsoRotationLerpSpeed);
	ChestTargetContainer.global_rotation.z = lerp_angle(ChestTargetContainer.global_rotation.z, targetRotation.z, delta * TorsoRotationLerpSpeed);
	Skeleton.global_position = ChestTargetContainer.global_position;
	
	
	Skeleton.set_bone_pose_position(ChestBoneID, Skeleton.to_local(ChestTargetPoint.global_position));
	Skeleton.set_bone_pose_rotation(ChestBoneID, ChestTargetPoint.global_transform.basis.get_rotation_quaternion());

func UpdateHeadPosition(delta: float):
	HeadTargetContainer.global_position = ChestTargetContainer.global_position;
	
	var targetLookAtPoint: Vector3 = EnemyAIController.CurrentTarget.global_position if EnemyAIController.CurrentTarget != null else ChestTargetContainer.global_position + LastVelocity;
	var targetRotation: Vector3 = HeadTargetContainer.global_transform.looking_at(targetLookAtPoint, 
		Vector3.UP if abs(ChestTargetContainer.global_transform.basis.y.dot(targetLookAtPoint - HeadTargetContainer.global_position)) > 0.99 else ChestTargetContainer.global_transform.basis.y).basis.get_euler();
	
	HeadTargetContainer.global_rotation.x = lerp_angle(HeadTargetContainer.global_rotation.x, targetRotation.x, delta * HeadRotationLerpSpeed);
	HeadTargetContainer.global_rotation.y = lerp_angle(HeadTargetContainer.global_rotation.y, targetRotation.y, delta * HeadRotationLerpSpeed);
	HeadTargetContainer.global_rotation.z = lerp_angle(HeadTargetContainer.global_rotation.z, targetRotation.z, delta * HeadRotationLerpSpeed);
	
	HeadIKSolver.interpolation = ((-ChestTargetContainer.global_transform.basis.z).dot(targetLookAtPoint - HeadTargetContainer.global_position) + 1) / 2;

func GetTargetLimbPosition(targetLimb: LimbReference.LimbEnum):
	var targetPosition = EnemyBody.global_position + ChestTargetContainer.global_transform.basis.y;
	
	targetPosition += EnemyBody.linear_velocity * VelocityAccountingMultiplier;
	
	if EnemyBody.linear_velocity.length() > 0.5:
		LastVelocity = EnemyBody.linear_velocity.normalized();
	
	targetPosition += LastVelocity * (BodyLength / 2) * (-1 if targetLimb == LimbReference.LimbEnum.LeftFoot or targetLimb == LimbReference.LimbEnum.RightFoot else 1);
	
	var centerPoint = targetPosition;
	var sideAngle = LastVelocity.cross(ChestTargetContainer.global_transform.basis.y) * (-1 if targetLimb == LimbReference.LimbEnum.LeftHand or targetLimb == LimbReference.LimbEnum.LeftFoot else 1);
	
	targetPosition = centerPoint + (sideAngle * (ShoulderBodyWidth / 2));
	
	LimbRaycast.global_position = targetPosition;
	
	targetPosition = centerPoint + (sideAngle * (BottomBodyWidth / 2)) + (-ChestTargetContainer.global_transform.basis.y * (TargetOffsetDown + 1));
	
	LimbRaycast.look_at(targetPosition, Vector3.BACK if abs((targetPosition - LimbRaycast.global_position).y) > 0.99 else Vector3.UP);
	LimbRaycast.force_raycast_update();
	
	var hitSurface = LimbRaycast.is_colliding();
	var hitNormal = ChestTargetContainer.global_transform.basis.y;
	if hitSurface:
		targetPosition = LimbRaycast.get_collision_point();
		hitNormal = LimbRaycast.get_collision_normal();
	
	return {"Position": targetPosition, "HitSurface": hitSurface, "HitNormal": hitNormal};
	
