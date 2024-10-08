uniform sampler2D u_sDepth;
uniform sampler2D u_sNormal;

uniform int u_iSamples;		// Number of random samples to use when checking nearby fragments
uniform float u_fFalloff;	// Threshold for distance falloff
uniform float u_fRadius;	// Sample radius in texels
uniform float u_fStrength;	// Strength of the SSAO effect
uniform float u_fArea;		// Area threshold for falloff vs occlusion
uniform float u_fNormalBias;	// Larger will discard occlusion between fragments w/ similar normals

varying vec2 v_vTexcoord;

float rand(vec2 vValue){
    return abs(fract(sin(dot(vValue, vec2(12.9898, 78.233))) * 43758.5453)) * 2.0 - 1.0;
}

void main() {
	// Random sample vector to allow for noise
	vec3 vRandom = normalize(vec3(
		rand(v_vTexcoord.xy * 2.0),
		rand(v_vTexcoord.xy * 3.0),
		rand(v_vTexcoord.xy * 4.0)
	)); 
	float fDepth = texture2D(u_sDepth, v_vTexcoord.xy).r;
	vec3 vNormal = normalize(texture2D(u_sNormal, v_vTexcoord.xy).rgb * 2.0 - 1.0);
	vNormal = -vNormal;
	vec3 vPosition = vec3(v_vTexcoord.xy, fDepth);
	float fRadiusDepth = u_fRadius / fDepth;
	float fOcclusion = 0.0;
	
	for (int i = 0; i < u_iSamples; ++i){
			// Note: We randomize the length multiplier by [0.25..1.0] than raise to a power
			//		 to prioritize samples closer to our position.
		vec3 vRay = vRandom * fRadiusDepth * pow(max(0.1, abs(rand(vRandom.yy))), 1.25);
		vec3 vHemiRay = vPosition + sign(dot(vRay, vNormal)) * vRay; // Grab the final position; mirror the ray if pointing the wrong way
		vRandom = normalize(vRandom + vec3(rand(vHemiRay.zx), rand(vRay.xz), rand(vHemiRay.yy)));
		
		float fOcclusionDepth = texture2D(u_sDepth, clamp(vHemiRay.xy, 0.0, 1.0)).r;
		float fDifference = fDepth - fOcclusionDepth;
		
		// Sample normal and compare; if they are similar normals then we likely
		// won't have occlusion
		vec3 vSampleNormal = normalize(texture2D(u_sNormal, clamp(vHemiRay.xy, 0.0, 1.0)).xyz * 2.0 - 1.0);
		vSampleNormal = -vSampleNormal;
		float fDot = 1.0 - max(0.0, dot(vSampleNormal, vNormal)) * u_fNormalBias;
		 
		fOcclusion += step(u_fFalloff, fDifference) * (1.0 - smoothstep(u_fFalloff, u_fArea, fDifference)) * fDot;
	}
	
	float fFinal = 1.0 - u_fStrength * fOcclusion * (1.0 / float(u_iSamples));
	gl_FragColor.r = fFinal;
}