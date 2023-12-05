extends Marker3D

# Used to make sure it is addable via the add node menu in editor.
class_name EnemySpawnPoint

@export var EnemyPackedScene: PackedScene
@export var AutoSetTarget: bool = false
@export var TargetToSet: Node3D

# Executed via signal, primarily from a TriggerVolume Node, discards the Node3D (using "_") so it can be called via bodyentered trigger.
func SpawnInitiated(_collidedBody : Node3D):
	var newEnemy = EnemyPackedScene.instantiate() as EnemyAIController
	get_parent().add_child(newEnemy)
	
	newEnemy.global_position = global_position
	newEnemy.global_rotation = global_rotation
	
	newEnemy.PlaceOnMesh()
	if AutoSetTarget:
		newEnemy.SetNodeTarget(TargetToSet)

