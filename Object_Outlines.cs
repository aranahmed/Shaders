using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;


public class Object_Outlines : MonoBehaviour
{
    private int selectionBuffer;
    public Renderer OutlinedObject;
    public Material WriteObject;
    
    

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // setup
        var commands = new CommandBuffer();
        int objectBuffer = Shader.PropertyToID("_SelectionBuffer");
        commands.GetTemporaryRT(objectBuffer, source.descriptor);
            
            // render selectionBuffer
            commands.SetRenderTarget(selectionBuffer);
            commands.ClearRenderTarget(true,true, Color.clear);
            if (OutlinedObject != null)
            {
                commands.DrawRenderer(OutlinedObject, WriteObject);
            }
            
        //apply everything and clean up in commandBuffer
        commands.Blit(selectionBuffer, destination);
        commands.ReleaseTemporaryRT(selectionBuffer);
            
        //execute and clean up commandbuffer itself
        Graphics.ExecuteCommandBuffer(commands);
        commands.Dispose();

        
    }
}
