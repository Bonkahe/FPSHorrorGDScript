extends RigidBody3D
class_name BasicEnemyNavigationAgent

@export var MaximumVelocity: float;
@export var VelocityChange: float;
@export var NavigationAgent: NavigationAgent3D;

var DesiredVelocity: Vector3;


func _physics_process(delta):
	
	if (NavigationAgent.is_target_reached()):
		DesiredVelocity = Vector3.ZERO;
		return;
	
	DesiredVelocity = (NavigationAgent.get_next_path_position() - global_position).normalized() * MaximumVelocity;
