using Godot;
using System;
using System.Linq;

public partial class WeaponEffectsController : Node
{
    [ExportCategory("Shot Functionality")]
    [Export] public Node3D BarrelEnd { get; set; }
    [Export] public RayCast3D BarrelRayCast { get; set; }
    [Export] public PackedScene MuzzleFlash { get; set; }
    [Export] public PackedScene ImpactEffect { get; set; }

    [Export] public float ImpactForce { get; set; } = 20;

    [ExportCategory("Spread")]
    [Export] public FastNoiseLite SpreadNoise { get; set; }

    [Export] public float SpreadPanningSpeed { get; set; } = 10;
    [Export] public float SpreadAimingConeSize { get; set; } = 5;
    [Export] public float SpreadIdleConeSize { get; set; } = 20;

    [Export] public float SpreadBloomPerShot { get; set; } = 5;
    [Export] public float SpreadBloomDecay { get; set; } = 3;

    [Export(PropertyHint.Range, "-1,1")] public float RecoilHorizontalBias { get; set; } = -0.15f;
    [Export(PropertyHint.Range, "0,1")] public float RecoilRotationBias { get; set; } = 0.85f;

    [Export] public float RecoilSize { get; set; } = 15;
    [Export] public float RecoilPanningSpeed { get; set; } = 15;
    [Export] public float RecoilFade { get; set; } = 20;
    [Export] public float RecoilActualBlendSpeed { get; set; } = 10;

    [ExportCategory("Flashlight")]
    [Export] public Vector2 FlashlightDelayDurationRange { get; set; } = new Vector2(1, 2);
    [Export] public Vector2 FlashlightPointDurationRange { get; set; } = new Vector2(2, 3);
    [Export] public float FlashlightPerPriorityLevelAdditive { get; set; } = 1;
    [Export] public float FlashlightViewRange { get; set; } = 25;
    [Export] public float FlashlightTargetMoveSpeed { get; set; } = 5;
    [Export] public float FlashlightBlendSpeed { get; set; } = 1.2f;
    [Export(PropertyHint.Range, "0,180")] public float FlashlightFieldOfViewClamp { get; set; } = 30;


    [ExportCategory("World Collision")]
    [Export(PropertyHint.Layers3DPhysics)] public uint EnvironmentCollisionMask { get; set; }
    [Export] public float EnvironmentStandoff { get; set; } = 0.15f;

    [Export] public float TiltMaxVerticalOffset { get; set; } = 0.2f;
    [Export] public float TiltMaxDistanceAiming { get; set; } = 0.4f;
    [Export] public float TiltMaxDistanceIdle { get; set; } = 0.1f;

    [Export] public float TiltBlendSpeed { get; set; } = 2.5f;


    [ExportCategory("Node References")]
    [Export] public SkeletonIK3D RightHandIKSolver { get; set; }
    [Export] public SkeletonIK3D LeftHandIKSolver { get; set; }

    [Export] public Node3D CameraNode { get; set; }

    [Export] public Node3D AimingIKContainer { get; set; }
    [Export] public Node3D RightHandIdleIKContainer { get; set; }
    [Export] public Node3D LeftHandIdleIKContainer { get; set; }

    [Export] public Node3D RightHandIdleIKTarget { get; set; }
    [Export] public Node3D RightHandAimingIKTarget { get; set; }

    [Export] public Node3D LeftHandIdleIKTarget { get; set; }
    [Export] public Node3D LeftHandAimingIKTarget { get; set; }

    public bool HasRoundAvailable { get; private set; } = false;
    public bool IsAiming { get; private set; } = false;
    private int currentRoundCount = 0;

    private float currentRecoilTarget;
    private float currentRecoilActual;

    private float currentRecoilTime;

    private float currentSpreadAdditive;
    private float currentSpreadTime;

    private Vector3 AimingTargetBasePosition;
    private Vector3 RightHandIdleBasePosition;
    private Vector3 LeftHandIdleBasePosition;

    private float currentRightTiltWeight;
    private Vector3 lastRightTiltOffsetVector;
    private Vector3 lastRightTiltLookAtVector;

    private float currentLeftTargetTrackingWeight;
    private Vector3 lastLeftHandTargetPositionVector;
    private float currentLeftTiltWeight;
    private Vector3 lastLeftTiltOffsetVector;
    private Vector3 lastLeftTiltLookAtVector;

    private FlashlightPoint currentFlashlightTarget;
    private float currentFlashlightTimer;

