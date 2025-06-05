using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Postprocessing : MonoBehaviour
{
    // material that's applied when doing postprocessing
    [SerializeField]
    private Material postprocessMaterial;

    // auto called by unity after camera is done rendering
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // draws the pixels from the source texture to the destination texture
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
