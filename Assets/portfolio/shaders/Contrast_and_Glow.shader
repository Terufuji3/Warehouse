Shader "Custom/Contrast_and_Glow"
{
	Properties{
        _Color("color", Color) = (1,1,1,0)
        _Strength("Strength", Range(0.5, 200)) = 1
		_Contrast("Contrast", Range(4.8, 50))=10
        _ContrastDeg("Contrast Degree", Range(0, 1)) = 0
	}

	SubShader
	{
		Tags{
			"RenderType"="Transparent"
			"Queue"="Transparent+5000"
		}

		GrabPass{}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _GrabTexture;

            float _Strength;
            float4 _Color;
			float _Contrast, _ContrastDeg;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half2 grabUV = (i.screenPos.xy / i.screenPos.w);
				fixed4 tex = tex2D(_GrabTexture, grabUV) * _Color;
                tex.xyz *= _Strength;
				tex = lerp(tex, 1/(1+exp(-_Contrast*(tex-0.5))), _ContrastDeg);
				return tex;
			}
			ENDCG
		}
	}
}