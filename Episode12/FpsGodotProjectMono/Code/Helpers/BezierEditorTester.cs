using Godot;
using System;

[Tool]
public partial class BezierEditorTester : Node
{
	[Export] public Node3D TargetNode { get; set; }
    [Export] public Node3D TargetControlNode { get; set; }
    [Export] public Node3D OriginNode { get; set; }
    [Export] public Node3D OriginControlNode { get; set; }
    [Export(PropertyHint.Range,"0,1")] public float CurrentLerp { get; set; }
    [Export] public float UpdateRate { get; set; } = 0.2f;
    private float CurrentUpdateRate;
    public override void _PhysicsProcess(double delta)
	{
		if (TargetNode != null && TargetControlNode != null && OriginNode != null && OriginControlNode != null)
        {
            CurrentUpdateRate += (float)delta;
            if (CurrentUpdateRate >= UpdateRate)
            {
                CurrentUpdateRate -= UpdateRate;
                DrawDebugLine(UpdateRate);
            }
        }
	}

    public void DrawDebugLine(float duration)
    {
        this.DebugBezierCurve(TargetNode.GlobalPosition, TargetControlNode.GlobalPosition, OriginNode.GlobalPosition, OriginControlNode.GlobalPosition, new Color(1, 1, 1), duration);

        this.DrawPoint(TargetNode.GlobalPosition, duration, new Color(0, 1, 0));
        this.DrawPoint(TargetControlNode.GlobalPosition, duration, new Color(0, 1, 0));
        this.DrawPoint(OriginNode.GlobalPosition, duration, new Color(0, 1, 0));
        this.DrawPoint(OriginControlNode.GlobalPosition, duration, new Color(0, 1, 0));

        this.BuildDebugLine(TargetNode.GlobalPosition, TargetControlNode.GlobalPosition, duration, new Color(0, 1, 0));
        this.BuildDebugLine(TargetControlNode.GlobalPosition, OriginControlNode.GlobalPosition, duration, new Color(0, 1, 0));
        this.BuildDebugLine(OriginControlNode.GlobalPosition, OriginNode.GlobalPosition, duration, new Color(0, 1, 0));

        Vector3 A = OriginNode.GlobalPosition.Lerp(OriginControlNode.GlobalPosition, CurrentLerp);
        Vector3 B = OriginControlNode.GlobalPosition.Lerp(TargetControlNode.GlobalPosition, CurrentLerp);
        Vector3 C = TargetControlNode.GlobalPosition.Lerp(TargetNode.GlobalPosition, CurrentLerp);

        Vector3 D = A.Lerp(B, CurrentLerp);
        Vector3 E = B.Lerp(C, CurrentLerp);

        Vector3 F = D.Lerp(E, CurrentLerp);

        this.BuildDebugLine(A, B, duration, new Color(0, 0, 1));
        this.BuildDebugLine(B, C, duration, new Color(0, 0, 1));

        this.DrawPoint(A, duration, new Color(0, 0, 1));
        this.DrawPoint(B, duration, new Color(0, 0, 1));
        this.DrawPoint(C, duration, new Color(0, 0, 1));

        this.BuildDebugLine(D, E, duration, new Color(1, 0, 0));

        this.DrawPoint(D, duration, new Color(1, 0, 0));
        this.DrawPoint(E, duration, new Color(1, 0, 0));

        this.DrawPoint(F, duration, new Color(1, 1, 1));
    }
}
