uniform sampler2D u_sShadow;    // Shadow values (either 0 or 1)
uniform vec2 u_vTexelSize;

varying vec2 v_vTexcoord;

/// @todo   Add following sample method for much better edges
// https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-17-efficient-soft-edged-shadows-using
float calculate_shadow(){
	// HLSL uses a really old shader version and it fails to compile due to loop complexity
	// w/ the sampling if > 2.
	#ifdef _YY_HLSL11_
    const int iRadius = 2;
	#else
	const int iRadius = 3;
	#endif
    
    float fShadow = 0.0;
    for (int i = -iRadius; i <= iRadius; ++i){
        for (int j = -iRadius; j <= iRadius; ++j){
            vec2 vUV = v_vTexcoord + vec2(i, j) * u_vTexelSize;
            fShadow += texture2D(u_sShadow, vUV).r;
        }
    }
    
    return fShadow / pow(2.0 * float(iRadius) + 1.0, 2.0);
}

void main()
{
    vec4 vColor = texture2D(gm_BaseTexture, v_vTexcoord);
    float fShadow = calculate_shadow();
    gl_FragColor = vec4(vColor.rgb * (1.0 - fShadow), vColor.a);
}
