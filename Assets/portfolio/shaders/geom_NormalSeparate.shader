Shader "Custom/geom_NormalSeparate"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        _Radial("Radial", Range(0, 1)) = 0.275

    }
   
    SubShader
    {
 
        Tags{ "Queue"="Geometry" "RenderType"= "Opaque"}
        Cull Off

        Pass
        {
            CGPROGRAM
 
            #include "UnityCG.cginc"
            #pragma vertex vert
            //Geometry Shader ステージのときに呼び出される
            #pragma geometry geom
            #pragma fragment frag

            #define pi 3.1415
 
            float4 _Color;
            sampler2D _MainTex;
            float _Radial;
 
            struct v2g
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 vertex : TEXCOORD1;
            };
 
            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
 
            //centerを中心にy軸回転行列を返す関数
            float3x3 RotateFuncY(int n) {
                float theta = n * _Radial;
                float3x3 rotate = float3x3(
                    cos(theta), 0, sin(theta),
                         0     , 1,      0     ,
                    -sin(theta), 0, cos(theta)
                );
                return  rotate;
            };


            v2g vert(appdata_full v)
            {
                v2g o;
                o.vertex = v.vertex;
                //o.pos = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex;
                o.uv = v.texcoord;
                return o;
            }
 
            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> triStream)
            {
                g2f o;
 
                //法線ベクトル
                float3 vecA = IN[1].vertex - IN[0].vertex;
                float3 vecB = IN[2].vertex - IN[0].vertex;
                float3 normal = normalize(cross(vecA, vecB));
 
                o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

                for(int i = 0; i < 3; i++){
                    IN[i].pos.xyz += normal * _Radial;
                    o.pos = UnityObjectToClipPos(IN[i].pos);
                    triStream.Append(o);    
                }
                
            }

 

            half4 frag(g2f i) : COLOR
            {
                float4 col = tex2D(_MainTex, i.uv);
                return col;
            }
 
            ENDCG
        }
    }
    Fallback "Diffuse"
}