Shader "Custom/GamingSurface"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _RainbowAipha("透明度", Range(0.0, 1)) = 1
        _Speed("Speed", Range(0, 5)) = 1
        _ColorWidth ("ColorWidth", Range(0.1, 10)) = 1
        _Theta("rotation", Range(0, 3.14)) = 0
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
            };

            float3 HUEtoRGB(in float H)
            {
                float R = abs(H * 6 - 3) - 1;
                float G = 2 - abs(H * 6 - 2);
                float B = 2 - abs(H * 6 - 4);
                return saturate(float3(R, G, B));
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Speed, _ColorWidth, _RainbowAipha, _Theta;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                float2x2 rotateMatrix = float2x2(cos(_Theta), -sin(_Theta), sin(_Theta), cos(_Theta));
                i.screenPos.xy = mul(i.screenPos.xy, rotateMatrix);
                float2 grabUV = (i.screenPos.xy / i.screenPos.w);                
                col.xyz = HUEtoRGB(frac((grabUV.y * _ColorWidth) + (_Time.y * _Speed))) * _RainbowAipha;
                col += tex2D(_MainTex, i.uv);
                return col;
            }

            ENDCG
        }

    }
}