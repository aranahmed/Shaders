Shader "Unlit/Outline_Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlinePower ("Outline Power", Range(0,1)) = 1 
        _OutlineWidth ("Outline Width", Range(0,1)) = 1 
        _OutlineSoftness ("Outline Softness", Range(0,1)) = 1 
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Geometry" }
        

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlinePower;
            float _OutlineWidth;
            float _OutlineSoftness;
            float3 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float Fresnel(float n, float v, float p){
               
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
               
                float edge1 = 1 - _OutlineWidth;
                float edge2 = edge1 + _OutlineSoftness;
                float fresnel = pow((1.0 - saturate(dot(i.normal,i.viewDir))),_OutlinePower);
                float4 outline = float4((lerp(1,smoothstep(edge1,edge2,fresnel),step(0,edge1)) * _OutlineColor),1);
                col += outline;

                return float4(col);
            }
            ENDCG
        }
    }
}
