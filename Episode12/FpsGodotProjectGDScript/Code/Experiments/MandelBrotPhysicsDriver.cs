using Godot;
using System;

public partial class MandelBrotPhysicsDriver : RigidBody3D
{
	[Export] public Node3D player { get; set; }
	[Export] public Node3D MandelContainer { get; set; }
	[Export] public MeshInstance3D MandelBrotMesh { get; set; }
	[Export] public string MandelTimeName { get; set; }
    [Export] public string MandelEmissionName { get; set; }
    [Export] public string MandelStepsName { get; set; }
    [Export] public string MandelScaleName { get; set; }

    [Export] public float MaximumMandelRotationSpeed { get; set; }
    [Export] public float MinimumMandelRotationSpeed { get; set; }

    [Export] public float MaximumMandelTime { get; set; }
    [Export] public float MinimumMandelTime { get; set; }
    [Export] public float MaximumMandelEmission { get; set; }
    [Export] public float MinimumMandelEmission { get; set; }
    [Export] public float MaximumMandelSteps { get; set; }
    [Export] public float MinimumMandelSteps { get; set; }
    [Export] public float MaximumMandelScale { get; set; }
    [Export] public float MinimumMandelScale { get; set; }

    [Export] public float MaximumTargetDistance { get; set; }
	[Export] public float MinimumTargetDistance { get; set; }
    [Export] public float MaximumTargetVelocity { get; set; }
    [Export] public float MinimumTargetVelocity { get; set; }

    //[Export] public float maxVelocityRange { get; set; }
    //[Export] public float maxTimeStepSpeed { get; set; }
    //[Export] public float maxEmissionRange { get; set; }

    private float currentTime;
	public override void _PhysicsProcess(double delta)
	{
		float currentDistance = player.GlobalPosition.DistanceTo(MandelContainer.GlobalPosition);

        float currentMandelTime = Mathf.Remap(currentDistance, MinimumTargetDistance, MaximumTargetDistance, MaximumMandelTime, MinimumMandelTime);
        currentMandelTime = Mathf.Clamp(currentMandelTime, MinimumMandelTime, MaximumMandelTime);

        float currentMandelEmission = Mathf.Remap(currentDistance, MinimumTargetDistance, MaximumTargetDistance, MaximumMandelEmission, MinimumMandelEmission);
        currentMandelEmission = Mathf.Clamp(currentMandelEmission, MinimumMandelEmission, MaximumMandelEmission);

        float currentMandelSteps = Mathf.Remap(LinearVelocity.Length(), MinimumTargetVelocity, MaximumTargetVelocity, MaximumMandelSteps, MinimumMandelSteps);
        currentMandelSteps = Mathf.Clamp(currentMandelSteps, MinimumMandelSteps, MaximumMandelSteps);

        float currentMandelScale = Mathf.Remap(currentDistance, MinimumTargetDistance, MaximumTargetDistance, MinimumMandelScale, MaximumMandelScale);
        currentMandelScale = Mathf.Clamp(currentMandelScale, MinimumMandelScale, MaximumMandelScale);

        MandelBrotMesh.SetInstanceShaderParameter(MandelTimeName, currentMandelTime);
        MandelBrotMesh.SetInstanceShaderParameter(MandelEmissionName, currentMandelEmission);
        MandelBrotMesh.SetInstanceShaderParameter(MandelStepsName, currentMandelSteps);
        MandelBrotMesh.SetInstanceShaderParameter(MandelScaleName, currentMandelScale);
        

        float currentMandelRotationSpeed = Mathf.Remap(LinearVelocity.Length() + AngularVelocity.Length(), MinimumTargetVelocity, MaximumTargetVelocity, MaximumMandelRotationSpeed, MinimumMandelRotationSpeed);
        currentMandelRotationSpeed = Mathf.Clamp(currentMandelRotationSpeed, MinimumMandelRotationSpeed, MaximumMandelRotationSpeed);

        if (currentMandelRotationSpeed > 0)
        {
            Vector3 originalRotation = MandelContainer.Rotation;
            MandelContainer.LookAt(player.GlobalPosition, Vector3.Up);
            MandelContainer.Rotation = new Vector3(
                Mathf.LerpAngle(originalRotation.X, MandelContainer.Rotation.X, (float)delta * currentMandelRotationSpeed),
                Mathf.LerpAngle(originalRotation.Y, MandelContainer.Rotation.Y, (float)delta * currentMandelRotationSpeed),
                Mathf.LerpAngle(originalRotation.Z, MandelContainer.Rotation.Z, (float)delta * currentMandelRotationSpeed));
        }
        //float currentVelocityRange = (LinearVelocity.Length() / maxVelocityRange);
        //currentTime += (float)delta * currentVelocityRange * maxTimeStepSpeed;
        //MandelBrotMesh.SetInstanceShaderParameter(MandelTimeName, currentTime);
        //MandelBrotMesh.SetInstanceShaderParameter(MandelEmissionName, maxEmissionRange * currentVelocityRange);
    }
}
