Shader "Unlit/WavesTessWithLOD"
{
    Properties
    {
        _DepthWaterColor ("Depth Water Color", Color) = (1,1,1,1)
        _ShallowWaterColor ("Shallow Water Color", Color) = (1,1,1,1)
        
        
        _BaseTex ("Base Texture", 2D) = "white" {}
        _WaveStrength("Wave Strength", Range(0, 2)) = 0.1
        _WaveSpeed("Wave Speed", Range(0, 10)) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("Source Blend Factor", Int) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("Destination Blend Factor", Int) = 1
        
        _TessAmount("Tesselation Amount", Range(1, 64)) = 2
        
        _MaxTessDistance("Max Tesselation Distance", Range(5, 256)) = 15
        
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
                float4 screenPos : TEXCOORD1;
                
                float4 positionCS : SV_POSITION;
                float4 positionWS : INTERP0;
            };

            sampler2D _BaseTex;

            CBUFFER_START(UnityPerMaterial)
                    float4 _DepthWaterColor;
                    float4 _BaseTex_ST;
                    float _TessAmount;
                    float _WaveStrength;
                    float _WaveSpeed;
                    float _MaxTessDistance;
            CBUFFER_END

            //fade tesselation at a distance
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tessFactor)
            {
                float3 worldPosition = mul(unity_ObjectToWorld, vertex).xyz;
                float dist = distance(worldPosition, GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tessFactor;
                return f;
            }

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

                float4 positionWS = mul(unity_ObjectToWorld, v.positionOS);
                // where we form the waves using WS pos
                float height = sin(_Time.y * _WaveSpeed + positionWS.x +positionWS.z);
                positionWS.y += height * _WaveStrength;

                o.positionCS = mul(UNITY_MATRIX_VP, positionWS); 
                //o.vertex = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
               
                return o;
            }
            tessFactors patchConstantFunc(InputPatch<tessControlPoint, 3> patch)
            {
                // values for distance fading the tess
                float minDist = 5.0;
                float maxDist = _MaxTessDistance;
                float tess = _TessAmount;
                
                tessFactors f;
                float edge0 = CalcDistanceTessFactor(patch[0].positionOS, minDist, maxDist, tess);
                float edge1 = CalcDistanceTessFactor(patch[1].positionOS, minDist, maxDist, tess);
                float edge2 = CalcDistanceTessFactor(patch[2].positionOS, minDist, maxDist, tess);

                // make sure there are no gaps between different tesselated distances, by averaging the edges out.
                f.edge[0] = (edge1 + edge2) / 2;
                f.edge[1] = (edge2 + edge0) / 2;
                f.edge[2] = (edge0 + edge1) / 2;

                f.inside = (edge0 + edge1 + edge2) / 3;
                
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
                float2 screenUVs = i.screenPos.xy / i.screenPos.w;
                float4 textureSample = tex2D(_BaseTex, i.uv);
                textureSample *= _DepthWaterColor;
                
                return textureSample;
            }
            ENDHLSL
        }
    }
Fallback Off
}
