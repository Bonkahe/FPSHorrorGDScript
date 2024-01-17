extends Node

class_name DamageableObject

signal OnDamage(hitLocation : Vector3, force : Vector3, AggressorBodyNode : Node3D)
@export var ImpactEffect: PackedScene;

func HitObject(hitlocation: Vector3, force: Vector3, AggressorBodyNode : Node3D):
	emit_signal("OnDamage", hitlocation, force, AggressorBodyNode)
