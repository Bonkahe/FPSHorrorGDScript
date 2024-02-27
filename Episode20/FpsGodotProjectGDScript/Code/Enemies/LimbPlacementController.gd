extends Node
class_name LimbPlacementController

@export var FootstepSounds : Array[AudioStream] = []
@export var JumpSounds : Array[AudioStream] = []

@export var Skeleton: Skeleton3D
@export var ChestBone: PhysicalBone3D
@export var HeadIKSolver: SkeletonIK3D

@export var ChestTargetPoint: Node3D
@export var ChestTargetContainer: Node3D
@export var HeadTargetContainer: Node3D

@export var JumpVelocity: float = 8
@export var LaunchVelocityMultiplier: float = 5
@export var MaxLaunchVelocity: float = 40

@export var StepBouncePower: float = 5
@export var TorsoBounceVisualStrength: float = 0.2
@export var TorsoLerpSpeed: float = 12
@export var TorsoRotationLerpSpeed: float = 8
@export var HeadRotationLerpSpeed: float = 2

@export var EnemyAIController: EnemyAIController
@export var EnemyBody: BasicEnemyNavigationAgent
@export var LimbRaycast: RayCast3D
@export var BodyLength: float = 1

@export var ShoulderBodyWidth: float = 0.5
@export var BottomBodyWidth: float = 2

@export var TargetOffsetDown: float = 2.5

@export var CurrentLimbs: Array[Limb]
@export var MinimumLimbStepDelay: float = 0.12
@export var VelocityAccountingMultiplier: float = 0.45

@export var FlightFlailSpeed: float = 15
@export var FlightFlailSize: float = 3

var CurrentFlightTime: float

var CurrentLimbStepDelayTimer: float;
var CurrentLimbIndex: int;

var LastVelocity: Vector3 = Vector3.FORWARD;

var CurrentTorsoOffset: Vector3 = Vector3.ZERO;
var ChestBoneID: int;

var lastGroundedState: BasicEnemyNavigationAgent.GroundedState
var LaunchingRequested: bool

func _ready():
	lastGroundedState = EnemyBody.CurrentGroundedState
	
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
	EnemyAIController.CheckTargetValid()
	
	if (lastGroundedState != EnemyBody.CurrentGroundedState):
		CurrentFlightTime = 0
		
		if (EnemyBody.CurrentGroundedState == BasicEnemyNavigationAgent.GroundedState.None):
			var rng = RandomNumberGenerator.new();
			rng.randomize()
			
			for limb in CurrentLimbs:
				limb.SetLimbGroundedState(false, rng.randf() * 10.0)
		else:
			for limb in CurrentLimbs:
				limb.SetLimbGroundedState(true, 0)
				limb.PlaceFootHard()
		
		lastGroundedState = EnemyBody.CurrentGroundedState
	
	if (EnemyBody.CurrentGroundedState != BasicEnemyNavigationAgent.GroundedState.None):
		if !LaunchingRequested:
			CurrentLimbStepDelayTimer += delta;
			if CurrentLimbStepDelayTimer >= MinimumLimbStepDelay:
				CurrentLimbStepDelayTimer -= MinimumLimbStepDelay;
				CurrentLimbs[CurrentLimbIndex].InitializeStep();
				CurrentLimbIndex += 1;
				if (CurrentLimbIndex == CurrentLimbs.size()):
					CurrentLimbIndex = 0;
	else:
		CurrentFlightTime += delta * FlightFlailSpeed
	
	var countval = 0;
	for limb in CurrentLimbs:
		if (limb.CurrentlyTraveling):
			countval += 1;
	
	CurrentTorsoOffset = Vector3.DOWN * countval * TorsoBounceVisualStrength;
	
	UpdateBodyPositions(delta)
	UpdateHeadPosition(delta)

