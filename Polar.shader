Shader "Unlit/PolarCoordinates"
{
    Properties
    {
        _BaseTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color" , Color) = (0.5, 0.5, 0.5, 1)
        //_Center ("Center" , Vector) = (0.5, 0.5)
        _Center ("Center", Vector) = (0.5, 0.5, 0.0)
        _RadialScale ("Radial Scale" , Float) = 0.5
        _LengthScale ("Length Scale" , Float) = 0.5
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" } 
        

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
           // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

           
            
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                float4 vertex : SV_POSITION;
            };

             CBUFFER_START(UnityPerMaterial)

                sampler2D _BaseTex;
                float4 _BaseColor;
                float4  _BaseTex_ST;
                float2  _Center;
                float  _RadialScale;
                float  _LengthScale;
            CBUFFER_END


            float2 cartesianToPolar(inout float2 uv)
            {
                float2 offset = uv - _Center;
                float radius = length(offset) * 2;
                float angle = atan2(offset.x, offset.y) / (2.0 * UNITY_PI);
                
                return float2(radius, angle);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture

                float2 radialUV = cartesianToPolar(i.uv);
                radialUV.x *= _RadialScale;
                radialUV.y *= _LengthScale;
                
                float4 textureSample = tex2D(_BaseTex, radialUV);
                textureSample *= _BaseColor;
                return textureSample;
            }
            ENDHLSL
        }
    }
}
