using Godot;
using System;

[GlobalClass]
public partial class FlashlightPoint : Marker3D
{
	public enum Priority { none, low, medium, high}
	[Export] public Priority priority = Priority.none;
	public bool HasBeenTargeted { get; set; }

}
