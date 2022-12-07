Shader "Custom/Gerstner"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        //_Amplitude ("Amplitude", Float) = 1
        //steepness ("Steepness", Range(0,1)) = 0.5
        //_Wavelength ("Wavelength", Float) = 10
        //_Direction ("Direction (2D)", Vector) = (1, 0, 0, 0)
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
        _WaveB ("Wave B (dir, steepness, wavelength)", Vector) = (0, 1, 0.25, 20)
        _WaveC ("Wave C (dir, steepness, wavelength)", Vector) = (1, 1, 0.15, 10)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float4 _WaveA, _WaveB, _WaveC;
        //float _Wavelength, steepness;
        //float2 _Direction;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        float3 GerstnerWave(float4 wave, float3 pnt, inout float3 tangent, inout float3 binormal)
        {
            float steepness = wave.z;
            float wavelength = wave.w;
            float k = UNITY_TWO_PI / wavelength;
            float c = sqrt(9.8 / k);
            float2 direction = normalize(wave.xy);
            float f = k * (dot(direction, pnt.xz) - c * _Time.y);
            float amplitude = steepness / k;

            tangent += float3(
                        -direction.x * direction.x * (steepness * sin(f)),
                        direction.x * (steepness * cos(f)),
                        -direction.x * direction.y * (steepness * sin(f)));
            binormal += float3(
                        -direction.x * direction.y * (steepness * sin(f)),
                        direction.y * (steepness * cos(f)),
                        1 - direction.y * direction.y * (steepness * sin(f)));
            
            return float3(
                        direction.x * (amplitude * cos(f)),
                        amplitude * sin(f),
                        direction.y * (amplitude * cos(f)));
            //float3 normal = normalize(cross(binormal, tangent));
        }

        void vert(inout appdata_full vertexData)
        {
           

            float3 gridPoint = vertexData.vertex.xyz;
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);
            float3 p = gridPoint;

            p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
            float3 normal = normalize(cross(binormal, tangent));
            vertexData.vertex.xyz = p;
            vertexData.normal = normal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
