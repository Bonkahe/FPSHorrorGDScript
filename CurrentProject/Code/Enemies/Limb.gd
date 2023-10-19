extends Node
class_name Limb

@export var LimbIKContainer: Node3D;
@export var Skeleton: Skeleton3D;
@export var LimbIKSolver: SkeletonIK3D;

@export var LimbIKMagnetOffset: Vector3;
@export var LimbIKTargetOffset: Vector3;
@export var AllowedIKInaccuracies: float = 0.2;

@export_range(0,1) var EnemyBodyOriginVelocityBias: float = 0.8;
@export_range(0,1) var EnemyBodyDesiredVelocityBias: float = 0.8;

@export var ThisLimb: LimbReference.LimbEnum;
@export var TargetPointOffsetMinimumDistance: float;
@export var ControlPointOffsetMinimumDistance: float;
@export var ControlPointOffset: float;
@export var BlendSpeed: float = 3;
@export var MinimumMovementDistance: float = 0.5;

var CurrentTargetLocation: Vector3;
var Controller: LimbPlacementController;

var CurrentLerpValue: float;
var CurrentlyTraveling: bool;
var CurrentCurve: BezierCurve;

var IKBoneTipID: int;

func _ready():
	CurrentCurve = GetInitialCurve();
	CurrentTargetLocation = CurrentCurve.TargetLocation;
	
	SetIKTargets();
	LimbIKSolver.start();
	IKBoneTipID = Skeleton.find_bone(LimbIKSolver.tip_bone);

func _physics_process(delta):
#	DebugExtensions.DrawPoint(self, CurrentTargetLocation, delta, Color(0,1,0) if CurrentlyTraveling else Color(1,0,0), 0.3);
	if (CurrentlyTraveling):
		CurrentLerpValue = clamp(CurrentLerpValue + (BlendSpeed * delta), 0, 1);
		CurrentTargetLocation = AdjustTargetPoint(CurrentCurve.Lerp(CurrentLerpValue));
		if (CurrentLerpValue == 1):
			CurrentLerpValue = 0;
			CurrentlyTraveling = false;
	
	SetIKTargets();

func SetIKTargets():
	LimbIKSolver.magnet = Skeleton.to_local(LimbIKContainer.global_position.lerp(Controller.EnemyBody.global_position, 0.5) + (Controller.ChestTargetContainer.global_transform.basis * LimbIKMagnetOffset));
	
	LimbIKContainer.global_position = CurrentTargetLocation + (Controller.ChestTargetContainer.global_transform.basis * LimbIKTargetOffset);
	
	var newLookatPos = LimbIKContainer.global_position + (LimbIKContainer.global_position - Controller.EnemyBody.global_position).normalized();
	newLookatPos.y = LimbIKContainer.global_position.y;
	
	var normal:Vector3 = CurrentCurve.OriginHitNormal.lerp(CurrentCurve.TargetHitNormal, CurrentLerpValue) if CurrentlyTraveling else CurrentCurve.TargetHitNormal;
	var currentDifference:float = absf((newLookatPos - LimbIKContainer.global_position).dot(normal));
	
	LimbIKContainer.look_at(newLookatPos, 
		Controller.ChestTargetContainer.global_transform.basis.z if currentDifference > 0.99 || normal.is_zero_approx() else normal)

func InitializeStep():
	var newcurve = GetNewCurve();
	if (newcurve != null):
		CurrentLerpValue = 0;
		CurrentlyTraveling = true;
		
		if (CurrentCurve.HitSurface and Controller.EnemyBody.DesiredVelocity != Vector3.ZERO):
			if (ThisLimb == LimbReference.LimbEnum.LeftFoot ||ThisLimb == LimbReference.LimbEnum.RightFoot):
				var footVector:Vector3 = (LimbIKContainer.global_position - newcurve.TargetLocation).normalized().lerp(Controller.EnemyBody.DesiredVelocity, EnemyBodyDesiredVelocityBias);
				Controller.KickOffVelocity(footVector.normalized(), LimbIKContainer.global_position.lerp(Controller.EnemyBody.global_position, EnemyBodyOriginVelocityBias));
			else:
				var handVector:Vector3 = (newcurve.TargetLocation - LimbIKContainer.global_position).normalized().lerp(Controller.EnemyBody.DesiredVelocity, EnemyBodyDesiredVelocityBias);
				Controller.KickOffVelocity(handVector.normalized(), LimbIKContainer.global_position.lerp(Controller.EnemyBody.global_position, EnemyBodyOriginVelocityBias));
		
		CurrentCurve = newcurve;


