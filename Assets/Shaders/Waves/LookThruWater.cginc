#if !defined(LOOK_THRU_WATER_INCLUDED)
#define LOOK_THRU_WATER_INCLUDED


sampler2D _CameraDepthTexture;
sampler2D _WaterBackground;
float4 _CameraDepthTexture_TexelSize;
float3 _WaterFogColour;
float _WaterFogDensity;

float2 AlignWithGrabTexel(float uv)
{
	#if UNITY_UV_STARTS_AT_TOP
	if(_CameraDepthTexture_TexelSize.y < 0)
	{
		uv.y = 1 - uv.y;
	}
	#endif
	return (floor(*uv * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs(_CameraDepthTexture_TexelSize.xy);
}

float3 ColourBelowWater(float4 screenPos, float3 tangentSpaceNormal)
{
	// float4 is xyzw
	float uvOffset = tangentSpaceNormal.xy;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	float screenUV = AlignWithGrabTexel((screenPos.xy + uvOffset)	/ screenPos.w); // Final depth texture coordinates

	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
	// UNITY_Z_0_FAR_FROM_CLIPSPACE convert it to linear depth
	// screenPos.z interpolated clip space depth
	// Simply, it's the depth to the surface of the water
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	// We now have the depth from the surface of the water to the background
	float depthDifference = backgroundDepth - surfaceDepth;
	uvOffset =   
	if(depthDifference < 0)
	{
		screenUV = AlignWithGrabTexel(screenPos.xy / screenPos.w);
		backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
		depthDifference = backgroundDepth - surfaceDepth;
	}

	float backgroundColour = tex2D(_WaterBackground, screenUV).rgb;
	float fogFactor = exp2(-_WaterFogDensity * depthDifference);
	return lerp(_WaterFogColour, backgroundColour, fogFactor);
}

#endif