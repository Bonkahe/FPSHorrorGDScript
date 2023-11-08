using Godot;
using System;

public partial class SetTarget : Node
{
	[Export] public Node3D target { get; set; }
	[Export] public BasicEnemyNavigationAgent agent { get; set; } 

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		agent.PlayerTarget = target;

    }

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}
}
