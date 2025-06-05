Shader "Unlit/SceneDepth"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        [Enum(Less, 0, LEqual, 1, Equal, 2, GEqual, 3, Greater, 4, NotEqual, 5, Always, 6)]
        _ZBuffer("Z Buffer Status", Float ) = 0
      
    }
    SubShader
    {
        
        Tags 
        { 
                "RenderType"="Transparent" 
                "RenderPipeline" = "UniversalRenderPipeline" 
        }
        //ZTest [_ZBuffer]
        ZTest LEqual
        Blend SrcAlpha OneMinusSrcAlpha // default Transparency

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
           

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


            CBUFFER_START(variables)
            
            float4 _BaseColor;
            


            CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionVS: TEXCOORD2;
                float4 positionNDC : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
                float4 positionCS : SV_POSITION;
                // float3 positionWS: TEXCOORD1;
                //float4 positionOS : SV_POSITION;
            };

            //sampler2D _MainTex;
            //float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                //o.positionOS = TransformObjectToHClip(v.positionOS);
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 positionVS = TransformWorldToView(positionWS);
                float4 positionCS = TransformWorldToHClip(positionWS);
                o.positionVS = positionVS;
                o.positionCS = positionCS;
                o.screenPos = ComputeScreenPos(positionCS);
                
                // Clip Space Position (calculated for vertex shader SV_POSITION output)
                //o.positionVS = positionVS;


                // Remap, Handled automatically for the SV_POSITION semantic.
                // Note that it's w (eye depth) component remains untouched, even when passed into the fragment.
                // Other semantics (TEXCOORDX) passing clip space through would need to do this manually

                // normalized device Coordinates
                // float4 positionNDC = positionCS * 0.5f;
                // positionNDC.xy = float2(positionNDC.x, positionNDC.y * _ProjectionParams.x) + positionNDC.w;
                // positionNDC.zw = positionCS.zw;
                // o.positionNDC = positionNDC;

                // or just
                //o.positionNDC = ComputeScreenPos(positionCS);
                
                
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                return o;
            }


            struct FragOut{
                half4 color : SV_Target;
                float depth : SV_Depth;
            };

            float LinearDepthToNonLinear(float linear01Depth, float4 zBufferParam){
                // Inverse of Linear01Depth
                return (1.0 - (linear01Depth * zBufferParam)) / (linear01Depth * zBufferParam.x);
            }

            float EyeDepthToNonLinear(float eyeDepth, float4 zBufferParam){
                // Inverse of LinearEyeDepth
                return (1.0 - (eyeDepth * zBufferParam.w)) / (eyeDepth * zBufferParam.z);
            }
            
            

            float4 frag (v2f i) : SV_Target
            {

                float fragmentEyeDepth = -i.positionVS.z;
                float rawDepth = SampleSceneDepth(i.screenPos.xy / i.screenPos.w);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                
            /*
                // Perspective Divide (handled in Fragment shader)
                float3 pd = i.positionNDC.xyz / i.positionNDC.w;
                float2 screenUV = pd.xy;
                float depth = pd.z; // for OpenGL, also need * 0.5 + 0.5;
                
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv);

                float4 color = _MainCol;
                //float4 eye = float4(fragmentEyeDepth, 0.0, 0.0, 1.0);

                FragOut o;
                //o.color =  color;
                //o.depth = depth;
            */
                float4 color = _BaseColor;
                
                float depthDifference = 1 - saturate((sceneEyeDepth - fragmentEyeDepth) * 1);
                float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);

                

                

                return float4(linearDepth.xxx,  1);
            }
            ENDHLSL
        }
    }
}



//Specifically, the values of _ZBufferParams are :
// x = 1-far/near
// y = far/near
// z = x/far
// w = y/far
// or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1) :
// x = -1+far/near
// y = 1
// z = x/far
// w = 1/far
