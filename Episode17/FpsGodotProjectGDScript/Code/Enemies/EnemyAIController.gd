extends Node3D
class_name EnemyAIController

@export_category("Wandering Settings")
# If true, allows the center of the wander radius to update whenever moving by targetted pathing override.
@export var AllowMovementOfWanderCenter : bool = false
@export var WanderRadius : float = 20.0

@export_category("Target Tracking Settings")
# Distance moved by the target requiring pathing update
@export var TargetMovementBias : float = 3.0
@export var NavigationAgent : BasicEnemyNavigationAgent
@export var CurrentTarget : Node3D

@export_category("Health Settings")
@export var MaxHealth : float = 1.0
@export var DamagePerShot : float = 1.0

@export var BaseSkeleton : Skeleton3D
# Must have a skeleton3D somewhere in the hirearchy
@export var RagdollScene : PackedScene

var CurrentHealth : float

var WanderingPosition : Vector3 = Vector3.ZERO

var TargetOverwritten : bool = false
var TargetOverride : Vector3 = Vector3.ZERO

var LastTargetPosition : Vector3 = Vector3.ZERO


func _ready():
	CurrentHealth = MaxHealth

## Used via signal from damageable object, to subtract health and handle death events.
func OnDamaged(hitLocation : Vector3, force : Vector3, AggressorBodyNode : Node3D):
	CurrentTarget = AggressorBodyNode
	CurrentHealth -= DamagePerShot
	if (CurrentHealth <= 0):
		OnDeath(hitLocation, force)

## Adds a ragdoll to the current location, poses all it's bones to the correct poses
## imparts the current velocity to the body, and then finds the nearest bone to the
## last shot location, and imparts the impact velocity to that loation.
func OnDeath(hitLocation : Vector3, force : Vector3):
	var newRagdoll : Node3D = RagdollScene.instantiate() as Node3D
	get_parent().add_child(newRagdoll)
	var foundSkeleton : Skeleton3D = RetrieveSkeleton(newRagdoll)
	
	if (foundSkeleton == null):
		printerr("Could not find skeleton 3D in ragdoll scene.")
		return
	
	newRagdoll.global_position = BaseSkeleton.global_position
	newRagdoll.global_rotation = BaseSkeleton.global_rotation
	
	foundSkeleton.global_position = BaseSkeleton.global_position
	foundSkeleton.global_rotation = BaseSkeleton.global_rotation
	
	for i in foundSkeleton.get_bone_count():
		foundSkeleton.set_bone_pose_position(i, BaseSkeleton.get_bone_pose_position(i));
		foundSkeleton.set_bone_pose_rotation(i, BaseSkeleton.get_bone_pose_rotation(i));
	
	foundSkeleton.physical_bones_start_simulation()
	
	var closestBone : PhysicalBone3D = null
	var closestDistance : float = INF
	
	for child in foundSkeleton.get_children():
		if (child is PhysicalBone3D):
			child.apply_impulse(NavigationAgent.linear_velocity)
			var thisDistance : float = hitLocation.distance_to(child.global_position)
			if (thisDistance < closestDistance):
				closestDistance = thisDistance
				closestBone = child
	
	if (closestBone != null):
		closestBone.apply_impulse(force, hitLocation)
	
	queue_free()

## Recursively goes through the node and all it's children searching for the first skeleton3D it finds.
func RetrieveSkeleton(curnode : Node) -> Skeleton3D:
	if (curnode is Skeleton3D):
		return curnode as Skeleton3D
	else:
		for child in curnode.get_children():
			var foundSkeleton : Skeleton3D = RetrieveSkeleton(child)
			if (foundSkeleton != null):
				return foundSkeleton
	
	return null

## Handles snapping to navmesh
func PlaceOnMesh():
	WanderingPosition = global_position
	NavigationAgent.SetNewTarget(global_position)
	
	global_position = NavigationAgent.TargetPosition

## Sets the node target to chase, this is overwritten by the pathing target, unless the override targetted pathing is true.
func SetNodeTarget(newTarget : Node3D, overrideTargettedPathing : bool = false):
	if TargetOverwritten and overrideTargettedPathing:
		TargetOverwritten = false
	
	CurrentTarget = newTarget

## Sets the primary target to move too, this is overriding current target, if the overrideAggro option is set to true.
func SetPathingTarget(targetPosition : Vector3, overrideAggro : bool = false):
	if CurrentTarget != null and !overrideAggro:
		return
	
	TargetOverride = targetPosition
	TargetOverwritten = true

func _process(delta):
	
	
	# Handle pathing override (Later will be used for in combat pathing, and cinematic overrides)
	if TargetOverwritten:
		if NavigationAgent.TargetPosition != TargetOverride:
			NavigationAgent.SetNewTarget(TargetOverride)
		elif NavigationAgent.IsTargetReached():
			if AllowMovementOfWanderCenter:
				WanderingPosition = TargetOverride
			
			TargetOverwritten = false
		
		
		return
	# If that is not present use the current target node if it is present, simply chasing.
	elif CurrentTarget != null:
		if LastTargetPosition.distance_to(CurrentTarget.global_position) > TargetMovementBias:
			LastTargetPosition = CurrentTarget.global_position
			NavigationAgent.SetNewTarget(LastTargetPosition)
		
		
		return
	
	# If neither are available use basic wandering code.
	if NavigationAgent.IsTargetReached():
		SetWanderPosition()

## Select direction randomly, then normalize and set the scale to a float between 0 and WanderRadius.
func SetWanderPosition():
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var wanderDir : Vector3 = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized() * rng.randf() * WanderRadius
	
	NavigationAgent.SetNewTarget(WanderingPosition + wanderDir)
