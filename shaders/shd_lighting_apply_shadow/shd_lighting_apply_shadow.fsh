precision highp float;

uniform sampler2D u_sShadow;    // Shadow values (either 0 or 1)
uniform sampler2D u_sDepth;
uniform sampler2D u_sDither;
uniform vec2 u_vTexelSize;
uniform float u_fSampleBias;
uniform int u_iDither;			// Whether or not dithering should occur on shadow edges
uniform int u_iSampleRadius;	

varying vec2 v_vTexcoord;

float modulo(float fV, float fM){
    return fract(fV / fM) * fM;
}

float calculate_dither(float fShadow, vec2 vUV){
	vec2 vCoord = vUV / u_vTexelSize;
	float fX = modulo(vCoord.x, 128.0) / 128.0; // @note: Hard-coded to match sprite
	float fY = modulo(vCoord.y, 6.0) / 256.0;
	float fD = step(0.5, texture2D(u_sDither, vec2(fX, clamp(fShadow + fY, 0.0, 0.9999))).r);
	if (fD > 0.5)
		return fShadow * 0.5;
	
	return fShadow;
}

/// @todo   Add following sample method for much better edges
// https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-17-efficient-soft-edged-shadows-using
float calculate_shadow(){
	#ifdef _YY_GLSLES_
	const int iRadius = 3;
	#else
	int iRadius = u_iSampleRadius;
	#endif
    float fShadow = 0.0;
    float fDepth = texture2D(u_sDepth, v_vTexcoord).r;
    int iCount = 0;
    for (int i = -iRadius; i <= iRadius; ++i){
        for (int j = -iRadius; j <= iRadius; ++j){
            vec2 vUV = v_vTexcoord + vec2(i, j) * u_vTexelSize;
            float fShadowDepth = texture2D(u_sDepth, vUV).r;
            if (abs(fShadowDepth - fDepth) > u_fSampleBias)
            	continue;
            
            fShadow += texture2D(u_sShadow, vUV).r;
            iCount += 1;
        }
    }
    
    fShadow /= float(iCount);
    if (u_iDither > 0)
    	fShadow = calculate_dither(fShadow, v_vTexcoord);
    	
    return fShadow;
}

void main()
{
    vec4 vColor = texture2D(gm_BaseTexture, v_vTexcoord);
    float fShadow = calculate_shadow();
    gl_FragColor = vec4(vColor.rgb * (1.0 - fShadow), vColor.a);
}
