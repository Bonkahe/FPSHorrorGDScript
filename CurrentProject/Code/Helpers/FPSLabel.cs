using Godot;
using System;

public partial class FPSLabel : Label
{

	public override void _PhysicsProcess(double delta)
	{
        Text = Engine.GetFramesPerSecond().ToString();
    }

}