    public override void _Ready()
    {
        AimingTargetBasePosition = AimingIKContainer.Position;
        RightHandIdleBasePosition = RightHandIdleIKContainer.Position;
        LeftHandIdleBasePosition = LeftHandIdleIKContainer.Position;

        RightHandIKSolver.Start();
        LeftHandIKSolver.Start();

        Reload();
    }

    public override void _PhysicsProcess(double delta)
    {
        currentRecoilTime = Mathf.Wrap(currentRecoilTime + (float)(delta * RecoilPanningSpeed), 0, 1000000);
        currentSpreadTime = Mathf.Wrap(currentSpreadTime + (float)(delta * SpreadPanningSpeed), 0, 1000000);

        currentSpreadAdditive = Mathf.Max(currentSpreadAdditive - ((float)delta * SpreadBloomDecay), 0);
        currentRecoilTarget = Mathf.Max(currentRecoilTarget - ((float)delta * RecoilFade), 0);

        currentRecoilActual = Mathf.Lerp(currentRecoilActual, currentRecoilTarget, (float)delta * RecoilActualBlendSpeed);
        Vector3 recoil = (new Vector3(SpreadNoise.GetNoise1D(currentRecoilTime) * 0.5f + 1, SpreadNoise.GetNoise1D(currentRecoilTime + 1000) - RecoilHorizontalBias, 0) * Mathf.DegToRad(currentRecoilActual));

        if (IsAiming)
        {
            if (currentFlashlightTarget != null && currentFlashlightTarget.priority < FlashlightPoint.Priority.high)
            {
                currentFlashlightTarget = null;
            }

            Vector3 spread = (new Vector3(SpreadNoise.GetNoise1D(currentSpreadTime), SpreadNoise.GetNoise1D(currentSpreadTime + 1000), 0) * Mathf.DegToRad(SpreadAimingConeSize + currentSpreadAdditive));
            AimingIKContainer.Rotation = recoil + spread;
            AimingIKContainer.GlobalPosition = CameraNode.ToGlobal(AimingTargetBasePosition).Lerp(CameraNode.GlobalPosition + (-AimingIKContainer.GlobalTransform.Basis.Z).Normalized() * AimingTargetBasePosition.Length(), RecoilRotationBias);

            AimingIKContainer.GlobalTransform = AdjustToEnvironment(AimingIKContainer.GlobalTransform, (float)delta, true);
        }
        else
        {
            Vector3 spread = (new Vector3(SpreadNoise.GetNoise1D(currentSpreadTime), SpreadNoise.GetNoise1D(currentSpreadTime + 1000), 0) * Mathf.DegToRad(SpreadIdleConeSize + currentSpreadAdditive));
            RightHandIdleIKContainer.Rotation = recoil + spread;
            RightHandIdleIKContainer.GlobalPosition = CameraNode.ToGlobal(RightHandIdleBasePosition).Lerp(CameraNode.ToGlobal(new Vector3(RightHandIdleBasePosition.X, RightHandIdleBasePosition.Y, 0)) + (-RightHandIdleIKContainer.GlobalTransform.Basis.Z).Normalized() * RightHandIdleBasePosition.Length(), RecoilRotationBias);

            RightHandIdleIKContainer.GlobalTransform = AdjustToEnvironment(RightHandIdleIKContainer.GlobalTransform, (float)delta, true);

            //flashlight code

            UpdateFlashlightTarget((float)delta);

            if (currentFlashlightTarget != null)
            {
                currentLeftTargetTrackingWeight = Mathf.Min(currentLeftTargetTrackingWeight + (float)delta * FlashlightBlendSpeed, 1);
                lastLeftHandTargetPositionVector = lastLeftHandTargetPositionVector.Lerp(CameraNode.ToLocal(currentFlashlightTarget.GlobalPosition), (float)delta * FlashlightTargetMoveSpeed);
            }
            else
            {
                currentLeftTargetTrackingWeight = Mathf.Max(currentLeftTargetTrackingWeight - (float)delta * FlashlightBlendSpeed, 0);
            }

            spread = new Vector3(SpreadNoise.GetNoise1D(currentSpreadTime + 10), SpreadNoise.GetNoise1D(currentSpreadTime + 1010), 0) * Mathf.DegToRad(SpreadIdleConeSize);

            if (currentLeftTargetTrackingWeight > 0)
            {
                LeftHandIdleIKContainer.LookAt(CameraNode.ToGlobal(lastLeftHandTargetPositionVector));
                LeftHandIdleIKContainer.Rotation += spread;

                LeftHandIdleIKContainer.Rotation = spread.Lerp(LeftHandIdleIKContainer.Rotation, currentLeftTargetTrackingWeight);
            }
            else
            {
                LeftHandIdleIKContainer.Rotation = spread;
            }

            LeftHandIdleIKContainer.GlobalPosition = CameraNode.ToGlobal(LeftHandIdleBasePosition).Lerp(CameraNode.ToGlobal(new Vector3(LeftHandIdleBasePosition.X, LeftHandIdleBasePosition.Y, 0)) + (-LeftHandIdleIKContainer.GlobalTransform.Basis.Z).Normalized() * LeftHandIdleBasePosition.Length(), RecoilRotationBias);
            LeftHandIdleIKContainer.GlobalTransform = AdjustToEnvironment(LeftHandIdleIKContainer.GlobalTransform, (float)delta, false);
        }
    }

