class_name BezierCurve

@export var TargetLocation: Vector3;
@export var TargetLocationControl: Vector3;
@export var TargetHitNormal: Vector3;
@export var OriginLocation: Vector3;
@export var OriginLocationControl: Vector3;
@export var OriginHitNormal: Vector3;
@export var HitSurface: bool;

func Lerp(t:float):
	return DebugExtensions.GetBezierCurvePosition(TargetLocation, TargetLocationControl, OriginLocation, OriginLocationControl, t);
