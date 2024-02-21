extends Node

class_name PlayerHealthController

signal OnPlayerDeath(CameraLocation : Vector3, CameraRotation : Vector3)

@export var PlayerBody : PlayerBodyController
@export var PlayerCamera : Node3D
@export var DamageEffectMaterial : ShaderMaterial

@export var HealDelay : float = 10.0
@export var HealRate : float = 0.5

@export var FlashFadeRate : float = 2.0
@export var HealthTotal : float = 3.0

var CurrentHealth  : float

var CurrentHealDelay : float = 0.0
var CurrentOverlayWeight : float = 0.0
var CurrentFlashPower : float = 0.0

func _ready():
	CurrentHealth = HealthTotal

func OnDamaged(hitLocation : Vector3, force : Vector3, AggressorBodyNode : Node3D):
	#Subtract the damage but clamp it so it doesn't go below 0.
	CurrentHealth = clamp(CurrentHealth - 1, 0, HealthTotal)
	
	#Handle death later.
	if (CurrentHealth == 0):
		emit_signal("OnPlayerDeath", PlayerCamera.global_position, PlayerCamera.global_rotation)
		DamageEffectMaterial.set_shader_parameter("EffectStrength", 0);
		
		return
	
	#Update heal delay.
	CurrentHealDelay = HealDelay
	CurrentFlashPower = 1
	
	PlayerBody.ImpulseCamera(force, force.length())
	PlayerBody.velocity += force

##Helper function used to get the current desired weight based on the health.
func GetTargetOverlayWeight():
	return remap(CurrentHealth / HealthTotal, 0, 1, 3, 0) + CurrentFlashPower


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Handle healing after a delay
	if (CurrentHealth < HealthTotal):
		if (CurrentHealDelay > 0):
			CurrentHealDelay -= delta
		else:
			CurrentHealth += HealRate * delta
			if (CurrentHealth > HealthTotal):
				CurrentHealth = HealthTotal
	
	CurrentFlashPower = clamp(CurrentFlashPower - delta * FlashFadeRate, 0, 1)
	
	#Retrieve the new target
	var newTargetOverlayWeight : float = GetTargetOverlayWeight();
	
	#If we are at the target make no change
	if (newTargetOverlayWeight == CurrentOverlayWeight):
		return
	
	#If we are below it set it directly for rapid response to hits.
	if (newTargetOverlayWeight > CurrentOverlayWeight):
		CurrentOverlayWeight = newTargetOverlayWeight
	elif (newTargetOverlayWeight < CurrentOverlayWeight): #if it's below fade down to it as a set speed.
		CurrentOverlayWeight -= FlashFadeRate * delta
		if (CurrentOverlayWeight < newTargetOverlayWeight):
			CurrentOverlayWeight = newTargetOverlayWeight
	
	#Whatever the result update the material.
	DamageEffectMaterial.set_shader_parameter("EffectStrength", CurrentOverlayWeight);