    public Transform3D AdjustToEnvironment(Transform3D targetGlobalTransform, float deltaTime, bool isRight)
    {
        PhysicsDirectSpaceState3D spaceState = RightHandAimingIKTarget.GetWorld3D().DirectSpaceState;
        PhysicsRayQueryParameters3D query = PhysicsRayQueryParameters3D.Create(CameraNode.GlobalPosition, targetGlobalTransform.Origin, EnvironmentCollisionMask);

        Vector3 offset = -CameraNode.GlobalTransform.Basis.Z * EnvironmentStandoff;
        query.To += offset;

        var result = spaceState.IntersectRay(query);

        float currentTiltWeight = isRight ? currentRightTiltWeight : currentLeftTiltWeight;
        Vector3 lastTiltOffsetVector = isRight ? lastRightTiltOffsetVector : lastLeftTiltOffsetVector;
        Vector3 lastTiltLookAtVector = isRight ? lastRightTiltLookAtVector : lastLeftTiltLookAtVector;

        if (result.Count > 0)
        {
            Vector3 hitpos = (Vector3)result["position"];
            Vector3 hitnormal = (Vector3)result["normal"];

            float tiltWeight = Mathf.Clamp(hitpos.DistanceTo(query.To) / (IsAiming ? TiltMaxDistanceAiming : TiltMaxDistanceIdle), 0, 1);
            currentTiltWeight += (tiltWeight - currentTiltWeight) * deltaTime * TiltBlendSpeed;

            targetGlobalTransform.Origin = hitpos - offset + (Vector3.Up * currentTiltWeight * TiltMaxVerticalOffset);
            lastTiltOffsetVector = CameraNode.ToLocal(targetGlobalTransform.Origin);

            Vector3 newLookAtVector = (hitpos - (CameraNode.GlobalPosition - new Vector3(0, 1, 0))).Bounce(hitnormal).Normalized() * EnvironmentStandoff;
            lastTiltLookAtVector = newLookAtVector;

            targetGlobalTransform =
                targetGlobalTransform.InterpolateWith(
                    targetGlobalTransform.LookingAt(targetGlobalTransform.Origin + newLookAtVector, CameraNode.GlobalTransform.Basis.Z),
                    currentTiltWeight / 2);
        }
        else if (currentTiltWeight > 0)
        {
            currentTiltWeight = Mathf.Max(currentTiltWeight - deltaTime * TiltBlendSpeed, 0);

            targetGlobalTransform.Origin = targetGlobalTransform.Origin.Lerp(CameraNode.ToGlobal(lastTiltOffsetVector), currentTiltWeight);

            targetGlobalTransform =
                targetGlobalTransform.InterpolateWith(
                    targetGlobalTransform.LookingAt(targetGlobalTransform.Origin + lastTiltLookAtVector, CameraNode.GlobalTransform.Basis.Z),
                    currentTiltWeight / 2);
        }

        if (isRight)
        {
            currentRightTiltWeight = currentTiltWeight;
            lastRightTiltOffsetVector = lastTiltOffsetVector;
            lastRightTiltLookAtVector = lastTiltLookAtVector;
        }
        else
        {
            currentLeftTiltWeight = currentTiltWeight;
            lastLeftTiltOffsetVector = lastTiltOffsetVector;
            lastLeftTiltLookAtVector = lastTiltLookAtVector;
        }

        return targetGlobalTransform;
    }

