extends Node

class_name WeaponEffectsController

@export var BarrelEnd: Node3D;
@export var BarrelRayCast: RayCast3D;
@export var MuzzleFlash: PackedScene;
@export var ImpactEffect: PackedScene;

@export var ImpactForce: float = 20;

var hasRoundAvailable: bool = false;
var currentRoundCount: int;


func _ready():
	Reload();


func Reload():
	currentRoundCount = 6;
	hasRoundAvailable = true;

func FireRevolver():
	var newMuzzleFlash = MuzzleFlash.instantiate() as Node3D;
	BarrelEnd.add_child(newMuzzleFlash);
	newMuzzleFlash.global_position = BarrelEnd.global_position;
	newMuzzleFlash.global_rotation = BarrelEnd.global_rotation;
	
	currentRoundCount -= 1;
	hasRoundAvailable = currentRoundCount > 0;
	
	if (BarrelRayCast.is_colliding()):
		var hitLocation = BarrelRayCast.get_collision_point();
		var damageableEffect = ImpactEffect;
		var impactedTarget = BarrelRayCast.get_collider() as Node3D;
		
		if (impactedTarget is RigidBody3D):
			impactedTarget.apply_impulse(-BarrelRayCast.global_transform.basis.z * ImpactForce, hitLocation - impactedTarget.global_position);
		
		if (impactedTarget.has_node("Damageable")):
			var damageable = impactedTarget.get_node("Damageable") as DamageableObject;
			if (damageable.ImpactEffect != null):
				damageableEffect = damageable.ImpactEffect;
			damageable.HitObject(hitLocation, -BarrelRayCast.global_transform.basis.z * ImpactForce);
		
		var newImpactEffect = damageableEffect.instantiate() as Node3D;
		add_child(newImpactEffect);
		newImpactEffect.global_position = hitLocation;
		
		var lookAtPoint = BarrelRayCast.get_collision_normal();
		
		if (lookAtPoint != Vector3.ZERO):
			newImpactEffect.look_at(newImpactEffect.global_position + lookAtPoint, Vector3.BACK if abs(lookAtPoint.y) > 0.99 else Vector3.UP);

