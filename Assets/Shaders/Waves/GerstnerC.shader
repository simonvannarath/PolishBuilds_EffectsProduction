Shader "Custom/GerstnerC"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _WaterFogColour("Water Fog Colour", Color) = (0, 0, 0, 0)
        _WaterFogDensity("Water Fog Density", Range(0,1)) = 0.0
        _RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25

        //_Steepness ("Steepness", Range(0,1)) = 0.5
        //_Wavelength ("Wavelength", Float) = 10
        //_Direction ("Direction (2D)", Vector) = (1,0,0,0)
        _WaveA ("Wave A(dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B(dir, steepness, wavelength)", Vector) = (0,1,0.25,20)
        _WaveC ("Wave C(dir, steepness, wavelength)", Vector) = (1,1,0.15,10)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
        }
        LOD 200

        GrabPass {"_WaterBackground"}

        CGPROGRAM
        #pragma surface surf Standard alpha vertex:vert finalcolor:ResetAlpha
        #pragma target 3.0

        #include "LookThruWater.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float4 _WaveA, _WaveB, _WaveC;
        float _RefractionStrength;
        //float _Wavelength, _Steepness;
        //float2 _Direction;
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color)
        {
            color.a = 1;
        }

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
                    direction.x                * (steepness * cos(f)),
                    -direction.x * direction.y * (steepness * sin(f))
            );
            binormal += float3(
                -direction.x * direction.y    * (steepness * sin(f)),
                direction.y                   * (steepness * cos(f)),
                1 - direction.y * direction.y * (steepness * sin(f))
            );
            return float3(
            direction.x * (amplitute * cos(f)), //moves left and right
            amplitude   * sin(f), //moves up and down
            direction.y * (amplitute * cos(f))
            );
        }

        //waves
        void vert(inout appdata_full vertexData)
        {
            float3 gridPoint = vertexData.vertex.xyz;
            float3 tangent = float3(1,0,0);
            float3 binormal = float3(0,0,1);
            float3 p = gridPoint;
            p+= GerstnerWave(_WaveA, gridPoint, tangent, binormal);
            p+= GerstnerWave(_WaveB, gridPoint, tangent, binormal);
            p+= GerstnerWave(_WaveC, gridPoint, tangent, binormal);
            float3 normal = normalize(cross(binormal, tangent));
            vertexData.vertex.xyz = p;
            vertexData.normal = normal;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            
            // Metallic and smoothness come from slider variables
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Emission = ColourBelowWater(IN.screenPos, o.Normal) * (1 - c.a);

        }
        ENDCG
    }
}