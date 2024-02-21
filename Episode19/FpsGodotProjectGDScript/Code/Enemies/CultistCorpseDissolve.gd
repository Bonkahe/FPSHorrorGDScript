extends Node

@export var MaxRandomDelay : float = 2.0
@export var DissolveDuration : float = 3.0
@export var DissolvedMeshes : Array[MeshInstance3D] = []
@export var DissolveParticles : PackedScene
@export var DissolveSpawnPoints : Array[Node3D] = []

var fadeDelay : float = 0.0
var fadeCurrent : float = 0.0
var spawnedParticles : bool = false

var spawnedParticlesCache : Array[GPUParticles3D] = []


func _ready():
	var rng = RandomNumberGenerator.new()
	fadeDelay = rng.randf_range(0, MaxRandomDelay)


func _process(delta):
	if (fadeDelay > 0):
		fadeDelay -= delta
	else:
		if (!spawnedParticles):
			spawnedParticles = true
			
			for point in DissolveSpawnPoints:
				var particles : GPUParticles3D = DissolveParticles.instantiate() as GPUParticles3D
				point.add_child(particles)
				particles.global_position = point.global_position
				particles.global_rotation = point.global_rotation
				particles.emitting = true
				particles.restart()
				spawnedParticlesCache.append(particles)
				
				var time = (particles.lifetime * 2.0) / particles.speed_scale
				get_tree().create_timer(time).timeout.connect(particles.queue_free.bind())
		
		fadeCurrent += delta / DissolveDuration
		var currentMappedFade : float = remap(fadeCurrent, 0.0, 1.0, -0.1, 1.1)
		for mesh in DissolvedMeshes:
			mesh.set_instance_shader_parameter("DissolveWeight", currentMappedFade)
		
		if (fadeCurrent >= 1.0):
			for particles in spawnedParticlesCache:
				if (is_instance_valid(particles)):
					var position : Vector3 = particles.global_position
					var rotation : Vector3 = particles.global_rotation
					
					particles.get_parent().remove_child(particles)
					get_parent().add_child(particles)
					
					particles.global_position = position
					particles.global_rotation = rotation
			queue_free()
