extends RigidBody3D
class_name BasicEnemyNavigationAgent

@export var MaximumVelocity: float;
@export var VelocityChange: float;
@export var PlayerTarget: Node3D;
@export var NavigationAgent: NavigationAgent3D;

var lastPlayerPosition: Vector3;
var lastEnemyPosition: Vector3;

func _physics_process(delta):
	if (lastPlayerPosition.distance_to(PlayerTarget.global_position) > 0.5 or lastEnemyPosition.distance_to(global_position) > 0.5):
		lastPlayerPosition = PlayerTarget.global_position;
		lastEnemyPosition = global_position;
		NavigationAgent.target_position = lastPlayerPosition;
	
	if (NavigationAgent.is_target_reached()):
		constant_force = Vector3.ZERO;
		return;
	
	var targetVelocity = (NavigationAgent.get_next_path_position() - global_position).normalized() * MaximumVelocity;
	targetVelocity = (targetVelocity - linear_velocity) * (VelocityChange * delta);
	
	constant_force = targetVelocity;
