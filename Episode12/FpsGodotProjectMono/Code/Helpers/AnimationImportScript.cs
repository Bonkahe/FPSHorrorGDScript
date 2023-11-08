using Godot;
using System;

#if DEBUG
[Tool]
public partial class AnimationImportScript : EditorScenePostImport
{
    public override GodotObject _PostImport(Node scene)
    {
        string truncatedPath = GetSourceFile();
        truncatedPath = truncatedPath.Remove(truncatedPath.LastIndexOf("/") + 1);
        Iterate(scene, truncatedPath, scene.Name);
        return scene;
    }

    public void Iterate(Node node, string basePath, string fileName)
    {
        if (node != null)
        {
            if (node.Name == "AnimationPlayer")
            {
                AnimationPlayer animationPlayer = node as AnimationPlayer;
                string[] animations = animationPlayer.GetAnimationList();
                foreach (string animation in animations)
                {
                    Animation foundanim = animationPlayer.GetAnimation(animation);
                    using var dir = DirAccess.Open(basePath);

                    string newFileName = basePath + fileName + "-" + animation + ".tres";
                    GD.Print(newFileName);

                    if (dir != null)
                    {
                        Animation previousanim = ResourceLoader.Load(newFileName) as Animation;

                        //GD.Print("Found animation:");
                        //GD.Print(previousanim);
                        if (previousanim != null)
                        {
                            
                            for (int i = 0; i < previousanim.GetTrackCount(); i++)
                            {
                                //GD.Print("Track " + i.ToString() + " type: " + previousanim.TrackGetType(i));
                                switch (previousanim.TrackGetType(i))
                                {
                                    case Animation.TrackType.Value:
                                    case Animation.TrackType.BlendShape:
                                    case Animation.TrackType.Method:
                                    case Animation.TrackType.Audio:
                                        int newTrack = foundanim.AddTrack(previousanim.TrackGetType(i));

                                        for (int c = 0; c < previousanim.TrackGetKeyCount(i); c++)
                                        {
                                            int newKeyIndex = foundanim.TrackInsertKey(newTrack, previousanim.TrackGetKeyTime(i, c), previousanim.TrackGetKeyValue(i, c), previousanim.TrackGetKeyTransition(i, c));
                                            GD.Print("added key at index: " + newKeyIndex + " at time: " + foundanim.TrackGetKeyTime(newTrack, newKeyIndex));
                                        }
                                        break;
                                }
                                
                            }
                        }
                    }

                    Error error = ResourceSaver.Save(foundanim, newFileName, ResourceSaver.SaverFlags.ReplaceSubresourcePaths);
                    if (error != Error.Ok)
                    {
                        GD.PushError("An error occurred while saving the scene to disk.");
                    }
                }
            }
            else
            {
                GD.Print(node.Name);
                foreach (Node child in node.GetChildren())
                {
                    Iterate(child, basePath, fileName);
                }
            }

            //if (node.Name == "GeneralSkeleton")
            //{
            //    foreach (Node child in node.GetChildren())
            //    {
            //        var scene = new PackedScene();
            //        Error result = scene.Pack(child);
            //        if (result == Error.Ok)
            //        {
            //            using var dir = DirAccess.Open(basePath);
            //            if (dir != null)
            //            {
            //                Error errordel = dir.Remove(child.Name + ".tscn");
            //            }

            //            Error error = ResourceSaver.Save(scene, basePath + child.Name + ".tscn", ResourceSaver.SaverFlags.ReplaceSubresourcePaths);
            //            if (error != Error.Ok)
            //            {
            //                GD.PushError("An error occurred while saving the scene to disk.");
            //            }
            //        }
            //    }
            //}
            //else
            //{
            //    foreach (Node child in node.GetChildren())
            //    {
            //        Iterate(child, basePath);
            //    }
            //}
        }
    }
}
#endif