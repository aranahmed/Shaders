Shader "Unlit/Waves"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BaseTex ("Base Texture", 2D) = "white" {}
        _WaveStrength("Wave Strength", Range(0, 2)) = 0.1
        _WaveSpeed("Wave Speed", Range(0, 10)) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("Source Blend Factor", Int) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("Destination Blend Factor", Int) = 1
        
        _TessAmount("Tesselation Amount", Range(1, 64)) = 2
        
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
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull tessHull
            #pragma domain tessDomain
            #pragma target 4.6
            
            

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct tessControlPoint
            {
                float4 positionOS : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
            };
            struct tessFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _BaseTex;

            CBUFFER_START(UnityPerMaterial)
                    float4 _BaseColor;
                    float4 _BaseTex_ST;
                    float _TessAmount;
                    float _WaveStrength;
                    float _WaveSpeed;
            CBUFFER_END

            tessControlPoint vert(appdata v)
            {
                tessControlPoint o;
                o.positionOS = v.positionOS;
                o.uv = v.uv;
                return o;
            }
            
            v2f tessVert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
               
                return o;
            }
            tessFactors patchConstantFunc(InputPatch<tessControlPoint, 3> patch)
            {
                tessFactors f;
                f.edge[0] = f.edge[1] = f.edge[2] = _TessAmount;
                f.inside = _TessAmount;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_even")]
            [patchconstantfunc("patchConstantFunc")]
            tessControlPoint tessHull(InputPatch<tessControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [domain("tri")]
            v2f tessDomain(tessFactors factors, OutputPatch<tessControlPoint, 3> patch, float3 bcCoords : SV_DomainLocation)
            {
                appdata i;

                i.positionOS = patch[0].positionOS * bcCoords.x +
                    patch[1].positionOS * bcCoords.y +
                        patch[2].positionOS * bcCoords.z;

                i.uv = patch[0].uv * bcCoords.x +
                    patch[1].uv * bcCoords.y +
                        patch[2].uv * bcCoords.z;

                return tessVert(i);
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_BaseTex, i.uv);
                
                return col;
            }
            ENDHLSL
        }
    }
Fallback Off
}
