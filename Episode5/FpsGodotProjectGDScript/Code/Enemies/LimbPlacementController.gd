extends Node

@export var EnemyBody: RigidBody3D;
@export var LimbRaycast: RayCast3D;
@export var BodyLength: float = 1.5;
@export var BodyWidth: float = 2;
@export var TargetOffsetDown: float = 1.5;
@export var UpdateRate: float = 0.1;

enum LimbReference {LeftHand, RightHand, LeftFoot, RightFoot};

var LastVelocity: Vector3 = Vector3.FORWARD;
var CurrentUpdateTimer: float;

func _ready():
	LimbRaycast.target_position = Vector3(0,0,-TargetOffsetDown);

func _physics_process(delta):
	CurrentUpdateTimer += delta;
	if CurrentUpdateTimer >= UpdateRate:
		CurrentUpdateTimer -= UpdateRate;
		for limb in LimbReference:
			var targetData = GetTargetLimbPosition(LimbReference[limb]);
			DebugExtensions.DrawPoint(self, targetData.Position, UpdateRate, Color(0,1,0) if targetData.HitSurface else Color(1,0,0), 0.3);

func GetTargetLimbPosition(targetLimb: LimbReference):
	var targetPosition = EnemyBody.global_position;
	
	if EnemyBody.linear_velocity.length() > 0.5:
		LastVelocity = EnemyBody.linear_velocity.normalized();
	
	targetPosition += LastVelocity * (BodyLength / 2) * (-1 if targetLimb == LimbReference.LeftFoot or targetLimb == LimbReference.RightFoot else 1);
	
	LimbRaycast.global_position = targetPosition;
	
	targetPosition += LastVelocity.cross(Vector3.UP) * (BodyWidth / 2) * (-1 if targetLimb == LimbReference.LeftHand or targetLimb == LimbReference.LeftFoot else 1);
	
	targetPosition.y -= TargetOffsetDown;
	
	LimbRaycast.look_at(targetPosition, Vector3.BACK if abs((targetPosition - LimbRaycast.global_position).y) > 0.99 else Vector3.UP);
	LimbRaycast.force_raycast_update();
	
	var hitSurface = LimbRaycast.is_colliding();
	if hitSurface:
		targetPosition = LimbRaycast.get_collision_point();
	
	return {"Position": targetPosition, "HitSurface": hitSurface};
	
