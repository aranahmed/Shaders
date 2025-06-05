Shader "Unlit/SDF_Box"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            float sdBox( in float2 p, in float2 rad){
                p = abs(p)-rad;
                return max(p.x,p.y);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv -= float2(0.5,0.5);

                float2 p = (2 * i.uv.xy) / i.uv.y;


          
                const float2 rad = float2(0.5,0.2);
             
                float d = sdBox(p,rad);

                fixed3 col = fixed3(1.0,0.9,1.0) + sign(d) * fixed3(-0.3,0.4,0.3);
                col *= 1.0 - exp(-3.0*abs(d));
                col *= 0.8 + 0.2*cos(10.0 * d);
                col = lerp(col, float3(1.0,1.0,1.0),1.0 - smoothstep(0.0,0.008,abs(d)));
                




                return fixed4(col,1.0);
            }
            ENDCG
        }
    }
}
