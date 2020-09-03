Shader "Custom/Grid_and_Polkadot"
{
    Properties
    {
        _MainTex ("Background Texture", 2D) = "white" {}
        _MainCol("Background Color", Color) = (0, 0, 0, 0)

        [Space(20)]
        [Header(Grid)]
        [Space(5)]
        _VerticalLineTexture("Vertical Line Texture", 2D) = "white" {}
        _HorizontalLineTexture("Horizontal Line Texture", 2D) = "white" {}
        [Space(5)]
        _CrossLinePriority("Cross Line Priority", Range(0, 1)) = 0.5
        [Space(10)]
        _VerticalLineColor("Vertical Line Color", Color) = (0, 0, 0, 0)
        _VerticalLineWidth("Vertical Line Width", Range(0, 1)) = 0.5
        _VerticalLineNum("Vertical Line Num", Range(0, 500)) = 5
        _VerticalScrollSpeed("Vertical Scroll Speed", Range(-2, 2)) = 0
        [Space(10)]
        _HorizontalLineColor("Horizontal Line Color", Color) = (0, 0, 0, 0)
        _HorizontalLineWidth("Horizontal Line Width", Range(0, 1)) = 0.5
        _HorizontalLineNum("Horizontal Line Num", Range(0 ,500)) = 5
        _HorizontalScrollSpeed("Horizontal Scroll Speed", Range(-2, 2)) = 0

        [Space(20)]
        [Header(Polka dot)]
        [Space(5)]
        _PolkaTexture("Polka Dot Texture", 2D) = "white" {}
        _PolkaCol("Polka Dot Color", Color) = (0, 0, 0, 0)
        [Space(5)]
        _PolkaBackgroundTexture("Polka Dot Background Texture", 2D) = "white" {}
        _PolkaBackgroundCol("Polka Dot Background Color", Color) = (0, 0, 0, 0)
        [Space(5)]
        _PolkaNumX("Polka Dot Num X", Range(0, 100)) = 5
        _PolkaNumY("Polka Dot Num Y", Range(0, 100)) = 5
        _PolkaRadius("Polka Dot Radius", Range(0, 1)) = 0.3
        _PolkaDotTextureScrollSpeedX("Polka Dot Texture Scroll Speed X", Range(-2, 2)) = 0
        _PolkaDotTextureScrollSpeedY("Polka Dot Texture Scroll Speed Y", Range(-2, 2)) = 0
        _PolkaDotScrollSpeedX("Polka Dot Scroll Speed X", Range(-2, 2)) = 0
        _PolkaDotScrollSpeedY("Polka Dot Scroll Speed Y", Range(-2, 2)) = 0

        [Space(20)]
        _Para("Change pattern", Range(0, 1)) = 0.5
    }


    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
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


            float3 HUEtoRGB(in float H)
            {
                float R = abs(H * 6 - 3) - 1;
                float G = 2 - abs(H * 6 - 2);
                float B = 2 - abs(H * 6 - 4);
                return saturate(float3(R, G, B));
            }


            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex, _VerticalLineTexture, _HorizontalLineTexture;
            float4 _MainTex_ST, _VerticalLineTexture_ST, _HorizontalLineTexture_ST;
            float4 _MainCol, _VerticalLineColor, _HorizontalLineColor;
            float _CrossLinePriority, _VerticalLineWidth, _VerticalLineNum, _HorizontalLineWidth, _HorizontalLineNum;
            float _VerticalScrollSpeed, _HorizontalScrollSpeed;

            sampler2D _PolkaTexture, _PolkaBackgroundTexture;
            float4 _PolkaCol, _PolkaBackgroundCol;
            float _PolkaTexture_ST, _PolkaBackgroundTexture_ST;
            float _PolkaNumX, _PolkaNumY, _PolkaRadius;
            float _PolkaDotTextureScrollSpeedX, _PolkaDotTextureScrollSpeedY;
            float _PolkaDotScrollSpeedX, _PolkaDotScrollSpeedY;

            float _Para;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
			
                //Grid

				fixed4 grid_col, polkadot_col, col;
                float4 v_col, h_col;
                float2 vertical_uv, horizontal_uv;

                vertical_uv = i.uv;
                horizontal_uv = i.uv;

                vertical_uv += _Time.y * _VerticalScrollSpeed;
                horizontal_uv += _Time.y * _HorizontalScrollSpeed;

                float y1 = abs(sin(vertical_uv.x * _VerticalLineNum));
                float y2 = abs(sin(horizontal_uv.y * _HorizontalLineNum));

                v_col = tex2D(_VerticalLineTexture, vertical_uv) * _VerticalLineColor;
                h_col = tex2D(_HorizontalLineTexture, horizontal_uv) * _HorizontalLineColor;

                if(0 <= y1 && y1 <= _VerticalLineWidth && 0 <= y2 && y2 <= _HorizontalLineWidth){
                    grid_col = lerp(v_col, h_col, _CrossLinePriority);
                }else if(0 <= y1 && y1 <= _VerticalLineWidth){
                    grid_col = v_col;
                }else if(0 <= y2 && y2 <= _HorizontalLineWidth){
                    grid_col = h_col;
                }else{
                    grid_col = tex2D(_MainTex, i.uv) * _MainCol;
                }


                //Polka Dot
                fixed2 tmp = i.uv;
                tmp.x += _Time.y * _PolkaDotScrollSpeedX;
                tmp.y += _Time.y * _PolkaDotScrollSpeedY;
                fixed2 st = tmp;
                st.x *= _PolkaNumX;
                st.y *= _PolkaNumY;
                st = frac(st);
                fixed l = distance(st, fixed2(0.5,0.5));

                fixed2 tex_uv = i.uv;
                tex_uv.x += _Time.z * _PolkaDotTextureScrollSpeedX;
                tex_uv.y += _Time.z * _PolkaDotTextureScrollSpeedY;   

                if(_PolkaRadius >= l){
                    polkadot_col = tex2D(_PolkaTexture, frac(tex_uv)) * _PolkaCol;
                }else{
                    polkadot_col = tex2D(_PolkaBackgroundTexture, i.uv) * _PolkaBackgroundCol;
                }

                col = lerp(grid_col, polkadot_col, _Para);
                return col;
            }
            ENDCG
        }
    }
}
