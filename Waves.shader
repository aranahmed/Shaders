Shader "Unlit/Waves"
{
    Properties
    {
        _DepthGradientShallow ("Depth Gradient Shallow", Color) = (0.325,0.807,0.971,0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        
//        _RippleTex ("Ripple Texture", 2D) = "white" {}
//        _Position ("position", Vector) = (0,0,0)
//        _OrthographicCamSize ("OrthoCam", Float) = 0
//        
        _SurfaceNoise("Surface Noise" , 2D) = "white" {}
        
        _BaseTex ("Base Texture", 2D) = "white" {}
        _WaveStrength("Wave Strength", Range(0, 2)) = 0.1 // = WaveAmplitude
        _Steepness("Steepness", Range(0,1)) = 0.5
        //_WaveSpeed("Wave Speed", Range(0, 10)) = 1
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
        
        _Shininess ("Shininess", Float) = 0

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
            #pragma hull tessHull
            #pragma domain tessDomain
            #pragma target 4.6
            
            

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl" 
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl" 
            
            
            
            
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 surfaceUV : TEXCOORD1;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                
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
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 binormal : TEXCOORD4;
                float3 positionVS : TEXCOORD5;
                float2 surfaceUV : TEXCOORD6;
                float4 positionCS : SV_POSITION;
                float4 positionWS : INTERP0;
                half3 lightAmount : TEXCOORD7;
                float3 normalWS : TEXCOORD8;
                float3 viewDirWS : TEXCOORD9;
            };
            

            sampler2D _BaseTex;
            
            

            CBUFFER_START(UnityPerMaterial)
                    float4 _DepthWaterColor;
                    float4 _BaseTex_ST;
                    sampler2D _SurfaceNoise;
                    float4 _SurfaceNoise_ST;
                    float _TessAmount;
                    //float _WaveStrength;
                    float _Steepness;
                    float2 _Direction;
                    float4 _WaveA;
                    float4 _WaveB;
                    float4 _WaveC;
                    //float _WaveSpeed;
                    float _WaveLength;
                    float _MaxTessDistance;
                    // marching variable
                    float _FoamDistance;
                    float _SurfaceNoiseCutoff;
                    float4 _DepthGradientShallow;
                    float4 _DepthGradientDeep;
                    float _DepthMaxDistance;
                    float _FoamShrink;
                    //sampler2D _RippleTex;

                    // for render texture
                    uniform sampler2D _GlobalEffectRT;
                    uniform float _OrthographicCamSize;
                    uniform float3 _Position;
            
                    float _RipplesCutoff;
                    float _Ambient;
                    float _WaveHeight;

                    //sampler2D _CameraDepthTexture;
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

            float3 GerstnerWave (
			float4 wave, float3 p, inout float3 tangent, inout float3 binormal
		) {
		    float steepness = wave.z;
		    float wavelength = wave.w;
		    float k = 2 * PI / wavelength;
			float c = sqrt(9.8 / k);
			float2 d = normalize(wave.xy);
			float f = k * (dot(d, p.xz) - c * _Time.y);
			float a = steepness / k;
			
			//p.x += d.x * (a * cos(f));
			//p.y = a * sin(f);
			//p.z += d.y * (a * cos(f));

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
            
            
            v2f tessVert (appdata v)
            {
                v2f o;

                
                // transform our object space pos to worldSpace using matrix mul()
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                //o.positionWS = positionWS.xyzw;
                float3 gridPoint = positionWS.xyz;

                float3 tangent = float3(1, 0, 0);
    			float3 binormal = float3(0, 0, 1);

                //float3 p = gridPoint;

                positionWS.xyz += GerstnerWave(_WaveA, gridPoint,tangent,binormal);
                positionWS.xyz += GerstnerWave(_WaveB, gridPoint,tangent,binormal);
                positionWS.xyz += GerstnerWave(_WaveC, gridPoint,tangent,binormal);
                
                //float p = gridPoint;
                //positionWS.xyz = p;
                
              
                // positionWS.x += d.x * (a  * cos(f));
                // positionWS.y += a * sin(f);
                // positionWS.z += d.y * (a  * cos(f));

                // code if you add lighting
                // correcting normals
                // float3 tangent = normalize(float3(
                //     1 - k * a * sin(f),
                //     k * a * cos(f),
                //     0
                // ));
                // float3 normal  = float3 (-tangent.y, tangent.x, 0);
                
                o.normal = v.normal;
                
                
                
                // where we form the waves using WS pos
                //float height = sin(k * (_WaveSpeed * _Time.y   + positionWS.x +positionWS.z));
                //positionWS.y += height * _WaveStrength;

                

                o.positionVS = TransformWorldToView(positionWS);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.screenPos = ComputeScreenPos(o.positionCS);
                
                //o.vertex = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);

                o.surfaceUV = TRANSFORM_TEX(v.surfaceUV, _SurfaceNoise);


                //float exisitingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(o.screenPos)).r;
                
                
                return o;
            }

            // void unity_light (in float3 normals, out float3 Out)
            // {
            //     Out = [Op] (normals);
            // }

            
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

                i.surfaceUV = patch[0].uv * bcCoords.x +
                    patch[1].uv * bcCoords.y +
                        patch[2].uv * bcCoords.z;
                
                return tessVert(i);
            }

            float4 frag (v2f i) : SV_Target
            {
                
                // calculating scene depth elements
                float fragmentEyeDepth = -i.positionVS.z;
                float rawDepth = SampleSceneDepth(i.screenPos.xy / i.screenPos.w);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);
                
                float depthDifference =  saturate((sceneEyeDepth - fragmentEyeDepth) * _FoamShrink); // this value of 1 needs to change
                float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
                
                float depth =  linearDepth -  i.screenPos.w;

                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                float2 uv  = i.positionWS.xz - _Position.xz;
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;

                float ripples = tex2D(_GlobalEffectRT, uv).b;
                ripples = step(0.99, ripples * 3);
                
                
                    //_Time.y * 0.02f * float3(_WaveA.x, _WaveB.x, _WaveC.x);
                i.surfaceUV.xy += _Time.y * 0.04f * float2(_WaveA.x, _WaveC.x);

                
                float surfaceNoiseSample = tex2D(_SurfaceNoise,  i.surfaceUV).r;

                //float surfaceNoise = tex2D(_SurfaceNoise, i.uv);

                //float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? 1 : 0 ;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
                
                float2 screenUVs = i.screenPos.xy / i.screenPos.w;
                float4 textureSample = tex2D(_BaseTex, i.uv);
                textureSample *= _DepthWaterColor;
                //float4 color = lerp(_DepthWaterColor, float4(1,1,1,1), i.positionWS.x * 0.4 );
                textureSample.a = 0.9;

                float waterDepthDifference = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference);

              
                
                float3 ambient_color = UNITY_LIGHTMODEL_AMBIENT * _Ambient;
                waterColor.rgb += ambient_color;

                //waterColor += i.positionWS.y;
              return float4(waterColor + surfaceNoise);

              //  return float4(foamDepthDifference01.xxx,1);
              //  return   textureSample + float4(surfaceNoiseSample, surfaceNoiseSample,surfaceNoiseSample,1.0);
                
}
            ENDHLSL
        }
    }
Fallback Off
}
