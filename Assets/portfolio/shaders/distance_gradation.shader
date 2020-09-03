Shader "Custom/distance_Gradation"
{
    Properties
    {
        [Enum(OFF,0,ON,1)] _ZWrite ("ZWrite", float) = 1.0
        [Space(20)]
        _NearColor("NearColor", color) = (0, 0, 0, 0)
        _FarColor("FarColor", color) = (0, 0, 0, 0)
        _NearTexture("NearTexture", 2D) = "white" {}
        _FarTexture("FarTexture", 2D) = "white" {}
        _Dinstance("Distance", Range(0, 200)) = 0.5
        _NearThreshold("Near Threshold", Range(-100, -0.1)) = 0.1
        _FarThreshold("Far Threshold", Range(0.1, 100)) = 0.1

        [Space(30)]
        [Header(Particle)]
        [Enum(Particle Property, 0, Material, 1)] _DecisionOfAlpha("Which decides alpha?", float) = 1
        _ColorBlend("Color Blend", Range(0, 1)) = 1
        _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 3
    }

    SubShader
    {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Off 
    Lighting Off 
    ZWrite [_ZWrite]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_particles

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD2;
                fixed4 color : COLOR;
                #ifdef SOFTPARTICLES_ON
                    float4 projPos : TEXCOORD3;
                #endif
            };

            float4 _NearColor, _FarColor;
            float _Dinstance, _NearThreshold, _FarThreshold;
            sampler2D _NearTexture, _FarTexture;
            float4 _NearTexture_ST, _FarTexture_ST;
            float _InvFade;
            float _ColorBlend;
            float _DecisionOfAlpha;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.uv1 = TRANSFORM_TEX(v.uv, _NearTexture);
                o.uv2 = TRANSFORM_TEX(v.uv, _FarTexture);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                #ifdef SOFTPARTICLES_ON
                    o.projPos = ComputeScreenPos (o.vertex);
                    COMPUTE_EYEDEPTH(o.projPos.z);
                #endif
                o.color = lerp((1,1,1,1), v.color, _ColorBlend);
                //_DecisionOfAlphaを-10とかにしてstart colorのalphaを0にするとなんかすごいことになる
                //_ColorBlendは1
                o.color.w = lerp(o.color.w, 1, _DecisionOfAlpha);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                float dist = distance(i.worldPos, _WorldSpaceCameraPos);

                _NearColor *= tex2D(_NearTexture, i.uv1) * i.color;
                _FarColor *= tex2D(_FarTexture, i.uv2) * i.color;

                if(dist <= _Dinstance + _FarThreshold && dist >= _Dinstance + _NearThreshold){
                    float range = ((dist - _Dinstance) - _NearThreshold) / (_FarThreshold - _NearThreshold);
                    col = lerp(_NearColor, _FarColor, range);
                }else if(dist < _Dinstance + _NearThreshold){
                    col = _NearColor;
                }else{
                    col = _FarColor;
                }

                #ifdef SOFTPARTICLES_ON
                    float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                    float partZ = i.projPos.z;
                    float fade = saturate (_InvFade * (sceneZ-partZ));
                    col *= fade;
                #endif

                return col;
            }
            ENDCG
        }
    }
}
