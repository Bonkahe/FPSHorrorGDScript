using Godot;
using System;

public partial class DamageableObject : Node
{
    [Export] public PackedScene ImpactEffect { get; set; }

    public virtual void HitObject(Vector3 hitLocation, Vector3 force)
    {

    }
}