func OnLaunchRequested():
	if (LaunchingRequested):
		return
	
	LaunchingRequested = true
	
	for limb in CurrentLimbs:
		limb.PlaceFootHard()
	
	await get_tree().create_timer(0.25).timeout
	
	var waypoint: BasicEnemyNavigationAgent.PathWaypoint = EnemyBody.GetNextWaypoint()
	var requestedVelocity: Vector3 = waypoint.WaypointPosition
	
	requestedVelocity += Vector3.UP * EnemyBody.global_position.distance_to(requestedVelocity) * 2.0
	requestedVelocity = ((requestedVelocity - EnemyBody.global_position) * LaunchVelocityMultiplier) - EnemyBody.linear_velocity
	
	if (requestedVelocity.length() > MaxLaunchVelocity):
		requestedVelocity = requestedVelocity.normalized() * MaxLaunchVelocity
	
	EnemyBody.apply_impulse(requestedVelocity)
	LaunchingRequested = false
	
	if (FootstepSounds.size() > 0):
		get_tree().call_group("AudioQues", "PlayAudioQue3D", FootstepSounds[RandomNumberGenerator.new().randi_range(0, FootstepSounds.size() - 1)], EnemyBody.global_position, 5)

func OnAttackLaunchRequested(target: Node3D):
	if (LaunchingRequested):
		return
	
	LaunchingRequested = true
	
	for limb in CurrentLimbs:
		limb.PlaceFootHard()
	
	await get_tree().create_timer(0.25).timeout
	
	var requestedVelocity: Vector3 = target.global_position
	
	requestedVelocity += Vector3.UP * EnemyBody.global_position.distance_to(requestedVelocity) * 0.5
	requestedVelocity = ((requestedVelocity - EnemyBody.global_position) * LaunchVelocityMultiplier) - EnemyBody.linear_velocity
	
	if (requestedVelocity.length() > MaxLaunchVelocity):
		requestedVelocity = requestedVelocity.normalized() * MaxLaunchVelocity
	
	EnemyBody.apply_impulse(requestedVelocity)
	LaunchingRequested = false
	
	if (JumpSounds.size() > 0):
		get_tree().call_group("AudioQues", "PlayAudioQue3D", JumpSounds[RandomNumberGenerator.new().randi_range(0, JumpSounds.size() - 1)], EnemyBody.global_position, 0)


func KickOffVelocity(desiredDirection: Vector3, targetPoint: Vector3):
	if (FootstepSounds.size() > 0):
		get_tree().call_group("AudioQues", "PlayAudioQue3D", FootstepSounds[RandomNumberGenerator.new().randi_range(0, FootstepSounds.size() - 1)], EnemyBody.global_position, 0)
	
	var currentVelocity: float = JumpVelocity;
	if (EnemyBody.linear_velocity.dot(EnemyBody.DesiredVelocity) < 0):
		currentVelocity *= EnemyBody.DesiredVelocity.length() * VelocityAccountingMultiplier;
	
	EnemyBody.apply_impulse(desiredDirection * currentVelocity + (Vector3.UP * StepBouncePower) - EnemyBody.linear_velocity, EnemyBody.to_local(targetPoint));

