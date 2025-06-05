Shader "Unlit/USB__SDF_fruit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _PlaneTex ("Plane Texture", 2D) = "white" {}

        _CircleCol ("Circle Color", Color) = (1,1,1,1)

        _CircleRadius ("Circle Radius", Range(0.0,0.5)) = 0.45
        _Edge ("Edge", Range(-0.5,0.5)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
              
        Cull Off
                        
        Pass
        {
           CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            
            #include "UnityCG.cginc"


            sampler2D _MainTex;
            sampler2D _PlaneTex;
            float4 _MainTex_ST;
            float4 _CircleCol;
            float _CircleRadius;
            float _Edge;


            // declare the function for the plane
            float planeSDF(float3 ray_position){
                // subtract the edge to the "Y" ray position to increase
                // or decrease the plane position
                
                float plane = ray_position.y - _Edge;
                return plane;

            }

            // max of steps to determine the surface intersection
            #define MAX_MARCHING_STEPS 50
            // max distance to find the surface intersection
            #define MAX_DISTANCE 10.0
            // surface distance
            #define SURFACE_DISTANCE 0.001

            float sphereCasting (float3 ray_origin, float3 ray_direction)
            {
                // distance of the origin starts at 0
                float distance_origin = 0;

                // for every marching step ray goes forward based on direction
                // distance_origin is based on the  ray pos.y - Edge given
                for(int i=0; i <  MAX_MARCHING_STEPS; i++)
                {
                    //_Edge =  sin(_Edge - _Time.y) ;
                    float3 ray_position = ray_origin + ray_direction * distance_origin;
                    float distance_scene = planeSDF(ray_position);
                    distance_origin += distance_scene;
                    
                    if (distance_scene < SURFACE_DISTANCE || distance_origin > MAX_MARCHING_STEPS);
                    break;
                }
            return distance_origin;
            }





            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 hitPos : TEXCOORD1;
                float3 positionVS: TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 positionWS = TransformViewToProjection(v.vertex.xyz);
                
                // we assign the vertex position in object-space
                o.hitPos = v.vertex;
                
                return o;
            }

            float smooth_min(float a , float b, float k )
            {
                float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
                return lerp(b, a, k) - k * h * (1.0 - h);
            }

            fixed4 frag (v2f i, bool face : SV_ISFRONTFACE) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // transform the camera to local-space
                float3 ray_origin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                //calculate the ray direction
                float3 ray_direction = normalize(i.hitPos - ray_origin);

                // use the values in the ray casting function
                float t = sphereCasting(ray_origin,ray_direction);
                float4 planeCol = 0;
                float4 circleCol = 0;    

                // calculate the point position in space
                if (t < MAX_DISTANCE){
                    float3 p = ray_origin + ray_direction * t;
                    
                    float2 uv_p = p.xz;

                    float l = pow(-abs(_Edge), 2) + pow(-abs(_Edge) - 1, 2);

                    float c = length(uv_p);

                    //uv_p += 1-abs(pow(_Edge * l, 2));

                    circleCol = smoothstep(c - 0.01, c + 0.01, _CircleRadius -
                        abs(pow(_Edge * (1 * 0.5), 2)));
                    
                    //planeCol = tex2D(_PlaneTex, uv_p * (1 - abs(pow(_Edge * l, 2)))) - 0.5;
                    //planeCol = tex2D(_PlaneTex, uv_p * (1 - abs(pow(_Edge * l, 2)))) - 0.5;
                    planeCol = tex2D(_PlaneTex, i.uv  * l );

                    // delete the texture borders
                    //planeCol *= circleCol;

                    // add the cricle and apply color

                    

                    //planeCol *= circleCol;
                    
                    //planeCol += l *circleCol;
                }

                if (i.hitPos.y > _Edge){
                    discard;
                }

                return face ? col : planeCol;

                //return float4(uv_p.xxx,1);
            }
            ENDCG
        }
    }
}