func GetInitialCurve():
	var targetData = Controller.GetTargetLimbPosition(ThisLimb);
	var newCurve = BezierCurve.new();
	newCurve.OriginLocation = targetData.Position;
	newCurve.OriginLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
	newCurve.TargetLocation = targetData.Position;
	newCurve.TargetLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
	newCurve.HitSurface = targetData.HitSurface;
	return newCurve;

func GetNewCurve():
	var targetData = Controller.GetTargetLimbPosition(ThisLimb);
	
	var TofarFromTarget:bool = Skeleton.to_global(Skeleton.get_bone_global_pose(IKBoneTipID).origin).distance_to(CurrentTargetLocation) > AllowedIKInaccuracies;
	
	if (CurrentTargetLocation.distance_to(targetData.Position) > MinimumMovementDistance || TofarFromTarget):
		
		if (TofarFromTarget):
			CurrentTargetLocation = Skeleton.to_global(Skeleton.get_bone_global_pose(IKBoneTipID).origin);
			CurrentCurve.HitSurface = false;
		
		var newCurve = BezierCurve.new();
		newCurve.OriginLocation = CurrentTargetLocation;
		newCurve.OriginLocationControl = CurrentTargetLocation + (CurrentCurve.TargetLocationControl - CurrentCurve.TargetLocation);
		newCurve.TargetLocation = targetData.Position;
		newCurve.TargetLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
		newCurve.HitSurface = targetData.HitSurface;
		newCurve.OriginHitNormal = CurrentCurve.TargetHitNormal;
		newCurve.TargetHitNormal = targetData.HitNormal;
		
		return AdjustControlPoints(newCurve);
	else:
		return null;

func AdjustControlPoints(newCurve: BezierCurve):
	var offsettedWorldBodyPosition:Vector3 = Controller.EnemyBody.global_position;
	offsettedWorldBodyPosition.y = newCurve.TargetLocationControl.y;
	
	if (newCurve.TargetLocationControl.distance_to(offsettedWorldBodyPosition) < ControlPointOffsetMinimumDistance):
		newCurve.TargetLocationControl = offsettedWorldBodyPosition + (newCurve.TargetLocationControl - offsettedWorldBodyPosition).normalized() * ControlPointOffsetMinimumDistance;
	
	if (CurrentCurve.HitSurface):
		newCurve.OriginLocationControl = newCurve.OriginLocation + ((newCurve.OriginLocation - newCurve.TargetLocationControl).normalized() * ControlPointOffset);
	elif (newCurve.OriginLocationControl.distance_to(offsettedWorldBodyPosition) < ControlPointOffsetMinimumDistance):
		newCurve.OriginLocationControl = offsettedWorldBodyPosition + (newCurve.OriginLocationControl - offsettedWorldBodyPosition).normalized() * ControlPointOffsetMinimumDistance;
	
	return newCurve;

func AdjustTargetPoint(TargetPoint: Vector3):
	var offsettedWorldBodyPosition : Vector3 = Controller.ChestTargetContainer.to_local(TargetPoint);
	
	if (ThisLimb == LimbReference.LimbEnum.LeftHand or ThisLimb == LimbReference.LimbEnum.LeftFoot):
		offsettedWorldBodyPosition.x = minf(offsettedWorldBodyPosition.x, -TargetPointOffsetMinimumDistance);
	else:
		offsettedWorldBodyPosition.x = maxf(offsettedWorldBodyPosition.x, TargetPointOffsetMinimumDistance);
	
	TargetPoint = Controller.ChestTargetContainer.to_global(offsettedWorldBodyPosition);
	return TargetPoint;


