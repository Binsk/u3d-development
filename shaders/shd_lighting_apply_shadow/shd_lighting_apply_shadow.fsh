precision highp float;

uniform sampler2D u_sShadow;    // Shadow values (either 0 or 1)
uniform sampler2D u_sDepth;
uniform vec2 u_vTexelSize;
uniform float u_fSampleBias;

varying vec2 v_vTexcoord;

/// @todo   Add following sample method for much better edges
// https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-17-efficient-soft-edged-shadows-using
float calculate_shadow(){
	const int iRadius = 3;
    
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
    
    return fShadow / float(iCount);
}

void main()
{
    vec4 vColor = texture2D(gm_BaseTexture, v_vTexcoord);
    float fShadow = calculate_shadow();
    gl_FragColor = vec4(vColor.rgb * (1.0 - fShadow), vColor.a);
}