func UpdateBodyPositions(delta: float):
	ChestTargetContainer.global_position.x = EnemyBody.global_position.x;
	ChestTargetContainer.global_position.z = EnemyBody.global_position.z;
	ChestTargetContainer.global_position.y = lerp(
		ChestTargetContainer.global_position.y, 
		(EnemyBody.global_position + (ChestTargetContainer.global_transform.basis.y * CurrentTorsoOffset)).y, 
		delta * TorsoLerpSpeed);
	
	var UpVector : Vector3 = EnemyBody.GetGroundNormal()
	if (UpVector == Vector3.UP):
		UpVector = Vector3.BACK if abs(LastVelocity.y) > 0.99 else Vector3.UP
	
	var targetRotation = ChestTargetContainer.global_transform.looking_at(
		ChestTargetContainer.global_position + LastVelocity, UpVector).basis.get_euler()
	
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
	var UpVector : Vector3 = EnemyBody.GetGroundNormal()
	if (UpVector == Vector3.UP):
		UpVector = Vector3.BACK if abs(LastVelocity.y) > 0.99 else Vector3.UP
	
	var targetPosition = EnemyBody.global_position + UpVector
	
	targetPosition += EnemyBody.linear_velocity * VelocityAccountingMultiplier;
	
	if EnemyBody.linear_velocity.length() > 0.5:
		LastVelocity = EnemyBody.linear_velocity.normalized();
	
	targetPosition += LastVelocity * (BodyLength / 2) * (-1 if targetLimb == LimbReference.LimbEnum.LeftFoot or targetLimb == LimbReference.LimbEnum.RightFoot else 1);
	
	var centerPoint = targetPosition;
	var sideAngle = LastVelocity.cross(UpVector) * (-1 if targetLimb == LimbReference.LimbEnum.LeftHand or targetLimb == LimbReference.LimbEnum.LeftFoot else 1);
	
	targetPosition = centerPoint + (sideAngle * (ShoulderBodyWidth / 2));
	
	LimbRaycast.global_position = targetPosition;
	
	targetPosition = centerPoint + (sideAngle * (BottomBodyWidth / 2)) + (-UpVector * (TargetOffsetDown + 1));
	
	if (targetPosition == LimbRaycast.global_position):
		targetPosition += Vector3.DOWN
	
	LimbRaycast.look_at(targetPosition, Vector3.BACK if abs((targetPosition - LimbRaycast.global_position).y) > 0.99 else Vector3.UP);
	LimbRaycast.force_raycast_update();
	
	var hitSurface = LimbRaycast.is_colliding();
	var hitNormal = UpVector;
	if hitSurface:
		targetPosition = LimbRaycast.get_collision_point();
		hitNormal = LimbRaycast.get_collision_normal();
	
	return {"Position": targetPosition, "HitSurface": hitSurface, "HitNormal": hitNormal};
	

## Almost Identical to GetTargetLimbPosition, except that the position is generated via sin and cos to make a flailing motion
func GetTargetLimbFlyingPosition(targetLimb: LimbReference.LimbEnum, flightTimeOffset : float) -> Vector3:
	
	var UpVector : Vector3 = EnemyBody.GetGroundNormal()
	if (UpVector == Vector3.UP):
		UpVector = Vector3.BACK if abs(LastVelocity.y) > 0.99 else Vector3.UP
	
	var targetPosition = EnemyBody.global_position + UpVector
	
	targetPosition += EnemyBody.linear_velocity * VelocityAccountingMultiplier * (0.1 if targetLimb == LimbReference.LimbEnum.LeftFoot or targetLimb == LimbReference.LimbEnum.RightFoot else 1)
	
	if EnemyBody.linear_velocity.length() > 0.5:
		LastVelocity = EnemyBody.linear_velocity.normalized()
	
	targetPosition += LastVelocity * (BodyLength / 2) * (-1 if targetLimb == LimbReference.LimbEnum.LeftFoot or targetLimb == LimbReference.LimbEnum.RightFoot else 1)
	
	var centerPoint = targetPosition
	var sideAngle = LastVelocity.cross(UpVector) * (-1 if targetLimb == LimbReference.LimbEnum.LeftHand or targetLimb == LimbReference.LimbEnum.LeftFoot else 1)
	
	targetPosition = centerPoint + (sideAngle * (ShoulderBodyWidth / 2))
	
	LimbRaycast.global_position = targetPosition
	
	targetPosition = centerPoint + (sideAngle * (BottomBodyWidth / 2)) + (-UpVector * (TargetOffsetDown + 1))
	
	var flailOffset : Vector3 = Vector3(0, sin(CurrentFlightTime + flightTimeOffset), cos(CurrentFlightTime + flightTimeOffset)) * FlightFlailSize
	
	targetPosition += ChestTargetContainer.global_transform.basis * flailOffset
	
	LimbRaycast.look_at(targetPosition, Vector3.BACK if abs((targetPosition - LimbRaycast.global_position).y) > 0.99 else Vector3.UP)
	LimbRaycast.force_raycast_update()
	
	if LimbRaycast.is_colliding():
		targetPosition = LimbRaycast.get_collision_point()
	
	return targetPosition
