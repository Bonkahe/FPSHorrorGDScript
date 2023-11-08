using Godot;
using System;
using System.Security.Cryptography;


public class BezierCurve
{
    public Vector3 TargetLocation { get; set; }
    public Vector3 TargetLocationControl { get; set; }
    public Vector3 TargetHitNormal { get; set; }
    public Vector3 OriginLocation { get; set; }
    public Vector3 OriginLocationControl { get; set; }
    public Vector3 OriginHitNormal { get; set; }
    public bool HitSurface { get; set; }

    public Vector3 Lerp(float t)
    {
        return DebugExtensions.GetBezierCurvePosition(TargetLocation, TargetLocationControl, OriginLocation, OriginLocationControl, t);
    }
}

[GlobalClass]
public partial class Limb : Node
{
    [Export] public Node3D LimbIKContainer { get; set; }
    [Export] public Skeleton3D Skeleton { get; set; }
    [Export] public SkeletonIK3D LimbIKSolver { get; set; }

    [Export] public Vector3 LimbIKMagnetOffset { get; set; }
    [Export] public Vector3 LimbIKTargetOffset { get; set; }
    [Export] public float AllowedIKInaccuracies { get; set; } = 0.2f;

    [Export(PropertyHint.Range, "0,1")] public float EnemyBodyOriginVelocityBias { get; set; } = 0.8f;
    [Export(PropertyHint.Range, "0,1")] public float EnemyBodyDesiredVelocityBias { get; set; } = 0.8f;



    [Export] public LimbReference ThisLimb { get; set; }
    [Export] public float TargetPointOffsetMinimumDistance { get; set; }
    [Export] public float ControlPointOffsetMinimumDistance { get; set; }
    [Export] public float ControlPointOffset { get; set; }
    [Export] public float BlendSpeed { get; set; } = 3;
    [Export] public float MinimumMovementDistance { get; set; } = 0.5f;

    public Vector3 CurrentTargetLocation;
    public LimbPlacementController Controller;

    private float CurrentLerpValue;
    public bool CurrentlyTraveling;
    private BezierCurve CurrentCurve;

    private int IKBoneTipID;

    public override void _Ready()
	{
        CurrentCurve = GetInitialCurve();
        CurrentTargetLocation = CurrentCurve.TargetLocation;

        SetIKTargets();
        LimbIKSolver.Start();
        IKBoneTipID = Skeleton.FindBone(LimbIKSolver.TipBone);
    }

    public override void _PhysicsProcess(double delta)
    {
        //this.DrawPoint(CurrentTargetLocation, (float)delta, CurrentlyTraveling ? new Color(0, 1, 0) : new Color(1, 0, 0), 0.3f);
        if (CurrentlyTraveling)
        {
            CurrentLerpValue = Mathf.Clamp(CurrentLerpValue + (BlendSpeed * (float)delta), 0, 1);
            CurrentTargetLocation = AdjustTargetPoint(CurrentCurve.Lerp(CurrentLerpValue));
            if (CurrentLerpValue == 1)
            {
                CurrentLerpValue = 0;
                CurrentlyTraveling = false;
            }
        }

        SetIKTargets();
    }

    public void SetIKTargets()
    {
        LimbIKSolver.Magnet = LimbIKContainer.GlobalPosition.Lerp(Controller.EnemyBody.GlobalPosition, 0.5f) + (Controller.ChestTargetContainer.GlobalTransform.Basis * LimbIKMagnetOffset);
        LimbIKSolver.Magnet = Skeleton.ToLocal(LimbIKSolver.Magnet);

        LimbIKContainer.GlobalPosition = CurrentTargetLocation + (Controller.ChestTargetContainer.GlobalTransform.Basis * LimbIKTargetOffset);

        Vector3 newLookatPos = LimbIKContainer.GlobalPosition + (LimbIKContainer.GlobalPosition - Controller.EnemyBody.GlobalPosition).Normalized();
        newLookatPos.Y = LimbIKContainer.GlobalPosition.Y;

        Vector3 normal = CurrentlyTraveling ? CurrentCurve.OriginHitNormal.Lerp(CurrentCurve.TargetHitNormal, CurrentLerpValue) : CurrentCurve.TargetHitNormal;
        float currentDifference = Mathf.Abs((newLookatPos - LimbIKContainer.GlobalPosition).Dot(normal));

        LimbIKContainer.LookAt(newLookatPos,
            currentDifference > 0.99f || normal.IsZeroApprox() ? Controller.ChestTargetContainer.GlobalTransform.Basis.Z : normal);
    }