    public void UpdateFlashlightTarget(float deltaTime)
    {
        if (currentFlashlightTarget != null && !IsInFlashlightFieldOfView(currentFlashlightTarget.GlobalPosition))
        {
            currentFlashlightTarget = null;
            currentFlashlightTimer = 0;
        }

        currentFlashlightTimer -= deltaTime;

        if (currentFlashlightTimer > 0)
        {
            return;
        }
        else {
            var flashlightTargets = GetTree().GetNodesInGroup("FlashlightPoints")
                .Select(x => x as FlashlightPoint)
                .Where(x =>
                    (!x.HasBeenTargeted || x.priority == FlashlightPoint.Priority.high)
                    && x.GlobalPosition.DistanceTo(CameraNode.GlobalPosition) < FlashlightViewRange
                    && IsInFlashlightFieldOfView(x.GlobalPosition))
                .OrderByDescending(x => x.priority).ToList();

            RandomNumberGenerator rng = new RandomNumberGenerator();
            rng.Randomize();

            if (flashlightTargets.Count > 0)
            {
                if (flashlightTargets[0].priority == FlashlightPoint.Priority.high)
                {
                    currentFlashlightTarget = flashlightTargets[0];
                }
                else
                {
                    currentFlashlightTarget = flashlightTargets[rng.RandiRange(0, flashlightTargets.Count - 1)];
                }
                currentFlashlightTarget.HasBeenTargeted = true;
                currentFlashlightTimer = rng.RandfRange(FlashlightPointDurationRange.X, FlashlightPointDurationRange.Y) + (FlashlightPerPriorityLevelAdditive * (float)currentFlashlightTarget.priority);
            }
            else
            {
                currentFlashlightTarget = null;
                currentFlashlightTimer = rng.RandfRange(FlashlightDelayDurationRange.X, FlashlightDelayDurationRange.Y);
            }
        }
    }

    public void Reload()
    {
        currentRoundCount = 6;
        HasRoundAvailable = true;
    }

    public void FireRevolver()
    {
        currentRecoilTarget += RecoilSize;
        currentSpreadAdditive += SpreadBloomPerShot;

        Node3D newMuzzleFlash = MuzzleFlash.Instantiate() as Node3D;
        BarrelEnd.AddChild(newMuzzleFlash);
        newMuzzleFlash.GlobalPosition = BarrelEnd.GlobalPosition;
        newMuzzleFlash.GlobalRotation = BarrelEnd.GlobalRotation;

        currentRoundCount -= 1;
        HasRoundAvailable = currentRoundCount > 0;

        if (BarrelRayCast.IsColliding())
        {
            Vector3 hitLocation = BarrelRayCast.GetCollisionPoint();
            PackedScene damageableEffect = ImpactEffect;
            Node3D ImpactedTarget = BarrelRayCast.GetCollider() as Node3D;

            if (ImpactedTarget is RigidBody3D rigidbody)
            {
                rigidbody.ApplyImpulse(-BarrelRayCast.GlobalTransform.Basis.Z * ImpactForce, hitLocation - rigidbody.GlobalPosition);
            }
            else if (ImpactedTarget is PhysicalBone3D physicalBone)
            {
                physicalBone.ApplyImpulse(-BarrelRayCast.GlobalTransform.Basis.Z * ImpactForce, hitLocation - physicalBone.GlobalPosition);
            }

            if (ImpactedTarget.GetChildren().FirstOrDefault(x => x.Name == "Damageable") is DamageableObject damageable)
            {
                if (damageable.HitObject != null)
                {
                    damageableEffect = damageable.ImpactEffect;
                }
                damageable.HitObject(hitLocation, -BarrelRayCast.GlobalTransform.Basis.Z * ImpactForce);
            }

            Node3D newImpactEffect = damageableEffect.Instantiate() as Node3D;
            AddChild(newImpactEffect);
            newImpactEffect.GlobalPosition = hitLocation;

            Vector3 lookAtPoint = BarrelRayCast.GetCollisionNormal();
            if (lookAtPoint != Vector3.Zero)
            {
                newImpactEffect.LookAt(newImpactEffect.GlobalPosition + lookAtPoint, Mathf.Abs(lookAtPoint.Y) > 0.99 ? Vector3.Back : Vector3.Up);
            }
        }
    }

    public void SetAimMode()
    {
        LeftHandIKSolver.TargetNode = LeftHandAimingIKTarget.GetPath();
        RightHandIKSolver.TargetNode = RightHandAimingIKTarget.GetPath();
        IsAiming = true;
    }

    public void SetIdleMode()
    {
        LeftHandIKSolver.TargetNode = LeftHandIdleIKTarget.GetPath();
        RightHandIKSolver.TargetNode = RightHandIdleIKTarget.GetPath();
        IsAiming = false;
    }

    private bool IsInFlashlightFieldOfView(Vector3 position)
    {
        return ((-CameraNode.GlobalTransform.Basis.Z.Dot((position - CameraNode.GlobalTransform.Origin).Normalized()) * -1 + 1) / 2) * 180 < FlashlightFieldOfViewClamp;
    }
}
