Shader "Unlit/Lighting"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss("Gloss", float) = 1
        _Color("Colour", color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            // #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPosition : TEXCOORD02;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Diffuse Lambert lighting
                
                float3 N = normalize(i.normal);
                float3 L = _WorldSpaceLightPos0.xyz; // says its a position, but is actually a direction to a light source
                float3 lambert = max(0, dot(N,L));
                float3 diffuseLight = lambert * _LightColor0.xyz;
                
                // Blinn-Phong
                float3 V = normalize(_WorldSpaceLightPos0 - i.worldPosition);
                float3 H = normalize(L + V);
                float3 specularLight = saturate(dot(H, N)) * (lambert > 0);
                float specularExponent = exp2(_Gloss * 11);
                specularLight = pow(specularLight, specularExponent) * _Gloss;
                specularExponent *= _LightColor0.xyz;

                return float4(diffuseLight * _Color + specularLight, 1);
            }
            ENDCG
        }
    }
}
