using Godot;
using System;

public partial class PlayerBodyController : CharacterBody3D
{
    [Export] public WeaponEffectsController GunEffects { get; set; }

    [Export] public AnimationTree AnimationTree { get; set; }
    [Export] public string HandStateMachinePlaybackPath { get; set; }
    [Export] public string IdleAnimationName { get; set; }
    [Export] public string AimingAnimationName { get; set; }

    [Export] public string IdleFireAnimationName { get; set; }
	[Export] public string AimingFireAnimationName { get; set; }

    [Export] public string IdleReloadAnimationName { get; set; }
    [Export] public string AimingReloadAnimationName { get; set; }

	[Export] public Node3D CameraNode { get; set; }
    [Export] public Node3D ArmsNode { get; set; }

    [Export] public float RotationSpeed { get; set; }
    [Export] public float CameraActualRotationSpeed { get; set; }
    [Export] public float ArmsActualRotationSpeed { get; set; }
	[Export] public float VerticalRotationLimit { get; set; } = 80;


    [Export] public float Speed = 5.0f;
    [Export] public float JumpVelocity = 4.5f;

	// Get the gravity from the project settings to be synced with RigidBody nodes.
	public float gravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();


	private AnimationNodeStateMachinePlayback handStateMachinePlayback;
	private Vector3 targetRotation;
	private bool isAiming;

	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;
		handStateMachinePlayback = (AnimationNodeStateMachinePlayback)AnimationTree.Get(HandStateMachinePlaybackPath);
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventMouseMotion mouseMotion)
		{
			targetRotation = new Vector3(
				Mathf.Clamp((-1 * mouseMotion.Relative.Y * RotationSpeed) + targetRotation.X, -VerticalRotationLimit, VerticalRotationLimit),
				Mathf.Wrap((-1 * mouseMotion.Relative.X * RotationSpeed) + targetRotation.Y, 0, 360),
				0);
		}

		if (@event.IsActionPressed("escape"))
		{
			ToggleMouseMode();
        }

		if (@event.IsActionPressed("Aim"))
		{
			isAiming = true;
			handStateMachinePlayback.Travel(AimingAnimationName);
		}
		if (@event.IsActionReleased("Aim"))
		{
			isAiming = false;
			handStateMachinePlayback.Travel(IdleAnimationName);
		}
		if (@event.IsActionPressed("Fire"))
        {
			FireWeapon();
        }
        if (@event.IsActionPressed("Reload"))
        {
            ReloadWeapon();
        }
    }

	private void FireWeapon()
	{
		if (!GunEffects.HasRoundAvailable)
		{
			ReloadWeapon();
            return;
		}

        handStateMachinePlayback.Travel(IdleFireAnimationName);
		if (isAiming)
		{
			handStateMachinePlayback.Travel(AimingFireAnimationName);
		}
		else
		{
			handStateMachinePlayback.Travel(IdleFireAnimationName);
		}
	}

	private void ReloadWeapon()
	{
        if (isAiming)
        {
            handStateMachinePlayback.Travel(AimingReloadAnimationName);
        }
        else
        {
            handStateMachinePlayback.Travel(IdleReloadAnimationName);
        }
        isAiming = false;
    }

	private void ToggleMouseMode()
	{
		if (Input.MouseMode == Input.MouseModeEnum.Visible)
		{
			Input.MouseMode = Input.MouseModeEnum.Captured;
		}
		else
		{
            Input.MouseMode = Input.MouseModeEnum.Visible;
        }
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;


		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;


		if (Input.IsActionJustPressed("Jump") && IsOnFloor())
			velocity.Y = JumpVelocity;


		Vector2 inputDir = Input.GetVector("Move_left", "Move_right", "Move_up", "Move_down");
		Vector3 direction = (CameraNode.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();

		CameraNode.Rotation = new Vector3(
			Mathf.LerpAngle(CameraNode.Rotation.X, Mathf.DegToRad(targetRotation.X), CameraActualRotationSpeed * (float)delta),
            Mathf.LerpAngle(CameraNode.Rotation.Y, Mathf.DegToRad(targetRotation.Y), CameraActualRotationSpeed * (float)delta),
			0);

        ArmsNode.Rotation = new Vector3(
            Mathf.LerpAngle(ArmsNode.Rotation.X, Mathf.DegToRad(targetRotation.X), ArmsActualRotationSpeed * (float)delta),
            Mathf.LerpAngle(ArmsNode.Rotation.Y, Mathf.DegToRad(targetRotation.Y), ArmsActualRotationSpeed * (float)delta),
            0);
    }
}
