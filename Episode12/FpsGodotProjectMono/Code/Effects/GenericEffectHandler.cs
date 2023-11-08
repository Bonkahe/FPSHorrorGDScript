using Godot;
using System;

public partial class GenericEffectHandler : Node3D
{
    [Export] public Light3D OptionalLight { get; set; }
    [Export] public float LightDuration { get; set; }

    public override void _Ready()
	{
        double maxDuration = 0;
		foreach (var child in GetChildren())
        {
			if (child is GpuParticles3D gpuParticles)
            {
                maxDuration = Mathf.Max(maxDuration, gpuParticles.Lifetime);
                gpuParticles.Emitting = true;

                continue;
            }

            if (child is CpuParticles2D cpuParticles)
            {
                maxDuration = Mathf.Max(maxDuration, cpuParticles.Lifetime);
                cpuParticles.Emitting = true;

                continue;
            }
        }

        if (OptionalLight != null)
        {
            Tween newTween = CreateTween();
            newTween.TweenProperty(OptionalLight, "light_energy", 0, LightDuration);
            newTween.TweenProperty(OptionalLight, "omni_range", 0, LightDuration);
        }

        SceneTreeTimer timer = GetTree().CreateTimer(maxDuration);
        timer.Connect("timeout", new Callable(this, MethodName.QueueFree));
    }
}
