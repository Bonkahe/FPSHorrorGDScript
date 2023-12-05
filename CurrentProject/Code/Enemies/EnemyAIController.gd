extends Node3D
class_name EnemyAIController

@export_category("Wandering Settings")
# If true, allows the center of the wander radius to update whenever moving by targetted pathing override.
@export var AllowMovementOfWanderCenter : bool = false
@export var WanderRadius : float = 20.0

@export_category("Target Tracking Settings")
# Distance moved by the target requiring pathing update
@export var TargetMovementBias : float = 1.0
@export var NavigationAgent : NavigationAgent3D
@export var CurrentTarget : Node3D

var WanderingPosition : Vector3 = Vector3.ZERO

var TargetOverwritten : bool = false
var TargetOverride : Vector3 = Vector3.ZERO

var LastTargetPosition : Vector3 = Vector3.ZERO


# Handles snapping to navmesh
func PlaceOnMesh():
	WanderingPosition = global_position
	NavigationAgent.target_position = global_position
	
	global_position = NavigationAgent.get_final_position()

# Sets the node target to chase, this is overwritten by the pathing target, unless the override targetted pathing is true.
func SetNodeTarget(newTarget : Node3D, overrideTargettedPathing : bool = false):
	if TargetOverwritten and overrideTargettedPathing:
		TargetOverwritten = false
	
	CurrentTarget = newTarget

# Sets the primary target to move too, this is overriding current target, if the overrideAggro option is set to true.
func SetPathingTarget(targetPosition : Vector3, overrideAggro : bool = false):
	if CurrentTarget != null and !overrideAggro:
		return
	
	TargetOverride = targetPosition
	TargetOverwritten = true

func _process(delta):
	# Handle pathing override (Later will be used for in combat pathing, and cinematic overrides)
	if TargetOverwritten:
		if NavigationAgent.target_position != TargetOverride:
			NavigationAgent.target_position = TargetOverride
		elif NavigationAgent.is_navigation_finished():
			if AllowMovementOfWanderCenter:
				WanderingPosition = TargetOverride
			
			TargetOverwritten = false
		
		
		return
	# If that is not present use the current target node if it is present, simply chasing.
	elif CurrentTarget != null:
		if LastTargetPosition.distance_to(CurrentTarget.global_position) > TargetMovementBias:
			LastTargetPosition = CurrentTarget.global_position
			NavigationAgent.target_position = LastTargetPosition
		
		return
	
	# If neither are available use basic wandering code.
	if NavigationAgent.is_navigation_finished():
		SetWanderPosition()

# Select direction randomly, then normalize and set the scale to a float between 0 and WanderRadius.
func SetWanderPosition():
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var wanderDir : Vector3 = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized() * rng.randf() * WanderRadius
	
	NavigationAgent.target_position = WanderingPosition + wanderDir
