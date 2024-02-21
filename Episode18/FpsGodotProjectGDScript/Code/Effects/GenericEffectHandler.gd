extends Node3D

@export var OptionalLight: Light3D;
@export var LightDuration: float;

# Called when the node enters the scene tree for the first time.
func _ready():
	var maxDuration:float = 0;
	
	for child in get_children():
		if (child is GPUParticles3D or child is CPUParticles3D):
				maxDuration = max(maxDuration, child.lifetime);
				child.emitting = true;
	
	if (OptionalLight != null):
		var newTween = create_tween();
		newTween.tween_property(OptionalLight, "light_energy", 0, LightDuration);
		newTween.tween_property(OptionalLight, "omni_range", 0, LightDuration);
	
	var timer = get_tree().create_timer(maxDuration);
	timer.connect("timeout", Callable(self, "queue_free"));

