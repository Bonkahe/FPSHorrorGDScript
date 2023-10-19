extends RigidBody3D
class_name BasicEnemyNavigationAgent

@export var MaximumVelocity: float;
@export var VelocityChange: float;
@export var PlayerTarget: Node3D;
@export var NavigationAgent: NavigationAgent3D;

var DesiredVelocity: Vector3;

var lastPlayerPosition: Vector3;

func _physics_process(delta):
	if (PlayerTarget == null):
		return;
	
	if (lastPlayerPosition.distance_to(PlayerTarget.global_position) > 1):
		lastPlayerPosition = PlayerTarget.global_position;
		NavigationAgent.target_position = lastPlayerPosition;
	
	if (NavigationAgent.is_target_reached()):
		DesiredVelocity = Vector3.ZERO;
		return;
	
	DesiredVelocity = (NavigationAgent.get_next_path_position() - global_position).normalized() * MaximumVelocity;
