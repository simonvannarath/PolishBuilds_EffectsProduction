
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

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
    LIGHTING_COORDS(3,4)
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
    TRANSFER_VERTEX_TO_FRAGMENT(o); // gives us out lighting data
    return o;
}

fixed4 frag (v2f i) : SV_Target
{
    // Diffuse Lambert lighting
                
    float3 N = normalize(i.normal);
    float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition)); // Light position a different value returned depending on pass
    float attenuation = LIGHT_ATTENUATION(i);
    float3 lambert = max(0, dot(N,L));
    float3 diffuseLight = (lambert * attenuation) * _LightColor0.xyz;
                
    // Blinn-Phong
    float3 V = normalize(_WorldSpaceLightPos0 - i.worldPosition);
    float3 H = normalize(L + V);
    float3 specularLight = saturate(dot(H, N)) * (lambert > 0);
    float specularExponent = exp2(_Gloss * 11);
    specularLight = pow(specularLight, specularExponent) * _Gloss * attenuation;
    specularExponent *= _LightColor0.xyz;

    return float4(diffuseLight * _Color + specularLight, 1);
}
