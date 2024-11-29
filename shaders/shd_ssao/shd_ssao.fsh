precision highp float;
uniform sampler2D u_sDepth;
uniform sampler2D u_sNormal;
uniform sampler2D u_sNoise;

uniform mat4 u_mInvProj;
uniform mat3 u_mView;		// View matrix, required for normal sampling
uniform vec2 u_vTexelSize;
uniform vec2 u_vaSampleDirections[64]; // Maximum of 64 samples
uniform float u_fSampleRadius;
uniform float u_fScale;
uniform float u_fBias;
uniform float u_fIntensity;

#ifndef _YY_GLSLES_
uniform int u_iSamples;
#endif

varying vec2 v_vTexcoord;

vec3 depth_to_view(float fDepth, vec2 vUV){
	#ifdef _YY_HLSL11_
    float fZ = fDepth;
    vec4 vClipPos = vec4(vUV.x * 2.0 - 1.0, (1.0 - vUV.y) * 2.0 - 1.0, fZ, 1.0);
    #else
    float fZ = fDepth * 2.0 - 1.0;
    vec4 vClipPos = vec4(vUV.xy * 2.0 - 1.0, fZ, 1.0);
    #endif
    
    vec4 vViewPos = u_mInvProj * vClipPos;
    vViewPos /= vViewPos.w;
    return vViewPos.xyz;
}

float calculate_ao(vec2 vUV, vec2 vOffset, vec3 vPosition, vec3 vNormal){
	vec3 vNPosition = depth_to_view(texture2D(u_sDepth, vUV + vOffset).r, vUV + vOffset);
	vec3 vDifference = vNPosition - vPosition;
	vec3 vDirection = normalize(vDifference);
	float fDistance = length(vDifference) * u_fScale;
	return max(0.0, dot(vNormal, vDirection) - u_fBias) * (1.0 / (1.0 + fDistance)) * u_fIntensity;
}

void main() {
	vec3 vPosition = depth_to_view(texture2D(u_sDepth, v_vTexcoord).r , v_vTexcoord);
	vec3 vNormal = normalize(u_mView * (texture2D(u_sNormal, v_vTexcoord).rgb * 2.0 - 1.0));
	
	vec2 vRand = normalize(texture2D(u_sNoise, fract(v_vTexcoord / u_vTexelSize / 64.0)).rg * 2.0 - 1.0);
	float fAO = 0.0;
	float fSampleRadius = u_fSampleRadius / vPosition.z;
	
	#ifndef _YY_GLSLES_
	for (int i = 0; i < u_iSamples; ++i){
	#else
	for (int i = 0; i < 8; ++i){
	#endif
		vec2 vC = u_vaSampleDirections[i];
		
		vec2 vCoord1 = reflect(vC, vRand) * fSampleRadius;
		vec2 vCoord2 = vec2(vCoord1.x * 0.707 - vCoord1.y * 0.707, vCoord1.x * 0.707 + vCoord1.y * 0.707);
		// @note	Used to do 4 quarter samples; looks much better but WAY too costly.
		fAO += calculate_ao(v_vTexcoord, vCoord1 * 0.25, vPosition, vNormal);
		fAO += calculate_ao(v_vTexcoord, vCoord2, vPosition, vNormal);
	}
	
	#ifndef _YY_GLSLES_
	fAO = clamp(fAO / float(u_iSamples * 2), 0.0, 1.0);
	#else
	fAO = clamp(fAO / 16.0, 0.0, 1.0);
	#endif
	gl_FragColor.r = 1.0 - fAO;
}