Shader "Custom/geom_DummyReflection"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        _st("st", Range(0, 0.5)) = 0
        _deg("deg", Range(0, 0.1)) = 0
        _dest("dest", Range(0, 500)) = 0
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
 
            float4 _Color;
            sampler2D _MainTex;
            float _st, _deg, _dest;
 
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
 
            v2g vert(appdata_full v)
            {
                v2g o;
                o.vertex = v.vertex;
                //o.pos = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex;
                o.uv = v.texcoord;
                return o;
            }
 
            [maxvertexcount(6)]
            void geom(triangle v2g IN[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> triStream)
            {
                g2f o;
 
                //法線ベクトルの計算(ライティングで使用)
                float3 vecA = IN[1].vertex - IN[0].vertex;
                float3 vecB = IN[2].vertex - IN[0].vertex;
                float3 normal = normalize(cross(vecA, vecB));
 
                o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

                //メッシュ作成
                for(int i = 0; i < 3; i++)
                {
                    o.pos = IN[i].pos;;  
                    //o.pos.xyz += _st;
                    o.pos = UnityObjectToClipPos(o.pos);
                    triStream.Append(o);    
                }
                triStream.RestartStrip();//さらに他の三角メッシュを作成する時に必要
            

                for(int i = 0; i < 3; i++)
                {
                    o.pos = IN[i].pos;;  
                    o.pos = mul(unity_ObjectToWorld, o.pos);
                    o.pos.y *= -1;
                    o.pos.x += sin(o.pos.y * _dest * _Time.x) * _deg ;
                    o.pos = mul(unity_WorldToObject, o.pos);
                    o.pos = UnityObjectToClipPos(o.pos);
                    triStream.Append(o);    
                }
                triStream.RestartStrip();
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