using Godot;
using System;

public static class DebugExtensions
{

    public static void DrawPoint(this Node originNode, Vector3 pos, float duration, Color color, float size = 0.05f)
    {
        MeshInstance3D mesh_instance = new();
        SphereMesh sphereMesh = new();
        StandardMaterial3D material = new();

        mesh_instance.Mesh = sphereMesh;
        mesh_instance.CastShadow = GeometryInstance3D.ShadowCastingSetting.Off;
        mesh_instance.Position = pos;

        sphereMesh.Radius = size / 2;
        sphereMesh.Height = size;
        sphereMesh.Material = material;

        material.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
        material.AlbedoColor = color;

        originNode.GetTree().Root.AddChild(mesh_instance);
        if (duration != 0)
        {
            SceneTreeTimer timer = originNode.GetTree().CreateTimer(duration);
            timer.Connect("timeout", new Callable(mesh_instance, "queue_free"));
        }
    }


    public static void BuildDebugLine(this Node originNode, Vector3 origin, Vector3 destination, float duration, Color color)
    {
        MeshInstance3D mesh_instance = new();

        ImmediateMesh immediate_mesh = new();

        StandardMaterial3D material = new();

        mesh_instance.Mesh = immediate_mesh;
        mesh_instance.CastShadow = GeometryInstance3D.ShadowCastingSetting.Off;


        immediate_mesh.SurfaceBegin(Mesh.PrimitiveType.Lines, material);
        immediate_mesh.SurfaceAddVertex(origin);
        immediate_mesh.SurfaceAddVertex(destination);
        immediate_mesh.SurfaceEnd();

        material.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;

        material.AlbedoColor = color;
        originNode.GetTree().Root.AddChild(mesh_instance);
        if (duration != 0)
        {
            SceneTreeTimer timer = originNode.GetTree().CreateTimer(duration);
            timer.Connect("timeout", new Callable(mesh_instance, "queue_free"));
        }
    }




    public static Vector3 GetBezierCurvePosition(Vector3 targetPos, Vector3 targetControl, Vector3 originPos, Vector3 originControl, float lerpValue)
    {
        Vector3 A = originPos.Lerp(originControl, lerpValue);
        Vector3 B = originControl.Lerp(targetControl, lerpValue);
        Vector3 C = targetControl.Lerp(targetPos, lerpValue);

        Vector3 D = A.Lerp(B, lerpValue);
        Vector3 E = B.Lerp(C, lerpValue);

        Vector3 F = D.Lerp(E, lerpValue);
        return F;
    }

    public static void DebugBezierCurve(this Node originNode, Vector3 targetPos, Vector3 targetControl, Vector3 originPos, Vector3 originControl, Color newColor, float duration)
    {
        Vector3 lastPosition = originPos;
        Vector3 newPosition;
        for (float i = 1; i < 20; i++)
        {
            newPosition = GetBezierCurvePosition(targetPos, targetControl, originPos, originControl, i / 20);
            originNode.BuildDebugLine(lastPosition, newPosition, duration, newColor);
            lastPosition = newPosition;
        }
        originNode.BuildDebugLine(lastPosition, targetPos, duration, newColor);
    }
}