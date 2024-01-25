extends RigidBody3D
class_name BasicEnemyNavigationAgent

class PathWaypoint:
	var WaypointPosition : Vector3
	var WaypointNormal : Vector3
	var WaypointNotFloor : bool
	var EstimatedWaypointDuration : float

signal LaunchRequest

@export_group("Path Navigation")

@export var MaximumVelocity: float;
@export var VelocityChange: float;

@export var MinimumLaunchDelay: float = 0.25

@export_group("Path Generation")

@export var DebugActive : bool = false
@export var GroundedCheckDistance : float = 1.25
@export var StoppingDistance : float = 3.0
@export_range(0,1) var WallRoofDistanceChangeAllowance : float = 0.25
@export var UpPathCheckDistance : float = 15.0
@export_flags_3d_physics var WorldCollision : int
@export_range(0,1) var ChanceOfUpPath : float = 0.1

var DesiredVelocity: Vector3
var TargetPosition: Vector3
var LastRetrievedPathWaypoint: PathWaypoint

enum GroundedState {None, Floor, WallRoof}
var CurrentGroundedState : GroundedState = GroundedState.None
var CurrentGroundNormal: Vector3

var InitialWallRoofDistance: float

var LaunchAttemptInterval: float
var WaypointFailureTimer: float

var InternalGravityScale: float

var rng : RandomNumberGenerator
var CurrentPath : Array[PathWaypoint]
var NavMap : RID

func _ready():
	NavMap = get_world_3d().navigation_map
	InternalGravityScale = gravity_scale
	
	rng.randomize()
	LaunchAttemptInterval = rng.randf_range(0, MinimumLaunchDelay)

func _physics_process(delta):
	WaypointReachedCheck()
	CurrentGroundedState = GetGrounded()
	
	if (IsTargetReached()):
		DesiredVelocity = Vector3.ZERO
		return
	
	var currentWaypoint := GetNextWaypoint()
	
	if (CurrentGroundedState == GroundedState.None):
		LaunchAttemptInterval = MinimumLaunchDelay
	else:
		if (LaunchAttemptInterval > 0):
			LaunchAttemptInterval -= delta
	
	if (currentWaypoint.WaypointNotFloor):
		if (CurrentGroundedState == GroundedState.WallRoof):
			linear_velocity -= CurrentGroundNormal * 0.5
			gravity_scale = 0
		else:
			if (CurrentGroundedState == GroundedState.Floor and LaunchAttemptInterval <= 0):
				LaunchAttemptInterval = MinimumLaunchDelay
				LaunchRequest.emit()
			
			gravity_scale = InternalGravityScale
	else:
		gravity_scale = InternalGravityScale
	
	DesiredVelocity = (currentWaypoint.WaypointPosition - global_position).normalized() * MaximumVelocity
	
	if (DebugActive):
		DebugExtensions.BuildDebugLine(self, global_position, currentWaypoint.WaypointPosition, delta * 2.0, Color(0,1,0))

func GetGrounded() -> GroundedState:
	var sphereQuery := PhysicsShapeQueryParameters3D.new()
	
	var sphereShape := SphereShape3D.new()
	sphereShape.radius = GroundedCheckDistance
	
	sphereQuery.shape = sphereShape
	sphereQuery.transform = global_transform
	sphereQuery.collision_mask = WorldCollision
	
	var spaceState := get_world_3d().direct_space_state
	
	CurrentGroundNormal = Vector3.UP
	var result = spaceState.intersect_shape(sphereQuery)
	
	if (result):
		var currentNormal = GetCurrentNormal()
		
		##Quit out early is we're supposed to be on the ground.
		if (currentNormal == Vector3.UP):
			return GroundedState.Floor
		
		##Check the direction of the current "wallroof"
		var rayquery = PhysicsRayQueryParameters3D.create(global_position, global_position - (currentNormal * GroundedCheckDistance), WorldCollision)
		var raycastResult = spaceState.intersect_ray(rayquery)
		
		##If that is nearby, we're on the wall/roof
		if (raycastResult):
			CurrentGroundNormal = raycastResult.normal
			return GroundedState.WallRoof
		else:
			return GroundedState.Floor
		
	else:
		return GroundedState.None

func GetGroundNormal() -> Vector3:
	return CurrentGroundNormal

func GetCurrentNormal() -> Vector3:
	return GetNextWaypoint().WaypointNormal

