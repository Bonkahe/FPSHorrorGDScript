extends Node
class_name Limb

@export var ThisLimb: LimbReference.LimbEnum;
@export var ControlPointOffset: float;
@export var BlendSpeed: float = 3;
@export var MinimumMovementDistance: float = 0.5;

var CurrentTargetLocation: Vector3;
var Controller: LimbPlacementController;

var CurrentLerpValue: float;
var CurrentlyTraveling: bool;
var CurrentCurve: BezierCurve;


func _ready():
	CurrentCurve = GetInitialCurve();
	CurrentTargetLocation = CurrentCurve.TargetLocation;

func _physics_process(delta):
	DebugExtensions.DrawPoint(self, CurrentTargetLocation, delta, Color(0,1,0) if CurrentlyTraveling else Color(1,0,0), 0.3);
	if (CurrentlyTraveling):
		CurrentLerpValue = clamp(CurrentLerpValue + (BlendSpeed * delta), 0, 1);
		CurrentTargetLocation = CurrentCurve.Lerp(CurrentLerpValue);
		if (CurrentLerpValue == 1):
			CurrentLerpValue = 0;
			CurrentlyTraveling = false;


func InitializeStep():
	var newcurve = GetNewCurve();
	if (newcurve != null):
		CurrentLerpValue = 0;
		CurrentlyTraveling = true;
		CurrentCurve = newcurve;


func GetInitialCurve():
	var targetData = Controller.GetTargetLimbPosition(ThisLimb);
	var newCurve = BezierCurve.new();
	newCurve.OriginLocation = targetData.Position;
	newCurve.OriginLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
	newCurve.TargetLocation = targetData.Position;
	newCurve.TargetLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
	newCurve.HitSurface = targetData.HitSurface;
	return newCurve;

func GetNewCurve():
	var targetData = Controller.GetTargetLimbPosition(ThisLimb);
	if (CurrentTargetLocation.distance_to(targetData.Position) > MinimumMovementDistance):
		var newCurve = BezierCurve.new();
		newCurve.OriginLocation = CurrentTargetLocation;
		newCurve.OriginLocationControl = CurrentTargetLocation + (CurrentCurve.TargetLocationControl - CurrentCurve.TargetLocation);
		newCurve.TargetLocation = targetData.Position;
		newCurve.TargetLocationControl = targetData.Position + targetData.HitNormal * ControlPointOffset;
		newCurve.HitSurface = targetData.HitSurface;
		return newCurve;
	else:
		return null;