    public void InitializeStep()
    {
        BezierCurve newcurve = GetNewCurve();
        if (newcurve != CurrentCurve)
        {
            //this.DebugBezierCurve(newcurve.TargetLocation, newcurve.TargetLocationControl, newcurve.OriginLocation, newcurve.OriginLocationControl, new Color(0, 1, 0), 0.3f);
            CurrentLerpValue = 0;
            CurrentlyTraveling = true;

            if (CurrentCurve.HitSurface && Controller.EnemyBody.DesiredVelocity != Vector3.Zero)
            {
                if (ThisLimb == LimbReference.LeftFoot || ThisLimb == LimbReference.RightFoot)
                {
                    Vector3 footVector = (LimbIKContainer.GlobalPosition - newcurve.TargetLocation).Lerp(Controller.EnemyBody.DesiredVelocity, EnemyBodyDesiredVelocityBias);
                    Controller.KickOffVelocity(footVector.Normalized(), LimbIKContainer.GlobalPosition.Lerp(Controller.EnemyBody.GlobalPosition, EnemyBodyOriginVelocityBias));
                }
                else
                {
                    Vector3 handVector = (newcurve.TargetLocation - LimbIKContainer.GlobalPosition).Lerp(Controller.EnemyBody.DesiredVelocity, EnemyBodyDesiredVelocityBias);
                    Controller.KickOffVelocity(handVector.Normalized(), LimbIKContainer.GlobalPosition.Lerp(Controller.EnemyBody.GlobalPosition, EnemyBodyOriginVelocityBias));
                }

                
            }

            CurrentCurve = newcurve;
        }
    }

    private BezierCurve GetInitialCurve()
    {
        Vector3 targetPosition = Controller.GetTargetLimbPosition(ThisLimb, out bool hitSurface, out Vector3 hitNormal);

        return new BezierCurve()
        {
            OriginLocation = targetPosition,
            OriginLocationControl = targetPosition + hitNormal * ControlPointOffset,
            TargetLocation = targetPosition,
            TargetLocationControl = targetPosition + hitNormal * ControlPointOffset,
            HitSurface = hitSurface
        };
    }

    private BezierCurve GetNewCurve()
    {
        Vector3 targetPosition = Controller.GetTargetLimbPosition(ThisLimb, out bool hitSurface, out Vector3 hitNormal);

        bool TofarFromTarget = Skeleton.ToGlobal(Skeleton.GetBoneGlobalPose(IKBoneTipID).Origin).DistanceTo(CurrentTargetLocation) > AllowedIKInaccuracies;

        if (targetPosition.DistanceTo(CurrentTargetLocation) > MinimumMovementDistance || TofarFromTarget)
        {
            if (TofarFromTarget)
            {
                CurrentTargetLocation = Skeleton.ToGlobal(Skeleton.GetBoneGlobalPose(IKBoneTipID).Origin);
                CurrentCurve.HitSurface = false; //We are moving in mid air.
            }

            return AdjustControlPoints(new BezierCurve()
            {
                OriginLocation = CurrentTargetLocation,
                OriginLocationControl = CurrentTargetLocation + (CurrentCurve.TargetLocationControl - CurrentCurve.TargetLocation),
                TargetLocation = targetPosition,
                TargetLocationControl = targetPosition + hitNormal * ControlPointOffset,
                HitSurface = hitSurface,
                OriginHitNormal = CurrentCurve.TargetHitNormal,
                TargetHitNormal = hitNormal,
            });
        }
        else
        {
            return CurrentCurve;
        }
    }

    public BezierCurve AdjustControlPoints(BezierCurve newCurve)
    {
        Vector3 offsettedWorldBodyPosition = Controller.EnemyBody.GlobalPosition;
        offsettedWorldBodyPosition.Y = newCurve.TargetLocationControl.Y;

        if (newCurve.TargetLocationControl.DistanceTo(offsettedWorldBodyPosition) < ControlPointOffsetMinimumDistance)
        {
            newCurve.TargetLocationControl = offsettedWorldBodyPosition + (newCurve.TargetLocationControl - offsettedWorldBodyPosition).Normalized() * ControlPointOffsetMinimumDistance;
        }

        if (CurrentCurve.HitSurface)
        {
            newCurve.OriginLocationControl = newCurve.OriginLocation + ((newCurve.OriginLocation - newCurve.TargetLocationControl).Normalized() * ControlPointOffset);
            //this.DebugBezierCurve(newCurve.TargetLocation, newCurve.TargetLocationControl, newCurve.OriginLocation, newCurve.OriginLocationControl, new Color(1, 0, 0), 1f);
        }
        else
        {
            if (newCurve.OriginLocationControl.DistanceTo(offsettedWorldBodyPosition) < ControlPointOffsetMinimumDistance)
            {
                newCurve.OriginLocationControl = offsettedWorldBodyPosition + (newCurve.OriginLocationControl - offsettedWorldBodyPosition).Normalized() * ControlPointOffsetMinimumDistance;
                //this.DebugBezierCurve(newCurve.TargetLocation, newCurve.TargetLocationControl, newCurve.OriginLocation, newCurve.OriginLocationControl, new Color(0, 0, 1), 0.3f);
            }
        }

        return newCurve;
    }


    public Vector3 AdjustTargetPoint(Vector3 TargetPoint)
    {
        Vector3 offsettedWorldBodyPosition = Controller.ChestTargetContainer.ToLocal(TargetPoint);

        if (ThisLimb == LimbReference.LeftHand || ThisLimb == LimbReference.LeftFoot)
        {
            offsettedWorldBodyPosition.X = Mathf.Min(offsettedWorldBodyPosition.X, -TargetPointOffsetMinimumDistance);
        }
        else
        {
            offsettedWorldBodyPosition.X = Mathf.Max(offsettedWorldBodyPosition.X, TargetPointOffsetMinimumDistance);
        }

        TargetPoint = Controller.ChestTargetContainer.ToGlobal(offsettedWorldBodyPosition);
        return TargetPoint;
    }
}
