Shader "Custom/ImageProcessing"
{
	Properties {
		[Header(Bloom)]
		[Toggle(Bloom)] _Bloom ("active", Float) = 0
		_BloomStrength ("Bloomの強さ", Range (0.0, 10.0)) = 1.5
		_BloomBlur ("Blurの強度", Range(1, 128)) = 16

		[space(100)]
		[Header(Shake Window)] 
		[Toggle(Shake)] _Shake("active", Float) = 0
		_ShakeSpeed("揺れの速さ", Range (0.0, 250.0)) = 0.0
		_ShakeAmplitude ("振幅", Range (0.0, 100.0)) = 0.0

		[space(100)]
		[Header(Color jack)]
		[Toggle(Colorjack)] _Colorjack("active", Float) = 0.0
		_JackColor("画面の色", Color) = (0, 0, 0, 1)
		_ColorInterpolation("濃さ", Range(0.0, 1.0)) = 0.0

		[space(100)]
		[Header(Radial Blur)]
		[Toggle(RadialBlur)] _RadialBlur("active", Float) = 0.0
		_RadialBlurStrength("放射状blurの強さ", Range(0.0, 1.0)) = 0.0
		_RadialSampleCount("繰り返し回数", Range(0.0, 30)) = 0.0

		[space(100)]
		[Header(Zoom)]
		[Toggle(Zoom)] _Zoom("active", Float) = 0.0
		_ZoomScale("拡大率", Range(1, 10)) = 1

		[space(100)]
		[Header(Double Zoom)]
		[Toggle(DoubleZoom)] _DoubleZoom("active", Float) = 0.0
		_DoubleZoomScale("拡大率", Range(0.0, 1.0)) = 0.0

		[space(100)]
		[Header(Rotation Window)]
		[Toggle(RotationWindow)] _RotationWindow("active", Float) = 0.0
		_RotationAngle("回転角", Range(-6.28, 6.28)) = 0.0

		[space(100)]
		[Header(Chromatic Aberration)]
		[Toggle(ChromaticAberration)] _CA("active", Float) = 0.0
		_CASize("size", Range(0.0, 1.0)) = 0.0

		[space(100)]
		[Header(Color Inversion)]
		[Toggle(ColorInversion)] _ColorInversion("active", Float) = 0.0

		[space(100)]
		[Header(Binarization)]
		[Toggle(Binarization)] _Binarization("active", Float) = 0.0
		_BinarizationThreshold("Threshold", Range(0.0, 1.0)) = 0.0

		[SPACE(100)]
		[Header(Grayscale)]
		[Toggle(Grayscale)] _Grayscale("active", Float) = 0.0

		[space(100)]
		[Header(Blur)]
		[Toggle(Blur)] _BlurActive("active", Float) = 0.0
		_BlurFactor("Blurの強度", Range(0, 0.05)) = 0.0
		
	}


	SubShader {
		Tags{"RenderType" = "Transparent" "Queue" = "Overlay"}
		Cull Off
		ZTest Always

		GrabPass{}

		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			#pragma shader_feature Bloom
			#pragma shader_feature Shake
			#pragma shader_feature Colorjack
			#pragma shader_feature RadialBlur
			#pragma shader_feature Zoom
			#pragma shader_feature DoubleZoom
			#pragma shader_feature RotationWindow
			#pragma shader_feature ChromaticAberration
			#pragma shader_feature ColorInversion
			#pragma shader_feature Binarization
			#pragma shader_feature Grayscale
			#pragma shader_feature Blur
			
			sampler2D _GrabTexture;

			//Bloom
			float _BloomStrength, _BloomBlur;
			//Shake
			float _ShakeSpeed, _ShakeAmplitude;
			//カラージャック
			float4 _JackColor;
			float _ColorInterpolation;
			//RadialBlur
			float _RadialBlurStrength, _RadialSampleCount;
			//Zoom
			float _ZoomScale;
			//DoubleZoom
			float _DoubleZoomScale;
			//Rotaion Window
			float _RotationAngle;
			//Chromatic Aberration
			float _CASize;
			//Binarization
			float _BinarizationThreshold;
			//Blur
			float _BlurFactor;
			float4 _GrabTexture_TexelSize;


			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeGrabScreenPos (o.vertex);
				return o;
			} 


			fixed4 frag(v2f i) : SV_Target
			{
				half2 grabUV = (i.screenPos.xy / i.screenPos.w);
				fixed4 result = 0.0f;

				#ifdef Shake
				grabUV += _ShakeAmplitude * 0.0001 * sin(_Time.y * _ShakeSpeed);
				#endif

				#ifdef Zoom
					float2 pivot_uv = float2(0.5, 0.5);
					float2 r = (grabUV - pivot_uv) * (1 / _ZoomScale);
					grabUV = r + pivot_uv;
				#endif

				#ifdef RotationWindow
					float2x2 RotationMatrix = float2x2(cos(_RotationAngle), -sin(_RotationAngle), sin(_RotationAngle), cos(_RotationAngle));
					float2 RotationPivot = float2(0.5, 0.5);
					float2 Rotation_temp = (grabUV - RotationPivot);
					grabUV = mul(RotationMatrix, Rotation_temp) + RotationPivot;
				#endif


				fixed4 col = tex2D(_GrabTexture, grabUV);


				#ifdef Bloom
					float u = 1 / _ScreenParams.x;
					float v = 1 / _ScreenParams.y;
					for (float x = 0; x < _BloomBlur; x++){
						float xx = grabUV.x + (x - _BloomBlur / 2) * u;
						for (float y = 0; y < _BloomBlur; y++){
							float yy = grabUV.y + (y - _BloomBlur / 2) * v;
							fixed4 smp = tex2D(_GrabTexture, float2(xx, yy));
							result += smp;
						}
					}
					result /= _BloomBlur * _BloomBlur;
					result *= _BloomStrength;
					col += result;
				#endif				

				#ifdef RadialBlur
					float2 window_center = (0.5, 0.5);
					float4 destColor = 0;
					float2 symmetryUV = grabUV - 0.5;
					float radial_distance = length(symmetryUV);
					float factor = _RadialBlurStrength / _RadialSampleCount * radial_distance;
					for(int j=0; j<_RadialSampleCount; j++){
						float uvOffset = 1 - factor * j;
						destColor += tex2D(_GrabTexture, symmetryUV * uvOffset + 0.5);
					}
					destColor /= _RadialSampleCount;
					col.rgb = lerp(col.rgb, destColor, 0.5);
				#endif

				#ifdef ChromaticAberration
					float4 CAtmp = col;
					float2 CAuvBase = grabUV - 0.5;
					float2 CAuvR = CAuvBase * (1.0 - _CASize * 2.0) + 0.5;
					CAtmp.r = tex2D(_GrabTexture, CAuvR).r;
					float2 CAuvG = CAuvBase * (1.0 - _CASize) + 0.5;
					CAtmp.g = tex2D(_GrabTexture, CAuvG).g;
					col.rgb = lerp(col.rgb, CAtmp.rgb, 0.5);
				#endif

				#ifdef DoubleZoom
					float4 dztmp = col;
					float2 dzuvBase = grabUV - 0.5;
					float2 dzuv = dzuvBase * (1.0 - _DoubleZoomScale * 2.0) + 0.5;
					dztmp = tex2D(_GrabTexture, dzuv);
					col.rgb = lerp(col.rgb, dztmp.rgb, 0.5);
				#endif

				#ifdef ColorInversion
					col.rgb = 1 - col.rgb;
				#endif

				#ifdef Binarization
					float4 Binaritmp = col;
					float BinariGray = dot(Binaritmp.rgb, float3(0.299, 0.587, 0.114));
					if(BinariGray < _BinarizationThreshold){
						Binaritmp = float4(0, 0, 0, 1);
					}else{
						Binaritmp = float4(1, 1, 1, 1);
					}
					col.rgb = lerp(col.rgb, Binaritmp.rgb, 1);
				#endif

				#ifdef Grayscale
					float4 Graytmp = col;
					float Gray = dot(Graytmp.rgb, float3(0.299, 0.587, 0.114));
					Graytmp = float4(Gray, Gray, Gray, 1);
					col.rgb = lerp(col.rgb, Graytmp.rgb, 1);
				#endif

				#ifdef Blur
					float4 BlurPixelCol = (0, 0, 0, 0);
					#define ADDPIXEL_x(weight, kernelX) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.screenPos.x + _GrabTexture_TexelSize.x * 1000 * kernelX * _BlurFactor, i.screenPos.y, i.screenPos.z, i.screenPos.w))) * weight;
					BlurPixelCol += ADDPIXEL_x(0.05, 4.0);
                	BlurPixelCol += ADDPIXEL_x(0.09, 3.0);
                	BlurPixelCol += ADDPIXEL_x(0.12, 2.0);
                	BlurPixelCol += ADDPIXEL_x(0.15, 1.0);
                	BlurPixelCol += ADDPIXEL_x(0.18, 0.0);
                	BlurPixelCol += ADDPIXEL_x(0.15, -1.0);
                	BlurPixelCol += ADDPIXEL_x(0.12, -2.0);
                	BlurPixelCol += ADDPIXEL_x(0.09, -3.0);
                	BlurPixelCol += ADDPIXEL_x(0.05, -4.0);	
					col.rgb = lerp(col.rgb, BlurPixelCol.rgb, 1);
				#endif

				#ifdef Colorjack
					//float4 colTmp = tex2D(_GrabTexture, grabUV);
					col.rgb = lerp(col.rgb, _JackColor.rgb, _ColorInterpolation);
				#endif

				return col;
			}
			ENDCG
		}

		GrabPass{}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			#pragma shader_feature Blur

			sampler2D _GrabTexture;

			//Blur
			float _BlurFactor;
			float4 _GrabTexture_TexelSize;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD0;
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
				fixed4 col = tex2D(_GrabTexture, grabUV);
				float4 BlurPixelCol = (0, 0, 0, 0);

				#ifdef Blur
                    #define ADDPIXEL_y(weight, kernelY) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.screenPos.x, i.screenPos.y + _GrabTexture_TexelSize.y * 1000 * kernelY * _BlurFactor, i.screenPos.z, i.screenPos.w))) * weight;					
               		BlurPixelCol += ADDPIXEL_y(0.05, 4.0);
               		BlurPixelCol += ADDPIXEL_y(0.09, 3.0);
               		BlurPixelCol += ADDPIXEL_y(0.12, 2.0);
               		BlurPixelCol += ADDPIXEL_y(0.15, 1.0);
               		BlurPixelCol += ADDPIXEL_y(0.18, 0.0);
               		BlurPixelCol += ADDPIXEL_y(0.15, -1.0);
               		BlurPixelCol += ADDPIXEL_y(0.12, -2.0);
               		BlurPixelCol += ADDPIXEL_y(0.09, -3.0);
               		BlurPixelCol += ADDPIXEL_y(0.05, -4.0);
	   				col.rgb = lerp(col.rgb, BlurPixelCol.rgb, 1);
				#endif

				return col;
			}
		
			ENDCG
		}
	}
}