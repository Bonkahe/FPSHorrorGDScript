extends Node3D

@export var target: Node3D;
@export var agent: BasicEnemyNavigationAgent;

# Called when the node enters the scene tree for the first time.
func _ready():
	agent.PlayerTarget = target;

