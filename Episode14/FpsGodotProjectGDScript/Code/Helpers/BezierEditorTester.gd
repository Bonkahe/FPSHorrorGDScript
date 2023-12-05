@tool
extends Node


@export var TargetNode: Node3D;
@export var TargetControlNode: Node3D;
@export var OriginNode: Node3D;
@export var OriginControlNode: Node3D;
@export_range(0,1) var CurrentLerp: float;
@export var UpdateRate: float;

var CurrentUpdateRate: float = 0;

func _process(delta):
	if (TargetNode != null and TargetControlNode != null and OriginNode != null and OriginControlNode != null):
		CurrentUpdateRate += delta;
		if (CurrentUpdateRate >= UpdateRate):
			CurrentUpdateRate -= UpdateRate;
			DrawDebugLine(UpdateRate);

func DrawDebugLine(duration: float):
	DebugExtensions.DebugBezierCurve(self, TargetNode.global_position, TargetControlNode.global_position, OriginNode.global_position, OriginControlNode.global_position, Color(1,1,1), duration);
	
	DebugExtensions.DrawPoint(self, TargetNode.global_position, duration, Color(0,1,0));
	DebugExtensions.DrawPoint(self, TargetControlNode.global_position, duration, Color(0,1,0));
	DebugExtensions.DrawPoint(self, OriginNode.global_position, duration, Color(0,1,0));
	DebugExtensions.DrawPoint(self, OriginControlNode.global_position, duration, Color(0,1,0));
	
	DebugExtensions.BuildDebugLine(self, TargetNode.global_position, TargetControlNode.global_position, duration, Color(0,1,0));
	DebugExtensions.BuildDebugLine(self, TargetControlNode.global_position, OriginControlNode.global_position, duration, Color(0,1,0));
	DebugExtensions.BuildDebugLine(self, OriginControlNode.global_position, OriginNode.global_position, duration, Color(0,1,0));
	
	var A:Vector3 = OriginNode.global_position.lerp(OriginControlNode.global_position, CurrentLerp);
	var B:Vector3 = OriginControlNode.global_position.lerp(TargetControlNode.global_position, CurrentLerp);
	var C:Vector3 = TargetControlNode.global_position.lerp(TargetNode.global_position, CurrentLerp);
	
	var D:Vector3 = A.lerp(B, CurrentLerp);
	var E:Vector3 = B.lerp(C, CurrentLerp);
	
	var F:Vector3 = D.lerp(E, CurrentLerp);
	
	DebugExtensions.BuildDebugLine(self, A, B, duration, Color(0,0,1));
	DebugExtensions.BuildDebugLine(self, B, C, duration, Color(0,0,1));
	
	DebugExtensions.DrawPoint(self, A, duration, Color(0,0,1));
	DebugExtensions.DrawPoint(self, B, duration, Color(0,0,1));
	DebugExtensions.DrawPoint(self, C, duration, Color(0,0,1));
	
	DebugExtensions.BuildDebugLine(self, D, E, duration, Color(1,0,0));
	
	DebugExtensions.DrawPoint(self, D, duration, Color(1,0,0));
	DebugExtensions.DrawPoint(self, E, duration, Color(1,0,0));
	
	DebugExtensions.DrawPoint(self, F, duration, Color(1,1,1));
	
