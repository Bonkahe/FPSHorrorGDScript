using Godot;
using System;

public partial class BasicEnemyNavigationAgent : RigidBody3D
{
    [Export] public float MaximumVelocity { get; set; }
    [Export] public float VelocityChange { get; set; }
    [Export] public Node3D PlayerTarget { get; set; }
    [Export] public NavigationAgent3D NavigationAgent { get; set; }

    public Vector3 DesiredVelocity;

    private Vector3 lastPlayerPosition;

    public override void _PhysicsProcess(double delta)
    {
        if (PlayerTarget == null)
        {
            return;
        }

        if (lastPlayerPosition.DistanceTo(PlayerTarget.GlobalPosition) > 1f)
        {
            lastPlayerPosition = PlayerTarget.GlobalPosition;
            NavigationAgent.TargetPosition = lastPlayerPosition;
        }

        if (NavigationAgent.IsTargetReached())
        {
            DesiredVelocity = Vector3.Zero;
            return;
        }

        DesiredVelocity = (NavigationAgent.GetNextPathPosition() - GlobalPosition).Normalized() * MaximumVelocity;
    }
}