func GetNextWaypoint() -> PathWaypoint:
	if (CurrentPath.size() > 0):
		if (LastRetrievedPathWaypoint != CurrentPath[0]):
			LastRetrievedPathWaypoint = CurrentPath[0]
			WaypointFailureTimer = LastRetrievedPathWaypoint.EstimatedWaypointDuration
	else:
		if (LastRetrievedPathWaypoint == null):
			LastRetrievedPathWaypoint = PathWaypoint.new()
			LastRetrievedPathWaypoint.WaypointNormal = Vector3.UP
			LastRetrievedPathWaypoint.WaypointPosition = global_position
			LastRetrievedPathWaypoint.WaypointNotFloor = false
	
	return LastRetrievedPathWaypoint

func IsTargetReached() -> bool:
	return (CurrentPath.size() == 0)

func WaypointReachedCheck():
	if (CurrentPath.size() > 0):
		var currentDelta : Vector3 = CurrentPath[0].WaypointPosition - global_position
		var closertoNext : bool = false
		var launch : bool = false
		
		if (CurrentPath.size() > 1):
			closertoNext = (CurrentPath[0].WaypointPosition.distance_to(global_position) > CurrentPath[1].WaypointPosition.distance_to(global_position))
			launch = (CurrentPath.size() > 1 and CurrentPath[0].WaypointNotFloor != CurrentPath[1].WaypointNotFloor)
		
		if (currentDelta.length() <= StoppingDistance or closertoNext):
			CurrentPath.remove_at(0)
			
			if (launch):
				LaunchAttemptInterval = MinimumLaunchDelay
				LaunchRequest.emit()

func SetNewTarget(newTarget : Vector3):
	CurrentPath.clear()
	rng.randomize()
	
	var newPath : Array[Vector3] = NavigationServer3D.map_get_path(NavMap, global_position, newTarget, false)
	
	var CurrentUpVector := Vector3.UP
	var LastWaypoint := global_position
	var LastOnCeiling : bool = false
	var currentPathChance : float = ChanceOfUpPath / newPath.size()
	
	if (LastRetrievedPathWaypoint != null):
		LastOnCeiling = LastRetrievedPathWaypoint.WaypointNotFloor
	
	var spaceState := get_world_3d().direct_space_state
	for waypoint in newPath:
		var estimatedDuration : float = LastWaypoint.distance_to(waypoint) / MaximumVelocity
		
		if (LastOnCeiling and rng.randf() < currentPathChance * 2.0):
			if (DebugActive):
				DebugExtensions.BuildDebugLine(self, LastWaypoint, waypoint, 2, Color(0,0,1))
			LastOnCeiling = false
		LastWaypoint = waypoint
		
		var newWaypoint =  PathWaypoint.new()
		newWaypoint.WaypointNormal = Vector3.UP
		newWaypoint.WaypointPosition = waypoint
		newWaypoint.WaypointNotFloor = false
		newWaypoint.EstimatedWaypointDuration = estimatedDuration
		
		if (!LastOnCeiling):
			if (rng.randf() < currentPathChance):
				CurrentUpVector = Vector3.ONE + (Vector3.ONE * (rng.randf() - 0.5) * 2.0)
			else:
				CurrentPath.append(newWaypoint)
				continue
		
		var query = PhysicsRayQueryParameters3D.create(waypoint, waypoint + (CurrentUpVector * UpPathCheckDistance), WorldCollision)
		var result = spaceState.intersect_ray(query)
		
		
		if (result):
			
			var currentDistance : float = result.position.distance_to(waypoint)
			var currentChangeDelta : float = abs((currentDistance - InitialWallRoofDistance) / InitialWallRoofDistance)
			
			if (LastOnCeiling and currentChangeDelta > WallRoofDistanceChangeAllowance):
				LastOnCeiling = false
			else:
				if (!LastOnCeiling):
					InitialWallRoofDistance = currentDistance
					LastOnCeiling = true
				
				newWaypoint.WaypointNormal = result.normal
				newWaypoint.WaypointPosition = result.position
				newWaypoint.WaypointNotFloor = true
			
		
		CurrentPath.append(newWaypoint)
	
	if (CurrentPath.size() > 0):
		TargetPosition = CurrentPath[CurrentPath.size() - 1].WaypointPosition
	else:
		TargetPosition = global_position
	
	if (DebugActive):
		var lastPosition : Vector3 = global_position
		for waypoint in CurrentPath:
			DebugExtensions.BuildDebugLine(self, lastPosition, waypoint.WaypointPosition, 5.0, Color(1,0,0))
			lastPosition = waypoint.WaypointPosition
