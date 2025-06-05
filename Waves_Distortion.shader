Shader "Unlit/Waves"
{
    Properties
    {
        _DepthGradientShallow ("Depth Gradient Shallow", Color) = (0.325,0.807,0.971,0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _SurfaceNoise("Surface Noise" , 2D) = "white" {}
        
        _BaseTex ("Base Texture", 2D) = "white" {}
        _WaveStrength("Wave Strength", Range(0, 2)) = 0.1
        _Steepness("Steepness", Range(0,1)) = 0.5
        _WaveLength("Wave Length", Float) = 10
        _Direction ("Direction (2D)", Vector) = (1,0,0,0)
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("Source Blend Factor", Int) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("Destination Blend Factor", Int) = 1
        
        _TessAmount("Tesselation Amount", Range(1, 64)) = 2
        
        _MaxTessDistance("Max Tesselation Distance", Range(5, 256)) = 15
        
        _WaveA("Wave A, (Direction, Steepness, WaveLength)", Vector) = (1,0,0.5,10)
        _WaveB("Wave B, (Direction, Steepness, WaveLength)", Vector) = (0,1.0,0.25,20)
        _WaveC("Wave C, (Direction, Steepness, WaveLength)", Vector) = (0,1.0,0.25,20)
        
        _FoamDistance("Foam Distance", Float) = 0.5
        _FoamShrink ("Foam Shrink", Float) = 0.1
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        
        _Ambient ("Ambient float", Float) = 1
        
        _WaveHeight("Wave Height", Float) = 0

        // New properties for distortion
        _DistortionStrength("Distortion Strength", Range(0, 1)) = 0.05
        _DistortionSpeed("Distortion Speed", Float) = 1.0
        _DisTex ("Dis Texture", 2D) = "white" {}

    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent" 
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }
        
        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            HLSLPROGRAM
            #define SMOOTHSTEP_AA  0.01
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.6
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl" 
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl" 
            
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 surfaceUV : TEXCOORD1;
                float2 dist_uv : TEXCOORD2;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 dist_uv : TEXCOORD9;
                float4 screenPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 binormal : TEXCOORD4;
                float3 positionVS : TEXCOORD5;
                float2 surfaceUV : TEXCOORD6;
                float4 positionCS : SV_POSITION;
                float4 positionWS : INTERP0;
                half3 lightAmount : TEXCOORD7;
            };

            sampler2D _BaseTex;
            sampler2D _SurfaceNoise;
            sampler2D _DisTex;
           

            CBUFFER_START(UnityPerMaterial)
                float4 _DepthWaterColor;
                float4 _BaseTex_ST;
                float4 _DisTex_ST;
                float4 _SurfaceNoise_ST;
                float _TessAmount;
                float _Steepness;
                float2 _Direction;
                float4 _WaveA;
                float4 _WaveB;
                float4 _WaveC;
                float _WaveLength;
                float _MaxTessDistance;
                float _FoamDistance;
                float _SurfaceNoiseCutoff;
                float4 _DepthGradientShallow;
                float4 _DepthGradientDeep;
                float _DepthMaxDistance;
                float _FoamShrink;
                float _Ambient;
                float _WaveHeight;
                float _DistortionStrength;
                float _DistortionSpeed;
               
            CBUFFER_END

            float3 GerstnerWave(
                float4 wave, float3 p, inout float3 tangent, inout float3 binormal
            ) {
                float steepness = wave.z;
                float wavelength = wave.w;
                float k = 2 * PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, p.xz) - c * _Time.y);
                float a = steepness / k;

                tangent += float3(
                    -d.x * d.x * (steepness * sin(f)),
                    d.x * (steepness * cos(f)),
                    -d.x * d.y * (steepness * sin(f))
                );
                binormal += float3(
                    -d.x * d.y * (steepness * sin(f)),
                    d.y * (steepness * cos(f)),
                    -d.y * d.y * (steepness * sin(f))
                );
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                );
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 gridPoint = positionWS.xyz;

                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);

                positionWS.xyz += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
                positionWS.xyz += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
                positionWS.xyz += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
                
                o.normal = v.normal;
                o.positionVS = TransformWorldToView(positionWS);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.screenPos = ComputeScreenPos(o.positionCS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                
                o.surfaceUV = TRANSFORM_TEX(v.surfaceUV, _SurfaceNoise);
                
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Offset UV coordinates based on wave-like distortion
                // float2 distortion = tex2D(_SurfaceNoise, i.uv * _DistortionSpeed + _Time.yz * _DistortionSpeed).rg;
                // distortion = distortion * 2.0 - 1.0;
                // distortion *= _DistortionStrength;

                // Apply distortion to screen position
                //i.screenPos.xy += distortion * i.screenPos.w;
                i.screenPos.xy -= 50;
                i.dist_uv.x += sin(_Time.y * _DistortionSpeed) * _DistortionStrength;
                float3 sampler_dist =  tex2D(_DisTex, i.screenPos.xy);
                    
                
                float2 tempScreenPos = i.screenPos.xy * sampler_dist;
                i.screenPos.xy += tempScreenPos;

                // Sample scene depth and color with the correct URP method
                float sceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenPos.xy);
                float4 sceneColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.screenPos.xy);

                // Convert depth to linear depth
                float linearDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);

                // Normalize the depth based on max distance
                float normalizedDepth = saturate(linearDepth / _DepthMaxDistance);

                // Output the depth as grayscale
                 float fragmentEyeDepth = -i.positionVS.z;

                return (fragmentEyeDepth.xxx,0.5); 


                
                // Mix with water color
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, sceneDepth / _DepthMaxDistance);


                

                // Apply final water color with transparency based on depth
                return float4(sceneDepth.xx, 0, 1);
            }

            ENDHLSL
        }
    }

    Fallback Off
}
