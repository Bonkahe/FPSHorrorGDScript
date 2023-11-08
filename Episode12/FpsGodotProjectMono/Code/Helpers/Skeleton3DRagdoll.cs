using Godot;
using System;

public partial class Skeleton3DRagdoll : Skeleton3D
{
	public override void _Ready()
	{
        PhysicalBonesStartSimulation();
	}
}
